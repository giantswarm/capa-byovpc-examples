module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "2.12.2"

  name        = var.public_vpc_name
  description = "TGW between private and public VPCs"

  enable_auto_accept_shared_attachments  = true
  enable_multicast_support               = false
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false

  vpc_attachments = {
    private_vpc = {
      vpc_id              = aws_vpc.private.id
      subnet_ids          = [for s in aws_subnet.private_vpc_private : s.id]

      dns_support  = true
      ipv6_support = false

      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false

      tags = {
        Name = var.private_vpc_name
      }
    },
    public_vpc = {
      vpc_id              = aws_vpc.public.id
      subnet_ids          = [for s in aws_subnet.public_vpc_private : s.id]

      dns_support  = true
      ipv6_support = false

      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false

      tgw_routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
        }
      ]

      tags = {
        Name = var.public_vpc_name
      }
    },
  }

  share_tgw = false

  tags = var.tags
}

# Route internet traffic from the private VPC to the TGW
resource "aws_route" "private_vpc_tgw" {
  for_each               = aws_route_table.private_vpc_private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}
