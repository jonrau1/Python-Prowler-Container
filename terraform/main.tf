resource "aws_ecs_cluster" "Prowler_ECS_Cluster" {
  name = "${var.Prowler_ECS_Cluster_Name}"
}
resource "aws_s3_bucket" "Prowler_Security_Artifact_Bucket" {
  bucket = "${var.Prowler_ECS_Cluster_Name}-artifact-bucket"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}
resource "aws_s3_bucket_notification" "Prowler_Artifact_Upload_Notifications" {
  bucket          = "${aws_s3_bucket.Prowler_Security_Artifact_Bucket.id}"
  topic {
    topic_arn     = "${aws_sns_topic.Prowler_Artifact_Alerts_SNS_Topic.arn}"
    events        = ["s3:ObjectCreated:*"]
  }
}
resource "aws_sns_topic" "Prowler_Artifact_Alerts_SNS_Topic" {
  name         = "${var.Prowler_ECS_Cluster_Name}-artifact-topic"
  display_name = "${var.Prowler_ECS_Cluster_Name}-artifact-topic"
  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": {"AWS":"*"},
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:${var.Prowler_ECS_Cluster_Name}-artifact-topic",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.Prowler_Security_Artifact_Bucket.arn}"}
        }
    }]
}
POLICY
}
resource "aws_vpc" "ECS_VPC" {
  instance_tenancy     = "${var.ECS_VPC_Tennacy}"
  cidr_block           = "${var.ECS_VPC_CIDR_Block}"
  enable_dns_support   = "${var.ECS_VPC_DNS_Support}"
  enable_dns_hostnames = "${var.ECS_VPC_DNS_Hostnames}"
  tags {
      Name = "${var.ECS_VPC_Name_Tag}"
  }
}
resource "aws_subnet" "ECS_VPC_Public_Subnet" {
  vpc_id                  = "${aws_vpc.ECS_VPC.id}"
  cidr_block              = "${var.ECS_PUB_Subnet_CIDR}"
  availability_zone       = "${data.aws_availability_zones.Available_Region_AZ.names[0]}"
  map_public_ip_on_launch = "${var.ECS_PUB_Subnet_PublicIP_On_Launch}"
  tags {
      Name = "${var.ECS_PUB_Subnet_Name_Tag}"
  }
}
resource "aws_subnet" "ECS_VPC_Private_Subnet_1" {
  vpc_id            = "${aws_vpc.ECS_VPC.id}"
  cidr_block        = "${var.ECS_PRIV_Subnet_1_CIDR}"
  availability_zone = "${data.aws_availability_zones.Available_Region_AZ.names[1]}"
  tags {
      Name = "${var.ECS_PRIV_Subnet_1_Name_Tag}"
  }
}
resource "aws_subnet" "ECS_VPC_Private_Subnet_2" {
  vpc_id            = "${aws_vpc.ECS_VPC.id}"
  cidr_block        = "${var.ECS_PRIV_Subnet_2_CIDR}"
  availability_zone = "${data.aws_availability_zones.Available_Region_AZ.names[2]}"
  tags {
      Name = "${var.ECS_PRIV_Subnet_2_Name_Tag}"
  }
}
resource "aws_subnet" "ECS_VPC_Private_Subnet_3" {
  vpc_id            = "${aws_vpc.ECS_VPC.id}"
  cidr_block        = "${var.ECS_PRIV_Subnet_3_CIDR}"
  availability_zone = "${data.aws_availability_zones.Available_Region_AZ.names[3]}"
  tags {
      Name = "${var.ECS_PRIV_Subnet_3_Name_Tag}"
  }
}
resource "aws_internet_gateway" "ECS_VPC_IGW" {
  vpc_id = "${aws_vpc.ECS_VPC.id}"
  tags {
      Name = "${var.ECS_VPC_Name_Tag}-IGW"
  }
}
resource "aws_route_table" "ECS_VPC_Public_RTB" {
  vpc_id = "${aws_vpc.ECS_VPC.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.ECS_VPC_IGW.id}"
  }
  tags {
    Name = "${var.ECS_VPC_Name_Tag}-PUB-RTB"
  }
}
resource "aws_route_table_association" "ECS_VPC_PUB_Subnet_RTB_Assoc" {
  subnet_id      = "${aws_subnet.ECS_VPC_Public_Subnet.id}"
  route_table_id = "${aws_route_table.ECS_VPC_Public_RTB.id}"
}
resource "aws_eip" "ECS_VPC_NAT_GW_EIP" {
  vpc = true
  tags {
    Name = "${var.ECS_VPC_Name_Tag}-NATGW-EIP"
  }
}
resource "aws_nat_gateway" "ECS_VPC_NAT_Gateway" {
  allocation_id = "${aws_eip.ECS_VPC_NAT_GW_EIP.id}"
  subnet_id     = "${aws_subnet.ECS_VPC_Public_Subnet.id}"
  depends_on = ["aws_internet_gateway.ECS_VPC_IGW"]
  tags {
    Name = "${var.ECS_VPC_Name_Tag}-NAT-GW"
  }
}
resource "aws_route_table" "ECS_VPC_Private_RTB" {
  vpc_id = "${aws_vpc.ECS_VPC.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ECS_VPC_NAT_Gateway.id}"
  }
  tags {
    label = "${var.ECS_VPC_Name_Tag}-PRIV-RTB"
  }
}
resource "aws_route_table_association" "ECS_VPC_PRIV_Subnet_1_RTB_Assoc" {
  subnet_id      = "${aws_subnet.ECS_VPC_Private_Subnet_1.id}"
  route_table_id = "${aws_route_table.ECS_VPC_Private_RTB.id}"
}
resource "aws_route_table_association" "ECS_VPC_PRIV_Subnet_2_RTB_Assoc" {
  subnet_id      = "${aws_subnet.ECS_VPC_Private_Subnet_2.id}"
  route_table_id = "${aws_route_table.ECS_VPC_Private_RTB.id}"
}
resource "aws_route_table_association" "ECS_VPC_PRIV_Subnet_3_RTB_Assoc" {
  subnet_id      = "${aws_subnet.ECS_VPC_Private_Subnet_3.id}"
  route_table_id = "${aws_route_table.ECS_VPC_Private_RTB.id}"
}
resource "aws_default_security_group" "ECS_VPC_Default_SG" {
  vpc_id = "${aws_vpc.ECS_VPC.id}"
  tags {
    Name = "DEFAULT_SG_DO_NOT_USE"
  }
}
resource "aws_security_group" "ECS_VPC_Primary_SG" {
  name_prefix = "${var.ECS_VPC_Name_Tag}-SG"
  description = "${var.Primary_SG_Group_Description} - Managed by Terraform"
  vpc_id      = "${aws_vpc.ECS_VPC.id}"
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
  tags {
      Name = "${var.ECS_VPC_Name_Tag}-SG"
  }
}
resource "aws_default_network_acl" "ECS_VPC_Default_NACL" {
  default_network_acl_id = "${aws_vpc.ECS_VPC.default_network_acl_id}"
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags {
    Name = "${var.ECS_VPC_Name_Tag}-DEFAULT-NACL"
  }
}
resource "aws_vpc_endpoint" "S3_VPC_Endpoint_Gateway" {
  vpc_id            = "${aws_vpc.ECS_VPC.id}"
  service_name      = "com.amazonaws.${var.AWS_Region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = ["${aws_route_table.ECS_VPC_Private_RTB.id}"]
}
resource "aws_vpc_endpoint" "ECR_DKR_VPC_Interface_Endpoint" {
  vpc_id              = "${aws_vpc.ECS_VPC.id}"
  service_name        = "com.amazonaws.${var.AWS_Region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.ECS_VPC_Primary_SG.id}"]
  subnet_ids          = [
      "${aws_subnet.ECS_VPC_Private_Subnet_1.id}",
      "${aws_subnet.ECS_VPC_Private_Subnet_2.id}",
      "${aws_subnet.ECS_VPC_Private_Subnet_3.id}"
    ]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "CloudWatch_Logs_VPC_Interface_Endpoint" {
  vpc_id              = "${aws_vpc.ECS_VPC.id}"
  service_name        = "com.amazonaws.${var.AWS_Region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.ECS_VPC_Primary_SG.id}"]
  subnet_ids          = [
      "${aws_subnet.ECS_VPC_Private_Subnet_1.id}",
      "${aws_subnet.ECS_VPC_Private_Subnet_2.id}",
      "${aws_subnet.ECS_VPC_Private_Subnet_3.id}"
    ]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "CloudWatch_Events_VPC_Interface_Endpoint" {
  vpc_id              = "${aws_vpc.ECS_VPC.id}"
  service_name        = "com.amazonaws.${var.AWS_Region}.events"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.ECS_VPC_Primary_SG.id}"]
  subnet_ids          = [
      "${aws_subnet.ECS_VPC_Private_Subnet_1.id}",
      "${aws_subnet.ECS_VPC_Private_Subnet_2.id}",
      "${aws_subnet.ECS_VPC_Private_Subnet_3.id}"
    ]
  private_dns_enabled = true
}
resource "aws_flow_log" "ECS_VPC_Flow_Logs" {
  iam_role_arn    = "${aws_iam_role.Flow_Logs_IAM_Role.arn}"
  log_destination = "${aws_cloudwatch_log_group.ECS_VPC_Flow_Logs_CW_Logs_Group.arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.ECS_VPC.id}"
}
resource "aws_cloudwatch_log_group" "ECS_VPC_Flow_Logs_CW_Logs_Group" {
  name = "${var.ECS_VPC_Name_Tag}-flow-logs"
}
resource "aws_iam_role" "Flow_Logs_IAM_Role" {
  name = "${var.ECS_VPC_Name_Tag}-flowlogs-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "Flows_Logs_To_CW_IAM_Policy" {
  name   = "${var.ECS_VPC_Name_Tag}-flowlogs-policy"
  role   = "${aws_iam_role.Flow_Logs_IAM_Role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_secretsmanager_secret" "Access_Key_Secret_Repo" {
  name = "${var.Access_Key_Secret_Repo_Name}"
}
resource "aws_secretsmanager_secret" "Secret_Access_Key_Secret_Repo" {
  name = "${var.Secret_Access_Key_Secret_Repo_Name}"
}
resource "aws_ssm_parameter" "Prowler_Bucket_Parameter" {
  name  = "${var.Prowler_Bucket_Parameter_Name}"
  type  = "String"
  value = "${aws_s3_bucket.Prowler_Security_Artifact_Bucket.id}"
}
resource "aws_cloudwatch_log_group" "Prowler_ECS_Task_Definition_CW_Logs_Group" {
  name = "/ecs/${var.Container_Name}"
}
resource "aws_ecs_task_definition" "Prowler_ECS_Task_Definition" {
  family                   = "${var.Prowler_Task_Definition_Name}"
  execution_role_arn       = "${aws_iam_role.Prowler_ECS_Task_Execution_Role.arn}"
  task_role_arn            = "${aws_iam_role.Prowler_ECS_Task_Role.arn}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.Fargate_CPU}"
  memory                   = "${var.Fargate_MEM}"

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.Fargate_CPU},
    "image": "${var.Prowler_Docker_Image_URI}",
    "memory": ${var.Fargate_MEM},
    "memoryReservation": ${var.Fargate_MEM},
    "essential": true,
    "environment": [],
    "name": "${var.Container_Name}",
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "secretOptions": null,
      "options": {
        "awslogs-group": "/ecs/${var.Container_Name}",
        "awslogs-region": "${var.AWS_Region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [],
    "volumesFrom": [],
    "mountPoints": [],
    "secrets": [
      {
        "valueFrom": "${aws_ssm_parameter.Prowler_Bucket_Parameter.arn}",
        "name": "S3_REPORTS_BUCKET"
      },
      {
        "valueFrom": "${aws_secretsmanager_secret.Access_Key_Secret_Repo.arn}",
        "name": "AWS_ACCESS_KEY_ID"
      },
      {
        "valueFrom": "${aws_secretsmanager_secret.Secret_Access_Key_Secret_Repo.arn}",
        "name": "AWS_SECRET_ACCESS_KEY"
      }
    ]
  }
]
DEFINITION
}
resource "aws_iam_role" "Prowler_ECS_Task_Execution_Role" {
  name               = "${var.Prowler_Task_Definition_Name}-exec-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "Prowler_Task_Exeuction_Role_Policy" {
  name   = "${var.Prowler_Task_Definition_Name}-exec-policy"
  role   = "${aws_iam_role.Prowler_ECS_Task_Execution_Role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "kms:Decrypt",
        "kms:DescribeKey",
        "ssm:GetParametersByPath",
        "ssm:GetParameters",
        "ssm:GetParameter",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role" "Prowler_ECS_Task_Role" {
  name               = "${var.Prowler_Task_Definition_Name}-task-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "Prowler_ECS_Task_Role_Policy" {
  role       = "${aws_iam_role.Prowler_ECS_Task_Role.id}"
  policy_arn = "${data.aws_iam_policy.AWS_Managed_Security_Audit_Role.arn}"
}
resource "aws_cloudwatch_event_rule" "Prowler_Task_Scheduling_CW_Event_Rule" {
  name                = "${var.Prowler_Task_Definition_Name}_Scheduled_Task"
  description         = "Run ${var.Prowler_Task_Definition_Name} Task at a scheduled time (${var.Prowler_Schedule_Task_Expression}) - Managed by Terraform"
  schedule_expression = "${var.Prowler_Schedule_Task_Expression}"
}
resource "aws_iam_role" "Prowler_Scheduled_Task_Event_Role" {
  name               = "${var.Prowler_Scheduled_Task_Event_Role_Name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "Prowler_Scheduled_Task_Event_Role_Policy" {
  role       = "${aws_iam_role.Prowler_Scheduled_Task_Event_Role.id}"
  policy_arn = "${data.aws_iam_policy.AWS_Managed_ECS_Events_Role.arn}"
}
resource "random_shuffle" "Shuffle_Fargate_AZ" {
  input = [
      "${aws_subnet.ECS_VPC_Private_Subnet_1.id}", 
      "${aws_subnet.ECS_VPC_Private_Subnet_2.id}", 
      "${aws_subnet.ECS_VPC_Private_Subnet_3.id}"
    ]
  result_count = 1
}
resource "aws_cloudwatch_event_target" "Prowler_Scheduled_Scans" {
  rule       = "${aws_cloudwatch_event_rule.Prowler_Task_Scheduling_CW_Event_Rule.name}"
  arn        = "${aws_ecs_cluster.Prowler_ECS_Cluster.arn}"
  role_arn   = "${aws_iam_role.Prowler_Scheduled_Task_Event_Role.arn}"
  ecs_target = {
      launch_type         = "FARGATE"
      task_definition_arn = "${aws_ecs_task_definition.Prowler_ECS_Task_Definition.arn}"
      task_count          = "1"
      platform_version    = "${var.Fargate_Platform_Version}"
      network_configuration  {
        subnets         = ["${random_shuffle.Shuffle_Fargate_AZ.result}"]
        security_groups = ["${aws_security_group.ECS_VPC_Primary_SG.id}"]
    }
  }
}
resource "aws_iam_group" "Prowler_IAM_Group" {
  name = "${var.Prowler_IAM_Group_Name}"
}
resource "aws_iam_group_policy_attachment" "Prowler_IAM_Group_SecAudit_Policy_Attachment" {
  group      = "${aws_iam_group.Prowler_IAM_Group.name}"
  policy_arn = "${data.aws_iam_policy.AWS_Managed_Security_Audit_Role.arn}"
}
resource "aws_iam_group_policy_attachment" "Prowler_IAM_Group_S3Full_Policy_Attachment" {
  group      = "${aws_iam_group.Prowler_IAM_Group.name}"
  policy_arn = "${data.aws_iam_policy.AWS_Managed_Full_S3_Access.arn}"
}
resource "aws_iam_user" "Prowler_IAM_User" {
  name = "${var.Prowler_IAM_User_Name}"
}
resource "aws_iam_group_membership" "Prowler_IAM_User_Group_Memmbership" {
  name = "${var.Prowler_IAM_User_Group_Memmbership_Name}"
  users = ["${aws_iam_user.Prowler_IAM_User.name}",]
  group = "${aws_iam_group.Prowler_IAM_Group.name}"
}