# CAPA Bring-Your-Own-VPC Examples

This repository contains examples and information on how to Bring Your Own VPC with the Giant Swarm platform.

The [`example-vpc`](./example-vpc/) directory contains Terraform configuration to deploy a simple VPC, with subnets, NAT gateways, Internet Gateway and working routing, that should serve as an example on how to setup an external VPC and then adopt it when creating a CAPA cluster.

The [`example-cluster.yaml`](./example-cluster.yaml) file contains Kubernetes manifests to deploy a Giant Swarm workload cluster that adopts an existing VPC and subnets. The Security Groups required by the WC will be created and managed by CAPA.

## VPC requirements

The requirements to adopt an existing VPC into a CAPA cluster are:

- Existing VPC
- Existing Subnets
  - All subnets to be used by the cluster need to be tagged:
    - `kubernetes.io/cluster/<cluster_name>: shared`
  - All public subnets (if any) need to be tagged:
    - `kubernetes.io/role/elb: "1"`
  - All private subnets need to be tagged:
    - `kubernetes.io/role/internal-elb: "1"`
    - `sigs.k8s.io/cluster-api-provider-aws/role: private`
- Existing route tables
  - All route tables to be used by the cluster need to be tagged:
    - `kubernetes.io/cluster/<cluster_name>: shared`
- Working routing between the subnets and to the internet / proxy

To create a cluster adopting existing VPC and subnets, you need to set their IDs under `global.connectivity` in the Cluster App values, as shown in the [provided example manifests](./example-cluster.yaml).
