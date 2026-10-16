@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - PO items that can still be put on an ASN'
define root view entity ZI_VP_AsnEligibleItem
  as select from ZI_VP_PurchaseOrderItem
{
  key PurchaseOrder,
  key PurchaseOrderItem,
      Supplier,
      Material,
      MaterialDescription,
      OrderUnit,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      ConfirmedQuantity - AsnQuantity as OpenQuantity,
      ConfirmedDate
}
where ConfirmedQuantity > AsnQuantity
