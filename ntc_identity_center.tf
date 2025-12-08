# =====================================================================================================================
# NTC IDENTITY CENTER - CENTRALIZED IDENTITY AND ACCESS MANAGEMENT
# =====================================================================================================================
# NTC Identity Center automates the deployment and management of AWS IAM Identity Center (formerly AWS SSO),
# providing centralized identity and access management across your entire AWS organization.
#
# PREREQUISITES - MANUAL SETUP REQUIRED:
# --------------------------------------
# ⚠️  AWS IAM Identity Center must be enabled and configured manually BEFORE using this module
#
# Required manual steps:
#   1. Enable IAM Identity Center in AWS Console (Management Account)
#   2. Select home region (cannot be changed later without redeployment)
#   3. Choose and configure identity source (see options below)
#   4. Configure identity provider integration (if using external IdP)
#   5. Set up user/group synchronization (optional but recommended)
#
# For detailed step-by-step instructions, see:
# https://docs.nuvibit.com/ntc-building-blocks/management/ntc-identity-center/prerequisites
#
# IDENTITY SOURCE OPTIONS:
# ------------------------
# Choose ONE of the following identity source options:
#
# Option A: Identity Center Store (Internal) - AWS-Native Identity Management
#   • Users and groups stored directly in IAM Identity Center
#   • Best for: Small orgs, testing, proof-of-concept
#   • Configuration: Use 'manual_provisioning_sso_users' and 'manual_provisioning_sso_groups'
#   • No external dependencies required
#
# Option B: External Identity Provider (RECOMMENDED) - SAML 2.0 Integration
#   • Integrate with Microsoft Entra ID (Azure AD), Okta, or other SAML 2.0 providers
#   • Best for: Organizations with existing identity infrastructure
#   • Benefits: Centralized identity, existing MFA, simplified lifecycle management
#   • Configuration: Enable SCIM sync for automatic user/group provisioning
#
# Option C: Active Directory - Hybrid Identity
#   • Connect to on-premises Microsoft Active Directory via AWS Directory Service
#   • Best for: Organizations with existing AD infrastructure
#   • Requirements: AWS Managed Microsoft AD or AD Connector, network connectivity
#   • Configuration: Manual provisioning or SCIM (depending on setup)
#
# PROVISIONING MODES:
# -------------------
# Choose ONE of the following provisioning modes:
#
# Mode 1: SCIM Automatic Provisioning (RECOMMENDED for External Identity Providers)
#   • Users and groups automatically synchronized from identity provider
#   • Real-time updates when users/groups change in IdP (synchronization delay may apply)
#   • Automatic lifecycle management (onboarding/offboarding)
#   • Set: is_automatic_provisioning_enabled = true
#   • Supported by: Microsoft Entra ID, Okta, PingIdentity, OneLogin, Google Workspace
#
# Mode 2: Manual Provisioning (Required for Identity Center Store and some AD setups)
#   • Users and groups defined in Terraform configuration
#   • Manual updates required for changes
#   • Users/groups NOT synced back to external identity provider
#   • Set: is_automatic_provisioning_enabled = false
#   • Use: 'manual_provisioning_sso_users' and 'manual_provisioning_sso_groups'
#
# PERMISSION SETS:
# ----------------
# Permission Sets define what actions users can perform in AWS accounts
# They can combine multiple policy types for granular access control:
#
# 1. AWS Managed Policies (Recommended Starting Point)
#    • Pre-defined policies maintained by AWS
#    • Examples: AdministratorAccess, ReadOnlyAccess, Billing, SupportUser
#    • No additional configuration required in member accounts
#
# 2. Inline Policies (For Additional Permissions)
#    • Custom policies embedded directly in the permission set
#    • Automatically deployed to all accounts
#    • Good for adding missing permissions to AWS managed policies
#
# 3. Customer Managed Policies (For Organization-Specific Requirements)
#    • Custom IAM policies you create and maintain
#    • ⚠️  Must be created manually in EACH AWS account before assignment
#    • Use only when AWS managed + inline policies are insufficient
#
# 4. Permission Boundaries (For Maximum Permission Limits)
#    • Define maximum permissions regardless of other policies
#    • Act as security guardrails
#    • Can use AWS managed policies (no manual creation needed) or customer managed policies
#    • ⚠️  Customer managed boundaries must be created manually in EACH AWS account before assignment
#
# For detailed permission set guidance, see:
# https://docs.nuvibit.com/ntc-building-blocks/management/ntc-identity-center/permission-sets
#
# ACCOUNT ASSIGNMENTS:
# --------------------
# Account assignments map users/groups to AWS accounts with specific permission sets
# Two approaches available:
#
# Approach A: Dynamic Assignment (RECOMMENDED) - Using Account Factory Account Map
#   • Automatically assigns permissions based on account metadata
#   • Scales effortlessly as accounts are added/removed
#   • Consistent access patterns across account lifecycle
#   • Example: All production accounts get same permission sets automatically
#   • Implementation: Loop over 'module.ntc_parameters_reader.account_map' stored in NTC Parameters
#
# Approach B: Static Assignment - Individual Account Configuration
#   • Manually define each account and its permissions
#   • Full control over each assignment
#   • More verbose configuration
#   • Requires manual updates when accounts change
#
# BEST PRACTICES:
# ---------------
# ✅ Use SCIM sync with external identity provider for automated lifecycle management
# ✅ Start with AWS managed policies, extend with inline policies as needed
# ✅ Use dynamic assignments based on Account Factory account map
# ✅ Limit session duration to minimum necessary
# ✅ Assign permissions to groups, not individual users
# ✅ Apply principle of least privilege
# ✅ Review and audit permissions regularly
# ✅ Document custom permission sets and their purpose
#
# ❌ Avoid customer managed policies unless absolutely necessary (maintenance overhead)
# ❌ Don't grant AdministratorAccess broadly - use role-specific permissions
# ❌ Don't assign permissions directly to users - use groups instead
# =====================================================================================================================

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC IDENTITY CENTER - SSO CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_identity_center" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-identity-center?ref=1.0.4"

  # ===================================================================================================================
  # PROVISIONING MODE CONFIGURATION
  # ===================================================================================================================
  # Choose automatic (SCIM) or manual provisioning based on your identity source
  #
  # SCIM Automatic Provisioning (RECOMMENDED for External Identity Providers):
  #   • Users and groups automatically synced from identity provider (Entra ID, Okta, etc.)
  #   • Real-time updates when users/groups change (synchronization delay may apply)
  #   • Automatic lifecycle management
  #   • Set to TRUE when using external identity provider with SCIM enabled
  #
  # Manual Provisioning (Required for Identity Center Store):
  #   • Users and groups defined in Terraform configuration files
  #   • Manual updates required for changes
  #   • Set to FALSE and use manual_provisioning_sso_users/groups below
  #
  # ⚠️  IMPORTANT: Account assignments can only reference users/groups that exist in Identity Center
  #     • Users/groups must be synced via SCIM or provisioned manually BEFORE assignment
  #     • Deployment will FAIL if referenced users/groups don't exist yet
  #     • SCIM synchronization delay may apply (up to 40 minutes for Microsoft Entra ID)
  #     • Verify users/groups are synced in Identity Center before running Terraform
  # ===================================================================================================================
  is_automatic_provisioning_enabled = true

  # ===================================================================================================================
  # MANUAL PROVISIONING (Only when 'is_automatic_provisioning_enabled' = false)
  # ===================================================================================================================
  # Define users and groups directly in Terraform configuration
  #
  # Use Case: Identity Center Store as identity source, or AD without SCIM
  # Note: Users and groups will NOT be synced back to external identity provider
  #
  # Example 'sso_users.json' format:
  # [
  #   {
  #     "user_name": "john.doe@example.com",
  #     "first_name": "John",
  #     "last_name": "Doe",
  #     "email": "john.doe@example.com",
  #   }
  # ]
  #
  # Example 'sso_groups.json' format:
  # [
  #   {
  #     "group_name": "aws-admins",
  #     "group_description": "AWS Administrators with full access",
  #     "group_member_user_names": ["john.doe@example.com"]
  #   }
  # ]
  # ===================================================================================================================
  # manual_provisioning_sso_users = jsondecode(file("${path.module}/sso_users.json"))
  # manual_provisioning_sso_groups = jsondecode(file("${path.module}/sso_groups.json"))

  # ===================================================================================================================
  # PERMISSION SETS - DEFINE WHAT USERS CAN DO
  # ===================================================================================================================
  # Permission Sets are collections of policies that grant access to AWS resources
  # They can combine multiple policy types for fine-grained access control
  #
  # Policy Types Available:
  #   1. AWS Managed Policies: Pre-built policies maintained by AWS (recommended starting point)
  #   2. Inline Policies: Custom policies embedded in permission set (auto-deployed)
  #   3. Customer Managed Policies: Custom IAM policies (must exist in all accounts before assignment)
  #   4. Permission Boundaries: Can use AWS managed (no setup needed) or customer managed policies (must exist in all accounts before assignment)
  #
  # Best Practice: Start with AWS managed policies, extend with inline policies as needed
  #
  # For comprehensive permission set guidance and examples, see:
  # https://docs.nuvibit.com/ntc-building-blocks/management/ntc-identity-center/permission-sets
  # ===================================================================================================================
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

  # ===================================================================================================================
  # ACCOUNT ASSIGNMENTS - MAP USERS/GROUPS TO AWS ACCOUNTS
  # ===================================================================================================================
  # Account assignments grant users/groups access to specific AWS accounts with defined permission sets
  #
  # Two approaches available:
  #
  # APPROACH A: DYNAMIC ASSIGNMENT (RECOMMENDED) - Using Account Factory Account Map
  # ---------------------------------------------------------------------------------
  # Automatically assigns permissions based on account metadata from NTC Account Factory
  #
  # Benefits:
  #   ✅ Scales automatically as accounts are added/removed
  #   ✅ Consistent access patterns across all accounts
  #   ✅ Reduces configuration duplication
  #   ✅ Enables account-specific permissions via metadata
  #   ✅ Automatic cleanup when accounts are decommissioned
  #
  # How it works:
  #   1. NTC Account Factory maintains comprehensive account inventory (account_map)
  #   2. Account map is shared via NTC Parameters
  #   3. Loop over account_map to create assignments dynamically
  #   4. Filter accounts based on tags, OU path, or custom attributes
  #
  # Example use cases:
  #   • Grant admin access to all production accounts
  #   • Assign billing access to all accounts automatically
  #   • Provide developers access only to dev/test accounts
  #   • Combine global permissions with account-specific permissions
  #
  # Implementation below uses dynamic assignment with:
  #   • Global permissions (all accounts get same groups)
  #   • Account-specific permissions (via account metadata)
  #   • Automatic decommission filtering
  #
  # APPROACH B: STATIC ASSIGNMENT - Individual Account Configuration
  # -----------------------------------------------------------------
  # Manually define each account and its permission assignments
  #
  # Example static configuration:
  # account_assignments = [
  #   {
  #     account_name = "production-account"
  #     account_id   = "111111111111"
  #     permissions = [
  #       {
  #         permission_set_name = "AdministratorAccess"
  #         groups = ["prod-admins"]
  #         users  = []
  #       }
  #     ]
  #   },
  #   {
  #     account_name = "development-account"
  #     account_id   = "222222222222"
  #     permissions = [
  #       {
  #         permission_set_name = "PowerUserAccess"
  #         groups = ["developers"]
  #         users  = []
  #       }
  #     ]
  #   }
  # ]
  #
  # Use static assignments only when:
  #   • You have a small number of accounts (< 10)
  #   • Permissions vary significantly per account
  #   • You want explicit control over each assignment
  # ===================================================================================================================
  account_assignments = [
    # Dynamic assignment: Loop over all accounts from Account Factory account map
    for account in module.ntc_parameters_reader.account_map :
    {
      account_name = account.account_name
      account_id   = account.account_id
      permissions = [
        {
          permission_set_name : "AdministratorAccess"
          # Global permission: All accounts get aws-c2-admins group
          # Can be extended with account-specific groups from account metadata
          groups : ["aws-c2-admins"]
          # Example combining global + account-specific permissions:
          # groups : concat(["aws-c2-admins"], try(account.customer_values.sso_admin_groups, []))
        },
        {
          permission_set_name : "Billing+ViewOnlyAccess"
          groups : ["aws-c2-finops"]
          # Example account-specific permissions only:
          # groups : try(account.customer_values.sso_billing_groups, [])
        },
        {
          permission_set_name : "SupportUser+ReadOnlyAccess"
          groups : ["aws-c2-devops"]
        }
      ]
    }
    # Filter condition: Exclude accounts marked for decommissioning
    # This automatically removes SSO access when accounts are scheduled for deletion
    if try(account.account_tags["AccountDecommission"], false) == false
    
    # Additional filter examples:
    # Only production accounts: if contains(account.ou_path, "/prod")
    # Only specific OU: if account.ou_path == "/root/workloads/prod"
    # Only active accounts: if account.status == "ACTIVE"
  ]

  providers = {
    aws = aws.euc1
  }
}

# =====================================================================================================================
# ADVANCED CONFIGURATION EXAMPLES
# =====================================================================================================================
# The examples below demonstrate advanced Identity Center configurations
# Uncomment and adapt as needed for your organization
# =====================================================================================================================

# ---------------------------------------------------------------------------------------------------------------------
# EXAMPLE: Account-Specific Permissions from Account Metadata
# ---------------------------------------------------------------------------------------------------------------------
# This example shows how to use account metadata from Account Factory to assign permissions dynamically
# Store SSO group names in the account's custom_values field during account creation
#
# In Account Factory account map:
# "customer_values": {
#   "sso_admin_groups": ["app1-admins"],
#   "sso_dev_groups": ["app1-developers"],
#   "sso_support_groups": ["app1-support"]
# }
#
# locals {
#   global_permissions = {
#     admin_groups   = ["platform-admins"]
#     billing_groups = ["platform-finops"]
#     support_groups = ["platform-support"]
#   }
# }
#
# account_assignments = [
#   for account in module.ntc_parameters_reader.account_map :
#   {
#     account_name = account.account_name
#     account_id   = account.account_id
#     permissions = [
#       {
#         permission_set_name = "AdministratorAccess"
#         # Combine global admins with account-specific admin groups
#         groups = concat(
#           local.global_permissions.admin_groups,
#           try(account.customer_values.sso_admin_groups, [])
#         )
#       }
#     ]
#   }
# ]
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# EXAMPLE: OU-Based Permission Assignment
# ---------------------------------------------------------------------------------------------------------------------
# Assign different permissions based on the account's organizational unit
#
# account_assignments = concat(
#   # Production accounts: Admin + Read-only access
#   [
#     for account in module.ntc_parameters_reader.account_map :
#     {
#       account_name = account.account_name
#       account_id   = account.account_id
#       permissions = [
#         {
#           permission_set_name = "AdministratorAccess"
#           groups = ["prod-admins"]
#         },
#         {
#           permission_set_name = "ReadOnlyAccess"
#           groups = ["all-developers"]
#         }
#       ]
#     }
#     if contains(account.ou_path, "/production")
#   ],
#   # Development accounts: Power user access
#   [
#     for account in module.ntc_parameters_reader.account_map :
#     {
#       account_name = account.account_name
#       account_id   = account.account_id
#       permissions = [
#         {
#           permission_set_name = "PowerUserAccess"
#           groups = ["developers"]
#         }
#       ]
#     }
#     if contains(account.ou_path, "/development")
#   ]
# )
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# EXAMPLE: Permission Set with Inline Policy
# ---------------------------------------------------------------------------------------------------------------------
# Extend AWS managed policies with custom inline policies
#
# permission_sets = [
#   {
#     name = "S3ReadWriteAccess"
#     description = "Read-only base access plus S3 bucket management"
#     session_duration = 4
#     
#     # AWS Managed Policy for baseline permissions
#     managed_policies = [
#       {
#         managed_by  = "aws"
#         policy_name = "ReadOnlyAccess"
#         policy_path = "/"
#       }
#     ]
#     
#     # Inline policy for additional S3 permissions
#     inline_policy_json = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Action = [
#             "s3:PutObject",
#             "s3:DeleteObject"
#           ]
#           Resource = "arn:aws:s3:::my-bucket/*"
#         }
#       ]
#     })
#     
#     boundary_policy = {}
#   }
# ]
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# EXAMPLE: Permission Set with Customer Managed Policy and Boundary
# ---------------------------------------------------------------------------------------------------------------------
# Use custom IAM policies and permission boundaries for advanced access control
# ⚠️  Customer managed policies and boundaries must exist in ALL AWS accounts before assignment
#
# permission_sets = [
#   {
#     name = "RestrictedDeveloper"
#     description = "Developer access with strict boundaries"
#     session_duration = 4
#     
#     # Custom policy (must be created in all accounts)
#     managed_policies = [
#       {
#         managed_by  = "customer"
#         policy_name = "DeveloperPermissions"
#         policy_path = "/"
#       }
#     ]
#     
#     inline_policy_json = ""
#     
#     # Permission boundary (must be created in all accounts)
#     boundary_policy = {
#       managed_by  = "customer"
#       policy_name = "DeveloperBoundary"
#       policy_path = "/"
#     }
#   }
# ]
# ---------------------------------------------------------------------------------------------------------------------