provider "aws" {
  region  = "ca-central-1"
  profile = "InvictonLabs_management"
}

module "org_structure" {
  source = "../"
}

output "ous_by_id" {
  value = module.org_structure.ous_by_id
}

output "accounts_by_id" {
  value = module.org_structure.accounts_by_id
}
