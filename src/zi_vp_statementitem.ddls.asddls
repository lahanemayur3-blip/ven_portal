@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read vendor stmnt line itms(FBL1N)'
define root view entity ZI_VP_StatementItem
  as select from I_OperationalAcctgDocItem as Item
    inner join   ZI_VP_CurrentSupplier     as Cur on  Cur.Supplier    = Item.Supplier
                                                  and Cur.CompanyCode = Item.CompanyCode
  association [0..1] to I_JournalEntry as _Journal
    on  _Journal.CompanyCode        = $projection.CompanyCode
    and _Journal.FiscalYear         = $projection.FiscalYear
    and _Journal.AccountingDocument = $projection.AccountingDocument
{
  key Item.CompanyCode             as CompanyCode,
  key Item.FiscalYear              as FiscalYear,
  key Item.AccountingDocument      as AccountingDocument,
  key Item.AccountingDocumentItem  as AccountingDocumentItem,
      Item.Supplier                as Supplier,
      Item.AccountingDocumentType  as DocumentType,
      Item.DocumentDate            as DocumentDate,
      Item.PostingDate             as PostingDate,
      Item.NetDueDate              as NetDueDate,
      _Journal.DocumentReferenceID as Reference,
      Item.AssignmentReference     as Assignment,
      Item.DocumentItemText        as ItemText,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      Item.AmountInCompanyCodeCurrency as AmountInCompanyCurrency,
      Item.CompanyCodeCurrency     as CompanyCodeCurrency,
//      Item.ClearingAccountingDocument as ClearingDocument,
      Item.ClearingJournalEntry as ClearingDocument,
      Item.ClearingDate            as ClearingDate
}
where Item.FinancialAccountType = 'K'
