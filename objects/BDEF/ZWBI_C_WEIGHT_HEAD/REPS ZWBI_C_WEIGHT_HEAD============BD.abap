projection;
strict ( 1 );
use side effects;
define behavior for ZWBI_C_WEIGHT_HEAD  alias Head //alias <alias_name>
{
use action getWeightTare;
//use function GetDefaultsForGRMSG; //24/06
//side effects {                       //21-03
//field pwiempwg affects field Type;  //21-03
 // }                                //21-03
  use action getWeightGross;

  use action getEdit;  //3/02/2025
  use action getHeadEdit; //11/4/2025 new
  use function GetDefaultsForgetEdit;
  use function GetDefaultsForgetHeadEdit;

  use association _Item { }
//   side effects { action getWeightTare affects entity _Item, $self; } // auto refresh the entity after tareweight capture 29-03-2024
}




define behavior for ZWBI_C_WEIGHT_ITEM alias Item //alias <alias_name>
{
  use update;
  use delete; //17/12/2024
  use association _Head;
}