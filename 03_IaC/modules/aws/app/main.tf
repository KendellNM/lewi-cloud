data "aws_partition" "current" {}

locals {
  tags = merge(var.tags, { Modulo = "aws-app" })
}

# --- IAM de las instancias (minimo privilegio) ---
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(["AmazonSSMManagedInstanceCore", "CloudWatchAgentServerPolicy"])
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.key}"
}

data "aws_iam_policy_document" "app" {
  statement {
    sid       = "ObjetosDeNegocio"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [var.objects_bucket_arn, "${var.objects_bucket_arn}/*"]
  }
  statement {
    sid       = "SecretoDeBaseDeDatos"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
  statement {
    sid       = "ClaveDelEntorno"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "app" {
  name   = "datos-de-la-aplicacion"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app"
  role = aws_iam_role.app.name
}

# --- Balanceador + WAF ---
resource "aws_lb" "this" {
  name                             = "${var.name}-alb"
  load_balancer_type               = "application"
  internal                         = false
  subnets                          = var.public_subnet_ids
  security_groups                  = [var.alb_sg_id]
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].id
      enabled = true
    }
  }
  tags       = local.tags
  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# --- Logs de acceso del ALB ---
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "alb_logs" {
  count         = var.enable_access_logs ? 1 : 0
  bucket        = "${var.name}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count                   = var.enable_access_logs ? 1 : 0
  bucket                  = aws_s3_bucket.alb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "alb_logs" {
  count = var.enable_access_logs ? 1 : 0
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_logs[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  policy = data.aws_iam_policy_document.alb_logs[0].json
}

resource "aws_lb_target_group" "app" {
  name     = "${var.name}-tg"
  vpc_id   = var.vpc_id
  port     = var.app_port
  protocol = "HTTPS"

  health_check {
    protocol            = "HTTPS"
    path                = "/healthz"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  deregistration_delay = 30
  tags                 = local.tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Cierra el rodeo del proxy: el origen solo acepta trafico que Cloudflare marco con el secreto.
  dynamic "rule" {
    for_each = var.origin_verify_secret == "" ? [] : [1]
    content {
      name     = "exigir-cabecera-de-origen"
      priority = 0
      action {
        block {}
      }
      statement {
        not_statement {
          statement {
            byte_match_statement {
              search_string         = var.origin_verify_secret
              positional_constraint = "EXACTLY"
              field_to_match {
                single_header {
                  name = "x-origin-verify"
                }
              }
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "origen-sin-cabecera"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "limite-por-ip-cliente"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = var.rate_limit_per_5min
        aggregate_key_type = "FORWARDED_IP"
        forwarded_ip_config {
          header_name       = "CF-Connecting-IP"
          fallback_behavior = "MATCH"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "limite-por-ip"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "reglas-comunes-aws"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "reglas-comunes"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-waf"
    sampled_requests_enabled   = true
  }
  tags = local.tags
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

# --- Computo: Auto Scaling Group 2-4 en dos AZ, sin IP publica ---
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "app" {
  name_prefix            = "${var.name}-app-"
  image_id               = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.app_sg_id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }
  monitoring {
    enabled = true
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
  user_data = base64encode(templatefile("${path.module}/../../shared/nginx-origin.sh.tftpl", { provider = "aws" }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.name}-app" })
  }
  tags = local.tags
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.name}-asg"
  min_size                  = var.asg_min
  desired_capacity          = var.asg_min
  max_size                  = var.asg_max
  vpc_zone_identifier       = var.app_subnet_ids
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                      = "${var.name}-cpu-objetivo"
  autoscaling_group_name    = aws_autoscaling_group.app.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180

  target_tracking_configuration {
    target_value = var.cpu_target
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}
