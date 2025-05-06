  METHOD if_sadl_exit_calc_element_read~get_calculation_info.


*   LOOP AT it_requested_calc_elements ASSIGNING FIELD-SYMBOL(<fs_calc_element>).
*      CASE <fs_calc_element>.
*        WHEN 'LSCTRL'.
*        APPEND 'AVGWEIGHT' TO et_requested_orig_elements.
*        WHEN 'DCTRL'.
*
*        WHEN 'GCTRL'.
*
*      ENDCASE.
*    ENDLOOP.


  ENDMETHOD.