// Region (state) value help on the released view I_RegionText (check release state in ADT)
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor onboarding - regions'
define view entity ZI_VP_RegionVH
  as select from I_RegionText
{
  key Country,
      @ObjectModel.text.element: ['RegionName']
  key Region,
      RegionName
}
where
  Language = $session.system_language
