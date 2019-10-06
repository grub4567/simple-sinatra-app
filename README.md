# REA Systems Engineer practical task

# Overview
The application will be deployed into AWS. A Packer template is used to create a Amazon Machine
Image (AMI) containing the application, served using Puma and NGINX. Terraform scripts provision
the AWS infrastructure including servers based on this AMI. The AWS infrastructure includes an
Autoscaling group to provide robustness and rolling deployments of new AMIs.

## Packer Template
The Packer template is in the `./packer` subdirectory.  It creates a Ubuntu 18.04 LTS AMI containing
the application, served by Puma and NGINX. Puma serves the application up to a unix socket which
NGINX reverse proxies HTTP/80 to. A systemd unit for Puma is provided to ensure that Puma restarts
if there is a failure. The Puma config, NGINX config and Puma systemd unit file are found in the
  `./packer` subdirectory. The AMI is configured using a small POSIX shell script.

## AWS Infrastructure
- The AMI for the application server.
- A SSH keypair.
- A VPC.
- Two subnets in the VPC, in 2 different AZs.
- An internet gateway and a route table connecting the subnets to the internet gateway.
- Security groups:
  - One for the application servers. It allows SSH and ICMP access from the machine that the
    Terraform is run on. It also allows HTTP from the loadbalancer security group.
  - One for a loadbalancer. It allows HTTP from anywhere and HTTP to the application server security
    group.
- An Application loadbalancer:
  - With a target group targeting http/80.
  - With a listener on http/80 forwarding to the target group.
- A launch template for the application servers using the AMI and the SSH key.
- An autoscaling group using the launch template and the loadbalancer target group. The autoscaling
  group is provisioned by Terraform but via Cloudformation to provide rolling deployments of new
  AMIs. See
  [here](https://www.joshdurbin.net/posts/2018-05-auto-scaling-rollout-on-aws-with-terraform/) for
  more information.

## AWS Infrastructure Diagram
Note: While the diagram shows servers in both AZs, there will only be a single server in one AZ
or the other with the current autoscaling settings.
![diagram](/images/diagram.png)

# Usage

## Prerequisites
- A POSIX shell environment, including:
  - [Terraform](https://www.terraform.io/downloads.html) (version 0.12 or higher).
  - [Packer](https://www.packer.io/downloads.html)
  - [AWS CLI](https://aws.amazon.com/cli/)
  - make
  - curl
- Credentials to an AWS account which the infrastructure will be deployed into.
  - The credential's user should have administrator access (a minimal IAM policy is required, see
    shortcomings).
  - The AWS account needs a default VPC for Packer to run in.
  - The credentials need only to be available as the default AWS credentials in your
    environment. You can follow the guide [here](https://aws.amazon.com/cli/) to configure
    your environment.
- A SSH keypair for accessing the servers.

## Quick
- Clone the repo:
```sh
$ git clone TODO simple-sinatra-app
$ cd simple-sinatra-app
```
- The Packer template is in the `./packer` directory and the Terraform scripts in `./terraform`.
  The Packer template should be run first, then the Terraform. To run the Packer template:
```sh
$ make packer
make -C packer build
make[1]: Entering directory '/home/user/workspace/simple-sinatra-app/packer'
packer build \
	-var=host_ip=1.2.3.4 \
	-force \
	packer.json \
	| tee output
amazon-ebs output will be in this color.

SNIP 

Build 'amazon-ebs' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
ap-southeast-2: ami-03e6631931f7a0292

make[1]: Leaving directory '/home/user/workspace/simple-sinatra-app/packer'
```
- You should now have an AMI of the application server in your AWS account.
- Review the Terraform variables. In particular, review the variable which is the path to the
  public SSH key which will be added to the application servers and make sure it is correct.
  By default it is `~/.ssh/id_rsa.pub`. The provided values of the other variable will work fine
  but feel free to customize them. Review the Terraform variables with:
```sh
$ $EDITOR ./terraform/development.tfvars
```
- Run the Terraform. When running the Terraform, review the plan and enter 'yes' to confirm when
  prompted. To run the Terraform:
```sh
$ make terraform
 simple-sinatra-app > make terraform
make -C terraform apply
make[1]: Entering directory '/home/luther/workspace/personal/simple-sinatra-app/terraform'
terraform init

Initializing the backend...

Initializing provider plugins...

SNIP

Terraform has been successfully initialized!

SNIP

if ! terraform workspace list | grep development; then \
	terraform workspace new development; \
fi
* development
terraform workspace select development
terraform apply -var-file=development.tfvars

SNIP

Terraform will perform the following actions:

SNIP

Plan: 26 to add, 0 to change, 0 to destroy.

Do you want to perform these actions in workspace "development"?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

SNIP

Apply complete! Resources: 26 added, 0 changed, 0 destroyed.

Outputs:

domain = simple-sinatra-app-loadbalancer-584191826.ap-southeast-2.elb.amazonaws.com
make[1]: Leaving directory '/home/user/workspace/simple-sinatra-app/terraform'
```
- The application server should come up and be accessible on the loadbalancer domain
  name output by the Terraform command. It might take a minute or so to be accessable:
```sh
$ curl simple-sinatra-app-loadbalancer-584191826.ap-southeast-2.elb.amazonaws.com; echo
Hello World!
```

## Makefiles
There are more usage options provided as targets in the Makefiles in the `./packer` and
`./terraform` directories. Please view the Makefiles, which have comments, for more instructions.

## Destroying
To destroy the infrastructure:
```sh
$ make terraform.destroy

 simple-sinatra-app > make terraform.destroy
make -C terraform destroy
make[1]: Entering directory '/home/luther/workspace/personal/simple-sinatra-app/terraform'

SNIP

Plan: 0 to add, 0 to change, 26 to destroy.

Do you really want to destroy all resources in workspace "development"?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

SNIP

Destroy complete! Resources: 26 destroyed.
make[1]: Leaving directory '/home/luther/workspace/personal/simple-sinatra-app/terraform'
```
There is a bug where destruction may hang on deleting a security group. Delete the last remaining
network interface using the AWS console if this happens.

## Rolling Updates
You can rebuild the AMI and perform a rolling update by:
- Changing the application (and changing the check in the Packer template's configure script
  if needed).
- Rebuilding the AMI with Packer. It will create a new, additional AMI.
- Running the Terraform again. It will roll out the latest AMI. The Cloudformation Stack managing
  the autoscaling group will manage the rolling update.

# Design

## Assumptions
I assumed that the target user would be a typical infrastructure/cloud/devops developer who would
be using a POSIX shell, be able to furnish themselves with the required tools (Terraform and Packer)
and have an AWS account to deploy the application into.

## Design Choices
I wanted to demonstrate that I could build a simple and typical AWS deployment using common-place
tools. As such, I used Terraform to provision the required infrastructure, as Terraform is fairly
ubiquitous, simple and provides idempotency. I avoided using Kubernetes as it could be seen as
too heavy for a simple application. I wanted the application server to be deployed as an immutable
artifact, hence the use of Packer. An autoscaling group in AWS was used for anti-fragility. I
wanted to exhibit a mechanism for performing rolling updates of the application server also for
the sake of anti-fragility and idempotency. A shell script was used in the Packer template
instead of something like Ansible to try and keep the project simple.

## Major Shortcomings
- HTTPS would be great! This would require the AWS account to have control over a domain name to
  achieve.
- The application instances have public IPs, which is not ideal. Adding bastion instances
  (dedicated SSH proxies) would increase security by allowing the application instances to not
  have public IPs.
- An IAM policy containing the minimal permissions for being able to provision the infrastruture
  would be ideal.
- Some automation for getting the prerequisites (like a script or a Docker container) would be
  nice.
- The Terraform state is not remote.

## Further Features
These are the essential features that I would have continued developing if taking the project
further. Some address the previously mentioned shortcomings and others are there for completeness.

### HTTPS
HTTPS could be easily added using AWS's Certificate manager and Route 53. It would require a
domain name controlled by a Route 53 hosted zone in the target AWS account as a prerequisite.

### SSH bastion Instances
Instances dedicated to proxying SSH to the application instances could be added. This would allow
the application instances to not have public IPs, increasing security by protecting against
mistakes made on the application instance's firewalls.

### Script or Docker image to check for and download prerequisites
A script to download Terraform and Packer for the user or a Docker image containing them would be
nice.

### Terraform remote state bucket
Currently, the Terraform state is saved locally. It would be ideal to move the Terraform state into
an S3 bucket and to provide a script to provision this bucket and set up the Terraform backend.

### Black Box Monitoring
Adding black box monitoring of the application using a service external to AWS such as Status Cake
could be added providing monitoring decoupled from AWS.

### Cloudwatch Alerting
Cloudwatch alerts triggered by failed instance status checks, loadbalancer 5XX responses and
autoscaling actions could be added.

### CI
Adding continuous integration to build the Packer template and to plan and deploy the Terraform
(with manual steps where appropriate) would allow the infrastructure to be managed from a Web UI.
Care would be needed to ensure that any secret AWS credentials were managed correctly in the CI
server.


**Thanks for reviewing**
