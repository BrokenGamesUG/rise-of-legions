unit Engine.Eventsystem.Helper;

interface

uses
  // ------------------------Delphi----------------------------------------------

  // -----------------------Engine-----------------------------------------------
  // ------------------------Eventsystem----------------------------------------
  Engine.Eventsystem.Types,
  System.Generics.Collections;

function ByteArrayToComponentGroup(inArray : TArray<Byte>) : SetComponentGroup;

implementation

function ByteArrayToComponentGroup(inArray : TArray<Byte>) : SetComponentGroup;
var
  i : integer;
begin
  Result := [];
  for i := 0 to length(inArray) - 1 do
      Result := Result + [inArray[i]];
end;

end.
