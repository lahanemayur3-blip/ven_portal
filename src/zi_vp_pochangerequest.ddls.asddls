@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP BO - PO change request (root)'
define root view entity ZI_VP_PoChangeRequest
  as select from zvp_po_chgreq       as Chg
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Chg.supplier
{
  key Chg.change_uuid      as ChangeUUID,
      Chg.purchase_order   as PurchaseOrder,
      Chg.supplier         as Supplier,
      Chg.request_text     as RequestText,
      Chg.status           as Status,
      Chg.business_comment as BusinessComment,
      Chg.processed_by     as ProcessedBy,
      Chg.processed_at     as ProcessedAt,
      @Semantics.user.createdBy: true
      Chg.local_created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Chg.local_created_at      as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      Chg.local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Chg.local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      Chg.last_changed_at       as LastChangedAt
}
