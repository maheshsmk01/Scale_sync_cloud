
*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_ls_buffer_item DEFINITION. "buffer data to use globally
  PUBLIC SECTION.


    TYPES : BEGIN OF ty_dplant_p,
              Plant     TYPE c LENGTH 4,
              PlantName TYPE c LENGTH  30,

            END OF ty_dplant_p.
*
    DATA : lt_dplant_p  TYPE STANDARD TABLE OF ty_dplant_p.

    CLASS-DATA: gv_header_qty_so         TYPE string,
                gv_header_grossweight_so TYPE string, "/N4C03/WBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_netweight_so   TYPE string, "/N4C03/WBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_weightuint_so  TYPE c LENGTH 3,
                gv_header_grossweight_po TYPE string, "/N4C03/WBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_netweight_po   TYPE string, "/N4C03/WBI_DT_WEIGHT ,"p LENGTH 15 DECIMALS 2,
                gv_header_weightuint_po  TYPE  c LENGTH 3,
                GV_CreationDate_SO       TYPE String, "/N4C03/WBI_DT_DATE_N,
                GV_CreationTIME_SO       TYPE uzeit, "String, "/N4C03/WBI_DT_DATE_N,
                GV_ShipToParty_SO        TYPE c LENGTH 10,
                GV_SoldToParty_SO        TYPE c LENGTH 10,
                GV_shippoint             TYPE c LENGTH 4,
                gv_shiptext              TYPE c LENGTH 38,
                gv_bp                    TYPE c LENGTH 10,
                gv_pf                    TYPE c  LENGTH 2,
                gv_pfc                   TYPE c  LENGTH 2,
                gv_AddressID             TYPE c LENGTH 10,
                gv_addname1              TYPE c LENGTH 35,
                gv_REGION                TYPE c LENGTH 8,
                gv_orgname1              TYPE c LENGTH 35,
                GV_CreationDate_PO       TYPE String, "/N4C03/WBI_DT_DATE_N,
                gv_uom                   TYPE c LENGTH 3,
                gv_item_uom              TYPE c LENGTH 3,
                GV_OverallDBStatus       TYPE c LENGTH 30,
                GV_OverallGoodsMovStatus TYPE c LENGTH 30,
                GV_OverallPackStatus     TYPE c LENGTH 30,
                GV_OverallPickConfStatus TYPE c LENGTH 30,
                GV_OverallPickStatus     TYPE c LENGTH 30,
                GV_PodelvStatus          TYPE c LENGTH 30,
                gv_delquantity_po        TYPE string,
                gv_invquantity_po        TYPE string,
                gv_stilltodelquantity_po TYPE string,
                gv_invoicstatus          TYPE c LENGTH 30,
                GV_sloc                  TYPE c LENGTH 4,
                GV_sloctext              TYPE c LENGTH 38,
                gv_header_pickqty_so     TYPE string,
                gv_header_pickqty_so_r   TYPE string,
                gv_error_flag            TYPE c LENGTH 1,
                gv_msg_flag              TYPE c LENGTH 1,
                gv_msg_flag2             TYPE c LENGTH 1,
                gv_msg_flag3             TYPE c LENGTH 1.


ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR Item RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR item RESULT result.
    METHODS setinwardtype FOR DETERMINE ON MODIFY
      IMPORTING keys FOR item~setinwardtype .
    METHODS validateorder FOR VALIDATE ON SAVE
      IMPORTING keys FOR item~validateorder .
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR item RESULT result.
    METHODS calctotalweight FOR DETERMINE ON SAVE
      IMPORTING keys FOR item~calctotalweight.
    METHODS getpickqtyupdate FOR  MODIFY
      IMPORTING keys FOR ACTION item~getpickqtyupdate RESULT result. " added RESULT result

 METHODS getItemDelete FOR  MODIFY
      IMPORTING keys FOR ACTION item~getItemDelete RESULT result. "//30/12/2024

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD setinwardtype.
    DATA: lv_cnt          TYPE i,
          lv_public_cloud TYPE c LENGTH 1. " VALUE 'X'.

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE c
        ENTITY item
            ALL FIELDS WITH CORRESPONDING #( keys )
                RESULT DATA(items).

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE   c
            ENTITY item BY \_head
                ALL FIELDS WITH CORRESPONDING #( keys )
                    RESULT DATA(heads)
                    LINK   DATA(link)
                    FAILED DATA(failed)
                    REPORTED DATA(reported1).

    TRY.
        DATA(ls_head) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        DATA(ls_item) = items[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    LOOP AT items INTO DATA(ls_itemtemp).
      lv_cnt = lv_cnt + 1.
      IF lv_cnt = 2.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF lv_cnt > 1.
      RETURN.
    ENDIF.

*********start of shipping point text 12-04

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
              spoint TYPE c LENGTH 4,
              spname TYPE c LENGTH  30,
            END OF ty_stext.
*
    DATA : lt_stext     TYPE STANDARD TABLE OF ty_stext,
           lt_stext_out TYPE STANDARD TABLE OF ty_stext,
           ls_stext     TYPE ty_stext,
           lv_stext_txt TYPE c LENGTH 30. "01-04


TRY.
 SELECT Shippingpoint,ShippingPointName from i_shippingpointtext WHERE language = @sy-langu
               into table @lt_stext.

      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.




********end of shipping point text 12-04
*********start of logic to fetch storage location text 02-05

    TYPES : BEGIN OF ty_sloc,
*                      item         TYPE zWBI_DT_ITEMNO,
              Sloc     TYPE c LENGTH 4,
              Slocname TYPE c LENGTH  30,
              dchannel TYPE c LENGTH 2,

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

TRY.
SELECT storagelocation, StorageLocationName, DistributionChannel from I_StorageLocation into TABLE @lt_sloc.
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.



*********end of logic to fetch storage location text

****************************************************** plant text
***SO item
    FIELD-SYMBOLS:
      <fs_data_dip>        TYPE data,
      <fs_results_dip>     TYPE any,
      <fs_structure_dip>   TYPE any,
      <fs_hold_dip>        TYPE any,
      <fs_error_dip>       TYPE any,
      <fs_error_temp_dip>  TYPE any,
      <fs_error_table_dip> TYPE any,
      <fs_table_dip>       TYPE ANY TABLE,
      <fs_table_temp_dip>  TYPE ANY TABLE,
      <fs_field_dip>       TYPE any,
      <fs_field_value_dip> TYPE data.


    DATA: lr_data_dip TYPE REF TO data.


    FIELD-SYMBOLS : <ls_table_dip> TYPE any.
    FIELD-SYMBOLS : <lv_severity_dip>   TYPE any,
                    <fs_final_data_dip> TYPE data.

****
    DATA : gv_web_dip TYPE string.
    DATA : gv_web_dip2 TYPE string.
    DATA : gv_web_dip3 TYPE string.
    DATA: lv_so_det_dip TYPE string.



    TYPES : BEGIN OF ty_dplant,
              Plant     TYPE c LENGTH 4,
              PlantName TYPE c LENGTH  30,

            END OF ty_dplant.
*
    DATA : lt_dplant     TYPE STANDARD TABLE OF ty_dplant,
           lt_dplant_out TYPE STANDARD TABLE OF ty_dplant,
           ls_dplant     TYPE ty_dplant,
           lv_dplant_txt TYPE c LENGTH 30.


TRY.
SELECT Plant, Plantname from i_plant into table @lt_dplant.
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.

   SELECT SINGLE * FROM i_businessuserbasic
    WHERE businesspartner = @sy-uname+2(10) into @data(ls_username1).
    if sy-subrc EQ 0.
       data(lv_fullname) = ls_username1-PersonFullName.
    endif.
    if lv_fullname is INITIAL.
            lv_fullname = sy-uname.
      endif.

***************end of logic fetching plants from on premise S4D system using destinations*******


*********************************** plant text

    IF ls_item-intype IS INITIAL.

      SELECT SINGLE
          FROM zwbi_vehicle_inward_item "zi_vehicle_inward_item_data  c  view
              FIELDS MAX( inwarditem ) AS inwarditem
                  WHERE inwarduuid = @ls_item-inward_uuid
                    INTO @DATA(max_inwarditem).

      MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE c
                ENTITY item
                    UPDATE SET FIELDS WITH VALUE #(
                            FOR it IN items (
                                %key = it-%key
                                %is_draft = it-%is_draft
                                intype = ls_head-intype
                                inwarditem = max_inwarditem + 1
                                dchannel = ls_head-dchannel
                                plant = ls_head-plant
                                CreatedOn = sy-datum
                                CreatedBy = lv_fullname
                           "     %control = value (  )
                            )
                    ) REPORTED DATA(modifyreported).
      reported = CORRESPONDING #( DEEP modifyreported ).

    ELSEIF ls_item-ordnum IS NOT INITIAL.

      CLEAR:   lcl_ls_buffer_item=>gv_header_qty_so,
               lcl_ls_buffer_item=>gv_header_grossweight_so,
               lcl_ls_buffer_item=>gv_header_netweight_so,
               lcl_ls_buffer_item=>gv_header_weightuint_so,
               lcl_ls_buffer_item=>gv_header_grossweight_po,
               lcl_ls_buffer_item=>gv_header_netweight_po,
               lcl_ls_buffer_item=>gv_header_weightuint_po,
              lcl_ls_buffer_item=>GV_CreationDate_SO,
              lcl_ls_buffer_item=>GV_ShipToParty_SO,
             lcl_ls_buffer_item=>GV_SoldToParty_SO,
             lcl_ls_buffer_item=>gv_bp,
             lcl_ls_buffer_item=>gv_pf,
             lcl_ls_buffer_item=>gv_addname1,
             lcl_ls_buffer_item=>gv_orgname1,
             lcl_ls_buffer_item=>gv_header_pickqty_so,
             lcl_ls_buffer_item=>GV_CreationTIME_SO.

      IF ls_item-intype = 'S'.

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

***Start of Timestamp to Date conversion declarations*****
        TYPES : BEGIN OF ty_data,
                  create_date TYPE datum, "timestamp,  " <<<<<<<<< This is the Trick
                END OF ty_data.

        DATA: lv_json1                    TYPE   string,
              lv_json2                    TYPE string,
              lv_json3                    TYPE string,
              lv_cdate                    TYPE datum,
              LV_OverallDBStatus_SO       TYPE c LENGTH 1,
              LV_OverallGoodsMovStatus_SO TYPE c LENGTH 1,
              LV_OverallPackStatus        TYPE c LENGTH 1,
              LV_OverallPickConfStatus    TYPE c LENGTH 1,
              LV_OverallPickStatus        TYPE c LENGTH 1.

        DATA: ls_date TYPE ty_data,
              lv_json TYPE /ui2/cl_json=>json.
******end of Timestamp declartions**********************

        DATA : gv_web_Dh TYPE string.
        DATA : gv_web_Dh2 TYPE string.
        DATA : gv_web_Dh3 TYPE string.
        DATA lv_so_det_Dh TYPE string.


        IF ls_item-ordnum IS NOT INITIAL.

TRY.
       SELECT SINGLE HEADERGROSSWEIGHT,HEADERNETWEIGHT,HEADERWEIGHTUNIT,CREATIONDATE,
           OVERALLDELIVRELTDBILLGSTATUS,OVERALLGOODSMOVEMENTSTATUS, OVERALLPACKINGSTATUS,
           OVERALLPICKINGCONFSTATUS,OVERALLPICKINGSTATUS, deliverydocument,shiptoparty,soldtoparty,
           shippingpoint, DeliveryDate
           from I_DeliveryDocument where deliverydocument = @ls_item-ordnum into @data(ls_shead).
           if sy-subrc EQ 0.

            lcl_ls_buffer_item=>gv_header_grossweight_so = ls_shead-HEADERGROSSWEIGHT.
            lcl_ls_buffer_item=>gv_header_netweight_so = ls_shead-HEADERNETWEIGHT.
            lcl_ls_buffer_item=>gv_header_weightuint_so = ls_shead-HEADERWEIGHTUNIT.
            lcl_ls_buffer_item=>GV_CreationDate_SO = ls_shead-CREATIONDATE.
            lcl_ls_buffer_item=>gv_shiptoparty_so   = ls_shead-shiptoparty.
            lcl_ls_buffer_item=>GV_SoldToParty_SO   = ls_shead-soldtoparty.
            lcl_ls_buffer_item=>GV_shippoint = ls_shead-shippingpoint.
            clear ls_stext.
            read table lt_stext into ls_stext WITH KEY spoint = ls_shead-shippingpoint.
            if sy-subrc eq 0.
            lcl_ls_buffer_item=>gv_Shiptext = ls_stext-spname.
            endif.


              IF ls_shead-OVERALLDELIVRELTDBILLGSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallDBStatus =     'Not Relevant'.
              ELSEIF ls_shead-OVERALLDELIVRELTDBILLGSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallDBStatus =  'Not yet processed'.
              ELSEIF ls_shead-OVERALLDELIVRELTDBILLGSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallDBStatus =  'Partially processed'.
              ELSEIF ls_shead-OVERALLDELIVRELTDBILLGSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallDBStatus =   'Completely processed'.
              ENDIF.

              IF ls_shead-OVERALLGOODSMOVEMENTSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus =     'Not Relevant'.
              ELSEIF ls_shead-OVERALLGOODSMOVEMENTSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus =  'Not yet processed'.
              ELSEIF ls_shead-OVERALLGOODSMOVEMENTSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus =  'Partially processed'.
              ELSEIF ls_shead-OVERALLGOODSMOVEMENTSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus =   'Completely processed'.
              ENDIF.

              IF ls_shead-OVERALLPACKINGSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallPackStatus =     'Not Relevant'.
              ELSEIF ls_shead-OVERALLPACKINGSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallPackStatus =  'Not yet processed'.
              ELSEIF ls_shead-OVERALLPACKINGSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallPackStatus =  'Partially processed'.
              ELSEIF ls_shead-OVERALLPACKINGSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallPackStatus =   'Completely processed'.
              ENDIF.

              IF ls_shead-OVERALLPICKINGCONFSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus =     'Not Relevant'.
              ELSEIF ls_shead-OVERALLPICKINGCONFSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus =  'Not yet processed'.
              ELSEIF ls_shead-OVERALLPICKINGCONFSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus =  'Partially processed'.
              ELSEIF ls_shead-OVERALLPICKINGCONFSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus =   'Completely processed'.
              ENDIF.

              IF ls_shead-OVERALLPICKINGSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallPickStatus =     'Not Relevant'.
              ELSEIF ls_shead-OVERALLPICKINGSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallPickStatus =  'Not yet processed'.
              ELSEIF ls_shead-OVERALLPICKINGSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallPickStatus =  'Partially processed'.
              ELSEIF ls_shead-OVERALLPICKINGSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallPickStatus =   'Completely processed'.
              ENDIF.

              CLEAR:lv_cdate,lv_json1,lv_json2,lv_json3,lv_json,ls_date.

*             lv_json1 = '{ "Order_No" : "0021232324" , "Create_Date" : '.
              lv_json1 = '{ "Create_Date" : '.
              lv_json2 = | "{ lcl_ls_buffer_item=>GV_CreationDate_SO }" |.
              lv_json3 = '}'.
              lv_json  = |'{ lv_json1 }{ lv_json2 }{ lv_json3 }'|.

              /ui2/cl_json=>deserialize(
                EXPORTING
                  json        = lv_json             " JSON string
                CHANGING
                  data        = ls_date ).          " Converted Data

              lv_cdate =   ls_date-create_date." So creation date

           endif.
            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.

        ENDIF.

******************fetching sales order number from delivery number

*API logic INPUT DELIVERY NUMBER from screen AND OUTPUT IS SALES ORDER

        FIELD-SYMBOLS:
          <fs_data>           TYPE data,
          <fs_data_ds>        TYPE data,
          <fs_results>        TYPE any,
          <fs_results_ds>     TYPE any,
          <fs_structure>      TYPE any,
          <fs_hold>           TYPE any,
          <fs_error>          TYPE any,
          <fs_error_temp>     TYPE any,
          <fs_error_temp_d>   TYPE any,
          <fs_error_table>    TYPE  any,
          <fs_table>          TYPE  ANY TABLE,
          <fs_table_temp>     TYPE  ANY TABLE,
          <fs_field>          TYPE any,
          <fs_field_d>        TYPE any,
          <fs_field_ds>       TYPE any,
          <fs_field_value>    TYPE data,
          <fs_field_value_d>  TYPE data,
          <fs_field_value_ds> TYPE data.
        FIELD-SYMBOLS : <ls_table> TYPE any.
        FIELD-SYMBOLS : <ls_table_d> TYPE any.
        FIELD-SYMBOLS : <lv_severity>      TYPE any,
                        <fs_final_data>    TYPE data,
                        <fs_final_data_d>  TYPE data,
                        <fs_final_data_ds> TYPE data.

        DATA: lr_data    TYPE REF TO data,
              lr_data_d  TYPE REF TO data,
              lr_data_dS TYPE REF TO data.

        DATA :    "ls_cond TYPE ty_cond,
          lv_so      TYPE c LENGTH 10,
          lv_DN      TYPE c LENGTH 10,
          lv_DN_item TYPE zwbi_dt_itemno,
          lv_so_qty  TYPE zwbi_dt_weigh.

        DATA : gv_web TYPE string.
        DATA : gv_web2 TYPE string.
        DATA : gv_web3 TYPE string.
        DATA lv_so_det TYPE string.


        IF NOT ls_item-ordnum IS INITIAL.


TRY.

  SELECT single REFERENCESDDOCUMENT,ACTUALDELIVERYQUANTITY,DISTRIBUTIONCHANNEL,DELIVERYQUANTITYUNIT,
         DELIVERYDOCUMENT,DELIVERYDOCUMENTITEM , ItemWeightUnit  from I_DeliveryDocumentItem
         where DELIVERYDOCUMENT = @ls_item-ordnum into @data(ls_sohead).
      if sy-subrc eq 0.
        lv_so = ls_sohead-REFERENCESDDOCUMENT.
        lv_so_qty = ls_sohead-ACTUALDELIVERYQUANTITY.
        lcl_ls_buffer_item=>gv_header_qty_so  =  lcl_ls_buffer_item=>gv_header_qty_so  + lv_so_qty.

        ls_head-dchannel = ls_sohead-DISTRIBUTIONCHANNEL.
* To convert internal UOM to External UOM
       SELECT SINGLE UnitOfMeasure_E from I_UnitOfMeasureText
          where UnitOfMeasure = @ls_sohead-DELIVERYQUANTITYUNIT
            and Language = @sy-langu into @data(lv_external_uom).

        lcl_ls_buffer_item=>gv_uom = lv_external_uom.

        lcl_ls_buffer_item=>gv_item_uom = ls_sohead-itemweightunit.
        clear lv_dn.
        lv_dn = ls_sohead-DELIVERYDOCUMENT.

        CLEAR:lv_DN_item.
        lv_DN_item = ls_sohead-DELIVERYDOCUMENTITEM.

        CLEAR:lv_so_qty.


      endif.

            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.

******Start of SD delv no items pick quantity logic API*******
*                    TRY.

                        DATA : gv_web_pdi TYPE string.
                        DATA : gv_web_pdi2 TYPE string.
                        DATA : gv_web_pdi3 TYPE string.
                        DATA: lv_so_det_pdi TYPE string,
                              lv_pdchan     TYPE c LENGTH 2.


                        TYPES : BEGIN OF ty_pditems,
                                  Predeldoc TYPE c LENGTH 10,
                                  Preitem   TYPE zwbi_dt_itemno,
                                  subdeldoc TYPE c LENGTH 10,
                                  Pickqty   TYPE  zwbi_dt_weigh,
                                  subdoccat type c LENGTH 1,  "new 05-06

                                END OF ty_pditems.
*
                        DATA : lt_pditems TYPE STANDARD TABLE OF ty_pditems,
                               ls_pditems TYPE ty_pditems.

***SO Header
                        FIELD-SYMBOLS : <ls_table_pdh> TYPE any.
                        FIELD-SYMBOLS : <lv_severity_pdh>   TYPE any,
                                        <fs_final_data_pdh> TYPE data.
                        DATA: lr_data_pdh TYPE REF TO data.

*****SO Item
                        FIELD-SYMBOLS : <ls_table_pdi> TYPE any.
                        FIELD-SYMBOLS : <lv_severity_pdi>   TYPE any,
                                        <fs_final_data_pdi> TYPE data.
                        DATA: lr_data_pdi TYPE REF TO data.

                        FIELD-SYMBOLS: <fs_data_pdi>        TYPE data,
                                       <fs_results_pdi>     TYPE any,
                                       <fs_structure_pdi>   TYPE any,
                                       <fs_hold_pdi>        TYPE any,
                                       <fs_error_pdi>       TYPE any,
                                       <fs_error_temp_pdi>  TYPE any,
                                       <fs_error_table_pdi> TYPE any,
                                       <fs_table_pdi>       TYPE ANY TABLE,
                                       <fs_table_temp_pdi>  TYPE ANY TABLE,
                                       <fs_field_pdi>       TYPE any,
                                       <fs_field_value_pdi> TYPE data.
*****

      TRY.
       select single * from I_BillingDocumentItem
      WHERE ReferenceSDDocument = @lv_DN and ReferenceSDDocumentItem = @lv_DN_item
       into @data(ls_soitemdata).

       if sy-subrc eq 0.
            ls_pditems-predeldoc = ls_soitemdata-SalesDocument.
            ls_pditems-subdoccat = ls_soitemdata-SalesSDDocumentCategory.
            ls_pditems-pickqty = ls_soitemdata-billingQUANTITYINBASEUNIT.

*          if ls_pditems-subdoccat eq 'Q' .  "new 05-06  pick qty based on SUBSEQUENTDOCUMENTCATEGORY in SO
             lcl_ls_buffer_item=>gv_header_pickqty_so = lcl_ls_buffer_item=>gv_header_pickqty_so + ls_pditems-pickqty.
*          endif.

         CLEAR:ls_pditems-pickqty.
       endif.
******End of Sd delv no pick quantity   logic

*                  ENDLOOP.
*
*                ENDIF.
*              ENDIF.

            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.
        ENDIF.

**************start of API to fetch partner function using delivery details
*****************API to fetch SO customer details***********************
        IF lv_so IS NOT INITIAL. "exit the loop once sales order is picked
*          TRY.
*              DATA : gv_web_D TYPE string.
*              DATA : gv_web_D2 TYPE string.
*              DATA : gv_web_D3 TYPE string.
              DATA : lv_so_det_D TYPE string,
                     lv_pf       TYPE c  LENGTH 2,
                     lv_pfc      TYPE c  LENGTH 2.
*
TRY.
   SELECT SINGLE PARTNERFUNCTION, REFERENCEBUSINESSPARTNER, ADDRESSID "PARTNERFUNCTIONINTERNALCODE
     from I_SalesDocumentPartner where SalesDocument = @lv_so into @data(ls_pdata).
     if sy-subrc eq 0.
        lcl_ls_buffer_item=>gv_pf = ls_pdata-PARTNERFUNCTION.
        lv_pf = ls_pdata-PARTNERFUNCTION.

        lcl_ls_buffer_item=>gv_bp = ls_pdata-REFERENCEBUSINESSPARTNER.

*        lcl_ls_buffer_item=>gv_pfc = ls_pdata-PARTNERFUNCTIONINTERNALCODE.
*        lv_pfc = ls_pdata-PARTNERFUNCTIONINTERNALCODE.

        lcl_ls_buffer_item=>gv_AddressID = ls_pdata-ADDRESSID.
        lcl_ls_buffer_item=>gv_orgname1 = ls_pdata-ADDRESSID.
     endif.
            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.
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



          DATA : lv_cust      TYPE c LENGTH 10,
            lv_ctext_txt TYPE c LENGTH 30. "01-04


try.

 lv_cust = |{ lcl_ls_buffer_item=>gv_bp ALPHA = IN }|.
   SELECT SINGLE CUSTOMERNAME,ORGANIZATIONBPNAME1 from i_customer
    where customer = @lv_cust into @data(ls_cust).
    if sy-subrc eq 0.
      lcl_ls_buffer_item=>gv_addname1 = ls_cust-CUSTOMERNAME.
      lcl_ls_buffer_item=>gv_orgname1 = ls_cust-ORGANIZATIONBPNAME1.
    endif.

            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.
************************************ end  of customer details

**********************fetching SO partner details*******************

************************************* SO partner address details here cuz BP API not fetching cust details start

*          TRY.
              DATA : gv_web_DS TYPE string.
              DATA : gv_web_DS2 TYPE string.
              DATA : gv_web_DS3 TYPE string.
              DATA : lv_so_det_DS TYPE string,
                     lv_pf_DS     TYPE c  LENGTH 2,
                     lv_pfc_DS    TYPE c  LENGTH 2.

              FIELD-SYMBOLS :

                <fs_structure_ds>   TYPE any,
                <fs_hold_ds>        TYPE any,
                <fs_error_ds>       TYPE any,
                <fs_error_temp_ds>  TYPE any,
                <fs_error_table_ds> TYPE any,
                <fs_table_ds>       TYPE ANY TABLE,
                <fs_table_temp_ds>  TYPE ANY TABLE.
              FIELD-SYMBOLS : <ls_table_ds> TYPE any.



TRY.



   SELECT single b~customerFULLNAME, b~ORGANIZATIONbpNAME1, b~REGION from I_SalesDocumentPartner as a
   inner join I_customer as b on  a~customer = b~customer
    WHERE a~salesdocument = @lv_so and a~PartnerFunction = @lv_pf into @data(ls_adata).
    if sy-subrc eq 0.
    lcl_ls_buffer_item=>gv_addname1 = ls_adata-customerFULLNAME.
    lcl_ls_buffer_item=>gv_orgname1 = ls_adata-ORGANIZATIONbpNAME1.
    lcl_ls_buffer_item=>gv_REGION  = ls_adata-REGION.
    endif.
  CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
 ENDTRY.

**************************** end

******TRY.
******   SELECT single b~addresseefullname, b~region from I_BusPartAddress as a inner join i_address_2 as b
******       on a~AddressID = b~AddressID
******   where a~BusinessPartner = @lcl_ls_buffer_item=>gv_bp and a~AddressID = @lcl_ls_buffer_item=>gv_AddressID
******   into @data(ls_adata1).
******   if sy-subrc eq 0.
******      lcl_ls_buffer_item=>gv_addname1 = ls_adata1-addresseeFULLNAME.
******      lcl_ls_buffer_item=>gv_orgname1 = ls_adata1-REGION.
******   endif.
******
******  CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
****** ENDTRY.

  ENDIF.

**********************************************************************
* Above LOGIC WRITTEN FOR BELOW SO

*below logic used for public cloud version, uncomment the below selects and map the fields for data flow
* c       SELECT SINGLE quantity,
*                      grossweight,
*                      netweight,
*                      Orderhead "ordnum
*                     FROM  zi_sorder_data   "need to check later c
*                         WHERE sorder = @ls_item-ordnum  "c
*                               INTO @DATA(ls_data).

*c        SELECT SINGLE
*                salesorderdate,
*                soldtoparty,
*                organizationbpname1,
*                partner~fullname
*                    FROM zi_salesorder AS order
*                          LEFT OUTER JOIN zi_customer AS customer
*                              ON customer~customer = order~soldtoparty
*                                LEFT OUTER JOIN zi_salesorderpartner AS partner
*                                    ON partner~salesorder = order~salesorder
*                                    AND partner~partnerfunction = 'ZB'
*                        WHERE order~salesorder = @ls_data-ordnum
*                            INTO @DATA(ls_odata).

      ELSE.

*********Using API to fetch PO header and Item details for BTP version***start
*****************************logic to fetch Purchase order data using API *************************************
*below logic BTP API is used in place of cloud version view zi_porder_data logic
        IF ls_item-ordnum IS NOT INITIAL.

***PO Header
          FIELD-SYMBOLS : <fs_data_ph>        TYPE data,
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

***PO Header
          FIELD-SYMBOLS : <ls_table_ph> TYPE any.
          FIELD-SYMBOLS : <lv_severity_ph>   TYPE any,
                          <fs_final_data_ph> TYPE data.
          DATA: lr_data_ph TYPE REF TO data.


          DATA: lv_header_grossweight TYPE string,
                lv_header_netweight   TYPE string,
                lv_header_weightuint  TYPE  c LENGTH 3.

          DATA : gv_web_ph TYPE string.
          DATA : gv_web_ph2 TYPE string.
          DATA : gv_web_ph3 TYPE string.

          DATA: lv_POdoc           TYPE c LENGTH 10,
                lv_PO_addr_name    TYPE c LENGTH 35,
                lv_PO_cdate        TYPE datum,
                lv_po_dchan        TYPE c LENGTH 2,
                lv_po_supp         TYPE c LENGTH 10,
                lv_po_invoic_party TYPE c LENGTH 35.


TRY.
  SELECT SINGLE a~PurchaseOrder,a~PURCHASEORDERDATE,a~SUPPLIER,b~OrganizationBPName1 from I_PurchaseOrderTP_2 as a
   inner join I_supplier as b on
   a~supplier = b~supplier
  where a~purchaseorder = @ls_item-ordnum into @data(ls_po).
  if sy-subrc eq 0.
    lv_POdoc  =  ls_po-PURCHASEORDER.
    lcl_ls_buffer_item=>GV_CreationDate_po = ls_po-PURCHASEORDERDATE.

      CLEAR:lv_cdate,lv_json1,lv_json2,lv_json3,lv_json,ls_date.

      lv_json1 = '{ "Create_Date" : '.
      lv_json2 = | "{ lcl_ls_buffer_item=>GV_CreationDate_PO }" |.
      lv_json3 = '}'.
      lv_json  = |'{ lv_json1 }{ lv_json2 }{ lv_json3 }'|.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json        = lv_json             " JSON string
        CHANGING
          data        = ls_date ).          " Converted Data

      lv_PO_cdate =   ls_date-create_date." PO creation date

      CLEAR:lv_po_supp.
       lv_po_supp = ls_po-SUPPLIER.


     CLEAR:lv_po_addr_name.
     lv_po_addr_name = ls_po-OrganizationbpName1.
     lv_po_invoic_party  = ls_po-OrganizationbpName1.
  endif.

            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.

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
                          <fs_field_value_pi> TYPE data.

***PO item
          FIELD-SYMBOLS : <ls_table_pi> TYPE any.
          FIELD-SYMBOLS : <lv_severity_pi>   TYPE any,
                          <fs_final_data_pi> TYPE data.
          DATA: lr_data_pi TYPE REF TO data.

          DATA : gv_web_pi TYPE string.
          DATA : gv_web_pi2 TYPE string.
          DATA : gv_web_pi3 TYPE string.

          TYPES : BEGIN OF ty_pitems,
                    Deldoc         TYPE c LENGTH 10,
                    item           TYPE zwbi_dt_itemno,
                    plant          TYPE c LENGTH 4,
                    ordqty         TYPE zwbi_dt_quantity,
                    dchan          TYPE c LENGTH 2,
                    ItemGWeight    TYPE zwbi_dt_quantity,
                    itemqtyunit    TYPE c LENGTH 3,
                    itemweightunit TYPE c LENGTH 3,
                    ItemNWeight    TYPE  zwbi_dt_quantity,
                    Podelstatus    TYPE c LENGTH 1,
                    sloc           TYPE c LENGTH 4,
                    slocname       TYPE c LENGTH 38,

                  END OF ty_pitems.
*
          DATA : lt_pitems TYPE STANDARD TABLE OF ty_pitems,
                 ls_pitems TYPE ty_pitems.

          DATA: lv_po_ordqty      TYPE zwbi_dt_quantity,
                lv_po             TYPE c LENGTH 10,
                lv_po_ItemGWeight TYPE zwbi_dt_quantity,
                lv_po_ItemNWeight TYPE  zwbi_dt_quantity,
                lv_ITEMWEIGHTUNIT TYPE c LENGTH 3.


*****end of storage location text logic
TRY.
    SELECT Purchaseorder,PurchaseorderItem,PLANT,ORDERQUANTITY,ORDERPRICEUNIT, ITEMGROSSWEIGHT,
           ITEMNETWEIGHT,itemWeightUnit,
           ISFINALLYINVOICED,STORAGELOCATION,ISCOMPLETELYDELIVERED
           from I_PurchaseOrderItemTP_2 "I_PurchaseOrderTP_2
    where Purchaseorder = @ls_item-ordnum INto TABLE @data(lt_po).
    if sy-subrc eq 0.
      CLEAR: lv_po_ordqty,lv_po_ItemGWeight,lv_po_ItemNWeight.
      loop at lt_po into data(ls_poitemdata).

        ls_pitems-deldoc = ls_poitemdata-PURCHASEORDER.
        CLEAR: lv_po.
        lv_po = ls_pitems-deldoc.

        ls_pitems-item = ls_poitemdata-PURCHASEORDERITEM.

        CLEAR:ls_head-plant.
        ls_head-plant = ls_poitemdata-PLANT.

        ls_pitems-ordqty = ls_poitemdata-ORDERQUANTITY.
        lv_po_ordqty  = lv_po_ordqty + ls_pitems-ordqty.

        ls_pitems-itemqtyunit = ls_poitemdata-ORDERPRICEUNIT.

* Converting external to internal unit
       SELECT SINGLE UnitOfMeasure_E from I_UnitOfMeasureText
          where UnitOfMeasure = @ls_pitems-itemqtyunit
            and Language = @sy-langu into @data(lv_external_uom1).
        lcl_ls_buffer_item=>gv_uom = lv_external_uom1.

*        lcl_ls_buffer_item=>gv_uom  = ls_pitems-itemqtyunit.

        ls_pitems-ItemGWeight = ls_poitemdata-ITEMGROSSWEIGHT.
        lv_po_ItemGWeight   = lv_po_ItemGWeight + ( ls_pitems-ItemGWeight * ls_pitems-ordqty ).

        ls_pitems-ItemNWeight = ls_poitemdata-ITEMNETWEIGHT.
        lv_po_ItemNWeight = lv_po_ItemNWeight + ( ls_pitems-ItemNWeight * ls_pitems-ordqty ).

        ls_pitems-itemweightunit = ls_poitemdata-ITEMWEIGHTUNIT.

        if ls_pitems-itemweightunit is not INITIAL.   "21-05
            CLEAR:lv_ITEMWEIGHTUNIT.
            lv_ITEMWEIGHTUNIT  =  ls_pitems-itemweightunit.
        endif.

        lcl_ls_buffer_item=>gv_invoicstatus = ls_poitemdata-ISFINALLYINVOICED.
        CONDENSE lcl_ls_buffer_item=>gv_invoicstatus.

        IF lcl_ls_buffer_item=>gv_invoicstatus IS INITIAL.
           lcl_ls_buffer_item=>gv_invoicstatus = 'Not yet processed'.
        ELSE.
           lcl_ls_buffer_item=>gv_invoicstatus = 'Fully Invoiced'.
        ENDIF.
        CONDENSE lcl_ls_buffer_item=>gv_invoicstatus.

        ls_pitems-sloc = ls_poitemdata-STORAGELOCATION.
        ls_pitems-Podelstatus = ls_poitemdata-ISCOMPLETELYDELIVERED.



*        ****start of Storage location text logic

        READ TABLE lt_sloc INTO ls_sloc WITH KEY sloc = ls_pitems-sloc.

        IF sy-subrc EQ 0.

         lcl_ls_buffer_item=>GV_sloc  = ls_pitems-sloc.

          CONCATENATE ls_pitems-sloc  ' (' ls_sloc-slocname ')' INTO lcl_ls_buffer_item=>GV_sloctext." SEPARATED BY space.
        CONDENSE lcl_ls_buffer_item=>GV_sloctext.

        ls_pitems-slocname = lcl_ls_buffer_item=>GV_sloctext.

        ENDIF.

        APPEND ls_pitems TO lt_pitems.
        CLEAR:ls_pitems.

*****end of storage location text logic
      endloop.
    endif.

            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.

*                  ENDLOOP.

**** start  of PO history logic and same logic exist in method getpickqtyupdate for Refresh button action sync the logic if required

***SO item
                  FIELD-SYMBOLS:
                    <fs_data_dist_h>        TYPE data,
                    <fs_results_dist_h>     TYPE any,
                    <fs_structure_dist_h>   TYPE any,
                    <fs_hold_dist_h>        TYPE any,
                    <fs_error_dist_h>       TYPE any,
                    <fs_error_temp_dist_h>  TYPE any,
                    <fs_error_table_dist_h> TYPE any,
                    <fs_table_dist_h>       TYPE ANY TABLE,
                    <fs_table_temp_dist_h>  TYPE ANY TABLE,
                    <fs_field_dist_h>       TYPE any,
                    <fs_field_value_dist_h> TYPE data.


                  DATA: lr_data_dist_h TYPE REF TO data.


                  FIELD-SYMBOLS : <ls_table_dist_h> TYPE any.
                  FIELD-SYMBOLS : <lv_severity_dist_h>   TYPE any,
                                  <fs_final_data_dist_h> TYPE data.

****
                  DATA : gv_web_dist_h TYPE string.
                  DATA : gv_web_dist2_h TYPE string.
                  DATA : gv_web_dist3_h TYPE string.
                  DATA: lv_so_det_dist_h TYPE string.



                  TYPES : BEGIN OF ty_PO_h,
                            Purorder            TYPE c LENGTH 10,
                            item                TYPE zwbi_dt_itemno,
                            delqty              TYPE zwbi_dt_quantity,
                            orderqty            TYPE zwbi_dt_quantity,
                            totaldelqty         TYPE zwbi_dt_quantity,
                            totalinvqty         TYPE zwbi_dt_quantity,
                            debitcredit         TYPE c LENGTH 1,
                            iscompletedelv      TYPE c LENGTH 1,
                            pocompletedelv      TYPE c LENGTH 1,
                            finalpocompletedelv TYPE c LENGTH 1,
                            finalinvoicestatus  TYPE c LENGTH 1,
                            purhiscatg          TYPE c LENGTH 1,
                            movetyp             TYPE c LENGTH  3,


                          END OF ty_PO_h.
*
                  DATA : lt_po_h          TYPE STANDARD TABLE OF ty_po_h,
                         lt_po_out_h      TYPE STANDARD TABLE OF ty_po_h,
                         lt_po_out_h_I    TYPE STANDARD TABLE OF ty_po_h,
                         lt_po_result_h   TYPE STANDARD TABLE OF ty_po_h,
                         lt_po_result_h_i TYPE STANDARD TABLE OF ty_po_h,
                         ls_po_h          TYPE ty_po_h,
                         ls_po_out_h      TYPE ty_po_h,
                         lv_totaldelqty   TYPE zwbi_dt_quantity,
                         lv_Invqty        TYPE zwbi_dt_quantity,
                         lv_delqty        TYPE zwbi_dt_quantity,
                         lv_stilltodelqty TYPE zwbi_dt_quantity,
                         lv_ordqty        TYPE zwbi_dt_quantity,
                         lv_po_h          TYPE c LENGTH 30. "01-04




try.
SELECT PURCHASEORDER, PURCHASEORDERITEM, QUANTITY,GOODSMOVEMENTTYPE,ISCOMPLETELYDELIVERED,
       DEBITCREDITCODE, PURCHASINGHISTORYCATEGORY from I_PurchaseOrderHistoryAPI01
where purchaseorder = @lv_po into table @data(lt_pohist).
if sy-subrc eq 0.
loop at lt_pohist into data(ls_pohist).
ls_po_h-Purorder =      ls_pohist-PURCHASEORDER.
ls_po_h-item = ls_pohist-PURCHASEORDERITEM.
ls_po_h-delqty = ls_pohist-QUANTITY.
ls_po_h-movetyp = ls_pohist-GOODSMOVEMENTTYPE.
ls_po_h-iscompletedelv = ls_pohist-ISCOMPLETELYDELIVERED.
ls_po_h-debitcredit = ls_pohist-DEBITCREDITCODE.
ls_po_h-purhiscatg = ls_pohist-PURCHASINGHISTORYCATEGORY.

READ TABLE lt_pitems INTO ls_pitems WITH KEY Deldoc = ls_po_h-purorder  item = ls_po_h-item. "  getting order qty and delivery status

IF sy-subrc EQ 0.
 ls_po_h-orderqty  = ls_pitems-ordqty.
IF ls_po_h-delqty LT ls_po_h-orderqty.
   ls_po_h-pocompletedelv = 'P'. " Partially deliveried status
ELSEIF ls_po_h-delqty EQ ls_po_h-orderqty.
   ls_po_h-pocompletedelv = 'F'.   " Fully delivered status
ELSEIF ls_po_h-delqty IS INITIAL.
  ls_po_h-pocompletedelv = 'N'.  " not delivery status
ENDIF.

ELSE.
  ls_po_h-pocompletedelv = 'N'.  " not delivery status
ENDIF.

 APPEND ls_po_h TO lt_po_h.
 CLEAR:ls_po_h,ls_pitems.
endloop.
endif.

                  lt_po_out_h[] = lt_po_h[].

            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
          ENDTRY.

*****************new

data: lv_revDelveredqty_h  TYPE zwbi_dt_quantity,
      lv_Delveredqty_s     TYPE zwbi_dt_quantity,
      lv_revinvoicedqty_h       TYPE zwbi_dt_quantity,
      lv_postedinvoicedqty_s       TYPE zwbi_dt_quantity,
       lv_Delveredqty     TYPE zwbi_dt_quantity,  "delivered qty
       lv_invoicedqty     TYPE zwbi_dt_quantity,
       lv_Totorderqty     TYPE zwbi_dt_quantity.  "ordered qty


clear:lv_revDelveredqty_h, lv_Delveredqty_s,lv_revinvoicedqty_h,lv_postedinvoicedqty_s,lv_Totorderqty.
SORT lt_po_h BY Purorder item. " debitcredit purhiscatg.
              LOOP AT lt_po_h INTO ls_po_h.

* DATA(ls_po_out_h2) = ls_po_h.

 if ls_po_h-debitcredit = 'H' and ls_po_h-purhiscatg = 'E'.
    lv_revDelveredqty_h   = ls_po_h-delqty + lv_revDelveredqty_h.
 elseif ls_po_h-debitcredit = 'S' and ls_po_h-purhiscatg = 'E'.
    lv_Delveredqty_s    =  ls_po_h-delqty + lv_Delveredqty_s.
 elseif ls_po_h-debitcredit = 'H' and ls_po_h-purhiscatg = 'Q'.
    lv_revinvoicedqty_h   =  ls_po_h-delqty +  lv_revinvoicedqty_h.
 elseif ls_po_h-debitcredit = 'S' and ls_po_h-purhiscatg = 'Q'.
    lv_postedinvoicedqty_s   =   ls_po_h-delqty + lv_postedinvoicedqty_s.
 endif.

endloop.

 lv_Totorderqty  = lv_po_ordqty.  " order qty
 lv_Delveredqty =    lv_Delveredqty_s - lv_revDelveredqty_h. "total delvd qty

 lv_invoicedqty  =  lv_postedinvoicedqty_s - lv_revinvoicedqty_h.

  lcl_ls_buffer_item=>gv_delquantity_po  = lv_Delveredqty . "23-05 "PO delivered qty
  lcl_ls_buffer_item=>gv_invquantity_po = lv_invoicedqty. "23-05  PO invoiced qty
  lcl_ls_buffer_item=>gv_stilltodelquantity_po  = lv_Totorderqty - lv_Delveredqty." 23-05 PO still to delivery qty
  CONDENSE lcl_ls_buffer_item=>gv_stilltodelquantity_po. "22-05.
*Delivery status logic
       IF lv_Delveredqty LT lv_Totorderqty and lv_Delveredqty is not INITIAL.
          lcl_ls_buffer_item=>GV_PodelvStatus =    'Partially Delivered'. " Partially deliveried status
       ELSEIF lv_Delveredqty EQ lv_Totorderqty.
*    ls_po_out_h1-finalpocompletedelv =  'F'.   " Fully delivered status
          lcl_ls_buffer_item=>GV_PodelvStatus =  'Fully Delivered'.
       ELSEIF lv_Delveredqty IS INITIAL.
          lcl_ls_buffer_item=>GV_PodelvStatus =  'Not Delivered'. " not delivery status
      ENDIF.

*Invoice status logic
      IF lv_invoicedqty LT lv_Totorderqty and lv_invoicedqty is not INITIAL.
         lcl_ls_buffer_item=>gv_invoicstatus =    'Partially Invoiced'.
      ELSEIF lv_invoicedqty EQ lv_Totorderqty.
          lcl_ls_buffer_item=>gv_invoicstatus =  'Fully Invoiced'.
      ELSEIF lv_invoicedqty IS INITIAL.
         lcl_ls_buffer_item=>gv_invoicstatus =  'Not Invoiced'.
      endif.
****************end
*"PO total qty, grossweight and netweight of all items***start
                  CLEAR:
                  lcl_ls_buffer_item=>gv_header_qty_so,
                  lcl_ls_buffer_item=>gv_header_grossweight_so,
                  lcl_ls_buffer_item=>gv_header_netweight_so,
                  lcl_ls_buffer_item=>gv_orgname1,
                  lcl_ls_buffer_item=>GV_SoldToParty_SO,lv_cdate,
                  lcl_ls_buffer_item=>gv_header_pickqty_so.
                  lcl_ls_buffer_item=>gv_header_qty_so =  lv_po_ordqty. " Po order qty
                  lcl_ls_buffer_item=>gv_header_grossweight_so =  lv_po_ItemGWeight.
                  lcl_ls_buffer_item=>gv_header_netweight_so = lv_po_ItemNWeight.
                  lcl_ls_buffer_item=>gv_item_uom  = lv_ITEMWEIGHTUNIT .
                  lcl_ls_buffer_item=>gv_addname1  = lv_po_addr_name.
                  lv_cdate = lv_PO_cdate.
                  lcl_ls_buffer_item=>GV_SoldToParty_SO = lv_po_supp. "PO supplier
                  lcl_ls_buffer_item=>gv_orgname1 = lv_po_invoic_party.

                  CLEAR: lv_po_ordqty,lv_po_ItemGWeight,lv_po_ItemNWeight.
                  clear: lv_Delveredqty_s, lv_revDelveredqty_h.

                ENDIF.
              ENDIF.

*            CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
*          ENDTRY.

        ENDIF.

********************************************************end

*      need to write below PO select logic to API
*below logic used for public cloud version, uncomment the below selects and map the fields for data flow
* c       SELECT SINGLE
*              purchaseorderdate,
*              order~supplier,
*              organizationbpname1
*                  FROM zi_purchaseorderapi01 AS order
*                        INNER JOIN zi_supplier AS supplier
*                                ON supplier~supplier = order~supplier
*                      WHERE purchaseorder = @ls_item-ordnum
*                          INTO @ls_odata.
*
* "c        SELECT SINGLE quantity,
*                      grossweight,
*                      netweight
*                    FROM zi_porder_data
*                          WHERE porder = @ls_item-ordnum
*                              INTO @ls_data.


*      ENDIF.
*******plant text logic updating to item 10-04
      CLEAR:ls_dplant.
      READ TABLE lt_dplant INTO ls_dplant WITH KEY plant = ls_head-plant.
      IF sy-subrc EQ 0.

        CONCATENATE ls_head-plant  ' (' ls_dplant-plantname ')' INTO ls_head-planttext." SEPARATED BY space.
        CONDENSE ls_head-planttext.
      ENDIF.

*******plant text logic updating to item 10-04

*Item data updating

      MODIFY ENTITIES OF zwbi_i_vehin_head  IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
             ENTITY item
                 UPDATE SET FIELDS WITH VALUE  #(
                         FOR it IN items (
                             %key = it-%key
                             %tky = it-%tky  "01-06
                             %is_draft = it-%is_draft
                             orderdate = lv_cdate  "lcl_ls_buffer_item=>GV_CreationDate_SO "ls_odata-salesorderdate "c
                             bpcode    = lcl_ls_buffer_item=>GV_SoldToParty_SO  "ls_odata-soldtoparty      "c
                             bpname    = lcl_ls_buffer_item=>gv_orgname1 " ls_odata-organizationbpname1    "c
                             brokername = lcl_ls_buffer_item=>gv_addname1  "ls_odata-fullname    "c
                             quantity =  lcl_ls_buffer_item=>gv_header_qty_so "ls_data-quantity      "c
                             grossweight = lcl_ls_buffer_item=>gv_header_grossweight_so "ls_data-grossweight
                             netweight = lcl_ls_buffer_item=>gv_header_netweight_so "ls_data-netweight
                             dchannel = ls_head-dchannel
                             plant = ls_head-plant
                             Planttext = ls_head-Planttext    "10-04 plant text
                             unit = lcl_ls_buffer_item=>gv_uom    "qty uom  PC
                             itemunit  = lcl_ls_buffer_item=>gv_item_uom   "06-07
                             Pickquantity = lcl_ls_buffer_item=>gv_header_pickqty_so
                             overalldbstatus   =     lcl_ls_buffer_item=>GV_OverallDBStatus
                             overallgoodsmovstatus = lcl_ls_buffer_item=>GV_OverallGoodsMovStatus
                             overallpackstatus    =  lcl_ls_buffer_item=>GV_OverallPackStatus
                             overallpickconfstatus = lcl_ls_buffer_item=>GV_OverallPickConfStatus
                             overallpickstatus  =    lcl_ls_buffer_item=>GV_OverallPickStatus
                             Shippoint          = lcl_ls_buffer_item=>GV_shippoint
                             Shipptext         = lcl_ls_buffer_item=>gv_shiptext
                             Podelvstatus      = lcl_ls_buffer_item=>GV_PodelvStatus   " PO delivery status
                             Sloc              = lcl_ls_buffer_item=>GV_sloc
                             Sloctext          =  lcl_ls_buffer_item=>GV_sloctext
                             Isfinallyinvoiced = lcl_ls_buffer_item=>gv_invoicstatus     "PO invoice status
                             Delquantity       =   lcl_ls_buffer_item=>gv_delquantity_po   "PO delivered qty
                             Invquantity       = lcl_ls_buffer_item=>gv_invquantity_po  "  PO invoiced qty
                             Stilltodelquantity  =    lcl_ls_buffer_item=>gv_stilltodelquantity_po "  PO still to delivery qty
*****                             Delqty              =  lcl_ls_buffer_item=>gv_delquantity_po  " "PO delivered qty  testing
*                             %control-Delquantity = if_abap_behv=>mk-on
*                                  %control-Delquantity = if_abap_behv=>mk-off


                        "     %control = value (  )
                         )
                 ) REPORTED modifyreported.
      reported = CORRESPONDING #( DEEP modifyreported ).

*if lcl_ls_buffer_item=>gv_delquantity_po is INITIAL or lcl_ls_buffer_item=>gv_delquantity_po = 0 or lcl_ls_buffer_item=>gv_invquantity_po = 0 or lcl_ls_buffer_item=>gv_invquantity_po is INITIAL
* or lcl_ls_buffer_item=>gv_stilltodelquantity_po = 0 or lcl_ls_buffer_item=>gv_stilltodelquantity_po is not INITIAL. "22-05
***logic to update zero quantity or values into custom table  with update only zero value getting updated but not with Modify
**this logic is not needed in setinwardtype
*
*READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE   c
*        ENTITY item
*            ALL FIELDS WITH CORRESPONDING #( keys )
*                RESULT DATA(items1).
*
*    TRY.
*        DATA(ls_items1) = items1[ 1 ].
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.

*              update zwbi_vi_id  SET "inward_uuid = @ls_items1-Inward_uuid,
*                                            "item_uuid = @ls_items1-Item_Uuid,
*                                              Delquantity  = @lv_decimal. "@lcl_ls_buffer_item=>gv_delquantity_po
**                                              where item_uuid = @ls_items1-Item_Uuid and inward_uuid = @ls_items1-Inward_uuid.
***                                              Invquantity  = @lcl_ls_buffer_item=>gv_invquantity_po,
***                                              Stilltodelquantity  =    @lcl_ls_buffer_item=>gv_stilltodelquantity_po .
**endif.

*    ENDIF.
  ENDMETHOD.

  METHOD validateorder."triggers at the time of creation and save

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE   c
        ENTITY item
            ALL FIELDS WITH CORRESPONDING #( keys )
                RESULT DATA(items).

    TRY.
    sort items[] by ordnum."1/5/2025 "sorting to get empty reference number first to capture error
        DATA(ls_item) = items[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    IF ls_item-ordnum IS INITIAL.
      APPEND VALUE #(
               %tky = ls_item-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-error
               text     = |{ TEXT-001 }|
            )

            ) TO reported-item.
      APPEND VALUE #( %tky = ls_item-%tky ) TO  failed-item.
      lcl_ls_buffer_item=>gv_error_flag = 'X'. " flag to handle error while creation
    ENDIF.


  ENDMETHOD.

  METHOD get_instance_features.

*****this logic is to make reference order field as read only mode when net weight and gross weight captured.
    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE   c
        ENTITY item
            ALL FIELDS WITH CORRESPONDING #( keys )
                RESULT DATA(items).
TRY.
        DATA(ls_item) = items[ 1 ].
        data(ls_items_d) = items[].  "12/12
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.


   READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE   c
            ENTITY item BY \_head
                ALL FIELDS WITH CORRESPONDING #( keys )
                    RESULT DATA(heads)
                    LINK   DATA(link)
*                    FAILED DATA(failed)
                    REPORTED DATA(reported1).

    TRY.
        DATA(ls_head) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.



* LOOP AT items INTO DATA(ls_data).

*LOOP AT keys INTO DATA(ls_keys).
*
*      IF ls_keys-%is_draft EQ '01'.
*        DATA(lv_draft)  = abap_true.
*      ELSE.
*        lv_draft = abap_false.
*      ENDIF.
*      " End of Insert by
*    ENDLOOP.



if ls_head-pwoempwg is not INITIAL and ls_head-pwiempwg is not INITIAL." old  31-05
result = value #( For ls_items IN items   "old 31-05
                   ( %tky   = ls_items-%tky
                    %field-Ordnum                 = if_abap_behv=>fc-f-read_only )


  ) .


 endif.



 result = value #( For ls_items IN items  "31-05 new
                   ( %tky   = keys[ 1 ]-%tky"ls_items-%tky
               %action-getPickQtyUpdate =  COND #( when ls_items-%tky-%is_draft = '01'   "01 = edit
                               Then  if_abap_behv=>fc-o-disabled
                          ELSE if_abap_behv=>fc-o-enabled ) ) ).

LOOP AT ls_items_d INTO DATA(ls_item_d). "start 20-03-2025 logic to enable delete button in edit mode only.
*  result = VALUE #( FOR ls_items IN items  "20-03-2025 logic to enable delete button in edit mode only.
*                      ( %tky   = keys[ 1 ]-%tky"ls_items-%tky
*                  %action-getItemDelete =  COND #( WHEN ls_item_d-%tky-%is_draft = '00'   "01 = edit
*                                  THEN  if_abap_behv=>fc-o-disabled
*                             ELSE if_abap_behv=>fc-o-enabled ) ) ).


     APPEND VALUE #( %tky = ls_item_d-%tky  "old 21-05
                          %action-getItemDelete = COND #( WHEN ls_item_d-%tky-%is_draft = '00'   "01 = edit
                                  THEN  if_abap_behv=>fc-o-disabled
                             ELSE if_abap_behv=>fc-o-enabled ) )
         TO result.



endloop. "end 20-03-2025

*  SELECT SINGLE  *
*                       FROM zwbi_vin_i
*                       WHERE item_uuid = @ls_item-item_uuid and
*                             inward_uuid = @ls_item-inward_uuid
*                       INTO @DATA(ls_item_val).
*if sy-subrc eq 0.
*result = value #( For ls_items IN items
*                   ( %tky   = ls_items-%tky
*                     %action-getPickQtyUpdate =  COND #( when ls_items-%tky-%is_draft = '01'  "01 =  edit mode
*                               Then  if_abap_behv=>fc-o-disabled
*                     ELSE if_abap_behv=>fc-o-enabled ) ) ).


*                       %action-getPickQtyUpdate = COND #( WHEN ( ls_data-pwigetwg = 'C' OR ls_data-pwogetwg = 'C' OR ls_data-pwexit = 'C' )
*                            THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
*endif.

*****
*  endloop.
*
*below result logic is commented in orginal program so no need of writting logic for now
*    result = VALUE #( FOR ls_data IN lt_context_data
*                        LET lv_active   = COND #( WHEN ( ls_data-ticknum IS NOT INITIAL AND ( ls_data-type = 'BULK' OR ls_data-type = 'PO') )
*                                                        OR ( ls_data-pwigetwg = 'C' OR ls_data-pwogetwg = 'C' OR ls_data-pwexit = 'C' )
*                            THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled  )
*                        IN ( %tky                         = ls_data-%tky
*                             %assoc-_item                 = lv_active
*                             %update                      = lv_active
*                     )
*                     ).


*    LOOP AT items INTO DATA(ls_data).
*  APPEND VALUE #( %tky = ls_data-%tky
*
*
*    " Field control information
**               %field-field1                 = if_abap_behv=>fc-f-readonly
**               %field-field2                 = if_abap_behv=>fc-f-mandatory
*
*
*
*" ls_data-Plant IS INITIAL OR ls_data-Intype is INITIAL
*
*                   %action-getPickQtyUpdate = COND #( WHEN ( ls_data-Ordnum is INITIAL   )
*                                                         THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
*
*      )
*      TO result.
*
*endloop.




  ENDMETHOD.

  METHOD calctotalweight.
    DATA: lv_grwg    TYPE p DECIMALS 3,
          lv_ntwg    TYPE p DECIMALS 3,
          lv_headuom TYPE msehi,

          lv_grwg_c  TYPE c LENGTH 16,
          lv_ntwg_c  TYPE c LENGTH 16.

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE ENTITY  "zi_vehin_head IN LOCAL MODE ENTITY "c
          head ALL FIELDS WITH CORRESPONDING #( keys )
              RESULT DATA(heads).

    TRY.
        DATA(ls_head) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE c
        ENTITY head BY \_item
            ALL FIELDS WITH VALUE #( ( %tky = ls_head-%tky ) )
                RESULT DATA(allitems).

    sort allitems[] by ordnum."1/5/2025
    CLEAR:lv_headuom.
    LOOP AT allitems INTO DATA(ls_allitem).


      lv_grwg = lv_grwg + ls_allitem-grossweight.
      lv_ntwg = lv_ntwg + ls_allitem-netweight.
      lv_headuom = ls_allitem-Itemunit. " line item unit updating to header

      IF ls_allitem-ordnum IS INITIAL.
        lcl_ls_buffer_item=>gv_error_flag = 'X'. " flag to handle error while creation
      ENDIF.

*validation on same order number, plant , driver name and driver number  combination
      IF ls_allitem-ordnum IS NOT INITIAL AND lcl_ls_buffer_item=>gv_msg_flag3 NE 'X'.   "new 16-04
* IF ls_allitem-ordnum IS not INITIAL.

        SELECT SINGLE inward_uuid,
                      inwarditem,
                      ordnum
                       FROM    zwbi_vin_i
                       WHERE  ordnum =  @ls_allitem-ordnum
                       INTO @DATA(ls_item_val).

        SELECT SINGLE  drivname,
                       drivnum,
                       plant
                       FROM zwbi_vinh
                       WHERE inward_uuid = @ls_item_val-inward_uuid
                       INTO @DATA(ls_head_val).

        IF ls_item_val-ordnum = ls_allitem-ordnum AND ls_head_val-drivname = ls_head-Drivname "warning message creating wt ticket with same header inputs
            AND ls_head_val-drivnum = ls_head-Drivnum AND ls_head_val-plant+0(4) = ls_head-Plant+0(4).

          lcl_ls_buffer_item=>gv_msg_flag = 'X'.

        ENDIF.
        CLEAR:ls_head_val, ls_item_val.
*************
        elseif ls_allitem-ordnum IS INITIAL.

        APPEND VALUE #(
                    %tky = ls_allitem-%tky
                    %msg = new_message_with_text(
                    severity = if_abap_behv_message=>severity-information "this should be only information then only message working properly
                    text     = |{ TEXT-005 }|
                 )

                 ) TO reported-item.

*       select single * from /n4c03/wbi_vi_id where  item_uuid =   @ls_allitem-Item_Uuid and
*                                          inward_uuid = @ls_allitem-Inward_uuid and
*                                          inwarditem =  @ls_allitem-Inwarditem
*      into @data(lt_itemorders_id) .
*      if sy-subrc eq 0.
*      delete /n4c03/wbi_vi_id from @lt_itemorders_id. "where  item_uuid =   @ls_items-Item_Uuid and
**                                          inward_uuid = @ls_items-Inward_uuid and
**                                          inwarditem =  @ls_items-Inwarditem.

*     endif.
**********


      ENDIF.
*******Validation logic ends
    ENDLOOP.


    lv_grwg_c  = lv_grwg.    "01-04
    CONDENSE lv_grwg_c NO-GAPS.
    lv_ntwg_c = lv_ntwg.
    CONDENSE lv_ntwg_c NO-GAPS.

**************start of 09-04 disable setoutward button logic for partially pick qty

    DATA: lv_delvstatus  TYPE c LENGTH 1.
    LOOP AT allitems INTO DATA(ls_itemsp1).
      IF ls_itemsp1-Intype = 'S'.
        CONDENSE ls_itemsp1-overalldbstatus.  "Overallpickstatus. " considering Invoice status for outward button enable
        IF ls_itemsp1-overalldbstatus+0(1) NE 'C'.
          lv_delvstatus = 'P'.
          EXIT.
        ELSE.
          lv_delvstatus = 'C'.   "outward is consider for Partial and Fully delivered status in SO
        ENDIF.
      ELSEIF  ls_itemsp1-Intype = 'P'.

        CONDENSE ls_itemsp1-Podelvstatus.  "considering Delivery status for outward button logic enable
*        IF ls_itemsp1-Podelvstatus+0(1) NE 'F'.
 IF ls_itemsp1-Podelvstatus+0(1) Eq 'N'. "Not delivered
          lv_delvstatus = 'P'.
          EXIT.
        ELSE.
          lv_delvstatus = 'C'.   "outward is consider for Partial and Fully delivered status in PO "(Partially delivered or Fully delivered)
        ENDIF.


      ENDIF.
      CLEAR:ls_itemsp1.
    ENDLOOP.

*************end of

*Netweight and Grossweight's  are updating to screen from given line item.
    MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE   c
          ENTITY head
              UPDATE SET FIELDS WITH VALUE #(
                            FOR head IN heads (
                                %key = head-%key
                                %is_draft = head-%is_draft
                                Itemunit  = lv_headuom   " UOM updating to header"
                               grossweight = lv_grwg_c
                               netweight = lv_ntwg_c
                                grossweight_f = lv_grwg_c  "25/10/2025
                               netweight_f = lv_ntwg_c    "25/10/2025
                               Pwiuom_f  =   lv_headuom   "25/10/2025    " UOM updating to header"
                               hdevlstatus = lv_delvstatus  "  disable setoutward button logic
*                               eflag    = lcl_ls_buffer_item=>gv_msg_flag
                              )

                    ) REPORTED DATA(modifyreported).
    reported = CORRESPONDING #( DEEP modifyreported ).


*if lcl_ls_buffer_item=>gv_msg_flag = 'X' and lcl_ls_buffer_item=>gv_msg_flag3 ne 'X'. "new validation on same order number, plant , driver name and driver number  combination

    IF lcl_ls_buffer_item=>gv_msg_flag = 'X' . "old 16-04
      APPEND VALUE #(
                    %tky = ls_allitem-%tky
                    %msg = new_message_with_text(
                    severity = if_abap_behv_message=>severity-information "this should be information only then only message working properly
                    text     = |{ TEXT-003 }|
                 )

                 ) TO reported-item.

      CLEAR:lcl_ls_buffer_item=>gv_msg_flag.
    ENDIF.

    "weight ticket creation success message logic
    IF lcl_ls_buffer_item=>gv_error_flag NE 'X'.
      CLEAR:lcl_ls_buffer_item=>gv_error_flag.
      APPEND VALUE #(
                    %tky = ls_allitem-%tky
                    %msg = new_message_with_text(
                    severity = if_abap_behv_message=>severity-success
                    text     = |{ TEXT-002 }|
                 )

                 ) TO reported-item.
*Return.

    ENDIF.

  ENDMETHOD.

METHOD getItemDelete.

 READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE c
        ENTITY item
            ALL FIELDS WITH CORRESPONDING #( keys )
                RESULT DATA(itemss).

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE   c
            ENTITY item BY \_head
                ALL FIELDS WITH CORRESPONDING #( keys )
                    RESULT DATA(heads)
                    LINK   DATA(links)
                    FAILED DATA(faileds)
                    REPORTED DATA(reporteds).

    TRY.
        DATA(ls_head) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        DATA(ls_items) = itemss[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

"loop at itemss INTO data(ls_items_delete).

IF ls_head-pwoempwg IS INITIAL and ls_head-pwiempwg IS INITIAL." new  12-12

ls_head-Grossweight = ls_head-Grossweight - ls_items-GrossWeight. " after deletion line items weights getting updated logic
ls_head-Netweight = ls_head-Netweight - ls_items-NetWeight.

ls_head-Grossweight_f = ls_head-Grossweight_f - ls_items-GrossWeight. " after deletion line items weights getting updated logic
ls_head-Netweight_f = ls_head-Netweight_f - ls_items-NetWeight.


*note: data need to be deleted from both item and draft table while deleting line items.

"data: lt_itemorder type table of /n4c03/wbi_vin_i.

    " Get the SalesOrder based on the key passed
*Item table table data deletion
    select * from zwbi_vin_i where  item_uuid =   @ls_items-Item_Uuid and
                                          inward_uuid = @ls_items-Inward_uuid and
                                          inwarditem =  @ls_items-Inwarditem
      into table @data(lt_itemorders) .

*       DATA(ls_itemorders) = lt_itemorders[ 1 ].
*Draft table data deletion
*if lt_itemorders[] is INITIAL. "n
    select * from zwbi_vi_id where  item_uuid =   @ls_items-Item_Uuid and
                                          inward_uuid = @ls_items-Inward_uuid and
                                          inwarditem =  @ls_items-Inwarditem
      into table @data(lt_itemorders_d) .
*endif. "n
*Item table table data deletion
if lt_itemorders[] is not INITIAL.
       DATA(ls_itemorders) = lt_itemorders[ 1 ].
endif.

    " If the order exists, delete it
    if lines( lt_itemorders ) > 0.
     delete zwbi_vin_i from @ls_itemorders. "where  item_uuid =   @ls_items-Item_Uuid and
*                                          inward_uuid = @ls_items-Inward_uuid and
*                                          inwarditem =  @ls_items-Inwarditem.


"    else.
"      raise exception type cl_abap_behavior_saver_failed.
    endif.
*Draft table data deletion
if lt_itemorders_d[] is not INITIAL.
       DATA(ls_itemorders_d) = lt_itemorders_d[ 1 ].
endif.
    " If the order exists, delete it
    if lines( lt_itemorders_d ) > 0.
     delete zwbi_vi_id from @ls_itemorders_d. "where  item_uuid =   @ls_items-Item_Uuid and
*                                          inward_uuid = @ls_items-Inward_uuid and
*                                          inwarditem =  @ls_items-Inwarditem.


"    else.
"      raise exception type cl_abap_behavior_saver_failed.
    endif.
"    clear:ls_items_delete.
"endloop.
"    clear:ls_items_delete.
"endloop.

 MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE
           ENTITY head
               UPDATE
                   FROM VALUE #( FOR head IN heads INDEX INTO i    (

                       %tky  = head-%tky
                       ticknum = ls_head-Ticknum
                       grossweight = ls_head-grossweight
                       netweight = ls_head-netweight
                       grossweight_f = ls_head-Grossweight_f
                       netweight_f = ls_head-netweight_f
                       %control-ticknum = if_abap_behv=>mk-on
                      " %control-range = if_abap_behv=>mk-on
                       %control-grossweight = if_abap_behv=>mk-on
                       %control-netweight = if_abap_behv=>mk-on
                        %control-grossweight_f = if_abap_behv=>mk-on  "25/10/2-24
                       %control-netweight_f = if_abap_behv=>mk-on  "25/10/2-24
                   )  )
         REPORTED DATA(update_reported).

else.

APPEND VALUE #(
               %tky = ls_items-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-error
               text     = |{ TEXT-004 }|
            )

            ) TO reported-item.
      APPEND VALUE #( %tky = ls_items-%tky ) TO  failed-item.

endif.

  ENDMETHOD.

  METHOD getPickQtyUpdate. "01-04 "refresh button logic to get update pick qty @ item level to screen and table

    DATA:" lv_cnt          TYPE i,
             lv_public_cloud TYPE c LENGTH 1. " VALUE 'X'.

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

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE c
        ENTITY item
            ALL FIELDS WITH CORRESPONDING #( keys )
                RESULT DATA(itemss).

    READ ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE "zi_vehin_head IN LOCAL MODE   c
            ENTITY item BY \_head
                ALL FIELDS WITH CORRESPONDING #( keys )
                    RESULT DATA(heads)
                    LINK   DATA(links)
                    FAILED DATA(faileds)
                    REPORTED DATA(reporteds).

    TRY.
        DATA(ls_head) = heads[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        DATA(ls_items) = itemss[ 1 ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

*LOOP AT itemss INTO DATA(ls_itemtemp).
*
*
*
*    ENDLOOP.
    lcl_ls_buffer_item=>gv_msg_flag3 = 'X'. " to control  duplicate data warning message on refresh 16-04

    IF ls_items-ordnum IS NOT INITIAL AND ls_items-intype = 'S'.


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

***Start of Timestamp to Date conversion declarations*****
      TYPES : BEGIN OF ty_data,
*                    order_no     TYPE char10,
                create_date TYPE datum, "timestamp,  " <<<<<<<<< This is the Trick
              END OF ty_data.

      DATA: lv_json1                    TYPE string,
            lv_json2                    TYPE string,
            lv_json3                    TYPE string,
            lv_cdate                    TYPE datum,
            LV_OverallDBStatus_SO       TYPE c LENGTH 1,
            LV_OverallGoodsMovStatus_SO TYPE c LENGTH 1,
            LV_OverallPackStatus        TYPE c LENGTH 1,
            LV_OverallPickConfStatus    TYPE c LENGTH 1,
            LV_OverallPickStatus        TYPE c LENGTH 1.

      DATA: ls_date TYPE ty_data,
            lv_json TYPE /ui2/cl_json=>json.
******end of Timestamp declartions**********************

      DATA : gv_web_Dh  TYPE string.
      DATA : gv_web_Dh2 TYPE string.
      DATA : gv_web_Dh3 TYPE string.
      DATA lv_so_det_Dh TYPE string.


      CLEAR:lv_json1,
            lv_json2,
            lv_json3,
            lv_cdate,
            LV_OverallDBStatus_SO,
            LV_OverallGoodsMovStatus_SO,
            LV_OverallPackStatus,
            LV_OverallPickConfStatus,
            LV_OverallPickStatus,gv_web_Dh,
             gv_web_Dh2,
              gv_web_Dh3,
             lv_so_det_Dh.


try.
  SELECT SINGLE OVERALLDELIVRELTDBILLGSTATUS,OVERALLGOODSMOVEMENTSTATUS,OVERALLPACKINGSTATUS,
         OVERALLPICKINGCONFSTATUS,OVERALLPICKINGSTATUS from I_DeliveryDocument
  where DeliveryDocument = @ls_items-ordnum into @data(ls_deldata).
  if sy-subrc eq 0.
              lcl_ls_buffer_item=>GV_OverallDBStatus =  ls_deldata-OVERALLDELIVRELTDBILLGSTATUS.
              CLEAR:lcl_ls_buffer_item=>GV_OverallDBStatus.
*              CONDENSE <fs_field_value_dh>->* NO-GAPS.
              IF ls_deldata-OVERALLDELIVRELTDBILLGSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallDBStatus = 'Not Relevant'.
              ELSEIF ls_deldata-OVERALLDELIVRELTDBILLGSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallDBStatus = 'Not yet processed'.
              ELSEIF ls_deldata-OVERALLDELIVRELTDBILLGSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallDBStatus = 'Partially processed'.
              ELSEIF ls_deldata-OVERALLDELIVRELTDBILLGSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallDBStatus = 'Completely processed'.
              ENDIF.

              lcl_ls_buffer_item=>GV_OverallGoodsMovStatus =  ls_deldata-OVERALLGOODSMOVEMENTSTATUS.
              CLEAR: lcl_ls_buffer_item=>GV_OverallGoodsMovStatus.
*              CONDENSE <fs_field_value_dh>->* NO-GAPS.
              IF ls_deldata-OVERALLGOODSMOVEMENTSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus = 'Not Relevant'.
              ELSEIF ls_deldata-OVERALLGOODSMOVEMENTSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus = 'Not yet processed'.
              ELSEIF ls_deldata-OVERALLGOODSMOVEMENTSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus = 'Partially processed'.
              ELSEIF ls_deldata-OVERALLGOODSMOVEMENTSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallGoodsMovStatus = 'Completely processed'.
              ENDIF.


              lcl_ls_buffer_item=>GV_OverallPackStatus = ls_deldata-OVERALLPACKINGSTATUS.

              CLEAR: lcl_ls_buffer_item=>GV_OverallPackStatus.
*              CONDENSE <fs_field_value_dh>->* NO-GAPS.
              IF ls_deldata-OVERALLPACKINGSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallPackStatus = 'Not Relevant'.
              ELSEIF ls_deldata-OVERALLPACKINGSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallPackStatus = 'Not yet processed'.
              ELSEIF ls_deldata-OVERALLPACKINGSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallPackStatus = 'Partially processed'.
              ELSEIF ls_deldata-OVERALLPACKINGSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallPackStatus = 'Completely processed'.
              ENDIF.

             lcl_ls_buffer_item=>GV_OverallPickConfStatus = ls_deldata-OVERALLPICKINGCONFSTATUS.

              CLEAR:  lcl_ls_buffer_item=>GV_OverallPickConfStatus.
*              CONDENSE <fs_field_value_dh>->* NO-GAPS.
              IF ls_deldata-OVERALLPICKINGCONFSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus = 'Not Relevant'.
              ELSEIF ls_deldata-OVERALLPICKINGCONFSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus = 'Not yet processed'.
              ELSEIF ls_deldata-OVERALLPICKINGCONFSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus = 'Partially processed'.
              ELSEIF ls_deldata-OVERALLPICKINGCONFSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallPickConfStatus = 'Completely processed'.
              ENDIF.

              lcl_ls_buffer_item=>GV_OverallPickStatus = ls_deldata-OVERALLPICKINGSTATUS.

              CLEAR:  lcl_ls_buffer_item=>GV_OverallPickStatus.
*              CONDENSE <fs_field_value_dh>->* NO-GAPS.
              IF ls_deldata-OVERALLPICKINGSTATUS EQ space.
                lcl_ls_buffer_item=>GV_OverallPickStatus = 'Not Relevant'.
              ELSEIF ls_deldata-OVERALLPICKINGSTATUS EQ 'A'.
                lcl_ls_buffer_item=>GV_OverallPickStatus = 'Not yet processed'.
              ELSEIF ls_deldata-OVERALLPICKINGSTATUS EQ 'B'.
                lcl_ls_buffer_item=>GV_OverallPickStatus = 'Partially processed'.
              ELSEIF ls_deldata-OVERALLPICKINGSTATUS EQ 'C'.
                lcl_ls_buffer_item=>GV_OverallPickStatus = 'Completely processed'.
              ENDIF.
  endif.

        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.
***********fetching sales order number from delivery number
*API logic INPUT DELIVERY NUMBER from screen AND OUTPUT IS SALES ORDER

      FIELD-SYMBOLS:
        <fs_data>           TYPE data,
        <fs_data_ds>        TYPE data,
        <fs_results>        TYPE any,
        <fs_results_ds>     TYPE any,
        <fs_structure>      TYPE any,
        <fs_hold>           TYPE any,
        <fs_error>          TYPE any,
        <fs_error_temp>     TYPE any,
        <fs_error_temp_d>   TYPE any,
        <fs_error_table>    TYPE  any,
        <fs_table>          TYPE  ANY TABLE,
        <fs_table_temp>     TYPE  ANY TABLE,
        <fs_field>          TYPE any,
        <fs_field_d>        TYPE any,
        <fs_field_ds>       TYPE any,
        <fs_field_values>   TYPE data,
        <fs_field_value_d>  TYPE data,
        <fs_field_value_ds> TYPE data.
      FIELD-SYMBOLS : <ls_table> TYPE any.
      FIELD-SYMBOLS : <ls_table_d> TYPE any.
      FIELD-SYMBOLS : <lv_severity>      TYPE any,
                      <fs_final_data>    TYPE data,
                      <fs_final_data_d>  TYPE data,
                      <fs_final_data_ds> TYPE data.

      DATA: lr_data    TYPE REF TO data,
            lr_data_d  TYPE REF TO data,
            lr_data_dS TYPE REF TO data.

      DATA :    "ls_cond TYPE ty_cond,
        lv_so      TYPE c LENGTH 10,
        lv_DN      TYPE c LENGTH 10,
        lv_DN_item TYPE zwbi_dt_itemno,
        lv_so_qty  TYPE zwbi_dt_weigh.

      DATA : gv_web TYPE string.
      DATA : gv_web2 TYPE string.
      DATA : gv_web3 TYPE string.
      DATA lv_so_det TYPE string.


try.
SELECT single DELIVERYDOCUMENT,DELIVERYDOCUMENTITEM,REFERENCESDDOCUMENT from I_DeliveryDocumentItem
 where deliverydocument = @ls_items-ordnum into @data(ls_del).
if sy-subrc eq 0.
CLEAR:lv_so,lv_so_qty.
lv_so = ls_del-REFERENCESDDOCUMENT.

CLEAR:lv_DN.
lv_DN = ls_del-DELIVERYDOCUMENT.

CLEAR:lv_DN_item.
lv_DN_item = ls_del-DELIVERYDOCUMENTITEM.

endif.

        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.
******Start of SD delv no items pick quantity logic API*******
*                TRY.

                    DATA : gv_web_pdi TYPE string.
                    DATA : gv_web_pdi2 TYPE string.
                    DATA : gv_web_pdi3 TYPE string.
                    DATA: lv_so_det_pdi TYPE string,
                          lv_pdchan     TYPE c LENGTH 2.


                    TYPES : BEGIN OF ty_pditems,
                              Predeldoc TYPE c LENGTH 10,
                              Preitem   TYPE zwbi_dt_itemno,
                              subdeldoc TYPE c LENGTH 10,
                              Pickqty   TYPE  zwbi_dt_weigh,
                              subdoccat  type c LENGTH 1, "new 05-06

                            END OF ty_pditems.
*
                    DATA : lt_pditemss TYPE STANDARD TABLE OF ty_pditems,
                           ls_pditemss TYPE ty_pditems.

***SO Header
                    FIELD-SYMBOLS : <ls_table_pdh> TYPE any.
                    FIELD-SYMBOLS : <lv_severity_pdh>   TYPE any,
                                    <fs_final_data_pdh> TYPE data.
                    DATA: lr_data_pdh TYPE REF TO data.

*****SO Item
                    FIELD-SYMBOLS : <ls_table_pdi> TYPE any.
                    FIELD-SYMBOLS : <lv_severity_pdi>   TYPE any,
                                    <fs_final_data_pdi> TYPE data.
                    DATA: lr_data_pdi TYPE REF TO data.

                    FIELD-SYMBOLS: <fs_data_pdi>        TYPE data,
                                   <fs_results_pdi>     TYPE any,
                                   <fs_structure_pdi>   TYPE any,
                                   <fs_hold_pdi>        TYPE any,
                                   <fs_error_pdi>       TYPE any,
                                   <fs_error_temp_pdi>  TYPE any,
                                   <fs_error_table_pdi> TYPE any,
                                   <fs_table_pdi>       TYPE ANY TABLE,
                                   <fs_table_temp_pdi>  TYPE ANY TABLE,
                                   <fs_field_pdi>       TYPE any,
                                   <fs_field_value>     TYPE data,
                                   <fs_field_value_pdi> TYPE data.
*****
                    CLEAR: gv_web_pdi,gv_web_pdi2, gv_web_pdi3,lv_so_det_pdi , lv_pdchan .

try.
  select single * from I_BillingDocumentItem
      WHERE ReferenceSDDocument = @lv_DN and ReferenceSDDocumentItem = @lv_DN_item
       into @data(ls_soitemdata1).

       if sy-subrc eq 0.

            ls_pditemss-predeldoc = ls_soitemdata1-SalesDocument.
            ls_pditemss-subdoccat = ls_soitemdata1-SalesSDDocumentCategory.
            ls_pditemss-pickqty = ls_soitemdata1-billingQUANTITYINBASEUNIT.






*            if ls_pditemss-subdoccat eq 'Q' .  "new   pick qty based on SUBSEQUENTDOCUMENTCATEGORY in SO
               lcl_ls_buffer_item=>gv_header_pickqty_so_r = lcl_ls_buffer_item=>gv_header_pickqty_so_r + ls_pditemss-pickqty.
*             endif.

         CLEAR:ls_pditemss-pickqty.
       endif.

******End of Sd delv no pick quantity   logic

*              ENDLOOP.

*Item data updating
              MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE
                     ENTITY item
                         UPDATE SET FIELDS WITH VALUE #(
                                 FOR it IN itemss (
                                     %key = it-%key
                                     %is_draft = it-%is_draft
                                     Pickquantity = lcl_ls_buffer_item=>gv_header_pickqty_so_r
                                     overalldbstatus   =     lcl_ls_buffer_item=>GV_OverallDBStatus
                                     overallgoodsmovstatus = lcl_ls_buffer_item=>GV_OverallGoodsMovStatus
                                     overallpackstatus    =  lcl_ls_buffer_item=>GV_OverallPackStatus
                                     overallpickconfstatus = lcl_ls_buffer_item=>GV_OverallPickConfStatus
                                     overallpickstatus  =    lcl_ls_buffer_item=>GV_OverallPickStatus
                                "     %control = value (  )
                                 )
                         ) REPORTED DATA(modifreported).
              reported = CORRESPONDING #( DEEP modifreported ).

              lcl_ls_buffer_item=>gv_error_flag = 'X'.
*            ENDIF.
*          ENDIF.
*
        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.
    ENDIF.

    IF ls_items-ordnum IS NOT INITIAL AND ls_items-intype = 'P'.     " Logic for PO live delivery status update

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
                      <fs_field_value_pi> TYPE data.

***PO item
      FIELD-SYMBOLS : <ls_table_pi> TYPE any.
      FIELD-SYMBOLS : <lv_severity_pi>   TYPE any,
                      <fs_final_data_pi> TYPE data.
      DATA: lr_data_pi TYPE REF TO data.

      DATA : gv_web_pi TYPE string.
      DATA : gv_web_pi2 TYPE string.
      DATA : gv_web_pi3 TYPE string.


      TYPES : BEGIN OF ty_pitems,
                Deldoc         TYPE c LENGTH 10,
                item           TYPE zwbi_dt_itemno,
                plant          TYPE c LENGTH 4,
                ordqty         TYPE zwbi_dt_quantity,
                dchan          TYPE c LENGTH 2,
                ItemGWeight    TYPE zwbi_dt_quantity,
                itemqtyunit    TYPE c LENGTH 3,
                itemweightunit TYPE c LENGTH 3,
                ItemNWeight    TYPE  zwbi_dt_quantity,
                Podelstatus    TYPE c LENGTH 1,
                invoicstatus   TYPE c LENGTH 1,
              END OF ty_pitems.
*
      DATA : lt_pitems TYPE STANDARD TABLE OF ty_pitems,
             ls_pitems TYPE ty_pitems.

      DATA: lv_po_ordqty      TYPE zwbi_dt_quantity,
            lv_po_ItemGWeight TYPE zwbi_dt_quantity,
            lv_po_ItemNWeight TYPE  zwbi_dt_quantity,
            lv_ITEMWEIGHTUNIT TYPE c LENGTH 3,
            lv_po             TYPE c LENGTH 10.

***********updating Net and Gross weights  18-05
*              lcl_ls_buffer_item=>gv_header_grossweight_so =  lv_po_ItemGWeight.
*              lcl_ls_buffer_item=>gv_header_netweight_so = lv_po_ItemNWeight.
***************17-05 start  of PO history logic*******************************************************************************
try.
    SELECT Purchaseorder,PurchaseorderItem,PLANT,ORDERQUANTITY, ITEMGROSSWEIGHT,
           ITEMNETWEIGHT,orderpriceunit,itemweightunit,
           ISFINALLYINVOICED,ISCOMPLETELYDELIVERED
           from I_PurchaseOrderItemTP_2 "I_PurchaseOrderTP_2
    where Purchaseorder = @ls_items-ordnum INto TABLE @data(lt_po1).
    if sy-subrc eq 0.
      loop at lt_po1 into data(ls_poitemdata1).
        CLEAR: lv_po_ordqty,lv_po_ItemGWeight,lv_po_ItemNWeight.
        ls_pitems-deldoc = ls_poitemdata1-PURCHASEORDER.
        CLEAR: lv_po.
        lv_po = ls_pitems-deldoc.

        ls_pitems-item = ls_poitemdata1-PURCHASEORDERITEM.

        CLEAR:ls_head-plant.
        ls_head-plant = ls_poitemdata1-PLANT.

        ls_pitems-ordqty = ls_poitemdata1-ORDERQUANTITY.
        lv_po_ordqty  = lv_po_ordqty + ls_pitems-ordqty.

        ls_pitems-itemqtyunit = ls_poitemdata1-ORDERPRICEUNIT.

       SELECT SINGLE UnitOfMeasure_E from I_UnitOfMeasureText
          where UnitOfMeasure = @ls_pitems-itemqtyunit
            and Language = @sy-langu into @data(lv_external_uom2).
        lcl_ls_buffer_item=>gv_uom = lv_external_uom2.
*        lcl_ls_buffer_item=>gv_uom  = ls_pitems-itemqtyunit.

        ls_pitems-ItemGWeight = ls_poitemdata1-ITEMGROSSWEIGHT.
        lv_po_ItemGWeight   = lv_po_ItemGWeight + ( ls_pitems-ItemGWeight * ls_pitems-ordqty ).

        ls_pitems-ItemNWeight = ls_poitemdata1-ITEMNETWEIGHT.
        lv_po_ItemNWeight = lv_po_ItemNWeight + ( ls_pitems-ItemNWeight * ls_pitems-ordqty ).

        ls_pitems-itemweightunit = ls_poitemdata1-ITEMWEIGHTUNIT.

        if ls_pitems-itemweightunit is not INITIAL.   "21-05
            CLEAR:lv_ITEMWEIGHTUNIT.
            lv_ITEMWEIGHTUNIT  =  ls_pitems-itemweightunit.
        endif.

        lcl_ls_buffer_item=>gv_invoicstatus = ls_poitemdata1-ISFINALLYINVOICED.
        CONDENSE lcl_ls_buffer_item=>gv_invoicstatus.

        IF lcl_ls_buffer_item=>gv_invoicstatus IS INITIAL.
           lcl_ls_buffer_item=>gv_invoicstatus = 'Not yet processed'.
        ELSE.
           lcl_ls_buffer_item=>gv_invoicstatus = 'Fully Invoiced'.
        ENDIF.
        CONDENSE lcl_ls_buffer_item=>gv_invoicstatus.

*        ls_pitems-sloc = ls_poitemdata1-STORAGELOCATION.
        ls_pitems-Podelstatus = ls_poitemdata1-ISCOMPLETELYDELIVERED.

        APPEND ls_pitems TO lt_pitems.
        CLEAR:ls_pitems.

*****end of storage location text logic
      endloop.
    endif.
              lcl_ls_buffer_item=>gv_header_grossweight_so =  lv_po_ItemGWeight.
              lcl_ls_buffer_item=>gv_header_netweight_so = lv_po_ItemNWeight.
***SO item
              FIELD-SYMBOLS:
                <fs_data_dist_h>        TYPE data,
                <fs_results_dist_h>     TYPE any,
                <fs_structure_dist_h>   TYPE any,
                <fs_hold_dist_h>        TYPE any,
                <fs_error_dist_h>       TYPE any,
                <fs_error_temp_dist_h>  TYPE any,
                <fs_error_table_dist_h> TYPE any,
                <fs_table_dist_h>       TYPE ANY TABLE,
                <fs_table_temp_dist_h>  TYPE ANY TABLE,
                <fs_field_dist_h>       TYPE any,
                <fs_field_value_dist_h> TYPE data.


              DATA: lr_data_dist_h TYPE REF TO data.


              FIELD-SYMBOLS : <ls_table_dist_h> TYPE any.
              FIELD-SYMBOLS : <lv_severity_dist_h>   TYPE any,
                              <fs_final_data_dist_h> TYPE data.

****
              DATA : gv_web_dist_h TYPE string.
              DATA : gv_web_dist2_h TYPE string.
              DATA : gv_web_dist3_h TYPE string.
              DATA: lv_so_det_dist_h TYPE string.



              TYPES : BEGIN OF ty_PO_h,
                        Purorder            TYPE c LENGTH 10,
                        item                TYPE zwbi_dt_itemno,
                        delqty              TYPE zwbi_dt_quantity,
                        orderqty            TYPE zwbi_dt_quantity,
                        totaldelqty         TYPE zwbi_dt_quantity,
                        totalinvqty         TYPE zwbi_dt_quantity,
                        debitcredit         TYPE c LENGTH 1,
                        iscompletedelv      TYPE c LENGTH 1,
                        pocompletedelv      TYPE c LENGTH 1,
                        finalpocompletedelv TYPE c LENGTH 1,
                        finalinvoicestatus  TYPE c LENGTH 1,
                        purhiscatg          TYPE c LENGTH 1,
                        movetyp             TYPE c LENGTH  3,


                      END OF ty_PO_h.
*
              DATA : lt_po_h          TYPE STANDARD TABLE OF ty_po_h,
                     lt_po_out_h      TYPE STANDARD TABLE OF ty_po_h,
                     lt_po_out_h_I    TYPE STANDARD TABLE OF ty_po_h,
                     lt_po_result_h   TYPE STANDARD TABLE OF ty_po_h,
                     lt_po_result_h_i TYPE STANDARD TABLE OF ty_po_h,
                     ls_po_h          TYPE ty_po_h,
                     ls_po_out_h      TYPE ty_po_h,
                     lv_totaldelqty   TYPE zwbi_dt_quantity,
                     lv_Invqty        TYPE zwbi_dt_quantity,
                     lv_delqty        TYPE zwbi_dt_quantity,
                     lv_stilltodelqty TYPE zwbi_dt_quantity,
                     lv_ordqty        TYPE zwbi_dt_quantity,
                     lv_po_h          TYPE c LENGTH 30. "01-04


try.
SELECT PURCHASEORDER, PURCHASEORDERITEM, QUANTITY,GOODSMOVEMENTTYPE,ISCOMPLETELYDELIVERED,
       DEBITCREDITCODE, PURCHASINGHISTORYCATEGORY from I_PurchaseOrderHistoryAPI01
where purchaseorder = @lv_po into table @data(lt_pohist).
if sy-subrc eq 0.
loop at lt_pohist into data(ls_pohist).
ls_po_h-Purorder =      ls_pohist-PURCHASEORDER.
ls_po_h-item = ls_pohist-PURCHASEORDERITEM.
ls_po_h-delqty = ls_pohist-QUANTITY.
ls_po_h-movetyp = ls_pohist-GOODSMOVEMENTTYPE.
ls_po_h-iscompletedelv = ls_pohist-ISCOMPLETELYDELIVERED.
ls_po_h-debitcredit = ls_pohist-DEBITCREDITCODE.
ls_po_h-purhiscatg = ls_pohist-PURCHASINGHISTORYCATEGORY.

READ TABLE lt_pitems INTO ls_pitems WITH KEY Deldoc = ls_po_h-purorder  item = ls_po_h-item. "  getting order qty and delivery status

IF sy-subrc EQ 0.
 ls_po_h-orderqty  = ls_pitems-ordqty.
IF ls_po_h-delqty LT ls_po_h-orderqty.
   ls_po_h-pocompletedelv = 'P'. " Partially deliveried status
ELSEIF ls_po_h-delqty EQ ls_po_h-orderqty.
   ls_po_h-pocompletedelv = 'F'.   " Fully delivered status
ELSEIF ls_po_h-delqty IS INITIAL.
  ls_po_h-pocompletedelv = 'N'.  " not delivery status
ENDIF.

ELSE.
  ls_po_h-pocompletedelv = 'N'.  " not delivery status
ENDIF.

 APPEND ls_po_h TO lt_po_h.
 CLEAR:ls_po_h,ls_pitems.
endloop.
endif.

              lt_po_out_h[] = lt_po_h[].

        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.
*****************new  23-05

data: lv_revDelveredqty_h  TYPE zwbi_dt_quantity,
      lv_Delveredqty_s     TYPE zwbi_dt_quantity,
      lv_revinvoicedqty_h       TYPE zwbi_dt_quantity,
      lv_postedinvoicedqty_s       TYPE zwbi_dt_quantity,
       lv_Delveredqty     TYPE zwbi_dt_quantity,  "delivered qty
       lv_invoicedqty     TYPE zwbi_dt_quantity,
       lv_Totorderqty     TYPE zwbi_dt_quantity.  "ordered qty


clear:lv_revDelveredqty_h, lv_Delveredqty_s,lv_revinvoicedqty_h,lv_postedinvoicedqty_s,lv_Totorderqty.
SORT lt_po_h BY Purorder item. " debitcredit purhiscatg.
              LOOP AT lt_po_h INTO ls_po_h.

* DATA(ls_po_out_h2) = ls_po_h.

 if ls_po_h-debitcredit = 'H' and ls_po_h-purhiscatg = 'E'.

 lv_revDelveredqty_h   = ls_po_h-delqty + lv_revDelveredqty_h.

 elseif ls_po_h-debitcredit = 'S' and ls_po_h-purhiscatg = 'E'.

 lv_Delveredqty_s    =  ls_po_h-delqty + lv_Delveredqty_s.

 elseif ls_po_h-debitcredit = 'H' and ls_po_h-purhiscatg = 'Q'.


  lv_revinvoicedqty_h   =  ls_po_h-delqty +  lv_revinvoicedqty_h.

 elseif ls_po_h-debitcredit = 'S' and ls_po_h-purhiscatg = 'Q'.

 lv_postedinvoicedqty_s   =   ls_po_h-delqty + lv_postedinvoicedqty_s.

endif.


endloop.

 lv_Totorderqty  = lv_po_ordqty.  " order qty
 lv_Delveredqty =    lv_Delveredqty_s - lv_revDelveredqty_h. "total delvd qty

 lv_invoicedqty  =  lv_postedinvoicedqty_s - lv_revinvoicedqty_h.

  lcl_ls_buffer_item=>gv_delquantity_po  = lv_Delveredqty . "23-05 "PO delivered qty
  lcl_ls_buffer_item=>gv_invquantity_po = lv_invoicedqty. "23-05  PO invoiced qty
  lcl_ls_buffer_item=>gv_stilltodelquantity_po  = lv_Totorderqty - lv_Delveredqty." 23-05 PO still to delivery qty
  CONDENSE lcl_ls_buffer_item=>gv_stilltodelquantity_po. "22-05
*Delivery status logic
                       IF lv_Delveredqty LT lv_Totorderqty and lv_Delveredqty is not INITIAL..

                     lcl_ls_buffer_item=>GV_PodelvStatus =    'Partially Delivered'. " Partially deliveried status

                  ELSEIF lv_Delveredqty EQ lv_Totorderqty.

*                    ls_po_out_h1-finalpocompletedelv =  'F'.   " Fully delivered status
                    lcl_ls_buffer_item=>GV_PodelvStatus =  'Fully Delivered'.

                  ELSEIF lv_Delveredqty IS INITIAL.

                      lcl_ls_buffer_item=>GV_PodelvStatus =  'Not Delivered'. " not delivery status

                  ENDIF.

*Invoice status logic
      IF lv_invoicedqty LT lv_Totorderqty  and lv_invoicedqty is not INITIAL.

     lcl_ls_buffer_item=>gv_invoicstatus =    'Partially Invoiced'.

       ELSEIF lv_invoicedqty EQ lv_Totorderqty.

       lcl_ls_buffer_item=>gv_invoicstatus =  'Fully Invoiced'.

         ELSEIF lv_invoicedqty IS INITIAL.
         lcl_ls_buffer_item=>gv_invoicstatus =  'Not Invoiced'.

          endif.


****************end 23-05

*Item data updating
              MODIFY ENTITIES OF zwbi_i_vehin_head IN LOCAL MODE  "zi_vehin_head IN LOCAL MODE
                     ENTITY item
                         UPDATE SET FIELDS WITH VALUE #(
                                 FOR it IN itemss (
                                     %key = it-%key
                                     %is_draft = it-%is_draft
*                             Pickquantity = lcl_ls_buffer_item=>gv_header_pickqty_so_r
*                             overalldbstatus   =     lcl_ls_buffer_item=>GV_OverallDBStatus
*                             overallgoodsmovstatus = lcl_ls_buffer_item=>GV_OverallGoodsMovStatus
*                             overallpackstatus    =  lcl_ls_buffer_item=>GV_OverallPackStatus
*                             overallpickconfstatus = lcl_ls_buffer_item=>GV_OverallPickConfStatus
*                             overallpickstatus  =    lcl_ls_buffer_item=>GV_OverallPickStatus
                                     Podelvstatus       =  lcl_ls_buffer_item=>GV_PodelvStatus
                                     Isfinallyinvoiced  = lcl_ls_buffer_item=>gv_invoicstatus  "04-05
                                     grossweight = lcl_ls_buffer_item=>gv_header_grossweight_so "ls_data-grossweight "18-05
                                     netweight = lcl_ls_buffer_item=>gv_header_netweight_so "ls_data-netweight   "18-05
                                     Delquantity       =  lcl_ls_buffer_item=>gv_delquantity_po  "17-05 "PO delivered qty
                                     Invquantity       = lcl_ls_buffer_item=>gv_invquantity_po  "17-05  PO invoiced qty
                                     Stilltodelquantity  = lcl_ls_buffer_item=>gv_stilltodelquantity_po " 17-05 PO still to delivery qty
                                      Delqty              =   lcl_ls_buffer_item=>gv_stilltodelquantity_po "  lcl_ls_buffer_item=>gv_delquantity_po  "01-06 "PO delivered qty  testing
                                "     %control = value (  )
                                 )
                         ) REPORTED modifreported.
              reported = CORRESPONDING #( DEEP modifreported ).

*if ( lcl_ls_buffer_item=>gv_stilltodelquantity_po is INITIAL or lcl_ls_buffer_item=>gv_stilltodelquantity_po = 0 )
*or ( lcl_ls_buffer_item=>gv_delquantity_po = 0  or lcl_ls_buffer_item=>gv_delquantity_po is INITIAL )
*or ( lcl_ls_buffer_item=>gv_invquantity_po = 0  or lcl_ls_buffer_item=>gv_invquantity_po is INITIAL ). "22-05
***logic to update zero quantity or values into custom table  with update only zero value getting updated but not with Modify

*              update zwbi_vin_i SET    Stilltodelquantity  = @lcl_ls_buffer_item=>gv_stilltodelquantity_po,
*                                              Delquantity       =   @lcl_ls_buffer_item=>gv_delquantity_po,
*                                               Invquantity       = @lcl_ls_buffer_item=>gv_invquantity_po.
**                                                WHERE inward_uuid = @ls_key-inwarduuid.
*endif.
              lcl_ls_buffer_item=>gv_error_flag = 'X'.
*            ENDIF.
*          ENDIF.
        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
      ENDTRY.
    ENDIF.

  ENDMETHOD.

  METHOD get_instance_authorizations.

  ENDMETHOD.

ENDCLASS.