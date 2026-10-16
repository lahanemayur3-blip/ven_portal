"! Quick approval for testing - no reviewer UI needed.
"! Edit the constants, then run with F9 (Run As > ABAP Application (Console)).
"! Moves the application Submitted/Resubmitted -> Under Review -> Approved through the
"! RAP BO (same actions the reviewer service uses), so ZVP_USER_MAP, history and
"! notifications are written exactly as in production.
CLASS zcl_vp_onb_approve DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS:
      gc_application_id TYPE zvp_onb_app-application_id VALUE 'V001001',     " EDIT: from the onboarding app
      gc_supplier       TYPE zvp_user_map-supplier      VALUE '0000100234',  " EDIT: existing supplier (BP)
      gc_company_code   TYPE zvp_user_map-company_code  VALUE '1010',        " EDIT: company code
      gc_comment        TYPE c LENGTH 60                VALUE 'Approved via ZCL_VP_ONB_APPROVE'.

ENDCLASS.


CLASS zcl_vp_onb_approve IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    SELECT SINGLE app_uuid, status, applicant_user
      FROM zvp_onb_app
      WHERE application_id = @gc_application_id
      INTO @DATA(ls_app).
    IF sy-subrc <> 0.
      out->write( |Application { gc_application_id } not found in ZVP_ONB_APP| ).
      RETURN.
    ENDIF.
    out->write( |{ gc_application_id }: status "{ ls_app-status }", applicant { ls_app-applicant_user }| ).

    " The portal's VendorContext inner-joins I_Supplier and I_CompanyCode -
    " an unknown supplier or company code would leave the portal empty.
    SELECT SINGLE @abap_true FROM I_Supplier
      WHERE Supplier = @gc_supplier
      INTO @DATA(lv_supplier_ok).
    IF lv_supplier_ok = abap_false.
      out->write( |Supplier { gc_supplier } does not exist - create the business partner first| ).
      RETURN.
    ENDIF.
    SELECT SINGLE @abap_true FROM I_CompanyCode
      WHERE CompanyCode = @gc_company_code
      INTO @DATA(lv_cc_ok).
    IF lv_cc_ok = abap_false.
      out->write( |Company code { gc_company_code } does not exist| ).
      RETURN.
    ENDIF.

    "--- 1) Submitted / Resubmitted -> Under Review
    IF ls_app-status = 'Submitted' OR ls_app-status = 'Resubmitted'.
      MODIFY ENTITIES OF zi_vp_onbapplication
        ENTITY Application
          EXECUTE startReview FROM VALUE #( ( AppUuid = ls_app-app_uuid ) )
        FAILED   DATA(ls_failed_review)
        REPORTED DATA(ls_reported_review).

      IF ls_failed_review-application IS NOT INITIAL.
        LOOP AT ls_reported_review-application INTO DATA(ls_msg_review) WHERE %msg IS BOUND.
          out->write( ls_msg_review-%msg->if_message~get_text( ) ).
        ENDLOOP.
        out->write( 'startReview failed' ).
        ROLLBACK ENTITIES.
        RETURN.
      ENDIF.

      COMMIT ENTITIES.
      IF sy-subrc <> 0.
        out->write( 'Commit of startReview failed' ).
        RETURN.
      ENDIF.
      out->write( 'Status -> Under Review' ).
      ls_app-status = 'Under Review'.
    ENDIF.

    IF ls_app-status <> 'Under Review'.
      out->write( |Approval needs status "Under Review" (current: "{ ls_app-status }"). | &&
                  |Submit the application in the onboarding app first.| ).
      RETURN.
    ENDIF.

    "--- 2) Under Review -> Approved (handler buffers the ZVP_USER_MAP row, saver writes it)
    MODIFY ENTITIES OF zi_vp_onbapplication
      ENTITY Application
        EXECUTE approveApplication FROM VALUE #(
          ( AppUuid = ls_app-app_uuid
            %param  = VALUE #( Supplier    = gc_supplier
                               CompanyCode = gc_company_code
                               Comment1    = gc_comment ) ) )
      FAILED   DATA(ls_failed_approve)
      REPORTED DATA(ls_reported_approve).

    IF ls_failed_approve-application IS NOT INITIAL.
      LOOP AT ls_reported_approve-application INTO DATA(ls_msg_approve) WHERE %msg IS BOUND.
        out->write( ls_msg_approve-%msg->if_message~get_text( ) ).
      ENDLOOP.
      out->write( 'approveApplication failed' ).
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    COMMIT ENTITIES.
    IF sy-subrc <> 0.
      out->write( 'Commit of approveApplication failed' ).
      RETURN.
    ENDIF.
    out->write( |Status -> Approved, supplier { gc_supplier ALPHA = OUT }| ).

    "--- 3) show what the portal will see for this user
    SELECT user_id, supplier, company_code, is_active, valid_from, valid_to, source
      FROM zvp_user_map
      WHERE user_id = @ls_app-applicant_user
      INTO TABLE @DATA(lt_map).
    out->write( lt_map ).
    IF lines( lt_map ) > 1.
      out->write( |Note: { ls_app-applicant_user } is mapped to { lines( lt_map ) } suppliers - | &&
                  |the portal shows the first one. Set IS_ACTIVE = ' ' on the rows you don't need.| ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.

