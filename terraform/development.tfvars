#
# Terraform variables
#

# A default name used as a basis for naming resources
default_name = "simple-sinatra-app"

# Tags common to all resources
default_tags = {
  Environment = "development"
}

# Whitelist of subnets to allow HTTP requests from
http_ingress_ip_whitelist = ["0.0.0.0/0"]

# Name of the default SSH key added to all instances
ssh_key_name = "packer"

# Path to the public SSH key added to instances
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Subnet of the VPC
vpc_subnet = "10.0.0.0/16"

# AWS region
region = "ap-southeast-2"

# AWS availability zones
availability_zones = ["ap-southeast-2a","ap-southeast-2b"]

# Subnets
subnets = ["10.0.0.0/21","10.0.8.0/21"]

# Starting number of instances
instance_minimum_size = "1"

# Starting number of instances
instance_maximum_size = "2"

# Instance type
instance_type = "t2.nano"

# Bastion instance root volume size in GB
instance_root_volume_size = "16"
