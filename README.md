# Terraform workspace repository for aws-identity-center

<!-- LOGO -->
<a href="https://nuvibit.com">
    <img src="https://nuvibit.com/images/logo/logo-nuvibit-square.png" alt="nuvibit logo" title="nuvibit" align="right" width="100" />
</a>

<!-- SHIELDS -->
[![Maintained by nuvibit.com][nuvibit-shield]][nuvibit-url]
[![Terraform Version][terraform-version-shield]][terraform-version-url]

<!-- DESCRIPTION -->
[Terraform workspace][terraform-workspace-url] repository to provision and manage AWS IAM Identity Center

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- terraform (>= 1.3.0)

- aws (~> 5.33)

## Providers

The following providers are used by this module:

- aws (~> 5.33)

## Modules

The following Modules are called:

### ntc\_identity\_center

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-identity-center

Version: 1.0.4

### ntc\_parameters\_reader

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader

Version: 1.1.2

### ntc\_parameters\_writer

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer

Version: 1.1.3

## Resources

The following resources are used by this module:

- [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) (data source)
- [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data source)

## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### account\_id

Description: The current account id

### default\_region

Description: The default region name

### ntc\_parameters

Description: Map of all ntc parameters
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors
This repository is maintained by [Nuvibit][nuvibit-url] with help from [these amazing contributors][contributors-url]

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright &copy; 2023 Nuvibit AG</p>

<!-- MARKDOWN LINKS & IMAGES -->
[nuvibit-shield]: https://img.shields.io/badge/maintained%20by-nuvibit.com-%235849a6.svg?style=flat&color=1c83ba
[nuvibit-url]: https://nuvibit.com
[terraform-version-shield]: https://img.shields.io/badge/terraform-%3E%3D1.2-blue.svg?style=flat&color=blueviolet
[terraform-version-url]: https://developer.hashicorp.com/terraform/language/v1.2.x/upgrade-guides
[contributors-url]: https://github.com/nuvibit-terraform-collection/aws-c2-identity-center/graphs/contributors
[terraform-workspace-url]: https://app.terraform.io/app/nuvibit-c2/workspaces/aws-c2-identity-center