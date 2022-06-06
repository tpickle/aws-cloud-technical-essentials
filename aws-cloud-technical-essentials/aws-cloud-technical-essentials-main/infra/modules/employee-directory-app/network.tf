resource "aws_vpc" "employee_directory_app_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "employee-directory-app-vpc"
  }
}

resource "aws_internet_gateway" "employee_directory_app_igw" {
  vpc_id = aws_vpc.employee_directory_app_vpc.id

  tags = {
    name = "employee-directory-app-igw"
  }
}

resource "aws_route_table" "employee_directory_app_route_table_public" {
  vpc_id = aws_vpc.employee_directory_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.employee_directory_app_igw.id
  }

  tags = {
    name = "employee-directory-app-route-table-public"
  }
}

resource "aws_route_table" "employee_directory_app_route_table_private" {
  vpc_id = aws_vpc.employee_directory_app_vpc.id

  tags = {
    name = "employee-directory-app-route-table-private"
  }
}

variable "number_of_az" {
  description = "The amount of availability zones to setup in the region. Each az will have a public subnet and a private subnet. The value Should be greater than 0 and smaller than the number of az in the region."
  type        = number
  default     = 2
  validation {
    condition     = var.number_of_az > 0
    error_message = "The number_of_az value must be greater than 0."
  }
}

resource "aws_subnet" "employee_directory_app_public_subnet" {
  count = var.number_of_az

  vpc_id                  = aws_vpc.employee_directory_app_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index * 2}.0/24"
  map_public_ip_on_launch = true

  tags = {
    name = "employee-directory-app-public-subnet-${data.aws_availability_zones.available.zone_ids[count.index]}"
  }
}

resource "aws_route_table_association" "employee_directory_app_public_route_table_association" {
  count = var.number_of_az

  subnet_id      = aws_subnet.employee_directory_app_public_subnet[count.index].id
  route_table_id = aws_route_table.employee_directory_app_route_table_public.id
}


resource "aws_subnet" "employee_directory_app_private_subnet" {
  count = var.number_of_az

  vpc_id            = aws_vpc.employee_directory_app_vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${(count.index * 2) + 1}.0/24"

  tags = {
    name = "employee-directory-app-private-subnet-${data.aws_availability_zones.available.zone_ids[count.index]}"
  }
}

resource "aws_route_table_association" "employee_directory_app_private_route_table_association" {
  count = var.number_of_az

  subnet_id      = aws_subnet.employee_directory_app_private_subnet[count.index].id
  route_table_id = aws_route_table.employee_directory_app_route_table_private.id
}
