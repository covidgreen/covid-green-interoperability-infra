# #########################################
# ECS General Resources
# #########################################
data "aws_iam_policy_document" "interop_ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "interop_ecs_task_execution" {
  name               = "${module.labels.id}-interop-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.interop_ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "interop_ecs_task_execution" {
  role       = aws_iam_role.interop_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "interop_ecs_task_role" {
  name               = "${module.labels.id}-interop-task-role"
  assume_role_policy = data.aws_iam_policy_document.interop_ecs_assume_role_policy.json
}

data "aws_iam_policy_document" "interop_ecs_task_policy" {
  statement {
    actions = ["ssm:GetParameter", "secretsmanager:GetSecretValue"]
    resources = [
      aws_ssm_parameter.log_level.arn,
      aws_ssm_parameter.interop_port.arn,
      aws_ssm_parameter.interop_host.arn,
      aws_ssm_parameter.cors_origin.arn,
      aws_ssm_parameter.db_host.arn,
      aws_ssm_parameter.db_reader_host.arn,
      aws_ssm_parameter.db_port.arn,
      aws_ssm_parameter.db_database.arn,
      aws_ssm_parameter.db_ssl.arn,
      aws_ssm_parameter.batch_size.arn,
      aws_ssm_parameter.batch_url.arn,
      data.aws_secretsmanager_secret_version.rds.arn,
      data.aws_secretsmanager_secret_version.rds_read_write_create.arn,
      data.aws_secretsmanager_secret_version.jwt.arn
    ]
  }

  statement {
    actions = ["sqs:*"]
    resources = [
      aws_sqs_queue.batch.arn
    ]
  }
}

resource "aws_iam_policy" "interop_ecs_task_policy" {
  name   = "${module.labels.id}-ecs-interop-task-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.interop_ecs_task_policy.json
}

resource "aws_iam_role_policy_attachment" "interop_ecs_task_policy" {
  role       = aws_iam_role.interop_ecs_task_role.name
  policy_arn = aws_iam_policy.interop_ecs_task_policy.arn
}

# #########################################
# Interop Service
# #########################################
data "template_file" "interop_service_container_definitions" {
  template = file("templates/interop_service_task_definition.tpl")

  vars = {
    interop_image_uri    = "${aws_ecr_repository.interop.repository_url}:latest"
    config_var_prefix    = local.config_var_prefix
    migrations_image_uri = "${aws_ecr_repository.migrations.repository_url}:latest"
    listening_port       = var.interop_listening_port
    logs_service_name    = aws_cloudwatch_log_group.interop.name
    log_group_region     = var.aws_region
    node_env             = "production"
    aws_region           = var.aws_region
  }
}

resource "aws_ecs_task_definition" "interop" {
  family                   = "${module.labels.id}-interop"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.interop_services_task_cpu
  memory                   = var.interop_services_task_memory
  execution_role_arn       = aws_iam_role.interop_ecs_task_execution.arn
  task_role_arn            = aws_iam_role.interop_ecs_task_role.arn
  container_definitions    = data.template_file.interop_service_container_definitions.rendered

  tags = module.labels.tags
}

resource "aws_ecs_service" "interop" {
  name            = "${module.labels.id}-interop"
  cluster         = aws_ecs_cluster.services.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.interop.arn
  desired_count   = var.interop_service_desired_count

  network_configuration {
    security_groups = [module.interop_sg.id]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.interop.id
    container_name   = "interop"
    container_port   = var.interop_listening_port
  }

  depends_on = [
    aws_lb_listener.interop_http
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

module "interop_autoscale" {
  source                      = "./modules/ecs-autoscale-service"
  ecs_cluster_resource_name   = aws_ecs_cluster.services.name
  service_resource_name       = aws_ecs_service.interop.name
  ecs_autoscale_max_instances = var.interop_ecs_autoscale_max_instances
  ecs_autoscale_min_instances = var.interop_ecs_autoscale_min_instances
  ecs_as_cpu_high_threshold   = var.interop_cpu_high_threshold
  ecs_as_cpu_low_threshold    = var.interop_cpu_low_threshold
  ecs_as_mem_high_threshold   = var.interop_mem_high_threshold
  ecs_as_mem_low_threshold    = var.interop_mem_low_threshold
  tags                        = module.labels.tags
}

# #########################################
# Interop log group
# #########################################
resource "aws_cloudwatch_log_group" "interop" {
  name              = "${module.labels.id}-interop"
  retention_in_days = var.logs_retention_days
  tags              = module.labels.tags

  lifecycle {
    create_before_destroy = true
  }
}

# #########################################
# Security group - Allow all access from LB
# #########################################
module "interop_sg" {
  source      = "./modules/security-group"
  open_egress = true
  name        = "${module.labels.id}-interop"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = module.labels.tags
}

resource "aws_security_group_rule" "interop_ingress_http" {
  description              = "Allows backend services to accept connections from ALB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.alb_interop_sg.id
  security_group_id        = module.interop_sg.id
}
