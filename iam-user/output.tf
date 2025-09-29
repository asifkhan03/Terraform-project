output "access_key" {
  description = "The access key ID for the IAM user"
  value       = aws_iam_access_key.this.id
  sensitive   = true
}

output "secret_key" {
  description = "The secret access key for the IAM user"
  value       = aws_iam_access_key.this.secret
  sensitive   = true
}
