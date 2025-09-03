variable "dataplane" {
    type = object({
      cluster_name =  string
      iam_instance_profile = string
      private_subnet_ids = list(string)
      sg_ids = list(string)
      instance_type= string
      private_subnet_zones = list(string)
      vpc_cidr = string
    })
}

variable "environment" {
  
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "eks_cluster_ca" {
  description = "EKS cluster certificate authority"
  type        = string
}
