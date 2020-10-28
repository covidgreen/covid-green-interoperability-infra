data "archive_file" "batch" {
  type        = "zip"
  output_path = "${path.module}/.zip/${module.labels.id}_batch.zip"
  source_file = "${path.module}/templates/lambda-placeholder.js"
}

data "aws_iam_policy_document" "batch_policy" {
  statement {
    actions = [
      "s3:*",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "sqs:*"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      data.aws_secretsmanager_secret_version.rds_read_write.arn,
      data.aws_secretsmanager_secret_version.rds.arn,
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      aws_ssm_parameter.db_host.arn,
      aws_ssm_parameter.db_port.arn,
      aws_ssm_parameter.db_database.arn,
      aws_ssm_parameter.db_ssl.arn,
      aws_ssm_parameter.batch_size.arn
    ]
  }
}

data "aws_iam_policy_document" "batch_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "batch_policy" {
  name   = "${module.labels.id}-lambda-batch-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.batch_policy.json
}

resource "aws_iam_role" "batch" {
  name               = "${module.labels.id}-lambda-batch"
  assume_role_policy = data.aws_iam_policy_document.batch_assume_role.json
  tags               = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "batch_policy" {
  role       = aws_iam_role.batch.name
  policy_arn = aws_iam_policy.batch_policy.arn
}

resource "aws_iam_role_policy_attachment" "batch_logs" {
  role       = aws_iam_role.batch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "batch" {
  filename         = "${path.module}/.zip/${module.labels.id}_batch.zip"
  function_name    = "${module.labels.id}-batch"
  source_code_hash = data.archive_file.batch.output_base64sha256
  role             = aws_iam_role.batch.arn
  runtime          = "nodejs10.x"
  handler          = "batch.handler"
  memory_size      = 128
  timeout          = 15
  tags             = module.labels.tags

  vpc_config {
    security_group_ids = [module.lambda_sg.id]
    subnet_ids         = module.vpc.private_subnets
  }

  environment {
    variables = {
      CONFIG_VAR_PREFIX = local.config_var_prefix,
      NODE_ENV          = "production"
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }
}

resource "aws_lambda_event_source_mapping" "batch" {
  event_source_arn = aws_sqs_queue.batch.arn
  function_name    = aws_lambda_function.batch.arn
}

resource "aws_cloudwatch_event_rule" "batch_schedule" {
  schedule_expression = var.batch_schedule
}

resource "aws_cloudwatch_event_target" "batch_schedule" {
  rule      = aws_cloudwatch_event_rule.batch_schedule.name
  target_id = "batch"
  arn       = aws_lambda_function.batch.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_batch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.batch.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.batch_schedule.arn
}
