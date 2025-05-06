projection;
strict ( 1 );
use draft;
use side effects;
define behavior for ZWBI_C_VEHIN_HEAD alias Head //alias <alias_name>
{
  use create;
  use update;
  use delete;


  use action Edit;
  use action Activate;
  use action Discard;
  use action Resume;
  use action Prepare;
  use action print;
  use action setOutward;
  use association _Item { create; with draft; }


}



define behavior for ZWBI_C_VEHIN_ITEM  alias Item //alias <alias_name>
{
  use update;
//  use delete; //30/12/2024 commented
  use action getPickQtyUpdate;
  use action getItemDelete ;   //30/12/2024  added
  use association _Head { with draft; }
}