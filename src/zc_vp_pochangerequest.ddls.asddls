@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - PO change request'
@Metadata.allowExtensions: true
define root view entity ZC_VP_PoChangeRequest
  provider contract transactional_query
  as projection on ZI_VP_PoChangeRequest
{
  key ChangeUUID,
      PurchaseOrder,
      RequestText,
      Status,
      BusinessComment,
      CreatedAt
}
