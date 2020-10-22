provider "aws" {
  version = "~> 2.0"
  profile = "default"
  region     = var.region
}
# create the VPC
resource "aws_vpc" "My_VPC" {
  cidr_block           = var.vpcCIDRblock
  instance_tenancy     = var.instanceTenancy 
  enable_dns_support   = var.dnsSupport 
  enable_dns_hostnames = var.dnsHostNames
tags = {
    Name = "Grafana&Prometheus VPC"
}
} # end resource
# create the Subnet

resource "aws_subnet" "Grafana" {
  vpc_id                  = aws_vpc.My_VPC.id
  cidr_block              = var.subnetCIDRblock
  map_public_ip_on_launch = var.mapPublicIP 
  availability_zone       = var.availabilityZone
  tags = {
   Name = "Grafana"
  }
}

# create the Subnet
resource "aws_subnet" "Prometheus" {
  vpc_id                  = aws_vpc.My_VPC.id
  cidr_block              = var.subnetCIDRblock1
  availability_zone       = var.availabilityZone1
  tags = {
   Name = "Prometheus"
  }
} # end resource

# Create the Security Group
resource "aws_security_group" "Grafana" {
  vpc_id       = aws_vpc.My_VPC.id
  name         = "GrafanaSG"
  description  = "GrafanaNodeSG"
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 

  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
  } 
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
   Name = "Grafana Security Group"
   Description = "My VPC Security Group"
  }
} # end resource

# Create the Security Group2
resource "aws_security_group" "Prometheus" {
  vpc_id       = aws_vpc.My_VPC.id
  name         = "Prometheus Security Group"
  description  = "Prom Security Group"
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 

  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
  } 
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
   Name = "Prom Security Group"
   Description = "Prom Security Group"
  }
} # end resource

# Create the Internet Gateway
resource "aws_internet_gateway" "My_VPC_GW" {
  vpc_id = aws_vpc.My_VPC.id
  tags = {
        Name = "My VPC Internet Gateway"
  }
} # end resource

# Create the Route Table
resource "aws_route_table" "My_VPC_route_table" {
  vpc_id = aws_vpc.My_VPC.id
  tags = {
        Name = "My VPC Route Table"
  }
} # end resource

# Create the Internet Access
resource "aws_route" "My_VPC_internet_access" {
  route_table_id         = aws_route_table.My_VPC_route_table.id
  destination_cidr_block = var.destinationCIDRblock
  gateway_id             = aws_internet_gateway.My_VPC_GW.id
} # end resource

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "My_VPC_association" {
  subnet_id      = aws_subnet.Grafana.id
  route_table_id = aws_route_table.My_VPC_route_table.id
} # end resource

data "aws_ami" "Graf_Linux" {
  most_recent = true
  owners = ["697430341089"] # Canonical

  filter {
      name   = "name"
      values = ["Grafana Node"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

data "aws_ami" "Prom_Linux" {
  most_recent = true
  owners = ["697430341089"] # Canonical

  filter {
      name   = "name"
      values = ["Prometheus Node"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

# Create EC2 instance
resource "aws_instance" "Grafana" {
  ami                    = "${data.aws_ami.Graf_Linux.id}"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.Grafana.id
  key_name               = "crossovertest"
  vpc_security_group_ids = [aws_security_group.Grafana.id]
  user_data              = file("script.sh")
  tags = {
    Name        = "Grafana Node"
    name        = "Grafana Node"
    provisioner = "Terraform"
  }
}

# Create EC2 instance2
resource "aws_instance" "Prometheus" {
  ami                    = "${data.aws_ami.Prom_Linux.id}"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.Prometheus.id
  key_name               = "crossovertest"
  vpc_security_group_ids = [aws_security_group.Prometheus.id]
  user_data              = file("scripted.sh")
  tags = {
    Name        = "Prometheus Node"
    name        = "Prometheus Node"
    provisioner = "Terraform"
  }
}

output "ip" {
  value       = aws_instance.Grafana.public_dns
  description = "The URL of the server instance."
}