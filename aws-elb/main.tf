
# Get the List of availability_zone in the current region

data "aws_availability_zones" "all" {}

# SG for the ELB

resource "aws_security_group" "elb" {
    name        = "brew-example-elb"

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}


# SG for each EC2 in the ASG 

resource "aws_security_group" "instance" {
    name            = "brew-example-instance"

    ingress {
        from_port       =   var.server_port
        to_port         =   var.server_port
        protocol        =   "tcp"
        cidr_blocks     = ["0.0.0.0/0"]

    }
}

# create an application elb to route traffic across the ASG

resource "aws_elb" "example" {
    name              = "brew-elb-example"
    security_groups   = [aws_security_group.elb.id]
    availability_zone = data.aws_availability_zones.all.names   #all.names = in every AZs

    health_check {
        target        = "HTTP:${var.server_port}/"
        interval      = 30
        timeout       = 3
        healthy_thresold = 2
        unhealthy_thresold = 2
    }    

    # listener for incoming HTTP requests
    listener {
        lb_port         = var.elb_port
        lb_protocol     = "http"
        instance_port   = var.server_port
        instance_protocol = "http"
    }
}


# Create a launch Configuratin the defines each ec2 instance in the ASG

resource "aws_launch_configuration" "example" {
    name = "brew-example-launchconfig"

    image_id        = "ami-02d26659fd82cf299"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                # Create a simple HTML file
                cat <<EOT > index.html
                <html>
                    <body>
                        <h1 style="font-size:50px;color:blue;">Brew Labs "Asif"</h1>
                    </body>
                </html>
                EOT

# Whenever using a Launch Configuratin with an ASG, use below

    lifecycle {
        create_before_destroy = true
    }
}

# Actual ASG 

resource "aws_autoscaling_group" "example" {
    name = "brew-example-asg"
    launch_configuration = "aws_launch_configuration.example.id 
    availability_zone    = data.aws_availability_zones.all.names
    
    min_size = 3
    max_size = 8


    load_balancers      = [aws_elb.example.name]
    health_check_type   = "ELB"

    tag {
        key         = "NAME"
        value       = "BREW"
        propogate_at_launch = true 
    }
}

