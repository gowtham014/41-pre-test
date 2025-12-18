variable "deploy_ecs" {
  description = "Deploy the ECS Cluster and Fargate Service"
  type        = bool
  default     = false
}

variable "deploy_lambda" {
  description = "Deploy the Lambda Function and API Gateway"
  type        = bool
  default     = false
}