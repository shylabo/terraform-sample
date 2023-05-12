module "web_server" {
  source        = "./modules/http_server"
  instance_type = "t2.nano"
}

output "public_dns" {
  value = module.web_server.public_dns
}

module "describe_regions_for_ec2" {
  source     = "./modules/iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}


# ***************************
# iam policy document
# ***************************
data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }
}
