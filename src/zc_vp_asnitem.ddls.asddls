@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - ASN item'
@Metadata.allowExtensions: true
define view entity ZC_VP_AsnItem
  as projection on ZI_VP_AsnItem
{
  key AsnItemUUID,
      AsnUUID,
      PurchaseOrder,
      PurchaseOrderItem,
      Material,
      MaterialDescription,
      Quantity,
      Unit,

      _Asn : redirected to parent ZC_VP_Asn
}
