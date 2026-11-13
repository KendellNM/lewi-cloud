locals {
  tags = merge(var.tags, { modulo = "oci-data" })
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

locals {
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.ad_index].name
  # primario y standby en fault domains distintos (un FD caido no tumba la base)
  db_nodes = var.standby_enabled ? { primary = "FAULT-DOMAIN-1", standby = "FAULT-DOMAIN-2" } : { primary = "FAULT-DOMAIN-1" }
}

data "oci_core_images" "ol9" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# --- PostgreSQL autogestionado: suscriptor logico de RDS ---
resource "oci_core_instance" "postgres" {
  for_each            = local.db_nodes
  fault_domain        = each.value
  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name}-postgres-${each.key}"
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_gb
  }
  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ol9.images[0].id
    boot_volume_size_in_gbs = 50
  }
  create_vnic_details {
    subnet_id        = var.data_subnet_id
    assign_public_ip = false
    nsg_ids          = [var.nsg_db_id]
  }
  metadata = {
    user_data = base64encode(templatefile("${path.module}/postgres-cloud-init.sh.tftpl", {
      pg_major = var.pg_major
    }))
  }
  agent_config {
    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
  is_pv_encryption_in_transit_enabled = true
  freeform_tags                       = local.tags

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

resource "oci_core_volume" "pgdata" {
  for_each            = local.db_nodes
  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name}-pgdata-${each.key}"
  size_in_gbs         = var.data_volume_gb
  vpus_per_gb         = 10
  freeform_tags       = local.tags
}

resource "oci_core_volume_attachment" "pgdata" {
  for_each                            = local.db_nodes
  attachment_type                     = "paravirtualized"
  instance_id                         = oci_core_instance.postgres[each.key].id
  volume_id                           = oci_core_volume.pgdata[each.key].id
  is_pv_encryption_in_transit_enabled = true
}

# --- Object Storage ---
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

resource "oci_objectstorage_bucket" "backups" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = "${var.name}-copias"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
  versioning     = "Enabled"
  freeform_tags  = local.tags
}

# --- Vault: secreto de replicacion ---
resource "oci_kms_vault" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-vault"
  vault_type     = "DEFAULT"
  freeform_tags  = local.tags
}

resource "oci_kms_key" "secrets" {
  compartment_id      = var.compartment_id
  display_name        = "${var.name}-clave-secretos"
  management_endpoint = oci_kms_vault.this.management_endpoint
  protection_mode     = "SOFTWARE"
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  freeform_tags = local.tags
}

resource "oci_vault_secret" "replication" {
  count          = var.replication_password == "" ? 0 : 1
  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.this.id
  key_id         = oci_kms_key.secrets.id
  secret_name    = "${var.name}-replicacion"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.replication_password)
  }
  freeform_tags = local.tags
}
