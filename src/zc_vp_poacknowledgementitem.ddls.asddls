@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - PO acknowledgement item'
@Metadata.allowExtensions: true
define view entity ZC_VP_PoAcknowledgementItem
  as projection on ZI_VP_PoAcknowledgementItem
{
  key AckItemUUID,
      AckUUID,
      PurchaseOrderItem,
      OrderedQuantity,
      ConfirmedQuantity,
      OrderUnit,
      OrderedDate,
      ConfirmedDate,

      _Ack : redirected to parent ZC_VP_PoAcknowledgement
}
