
variable "ami_id" {
  default = "ami-0b69ea66ff7391e80"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_password" {
  default = "password&1234"
}

variable "environment" {
  default = "dev"
}
variable "key_name" {
  default = "bluewave"
}

# variable "subnet_id" {
#   default = "subnet-0b0e1c9f1f1f1f1f1"
# }

# variable "vpc_id" {
#   default = "vpc-0b0e1c9f1f1f1f1f1"
# }

variable "region" {
  default = "us-east-1"
}

# variable "availability_zone" {
#   default = "us-east-1a"
# }

# variable "security_group_id" {
#   default = "sg-0b0e1c9f1f1f1f1f1"
# }

variable "cluster_name" {
  default = "bluewave-docker"
}
  
variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
  
}