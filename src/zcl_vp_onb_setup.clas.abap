*&---------------------------------------------------------------------*
*& ZCL_VP_ONB_SETUP - configuration for vendor onboarding
*& ADT: New > ABAP Class, paste, activate, run with F9 (re-runnable).
*& Fills ZVP_ONB_DOCTYPE and ZVP_ONB_COTYPE.
*&---------------------------------------------------------------------*
CLASS zcl_vp_onb_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_vp_onb_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA lt_doctype TYPE STANDARD TABLE OF zvp_onb_doctype WITH EMPTY KEY.
    DATA lt_cotype  TYPE STANDARD TABLE OF zvp_onb_cotype  WITH EMPTY KEY.

    "                 type          description                        mandatory   expiry
    lt_doctype = VALUE #(
      ( doc_type = 'GST'       description = 'GST Certificate'                 is_mandatory = abap_true  expiry_required = abap_false sort_order = 10 )
      ( doc_type = 'PAN'       description = 'PAN Card'                        is_mandatory = abap_true  expiry_required = abap_false sort_order = 20 )
      ( doc_type = 'CHEQUE'    description = 'Bank Proof (Cancelled Cheque)'   is_mandatory = abap_true  expiry_required = abap_false sort_order = 30 )
      ( doc_type = 'MSME'      description = 'MSME Certificate'                is_mandatory = abap_false expiry_required = abap_true  sort_order = 40 )
      ( doc_type = 'INSURANCE' description = 'Insurance Certificate'           is_mandatory = abap_false expiry_required = abap_true  sort_order = 50 )
      ( doc_type = 'ISO9001'   description = 'ISO 9001 Certification'          is_mandatory = abap_false expiry_required = abap_true  sort_order = 60 )
      ( doc_type = 'OTHER'     description = 'Other document'                  is_mandatory = abap_false expiry_required = abap_false sort_order = 99 ) ).

    lt_cotype = VALUE #(
      ( company_type = 'PL' description = 'Private Limited' sort_order = 10 )
      ( company_type = 'PU' description = 'Public Limited'  sort_order = 20 )
      ( company_type = 'PA' description = 'Partnership'     sort_order = 30 )
      ( company_type = 'PR' description = 'Proprietorship'  sort_order = 40 ) ).

    MODIFY zvp_onb_doctype FROM TABLE @lt_doctype.
    MODIFY zvp_onb_cotype  FROM TABLE @lt_cotype.
    COMMIT WORK.

    out->write( |ZVP_ONB_DOCTYPE: { lines( lt_doctype ) } rows| ).
    out->write( |ZVP_ONB_COTYPE : { lines( lt_cotype ) } rows| ).
  ENDMETHOD.

ENDCLASS.

