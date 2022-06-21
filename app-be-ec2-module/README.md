#!/bin/bash -xe
echo "Hello World" > index.html
sudo python -m SimpleHTTPServer 80

This is the backend layer of the fullstack app.
Use this to provision a single EC2 instance.

## Deploy to your local cloud

- Setup an AWS account
- Setup AWS CLI and configure it
- Create a local.tfvars
- Make sure you use the directory this README is in as root directory
- `terraform init`
- Generate key pair
- Change count of aws_instance.test
- `terraform apply -var-file=local.tfvars`

## Generating Public Private Key Pair for EC2 SSH

- `ssh-keygen -t rsa -b 4096 -C "my-ec2-keypair" -m "PEM" -N "" -f ./default_keypair`
  - rsa or ed25519. 2048 or 4096.
  - `-N ""` for empty new passphrase
  - `-C` is arbitrary username
- `mv default_keypair default_keypair.pem`