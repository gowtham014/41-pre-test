# Security Group for ALB
resource "aws_security_group" "alb_security_group" {
  count  = var.deploy_ecs ? 1 : 0
  name   = "alb-security-group"
  vpc_id = module.vpc.vpc_id
}
resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  count             = var.deploy_ecs ? 1 : 0
  security_group_id = aws_security_group.alb_security_group[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress" {
  count             = var.deploy_ecs ? 1 : 0
  security_group_id = aws_security_group.alb_security_group[0].id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_ingress" {
  count             = var.deploy_ecs ? 1 : 0
  security_group_id = aws_security_group.ecs_security_group[0].id
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  # security_group_id = aws_security_group.ecs_security_group[0].id
  referenced_security_group_id = aws_security_group.alb_security_group[0].id
  depends_on                   = [aws_security_group.ecs_security_group]
}

resource "aws_vpc_security_group_egress_rule" "ecs_egress" {
  count             = var.deploy_ecs ? 1 : 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.ecs_security_group[0].id
  depends_on        = [aws_security_group.ecs_security_group]
}

# Security Group for ECS
resource "aws_security_group" "ecs_security_group" {
  count      = var.deploy_ecs ? 1 : 0
  name       = "ecs-security-group"
  vpc_id     = module.vpc.vpc_id
  depends_on = [aws_security_group.alb_security_group]
}

# ECS Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  count = var.deploy_ecs ? 1 : 0
  name  = "pretest-ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
  depends_on = [aws_security_group.ecs_security_group]
}
# Attach Policy to ECS Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  count      = var.deploy_ecs ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  depends_on = [aws_iam_role.ecs_task_execution_role]
}

# ECS Cluster
resource "aws_ecs_cluster" "pretest_ecs_cluster" {
  count = var.deploy_ecs ? 1 : 0
  name  = "pretest-ecs-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ecs_task" {
  count                    = var.deploy_ecs ? 1 : 0
  family                   = "pretest-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role[0].arn

  container_definitions = jsonencode([
    {
      name      = "pretest-container"
      image     = var.ecs_image_name
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
    }
  ])
  depends_on = [aws_ecs_cluster.pretest_ecs_cluster]
}

#  AWS LOAD BALANCER FOR ECS SERVICE
resource "aws_lb" "ecs_alb" {
  count                      = var.deploy_ecs ? 1 : 0
  name                       = "pretest-ecs-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_security_group[0].id]
  subnets                    = slice(module.vpc.public_subnets, 0, 2)
  enable_deletion_protection = false
  depends_on                 = [aws_security_group.alb_security_group]
}

# ALB Target Group for ECS Service
resource "aws_lb_target_group" "ecs_tg" {
  count       = var.deploy_ecs ? 1 : 0
  name        = "pretest-ecs-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  depends_on = [aws_lb.ecs_alb]
}

#  ALB Listener for ECS Service
resource "aws_lb_listener" "ecs_alb_listener" {
  count             = var.deploy_ecs ? 1 : 0
  load_balancer_arn = aws_lb.ecs_alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[0].arn
  }
  depends_on = [aws_lb_target_group.ecs_tg]
}

# ECS Service
resource "aws_ecs_service" "ecs_service" {
  count           = var.deploy_ecs ? 1 : 0
  name            = "pretest-ecs-service"
  cluster         = aws_ecs_cluster.pretest_ecs_cluster[0].id
  task_definition = aws_ecs_task_definition.ecs_task[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = slice(module.vpc.private_subnets, 0, 2)
    security_groups  = [aws_security_group.ecs_security_group[0].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg[0].arn
    container_name   = "pretest-container"
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.ecs_alb_listener]
}


