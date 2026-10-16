@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor onboarding application'
define root view entity ZI_VP_OnbApplication
  as select from zvp_onb_app
  composition [0..*] of ZI_VP_OnbDocument    as _Document
  composition [0..*] of ZI_VP_OnbHistory     as _History
  association [0..1] to ZI_VP_OnbCompanyType as _CompanyType on $projection.CompanyType = _CompanyType.CompanyType
{
  key app_uuid              as AppUuid,
      application_id        as ApplicationId,
      applicant_user        as ApplicantUser,
      status                as Status,
      current_step          as CurrentStep,

      company_name          as CompanyName,
      contact_person        as ContactPerson,
      email                 as Email,
      phone                 as Phone,

      legal_name            as LegalName,
      company_type          as CompanyType,
      address_line          as AddressLine,
      city                  as City,
      region                as Region,
      country               as Country,
      postal_code           as PostalCode,

      gstin                 as Gstin,
      pan                   as Pan,
      msme_number           as MsmeNumber,

      bank_name             as BankName,
      account_holder        as AccountHolderName,
      bank_account          as BankAccountNumber,
      ifsc                  as Ifsc,

      submitted_at          as SubmittedAt,
      reviewed_by           as ReviewedBy,
      reviewed_at           as ReviewedAt,
      review_comment        as ReviewComment,
      supplier              as Supplier,

      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      _Document,
      _History,
      _CompanyType
}
