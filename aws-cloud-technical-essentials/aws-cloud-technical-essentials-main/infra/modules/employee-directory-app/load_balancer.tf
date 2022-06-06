resource "aws_security_group" "employee_directory_app_lb_security_group" {
  name        = "enable-http-access"
  description = "Enable HTTP access"

  vpc_id = aws_vpc.employee_directory_app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "employee-directory-app-lb-security-group"
  }
}


resource "aws_lb" "employee_directory_app_lb" {
  name               = "employee-directory-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.employee_directory_app_lb_security_group.id]
  subnets            = [for subnet in aws_subnet.employee_directory_app_public_subnet : subnet.id]

  tags = {
    name = "employee-directory-app-lb"
  }
}

resource "aws_lb_target_group" "employee_directory_app_target_group" {
  name     = "app-target-group"
  vpc_id   = aws_vpc.employee_directory_app_vpc.id
  port     = 80
  protocol = "HTTP"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 30
    interval            = 40
  }

  tags = {
    name = "employee-directory-app-target-group"
  }
}

resource "aws_lb_listener" "employee_directory_app_lb_listener" {
  load_balancer_arn = aws_lb.employee_directory_app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.employee_directory_app_target_group.arn
  }
}
