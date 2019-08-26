# ---------------------------------------------------------------------------------------------------------------------
# CREATE IAM POLICY RULES FOR SFTP BUCKET
# ---------------------------------------------------------------------------------------------------------------------

locals {
  s3_actions = {
    "rw" = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    "ro" = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
  }
}

data "aws_iam_policy_document" "transfer_server_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "transfer_server_assume_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      data.aws_s3_bucket.bucket.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        var.s3_bucket_folder == "" ? "*" : "${var.s3_bucket_folder}/*",
      ]
    }
  }

  statement {
    effect = "Allow"

    actions = local.s3_actions[var.access_type]

    resources = [
      var.s3_bucket_folder == "" ? "${data.aws_s3_bucket.bucket.arn}/*" : "${data.aws_s3_bucket.bucket.arn}/${var.s3_bucket_folder}/*",
      var.s3_bucket_folder == "" ? data.aws_s3_bucket.bucket.arn : "${data.aws_s3_bucket.bucket.arn}/${var.s3_bucket_folder}",
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE IAM POLICY AND ROLE FROM DEFINED RULES
# ---------------------------------------------------------------------------------------------------------------------

# resource "random_string" "iam_id" {
#   length  = 8
#   special = false
# }

resource "aws_iam_role" "transfer_server_assume_role" {
  name               = "transfer-${var.transfer_server_id}-${var.username}"
  assume_role_policy = data.aws_iam_policy_document.transfer_server_assume_role.json
}

resource "aws_iam_role_policy" "transfer_server_policy" {
  name   = "transfer-${var.transfer_server_id}-${var.username}"
  role   = aws_iam_role.transfer_server_assume_role.name
  policy = data.aws_iam_policy_document.transfer_server_assume_policy.json
}
