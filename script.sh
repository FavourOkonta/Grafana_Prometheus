#! /bin/bash
sudo -i
sudo service docker start
sudo docker run -d --name=grafana1 -p 3000:3000 grafana/grafana