#!/bin/bash
echo "*** Installing apache"
sudo yum update -y
sudo yum install httpd22 -y
sudo systemctl enable httpd22.service
sudo systemctl start httpd22.service
echo "*** Completed Installing apache2"