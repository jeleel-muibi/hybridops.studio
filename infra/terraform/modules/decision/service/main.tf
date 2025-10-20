resource "local_file" "decision" {
  filename = var.output_path
  content  = jsonencode({
    chosen  = var.preferred,
    reason  = var.reason,
    at      = timestamp()
  })
}
