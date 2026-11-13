# Instance principals: las instancias del compartment obtienen permisos sin claves en disco.
resource "oci_identity_dynamic_group" "instances" {
  compartment_id = var.tenancy_ocid
  name           = "${var.name}-instancias"
  description    = "Instancias del compartment del proyecto"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}'}"
}

resource "oci_identity_policy" "instances" {
  compartment_id = var.compartment_id
  name           = "${var.name}-instancias"
  description    = "Minimo privilegio: objetos del bucket del proyecto y lectura de secretos"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.instances.name} to manage objects in compartment id ${var.compartment_id} where target.bucket.name='${var.bucket_name}'",
    "Allow dynamic-group ${oci_identity_dynamic_group.instances.name} to read secret-bundles in compartment id ${var.compartment_id}",
  ]
}
