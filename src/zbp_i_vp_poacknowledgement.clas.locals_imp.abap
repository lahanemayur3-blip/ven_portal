CLASS lhc_PoAck DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PoAck RESULT result.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PoAck~setDefaults.
    METHODS validatePurchaseOrder FOR VALIDATE ON SAVE
      IMPORTING keys FOR PoAck~validatePurchaseOrder.
ENDCLASS.

CLASS lhc_PoAck IMPLEMENTATION.

  METHOD get_global_authorizations.
    " only mapped portal users may create
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = COND #( WHEN zcl_vp_util=>current_supplier( ) IS INITIAL
                               THEN if_abap_behv=>auth-unauthorized
                               ELSE if_abap_behv=>auth-allowed ).
    ENDIF.
  ENDMETHOD.

  METHOD setDefaults.
    DATA(lv_supplier) = zcl_vp_util=>current_supplier( ).
    MODIFY ENTITIES OF zi_vp_poacknowledgement IN LOCAL MODE
      ENTITY PoAck
        UPDATE FIELDS ( Supplier Status AllMatch )
        WITH VALUE #( FOR key IN keys
                      ( %tky     = key-%tky
                        Supplier = lv_supplier
                        Status   = 'N'          " your initial status
                        AllMatch = abap_false ) ).
  ENDMETHOD.

  METHOD validatePurchaseOrder.
    READ ENTITIES OF zi_vp_poacknowledgement IN LOCAL MODE
      ENTITY PoAck
        FIELDS ( PurchaseOrder ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_ack).

    LOOP AT lt_ack INTO DATA(ls_ack).
      IF zcl_vp_util=>po_accessible( CONV #( ls_ack-PurchaseOrder ) ) = abap_false.
        APPEND VALUE #( %tky = ls_ack-%tky ) TO failed-poack.
        APPEND VALUE #( %tky = ls_ack-%tky
                        %element-PurchaseOrder = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Purchase order { ls_ack-PurchaseOrder } is not accessible| ) )
               TO reported-poack.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_PoAckItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateItem FOR VALIDATE ON SAVE
      IMPORTING keys FOR PoAckItem~validateItem.
ENDCLASS.

CLASS lhc_PoAckItem IMPLEMENTATION.
  METHOD validateItem.
    READ ENTITIES OF zi_vp_poacknowledgement IN LOCAL MODE
      ENTITY PoAckItem
        FIELDS ( ConfirmedQuantity ConfirmedDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-ConfirmedQuantity <= 0.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-poackitem.
        APPEND VALUE #( %tky = ls_item-%tky
                        %element-ConfirmedQuantity = if_abap_behv=>mk-on
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Confirmed quantity must be greater than 0' ) )
               TO reported-poackitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lsc_zi_vp_poacknowledgement DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_vp_poacknowledgement IMPLEMENTATION.
  METHOD save_modified.
    " additional save: log an activity row per created acknowledgement
    DATA lt_activity TYPE STANDARD TABLE OF zvp_activity WITH EMPTY KEY.
    LOOP AT create-poack INTO DATA(ls_new).
      APPEND zcl_vp_util=>new_activity(
               iv_supplier = ls_new-Supplier
               iv_text     = |Acknowledgement created for PO { ls_new-PurchaseOrder }|
               iv_type     = 'PO_ACK'
               iv_id       = CONV #( ls_new-PurchaseOrder ) ) TO lt_activity.
    ENDLOOP.
    IF lt_activity IS NOT INITIAL.
      INSERT zvp_activity FROM TABLE @lt_activity.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
