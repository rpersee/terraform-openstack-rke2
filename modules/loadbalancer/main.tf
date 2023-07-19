data "openstack_networking_network_v2" "floating_net" {
  name = var.floating_network
}

resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
  name = var.name_prefix
  vip_subnet_id = var.subnet_id
  security_group_ids = [var.secgroup_id]
}

resource "openstack_lb_listener_v2" "api" {
  name                = "${var.name_prefix}-api-listener"
  protocol            = "TCP"
  protocol_port       = 6443
  loadbalancer_id     = openstack_lb_loadbalancer_v2.loadbalancer.id
  timeout_client_data = 2 * 60 * 1000
  timeout_member_data = 2 * 60 * 1000
}

resource "openstack_lb_pool_v2" "api" {
  name        = "${var.name_prefix}-api-pool"
  protocol    = "TCP"
  listener_id = openstack_lb_listener_v2.api.id
  lb_method   = "ROUND_ROBIN"
}

resource "openstack_lb_monitor_v2" "api" {
  name        = "${var.name_prefix}-api-monitor"
  pool_id     = openstack_lb_pool_v2.api.id
  type        = "TLS-HELLO"
  delay       = 5
  timeout     = 5
  max_retries = 3
}

resource "openstack_lb_member_v2" "api" {
  for_each      = var.lb_members
  name          = each.key
  pool_id       = openstack_lb_pool_v2.api.id
  address       = each.value.internal_ip
  protocol_port = 6443
}

resource "openstack_lb_listener_v2" "rke2" {
  name            = "${var.name_prefix}-rke2-listener"
  protocol        = "TCP"
  protocol_port   = 9345
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
}

resource "openstack_lb_pool_v2" "rke2" {
  name        = "${var.name_prefix}-rke2-pool"
  protocol    = "TCP"
  listener_id = openstack_lb_listener_v2.rke2.id
  lb_method   = "ROUND_ROBIN"
}

resource "openstack_lb_monitor_v2" "rke2" {
  name        = "${var.name_prefix}-rke2-monitor"
  pool_id     = openstack_lb_pool_v2.rke2.id
  type        = "TLS-HELLO"
  delay       = 5
  timeout     = 5
  max_retries = 3
}

resource "openstack_lb_member_v2" "rke2" {
  for_each      = var.lb_members
  name          = each.key
  pool_id       = openstack_lb_pool_v2.rke2.id
  address       = each.value.internal_ip
  protocol_port = 9345
  monitor_port  = 6443
}


resource "openstack_networking_floatingip_v2" "loadbalancer" {
  pool = var.floating_network
}

resource "openstack_networking_floatingip_associate_v2" "loadbalancer" {
  floating_ip = openstack_networking_floatingip_v2.loadbalancer.address
  port_id     = openstack_lb_loadbalancer_v2.loadbalancer.vip_port_id
}
