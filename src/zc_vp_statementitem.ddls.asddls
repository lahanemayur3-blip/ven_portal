@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Vendor statement item'
@Metadata.allowExtensions: true
define view entity ZC_VP_StatementItem
  as select from ZI_VP_StatementItem
{
  key CompanyCode,
  key FiscalYear,
  key AccountingDocument,
  key AccountingDocumentItem,
      DocumentType,
      DocumentDate,
      PostingDate,
      NetDueDate,
      Reference,
      Assignment,
      ItemText,
//         @ObjectModel.readOnly: true
      AmountInCompanyCurrency,
      CompanyCodeCurrency,
      ClearingDocument,
      ClearingDate
}
