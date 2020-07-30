# #########################################
# ALB Interop
# #########################################
module "alb_interop_sg" {
  source      = "./modules/security-group"
  open_egress = true
  name        = "${module.labels.id}-alb-interop"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = module.labels.tags
}

resource "aws_security_group_rule" "alb_interop_http_ingress" {
  description       = "Allows connection on port 80 from anywhere"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.alb_interop_sg.id
}

resource "aws_lb" "interop" {
  name                             = "${module.labels.id}-interop"
  internal                         = false
  subnets                          = module.vpc.public_subnets
  security_groups                  = ["${module.alb_interop_sg.id}"]
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  ip_address_type                  = "dualstack"
  enable_deletion_protection       = true

  tags = module.labels.tags
}

resource "aws_lb_target_group" "interop" {
  name                 = "${module.labels.id}-interop"
  port                 = var.interop_listening_port
  protocol             = var.interop_listening_protocol
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = "10"
  target_type          = "ip"

  health_check {
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = module.labels.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "interop_http" {
  load_balancer_arn = aws_lb.interop.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "header_check" {
  listener_arn = aws_lb_listener.interop_http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.interop.arn
  }

  condition {
    http_header {
      http_header_name = "X-Routing-Secret"
      values           = [jsondecode(data.aws_secretsmanager_secret_version.api_gateway_header.secret_string)["header-secret"]]
    }
  }
}
