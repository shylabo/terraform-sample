resource "aws_elasticache_parameter_group" "example" {
  name   = "example"
  family = "redis5.0"

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_subnet_group" "example" {
  name       = "example"
  subnet_ids = [aws_subnet.private_0.id, aws_subnet.private_1.id]
}

// RDSやElasticacheはapplyに時間がかかる（一度applyするだけでも10min~30min）
// 特にt2, t3系の低スペックはそれ以上にかかる可能性がある。検証中はサイズをケチらないことも検討
resource "aws_elasticache_replication_group" "example" {
  replication_group_id          = "example"
  replication_group_description = "Cluster Disabled"
  engine                        = "redis" // memcached or redis
  engine_version                = "5.0.4"
  number_cache_clusters         = 3 // ノード数を指定。ノード数はプライマリノードとレプリカノードの合計。3の場合はプライマリ×1 + レプリカ×2
  node_type                     = "cache.m3.micro"
  snapshot_window               = "09:10-10:10"         // UTC
  snapshot_retention_limit      = 7                     // スナップショットの保持期間
  maintenance_window            = "mon:10:40-mon:11:40" // UTC
  automatic_failover_enabled    = true                  // 自動フェールオーバーが有効（マルチAZ化している前提）
  port                          = 6379
  apply_immediately             = false                               // メンテナンスウィンドウでの設定変更にする
  security_group_ids            = [module.redis_sg.security_group_id] // VPCからの通信のみ許可（外部は遮断）
  parameter_group_name          = aws_elasticache_parameter_group.example.name
  subnet_group_name             = aws_elasticache_subnet_group.example.name
}

module "redis_sg" {
  source      = "./modules/security_group"
  name        = "redis-sg"
  vpc_id      = aws_vpc.example.id
  port        = 6379
  cidr_blocks = [aws_vpc.example.cidr_block]
}
