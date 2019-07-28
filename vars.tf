# Define Region
variable "region" {
  description = "AWS region you want the infrastructure to be created in"
  default = "us-west-1"
}

# Define VPC CIDR Range
variable "vpc_cidr" {
  description = "CIDR range for VPC"
  default = "10.0.0.0/16"
}

variable "profile" {
  description = "Profile for AWS Credentials"
  default = "terraform"
}