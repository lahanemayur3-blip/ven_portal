@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Recent activity'
@Metadata.allowExtensions: true
define root view entity ZC_VP_Activity
  provider contract transactional_query
  as projection on ZI_VP_Activity
{
  key ActivityUUID,
      ActivityTimestamp,
      ActivityText
}
