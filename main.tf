module "dynamic_depends_on" {
  source = "./dynamic-depends-on"
  dynamic_depends_on = var.dynamic_depends_on
}

data "aws_organizations_organization" "organization" {
  depends_on = [
    module.dynamic_depends_on
  ]
}

// We only search for a total depth of 5 nested OUs, since the limit is 5
// https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html
locals {
  roots = {
    for root in data.aws_organizations_organization.organization.roots :
    root.id => {
      id           = root.id
      name         = root.name
      arn          = root.arn
      parent_id    = null
      ancestor_ids = []
    }
  }
}

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
    for k, v in data.aws_organizations_organizational_units.level_1 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id = v.parent_id
        ancestor_ids = [
          v.parent_id
        ]
      })
    }
  ]...)
  level_2_ous = merge([
    for k, v in data.aws_organizations_organizational_units.level_2 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id = v.parent_id
        ancestor_ids = concat(
          [
            v.parent_id
          ],
          local.level_1_ous[v.parent_id].ancestor_ids
        )
      })
    }
  ]...)
  level_3_ous = merge([
    for k, v in data.aws_organizations_organizational_units.level_3 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id = v.parent_id
        ancestor_ids = concat(
          [
            v.parent_id
          ],
          local.level_2_ous[v.parent_id].ancestor_ids
        )
      })
    }
  ]...)
  level_4_ous = merge([
    for k, v in data.aws_organizations_organizational_units.level_4 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id = v.parent_id
        ancestor_ids = concat(
          [
            v.parent_id
          ],
          local.level_3_ous[v.parent_id].ancestor_ids
        )
      })
    }
  ]...)
  level_5_ous = merge([
    for k, v in data.aws_organizations_organizational_units.level_5 :
    {
      for child in v.children :
      child.id => merge(child, {
        parent_id = v.parent_id
        ancestor_ids = concat(
          [
            v.parent_id
          ],
          local.level_4_ous[v.parent_id].ancestor_ids
        )
      })
    }
  ]...)

  all_ous = merge(
    local.roots,
    local.level_1_ous,
    local.level_2_ous,
    local.level_3_ous,
    local.level_4_ous,
    local.level_5_ous,
  )

  all_ous_with_children = {
    for ou_id, ou in local.all_ous :
    ou_id => merge(ou, {
      children_ids = [
        for child_ou_id, child_ou in local.all_ous :
        child_ou_id
        if child_ou.parent_id == ou_id
      ]
      descendant_ids = [
        for descendant_ou_id, descendant_ou in local.all_ous :
        descendant_ou_id
        if contains(descendant_ou.ancestor_ids, ou_id)
      ]
      // Add a field that has all ancestor OU IDs and this OU's own ID. These are the OU IDs that apply to anything in this OU.
      applicable_ou_ids = concat([ou_id], ou.ancestor_ids)
    })
  }

  all_ous_with_arns = {
    for ou_id, ou in local.all_ous_with_children :
    ou_id => merge(ou, {
      // If it's an organization root, then the parent ARN is the organization ARN
      // Otherwise, it's the ARN of the parent OU or root
      parent_arn = ou.parent_id == null ? data.aws_organizations_organization.organization.arn : local.all_ous[ou.parent_id].arn
      ancestor_arns = concat([
        for ancestor_id in ou.ancestor_ids :
        local.all_ous[ancestor_id].arn
        ], [
        data.aws_organizations_organization.organization.arn
          // Add the organization ARN to the list
      ])
      applicable_ou_arns = concat([
        for applicable_ou_id in ou.applicable_ou_ids :
        local.all_ous[applicable_ou_id].arn
        ], [
          // Add the organization ARN to the list
        data.aws_organizations_organization.organization.arn
      ])
      children_arns = [
        for child_id in ou.children_ids :
        local.all_ous[child_id].arn
      ]
      descendant_arns = [
        for descendant_id in ou.descendant_ids :
        local.all_ous[descendant_id].arn
      ]
      // Add the organization ID to the list
      ancestor_ids = concat(ou.ancestor_ids, [data.aws_organizations_organization.organization.id])
      // Add the organization ID to the list
      applicable_ou_ids = concat(ou.applicable_ou_ids, [data.aws_organizations_organization.organization.id])
    })
  }

  all_ous_by_arn = {
    for ou in values(local.all_ous_with_arns) :
    ou.arn => ou
  }
}
