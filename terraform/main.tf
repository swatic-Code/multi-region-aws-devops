module "primary" {
  source        = "./modules/region"
  providers     = { aws = aws.primary }
  app_name      = var.app_name
  vpc_cidr      = "10.0.0.0/16"
  instance_type = var.instance_type
  min_size      = var.min_size
  max_size      = var.max_size
}

module "secondary" {
  source        = "./modules/region"
  providers     = { aws = aws.secondary }
  app_name      = var.app_name
  vpc_cidr      = "10.1.0.0/16"
  instance_type = var.instance_type
  min_size      = var.min_size
  max_size      = var.max_size
}

# ---------- AWS Global Accelerator ----------
resource "aws_globalaccelerator_accelerator" "this" {
  provider        = aws.ga
  name            = "${var.app_name}-accelerator"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "http" {
  provider        = aws.ga
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  provider              = aws.ga
  listener_arn          = aws_globalaccelerator_listener.http.id
  endpoint_group_region = var.primary_region
  health_check_protocol = "HTTP"
  health_check_path     = "/health"
  health_check_port     = 80

  endpoint_configuration {
    endpoint_id = module.primary.alb_arn
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  provider              = aws.ga
  listener_arn          = aws_globalaccelerator_listener.http.id
  endpoint_group_region = var.secondary_region
  health_check_protocol = "HTTP"
  health_check_path     = "/health"
  health_check_port     = 80

  endpoint_configuration {
    endpoint_id = module.secondary.alb_arn
    weight      = 100
  }
}
