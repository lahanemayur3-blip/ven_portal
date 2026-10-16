@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor onboarding document (reviewer)'
@UI.headerInfo: { typeName: 'Document', typeNamePlural: 'Documents',
                  title: { type: #STANDARD, value: 'FileName' } }
define view entity ZC_VP_OnbReviewDoc
  as projection on ZI_VP_OnbDocument
{
      @UI.hidden: true
  key DocUuid,
      @UI.hidden: true
      AppUuid,
      @UI.lineItem: [{ position: 10, label: 'Document Type' }]
      @ObjectModel.text.element: ['DocTypeText']
      DocType,
      _DocType.Description as DocTypeText,
      @UI.lineItem: [{ position: 20, label: 'Name' }]
      DocName,
      @UI.lineItem: [{ position: 30, label: 'File' }]
      FileContent,
      MimeType,
      FileName,
      @UI.lineItem: [{ position: 40, label: 'Expiry Date' }]
      ExpiryDate,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,

      _Application : redirected to parent ZC_VP_OnbReview,
      _DocType
}
