@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - PO item with confirmation, ASN and invoice quantities'
define root view entity ZI_VP_PurchaseOrderItem
  as select from I_PurchaseOrderItemAPI01 as Item
    inner join   I_PurchaseOrderAPI01     as Po  on Po.PurchaseOrder = Item.PurchaseOrder
    inner join   ZI_VP_CurrentSupplier    as Cur on Cur.Supplier = Po.Supplier
    left outer join ZI_VP_PoItemDelivery  as Dlv on  Dlv.PurchaseOrder     = Item.PurchaseOrder
                                                 and Dlv.PurchaseOrderItem = Item.PurchaseOrderItem
    left outer join ZI_VP_PoAckItem       as Ack on  Ack.PurchaseOrder     = Item.PurchaseOrder
                                                 and Ack.PurchaseOrderItem = Item.PurchaseOrderItem
    left outer join ZI_VP_PoItemAsnQty    as Asn on  Asn.PurchaseOrder     = Item.PurchaseOrder
                                                 and Asn.PurchaseOrderItem = Item.PurchaseOrderItem
    left outer join ZI_VP_PoItemInvQty    as Inv on  Inv.PurchaseOrder     = Item.PurchaseOrder
                                                 and Inv.PurchaseOrderItem = Item.PurchaseOrderItem
{
  key Item.PurchaseOrder                as PurchaseOrder,
  key Item.PurchaseOrderItem            as PurchaseOrderItem,
      Po.Supplier                       as Supplier,
      Item.Material                     as Material,
      Item.PurchaseOrderItemText        as MaterialDescription,
      Item.Plant                        as Plant,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      Item.OrderQuantity                as OrderQuantity,
      Item.PurchaseOrderQuantityUnit    as OrderUnit,
      @Semantics.amount.currencyCode: 'Currency'
      Item.NetPriceAmount               as NetPrice,
      @Semantics.amount.currencyCode: 'Currency'
      Item.NetAmount                    as NetAmount,
      Item.DocumentCurrency             as Currency,
      Dlv.DeliveryDate                  as DeliveryDate,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      cast( coalesce( Ack.ConfirmedQuantity, 0 ) as abap.quan( 13, 3 ) ) as ConfirmedQuantity,
      Ack.ConfirmedDate                 as ConfirmedDate,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      cast( coalesce( Asn.AsnQuantity, 0 ) as abap.quan( 13, 3 ) )       as AsnQuantity,
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      cast( coalesce( Inv.InvoicedQuantity, 0 ) as abap.quan( 13, 3 ) )  as InvoicedQuantity
}
where Item.PurchasingDocumentDeletionCode = ''
