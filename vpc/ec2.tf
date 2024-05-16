data "aws_ami" "lab" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

locals {
  setup_script = <<EOT
#!/bin/bash
# To connect to your EC2 instance and install the Apache web server with PHP
yum update -y
yum install -y httpd php8.1
systemctl enable httpd.service
systemctl start httpd
cd /var/www/html
wget  https://us-west-2-tcprod.s3.amazonaws.com/courses/ILT-TF-200-ARCHIT/v7.7.2.prod-4fe3faa2/lab-2-VPC/scripts/instanceData.zip
unzip instanceData.zip
EOT
}

resource "aws_instance" "public" {
  ami           = data.aws_ami.lab.id
  instance_type = "t3.micro"

  # NW
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  # FW
  security_groups = [
    aws_security_group.lab_public.id
  ]

  user_data = local.setup_script

  tags = {
    Name = "Public Instance"
  }
}

resource "aws_instance" "private" {
  ami           = data.aws_ami.lab.id
  instance_type = "t3.micro"

  # NW
  subnet_id = aws_subnet.private.id

  # FW
  security_groups = [
    aws_security_group.lab_private.id
  ]

  user_data = local.setup_script

  tags = {
    Name = "Private Instance"
  }
}
