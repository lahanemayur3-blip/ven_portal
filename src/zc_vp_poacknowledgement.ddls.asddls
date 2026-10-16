@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - PO acknowledgement'
@Metadata.allowExtensions: true
define root view entity ZC_VP_PoAcknowledgement
  provider contract transactional_query
  as projection on ZI_VP_PoAcknowledgement
{
  key AckUUID,
      PurchaseOrder,
      Status,
      CreatedAt,

      _Items : redirected to composition child ZC_VP_PoAcknowledgementItem
}
