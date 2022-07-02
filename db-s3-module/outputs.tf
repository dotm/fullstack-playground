output "bucket_domain_name" {
  value = aws_s3_bucket.example_public.bucket_domain_name
}

output "bucket_readme_url" {
  value = "https://${aws_s3_bucket.example_public.bucket_domain_name}/${aws_s3_object.readme.id}"
}