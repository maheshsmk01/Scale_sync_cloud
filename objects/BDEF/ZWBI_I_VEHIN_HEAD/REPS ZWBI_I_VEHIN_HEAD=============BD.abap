managed;
strict ( 1 );
with draft;

define behavior for ZWBI_I_VEHIN_HEAD alias Head //ZI_VEHIN_HEAD alias Head
implementation in class zbp_wbi_i_vehin_head unique //zbp_i_vehin_head unique
persistent table ZWBI_VINH  //zdt_vehin_head
draft table zwbi_vihd  //zdt_vehin_head_d
lock master total etag LastChangedAt
authorization master ( instance )
etag master LocalLastChangedAt

{
  create ;
  update ( features : instance );
  delete ( features : instance );
  field ( features : instance  )Orderhead;  //28-05
  association _Item { create ( features : instance ); }
  action ( features : instance ) print result [1] $self;
  validation validateInward on save { create; update; }
  internal action calcTotWeight;
  action ( features : instance ) setOutward;
  //action ( features : instance ) getPickQtyUpdate; //01-04

 //action ( features : instance ) Plant parameter /N4C03/WBI_DELV_SO_F4_ABS result [1] $self;  //17 new

  draft determine action Prepare
  {
    validation validateInward;
  }

  draft action Edit;
  draft action Activate;
  draft action Discard;
  draft action Resume;


  field ( numbering : managed, readonly ) Inward_Uuid;
 // field ( readonly ) Ticknum, Plant, Type, Fiscal, Range, grossweight, netweight, Intime, Indate, pwexitdt, pwexittm;
  field ( readonly ) Ticknum, Type, Fiscal, Range, Grossweight, Netweight, Intime, Indate, Pwexitdt, Pwexittm, Grossweight_f, Netweight_f,Pwiuom_f;
  field ( readonly ) Pwidate, Pwitime,Pwodate,Pwotime;
  field ( readonly ) LastChangedAt,Last_changed_by_n,LastChangedBy,CreatedAt,CreatedOn, CreatedBy,CreatedTm, LocalLastChangedAt, Eflag, Hdevlstatus, Shipptext, shippoint, Dchannel;
  //field ( mandatory ) intype, Drivnum, Vehnum, Orderhead;
  field ( mandatory ) Intype, Plant;

  determination defaultData on modify { field Intype; create; }
  determination getOrderData on modify { field Orderhead; create; }
  determination setItem on save { create; }
  determination calculateTickNum on save { create; }


  side effects
  {
    field Orderhead affects field Type;
      action setOutward affects  $self;  // auto refresh the entity after outward date capture 21-05-2024
  }
  mapping for ZWBI_VINH  //zdt_vehin_head
    {
      Inward_Uuid        = inward_uuid;
      Drivnum            = drivnum;
      Indate             = indate;
      Intime             = intime;
      Intype             = intype;
      Ticknum            = ticknum;
      Vehnum             = vehnum;
      Drivname           = drivname;  //add newly 17
      Tranname           = tranname;  //add newly 17
      Orderhead          = orderhead;
      Plant              = plant;
      Planttext          = planttext;
      Type               = type;
      Range              = range;
      Fiscal             = fiscal;
      Dchannel           = dchannel;
      Itemunit           = itemunit;
      GrossWeight        = grossweight;
      NetWeight          = netweight;
      Hdevlstatus        = hdevlstatus;  //09-04
      Shippoint          = shippoint;
      Shipptext          = shipptext;
      Pwoempwg           = pwoempwg;  //29-05
      Pwiempwg           = pwiempwg; //29-05
      Pwoempwg_f         = pwoempwg_f;      //25/10/2024
      Pwiempwg_f         = pwiempwg_f;      //25/10/2024
      Gunit_f            = gunit_f;         //25/10/2024
      Tunit_f            = tunit_f;
      CreatedAt          = created_at;
      CreatedBy          = created_by;
      CreatedOn          = created_on;
      CreatedTm          = created_tm;
      LastChangedAt      = last_changed_at;
      LastChangedBy      = last_changed_by;
      LocalLastChangedAt = local_last_changed_at;
      Pwitime            = pwitime;
      Eflag              = eflag;   // added newly on 30-03
      Itemunit_f         = itemunit_f;     //25/10/2024
      Grossweight_f      = grossweight_f;  //25/10/2024
      Netweight_f        = netweight_f;    //25/10/2024
      Pwiuom_f           = pwiuom_f;       //25/10/2024
      Last_changed_by_n = last_changed_by_n;
      //      pwotime            = pwotime;
    }
}


define behavior for ZWBI_I_VEHIN_ITEM  alias Item //alias <alias_name>
implementation in class zbp_wbi_i_vehin_item unique  //zbp_i_vehin_item unique
persistent table ZWBI_VIN_I  //zdt_vehin_item
draft table ZWBI_VI_ID  //zdt_vehin_item_d
lock dependent by _Head
authorization dependent by _Head
etag master LocalLastChangedAt
{
  update ( features : instance );
  delete ( features : instance );
  field ( features : instance  )Ordnum;  //28-05
  field ( readonly ) inward_uuid;
  field ( numbering : managed, readonly ) Item_Uuid;
  field ( readonly ) CreatedBy, LastChangedBy, LocalLastChangedAt;
  field ( readonly ) Bpcode, Bpname, Orderdate, brokername, Inwarditem, Quantity, Unit, Itemunit, GrossWeight, NetWeight, Intype, Pickquantity,
      Packquantity, Overalldbstatus, Overallgoodsmovstatus, Overallpackstatus, Overallpickconfstatus, Overallpickstatus, Podelvstatus, Invquantity,
      Delquantity,Stilltodelquantity, Isfinallyinvoiced, Sloctext, Sloc, Planttext, Shipptext,Delqty, Dchannel  ;
  field ( mandatory ) Ordnum;
  association _Head { with draft; }

  validation validateOrder on save { create; update; }
 // determination setInwardType on modify { field Ordnum; create; } :old 01-06
   determination setInwardType on modify { field Ordnum; create; }  //added update; delete;on 1/5/2025
  determination calcTotalWeight on save { create; update; delete; }

//  action ( features : instance ) getPickQtyUpdate result [1] $self; //31-05  added result [1] $self
//  side effects { action getPickQtyUpdate affects entity  _Head,  $self; } // auto refresh the entity after refresh button click 01-04

  action ( features : instance ) getPickQtyUpdate result [1] $self;
  action ( features : instance ) getItemDelete result [1] $self;

  side effects {

//  action getItemDelete affects entity _Head,  $self;
  action getPickQtyUpdate  affects entity _Head,  $self;
   action getItemDelete affects entity _Head,  $self;


  }// auto refresh the entity after refresh button click 01-04

//   side effects   //01-04
//  {
//    field Ordnum affects field Pickquantity;
//  }

  mapping for ZWBI_VIN_I   //zdt_vehin_item
    {
      Inward_uuid        = inward_uuid;
      Item_Uuid          = item_uuid;
      Inwarditem         = inwarditem;
      Bpcode             = bpcode;
      Bpname             = bpname;
      Brokername         = brokername;
      Orderdate          = orderdate;
      Ordnum             = ordnum;
      Quantity           = quantity;
      GrossWeight        = grossweight;
      NetWeight          = netweight;
      Intype             = intype;
      Dchannel           = dchannel;
      Plant              = plant;
      Planttext          = Planttext;
      Unit               = unit;
      Itemunit           = itemunit;
      Pickquantity       =  pickquantity;
      Packquantity       = packquantity;
      Overalldbstatus    = overalldbstatus;
      Overallgoodsmovstatus  = overallgoodsmovstatus;
      Overallpackstatus    = overallpackstatus;
      Overallpickconfstatus   = overallpickconfstatus;
      Overallpickstatus       = overallpickstatus;
      Shippoint            = shippoint;
      Shipptext            = shipptext;
      Podelvstatus         = podelvstatus;
      Isfinallyinvoiced    = isfinallyinvoiced;
      Sloc                 = sloc;
      Sloctext             = sloctext;
      Invquantity          = invquantity;
      Delquantity          = delquantity;
      Stilltodelquantity   = stilltodelquantity;
      Delqty               = delqty;
      CreatedBy            = created_by;
      CreatedOn            = created_on;
      LastChangedBy        = last_changed_by;
      LocalLastChangedAt   = local_last_changed_at;
    }

}