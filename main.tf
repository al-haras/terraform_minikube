provider "aws" {
  profile = var.profile
  region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "minikube"
  cidr = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  azs             = ["us-west-1c"]
  public_subnets = ["10.0.1.0/24"]
  
  public_subnet_tags = {
    Name = "k8s-public"
  }

  tags = {
    Terraform = "true"
    Name      = "k8s_vpc"
  }
}

module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.0.1"

  name                = "k8s"
  description         = "Allow SSH from single public IP address"
  vpc_id              = module.vpc.vpc_id
  egress_rules        = ["all-all"]
  ingress_rules       = ["ssh-tcp"]
  ingress_cidr_blocks = [join("", [chomp(data.http.icanhazip.body), "/32"])]

# This can be modified to use whatever port you are wanting to test k8s with.
#  ingress_with_cidr_blocks = [
#    {
#      from_port   = 80
#      to_port     = 80
#      protocol    = "tcp"
#      cidr_blocks = "0.0.0.0/0"
#    }
#  ]
}

resource "aws_instance" "host" {
  ami             = data.aws_ami.ubuntu.image_id
  instance_type   = "t2.medium"
  security_groups = [module.sg.this_security_group_id]
  user_data       = "${file("minikubestrap.sh")}"
  key_name        = aws_key_pair.k8s.key_name
  subnet_id       = module.vpc.public_subnets[0]
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s" {
  key_name   = "k8s"
  public_key = tls_private_key.default.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  content  = tls_private_key.default.private_key_pem
  filename = "k8s.pem"
}

resource "null_resource" "chmod" {
  depends_on = [local_file.ssh_private_key]

  provisioner "local-exec" {
    command = format("chmod 600 %s", local_file.ssh_private_key.filename)
  }
}

data "http" "icanhazip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}