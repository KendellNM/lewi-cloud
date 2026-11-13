#!/usr/bin/env bash
# Busca residuos facturables despues del destroy. Requiere aws CLI configurado (us-east-1).
set -uo pipefail
R=${AWS_REGION:-us-east-1}
echo "-- NAT Gateways";   aws ec2 describe-nat-gateways --region $R --filter Name=state,Values=available,pending --query 'NatGateways[].NatGatewayId' --output text
echo "-- Elastic IPs";    aws ec2 describe-addresses --region $R --query 'Addresses[].PublicIp' --output text
echo "-- VPN conexiones"; aws ec2 describe-vpn-connections --region $R --query 'VpnConnections[?State!=`deleted`].VpnConnectionId' --output text
echo "-- Balanceadores";  aws elbv2 describe-load-balancers --region $R --query 'LoadBalancers[].LoadBalancerName' --output text
echo "-- RDS + snapshots";aws rds describe-db-instances --region $R --query 'DBInstances[].DBInstanceIdentifier' --output text; aws rds describe-db-snapshots --region $R --snapshot-type manual --query 'DBSnapshots[].DBSnapshotIdentifier' --output text
echo "-- Volumenes EBS";  aws ec2 describe-volumes --region $R --query 'Volumes[].VolumeId' --output text
echo "-- Buckets e3-abelito"; aws s3 ls | grep e3-abelito || true
echo "OCI/GCP/Azure: revisar consola (compartment e3-abelito, bucket GCS, grupo de recursos e3-abelito-recuperacion)."
