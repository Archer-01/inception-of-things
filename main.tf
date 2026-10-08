variable "aws_region" {
  description = "AWS region that hosts the HLS media bucket."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally-unique name for the private HLS media bucket."
  type        = string
}

variable "custom_production_origins" {
  description = "Additional production origins allowed to fetch HLS assets from S3."
  type        = list(string)
  default     = []
}

variable "live_segment_prefix" {
  description = "Prefix used for live HLS segments to expire automatically."
  type        = string
  default     = "live/"
}

variable "live_segment_expiration_days" {
  description = "Retention period for live HLS segments."
  type        = number
  default     = 2
}

variable "vercel_project_name" {
  description = "Name of the Vercel project to create/manage."
  type        = string
}

variable "vercel_framework" {
  description = "Framework preset for Vercel project."
  type        = string
  default     = "other"
}

locals {
  allowed_origins = concat(["https://*.vercel.app"], var.custom_production_origins)
  env_targets     = toset(["production", "preview"])
}

resource "aws_s3_bucket" "hls_media" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "hls_media" {
  bucket = aws_s3_bucket.hls_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "hls_media" {
  bucket = aws_s3_bucket.hls_media.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "hls_media" {
  bucket = aws_s3_bucket.hls_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "hls_media" {
  bucket = aws_s3_bucket.hls_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = local.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 300
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "hls_media" {
  bucket = aws_s3_bucket.hls_media.id

  rule {
    id     = "expire-live-hls-segments"
    status = "Enabled"

    filter {
      prefix = var.live_segment_prefix
    }

    expiration {
      days = var.live_segment_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.live_segment_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "vercel_project" "hls_origin" {
  name      = var.vercel_project_name
  framework = var.vercel_framework
}

resource "vercel_project_environment_variable" "s3_bucket" {
  for_each = local.env_targets

  project_id = vercel_project.hls_origin.id
  target     = [each.key]
  key        = "AWS_S3_BUCKET"
  value      = aws_s3_bucket.hls_media.id
}

resource "vercel_project_environment_variable" "aws_region" {
  for_each = local.env_targets

  project_id = vercel_project.hls_origin.id
  target     = [each.key]
  key        = "AWS_REGION"
  value      = var.aws_region
}

output "hls_bucket_id" {
  value       = aws_s3_bucket.hls_media.id
  description = "Private S3 bucket ID used for HLS media segments."
}

output "hls_bucket_regional_domain_name" {
  value       = aws_s3_bucket.hls_media.bucket_regional_domain_name
  description = "Regional S3 endpoint that can be consumed by the stream switcher."
}

output "vercel_project_id" {
  value       = vercel_project.hls_origin.id
  description = "Created or managed Vercel project ID."
}
