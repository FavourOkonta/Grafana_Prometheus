#! /bin/bash
sudo -i
sudo service docker start
sudo docker run -d --name=prometheus1 -p 9090:9090 prom/prometheus
