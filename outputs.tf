//==================================================
//     Outputs that match the input variables
//==================================================
output "active_accounts_only" {
  description = "The value of the `active_accounts_only` input variable, or the default value if the input was `null`."
  value       = var.active_accounts_only
}


//==================================================
//       Outputs generated by this module
//==================================================
output "ous_by_id" {
  description = "A map of Organization, Organization Root, and Organizational Unit IDs to Org/Root/OU metadata. Each value includes the OU's ID, name, ARN, parent OU ID and ARN, ancestor OU IDs and ARNs (including grandparents, great-grandparents, etc., all the way up to the organization ID), child OU IDs and ARNs (direct descendants), and all descendant OU IDs and ARNs (children, grandchildren, etc.). If the `account_parent_ids` variable was provided, it will also include all direct child accounts and all decendant accounts."
  value       = local.ous_by_id
}

output "ous_by_arn" {
  description = "Same as the `ous_by_ids` output, except that the keys are the OU ARNs instead of IDs."
  value       = local.ous_by_arn
}

output "ous_by_name" {
  description = "Same as the `ous_by_ids` output, except that the keys are the OU names instead of IDs."
  value       = local.ous_by_name
}

output "ous_by_org_path" {
  description = "Same as the `ous_by_ids` output, except that the keys are the OU paths (e.g. \"o-abcdefg123/r-zxy1/ou-zxy1-foobar99\") instead of IDs."
  value       = local.ous_by_org_path
}

output "organization" {
  description = "The metadata for the organization (matches the output of the `aws_organizations_organization` data source)."
  value       = data.aws_organizations_organization.organization
}

output "accounts_by_id" {
  description = "A map of account ID to account information (containing ID, name, email, ARN, and status). If the `account_parent_ids` variable was provided, it will also include information about the organizational units that apply to each account."
  value       = local.accounts_by_id
}

output "accounts_by_name" {
  description = "Same as the `accounts_by_id` output, except that the keys are the account names instead of IDs."
  value       = local.accounts_by_name
}

output "accounts_by_arn" {
  description = "Same as the `accounts_by_id` output, except that the keys are the account ARNs instead of IDs."
  value       = local.accounts_by_arn
}

output "accounts_by_root_email" {
  description = "Same as the `accounts_by_id` output, except that the keys are the account root email addresses instead of IDs."
  value       = local.accounts_by_email
}
