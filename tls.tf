provider "acme" {
  # You cannot attach a let's encrypt staging cert to an app in Azure, you get a BadRequest 04038 error: Expired certificate is not allowed.
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "reg_private_key" {
  count     = local.create_dns ? 1 : 0
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  count           = local.create_dns ? 1 : 0
  account_key_pem = tls_private_key.reg_private_key.0.private_key_pem
  email_address   = var.custom_dns.lets_encrypt_contact_email
}
