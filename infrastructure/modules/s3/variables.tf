variable "bucket_name" {
  description = "Name of the S3 bucket. Must be globally unique within the Floci instance."
  type        = string
}

variable "enable_versioning" {
  description = "Enable object versioning on the bucket. Supported by Floci."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to the bucket and related resources."
  type        = map(string)
  default     = {}
}
