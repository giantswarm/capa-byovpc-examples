output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnets" {
  value = [for s in aws_subnet.public : {
    id             = s.id
    route_table_id = aws_route_table.public.id
    nat_gateway_id = aws_nat_gateway.this[s.availability_zone].id
  }]
}

output "private_subnets" {
  value = [for s in aws_subnet.private : {
    id             = s.id
    route_table_id = aws_route_table.private[s.availability_zone].id
  }]
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "connectivity_config" {
  value = yamlencode({
    network = {
      vpcId = aws_vpc.this.id
    }
    subnets = concat([
      for s in aws_subnet.public : {
        id = s.id
      }
    ], [
      for s in aws_subnet.private : {
        id = s.id
      }
    ])
  })
}
