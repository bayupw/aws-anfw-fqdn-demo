# EC2 instances

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}

resource "aws_security_group" "protected_vpc_a_host_sg" {
  name        = "protected-vpc-a/sg-host"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = aws_vpc.protected_vpc_a.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.protected_vpc_a.cidr_block, aws_vpc.protected_vpc_b.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "protected-vpc-a/sg-host"
  }
}

resource "aws_instance" "protected_vpc_a_host" {
  ami                    = data.aws_ami.amazon-linux-2.id
  subnet_id              = aws_subnet.protected_vpc_a_private_subnet.id
  iam_instance_profile   = "ssm-instance-profile"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.protected_vpc_a_host_sg.id]
  tags = {
    Name = "protected-vpc-a/host"
  }
  #user_data = file("install-nginx.sh")
}

resource "aws_security_group" "protected_vpc_b_host_sg" {
  name        = "protected-vpc-b/sg-host"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = aws_vpc.protected_vpc_b.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.protected_vpc_a.cidr_block, aws_vpc.protected_vpc_b.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "protected-vpc-b/sg-host"
  }
}

resource "aws_instance" "protected_vpc_b_host" {
  ami                    = data.aws_ami.amazon-linux-2.id
  subnet_id              = aws_subnet.protected_vpc_b_private_subnet.id
  iam_instance_profile   = "ssm-instance-profile"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.protected_vpc_b_host_sg.id]
  tags = {
    Name = "protected-vpc-b/host"
  }
  #user_data = file("install-nginx.sh")
}