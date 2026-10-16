@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - acknowledgement status per PO'
define view entity ZI_VP_PoAckHeader
  as select from zvp_po_ack
{
  key purchase_order    as PurchaseOrder,
      max( ack_status ) as AckStatus
}
group by purchase_order
