@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Receiving location'
@Metadata.allowExtensions: true
define root view entity ZC_VP_ReceivingLocation
  provider contract transactional_query
  as projection on ZI_VP_ReceivingLocation
{
  key Plant,
      PlantName
}
