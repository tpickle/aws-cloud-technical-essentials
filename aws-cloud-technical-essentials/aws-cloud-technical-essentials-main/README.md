# aws-cloud-technical-essentials

Contains exercises from coursera's course [AWS Cloud Technical Essentials](https://www.coursera.org/learn/aws-cloud-technical-essentials)

## Infra
Infrastructure is managed using [Terraform's AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs),
all the related code is under `infra` root folder.

The first time terraform has to be initialized using the following command
```shell
aws-cloud-technical-essentials/infra/env
$ terraform init
```
On every infrastructure modification changes can be applied with the following command
```shell
aws-cloud-technical-essentials/infra/env
$ terraform apply
```

To receive autoscaling notifications through email provide `autoscaling_notification_emails` var through command line:
```shell
aws-cloud-technical-essentials/infra/env
$ terraform apply -var='autoscaling_notification_emails=["foo@bar.com"]'
```
This will create additional SNS topic to send the emails and subscribe the provided emails to it.

The output `employee_directory_app_instance_private_key` is exposed to get the private key to connect to the ec2 instances:
```shell
aws-cloud-technical-essentials/infra/env
$ terraform output -raw employee_directory_app_instance_private_key > employee_directory_app_instance_private_key.pem
$ ssh -i employee_directory_app_instance_private_key.pem ec2-user@<employee_directory_instance_public_ip>
```

The output `employee_directory_dns_name` is exposed to connect to the employee directory app through the load balancer

## Tips

Default VPC not created for the region:
```shell
aws --region <REGION> ec2 create-default-vpc
```
If your account does not have default VPC you might need to reach out Amazon. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/vpc-migrate.html
