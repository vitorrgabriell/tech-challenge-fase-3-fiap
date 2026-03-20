resource "aws_sqs_queue" "events" {
  name = "${var.project_name}-events"

  tags = {
    Name        = "${var.project_name}-events"
    Environment = var.environment
    Project     = "togglemaster"
  }
}
