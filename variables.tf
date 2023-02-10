variable "ami" {
  type = string
  default = "ami-0d50e5e845c552faf"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "access_key" {}

variable "secret_key" {}

variable "region" {
  default = "us-west-1"   
}
