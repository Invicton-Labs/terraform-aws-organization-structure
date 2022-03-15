variable "dynamic_depends_on" {
    description = "Used in the same manner as the Terraform `depends_on` variable, except that it can handle dynamic values such as locals."
    type = any
    default = null
}
