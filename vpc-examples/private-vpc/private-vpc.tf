data "aws_availability_zones" "available" {
  state = "available"
}

### VPC

resource "aws_vpc" "private" {
  cidr_block           = var.private_vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      "Name" = var.private_vpc_name
    },
  )
}

### ROUTE TABLES

resource "aws_route_table" "private_vpc_private" {
  for_each = toset(data.aws_availability_zones.available.names)
  vpc_id   = aws_vpc.private.id

  tags = merge(
    var.tags,
    {
      "Name"                                          = "${var.private_vpc_name}-private-${each.key}"
      "kubernetes.io/cluster/${var.k8s_cluster_name}" = "shared"
    },
  )
}

### PRIVATE SUBNETS

resource "aws_subnet" "private_vpc_private" {
  for_each                = toset(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.private.id
  cidr_block              = cidrsubnet(var.private_vpc_cidr_block, var.subnet_cidr_newbits, 20 + index(data.aws_availability_zones.available.names, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name"                                          = "${var.private_vpc_name}-private-${each.key}"
      "kubernetes.io/cluster/${var.k8s_cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"               = "1"
      "sigs.k8s.io/cluster-api-provider-aws/role"     = "private"
      "giantswarm.io/cluster"                         = var.k8s_cluster_name
      "giantswarm.io/installation"                    = var.k8s_management_cluster_name
    },
  )
}

resource "aws_route_table_association" "private_vpc_private_subnet_association" {
  for_each       = aws_subnet.private_vpc_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_vpc_private[each.key].id
}
