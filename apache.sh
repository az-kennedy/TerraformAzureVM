#!/bin/bash
echo "*** Installing apache"
sudo dnf install httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --reload

echo "*** Completed Installing apache2"