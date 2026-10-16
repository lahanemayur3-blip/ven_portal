@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP BO - ASN item'
define view entity ZI_VP_AsnItem
  as select from zvp_asn_itm         as Itm
    inner join   zvp_asn_hdr         as Asn on Asn.asn_uuid = Itm.asn_uuid
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Asn.supplier
  association to parent ZI_VP_Asn as _Asn on $projection.AsnUUID = _Asn.AsnUUID
{
  key Itm.asn_item_uuid      as AsnItemUUID,
      Itm.asn_uuid           as AsnUUID,
      Itm.purchase_order     as PurchaseOrder,
      Itm.purchase_order_item as PurchaseOrderItem,
      Itm.material           as Material,
      Itm.material_text      as MaterialDescription,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      Itm.quantity           as Quantity,
      Itm.unit               as Unit,

      _Asn
}
