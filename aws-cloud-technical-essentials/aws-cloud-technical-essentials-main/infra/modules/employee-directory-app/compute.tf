data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "tls_private_key" "employee_directory_app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "employee_directory_app_key_pair" {
  key_name   = "employee_directory_app"
  public_key = tls_private_key.employee_directory_app_key.public_key_openssh

  tags = {
    name = "employee-directory-app-key-pair"
  }
}

resource "aws_iam_instance_profile" "employee_directory_app_instance_profile" {
  name = "employee-directory-app-instance-profile"
  role = aws_iam_role.ec2_s3_dynamodb_full_access_role.name

  tags = {
    name = "employee-directory-app-instance-profile"
  }
}

resource "aws_security_group" "employee_directory_app_web_security_group" {
  name        = "enable-http-https-ssh-access"
  description = "Enable HTTP, HTTPS and SSH access"

  vpc_id = aws_vpc.employee_directory_app_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    name = "employee-directory-web-security-group"
  }
}

resource "aws_autoscaling_group" "employee_directory_app_autoscaling_group" {
  target_group_arns   = [aws_lb_target_group.employee_directory_app_target_group.arn]
  min_size            = 2
  max_size            = 4
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.employee_directory_app_launch_template.id
    version = aws_launch_template.employee_directory_app_launch_template.latest_version
  }
  vpc_zone_identifier = [for subnet in aws_subnet.employee_directory_app_public_subnet : subnet.id]
}

resource "aws_autoscaling_attachment" "employee_directory_app_autoscaling_attachment" {
  autoscaling_group_name = aws_autoscaling_group.employee_directory_app_autoscaling_group.name
  alb_target_group_arn   = aws_lb_target_group.employee_directory_app_target_group.arn
}

resource "aws_autoscaling_policy" "employee_directory_app_scale_policy" {
  name                      = "employee-directory-app-scale-policy"
  autoscaling_group_name    = aws_autoscaling_group.employee_directory_app_autoscaling_group.name
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 300

  target_tracking_configuration {
    target_value = 60
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

resource "aws_autoscaling_notification" "employee_directory_app_autoscaling_notification" {
  count = length(var.autoscaling_notification_emails) > 0 ? 1 : 0

  group_names = [
    aws_autoscaling_group.employee_directory_app_autoscaling_group.name,
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.employee_directory_app_autoscaling_sns[0].arn
}

resource "aws_sns_topic" "employee_directory_app_autoscaling_sns" {
  count = length(var.autoscaling_notification_emails) > 0 ? 1 : 0

  name = "employee-directory-app-autoscaling-sns"

  tags = {
    name = "employee-directory-app-autoscaling-sns"
  }
}

resource "aws_sns_topic_subscription" "employee_directory_app_autoscaling_email_subscription" {
  for_each = var.autoscaling_notification_emails

  topic_arn = aws_sns_topic.employee_directory_app_autoscaling_sns[0].arn
  protocol  = "email"
  endpoint  = each.key
}

data "template_file" "employee_directory_app_launch_template_user_data" {
  template = <<EOF
  #!/bin/bash -ex
  wget https://aws-tc-largeobjects.s3-us-west-2.amazonaws.com/DEV-AWS-MO-GCNv2/FlaskApp.zip
  unzip FlaskApp.zip
  cd FlaskApp/
  yum -y install python3 mysql
  pip3 install -r requirements.txt
  amazon-linux-extras install epel
  yum -y install stress
  export PHOTOS_BUCKET=${aws_s3_bucket.employee_directory_app_photo_bucket.bucket}
  export AWS_DEFAULT_REGION=${data.aws_region.current.name}
  export DYNAMO_MODE=on
  FLASK_APP=application.py /usr/local/bin/flask run --host=0.0.0.0 --port=80
EOF
}

resource "aws_launch_template" "employee_directory_app_launch_template" {
  name = "employee-directory-app-launch-template"

  image_id      = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.employee_directory_app_key_pair.key_name
  iam_instance_profile {
    arn = aws_iam_instance_profile.employee_directory_app_instance_profile.arn
  }

  network_interfaces {
    security_groups             = [aws_security_group.employee_directory_app_web_security_group.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(data.template_file.employee_directory_app_launch_template_user_data.rendered)

  tag_specifications {
    resource_type = "instance"

    tags = {
      name = "employee-directory-app-instance"
    }
  }

  tags = {
    name = "employee-directory-app-launch-template"
  }
}
