data "aws_availability_zones" "Available_Region_AZ" {
  state = "available"
}
data "aws_iam_policy" "AWS_Managed_Security_Audit_Role" {
  arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
data "aws_iam_policy" "AWS_Managed_Full_S3_Access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
data "aws_iam_policy" "AWS_Managed_ECS_Events_Role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}