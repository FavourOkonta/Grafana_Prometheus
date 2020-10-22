#! /bin/bash
sudo -i
sudo yum install git java docker -y
sudo service docker start 
sudo usermod -aG docker ec2-user
sudo docker pull prom/prometheus
sudo docker pull grafana/grafana
