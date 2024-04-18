resource "null_resource" "test1" {
 connection {
    type     = "ssh"
    user     = "iac_2_instance"
    private_key = file("./alexkey.pem")
    host     = aws_instance.iac_2_instance.public_ip
  }


 provisioner "remote-exec" {
    inline = [
      "sudo yum install http -y",
      "sudo yum install php -y",
      "sudo systemctl start httpd",
      "sudo systemctl start php",
      "cd /var/www/html",
      "sudo wget https://wordpress.org/latest.zip",
      "sudo unzip latest.zip"
    ]
  }
}

