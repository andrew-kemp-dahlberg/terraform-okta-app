locals {

  profile             = [for role in var.roles : role.profile]
  app_group_names     = ["Not a department group"]
  push_group_names    = ["Not a department group"]
  mailing_group_names = ["Not a department group"]
  group_profile = [for p in local.profile : length(p) == 0 ?
    "No profile assigned" :
    replace(
      jsonencode(p),
      "/^{|}$/",
      ""
    )
  ]

  group_notes = [for p in local.profile : format(
    "Assigns the user to the %s with the following profile.\n%s\nGroup is managed by Terraform. Do not edit manually.",
    var.name,
    jsonencode(p)
  )]

  custom_attributes = [for index in range(length(var.roles)) : merge(
    { notes = local.group_notes[index] },
    { assignmentProfile = local.group_profile[index] },
    local.app_group_names != "" ? { applicationAssignments = local.app_group_names } : {},
    local.mailing_group_names != "" ? { mailingLists = local.mailing_group_names } : {},
    local.push_group_names != "" ? { pushGroups = local.push_group_names } : {}
  )]

}

resource "okta_group" "assignment_groups" {
  count                     = length(var.roles)
  name                      = "APP-ROLE-${upper(var.name)}-${upper(var.roles[count.index].name)}"
  description               = "Group assigns users to ${var.name} with the role of ${var.roles[count.index].name}"
  custom_profile_attributes = jsonencode(local.custom_attributes[count.index])
}


locals {
  // Condensed Admin Note         
  admin_note = {
    name = var.admin_note.saas_mgmt_name
    sso  = var.admin_note.sso_enforced
    auto = distinct([
      var.admin_note.lifecycle_automations.provisioning.type,
      var.admin_note.lifecycle_automations.user_updates.type,
      var.admin_note.lifecycle_automations.deprovisioning.type
    ])
    owner = var.admin_note.app_owner
    audit = var.admin_note.last_access_audit_date
  }
  // Authentication policy
  authentication_policy_id = contains(["low", "medium", "high"], var.authentication_policy) ? var.environment.authentication_policy_ids[var.authentication_policy] : var.authentication_policy

  // Basic App Settings to get right. 
  saml_label  = var.saml_app.label == null ? var.name : var.saml_app.label
  recipient   = var.saml_app.recipient == null && var.saml_app.preconfigured_app == null ? var.saml_app.sso_url : var.saml_app.recipient
  destination = var.saml_app.destination == null && var.saml_app.preconfigured_app == null ? var.saml_app.sso_url : var.saml_app.destination

   // Accessibility settings
  accessibility_self_service = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.accessibility_self_service, false) : var.saml_app.accessibility_self_service
  
  // Endpoint settings
  acs_endpoints = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.acs_endpoints, []) : var.saml_app.acs_endpoints
  
  // SAML protocol settings
  assertion_signed = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.assertion_signed, true) : var.saml_app.assertion_signed
  authn_context_class_ref = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.authn_context_class_ref, "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport") : var.saml_app.authn_context_class_ref
  digest_algorithm = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.digest_algorithm, "SHA256") : var.saml_app.digest_algorithm
  honor_force_authn = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.honor_force_authn, true) : var.saml_app.honor_force_authn
  idp_issuer = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.idp_issuer, "http://www.okta.com/$${org.externalKey}") : var.saml_app.idp_issuer
  response_signed = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.response_signed, true) : var.saml_app.response_signed
  saml_version = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.saml_version, "2.0") : var.saml_app.saml_version
  signature_algorithm = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.signature_algorithm, "RSA_SHA256") : var.saml_app.signature_algorithm
  subject_name_id_format = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.subject_name_id_format, "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified") : var.saml_app.subject_name_id_format
  subject_name_id_template = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.subject_name_id_template, "$${user.userName}") : var.saml_app.subject_name_id_template
  
  // User management settings
  user_name_template = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.user_name_template, "$${source.login}") : var.saml_app.user_name_template
  user_name_template_type = var.saml_app.preconfigured_app == null ? coalesce(var.saml_app.user_name_template_type, "BUILT_IN") : var.saml_app.user_name_template_type
  

  
  //Formatting user attribute statements from saml_app variable
  user_attribute_statements = var.saml_app.user_attribute_statements == null ? null : [
    for attr in var.saml_app.user_attribute_statements : {
      type = "EXPRESSION"
      name = attr.name
      namespace = lookup({
        "basic"         = "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "uri reference" = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri",
        "unspecified"   = "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"
      }, attr.name_format, "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified")
      values = attr.values
    }
  ]

  //Formatting group attribute statements & adding filter based on groups that are flagged to be added.
  group_attribute_exists = local.group_attribute_statements != null ? 1 : 0

  attribute_statement_roles = [
    for role in var.roles : role
    if role.attribute_statement == true
  ]
  group_attribute_statements_regex = length(local.attribute_statement_roles) > 0 ? format(
    "^APP-ROLE-%s-(%s)$",
    upper(var.name),
    join("|", [for role in local.attribute_statement_roles : upper(role.name)])
  ) : "^$"

  group_attribute_statements = var.saml_app.group_attribute_statements != null ? {
    attributeStatements = [
      {
        type = "GROUP"
        name = var.saml_app.group_attribute_statements.name
        namespace = lookup({
          "basic"         = "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
          "uri reference" = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri",
          "unspecified"   = "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
        }, var.saml_app.group_attribute_statements.name_format, "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified")
        filterType  = "REGEX"
        filterValue = local.group_attribute_statements_regex
      }
  ] } : null

  // Combine user and group attribute statements with custom_settings var to be pushed through settings
  attribute_statements_combined = {
    attributeStatements = concat(
      var.saml_app.user_attribute_statements != null ? local.user_attribute_statements : [],
      var.saml_app.group_attribute_statements != null ? local.group_attribute_statements.attributeStatements : []
    )
  }

  attribute_statements_map = length(local.attribute_statements_combined.attributeStatements) > 0 ? {
    attribute_statements = local.attribute_statements_combined
  } : {}

  app_settings = merge(
    var.saml_app.custom_settings != null ? var.saml_app.custom_settings : {},
    local.attribute_statements_map
  )
}

resource "okta_app_saml" "saml_app" {
  // Basic app configuration
  label                            = local.saml_label
  status                           = var.saml_app.status
  preconfigured_app                = var.saml_app.preconfigured_app

  
  // Visual/UI settings
  logo                             = var.saml_app.logo
  admin_note                       = jsonencode(local.admin_note)
  enduser_note                     = var.saml_app.enduser_note
  hide_ios                         = var.saml_app.hide_ios
  hide_web                         = var.saml_app.hide_web
  auto_submit_toolbar              = var.saml_app.auto_submit_toolbar
  
  // Accessibility settings
  accessibility_self_service       = local.accessibility_self_service
  accessibility_error_redirect_url = var.saml_app.accessibility_error_redirect_url
  accessibility_login_redirect_url = var.saml_app.accessibility_login_redirect_url
  
  // Authentication policy
  authentication_policy            = local.authentication_policy_id
  implicit_assignment              = var.saml_app.implicit_assignment
  
  // User management settings
  user_name_template               = local.user_name_template
  user_name_template_type          = local.user_name_template_type
  user_name_template_suffix        = var.saml_app.user_name_template_suffix
  user_name_template_push_status   = var.saml_app.user_name_template_push_status
  
  // SAML protocol settings
  saml_version                     = local.saml_version
  assertion_signed                 = local.assertion_signed
  response_signed                  = local.response_signed
  signature_algorithm              = local.signature_algorithm
  digest_algorithm                 = local.digest_algorithm
  honor_force_authn                = local.honor_force_authn
  authn_context_class_ref          = local.authn_context_class_ref
  idp_issuer                       = local.idp_issuer
  
  // SAML subject configuration
  subject_name_id_format           = local.subject_name_id_format
  subject_name_id_template         = local.subject_name_id_template
  
  // Endpoint configuration
  acs_endpoints                    = local.acs_endpoints
  sso_url                          = var.saml_app.sso_url
  destination                      = local.destination
  recipient                        = local.recipient
  audience                         = var.saml_app.audience
  default_relay_state              = var.saml_app.default_relay_state
  sp_issuer                        = var.saml_app.sp_issuer
  
  // Single logout configuration
  single_logout_url                = var.saml_app.single_logout_url
  single_logout_certificate        = var.saml_app.single_logout_certificate
  single_logout_issuer             = var.saml_app.single_logout_issuer
  
  // Advanced SAML settings
  request_compressed               = var.saml_app.request_compressed
  saml_signed_request_enabled      = var.saml_app.saml_signed_request_enabled
  inline_hook_id                   = var.saml_app.inline_hook_id
  
  // Certificate settings
  key_name                         = var.saml_app.key_name
  key_years_valid                  = var.saml_app.key_years_valid

    // App settings (JSON format)
  app_settings_json                = jsonencode(local.app_settings)
  
}

resource "okta_app_user_base_schema_property" "properties" {
  for_each = { for idx, prop in var.base_schema : prop.index => prop }
  
  app_id      = okta_app_saml.saml_app.id
  index       = each.value.index
  title       = each.value.title
  type        = each.value.type
  master      = each.value.master
  pattern     = each.value.pattern
  permissions = each.value.permissions
  required    = each.value.required
  user_type   = each.value.user_type
}

resource "okta_app_group_assignments" "main_app" {
  app_id = okta_app_saml.saml_app.id

  dynamic "group" {
    for_each = okta_group.assignment_groups[*].id
    iterator = group_id
    content {
      id       = group_id.value
      profile  = jsonencode(var.roles[group_id.key].profile)
      priority = tonumber(group_id.key) + 1
    }
  }
}

resource "okta_app_user_schema_property" "custom_properties" {
  for_each = { for idx, prop in var.custom_schema : prop.index => prop }

  app_id      = okta_app_saml.saml_app.id
  index       = each.value.index
  title       = each.value.title
  type        = each.value.type
  description = each.value.description
  master      = each.value.master
  scope       = each.value.scope
  
  # Optional properties
  dynamic "array_one_of" {
    for_each = each.value.array_one_of != null ? each.value.array_one_of : []
    content {
      const = array_one_of.value.const
      title = array_one_of.value.title
    }
  }
  
  array_enum         = each.value.array_enum
  array_type         = each.value.array_type
  enum               = each.value.enum
  external_name      = each.value.external_name
  external_namespace = each.value.external_namespace
  max_length         = each.value.max_length
  min_length         = each.value.min_length
  permissions        = each.value.permissions
  required           = each.value.required
  union              = each.value.union
  unique             = each.value.unique
  user_type          = each.value.user_type
  
  dynamic "one_of" {
    for_each = each.value.one_of != null ? each.value.one_of : []
    content {
      const = one_of.value.const
      title = one_of.value.title
    }
  }
}

