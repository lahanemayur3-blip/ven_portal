@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor onboarding document (vendor UI)'
@Metadata.allowExtensions: true
define view entity ZC_VP_OnbDocument
  as projection on ZI_VP_OnbDocument
{
  key DocUuid,
      AppUuid,
      @ObjectModel.text.element: ['DocTypeText']
      DocType,
      _DocType.Description as DocTypeText,
      DocName,
      FileContent,
      MimeType,
      FileName,
      ExpiryDate,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,

      _Application : redirected to parent ZC_VP_OnbApplication,
      _DocType
}
