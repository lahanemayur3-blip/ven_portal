@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - receiving plants (value help)'
define root view entity ZI_VP_ReceivingLocation
  as select from I_Plant
{
  key Plant,
      PlantName
}
