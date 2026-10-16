"! One-time setup. Run from ADT with F9 (Run As > ABAP Application (Console)).
"! 1) creates the number range intervals for ZVP_ASN and ZVP_INV
"! 2) maps a portal user to a supplier in ZVP_USER_MAP
"! EDIT THE CONSTANTS BELOW BEFORE RUNNING. Safe to run again.
CLASS zcl_vp_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS:
      gc_portal_user        TYPE zvp_user_map-user_id      VALUE '',            " blank = user who runs this class
      gc_supplier           TYPE zvp_user_map-supplier     VALUE '0000100234',  " EDIT: supplier number (10 digits)
      gc_company_code       TYPE zvp_user_map-company_code VALUE '1010',        " EDIT: company code
      gc_payment_terms_days TYPE zvp_user_map-payment_terms_days VALUE 30.

ENDCLASS.


CLASS zcl_vp_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    " ---- 1) number range intervals ------------------------------------
    TRY.
        cl_numberrange_intervals=>create(
          EXPORTING interval = VALUE #( ( nrrangenr = '01' fromnumber = '0000008001' tonumber = '0000099999' ) )
                    object   = 'ZVP_ASN'
          IMPORTING error    = DATA(lv_error_asn) ).
        out->write( |ZVP_ASN interval 01 created (error flag = { lv_error_asn }; 'X' usually means it already exists)| ).
      CATCH cx_root INTO DATA(lx_asn).
        out->write( |ZVP_ASN: { lx_asn->get_text( ) } - did you create the number range object ZVP_ASN?| ).
    ENDTRY.

    TRY.
        cl_numberrange_intervals=>create(
          EXPORTING interval = VALUE #( ( nrrangenr = '01' fromnumber = '0000003001' tonumber = '0000099999' ) )
                    object   = 'ZVP_INV'
          IMPORTING error    = DATA(lv_error_inv) ).
        out->write( |ZVP_INV interval 01 created (error flag = { lv_error_inv }; 'X' usually means it already exists)| ).
      CATCH cx_root INTO DATA(lx_inv).
        out->write( |ZVP_INV: { lx_inv->get_text( ) } - did you create the number range object ZVP_INV?| ).
    ENDTRY.

    " ---- 2) user -> supplier mapping ----------------------------------
    DATA lv_user TYPE zvp_user_map-user_id.
    lv_user = COND #( WHEN gc_portal_user IS NOT INITIAL
                      THEN gc_portal_user
                      ELSE cl_abap_context_info=>get_user_technical_name( ) ).

    DATA(ls_map) = VALUE zvp_user_map( user_id            = lv_user
                                       supplier           = gc_supplier
                                       company_code       = gc_company_code
                                       payment_terms_days = gc_payment_terms_days
                                       is_active          = 'X'
                                       valid_from         = '20200101'
                                       valid_to           = '99991231' ).
    MODIFY zvp_user_map FROM @ls_map.
    IF sy-subrc = 0.
      out->write( |User { lv_user } mapped to supplier { gc_supplier } / company code { gc_company_code }| ).
    ELSE.
      out->write( |Could not write ZVP_USER_MAP (sy-subrc = { sy-subrc })| ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.

