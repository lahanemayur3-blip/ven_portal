@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP KPI - purchase orders'
define view entity ZI_VP_KpiPo
  as select from ZI_VP_PurchaseOrder
{
  key Supplier,
      sum( case when Status <> 'Closed'  then 1 else 0 end ) as OpenPOs,
      sum( case when Status =  'Sent'    then 1 else 0 end ) as PendingAck,
      sum( case when IsUpcoming = 'X'    then 1 else 0 end ) as UpcomingDeliveries,
      sum( case when IsDelayed  = 'X'    then 1 else 0 end ) as DelayedPOs
}
group by Supplier
