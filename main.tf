# ---------------------------------------------------------------------------------------------------------------------
# GET EXISTING S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------

data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN USER WITH A SSH KEY FOR THE SHARED TRANSFER SERVER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_transfer_user" "transfer_user" {
  server_id      = var.transfer_server_id
  role           = aws_iam_role.transfer_server_assume_role.arn
  home_directory = "/${data.aws_s3_bucket.bucket.id}/${var.s3_bucket_folder}"
  user_name      = var.username
}

resource "aws_transfer_ssh_key" "transfer_ssh_key" {
  count     = length(var.ssh_public_keys)
  server_id = var.transfer_server_id
  user_name = aws_transfer_user.transfer_user.user_name
  body      = var.ssh_public_keys[count.index]
}
