resource "aws_kms_key" "example" {
  description             = "Example Customer Master Key"
  enable_key_rotation     = true // 自動ローテーション（年1回）
  is_enabled              = true // カスタマーマスターキーの有効化
  deletion_window_in_days = 30   //カスタマーマスターキーの削除待機期間。削除の取り消しができる期間
  // カスタマーマスターキーの削除は推奨されない。削除したマスターキーで暗号化されたデータは復号できないため無効化にすべき
}

resource "aws_kms_alias" "example" {
  // エイリアスで設定する場合はalias/のプレフィックスが必要
  name          = "alias/example"
  target_key_id = aws_kms_key.example.key_id
}
