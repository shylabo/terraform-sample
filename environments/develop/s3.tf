
# ***************************
# private
# ***************************
resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform-20230310"

  // pocのため便宜上毎回強制削除
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ***************************
# public
# ***************************
resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform-20230310"
  acl    = "public-read"

  // pocのため便宜上毎回強制削除
  force_destroy = true

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

# ***************************
# log
# ***************************
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform-20230310"

  // pocのため便宜上毎回強制削除
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["219788221340"]
    }
  }
}

# ***************************
# force destroy
# ***************************
resource "aws_s3_bucket" "force_destroy" {
  bucket        = "force-destroy-pragmatic-terraform-20230310"
  force_destroy = true
}

# ***************************
# prevent destroy
# ***************************
// prevent_destroyはTerraformの全リソースに設定可能
resource "aws_s3_bucket" "prevent_destroy_bucket" {
  bucket = "prevent-destroy-pragmatic-terraform"

  lifecycle {
    prevent_destroy = true
  }
}
