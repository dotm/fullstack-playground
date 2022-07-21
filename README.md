# README

## Installing Terraform

We recommend using a version manager like `tfenv` to install Terraform
so that you can change between multiple Terraform versions easily.

## Sharing plugins across modules

This reduces the size of .terraform directory by providing a single source of aws plugin cache.

- `mkdir $HOME/.terraform.d/plugin-cache`
- `echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' >> $HOME/.terraformrc`
  - You can also use: `export TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache`
- Restart shell

## Module Introduction

Each module should act as if they don't know other module.
Do NOT introduce any dependency that relies on the fact that they are in the same directory as this README.
Other dependencies through Terraform data sources, external key value storage, etc. is fine.

Notes on `0-` modules:

- `0-console-experiment`: use this for experimenting with `terraform console`
- `0-empty-module`: copy this to create a new module (don't forget to remove every `"0-empty-module"` especially in `variables.tf` file)
- `0-standalone-resource-examples`: this directory can't be validated and serve only as documentation for resources that can be copied to other modules and applied after validation

## Recommended Module Structure

https://learn.hashicorp.com/tutorials/terraform/pattern-module-creation

- Organization Module
- Network Module
- DNS Zone???
- Database Module: RDS, ElasticSearch (ES), etc.
- App Module:
  - Backend (BE)
  - Frontend (FE)
- Security Module
