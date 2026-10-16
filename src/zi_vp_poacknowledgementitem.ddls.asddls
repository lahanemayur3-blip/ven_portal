@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP BO - PO acknowledgement item'
define view entity ZI_VP_PoAcknowledgementItem
  as select from zvp_po_ack_itm      as Itm
    inner join   zvp_po_ack          as Ack on Ack.ack_uuid = Itm.ack_uuid
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Ack.supplier
  association to parent ZI_VP_PoAcknowledgement as _Ack on $projection.AckUUID = _Ack.AckUUID
{
  key Itm.ack_item_uuid      as AckItemUUID,
      Itm.ack_uuid           as AckUUID,
      Itm.purchase_order_item as PurchaseOrderItem,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      Itm.ordered_quantity   as OrderedQuantity,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      Itm.confirmed_quantity as ConfirmedQuantity,
      Itm.order_unit         as OrderUnit,
      Itm.ordered_date       as OrderedDate,
      Itm.confirmed_date     as ConfirmedDate,

      _Ack
}
