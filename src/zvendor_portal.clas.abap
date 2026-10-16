CLASS zvendor_portal DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_http_service_extension .

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: tablename  TYPE string.
    DATA: filename   TYPE string.
    DATA: fileext    TYPE string.
    DATA: dataoption TYPE string.
    DATA: filedata   TYPE string.

    METHODS: get_input_field_value IMPORTING name         TYPE string
                                             dataref      TYPE data
                                   RETURNING VALUE(value) TYPE string.
    METHODS: get_html RETURNING VALUE(ui_html) TYPE string.

    METHODS: read_excel IMPORTING file         TYPE xstring
                        CHANGING  target_table TYPE STANDARD TABLE
                        RETURNING VALUE(error) TYPE string.
ENDCLASS.



CLASS zvendor_portal IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    CASE request->get_method(  ).

*--------------------------------------------------------------------*
* GET : return the UI, or table name suggestions
*--------------------------------------------------------------------*
      WHEN CONV string( if_web_http_client=>get ).
        DATA(sap_table_request) = request->get_header_field( 'sap-table-request' ).
        IF sap_table_request IS INITIAL.
          response->set_text( get_html(   ) ).
        ELSE.
          DATA(name_filter) = xco_cp_abap_repository=>object_name->get_filter(
                               xco_cp_abap_sql=>constraint->contains_pattern( to_upper( sap_table_request ) && '%' )  ).
          DATA(objects) = xco_cp_abap_repository=>objects->tabl->where( VALUE #(
                              ( name_filter ) ) )->in( xco_cp_abap=>repository  )->get(  ).
          DATA(res) = `[`.
          LOOP AT objects INTO DATA(object).
            res &&= |\{ "TABLE_NAME": "{ object->name }" \}|.
            IF sy-tabix NE lines( objects ).
              res &&= `,`.
            ENDIF.
          ENDLOOP.
          res &&= `]`.
          response->set_text( res ).
        ENDIF.

*--------------------------------------------------------------------*
* POST : delete all data (Delete button) OR upload a file
*--------------------------------------------------------------------*
      WHEN CONV string( if_web_http_client=>post ).

*      * ---- Delete all data request (sent by the Delete button) ----
        DATA(delete_table) = to_upper( condense( request->get_header_field( 'sap-delete-table' ) ) ).
        IF delete_table IS NOT INITIAL.
          IF delete_table NP 'Z*' AND delete_table NP 'Y*'.
            response->set_status( i_code = if_web_http_status=>bad_request
                                  i_reason = `Only custom tables (Z*/Y*) can be cleared` ).
            response->set_text( `Only custom tables (Z*/Y*) can be cleared` ).
            RETURN.
          ENDIF.
          IF xco_cp_abap_repository=>object->tabl->database_table->for(
               iv_name = CONV #( delete_table ) )->exists( ) = abap_false.
            response->set_status( i_code = if_web_http_status=>bad_request
                                  i_reason = |Table { delete_table } does not exist| ).
            response->set_text( |Table { delete_table } does not exist| ).
            RETURN.
          ENDIF.
          TRY.
              DELETE FROM (delete_table).
              response->set_status( i_code = if_web_http_status=>ok
                                    i_reason = `Table cleared` ).
              response->set_text( |All data deleted from { delete_table } ({ sy-dbcnt } rows)| ).
            CATCH cx_sy_open_sql_db INTO DATA(del_exception).
              response->set_status( i_code = if_web_http_status=>bad_request
                                    i_reason = del_exception->get_text( ) ).
              response->set_text( del_exception->get_text( ) ).
          ENDTRY.
          RETURN.
        ENDIF.
* ---- File upload ----
* The browser sends the file base64-encoded in the body; metadata is in headers.
        tablename  = to_upper( condense( request->get_header_field( 'sap-upload-table' ) ) ).
        dataoption = condense( request->get_header_field( 'sap-upload-option' ) ).
        filename   = request->get_header_field( 'sap-upload-filename' ).
        fileext    = to_lower( segment( val = filename sep = '.' index = -1 ) ).

* Check table name is valid.
        IF tablename IS INITIAL OR
           xco_cp_abap_repository=>object->tabl->database_table->for(
             iv_name = CONV #( tablename ) )->exists( ) = abap_false.
          response->set_status( i_code = if_web_http_status=>bad_request
                                i_reason = |Table name { tablename } not valid or does not exist| ).
          response->set_text( |Table name { tablename } not valid or does not exist| ).
          RETURN.
        ENDIF.

* Check file extension
        IF fileext <> `xlsx` AND fileext <> `json`.
          response->set_status( i_code = if_web_http_status=>bad_request
                                i_reason = `File type not supported` ).
          response->set_text( `File type not supported. Use .xlsx or .json` ).
          RETURN.
        ENDIF.

* Decode file content
        DATA(file_content) = cl_web_http_utility=>decode_x_base64( request->get_text( ) ).

* Dynamic internal table for the target table
        DATA: dynamic_table TYPE REF TO data.
        FIELD-SYMBOLS: <table_structure> TYPE STANDARD TABLE.
        TRY.
            CREATE DATA dynamic_table TYPE TABLE OF (tablename).
            ASSIGN dynamic_table->* TO <table_structure>.
          CATCH cx_sy_create_data_error INTO DATA(cd_exception).
            response->set_status( i_code = if_web_http_status=>bad_request
                                  i_reason = cd_exception->get_text( ) ).
            response->set_text( cd_exception->get_text( ) ).
            RETURN.
        ENDTRY.

* Parse the file
        IF fileext = `xlsx`.
          DATA(excel_error) = read_excel( EXPORTING file = file_content
                                          CHANGING  target_table = <table_structure> ).
          IF excel_error IS NOT INITIAL.
            response->set_status( i_code = if_web_http_status=>bad_request
                                  i_reason = `Excel could not be read` ).
            response->set_text( excel_error ).
            RETURN.
          ENDIF.
        ELSE.
          filedata = cl_abap_conv_codepage=>create_in( )->convert( file_content ).
          /ui2/cl_json=>deserialize( EXPORTING json = filedata
                                               pretty_name = /ui2/cl_json=>pretty_mode-none
                                     CHANGING  data = <table_structure> ).
        ENDIF.

        IF lines( <table_structure> ) = 0.
          response->set_status( i_code = if_web_http_status=>bad_request
                                i_reason = `No rows parsed from file` ).
          response->set_text( `No rows parsed from file. Check the format and field names.` ).
          RETURN.
        ENDIF.

        TRY.
            CASE dataoption.
              WHEN `1`.
                DELETE FROM (tablename).
                MODIFY (tablename) FROM TABLE @<table_structure>.
              WHEN `2`.
                MODIFY (tablename) FROM TABLE @<table_structure>.
              WHEN OTHERS.
                INSERT (tablename) FROM TABLE @<table_structure>.
            ENDCASE.
            IF sy-subrc = 0.
              response->set_status( i_code = if_web_http_status=>ok
                                    i_reason = `Table updated successfully` ).
              response->set_text( |Table updated successfully ({ lines( <table_structure> ) } rows)| ).
            ENDIF.
          CATCH cx_sy_open_sql_db INTO DATA(db_exception).
            response->set_status( i_code = if_web_http_status=>bad_request
                                  i_reason = db_exception->get_text( ) ).
            response->set_text( db_exception->get_text( ) ).
            RETURN.
        ENDTRY.

    ENDCASE.
  ENDMETHOD.


  METHOD get_input_field_value.
    FIELD-SYMBOLS: <value> TYPE data,
                   <field> TYPE any.
    ASSIGN COMPONENT name  OF STRUCTURE dataref TO <field>.
    IF <field> IS ASSIGNED.
      ASSIGN <field>->* TO <value>.
      value = condense( <value> ).
    ENDIF.
  ENDMETHOD.


  METHOD get_html.
    ui_html =
    |<!DOCTYPE HTML> \n| &&
     |<html> \n| &&
     |<head> \n| &&
     |    <meta http-equiv="X-UA-Compatible" content="IE=edge"> \n| &&
     |    <meta http-equiv='Content-Type' content='text/html;charset=UTF-8' /> \n| &&
     |    <title>ABAP File Uploader</title> \n| &&
     |    <script id="sap-ui-bootstrap" src="https://sapui5.hana.ondemand.com/resources/sap-ui-core.js" \n| &&
     |        data-sap-ui-theme="sap_fiori_3_dark" data-sap-ui-xx-bindingSyntax="complex" data-sap-ui-compatVersion="edge" \n| &&
     |        data-sap-ui-async="true"> \n| &&
     |    </script> \n| &&
     |    <script> \n| &&
     |        sap.ui.require(['sap/ui/core/Core'], (oCore) => \{ \n| &&
     | \n| &&
     |            sap.ui.getCore().loadLibrary("sap.f", \{ \n| &&
     |                async: true \n| &&
     |            \}).then(() => \{ \n| &&
     |                let shell = new sap.f.ShellBar("shell") \n| &&
     |                shell.setTitle("ABAP File Uploader") \n| &&
     |                shell.setShowCopilot(true) \n| &&
     |                shell.setShowSearch(true) \n| &&
     |                shell.setShowNotifications(true) \n| &&
     |                shell.setShowProductSwitcher(true) \n| &&
     |                shell.placeAt("uiArea") \n| &&
     |                sap.ui.getCore().loadLibrary("sap.ui.layout", \{ \n| &&
     |                    async: true \n| &&
     |                \}).then(() => \{ \n| &&
     |                    let layout = new sap.ui.layout.VerticalLayout("layout") \n| &&
     |                    layout.placeAt("uiArea") \n| &&
     |                    let line2 = new sap.ui.layout.HorizontalLayout("line2") \n| &&
     |                    let line3 = new sap.ui.layout.HorizontalLayout("line3") \n| &&
     |                    let line4 = new sap.ui.layout.HorizontalLayout("line4") \n| &&
     |                    sap.ui.getCore().loadLibrary("sap.m", \{ \n| &&
     |                        async: true \n| &&
     |                    \}).then(() => \{\}) \n| &&
     | \n| &&
     |                    // ---------- Upload logic (shared by both buttons) ---------- \n| &&
     |                    let selectedFile = null \n| &&
     |                    function doUpload(expectedExt) \{ \n| &&
     |                        if (!selectedFile) \{ \n| &&
     |                            sap.m.MessageToast.show("Choose a file first") \n| &&
     |                            return \n| &&
     |                        \} \n| &&
     |                        let ext = selectedFile.name.split(".").pop().toLowerCase() \n| &&
     |                        if (ext !== expectedExt) \{ \n| &&
     |                            sap.m.MessageToast.show("Selected file is not a ." + expectedExt + " file") \n| &&
     |                            return \n| &&
     |                        \} \n| &&
     |                        let oInput = oCore.byId("tablename") \n| &&
     |                        let oGroup = oCore.byId("grpDataOptions") \n| &&
     |                        if (!oInput.getValue()) \{ \n| &&
     |                            sap.m.MessageToast.show("Target Table is Required") \n| &&
     |                            return \n| &&
     |                        \} \n| &&
     |                        let reader = new FileReader() \n| &&
     |                        reader.onload = function (e) \{ \n| &&
     |                            let bytes = new Uint8Array(e.target.result) \n| &&
     |                            let bin = "" \n| &&
     |                            for (let i = 0; i < bytes.length; i += 8192) \{ \n| &&
     |                                bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 8192)) \n| &&
     |                            \} \n| &&
     |                            jQuery.ajax(\{ \n| &&
     |                                method: "POST", \n| &&
     |                                timeout: 120000, \n| &&
     |                                contentType: "text/plain", \n| &&
     |                                data: btoa(bin), \n| &&
     |                                headers: \{ \n| &&
     |                                    "sap-upload-table": oInput.getValue(), \n| &&
     |                                    "sap-upload-option": String(oGroup.getSelectedIndex()), \n| &&
     |                                    "sap-upload-filename": selectedFile.name \n| &&
     |                                \}, \n| &&
     |                                success: function (res) \{ alert(res) \}, \n| &&
     |                                error: function (err) \{ alert(err.responseText) \} \n| &&
     |                            \}) \n| &&
     |                        \} \n| &&
     |                        reader.readAsArrayBuffer(selectedFile) \n| &&
     |                    \} \n| &&
     | \n| &&
     |                    // ---------- Upload JSON button ---------- \n| &&
     |                    let button = new sap.m.Button("button") \n| &&
     |                    button.setText("Upload JSON") \n| &&
     |                    button.attachPress(function () \{ doUpload("json") \}) \n| &&
     | \n| &&
     |                    // ---------- Upload Excel button ---------- \n| &&
     |                    let excelButton = new sap.m.Button("excelButton") \n| &&
     |                    excelButton.setText("Upload Excel") \n| &&
     |                    excelButton.attachPress(function () \{ doUpload("xlsx") \}) \n| &&
     | \n| &&
     |                    // ---------- Delete button ---------- \n| &&
     |                    let delButton = new sap.m.Button("deleteButton") \n| &&
     |                    delButton.setText("Delete All Data") \n| &&
     |                    delButton.setType("Reject") \n| &&
     |                    delButton.attachPress(function () \{ \n| &&
     |                        let oTable = oCore.byId("tablename") \n| &&
     |                        if (!oTable.getValue()) \{ \n| &&
     |                            sap.m.MessageToast.show("Target Table is Required") \n| &&
     |                            return \n| &&
     |                        \} \n| &&
     |                        if (!confirm("Delete ALL data from table " + oTable.getValue() + "?")) \{ \n| &&
     |                            return \n| &&
     |                        \} \n| &&
     |                        jQuery.ajax(\{ \n| &&
     |                            method: "POST", \n| &&
     |                            timeout: 30000, \n| &&
     |                            headers: \{ "sap-delete-table": oTable.getValue() \}, \n| &&
     |                            success: function (res) \{ alert(res) \}, \n| &&
     |                            error: function (err) \{ alert(err.responseText) \} \n| &&
     |                        \}) \n| &&
     |                    \}) \n| &&
     | \n| &&
     |                    // ---------- Target table input ---------- \n| &&
     |                    let input = new sap.m.Input("tablename") \n| &&
     |                    input.placeAt("layout") \n| &&
     |                    input.setRequired(true) \n| &&
     |                    input.setWidth("600px") \n| &&
     |                    input.setPlaceholder("Target ABAP Table") \n| &&
     |                    input.setShowSuggestion(true) \n| &&
     |                    input.attachSuggest(function (oEvent)\{ \n| &&
     |                      jQuery.ajax(\{headers: \{ "sap-table-request": oEvent.getParameter("suggestValue") \n| &&
     |                          \}, \n| &&
     |                         error: function(oErr)\{ alert( JSON.stringify(oErr))\}, timeout: 30000, method:"GET",dataType: "json",success: function(myJSON) \{ \n| &&
     |                      let input = oCore.byId("tablename") \n| &&
     |                      input.destroySuggestionItems() \n| &&
     |                      for (var i = 0; i < myJSON.length; i++) \{ \n| &&
     |                          input.addSuggestionItem(new sap.ui.core.Item(\{ \n| &&
     |                              text: myJSON[i].TABLE_NAME  \n| &&
     |                          \})); \n| &&
     |                      \} \n| &&
     |                    \} \}) \n| &&
     |                    \}) \n| &&
     |                    line2.placeAt("layout") \n| &&
     |                    line3.placeAt("layout") \n| &&
     |                    line4.placeAt("layout") \n| &&
     | \n| &&
     |                    // ---------- Data upload options ---------- \n| &&
     |                    let groupDataOptions = new sap.m.RadioButtonGroup("grpDataOptions") \n| &&
     |                    let lblGroupDataOptions = new sap.m.Label("lblDataOptions") \n| &&
     |                    lblGroupDataOptions.setLabelFor(groupDataOptions) \n| &&
     |                    lblGroupDataOptions.setText("Data Upload Options") \n| &&
     |                    lblGroupDataOptions.placeAt("line3") \n| &&
     |                    groupDataOptions.placeAt("line4") \n| &&
     |                    let rbAppend = new sap.m.RadioButton("rbAppend") \n| &&
     |                    let rbReplace = new sap.m.RadioButton("rbReplace") \n| &&
     |                    let rbModify = new sap.m.RadioButton("rbModify") \n| &&
     |                    rbAppend.setText("Append") \n| &&
     |                    rbReplace.setText("Replace") \n| &&
     |                    rbModify.setText("Modify") \n| &&
     |                    groupDataOptions.addButton(rbAppend) \n| &&
     |                    groupDataOptions.addButton(rbReplace) \n| &&
     |                    groupDataOptions.addButton(rbModify) \n| &&
     |                    rbAppend.setGroupName("grpDataOptions") \n| &&
     |                    rbReplace.setGroupName("grpDataOptions") \n| &&
     |                    rbModify.setGroupName("grpDataOptions") \n| &&
     | \n| &&
     |                    // ---------- File uploader ---------- \n| &&
     |                    sap.ui.getCore().loadLibrary("sap.ui.unified", \{ \n| &&
     |                        async: true \n| &&
     |                    \}).then(() => \{ \n| &&
     |                        var fileUploader = new sap.ui.unified.FileUploader("fileToUpload") \n| &&
     |                        fileUploader.setFileType(["xlsx", "json"]) \n| &&
     |                        fileUploader.setWidth("400px") \n| &&
     |                        fileUploader.attachChange(function (oEvent) \{ \n| &&
     |                            let files = oEvent.getParameter("files") \n| &&
     |                            selectedFile = (files && files.length) ? files[0] : null \n| &&
     |                        \}) \n| &&
     |                        fileUploader.placeAt("line2") \n| &&
     |                        button.placeAt("line2") \n| &&
     |                        excelButton.placeAt("line2") \n| &&
     |                        delButton.placeAt("line2") \n| &&
     |                        fileUploader.setPlaceholder("Choose JSON (.json) or Excel (.xlsx) file...") \n| &&
     |                    \}) \n| &&
     |                \}) \n| &&
     |            \}) \n| &&
     |        \}) \n| &&
     |    </script> \n| &&
     |</head> \n| &&
     |<body class="sapUiBody"> \n| &&
     |    <div id="uiArea"></div> \n| &&
     |</body> \n| &&
     | \n| &&
     |</html> |.
  ENDMETHOD.


  METHOD read_excel.
    FIELD-SYMBOLS: <tgt> TYPE any,
                   <fld> TYPE any.

    CONSTANTS letters TYPE string VALUE `ABCDEFGHIJKLMNOPQRSTUVWXYZ`.

    DATA(tgt_comps) = CAST cl_abap_structdescr(
                        CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( target_table )
                        )->get_table_line_type( ) )->get_components( ).
    DATA(max_cols) = lines( tgt_comps ).

    DATA col_names TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DO max_cols TIMES.
      APPEND `` TO col_names.
    ENDDO.

    DATA val     TYPE string.
    DATA row_no  TYPE i VALUE 0.

    TRY.
        DATA(worksheet) = xco_cp_xlsx=>document->for_file_content( file
                            )->read_access( )->get_workbook( )->worksheet->at_position( 1 ).

        DO.
          row_no = row_no + 1.
          IF row_no > 100000.
            EXIT.
          ENDIF.

          DATA(row_has_data) = abap_false.
          IF row_no > 1.
            APPEND INITIAL LINE TO target_table ASSIGNING <tgt>.
          ENDIF.

          DO max_cols TIMES.
            DATA(col_idx) = sy-index.

            " column index -> Excel letter (A..Z, AA..)
            DATA(col_letter) = COND string(
              WHEN col_idx <= 26
              THEN substring( val = letters off = col_idx - 1 len = 1 )
              ELSE substring( val = letters off = ( col_idx - 1 ) DIV 26 - 1 len = 1 ) &&
                   substring( val = letters off = ( col_idx - 1 ) MOD 26 len = 1 ) ).

            " read one cell as text
            CLEAR val.
            DATA(cell_cursor) = worksheet->cursor(
                                  io_column = xco_cp_xlsx=>coordinate->for_alphabetic_value( col_letter )
                                  io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( row_no ) ).
            IF cell_cursor->has_cell( ) = abap_true.
              DATA(cell) = cell_cursor->get_cell( ).
              IF cell->has_value( ) = abap_true.
                cell->get_value( )->set_transformation(
                  xco_cp_xlsx_read_access=>value_transformation->string_value )->write_to( REF #( val ) ).
              ENDIF.
            ENDIF.
            val = condense( val ).
            IF val IS INITIAL.
              CONTINUE.
            ENDIF.
            row_has_data = abap_true.

            IF row_no = 1.
              " ---- header row: remember field name per column ----
              val = to_upper( val ).
              IF NOT line_exists( tgt_comps[ name = val ] ).
                error = |Column "{ val }" does not exist in table { tablename }|.
                RETURN.
              ENDIF.
              col_names[ col_idx ] = val.
            ELSE.
              " ---- data row ----
              DATA(col_name) = col_names[ col_idx ].
              IF col_name IS INITIAL.
                CONTINUE.
              ENDIF.
              ASSIGN COMPONENT col_name OF STRUCTURE <tgt> TO <fld>.
                         DATA(ftype) = cl_abap_typedescr=>describe_by_data( <fld> )->type_kind.
              CASE ftype.
                WHEN cl_abap_typedescr=>typekind_date.
                  REPLACE ALL OCCURRENCES OF '-' IN val WITH ``.            " 2025-01-31 -> 20250131
                WHEN cl_abap_typedescr=>typekind_packed.
                  " ISO timestamp (2026-10-14T09:00:00Z) -> 20261014090000
                  IF matches( val = val regex = `\d{4}-\d{2}-\d{2}[T ].*` ).
                    REPLACE ALL OCCURRENCES OF REGEX `[-:TZ ]` IN val WITH ``.
                  ENDIF.
              ENDCASE.
              TRY.
                  <fld> = val.
                CATCH cx_sy_conversion_error INTO DATA(conv_err).
                  error = |Row { row_no }, column { col_name }: { conv_err->get_text( ) }|.
                  RETURN.
              ENDTRY.
            ENDIF.
          ENDDO.

          IF row_has_data = abap_false.
            IF row_no = 1.
              error = `Row 1 must contain the field names`.
              RETURN.
            ENDIF.
            DELETE target_table INDEX lines( target_table ).   " first blank row = end of data
            EXIT.
          ENDIF.
        ENDDO.

      CATCH cx_root INTO DATA(lx).
        error = lx->get_text( ).
        RETURN.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
