@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - supplier(s) of the logged-on portal user'
define view entity ZI_VP_CurrentSupplier
  as select from zvp_user_map
{
  key supplier           as Supplier,
      company_code       as CompanyCode,
      payment_terms_days as PaymentTermsDays,
      portal_email       as PortalEmail
}
where user_id    =  $session.user
  and is_active  =  'X'
  and valid_from <= $session.system_date
  and valid_to   >= $session.system_date
