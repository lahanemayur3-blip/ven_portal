CLASS lhc_PoChange DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PoChange RESULT result.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PoChange~setDefaults.
    METHODS validatePurchaseOrder FOR VALIDATE ON SAVE
      IMPORTING keys FOR PoChange~validatePurchaseOrder.
ENDCLASS.

CLASS lhc_PoChange IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = COND #( WHEN zcl_vp_util=>current_supplier( ) IS NOT INITIAL
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.

  METHOD setDefaults.
    DATA(lv_supplier) = zcl_vp_util=>current_supplier( ).
    MODIFY ENTITIES OF zi_vp_pochangerequest IN LOCAL MODE
      ENTITY PoChange UPDATE FIELDS ( Supplier Status )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky Supplier = lv_supplier Status = 'Pending' ) ).
  ENDMETHOD.

  METHOD validatePurchaseOrder.
    READ ENTITIES OF zi_vp_pochangerequest IN LOCAL MODE
      ENTITY PoChange FIELDS ( PurchaseOrder RequestText ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chg).

    LOOP AT lt_chg ASSIGNING FIELD-SYMBOL(<chg>).
      DATA(lv_text) = condense( <chg>-RequestText ).

      IF zcl_vp_util=>po_accessible( <chg>-PurchaseOrder ) = abap_false.
        APPEND VALUE #( %tky = <chg>-%tky ) TO failed-pochange.
        APPEND VALUE #( %tky = <chg>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Purchase order { <chg>-PurchaseOrder } does not exist or is not yours| )
                        %element-PurchaseOrder = if_abap_behv=>mk-on ) TO reported-pochange.
      ELSEIF lv_text IS INITIAL.
        APPEND VALUE #( %tky = <chg>-%tky ) TO failed-pochange.
        APPEND VALUE #( %tky = <chg>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Please describe the change you need' )
                        %element-RequestText = if_abap_behv=>mk-on ) TO reported-pochange.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_zi_vp_pochangerequest DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_vp_pochangerequest IMPLEMENTATION.

  METHOD save_modified.
    DATA lt_activity TYPE STANDARD TABLE OF zvp_activity WITH EMPTY KEY.

    LOOP AT create-pochange ASSIGNING FIELD-SYMBOL(<new>).
      APPEND zcl_vp_util=>new_activity(
        iv_supplier = <new>-Supplier
        iv_text     = |Change requested on PO { <new>-PurchaseOrder }|
        iv_type     = 'PO'
        iv_id       = CONV #( <new>-PurchaseOrder ) ) TO lt_activity.
    ENDLOOP.

    IF lt_activity IS NOT INITIAL.
      INSERT zvp_activity FROM TABLE @lt_activity.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

