# VPC
resource "aws_vpc" "vpc10" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = "true"

    tags = {
        Name = "vpc10"
    }
}

resource "aws_vpc" "vpc20" {
    cidr_block           = "20.0.0.0/16"
    enable_dns_hostnames = "true"

    tags = {
        Name = "vpc20"
    }
}

# # VPC Peering
resource "aws_vpc_peering_connection" "vpc_peering" {
    peer_vpc_id   = aws_vpc.vpc20.id
    vpc_id        = aws_vpc.vpc10.id
    auto_accept   = true
    
    tags = {
        Name = "vpc_peering"
    }

}

# INTERNET GATEWAY
resource "aws_internet_gateway" "igw_vpc10" {
    vpc_id = aws_vpc.vpc10.id

    tags = {
        Name = "igw_vpc10"
    }
}

resource "aws_internet_gateway" "igw_vpc20" {
    vpc_id = aws_vpc.vpc20.id

    tags = {
        Name = "igw_vpc20"
    }
}

# SUBNET
resource "aws_subnet" "sn_vpc10_public" {
    vpc_id                  = aws_vpc.vpc10.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1a"

    tags = {
        Name = "sn_vpc10_public"
    }
}

resource "aws_subnet" "sn_vpc10_private" {
    vpc_id            = aws_vpc.vpc10.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1c"

    tags = {
        Name = "sn_vpc10_private"
    }
}

resource "aws_subnet" "sn_vpc20_public" {
    vpc_id                  = aws_vpc.vpc20.id
    cidr_block              = "20.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1a"

    tags = {
        Name = "sn_vpc20_public"
    }
}

resource "aws_subnet" "sn_vpc20_private" {
    vpc_id            = aws_vpc.vpc20.id
    cidr_block        = "20.0.2.0/24"
    availability_zone = "us-east-1c"

    tags = {
        Name = "sn_vpc20_private"
    }
}

# # Elastic IP
resource "aws_eip" "eip_ngw_vpc10" {
    depends_on = [aws_internet_gateway.igw_vpc10]
}

resource "aws_eip" "eip_ngw_vpc20" {
    depends_on = [aws_internet_gateway.igw_vpc20]
}

# # NAT Gateway
resource "aws_nat_gateway" "ngw_vpc10" {
    allocation_id = aws_eip.eip_ngw_vpc10.id
    subnet_id     = aws_subnet.sn_vpc10_public.id

    tags = {
        Name = "ngw_vpc10"
    }

    depends_on = [aws_internet_gateway.igw_vpc10]
}

resource "aws_nat_gateway" "ngw_vpc20" {
    allocation_id = aws_eip.eip_ngw_vpc20.id
    subnet_id     = aws_subnet.sn_vpc20_public.id

    tags = {
        Name = "ngw_vpc20"
    }

    depends_on = [aws_internet_gateway.igw_vpc20]
}

# ROUTE TABLE
resource "aws_route_table" "rt_vpc10_public" {
    vpc_id = aws_vpc.vpc10.id

    route {
        cidr_block = "20.0.0.0/16"
        gateway_id = aws_vpc_peering_connection.vpc_peering.id
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_vpc10.id
    }

    tags = {
        Name = "rt_vpc10_public"
    }
}

resource "aws_route_table" "rt_vpc10_private" {
    vpc_id = aws_vpc.vpc10.id

    route {
        cidr_block = "20.0.0.0/16"
        gateway_id = aws_vpc_peering_connection.vpc_peering.id
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.ngw_vpc10.id
    }

    tags = {
        Name = "rt_vpc10_private"
    }
}

resource "aws_route_table" "rt_vpc20_public" {
    vpc_id = aws_vpc.vpc20.id

    route {
        cidr_block = "10.0.0.0/16"
        gateway_id = aws_vpc_peering_connection.vpc_peering.id
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_vpc20.id
    }

    tags = {
        Name = "rt_vpc20_public"
    }
}

resource "aws_route_table" "rt_vpc20_private" {
    vpc_id = aws_vpc.vpc20.id

    route {
        cidr_block = "10.0.0.0/16"
        gateway_id = aws_vpc_peering_connection.vpc_peering.id
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.ngw_vpc20.id
    }

    tags = {
        Name = "rt_vpc20_private"
    }
}

# SUBNET ASSOCIATION
resource "aws_route_table_association" "rt_vpc10_public_To_sn_vpc10_public" {
  subnet_id      = aws_subnet.sn_vpc10_public.id
  route_table_id = aws_route_table.rt_vpc10_public.id
}

resource "aws_route_table_association" "rt_vpc10_private_To_sn_vpc10_private" {
  subnet_id      = aws_subnet.sn_vpc10_private.id
  route_table_id = aws_route_table.rt_vpc10_private.id
}

resource "aws_route_table_association" "rt_vpc20_public_To_sn_vpc20_public" {
  subnet_id      = aws_subnet.sn_vpc20_public.id
  route_table_id = aws_route_table.rt_vpc20_public.id
}

resource "aws_route_table_association" "rt_vpc20_private_To_sn_vpc20_private" {
  subnet_id      = aws_subnet.sn_vpc20_private.id
  route_table_id = aws_route_table.rt_vpc20_private.id
}

# SECURITY GROUP
resource "aws_security_group" "sg_vpc10_public" {
    name        = "sg_vpc10_public"
    description = "sg_vpc10_public"
    vpc_id      = aws_vpc.vpc10.id
    
    egress {
        description = "All to All"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "All from 10.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        description = "All from 20.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["20.0.0.0/16"]
    }

    ingress {
        description = "TCP/22 from All"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "TCP/80 from All"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "TCP/3389 from All"
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "sg_vpc10_public"
    }
}

resource "aws_security_group" "sg_vpc10_private" {
    name        = "sg_vpc10_private"
    description = "sg_vpc10_private"
    vpc_id      = aws_vpc.vpc10.id
    
    egress {
        description = "All to All"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "All from 10.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        description = "All from 20.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["20.0.0.0/16"]
    }

    tags = {
        Name = "sg_vpc10_private"
    }
}

resource "aws_security_group" "sg_vpc20_public" {
    name        = "sg_vpc20_public"
    description = "sg_vpc20_public"
    vpc_id      = aws_vpc.vpc20.id
    
    egress {
        description = "All to All"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "All from 20.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["20.0.0.0/16"]
    }

    ingress {
        description = "All from 10.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        description = "TCP/22 from All"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "TCP/80 from All"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "TCP/3389 from All"
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "sg_vpc20_public"
    }
}

resource "aws_security_group" "sg_vpc20_private" {
    name        = "sg_vpc20_private"
    description = "sg_vpc20_private"
    vpc_id      = aws_vpc.vpc20.id
    
    egress {
        description = "All to All"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "All from 20.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["20.0.0.0/16"]
    }

    ingress {
        description = "All from 10.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }

    tags = {
        Name = "sg_vpc20_private"
    }
}

# EC2 INSTANCE
resource "aws_instance" "nagios" {
    ami                    = "ami-005f9685cb30f234b"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.sn_vpc10_public.id
    vpc_security_group_ids = [aws_security_group.sg_vpc10_public.id]
	user_data = <<-EOF
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
        Name = "nagios"
    }
}

resource "aws_instance" "node_a" {
    ami                    = "ami-005f9685cb30f234b"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.sn_vpc10_public.id
    vpc_security_group_ids = [aws_security_group.sg_vpc10_public.id]
	user_data = <<-EOF
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
        Name = "node_a"
    }
}

resource "aws_instance" "node_b" {
    ami                    = "ami-005f9685cb30f234b"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.sn_vpc20_public.id
    vpc_security_group_ids = [aws_security_group.sg_vpc20_public.id]
	user_data = <<-EOF
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
        Name = "node_b"
    }
}

resource "aws_instance" "node_c" {
    ami                    = "ami-005f9685cb30f234b"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.sn_vpc10_private.id
    vpc_security_group_ids = [aws_security_group.sg_vpc10_private.id]
	user_data = <<-EOF
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
        Name = "node_c"
    }
}

resource "aws_instance" "node_d" {
    ami                    = "ami-005f9685cb30f234b"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.sn_vpc20_private.id
    vpc_security_group_ids = [aws_security_group.sg_vpc20_private.id]
	user_data = <<-EOF
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
        key_name = "nagios"
	EOF
 
    tags = {
        Name = "node_d"
    }
}