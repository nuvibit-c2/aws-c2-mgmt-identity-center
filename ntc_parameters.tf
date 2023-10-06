locals {
  ntc_parameters_bucket_name = "aws-c2-ntc-parameters"
  ntc_parameters_writer_node = "identity-center"

  ntc_parameters_to_write = {}

  # by default existing node parameters will be merged with new parameters to avoid deleting parameters
  replace_parameters = true

  # map of parameters merged from all parameter nodes
  ntc_parameters = module.ntc_parameters_reader.all_parameters
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader?ref=1.0.0"

  bucket_name = local.ntc_parameters_bucket_name

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_writer" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer?ref=1.0.0"

  bucket_name     = local.ntc_parameters_bucket_name
  parameter_node  = local.ntc_parameters_writer_node
  node_parameters = local.ntc_parameters_to_write

  providers = {
    aws = aws.euc1
  }
}