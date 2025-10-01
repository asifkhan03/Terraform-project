# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets of the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for the ALB
resource "aws_security_group" "alb" {
  name   = "brew-example-alb"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Security Group for EC2 instances in ASG
resource "aws_security_group" "instance" {
  name   = "brew-example-instance"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # only allow traffic from ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Application Load Balancer
resource "aws_lb" "example" {
  name               = "brew-alb-example"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

# Target Group for ALB
resource "aws_lb_target_group" "example" {
  name     = "brew-alb-tg"
  port     = var.server_port   # EC2 instance port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    port                = var.server_port
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


# Listener for ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port               = var.elb_port
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}


resource "aws_launch_template" "example" {
  name_prefix   = "brew-example-lt"
  image_id      = "ami-02d26659fd82cf299"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2

              # Configure Apache to listen on ${var.server_port}
              echo "Listen ${var.server_port}" >> /etc/apache2/ports.conf
              sed -i "s/:80>/:${var.server_port}>/g" /etc/apache2/sites-enabled/000-default.conf

              cat <<EOT > /var/www/html/index.html
              <html>
                  <body>
                      <h1 style="font-size:50px;color:blue;">Brew Labs "Asif"</h1>
                  </body>
              </html>
              EOT

              systemctl restart apache2
              systemctl enable apache2
              EOF
)
}

# Auto Scaling Group using Launch Template
resource "aws_autoscaling_group" "example" {
  name                = "brew-example-asg"
  min_size            = 3
  max_size            = 8
  desired_capacity    = 3
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns   = [aws_lb_target_group.example.arn]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "BREW"
    propagate_at_launch = true  
  }
}

