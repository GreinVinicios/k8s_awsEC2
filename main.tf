module "ec2" {
  source = "./ec2"

  ami           = var.ami
  instance_type = var.instance_type
}