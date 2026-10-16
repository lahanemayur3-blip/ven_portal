@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - quantity on ASNs per PO item'
define view entity ZI_VP_PoItemAsnQty
  as select from zvp_asn_itm
{
  key purchase_order      as PurchaseOrder,
  key purchase_order_item as PurchaseOrderItem,
      unit                as Unit,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      sum( quantity )     as AsnQuantity
}
group by purchase_order, purchase_order_item, unit
