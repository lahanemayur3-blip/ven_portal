@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VP BO - Advance shipping notice (root)'
define root view entity ZI_VP_Asn
  as select from zvp_asn_hdr         as Asn
    inner join   ZI_VP_CurrentSupplier as Cur on Cur.Supplier = Asn.supplier
  composition [0..*] of ZI_VP_AsnItem as _Items
{
  key Asn.asn_uuid               as AsnUUID,
      Asn.asn_number             as AsnNumber,
      Asn.supplier               as Supplier,
      Asn.dispatch_date          as DispatchDate,
      Asn.expected_delivery_date as ExpectedDeliveryDate,
      Asn.transporter            as Transporter,
      Asn.vehicle_number         as VehicleNumber,
      Asn.lr_number              as LrNumber,
      Asn.package_count          as PackageCount,
      Asn.weight_kg              as WeightKg,
      Asn.sending_location       as SendingLocation,
      Asn.receiving_plant        as ReceivingPlant,
      Asn.receiving_plant_name   as ReceivingPlantName,
      Asn.po_count               as PoCount,
      Asn.item_count             as ItemCount,
      Asn.status                 as Status,
      Asn.file_name              as FileName,
      Asn.mime_type              as MimeType,
      Asn.file_content           as FileContent,
      @Semantics.user.createdBy: true
      Asn.local_created_by       as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Asn.local_created_at       as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      Asn.local_last_changed_by  as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Asn.local_last_changed_at  as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      Asn.last_changed_at        as LastChangedAt,

      _Items
}
