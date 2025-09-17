#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -aG docker ec2-user

# Login to Docker Hub
echo "${dockerhub_password}" | docker login -u "${dockerhub_user}" --password-stdin

# Stop old container if running
docker stop springboot-app || true
docker rm springboot-app || true

# Pull and run latest image
docker pull ${app_image_uri}
docker run -d --name springboot-app -p 8080:8080 ${app_image_uri}

# Optional: Watchtower to auto-redeploy if new image is pushed
docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower springboot-app --interval 30
