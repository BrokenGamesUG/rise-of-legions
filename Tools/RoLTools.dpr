program RoLTools;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Vcl.Forms,
  BaseConflict.Types.Target in '..\BaseConflict.Types.Target.pas',
  BaseConflict.Api.Account in '..\BaseConflict.Api.Account.pas',
  BaseConflict.Api.Cards in '..\BaseConflict.Api.Cards.pas',
  BaseConflict.Api.Chat in '..\BaseConflict.Api.Chat.pas',
  BaseConflict.Api.Deckbuilding in '..\BaseConflict.Api.Deckbuilding.pas',
  BaseConflict.Api.Game in '..\BaseConflict.Api.Game.pas',
  BaseConflict.Api.Matchmaking in '..\BaseConflict.Api.Matchmaking.pas',
  BaseConflict.Api.Messages in '..\BaseConflict.Api.Messages.pas',
  BaseConflict.Api in '..\BaseConflict.Api.pas',
  BaseConflict.Api.Profile in '..\BaseConflict.Api.Profile.pas',
  BaseConflict.Api.Quests in '..\BaseConflict.Api.Quests.pas',
  Baseconflict.Api.Scenarios in '..\Baseconflict.Api.Scenarios.pas',
  BaseConflict.Api.Shared in '..\BaseConflict.Api.Shared.pas',
  BaseConflict.Api.Shop in '..\BaseConflict.Api.Shop.pas',
  BaseConflict.Api.Types in '..\BaseConflict.Api.Types.pas',
  BaseConflict.Classes.Client in '..\BaseConflict.Classes.Client.pas',
  BaseConflict.Classes.Gamestates.Actions in '..\BaseConflict.Classes.Gamestates.Actions.pas',
  BaseConflict.Classes.Gamestates.GUI in '..\BaseConflict.Classes.Gamestates.GUI.pas',
  BaseConflict.Classes.Gamestates in '..\BaseConflict.Classes.Gamestates.pas',
  BaseConflict.Classes.MiniMap in '..\BaseConflict.Classes.MiniMap.pas',
  BaseConflict.Classes.Pathfinding in '..\BaseConflict.Classes.Pathfinding.pas',
  BaseConflict.Classes.Shared in '..\BaseConflict.Classes.Shared.pas',
  BaseConflict.Client.Init in '..\BaseConflict.Client.Init.pas',
  BaseConflict.Constants.Cards in '..\BaseConflict.Constants.Cards.pas',
  BaseConflict.Constants.Client in '..\BaseConflict.Constants.Client.pas',
  BaseConflict.Constants in '..\BaseConflict.Constants.pas',
  BaseConflict.Constants.Scenario in '..\BaseConflict.Constants.Scenario.pas',
  BaseConflict.Entity in '..\BaseConflict.Entity.pas',
  BaseConflict.EntityComponents.Client.Debug in '..\BaseConflict.EntityComponents.Client.Debug.pas',
  BaseConflict.EntityComponents.Client.GUI in '..\BaseConflict.EntityComponents.Client.GUI.pas',
  BaseConflict.EntityComponents.Client in '..\BaseConflict.EntityComponents.Client.pas',
  BaseConflict.EntityComponents.Client.Sound in '..\BaseConflict.EntityComponents.Client.Sound.pas',
  BaseConflict.EntityComponents.Client.Visuals in '..\BaseConflict.EntityComponents.Client.Visuals.pas',
  BaseConflict.EntityComponents.Shared in '..\BaseConflict.EntityComponents.Shared.pas',
  BaseConflict.EntityComponents.Shared.Wela in '..\BaseConflict.EntityComponents.Shared.Wela.pas',
  BaseConflict.Game.Client in '..\BaseConflict.Game.Client.pas',
  BaseConflict.Game in '..\BaseConflict.Game.pas',
  BaseConflict.GlobalManager in '..\BaseConflict.GlobalManager.pas',
  BaseConflict.Globals.Client in '..\BaseConflict.Globals.Client.pas',
  BaseConflict.Globals in '..\BaseConflict.Globals.pas',
  BaseConflict.Map.Client in '..\BaseConflict.Map.Client.pas',
  BaseConflict.Map in '..\BaseConflict.Map.pas',
  BaseConflict.Settings.Client in '..\BaseConflict.Settings.Client.pas',
  BaseConflict.Types.Shared in '..\BaseConflict.Types.Shared.pas',
  BaseConflictMainUnit in '..\BaseConflictMainUnit.pas',
  BaseConflictSplash in '..\BaseConflictSplash.pas',
  Baseconflict.Tools.Main in 'Baseconflict.Tools.Main.pas',
  Baseconflict.Tools.PreloaderCache in 'Baseconflict.Tools.PreloaderCache.pas',
  Baseconflict.Tools.ScriptTest in 'Baseconflict.Tools.ScriptTest.pas',
  BaseConflict.EntityComponents.Server.Warheads in '..\GameServer\BaseConflict.EntityComponents.Server.Warheads.pas',
  BaseConflict.EntityComponents.Server.Welas in '..\GameServer\BaseConflict.EntityComponents.Server.Welas.pas',
  BaseConflict.EntityComponents.Server.Welas.Special in '..\GameServer\BaseConflict.EntityComponents.Server.Welas.Special.pas',
  BaseConflict.Classes.Server in '..\GameServer\BaseConflict.Classes.Server.pas',
  BaseConflict.Constants.Scenario.Server in '..\GameServer\BaseConflict.Constants.Scenario.Server.pas',
  BaseConflict.EntityComponents.Server.Brains in '..\GameServer\BaseConflict.EntityComponents.Server.Brains.pas',
  BaseConflict.EntityComponents.Server.Brains.Special in '..\GameServer\BaseConflict.EntityComponents.Server.Brains.Special.pas',
  BaseConflict.EntityComponents.Server in '..\GameServer\BaseConflict.EntityComponents.Server.pas',
  BaseConflict.EntityComponents.Server.Statistics in '..\GameServer\BaseConflict.EntityComponents.Server.Statistics.pas',
  Engine.Script in '..\..\Units\Engine.Script.pas',
  BaseConflict.Globals.Server in '..\GameServer\BaseConflict.Globals.Server.pas',
  BaseConflict.Game.Server in '..\GameServer\BaseConflict.Game.Server.pas',
  BaseConflict.Types.Server in '..\GameServer\BaseConflict.Types.Server.pas',
  Engine.Log in '..\..\Units\Engine.Log.pas',
  BaseConflict.Types.Client in '..\BaseConflict.Types.Client.pas';

var
  CommandManager : TCommandManager;
  Input : string;
  Selection : integer;

begin
  try
    HLog.OpenConsole;
    CommandManager := TCommandManager.Create;
    CommandManager.AddCommand(TScriptTestCommand.Create);
    CommandManager.AddCommand(TBuildPreloaderCacheCommand.Create);
    if ParamCount <= 1 then
    begin
      repeat
        HLog.ClearConsole;

        CommandManager.PrintOverview;
        WriteLn('exit: Close RoLTools');
        readln(Input);
        if TryStrToInt(Input, Selection) then
        begin
          HLog.ClearConsole;
          CommandManager.ExecuteCommand(Selection);
          WriteLn;
          WriteLn(' - Press any key to continue - ');
          readln;
        end;

      until SameText(Input, 'exit');
    end
    else
    begin
      CommandManager.ExecuteCommand(ParamStr(1));
    end;
  except
    on E : Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      readln;
    end;
  end;

end.
