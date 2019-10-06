#
# Terraform
#

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_ami" "simple_sinatra_app" {
  most_recent = true
  owners      = [data.aws_caller_identity.current.account_id]

  filter {
    name   = "name"
    values = ["simple-sinatra-app*"]
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.ssh_key_name
  public_key = file("${var.ssh_public_key_path}")
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_subnet
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.default_name}-vpc"
    },
  )
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.default_name}-internet_gateway"
    },
  )
}

resource "aws_subnet" "subnets" {
  vpc_id            = aws_vpc.vpc.id
  count             = length(var.subnets)
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.subnets, count.index)

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.default_name}-subnet-${element(var.availability_zones, count.index)}"
    },
  )
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.default_name}-route-table"
    },
  )
}

resource "aws_route_table_association" "route_table_associations" {
  count          = length(var.subnets)
  subnet_id      = element(aws_subnet.subnets.*.id, count.index)
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "instance_security_group" {
  name   = "${var.default_name}-instance-security-group"
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.default_name}-instance-security-group"
    },
  )
}

data "http" "ip" {
  url = "http://api.ipify.org"
}

locals {
  host_ip_cidr              = ["${data.http.ip.body}/32"]
  ssh_ingress_ip_whitelist  = "${length(var.ssh_ingress_ip_whitelist) != 0 ? var.ssh_ingress_ip_whitelist : local.host_ip_cidr}"
  icmp_ingress_ip_whitelist = "${length(var.icmp_ingress_ip_whitelist) != 0 ? var.icmp_ingress_ip_whitelist : local.host_ip_cidr}"
}

# Allow all egress.
resource "aws_security_group_rule" "all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance_security_group.id
}

# Allow reflexive ingress.
resource "aws_security_group_rule" "reflexive_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.instance_security_group.id
  security_group_id        = aws_security_group.instance_security_group.id
}

# Allow SSH connections from whitelisted IPs.
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = local.ssh_ingress_ip_whitelist
  security_group_id = aws_security_group.instance_security_group.id
}

# Allow specific ICMP messages from whitelisted IPs to instances.
resource "aws_security_group_rule" "echo_ingress" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "ICMP"
  cidr_blocks       = local.icmp_ingress_ip_whitelist
  security_group_id = aws_security_group.instance_security_group.id
}

# Allow specific ICMP messages from whitelisted IPs to instances.
resource "aws_security_group_rule" "echo_reply_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "ICMP"
  cidr_blocks       = local.icmp_ingress_ip_whitelist
  security_group_id = aws_security_group.instance_security_group.id
}

# Allow specific ICMP messages from whitelisted IPs to instances.
resource "aws_security_group_rule" "destination_unreachable_ingress" {
  type              = "ingress"
  from_port         = 3
  to_port           = 0
  protocol          = "ICMP"
  cidr_blocks       = local.icmp_ingress_ip_whitelist
  security_group_id = aws_security_group.instance_security_group.id
}

# Allow specific ICMP messages from whitelisted IPs to instances.
resource "aws_security_group_rule" "time_exceeded_ingress" {
  type              = "ingress"
  from_port         = 11
  to_port           = 0
  protocol          = "ICMP"
  cidr_blocks       = local.icmp_ingress_ip_whitelist
  security_group_id = aws_security_group.instance_security_group.id
}

resource "aws_security_group" "loadbalancer_security_group" {
  name   = "${var.default_name}-loadbalancer-security-group"
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.default_name}-loadbalancer-security-group"
    },
    )
}

# Allow HTTP connections from from whitelisted IPs.
resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = var.http_ingress_ip_whitelist
  security_group_id = aws_security_group.loadbalancer_security_group.id
}

# Allow HTTP connections from instances to loadbalancers.
resource "aws_security_group_rule" "instance_loadbalancer_http_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.instance_security_group.id
  security_group_id        = aws_security_group.loadbalancer_security_group.id
}

# Allow HTTP connections from loadbalancers to instances.
resource "aws_security_group_rule" "loadbalancer_instance_http_instance" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.loadbalancer_security_group.id
  security_group_id        = aws_security_group.instance_security_group.id
}

# Allow HTTP connections from loadbalancers to instances.
resource "aws_security_group_rule" "loadbalancer_instance_http_egress" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.instance_security_group.id
  security_group_id        = aws_security_group.loadbalancer_security_group.id
}

resource "aws_lb" "alb" {
  name                       = "${var.default_name}-loadbalancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.loadbalancer_security_group.id]
  subnets                    = aws_subnet.subnets.*.id
  enable_deletion_protection = false

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.default_name}-loadbalancer"
    },
  )
}

resource "aws_lb_target_group" "target_group" {
  name     = "${var.default_name}-target-group"
  vpc_id   = aws_vpc.vpc.id
  protocol = "HTTP"
  port     = 80

  health_check {
    path = var.health_check_path
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }
}

resource "aws_launch_template" "launch_template" {
  name                   = "${var.default_name}-launch-template"
  image_id               = data.aws_ami.simple_sinatra_app.id
  key_name               = var.ssh_key_name
  instance_type          = var.instance_type

  network_interfaces {
    security_groups             = aws_security_group.instance_security_group.*.id
    associate_public_ip_address = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.instance_root_volume_size
      volume_type = "gp2"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.default_tags,
      {
        "Name" = "${var.default_name}-instance"
      },
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  launch_template_version = "${var.launch_template_version != "" ? var.launch_template_version : aws_launch_template.launch_template.latest_version}"
}

# Use a cloudformation stack to achieve rolling updates.
# See: https://www.joshdurbin.net/posts/2018-05-auto-scaling-rollout-on-aws-with-terraform/
resource "aws_cloudformation_stack" "rolling_update_asg" {
  name = "${var.default_name}-autoscaling-group-cloudformation-stack"

  parameters = {
    AvailabilityZones     = join(",", var.availability_zones)
    LaunchTemplateID      = aws_launch_template.launch_template.id
    LaunchTemplateVersion = local.launch_template_version
    VPCZoneIdentifier     = join(",", aws_subnet.subnets.*.id)
    TargetGroupARN        = aws_lb_target_group.target_group.arn
    MinimumCapacity       = var.instance_minimum_size
    MaximumCapacity       = var.instance_maximum_size
  }

  template_body = <<STACK
{
  "Description": "Autoscaling Group Cloudformation Template",
  "Parameters": {
    "AvailabilityZones": {
      "Type": "CommaDelimitedList",
      "Description": "Availability zones for the ASG"
    },
    "LaunchTemplateID": {
      "Type": "String",
      "Description": "Launch template ID for the ASG"
    },
    "LaunchTemplateVersion": {
      "Type": "String",
      "Description": "Launch template version for the ASG"
    },
    "VPCZoneIdentifier": {
      "Type": "CommaDelimitedList",
      "Description": "VPC subnet IDs for the ASG"
    },
    "TargetGroupARN": {
      "Type": "String",
      "Description": "The ARN of the target group for the ASG"
    },
    "MaximumCapacity": {
      "Type": "String",
      "Description": "The maximum desired capacity size"
    },
    "MinimumCapacity": {
      "Type": "String",
      "Description": "The minimum and initial desired capacity size"
    }
  },
  "Resources": {
    "ASG": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": { "Ref": "AvailabilityZones" },
        "LaunchTemplate": {
          "LaunchTemplateId": { "Ref": "LaunchTemplateID" },
          "Version": { "Ref": "LaunchTemplateVersion" }
        },
        "VPCZoneIdentifier": { "Ref": "VPCZoneIdentifier" },
        "TargetGroupARNs": [
          { "Ref": "TargetGroupARN" }
        ],
        "MaxSize": { "Ref": "MaximumCapacity" },
        "MinSize": { "Ref": "MinimumCapacity" },
        "DesiredCapacity": { "Ref": "MinimumCapacity" },
        "TerminationPolicies": [ "OldestLaunchConfiguration", "OldestInstance" ],
        "HealthCheckType": "ELB",
        "MetricsCollection": [
          {
            "Granularity": "1Minute",
            "Metrics": []
          }
        ],
        "HealthCheckGracePeriod": "300",
        "Tags": []
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "1",
          "MaxBatchSize": "1",
          "PauseTime": "PT1M"
        }
      }
    }
  }
}
STACK
}

