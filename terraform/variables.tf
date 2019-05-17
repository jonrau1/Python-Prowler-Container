variable "AWS_Region" {
  default = "us-east-1"
  description = "AWS Region is used to VPC Endpoints in this Case - should match your Region in Provider"
}
variable "Prowler_ECS_Cluster_Name" {
  default = ""
}
variable "ECS_VPC_Tennacy" {
  default = "default"
  description = "default or dedicated"
}
variable "ECS_VPC_CIDR_Block" {
  default = "172.17.0.0/16"
  description = "RFC1918 Compliant CIDR Block for the VPC"
}
variable "ECS_VPC_DNS_Support" {
  default = "true"
  description = "Indicates whether instances with public IP addresses get corresponding public DNS hostnames."
}
variable "ECS_VPC_DNS_Hostnames" {
  default = "true"
  description = "Indicates whether the DNS resolution is supported. Needed for VPC Endpoints"
}
variable "ECS_VPC_Name_Tag" {
  default = ""
  description = "Tag Value for the Name of the ECS VPC"
}
variable "ECS_PUB_Subnet_CIDR" {
  default = "172.17.10.0/24"
  description = "RFC1918 Compliant CIDR Block for the Public Subnet of the VPC"
}
variable "ECS_PUB_Subnet_PublicIP_On_Launch" {
  default = "true"
  description = "Controls whether your instance in a default or nondefault subnet is assigned a public IPv4 address during launch"
}
variable "ECS_PUB_Subnet_Name_Tag" {
  default = ""
  description = "Tag Value for the Name of the ECS Public Subnet"
}
variable "ECS_PRIV_Subnet_1_CIDR" {
  default = "172.17.3.0/24"
  description = "RFC1918 Compliant CIDR Block for the Public Subnet of the VPC"
}
variable "ECS_PRIV_Subnet_1_Name_Tag" {
  default = ""
  description = "Tag Value for the Name of the ECS Private Subnet 1"
}
variable "ECS_PRIV_Subnet_2_CIDR" {
  default = "172.17.7.0/24"
  description = "RFC1918 Compliant CIDR Block for the Public Subnet of the VPC"
}
variable "ECS_PRIV_Subnet_2_Name_Tag" {
  default = ""
  description = "Tag Value for the Name of the ECS Private Subnet 2"
}
variable "ECS_PRIV_Subnet_3_CIDR" {
  default = "172.17.1.0/24"
  description = "RFC1918 Compliant CIDR Block for the Public Subnet of the VPC"
}
variable "ECS_PRIV_Subnet_3_Name_Tag" {
  default = ""
  description = "Tag Value for the Name of the ECS Private Subnet 3"
}
variable "Primary_SG_Group_Description" {
  default = "for prowler"
  description = "Group Description for the Primary Security Group"
}
variable "Access_Key_Secret_Repo_Name" {
  default = ""
  description = "Name of the ASM Secret - This is NOT the actual Secret it will need to be created manually"
}
variable "Secret_Access_Key_Secret_Repo_Name" {
  default = ""
  description = "Name of the ASM Secret - This is NOT the actual Secret it will need to be created manually"
}
variable "Prowler_Bucket_Parameter_Name" {
  default = ""
  description = "Name of the SSM Parameter that stores the Value of the S3 Bucket to Store Prowler Reports"
}
variable "Prowler_Task_Definition_Name" {
  default = "prowler-ecs"
  description = "Unique name for your ECS Task Definition"
}
variable "Fargate_CPU" {
  default     = 1024
  description = "CPU Reservation for ECS Fargate Task"
}
variable "Fargate_MEM" {
  default     = 2048
  description = "Memory Reservation for ECS Fargate Task"
}
variable "Prowler_Docker_Image_URI" {
  default = ""
  description = "URI Path of the Prowler Docker Image - Preferably from ECR"
}
variable "Container_Name" {
  default = ""
  description = "Name of the Container within ECS"
}
variable "Prowler_Schedule_Task_Expression" {
  type        = "string"
  default     = "cron(0 0 12 1/6 * ? *)"
  description = "Crom Schedule Expression for how often to run the Prowler ECS Fargate Task - Default is 6 Days"
}
variable "Prowler_Scheduled_Task_Event_Role_Name" {
  default     = ""
  description = "Name of the IAM Role for CloudWatch Event Task Scheduler for ECS Fargate"
}
variable "Fargate_Platform_Version" {
  default = "1.3.0"
  description = "Must use LATEST (1.3.0 as of MAY 2019) Version"
}
variable "Prowler_IAM_Group_Name" {
  default = ""
}
variable "Prowler_IAM_User_Name" {
  default = ""
}
variable "Prowler_IAM_User_Group_Memmbership_Name" {
  default = ""
}
