"! Back-office helpers that move portal documents through their life cycle.
"! They update the Z tables directly on purpose: the portal business objects only see
"! the rows of the logged-on supplier, so a back-office user could not reach them through EML.
"! Run the class (F9) to synchronise invoices with S/4HANA, e.g. from an application job.
CLASS zcl_vp_backoffice DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CLASS-METHODS:
      "! Booked / Paid detection from S/4HANA supplier invoices and the vendor ledger
      sync_invoices
        RETURNING VALUE(rv_changed) TYPE i,

      set_invoice_status
        IMPORTING iv_invoice_id TYPE zvp_inv_hdr-invoice_id
                  iv_status     TYPE zvp_inv_hdr-status
                  iv_reason     TYPE string OPTIONAL
        RETURNING VALUE(rv_ok)  TYPE abap_boolean,

      set_asn_status
        IMPORTING iv_asn_number TYPE zvp_asn_hdr-asn_number
                  iv_status     TYPE zvp_asn_hdr-status
        RETURNING VALUE(rv_ok)  TYPE abap_boolean.

ENDCLASS.


CLASS zcl_vp_backoffice IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    out->write( |{ sync_invoices( ) } invoice(s) updated| ).
  ENDMETHOD.

  METHOD sync_invoices.
    GET TIME STAMP FIELD DATA(lv_ts).

    SELECT invoice_uuid, invoice_id, supplier, vendor_invoice_number, status,
           supplier_invoice, supplier_invoice_fiscal_year
      FROM zvp_inv_hdr
      WHERE status IN ( 'Submitted', 'In Business Processing', 'Booked' )
      INTO TABLE @DATA(lt_inv).

    LOOP AT lt_inv ASSIGNING FIELD-SYMBOL(<inv>).

      " 1) found as supplier invoice in S/4HANA -> Booked
      IF <inv>-status <> 'Booked'.
        SELECT SINGLE SupplierInvoice, FiscalYear
          FROM I_SupplierInvoiceAPI01
          WHERE InvoicingParty = @<inv>-supplier
            AND SupplierInvoiceIDByInvcgParty = @<inv>-vendor_invoice_number
          INTO @DATA(ls_si).
        IF sy-subrc = 0.
          UPDATE zvp_inv_hdr
            SET status                       = 'Booked',
                supplier_invoice             = @ls_si-SupplierInvoice,
                supplier_invoice_fiscal_year = @ls_si-FiscalYear,
                local_last_changed_at        = @lv_ts,
                last_changed_at              = @lv_ts
            WHERE invoice_uuid = @<inv>-invoice_uuid.
          <inv>-status                       = 'Booked'.
          <inv>-supplier_invoice             = ls_si-SupplierInvoice.
          <inv>-supplier_invoice_fiscal_year = ls_si-FiscalYear.
          rv_changed += 1.
          INSERT zvp_activity FROM @( zcl_vp_util=>new_activity(
            iv_supplier = <inv>-supplier
            iv_text     = |Invoice { <inv>-invoice_id } booked as { ls_si-SupplierInvoice }|
            iv_type     = 'INVOICE'
            iv_id       = CONV #( <inv>-invoice_id ) ) ).
        ENDIF.
      ENDIF.

      " 2) booked invoice with a clearing document -> Paid
      IF <inv>-status = 'Booked'.
        DATA(lv_awkey) = |{ <inv>-supplier_invoice }{ <inv>-supplier_invoice_fiscal_year }|.
        SELECT SINGLE ClearingAccountingDocument
          FROM I_OperationalAcctgDocItem
          WHERE FinancialAccountType = 'K'
            AND Supplier = @<inv>-supplier
            AND OriginalReferenceDocument = @lv_awkey
            AND ClearingAccountingDocument <> ''
          INTO @DATA(lv_clearing).
        IF sy-subrc = 0.
          UPDATE zvp_inv_hdr
            SET status                = 'Paid',
                payment_reference     = @lv_clearing,
                local_last_changed_at = @lv_ts,
                last_changed_at       = @lv_ts
            WHERE invoice_uuid = @<inv>-invoice_uuid.
          rv_changed += 1.
          INSERT zvp_activity FROM @( zcl_vp_util=>new_activity(
            iv_supplier = <inv>-supplier
            iv_text     = |Invoice { <inv>-invoice_id } paid (clearing document { lv_clearing })|
            iv_type     = 'INVOICE'
            iv_id       = CONV #( <inv>-invoice_id ) ) ).
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_invoice_status.
    GET TIME STAMP FIELD DATA(lv_ts).
    SELECT SINGLE supplier FROM zvp_inv_hdr WHERE invoice_id = @iv_invoice_id INTO @DATA(lv_supplier).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF iv_status = 'Rejected'.
      UPDATE zvp_inv_hdr
        SET status = @iv_status, rejection_reason = @iv_reason,
            local_last_changed_at = @lv_ts, last_changed_at = @lv_ts
        WHERE invoice_id = @iv_invoice_id AND status <> 'Paid'.
    ELSE.
      UPDATE zvp_inv_hdr
        SET status = @iv_status,
            local_last_changed_at = @lv_ts, last_changed_at = @lv_ts
        WHERE invoice_id = @iv_invoice_id AND status <> 'Paid'.
    ENDIF.
    rv_ok = xsdbool( sy-dbcnt > 0 ).
    IF rv_ok = abap_true.
      INSERT zvp_activity FROM @( zcl_vp_util=>new_activity(
        iv_supplier = lv_supplier
        iv_text     = |Invoice { iv_invoice_id } is now { iv_status }|
        iv_type     = 'INVOICE'
        iv_id       = CONV #( iv_invoice_id ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD set_asn_status.
    GET TIME STAMP FIELD DATA(lv_ts).
    SELECT SINGLE supplier FROM zvp_asn_hdr WHERE asn_number = @iv_asn_number INTO @DATA(lv_supplier).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    UPDATE zvp_asn_hdr
      SET status = @iv_status, local_last_changed_at = @lv_ts, last_changed_at = @lv_ts
      WHERE asn_number = @iv_asn_number.
    rv_ok = xsdbool( sy-dbcnt > 0 ).
    IF rv_ok = abap_true.
      INSERT zvp_activity FROM @( zcl_vp_util=>new_activity(
        iv_supplier = lv_supplier
        iv_text     = |ASN { iv_asn_number } is now { iv_status }|
        iv_type     = 'ASN'
        iv_id       = CONV #( iv_asn_number ) ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

