# DNS と SSL 証明書

- Route 53
- ACM

# VPC

## パブリックサブネット

- ALB
- NAT ゲートウェイ

## プライベートサブネット

- ECS
- RDS
- EC2
- ElastiCache

## デプロイメントパイプライン

- ECR
- CodeBuild
- CodePipeline

# ロギング

- s3
- Kinesis Data Firehose
- CloudWatch Logs
- Athena

# 鍵管理と設定管理

- KMS
- SSM パラメータストア

--

# Terraform で管理できない

- Route53

# Command

```sh
# 未フォーマットのコードがあるとExitCodeが0以外になるのでCIチェックに便利
$ terraform fmt -recursive -check

# 変数に値がセットされてない場合やSyntaxエラーを通知
$ terraform validate
# サブディレクトリも含めてバリデーションチェック
$ find . -type f -name '*.tf' -exec dirname {} \; | sort -u | xargs -I {} terraform validate {}

# オートコンプリート設定
$ terraform -install-autocomplete

## tflintによる不正コード検出
$ brew install tflint
$ tflint # 不正コード検出
# $ tflint --deep --aws-region=ap-northeast-1
```
