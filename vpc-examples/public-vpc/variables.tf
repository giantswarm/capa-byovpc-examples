variable "name" {
  type        = string
  description = "The name of the setup"
}

variable "k8s_cluster_name" {
  type        = string
  description = "The name of the Kubernetes cluster"
}

variable "cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "subnet_cidr_newbits" {
  type        = number
  description = "The number of bits to add to the CIDR block for the subnets"
  default     = 8
}
