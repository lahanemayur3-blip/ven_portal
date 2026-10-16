CLASS lhc_invoice DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR invoice RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR invoice RESULT result.
    METHODS setdefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR invoice~setdefaults.
    METHODS validateheader FOR VALIDATE ON SAVE
      IMPORTING keys FOR invoice~validateheader.
    METHODS resubmit FOR MODIFY
      IMPORTING keys FOR ACTION invoice~resubmit RESULT result.
ENDCLASS.

CLASS lhc_invoice IMPLEMENTATION.

  METHOD get_global_authorizations.
    DATA(lv_is_portal_user) = xsdbool( zcl_vp_util=>current_supplier( ) IS NOT INITIAL ).
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = COND #( WHEN lv_is_portal_user = abap_true
                               THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = COND #( WHEN lv_is_portal_user = abap_true
                               THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
    IF requested_authorizations-%action-resubmit = if_abap_behv=>mk-on.
      result-%action-resubmit = COND #( WHEN lv_is_portal_user = abap_true
                                        THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
    DATA lv_fc TYPE abp_behv_flag.

    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoice FIELDS ( status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_inv).

    LOOP AT lt_inv ASSIGNING FIELD-SYMBOL(<inv>).
      lv_fc = COND #( WHEN <inv>-status = 'Rejected'
                      THEN if_abap_behv=>fc-o-enabled
                      ELSE if_abap_behv=>fc-o-disabled ).
      APPEND VALUE #( %tky = <inv>-%tky
                      %update = lv_fc
                      %action-resubmit = lv_fc ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD setdefaults.
    DATA(lv_supplier) = zcl_vp_util=>current_supplier( ).

    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoice FIELDS ( purchaseorder ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_inv).

    LOOP AT lt_inv ASSIGNING FIELD-SYMBOL(<inv>).
      DATA(lv_id) = zcl_vp_util=>next_invoice_id( ).
      IF lv_id IS INITIAL.
        IF lv_id IS INITIAL.
          APPEND VALUE #( %tky = <inv>-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'Number range object ZVP_INV is not configured (run ZCL_VP_SETUP)' ) )
            TO reported-invoice.
          CONTINUE.
        ENDIF.
        APPEND VALUE #( %tky = <inv>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Number range object ZVP_INV is not configured (run ZCL_VP_SETUP)' ) )
          TO reported-invoice.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zi_vp_invoice IN LOCAL MODE
        ENTITY invoice UPDATE FIELDS ( supplier invoiceid status currency )
        WITH VALUE #( ( %tky      = <inv>-%tky
                        supplier  = lv_supplier
                        invoiceid = lv_id
                        status    = 'Submitted'
                        currency  = zcl_vp_util=>po_currency( <inv>-purchaseorder ) ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD validateheader.
    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoice
        FIELDS ( supplier vendorinvoicenumber purchaseorder invoicedate duedate filecontent )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_inv)
      ENTITY invoice BY \_items FIELDS ( purchaseorderitem )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_item) LINK DATA(lt_link).

    LOOP AT lt_inv ASSIGNING FIELD-SYMBOL(<inv>).
      DATA(lv_error) = ``.

      IF zcl_vp_util=>po_accessible( <inv>-purchaseorder ) = abap_false.
        lv_error = |Purchase order { <inv>-purchaseorder } does not exist or is not yours|.
      ELSEIF <inv>-vendorinvoicenumber IS INITIAL.
        lv_error = 'Invoice number is required'.
      ELSEIF <inv>-invoicedate IS INITIAL OR <inv>-duedate IS INITIAL.
        lv_error = 'Invoice date and due date are required'.
      ELSEIF <inv>-duedate < <inv>-invoicedate.
        lv_error = 'Due date cannot be before the invoice date'.
      ELSEIF <inv>-filecontent IS INITIAL.
        lv_error = 'Please attach the invoice document'.
      ELSEIF xstrlen( <inv>-filecontent ) > 5000000.
        lv_error = 'The attachment is larger than 5 MB'.
      ELSEIF NOT line_exists( lt_link[ source-invoiceuuid = <inv>-invoiceuuid ] ).
        lv_error = 'Add at least one invoice line'.
      ELSE.
        SELECT SINGLE invoice_uuid FROM zvp_inv_hdr
          WHERE supplier              = @<inv>-supplier
            AND vendor_invoice_number = @<inv>-vendorinvoicenumber
            AND invoice_uuid         <> @<inv>-invoiceuuid
            AND status               <> 'Rejected'
          INTO @DATA(lv_duplicate).
        IF sy-subrc = 0.
          lv_error = |Invoice number { <inv>-vendorinvoicenumber } has already been submitted|.
        ENDIF.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = <inv>-%tky ) TO failed-invoice.
        APPEND VALUE #( %tky = <inv>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = lv_error ) )
          TO reported-invoice.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD resubmit.
    MODIFY ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoice UPDATE FIELDS ( status rejectionreason )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky status = 'Submitted' rejectionreason = `` ) ).

    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoice ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_inv).

    result = VALUE #( FOR inv IN lt_inv ( %tky = inv-%tky %param = inv ) ).
  ENDMETHOD.

ENDCLASS.


CLASS lhc_invoiceitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR invoiceitem RESULT result.
    METHODS calculateamounts FOR DETERMINE ON MODIFY
      IMPORTING keys FOR invoiceitem~calculateamounts.
    METHODS validateitem FOR VALIDATE ON SAVE
      IMPORTING keys FOR invoiceitem~validateitem.
    METHODS net_of
      IMPORTING iv_quantity   TYPE zvp_inv_itm-quantity
                iv_rate       TYPE zvp_inv_itm-rate
      RETURNING VALUE(rv_net) TYPE zvp_inv_itm-net_amount.
ENDCLASS.

CLASS lhc_invoiceitem IMPLEMENTATION.

  METHOD net_of.
    rv_net = round( val = iv_quantity * iv_rate dec = 2 ).
  ENDMETHOD.

  METHOD get_instance_features.
    DATA lv_fc TYPE abp_behv_flag.

    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoiceitem BY \_invoice FIELDS ( status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_inv) LINK DATA(lt_link).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      lv_fc = if_abap_behv=>fc-o-disabled.
      ASSIGN lt_link[ source-invoiceitemuuid = <key>-invoiceitemuuid ] TO FIELD-SYMBOL(<link>).
      IF sy-subrc = 0.
        ASSIGN lt_inv[ invoiceuuid = <link>-target-invoiceuuid ] TO FIELD-SYMBOL(<inv>).
        IF sy-subrc = 0 AND <inv>-status = 'Rejected'.
          lv_fc = if_abap_behv=>fc-o-enabled.
        ENDIF.
      ENDIF.
      APPEND VALUE #( %tky = <key>-%tky %update = lv_fc ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD calculateamounts.
    DATA lt_invoice TYPE SORTED TABLE OF zvp_inv_itm-invoice_uuid WITH UNIQUE KEY table_line.
    DATA lt_upd_item TYPE TABLE FOR UPDATE zi_vp_invoice\\invoiceitem.
    DATA lt_upd_inv  TYPE TABLE FOR UPDATE zi_vp_invoice\\invoice.

    " ---- 1) line net amount + currency -------------------------------------------
    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoiceitem FIELDS ( purchaseorderitem quantity rate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item)
      ENTITY invoiceitem BY \_invoice FIELDS ( purchaseorder ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_parent) LINK DATA(lt_link).

    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<item>).
      DATA(lv_currency) = VALUE zvp_inv_hdr-currency( ).
      ASSIGN lt_link[ source-invoiceitemuuid = <item>-invoiceitemuuid ] TO FIELD-SYMBOL(<link>).
      IF sy-subrc = 0.
        INSERT <link>-target-invoiceuuid INTO TABLE lt_invoice.
        ASSIGN lt_parent[ invoiceuuid = <link>-target-invoiceuuid ] TO FIELD-SYMBOL(<parent>).
        IF sy-subrc = 0.
          lv_currency = zcl_vp_util=>po_currency( <parent>-purchaseorder ).
        ENDIF.
      ENDIF.
      SELECT SINGLE orderunit FROM zi_vp_purchaseorderitem
        WHERE purchaseorder = @<parent>-purchaseorder AND purchaseorderitem = @<item>-purchaseorderitem
        INTO @DATA(lv_unit).
      APPEND VALUE #( %tky      = <item>-%tky
                      netamount = net_of( iv_quantity = <item>-quantity iv_rate = <item>-rate )
                      currency  = lv_currency
                      unit      = lv_unit ) TO lt_upd_item.
    ENDLOOP.

    MODIFY ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoiceitem UPDATE FIELDS ( netamount currency unit ) WITH lt_upd_item.

    " ---- 2) invoice totals (all lines of every touched invoice) -------------------
    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoice BY \_items FIELDS ( quantity rate taxpercent )
      WITH VALUE #( FOR uuid IN lt_invoice ( invoiceuuid = uuid ) )
      RESULT DATA(lt_all) LINK DATA(lt_all_link).

    LOOP AT lt_invoice ASSIGNING FIELD-SYMBOL(<uuid>).
      DATA(lv_net) = VALUE zvp_inv_hdr-net_amount( ).
      DATA(lv_tax) = VALUE zvp_inv_hdr-tax_amount( ).
      LOOP AT lt_all_link ASSIGNING FIELD-SYMBOL(<all_link>) WHERE source-invoiceuuid = <uuid>.
        ASSIGN lt_all[ invoiceitemuuid = <all_link>-target-invoiceitemuuid ] TO FIELD-SYMBOL(<line>).
        IF sy-subrc = 0.
          DATA(lv_line_net) = net_of( iv_quantity = <line>-quantity iv_rate = <line>-rate ).
          lv_net += lv_line_net.
          lv_tax += round( val = lv_line_net * <line>-taxpercent / 100 dec = 2 ).
        ENDIF.
      ENDLOOP.
      APPEND VALUE #( invoiceuuid  = <uuid>
                      netamount    = lv_net
                      taxamount    = lv_tax
                      grossamount  = lv_net + lv_tax ) TO lt_upd_inv.
    ENDLOOP.

    MODIFY ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoice UPDATE FIELDS ( netamount taxamount grossamount ) WITH lt_upd_inv.
  ENDMETHOD.

  METHOD validateitem.
    TYPES: BEGIN OF ty_sum,
             item TYPE zvp_inv_itm-purchase_order_item,
             qty  TYPE zvp_inv_itm-quantity,
           END OF ty_sum.
    DATA lt_sum TYPE SORTED TABLE OF ty_sum WITH UNIQUE KEY item.

    READ ENTITIES OF zi_vp_invoice IN LOCAL MODE
      ENTITY invoiceitem FIELDS ( purchaseorderitem quantity rate taxpercent )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item)
      ENTITY invoiceitem BY \_invoice FIELDS ( purchaseorder )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_parent) LINK DATA(lt_link).

    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<item>).
      ASSIGN lt_sum[ item = <item>-purchaseorderitem ] TO FIELD-SYMBOL(<sum>).
      IF sy-subrc = 0.
        <sum>-qty += <item>-quantity.
      ELSE.
        INSERT VALUE #( item = <item>-purchaseorderitem qty = <item>-quantity ) INTO TABLE lt_sum.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_item ASSIGNING <item>.
      DATA(lv_error) = ``.
      DATA(lv_po) = VALUE zvp_po_ack-purchase_order( ).
      ASSIGN lt_link[ source-invoiceitemuuid = <item>-invoiceitemuuid ] TO FIELD-SYMBOL(<link>).
      IF sy-subrc = 0.
        lv_po = VALUE #( lt_parent[ invoiceuuid = <link>-target-invoiceuuid ]-purchaseorder OPTIONAL ).
      ENDIF.

      IF <item>-quantity <= 0.
        lv_error = |Item { <item>-purchaseorderitem }: quantity must be greater than zero|.
      ELSEIF <item>-rate <= 0.
        lv_error = |Item { <item>-purchaseorderitem }: rate must be greater than zero|.
      ELSEIF <item>-taxpercent < 0 OR <item>-taxpercent > 100.
        lv_error = |Item { <item>-purchaseorderitem }: tax % must be between 0 and 100|.
      ELSE.
        SELECT SINGLE shippednotinvoicedquantity FROM zi_vp_invoiceeligibleitem
          WHERE purchaseorder = @lv_po AND purchaseorderitem = @<item>-purchaseorderitem
          INTO @DATA(lv_open).
        IF sy-subrc <> 0.
          lv_error = |Item { <item>-purchaseorderitem } has no shipped quantity left to invoice|.
        ELSEIF lt_sum[ item = <item>-purchaseorderitem ]-qty > lv_open.
          lv_error = |Item { <item>-purchaseorderitem }: quantity exceeds the shipped, not yet invoiced quantity|.
        ENDIF.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = <item>-%tky ) TO failed-invoiceitem.
        APPEND VALUE #( %tky = <item>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = lv_error ) )
          TO reported-invoiceitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_zi_vp_invoice DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_vp_invoice IMPLEMENTATION.

  METHOD save_modified.
    DATA lt_activity TYPE STANDARD TABLE OF zvp_activity WITH EMPTY KEY.

    LOOP AT create-invoice ASSIGNING FIELD-SYMBOL(<new>).
      APPEND zcl_vp_util=>new_activity(
        iv_supplier = <new>-supplier
        iv_text     = |Invoice { <new>-invoiceid } submitted for PO { <new>-purchaseorder }|
        iv_type     = 'INVOICE'
        iv_id       = CONV #( <new>-invoiceid ) ) TO lt_activity.
    ENDLOOP.

    " resubmission = update that sets Status back to 'Submitted'
    LOOP AT update-invoice ASSIGNING FIELD-SYMBOL(<upd>) WHERE %control-status = if_abap_behv=>mk-on.
      IF <upd>-status = 'Submitted'.
        SELECT SINGLE supplier, invoice_id FROM zvp_inv_hdr
          WHERE invoice_uuid = @<upd>-invoiceuuid
          INTO @DATA(ls_hdr).
        IF sy-subrc = 0.
          APPEND zcl_vp_util=>new_activity(
            iv_supplier = ls_hdr-supplier
            iv_text     = |Invoice { ls_hdr-invoice_id } resubmitted|
            iv_type     = 'INVOICE'
            iv_id       = CONV #( ls_hdr-invoice_id ) ) TO lt_activity.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF lt_activity IS NOT INITIAL.
      INSERT zvp_activity FROM TABLE @lt_activity.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

