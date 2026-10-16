@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - dashboard KPIs (one row per supplier)'
define root view entity ZI_VP_DashboardKpi
  as select from ZI_VP_VendorContext      as Ctx
    left outer join ZI_VP_KpiPo           as Po  on Po.Supplier  = Ctx.Supplier
    left outer join ZI_VP_KpiAsn          as Asn on Asn.Supplier = Ctx.Supplier
    left outer join ZI_VP_KpiAsnReady     as Rdy on Rdy.Supplier = Ctx.Supplier
    left outer join ZI_VP_KpiInvoice      as Inv on Inv.Supplier = Ctx.Supplier
    left outer join ZI_VP_KpiLedger       as Led on  Led.Supplier = Ctx.Supplier
                                                 and Led.Currency = Ctx.Currency
{
  key Ctx.Supplier                               as Supplier,
      coalesce( Po.OpenPOs, 0 )                  as OpenPOs,
      coalesce( Po.PendingAck, 0 )               as PendingAck,
      coalesce( Po.UpcomingDeliveries, 0 )       as UpcomingDeliveries,
      coalesce( Po.DelayedPOs, 0 )               as DelayedPOs,
      coalesce( Rdy.AsnItemsReady, 0 )           as AsnItemsReady,
      coalesce( Asn.ShipmentsInTransit, 0 )      as ShipmentsInTransit,
      coalesce( Inv.InvoicesSubmitted, 0 )       as InvoicesSubmitted,
      coalesce( Inv.InvoicesRejected, 0 )        as InvoicesRejected,
      coalesce( Inv.InvoicesBooked, 0 )          as InvoicesBooked,
      coalesce( Led.OverduePayments, 0 )         as OverduePayments,
      @Semantics.amount.currencyCode: 'Currency'
      Led.OpenBalance * -1                       as NetPayable,
      coalesce( Inv.PaidInvoices, 0 )            as PaidInvoices,
      Ctx.Currency                               as Currency
}
