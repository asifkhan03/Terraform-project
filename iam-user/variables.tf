variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "user_name" {
  description = "IAM user name to be created"
  type        = string
  default     = "asif"
}
