# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC IDENTITY CENTER - SSO
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_identity_center" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-identity-center?ref=1.0.4"

  # SCIM automatic provisioning is the recommended way to provision users and groups in IAM Identity Center.
  # Users and Groups will be synced from the external identity provider to IAM Identity Center.
  # WARNING: 'account_assignments' can only be used for users and groups that are successfully provisioned via SCIM.
  is_automatic_provisioning_enabled = true

  # users that should be manually provisioned in IAM Identity Center via Terraform. Automatic provisioning must be disabled.
  # Users will not be synced back to external identitiy provider!
  # manual_provisioning_sso_users = jsondecode(file("${path.module}/sso_users.json"))

  # groups that should be manually provisioned in IAM Identity Center via Terraform. Automatic provisioning must be disabled.
  # Groups will not be synced back to external identitiy provider!
  # manual_provisioning_sso_groups = jsondecode(file("${path.module}/sso_groups.json"))

  # permission sets can be a combination of aws and customer managed policies
  # https://docs.aws.amazon.com/singlesignon/latest/userguide/permissionsetcustom.html
  permission_sets = [
    {
      name : "AdministratorAccess"
      description : "This permission set grants administrator access"
      session_duration : 2
      inline_policy_json : ""
      managed_policies : [
        {
          managed_by : "aws"
          policy_name : "AdministratorAccess"
          policy_path : "/"
        }
      ]
      boundary_policy : {}
    },
    {
      name : "Billing+ViewOnlyAccess"
      description : "This permission set grants billing and read-only access"
      session_duration : 10
      inline_policy_json : ""
      managed_policies : [
        {
          managed_by : "aws"
          policy_name : "Billing"
          policy_path : "/job-function/"
        },
        {
          managed_by : "aws"
          policy_name : "ViewOnlyAccess"
          policy_path : "/job-function/"
        }
      ]
      boundary_policy : {}
    },
    {
      name : "SupportUser+ReadOnlyAccess"
      description : "This permission set grants support and read-only access"
      session_duration : 10
      inline_policy_json : ""
      managed_policies : [
        {
          managed_by : "aws"
          policy_name : "SupportUser"
          policy_path : "/job-function/"
        },
        {
          managed_by : "aws"
          policy_name : "ReadOnlyAccess"
          policy_path : "/"
        }
      ]
      boundary_policy : {}
    }
  ]

  account_assignments = [
    for account in module.ntc_parameters_reader.account_map :
    {
      account_name = account.account_name
      account_id   = account.account_id
      permissions = [
        {
          permission_set_name : "AdministratorAccess"
          groups : ["aws-c2-admins"]
        },
        {
          permission_set_name : "Billing+ViewOnlyAccess"
          groups : ["aws-c2-finops"]
        },
        {
          permission_set_name : "SupportUser+ReadOnlyAccess"
          groups : ["aws-c2-devops"]
        }
      ]
    }
    # remove SSO permission if account is marked for decommissioning
    if try(account.account_tags["AccountDecommission"], false) == false
  ]

  providers = {
    aws = aws.euc1
  }
}