/*
    Define Security Groups
    for private EC2 instances running webservers accessible only via ALB
*/

// For private subnets (only ingress from VPC 2)
resource "aws_security_group" "only-vpc-2" {
    vpc_id = "${aws_vpc.vpc-1.id}"
    name = "only-vpc-2"
    description = "Security group that allows only ingress/egress traffic from/to VPC 2"

    tags = {
      name = "only-vpc-2"
    }
}

// For Application Load Balancer in VPC 2
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.vpc-2.id
}

// Specific ingress/egress role for ALB in VPC 2
resource "aws_security_group_rule" "ingress_alb_traffic" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "engress_ec2_traffic" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.only-vpc-2.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ingress_ec2_health_check" {
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.only-vpc-2.id
  source_security_group_id = aws_security_group.alb_sg.id
}