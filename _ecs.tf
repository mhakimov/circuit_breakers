resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
}

resource "aws_service_discovery_private_dns_namespace" "ns" {
  name        = "${var.project}-svc.local"
  vpc         = module.network.vpc_id
  description = "Private DNS namespace for ${var.project}"
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = module.network.vpc_id
  ingress {
    from_port   = 3101
    to_port     = 3101
    protocol    = "tcp"
    cidr_blocks = ["10.20.11.0/24", "10.20.12.0/24"]
    description = "Allow internal VPC on app port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_service" "appmgr" {
  name         = "application-manager-api"
  namespace_id = aws_service_discovery_private_dns_namespace.ns.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ns.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config { failure_threshold = 1 }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/circuit_breakers",
          awslogs-region        = "${var.aws_region}",
          awslogs-stream-prefix = "ecs"
        }
      },
      name         = "app"
      image        = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/order_manager_repo:latest" # replace with your image
      portMappings = [{ containerPort = 3101, protocol = "tcp" }]
      environment = [
        { "name" : "FAILURE_RATE", "value" : "0.3" },
        { "name" : "TIMEOUT_RATE", "value" : "0.7" }
      ]
      essential   = true
      healthCheck = { command = ["CMD-SHELL", "curl -f http://localhost:3101/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 30 }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1


  network_configuration {
    # subnets          = values(aws_subnet.private)[*].id
    subnets          = module.network.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }


  service_registries {
    registry_arn = aws_service_discovery_service.appmgr.arn
  }


  depends_on = [aws_service_discovery_service.appmgr]
}

