@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - derived PO status'
define view entity ZI_VP_PurchaseOrderStatus
  as select from ZI_VP_PoItemAgg       as Agg
    left outer join ZI_VP_PoAckHeader  as Ack on Ack.PurchaseOrder = Agg.PurchaseOrder
    left outer join ZI_VP_PoAsnActive  as Act on Act.PurchaseOrder = Agg.PurchaseOrder
    left outer join ZI_VP_PoChangeCount as Chg on Chg.PurchaseOrder = Agg.PurchaseOrder
{
  key Agg.PurchaseOrder as PurchaseOrder,
      cast(
        case
          when Agg.ItemCount > 0 and Agg.InvoicedFullItems = Agg.ItemCount then 'Closed'
          when Agg.ItemCount > 0 and Agg.ShippedFullItems  = Agg.ItemCount
               and coalesce( Act.ActiveAsnCount, 0 ) = 0                    then 'Delivered'
          when Agg.ShippedItems > 0                                         then 'In Delivery'
          when Ack.AckStatus = 'Confirmed'                                  then 'Confirmed'
          when Ack.AckStatus is not null                                    then 'Acknowledged'
          else 'Sent'
        end as abap.char(15) )                                              as Status,
      coalesce( Chg.PendingCount, 0 )                                       as PendingChangeCount
}
