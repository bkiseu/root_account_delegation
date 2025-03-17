# Terraform Implementation for AWS Organization Root Access Delegation

This Terraform module implements AWS Organization Root Access Delegation to improve security posture by eliminating the need for direct root credential usage across member accounts in your AWS Organization.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with management account credentials
- AWS Organization with all features enabled
- Administrative access to create IAM roles and policies

## Usage

1. Clone this repository
2. Configure variables in `terraform.tfvars` or through environment variables
3. Initialize, plan, and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply
```

## Important Notes

- The `enable-root-access-for-member-accounts` command is executed using a `null_resource` with `local-exec` since Terraform doesn't directly support this AWS Organizations API call yet. Make sure AWS CLI is installed and configured on the machine running Terraform.

- You must specify which IAM principals are allowed to assume the delegated root access role by populating the `admin_principal_arns` variable.

- After implementation, you should test the delegation thoroughly before removing root credentials from member accounts.

## Example `terraform.tfvars`

```hcl
aws_region = "us-east-1"
admin_principal_arns = [
  "arn:aws:iam::123456789012:user/AdminUser",
  "arn:aws:iam::123456789012:role/AdminRole"
]
member_account_id = "987654321098"
sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:RootAccessAlerts"
organization_id = "o-exampleorgid"
```

## Post-Implementation Steps

1. Test the delegation by assuming the created role and executing root actions on member accounts:

```bash
# Assume the delegated role
aws sts assume-role \
  --role-arn <delegated_root_access_role_arn> \
  --role-session-name DelegatedRootAccess

# Set the temporary credentials in your environment
export AWS_ACCESS_KEY_ID="<Temporary access key>"
export AWS_SECRET_ACCESS_KEY="<Temporary secret key>"
export AWS_SESSION_TOKEN="<Temporary session token>"

# Execute a root action
aws organizations execute-root-action \
  --action-name UpdateS3BucketPolicy \
  --account-id <member_account_id> \
  --parameters '{...}'
```

2. Once testing is successful, proceed with removing root credentials from member accounts

## Root Credential Removal

After successful implementation and testing, you can proceed with the cleanup of root credentials from member accounts. This can be automated with a script or implemented as another Terraform module.

## Security Considerations

- Limit the number of principals who can assume the delegated root access role
- Enable CloudTrail logging for all Organizations API calls
- Set up CloudWatch alarms to monitor usage of the delegated root access
- Review IAM Access Analyzer findings regularly
- Consider implementing additional guardrails through Service Control Policies (SCPs)

## Resources

- [AWS Documentation: Root Delegation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-enable-root-access.html)
- [AWS Blog: Secure Root User Access for Member Accounts](https://aws.amazon.com/blogs/security/secure-root-user-access-for-member-accounts-in-aws-organizations/)
