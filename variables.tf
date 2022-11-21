# for base/vpc.tf
variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
  default = "cluster-1"
}

variable "instance_type" {
  type = string
  description = "EC2 instance type"
  default = "t2.micro"
}

variable "iac_environment_tag" {
  type = string
  description = "env tag"
  default = "cluster=poc"
}