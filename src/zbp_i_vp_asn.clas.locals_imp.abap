CLASS lhc_asn DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR asn RESULT result.
    METHODS setdefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR asn~setdefaults.
    METHODS calculatecounts FOR DETERMINE ON MODIFY
      IMPORTING keys FOR asn~calculatecounts.
    METHODS validateheader FOR VALIDATE ON SAVE
      IMPORTING keys FOR asn~validateheader.
ENDCLASS.

CLASS lhc_asn IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = COND #( WHEN zcl_vp_util=>current_supplier( ) IS NOT INITIAL
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.

  METHOD setdefaults.
    DATA(lv_supplier) = zcl_vp_util=>current_supplier( ).

    READ ENTITIES OF zi_vp_asn IN LOCAL MODE
      ENTITY asn FIELDS ( receivingplant ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_asn).

    LOOP AT lt_asn ASSIGNING FIELD-SYMBOL(<asn>).
      DATA(lv_number) = zcl_vp_util=>next_asn_number( ).
      IF lv_number IS INITIAL.
        APPEND VALUE #( %tky = <asn>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Number range object ZVP_ASN is not configured (run ZCL_VP_SETUP)' ) )
          TO reported-asn.
        CONTINUE.
      ENDIF.

      SELECT SINGLE plantname FROM i_plant
        WHERE plant = @<asn>-receivingplant
        INTO @DATA(lv_plant_name).

      MODIFY ENTITIES OF zi_vp_asn IN LOCAL MODE
        ENTITY asn UPDATE FIELDS ( supplier asnnumber status receivingplantname )
        WITH VALUE #( ( %tky               = <asn>-%tky
                        supplier           = lv_supplier
                        asnnumber          = lv_number
                        status             = 'Submitted to Business'
                        receivingplantname = lv_plant_name ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD calculatecounts.
    DATA lt_po TYPE SORTED TABLE OF zvp_asn_itm-purchase_order WITH UNIQUE KEY table_line.

    READ ENTITIES OF zi_vp_asn IN LOCAL MODE
      ENTITY asn BY \_items FIELDS ( purchaseorder ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item) LINK DATA(lt_link).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      CLEAR lt_po.
      DATA(lv_items) = 0.
      LOOP AT lt_link ASSIGNING FIELD-SYMBOL(<link>) WHERE source-asnuuid = <key>-asnuuid.
        lv_items += 1.
        ASSIGN lt_item[ asnitemuuid = <link>-target-asnitemuuid ] TO FIELD-SYMBOL(<item>).
        IF sy-subrc = 0.
          INSERT <item>-purchaseorder INTO TABLE lt_po.
        ENDIF.
      ENDLOOP.

      MODIFY ENTITIES OF zi_vp_asn IN LOCAL MODE
        ENTITY asn UPDATE FIELDS ( pocount itemcount )
        WITH VALUE #( ( %tky = <key>-%tky pocount = lines( lt_po ) itemcount = lv_items ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD validateheader.
    READ ENTITIES OF zi_vp_asn IN LOCAL MODE
      ENTITY asn FIELDS ( dispatchdate expecteddeliverydate receivingplant filecontent )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_asn)
      ENTITY asn BY \_items FIELDS ( purchaseorder )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item) LINK DATA(lt_link).

    LOOP AT lt_asn ASSIGNING FIELD-SYMBOL(<asn>).
      DATA(lv_error) = ``.

      IF <asn>-expecteddeliverydate < <asn>-dispatchdate.
        lv_error = 'Expected delivery date cannot be before the dispatch date'.
      ELSEIF xstrlen( <asn>-filecontent ) > 5000000.
        lv_error = 'The attachment is larger than 5 MB'.
      ELSE.
        SELECT SINGLE plant FROM i_plant WHERE plant = @<asn>-receivingplant INTO @DATA(lv_plant).
        IF sy-subrc <> 0.
          lv_error = |Receiving plant { <asn>-receivingplant } does not exist|.
        ELSEIF NOT line_exists( lt_link[ source-asnuuid = <asn>-asnuuid ] ).
          lv_error = 'Add at least one item to the ASN'.
        ENDIF.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = <asn>-%tky ) TO failed-asn.
        APPEND VALUE #( %tky = <asn>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = lv_error ) )
          TO reported-asn.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_asnitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS fillitem FOR DETERMINE ON MODIFY
      IMPORTING keys FOR asnitem~fillitem.
    METHODS validateitem FOR VALIDATE ON SAVE
      IMPORTING keys FOR asnitem~validateitem.
ENDCLASS.

CLASS lhc_asnitem IMPLEMENTATION.

  METHOD fillitem.
    DATA lt_upd TYPE TABLE FOR UPDATE zi_vp_asn\\asnitem.

    READ ENTITIES OF zi_vp_asn IN LOCAL MODE
      ENTITY asnitem FIELDS ( purchaseorder purchaseorderitem ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<item>).
      SELECT SINGLE material, materialdescription, orderunit
        FROM zi_vp_purchaseorderitem
        WHERE purchaseorder = @<item>-purchaseorder AND purchaseorderitem = @<item>-purchaseorderitem
        INTO @DATA(ls_po).
      IF sy-subrc = 0.
        APPEND VALUE #( %tky                = <item>-%tky
                        material            = ls_po-material
                        materialdescription = ls_po-materialdescription
                        unit                = ls_po-orderunit ) TO lt_upd.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zi_vp_asn IN LOCAL MODE
      ENTITY asnitem UPDATE FIELDS ( material materialdescription unit ) WITH lt_upd.
  ENDMETHOD.

  METHOD validateitem.
    TYPES: BEGIN OF ty_sum,
             po   TYPE zvp_asn_itm-purchase_order,
             item TYPE zvp_asn_itm-purchase_order_item,
             qty  TYPE zvp_asn_itm-quantity,
           END OF ty_sum.
    DATA lt_sum TYPE SORTED TABLE OF ty_sum WITH UNIQUE KEY po item.

    READ ENTITIES OF zi_vp_asn IN LOCAL MODE
      ENTITY asnitem FIELDS ( purchaseorder purchaseorderitem quantity )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    " total per PO item over everything created in this request
    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<item>).
      ASSIGN lt_sum[ po = <item>-purchaseorder item = <item>-purchaseorderitem ] TO FIELD-SYMBOL(<sum>).
      IF sy-subrc = 0.
        <sum>-qty += <item>-quantity.
      ELSE.
        INSERT VALUE #( po = <item>-purchaseorder item = <item>-purchaseorderitem qty = <item>-quantity )
          INTO TABLE lt_sum.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_item ASSIGNING <item>.
      DATA(lv_error) = ``.

      IF <item>-quantity <= 0.
        lv_error = |Item { <item>-purchaseorder }/{ <item>-purchaseorderitem }: quantity must be greater than zero|.
      ELSEIF zcl_vp_util=>po_accessible( <item>-purchaseorder ) = abap_false.
        lv_error = |Purchase order { <item>-purchaseorder } does not exist or is not yours|.
      ELSE.
        SELECT SINGLE openquantity FROM zi_vp_asneligibleitem
          WHERE purchaseorder = @<item>-purchaseorder AND purchaseorderitem = @<item>-purchaseorderitem
          INTO @DATA(lv_open).
        IF sy-subrc <> 0.
          lv_error = |Item { <item>-purchaseorder }/{ <item>-purchaseorderitem } has no open confirmed quantity|.
        ELSE.
          DATA(lv_total) = lt_sum[ po = <item>-purchaseorder item = <item>-purchaseorderitem ]-qty.
          IF lv_total > lv_open.
            lv_error = |Item { <item>-purchaseorder }/{ <item>-purchaseorderitem }: quantity exceeds the open quantity|.
          ENDIF.
        ENDIF.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = <item>-%tky ) TO failed-asnitem.
        APPEND VALUE #( %tky = <item>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = lv_error )
                        %element-quantity = if_abap_behv=>mk-on ) TO reported-asnitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_zi_vp_asn DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_vp_asn IMPLEMENTATION.

  METHOD save_modified.
    DATA lt_activity TYPE STANDARD TABLE OF zvp_activity WITH EMPTY KEY.

    LOOP AT create-asn ASSIGNING FIELD-SYMBOL(<new>).
      APPEND zcl_vp_util=>new_activity(
        iv_supplier = <new>-supplier
        iv_text     = |ASN { <new>-asnnumber } submitted|
        iv_type     = 'ASN'
        iv_id       = CONV #( <new>-asnnumber ) ) TO lt_activity.
    ENDLOOP.

    IF lt_activity IS NOT INITIAL.
      INSERT zvp_activity FROM TABLE @lt_activity.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

