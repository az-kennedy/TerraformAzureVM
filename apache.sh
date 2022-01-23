#!/bin/bash
echo "*** Installing apache"
sudo subscription-manager repos --disable codeready-builder-for-rhel-8-x86_64-eus-debug-rpms
sudo dnf clean all
sudo rm -r /var/cache/dnf
sudo dnf upgrade

sudo dnf install httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --reload

echo "*** Completed Installing apache2"