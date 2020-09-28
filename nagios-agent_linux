#!/bin/bash
# https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
yum update -y
rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
systemctl restart ncpa_listener.service
echo done > /tmp/nagios.status
