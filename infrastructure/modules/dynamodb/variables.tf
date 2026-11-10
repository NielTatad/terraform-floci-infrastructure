variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "billing_mode" {
  description = "Billing mode for the table. Valid values: PAY_PER_REQUEST, PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "hash_key" {
  description = "Name of the partition (hash) key attribute."
  type        = string
}

variable "hash_key_type" {
  description = "Type of the partition key. Valid values: S (String), N (Number), B (Binary)."
  type        = string
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.hash_key_type)
    error_message = "hash_key_type must be S, N, or B."
  }
}

variable "range_key" {
  description = "Name of the sort (range) key attribute. Leave null for partition-key-only tables."
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "Type of the sort key. Valid values: S (String), N (Number), B (Binary)."
  type        = string
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.range_key_type)
    error_message = "range_key_type must be S, N, or B."
  }
}

variable "read_capacity" {
  description = "Provisioned read capacity units. Only used when billing_mode is PROVISIONED."
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Provisioned write capacity units. Only used when billing_mode is PROVISIONED."
  type        = number
  default     = 5
}

variable "tags" {
  description = "Map of tags to apply to the DynamoDB table."
  type        = map(string)
  default     = {}
}
