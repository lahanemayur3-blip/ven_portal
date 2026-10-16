@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor onboarding history (vendor UI)'
define view entity ZC_VP_OnbHistory
  as projection on ZI_VP_OnbHistory
{
  key HistUuid,
      AppUuid,
      StatusFrom,
      StatusTo,
      Comment1,
      ChangedBy,
      ChangedAt,

      _Application : redirected to parent ZC_VP_OnbApplication
}
