# Terraform AWS Organization Structure

This module computes a useful mapping of Organizational Units within an AWS Organization. We decided to develop this module when we needed to determine all of the Organizational Units that a given AWS account was in (all of the ancestors, including the parent, grandparent, great-grandparent, etc., all the way back to the organization root).

## Usage

```
module "organization_structure" {
  source = "Invicton-Labs/organization-structure/aws"
}

output "ous_by_id" {
  value = module.organization_structure.ous_by_id
}
output "accounts_by_id" {
  value = module.organization_structure.accounts_by_id
}
```

Output:
```
Outputs:

ous_by_id = {
  // TODO: generate some fake output data that doesn't expose a bunch of sensitive data
}
accounts_by_id = {
  // TODO: generate some fake output data that doesn't expose a bunch of sensitive data
}
```
