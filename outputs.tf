output "ous_by_id" {
  description = "A map of OU IDs to OU metadata. Each value (OU metadata) includes the OU's ID, name, ARN, parent OU ID and ARN, ancestor OU IDs and ARNs (including grandparents, great-grandparents, etc., all the way up to the organization root), child OU IDs and ARNs (direct descendants), and all descendant OU IDs and ARNs (children, grandchildren, etc.)."
  value       = local.all_ous_with_arns
}

output "ous_by_arn" {
  description = "Same as the `ous_by_ids` output, except that the keys are the OU ARNs instead of IDs."
  value       = local.all_ous_by_arn
}

output "organization" {
  description = "The metadata for the organization (matches the output of the `aws_organizations_organization` data source)."
  value       = data.aws_organizations_organization.organization
}

output "accounts_by_id" {
  description = "A map of account ID to account information (containing ID, name, email, ARN, and status)."
  value = local.accounts_by_id
}

output "accounts_by_name" {
  description = "A map of account name to account information (containing ID, name, email, ARN, and status)."
  value = local.accounts_by_name
}

output "accounts_by_arn" {
  description = "A map of account ARN to account information (containing ID, name, email, ARN, and status)."
  value = local.accounts_by_arn
}

output "accounts_by_root_email" {
  description = "A map of account root email to account information (containing ID, name, email, ARN, and status)."
  value = local.accounts_by_root_email
}
