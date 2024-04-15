# Définition du fournisseur AWS
provider "aws" {
  region = "us-east-1"  # Remplacez par votre région AWS
  access_key_id = var.aws_access_key_id
  secret_access_key = var.aws_secret_access_key
}

# Définition du réseau VPC
resource "aws_vpc" "wordpress_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Définition du sous-réseau public
resource "aws_subnet" "wordpress_public_subnet" {
  vpc_id = aws_vpc.wordpress_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Définition de la passerelle internet
resource "aws_internet_gateway" "wordpress_gateway" {
  vpc_id = aws_vpc.wordpress_vpc.id
}

# Définition de la route vers Internet
resource "aws_route_table" "wordpress_public_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_gateway.id
  }
}

# Définition de l'association de sous-réseau à la route
resource "aws_subnet_association" "wordpress_public_subnet_association" {
  subnet_id = aws_subnet.wordpress_public_subnet.id
  route_table_id = aws_route_table.wordpress_public_route_table.id
}

# Définition de la sécurité du groupe pour l'instance WordPress
resource "aws_security_group" "wordpress_security_group" {
  name = "wordpress-security-group"
  vpc_id = aws_vpc.wordpress_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.ssh_cidr_block]
  }
}

# Définition de l'instance AWS
resource "aws_instance" "wordpress_instance" {
  ami           = "ami-0c55b159cbfafe1f0"   # AMI Ubuntu 20.04 LTS
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.wordpress_public_subnet.id
  security_groups = [aws_security_group.wordpress_security_group.id]

  user_data = <<-EOF
#!/bin/bash

# Mettre à jour les packages
sudo apt update && sudo apt upgrade -y

# Installer le serveur web Apache
sudo apt install apache2 -y

# Installer MySQL
sudo apt install mysql-server -y

# Sécuriser l'installation de MySQL
sudo mysql_secure_installation

# Télécharger et décompresser WordPress
wget https://wordpress.org/latest.tar.gz
tar -xf latest.tar.gz

# Déplacer les fichiers WordPress vers le répertoire approprié
sudo mv wordpress/* /var/www/html/

# Configurer les permissions pour le dossier WordPress
sudo chown -R www-data:www-data /var/www/html/

# Redémarrer le service Apache
sudo systemctl restart apache2

# Ouvrir le navigateur et accéder à l'adresse IP de l'instance pour lancer 
l'installation de WordPress
EOF
}

# Définition de la base de données RDS
resource "aws_db_instance" "wordpress_db" {
  engine         = "mysql"
  engine_version = "5.7"
  instance_type = "db.t2.micro"
  allocated_storage = 10

  db_name = "wordpress"
  master_username = "wordpress"
  master_password = var.db_password

  publicly_accessible = true
}

