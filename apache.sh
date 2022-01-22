#!/bin/bash
echo "*** Installing apache"
sudo yum update -y
sudo yum update httpd -y
sudo systemctl start httpd -y
sudo systemctl status httpd -y
echo "*** Completed Installing apache2"