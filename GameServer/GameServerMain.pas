unit GameServerMain;

interface

uses
  madExcept,
  Math,
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Engine.Network,
  Engine.Network.RPC,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Script,
  Engine.Serializer,
  Engine.Serializer.JSON,
  Engine.Log,
  BaseConflict.Globals,
  BaseConflict.Globals.Server,
  BaseConflict.Game,
  BaseConflict.Game.Server,
  BaseConflict.Classes.Shared,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Server,
  BaseConflict.EntityComponents.Server.Statistics,
  BaseConflict.Entity,
  BaseConflict.Constants,
  BaseConflict.Types.Shared,
  BaseConflict.Api,
  BaseConflict.Api.Account,
  BaseConflict.Api.Types,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Scenario,
  Generics.Collections,
  System.UITypes,
  IniFiles,
  idHttp,
  IdMultipartFormData,
  Vcl.AppEvnts,
  Vcl.StdCtrls,
  Vcl.Grids,
  Vcl.ValEdit,
  IdContext,
  IdCustomHTTPServer,
  IdBaseComponent,
  IdComponent,
  IdCustomTCPServer,
  IdHTTPServer,
  System.Rtti;

type

  ENotFound = class(Exception);
  EBadRequest = class(Exception);
  EObjectNotFound = class(ENotFound);
  EDataConflict = class(Exception);
  EForbidden = class(Exception);
  ECorruptData = class(Exception);

  TForm1 = class(TForm)
    ApplicationEvents1 : TApplicationEvents;
    LogList : TListBox;
    NetworkDisplay : TLabel;
    EventCounterDisplay : TValueListEditor;
    pnl1 : TPanel;
    Label1 : TLabel;
    GamesRunningEdt : TEdit;
    KillAllGamesBtn : TButton;
    HttpServer : TIdHTTPServer;
    CheatCheck : TCheckBox;
    BreakOnExceptionCheck : TCheckBox;
    SendGameTickBtn : TButton;
    LoadBalancingButton : TButton;
    ExcelFileOpenDialog : TOpenDialog;
    OverwatchChecked : TCheckBox;
    Panel1 : TPanel;
    StatusDisplay : TLabel;
    procedure FormCreate(Sender : TObject);
    procedure FormClose(Sender : TObject; var Action : TCloseAction);
    procedure ApplicationEvents1Idle(Sender : TObject; var Done : Boolean);
    procedure ClearEventLogBtnClick(Sender : TObject);
    procedure KillAllGamesBtnClick(Sender : TObject);
    procedure HttpServerCommandOther(AContext : TIdContext;
      ARequestInfo : TIdHTTPRequestInfo; AResponseInfo : TIdHTTPResponseInfo);
    procedure CheatCheckClick(Sender : TObject);
    procedure SendGameTickBtnClick(Sender : TObject);
    procedure LoadBalancingButtonClick(Sender : TObject);
    procedure OverwatchCheckedClick(Sender : TObject);
    procedure BreakOnExceptionCheckClick(Sender : TObject);
    procedure EventCounterDisplaySelectCell(Sender : TObject; ACol,
      ARow : Integer; var CanSelect : Boolean);
    private
      { Private-Deklarationen }
      FDisplayTimer : TTimer;
      FEventCounter : TDictionary<EnumEventIdentifier, Integer>;
      FBaseCaption : string;
    public
      procedure NewLogMessage(Message : string);
      procedure UpdateDisplayDataTimerTimer;
      procedure UpdateGameData;
  end;
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  Form1 : TForm1;
  FPS : TFPSCounter;
  GameManager : TGameManager;

implementation

{$R *.dfm}

{ TForm1 }

procedure TForm1.ApplicationEvents1Idle(Sender : TObject; var Done : Boolean);
begin
  try
    FPS.FrameTick;
    TimeManager.TickTack;
    Engine.Network.InfoData.Idle;
    if assigned(GameManager) then
        GameManager.Idle;
    if FDisplayTimer.Expired then
    begin
      FDisplayTimer.Start;
      UpdateDisplayDataTimerTimer;
      UpdateGameData;
    end;
    Done := False;
  except
    on e : Exception do
    begin
      ReportMemoryLeaksOnShutdown := False;
      raise;
    end;
  end;
end;

procedure TForm1.UpdateDisplayDataTimerTimer;
begin
  try
    Caption := FBaseCaption + ' - FPS: ' + FPS.getFPS.ToString;
    NetworkDisplay.Caption := 'Up:' + HString.IntToStrBandwidth(Engine.Network.InfoData.SendRate.GetDataRate) + sLineBreak +
      'SumUp:' + HString.IntToStrBandwidth(Engine.Network.InfoData.TotalSendedDataAmount) + sLineBreak +
      'Down:' + HString.IntToStrBandwidth(Engine.Network.InfoData.ReceiveRate.GetDataRate) + sLineBreak +
      'SumDown:' + HString.IntToStrBandwidth(Engine.Network.InfoData.TotalDataReceived);
    if assigned(GameManager) then
    begin
      StatusDisplay.Caption := 'Games Served: ' + Inttostr(GameManager.GamesServed);
      GamesRunningEdt.Text := Inttostr(GameManager.GamesRunning);
    end;
  except
    // mute every error
  end;
end;

procedure TForm1.UpdateGameData;
var
  row : Integer;
  GameThread : TGameThread;
begin
  try
    if assigned(GameManager) then
    begin
      for row := GameManager.GameThreads.Count + 1 to EventCounterDisplay.RowCount - 1 do
      begin
        EventCounterDisplay.Cells[0, row] := '';
        EventCounterDisplay.Cells[1, row] := '';
      end;
      row := 1;
      for GameThread in GameManager.GameThreads do
      begin
        if row >= EventCounterDisplay.RowCount then
            EventCounterDisplay.Strings.AddPair('', '');
        EventCounterDisplay.Cells[0, row] := GameThread.GameID;
        EventCounterDisplay.Cells[1, row] := HString.IntToLongTimeDetail(GameThread.TimeFromStart div 1000) + ' | P# ' + GameThread.ConnectedPlayerCount.ToString + ' | ' + GameThread.CurrentFrameRate.ToString + ' FPS';
        inc(row);
      end;
    end;
  except
    // mute every error
  end;
end;

procedure TForm1.ClearEventLogBtnClick(Sender : TObject);
begin
  FEventCounter.Clear;
  EventCounterDisplay.Strings.Clear;
end;

procedure TForm1.EventCounterDisplaySelectCell(Sender : TObject; ACol, ARow : Integer; var CanSelect : Boolean);
begin
  CanSelect := False;
end;

procedure TForm1.BreakOnExceptionCheckClick(Sender : TObject);
begin
  GameManager.BreakOnException := BreakOnExceptionCheck.Checked;
end;

procedure TForm1.CheatCheckClick(Sender : TObject);
begin
  Cheatmode := CheatCheck.Checked;
end;

procedure TForm1.FormClose(Sender : TObject; var Action : TCloseAction);
begin
  FreeAndNil(GameManager);
  FreeAndNil(BalancingManager);
  FreeAndNil(FDisplayTimer);
  FreeAndNil(FPS);
  FreeAndNil(FEventCounter);
  FreeAndNil(GameTimeManager);
end;

procedure TForm1.FormCreate(Sender : TObject);
var
  SETTINGSFILE : TIniFile;
  TargetMonitor, ServerInstanceIndex : Integer;
begin
  FormatSettings.DecimalSeparator := '.';
  Randomize;
  FDisplayTimer := TTimer.Create(1000);
  HLog.LogFilePath := ExtractFilePath(Application.ExeName) + 'Logs\';
  ForceDirectories(HLog.LogFilePath);
  if MULTITHREADING_ENABLED then
  begin
    HLog.ThreadLogging := True;
    HFileIO.DeleteAllFilesInDirectory(HLog.LogFilePath);
  end;
  // use a dir up as basepath, because the server use the same Resources as client (e.g. skripts)
  HFilepathManager.RelativeWorkingPath := '\..\';
  // load settings
  if FileExists(FormatDateiPfad(GAMESERVER_SETTINGSFILE)) then
  begin
    SETTINGSFILE := TIniFile.Create(FormatDateiPfad(GAMESERVER_SETTINGSFILE));
    GAMESERVER_OUTBOUND_IP := SETTINGSFILE.ReadString('Server', 'GAMESERVER_OUTBOUND_IP', GAMESERVER_OUTBOUND_IP);
    GAMESERVER_HTTP_PORT := SETTINGSFILE.ReadInteger('Server', 'GAMESERVER_HTTP_PORT', GAMESERVER_HTTP_PORT);
    GAMESERVER_PORTRANGE_MIN := SETTINGSFILE.ReadInteger('Server', 'GAMESERVER_PORTRANGE_MIN', GAMESERVER_PORTRANGE_MIN);
    GAMESERVER_PORTRANGE_MAX := SETTINGSFILE.ReadInteger('Server', 'GAMESERVER_PORTRANGE_MAX', GAMESERVER_PORTRANGE_MAX);
    GAMESERVER_PORTRANGE_LENGTH := GAMESERVER_PORTRANGE_MAX - GAMESERVER_PORTRANGE_MIN + 1;
    FBaseCaption := SETTINGSFILE.ReadString('Server', 'GAMESERVER_CAPTION', '!Caption entry missing!');
    MANAGE_SERVER_URL := SETTINGSFILE.ReadString('Connection', 'MANAGE_SERVER_URL', MANAGE_SERVER_URL);
    SETTINGSFILE.Free;
  end;
  {$IFDEF DEBUG}
  CheatCheck.Checked := False;
  // if there any debug settings, override standard settings with debug settings
  if FileExists(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE)) then
  begin
    SETTINGSFILE := TIniFile.Create(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE));
    GAMESERVER_OUTBOUND_IP := SETTINGSFILE.ReadString('Server', 'GAMESERVER_OUTBOUND_IP', GAMESERVER_OUTBOUND_IP);
    GAMESERVER_HTTP_PORT := SETTINGSFILE.ReadInteger('Server', 'GAMESERVER_HTTP_PORT', GAMESERVER_HTTP_PORT);
    GAMESERVER_PORTRANGE_MIN := SETTINGSFILE.ReadInteger('Server', 'GAMESERVER_PORTRANGE_MIN', GAMESERVER_PORTRANGE_MIN);
    GAMESERVER_PORTRANGE_MAX := SETTINGSFILE.ReadInteger('Server', 'GAMESERVER_PORTRANGE_MAX', GAMESERVER_PORTRANGE_MAX);
    GAMESERVER_PORTRANGE_LENGTH := GAMESERVER_PORTRANGE_MAX - GAMESERVER_PORTRANGE_MIN + 1;
    CheatCheck.Checked := SETTINGSFILE.ReadBool('Server', 'GAMESERVER_CHEATS_ENABLED', CheatCheck.Checked);
    TESTSERVER_SCENARIO_UID := SETTINGSFILE.ReadString('Server', 'TESTSERVER_SCENARIO_UID', TESTSERVER_SCENARIO_UID);
    TESTSERVER_SENARIO_LEAGUE := SETTINGSFILE.ReadInteger('Server', 'TESTSERVER_SCENARIO_LEAGUE', TESTSERVER_SENARIO_LEAGUE);
    FBaseCaption := SETTINGSFILE.ReadString('Server', 'GAMESERVER_CAPTION', FBaseCaption);
    MANAGE_SERVER_URL := SETTINGSFILE.ReadString('Connection', 'MANAGE_SERVER_URL', MANAGE_SERVER_URL);
    SETTINGSFILE.Free;
  end;
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  // position window
  if (Screen.MonitorCount > 1) then
  begin
    TargetMonitor := 1;
    if Screen.MonitorCount > 2 then TargetMonitor := 2;
    if Screen.MonitorCount > 3 then TargetMonitor := 1;
    Left := Screen.Monitors[TargetMonitor].Left + Screen.Monitors[TargetMonitor].Width div 2 - Width div 2;
    Top := Screen.Monitors[TargetMonitor].Top + Screen.Monitors[TargetMonitor].Height div 2 - Height div 2;
  end
  else
  begin
    if (length(FBaseCaption) > 0) and TryStrToInt(FBaseCaption[length(FBaseCaption)], ServerInstanceIndex) then
    begin
      Left := Screen.Monitors[0].Left + Screen.Monitors[0].Width - ((Width + 2) * (3 - (ServerInstanceIndex mod 3)) + 2);
      Top := Screen.Monitors[0].Top + (Height + 5) * (ServerInstanceIndex div 3) + 40;
    end;
  end;

  HRPCHostManager.DefaultHost := MANAGE_SERVER_URL;
  GameTimeManager := TTimeManager.Create;
  GameManager := TGameManager.Create(NewLogMessage);
  FPS := TFPSCounter.Create(60);
  FEventCounter := TDictionary<EnumEventIdentifier, Integer>.Create;
  // start the http server that receive commands from manage server
  HttpServer.DefaultPort := GAMESERVER_HTTP_PORT;
  HttpServer.Active := True;
  ExcelFileOpenDialog.InitialDir := FormatDateiPfad('..\Dokumente\Base Conflict');
  EventCounterDisplay.Selection := TGridRect(Rect(-1, -1, -1, -1));
  ContentManager.ObservationEnabled := True;
end;

procedure TForm1.HttpServerCommandOther(AContext : TIdContext; ARequestInfo : TIdHTTPRequestInfo; AResponseInfo : TIdHTTPResponseInfo);
var
  ResultValue : TValue;
  data, identifier : string;
  ErrorMsg : string;
begin
  if ARequestInfo.CommandType = hcPOST then
  begin
    if (ARequestInfo.Params.IndexOfName('data') < 0) then raise EBadRequest.Create('Parameter data not found.');
    identifier := ARequestInfo.URI;
    data := ARequestInfo.Params.Values['data'];
    ErrorMsg := '';
    DoSynchronized(
      procedure()
      begin
        try
          ResultValue := RPCHandlerManager.CallHandlerWithResult(identifier, data);
        except
          on e : Exception do
          begin
            // also report bug to window
            NewLogMessage('[EXCEPTION] "' + e.Message + '"!');
            ErrorMsg := CreateBugReport(etNormal);
            // if an error occurs, use madexcept to send a bugreport
            if not GameManager.BreakOnException then
            begin
              AutoSaveBugReport(ErrorMsg, nil);
              AutoSendBugReport(ErrorMsg, nil);
            end
            else raise;
          end;
        end;
      end);

    // when all was fine, return call result, else the exception traceback
    if ErrorMsg.IsEmpty then
    begin
      AResponseInfo.ResponseNo := 200;
      AResponseInfo.ContentText := TJSONSerializer.SerializeValue(ResultValue);
    end
    else
    begin
      AResponseInfo.ResponseNo := 500;
      AResponseInfo.ContentText := ErrorMsg;
    end;
  end
  else
      AResponseInfo.ResponseNo := 405;
end;

procedure TForm1.KillAllGamesBtnClick(Sender : TObject);
begin
  GameManager.KillAllGames;
end;

procedure TForm1.LoadBalancingButtonClick(Sender : TObject);
begin
  if ExcelFileOpenDialog.Execute then
  begin
    BalancingManager.LoadExcelFile(ExcelFileOpenDialog.Filename);
    BalancingManager.Apply;
  end;
end;

procedure TForm1.NewLogMessage(Message : string);
begin
  if Form1.LogList.Items.Count >= 15 then
      Form1.LogList.Items.Delete(0);
  Form1.LogList.Items.Add('[' + DateToStr(Date) + ' ' + TimeToStr(Time) + '] ' + message);
end;

procedure TForm1.OverwatchCheckedClick(Sender : TObject);
begin
  Overwatch := OverwatchChecked.Checked;
end;

procedure TForm1.SendGameTickBtnClick(Sender : TObject);
begin
  GameManager.SendGameTick;
end;

end.
