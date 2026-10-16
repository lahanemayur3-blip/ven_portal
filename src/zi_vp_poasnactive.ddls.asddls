@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP helper - ASNs per PO that are not yet delivered'
define view entity ZI_VP_PoAsnActive
  as select from zvp_asn_itm as Itm
    inner join   zvp_asn_hdr as Hdr on Hdr.asn_uuid = Itm.asn_uuid
{
  key Itm.purchase_order                          as PurchaseOrder,
      cast( count( distinct Hdr.asn_uuid ) as abap.int4 ) as ActiveAsnCount
}
where Hdr.status <> 'Delivered'
group by Itm.purchase_order
