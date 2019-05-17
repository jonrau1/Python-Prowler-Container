# Python-Prowler-Container
#### Run Prowler on ECS Fargate for AWS Security & Compliance Checks
Created a minimalist Dockerfile with AWS CLI Credentials and ENV Variables that can be securely passed to the container from ECS Task Definitions via AWS Secrets Manager. For more information on Prowler, refer to https://github.com/toniblyx/prowler. Only basic ./prowler check is used, modify as per your needs to use Custom/GDPR/HIPAA checks. Reports will be written out in HTML format using ansi2html, and will be uploaded to a S3 Bucket. The supporting Infrastructure is provisioned in an immutable and declarative fashion by Terraform.

## AWS Services Used
- Elastic Container Service - Fargate (ECS) 
- Elastic Container Registry (ECR)
- Simple Storage Service (S3)
- Simple Notification Server (SNS)
- CloudWatch Events
- Virtual Private Cloud (VPC)
- PrivateLink (VPC Gateway & Interface Endpoints)
- Secrets Manager (ASM)
- Systems Manager Paramater Store (SSM-PS)
- Key Management Service (KMS)
- Identity & Access Management (IAM)

## Solutions Architecture
![ArchitectureDiagram](https://github.com/jonrau1/Python-Prowler-Container/blob/master/pictures/Architecture-Diagram.jpg)
- Prowler will run in Fargate on ECS with `awsvpc` mode -- place in one of 3 possible Private Subnets (for US-East-1)
    - Logs are Passed to CloudWatch Logs via `awslogs` logs configuration
    - Secrets & Bucket Information Injected into Container via ASM & SSM-PS
    - Docker Image pulled down from ECR
- Task Scheduling is done via a Cron-expressed CloudWatch Event Rule
- VPC Endpoints for ECR, CloudWatch Events and S3 are provided for non-Internet Routeable Service Communications
- Artifacts are saved into a S3 Bucket, and a S3 Event publishes notifcations to a SNS Topic

## Deploying Via Terraform
#### NOTE: This Readme will talk through steps as you would do them on a brand new Ubuntu 18.04LTS EC2 Linux Instance, please ignore / modify based on your preferred deployment environment / mechanism ####

### Setup Deployment Environment
1. Create & Update Instance, Install Dependencies and Clone this Repository
```
#!/bin/bash
apt-get update
apt-get upgrade -y
apt-get install -y docker.io
apt-get install -y unzip
git clone https://github.com/jonrau1/Python-Prowler-Container.git
wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
unzip terraform_0.11.13_linux_amd64.zip
mv terraform /usr/local/bin/
```
2. Create ECR Repository, Build & Push Docker Image
- Navigate to Compute > ECR
- Choose `Create Repository`
- Give a unique name, include a namespace if desired
    - You can highlight your new created Repository for Push Commands
- In your instance, issue the following commands to Login to ECR, Build, Tag & Push (replace Account Number and Region as needed)
```
cd ~/Python-Prowler-Container
sudo su
$(aws ecr get-login --no-include-email --region <AWS_REGION>)
docker build -t <REPOSITORY_NAME> .
docker tag <REPOSITORY_NAME>:latest <ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com/<REPOSITORY_NAME>:latest
docker push <ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com/<REPOSITORY_NAME>:latest
```

### Configure Terraform & Deploy Infrastructure
1. Ensure your Instance has an EC2 Role attached to it that has write permissions for at least the Services listed in the `Services Used` Section Above
    - For more information refer to: https://www.terraform.io/docs/providers/aws/index.html#ec2-role
2. Navigate to the Terraform Scripts Sub-Directory `cd Python-Prowler-Container/terraform`
3. Initialize Terraform to download latest AWS Provider `terraform init`
4. Fill out Variables file `nano variables.tf`
5. Attempt a Terraform Plan, this may fail and tell you to re-initalize Terraform to facilitate downloading a generic Provider for the `Random Shuffle` Resource `terraform plan && terraform init`
6. Apply your Infrastructure - this may take a few minutes to create NAT Gateway && VPC Endpoint Interfaces `terraform apply`

### Retrieve IAM Credentials & Store Keys
1. Navigate to IAM Console > Users and find the IAM User you created via Terraform
2. Generate Access Keys in the Security Credentials section, save the CSV or copy out the Secret Access Key somewhere safe
![IAMCreds](https://github.com/jonrau1/Python-Prowler-Container/blob/master/pictures/IAM_Creds.jpg)
3. Navigate to the Secrets Manager and find the Secret repositories you created via Terraform
4. (Repeat these steps for each Secret)
    - Select the Secret
    - Scroll down to Secret Value > Get Secret Value > Set Secret Value
    ![SetSecretValue](https://github.com/jonrau1/Python-Prowler-Container/blob/master/pictures/Set_Secret_Value.jpg)
    - Select the `Plaintext` format and simply paste in your Secret(s)
    ![PlaintextSecret](https://github.com/jonrau1/Python-Prowler-Container/blob/master/pictures/Plaintext_Secret.jpg)

### Subscribe to Topic
1. Navigate to SNS and Find your Topic
2. Create Subscription - Email, HTTP, etc 
![CreateSubscription](https://github.com/jonrau1/Python-Prowler-Container/blob/master/pictures/Create_Subscription.jpg)
3. Confirm your Subscription to ensure you get alerts whenever the Prowler HTML file is written to your S3 Bucket

### Run Prowler Task
**NOTE** The first run task by the Event will fail due to the Secrets in ASM not being available, so you will have to manually run it the first time
1. Navigate to ECS > Task Definitions
2. Find the latest revision of your Task (it may be in Rev2 due to the way Terraform provisions resources),  Select Run Task from the Actions dropdown
![RunTask](https://github.com/jonrau1/Python-Prowler-Container/blob/master/pictures/Run_Task.jpg)
3. In the Run Task Screen, configure the following options
    - Launch Type = Fargate
    - Platform Version = Latest
    - Cluster = Your Terraform'ed Cluster Name
    - Number of Tasks = 1
    - Cluster VPC = Your Terraform'ed VPC Name
    - Subnets = Any Private Subnet
    - Security groups = Your Terraform'ed Security Group
    - Auto-assign Public IP = Disabled
![LaunchTask](https://github.com/jonrau1/Python-Prowler-Container/blob/master/pictures/Launch_Task.jpg)

## Next Steps

Feel free to Modify the Dockerfile to change the type of Prowler scan being run, or to modify any variables to conform to any naming standards by your organization.