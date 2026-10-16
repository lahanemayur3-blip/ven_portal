@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP BO - Supplier invoice (root)'
define root view entity ZI_VP_Invoice
  as select from zvp_inv_hdr         as Inv
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Inv.supplier
  composition [0..*] of ZI_VP_InvoiceItem as _Items
{
  key Inv.invoice_uuid          as InvoiceUUID,
      Inv.invoice_id            as InvoiceId,
      Inv.supplier              as Supplier,
      Inv.vendor_invoice_number as VendorInvoiceNumber,
      Inv.purchase_order        as PurchaseOrder,
      Inv.invoice_date          as InvoiceDate,
      Inv.due_date              as DueDate,
      @Semantics.amount.currencyCode: 'Currency'
      Inv.net_amount            as NetAmount,
      @Semantics.amount.currencyCode: 'Currency'
      Inv.tax_amount            as TaxAmount,
      @Semantics.amount.currencyCode: 'Currency'
      Inv.gross_amount          as GrossAmount,
      Inv.currency              as Currency,
      Inv.status                as Status,
      Inv.rejection_reason      as RejectionReason,
      Inv.supplier_invoice      as SupplierInvoice,
      Inv.supplier_invoice_fiscal_year as SupplierInvoiceFiscalYear,
      Inv.payment_reference     as PaymentReference,
      Inv.file_name             as FileName,
      Inv.mime_type             as MimeType,
      Inv.file_content          as FileContent,
      @Semantics.user.createdBy: true
      Inv.local_created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Inv.local_created_at      as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      Inv.local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Inv.local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      Inv.last_changed_at       as LastChangedAt,

      _Items
}
