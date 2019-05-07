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
- Secrets Manager
- Systems Manager Paramater Store
- Key Management Service (KMS)
- Identity & Access Management (IAM)

## Solutions Architecture
![ArchitectureDiagram](https://github.com/jonrau1/Python-Prowler-Container/blob/master/Architecture-Diagram.jpg)

## Getting Started

### Create ECR Repository & Push Image
- Navigate to Elastic Container Registry
- `Create Repository`
    - Give a unique name, can use Namespace via <Namespace>/<ECR_REPO_NAME>
- Clone this Repo for the next step
- `View Push Commands`
    - Follow the commands wherever you build Docker Images -- feel free to modify `Docker Build` as per your normal process (i.e. --no-cache, etc)

### Create S3 Bucket for HTML Prowler Reports
- Use a DNS Compliant Name
- Specify encryption & versioning, at a minimum

### Create ECS Cluster
- Navigate to ECS, Choose Cluster
- `Create Cluster`
    - Choose Networking Only
- Note on VPCs
    - For best network security ensure you use Private Subnets with VPC Endpoints & NATGW
        - For Fargate use VPC Interace Endpoint for com.amazonaws.region.ecr.dkr as well as a VPC Gateway Endpoint for S3 (https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html#ecr-vpc-endpoint-considerations)
        - Your SG you associate with the Fargate Task must have 443 open to use the VPC Endpoints

### Generate IAM Progammatic Access Keys & Pass to AWS Secrets Manager
*At a minimum Prowler will need AWS Credentials with Security Audit Policy Permissions -- see https://github.com/toniblyx/prowler for details*
- Generate Access Key & Secret Access Key, save CSV or copy out Secret Access Key somewhere safe
- Navigate to AWS Secrets Manager & Create Secrets
    - Choose `plaintext` instead of `key-value pair`
    - Create a Secret per Access Key and Secret Access Key

### Create ECS Task Definitions
- Choose Fargate
- Enter a name and choose a Task Role with at least the Security Audit Policy attached
- Have ECS Create the `ecsTaskExecutionRole` if you do not have it already
    - Attach a Policy that has access to KMS:Decrypt and SecretsManager:GetSecretValue
        - You can specify the ARNs of your Two Secrets in Resources of this new Policy
- Specify Task Memory and Task vCPU (I Use 3GB & 1vCPU)
- Under Container Definitions choose `Add container`
    - Choose a Unique Name
    - For the Image, copy the URI Path from your ECR Repository
    - Scroll down the `Environment variables` and add the following (this will be in the order of Key, ValueSelection, Value)
        - AWS_ACCESS_KEY_ID - ValueFrom - ARN of your Access Key Secret
        - AWS_SECRET_ACCESS_KEY - ValueFrom - ARN of your Secret Access Key Secret
        - S3_REPORTS_BUCKET - Value - Name of your S3 Bucket
- `Create`

### Run ECS Task
- Select your Task Definition and from the `Actions` dropdown select `Run Task`
    - Choose Fargate Launch Type
    - Choose your ECS Cluster
    - Specify you VPC, Subnet and Security Groups
    - `Run Task`
- Logs will not show up except for some small warnings from Prowler bash scripts and ansi2html -- takes around 7 minutes to complete the basic checks

## Next Steps

### ChatOps
You can create Event Source Invocations from S3 into SNS to alert Slack/SMS/Email that a new report is available

### Scheduling Tasks
You can schedule your ECS Task running Prowler in your Cluster (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduled_tasks.html) allowing you to automate weekly/bi-weekly/etc Prowler reports as per your regulatory and compliance requirements

### Terraformed!
Will be adding some support in my main project (https://github.com/jonrau1/AWS-ComplianceMachineDontStop) for this, to include creating most (if not all, except the secrets themselves) resources needed for this project
