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
