unit BaseConflictMainUnit;

interface

uses
  // ----------- Delphi ------------
  System.UITypes,
  System.Classes,
  System.Types,
  System.SysUtils,
  System.Threading,
  System.SyncObjs,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.AppEvnts,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  System.Win.TaskbarCore,
  // ---------- ThirdParty --------
  FMOD.Common,
  FMOD.Studio.Common,
  FMOD.Studio.Classes,
  steam_api,
  steamclientpublic,
  {$IFDEF MADEXCEPT}
  madExcept,
  {$ENDIF}
  // ---------- Engine -----------
  {$IFDEF PROFILE_MEMORY}
  Engine.Profiler.Memory,
  {$ENDIF}
  Engine.Log,
  Engine.Input,
  Engine.Vertex,
  Engine.Network,
  Engine.Network.RPC,
  Engine.ParticleEffects,
  Engine.Physics,
  Engine.Core,
  Engine.Core.Types,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Script,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Gfxapi.Types,
  Engine.Mesh,
  Engine.Gfxapi,
  Engine.GUI,
  Engine.Posteffects,
  Engine.Serializer,
  {$IFDEF DEBUG}
  Engine.GUI.Editor,
  Engine.Posteffects.Editor,
  {$ENDIF}
  // --------- Game ------------
  BaseConflict.Api,
  BaseConflict.Api.Account,
  BaseConflict.Api.Chat,
  BaseConflict.Entity,
  BaseConflict.Globals,
  BaseConflict.Globals.Client,
  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Settings.Client,
  BaseConflict.Classes.Shared,
  BaseConflict.Classes.Client,
  BaseConflict.Classes.Gamestates,
  BaseConflict.EntityComponents.Shared.Wela,
  BaseConflict.EntityComponents.Client,
  BaseConflict.EntityComponents.Client.Sound;

type

  THauptform = class(TGameForm)
    ApplicationEvents1 : TApplicationEvents;
    procedure FormCreate(Sender : TObject);
    procedure ApplicationEvents1Idle(Sender : TObject; var Done : Boolean);
    procedure FormClose(Sender : TObject; var Action : TCloseAction);
    procedure FormMouseEnter(Sender : TObject);
    procedure ApplicationEvents1Activate(Sender : TObject);
    procedure OnFinishResize(var Msg : TWMMove); message WM_EXITSIZEMOVE;
    procedure FormConstrainedResize(Sender : TObject; var MinWidth, MinHeight, MaxWidth, MaxHeight : Integer);
    procedure ApplicationEvents1Deactivate(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure ApplicationEvents1Exception(Sender : TObject; E : Exception);
    private
      procedure LoadCursor(CursorIndex : Integer; CursorName : string);
      procedure RedirectEventsToEventbus(const Sender : RGUIEvent);
      procedure WMNCHitTest(var Message : TWMNCHitTest); message WM_NCHITTEST;
      procedure OnCallLogDataAvailable(const Data : TArray<RCallLogItem>);
    public
  end;

var
  NvOptimusEnablement : DWORD;
  AmdPowerXpressRequestHighPerformance : DWORD;

var
  Hauptform : THauptform;
  InputManager : TInputDeviceManager;
  GameStateManager : TGameStateManager;
  ShutdownApplication : Boolean;
  LastMaximizeState : System.UITypes.TWindowState;

  EMULATE_RELEASE : Boolean = {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};

  // try to hint the driver to automatically use dedicated graphics card to prevent graphic card removed error
exports
  NvOptimusEnablement, AmdPowerXpressRequestHighPerformance;

implementation

{$R *.dfm}

uses
  BaseConflictSplash;

procedure THauptform.FormCreate(Sender : TObject);
var
  KeyBinding : EnumKeybinding;
  SteamInitSuccessful : Boolean;
  SteamLanguageKey, BranchName, Key : string;
  BugReportServer, Item : string;
  BugReportPort : Integer;
  FMODInitFlags : FMOD_STUDIO_INITFLAGS;
begin
  Randomize;
  {$IFDEF PROFILE_MEMORY}
  MemoryProfiler := TMemoryProfiler.Create;
  MemoryProfiler.EnableProfiler;
  {$ENDIF}
  HLog.Log('Init started');
  LastMaximizeState := WindowState;
  // ///////////////////////////////////////////////////////////////////////////
  // Initialization of the game
  // ///////////////////////////////////////////////////////////////////////////
  HLog.Log('Init Steam');
  TRpcApi.OnCallLogDataAvailable := OnCallLogDataAvailable;
  {$IFDEF STEAM}
  SteamInitSuccessful := SteamAPI_Init;
  {$IFDEF RELEASE}
  if not SteamInitSuccessful then
  begin
    HLog.Log('Steam could not initialized');
    MessageDlg('Could not initialize Steam. Please try to restart Steam.', mtError, [mbOK], 0);
    ReportMemoryLeaksOnShutdown := False;
    Halt;
  end;
  HLog.Log('Steam initialized');
  {$ENDIF}
  {$ENDIF}
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  FormatSettings.DecimalSeparator := '.';

  // Load game cursor //////////////////////////////////////////////////////////
  HLog.Log('Init Cursor');
  LoadCursor(crIngame, 'Default');
  LoadCursor(crIngameHover, 'Hover');

  // Load Fonts // /////////////////////////////////////////////////////////////

  Engine.GUI.DefaultFontFamily := 'Proza Libre';
  // fonts are loaded via BaseConflict.Init.pas

  // Init Globals //////////////////////////////////////////////////////////////
  HLog.Log('Init Globals');
  GlobalEventbus := TEventbus.Create(nil);
  GlobalEntity := TEntity.Create(GlobalEventbus, -1);
  GameTimeManager := TTimeManager.Create;

  // Load Options //////////////////////////////////////////////////////////////
  HLog.Log('Init Settings');
  IsStaging := False;
  {$IFDEF STEAM}
  if assigned(SteamApps) and SteamApps.GetCurrentBetaName(BranchName) then
  begin
    CONNECTIONSETTINGSFILE := '\SettingsConnection' + BranchName + '.ini';
    if BranchName = 'staging' then
        IsStaging := True;
  end;
  {$ENDIF}
  {$IFDEF DEBUG}
  IsStaging := True;
  {$ENDIF}
  Settings := TOptionManager.Create();
  Settings.LoadSettings;

  EMULATE_RELEASE := Settings.GetBooleanOption(coDebugEmulateRelease);
  if EMULATE_RELEASE then
  begin
    LOAD_RAW_TEXTURE := True;
    LOAD_RAW_MESH := True;
    USE_ASSET_PRELOADER_CACHE := True;
    IsStaging := False;
  end;

  {$IFDEF MADEXCEPT}
  HLog.Log('Init Madexcept');
  BugReportServer := Settings.GetStringOption(coServerBugReportServer);
  // madexcept does not support url including port, so manually split it
  if BugReportServer.Contains(':') then
  begin
    // on default http using port 80
    BugReportPort := 80;
    for Item in HString.Split(BugReportServer, [':', '/']) do
      if TryStrToInt(Item, BugReportPort) then
          break;
    BugReportServer := BugReportServer.Replace(':' + BugReportPort.ToString, '');
    MESettings.HttpPort := BugReportPort;
    MESettings.HttpServer := AnsiString(BugReportServer);
  end
  else
  // on default http using port 80
  begin
    MESettings.HttpServer := AnsiString(BugReportServer);
    MESettings.HttpPort := 80;
  end;
  {$ENDIF}
  // Localization //////////////////////////////////////////////////////////////
  HLog.Log('Init Localization');
  HInternationalizer.LoadLangFiles(FormatDateiPfad(PATH_LANG), False, 'steam*');
  {$IFDEF STEAM}
  if SteamInitSuccessful and not Settings.IsSetNotNone(coGeneralLanguage) then
  begin
    SteamLanguageKey := SteamApps.GetCurrentGameLanguage;
    HInternationalizer.ChooseLanguage(HClient.MapSteamLanguageKeyToGame(SteamLanguageKey));
  end
  else
    {$ENDIF}
    if Settings.IsSetNotNone(coGeneralLanguage) then
        HInternationalizer.ChooseLanguage(Settings.GetStringOption(coGeneralLanguage));

  FormatSettings := TFormatSettings.Create(HInternationalizer.CurrentLanguageAsLocaleName);

  for Key in SteamLanguageKeys.Keys do
      SteamLanguageKeys[Key] := SteamLanguageKeys[Key].UpdateProgress;

  // Init Input ////////////////////////////////////////////////////////////////
  HLog.Log('Init Input');
  InputManager := TInputDeviceManager.Create(False, Handle);
  Mouse := InputManager.DirectInputFactory.ErzeugeTMouseDirectInput(False);
  Keyboard := InputManager.DirectInputFactory.ErzeugeTKeyboardDirectInput(False);
  KeybindingManager := TKeybindingManager<EnumKeybinding>.Create(Mouse, Keyboard);

  assert(ord(high(EnumKeybindingOptions)) - ord(low(EnumKeybindingOptions)) + 1 = ((ord(high(EnumKeybinding)) + 1) * 2), 'Invalid settings setup for keybindings! Did you add all new keybindings to the settings enumeration?');
  for KeyBinding := low(EnumKeybinding) to high(EnumKeybinding) do
  begin
    KeybindingManager.SetMapping(KeyBinding, 0, Settings.GetKeybinding(EnumClientOption(ord(coKeybindingBindingNone) + ord(KeyBinding) * 2)));
    KeybindingManager.SetMapping(KeyBinding, 1, Settings.GetKeybinding(EnumClientOption(ord(coKeybindingBindingNone) + ord(KeyBinding) * 2 + 1)));
  end;

  // Init Meta /////////////////////////////////////////////////////////////////
  HLog.Log('Init RPC');
  RPC_API_TIMEOUT := Settings.GetIntegerOption(coGeneralApiTimeout);
  HRPCHostManager.DefaultHost := Settings.GetStringOption(coServerWebApiServer);

  // Init Environment //////////////////////////////////////////////////////////
  HLog.Log('Init Environment');
  ScriptManager.Defines.Add('CLIENT');
  CursorInRenderpanel := True;

  // Init Sound ///////////////////////////////////////////////////////////
  HLog.Log('Init Sound');
  if Settings.GetBooleanOption(coEngineFMODConnectorEnabled) then
      FMODInitFlags := FMOD_STUDIO_INIT_LIVEUPDATE
  else
      FMODInitFlags := FMOD_STUDIO_INIT_NORMAL;
  SoundSystem := TFMODStudioSystem.Create(256, FMODInitFlags, FMOD_INIT_NORMAL, nil);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Master.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Master.strings.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/UI.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Music.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Shared.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Green.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Env.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Blue.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/White.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Colorless.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundSystem.LoadBankFile(FormatDateiPfad('Sound/Banks/Black.bank'), FMOD_STUDIO_LOAD_BANK_NORMAL);
  SoundMasterBus := SoundSystem.GetBus('bus:/master');
  SoundEffectBus := SoundSystem.GetBus('bus:/master/game');
  SoundMusicBus := SoundSystem.GetBus('bus:/master/music');
  SoundUIBus := SoundSystem.GetBus('bus:/master/ui');
  SoundPingBus := SoundSystem.GetBus('bus:/master/pings');

  // Init Graphics // //////////////////////////////////////////////////////////
  HLog.Log('Init Graphics');
  try
    GFXD := TGFXD.Create(Handle,
      False,
      Clientwidth,
      ClientHeight,
      True,
      Settings.GetBooleanOption(coGraphicsVSync),
      EnumAntialiasingLevel.aaNone,
      32,
      DirectX11Device,
      True);
  except
    if MessageDlg('The graphics couldn''t be initialized. Did you installed DirectX 11, updated your graphic drivers and your hardware meets the minimal requirements?',
      mtError, [mbClose, mbIgnore], 0) = mrIgnore then
        raise
    else
    begin
      Close;
      exit;
    end;
  end;

  GFXD.Settings.VSyncLevel := Settings.GetIntegerOption(coEngineVSyncLevel);


  // TRawMesh.PrecompileDefaultShaders;
  // TVertexEngine.PrecompileDefaultShaders;
  // ReportMemoryLeaksOnShutdown := False;
  // Halt;

  // graphics are initialized, now check vram
  if Settings.GetBooleanOption(coGeneralFirstStart) then
  begin
    HLog.Log('Check VRAM');
    // if dedicated video memory is lower than 900 MB lower settings
    if GFXD.Device3D.GetDedicatedVideoMemory < 900 * 1024 * 1024 then
    begin
      HLog.Log('VRAM too small, lower Graphics settings');
      TSettingsWrapper.WriteGraphicsQualityToSettings(gqVeryLow);
      Settings.SetEnumOption<EnumTextureQuality>(coGraphicsTextureQuality, tqMinimum);
      MessageDlg(HInternationalizer.Translate('§settings_message_low_memory'), mtWarning, [mbOK], 0);
    end
    else
        HLog.Log('VRAM ok');
    HLog.Log(GFXD.Device3D.GetVideoMemoryInfo);
    Settings.SetBooleanOption(coGeneralFirstStart, False);
    Settings.SaveSettings;
  end;

  HLog.Log('Init Graphic Globals');
  GFXD.Settings.DeferredShading := Settings.GetBooleanOption(coGraphicsDeferredShading);
  GFXD.MainScene.Backgroundcolor := $23373C;
  GFXD.MainScene.Camera.PerspectiveCamera(RVector3.Create(10, 10, 10), RVector3.ZERO);
  Color := RColor.Create(GFXD.MainScene.Backgroundcolor).AsBGRCardinal;

  HLog.Log('Init Pools');
  LinePool := TLinePool.Create(GFXD.MainScene, 500000);
  RHWLinePool := TRHWLinePool.Create(GFXD.MainScene);

  HLog.Log('Init Vertexengine');
  VertexEngine := TVertexEngine.Create(GFXD.MainScene);

  HLog.Log('Init Physicmanager');
  PhysicManager := TPhysicManager.Create;
  PhysicManager.AddForceField(TGlobalForceField.Create(RVector3.Create(0, -9.81, 0)));
  PhysicManager.AddObstacle(TPlaneObstacle.Create(RPlane.XZ.Translate(RVector3.Create(0, 0.2, 0))));

  HLog.Log('Init Particleeffects');
  ParticleEffectEngine := TParticleEffectEngine.Create(GFXD.MainScene, PhysicManager);
  ParticleEffectEngine.AssetPath := PATH_GRAPHICS_PARTICLE_EFFECTS;
  ParticleEffectEngine.DeferredShading := False;
  ParticleEffectEngine.Softparticlerange := 0.1;
  ParticleEffectEngine.Shadows := False;

  HLog.Log('Init Shadows');
  GFXD.MainScene.ShadowTechnique := EnumShadowTechnique.stShadowmapping;
  GFXD.MainScene.Shadowmapping.Shadowbias := 0.01;
  GFXD.MainScene.Shadowmapping.Slopebias := 0.5;

  HLog.Log('Init Posteffects');
  Posteffects := TPostEffectManager.CreateFromFile(GFXD.MainScene, AbsolutePath('PostEffects.fxs'));

  HLog.Log('Init Texturequality');
  TextureQualityManager.ClearOffsets;
  case Settings.GetEnumOption<EnumTextureQuality>(coGraphicsTextureQuality) of
    tqMaximum :
      begin
        // no reduction
        TextureQualityManager.DefaultOffset := 0;
      end;
    tqHigh :
      begin
        // reduction of textures shaped by meshes as the difference is not so big
        TextureQualityManager.DefaultOffset := 0;
        TextureQualityManager.AddOffset(PATH_GRAPHICS_GAMEPLAY, 1);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_UNITS, 1);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_EFFECTS, 1);
      end;
    tqMedium :
      begin
        // reduction of overall visual
        TextureQualityManager.DefaultOffset := 0;
        TextureQualityManager.AddOffset(PATH_MAP, 1);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_ENVIRONMENT, 1);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_GAMEPLAY, 2);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_UNITS, 2);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_EFFECTS, 2);
      end;
    tqLow :
      begin
        // strong reduction of all 3D
        TextureQualityManager.DefaultOffset := 0;
        TextureQualityManager.AddOffset(PATH_MAP, 2);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_ENVIRONMENT, 2);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_GAMEPLAY, 3);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_UNITS, 3);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_EFFECTS, 3);
      end;
    tqMinimum :
      begin
        // reduction of everything including UI
        TextureQualityManager.DefaultOffset := 1;
        TextureQualityManager.AddOffset(PATH_MAP, 2);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_ENVIRONMENT, 2);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_GAMEPLAY, 3);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_UNITS, 3);
        TextureQualityManager.AddOffset(PATH_GRAPHICS_EFFECTS, 3);
        TextureQualityManager.AddOffset(PATH_GUI, 1);
      end;
  end;

  // Init GUI //////////////////////////////////////////////////////////////////
  HLog.Log('Init GUI');
  GUI := TGUI.Create(GFXD.MainScene);
  Engine.GUI.GUI := GUI;
  GUI.AssetPath := PATH_GUI;
  GUI.StyleManager.LoadStylesFromFolder(PATH_STYLESHEETS);
  GUI.HintComponent := TGUIStackPanel.CreateFromFile(AbsolutePath(PATH_HINT_DEFAULT), GUI);
  GUI.HintDelay := 100;

  GUI.SubscribeToEvent(geAll, RedirectEventsToEventbus);

  // Init Global Components ////////////////////////////////////////////////////
  HLog.Log('Init Global components');
  SoundManager := TGlobalSoundManagerComponent.Create(GlobalEntity);
  TClientSettingsComponent.Create(GlobalEntity);

  // Init GameStates ///////////////////////////////////////////////////////////
  HLog.Log('Init Gamestates');
  EntityDataCache := TEntityDataCache.Create;

  // Manager publish serverstate to gui, so it has to be created before
  ServerState := TServerState.Create;
  GameStateManager := TGameStateManager.Create(self);
  GameStateManager.OnShutdown := procedure()
    begin
      ShutdownApplication := True;
    end;
  GameStateManager.AddNewGameState(TGameStateCoreGame.Create(GameStateManager), GAMESTATE_INGAME);
  GameStateManager.AddNewGameState(TGameStateMainMenu.Create(GameStateManager), GAMESTATE_MAINMENU);
  GameStateManager.AddNewGameState(TGameStateLoadCoreGame.Create(GameStateManager), GAMESTATE_LOADGAMESTATE);
  GameStateManager.AddNewGameState(TGameStateLoginSteam.Create(GameStateManager), GAMESTATE_LOGINSTEAM);
  GameStateManager.AddNewGameState(TGameStateLoginQueue.Create(GameStateManager), GAMESTATE_LOGIN_QUEUE);
  GameStateManager.AddNewGameState(TGameStateReconnect.Create(GameStateManager), GAMESTATE_RECONNECT);
  GameStateManager.AddNewGameState(TGameStateMaintenance.Create(GameStateManager), GAMESTATE_MAINTENANCE);
  GameStateManager.AddNewGameState(TGameStateServerDown.Create(GameStateManager), GAMESTATE_SERVER_DOWN);

  GFXD.FPSCounter.FrameLimit := Settings.GetIntegerOption(coMenuLimitFramerate);

  if Settings.GetBooleanOption(coDebugUseLocalTestServer) then
  begin
    SplashForm.Hide;
    Visible := True;
    GUI.LoadFromFile(GUI_ROOT_MAIN_FILENAME);
    GameStateManager.ChangeGameState(GAMESTATE_LOADGAMESTATE);
  end
  else
  begin
    HLog.Log('Check Server state');
    // Check if has access to server
    if not ServerState.UpdateServerStateSynchronous then
    begin
      HLog.Log('Servers state fetching failed');
      MessageDlg('Could not connect to the Rise of Legions servers. Please check your internet connection, firewall and antivirus to allow the game''s communication.', mtError, [mbOK], 0);
      ReportMemoryLeaksOnShutdown := False;
      Halt;
    end;
    HLog.Log('Server state fetched');

    if ServerState.ServerOffline or Settings.GetBooleanOption(coGeneralForceServerOffline) then
    begin
      HLog.Log('Server is offline');
      GameStateManager.ChangeGameState(GAMESTATE_SERVER_DOWN);
    end
    else if (ServerState.IsMaintenanceActive and not Settings.GetBooleanOption(coGeneralBypassMaintenance)) then
    begin
      HLog.Log('Server is in maintenance');
      GameStateManager.ChangeGameState(GAMESTATE_MAINTENANCE);
    end
    else
    begin
      HLog.Log('Server is online');
      {$IFDEF STEAM}
      if SteamInitSuccessful then
      begin
        HLog.Log('Enter Login Queue');
        GameStateManager.ChangeGameState(GAMESTATE_LOGIN_QUEUE);
      end
      else
      begin
        HLog.Log('Steam was not initialized, can''t enter login');
        MessageDlg('Login with steam failed.', mtError, [mbOK], 0);
        ReportMemoryLeaksOnShutdown := False;
        Halt;
      end;
      {$ELSE}
      GameStateManager.ChangeGameState(GAMESTATE_LOGIN_QUEUE);
      {$ENDIF}
    end;
  end;
  ContentManager.ObservationEnabled := Settings.GetBooleanOption(coEngineFileHotReload);
  // Finish, start gameloop ////////////////////////////////////////////////////
  ApplicationEvents1.OnIdle := ApplicationEvents1Idle;
end;

procedure THauptform.FormClose(Sender : TObject; var Action : TCloseAction);
begin
  {$IFDEF MADEXCEPT}
  madExcept.PauseMadExcept;
  {$ENDIF}
  {$IFDEF PROFILE_MEMORY}
  MemoryProfiler.Free;
  {$ENDIF}
  ShutdownApplication := True;
  FreeAndNil(MainActionQueue);
  FreeAndNil(GameStateManager);
  FreeAndNil(EntityDataCache);
  FreeAndNil(GlobalEntity);
  FreeAndNil(GlobalEventbus);
  FreeAndNil(GUI);
  FreeAndNil(Posteffects);
  FreeAndNil(RHWLinePool);
  FreeAndNil(SoundUIBus);
  FreeAndNil(SoundMasterBus);
  FreeAndNil(SoundMusicBus);
  FreeAndNil(SoundEffectBus);
  FreeAndNil(SoundPingBus);
  FreeAndNil(SoundSystem);
  FreeAndNil(ParticleEffectEngine);
  FreeAndNil(PhysicManager);
  FreeAndNil(VertexEngine);
  FreeAndNil(LinePool);
  FreeAndNil(KeybindingManager);
  FreeAndNil(Keyboard);
  FreeAndNil(Mouse);
  FreeAndNil(InputManager);
  SteamAPI_Shutdown;
  FreeAndNil(GameTimeManager);

  GFXD.Free;
  GFXD := nil; // FreeAndNil set to nil first and frees then, not possible here, as items use the reference on free
  FreeAndNil(Settings);
  try
    TRpcApi.FlushCallLog;
  except
    // mute anything
  end;
end;

procedure THauptform.FormConstrainedResize(Sender : TObject; var MinWidth, MinHeight, MaxWidth, MaxHeight : Integer);
begin
  MinWidth := 640;
  MinHeight := 450;
end;

procedure THauptform.FormMouseEnter(Sender : TObject);
begin
  if ShutdownApplication then exit;
  // only fetch mouse position if in windowed mode and has the focus
  if not GFXD.Settings.Fullscreen and Active then
  begin
    Mouse.Position := RIntVector2(ScreenToClient(Vcl.Controls.Mouse.CursorPos));
  end;
end;

procedure THauptform.FormShow(Sender : TObject);
begin
  BringToFront;
end;

procedure THauptform.LoadCursor(CursorIndex : Integer; CursorName : string);
begin
  CursorName := FormatDateiPfad(PATH_CURSOR + CursorName + '.ani');
  if not FileExists(CursorName) then CursorName := ChangeFileExt(CursorName, '.cur');
  if FileExists(CursorName) then
      Screen.Cursors[CursorIndex] := LoadCursorFromFile(PChar(CursorName));
end;

procedure THauptform.OnCallLogDataAvailable(const Data : TArray<RCallLogItem>);
begin
  if assigned(AccountApi) then
      AccountApi.SendApiLog(Data).Free;
end;

procedure THauptform.OnFinishResize(var Msg : TWMMove);
begin
  if assigned(GFXD) then
      GFXD.ChangeResolution(RIntVector2.Create(Clientwidth, ClientHeight));
end;

procedure THauptform.RedirectEventsToEventbus(const Sender : RGUIEvent);
begin
  if Sender.Event in [geClick, geRightClick, geChanged, geSubmit, geMouseDown] then
  begin
    GlobalEventbus.Trigger(eiGUIEvent, [RParam.From<RGUIEvent>(Sender)]);
  end;
end;

procedure THauptform.WMNCHitTest(var Message : TWMNCHitTest);
var
  Pt : TPoint;
begin
  Pt := ScreenToClient(SmallPointToPoint(message.Pos));
  if assigned(GameStateManager) and GameStateManager.IsClientWindow and not GameStateManager.IsFullscreen and (Pt.Y < 60) and
    assigned(GUI) and not GUI.IsMouseOverClickable and not GUI.IsMouseOverHint then
      message.Result := HTCAPTION
  else
      inherited;
end;

procedure THauptform.ApplicationEvents1Activate(Sender : TObject);
var
  MasterOption : EnumClientOption;
begin
  if ShutdownApplication or not assigned(GameStateManager) then exit;
  // fix problem with live binding to FMOD Studio
  if assigned(SoundMasterBus) then
  begin
    if not(SoundMasterBus.IsValid = FMOD_TRUE) then
    begin
      SoundMasterBus.Free;
      SoundMasterBus := SoundSystem.GetBus('bus:/master');
    end;
    if GameStateManager.IsGameWindow then MasterOption := coSoundPlayMaster
    else MasterOption := coSoundMetaPlayMaster;
    if Settings.GetBooleanOption(MasterOption) then SoundMasterBus.Unmute
    else SoundMasterBus.Mute;
  end;
  if assigned(Keyboard) then Keyboard.CleanButtonState;
end;

procedure THauptform.ApplicationEvents1Deactivate(Sender : TObject);
var
  MuteOption : EnumClientOption;
begin
  if assigned(GameStateManager) then
  begin
    if GameStateManager.IsGameWindow then MuteOption := coSoundBackground
    else MuteOption := coSoundMetaBackground;
    if assigned(SoundMasterBus) and not Settings.GetBooleanOption(MuteOption) then SoundMasterBus.Mute;
  end;
end;

procedure THauptform.ApplicationEvents1Exception(Sender : TObject; E : Exception);
begin
  ReportMemoryLeaksOnShutdown := False;
  if ShutdownApplication then
      TerminateProcess(GetCurrentProcess, 0);
end;

procedure THauptform.ApplicationEvents1Idle(Sender : TObject; var Done : Boolean);
var
  NewMousePosition : RIntVector2;
  Pointi : TPoint;
  Used : Boolean;
  i : Integer;
  ShadowDrawer : TPostEffectDrawDepthBuffer;
begin
  if PreventIdle then exit;
  if ShutdownApplication then
  begin
    Close;
    exit;
  end;
  Done := False;

  TimeManager.TickTack;
  GameTimeManager.TickTack;

  if assigned(TaskbarManager) then
  begin
    case Appstate of
      tsNone : TaskbarManager.ProgressState := TTaskBarProgressState.None;
      tsNormal : TaskbarManager.ProgressState := TTaskBarProgressState.Normal;
      tsError : TaskbarManager.ProgressState := TTaskBarProgressState.Error;
      tsPaused : TaskbarManager.ProgressState := TTaskBarProgressState.Paused;
      tsIndeterminate : TaskbarManager.ProgressState := TTaskBarProgressState.Indeterminate;
    end;
    TaskbarManager.ProgressMaxValue := AppProgressMax;
    TaskbarManager.ProgressValue := AppProgress;
  end;

  GUIInputUsed := [];
  InputManager.Idle;
  SoundSystem.Update;
  {$IFDEF STEAM}
  SteamAPI_RunCallbacks();
  {$ENDIF}
  if not GFXD.Settings.Fullscreen and CursorInRenderpanel then
  begin
    if not RRect.Create(0, 0, Clientwidth, ClientHeight).ContainsPoint(Mouse.Position) then
    begin
      NewMousePosition := ClientToScreen(TPoint(Mouse.Position));
      CursorInRenderpanel := False;
    end;
  end;

  Pointi := ScreenToClient(Vcl.Controls.Mouse.CursorPos);
  CursorInRenderpanel := ((0 <= Pointi.X) and (Width >= Pointi.X)) and ((0 <= Pointi.Y) and (Height >= Pointi.Y));
  Mouse.Position := RIntVector2(ScreenToClient(Vcl.Controls.Mouse.CursorPos));

  BaseConflict.Globals.Client.ClientWindowActive := Active;

  if Active and CursorInRenderpanel then
  begin
    // pass input to GUI
    GUI.HandleMouse(Mouse);
    if GUI.IsMouseOverGUI then GUIInputUsed := GUIInputUsed + [itMouse];
    if ShutdownApplication then exit;
  end
  else if CursorInRenderpanel then
  begin
    GUI.MouseMove(Mouse.Position);
  end;

  if Active then
  begin
    {$IFDEF DIRECTGAME}
    if Keyboard.KeyUp(TasteEsc) then
    begin
      if Keyboard.KeyIsDown(TasteShiftLinks) and GameStateManager.CanProgramClose then
      begin
        ShutdownApplication := True;
        exit;
      end;
    end;
    {$ENDIF}
    if KeybindingManager.KeyUp(kbScreenshot) then GFXD.ScreenShot(HFilepathManager.GetSpecialPath(spDesktop, Handle));

    Used := False;
    for i := 0 to Keyboard.DataFromLastFrame.Count - 1 do
    begin
      if Keyboard.DataFromLastFrame[i].Value then Used := GUI.KeyboardUp(Keyboard.DataFromLastFrame[i].Key) or Used
      else Used := GUI.KeyboardDown(Keyboard.DataFromLastFrame[i].Key) or Used;
      if ShutdownApplication then exit;
    end;
    if Used then GUIInputUsed := GUIInputUsed + [itKeyboard];

    {$IFDEF DEBUG}
    if KeybindingManager.KeyUp(kbGUIEditor) then GUI.ShowDebugForm;
    if KeybindingManager.KeyUp(kbPostEffectEditor) then Posteffects.ShowDebugForm;
    {$ENDIF}
  end;

  // handle fullscreen mode, only for ingame
  if GameStateManager.IsGameWindow then
  begin
    if (Settings.GetEnumOption<EnumDisplayMode>(coEngineDisplayMode) = dmWindowed) and (BorderStyle = bsNone) then
    begin
      self.BorderStyle := bsSizeable;
      Height := GameStateManager.TargetMonitor.WorkareaRect.Height;
      Width := GameStateManager.TargetMonitor.WorkareaRect.Width;
      if assigned(GFXD) then
          GFXD.ChangeResolution(RIntVector2.Create(Clientwidth, ClientHeight));
    end;
    if (Settings.GetEnumOption<EnumDisplayMode>(coEngineDisplayMode) = dmBorderlessFullscreenWindow) and (BorderStyle = bsSizeable) then
    begin
      self.BorderStyle := bsNone;
      Height := GameStateManager.TargetMonitor.Height;
      Width := GameStateManager.TargetMonitor.Width;
      Top := GameStateManager.TargetMonitor.Top;
      Left := GameStateManager.TargetMonitor.Left;
      if assigned(GFXD) then
          GFXD.ChangeResolution(RIntVector2.Create(Clientwidth, ClientHeight));
    end;
    if (LastMaximizeState <> WindowState) and assigned(GFXD) then
        GFXD.ChangeResolution(RIntVector2.Create(Clientwidth, ClientHeight));
    LastMaximizeState := WindowState;
  end;

  GlobalEventbus.Trigger(eiIdle, []);

  GameStateManager.Idle;
  GUI.ProcessEvents;
  GUI.Idle;
  ParticleEffectEngine.Idle;

  if Posteffects.TryGet<TPostEffectDrawDepthBuffer>('DrawDepthBuffer', ShadowDrawer) then
      ShadowDrawer.DepthBuffer := GFXD.MainScene.Shadowmapping.ShadowMap;

  GFXD.RenderTheWholeUniverseMegaGameProzedureDingMussNochLängerWerdenDeswegenHierMüllZeugsBlubsKeks;

  InputManager.EndFrame;
end;

initialization

NvOptimusEnablement := $1;
AmdPowerXpressRequestHighPerformance := $1;

end.
