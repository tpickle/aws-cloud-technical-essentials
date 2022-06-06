variable "autoscaling_notification_emails" {
  type    = set(string)
  default = []
  description = "Email addresses where to send notifications when autoscaling is triggered"
}
