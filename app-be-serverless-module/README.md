This is a serverless module for the backend layer.

AWS Lambda functions and API gateway are often used to create serverless applications.

Follow along with this [tutorial on HashiCorp Learn](https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway?in=terraform/aws).

## Deploy to your local cloud

- Setup an AWS account
- Setup AWS CLI and configure it
- Create a local.tfvars
- Make sure you use the directory this README is in as root directory
- `terraform init`
- `terraform apply -var-file=local.tfvars`

## TODO

- add CRUD to dynamodb
- refactor main.tf
- add stages (prod, staging, qa) (don't forget to change api gateway tf config)
- add tests

## Go Init

- go mod init module/name
- go get github.com/aws/aws-lambda-go

## Testing

- curl "$(terraform output -raw base_url)/hello?Name=Terraform"