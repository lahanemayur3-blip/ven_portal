@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Items eligible for ASN'
@Metadata.allowExtensions: true
define root view entity ZC_VP_AsnEligibleItem     
  provider contract transactional_query
  as projection on ZI_VP_AsnEligibleItem
{
  key PurchaseOrder,
  key PurchaseOrderItem,
      Material,
      MaterialDescription,
      OrderUnit,
      OpenQuantity,
      ConfirmedDate
}
