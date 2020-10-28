# #########################################
# API Gateway REST API
# #########################################
resource "aws_api_gateway_rest_api" "main" {
  name = "${module.labels.id}-gw"
  tags = module.labels.tags

  endpoint_configuration {
    types = ["EDGE"]
  }
}

## custom domain name
resource "aws_api_gateway_domain_name" "main" {
  count           = local.enable_dns_count
  certificate_arn = aws_acm_certificate.wildcard_cert_us[0].arn
  domain_name     = var.interop_dns
  security_policy = "TLS_1_2"


  depends_on = [
    aws_acm_certificate.wildcard_cert_us[0],
    aws_acm_certificate_validation.wildcard_cert_us[0]
  ]
}

## execution role with s3 access
data "aws_iam_policy_document" "gw_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gateway" {
  name               = "${module.labels.id}-gw"
  assume_role_policy = data.aws_iam_policy_document.gw_assume_role_policy.json
}

data "aws_iam_policy_document" "gw" {
  statement {
    actions = ["s3:*", "logs:*"]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "gw" {
  name   = "${module.labels.id}-gw"
  path   = "/"
  policy = data.aws_iam_policy_document.gw.json
}

resource "aws_iam_role_policy_attachment" "gw" {
  role       = aws_iam_role.gateway.name
  policy_arn = aws_iam_policy.gw.arn
}

# #########################################
# API Gateway resources and mapping
# #########################################
## /
resource "aws_api_gateway_method" "root" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_rest_api.main.root_resource_id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({ statusCode : 404 })
  }
}

resource "aws_api_gateway_method_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "404"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "404"
}

## /diagnosiskeys
resource "aws_api_gateway_resource" "diagnosiskeys" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "diagnosiskeys"
}

## /diagnosiskeys/{proxy}
resource "aws_api_gateway_resource" "diagnosiskeys_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.diagnosiskeys.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "diagnosiskeys_proxy_options" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.diagnosiskeys_proxy.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "diagnosiskeys_proxy_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.diagnosiskeys_proxy.id
  http_method = aws_api_gateway_method.diagnosiskeys_proxy_options.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_method" "diagnosiskeys_proxy_any" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.diagnosiskeys_proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "diagnosiskeys_proxy_any_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.diagnosiskeys_proxy.id
  http_method             = aws_api_gateway_method.diagnosiskeys_proxy_any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.interop.dns_name}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy"              = "method.request.path.proxy",
    "integration.request.header.X-Routing-Secret" = "'${jsondecode(data.aws_secretsmanager_secret_version.api_gateway_header.secret_string)["header-secret"]}'",
    "integration.request.header.X-Forwarded-For"  = "'nope'"
  }
}

resource "aws_api_gateway_method_response" "diagnosiskeys_proxy_any" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.diagnosiskeys_proxy.id
  http_method = aws_api_gateway_method.diagnosiskeys_proxy_any.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "diagnosiskeys_proxy_any_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.diagnosiskeys_proxy.id
  http_method = aws_api_gateway_method.diagnosiskeys_proxy_any.http_method
  status_code = aws_api_gateway_method_response.diagnosiskeys_proxy_any.status_code
}

## /diagnosiskeys/healthcheck
resource "aws_api_gateway_resource" "diagnosiskeys_healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.diagnosiskeys.id
  path_part   = "healthcheck"
}

resource "aws_api_gateway_method" "diagnosiskeys_healthcheck_get" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.diagnosiskeys_healthcheck.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "diagnosiskeys_healthcheck_get_integration" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.diagnosiskeys_healthcheck.id
  http_method          = aws_api_gateway_method.diagnosiskeys_healthcheck_get.http_method
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  type                 = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 204
    })
  }
}

resource "aws_api_gateway_method_response" "diagnosiskeys_healthcheck_get" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.diagnosiskeys_healthcheck.id
  http_method = aws_api_gateway_method.diagnosiskeys_healthcheck_get.http_method
  status_code = "204"
}

resource "aws_api_gateway_integration_response" "diagnosiskeys_healthcheck_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.diagnosiskeys_healthcheck.id
  http_method = aws_api_gateway_method.diagnosiskeys_healthcheck_get.http_method
  status_code = aws_api_gateway_method_response.diagnosiskeys_healthcheck_get.status_code
}

# #########################################
# API Gateway Deployment
# #########################################
resource "aws_api_gateway_deployment" "live" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  stage_description = filemd5("${path.module}/gateway.tf")

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.root,
    aws_api_gateway_integration.diagnosiskeys_proxy_options_integration,
    aws_api_gateway_integration.diagnosiskeys_proxy_any_integration,
    aws_api_gateway_integration.diagnosiskeys_healthcheck_get_integration
  ]
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "${module.labels.id}-gw-access-logs"
  retention_in_days = var.logs_retention_days
}

resource "aws_api_gateway_stage" "live" {
  deployment_id = aws_api_gateway_deployment.live.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "live"
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = "[$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  }

  lifecycle {
    ignore_changes = [
      cache_cluster_size
    ]
  }
}

resource "aws_api_gateway_base_path_mapping" "main" {
  count       = local.enable_dns_count
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = "live"
  domain_name = aws_api_gateway_domain_name.main[0].domain_name
}
