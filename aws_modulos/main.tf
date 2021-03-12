terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
}

provider "aws" {
    region = var.region_aws
    profile = "default"
}

module "claves" {
    source = "./claves"
    longitud_clave_rsa = 4096
    id_clave = var.id_clave
}
