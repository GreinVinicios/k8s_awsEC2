# resource "aws_instance" "ec2_instance" {
resource "aws_spot_instance_request" "ec2_instance" {
  count         = 3
  ami           = var.ami
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id, aws_security_group.allow_k8s.id]
  key_name               = aws_key_pair.instance.key_name

  tags = {
    Name = "ec2-instance-${count.index}"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(tostring(data.http.myip.response_body))}/32"]
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP/s access"

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_k8s" {
  name        = "allow_k8s"
  description = "Allow K8s access"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "instance" {
  key_name   = "instance_key"
  public_key = file("~/.ssh/aws_key.pub")
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
