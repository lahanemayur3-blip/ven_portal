@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - purchase order of the logged-on supplier'
define root view entity ZI_VP_PurchaseOrder
  as select from I_PurchaseOrderAPI01        as Po
    inner join   ZI_VP_CurrentSupplier       as Cur on Cur.Supplier = Po.Supplier
    inner join   ZI_VP_PoItemAgg             as Agg on Agg.PurchaseOrder = Po.PurchaseOrder
    inner join   ZI_VP_PurchaseOrderStatus   as Sts on Sts.PurchaseOrder = Po.PurchaseOrder
  association [0..*] to ZI_VP_PurchaseOrderItem as _Items
    on _Items.PurchaseOrder = $projection.PurchaseOrder
  association [0..*] to ZI_VP_PoChangeRequest   as _ChangeRequests
    on _ChangeRequests.PurchaseOrder = $projection.PurchaseOrder
{
  key Po.PurchaseOrder     as PurchaseOrder,
      Po.Supplier          as Supplier,
      Po.CompanyCode       as CompanyCode,
      Po.PurchaseOrderDate as PurchaseOrderDate,
      Agg.DeliveryDate     as DeliveryDate,
      Agg.ItemCount        as ItemCount,
      @Semantics.amount.currencyCode: 'Currency'
      Agg.NetAmount        as NetAmount,
      Agg.Currency         as Currency,
      Sts.Status           as Status,
      cast(
        case
          when Sts.Status = 'Closed'                      then 'Completed'
          when Sts.PendingChangeCount > 0                 then 'Under approval'
          when Sts.Status = 'In Delivery'
            or Sts.Status = 'Delivered'                   then 'In process'
          else 'Open'
        end as abap.char(15) )                            as Stage,
      cast(
        case
          when Sts.Status <> 'Closed' and Sts.Status <> 'Delivered'
           and Agg.DeliveryDate < $session.system_date    then 'X'
          else ' '
        end as abap_boolean preserving type )             as IsDelayed,
      cast(
        case
          when Sts.Status <> 'Closed' and Sts.Status <> 'Delivered'
           and Agg.DeliveryDate >= $session.system_date
           and Agg.DeliveryDate <= dats_add_days( $session.system_date, 7, 'NULL' ) then 'X'
          else ' '
        end as abap_boolean preserving type )             as IsUpcoming,

      _Items,
      _ChangeRequests
}
