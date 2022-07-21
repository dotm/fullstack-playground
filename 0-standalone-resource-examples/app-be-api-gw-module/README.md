This is an example API Gateway module.

## Deploy to your local cloud

- Setup an AWS account
- Setup AWS CLI and configure it
- Create a local.tfvars based on tfvars.sample
- Make sure you use the directory this README is in as root directory
- `terraform init`
- `terraform apply -var-file=local.tfvars`