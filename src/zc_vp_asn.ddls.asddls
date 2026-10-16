@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP consumption - ASN'
@Metadata.allowExtensions: true
define root view entity ZC_VP_Asn
  provider contract transactional_query
  as projection on ZI_VP_Asn
{
  key AsnUUID,
      AsnNumber,
      DispatchDate,
      ExpectedDeliveryDate,
      PoCount,
      ItemCount,
      Transporter,
      VehicleNumber,
      LrNumber,
      PackageCount,
      WeightKg,
      SendingLocation,
      ReceivingPlant,
      ReceivingPlantName,
      Status,
      FileName,
      MimeType,
      FileContent,
      CreatedAt,

      _Items : redirected to composition child ZC_VP_AsnItem
}
