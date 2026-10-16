@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Items eligible for invoice'
@Metadata.allowExtensions: true
define root view entity ZC_VP_InvoiceEligibleItem
  provider contract transactional_query
  as projection on ZI_VP_InvoiceEligibleItem
{
  key PurchaseOrder,
  key PurchaseOrderItem,
      Material,
      MaterialDescription,
      OrderUnit,
      ShippedNotInvoicedQuantity,
      NetPrice,
      Currency
}
