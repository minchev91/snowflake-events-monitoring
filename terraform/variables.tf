variable "snowflake_account" {}
variable "snowflake_user" {}
variable "snowflake_password" {
  sensitive = true
}
variable "snowflake_warehouse" {}
variable "snowflake_database" {}
variable "snowflake_schema" {}
variable "snowflake_role" {
  default = null
}
