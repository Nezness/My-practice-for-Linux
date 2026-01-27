data "aws_prefix_list" "s3_pl" {
  name = "com.amazonaws.ap-northeast-1.s3"
}

data "aws_ami" "app" {
  most_recent = true
  owners      = ["self", "amazon"]

  # filter {
  #   name = "name"
  #   values = [ "#Put ami-ID you made" ] # Notice
  # }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.10.20260105.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}