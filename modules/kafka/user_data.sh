#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -aG docker ec2-user

# Login to Docker Hub
echo "${dockerhub_password}" | docker login -u "${dockerhub_user}" --password-stdin

# Stop old Kafka container if running
docker stop kafka || true
docker rm kafka || true

# Pull and run latest Kafka image from Docker Hub
docker pull ${dockerhub_user}/kafka:latest
docker run -d --name kafka -p 9092:9092 ${dockerhub_user}/kafka:latest

# Watchtower for automatic redeploy if new image is pushed
docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower kafka --interval 30
