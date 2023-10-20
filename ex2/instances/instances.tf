/*
    Define AWS EC2
    I chose two httpd web servers that exposes a simple HTML file showing their EC2 IP address
*/
resource "aws_instance" "private-webserver-1" {
  ami = "${AWS_UBUNTU_AMI}"
  instance_type = "t2.micro"
  security_groups = [ "${aws_security_group.only-vpc-2.id}" ]
  subnet_id = "${aws_subnet.private-1.id}"
  user_data = file("setup_apache.sh")
}

resource "aws_instance" "private-webserver-2" {
  ami = "${AWS_UBUNTU_AMI}"
  instance_type = "t2.micro"
  security_groups = [ "${aws_security_group.only-vpc-2.id}" ]
  subnet_id = "${aws_subnet.private-2.id}"
  user_data = file("setup_apache.sh")
}