# Terraform AWS Organization Structure

This module computes a useful mapping of Organizational Units within an AWS Organization. We decided to develop this module when we needed to determine all of the Organizational Units that a given AWS account was in (all of the ancestors, including the parent, grandparent, great-grandparent, etc., all the way back to the organization root).

Due to the lack of any Terraform data source (as of the time of this writing) that allow listing all of the accounts within an organizational unit, or the parent organizational unit of a given account ID, it's not possible using standard Terraform data sources to include the account IDs themselves in this mapping. However, if you know the `parent_id` of a given account (which would have been used in the [aws_organizations_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) resource that created the account), you can use that to look up the OU in the `ous_by_id` output of this module, which will in turn give you all of that OU's ancestors in the OU's `ancestor_ids` field.

## Usage

```
module "organization_structure" {
  source = "Invicton-Labs/organization-structure/aws"
}

output "ous_by_id" {
  value = module.organization_structure.ous_by_id
}
```

Output:
```
Outputs:

ous_by_id = {
  // TODO: generate some fake output data that doesn't expose a bunch of sensitive data
}
```
