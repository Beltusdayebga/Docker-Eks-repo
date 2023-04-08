provider "aws" {
  region = var.region
 
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.14.0"

  name = local.vpc_name
  cidr = local.vpc_cidr
  azs  = local.azs

  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  single_nat_gateway   = true
  create_igw           = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.vpc_name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.vpc_name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.vpc_name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    "public"                                    = "true"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "private"                                   = "true"
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

data "aws_subnet_ids" "public_subnets_az_1" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.cluster_name}-vpc-public-us-*-*a"
  }
  depends_on = [
    module.vpc
  ]
}

data "aws_subnet_ids" "public_subnets_az_2" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.cluster_name}-vpc-public-us-*-*b"
  }
  depends_on = [
    module.vpc
  ]
}

data "aws_subnet_ids" "public_subnets_az_3" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.cluster_name}-vpc-public-us-*-*c"
  }
  depends_on = [
    module.vpc
  ]
}

data "aws_availability_zones" "available" {}

output "public_ip" {
  value = aws_instance.docker.public_ip
}

resource "aws_security_group" "public_security_group" {
  name_prefix = "public-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow all HTTP and HTTPS traffic from any source"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outgoing traffic to any destination"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

locals {
#   subnet_id = element(data.aws_subnet_ids.public_subnets_az_3.ids, 0)
  subnet_id = element(tolist(data.aws_subnet_ids.public_subnets_az_3.ids), 0)

  vpc_name = join("-", [var.cluster_name, "vpc"])
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 4)
}


resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "docker" {
  ami           = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id     = local.subnet_id
  vpc_security_group_ids = aws_security_group.public_security_group.*.id

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -aG docker ec2-user

    # Create my-node-app directory in the home directory of ec2-user
    sudo mkdir /home/ec2-user/my-node-app
    sudo chown ec2-user:ec2-user /home/ec2-user/my-node-app

    # Create Dockerfile
    cat <<EOT >> /home/ec2-user/my-node-app/Dockerfile
    FROM node:14-alpine

    WORKDIR /app

    COPY *.json .

    RUN npm install --production

    COPY index.js .

    EXPOSE 3000

    ENTRYPOINT [ "npm", "start" ]

    CMD []
    EOT

    # Create package.json
    cat <<EOT >> /home/ec2-user/my-node-app/package.json
    {
      "name": "my-node-app",
      "version": "1.0.0",
      "description": "A simple Node.js app",
      "main": "index.js",
      "dependencies": {
        "express": "^4.17.1"
      },
      "scripts": {
        "start": "node index.js"
      },
      "author": "Your Name",
      "license": "MIT"
    }
    EOT
    # Create index.js
    cat <<EOT >> /home/ec2-user/my-node-app/index.js
    const express = require('express');
    const app = express();

    app.get('/', (req, res) => {
    res.send(`Welcome to my Dockerized Node.js app!

    This is a sample application that demonstrates how to containerize a Node.js application using Docker. With this application, you can learn how to:

    - Create a new Node.js project using npm
    - Write a Dockerfile to build a Docker image for your Node.js application
    - Build a Docker image using the Docker CLI
    - Run a Docker container from the Docker image
    - Expose a port from the Docker container to the host machine
    - Customize the startup behavior of the Docker container using environment variables

    If you're new to Docker and containerization, this application is a great starting point to learn the basics. You can follow along with the step-by-step instructions to build and run the Docker container, and experiment with different configurations to see how it affects the behavior of the container.

    Thank you for using my Dockerized Node.js app!`);
    });

    const port = process.env.PORT || 3000;

    app.listen(port, () => {
    console.log(`Server listening on port 3000.`);
    });


    EOT

    sudo chown ec2-user:ec2-user /home/ec2-user/my-node-app/*

  EOF


  

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

