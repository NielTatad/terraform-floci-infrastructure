variable "queue_name" {
  description = "Name of the SQS queue. FIFO queues must end with '.fifo'."
  type        = string
}

variable "fifo_queue" {
  description = "Set to true to create a FIFO queue. The queue_name must end with '.fifo'."
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "Duration (in seconds) that a received message is hidden from other consumers. Range: 0–43200."
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds must be between 0 and 43200."
  }
}

variable "message_retention_seconds" {
  description = "Duration (in seconds) that SQS retains a message. Range: 60–1209600 (1 min to 14 days)."
  type        = number
  default     = 345600 # 4 days

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds must be between 60 and 1209600."
  }
}

variable "delay_seconds" {
  description = "Time (in seconds) to delay delivery of all messages added to the queue. Range: 0–900."
  type        = number
  default     = 0

  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "delay_seconds must be between 0 and 900."
  }
}

variable "max_message_size" {
  description = "Maximum message size in bytes. Range: 1024–262144 (1 KB to 256 KB)."
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "max_message_size must be between 1024 and 262144 bytes."
  }
}

variable "receive_wait_time_seconds" {
  description = "Duration (in seconds) for long-polling. 0 disables long polling. Range: 0–20."
  type        = number
  default     = 0

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "receive_wait_time_seconds must be between 0 and 20."
  }
}

variable "tags" {
  description = "Map of tags to apply to the SQS queue."
  type        = map(string)
  default     = {}
}
