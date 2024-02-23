# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # users and groups with global permissions for all accounts
  global_sso_permissions = {
    admin_groups = [
      "aws-c2-admin"
    ]
    billing_groups = [
      "aws-c2-billing"
    ]
    support_groups = [
      "aws-c2-support"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC IDENTITY CENTER - SSO
# ---------------------------------------------------------------------------------------------------------------------
module "identity_center" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-identity-center?ref=1.0.2"

  is_automatic_provisioning_enabled = false

  # users that should be manually provisioned in IAM Identity Center via Terraform. Automatic provisioning must be disabled.
  # Users will not be synced back to external identitiy provider!
  manual_provisioning_sso_users = jsondecode(file("${path.module}/sso_users.json"))

  # groups that should be manually provisioned in IAM Identity Center via Terraform. Automatic provisioning must be disabled.
  # Groups will not be synced back to external identitiy provider!
  manual_provisioning_sso_groups = jsondecode(file("${path.module}/sso_groups.json"))

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
          # e.g. combine global sso permissions with sso permissions from account map
          groups : concat(local.global_sso_permissions.admin_groups, try(account.customer_values.sso_admin_groups, []))
          # alternatively groups can also be dynamically associated via predefined naming
          # groups : ["sg-aws-admin-${account.account_id}"]
        },
        {
          permission_set_name : "Billing+ViewOnlyAccess"
          # e.g. combine global sso permissions with sso permissions from account map
          groups : concat(local.global_sso_permissions.billing_groups, try(account.customer_values.sso_billing_groups, []))
          # alternatively groups can also be dynamically associated via predefined naming
          # groups : ["sg-aws-billing-${account.account_id}"]
        },
        {
          permission_set_name : "SupportUser+ReadOnlyAccess"
          # e.g. combine global sso permissions with sso permissions from account map
          groups : concat(local.global_sso_permissions.support_groups, try(account.customer_values.sso_support_groups, []))
          # alternatively groups can also be dynamically associated via predefined naming
          # groups : ["sg-aws-support-${account.account_id}"]
        },
        {
          permission_set_name : "AdministratorAccess"
          groups : [
            "aws-c2-alles-kaputt"
          ]
        } if account.account_name = "aws-c2-security"
      ]
    }
  ]

  providers = {
    aws = aws.euc1
  }
}
