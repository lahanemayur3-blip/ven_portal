"! Deletes ALL data from the custom tables of the vendor onboarding,
"! approver and vendor portal apps (current client only).
"! Safety: nothing happens until gc_confirm = abap_true.
"! Run with F9 (Run As > ABAP Application (Console)).
CLASS zcl_vp_clear_data DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS:
      gc_confirm        TYPE abap_boolean VALUE abap_true,  " set abap_true to really delete
      gc_include_config TYPE abap_boolean VALUE abap_false,  " also clear ZVP_ONB_DOCTYPE / ZVP_ONB_COTYPE
      gc_include_usrmap TYPE abap_boolean VALUE abap_true.   " also clear ZVP_USER_MAP

ENDCLASS.


CLASS zcl_vp_clear_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    IF gc_confirm = abap_false.
      out->write( 'Nothing deleted. Set gc_confirm = abap_true, activate and run again.' ).
      RETURN.
    ENDIF.

    "--- Onboarding / approver
    DELETE FROM zvp_onb_doc.
    out->write( |ZVP_ONB_DOC      : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_onb_hist.
    out->write( |ZVP_ONB_HIST     : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_onb_app.
    out->write( |ZVP_ONB_APP      : { sy-dbcnt } rows deleted| ).

    "--- Vendor portal
    DELETE FROM zvp_po_ack_itm.
    out->write( |ZVP_PO_ACK_ITM   : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_po_ack.
    out->write( |ZVP_PO_ACK       : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_po_chgreq.
    out->write( |ZVP_PO_CHGREQ    : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_asn_itm.
    out->write( |ZVP_ASN_ITM      : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_asn_hdr.
    out->write( |ZVP_ASN_HDR      : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_inv_itm.
    out->write( |ZVP_INV_ITM      : { sy-dbcnt } rows deleted| ).
    DELETE FROM zvp_inv_hdr.
    out->write( |ZVP_INV_HDR      : { sy-dbcnt } rows deleted| ).

    "--- Shared
    DELETE FROM zvp_activity.
    out->write( |ZVP_ACTIVITY     : { sy-dbcnt } rows deleted| ).

    IF gc_include_usrmap = abap_true.
      DELETE FROM zvp_user_map.
      out->write( |ZVP_USER_MAP     : { sy-dbcnt } rows deleted| ).
    ELSE.
      out->write( 'ZVP_USER_MAP     : kept' ).
    ENDIF.

    "--- Configuration (refill with ZCL_VP_ONB_SETUP)
    IF gc_include_config = abap_true.
      DELETE FROM zvp_onb_doctype.
      out->write( |ZVP_ONB_DOCTYPE  : { sy-dbcnt } rows deleted| ).
*      DELETE FROM zvp_onb_cotype.
*      out->write( |ZVP_ONB_COTYPE   : { sy-dbcnt } rows deleted| ).
    ELSE.
      out->write( 'ZVP_ONB_DOCTYPE / ZVP_ONB_COTYPE: kept' ).
    ENDIF.

    COMMIT WORK.
    out->write( 'Done.' ).

  ENDMETHOD.

ENDCLASS.
