@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Supplier invoice'
@Metadata.allowExtensions: true
define root view entity ZC_VP_Invoice
  provider contract transactional_query
  as projection on ZI_VP_Invoice
{
  key InvoiceUUID,
      InvoiceId,
      VendorInvoiceNumber,
      PurchaseOrder,
      InvoiceDate,
      DueDate,
      NetAmount,
      TaxAmount,
      GrossAmount,
      Currency,
      Status,
      RejectionReason,
      SupplierInvoice,
      PaymentReference,
      FileName,
      MimeType,
      FileContent,
      CreatedAt,

      _Items : redirected to composition child ZC_VP_InvoiceItem
}
