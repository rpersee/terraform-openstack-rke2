output "floating_ip" {
  value = openstack_compute_floatingip_associate_v2.associate_floating_ip[*].floating_ip
}

output "internal_ip" {
  value = openstack_compute_instance_v2.instance[*].access_ip_v4
}

output "nodes" {
  value = { for instance in openstack_compute_instance_v2.instance: 
             instance.name => 
                      {"id" = instance.id,
                       "internal_ip" = instance.access_ip_v4,
                       "floating_ip" = var.assign_floating_ip ? nonsensitive(openstack_networking_floatingip_v2.floating_ip[index(openstack_compute_instance_v2.instance, instance)].address) : ""} }
}