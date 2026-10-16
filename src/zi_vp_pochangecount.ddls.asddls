@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - pending change requests per PO'
define view entity ZI_VP_PoChangeCount
  as select from zvp_po_chgreq
{
  key purchase_order as PurchaseOrder,
      cast( count( * ) as abap.int4 ) as PendingCount
}
where status = 'Pending'
group by purchase_order
