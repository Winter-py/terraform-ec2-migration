terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}



# Retrieve attributes of existing EC2 instance
data "aws_instance" "existing_instance" {
  instance_id = "${var.instance_id}"
}

data "aws_eip" "by_public_ip" {
public_ip = data.aws_instance.existing_instance.public_ip
}

data "aws_ami" "packer"{
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["${var.Name}-migrated-app"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  } 
}

# Create a new EC2 instance with the same configuration as the existing instance
resource "aws_instance" "new_instance" {
  ami             = data.aws_ami.packer.id
  instance_type   = data.aws_instance.existing_instance.instance_type
  key_name        = data.aws_instance.existing_instance.key_name
  subnet_id       = data.aws_instance.existing_instance.subnet_id
  vpc_security_group_ids = data.aws_instance.existing_instance.vpc_security_group_ids
  iam_instance_profile   = "Migration_Instance_Role"

    root_block_device {
    encrypted = true
    }

    tags = data.aws_instance.existing_instance.tags

}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.new_instance.id
  allocation_id = data.aws_eip.by_public_ip.id
}