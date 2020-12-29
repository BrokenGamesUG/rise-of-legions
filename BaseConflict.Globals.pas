unit BaseConflict.Globals;

interface

uses
  // Delphi
  System.SysUtils,
  // Engine
  Engine.Script,
  Engine.Helferlein.Windows,
  // Game
  BaseConflict.Entity,
  BaseConflict.Game,
  BaseConflict.Map,
  BaseConflict.Classes.Shared;

var
  BalancingManager : TBalancingManager;

  threadvar
    GameTimeManager : TTimeManager;
  threadvar
    Game : TGame;
  threadvar
    Map : TMap;
  threadvar
    GlobalEventbus : TEventbus;
  threadvar
    EntityDataCache : TEntityDataCache;

type

  FuncGameResolver = function() : TGame;

implementation

function GameResolver : TGame;
begin
  Result := BaseConflict.Globals.Game;
end;

initialization

ScriptManager.ExposeFunction('Game', @GameResolver, TypeInfo(FuncGameResolver));

end.
