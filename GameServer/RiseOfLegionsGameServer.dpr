program RiseOfLegionsGameServer;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  Winapi.Windows,
  GameServerMain in 'GameServerMain.pas'{Form1},
  BaseConflict.Entity in '..\BaseConflict.Entity.pas',
  BaseConflict.EntityComponents.Shared in '..\BaseConflict.EntityComponents.Shared.pas',
  BaseConflict.Constants in '..\BaseConflict.Constants.pas',
  BaseConflict.Game.Server in 'BaseConflict.Game.Server.pas',
  BaseConflict.EntityComponents.Server in 'BaseConflict.EntityComponents.Server.pas',
  BaseConflict.EntityComponents.Server.Warheads in 'BaseConflict.EntityComponents.Server.Warheads.pas',
  BaseConflict.Map in '..\BaseConflict.Map.pas',
  BaseConflict.Game in '..\BaseConflict.Game.pas',
  BaseConflict.Globals in '..\BaseConflict.Globals.pas',
  Engine.Helferlein in '..\Engine\Engine.Helferlein.pas',
  Engine.Math in '..\Engine\Engine.Math.pas',
  Engine.Network in '..\Engine\Engine.Network.pas',
  Engine.Serializer in '..\Engine\Engine.Serializer.pas',
  Engine.Serializer.Types in '..\Engine\Engine.Serializer.Types.pas',
  Engine.Log in '..\Engine\Engine.Log.pas',
  Engine.Script in '..\Engine\Engine.Script.pas',
  Engine.Collision in '..\Engine\Engine.Collision.pas',
  Engine.Math.Collision2D in '..\Engine\Engine.Math.Collision2D.pas',
  Engine.Math.Collision3D in '..\Engine\Engine.Math.Collision3D.pas',
  BaseConflict.EntityComponents.Server.Brains in 'BaseConflict.EntityComponents.Server.Brains.pas',
  BaseConflict.EntityComponents.Server.Welas in 'BaseConflict.EntityComponents.Server.Welas.pas',
  BaseConflict.Types.Server in 'BaseConflict.Types.Server.pas',
  BaseConflict.Types.Target in '..\BaseConflict.Types.Target.pas',
  BaseConflict.EntityComponents.Server.Brains.Special in 'BaseConflict.EntityComponents.Server.Brains.Special.pas',
  BaseConflict.Classes.Shared in '..\BaseConflict.Classes.Shared.pas',
  BaseConflict.Globals.Server in 'BaseConflict.Globals.Server.pas',
  BaseConflict.EntityComponents.Server.Welas.Special in 'BaseConflict.EntityComponents.Server.Welas.Special.pas',
  BaseConflict.Api in '..\Baseconflict.Api.pas',
  BaseConflict.Constants.Cards in '..\BaseConflict.Constants.Cards.pas',
  BaseConflict.Classes.Pathfinding in '..\BaseConflict.Classes.Pathfinding.pas',
  Engine.Helferlein.DataStructures in '..\Engine\Engine.Helferlein.DataStructures.pas',
  BaseConflict.Api.Types in '..\Baseconflict.Api.Types.pas',
  BaseConflict.Api.Account in '..\BaseConflict.Api.Account.pas',
  BaseConflict.Constants.Scenario in '..\BaseConflict.Constants.Scenario.pas',
  BaseConflict.Types.Shared in '..\Baseconflict.Types.Shared.pas',
  BaseConflict.EntityComponents.Shared.Wela in '..\BaseConflict.EntityComponents.Shared.Wela.pas',
  BaseConflict.Classes.Server in 'BaseConflict.Classes.Server.pas',
  BaseConflict.Constants.Scenario.Server in 'BaseConflict.Constants.Scenario.Server.pas',
  BaseConflict.EntityComponents.Server.Statistics in 'BaseConflict.EntityComponents.Server.Statistics.pas';

{$IFDEF WIN32}
{$SETPEFLAGS IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}
{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
