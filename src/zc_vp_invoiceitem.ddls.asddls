@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Supplier invoice item'
@Metadata.allowExtensions: true
define view entity ZC_VP_InvoiceItem
  as projection on ZI_VP_InvoiceItem
{
  key InvoiceItemUUID,
      InvoiceUUID,
      PurchaseOrderItem,
      Description,
      Quantity,
      Unit,
      Rate,
      TaxPercent,
      NetAmount,
      Currency,

      _Invoice : redirected to parent ZC_VP_Invoice
}
