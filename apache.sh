#!/bin/bash
echo "*** Installing apache"
dnf install httpd
systemctl enable httpd
systemctl start httpd
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --reload
echo "*** Completed Installing apache2"