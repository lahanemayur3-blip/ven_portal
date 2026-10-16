@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - recent activity of the supplier'
define root view entity ZI_VP_Activity
  as select from zvp_activity        as Act
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Act.supplier
{
  key Act.activity_uuid       as ActivityUUID,
      Act.supplier            as Supplier,
      Act.created_at          as ActivityTimestamp,
      Act.activity_text       as ActivityText,
      Act.related_object_type as RelatedObjectType,
      Act.related_object_id   as RelatedObjectId
}
