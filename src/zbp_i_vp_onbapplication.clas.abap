*&---------------------------------------------------------------------*
*& Behavior pool ZBP_I_VP_ONBAPPLICATION - "Global Class" tab
*& The handler/saver classes go into the "Local Types" tab (file 2_locals_imp).
*&---------------------------------------------------------------------*
CLASS zbp_i_vp_onbapplication DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zi_vp_onbapplication.

  PUBLIC SECTION.
    " Filled by the action handlers, written in the saver (save_modified)
    CLASS-DATA gt_activity TYPE STANDARD TABLE OF zvp_activity WITH EMPTY KEY.
    CLASS-DATA gt_user_map TYPE STANDARD TABLE OF zvp_user_map WITH EMPTY KEY.
ENDCLASS.


CLASS zbp_i_vp_onbapplication IMPLEMENTATION.
ENDCLASS.

