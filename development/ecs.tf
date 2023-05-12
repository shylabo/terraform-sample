resource "aws_ecs_cluster" "example" {
  name = "example"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "example" // タスク定義のプレフィックス + リビジョン番号（example:1）
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc" // Fargate起動タイプの場合
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

resource "aws_ecs_task_definition" "example_batch" {
  family                   = "example-batch"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./batch_container_definitions.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

resource "aws_ecs_service" "example" {
  name                              = "example"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 2 // 維持するタスク数（1だとコンテナが異常終了するとタスク再起動までアクセスできないので2以上）
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0" // デフォルトはLATESTだが最新でない可能性があるため、明示的に指定するのが良い
  health_check_grace_period_seconds = 60      //ヘルスチェック猶予時間。デフォルトは0秒だがタスク起動に時間がかかる場合ヘルスチェックに引っかかり起動と終了が無限に続く

  network_configuration {
    assign_public_ip = false // プライベートネットワークでの起動のため不要
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "example" // コンテナ定義のname
    container_port   = 80        // コンテナ定義のportMappings.containerPort
  }

  // Fargateの場合、デプロイのたびにタスク定義が更新されるためPlan時に差分が出るのでタスク定義の変更は無視する
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

module "nginx_sg" {
  source      = "./modules/security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}

# ***************************
# CloudWatch Logs
# ***************************
// Fargateではホストサーバーにログインできないため、コンテナログの直接確認ができない
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/example"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
  name              = "/ecs-scheduled-tasks/example"
  retention_in_days = 180
}

# ***************************
# IAM / Policy
# ***************************
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  // 既存のポリシーの継承
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  // 既存ポリシーに追加する
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source     = "./modules/iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

module "ecs_events_role" {
  source     = "./modules/iam_role"
  name       = "ecs-events"
  identifier = "events.amazonaws.com"
  policy     = data.aws_iam_policy.ecs_events_role_policy.policy
}

data "aws_iam_policy" "ecs_events_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

# ***************************
# CloudWatch Event
# ***************************
resource "aws_cloudwatch_event_rule" "example_batch" {
  name                = "example-batch"
  description         = "this is an important batch process"
  schedule_expression = "cron(*/2 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "example_batch" {
  target_id = "example-batch"
  rule      = aws_cloudwatch_event_rule.example_batch.name
  role_arn  = module.ecs_events_role.iam_role_arn
  arn       = aws_ecs_cluster.example.arn

  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    platform_version    = "1.3.0"
    task_definition_arn = aws_ecs_task_definition.example_batch.arn

    network_configuration {
      assign_public_ip = "false"
      subnets          = [aws_subnet.private_0.id]
    }
  }
}
