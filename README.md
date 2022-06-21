# README

Each module should act as if they don't know other module.
Do NOT introduce any dependency that relies on the fact that they are in the same directory as this README.
Other dependencies through Terraform data sources, external key value storage, etc. is fine.

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

## Sharing plugins across modules

This reduces the size of .terraform directory by providing a single source of aws plugin cache.

- `mkdir $HOME/.terraform.d/plugin-cache`
- `echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' >> $HOME/.terraformrc`
  - You can also use: `export TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache`
- Restart shell