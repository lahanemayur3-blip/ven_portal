CLASS zcl_vp_util DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      "! Supplier mapped to the logged-on user (blank = not a portal user)
      current_supplier
        RETURNING VALUE(rv_supplier) TYPE zvp_user_map-supplier,

      "! abap_true if the PO belongs to the logged-on supplier
      po_accessible
        IMPORTING iv_po        TYPE zvp_po_ack-purchase_order
        RETURNING VALUE(rv_ok) TYPE abap_boolean,

      po_currency
        IMPORTING iv_po              TYPE zvp_po_ack-purchase_order
        RETURNING VALUE(rv_currency) TYPE zvp_inv_hdr-currency,

      "! Next ASN number from number range object ZVP_ASN (blank if not configured)
      next_asn_number
        RETURNING VALUE(rv_number) TYPE zvp_asn_hdr-asn_number,

      "! Next invoice id from number range object ZVP_INV (blank if not configured)
      next_invoice_id
        RETURNING VALUE(rv_id) TYPE zvp_inv_hdr-invoice_id,

      "! Builds a row for ZVP_ACTIVITY (caller inserts it in the save phase)
      new_activity
        IMPORTING iv_supplier        TYPE zvp_activity-supplier
                  iv_text            TYPE zvp_activity-activity_text
                  iv_type            TYPE zvp_activity-related_object_type
                  iv_id              TYPE zvp_activity-related_object_id
        RETURNING VALUE(rs_activity) TYPE zvp_activity.

ENDCLASS.


CLASS zcl_vp_util IMPLEMENTATION.

  METHOD current_supplier.
    SELECT SINGLE Supplier FROM ZI_VP_CurrentSupplier INTO @rv_supplier.
  ENDMETHOD.

  METHOD po_accessible.
    SELECT SINGLE po~PurchaseOrder
      FROM I_PurchaseOrderAPI01 AS po
      INNER JOIN ZI_VP_CurrentSupplier AS cur ON cur~Supplier = po~Supplier
      WHERE po~PurchaseOrder = @iv_po
      INTO @DATA(lv_po).
    rv_ok = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD po_currency.
    SELECT SINGLE DocumentCurrency FROM I_PurchaseOrderAPI01
      WHERE PurchaseOrder = @iv_po
      INTO @rv_currency.
  ENDMETHOD.

  METHOD next_asn_number.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING nr_range_nr = '01'
                    object      = 'ZVP_ASN'
          IMPORTING number      = DATA(lv_number) ).
        rv_number = |ASN{ lv_number ALPHA = OUT }|.
      CATCH cx_number_ranges.
        CLEAR rv_number.
    ENDTRY.
  ENDMETHOD.

  METHOD next_invoice_id.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING nr_range_nr = '01'
                    object      = 'ZVP_INV'
          IMPORTING number      = DATA(lv_number) ).
        rv_id = |INV-{ lv_number ALPHA = OUT }|.
      CATCH cx_number_ranges.
        CLEAR rv_id.
    ENDTRY.
  ENDMETHOD.

  METHOD new_activity.
    TRY.
        rs_activity-activity_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        " leave initial - insert would fail visibly
    ENDTRY.
    rs_activity-supplier            = iv_supplier.
    rs_activity-activity_text       = iv_text.
    rs_activity-related_object_type = iv_type.
    rs_activity-related_object_id   = iv_id.
    rs_activity-created_by          = cl_abap_context_info=>get_user_technical_name( ).
    GET TIME STAMP FIELD rs_activity-created_at.
  ENDMETHOD.

ENDCLASS.
