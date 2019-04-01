provider "aws" {
  region  = "${var.aws_region}"
#  profile = "${var.aws_profile}"
}

#update region and profile (if needed)

#to make publicly accessible, change variable in the db instance module
#otherwise a bastion host will need to be used.


##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

#####
# DB
#####
module "db" {
  source = "./terraform-aws-rds"

  identifier = "twdpostgres"

  engine            = "postgres"
  engine_version    = "10.6"
  instance_class    = "db.t2.medium"
  allocated_storage = 5
  storage_encrypted = false

 #kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name = "twdpostgres"

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = "twdpostgres"

  password = "t3stdb12345"
  port     = "5432"

  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "twdpostgres"
    Environment = "dev"
  }

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids = ["${data.aws_subnet_ids.all.ids}"]

  # DB parameter group
  family = "postgres10"

  # DB option group
  major_engine_version = "10.6"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "twdpostgres"

  # Database Deletion Protection
  deletion_protection = false
}

