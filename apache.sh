#!/bin/bash
echo "*** Installing apache"
sudo yum update -y
sudo yum update httpd -y
sudo systemctl start httpd
sudo systemctl status httpd
echo "*** Completed Installing apache2"