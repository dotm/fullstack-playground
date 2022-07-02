resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-bucket"
  tags   = {}
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "private"
}