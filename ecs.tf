module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  cluster_name = "ecs-integrated"
  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  services = {
    ecs-frontend = {
      cpu    = 2048
      memory = 4096
      container_definitions = {
        ecs-frontend = {
          cpu       = 2048
          memory    = 4096
          essential = true
          network_mode = "awsvpc"
          image     = "trabajogestion/cinema-app:latest"
          environment = [
            { name = "CINEMAFOOD_URL", value = "http://cinemafood" },
            { name = "CINEMASEATS_URL", value = "http://cinemaseats" }
          ]
          port_mappings = [
            {
              name          = "ecs-frontend"
              containerPort = 80
              protocol      = "http"
            }
          ]
          readonly_root_filesystem = false
          enable_cloudwatch_logging = true
          memory_reservation = 100
        }
      }
      log_configuration = {
        logDriver = "awslogs"
        options = {
          Name        = "ecs-frontend"
          region      = "us-east-2"
          log_group   = "ecs"
        }
      }
      service_connect_configuration = {
        namespace = "test-namespace"
        service = {
          client_alias = {
            port     = 80
            dns_name = "ecs-frontend"
          }
          port_name      = "ecs-frontend"
          discovery_name = "ecs-frontend"
        }
      }
      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress_80 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          cidr_blocks = module.vpc.private_subnets_cidr_blocks
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    cinemafood = {
      cpu    = 1024
      memory = 4096
      container_definitions = {
        cinemafood = {
          cpu       = 512
          memory    = 1024
          essential = true
          network_mode = "awsvpc"
          image     = "trabajogestion/cinemafood:latest"
          port_mappings = [
            {
              name          = "cinemafood"
              containerPort = 8082
              protocol      = "http"
            }
          ]
          readonly_root_filesystem = false
          enable_cloudwatch_logging = true
          memory_reservation = 100
        }
      }
      log_configuration = {
        logDriver = "awslogs"
        options = {
          Name        = "cinemafood"
          region      = "us-east-2"
          log_group   = "ecs"
        }
      }
      service_connect_configuration = {
        namespace = "test-namespace"
        service = {
          client_alias = {
            port     = 8082
            dns_name = "cinemafood"
          }
          port_name      = "cinemafood"
          discovery_name = "cinemafood"
        }
      }
      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        vpc_ingress = {
          type                     = "ingress"
          from_port                = 8082
          to_port                  = 8082
          protocol                 = "tcp"
          cidr_blocks = module.vpc.private_subnets_cidr_blocks
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    cinemaseats = {
      cpu    = 1024
      memory = 4096
      container_definitions = {
        cinemaseats = {
          cpu       = 512
          memory    = 1024
          essential = true
          network_mode = "awsvpc"
          image     = "trabajogestion/cinemaseats:latest"
          port_mappings = [
            {
              name          = "cinemaseats"
              containerPort = 8081
              protocol      = "http"
            }
          ]
          readonly_root_filesystem = false
          enable_cloudwatch_logging = true
          memory_reservation = 100
        }
      }
      log_configuration = {
        logDriver = "awslogs"
        options = {
          Name        = "cinemaseats"
          region      = "us-east-2"
          log_group   = "ecs"
        }
      }
      service_connect_configuration = {
        namespace = "test-namespace"
        service = {
          client_alias = {
            port     = 8081
            dns_name = "cinemaseats"
          }
          port_name      = "cinemaseats"
          discovery_name = "cinemaseats"
        }
      }
      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        vpc_ingress = {
          type                     = "ingress"
          from_port                = 8081
          to_port                  = 8081
          protocol                 = "tcp"
          cidr_blocks = module.vpc.private_subnets_cidr_blocks
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  depends_on = [
    aws_service_discovery_http_namespace.namespace_cluster
  ]
}

resource "aws_service_discovery_http_namespace" "namespace_cluster" {
  name = "test-namespace"
  depends_on = [
    module.vpc
  ]
}

