terraform{
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
        tls = {
            source = "hashicorp/tls"
        }
    }
}

provider "tls" {
    
}

provider "aws" {
    region = "eu-west-1"
    profile = "default"
}

resource "tls_private_key" "mi_pareja_claves" {
    algorithm = "RSA"
    
    provisioner "local-exec" {
        command = "echo \"${self.private_key_pem}\" > clave_privada.pem"
    }

    provisioner "local-exec" {
        command = "echo \"${self.public_key_pem}\" > clave_publica.pem"
    }
    
    provisioner "local-exec" {
        command =  "chmod 700 clave_privada.pem"
    }
    
     provisioner "local-exec" {
        command =  "chmod 700 clave_privada.pem"
    }
}

resource "aws_key_pair" "victor_kp" {
    key_name = "victor_kp"
    public_key = tls_private_key.mi_pareja_claves.public_key_openssh
}

resource "aws_security_group" "reglas_red_victor" {
  name        = "reglas_victor"
  description = "Allow ssh inbound traffic"

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Tomcat from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

data "aws_ami" "ami_ubuntu" {
    most_recent = true
    owners = [ "099720109477" ]
    
    filter {
        name   ="name"
        values = [ "*ubuntu-xenial-16.04-amd64-server-*" ]
    }
    
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_instance" "mi_maquina_victor" {
    ami = data.aws_ami.ami_ubuntu.id
    instance_type = "t2.micro"
    security_groups = [
        aws_security_group.reglas_red_victor.name
    ]
    key_name = aws_key_pair.victor_kp.key_name
    
    tags = {
        Name = "MaquinaVictor"
    }
    
    connection {
        type = "ssh"
        host = self.private_dns
        user = "ubuntu"
        private_key = tls_private_key.mi_pareja_claves.private_key_pem
        port = 22
    }
    
    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update && sudo apt-get install python -y"
        ]
    }
    
    provisioner "local-exec" {
        command =  "echo \"${self.public_ip} ansible_connection=ssh ansible_port=22 ansible_user=ubuntu ansible_ssh_private_key_file=./clave_privada.pem\" > inventario.ini"
    }
    
    provisioner "local-exec" {
        command =  "ansible-playbook -i inventario.ini mi-playbook.yaml"
    }
    
    provisioner "remote-exec"{
        inline = [
            "docker run -p 8080:8080 -d bitnami/tomcat"
        ]
    }
}

output "mi_clave_privada" {
    value = tls_private_key.mi_pareja_claves.private_key_pem
}

output "mi_clave_publica" {
    value = tls_private_key.mi_pareja_claves.public_key_pem
}

output "ip_tomcat" {
    value = aws_instance.mi_maquina_victor.public_ip
}

output "dns_tomcat" {
    value = aws_instance.mi_maquina_victor.public_dns
}