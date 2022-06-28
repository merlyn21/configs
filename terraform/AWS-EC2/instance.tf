resource "aws_instance" "instance" {

  ami           = data.aws_ami.ami.id
  instance_type = local.instance_type
  # vpc_security_group_ids = [aws_security_group.ssh-http.id]
  key_name  = "deployer-key"
  user_data = file("user-data/instance.sh")

  network_interface {
    network_interface_id = aws_network_interface.interface.id
    device_index         = 0

  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 40
  }

  tags = {
    Name    = format("%s-%s", local.name, local.project_name)
    Project = local.project_name
  }
}

resource "aws_network_interface" "interface" {
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.ssh-http.id]

  tags = {
    Name    = format("NIC-%s-%s", local.name, local.project_name)
    Project = local.project_name
  }
}

resource "aws_eip" "lb" {
  instance = aws_instance.instance.id
  vpc      = true
  tags = {
    Name    = format("eip-%s-%s", local.name, local.project_name)
    Project = local.project_name
  }
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [local.ami]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("keys/key.pub")
  tags = {
    Name    = format("key-%s-%s", local.name, local.project_name)
    Project = local.project_name
  }
}
