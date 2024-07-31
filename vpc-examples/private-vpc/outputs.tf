### Private VPC

output "private_vpc_id" {
  value = aws_vpc.private.id
}

output "connectivity_config" {
  value = yamlencode({
    network = {
      vpcId = aws_vpc.private.id
    }
    subnets = [
      for s in aws_subnet.private_vpc_private : {
        id = s.id
      }
    ]
  })
}

### Public VPC

output "public_vpc_id" {
  value = aws_vpc.public.id
}

output "public_vpc_private_subnets" {
  value = [for s in aws_subnet.public_vpc_private : {
    id             = s.id
    route_table_id = aws_route_table.public_vpc_private[s.availability_zone].id
  }]
}

output "public_vpc_public_subnets" {
  value = [for s in aws_subnet.public_vpc_public : {
    id             = s.id
    route_table_id = aws_route_table.public_vpc_public.id
  }]
}
