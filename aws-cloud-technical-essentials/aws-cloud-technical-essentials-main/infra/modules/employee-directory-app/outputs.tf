output "employee_directory_instance_private_key" {
  value     = tls_private_key.employee_directory_app_key.private_key_pem
  description = "The private key of the EC2 instance where the employee directory app is hosted."
  sensitive   = true
}

output "employee_directory_dns_name" {
  value     = aws_lb.employee_directory_app_lb.dns_name
  description = "The DNS name of the employee directory app."
}
