terraform {
    backend "s3" {
        bucket = "pella-state-bucket"
        key = "state/terraform.tfstate"
        region = "us-east-2"
        dynamodb_table = "pella_state_table"
        encrypt = true
    }
}


provider "aws" {
    region = "us-east-2"
}

resource "aws_s3_bucket" "pella_state_bucket" {
    bucket = "pella-state-bucket"

    lifecycle {
      prevent_destroy = false
    }
}

resource "aws_s3_bucket_versioning" "pella_state_bucket_versioning" {
    bucket = aws_s3_bucket.pella_state_bucket.id

    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pella_state_bucket_encryption" {
    bucket = aws_s3_bucket.pella_state_bucket.id

    rule{
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
    }
}

resource "aws_dynamodb_table" "pella_state_table" {
    name = "pella_state_table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute{
        name = "LockID"
        type = "S"
    }
}