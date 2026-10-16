@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor onboarding document'
define view entity ZI_VP_OnbDocument
  as select from zvp_onb_doc
  association        to parent ZI_VP_OnbApplication as _Application on $projection.AppUuid = _Application.AppUuid
  association [0..1] to ZI_VP_OnbDocType            as _DocType     on $projection.DocType = _DocType.DocType
{
  key doc_uuid              as DocUuid,
      app_uuid              as AppUuid,
      doc_type              as DocType,
      doc_name              as DocName,
      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        contentDispositionPreference: #INLINE
      }
      file_content          as FileContent,
      @Semantics.mimeType: true
      mime_type             as MimeType,
      file_name             as FileName,
      expiry_date           as ExpiryDate,

      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Application,
      _DocType
}
