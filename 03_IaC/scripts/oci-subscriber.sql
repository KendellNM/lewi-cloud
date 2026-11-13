-- Ejecutar en PostgreSQL de OCI (suscriptor) DESPUES de que la VPN y la regla de RDS esten activas (stack 30).
-- 1) En RDS (como pgadmin): CREATE ROLE replicador WITH LOGIN PASSWORD '<secreto>'; GRANT rds_replication TO replicador;
--    GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicador;  CREATE PUBLICATION abelito_pub FOR ALL TABLES;
-- 2) Cargar el esquema (pg_dump --schema-only de RDS) en OCI, luego:
CREATE SUBSCRIPTION abelito_sub
  CONNECTION 'host=<endpoint-rds> port=5432 dbname=abelito user=replicador password=<secreto> sslmode=verify-full sslrootcert=/etc/pki/rds-global-bundle.pem'
  PUBLICATION abelito_pub;
-- Retraso: SELECT now() - latest_end_time FROM pg_stat_subscription;
