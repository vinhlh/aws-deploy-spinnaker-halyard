locals {
  kms_alias = "alias/spinnaker/app"
  ssm_namespace = "/spinnaker/lite/"
}


data "template_file" "app_env" {
  template = "${file("../.env.production")}"
}
resource "aws_kms_key" "spinnaker" {
  description = "App"
}

resource "aws_kms_alias" "spinnaker" {
  name          = "${local.kms_alias}"
  target_key_id = "${aws_kms_key.spinnaker.key_id}"
}

resource "aws_ssm_parameter" "app" {
  count       = "${length(split("\n", data.template_file.app_env.rendered)) - 1}"
  name        = "${local.ssm_namespace}${element(split("=", element(split("\n", data.template_file.app_env.rendered), count.index)), 0)}"
  value       = "${element(split("=", element(split("\n", data.template_file.app_env.rendered), count.index)), 1)}"
  description = "Imported from .env.production"
  type        = "SecureString"
  key_id      = "${local.kms_alias}"
  overwrite   = true

  depends_on = ["aws_kms_alias.spinnaker"]
}


resource "aws_s3_bucket" "spinnaker" {
  bucket = "spinnaker.lite"

  tags = "${var.tags}"
}
