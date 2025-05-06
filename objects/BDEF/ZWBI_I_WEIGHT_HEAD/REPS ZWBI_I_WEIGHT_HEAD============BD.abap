managed;
//implementation in class
///n4c03/bp_wbi_i_weight_head unique;
strict ( 1 );

define behavior for ZWBI_I_WEIGHT_HEAD alias Head
implementation in class
zbp_wbi_i_weight_head unique //zbp_i_weight_head unique
persistent table ZWBI_VINH //zdt_vehin_head
lock master
authorization master ( instance )


//etag master <field_name>
{
  create;
  update;
  delete;
  association _Item { create; }
  action ( features : instance ) getHeadEdit parameter ZWBI_EDIT_H {default function GetDefaultsForgetHeadEdit ;} //11/04/2025 new
  action (features : instance ) getEdit parameter ZWBI_EDIT   {default function GetDefaultsForgetEdit ;} //02/03/2025
  action ( features : instance ) getWeightTare parameter ZWBI_AB_TWT;  //result [1] $self; //"24/06 //added result [1] $self 24-06
 // action ( features : instance ) getWeightTare parameter /N4C03/WBI_I_GR_MSG  result [1] $self // result [1] $self;
 // { default function GetDefaultsForGRMSG; } //method will be created in /N4C03/WBI_I_WEIGHT_HEAD
  action ( features : instance ) getWeightGross parameter ZWBI_AB_GWT;   //added result [1] $self 24-06;
  field ( readonly ) Ticknum, Intype, Indate, Intime, Vehnum, Drivnum, pwidate, Pwitime, Pwiuom, pwodate, Pwotime, type, InwardUuid, pwiempwg,
                     Pwoempwg_f,Pwiempwg_f,Gunit_f, Tunit_f;
  side effects { action getWeightTare affects  $self; action getWeightGross affects  $self; action getEdit affects  $self; action getHeadEdit affects  $self;} // auto refresh the entity after tareweight capture 29-03-2024
}

// side effects { action getWeightTare affects entity  _Item, $self; } // auto refresh the entity after tareweight capture 29-03-2024
//}


define behavior for ZWBI_I_WEIGHT_ITEM alias Item//alias <alias_name>
implementation in class zbp_wbi_i_weight_item unique
persistent table ZWBI_VIN_I
//late numbering
lock dependent by _Head
authorization dependent by _Head
//etag master <field_name>
{
  update;
  delete;
  field ( readonly ) InwardUuid, Inwarditem, Podelvstatus, Isfinallyinvoiced, Sloc, Sloctext, Intype;
  association _Head;

}