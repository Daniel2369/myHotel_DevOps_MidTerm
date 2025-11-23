#!/bin/bash
set -e

# Variables - replace with your actual values or export them before running the script
DOCKERHUB_REPO="${DOCKERHUB_USERNAME}/devops-final-project"

IMAGE_TAG="latest"
IMAGE_NAME="myhotel"

# Log in to DockerHub using token (recommended way)
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

# Tag your local image with your DockerHub repo
docker tag $IMAGE_NAME:$IMAGE_TAG $DOCKERHUB_REPO:$IMAGE_TAG

# Push the image
docker push $DOCKERHUB_REPO:$IMAGE_TAG

echo "Docker image pushed to $DOCKERHUB_REPO:$IMAGE_TAG"

