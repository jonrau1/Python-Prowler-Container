provider "aws" {
  region = "us-east-1"
}

## terraform {
##     backend "s3" {
##       encrypt = true
##       bucket = ""
##       dynamodb_table = ""
##       key = "path/to/file/terraform.tfstate"
##       region = "us-east-1"
##   }
## }