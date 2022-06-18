data "aws_organizations_organization" "organization" {}

locals {
  org_entity = {
    id                   = data.aws_organizations_organization.organization.id
    name                 = "Organization"
    arn                  = data.aws_organizations_organization.organization.arn
    parent_id            = null
    ancestor_entity_ids  = []
    parent_arn           = null
    ancestor_entity_arns = []
    org_path             = data.aws_organizations_organization.organization.id
  }

  roots = {
    for root in data.aws_organizations_organization.organization.roots :
    root.id => {
      id        = root.id
      name      = root.name
      arn       = root.arn
      parent_id = local.org_entity.id
      ancestor_entity_ids = concat([
        local.org_entity.id
      ], local.org_entity.ancestor_entity_ids)
      parent_arn = local.org_entity.arn
      ancestor_entity_arns = concat([
        local.org_entity.arn
      ], local.org_entity.ancestor_entity_arns)
      org_path = "${local.org_entity.org_path}/${root.id}"
    }
  }

  all_accounts_by_id = data.aws_organizations_organization.organization.accounts == null ? null : {
    for account in data.aws_organizations_organization.organization.accounts :
    account.id => account
  }
}

// We only search for a total depth of 5 nested OUs, since the limit is 5
// https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html

data "aws_organizations_organizational_units" "level_1" {
  for_each  = local.roots
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_2" {
  for_each = merge([
    for k, v in data.aws_organizations_organizational_units.level_1 :
    {
      for child in v.children :
      child.id => child
    }
  ]...)
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_3" {
  for_each = merge([
    for k, v in data.aws_organizations_organizational_units.level_2 :
    {
      for child in v.children :
      child.id => child
    }
  ]...)
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_4" {
  for_each = merge([
    for k, v in data.aws_organizations_organizational_units.level_3 :
    {
      for child in v.children :
      child.id => child
    }
  ]...)
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_5" {
  for_each = merge([
    for k, v in data.aws_organizations_organizational_units.level_4 :
    {
      for child in v.children :
      child.id => child
    }
  ]...)
  parent_id = each.value.id
}

locals {
  level_1_ous = merge([
    for ou in values(data.aws_organizations_organizational_units.level_1) :
    {
      for child in ou.children :
      child.id => merge(child, {
        parent_id  = ou.parent_id
        parent_arn = local.roots[ou.parent_id].arn
        ancestor_entity_ids = concat(
          [
            ou.parent_id
          ],
          local.roots[ou.parent_id].ancestor_entity_ids
        )
        ancestor_entity_arns = concat(
          [
            local.roots[ou.parent_id].arn
          ],
          local.roots[ou.parent_id].ancestor_entity_arns
        )
        org_path = "${local.roots[ou.parent_id].org_path}/${child.id}"
      })
    }
  ]...)
  level_2_ous = merge([
    for ou in values(data.aws_organizations_organizational_units.level_2) :
    {
      for child in ou.children :
      child.id => merge(child, {
        parent_id  = ou.parent_id
        parent_arn = local.level_1_ous[ou.parent_id].arn
        ancestor_entity_ids = concat(
          [
            ou.parent_id
          ],
          local.level_1_ous[ou.parent_id].ancestor_entity_ids
        )
        ancestor_entity_arns = concat(
          [
            local.level_1_ous[ou.parent_id].arn
          ],
          local.level_1_ous[ou.parent_id].ancestor_entity_arns
        )
        org_path = "${local.level_1_ous[ou.parent_id].org_path}/${child.id}"
      })
    }
  ]...)
  level_3_ous = merge([
    for ou in values(data.aws_organizations_organizational_units.level_3) :
    {
      for child in ou.children :
      child.id => merge(child, {
        parent_id  = ou.parent_id
        parent_arn = local.level_2_ous[ou.parent_id].arn
        ancestor_entity_ids = concat(
          [
            ou.parent_id
          ],
          local.level_2_ous[ou.parent_id].ancestor_entity_ids
        )
        ancestor_entity_arns = concat(
          [
            local.level_2_ous[ou.parent_id].arn
          ],
          local.level_2_ous[ou.parent_id].ancestor_entity_arns
        )
        org_path = "${local.level_2_ous[ou.parent_id].org_path}/${child.id}"
      })
    }
  ]...)
  level_4_ous = merge([
    for ou in values(data.aws_organizations_organizational_units.level_4) :
    {
      for child in ou.children :
      child.id => merge(child, {
        parent_id  = ou.parent_id
        parent_arn = local.level_3_ous[ou.parent_id].arn
        ancestor_entity_ids = concat(
          [
            ou.parent_id
          ],
          local.level_3_ous[ou.parent_id].ancestor_entity_ids
        )
        ancestor_entity_arns = concat(
          [
            local.level_3_ous[ou.parent_id].arn
          ],
          local.level_3_ous[ou.parent_id].ancestor_entity_arns
        )
        org_path = "${local.level_3_ous[ou.parent_id].org_path}/${child.id}"
      })
    }
  ]...)
  level_5_ous = merge([
    for ou in values(data.aws_organizations_organizational_units.level_5) :
    {
      for child in ou.children :
      child.id => merge(child, {
        parent_id  = ou.parent_id
        parent_arn = local.level_4_ous[ou.parent_id].arn
        ancestor_entity_ids = concat(
          [
            ou.parent_id
          ],
          local.level_4_ous[ou.parent_id].ancestor_entity_ids
        )
        ancestor_entity_arns = concat(
          [
            local.level_4_ous[ou.parent_id].arn
          ],
          local.level_4_ous[ou.parent_id].ancestor_entity_arns
        )
        org_path = "${local.level_4_ous[ou.parent_id].org_path}/${child.id}"
      })
    }
  ]...)

  all_ous = merge(
    {
      (local.org_entity.id) = local.org_entity
    },
    local.roots,
    local.level_1_ous,
    local.level_2_ous,
    local.level_3_ous,
    local.level_4_ous,
    local.level_5_ous,
  )

  // Add metadata to each OU, for its ancestor and descendant OUs
  all_ous_with_family = {
    for ou_id, ou in local.all_ous :
    ou_id => merge(ou,
      {

        // Add a field that has all ancestor OU IDs and this OU's own ID. These are the OU IDs that apply to anything in this OU.
        applicable_entity_ids  = concat([ou_id], ou.ancestor_entity_ids)
        applicable_entity_arns = concat([ou.arn], ou.ancestor_entity_arns)

        // Add IDs and ARNs of direct children
        child_ou_ids = [
          for child_ou_id, child_ou in local.all_ous :
          child_ou_id
          if child_ou.parent_id == ou_id
        ]
        child_ou_arns = [
          for child_ou in values(local.all_ous) :
          child_ou.arn
          if child_ou.parent_id == ou_id
        ]

        // Add IDs and ARNs of all descendants
        descendant_ou_ids = [
          for descendant_ou_id, descendant_ou in local.all_ous :
          descendant_ou_id
          if contains(descendant_ou.ancestor_entity_ids, ou_id)
        ]
        descendant_ou_arns = [
          for descendant_ou in values(local.all_ous) :
          descendant_ou.arn
          if contains(descendant_ou.ancestor_entity_ids, ou_id)
        ]
    })
  }

  // If account parent data was provided, use it to add account family data
  all_ous_by_id = {
    for ou_id, ou in local.all_ous_with_family :
    ou_id => merge(ou, local.var_account_parent_ids != null ? {
      // A list of all account IDs that are directly within this OU
      child_account_ids = [
        for account_id, parent_id in local.var_account_parent_ids :
        account_id
        if parent_id == ou_id
      ]
      child_account_arns = [
        for account_id, parent_id in local.var_account_parent_ids :
        local.all_accounts_by_id[account_id].arn
        if parent_id == ou_id
      ]
      // A list of all account IDs that are directly within this OU or any of its descendant OUs
      descendant_account_ids = [
        for account_id, parent_id in local.var_account_parent_ids :
        account_id
        if contains(concat([ou_id], ou.descendant_ou_ids), parent_id)
      ]
      descendant_account_arns = [
        for account_id, parent_id in local.var_account_parent_ids :
        local.all_accounts_by_id[account_id].arn
        if contains(concat([ou_id], ou.descendant_ou_ids), parent_id)
      ]
    } : {})
  }

  all_ous_by_arn = {
    for ou in values(local.all_ous_by_id) :
    ou.arn => ou
  }

  all_ous_by_name = {
    for ou in values(local.all_ous_by_id) :
    ou.name => ou
  }

  accounts_by_id = local.all_accounts_by_id == null ? null : {
    for account in values(local.all_accounts_by_id) :
    account.id => merge(account,
      local.var_account_parent_ids != null ? contains(keys(local.var_account_parent_ids), account.id) ? {
        ou = local.all_ous_by_id[local.var_account_parent_ids[account.id]]
      } : {} : {}
    )
    // Only include accounts that are active, unless we want to get non-active accounts as well
    if !local.var_active_accounts_only || account.status == "ACTIVE"
  }

  accounts_by_name = local.accounts_by_id == null ? null : {
    for account in values(local.accounts_by_id) :
    account.name => account
  }

  accounts_by_arn = local.accounts_by_id == null ? null : {
    for account in values(local.accounts_by_id) :
    account.arn => account
  }

  accounts_by_root_email = local.accounts_by_id == null ? null : {
    for account in values(local.accounts_by_id) :
    account.email => account
  }
}
