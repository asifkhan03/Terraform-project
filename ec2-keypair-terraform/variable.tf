variables "region_name"{
    description = "region in which EC2 will be created"
    type = string
    default=  "us-east-1"
}

variable "ami_id" {
  default = "ami-084568db4383264d4"  # Replace with your desired AMI ID
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "your-key-pair"  # Replace with your key pair name
}
