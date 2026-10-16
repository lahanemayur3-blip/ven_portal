@EndUserText.label: 'Onboarding action parameter - approval'
define abstract entity ZA_VP_OnbApprove
{
  Supplier    : abap.char(10);   // SAP supplier (business partner) created for this vendor
  CompanyCode : abap.char(4);
  Comment1     : abap.char(1000);
}
