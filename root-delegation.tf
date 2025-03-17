# Terraform Implementation for AWS Organization Root Access Delegation
# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Use management account credentials
  # This provider will be used for operations in the management account
}

# Provider for member account operations (if needed)
provider "aws" {
  alias  = "member_account"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${var.member_account_id}:role/OrganizationAccountAccessRole"
  }
}

# Enable root access delegation in AWS Organizations
# Note: This might require AWS CLI or API as Terraform doesn't directly support this yet
# You may need to use a null_resource with local-exec to run AWS CLI commands

resource "null_resource" "enable_root_access_delegation" {
  provisioner "local-exec" {
    command = "aws organizations enable-root-access-for-member-accounts --region ${var.aws_region}"
  }
}

# Create the IAM policy for delegated root access
resource "aws_iam_policy" "delegated_root_access_policy" {
  name        = "DelegatedRootAccessPolicy"
  description = "Policy for delegated administrators to execute root actions in member accounts"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRootActionExecution"
        Effect   = "Allow"
        Action   = ["organizations:ExecuteRootAction"]
        Resource = "*"
      },
      {
        Sid    = "AllowRootAccountManagement"
        Effect = "Allow"
        Action = [
          "organizations:DescribeAccount",
          "organizations:ListAccounts",
          "organizations:ListRoots",
          "organizations:ListOrganizationalUnitsForParent",
          "organizations:ListAccountsForParent",
          "organizations:ListDelegatedServicesForAccount"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowCloudTrailAccess"
        Effect   = "Allow"
        Action   = ["cloudtrail:LookupEvents"]
        Resource = "*"
      }
    ]
  })
}

# Create IAM role for delegated administrators
resource "aws_iam_role" "delegated_root_access_role" {
  name = "DelegatedRootAccessRole"
  description = "Role for executing root actions in member accounts"
  
  # Trust relationship - who can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.admin_principal_arns
        }
        Action = "sts:AssumeRole"
        Condition = {}
      }
    ]
  })

  # Optional: Add tags
  tags = {
    Name = "DelegatedRootAccessRole"
    Purpose = "AWS Organization Root Access Delegation"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach_delegation_policy" {
  role       = aws_iam_role.delegated_root_access_role.name
  policy_arn = aws_iam_policy.delegated_root_access_policy.arn
}

# Optional: Create a boundary policy to limit the scope of the role
resource "aws_iam_policy" "permission_boundary" {
  name        = "DelegatedRootAccessBoundary"
  description = "Permission boundary for delegated root access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "organizations:*",
          "cloudtrail:*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Deny"
        Action   = [
          "organizations:LeaveOrganization",
          "organizations:DeleteOrganization",
          "organizations:RemoveAccountFromOrganization"
        ]
        Resource = "*"
      }
    ]
  })
}

# Apply permission boundary to the role
resource "aws_iam_role_policy_attachment" "apply_boundary" {
  role       = aws_iam_role.delegated_root_access_role.name
  policy_arn = aws_iam_policy.permission_boundary.arn
}

# Optional: CloudWatch Alarm for monitoring usage
resource "aws_cloudwatch_metric_alarm" "root_access_delegation_usage" {
  alarm_name          = "RootAccessDelegationUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ExecuteRootActionCount"
  namespace           = "AWS/Organizations"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Monitors usage of delegated root access"
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    Service = "Organizations"
  }
}
