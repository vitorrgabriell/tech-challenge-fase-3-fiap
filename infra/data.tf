# ──────────────────────────────────────────────
# AWS Academy LabRole
# Não podemos criar IAM Roles/Policies no Academy.
# Referenciamos a LabRole existente via data source.
# ──────────────────────────────────────────────

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_caller_identity" "current" {}
