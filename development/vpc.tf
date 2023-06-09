# ***************************
# VPC
# ***************************
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true // AWSのDNSサーバによる名前解決を有効にする
  enable_dns_hostnames = true // リソースにパブリックDNSホスト名を自動的に割り当て

  tags = {
    Name = "example" // 用途をわかりやすくするためNameタグをつけた方が良い
  }
}

# ***************************
# Public subnet
# ***************************
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true // このサブネットに立てたインスタンスへのパブリックIP自動割り当て
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

# ***************************
# Internet gateway
# ***************************
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# ※ルートテーブルではVPC内の通信を有効にするためローカルルート(10.0.0.0/16)が自動的に作成されるがこれはTerraformから制御は不可
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

// VPC以外への通信をIGW経由でインターネットに流すためにデフォルトルートを指定
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

// ルートテーブルとサブネットの関連付け
// 関連付けをしない場合は、デフォルトルートテーブルが自動的に使われるがこれはアンチパターンなので注意
resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# ***************************
# Private subnet
# ***************************
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id //gateway_idにしないよう注意
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

// ルートテーブルとサブネットの関連付け
// 関連付けをしない場合は、デフォルトルートテーブルが自動的に使われるがこれはアンチパターンなので注意
resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# ***************************
# NAT Gateway
# ***************************
resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.example] // igw作成後にEIPの作成を保証
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example] // igw作成後にNATの作成を保証
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]
}
