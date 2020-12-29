unit MapEditorMain;

interface

uses
  Windows,
  Messages,
  SysUtils,
  AppEvnts,
  Variants,
  Graphics,
  Controls,
  Forms,
  Engine.Vertex,
  Dialogs,
  System.UITypes,
  Engine.Log,
  Engine.Core,
  Engine.Core.Types,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Animation,
  ExtCtrls,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.VCLUtils,
  Engine.Pathfinding.Helper,
  Math,
  StdCtrls,
  Menus,
  Engine.Mesh,
  Engine.Input,
  System.Classes,
  Engine.Serializer,
  Vcl.Grids,
  Vcl.ComCtrls,
  Shellapi,
  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Globals,
  FileCtrl,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.ParticleEffects,
  Engine.Physics,
  Engine.Sound,
  BaseConflict.Classes.Client,
  BaseConflict.Classes.Gamestates.GUI,
  BaseConflict.EntityComponents.Client,
  BaseConflict.EntityComponents.Client.Visuals,
  BaseConflict.EntityComponents.Client.Debug,
  BaseConflict.Settings.Client,
  Engine.Collision,
  Engine.Terrain,
  Engine.Terrain.Editor,
  Engine.Water,
  Engine.Water.Editor,
  Engine.Vegetation,
  Engine.Vegetation.Editor,
  Engine.Script,
  Engine.PostEffects,
  Engine.PostEffects.Editor,
  Vcl.ValEdit,
  BaseConflict.Entity,
  BaseConflict.Map,
  BaseConflict.Map.Client,
  BaseConflict.Globals.Client,
  Vcl.Samples.Spin,
  Generics.Collections,
  Vcl.Buttons,
  LightManagerFormUnit,
  ClipBrd;

type

  THauptform = class(TForm)
    ApplicationEvents1 : TApplicationEvents;
    MainMenu1 : TMainMenu;
    Datei1 : TMenuItem;
    Beenden1 : TMenuItem;
    MapSaveDialog : TSaveDialog;
    N1 : TMenuItem;
    Neu1 : TMenuItem;
    Open1 : TMenuItem;
    Save1 : TMenuItem;
    Saveas1 : TMenuItem;
    View1 : TMenuItem;
    RenderPanel : TPanel;
    MapOpenDialog : TOpenDialog;
    StatusBar : TStatusBar;
    erraineditor1 : TMenuItem;
    ShowGrid1 : TMenuItem;
    SnaptoGrid1 : TMenuItem;
    Snaptogrid : TMenuItem;
    WaterEditor1 : TMenuItem;
    Vegetationeditor1 : TMenuItem;
    Limitcamera1 : TMenuItem;
    Sceneeditor1 : TMenuItem;
    ResetCamera1 : TMenuItem;
    Window1 : TMenuItem;
    ShowWater1 : TMenuItem;
    TargetGamePlaneCheck : TMenuItem;
    ShowZonesCheck : TMenuItem;
    VerticalCamera1 : TMenuItem;
    BuildPopupMenu : TPopupMenu;
    BuildAddGrid : TMenuItem;
    BuildDeleteGrid : TMenuItem;
    ShowReferenceEntities1 : TMenuItem;
    Posteffects1 : TMenuItem;
    MapEditor1 : TMenuItem;
    FreeCameraCheck : TMenuItem;
    SetBackgroundColor1 : TMenuItem;
    ColorDialog1 : TColorDialog;
    ShowMaterialEditorBtn : TMenuItem;
    GraphicReduction1 : TMenuItem;
    ReferenceOpenDialog : TOpenDialog;
    LoadReferenceEntitiesfromFile1 : TMenuItem;
    ShowVegetation1 : TMenuItem;
    ShowDropzonesCheck : TMenuItem;
    procedure FormCreate(Sender : TObject);
    procedure ApplicationEvents1Idle(Sender : TObject; var Done : Boolean);
    procedure FormClose(Sender : TObject; var Action : TCloseAction);
    procedure Beenden1Click(Sender : TObject);
    procedure Neu1Click(Sender : TObject);
    procedure Open1Click(Sender : TObject);
    procedure Save1Click(Sender : TObject);
    procedure Saveas1Click(Sender : TObject);
    procedure BigChange(Sender : TObject);
    procedure ShowEditorClick(Sender : TObject);
    procedure FormActivate(Sender : TObject);
    procedure FormDeactivate(Sender : TObject);
    procedure RenderPanelResize(Sender : TObject);
    procedure Posteffects1Click(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure MapEditor1Click(Sender : TObject);
    procedure SetBackgroundColor1Click(Sender : TObject);
    procedure ShowMaterialEditorBtnClick(Sender : TObject);
    procedure GraphicReduction1Click(Sender : TObject);
    procedure ApplicationEvents1Exception(Sender : TObject; E : Exception);
    procedure LoadReferenceEntitiesfromFile1Click(Sender : TObject);
    private
      { Private-Deklarationen }
    public
      originalPanelWindowProc : TWndMethod;
      procedure DragAndDropWindowProc(var Msg : TMessage);
      procedure DropFile(Msg : TWMDROPFILES);

      function MausInRenderpanel : Boolean;
      procedure Load(Path : string);
      procedure LoadReferenceEntities(const Path : string);
      procedure ToggleFullscreenMode;
      { Public-Deklarationen }
  end;

  TEditorModule = class
    protected
      FMouse : TMouse;
      FKeyboard : TKeyboard;
      FActive, FDefault : Boolean;
      procedure SetActive(State : Boolean); virtual;
      procedure SyncFromGUI; virtual;
      procedure SyncToGUI; virtual;
      procedure GUIEvent(Sender : TObject); virtual;
      procedure Init; virtual;
      procedure SaveMap(const Filename : string); virtual;
      procedure LoadMap(const Filename : string); virtual;
    public
      property DefaultModule : Boolean read FDefault;
      property Active : Boolean read FActive write SetActive;
      constructor Create(Mouse : TMouse; Keyboard : TKeyboard);
      procedure Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay); virtual;
      procedure MouseDown(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay); virtual;
      procedure MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay); virtual;
      destructor Destroy; override;
  end;

  CModule = class of TEditorModule;

  TEditorModuleManager = class
    protected
      FMouse : TMouse;
      FKeyboard : TKeyboard;
      FModules : TObjectList<TEditorModule>;
    public
      property Modules : TObjectList<TEditorModule> read FModules;
      constructor Create(Mouse : TMouse; Keyboard : TKeyboard);
      procedure ActivateModule(Module : CModule);
      procedure DeActivateModule(Module : CModule);
      procedure DeactivateAllModules();
      procedure SyncToGUI(Module : CModule);
      procedure GUIEvent(Sender : TObject);
      function GetModule<T : class>() : T;
      procedure SaveMap(const Filename : string);
      procedure LoadMap(const Filename : string);
      /// <summary> Should be called everytime a new map has been loaded. </summary>
      procedure Init;
      procedure Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay);
      destructor Destroy; override;
  end;

  TZoneModule = class(TEditorModule)
    protected
      StartPoint, EndPoint : RVector2;
      FPathfinding : TMultipolygonPathfinding;
      procedure SyncToGUI; override;
      procedure SetActive(State : Boolean); override;
      procedure GUIEvent(Sender : TObject); override;
    public
      constructor Create(Mouse : TMouse; Keyboard : TKeyboard);
      procedure ExportSelectedZone;
      procedure Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay); override;
      procedure MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay); override;
      destructor Destroy; override;
  end;

  TLaneHack = class(TLane)

  end;

  TLaneModule = class(TEditorModule)
    protected
      StartPoint : RVector2;
      procedure SyncToGUI; override;
      procedure SetActive(State : Boolean); override;
      procedure GUIEvent(Sender : TObject); override;
    public
      constructor Create(Mouse : TMouse; Keyboard : TKeyboard);
      procedure Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay); override;
      procedure MouseDown(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay); override;
      procedure MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay); override;
      destructor Destroy; override;
  end;

  REntityDescription = record
    Position, Front : RVector3;
    Size : single;
    ScriptFile : string;
    Freezed : Boolean;
    // only editor
    DragOffset : RVector3;
  end;

  TPlaceEntityModule = class(TEditorModule)
    protected
      FSupressFieldSync, FSeenDown : Boolean;
      FLastRotation : single;
      UnitsFileList : TStrings;
      ModelDragging, ModelAnchored, Visible : Boolean;
      DragOffset : RVector3;
      EntityToSet : TEntity;
      procedure RefreshEntityFields; virtual;
      procedure PickEntity(KeepSelected : Boolean; Clickvector : RRay);
      procedure SyncToGUI; override;
      procedure SetActive(State : Boolean); override;
      procedure GUIEvent(Sender : TObject); override;
      procedure RefreshEntityFileList; virtual; abstract;
      function GetCorrespondingTab : TCategoryPanel; virtual; abstract;
      function GetPatternList : TListBox; virtual; abstract;
      function GetEntityList : TListBox; virtual; abstract;
      procedure RemoveEntity(index : integer); virtual; abstract;
      procedure ManipulateEntity; virtual; abstract;
      function GetEntityDescription(index : integer) : REntityDescription; virtual; abstract;
      procedure UpdateEntityDescription(index : integer; Desc : REntityDescription); virtual;
      procedure AddEntity(Desc : REntityDescription); virtual; abstract;
      function GetBoundingsOfEntity(index : integer) : RSphere; virtual; abstract;
      function GetEntityCount : integer; virtual; abstract;
      function SelectionIsFreezed : Boolean; virtual;
      function GetCenterOfSelection : RVector3;
      procedure DuplicateEntity(index : integer);
      function GetEntityByIndex(index : integer) : TEntity; virtual; abstract;
    public
      constructor Create(Mouse : TMouse; Keyboard : TKeyboard);
      procedure Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay); override;
      procedure MouseDown(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay); override;
      procedure MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay); override;
      destructor Destroy; override;
  end;

  // For doodads and deco objects placed in the world just for visual appearance
  TDecoModule = class(TPlaceEntityModule)
    protected
      const
      DECO_ENTITY_PATH = PATH_SCRIPT_ENVIRONMENT;
    var
      procedure GUIEvent(Sender : TObject); override;
      function MigrateDesc(a : REntityDescription) : RDecoEntityDescription;
      function MigrateDescReverse(a : RDecoEntityDescription) : REntityDescription;
      procedure RefreshEntityFileList; override;
      procedure RefreshEntityFields; override;
      procedure RemoveEntity(index : integer); override;
      procedure ManipulateEntity; override;
      function GetEntityDescription(index : integer) : REntityDescription; override;
      procedure UpdateEntityDescription(index : integer; Desc : REntityDescription); override;
      procedure AddEntity(Desc : REntityDescription); override;
      function GetBoundingsOfEntity(index : integer) : RSphere; override;
      function GetCorrespondingTab : TCategoryPanel; override;
      function GetPatternList : TListBox; override;
      function GetEntityList : TListBox; override;
      function GetEntityCount : integer; override;
      function GetEntityByIndex(index : integer) : TEntity; override;
  end;

  // For units and other game entites, placed in the world for reference. Not transported in final game.
  TReferenceModule = class(TPlaceEntityModule)
    protected
      FWalkerIndices : TList<integer>;
      FWalkerProgress : TTimer;
      FReferenceEntitiesRaw : TList<REntityDescription>;
      FReferenceEntities : TObjectList<TEntity>;
      procedure SaveMap(const Filename : string); override;
      procedure LoadMap(const Filename : string); override;
      procedure GUIEvent(Sender : TObject); override;
      procedure RefreshEntityFileList; override;
      procedure RemoveEntity(index : integer); override;
      procedure ManipulateEntity; override;
      function GetEntityDescription(index : integer) : REntityDescription; override;
      procedure UpdateEntityDescription(index : integer; Desc : REntityDescription); override;
      procedure AddEntity(Desc : REntityDescription); override;
      function GetBoundingsOfEntity(index : integer) : RSphere; override;
      function GetCorrespondingTab : TCategoryPanel; override;
      function GetPatternList : TListBox; override;
      function GetEntityList : TListBox; override;
      function GetEntityCount : integer; override;
      function SelectionIsFreezed : Boolean; override;
      function GetEntityByIndex(index : integer) : TEntity; override;
    public
      constructor Create(Mouse : TMouse; Keyboard : TKeyboard);
      procedure LoadReferenceFile(const Filename : string);
      procedure CopyEntitiesToClipboard;
      procedure Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay); override;
      destructor Destroy; override;
  end;

var
  Hauptform : THauptform;
  Input : TInputDeviceManager;
  MountedFile : string;

  MausPos : RIntVector2;
  Cam : TClientCameraComponent;
  ModuleManager : TEditorModuleManager;
  PostEffectManager : TPostEffectManager;
  DropZoneRenderer : TZoneRenderer;

implementation

uses
  MapEditorToolBox;

{$R *.dfm}


procedure THauptform.FormCreate(Sender : TObject);
var
  KeyBinding : EnumKeybinding;
begin
  {$IFDEF DEBUG} ReportMemoryLeaksOnShutdown := DebugHook <> 0; {$ENDIF}
  FormatSettings.DecimalSeparator := '.';
  Application.HintHidePause := 5000;
  ContentManager.ObservationEnabled := True;
  HFilepathManager.RelativeWorkingPath := '\..\';
  MapSaveDialog.InitialDir := AbsolutePath(PATH_MAP);
  MapOpenDialog.InitialDir := AbsolutePath(PATH_MAP);

  // Init Globals //////////////////////////////////////////////////////////////
  GlobalEventbus := TEventbus.Create(nil);
  GlobalEntity := TEntity.Create(GlobalEventbus);
  GameTimeManager := TTimeManager.Create;

  // Load Options //////////////////////////////////////////////////////////////
  Settings := TOptionManager.Create();
  Settings.LoadSettings;

  // Init Input ////////////////////////////////////////////////////////////////
  Input := TInputDeviceManager.Create(False, RenderPanel.Handle);
  Mouse := Input.DirectInputFactory.ErzeugeTMouseDirectInput(False);
  Keyboard := Input.DirectInputFactory.ErzeugeTKeyboardDirectInput(False);
  KeybindingManager := TKeybindingManager<EnumKeybinding>.Create(Mouse, Keyboard);

  assert((ord(high(EnumKeybindingOptions)) - ord(low(EnumKeybindingOptions)) - 1) = ((ord(high(EnumKeybinding)) + 1) * 2), 'Invalid settings setup for keybindings! Did you add all new keybindings to the settings enumeration?');
  for KeyBinding := low(EnumKeybinding) to high(EnumKeybinding) do
  begin
    KeybindingManager.SetMapping(KeyBinding, 0, Settings.GetKeybinding(EnumClientOption(ord(coKeybindingOptionsStart) + 1 + ord(KeyBinding) * 2)));
    KeybindingManager.SetMapping(KeyBinding, 1, Settings.GetKeybinding(EnumClientOption(ord(coKeybindingOptionsStart) + 1 + ord(KeyBinding) * 2 + 1)));
  end;

  // Init Environment //////////////////////////////////////////////////////////
  TXMLSerializer.CacheXMLDocuments := False;
  ScriptManager.UnitSearchPath := AbsolutePath(PATH_SCRIPT_UNITS);
  ScriptManager.Defines.Add('CLIENT');
  ScriptManager.Defines.Add('MAPEDITOR');

  // Init Graphics // //////////////////////////////////////////////////////////
  try
    GFXD := TGFXD.Create(RenderPanel.Handle,
      False,
      RenderPanel.Width,
      RenderPanel.Height,
      True,
      False,
      EnumAntialiasingLevel.aaNone,
      32,
      DirectX11Device,
      not IsDebuggerPresent or True);
  except
    on E : EGraphicInitError do
    begin
      MessageDlg('The graphics couldn''t be initialized. Did you installed DirectX 11, updated your graphic drivers and your hardware meets the minimal requirements?',
        mtError, [mbClose], 0);
      Close;
      exit;
    end;
  end;
  GFXD.Settings.DeferredShading := Settings.GetBooleanOption(coGraphicsDeferredShading);
  GFXD.MainScene.Backgroundcolor := $23373C;
  Color := RColor.Create(GFXD.MainScene.Backgroundcolor).AsBGRCardinal;

  LinePool := TLinePool.Create(GFXD.MainScene, 500000);
  RHWLinePool := TRHWLinePool.Create();

  VertexEngine := TVertexEngine.Create(GFXD.MainScene);
  PhysicManager := TPhysicManager.Create;
  PhysicManager.AddForceField(TGlobalForceField.Create(RVector3.Create(0, -9.81, 0)));
  PhysicManager.AddObstacle(TPlaneObstacle.Create(RPlane.XZ.Translate(RVector3.Create(0, 0.2, 0))));

  ParticleEffectEngine := TParticleEffectEngine.Create(GFXD.MainScene, PhysicManager);
  ParticleEffectEngine.AssetPath := PATH_GRAPHICS_PARTICLE_EFFECTS;
  ParticleEffectEngine.DeferredShading := False;
  ParticleEffectEngine.Softparticlerange := 0.1;
  ParticleEffectEngine.Shadows := False;

  GFXD.MainScene.Camera.PerspectiveCamera(RVector3.Create(10, 10, 10), RVector3.ZERO);

  GFXD.MainScene.ShadowTechnique := EnumShadowTechnique.stShadowmapping;
  GFXD.MainScene.ShadowMapping.Resolution := 4096;
  GFXD.MainScene.ShadowMapping.Shadowbias := 0.01;
  GFXD.MainScene.ShadowMapping.Slopebias := 0.5;

  PostEffectManager := TPostEffectManager.Create(GFXD.MainScene);
  if HFilepathManager.FileExists('/Editor/PostEffects.fxs') then
      PostEffectManager.LoadFromFile(AbsolutePath('/Editor/PostEffects.fxs'));

  // Init MapEditor //////////////////////////////////////////////////////////

  DragAcceptFiles(Self.Handle, True);
  Self.originalPanelWindowProc := Self.WindowProc;
  Self.WindowProc := DragAndDropWindowProc;

  HUD := TIngameHUD.Create;
  HUD.CameraLimited := Limitcamera1.Checked;
  Cam := TClientCameraComponent.Create(GlobalEntity);
  Cam.Vertical := VerticalCamera1.Checked;
  Cam.FreeCamera := FreeCameraCheck.Checked;
  Cam.EnableScrollingBorder := False;

  ModuleManager := TEditorModuleManager.Create(Mouse, Keyboard);
  ModuleManager.Modules.Add(TZoneModule.Create(Mouse, Keyboard));
  ModuleManager.Modules.Add(TDecoModule.Create(Mouse, Keyboard));
  ModuleManager.Modules.Add(TLaneModule.Create(Mouse, Keyboard));
  ModuleManager.Modules.Add(TReferenceModule.Create(Mouse, Keyboard));
  ModuleManager.ActivateModule(TDecoModule);

  Neu1Click(Self);
  if ParamStr(1) <> '' then Load(ParamStr(1));
end;

procedure THauptform.FormDeactivate(Sender : TObject);
begin
  GFXD.FPSCounter.FrameLimit := 5;
end;

procedure THauptform.FormShow(Sender : TObject);
begin
  Height := Screen.PrimaryMonitor.WorkareaRect.Height;
  Width := Screen.PrimaryMonitor.WorkareaRect.Width;
  Top := Screen.PrimaryMonitor.WorkareaRect.Top;
  Left := Screen.PrimaryMonitor.WorkareaRect.Left;
end;

procedure THauptform.GraphicReduction1Click(Sender : TObject);
begin
  GFXD.Settings.DeferredShading := False;
  PostEffectManager.Clear;
  GFXD.MainScene.ShadowMapping.Resolution := 1024;
  ShowWater1.Checked := False;
end;

procedure THauptform.FormClose(Sender : TObject; var Action : TCloseAction);
begin
  SoundManager.Free;
  ModuleManager.Free;
  Settings.Free;
  DropZoneRenderer.Free;
  Map.Free;
  ClientMap.Free;
  VertexEngine.Free;
  GlobalEventbus.Trigger(eiFree, []);
  GlobalEntity.Free;
  GlobalEventbus.Free;
  ParticleEffectEngine.Free;
  PhysicManager.Free;
  PostEffectManager.Free;
  FreeAndNil(HUD);
  FreeAndNil(KeybindingManager);
  LinePool.Free;
  RHWLinePool.Free;
  GFXD.Free;
  Mouse.Free;
  Keyboard.Free;
  Input.Free;
  FreeAndNil(GameTimeManager);
end;

procedure THauptform.ApplicationEvents1Exception(Sender : TObject; E : Exception);
begin
  MessageDlg(E.Message + sLineBreak + sLineBreak + 'Program will now teminate, because it is in an instable state.', mtError, [mbOK], 0);
  ReportMemoryLeaksOnShutdown := False;
  Halt;
end;

procedure THauptform.ApplicationEvents1Idle(Sender : TObject; var Done : Boolean);
var
  Clickvector : RRay;
  tempMouse, diffMouse : RIntVector2;
  MouseState : EnumKeyState;
  MouseInRenderpanel : Boolean;
  GroundTarget : RVector3;
begin
  HUD.CameraLimited := Limitcamera1.Checked;
  Cam.Vertical := VerticalCamera1.Checked;
  Cam.FreeCamera := FreeCameraCheck.Checked;
  Clickvector := GFXD.MainScene.Camera.Clickvector(MausPos);
  if TargetGamePlaneCheck.Checked then
      GroundTarget := RPlane.XZ.IntersectRay(Clickvector)
  else
    if (ClientMap.Terrain <> nil) then GroundTarget := ClientMap.Terrain.IntersectRayTerrain(Clickvector);
  if Snaptogrid.Checked then GroundTarget := GroundTarget.Round;
  StatusBar.Panels[0].Text := 'Cursorpos: ' + GroundTarget;
  Caption := 'FPS:' + Inttostr(GFXD.FPS);
  TimeManager.TickTack;
  Input.DirectInputFactory.Idle;
  MouseInRenderpanel := MausInRenderpanel;

  if Active and MouseInRenderpanel then
  begin
    tempMouse := RIntVector2(RenderPanel.ScreenToClient(Vcl.Controls.Mouse.CursorPos));
    diffMouse := tempMouse - MausPos;
    Mouse.Position := tempMouse;
    MausPos := tempMouse;

    if not Mouse.DeltaPosition.isZeroVector then GlobalEventbus.Trigger(eiMouseMoveEvent, [Mouse.Position, Mouse.DeltaPosition]);
    if Mouse.dZ <> 0 then GlobalEventbus.Trigger(eiMouseWheelEvent, [Mouse.dZ]);
    if (Keyboard.HasAnyKeyActivity) or (Mouse.HasAnyButtonActivity) then
        GlobalEventbus.Trigger(eiKeybindingEvent, []);

    if assigned(ClientMap) then
    begin
      ClientMap.Terrain.RenderBrush(Clickvector);
      if Mouse.ButtonDown(mbLeft) then MouseState := ksDown
      else if Mouse.ButtonUp(mbLeft) then MouseState := ksUp
      else if Mouse.ButtonIsDown(mbLeft) then MouseState := ksIsDown
      else MouseState := ksIsUp;
      ClientMap.Terrain.Manipulate(Clickvector, (diffMouse.x <> 0) or (diffMouse.y <> 0), Keyboard.KeyIsDown(TasteSTRGRechts) or Keyboard.KeyIsDown(TasteSTRGLinks), MouseState, Mouse.ButtonUp(mbRight));
    end;

    if not Cam.FreeCamera and Keyboard.KeyUp(TasteW) then ShowWater1.Click;
    if Keyboard.KeyUp(TasteQ) then ShowGrid1.Click;

    if Keyboard.KeyUp(TasteF11) then ToggleFullscreenMode;

    if Keyboard.KeyUp(TasteF1) then FreeCameraCheck.Click;
    if Keyboard.KeyUp(TasteF2) then Cam.Locked := not Cam.Locked;
    if Keyboard.KeyUp(TasteF3) then Cam.FreeSlow := not Cam.FreeSlow;

    if Keyboard.KeyUp(TasteF5) then ShowMaterialEditorBtn.Click;
    if Keyboard.KeyUp(TasteF6) then ShowDropzonesCheck.Click;

    if Cam.FreeCamera and not Cam.Locked then
    begin
      RenderPanel.Cursor := crNone;
      Vcl.Controls.Mouse.CursorPos := TPoint.Create(Left + Width div 2, Top + Height div 2);
    end
    else RenderPanel.Cursor := crDefault;
  end;

  if assigned(ClientMap) then
  begin
    ClientMap.Water.IdleEditor(Active and MouseInRenderpanel);
    ClientMap.Vegetation.IdleEditor(Active and MouseInRenderpanel);
  end;

  ModuleManager.Idle(MouseInRenderpanel and Active, GroundTarget, Clickvector);

  Map.Idle;
  ParticleEffectEngine.Idle;
  ClientMap.DrawWater := ShowWater1.Checked;
  ClientMap.DrawVegetation := ShowVegetation1.Checked;
  ClientMap.Idle;
  GlobalEventbus.Trigger(eiIdle, []);

  if assigned(DropZoneRenderer) then
      DropZoneRenderer.Visible := ShowDropzonesCheck.Checked;

  if ShowGrid1.Checked and assigned(Map) then
  begin
    LinePool.DrawFixedGridOnTerrain(ClientMap.Terrain, GroundTarget, 20, $FF606060);
  end;

  GFXD.RenderTheWholeUniverseMegaGameProzedureDingMussNochLängerWerdenDeswegenHierMüllZeugsBlubsKeks;
  Done := False;
end;

procedure THauptform.FormActivate(Sender : TObject);
begin
  MausPos := RIntVector2(RenderPanel.ScreenToClient(Vcl.Controls.Mouse.CursorPos));
  GFXD.FPSCounter.FrameLimit := 0;
end;

procedure THauptform.Beenden1Click(Sender : TObject);
begin
  Close;
end;

procedure THauptform.BigChange(Sender : TObject);
begin
  if (Map = nil) or (ClientMap = nil) then exit;
  ModuleManager.GUIEvent(Sender);
  Cam.ResetPosition;
end;

procedure THauptform.DragAndDropWindowProc(var Msg : TMessage);
begin
  if Msg.Msg = WM_DROPFILES then
      DropFile(TWMDROPFILES(Msg))
  else
      originalPanelWindowProc(Msg);
end;

procedure THauptform.DropFile(Msg : TWMDROPFILES);
var
  numFiles : longInt;
  buffer : array [0 .. MAX_PATH] of Char;
  Filename : string;
begin
  numFiles := DragQueryFile(Msg.Drop, $FFFFFFFF, nil, 0);
  if numFiles = 0 then
  begin
    exit;
  end
  else if numFiles > 1 then
  begin
    ShowMessage('You can only drop one file at a time in this window!');
    exit;
  end;

  DragQueryFile(Msg.Drop, 0, @buffer, sizeof(buffer));
  Filename := string(buffer);
  if ExtractFileExt(Filename) = '.dme' then
      LoadReferenceEntities(Filename)
  else if ExtractFileExt(Filename) = '.bcm' then
      Load(Filename);
end;

procedure THauptform.ShowEditorClick(Sender : TObject);
begin
  ModuleManager.DeactivateAllModules;
  ClientMap.Terrain.HideDebugForm;
  ClientMap.Water.HideEditor;
  ClientMap.Vegetation.HideEditor;
  LightManagerForm.HideEditor;
  case TComponent(Sender).Tag of
    0 : ClientMap.Terrain.ShowDebugForm;
    1 : ClientMap.Water.ShowEditor;
    2 : ClientMap.Vegetation.ShowEditor(ClientMap.Terrain);
    3 : LightManagerForm.ShowEditor(ClientMap.LightManager);
  end;
end;

procedure THauptform.ShowMaterialEditorBtnClick(Sender : TObject);
var
  Module : TEditorModule;
  Entity : TEntity;
  Found : Boolean;
begin
  for Module in ModuleManager.Modules do
    if Module is TPlaceEntityModule then
    begin
      if TPlaceEntityModule(Module).GetEntityList.HasSelection then
      begin
        Entity := TPlaceEntityModule(Module).GetEntityByIndex(TPlaceEntityModule(Module).GetEntityList.SelectedIndices[0]);
        if assigned(Entity) then
        begin
          Found := False;
          Entity.Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(
            procedure(Component : TEntityComponent)
            begin
              if (Component is TMeshComponent) then
              begin
                if not Found then TMeshComponent(Component).ShowMaterialEditor;
                Found := True;
              end;
            end)]);
          exit;
        end;
      end;
    end;
end;

procedure THauptform.ToggleFullscreenMode;
begin
  if BorderStyle = bsSizeable then
  begin
    BorderStyle := bsNone;
    Height := Screen.Height;
    Width := Screen.Width;
    Top := 0;
    Left := 0;
    Menu := nil;
    StatusBar.Visible := False;
    if ShowZonesCheck.Checked then ShowZonesCheck.Tag := 1
    else ShowZonesCheck.Tag := 0;
    ShowZonesCheck.Checked := False;
    if Limitcamera1.Checked then Limitcamera1.Tag := 1
    else Limitcamera1.Tag := 0;
    Limitcamera1.Checked := True;
    ClientMap.Terrain.HideDebugForm;
    ClientMap.Water.HideEditor;
    ClientMap.Vegetation.HideEditor;
    LightManagerForm.HideEditor;
  end
  else
  begin
    BorderStyle := bsSizeable;
    Height := Screen.WorkAreaHeight;
    Width := Screen.Width;
    Top := 0;
    Left := 0;
    Menu := MainMenu1;
    StatusBar.Visible := True;
    if ShowZonesCheck.Tag = 1 then ShowZonesCheck.Checked := True
    else ShowZonesCheck.Checked := False;
    if Limitcamera1.Tag = 1 then Limitcamera1.Checked := True
    else Limitcamera1.Checked := False;
  end;
end;

procedure THauptform.Neu1Click(Sender : TObject);
begin
  MountedFile := '';
  Map.Free;
  Map := TMap.CreateEmpty;
  ClientMap.Free;
  ClientMap := TClientMap.CreateEmpty();
  FreeAndNil(DropZoneRenderer);
  ModuleManager.Init;
end;

procedure THauptform.Open1Click(Sender : TObject);
begin
  if MapOpenDialog.Execute then
  begin
    Load(MapOpenDialog.Filename);
  end;
end;

procedure THauptform.Posteffects1Click(Sender : TObject);
begin
  PostEffectManager.ShowDebugForm;
end;

procedure THauptform.RenderPanelResize(Sender : TObject);
begin
  if assigned(GFXD) then
      GFXD.ChangeResolution(RIntVector2.Create(RenderPanel.Width, RenderPanel.Height));
end;

procedure THauptform.Load(Path : string);
begin
  MountedFile := Path;
  Map.Free;
  Map := TMap.CreateFromFile(MountedFile);
  ClientMap.Free;
  ClientMap := TClientMap.CreateFromFile(MountedFile);
  FreeAndNil(DropZoneRenderer);
  DropZoneRenderer := TZoneRenderer.Create(GFXD.MainScene, ZONE_DROP);
  ModuleManager.Init;
  ModuleManager.LoadMap(MountedFile);
  ToolWindow.Init;
end;

procedure THauptform.LoadReferenceEntities(const Path : string);
begin
  ModuleManager.GetModule<TReferenceModule>.LoadReferenceFile(Path);
end;

procedure THauptform.LoadReferenceEntitiesfromFile1Click(Sender : TObject);
begin
  if ReferenceOpenDialog.Execute then
      LoadReferenceEntities(ReferenceOpenDialog.Filename);
end;

procedure THauptform.Save1Click(Sender : TObject);
begin
  if (MountedFile <> '') or MapSaveDialog.Execute then
  begin
    if (MountedFile = '') then MountedFile := MapSaveDialog.Filename;
    Map.SaveToFile(MountedFile);
    ClientMap.SaveToFile(MountedFile);
    ModuleManager.SaveMap(MountedFile);
  end;
end;

procedure THauptform.Saveas1Click(Sender : TObject);
begin
  MountedFile := '';
  Save1Click(Self);
end;

procedure THauptform.SetBackgroundColor1Click(Sender : TObject);
begin
  ColorDialog1.Color := GFXD.MainScene.Backgroundcolor.AsBGRCardinal;
  if ColorDialog1.Execute then
  begin
    GFXD.MainScene.Backgroundcolor.AsBGRCardinal := ColorDialog1.Color;
    HFileIO.WriteToIni(AbsolutePath('Settings.ini'), 'Debug', 'BgColor', GFXD.MainScene.Backgroundcolor.ToHexString);
  end;
end;

procedure THauptform.MapEditor1Click(Sender : TObject);
begin
  ToolWindow.Show;
end;

function THauptform.MausInRenderpanel : Boolean;
var
  Pointi : TPoint;
begin
  Pointi := RenderPanel.ScreenToClient(Vcl.Controls.Mouse.CursorPos);
  Result := ((0 <= Pointi.x) and (RenderPanel.Width >= Pointi.x)) and ((0 <= Pointi.y) and (RenderPanel.Height >= Pointi.y));
  Result := Result and Active;
end;

{ TEditorModuleManager }

procedure TEditorModuleManager.ActivateModule(Module : CModule);
var
  aModule : TEditorModule;
begin
  for aModule in FModules do
    if aModule.Active <> (aModule is Module) then aModule.Active := aModule is Module;
end;

constructor TEditorModuleManager.Create(Mouse : TMouse; Keyboard : TKeyboard);
begin
  FMouse := Mouse;
  FKeyboard := Keyboard;
  FModules := TObjectList<TEditorModule>.Create;
end;

procedure TEditorModuleManager.DeactivateAllModules();
var
  aModule : TEditorModule;
begin
  for aModule in FModules do
    if aModule.Active then aModule.Active := False;
end;

procedure TEditorModuleManager.DeActivateModule(Module : CModule);
var
  aModule : TEditorModule;
  somethingactive : Boolean;
begin
  for aModule in FModules do
    if aModule.Active and (aModule is Module) then aModule.Active := False;
  somethingactive := False;
  for aModule in FModules do
    if aModule.Active then somethingactive := True;
  if not somethingactive then
  begin
    for aModule in FModules do
      if aModule.DefaultModule then aModule.Active := True;
  end;
end;

destructor TEditorModuleManager.Destroy;
begin
  FModules.Free;
  inherited;
end;

function TEditorModuleManager.GetModule<T> : T;
var
  i : integer;
begin
  Result := nil;
  for i := 0 to ModuleManager.Modules.Count - 1 do
    if ModuleManager.Modules[i] is T then
        exit(ModuleManager.Modules[i] as T);
end;

procedure TEditorModuleManager.GUIEvent(Sender : TObject);
var
  aModule : TEditorModule;
begin
  for aModule in FModules do aModule.GUIEvent(Sender);
end;

procedure TEditorModuleManager.Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay);
var
  aModule : TEditorModule;
  Button : EnumMouseButton;
begin
  if MouseInRenderpanel then
    for Button := low(EnumMouseButton) to high(EnumMouseButton) do
    begin
      if FMouse.ButtonDown(Button) then
        for aModule in FModules do
          if aModule.Active then aModule.MouseDown(Button, GroundTarget, Clickvector);
      if FMouse.ButtonUp(Button) and ((Button <> mbRight) or (not FMouse.WasDragging)) then
        for aModule in FModules do
          if aModule.Active then aModule.MouseUp(Button, GroundTarget, Clickvector);
    end;
  for aModule in FModules do
      aModule.Idle(MouseInRenderpanel, GroundTarget, Clickvector);
end;

procedure TEditorModuleManager.Init;
var
  aModule : TEditorModule;
begin
  for aModule in FModules do aModule.Init;
end;

procedure TEditorModuleManager.LoadMap(const Filename : string);
var
  aModule : TEditorModule;
begin
  for aModule in FModules do aModule.LoadMap(Filename);
end;

procedure TEditorModuleManager.SaveMap(const Filename : string);
var
  aModule : TEditorModule;
begin
  for aModule in FModules do aModule.SaveMap(Filename);
end;

procedure TEditorModuleManager.SyncToGUI(Module : CModule);
var
  aModule : TEditorModule;
begin
  for aModule in FModules do
    if (aModule is Module) then aModule.SyncToGUI;
end;

{ TEditorModule }

constructor TEditorModule.Create(Mouse : TMouse; Keyboard : TKeyboard);
begin
  FMouse := Mouse;
  FKeyboard := Keyboard;
end;

destructor TEditorModule.Destroy;
begin

  inherited;
end;

procedure TEditorModule.GUIEvent(Sender : TObject);
begin

end;

procedure TEditorModule.Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay);
begin

end;

procedure TEditorModule.Init;
begin

end;

procedure TEditorModule.LoadMap(const Filename : string);
begin

end;

procedure TEditorModule.MouseDown(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay);
begin

end;

procedure TEditorModule.MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay);
begin

end;

procedure TEditorModule.SaveMap(const Filename : string);
begin

end;

procedure TEditorModule.SetActive(State : Boolean);
begin
  FActive := State;
end;

procedure TEditorModule.SyncFromGUI;
begin

end;

procedure TEditorModule.SyncToGUI;
begin

end;

{ TStartpointModule }
{ TZoneModule }

constructor TZoneModule.Create(Mouse : TMouse; Keyboard : TKeyboard);
begin
  inherited Create(Mouse, Keyboard);
  StartPoint := RVector2.EMPTY;
  EndPoint := RVector2.EMPTY;
end;

destructor TZoneModule.Destroy;
begin
  FPathfinding.Free;
  inherited;
end;

procedure TZoneModule.ExportSelectedZone;
var
  index : integer;
  poly : TMultipolygon;
  target : Text;
  i, j, Count : integer;
begin
  index := ToolWindow.ZoneList.ItemIndex;
  if (index >= 0) and ToolWindow.ZoneSaveDialog.Execute then
  begin
    poly := Map.Zones.Items[ToolWindow.ZoneList.Items[index]];
    assignfile(target, ToolWindow.ZoneSaveDialog.Filename);
    Rewrite(target);
    Count := 0;
    for i := 0 to poly.Polygons.Count - 1 do
    begin
      for j := 0 to poly.Polygons[i].Polygon.Nodes.Count - 1 do
      begin
        writeln(target, 'v ', string(poly.Polygons[i].Polygon.Nodes[j].X0Y).Replace(',', ' ').Replace('(', '').Replace(')', ''));
        inc(Count);
      end;
    end;
    // obj indices are 1 based
    for i := 1 to Count - 1 do
    begin
      writeln(target, 'f ' + i.ToString + ' ' + (i + 1).ToString + ' ' + i.ToString)
    end;
    CloseFile(target);
  end;
end;

procedure TZoneModule.GUIEvent(Sender : TObject);
begin
  inherited;
  if Sender = ToolWindow.ZonePanel then SyncToGUI();
  if Sender = ToolWindow.ZoneList then
  begin
    ModuleManager.ActivateModule(TZoneModule);
    FreeAndNil(FPathfinding);
  end;
  if (Sender = ToolWindow.ZoneAddBtn) and (ToolWindow.ZoneEdit.Text <> '') then
  begin
    if Map.Zones.ContainsKey(ToolWindow.ZoneEdit.Text) then ShowMessage('Zonenames must be unique!')
    else
    begin
      ToolWindow.ZoneList.Items.Add(ToolWindow.ZoneEdit.Text);
      Map.Zones.Add(ToolWindow.ZoneEdit.Text, TMultipolygon.Create());
      Map.Zones[ToolWindow.ZoneEdit.Text].AddPolygon(TPolygon.Create, False);
      ToolWindow.ZoneEdit.Text := '';
    end;
  end;
  if Sender = ToolWindow.ZoneExportBtn then
  begin
    ExportSelectedZone;
  end;
end;

procedure TZoneModule.Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay);
var
  i, index : integer;
  str : string;
  poly : TPolygon;
  Color : RColor;
begin
  inherited;
  index := ToolWindow.ZoneList.ItemIndex;

  if ToolWindow.Active then
  begin
    if MouseInRenderpanel and (index <> -1) then
    begin
      poly := Map.Zones[ToolWindow.ZoneList.Items[index]].Polygons.Last.Polygon;
      if not poly.Closed and (poly.Nodes.Count > 0) then
      begin
        if GroundTarget.SetY(0).Distance(poly.Nodes.First.X0Y) < 0.5 then GroundTarget := poly.Nodes.First.X0Y;
        Color := RColor.Create($FF70FF4D);
        if Map.Zones[ToolWindow.ZoneList.Items[index]].Polygons.Last.Subtractive then Color := Color.Lerp($FF000000, 0.5);
        LinePool.AddLine(poly.Nodes.Last.X0Y, GroundTarget, Color, RVector3.Create0Y0(Map.Zones.Count * 0.01 + 0.1));
      end;
      if FKeyboard.KeyUp(TasteP) then
      begin
        if StartPoint.isEmpty then StartPoint := GroundTarget.XZ
        else if EndPoint.isEmpty then EndPoint := GroundTarget.XZ
        else
        begin
          StartPoint := GroundTarget.XZ;
          EndPoint := RVector2.EMPTY;
        end;
      end;
      LinePool.AddSphere(ClientMap.Terrain.GetTerrainHeight(Map.Zones[ToolWindow.ZoneList.Items[index]].EnsurePointInMultiPoly(GroundTarget.XZ)), 0.25, RColor.CRED)
    end;

    // deletion
    if FKeyboard.KeyUp(TasteEntf) then
    begin
      if (index <> -1) then
      begin
        FreeAndNil(FPathfinding);
        poly := Map.Zones[ToolWindow.ZoneList.Items[index]].Polygons.Last.Polygon;
        // open closed poly
        if poly.Closed then poly.Closed := False
          // if open delete last node
        else if poly.Nodes.Count > 1 then poly.DeleteNode(poly.Nodes.Count - 1)
          // if there are no nodes delete poly
        else if Map.Zones[ToolWindow.ZoneList.Items[index]].Polygons.Count > 1 then Map.Zones[ToolWindow.ZoneList.Items[index]].DeletePolygon(Map.Zones[ToolWindow.ZoneList.Items[index]].Polygons.Count - 1)
          // if there are no polys left in the multipolygon delete multipoly
        else
        begin
          Map.Zones.Remove(ToolWindow.ZoneList.Items[index]);
          ToolWindow.ZoneList.Items.Delete(index);
          ModuleManager.DeActivateModule(TZoneModule);
        end;
      end;
    end;

    index := ToolWindow.ZoneList.ItemIndex;
    if (index <> -1) and (FPathfinding = nil) then FPathfinding := TMultipolygonPathfinding.Create(Map.Zones[ToolWindow.ZoneList.Items[index]]);

    if not StartPoint.isEmpty then LinePool.AddSphere(ClientMap.Terrain.GetTerrainHeight(StartPoint), 0.25, RColor.CRED);
    if not EndPoint.isEmpty then LinePool.AddSphere(ClientMap.Terrain.GetTerrainHeight(EndPoint), 0.25, RColor.CRED);
    index := ToolWindow.ZoneList.ItemIndex;
    if not StartPoint.isEmpty and not EndPoint.isEmpty and (FPathfinding <> nil) then
    begin
      poly := FPathfinding.FindPath(StartPoint, EndPoint);
      if assigned(poly) then LinePool.AddPolygon(poly, RColor.CRED, RVector3.Create0Y0(0.1 + (Map.Zones.Count + 2) * 0.01));
      poly.Free;
    end;
  end;

  i := 0;
  // show Zones
  if Hauptform.ShowZonesCheck.Checked then
    for str in Map.Zones.Keys do
    begin
      inc(i);
      if (index <> -1) and (ToolWindow.ZoneList.Items[index] = str) then
      begin
        if Map.Zones[str].IsPointInMultiPolygon(GroundTarget.XZ) then Color := $FFCCFFCC
        else Color := $FF80FF80;
        i := i + Map.Zones.Count + 1;
      end
      else
      begin
        if Map.Zones[str].IsPointInMultiPolygon(GroundTarget.XZ) then Color := $FFFF913B
        else Color := $FF3BD1FF;
      end;
      LinePool.AddMultiPolygon(Map.Zones[str], Color, Color.Lerp(RColor.CBLACK, 0.25), RVector3.Create0Y0(0.1 + 0.01 * i));
      if (index <> -1) and (ToolWindow.ZoneList.Items[index] = str) then i := i - Map.Zones.Count + 1;
    end;
end;

procedure TZoneModule.MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay);
var
  index : integer;
  poly : TPolygon;
begin
  inherited;
  index := ToolWindow.ZoneList.ItemIndex;
  if index = -1 then
  begin
    ModuleManager.DeActivateModule(TZoneModule);
    exit;
  end;
  FreeAndNil(FPathfinding);
  if Button = mbLeft then
  begin
    poly := Map.Zones[ToolWindow.ZoneList.Items[index]].Polygons.Last.Polygon;
    if not poly.Closed then
    begin
      if (poly.Nodes.Count > 0) and (GroundTarget.SetY(0).Distance(poly.Nodes.First.X0Y) < 0.5) then poly.Closed := True
      else poly.AddNode(GroundTarget.XZ);
    end
    else
    begin
      Map.Zones[ToolWindow.ZoneList.Items[index]].AddPolygon(TPolygon.Create, Keyboard.KeyIsDown(TasteShiftLinks));
      poly := Map.Zones[ToolWindow.ZoneList.Items[index]].Polygons.Last.Polygon;
      poly.AddNode(GroundTarget.XZ);
    end;
  end;
  if Button = mbRight then
  begin
    ModuleManager.DeActivateModule(TZoneModule);
  end;
end;

procedure TZoneModule.SetActive(State : Boolean);
begin
  inherited;
  if not State then ToolWindow.ZoneList.ItemIndex := -1;
end;

procedure TZoneModule.SyncToGUI;
var
  str : string;
begin
  inherited;
  ToolWindow.ZoneList.Clear;
  for str in Map.Zones.Keys do ToolWindow.ZoneList.Items.Add(str);
end;

{ TPlaceEntityModule }

constructor TPlaceEntityModule.Create(Mouse : TMouse; Keyboard : TKeyboard);
begin
  inherited Create(Mouse, Keyboard);
  RefreshEntityFileList;
  FDefault := True;
  Visible := True;
end;

destructor TPlaceEntityModule.Destroy;
begin
  EntityToSet.Free;
  UnitsFileList.Free;
  inherited;
end;

function TPlaceEntityModule.GetCenterOfSelection : RVector3;
var
  i : integer;
begin
  Result := RVector3.ZERO;
  for i := 0 to GetEntityList.SelectionCount - 1 do
      Result := Result + GetEntityDescription(GetEntityList.SelectedIndices[i]).Position;
  Result := Result / GetEntityList.SelectionCount;
end;

procedure TPlaceEntityModule.GUIEvent(Sender : TObject);
begin
  inherited;
  if Sender = Hauptform.Neu1 then FreeAndNil(EntityToSet);
  if Sender = GetCorrespondingTab then SyncToGUI;
  if (Sender = GetEntityList) and GetEntityList.HasSelection then ModuleManager.ActivateModule(CModule(Self.ClassType));
  if Sender = GetPatternList then
  begin
    if GetPatternList.ItemIndex <> -1 then
    begin
      ModuleManager.ActivateModule(CModule(Self.ClassType));
      EntityToSet.Free;
      EntityToSet := TEntity.CreateFromScript(
        HString.TrimBeforeCaseInsensitive('scripts', UnitsFileList[GetPatternList.ItemIndex]),
        GlobalEventbus,
        procedure(Entity : TEntity)
        begin
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), 4);
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), 5);
        end
        );
      TLogicToWorldComponent.Create(EntityToSet);
      EntityToSet.Eventbus.Write(eiSize, [RVector3.ONE]);
      EntityToSet.Eventbus.Trigger(eiColorAdjustment, [RVector3.Create(1 / 3, 0, 0.5), True, False, False]);
    end;
  end;
end;

procedure TPlaceEntityModule.Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay);
var
  EntityDesc : REntityDescription;
  i : integer;
  Rotation, DifferenceRotation : single;
  Center : RVector3;
begin
  inherited;

  if Hauptform.Active then
  begin
    if GetEntityList.HasSelection then
    begin
      // delete all selected entities
      if Keyboard.KeyUp(TasteEntf) then
      begin
        for i := GetEntityList.SelectionCount - 1 downto 0 do
        begin
          RemoveEntity(GetEntityList.SelectedIndices[i]);
          GetEntityList.Items.Delete(GetEntityList.SelectedIndices[i]);
        end;
      end
      // manipulate all selected entities
      else ManipulateEntity;
    end;

    if MouseInRenderpanel then
    begin
      if Keyboard.Strg and Keyboard.KeyUp(TasteD) then
      begin
        for i := 0 to GetEntityList.SelectionCount - 1 do
        begin
          DuplicateEntity(GetEntityList.SelectedIndices[i]);
        end;
      end;
      // reset rotation
      if Keyboard.KeyDown(TasteShiftLinks) or Keyboard.KeyUp(TasteShiftRechts) then
          FLastRotation := -200;

      if ModelDragging and Mouse.WasDragging and GetEntityList.HasSelection then
      begin
        Center := GetCenterOfSelection;

        // compute rotation difference to last frame
        Rotation := (GroundTarget - Center).Polar.y;
        if FLastRotation < -100 then
            DifferenceRotation := 0
        else
            DifferenceRotation := Rotation - FLastRotation;

        if not Keyboard.KeyIsDown(TasteR) then FLastRotation := Rotation
        else
          if abs(DifferenceRotation) >= PI / 2 / 4 then
        begin
          DifferenceRotation := Round(DifferenceRotation / PI * 4) / 4 * PI;
          FLastRotation := Rotation;
        end
        else DifferenceRotation := 0;

        // manipulate position
        for i := 0 to GetEntityList.SelectionCount - 1 do
        begin
          EntityDesc := GetEntityDescription(GetEntityList.SelectedIndices[i]);
          if Keyboard.AltGr then
              EntityDesc.Size := (GroundTarget - Center).SetY(0).Length / 2
          else
            if Keyboard.Shift then
          begin
            EntityDesc.Position := EntityDesc.Position.RotateAroundPoint(Center, 0, DifferenceRotation, 0);
            EntityDesc.Front := EntityDesc.Front.RotatePitchYawRoll(0, DifferenceRotation, 0);
          end
          else
            if Keyboard.KeyIsDown(TasteF) then
              EntityDesc.Freezed := not EntityDesc.Freezed
          else
            if Keyboard.KeyIsDown(TasteX) then
              EntityDesc.Position.x := RPlane.CreateFromCenter(Center, RVector3.UNITX, GFXD.MainScene.Camera.ScreenLeft).IntersectRay(Clickvector).x + (EntityDesc.Position - Center).x
          else
            if Keyboard.KeyIsDown(TasteY) then
              EntityDesc.Position.y := RPlane.CreateFromCenter(Center, RVector3.UNITY, GFXD.MainScene.Camera.ScreenLeft).IntersectRay(Clickvector).y + (EntityDesc.Position - Center).y
          else
            if Keyboard.KeyIsDown(TasteZ) then
              EntityDesc.Position.z := RPlane.CreateFromCenter(Center, RVector3.UNITZ, GFXD.MainScene.Camera.ScreenLeft).IntersectRay(Clickvector).z + (EntityDesc.Position - Center).z
          else
              EntityDesc.Position := GroundTarget + DragOffset + (EntityDesc.Position - Center);
          UpdateEntityDescription(GetEntityList.SelectedIndices[i], EntityDesc);
        end;
      end;

      // model is ready for placement
      if EntityToSet <> nil then
      begin
        if ModelAnchored then
        begin
          EntityToSet.Position := DragOffset.XZ;
          EntityToSet.Front := RVector2.UNITY;
          if DragOffset.Distance(GroundTarget) > 1 then
          begin
            EntityToSet.Front := (DragOffset - GroundTarget).Normalize.XZ;
          end;
        end
        else
        begin
          EntityToSet.Position := GroundTarget.XZ;
          EntityToSet.Front := RVector2.UNITY;
        end;
      end;
    end;
  end;

  // show selection
  if GetEntityList.HasSelection then
  begin
    for i := 0 to GetEntityList.SelectionCount - 1 do
    begin
      EntityDesc := GetEntityDescription(GetEntityList.SelectedIndices[i]);
      LinePool.DrawCircleOnTerrain(ClientMap.Terrain, EntityDesc.Position, GetBoundingsOfEntity(GetEntityList.SelectedIndices[i]).Radius, RColor.CGREEN);
    end;
  end;
end;

procedure TPlaceEntityModule.MouseDown(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay);
begin
  inherited;
  if Button = mbLeft then
  begin
    FSeenDown := True;
    if EntityToSet = nil then
    begin
      PickEntity(True, Clickvector);
      if GetEntityList.HasSelection and not SelectionIsFreezed then
      begin
        ModelDragging := True;
        DragOffset := GetCenterOfSelection - GroundTarget;
      end;
    end
    else
    begin
      DragOffset := GroundTarget;
      ModelAnchored := True;
    end;
  end;
end;

procedure TPlaceEntityModule.MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay);
var
  Description : REntityDescription;
begin
  inherited;
  if (Button = mbRight) and not Mouse.WasDragging then
  begin
    FreeAndNil(EntityToSet);
    GetEntityList.DeselectAll;
    GetPatternList.DeselectAll;
  end;
  if Button = mbLeft then
  begin
    // if model is chosen place the model to set onto the map
    if EntityToSet <> nil then
    begin
      if FSeenDown then
      begin
        EntityToSet.Eventbus.Trigger(eiColorAdjustment, [RVector3.Create(0, 0, 0), False, False, False]);
        ModelAnchored := False;
        Description.Position := EntityToSet.DisplayPosition;
        Description.Front := EntityToSet.DisplayFront;
        Description.Size := EntityToSet.Eventbus.Read(eiSize, []).AsVector3.x;
        Description.ScriptFile := EntityToSet.ScriptFile;
        AddEntity(Description);
        GetEntityList.Items.Add(ChangeFileExt(ExtractFileName(EntityToSet.ScriptFile), '') + ' ' + Inttostr(GetEntityList.Count));
        EntityToSet.Free;
        EntityToSet := TEntity.CreateFromScript(
          HString.TrimBeforeCaseInsensitive('scripts', UnitsFileList[GetPatternList.ItemIndex]),
          GlobalEventbus,
          procedure(Entity : TEntity)
          begin
            Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), 4);
            Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), 5);
          end
          );
        TLogicToWorldComponent.Create(EntityToSet);
        EntityToSet.Eventbus.Write(eiSize, [RVector3.ONE]);
        EntityToSet.Eventbus.Trigger(eiColorAdjustment, [RVector3.Create(1 / 3, 0, 0.5), True, False, False]);
      end;
    end
    else
    begin
      if not ModelDragging then PickEntity(False, Clickvector);
      ModelDragging := False;
    end;
    FSeenDown := False;
  end;
end;

procedure TPlaceEntityModule.DuplicateEntity(index : integer);
var
  Description : REntityDescription;
begin
  Description := GetEntityDescription(index);
  AddEntity(Description);
  GetEntityList.Items.Add(ChangeFileExt(ExtractFileName(Description.ScriptFile), '') + ' ' + Inttostr(GetEntityList.Count));
end;

procedure TPlaceEntityModule.PickEntity(KeepSelected : Boolean; Clickvector : RRay);
var
  i, minIndex : integer;
  minDistance, Distance : single;
  Bounding : RSphere;
  EntityList : TListBox;
  Append, Remove : Boolean;
begin
  if not Visible then exit;
  Remove := Keyboard.Alt;
  Append := Keyboard.Strg and not Remove;
  EntityList := GetEntityList;
  // if we want to keep the selected items
  // first check whether our clicks hits a unit previously selected and keep the selection
  if KeepSelected and EntityList.HasSelection and not(Remove or Append) then
  begin
    for i := 0 to EntityList.SelectionCount - 1 do
    begin
      Bounding := GetBoundingsOfEntity(EntityList.SelectedIndices[i]);
      if Bounding.IntersectSphereRay(Clickvector) then exit;
    end;
  end;
  // pick new entity
  // singleselect select nearest
  // multiselect, holding Strg adds entities, holding Alt removes them, no key renews selection with nearest
  minDistance := single.MaxValue;
  minIndex := -1;
  for i := 0 to EntityList.Items.Count - 1 do
  begin
    // freezed entities cannot be targeted
    if GetEntityDescription(i).Freezed or
    // we can only append entities which aren't selected
      (EntityList.HasSelection and Append and EntityList.IsSelected(i)) or
    // we can only remove entities which are selected
      (EntityList.HasSelection and Remove and not EntityList.IsSelected(i)) then continue;
    Bounding := GetBoundingsOfEntity(i);
    Distance := Clickvector.DistanceToPoint(Bounding.Center);
    if Bounding.IntersectSphereRay(Clickvector) and (Distance < minDistance) then
    begin
      minDistance := Distance;
      minIndex := i;
    end;
  end;
  if minIndex >= 0 then
  begin
    if Append then EntityList.Select(minIndex, False)
    else if Remove then EntityList.Deselect(minIndex)
    else EntityList.Select(minIndex);
  end
  // clicked anywhere without entity
  else if not(Remove or Append) then EntityList.DeselectAll;
  ToolWindow.BigChange(GetEntityList);
end;

procedure TPlaceEntityModule.RefreshEntityFields;
begin
end;

function TPlaceEntityModule.SelectionIsFreezed : Boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to GetEntityList.SelectionCount - 1 do
    if GetEntityDescription(GetEntityList.SelectedIndices[i]).Freezed then exit(True);
end;

procedure TPlaceEntityModule.SetActive(State : Boolean);
begin
  inherited;
  if not State then
  begin
    GetEntityList.DeselectAll;
    GetPatternList.DeselectAll;
    FreeAndNil(EntityToSet);
  end;
end;

procedure TPlaceEntityModule.SyncToGUI;
var
  i : integer;
begin
  inherited;
  if not assigned(ClientMap) then exit;
  GetPatternList.Clear;
  for i := 0 to UnitsFileList.Count - 1 do GetPatternList.Items.Add(HFilepathManager.RelativeToRelative(HFilepathManager.AbsoluteToRelative(ChangeFileExt(UnitsFileList[i], '')), PATH_SCRIPT).Replace('Units\', '').Replace('Environment\', ''));
  GetPatternList.ItemIndex := -1;
  GetEntityList.Clear;
  for i := 0 to GetEntityCount - 1 do GetEntityList.Items.Add(ChangeFileExt(ExtractFileName(GetEntityDescription(i).ScriptFile), '') + ' ' + Inttostr(i));
end;

procedure TPlaceEntityModule.UpdateEntityDescription(index : integer; Desc : REntityDescription);
begin
  if not FSupressFieldSync then RefreshEntityFields;
end;

{ TLaneModule }

constructor TLaneModule.Create(Mouse : TMouse; Keyboard : TKeyboard);
begin
  inherited Create(Mouse, Keyboard);
  StartPoint := RVector2.EMPTY;
end;

destructor TLaneModule.Destroy;
begin
  inherited;
end;

procedure TLaneModule.GUIEvent(Sender : TObject);
begin
  inherited;
  if Sender = ToolWindow.LaneTab then SyncToGUI();
  if (Sender = ToolWindow.LanesList) or (Sender = ToolWindow.PlaceLaneSpeed) then
  begin
    ModuleManager.ActivateModule(TLaneModule);
  end;
end;

procedure TLaneModule.Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay);
var
  index : integer;
begin
  inherited;
  index := ToolWindow.LanesList.ItemIndex;

  if ToolWindow.Active then
  begin
    if MouseInRenderpanel then
    begin
      if (index = -1) and Mouse.ButtonIsDown(mbLeft) then LinePool.AddLine(StartPoint.X0Y.SetY(0.3), GroundTarget.SetY(0.3), RColor.CNEONORANGE);
    end;
    if FKeyboard.KeyUp(TasteEntf) and (index <> -1) then
    begin
      Map.Lanes.Lanes.Delete(index);
      SyncToGUI;
    end;
  end;
end;

procedure TLaneModule.MouseDown(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay);
begin
  inherited;
end;

procedure TLaneModule.MouseUp(Button : EnumMouseButton; GroundTarget : RVector3; Clickvector : RRay);
// var
// index : integer;
begin
  inherited;
  // index := ToolWindow.LanesList.ItemIndex;

  if Button = mbLeft then
  begin
    if ToolWindow.PlaceLaneSpeed.Down then
    begin
      // Map.Lanes.Lanes.Add(TLane.Create());
      // TLaneHack(Map.Lanes.Lanes.Last).FLane.AddNode(GroundTarget.XZ);
    end
    else
        SyncToGUI;
  end;
  if Button = mbRight then
  begin
    StartPoint := RVector2.EMPTY;
    ModuleManager.DeActivateModule(TLaneModule);
  end;
end;

procedure TLaneModule.SetActive(State : Boolean);
begin
  inherited;
  if not State then
  begin
    ToolWindow.LanesList.ItemIndex := -1;
    ToolWindow.PlaceLaneSpeed.Down := False;
  end;
end;

procedure TLaneModule.SyncToGUI;
var
  i : integer;
begin
  inherited;
  ToolWindow.LanesList.Clear;
  for i := 0 to Map.Lanes.Lanes.Count - 1 do ToolWindow.LanesList.Items.Add('Lane ' + Inttostr(i));
end;

{ TDecoModule }

procedure TDecoModule.AddEntity(Desc : REntityDescription);
begin
  ClientMap.AddDecoEntity(MigrateDesc(Desc));
end;

function TDecoModule.GetBoundingsOfEntity(index : integer) : RSphere;
begin
  Result := ClientMap.DecorationEntities[index].Eventbus.Read(eiBoundings, []).AsType<RSphere>;
end;

function TDecoModule.GetCorrespondingTab : TCategoryPanel;
begin
  Result := ToolWindow.DecoTab;
end;

function TDecoModule.GetEntityByIndex(index : integer) : TEntity;
begin
  if InRange(index, 0, ClientMap.DecorationEntities.Count - 1) then
      Result := ClientMap.DecorationEntities[index]
  else
      Result := nil;
end;

function TDecoModule.GetEntityCount : integer;
begin
  Result := ClientMap.DecorationEntities.Count;
end;

function TDecoModule.GetEntityDescription(index : integer) : REntityDescription;
begin
  Result := MigrateDescReverse(ClientMap.Decorations[index])
end;

function TDecoModule.GetEntityList : TListBox;
begin
  Result := ToolWindow.ExistingDecoList;
end;

function TDecoModule.GetPatternList : TListBox;
begin
  Result := ToolWindow.DecoUnitsList;
end;

procedure TDecoModule.GUIEvent(Sender : TObject);
var
  Desc : RDecoEntityDescription;
begin
  inherited;
  if Sender = ToolWindow.DecoPatternRefreshBtn then RefreshEntityFileList;
  if Sender = GetEntityList then RefreshEntityFields;
  if (TComponent(Sender).GetParentComponent = ToolWindow.DecoValueGroup) and GetEntityList.HasSelection and not(GetEntityList.SelectionCount > 1) then
  begin
    Desc := MigrateDesc(GetEntityDescription(GetEntityList.ItemIndex));
    if Sender = ToolWindow.DecoValuePositionXEdit then Desc.Position.x := ToolWindow.DecoValuePositionXEdit.SingleValue;
    if Sender = ToolWindow.DecoValuePositionYEdit then Desc.Position.y := ToolWindow.DecoValuePositionYEdit.SingleValue;
    if Sender = ToolWindow.DecoValuePositionZEdit then Desc.Position.z := ToolWindow.DecoValuePositionZEdit.SingleValue;
    if Sender = ToolWindow.DecoValueRotationEdit then Desc.Front.Polar := RVector3.Create(0, DegToRad(ToolWindow.DecoValueRotationEdit.SingleValue) - PI, 1);
    if Sender = ToolWindow.DecoValueSizeEdit then Desc.Size := ToolWindow.DecoValueSizeEdit.SingleValue;
    if Sender = ToolWindow.DecoValueFreezeCheck then Desc.Freezed := ToolWindow.DecoValueFreezeCheck.Checked;
    FSupressFieldSync := True;
    UpdateEntityDescription(GetEntityList.ItemIndex, MigrateDescReverse(Desc));
    FSupressFieldSync := False;
  end;
end;

procedure TDecoModule.ManipulateEntity();
var
  EntityDesc : RDecoEntityDescription;
  i, index : integer;
begin
  for i := 0 to GetEntityList.SelectionCount - 1 do
  begin
    index := GetEntityList.SelectedIndices[i];
    EntityDesc := ClientMap.Decorations[index];

    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNumPlus) then EntityDesc.Position.y := EntityDesc.Position.y + 0.1;
    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNumMinus) then EntityDesc.Position.y := EntityDesc.Position.y - 0.1;

    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNum4) then EntityDesc.Front := EntityDesc.Front.RotateAxis(RVector3.UNITY, 0.1);
    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNum6) then EntityDesc.Front := EntityDesc.Front.RotateAxis(RVector3.UNITY, -0.1);
    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNum8) then EntityDesc.Front := EntityDesc.Front.RotateAxis(RVector3.UNITX, 0.1);
    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNum2) then EntityDesc.Front := EntityDesc.Front.RotateAxis(RVector3.UNITX, -0.1);
    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNum7) then EntityDesc.Front := EntityDesc.Front.RotateAxis(RVector3.UNITZ, 0.1);
    // if Keyboard.KeyUp(EnumKeyboardKey.TasteNum3) then EntityDesc.Front := EntityDesc.Front.RotateAxis(RVector3.UNITZ, -0.1);

    ClientMap.UpdateDecoEntity(index, EntityDesc);
  end;
end;

function TDecoModule.MigrateDesc(a : REntityDescription) : RDecoEntityDescription;
begin
  Result.Position := a.Position;
  Result.Front := a.Front;
  Result.Size := a.Size;
  Result.ScriptFilename := a.ScriptFile;
  Result.Freezed := a.Freezed;
end;

function TDecoModule.MigrateDescReverse(a : RDecoEntityDescription) : REntityDescription;
begin
  Result.Position := a.Position;
  Result.Front := a.Front;
  Result.Size := a.Size;
  Result.ScriptFile := a.ScriptFilename;
  Result.Freezed := a.Freezed;
end;

procedure TDecoModule.RefreshEntityFields;
var
  Desc : RDecoEntityDescription;
begin
  if GetEntityList.HasSelection and not(GetEntityList.SelectionCount > 1) then
  begin
    Desc := ClientMap.Decorations[GetEntityList.ItemIndex];
    ToolWindow.DecoValueGroup.Visible := True;
    ToolWindow.DecoValuePositionXEdit.SingleValue := Desc.Position.x;
    ToolWindow.DecoValuePositionYEdit.SingleValue := Desc.Position.y;
    ToolWindow.DecoValuePositionZEdit.SingleValue := Desc.Position.z;
    ToolWindow.DecoValueRotationEdit.SingleValue := RadToDeg(Desc.Front.Polar.y + PI);
    ToolWindow.DecoValueSizeEdit.SingleValue := Desc.Size;
    ToolWindow.DecoValueFreezeCheck.Checked := Desc.Freezed;
  end
  else ToolWindow.DecoValueGroup.Visible := False;
end;

procedure TDecoModule.RefreshEntityFileList;
begin
  UnitsFileList.Free;
  UnitsFileList := TStringList.Create;
  HFileIO.FindAllFiles(UnitsFileList, FormatDateiPfad(DECO_ENTITY_PATH), '*.ets');
  SyncToGUI;
end;

procedure TDecoModule.RemoveEntity(index : integer);
begin
  ClientMap.RemoveDecoEntity(index);
end;

procedure TDecoModule.UpdateEntityDescription(index : integer; Desc : REntityDescription);
begin
  inherited;
  ClientMap.UpdateDecoEntity(index, MigrateDesc(Desc));
end;

{ TReferenceModule }

procedure TReferenceModule.AddEntity(Desc : REntityDescription);
var
  Entity : TEntity;
begin
  FReferenceEntitiesRaw.Add(Desc);
  Entity := TEntity.CreateFromScript(
    Desc.ScriptFile,
    GlobalEventbus,
    procedure(Entity : TEntity)
    begin
      Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), 4);
      Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), 5);
    end
    );
  TLogicToWorldComponent.Create(Entity);
  Entity.Eventbus.Write(eiVisible, [Hauptform.ShowReferenceEntities1.Checked]);
  FReferenceEntities.Add(Entity);
  UpdateEntityDescription(FReferenceEntities.Count - 1, Desc);
  Entity.Eventbus.Trigger(eiAfterCreate, []);
  Entity.Eventbus.Trigger(eiDeploy, []);
end;

procedure TReferenceModule.CopyEntitiesToClipboard;
var
  i : integer;
  Result : string;
begin
  Result := '';
  for i := 0 to FReferenceEntitiesRaw.Count - 1 do
  begin
    Result := Result + 'Game.ServerEntityManager.SpawnUnitWithFront(';
    Result := Result + Format('%.2f, %.2f, ', [FReferenceEntitiesRaw[i].Position.x, FReferenceEntitiesRaw[i].Position.z]);
    Result := Result + Format('%.2f, %.2f, ', [FReferenceEntitiesRaw[i].Front.x, FReferenceEntitiesRaw[i].Front.z]);
    Result := Result + Format('''%s''', [FReferenceEntitiesRaw[i].ScriptFile]);
    Result := Result + ', TEAMID);';
    Result := Result + sLineBreak;
  end;
  Clipboard.AsText := Result;
end;

constructor TReferenceModule.Create(Mouse : TMouse; Keyboard : TKeyboard);
begin
  inherited Create(Mouse, Keyboard);
  FReferenceEntitiesRaw := TList<REntityDescription>.Create;
  FReferenceEntities := TObjectList<TEntity>.Create;
  FWalkerProgress := TTimer.Create(4000);
  FWalkerIndices := TList<integer>.Create;
end;

destructor TReferenceModule.Destroy;
begin
  FWalkerIndices.Free;
  FWalkerProgress.Free;
  FReferenceEntitiesRaw.Free;
  FReferenceEntities.Free;
  inherited;
end;

function TReferenceModule.GetBoundingsOfEntity(index : integer) : RSphere;
begin
  Result := FReferenceEntities[index].Eventbus.Read(eiBoundings, []).AsType<RSphere>;
end;

function TReferenceModule.GetCorrespondingTab : TCategoryPanel;
begin
  Result := ToolWindow.ReferenceEntitiesTab;
end;

function TReferenceModule.GetEntityByIndex(index : integer) : TEntity;
begin
  if InRange(index, 0, FReferenceEntities.Count - 1) then
      Result := FReferenceEntities[index]
  else
      Result := nil;
end;

function TReferenceModule.GetEntityCount : integer;
begin
  Result := FReferenceEntitiesRaw.Count;
end;

function TReferenceModule.GetEntityDescription(index : integer) : REntityDescription;
begin
  Result := FReferenceEntitiesRaw[index];
end;

function TReferenceModule.GetEntityList : TListBox;
begin
  Result := ToolWindow.ReferenceEntitiesList;
end;

function TReferenceModule.GetPatternList : TListBox;
begin
  Result := ToolWindow.ReferenceEntityPatternList;
end;

procedure TReferenceModule.GUIEvent(Sender : TObject);
var
  i : integer;
begin
  inherited;
  if Sender = Hauptform.ShowReferenceEntities1 then
  begin
    Visible := Hauptform.ShowReferenceEntities1.Checked;
    for i := 0 to FReferenceEntities.Count - 1 do FReferenceEntities[i].Eventbus.Write(eiVisible, [Hauptform.ShowReferenceEntities1.Checked]);
  end;
end;

procedure TReferenceModule.Idle(MouseInRenderpanel : Boolean; GroundTarget : RVector3; Clickvector : RRay);
var
  Walker : TEntity;
  i, newWalkerIndex : integer;
  WalkSpeed : single;
begin
  inherited;
  if GetEntityList.HasSelection and FKeyboard.KeyUp(TasteF4) then
  begin
    newWalkerIndex := GetEntityList.SelectedIndices[0];
    Walker := GetEntityByIndex(newWalkerIndex);
    if FKeyboard.Shift then
    begin
      if assigned(Walker) then
      begin
        if FKeyboard.Strg then Walker.Eventbus.Trigger(eiPlayAnimation, [ANIMATION_ATTACK2, RParam.From<EnumAnimationPlayMode>(alSingle), 0])
        else Walker.Eventbus.Trigger(eiPlayAnimation, [ANIMATION_ATTACK, RParam.From<EnumAnimationPlayMode>(alSingle), 0]);
      end;
    end
    else
      if FKeyboard.Strg then
    begin
      if assigned(Walker) then
          Walker.Eventbus.Trigger(eiPlayAnimation, [ANIMATION_ABILITY_1, RParam.From<EnumAnimationPlayMode>(alSingle), 0]);
    end
    else
    begin
      if not FWalkerIndices.Contains(newWalkerIndex) then
      begin
        FWalkerIndices.Add(newWalkerIndex);
        if assigned(Walker) then
            Walker.Eventbus.Trigger(eiPlayAnimation, [ANIMATION_WALK, RParam.From<EnumAnimationPlayMode>(alLoop), 0]);
      end
      else
      begin
        FWalkerIndices.Remove(newWalkerIndex);
        if assigned(Walker) then
        begin
          Walker.Position := GetEntityDescription(newWalkerIndex).Position.XZ;
          Walker.Eventbus.Trigger(eiPlayAnimation, [ANIMATION_STAND, RParam.From<EnumAnimationPlayMode>(alLoop), 0]);
        end;
      end;
    end;
  end;
  for i := 0 to FWalkerIndices.Count - 1 do
  begin
    Walker := GetEntityByIndex(FWalkerIndices[i]);
    if assigned(Walker) then
    begin
      WalkSpeed := Walker.Eventbus.Read(eiSpeed, []).AsSingle * 1000;
      Walker.Position := (GetEntityDescription(FWalkerIndices[i]).Position + GetEntityDescription(FWalkerIndices[i]).Front * WalkSpeed * (frac(FWalkerProgress.ZeitDiffProzent) * 4 - 2)).XZ;
    end;
  end;
end;

procedure TReferenceModule.LoadMap(const Filename : string);
begin
  inherited;
  LoadReferenceFile(ChangeFileExt(Filename, '.dme'));
end;

procedure TReferenceModule.LoadReferenceFile(const Filename : string);
var
  temp : TList<REntityDescription>;
  i : integer;
begin
  FReferenceEntitiesRaw.Clear;
  FReferenceEntities.Clear;
  temp := TList<REntityDescription>.Create;
  HXMLSerializer.LoadObjectFromFile(temp, Filename);
  for i := 0 to temp.Count - 1 do Self.AddEntity(temp[i]);
  temp.Free;
  SyncToGUI;
end;

procedure TReferenceModule.ManipulateEntity();
begin
end;

procedure TReferenceModule.RefreshEntityFileList;
var
  i : integer;
begin
  UnitsFileList.Free;
  UnitsFileList := TStringList.Create;
  HFileIO.FindAllFiles(UnitsFileList, AbsolutePath(PATH_SCRIPT + '/Units/'), '*.ets');
  HFileIO.FindAllFiles(UnitsFileList, AbsolutePath(PATH_SCRIPT + '/BaseBuildings/'), '*.ets');
  HFileIO.FindAllFiles(UnitsFileList, AbsolutePath(PATH_SCRIPT + '/Units/'), '*.bds');
  HFileIO.FindAllFiles(UnitsFileList, AbsolutePath(PATH_SCRIPT + '/BaseBuildings/'), '*.bds');
  for i := UnitsFileList.Count - 1 downto 0 do
    if UnitsFileList[i].Contains('Spawner') or
      UnitsFileList[i].Contains('Template') or
      UnitsFileList[i].Contains('Drop') or
      UnitsFileList[i].Contains('_Base') or
      UnitsFileList[i].Contains('Building.') then UnitsFileList.Delete(i);
  SyncToGUI;
end;

procedure TReferenceModule.RemoveEntity(index : integer);
begin
  FReferenceEntitiesRaw.Delete(index);
  FReferenceEntities.Delete(index);
end;

procedure TReferenceModule.SaveMap(const Filename : string);
begin
  inherited;
  HXMLSerializer.SaveObjectToFile(FReferenceEntitiesRaw, ChangeFileExt(Filename, '.dme'));
end;

function TReferenceModule.SelectionIsFreezed : Boolean;
begin
  if ToolWindow.FreezeReferenceCheck.Checked then Result := True
  else Result := inherited;
end;

procedure TReferenceModule.UpdateEntityDescription(index : integer; Desc : REntityDescription);
var
  Entity : TEntity;
begin
  inherited;
  Desc.Position.y := 0;
  FReferenceEntitiesRaw[index] := Desc;
  Entity := FReferenceEntities[index];
  Entity.Position := Desc.Position.XZ;
  Entity.Front := Desc.Front.XZ;
  Entity.DisplayPosition := Desc.Position;
  Entity.DisplayFront := Desc.Front;
  Entity.DisplayUp := RVector3.UNITY;
  Entity.Eventbus.Write(eiSize, [RVector3.Create(Desc.Size)]);
  Entity.Eventbus.Write(eiTeamID, [1]);
end;

end.
