# variables.tf

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "admin_principal_arns" {
  description = "List of IAM principal ARNs allowed to assume the delegated root access role"
  type        = list(string)
  default     = []
  # Example: ["arn:aws:iam::123456789012:user/AdminUser", "arn:aws:iam::123456789012:role/AdminRole"]
}

variable "member_account_id" {
  description = "AWS account ID for testing root access delegation"
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for root access delegation alarms"
  type        = string
  default     = ""
}

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "enable_cloudwatch_alarms" {
  description = "Whether to enable CloudWatch alarms for monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}