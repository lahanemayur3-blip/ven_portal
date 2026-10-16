@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Dashboard KPIs'
@Metadata.allowExtensions: true
define root view entity ZC_VP_DashboardKpi
  provider contract transactional_query
  as projection on ZI_VP_DashboardKpi
{
  key Supplier,
      OpenPOs,
      PendingAck,
      UpcomingDeliveries,
      DelayedPOs,
      AsnItemsReady,
      ShipmentsInTransit,
      InvoicesSubmitted,
      InvoicesRejected,
      InvoicesBooked,
      OverduePayments,
      NetPayable,
      PaidInvoices,
      Currency
}
