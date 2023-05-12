resource "aws_db_parameter_group" "example" {
  name   = "example"
  family = "mysql5.7" //エンジンとバージョンセット

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

resource "aws_db_option_group" "example" {
  name                 = "example"
  engine_name          = "mysql"
  major_engine_version = "5.7"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
}

resource "aws_db_subnet_group" "example" {
  name       = "example"
  subnet_ids = [aws_subnet.private_0.id, aws_subnet.private_1.id]
}

// 検証環境でリソースをdestoryする場合はDBインスタンスを削除する場合
// deletion_protectionをfalseにして、skip_final_snapshotをtrueにしてスナップショットの作成をスキップ
resource "aws_db_instance" "example" {
  identifier                 = "example"
  engine                     = "mysql"
  engine_version             = "5.7.25"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  max_allocated_storage      = 100 //この容量まで自動的にスケールアップ
  storage_type               = "gp2"
  storage_encrypted          = true
  kms_key_id                 = aws_kms_key.example.arn // デフォルトのAWS KMS 暗号鍵を使うとアカウントを跨いだスナップショットの共有ができなくなるため、自作鍵が無難
  username                   = "admin"
  password                   = "uninitialized"       // $ aws rds modify-db-instance --db-instance-identifier 'example'\ --master-user-password 'NewMasterPassword!'
  multi_az                   = true                  // それぞれのAZにサブネットを指定しておくことが前提
  publicly_accessible        = false                 // VPC外からのアクセスを遮断
  backup_window              = "09:10-09:40"         // RDSバックアップは毎日。設定はUTCなので注意
  backup_retention_period    = 30                    // バックアップ期間は最大35日
  maintenance_window         = "mon:10:10-mon:10:40" // メンテナンスのタイミングもUTC。メンテ自体を無効化はできない
  auto_minor_version_upgrade = false                 // 自動マイナーバージョンアップを無効化
  deletion_protection        = true
  skip_final_snapshot        = false // インスタンス削除時のスナップショット作成のためfalseに
  port                       = 3306
  apply_immediately          = false // RDSの設定変更タイミングは「即時」と「メンテナンスウィンドウ」の二つがある。RDSでは一部の設定変更に再起動が伴い予期せぬダウンタイムが起こりうるので、即時反映は避けたい
  vpc_security_group_ids     = [module.mysql_sg.security_group_id]
  parameter_group_name       = aws_db_parameter_group.example.name
  option_group_name          = aws_db_option_group.example.name
  db_subnet_group_name       = aws_db_subnet_group.example.name

  lifecycle {
    ignore_changes = [password]
  }
}

module "mysql_sg" {
  source      = "./modules/security_group"
  name        = "mysql-sg"
  vpc_id      = aws_vpc.example.id
  port        = 3306
  cidr_blocks = [aws_vpc.example.cidr_block]
}
