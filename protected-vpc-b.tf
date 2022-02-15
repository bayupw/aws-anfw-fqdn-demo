resource "aws_vpc" "protected_vpc_b" {
  cidr_block           = local.protected_vpc_b_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "protected-vpc-b"
  }
}

resource "aws_internet_gateway" "protected_vpc_b_igw" {
  vpc_id = aws_vpc.protected_vpc_b.id
  tags = {
    Name = "protected-vpc-b/internet-gateway"
  }
}

# Private (Protected) Subnet 
resource "aws_subnet" "protected_vpc_b_private_subnet" {
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.protected_vpc_b.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = cidrsubnet(var.supernet, 16, 512)

  tags = {
    Name = "protected-vpc-b/${data.aws_availability_zones.available.names[0]}/private-subnet"
  }
}

# SSM Endpoint Subnet
resource "aws_subnet" "protected_vpc_b_endpoint_subnet" {
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.protected_vpc_b.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = cidrsubnet(var.supernet, 16, 513)

  tags = {
    Name = "protected-vpc-b/${data.aws_availability_zones.available.names[0]}/endpoint-subnet"
  }
}

# Public Subnet
resource "aws_subnet" "protected_vpc_b_public_subnet" {
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.protected_vpc_b.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = cidrsubnet(var.supernet, 16, 514)

  tags = {
    Name = "protected-vpc-b/${data.aws_availability_zones.available.names[0]}/public-subnet"
  }
}

resource "aws_eip" "protected_vpc_b_natgw" {
  vpc = true
}

resource "aws_nat_gateway" "protected_vpc_b_natgw" {
  allocation_id = aws_eip.protected_vpc_b_natgw.id
  subnet_id     = aws_subnet.protected_vpc_b_public_subnet.id

  tags = {
    Name = "protected-vpc-b/nat-gateway"
  }

  depends_on = [aws_internet_gateway.protected_vpc_b_igw]
}

resource "aws_subnet" "protected_vpc_b_firewall_subnet" {
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.protected_vpc_b.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = cidrsubnet(var.supernet, 16, 515)

  tags = {
    Name = "protected-vpc-b/${data.aws_availability_zones.available.names[0]}/firewall-subnet"
  }
}

resource "aws_networkfirewall_firewall" "protected_vpc_b_anfw" {
  name                = "protected-vpc-b-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
  vpc_id              = aws_vpc.protected_vpc_b.id

  subnet_mapping {
    subnet_id = aws_subnet.protected_vpc_b_firewall_subnet.id
  }

  tags = {
    Name = "protected-vpc-b/anfw"
  }
}

# Private Route Tables
resource "aws_route_table" "protected_vpc_b_private_subnet_route_table" {
  vpc_id = aws_vpc.protected_vpc_b.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.protected_vpc_b_natgw.id
  }
  tags = {
    Name = "protected-vpc-b/private-subnet-route-table"
  }

  depends_on = [aws_nat_gateway.protected_vpc_b_natgw]
}

resource "aws_route_table_association" "protected_vpc_b_protected_subnet_route_table_assoc" {
  subnet_id      = aws_subnet.protected_vpc_b_private_subnet.id
  route_table_id = aws_route_table.protected_vpc_b_private_subnet_route_table.id
}

# Public Route Tables
resource "aws_route_table" "protected_vpc_b_public_subnet_route_table" {
  vpc_id = aws_vpc.protected_vpc_b.id
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.protected_vpc_b_anfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.protected_vpc_b_firewall_subnet.id], 0)
  }
  tags = {
    Name = "protected-vpc-b/public-subnet-route-table"
  }

  depends_on = [aws_networkfirewall_firewall.protected_vpc_b_anfw]
}

resource "aws_route_table_association" "protected_vpc_b_public_subnet_route_table_assoc" {
  subnet_id      = aws_subnet.protected_vpc_b_public_subnet.id
  route_table_id = aws_route_table.protected_vpc_b_public_subnet_route_table.id
}

# Firewall Route Tables
resource "aws_route_table" "protected_vpc_b_firewall_subnet_route_table" {
  vpc_id = aws_vpc.protected_vpc_b.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.protected_vpc_b_igw.id
  }
  tags = {
    Name = "protected-vpc-b/firewall-subnet-route-table"
  }

  depends_on = [aws_internet_gateway.protected_vpc_b_igw]
}

resource "aws_route_table_association" "protected_vpc_b_firewall_subnet_route_table_assoc" {
  subnet_id      = aws_subnet.protected_vpc_b_firewall_subnet.id
  route_table_id = aws_route_table.protected_vpc_b_firewall_subnet_route_table.id
}


# Ingress Route Tables
resource "aws_route_table" "protected_vpc_b_ingress_route_table" {
  vpc_id = aws_vpc.protected_vpc_b.id
  route {
    cidr_block      = aws_subnet.protected_vpc_b_public_subnet.cidr_block
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.protected_vpc_b_anfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.protected_vpc_b_firewall_subnet.id], 0)
  }
  tags = {
    Name = "protected-vpc-b/ingress-route-table"
  }

  depends_on = [aws_internet_gateway.protected_vpc_b_igw]
}

resource "aws_route_table_association" "protected_vpc_b_ingress_route_table_assoc" {
  gateway_id     = aws_internet_gateway.protected_vpc_b_igw.id
  route_table_id = aws_route_table.protected_vpc_b_ingress_route_table.id
}