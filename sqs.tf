resource "aws_sqs_queue" "batch" {
  name = "batch"
  tags = module.labels.tags
}
