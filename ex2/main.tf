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
    Define Internet Gateways
*/
// IGW for VPC 2
resource "aws_internet_gateway" "igw-vpc-2" {
    vpc_id = "${aws_vpc.vpc-2}"

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
  depends_on = [ "aws_internet_gateway.igw-vpc-2" ]
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
  name       = "alb-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.vpc-1.id
  slow_start = 0

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

resource "aws_lb_target_group_attachment" "alb_tg_attach" {
  for_each = aws_instance.alb_tg

  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = each.value.id
  port             = 8080
}

resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_tg.id]

  subnets = [
    aws_subnet.public-1.id,
    aws_subnet.public-2.id
  ]
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