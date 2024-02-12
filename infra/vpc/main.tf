module "vpc" {
  source = "../../modules/vpc"
   cidr = var.cidr
   name = var.name
}