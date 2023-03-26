variable "active_accounts_only" {
  description = "Whether the listed accounts should only include accounts that are in active status. If `true`, accounts in \"SUSPENDED\" or \"PENDING_CLOSURE\" status will not be returned."
  type        = bool
  default     = true
  nullable    = false
}
