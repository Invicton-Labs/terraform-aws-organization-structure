variable "account_parent_ids" {
  description = "A map of account ID to parent ID. This is optional; if it is provided, account IDs will be added to each OU (the accounts that are within that OU)."
  type        = map(string)
  default     = null
}
locals {
  var_account_parent_ids = var.account_parent_ids
}

variable "active_accounts_only" {
  description = "Whether the listed accounts should only include accounts that are in active status. If `true`, accounts in \"SUSPENDED\" or \"PENDING_CLOSURE\" status will not be returned."
  type        = bool
  default     = true
}
locals {
  var_active_accounts_only = var.active_accounts_only != null ? var.active_accounts_only : true
}
