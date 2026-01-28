#-------------------------
# Key pair
#-------------------------
resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("./src/basevpc-keypair.pub")
  // Use ssh-keygen and make src dir, then put both keypair-files in before applying
  // Don't forget rename secret-key-file to ".pem"

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}

#-------------------------
# SSM Parameter Store
#-------------------------
resource "aws_ssm_parameter" "host" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_HOST"
  type  = "String"
  value = aws_db_instance.mysql_standalone.address
}

resource "aws_ssm_parameter" "port" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PORT"
  type  = "String"
  value = aws_db_instance.mysql_standalone.port
}

# resource "aws_ssm_parameter" "database" {
#   name  = "/${var.project}/${var.environment}/app/MYSQL_DATABASE"
#   type  = "String"
#   value = aws_db_instance.mysql_standalone.name
# }

resource "aws_ssm_parameter" "username" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_USERNAME"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.username
}

resource "aws_ssm_parameter" "password" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PASSWORD"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.password
}

#-------------------------
# EC2 Instance
#-------------------------
// If you want to add some instance already made, use command "terraform import <ADDRESS> <ID>" 
// and resource block(from "terraform state show <ADDRESS>") or like below
//
// import {
//    to = aws_instance.example  # replace this to configuration
//    id = "i-1234567890abcdef0" # take from instance-ID
// }

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.app.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.app_ec2_profile.name
  vpc_security_group_ids = [
    aws_security_group.app_sg.id,
    aws_security_group.ops_sg.id
  ]
  key_name = aws_key_pair.keypair.key_name

  tags = {
    Name    = "${var.project}-${var.environment}-app-ec2"
    Project = var.project
    Env     = var.environment
    Type    = "app"
  }
}