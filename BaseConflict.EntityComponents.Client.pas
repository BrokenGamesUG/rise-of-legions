unit BaseConflict.EntityComponents.Client;

interface

uses
  Generics.Collections,
  SysUtils,
  Classes,
  Math,
  Vcl.Forms,
  RegularExpressions,
  // ------- ThirdParty -----------
  FMOD.Common,
  FMOD.Studio.Common,
  FMOD.Studio.Classes,
  // ------- Engine ---------
  Engine.Mesh,
  Engine.ParticleEffects,
  Engine.Helferlein,
  Engine.Helferlein.Threads,
  Engine.Helferlein.Windows,
  Engine.Core,
  Engine.Core.Camera,
  Engine.Core.Types,
  Engine.Math,
  Engine.Animation,
  Engine.GUI,
  Engine.GUI.Editor,
  Engine.Vertex,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.GFXApi,
  Engine.GFXApi.Types,
  Engine.Log,
  Engine.Network,
  Engine.Network.RPC,
  Engine.Script,
  Engine.Input,
  // -------- Game ----------
  BaseConflict.Api,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Client,
  BaseConflict.Constants.Scenario,
  BaseConflict.Globals,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.Game,
  BaseConflict.Map,
  BaseConflict.Classes.MiniMap,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Types.Client,
  BaseConflict.Settings.Client,
  BaseConflict.Classes.Client;

type

  {$RTTI INHERIT}
  /// <summary> Each units gets this component at the client for determining the unit clicked onto. </summary>
  TClickCollisionComponent = class(TEntityComponent)
    public
      class var CLICK_BIAS : single;
    protected
      FLowPriority : boolean;
      FCapsule : RCapsule;
      {$IFDEF DEBUG}
      FFrame : integer;
      {$ENDIF}
      function CurrentCapsule : RCapsule;
    published
      [XEvent(eiGetUnitsAtCursor, epMiddle, etRead, esGlobal)]
      /// <summary> Returns this if hit by ray and more near than previous. </summary>
      function OnGetUnitsAtCursor(ClickRay : RParam; Previous : RParam) : RParam;
    public
      function SetCapsule(Origin, Endpoint : RVector3; Radius : single) : TClickCollisionComponent;
      function LowPriority : TClickCollisionComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> General Component that handle a changed option. Should be used for any option that not direct connect to any
  /// subsystem like GUI or Sound and so has no own ManagerComponent.</summary>
  TClientSettingsComponent = class(TEntityComponent)
    protected
      procedure HandleOption(Option : EnumClientOption);
      procedure Init;
    published
      [XEvent(eiClientOption, epLast, etTrigger, esGlobal)]
      /// <summary> Handle a option.</summary>
      function OnClientOption(Option : RParam) : boolean;
    public
      constructor Create(Entity : TEntity); override;
  end;

  {$RTTI INHERIT}

  ProcTokenCallBack = procedure(TokenMapping : TList<integer>) of object;

  RPingLogData = record
    Timestamp : int64;
    Ping : integer;
  end;

  /// <summary> Handles network for client. </summary>
  TClientNetworkComponent = class(TNetworkComponent)
    private const
      PING_LOG_INTERVAL = 2000;
    protected type
      TSocketPromise = class(TPromise<TTCPClientSocketDeluxe>);

      TReconnectThread = class(TThread)
        private const
          MAXTIME_FOR_TRYING    = 20000;
          TIME_BETWEEN_ATTEMPTS = 1000;
        private
          FReconnectTimer : TTimer;
          FAttemptTime : TTimer;
          FNewSocket : TSocketPromise;
          FServerAddress : RInetAddress;
          FLastReceivedIndex : integer;
          FToken : string;
        protected
          procedure Execute; override;
        public
          property NewSocket : TSocketPromise read FNewSocket;
          constructor Create(const ServerAddress : RInetAddress; LastReceivedIndex : integer; const Token : string);
          destructor Destroy; override;
      end;
    protected
      FTokenCallBack : ProcTokenCallBack;
      FTCPClientSocket : TTCPClientSocketDeluxe;
      FServerAddress : RInetAddress;
      FServerCrashedTimer : TTimer;
      FServerCrashedTimerStarted : boolean;
      FAuthentificationToken : string;
      FLastReceivedIndex : integer;
      FStopReconnect : boolean;
      FReconnectPromise : TSocketPromise;
      FFinishedReceivedGameData : ProcCallback;
      FPingLogTimer : TTimer;
      FPingLog : TList<RPingLogData>;
      procedure NewData(Data : TDatapacket); override;
      procedure DeserializeEntity(Stream : TStream);
      procedure Reconnect;
      procedure LogPing;
      procedure SendPingLog;
      procedure SendRageQuit;
      procedure BeforeComponentFree; override;
    published
      [XEvent(eiIdle, epFirst, etTrigger, esGlobal)]
      /// <summary> Handles networkdata. </summary>
      function OnIdle : boolean;
      [XEvent(eiClientReady, epLast, etTrigger, esGlobal)]
      function OnClientReady : boolean;
    public
      constructor Create(Owner : TEntity; Socket : TTCPClientSocketDeluxe; const AuthentificationToken : string; FinishedReceivedGameData : ProcCallback); reintroduce;
      function Ping : integer;
      procedure Send(Data : TCommandSequence); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Manages multicommander players. </summary>
  TCommanderManagerComponent = class(TEntityComponent)
    protected
      FCommander : TList<TEntity>;
      FActiveCommander : TEntity;
      FActiveIndex : integer;
    published
      [XEvent(eiChangeCommander, epMiddle, etTrigger, esGlobal)]
      /// <summary> Try to change the active commander. </summary>
      function OnChangeCommander(Index : RParam) : boolean;
      [XEvent(eiNewCommander, epLast, etTrigger, esGlobal)]
      /// <summary> Adds a new commander to the list. </summary>
      function OnNewCommander(Commander : RParam) : boolean;
    public
      function Count : integer;
      function HasActiveCommander : boolean;
      property ActiveCommander : TEntity read FActiveCommander;
      property ActiveCommanderIndex : integer read FActiveIndex;
      function ActiveCommanderTeamID : integer;

      procedure ChangeCommander(Index : integer);
      function GetCommanderByIndex(Index : integer) : TEntity;
      function TryGetCommanderByIndex(Index : integer; out Commander : TEntity) : boolean;
      procedure RegisterCommander(Commander : TEntity);
      procedure ClearCommanders;
      function EnumerateCommanders : TList<TEntity>;

      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles some commanderfunctionality like enumeration. </summary>
  TCommanderComponent = class(TEntityComponent)
    published
      [XEvent(eiEnumerateCommanders, epFirst, etRead, esGlobal)]
      /// <summary> Add this commander to the enumeration. </summary>
      function OnEnumerateCommanders(PrevValue : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Stifles eiFire events if the owner not belongs to your team. </summary>
  TClientFireTeamFilterComponent = class(TEntityComponent)
    published
      [XEvent(eiFire, epFirst, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles the camera. </summary>
  TClientCameraComponent = class(TEntityComponent)
    public const
      // top, right, bottom, left
      SCROLLBORDERWIDTH : RIntVector4 = (X : 10; Y : 10; Z : 2; W : 10);
    private
      procedure setFree(const Value : boolean);
      procedure setLocked(const Value : boolean);
    protected
      const
      CAMERA_ROTATION_SPEED = 0.008;
    var
      FRotation : single;
      FZoom : single;
      FCamPos : RVector2;
      FMoving, FHasMoved, FFree, FWasFree, FFreeLocked : boolean;
      FMousePos : RIntVector2;
      FMovedLength : single;
      FLeft, FUp, FRight, FBottom, FLaneLeft, FLaneRight : boolean;
      FDragPosition : RVector2;
      FTransitionTarget, FTransitionStart : RVector2;
      FTransitionDuration : TTimer;
      FTransition : boolean;
      FFreeCamera : RRay;
      procedure Scroll(Amount : single; Left, Up, Right, Bottom, LaneLeft, LaneRight : boolean);
      function MinZoom : single;
      function MaxZoom : single;
      procedure ResetZoom;
      procedure SetCamera(Position : RVector2);
      procedure MoveCamera(Translation : RVector2);
      procedure ClampCamera;
      procedure ApplyCamera;
      procedure ApplyOption(ChangedOption : EnumClientOption);
      function MouseWorldPosition : RVector2;
    published
      [XEvent(eiMouseMoveEvent, epHigh, etTrigger, esGlobal)]
      /// <summary> Moves the camera related to mouseevents. </summary>
      function OnMouseMoveEvent(Position, Difference : RParam) : boolean;
      [XEvent(eiKeybindingEvent, epHigh, etTrigger, esGlobal)]
      function OnKeybindingEvent() : boolean;
      [XEvent(eiMouseWheelEvent, epLast, etTrigger, esGlobal)]
      /// <summary> Zooms. </summary>
      function OnMouseWheelEvent(dZ : RParam) : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Set the camera in GFXD. </summary>
      function OnIdle : boolean;
      [XEvent(eiClientInit, epMiddle, etTrigger, esGlobal)]
      /// <summary> Initialized the camera at the nexus. </summary>
      function OnClientInit : boolean;
      [XEvent(eiCameraMoveTo, epLast, etTrigger, esGlobal)]
      /// <summary> Moves the camera to pos over duration. Ignore user Input while moving. </summary>
      function OnCameraMoveTo(Pos : RParam; TransitionDuration : RParam) : boolean;
      [XEvent(eiCameraMove, epMiddle, etTrigger, esGlobal)]
      /// <summary> Moves the camera to pos. Clips the position. </summary>
      function OnCameraMove(var Pos : RParam) : boolean;
      [XEvent(eiCameraPosition, epFirst, etRead, esGlobal)]
      function OnCameraPosition() : RParam;
      [XEvent(eiClientOption, epLast, etTrigger, esGlobal)]
      /// <summary> React to option changes. </summary>
      function OnClientOption(ChangedOption : RParam) : boolean;
      [XEvent(eiMiniMapMoveToEvent, epLast, etTrigger, esGlobal)]
      /// <summary> Move to minimap position. </summary>
      function OnMiniMapMoveToEvent(WorldPosition : RParam) : boolean;
      [XEvent(eiClientCommand, epMiddle, etTrigger, esGlobal)]
      function OnClientCommand(ClientCommand, Param1 : RParam) : boolean;
    public
      EnableScrollingBorder : boolean;
      Vertical, FreeSlow : boolean;
      property FreeCamera : boolean read FFree write setFree;
      property Locked : boolean read FFreeLocked write setLocked;
      procedure ResetPosition;
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Describes a commander spell, which the user is settings targets for.
  /// The abilitybuttons are owning each one of this as a pattern, and if the user activates a spell
  /// the Inputhandler copies it and gather targets of the user input to finally execute the spell. </summary>
  TCommanderSpellData = class
    protected
      type
      ProcDoSomethingWithTarget = reference to procedure(Target : PCommanderAbilityTarget);
    var
      FGlobalEventbus : TEventbus;
      FIsInMode : integer;
      procedure ApplyToNextTarget(proc : ProcDoSomethingWithTarget);
    public
      EntityID : integer;                 // Commander
      ComponentGroup : SetComponentGroup; // Spellgroup
      Targets : ACommanderAbilityTarget;  // Targets
      Range : single;                     // max distance between targets if > 0
      ClosesTooltip, IsSpawner, IsDrop, IsSpell, IsEpic : boolean;
      MultiModes : TArray<byte>;
      constructor Create(GlobalEventbus : TEventbus; EntityID : integer; ComponentGroup : SetComponentGroup; Targets : array of RCommanderAbilityTarget; Range : single);
      function TryGetCommander(out Commander : TEntity) : boolean;
      function NextTargetType : EnumCommanderAbilityTargetType;
      function TargetCount : integer;
      function AllTargetsSet : boolean;
      function IsMultiMode : boolean;
      function IsReady : boolean;
      /// <summary> Returns true if any of the already set targets is invalid </summary>
      function AnySetTargetIsInvalid : boolean;
      procedure SetCoordinateTarget(Position : RVector2);
      procedure SetEntityTarget(Entity : TEntity);
      procedure SetBuildgridTarget(BuildZoneID : integer; Coordinate : RIntVector2);
      function HasEntityTarget(Entity : TEntity) : boolean;
      function WouldEntityBeValidTarget(Entity : TEntity) : boolean;
      procedure Execute;
      procedure Visualize;
      procedure HideVisualization;
      procedure Unset;
      function Copy : TCommanderSpellData;
  end;

  /// <summary> Handles all input of the user. </summary>
  TClientInputComponent = class(TEntityComponent)
    private
      FLastCursorPos : RIntVector2;
      FWorldMousePosition : RVector2;
      FClickVector : RRay;
      FPreparedSpell : TCommanderSpellData;
      FSpellPreparedOnMouseDown : boolean;
      FDropZoneRenderer : TZoneRenderer;
      procedure PrepareAction(CustomData : TCommanderSpellData);
      function IsActionPrepared : boolean;
      function ApplyGridOffset(Spell : TCommanderSpellData; BuildZone : TBuildZone; Pos : RVector2) : RIntVector2;
      procedure UpdateTargetDisplay;
      function WaitingForSpellTargets : boolean;
      procedure SetNextTarget(Spell : TCommanderSpellData);
      /// <summary> Returns the first matching unit for the spell. </summary>
      function TryGetTargetableUnitAtCursor(Spell : TCommanderSpellData; out UnitAtCursor : TEntity) : boolean;
      function GetUnitsAtCursor() : TList<RTuple<single, TEntity>>;
      /// <summary> Returns the foremost unit at the cursor. </summary>
      function TryGetUnitAtCursor(out UnitAtCursor : TEntity) : boolean;
      procedure UpdateCursorPos(Position : RIntVector2);
      procedure OnCommanderAbilityClick(CommanderSpellData : TCommanderSpellData; MouseEvent : EnumGUIEvent);
    published
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      /// <summary> Clear any prepared action. </summary>
      function OnLose(TeamID : RParam) : boolean;
      [XEvent(eiChangeCommander, epLast, etTrigger, esGlobal)]
      /// <summary> Refreshes the commanderswitch. </summary>
      function OnChangeCommander(Index : RParam) : boolean;
      [XEvent(eiCameraMove, epLast, etTrigger, esGlobal)]
      /// <summary> Update world-cursor. </summary>
      function OnCameraMove(Pos : RParam) : boolean;
      [XEvent(eiKeybindingEvent, epLast, etTrigger, esGlobal)]
      /// <summary> Hotkeys for build/spellabilities. </summary>
      function OnKeybindingEvent() : boolean;
      [XEvent(eiMouseMoveEvent, epLast, etTrigger, esGlobal)]
      /// <summary> Handles commanderability preview or the use of an ability. </summary>
      function OnMouseMoveEvent(Position, Difference : RParam) : boolean;
      [XEvent(eiIdle, epLow, etTrigger, esGlobal)]
      /// <summary> Updates the abilitypreview. </summary>
      function OnIdle : boolean;
    public
      constructor Create(Owner : TEntity); override;
      procedure ClearAction();
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles the gui. </summary>
  TClientGUIComponent = class(TEntityComponent)
    protected
      FHealthbars : TGUIComponent;
      FFirstGameTick : boolean;
      procedure UpdateDisplays;
    published
      [XEvent(eiGameCommencing, epLast, etTrigger, esGlobal)]
      /// <summary> Update Hud. </summary>
      function OnGameCommencing() : boolean;
      [XEvent(eiGameEvent, epLast, etTrigger, esGlobal)]
      function OnGameEvent(const EventUID : RParam) : boolean;
      [XEvent(eiChangeCommander, epHigh, etTrigger, esGlobal)]
      /// <summary> Refreshes the commanderswitch. </summary>
      function OnChangeCommander(Index : RParam) : boolean;
      [XEvent(eiNewCommander, epLast, etTrigger, esGlobal)]
      /// <summary> Updates the commanderswitch. </summary>
      function OnAddCommander(Entity : RParam) : boolean;
      [XEvent(eiKeybindingEvent, epMiddle, etTrigger, esGlobal)]
      /// <summary> React on some debugkeys. </summary>
      function OnKeybindingEvent() : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Updates the resource displays. </summary>
      function OnIdle : boolean;
      [XEvent(eiClientInit, epHigh, etTrigger, esGlobal)]
      /// <summary> Initializes the score board the active commander. </summary>
      function OnClientInit : boolean;
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal)]
      function OnGameTick() : boolean;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  TLogicToWorldComponent = class(TEntityComponent)
    published
      [XEvent(eiDisplayPosition, epFirst, etRead)]
      /// <summary> Return saved logic position. </summary>
      function OnDisplayPosition() : RParam;
      [XEvent(eiDisplayFront, epFirst, etRead)]
      /// <summary> Return saved logic front. </summary>
      function OnDisplayFront() : RParam;
      [XEvent(eiDisplayUp, epFirst, etRead)]
      /// <summary> Return saved up. </summary>
      function OnDisplayUp() : RParam;
      [XEvent(eiAfterCreate, epMiddle, etTrigger)]
      /// <summary> Updates the displayed properties of the entity. </summary>
      function OnAfterCreate : boolean;
      [XEvent(eiIdle, epHigh, etTrigger, esGlobal)]
      /// <summary> Updates the displayed properties of the entity. </summary>
      function OnIdle : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Clientspecific methods. </summary>
  TClientEntityManagerComponent = class(TEntityManagerComponent)
    protected
      FFinishTimer, FEndScreenTimer : TTimer;
      FVictory : boolean;
    published
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      /// <summary> Kill client if lose. </summary>
      function OnLose(TeamID : RParam) : boolean;
      [XEvent(eiGUIEvent, epLast, etTrigger, esGlobal)]
      /// <summary> Handles the continue button. </summary>
      function OnGUIEvent(Event : RParam) : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Handle termination of game. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Kills the entity on finishing the game. </summary>
  TSuicideOnGameEndComponent = class(TEntityComponent)
    published
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      function OnLose(TeamID : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  TMiniMapComponent = class(TEntityComponent)
    protected
      FMiniMap : TMiniMap;
      FMouseDown : boolean;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Updates and renders the positions of the markers. </summary>
      function OnIdle() : boolean;
      [XEvent(eiKeybindingEvent, epMiddle, etTrigger, esGlobal)]
      /// <summary> Clicking on the minimap triggers a minimap event. </summary>
      function OnKeybindingEvent() : boolean;
      [XEvent(eiMouseMoveEvent, epHigh, etTrigger, esGlobal)]
      /// <summary> Moves the camera related to mouseevents. </summary>
      function OnMouseMoveEvent(Position, Difference : RParam) : boolean;
    public
      property MiniMap : TMiniMap read FMiniMap;
      constructor Create(Owner : TEntity); override;
      procedure AddToMinimap(Entity : TEntity; IconPath : string; IconSize : single);
      procedure RemoveFromMinimap(Entity : TEntity);
      destructor Destroy(); override;
  end;

  {$RTTI INHERIT}

  TGameIntensityComponent = class(TEntityComponent)
    published
      [XEvent(eiShortestBattleFrontDistance, epFirst, etRead, esGlobal)]
      /// <summary> Returns distance. </summary>
      function OnShortestBattleFrontDistance(Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Renders the buildgrid. Displays the spawn mechanics. </summary>
  TBuildGridManagerComponent = class(TEntityComponent)
    protected
      type
      TTile = class
        strict private
        const
          GLOW_TIME_IN         = 500;
          GLOW_TIME_OUT        = 1000;
          GLOW_INTENSITY       = 0.032;
          GLOW_COLOR_INTENSITY = 0.4;
        strict private
          FBuildZone : TBuildZone;
          FCoordinate : RIntVector2;
          FMesh : TMesh;
          FIsActive : boolean;
          FGlowTransition : TGUITransitionValueSingle;
          procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
        public
          property BuildZone : TBuildZone read FBuildZone;
          property Coordinate : RIntVector2 read FCoordinate;
          property Mesh : TMesh read FMesh;
          property IsActive : boolean read FIsActive;
          constructor Create(BuildZone : TBuildZone; const Coordinate : RIntVector2);
          procedure Activate;
          procedure Reset;
          destructor Destroy; override;
      end;

      TBuildGridVisualizer = class
        strict private
          FActivateEffect : TParticleEffect;
          FTiles : TObjectList<TTile>;
          FCurrentRotationCount, FFieldCount : integer;
        public
          property CurrentRotationCount : integer read FCurrentRotationCount;
          property FieldCount : integer read FFieldCount;
          procedure Spawn(const Coordinate : RIntVector2);
          procedure Reset;

          /// <summary> Render occupied tiles red and others green. </summary>
          procedure ShowOccupation(const ReferencePosition : RVector2; TeamID : integer);
          /// <summary> All tiles are rendered red. </summary>
          procedure ShowInvalid;
          /// <summary> All tiles are reset to uncolored. </summary>
          procedure ResetColors;

          constructor Create(BuildZone : TBuildZone);
          destructor Destroy; override;
      end;
    var
      FBuildGridVisualizers : TObjectDictionary<integer, TBuildGridVisualizer>;
    published
      [XEvent(eiWaveSpawn, epLast, etTrigger, esGlobal)]
      /// <summary> Updates tile states. </summary>
      function OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      /// <summary> Render occupied tiles red and others green. </summary>
      function ShowOccupation(const ReferencePosition : RVector2; TeamID : integer) : TBuildGridManagerComponent;
      /// <summary> All tiles are rendered red. </summary>
      function ShowInvalid : TBuildGridManagerComponent;
      /// <summary> All tiles are reset to uncolored. </summary>
      function ResetColors : TBuildGridManagerComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  TVertexTraceManagerComponent = class(TEntityComponent)
    protected type
      TVertexTraceHandle = class
        Trace : TVertexTrace;
        RollUpSpeed : single;
        constructor Create(Trace : TVertexTrace; RollUpSpeed : single);
        destructor Destroy; override;
      end;
    protected
      FTraces : TObjectList<TVertexTraceHandle>;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Handle Traces. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); reintroduce;
      procedure AddTrace(Trace : TVertexTrace; RollUpSpeed : single);
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles the procedural death effect of units. </summary>
  TUnitDecayManagerComponent = class(TEntityComponent)
    protected type
      TDecayingUnit = class
        Mesh : TMesh;
        DecayTimer : TTimer;
        constructor Create;
        destructor Destroy; override;
      end;
    protected
      FDecayingUnits : TObjectList<TDecayingUnit>;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Free entities which are decayed finally. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); reintroduce;
      procedure AddMesh(Mesh : TMesh; ColorIdentity : EnumEntityColor);
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}
  {$REGION 'TutorialDirectorActions'}

  TTutorialDirectorComponent = class;

  TTutorialDirectorAction = class abstract
    protected
      FOwner : TTutorialDirectorComponent;
    public
      procedure Execute; virtual; abstract;
  end;

  TTutorialDirectorActionSendGameevent = class(TTutorialDirectorAction)
    strict private
      FEventnames : TArray<string>;
    public
      function Eventname(const Eventname : string) : TTutorialDirectorActionSendGameevent;
      procedure Execute; override;
  end;

  TTutorialDirectorActionWorld = class(TTutorialDirectorAction)
    private
      FPosition, FLeft, FUp : RVector3;
      FSize : RVector2;
      FColor : RColor;
    public
      constructor Create;
      function Position(const X, Y, Z : single) : TTutorialDirectorActionWorld;
      function Left(const X, Y, Z : single) : TTutorialDirectorActionWorld;
      function Up(const X, Y, Z : single) : TTutorialDirectorActionWorld;
      function Size(const Width, Height : single) : TTutorialDirectorActionWorld;
      function Color(const Color : cardinal) : TTutorialDirectorActionWorld;
  end;

  TTutorialDirectorActionScript = class(TTutorialDirectorAction)
    private
      FScript, FEntityUID : string;
      FEntityID : integer;
    public
      constructor Create;
      function Scriptfile(const Filename : string) : TTutorialDirectorActionScript;
      function Entity(const EntityID : integer) : TTutorialDirectorActionScript; overload;
      function Entity(const EntityUID : string) : TTutorialDirectorActionScript; overload;
      procedure Execute; override;
  end;

  TTutorialDirectorActionWorldText = class(TTutorialDirectorActionWorld)
    strict private
      FWorldToPixelFactor, FFontHeight : single;
      FText : string;
    public
      constructor Create;
      function Text(const Text : string) : TTutorialDirectorActionWorldText;
      function WorldToPixelFactor(const Factor : single) : TTutorialDirectorActionWorldText;
      function FontHeight(const FontHeight : single) : TTutorialDirectorActionWorldText;
      procedure Execute; override;
  end;

  TTutorialDirectorActionTutorialHint = class(TTutorialDirectorAction)
    strict private
      FText, FButtonText : string;
      FIsWindow, FClear : boolean;
      FPosition : RIntVector2;
    public
      function Text(const Text : string) : TTutorialDirectorActionTutorialHint;
      function Passive : TTutorialDirectorActionTutorialHint;
      function ButtonText(const ButtonText : string) : TTutorialDirectorActionTutorialHint;
      function Clear : TTutorialDirectorActionTutorialHint;
      procedure Execute; override;
  end;

  TTutorialDirectorActionGUIElement = class(TTutorialDirectorAction)
    strict private
      FElements, FAddClass, FRemoveClass : TArray<string>;
      FHide, FEnable, FClearLock, FClearVisibility, FDisable : boolean;
    public
      function Element(const ElementUID : string) : TTutorialDirectorActionGUIElement;
      function LoadElementsFromGroup(const GroupName : string) : TTutorialDirectorActionGUIElement;
      function Hide : TTutorialDirectorActionGUIElement;
      function Lock : TTutorialDirectorActionGUIElement;
      function Unlock : TTutorialDirectorActionGUIElement;
      function Clear : TTutorialDirectorActionGUIElement;
      function ClearLock : TTutorialDirectorActionGUIElement;
      function ClearVisibility : TTutorialDirectorActionGUIElement;
      function AddClass(const Classname : string) : TTutorialDirectorActionGUIElement;
      function RemoveClass(const Classname : string) : TTutorialDirectorActionGUIElement;
      procedure Execute; override;
      destructor Destroy; override;
  end;

  TTutorialDirectorActionKeybinding = class(TTutorialDirectorAction)
    strict private
      FKeybindings : TArray<EnumKeybinding>;
      FBlock : boolean;
    public
      function Keybinding(const Keybinding : EnumKeybinding) : TTutorialDirectorActionKeybinding;
      function LoadElementsFromGroup(const GroupName : string) : TTutorialDirectorActionKeybinding;
      function Block : TTutorialDirectorActionKeybinding;
      function Unblock : TTutorialDirectorActionKeybinding;
      procedure Execute; override;
      destructor Destroy; override;
  end;

  TTutorialDirectorActionArrowHighlight = class(TTutorialDirectorAction)
    strict private
      FWorldPoint : RVector3;
      FWorldRadius : single;
      FText, FElement, FWindowButton : string;
      FElementAnchor, FWindowAnchor : EnumComponentAnchor;
      FLockGUI, FClear, FNoBackdrop, FNoArrow : boolean;
    public
      constructor Create;
      function Text(const Text : string) : TTutorialDirectorActionArrowHighlight;
      function WorldPoint(const PointX, PointY, PointZ : single) : TTutorialDirectorActionArrowHighlight;
      function WorldRadius(const Radius : single) : TTutorialDirectorActionArrowHighlight;
      function LoadElementFromGroup(const GroupName : string) : TTutorialDirectorActionArrowHighlight;
      function Element(const ElementUID : string) : TTutorialDirectorActionArrowHighlight;
      function ElementAnchor(Anchor : EnumComponentAnchor) : TTutorialDirectorActionArrowHighlight;
      function WindowAnchor(Anchor : EnumComponentAnchor) : TTutorialDirectorActionArrowHighlight;
      function WindowButton(const ButtonText : string) : TTutorialDirectorActionArrowHighlight;
      function NoBackdrop : TTutorialDirectorActionArrowHighlight;
      function NoArrow : TTutorialDirectorActionArrowHighlight;
      function LockGUI : TTutorialDirectorActionArrowHighlight;
      function Clear : TTutorialDirectorActionArrowHighlight;
      procedure Execute; override;
  end;

  TTutorialDirectorActionWorldTexture = class(TTutorialDirectorActionWorld)
    strict private
      FTexturePath : string;
    public
      function TexturePath(const TexturePath : string) : TTutorialDirectorActionWorldTexture;
      procedure Execute; override;
  end;

  TTutorialDirectorActionHUD = class(TTutorialDirectorAction)
    strict private
      FPreventConsecutiveCardPlay : EnumNullableBoolean;
    public
      function PreventMultiCardPlay() : TTutorialDirectorActionHUD;
      function AllowMultiCardPlay() : TTutorialDirectorActionHUD;
      procedure Execute; override;
  end;

  TTutorialDirectorActionClearWorldObjects = class(TTutorialDirectorAction)
    public
      procedure Execute; override;
  end;

  TTutorialDirectorActionCamera = class(TTutorialDirectorAction)
    protected
      FSpawnerJumpEnabled : boolean;
    public
      function SpawnerJumpAllowed : TTutorialDirectorActionCamera;
  end;

  TTutorialDirectorActionLockCamera = class(TTutorialDirectorActionCamera)
    protected
      FLimit : boolean;
      FThreshold : single;
    public
      function LimitX(Threshold : single) : TTutorialDirectorActionLockCamera;
      procedure Execute; override;
  end;

  TTutorialDirectorActionUnlockCamera = class(TTutorialDirectorActionCamera)
    public
      procedure Execute; override;
  end;

  TTutorialDirectorActionMoveCamera = class(TTutorialDirectorAction)
    strict private
      FTargetPos : RVector2;
      FTime : integer;
      FFollow : boolean;
    public
      function MoveTo(X, Y : single) : TTutorialDirectorActionMoveCamera;
      function Time(Time : integer) : TTutorialDirectorActionMoveCamera;
      function FollowLastSpawnedEntity : TTutorialDirectorActionMoveCamera;
      procedure Execute; override;
  end;

  TTutorialDirectorActionGotoStep = class(TTutorialDirectorAction)
    strict private
      FStepUID : string;
    public
      function UID(const StepUID : string) : TTutorialDirectorActionGotoStep;
      procedure Execute; override;
  end;
  {$ENDREGION}

  EnumStepTrigger = (stNever, stEvent, stGameTick, stNewEntity, stClientInit, stTime, stLastUnitDies, stCamPos, stUnitsDead);
  SetStepTrigger = set of EnumStepTrigger;

  TTutorialDirectorStep = class
    strict private
      FOwner : TTutorialDirectorComponent;
    public
      Eventname, StepUID : string;
      FUnitUIDs : TArray<string>;
      FOptional : boolean;
      GameTick, TriggerCount, TriggeredTimes : integer;
      TriggerOn : EnumStepTrigger;
      UnitPropertyMustHave : SetUnitProperty;
      Actions : TObjectList<TTutorialDirectorAction>;
      Timer : TTimer;
      TargetCamPos : RCircle;
      constructor Create(Owner : TTutorialDirectorComponent);
      function IncrementAndCheckTriggerCount : boolean;
      function CheckUIDDead : boolean;
      function CheckTimeTrigger : boolean;
      function CheckLastUnitDiesTrigger(UnitID : integer) : boolean;
      function CheckGameEventTrigger(const GameEvent : string) : boolean;
      function CheckNewEntityTrigger(Entity : TEntity) : boolean;
      function CheckClientInitTrigger : boolean;
      function CheckGameTickTrigger(CurrentGameTick : integer) : boolean;
      function CheckCamPos : boolean;
      destructor Destroy; override;
  end;

  /// <summary> Handles all actions in the tutorial. </summary>
  TTutorialDirectorComponent = class(TEntityComponent)
    strict private
      FActionQueue : TObjectList<TTutorialDirectorStep>;
      FFirstGameTickSend, FExecuting : boolean;
      FCurrentGameTick : integer;
      FCurrentStepIndex : integer;
      FUnitFilterMustHave, FUnitFilterMustNotHave : SetUnitProperty;
      /// <summary> Returns all coming steps from the current execution point to the next mandatory step. Nil if no more steps are ahead. </summary>
      function CurrentSteps : TArray<TTutorialDirectorStep>;
      /// <summary> Returns all coming step triggers from the current execution point to the next mandatory step. Empty if no more steps are ahead. </summary>
      function CurrentStepsTriggers : SetStepTrigger;
      /// <summary> Executes the specified step if not executing another step at the moment. </summary>
      procedure ExecuteStep(Step : TTutorialDirectorStep);
      /// <summary> Executes all actions of the specified step. </summary>
      procedure ExecuteStepActions(Step : TTutorialDirectorStep);
      /// <summary> Moves the execution point to the next step. Not executing anything. Should be called before
      /// executing steps as they can manipulate the execution point. </summary>
      procedure NextStep;
    protected
      FWorldObjects : TObjectList<TVertexObject>;
      FLastUnit : integer;
      procedure DoGotoStep(StepLabel : string);
    protected
      class var FGroups : TDictionary<string, TArray<string>>;
      class var FKeybindingGroups : TDictionary<string, TArray<EnumKeybinding>>;
      class constructor Create;
      class destructor Destroy;
    published
      [XEvent(eiIdle, epLast, etTrigger, esGlobal)]
      function OnIdle() : boolean;
      [XEvent(eiGameEvent, epLast, etTrigger, esGlobal)]
      function OnGameEvent(Eventname : RParam) : boolean;
      [XEvent(eiClientInit, epLower, etTrigger, esGlobal)]
      function OnClientInit : boolean;
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal)]
      function OnGameTick() : boolean;
      [XEvent(eiNewEntity, epLast, etTrigger, esGlobal)]
      function OnNewEntity(NewEntity : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      function AddStepNever() : TTutorialDirectorComponent;
      function AddStepClientInit() : TTutorialDirectorComponent;
      function AddStepGameEvent(const GameEvent : string) : TTutorialDirectorComponent;
      function AddStepUIDsDead(const UIDs : TArray<string>) : TTutorialDirectorComponent;
      function AddStepNewEntity(MustHave : TArray<byte>) : TTutorialDirectorComponent;
      function AddStepGameTick(const GameTick : integer) : TTutorialDirectorComponent;
      function AddStepTimer(const Interval : integer) : TTutorialDirectorComponent;
      function AddStepLastEntityDies() : TTutorialDirectorComponent;
      function AddStepCamPos(X, Y, Range : single) : TTutorialDirectorComponent;
      function StepTriggerCount(const StepTriggerCount : integer) : TTutorialDirectorComponent;
      function StepLabel(const StepLabel : string) : TTutorialDirectorComponent;
      function StepIsOptional : TTutorialDirectorComponent;
      function IfGameEventGotoStep(const GameEvent : string; const TargetLabel : string) : TTutorialDirectorComponent;
      function IfGameTickGotoStep(const GameTick : integer; const TargetLabel : string) : TTutorialDirectorComponent;
      function IfTimerGotoStep(const Interval : integer; const TargetLabel : string) : TTutorialDirectorComponent;
      function IfLastEntityDiesGotoStep(const TargetLabel : string) : TTutorialDirectorComponent;
      function AddAction(const Action : TTutorialDirectorAction) : TTutorialDirectorComponent;
      function AddActions(const A1 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4, A5 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4, A5, A6 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4, A5, A6, A7 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4, A5, A6, A7, A8 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4, A5, A6, A7, A8, A9 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4, A5, A6, A7, A8, A9, A10 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function AddActions(const A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11 : TTutorialDirectorAction) : TTutorialDirectorComponent; overload;
      function BuildElementGroup(const GroupName : string; const Elements : TArray<string>) : TTutorialDirectorComponent;
      function BuildKeybindingGroup(const GroupName : string; const Keybindings : TArray<byte>) : TTutorialDirectorComponent;
      // shortcuts
      function HideGroup(const GroupName : string) : TTutorialDirectorComponent;
      function LockGroup(const GroupName : string) : TTutorialDirectorComponent;
      function UnlockGroup(const GroupName : string) : TTutorialDirectorComponent;
      function UnshadowGroup(const GroupName : string) : TTutorialDirectorComponent;
      function ClearGroupUnshadow(const GroupName : string) : TTutorialDirectorComponent;
      function ClearGroupLock(const GroupName : string) : TTutorialDirectorComponent;
      function ClearGroupStates(const GroupName : string) : TTutorialDirectorComponent;
      function SendGameevent(const Eventname : string) : TTutorialDirectorComponent;
      function GotoStep(const StepLabel : string) : TTutorialDirectorComponent;
      function LockCamera : TTutorialDirectorComponent;
      function UnlockCamera : TTutorialDirectorComponent;
      function MoveCamera(X, Y : single) : TTutorialDirectorComponent;
      function MoveCameraOverTime(X, Y : single; Time : integer) : TTutorialDirectorComponent;
      function ClearWorldObjects : TTutorialDirectorComponent;
      function ClearTutorialHint : TTutorialDirectorComponent;
      function GroundText(X : single; const Text : string) : TTutorialDirectorComponent;
      function PassiveText(const Text, ButtonText : string) : TTutorialDirectorComponent;
      function PreventMultiCardPlay : TTutorialDirectorComponent;
      function AllowMultiCardPlay : TTutorialDirectorComponent;
      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals.Client,
  BaseConflict.Map.Client,
  BaseConflict.Classes.Gamestates.GUI,
  BaseConflict.EntityComponents.Client.GUI;

{ TClientNetworkComponent }

constructor TClientNetworkComponent.Create(Owner : TEntity; Socket : TTCPClientSocketDeluxe; const AuthentificationToken : string; FinishedReceivedGameData : ProcCallback);
begin
  inherited Create(Owner);
  FPingLog := TList<RPingLogData>.Create;
  FPingLogTimer := TTimer.CreateAndStart(PING_LOG_INTERVAL);
  FServerAddress := Socket.RemoteInetAddress;
  FTCPClientSocket := Socket;
  FTCPClientSocket.SendCommand(NET_CLIENT_ENTER_CORE);
  FFinishedReceivedGameData := FinishedReceivedGameData;
  FAuthentificationToken := AuthentificationToken;
end;

procedure TClientNetworkComponent.DeserializeEntity(Stream : TStream);
var
  Entity : TEntity;
  EntityID : integer;
begin
  EntityID := Stream.ReadInteger;
  if not Game.EntityManager.HasEntityByID(EntityID) then
  begin
    Entity := TEntity.Deserialize(EntityID, Stream, GlobalEventbus, nil{ ENTITYCOMPONENTCLASSMAPPING });
    TLogicToWorldComponent.Create(Entity);
    Entity.Eventbus.Trigger(eiAfterCreate, []);
    Entity.Deploy;
  end;
end;

destructor TClientNetworkComponent.Destroy;
begin
  SendPingLog;
  FTCPClientSocket.Free;
  FServerCrashedTimer.Free;
  FPingLogTimer.Free;
  FPingLog.Free;
  inherited;
end;

procedure TClientNetworkComponent.LogPing;
var
  NewLog : RPingLogData;
begin
  if FPingLogTimer.Expired then
  begin
    NewLog.Timestamp := TimeManager.GetTimeStamp;
    if assigned(FTCPClientSocket) then
        NewLog.Ping := FTCPClientSocket.Ping
    else
        NewLog.Ping := -2;
    FPingLog.Add(NewLog);
    FPingLogTimer.Start;
  end;
end;

procedure TClientNetworkComponent.NewData(Data : TDatapacket);
var
  DataStream : TStream;
  Count, i, ErrorCode : integer;
  ErrorMessage : string;
begin
  case Data.Command of
    NET_SERVER_FINISHED_SEND_GAME_DATA :
      begin
        FFinishedReceivedGameData();
      end;
    NET_NEW_ENTITY :
      begin
        Count := Data.Read<integer>;
        for i := 0 to Count - 1 do
        begin
          DataStream := Data.ReadStream;
          DeserializeEntity(DataStream);
          DataStream.Free;
        end;
      end;
    NET_SECURITY_ERROR :
      begin
        ErrorCode := Data.Read<integer>;
        ErrorMessage := Data.ReadString;
        AccountAPI.SendCustomBugReport('Connect to server failed: ' + IntToStr(ErrorCode) + ' ' + 'ErrorMessage', '').Free;
        ClientGame.GameState := gsCrashed;
      end;
    NET_SERVER_GAME_ABORTED :
      begin
        ClientGame.GameState := gsAborted;
      end;
    NET_RECONNECT_RESULT :
      begin
        if Data.Read<boolean> then
        begin
          ClientGame.GameState := gsRunning;
        end
        else
        begin
          ErrorMessage := Data.ReadString;
          AccountAPI.SendCustomBugReport('Reconnect failed. Reason: ' + ErrorMessage, '').Free;
          ClientGame.GameState := gsCrashed;
        end;
      end
  else inherited NewData(Data);
  end;
  FLastReceivedIndex := Data.Read<integer>;
end;

procedure TClientNetworkComponent.BeforeComponentFree;
begin
  SendRageQuit;
  inherited;
end;

function TClientNetworkComponent.OnClientReady : boolean;
begin
  Result := True;
  if assigned(FTCPClientSocket) and FTCPClientSocket.IsConnected then
      FTCPClientSocket.SendCommand(NET_CLIENT_READY);
end;

function TClientNetworkComponent.OnIdle : boolean;
var
  Datapacket : TDatapacket;
begin
  if Keyboard.Strg and Keyboard.Alt and Keyboard.KeyUp(Taste‹) and not FStopReconnect then
  begin
    FTCPClientSocket.CloseConnection;
    FStopReconnect := True;
  end;

  if Keyboard.Strg and Keyboard.Alt and Keyboard.KeyUp(Taste÷) then
  begin
    FStopReconnect := False;
  end;

  Result := True;

  LogPing;

  while FTCPClientSocket.IsDataPacketAvailable do
  begin
    Datapacket := FTCPClientSocket.ReceiveDataPacket;
    assert(assigned(Datapacket));
    NewData(Datapacket);
    Datapacket.Free;
  end;

  if (FTCPClientSocket.Status = TCPStDisconnected) then
  begin
    if ClientGame.GameState = gsPreparing then
    begin
      Hlog.Log('Client lost connection to game server after loading and before token mapping.');
      ClientGame.GameState := gsCrashed;
    end
    else if ClientGame.GameState = gsRunning then
    begin
      Hlog.Log('Reconnecting game...');
      // only reconnect if player is not specator
      if not (FAuthentificationToken <> '') then
          Reconnect
      else
          ClientGame.GameState := gsCrashed;
    end
    else if ClientGame.GameState = gsReconnecting then
    begin
      if FReconnectPromise.IsFinished then
      begin
        if FReconnectPromise.WasSuccessful then
        begin
          FTCPClientSocket.Free;
          FTCPClientSocket := FReconnectPromise.Value;
          ClientGame.GameState := gsRunning;
        end
        else
        begin
          AccountAPI.SendCustomBugReport('Client lost connection to server. Reason: ' + FTCPClientSocket.DisconnectReason +
            ', Reconnecting failed. Reason: ' + FReconnectPromise.ErrorMessage, '').Free;
          ClientGame.GameState := gsCrashed;
        end;
        FReconnectPromise.Free;
      end;
    end;
  end;

  // update servertime
  Game.ServerTime := FTCPClientSocket.GetCurrentPeerTime;
end;

function TClientNetworkComponent.Ping : integer;
begin
  Result := FTCPClientSocket.Ping;
end;

procedure TClientNetworkComponent.Reconnect;
begin
  if ClientGame.GameState in [gsRunning] then
  begin
    FReconnectPromise := TReconnectThread.Create(FServerAddress, FLastReceivedIndex, FAuthentificationToken).NewSocket;
    ClientGame.GameState := gsReconnecting;
  end;
end;

procedure TClientNetworkComponent.Send(Data : TCommandSequence);
begin
  assert(assigned(FTCPClientSocket));
  FTCPClientSocket.SendData(Data);
end;

procedure TClientNetworkComponent.SendPingLog;
var
  DataArray : TArray<TArray<int64>>;
  i : integer;
begin
  try
    setLength(DataArray, FPingLog.Count);
    for i := 0 to length(DataArray) - 1 do
        DataArray[i] := TArray<int64>.Create(FPingLog[i].Timestamp, FPingLog[i].Ping);
    AccountAPI.SendPingLog(DataArray).Free;
  except
    // mute any errors
  end;
end;

procedure TClientNetworkComponent.SendRageQuit;
var
  SendData : TCommandSequence;
begin
  if assigned(FTCPClientSocket) and FTCPClientSocket.IsConnected and assigned(ClientGame) and not(ClientGame.GameState in [gsFinishing, gsFinished]) then
  begin
    SendData := TCommandSequence.Create(NET_CLIENT_RAGE_QUIT);
    FTCPClientSocket.SendData(SendData);
    SendData.Free;
  end;
end;

{ TClientInputManager }

function TClientInputComponent.ApplyGridOffset(Spell : TCommanderSpellData; BuildZone : TBuildZone; Pos : RVector2) : RIntVector2;
var
  SetOnGridOffset : RVector2;
  NeededSize : RIntVector2;
  Commander : TEntity;
begin
  if Spell.TryGetCommander(Commander) then
  begin
    NeededSize := Commander.Eventbus.Read(eiWelaNeededGridSize, [], Spell.ComponentGroup).AsIntVector2;
    SetOnGridOffset := -(TBuildZone.GRIDNODESIZE * (NeededSize / 2 - 0.5));
    Result := BuildZone.PositionToCoord(Pos + BuildZone.CoordBase * SetOnGridOffset)
  end
  else Result := RIntVector2.ZERO;
end;

procedure TClientInputComponent.ClearAction;
begin
  if assigned(FPreparedSpell) then
      FPreparedSpell.HideVisualization;
  FreeAndNil(FPreparedSpell);
end;

constructor TClientInputComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FDropZoneRenderer := TZoneRenderer.Create(GFXD.MainScene, ZONE_DROP);
  if assigned(HUD) then
      HUD.OnCommanderAbilityClick := OnCommanderAbilityClick;
end;

destructor TClientInputComponent.Destroy;
begin
  FDropZoneRenderer.Free;
  inherited;
end;

procedure TClientInputComponent.UpdateCursorPos(Position : RIntVector2);
begin
  FLastCursorPos := Position;
  FClickVector := GFXD.MainScene.Camera.Clickvector(Position);
  FWorldMousePosition := RPlane.XZ.IntersectRay(FClickVector).XZ;
  if assigned(HUD) and HUD.IsSandboxControlVisible then
  begin
    HUD.MousePosition := FWorldMousePosition;
    HUD.MouseScreenPosition := Position;
  end;
end;

function TClientInputComponent.GetUnitsAtCursor : TList<RTuple<single, TEntity>>;
begin
  Result := GlobalEventbus.Read(eiGetUnitsAtCursor, [RParam.From<RRay>(FClickVector)]).AsType<TList<RTuple<single, TEntity>>>;
end;

function TClientInputComponent.IsActionPrepared : boolean;
begin
  Result := assigned(FPreparedSpell);
end;

function TClientInputComponent.OnCameraMove(Pos : RParam) : boolean;
begin
  Result := True;
  UpdateCursorPos(FLastCursorPos);
end;

function TClientInputComponent.OnChangeCommander(Index : RParam) : boolean;
begin
  Result := True;
  ClearAction;
end;

procedure TClientInputComponent.OnCommanderAbilityClick(CommanderSpellData : TCommanderSpellData; MouseEvent : EnumGUIEvent);
begin
  if (MouseEvent in [geClick, geMouseDown]) then
  begin
    // for a normal click simply prepare ability
    if (MouseEvent = geClick) or
    // for building of drag & drop prepare ability on mouse down for drag and drop
      ((MouseEvent = geMouseDown) and
      Settings.GetBooleanOption(coGameplayDragWavetemplates)) then
    begin
      FSpellPreparedOnMouseDown := False;
      if (MouseEvent = geMouseDown) and not Settings.GetBooleanOption(coGameplayDragWavetemplates) then
          FSpellPreparedOnMouseDown := True;
      PrepareAction(CommanderSpellData);
    end;
  end;
end;

function TClientInputComponent.OnIdle : boolean;
var
  UnitAtCursor : TEntity;
  ShowedZone : EnumDynamicZone;
begin
  Result := True;
  if assigned(ClientGame) then ClientGame.BuildgridManager.ResetColors;

  if not GUI.IsMouseOverGUI then
  begin
    if (not WaitingForSpellTargets and TryGetUnitAtCursor(UnitAtCursor)) or
      (WaitingForSpellTargets and TryGetTargetableUnitAtCursor(FPreparedSpell, UnitAtCursor)) then
        UnitAtCursor.Eventbus.Trigger(eiDrawOutline, [RColor.CTRANSPARENTBLACK, False]);
  end;
  if WaitingForSpellTargets and FPreparedSpell.IsSpawner then
  begin
    if assigned(ClientGame) then ClientGame.BuildgridManager.ShowOccupation(FWorldMousePosition, ClientGame.CommanderManager.ActiveCommanderTeamID);
  end;
  // have to be after Occupationrendering from buildzones, otherwise highlighting becomes hidden
  UpdateTargetDisplay;
  // DropZone render
  FDropZoneRenderer.Visible := WaitingForSpellTargets and (FPreparedSpell.IsDrop or (FPreparedSpell.IsSpell and FPreparedSpell.IsEpic));

  if FDropZoneRenderer.Visible then
  begin
    FDropZoneRenderer.DropZoneMode := Settings.GetEnumOption<EnumDropZoneMode>(coGameplayDropZoneMode);
    if assigned(ClientGame) then
        ClientGame.BuildgridManager.ShowInvalid();
    if FPreparedSpell.IsEpic then
        ShowedZone := dzNexus
    else
        ShowedZone := dzDrop;
    FDropZoneRenderer.DynamicZones := GlobalEventbus.Read(eiDrawSpawnZone, [RParam.From<EnumDynamicZone>(ShowedZone)]).AsType<TList<RCircle>>;
  end;
end;

function TClientInputComponent.OnKeybindingEvent() : boolean;
var
  Index : integer;
  Keybinding : EnumKeybinding;
  SelectedEntity : TEntity;
begin
  Result := True;
  if not assigned(ClientGame) or not ClientGame.IsRunning then exit;

  // Buildhotkeys --------------------------------------------------
  for Keybinding := kbDeckslot01 to kbDeckslot12 do
    if KeybindingManager.KeyUp(Keybinding) then
    begin
      index := ord(Keybinding) - ord(kbDeckslot01);
      if index < HUD.DeckSlotsStage1.Count then
          HUD.ClickDeckslot(HUD.DeckSlotsStage1[index])
      else
      begin
        index := index - HUD.DeckSlotsStage1.Count;
        if index < HUD.DeckSlotsStage2.Count then
            HUD.ClickDeckslot(HUD.DeckSlotsStage2[index])
        else
        begin
          index := index - HUD.DeckSlotsStage2.Count;
          if index < HUD.DeckSlotsStage3.Count then
              HUD.ClickDeckslot(HUD.DeckSlotsStage3[index])
          else
          begin
            index := index - HUD.DeckSlotsStage3.Count;
            if index < HUD.DeckSlotsSpawner.Count then
                HUD.ClickDeckslot(HUD.DeckSlotsSpawner[index])
          end;
        end;
      end;
    end;
  // pings
  if KeybindingManager.KeyUp(kbPingGeneric) then
      HUD.ClickCommanderAbility('ping_generic');
  if KeybindingManager.KeyUp(kbPingAttack) then
      HUD.ClickCommanderAbility('ping_attack');
  if KeybindingManager.KeyUp(kbPingDefend) then
      HUD.ClickCommanderAbility('ping_defense');
  // change active commander --------------------------------------------------
  for Keybinding := kbChangeCommander01 to kbChangeCommander12 do
    if KeybindingManager.KeyUp(Keybinding) then
    begin
      index := ord(Keybinding) - ord(kbChangeCommander01);
      if HUD.CommanderActiveIndex <> index then
          HUD.CommanderChange(index);
    end;
  // card --------------------------------------------------
  if KeybindingManager.KeyDown(kbSpellCast) or KeybindingManager.KeyUp(kbSpellCastRepeat) then
  begin
    if WaitingForSpellTargets and FPreparedSpell.IsReady then
    begin
      // lock targeted entity in mouse down
      if FPreparedSpell.NextTargetType = ctEntity then
          SetNextTarget(FPreparedSpell);
    end;
  end;
  if KeybindingManager.KeyUp(kbMainCancel) then
  begin
    // if spell is prepared, cancel it
    if IsActionPrepared then
    begin
      ClearAction;
      if HUD.IsTutorial then
          HUD.SendGameevent(GAME_EVENT_CARD_DESELECTED);
    end
    else if HUD.IsSettingsOpen then HUD.ShouldCloseSettings := True
    else HUD.IsMenuOpen := not HUD.IsMenuOpen;
  end;
  if KeybindingManager.KeyUp(kbSecondaryAction) then
  begin
    if IsActionPrepared then
    begin
      ClearAction;
      if HUD.IsTutorial then
          HUD.SendGameevent(GAME_EVENT_CARD_DESELECTED);
    end;
  end;
  // Jump to nexus of commander --------------------------------------------------
  if KeybindingManager.KeyUp(kbNexusJump) then
      HUD.SpawnerJump;

  // Debug show hit boxes --------------------------------------------------
  if KeybindingManager.KeyUp(kbHitboxToggleVisibility) then
      ShowHitBoxes := not ShowHitBoxes;
  // Debug next game tick --------------------------------------------------
  if KeybindingManager.KeyUp(kbForceGameTick) then
  begin
    HUD.CallClientCommand(ccForceGameTick);
    if Game.InGameStatus = gsLoading then GlobalEventbus.Trigger(eiGameCommencing, []);
  end;

  if not(itMouse in GUIInputUsed) then
  begin
    if KeybindingManager.KeyUp(kbSpellCast) or KeybindingManager.KeyUp(kbSpellCastRepeat) or KeybindingManager.KeyUp(kbUnitSelect) then
    begin
      if WaitingForSpellTargets and (KeybindingManager.KeyUp(kbSpellCast) or KeybindingManager.KeyUp(kbSpellCastRepeat)) then
      begin
        if not FSpellPreparedOnMouseDown then
        begin
          if FPreparedSpell.IsReady then
          begin
            // set target if needed
            if not FPreparedSpell.AllTargetsSet then
                SetNextTarget(FPreparedSpell);
            // Execute Spell if ready afterwards of selection
            if FPreparedSpell.AllTargetsSet then
            begin
              if (not FPreparedSpell.AnySetTargetIsInvalid or Game.IsSandbox) then
              begin
                FPreparedSpell.Execute;
                // don't deselect if option is set or shift is hold
                if HUD.PreventConsecutivePlaying or
                  not(KeybindingManager.KeyUp(kbSpellCastRepeat) or Settings.GetBooleanOption(coGameplayEndlessBuild)) then
                    ClearAction
                else
                    FPreparedSpell.Unset;
              end
              else
              begin
                SoundManager.PlayCardError;
                FPreparedSpell.Unset;
              end;
            end;
          end
          else SoundManager.PlayCardError;
        end
        else FSpellPreparedOnMouseDown := False;
      end
      else
        if KeybindingManager.KeyUp(kbUnitSelect) then
      begin
        if TryGetUnitAtCursor(SelectedEntity) then
        begin
          GlobalEventbus.Trigger(eiSelectEntity, [SelectedEntity]);
          TSelectedEntityComponent.Create(SelectedEntity);
        end
        else GlobalEventbus.Trigger(eiHideToolTip, []);
      end;
    end;
  end;
end;

function TClientInputComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  ClearAction;
end;

function TClientInputComponent.OnMouseMoveEvent(Position, Difference : RParam) : boolean;
begin
  Result := True;
  UpdateCursorPos(Position.AsIntVector2);
end;

procedure TClientInputComponent.PrepareAction(CustomData : TCommanderSpellData);
var
  ExecutingEntity : TEntity;
begin
  if not assigned(CustomData) then exit;
  ExecutingEntity := Game.EntityManager.GetEntityByID(CustomData.EntityID);
  if (ExecutingEntity <> nil) then
  begin
    ClearAction;
    FPreparedSpell := CustomData.Copy;
    if HUD.IsTutorial then
    begin
      if FPreparedSpell.IsSpawner then
          HUD.SendGameevent(GAME_EVENT_SPAWNER_SELECTED)
      else if FPreparedSpell.IsDrop then
          HUD.SendGameevent(GAME_EVENT_DROP_SELECTED)
      else
          HUD.SendGameevent(GAME_EVENT_SPELL_SELECTED)
    end;
    if FPreparedSpell.AllTargetsSet then
    begin
      // Target of spell is determined => execute
      FPreparedSpell.Execute;
      ClearAction;
    end;
  end;
end;

procedure TClientInputComponent.SetNextTarget(Spell : TCommanderSpellData);
var
  UnitAtCursor : TEntity;
  TargetBuildZone : TBuildZone;
  ClampedWorldMousePosition : RVector2;
begin
  case Spell.NextTargetType of
    ctCoordinate :
      begin
        ClampedWorldMousePosition := FWorldMousePosition;
        if (Spell.Range > 0) and (Spell.TargetCount = 2) and Spell.Targets[0].IsSet then
        begin
          ClampedWorldMousePosition := ClampedWorldMousePosition.ClampDistance(Spell.Targets[0].Coordinate, Spell.Range - 0.01);
        end;
        Spell.SetCoordinateTarget(ClampedWorldMousePosition);
      end;
    ctEntity :
      begin
        if TryGetTargetableUnitAtCursor(Spell, UnitAtCursor) then
            Spell.SetEntityTarget(UnitAtCursor);
      end;
    ctBuildZone :
      begin
        TargetBuildZone := Game.Map.BuildZones.GetBuildZoneByPosition(FWorldMousePosition);
        if assigned(TargetBuildZone) then
            Spell.SetBuildgridTarget(TargetBuildZone.ID, ApplyGridOffset(Spell, TargetBuildZone, FWorldMousePosition));
      end;
  else
    assert(False, 'Spell should already have been executed!');
  end;
end;

function TClientInputComponent.TryGetTargetableUnitAtCursor(Spell : TCommanderSpellData; out UnitAtCursor : TEntity) : boolean;
var
  UnitsAtCursor : TList<RTuple<single, TEntity>>;
  i : integer;
begin
  Result := False;
  UnitsAtCursor := GetUnitsAtCursor;
  if assigned(UnitsAtCursor) then
    for i := 0 to UnitsAtCursor.Count - 1 do
      if Spell.WouldEntityBeValidTarget(UnitsAtCursor[i].b) then
      begin
        Result := True;
        UnitAtCursor := UnitsAtCursor[i].b;
        break;
      end;
  UnitsAtCursor.Free;
end;

function TClientInputComponent.TryGetUnitAtCursor(out UnitAtCursor : TEntity) : boolean;
var
  UnitsAtCursor : TList<RTuple<single, TEntity>>;
begin
  UnitsAtCursor := GetUnitsAtCursor();
  Result := assigned(UnitsAtCursor) and (UnitsAtCursor.Count > 0);
  if Result then
      UnitAtCursor := UnitsAtCursor.First.b;
  UnitsAtCursor.Free;
end;

procedure TClientInputComponent.UpdateTargetDisplay;
var
  TempSpell : TCommanderSpellData;
  TargetBuildZone : TBuildZone;
  UnitAtCursor : TEntity;
begin
  if WaitingForSpellTargets then
  begin
    if FPreparedSpell.AnySetTargetIsInvalid then
    begin
      ClearAction;
      exit;
    end;

    if FPreparedSpell.NextTargetType in [ctCoordinate, ctEntity, ctBuildZone] then
    begin
      // hacking the current mousetarget into the targets
      TempSpell := FPreparedSpell.Copy;
      if TempSpell.NextTargetType = ctBuildZone then
      begin
        TargetBuildZone := Game.Map.BuildZones.GetBuildZoneByPosition(FWorldMousePosition);
        if assigned(TargetBuildZone) then
            TempSpell.SetBuildgridTarget(TargetBuildZone.ID, ApplyGridOffset(TempSpell, TargetBuildZone, FWorldMousePosition))
        else TempSpell.ApplyToNextTarget(
            procedure(Target : PCommanderAbilityTarget)
            begin
              Target^ := RCommanderAbilityTarget.Create(FWorldMousePosition);
            end)
      end
      else if TempSpell.NextTargetType = ctEntity then
      begin
        if not TryGetTargetableUnitAtCursor(TempSpell, UnitAtCursor) or TempSpell.HasEntityTarget(UnitAtCursor) then
        begin
          TempSpell.ApplyToNextTarget(
            procedure(Target : PCommanderAbilityTarget)
            begin
              Target^ := RCommanderAbilityTarget.Create(FWorldMousePosition);
            end)
        end
        else TempSpell.SetEntityTarget(UnitAtCursor);
      end
      else SetNextTarget(TempSpell);
      TempSpell.Visualize;
      TempSpell.Free;
    end
    else FPreparedSpell.Visualize;
  end;
end;

function TClientInputComponent.WaitingForSpellTargets : boolean;
begin
  Result := assigned(FPreparedSpell);
end;

{ TClientGUIComponent }

constructor TClientGUIComponent.Create(Owner : TEntity);
begin
  inherited;
  FFirstGameTick := True;
  FHealthbars := TGUIComponent.Create(GUI, TGUIStyleSheet.CreateFromText('position:0 0;size:100% 100%;Passthroughevents:true;Zoffset : -10000;'), HEALTHBARWRAPPER, GUI.DynamicDOMRoot);
end;

destructor TClientGUIComponent.Destroy;
begin
  FHealthbars.Free;
  inherited;
end;

function TClientGUIComponent.OnAddCommander(Entity : RParam) : boolean;
begin
  Result := True;
  HUD.CommanderCount := ClientGame.CommanderManager.Count;
  HUD.CommanderActiveIndex := ClientGame.CommanderManager.ActiveCommanderIndex;
end;

function TClientGUIComponent.OnChangeCommander(Index : RParam) : boolean;
var
  ActiveCommander, oldCommander : TEntity;
begin
  Result := True;
  oldCommander := ClientGame.CommanderManager.ActiveCommander;
  ActiveCommander := ClientGame.CommanderManager.GetCommanderByIndex(index.AsInteger);
  if not assigned(ActiveCommander) then exit(True);
  if assigned(oldCommander) then oldCommander.Eventbus.Trigger(eiDeregisterInGui, []);
  if assigned(ActiveCommander) then ActiveCommander.Eventbus.Trigger(eiRegisterInGui, []);
end;

function TClientGUIComponent.OnClientInit : boolean;
begin
  Result := True;
  HUD.CommanderCount := ClientGame.CommanderManager.Count;
  HUD.CommanderChange(0);
  if not Game.IsTutorial and not HUD.HasGameStarted then
      HUD.ShowAnnouncement('waiting');
end;

function TClientGUIComponent.OnGameCommencing : boolean;
begin
  Result := True;
  HUD.HasGameStarted := True;
  HUD.HideAnnouncement;
end;

function TClientGUIComponent.OnGameEvent(const EventUID : RParam) : boolean;
begin
  Result := True;
  if (EventUID.AsString = GAME_EVENT_SHOWDOWN) and Game.HasShowdown then
  begin
    HUD.ShowAnnouncementForTime('showdown');
    SoundManager.PlayAnnouncementShowdown;
  end
  else if (EventUID.AsString = GAME_EVENT_TECH_LEVEL_2) and not Game.IsTutorial then
  begin
    HUD.ShowAnnouncementForTime('stage_2');
    SoundManager.PlayAnnouncementStage;
  end
  else if (EventUID.AsString = GAME_EVENT_TECH_LEVEL_3) and (Game.League > 2) and not Game.IsTutorial then
  begin
    HUD.ShowAnnouncementForTime('stage_3');
    SoundManager.PlayAnnouncementStage;
  end;
end;

function TClientGUIComponent.OnGameTick : boolean;
begin
  Result := True;
  if FFirstGameTick then
  begin
    HUD.ShowAnnouncementForTime('stage_1');
    SoundManager.PlayAnnouncementStage;
    FFirstGameTick := False;
  end;
end;

function TClientGUIComponent.OnIdle : boolean;
begin
  Result := True;
  UpdateDisplays;
  GUI.FindUnique(HEALTHBARWRAPPER).Visible := ShowHealthbars and not HUD.CaptureMode;
end;

function TClientGUIComponent.OnKeybindingEvent() : boolean;
begin
  Result := True;
  if Result and KeybindingManager.KeyUp(kbHealthbarsToggleVisibility) then
      ShowHealthbars := not ShowHealthbars;
end;

procedure TClientGUIComponent.UpdateDisplays;
const
  TIER_GROUP : SetComponentGroup = [3];
var
  Wrapper, temp : TGUIComponent;
  i, TimeToFirstSpawn, TempI : integer;
  TimeString : string;
  Health, MaxHealth : single;
  TimeToSpawnRound, HealthPercentage : integer;
  Nexus : TEntity;
  Matches : TList<TEntity>;
  TierLocked, TempB : boolean;
begin
  if assigned(HUD) then
  begin
    // Spawntimer
    TimeToFirstSpawn := GlobalEventbus.Read(eiGameTickTimeToFirstTick, []).AsInteger;
    if TimeToFirstSpawn > 0 then
    begin
      TimeToSpawnRound := Max(0, Ceil(TimeToFirstSpawn / 100));
      if TimeToSpawnRound <= 9 then TimeString := IntToStr(Floor(TimeToSpawnRound / 10)) + '.' + IntToStr(TimeToSpawnRound mod 10)
      else TimeString := IntToStr(Ceil(TimeToSpawnRound / 10));
    end
    else
    begin
      TimeToSpawnRound := GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
      TimeString := HString.IntToTime(TimeToSpawnRound);
    end;
    if HUD.SpawnTimer <> TimeString then HUD.SpawnTimer := TimeString;

    // Nexuss Nexi Nexusse Nexane Nexen
    for i := 1 to 2 do
    begin
      // ToDo remove hack for PvE-Maps
      if Game.EntityManager.TryGetNexusByTeamID(i, Nexus) or Game.EntityManager.TryGetNexusByTeamID(PVE_TEAM_ID, Nexus) then
      begin
        Health := Nexus.Eventbus.Read(eiResourceBalance, [ord(reHealth)]).AsSingle;
        MaxHealth := Nexus.Eventbus.Read(eiResourceCap, [ord(reHealth)]).AsSingle;
        // Nexus should never show 0% => ceil, but even the slightest damage should be shown as 99%
        if (Ceil((Health / MaxHealth) * 100) = 100) and (Health <> MaxHealth) then
            HealthPercentage := 99
        else
            HealthPercentage := Ceil((Health / MaxHealth) * 100);
        TempI := GetDisplayedTeam(i);
        if i = 1 then
        begin
          if HUD.LeftTeamID <> TempI then
              HUD.LeftTeamID := TempI;
          if HUD.LeftNexusHealth <> HealthPercentage then
              HUD.LeftNexusHealth := HealthPercentage;
        end
        else
        begin
          if HUD.RightTeamID <> TempI then
              HUD.RightTeamID := TempI;
          if HUD.RightNexusHealth <> HealthPercentage then
              HUD.RightNexusHealth := HealthPercentage;
        end;
      end;
    end;

    if ClientGame.CommanderManager.HasActiveCommander then
    begin
      // Resources
      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 450
      else
          TempI := Trunc(ClientGame.CommanderManager.ActiveCommander.Balance(reGold).AsSingle);
      if HUD.Gold <> TempI then
          HUD.Gold := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 1200
      else
          TempI := Trunc(ClientGame.CommanderManager.ActiveCommander.Cap(reGold).AsSingle);
      if (HUD.GoldCap <> TempI) then
          HUD.GoldCap := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 14
      else
          TempI := round(GlobalEventbus.Read(eiIncome, [ClientGame.CommanderManager.ActiveCommander.ID]).AsType<RIncome>.Gold);
      if HUD.GoldIncome <> TempI then
          HUD.GoldIncome := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 0
      else
          TempI := round(GlobalEventbus.Read(eiIncome, [ClientGame.CommanderManager.ActiveCommander.ID]).AsType<RIncome>.Wood);
      if HUD.WoodIncome <> TempI then
          HUD.WoodIncome := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 1280
      else
          TempI := Trunc(ClientGame.CommanderManager.ActiveCommander.Balance(reWood).AsSingle);
      if HUD.Wood <> TempI then
          HUD.Wood := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 1600
      else
          TempI := Trunc(ClientGame.CommanderManager.ActiveCommander.Balance(reSpentWood).AsSingle);
      if HUD.SpentWood <> TempI then
          HUD.SpentWood := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 2400
      else
          TempI := Trunc(ClientGame.CommanderManager.ActiveCommander.Eventbus.Read(eiResourceCost, [], [3]).AsAResourceCost[0].Amount.AsSingle);
      if HUD.SpentWoodToIncomeUpgrade <> TempI then
          HUD.SpentWoodToIncomeUpgrade := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 3
      else
          TempI := ClientGame.CommanderManager.ActiveCommander.Balance(reIncomeUpgrade).AsInteger;
      if HUD.IncomeUpgrades <> TempI then
          HUD.IncomeUpgrades := TempI;

      if Game.IsSandbox and HUD.CaptureMode and not HUD.KeepResourcesInCaptureMode then
          TempI := 10
      else
          TempI := ClientGame.CommanderManager.ActiveCommander.Cap(reIncomeUpgrade).AsInteger;
      if HUD.MaxIncomeUpgrades <> TempI then
          HUD.MaxIncomeUpgrades := TempI;

      TempI := ClientGame.CommanderManager.ActiveCommander.Balance(reTier).AsInteger;
      if HUD.Tier <> TempI then
          HUD.Tier := TempI;
      case TempI of
        1 :
          begin
            TempI := GlobalEventbus.Read(eiGameEventTimeTo, [GAME_EVENT_TECH_LEVEL_2]).AsInteger;
            if HUD.TimeToNextTier <> TempI then
                HUD.TimeToNextTier := TempI;
          end;
        2 :
          begin
            TempI := GlobalEventbus.Read(eiGameEventTimeTo, [GAME_EVENT_TECH_LEVEL_3]).AsInteger;
            if HUD.TimeToNextTier <> TempI then
                HUD.TimeToNextTier := TempI;
          end
      else
        begin
          if HUD.TimeToNextTier <> -1 then
              HUD.TimeToNextTier := -1;
        end;
      end;

      // deck
      if GUI.FindUnique(HUD_BUILD_BUTTONS_WRAPPER, Wrapper) then
      begin
        if Wrapper.Find(HUD_BUILD_BUTTONS_TECH2, temp) then
        begin
          TierLocked := ClientGame.CommanderManager.ActiveCommander.Balance(reTier).AsInteger < 2;
          temp.BindClass(temp.ChildCount = 2, 'single'); // are there exact one card (ignore timer)
          temp.BindClass(TierLocked, 'disabled');
          temp.Visible := temp.ChildCount > 1; // are there any cards or only the timer
          temp.Find(HUD_BUILD_BUTTONS_TIMER_WRAPPER).Visible := TierLocked;
          if temp.Find(HUD_BUILD_BUTTONS_TIMER_TEXT, temp) then
              temp.Text := HString.IntToTime(GlobalEventbus.Read(eiGameEventTimeTo, [GAME_EVENT_TECH_LEVEL_2]).AsInteger);
        end;
        if Wrapper.Find(HUD_BUILD_BUTTONS_TECH3, temp) then
        begin
          TierLocked := ClientGame.CommanderManager.ActiveCommander.Balance(reTier).AsInteger < 3;
          temp.BindClass(temp.ChildCount = 2, 'single'); // are there exact one card (ignore timer)
          temp.BindClass(TierLocked, 'disabled');
          temp.Visible := temp.ChildCount > 1; // are there any cards or only the timer
          temp.Find(HUD_BUILD_BUTTONS_TIMER_WRAPPER).Visible := TierLocked;
          if temp.Find(HUD_BUILD_BUTTONS_TIMER_TEXT, temp) then
              temp.Text := HString.IntToTime(GlobalEventbus.Read(eiGameEventTimeTo, [GAME_EVENT_TECH_LEVEL_3]).AsInteger);
        end;
        if Wrapper.Find(HUD_BUILD_BUTTONS_SPAWNER, temp) then
        begin
          temp.Visible := temp.ChildCount > 3; // are there any cards or only the deco
        end;
      end;
    end;

    // Technical Infos
    TempB := ClientGame.GameState = gsReconnecting;
    if HUD.IsReconnecting <> TempB then
        HUD.IsReconnecting := TempB;

    TempI := GFXD.FPS();
    if HUD.FPS <> TempI then
        HUD.FPS := TempI;
    TempI := ClientGame.Ping;
    if HUD.Ping <> TempI then
        HUD.Ping := TempI;

    if GUI.FindUnique(TIMEDISPLAY, temp) then
    begin
      DateTimeToString(TimeString, 'hh : nn', Now);
      temp.Text := TimeString;
    end;

    if HUD.IsPvEAttack and Game.EntityManager.TryGetNexusByTeamID(PVE_TEAM_ID, Nexus) then
    begin
      TempI := Nexus.Cap(reWelaCharge).AsInteger - Nexus.Balance(reWelaCharge).AsInteger;
      if TempI = 0 then TempI := -1;
      if HUD.TimeToAttack <> TempI then
          HUD.TimeToAttack := TempI;
      Matches := GlobalEventbus.Read(eiGameEvent, ['GolemTower_Destroyed']).AsType<TList<TEntity>>;
      if assigned(Matches) then
          TempI := Matches.Count
      else
          TempI := 0;
      if HUD.AttackBaseCount <> TempI then
          HUD.AttackBaseCount := TempI;
      Matches.Free;
      TempI := GlobalEventbus.Read(eiGameEventTimeTo, ['pve_attack_boss_wave']).AsInteger;
      if HUD.TimeToNextBossWave <> TempI then
          HUD.TimeToNextBossWave := TempI;
    end;
  end;
end;

{ TClientEntityManagerComponent }

constructor TClientEntityManagerComponent.Create(Owner : TEntity);
begin
  inherited;
  FFinishTimer := TTimer.Create(TIME_TO_FINISH_GAME);
  FEndScreenTimer := TTimer.Create(TIME_OFFSET_ENDSCREEN);
end;

destructor TClientEntityManagerComponent.Destroy;
begin
  FFinishTimer.Free;
  FEndScreenTimer.Free;
  inherited;
end;

function TClientEntityManagerComponent.OnGUIEvent(Event : RParam) : boolean;
var
  SenderInfo : RGUIEvent;
begin
  Result := True;
  SenderInfo := Event.AsType<RGUIEvent>;
  if SenderInfo.Event = geClick then
  begin
    if SenderInfo = HUD_ENDSCREEN_CONTINUE_BUTTON then
        FFinishTimer.Expired := True;
  end;
end;

function TClientEntityManagerComponent.OnIdle : boolean;
begin
  Result := True;
  if (ClientGame.GameState = gsFinishing) and FEndScreenTimer.Expired then
  begin
    if FVictory then HUD.State := hsVictory
    else HUD.State := hsDefeat;
  end;
  if (ClientGame.GameState = gsFinishing) and FFinishTimer.Expired then
  begin
    ClientGame.GameState := gsFinished;
  end;
end;

function TClientEntityManagerComponent.OnLose(TeamID : RParam) : boolean;
var
  Nexus : TEntity;
  PlayerTeamID : integer;
  Target : RVector2;
begin
  Result := True;
  PlayerTeamID := ClientGame.CommanderManager.ActiveCommanderTeamID;
  if PlayerTeamID = TeamID.AsInteger then FVictory := False
  else FVictory := True;
  ClientGame.GameState := gsFinishing;
  if Game.EntityManager.TryGetNexusByTeamID(TeamID.AsInteger, Nexus) or Game.EntityManager.TryGetNexusByTeamID(PlayerTeamID, Nexus) then
  begin
    Target := Nexus.DisplayPosition.XZ;
    if Game.IsSandbox then
        Target := Target + Settings.GetVector2Option(coSandboxFinishCamOffset);
    HUD.CameraMoveTo(Target, 500);
  end;
  HUD.CameraLocked := True;
  HUD.IsHUDVisible := True;
  ShowHealthbars := False;
  HUD.State := hsNone;
  GlobalEventbus.Trigger(eiHideToolTip, []);
  FFinishTimer.Start;
  FEndScreenTimer.Start;
end;

{ TCommanderManagerComponent }

function TCommanderManagerComponent.ActiveCommanderTeamID : integer;
begin
  if HasActiveCommander then
      Result := ActiveCommander.TeamID
  else
      Result := 0;
end;

procedure TCommanderManagerComponent.ChangeCommander(Index : integer);
begin
  if TryGetCommanderByIndex(index, FActiveCommander) then FActiveIndex := index;
end;

procedure TCommanderManagerComponent.ClearCommanders;
begin
  FCommander.Clear;
end;

function TCommanderManagerComponent.Count : integer;
begin
  Result := FCommander.Count;
end;

constructor TCommanderManagerComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FActiveIndex := -1;
  FCommander := TList<TEntity>.Create;
end;

destructor TCommanderManagerComponent.Destroy;
begin
  FCommander.Free;
  inherited;
end;

function TCommanderManagerComponent.EnumerateCommanders : TList<TEntity>;
begin
  Result := FCommander;
end;

function TCommanderManagerComponent.GetCommanderByIndex(Index : integer) : TEntity;
begin
  if not TryGetCommanderByIndex(index, Result) then Result := nil;
end;

function TCommanderManagerComponent.HasActiveCommander : boolean;
begin
  Result := assigned(ActiveCommander);
end;

function TCommanderManagerComponent.OnChangeCommander(Index : RParam) : boolean;
begin
  Result := True;
  ChangeCommander(index.AsInteger);
end;

function TCommanderManagerComponent.OnNewCommander(Commander : RParam) : boolean;
begin
  Result := True;
  RegisterCommander(Commander.AsType<TEntity>);
end;

procedure TCommanderManagerComponent.RegisterCommander(Commander : TEntity);
begin
  FCommander.Add(Commander);
end;

function TCommanderManagerComponent.TryGetCommanderByIndex(Index : integer; out Commander : TEntity) : boolean;
begin
  if (0 <= index) and (index < FCommander.Count) then
  begin
    Commander := FCommander[index];
    Result := True;
  end
  else Result := False;
end;

{ TClientCameraComponent }

procedure TClientCameraComponent.ApplyCamera;
var
  Eye, Target, CameraDirection : RVector3;
  CameraData : RCameraData;
  Rotation, Tilt : single;
begin
  if FreeCamera then exit;
  if HUD.CameraLaneXLimited then
      FCamPos.X := Min(FCamPos.X, HUD.CameraLaneXLimit);
  if HUD.CameraFixedToLane then
      FCamPos.Y := -23;
  Target := FCamPos.X0Y;
  if Vertical then
      CameraDirection := (FZoom * RVector3.UNITY * 10) + (CAMERAOFFSET.Normalize * 0.01)
  else
      CameraDirection := FZoom * CAMERAOFFSET.Normalize * 10;

  // Rotate
  if HUD.CameraRotate then
  begin
    FRotation := FRotation + Settings.GetSingleOption(coSandboxRotationSpeed) / 1000;
  end
  else FRotation := 0;

  Rotation := FRotation;
  if HUD.CameraRotationOffsetUsed then
      Rotation := Rotation + DegToRad(HUD.CameraRotationOffset);
  Tilt := 0;
  if HUD.CameraTiltOffsetUsed then
      Tilt := Tilt + DegToRad(HUD.CameraTiltOffset);

  CameraDirection := CameraDirection.RotateAxis(CameraDirection.Cross(RVector3.UNITY).Normalize, Tilt).RotatePitchYawRoll(0, Rotation, 0);

  Eye := Target + CameraDirection;

  CameraData := GFXD.MainScene.Camera.CameraData;
  CameraData.FieldOfView := Settings.GetSingleOption(coEngineCameraFoV);
  if HUD.CameraFoVOffsetUsed then
      CameraData.FieldOfView := CameraData.FieldOfView + DegToRad(HUD.CameraFoVOffset);
  GFXD.MainScene.Camera.CameraData := CameraData;
  GFXD.MainScene.Camera.PerspectiveCamera(Eye, Target);
  // adjust shadowbias to reduce peter panning at different zoomings, no constants because has been evaluated for a specific min max zoomlevel
  GFXD.MainScene.Shadowmapping.Shadowbias := HMath.LinLerpF(Settings.GetSingleOption(coEngineShadowBiasMin), Settings.GetSingleOption(coEngineShadowBiasMax), (FZoom - MinZoom) / (MaxZoom - MinZoom));
  GFXD.MainScene.Shadowmapping.Slopebias := Settings.GetSingleOption(coEngineShadowSlopeBias);
  if Settings.GetBooleanOption(coDebugHideMapEnvironment) then
  begin
    GFXD.MainScene.Shadowmapping.ClipBelow := Settings.GetSingleOption(coEngineShadowClipBelow);
    GFXD.MainScene.Shadowmapping.ClipAbove := Settings.GetSingleOption(coEngineShadowClipAbove);
    GFXD.MainScene.Shadowmapping.TweakZoom := Settings.GetSingleOption(coEngineShadowTweakZoom);
  end;

  HUD.CameraPosition := FCamPos;
end;

procedure TClientCameraComponent.ApplyOption(ChangedOption : EnumClientOption);
begin
  case ChangedOption of
    coGameplayClipCursor : EnableScrollingBorder := Settings.GetBooleanOption(coGameplayClipCursor);
  end;
end;

procedure TClientCameraComponent.ClampCamera;
var
  CameraZone : TMultipolygon;
begin
  if HUD.CameraLimited and not FreeCamera then
  begin
    if assigned(Map) and Map.Zones.TryGetValue(ZONE_CAMERA, CameraZone) then
        FCamPos := CameraZone.EnsurePointInMultiPoly(FCamPos);
    FZoom := Min(MaxZoom, Max(MinZoom, FZoom));
  end;
end;

constructor TClientCameraComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FMousePos := RIntVector2.Create(SCROLLBORDERWIDTH.Left + 1, SCROLLBORDERWIDTH.Top + 1);
  ResetZoom;
  FTransitionDuration := TTimer.Create;
  ApplyOption(coGameplayClipCursor);
end;

destructor TClientCameraComponent.Destroy;
begin
  FTransitionDuration.Free;
  inherited;
end;

function TClientCameraComponent.MaxZoom : single;
begin
  Result := Settings.GetSingleOption(coGameplayCameraMaxZoom);
end;

function TClientCameraComponent.MinZoom : single;
begin
  Result := Settings.GetSingleOption(coGameplayCameraMinZoom);
end;

procedure TClientCameraComponent.MoveCamera(Translation : RVector2);
begin
  SetCamera(FCamPos + Translation);
end;

function TClientCameraComponent.OnCameraMove(var Pos : RParam) : boolean;
begin
  Result := True;
  FCamPos := Pos.AsVector2;
  ClampCamera;
  ApplyCamera;
  Pos := FCamPos;
end;

function TClientCameraComponent.OnCameraMoveTo(Pos, TransitionDuration : RParam) : boolean;
begin
  Result := True;
  FTransitionTarget := Pos.AsVector2;
  // if duration is zero, just jump immediately to position
  if TransitionDuration.AsInteger <= 0 then
  begin
    SetCamera(FTransitionTarget);
    exit;
  end;
  FTransitionStart := FCamPos;
  FTransitionDuration.Interval := TransitionDuration.AsInteger;
  FTransitionDuration.Start;
  FMoving := False;
  FTransition := True;
end;

function TClientCameraComponent.OnCameraPosition : RParam;
begin
  Result := FCamPos;
end;

function TClientCameraComponent.OnClientOption(ChangedOption : RParam) : boolean;
begin
  Result := True;
  ApplyOption(ChangedOption.AsEnumType<EnumClientOption>);
end;

function TClientCameraComponent.OnClientInit : boolean;
var
  Target : TEntity;
begin
  Result := True;
  if Game.EntityManager.TryGetNexusByTeamID(ClientGame.CommanderManager.ActiveCommanderTeamID, Target) then
  begin
    SetCamera(Target.DisplayPosition.XZ);
  end;
  HUD.CameraLocked := False;
end;

function TClientCameraComponent.OnIdle : boolean;
var
  RealScrollSpeed : single;
  FollowedEntity : TEntity;
begin
  Result := True;
  if not KeybindingManager.KeyIsDown(kbCameraPanning) then
      FMoving := False;
  if FreeCamera and not Locked then
  begin
    RealScrollSpeed := 1.5 / TimeManager.ZDiff;
    if FreeSlow then RealScrollSpeed := RealScrollSpeed * 0.2;

    if KeybindingManager.KeyIsDown(kbCameraLeft) then
        GFXD.MainScene.Camera.Move(GFXD.MainScene.Camera.ScreenLeft * RealScrollSpeed);
    if KeybindingManager.KeyIsDown(kbCameraRight) then
        GFXD.MainScene.Camera.Move(-GFXD.MainScene.Camera.ScreenLeft * RealScrollSpeed);
    if KeybindingManager.KeyIsDown(kbCameraUp) then
        GFXD.MainScene.Camera.Move(GFXD.MainScene.Camera.CameraDirection * RealScrollSpeed);
    if KeybindingManager.KeyIsDown(kbCameraDown) then
        GFXD.MainScene.Camera.Move(-GFXD.MainScene.Camera.CameraDirection * RealScrollSpeed);

    if KeybindingManager.KeyIsDown(kbCameraRise) then
        GFXD.MainScene.Camera.Move(GFXD.MainScene.Camera.Up * RealScrollSpeed);
    if KeybindingManager.KeyIsDown(kbCameraFall) then
        GFXD.MainScene.Camera.Move(-GFXD.MainScene.Camera.Up * RealScrollSpeed);

    FFreeCamera := RRay.Create(GFXD.MainScene.Camera.Position, GFXD.MainScene.Camera.CameraDirection);
  end;

  FLeft := KeybindingManager.KeyIsDown(kbCameraLeft);
  FUp := KeybindingManager.KeyIsDown(kbCameraUp);
  FRight := KeybindingManager.KeyIsDown(kbCameraRight);
  FBottom := KeybindingManager.KeyIsDown(kbCameraDown);
  FLaneLeft := KeybindingManager.KeyIsDown(kbCameraLaneLeft);
  FLaneRight := KeybindingManager.KeyIsDown(kbCameraLaneRight);

  if FTransition then
  begin
    if Game.EntityManager.TryGetEntityByID(HUD.CameraFollowEntity, FollowedEntity) then
        FTransitionTarget := FollowedEntity.Position;
    if FTransitionDuration.Expired then
    begin
      SetCamera(FTransitionTarget);
      FTransition := False;
    end
    else SetCamera(FTransitionStart.Lerp(FTransitionTarget, FTransitionDuration.ZeitDiffProzent));
  end
  else
    if assigned(Game) and Game.EntityManager.TryGetEntityByID(HUD.CameraFollowEntity, FollowedEntity) then
      SetCamera(FollowedEntity.Position);
  if ClientWindowActive and not FTransition and not FMoving and not HUD.CameraLocked then
  begin
    Scroll(
      Settings.GetSingleOption(coGameplayScrollSpeed) / 1000 * TimeManager.ZDiff,
      (EnableScrollingBorder and (FMousePos.X <= SCROLLBORDERWIDTH.Left)) or FLeft,
      (EnableScrollingBorder and (FMousePos.Y <= SCROLLBORDERWIDTH.Top)) or FUp,
      (EnableScrollingBorder and (FMousePos.X >= GFXD.Settings.Resolution.Width - SCROLLBORDERWIDTH.Right)) or FRight,
      (EnableScrollingBorder and (FMousePos.Y >= GFXD.Settings.Resolution.Height - SCROLLBORDERWIDTH.Bottom)) or FBottom,
      FLaneLeft,
      FLaneRight
      );
  end;
  SetCamera(FCamPos);
end;

function TClientCameraComponent.OnMiniMapMoveToEvent(WorldPosition : RParam) : boolean;
begin
  Result := True;
  HUD.CameraMoveTo(WorldPosition.AsVector2, 0);
end;

function TClientCameraComponent.OnMouseMoveEvent(Position, Difference : RParam) : boolean;
const
  FREE_ROTATION_SPEED = 0.003;
var
  TargetCamPosition : RVector3;
  TargetGroundPos : RVector2;
  FinalrotationSpeed : single;
begin
  Result := True;
  if FreeCamera and not Locked then
  begin
    FinalrotationSpeed := FREE_ROTATION_SPEED;
    if FreeSlow then FinalrotationSpeed := FinalrotationSpeed * 0.2;

    GFXD.MainScene.Camera.CameraDirection := GFXD.MainScene.Camera.CameraDirection.RotateAxis(GFXD.MainScene.Camera.ScreenLeft, -Mouse.dY * FinalrotationSpeed);
    GFXD.MainScene.Camera.CameraDirection := GFXD.MainScene.Camera.CameraDirection.RotateAxis(GFXD.MainScene.Camera.ScreenUp, Mouse.dX * FinalrotationSpeed);
  end;
  if FTransition or HUD.CameraLocked then exit;
  FMousePos := Position.AsIntVector2;
  if FMoving then
  begin
    if Keyboard.Alt {$IFNDEF MAPEDITOR} and False {$ENDIF} then
    begin
      FRotation := FRotation - Difference.AsIntVector2.X * CAMERA_ROTATION_SPEED;
    end
    else
    begin
      TargetCamPosition := RPlane.CreateFromNormal(RVector3.UNITY * (FZoom * (CAMERAOFFSET.Normalize.RotatePitchYawRoll(0, FRotation, 0)).Y * 10), RVector3.UNITY).IntersectRay(RRay.Create(FDragPosition.X0Y, GFXD.MainScene.Camera.Clickvector(Position.AsIntVector2).Direction));
      TargetGroundPos := RPlane.CreateFromNormal(RVector3.ZERO, RVector3.UNITY).IntersectRay(RRay.Create(TargetCamPosition, (CAMERAOFFSET.Normalize.RotatePitchYawRoll(0, FRotation, 0)))).XZ;
      SetCamera(TargetGroundPos);
      FHasMoved := True;
      FMovedLength := FMovedLength + Difference.AsIntVector2.length;

      if HUD.CameraLaneXLimited and (TargetGroundPos.X > HUD.CameraLaneXLimit) then
          FDragPosition := MouseWorldPosition;
    end;
  end;
end;

function TClientCameraComponent.MouseWorldPosition : RVector2;
begin
  Result := RPlane.CreateFromNormal(RVector3.ZERO, RVector3.UNITY).IntersectRay(GFXD.MainScene.Camera.Clickvector(Mouse.Position)).XZ;
end;

function TClientCameraComponent.OnKeybindingEvent : boolean;
begin
  Result := True;
  if FTransition or HUD.CameraLocked then exit;
  if KeybindingManager.KeyUp(kbCameraMoveTo) then
      HUD.CameraMoveTo(MouseWorldPosition, 100);

  if (KeybindingManager.KeyDown(kbCameraPanning) or KeybindingManager.KeyUp(kbCameraPanning)) and (not assigned(GUI) or not GUI.IsMouseOverGUI) and (Settings.GetBooleanOption(coGameplayRightClickPanning)) then
  begin
    FDragPosition := MouseWorldPosition;
    FMoving := not KeybindingManager.KeyUp(kbCameraPanning);
    if not FMoving and FHasMoved and (FMovedLength > Settings.GetIntegerOption(coGeneralRightClickEpsilon)) then Result := False;
    FHasMoved := False;
    FMovedLength := 0;
  end;
  if FMoving and KeybindingManager.KeyUp(kbCameraPanning) then FMoving := False;

  if KeybindingManager.KeyUp(kbCameraResetZoom) then ResetZoom;
end;

function TClientCameraComponent.OnMouseWheelEvent(dZ : RParam) : boolean;
begin
  Result := True;
  if {$IFDEF MAPEDITOR} True or {$ENDIF} (assigned(GUI) and not GUI.IsMouseOverGUI) then
  begin
    FZoom := FZoom - dZ.AsInteger * ZOOMSPEED;
    if HUD.CameraLimited then FZoom := Min(MaxZoom, Max(MinZoom, FZoom));
  end;
end;

function TClientCameraComponent.OnClientCommand(ClientCommand, Param1 : RParam) : boolean;
var
  RealCommand : EnumClientCommand;
begin
  Result := False;
  RealCommand := ClientCommand.AsEnumType<EnumClientCommand>;
  case RealCommand of
    ccSaveCameraPosition :
      begin
        Settings.SetVector2Option(coSandboxSavedCameraPosition, FCamPos);
        Settings.SaveSettings;
      end;
    ccReturnToSavedCameraPosition : FCamPos := Settings.GetVector2Option(coSandboxSavedCameraPosition);
  else
    Result := True;
  end;
end;

procedure TClientCameraComponent.ResetPosition;
begin
  FCamPos := RVector2.ZERO;
end;

procedure TClientCameraComponent.ResetZoom;
begin
  FZoom := MaxZoom;
end;

procedure TClientCameraComponent.Scroll(Amount : single; Left, Up, Right, Bottom, LaneLeft, LaneRight : boolean);
var
  ScrollVector : RVector2;
begin
  ScrollVector := RVector2.ZERO;

  if Left then ScrollVector := ScrollVector - CAMERAOFFSET.XZ.Normalize.GetOrthogonal;
  if Up then ScrollVector := ScrollVector - CAMERAOFFSET.XZ.Normalize;
  if Right then ScrollVector := ScrollVector + CAMERAOFFSET.XZ.Normalize.GetOrthogonal;
  if Bottom then ScrollVector := ScrollVector + CAMERAOFFSET.XZ.Normalize;
  if LaneLeft then ScrollVector := ScrollVector - RVector2.UNITX;
  if LaneRight then ScrollVector := ScrollVector + RVector2.UNITX;

  MoveCamera(Amount * ScrollVector.Normalize)
end;

procedure TClientCameraComponent.SetCamera(Position : RVector2);
begin
  GlobalEventbus.Trigger(eiCameraMove, [Position]);
end;

procedure TClientCameraComponent.setFree(const Value : boolean);
var
  temp : RVector3;
begin
  if FFree = Value then exit;
  FFree := Value;
  if FFree then
  begin
    if not FWasFree then
    begin
      RVector3.TryFromString(HFileIO.ReadFromIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraPosition', GFXD.MainScene.Camera.Position), temp);
      FFreeCamera.Origin := temp;
      RVector3.TryFromString(HFileIO.ReadFromIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraDirection', GFXD.MainScene.Camera.CameraDirection), temp);
      FFreeCamera.Direction := temp;
      TryStrToBool(HFileIO.ReadFromIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraLocked', BoolToStr(Locked)), FFreeLocked);
      FWasFree := True;
    end;
    GFXD.MainScene.Camera.Position := FFreeCamera.Origin;
    GFXD.MainScene.Camera.CameraDirection := FFreeCamera.Direction;
  end
  else
  begin
    // save camera to settings
    HFileIO.WriteToIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraPosition', FFreeCamera.Origin);
    HFileIO.WriteToIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraDirection', FFreeCamera.Direction);
  end;
end;

procedure TClientCameraComponent.setLocked(const Value : boolean);
begin
  if FFreeLocked = Value then exit;
  FFreeLocked := Value;
  if FFree then
  begin
    // save camera to settings
    HFileIO.WriteToIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraPosition', FFreeCamera.Origin);
    HFileIO.WriteToIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraDirection', FFreeCamera.Direction);
    HFileIO.WriteToIni(AbsolutePath('Settings.ini'), 'Debug', 'FreeCameraLocked', BoolToStr(Locked));
  end;
end;

{ TCommanderSpellData }

function TCommanderSpellData.Copy : TCommanderSpellData;
begin
  Result := TCommanderSpellData.Create(FGlobalEventbus, EntityID, ComponentGroup, Targets, Range);
  Result.ClosesTooltip := ClosesTooltip;
  Result.IsSpawner := IsSpawner;
  Result.IsDrop := IsDrop;
  Result.IsSpell := IsSpell;
  Result.IsEpic := IsEpic;
  Result.MultiModes := MultiModes;
end;

constructor TCommanderSpellData.Create(GlobalEventbus : TEventbus; EntityID : integer; ComponentGroup : SetComponentGroup; Targets : array of RCommanderAbilityTarget; Range : single);
begin
  self.FGlobalEventbus := GlobalEventbus;
  self.EntityID := EntityID;
  self.ComponentGroup := ComponentGroup;
  self.Targets := ACommanderAbilityTarget(HArray.ConvertDynamicToTArray<RCommanderAbilityTarget>(Targets));
  self.Range := Range;
  FIsInMode := -1;
end;

procedure TCommanderSpellData.Execute;
var
  ExecutingEntity : TEntity;
begin
  if TryGetCommander(ExecutingEntity) then
  begin
    if ClosesTooltip then
        FGlobalEventbus.Trigger(eiHideToolTip, []);
    if IsMultiMode then
    begin
      assert(FIsInMode >= 0);
      ExecutingEntity.Eventbus.Trigger(eiUseAbility, [Targets.ToRParam], ComponentGroup + [MultiModes[FIsInMode]]);
    end
    else ExecutingEntity.Eventbus.Trigger(eiUseAbility, [Targets.ToRParam], ComponentGroup);
    if HUD.IsTutorial then
    begin
      if IsSpawner then
          HUD.SendGameevent(GAME_EVENT_SPAWNER_PLACED)
      else if IsDrop then
          HUD.SendGameevent(GAME_EVENT_DROP_PLACED)
      else
          HUD.SendGameevent(GAME_EVENT_SPELL_PLACED)
    end;
  end;
end;

function TCommanderSpellData.TryGetCommander(out Commander : TEntity) : boolean;
begin
  Result := assigned(Game) and assigned(Game.EntityManager) and Game.EntityManager.TryGetEntityByID(EntityID, Commander);
end;

procedure TCommanderSpellData.Unset;
var
  i : integer;
begin
  FIsInMode := -1;
  for i := 0 to length(Targets) - 1 do
      Targets[i].Unset;
end;

function TCommanderSpellData.HasEntityTarget(Entity : TEntity) : boolean;
var
  i : integer;
begin
  Result := False;
  if not assigned(Entity) then exit;
  for i := 0 to length(Targets) - 1 do
    if Targets[i].IsSet and Targets[i].IsEntityTarget and (Targets[i].EntityID = Entity.ID) then exit(True)
end;

procedure TCommanderSpellData.HideVisualization;
var
  Commander : TEntity;
  i : integer;
begin
  if TryGetCommander(Commander) then
  begin
    if not IsMultiMode then Commander.Eventbus.Trigger(eiSpellVisualizationHide, [], ComponentGroup)
    else
      for i := 0 to length(MultiModes) - 1 do Commander.Eventbus.Trigger(eiSpellVisualizationHide, [], [MultiModes[i]])
  end;
end;

function TCommanderSpellData.IsMultiMode : boolean;
begin
  Result := length(MultiModes) > 0;
end;

function TCommanderSpellData.IsReady : boolean;
var
  ExecutingEntity : TEntity;
begin
  Result := Game.IsSandbox or (TryGetCommander(ExecutingEntity) and ExecutingEntity.Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue);
end;

function TCommanderSpellData.NextTargetType : EnumCommanderAbilityTargetType;
var
  i : integer;
begin
  Result := ctNone;
  for i := 0 to length(Targets) - 1 do
    if not Targets[i].IsSet then
    begin
      Result := Targets[i].TargetType;
      break;
    end;
end;

procedure TCommanderSpellData.ApplyToNextTarget(proc : ProcDoSomethingWithTarget);
var
  i, mode : integer;
  Commander : TEntity;
begin
  for i := 0 to length(Targets) - 1 do
    if not Targets[i].IsSet then
    begin
      proc(@Targets[i]);
      // first target determines mode
      if IsMultiMode and (i = 0) and TryGetCommander(Commander) then
      begin
        for mode := 0 to length(MultiModes) - 1 do
          if Commander.Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Targets[i].ToRTarget(Commander)).ToRParam], [MultiModes[mode]]).AsRTargetValidity.IsValid then
          begin
            FIsInMode := mode;
            break;
          end;
      end;
      break;
    end;
end;

procedure TCommanderSpellData.SetBuildgridTarget(BuildZoneID : integer; Coordinate : RIntVector2);
begin
  ApplyToNextTarget(
    procedure(Target : PCommanderAbilityTarget)
    begin
      if Target.IsBuildTarget then Target^ := RCommanderAbilityTarget.CreateBuildTarget(BuildZoneID, Coordinate);
    end)
end;

procedure TCommanderSpellData.SetCoordinateTarget(Position : RVector2);
begin
  ApplyToNextTarget(
    procedure(Target : PCommanderAbilityTarget)
    begin
      if Target.IsCoordinateTarget then Target^ := RCommanderAbilityTarget.Create(Position);
    end)
end;

procedure TCommanderSpellData.SetEntityTarget(Entity : TEntity);
begin
  if not assigned(Entity) then exit;
  ApplyToNextTarget(
    procedure(Target : PCommanderAbilityTarget)
    begin
      if Target.IsEntityTarget then Target^ := RCommanderAbilityTarget.Create(Entity);
    end)
end;

function TCommanderSpellData.AnySetTargetIsInvalid : boolean;
var
  i : integer;
  Commander : TEntity;
  Validity : RTargetValidity;
begin
  Result := False;
  if TryGetCommander(Commander) then
  begin
    if not IsMultiMode then
        Validity := Commander.Eventbus.Read(eiWelaTargetPossible, [Targets.ToRTargets(Commander).ToRParam], ComponentGroup).AsRTargetValidity
    else if FIsInMode >= 0 then
        Validity := Commander.Eventbus.Read(eiWelaTargetPossible, [Targets.ToRTargets(Commander).ToRParam], [MultiModes[FIsInMode]]).AsRTargetValidity
    else exit(False);
    for i := 0 to length(Targets) - 1 do
      if Targets[i].IsSet and (Validity.IsInitialized and not(i in Validity.SingleValidityMask)) then
          exit(True);
  end
  else Result := True;
end;

function TCommanderSpellData.AllTargetsSet : boolean;
begin
  Result := NextTargetType = ctNone;
end;

function TCommanderSpellData.TargetCount : integer;
begin
  Result := length(Targets);
end;

procedure TCommanderSpellData.Visualize;
var
  Commander : TEntity;
  i : integer;
begin
  if TryGetCommander(Commander) then
  begin
    if not IsMultiMode then Commander.Eventbus.Trigger(eiSpellVisualization, [self], ComponentGroup)
    else
    begin
      for i := 0 to length(MultiModes) - 1 do Commander.Eventbus.Trigger(eiSpellVisualizationHide, [], [MultiModes[i]]);
      if FIsInMode < 0 then Commander.Eventbus.Trigger(eiSpellVisualization, [self], [MultiModes[0]])
      else Commander.Eventbus.Trigger(eiSpellVisualization, [self], [MultiModes[FIsInMode]]);
    end;
  end;
end;

function TCommanderSpellData.WouldEntityBeValidTarget(Entity : TEntity) : boolean;
var
  Commander : TEntity;
  i : integer;
begin
  if (NextTargetType = ctEntity) and TryGetCommander(Commander) then
  begin
    Result := not HasEntityTarget(Entity);
    if Result then
    begin
      if not IsMultiMode then
      begin
        Result := Commander.Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Entity).ToRParam], ComponentGroup).AsRTargetValidity.IsValid
      end
      else
      begin
        if FIsInMode = -1 then
        begin
          // is valid if any mode would say yes
          Result := False;
          for i := 0 to length(MultiModes) - 1 do
              Result := Result or (Commander.Eventbus.Read(eiIsReady, [], [MultiModes[i]]).AsBooleanDefaultTrue and
              Commander.Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Entity).ToRParam], [MultiModes[i]]).AsRTargetValidity.IsValid)
        end
        else
          // mode has been determined before, now saying constraints for following targets
            Result := Commander.Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Entity).ToRParam], [MultiModes[FIsInMode]]).AsRTargetValidity.IsValid
      end;
    end;
  end
  else Result := False;
end;

{ TCommanderComponent }

function TCommanderComponent.OnEnumerateCommanders(PrevValue : RParam) : RParam;
begin
  if PrevValue.IsEmpty then Result := TList<TEntity>.Create
  else Result := PrevValue;
  Result.AsType < TList < TEntity >>.Add(FOwner);
end;

{ TMiniMapComponent }

constructor TMiniMapComponent.Create(Owner : TEntity);
begin
  inherited;
  FMiniMap := TMiniMap.Create();
  FMouseDown := False;
end;

destructor TMiniMapComponent.Destroy;
begin
  FreeAndNil(FMiniMap);
  inherited;
end;

procedure TMiniMapComponent.AddToMinimap(Entity : TEntity; IconPath : string; IconSize : single);
var
  entry : RMiniMapEntry;
begin
  entry := RMiniMapEntry.Create(Entity, IconSize, IconPath);
  FMiniMap.Add(entry);
end;

function TMiniMapComponent.OnIdle : boolean;
begin
  FMiniMap.Idle();
  Result := True;
end;

function TMiniMapComponent.OnKeybindingEvent() : boolean;
var
  worldPos : RVector2;
begin
  Result := True;
  if not HUD.IsHUDVisible or HUD.CameraLocked then
  begin
    FMouseDown := False;
    exit;
  end;
  if KeybindingManager.KeyDown(kbMainAction) and not(itMouse in GUIInputUsed) then
  begin
    if FMiniMap.isWithinGuiBounds(Mouse.Position) then
    begin
      FMouseDown := True;
      worldPos := FMiniMap.MiniMapToWorld(Mouse.Position);
      GlobalEventbus.Trigger(eiMiniMapMoveToEvent, [worldPos]);
      GUIInputUsed := GUIInputUsed + [itMouse];
    end;
  end;
  if KeybindingManager.KeyUp(kbMainAction) then
  begin
    if FMouseDown or FMiniMap.isWithinGuiBounds(Mouse.Position) then
        GUIInputUsed := GUIInputUsed + [itMouse];
    FMouseDown := False;
  end;
end;

function TMiniMapComponent.OnMouseMoveEvent(Position, Difference : RParam) : boolean;
begin
  Result := True;
  if FMouseDown and FMiniMap.isWithinGuiBounds(Mouse.Position) then
  begin
    GlobalEventbus.Trigger(eiMiniMapMoveToEvent, [FMiniMap.MiniMapToWorld(Mouse.Position)]);
    GUIInputUsed := GUIInputUsed + [itMouse];
  end;
end;

procedure TMiniMapComponent.RemoveFromMinimap(Entity : TEntity);
begin
  FMiniMap.Remove(Entity);
end;

{ TClickCollisionComponent }

function TClickCollisionComponent.CurrentCapsule : RCapsule;
var
  Position, Front : RVector3;
  Transform : RMatrix;
begin
  Position := Owner.DisplayPosition;
  Front := Owner.DisplayFront;
  Transform := RMatrix.CreateSaveBase(Front, RVector3.UNITY);
  Result := RCapsule.Create(Position + Transform * FCapsule.Origin, Position + Transform * FCapsule.Endpoint, FCapsule.Radius);
  Result.Radius := Result.Radius + TClickCollisionComponent.CLICK_BIAS;
end;

function TClickCollisionComponent.LowPriority : TClickCollisionComponent;
begin
  Result := self;
  FLowPriority := True;
end;

function TClickCollisionComponent.OnGetUnitsAtCursor(ClickRay, Previous : RParam) : RParam;
var
  Ray : RRay;
  Capsule : RCapsule;
  List : TList<RTuple<single, TEntity>>;
  Hit : RTuple<single, TEntity>;
  i : integer;
begin
  if not Eventbus.Read(eiVisible, []).AsBooleanDefaultTrue then exit(Previous);
  Ray := ClickRay.AsType<RRay>;
  Capsule := CurrentCapsule;
  if Capsule.IntersectCapsuleRay(Ray, nil) then
  begin
    List := Previous.AsType<TList<RTuple<single, TEntity>>>;
    if not assigned(List) then List := TList < RTuple < single, TEntity >>.Create;

    Hit.b := FOwner;
    Hit.a := Capsule.ToLine.DistanceToRay(Ray);
    if FLowPriority then
        Hit.a := 100000;
    for i := 0 to List.Count do
      if i = List.Count then
      begin
        List.Add(Hit);
        break;
      end
      else
        if List[i].a > Hit.a then
      begin
        List.Insert(i, Hit);
        break;
      end;

    Result := List;
    {$IFDEF DEBUG}
    if ShowHitBoxes and (FFrame <> GFXD.FPSCounter.FrameCount) then Linepool.AddCapsule(Capsule, RColor.CGREEN, 8);
    {$ENDIF}
  end
  else
  begin
    Result := Previous;
    {$IFDEF DEBUG}
    if ShowHitBoxes and (FFrame <> GFXD.FPSCounter.FrameCount) then Linepool.AddCapsule(Capsule, RColor.CRED, 8);
    {$ENDIF}
  end;
  {$IFDEF DEBUG}
  FFrame := GFXD.FPSCounter.FrameCount;
  {$ENDIF}
end;

function TClickCollisionComponent.SetCapsule(Origin, Endpoint : RVector3; Radius : single) : TClickCollisionComponent;
begin
  Result := self;
  FCapsule := RCapsule.Create(Origin, Endpoint, Radius);
end;

{ TLogicToWorldComponent }

function TLogicToWorldComponent.OnAfterCreate : boolean;
begin
  Result := True;
  OnIdle();
end;

function TLogicToWorldComponent.OnDisplayFront() : RParam;
begin
  if Owner.Front.IsZeroVector then Result := RVector3.UNITZ
  else Result := Owner.Front.X0Y;
end;

function TLogicToWorldComponent.OnDisplayPosition() : RParam;
begin
  Result := Owner.Position.X0Y;
end;

function TLogicToWorldComponent.OnDisplayUp() : RParam;
begin
  Result := RVector3.UNITY;
end;

function TLogicToWorldComponent.OnIdle() : boolean;
begin
  Result := True;
  Owner.DisplayPosition := Eventbus.Read(eiDisplayPosition, []).AsVector3;
  Owner.DisplayFront := Eventbus.Read(eiDisplayFront, []).AsVector3;
  Owner.DisplayUp := Eventbus.Read(eiDisplayUp, []).AsVector3;
end;

{ TGameIntensityComponent }

function TGameIntensityComponent.OnShortestBattleFrontDistance(Previous : RParam) : RParam;
var
  dist : single;
  Pos, npos : RVector2;
  Nexus : TEntity;
begin
  Pos := Owner.Position;
  if Game.EntityManager.TryGetNexusNextEnemy(Pos, Owner.TeamID, Nexus) then npos := Nexus.Position
  else exit(Previous);
  dist := abs(Pos.X - npos.X);
  if Previous.IsEmpty then Result := dist
  else Result := Min(dist, Previous.AsSingle);
end;

{ TClientSettingsComponent }

constructor TClientSettingsComponent.Create(Entity : TEntity);
begin
  inherited;
  Init;
end;

function TClientSettingsComponent.OnClientOption(Option : RParam) : boolean;
begin
  Result := True;
  HandleOption(Option.AsType<EnumClientOption>);
end;

procedure TClientSettingsComponent.HandleOption(Option : EnumClientOption);
begin
  case Option of
    coGraphicsShadows :
      if Settings.GetBooleanOption(coGraphicsShadows) then GFXD.MainScene.ShadowTechnique := stShadowMapping
      else GFXD.MainScene.ShadowTechnique := stNone;
    coGraphicsShadowResolution : GFXD.MainScene.Shadowmapping.Resolution := Settings.GetIntegerOption(coGraphicsShadowResolution);
    coGraphicsDeferredShading : GFXD.Settings.DeferredShading := Settings.GetBooleanOption(coGraphicsDeferredShading);
    coGraphicsVSync :
      begin
        if GFXD.Settings.Vsync <> Settings.GetBooleanOption(coGraphicsVSync) then
        begin
          GFXD.Settings.Vsync := Settings.GetBooleanOption(coGraphicsVSync);
          // trigger swap chain update
          GFXD.ChangeResolution(GFXD.Settings.Resolution.Size);
        end;
      end;
    coGraphicsGUIBlurBackgrounds : GUI.EnableBlurBackgrounds := Settings.GetBooleanOption(coGraphicsGUIBlurBackgrounds);
    coGraphicsPostEffectSSAO : PostEffects.GetPostEffect('SSAO').Enabled := Settings.GetBooleanOption(coGraphicsPostEffectSSAO);
    coGraphicsPostEffectToon : PostEffects.GetPostEffect('Toon').Enabled := Settings.GetBooleanOption(coGraphicsPostEffectToon);
    coGraphicsPostEffectGlow : PostEffects.GetPostEffect('Glow').Enabled := Settings.GetBooleanOption(coGraphicsPostEffectGlow);
    coGraphicsPostEffectFXAA : PostEffects.GetPostEffect('FXAA').Enabled := Settings.GetBooleanOption(coGraphicsPostEffectFXAA);
    coGraphicsPostEffectUnsharpMasking : PostEffects.GetPostEffect('UnsharpMasking').Enabled := Settings.GetBooleanOption(coGraphicsPostEffectUnsharpMasking);
    coGraphicsPostEffectDistortion : PostEffects.GetPostEffect('Distortion').Enabled := Settings.GetBooleanOption(coGraphicsPostEffectDistortion);

    coGameplayClickPrecision : TClickCollisionComponent.CLICK_BIAS := Settings.GetSingleOption(coGameplayClickPrecision);
  end;
end;

procedure TClientSettingsComponent.Init;
var
  Option : EnumClientOption;
begin
  inherited;
  for Option := low(EnumClientOption) to high(EnumClientOption) do HandleOption(Option);
end;

{ TBuildGridManagerComponent }

constructor TBuildGridManagerComponent.Create(Owner : TEntity);
var
  BuildZone : TBuildZone;
begin
  inherited;
  FBuildGridVisualizers := TObjectDictionary<integer, TBuildGridVisualizer>.Create([doOwnsValues]);
  for BuildZone in Map.BuildZones.BuildZones.Values do
      FBuildGridVisualizers.Add(BuildZone.ID, TBuildGridVisualizer.Create(BuildZone));
end;

destructor TBuildGridManagerComponent.Destroy;
begin
  FBuildGridVisualizers.Free;
  inherited;
end;

function TBuildGridManagerComponent.OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
var
  Visualizer : TBuildGridVisualizer;
begin
  Result := True;
  if FBuildGridVisualizers.TryGetValue(GridID.AsInteger, Visualizer) then
      Visualizer.Spawn(Coordinate.AsIntVector2);
end;

function TBuildGridManagerComponent.ResetColors : TBuildGridManagerComponent;
var
  Visualizer : TBuildGridVisualizer;
begin
  Result := self;
  for Visualizer in FBuildGridVisualizers.Values do
      Visualizer.ResetColors;
end;

function TBuildGridManagerComponent.ShowInvalid : TBuildGridManagerComponent;
var
  Visualizer : TBuildGridVisualizer;
begin
  Result := self;
  for Visualizer in FBuildGridVisualizers.Values do
      Visualizer.ShowInvalid;
end;

function TBuildGridManagerComponent.ShowOccupation(const ReferencePosition : RVector2; TeamID : integer) : TBuildGridManagerComponent;
var
  Visualizer : TBuildGridVisualizer;
begin
  Result := self;
  for Visualizer in FBuildGridVisualizers.Values do
      Visualizer.ShowOccupation(ReferencePosition, TeamID);
end;

{ TBuildGridManagerComponent.TTile }

procedure TBuildGridManagerComponent.TTile.Activate;
begin
  FIsActive := False;
  FGlowTransition.SetValue(0.0);
  FGlowTransition.TimingFunction := RCubicBezier.Create(0, -2.38, 0.58, 1);
  FGlowTransition.Duration := GLOW_TIME_OUT;
end;

constructor TBuildGridManagerComponent.TTile.Create(BuildZone : TBuildZone; const Coordinate : RIntVector2);
const
  GRIDNODE_SCALE = (TBuildZone.GRIDNODESIZE / 1.84) + 0.08;
var
  GlowShader : RMeshShader;
begin
  FIsActive := True;
  FBuildZone := BuildZone;
  FCoordinate := Coordinate;

  FMesh := TMesh.CreateFromFile(GFXD.MainScene, Format(BUILDGRID_MESH_PATH, [random(BUILDGRID_MESH_PATH_COUNT) + 1]));
  FMesh.Position := BuildZone.GetCenterOfField(Coordinate).X0Y(-0.04);
  FMesh.Scale := GRIDNODE_SCALE;
  FMesh.Rotation := RVector3.Create(0, PI / 2 * random(4), 0);

  GlowShader := RMeshShader.Create(
    PATH_GRAPHICS_SHADER + 'GlowOvershoot.fx',
    SetUpShader);
  FMesh.CustomShader.Add(GlowShader);
  FGlowTransition := TGUITransitionValueSingle.Create;
  FGlowTransition.TimingFunction := RCubicBezier.EASEOUT;
  FGlowTransition.SetValue(GLOW_INTENSITY);
end;

destructor TBuildGridManagerComponent.TTile.Destroy;
begin
  FMesh.Free;
  FGlowTransition.Free;
  inherited;
end;

procedure TBuildGridManagerComponent.TTile.Reset;
begin
  FIsActive := True;
  FGlowTransition.SetValue(GLOW_INTENSITY);
  FGlowTransition.TimingFunction := RCubicBezier.EASEOUT;
  FGlowTransition.Duration := GLOW_TIME_IN;
end;

procedure TBuildGridManagerComponent.TTile.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
var
  ColorIntensity : single;
begin
  ColorIntensity := FGlowTransition.CurrentValue;
  if Stage = rsGlow then
      CurrentShader.SetShaderConstant<single>('go_is_glow_stage', 1)
  else
  begin
    CurrentShader.SetShaderConstant<single>('go_is_glow_stage', 0);
    if not Settings.GetBooleanOption(coGraphicsPostEffectGlow) then
        ColorIntensity := ColorIntensity / GLOW_INTENSITY * GLOW_COLOR_INTENSITY;
  end;
  CurrentShader.SetShaderConstant<single>('go_overshoot', ColorIntensity);
  CurrentShader.SetShaderConstant<RVector3>('go_color', RColor.Create($00FFFF).RGB);
end;

{ TUnitDecayManagerComponent }

procedure TUnitDecayManagerComponent.AddMesh(Mesh : TMesh; ColorIdentity : EnumEntityColor);
var
  DecayingUnit : TDecayingUnit;
  GlowColor : RColor;
begin
  DecayingUnit := TDecayingUnit.Create;
  DecayingUnit.Mesh := Mesh;
  Mesh.FurIterations := 0;
  GlowColor := GLOW_COLOR_MAP[ColorIdentity];
  Mesh.CustomShader.Clear;
  case ColorIdentity of
    ecBlack :
      begin
        Mesh.CustomShader.Add(RMeshShader.Create(PATH_GRAPHICS_SHADER + 'DeathShader_Black.fx',
          procedure(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer)
          begin
            CurrentShader.SetShaderConstant<single>('dsb_progress', DecayingUnit.DecayTimer.ZeitDiffProzent(True));
          end));
      end;
  else
    begin
      Mesh.CustomShader.Add(RMeshShader.Create(PATH_GRAPHICS_SHADER + 'DeathShader.fx',
        procedure(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer)
        begin
          CurrentShader.SetShaderConstant<single>('explosion_progress', DecayingUnit.DecayTimer.ZeitDiffProzent(True));
          CurrentShader.SetShaderConstant<RVector3>('explosion_color', GlowColor.RGB);
        end));
    end;
  end;

  FDecayingUnits.Add(DecayingUnit)
end;

constructor TUnitDecayManagerComponent.Create(Owner : TEntity);
begin
  inherited;
  FDecayingUnits := TObjectList<TDecayingUnit>.Create;
end;

destructor TUnitDecayManagerComponent.Destroy;
begin
  FDecayingUnits.Free;
  inherited;
end;

function TUnitDecayManagerComponent.OnIdle : boolean;
var
  i : integer;
begin
  Result := True;
  for i := FDecayingUnits.Count - 1 downto 0 do
    if FDecayingUnits[i].DecayTimer.Expired then FDecayingUnits.Delete(i);
end;

{ TUnitDecayManagerComponent.TDecayingUnit }

constructor TUnitDecayManagerComponent.TDecayingUnit.Create;
begin
  DecayTimer := TTimer.CreateAndStart(500);
end;

destructor TUnitDecayManagerComponent.TDecayingUnit.Destroy;
begin
  DecayTimer.Free;
  Mesh.Free;
  inherited;
end;

{ TVertexTraceManagerComponent }

procedure TVertexTraceManagerComponent.AddTrace(Trace : TVertexTrace; RollUpSpeed : single);
begin
  FTraces.Add(TVertexTraceHandle.Create(Trace, RollUpSpeed));
  Trace.StopTracking;
end;

constructor TVertexTraceManagerComponent.Create(Owner : TEntity);
begin
  inherited;
  FTraces := TObjectList<TVertexTraceHandle>.Create;
end;

destructor TVertexTraceManagerComponent.Destroy;
begin
  FTraces.Free;
  inherited;
end;

function TVertexTraceManagerComponent.OnIdle : boolean;
var
  i : integer;
begin
  Result := True;
  for i := FTraces.Count - 1 downto 0 do
  begin
    FTraces[i].Trace.RollUp(FTraces[i].RollUpSpeed * TimeManager.ZDiff);
    if FTraces[i].Trace.IsEmpty then FTraces.Delete(i);
  end;
  for i := 0 to FTraces.Count - 1 do FTraces[i].Trace.AddRenderJob;
end;

{ TVertexTraceManagerComponent.TVertexTraceHandle }

constructor TVertexTraceManagerComponent.TVertexTraceHandle.Create(Trace : TVertexTrace; RollUpSpeed : single);
begin
  self.Trace := Trace;
  self.RollUpSpeed := RollUpSpeed;
end;

destructor TVertexTraceManagerComponent.TVertexTraceHandle.Destroy;
begin
  Trace.Free;
  inherited;
end;

{ TClientNetworkComponent.TReconnectThread }

constructor TClientNetworkComponent.TReconnectThread.Create(const ServerAddress : RInetAddress; LastReceivedIndex : integer; const Token : string);
begin
  inherited Create(False);
  FServerAddress := ServerAddress;
  FNewSocket := TSocketPromise.Create();
  FNewSocket.SourceThread := self;
  FreeOnTerminate := True;
  FReconnectTimer := TTimer.Create(MAXTIME_FOR_TRYING);
  FAttemptTime := TTimer.Create(TIME_BETWEEN_ATTEMPTS);
  FLastReceivedIndex := LastReceivedIndex;
  FToken := Token;
end;

destructor TClientNetworkComponent.TReconnectThread.Destroy;
begin
  FReconnectTimer.Free;
  FAttemptTime.Free;
  FNewSocket.Free;
  inherited;
end;

procedure TClientNetworkComponent.TReconnectThread.Execute;
var
  SendData : TCommandSequence;
  Socket : TTCPClientSocketDeluxe;
  ErrorMessage : string;
begin
  ErrorMessage := 'Not set';
  FReconnectTimer.Start;
  while not FReconnectTimer.Expired and not Terminated do
  begin
    FAttemptTime.Start;
    try
      Socket := TTCPClientSocketDeluxe.Create(FServerAddress);
      SendData := TCommandSequence.Create(NET_RECONNECT);
      SendData.AddData(FToken);
      SendData.AddData<integer>(FLastReceivedIndex);
      Socket.SendData(SendData);
      SendData.Free;
      NewSocket.SetPromiseSuccessful(Socket);
      // reconnect succesful
      exit;
    except
      on e : ENetworkException do
      begin
        ErrorMessage := e.ToString;
        sleep(round(FAttemptTime.TimeToExpired));
      end;
    end;
  end;
  // reconnect after serveral attempts failed
  NewSocket.SetPromiseError(ErrorMessage)
end;

{ TTutorialDirectorComponent }

function TTutorialDirectorComponent.AddAction(const Action : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  assert(FActionQueue.Count > 0);
  Action.FOwner := self;
  FActionQueue.Last.Actions.Add(Action);
end;

function TTutorialDirectorComponent.AddActions(const A1 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4, A5 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
  AddAction(A5);
end;

function TTutorialDirectorComponent.AddActions(const A1, A2 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);

end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4, A5, A6 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
  AddAction(A5);
  AddAction(A6);
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4, A5, A6, A7, A8, A9 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
  AddAction(A5);
  AddAction(A6);
  AddAction(A7);
  AddAction(A8);
  AddAction(A9);
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4, A5, A6, A7, A8, A9, A10 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
  AddAction(A5);
  AddAction(A6);
  AddAction(A7);
  AddAction(A8);
  AddAction(A9);
  AddAction(A10);
end;

function TTutorialDirectorComponent.IfGameEventGotoStep(const GameEvent : string; const TargetLabel : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddStepGameEvent(GameEvent);
  StepIsOptional;
  AddAction(TTutorialDirectorActionGotoStep.Create.UID(TargetLabel));
end;

function TTutorialDirectorComponent.IfLastEntityDiesGotoStep(const TargetLabel : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddStepLastEntityDies();
  StepIsOptional;
  AddAction(TTutorialDirectorActionGotoStep.Create.UID(TargetLabel));
end;

function TTutorialDirectorComponent.IfTimerGotoStep(const Interval : integer; const TargetLabel : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddStepTimer(Interval);
  StepIsOptional;
  AddAction(TTutorialDirectorActionGotoStep.Create.UID(TargetLabel));
end;

function TTutorialDirectorComponent.IfGameTickGotoStep(const GameTick : integer; const TargetLabel : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddStepGameTick(GameTick);
  StepIsOptional;
  AddAction(TTutorialDirectorActionGotoStep.Create.UID(TargetLabel));
end;

function TTutorialDirectorComponent.LockCamera : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(TTutorialDirectorActionLockCamera.Create);
end;

function TTutorialDirectorComponent.LockGroup(const GroupName : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionKeybinding.Create
    .LoadElementsFromGroup(GroupName)
    .Block,
    TTutorialDirectorActionGUIElement.Create
    .LoadElementsFromGroup(GroupName)
    .Lock
    );
end;

function TTutorialDirectorComponent.MoveCamera(X, Y : single) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(TTutorialDirectorActionMoveCamera.Create.MoveTo(X, Y));
end;

function TTutorialDirectorComponent.MoveCameraOverTime(X, Y : single; Time : integer) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(TTutorialDirectorActionMoveCamera.Create.MoveTo(X, Y).Time(Time));
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4, A5, A6, A7 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
  AddAction(A5);
  AddAction(A6);
  AddAction(A7);
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4, A5, A6, A7, A8 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
  AddAction(A5);
  AddAction(A6);
  AddAction(A7);
  AddAction(A8);
end;

function TTutorialDirectorComponent.AddStepCamPos(X, Y, Range : single) : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.TriggerOn := stCamPos;
  FActionQueue.Last.TargetCamPos := RCircle.Create(RVector2.Create(X, Y), Range);
end;

function TTutorialDirectorComponent.AddStepClientInit : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.TriggerOn := stClientInit;
end;

function TTutorialDirectorComponent.AddStepGameEvent(const GameEvent : string) : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.Eventname := GameEvent;
  FActionQueue.Last.TriggerOn := stEvent;
end;

function TTutorialDirectorComponent.AddStepNever : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.TriggerOn := stNever;
end;

function TTutorialDirectorComponent.AddStepNewEntity(MustHave : TArray<byte>) : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.TriggerOn := stNewEntity;
  FActionQueue.Last.UnitPropertyMustHave := ByteArrayToSetUnitProperies(MustHave);
end;

function TTutorialDirectorComponent.AddStepTimer(const Interval : integer) : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.TriggerOn := stTime;
  FActionQueue.Last.Timer := TTimer.Create(Interval);
end;

function TTutorialDirectorComponent.AddStepUIDsDead(const UIDs : TArray<string>) : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.TriggerOn := stUnitsDead;
  FActionQueue.Last.FUnitUIDs := UIDs;
end;

function TTutorialDirectorComponent.AllowMultiCardPlay : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(
    TTutorialDirectorActionHUD.Create
    .AllowMultiCardPlay
    );
end;

function TTutorialDirectorComponent.AddStepGameTick(const GameTick : integer) : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.GameTick := GameTick;
  FActionQueue.Last.TriggerOn := stGameTick;
end;

function TTutorialDirectorComponent.AddStepLastEntityDies : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Add(TTutorialDirectorStep.Create(self));
  FActionQueue.Last.TriggerOn := stLastUnitDies;
end;

function TTutorialDirectorComponent.BuildElementGroup(const GroupName : string; const Elements : TArray<string>) : TTutorialDirectorComponent;
begin
  Result := self;
  FGroups.AddOrSetValue(GroupName.ToLowerInvariant, Elements);
end;

function TTutorialDirectorComponent.BuildKeybindingGroup(const GroupName : string; const Keybindings : TArray<byte>) : TTutorialDirectorComponent;
  function ByteArrayToKeybindingArray(const ByteArray : TArray<byte>) : TArray<EnumKeybinding>;
  var
    i : integer;
  begin
    setLength(Result, length(ByteArray));
    for i := 0 to length(Result) - 1 do
        Result[i] := EnumKeybinding(ByteArray[i]);
  end;

begin
  Result := self;
  FKeybindingGroups.AddOrSetValue(GroupName.ToLowerInvariant, ByteArrayToKeybindingArray(Keybindings));
end;

function TTutorialDirectorComponent.ClearGroupLock(const GroupName : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionKeybinding.Create
    .LoadElementsFromGroup(GroupName)
    .Unblock,
    TTutorialDirectorActionGUIElement.Create
    .LoadElementsFromGroup(GroupName)
    .ClearLock
    );
end;

function TTutorialDirectorComponent.ClearGroupUnshadow(const GroupName : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionGUIElement.Create
    .RemoveClass('unshadowed')
    .LoadElementsFromGroup(GroupName)
    );
end;

function TTutorialDirectorComponent.ClearGroupStates(const GroupName : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionKeybinding.Create
    .LoadElementsFromGroup(GroupName)
    .Unblock,
    TTutorialDirectorActionGUIElement.Create
    .LoadElementsFromGroup(GroupName)
    .Clear
    );
end;

function TTutorialDirectorComponent.ClearTutorialHint : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionTutorialHint.Create
    .Clear,
    TTutorialDirectorActionArrowHighlight.Create
    .Clear
    );
end;

function TTutorialDirectorComponent.ClearWorldObjects : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(TTutorialDirectorActionClearWorldObjects.Create);
end;

constructor TTutorialDirectorComponent.Create(Owner : TEntity);
begin
  inherited;
  FActionQueue := TObjectList<TTutorialDirectorStep>.Create;
  FWorldObjects := TObjectList<TVertexObject>.Create;
  FUnitFilterMustHave := [upUnit];
  FUnitFilterMustNotHave := [upGolem];
end;

class constructor TTutorialDirectorComponent.Create;
begin
  FGroups := TDictionary < string, TArray < string >>.Create;
  FKeybindingGroups := TDictionary < string, TArray < EnumKeybinding >>.Create;
end;

function TTutorialDirectorComponent.CurrentSteps : TArray<TTutorialDirectorStep>;
var
  i : integer;
begin
  Result := nil;
  i := FCurrentStepIndex;
  while (i >= 0) and (i < FActionQueue.Count) do
  begin
    setLength(Result, length(Result) + 1);
    Result[high(Result)] := FActionQueue[i];
    dec(i);
    if (i < 0) or not FActionQueue[i].FOptional then break;
  end;
end;

function TTutorialDirectorComponent.CurrentStepsTriggers : SetStepTrigger;
var
  CurrentSteps : TArray<TTutorialDirectorStep>;
  i : integer;
begin
  Result := [];
  CurrentSteps := self.CurrentSteps;
  for i := 0 to length(CurrentSteps) - 1 do
      include(Result, CurrentSteps[i].TriggerOn);
end;

class destructor TTutorialDirectorComponent.Destroy;
begin
  FGroups.Free;
  FKeybindingGroups.Free;
end;

destructor TTutorialDirectorComponent.Destroy;
var
  LastStepUid : string;
  i : integer;
begin
  if assigned(HUD) then HUD.IsTutorial := False;
  LastStepUid := 'NOT SET';
  for i := FCurrentStepIndex - 1 downto 0 do
    if (i < FActionQueue.Count) and not FActionQueue[i].StepUID.IsEmpty then
    begin
      LastStepUid := FActionQueue[i].StepUID;
      break;
    end;
  GameManagerAPI.SendTutorialLastStep(LastStepUid).Free;
  FActionQueue.Free;
  FWorldObjects.Free;
  inherited;
end;

function TTutorialDirectorComponent.OnGameTick : boolean;
var
  CurrentSteps : TArray<TTutorialDirectorStep>;
  i : integer;
begin
  Result := True;
  inc(FCurrentGameTick);
  if not FFirstGameTickSend then
  begin
    HUD.SendGameevent(GAME_EVENT_GAME_TICK_FIRST);
    FFirstGameTickSend := True;
  end
  else
      HUD.SendGameevent(GAME_EVENT_GAME_TICK);

  if stGameTick in CurrentStepsTriggers then
  begin
    CurrentSteps := self.CurrentSteps;
    for i := 0 to length(CurrentSteps) - 1 do
      if CurrentSteps[i].CheckGameTickTrigger(FCurrentGameTick) then
      begin
        NextStep;
        ExecuteStep(CurrentSteps[i]);
        exit;
      end;
  end;
end;

procedure TTutorialDirectorComponent.ExecuteStep(Step : TTutorialDirectorStep);
begin
  if not FExecuting then
  begin
    FExecuting := True;
    ExecuteStepActions(Step);
    FExecuting := False;
  end;
end;

procedure TTutorialDirectorComponent.ExecuteStepActions(Step : TTutorialDirectorStep);
var
  i : integer;
begin
  for i := 0 to Step.Actions.Count - 1 do
      Step.Actions[i].Execute;
end;

procedure TTutorialDirectorComponent.DoGotoStep(StepLabel : string);
var
  i : integer;
begin
  StepLabel := StepLabel.ToLowerInvariant;
  for i := 0 to FActionQueue.Count - 1 do
    if FActionQueue[i].StepUID = StepLabel then
    begin
      FCurrentStepIndex := i;
      NextStep;
      ExecuteStepActions(FActionQueue[i]);
      break;
    end;
end;

function TTutorialDirectorComponent.GotoStep(const StepLabel : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(
    TTutorialDirectorActionGotoStep.Create
    .UID(StepLabel)
    );
end;

function TTutorialDirectorComponent.GroundText(X : single; const Text : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(
    TTutorialDirectorActionWorldText.Create
    .Text(Text)
    .Position(X, 0.1, -23)
    );
end;

function TTutorialDirectorComponent.HideGroup(const GroupName : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionKeybinding.Create
    .LoadElementsFromGroup(GroupName)
    .Block,
    TTutorialDirectorActionGUIElement.Create
    .LoadElementsFromGroup(GroupName)
    .Hide
    );
end;

procedure TTutorialDirectorComponent.NextStep;
var
  i : integer;
begin
  for i := FCurrentStepIndex + 1 to FActionQueue.Count - 1 do
  begin
    if assigned(FActionQueue[i].Timer) then
        FActionQueue[i].Timer.Start;
    if not FActionQueue[i].FOptional then
    begin
      FCurrentStepIndex := i;
      break;
    end;
  end;
end;

function TTutorialDirectorComponent.OnClientInit : boolean;
var
  CurrentSteps : TArray<TTutorialDirectorStep>;
  i : integer;
begin
  Result := True;
  if assigned(HUD) then HUD.IsTutorial := True;
  if stClientInit in CurrentStepsTriggers then
  begin
    CurrentSteps := self.CurrentSteps;
    for i := 0 to length(CurrentSteps) - 1 do
      if CurrentSteps[i].CheckClientInitTrigger then
      begin
        NextStep;
        ExecuteStep(CurrentSteps[i]);
        exit;
      end;
  end;
end;

function TTutorialDirectorComponent.OnGameEvent(Eventname : RParam) : boolean;
var
  CurrentSteps : TArray<TTutorialDirectorStep>;
  i : integer;
  Event : string;
begin
  Result := True;
  if stEvent in CurrentStepsTriggers then
  begin
    Event := Eventname.AsString;
    CurrentSteps := self.CurrentSteps;
    for i := 0 to length(CurrentSteps) - 1 do
      if CurrentSteps[i].CheckGameEventTrigger(Event) then
      begin
        NextStep;
        ExecuteStep(CurrentSteps[i]);
        exit;
      end;
  end;
end;

function TTutorialDirectorComponent.OnIdle : boolean;
var
  CurrentSteps : TArray<TTutorialDirectorStep>;
  i : integer;
begin
  Result := True;
  if stUnitsDead in CurrentStepsTriggers then
  begin
    CurrentSteps := self.CurrentSteps;
    for i := 0 to length(CurrentSteps) - 1 do
      if CurrentSteps[i].CheckUIDDead then
      begin
        NextStep;
        ExecuteStep(CurrentSteps[i]);
        exit;
      end;
  end;
  if stTime in CurrentStepsTriggers then
  begin
    CurrentSteps := self.CurrentSteps;
    for i := 0 to length(CurrentSteps) - 1 do
      if CurrentSteps[i].CheckTimeTrigger then
      begin
        NextStep;
        ExecuteStep(CurrentSteps[i]);
        exit;
      end;
  end;
  if stCamPos in CurrentStepsTriggers then
  begin
    CurrentSteps := self.CurrentSteps;
    for i := 0 to length(CurrentSteps) - 1 do
      if CurrentSteps[i].CheckCamPos then
      begin
        NextStep;
        ExecuteStep(CurrentSteps[i]);
        exit;
      end;
  end;
  if stLastUnitDies in CurrentStepsTriggers then
  begin
    CurrentSteps := self.CurrentSteps;
    for i := 0 to length(CurrentSteps) - 1 do
      if CurrentSteps[i].CheckLastUnitDiesTrigger(FLastUnit) then
      begin
        NextStep;
        ExecuteStep(CurrentSteps[i]);
        exit;
      end;
  end;
  if Keyboard.KeyUp(TasteEnter) or Keyboard.KeyUp(TasteNumEnter) then
  begin
    HUD.IsTutorialHintOpen := False;
    HUD.SendGameevent(GAME_EVENT_TUTORIAL_HINT_CONFIRMED)
  end;
  for i := 0 to FWorldObjects.Count - 1 do
      FWorldObjects[i].AddRenderJob;
end;

function TTutorialDirectorComponent.OnNewEntity(NewEntity : RParam) : boolean;
var
  CurrentSteps : TArray<TTutorialDirectorStep>;
  i : integer;
  Entity : TEntity;
begin
  Result := True;
  Entity := NewEntity.AsType<TEntity>;
  if ((FUnitFilterMustHave = []) or (Entity.UnitProperties * FUnitFilterMustHave <> [])) and
    (Entity.UnitProperties * FUnitFilterMustNotHave = []) then
  begin
    FLastUnit := NewEntity.AsType<TEntity>.ID;

    if stNewEntity in CurrentStepsTriggers then
    begin
      CurrentSteps := self.CurrentSteps;
      for i := 0 to length(CurrentSteps) - 1 do
        if CurrentSteps[i].CheckNewEntityTrigger(Entity) then
        begin
          NextStep;
          ExecuteStep(CurrentSteps[i]);
          exit;
        end;
    end;
  end;
end;

function TTutorialDirectorComponent.PassiveText(const Text, ButtonText : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(
    TTutorialDirectorActionTutorialHint.Create
    .Text(Text)
    .Passive
    .ButtonText(ButtonText)
    );
end;

function TTutorialDirectorComponent.PreventMultiCardPlay : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(
    TTutorialDirectorActionHUD.Create
    .PreventMultiCardPlay
    );
end;

function TTutorialDirectorComponent.SendGameevent(const Eventname : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(TTutorialDirectorActionSendGameevent.Create.Eventname(Eventname));
end;

function TTutorialDirectorComponent.StepIsOptional : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Last.FOptional := True;
end;

function TTutorialDirectorComponent.StepLabel(const StepLabel : string) : TTutorialDirectorComponent;
var
  i : integer;
begin
  Result := self;
  for i := 0 to FActionQueue.Count - 1 do
      assert(FActionQueue[i].StepUID <> StepLabel.ToLowerInvariant, 'TTutorialDirectorComponent.StepLabel: Steplabels must be unique! Found duplicate of ' + StepLabel);
  FActionQueue.Last.StepUID := StepLabel.ToLowerInvariant;
end;

function TTutorialDirectorComponent.StepTriggerCount(const StepTriggerCount : integer) : TTutorialDirectorComponent;
begin
  Result := self;
  FActionQueue.Last.TriggerCount := StepTriggerCount;
end;

function TTutorialDirectorComponent.UnlockCamera : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(TTutorialDirectorActionUnlockCamera.Create);
end;

function TTutorialDirectorComponent.UnlockGroup(const GroupName : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionKeybinding.Create
    .LoadElementsFromGroup(GroupName)
    .Unblock,
    TTutorialDirectorActionGUIElement.Create
    .LoadElementsFromGroup(GroupName)
    .Unlock
    );
end;

function TTutorialDirectorComponent.UnshadowGroup(const GroupName : string) : TTutorialDirectorComponent;
begin
  Result := self;
  AddActions(
    TTutorialDirectorActionGUIElement.Create
    .AddClass('unshadowed')
    .LoadElementsFromGroup(GroupName)
    );
end;

function TTutorialDirectorComponent.AddActions(const A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11 : TTutorialDirectorAction) : TTutorialDirectorComponent;
begin
  Result := self;
  AddAction(A1);
  AddAction(A2);
  AddAction(A3);
  AddAction(A4);
  AddAction(A5);
  AddAction(A6);
  AddAction(A7);
  AddAction(A8);
  AddAction(A9);
  AddAction(A10);
  AddAction(A11);
end;

{ TTutorialDirectorStep }

function TTutorialDirectorStep.CheckCamPos : boolean;
begin
  Result := (TriggerOn = stCamPos) and TargetCamPos.ContainsPoint(HUD.CameraPosition);
  Result := Result and IncrementAndCheckTriggerCount;
end;

function TTutorialDirectorStep.CheckClientInitTrigger : boolean;
begin
  Result := TriggerOn = stClientInit;
  Result := Result and IncrementAndCheckTriggerCount;
end;

function TTutorialDirectorStep.CheckGameEventTrigger(const GameEvent : string) : boolean;
begin
  Result := (TriggerOn = stEvent) and (GameEvent = self.Eventname);
  Result := Result and IncrementAndCheckTriggerCount;
end;

function TTutorialDirectorStep.CheckGameTickTrigger(CurrentGameTick : integer) : boolean;
begin
  Result := (TriggerOn = stGameTick) and (GameTick <= CurrentGameTick);
  Result := Result and IncrementAndCheckTriggerCount;
end;

function TTutorialDirectorStep.CheckLastUnitDiesTrigger(UnitID : integer) : boolean;
var
  Entity : TEntity;
begin
  Result := (TriggerOn = stLastUnitDies) and not Game.EntityManager.TryGetEntityByID(UnitID, Entity);
  Result := Result and IncrementAndCheckTriggerCount;
end;

function TTutorialDirectorStep.CheckNewEntityTrigger(Entity : TEntity) : boolean;
begin
  Result := (TriggerOn = stNewEntity) and
    ((UnitPropertyMustHave = []) or (UnitPropertyMustHave * Entity.UnitProperties <> []));
  Result := Result and IncrementAndCheckTriggerCount;
end;

function TTutorialDirectorStep.CheckTimeTrigger : boolean;
begin
  Result := (TriggerOn = stTime) and assigned(Timer) and (Timer.Expired);
  Result := Result and IncrementAndCheckTriggerCount;
end;

function TTutorialDirectorStep.CheckUIDDead : boolean;
var
  Entity : TEntity;
  i : integer;
begin
  Result := (TriggerOn = stUnitsDead);
  for i := 0 to length(FUnitUIDs) - 1 do
      Result := Result and not Game.EntityManager.TryGetEntityByUID(FUnitUIDs[i], Entity);
  Result := Result and IncrementAndCheckTriggerCount;
end;

constructor TTutorialDirectorStep.Create(Owner : TTutorialDirectorComponent);
begin
  FOwner := Owner;
  Actions := TObjectList<TTutorialDirectorAction>.Create;
  GameTick := -1;
  TriggerCount := 1;
end;

destructor TTutorialDirectorStep.Destroy;
begin
  Actions.Free;
  Timer.Free;
  inherited;
end;

function TTutorialDirectorStep.IncrementAndCheckTriggerCount : boolean;
begin
  inc(TriggeredTimes);
  Result := TriggeredTimes >= TriggerCount;
end;

{ TTutorialDirectorActionSendGameevent }

function TTutorialDirectorActionSendGameevent.Eventname(const Eventname : string) : TTutorialDirectorActionSendGameevent;
begin
  Result := self;
  HArray.Push<string>(FEventnames, Eventname);
end;

procedure TTutorialDirectorActionSendGameevent.Execute;
var
  i : integer;
begin
  for i := 0 to length(FEventnames) - 1 do
  begin
    GlobalEventbus.Trigger(eiGameEvent, [FEventnames[i]]);
    HUD.CallClientCommand(ccTutorialGameEvent, FEventnames[i]);
  end;
end;

{ TTutorialDirectorActionWorld }

function TTutorialDirectorActionWorld.Position(const X, Y, Z : single) : TTutorialDirectorActionWorld;
begin
  Result := self;
  FPosition.X := X;
  FPosition.Y := Y;
  FPosition.Z := Z;
end;

function TTutorialDirectorActionWorld.Size(const Width, Height : single) : TTutorialDirectorActionWorld;
begin
  Result := self;
  FSize.X := Width;
  FSize.Y := Height;
end;

function TTutorialDirectorActionWorld.Color(const Color : cardinal) : TTutorialDirectorActionWorld;
begin
  Result := self;
  FColor := RColor.Create(Color);
end;

constructor TTutorialDirectorActionWorld.Create;
begin
  inherited;
  FColor := RColor.CWHITE;
  FLeft := RVector3.UNITZ;
  FUp := RVector3.UNITX;
  FSize := RVector2.Create(10, 5);
end;

function TTutorialDirectorActionWorld.Left(const X, Y, Z : single) : TTutorialDirectorActionWorld;
begin
  Result := self;
  FLeft.X := X;
  FLeft.Y := Y;
  FLeft.Z := Z;
end;

function TTutorialDirectorActionWorld.Up(const X, Y, Z : single) : TTutorialDirectorActionWorld;
begin
  Result := self;
  FUp.X := X;
  FUp.Y := Y;
  FUp.Z := Z;
end;

{ TTutorialDirectorActionWorldText }

constructor TTutorialDirectorActionWorldText.Create;
begin
  inherited;
  FWorldToPixelFactor := 50;
  FFontHeight := 48;
end;

procedure TTutorialDirectorActionWorldText.Execute;
var
  Font : TVertexFontWorld;
  FontDescription : RFontDescription;
begin
  FontDescription := RFontDescription.Create(DefaultFontFamily);
  FontDescription.Height := FFontHeight;
  FontDescription.Weight := fwMedium;
  Font := TVertexFontWorld.Create(VertexEngine, FontDescription);
  Font.Position := FPosition;
  Font.Left := FLeft;
  Font.Up := FUp;
  Font.Size := FSize;
  Font.Text := HInternationalizer.TranslateTextRecursive(FText).Replace('\n', sLineBreak);
  Font.Color := FColor;
  Font.WorldToPixelFactor := FWorldToPixelFactor;
  Font.Format := [ffCenter, ffVerticalCenter, ffWordWrap];
  Font.Visible := True;
  FOwner.FWorldObjects.Add(Font);
end;

function TTutorialDirectorActionWorldText.FontHeight(const FontHeight : single) : TTutorialDirectorActionWorldText;
begin
  Result := self;
  FFontHeight := FontHeight;
end;

function TTutorialDirectorActionWorldText.Text(const Text : string) : TTutorialDirectorActionWorldText;
begin
  Result := self;
  FText := Text;
end;

function TTutorialDirectorActionWorldText.WorldToPixelFactor(const Factor : single) : TTutorialDirectorActionWorldText;
begin
  Result := self;
  FWorldToPixelFactor := Factor;
end;

{ TTutorialDirectorActionWorldTexture }

procedure TTutorialDirectorActionWorldTexture.Execute;
var
  Quad : TVertexWorldspaceQuad;
begin
  Quad := TVertexWorldspaceQuad.Create(VertexEngine);
  Quad.Position := FPosition;
  Quad.Left := FLeft;
  Quad.Up := FUp;
  Quad.Size := FSize;
  Quad.Visible := True;
  Quad.OwnsTexture := True;
  Quad.Texture := TTexture.CreateTextureFromFile(AbsolutePath(FTexturePath), GFXD.Device3D);
  FOwner.FWorldObjects.Add(Quad);
end;

function TTutorialDirectorActionWorldTexture.TexturePath(const TexturePath : string) : TTutorialDirectorActionWorldTexture;
begin
  Result := self;
  FTexturePath := TexturePath;
end;

{ TTutorialDirectorActionClearWorldObjects }

procedure TTutorialDirectorActionClearWorldObjects.Execute;
begin
  FOwner.FWorldObjects.Clear;
end;

{ TTutorialDirectorActionLockCamera }

procedure TTutorialDirectorActionLockCamera.Execute;
begin
  if FLimit then
  begin
    HUD.CameraLaneXLimited := True;
    HUD.CameraLaneXLimit := FThreshold;
  end
  else
  begin
    HUD.CameraLocked := True;
    HUD.CameraLockedSpawnerJumpEnabled := FSpawnerJumpEnabled;
  end;
end;

function TTutorialDirectorActionLockCamera.LimitX(Threshold : single) : TTutorialDirectorActionLockCamera;
begin
  Result := self;
  FThreshold := Threshold;
  FLimit := True;
end;

{ TTutorialDirectorActionUnlockCamera }

procedure TTutorialDirectorActionUnlockCamera.Execute;
begin
  HUD.CameraLocked := False;
  HUD.CameraFollowEntity := -1;
  HUD.CameraLockedSpawnerJumpEnabled := False;
  HUD.CameraLaneXLimited := False;
end;

{ TTutorialDirectorActionMoveCamera }

procedure TTutorialDirectorActionMoveCamera.Execute;
begin
  HUD.CameraLockedSpawnerJumpEnabled := False;
  HUD.CameraMoveTo(FTargetPos, FTime);
  if FFollow then
      HUD.CameraFollowEntity := FOwner.FLastUnit;
end;

function TTutorialDirectorActionMoveCamera.FollowLastSpawnedEntity : TTutorialDirectorActionMoveCamera;
begin
  Result := self;
  FFollow := True;
end;

function TTutorialDirectorActionMoveCamera.MoveTo(X, Y : single) : TTutorialDirectorActionMoveCamera;
begin
  Result := self;
  FTargetPos.X := X;
  FTargetPos.Y := Y;
end;

function TTutorialDirectorActionMoveCamera.Time(Time : integer) : TTutorialDirectorActionMoveCamera;
begin
  Result := self;
  FTime := Time;
end;

{ TTutorialDirectorActionTutorialHint }

function TTutorialDirectorActionTutorialHint.ButtonText(const ButtonText : string) : TTutorialDirectorActionTutorialHint;
begin
  Result := self;
  FButtonText := ButtonText;
end;

function TTutorialDirectorActionTutorialHint.Clear : TTutorialDirectorActionTutorialHint;
begin
  Result := self;
  FClear := True;
end;

procedure TTutorialDirectorActionTutorialHint.Execute;
begin
  if FClear then
  begin
    HUD.IsTutorialHintOpen := False;
  end
  else
  begin
    if FText <> '' then
    begin
      HUD.TutorialWindowHighlight := False;
      HUD.IsTutorialHintOpen := True;
      HUD.TutorialHintText := FText;
      HUD.TutorialHintFullscreen := not FIsWindow;
      HUD.TutorialWindowPosition := FPosition;
      HUD.TutorialWindowButtonText := FButtonText;
    end;
  end;
end;

function TTutorialDirectorActionTutorialHint.Passive : TTutorialDirectorActionTutorialHint;
begin
  Result := self;
  FIsWindow := True;
end;

function TTutorialDirectorActionTutorialHint.Text(const Text : string) : TTutorialDirectorActionTutorialHint;
begin
  Result := self;
  FText := Text;
end;

{ TTutorialDirectorActionCamera }

function TTutorialDirectorActionCamera.SpawnerJumpAllowed : TTutorialDirectorActionCamera;
begin
  Result := self;
  FSpawnerJumpEnabled := True;
end;

{ TTutorialDirectorActionArrowHighlight }

constructor TTutorialDirectorActionArrowHighlight.Create;
begin
  FWindowAnchor := caAuto;
end;

function TTutorialDirectorActionArrowHighlight.Element(const ElementUID : string) : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FElement := ElementUID;
end;

function TTutorialDirectorActionArrowHighlight.ElementAnchor(Anchor : EnumComponentAnchor) : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FElementAnchor := Anchor;
end;

procedure TTutorialDirectorActionArrowHighlight.Execute;
var
  Component : TGUIComponent;
begin
  if FClear then
  begin
    HUD.IsTutorialHintOpen := False;
  end
  else
  begin
    HUD.IsTutorialHintOpen := True;
    HUD.TutorialHintText := FText;
    HUD.TutorialHintFullscreen := False;
    HUD.TutorialWindowHighlight := True;
    HUD.TutorialWindowButtonText := FWindowButton;
    HUD.TutorialWindowBackdrop := not FNoBackdrop;
    HUD.TutorialWindowArrowVisible := not FNoArrow;
    if FWindowAnchor = caAuto then
        FWindowAnchor := InverseAnchor(FElementAnchor);
    if (FElement <> '') then
    begin
      if GUI.FindUnique(FElement, Component) then
      begin
        HUD.TutorialWindowPosition := Component.AnchorPosition(FElementAnchor);
        HUD.TutorialWindowAnchor := FWindowAnchor;
      end
      else Hlog.Write(elWarning, 'Could not find component ' + FElement);
    end
    else
    begin
      HUD.TutorialWindowPosition := GFXD.MainScene.Camera.WorldSpaceToScreenSpace(FWorldPoint + (((AnchorToVector(FWindowAnchor).X * GFXD.MainScene.Camera.ScreenLeft) + (AnchorToVector(FWindowAnchor).Y * GFXD.MainScene.Camera.ScreenUp)).Normalize * FWorldRadius)).XY.round;
      HUD.TutorialWindowAnchor := FWindowAnchor;
    end;
    HUD.TutorialWindowPosition := HUD.TutorialWindowPosition.Clamp(RIntVector2.Create(50, 50), GFXD.Settings.Resolution.Size - 50);
  end;
end;

function TTutorialDirectorActionArrowHighlight.LoadElementFromGroup(const GroupName : string) : TTutorialDirectorActionArrowHighlight;
var
  Elements : TArray<string>;
begin
  Result := self;
  Elements := [''];
  if not TTutorialDirectorComponent.FGroups.TryGetValue(GroupName.ToLowerInvariant, Elements) then
      Hlog.Write(elWarning, 'TTutorialDirectorActionArrowHighlight.LoadElementFromGroup: Could not find group ' + GroupName);
  assert(length(Elements) > 0, 'TTutorialDirectorActionArrowHighlight.LoadElementFromGroup: Group ''' + GroupName + ''' is empty!');
  FElement := Elements[0];
end;

function TTutorialDirectorActionArrowHighlight.LockGUI : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FLockGUI := True;
end;

function TTutorialDirectorActionArrowHighlight.NoArrow : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FNoArrow := True;
end;

function TTutorialDirectorActionArrowHighlight.NoBackdrop : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FNoBackdrop := True;
end;

function TTutorialDirectorActionArrowHighlight.Clear : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FClear := True;
end;

function TTutorialDirectorActionArrowHighlight.Text(const Text : string) : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FText := Text;
end;

function TTutorialDirectorActionArrowHighlight.WindowAnchor(Anchor : EnumComponentAnchor) : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FWindowAnchor := Anchor;
end;

function TTutorialDirectorActionArrowHighlight.WindowButton(const ButtonText : string) : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FWindowButton := ButtonText;
end;

function TTutorialDirectorActionArrowHighlight.WorldPoint(const PointX, PointY, PointZ : single) : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FWorldPoint := RVector3.Create(PointX, PointY, PointZ);
end;

function TTutorialDirectorActionArrowHighlight.WorldRadius(const Radius : single) : TTutorialDirectorActionArrowHighlight;
begin
  Result := self;
  FWorldRadius := Radius;
end;

{ TTutorialDirectorActionGotoStep }

procedure TTutorialDirectorActionGotoStep.Execute;
begin
  FOwner.DoGotoStep(FStepUID);
end;

function TTutorialDirectorActionGotoStep.UID(const StepUID : string) : TTutorialDirectorActionGotoStep;
begin
  Result := self;
  FStepUID := StepUID.ToLowerInvariant;
end;

{ TTutorialDirectorActionGUIElement }

function TTutorialDirectorActionGUIElement.AddClass(const Classname : string) : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  HArray.Push<string>(FAddClass, Classname);
end;

function TTutorialDirectorActionGUIElement.Clear : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  ClearLock;
  ClearVisibility;
end;

function TTutorialDirectorActionGUIElement.ClearLock : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  FClearLock := True;
end;

function TTutorialDirectorActionGUIElement.ClearVisibility : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  FClearVisibility := True;
end;

destructor TTutorialDirectorActionGUIElement.Destroy;
var
  Component : TGUIComponent;
  i, j : integer;
begin
  if assigned(GUI) then
  begin
    for i := 0 to length(FElements) - 1 do
    begin
      if GUI.FindUnique(FElements[i], Component) then
      begin
        Component.ClearEnabled;
        Component.ClearVisible;
        for j := 0 to length(FRemoveClass) - 1 do
            Component.RemoveClass(FRemoveClass[j]);
      end;
      // else ... we only want to reset persistent element, others are not important
    end;
  end;
end;

function TTutorialDirectorActionGUIElement.Element(const ElementUID : string) : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  HArray.Push<string>(FElements, ElementUID);
end;

procedure TTutorialDirectorActionGUIElement.Execute;
var
  Component : TGUIComponent;
  i, j : integer;
begin
  for i := 0 to length(FElements) - 1 do
  begin
    if GUI.FindUnique(FElements[i], Component) then
    begin
      if FClearLock then
          Component.ClearEnabled;
      if FClearVisibility then
          Component.ClearVisible;
      if FHide then
          Component.Visible := False;
      if FEnable then
          Component.Enabled := True;
      if FDisable then
          Component.Enabled := False;
      for j := 0 to length(FAddClass) - 1 do
          Component.AddClass(FAddClass[j]);
      for j := 0 to length(FRemoveClass) - 1 do
          Component.RemoveClass(FRemoveClass[j]);
    end
    else Hlog.Write(elWarning, 'TTutorialDirectorActionGUIElement.Execute: Could not find component ' + FElements[i]);
  end;
end;

function TTutorialDirectorActionGUIElement.Hide : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  FHide := True;
end;

function TTutorialDirectorActionGUIElement.LoadElementsFromGroup(const GroupName : string) : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  if not TTutorialDirectorComponent.FGroups.TryGetValue(GroupName.ToLowerInvariant, FElements) then
      Hlog.Write(elWarning, 'TTutorialDirectorActionGUIElement.LoadElementsFromGroup: Could not find group ' + GroupName);
end;

function TTutorialDirectorActionGUIElement.Lock : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  FDisable := True;
end;

function TTutorialDirectorActionGUIElement.RemoveClass(const Classname : string) : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  HArray.Push<string>(FRemoveClass, Classname);
end;

function TTutorialDirectorActionGUIElement.Unlock : TTutorialDirectorActionGUIElement;
begin
  Result := self;
  FEnable := True;
end;

{ TTutorialDirectorActionKeybinding }

function TTutorialDirectorActionKeybinding.Block : TTutorialDirectorActionKeybinding;
begin
  Result := self;
  FBlock := True;
end;

destructor TTutorialDirectorActionKeybinding.Destroy;
begin
  if assigned(KeybindingManager) then
      KeybindingManager.UnblockBindings(FKeybindings);
  inherited;
end;

procedure TTutorialDirectorActionKeybinding.Execute;
begin
  if FBlock then
      KeybindingManager.BlockBindings(FKeybindings)
  else
      KeybindingManager.UnblockBindings(FKeybindings);
end;

function TTutorialDirectorActionKeybinding.Keybinding(const Keybinding : EnumKeybinding) : TTutorialDirectorActionKeybinding;
begin
  Result := self;
  HArray.Push<EnumKeybinding>(FKeybindings, Keybinding);
end;

function TTutorialDirectorActionKeybinding.LoadElementsFromGroup(const GroupName : string) : TTutorialDirectorActionKeybinding;
begin
  Result := self;
  if not TTutorialDirectorComponent.FKeybindingGroups.TryGetValue(GroupName.ToLowerInvariant, FKeybindings) then
      Hlog.Write(elWarning, 'TTutorialDirectorActionKeybinding.LoadElementsFromGroup: Could not find group ' + GroupName);
end;

function TTutorialDirectorActionKeybinding.Unblock : TTutorialDirectorActionKeybinding;
begin
  Result := self;
  FBlock := False;
end;

{ TTutorialDirectorActionScript }

constructor TTutorialDirectorActionScript.Create;
begin
  FEntityID := -1;
end;

function TTutorialDirectorActionScript.Entity(const EntityUID : string) : TTutorialDirectorActionScript;
begin
  Result := self;
  FEntityUID := EntityUID;
end;

function TTutorialDirectorActionScript.Entity(const EntityID : integer) : TTutorialDirectorActionScript;
begin
  Result := self;
  FEntityID := EntityID;
end;

procedure TTutorialDirectorActionScript.Execute;
var
  Entity : TEntity;
begin
  if Game.EntityManager.TryGetEntityByUID(FEntityUID, Entity) then
      Entity.ApplyScript(FScript)
  else if Game.EntityManager.TryGetEntityByID(FEntityID, Entity) then
      Entity.ApplyScript(FScript);
end;

function TTutorialDirectorActionScript.Scriptfile(const Filename : string) : TTutorialDirectorActionScript;
begin
  Result := self;
  FScript := Filename;
end;

{ TTutorialDirectorActionHUD }

function TTutorialDirectorActionHUD.AllowMultiCardPlay : TTutorialDirectorActionHUD;
begin
  Result := self;
  FPreventConsecutiveCardPlay := nbFalse;
end;

procedure TTutorialDirectorActionHUD.Execute;
begin
  if FPreventConsecutiveCardPlay = nbFalse then
      HUD.PreventConsecutivePlaying := False
  else if FPreventConsecutiveCardPlay = nbTrue then
      HUD.PreventConsecutivePlaying := True;
end;

function TTutorialDirectorActionHUD.PreventMultiCardPlay : TTutorialDirectorActionHUD;
begin
  Result := self;
  FPreventConsecutiveCardPlay := nbTrue;
end;

{ TBuildGridManagerComponent.TBuildGridVisualizer }

constructor TBuildGridManagerComponent.TBuildGridVisualizer.Create(BuildZone : TBuildZone);
var
  X, Y : integer;
  Tile : TTile;
begin
  FActivateEffect := ParticleEffectEngine.CreateParticleEffectFromFile(PATH_GRAPHICS_PARTICLE_EFFECTS_SHARED + 'buildgrid_activate.pfx');
  FTiles := TObjectList<TTile>.Create;
  FFieldCount := 0;
  for X := 0 to BuildZone.Size.X - 1 do
    for Y := 0 to BuildZone.Size.Y - 1 do
      if not BuildZone.IsBanned(X, Y) then
      begin
        Tile := TTile.Create(BuildZone, RIntVector2.Create(X, Y));
        FTiles.Add(Tile);
        inc(FFieldCount);
      end;
  FCurrentRotationCount := FFieldCount;
end;

destructor TBuildGridManagerComponent.TBuildGridVisualizer.Destroy;
begin
  FTiles.Free;
  FActivateEffect.Free;
  inherited;
end;

procedure TBuildGridManagerComponent.TBuildGridVisualizer.ShowInvalid;
var
  i : integer;
begin
  for i := 0 to FTiles.Count - 1 do
  begin
    FTiles[i].Mesh.AbsoluteColorAdjustmentH := True;
    FTiles[i].Mesh.ColorAdjustment := RVector3.Create(0, 0.12, 0.04) * RVector3.Create(1, HGeneric.TertOp<single>(FTiles[i].IsActive, 0, 1), 1);
  end;
end;

procedure TBuildGridManagerComponent.TBuildGridVisualizer.ShowOccupation(const ReferencePosition : RVector2; TeamID : integer);
const
  INNER_RADIUS  = 2 * TBuildZone.GRIDNODESIZE;
  FADING_RADIUS = 4 * TBuildZone.GRIDNODESIZE;
var
  i : integer;
  Coordinate : RIntVector2;
  BuildZone : TBuildZone;
begin
  for i := 0 to FTiles.Count - 1 do
  begin
    BuildZone := FTiles[i].BuildZone;
    Coordinate := FTiles[i].Coordinate;
    if BuildZone.IsFree(Coordinate) and (TeamID = BuildZone.TeamID) then
        FTiles[i].Mesh.ColorAdjustment := RVector3.Create(-0.17, 0.12, 0.04) * RVector3.Create(1, HGeneric.TertOp<single>(FTiles[i].IsActive, 0, 1), 1)
    else
        FTiles[i].Mesh.ColorAdjustment := RVector3.Create(-0.5, 0.12, 0.04) * RVector3.Create(1, HGeneric.TertOp<single>(FTiles[i].IsActive, 0, 1), 1);
  end;
end;

procedure TBuildGridManagerComponent.TBuildGridVisualizer.Spawn(const Coordinate : RIntVector2);
var
  i : integer;
begin
  for i := 0 to FTiles.Count - 1 do
    if FTiles[i].Coordinate = Coordinate then
    begin
      FActivateEffect.Position := FTiles[i].Mesh.Position;
      FActivateEffect.StartEmission;

      if FTiles[i].IsActive then
      begin
        FTiles[i].Activate;
        dec(FCurrentRotationCount);
      end;
    end;
  if CurrentRotationCount <= 0 then
      Reset;
end;

procedure TBuildGridManagerComponent.TBuildGridVisualizer.Reset;
var
  i : integer;
begin
  FCurrentRotationCount := FFieldCount;
  for i := 0 to FTiles.Count - 1 do
      FTiles[i].Reset;
end;

procedure TBuildGridManagerComponent.TBuildGridVisualizer.ResetColors;
var
  i : integer;
begin
  for i := 0 to FTiles.Count - 1 do
  begin
    FTiles[i].Mesh.AbsoluteColorAdjustmentH := False;
    FTiles[i].Mesh.AbsoluteColorAdjustmentS := False;
    FTiles[i].Mesh.AbsoluteColorAdjustmentV := False;
    FTiles[i].Mesh.ColorAdjustment := RVector3.ZERO;
  end
end;

{ TSuicideOnGameEndComponent }

function TSuicideOnGameEndComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  Owner.DeferFree;
end;

{ TClientFireTeamFilterComponent }

function TClientFireTeamFilterComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := not assigned(ClientGame) or (ClientGame.CommanderManager.ActiveCommanderTeamID = Owner.TeamID);
end;

initialization

ScriptManager.ExposeClass(TClickCollisionComponent);
ScriptManager.ExposeClass(TCommanderComponent);
ScriptManager.ExposeClass(TGameIntensityComponent);
ScriptManager.ExposeClass(TSuicideOnGameEndComponent);
ScriptManager.ExposeClass(TClientFireTeamFilterComponent);

ScriptManager.ExposeType(TypeInfo(EnumComponentAnchor));
ScriptManager.ExposeClass(TTutorialDirectorComponent);
ScriptManager.ExposeClass(TTutorialDirectorAction);
ScriptManager.ExposeClass(TTutorialDirectorActionSendGameevent);
ScriptManager.ExposeClass(TTutorialDirectorActionWorld);
ScriptManager.ExposeClass(TTutorialDirectorActionWorldText);
ScriptManager.ExposeClass(TTutorialDirectorActionWorldTexture);
ScriptManager.ExposeClass(TTutorialDirectorActionArrowHighlight);
ScriptManager.ExposeClass(TTutorialDirectorActionClearWorldObjects);
ScriptManager.ExposeClass(TTutorialDirectorActionCamera);
ScriptManager.ExposeClass(TTutorialDirectorActionLockCamera);
ScriptManager.ExposeClass(TTutorialDirectorActionUnlockCamera);
ScriptManager.ExposeClass(TTutorialDirectorActionMoveCamera);
ScriptManager.ExposeClass(TTutorialDirectorActionTutorialHint);
ScriptManager.ExposeClass(TTutorialDirectorActionGotoStep);
ScriptManager.ExposeClass(TTutorialDirectorActionGUIElement);
ScriptManager.ExposeClass(TTutorialDirectorActionKeybinding);
ScriptManager.ExposeClass(TTutorialDirectorActionScript);
ScriptManager.ExposeClass(TTutorialDirectorActionHUD);

end.
