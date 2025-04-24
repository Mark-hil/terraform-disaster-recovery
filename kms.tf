resource "aws_kms_key" "primary" {
  description             = "KMS key for primary region encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key" "dr" {
  provider = aws.dr
  description             = "KMS key for DR region encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
