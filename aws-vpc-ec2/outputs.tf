output "public_instance_ip" {
  value = aws_instance.server.public_ip
}

output "private_subnet_id" {
  value = aws_subnet.private_ap_south_1b.id
}
