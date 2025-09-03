variable "environment" {
  
}

variable "eks" {
    type = object({
      name = string
      version = string
      public_subnet_ids = list(string)
      private_subnet_ids = list(string)
      control_plane_role_arn = string
      node_group_role_arn = string
    })
  
}

