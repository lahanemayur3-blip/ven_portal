@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - PO items shipped but not yet invoiced'
define root view entity ZI_VP_InvoiceEligibleItem
  as select from ZI_VP_PurchaseOrderItem
{
  key PurchaseOrder,
  key PurchaseOrderItem,
      Supplier,
      Material,
      MaterialDescription,
      OrderUnit,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      AsnQuantity - InvoicedQuantity as ShippedNotInvoicedQuantity,
      @Semantics.amount.currencyCode: 'Currency'
      NetPrice,
      Currency
}
where AsnQuantity > InvoicedQuantity
