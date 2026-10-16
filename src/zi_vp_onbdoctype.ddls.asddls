@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor onboarding document types'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_VP_OnbDocType
  as select from zvp_onb_doctype
{
      @ObjectModel.text.element: ['Description']
  key doc_type        as DocType,
      description     as Description,
      is_mandatory    as IsMandatory,
      expiry_required as ExpiryRequired,
      sort_order      as SortOrder
}
