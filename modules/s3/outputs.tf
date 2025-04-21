output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.primary.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.primary.bucket_domain_name
}