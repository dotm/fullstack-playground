#Put resources here.
#If this files become to long, you can move related resources to their own files.

#Local variables that are used in multiple files should be placed in ./locals.tf
#Put local variables that are only used in this file below
locals {
  db_suffix = "${var.deployment_environment_name}-${var.project_name_short}-${var.aws_deployment_account_id}"

  db_instance_name = "main-instance-${local.db_suffix}"

  #can't use - in db_name, so we capitalize each word
  db_name_with_hyphen = "main-db-${local.db_suffix}"
  db_name_with_space  = replace(local.db_name_with_hyphen, "-", " ")
  db_name_capitalized = title(local.db_name_with_space)
  db_name             = replace(local.db_name_capitalized, " ", "")

  db_replica_name_list = {
    #up to 5 replicas
    # "replica-1" = "main-replica-1-${local.db_suffix}",
  }
  db_final_snapshot_name = "final-snapshot-${local.db_name}"

  deployment_environment_is_temporary = contains(["local"], var.deployment_environment_name)

  db_is_publicly_accessible = local.deployment_environment_is_temporary ? true : false

  db_subnet_ids = local.db_is_publicly_accessible ? data.aws_subnets.list_public.ids : data.aws_subnets.list_private.ids

  db_instance_class = "db.t4g.micro"

  active_db_engine_config = "postgresql-14.3"
  db_engine_config_list = {
    "postgresql-14.3" = {
      engine                 = "postgres",
      engine_version         = "14.3",
      parameter_group_family = "postgres14",
      port                   = 5432
    }
  }
  is_using_postgres = local.db_engine_config_list[local.active_db_engine_config].engine == "postgres"
}

#Notes:
#The parameter group resource contains all of the database-level settings for your RDS instance,
# which will be specific to the database engine and version you use.
#Custom parameter groups are optional, and AWS will create the instance
# using a default parameter group if you do not supply one.
# However, you cannot modify the settings of a default parameter group,
# and changing the associated parameter group for an AWS instance always requires a reboot,
# so it is best to use a custom one to support modifications over the RDS life cycle.
#Option vs Parameter
# Option groups allows the use of available features within a database.
# Parameter groups is how the database is configured.
#PostgreSQL does not use options and option groups.
# PostgreSQL uses extensions and modules to provide additional features.

resource "aws_db_subnet_group" "main" {
  name = "main"
  # name_prefix = "conflicts_with_nam"
  description = "Main RDS subnet group"

  subnet_ids = local.db_subnet_ids

  tags = {}
}

resource "aws_security_group" "rds" {
  name   = "rds_sg"
  vpc_id = data.aws_vpcs.list.ids[0]

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {}
}

resource "aws_db_parameter_group" "main" {
  name = "main"
  # name_prefix = "conflicts_with_nam"
  description = "Main RDS subnet group"

  family = local.db_engine_config_list[local.active_db_engine_config].parameter_group_family
  #parameters may differ from one family to another.

  #one block per parameter. multiple parameter blocks are allowed.
  parameter {
    name  = "log_connections"
    value = "1"

    apply_method = "immediate" #Optional. "immediate" (default), or "pending-reboot".
    #Some engines can't apply some parameters without a reboot,
    # and you will need to specify "pending-reboot" here.
    #After applying your changes, you may encounter a perpetual diff in your Terraform plan output
    # for a parameter whose value remains unchanged but whose apply_method is changing
    # (e.g. from immediate to pending-reboot, or pending-reboot to immediate).
    # If only the apply method of a parameter is changing, the AWS API will not register this change.
    # To change the apply_method of a parameter, its value must also change.
  }

  tags = {}
}

resource "aws_db_instance" "main" {
  identifier = local.db_instance_name
  #both identifier and identifier_prefix will force create a new resource if changed
  # identifier_prefix = local.db_instance_name

  instance_class = local.db_instance_class
  #List: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html

  port = local.db_engine_config_list[local.active_db_engine_config].port

  allocated_storage = 5 #GiB
  #To enable Storage Autoscaling with instances that support the feature,
  #define the max_allocated_storage argument higher than the allocated_storage argument.
  #Terraform will automatically hide differences with
  #the allocated_storage argument value if autoscaling occurs.
  max_allocated_storage = local.deployment_environment_is_temporary ? 0 : 10
  #Must be greater than or equal to allocated_storage
  #or 0 to disable Storage Autoscaling.

  #for detail, see the Engine and EngineVersion parameter in this docs: https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html
  #for Amazon Aurora instances the engine and engine version must match the aws_rds_cluster ones.
  engine         = local.db_engine_config_list[local.active_db_engine_config].engine
  engine_version = local.db_engine_config_list[local.active_db_engine_config].engine_version
  #Changing this parameter does not result in an outage and
  #the change is asynchronously applied as soon as possible.
  allow_major_version_upgrade = local.deployment_environment_is_temporary ? true : false
  auto_minor_version_upgrade  = true #During maintenance window if not applied immediately. Defaults to true.

  #Changes to a DB instance can occur when you manually change a parameter
  #and are reflected in the next maintenance window.
  #So, Terraform may report a difference in its planning phase
  #because a modification has not yet taken place.
  #You can use the apply_immediately flag to instruct the service
  #to apply the change immediately.
  #using apply_immediately can result in a brief downtime as the server reboots.
  apply_immediately = local.deployment_environment_is_temporary ? true : false

  username = var.db_username
  password = var.db_password
  db_name  = local.db_name
  #This does not apply for Oracle or SQL Server engines.
  #If you are providing an Oracle db name, it needs to be in all upper case.
  #If unspecified, no database is created in the DB instance.

  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible  = local.db_is_publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.main.name #If unspecified, will be created in the default VPC.
  # availability_zone = "" #unneeded because we've specified db_subnet_group_name (?)
  multi_az = local.deployment_environment_is_temporary ? false : true #if the RDS instance is multi-AZ

  maintenance_window = "Mon:00:00-Mon:03:00" #UTC. Syntax: "ddd:hh24:mi-ddd:hh24:mi"
  #https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.Maintenance.html#AdjustingTheMaintenanceWindow

  backup_retention_period = 35 #days to retain backups. 0-35
  backup_window           = "09:46-10:16"
  #Daily time range (UTC) in which automated backups are created if they are enabled.
  #Must not overlap with maintenance_window.
  delete_automated_backups = local.deployment_environment_is_temporary ? true : false
  #remove automated backups immediately after the DB instance is deleted. Default is true.

  deletion_protection = local.deployment_environment_is_temporary ? false : true
  #db can't be deleted when this value is set to true. The default is false.
  skip_final_snapshot = true
  # final_snapshot_identifier = local.db_final_snapshot_name
  #name of final DB snapshot when this DB instance is deleted. 

  # enabled_cloudwatch_logs_exports = []
  #If omitted, no logs will be exported.
  #Valid values (depending on engine):
  # MySQL and MariaDB: audit, error, general, slowquery.
  # PostgreSQL: postgresql, upgrade.
  # MSSQL: agent, error.
  # Oracle: alert, audit, listener, trace.

  parameter_group_name = aws_db_parameter_group.main.name
  # option_group_name    = aws_db_option_group.main.name

  # kms_key_id = aws_kms_key.main_rds.arn
  storage_encrypted = false #default to false
  #Whether the DB instance is encrypted.
  #If you are creating a cross-region read replica,
  # this field is ignored and you should instead
  # declare kms_key_id with a valid ARN.

  storage_type = "gp2"
  #Valid values: "standard" (magnetic), "gp2" (general purpose SSD), or "io1" (provisioned IOPS SSD).
  #The default is "io1" if iops is specified, "gp2" if not.

  copy_tags_to_snapshot = true #Copy all Instance tags to snapshots. Default is false.
  tags                  = {}

  timeouts {
    create = "40m" #Default 40m. Used for Creating Instances, Replicas, and restoring from Snapshots.
    update = "80m" #Default 80m. Used for Database modifications.
    delete = "1h"  #Default 60m. Used for destroying databases. Includes the time required to take snapshots.
  }

  # restore_to_point_in_time {
  #   #choose one of these two arguments:
  #   restore_time = "" #The date and time in UTC to restore from.
  #   #Value must be before the latest restorable time for the DB instance.
  #   use_latest_restorable_time = false #whether the DB instance is restored from the latest backup time.
  #   #Defaults to false.

  #   #Choose one of these three arguments:
  #   source_db_instance_identifier            = "" #source DB instance from which to restore.
  #   source_db_instance_automated_backups_arn = "" #the automated backup from which to restore.
  #   source_dbi_resource_id                   = "" #resource ID of the DB instance from which to restore.
  # }

  # s3_import { #Restore from a Percona Xtrabackup in S3.
  #   #see: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MySQL.Procedural.Importing.html

  #   source_engine         = local.db_engine_config_list[local.active_db_engine_config].engine
  #   source_engine_version = local.db_engine_config_list[local.active_db_engine_config].engine_version

  #   #where your backup is stored:
  #   bucket_name   = "mybucket"
  #   bucket_prefix = "path/to/backups" #can be blank

  #   #IAM Role arn applied to load the data
  #   ingestion_role = ""
  # }

  # customer_owned_ip_enabled
  #whether to enable a customer-owned IP address (CoIP) for an RDS on Outposts DB instance.
  #see: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-on-outposts.html#rds-on-outposts.coip

  # monitoring_interval = 0 #seconds between points when Enhanced Monitoring metrics are collected.
  # #To disable collecting Enhanced Monitoring metrics, specify 0.
  # #Valid Values: 0 (default), 1, 5, 10, 15, 30, 60.
  # monitoring_role_arn = "" #permits RDS to send metrics to CloudWatch Logs.

  # performance_insights_enabled    = false #Defaults to false.
  # performance_insights_kms_key_id = aws_kms_key.main_rds_performance_insights.arn
  # #Once KMS key is set, it can never be changed.
  # performance_insights_retention_period = 7 #days to retain data. Either 7 (default) or 731 (2 years).

  # iops = 1 #Amount of provisioned IOPS. Setting this implies a storage_type of "io1".

  # ca_cert_identifier = "" #CA certificate for the DB instance

  # character_set_name = ""
  #The character set name to use for DB encoding
  #in Oracle and Microsoft SQL instances (collation).
  #This can't be changed.
  # nchar_character_set_name = ""
  #The national character set is used in the NCHAR, NVARCHAR2, and NCLOB data types for Oracle instances.
  #This can't be changed (force new resource creation on change).

  # license_model = "" #required for some DB engines (i.e. Oracle SE1)

  # timezone = "" #Only supported by Microsoft SQL Server. Can only be set on creation. 

  # domain = ""
  #The ID of the Directory Service Active Directory domain to create the instance in.
  # domain_iam_role_name = ""
  #The name of the IAM role to be used when making API calls to the Directory Service.

  # iam_database_authentication_enabled = true
  #whether mappings of AWS IAM accounts to database accounts is enabled.

  # snapshot_identifier = "" #the snapshot ID you'd find in the RDS console
  #will create this database from a snapshot.
}

#Attributes that cannot be specified for a read replica:
# db_name, engine, engine_version, final_snapshot_identifier
# allocated_storage, username, password
#For source of read replica:
# backup_retention_period must be greater than 0.
#db_subnet_group_name for read replicas should be specified only if
# the source database specifies an instance in another AWS Region.
#see this for additional constraints on read replica:
# https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstanceReadReplica.html
resource "aws_db_instance" "main_replica" {
  for_each   = local.db_replica_name_list
  identifier = each.value

  #specify this instance as read replica
  replicate_source_db = aws_db_instance.main.identifier
  #Use identifier if replicating within a single region or ARN if replicating cross-region.
  #For a cross-region replica of an encrypted database you will also need to specify a kms_key_id.
  #Removing the replicate_source_db attribute from an existing read replica
  # will promote the database to a fully standalone database.

  instance_class = local.db_instance_class

  apply_immediately      = local.deployment_environment_is_temporary ? true : false
  publicly_accessible    = local.db_is_publicly_accessible
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main.name

  # replica_mode = ""
  #whether the replica is in either mounted or open-read-only mode (default).
  #This attribute is only supported by Oracle instances.

  # kms_key_id = aws_kms_key.main_rds.arn
  #If you are creating a cross-region read replica,
  # storage_encrypted is ignored and you should instead
  # declare kms_key_id with a valid ARN.
}