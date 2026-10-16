@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - confirmed qty/date per PO item'
define view entity ZI_VP_PoAckItem
  as select from zvp_po_ack_itm as Itm
    inner join   zvp_po_ack     as Hdr on Hdr.ack_uuid = Itm.ack_uuid
{
  key Hdr.purchase_order      as PurchaseOrder,
  key Itm.purchase_order_item as PurchaseOrderItem,
      Itm.order_unit          as OrderUnit,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      sum( Itm.confirmed_quantity ) as ConfirmedQuantity,
      max( Itm.confirmed_date )     as ConfirmedDate
}
group by Hdr.purchase_order, Itm.purchase_order_item, Itm.order_unit
