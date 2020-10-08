#!/bin/bash

# WebServer Apache Install Instructions
# http://httpd.apache.org/docs/current/install.html
yum update -y
yum install -y httpd
systemctl enable httpd
service httpd start
cat <<EOF >/var/www/html/index.html
<html>
<body>
<p>hostname:<b> $(hostname) </b></p>
<p>date/time:<b> $(date) </b></p>
</body>
</html>
EOF
echo done > /tmp/webserver-apache.done
