METHOD if_sadl_exit_calc_element_read~calculate.

    FIELD-SYMBOLS: <ls_original_data> TYPE any,
                   <lv_wtkt>          TYPE any,
                   <lv_harseq>        TYPE any,
                   <lv_carcass>       TYPE any.


    DATA lt_original_data TYPE STANDARD TABLE OF ZWBI_C_VEHIN_ITEM WITH DEFAULT KEY.  " give projuction view name
*     DATA lt_original_data TYPE STANDARD TABLE OF /N4C03/WBI_C_WEIGHT_ITEM WITH DEFAULT KEY.
    lt_original_data = CORRESPONDING #( it_original_data ).

    LOOP AT lt_original_data ASSIGNING FIELD-SYMBOL(<fs_original_data>).
      IF <fs_original_data>-intype EQ 'P'.
        <fs_original_data>-lsctrl =    abap_true.  " Passing 'X' to hide space to Unhide field
      ENDIF.

      IF <fs_original_data>-intype EQ 'S'.
       <fs_original_data>-lsctrlsd =  abap_true.
      ENDIF.

    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( lt_original_data ).

  ENDMETHOD.