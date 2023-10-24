//
// Exercise #2 with Terraform
// Project created by Luca Roveroni
// STORM Reply srl - 18/10/2023
//

// Define cloud provider
provider "aws" {
    profile = "TerraformAdmin"
    region = var.AWS_REGION
}

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

/*
    Define Subnets for VPC 1
*/
// Private subnet in AZ1
resource "aws_subnet" "private-1" {
  vpc_id = "${aws_vpc.vpc-1.id}"
  cidr_block = "10.1.0.0/17"
  availability_zone = "${var.AWS_REGION}a"

  tags = {
    name = "private-1"
  }
}

// Private subnet in AZ2
resource "aws_subnet" "private-2" {
  vpc_id = "${aws_vpc.vpc-1.id}"
  cidr_block = "10.1.128.0/17"
  availability_zone = "${var.AWS_REGION}b"

  tags = {
    name = "private-2"
  }
}

/*
    Define Subnets for VPC 2
*/
// Public subnet in AZ1
resource "aws_subnet" "public-1" {
  vpc_id = "${aws_vpc.vpc-2.id}"
  cidr_block = "10.2.0.0/17"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.AWS_REGION}a"

  tags = {
    name = "public-1"
  }
}

// Public subnet in AZ2
resource "aws_subnet" "public-2" {
  vpc_id = "${aws_vpc.vpc-2.id}"
  cidr_block = "10.2.128.0/17"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.AWS_REGION}b"

  tags = {
    name = "public-2"
  }
}

/*
    Route Tables for VPCs
*/
# Configuration section for route table public subnet
resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.vpc-1.id
  tags = {
    "Name" = "private-rt1"
  }
} 

# Create route table public subnet association
resource "aws_route_table_association" "private_subnet_association1" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private_subnet_rt.id
}

resource "aws_route_table_association" "private_subnet_association2" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.private_subnet_rt.id
}

# Create route to transist gateway in route table 
resource "aws_route" "tgw-route-1" {
  route_table_id         = aws_route_table.private_subnet_rt.id
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  depends_on = [ aws_ec2_transit_gateway.tgw ]
}

# Configuration section for route table public subnet2
resource "aws_route_table" "public_subnet_rt" {
  vpc_id = aws_vpc.vpc-2.id
  tags = {
    "Name" = "public-rt2"
  }
} 

# Create route table public subnet association
resource "aws_route_table_association" "public_subnet_association1" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public_subnet_rt.id
}

resource "aws_route_table_association" "public_subnet_association2" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public_subnet_rt.id
}


# Configuration section for default route to internet from public subnet
resource "aws_route" "default_route_public_subnet2" {
  route_table_id         = aws_route_table.public_subnet_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw-vpc-2.id
}

# Create route to transist gateway in route table
resource "aws_route" "tgw-route-2" {
  route_table_id         = aws_route_table.public_subnet_rt.id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  depends_on = [ aws_ec2_transit_gateway.tgw ]
}

/*
    Define AWS EC2
    I chose two httpd web servers that exposes a simple HTML file showing their EC2 IP address
*/
resource "aws_instance" "private-webserver-1" {
  ami = "${var.AWS_UBUNTU_AMI}"
  instance_type = "t3.micro"
  security_groups = [ "${aws_security_group.webserver-sg-ec2.id}" ]
  subnet_id = "${aws_subnet.private-1.id}"
  user_data = file("setup_apache.sh")
}

resource "aws_instance" "private-webserver-2" {
  ami = "${var.AWS_UBUNTU_AMI}"
  instance_type = "t3.micro"
  security_groups = [ "${aws_security_group.webserver-sg-ec2.id}" ]
  subnet_id = "${aws_subnet.private-2.id}"
  user_data = file("setup_apache.sh")
}

/*
    Define Security Groups
    for private EC2 instances running webservers accessible only via ALB
*/
resource "aws_security_group" "webserver-sg-ec2" {
  name        = "webserver-sg-ec2"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/24"]
  }
 
  tags = {
    Name = "webserver-sg-ec2" 
  }
}

/*
    Define Internet Gateways
*/
// IGW for VPC 2
resource "aws_internet_gateway" "igw-vpc-2" {
    vpc_id = "${aws_vpc.vpc-2.id}"

    tags = {
        name = "igw-vpc-2"
    }
}

/*
    Define NAT Gateway
    Specifically for private EC2 (download apache)
*/
resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "nat-vpc-1" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public-1.id}"
  depends_on = [ aws_internet_gateway.igw-vpc-2 ]
}

/*
    Define Transit Gateway
    Tutorial: https://awstip.com/aws-transit-gateway-using-terraform-fb7731e94e58
*/
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Transit Gateway with 2 VPCs"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  tags = {
    name = "tgw"
  }
}

// Attach VPC1 to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc1-attachment" {
  subnet_ids         = [aws_subnet.private-1.id, aws_subnet.private-2.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc-1.id
  tags = {
    name = "tgw-attachment-1"
  }
}

// Attach VPC2 to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc2-attachment" {
  subnet_ids         = [aws_subnet.public-1.id, aws_subnet.public-2.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc-2.id
  tags = {
    name = "tgw-attachment-2"
  }
}

/*
    Define Application Load Balancer
    and all its requirements: target group, attachment, lb and listener
    Tutorial: https://antonputra.com/amazon/create-alb-terraform/
*/
resource "aws_lb_target_group" "alb_tg" {
  name       = "ALB-TargetGroup"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.vpc-2.id

  load_balancing_algorithm_type = "round_robin"

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  health_check {
    enabled             = true
    port                = 8081
    interval            = 30
    protocol            = "HTTP"
    path                = "/health"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

// Attach ALB with one EC2 of VPC 1
resource "aws_lb_target_group_attachment" "alb_tg_attach_webserver_1" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.private-webserver-1.private_ip
  availability_zone = "all"
  port             = 8080
}

// Attach ALB with another EC2 of VPC 1
resource "aws_lb_target_group_attachment" "alb_tg_attach_webserver_2" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.private-webserver-2.private_ip
  availability_zone = "all"
  port             = 8080
}

resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.alb_sec-group.id ]

  subnets = [
    aws_subnet.public-1.id,
    aws_subnet.public-2.id
  ]
}

resource "aws_security_group" "alb-sec-group" {
  name   = "alb-sec-group"
  vpc_id = aws_vpc.vpc-2.id
}

resource "aws_security_group_rule" "ingress_alb_traffic" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb-sec-group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_alb_traffic" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb-sec-group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}