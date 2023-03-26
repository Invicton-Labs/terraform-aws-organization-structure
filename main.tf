// Get basic organization data
data "aws_organizations_organization" "organization" {}
locals {
  roots_basic = {
    for root in data.aws_organizations_organization.organization.roots :
    root.id => merge(root, {
      parent_id       = data.aws_organizations_organization.organization.id
      is_organization = false
      is_root         = true
      is_ou           = false
      }
    )
  }
}
data "aws_organizations_organizational_unit_child_accounts" "roots" {
  for_each  = local.roots_basic
  parent_id = each.value.id
}

// ==========================================================================================
// For each level of OUs, get all child OUs, all child accounts, and all descendant accounts

// We only search for a total depth of 5 nested OUs, since the limit is 5
// https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html

data "aws_organizations_organizational_units" "level_1" {
  for_each  = local.roots_basic
  parent_id = each.value.id
}
locals {
  level_1_ous_basic = merge([
    for id, v in data.aws_organizations_organizational_units.level_1 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id       = id
        is_organization = false
        is_root         = false
        is_ou           = true
      })
    }
  ]...)
}
data "aws_organizations_organizational_unit_child_accounts" "level_1" {
  for_each  = local.level_1_ous_basic
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_2" {
  for_each  = local.level_1_ous_basic
  parent_id = each.value.id
}
locals {
  level_2_ous_basic = merge([
    for id, v in data.aws_organizations_organizational_units.level_2 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id       = id
        is_organization = false
        is_root         = false
        is_ou           = true
      })
    }
  ]...)
}
data "aws_organizations_organizational_unit_child_accounts" "level_2" {
  for_each  = local.level_2_ous_basic
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_3" {
  for_each  = local.level_2_ous_basic
  parent_id = each.value.id
}
locals {
  level_3_ous_basic = merge([
    for id, v in data.aws_organizations_organizational_units.level_3 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id       = id
        is_organization = false
        is_root         = false
        is_ou           = true
      })
    }
  ]...)
}
data "aws_organizations_organizational_unit_child_accounts" "level_3" {
  for_each  = local.level_3_ous_basic
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_4" {
  for_each  = local.level_3_ous_basic
  parent_id = each.value.id
}
locals {
  level_4_ous_basic = merge([
    for id, v in data.aws_organizations_organizational_units.level_4 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id       = id
        is_organization = false
        is_root         = false
        is_ou           = true
      })
    }
  ]...)
}
data "aws_organizations_organizational_unit_child_accounts" "level_4" {
  for_each  = local.level_4_ous_basic
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_5" {
  for_each  = local.level_4_ous_basic
  parent_id = each.value.id
}
locals {
  level_5_ous_basic = merge([
    for id, v in data.aws_organizations_organizational_units.level_5 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id       = id
        is_organization = false
        is_root         = false
        is_ou           = true
      })
    }
  ]...)
}
data "aws_organizations_organizational_unit_child_accounts" "level_5" {
  for_each  = local.level_5_ous_basic
  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_6" {
  for_each  = local.level_5_ous_basic
  parent_id = each.value.id
}
locals {
  level_6_ous_basic = merge([
    for id, v in data.aws_organizations_organizational_units.level_6 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id       = id
        is_organization = false
        is_root         = false
        is_ou           = true
      })
    }
  ]...)
}
data "aws_organizations_organizational_unit_child_accounts" "level_6" {
  for_each  = local.level_6_ous_basic
  parent_id = each.value.id
}

// ==========================================================================================
// Now get info for each account

locals {

  organization = {
    id              = data.aws_organizations_organization.organization.id
    name            = "Organization"
    arn             = data.aws_organizations_organization.organization.arn
    org_path        = data.aws_organizations_organization.organization.id
    is_organization = true
    is_root         = false
    is_ou           = false
    parent_id       = null
  }

  // All child IDs for each OU
  ou_child_ou_ids = merge(
    {
      (local.organization.id) = data.aws_organizations_organization.organization.roots.*.id
    }
    , {
      for parent_id, ou_set in merge(
        data.aws_organizations_organizational_units.level_1,
        data.aws_organizations_organizational_units.level_2,
        data.aws_organizations_organizational_units.level_3,
        data.aws_organizations_organizational_units.level_4,
        data.aws_organizations_organizational_units.level_5,
        data.aws_organizations_organizational_units.level_6,
      ) :
      parent_id => [
        for ou in ou_set.children :
        ou.id
      ]
  })

  // All child accounts for each root/OU
  all_child_accounts_by_ou_id = {
    for ou_id, data_source in merge(
      {
        (local.organization.id) = {
          accounts = []
        }
      },
      data.aws_organizations_organizational_unit_child_accounts.roots,
      data.aws_organizations_organizational_unit_child_accounts.level_1,
      data.aws_organizations_organizational_unit_child_accounts.level_2,
      data.aws_organizations_organizational_unit_child_accounts.level_3,
      data.aws_organizations_organizational_unit_child_accounts.level_4,
      data.aws_organizations_organizational_unit_child_accounts.level_5,
      data.aws_organizations_organizational_unit_child_accounts.level_6,
    ) :
    ou_id => {
      for account in data_source.accounts :
      account.id => merge(account, {
        parent_id = ou_id
      })
      if !var.active_accounts_only || !contains(["SUSPENDED", "PENDING_CLOSURE"], account.status)
    }
  }

  // A map of root/OU id to root/OU basic data
  ous_basic = merge(
    {
      (local.organization.id) = local.organization
    },
    local.roots_basic,
    local.level_1_ous_basic,
    local.level_2_ous_basic,
    local.level_3_ous_basic,
    local.level_4_ous_basic,
    local.level_5_ous_basic,
    local.level_6_ous_basic,
  )

  ous_with_parents = {
    for ou_id, ou in local.ous_basic :
    ou_id => merge(ou, {
      parent_arn = ou.parent_id == null ? null : local.ous_basic[ou.parent_id].arn
    })
  }

  root_ous_with_ancestors = {
    for id in keys(local.roots_basic) :
    id => merge(local.ous_with_parents[id], {
      ancestor_ou_ids = [
        local.ous_with_parents[id].parent_id
      ]
    })
  }

  level_1_ous_with_ancestors = {
    for id in keys(local.level_1_ous_basic) :
    id => merge(local.ous_with_parents[id], {
      ancestor_ou_ids = concat([local.ous_with_parents[id].parent_id], local.root_ous_with_ancestors[local.ous_with_parents[id].parent_id].ancestor_ou_ids)
    })
  }

  level_2_ous_with_ancestors = {
    for id in keys(local.level_2_ous_basic) :
    id => merge(local.ous_with_parents[id], {
      ancestor_ou_ids = concat([local.ous_with_parents[id].parent_id], local.level_1_ous_with_ancestors[local.ous_with_parents[id].parent_id].ancestor_ou_ids)
    })
  }

  level_3_ous_with_ancestors = {
    for id in keys(local.level_3_ous_basic) :
    id => merge(local.ous_with_parents[id], {
      ancestor_ou_ids = concat([local.ous_with_parents[id].parent_id], local.level_2_ous_with_ancestors[local.ous_with_parents[id].parent_id].ancestor_ou_ids)
    })
  }

  level_4_ous_with_ancestors = {
    for id in keys(local.level_4_ous_basic) :
    id => merge(local.ous_with_parents[id], {
      ancestor_ou_ids = concat([local.ous_with_parents[id].parent_id], local.level_3_ous_with_ancestors[local.ous_with_parents[id].parent_id].ancestor_ou_ids)
    })
  }

  level_5_ous_with_ancestors = {
    for id in keys(local.level_5_ous_basic) :
    id => merge(local.ous_with_parents[id], {
      ancestor_ou_ids = concat([local.ous_with_parents[id].parent_id], local.level_4_ous_with_ancestors[local.ous_with_parents[id].parent_id].ancestor_ou_ids)
    })
  }

  level_6_ous_with_ancestors = {
    for id in keys(local.level_6_ous_basic) :
    id => merge(local.ous_with_parents[id], {
      ancestor_ou_ids = concat([local.ous_with_parents[id].parent_id], local.level_5_ous_with_ancestors[local.ous_with_parents[id].parent_id].ancestor_ou_ids)
    })
  }

  // All OUs with parents and ancestors
  ous_with_ancestors = merge(
    {
      (local.organization.id) = merge(local.organization, {
        ancestor_ou_ids = []
      })
    },
    local.root_ous_with_ancestors,
    local.level_1_ous_with_ancestors,
    local.level_2_ous_with_ancestors,
    local.level_3_ous_with_ancestors,
    local.level_4_ous_with_ancestors,
    local.level_5_ous_with_ancestors,
    local.level_6_ous_with_ancestors,
  )

  ous_with_children = {
    for ou_id, ou in local.ous_with_ancestors :
    ou_id => merge(ou, {
      ancestor_ou_arns = [
        for ancestor_id in local.ous_with_ancestors[ou_id].ancestor_ou_ids :
        local.ous_with_ancestors[ancestor_id].arn
      ]
      org_path     = join("/", concat(reverse(ou.ancestor_ou_ids), [ou_id]))
      child_ou_ids = local.ou_child_ou_ids[ou_id]
      child_ou_arns = [
        for child_ou_id in local.ou_child_ou_ids[ou_id] :
        local.ous_with_ancestors[child_ou_id].arn
      ]
    })
  }

  level_6_ous_with_descendants = {
    for ou_id in keys(local.level_6_ous_basic) :
    ou_id => merge(local.ous_with_children[ou_id], {
      descendant_ou_ids      = local.ous_with_children[ou_id].child_ou_ids
      descendant_account_ids = keys(local.all_child_accounts_by_ou_id[ou_id])
    })
  }

  level_5_ous_with_descendants = {
    for ou_id in keys(local.level_5_ous_basic) :
    ou_id => merge(local.ous_with_children[ou_id], {
      descendant_ou_ids = concat(local.ous_with_children[ou_id].child_ou_ids, flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_6_ous_with_descendants[child_ou_id].descendant_ou_ids
      ]))
      descendant_account_ids = concat(keys(local.all_child_accounts_by_ou_id[ou_id]), flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_6_ous_with_descendants[child_ou_id].descendant_account_ids
      ]))
    })
  }

  level_4_ous_with_descendants = {
    for ou_id in keys(local.level_4_ous_basic) :
    ou_id => merge(local.ous_with_children[ou_id], {
      descendant_ou_ids = concat(local.ous_with_children[ou_id].child_ou_ids, flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_5_ous_with_descendants[child_ou_id].descendant_ou_ids
      ]))
      descendant_account_ids = concat(keys(local.all_child_accounts_by_ou_id[ou_id]), flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_5_ous_with_descendants[child_ou_id].descendant_account_ids
      ]))
    })
  }

  level_3_ous_with_descendants = {
    for ou_id in keys(local.level_3_ous_basic) :
    ou_id => merge(local.ous_with_children[ou_id], {
      descendant_ou_ids = concat(local.ous_with_children[ou_id].child_ou_ids, flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_4_ous_with_descendants[child_ou_id].descendant_ou_ids
      ]))
      descendant_account_ids = concat(keys(local.all_child_accounts_by_ou_id[ou_id]), flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_4_ous_with_descendants[child_ou_id].descendant_account_ids
      ]))
    })
  }

  level_2_ous_with_descendants = {
    for ou_id in keys(local.level_2_ous_basic) :
    ou_id => merge(local.ous_with_children[ou_id], {
      descendant_ou_ids = concat(local.ous_with_children[ou_id].child_ou_ids, flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_3_ous_with_descendants[child_ou_id].descendant_ou_ids
      ]))
      descendant_account_ids = concat(keys(local.all_child_accounts_by_ou_id[ou_id]), flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_3_ous_with_descendants[child_ou_id].descendant_account_ids
      ]))
    })
  }

  level_1_ous_with_descendants = {
    for ou_id in keys(local.level_1_ous_basic) :
    ou_id => merge(local.ous_with_children[ou_id], {
      descendant_ou_ids = concat(local.ous_with_children[ou_id].child_ou_ids, flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_2_ous_with_descendants[child_ou_id].descendant_ou_ids
      ]))
      descendant_account_ids = concat(keys(local.all_child_accounts_by_ou_id[ou_id]), flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_2_ous_with_descendants[child_ou_id].descendant_account_ids
      ]))
    })
  }

  root_ous_with_descendants = {
    for ou_id in keys(local.roots_basic) :
    ou_id => merge(local.ous_with_children[ou_id], {
      descendant_ou_ids = concat(local.ous_with_children[ou_id].child_ou_ids, flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_1_ous_with_descendants[child_ou_id].descendant_ou_ids
      ]))
      descendant_account_ids = concat(keys(local.all_child_accounts_by_ou_id[ou_id]), flatten([
        for child_ou_id in local.ous_with_children[ou_id].child_ou_ids :
        local.level_1_ous_with_descendants[child_ou_id].descendant_account_ids
      ]))
    })
  }

  organization_with_descendants = {
    (local.organization.id) = merge(local.ous_with_children[local.organization.id], {
      descendant_ou_ids = concat(local.ous_with_children[local.organization.id].child_ou_ids, flatten([
        for child_ou_id in local.ous_with_children[local.organization.id].child_ou_ids :
        local.root_ous_with_descendants[child_ou_id].descendant_ou_ids
      ]))
      descendant_account_ids = concat(keys(local.all_child_accounts_by_ou_id[local.organization.id]), flatten([
        for child_ou_id in local.ous_with_children[local.organization.id].child_ou_ids :
        local.root_ous_with_descendants[child_ou_id].descendant_account_ids
      ]))
    })
  }

  // A map with keys for all entities (roots, OUs, and accounts)
  all_entity_ids_map = {
    for id in concat(keys(local.ous_basic), flatten([
      for accounts in values(local.all_child_accounts_by_ou_id) :
      keys(accounts)
    ])) :
    id => id
  }
}

data "aws_organizations_resource_tags" "all_entities" {
  for_each = {
    for k in keys(local.all_entity_ids_map) :
    k => k
    if k != local.organization.id
  }
  resource_id = each.key
}

locals {
  accounts_by_id = merge([
    for ou_id, child_accounts in local.all_child_accounts_by_ou_id :
    {
      for id, account in child_accounts :
      id => merge(account, {
        ancestor_ou_ids  = concat([ou_id], local.ous_with_children[ou_id].ancestor_ou_ids)
        ancestor_ou_arns = concat([local.ous_with_children[ou_id].arn], local.ous_with_children[ou_id].ancestor_ou_arns)
        resource_tags    = data.aws_organizations_resource_tags.all_entities[id]
      })
    }
  ]...)

  // All OUs with parents, ancestors, children, and descendants
  ous_by_id = {
    for ou_id, ou in merge(
      local.organization_with_descendants,
      local.root_ous_with_descendants,
      local.level_1_ous_with_descendants,
      local.level_2_ous_with_descendants,
      local.level_3_ous_with_descendants,
      local.level_4_ous_with_descendants,
      local.level_5_ous_with_descendants,
      local.level_6_ous_with_descendants,
    ) :
    ou_id => merge(ou, {
      descendant_ou_arns = [
        for descendant_ou_id in ou.descendant_ou_ids :
        local.ous_with_children[descendant_ou_id].arn
      ]
      descendant_account_arns = [
        for descendant_account_id in ou.descendant_account_ids :
        local.accounts_by_id[descendant_account_id].arn
      ]
      resource_tags = ou_id == local.organization.id ? null : data.aws_organizations_resource_tags.all_entities[ou_id].tags
    })
  }
}

locals {
  accounts_by_arn = {
    for account in values(local.accounts_by_id) :
    (account.arn) => account
  }
  accounts_by_name = {
    for account in values(local.accounts_by_id) :
    (account.name) => account
  }
  accounts_by_email = {
    for account in values(local.accounts_by_id) :
    (account.email) => account
  }

  ous_by_arn = {
    for k, v in local.ous_by_id :
    (v.arn) => v
  }

  ous_by_name = {
    for k, v in local.ous_by_id :
    (v.name) => v
  }

  ous_by_org_path = {
    for k, v in local.ous_by_id :
    (v.org_path) => v
  }
}
