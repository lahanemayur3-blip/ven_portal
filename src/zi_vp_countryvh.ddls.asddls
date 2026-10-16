// Country value help on the released view I_CountryText (check release state in ADT)
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor onboarding - countries'
define view entity ZI_VP_CountryVH
  as select from I_CountryText
{
      @ObjectModel.text.element: ['CountryName']
  key Country,
      CountryName
}
where
  Language = $session.system_language
