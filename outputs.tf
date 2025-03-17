# outputs.tf

output "delegated_root_access_role_arn" {
  description = "ARN of the created delegated root access role"
  value       = aws_iam_role.delegated_root_access_role.arn
}

output "delegated_root_access_policy_arn" {
  description = "ARN of the delegated root access policy"
  value       = aws_iam_policy.delegated_root_access_policy.arn
}

output "permission_boundary_arn" {
  description = "ARN of the permission boundary policy"
  value       = aws_iam_policy.permission_boundary.arn
}

output "assume_role_command" {
  description = "AWS CLI command to assume the delegated root access role"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.delegated_root_access_role.arn} --role-session-name DelegatedRootAccess"
}