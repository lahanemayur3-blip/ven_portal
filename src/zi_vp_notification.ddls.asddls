// Notifications for the logged-in user (reads the extended ZVP_ACTIVITY)
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor portal notifications per user'
define view entity ZI_VP_Notification
  as select from zvp_activity
{
  key activity_uuid       as ActivityUuid,
      user_id             as UserId,
      supplier            as Supplier,
      activity_text       as ActivityText,
      related_object_type as RelatedObjectType,
      related_object_id   as RelatedObjectId,
      is_read             as IsRead,
      created_by          as CreatedBy,
      created_at          as CreatedAt
}
