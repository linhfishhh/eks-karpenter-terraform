variable "environment" {

}

variable "region" {

}


variable "vpc" {
  type = object({
    vpc_cidr           = string
    availability_zones = list(string)
  })

}

variable "eks" {
  type = object({
    name    = string
    version = string
  })
}


variable "dataplane" {
  type = object({
    instance_type = string
  })

}