@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP BO - Supplier invoice item'
define view entity ZI_VP_InvoiceItem
  as select from zvp_inv_itm         as Itm
    inner join   zvp_inv_hdr         as Inv on Inv.invoice_uuid = Itm.invoice_uuid
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Inv.supplier
  association to parent ZI_VP_Invoice as _Invoice on $projection.InvoiceUUID = _Invoice.InvoiceUUID
{
  key Itm.inv_item_uuid       as InvoiceItemUUID,
      Itm.invoice_uuid        as InvoiceUUID,
      Itm.purchase_order_item as PurchaseOrderItem,
      Itm.description         as Description,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      Itm.quantity            as Quantity,
      Itm.unit                as Unit,
      @Semantics.amount.currencyCode: 'Currency'
      Itm.rate                as Rate,
      Itm.tax_percent         as TaxPercent,
      @Semantics.amount.currencyCode: 'Currency'
      Itm.net_amount          as NetAmount,
      Itm.currency            as Currency,

      _Invoice
}
