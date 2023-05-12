# ステートバケットの作成

```sh
## ステートバケットの作成
aws s3api create-bucket --bucket tfstate-pragmatic-terraform --create-bucket-configuration LocationConstraint=ap-northeast-1

## バージョニング設定
$ aws s3api put-bucket-versioning --bucket tfstate-pragmatic-terraform --versioning-configuration Status=Enabled

## 暗号化
$ aws s3api put-bucket-encryption --bucket tfstate-pragmatic-terraform --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

## ブロックパブリックアクセス
$ aws s3api put-public-access-block --bucket tfstate-pragmatic-terraform --public-access-block-configuration '{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}'
```

# provider の修正

```js
terraform {
  backend "s3" {
    bucket = "tfstate-pragmatic-terraform"
    key = "example/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
```
