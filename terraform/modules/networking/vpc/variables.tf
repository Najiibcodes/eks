variable "cluster_name" {
  type        = string
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidr_a" {
  type    = string
  default = "10.0.101.0/24"
}

variable "public_subnet_cidr_b" {
  type    = string
  default = "10.0.102.0/24"
}

variable "private_subnet_cidr_a" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr_b" {
  type    = string
  default = "10.0.2.0/24"
}
