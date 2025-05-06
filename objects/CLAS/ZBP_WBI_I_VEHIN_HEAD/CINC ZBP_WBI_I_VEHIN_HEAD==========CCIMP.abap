CLASS lcl_ls_buffer DEFINITION. "buffer data to use globally
  PUBLIC SECTION.

    CLASS-DATA: gv_header_grossweight_so TYPE string, "zWBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_netweight_so   TYPE string, "zWBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_weightuint_so  TYPE  c LENGTH 3,
                gv_header_grossweight_po TYPE string, "zWBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_netweight_po   TYPE string, "zWBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_weightuint_po  TYPE  c LENGTH 3,
                gv_error_h_flag          TYPE c LENGTH 1.

ENDCLASS.


CLASS lhc_Head DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Head RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Head RESULT result.

    METHODS calcTotWeight FOR MODIFY
      IMPORTING keys FOR ACTION Head~calcTotWeight.

    METHODS print FOR MODIFY
      IMPORTING keys FOR ACTION Head~print RESULT result.

    METHODS setOutward FOR MODIFY
      IMPORTING keys FOR ACTION Head~setOutward.

    METHODS defaultData FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Head~defaultData.

    METHODS getOrderData FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Head~getOrderData.

    METHODS calculateTickNum FOR DETERMINE ON SAVE
      IMPORTING keys FOR Head~calculateTickNum.

    METHODS setItem FOR DETERMINE ON SAVE
      IMPORTING keys FOR Head~setItem.

    METHODS validateInward FOR VALIDATE ON SAVE
      IMPORTING keys FOR Head~validateInward.

ENDCLASS.

CLASS lhc_head IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD calculateticknum."triggering at creation

    DATA: lv_weigh_GROSSWEIGHT TYPE zwbi_dt_weigh,
          lv_weigh_netweight   TYPE zwbi_dt_weigh.

    CONSTANTS: lc_tzone TYPE cl_abap_context_info=>ty_time_zone VALUE 'INDIA'. "cross check this
    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE lc_tzone INTO DATE DATA(lv_date) TIME DATA(lv_time).

    SELECT SINGLE fiscalyear
            FROM zwbi_fiscalcalendardate  "zi_fiscalcalendardate
                WHERE fiscalyearvariant = 'V3'
                AND calendardate = @lv_date
                        INTO @DATA(lv_fyear).
    IF  lv_fyear IS INITIAL.
      lv_fyear = sy-datlo+0(4).
    ENDIF.

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE reads data from screen
            ENTITY head
                ALL FIELDS WITH CORRESPONDING #( keys )
                    RESULT DATA(heads).

    TRY.
        DATA(ls_head) = heads[ 1 ].
*        ls_head-Planttext = ls_head-plant. "01-04
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

*************************************start 1/5/2025 logic to stop creating wkt without line item

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE c
            ENTITY head BY \_item
                ALL FIELDS WITH VALUE #( ( %tky = ls_head-%tky ) )
                    RESULT DATA(allitems).


    TRY.
        sort allitems[] by ordnum."1/5/2025
        DATA(ls_item) = allitems[ 1 ].
      CATCH cx_sy_itab_line_not_found.



APPEND VALUE #(
             %tky = ls_head-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-014 }|
          )

          ) TO reported-head.
*          APPEND VALUE #( %tky = ls_head-%tky ) TO reported-head  .
          return.
      ENDTRY.

**********************end 1/5/2025

    SELECT SINGLE
            FROM zwbi_i_vehin_head  "zi_vehin_head
                FIELDS MAX( range ) AS ticknum
                    WHERE plant = @ls_head-plant
                    AND   fiscal = @lv_fyear
                      INTO @DATA(max_ticknum).
    IF max_ticknum IS INITIAL.
      max_ticknum = '0000000001'.
    ELSE.
      max_ticknum = max_ticknum + 1.
    ENDIF.

    IF ls_head-intype = 'S'.
      CLEAR:lv_weigh_GROSSWEIGHT,lv_weigh_netweight.
*below select logic is uncommented for public cloud requirement and map the fields for data flow
*  SELECT SINGLE     grossweight,
*                        netweight
*                       FROM zi_sorder_data
*                             WHERE sorder = @ls_head-orderhead
*                                 INTO @DATA(ls_weigh).
*Below data fetching from METHOD get_instance_features
      lv_weigh_GROSSWEIGHT = lcl_ls_buffer=>gv_header_grossweight_so.
      lv_weigh_netweight   = lcl_ls_buffer=>gv_header_netweight_so.

    ELSEIF ls_head-intype = 'P'.
      CLEAR:lv_weigh_GROSSWEIGHT,lv_weigh_netweight.

*below select logic is uncommented for public cloud requirement and map the fields for data flow

*  SELECT SINGLE grossweight,
*                    netweight
*                  FROM zi_porder_data
*                        WHERE porder = @ls_head-orderhead
*                            INTO @ls_weigh.
*
*    NEED TO WRITE LOGIC IN METHOD get_instance_features TO fetch PO gross & netweight
      lv_weigh_GROSSWEIGHT = lcl_ls_buffer=>gv_header_grossweight_po.
      lv_weigh_netweight   = lcl_ls_buffer=>gv_header_netweight_po.

    ENDIF.
    CLEAR:  ls_head-grossweight, ls_head-netweight.

    ls_head-grossweight = lv_weigh_GROSSWEIGHT. " ls_weigh-grossweight.
    ls_head-netweight   = lv_weigh_netweight.  "ls_weigh-netweight.
    ls_head-Grossweight_f  = lv_weigh_GROSSWEIGHT. "25/10/2024
    ls_head-netweight_f   = lv_weigh_netweight. "25/10/2024
    DATA(lv_ticknum) = |{ ls_head-plant }{ lv_fyear }{ max_ticknum }|. "01-04
    MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE
           ENTITY head
               UPDATE
                   FROM VALUE #( FOR head IN heads INDEX INTO i    (
                       %tky  = head-%tky
                       ticknum = lv_ticknum
                       range = max_ticknum
                        grossweight = ls_head-grossweight
                        netweight = ls_head-netweight
                        grossweight_f = ls_head-Grossweight_f
                       netweight_f = ls_head-netweight_f
                       %control-ticknum = if_abap_behv=>mk-on
                       %control-range = if_abap_behv=>mk-on
                       %control-grossweight = if_abap_behv=>mk-on
                       %control-netweight = if_abap_behv=>mk-on
                       %control-grossweight_f = if_abap_behv=>mk-on  "25/10/2-24
                       %control-netweight_f = if_abap_behv=>mk-on  "25/10/2-24
                   )  )
         REPORTED DATA(update_reported).
  ENDMETHOD.

  METHOD validateinward.

    CONSTANTS: lv_ph_no  TYPE string VALUE 'QAZWSXEDCRFVTGBYHNUJMIKOLPqwertyuiopasdfghjklzxcvbnm~!@#$%^&*()_+=|}]{[}?/>.,<:"'';`',
               lv_Dname  TYPE string VALUE '0123456789~!@#$%^&*()_-+=|}]{[}?/>,<:"'';`',
               lv_Tname  TYPE string VALUE '~!#$%^&*()_-+=|}]{[}?/>,<:"'';`',
               lv_Veh_no TYPE string VALUE '~!@#$%^&*()_-+=|}]{[}?/>.,<:"'';`'.
    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE " zi_vehin_head IN LOCAL MODE
           ENTITY head
               FIELDS ( intype orderhead vehnum drivnum drivname tranname ) WITH CORRESPONDING #( keys )
                   RESULT DATA(head).
    TRY.
        DATA(ls_header) = head[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.


    IF ls_header-intype IS NOT INITIAL.
      SELECT SINGLE   ticknum,
                      intype
          FROM zwbi_vehicle_inward_data "zi_vehicle_inward_data  " view on table to fetch data
              WHERE inwarduuid = @ls_header-inward_uuid
                  INTO @DATA(ls_data).
      IF ls_data IS NOT INITIAL.
        IF ls_header-intype <> ls_data-intype.
          APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-001 }|
          )

          ) TO reported-head.
          APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.

        ENDIF.
      ENDIF.
    ELSE.
      APPEND VALUE #(
         %tky = ls_header-%tky
         %msg = new_message_with_text(
         severity = if_abap_behv_message=>severity-error
         text     = |{ TEXT-005 }|
      )

      ) TO reported-head.
      APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.
    ENDIF.

*    IF ls_header-vehnum IS INITIAL. "commented on 23/4/2025 not required now
*      APPEND VALUE #(
*           %tky = ls_header-%tky
*           %msg = new_message_with_text(
*           severity = if_abap_behv_message=>severity-error
*           text     = |{ TEXT-002 }|
*        )
*
*        ) TO reported-head.
*      APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.
*    ENDIF.
*
*    IF ls_header-drivnum IS INITIAL. "commented on 23/4/2025 not required now
*      APPEND VALUE #(
*           %tky = ls_header-%tky
*           %msg = new_message_with_text(
*           severity = if_abap_behv_message=>severity-error
*           text     = |{ TEXT-003 }|
*        )
*
*        ) TO reported-head.
*      APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.
*
*
*    ENDIF.

    IF ls_header-Vehnum IS NOT INITIAL.

      IF  ls_header-Vehnum CA lv_Veh_no .
        " Then raise a message
*         get message manager
*if sy-subrc eq 0.
        APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-010 }|
          )

          ) TO reported-head.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.

*endif.
      ENDIF.
    ENDIF.

    IF ls_header-drivnum IS NOT INITIAL.

      IF  ls_header-drivnum CA lv_ph_no .
        " Then raise a message
*         get message manager
*if sy-subrc eq 0.
        APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-007 }|
          )

          ) TO reported-head.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.

*endif.
      ENDIF.
    ENDIF.

    IF ls_header-Tranname IS NOT INITIAL.  "28-03

      IF  ls_header-Tranname CA lv_Tname.  "lv_Dname .
        " Then raise a message
*         get message manager
*if sy-subrc eq 0.
        APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-008 }|
          )

          ) TO reported-head.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.

*endif.
      ENDIF.
    ENDIF.


    IF ls_header-Drivname IS NOT INITIAL.  "28-03

      IF  ls_header-Drivname CA lv_Dname .
        " Then raise a message
*         get message manager
*if sy-subrc eq 0.
        APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-009 }|
          )

          ) TO reported-head.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.

*endif.
      ENDIF.
    ENDIF.

***************start***********4/5/2025 logic to stop saving or creating ticket without line item

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE c
            ENTITY head BY \_item
                ALL FIELDS WITH VALUE #( ( %tky = ls_header-%tky ) )
                    RESULT DATA(allitems).

    TRY.
        sort allitems[] by ordnum."1/5/2025
        DATA(ls_item) = allitems[ 1 ].
      CATCH cx_sy_itab_line_not_found.

select single ticknum from zwbi_vihd where  inward_uuid = @ls_header-Inward_uuid
      into @data(ls_ticknum) .
if ls_ticknum is not INITIAL.
       APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-016 }|
          )

          ) TO reported-head.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.
else.

 APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-017 }|
          )

          ) TO reported-head.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-head.

endif.
return.
endtry.
*************end ******4/5/2025***

  ENDMETHOD.

  METHOD defaultdata.
    CONSTANTS: lc_tzone TYPE cl_abap_context_info=>ty_time_zone VALUE 'INDIA'.

    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE lc_tzone INTO DATE DATA(lv_date) TIME DATA(lv_time).
    DATA(lv_ctime) = lv_time.
    CLEAR: lv_ctime.

    SELECT SINGLE fiscalyear
            FROM zwbi_fiscalcalendardate "zi_fiscalcalendardate  view
                WHERE fiscalyearvariant = 'V3'
                AND   calendardate = @lv_date
                        INTO @DATA(lv_fyear).
    IF lv_fyear IS INITIAL.
      lv_fyear = sy-datum+0(4).
    ENDIF.

    data(lv_sysdate) = sy-datum.
    data(lv_systime) = sy-uzeit.
    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE ENTITY "zi_vehin_head IN LOCAL MODE ENTITY
          head ALL FIELDS WITH CORRESPONDING #( keys )
              RESULT DATA(heads).

    DATA(ls_header) = heads[ 1 ].
     ls_header-CreatedOn = sy-datum.
     ls_header-CreatedTm = sy-uzeit.
    SELECT SINGLE * FROM i_businessuserbasic
    WHERE businesspartner = @sy-uname+2(10) into @data(ls_username).
    if sy-subrc EQ 0.
       ls_header-CreatedBy = ls_username-PersonFullName.
    endif.

    IF ls_header-indate IS INITIAL.
      MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
        ENTITY head
            UPDATE SET FIELDS WITH VALUE #(
                          FOR head IN heads (
                              %key = head-%key
                              %is_draft = head-%is_draft
                             indate = lv_date
                             intime = lv_time
                             fiscal = lv_fyear
                             pwitime = lv_ctime
                             CreatedBy = ls_username-PersonFullName
                             CreatedOn = lv_sysdate
                             CreatedTm = lv_systime
                             LastChangedOn = lv_sysdate
"                             Pwexittm = '000000' "if passing time zero hours its taking default time as 12 AM outward
                     "        range = '0000000001'
                          )
                  ) REPORTED DATA(modifyreported).
      reported = CORRESPONDING #( DEEP modifyreported ).
    ENDIF.
  ENDMETHOD.

  METHOD print.
    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE ENTITY "zi_vehin_head IN LOCAL MODE ENTITY
       head ALL FIELDS WITH CORRESPONDING #( keys )
           RESULT DATA(heads).
    TRY.
        DATA(ls_header) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
    TRY.
        cl_fp_fdp_services=>get_instance(
                 EXPORTING
                   iv_service_definition = 'ZUI_VEHIN_ENTRY_PRINT'
                   iv_root_node          = 'ZC_VEHIN_HEAD_PRINT'
                 RECEIVING
                   ro_api                = DATA(lo_fdp_api)
               ).
*              CATCH cx_fp_fdp_error.
        DATA(lt_keys)    = lo_fdp_api->get_keys( ).

        lt_keys[ name = 'INWARD_UUID' ]-value = ls_header-inward_uuid.

        DATA(lv_xsd)     = lo_fdp_api->get_xsd(  ).

        " DATA(lv_data) = lo_fdp_api->read_to_xml( lt_keys ).

        lo_fdp_api->read_to_xml(
          EXPORTING
            it_select   = lt_keys
            iv_language = sy-langu
          RECEIVING
            rv_xml      = DATA(lv_data)
        ).
        "        out->write( lv_xdp ).
*        CATCH cx_fp_fdp_error.

      CATCH cx_fp_fdp_error INTO DATA(lo_fp_fdp_error).
    ENDTRY.

    TRY.
*Render PDF
        cl_fp_ads_util=>render_pdf( EXPORTING iv_xml_data      = lv_data
                                              iv_xdp_layout    = lv_xsd
                                              iv_locale        = 'en_IN'
                      "                        is_options       = ls_options
                                    IMPORTING ev_pdf           = DATA(ev_pdf)
                                              ev_pages         = DATA(ev_pages)
                                              ev_trace_string  = DATA(ev_trace_string)
                                              ).

      CATCH cx_fp_ads_util INTO DATA(lo_fp_ads_util).

    ENDTRY.


  ENDMETHOD.

  METHOD get_instance_features.

    FIELD-SYMBOLS:
      <fs_data>          TYPE data,
      <fs_results>       TYPE any,
      <fs_structure>     TYPE any,
      <fs_hold>          TYPE any,
      <fs_error>         TYPE any,
      <fs_error_temp>    TYPE any,
      <fs_error_temp_d>  TYPE any,
      <fs_error_table>   TYPE  any,
      <fs_table>         TYPE  ANY TABLE,
      <fs_table_temp>    TYPE  ANY TABLE,
      <fs_field>         TYPE any,
      <fs_field_d>       TYPE any,
      <fs_field_value>   TYPE data,
      <fs_field_value_d> TYPE data.
    FIELD-SYMBOLS : <ls_table> TYPE any.
    FIELD-SYMBOLS : <ls_table_d> TYPE any.
    FIELD-SYMBOLS : <lv_severity>     TYPE any,
                    <fs_final_data>   TYPE data,
                    <fs_final_data_d> TYPE data.

    DATA: lr_data   TYPE REF TO data,
          lr_data_d TYPE REF TO data.

    DATA : " lt_cond TYPE STANDARD TABLE OF ty_cond,
      "ls_cond TYPE ty_cond,
      lv_so      TYPE c LENGTH 10,
      lv_SDIC    TYPE c LENGTH 4,
      lv_sitemno TYPE zwbi_dt_itemno,
      lv_uid16   TYPE zwbi_dt_uid.

    DATA: lv_test TYPE c.



    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
        ENTITY head
            ALL FIELDS WITH CORRESPONDING #( keys )
                RESULT DATA(lt_context_data)
                    FAILED failed.

    CLEAR:lv_SDIC.
    LOOP AT lt_context_data INTO DATA(ls_data).




***********************************************************
*Below API is used instead of cloud view zi_salesdocitmsubsqntprocflow
*API logic INPUT DELIVERY NUMBER from screen AND OUTPUT IS SALES ORDER

***end of standard procedure******************************************************


*for below zi_salesdocitmsubsqntprocflow select logic is used for cloud version can be uncommented and map the fields
*      SELECT SINGLE subsequentdocument
*              FROM zi_salesdocitmsubsqntprocflow
*                  WHERE subsqntdocitmprecdgdocument = @ls_data-orderhead
*                  AND subsequentdocumentcategory = 'M'
*                      INTO @DATA(lv_deldoc).
*      IF sy-subrc = 0.
**commented 17 start old
*      if lv_SDIC eq 'M'. "considering only invoiced documents which is type 'M'
*        DATA(lv_exist) = 'X'.
*      ELSE.
*        CLEAR lv_exist.
*        IF ls_data-intype = 'P'.
*          lv_exist = 'X'.
*        ENDIF.
*      ENDIF.
***end 17


      IF ls_data-intype = 'S'. "lv_SDIC eq 'M'. "considering only invoiced documents which is type 'M'
        DATA(lv_exist) = 'X'.
      ELSE.
        CLEAR lv_exist.
        IF ls_data-intype = 'P'.
          lv_exist = 'X'.
        ENDIF.
      ENDIF.


      APPEND VALUE #( %tky = ls_data-%tky  "old 21-05

*                           %update = COND #( WHEN ( ls_data-ticknum IS NOT INITIAL AND ( ls_data-type = 'BULK' ) )
*                                                             OR ( ls_data-pwigetwg = 'C' OR ls_data-pwogetwg = 'C' OR ls_data-pwexit = 'C' )
*                                 THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )

                           %assoc-_item = COND #( WHEN ( ls_data-ticknum IS NOT INITIAL AND ( ls_data-type = 'BULK' ) )
                                                             OR ( ls_data-pwigetwg = 'C' OR ls_data-pwogetwg = 'C' OR ls_data-pwexit = 'C' )
                                 THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )

                          %action-print = COND #( WHEN ( ls_data-ticknum IS INITIAL OR ls_data-pwexit = 'C' OR ls_data-pwigetwg = 'C' OR ls_data-pwogetwg = 'C'  )
                                                              THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )

              %action-setoutward = COND #( WHEN ( ( ls_data-ticknum IS INITIAL OR ls_data-pwexit = 'C' OR ls_data-Hdevlstatus = 'P' OR  ( ls_data-pwigetwg = ' ' AND ls_data-pwogetwg = ' ' ) " considering delivered complete & partial SO for outward enabled
                   OR  ( ls_data-pwigetwg = ' ' AND ls_data-pwogetwg NE ' ' ) OR  ( ls_data-pwigetwg NE ' ' AND ls_data-pwogetwg EQ ' ' ) OR lv_exist = ' ' ) )
                    THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )   "ADDED  newly on 20-05 ls_data-Hdevlstatus = 'P' "2nd change

*                     %action-setoutward = COND #( WHEN ( ( ls_data-ticknum IS INITIAL OR ls_data-pwexit = 'C' OR ls_data-Hdevlstatus = 'P' OR  ( ls_data-pwigetwg = ' ' AND ls_data-pwogetwg = ' ' ) OR lv_exist = ' ' ) )
*                                                         THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )   "ADDED  newly on 09-04 ls_data-Hdevlstatus = 'P'  1st change

*                    %action-setoutward = COND #( WHEN ( ( ls_data-ticknum IS INITIAL OR ls_data-pwexit = 'C' OR ( ls_data-pwigetwg = ' ' AND ls_data-pwogetwg = ' ' ) OR lv_exist = ' ' ) )
*                                                         THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )  "09-05 old

                         %delete = COND #( WHEN ( ls_data-pwigetwg = 'C' OR ls_data-pwogetwg = 'C' OR ls_data-pwexit = 'C' )
                                THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )   "08-04 logic to disable delete button either Tare or Gross weight is captured or both


          )
          TO result.

*  endif.

      CLEAR lv_exist.
    ENDLOOP.

  ENDMETHOD.

  METHOD getorderdata.

    FIELD-SYMBOLS:
***SO Header
      <fs_data_dh>        TYPE data,
      <fs_results_dh>     TYPE any,
      <fs_structure_dh>   TYPE any,
      <fs_hold_dh>        TYPE any,
      <fs_error_dh>       TYPE any,
      <fs_error_temp_dh>  TYPE any,
      <fs_error_table_dh> TYPE any,
      <fs_table_dh>       TYPE ANY TABLE,
      <fs_table_temp_dh>  TYPE ANY TABLE,
      <fs_field_dh>       TYPE any,
      <fs_field_value_dh> TYPE data,

***SO item
      <fs_data_di>        TYPE data,
      <fs_results_di>     TYPE any,
      <fs_structure_di>   TYPE any,
      <fs_hold_di>        TYPE any,
      <fs_error_di>       TYPE any,
      <fs_error_temp_di>  TYPE any,
      <fs_error_table_di> TYPE any,
      <fs_table_di>       TYPE ANY TABLE,
      <fs_table_temp_di>  TYPE ANY TABLE,
      <fs_field_di>       TYPE any,
      <fs_field_value_di> TYPE data,

***PO Header
      <fs_data_ph>        TYPE data,
      <fs_results_ph>     TYPE any,
      <fs_structure_ph>   TYPE any,
      <fs_hold_ph>        TYPE any,
      <fs_error_ph>       TYPE any,
      <fs_error_temp_ph>  TYPE any,
      <fs_error_table_ph> TYPE any,
      <fs_table_ph>       TYPE ANY TABLE,
      <fs_table_temp_ph>  TYPE ANY TABLE,
      <fs_field_ph>       TYPE any,
      <fs_field_value_ph> TYPE data.



***SO Header
    FIELD-SYMBOLS : <ls_table_dh> TYPE any.
    FIELD-SYMBOLS : <lv_severity_dh>   TYPE any,
                    <fs_final_data_dh> TYPE data.
    DATA: lr_data_dh TYPE REF TO data.

*****SO Item
    FIELD-SYMBOLS : <ls_table_di> TYPE any.
    FIELD-SYMBOLS : <lv_severity_di>   TYPE any,
                    <fs_final_data_di> TYPE data.
    DATA: lr_data_di      TYPE REF TO data,
          lv_public_cloud TYPE c LENGTH 1 . "VALUE 'X'.
*****

***PO Header
    FIELD-SYMBOLS : <ls_table_ph> TYPE any.
    FIELD-SYMBOLS : <lv_severity_ph>   TYPE any,
                    <fs_final_data_ph> TYPE data.
    DATA: lr_data_ph TYPE REF TO data.

***Variable declartions
    DATA: lv_header_grossweight TYPE string, "zWBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
          lv_header_netweight   TYPE string, "zWBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
          lv_header_weightuint  TYPE  c LENGTH 3.

    DATA : gv_web_di TYPE string.
    DATA : gv_web_di2 TYPE string.
    DATA : gv_web_di3 TYPE string.
    DATA: lv_so_det_di TYPE string,
          lv_dchan     TYPE c LENGTH 2.


    TYPES : BEGIN OF ty_ditems,
              Deldoc         TYPE c LENGTH 10,
              item           TYPE zwbi_dt_itemno,
              plant          TYPE c LENGTH 4,
              dchan          TYPE c LENGTH 2,
              ItemGWeight    TYPE zwbi_dt_quantity,
              ItemNWeight    TYPE  zwbi_dt_quantity,
              ItemWeightUnit TYPE c LENGTH 3,
            END OF ty_ditems.
*
    DATA : lt_ditems TYPE STANDARD TABLE OF ty_ditems,
           ls_ditems TYPE ty_ditems.

****cloud destinations fetching from table
*    SELECT SINGLE sysname,
*      cflag,
*      cdest,
*      curl
*      FROM zwbi_dcong WHERE  cflag = 'X'  INTO @DATA(ls_cdest).

*    IF ls_cdest-sysname = 'C'.

*      lv_public_cloud  = ls_cdest-cflag.
*    ENDIF.


*******

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE ENTITY " zi_vehin_head IN LOCAL MODE ENTITY
          head ALL FIELDS WITH CORRESPONDING #( keys )
              RESULT DATA(heads).

    TRY.
        DATA(ls_header) = heads[ 1 ].
*ls_header-Planttext =   ls_header-Plant+5(25).
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    SELECT SINGLE * FROM i_businessuserbasic
    WHERE businesspartner = @sy-uname+2(10) into @data(ls_username).
    if sy-subrc EQ 0 and ls_header-CreatedBy is NOT INITIAL.
       ls_header-LastChangedBy = ls_username-PersonFullName.
    endif.

*****fetching selected item delivery number form entity set.
    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE c
            ENTITY head BY \_item
                ALL FIELDS WITH VALUE #( ( %tky = ls_header-%tky ) )
                    RESULT DATA(allitems1).

************ 1/5/2025
*if allitems1[] is not INITIAL.
* DATA(ls_item1) = allitems1[ 1 ].
* endif.
***********
    TRY.
      DATA(ls_item1) = allitems1[ 1 ].
        ls_header-Planttext =  ls_item1-Planttext.   " "plant text update to header table from item
*          ls_header-shipptext = ls_item1-
      CATCH cx_sy_itab_line_not_found.
           RETURN.
    ENDTRY.


    IF ls_header-intype = 'S'.


************fetching delivery header details using API*********************

*******************************start of new logic ********************************************
*****************Below logic to fetch delivery item data using API***********

* below commented code to call FM from S4D system using destinations***************************
      "IF ls_header-Plant is not INITIAL.
      IF ls_item1-Ordnum IS NOT INITIAL.
        TRY.


SELECT deliverydocument, deliverydocumentitem,distributionchannel,plant,itemgrossweight,
       itemnetweight,itemweightunit from I_DeliveryDocumentItem
        where deliverydocument = @ls_item1-Ordnum and GoodsMovementStatus ne 'C'
        into TABLE @data(lt_delitem).

        if sy-subrc EQ 0.

          loop at lt_delitem into data(ls_delitem).
            ls_ditems-deldoc = ls_delitem-deliverydocument.
            ls_ditems-item = ls_delitem-deliverydocumentitem.
            ls_ditems-dchan = ls_delitem-distributionchannel.
            ls_ditems-plant = ls_delitem-plant.
            ls_ditems-ItemGWeight = ls_delitem-itemgrossweight.
            ls_ditems-ItemNWeight = ls_delitem-itemnetweight.
            ls_ditems-ItemWeightUnit = ls_delitem-itemweightunit.
            lv_dchan   = ls_ditems-dchan.
            APPEND ls_ditems TO lt_ditems.
            CLEAR:ls_ditems.

          ENDLOOP.
        endif.
*              ENDIF.
*            ENDIF.

          CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
        ENDTRY.

      ENDIF.
******************************end of new logic
*for below zi_salesdocitmsubsqntprocflow select logic is used for cloud version can be uncommented and map the fields
*   SELECT SINGLE sorder,
*                    distributionchannel,
*                    plant
*              FROM zi_sorder_data
*                  WHERE sorder = @ls_header-orderhead
*                      INTO @DATA(ls_sorder).

      SORT lt_ditems BY deldoc item.
      DELETE lt_ditems WHERE Dchan EQ space.
*         read table  lt_ditems into data(ls_sorder) with key deldoc = ls_header-orderhead."17
      READ TABLE  lt_ditems INTO DATA(ls_sorder) WITH KEY deldoc = ls_item1-Ordnum
                                                           plant = ls_header-Plant."+0(4). "01-04
      CHECK sy-subrc = 0.
      IF ls_sorder-Dchan = '10'. " ls_sorder-distributionchannel = '10'.
        DATA(lv_type) = 'PACK'.
      ELSEIF ls_sorder-Dchan = '15'." ls_sorder-distributionchannel = '15'.
        lv_type = 'BULK'.
      ELSEIF ls_sorder-Dchan = '30'. "ls_sorder-distributionchannel = '30'.
        lv_type = 'PO'.
      ENDIF.

      MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
          ENTITY head
              UPDATE SET FIELDS WITH VALUE #(
                            FOR head IN heads (
                                %key = head-%key
                                %is_draft = head-%is_draft
                               plant = ls_sorder-plant
                               Planttext  = ls_header-planttext  "10-04
                               type = lv_type
                               dchannel = ls_sorder-Dchan "ls_sorder-distributionchannel
                              )
                    ) REPORTED DATA(modifyreported).
      reported = CORRESPONDING #( DEEP modifyreported ).

    ELSEIF ls_header-intype = 'P'.

*****************************logic to fetch Purchase order data using API *************************************
*below logic BTP API is used in place of cloud version view zi_porder_data logic
*  if ls_header-orderhead is NOT INITIAL. "09-03
      IF ls_item1-Ordnum IS NOT INITIAL. "09-03
*************
        DATA : gv_web_ph TYPE string.
        DATA : gv_web_ph2 TYPE string.
        DATA : gv_web_ph3 TYPE string.

        DATA: lv_POdoc    TYPE c LENGTH 10,
              lv_potyp    TYPE c LENGTH 4,
              lv_ccode    TYPE c LENGTH 4,
              lv_po_dchan TYPE c LENGTH 2.



        TRY.

    SELECT SINGLE purchaseorder, companycode,purchaseordertype from I_PurchaseOrderTP_2
           where purchaseorder = @ls_item1-Ordnum into @data(ls_pohead).
         if sy-subrc eq 0.
            lv_POdoc  = ls_pohead-PurchaseOrder.
            lv_ccode  = ls_pohead-CompanyCode.
            lv_potyp = ls_pohead-PurchaseOrderType.
         endif.
          CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
        ENDTRY.


**********************************************************************
**for below zi_porder_data select logic is used for cloud version can be uncommented and map the fields
*   SELECT SINGLE porder,
*                  distributionchannel,
*                  plant
*            FROM zi_porder_data
*                WHERE porder = @ls_header-orderhead
*                    INTO @DATA(ls_porder).


        lv_type = 'PO'.

        MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
         ENTITY head
             UPDATE SET FIELDS WITH VALUE #(
                           FOR head IN heads (
                               %key = head-%key
                               %is_draft = head-%is_draft
                              plant = lv_ccode  "ls_porder-plant
                              Planttext  = ls_header-planttext  "10-04
                              type = lv_type
                              dchannel = lv_po_dchan "ls_porder-Dchannel " NEED TO FETCH PO Distchannel data from API
                           )
                   ) REPORTED DATA(modifyreported1).
        reported = CORRESPONDING #( DEEP modifyreported1 ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD setitem.
    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
        ENTITY head
            ALL FIELDS WITH CORRESPONDING #( keys )
              RESULT DATA(heads).
    TRY.
        DATA(ls_header) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

****************17 logic added validation **********************


    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE c
            ENTITY head BY \_item
                ALL FIELDS WITH VALUE #( ( %tky = ls_header-%tky ) )
                    RESULT DATA(allitems).

    TRY.
        sort allitems[] by ordnum."1/5/2025
        DATA(ls_item) = allitems[ 1 ].
      CATCH cx_sy_itab_line_not_found.

*********start of new logic 1/5/2025 logic to stop creating WKT without line items

if ls_header-Ticknum is INITIAL and allitems[] is INITIAL.

APPEND VALUE #(
               %tky = ls_header-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-error
               text     = |{ TEXT-015 }|


            )

            ) TO reported-head.

            return.
endif.
***********end of new logic 1/5/2025
   ENDTRY.


    IF ls_item-ordnum IS INITIAL and allitems[] is not INITIAL.

      APPEND VALUE #(
               %tky = ls_item-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-error
               text     = |{ TEXT-006 }|
            )

            ) TO reported-item.
*  APPEND VALUE #( %tky = ls_item-%tky ) TO  reported-item.
      RETURN.

    ENDIF.

  ENDMETHOD.

  METHOD calctotweight.
    DATA: lv_grwg TYPE p,
          lv_ntwg TYPE p.

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE ENTITY "zi_vehin_head IN LOCAL MODE ENTITY
          head ALL FIELDS WITH CORRESPONDING #( keys )
              RESULT DATA(heads).

    TRY.
        DATA(ls_header) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
            ENTITY head BY \_item
                ALL FIELDS WITH VALUE #( ( %tky = ls_header-%tky  ) )
                    RESULT DATA(item).


    LOOP AT item INTO DATA(ls_item).

      lv_grwg = lv_grwg + ls_item-grossweight.
      lv_ntwg = lv_ntwg + ls_item-netweight.
    ENDLOOP.

data: lv_lc_date  type sydate.
        lv_lc_date = ls_header-LastChangedAt.
    MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
            ENTITY head
                UPDATE SET FIELDS WITH VALUE #(
                              FOR head IN heads (
                                  %key = head-%key
                                  %is_draft = head-%is_draft
                                 grossweight = lv_grwg
                                 netweight = lv_ntwg
                                 Grossweight_f = lv_grwg   "25/10/2024
                                 Netweight_f  = lv_ntwg     "25/10/2024
                                 LastChangedOn  = lv_lc_date  "ls_header-LastChangedAt+0(8)
                                )
                      ) REPORTED DATA(modifyreported).
    reported = CORRESPONDING #( DEEP modifyreported ).
  ENDMETHOD.

  METHOD setoutward.
    CONSTANTS: lc_tzone TYPE cl_abap_context_info=>ty_time_zone VALUE 'INDIA'.
    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE lc_tzone INTO DATE DATA(lv_date) TIME DATA(lv_time).

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
           ENTITY head
               ALL FIELDS WITH CORRESPONDING #( keys )
                   RESULT DATA(heads).
    TRY.
        DATA(ls_head) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        DATA(ls_key) = keys[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    UPDATE zwbi_vinh SET pwexit = 'C', "zdt_vehin_head SET pwexit = 'C',
                            pwexitdt = @lv_date,
                            pwexittm = @lv_time
        WHERE inward_uuid = @ls_key-inward_uuid.

  ENDMETHOD.

ENDCLASS.