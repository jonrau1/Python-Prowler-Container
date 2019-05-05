FROM python:latest

# Set Docker ENV & AWSCLI ENV
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_DEFAULT_REGION=us-east-1

# Install Dependencies
RUN \
    apt-get update && \
    apt-get upgrade -y && \
    pip install ansi2html && \
    pip install awscli

# Runs Prowler Check, Save in HTML, PUT to S3 Bucket
RUN git clone https://github.com/Alfresco/prowler
WORKDIR /prowler
CMD  \
    ./prowler | ansi2html -la > prowler-report.html  && \
    aws s3 cp prowler-report.html s3://$S3_REPORTS_BUCKET/prowler-report.html
