@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP BO - PO acknowledgement (root)'
define root view entity ZI_VP_PoAcknowledgement
  as select from zvp_po_ack          as Ack
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Ack.supplier
  composition [0..*] of ZI_VP_PoAcknowledgementItem as _Items
{
  key Ack.ack_uuid       as AckUUID,
      Ack.purchase_order as PurchaseOrder,
      Ack.supplier       as Supplier,
      Ack.all_match      as AllMatch,
      Ack.ack_status     as Status,
      @Semantics.user.createdBy: true
      Ack.local_created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Ack.local_created_at      as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      Ack.local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Ack.local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      Ack.last_changed_at       as LastChangedAt,

      _Items
}
