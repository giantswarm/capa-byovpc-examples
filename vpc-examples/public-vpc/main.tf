data "aws_availability_zones" "available" {
  state = "available"
}

### VPC

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

### ROUTE TABLES

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      "Name"                                          = "${var.name}-public"
      "kubernetes.io/cluster/${var.k8s_cluster_name}" = "shared"
    },
  )
}

resource "aws_route_table" "private" {
  for_each = toset(data.aws_availability_zones.available.names)
  vpc_id   = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      "Name"                                          = "${var.name}-private-${each.key}"
      "kubernetes.io/cluster/${var.k8s_cluster_name}" = "shared"
    },
  )
}

### INTERNET GATEWAY

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

### NAT GATEWAY(S)

resource "aws_eip" "nat_gateway" {
  for_each = toset(data.aws_availability_zones.available.names)
  domain   = "vpc"
}

resource "aws_nat_gateway" "this" {
  for_each      = toset(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.nat_gateway[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    var.tags,
    {
      "Name" = each.key
    },
  )
}

resource "aws_route" "nat_gateway" {
  for_each               = aws_nat_gateway.this
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value.id
}

### PUBLIC SUBNETS

resource "aws_subnet" "public" {
  for_each                = toset(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr_block, var.subnet_cidr_newbits, 10 + index(data.aws_availability_zones.available.names, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name"                                          = "${var.name}-public-${each.key}"
      "kubernetes.io/cluster/${var.k8s_cluster_name}" = "shared"
      "kubernetes.io/role/elb"                        = "1"
    },
  )
}

resource "aws_route_table_association" "public_subnet_association" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

### PRIVATE SUBNETS

resource "aws_subnet" "private" {
  for_each                = toset(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr_block, var.subnet_cidr_newbits, 20 + index(data.aws_availability_zones.available.names, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name"                                          = "${var.name}-private-${each.key}"
      "kubernetes.io/cluster/${var.k8s_cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"               = "1"
      "sigs.k8s.io/cluster-api-provider-aws/role"     = "private"
    },
  )
}

resource "aws_route_table_association" "private_subnet_association" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
