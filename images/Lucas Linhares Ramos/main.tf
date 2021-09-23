# PROVIDER
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# REGIAO
provider "aws" {
  region = "us-east-1"
}

# VPC'S
resource "aws_vpc" "vpc10" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    "Name" = "vpc10"
  }
}

resource "aws_vpc" "vpc20" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    "Name" = "vpc20"
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "igw_vpc10" {
  vpc_id = aws_vpc.vpc10.id

  tags = {
    "Name" = "igw_vpc10"
  }
}

resource "aws_internet_gateway" "igw_vpc20" {
  vpc_id = aws_vpc.vpc20.id

  tags = {
    "Name" = "igw_vpc20"
  }
}

# SUBNET'S
resource "aws_subnet" "sn_vpc10_public" {
  vpc_id                  = aws_vpc.vpc10.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "sn_vpc10_public"
  }
}

resource "aws_subnet" "sn_vpc20_public" {
  vpc_id                  = aws_vpc.vpc20.id
  cidr_block              = "20.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "sn_vpc20_public"
  }
}

resource "aws_subnet" "sn_vpc10_private" {
  vpc_id            = aws_vpc.vpc10.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name" = "sn_vpc10_private"
  }
}

resource "aws_subnet" "sn_vpc20_private" {
  vpc_id            = aws_vpc.vpc20.id
  cidr_block        = "20.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name" = "sn_vpc20_private"
  }
}

# VPC PEERING
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = aws_vpc.vpc10.id
  vpc_id      = aws_vpc.vpc20.id
  auto_accept = true

  tags = {
    "Name" = "vpc_peering"
  }
}

# ELASTIC IP
resource "aws_eip" "elastic_ip_pub_10" {
  vpc = true
}

resource "aws_eip" "elastic_ip_pub_20" {
  vpc = true
}

# NAT GATEWAY
resource "aws_nat_gateway" "ngw_vpc10" {
  allocation_id = aws_eip.elastic_ip_pub_10.id
  subnet_id     = aws_subnet.sn_vpc10_public.id
  depends_on    = [aws_internet_gateway.igw_vpc10]

  tags = {
    "Name" = "ngw_vpc10"
  }
}

resource "aws_nat_gateway" "ngw_vpc20" {
  allocation_id = aws_eip.elastic_ip_pub_20.id
  subnet_id     = aws_subnet.sn_vpc20_public.id
  depends_on    = [aws_internet_gateway.igw_vpc20]

  tags = {
    "Name" = "ngw_vpc20"
  }
}

# ROUTE TABLE
resource "aws_route_table" "rt_vpc10_public" {
  vpc_id = aws_vpc.vpc10.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc10.id
  }

  route {
    cidr_block = "20.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc10_public"
  }
}

resource "aws_route_table" "rt_vpc10_private" {
  vpc_id = aws_vpc.vpc10.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw_vpc10.id
  }

  route {
    cidr_block = "20.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc10_private"
  }
}

resource "aws_route_table" "rt_vpc20_public" {
  vpc_id = aws_vpc.vpc20.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc20.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc20_public"
  }
}

resource "aws_route_table" "rt_vpc20_private" {
  vpc_id = aws_vpc.vpc20.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw_vpc20.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc20_private"
  }
}

# SUBNET ASSOCIATION
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sn_vpc10_public.id
  route_table_id = aws_route_table.rt_vpc10_public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sn_vpc10_private.id
  route_table_id = aws_route_table.rt_vpc10_private.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.sn_vpc20_public.id
  route_table_id = aws_route_table.rt_vpc20_public.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.sn_vpc20_private.id
  route_table_id = aws_route_table.rt_vpc20_private.id
}

# SECURITY GROUP

# SG PÚBLICO VPC10
resource "aws_security_group" "sg_vpc10_public" {
  name        = "SG Pub VPC10"
  description = "SG para a rede publica"
  vpc_id      = aws_vpc.vpc10.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  ingress {
    description = "Liberando a porta 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 3389"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "sg_vpc10_public"
  }
}

# SG PRIVADO VPC10
resource "aws_security_group" "sg_vpc10_private" {
  name        = "SG Private VPC10"
  description = "SG para rede privada"
  vpc_id      = aws_vpc.vpc10.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  tags = {
    "Name" = "sg_vpc10_private"
  }
}

# SG PÚBLICO VPC20
resource "aws_security_group" "sg_vpc20_public" {
  name        = "SG Pub VPC20"
  description = "SG para a rede publica"
  vpc_id      = aws_vpc.vpc20.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  ingress {
    description = "Liberando a porta 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 3389"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "sg_vpc20_public"
  }
}

# SG PRIVADO VPC20
resource "aws_security_group" "sg_vpc20_private" {
  name        = "SG Private VPC20"
  description = "SG para rede privada"
  vpc_id      = aws_vpc.vpc20.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  tags = {
    "Name" = "sg_vpc20_private"
  }
}

# EC2 NAGIOS
resource "aws_instance" "nagios" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc10_public.id
  vpc_security_group_ids = [aws_security_group.sg_vpc10_public.id]
  user_data              = <<-EOF
   #!/bin/bash
        # Nagios Core Install Instructions
        # https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html
        yum update -y
        setenforce 0
        cd /tmp
        yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
        yum install -y perl-Net-SNMP
        yum install -y unzip httpd php gd gd-devel perl postfix
        cd /tmp
        wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.5.tar.gz
        tar xzf nagioscore.tar.gz
        cd /tmp/nagioscore-nagios-4.4.5/
        ./configure
        make all
        make install-groups-users
        usermod -a -G nagios apache
        make install
        make install-daemoninit
        systemctl enable httpd.service
        make install-commandmode
        make install-config
        make install-webconf
        iptables -I INPUT -p tcp --destination-port 80 -j ACCEPT
        ip6tables -I INPUT -p tcp --destination-port 80 -j ACCEPT
        htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin
        service httpd start
        service nagios start
        cd /tmp
        wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
        tar zxf nagios-plugins.tar.gz
        cd /tmp/nagios-plugins-release-2.2.1/
        ./tools/setup
        ./configure
        make
        make install
        service nagios restart
        echo done > /tmp/nagioscore.done
	EOF

  tags = {
    "Name" = "nagios"
  }
}

# EC2 node_a
resource "aws_instance" "node_a" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc10_public.id
  vpc_security_group_ids = [aws_security_group.sg_vpc10_public.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_a"
  }
}

# EC2 node_b
resource "aws_instance" "node_b" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc20_public.id
  vpc_security_group_ids = [aws_security_group.sg_vpc20_public.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_b"
  }
}

# EC2 node_c
resource "aws_instance" "node_c" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc10_private.id
  vpc_security_group_ids = [aws_security_group.sg_vpc10_private.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_c"
  }
}

# EC2 node_d
resource "aws_instance" "node_d" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc20_private.id
  vpc_security_group_ids = [aws_security_group.sg_vpc20_private.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_d"
  }
}