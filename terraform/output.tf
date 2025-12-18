

#  ECS ALB Output 
output "ecs_alb_dns_name" {
  description = "DNS name of the ECS Application Load Balancer"
  value       = var.deploy_ecs ? aws_lb.ecs_alb[0].dns_name : null
}


output "output_path" {
  value = var.deploy_lambda ? data.archive_file.lambda_zip[0].output_path : null
}

output "http_api_url" {
  value = var.deploy_lambda ? aws_apigatewayv2_api.apigw_pt[0].api_endpoint : null
}
