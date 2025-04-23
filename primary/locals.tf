locals {
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.project_name}"
    }
  )
}
