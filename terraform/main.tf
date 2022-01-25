terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

#S3

#LANDING ZONE
resource "aws_s3_bucket" "landing_zone" {
  bucket = "pismo-landing-zone"
  acl    = "private"
  
  versioning {
    enabled = true
  }

  tags = {
    Name        = "Landing Zone"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "landing_zone" {
  bucket = aws_s3_bucket.landing_zone.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#STAGE ZONE
resource "aws_s3_bucket" "stage_zone" {
  bucket = "pismo-stage-zone"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "Stage Zone"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "stage_zone" {
  bucket = aws_s3_bucket.stage_zone.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#TRUSTED ZONE
resource "aws_s3_bucket" "trusted_zone" {
  bucket = "pismo-trusted-zone"
  acl    = "private"
  
  versioning {
    enabled = true
  }

  tags = {
    Name        = "Trusted Zone"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "trusted_zone" {
  bucket = aws_s3_bucket.trusted_zone.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#ATHENA OUTPUT LOCATION
resource "aws_s3_bucket" "athena_output_location" {
  bucket = "pismo-athena-output-location"
  acl    = "private"

  tags = {
    Name        = "Athena Output Location"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_output_location" {
  bucket = aws_s3_bucket.athena_output_location.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#SCRIPTS GLUE
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "pismo-glue-scripts"
  acl    = "private"

  tags = {
    Name        = "Glue Scripts Location"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#GLUE CRAWLER-ROLE-POLICY/DATABASE/CRAWLER-LANDING-ZONE

resource "aws_iam_role" "glue_crawler" {
  name = "AWSGlueServiceRole-CrawlerS3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "glue_crawler" {
  name        = "s3-get-put-object-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:PutObject"
        ],
        "Resource": [
            "arn:aws:s3:::*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_s3_get_put_object_policy" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = aws_iam_policy.glue_crawler.arn
}

resource "aws_iam_role_policy_attachment" "attach_glue_service_role_policy" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_catalog_database" "glue_database_stage" {
  name = "pismo-stage-zone"
}

resource "aws_glue_catalog_database" "glue_database_trusted" {
  name = "pismo-trusted-zone"
}

resource "aws_glue_crawler" "stage_zone" {
  database_name = aws_glue_catalog_database.glue_database_stage.name
  name          = "pismo-s3-stage-zone"
  role          = aws_iam_role.glue_crawler.arn

  s3_target {
    path = "s3://${aws_s3_bucket.stage_zone.bucket}/events"
  }
}

resource "aws_glue_crawler" "trusted_zone" {
  database_name = aws_glue_catalog_database.glue_database_trusted.name
  name          = "pismo-s3-trusted-zone"
  role          = aws_iam_role.glue_crawler.arn

  s3_target {
    path = "s3://${aws_s3_bucket.trusted_zone.bucket}/events"
  }
}

#GLUE JOB

resource "aws_iam_role" "glue_job" {
  name = "AWSGlueServiceRole-GlueJob"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_full_access" {
  name        = "s3-full-access-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:*",
            "s3-object-lambda:*"
        ],
        "Resource": [
            "arn:aws:s3:::*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_s3_full_access_policy" {
  role       = aws_iam_role.glue_job.name
  policy_arn = aws_iam_policy.s3_full_access.arn
}

resource "aws_glue_job" "glue_job_parser" {
  name     = "parser"
  role_arn = aws_iam_role.glue_job.arn
  glue_version = "2.0"

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/parser/parser.py"
  }
}

resource "aws_iam_policy" "glue_full_access" {
  name        = "glue-full-access-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "glue:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::aws-glue-*/*",
                "arn:aws:s3:::*/*aws-glue-*/*",
                "arn:aws:s3:::aws-glue-*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_glue_full_access_policy" {
  role       = aws_iam_role.glue_job.name
  policy_arn = aws_iam_policy.glue_full_access.arn
}

resource "aws_glue_job" "glue_job_distributor" {
  name     = "distributor"
  role_arn = aws_iam_role.glue_job.arn
  glue_version = "2.0"

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/distributor/distributor.py"
  }
}