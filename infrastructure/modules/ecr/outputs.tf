output "repository_url" {
  description = "URL of the ECR repository. Use this as the Docker image registry."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "Registry ID (AWS account ID) the repository belongs to."
  value       = aws_ecr_repository.this.registry_id
}
