terraform {
  required_version = "= 1.1.3"
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      course = "aws-cloud-technical-essentials"
      application = "employee-directory-app"
    }
  }
}

variable "autoscaling_notification_emails" {
  description = "Email addresses where to send notifications when autoscaling is triggered"
  default = []
}

module "employee_directory_app" {
  source = "../modules/employee-directory-app"
  autoscaling_notification_emails = var.autoscaling_notification_emails
}

output "employee_directory_app_instance_private_key" {
  value       = module.employee_directory_app.employee_directory_instance_private_key
  description = "The private key of the EC2 instance where the employee directory app is hosted."
  sensitive   = true
}

output "employee_directory_dns_name" {
  value       = module.employee_directory_app.employee_directory_dns_name
  description = "The DNS name of the employee directory app."
}
