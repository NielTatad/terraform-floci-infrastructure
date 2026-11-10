locals {
  # Build the full list of attribute definitions. The range key attribute is
  # only included when a range key name is provided.
  attribute_definitions = concat(
    [{ name = var.hash_key, type = var.hash_key_type }],
    var.range_key != null ? [{ name = var.range_key, type = var.range_key_type }] : []
  )
}

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  # Conditionally set provisioned capacity — only relevant for PROVISIONED mode.
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  dynamic "attribute" {
    for_each = local.attribute_definitions
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  tags = var.tags
}
