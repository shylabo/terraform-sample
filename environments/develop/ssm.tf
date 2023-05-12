resource "aws_ssm_parameter" "db_username" {
  name        = "/db/username"
  value       = "root"
  type        = "String"
  description = "db user name"
}

// パスワードなどはソースコードに平文で書くべきでないし、バージョン管理されるものでもない。
// 一度以下で初期化し、AWS CLIで更新する
// $ aws ssm put-parameter --name '/db/password' --type SecureString \
//   --value 'ModifiedStrongPassword!' --overwrite
resource "aws_ssm_parameter" "db_raw_password" {
  name        = "/db/raw_password"
  value       = "uninitialized"
  type        = "SecureString"
  description = "db password"

  lifecycle {
    ignore_changes = [value]
  }
}
