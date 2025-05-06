  METHOD if_rap_query_provider~select.


data:  lv_top_c   type int8,
       lv_skip_c   type int8 .  "29-05


    IF io_request->is_data_requested( ).

      TRY.
          "get and add filters
          DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ). " get_filter_conditions( ).
        CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_sel_option).
      ENDTRY.


      DATA lv_total_number_of_records TYPE int8.

      DATA(ld_is_data_requested)  = io_request->is_data_requested( ).
      DATA(ld_is_count_requested) = io_request->is_total_numb_of_rec_requested( ).
      DATA(lt_requested_elements) = io_request->get_requested_elements( ).
*DATA(lt_filter_condition) = io_request->get_filter( )->get_as_ranges( ).
      DATA(lv_skip)    = io_request->get_paging( )->get_offset( ).
      DATA(lv_top)     = io_request->get_paging( )->get_page_size(  ).   "get_page_size( ).
      DATA(lt_sort)    = io_request->get_sort_elements( ).
      DATA(ls_get_filter_sql) = io_request->get_filter( )->get_as_sql_string( ).


      if lv_skip eq 0  or lv_skip is INITIAL.   "logic to fetch Top values in URL
       clear: lv_top_c.
       lv_top_c  = 1000.
      else.
      lv_skip_c = lv_skip * 20.
        lv_top_c    = 1000 + lv_skip_c.

        endif.

***SO item
      FIELD-SYMBOLS:
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
        <fs_field_value_di> TYPE data.

      DATA: lv_plant        TYPE c LENGTH 4,
            lv_inwtyp       TYPE zwbi_dt_inward,
            lv_public_cloud TYPE c LENGTH 1. " VALUE 'X'.
      DATA: lr_data_di TYPE REF TO data.


      FIELD-SYMBOLS : <ls_table_di> TYPE any.
      FIELD-SYMBOLS : <lv_severity_di>   TYPE any,
                      <fs_final_data_di> TYPE data.

****
      DATA : gv_web_di TYPE string.
      DATA : gv_web_di2 TYPE string.
      DATA : gv_web_di3 TYPE string.
      DATA: lv_so_det_di TYPE string,
            lv_dchan     TYPE c LENGTH 2.


      TYPES : BEGIN OF ty_ditems,
                Deldoc     TYPE c LENGTH 10,
                plant_n    TYPE c LENGTH 4, "01-04
                plantname  TYPE c LENGTH 30, "06-04
                inwtype    TYPE zwbi_dt_inward,
                mtype      TYPE c LENGTH 1,
                salesorder TYPE c LENGTH 10,  "06-04
                partfunct  TYPE c LENGTH 2,
              END OF ty_ditems.
*
      DATA : lt_ditems     TYPE STANDARD TABLE OF ty_ditems,
             lt_ditems_out TYPE STANDARD TABLE OF ty_ditems,
             ls_ditems     TYPE ty_ditems.

****
*****cloud destinations fetching from table
*"      SELECT SINGLE sysname,
*"        cflag,
*"        cdest,
*"        curl
*"        FROM zwbi_dcong WHERE  cflag = 'X'  INTO @DATA(ls_cdest).
*
*"      IF ls_cdest-sysname = 'C'.
*
*"        lv_public_cloud  = ls_cdest-cflag.
*"      ENDIF.
*
lv_public_cloud  = 'X'.
****************************API to fetch plant text start
      TYPES : BEGIN OF ty_dplant,
                Plant     TYPE c LENGTH 4,
                PlantName TYPE c LENGTH  30,

              END OF ty_dplant.
*
      DATA : lt_dplant     TYPE STANDARD TABLE OF ty_dplant,
             lt_dplant_out TYPE STANDARD TABLE OF ty_dplant,
             ls_dplant     TYPE ty_dplant,
             lv_dplant_txt TYPE c LENGTH 30.

*
*********
*      TRY.
**
**
***************start of cloud destination testing
**
*          IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*            DATA(lo_destination_dis) = cl_http_destination_provider=>create_by_cloud_destination(
*                                         i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*            "                             i_name = 'my403202_public_cloud_wbi' " not working 06
*                                         i_authn_mode = if_a4c_cp_service=>service_specific ).
*
*
***********below logic is URL preparing logic*********
*            CLEAR : gv_web_di,gv_web_di2.
*            gv_web_di = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata4/sap/zwbi_sb_plant_f4/srvd/sap/zwbi_sd_plant_f4/0001/I_Plant?$top=100000'. "06 not working
*
**        "create HTTP client by destination
*            DATA(lo_web_http_client_dis) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_dis ).
**
**        "adding headers with API Key for API Sandbox
*            DATA(lo_web_http_request_dis) = lo_web_http_client_dis->get_http_request( ).
*
*
*            gv_web_di = |{ gv_web_di }{ gv_web_di2 }|." concatenating
*
*            lo_web_http_request_dis->set_uri_path( i_uri_path = gv_web_di ).
*
*            lo_web_http_request_dis->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*
*  "          (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
**          (  name = 'x-csrf-token' value = 'fetch' )
**          (  name = 'DataServiceVersion' value = '2.0' )
*           (  name = 'Accept' value = 'application/json' )
*             ) ).
**
*            DATA(lo_web_http_response_dis) = lo_web_http_client_dis->execute( if_web_http_client=>get ).
*            DATA(lv_response_dis) = lo_web_http_response_dis->get_text( )." data fetching in json format
*
*            DATA(lv_status_dis) = lo_web_http_response_dis->get_status(  ).
*            CLEAR : lr_data_di.
*            CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*              EXPORTING
*                json = lv_response_dis
**               pretty_name  = /ui2/cl_json=>pretty_mode-user
**               assoc_arrays = abap_true
*              CHANGING
*                data = lr_data_di.
*
****start of below logic is standard procedure to get data from deep structures to internal table
*            IF lv_status_dis-code = '200' OR lv_status_dis-code = '201'.
*              IF lr_data_di IS BOUND.
*                UNASSIGN : <fs_data_di>,<fs_results_di>.
*                ASSIGN lr_data_di->* TO <fs_data_di>.
*
*                ASSIGN COMPONENT 'VALUE' OF STRUCTURE <fs_data_di> TO <fs_results_di>.
*                ASSIGN <fs_results_di>->* TO <fs_error_temp_di>.
*
*
*                LOOP AT <fs_error_temp_di> ASSIGNING <ls_table_di> .
*
*                  ASSIGN <ls_table_di>->* TO <fs_final_data_di>.
*
*                  UNASSIGN : <fs_field_di>, <fs_field_value_di>.
*                  ASSIGN COMPONENT 'PLANT' OF STRUCTURE <fs_final_data_di> TO <fs_field_di>.
*                  ls_dplant-Plant = <fs_field_di>->*.
*
*                  UNASSIGN : <fs_field_di>, <fs_field_value_di>.
*                  ASSIGN COMPONENT 'PLANTNAME' OF STRUCTURE <fs_final_data_di> TO <fs_field_di>.
*                  ls_dplant-PlantName = <fs_field_di>->*. "01-04
*
*                  APPEND ls_dplant TO lt_dplant.
*                  CLEAR:ls_dplant.
*
*                ENDLOOP.
*
*              ENDIF.
*            ENDIF.
*          ENDIF.
TRY.
     SELECT Plant, Plantname from i_plant into table @lt_dplant.
        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.



********************Start of below logic fetching plants from on premise S4D system using destinations
*      IF lv_public_cloud EQ space.
*
*        TYPES: BEGIN OF ty_plant,
*                 werks TYPE c LENGTH 4,
*                 Name1 TYPE c LENGTH  30,
*                 spras TYPE c LENGTH 1,
*               END OF ty_plant.
*
*        DATA : lt_plant          TYPE STANDARD TABLE OF ty_plant, "/n4c03/wbi_plant_f4, "/i4e01/cbp_sh_material,
*               ls_plant          LIKE LINE OF lt_plant,
*               lv_orderby_string TYPE string,
*               lt_plant_ui       TYPE STANDARD TABLE OF ty_plant. "/n4c03/wbi_plant_f4.
*
*        "http://devf4d.solco.global.nttdata.com:8000/sap/opu/odata/sap/API_PLANT_SRV/A_Plant  "this can be used later
*        TRY.
*            DATA(lo_destination) = cl_rfc_destination_provider=>create_by_cloud_destination( i_name = 'S4D_400_RFC_RPK' ).
*          CATCH cx_rfc_dest_provider_error.
*            "handle exception
*        ENDTRY.
*
*        TRY.
*            DATA(lv_destination) = lo_destination->get_destination_name( ).
*          CATCH cx_rfc_dest_provider_error.
*            "handle exception
*        ENDTRY.
*"        IF lv_destination IS NOT INITIAL.
*"          CALL FUNCTION '/I4E01/WBI_SH_PLANT' DESTINATION lv_destination " this FM created in S4D with separate TR
*"            TABLES
*"              lt_plant = lt_plant.
*"        ENDIF.
*
*"        IF lt_plant[] IS NOT INITIAL.
*
*"          LOOP AT  lt_plant INTO ls_plant   .
*"            ls_dplant-Plant = ls_plant-werks.
*
*"            ls_dplant-PlantName = ls_plant-name1. "01-04
*
*"            APPEND ls_dplant TO lt_dplant.
*"            CLEAR:ls_dplant,ls_plant.
*"          ENDLOOP.
*
*"        ENDIF.
*
*      ENDIF.
***************end of logic fetching plants from on premise S4D system using destinations*******

***************************API to fetch plant text end
*********start of logic to fetch storage location text

    TYPES : BEGIN OF ty_sloc,
                Sloc     TYPE c LENGTH 4,
                Slocname TYPE c LENGTH  30,
                dchannel   TYPE c LENGTH 2,

              END OF ty_sloc.
*
      DATA : lt_sloc     TYPE STANDARD TABLE OF ty_sloc,
             lt_sloc_out TYPE STANDARD TABLE OF ty_sloc,
             ls_sloc     TYPE ty_sloc,
             lv_sloc_txt TYPE c LENGTH 30. "01-04


      DATA : gv_web_disl TYPE string.
      DATA : gv_web_disl2 TYPE string.
      DATA : gv_web_disl3 TYPE string.


              DATA: lr_data_disl TYPE REF TO data.

  FIELD-SYMBOLS:
        <fs_data_disl>        TYPE data,
        <fs_results_disl>     TYPE any,
        <fs_structure_disl>   TYPE any,
        <fs_hold_disl>        TYPE any,
        <fs_error_disl>       TYPE any,
        <fs_error_temp_disl>  TYPE any,
        <fs_error_table_disl> TYPE any,
        <fs_table_disl>       TYPE ANY TABLE,
        <fs_table_temp_disl>  TYPE ANY TABLE,
        <fs_field_disl>       TYPE any,
        <fs_field_value_disl> TYPE data.


      FIELD-SYMBOLS : <ls_table_disl> TYPE any.
      FIELD-SYMBOLS : <lv_severity_disl>   TYPE any,
                      <fs_final_data_disl> TYPE data.

*******
*      TRY.
*
*
**************start of cloud destination testing
*
*          IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*            DATA(lo_destination_disl) = cl_http_destination_provider=>create_by_cloud_destination(
*                                         i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*            "                             i_name = 'my403202_public_cloud_wbi' " not working 06
*                                         i_authn_mode = if_a4c_cp_service=>service_specific ).
*
*
***********below logic is URL preparing logic*********
*            CLEAR : gv_web_disl,gv_web_disl2.
*            gv_web_disl = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata4/sap/zwbi_sb_sloctxt/srvd/sap/zwbi_sd_sloctxt/0001/I_StorageLocation?$top=1000000'. "06 not working
*
**        "create HTTP client by destination
*            DATA(lo_web_http_client_disl) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_disl ).
**
**        "adding headers with API Key for API Sandbox
*            DATA(lo_web_http_request_disl) = lo_web_http_client_disl->get_http_request( ).
*
*            gv_web_disl = |{ gv_web_disl }{ gv_web_disl2 }|." concatenating
*
*            lo_web_http_request_disl->set_uri_path( i_uri_path = gv_web_disl ).
*
*            lo_web_http_request_disl->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*
*  "          (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
**          (  name = 'x-csrf-token' value = 'fetch' )
**          (  name = 'DataServiceVersion' value = '2.0' )
*           (  name = 'Accept' value = 'application/json' )
*             ) ).
**
*            DATA(lo_web_http_response_disl) = lo_web_http_client_disl->execute( if_web_http_client=>get ).
*            DATA(lv_response_disl) = lo_web_http_response_disl->get_text( )." data fetching in json format
*
*            DATA(lv_status_disl) = lo_web_http_response_disl->get_status(  ).
*            CLEAR : lr_data_disl.
*            CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*              EXPORTING
*                json = lv_response_disl
**               pretty_name  = /ui2/cl_json=>pretty_mode-user
**               assoc_arrays = abap_true
*              CHANGING
*                data = lr_data_disl.
*
****start of below logic is standard procedure to get data from deep structures to internal table
*            IF lv_status_disl-code = '200' OR lv_status_disl-code = '201'.
*              IF lr_data_disl IS BOUND.
*                UNASSIGN : <fs_data_disl>,<fs_results_disl>.
*                ASSIGN lr_data_disl->* TO <fs_data_disl>.
*
*                ASSIGN COMPONENT 'VALUE' OF STRUCTURE <fs_data_disl> TO <fs_results_disl>.
*                ASSIGN <fs_results_disl>->* TO <fs_error_temp_disl>.
*
*
*                LOOP AT <fs_error_temp_disl> ASSIGNING <ls_table_disl> .
*
*                  ASSIGN <ls_table_disl>->* TO <fs_final_data_disl>.
*
*                  UNASSIGN : <fs_field_disl>, <fs_field_value_disl>.
*                  ASSIGN COMPONENT 'STORAGELOCATION' OF STRUCTURE <fs_final_data_disl> TO <fs_field_disl>.
*                  ls_sloc-sloc = <fs_field_disl>->*.
*
*                  UNASSIGN : <fs_field_disl>, <fs_field_value_disl>.
*                  ASSIGN COMPONENT 'STORAGELOCATIONNAME' OF STRUCTURE <fs_final_data_disl> TO <fs_field_disl>.
*                  ls_sloc-slocname = <fs_field_disl>->*. "01-04
*
*                  UNASSIGN : <fs_field_disl>, <fs_field_value_disl>.
*                  ASSIGN COMPONENT 'DISTRIBUTIONCHANNEL' OF STRUCTURE <fs_final_data_disl> TO <fs_field_disl>.
*                  ls_sloc-dchannel = <fs_field_disl>->*. "01-04
*
*                  APPEND ls_sloc TO lt_sloc.
*                  CLEAR:ls_sloc.
**exit.
*                ENDLOOP.
*
*              ENDIF.
*            ENDIF.
*          ENDIF.
TRY.

    SELECT storagelocation, StorageLocationName, DistributionChannel from I_StorageLocation into TABLE @lt_sloc.
        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.

*********end of logic to fetch storage location text
*********start of shipping point text

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
                   spName TYPE c LENGTH  60,
                   END OF ty_stext.
*
      DATA : lt_stext     TYPE STANDARD TABLE OF ty_stext,
             lt_stext_out TYPE STANDARD TABLE OF ty_stext,
             ls_stext     TYPE ty_stext,
             lv_stext_txt type c LENGTH 30.


*      TRY.
*
*
**************start of cloud destination testing
*
*          IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*            DATA(lo_destination_dist) = cl_http_destination_provider=>create_by_cloud_destination(
*                                         i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*            "                             i_name = 'my403202_public_cloud_wbi' " not working 06
*                                         i_authn_mode = if_a4c_cp_service=>service_specific ).
*
*
***********below logic is URL preparing logic*********
*            CLEAR : gv_web_dist,gv_web_dist2.
**            gv_web_di = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata4/sap/zwbi_sb_plant_f4/srvd/sap/zwbi_sd_plant_f4/0001/I_Plant'. "06 not working
*gv_web_dist = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata4/sap/zwbi_sb_shiptext_f4/srvd/sap/zwbi_sd_shiptext_f4/0001/I_ShippingPointText?$top=1000000&$filter=Language eq'. "06 not working
*
*gv_web_dist2 = | '{ sy-langu }'|.
*
**        "create HTTP client by destination
*            DATA(lo_web_http_client_dist) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_dist ).
**
**        "adding headers with API Key for API Sandbox
*            DATA(lo_web_http_request_dist) = lo_web_http_client_dist->get_http_request( ).
*
*
*            gv_web_dist = |{ gv_web_dist }{ gv_web_dist2 }|." concatenating
*
*            lo_web_http_request_dist->set_uri_path( i_uri_path = gv_web_dist ).
*
*            lo_web_http_request_dist->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*
*  "          (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
**          (  name = 'x-csrf-token' value = 'fetch' )
**          (  name = 'DataServiceVersion' value = '2.0' )
*           (  name = 'Accept' value = 'application/json' )
*             ) ).
**
*            DATA(lo_web_http_response_dist) = lo_web_http_client_dist->execute( if_web_http_client=>get ).
*            DATA(lv_response_dist) = lo_web_http_response_dist->get_text( )." data fetching in json format
*
*            DATA(lv_status_dist) = lo_web_http_response_dist->get_status(  ).
*            CLEAR : lr_data_dist.
*            CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*              EXPORTING
*                json = lv_response_dist
**               pretty_name  = /ui2/cl_json=>pretty_mode-user
**               assoc_arrays = abap_true
*              CHANGING
*                data = lr_data_dist.
*
****start of below logic is standard procedure to get data from deep structures to internal table
*            IF lv_status_dist-code = '200' OR lv_status_dist-code = '201'.
*              IF lr_data_dist IS BOUND.
*                UNASSIGN : <fs_data_dist>,<fs_results_dist>.
*                ASSIGN lr_data_dist->* TO <fs_data_dist>.
*
*                ASSIGN COMPONENT 'VALUE' OF STRUCTURE <fs_data_dist> TO <fs_results_dist>.
*                ASSIGN <fs_results_dist>->* TO <fs_error_temp_dist>.
*
*                LOOP AT <fs_error_temp_dist> ASSIGNING <ls_table_dist> .
*
*                  ASSIGN <ls_table_dist>->* TO <fs_final_data_dist>.
*
*                  UNASSIGN : <fs_field_dist>, <fs_field_value_dist>.
*                  ASSIGN COMPONENT 'SHIPPINGPOINT' OF STRUCTURE <fs_final_data_dist> TO <fs_field_dist>.
*                  ls_stext-spoint = <fs_field_dist>->*.
*
*                  UNASSIGN : <fs_field_dist>, <fs_field_value_dist>.
*                  ASSIGN COMPONENT 'SHIPPINGPOINTNAME' OF STRUCTURE <fs_final_data_dist> TO <fs_field_dist>.
*                 ls_stext-spName = <fs_field_dist>->*. "01-04
*                  APPEND ls_stext TO lt_stext.
*                  CLEAR:ls_stext.
**exit.
*                ENDLOOP.
*
*              ENDIF.
*            ENDIF.
*          ENDIF.
TRY.
  SELECT Shippingpoint,ShippingPointName from i_shippingpointtext WHERE language = @sy-langu
               into table @lt_stext.

        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.

********end of shipping point text

      CLEAR:lv_inwtyp,LV_PLant.
      LOOP AT lt_filter INTO DATA(ls_filter).

        CASE ls_filter-name.
          WHEN 'INWTYPE'.
            LOOP AT ls_filter-range INTO DATA(ls_filter_data).
              lv_inwtyp = ls_filter_data-low.
            ENDLOOP.
          WHEN 'PLANT_N'. "01-04
            LOOP AT ls_filter-range INTO DATA(ls_filter_data_P).
              CONDENSE ls_filter_data_P-low.
              LV_PLant = ls_filter_data_P-low.
            ENDLOOP.
        ENDCASE.
        CLEAR:ls_filter.
      ENDLOOP.


      IF LV_PLant IS NOT INITIAL AND lv_inwtyp  EQ 'S'.

        TRY.

**************start of cloud destination testing
*
*            IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*              DATA(lo_destination_di) = cl_http_destination_provider=>create_by_cloud_destination(
*                                           i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*                                           i_authn_mode = if_a4c_cp_service=>service_specific ).
*
*
***********below logic is URL preparing logic*********
*              CLEAR : gv_web_di,gv_web_di2.
*              gv_web_di = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryItem?$filter=Plant eq'. "06 not working
*              " gv_web_di = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryItem?$filter=Plant eq'. "06 working
**               gv_web_di2 = | '{ lv_plant }' and GoodsMovementStatus ne 'C' |.
*              gv_web_di2 = | '{ lv_plant }' and GoodsMovementStatus ne 'C'&$top={ lv_top_c } |.
*
*            ENDIF.

*            IF lv_public_cloud EQ space. " on premise destination logic
*              lo_destination_di = cl_http_destination_provider=>create_by_cloud_destination(
*                  i_name       = 'F4D_400_CLONING_RP1'  " get this from BTP sub account
*                   i_authn_mode =  if_a4c_cp_service=>service_specific
*                 ).
*
***********below logic is URL preparing logic*********
*              CLEAR : gv_web_di,gv_web_di2.
*              gv_web_di = 'https://itcf4d.intern.itelligence.de:8000/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryItem?$filter=Plant eq'.
*
*              gv_web_di2 = | '{ lv_plant }' and GoodsMovementStatus ne 'C'&$top={ lv_top_c } |.
*
*
*            ENDIF.

**        "create HTTP client by destination
*            DATA(lo_web_http_client_di) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_di ).
**
**        "adding headers with API Key for API Sandbox
*            DATA(lo_web_http_request_di) = lo_web_http_client_di->get_http_request( ).
**************end of cloud destinations testing
*
*            gv_web_di = |{ gv_web_di }{ gv_web_di2 }|." concatenating
*
*            lo_web_http_request_di->set_uri_path( i_uri_path = gv_web_di ).
*
*            lo_web_http_request_di->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*
*            (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
**          (  name = 'x-csrf-token' value = 'fetch' )
**          (  name = 'DataServiceVersion' value = '2.0' )
*           (  name = 'Accept' value = 'application/json' )
*             ) ).
**
*            DATA(lo_web_http_response_di) = lo_web_http_client_di->execute( if_web_http_client=>get ).
*            DATA(lv_response_di) = lo_web_http_response_di->get_text( )." data fetching in json format
*
*            DATA(lv_status_di) = lo_web_http_response_di->get_status(  ).
*            CLEAR : lr_data_di.
*            CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*              EXPORTING
*                json = lv_response_di
**               pretty_name  = /ui2/cl_json=>pretty_mode-user
**               assoc_arrays = abap_true
*              CHANGING
*                data = lr_data_di.

***start of below logic is standard procedure to get data from deep structures to internal table
*            IF lv_status_di-code = '200' OR lv_status_di-code = '201'.
*              IF lr_data_di IS BOUND.
*                UNASSIGN : <fs_data_di>,<fs_results_di>.
*                ASSIGN lr_data_di->* TO <fs_data_di>.
*
*                ASSIGN COMPONENT 'D' OF STRUCTURE <fs_data_di> TO <fs_results_di>.
*
*                ASSIGN <fs_results_di>->* TO <fs_hold_di>.
*                ASSIGN COMPONENT 'RESULTS' OF STRUCTURE <fs_hold_di> TO <fs_error_di>.
*
*                ASSIGN <fs_error_di>->* TO <fs_error_temp_di>.

*                LOOP AT <fs_error_temp_di> ASSIGNING <ls_table_di> .
*
*                  ASSIGN <ls_table_di>->* TO <fs_final_data_di>.
*
*                  UNASSIGN : <fs_field_di>, <fs_field_value_di>.
*                  ASSIGN COMPONENT 'DELIVERYDOCUMENT' OF STRUCTURE <fs_final_data_di> TO <fs_field_di>.
*                  ls_ditems-deldoc = <fs_field_di>->*.
*
*                  UNASSIGN : <fs_field_di>, <fs_field_value_di>.
*                  ASSIGN COMPONENT 'REFERENCESDDOCUMENT' OF STRUCTURE <fs_final_data_di> TO <fs_field_di>.
**                ASSIGN <fs_field_di>->* TO <fs_field_value_di>.
**                 LV_HEADER_GROSSWEIGHT =  <fs_field_value_di>.
*                  ls_ditems-salesorder = <fs_field_di>->*.
*
*                  UNASSIGN : <fs_field_di>, <fs_field_value_di>.
*                  ASSIGN COMPONENT 'PLANT' OF STRUCTURE <fs_final_data_di> TO <fs_field_di>.
*                  ls_ditems-plant_n = <fs_field_di>->*. "01-04
*
*
*                  READ TABLE  lt_dplant INTO  ls_dplant WITH KEY plant = ls_ditems-plant_n.
*                  IF sy-subrc EQ 0.
*                    ls_ditems-plantname  =   ls_dplant-plantname.
*                  ENDIF.
*
*
*                  ls_ditems-inwtype = lv_inwtyp.
*
*
*                  UNASSIGN : <fs_field_di>, <fs_field_value_di>.
*                  ASSIGN COMPONENT 'GOODSMOVEMENTSTATUS' OF STRUCTURE <fs_final_data_di> TO <fs_field_di>.
*                  ls_ditems-mtype = <fs_field_di>->*.
*
*                  APPEND ls_ditems TO lt_ditems.
*                  CLEAR:ls_ditems,ls_dplant.
**exit.
*                ENDLOOP.

SELECT deliverydocument, referencesddocument, plant, goodsmovementstatus
           FROM I_DeliveryDocumentItem where plant = @lv_plant and goodsmovementstatus <> 'C'
           into TABLE @data(lt_delitems).
if  sy-subrc EQ 0.
   LOOP AT lt_delitems INTO data(ls_delitems).
     ls_ditems-deldoc = ls_delitems-DeliveryDocument.
     ls_ditems-salesorder = ls_delitems-ReferenceSDDocument.
     ls_ditems-plant_n = ls_delitems-Plant.
     READ TABLE  lt_dplant INTO  ls_dplant WITH KEY plant = ls_ditems-plant_n.
     IF sy-subrc EQ 0.
        ls_ditems-plantname  =   ls_dplant-plantname.
     ENDIF.
     ls_ditems-inwtype = lv_inwtyp.
     ls_ditems-mtype = ls_delitems-GoodsMovementStatus.

     APPEND ls_ditems TO lt_ditems.
     CLEAR:ls_ditems,ls_dplant.

   ENDLOOP.
endif.
*              ENDIF.
*            ENDIF.



            IF lt_ditems IS NOT INITIAL.
              SORT lt_ditems BY deldoc plant_n. "01-04
              DELETE ADJACENT DUPLICATES FROM lt_ditems COMPARING deldoc plant_n. "01-04
            ENDIF.

*            IF lv_public_cloud EQ space. "public cloud destinations logic "need to remove later once test is successful
*              DELETE lt_ditems WHERE deldoc NE '80000430' AND deldoc NE '80000429' . "need to remove later once test is successful
*            ENDIF."need to remove later once test is successful
**********************************************************************

          CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
        ENDTRY.

******************************Fetching API data************************

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
          <fs_field_value_dh> TYPE data.

***SO Header
        FIELD-SYMBOLS : <ls_table_dh> TYPE any.
        FIELD-SYMBOLS : <lv_severity_dh>   TYPE any,
                        <fs_final_data_dh> TYPE data.
        DATA: lr_data_dh TYPE REF TO data.

        TYPES : BEGIN OF ty_dhead,
                  Deldoc          TYPE c LENGTH 10,
*                      item         TYPE ZWBI_DT_ITEMNO,
                  plant_n         TYPE c LENGTH 4,
                  Plantname       TYPE c LENGTH 30,
                  inwtype         TYPE zwbi_dt_inward,
                  Ddate           TYPE  datum,
                  Shiptoparty     TYPE c LENGTH 10,
                  Soldtoparty     TYPE c LENGTH 10,
                  Shiptopartyname TYPE c LENGTH 60,
                  Shippingpoint   TYPE c LENGTH 4,
                  Shippname       TYPE c LENGTH 60,
                  Sloc            Type c LENGTH 4,
                  Slocname        type c LENGTH 30,
                END OF ty_dhead.
*
        DATA : lt_dhead     TYPE STANDARD TABLE OF ty_dhead,
               lt_dhead_out TYPE STANDARD TABLE OF ty_dhead,
               ls_dhead     TYPE  ty_dhead.

***Start of Timestamp to Date conversion declarations*****
        TYPES : BEGIN OF ty_data,
                  create_date TYPE datum, "timestamp,  " <<<<<<<<< This is the Trick
                END OF ty_data.

        DATA: lv_json1 TYPE string,
              lv_json2 TYPE string,
              lv_json3 TYPE string,
              lv_cdate TYPE datum,
              lv_ddate TYPE string.

        DATA: ls_date TYPE ty_data,
              lv_json TYPE /ui2/cl_json=>json.
******end of Timestamp declartions**********************

        DATA : gv_web_Dh TYPE string.
        DATA : gv_web_Dh2 TYPE string.
        DATA : gv_web_Dh3 TYPE string.
        DATA lv_so_det_Dh TYPE string.


        CLEAR:ls_ditems.
        LOOP AT lt_ditems INTO ls_ditems. "del header logic to filter del documents based on creation data LE current date
          IF ls_ditems-deldoc IS NOT INITIAL.
            TRY.


*                IF lv_public_cloud EQ 'X'. "public cloud destinations logic

*                  DATA(lo_destination_dh) = cl_http_destination_provider=>create_by_cloud_destination(
*                                               i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*                  "                             i_name = 'my403202_public_cloud_wbi' " not working 06
*                                               i_authn_mode = if_a4c_cp_service=>service_specific ).
*                  CLEAR : gv_web_dh.
***********below logic is URL preparing logic*********
*                  gv_web_dh = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryHeader'.


               SELECT SINGLE deliverydocument,shiptoparty,soldtoparty,shippingpoint, DocumentDate   "DeliveryDate
                   from I_DeliveryDocument where deliverydocument = @ls_ditems-deldoc and SDdocumentCategory = 'J'
                                             and DocumentDate LE @sy-datum  "28/4/2025 added new
                                              into @data(ls_delhead).
                   if sy-subrc EQ 0.
                    ls_dhead-deldoc        = ls_delhead-deliverydocument.
                    ls_dhead-shiptoparty   = ls_delhead-shiptoparty.
                    ls_dhead-soldtoparty   = ls_delhead-soldtoparty.
                    ls_dhead-shippingpoint = ls_delhead-shippingpoint.
                    read table lt_stext into  ls_stext WITH KEY spoint = ls_dhead-shippingpoint.
                    if sy-subrc eq 0.
                    ls_dhead-Shippname = ls_stext-spname.
                    endif.
                    lv_ddate = ls_delhead-DocumentDate.  "deliverydate. 28/4
*                   endif. "28/4/2025 old
*                ENDIF.

*                IF lv_public_cloud EQ space.  " on premise destination logic
** below commented code to call FM from S4D system using destinations***************************
*                  lo_destination_dh  = cl_http_destination_provider=>create_by_cloud_destination(
*                           i_name       = 'F4D_400_CLONING_RP1'  " get this from BTP sub account
*                           i_authn_mode = if_a4c_cp_service=>service_specific
*                         ).
*
***********below logic is URL preparing logic*********
*                  CLEAR : gv_web_dh.
*                  gv_web_dh = 'https://itcf4d.intern.itelligence.de:8000/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV/A_OutbDeliveryHeader'.
*
*                ENDIF.
**        "create HTTP client by destination
*                DATA(lo_web_http_client_dh) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_dh ).
**
**        "adding headers with API Key for API Sandbox
*                DATA(lo_web_http_request_dh) = lo_web_http_client_dh->get_http_request( ).
***********************************************************************************************
*
*                gv_web_dh2 = |('{ ls_ditems-deldoc }')|.
*                gv_web_dh = |{ gv_web_dh }{ gv_web_dh2 }|." concatenating
*
*                lo_web_http_request_dh->set_uri_path( i_uri_path = gv_web_dh ).
*                lo_web_http_request_dh->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*                (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
**              (  name = 'x-csrf-token' value = 'fetch' )
**              (  name = 'DataServiceVersion' value = '2.0' )
*               (  name = 'Accept' value = 'application/json' )
*                 ) ).
**
*                DATA(lo_web_http_response_dh) = lo_web_http_client_dh->execute( if_web_http_client=>get ).
*                DATA(lv_response_dh) = lo_web_http_response_dh->get_text( )." data fetching in json format
*
*                DATA(lv_status_dh) = lo_web_http_response_dh->get_status(  ).
*                CLEAR : lr_data_dh.
*                CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*                  EXPORTING
*                    json = lv_response_dh
**                   pretty_name  = /ui2/cl_json=>pretty_mode-user
**                   assoc_arrays = abap_true
*                  CHANGING
*                    data = lr_data_dh.
*
****start of below logic is standard procedure to get data from deep structures to internal table
*                IF lv_status_dh-code = '200' OR lv_status_dh-code = '201'.
*                  IF lr_data_dh IS BOUND.
*                    UNASSIGN : <fs_data_dh>,<fs_results_dh>.
*                    ASSIGN lr_data_dh->* TO <fs_data_dh>.
*                    ASSIGN COMPONENT 'D' OF STRUCTURE <fs_data_dh> TO <fs_error_dh>.
*
*                    ASSIGN <fs_error_dh>->* TO <fs_error_temp_dh>.
*                    UNASSIGN : <fs_field_value_dh>.
*                    ASSIGN COMPONENT 'DELIVERYDOCUMENT' OF STRUCTURE <fs_error_temp_dh> TO <fs_field_value_dh>.
*                    ls_dhead-deldoc      =  <fs_field_value_dh>->*.
*
*
*
*                    UNASSIGN : <fs_field_value_dh>.   "06-04
*                    ASSIGN COMPONENT 'SHIPTOPARTY' OF STRUCTURE <fs_error_temp_dh> TO <fs_field_value_dh>.
*                    ls_dhead-shiptoparty      =  <fs_field_value_dh>->*.
*
*
*                    UNASSIGN : <fs_field_value_dh>.  "06-04
*                    ASSIGN COMPONENT 'SOLDTOPARTY' OF STRUCTURE <fs_error_temp_dh> TO <fs_field_value_dh>.
*                    ls_dhead-soldtoparty  =  <fs_field_value_dh>->*.
*
*                    UNASSIGN : <fs_field_value_dh>.    "06-04
*                    ASSIGN COMPONENT 'SHIPPINGPOINT' OF STRUCTURE <fs_error_temp_dh> TO <fs_field_value_dh>.
*                    ls_dhead-shippingpoint   =  <fs_field_value_dh>->*.
*
*                    read table lt_stext into  ls_stext WITH KEY spoint = ls_dhead-shippingpoint.
*                    if sy-subrc eq 0.
*                    ls_dhead-Shippname = ls_stext-spname.
*                    endif.
*
*
*                    UNASSIGN : <fs_field_value_dh>.
*                    ASSIGN COMPONENT 'DELIVERYDATE' OF STRUCTURE <fs_error_temp_dh> TO <fs_field_value_dh>.
*                    lv_ddate =  <fs_field_value_dh>->*.



**********Start of Timestamp to Date conversion logic
                    CLEAR:lv_cdate,lv_json1,lv_json2,lv_json3,lv_json,ls_date.

*                 lv_json1 = '{ "Order_No" : "0021232324" , "Create_Date" : '.
                    lv_json1 = '{ "Create_Date" : '.
                    lv_json2 = | "{ lv_ddate }" |.
                    lv_json3 = '}'.
                    lv_json  = |'{ lv_json1 }{ lv_json2 }{ lv_json3 }'|.

                    /ui2/cl_json=>deserialize(
                      EXPORTING
                        json        = lv_json             " JSON string
                      CHANGING
                        data        = ls_date ).          " Converted Data

                    ls_dhead-ddate =   ls_date-create_date." So creation date

                    IF ls_dhead-ddate LE sy-datum.

                      ls_dhead-plant_n  = ls_ditems-plant_n.

                      READ TABLE  lt_dplant INTO  ls_dplant WITH KEY plant = ls_dhead-plant_n.
                      IF sy-subrc EQ 0.
                        ls_dhead-plantname  =   ls_dplant-plantname.
                      ENDIF.

                      ls_dhead-inwtype  = ls_ditems-inwtype.

************************ START OF CUST ADDRESS DETAILS
*************************************start of customer details using communication scenario

***SO item
      FIELD-SYMBOLS:
        <fs_data_dict>        TYPE data,
        <fs_results_dict>     TYPE any,
        <fs_structure_dict>   TYPE any,
        <fs_hold_dict>        TYPE any,
        <fs_error_dict>       TYPE any,
        <fs_error_temp_dict>  TYPE any,
        <fs_error_table_dict> TYPE any,
        <fs_table_dict>       TYPE ANY TABLE,
        <fs_table_temp_dict>  TYPE ANY TABLE,
        <fs_field_dict>       TYPE any,
        <fs_field_value_dict> TYPE data.


      DATA: lr_data_dict TYPE REF TO data.


      FIELD-SYMBOLS : <ls_table_dict> TYPE any.
      FIELD-SYMBOLS : <lv_severity_dict>   TYPE any,
                      <fs_final_data_dict> TYPE data.

****
      DATA : gv_web_dict TYPE string.
      DATA : gv_web_dict2 TYPE string.
      DATA : gv_web_dict3 TYPE string.
      DATA: lv_so_det_dict TYPE string.

      DATA : LV_CUST  type c length 10,
             lv_ctext_txt type c LENGTH 60. "01-04

      TRY.


*************start of cloud destination testing
      LV_CUST = |{  ls_dhead-shiptoparty ALPHA = IN }|.
*          IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*            DATA(lo_destination_dict) = cl_http_destination_provider=>create_by_cloud_destination(
*                                         i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*            "                             i_name = 'my403202_public_cloud_wbi' " not working 06
*                                         i_authn_mode = if_a4c_cp_service=>service_specific ).
*
*
***********below logic is URL preparing logic*********
*            CLEAR : gv_web_dict,gv_web_dict2.
*
*     gv_web_dict = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata4/sap/zwbi_sb_custdetails/srvd/sap/zwbi_sd_custdetails/0001/I_Customer?$filter=Customer eq'. "06 not working
*
*                 gv_web_dict2 = | '{ LV_CUST }'|.
*
*
*
*
**        "create HTTP client by destination
*            DATA(lo_web_http_client_dict) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_dict ).
**
**        "adding headers with API Key for API Sandbox
*            DATA(lo_web_http_request_dict) = lo_web_http_client_dict->get_http_request( ).
*
*
*            gv_web_dict = |{ gv_web_dict }{ gv_web_dict2 }|." concatenating
*
*            lo_web_http_request_dict->set_uri_path( i_uri_path = gv_web_dict ).
*
*            lo_web_http_request_dict->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*
*  "          (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
**          (  name = 'x-csrf-token' value = 'fetch' )
**          (  name = 'DataServiceVersion' value = '2.0' )
*           (  name = 'Accept' value = 'application/json' )
*             ) ).
**
*            DATA(lo_web_http_response_dict) = lo_web_http_client_dict->execute( if_web_http_client=>get ).
*            DATA(lv_response_dict) = lo_web_http_response_dict->get_text( )." data fetching in json format
*
*            DATA(lv_status_dict) = lo_web_http_response_dict->get_status(  ).
*            CLEAR : lr_data_dict.
*            CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*              EXPORTING
*                json = lv_response_dict
**               pretty_name  = /ui2/cl_json=>pretty_mode-user
**               assoc_arrays = abap_true
*              CHANGING
*                data = lr_data_dict.

***start of below logic is standard procedure to get data from deep structures to internal table
*            IF lv_status_dict-code = '200' OR lv_status_dict-code = '201'.
*              IF lr_data_dict IS BOUND.
*                UNASSIGN : <fs_data_dict>,<fs_results_dict>.
*                ASSIGN lr_data_dict->* TO <fs_data_dict>.
*
*                ASSIGN COMPONENT 'VALUE' OF STRUCTURE <fs_data_dict> TO <fs_results_dict>.
*                ASSIGN <fs_results_dict>->* TO <fs_error_temp_dict>.

*                LOOP AT <fs_error_temp_dict> ASSIGNING <ls_table_dict> .
*
*                  ASSIGN <ls_table_dict>->* TO <fs_final_data_dict>.
*                  UNASSIGN : <fs_field_dict>, <fs_field_value_dict>.
*                  ASSIGN COMPONENT 'CUSTOMERNAME' OF STRUCTURE <fs_final_data_dict> TO <fs_field_dict>.
*                   ls_dhead-shiptopartyname = <fs_field_dict>->*.
*
*                ENDLOOP.

*              ENDIF.
*            ENDIF.
*          ENDIF.

 SELECT SINGLE customername from I_Customer
   where Customer = @LV_CUST into @ls_dhead-shiptopartyname.

        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.
************************************ end  of customer details
************************************** SO partner address details here cuz BP API not fetching cust details start

                      TRY.
                          DATA : gv_web_DS TYPE string.
                          DATA : gv_web_DS2 TYPE string.
                          DATA : gv_web_DS3 TYPE string.
                          DATA : lv_so_det_DS TYPE string,
                                 lv_pf_DS     TYPE c  LENGTH 2,
                                 lv_pfc_DS    TYPE c  LENGTH 2.


                          DATA:lr_data_dS TYPE REF TO data.

                          FIELD-SYMBOLS :

                            <fs_structure_ds>   TYPE any,
                            <fs_hold_ds>        TYPE any,
                            <fs_error_ds>       TYPE any,
                            <fs_error_temp_ds>  TYPE any,
                            <fs_error_table_ds> TYPE any,
                            <fs_table_ds>       TYPE ANY TABLE,
                            <fs_table_temp_ds>  TYPE ANY TABLE.
                          FIELD-SYMBOLS : <ls_table_ds> TYPE any.

                          FIELD-SYMBOLS:

                            <fs_data_ds>        TYPE data,
                            <fs_results>        TYPE any,
                            <fs_results_ds>     TYPE any,
                            <fs_field_ds>       TYPE any,
                            <fs_final_data_ds>  TYPE data,
                            <fs_field_value_ds> TYPE data.


*************start of cloud destination testing
*                          IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*
*                            DATA(lo_destination_dS) = cl_http_destination_provider=>create_by_cloud_destination(
*                                                i_name       = 'my403232_Public_cloud' " public cloud demo system working 06
*                                                i_authn_mode = if_a4c_cp_service=>service_specific
*                                              ).
***********below logic is URL preparing logic*********
*                            CLEAR : gv_web_dS,gv_web_dS2.
*                            gv_web_dS = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata/sap/API_SALES_ORDER_SRV/A_SalesOrderPartnerAddress?$filter='.  "A_SalesOrderHeaderPartner'.  "A_SalesOrderPartnerAddress'.
*                             gv_web_dS2 = |SalesOrder eq '{ ls_ditems-salesorder }'|.
*                          ENDIF.

*                          IF lv_public_cloud EQ space. " on premise destination logic
** below commented code to call FM from S4D system using destinations***************************
*                            lo_destination_dS = cl_http_destination_provider=>create_by_cloud_destination(
*                                     i_name       = 'F4D_400_CLONING_RP1'  " get this from BTP sub account
*                                     i_authn_mode = if_a4c_cp_service=>service_specific
*                                   ).
*
*                            CLEAR : gv_web_dS,gv_web_dS2.
*                            gv_web_dS = 'https://itcf4d.intern.itelligence.de:8000/sap/opu/odata/sap/API_SALES_ORDER_SRV/A_SalesOrderPartnerAddress?$filter='.
*                                 gv_web_dS2 = |SalesOrder eq '{ ls_ditems-salesorder }'|.
*                          ENDIF.

**        "create HTTP client by destination
*                          DATA(lo_web_http_client_dS) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_dS ).
**
**        "adding headers with API Key for API Sandbox
*                          DATA(lo_web_http_request_dS) = lo_web_http_client_dS->get_http_request( ).
***********************************************************************************************

                          "              CLEAR : gv_web_d.
**********below logic is URL preparing logic*********

*                          gv_web_dS = |{ gv_web_dS }{ gv_web_dS2 }|." concatenating
*
*                          lo_web_http_request_dS->set_uri_path( i_uri_path = gv_web_dS ).
*
*                          lo_web_http_request_dS->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*                          (  name = 'APIKey' value =   'NhKVw93xyOAXFELg0waG5pstqbyG5qB8' ) "'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' ) "   "
*            "              (  name = 'x-csrf-token' value = 'fetch' )
*            "              (  name = 'DataServiceVersion' value = '2.0' )
*                         (  name = 'Accept' value = 'application/json' )
*                           ) ).
**
*                          DATA(lo_web_http_response_dS) = lo_web_http_client_dS->execute( if_web_http_client=>get ).
*                          DATA(lv_response_dS) = lo_web_http_response_dS->get_text( )." data fetching in json format
*
*                          DATA(lv_status_dS) = lo_web_http_response_dS->get_status(  ).
*                          CLEAR : lr_data_dS.
*                          CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*                            EXPORTING
*                              json = lv_response_dS
**                             pretty_name  = /ui2/cl_json=>pretty_mode-user
**                             assoc_arrays = abap_true
*                            CHANGING
*                              data = lr_data_ds.

*                          IF lv_status_ds-code EQ '200'  OR lv_status_ds-code = '201'.  "need to check error logic
****start of below logic is standard procedure to get data from deep structures to internal table
*                            IF lv_status_ds-code = '200' OR lv_status_ds-code = '201'.
*                              IF lr_data_ds IS BOUND.
*                                UNASSIGN : <fs_data_ds>,<fs_results_ds>.
*                                ASSIGN lr_data_ds->* TO <fs_data_ds>.
*                                ASSIGN COMPONENT 'D' OF STRUCTURE <fs_data_ds> TO <fs_results_ds>.
*
*                                ASSIGN <fs_results_ds>->* TO <fs_hold_ds>.
*                                ASSIGN COMPONENT 'RESULTS' OF STRUCTURE <fs_hold_ds> TO <fs_error_ds>.
*
*                                ASSIGN <fs_error_ds>->* TO <fs_error_temp_ds>.
*
*                                LOOP AT <fs_error_temp_ds> ASSIGNING <ls_table_ds> .
*
*                                  ASSIGN <ls_table_ds>->* TO <fs_final_data_ds>.
******
*                                  UNASSIGN : <fs_field_ds>, <fs_field_value_ds>.
*                                  ASSIGN COMPONENT 'ADDRESSEEFULLNAME' OF STRUCTURE <fs_final_data_ds> TO <fs_field_ds>.
*                                  ASSIGN <fs_field_ds>->* TO <fs_field_value_ds>.
*                                 if <fs_field_value_ds> is not INITIAL.
*                                  ls_dhead-shiptopartyname  = <fs_field_value_ds>.
*                                  endif.
*
*                                ENDLOOP.
*
*                              ENDIF.
*                            ENDIF.
*                          ENDIF.

                SELECT  single a~customerfullname from I_customer as a inner join
                I_SalesDocumentPartner as b on a~customer = b~customer
                where salesdocument = @ls_ditems-salesorder into @ls_dhead-shiptopartyname.
        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.

*          endif.
***************************** end
**************************** END OF CUST ADDRESS DETAILS

                      APPEND ls_dhead TO lt_dhead.
                      CLEAR:ls_dhead,ls_dplant.
                      endif.  "28/4/2025 new
                    ENDIF.
***********end of Timestamp to Date conversion declarations
*                  ENDIF.
*                ENDIF.

              CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
            ENDTRY.
          ENDIF.
          clear:ls_ditems.
        ENDLOOP.


***********start of purchase order logic 05***************************************************************
*Elseif  lv_inwtyp eq 'P' .
    ENDIF.

    IF LV_PLant IS NOT INITIAL  AND lv_inwtyp EQ 'P'.

********Fetching PO item details using API BTP version
***PO Item
      FIELD-SYMBOLS : <fs_data_pi>        TYPE data,
                      <fs_results_pi>     TYPE any,
                      <fs_structure_pi>   TYPE any,
                      <fs_hold_pi>        TYPE any,
                      <fs_error_pi>       TYPE any,
                      <fs_error_temp_pi>  TYPE any,
                      <fs_error_table_pi> TYPE any,
                      <fs_table_pi>       TYPE ANY TABLE,
                      <fs_table_temp_pi>  TYPE ANY TABLE,
                      <fs_field_pi>       TYPE any,
                       <fs_field_pih>       TYPE any,
                      <fs_field_value_pi> TYPE data.

***PO item
      FIELD-SYMBOLS : <ls_table_pi> TYPE any.
      FIELD-SYMBOLS : <lv_severity_pi>   TYPE any,
                      <fs_final_data_pi> TYPE data.
      DATA: lr_data_pi TYPE REF TO data.
      DATA : gv_web_pi TYPE string.
      DATA : gv_web_pi2 TYPE string.
      DATA : gv_web_pi3 TYPE string.


data: lv_null type abap_BOOLEAN  VALUE '0'.

      TRY.

*          IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*
*            DATA(lo_destination_pi) = cl_http_destination_provider=>create_by_cloud_destination(
*                                         i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*            "                             i_name = 'my403202_public_cloud_wbi' " not working 06
*                                         i_authn_mode = if_a4c_cp_service=>service_specific ).
*            CLEAR : gv_web_pi.
*
********new start 27-05  here data fetching from custom view using Communication arrangement
*gv_web_pi = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata4/sap/zwbi_sb_po_h_i_supp/srvd/sap/zwbi_sd_po_h_i_supp/0001/ZWBI_DD_PO_H_I?$filter=Plant eq'.
*
*gv_web_pi2 = | '{ lv_plant }' and PurchaseOrderCategory eq 'F' and IsCompletelyDelivered eq false&$top={ lv_top_c }&$expand=_SupplierData |.
*
*          ENDIF.

*          IF lv_public_cloud EQ space. " on premise destination logic
** below  code to call API/Odata Services from S4D system using destinations*********
*            lo_destination_pi = cl_http_destination_provider=>create_by_cloud_destination(
*                     i_name       = 'F4D_400_CLONING_RP1'  " get this from BTP sub account
*                     i_authn_mode = if_a4c_cp_service=>service_specific
*                   ).
*
*            CLEAR : gv_web_pi.
*
**here data fetching from standard API
*        gv_web_pi = 'https://itcf4d.intern.itelligence.de:8000/sap/opu/odata4/sap/api_purchaseorder_2/srvd_a2x/sap/purchaseorder/0001/PurchaseOrderItem?$filter=Plant eq'.
*        gv_web_pi2 = | '{ lv_plant }' and PurchaseOrderCategory eq 'F' and IsCompletelyDelivered eq false&$top={ lv_top_c }&$expand=_SupplierData |. "_PurchaseOrder,_DeliveryAddress |.
*
*          ENDIF.

**        "create HTTP client by destination
*          DATA(lo_web_http_client_pi) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_pi ).
**
**        "adding headers with API Key for API Sandbox
*          DATA(lo_web_http_request_pi) = lo_web_http_client_pi->get_http_request( ).
**********************************************************************************************

          TYPES : BEGIN OF ty_pitems,
                    deldoc          TYPE c LENGTH 10,
                    item            TYPE zwbi_dt_itemno,
                    plant           TYPE c LENGTH 4,
                    Plantname       TYPE c LENGTH 30,
                    Ddate           TYPE  datum,
                    Shiptoparty     TYPE c LENGTH 10,
                    Soldtoparty     TYPE c LENGTH 10,
                    Shiptopartyname TYPE c LENGTH 60,
                    Shippingpoint   TYPE c LENGTH 4,
                    Sloc            Type c LENGTH 4,
                    Slocname        type c LENGTH 30,
                    itemweightunit  TYPE c LENGTH 3,
                  END OF ty_pitems.
*
          DATA : lt_pitems TYPE STANDARD TABLE OF ty_pitems,
                 ls_pitems TYPE ty_pitems.

          DATA: lv_po_ordqty      TYPE zwbi_dt_quantity,
                lv_po_ItemGWeight TYPE zwbi_dt_quantity,
                lv_po_ItemNWeight TYPE zwbi_dt_quantity,
                lv_ITEMWEIGHTUNIT TYPE c LENGTH 3.



**********below logic is URL preparing logic*********
*          gv_web_pi = |{ gv_web_pi }{ gv_web_pi2 }|." concatenating
*
*          lo_web_http_request_pi->set_uri_path( i_uri_path = gv_web_pi ).
*
*          lo_web_http_request_pi->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
**          (  name = 'APIKey' value = 'NhKVw93xyOAXFELg0waG5pstqbyG5qB8' )
**          (  name = 'x-csrf-token' value = 'fetch' )
*          (  name = 'DataServiceVersion' value = '1.0' )
*         (  name = 'Accept' value = 'application/json' )
*           ) ).
**
*          DATA(lo_web_http_response_pi) = lo_web_http_client_pi->execute( if_web_http_client=>get ).
*          DATA(lv_response_pi) = lo_web_http_response_pi->get_text( )." data fetching in json format


*          DATA(lv_status_pi) = lo_web_http_response_pi->get_status(  ).
*          CLEAR : lr_data_pi.
*          CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*            EXPORTING
*              json = lv_response_pi
**             pretty_name  = /ui2/cl_json=>pretty_mode-user
**             assoc_arrays = abap_true
*            CHANGING
*              data = lr_data_pi.

***start of below logic is standard procedure to get data from deep structures to internal table
*          IF lv_status_pi-code = '200' OR lv_status_pi-code = '201'.
*
*            IF lr_data_pi IS BOUND.
*
*              UNASSIGN : <fs_data_pi>,<fs_results_pi>.
*              ASSIGN lr_data_pi->* TO <fs_data_pi>.
**              ASSIGN COMPONENT 'D' OF STRUCTURE <fs_data_pi> TO <fs_results_pi>."<fs_results_dh>.
*               ASSIGN COMPONENT 'VALUE' OF STRUCTURE <fs_data_pi> TO <fs_results_pi>."<fs_results_dh>.
**               ASSIGN <fs_results_pi>->* TO <fs_error_pi>.
*               ASSIGN <fs_results_pi>->* TO <fs_error_temp_pi>.
*
*              CLEAR: lv_po_ordqty,lv_po_ItemGWeight,lv_po_ItemNWeight.
*              LOOP AT <fs_error_temp_pi> ASSIGNING <ls_table_pi> .
*
*                ASSIGN <ls_table_pi>->* TO <fs_final_data_pi>.
*
*                UNASSIGN : <fs_field_pi>, <fs_field_value_pi>.
*                ASSIGN COMPONENT 'PURCHASEORDER' OF STRUCTURE <fs_final_data_pi> TO <fs_field_pi>.
*                ls_dhead-deldoc      =   <fs_field_pi>->*.
*
*                 UNASSIGN : <fs_field_pi>, <fs_field_value_pi>.
*                ASSIGN COMPONENT 'STORAGELOCATION' OF STRUCTURE <fs_final_data_pi> TO <fs_field_pi>..
*                         ls_dhead-sloc = <fs_field_pi>->*.
*
*                  clear: ls_sloc.
*                  read table lt_sloc into ls_sloc  with key sloc = ls_dhead-sloc.
*                  if sy-subrc eq 0.
*                  ls_dhead-slocname    = ls_sloc-slocname.
*                  endif.

*                UNASSIGN : <fs_field_pi>, <fs_field_value_pi>.
*                ASSIGN COMPONENT 'PLANT' OF STRUCTURE <fs_final_data_pi> TO <fs_field_pi>.
*
*                ls_dhead-plant_n =  <fs_field_pi>->*.
*
*                 READ TABLE  lt_dplant INTO  ls_dplant WITH KEY plant = ls_dhead-plant_n.
*                      IF sy-subrc EQ 0.
*                        ls_dhead-plantname  =   ls_dplant-plantname.
*                      ENDIF.
*
*                      ls_dhead-inwtype = lv_inwtyp.
*
*
*              UNASSIGN : <fs_field_pi>, <fs_field_value_pi>.
*                ASSIGN COMPONENT 'SUPPLIER' OF STRUCTURE <fs_final_data_pi> TO <fs_field_pi>.
*                         ls_dhead-shiptoparty = <fs_field_pi>->*.
*
*
*               UNASSIGN : <fs_field_pi>, <fs_field_value_pi>.  "$EXPAND NODE _Supplierdata of PO ORDER DATA  "26-05
*                ASSIGN COMPONENT '_SUPPLIERDATA' OF STRUCTURE <fs_final_data_pi> TO <fs_field_pih>.
*                  ASSIGN COMPONENT 'SUPPLIERNAME' OF STRUCTURE <fs_field_pih>->* TO <fs_field_pi>.
*
*                ls_dhead-shiptopartyname  = <fs_field_pi>->*.


 SELECT a~purchaseorder, a~storagelocation, a~plant, b~supplier, c~suppliername
    from I_PurchaseOrderItemAPI01 as a inner join I_PurchaseOrderAPI01 as b
    on a~purchaseorder = b~purchaseorder INNER join I_Supplier as c on b~supplier = c~supplier
    where plant = @lv_plant and PurchaseOrderCategory eq 'F' and IsCompletelyDelivered eq ''
    into table @data(lt_podata).
   if sy-subrc EQ 0.
     loop at lt_podata INTO data(ls_podata).
      ls_dhead-deldoc = ls_podata-PURCHASEORDER.
      ls_dhead-sloc = ls_podata-storagelocation.
      clear: ls_sloc.
      read table lt_sloc into ls_sloc  with key sloc = ls_dhead-sloc.
      if sy-subrc eq 0.
      ls_dhead-slocname    = ls_sloc-slocname.
      endif.
      ls_dhead-plant_n = ls_podata-plant.
      READ TABLE  lt_dplant INTO  ls_dplant WITH KEY plant = ls_dhead-plant_n.
       IF sy-subrc EQ 0.
          ls_dhead-plantname  =   ls_dplant-plantname.
       ENDIF.
      ls_dhead-inwtype = lv_inwtyp.
      ls_dhead-shiptoparty = ls_podata-SUPPLIER.
      ls_dhead-shiptopartyname = ls_podata-SUPPLIERNAME.
      APPEND ls_dhead TO lt_dhead.
      CLEAR:ls_dhead,ls_dplant.
     endloop.
   endif.
**************start of logic to fetch PO Sold to party ship to party  text 26-05

* IF lv_public_cloud EQ space. " on premise destination logic
*
* UNASSIGN : <fs_field_pi>, <fs_field_value_pi>.  "$EXPAND NODE _PURCHASE ORDER DATA  "26-05
*                ASSIGN COMPONENT '_PURCHASEORDER' OF STRUCTURE <fs_final_data_pi> TO <fs_field_pih>.
*                  ASSIGN COMPONENT 'SUPPLIER' OF STRUCTURE <fs_field_pih>->* TO <fs_field_pi>.
*
*                ls_dhead-shiptoparty  = <fs_field_pi>->*.
*
*    TYPES : BEGIN OF ty_sp,
**                      item         TYPE /N4C03/WBI_DT_ITEMNO,
*              SPnumber     TYPE c LENGTH 10,
*              SPtext TYPE c LENGTH  60,
*            END OF ty_sp.
**
*    DATA : lt_sp     TYPE STANDARD TABLE OF ty_sp,
*           lt_sp_out TYPE STANDARD TABLE OF ty_sp,
*           ls_sp     TYPE ty_sp,
*           lv_sp_txt TYPE c LENGTH 30. "01-04
*
*
*    DATA : gv_web_sp TYPE string.
*    DATA : gv_web_sp2 TYPE string.
*    DATA : gv_web_sp3 TYPE string.
*
*
*    DATA: lr_data_sp TYPE REF TO data.
*
*    FIELD-SYMBOLS:
*      <fs_data_sp>        TYPE data,
*      <fs_results_sp>     TYPE any,
*      <fs_structure_sp>   TYPE any,
*      <fs_hold_sp>        TYPE any,
*      <fs_error_sp>       TYPE any,
*      <fs_error_temp_sp>  TYPE any,
*      <fs_error_table_sp> TYPE any,
*      <fs_table_sp>       TYPE ANY TABLE,
*      <fs_table_temp_sp>  TYPE ANY TABLE,
*      <fs_field_sp>       TYPE any,
*      <fs_field_value_sp> TYPE data.
*
*
*    FIELD-SYMBOLS : <ls_table_sp> TYPE any.
*    FIELD-SYMBOLS : <lv_severity_sp>   TYPE any,
*                    <fs_final_data_sp> TYPE data.

*******
*    TRY.


*************start of cloud destination testing

*        IF lv_public_cloud EQ 'X'. "public cloud destinations logic
*          DATA(lo_destination_sp) = cl_http_destination_provider=>create_by_cloud_destination(
*                                       i_name = 'my403232_Public_cloud' " public cloud demo system working 06
*          "                             i_name = 'my403202_public_cloud_wbi' " not working 06
*                                       i_authn_mode = if_a4c_cp_service=>service_specific ).
*
*
***********below logic is URL preparing logic*********
*          CLEAR : gv_web_sp,gv_web_sp2.
*          gv_web_sp = 'https://my403232-api.s4hana.cloud.sap/sap/opu/odata4/sap/zwbi_sb_supp/srvd/sap/zwbi_sd_supp/0001/I_Supplier?$filter=Supplier eq' .".$inlinecount=allpages'.
*            gv_web_sp2 = |('{ ls_dhead-shiptoparty }')|. "09-03
*
**        "create HTTP client by destination
*          DATA(lo_web_http_client_sp) = cl_web_http_client_manager=>create_by_http_destination( lo_destination_sp ).
**
**        "adding headers with API Key for API Sandbox
*          DATA(lo_web_http_request_sp) = lo_web_http_client_sp->get_http_request( ).
*
*
*          gv_web_sp = |{ gv_web_sp }{ gv_web_sp2 }|." concatenating
*
*          lo_web_http_request_sp->set_uri_path( i_uri_path = gv_web_sp ).
*
*          lo_web_http_request_sp->set_header_fields( VALUE #(
*
**         (  name = 'APIKey' value = 'LFCePLAPFQgKOdRgwQx8coSdJLenYXug' )
*
*"          (  name = 'APIKey' value = 'gbw9IUGDQvBxQfX1hysRApW2qAF9afgS' )
**          (  name = 'x-csrf-token' value = 'fetch' )
**          (  name = 'DataServiceVersion' value = '2.0' )
*         (  name = 'Accept' value = 'application/json' )
*           ) ).
**
*          DATA(lo_web_http_response_sp) = lo_web_http_client_sp->execute( if_web_http_client=>get ).
*          DATA(lv_response_sp) = lo_web_http_response_sp->get_text( )." data fetching in json format
*
*          DATA(lv_status_sp) = lo_web_http_response_sp->get_status(  ).
*          CLEAR : lr_data_sp.
*          CALL METHOD /ui2/cl_json=>deserialize "class is used to convert json data to internal table format
*            EXPORTING
*              json = lv_response_sp
**             pretty_name  = /ui2/cl_json=>pretty_mode-user
**             assoc_arrays = abap_true
*            CHANGING
*              data = lr_data_sp.

***start of below logic is standard procedure to get data from deep structures to internal table
*          IF lv_status_sp-code = '200' OR lv_status_sp-code = '201'.
*            IF lr_data_sp IS BOUND.
*              UNASSIGN : <fs_data_sp>,<fs_results_sp>.
*              ASSIGN lr_data_sp->* TO <fs_data_sp>.
*
*              ASSIGN COMPONENT 'VALUE' OF STRUCTURE <fs_data_sp> TO <fs_results_sp>.
*              ASSIGN <fs_results_sp>->* TO <fs_error_temp_sp>.
*
*
*              LOOP AT <fs_error_temp_sp> ASSIGNING <ls_table_sp> .
*
*                ASSIGN <ls_table_sp>->* TO <fs_final_data_sp>.
*
*                UNASSIGN : <fs_field_sp>, <fs_field_value_sp>.
*                ASSIGN COMPONENT 'SUPPLIER' OF STRUCTURE <fs_final_data_sp> TO <fs_field_sp>.
*                ls_sp-spnumber = <fs_field_sp>->*.
*
*               UNASSIGN : <fs_field_sp>, <fs_field_value_sp>.
*                ASSIGN COMPONENT 'SUPPLIERNAME' OF STRUCTURE <fs_final_data_sp> TO <fs_field_sp>.
*                ls_sp-sptext = <fs_field_sp>->*. "01-04
*
*              ls_dhead-shiptopartyname  =  <fs_field_sp>->*.  " delete later testing 27-05
*
*                APPEND ls_sp TO lt_sp.
*                CLEAR:ls_sp.
*              ENDLOOP.
*
*            ENDIF.
*          ENDIF.
*        ENDIF.

*      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
*    ENDTRY.

*ENDIF.
*********end of logic to fetch PO SP text  23-04

*                      APPEND ls_dhead TO lt_dhead.
*                      CLEAR:ls_dhead,ls_dplant.

*              ENDLOOP.

              IF lt_dhead IS NOT INITIAL.
                SORT lt_dhead BY deldoc plant_n.
                DELETE ADJACENT DUPLICATES FROM lt_dhead COMPARING deldoc plant_n.
              ENDIF.

*            ENDIF.
*          ENDIF.

        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.

********end of purchase order logic

    ENDIF.

endif.
*******************************SO & PO data sending to screen for F4 help**********************************
if lt_dhead[] is not INITIAL.
       DATA: lv_order TYPE string VALUE 'Deldoc'.

****1/4/2025 START of  sort order logic

data:lv_field type string,
     lv_descend type c LENGTH 1,
     lv_Asc type c LENGTH 1,
     lv_sord type string.

 loop at lt_sort INTO data(ls_sort).
 lv_field = ls_sort-element_name .
 lv_descend = ls_sort-descending.
 if lv_descend = 'X'.
 lv_sord  = 'Descending'.
 else .
 lv_sord  = 'Ascending'.
 endif.
clear:lv_order.
 CONCATENATE lv_field lv_sord INTO lv_order SEPARATED BY space.

 if lv_field is INITIAL.
 clear:lv_order.
 lv_field = 'DELDOC'.
 lv_sord  = 'Ascending'.
 CONCATENATE lv_field lv_sord INTO lv_order SEPARATED BY space.
 endif.

 endloop.

****1/4/2025 end  of  sort order logic

        SELECT * FROM @lt_dhead  AS Output  " @lt_ditems AS Output
      WHERE (ls_get_filter_sql)
               ORDER BY (lv_order)
                          INTO CORRESPONDING FIELDS OF TABLE @lt_dhead_out  " @lt_ditems_out
                          UP TO @lv_top ROWS
                         OFFSET @lv_skip .

        IF io_request->is_total_numb_of_rec_requested(  ).

          io_response->set_total_number_of_records( lines( lt_dhead ) ).
        ENDIF.
        io_response->set_data( lt_dhead_out ).
endif.
  ENDMETHOD.