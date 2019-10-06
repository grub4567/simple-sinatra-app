#
# Terraform variables
#

variable launch_template_version {
  description = "The launch template version to deploy, defaults to false which causes the latest version to be deployed"
  default     = ""
}

variable default_name {
  description = "A default name used as a basis for naming resources"
}

variable default_tags {
  description = "Tags common to all resources"
}

variable ssh_ingress_ip_whitelist {
  description = "Whitelist of subnets to allow SSH access from"
  type        = "list"
}

variable icmp_ingress_ip_whitelist {
  description = "Whitelist of subnets to allow ICMP messages from"
  type        = "list"
}

variable http_ingress_ip_whitelist {
  description = "Whitelist of subnets to allow HTTP requests from"
  type        = "list"
}

variable ssh_key_name {
  description = "Name of the SSH key added to instances"
}

variable ssh_public_key_path {
  description = "Path to the public SSH key added to instances"
}

variable vpc_subnet {
  description = "Subnet of the VPC"
}

variable region {
  description = "AWS region"
}

variable availability_zones {
  description = "AWS availability zones"
  type        = "list"
}

variable subnets {
  description = "Subnets"
  type        = "list"
}

variable instance_minimum_size {
  description = "Starting number of instances"
}

variable instance_maximum_size {
  description = "Starting number of instances"
}

variable instance_type {
  description = "Instance type"
}

variable instance_root_volume_size {
  description = "Instance root volume size in GB"
}

variable health_check_path {
  description = "Path for health checks"
  default     = "/"
}
