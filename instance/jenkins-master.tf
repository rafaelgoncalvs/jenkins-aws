provider "aws" {
  region = "ap-southeast-2"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_ami" "jenkins-master" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["jenkins-master-2.190.1"]
  }
}

resource "aws_vpc" "jenkinns_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "jenkins_vpc"
    Author = "rafaelgoncalvs"
    Tool   = "Terraform"
  }
}

resource "aws_internet_gateway" "jenkins_gw" {
  vpc_id = "${aws_vpc.jenkinns_vpc.id}"

  tags = {
    Name   = "jenkins_gateway"
    Author = "rafaelgoncalvs"
    Tool   = "Terraform"
  }
}

resource "aws_subnet" "jenkins_subnet" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "${cidrsubnet(aws_vpc.jenkinns_vpc.cidr_block, 3, 1)}"
  vpc_id            = "${aws_vpc.jenkinns_vpc.id}"

  tags = {
    Name   = "jenkins_subnet"
    Author = "rafaelgoncalvs"
    Tool   = "Terraform"
  }
}

resource "aws_route_table" "jenkins-route-table" {
  vpc_id = "${aws_vpc.jenkinns_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jenkins_gw.id}"
  }
  
  tags = {
    Name   = "jenkins_gateway"
    Author = "rafaelgoncalvs"
    Tool   = "Terraform"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.jenkins_subnet.id}"
  route_table_id = "${aws_route_table.jenkins-route-table.id}"
}

resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins_master_sg"
  description = "Allow traffic on port 8080 and enable SSH"
  vpc_id      = "${aws_vpc.jenkinns_vpc.id}"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "jenkins_master_sg"
    Author = "nexus-user-conference"
    Tool   = "Terraform"
  }
}

resource "aws_instance" "jenkins_master" {
  ami             = "${data.aws_ami.jenkins-master.id}"
  instance_type   = "t2.micro"
  key_name        = "aws"
  security_groups = ["${aws_security_group.jenkins_master_sg.id}"]
  subnet_id       = "${aws_subnet.jenkins_subnet.id}"

  #   connection {
  #       user = "ec2-user"
  #       private_key = "${file(var.private_key_path)}"
  #   }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = false
  }

  tags = {
    Name   = "jenkins_master"
    Author = "rafaelgoncalvs"
    Tool   = "Terraform"
  }
}

resource "aws_eip" "this" {
  vpc      = true
  instance = "${aws_instance.jenkins_master.id}"
}

output "aws_instance_public_dns" {
  value = "${aws_instance.jenkins_master.public_dns}"
}
