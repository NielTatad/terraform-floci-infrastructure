resource "aws_sqs_queue" "this" {
  name       = var.queue_name
  fifo_queue = var.fifo_queue

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  tags = var.tags
}
