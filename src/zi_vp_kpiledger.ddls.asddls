@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP KPI - open vendor ledger items'
define view entity ZI_VP_KpiLedger
  as select from ZI_VP_StatementItem
{
  key Supplier,
  key CompanyCodeCurrency as Currency,
      sum( case when NetDueDate < $session.system_date then 1 else 0 end ) as OverduePayments,
      @Semantics.amount.currencyCode: 'Currency'
      sum( AmountInCompanyCurrency )                                       as OpenBalance
}
where ClearingDate is initial
group by Supplier, CompanyCodeCurrency
