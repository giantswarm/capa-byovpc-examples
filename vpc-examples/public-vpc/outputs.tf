output "vpc_id" {
  value = aws_vpc.this.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  value = [for ng in aws_nat_gateway.this : ng.id]
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
