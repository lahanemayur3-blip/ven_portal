@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - invoiced quantity per PO item (rejected invoices excluded)'
define view entity ZI_VP_PoItemInvQty
  as select from zvp_inv_itm as Itm
    inner join   zvp_inv_hdr as Hdr on Hdr.invoice_uuid = Itm.invoice_uuid
{
  key Hdr.purchase_order      as PurchaseOrder,
  key Itm.purchase_order_item as PurchaseOrderItem,
      Itm.unit                as Unit,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      sum( Itm.quantity )     as InvoicedQuantity
}
where Hdr.status <> 'Rejected'
group by Hdr.purchase_order, Itm.purchase_order_item, Itm.unit
