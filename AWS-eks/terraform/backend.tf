terraform {
  backend "s3" {
    bucket         = "terraform-remote-locking-vikas"
    key            = "env:/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    use_lockfile   = true
  }
}
