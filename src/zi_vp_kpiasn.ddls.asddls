@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP KPI - shipments'
define view entity ZI_VP_KpiAsn
  as select from ZI_VP_Asn
{
  key Supplier,
      sum( case when Status = 'In Transit' then 1 else 0 end ) as ShipmentsInTransit
}
group by Supplier
