@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - next delivery date per PO item'
define view entity ZI_VP_PoItemDelivery
  as select from I_PurOrdScheduleLineAPI01
{
  key PurchaseOrder,
  key PurchaseOrderItem,
      min( ScheduleLineDeliveryDate ) as DeliveryDate
}
group by
  PurchaseOrder,
  PurchaseOrderItem
