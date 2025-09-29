resource "tls_private_key" "test-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# save the file key locally
resource "local_file" "private_key" {
  filename        = "./mykey.pem"
  content         = tls_private_key.test-key.private_key_pem
  file_permission = "0600"
}

# create an AWS key pair from the generated public key
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.test-key.public_key_openssh
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = "MyEC2Instance"
  }
}
