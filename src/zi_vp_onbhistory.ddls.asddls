@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor onboarding status history'
define view entity ZI_VP_OnbHistory
  as select from zvp_onb_hist
  association to parent ZI_VP_OnbApplication as _Application on $projection.AppUuid = _Application.AppUuid
{
  key hist_uuid   as HistUuid,
      app_uuid    as AppUuid,
      status_from as StatusFrom,
      status_to   as StatusTo,
      comment1     as Comment1,
      @Semantics.user.createdBy: true
      changed_by  as ChangedBy,
      @Semantics.systemDateTime.createdAt: true
      changed_at  as ChangedAt,

      _Application
}
