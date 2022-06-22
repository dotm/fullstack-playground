resource "aws_s3_bucket" "sej_clip_bucket" {
  bucket = "dev-sej-clip-bucket"
}

resource "aws_s3_bucket_acl" "sej_clip_bucket_acl" {
  bucket = aws_s3_bucket.sej_clip_bucket.id
  acl    = "private"
}