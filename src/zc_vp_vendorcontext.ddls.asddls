@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - Vendor context'
@Metadata.allowExtensions: true
define root view entity ZC_VP_VendorContext
  provider contract transactional_query
  as projection on ZI_VP_VendorContext
{
  key Supplier,
      SupplierName,
      CompanyCode,
      PaymentTermsDays,
      Currency
}
