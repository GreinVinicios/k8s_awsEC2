terraform {
  backend "s3" {
    bucket         = "greink8s-ec2-tfstate"
    key            = "greink8s/terraform.tfstate"
    region         = "us-west-1"
  }
}
