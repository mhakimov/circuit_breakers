variable "project" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "enable_eks_tags" {
  type    = bool
  default = false
}
variable "private_subnet_azs" {
  type = list(string)
}
variable "eks_cluster_name" {
  type    = string
  default = ""
}
variable "tags" { type = map(string) }
