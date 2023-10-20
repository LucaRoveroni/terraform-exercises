//
// Exercise #1 with Terraform
// Project created by Luca Roveroni
// STORM Reply srl - 17/10/2023
//

// Define cloud provider
provider "aws" {
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
    region = var.AWS_REGION
}

/*
    Define VPC
*/
resource "aws_vpc" "vpc_es1" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = "true"
    tags = {
        name = "vpc-es1"
    }
}

/*
    Define SUBNETS
    4 in total --> 2 privates and 2 public in 2 AZ
*/
// Public subnet AZ1
resource "aws_subnet" "az1-public" {
  vpc_id = "${aws_vpc.vpc_es1}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "${AWS_REGION}a"

  tags = {
    name = "subnet-public-1"
  }
}

// Private subnet AZ1
resource "aws_subnet" "az1-private" {
  vpc_id = "${aws_vpc.vpc_es1}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "${AWS_REGION}a"

  tags = {
    name = "subnet-private-1"
  }
}

// Public subnet AZ2
resource "aws_subnet" "az2-public" {
  vpc_id = "${aws_vpc.vpc_es1}"
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "${AWS_REGION}b"

  tags = {
    name = "subnet-public-2"
  }
}

// Private subnet AZ2
resource "aws_subnet" "az2-private" {
  vpc_id = "${aws_vpc.vpc_es1}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "${AWS_REGION}b"

  tags = {
    name = "subnet-private-2"
  }
}

/*
    Define INTERNET GATEWAY
*/
resource "aws_internet_gateway" "igw_es1" {
    vpc_id = "${aws_vpc.vpc_es1}"

    tags = {
        name = "igw-es1"
    }
}

/*
    Define NAT GATEWAYS
    One for each public subnet
*/
resource "aws_eip" "nat-az1" {}
resource "aws_eip" "nat-az2" {}

resource "aws_nat_gateway" "nat-sub1" {
  allocation_id = "${aws_eip.nat-az1.id}"
  subnet_id = "${aws_subnet.subnet-public-1.id}"
  depends_on = [ "aws_internet_gateway.igw-es1" ]
}

resource "aws_nat_gateway" "nat-sub2" {
  allocation_id = "${aws_eip.nat-az2.id}"
  subnet_id = "${aws_subnet.subnet-public-2.id}"
  depends_on = [ "aws_internet_gateway.igw-es1" ]
}

/*
    Define ROUTE TABLES
    Define generic permissions for public and private subnets
*/
resource "aws_route_table" "public-subnets" {
  vpc_id = var.aws_vpc.vpc_es1
  route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw-es1}"
  }

  tags = {
    Name = "public-subnets-rt"
  }
}

resource "aws_route_table" "private-subnets" {
  vpc_id = var.aws_vpc.vpc_es1
  route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.nat-es1.id}"
  }

  tags = {
    Name = "private-subnets-rt"
  }
}

/*
    Define ROUTE ASSOCIATIONS
    Assign permissions to existing subnets
*/
// Traffic for PUB SUB AZ1
resource "aws_route_table_association" "subnet-public-1" {
  subnet_id = "${aws_subnet.subnet-public-1.id}"
  route_table_id = "${aws_route_table.public-subnets-rt.id}"
}
// Traffic for PUB SUB AZ2
resource "aws_route_table_association" "subnet-public-2" {
  subnet_id = "${aws_subnet.subnet-public-2.id}"
  route_table_id = "${aws_route_table.public-subnets-rt.id}"
}
// Traffic for PRIV SUB AZ1
resource "aws_route_table_association" "subnet-private-1" {
  subnet_id = "${aws_subnet.subnet-private-1.id}"
  route_table_id = "${aws_route_table.private-subnets-rt}"
}
// Traffic for PRIV SUB AZ2
resource "aws_route_table_association" "subnet-private-2" {
  subnet_id = "${aws_subnet.subnet-private-2.id}"
  route_table_id = "${aws_route_table.private-subnets-rt}"
}

/*
    Define AWS EC2
*/
// Bastion EC2 for subnet in AZ1
resource "aws_instance" "bastion-az1" {
  ami = "${AWS_UBUNTU_AMI}"
  instance_type = "t2.micro"

  subnet_id = "${aws_subnet.subnet-public-1.id}"
  vpc_security_group_ids = [ "${aws_sercurity_group.allow-everything.id}" ]
}

// Bastion EC2 for subnet in AZ2
resource "aws_instance" "bastion-az2" {
  ami = "${AWS_UBUNTU_AMI}"
  instance_type = "t2.micro"

  subnet_id = "${aws_subnet.subnet-public-2.id}"
  vpc_security_group_ids = [ "${aws_sercurity_group.allow-everything.id}" ]
}

// Private EC2 for subnet in AZ1
resource "aws_instance" "private-ec2-az1" {
  ami = "${AWS_UBUNTU_AMI}"
  instance_type = "t2.micro"

  subnet_id = "${aws_subnet.subnet-private-1.id}"
  vpc_security_group_ids = [ "${aws_sercurity_group.allow-bastion.id}" ]
}

// Private EC2 for subnet in AZ2
resource "aws_instance" "private-ec2-az2" {
  ami = "${AWS_UBUNTU_AMI}"
  instance_type = "t2.micro"

  subnet_id = "${aws_subnet.subnet-private-2.id}"
  vpc_security_group_ids = [ "${aws_sercurity_group.allow-bastion.id}" ]
}

/*
    Define SECURITY GROUPS
    For public and private subnets
*/
// For public subnets
resource "aws_security_group" "allow-everything" {
    vpc_id = "${aws_vpc.vpc_es1.id}"
    name = "allow-everything"
    description = "Security group that allows ssh and all egress traffic"
    egress = {
        from_port = 0
        tp_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress = {
        from_port = 0
        tp_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      name = "allow-everything"
    }
}

// For private subnets (only ingress from bastion)
resource "aws_security_group" "allow-bastion" {
    vpc_id = "${aws_vpc.vpc_es1.id}"
    name = "allow-batsion"
    description = "Security group that allows only ingress traffic from bastion"
    egress = {}

    ingress = {
        from_port = 0
        tp_port = 0
        protocol = "-1"
        cidr_blocks = ["${aws_security_group.allow-everything.id}"]
    }

    tags = {
      name = "allow-bastion"
    }
}
