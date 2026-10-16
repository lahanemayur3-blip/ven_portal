@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - PO item aggregates per PO'
define view entity ZI_VP_PoItemAgg
  as select from ZI_VP_PurchaseOrderItem
{
  key PurchaseOrder,
      Currency,
      min( DeliveryDate )                         as DeliveryDate,
      cast( count( * ) as abap.int4 )             as ItemCount,
      @Semantics.amount.currencyCode: 'Currency'
      sum( NetAmount )                            as NetAmount,
      sum( case when AsnQuantity > 0 then 1 else 0 end )                as ShippedItems,
      sum( case when AsnQuantity >= OrderQuantity then 1 else 0 end )   as ShippedFullItems,
      sum( case when InvoicedQuantity >= OrderQuantity then 1 else 0 end ) as InvoicedFullItems
}
group by PurchaseOrder, Currency
