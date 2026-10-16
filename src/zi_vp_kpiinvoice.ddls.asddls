@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP KPI - invoices'
define view entity ZI_VP_KpiInvoice
  as select from ZI_VP_Invoice
{
  key Supplier,
      sum( case when Status = 'Submitted' or Status = 'In Business Processing' then 1 else 0 end ) as InvoicesSubmitted,
      sum( case when Status = 'Rejected' then 1 else 0 end ) as InvoicesRejected,
      sum( case when Status = 'Booked'   then 1 else 0 end ) as InvoicesBooked,
      sum( case when Status = 'Paid'     then 1 else 0 end ) as PaidInvoices
}
group by Supplier
