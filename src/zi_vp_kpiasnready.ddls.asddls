@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP KPI - items ready for ASN'
define view entity ZI_VP_KpiAsnReady
  as select from ZI_VP_AsnEligibleItem
{
  key Supplier,
      cast( count( * ) as abap.int4 ) as AsnItemsReady
}
group by Supplier
