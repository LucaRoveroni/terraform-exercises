/*
    Define VPC 1
    Its subnets are spread onto 2 AZs eu-north-1a/b
*/
resource "aws_vpc" "vpc-1" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = "true"
    tags = {
        name = "vpc-1"
    }
}

/*
    Define VPC 2
    Its subnets are spread onto 2 AZs eu-north-1a/b
*/
resource "aws_vpc" "vpc-2" {
    cidr_block = "10.2.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = "true"
    tags = {
        name = "vpc-2"
    }
}