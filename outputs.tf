output "key" {
  value = aws_iam_access_key.ci_user.id
}

output "secret" {
  value = aws_iam_access_key.ci_user.secret
}

output "api_aws_dns" {
  value = join("", aws_api_gateway_domain_name.main.*.cloudfront_domain_name)
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.services.name
}

output "ecs_cluster_service_name" {
  value = aws_ecs_service.interop.name
}

output "lambda_names" {
  value = [
    aws_lambda_function.batch.function_name,
    aws_lambda_function.token.function_name
  ]
}

output "rds_cluster_identifier" {
  value = module.rds_cluster_aurora_postgres.cluster_identifier
}

output "waf_acl_metric_name" {
  value = aws_wafregional_web_acl.acl.metric_name
}

