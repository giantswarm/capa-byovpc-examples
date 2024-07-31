### VPC

resource "aws_vpc" "public" {
  cidr_block           = var.public_vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      "Name" = var.public_vpc_name
    },
  )
}

### ROUTE TABLES

resource "aws_route_table" "public_vpc_public" {
  vpc_id = aws_vpc.public.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.public_vpc_name}-public"
    },
  )
}

resource "aws_route_table" "public_vpc_private" {
  for_each = toset(data.aws_availability_zones.available.names)
  vpc_id   = aws_vpc.public.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.public_vpc_name}-private-${each.key}"
    },
  )
}

### INTERNET GATEWAY

resource "aws_internet_gateway" "public_vpc" {
  vpc_id = aws_vpc.public.id

  tags = merge(
    var.tags,
    {
      "Name" = var.public_vpc_name
    },
  )
}

resource "aws_route" "public_vpc_igw" {
  route_table_id         = aws_route_table.public_vpc_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_vpc.id
}

### NAT GATEWAY(S)

resource "aws_eip" "public_vpc_nat_gateway" {
  for_each = toset(data.aws_availability_zones.available.names)
  domain   = "vpc"
}

resource "aws_nat_gateway" "public_vpc" {
  for_each      = toset(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.public_vpc_nat_gateway[each.key].id
  subnet_id     = aws_subnet.public_vpc_public[each.key].id

  tags = merge(
    var.tags,
    {
      "Name" = each.key
    },
  )
}

resource "aws_route" "public_vpc_nat_gateway" {
  for_each               = aws_nat_gateway.public_vpc
  route_table_id         = aws_route_table.public_vpc_private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value.id
}

### PUBLIC SUBNETS

resource "aws_subnet" "public_vpc_public" {
  for_each                = toset(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.public.id
  cidr_block              = cidrsubnet(var.public_vpc_cidr_block, var.subnet_cidr_newbits, 10 + index(data.aws_availability_zones.available.names, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name" = "${var.public_vpc_name}-public-${each.key}"
    },
  )
}

resource "aws_route_table_association" "public_vpc_public_subnet_association" {
  for_each       = aws_subnet.public_vpc_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_vpc_public.id
}

### PRIVATE SUBNETS

resource "aws_subnet" "public_vpc_private" {
  for_each                = toset(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.public.id
  cidr_block              = cidrsubnet(var.public_vpc_cidr_block, var.subnet_cidr_newbits, 20 + index(data.aws_availability_zones.available.names, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name" = "${var.public_vpc_name}-private-${each.key}"
    },
  )
}

resource "aws_route_table_association" "public_vpc_private_subnet_association" {
  for_each       = aws_subnet.public_vpc_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_vpc_private[each.key].id
}
