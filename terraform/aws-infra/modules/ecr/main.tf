resource "aws_ecr_repository" "ecr_repos" {
  name = "${var.project}-${var.repo_name}"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr_repos.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_number_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = "${var.ecr_number_images}"
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
