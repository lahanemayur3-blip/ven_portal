@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor onboarding company types'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_VP_OnbCompanyType
  as select from zvp_onb_cotype
{
      @ObjectModel.text.element: ['Description']
  key company_type as CompanyType,
      description  as Description,
      sort_order   as SortOrder
}
