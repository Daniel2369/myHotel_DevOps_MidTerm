# #!/bin/bash
# set -e

# # Variables - replace these with your actual values or export them before running the script
# AWS_REGION="us-east-1"
# ECR_REPO_URI="623866174656.dkr.ecr.us-east-1.amazonaws.com/myhotel"
# IMAGE_TAG="latest"
# IMAGE_NAME="myhotel"

# # Authenticate Docker to your ECR registry
# aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(echo $ECR_REPO_URI | cut -d '/' -f 1)

# # Tag your local Docker image with the ECR repository URI
# docker tag $IMAGE_NAME:$IMAGE_TAG $ECR_REPO_URI:$IMAGE_TAG

# # Push the image to ECR
# docker push $ECR_REPO_URI:$IMAGE_TAG

# echo "Docker image pushed to $ECR_REPO_URI:$IMAGE_TAG"
