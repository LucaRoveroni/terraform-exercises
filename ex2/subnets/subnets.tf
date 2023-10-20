/*
    Define Subnets for VPC 1
*/
// Private subnet in AZ1
resource "aws_subnet" "private-1" {
  vpc_id = "${aws_vpc.vpc-1}"
  cidr_block = "10.0.0.0/17"
  availability_zone = "${AWS_REGION}a"

  tags = {
    name = "private-1"
  }
}

// Private subnet in AZ2
resource "aws_subnet" "private-2" {
  vpc_id = "${aws_vpc.vpc-1}"
  cidr_block = "10.0.128.0/17"
  availability_zone = "${AWS_REGION}b"

  tags = {
    name = "private-2"
  }
}

/*
    Define Subnets for VPC 2
*/
// Public subnet in AZ1
resource "aws_subnet" "public-1" {
  vpc_id = "${aws_vpc.vpc-2}"
  cidr_block = "10.0.0.0/17"
  map_public_ip_on_launch = "true"
  availability_zone = "${AWS_REGION}a"

  tags = {
    name = "public-1"
  }
}

// Public subnet in AZ2
resource "aws_subnet" "public-2" {
  vpc_id = "${aws_vpc.vpc-2}"
  cidr_block = "10.0.128.0/17"
  map_public_ip_on_launch = "true"
  availability_zone = "${AWS_REGION}b"

  tags = {
    name = "public-2"
  }
}
