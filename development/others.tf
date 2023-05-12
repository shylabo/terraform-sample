# ***************************
# 外部ソースからの取得によるハードコード削減
# ***************************
data "aws_region" "current" {}
output "region_name" {
  value = data.aws_region.current.name
}

data "aws_availability_zones" "available" {
  state = "available"
}
output "availaility_zones" {
  value = data.aws_availability_zones.available.names
}

data "aws_elb_service_account" "current" {}
output "alb_service_account_id" {
  value = data.aws_elb_service_account.current.id
}

# ***************************
# ランダム文字列の生成
# ***************************
// db passwordなどで使える
// password = random_string.password.result
provider "random" {}

resource "random_string" "password" {
  length = 32
  special = false // 特殊文字の利用を抑制
}
