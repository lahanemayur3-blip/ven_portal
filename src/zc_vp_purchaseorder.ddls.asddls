@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Purchase order'
@Metadata.allowExtensions: true
define root view entity ZC_VP_PurchaseOrder
  provider contract transactional_query
  as projection on ZI_VP_PurchaseOrder
{
  key PurchaseOrder,
      PurchaseOrderDate,
      DeliveryDate,
      ItemCount,
      NetAmount,
      Currency,
      Status,
      Stage,
      IsDelayed,
      IsUpcoming,

      _Items          : redirected to ZC_VP_PurchaseOrderItem,
      _ChangeRequests : redirected to ZC_VP_PoChangeRequest
}
