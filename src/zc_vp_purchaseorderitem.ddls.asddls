@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Purchase order item'
@Metadata.allowExtensions: true
define root view entity ZC_VP_PurchaseOrderItem
  provider contract transactional_query
  as projection on ZI_VP_PurchaseOrderItem
{
  key PurchaseOrder,
  key PurchaseOrderItem,
      Material,
      MaterialDescription,
      OrderQuantity,
      OrderUnit,
      NetPrice,
      NetAmount,
      Currency,
      DeliveryDate,
      ConfirmedQuantity,
      ConfirmedDate,
      AsnQuantity,
      InvoicedQuantity
}
