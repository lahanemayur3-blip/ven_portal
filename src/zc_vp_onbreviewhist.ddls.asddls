@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor onboarding history (reviewer)'
@UI.headerInfo: { typeName: 'Status Change', typeNamePlural: 'Status History' }
@UI.presentationVariant: [{ sortOrder: [{ by: 'ChangedAt', direction: #DESC }] }]
define view entity ZC_VP_OnbReviewHist
  as projection on ZI_VP_OnbHistory
{
      @UI.hidden: true
  key HistUuid,
      @UI.hidden: true
      AppUuid,
      @UI.lineItem: [{ position: 10, label: 'From' }]
      StatusFrom,
      @UI.lineItem: [{ position: 20, label: 'To' }]
      StatusTo,
      @UI.lineItem: [{ position: 30, label: 'Comment' }]
      Comment1,
      @UI.lineItem: [{ position: 40, label: 'Changed By' }]
      ChangedBy,
      @UI.lineItem: [{ position: 50, label: 'Changed At' }]
      ChangedAt,

      _Application : redirected to parent ZC_VP_OnbReview
}
