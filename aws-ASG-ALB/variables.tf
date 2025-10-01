variable "server_port" {
  description = "Port on which the EC2 instance serves HTTP requests"
  type        = number
  default     = 8080
}

variable "elb_port" {
  description = "Port on which the ALB listens"
  type        = number
  default     = 80
}
