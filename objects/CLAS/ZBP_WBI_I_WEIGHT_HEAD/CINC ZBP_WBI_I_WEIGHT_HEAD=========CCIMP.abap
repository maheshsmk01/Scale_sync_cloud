CLASS lhc_Head DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Head RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Head RESULT result.

      METHODS getEdit FOR MODIFY
      IMPORTING keys FOR ACTION head~getEdit ."RESULT result. "24-06 added RESULT result.

       METHODS getHeadEdit FOR MODIFY
      IMPORTING keys FOR ACTION head~getHeadEdit."RESULT result. "24-06 added RESULT result.

    METHODS getWeightGross FOR MODIFY
      IMPORTING keys FOR ACTION Head~getWeightGross.

    METHODS getWeightTare FOR MODIFY
      IMPORTING keys FOR ACTION Head~getWeightTare.

     METHODS getdefaultsforgetEdit FOR READ
      IMPORTING keys FOR FUNCTION head~getdefaultsforgetEdit RESULT result.

       METHODS getdefaultsforgetHeadEdit FOR READ
     IMPORTING keys FOR FUNCTION head~getdefaultsforgetHeadEdit RESULT result.

    METHODS getweight
      IMPORTING VALUE(iv_plant) TYPE werks_d
      RETURNING VALUE(result)   TYPE string.
ENDCLASS.

CLASS lhc_Head IMPLEMENTATION.

METHOD get_instance_authorizations.
  ENDMETHOD.

 method getdefaultsforgetEdit. "//logic to populate data on popup screen

data: lv_count type int2.
     READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
         ENTITY head
             ALL FIELDS WITH CORRESPONDING #( keys )
                 RESULT DATA(heads).
    TRY.
        DATA(ls_head) = heads[ 1 ].

         APPEND VALUE #( %tky = ls_head-%tky
                      %param-GWeightU  = ls_head-pwoempwg
                      %param-TWeightU  = ls_head-pwiempwg
       ) TO result.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

  ENDMETHOD.

METHOD getdefaultsforgetHeadEdit. "//logic to populate data on popup screen 11/4

    data: lv_count type int2.
     READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
         ENTITY head
             ALL FIELDS WITH CORRESPONDING #( keys )
                 RESULT DATA(heads).
    TRY.
        DATA(ls_head) = heads[ 1 ].

                      APPEND VALUE #( %tky = ls_head-%tky
                                    %param-intype_h     = ls_head-Intype
                                    %param-plant_h      = ls_head-Plant
                                    %param-vehnum_h      = ls_head-Vehnum
                                    %param-drivname_h     = ls_head-drivname
                                    %param-drivnum_h       = ls_head-Drivnum
                                    %param-tranname_h       = ls_head-tranname

       ) TO result.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
           ENTITY head
              ALL FIELDS WITH CORRESPONDING #( keys )
                   RESULT DATA(heads)
                   FAILED failed.


    result = VALUE #( FOR head IN heads
     LET status = COND #(
                         WHEN head-pwigetwg = 'C'
                         THEN if_abap_behv=>fc-o-disabled
                         ELSE if_abap_behv=>fc-o-enabled )
                         IN (  %tky = head-%tky
                               %action-getweighttare = status
                         )
       ).


*    SELECT * FROM zwbi_vin_i  for all entries in @heads
*    where inward_uuid = @heads-inwarduuid INTO TABLE @DATA(lt_weight_item).  "14-06
*  sort  result by  inwarduuid. "14-06 new
*  sort lt_weight_item by inward_uuid. "14-06 new
    LOOP AT result ASSIGNING FIELD-SYMBOL(<fs_result>)."tare and gross weight button enable logic

      DATA(ls_head) = heads[ %key = <fs_result>-%key ].

*loop at lt_weight_item into data(ls_weight_item) where inward_uuid = ls_head-InwardUuid. "14-06 new only statement loop logic to consider GR fully or partial to enable tare wgt button

*     IF ls_weight_item-PODELVSTATUS+0(1) = 'F' OR ls_weight_item-PODELVSTATUS+0(1) = 'P'. "14-06

      IF ls_head-pwogetwg = 'C'.   "sales side
        <fs_result>-%action-getweightgross = if_abap_behv=>fc-o-disabled.
      ELSE.
        IF ls_head-intype = 'P'.
          <fs_result>-%action-getweightgross = if_abap_behv=>fc-o-enabled.
        ELSE.
          IF ls_head-pwigetwg = 'C'.
            <fs_result>-%action-getweightgross = if_abap_behv=>fc-o-enabled.
          ELSE.
            <fs_result>-%action-getweightgross = if_abap_behv=>fc-o-disabled.
            <fs_result>-%action-getEdit = if_abap_behv=>fc-o-disabled." 04/02/2025 "zero weights edit button disable logic
          ENDIF  .
        ENDIF.
      ENDIF.

      CLEAR <fs_result>-%action-getweighttare.
      IF ls_head-pwigetwg = 'C'.
        <fs_result>-%action-getweighttare = if_abap_behv=>fc-o-disabled.
      ELSE.
        IF ls_head-intype = 'S'.
          <fs_result>-%action-getweighttare = if_abap_behv=>fc-o-enabled.
        ELSE.
         IF ls_head-pwogetwg = 'C'.  "old 14-06
*         if   ls_head-pwogetwg = 'C' and ( ls_weight_item-podelvstatus+0(1) = 'F' or ls_weight_item-podelvstatus+0(1) = 'P' ). "new 14-06
            <fs_result>-%action-getweighttare = if_abap_behv=>fc-o-enabled. "07-05  old
*            <fs_result>-%action-getweighttare = if_abap_behv=>fc-o-disabled. "07-05 new
          ELSE.
            <fs_result>-%action-getweighttare = if_abap_behv=>fc-o-disabled. "07-05 old
*             <fs_result>-%action-getweighttare = if_abap_behv=>fc-o-enabled. "07-05  new
            <fs_result>-%action-getEdit = if_abap_behv=>fc-o-disabled." 04/02/2025 "zero weights edit button disable logic
          ENDIF.
        ENDIF.
      ENDIF.

*      ELSE. ""14-06

* WRITE MESSAGE THAT GR NOT DONE

*     ENDIF.""14-06

*      endloop. "14-06 new only statement loop

    ENDLOOP.

  ENDMETHOD.


  METHOD getheadedit.  "//11/4/2025

  data:  lv_Intype TYPE string,
         lv_Plant TYPE string.


READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
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




*      if ls_key-%param-intype_h is not INITIAL.
        clear:ls_head-Intype.
        ls_head-Intype = ls_key-%param-intype_h.
        lv_Intype =  ls_key-%param-intype_h.

*        endif.

*         if ls_key-%param-plant_h is not INITIAL.
clear:ls_head-plant.
        ls_head-Plant = ls_key-%param-plant_h.
        lv_Plant  =   ls_key-%param-plant_h.

*        endif.

*         if ls_key-%param-vehnum_h is not INITIAL.
clear:ls_head-Vehnum.
        ls_head-Vehnum = ls_key-%param-vehnum_h.

*        endif.

*         if ls_key-%param-drivname_h is not INITIAL.
clear:ls_head-drivname.
        ls_head-drivname = ls_key-%param-drivname_h.

*        endif.

*         if ls_key-%param-drivnum_h is not INITIAL.
clear:ls_head-Drivnum.
        ls_head-Drivnum = ls_key-%param-drivnum_h.

*        endif.

*         if ls_key-%param-tranname_h is not INITIAL.
clear:ls_head-tranname.
        ls_head-tranname = ls_key-%param-tranname_h.

*        endif.



data(lv_sysdate) = sy-datum.
    data(lv_systime) = sy-uzeit.
    ls_head-CreatedOn = sy-datum.
     ls_head-CreatedTm = sy-uzeit.

     SELECT SINGLE * FROM i_businessuserbasic
    WHERE businesspartner = @sy-uname+2(10) into @data(ls_username).
    if sy-subrc EQ 0.
       ls_head-LastChangedBy = ls_username-PersonFullName.
    endif.


        UPDATE ZWBI_VINH SET  Intype  = @lv_Intype ,
                                    Plant  = @lv_Plant,
                                    Vehnum  = @ls_head-Vehnum,
                                    drivname = @ls_head-drivname,
                                    Drivnum = @ls_head-Drivnum,
                                    tranname       = @ls_head-tranname,
                                    last_changed_by = @ls_head-LastChangedBy,
                                    Last_changed_by_n = @ls_username-PersonFullName,
                                    last_changed_on =  @lv_sysdate
                              WHERE inward_uuid     = @ls_key-inwarduuid.

               APPEND VALUE #(                 "newly added
               %tky = ls_head-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-success
               text     =  |{ TEXT-011 }|
            )
              ) TO reported-head.
               RETURN.




  ENDMETHOD.



Method Getedit.  "03/2/2025 "Logic to edit Tare and Gross weight after capturing weights

  data:  lv_weight_T_U TYPE string,
         lv_weight_G_U TYPE string.

 CONSTANTS: lc_tzone TYPE cl_abap_context_info=>ty_time_zone VALUE 'INDIA'.
    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE lc_tzone INTO DATE DATA(lv_date) TIME DATA(lv_time).


   READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
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

if ls_key-%param-GWeightU is not INITIAL.
        clear:lv_weight_G_U.
        lv_weight_G_U = ls_key-%param-GWeightU.

        endif.

if ls_key-%param-TWeightU is not INITIAL.
        clear:lv_weight_T_U.
        lv_weight_T_U = ls_key-%param-TWeightU.

        endif.

 IF ( ls_head-pwoempwg IS INITIAL OR ls_head-pwoempwg = 0 ) and ( lv_weight_G_U IS not INITIAL OR lv_weight_G_U LE 0 ).
      APPEND VALUE #(
           %tky = ls_head-%tky
           %msg = new_message_with_text(
           severity = if_abap_behv_message=>severity-error
           text     = |{ TEXT-010 }|
          )
          ) TO reported-head.
      APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.
      RETURN.
    ENDIF.

IF ( ls_head-pwiempwg IS INITIAL OR ls_head-pwiempwg = 0 ) and ( lv_weight_T_U IS not INITIAL OR lv_weight_T_U LE 0 ).
      APPEND VALUE #(
           %tky = ls_head-%tky
           %msg = new_message_with_text(
           severity = if_abap_behv_message=>severity-error
           text     = |{ TEXT-010 }|
          )
          ) TO reported-head.
      APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.
      RETURN.
    ENDIF.


if lv_weight_g_u is INITIAL or lv_weight_g_u LE 0.
clear:lv_weight_g_u.
lv_weight_g_u = ls_head-pwoempwg.

endif.


if lv_weight_t_u is INITIAL or lv_weight_t_u LE 0.
clear:lv_weight_t_u.
lv_weight_t_u = ls_head-pwiempwg.
endif.


data(lv_sysdate) = sy-datum.
    data(lv_systime) = sy-uzeit.
    ls_head-CreatedOn = sy-datum.
     ls_head-CreatedTm = sy-uzeit.

     SELECT SINGLE * FROM i_businessuserbasic
    WHERE businesspartner = @sy-uname+2(10) into @data(ls_username).
    if sy-subrc EQ 0.
       ls_head-LastChangedBy = ls_username-PersonFullName.
    endif.


         UPDATE ZWBI_VINH SET pwoempwg = @lv_weight_g_u,   "'280.51',
                                    pwiempwg = @lv_weight_t_u,
                                    pwiuom = @ls_head-Itemunit, "'KG',          "KG is hard coded UOM to table need to change
                                    pwodate = @lv_date,
                                    pwotime = @lv_time,
                                    pwogetwg = 'C',
                                    pwoempwg_f = @lv_weight_g_u,  "for F4 Filter only
                                    gunit_f   = @ls_head-Itemunit, "'KG', ""for F4 Filter only
                                    pwiempwg_f = @lv_weight_t_u, "only for F4 filter
                                    tunit_f = @ls_head-Itemunit, "'KG',            "only for F4 filter
                                    last_changed_by = @ls_head-LastChangedBy,
                                    Last_changed_by_n = @ls_username-PersonFullName,
                                    last_changed_on =  @lv_sysdate
                  WHERE inward_uuid = @ls_key-inwarduuid.

               APPEND VALUE #(                 "newly added
               %tky = ls_head-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-success
               text     =  |{ TEXT-009 }|
            )
              ) TO reported-head.
               RETURN.


  ENDMETHOD.

  METHOD getweightgross.

  data: lr_data          TYPE REF TO data,
        lv_public_cloud   type c LENGTH 1 VALUE 'X'.
    CONSTANTS: lc_tzone TYPE cl_abap_context_info=>ty_time_zone VALUE 'INDIA'.
    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE lc_tzone INTO DATE DATA(lv_date) TIME DATA(lv_time).

    DATA: lv_htol   TYPE p DECIMALS 3,
          lv_ltol   TYPE p DECIMALS 3,
          lv_tol    TYPE p DECIMALS 3,
          lv_wgt    TYPE p DECIMALS 3,
          lv_weight TYPE string.

            DATA : gv_web TYPE string.
            DATA lv_po_det TYPE string.
****
 DATA :           LV_SO   type c LENGTH 10,
                   lv_SDIC   TYPE C LENGTH 4,
                   lv_sitemno type ZWBI_DT_ITEMNO,
                    LV_DVer   type N LENGTH 4.
FIELD-SYMBOLS:
      <fs_data>        TYPE data,
      <fs_results>     TYPE any,
      <fs_structure>   TYPE any,
      <fs_hold>        TYPE any,
      <fs_error>       TYPE any,
      <fs_error_temp>  TYPE any,
      <fs_error_table> TYPE  any,
      <fs_table>       TYPE  ANY TABLE,
      <fs_table_temp>  TYPE  ANY TABLE,
      <fs_field>       TYPE any,
      <fs_field_value> TYPE data.

    FIELD-SYMBOLS : <ls_table> TYPE any.
    FIELD-SYMBOLS : <fs_final_data> TYPE data.

****cloud destinations fetching from table
*select single sysname,
*  cflag,
*  cdest,
*  curl
*  from /N4C03/WBI_DCONG where  cflag = 'X'  into @data(ls_cdest).
*
*  if ls_cdest-sysname = 'C'.
*
*  lv_public_cloud  = ls_cdest-cflag.
*  endif.


*******
    READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
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

    CALL METHOD getweight " capturing Gross weight from live weigh bridge
      EXPORTING
        iv_plant = ls_head-plant
      RECEIVING
        result   = lv_weight.

*         lv_weight  = '3121.00'. "'3185.00'. " old 320 "gross weight for testing need to remove later
** Capturing data from Capture TareWeight popup and passing to local variable
       if ls_key-%param-GrossWeight is not INITIAL.
        clear:lv_weight.
        lv_weight = ls_key-%param-GrossWeight.
        else.
        lv_weight  = '3121.00'. "'3185.00'. " old 320 "gross weight for testing need to remove later
        endif.

    IF lv_weight IS INITIAL OR lv_weight = 0.
      APPEND VALUE #(
           %tky = ls_head-%tky
           %msg = new_message_with_text(
           severity = if_abap_behv_message=>severity-error
           text     = |{ TEXT-005 }|
          )
          ) TO reported-head.
      APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.
      RETURN.
    ENDIF.

    IF ls_head-intype = 'S' or ls_head-intype = 'P'.
      IF ls_head-type = 'PACK'  or ls_head-type = 'PO'.



*       CONDENSE ls_head-grossweight. "10-04
       data(lv_gtest) = lv_weight. "after testing need to remove this statement later its not required
        lv_weight =   lv_weight + ls_head-grossweight. "after testing need to remove this statement later its not required

        ls_head-grossweight = ls_head-grossweight + ls_head-pwiempwg.
*        CONDENSE ls_head-grossweight. "10-04
        lv_htol = ls_head-grossweight + ( ls_head-grossweight * 25 / 10000 ). "0.25 tolerance added
        lv_ltol = ls_head-grossweight - ( ls_head-grossweight * 25 / 10000 ).
*
        if ls_head-intype = 'P'. ""after testing need to remove this statement later its not required
        lv_htol  = lv_htol + lv_gtest.  ""after testing need to remove this statement later its not required
        lv_ltol  = lv_ltol + lv_gtest.  ""after testing need to remove this statement later its not required
        endif.  ""after testing need to remove this statement later its not required
*
*
       IF lv_weight BETWEEN lv_ltol AND lv_htol. "if tolerance is required then uncomment this statement.  "08-04
*        IF lv_weight is not initial. " comment this, once above if condition is uncommented               "08-04
**** Logic to get the Gross Weight
*          UPDATE zdt_vehin_head SET pwoempwg = @lv_weight,   "'280.51',
         UPDATE ZWBI_VINH SET pwoempwg = @lv_weight,   "'280.51',
                                    pwiuom = @ls_head-Itemunit,"'KG',          "KG is hard coded UOM to table need to change
                                    pwodate = @lv_date,
                                    pwotime = @lv_time,
                                    pwogetwg = 'C',
                                    pwoempwg_f = @lv_weight,  "for F4 Filter only
                                    gunit_f   = @ls_head-Itemunit"'KG' ""for F4 Filter only
                  WHERE inward_uuid = @ls_key-inwarduuid.

               APPEND VALUE #(                 "newly added
               %tky = ls_head-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-information  "severity-success
                 text     =  |{ TEXT-014 } { lv_weight } { ls_head-Itemunit } { TEXT-015 }|    "{ TEXT-006 }
            )
              ) TO reported-head.
               RETURN.
        ELSE.

          APPEND VALUE #(
          %tky = ls_head-%tky
          %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = |{ TEXT-001 } { lv_weight } { TEXT-002 } { ls_head-grossweight }|
       )

       ) TO reported-head.
          APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.
          RETURN.
        ENDIF.
      ELSEIF ls_head-type = 'BULK'.

*        CONDENSE ls_head-grossweight. "10-04
        ls_head-grossweight = ls_head-grossweight + ls_head-pwiempwg.
*        CONDENSE ls_head-grossweight. "10-04

        lv_htol = ls_head-grossweight + ( ls_head-grossweight * 2 / 100 ).
        lv_ltol = ls_head-grossweight - ( ls_head-grossweight * 2 / 100 ).

*
        IF lv_weight BETWEEN lv_ltol AND lv_htol. "if tolerance is required then uncomment this statement."08-04
*       IF lv_weight is not initial. " comment this, once above if condition is uncommented                "08-04

          lv_wgt = ( lv_weight - ls_head-pwiempwg ) / 1000.
*          UPDATE zdt_vehin_head SET pwoempwg = @lv_weight,
          UPDATE ZWBI_VINH SET pwoempwg = @lv_weight,
                                pwiuom = @ls_head-Itemunit,"'KG',       "KG is hard coded UOM to table need to change
                                pwodate = @lv_date,
                                pwotime = @lv_time,
                                pwogetwg = 'C',
                                pwoempwg_f = @lv_weight,  "for F4 Filter only
                                gunit_f   = @ls_head-Itemunit "'KG' ""for F4 Filter only
              WHERE inward_uuid = @ls_key-inwarduuid.

**************************logic to read outbound delivery using API************************************************
  TRY.
*************start of cloud destination testing
clear:ls_head-orderhead.
select single ordnum    " getting order number from Veh inwd item table
from ZWBI_VIN_I
where inward_uuid = @ls_head-InwardUuid into @ls_head-orderhead.

*if lv_public_cloud eq 'X'. "public cloud destinations logic
*
 DATA(lo_destination) = cl_http_destination_provider=>create_by_cloud_destination(
          i_name       = 'my403232_Public_cloud' " public cloud demo system working 06
          i_authn_mode = if_a4c_cp_service=>service_specific
        ).
***********below logic is URL preparing logic*********
*  CLEAR : gv_web,lv_po_det.
*            gv_web = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryHeader'.
*"            lv_po_det =  |('{ ls_head-orderhead }')/to_DeliveryDocumentItem|.
*
*endif.


*if lv_public_cloud eq space. " on premise destination logic
*
*          lo_destination = cl_http_destination_provider=>create_by_cloud_destination(
*          i_name       = 'F4D_400_CLONING_RP1'  " get this from BTP sub account
*          i_authn_mode = if_a4c_cp_service=>service_specific
*        ).
*
***********below logic is URL preparing logic*********
*  CLEAR : gv_web,lv_po_det.
*            gv_web = 'https://itcf4d.intern.itelligence.de:8000/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryHeader'.
*"         lv_po_det =  |('{ ls_head-orderhead }')/to_DeliveryDocumentItem|.
*
*endif.


*            lv_po_det =  |('{ ls_head-orderhead }')/to_DeliveryDocumentItem|.
*        "create HTTP client by destination
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
*
*        "adding headers with API Key for API Sandbox
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
*
*            gv_web = |{ gv_web }{ lv_po_det }|.
*
*            lo_web_http_request->set_uri_path( i_uri_path = gv_web ).
*
*          lo_web_http_request->set_header_fields( VALUE #(   "newly added can remove if its dumps
*          (  name = 'APIKey' value = 'NhKVw93xyOAXFELg0waG5pstqbyG5qB8' )   "NhKVw93xyOAXFELg0waG5pstqbyG5qB8
**          (  name = 'x-csrf-token' value = 'fetch' )
**          (  name = 'DataServiceVersion' value = '2.0' )
*          (  name = 'Accept' value = 'application/json' )
*           ) ).
**
            data(lo_web_http_response1) = lo_web_http_client->execute( if_web_http_client=>get ).
            data(lv_response1) = lo_web_http_response1->get_text( ).

*      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.

***Read the PO data and pass the same to patch API
            TYPES : BEGIN OF ty_cond,
                      con_type TYPE char4,
                      doc      TYPE c LENGTH 10,
                      item     TYPE c LENGTH 2,
                      counter  TYPE c LENGTH 1,
                      step     TYPE c LENGTH 3,
                    END OF ty_cond.

            DATA : lt_cond TYPE STANDARD TABLE OF ty_cond,
                   ls_cond TYPE ty_cond.

     DATA(lv_status) = lo_web_http_response1->get_status(  ).
            CLEAR : lr_data.
            CALL METHOD /ui2/cl_json=>deserialize
              EXPORTING
                json         = lv_response1
                pretty_name  = /ui2/cl_json=>pretty_mode-user
                assoc_arrays = abap_true
              CHANGING
                data         = lr_data.
*
****start of below logic is standard procedure to get data from deep structures to internal table
*           IF lv_status-code = '200' OR lv_status-code = '201'.
*             IF lr_data IS BOUND.
*              UNASSIGN : <fs_data>,<fs_results>.
*              ASSIGN lr_data->* TO <fs_data>.
*              ASSIGN COMPONENT 'D' OF STRUCTURE <fs_data> TO <fs_results>.
*
*              ASSIGN <fs_results>->* TO <fs_hold>.
*              ASSIGN COMPONENT 'RESULTS' OF STRUCTURE <fs_hold> TO <fs_error>.
*
*               ASSIGN <fs_error>->* TO <fs_error_temp>.
*
*                 clear:LV_SO.
*               LOOP AT <fs_error_temp> ASSIGNING <ls_table> .
*
*                ASSIGN <ls_table>->* TO <fs_final_data>.
*
*                UNASSIGN : <fs_field>, <fs_field_value>.
*                ASSIGN COMPONENT 'DELIVERYDOCUMENT' OF STRUCTURE <fs_final_data> TO <fs_field>.
*                ASSIGN <fs_field>->* TO <fs_field_value>.
*                 LV_SO =  <fs_field_value>.
*
*                  UNASSIGN : <fs_field>, <fs_field_value>.
*                ASSIGN COMPONENT 'DELIVERYDOCUMENTITEM' OF STRUCTURE <fs_final_data> TO <fs_field>.
*                ASSIGN <fs_field>->* TO <fs_field_value>.
*                 lv_sitemno =  <fs_field_value>.
*
*
*                  UNASSIGN : <fs_field>, <fs_field_value>.
*                ASSIGN COMPONENT 'DELIVERYVERSION' OF STRUCTURE <fs_final_data> TO <fs_field>.
*                ASSIGN <fs_field>->* TO <fs_field_value>.
*                 LV_DVer =  <fs_field_value>.
*
*
*               ENDLOOP.
*
* endif.
*endif.

SELECT single a~DELIVERYDOCUMENT,b~DELIVERYDOCUMENTITEM,a~DELIVERYVERSION FROM I_DeliveryDocument as a
inner join I_DeliveryDocumentItem as b on a~DeliveryDocument = b~DeliveryDocument
 WHERE a~deliverydocument = @ls_head-orderhead INTO @DATA(ls_deldata).
if sy-subrc eq 0.
   LV_SO = ls_deldata-DELIVERYDOCUMENT.
   LV_SITEMNO = ls_deldata-DELIVERYDOCUMENTITEM.
   LV_DVer = ls_deldata-DELIVERYVERSION.
endif.
*need to write weight update logic here for outbound delivery for this entity( MODIFY ENTITIES OF i_outbounddeliverytp)

 CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
ENDTRY.

*****start of weight updating to delivery API only for Bulk
**************************logic to read outbound delivery using API************************************************
  TRY.
*************start of cloud destination testing

*if lv_public_cloud eq 'X'. "public cloud destinations logic
*
* lo_destination = cl_http_destination_provider=>create_by_cloud_destination(
*          i_name       = 'my403232_Public_cloud' " public cloud demo system working 06
*          i_authn_mode = if_a4c_cp_service=>service_specific
*        ).
***********below logic is URL preparing logic*********
*  CLEAR : gv_web,lv_po_det.
*      gv_web = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryItem'.
       lv_po_det =  |(DeliveryDocument='{ LV_SO }',DeliveryDocumentItem='{ lv_sitemno }')|.
*endif.


*      if lv_public_cloud eq space. " on premise destination logic
*
*          lo_destination = cl_http_destination_provider=>create_by_cloud_destination(
*          i_name       = 'F4D_400_CLONING_RP1'  " get this from BTP sub account
*          i_authn_mode = if_a4c_cp_service=>service_specific
*        ).
*
***********below logic is URL preparing logic*********
*  CLEAR : gv_web,lv_po_det.
*           gv_web = 'https://itcf4d.intern.itelligence.de:8000/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryItem'.
*       lv_po_det =  |(DeliveryDocument='{ LV_SO }',DeliveryDocumentItem='{ lv_sitemno }')|.
*endif.
*        "create HTTP client by destination
*        lo_web_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
**
**        "adding headers with API Key for API Sandbox
*        lo_web_http_request = lo_web_http_client->get_http_request( ).
**
**            gv_web = |{ gv_web }{ lv_po_det }|.
**
*            lo_web_http_request->set_uri_path( i_uri_path = gv_web ).
*
*          lo_web_http_request->set_header_fields( VALUE #(   "newly added can remove if its dumps
*          (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )   "NhKVw93xyOAXFELg0waG5pstqbyG5qB8
*          (  name = 'x-csrf-token' value = 'fetch' )
*          (  name = 'DataServiceVersion' value = '2.0' )
*          (  name = 'Accept' value = 'application/json' )
*           ) ).
**
*            lo_web_http_response1 = lo_web_http_client->execute( if_web_http_client=>get ).
*            lv_response1 = lo_web_http_response1->get_text( ).
*
*          data(lv_val1) = lo_web_http_response1->get_header_field( 'x-csrf-token' ).


 CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.


 TRY.
*          lo_web_http_request->set_header_fields( VALUE #(
*         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*         (  name = 'DataServiceVersion' value = '2.0' )
*         (  name = 'Accept' value = 'application/json' )
*         (  name = 'x-csrf-Token' value = lv_val1 )
*         ( name = 'If-Match'     value = '*')
*         (  name = 'Content-Type' value = 'application/json' ) ) ).

          DATA : a TYPE char1 VALUE '"',
                 b TYPE char1 VALUE '{',
                 c TYPE char1 VALUE '}',
                 lv_live_gweight  type ZWBI_DT_WEIGH value '300', " testing live weight should be passed to this field for bulk
                 lv_live_Tweight  type ZWBI_DT_WEIGH value '300'. " testing live weight should be passed to this field for bulk

           CONDENSE lv_weight NO-GAPS.

"preparing Json format to update gross weight in delivery API
DATA(lv_str100) = |{ b } "DeliveryVersion" : "{ LV_DVer }","DeliveryDocument" : "{ LV_SO }","DeliveryDocumentItem" : "{ lv_sitemno }", "ItemGrossWeight" : "{ lv_weight }"  { c }|.

          data(lv_str) = | { lv_str100 } |.
          lo_web_http_request->set_text( lv_str ).

          DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>patch ).
          DATA(lv_response) = lo_web_http_response->get_text( ).
          DATA(lv_status1) = lo_web_http_response->get_status(  ).
          DATA(lv_last_error) = lo_web_http_response->get_last_error(  ).
          DATA(lv_test) = lo_web_http_response->to_xstring(  ).
           IF lv_status-code = '200' OR lv_status-code = '201'  OR lv_status-code = '204'.
            DATA(lv_so_msg) = | Delivery document { LV_SO } weight { ls_head-Itemunit } { lv_weight } updated |.


             APPEND VALUE #(
               %tky = ls_head-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-information  " severity-success  "23/4/2025
               text     =  lv_so_msg
            )
              ) TO reported-head.

            endif.

CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.
*****end of weight updating logic

***************************************************************************
*below logic written above this using API API_OUTBOUND_DELIVERY_SRV

          TRY.
            CATCH cx_sy_itab_line_not_found.

          ENDTRY.

          IF lr_data IS NOT INITIAL. "ls_delivery_item IS NOT INITIAL. "need to convert below commented logic here

            IF lr_data IS NOT INITIAL. "ls_failed_upd IS NOT INITIAL. "need to convert below logic here

            ELSE. "no need of converting below PGI logic its already commented in original program

            ENDIF.

          ELSE.
            APPEND VALUE #(
               %tky = ls_head-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-warning
               text     = |{ TEXT-003 }|
            )

    ) TO reported-head.
            APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.


          ENDIF.
        ELSE.
          APPEND VALUE #(
       %tky = ls_head-%tky
       %msg = new_message_with_text(
       severity = if_abap_behv_message=>severity-error
       text     = |{ TEXT-001 } { lv_weight } { TEXT-002 } { ls_head-grossweight }|
    )

    ) TO reported-head.
          APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.
          RETURN.
        ENDIF.
 else.
**** Update Gross Weight fields are  for Purchase Scenario//30/10/2024

   UPDATE ZWBI_VINH SET pwoempwg = @lv_weight,    "W
                                pwiuom = @ls_head-Itemunit, "'KG',       "KG is hard coded UOM to table need to change
                                pwodate = @lv_date,
                                pwotime = @lv_time,
                                pwogetwg = 'C',
                                 pwoempwg_f = @lv_weight,  "for F4 Filter only
                                    gunit_f   = @ls_head-Itemunit "'KG' ""for F4 Filter only
              WHERE inward_uuid = @ls_key-inwarduuid.
      ENDIF.
    ELSE.

**** Update Gross Weight fields are  for Purchase Scenario

   UPDATE ZWBI_VINH SET pwoempwg = @lv_weight,    "W
                                pwiuom = @ls_head-Itemunit, "'KG',       "KG is hard coded UOM to table need to change
                                pwodate = @lv_date,
                                pwotime = @lv_time,
                                pwogetwg = 'C',
                                pwoempwg_f = @lv_weight,  "for F4 Filter only
                                 gunit_f   = @ls_head-Itemunit "'KG' ""for F4 Filter only
              WHERE inward_uuid = @ls_key-inwarduuid.


    ENDIF.
  ENDMETHOD.


  METHOD getweighttare.
    CONSTANTS: lc_tzone TYPE cl_abap_context_info=>ty_time_zone VALUE 'INDIA'.

    DATA: lv_weight TYPE string.

    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE lc_tzone INTO DATE DATA(lv_date) TIME DATA(lv_time).

    READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
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
**********"GR pop up message logic to capture tare weight
if ls_head-Intype = 'P'. "only for purchase order
SELECT * FROM zwbi_vin_i  for all entries in @heads
    where inward_uuid = @heads-inwarduuid INTO TABLE @DATA(lt_weight_item).  "14-06

*SELECT single inward_uuid ,
*              ticknum ,
*              fiscal ,
*              intype,
*              eflag
*  FROM /N4C03/WBI_VINH
*    where inward_uuid = @ls_head-inwarduuid INTO @DATA(ls_weight_head).  "24-06

*  sort  result by  inwarduuid. "14-06 new

*if ls_weight_head-eflag ne 'X'. "24-06 eflag used only to control GR message
  sort lt_weight_item by inward_uuid. "14-06 new
loop at lt_weight_item into data(ls_weight_item) where inward_uuid = ls_head-InwardUuid. "14-06 new only statement loop logic to consider GR fully or partial to enable tare wgt button
 IF ls_weight_item-PODELVSTATUS+0(1) = 'F' OR ls_weight_item-PODELVSTATUS+0(1) = 'P'. "14-06

      ELSE. ""14-06

  data: lv_answer  type c length 1.


* WRITE MESSAGE THAT GR NOT DONE

*****data(lv_message) = me->new_message_with_text(   "new_message(
*****
*****
*****         severity = ms-warning   "IF_ABAP_BEHV_MESSAGE=>SEVERITY-warning
*****          text     =   'GR not done are you sure you want proceed?'
*****).
******display error popup
*****data: ls_record like line of reported-head.
*****      ls_record-%msg = lv_message.
*****      append ls_record to  reported-head.



APPEND VALUE #(
           %tky = ls_head-%tky
           %msg = new_message_with_text(
           severity = if_abap_behv_message=>severity-information
           text     = |{ TEXT-012 }|  "'GR is not yet done' "|{ TEXT-012 }|
          )
          ) TO reported-head.
      APPEND VALUE #( %tky = ls_head-%tky ) TO mapped-head.


exit.
*
* UPDATE /N4C03/WBI_VINH SET eflag = 'X'  "'280.51',  "07-05  old   W
*            WHERE inward_uuid = @ls_key-inwarduuid.

*****



*****data: ls_fail like line of failed-head.
*****
*****      append ls_fail to  failed-head.

*     APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.

* APPEND VALUE #(
*           %tky = ls_head-%tky
*           %msg = new_message_with_text(
*           severity =  IF_ABAP_BEHV_MESSAGE=>SEVERITY-information "if_abap_behv_message=>severity-error
*           text     = |{ TEXT-008 }|
*
*          )
*          ) TO reported-head.
**      APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.
*RETURN.

     ENDIF.""14-06

      endloop. "14-06 new only statement loop

*      endif.  "24-06
endif.
************
    CALL METHOD getweight " capturing live Tare weight from weigh bridge
      EXPORTING
        iv_plant = ls_head-plant
      RECEIVING
        result   = lv_weight.

*        lv_weight = '3120.00'. "testing purpose need to remove later
*** Capturing Tare Weight from popup screen.
        if ls_key-%param-TareWeight is not INITIAL.
        clear:lv_weight.
        lv_weight = ls_key-%param-TareWeight.
        else.
        lv_weight = '3120.00'. "testing purpose need to remove later
        endif.

    IF lv_weight IS INITIAL  OR lv_weight = 0.
      APPEND VALUE #(
           %tky = ls_head-%tky
           %msg = new_message_with_text(
           severity = if_abap_behv_message=>severity-error
           text     = |{ TEXT-005 }|
          )
          ) TO reported-head.
      APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.


      RETURN.
    ENDIF.


     UPDATE ZWBI_VINH SET pwiempwg = @lv_weight,   "'280.51',  "07-05  old   W
                              pwiuom =  @ls_head-Itemunit," 'KG',   "KG is hard coded UOM to table need to change
                              pwidate = @lv_date,
                              pwitime = @lv_time,
                              pwigetwg = 'C',
                              pwiempwg_f = @lv_weight, "only for F4 filter
                              tunit_f =  @ls_head-Itemunit "'KG'            "only for F4 filter
*                              eflag = ' '
            WHERE inward_uuid = @ls_key-inwarduuid.



   APPEND VALUE #(                               "new
           %tky = ls_head-%tky
           %msg = new_message_with_text(
           severity = if_abap_behv_message=>severity-information    "severity-success
           text     = |{ TEXT-016 } { lv_weight } { ls_head-Itemunit } { TEXT-017 }|  "23/4/2025
*           text     = |{ TEXT-007 }|   "23/4/2025
          )
          ) TO reported-head.
"      APPEND VALUE #( %tky = ls_head-%tky ) TO failed-head.
      RETURN.

  ENDMETHOD.

  METHOD getweight. " LOGIC TO GET WEIGHTS FROM THIRD PARTY INTEGRATION(CPI)
"NOTE: OIL company has multiple weigh bridge with  2 different plants
  if 1 = 2. "16-02 after testing remove if condition
*******************************testing logic starts 05-03-2024
*data: lv_Url type string.
*      data:lo_http_client_w TYPE REF TO if_web_http_client.
*
*lv_Url   = 'http://localhost:8080/weight'.
*
**cl_http_client=>create_by_url ( exporting
**   url =  lv_Url
**   importing
**   client = data(lo_http)
**   exceptions
**   arugument not found = 1
**   others = 5
**   ).
*
*
*lo_http_client_w = cl_web_http_client_manager=>create_by_http_destination(
*                                i_destination = cl_http_destination_provider=>create_by_url( lv_url ) ).
*
*          data(lo_request1) = lo_http_client_w->get_http_request( ).
*
*          lo_request1->set_header_fields( value  #( (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*          (  name = 'Accept' value = 'application/json' )
*"         ( name = 'If-Match'     value = '*')
*         (  name = 'Content-Type' value = 'application/json' ) ) )  .
*
*
* "          data(lo_web_http_request) =  cl_http_destination_provider=>create_by_url( lv_url ).
*
* lo_request1->set_uri_path( i_uri_path = lv_url ).
*
* TRY.
* DATA(lv_response) = lo_http_client_w->execute( i_method = if_web_http_client=>get )->get_text( ).
* CATCH CX_WEB_HTTP_CLIENT_ERROR.
* ENDTRY.



*********************08-05-

***SO item
      FIELD-SYMBOLS:
        <fs_data_dist>        TYPE data,
        <fs_results_dist>     TYPE any,
        <fs_structure_dist>   TYPE any,
        <fs_hold_dist>        TYPE any,
        <fs_error_dist>       TYPE any,
        <fs_error_temp_dist>  TYPE any,
        <fs_error_table_dist> TYPE any,
        <fs_table_dist>       TYPE ANY TABLE,
        <fs_table_temp_dist>  TYPE ANY TABLE,
        <fs_field_dist>       TYPE any,
        <fs_field_value_dist> TYPE data.


      DATA: lr_data_dist TYPE REF TO data.


      FIELD-SYMBOLS : <ls_table_dist> TYPE any.
      FIELD-SYMBOLS : <lv_severity_dist>   TYPE any,
                      <fs_final_data_dist> TYPE data.

****
      DATA : gv_web_dist TYPE string.
      DATA : gv_web_dist2 TYPE string.
      DATA : gv_web_dist3 TYPE string.
      DATA: lv_so_det_dist TYPE string.



           TYPES : BEGIN OF ty_stext,
                   spoint     TYPE c LENGTH 4,
                   spname TYPE c LENGTH  30,
                   END OF ty_stext.
*
      DATA : lt_stext     TYPE STANDARD TABLE OF ty_stext,
             lt_stext_out TYPE STANDARD TABLE OF ty_stext,
             ls_stext     TYPE ty_stext,
             lv_stext_txt type c LENGTH 30. "01-04


      TRY.


*************start of cloud destination testing working

* below commented code to call on prime system using destinations***************************

* Weigh Bridge Integration Testing with Create by URL

*Changes on 18.09.2024
**  TRY.
*    CONSTANTS: lc_po_url   TYPE string VALUE 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV',
*               lc_user     TYPE string VALUE 'DEMO_API_PC',
*               lc_password TYPE string VALUE 'fSQ#xoXWmonAJJnqVaKoqzmRuxAh9ZfFktRbFSfL'.
**
**          lo_http_client = cl_web_http_client_manager=>create_by_http_destination(
**                    i_destination = cl_http_destination_provider=>create_by_url( lc_po_url ) ).
**          DATA(lo_http_req) = lo_http_client->get_http_request( ).
**          lo_http_req->set_authorization_basic(
**                                                 i_username = lc_user
**                                                 i_password = lc_password
**                                               ).
**
**          lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
**          EXPORTING
**             is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
**                                                 proxy_model_id      = 'ZPR_SCM_CBP_PO_V2'
**                                                 proxy_model_version = '0001' )
**            io_http_client             = lo_http_client
**            iv_relative_service_root   = ''  ).
**
**          ASSERT lo_http_client IS BOUND.
**  ENDTRY.
*Changes on 18.09.2024
*
            DATA(lo_destination_dist) = cl_http_destination_provider=>create_by_cloud_destination(
            i_name = 'scalesync'
*                                         i_name = 'scalesyncrpk' ). " public cloud demo system working 06
            "                             i_name = 'my403202_public_cloud_wbi' " not working 06
                                        i_authn_mode = if_a4c_cp_service=>service_specific ).

**********below logic is URL preparing logic*********
            CLEAR : gv_web_dist,gv_web_dist2.
      gv_web_dist = 'https://localhost:9443/weight'.

*        "create HTTP client by destination
            DATA(lo_web_http_client_dist) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_dist ).
*
*        "adding headers with API Key for API Sandbox
            DATA(lo_web_http_request_dist) = lo_web_http_client_dist->get_http_request( ).


            gv_web_dist = |{ gv_web_dist }|." concatenating

            lo_web_http_request_dist->set_uri_path( i_uri_path = gv_web_dist ).

            lo_web_http_request_dist->set_header_fields( VALUE #(

*         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )

  "          (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
         (  name = 'x-csrf-token' value = 'fetch' )
*          (  name = 'DataServiceVersion' value = '2.0' )
           (  name = 'Accept' value = 'application/json' )
             ) ).
*
            DATA(lo_web_http_response_dist) = lo_web_http_client_dist->execute( if_web_http_client=>get ).
            DATA(lv_response_dist) = lo_web_http_response_dist->get_text( )." data fetching in json format

            DATA(lv_status_dist) = lo_web_http_response_dist->get_status(  ).
            CLEAR : lr_data_dist.
            CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
              EXPORTING
                json = lv_response_dist
*               pretty_name  = /ui2/cl_json=>pretty_mode-user
*               assoc_arrays = abap_true
              CHANGING
                data = lr_data_dist.

                 IF lv_status_dist-code EQ '200'  OR lv_status_dist-code = '201'.  "need to check error logic
***start of below logic is standard procedure to get data from deep structures to internal table
*                  IF lv_status_dist-code = '200' OR lv_status_dist-code = '201'.
                    IF lr_data_dist IS BOUND.
                      UNASSIGN : <fs_data_dist>,<fs_results_dist>.
                      ASSIGN lr_data_dist->* TO <fs_data_dist>.
*                      ASSIGN COMPONENT 'D' OF STRUCTURE <fs_data_dist> TO <fs_results_dist>.
                      UNASSIGN : <fs_field_dist>, <fs_field_value_dist>.
                      ASSIGN COMPONENT 'WEIGHT' OF STRUCTURE <fs_data_dist> TO <fs_field_dist>.
                      ASSIGN <fs_field_dist>->* TO <fs_field_value_dist>.

endif.

*endif.
endif.


 CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.

      ENDTRY.


*******************************testing logic ends

    TRY.
        IF iv_plant = '1100'. " need to cross check with the team "weight bridge 1
          DATA(lo_dest) = cl_http_destination_provider=>create_by_comm_arrangement(
              comm_scenario  = 'YY1_WEIGHBRIDGE'
       ).

        ELSE.  "weight bridge 2
          lo_dest = cl_http_destination_provider=>create_by_comm_arrangement(
            comm_scenario  = 'YY1_WEIGHBRIDGE1'
     ).

        ENDIF.

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).

        " execute the request
        DATA(lo_request) = lo_http_client->get_http_request( ).
        DATA(lo_response) = lo_http_client->execute( if_web_http_client=>get ).
        DATA(lv_text) = lo_response->get_text(  ). "in text field get the weight along with field label
        SPLIT lv_text AT ':' INTO DATA(lv_lable) DATA(lv_data).
        REPLACE ALL OCCURRENCES OF '"' IN lv_data WITH space.
        REPLACE ALL OCCURRENCES OF '}' IN lv_data WITH space.
        CONDENSE lv_data.
        result = lv_data.  "in results set need to pass weight
      CATCH cx_http_dest_provider_error.
        " handle exception here

      CATCH cx_web_http_client_error.
        " handle exception here
    ENDTRY.
    endif.
  ENDMETHOD.



*  METHOD GetDefaultsForGRMSG.

*  READ ENTITIES OF ZWBI_I_WEIGHT_HEAD IN LOCAL MODE "zi_weight_head IN LOCAL MODE
*         ENTITY head
*             ALL FIELDS WITH CORRESPONDING #( keys )
*                 RESULT DATA(heads).
*
*    TRY.
*        DATA(ls_head) = heads[ 1 ].
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    TRY.
*        DATA(ls_key) = keys[ 1 ].
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*SELECT * FROM zwbi_vin_i  for all entries in @heads
*    where inward_uuid = @heads-inwarduuid INTO TABLE @DATA(lt_weight_item).  "14-06
**  sort  result by  inwarduuid. "14-06 new
*  sort lt_weight_item by inward_uuid. "14-06 new
*loop at lt_weight_item into data(ls_weight_item) where inward_uuid = ls_head-InwardUuid. "14-06 new only statement loop logic to consider GR fully or partial to enable tare wgt button
* IF ls_weight_item-PODELVSTATUS+0(1) = 'F' OR ls_weight_item-PODELVSTATUS+0(1) = 'P'. "14-06
*
*      ELSE. ""14-06
*
*  data: lv_answer  type c length 1.
*
*
*   APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<fs_result>).
*    <fs_result>-%tky = heads[ 1 ]-%tky.
*
*      <fs_result>-%param-msg = 'GR not done are you sure you want proceed?'.
*
*
*
*     ENDIF.""14-06
*
*      endloop. "14-06 new only statement loop


*  ENDMETHOD.




ENDCLASS.