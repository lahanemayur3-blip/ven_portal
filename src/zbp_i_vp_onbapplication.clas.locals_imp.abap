*&---------------------------------------------------------------------*
*& Behavior pool ZBP_I_VP_ONBAPPLICATION - "Local Types" tab
*&---------------------------------------------------------------------*
INTERFACE lif_status.
  CONSTANTS:
    draft         TYPE c LENGTH 30 VALUE 'Draft',
    submitted     TYPE c LENGTH 30 VALUE 'Submitted',
    under_review  TYPE c LENGTH 30 VALUE 'Under Review',
    clarification TYPE c LENGTH 30 VALUE 'Clarification Required',
    resubmitted   TYPE c LENGTH 30 VALUE 'Resubmitted',
    approved      TYPE c LENGTH 30 VALUE 'Approved',
    rejected      TYPE c LENGTH 30 VALUE 'Rejected'.
ENDINTERFACE.


*----------------------------------------------------------------------*
* Application
*----------------------------------------------------------------------*
CLASS lhc_application DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_error,
        field TYPE string,
        text  TYPE string,
      END OF ty_error,
      tt_error TYPE STANDARD TABLE OF ty_error WITH EMPTY KEY.

    DATA mt_error TYPE tt_error.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Application RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Application RESULT result.

    METHODS setdefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Application~setDefaults.

    METHODS validateoneapplication FOR VALIDATE ON SAVE
      IMPORTING keys FOR Application~validateOneApplication.

    METHODS submitapplication FOR MODIFY
      IMPORTING keys FOR ACTION Application~submitApplication RESULT result.

    METHODS startreview FOR MODIFY
      IMPORTING keys FOR ACTION Application~startReview RESULT result.

    METHODS requestclarification FOR MODIFY
      IMPORTING keys FOR ACTION Application~requestClarification RESULT result.

    METHODS approveapplication FOR MODIFY
      IMPORTING keys FOR ACTION Application~approveApplication RESULT result.

    METHODS rejectapplication FOR MODIFY
      IMPORTING keys FOR ACTION Application~rejectApplication RESULT result.

    "--- helpers
    METHODS add_error
      IMPORTING iv_field TYPE string OPTIONAL
                iv_text  TYPE string.

    METHODS req
      IMPORTING iv_value TYPE clike
                iv_field TYPE string
                iv_label TYPE string.

    METHODS fmt
      IMPORTING iv_value TYPE clike
                iv_regex TYPE string
                iv_field TYPE string
                iv_text  TYPE string.

    METHODS log_activity
      IMPORTING iv_user   TYPE clike
                iv_app_id TYPE clike
                iv_text   TYPE string.

    METHODS new_uuid
      RETURNING VALUE(rv_uuid) TYPE sysuuid_x16.

    METHODS now
      RETURNING VALUE(rv_ts) TYPE abp_lastchange_tstmpl.
ENDCLASS.


CLASS lhc_application IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Row-level access: DCL (an applicant only sees and changes his own application).
    " Reviewer actions are not exposed in the vendor projection ZC_VP_OnbApplication.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
    result-%action-submitApplication    = if_abap_behv=>auth-allowed.
    result-%action-startReview          = if_abap_behv=>auth-allowed.
    result-%action-requestClarification = if_abap_behv=>auth-allowed.
    result-%action-approveApplication   = if_abap_behv=>auth-allowed.
    result-%action-rejectApplication    = if_abap_behv=>auth-allowed.
  ENDMETHOD.


  METHOD get_instance_features.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_app)
      FAILED failed.

    LOOP AT lt_app INTO DATA(ls_app).
      DATA(lv_edit)   = xsdbool( ls_app-Status = lif_status=>draft OR ls_app-Status = lif_status=>clarification ).
      DATA(lv_draft)  = xsdbool( ls_app-Status = lif_status=>draft ).
      DATA(lv_review) = xsdbool( ls_app-Status = lif_status=>submitted OR ls_app-Status = lif_status=>resubmitted ).
      DATA(lv_decide) = xsdbool( ls_app-Status = lif_status=>under_review ).

      APPEND VALUE #(
        %tky                         = ls_app-%tky
        %update                      = COND #( WHEN lv_edit   = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %delete                      = COND #( WHEN lv_draft  = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %assoc-_Document             = COND #( WHEN lv_edit   = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-submitApplication    = COND #( WHEN lv_edit   = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-startReview          = COND #( WHEN lv_review = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-requestClarification = COND #( WHEN lv_decide = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-approveApplication   = COND #( WHEN lv_decide = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-rejectApplication    = COND #( WHEN lv_decide = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD setdefaults.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( ApplicationId Country CurrentStep ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_app).

    DELETE lt_app WHERE ApplicationId IS NOT INITIAL.
    IF lt_app IS INITIAL.
      RETURN.
    ENDIF.

    " Demo numbering V001001, V001002 ... For production use a number range object
    " (ADT: New > Number Range Object, then cl_numberrange_runtime=>number_get).
    SELECT MAX( application_id ) FROM zvp_onb_app INTO @DATA(lv_max).
    DATA(lv_next) = COND i( WHEN lv_max IS INITIAL THEN 1001
                            ELSE CONV i( substring( val = condense( lv_max ) off = 1 ) ) + 1 ).

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    MODIFY ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        UPDATE FIELDS ( ApplicationId ApplicantUser Status Country CurrentStep )
        WITH VALUE #( FOR ls_app IN lt_app INDEX INTO lv_idx
                      ( %tky          = ls_app-%tky
                        ApplicationId = |V{ lv_next + lv_idx - 1 WIDTH = 6 ALIGN = RIGHT PAD = '0' }|
                        ApplicantUser = lv_user
                        Status        = lif_status=>draft
                        Country       = COND #( WHEN ls_app-Country IS INITIAL THEN 'IN' ELSE ls_app-Country )
                        CurrentStep   = COND #( WHEN ls_app-CurrentStep IS INITIAL THEN 1 ELSE ls_app-CurrentStep ) ) )
      REPORTED DATA(lt_reported).

    reported = CORRESPONDING #( DEEP lt_reported ).
  ENDMETHOD.


  METHOD validateoneapplication.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( ApplicantUser ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_app).

    LOOP AT lt_app INTO DATA(ls_app).
      SELECT SINGLE @abap_true FROM zvp_onb_app
        WHERE applicant_user = @ls_app-ApplicantUser
          AND app_uuid      <> @ls_app-AppUuid
        INTO @DATA(lv_exists).

      IF lv_exists = abap_true.
        APPEND VALUE #( %tky = ls_app-%tky ) TO failed-application.
        APPEND VALUE #( %tky = ls_app-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'An onboarding application already exists for your user' ) )
          TO reported-application.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD submitapplication.
    DATA ls_rep LIKE LINE OF reported-application.
    DATA lv_new TYPE c LENGTH 30.

    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_app)
      ENTITY Application BY \_Document
        FIELDS ( AppUuid DocType FileName ExpiryDate ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_doc).

    SELECT doc_type, description, is_mandatory, expiry_required
      FROM zvp_onb_doctype
      INTO TABLE @DATA(lt_type).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_now)   = now( ).

    LOOP AT lt_app INTO DATA(ls_app).
      CLEAR mt_error.

      "--- 1. Basic information
      req( iv_value = ls_app-CompanyName   iv_field = `CompanyName`   iv_label = `Company name` ).
      req( iv_value = ls_app-ContactPerson iv_field = `ContactPerson` iv_label = `Contact person` ).
      req( iv_value = ls_app-Email         iv_field = `Email`         iv_label = `E-mail` ).
      req( iv_value = ls_app-Phone         iv_field = `Phone`         iv_label = `Phone` ).
      fmt( iv_value = ls_app-Email iv_field = `Email`
           iv_regex = `^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$`
           iv_text  = `Enter a valid e-mail address, e.g. accounts@company.in` ).

      "--- 2. Company information
      req( iv_value = ls_app-LegalName   iv_field = `LegalName`   iv_label = `Legal name` ).
      req( iv_value = ls_app-CompanyType iv_field = `CompanyType` iv_label = `Company type` ).
      req( iv_value = ls_app-AddressLine iv_field = `AddressLine` iv_label = `Address` ).
      req( iv_value = ls_app-City        iv_field = `City`        iv_label = `City` ).
      req( iv_value = ls_app-Country     iv_field = `Country`     iv_label = `Country` ).
      req( iv_value = ls_app-PostalCode  iv_field = `PostalCode`  iv_label = `Postal code` ).

      IF ls_app-Country = 'IN'.
        fmt( iv_value = ls_app-Phone iv_field = `Phone`
             iv_regex = `^(\+91[\- ]?)?[6-9][0-9]{9}$`
             iv_text  = `Phone must be a 10-digit mobile number, e.g. 9876543210` ).
        fmt( iv_value = ls_app-PostalCode iv_field = `PostalCode`
             iv_regex = `^[1-9][0-9]{5}$`
             iv_text  = `PIN code must be 6 digits, e.g. 400001` ).

        "--- 3. GST / PAN / Tax (India)
        req( iv_value = ls_app-Gstin iv_field = `Gstin` iv_label = `GSTIN` ).
        req( iv_value = ls_app-Pan   iv_field = `Pan`   iv_label = `PAN` ).
      ELSE.
        fmt( iv_value = ls_app-Phone iv_field = `Phone`
             iv_regex = `^\+?[0-9 \-]{6,20}$`
             iv_text  = `Enter a valid phone number` ).
      ENDIF.

      fmt( iv_value = ls_app-Gstin iv_field = `Gstin`
           iv_regex = `^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$`
           iv_text  = `GSTIN must be 15 characters, e.g. 27AAACA1000F1Z5` ).
      fmt( iv_value = ls_app-Pan iv_field = `Pan`
           iv_regex = `^[A-Z]{5}[0-9]{4}[A-Z]$`
           iv_text  = `PAN must be 10 characters, e.g. AAACA1000F` ).
      IF ls_app-Gstin IS NOT INITIAL AND ls_app-Pan IS NOT INITIAL AND ls_app-Gstin+2(10) <> ls_app-Pan.
        add_error( iv_field = `Pan` iv_text = `PAN does not match characters 3-12 of the GSTIN` ).
      ENDIF.
      fmt( iv_value = ls_app-MsmeNumber iv_field = `MsmeNumber`
           iv_regex = `^UDYAM-[A-Z]{2}-[0-9]{2}-[0-9]{7}$`
           iv_text  = `Format: UDYAM-MH-01-1234567` ).

      "--- 4. Bank details
      req( iv_value = ls_app-BankName          iv_field = `BankName`          iv_label = `Bank name` ).
      req( iv_value = ls_app-AccountHolderName iv_field = `AccountHolderName` iv_label = `Account holder` ).
      req( iv_value = ls_app-BankAccountNumber iv_field = `BankAccountNumber` iv_label = `Account number` ).
      req( iv_value = ls_app-Ifsc              iv_field = `Ifsc`              iv_label = `IFSC` ).
      fmt( iv_value = ls_app-BankAccountNumber iv_field = `BankAccountNumber`
           iv_regex = `^[0-9]{9,18}$`
           iv_text  = `Account number must be 9-18 digits` ).
      fmt( iv_value = ls_app-Ifsc iv_field = `Ifsc`
           iv_regex = `^[A-Z]{4}0[A-Z0-9]{6}$`
           iv_text  = `IFSC must be 11 characters, e.g. HDFC0000123` ).

      "--- 5. Documents
      LOOP AT lt_type INTO DATA(ls_type).
        DATA(lv_found) = abap_false.
        LOOP AT lt_doc INTO DATA(ls_doc)
             WHERE AppUuid = ls_app-AppUuid AND DocType = ls_type-doc_type AND FileName IS NOT INITIAL.
          lv_found = abap_true.
          IF ls_type-expiry_required = abap_true AND ls_doc-ExpiryDate IS INITIAL.
            add_error( iv_text = |{ ls_type-description }: enter the expiry date| ).
          ELSEIF ls_doc-ExpiryDate IS NOT INITIAL AND ls_doc-ExpiryDate < lv_today.
            add_error( iv_text = |{ ls_type-description }: the document has expired| ).
          ENDIF.
        ENDLOOP.
        IF lv_found = abap_false AND ls_type-is_mandatory = abap_true.
          add_error( iv_text = |{ ls_type-description } is mandatory| ).
        ENDIF.
      ENDLOOP.

      "--- errors -> failed / reported (field-bound where possible)
      IF mt_error IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_app-%tky ) TO failed-application.
        LOOP AT mt_error INTO DATA(ls_err).
          CLEAR ls_rep.
          ls_rep-%tky = ls_app-%tky.
          ls_rep-%msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                               text     = ls_err-text ).
          IF ls_err-field IS NOT INITIAL.
            ASSIGN COMPONENT ls_err-field OF STRUCTURE ls_rep-%element TO FIELD-SYMBOL(<lv_flag>).
            IF sy-subrc = 0.
              <lv_flag> = if_abap_behv=>mk-on.
            ENDIF.
          ENDIF.
          APPEND ls_rep TO reported-application.
        ENDLOOP.
        CONTINUE.
      ENDIF.

      "--- status change + history + notification
      lv_new = COND #( WHEN ls_app-Status = lif_status=>clarification
                       THEN lif_status=>resubmitted
                       ELSE lif_status=>submitted ).

      MODIFY ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
        ENTITY Application
          UPDATE FIELDS ( Status SubmittedAt )
          WITH VALUE #( ( %tky = ls_app-%tky Status = lv_new SubmittedAt = lv_now ) )
          CREATE BY \_History
          FIELDS ( StatusFrom StatusTo )
          WITH VALUE #( ( %tky    = ls_app-%tky
                          %target = VALUE #( ( %cid = 'HIST' StatusFrom = ls_app-Status StatusTo = lv_new ) ) ) )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      log_activity( iv_user   = ls_app-ApplicantUser
                    iv_app_id = ls_app-ApplicationId
                    iv_text   = |Application { ls_app-ApplicationId } { to_lower( lv_new ) } for review| ).
    ENDLOOP.

    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).
    result = VALUE #( FOR ls_res IN lt_result ( %tky = ls_res-%tky %param = ls_res ) ).
  ENDMETHOD.


  METHOD startreview.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( Status ApplicantUser ApplicationId ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_app).

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA(lv_now)  = now( ).

    LOOP AT lt_app INTO DATA(ls_app).
      MODIFY ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
        ENTITY Application
          UPDATE FIELDS ( Status ReviewedBy ReviewedAt )
          WITH VALUE #( ( %tky = ls_app-%tky Status = lif_status=>under_review ReviewedBy = lv_user ReviewedAt = lv_now ) )
          CREATE BY \_History
          FIELDS ( StatusFrom StatusTo )
          WITH VALUE #( ( %tky    = ls_app-%tky
                          %target = VALUE #( ( %cid = 'HIST' StatusFrom = ls_app-Status StatusTo = lif_status=>under_review ) ) ) )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      log_activity( iv_user   = ls_app-ApplicantUser
                    iv_app_id = ls_app-ApplicationId
                    iv_text   = |Application { ls_app-ApplicationId } is under review| ).
    ENDLOOP.

    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).
    result = VALUE #( FOR ls_res IN lt_result ( %tky = ls_res-%tky %param = ls_res ) ).
  ENDMETHOD.


  METHOD requestclarification.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( Status ApplicantUser ApplicationId ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_app).

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA(lv_now)  = now( ).

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_app INTO DATA(ls_app) WITH KEY AppUuid = ls_key-AppUuid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF ls_key-%param-Comment1 IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-application.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Enter what the vendor has to clarify' ) )
          TO reported-application.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
        ENTITY Application
          UPDATE FIELDS ( Status ReviewedBy ReviewedAt ReviewComment )
          WITH VALUE #( ( %tky = ls_key-%tky Status = lif_status=>clarification
                          ReviewedBy = lv_user ReviewedAt = lv_now ReviewComment = ls_key-%param-Comment1 ) )
          CREATE BY \_History
          FIELDS ( StatusFrom StatusTo Comment1 )
          WITH VALUE #( ( %tky    = ls_key-%tky
                          %target = VALUE #( ( %cid = 'HIST' StatusFrom = ls_app-Status
                                               StatusTo = lif_status=>clarification Comment1 = ls_key-%param-Comment1 ) ) ) )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      log_activity( iv_user   = ls_app-ApplicantUser
                    iv_app_id = ls_app-ApplicationId
                    iv_text   = |Clarification required: { ls_key-%param-Comment1 }| ).
    ENDLOOP.

    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).
    result = VALUE #( FOR ls_res IN lt_result ( %tky = ls_res-%tky %param = ls_res ) ).
  ENDMETHOD.


  METHOD approveapplication.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( Status ApplicantUser ApplicationId Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_app).

    DATA(lv_user)  = cl_abap_context_info=>get_user_technical_name( ).
    DATA(lv_now)   = now( ).
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_app INTO DATA(ls_app) WITH KEY AppUuid = ls_key-AppUuid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " The supplier (business partner) is created by procurement first - e.g. via the
      " released BP API - and its number is passed here. Then the portal user is mapped to it.
      IF ls_key-%param-Supplier IS INITIAL OR ls_key-%param-CompanyCode IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-application.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Enter the supplier number and company code' ) )
          TO reported-application.
        CONTINUE.
      ENDIF.

      DATA lv_supplier TYPE c LENGTH 10.
      lv_supplier = |{ ls_key-%param-Supplier ALPHA = IN }|.

      MODIFY ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
        ENTITY Application
          UPDATE FIELDS ( Status Supplier ReviewedBy ReviewedAt ReviewComment )
          WITH VALUE #( ( %tky = ls_key-%tky Status = lif_status=>approved Supplier = lv_supplier
                          ReviewedBy = lv_user ReviewedAt = lv_now ReviewComment = ls_key-%param-Comment1 ) )
          CREATE BY \_History
          FIELDS ( StatusFrom StatusTo Comment1 )
          WITH VALUE #( ( %tky    = ls_key-%tky
                          %target = VALUE #( ( %cid = 'HIST' StatusFrom = ls_app-Status
                                               StatusTo = lif_status=>approved Comment1 = ls_key-%param-Comment1 ) ) ) )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      " portal user -> new supplier (written in save_modified)
      APPEND VALUE #( user_id      = ls_app-ApplicantUser
                      supplier     = lv_supplier
                      company_code = ls_key-%param-CompanyCode
                      portal_email = ls_app-Email
                      is_active    = abap_true
                      valid_from   = lv_today
                      valid_to     = '99991231'
                      onb_app_uuid = ls_app-AppUuid
                      source       = 'ONBOARDING' )
        TO zbp_i_vp_onbapplication=>gt_user_map.

      log_activity( iv_user   = ls_app-ApplicantUser
                    iv_app_id = ls_app-ApplicationId
                    iv_text   = |Application { ls_app-ApplicationId } approved - supplier { lv_supplier ALPHA = OUT }| ).
    ENDLOOP.

    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).
    result = VALUE #( FOR ls_res IN lt_result ( %tky = ls_res-%tky %param = ls_res ) ).
  ENDMETHOD.


  METHOD rejectapplication.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( Status ApplicantUser ApplicationId ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_app).

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA(lv_now)  = now( ).

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_app INTO DATA(ls_app) WITH KEY AppUuid = ls_key-AppUuid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF ls_key-%param-Comment1 IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-application.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Enter the reason for rejection' ) )
          TO reported-application.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
        ENTITY Application
          UPDATE FIELDS ( Status ReviewedBy ReviewedAt ReviewComment )
          WITH VALUE #( ( %tky = ls_key-%tky Status = lif_status=>rejected
                          ReviewedBy = lv_user ReviewedAt = lv_now ReviewComment = ls_key-%param-Comment1 ) )
          CREATE BY \_History
          FIELDS ( StatusFrom StatusTo Comment1 )
          WITH VALUE #( ( %tky    = ls_key-%tky
                          %target = VALUE #( ( %cid = 'HIST' StatusFrom = ls_app-Status
                                               StatusTo = lif_status=>rejected Comment1 = ls_key-%param-Comment1 ) ) ) )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      log_activity( iv_user   = ls_app-ApplicantUser
                    iv_app_id = ls_app-ApplicationId
                    iv_text   = |Application { ls_app-ApplicationId } rejected: { ls_key-%param-Comment1 }| ).
    ENDLOOP.

    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).
    result = VALUE #( FOR ls_res IN lt_result ( %tky = ls_res-%tky %param = ls_res ) ).
  ENDMETHOD.


  "----------------------------------------------------------------------
  " helpers
  "----------------------------------------------------------------------
  METHOD add_error.
    APPEND VALUE #( field = iv_field text = iv_text ) TO mt_error.
  ENDMETHOD.


  METHOD req.
    IF iv_value IS INITIAL.
      add_error( iv_field = iv_field iv_text = |{ iv_label } is mandatory| ).
    ENDIF.
  ENDMETHOD.


  METHOD fmt.
    IF iv_value IS INITIAL.
      RETURN.   " empty = handled by req( ) where mandatory
    ENDIF.
    IF NOT matches( val = condense( CONV string( iv_value ) ) pcre = iv_regex ).
      add_error( iv_field = iv_field iv_text = iv_text ).
    ENDIF.
  ENDMETHOD.


  METHOD log_activity.
    DATA(lv_text) = iv_text.
    IF strlen( lv_text ) > 255.
      lv_text = lv_text(255).
    ENDIF.
    APPEND VALUE #( activity_uuid       = new_uuid( )
                    user_id             = iv_user
                    activity_text       = lv_text
                    related_object_type = 'ONBOARDING'
                    related_object_id   = iv_app_id
                    is_read             = abap_false
                    created_by          = cl_abap_context_info=>get_user_technical_name( )
                    created_at          = now( ) )
      TO zbp_i_vp_onbapplication=>gt_activity.
  ENDMETHOD.


  METHOD new_uuid.
    TRY.
        rv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        CLEAR rv_uuid.
    ENDTRY.
  ENDMETHOD.


  METHOD now.
    GET TIME STAMP FIELD rv_ts.
  ENDMETHOD.

ENDCLASS.


*----------------------------------------------------------------------*
* Document: editable only while the application is Draft / Clarification Required
*----------------------------------------------------------------------*
CLASS lhc_document DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Document RESULT result.
ENDCLASS.


CLASS lhc_document IMPLEMENTATION.

  METHOD get_instance_features.
    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Document
        FIELDS ( AppUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_doc)
      FAILED failed.

    DATA lt_app_keys TYPE TABLE FOR READ IMPORT zi_vp_onbapplication.
    lt_app_keys = VALUE #( FOR ls_d IN lt_doc ( AppUuid = ls_d-AppUuid ) ).
    SORT lt_app_keys BY AppUuid.
    DELETE ADJACENT DUPLICATES FROM lt_app_keys COMPARING AppUuid.

    READ ENTITIES OF zi_vp_onbapplication IN LOCAL MODE
      ENTITY Application
        FIELDS ( Status ) WITH lt_app_keys
      RESULT DATA(lt_app).

    LOOP AT lt_doc INTO DATA(ls_doc).
      READ TABLE lt_app INTO DATA(ls_app) WITH KEY AppUuid = ls_doc-AppUuid.
      DATA(lv_edit) = xsdbool( sy-subrc = 0 AND ( ls_app-Status = lif_status=>draft OR ls_app-Status = lif_status=>clarification ) ).

      APPEND VALUE #(
        %tky    = ls_doc-%tky
        %update = COND #( WHEN lv_edit = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %delete = COND #( WHEN lv_edit = abap_true THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


*----------------------------------------------------------------------*
* Additional save: notifications (ZVP_ACTIVITY) + user mapping on approval
*----------------------------------------------------------------------*
CLASS lsc_zi_vp_onbapplication DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.


CLASS lsc_zi_vp_onbapplication IMPLEMENTATION.

  METHOD save_modified.
    IF zbp_i_vp_onbapplication=>gt_activity IS NOT INITIAL.
      INSERT zvp_activity FROM TABLE @zbp_i_vp_onbapplication=>gt_activity.
    ENDIF.
    IF zbp_i_vp_onbapplication=>gt_user_map IS NOT INITIAL.
      MODIFY zvp_user_map FROM TABLE @zbp_i_vp_onbapplication=>gt_user_map.
    ENDIF.
    CLEAR: zbp_i_vp_onbapplication=>gt_activity,
           zbp_i_vp_onbapplication=>gt_user_map.
  ENDMETHOD.


  METHOD cleanup_finalize.
    CLEAR: zbp_i_vp_onbapplication=>gt_activity,
           zbp_i_vp_onbapplication=>gt_user_map.
  ENDMETHOD.

ENDCLASS.

