resource "aws_instance" "server" {
  count = var.instance_count

  ami                         = var.ami
  instance_type               = var.instance_type
  user_data                   = var.user_data
  subnet_id                   = distinct(compact(concat(list(var.subnet_id), var.subnet_ids)))[count.index]
  key_name                    = ${var.key_name}"
  monitoring                  = var.monitoring
  vpc_security_group_ids      = var.vpc_security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = var.associate_public_ip_address
  ebs_optimized               = var.ebs_optimized
  tenancy                     = var.tenancy
  disable_api_termination     = var.disable_api_termination
  tags = {
    Name        = format("%s-%d", var.name, count.index)
    kafka-index = count.index
    type        = var.tag_type
    Env         = var.environment
    build       = "terraform"
  }
  volume_tags = {
    Name  = format("%s-%d", var.name, count.index)
    build = "terraform"
  }
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = var.root_volume_delete_on_termination
  }
  lifecycle {
    ignore_changes = [
      private_ip,
      root_block_device,
      ebs_block_device,
      ami,
      volume_tags
    ]
  }
}

resource "aws_ebs_volume" "data" {
  count             = var.create_ebs ? var.instance_count : 0
  availability_zone = aws_instance.server[count.index].availability_zone
  size              = var.ebs_volume_size
  type              = "gp2"
  tags = {
    Name  = format("%s-%d-data", var.name, count.index)
    build = "terraform"
  }
}
resource "aws_volume_attachment" "data" {
  count       = var.create_ebs ? var.instance_count : 0
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.*.id[count.index]
  instance_id = aws_instance.server.*.id[count.index]
}
