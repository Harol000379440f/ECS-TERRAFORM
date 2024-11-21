resource "aws_ecs_cluster" "my_cluster" {
  name = "app-cluster"
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = <<DEFINITION
  [
    {
      "name": "frontend",
      "image": "trabajogestion/cinema-app:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "environment": [
        {
          "name": "CINEMAFOOD_URL",
          "value": "http://cinemafood"
        },
        {
          "name": "CINEMASEATS_URL",
          "value": "http://cinemaseats"
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_ecs_task_definition" "cinemafood_task" {
  family                   = "cinemafood"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = <<DEFINITION
  [
    {
      "name": "cinemafood",
      "image": "trabajogestion/cinemafood:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8082,
          "hostPort": 8082
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_ecs_task_definition" "cinemaseats_task" {
  family                   = "cinemaseats"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = <<DEFINITION
  [
    {
      "name": "cinemaseats",
      "image": "trabajogestion/cinemaseats:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8081,
          "hostPort": 8081
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "frontend"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.load_balancer_security_group.id]
  }
}

resource "aws_ecs_service" "cinemafood_service" {
  name            = "cinemafood-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.cinemafood_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.load_balancer_security_group.id]
  }
}

resource "aws_ecs_service" "cinemaseats_service" {
  name            = "cinemaseats-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.cinemaseats_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.load_balancer_security_group.id]
  }
}

