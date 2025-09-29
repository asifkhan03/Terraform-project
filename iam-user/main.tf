# Create IAM user
resource "aws_iam_user" "this" {
  name = var.user_name
}

# Create access keys for the IAM user
resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

# Attach AdministratorAccess policy to the IAM user
resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.this.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
