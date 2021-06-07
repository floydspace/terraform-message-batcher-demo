variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "policy_statements" {
  type = list(map(any))
}

variable "event_source_arn" {
  type = string
}

variable "batch_size" {
  type    = number
  default = 1
}

variable "tags" {
  type = map(string)
}

variable "source_path" {}
