This is a data layer that uses s3.
Resources not in local deployment environment should not be auto-deleted to avoid accidental data loss.

## Deploy to your local cloud

- Setup an AWS account
- Setup AWS CLI and configure it
- Create a local.tfvars based on tfvars.sample
- Make sure you use the directory this README is in as root directory
- `terraform init`
- `terraform apply -var-file=local.tfvars`