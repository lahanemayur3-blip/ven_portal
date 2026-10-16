@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP read - vendor context of the logged-on user'
define root view entity ZI_VP_VendorContext
  as select from ZI_VP_CurrentSupplier as Cur
    inner join   I_Supplier            as Sup on Sup.Supplier    = Cur.Supplier
    inner join   I_CompanyCode         as Cc  on Cc.CompanyCode  = Cur.CompanyCode
{
  key Cur.Supplier         as Supplier,
      Sup.SupplierName     as SupplierName,
      Cur.CompanyCode      as CompanyCode,
      Cur.PaymentTermsDays as PaymentTermsDays,
      Cc.Currency          as Currency
}
