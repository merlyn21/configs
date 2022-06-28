output "ec2instance" {
  value = aws_instance.instance.public_ip
}
