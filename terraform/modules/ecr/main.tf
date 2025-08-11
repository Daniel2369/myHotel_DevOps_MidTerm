resource "aws_ecr_repository" "myHotel" {
  name = var.repository_name
}

resource "null_resource" "docker_build_and_push" {
  depends_on = [aws_ecr_repository.myHotel]

  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.myHotel.repository_url}

      docker buildx build --platform linux/amd64 -t ${var.image_name}:${var.tag} --push ${var.docker_context}

      docker tag ${var.image_name}:${var.tag} ${aws_ecr_repository.myHotel.repository_url}:${var.tag}

      docker push ${aws_ecr_repository.myHotel.repository_url}:${var.tag}
    EOT
  }
}
