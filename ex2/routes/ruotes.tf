/*
    Define ROUTE TABLES
    Define generic permissions for public and private subnets
*/
// Route table for TGW VPC 2
resource "aws_route_table" "public-to-tgw" {
  vpc_id = aws_vpc.vpc-2.id

  route = [
    {
        cidr_block = "10.2.0.0/16"
        gateway_id = "${aws_internet_gateway.igw-vpc-2.id}"
    },
    {
      cidr_block = "10.1.0.0/16"
      gateway_id = "${aws_nat_gateway.nat-vpc-1.id}"
    }
  ]

  tags = {
    name = "public-to-tgw"
  }
}

// Route table for TGW VPC 1
resource "aws_route_table" "private-to-tgw" {
  vpc_id = aws_vpc.vpc-1.id
  tags = {
    name = "private-to-tgw"
  }
}

// Create route to transist gateway for VPC 1
resource "aws_route" "tgw-route-vpc-1" {
  route_table_id = aws_route_table.private-to-tgw.id
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  depends_on = [aws_ec2_transit_gateway.tgw]
}

// Create route to transist gateway for VPC 2
resource "aws_route" "tgw-route-vpc-2" {
  route_table_id = aws_route_table.public-to-tgw.id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  depends_on = [aws_ec2_transit_gateway.tgw]
}

/*
    Define ROUTE ASSOCIATIONS
    Assign permissions to existing subnets
*/
resource "aws_route_table_association" "subnet-public-tgw-1" {
  subnet_id = "${aws_subnet.public-1.id}"
  route_table_id = "${aws_route_table.public-to-tgw.id}"
}

resource "aws_route_table_association" "subnet-public-tgw-2" {
  subnet_id = "${aws_subnet.public-2.id}"
  route_table_id = "${aws_route_table.public-to-tgw.id}"
}

resource "aws_route_table_association" "subnet-private-tgw-1" {
  subnet_id = "${aws_subnet.private-1.id}"
  route_table_id = "${aws_route_table.private-to-tgw.id}"
}

resource "aws_route_table_association" "subnet-private-tgw-2" {
  subnet_id = "${aws_subnet.private-1.id}"
  route_table_id = "${aws_route_table.private-to-tgw.id}"
}