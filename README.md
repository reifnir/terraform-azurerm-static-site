# terraform-azurerm-static-site

[![LICENSE](https://img.shields.io/github/license/reifnir/terraform-azurerm-static-site)](https://github.com/reifnir/terraform-azurerm-static-site/blob/master/LICENSE)

This Terraform module stands up a static website and supports custom domain names and generates Let's Encrypt TLS certs. It currently only supports Azure DNS Zones, but I'll implement more DNS providers if someone requests it.

## Summary

Find the Terraform Module publicly hosted [here](https://registry.terraform.io/modules/reifnir/static-site/azurerm)!

- Hosts static resources in a Storage Account using the static website hosting capability

- Stands up an Azure Functions application to act as a reverse proxy over the Storage Account's static website

_If the `custom_dns` variable is populated..._

- Generates a Let's Encrypt TLS certificate with all of the domain names configured

- Creates DNS entries for the configured domains

- Binds those domain names and the Let's Encrypt certificate to the Azure Functions application

- Certificates are valid for 90 days. Applying Terraform again will renew the certificate if there are fewer than 30 days before it expires.

## Detail

It does this by first pushing all of the blob resources into a new storage account as a static website. This is an okay place to stop if you don't mind your resources being accessed with a domain like this: `https://sastaticsiteexammiahdsnu.z13.web.core.windows.net/`.

Because it is currently impossible to bind custom TLS certificates to an Azure Storage Account or CDN, a minimal Azure Functions application is created to act as a reverse proxy for the static site. There are zero functions in the entire Azure Functions application. The following is the entire contents of the Function:

```json
{
  "$schema": "http://json.schemastore.org/proxies",
  "proxies": {
    "files": {
      "matchCondition": {
        "route": "{*path}",
        "methods": ["GET"]
      },
      "backendUri": "${storage_account_static_website_url}{path}"
    }
  }
}
```

In order for the files hosted in the Storage account to return the correct `content-type`, we're using  to map the values from [jshttp/mime-db](https://github.com/jshttp/mime-db) via [this](https://registry.terraform.io/modules/reifnir/mime-map/null/latest) Terraform module.

These mappings can be replaced or added onto in the case that you have more exotic file types by passing that into the `custom_mime_mappings` variable.

## Usage example
 
 See examples [here](https://github.com/reifnir/terraform-azurerm-static-site/tree/main/examples)

### Basic example without custom DNS/TLS certificate...

```terraform
module "simple_example_static_site" {
  source                   = "../../"
  name                     = "some-unique-azure-functions-app-name"
  static_content_directory = "${path.root}/static-content"
  error_404_document       = "error_404.html"
  tags                     = { "ManagedBy" = "Terraform }
}
```

### Basic example with custom DNS/TLS certificate...

```terraform
module "custom_dns_static_site" {
  source                   = "../../"
  name                     = local.azure_function_name
  static_content_directory = "${path.root}/static-content"
  error_404_document       = "error_404.html"

  custom_dns = {
    # @ is interpreted as a naked domain. This would create the following FQDNs:
    #   - example.com
    #   - www.example.com
    #   - deeper.subdomain.example.com
    hostnames                  = ["@", "www", "deeper.subdomain"]
    dns_provider               = "azure"
    dns_zone_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns-zones/providers/Microsoft.Network/dnszones/example.com"
    lets_encrypt_contact_email = "you@example.com"
    
    # Because you don't want to save secrets in your Terraform code
    azure_client_id     = var.azure_client_id
    azure_client_secret = var.azure_client_secret
  }

  tags = { "ManagedBy" = "Terraform }
}
```

## Author

Created and maintained by Jim Andreasen.

[github.com/reifnir](https://github.com/reifnir)

[gitlab.com/jim.andreasen](https://gitlab.com/jim.andreasen)

jim.andreasen@reifnir.com

## License

MIT Licensed. See [LICENSE](https://github.com/reifnir/terraform-azurerm-static-site/blob/main/LICENSE) for full details.

<!-- regenerate TF docs using this: https://github.com/terraform-docs/terraform-docs -->
<!-- run from project root: docker run --rm -v "$(pwd):/terraform-docs" quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_acme"></a> [acme](#requirement\_acme) | 2.13.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_acme"></a> [acme](#provider\_acme) | 2.13.1 |
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.14.0 |
| <a name="provider_dns"></a> [dns](#provider\_dns) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_file_extensions"></a> [file\_extensions](#module\_file\_extensions) | reifnir/mime-map/null | n/a |

## Resources

| Name | Type |
|------|------|
| [acme_certificate.certificate](https://registry.terraform.io/providers/vancluever/acme/2.13.1/docs/resources/certificate) | resource |
| [acme_registration.reg](https://registry.terraform.io/providers/vancluever/acme/2.13.1/docs/resources/registration) | resource |
| [azurerm_app_service_certificate.custom_hostname](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_certificate) | resource |
| [azurerm_app_service_certificate_binding.custom_hostname](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_certificate_binding) | resource |
| [azurerm_app_service_custom_hostname_binding.static_site](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_custom_hostname_binding) | resource |
| [azurerm_dns_a_record.naked_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_cname_record.cnames_to_function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_txt_record.function_domain_verification](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_linux_function_app.static_site](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_resource_group.static_site](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.static_site](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.static_site](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_blob.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.static_files](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_container.function_packages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [local_file.proxies](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_password.pfx](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.storage_account_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.reg_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [archive_file.azure_function_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_dns_zone.custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/dns_zone) | data source |
| [azurerm_storage_account_sas.package](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account_sas) | data source |
| [dns_a_record_set.function](https://registry.terraform.io/providers/hashicorp/dns/latest/docs/data-sources/a_record_set) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_dns"></a> [custom\_dns](#input\_custom\_dns) | Information required to wire-up custom DNS for your static site. When setting hostnames, be sure to enter the full DNS. Note that the Azure client secret is necessary for completing ACME DNS verification when generating a Let's Encrypt TLS certificate. | <pre>object({<br>    dns_provider               = string<br>    dns_zone_id                = string<br>    hostnames                  = set(string)<br>    lets_encrypt_contact_email = string<br>    azure_client_id            = string<br>    azure_client_secret        = string<br>  })</pre> | `null` | no |
| <a name="input_custom_mime_mappings"></a> [custom\_mime\_mappings](#input\_custom\_mime\_mappings) | Add or replace content-type mappings by setting this value. Ex: `{ "text" = "text/plain", "new" = "text/derp" }` | `map(string)` | `null` | no |
| <a name="input_error_404_document"></a> [error\_404\_document](#input\_error\_404\_document) | The resource path to a custom webpage that should be used when a request is made for a resource that doesn't exist in the supplied directory of static content. Ex: 'error\_404.html' | `string` | `""` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. This value is case-sensitive. | `string` | `"index.html"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region in which resources will be located | `string` | `"eastus"` | no |
| <a name="input_name"></a> [name](#input\_name) | Slug is added to the name of most resources. This is also the name of the Azure Functions application and MUST be unique across all of Azure. | `string` | n/a | yes |
| <a name="input_static_content_directory"></a> [static\_content\_directory](#input\_static\_content\_directory) | This is the path to the directory containing static resources. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | <pre>{<br>  "ManagedBy": "Terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azure_function_default_url"></a> [azure\_function\_default\_url](#output\_azure\_function\_default\_url) | The Azure Functions application's default URL |
| <a name="output_custom_dns_domains"></a> [custom\_dns\_domains](#output\_custom\_dns\_domains) | List of any custom DNS domains that were created bound to the static site |
| <a name="output_storage_account_primary_web_endpoint"></a> [storage\_account\_primary\_web\_endpoint](#output\_storage\_account\_primary\_web\_endpoint) | The storage account's self-hosted static site URL |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Change Log

### 3.4.0

Released 2025-06-01

Fixed issue with newer versions of Terraform have been failing to apply due to the use of a (not really) sensitive value information being used in a for_each key:

> │ Error: Invalid for_each argument
> │ 
> │   on .terraform/modules/resume_andreasen_dev/dns.tf line 46, in resource "azurerm_dns_txt_record" "function_domain_verification":
> │   46:   for_each            = local.hostnames
> │     ├────────────────
> │     │ local.hostnames has a sensitive value
> │ 
> │ Sensitive values, or values derived from sensitive values, cannot be used
> │ as for_each arguments. If used, the sensitive value could be exposed as a
> │ resource instance key.


### 3.3.1

Released 2023-04-30

### 3.3.0

Released 2023-04-30

- Bumped ACME provider version to 2.13.1.

### 3.2.0

Released 2022-07-15

- `default_hostname` and `custom_domain_verification_id` weren't implemented in the `azurerm_linux_function_app` object until azurerm version 3.14.0. Now that they are, got rid of that `azurerm_function_app` data object that was creating so much noise each time plan was run.

### 3.1.0

Released 2022-07-04

- Fixed issue where static files weren't being updated when their content changed.

### 3.0.1

Released 2022-07-04

- Added changelog notes.

### 3.0.0

Released 2022-07-04

- Realized that the `azure_function_defualt_url` output was still misspelled and tried to correct it to `azure_function_default_url` before anyone used v2.0.0.

### 2.0.0

Released 2022-07-04

- When creating multiple objects, such as the DNS verification TXT records, switched from `count` to `for_each`. Using `count` can be buggy when items in a list are changed. If you're creating objects and their state index changes, Terraform will try to update both at once or remove/add at the same time leading to conflicts where you have to retry a number of times. Using `for_each` instead gives more stable state names. Ex: `module.custom_dns_static_site.azurerm_app_service_custom_hostname_binding.static_site["www"]` instead of `module.custom_dns_static_site.azurerm_app_service_custom_hostname_binding.static_site[0]`.
- Marked the module compatible with versions beyond `0.14`.
- Bumped the ACME provider used to generate Let's Encrypt certs from `2.4.0` to the current version, `2.9.0`.
- Now using azurerm Terraform provider version 3 and later.
- Moved away from deprecated objects `azurerm_function_app` and `azurerm_app_service_plan` resource for the newer `azurerm_linux_function_app` and `azurerm_service_plan`.
   - Unfortunately, there are still a couple of bugs in `azurerm_linux_function_app` in that some properties (`custom_domain_verification_id`, `default_hostname`) are not yet implemented. There are already a couple of MRs that are just awaiting responses from Hashicorp [here](https://github.com/hashicorp/terraform-provider-azurerm/issues/16263) and [here](https://github.com/hashicorp/terraform-provider-azurerm/issues/17444) (I did that one).
   - In order to use the newer resources, I needed to add a deprecated `azurerm_function_app` data reference as a workaround. This will be removed as soon as the missing functionality is released.
