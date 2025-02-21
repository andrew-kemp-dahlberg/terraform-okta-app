# variables.tf
variable "client_id" {
  description = "Okta Client ID"
  type        = string
  sensitive   = true
}

variable "org_name" {
  description = "Okta org name ie. company"
  type        = string
}

variable "base_url" {
  description = "Okta Base URL ie. okta.com"
  type        = string
}

variable "private_key_id" {
  description = "Okta Oauth private key id"
  type        = string
  sensitive   = true
}

variable "private_key" {
  description = "Okta Oauth private key"
  type        = string
  sensitive   = true
}

variable "label" {
  description = "Application label"
  type        = string
}

variable "logo" {
  description = "Logo URL"
  type        = string
}

variable "sso_url" {
  description = "SSO URL"
  type        = string
}

variable "audience" {
  description = "Audience URI"
  type        = string
}
variable "recipient" {
  description = "Recipient URL"
  type        = string
  default     = var.sso_url
}
variable "destination" {
  description = "Destination URL"
  type        = string
  default     = var.sso_url
}

variable "accessibility_error_redirect_url" {
  description = "Custom error page URL"
  type        = string
  default     = null
}

variable "accessibility_login_redirect_url" {
  description = "Custom login redirect URL"
  type        = string
  default     = null
}

variable "accessibility_self_service" {
  description = "Enable self-service"
  type        = bool
  default     = false
}

variable "acs_endpoints" {
  description = "List of ACS endpoints"
  type        = list(string)
  default     = []
}

variable "admin_note" {
  description = "Administrator notes"
  type        = string
  default     = null
}

variable "assertion_signed" {
  description = "Whether SAML assertions are signed"
  type        = bool
  default     = true
}

variable "authn_context_class_ref" {
  description = "Authentication context class reference"
  type        = string
  default     = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
}

variable "auto_submit_toolbar" {
  description = "Display auto-submit toolbar"
  type        = bool
  default     = false
}

variable "default_relay_state" {
  description = "Default relay state"
  type        = string
  default     = null
}

variable "digest_algorithm" {
  description = "Digest algorithm"
  type        = string
  default     = "SHA256"
}

variable "enduser_note" {
  description = "End user notes"
  type        = string
  default     = null
}

variable "hide_ios" {
  description = "Hide on iOS"
  type        = bool
  default     = false
}

variable "hide_web" {
  description = "Hide on web"
  type        = bool
  default     = false
}

variable "honor_force_authn" {
  description = "Honor ForceAuthn"
  type        = bool
  default     = true
}

variable "idp_issuer" {
  description = "IdP issuer URL"
  type        = string
  default     = "http://www.okta.com/$${org.externalKey}"
}

variable "implicit_assignment" {
  description = "Implicit assignment"
  type        = bool
  default     = false
}

variable "inline_hook_id" {
  description = "Inline hook ID"
  type        = string
  default     = null
}

variable "key_name" {
  description = "Key name"
  type        = string
  default     = null
}

variable "key_years_valid" {
  description = "Key validity years"
  type        = number
  default     = null
}

variable "preconfigured_app" {
  description = "Preconfigured application ID"
  type        = string
  default     = null
}



variable "request_compressed" {
  description = "Request compressed"
  type        = bool
  default     = null
}

variable "response_signed" {
  description = "Response signed"
  type        = bool
  default     = true
}

variable "saml_signed_request_enabled" {
  description = "SAML signed request enabled"
  type        = bool
  default     = false
}

variable "saml_version" {
  description = "SAML version"
  type        = string
  default     = "2.0"
}

variable "signature_algorithm" {
  description = "Signature algorithm"
  type        = string
  default     = "RSA_SHA256"
}

variable "single_logout_certificate" {
  description = "Single logout certificate"
  type        = string
  default     = null
}

variable "single_logout_issuer" {
  description = "Single logout issuer"
  type        = string
  default     = null
}

variable "single_logout_url" {
  description = "Single logout URL"
  type        = string
  default     = null
}

variable "sp_issuer" {
  description = "SP issuer"
  type        = string
  default     = null
}

variable "status" {
  description = "Application status"
  type        = string
  default     = "ACTIVE"
}

variable "subject_name_id_format" {
  description = "Subject name ID format"
  type        = string
  default     = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
}

variable "subject_name_id_template" {
  description = "Subject name ID template"
  type        = string
  default     = "$${user.userName}"
}

variable "user_name_template" {
  description = "Username template"
  type        = string
  default     = "$${source.login}"
}

variable "user_name_template_push_status" {
  description = "Username template push status"
  type        = string
  default     = null
}

variable "user_name_template_suffix" {
  description = "Username template suffix"
  type        = string
  default     = null
}

variable "user_name_template_type" {
  description = "Username template type"
  type        = string
  default     = "BUILT_IN"
}

variable "attribute_statements" {
  description = "List of Objects containing, type (user or group), name, formation, filter_value for group attributes that is a regex, "
  type = list(object({
    type         = string
    name         = string
    name_format  = optional(string, "unspecified")
    filter_value = optional(string, null)
    values       = optional(list(string), [])
  }))
  default = null

  validation {
    condition = var.attribute_statements == null ? true : alltrue([
      for attr in var.attribute_statements :
      (attr.type == "user" && attr.values != null && length(attr.values) > 0 && attr.filter_value == null) ||
      (attr.type == "group" && attr.filter_value != null && (attr.values == null || length(attr.values) == 0))
    ])
    error_message = <<EOT
Invalid configuration:
- attribute_statements with "user" types must have non-empty "values" and no filter_value
- attribute_statements with "group"types must have "filter_value" and no "values"
EOT
  }

  validation {
    condition = var.attribute_statements == null ? true : alltrue([
      for attr in var.attribute_statements :
      contains(["user", "group"], attr.type) &&
      contains(["basic", "uri reference", "unspecified"], attr.name_format)
    ])
    error_message = <<EOT
Validation errors:
- Each object in attribute_statements Type must be 'user' or 'group'
- attribute_statements name_format must be 'basic', 'uri reference', or 'unspecified'
EOT
  }

}

variable "signon_policy_rules" {
  type = list(object({
    # Required attributes
    name        = string
    constraints = list(string)

    # Optional attributes with proper null defaults
    access                      = optional(string)
    custom_expression           = optional(string)
    device_assurances_included  = optional(list(string))
    device_is_managed           = optional(bool)
    device_is_registered        = optional(bool)
    factor_mode                 = optional(string, "2FA")
    groups_excluded             = optional(list(string))
    groups_included             = optional(list(string))
    inactivity_period           = optional(string)
    network_connection          = optional(string, "ANYWHERE")
    network_excludes            = optional(list(string))
    network_includes            = optional(list(string))
    re_authentication_frequency = optional(string, "PT43800H")
    risk_score                  = optional(string)
    status                      = optional(string)
    type                        = optional(string)
    user_types_excluded         = optional(list(string))
    user_types_included         = optional(list(string))
    users_excluded              = optional(list(string))
    users_included              = optional(list(string))

    # Platform includes
    platform_includes = optional(list(object({
      os_expression = optional(string)
      os_type       = string
      type          = string
    })), [])
  }))

  default = [
    { # Mac and Windows Devices
      name            = "Mac and Windows Devices"
      constraints     = ["{\"possession\":{\"required\":true,\"hardwareProtection\":\"REQUIRED\",\"userPresence\":\"REQUIRED\",\"userVerification\":\"REQUIRED\"}}"]
      groups_included = ["00g11p7vbcqI3vXBt2p8"]
      platform_includes = [
        { os_type = "MACOS", type = "DESKTOP" },
        { os_type = "WINDOWS", type = "DESKTOP" }
      ]
    },
    { # Android and iOS devices
      name                       = "Android and iOS devices"
      constraints                = ["{\"knowledge\":{\"required\":false},\"possession\":{\"authenticationMethods\":[{\"key\":\"okta_verify\",\"method\":\"signed_nonce\"}],\"required\":false,\"hardwareProtection\":\"REQUIRED\",\"phishingResistant\":\"REQUIRED\",\"userPresence\":\"REQUIRED\"}}"]
      device_assurances_included = ["daeya6jtpsaMCFM4h2p7", "daeya6odzfBCEPM8F2p7"]
      device_is_managed          = false
      device_is_registered       = false
      groups_included            = ["00g11p7vbcqI3vXBt2p8"]
    },
    { # Unsupported Devices
      name        = "Unsupported Devices"
      constraints = ["{\"knowledge\":{\"reauthenticateIn\":\"PT43800H\",\"types\":[\"password\"],\"required\":true},\"possession\":{\"required\":true,\"hardwareProtection\":\"REQUIRED\",\"userPresence\":\"REQUIRED\"}}"]
      platform_includes = [
        { os_type = "CHROMEOS", type = "DESKTOP" },
        { os_type = "OTHER", type = "DESKTOP" },
        { os_type = "OTHER", type = "MOBILE" }
      ]
    }
  ]
}

variable "assignments" {
  description = "Creates assignments based on groups that can then be assigned to users."
  type = list(object({
    role = string
    profile = map
  }))
  default = [ {
    role = "assignement"
    profile = {}
  } ]
}

variable "admin_assignment" {
  description = "Creates the role specifically for. Just enter the map for the assignment for the assignment"
  type = map
  default = {}
}

  
