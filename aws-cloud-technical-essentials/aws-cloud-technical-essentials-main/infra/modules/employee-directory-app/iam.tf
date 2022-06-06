resource "aws_iam_role" "ec2_s3_dynamodb_full_access_role" {
  name               = "ec2_s3_dynamodb_full_access_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Sid       = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      }
    ]
  })

  tags = {
    name = "employee-directory-app-full-access-role"
  }
}

resource "aws_iam_role_policy_attachment" "s3_full_access_role_policy_attach" {
  role       = aws_iam_role.ec2_s3_dynamodb_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access_role_policy_attach" {
  role       = aws_iam_role.ec2_s3_dynamodb_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
