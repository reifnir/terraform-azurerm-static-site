# Until/unless Terraform provides a simpler `path.temp` capability, this is a workaround for creating
#   A temporary directory
#   That does not get cleaned-up after multiple jobs (boo)
#   With no possibility of file collissions for previous builds
# See: https://github.com/hashicorp/terraform/issues/21308#issuecomment-721478826
locals {
  temp_dir              = "${path.root}/.terraform/tmp"
  temp_package_zip_path = "${local.temp_dir}/package.zip"


  proxies_json_content = templatefile("${path.module}/templates/proxies.json", {
    storage_account_static_website_url = azurerm_storage_account.static_site.primary_web_endpoint
  })
}

data "archive_file" "azure_function_package" {
  type = "zip"
  source {
    content  = local.proxies_json_content
    filename = "proxies.json"
  }

  output_path = local.temp_package_zip_path
}

resource "azurerm_storage_blob" "function" {
  name                   = "fn-${data.archive_file.azure_function_package.output_md5}.zip"
  storage_account_name   = azurerm_storage_account.static_site.name
  storage_container_name = azurerm_storage_container.function_packages.name
  type                   = "Block"
  metadata = {
    sha1   = data.archive_file.azure_function_package.output_sha
    sha256 = data.archive_file.azure_function_package.output_base64sha256
    md5    = data.archive_file.azure_function_package.output_md5
  }
  source = data.archive_file.azure_function_package.output_path
}
