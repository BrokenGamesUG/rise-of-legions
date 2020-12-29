unit BaseConflict.Globals.Server;

interface

uses
  BaseConflict.Game.Server;

var
  Cheatmode : boolean = False;

  threadvar
    Overwatch, OverwatchClearable : boolean;

  threadvar
  /// <summary> The current servergame. Used by the components, so it must be contain the right game. </summary>
    ServerGame : TServerGame;

implementation

end.
