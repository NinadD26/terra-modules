
######################Creating VPC#######################
resource "aws_vpc" "staging" {

    cidr_block          = var.cidr
    enable_dns_hostnames                 = true
    enable_dns_support                   = true

    tags = merge(
    { "Name" = var.name },
    )
}

#######################Avability zones in region#################

data "aws_availability_zones" "available" {}

################################### create public subnet

resource "aws_subnet" "public" {
     count                   = length(data.aws_availability_zones.available.names)
     vpc_id                  = aws_vpc.staging.id
     availability_zone       = data.aws_availability_zones.available.names[count.index]
     cidr_block              = cidrsubnet(var.cidr, 8, count.index)
     enable_resource_name_dns_a_record_on_launch    = true
     #map_public_ip_on_launch = true
    tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

##############################create IGW
resource "aws_internet_gateway" "igw" {
  

  vpc_id = aws_vpc.staging.id

  tags = merge(
    { "Name" = "terra-IGW" }
    )
}


################################### Create Public RT

resource "aws_default_route_table" "staging" {
  default_route_table_id = aws_vpc.staging.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

#########################creating private subnet

resource "aws_subnet" "private" {
  count                   = length(data.aws_availability_zones.available.names)
  availability_zone                              = data.aws_availability_zones.available.names[count.index]
  cidr_block                                     =  cidrsubnet(var.cidr, 8, count.index + length(data.aws_availability_zones.available.names))   #10.1.0.0/8",10.2.0.0/8",10.3.0.0/8"
  vpc_id                                         = aws_vpc.staging.id
  enable_resource_name_dns_a_record_on_launch    = true

  tags = merge(
    {
      Name = "private-subnet-${(count.index+1)}"
    }
  )
 }

#################### create private route table

resource "aws_route_table" "private" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id = aws_vpc.staging.id

  tags = merge(
    {
    Name = "Pvt-RT"
    }
  )
}

############## creating private route table association 

resource "aws_route_table_association" "private" {
  count = length(data.aws_availability_zones.available.names)

  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id, count.index,
  )
}

########################## creating nat ip

resource "aws_eip" "nat-ip" {
  count = 1

  domain = "vpc"

  tags = merge(
    {
      "Name" ="NAT-IP",
       
    }
    )

  depends_on = [aws_internet_gateway.igw]
}

#################################creating NAT gateway 

resource "aws_nat_gateway" "nat-gateway" {
  count = 1

  allocation_id = aws_eip.nat-ip[0].id
  subnet_id = element(
    aws_subnet.public[*].id,count.index,
  )

depends_on = [aws_internet_gateway.igw]
}

##################################### route  table 


resource "aws_route" "private_nat_gateway_RT" {
  count = length(data.aws_availability_zones.available.names)

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat-gateway[*].id, count.index)

}