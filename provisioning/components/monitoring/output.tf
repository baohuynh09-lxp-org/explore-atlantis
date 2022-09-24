output es_loggroup_arn {
  value = data.aws_cloudwatch_log_group.es_loggroup.arn
}

output kafka_loggroup_name {
  value = aws_cloudwatch_log_group.kafka_loggroup.name
}

output es_access_document_policy {
  value = data.aws_iam_policy_document.es_access_document.json
}