@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor onboarding application (vendor UI)'
@Metadata.allowExtensions: true
define root view entity ZC_VP_OnbApplication
  provider contract transactional_query
  as projection on ZI_VP_OnbApplication
{
  key AppUuid,
      ApplicationId,
      ApplicantUser,
      Status,
      CurrentStep,
      CompanyName,
      ContactPerson,
      Email,
      Phone,
      LegalName,
      @ObjectModel.text.element: ['CompanyTypeText']
      CompanyType,
      _CompanyType.Description as CompanyTypeText,
      AddressLine,
      City,
      Region,
      Country,
      PostalCode,
      Gstin,
      Pan,
      MsmeNumber,
      BankName,
      AccountHolderName,
      BankAccountNumber,
      Ifsc,
      SubmittedAt,
      ReviewedBy,
      ReviewedAt,
      ReviewComment,
      Supplier,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Document : redirected to composition child ZC_VP_OnbDocument,
      _History  : redirected to composition child ZC_VP_OnbHistory,
      _CompanyType
}
