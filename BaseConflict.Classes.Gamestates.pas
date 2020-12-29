unit BaseConflict.Classes.Gamestates;

interface

uses
  // ----------- Delphi -------------
  System.Types,
  System.UITypes,
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.DateUtils,
  Winapi.ActiveX,
  Winapi.ShellAPI,
  Winapi.Windows,
  Vcl.Clipbrd,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Taskbar,
  RegularExpressions,
  // --------- ThirdParty -----------
  IdCoderMIME,
  FMOD.Studio.Common,
  FMOD.Studio.Classes,
  steamclientpublic,
  steam_api,
  // --------- Engine ------------
  Engine.Core,
  Engine.Core.Types,
  Engine.Core.Lights,
  Engine.GFXApi,
  Engine.GUI,
  Engine.Input,
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Engine.Math.Collision3D,
  Engine.Mesh,
  Engine.Animation,
  Engine.Network,
  Engine.Network.RPC,
  Engine.ParticleEffects,
  Engine.Script,
  Engine.Serializer,
  Engine.Serializer.Json,
  Engine.Terrain,
  Engine.PostEffects,
  {$IFDEF DEBUG}
  Engine.GUI.Editor,
  Engine.Terrain.Editor,
  {$ENDIF}
  Engine.AnimatedBackground,
  Engine.DataQuery,
  Engine.dXML,
  Engine.Vertex,
  Engine.Preloader,
  Engine.Debug,
  // ---------- Game ----------
  BaseConflict.Game,
  BaseConflict.Game.Client,
  BaseConflict.Classes.MiniMap,
  BaseConflict.Classes.Client,
  BaseConflict.Classes.Gamestates.GUI,
  BaseConflict.Entity,
  BaseConflict.Map,
  BaseConflict.Map.Client,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Constants.Scenario,
  BaseConflict.Globals,
  BaseConflict.Globals.Client,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Client,
  BaseConflict.Settings.Client,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Client,
  BaseConflict.EntityComponents.Client.Debug,
  BaseConflict.EntityComponents.Client.Visuals,
  BaseConflict.EntityComponents.Client.GUI,
  BaseConflict.Api,
  BaseConflict.Api.Account,
  BaseConflict.Api.Cards,
  BaseConflict.Api.Chat,
  BaseConflict.Api.Types,
  BaseConflict.Api.Scenarios,
  BaseConflict.Api.Matchmaking,
  BaseConflict.Api.Messages,
  BaseConflict.Api.Profile,
  BaseConflict.Api.Shop,
  BaseConflict.Api.Quests,
  BaseConflict.Api.Deckbuilding,
  BaseConflict.Api.Shared,
  BaseConflict.Api.Game;

type
  /// //////////////////////////////////////////////////////////////////////////
  /// Helper classes
  /// //////////////////////////////////////////////////////////////////////////

  TGameForm = class(TForm)
    public
      CursorInRenderpanel : Boolean;
  end;

  /// //////////////////////////////////////////////////////////////////////////
  /// Meta classes for gamestates
  /// //////////////////////////////////////////////////////////////////////////

  {$M+}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished, vcPrivate]) PROPERTIES([vcPublic, vcPublished, vcPrivate]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  TGameState = class;
  TGameStateManager = class;

  /// <summary> A game state component is a reusable part of a game state, such as a setting view.
  /// There are passive game state components, which are always active and can be used at the same time
  /// with other components like the chatsystem. </summary>
  TGameStateComponent = class abstract(TEntityComponent)
    protected
      FParent : TGameState;
      FActive, FPassive, FDefault, FInitialized : Boolean;
      property IsInitialized : Boolean read FInitialized;
      property IsDefault : Boolean read FDefault;
      procedure Initialize; virtual;
      function GetActive : Boolean;
      procedure SetActive(const Value : Boolean);
      /// <summary> Will only be called if IsInitialized. </summary>
      procedure GUIEventHandler(const Sender : RGUIEvent); virtual;
      procedure OnQueueError(ErrorCode : EnumErrorCode); virtual;
    public
      /// <summary> The gamestate which this component is attached to. </summary>
      property Parent : TGameState read FParent;
      /// <summary> Determines whether this component has the user focus at the moment.
      /// Passive components are always active. </summary>
      property Active : Boolean read GetActive;
      /// <summary> Activates this component, deactivating all other active and not passive components. </summary>
      procedure Activate; virtual;
      /// <summary> Deactivates this component. </summary>
      procedure Deactivate; virtual;
      /// <summary> Called when the parent TGameState has been entered. </summary>
      procedure ParentEntered; virtual;
      /// <summary> Called when the parent TGameState has been left. </summary>
      procedure ParentLeft; virtual;
      /// <summary> Creates a new game state component attached to a gamestate. </summary>
      constructor Create(Owner : TEntity; Parent : TGameState; IsDefault : Boolean = False); reintroduce;
      /// <summary> Called each frame. Regardless of active or not. </summary>
      procedure Idle; virtual;
  end;

  CGameStateComponent = class of TGameStateComponent;

  /// <summary> This class covers a large state of the game, such as Login, Mainmenu, Loading, Ingame.
  /// A gamestate can have some components to be juiced up with functionality. </summary>
  TGameState = class
    protected
      FOwner : TGameStateManager;
      FStateEntity : TEntity;
      FComponents : TList<TGameStateComponent>;
      /// <summary> Adds a new game state component to this gamestate. Called by components. </summary>
      procedure AddGameStateComponent(Component : TGameStateComponent);
      procedure EnterState; virtual;
      /// <summary> If this is active, it will be idled. </summary>
      procedure Idle; virtual;
      procedure LeaveState; virtual;
      /// <summary> Distributes GUI events to active GamestateComponents. </summary>
      procedure GUIEventHandlerRecursion(const Sender : RGUIEvent);
      /// <summary> Override this to manage the gui events. </summary>
      procedure GUIEventHandler(const Sender : RGUIEvent); virtual;
      procedure OnQueueError(ErrorCode : EnumErrorCode); virtual;
    public
      property Owner : TGameStateManager read FOwner;
      constructor Create(Owner : TGameStateManager);
      /// <summary> Activates one component and deactivates the rest. Called by components. </summary>
      procedure SetComponentActive(Component : CGameStateComponent; Disable : Boolean = False);
      function GetComponent<T : TGameStateComponent>() : T;
      destructor Destroy; override;
  end;

  EnumDialogIdentifier = (
    diNone,
    // passive
    diPassiveDialogs,

    diAscension,
    diCardDetails,
    diCollectionCardDetail,
    diDeckCardSkin,
    diDeckDelete,
    diDeckIcon,
    diDeckslotPurchase,
    diFeedback,
    diFriendInvite,
    diMatchmakingScenario,
    diMatchmakingScenarioDifficulty,
    diPlayerIcon,
    diReferAFriend,
    diSettings,
    diShopItem,
    diShopPurchase,
    // exclusive
    diActiveDialogs,

    diPreloading,
    diGenericLoading,
    diIdleLegions,
    diTutorialVideos,
    diStatisticsLoading,
    diPlayerLevelUpOverview,
    diPlayerLevelUp,
    diRanking,
    diDraftbox,
    diNotification,
    diMatchmakingDeck,
    diMetaTutorial
    );

  SetDialogIdentifier = set of EnumDialogIdentifier;

  ProcDialogVisibilityChanged = procedure(Visible : Boolean) of object;

  TDialogManager = class
    private
      const
      PASSIVE_DIALOGS   = [diPassiveDialogs .. diActiveDialogs];
      SOUNDLESS_DIALOGS = [diPreloading];
    var
      // dialog changes are deferred one frame to prevent inframe callings of dialogs and so sounds playing
      FDirty : SetDialogIdentifier;
      FOpenDialogs : SetDialogIdentifier;
      FCallbacks : array [EnumDialogIdentifier] of TList<ProcDialogVisibilityChanged>;
      procedure Notify(DialogIdentifier : EnumDialogIdentifier; Open : Boolean);
      procedure UpdateShownDialog;
      procedure SetDirty(DialogIdentifiers : SetDialogIdentifier);
    strict private
      FShownDialog : EnumDialogIdentifier;
      procedure SetShownDialog(const Value : EnumDialogIdentifier); virtual;
    published
      property ShownDialog : EnumDialogIdentifier read FShownDialog write SetShownDialog;
      [dXMLDependency('.ShownDialog')]
      function IsAnyDialogVisible : Boolean;
    public
      [dXMLDependency('.ShownDialog')]
      function IsDialogVisible(DialogIdentifier : EnumDialogIdentifier) : Boolean;

      procedure OpenDialog(DialogIdentifier : EnumDialogIdentifier);
      procedure CloseDialog(DialogIdentifier : EnumDialogIdentifier);
      procedure ToggleDialog(DialogIdentifier : EnumDialogIdentifier);
      procedure BindDialog(DialogIdentifier : EnumDialogIdentifier; Open : Boolean);
      procedure CloseAllDialogs;
      procedure Subscribe(DialogIdentifier : EnumDialogIdentifier; Callback : ProcDialogVisibilityChanged);
      procedure UnSubscribe(DialogIdentifier : EnumDialogIdentifier; Callback : ProcDialogVisibilityChanged);

      procedure Idle;
      destructor Destroy; override;
  end;

  EnumClientState = (csNone, csMainMenu, csCoreGame, csLoadCoreGame, csLoginQueue, csLoginSteam, csReconnect, csServerDown, csMaintenance);
  EnumMenuMusic = (mmNone, mmIntro, mmMenu, mmDeckbuilding, mmLoading);
  EnumWebsites = (weGame, weCompany, weFMod, weDiscord, weYoutube, weTwitter, weFacebook, wePatchNotes, weWiki, weTranslation, wePublisher, weGuide, weSteamForum, weScill, weScillTournament, weTournament, weSteamChat);
  EnumWindowMode = (wmClient, wmIngame);

  /// <summary> This is the global manager of the game, which handles all gamestates. </summary>
  TGameStateManager = class
    protected
      FOnShutdown : ProcCallback;
      FCurrentState : string;
      FCurrentStates : TStack<TGameState>;
      FStates : TObjectDictionary<string, TGameState>;
      FGameWindow : TGameForm;
      FWindowMode : EnumWindowMode;
      FWindowInitialized, FAllowClose : Boolean;
      FLastClickable : integer;
      FMenuMusicEvent : TFMODEventInstance;
      FCurrentMenuMusic : EnumMenuMusic;
      FClientWarmingSteps : integer;

      property GameWindow : TGameForm read FGameWindow;

      function GetIsStaging : Boolean;
      function GetGameState<T : TGameState>(const GameStateName : string) : T;
      function CurrentGameState : TGameState;
      /// <summary> Redirect GUI events to the current game state. </summary>
      procedure GUIEventCallback(const Sender : RGUIEvent);
      procedure OnQueueError(ErrorCode : EnumErrorCode);
    strict private
      FErrorCaption, FErrorMessage, FLoadingCaption, FLoadingMessage, FErrorConfirm : string;
      FExitDialogVisible, FIsErrorDialogOpen, FIsLoading : Boolean;
      FIsApiReady : Boolean;
      FClientState : EnumClientState;
      FDialogManager : TDialogManager;
      procedure SetDialogManager(const Value : TDialogManager); virtual;
      procedure SetErrorConfirm(const Value : string); virtual;
      procedure SetLoadingCaption(const Value : string); virtual;
      procedure SetLoadingMessage(const Value : string); virtual;
      procedure SetClientState(const Value : EnumClientState); virtual;
      procedure SetIsLoading(const Value : Boolean); virtual;
      procedure SetIsApiReady(const Value : Boolean); virtual;
      procedure SetExitDialogVisible(const Value : Boolean); virtual;
      procedure SetIsErrorDialogOpen(const Value : Boolean); virtual;
      procedure SetErrorCaption(const Value : string); virtual;
      procedure SetErrorMessage(const Value : string); virtual;
    published
      property State : EnumClientState read FClientState write SetClientState;
      property ExitDialogVisible : Boolean read FExitDialogVisible write SetExitDialogVisible;
      property IsStaging : Boolean read GetIsStaging;

      property ErrorCaption : string read FErrorCaption write SetErrorCaption;
      property ErrorMessage : string read FErrorMessage write SetErrorMessage;
      property ErrorConfirm : string read FErrorConfirm write SetErrorConfirm;
      property IsErrorDialogOpen : Boolean read FIsErrorDialogOpen write SetIsErrorDialogOpen;
      procedure ShowErrorConfirm(const ErrorCaption, ErrorMessage, ErrorConfirm : string);
      procedure ShowError(const ErrorCaption, ErrorMessage : string);
      procedure ShowErrorcodeRaw(ErrorCode : integer);
      procedure ShowErrorcode(ErrorCode : EnumErrorCode);

      property IsApiReady : Boolean read FIsApiReady write SetIsApiReady;
      property IsLoading : Boolean read FIsLoading write SetIsLoading;
      property LoadingCaption : string read FLoadingCaption write SetLoadingCaption;
      property LoadingMessage : string read FLoadingMessage write SetLoadingMessage;

      property DialogManager : TDialogManager read FDialogManager write SetDialogManager;

      procedure Close;
      procedure CloseForcePrompt;
      procedure CloseNoPrompt;
      procedure Minimize;

      procedure BrowseTo(Website : EnumWebsites);
    public const
      CLIENT_DEFAULT_DIMENSIONS : RIntVector2 = (X : 1280; Y : 720);
    public
      property OnShutdown : ProcCallback read FOnShutdown write FOnShutdown;
      /// <summary> The last state pushed by changegamestate. </summary>
      property CurrentState : string read FCurrentState;
      /// <summary> Allocate memory and prepare instance for use.</summary>
      constructor Create(GameWindow : TGameForm);
      /// <summary> Add new gamestate to list and make them available for use.
      /// This will not activate the new state!</summary>
      procedure AddNewGameState(GameState : TGameState; GameStateName : string);
      procedure RemoveGameState(GameStateName : string);
      /// <summary> Creates all api managers. </summary>
      procedure CreateManager;
      /// <summary> Frees all api managers. </summary>
      procedure CleanManager;
      procedure SwitchMenuMusic(NewMusic : EnumMenuMusic);
      /// <summary> Returns whether the application can be closed. </summary>
      function CanProgramClose : Boolean;
      function IsWindowMode(WindowMode : EnumWindowMode) : Boolean;
      function IsGameWindow : Boolean;
      function IsClientWindow : Boolean;
      function IsFullscreen : Boolean;
      procedure SetClientWindow;
      procedure SetIngameWindow;
      function TargetMonitor : TMonitor;
      procedure UpdateWindowPosition;
      procedure BringToFront;
      procedure ShowWindow;
      procedure HideWindow;
      procedure UpdateSoundSettings(Option : EnumClientOption = coGeneralNone);
      procedure UpdateSettingsOption(Option : EnumClientOption);
      /// <summary> Will change the current gamestate to gamestate with given name.
      /// Change gamestate will leave and pop all current stacked states
      /// The new gamestate has to be registered before use.</summary>
      procedure ChangeGameState(GameStateName : string);
      /// <summary> Idle all gamestates current on stack</summary>
      procedure Idle;
      /// <summary> Free allocated memory and free all added gamestates!</summary>
      destructor Destroy; override;
  end;

  /// ////////////////////////////////////////////////////////////////////
  /// Implemented gamestate components
  /// //////////////////////////////////////////////////////////////////////////
  EnumScenario = (esNone, es1vE, es2vE, es1v1, es2v2, es3v3, es4v4, esRanked1v1, esRanked2v2, esDuel, esDuel2v2, esDuel3v3, esDuel4v4, esTutorial, esSpecial);
  SetScenario = set of EnumScenario;

  /// <summary> Manages the process to start a game: Gamemode, Teambuilding/planning, Queue </summary>
  TGameStateComponentMatchMaking = class(TGameStateComponent)
    private
      const
      SCENARIO_MAPPING : array [EnumScenario] of string = (
        '',                              // esNone
        SCENARIO_PVE_ATTACK_SOLO,        // es1vE
        SCENARIO_PVE_ATTACK_DUO,         // es2vE
        SCENARIO_PVP_1VS1,               // es1v1
        SCENARIO_PVP_2VS2,               // es2v2
        SCENARIO_PVP_3VS3_TWO_LANE,      // es3v3
        SCENARIO_PVP_4VS4_TWO_LANE,      // es4v4
        SCENARIO_PVP_1VS1_RANKED,        // esRanked1v1
        SCENARIO_PVP_2VS2_RANKED,        // esRanked2v2
        SCENARIO_PVP_DUEL_1VS1,          // esDuel
        SCENARIO_PVP_DUEL_2VS2,          // esDuel2v2
        SCENARIO_PVP_DUEL_3VS3_TWO_LANE, // esDuel3v3
        SCENARIO_PVP_DUEL_4VS4_TWO_LANE, // esDuel4v4
        SCENARIO_PVE_TUTORIAL,           // esTutorial
        SCENARIO_PVE_DEFAULT             // esSpecial
        );
      SCENARIOS_WITH_AUTO_LEAGUE : SetScenario        = [es1v1, es2v2, es3v3, es4v4, esRanked1v1, esRanked2v2];
      SCENARIOS_WITH_LEAGUE_SELECTION : SetScenario   = [es1vE, es2vE, esDuel, esDuel2v2, esDuel3v3, esDuel4v4, esSpecial];
      SCENARIOS_WITH_SCENARIO_SELECTION : SetScenario = [esDuel, esDuel2v2, esDuel3v3, esDuel4v4, esSpecial];
      SCENARIOS_AGAINST_AI : SetScenario              = [es1vE, es2vE, esSpecial];
      SCENARIOS_DUEL : SetScenario                    = [esDuel, esDuel2v2, esDuel3v3, esDuel4v4];
      CURRENT_PLAYER_ONLINE_UPDATE_INTERVAL_QUEUE     = 1000;
      ENTER_QUEUE_BLOCK_TIMEROUT                      = 5000;
      MAINTENANCE_LEAVE_QUEUE_INTERVAL                = 5000;
    protected
      FCurrentPlayerUpdateTimer, FEnterQueueBlockTimeout, FMaintenanceLeaveQueueTimer : TTimer;
      FMatchmakingTeamAlreadyReset : Boolean;
      procedure Initialize; override;
      procedure OnQueueError(ErrorCode : EnumErrorCode); override;
      procedure OnGameFound(Game : TGameMetaInfo);
      procedure OnQueueEntered(Sender : TMatchmakingTeam; Queue : TMatchmakingQueue);
      procedure OnQueueLeft(Sender : TMatchmakingQueue; Leaver : TPerson);
      procedure OnServerQueueError;
      procedure OnScenarioChanged;
      procedure SanitizeGameData(Game : TGameMetaInfo);
      procedure UpdateScenarioSelection;
      function GetScenario(PredefinedScenario : EnumScenario) : TScenario;
      function GetEnumScenario(Scenario : TScenario) : EnumScenario;
    strict private
      // general
      function GetScenarioManager : TScenarioManager;
      procedure SetScenarioManager(const Value : TScenarioManager); virtual;
      function GetManager : TMatchmakingManager;
      procedure SetManager(const Value : TMatchmakingManager); virtual;
    strict private
      // team
      FScenarios : TUltimateList<TScenario>;
      FChosenScenario : EnumScenario;
      FLastChosenDifficulty : integer;
      procedure SetChosenScenario(const Value : EnumScenario); virtual;
    strict private
      // queue
      FInQueue : Boolean;
      FQueue : TMatchmakingQueue;
      FIsEnteringQueue : Boolean;
      procedure SetIsEnteringQueue(const Value : Boolean); virtual;
      procedure SetInQueue(const Value : Boolean); virtual;
      procedure SetQueue(const Value : TMatchmakingQueue); virtual;
    published
      // general
      property Manager : TMatchmakingManager read GetManager write SetManager;
      property Scenarios : TScenarioManager read GetScenarioManager write SetScenarioManager;
      property ScenarioSelection : TUltimateList<TScenario> read FScenarios;
      // scenario
      property ChosenScenario : EnumScenario read FChosenScenario write SetChosenScenario;
      [dXMLDependency('.ChosenScenario')]
      function HasAutoLeague : Boolean;
      [dXMLDependency('.ChosenScenario')]
      function HasLeagueSelection : Boolean;
      [dXMLDependency('.ChosenScenario')]
      function HasScenarioSelection : Boolean;
      [dXMLDependency('.ChosenScenario')]
      function IsDuel : Boolean;
      [dXMLDependency('.ChosenScenario')]
      function IsPvE : Boolean;
      [dXMLDependency('.Scenarios.Scenarios', '.Scenarios.Rankings')]
      function Ranked1vs1 : TScenarioInstance;
      [dXMLDependency('.Scenarios.Scenarios', '.Scenarios.Rankings')]
      function Ranked2vs2 : TScenarioInstance;
      // team
      [dXMLDependency('.Manager.CurrentTeam.Invites')]
      function PendingInvites : integer;
      procedure ChooseScenarioInstance(const ScenarioInstance : TScenarioInstance);
      procedure ChooseScenario(const Scenario : TScenario);
      // queue
      property IsEnteringQueue : Boolean read FIsEnteringQueue write SetIsEnteringQueue;
      property InQueue : Boolean read FInQueue write SetInQueue;
      property Queue : TMatchmakingQueue read FQueue write SetQueue;
      procedure EnterQueue;
      procedure LeaveQueue;
      // tutorial
      procedure StartTutorialGame;
      // spectate
      procedure SpectateFriend(Friend : TPerson);
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      procedure Idle; override;
      destructor Destroy; override;
  end;

  /// <summary> Manages the after game party. </summary>
  TGameStateComponentStatistics = class(TGameStateComponent)
    protected
      FIdleTimer : TTimer;
      FOldGameData : TGameMetaInfo;
      procedure OnDataReady;
      procedure Initialize; override;
    strict private
      FIsIdleBlocked : Boolean;
      FIdleTimerBlock : integer;
      procedure SetIsIdleBlocked(const Value : Boolean); virtual;
      procedure SetIdleTimerBlock(const Value : integer); virtual;
      function GetGameData : TGameMetaInfo;
      procedure SetGameData(const Value : TGameMetaInfo); virtual;
    published
      property GameData : TGameMetaInfo read GetGameData write SetGameData;
      // idle legions
      property IsIdleBlocked : Boolean read FIsIdleBlocked write SetIsIdleBlocked;
      property IdleTimerBlock : integer read FIdleTimerBlock write SetIdleTimerBlock;
      procedure ClearGameData;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      /// <summary> NILSAFE | Loads the new game data. </summary>
      procedure Show;
      procedure Idle; override;
      destructor Destroy; override;
  end;

  EnumGraphicsQuality = (gqVeryLow, gqLow, gqMedium, gqHigh, gqVeryHigh, gqCustom);
  EnumShadowQuality = (sqOff, sqVeryLow, sqLow, sqMedium, sqHigh, sqUltraHigh);
  EnumTextureQuality = (tqMaximum, tqHigh, tqMedium, tqLow, tqMinimum);
  EnumClickPrecision = (cpPrecise, cpExtended, cpWide);
  EnumDisplayMode = (dmBorderlessFullscreenWindow, dmWindowed);
  EnumMenuResolution = (mr1024x576, mr1280x720, mr1600x900, mr1920x1080, mr2560x1440, mrCustom);
  EnumMenuScaling = (msDownscaling, msFullscreen, msDisabled);

  TSettingsWrapper = class
    strict private
      FBlockUpdate : integer;
    protected const
      GRAPHICS_PRESET_SHADOW_QUALITY : array [gqVeryLow .. gqVeryHigh] of EnumShadowQuality =
        (sqOff, sqLow, sqMedium, sqHigh, sqUltraHigh);
      GRAPHICS_PRESET_ACTIVE_OPTIONS_VERY_LOW = [];
      GRAPHICS_PRESET_ACTIVE_OPTIONS_LOW      = GRAPHICS_PRESET_ACTIVE_OPTIONS_VERY_LOW + [coGraphicsPostEffectFXAA];
      GRAPHICS_PRESET_ACTIVE_OPTIONS_MEDIUM   = GRAPHICS_PRESET_ACTIVE_OPTIONS_LOW + [coGraphicsGUIBlurBackgrounds,
        coGraphicsPostEffectGlow, coGraphicsPostEffectUnsharpMasking, coGraphicsPostEffectDistortion];
      GRAPHICS_PRESET_ACTIVE_OPTIONS_HIGH      = GRAPHICS_PRESET_ACTIVE_OPTIONS_MEDIUM + [coGraphicsDeferredShading, coGraphicsPostEffectToon];
      GRAPHICS_PRESET_ACTIVE_OPTIONS_VERY_HIGH = GRAPHICS_PRESET_ACTIVE_OPTIONS_HIGH + [coGraphicsPostEffectSSAO];
      MENU_RESOLUTIONS : array [EnumMenuResolution] of RIntVector2 =
        ((X : 1024; Y : 576),
        (X : 1280; Y : 720),
        (X : 1600; Y : 900),
        (X : 1920; Y : 1080),
        (X : 2560; Y : 1440),
        (X : 0; Y : 0));
    protected
      /// <summary> Reads properties from settings. </summary>
      procedure Refresh;
      /// <summary> Publishes settings to GUI. </summary>
      procedure Sync;
      procedure DetermineMenuResolution;
      procedure DetermineShadowQualityFromSettings;
      procedure DetermineGraphicsQualityFromSettings(Sync : Boolean = False);
      procedure DetermineCurrentLanguage;
      procedure BeginUpdate;
      procedure EndUpdate;
    strict private
      FShadowQuality : EnumShadowQuality;
      FTextureQuality : EnumTextureQuality;
      FHealthbarMode : EnumHealthbarMode;
      FDropZoneMode : EnumDropZoneMode;
      FClickPrecision : EnumClickPrecision;
      FGraphicsQuality : EnumGraphicsQuality;
      FDisplayMode : EnumDisplayMode;
      FMenuResolution : EnumMenuResolution;
      FMenuScaling : EnumMenuScaling;
      FAvailableLanguages : TUltimateList<RSteamLanguage>;
      FCurrentLanguage : RSteamLanguage;
      procedure SetCurrentLanguage(const Value : RSteamLanguage); virtual;
      procedure SetAvailableLanguages(const Value : TUltimateList<RSteamLanguage>); virtual;
      procedure SetMenuScaling(const Value : EnumMenuScaling); virtual;
      procedure SetMenuResolution(const Value : EnumMenuResolution); virtual;
      procedure SetDisplayMode(const Value : EnumDisplayMode); virtual;
      procedure SetGraphicsQuality(const Value : EnumGraphicsQuality); virtual;
      procedure SetClickPrecision(const Value : EnumClickPrecision); virtual;
      procedure SetDropZoneMode(const Value : EnumDropZoneMode); virtual;
      procedure SetTextureQuality(const Value : EnumTextureQuality); virtual;
      procedure SetHealthbarMode(const Value : EnumHealthbarMode); virtual;
      procedure SetShadowQuality(const Value : EnumShadowQuality); virtual;
    strict private
      FKeyToBind : EnumKeybinding;
      FNewKeybinding : RBinding;
      FNewKeybindingIndex : integer;
      FBindableKeys : TUltimateList<EnumKeybinding>;
      procedure SetNewKeybinding(const Value : RBinding); virtual;
      procedure SetKeyToBind(const Value : EnumKeybinding); virtual;
    published
      property GraphicsQuality : EnumGraphicsQuality read FGraphicsQuality write SetGraphicsQuality;
      property TextureQuality : EnumTextureQuality read FTextureQuality write SetTextureQuality;
      property DisplayMode : EnumDisplayMode read FDisplayMode write SetDisplayMode;
      property ShadowQuality : EnumShadowQuality read FShadowQuality write SetShadowQuality;
      property HealthBarMode : EnumHealthbarMode read FHealthbarMode write SetHealthbarMode;
      property DropZoneMode : EnumDropZoneMode read FDropZoneMode write SetDropZoneMode;
      property ClickPrecision : EnumClickPrecision read FClickPrecision write SetClickPrecision;
      property MenuResolution : EnumMenuResolution read FMenuResolution write SetMenuResolution;
      property MenuScaling : EnumMenuScaling read FMenuScaling write SetMenuScaling;

      property AvailableLanguages : TUltimateList<RSteamLanguage> read FAvailableLanguages write SetAvailableLanguages;
      property CurrentLanguage : RSteamLanguage read FCurrentLanguage write SetCurrentLanguage;

      property BindableKeys : TUltimateList<EnumKeybinding> read FBindableKeys;
      property KeyToBind : EnumKeybinding read FKeyToBind write SetKeyToBind;
      property NewBinding : RBinding read FNewKeybinding write SetNewKeybinding;
      [dXMLDependency('.KeyToBind')]
      function KeyToBindString : string;
      [dXMLDependency('.NewBinding')]
      function IsRebindValid : Boolean;
      procedure RebindKey(Key : EnumKeybinding; Alt : Boolean);
      procedure DeleteKey(Key : EnumKeybinding; Alt : Boolean);
      procedure ApplyRebinding;
      procedure CancelRebinding;

      procedure RevertCategory(Category : EnumOptionType);
    public
      constructor Create;

      function GetBoolean(Option : EnumClientOption) : Boolean;
      procedure SetBoolean(Option : EnumClientOption; Value : Boolean);
      function GetInteger(Option : EnumClientOption) : integer;
      procedure SetInteger(Option : EnumClientOption; Value : integer);

      function GetKeybinding(Binding : EnumKeybinding) : RBinding;
      function GetAltKeybinding(Binding : EnumKeybinding) : RBinding;

      class procedure WriteShadowQualityToSettings(const Value : EnumShadowQuality);
      class procedure WriteGraphicsQualityToSettings(const Value : EnumGraphicsQuality);

      procedure Idle;

      destructor Destroy; override;
  end;

  RFPSLogData = record
    Timestamp : int64;
    FPS : integer;
  end;

  /// <summary> Manages the settings menu. Used in mainmenu and ingame. </summary>
  TGameStateComponentSettings = class(TGameStateComponent)
    protected
      FSettings : TSettingsWrapper;
      procedure Initialize; override;
      procedure OnDialogOpen(Open : Boolean);
    published
      [XEvent(eiClientOption, epLast, etTrigger, esGlobal)]
      function OnClientOption(ChangedOption : RParam) : Boolean;
    strict private
      FCategory : EnumOptionType;
      procedure SetCategory(const Value : EnumOptionType); virtual;
    published
      property Category : EnumOptionType read FCategory write SetCategory;

      procedure DeactivateAndSaveSettings;
      procedure DeactivateAndDiscardSettings;
    public
      constructor Create(Owner : TEntity; Parent : TGameState);

      procedure ParentEntered; override;
      procedure ParentLeft; override;

      procedure Idle; override;

      destructor Destroy; override;
  end;

  /// <summary> Manages the feedback form in the alpha. </summary>
  TGameStateComponentFeedback = class(TGameStateComponent)
    protected
      procedure Initialize; override;
    strict private
      FFeedback : string;
    published
      procedure SetFeedback(const Value : string); virtual;
      property Feedback : string read FFeedback write SetFeedback;
      procedure SendFeedback;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      constructor Create(Owner : TEntity; Parent : TGameState);
      destructor Destroy; override;
  end;

  /// <summary> Manages the inventory (Lootboxes, etc.) of the user. </summary>
  TGameStateComponentInventory = class(TGameStateComponent)
    protected
      FLastDraftbox : TDraftbox;
      procedure Initialize; override;
      procedure OnDraftboxOpen(Open : Boolean);
      procedure UpdateDraftboxDialog(CurrentDraftBox : TDraftbox);
    strict private
      FLootbox : TLootbox;
      FChosenDraftBoxChoice : TDraftBoxChoice;
      FOpenedBoosterPack : TLootbox;
      procedure SetOpenedBoosterPack(const Value : TLootbox); virtual;
      function GetShop : TShop;
      procedure SetChosenDraftBoxChoice(const Value : TDraftBoxChoice); virtual;
      procedure SetLootbox(const Value : TLootbox); virtual;
    published
      property Shop : TShop read GetShop;
      property Lootbox : TLootbox read FLootbox write SetLootbox;
      [dXMLDependency('.Lootbox')]
      function IsLootboxVisible : Boolean;
      procedure ShowLootbox(const Lootbox : TLootbox);
      procedure HideLootbox;
      // Draft boxes
      [dXMLDependency('.Draftbox')]
      function HasDraftbox : Boolean;
      [dXMLDependency('.Shop.Inventory.Opened')]
      function Draftbox : TDraftbox;
      property ChosenDraftBoxChoice : TDraftBoxChoice read FChosenDraftBoxChoice write SetChosenDraftBoxChoice;
      procedure Draft;
      // Booster packs
      [dXMLDependency('.Shop.Inventory.Opened')]
      function NextBoosterPack : TLootbox;
      [dXMLDependency('.Shop.Inventory.Opened')]
      function BoosterPackCount : integer;
      property OpenedBoosterPack : TLootbox read FOpenedBoosterPack write SetOpenedBoosterPack;
      procedure OpenNextBoosterPack;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  /// <summary> Manages the deckbuilding. </summary>
  TGameStateComponentDeckbuilding = class(TGameStateComponent)
    protected
      procedure Initialize; override;
      procedure ApplyFilters;
      procedure OnPlayerCardsChange(Sender : TUltimateList<TCardInstance>; Item : TArray<TCardInstance>; Action : EnumListAction; Indices : TArray<integer>);
    strict private// global
      function GetShop : TShop;
      procedure SetShop(const Value : TShop); virtual;
      function GetDeckManager : TDeckManager;
      procedure SetDeckManager(const Value : TDeckManager); virtual;
      function GetCardManager : TCardManager;
      procedure SetCardManager(const Value : TCardManager); virtual;
    strict private// decklist
      FDeckToDelete : TDeck;
      procedure SetDeckToDelete(const Value : TDeck); virtual;
      function GetDecklist : TUltimateList<TDeck>;
    strict private// deckeditor
      FNewDeckName : string;
      FEditedDeck : TDeck;
      FDeckCard : TDeckCard;

      FGridSize : integer;
      FCardpoolCards : TUltimateList<TCardInstance>;
      FCardpool : TPaginator<TCardInstance>;
      FCardpoolFilter : TPaginatorCardFilter<TCardInstance>;

      FSacrificeGridSize : integer;
      FCardInstanceWithRewards : TCardInstanceWithRewards;
      FSacrificeList, FSacrificePoolCards, FSacrificePoolCurrentObjects : TUltimateList<TCardInstance>;
      FSacrificePool : TPaginator<TCardInstance>;
      procedure UpdateSacrificePool;
      procedure UpdateCardDetails;
      procedure SetSacrificePool(const Value : TPaginator<TCardInstance>); virtual;
      procedure AscendRaw(WithCrystals : Boolean);

      procedure SetDeckCard(const Value : TDeckCard); virtual;
      procedure SetCardInstanceWithRewards(const Value : TCardInstanceWithRewards); virtual;

      procedure SetEditedDeck(const Value : TDeck); virtual;
      procedure SetNewDeckName(const Value : string); virtual;

      procedure SetGridSize(const Value : integer); virtual;
      procedure SetCardPool(const Value : TPaginator<TCardInstance>); virtual;
      procedure SetCardpoolCards(const Value : TUltimateList<TCardInstance>); virtual;
      procedure SetCardPoolFilter(const Value : TPaginatorCardFilter<TCardInstance>); virtual;
    published
      property Shop : TShop read GetShop write SetShop;
      property DeckManager : TDeckManager read GetDeckManager write SetDeckManager;
      property CardManager : TCardManager read GetCardManager write SetCardManager;

      // decklist ------------------------------------------------------------------------------------------------
      property DeckToDelete : TDeck read FDeckToDelete write SetDeckToDelete;
      property Decks : TUltimateList<TDeck> read GetDecklist;
      procedure EditDeck(Deck : TDeck);
      procedure AddDeck;
      procedure PrepareDeleteDeck(Deck : TDeck);
      procedure DeletePreparedDeck;

      // deckeditor ----------------------------------------------------------------------------------------------
      property Deck : TDeck read FEditedDeck write SetEditedDeck;
      procedure AddCard(const CardInstance : TCardInstance);
      procedure CloseIfInDeckeditor;

      // deck card skin
      property DeckCard : TDeckCard read FDeckCard write SetDeckCard;
      procedure ChooseSkin(const Skin : TCardSkin);

      // deckname
      property NewDeckName : string read FNewDeckName write SetNewDeckName;
      procedure SaveNewDeckName;
      procedure CancelNewDeckName;

      // choose deckicon dialog
      procedure ChooseDeckIcon(const IconUID : string);

      // cardpool
      property GridSize : integer read FGridSize write SetGridSize;
      property CardpoolCurrentObjects : TUltimateList<TCardInstance> read FCardpoolCards write SetCardpoolCards;
      property Cardpool : TPaginator<TCardInstance> read FCardpool write SetCardPool;
      property CardpoolFilter : TPaginatorCardFilter<TCardInstance> read FCardpoolFilter write SetCardPoolFilter;
      procedure ResetFilter;

      /// <summary> The card shown in the detailview. </summary>
      property Card : TCardInstanceWithRewards read FCardInstanceWithRewards write SetCardInstanceWithRewards;
      procedure ShowCardDetails(const Card : TCardInstance);
      procedure CloseCardDetails;
      property SacrificeList : TUltimateList<TCardInstance> read FSacrificeList;
      [dXMLDependency('.Card', '.SacrificeList')]
      function SacrificeListValue : integer;
      [dXMLDependency('.Card', '.SacrificeList')]
      function SacrificeListExperienceValue : integer;
      property SacrificePoolCurrentObjects : TUltimateList<TCardInstance> read FSacrificePoolCurrentObjects;
      property SacrificePool : TPaginator<TCardInstance> read FSacrificePool write SetSacrificePool;
      procedure PickMaterial(Card : TCardInstance);
      procedure RemoveMaterial(Card : TCardInstance);
      [dXMLDependency('.Card', '.SacrificeList')]
      function AscensionCreditCost : RCost;
      [dXMLDependency('.Card', '.SacrificeList')]
      function AscensionCrystalCost : RCost;
      [dXMLDependency('.Card.CardInstance.IsLeagueUpgradable', '.AscensionCreditCost')]
      function CanAscendWithSacrificeList : Boolean;
      [dXMLDependency('.Shop.Balances', '.Card.CardInstance.IsLeagueUpgradable', '.AscensionCreditCost')]
      function CanAscendWithCredits : Boolean;
      [dXMLDependency('.Shop.Balances', '.Card.CardInstance.IsLeagueUpgradable', '.AscensionCost')]
      function CanAscendWithCrystals : Boolean;
      procedure Ascend;
      procedure AscendWithCredits;
      procedure AscendWithCrystals;

      procedure PushCardXP;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  EnumPurchaseState = (psNone, psProcessing, psSuccess, psAborted, psFailed);

  /// <summary> Manages the shop in the main menu. </summary>
  TGameStateComponentShop = class(TGameStateComponent)
    protected
      procedure Initialize; override;
      procedure ApplyFilters;
      procedure OnGainReward(Rewards : TArray<RReward>);
      procedure OnShopItemsChange(Sender : TUltimateList<TShopItem>; Item : TArray<TShopItem>; Action : EnumListAction; Indices : TArray<integer>);
    strict private
      FChosenShopItem : TShopItem;
      FShopItemList : TUltimateList<TShopItem>;
      FShopItems : TPaginator<TShopItem>;
      FShopItemFilter : TPaginatorShopFilter<TShopItem>;
      FPurchaseState : EnumPurchaseState;
      FBonuscode : string;
      function GetShop : TShop;
      function GetDeckslotShopItemCredits : TShopItem;
      function GetDeckslotShopItemCrystals : TShopItem;
      procedure SetPurchaseState(const Value : EnumPurchaseState); virtual;
      procedure SetChosenShopItem(const Value : TShopItem); virtual;
      procedure SetShop(const Value : TShop); virtual;
      procedure SetShopItems(const Value : TPaginator<TShopItem>); virtual;
      procedure SetShopItemFilter(const Value : TPaginatorShopFilter<TShopItem>); virtual;
    published
      property Shop : TShop read GetShop write SetShop;

      // shop item list
      property ShopItemsCurrentObjects : TUltimateList<TShopItem> read FShopItemList;
      property ShopItems : TPaginator<TShopItem> read FShopItems write SetShopItems;
      property ShopItemFilter : TPaginatorShopFilter<TShopItem> read FShopItemFilter write SetShopItemFilter;
      procedure ResetFilter;

      // shop item selection
      property ChosenShopItem : TShopItem read FChosenShopItem write SetChosenShopItem;
      procedure SelectShopItem(const ShopItem : TShopItem);

      // purchasing
      property PurchaseState : EnumPurchaseState read FPurchaseState write SetPurchaseState;
      procedure BuyOffer(const Offer : TShopItemOffer);
      procedure BuyOfferTimes(const Offer : TShopItemOffer; Times : integer);
      procedure ConfirmPurchaseDialog;

      // bonus code
      procedure SetBonuscode(const Value : string); virtual;
      property Bonuscode : string read FBonuscode write SetBonuscode;
      procedure RedeemBonuscode;

      // first crystal purchase reward
      [dXMLDependency('.Shop.Items.PurchasesCount')]
      function FirstCrystalsBought : Boolean;

      // deckslots
      [dXMLDependency('.Shop.Items', '.Shop.Items.PurchasesCount')]
      property DeckslotShopItemCredits : TShopItem read GetDeckslotShopItemCredits;
      [dXMLDependency('.Shop.Items')]
      property DeckslotShopItemCrystals : TShopItem read GetDeckslotShopItemCrystals;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  EnumNotificationType = (ntNone, ntCardUnlock, ntFriendRequest, ntReward, ntLootlist, ntMessage);

  TGameStateComponentNotification = class;

  TNotification = class abstract
    protected
      FNotificationType : EnumNotificationType;
      FOwner : TGameStateComponentNotification;
      procedure OnShown; virtual;
    published
      property NotificationType : EnumNotificationType read FNotificationType;
    public
      constructor Create(Owner : TGameStateComponentNotification);
  end;

  TNotificationCardUnlock = class(TNotification)
    protected
      procedure OnShown; override;
    strict private
      FCard : TCard;
    published
      property Card : TCard read FCard;
      procedure ToShop;
    public
      constructor Create(Owner : TGameStateComponentNotification; const Card : TCard);
  end;

  TNotificationReward = class(TNotification)
    protected
      procedure OnShown; override;
    strict private
      FRewards : TArray<RReward>;
      FRewardCount : integer;
      FHasWideItems : Boolean;
    published
      property Rewards : TArray<RReward> read FRewards;
      property RewardCount : integer read FRewardCount;
      property HasWideItems : Boolean read FHasWideItems;
    public
      constructor Create(Owner : TGameStateComponentNotification; const Rewards : TArray<RReward>);
  end;

  TNotificationLootlist = class(TNotification)
    protected
      procedure OnShown; override;
    strict private
      FIdentifier : string;
      FStarterDeckColor : EnumEntityColor;
    published
      property Identifier : string read FIdentifier;
      // hacked for now as we are only using lootlists for starterdecks
      property StarterDeckColor : EnumEntityColor read FStarterDeckColor;
    public
      constructor Create(Owner : TGameStateComponentNotification; const Identifier : string);
  end;

  TNotificationFriendRequest = class(TNotification)
    strict private
      FRequester : TPerson;
    published
      // we use the person here, as the TFriendRequest can be freed while notification is still shown
      property Requester : TPerson read FRequester;
    public
      constructor Create(Owner : TGameStateComponentNotification; const Request : TFriendRequest);
  end;

  TNotificationMessage = class(TNotification)
    strict private
      FMessage : TMessage;
    published
      property Msg : TMessage read FMessage;
    public
      constructor Create(Owner : TGameStateComponentNotification; const Msg : TMessage);
  end;

  /// <summary> Manages messages like unlocks sent to the user </summary>
  TGameStateComponentNotification = class(TGameStateComponent)
    protected
      FBlock : integer;
      FBlockTimer : TTimer;
      procedure AddNotification(Notification : TNotification);
      procedure OnNotificationOpen(Open : Boolean);
      procedure OnNewMessage(const Msg : TMessage);
      function IsBlocked : Boolean;
      procedure Initialize; override;
    strict private
      FNotifications : TUltimateObjectList<TNotification>;
    published
      property Notifications : TUltimateObjectList<TNotification> read FNotifications;
      [dXMLDependency('.Notifications')]
      function HasNotification : Boolean;
      [dXMLDependency('.Notifications')]
      function Notification : TNotification;
      procedure Close;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      /// <summary> Blocks the next n notifications. </summary>
      procedure Block(Count : integer);
      procedure BlockForTime(Duration : integer);
      procedure AddCardUnlock(const Card : TCard);
      procedure AddFriendRequest(const Request : TFriendRequest);
      procedure AddRewards(const Rewards : TArray<RReward>);
      procedure AddMessage(const Msg : TMessage);
      destructor Destroy; override;
  end;

  /// <summary> Manages the users dashboard on the first page. </summary>
  TGameStateComponentDashboard = class(TGameStateComponent)
    strict private
      FScillBannerIndex : integer;
      procedure SetScillBannerIndex(const Value : integer); virtual;
    protected
      FBannerChangeTimer : TTimer;
      procedure Initialize; override;
    published
      property ScillBannerIndex : integer read FScillBannerIndex write SetScillBannerIndex;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      procedure Idle; override;
      destructor Destroy; override;
  end;

  /// <summary> Manages the user and his data the main menu. </summary>
  TGameStateComponentProfile = class(TGameStateComponent)
    protected
      procedure Initialize; override;
    strict private
      FTutorialVideoPage : TUltimateList<TTutorialVideo>;
      FTutorialVideoPaginator : TPaginator<TTutorialVideo>;
      procedure SetTutorialVideoPaginator(const Value : TPaginator<TTutorialVideo>); virtual;
    strict private
      FIsTutorialGameDialogOpen : Boolean;
      procedure SetIsTutorialGameDialogOpen(const Value : Boolean); virtual;
      function GetProfile : TUserProfile;
      function GetAccount : TAccount;
    published
      property Account : TAccount read GetAccount;
      property Profile : TUserProfile read GetProfile;

      function CanSpectate : Boolean;

      property IsTutorialGameDialogOpen : Boolean read FIsTutorialGameDialogOpen write SetIsTutorialGameDialogOpen;

      procedure TutorialFinished;
      procedure RedeemStarterDecks;

      // choose playericon dialog
      procedure ChoosePlayerIcon(const IconUID : string);

      property TutorialVideoPage : TUltimateList<TTutorialVideo> read FTutorialVideoPage;
      property TutorialVideoPaginator : TPaginator<TTutorialVideo> read FTutorialVideoPaginator write SetTutorialVideoPaginator;
    public
      function IsTranslationFinished : Boolean;
      function TranslationPercentage : string;
      function TranslationProgress : integer;
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  EnumMetaTutorialStage = (
    mtsNone,
    // finished tutorial match
    mtsStarterdeckWhite,
    mtsQuestListOpen,
    mtsQuestCollect,
    // meta tutorial finished
    mtsTutorialGoodbye,
    mtsTutorialFinished
    );
  SetMetaTutorialStage = set of EnumMetaTutorialStage;

  TGameStateComponentMetaTutorial = class(TGameStateComponent)
    private const
      STAGE_REWARD : SetMetaTutorialStage     = [mtsStarterdeckWhite];
      STAGE_HIDDEN : SetMetaTutorialStage     = [mtsNone, mtsTutorialFinished];
      STAGE_WITH_TITLE : SetMetaTutorialStage = [mtsTutorialGoodbye];
      STAGE_TEXT_ONLY : SetMetaTutorialStage  = [mtsTutorialGoodbye];
      STAGE_DELAY_DEFAULT                     = 200;
      STAGE_DELAY : array [EnumMetaTutorialStage] of integer = (
        0, STAGE_DELAY_DEFAULT, 400, 2000,
        STAGE_DELAY_DEFAULT, STAGE_DELAY_DEFAULT);
    protected
      FStageDelay : TTimer;
      procedure Initialize; override;
      procedure OnShowDialog(Open : Boolean);
      procedure OnShowTutorialVideoDialog(Open : Boolean);
      procedure OnCompleteStage(Stage : EnumMetaTutorialStage);
    strict private
      FStage : EnumMetaTutorialStage;
      FInTransition : Boolean;
      procedure SetInTransition(const Value : Boolean); virtual;
      procedure SetStage(const Value : EnumMetaTutorialStage); virtual;
    published
      property InTransition : Boolean read FInTransition write SetInTransition;
      property Stage : EnumMetaTutorialStage read FStage write SetStage;
      [dXMLDependency('.Stage')]
      function IsActive : Boolean;
      [dXMLDependency('.Stage')]
      function StageHasTitle : Boolean;
      [dXMLDependency('.Stage')]
      function TextOnlyStage : Boolean;
      [dXMLDependency('.Stage')]
      function RewardStage : Boolean;
      [dXMLDependency('.Stage')]
      function ReceivedStarterDeckColor : EnumEntityColor;
    public
      procedure StartMetaTutorial;
      procedure StartMetaTutorialAtStage(Stage : EnumMetaTutorialStage);
      /// <summary> Finish the stages if it is the current stage. </summary>
      procedure CompleteStages(Stages : SetMetaTutorialStage);
      /// <summary> Called by UI element to finish the stage if its active, some elements can finish multiple stages. </summary>
      procedure CompletedStage(Stage : EnumMetaTutorialStage);
      /// <summary> Called by UI element to finish the stage if its active, some elements can finish multiple stages. </summary>
      procedure CompletedTwoStages(Stage, Stage2 : EnumMetaTutorialStage);
      /// <summary> Called by UI element to finish the stage if its active, some elements can finish multiple stages. </summary>
      procedure CompletedThreeStages(Stage, Stage2, Stage3 : EnumMetaTutorialStage);
      /// <summary> Called by UI element to finish the stage if its active, some elements can finish multiple stages. </summary>
      procedure CompletedFourStages(Stage, Stage2, Stage3, Stage4 : EnumMetaTutorialStage);
      /// <summary> Called by Ok-Button of Text-Only-Window. </summary>
      procedure CompleteCurrentStage;
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      procedure Idle; override;
      destructor Destroy; override;
  end;

  /// <summary> Manages the player level and rewards. </summary>
  TGameStateComponentPlayerLevel = class(TGameStateComponent)
    protected
      procedure Initialize; override;
      procedure OnInventoryLoaded;
      procedure OnLevelUpReward(Reward : TLootbox; ForReachingLevel : integer; AdditionalText : string);
      procedure OnLevelUpOpen(Open : Boolean);
      procedure CheckForLevelUps;

    strict private
      FLevelUpLoot : TLootbox;
      FLevelUpText : string;
      procedure SetLevelUpText(const Value : string); virtual;
      function GetProfile : TUserProfile;
      function GetHasLevelUp : Boolean;
      procedure SetLevelUpLoot(const Value : TLootbox); virtual;
    strict private// level up reward overview
      FLevelUpRewardListPage : TUltimateList<TLevelUpReward>;
      FLevelUpRewardListPaginator : TPaginator<TLevelUpReward>;
      procedure SetLevelUpRewardListPaginator(const Value : TPaginator<TLevelUpReward>); virtual;
    published
      property Profile : TUserProfile read GetProfile;
      [dXMLDependency('.LevelUpRewards')]
      property HasLevelUp : Boolean read GetHasLevelUp;
      property LevelUpRewards : TLootbox read FLevelUpLoot write SetLevelUpLoot;
      property AdditionalLevelUpText : string read FLevelUpText write SetLevelUpText;
      procedure ReceiveReward;

      property LevelUpRewardListCurrentObjects : TUltimateList<TLevelUpReward> read FLevelUpRewardListPage;
      property LevelUpRewardListPaginator : TPaginator<TLevelUpReward> read FLevelUpRewardListPaginator write SetLevelUpRewardListPaginator;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  TCollectionCard = class
    strict private
      FCard : TCard;
    published
      property Card : TCard read FCard write FCard;
    public
      Position : RVector2;
  end;

  /// <summary> Manages the collection in the main menu. </summary>
  TGameStateComponentCollection = class(TGameStateComponent)
    protected
      procedure Initialize; override;
      procedure OnCardUnlocked(UnlockedCard : TCard);
      procedure OnCardsChange(Sender : TUltimateList<TCard>; Items : TArray<TCard>; Action : EnumListAction; Indices : TArray<integer>);
    strict private// general
      FTab : EnumEntityColor;
      procedure SetTab(const Value : EnumEntityColor); virtual;
      function GetCardManager : TCardManager;
      procedure SetCardManager(const Value : TCardManager); virtual;
    strict private// overview
      FCards : TUltimateList<TCollectionCard>;
      FChosenCard : TCard;
      FCollectionCardCache : TObjectDictionary<TCard, TCollectionCard>;
      FShopItem : TShopItem;
      procedure SetShopItem(const Value : TShopItem); virtual;
      procedure SetChosenCard(const Value : TCard); virtual;
      procedure BuildCards;
    published
      property CardManager : TCardManager read GetCardManager write SetCardManager;

      property Tab : EnumEntityColor read FTab write SetTab;
      property Cards : TUltimateList<TCollectionCard> read FCards;

      property ChosenCard : TCard read FChosenCard write SetChosenCard;
      property ShopItem : TShopItem read FShopItem write SetShopItem;
      procedure ShowCardDetail(const Card : TCard);
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  EnumLeaderboardCategory = (lcStone, lcBronze, lcSilver, lcGold, lcCrystal);

  /// <summary> Manages the leaderboards in the main menu. </summary>
  TGameStateComponentLeaderboards = class(TGameStateComponent)
    protected const
      DEFAULT_LEAGUE   = lcBronze;
      DEFAULT_SCENARIO = es1v1;
      NON_TIME_LEAGUES = [lcBronze, lcSilver, lcGold];
      TIME_SCENARIOS   = [es1vE, es2vE];
    protected
      procedure Initialize; override;
      procedure OnLeaderboardsLoaded;
      procedure RefreshLeaderboards;
      procedure UpdateCurrentLeaderboard;
    strict private
      FCurrentMonth : integer;
      FChosenLeague : EnumLeaderboardCategory;
      FCurrentLeaderboard : TLeaderboard;
      FChosenScenario : EnumScenario;
      procedure SetChosenScenario(const Value : EnumScenario); virtual;
      procedure SetChosenLeague(const Value : EnumLeaderboardCategory); virtual;
      procedure SetCurrentLeaderboard(const Value : TLeaderboard); virtual;
    published
      property CurrentMonth : integer read FCurrentMonth;
      property ChosenScenario : EnumScenario read FChosenScenario write SetChosenScenario;
      property ChosenLeague : EnumLeaderboardCategory read FChosenLeague write SetChosenLeague;
      [dXMLDependency('.ChosenScenario')]
      function IsTimeBoard : Boolean;
      property Leaderboard : TLeaderboard read FCurrentLeaderboard write SetCurrentLeaderboard;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  /// <summary> Manages the quest system. </summary>
  TGameStateComponentQuests = class(TGameStateComponent)
    protected
      procedure Initialize; override;
    strict private
      FIsVisible : Boolean;
      FSecondsUntilWeeklyResets : integer;
      function GetQuestManager : TQuestManager;
      procedure SetSecondsUntilWeeklyResets(const Value : integer); virtual;
      procedure SetIsVisible(const Value : Boolean); virtual;
      procedure SetQuestManager(const Value : TQuestManager); virtual;
    published
      property QuestManager : TQuestManager read GetQuestManager write SetQuestManager;
      property IsVisible : Boolean read FIsVisible write SetIsVisible;
      /// <summary> Collects all quests, which contain lootlists. (Hack for starterdeck) </summary>
      procedure AutoCollect;
      property SecondsUntilWeeklyResets : integer read FSecondsUntilWeeklyResets write SetSecondsUntilWeeklyResets;
    public
      procedure Idle; override;
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      destructor Destroy; override;
  end;

  /// <summary> Manages the friendlist (GUI-Binding, actions) in the main menu. </summary>
  TGameStateComponentFriendlist = class(TGameStateComponent)
    protected
      procedure Initialize; override;
      procedure OnFriendRequest(const FriendRequest : TFriendRequest);
      procedure UpdateFriendlist(Sender : TUltimateList<TPerson>; Items : TArray<TPerson>; Action : EnumListAction; Indices : TArray<integer>);
      procedure UpdateFriendInvites(Sender : TUltimateList<TFriendRequest>; Items : TArray<TFriendRequest>; Action : EnumListAction; Indices : TArray<integer>);
    strict private
      FNewFriend : string;
      FIsVisible : Boolean;
      function GetFriendlist : TFriendlist;
      procedure SetFriendlist(const Value : TFriendlist); virtual;
      function GetFriends : IDataQuery<TPerson>;
      function GetRequests : IDataQuery<TFriendRequest>;
      function GetIncomingRequests : IDataQuery<TFriendRequest>;
      function GetOutgoingRequests : IDataQuery<TFriendRequest>;
      procedure SetIncomingRequests(const Value : IDataQuery<TFriendRequest>); virtual;
      procedure SetOutgoingRequests(const Value : IDataQuery<TFriendRequest>); virtual;
      procedure SetFriends(const Value : IDataQuery<TPerson>); virtual;
      procedure SetRequests(const Value : IDataQuery<TFriendRequest>); virtual;
      procedure SetIsVisible(const Value : Boolean); virtual;
    published
      // friendlist
      property Friendlist : TFriendlist read GetFriendlist write SetFriendlist;
      property IsVisible : Boolean read FIsVisible write SetIsVisible;
      property Friends : IDataQuery<TPerson> read GetFriends write SetFriends;
      property Requests : IDataQuery<TFriendRequest> read GetRequests write SetRequests;
      property IncomingRequests : IDataQuery<TFriendRequest> read GetIncomingRequests write SetIncomingRequests;
      property OutgoingRequests : IDataQuery<TFriendRequest> read GetOutgoingRequests write SetOutgoingRequests;
      procedure SetNewFriendID(const Value : string); virtual;
      property NewFriendID : string read FNewFriend write SetNewFriendID;
      procedure AddNewFriend;
      procedure RemoveFriend(const Friend : TPerson);
      procedure OpenChat(const Friend : TPerson);
      // invite friend dialog
      procedure InviteFriendByProposal(const FriendProposal : TFriendProposal);
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      constructor Create(Owner : TEntity; Parent : TGameState);
      destructor Destroy; override;
  end;

  /// //////////////////////////////////////////////////////////////////////////
  /// Implemented gamestates
  /// //////////////////////////////////////////////////////////////////////////

  TGameStateMenu = class abstract(TGameState)
    private
      FAnimatedBackground : TAnimatedImage;
    protected
      procedure EnterState; override;
      procedure LeaveState; override;
    public
      procedure Idle; override;
      destructor Destroy; override;
  end;

  TGameStateServerDown = class(TGameStateMenu)
    protected
      procedure EnterState; override;
    public
      constructor Create(Owner : TGameStateManager);
  end;

  TGameStateMaintenance = class(TGameStateMenu)
    private const
      SERVER_STATUS_POLL_INTERVAL = 5000;
    private
      FPollTimer : TTimer;
    protected
      procedure EnterState; override;
    public
      constructor Create(Owner : TGameStateManager);
      procedure Idle; override;
      destructor Destroy; override;
  end;

  TGameStateLoginQueue = class(TGameStateMenu)
    private const
      FALLBACK_POLLING_RATE = 10000;
    protected
      FShortcutTested, FFirstShortcut, FFallbackLoginDelayWaited, FLoginQueueDown, FLoginQueueSaysGo : Boolean;
      FCurrentPlayerCount : integer;
      FTimestampStart : int64;
      FCurrentPlayerOnlinePromise : TPromise<integer>;
      FLoginQueueSocket : TWebSocketClient;
      FServerPollingRate : TTimer;
      procedure EnterLogin;
      procedure EnterLoginQueue;
      procedure InitLoginQueueWindow;
      procedure LoginQueueDown;
      procedure CheckLoginQueueSocket;
      procedure EnterState; override;
      procedure LeaveState; override;
    strict private
      FInLoginQueue : Boolean;
      FPositionInQueue : integer;
      FTimeInQueue : integer;
      procedure SetTimeInQueue(const Value : integer); virtual;
      procedure SetInLoginQueue(const Value : Boolean); virtual;
      procedure SetPositionInQueue(const Value : integer); virtual;
    published
      property InLoginQueue : Boolean read FInLoginQueue write SetInLoginQueue;
      property PositionInQueue : integer read FPositionInQueue write SetPositionInQueue;
      property TimeInQueue : integer read FTimeInQueue write SetTimeInQueue;
    public
      constructor Create(Owner : TGameStateManager);
      procedure Idle; override;
      destructor Destroy; override;
  end;

  TGameStateLoginSteam = class(TGameState)
    protected
      procedure Login;
      procedure EnterState; override;
    public
      procedure Idle; override;
  end;

  TGameStateReconnect = class(TGameState)
    private
      FReadyToReconnect : Boolean;
      procedure SetReadyToReconnect(const Value : Boolean);
      procedure OnClearQueueFinished;
      function GetForceBrokerFallback : Boolean;
    protected
      procedure EnterState; override;
      procedure LeaveState; override;
    published
      procedure SetForceBrokerFallback(const Value : Boolean); virtual;
      property ForceBrokerFallback : Boolean read GetForceBrokerFallback write SetForceBrokerFallback;
      property IsReadyToReconnect : Boolean read FReadyToReconnect write SetReadyToReconnect;
      procedure Reconnect;
    public
      constructor Create(Owner : TGameStateManager);
      destructor Destroy; override;
  end;

  EnumMenu = (mtStart, mtGame, mtDeck, mtShop, mtCollection, mtTutorial, mtLeaderboards, mtInventory, mtGameRewards, mtGameStatistics);

  /// <summary> Manages the main menu </summary>
  TGameStateMainMenu = class(TGameStateMenu)
    private
      const
      CURRENT_PLAYER_ONLINE_UPDATE_INTERVAL_DASHBOARD = 10 * 1000;
      SLOW_LOADING_TIME                               = 40 * 1000;
    protected
      FScreenSwapWait : integer;
      FAssetPreloader : TAssetPreloader;
      FUpdatePlayerTimer, FLoadingTime : TTimer;
      FPreloaderFailedBlock : TList<string>;
      FFirstLoadDone : Boolean;
      procedure InitDialogs;
      procedure InitAssetLoader;
      procedure OnPreloadingDialogOpen(Open : Boolean);
      procedure EnterState; override;
      procedure LeaveState; override;
      procedure OnPreloadFileFailed(const FileName, ErrorMessage : string);
    strict private
      FCurrentMenu : EnumMenu;
      FCardShowcase : TCardInfo;
      FCardInstanceShowcase : TCardInstance;
      FIsLoading, FIsPreLoading, FIsLoadingSlow : Boolean;
      procedure SetIsLoadingSlow(const Value : Boolean); virtual;
      procedure SetIsPreLoading(const Value : Boolean); virtual;
      procedure SetIsLoading(const Value : Boolean); virtual;
      procedure SetCardShowCase(const Value : TCardInfo); virtual;
      procedure SetCurrentMenu(const Value : EnumMenu); virtual;
      procedure SetCardInstanceShowCase(const Value : TCardInstance); virtual;
    published
      property CurrentMenu : EnumMenu read FCurrentMenu write SetCurrentMenu;
      property CardShowcase : TCardInfo read FCardShowcase write SetCardShowCase;
      property CardInstanceShowcase : TCardInstance read FCardInstanceShowcase write SetCardInstanceShowCase;
      property IsLoading : Boolean read FIsLoading write SetIsLoading;
      property IsPreLoading : Boolean read FIsPreLoading write SetIsPreLoading;
      property IsLoadingSlow : Boolean read FIsLoadingSlow write SetIsLoadingSlow;
    public
      constructor Create(Owner : TGameStateManager);
      procedure Idle; override;
      destructor Destroy; override;
  end;

  /// <summary> Manages the ingame hud. </summary>
  TGameStateComponentHUDTooltip = class(TGameStateComponent)
    protected
      procedure Initialize; override;
      procedure UpdateToolTip(Entity : TEntity; IsCard : Boolean);
      procedure ShowToBeShown;
    published
      [XEvent(eiShowToolTip, epLast, etTrigger, esGlobal)]
      /// <summary> Display the tooltip to an entity. </summary>
      function OnShowToolTip(Entity, IsCard : RParam) : Boolean;
      [XEvent(eiHideToolTip, epLast, etTrigger, esGlobal)]
      /// <summary> Hides the tooltip immediately. </summary>
      function OnHideToolTip : Boolean;
      [XEvent(eiSelectEntity, epFirst, etRead, esGlobal)]
      /// <summary> Return selected entity. </summary>
      function OnReadSelectEntity() : RParam;
      [XEvent(eiSelectEntity, epLast, etTrigger, esGlobal)]
      /// <summary> Show a tooltip while selecting an entity. </summary>
      function OnSelectEntity(Entity : RParam) : Boolean;
      [XEvent(eiReplaceEntity, epLast, etTrigger, esGlobal)]
      /// <summary> Updates the tooltip with the replaced one if old one was selected. </summary>
      function OnReplaceEntity(oldEntityID, newEntityID, IsSameEntity : RParam) : Boolean;
    strict private
      FSelectedEntity, FToBeShown : TEntity;
      FToBeShownScriptFile : string;
      FIsVisible, FHasMainWeapon, FToBeShownIsCard : Boolean;
      FMainWeaponType : EnumDamageType;
      FMainWeaponDPS : single;
      FMaximumHealth : single;
      FEntityScriptFile : string;
      FCurrentHealth : single;
      FArmorType : EnumArmorType;
      FCardType : EnumCardType;
      FDescription : string;
      FName : string;
      FEntityScriptFileForIcon : string;
      FMainWeaponRange : single;
      FMainWeaponDamage : single;
      FMainWeaponCooldown : single;
      FMainWeaponIsMelee : Boolean;
      FLevel : integer;
      FLeague : integer;
      FIsLegendary : Boolean;
      FAbilityNames : string;
      FKeywords : TArray<string>;
      FSkills : TArray<RAbilityDescription>;
      FHasKeywords : Boolean;
      FHasSkills : Boolean;
      FSkinID : string;
      FMaximumEnergy : integer;
      FCurrentOverheal : single;
      FCurrentEnergy : integer;
      FIsEpic : Boolean;
      procedure SetIsEpic(const Value : Boolean); virtual;
      procedure SetCurrentEnergy(const Value : integer); virtual;
      procedure SetCurrentOverheal(const Value : single); virtual;
      procedure SetMaximumEnergy(const Value : integer); virtual;
      procedure SetSkinID(const Value : string); virtual;
      procedure SetAbilityNames(const Value : string); virtual;
      procedure SetHasKeywords(const Value : Boolean); virtual;
      procedure SetHasSkills(const Value : Boolean); virtual;
      procedure SetKeywords(const Value : TArray<string>); virtual;
      procedure SetSkills(const Value : TArray<RAbilityDescription>); virtual;
      procedure SetIsLegendary(const Value : Boolean); virtual;
      procedure SetLeague(const Value : integer); virtual;
      procedure SetLevel(const Value : integer); virtual;
      procedure SetMainWeaponIsMelee(const Value : Boolean); virtual;
      procedure SetMainWeaponCooldown(const Value : single); virtual;
      procedure SetMainWeaponDamage(const Value : single); virtual;
      procedure SetMainWeaponRange(const Value : single); virtual;
      procedure SetEntityScriptFileForIcon(const Value : string); virtual;
      procedure SetName(const Value : string); virtual;
      procedure SetDescription(const Value : string); virtual;
      procedure SetCardType(const Value : EnumCardType); virtual;
      procedure SetArmorType(const Value : EnumArmorType); virtual;
      procedure SetCurrentHealth(const Value : single); virtual;
      procedure SetEntityScriptFile(const Value : string); virtual;
      procedure SetMaximumHealth(const Value : single); virtual;
      procedure SetMainWeaponDPS(const Value : single); virtual;
      procedure SetIsVisible(const Value : Boolean); virtual;
      procedure SetSelectedEntity(const Value : TEntity); virtual;
      procedure SetHasMainWeapon(const Value : Boolean); virtual;
      procedure SetMainWeaponType(const Value : EnumDamageType); virtual;
    published
      property SelectedEntity : TEntity read FSelectedEntity write SetSelectedEntity;
      property IsVisible : Boolean read FIsVisible write SetIsVisible;
      // --- General ---
      property EntityScriptFile : string read FEntityScriptFile write SetEntityScriptFile;
      property EntityScriptFileForIcon : string read FEntityScriptFileForIcon write SetEntityScriptFileForIcon;
      property SkinID : string read FSkinID write SetSkinID;
      property CardType : EnumCardType read FCardType write SetCardType;
      property name : string read FName write SetName;
      property IsLegendary : Boolean read FIsLegendary write SetIsLegendary;
      property IsEpic : Boolean read FIsEpic write SetIsEpic;
      property League : integer read FLeague write SetLeague;
      property Level : integer read FLevel write SetLevel;
      property AbilityNames : string read FAbilityNames write SetAbilityNames;
      property HasSkills : Boolean read FHasSkills write SetHasSkills;
      property Skills : TArray<RAbilityDescription> read FSkills write SetSkills;
      property HasKeywords : Boolean read FHasKeywords write SetHasKeywords;
      property Keywords : TArray<string> read FKeywords write SetKeywords;
      // --- Unit ---
      property ArmorType : EnumArmorType read FArmorType write SetArmorType;
      property CurrentHealth : single read FCurrentHealth write SetCurrentHealth;
      property MaximumHealth : single read FMaximumHealth write SetMaximumHealth;
      property CurrentOverheal : single read FCurrentOverheal write SetCurrentOverheal;
      property CurrentEnergy : integer read FCurrentEnergy write SetCurrentEnergy;
      property MaximumEnergy : integer read FMaximumEnergy write SetMaximumEnergy;
      // --- Spell ---
      property Description : string read FDescription write SetDescription;
      // --- Main weapon ---
      property HasMainWeapon : Boolean read FHasMainWeapon write SetHasMainWeapon;
      property MainWeaponType : EnumDamageType read FMainWeaponType write SetMainWeaponType;
      property MainWeaponDPS : single read FMainWeaponDPS write SetMainWeaponDPS;
      property MainWeaponDamage : single read FMainWeaponDamage write SetMainWeaponDamage;
      property MainWeaponCooldown : single read FMainWeaponCooldown write SetMainWeaponCooldown;
      property MainWeaponRange : single read FMainWeaponRange write SetMainWeaponRange;
      property MainWeaponIsMelee : Boolean read FMainWeaponIsMelee write SetMainWeaponIsMelee;
    public
      procedure ParentEntered; override;
      procedure ParentLeft; override;
      procedure Idle; override;
      destructor Destroy; override;
  end;

  TGameStateComponentCore = class(TGameStateComponent)
    protected
      FSentReady : Boolean;
    published
      [XEvent(eiGameEvent, epLast, etTrigger, esGlobal)]
      function OnGameEvent(Eventname : RParam) : Boolean;
    public
      procedure ParentEntered; override;
  end;

  /// <summary> This is the state, when the player is in game. </summary>
  TGameStateCoreGame = class(TGameState)
    private const
      FPS_LOG_INTERVAL               = 1234; // used a unusual number so it doesn't align with any other counters
      PERFORMANCE_ANALYSIS_THRESHOLD = 20;   // we lower the settings if FPS are lower than 20
      PERFORMANCE_ANALYSIS_DURATION  = 3000; // we measure performance after about 3 seconds
    protected                                // performance measurement for graphic reduction
      FPerformanceMesurementActive : Boolean;
      FPerformanceMeasurementDuration : TTimer;
      FFPSAverageSum, FFPSAverageSamples : int64;
      procedure InitPerformanceTest;
      procedure UpdatePerformanceTest;
      procedure LowerSettings;
    protected// fps log
      FFPSLog : TList<RFPSLogData>;
      FFPSLogTimer : TTimer;
      procedure LogFPS;
      procedure SendFPSLog;
    protected
      procedure EnterState; override;
      procedure LeaveState; override;
    strict private
      FGameSocket : TTCPClientSocketDeluxe;
      FTokenMapping : TList<integer>;
      FAuthentificationToken : string;
      FGameData : RGameFoundData;
      FCursorClipped : Boolean;
      FHUD : TIngameHUD;
      FBlank : TVertexScreenAlignedQuad;
      FGUIWarming : TTimer;
      /// <summary> Frames to wait after anything is loaded correctly. </summary>
      FScreenSwapWait : integer;
      FSentReady, FSentInit : Boolean;
      function BuildGameInfo : TGameInformation;
      procedure InitFullscreenColorBlank;
      procedure InitScoreboard;
      procedure InitValues;
      procedure UpdateConfinedCursor;
      function CheckAndProcessGameIsFinished : Boolean;
      procedure EnterMainMenuFailed;
      procedure EnterMainMenu;
    protected
      property GameData : RGameFoundData read FGameData write FGameData;
      procedure PassGameData(GameSocket : TTCPClientSocketDeluxe; const AuthentificationToken : string; TokenMapping : TList<integer>);
    public
      constructor Create(Owner : TGameStateManager);
      procedure Idle; override;
      destructor Destroy; override;
  end;

  EnumLoadingStage = (lsMatch, lsHint);

  /// <summary> Preloads files into the engine. Crawls while project folder and loads specific files endings. </summary>
  TGameStateLoadCoreGame = class(TGameState)
    protected const
      SLIDE_TIME           = 5;
      MATCH_TIME           = 10;
      MINIMUM_LOADING_TIME = MATCH_TIME;

    protected
      FGameSocket : TTCPClientSocketDeluxe;
      FTokenMapping : TList<integer>;
      FAuthentificationToken : string;
      FAssetPreloader : TAssetPreloader;
      FGameData : RGameFoundData;
      FPreloaderFailedBlock : TList<string>;
      /// <summary> Frames to wait after anything is loaded correctly. </summary>
      FScreenSwapWait : integer;
      // MinimumLoadingTime: The loading screen should be displayed at least for a short time to prevent confusion
      FMinimumLoadingTime, FLoadingTime : TTimer;
      procedure EnterState; override;
      procedure Idle; override;
      procedure LeaveState; override;

      procedure UpdateLoadingState;

      procedure ShutdownIfTestserver(const ErrorMessage : string);

      procedure InitAssetLoader;
      procedure OnPreloadFileFailed(const FileName, ErrorMessage : string);

      procedure SendAuthentification;
      procedure ConnectToGameServer;

      procedure ProcessGameServerMessages;

      procedure ConnectionToGameServerLost;
      procedure ConnectionToGameServerRefused(ErrorCode : integer; const ErrorMessage : string);
      procedure GameWasAborted;

      procedure EnterCore;
      procedure EnterMainMenu;
      procedure EnterMainMenuFailed;
    strict private// loading screen data
      FState : string;
      FSlideIndex, FSlideOffset : integer;
      FLoadingStage : EnumLoadingStage;
      FProgress : single;
      FFirstLoading : Boolean;
      procedure SetFirstLoading(const Value : Boolean); virtual;
      procedure SetLoadingStage(const Value : EnumLoadingStage); virtual;
      procedure SetSlideIndex(const Value : integer); virtual;
      procedure SetState(const Value : string); virtual;
      procedure SetProgress(const Value : single); virtual;
      procedure SetGameData(const Value : RGameFoundData); virtual;
    published
      property GameData : RGameFoundData read FGameData write SetGameData;
      property Loader : TAssetPreloader read FAssetPreloader;
      property Progress : single read FProgress write SetProgress;
      property State : string read FState write SetState;
      property SlideIndex : integer read FSlideIndex write SetSlideIndex;
      property FirstLoading : Boolean read FFirstLoading write SetFirstLoading;
      property Stage : EnumLoadingStage read FLoadingStage write SetLoadingStage;
    public
      constructor Create(Owner : TGameStateManager);
      destructor Destroy(); override;
  end;

  // End /////////////////////////////////////////////////////////////////////////////////////////////////////
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

uses
  BaseConflictSplash,
  BaseConflict.Classes.Gamestates.Actions;

{ TGameStateManager }

procedure TGameStateManager.AddNewGameState(GameState : TGameState; GameStateName : string);
begin
  assert(not FStates.ContainsKey(GameStateName));
  FStates.Add(GameStateName, GameState);
end;

procedure TGameStateManager.BringToFront;
begin
  Application.Restore;
  Application.BringToFront;
  GameWindow.BringToFront;
end;

procedure TGameStateManager.BrowseTo(Website : EnumWebsites);
begin
  case Website of
    weGame : HSystem.OpenUrlInBrowser('http://riseoflegions.com');
    weCompany : HSystem.OpenUrlInBrowser('http://brokengames.de');
    weFMod : HSystem.OpenUrlInBrowser('http://fmod.com/');
    weDiscord : HSystem.OpenUrlInBrowser('https://discordapp.com/invite/yZvpPBT');
    weYoutube : HSystem.OpenUrlInBrowser('https://www.youtube.com/c/Riseoflegions');
    weTwitter : HSystem.OpenUrlInBrowser('https://twitter.com/Rise_Of_Legions');
    weFacebook : HSystem.OpenUrlInBrowser('https://www.facebook.com/RiseOfLegions/');
    wePatchNotes : HSystem.OpenUrlInBrowser('http://riseoflegions.com/patch-notes');
    weWiki : HSystem.OpenUrlInBrowser('http://wiki.riseoflegions.com');
    weTranslation : HSystem.OpenUrlInBrowser('https://crowdin.com/project/riseoflegions');
    wePublisher : HSystem.OpenUrlInBrowser('http://www.crunchyleafgames.com/');
    weGuide : HSystem.OpenUrlInBrowser('https://steamcommunity.com/sharedfiles/filedetails/?id=2163901443');
    weSteamForum : HSystem.OpenUrlInBrowser('https://steamcommunity.com/app/748940/discussions/');
    weScill : if HInternationalizer.CurrentLanguage = 'de' then HSystem.OpenUrlInBrowser('https://bit.ly/2YeQHSv')
      else HSystem.OpenUrlInBrowser('https://bit.ly/3cZdar4');
    weTournament : HSystem.OpenUrlInBrowser('https://discord.gg/yMjZaje');
    weScillTournament : HSystem.OpenUrlInBrowser('https://app.scillplay.com/games/522523512784945154/tournaments');
    weSteamChat : HSystem.OpenUrlInBrowser('https://s.team/chat/LCJy43S0');
  end;
  if assigned(QuestManager) then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_OPEN_URL_PREFIX + HRTTi.EnumerationToString<EnumWebsites>(Website), True);
end;

function TGameStateManager.CanProgramClose : Boolean;
begin
  Result := Settings.GetBooleanOption(coDebugUseLocalTestServer) or FAllowClose;
  if not Result then
      ExitDialogVisible := True;
end;

procedure TGameStateManager.ChangeGameState(GameStateName : string);
var
  NewGameState : TGameState;
begin
  DialogManager.CloseAllDialogs;

  NewGameState := GetGameState<TGameState>(GameStateName);
  // clear old states
  FCurrentState := GameStateName;
  // remove all gamestates, remove until clear
  while FCurrentStates.Count > 0 do FCurrentStates.Pop.LeaveState;
  // stack is clear, push new state
  FCurrentStates.Push(NewGameState);
  // and start initiating it
  NewGameState.EnterState;
end;

procedure TGameStateManager.CleanManager;
begin
  Account.Logout;
  FreeAndNil(CurrencyManager);
  FreeAndNil(CardManager);
  FreeAndNil(Deckbuilding);
  FreeAndNil(Shop);
  FreeAndNil(QuestManager);
  FreeAndNil(UserProfile);
  FreeAndNil(Friendlist);
  FreeAndNil(ScenarioManager);
  FreeAndNil(LeaderboardManager);
  FreeAndNil(Matchmaking);
  FreeAndNil(ChatSystem);
  FreeAndNil(MessageInbox);
  IsApiReady := False;
end;

procedure TGameStateManager.Close;
begin
  if CanProgramClose and assigned(OnShutdown) then
      OnShutdown;
end;

procedure TGameStateManager.CloseForcePrompt;
begin
  FAllowClose := False;
  Close;
end;

procedure TGameStateManager.CloseNoPrompt;
begin
  FAllowClose := True;
  Close;
end;

constructor TGameStateManager.Create(GameWindow : TGameForm);
begin
  MainActionQueue.OnError := procedure(CriticalError : Boolean; const ErrorMsg : string; ActionClass : TClass)
    var
      Msg : string;
    begin
      Msg := '[QueueError]' + ErrorMsg;
      if CriticalError then Msg := '[Critical]' + Msg + ', Action: ' + ActionClass.ClassName;
      HLog.Write(elWarning, Msg);
      if ErrorMsg = 'TIMEOUT' then ShowErrorcode(ecRequestTimeOut)
      else if ErrorMsg = 'BLOCKED' then ShowErrorcode(ecRequestBlocked)
      else ShowErrorcodeRaw(HString.StrToInt(ErrorMsg, 0));
    end;

  FGameWindow := GameWindow;
  FStates := TObjectDictionary<string, TGameState>.Create([doOwnsValues]);
  FCurrentStates := TStack<TGameState>.Create;
  FDialogManager := TDialogManager.Create;
  FCurrentState := '';
  Account := TAccount.Create;
  Account.ForceBrokerFallback := Settings.GetBooleanOption(coGeneralForceBrokerFallback);
  FLastClickable := -1;

  FMenuMusicEvent := SoundSystem.GetEventInstance('event:/music/game/meta');

  GUI.SubscribeToEvent(geClick, GUIEventCallback);
  GUI.SubscribeToEvent(geRightClick, GUIEventCallback);
  GUI.SubscribeToEvent(geChanged, GUIEventCallback);
  GUI.SubscribeToEvent(geSubmit, GUIEventCallback);
  GUI.SubscribeToEvent(geMouseEnter, GUIEventCallback);
  GUI.SubscribeToEvent(geMouseLeave, GUIEventCallback);

  GUI.SetContext('serverstate', ServerState);
  GUI.SetContext('HClient', HClient);
  GUI.SetContext('F', HGUIMethods);
  GUI.SetContext('client', self);
  GUI.SetContext('CardInfoManager', CardInfoManager);
  GUI.SetContext('dialogs', FDialogManager);

  FAllowClose := False;
end;

procedure TGameStateManager.CreateManager;
begin
  if not assigned(CurrencyManager) then
      CurrencyManager := TCurrencyManager.Create;

  if not assigned(CardManager) then
      CardManager := TCardManager.Create;

  if not assigned(Deckbuilding) then
      Deckbuilding := TDeckManager.Create;

  if not assigned(Shop) then
      Shop := TShop.Create();

  if not assigned(QuestManager) then
      QuestManager := TQuestManager.Create;

  if not assigned(UserProfile) then
      UserProfile := TUserProfile.Create;

  if not assigned(Friendlist) then
      Friendlist := TFriendlist.Create(Account);

  if not assigned(ScenarioManager) then
      ScenarioManager := TScenarioManager.Create;

  if not assigned(Matchmaking) and assigned(Friendlist) then
      Matchmaking := TMatchmakingManager.Create(Account, Friendlist);

  if not assigned(LeaderboardManager) then
      LeaderboardManager := TLeaderboardManager.Create;

  if not assigned(ChatSystem) and assigned(Friendlist) then
      ChatSystem := TChatSystem.Create(Friendlist);

  if not assigned(MessageInbox) then
      MessageInbox := TMessageInbox.Create;

  TActionSetVariable<Boolean>.Create(True, IsApiReady, SetIsApiReady).DoInExecuteSynchronized.Deploy;
end;

function TGameStateManager.CurrentGameState : TGameState;
begin
  Result := FCurrentStates.Peek;
end;

destructor TGameStateManager.Destroy;
begin
  GUI.SetContext('serverstate', nil);
  GUI.SetContext('HClient', nil);
  GUI.SetContext('F', nil);
  GUI.SetContext('client', nil);
  GUI.SetContext('CardInfoManager', nil);
  GUI.SetContext('dialogs', nil);
  FCurrentStates.Free;
  FStates.Free;

  FMenuMusicEvent.Free;

  FreeAndNil(ServerState);
  FreeAndNil(Account);
  FreeAndNil(UserProfile);
  FreeAndNil(CurrencyManager);
  FreeAndNil(Deckbuilding);
  FreeAndNil(CardManager);
  FreeAndNil(QuestManager);
  FreeAndNil(Shop);
  FreeAndNil(Friendlist);
  FreeAndNil(ChatSystem);
  FreeAndNil(LeaderboardManager);
  FreeAndNil(Matchmaking);
  FreeAndNil(ScenarioManager);
  FreeAndNil(MessageInbox);
  FreeAndNil(FDialogManager);
  inherited;
end;

function TGameStateManager.GetGameState<T>(const GameStateName : string) : T;
var
  GameState : TGameState;
begin
  if not FStates.TryGetValue(GameStateName, GameState) then
      raise Exception.Create(
      Format('TGameStateManager.GetGameState: Gamestate with name "%s" is not registered.', [GameStateName]));
  Result := GameState as T;
end;

function TGameStateManager.GetIsStaging : Boolean;
begin
  Result := BaseConflict.Globals.Client.IsStaging;
end;

procedure TGameStateManager.GUIEventCallback(const Sender : RGUIEvent);
begin
  CurrentGameState.GUIEventHandlerRecursion(Sender);
end;

procedure TGameStateManager.HideWindow;
begin
  GameWindow.Visible := False;
end;

procedure TGameStateManager.SetClientState(const Value : EnumClientState);
begin
  FClientState := Value;
  UpdateSoundSettings;
end;

procedure TGameStateManager.SetClientWindow;
var
  DefaultWindowSize, WindowSize, FullWindowSize, ScaledWindowSize, ScreenSize : RIntVector2;
  ScalingMode : EnumMenuScaling;
  Framed, WideScreen, Is16To9 : Boolean;
begin
  if IsWindowMode(wmClient) and FWindowInitialized then exit;
  FWindowInitialized := True;
  FWindowMode := wmClient;
  GameWindow.Cursor := System.UITypes.crDefault;
  Framed := Settings.GetBooleanOption(coMenuClientFullscreenFrame);

  ScreenSize := RIntVector2.Create(TargetMonitor.Width, TargetMonitor.Height);
  Is16To9 := ScreenSize.Width * CLIENT_DEFAULT_DIMENSIONS.Height = ScreenSize.Height * CLIENT_DEFAULT_DIMENSIONS.Width;
  // windows only put windows before the taskbar if fullscreen, so we have to make it smaller on not perfect fitting screens
  if not Is16To9 and not Framed then
  begin
    ScreenSize.Height := TargetMonitor.WorkAreaRect.Height;
    ScreenSize.Width := TargetMonitor.WorkAreaRect.Width;
  end;
  WideScreen := ScreenSize.Width * CLIENT_DEFAULT_DIMENSIONS.Height > ScreenSize.Height * CLIENT_DEFAULT_DIMENSIONS.Width;

  DefaultWindowSize := CLIENT_DEFAULT_DIMENSIONS;
  WindowSize := Settings.GetDimensionOption(coMenuClientResolution);
  if WindowSize.IsZeroVector then
      WindowSize := CLIENT_DEFAULT_DIMENSIONS;
  FullWindowSize := RIntVector2.Create(ScreenSize.Width, ScreenSize.Height);
  if not WideScreen then
      ScaledWindowSize := RIntVector2.Create(ScreenSize.Width, (ScreenSize.Width * CLIENT_DEFAULT_DIMENSIONS.Height) div CLIENT_DEFAULT_DIMENSIONS.Width)
  else
      ScaledWindowSize := RIntVector2.Create((ScreenSize.Height * CLIENT_DEFAULT_DIMENSIONS.Width) div CLIENT_DEFAULT_DIMENSIONS.Height, ScreenSize.Height);

  ScalingMode := Settings.GetEnumOption<EnumMenuScaling>(coMenuClientScaling);
  if ScalingMode = msDownscaling then
  begin
    if (not WideScreen and (ScaledWindowSize.Width < CLIENT_DEFAULT_DIMENSIONS.Width)) or
      (WideScreen and (ScaledWindowSize.Height < CLIENT_DEFAULT_DIMENSIONS.Height)) then
        ScalingMode := msFullscreen
    else
        ScalingMode := msDisabled;
  end;

  if Framed then
  begin
    if ScalingMode = msDisabled then
    begin
      GUI.ViewSize := WindowSize;
      GUI.VirtualSize := DefaultWindowSize;
      WindowSize := FullWindowSize;
      GameWindow.BorderStyle := bsNone;
    end
    else if ScalingMode = msFullscreen then
    begin
      GUI.ViewSize := ScaledWindowSize;
      GUI.VirtualSize := DefaultWindowSize;
      WindowSize := FullWindowSize;
      GameWindow.BorderStyle := bsNone;
    end
  end
  else
  begin
    if ScalingMode = msDisabled then
    begin
      GUI.ViewSize := RIntVector2.ZERO;
      GUI.VirtualSize := DefaultWindowSize;
      WindowSize := WindowSize;
      GameWindow.BorderStyle := bsNone;
    end
    else if ScalingMode = msFullscreen then
    begin
      GUI.ViewSize := RIntVector2.ZERO;
      GUI.VirtualSize := DefaultWindowSize;
      WindowSize := ScaledWindowSize;
      GameWindow.BorderStyle := bsNone;
    end
  end;

  GameWindow.Width := WindowSize.Width;
  GameWindow.Height := WindowSize.Height;
  UpdateWindowPosition;

  if assigned(GFXD) then
      GFXD.ChangeResolution(RIntVector2.Create(GameWindow.Clientwidth, GameWindow.ClientHeight));
end;

procedure TGameStateManager.SetDialogManager(const Value : TDialogManager);
begin
  // only notification
end;

procedure TGameStateManager.SetErrorCaption(const Value : string);
begin
  FErrorCaption := Value;
end;

procedure TGameStateManager.SetErrorConfirm(const Value : string);
begin
  FErrorConfirm := Value;
end;

procedure TGameStateManager.SetErrorMessage(const Value : string);
begin
  FErrorMessage := Value;
end;

procedure TGameStateManager.SetExitDialogVisible(const Value : Boolean);
begin
  FExitDialogVisible := Value;
end;

procedure TGameStateManager.SetIngameWindow;
var
  ResX, ResY : integer;
  OverrideRect : TRect;
begin
  if IsWindowMode(wmIngame) and FWindowInitialized then exit;
  FWindowInitialized := True;
  FWindowMode := wmIngame;
  GameWindow.Cursor := crIngame;

  GameWindow.Top := TargetMonitor.Top;
  GameWindow.Left := TargetMonitor.Left;
  if Settings.GetEnumOption<EnumDisplayMode>(coEngineDisplayMode) = dmWindowed then
  begin
    GameWindow.BorderStyle := bsSizeable;
    if HSystem.TryParseResolution(Settings.GetStringOption(coEngineResolution), ResX, ResY) then
    begin
      GameWindow.ClientHeight := ResY;
      GameWindow.Clientwidth := ResX;
    end
    else
    begin
      GameWindow.SetBounds(TargetMonitor.Left, TargetMonitor.Top, TargetMonitor.WorkAreaRect.Width, TargetMonitor.WorkAreaRect.Height);
    end;
  end
  else // if Settings.GetEnumOption<EnumDisplayMode>(coEngineDisplayMode) = dmBorderlessFullscreenWindow then
  begin
    GameWindow.BorderStyle := bsNone;
    GameWindow.SetBounds(TargetMonitor.Left, TargetMonitor.Top, TargetMonitor.Width, TargetMonitor.Height);
  end;

  GUI.ViewSize := RIntVector2.ZERO;
  GUI.VirtualSize := RIntVector2.ZERO;

  if HSystem.TryParseRect(Settings.GetStringOption(coEngineGameWindowOverride), OverrideRect) then
  begin
    GameWindow.SetBounds(OverrideRect.Left, OverrideRect.Top, OverrideRect.Width, OverrideRect.Height);
    GUI.ViewSize := RIntVector2.Create(GameWindow.Clientwidth, GameWindow.ClientHeight);
    GUI.VirtualSize := RIntVector2.Create(GameWindow.Clientwidth, GameWindow.ClientHeight);
  end;

  if assigned(GFXD) then
      GFXD.ChangeResolution(RIntVector2.Create(GameWindow.Clientwidth, GameWindow.ClientHeight));
end;

procedure TGameStateManager.SetIsApiReady(const Value : Boolean);
begin
  FIsApiReady := Value;
  if FIsApiReady and not GetGameState<TGameStateMainMenu>(GAMESTATE_MAINMENU).IsPreLoading then
      DialogManager.CloseDialog(diPreloading);
end;

procedure TGameStateManager.SetIsErrorDialogOpen(const Value : Boolean);
begin
  FIsErrorDialogOpen := Value;
end;

procedure TGameStateManager.SetIsLoading(const Value : Boolean);
begin
  if MainActionQueue.IsActive then
  begin
    FIsLoading := Value;
    DialogManager.BindDialog(diGenericLoading, FIsLoading);
  end
  else
  begin
    if Value then
        TActionSetVariable<Boolean>.Create(Value, IsLoading, SetIsLoading).Deploy
    else
    begin
      TActionSetVariable<Boolean>.Create(Value, IsLoading, SetIsLoading).DoInFinished.Deploy;
      TActionSetVariable<string>.Create('', LoadingCaption, SetLoadingCaption).DoInFinished.Deploy;
      TActionSetVariable<string>.Create('', LoadingMessage, SetLoadingMessage).DoInFinished.Deploy;
    end;
  end;
end;

procedure TGameStateManager.SetLoadingCaption(const Value : string);
begin
  FLoadingCaption := Value;
end;

procedure TGameStateManager.SetLoadingMessage(const Value : string);
begin
  FLoadingMessage := Value;
end;

procedure TGameStateManager.ShowError(const ErrorCaption, ErrorMessage : string);
begin
  ShowErrorConfirm(ErrorCaption, ErrorMessage, '§ok');
end;

procedure TGameStateManager.ShowErrorcode(ErrorCode : EnumErrorCode);
begin
  ShowErrorcodeRaw(ord(ErrorCode));
end;

procedure TGameStateManager.ShowErrorcodeRaw(ErrorCode : integer);
begin
  ShowError(_('§error_caption'), _('§errorcode_' + HString.IntToStr(ErrorCode, 3)));
  OnQueueError(EnumErrorCode(ErrorCode));
end;

procedure TGameStateManager.ShowErrorConfirm(const ErrorCaption, ErrorMessage, ErrorConfirm : string);
begin
  self.ErrorConfirm := ErrorConfirm;
  self.ErrorCaption := ErrorCaption;
  self.ErrorMessage := ErrorMessage;
  IsErrorDialogOpen := True;
end;

procedure TGameStateManager.ShowWindow;
begin
  GameWindow.Visible := True;
  UpdateWindowPosition;
end;

procedure TGameStateManager.SwitchMenuMusic(NewMusic : EnumMenuMusic);
begin
  if FCurrentMenuMusic <> NewMusic then
  begin
    if NewMusic = mmNone then FMenuMusicEvent.Stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
    case NewMusic of
      mmIntro : FMenuMusicEvent.ParameterValue['switch_music'] := 0;
      mmMenu : FMenuMusicEvent.ParameterValue['switch_music'] := 1;
      mmDeckbuilding : FMenuMusicEvent.ParameterValue['switch_music'] := 2;
      mmLoading : FMenuMusicEvent.ParameterValue['switch_music'] := 3;
    end;
    if FCurrentMenuMusic = mmNone then FMenuMusicEvent.Start;
    FCurrentMenuMusic := NewMusic;
  end;
end;

function TGameStateManager.TargetMonitor : TMonitor;
var
  TargetMonitorIndex : integer;
begin
  TargetMonitorIndex := Settings.GetIntegerOption(coEngineTargetMonitor);
  if (TargetMonitorIndex >= 0) and (TargetMonitorIndex < Screen.MonitorCount) then
      Result := Screen.Monitors[TargetMonitorIndex]
  else
      Result := Screen.PrimaryMonitor;
end;

procedure TGameStateManager.UpdateSettingsOption(Option : EnumClientOption);
var
  SteamLanguageKey : string;
begin
  case Option of
    coGeneralLanguage :
      begin
        if Settings.IsSetNotNone(coGeneralLanguage) then
            HInternationalizer.ChooseLanguage(Settings.GetStringOption(coGeneralLanguage))
          {$IFDEF STEAM}
        else
        begin
          SteamLanguageKey := SteamApps.GetCurrentGameLanguage;
          HInternationalizer.ChooseLanguage(HClient.MapSteamLanguageKeyToGame(SteamLanguageKey));
        end;
        GUI.ReloadLanguage;
        {$ENDIF}
      end;
    coMenuClientScaling, coMenuClientResolution, coMenuClientFullscreenFrame :
      begin
        if IsClientWindow then
        begin
          FWindowInitialized := False;
          SetClientWindow;
        end;
      end;
    coKeybindingBindingDeckslot01 .. coKeybindingBindingDeckslot12 :
      begin
        if assigned(HUD) then
            HUD.UpdateHotkeysInDeck;
      end;
  end;
end;

procedure TGameStateManager.UpdateSoundSettings(Option : EnumClientOption);
begin
  if State = csCoreGame then
  begin
    // volume settings
    if Option in [coGeneralNone, coSoundMasterVolume] then SoundMasterBus.Volume := Settings.GetIntegerOption(coSoundMasterVolume) / 100;
    if Option in [coGeneralNone, coSoundEffectVolume] then SoundEffectBus.Volume := Settings.GetIntegerOption(coSoundEffectVolume) / 100;
    if Option in [coGeneralNone, coSoundPingVolume] then SoundPingBus.Volume := Settings.GetIntegerOption(coSoundPingVolume) / 100;
    if Option in [coGeneralNone, coSoundMusicVolume] then SoundMusicBus.Volume := Settings.GetIntegerOption(coSoundMusicVolume) / 100;
    if Option in [coGeneralNone, coSoundGUISoundVolume] then SoundUIBus.Volume := Settings.GetIntegerOption(coSoundGUISoundVolume) / 100;
    // enable/disable (mute/unmute) settings
    if Option in [coGeneralNone, coSoundPlayMaster] then SoundMasterBus.Muted := not Settings.GetBooleanOption(coSoundPlayMaster);
    if Option in [coGeneralNone, coSoundPlayMusic] then SoundMusicBus.Muted := not Settings.GetBooleanOption(coSoundPlayMusic);
    if Option in [coGeneralNone, coSoundPlayEffects] then SoundEffectBus.Muted := not Settings.GetBooleanOption(coSoundPlayEffects);
    if Option in [coGeneralNone, coSoundPlayPings] then SoundPingBus.Muted := not Settings.GetBooleanOption(coSoundPlayPings);
    if Option in [coGeneralNone, coSoundPlayGUISound] then SoundUIBus.Muted := not Settings.GetBooleanOption(coSoundPlayGUISound);
  end
  else
  begin
    // volume settings for menu
    if Option in [coGeneralNone, coSoundMetaMasterVolume] then SoundMasterBus.Volume := Settings.GetIntegerOption(coSoundMetaMasterVolume) / 100;
    if Option in [coGeneralNone, coSoundMetaMusicVolume] then SoundMusicBus.Volume := Settings.GetIntegerOption(coSoundMetaMusicVolume) / 100;
    if Option in [coGeneralNone, coSoundMetaGUISoundVolume] then SoundUIBus.Volume := Settings.GetIntegerOption(coSoundMetaGUISoundVolume) / 100;
    // enable/disable (mute/unmute) settings
    if Option in [coGeneralNone, coSoundMetaPlayMaster] then SoundMasterBus.Muted := not Settings.GetBooleanOption(coSoundMetaPlayMaster);
    if Option in [coGeneralNone, coSoundMetaPlayMusic] then SoundMusicBus.Muted := not Settings.GetBooleanOption(coSoundMetaPlayMusic);
    if Option in [coGeneralNone, coSoundMetaPlayGUISound] then SoundUIBus.Muted := not Settings.GetBooleanOption(coSoundMetaPlayGUISound);
  end;
end;

procedure TGameStateManager.UpdateWindowPosition;
begin
  GameWindow.Top := TargetMonitor.Top + Max(0, (TargetMonitor.WorkAreaRect.Height - GameWindow.Height) div 2);
  GameWindow.Left := TargetMonitor.Left + Max(0, (TargetMonitor.WorkAreaRect.Width - GameWindow.Width) div 2);
end;

procedure TGameStateManager.Idle;
var
  GameState : TGameState;
  ComponentID : integer;
begin
  if Keyboard.Strg and Keyboard.Alt and Keyboard.KeyUp(TasteF11) then
  begin
    if IsWindowMode(wmClient) then
        SetIngameWindow
    else
        SetClientWindow;
  end;
  // safety, all meta client tutorial dialogs must be closable
  if Keyboard.KeyUp(TasteEsc) then
      DialogManager.CloseDialog(diMetaTutorial);

  DialogManager.Idle;
  if assigned(Account) then
      Account.Idle;

  for GameState in FCurrentStates do
  begin
    GameState.Idle;
  end;

  if assigned(GUI) then
  begin
    if GUI.IsMouseOverWritable then
    begin
      ComponentID := GUI.GetWritableUnderMouse.UID;
      if FLastClickable <> ComponentID then
          SoundManager.PlayHover;
      FLastClickable := ComponentID;

      FGameWindow.Cursor := HGeneric.TertOp<TCursor>(IsGameWindow, BaseConflict.Constants.Client.crIngameHover, System.UITypes.crIBeam);
    end
    else if GUI.IsMouseOverClickable then
    begin
      ComponentID := GUI.GetClickableUnderMouse.UID;
      if FLastClickable <> ComponentID then
          SoundManager.PlayHover;
      FLastClickable := ComponentID;

      FGameWindow.Cursor := HGeneric.TertOp<TCursor>(IsGameWindow, BaseConflict.Constants.Client.crIngameHover, System.UITypes.crHandPoint);
    end
    else if GUI.IsMouseOverHint and IsClientWindow then
    begin
      FGameWindow.Cursor := System.UITypes.crHelp;
      FLastClickable := -1;
    end
    else
    begin
      FGameWindow.Cursor := HGeneric.TertOp<TCursor>(IsGameWindow, BaseConflict.Constants.Client.crIngame, System.UITypes.crDefault);
      FLastClickable := -1;
    end;
  end;
end;

function TGameStateManager.IsClientWindow : Boolean;
begin
  Result := IsWindowMode(wmClient);
end;

function TGameStateManager.IsFullscreen : Boolean;
begin
  Result := (TargetMonitor.Width = GameWindow.Width) and (TargetMonitor.Height = GameWindow.Height);
end;

function TGameStateManager.IsGameWindow : Boolean;
begin
  Result := IsWindowMode(wmIngame);
end;

function TGameStateManager.IsWindowMode(WindowMode : EnumWindowMode) : Boolean;
begin
  Result := FWindowMode = WindowMode;
end;

procedure TGameStateManager.Minimize;
begin
  FGameWindow.WindowState := wsMinimized;
end;

procedure TGameStateManager.OnQueueError(ErrorCode : EnumErrorCode);
begin
  CurrentGameState.OnQueueError(ErrorCode);
end;

procedure TGameStateManager.RemoveGameState(GameStateName : string);
begin
  FStates.Remove(GameStateName);
end;

{ TGameStateCoreGame }

function TGameStateCoreGame.BuildGameInfo : TGameInformation;
var
  Token, scenario_uid : string;
  scenario_instance_league : integer;
  IsSandboxOverride : Boolean;
begin
  if Settings.GetBooleanOption(coDebugUseLocalTestServer) then
  begin
    Token := Settings.GetStringOption(coDebugLocalTestServerToken);
    TESTSERVER_SCENARIO_UID := HFileIO.ReadFromIni(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE), 'Server', 'TESTSERVER_SCENARIO_UID', TESTSERVER_SCENARIO_UID);
    scenario_uid := TESTSERVER_SCENARIO_UID;
    TESTSERVER_SENARIO_LEAGUE := HFileIO.ReadIntFromIni(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE), 'Server', 'TESTSERVER_SCENARIO_LEAGUE', TESTSERVER_SENARIO_LEAGUE);
    scenario_instance_league := TESTSERVER_SENARIO_LEAGUE;
    IsSandboxOverride := HFileIO.ReadBoolFromIni(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE), 'Server', 'TESTSERVER_SANDBOX_CONTROLS', False);
  end
  else
  begin
    if assigned(ServerGameData) then
    begin
      Token := ServerGameData.Data.secret_key;
      scenario_uid := ServerGameData.Data.scenario_uid;
      scenario_instance_league := ServerGameData.Data.scenario_instance_league;
    end
    else
    begin
      Token := FGameData.secret_key;
      scenario_uid := FGameData.scenario_uid;
      scenario_instance_league := FGameData.scenario_instance_league;
    end;
    IsSandboxOverride := False;
  end;
  Result := TGameInformation.Create;
  Result.Scenario := HScenario.ResolveScenario(scenario_uid, scenario_instance_league);
  Result.ScenarioUID := scenario_uid;
  Result.League := scenario_instance_league;
  Result.IsSandboxOverride := IsSandboxOverride;
end;

function TGameStateCoreGame.CheckAndProcessGameIsFinished : Boolean;
begin
  Result := False;
  if ClientGame.IsFinished then
  begin
    if Settings.GetBooleanOption(coDebugUseLocalTestServer) then
        Owner.CloseNoPrompt;

    if (ClientGame.GameState = gsCrashed) and assigned(ServerGameData) then
        ServerGameData.Crashed := True;

    if ClientGame.GameState = gsAborted then
        ServerGameData.Aborted := True;

    EnterMainMenu;
    Result := True;
  end;
end;

constructor TGameStateCoreGame.Create(Owner : TGameStateManager);
begin
  inherited Create(Owner);
  FGUIWarming := TTimer.CreatePaused(500);
  TGameStateComponentFeedback.Create(FStateEntity, self);
  TGameStateComponentSettings.Create(FStateEntity, self);
  TGameStateComponentHUDTooltip.Create(FStateEntity, self);
  TGameStateComponentCore.Create(FStateEntity, self);
  FFPSAverageSum := 0;
  FFPSAverageSamples := 0;
  FFPSLogTimer := TTimer.CreateAndStart(FPS_LOG_INTERVAL);
  FFPSLog := TList<RFPSLogData>.Create;
  FPerformanceMeasurementDuration := TTimer.Create(PERFORMANCE_ANALYSIS_DURATION);
end;

destructor TGameStateCoreGame.Destroy;
begin
  LeaveState;
  FGUIWarming.Free;
  FFPSLog.Free;
  FFPSLogTimer.Free;
  FPerformanceMeasurementDuration.Free;
  inherited;
end;

procedure TGameStateCoreGame.EnterMainMenu;
begin
  Owner.ChangeGameState(GAMESTATE_MAINMENU);
end;

procedure TGameStateCoreGame.EnterMainMenuFailed;
begin
  Owner.GetGameState<TGameStateMainMenu>(GAMESTATE_MAINMENU).GetComponent<TGameStateComponentStatistics>.ClearGameData;
  EnterMainMenu;
end;

procedure TGameStateCoreGame.EnterState;
begin
  inherited;
  Account.SuspendBackchannel;
  InitValues;

  InitFullscreenColorBlank;
  FGUIWarming.StartAndPause;

  // first create hud as game has to register some things in it
  FHUD := TIngameHUD.Create;
  BaseConflict.Globals.Client.HUD := FHUD;

  ClientGame := TClientGame.Create(BuildGameInfo(), FGameSocket, FAuthentificationToken, FTokenMapping);
  FGameSocket := nil;
  FTokenMapping := nil;
  FAuthentificationToken := '';
  Game := ClientGame;

  FHUD.IsSandbox := Game.GameInfo.IsSandbox;
  FHUD.IsSandboxControlVisible := Game.GameInfo.IsSandbox;
  FHUD.IsPvEAttack := Game.GameInfo.IsPvE and not Game.GameInfo.IsTutorial;
  FHUD.IsTeamMode := Game.GameInfo.IsDuo;
  InitScoreboard;
end;

procedure TGameStateCoreGame.LeaveState;
begin
  inherited;
  SendFPSLog;
  GUI.SetContext('hud', nil);
  // free game first as the game has to deregister from hud
  Game.Free;
  Game := nil;
  ClientGame := nil;

  BaseConflict.Globals.Client.HUD := nil;
  FreeAndNil(FHUD);

  ClipCursor(nil);
  GFXD.FPSCounter.FrameLimit := Settings.GetIntegerOption(coMenuLimitFramerate);
  ParticleEffectEngine.ClearParticles;
  FreeAndNil(FBlank);
end;

procedure TGameStateCoreGame.LogFPS;
var
  NewLog : RFPSLogData;
begin
  if FFPSLogTimer.Expired then
  begin
    NewLog.Timestamp := TimeManager.GetTimeStamp;
    NewLog.FPS := GFXD.FPS;
    FFPSLog.Add(NewLog);
    FFPSLogTimer.Start;
  end;
end;

procedure TGameStateCoreGame.LowerSettings;
begin
  GetComponent<TGameStateComponentSettings>.FSettings.GraphicsQuality := gqLow;
  GetComponent<TGameStateComponentSettings>.DeactivateAndSaveSettings;
  Owner.ShowError('§settings_message_low_performance_caption', '§settings_message_low_performance');
end;

procedure TGameStateCoreGame.PassGameData(GameSocket : TTCPClientSocketDeluxe; const AuthentificationToken : string; TokenMapping : TList<integer>);
begin
  FGameSocket := GameSocket;
  FTokenMapping := TokenMapping;
  FAuthentificationToken := AuthentificationToken;
end;

procedure TGameStateCoreGame.SendFPSLog;
var
  DataArray : TArray<TArray<int64>>;
  i : integer;
begin
  if FFPSLog.Count > 0 then
  begin
    try
      setLength(DataArray, FFPSLog.Count);
      for i := 0 to length(DataArray) - 1 do
          DataArray[i] := TArray<int64>.Create(FFPSLog[i].Timestamp, FFPSLog[i].FPS);
      AccountAPI.SendFPSLog(DataArray).Free;
    except
      // mute any errors
    end;
    FFPSLog.Clear;
  end;
end;

procedure TGameStateCoreGame.UpdateConfinedCursor;
var
  ConfinedCursorCliprect : TRect;
begin
  // confine cursor, because cursor clipping is a shared resource we try to brute force clip
  // it every frame to ensure it is confined, of course only when the form is active
  if Owner.GameWindow.Active then
  begin
    if Settings.GetBooleanOption(coGameplayClipCursor) and not FCursorClipped then
        FCursorClipped := True;
    if FCursorClipped then
    begin
      ConfinedCursorCliprect := Owner.GameWindow.ClientRect;
      ConfinedCursorCliprect.TopLeft := Owner.GameWindow.ClientToScreen(ConfinedCursorCliprect.TopLeft);
      ConfinedCursorCliprect.BottomRight := Owner.GameWindow.ClientToScreen(ConfinedCursorCliprect.BottomRight);
      ClipCursor(@ConfinedCursorCliprect);
    end;

    if not Settings.GetBooleanOption(coGameplayClipCursor) and FCursorClipped then
    begin
      FCursorClipped := False;
      ClipCursor(nil);
    end;
  end;
end;

procedure TGameStateCoreGame.UpdatePerformanceTest;
begin
  if FPerformanceMesurementActive then
  begin
    // detect graphics performance
    if FPerformanceMeasurementDuration.Expired then
    begin
      if (FFPSAverageSamples > 0) and (FFPSAverageSum / FFPSAverageSamples <= PERFORMANCE_ANALYSIS_THRESHOLD) then
        // performance is low
          LowerSettings;
      Settings.SetBooleanOption(coGraphicsPerformanceAnalysed, True);
      Settings.SaveSettings;
      FPerformanceMeasurementDuration.StartAndPause;
      FPerformanceMesurementActive := False;
    end
    else
    begin
      FFPSAverageSum := FFPSAverageSum + GFXD.FPS;
      inc(FFPSAverageSamples);
    end;
  end;
end;

procedure TGameStateCoreGame.Idle;
var
  {$IFDEF DEBUG}
  LMouseState : EnumKeyState;
  {$ENDIF}
  Nexus : TEntity;
  ClickRay : RRay;
  tempB : Boolean;
begin
  inherited;
  if not FSentInit or not FGUIWarming.Expired then
  begin
    FBlank.Size := GFXD.Settings.Resolution.Size;
    FBlank.Color := FBlank.Color.SetAlphaF(1 - HMath.Saturate(FGUIWarming.ZeitDiffProzent * 4 - 3));
    FBlank.AddRenderJob;
  end;
  if FScreenSwapWait = 0 then
  begin
    // we want to freeze in the loading screen, so first load everything (first idle of Game will freeze as well after this frame)
    Owner.SetIngameWindow;
    if assigned(FBlank) then
        FBlank.Size := GFXD.Settings.Resolution.Size;
  end
  else if FScreenSwapWait = 1 then
  begin
    PostEffects.Clear;
    PostEffects.LoadFromFile('PostEffects.fxs');

    Settings.FireOptionEvents(OPTIONS_POSTEFFECTS);

    GFXD.FPSCounter.FrameLimit := 0;
  end
  else if FScreenSwapWait = 2 then
  begin
    // now we can load the gui
    Owner.State := csCoreGame;
    GUI.SetContext('hud', FHUD);

    // loading is done, so disable menu music
    Owner.SwitchMenuMusic(mmNone);
  end
  else
  begin
    if FHUD.Resolution <> GFXD.Settings.Resolution.Size then
        FHUD.Resolution := GFXD.Settings.Resolution.Size;

    if not FSentInit and ClientGame.IsReady and (FScreenSwapWait > 5) then
    begin
      GlobalEventbus.Trigger(eiClientInit, []);
      FSentInit := True;
      FGUIWarming.Start;
      InitPerformanceTest;
    end;

    if not FSentReady and FSentInit and ClientGame.IsReady and (FScreenSwapWait > 5) and not HUD.IsTutorial then
    begin
      HUD.SendGameEvent(GAME_EVENT_CLIENT_READY);
      FSentReady := True;
    end;

    if CheckAndProcessGameIsFinished then
        exit;

    UpdateConfinedCursor;

    if Owner.GameWindow.Active and Owner.GameWindow.CursorInRenderpanel then
    begin
      ClickRay := GFXD.MainScene.Camera.Clickvector(Mouse.Position);

      if (Keyboard.HasAnyKeyActivity) or (Mouse.HasAnyButtonActivity) then
          GlobalEventbus.Trigger(eiKeybindingEvent, []);
      if not Mouse.DeltaPosition.IsZeroVector then GlobalEventbus.Trigger(eiMouseMoveEvent, [Mouse.Position, Mouse.DeltaPosition]);
      if Mouse.dZ <> 0 then GlobalEventbus.Trigger(eiMouseWheelEvent, [Mouse.dZ]);

      tempB := KeybindingManager.KeyIsDown(kbScoreboardHold) and not HUD.IsMenuOpen;
      if FHUD.ScoreboardVisible <> tempB then
          FHUD.ScoreboardVisible := tempB;
      if KeybindingManager.KeyUp(kbGUIToggle) then HUD.IsHUDVisible := not HUD.IsHUDVisible;
      if KeybindingManager.KeyUp(kbSandboxGUIToggle) then HUD.IsSandboxControlVisible := not HUD.IsSandboxControlVisible;
      // if someone accidentally hides the gui, esc should bring it back to him
      if KeybindingManager.KeyUp(kbMainCancel) then HUD.IsHUDVisible := True;

      if Game.IsSandbox then
      begin
        if KeybindingManager.KeyUp(kbCameraToggleRotation) then HUD.CameraRotate := not HUD.CameraRotate;
        if KeybindingManager.KeyUp(kbCaptureMode) then HUD.CaptureMode := not HUD.CaptureMode;
        if Keyboard.KeyUp(TastePunkt) and Keyboard.Strg then
        begin
          if Game.EntityManager.TryGetNexusByTeamID(ClientGame.CommanderManager.ActiveCommanderTeamID, Nexus) then
              HUD.CameraMoveTo(Nexus.DisplayPosition.XZ + Settings.GetVector2Option(coSandboxFinishCamOffset), 500);
        end;
      end;

      if KeybindingManager.KeyUp(kbDrawTerrainToggle) then ClientGame.ClientMap.DrawTerrain := not ClientGame.ClientMap.DrawTerrain;
      if KeybindingManager.KeyUp(kbDrawWaterToggle) then ClientGame.ClientMap.DrawWater := not ClientGame.ClientMap.DrawWater;
      if KeybindingManager.KeyUp(kbDrawVegetationToggle) then ClientGame.ClientMap.DrawVegetation := not ClientGame.ClientMap.DrawVegetation;
      if KeybindingManager.KeyUp(kbDeferredShadingToggle) then GFXD.Settings.DeferredShading := not GFXD.Settings.DeferredShading;
      if KeybindingManager.KeyUp(kbNormalmappingToggle) then GFXD.Settings.Normalmapping := not GFXD.Settings.Normalmapping;
      if KeybindingManager.KeyUp(kbShadowTechniqueToggle) then GFXD.MainScene.ShadowTechnique := HGeneric.TertOp<EnumShadowTechnique>(GFXD.MainScene.ShadowTechnique = EnumShadowTechnique.stNone, stShadowmapping, EnumShadowTechnique.stNone);

      {$IFDEF DEBUG}
      ClientGame.ClientMap.Terrain.RenderBrush(ClickRay);
      if Mouse.ButtonUp(mbLeft) then LMouseState := ksUp
      else if Mouse.ButtonDown(mbLeft) then LMouseState := ksDown
      else if Mouse.ButtonIsDown(mbLeft) then LMouseState := ksIsDown
      else LMouseState := ksIsUp;
      ClientGame.ClientMap.Terrain.Manipulate(ClickRay, not Mouse.DeltaPosition.IsZeroVector, Keyboard.Strg, LMouseState, Mouse.ButtonUp(mbRight));
      if KeybindingManager.KeyUp(kbTerrainEditor) then ClientGame.ClientMap.Terrain.ShowDebugForm;
      {$ENDIF}
    end;

    if FHUD.ShouldCloseSettings then
    begin
      Owner.DialogManager.CloseDialog(diSettings);
      FHUD.ShouldCloseSettings := False;
    end;
    if FHUD.IsSettingsOpen <> Owner.DialogManager.IsDialogVisible(diSettings) then
        FHUD.IsSettingsOpen := Owner.DialogManager.IsDialogVisible(diSettings);

    if FHUD.IsTechnicalPanelVisible <> Settings.GetBooleanOption(coGameplayShowTechnicalPanel) then
        FHUD.IsTechnicalPanelVisible := Settings.GetBooleanOption(coGameplayShowTechnicalPanel);

    if FHUD.ShowCardHotkeys <> Settings.GetBooleanOption(coGameplayShowDeckHotkeys) then
        FHUD.ShowCardHotkeys := Settings.GetBooleanOption(coGameplayShowDeckHotkeys);

    if FHUD.ShowCardNumericChargeProgress <> Settings.GetBooleanOption(coGameplayShowNumericChargeCooldown) then
        FHUD.ShowCardNumericChargeProgress := Settings.GetBooleanOption(coGameplayShowNumericChargeCooldown);

    FHUD.Idle;
    Game.Idle;

    LogFPS;
    UpdatePerformanceTest;
  end;

  if FScreenSwapWait < 10 then
  begin
    inc(FScreenSwapWait);
    HLog.Log('Swap in Gamestate: ' + self.ClassName + ', ' + IntToStr(FScreenSwapWait) + ', MemoryUsage: ' + HMemoryDebug.GetMemoryUsedFormated);
  end;
end;

procedure TGameStateCoreGame.InitFullscreenColorBlank;
begin
  FBlank.Free;
  FBlank := TVertexScreenAlignedQuad.Create(VertexEngine);
  FBlank.Size := GFXD.Settings.Resolution.Size;
  FBlank.Color := GFXD.MainScene.Backgroundcolor.SetAlphaF(1.0);
  FBlank.DrawOrder := 1000000;
  FBlank.DrawsAtStage := rsGUI;
  FBlank.AddRenderJob;
end;

procedure TGameStateCoreGame.InitPerformanceTest;
begin
  FFPSAverageSum := 0;
  FFPSAverageSamples := 0;
  FPerformanceMesurementActive := HUD.IsTutorial and not Settings.GetBooleanOption(coGraphicsPerformanceAnalysed);
  if FPerformanceMesurementActive then
      FPerformanceMeasurementDuration.Start;
end;

procedure TGameStateCoreGame.InitScoreboard;
var
  Player : RGameFoundPlayer;
  ScoreboardPlayer : RScoreboardPlayer;
  Left, Right : TList<RScoreboardPlayer>;
begin
  Left := TList<RScoreboardPlayer>.Create;
  Right := TList<RScoreboardPlayer>.Create;
  for Player in FGameData.players do
  begin
    ScoreboardPlayer := RScoreboardPlayer.Create(Player.Username, Player.deckname, Player.deck_icon);
    if Player.team_id = 1 then
        Left.Add(ScoreboardPlayer)
    else
        Right.Add(ScoreboardPlayer);
  end;
  FHUD.ScoreboardLeftTeam.Clear;
  FHUD.ScoreboardLeftTeam.AddRange(Left);
  FHUD.ScoreboardRightTeam.Clear;
  FHUD.ScoreboardRightTeam.AddRange(Right);
  Left.Free;
  Right.Free;
end;

procedure TGameStateCoreGame.InitValues;
begin
  FSentReady := False;
  FSentInit := False;
  ShowHealthbars := True;
  FScreenSwapWait := 0;
  FPerformanceMesurementActive := False;
end;

{ TGameStateMainMenu }

constructor TGameStateMainMenu.Create(Owner : TGameStateManager);
begin
  inherited Create(Owner);
  TGameStateComponentProfile.Create(FStateEntity, self);
  TGameStateComponentPlayerLevel.Create(FStateEntity, self);
  TGameStateComponentFeedback.Create(FStateEntity, self);
  TGameStateComponentFriendlist.Create(FStateEntity, self);
  TGameStateComponentQuests.Create(FStateEntity, self);
  TGameStateComponentDeckbuilding.Create(FStateEntity, self);
  TGameStateComponentCollection.Create(FStateEntity, self);
  TGameStateComponentMatchMaking.Create(FStateEntity, self);
  TGameStateComponentStatistics.Create(FStateEntity, self);
  TGameStateComponentShop.Create(FStateEntity, self);
  TGameStateComponentNotification.Create(FStateEntity, self);
  TGameStateComponentInventory.Create(FStateEntity, self);
  TGameStateComponentDashboard.Create(FStateEntity, self);
  TGameStateComponentSettings.Create(FStateEntity, self);
  TGameStateComponentMetaTutorial.Create(FStateEntity, self);
  TGameStateComponentLeaderboards.Create(FStateEntity, self);

  Owner.DialogManager.Subscribe(diPreloading, OnPreloadingDialogOpen);

  FUpdatePlayerTimer := TTimer.Create(CURRENT_PLAYER_ONLINE_UPDATE_INTERVAL_DASHBOARD);
  FLoadingTime := TTimer.Create(SLOW_LOADING_TIME);
  FPreloaderFailedBlock := TList<string>.Create;
end;

destructor TGameStateMainMenu.Destroy;
begin
  FreeAndNil(FLoadingTime);
  FreeAndNil(FUpdatePlayerTimer);
  FreeAndNil(FAssetPreloader);
  GUI.SetContext('menu', nil);
  GUI.SetContext('deckmanager', nil);
  Owner.DialogManager.UnSubscribe(diPreloading, OnPreloadingDialogOpen);
  FPreloaderFailedBlock.Free;
  inherited;
end;

procedure TGameStateMainMenu.EnterState;
begin
  inherited;
  IsLoading := False;
  // delayed enterstate, enterstate will be done in idle
  FScreenSwapWait := 0;
  InitAssetLoader;
end;

procedure TGameStateMainMenu.LeaveState;
begin
  inherited;
  GUI.SetContext('menu', nil);
  GUI.SetContext('deckmanager', nil);
end;

procedure TGameStateMainMenu.OnPreloadFileFailed(const FileName, ErrorMessage : string);
var
  FileExt : string;
begin
  FileExt := ExtractFileExt(FileName).ToLowerInvariant;
  // we don't want to spam us with repeated failures
  if not FPreloaderFailedBlock.Contains(FileExt) then
  begin
    AccountAPI.SendCustomBugReport('TGameStateLoadCoreGame.OnPreloadFileFailed: ' + FileName + ' Error: ' + ErrorMessage, '').Free;
    FPreloaderFailedBlock.Add(FileExt);
  end;
end;

procedure TGameStateMainMenu.OnPreloadingDialogOpen(Open : Boolean);
begin
  if not Open and not FFirstLoadDone then
  begin
    Account.CheckBackchannelOrActivateFallback;
    SoundManager.PlayClientStartUp;
    FFirstLoadDone := True;
  end;
end;

procedure TGameStateMainMenu.SetCardInstanceShowCase(const Value : TCardInstance);
begin
  if MainActionQueue.IsActive then FCardInstanceShowcase := Value
  else
  begin
    if assigned(Value) then CardShowcase := nil;
    TActionSetVariable<TCardInstance>.Create(Value, CardInstanceShowcase, SetCardInstanceShowCase).Deploy;
  end;
end;

procedure TGameStateMainMenu.SetCardShowCase(const Value : TCardInfo);
begin
  if MainActionQueue.IsActive then FCardShowcase := Value
  else
  begin
    if assigned(Value) then CardInstanceShowcase := nil;
    TActionSetVariable<TCardInfo>.Create(Value, CardShowcase, SetCardShowCase).Deploy;
  end;
end;

procedure TGameStateMainMenu.SetCurrentMenu(const Value : EnumMenu);
begin
  if MainActionQueue.IsActive then
  begin
    FCurrentMenu := Value;
    if FCurrentMenu = mtDeck then Owner.SwitchMenuMusic(mmDeckbuilding)
    else Owner.SwitchMenuMusic(mmMenu);
  end
  else
  begin
    TActionSetVariable<EnumMenu>.Create(Value, CurrentMenu, SetCurrentMenu).Deploy;
    case Value of
      mtGame : QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_NAVIGATE_PLAY);
      mtDeck : QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_NAVIGATE_DECKBUILDER);
      mtShop : QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_NAVIGATE_SHOP);
      mtCollection : QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_NAVIGATE_COLLECTION);
    end;
  end;
end;

procedure TGameStateMainMenu.SetIsLoading(const Value : Boolean);
begin
  FIsLoading := Value;
end;

procedure TGameStateMainMenu.SetIsLoadingSlow(const Value : Boolean);
begin
  FIsLoadingSlow := Value;
end;

procedure TGameStateMainMenu.SetIsPreLoading(const Value : Boolean);
begin
  FIsPreLoading := Value;
  if not Value and Owner.IsApiReady then
      Owner.DialogManager.CloseDialog(diPreloading);
end;

procedure TGameStateMainMenu.Idle;
begin
  inherited;
  if assigned(FAssetPreloader) then
      FAssetPreloader.DoWork;
  if not Account.IsConnected then
  begin
    // we lost the connection to the backchannel, so everything is unstable
    Owner.ChangeGameState(GAMESTATE_RECONNECT);
    exit;
  end;

  if FScreenSwapWait = 0 then
  begin
    // first get a clean state, before go into freeze loading
    Owner.SetClientWindow;
  end
  else if FScreenSwapWait = 1 then
  begin
    // music before all other to show responsiveness
    Owner.SwitchMenuMusic(mmMenu);
  end
  else if FScreenSwapWait = 2 then
  begin
    // Server game data is only set at entering this state, when coming from core game, then we show rewards and statistics
    if assigned(ServerGameData) then
    begin
      InitDialogs;

      if ServerGameData.Crashed then
      begin
        Account.ResumeBackchannel;
        CurrentMenu := mtGame;
        Owner.ShowErrorcode(ecConnectionLostToGameServerDuringGame);
      end
      else if ServerGameData.Aborted then
      begin
        Account.ResumeBackchannel;
        CurrentMenu := mtGame;
        Owner.ShowErrorcode(ecGameAbortedAnotherPlayerLostConnection);
      end
      else // tutorial skips statistics
        if ServerGameData.ScenarioInstance.Scenario.UID = SCENARIO_PVE_TUTORIAL then
        begin
          // skipping statistics have to resume the backchannel
          Account.ResumeBackchannel;
          CurrentMenu := mtStart;
          GetComponent<TGameStateComponentProfile>.TutorialFinished;
        end
        else
        begin
          CurrentMenu := mtGameRewards;
          GetComponent<TGameStateComponentStatistics>.Show;
        end;
    end
    else
    begin
      Account.ResumeBackchannel;
      CurrentMenu := mtStart;
    end;
    CardShowcase := nil;

    GUI.SetContext('menu', self);
    GUI.SetContext('deckmanager', Deckbuilding);
  end
  else if FScreenSwapWait = 3 then
  begin
    Owner.ShowWindow;
    SplashForm.Hide;
    Owner.State := csMainMenu;
  end
  else
  begin
    if FUpdatePlayerTimer.Expired and (CurrentMenu = mtStart) then
    begin
      Account.UpdateCurrentPlayersOnline;
      FUpdatePlayerTimer.Start;
    end;
    if FLoadingTime.Expired and not IsLoadingSlow then
        IsLoadingSlow := True;

    // normal idle
    ServerState.Idle;
    UserProfile.Idle;
    if IsPreLoading and FAssetPreloader.Done then
    begin
      IsPreLoading := False;
      FreeAndNil(FAssetPreloader);
    end;

    if not ServerState.MaintenanceCanEnterQueues and (CurrentMenu = mtGame) then
        CurrentMenu := mtStart;

    if ServerState.IsMaintenanceActive and not Settings.GetBooleanOption(coGeneralBypassMaintenance) then
        Owner.ChangeGameState(GAMESTATE_MAINTENANCE);
  end;
  if FScreenSwapWait < 10 then
  begin
    inc(FScreenSwapWait);
    HLog.Log('Swap in Gamestate: ' + self.ClassName + ', ' + IntToStr(FScreenSwapWait) + ', MemoryUsage: ' + HMemoryDebug.GetMemoryUsedFormated);
  end;
end;

procedure TGameStateMainMenu.InitAssetLoader;
begin
  if not assigned(FAssetPreloader) then
  begin
    FAssetPreloader := TAssetPreloader.Create(False);
    FAssetPreloader.OnPreloadFileFailed := OnPreloadFileFailed;

    if USE_ASSET_PRELOADER_CACHE then
    begin
      if FileExists(AbsolutePath(PRELOADER_CACHE_FILENAME)) then
          FAssetPreloader.LoadCacheFromFile(AbsolutePath(PRELOADER_CACHE_FILENAME));
    end
    else
        FAssetPreloader.CacheEnabled := False;

    FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GUI));
    Owner.DialogManager.OpenDialog(diPreloading);
    IsPreLoading := True;
    IsLoadingSlow := False;
    FLoadingTime.Start;
  end;
end;

procedure TGameStateMainMenu.InitDialogs;
begin
  Owner.DialogManager.CloseAllDialogs;
  if GetComponent<TGameStateComponentInventory>.HasDraftbox then
      Owner.DialogManager.OpenDialog(diDraftbox);
end;

{ TGameStateLoadCoreGame }

procedure TGameStateLoadCoreGame.ConnectionToGameServerLost;
begin
  ShutdownIfTestserver('Connection to server lost!');
  Owner.ShowErrorcode(ecConnectionLostToGameServerDuringLoading);
  EnterMainMenuFailed;
end;

procedure TGameStateLoadCoreGame.ConnectionToGameServerRefused(ErrorCode : integer; const ErrorMessage : string);
begin
  ShutdownIfTestserver('Server refused connection: ' + IntToStr(ErrorCode) + ' ' + ErrorMessage);
  AccountAPI.SendCustomBugReport('Server refused connection: ' + IntToStr(ErrorCode) + ' ' + ErrorMessage, '').Free;
  HLog.Write(elInfo, 'Server refused connection (%s)!', [FGameSocket.RemoteInetAddress.IpAddress]);
  Owner.ShowErrorcode(EnumErrorCode(ErrorCode));
  EnterMainMenuFailed;
end;

procedure TGameStateLoadCoreGame.ConnectToGameServer;
begin
  try
    FGameSocket := TTCPClientSocketDeluxe.Create(RInetAddress.CreateByUrl(FGameData.gameserver_ip, FGameData.gameserver_port));
  except
    on e : ENetworkException do
    begin
      ShutdownIfTestserver('Connection to server failed!');
      AccountAPI.SendCustomBugReport(Format('Connection to game server failed: %s:%d - %s', [FGameData.gameserver_ip, FGameData.gameserver_port, e.ToString]), '').Free;
      HLog.Write(elInfo, 'Could not connect to gameserver (%s)!', [FGameData.gameserver_ip]);
      if e is EConnectionFailedException then
          Owner.ShowErrorcode(ecConnectionToGameServerNotPossiblePorts)
      else
          Owner.ShowErrorcode(ecConnectionToGameServerNotPossible);
      EnterMainMenuFailed;
      exit;
    end;
  end;
  SendAuthentification;
end;

constructor TGameStateLoadCoreGame.Create(Owner : TGameStateManager);
begin
  inherited Create(Owner);
  FMinimumLoadingTime := TTimer.Create(MINIMUM_LOADING_TIME * 1000);
  FLoadingTime := TTimer.Create(1000);
  FPreloaderFailedBlock := TList<string>.Create;
  FFirstLoading := True;
end;

destructor TGameStateLoadCoreGame.Destroy;
begin
  GUI.SetContext('loading', nil);
  FMinimumLoadingTime.Free;
  FLoadingTime.Free;
  FPreloaderFailedBlock.Free;
  inherited;
end;

procedure TGameStateLoadCoreGame.EnterCore;
begin
  Owner.GetGameState<TGameStateCoreGame>(GAMESTATE_INGAME).PassGameData(FGameSocket, FAuthentificationToken, FTokenMapping);
  FTokenMapping := nil;
  FGameSocket := nil;
  Owner.ChangeGameState(GAMESTATE_INGAME);
end;

procedure TGameStateLoadCoreGame.EnterMainMenu;
begin
  Owner.ChangeGameState(GAMESTATE_MAINMENU);
end;

procedure TGameStateLoadCoreGame.EnterMainMenuFailed;
begin
  Owner.GetGameState<TGameStateMainMenu>(GAMESTATE_MAINMENU).GetComponent<TGameStateComponentStatistics>.ClearGameData;
  EnterMainMenu;
end;

procedure TGameStateLoadCoreGame.EnterState;
begin
  inherited;
  FState := _('§loading_initializing');
  FScreenSwapWait := 0;
  FSlideOffset := random(TUTORIAL_SLIDE_COUNT);
  FSlideIndex := FSlideOffset;
  FLoadingStage := lsMatch;
  FProgress := 0;
  if Settings.GetBooleanOption(coDebugUseLocalTestServer) then
  begin
    FGameData.secret_key := Settings.GetStringOption(coDebugLocalTestServerToken);
    FGameData.gameserver_ip := Settings.GetStringOption(coDebugLocalTestServerIP);
    FGameData.gameserver_port := TESTSERVERGAMEPORT;
    TESTSERVER_SCENARIO_UID := HFileIO.ReadFromIni(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE), 'Server', 'TESTSERVER_SCENARIO_UID', TESTSERVER_SCENARIO_UID);
    FGameData.scenario_uid := TESTSERVER_SCENARIO_UID;
    FGameData.scenario_instance_league := TESTSERVER_SENARIO_LEAGUE;
    self.GameData := FGameData;
  end;

  if HScenario.IsTutorial(FGameData.scenario_uid) then
  begin
    FSlideOffset := 0;
    SlideIndex := 1;
    Stage := lsHint;
  end;

  ConnectToGameServer;
end;

procedure TGameStateLoadCoreGame.GameWasAborted;
begin
  ShutdownIfTestserver('Game has been aborted.');
  ServerGameData.Aborted := True;
  EnterMainMenu;
end;

procedure TGameStateLoadCoreGame.Idle;
var
  FileInfo : TAssetPreloaderFileInfo;
begin
  inherited;

  if FScreenSwapWait = 0 then
  begin
  end
  else if FScreenSwapWait = 1 then
  begin
    // and swap to fullscreen afterwards, preventing freeze in not rendered full screen
    Owner.SetIngameWindow;
  end
  else if FScreenSwapWait = 2 then
  begin
    // now load gui
    Owner.State := csLoadCoreGame;
    GUI.SetContext('loading', self);
  end
  else if FScreenSwapWait = 3 then
  begin
    // now load sound after visuals are correct
    Owner.SwitchMenuMusic(mmLoading);
  end
  else if FScreenSwapWait = 4 then
  begin
    // after view is ready, first freeze to collect file infos
    if not Settings.GetBooleanOption(coDebugSkipLoadingScreen) then
    begin
      InitAssetLoader;
      FMinimumLoadingTime.Start;
    end
    else
        FMinimumLoadingTime.Expired := True;
    if Stage = lsHint then
        FLoadingTime.SetZeitDiffProzent(MATCH_TIME)
    else
        FLoadingTime.Start;
  end
  else if FScreenSwapWait = 7 then
  begin
    if Settings.GetBooleanOption(coMenuBringToFrontOnMatchFound) then
        FOwner.BringToFront;
  end
  else
  begin
    if (Stage = lsMatch) and (FLoadingTime.ZeitDiffProzent < MATCH_TIME) then
        SlideIndex := 0
    else
    begin
      Stage := lsHint;
      SlideIndex := Max(0, (((trunc(FLoadingTime.ZeitDiffProzent - MATCH_TIME) div SLIDE_TIME) + FSlideOffset) mod TUTORIAL_SLIDE_COUNT)) + 1;
    end;

    // now everything should be settled, start loading
    if assigned(FAssetPreloader) then
    begin
      FAssetPreloader.DoWork;

      Progress := Max(Progress, Min(FAssetPreloader.Progress, FMinimumLoadingTime.ZeitDiffProzent));

      UpdateLoadingState;

      // detect preloader to got stuck, it should have loaded at least one file
      // to give collect jobs a bit time, we wait until minimumloading time is expired for stuck detection
      if not FAssetPreloader.Done and FAssetPreloader.IsStuck then
      begin
        HLog.Log('Preloader got stuck, skipping loading screen...');
        HLog.Log('%d / %d bytes loaded', [FAssetPreloader.FilesDoneSize, FAssetPreloader.TotalFileSize]);
        if FAssetPreloader.TryGetLastLoaded(FileInfo) then
            HLog.Log('Preloader got stuck at file %s', [FileInfo.FileName])
        else
            HLog.Log('Preloader got stuck without file info.');
        HLog.Log('%d jobs were still waiting.', [FAssetPreloader.PendingJobs]);
        AccountAPI.SendCustomBugReport('Preloader got stuck.', HLog.ReadLog).Free;
        FreeAndNil(FAssetPreloader);
      end
    end;

    // if loading done, start game
    if (not assigned(FAssetPreloader) or FAssetPreloader.Done) and FMinimumLoadingTime.Expired and assigned(FTokenMapping) then
        EnterCore;
  end;
  if FScreenSwapWait < 10 then
  begin
    inc(FScreenSwapWait);
    HLog.Log('Swap in Gamestate: ' + self.ClassName + ', ' + IntToStr(FScreenSwapWait) + ', MemoryUsage: ' + HMemoryDebug.GetMemoryUsedFormated);
  end;

  ProcessGameServerMessages;
end;

procedure TGameStateLoadCoreGame.LeaveState;
begin
  inherited;
  GUI.SetContext('loading', nil);
  FirstLoading := False;
  FreeAndNil(FAssetPreloader);
end;

procedure TGameStateLoadCoreGame.OnPreloadFileFailed(const FileName, ErrorMessage : string);
var
  FileExt : string;
begin
  FileExt := ExtractFileExt(FileName).ToLowerInvariant;
  // we don't want to spam us with repeated failures
  if not FPreloaderFailedBlock.Contains(FileExt) then
  begin
    AccountAPI.SendCustomBugReport('TGameStateLoadCoreGame.OnPreloadFileFailed: ' + FileName + ' Error: ' + ErrorMessage, '').Free;
    FPreloaderFailedBlock.Add(FileExt);
  end;
end;

procedure TGameStateLoadCoreGame.ProcessGameServerMessages;
var
  DataPacket : TDataPacket;
  ErrorCode : integer;
  ErrorMessage : string;
begin
  if assigned(FGameSocket) then
  begin
    while FGameSocket.IsDataPacketAvailable do
    begin
      DataPacket := FGameSocket.ReceiveDataPacket;
      case DataPacket.Command of
        NET_ASSIGNED_PLAYER :
          begin
            FTokenMapping := DataPacket.ReadList<integer>;
          end;
        NET_SECURITY_ERROR :
          begin
            ErrorCode := DataPacket.Read<integer>;
            ErrorMessage := DataPacket.ReadString;
            ConnectionToGameServerRefused(ErrorCode, ErrorMessage);
            DataPacket.Free;
            exit;
          end;
        NET_SERVER_GAME_ABORTED :
          begin
            GameWasAborted;
            DataPacket.Free;
            exit;
          end;
      end;
      DataPacket.Free;
    end;
    if (FGameSocket.Status = TCPStDisconnected) then
    begin
      HLog.Write(elInfo, 'Lost connection to gameserver (%s)!', [FGameSocket.RemoteInetAddress.IpAddress]);
      ConnectionToGameServerLost;
      exit;
    end;
  end;
end;

procedure TGameStateLoadCoreGame.SendAuthentification;
var
  SendData : TCommandSequence;
begin
  SendData := TCommandSequence.Create(NET_HELLO_SERVER);
  SendData.AddData(FAuthentificationToken);
  FGameSocket.SendData(SendData);
  SendData.Free;
end;

procedure TGameStateLoadCoreGame.SetFirstLoading(const Value : Boolean);
begin
  FFirstLoading := Value;
end;

procedure TGameStateLoadCoreGame.SetGameData(const Value : RGameFoundData);
begin
  FGameData := Value;
  FAuthentificationToken := FGameData.secret_key;
end;

procedure TGameStateLoadCoreGame.SetLoadingStage(const Value : EnumLoadingStage);
begin
  FLoadingStage := Value;
end;

procedure TGameStateLoadCoreGame.SetProgress(const Value : single);
begin
  FProgress := Value;
end;

procedure TGameStateLoadCoreGame.SetSlideIndex(const Value : integer);
begin
  FSlideIndex := Value;
end;

procedure TGameStateLoadCoreGame.SetState(const Value : string);
begin
  FState := Value;
end;

procedure TGameStateLoadCoreGame.ShutdownIfTestserver(const ErrorMessage : string);
begin
  if Settings.GetBooleanOption(coDebugUseLocalTestServer) then
  begin
    PreventIdle := True;
    MessageDlg(ErrorMessage, TMsgDlgType.mtError, [mbOK], 0);
    ReportMemoryLeaksOnShutdown := False;
    halt;
  end;
end;

procedure TGameStateLoadCoreGame.UpdateLoadingState;
var
  AssetType : EnumAssetCategory;
begin
  if assigned(FAssetPreloader) then
  begin
    if FAssetPreloader.Done then
        State := _('§loading_finalizing')
    else
    begin
      AssetType := EnumAssetCategory(round(FAssetPreloader.Progress * ord(high(EnumAssetCategory))));
      State := _('§loading_asset_type_' + HRTTi.EnumerationToString<EnumAssetCategory>(AssetType));
    end;
  end;
end;

procedure TGameStateLoadCoreGame.InitAssetLoader;
const // all Data in directories mentioned in PRELOADASSETS, are preloaded bevor game will start
  PRELOADASSETS : array [0 .. 9] of string = (
    PATH_SCRIPT,
    PATH_PRECOMPILEDSHADER,
    PATH_PRECOMPILEDSHADERCACHE,
    PATH_GRAPHICS_EFFECTS,
    PATH_GRAPHICS_ENVIRONMENT,
    PATH_GRAPHICS_GAMEPLAY,
    PATH_HUD,
    PATH_GUI_SHARED,
    PATH_GRAPHICS_UNITS + 'Neutral\',
    PATH_GRAPHICS_UNITS + 'Shared\'
    );
  TUTORIAL_DECK_UIDS : array [0 .. 5] of string = (
    '4a3d81c7-8c6b-454d-9469-95f6cf394c9b', // Footman Drop
    '51c25adb-3f4b-4e89-a972-15c2080933b9', // Archer Drop
    '21780eb8-3d2c-4c97-b279-59971475f3f8', // Defender Drop
    'ad3f1e1f-8c32-444e-acdc-9e01416890a1', // Avenger Drop
    'd6775352-3586-4a2d-af0f-b3149d59dbec', // Ballista Drop
    '5f0ce2b0-9e9b-4d1e-8c73-b55a7dd07963'  // HeavyGunner Drop
    );
  SAPLING_UIDS : array [0 .. 1] of string = (
    '67e7217d-4b1a-4366-a3e5-b71bca952d1a', // Sapling Drop
    'e1eb10e7-6dae-420d-9ac7-49a80697f5cb'  // Snow Sapling Drop
    );
var
  Item, Card : string;
  ScenarioMetaInfo : TScenarioMetaInfo;
  Player : RGameFoundPlayer;
  CardInfo : TCardInfo;
  i : integer;
begin
  // init preloader
  FAssetPreloader := TAssetPreloader.Create(True);
  FAssetPreloader.OnPreloadFileFailed := OnPreloadFileFailed;
  if USE_ASSET_PRELOADER_CACHE then
  begin
    if FileExists(AbsolutePath(PRELOADER_CACHE_FILENAME)) then
        FAssetPreloader.LoadCacheFromFile(AbsolutePath(PRELOADER_CACHE_FILENAME));
  end
  else
      FAssetPreloader.CacheEnabled := False;

  for Item in PRELOADASSETS do
  begin
    FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(Item));
  end;

  // load correct map
  ScenarioMetaInfo := HScenario.ResolveScenario(GameData.scenario_uid, GameData.scenario_instance_league);
  if assigned(ScenarioMetaInfo) and (ScenarioMetaInfo.MapName = MAP_DOUBLE) then
      FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_MAP + '\' + MAP_DOUBLE))
  else
      FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_MAP + '\' + MAP_SINGLE));

  if HScenario.IsSandbox(GameData.scenario_uid) then
  begin
    FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GRAPHICS_UNITS));
  end
  else
  begin
    // load tutorial deck if tutorial
    if HScenario.IsTutorial(GameData.scenario_uid) then
    begin
      for i := 0 to length(TUTORIAL_DECK_UIDS) - 1 do
        if CardInfoManager.TryResolveCardUID(TUTORIAL_DECK_UIDS[i], 1, 1, CardInfo) then
            FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GRAPHICS + CardInfo.SkinnedUnitFilename + '\'));
    end;

    // load pve-stuff if pve
    if HScenario.IsPvEScenario(GameData.scenario_uid) then
    begin
      FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GRAPHICS_UNITS + 'Colorless\'));
      FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GRAPHICS_UNITS + 'Scenario\'));
    end;

    // load needed units
    for Player in GameData.players do
    begin
      for Card in Player.Cards do
        if CardInfoManager.TryResolveCardUID(Card, MAX_LEAGUE, MAX_LEVEL, CardInfo) and not CardInfo.IsSpell then
        begin
          FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GRAPHICS + CardInfo.SkinnedUnitFilename.Replace(FILE_IDENTIFIER_GOLEMS + '\' + FILE_IDENTIFIER_GOLEMS, 'Colorless\') + '\'));
        end;
    end;
    // sapling is summoned by other units, so preload him always
    for i := 0 to length(SAPLING_UIDS) - 1 do
      if CardInfoManager.TryResolveCardUID(SAPLING_UIDS[i], 1, 1, CardInfo) then
          FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GRAPHICS + CardInfo.SkinnedUnitFilename + '\'));
  end;

  // load gui stuff
  FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GUI + 'Spelltarget\'));
  FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GUI + 'MainMenu\Shared\Card\'));
  FAssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GUI + PATH_GUI_RELATIVE_SHARED_CARD_ICONS_PATH));
end;

{ TGameStateComponentFriendlist }

procedure TGameStateComponentFriendlist.AddNewFriend;
var
  FriendID : integer;
begin
  if TryStrToInt(NewFriendID, FriendID) then
  begin
    Friendlist.AddUserToFriendlist(FriendID);
    QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_ADD_FRIEND);
    NewFriendID := '';
    Parent.Owner.DialogManager.CloseDialog(diFriendInvite);
  end
  else Parent.Owner.ShowErrorcode(ecFriendInviteFailedUnknownFriendID);
end;

constructor TGameStateComponentFriendlist.Create(Owner : TEntity; Parent : TGameState);
begin
  FPassive := True;
  inherited Create(Owner, Parent);
end;

destructor TGameStateComponentFriendlist.Destroy;
begin
  GUI.SetContext('friendlist', nil);
  inherited;
end;

function TGameStateComponentFriendlist.GetFriendlist : TFriendlist;
begin
  Result := BaseConflict.Api.Chat.Friendlist;
end;

function TGameStateComponentFriendlist.GetFriends : IDataQuery<TPerson>;
begin
  Result := Friendlist.Friends.Query.OrderBy('-IsOnline');
end;

function TGameStateComponentFriendlist.GetIncomingRequests : IDataQuery<TFriendRequest>;
begin
  Result := Friendlist.Requests.Query.Filter(F('IsIncoming') = True);
end;

function TGameStateComponentFriendlist.GetOutgoingRequests : IDataQuery<TFriendRequest>;
begin
  Result := Friendlist.Requests.Query.Filter(F('IsIncoming') = False);
end;

function TGameStateComponentFriendlist.GetRequests : IDataQuery<TFriendRequest>;
begin
  Result := Friendlist.Requests.Query.OrderBy('-IsIncoming');
end;

procedure TGameStateComponentFriendlist.Initialize;
begin
  if assigned(Friendlist) then
  begin
    Friendlist.OnFriendRequest := OnFriendRequest;
    Friendlist.Friends.OnChange := UpdateFriendlist;
    Friendlist.Requests.OnChange := UpdateFriendInvites;
    Friendlist.OwnStatus := csOnline;
    GUI.SetContext('friendlist', self);
    inherited;
  end;
end;

procedure TGameStateComponentFriendlist.InviteFriendByProposal(const FriendProposal : TFriendProposal);
begin
  FriendProposal.SendRequest;
  Parent.Owner.DialogManager.CloseDialog(diFriendInvite);
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_ADD_FRIEND);
end;

procedure TGameStateComponentFriendlist.OnFriendRequest(const FriendRequest : TFriendRequest);
begin
  if FriendRequest.IsIncoming then
      Parent.GetComponent<TGameStateComponentNotification>.AddFriendRequest(FriendRequest);
end;

procedure TGameStateComponentFriendlist.OpenChat(const Friend : TPerson);
begin
  if assigned(ChatSystem) then
  begin
    if SteamUtils.IsOverlayEnabled then
        ChatSystem.SendPrivateMessage(Friend, '')
    else
        Parent.Owner.ShowErrorcode(ecSteamOverlayDisabled);
  end;
end;

procedure TGameStateComponentFriendlist.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('friendlist', self);
end;

procedure TGameStateComponentFriendlist.ParentLeft;
begin
  inherited;
  GUI.SetContext('friendlist', nil);
end;

procedure TGameStateComponentFriendlist.RemoveFriend(const Friend : TPerson);
begin
  Friendlist.RemoveFriendFromList(Friend);
end;

procedure TGameStateComponentFriendlist.SetFriendlist(const Value : TFriendlist);
begin
  // only for notifications
end;

procedure TGameStateComponentFriendlist.SetFriends(const Value : IDataQuery<TPerson>);
begin
  // do nothing as this is only a notification method
end;

procedure TGameStateComponentFriendlist.SetIncomingRequests(const Value : IDataQuery<TFriendRequest>);
begin
  // do nothing as this is only a notification method
end;

procedure TGameStateComponentFriendlist.SetIsVisible(const Value : Boolean);
begin
  FIsVisible := Value;
end;

procedure TGameStateComponentFriendlist.SetNewFriendID(const Value : string);
begin
  FNewFriend := Value;
end;

procedure TGameStateComponentFriendlist.SetOutgoingRequests(const Value : IDataQuery<TFriendRequest>);
begin
  // do nothing as this is only a notification method
end;

procedure TGameStateComponentFriendlist.SetRequests(const Value : IDataQuery<TFriendRequest>);
begin
  // do nothing as this is only a notification method
end;

procedure TGameStateComponentFriendlist.UpdateFriendInvites(Sender : TUltimateList<TFriendRequest>; Items : TArray<TFriendRequest>; Action : EnumListAction; Indices : TArray<integer>);
begin
  // notify gui to update
  Requests := nil;
  IncomingRequests := nil;
  OutgoingRequests := nil;
end;

procedure TGameStateComponentFriendlist.UpdateFriendlist(Sender : TUltimateList<TPerson>; Items : TArray<TPerson>; Action : EnumListAction; Indices : TArray<integer>);
begin
  // notify gui to update
  Friends := nil;
end;

{ TGameStateComponent }

constructor TGameStateComponent.Create(Owner : TEntity; Parent : TGameState; IsDefault : Boolean);
begin
  inherited Create(Owner);
  FDefault := IsDefault;
  FParent := Parent;
  FParent.AddGameStateComponent(self);
end;

procedure TGameStateComponent.Activate;
begin
  SetActive(True);
end;

procedure TGameStateComponent.Deactivate;
begin
  SetActive(False);
end;

function TGameStateComponent.GetActive : Boolean;
begin
  Result := FPassive or FActive;
end;

procedure TGameStateComponent.GUIEventHandler(const Sender : RGUIEvent);
begin
  // only a placeholder
end;

procedure TGameStateComponent.Idle;
begin
  if not IsInitialized then Initialize;
end;

procedure TGameStateComponent.Initialize;
begin
  FInitialized := True;
end;

procedure TGameStateComponent.OnQueueError(ErrorCode : EnumErrorCode);
begin

end;

procedure TGameStateComponent.ParentEntered;
begin

end;

procedure TGameStateComponent.ParentLeft;
begin

end;

procedure TGameStateComponent.SetActive(const Value : Boolean);
begin
  if FPassive then exit;
  if Value <> FActive then
  begin
    FActive := Value;
    if FActive then Activate
    else Deactivate;
  end;
end;

{ TGameState }

procedure TGameState.AddGameStateComponent(Component : TGameStateComponent);
var
  i : integer;
begin
  for i := 0 to FComponents.Count - 1 do
    if FComponents[i].ClassType = Component.ClassType then raise EInvalidOpException.Create('TGameState.AddGameStateComponent: Each GameStateComponent must be unique for a GameState!');
  FComponents.Add(Component);
end;

constructor TGameState.Create(Owner : TGameStateManager);
begin
  FOwner := Owner;
  FComponents := TList<TGameStateComponent>.Create();
  FStateEntity := TEntity.Create(GlobalEventbus);
end;

destructor TGameState.Destroy;
begin
  FStateEntity.Free;
  FComponents.Free;
  inherited;
end;

procedure TGameState.EnterState;
var
  i : integer;
begin
  HLog.Log('Entered Gamestate: ' + self.ClassName);
  for i := 0 to FComponents.Count - 1 do
      FComponents[i].ParentEntered;
end;

function TGameState.GetComponent<T> : T;
var
  i : integer;
begin
  Result := nil;
  for i := 0 to FComponents.Count - 1 do
    if FComponents[i] is T then exit(FComponents[i] as T);
  assert(False, 'TGameState.GetComponent<' + T.ClassName + '>: Did not found matching component!');
end;

procedure TGameState.GUIEventHandler(const Sender : RGUIEvent);
begin
  // empty placeholder for overriding
end;

procedure TGameState.GUIEventHandlerRecursion(const Sender : RGUIEvent);
var
  i : integer;
begin
  for i := 0 to FComponents.Count - 1 do
    if FComponents[i].IsInitialized then FComponents[i].GUIEventHandler(Sender);
  GUIEventHandler(Sender);
end;

procedure TGameState.Idle;
var
  i : integer;
begin
  for i := 0 to FComponents.Count - 1 do
      FComponents[i].Idle;
end;

procedure TGameState.LeaveState;
var
  i : integer;
begin
  Owner.State := csNone;
  HLog.Log('Left Gamestate: ' + self.ClassName);
  for i := 0 to FComponents.Count - 1 do
      FComponents[i].ParentLeft;
end;

procedure TGameState.OnQueueError(ErrorCode : EnumErrorCode);
var
  i : integer;
begin
  for i := 0 to FComponents.Count - 1 do
    if FComponents[i].IsInitialized then FComponents[i].OnQueueError(ErrorCode);
end;

procedure TGameState.SetComponentActive(Component : CGameStateComponent; Disable : Boolean);
var
  i : integer;
begin
  for i := 0 to FComponents.Count - 1 do
      FComponents[i].SetActive(False);
  for i := 0 to FComponents.Count - 1 do
  begin
    if FComponents[i] is Component then FComponents[i].SetActive(not Disable);
    if Disable and FComponents[i].IsDefault then FComponents[i].SetActive(True);
  end;
end;

{ TGameStateComponentMatchMaking }

procedure TGameStateComponentMatchMaking.ChooseScenario(const Scenario : TScenario);
var
  ScenarioInstance : TScenarioInstance;
  i : integer;
begin
  ScenarioInstance := nil;
  if assigned(Scenario) then
  begin
    ScenarioInstance := Scenario.LevelsOfDifficulty.First;
    for i := 0 to Scenario.LevelsOfDifficulty.Count - 1 do
      if Scenario.LevelsOfDifficulty[i].League = FLastChosenDifficulty then
          ScenarioInstance := Scenario.LevelsOfDifficulty[i];
  end;
  ChooseScenarioInstance(ScenarioInstance);
end;

procedure TGameStateComponentMatchMaking.ChooseScenarioInstance(const ScenarioInstance : TScenarioInstance);
begin
  if assigned(Manager.CurrentTeam) then
  begin
    if assigned(ScenarioInstance) then
    begin
      Manager.CurrentTeam.ChooseScenarioInstance(ScenarioInstance);
      FLastChosenDifficulty := ScenarioInstance.League;
    end;
    if not assigned(Matchmaking.CurrentTeam.Deck) then
        Matchmaking.CurrentTeam.ChooseDeck(Deckbuilding.GetDefaultDeck);
  end;
  Parent.Owner.DialogManager.CloseDialog(diMatchmakingScenario);
  Parent.Owner.DialogManager.CloseDialog(diMatchmakingScenarioDifficulty);
end;

destructor TGameStateComponentMatchMaking.Destroy;
begin
  GUI.SetContext('matchmaking', nil);
  FreeAndNil(FScenarios);
  FreeAndNil(FQueue);
  FreeAndNil(FCurrentPlayerUpdateTimer);
  FreeAndNil(FMaintenanceLeaveQueueTimer);
  FreeAndNil(FEnterQueueBlockTimeout);
  inherited;
end;

procedure TGameStateComponentMatchMaking.EnterQueue;
var
  ScenarioInstance : TScenarioInstance;
  MaxLeague : integer;
begin
  FEnterQueueBlockTimeout.Start;
  IsEnteringQueue := True;

  // if pvp, choose the scenario according to the teams deck leagues
  if ChosenScenario in SCENARIOS_WITH_AUTO_LEAGUE then
  begin
    if DISABLE_LEAGUE_SYSTEM then
        MaxLeague := BaseConflict.Constants.Cards.MAX_LEAGUE
    else
        MaxLeague := Matchmaking.CurrentTeam.League;

    assert(Matchmaking.CurrentTeam.ScenarioInstance.Scenario.LevelsOfDifficulty.Count > MaxLeague - 1,
      'TGameStateComponentMatchMaking.EnterQueue: Missing PvP queue for league ' + IntToStr(MaxLeague));
    ScenarioInstance := Matchmaking.CurrentTeam.ScenarioInstance.Scenario.LevelsOfDifficulty[MaxLeague - 1];
    Manager.CurrentTeam.ChooseScenarioInstance(ScenarioInstance);
  end;

  Matchmaking.CurrentTeam.EnterQueue;
end;

function TGameStateComponentMatchMaking.GetEnumScenario(Scenario : TScenario) : EnumScenario;
var
  i : EnumScenario;
begin
  Result := esSpecial;
  for i := low(EnumScenario) to high(EnumScenario) do
    if SCENARIO_MAPPING[i] = Scenario.UID then
        exit(i);
end;

function TGameStateComponentMatchMaking.GetManager : TMatchmakingManager;
begin
  Result := Matchmaking;
end;

function TGameStateComponentMatchMaking.GetScenario(PredefinedScenario : EnumScenario) : TScenario;
begin
  Result := Scenarios.Scenarios.Query.Get(F('UID') = SCENARIO_MAPPING[PredefinedScenario], True);
end;

function TGameStateComponentMatchMaking.GetScenarioManager : TScenarioManager;
begin
  Result := ScenarioManager;
end;

procedure TGameStateComponentMatchMaking.Idle;
begin
  inherited;
  if IsInitialized then
  begin
    if InQueue then
    begin
      if not ServerState.MaintenanceCanEnterQueues and FMaintenanceLeaveQueueTimer.Expired then
      begin
        LeaveQueue;
        FMaintenanceLeaveQueueTimer.Start;
      end
      else
      begin
        Queue := Queue; // update queue in gui
        if FCurrentPlayerUpdateTimer.Expired then
        begin
          Account.UpdateCurrentPlayersOnline;
          FCurrentPlayerUpdateTimer.Start;
        end;
      end;
    end;
    if FEnterQueueBlockTimeout.Expired and IsEnteringQueue then
        IsEnteringQueue := False;
  end;
end;

procedure TGameStateComponentMatchMaking.Initialize;
begin
  if assigned(Matchmaking) and assigned(ScenarioManager) and Parent.Owner.IsApiReady then
  begin
    FMaintenanceLeaveQueueTimer := TTimer.Create(MAINTENANCE_LEAVE_QUEUE_INTERVAL);
    FCurrentPlayerUpdateTimer := TTimer.Create(CURRENT_PLAYER_ONLINE_UPDATE_INTERVAL_QUEUE);
    FEnterQueueBlockTimeout := TTimer.Create(ENTER_QUEUE_BLOCK_TIMEROUT);
    FScenarios := TUltimateList<TScenario>.Create;

    Matchmaking.OnGameFound := OnGameFound;
    Matchmaking.OnCurrentTeamChange := procedure()
      begin
        if not assigned(Matchmaking.CurrentTeam) then exit;
        Matchmaking.CurrentTeam.OnScenarioChanged := OnScenarioChanged;
        if Matchmaking.CurrentTeam.CurrentUserIsLeader then
            ChosenScenario := es1v1
        else
            OnScenarioChanged;
        Matchmaking.CurrentTeam.OnEnteredQueue := OnQueueEntered;
      end;
    // matchmaking manager starts with a initialized team, so attach handler
    Matchmaking.OnCurrentTeamChange();
    GUI.SetContext('matchmaking', self);
    inherited;
  end;
end;

function TGameStateComponentMatchMaking.IsDuel : Boolean;
begin
  Result := ChosenScenario in SCENARIOS_DUEL;
end;

function TGameStateComponentMatchMaking.IsPvE : Boolean;
begin
  Result := ChosenScenario in SCENARIOS_AGAINST_AI;
end;

procedure TGameStateComponentMatchMaking.LeaveQueue;
begin
  IsEnteringQueue := False;
  if assigned(Queue) then
      Queue.LeaveQueue;
end;

procedure TGameStateComponentMatchMaking.OnGameFound(Game : TGameMetaInfo);
begin
  // the matchmaking team worked, so we reset any recover state here
  FMatchmakingTeamAlreadyReset := False;

  SanitizeGameData(Game);

  if not Game.Spectator then
  begin
    if Game.ScenarioInstance.Scenario.UID = SCENARIO_PVE_TUTORIAL then
        QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_PLAY_TUTORIAL);

    // if we start any game signal it to quest system
    QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_START_GAME);

    Parent.GetComponent<TGameStateComponentStatistics>.GameData := Game;
  end;

  // remove queue, we don't need it anymore
  OnQueueLeft(FQueue, nil);

  if (Game.Data.scenario_uid = SCENARIO_DEBUG_META_TEST) or (Game.Data.scenario_uid = SCENARIO_DEBUG_IDLE) then
      Parent.Owner.ChangeGameState(GAMESTATE_MAINMENU)
  else
  begin
    Parent.Owner.GetGameState<TGameStateCoreGame>(GAMESTATE_INGAME).GameData := Game.Data;
    // Game found, now switch to loading state
    Parent.Owner.GetGameState<TGameStateLoadCoreGame>(GAMESTATE_LOADGAMESTATE).GameData := Game.Data;
    Parent.Owner.ChangeGameState(GAMESTATE_LOADGAMESTATE);
  end;
end;

procedure TGameStateComponentMatchMaking.OnQueueEntered(Sender : TMatchmakingTeam; Queue : TMatchmakingQueue);
begin
  IsEnteringQueue := False;
  // while in queue deck edit is disabled
  Parent.GetComponent<TGameStateComponentDeckbuilding>.EditDeck(nil);
  self.Queue := Queue;
  SoundManager.PlayEnterQueue;
end;

procedure TGameStateComponentMatchMaking.OnQueueError(ErrorCode : EnumErrorCode);
begin
  inherited;
  if ErrorCode = ecUnknownMatchmakingTeam then
  begin
    if FMatchmakingTeamAlreadyReset then
        Parent.Owner.ShowErrorcode(ecMatchmakingTeamCorrupt)
    else
    begin
      Parent.Owner.ShowErrorcode(ecMatchmakingTeamReset);
      if assigned(Manager) and assigned(Manager.CurrentTeam) then
      begin
        Manager.CurrentTeam.LeaveTeam;
        FMatchmakingTeamAlreadyReset := True;
      end;
    end;
  end;
end;

procedure TGameStateComponentMatchMaking.OnQueueLeft(Sender : TMatchmakingQueue; Leaver : TPerson);
var
  temp : TMatchmakingQueue;
begin
  IsEnteringQueue := False;
  temp := Queue;
  Queue := nil;
  temp.Free;
end;

procedure TGameStateComponentMatchMaking.OnScenarioChanged;
begin
  if assigned(Matchmaking.CurrentTeam) and not Matchmaking.CurrentTeam.CurrentUserIsLeader then
  begin
    if assigned(Matchmaking.CurrentTeam.ScenarioInstance) then
        ChosenScenario := GetEnumScenario(Matchmaking.CurrentTeam.ScenarioInstance.Scenario)
    else
        ChosenScenario := es1v1;
  end;
end;

procedure TGameStateComponentMatchMaking.OnServerQueueError;
begin
  Parent.Owner.ShowError('§MessageDialog_Error_Caption', '§MessageDialog_Error_Message_ServerQueueError');
end;

procedure TGameStateComponentMatchMaking.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('matchmaking', self);
end;

procedure TGameStateComponentMatchMaking.ParentLeft;
var
  temp : TMatchmakingQueue;
begin
  inherited;
  GUI.SetContext('matchmaking', nil);
  temp := Queue;
  Queue := nil;
  temp.Free;
end;

function TGameStateComponentMatchMaking.PendingInvites : integer;
begin
  if assigned(Manager) and assigned(Manager.CurrentTeam) then
      Result := Manager.CurrentTeam.Invites.Query.Filter(F('IsPending')).Count
  else
      Result := 0;
end;

function TGameStateComponentMatchMaking.Ranked1vs1 : TScenarioInstance;
var
  Scenario : TScenario;
begin
  Scenario := GetScenario(esRanked1v1);
  if assigned(Scenario) then
      Result := Scenario.LevelsOfDifficulty.First
  else
      Result := nil;
end;

function TGameStateComponentMatchMaking.Ranked2vs2 : TScenarioInstance;
var
  Scenario : TScenario;
begin
  Scenario := GetScenario(esRanked2v2);
  if assigned(Scenario) then
      Result := Scenario.LevelsOfDifficulty.First
  else
      Result := nil;
end;

procedure TGameStateComponentMatchMaking.SanitizeGameData(Game : TGameMetaInfo);
var
  GameData : RGameFoundData;
  i : integer;
begin
  GameData := Game.Data;

  if not Game.ScenarioInstance.Scenario.DeckRequired then
  begin
    for i := 0 to length(GameData.players) - 1 do
      if GameData.players[i].user_id > 0 then
      begin
        GameData.players[i].deckname := '§scenario_user_deck_name_' + GameData.scenario_uid;
        GameData.players[i].deck_icon := _('§scenario_user_deck_icon_' + GameData.scenario_uid);
      end;
  end;

  Game.Data := GameData;
end;

procedure TGameStateComponentMatchMaking.SetChosenScenario(const Value : EnumScenario);
var
  NewScenario : TScenario;
  NewScenarioInstance : TScenarioInstance;
begin
  if assigned(Matchmaking.CurrentTeam) and not Matchmaking.CurrentTeam.CurrentUserIsLeader then
  begin
    FChosenScenario := Value;
  end
  else
  begin
    NewScenario := GetScenario(Value);
    if assigned(NewScenario) then
    begin
      assert(NewScenario.LevelsOfDifficulty.Count > 0, Format('TGameStateComponentMatchMaking.SetChosenScenario: Scenario %s has no instances!', [NewScenario.UID]));
      NewScenarioInstance := NewScenario.LevelsOfDifficulty.First;
      FChosenScenario := Value;
    end
    else
    begin
      NewScenarioInstance := nil;
      if assigned(Manager.CurrentTeam) then
          Manager.CurrentTeam.Deck := nil;
      FChosenScenario := esNone;
    end;
    ChooseScenarioInstance(NewScenarioInstance);
    UpdateScenarioSelection;
  end;
end;

procedure TGameStateComponentMatchMaking.SetInQueue(const Value : Boolean);
begin
  FInQueue := Value;
end;

procedure TGameStateComponentMatchMaking.SetIsEnteringQueue(const Value : Boolean);
begin
  FIsEnteringQueue := Value;
end;

procedure TGameStateComponentMatchMaking.SetManager(const Value : TMatchmakingManager);
begin
  // only for notification
end;

procedure TGameStateComponentMatchMaking.SetQueue(const Value : TMatchmakingQueue);
begin
  FQueue := Value;
  if assigned(FQueue) then
  begin
    FQueue.OnQueueLeft := OnQueueLeft;
    FQueue.OnServerQueueError := OnServerQueueError;
  end;
  InQueue := assigned(FQueue);
end;

procedure TGameStateComponentMatchMaking.SetScenarioManager(const Value : TScenarioManager);
begin
  // only for notification
end;

procedure TGameStateComponentMatchMaking.SpectateFriend(Friend : TPerson);
begin
  if Friend.HasValidGame then
      OnGameFound(TGameMetaInfo.CreateSpectator(Friend.CurrentGame));
end;

function TGameStateComponentMatchMaking.HasAutoLeague : Boolean;
begin
  Result := ChosenScenario in SCENARIOS_WITH_AUTO_LEAGUE;
end;

function TGameStateComponentMatchMaking.HasLeagueSelection : Boolean;
begin
  Result := ChosenScenario in SCENARIOS_WITH_LEAGUE_SELECTION;
end;

function TGameStateComponentMatchMaking.HasScenarioSelection : Boolean;
begin
  Result := ChosenScenario in SCENARIOS_WITH_SCENARIO_SELECTION;
end;

procedure TGameStateComponentMatchMaking.StartTutorialGame;
begin
  (Parent as TGameStateMainMenu).IsLoading := True;
  Parent.GetComponent<TGameStateComponentProfile>.IsTutorialGameDialogOpen := False;
  (Parent as TGameStateMainMenu).CurrentMenu := mtGame;
  ChosenScenario := esTutorial;
  ChooseScenario(ScenarioManager.Scenarios.Query.Filter(F('UID') = SCENARIO_PVE_TUTORIAL).First(True));
  Manager.CurrentTeam.Deck := nil;
  EnterQueue;
end;

procedure TGameStateComponentMatchMaking.UpdateScenarioSelection;
begin
  if HasScenarioSelection then
  begin
    FScenarios.Clear;
    if IsDuel then
    begin
      FScenarios.Add(GetScenario(esDuel));
      FScenarios.Add(GetScenario(esDuel2v2));
      FScenarios.Add(GetScenario(esDuel3v3));
      FScenarios.Add(GetScenario(esDuel4v4));
    end
    else
        FScenarios.AddRange(Scenarios.Scenarios);
  end;
end;

{ TGameStateComponentDeckbuilding }

procedure TGameStateComponentDeckbuilding.AddCard(const CardInstance : TCardInstance);
begin
  FEditedDeck.AddCard(CardInstance);
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_DECK_ADD_CARD);
end;

procedure TGameStateComponentDeckbuilding.AddDeck;
var
  Deck : TDeck;
begin
  Deck := Deckbuilding.CreateNewDeck;
  Deck.name := _('§deckbuilding_deck_default_name');
  self.Deck := Deck;
end;

procedure TGameStateComponentDeckbuilding.ApplyFilters;
begin
  // filters cardpool cards and set new pool
  FCardpoolFilter.ApplyFilters(FCardpool);
end;

procedure TGameStateComponentDeckbuilding.CancelNewDeckName;
begin
  if assigned(Deck) then NewDeckName := Deck.name;
end;

procedure TGameStateComponentDeckbuilding.ChooseDeckIcon(const IconUID : string);
begin
  if assigned(Deck) then Deck.Icon := IconUID;
  Parent.Owner.DialogManager.CloseDialog(diDeckIcon);
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_SET_DECK_ICON);
end;

procedure TGameStateComponentDeckbuilding.ChooseSkin(const Skin : TCardSkin);
begin
  if assigned(FDeckCard) then
  begin
    FDeckCard.Skin := Skin;
    DeckCard := nil;
  end;
end;

procedure TGameStateComponentDeckbuilding.DeletePreparedDeck;
begin
  if assigned(DeckToDelete) and Decks.Contains(DeckToDelete) then
  begin
    // unset deck in matchmaking if it is deleted
    if assigned(Matchmaking) and assigned(Matchmaking.CurrentTeam) and (DeckToDelete = Matchmaking.CurrentTeam.Deck) then
        Matchmaking.CurrentTeam.Deck := nil;
    DeckToDelete.Delete;
  end;
  DeckToDelete := nil;
end;

destructor TGameStateComponentDeckbuilding.Destroy;
begin
  GUI.SetContext('deckbuilder', nil);
  FreeAndNil(FCardpoolFilter);
  FreeAndNil(FCardpool);
  FreeAndNil(FCardInstanceWithRewards);
  FreeAndNil(FSacrificeList);
  FreeAndNil(FSacrificePool);
  FreeAndNil(FSacrificePoolCards);
  FreeAndNil(FSacrificePoolCurrentObjects);
  FreeAndNil(FCardpoolCards);
  inherited;
end;

procedure TGameStateComponentDeckbuilding.EditDeck(Deck : TDeck);
begin
  self.Deck := Deck;
end;

function TGameStateComponentDeckbuilding.CanAscendWithCredits : Boolean;
var
  temp : TUltimateList<RCost>;
begin
  temp := TUltimateList<RCost>.Create();
  temp.Add(AscensionCreditCost);
  Result := assigned(Card) and Card.CardInstance.IsLeagueUpgradable and Shop.CanPayCosts(temp);
  temp.Free;
end;

function TGameStateComponentDeckbuilding.CanAscendWithCrystals : Boolean;
var
  temp : TUltimateList<RCost>;
begin
  temp := TUltimateList<RCost>.Create();
  temp.Add(AscensionCrystalCost);
  Result := assigned(Card) and Card.CardInstance.IsLeagueUpgradable and Shop.CanPayCosts(temp);
  temp.Free;
end;

function TGameStateComponentDeckbuilding.CanAscendWithSacrificeList : Boolean;
begin
  Result := AscensionCreditCost.Amount <= 0;
end;

function TGameStateComponentDeckbuilding.GetCardManager : TCardManager;
begin
  Result := BaseConflict.Api.Cards.CardManager;
end;

function TGameStateComponentDeckbuilding.GetDecklist : TUltimateList<TDeck>;
begin
  Result := Deckbuilding.Decks;
end;

function TGameStateComponentDeckbuilding.GetDeckManager : TDeckManager;
begin
  Result := BaseConflict.Api.Deckbuilding.Deckbuilding;
end;

function TGameStateComponentDeckbuilding.GetShop : TShop;
begin
  Result := BaseConflict.Api.Shop.Shop;
end;

procedure TGameStateComponentDeckbuilding.Initialize;
begin
  if assigned(Deckbuilding) and assigned(CardManager) and assigned(Shop) then
  begin
    FSacrificeList := TUltimateList<TCardInstance>.Create;
    FSacrificePoolCards := TUltimateList<TCardInstance>.Create;
    FSacrificePoolCurrentObjects := TUltimateList<TCardInstance>.Create;
    FSacrificeGridSize := Settings.GetIntegerOption(coMenuDeckbuildingSacrificeGridSize);
    FSacrificePool := TPaginator<TCardInstance>.Create(FSacrificePoolCards, FSacrificeGridSize, False);
    FSacrificePool.OnChange := procedure()
      begin
        SacrificePool := nil;
        FSacrificePoolCurrentObjects.Clear;
        FSacrificePoolCurrentObjects.AddRange(FSacrificePool.CurrentObjects);
      end;
    // init card pool ------------------------------------------
    FGridSize := Settings.GetIntegerOption(coMenuDeckbuildingGridSize);
    FCardpoolCards := TUltimateList<TCardInstance>.Create();
    FCardpool := TPaginator<TCardInstance>.Create(CardManager.PlayerCards.Query.ToList(False), sqr(GridSize), True);

    // filter contains real cardpool and updates shown cardpool on changes
    FCardpoolFilter := TPaginatorCardFilter<TCardInstance>.Create(CardManager.PlayerCards);
    FCardpoolFilter.OnChange := procedure()
      begin
        CardpoolFilter := nil
      end;
    // if cardpool changed apply filters and update paginator
    CardManager.PlayerCards.OnChange := OnPlayerCardsChange;
    // initially apply filters
    ApplyFilters;
    // update paginator in gui if it changed by calling setter
    FCardpool.OnChange := procedure()
      begin
        Cardpool := nil;
        FCardpoolCards.Clear;
        FCardpoolCards.AddRange(Cardpool.CurrentObjects);
      end;

    GUI.SetContext('deckbuilder', self);
    inherited;
  end;
end;

procedure TGameStateComponentDeckbuilding.OnPlayerCardsChange(Sender : TUltimateList<TCardInstance>; Item : TArray<TCardInstance>; Action : EnumListAction; Indices : TArray<integer>);
begin
  if Action in [laRemoved, laExtracted, laExtractedRange, laClear] then
  begin
    CardpoolCurrentObjects.Clear;
    CardpoolCurrentObjects := nil;
    SacrificeList.Clear;
  end;
  ApplyFilters;
  UpdateSacrificePool;
end;

procedure TGameStateComponentDeckbuilding.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('deckbuilder', self);
end;

procedure TGameStateComponentDeckbuilding.ParentLeft;
begin
  inherited;
  GUI.SetContext('deckbuilder', nil);
end;

procedure TGameStateComponentDeckbuilding.PickMaterial(Card : TCardInstance);
begin
  SacrificeList.Add(Card);
  UpdateSacrificePool;
  UpdateCardDetails;
end;

procedure TGameStateComponentDeckbuilding.PrepareDeleteDeck(Deck : TDeck);
begin
  DeckToDelete := Deck;
end;

procedure TGameStateComponentDeckbuilding.PushCardXP;
begin
  SoundManager.PlayCardXPPush;
  Card.CardInstance.PushCardXPBySacrifice(SacrificeList.ToArray);
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_LEVEL_TRIBUTE);
  if Card.CardInstance.Level = MAX_LEVEL then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_REACH_MAX_LEVEL);
  SacrificeList.Clear;
  UpdateSacrificePool;
  UpdateCardDetails;
  // paginate to pushed card
  Cardpool.CurrentPage := Cardpool.PageOfObject(Card.CardInstance);
end;

procedure TGameStateComponentDeckbuilding.RemoveMaterial(Card : TCardInstance);
begin
  SacrificeList.Remove(Card);
  UpdateSacrificePool;
  UpdateCardDetails;
end;

procedure TGameStateComponentDeckbuilding.ResetFilter;
begin
  if CardpoolFilter.Reset then
      ApplyFilters;
end;

procedure TGameStateComponentDeckbuilding.UpdateCardDetails;
begin
  if assigned(Card) then
  begin
    if not Card.CardInstance.IsLeagueUpgradable then
    begin
      Card.ExperienceGained := Card.CardInstance.GetXPBySacrifice(SacrificeList.ToArray);
      Card.HasAscension := False;
      Card.UpgradePointsGained := 0;
    end
    else
    begin
      Card.ExperienceGained := 0;
      Card.HasAscension := Parent.Owner.DialogManager.IsDialogVisible(diAscension);
      Card.UpgradePointsGained := SacrificeListValue;
    end;
  end;
end;

procedure TGameStateComponentDeckbuilding.UpdateSacrificePool;
var
  CardToSacrifice : TCardInstance;
begin
  FSacrificePoolCards.Clear;
  if assigned(Card) then
  begin
    FSacrificePoolCards.AddRange(
      CardManager.PlayerCards.Query
      .Filter(F('ID') <> Card.CardInstance.ID)
      .OrderBy(['IsInAnyDeck', 'League', 'ExperiencePoints'])
      .ToArray);
  end;
  for CardToSacrifice in SacrificeList do
      FSacrificePoolCards.Remove(CardToSacrifice);
  FSacrificePool.Update;
end;

procedure TGameStateComponentDeckbuilding.Ascend;
begin
  if CanAscendWithSacrificeList then
      AscendWithCredits
  else
  begin
    Parent.Owner.DialogManager.OpenDialog(diAscension);
    UpdateCardDetails;
  end;
end;

procedure TGameStateComponentDeckbuilding.AscendRaw(WithCrystals : Boolean);
begin
  Parent.Owner.DialogManager.CloseDialog(diAscension);
  SoundManager.PlayCardAscension;
  if SacrificeList.Count > 0 then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_LEVEL_TRIBUTE);
  if WithCrystals then
      Card.CardInstance.UpgradeCardUsePremium(SacrificeList.ToArray)
  else
      Card.CardInstance.UpgradeCardUseGold(SacrificeList.ToArray);
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_ASCEND);
  if Card.CardInstance.League = ord(leBronze) then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_ASCEND_BRONZE);
  if Card.CardInstance.League = ord(leSilver) then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_ASCEND_SILVER);
  if Card.CardInstance.League = ord(leGold) then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_ASCEND_GOLD);
  if Card.CardInstance.League = ord(leCrystal) then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_ASCEND_CRYSTAL);
  SacrificeList.Clear;
  UpdateSacrificePool;
  UpdateCardDetails;
  // paginate to ascended card
  Cardpool.CurrentPage := Cardpool.PageOfObject(Card.CardInstance);
end;

procedure TGameStateComponentDeckbuilding.AscendWithCredits;
begin
  AscendRaw(False);
end;

procedure TGameStateComponentDeckbuilding.AscendWithCrystals;
begin
  AscendRaw(True);
end;

function TGameStateComponentDeckbuilding.AscensionCreditCost : RCost;
begin
  Result.Amount := -1;
  Result.Currency := nil;
  if assigned(Card) and CurrencyManager.TryGetCurrencyByUID(CURRENCY_GOLD, Result.Currency) then
  begin
    Result := Card.CardInstance.UpgradeGoldCost;
    Result.Amount := Max(0, Result.Amount - SacrificeListValue);
  end;
end;

function TGameStateComponentDeckbuilding.AscensionCrystalCost : RCost;
begin
  Result.Amount := -1;
  Result.Currency := nil;
  if assigned(Card) and CurrencyManager.TryGetCurrencyByUID(CURRENCY_DIAMONDS, Result.Currency) then
  begin
    Result := Card.CardInstance.UpgradePremiumCost;
    Result.Amount := Max(0, Result.Amount - (SacrificeListValue div 4));
  end;
end;

function TGameStateComponentDeckbuilding.SacrificeListExperienceValue : integer;
var
  i : integer;
begin
  Result := 0;
  if assigned(Card) then
  begin
    for i := 0 to SacrificeList.Count - 1 do
        Result := Result + SacrificeList[i].ExperiencePointsValue(Card.CardInstance);
  end;
end;

function TGameStateComponentDeckbuilding.SacrificeListValue : integer;
var
  i : integer;
begin
  Result := 0;
  if assigned(Card) then
  begin
    for i := 0 to SacrificeList.Count - 1 do
        Result := Result + SacrificeList[i].UpgradePointsValue(Card.CardInstance);
  end;
end;

procedure TGameStateComponentDeckbuilding.SaveNewDeckName;
begin
  if assigned(Deck) then Deck.name := NewDeckName;
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_SET_DECK_NAME);
end;

procedure TGameStateComponentDeckbuilding.SetCardPool(const Value : TPaginator<TCardInstance>);
begin
  // do nothing as this only notifies changes
end;

procedure TGameStateComponentDeckbuilding.SetCardpoolCards(const Value : TUltimateList<TCardInstance>);
begin
  // do nothing as this only notifies changes
end;

procedure TGameStateComponentDeckbuilding.SetCardPoolFilter(const Value : TPaginatorCardFilter<TCardInstance>);
begin
  // the setter call notifies filter bar to update
  // and this to update cardpool
  ApplyFilters;
end;

procedure TGameStateComponentDeckbuilding.SetEditedDeck(const Value : TDeck);
begin
  if MainActionQueue.IsActive then
  begin
    if assigned(FEditedDeck) then
        FEditedDeck.OnChange := nil;
    FEditedDeck := Value;
    if assigned(FEditedDeck) then
    begin
      NewDeckName := FEditedDeck.name;
      FEditedDeck.OnChange :=
          procedure(const Deck : TDeck)
        begin
          Cardpool := nil;
        end;
      ResetFilter;
    end;
  end
  else
      TActionSetVariable<TDeck>.Create(Value, Deck, SetEditedDeck).Deploy;
end;

procedure TGameStateComponentDeckbuilding.SetGridSize(const Value : integer);
begin
  if MainActionQueue.IsActive then
  begin
    FGridSize := Value;
    FCardpool.PageSize := sqr(GridSize);
    Settings.SetIntegerOption(coMenuDeckbuildingGridSize, FGridSize);
    Settings.SaveSettings;
  end
  else TActionSetVariable<integer>.Create(Value, GridSize, SetGridSize).Deploy;
end;

procedure TGameStateComponentDeckbuilding.SetDeckCard(const Value : TDeckCard);
begin
  FDeckCard := Value;
  Parent.Owner.DialogManager.BindDialog(diDeckCardSkin, assigned(FDeckCard));
end;

procedure TGameStateComponentDeckbuilding.SetDeckManager(const Value : TDeckManager);
begin
  // only notification
end;

procedure TGameStateComponentDeckbuilding.SetDeckToDelete(const Value : TDeck);
begin
  if MainActionQueue.IsActive then
  begin
    FDeckToDelete := Value;
    Parent.Owner.DialogManager.BindDialog(diDeckDelete, assigned(FDeckToDelete));
  end
  else TActionSetVariable<TDeck>.Create(Value, DeckToDelete, SetDeckToDelete).Deploy;
end;

procedure TGameStateComponentDeckbuilding.SetNewDeckName(const Value : string);
begin
  if MainActionQueue.IsActive then FNewDeckName := Value
  else TActionSetVariable<string>.Create(Value, NewDeckName, SetNewDeckName).Deploy;
end;

procedure TGameStateComponentDeckbuilding.SetSacrificePool(const Value : TPaginator<TCardInstance>);
begin
  // only notification
end;

procedure TGameStateComponentDeckbuilding.SetShop(const Value : TShop);
begin
  // only notification
end;

procedure TGameStateComponentDeckbuilding.SetCardInstanceWithRewards(const Value : TCardInstanceWithRewards);
begin
  if MainActionQueue.IsActive then
  begin
    FCardInstanceWithRewards := Value;
    SacrificeList.Clear;
    UpdateSacrificePool;
  end
  else TActionSetInstanceVariable<TCardInstanceWithRewards>.Create(Value, Card, SetCardInstanceWithRewards).Deploy;
end;

procedure TGameStateComponentDeckbuilding.SetCardManager(const Value : TCardManager);
begin
  // only notification
end;

procedure TGameStateComponentDeckbuilding.ShowCardDetails(const Card : TCardInstance);
begin
  if not assigned(Card) then exit;
  self.Card := TCardInstanceWithRewards.Create(Card);
  Parent.Owner.DialogManager.OpenDialog(diCardDetails);
end;

procedure TGameStateComponentDeckbuilding.CloseCardDetails;
begin
  Card := nil;
  SacrificeList.Clear;
  UpdateSacrificePool;
  Parent.Owner.DialogManager.CloseDialog(diCardDetails);
end;

procedure TGameStateComponentDeckbuilding.CloseIfInDeckeditor;
begin
  if (Parent as TGameStateMainMenu).CurrentMenu = mtDeck then
      Deck := nil;
end;

{ TGameStateComponentShop }

procedure TGameStateComponentShop.ApplyFilters;
begin
  // filters cardpool cards and set new pool
  FShopItemFilter.ApplyFilters(FShopItems);
end;

procedure TGameStateComponentShop.BuyOffer(const Offer : TShopItemOffer);
begin
  BuyOfferTimes(Offer, 1);
end;

procedure TGameStateComponentShop.BuyOfferTimes(const Offer : TShopItemOffer; Times : integer);
begin
  TActionSetVariable<EnumPurchaseState>.Create(psProcessing, PurchaseState, SetPurchaseState).Deploy;
  Offer.Buy(Times);
  if Offer.RealMoney then
      MainActionQueue.DoAction(
      TActionInline.Create.OnExecuteSynchronized(
      function() : Boolean
      begin
        Result := True;
        case Shop.LastRealMoneyTransactionState of
          tsNone, tsProcessing : assert(False, 'TGameStateComponentShop.BuyOffer: Unexpected state after purchase!');
          tsSuccessful : PurchaseState := psSuccess;
          tsAborted : PurchaseState := psAborted;
          tsFailed : PurchaseState := psFailed;
        end;
      end).OnRollback(
      procedure()
      begin
        PurchaseState := psFailed;
      end))
  else
      TActionSetVariable<EnumPurchaseState>.Create(psSuccess, psFailed, SetPurchaseState).DoInExecuteSynchronized.Deploy;
  // if we bought a card, signal it to quest system
  if Offer.ShopItem is TShopItemBuyCardInstance then
      QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_BUY_CARD);
end;

procedure TGameStateComponentShop.ConfirmPurchaseDialog;
begin
  if PurchaseState = psSuccess then
      ChosenShopItem := nil;
  PurchaseState := psNone;
end;

function TGameStateComponentShop.GetDeckslotShopItemCredits : TShopItem;
var
  ShopItem : TShopItem;
  Offer : TShopItemOffer;
  BestPrice : integer;
begin
  Result := nil;
  BestPrice := integer.MaxValue;
  for ShopItem in Shop.Items do
    if ShopItem.ItemType = itDeckSlot then
    begin
      for Offer in ShopItem.Offers do
        if not Offer.HasHardCurrency then
        begin
          if not ShopItem.MaxPurchasesReached and (not assigned(Result) or (BestPrice > Offer.Costs[0].Amount)) then
          begin
            Result := ShopItem;
            BestPrice := Offer.Costs[0].Amount;
          end;
        end;
    end;
end;

function TGameStateComponentShop.GetDeckslotShopItemCrystals : TShopItem;
var
  ShopItem : TShopItem;
  Offer : TShopItemOffer;
begin
  Result := nil;
  for ShopItem in Shop.Items do
    if ShopItem.ItemType = itDeckSlot then
    begin
      for Offer in ShopItem.Offers do
        if Offer.HasHardCurrency then
            exit(ShopItem);
    end;
end;

destructor TGameStateComponentShop.Destroy;
begin
  GUI.SetContext('shop', nil);
  FreeAndNil(FShopItemFilter);
  FreeAndNil(FShopItems);
  FreeAndNil(FShopItemList);
  // DestroyBoosterScene;
  inherited;
end;

function TGameStateComponentShop.FirstCrystalsBought : Boolean;
var
  ShopItem : TShopItem;
begin
  Result := False;
  for ShopItem in Shop.Items do
    if (ShopItem.ItemType = itDiamonds) and (ShopItem.PurchasesCount > 0) then
        exit(True);
end;

function TGameStateComponentShop.GetShop : TShop;
begin
  Result := BaseConflict.Api.Shop.Shop;
end;

procedure TGameStateComponentShop.Initialize;
begin
  if assigned(Shop) then
  begin
    FShopItemList := TUltimateList<TShopItem>.Create();
    FShopItems := TPaginator<TShopItem>.Create(Shop.Items.Query.ToList(False), 6 * 3, True);

    // filter contains real shop items and updates shown shop items on changes
    FShopItemFilter := TPaginatorShopFilter<TShopItem>.Create(Shop.Items);
    FShopItemFilter.Category := scSkins;
    FShopItemFilter.OnChange := procedure()
      begin
        if FShopItemFilter.Category = scCards then
            FShopItems.PageSize := 5 * 3
        else
            FShopItems.PageSize := 6 * 3;
        ShopItemFilter := nil;
        ShopItems := nil;
      end;
    // if shop items changed apply filters and update paginator
    Shop.Items.OnChange := OnShopItemsChange;
    Shop.OnRewardGained := OnGainReward;
    // initially apply filters
    ApplyFilters;
    // update paginator in gui if it changed by calling setter
    FShopItems.OnChange := procedure()
      begin
        ShopItems := nil;
        FShopItemList.Clear;
        FShopItemList.AddRange(FShopItems.CurrentObjects);
      end;

    // Shop.Balances.OnChange := UpdateBalances;

    GUI.SetContext('shop', self);
    inherited;
  end;
end;

procedure TGameStateComponentShop.OnGainReward(Rewards : TArray<RReward>);
begin
  Parent.GetComponent<TGameStateComponentNotification>.AddRewards(Rewards);
end;

procedure TGameStateComponentShop.OnShopItemsChange(Sender : TUltimateList<TShopItem>; Item : TArray<TShopItem>; Action : EnumListAction; Indices : TArray<integer>);
begin
  ApplyFilters;
end;

procedure TGameStateComponentShop.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('shop', self);
end;

procedure TGameStateComponentShop.ParentLeft;
begin
  inherited;
  GUI.SetContext('shop', nil);
end;

procedure TGameStateComponentShop.RedeemBonuscode;
begin
  Parent.Owner.LoadingCaption := '§shop_redeem_dialog_loading_caption';
  Parent.Owner.LoadingMessage := '§shop_redeem_dialog_loading_message';
  Parent.Owner.IsLoading := True;
  if FBonuscode.StartsWith('JAGEX', True) or FBonuscode.StartsWith('YAGEX', True) then
      Parent.GetComponent<TGameStateComponentNotification>.BlockForTime(5000)
  else if FBonuscode.ToLowerInvariant = 'unlock_pve_levels' then
  begin
    UserProfile.UnlockPvELeague(1);
    UserProfile.UnlockPvELeague(2);
    UserProfile.UnlockPvELeague(3);
    UserProfile.UnlockPvELeague(4);
    UserProfile.UnlockPvELeague(5);
    UserProfile.Unlock2vELeague(1);
    UserProfile.Unlock2vELeague(2);
    UserProfile.Unlock2vELeague(3);
    UserProfile.Unlock2vELeague(4);
    UserProfile.Unlock2vELeague(5);
  end
  else if FBonuscode.ToLowerInvariant = 'unlock_level_unlocks' then
  begin
    UserProfile.DisableLevelUnlocks := True;
  end
  else if (FBonuscode.ToLowerInvariant = 'boom') or (FBonuscode.ToLowerInvariant = 'exception') then
      raise Exception.Create('This is a test exception fired by a bonus code.')
  else
      Shop.RedeemKeycode(FBonuscode);
  Parent.Owner.IsLoading := False;
  TActionSetVariable<string>.Create('', Bonuscode, SetBonuscode).DoInExecuteSynchronized.Deploy;
end;

procedure TGameStateComponentShop.ResetFilter;
begin
  ShopItemFilter.Reset;
  ApplyFilters;
end;

procedure TGameStateComponentShop.SelectShopItem(const ShopItem : TShopItem);
begin
  if [scBundles, scDiamonds] * ShopItem.Categories <> [] then BuyOffer(ShopItem.Offers.First)
  else ChosenShopItem := ShopItem;
end;

procedure TGameStateComponentShop.SetBonuscode(const Value : string);
begin
  FBonuscode := Value;
end;

procedure TGameStateComponentShop.SetChosenShopItem(const Value : TShopItem);
begin
  FChosenShopItem := Value;
  Parent.Owner.DialogManager.BindDialog(diShopItem, assigned(FChosenShopItem));
end;

procedure TGameStateComponentShop.SetPurchaseState(const Value : EnumPurchaseState);
begin
  FPurchaseState := Value;
  Parent.Owner.DialogManager.BindDialog(diShopPurchase, FPurchaseState <> psNone);
  if (Value = psSuccess) then
      SoundManager.PlayShopPurchase;
end;

procedure TGameStateComponentShop.SetShop(const Value : TShop);
begin
  // only notification
end;

procedure TGameStateComponentShop.SetShopItemFilter(const Value : TPaginatorShopFilter<TShopItem>);
begin
  // the setter call notifies filter bar to update
  // and this to update cardpool
  ApplyFilters;
  if FShopItemFilter.Category = scDiamonds then QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_NAVIGATE_SHOP_CRYSTALS);
end;

procedure TGameStateComponentShop.SetShopItems(const Value : TPaginator<TShopItem>);
begin
  // do nothing as this only notifies changes
end;

{ TGameStateComponentStatistics }

procedure TGameStateComponentStatistics.ClearGameData;
begin
  self.GameData := nil;
end;

destructor TGameStateComponentStatistics.Destroy;
begin
  GUI.SetContext('statistics', nil);
  FreeAndNil(ServerGameData);
  FreeAndNil(FOldGameData);
  FreeAndNil(FIdleTimer);
  inherited;
end;

function TGameStateComponentStatistics.GetGameData : TGameMetaInfo;
begin
  Result := ServerGameData;
end;

procedure TGameStateComponentStatistics.Idle;
begin
  inherited;
  if assigned(FIdleTimer) then
  begin
    if not FIdleTimer.Expired then
    begin
      IdleTimerBlock := ceil(FIdleTimer.TimeToExpired / 1000);
      AppProgress := ceil(FIdleTimer.TimeSinceStart);
      AppProgressMax := FIdleTimer.Interval;
    end
    else
    begin
      IdleTimerBlock := -1;
      FreeAndNil(FIdleTimer);
      AppProgress := 1;
      AppProgressMax := 1;
      Appstate := tsError;
    end;
  end;
end;

procedure TGameStateComponentStatistics.Initialize;
begin
  inherited;
  GUI.SetContext('statistics', self);
end;

procedure TGameStateComponentStatistics.OnDataReady;
var
  i : integer;
begin
  Parent.Owner.DialogManager.CloseDialog(diStatisticsLoading);

  for i := 0 to ServerGameData.Rewards.CardWithRewards.Count - 1 do
    if ServerGameData.Rewards.CardWithRewards[i].LevelAfter = MAX_LEVEL then
        QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_REACH_MAX_LEVEL);

  if ServerGameData.ScenarioInstance.Scenario.UID = SCENARIO_PVE_ATTACK_SOLO then
      UserProfile.UnlockPvELeague(ServerGameData.ScenarioInstance.League + 1);

  if ServerGameData.ScenarioInstance.Scenario.UID = SCENARIO_PVE_ATTACK_DUO then
      UserProfile.Unlock2vELeague(ServerGameData.ScenarioInstance.League + 1);

  if ServerGameData.ScenarioInstance.Scenario.UID = SCENARIO_DEBUG_IDLE then
  begin
    if not assigned(TaskbarManager) then
    begin
      try
        TaskbarManager := TTaskbar.Create(Parent.Owner.GameWindow);
        TaskbarManager.Initialize;
      except
        FreeAndNil(TaskbarManager);
      end;
    end;
    IsIdleBlocked := True;
    FIdleTimer := TTimer.CreateAndStart(ServerGameData.Statistics.Duration * 1000);
  end;

  Account.ResumeBackchannel;
end;

procedure TGameStateComponentStatistics.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('statistics', self);
end;

procedure TGameStateComponentStatistics.ParentLeft;
begin
  inherited;
  GUI.SetContext('statistics', nil);
end;

procedure TGameStateComponentStatistics.SetGameData(const Value : TGameMetaInfo);
begin
  FreeAndNil(FOldGameData);
  FOldGameData := ServerGameData;
  ServerGameData := Value;
  if assigned(ServerGameData) then
      ServerGameData.OnReady := OnDataReady;
end;

procedure TGameStateComponentStatistics.SetIdleTimerBlock(const Value : integer);
begin
  FIdleTimerBlock := Value;
end;

procedure TGameStateComponentStatistics.SetIsIdleBlocked(const Value : Boolean);
begin
  FIsIdleBlocked := Value;
  Parent.Owner.DialogManager.BindDialog(diIdleLegions, FIsIdleBlocked);
  if Value then Appstate := BaseConflict.Globals.Client.tsNormal
  else Appstate := BaseConflict.Globals.Client.tsNone;
end;

procedure TGameStateComponentStatistics.Show;
begin
  if self = nil then exit;
  Parent.Owner.DialogManager.OpenDialog(diStatisticsLoading);
  GameData.LoadAfterGameData;
  Parent.Owner.DialogManager.BindDialog(diRanking, GameData.ScenarioInstance.Scenario.Ranked);
end;

{ TSettingsWrapper }

procedure TSettingsWrapper.ApplyRebinding;
begin
  KeybindingManager.SetMapping(KeyToBind, FNewKeybindingIndex, NewBinding);
  Settings.SetKeybinding(EnumClientOption(ord(coKeybindingBindingNone) + ord(KeyToBind) * 2 + FNewKeybindingIndex), NewBinding);
  KeyToBind := kbNone;
  Sync;
end;

procedure TSettingsWrapper.BeginUpdate;
begin
  inc(FBlockUpdate);
end;

procedure TSettingsWrapper.CancelRebinding;
begin
  KeyToBind := kbNone;
end;

constructor TSettingsWrapper.Create();
var
  Keys : TArray<EnumKeybinding>;
  i : integer;
  SteamLanguageKey, SteamLanguage : string;
  temp : RSteamLanguage;
begin
  inherited;
  FBindableKeys := TUltimateList<EnumKeybinding>.Create;
  Keys := TArray<EnumKeybinding>.Create(
    kbCameraUp,
    kbCameraLeft,
    kbCameraDown,
    kbCameraRight,
    kbCameraLaneLeft,
    kbCameraLaneRight,
    kbCameraMoveTo,
    kbCameraResetZoom,

    kbPingGeneric,
    kbPingAttack,
    kbPingDefend,

    kbNexusJump,
    kbDeckslot01,
    kbDeckslot02,
    kbDeckslot03,
    kbDeckslot04,
    kbDeckslot05,
    kbDeckslot06,
    kbDeckslot07,
    kbDeckslot08,
    kbDeckslot09,
    kbDeckslot10,
    kbDeckslot11,
    kbDeckslot12,

    kbGUIToggle
    );
  FBindableKeys.AddRange(Keys);
  FAvailableLanguages := TUltimateList<RSteamLanguage>.Create;
  {$IFDEF STEAM}
  SteamLanguageKey := SteamApps.GetCurrentGameLanguage;
  if SteamLanguageKeys.TryGetValue(SteamLanguageKey, temp) then
      SteamLanguage := temp.NativeName
  else
      SteamLanguage := 'Steam';
  FAvailableLanguages.Add(RSteamLanguage.Create('', 'Steam', SteamLanguage, HClient.MapSteamLanguageKeyToGame(SteamLanguageKey)).UpdateProgress);
  {$ENDIF}
  for i := 0 to length(STEAM_LANGUAGES) - 1 do
      FAvailableLanguages.Add(SteamLanguageKeys[STEAM_LANGUAGES[i]]);
end;

destructor TSettingsWrapper.Destroy;
begin
  GUI.SetContext('settings', nil);
  FBindableKeys.Free;
  FAvailableLanguages.Free;
  inherited;
end;

procedure TSettingsWrapper.DetermineCurrentLanguage;
var
  LangCode : string;
  i : integer;
begin
  if Settings.IsSetNotNone(coGeneralLanguage) then
  begin
    LangCode := Settings.GetStringOption(coGeneralLanguage);
    for i := 0 to length(STEAM_LANGUAGES) - 1 do
      if SteamLanguageKeys[STEAM_LANGUAGES[i]].WebApiLanguageCode.ToLowerInvariant = LangCode.ToLowerInvariant then
      begin
        CurrentLanguage := SteamLanguageKeys[STEAM_LANGUAGES[i]];
        exit;
      end;
    CurrentLanguage := SteamLanguageKeys[STEAM_LANG_English];
  end
  else
      CurrentLanguage := FAvailableLanguages.First;
end;

procedure TSettingsWrapper.DetermineGraphicsQualityFromSettings(Sync : Boolean);
var
  ActiveOptions : SetClientOption;
begin
  ActiveOptions := [];
  if Settings.GetBooleanOption(coGraphicsDeferredShading) then
      include(ActiveOptions, coGraphicsDeferredShading);
  if Settings.GetBooleanOption(coGraphicsGUIBlurBackgrounds) then
      include(ActiveOptions, coGraphicsGUIBlurBackgrounds);
  if Settings.GetBooleanOption(coGraphicsPostEffectSSAO) then
      include(ActiveOptions, coGraphicsPostEffectSSAO);
  if Settings.GetBooleanOption(coGraphicsPostEffectToon) then
      include(ActiveOptions, coGraphicsPostEffectToon);
  if Settings.GetBooleanOption(coGraphicsPostEffectGlow) then
      include(ActiveOptions, coGraphicsPostEffectGlow);
  if Settings.GetBooleanOption(coGraphicsPostEffectFXAA) then
      include(ActiveOptions, coGraphicsPostEffectFXAA);
  if Settings.GetBooleanOption(coGraphicsPostEffectUnsharpMasking) then
      include(ActiveOptions, coGraphicsPostEffectUnsharpMasking);
  if Settings.GetBooleanOption(coGraphicsPostEffectDistortion) then
      include(ActiveOptions, coGraphicsPostEffectDistortion);

  if (ShadowQuality = GRAPHICS_PRESET_SHADOW_QUALITY[gqVeryHigh]) and (GRAPHICS_PRESET_ACTIVE_OPTIONS_VERY_HIGH = ActiveOptions) then
      FGraphicsQuality := gqVeryHigh
  else if (ShadowQuality = GRAPHICS_PRESET_SHADOW_QUALITY[gqHigh]) and (GRAPHICS_PRESET_ACTIVE_OPTIONS_HIGH = ActiveOptions) then
      FGraphicsQuality := gqHigh
  else if (ShadowQuality = GRAPHICS_PRESET_SHADOW_QUALITY[gqMedium]) and (GRAPHICS_PRESET_ACTIVE_OPTIONS_MEDIUM = ActiveOptions) then
      FGraphicsQuality := gqMedium
  else if (ShadowQuality = GRAPHICS_PRESET_SHADOW_QUALITY[gqLow]) and (GRAPHICS_PRESET_ACTIVE_OPTIONS_LOW = ActiveOptions) then
      FGraphicsQuality := gqLow
  else if (ShadowQuality = GRAPHICS_PRESET_SHADOW_QUALITY[gqVeryLow]) and (GRAPHICS_PRESET_ACTIVE_OPTIONS_VERY_LOW = ActiveOptions) then
      FGraphicsQuality := gqVeryLow
  else
      FGraphicsQuality := gqCustom;

  if Sync then
      GraphicsQuality := GraphicsQuality;
end;

procedure TSettingsWrapper.DetermineMenuResolution;
var
  MenuResolution : EnumMenuResolution;
  CurrentDimension : RIntVector2;
begin
  CurrentDimension := Settings.GetDimensionOption(coMenuClientResolution);

  for MenuResolution := low(EnumMenuResolution) to high(EnumMenuResolution) do
    if MENU_RESOLUTIONS[MenuResolution] = CurrentDimension then
    begin
      self.MenuResolution := MenuResolution;
      exit;
    end;
  self.MenuResolution := mrCustom;
end;

procedure TSettingsWrapper.DetermineShadowQualityFromSettings;
var
  ShadowResolution : integer;
begin
  if Settings.GetBooleanOption(coGraphicsShadows) then
  begin
    ShadowResolution := Settings.GetIntegerOption(coGraphicsShadowResolution);
    if ShadowResolution >= 4096 then ShadowQuality := sqUltraHigh
    else if ShadowResolution >= 2048 then ShadowQuality := sqHigh
    else if ShadowResolution >= 1024 then ShadowQuality := sqMedium
    else if ShadowResolution >= 512 then ShadowQuality := sqLow
    else ShadowQuality := sqVeryLow;
  end
  else ShadowQuality := sqOff;
end;

procedure TSettingsWrapper.EndUpdate;
begin
  dec(FBlockUpdate);
  if FBlockUpdate <= 0 then
      Sync;
end;

function TSettingsWrapper.GetAltKeybinding(Binding : EnumKeybinding) : RBinding;
begin
  Result := KeybindingManager.GetMapping(Binding, 1);
end;

function TSettingsWrapper.GetBoolean(Option : EnumClientOption) : Boolean;
begin
  Result := Settings.GetBooleanOption(Option);
end;

function TSettingsWrapper.GetInteger(Option : EnumClientOption) : integer;
begin
  Result := Settings.GetIntegerOption(Option);
end;

function TSettingsWrapper.GetKeybinding(Binding : EnumKeybinding) : RBinding;
begin
  Result := KeybindingManager.GetMapping(Binding, 0);
end;

procedure TSettingsWrapper.Idle;
var
  Key : EnumKeyboardKey;
  Button : EnumMouseButton;
begin
  inherited;
  if (KeyToBind <> kbNone) and (NewBinding.IsEmpty) then
  begin
    FNewKeybinding.Strg := Keyboard.Strg;
    FNewKeybinding.Alt := Keyboard.Alt;
    FNewKeybinding.Shift := Keyboard.Shift;
    for Key := low(EnumKeyboardKey) to high(EnumKeyboardKey) do
      if Keyboard.KeyIsDown(Key) and not(Key in [TasteFeststelltaste, TasteShiftLinks, TasteShiftRechts, TasteAltLeft, TasteAltGr, TasteSTRGLinks, TasteSTRGRechts]) then
      begin
        FNewKeybinding.KeyboardKeyCode := Key;
        break;
      end;
    if NewBinding.IsEmpty then
    begin
      for Button := low(EnumMouseButton) to high(EnumMouseButton) do
        if Mouse.ButtonIsDown(Button) then
        begin
          FNewKeybinding.MouseKeyCode := Button;
          break;
        end;
    end;
    // Prevent some important keys from being used directy
    if (FNewKeybinding.KeyboardKeyCode in [TasteEsc]) then
        FNewKeybinding.KeyboardKeyCode := TasteNone;
    if (FNewKeybinding.MouseKeyCode in [mbLeft, mbRight]) and not(FNewKeybinding.Strg or FNewKeybinding.Shift or FNewKeybinding.Alt) then
        FNewKeybinding.MouseKeyCode := mbNone;

    NewBinding := FNewKeybinding;
  end;
end;

function TSettingsWrapper.IsRebindValid : Boolean;
begin
  Result := not NewBinding.IsEmpty;
end;

function TSettingsWrapper.KeyToBindString : string;
begin
  Result := HRTTi.EnumerationToString<EnumKeybinding>(KeyToBind);
end;

procedure TSettingsWrapper.RebindKey(Key : EnumKeybinding; Alt : Boolean);
begin
  KeyToBind := Key;
  NewBinding := RBinding.EMPTY;
  if Alt then FNewKeybindingIndex := 1
  else FNewKeybindingIndex := 0;
end;

procedure TSettingsWrapper.Refresh;
var
  ClickPrecisionValue : single;
  KeyBinding : EnumKeybinding;
begin
  DetermineShadowQualityFromSettings;
  DetermineGraphicsQualityFromSettings(True);
  DisplayMode := Settings.GetEnumOption<EnumDisplayMode>(coEngineDisplayMode);
  HealthBarMode := Settings.GetEnumOption<EnumHealthbarMode>(coGameplayHealthbarMode);
  DropZoneMode := Settings.GetEnumOption<EnumDropZoneMode>(coGameplayDropZoneMode);
  TextureQuality := Settings.GetEnumOption<EnumTextureQuality>(coGraphicsTextureQuality);
  ClickPrecisionValue := Settings.GetSingleOption(coGameplayClickPrecision);
  DetermineMenuResolution;
  DetermineCurrentLanguage;
  MenuScaling := Settings.GetEnumOption<EnumMenuScaling>(coMenuClientScaling);
  if ClickPrecisionValue > 1.0 then
      ClickPrecision := cpWide
  else if ClickPrecisionValue > 0.0 then
      ClickPrecision := cpExtended
  else
      ClickPrecision := cpPrecise;

  for KeyBinding := low(EnumKeybinding) to high(EnumKeybinding) do
  begin
    KeybindingManager.SetMapping(KeyBinding, 0, Settings.GetKeybinding(EnumClientOption(ord(coKeybindingBindingNone) + ord(KeyBinding) * 2)));
    KeybindingManager.SetMapping(KeyBinding, 1, Settings.GetKeybinding(EnumClientOption(ord(coKeybindingBindingNone) + ord(KeyBinding) * 2 + 1)));
  end;
end;

procedure TSettingsWrapper.DeleteKey(Key : EnumKeybinding; Alt : Boolean);
begin
  KeybindingManager.SetMapping(Key, HGeneric.TertOp<integer>(Alt, 1, 0), RBinding.EMPTY);
  Settings.SetKeybinding(EnumClientOption(ord(coKeybindingBindingNone) + ord(Key) * 2 + HGeneric.TertOp<integer>(Alt, 1, 0)), RBinding.EMPTY);
  Sync;
end;

procedure TSettingsWrapper.RevertCategory(Category : EnumOptionType);
var
  RevertedOptions : SetClientOption;
  Option : EnumClientOption;
begin
  case Category of
    otSound : RevertedOptions := OPTIONS_SOUND;
    otSoundMeta : RevertedOptions := OPTIONS_SOUND_META;
    otGraphics : RevertedOptions := OPTIONS_GRAPHICS;
    otGameplay : RevertedOptions := OPTIONS_GAMEPLAY;
    otMenu : RevertedOptions := OPTIONS_MENU;
    otEngine : RevertedOptions := OPTIONS_ENGINE;
    otSandbox : RevertedOptions := OPTIONS_SANDBOX;
    otGeneral : RevertedOptions := OPTIONS_GENERAL;
    otKeybinding : RevertedOptions := OPTIONS_KEYBINDING;
    otServer : RevertedOptions := OPTIONS_SERVER;
  else
    exit;
  end;
  for Option in RevertedOptions do
      Settings.RevertOption(Option);
  Refresh;
  Sync;
end;

procedure TSettingsWrapper.SetAvailableLanguages(const Value : TUltimateList<RSteamLanguage>);
begin
  FAvailableLanguages := Value;
end;

procedure TSettingsWrapper.SetBoolean(Option : EnumClientOption; Value : Boolean);
begin
  Settings.SetBooleanOption(Option, Value);
end;

procedure TSettingsWrapper.SetClickPrecision(const Value : EnumClickPrecision);
begin
  case Value of
    cpPrecise : Settings.SetStringOption(coGameplayClickPrecision, '0.0');
    cpExtended : Settings.SetStringOption(coGameplayClickPrecision, '0.5');
    cpWide : Settings.SetStringOption(coGameplayClickPrecision, '1.0');
  end;
  FClickPrecision := Value;
end;

procedure TSettingsWrapper.SetCurrentLanguage(const Value : RSteamLanguage);
{$IFDEF STEAM}
var
  SteamLanguageKey : string;
  {$ENDIF}
begin
  FCurrentLanguage := Value;
  {$IFDEF STEAM}
  SteamLanguageKey := SteamApps.GetCurrentGameLanguage;
  if (Value.SteamLanguageCode = '') or (SteamLanguageKey = Value.SteamLanguageCode) then
      Settings.RevertOption(coGeneralLanguage)
  else
    {$ENDIF}
      Settings.SetStringOption(coGeneralLanguage, Value.WebApiLanguageCode);
end;

procedure TSettingsWrapper.SetDisplayMode(const Value : EnumDisplayMode);
begin
  Settings.SetEnumOption<EnumDisplayMode>(coEngineDisplayMode, Value);
  FDisplayMode := Value;
end;

procedure TSettingsWrapper.SetDropZoneMode(const Value : EnumDropZoneMode);
begin
  Settings.SetEnumOption<EnumDropZoneMode>(coGameplayDropZoneMode, Value);
  FDropZoneMode := Value;
end;

procedure TSettingsWrapper.SetGraphicsQuality(const Value : EnumGraphicsQuality);
begin
  FGraphicsQuality := Value;
  BeginUpdate;
  WriteGraphicsQualityToSettings(Value);
  DetermineShadowQualityFromSettings;
  EndUpdate;
end;

procedure TSettingsWrapper.SetHealthbarMode(const Value : EnumHealthbarMode);
begin
  Settings.SetEnumOption<EnumHealthbarMode>(coGameplayHealthbarMode, Value);
  FHealthbarMode := Value;
end;

procedure TSettingsWrapper.SetInteger(Option : EnumClientOption; Value : integer);
begin
  Settings.SetIntegerOption(Option, Value);
end;

procedure TSettingsWrapper.SetKeyToBind(const Value : EnumKeybinding);
begin
  FKeyToBind := Value;
end;

procedure TSettingsWrapper.SetMenuResolution(const Value : EnumMenuResolution);
begin
  FMenuResolution := Value;
  if Value <> mrCustom then
      Settings.SetDimensionOption(coMenuClientResolution, MENU_RESOLUTIONS[Value]);
end;

procedure TSettingsWrapper.SetMenuScaling(const Value : EnumMenuScaling);
begin
  FMenuScaling := Value;
  Settings.SetEnumOption<EnumMenuScaling>(coMenuClientScaling, Value);
end;

procedure TSettingsWrapper.SetNewKeybinding(const Value : RBinding);
begin
  FNewKeybinding := Value;
end;

procedure TSettingsWrapper.SetShadowQuality(const Value : EnumShadowQuality);
begin
  FShadowQuality := Value;
  BeginUpdate;
  WriteShadowQualityToSettings(Value);
  DetermineGraphicsQualityFromSettings;
  EndUpdate;
end;

procedure TSettingsWrapper.SetTextureQuality(const Value : EnumTextureQuality);
begin
  FTextureQuality := Value;
  Settings.SetEnumOption<EnumTextureQuality>(coGraphicsTextureQuality, Value);
end;

procedure TSettingsWrapper.Sync;
begin
  if FBlockUpdate <= 0 then
  begin
    DetermineGraphicsQualityFromSettings(False);
    DetermineCurrentLanguage;
    GUI.SetContext('settings', self);
  end;
end;

class procedure TSettingsWrapper.WriteGraphicsQualityToSettings(const Value : EnumGraphicsQuality);
var
  ActiveOptions : SetClientOption;
begin
  if Value <> gqCustom then
  begin
    TSettingsWrapper.WriteShadowQualityToSettings(GRAPHICS_PRESET_SHADOW_QUALITY[Value]);
    case Value of
      gqVeryLow : ActiveOptions := GRAPHICS_PRESET_ACTIVE_OPTIONS_VERY_LOW;
      gqLow : ActiveOptions := GRAPHICS_PRESET_ACTIVE_OPTIONS_LOW;
      gqMedium : ActiveOptions := GRAPHICS_PRESET_ACTIVE_OPTIONS_MEDIUM;
      gqHigh : ActiveOptions := GRAPHICS_PRESET_ACTIVE_OPTIONS_HIGH;
      gqVeryHigh : ActiveOptions := GRAPHICS_PRESET_ACTIVE_OPTIONS_VERY_HIGH;
    end;
    Settings.SetBooleanOption(coGraphicsDeferredShading, coGraphicsDeferredShading in ActiveOptions);
    Settings.SetBooleanOption(coGraphicsGUIBlurBackgrounds, coGraphicsGUIBlurBackgrounds in ActiveOptions);
    Settings.SetBooleanOption(coGraphicsPostEffectToon, coGraphicsPostEffectToon in ActiveOptions);
    Settings.SetBooleanOption(coGraphicsPostEffectGlow, coGraphicsPostEffectGlow in ActiveOptions);
    Settings.SetBooleanOption(coGraphicsPostEffectFXAA, coGraphicsPostEffectFXAA in ActiveOptions);
    Settings.SetBooleanOption(coGraphicsPostEffectUnsharpMasking, coGraphicsPostEffectUnsharpMasking in ActiveOptions);
    Settings.SetBooleanOption(coGraphicsPostEffectDistortion, coGraphicsPostEffectDistortion in ActiveOptions);
    Settings.SetBooleanOption(coGraphicsPostEffectSSAO, coGraphicsPostEffectSSAO in ActiveOptions);
  end;
end;

class procedure TSettingsWrapper.WriteShadowQualityToSettings(const Value : EnumShadowQuality);
begin
  if Value <> sqOff then Settings.SetBooleanOption(coGraphicsShadows, True);
  case Value of
    sqOff : Settings.SetBooleanOption(coGraphicsShadows, False);
    sqVeryLow :
      begin
        Settings.SetIntegerOption(coGraphicsShadowResolution, 256);
        Settings.SetStringOption(coEngineShadowBiasMin, '0.11');
        Settings.SetStringOption(coEngineShadowBiasMax, '0.22');
        Settings.SetStringOption(coEngineShadowSlopeBias, '3.4');
      end;
    sqLow :
      begin
        Settings.SetIntegerOption(coGraphicsShadowResolution, 512);
        Settings.SetStringOption(coEngineShadowBiasMin, '0.11');
        Settings.SetStringOption(coEngineShadowBiasMax, '0.22');
        Settings.SetStringOption(coEngineShadowSlopeBias, '1.9');
      end;
    sqMedium :
      begin
        Settings.SetIntegerOption(coGraphicsShadowResolution, 1024);
        Settings.SetStringOption(coEngineShadowBiasMin, '0.03');
        Settings.SetStringOption(coEngineShadowBiasMax, '0.06');
        Settings.SetStringOption(coEngineShadowSlopeBias, '0.8');
      end;
    sqHigh :
      begin
        Settings.SetIntegerOption(coGraphicsShadowResolution, 2048);
        Settings.SetStringOption(coEngineShadowBiasMin, '0.01');
        Settings.SetStringOption(coEngineShadowBiasMax, '0.02');
        Settings.SetStringOption(coEngineShadowSlopeBias, '0.5');
      end;
    sqUltraHigh :
      begin
        Settings.SetIntegerOption(coGraphicsShadowResolution, 4096);
        Settings.SetStringOption(coEngineShadowBiasMin, '0.01');
        Settings.SetStringOption(coEngineShadowBiasMax, '0.02');
        Settings.SetStringOption(coEngineShadowSlopeBias, '0.35');
      end;
  end;
end;

{ TGameStateComponentSettings }

constructor TGameStateComponentSettings.Create(Owner : TEntity; Parent : TGameState);
begin
  FPassive := True;
  inherited Create(Owner, Parent);
  FSettings := TSettingsWrapper.Create;
end;

procedure TGameStateComponentSettings.DeactivateAndDiscardSettings;
begin
  Settings.LoadSnapshot;
  FSettings.Refresh;
  FSettings.Sync;
  Parent.Owner.DialogManager.CloseDialog(diSettings);
end;

procedure TGameStateComponentSettings.DeactivateAndSaveSettings;
begin
  Settings.SaveSettings;
  FSettings.Sync;
  Parent.Owner.DialogManager.CloseDialog(diSettings);
end;

destructor TGameStateComponentSettings.Destroy;
begin
  Parent.Owner.DialogManager.UnSubscribe(diSettings, OnDialogOpen);
  GUI.SetContext('settings_menu', nil);
  FSettings.Free;
  inherited;
end;

procedure TGameStateComponentSettings.Idle;
begin
  inherited;
  FSettings.Idle;
end;

procedure TGameStateComponentSettings.Initialize;
begin
  inherited;
  Parent.Owner.DialogManager.Subscribe(diSettings, OnDialogOpen);
  Category := otMenu;
  FSettings.Refresh;
  GUI.SetContext('settings_menu', self);
  FSettings.Sync;
end;

function TGameStateComponentSettings.OnClientOption(ChangedOption : RParam) : Boolean;
begin
  Result := True;
  if FInitialized then
  begin
    FSettings.Sync;
    Parent.Owner.UpdateSettingsOption(ChangedOption.AsEnumType<EnumClientOption>);
  end;
end;

procedure TGameStateComponentSettings.OnDialogOpen(Open : Boolean);
begin
  if Open then
  begin
    Settings.SaveSnapshot;
    if Parent.Owner.IsClientWindow then
        Category := otMenu
    else
        Category := otGraphics
  end;
end;

procedure TGameStateComponentSettings.ParentEntered;
begin
  inherited;
  GUI.SetContext('settings_menu', self);
  FSettings.Sync;
end;

procedure TGameStateComponentSettings.ParentLeft;
begin
  inherited;
  GUI.SetContext('settings_menu', nil);
  FSettings.Sync;
end;

procedure TGameStateComponentSettings.SetCategory(const Value : EnumOptionType);
begin
  FCategory := Value;
end;

{ TGameStateComponentCollection }

procedure TGameStateComponentCollection.BuildCards;
var
  Cards : IDataQuery<TCard>;
  Card : TCard;
  CollectionCard : TCollectionCard;
  PositionDict : TDictionary<string, RVector2>;
  CardList : TList<TCollectionCard>;
begin
  PositionDict := TDictionary<string, RVector2>.Create;

  // Black card positions
  // ---------------------
  PositionDict.Add('VoidWorm Drop', RVector2.Create(0, 1.5));

  PositionDict.Add('Frenzy', RVector2.Create(1, 1));
  PositionDict.Add('Frostspear', RVector2.Create(1, 2));

  PositionDict.Add('VoidBane Drop', RVector2.Create(2, 0));
  PositionDict.Add('VoidWorm Spawner', RVector2.Create(2, 2));
  PositionDict.Add('VoidSkeleton Spawner', RVector2.Create(2, 1));
  PositionDict.Add('VoidSkeleton Drop', RVector2.Create(2, 3));

  PositionDict.Add('VoidBowman Drop', RVector2.Create(3, 1));
  PositionDict.Add('Freeze', RVector2.Create(3, 2));

  PositionDict.Add('VoidCauldron Drop', RVector2.Create(4, 0));
  PositionDict.Add('VoidBane Spawner', RVector2.Create(4, 1));
  PositionDict.Add('VoidCauldron Spawner', RVector2.Create(4, 2));
  PositionDict.Add('VoidBowman Spawner', RVector2.Create(4, 3));

  PositionDict.Add('RipOutSoul', RVector2.Create(5, 0));
  PositionDict.Add('PermaFrost', RVector2.Create(5, 2));
  PositionDict.Add('ShatterIce', RVector2.Create(5, 3));

  PositionDict.Add('Frostgoyle Drop', RVector2.Create(6, 0));
  PositionDict.Add('VoidWraith Drop', RVector2.Create(6, 2));
  PositionDict.Add('Frostgoyle Spawner', RVector2.Create(6, 3));

  PositionDict.Add('VoidWraith Spawner', RVector2.Create(7, 1));
  PositionDict.Add('FrostgoyleFountain Building', RVector2.Create(7, 3));

  PositionDict.Add('Tyrus Drop', RVector2.Create(8, 0));
  PositionDict.Add('VoidSlime Drop', RVector2.Create(8, 2));

  PositionDict.Add('Vecra Drop', RVector2.Create(9, 3));

  PositionDict.Add('VoidAltar Building', RVector2.Create(10, 0));
  PositionDict.Add('VoidSlime Spawner', RVector2.Create(9, 1));
  PositionDict.Add('Undying', RVector2.Create(10, 3));

  // White card positions
  // ---------------------
  PositionDict.Add('Footman Drop', RVector2.Create(0, 1.5));

  PositionDict.Add('ShieldsUp', RVector2.Create(1, 1));
  PositionDict.Add('LightPulse', RVector2.Create(1, 2));

  PositionDict.Add('Archer Drop', RVector2.Create(2, 0));
  PositionDict.Add('Footman Spawner', RVector2.Create(2, 1));
  PositionDict.Add('Archer Spawner', RVector2.Create(2, 2));
  PositionDict.Add('Monk Drop', RVector2.Create(2, 3));

  PositionDict.Add('Priest Drop', RVector2.Create(3, 1));
  PositionDict.Add('SurgeOfLight', RVector2.Create(3, 2));

  PositionDict.Add('HailOfArrows', RVector2.Create(4, 0));
  PositionDict.Add('Priest Spawner', RVector2.Create(4, 3));

  PositionDict.Add('HeavyGunner Drop', RVector2.Create(5, 0));
  PositionDict.Add('Monk Spawner', RVector2.Create(5, 1));
  PositionDict.Add('HeavyGunner Spawner', RVector2.Create(5, 2));

  PositionDict.Add('Avenger Drop', RVector2.Create(6, 1));
  PositionDict.Add('Ballista Drop', RVector2.Create(6, 2));

  PositionDict.Add('MonumentOfLight Building', RVector2.Create(7, 0));
  PositionDict.Add('Ballista Spawner', RVector2.Create(7, 1));
  PositionDict.Add('Avenger Spawner', RVector2.Create(7, 2));
  PositionDict.Add('SolarFlare', RVector2.Create(7, 3));

  PositionDict.Add('PatronSaint Drop', RVector2.Create(8, 1));
  PositionDict.Add('Defender Drop', RVector2.Create(8, 2));

  PositionDict.Add('Marksman Spawner', RVector2.Create(9, 1));
  PositionDict.Add('Marksman Drop', RVector2.Create(9, 2));

  PositionDict.Add('PromiseOfLife', RVector2.Create(10, 1));
  PositionDict.Add('Suntower Building', RVector2.Create(10, 2));

  // Green card positions
  // ---------------------
  PositionDict.Add('Thistle Drop', RVector2.Create(0, 1.5));

  PositionDict.Add('GiantGrowth', RVector2.Create(1, 1));
  PositionDict.Add('EntanglingRoots', RVector2.Create(1, 2));

  PositionDict.Add('Rootling Drop', RVector2.Create(2, 0));
  PositionDict.Add('SaplingFarm Building', RVector2.Create(2, 1));
  PositionDict.Add('Thistle Spawner', RVector2.Create(2, 2));
  PositionDict.Add('Rootling Spawner', RVector2.Create(2, 3));

  PositionDict.Add('Woodwalker Spawner', RVector2.Create(3, 0));
  PositionDict.Add('Rootdude Drop', RVector2.Create(3, 2));
  PositionDict.Add('HealingGarden', RVector2.Create(3, 3));

  PositionDict.Add('ForestGuardian Building', RVector2.Create(4, 1));
  PositionDict.Add('Woodwalker Drop', RVector2.Create(4, 2));

  PositionDict.Add('HeartOfTheForest Spawner', RVector2.Create(5, 1));
  PositionDict.Add('HeartOfTheForest Drop', RVector2.Create(5, 3));

  PositionDict.Add('Wisp Drop', RVector2.Create(6, 0));
  PositionDict.Add('Wisp Spawner', RVector2.Create(6, 3));

  PositionDict.Add('EvolveThistle', RVector2.Create(7, 1));
  PositionDict.Add('Oracle Drop', RVector2.Create(7, 2));

  PositionDict.Add('Spore Spawner', RVector2.Create(8, 0));
  PositionDict.Add('Rootdude Spawner', RVector2.Create(8, 1));
  PositionDict.Add('Spore Drop', RVector2.Create(8, 2));

  PositionDict.Add('Groundbreaker Spawner', RVector2.Create(9, 0));
  PositionDict.Add('SaplingCharge', RVector2.Create(9, 1));
  PositionDict.Add('Brratu Drop', RVector2.Create(9, 2));
  PositionDict.Add('Groundbreaker Drop', RVector2.Create(9, 3));

  PositionDict.Add('Oracle Spawner', RVector2.Create(10, 1));
  PositionDict.Add('EvolveOracle', RVector2.Create(10, 2));

  // Blue card positions
  // ---------------------
  PositionDict.Add('GatlingDrone Drop', RVector2.Create(0, 1.5));

  PositionDict.Add('EnergyRift', RVector2.Create(1, 1));
  PositionDict.Add('Relocate', RVector2.Create(1, 2));

  PositionDict.Add('GatlingDrone Spawner', RVector2.Create(2, 0));
  PositionDict.Add('DamperDrone Spawner', RVector2.Create(2, 1));
  PositionDict.Add('GatlingTurret Building', RVector2.Create(2, 2));
  PositionDict.Add('DamperDrone Drop', RVector2.Create(2, 3));

  PositionDict.Add('InverseGravity', RVector2.Create(3, 0));
  PositionDict.Add('AmmoRefill', RVector2.Create(3, 2));

  PositionDict.Add('PhaseDrone Drop', RVector2.Create(4, 1));
  PositionDict.Add('MissileTurret Building', RVector2.Create(4, 3));

  PositionDict.Add('PhaseDrone Spawner', RVector2.Create(5, 0));
  PositionDict.Add('Inductioner Drop', RVector2.Create(5, 2));

  PositionDict.Add('ShieldDrone Drop', RVector2.Create(6, 0));
  PositionDict.Add('FluxField', RVector2.Create(6, 1));
  PositionDict.Add('ObserverDrone Building', RVector2.Create(6, 3));

  PositionDict.Add('Airdominator Drop', RVector2.Create(7, 0));
  PositionDict.Add('Inductioner Spawner', RVector2.Create(7, 1));
  PositionDict.Add('AmmoFactory Building', RVector2.Create(7, 2));
  PositionDict.Add('ShieldDrone Spawner', RVector2.Create(7, 3));

  PositionDict.Add('Atlas Drop', RVector2.Create(8, 1));
  PositionDict.Add('Aegis Building', RVector2.Create(8, 2));
  PositionDict.Add('FactoryReset', RVector2.Create(8, 3));

  PositionDict.Add('Bombardier Spawner', RVector2.Create(9, 0));
  PositionDict.Add('Bombardier Drop', RVector2.Create(9, 3));

  PositionDict.Add('Airdominator Spawner', RVector2.Create(10, 1));
  PositionDict.Add('OrbitalStrike', RVector2.Create(10, 2));

  // Golem card positions
  // ---------------------
  PositionDict.Add('Golems SmallMeleeGolem Drop', RVector2.Create(0, 1.5));

  PositionDict.Add('EchoesOfTheFuture', RVector2.Create(1, 1));
  PositionDict.Add('Cataclysm', RVector2.Create(1, 2));

  PositionDict.Add('Golems SmallRangedGolem Spawner', RVector2.Create(2, 0));
  PositionDict.Add('Golems SmallGolemTower Building', RVector2.Create(2, 1));
  PositionDict.Add('Golems SmallMeleeGolem Spawner', RVector2.Create(2, 2));
  PositionDict.Add('Golems SmallRangedGolem Drop', RVector2.Create(2, 3));

  PositionDict.Add('Golems MediumMeleeGolem Drop', RVector2.Create(3, 0));
  PositionDict.Add('Golems SiegeGolem Spawner', RVector2.Create(3, 2));

  PositionDict.Add('Golems MeleeGolemTower Building', RVector2.Create(4, 1));
  PositionDict.Add('Golems MediumMeleeGolem Spawner', RVector2.Create(4, 2));
  PositionDict.Add('Petrify', RVector2.Create(4, 3));

  PositionDict.Add('Golems SmallCasterGolem Spawner', RVector2.Create(5, 0));
  PositionDict.Add('Golems SiegeGolem Drop', RVector2.Create(5, 2));

  PositionDict.Add('Golems SmallFlyingGolem Drop', RVector2.Create(6, 0));
  PositionDict.Add('Golems BigCasterGolem Spawner', RVector2.Create(6, 1));
  PositionDict.Add('Golems BigMeleeGolem Drop', RVector2.Create(6, 2));
  PositionDict.Add('Golems BigCasterGolem Drop', RVector2.Create(6, 3));

  PositionDict.Add('Golems SmallFlyingGolem Spawner', RVector2.Create(7, 0));
  PositionDict.Add('StoneCircle', RVector2.Create(7, 1));
  PositionDict.Add('Golems SmallCasterGolem Drop', RVector2.Create(7, 3));

  PositionDict.Add('Golems BossGolem Drop', RVector2.Create(8, 1));
  PositionDict.Add('Earthquake', RVector2.Create(8, 2));

  PositionDict.Add('Golems BigFlyingGolem Spawner', RVector2.Create(9, 0));
  PositionDict.Add('Golems BigGolemTower Building', RVector2.Create(9, 3));

  PositionDict.Add('Golems BigMeleeGolem Spawner', RVector2.Create(10, 1));
  PositionDict.Add('Golems BigFlyingGolem Drop', RVector2.Create(10, 2));

  FCards.Clear;
  CardList := TList<TCollectionCard>.Create;
  Cards := CardManager.Cards.Query.Filter(F('IsObtainableByPlayers') and (RQuery.From<EnumEntityColor>(FTab) in F('Colors')));
  for Card in Cards do
  begin
    if not FCollectionCardCache.TryGetValue(Card, CollectionCard) then
    begin
      CollectionCard := TCollectionCard.Create;
      CollectionCard.Card := Card;
      if not PositionDict.TryGetValue(Card.name, CollectionCard.Position) then
      begin
        {$IFDEF RELEASE}
        CollectionCard.Free;
        continue;
        {$ELSE}
        CollectionCard.Position := RVector2.Create(random, random);
        {$ENDIF}
      end;
      FCollectionCardCache.Add(Card, CollectionCard);
    end;
    CardList.Add(CollectionCard);
  end;
  CardList.Sort(TComparer<TCollectionCard>.Construct(
    function(const L, R : TCollectionCard) : integer
    begin
      Result := round(L.Position.X * 10) - round(R.Position.X * 10);
      if Result = 0 then
          Result := round(L.Position.Y * 10) - round(R.Position.Y * 10);
    end));
  FCards.AddRange(CardList);
  CardList.Free;
  PositionDict.Free;
end;

destructor TGameStateComponentCollection.Destroy;
begin
  GUI.SetContext('collection', nil);
  FCards.Free;
  FCollectionCardCache.Free;
  inherited;
end;

function TGameStateComponentCollection.GetCardManager : TCardManager;
begin
  Result := BaseConflict.Api.Cards.CardManager;
end;

procedure TGameStateComponentCollection.Initialize;
begin
  if assigned(CardManager) then
  begin
    FTab := ecWhite;
    FCollectionCardCache := TObjectDictionary<TCard, TCollectionCard>.Create([doOwnsValues]);
    FCards := TUltimateList<TCollectionCard>.Create;

    // if Collection changed apply filters and update paginator
    CardManager.Cards.OnChange := OnCardsChange;
    CardManager.OnCardUnlocked := OnCardUnlocked;
    GUI.SetContext('collection', self);
    inherited;
  end;
end;

procedure TGameStateComponentCollection.OnCardsChange(Sender : TUltimateList<TCard>; Items : TArray<TCard>; Action : EnumListAction; Indices : TArray<integer>);
begin
  BuildCards;
end;

procedure TGameStateComponentCollection.OnCardUnlocked(UnlockedCard : TCard);
begin
  Parent.GetComponent<TGameStateComponentNotification>.AddCardUnlock(UnlockedCard);
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_CARD_UNLOCK);
end;

procedure TGameStateComponentCollection.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('collection', self);
end;

procedure TGameStateComponentCollection.ParentLeft;
begin
  inherited;
  GUI.SetContext('collection', nil);
end;

procedure TGameStateComponentCollection.SetCardManager(const Value : TCardManager);
begin
  // only notification
end;

procedure TGameStateComponentCollection.SetChosenCard(const Value : TCard);
begin
  if MainActionQueue.IsActive then
      FChosenCard := Value
  else
      TActionSetVariable<TCard>.Create(Value, ChosenCard, SetChosenCard).Deploy;
end;

procedure TGameStateComponentCollection.SetShopItem(const Value : TShopItem);
begin
  if MainActionQueue.IsActive then
      FShopItem := Value
  else
      TActionSetVariable<TShopItem>.Create(Value, ShopItem, SetShopItem).Deploy;
end;

procedure TGameStateComponentCollection.SetTab(const Value : EnumEntityColor);
begin
  if Value in [ecBlack, ecGreen, ecBlue, ecWhite, ecColorless] then
  begin
    FTab := Value;
    BuildCards;
  end;
end;

procedure TGameStateComponentCollection.ShowCardDetail(const Card : TCard);
begin
  ChosenCard := Card;
  ShopItem := Shop.ResolveShopItemBuyCardInstance(Card);
  Parent.Owner.DialogManager.OpenDialog(diCollectionCardDetail);
end;

{ TGameStateComponentProfile }

function TGameStateComponentProfile.CanSpectate : Boolean;
begin
  Result := Settings.GetBooleanOption(coGeneralEnableSpectator);
end;

procedure TGameStateComponentProfile.ChoosePlayerIcon(const IconUID : string);
begin
  if assigned(Account) then Profile.Icon := IconUID;
  Parent.Owner.DialogManager.CloseDialog(diPlayerIcon);
  QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_SET_PROFILE_ICON);
end;

destructor TGameStateComponentProfile.Destroy;
begin
  GUI.SetContext('profile', nil);
  FTutorialVideoPaginator.Free;
  FTutorialVideoPage.Free;
  inherited;
end;

procedure TGameStateComponentProfile.SetIsTutorialGameDialogOpen(const Value : Boolean);
begin
  FIsTutorialGameDialogOpen := Value;
end;

procedure TGameStateComponentProfile.SetTutorialVideoPaginator(const Value : TPaginator<TTutorialVideo>);
begin
  // only notification
end;

function TGameStateComponentProfile.TranslationPercentage : string;
var
  Progress : integer;
  Classes : string;
begin
  Progress := TranslationProgress;
  if Progress >= 100 then
      Classes := 'premium'
  else if Progress >= 60 then
      Classes := 'warning'
  else if Progress >= 10 then
      Classes := 'questcount'
  else
      Classes := 'danger';
  Result := '<span class="' + Classes + '">' + HInternationalizer.MakePercentage(IntToStr(Progress)) + '</span>';
end;

function TGameStateComponentProfile.TranslationProgress : integer;
begin
  Result := trunc(HInternationalizer.TranslationProgress * 100);
end;

procedure TGameStateComponentProfile.TutorialFinished;
begin
  IsTutorialGameDialogOpen := False;
  if not UserProfile.TutorialPlayed then
  begin
    (Parent as TGameStateMainMenu).CurrentMenu := mtStart;
    RedeemStarterDecks;
    MainActionQueue.DoAction(TActionInline.Create.OnExecuteSynchronized(
      function() : Boolean
      begin
        Result := True;
        Parent.GetComponent<TGameStateComponentMetaTutorial>.StartMetaTutorial;
        Parent.GetComponent<TGameStateComponentMatchMaking>.ChosenScenario := es1v1;
        if not assigned(Matchmaking.CurrentTeam.Deck) then
            Matchmaking.CurrentTeam.ChooseDeck(Deckbuilding.GetDefaultDeck);
      end))
  end;
end;

function TGameStateComponentProfile.GetAccount : TAccount;
begin
  Result := BaseConflict.Api.Account.Account;
end;

function TGameStateComponentProfile.GetProfile : TUserProfile;
begin
  Result := UserProfile;
end;

procedure TGameStateComponentProfile.Initialize;
begin
  if assigned(UserProfile) and Parent.Owner.IsApiReady then
  begin
    // profile is initialized
    Profile.BotsDisabled := Settings.GetBooleanOption(coGeneralDisableBots);

    FTutorialVideoPage := TUltimateList<TTutorialVideo>.Create;
    FTutorialVideoPaginator := TPaginator<TTutorialVideo>.Create(UserProfile.TutorialVideos, 2 * 1, False);
    FTutorialVideoPaginator.OnChange := procedure()
      begin
        // notify gui of changes
        TutorialVideoPaginator := nil;
        FTutorialVideoPage.Clear;
        FTutorialVideoPage.AddRange(FTutorialVideoPaginator.CurrentObjects);
      end;
    FTutorialVideoPaginator.OnChange();

    IsTutorialGameDialogOpen := not UserProfile.TutorialPlayed;

    GUI.SetContext('profile', self);
    inherited;
  end;
end;

function TGameStateComponentProfile.IsTranslationFinished : Boolean;
begin
  Result := HInternationalizer.TranslationProgress >= 1.0;
end;

procedure TGameStateComponentProfile.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('profile', self);
end;

procedure TGameStateComponentProfile.ParentLeft;
begin
  inherited;
  GUI.SetContext('profile', nil);
end;

procedure TGameStateComponentProfile.RedeemStarterDecks;
begin
  if not UserProfile.TutorialPlayed then
  begin
    // we unlock all starter decks so we have to block five times 7 unlocks
    Parent.GetComponent<TGameStateComponentNotification>.Block(35);
    Parent.Owner.IsLoading := True;
    CardManager.ChooseStarterDeck(ecWhite);
    MainActionQueue.DoAction(TActionInline.Create.OnExecuteSynchronized(
      function() : Boolean
      begin
        Result := True;
        MainActionQueue.DoAction(TActionInline.Create.OnExecuteSynchronized(
          function() : Boolean
          begin
            Result := True;
            CardManager.CleanAllNewFlags;
            Parent.Owner.IsLoading := False;
          end))
      end));
  end;
end;

{ TGameStateComponentFeedback }

constructor TGameStateComponentFeedback.Create(Owner : TEntity; Parent : TGameState);
begin
  FPassive := True;
  inherited Create(Owner, Parent);
end;

destructor TGameStateComponentFeedback.Destroy;
begin
  GUI.SetContext('feedback', nil);
  inherited;
end;

procedure TGameStateComponentFeedback.Initialize;
begin
  inherited;
  GUI.SetContext('feedback', self);
end;

procedure TGameStateComponentFeedback.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('feedback', self);
end;

procedure TGameStateComponentFeedback.ParentLeft;
begin
  inherited;
  GUI.SetContext('feedback', nil);
end;

procedure TGameStateComponentFeedback.SendFeedback;
begin
  if Account.IsConnected then
      Account.SendFeedback(Feedback)
  else
      AccountAPI.SendCustomBugReport(Feedback, '').Free;
  Feedback := '';
  Parent.Owner.DialogManager.CloseDialog(diFeedback);
  Parent.Owner.ShowErrorConfirm('§feedback_sent_caption', '§feedback_sent_text', '§feedback_sent_confirm');
end;

procedure TGameStateComponentFeedback.SetFeedback(const Value : string);
begin
  FFeedback := Value;
end;

{ TGameStateComponentNotification }

procedure TGameStateComponentNotification.AddCardUnlock(const Card : TCard);
begin
  if IsBlocked then exit;
  AddNotification(TNotificationCardUnlock.Create(self, Card));
end;

procedure TGameStateComponentNotification.AddFriendRequest(const Request : TFriendRequest);
begin
  exit; // disabled for now
  if IsBlocked then exit;
  AddNotification(TNotificationFriendRequest.Create(self, Request));
end;

procedure TGameStateComponentNotification.AddMessage(const Msg : TMessage);
begin
  AddNotification(TNotificationMessage.Create(self, Msg));
end;

procedure TGameStateComponentNotification.AddNotification(Notification : TNotification);
begin
  FNotifications.Add(Notification);
  if FNotifications.Count = 1 then
      Parent.Owner.DialogManager.OpenDialog(diNotification);
end;

procedure TGameStateComponentNotification.AddRewards(const Rewards : TArray<RReward>);
begin
  if IsBlocked then exit;
  // hack for starterdeck
  if (length(Rewards) = 1) and (Rewards[0].ShopItem.ItemType = itLootList) then
      AddNotification(TNotificationLootlist.Create(self, Rewards[0].ShopItem.name))
  else
      AddNotification(TNotificationReward.Create(self, Rewards));
end;

procedure TGameStateComponentNotification.Block(Count : integer);
begin
  FBlock := FBlock + Count;
end;

procedure TGameStateComponentNotification.BlockForTime(Duration : integer);
begin
  FBlockTimer.SetIntervalAndStart(Duration);
end;

function TGameStateComponentNotification.IsBlocked : Boolean;
begin
  if FBlock > 0 then
  begin
    FBlock := FBlock - 1;
    Result := True;
  end
  else
  begin
    FBlock := 0;
    Result := False;
  end;
  Result := Result or not FBlockTimer.Expired;
end;

procedure TGameStateComponentNotification.Close;
begin
  if HasNotification then
  begin
    FNotifications.Insert(0, nil);
    Parent.Owner.DialogManager.CloseDialog(diNotification);
    FNotifications.Delete(1);
    FNotifications.Delete(0);
    if FNotifications.Count > 0 then
        Parent.Owner.DialogManager.OpenDialog(diNotification);
  end;
end;

destructor TGameStateComponentNotification.Destroy;
begin
  GUI.SetContext('notifications', nil);
  FNotifications.Free;
  FBlockTimer.Free;
  Parent.Owner.DialogManager.UnSubscribe(diNotification, OnNotificationOpen);
  inherited;
end;

function TGameStateComponentNotification.HasNotification : Boolean;
begin
  Result := not FNotifications.IsEmpty;
end;

procedure TGameStateComponentNotification.Initialize;
var
  i : integer;
begin
  if Parent.Owner.IsApiReady then
  begin
    FNotifications := TUltimateObjectList<TNotification>.Create;
    FBlockTimer := TTimer.CreateAndStart(1);

    for i := 0 to MessageInbox.Messages.Count - 1 do
        AddMessage(MessageInbox.Messages[i]);
    MessageInbox.OnNewMessage := OnNewMessage;

    Parent.Owner.DialogManager.Subscribe(diNotification, OnNotificationOpen);

    GUI.SetContext('notifications', self);
    inherited;
  end;
end;

function TGameStateComponentNotification.Notification : TNotification;
begin
  if FNotifications.IsEmpty then Result := nil
  else Result := FNotifications.First;
end;

procedure TGameStateComponentNotification.OnNewMessage(const Msg : TMessage);
begin
  AddMessage(Msg);
end;

procedure TGameStateComponentNotification.OnNotificationOpen(Open : Boolean);
begin
  if Open and (FNotifications.Count > 0) then
      FNotifications.First.OnShown;
end;

procedure TGameStateComponentNotification.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('notifications', self);
end;

procedure TGameStateComponentNotification.ParentLeft;
begin
  inherited;
  GUI.SetContext('notifications', nil);
end;

{ TNotificationReward }

constructor TNotificationReward.Create(Owner : TGameStateComponentNotification; const Rewards : TArray<RReward>);
var
  i : integer;
begin
  inherited Create(Owner);
  FNotificationType := ntReward;
  FRewards := Rewards;
  FRewardCount := length(Rewards);
  for i := 0 to length(FRewards) - 1 do
    if FRewards[i].ShopItem.ItemType in [itCard, itSkin, itDeckSlot] then
        FHasWideItems := True;
end;

procedure TNotificationReward.OnShown;
begin
  inherited;
  SoundManager.PlayReward;
end;

{ TNotificationCardUnlock }

procedure TNotificationCardUnlock.OnShown;
begin
  inherited;
  SoundManager.PlayCardUnlock;
end;

procedure TNotificationCardUnlock.ToShop;
begin
  inherited;
  (FOwner.Parent as TGameStateMainMenu).CurrentMenu := mtCollection;
  FOwner.Parent.GetComponent<TGameStateComponentCollection>.ShowCardDetail(Card);
  FOwner.Close;
end;

constructor TNotificationCardUnlock.Create(Owner : TGameStateComponentNotification; const Card : TCard);
begin
  inherited Create(Owner);
  FNotificationType := ntCardUnlock;
  FCard := Card;
end;

{ TGameStateComponentInventory }

function TGameStateComponentInventory.BoosterPackCount : integer;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to Shop.Inventory.Count - 1 do
    if not Shop.Inventory[i].Opened and (Shop.Inventory[i].TypeIdentifier = 'booster_pack') then
        inc(Result);
end;

destructor TGameStateComponentInventory.Destroy;
begin
  GUI.SetContext('inventory', nil);
  Parent.Owner.DialogManager.UnSubscribe(diDraftbox, OnDraftboxOpen);
  inherited;
end;

function TGameStateComponentInventory.HasDraftbox : Boolean;
begin
  Result := Draftbox <> nil;
end;

procedure TGameStateComponentInventory.HideLootbox;
begin
  self.Lootbox := nil;
end;

procedure TGameStateComponentInventory.Initialize;
begin
  if assigned(Shop) then
  begin
    Parent.Owner.DialogManager.Subscribe(diDraftbox, OnDraftboxOpen);
    GUI.SetContext('inventory', self);
    inherited;
  end;
end;

function TGameStateComponentInventory.IsLootboxVisible : Boolean;
begin
  Result := Lootbox <> nil;
end;

function TGameStateComponentInventory.NextBoosterPack : TLootbox;
var
  i : integer;
begin
  Result := nil;
  for i := 0 to Shop.Inventory.Count - 1 do
    if not Shop.Inventory[i].Opened and (Shop.Inventory[i].TypeIdentifier = 'booster_pack') then
    begin
      Result := Shop.Inventory[i] as TLootbox;
      break;
    end;
end;

procedure TGameStateComponentInventory.OnDraftboxOpen(Open : Boolean);
begin
  if Open then
      SoundManager.PlayCardboxOpen;
end;

procedure TGameStateComponentInventory.OpenNextBoosterPack;
var
  Pack : TLootbox;
begin
  Pack := self.NextBoosterPack;
  if assigned(Pack) then
  begin
    OpenedBoosterPack := Pack;
    Parent.GetComponent<TGameStateComponentNotification>.BlockForTime(5000);
    NextBoosterPack.OpenAndReceiveLoot;
  end;
end;

procedure TGameStateComponentInventory.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('inventory', self);
end;

procedure TGameStateComponentInventory.ParentLeft;
begin
  inherited;
  GUI.SetContext('inventory', nil);
end;

procedure TGameStateComponentInventory.SetLootbox(const Value : TLootbox);
begin
  FLootbox := Value;
end;

procedure TGameStateComponentInventory.SetOpenedBoosterPack(const Value : TLootbox);
begin
  FOpenedBoosterPack := Value;
end;

procedure TGameStateComponentInventory.ShowLootbox(const Lootbox : TLootbox);
begin
  self.Lootbox := Lootbox;
end;

procedure TGameStateComponentInventory.UpdateDraftboxDialog(CurrentDraftBox : TDraftbox);
begin
  if assigned(CurrentDraftBox) and (FLastDraftbox <> CurrentDraftBox) then
  begin
    Parent.Owner.DialogManager.OpenDialog(diDraftbox);
    FLastDraftbox := CurrentDraftBox;
  end;
end;

procedure TGameStateComponentInventory.Draft;
var
  Choice : TDraftBoxChoice;
begin
  if assigned(ChosenDraftBoxChoice) then
  begin
    Parent.Owner.DialogManager.CloseDialog(diDraftbox);
    Choice := ChosenDraftBoxChoice;
    ChosenDraftBoxChoice := nil;
    Draftbox.DraftItem(Choice);
    // old drafbox should be opened now and replaces by the next one in calling 'Draftbox'
    UpdateDraftboxDialog(Draftbox);
  end;
end;

function TGameStateComponentInventory.Draftbox : TDraftbox;
var
  i : integer;
begin
  Result := nil;
  for i := 0 to Shop.Inventory.Count - 1 do
    if not Shop.Inventory[i].Opened and (Shop.Inventory[i] is TDraftbox) then
    begin
      Result := Shop.Inventory[i] as TDraftbox;
      break;
    end;
  UpdateDraftboxDialog(Result);
end;

function TGameStateComponentInventory.GetShop : TShop;
begin
  Result := BaseConflict.Api.Shop.Shop;
end;

procedure TGameStateComponentInventory.SetChosenDraftBoxChoice(const Value : TDraftBoxChoice);
begin
  FChosenDraftBoxChoice := Value;
end;

{ TGameStateComponentPlayerLevel }

procedure TGameStateComponentPlayerLevel.CheckForLevelUps;
var
  i, lowestLevel : integer;
  lowestLevelBox : TLootbox;
  LevelUpReward : TLevelUpReward;
begin
  lowestLevel := 10000;
  lowestLevelBox := nil;
  for i := 0 to Shop.Inventory.Count - 1 do
    if Shop.Inventory[i].IsLevelReward and not Shop.Inventory[i].Opened then
    begin
      if lowestLevel > Shop.Inventory[i].RewardForPlayerLevel then
      begin
        lowestLevelBox := Shop.Inventory[i] as TLootbox;
        lowestLevel := Shop.Inventory[i].RewardForPlayerLevel;
      end;
    end;
  if assigned(lowestLevelBox) then
  begin
    LevelUpRewards := lowestLevelBox;
    if assigned(Profile.Constants) and Profile.Constants.PlayerLevelUpRewards.TryGetValue(lowestLevelBox.RewardForPlayerLevel, LevelUpReward) then
        AdditionalLevelUpText := LevelUpReward.AdditionalText;
    Parent.Owner.DialogManager.OpenDialog(diPlayerLevelUp);
  end
  else
  begin
    LevelUpRewards := nil;
    AdditionalLevelUpText := '';
  end;
end;

destructor TGameStateComponentPlayerLevel.Destroy;
begin
  GUI.SetContext('player_level', nil);
  Parent.Owner.DialogManager.UnSubscribe(diPlayerLevelUp, OnLevelUpOpen);
  FLevelUpRewardListPage.Free;
  FLevelUpRewardListPaginator.Free;
  inherited;
end;

function TGameStateComponentPlayerLevel.GetHasLevelUp : Boolean;
begin
  Result := assigned(FLevelUpLoot);
end;

function TGameStateComponentPlayerLevel.GetProfile : TUserProfile;
begin
  Result := UserProfile;
end;

procedure TGameStateComponentPlayerLevel.Initialize;
begin
  if assigned(UserProfile) and assigned(Shop) and Parent.Owner.IsApiReady then
  begin
    Shop.OnInventoryLoaded := OnInventoryLoaded;
    UserProfile.OnLevelUpReward := OnLevelUpReward;
    Parent.Owner.DialogManager.Subscribe(diPlayerLevelUp, OnLevelUpOpen);

    FLevelUpRewardListPage := TUltimateList<TLevelUpReward>.Create;
    FLevelUpRewardListPaginator := TPaginator<TLevelUpReward>.Create(UserProfile.Constants.PlayerLevelUpRewardList, 5 * 2, False);
    FLevelUpRewardListPaginator.OnChange := procedure()
      begin
        // notify gui of changes
        LevelUpRewardListPaginator := nil;
        FLevelUpRewardListPage.Clear;
        FLevelUpRewardListPage.AddRange(FLevelUpRewardListPaginator.CurrentObjects);
      end;
    FLevelUpRewardListPaginator.OnChange();

    GUI.SetContext('player_level', self);
    inherited;
  end;
end;

procedure TGameStateComponentPlayerLevel.OnInventoryLoaded;
begin
  CheckForLevelUps;
end;

procedure TGameStateComponentPlayerLevel.OnLevelUpOpen(Open : Boolean);
begin
  if Open then
      SoundManager.PlayPlayerLevelUp;
end;

procedure TGameStateComponentPlayerLevel.OnLevelUpReward(Reward : TLootbox; ForReachingLevel : integer; AdditionalText : string);
begin
  CheckForLevelUps;
end;

procedure TGameStateComponentPlayerLevel.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('player_level', self);
end;

procedure TGameStateComponentPlayerLevel.ParentLeft;
begin
  inherited;
  GUI.SetContext('player_level', nil);
end;

procedure TGameStateComponentPlayerLevel.ReceiveReward;
begin
  if assigned(LevelUpRewards) then
  begin
    LevelUpRewards.OpenAndReceiveLoot;
    Parent.Owner.DialogManager.CloseDialog(diPlayerLevelUp);
    CheckForLevelUps;
  end;
end;

procedure TGameStateComponentPlayerLevel.SetLevelUpLoot(const Value : TLootbox);
begin
  FLevelUpLoot := Value;
end;

procedure TGameStateComponentPlayerLevel.SetLevelUpRewardListPaginator(const Value : TPaginator<TLevelUpReward>);
begin
  // only notification
end;

procedure TGameStateComponentPlayerLevel.SetLevelUpText(const Value : string);
begin
  FLevelUpText := Value;
end;

{ TGameStateComponentDashboard }

destructor TGameStateComponentDashboard.Destroy;
begin
  FBannerChangeTimer.Free;
  GUI.SetContext('dashboard', nil);
  inherited;
end;

procedure TGameStateComponentDashboard.Idle;
begin
  inherited;
  if FBannerChangeTimer.Expired then
  begin
    ScillBannerIndex := (ScillBannerIndex + 1) mod 3;
    FBannerChangeTimer.Start;
  end;
end;

procedure TGameStateComponentDashboard.Initialize;
begin
  if not assigned(FBannerChangeTimer) then
      FBannerChangeTimer := TTimer.CreateAndStart(15000);
  ScillBannerIndex := random(3);
  GUI.SetContext('dashboard', self);
  inherited;
end;

procedure TGameStateComponentDashboard.ParentEntered;
begin
  inherited;
  if IsInitialized then
  begin
    ScillBannerIndex := random(3);
    GUI.SetContext('dashboard', self);
  end;
end;

procedure TGameStateComponentDashboard.ParentLeft;
begin
  inherited;
  GUI.SetContext('dashboard', nil);
end;

procedure TGameStateComponentDashboard.SetScillBannerIndex(const Value : integer);
begin
  FScillBannerIndex := Value;
end;

{ TGameStateComponentHUDTooltip }

procedure TGameStateComponentHUDTooltip.Idle;
begin
  inherited;
  if FInitialized then
  begin
    ShowToBeShown;
    UpdateToolTip(FSelectedEntity, FToBeShownIsCard);
  end;
end;

procedure TGameStateComponentHUDTooltip.Initialize;
begin
  inherited;
  GUI.SetContext('tooltip', self);
end;

function TGameStateComponentHUDTooltip.OnHideToolTip : Boolean;
begin
  Result := True;
  GlobalEventbus.Trigger(eiSelectEntity, [nil]);
  IsVisible := False;
end;

function TGameStateComponentHUDTooltip.OnReadSelectEntity : RParam;
begin
  Result := FSelectedEntity;
end;

function TGameStateComponentHUDTooltip.OnReplaceEntity(oldEntityID, newEntityID, IsSameEntity : RParam) : Boolean;
var
  Entity : RParam;
begin
  Result := True;
  if assigned(FSelectedEntity) and (oldEntityID.AsInteger = FSelectedEntity.ID) then
  begin
    Entity := Game.EntityManager.GetEntityByID(newEntityID.AsInteger);
    GlobalEventbus.Trigger(eiSelectEntity, [Entity]);
    TSelectedEntityComponent.Create(Entity.AsType<TEntity>);
  end;
end;

function TGameStateComponentHUDTooltip.OnSelectEntity(Entity : RParam) : Boolean;
begin
  Result := True;
  FSelectedEntity := Entity.AsType<TEntity>;
  GlobalEventbus.Trigger(eiShowToolTip, [Entity, False]);
end;

function TGameStateComponentHUDTooltip.OnShowToolTip(Entity, IsCard : RParam) : Boolean;
begin
  Result := True;
  FToBeShownScriptFile := '';
  FToBeShownIsCard := IsCard.AsBoolean;
  FToBeShown := Entity.AsType<TEntity>;
  IsVisible := True;
end;

procedure TGameStateComponentHUDTooltip.ParentEntered;
begin
  inherited;
  if IsInitialized then
  begin
    IsVisible := False;
    GUI.SetContext('tooltip', self);
  end;
end;

procedure TGameStateComponentHUDTooltip.ParentLeft;
begin
  inherited;
  GUI.SetContext('tooltip', nil);
end;

procedure TGameStateComponentHUDTooltip.SetAbilityNames(const Value : string);
begin
  FAbilityNames := Value;
end;

procedure TGameStateComponentHUDTooltip.SetArmorType(const Value : EnumArmorType);
begin
  FArmorType := Value;
end;

procedure TGameStateComponentHUDTooltip.SetCardType(const Value : EnumCardType);
begin
  FCardType := Value;
end;

procedure TGameStateComponentHUDTooltip.SetCurrentEnergy(const Value : integer);
begin
  FCurrentEnergy := Value;
end;

procedure TGameStateComponentHUDTooltip.SetCurrentHealth(const Value : single);
begin
  FCurrentHealth := Value;
end;

procedure TGameStateComponentHUDTooltip.SetCurrentOverheal(const Value : single);
begin
  FCurrentOverheal := Value;
end;

procedure TGameStateComponentHUDTooltip.SetDescription(const Value : string);
begin
  FDescription := Value;
end;

procedure TGameStateComponentHUDTooltip.SetEntityScriptFile(const Value : string);
begin
  FEntityScriptFile := Value;
end;

procedure TGameStateComponentHUDTooltip.SetEntityScriptFileForIcon(const Value : string);
begin
  FEntityScriptFileForIcon := Value;
end;

procedure TGameStateComponentHUDTooltip.SetHasKeywords(const Value : Boolean);
begin
  FHasKeywords := Value;
end;

procedure TGameStateComponentHUDTooltip.SetHasMainWeapon(const Value : Boolean);
begin
  FHasMainWeapon := Value;
end;

procedure TGameStateComponentHUDTooltip.SetHasSkills(const Value : Boolean);
begin
  FHasSkills := Value;
end;

procedure TGameStateComponentHUDTooltip.SetIsEpic(const Value : Boolean);
begin
  FIsEpic := Value;
end;

procedure TGameStateComponentHUDTooltip.SetIsLegendary(const Value : Boolean);
begin
  FIsLegendary := Value;
end;

procedure TGameStateComponentHUDTooltip.SetIsVisible(const Value : Boolean);
begin
  FIsVisible := Value;
end;

procedure TGameStateComponentHUDTooltip.SetKeywords(const Value : TArray<string>);
begin
  FKeywords := Value;
end;

procedure TGameStateComponentHUDTooltip.SetLeague(const Value : integer);
begin
  FLeague := Value;
end;

procedure TGameStateComponentHUDTooltip.SetLevel(const Value : integer);
begin
  FLevel := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMainWeaponCooldown(const Value : single);
begin
  FMainWeaponCooldown := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMainWeaponDamage(const Value : single);
begin
  FMainWeaponDamage := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMainWeaponDPS(const Value : single);
begin
  FMainWeaponDPS := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMainWeaponIsMelee(const Value : Boolean);
begin
  FMainWeaponIsMelee := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMainWeaponRange(const Value : single);
begin
  FMainWeaponRange := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMainWeaponType(const Value : EnumDamageType);
begin
  FMainWeaponType := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMaximumEnergy(const Value : integer);
begin
  FMaximumEnergy := Value;
end;

procedure TGameStateComponentHUDTooltip.SetMaximumHealth(const Value : single);
begin
  FMaximumHealth := Value;
end;

procedure TGameStateComponentHUDTooltip.SetName(const Value : string);
begin
  FName := Value;
end;

procedure TGameStateComponentHUDTooltip.SetSelectedEntity(const Value : TEntity);
begin
  FSelectedEntity := Value;
end;

procedure TGameStateComponentHUDTooltip.SetSkills(const Value : TArray<RAbilityDescription>);
begin
  FSkills := Value;
end;

procedure TGameStateComponentHUDTooltip.SetSkinID(const Value : string);
begin
  FSkinID := Value;
end;

procedure TGameStateComponentHUDTooltip.ShowToBeShown;
begin
  if assigned(FToBeShown) then
  begin
    IsVisible := True;
    // Build Tooltip
    UpdateToolTip(FToBeShown, FToBeShownIsCard);
    if FSelectedEntity <> FToBeShown then SelectedEntity := nil;
    FToBeShown := nil;
  end
end;

procedure TGameStateComponentHUDTooltip.UpdateToolTip(Entity : TEntity; IsCard : Boolean);
var
  DamageType : SetDamageType;
  Damage : RParam;
  AbilityList : TList<RAbilityDescription>;
  KeywordList, AbilityNameList : TList<string>;
  i : integer;
  producedUnit, TeamString : string;
  CardInfo : TCardInfo;
begin
  if assigned(Entity) then
  begin
    League := Entity.CardLeague;
    Level := Entity.CardLevel;
    SkinID := Entity.SkinID;

    if IsCard then
    begin
      CardType := CardInfoManager.ScriptFilenameToCardType(Entity.ScriptFile);
      if CardType in [ctDrop, ctBuilding] then
      begin
        producedUnit := Entity.Eventbus.Read(eiWelaUnitPattern, [], [GROUP_DROP_SPAWNER]).AsString;
        if producedUnit <> '' then
            Entity := EntityDataCache.GetEntity(producedUnit, Entity.CardLeague, Entity.CardLevel);
      end;
    end;

    IsLegendary := upLegendary in Entity.UnitProperties;
    IsEpic := False;

    EntityScriptFile := Entity.ScriptFile;
    if EntityScriptFile.Contains('Nexus') or (EntityScriptFile.Contains('Lanetower') and not EntityScriptFile.Contains('Golem')) then
    begin
      if Settings.GetBooleanOption(coGameplayFixedTeamColors) then
          TeamString := HGeneric.TertOp<string>(Entity.TeamID = ClientGame.CommanderManager.ActiveCommanderTeamID, 'Blue', 'Red')
      else
          TeamString := HGeneric.TertOp<string>(Entity.TeamID = 1, 'Blue', 'Red');
      EntityScriptFileForIcon := EntityScriptFile.Replace(FILE_EXTENSION_ENTITY, '') + TeamString;
    end
    else
        EntityScriptFileForIcon := EntityScriptFile;
    CardType := CardInfoManager.ScriptFilenameToCardType(EntityScriptFile);
    if (CardType = ctSpell) or (EntityScriptFile.Contains('LaneNode') and not EntityScriptFile.Contains('Golem')) then
    begin
      CardType := ctSpell;
      CardInfo := CardInfoManager.ScriptFilenameToCardInfo(TRegex.Replace(EntityScriptFile, 'Spell$', '.sps'), SkinID, 1, 1);
      if assigned(CardInfo) then
          Description := CardInfo.Description
      else
          Description := CardInfoManager.ScriptFilenameToCardStringInfo(EntityScriptFile, SkinID, Entity.CardLeague, ciDescription);
      IsEpic := EntityScriptFile.Contains('Cataclysm');
    end;
    name := CardInfoManager.ScriptFilenameToCardStringInfo(EntityScriptFile, SkinID, Entity.CardLeague);
    // take values from spawned unit if Spawner
    if CardType in [ctSpawner] then
    begin
      producedUnit := Entity.Eventbus.Read(eiWelaUnitPattern, [], [GROUP_TEMPLATE_SPAWNER]).AsString;
      if producedUnit <> '' then
          Entity := EntityDataCache.GetEntity(producedUnit, Entity.CardLeague, Entity.CardLevel);
    end;
    // ----- General -------------------------------------------------------------------------------------------
    ArmorType := Entity.Eventbus.Read(eiArmorType, []).AsEnumType<EnumArmorType>;
    MaximumHealth := Max(Entity.Cap(reHealth).AsSingle, 0.01);
    CurrentHealth := Entity.Balance(reHealth).AsSingle;
    CurrentOverheal := Entity.Balance(reOverheal).AsSingle;
    MaximumEnergy := Entity.Cap(reMana).AsIntegerDefault(Entity.Cap(reWelaCharge).AsInteger);
    CurrentEnergy := Entity.Balance(reMana).AsIntegerDefault(Entity.Balance(reWelaCharge).AsInteger);
    // ----- Main weapon ----------------------------------------------------------------------------------------
    Damage := Entity.Eventbus.Read(eiWelaDamage, [], [GROUP_MAINWEAPON]);
    HasMainWeapon := not Damage.IsEmpty;
    if HasMainWeapon then
    begin
      DamageType := Entity.Eventbus.Read(eiDamageType, [], [GROUP_MAINWEAPON]).AsType<SetDamageType>;
      if dtSiege in DamageType then MainWeaponType := dtSiege
      else if dtRanged in DamageType then MainWeaponType := dtRanged
      else MainWeaponType := dtMelee;
      MainWeaponDamage := Damage.AsSingle;
      MainWeaponCooldown := Entity.Eventbus.Read(eiCooldown, [], [GROUP_MAINWEAPON]).AsInteger / 1000;
      MainWeaponDPS := MainWeaponDamage / MainWeaponCooldown;
      MainWeaponRange := Entity.Eventbus.Read(eiWelaRange, [], [GROUP_MAINWEAPON]).AsSingle;
      MainWeaponIsMelee := MainWeaponRange <= 1.5;
    end;
    AbilityList := TList<RAbilityDescription>.Create;
    KeywordList := TList<string>.Create;
    AbilityNameList := TList<string>.Create;
    Entity.Eventbus.Trigger(eiBuildAbilityList, [AbilityList, KeywordList, nil]);
    Skills := AbilityList.ToArray;
    HasSkills := length(Skills) > 0;
    Keywords := KeywordList.ToArray;
    HasKeywords := length(FKeywords) > 0;
    for i := 0 to AbilityList.Count - 1 do
        AbilityNameList.Add(AbilityList[i].name);
    AbilityNames := HString.Join(AbilityNameList.ToArray, ', ');
    AbilityList.Free;
    AbilityNameList.Free;
    KeywordList.Free;
  end;
end;

destructor TGameStateComponentHUDTooltip.Destroy;
begin
  GUI.SetContext('tooltip', nil);
  inherited;
end;

{ TGameStateLoginSteam }

procedure TGameStateLoginSteam.EnterState;
begin
  inherited;
  Owner.State := csLoginSteam;
end;

procedure TGameStateLoginSteam.Idle;
begin
  try
    Login;
  except
    on e : ESteamException do
    begin
      PreventIdle := True;
      MessageDlg(e.Message, mtError, [mbOK], 0);
      ReportMemoryLeaksOnShutdown := False;
      halt;
    end;
    on e : ENetworkException do
    begin
      PreventIdle := True;
      MessageDlg(e.Message + ' - please contact support. (support@brokengames.de)', mtError, [mbOK], 0);
      ReportMemoryLeaksOnShutdown := False;
      halt;
    end;
  end;
  if Account.IsConnected then
      Owner.ChangeGameState(GAMESTATE_MAINMENU)
  else
  begin
    PreventIdle := True;
    MessageDlg('Could not connect to "Rise of Legions" network - please contact support. (support@brokengames.de)', mtError, [mbOK], 0);
    ReportMemoryLeaksOnShutdown := False;
    halt;
  end;
end;

procedure TGameStateLoginSteam.Login;
begin
  Account.LoginWithSteam();
  Owner.CreateManager;
  // after all is setup, check dlc ownership
  if DLC_SYSTEM_ENABLED then
      MainActionQueue.DoAction(TShopActionUpdateDLCOwnership.Create);
end;

{ TGameStateReconnect }

constructor TGameStateReconnect.Create(Owner : TGameStateManager);
begin
  inherited Create(Owner);
  TGameStateComponentSettings.Create(FStateEntity, self);
end;

destructor TGameStateReconnect.Destroy;
begin
  GUI.SetContext('reconnect', nil);
  inherited;
end;

procedure TGameStateReconnect.EnterState;
begin
  inherited;
  // reset broker check
  Owner.GetGameState<TGameStateMainMenu>(GAMESTATE_MAINMENU).FFirstLoadDone := False;

  Owner.ShowWindow;
  SplashForm.Hide;
  Owner.State := csReconnect;
  IsReadyToReconnect := False;
  Owner.SetClientWindow;
  GUI.SetContext('reconnect', self);

  MainActionQueue.OnClearQueueFinished := OnClearQueueFinished;
  MainActionQueue.ClearQueue;
end;

function TGameStateReconnect.GetForceBrokerFallback : Boolean;
begin
  Result := Account.ForceBrokerFallback;
end;

procedure TGameStateReconnect.LeaveState;
begin
  inherited;
  GUI.SetContext('reconnect', nil);
end;

procedure TGameStateReconnect.OnClearQueueFinished;
begin
  IsReadyToReconnect := True;
end;

procedure TGameStateReconnect.Reconnect;
begin
  if not IsReadyToReconnect then exit;
  assert(assigned(Account));
  try
    Account.ReLogin;
  except
    on e : ESteamException do
    begin
      PreventIdle := True;
      MessageDlg(e.Message, mtError, [mbOK], 0);
      ReportMemoryLeaksOnShutdown := False;
      halt;
    end;
    on e : ENetworkException do
    begin
      PreventIdle := True;
      MessageDlg('Could not connect to "Rise of Legions" network - please contact support.', mtError, [mbOK], 0);
      ReportMemoryLeaksOnShutdown := False;
      halt;
    end;
  end;
  MainActionQueue.DoAction(TMatchmakingManagerActionLoadCurrentTeam.Create(Matchmaking));
  Matchmaking.CurrentTeam.Deck := Deckbuilding.GetDefaultDeck;
  if Account.IsConnected then Owner.ChangeGameState(GAMESTATE_MAINMENU)
  else MessageDlg('Error while reconnecting. Please try again.', mtError, [mbOK], 0);
end;

procedure TGameStateReconnect.SetForceBrokerFallback(const Value : Boolean);
begin
  Account.ForceBrokerFallback := Value;
  Settings.SetBooleanOption(coGeneralForceBrokerFallback, Value);
  Settings.SaveSettings;
end;

procedure TGameStateReconnect.SetReadyToReconnect(const Value : Boolean);
begin
  FReadyToReconnect := Value;
end;

{ TNotificationFriendRequest }

constructor TNotificationFriendRequest.Create(Owner : TGameStateComponentNotification; const Request : TFriendRequest);
begin
  inherited Create(Owner);
  FNotificationType := ntFriendRequest;
  FRequester := Request.OtherPerson;
end;

{ TNotification }

constructor TNotification.Create(Owner : TGameStateComponentNotification);
begin
  FOwner := Owner;
end;

procedure TNotification.OnShown;
begin

end;

{ TGameStateServerDown }

constructor TGameStateServerDown.Create(Owner : TGameStateManager);
begin
  inherited Create(Owner);
  TGameStateComponentSettings.Create(FStateEntity, self);
end;

procedure TGameStateServerDown.EnterState;
begin
  inherited;
  Owner.State := csServerDown;
  GUI.Clear;
  Owner.SetClientWindow;
  Owner.SwitchMenuMusic(mmMenu);
  GUI.LoadFromFile(GUI_ROOT_SERVER_DOWN_FILENAME);
  Owner.ShowWindow;
  SplashForm.Hide;
end;

{ TGameStateComponentQuests }

procedure TGameStateComponentQuests.AutoCollect;
var
  i : integer;
begin
  for i := QuestManager.Quests.Count - 1 downto 0 do
    if QuestManager.Quests[i].Completed and QuestManager.Quests[i].ShouldBeAutoCollected then
        QuestManager.Quests[i].CollectReward;
end;

destructor TGameStateComponentQuests.Destroy;
begin
  GUI.SetContext('quests', nil);
  inherited;
end;

function TGameStateComponentQuests.GetQuestManager : TQuestManager;
begin
  Result := BaseConflict.Api.Quests.QuestManager;
end;

procedure TGameStateComponentQuests.Idle;
var
  WeeklyResetDate : TDateTime;
  NewSecondsUntilWeeklyResets, CurrentWeekday, DaysToAdvance : integer;
begin
  inherited;
  // compute next reset, wednesday 04:00
  WeeklyResetDate := Account.Servertime;
  CurrentWeekday := DayOfTheWeek(WeeklyResetDate);
  // on wednesday we have to look whether we are before or after the reset
  if CurrentWeekday = DayWednesday then
  begin
    if WeeklyResetDate >= RecodeTime(WeeklyResetDate, 4, 0, 0, 0) then
        WeeklyResetDate := IncWeek(WeeklyResetDate);
  end
  else
  // on all other days we can just advance to the next wednesday
  begin
    if CurrentWeekday < DayWednesday then
        DaysToAdvance := DayWednesday - CurrentWeekday
    else
        DaysToAdvance := (DaySunday - CurrentWeekday) + DayWednesday;
    WeeklyResetDate := IncDay(WeeklyResetDate, DaysToAdvance);
  end;
  WeeklyResetDate := RecodeTime(WeeklyResetDate, 4, 0, 0, 0);

  // update countdown
  if Account.Servertime < WeeklyResetDate then
      NewSecondsUntilWeeklyResets := SecondsBetween(Account.Servertime, WeeklyResetDate)
  else
      NewSecondsUntilWeeklyResets := 0;
  // only set values if changed
  if NewSecondsUntilWeeklyResets <> SecondsUntilWeeklyResets then
      SecondsUntilWeeklyResets := NewSecondsUntilWeeklyResets;
end;

procedure TGameStateComponentQuests.Initialize;
begin
  GUI.SetContext('quests', self);
  inherited;
end;

procedure TGameStateComponentQuests.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('quests', self);
end;

procedure TGameStateComponentQuests.ParentLeft;
begin
  inherited;
  GUI.SetContext('quests', nil);
end;

procedure TGameStateComponentQuests.SetIsVisible(const Value : Boolean);
begin
  FIsVisible := Value;
end;

procedure TGameStateComponentQuests.SetQuestManager(const Value : TQuestManager);
begin
  // notification only
end;

procedure TGameStateComponentQuests.SetSecondsUntilWeeklyResets(
  const Value : integer);
begin
  FSecondsUntilWeeklyResets := Value;
end;

{ TNotificationMessage }

constructor TNotificationMessage.Create(Owner : TGameStateComponentNotification; const Msg : TMessage);
begin
  inherited Create(Owner);
  FNotificationType := ntMessage;
  FMessage := Msg;
end;

{ TGameStateComponentCore }

function TGameStateComponentCore.OnGameEvent(Eventname : RParam) : Boolean;
begin
  Result := True;
  if not FSentReady and (Eventname.AsString = GAME_EVENT_CLIENT_READY) then
  begin
    GlobalEventbus.Trigger(eiClientReady, []);
    FSentReady := True;
  end;
end;

procedure TGameStateComponentCore.ParentEntered;
begin
  inherited;
  FSentReady := False;
end;

{ TDialogManager }

procedure TDialogManager.BindDialog(DialogIdentifier : EnumDialogIdentifier; Open : Boolean);
begin
  if Open then
      OpenDialog(DialogIdentifier)
  else
      CloseDialog(DialogIdentifier);
end;

procedure TDialogManager.CloseAllDialogs;
begin
  SetDirty(FOpenDialogs);
  FOpenDialogs := [];
end;

procedure TDialogManager.CloseDialog(DialogIdentifier : EnumDialogIdentifier);
begin
  if DialogIdentifier in FOpenDialogs then
  begin
    exclude(FOpenDialogs, DialogIdentifier);
    SetDirty([DialogIdentifier]);
  end;
end;

destructor TDialogManager.Destroy;
begin
  HArray.FreeAndNilAllObjects(FCallbacks);
  inherited;
end;

procedure TDialogManager.Idle;
begin
  if FDirty <> [] then
      UpdateShownDialog;
end;

function TDialogManager.IsAnyDialogVisible : Boolean;
begin
  Result := FOpenDialogs <> [];
end;

function TDialogManager.IsDialogVisible(DialogIdentifier : EnumDialogIdentifier) : Boolean;
begin
  Result := ((DialogIdentifier in PASSIVE_DIALOGS) and (DialogIdentifier in FOpenDialogs)) or (DialogIdentifier = ShownDialog);
end;

procedure TDialogManager.Notify(DialogIdentifier : EnumDialogIdentifier; Open : Boolean);
var
  Subscriber : TList<ProcDialogVisibilityChanged>;
  i : integer;
begin
  Subscriber := FCallbacks[DialogIdentifier];
  if assigned(Subscriber) then
    for i := 0 to Subscriber.Count - 1 do
        Subscriber[i](Open);
end;

procedure TDialogManager.OpenDialog(DialogIdentifier : EnumDialogIdentifier);
begin
  if not(DialogIdentifier in FOpenDialogs) then
  begin
    include(FOpenDialogs, DialogIdentifier);
    SetDirty([DialogIdentifier]);
    if assigned(QuestManager) then
        QuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_OPEN_DIALOG_PREFIX + HRTTi.EnumerationToString<EnumDialogIdentifier>(DialogIdentifier));
  end;
end;

procedure TDialogManager.SetDirty(DialogIdentifiers : SetDialogIdentifier);
begin
  FDirty := FDirty + DialogIdentifiers;
end;

procedure TDialogManager.SetShownDialog(const Value : EnumDialogIdentifier);
begin
  if (FShownDialog <> diNone) and (FShownDialog <> Value) then
  begin
    Notify(FShownDialog, False);
    if not(FShownDialog in SOUNDLESS_DIALOGS) then
        SoundManager.PlayDialogClose;
  end;

  if (Value <> diNone) and (FShownDialog <> Value) then
  begin
    Notify(Value, True);
    if not(Value in SOUNDLESS_DIALOGS) then
        SoundManager.PlayDialogOpen;
  end;

  FShownDialog := Value;
end;

procedure TDialogManager.Subscribe(DialogIdentifier : EnumDialogIdentifier; Callback : ProcDialogVisibilityChanged);
var
  Subscriber : TList<ProcDialogVisibilityChanged>;
begin
  Subscriber := FCallbacks[DialogIdentifier];
  if not assigned(Subscriber) then
  begin
    Subscriber := TList<ProcDialogVisibilityChanged>.Create;
    FCallbacks[DialogIdentifier] := Subscriber;
  end;
  Subscriber.Add(Callback)
end;

procedure TDialogManager.ToggleDialog(DialogIdentifier : EnumDialogIdentifier);
begin
  if DialogIdentifier in FOpenDialogs then
      CloseDialog(DialogIdentifier)
  else
      OpenDialog(DialogIdentifier);
end;

procedure TDialogManager.UnSubscribe(DialogIdentifier : EnumDialogIdentifier; Callback : ProcDialogVisibilityChanged);
var
  Subscriber : TList<ProcDialogVisibilityChanged>;
begin
  Subscriber := FCallbacks[DialogIdentifier];
  if assigned(Subscriber) then
      Subscriber.Remove(Callback);
end;

procedure TDialogManager.UpdateShownDialog;
var
  CurrentDialogIdentifier, NextDialog : EnumDialogIdentifier;
begin
  NextDialog := diNone;
  for CurrentDialogIdentifier := low(EnumDialogIdentifier) to high(EnumDialogIdentifier) do
    if CurrentDialogIdentifier in FOpenDialogs then
    begin
      NextDialog := CurrentDialogIdentifier;
      if not(CurrentDialogIdentifier in PASSIVE_DIALOGS) then
          break;
    end;
  if (ShownDialog = NextDialog) and (NextDialog in FDirty) then
      ShownDialog := diNone;
  ShownDialog := NextDialog;
  FDirty := [];
end;

{ TGameStateMaintenance }

constructor TGameStateMaintenance.Create(Owner : TGameStateManager);
begin
  inherited Create(Owner);
  TGameStateComponentFeedback.Create(FStateEntity, self);
  TGameStateComponentSettings.Create(FStateEntity, self);
  FPollTimer := TTimer.Create(SERVER_STATUS_POLL_INTERVAL);
end;

destructor TGameStateMaintenance.Destroy;
begin
  FPollTimer.Free;
  inherited;
end;

procedure TGameStateMaintenance.EnterState;
begin
  inherited;

  // reset mainmenu components
  Owner.RemoveGameState(GAMESTATE_MAINMENU);
  Owner.AddNewGameState(TGameStateMainMenu.Create(Owner), GAMESTATE_MAINMENU);

  // entering maintenance
  Owner.CleanManager;
  Owner.State := csMaintenance;
  GUI.Clear;
  Owner.SetClientWindow;
  Owner.SwitchMenuMusic(mmMenu);
  GUI.LoadFromFile(GUI_ROOT_MAINTENANCE_FILENAME);
  Owner.ShowWindow;
  SplashForm.Hide;
end;

procedure TGameStateMaintenance.Idle;
begin
  inherited;
  if FPollTimer.Expired then
  begin
    ServerState.UpdateServerStateAsynchronous;
    FPollTimer.Start;
  end;
  ServerState.Idle;
  if not ServerState.IsMaintenanceActive then
      Owner.ChangeGameState(GAMESTATE_LOGIN_QUEUE);
end;

{ TGameStateLoginQueue }

procedure TGameStateLoginQueue.CheckLoginQueueSocket;
var
  DataFrame : TWebSocketClientFrame;
  Data : TJsonObject;
begin
  if assigned(FLoginQueueSocket) then
  begin
    if FLoginQueueSocket.IsConnected then
    begin
      while assigned(FLoginQueueSocket) and FLoginQueueSocket.IsFrameAvailable do
      begin
        DataFrame := FLoginQueueSocket.ReceiveFrame;
        Data := DataFrame.PayloadAsJson.AsObject;
        DataFrame.Free;
        if Data['command'].AsValue.AsString = 'LOGIN_QUEUE_ENTER_NOW' then
        begin
          FreeAndNil(FLoginQueueSocket);
          FLoginQueueSaysGo := True;
        end
        else if Data['command'].AsValue.AsString = 'NET_LOGIN_QUEUE_UPDATE' then
        begin
          PositionInQueue := Data['data'].AsValue.AsInteger;
        end;
        Data.Free;
      end;
    end
    else
    begin
      LoginQueueDown
    end;
  end;
end;

constructor TGameStateLoginQueue.Create(Owner : TGameStateManager);
begin
  inherited Create(Owner);
  FServerPollingRate := TTimer.Create(FALLBACK_POLLING_RATE);
  TGameStateComponentSettings.Create(FStateEntity, self);
end;

destructor TGameStateLoginQueue.Destroy;
begin
  GUI.SetContext('loginqueue', nil);
  FreeAndNil(FCurrentPlayerOnlinePromise);
  FreeAndNil(FLoginQueueSocket);
  FreeAndNil(FServerPollingRate);
  inherited;
end;

procedure TGameStateLoginQueue.EnterLogin;
begin
  Owner.HideWindow;
  SplashForm.Show;
  GUI.SetContext('loginqueue', nil);
  GUI.LoadFromFile(GUI_ROOT_MAIN_FILENAME);
  Owner.ChangeGameState(GAMESTATE_LOGINSTEAM);
end;

procedure TGameStateLoginQueue.EnterLoginQueue;
begin
  try
    FLoginQueueSocket := TWebSocketClient.Create();
    FLoginQueueSocket.Connect(ServerState.LoginQueueAddress);
    if FLoginQueueSocket.IsDisconnected then
        LoginQueueDown
    else
        InLoginQueue := True;
  except
    LoginQueueDown;
  end;
end;

procedure TGameStateLoginQueue.EnterState;
begin
  inherited;
  FFirstShortcut := True;
  FTimestampStart := TimeManager.GetTimeStamp;
  TimeInQueue := 0;
  PositionInQueue := -1;
  FLoginQueueSaysGo := False;
  FLoginQueueDown := False;
  FShortcutTested := False;
  FCurrentPlayerCount := MaxInt;
  Owner.State := csLoginQueue;
  GUI.Clear;
  HLog.Log('Swap in Gamestate: ' + self.ClassName + ', MemoryUsage: ' + HMemoryDebug.GetMemoryUsedFormated);
end;

procedure TGameStateLoginQueue.LeaveState;
begin
  GUI.SetContext('loginqueue', nil);
  FreeAndNil(FLoginQueueSocket);
end;

procedure TGameStateLoginQueue.LoginQueueDown;
begin
  FreeAndNil(FLoginQueueSocket);
  FLoginQueueDown := True;
  InLoginQueue := False;
  PositionInQueue := -1;
end;

procedure TGameStateLoginQueue.SetInLoginQueue(const Value : Boolean);
begin
  FInLoginQueue := Value;
end;

procedure TGameStateLoginQueue.SetPositionInQueue(const Value : integer);
begin
  FPositionInQueue := Value;
end;

procedure TGameStateLoginQueue.SetTimeInQueue(const Value : integer);
begin
  FTimeInQueue := Value;
end;

procedure TGameStateLoginQueue.Idle;
begin
  inherited;
  if Settings.GetBooleanOption(coGeneralBypassLoginQueue) then
  begin
    EnterLogin;
    exit;
  end;
  TimeInQueue := (TimeManager.GetTimeStamp - FTimestampStart) div 1000;

  if not FShortcutTested or (FLoginQueueDown and (FServerPollingRate.Expired or (assigned(FCurrentPlayerOnlinePromise) and FCurrentPlayerOnlinePromise.IsFinished))) then
  begin
    if not assigned(FCurrentPlayerOnlinePromise) then
        FCurrentPlayerOnlinePromise := AccountAPI.GetCurrentPlayerOnline();

    if FCurrentPlayerOnlinePromise.IsFinished then
    begin
      if FCurrentPlayerOnlinePromise.WasSuccessful then
          FCurrentPlayerCount := FCurrentPlayerOnlinePromise.Value;
      FreeAndNil(FCurrentPlayerOnlinePromise);
      FServerPollingRate.Start;
      FShortcutTested := True;
      // fallback overflow prevention - if new data shows us full, we reset that we waited to enter
      if not(FCurrentPlayerCount < ServerState.MaxCurrentPlayerOnline) then
          FFallbackLoginDelayWaited := False;
    end;

    if (FCurrentPlayerCount < ServerState.MaxCurrentPlayerOnline) then
    begin
      // fallback overflow prevention - if we are in fallback we wait one poll to have enough space to really enter the server
      if FLoginQueueDown and not FFallbackLoginDelayWaited then
      begin
        FFallbackLoginDelayWaited := True;
        FCurrentPlayerCount := ServerState.MaxCurrentPlayerOnline + 1;
      end
      else
          EnterLogin;
    end
    else
      if FShortcutTested and not FLoginQueueDown then
    begin
      if FFirstShortcut then
          InitLoginQueueWindow;
      EnterLoginQueue;
    end;
  end
  else
  begin
    CheckLoginQueueSocket;
    if FLoginQueueSaysGo then
        EnterLogin;
  end;
end;

procedure TGameStateLoginQueue.InitLoginQueueWindow;
begin
  Owner.FWindowInitialized := False;
  Owner.SetClientWindow;
  Owner.SwitchMenuMusic(mmMenu);
  GUI.LoadFromFile(GUI_ROOT_LOGIN_QUEUE_FILENAME);
  Owner.ShowWindow;
  SplashForm.Hide;
  GUI.SetContext('loginqueue', self);
  FFirstShortcut := False;
end;

{ TGameStateMenu }

destructor TGameStateMenu.Destroy;
begin
  FAnimatedBackground.Free;
  inherited;
end;

procedure TGameStateMenu.EnterState;
begin
  inherited;
  if Settings.GetBooleanOption(coMenuAnimatedBackground) then
      FAnimatedBackground := TAnimatedImage.CreateFromFile(AbsolutePath(LOGINMENU_BACKGROUND_FILENAME));
end;

procedure TGameStateMenu.Idle;
begin
  inherited;
  if assigned(FAnimatedBackground) then
  begin
    FAnimatedBackground.Offset := (RVector2.Create(sin(TimeManager.GetFloatingTimestamp / 3000), (sin(TimeManager.GetFloatingTimestamp / 924) * 0.3 + 0.7) * cos(TimeManager.GetFloatingTimestamp / 3000))) * 0.08; // + (Mouse.Position.ToRVector / GFXD.Settings.Resolution.Size) * 0.08;
    FAnimatedBackground.Zoom := 1.15;
    FAnimatedBackground.Idle;
  end;
end;

procedure TGameStateMenu.LeaveState;
begin
  inherited;
  FreeAndNil(FAnimatedBackground);
end;

{ TGameStateComponentMetaTutorial }

procedure TGameStateComponentMetaTutorial.CompleteCurrentStage;
begin
  CompletedStage(Stage);
end;

procedure TGameStateComponentMetaTutorial.CompletedFourStages(Stage, Stage2, Stage3, Stage4 : EnumMetaTutorialStage);
begin
  CompleteStages([Stage, Stage2, Stage3, Stage4]);
end;

procedure TGameStateComponentMetaTutorial.CompletedStage(Stage : EnumMetaTutorialStage);
begin
  CompleteStages([Stage]);
end;

procedure TGameStateComponentMetaTutorial.CompletedTwoStages(Stage, Stage2 : EnumMetaTutorialStage);
begin
  CompleteStages([Stage, Stage2]);
end;

procedure TGameStateComponentMetaTutorial.CompletedThreeStages(Stage, Stage2, Stage3 : EnumMetaTutorialStage);
begin
  CompleteStages([Stage, Stage2, Stage3]);
end;

procedure TGameStateComponentMetaTutorial.CompleteStages(Stages : SetMetaTutorialStage);
begin
  if (self.Stage in Stages) then
  begin
    Parent.Owner.DialogManager.CloseDialog(diMetaTutorial);
    FStageDelay.Start(STAGE_DELAY[self.Stage]);
    InTransition := True;
    OnCompleteStage(self.Stage);
  end;
end;

destructor TGameStateComponentMetaTutorial.Destroy;
begin
  Parent.Owner.DialogManager.UnSubscribe(diMetaTutorial, OnShowDialog);
  Parent.Owner.DialogManager.UnSubscribe(diTutorialVideos, OnShowTutorialVideoDialog);
  FStageDelay.Free;
  inherited;
end;

procedure TGameStateComponentMetaTutorial.Idle;
begin
  inherited;
  if FStageDelay.Expired and (self.Stage <> high(EnumMetaTutorialStage)) then
  begin
    self.Stage := EnumMetaTutorialStage(ord(self.Stage) + 1);
    FStageDelay.StartAndPause;
    if not(self.Stage in STAGE_HIDDEN) then
        Parent.Owner.DialogManager.OpenDialog(diMetaTutorial);
  end;
  if FStageDelay.Paused and InTransition then
      InTransition := False;

  if Keyboard.Strg and Keyboard.Alt and Keyboard.KeyUp(TasteT) then
      StartMetaTutorial;
  if Keyboard.Strg and Keyboard.Alt and Keyboard.KeyUp(TasteZ) then
  begin
    if self.Stage = low(EnumMetaTutorialStage) then
        self.Stage := high(EnumMetaTutorialStage)
    else
        self.Stage := EnumMetaTutorialStage(ord(self.Stage) - 1);
  end;
  if Keyboard.Strg and Keyboard.Alt and Keyboard.KeyUp(TasteU) then
      CompletedStage(self.Stage);
  if Keyboard.Strg and Keyboard.Alt and Keyboard.KeyUp(TasteR) then
      Clipboard.AsText := FloatToStrF(Mouse.X / 1280 * 100, ffGeneral, 4, 4) + 'vw ' + FloatToStrF(Mouse.Y / 720 * 100, ffGeneral, 4, 4) + 'vh';
end;

procedure TGameStateComponentMetaTutorial.Initialize;
begin
  inherited;
  Parent.Owner.DialogManager.Subscribe(diMetaTutorial, OnShowDialog);
  Parent.Owner.DialogManager.Subscribe(diTutorialVideos, OnShowTutorialVideoDialog);
  FStageDelay := TTimer.Create(STAGE_DELAY[mtsNone]);
  FStageDelay.StartAndPause;

  GUI.SetContext('metatutorial', self);
end;

function TGameStateComponentMetaTutorial.IsActive : Boolean;
begin
  Result := not(self.Stage in [mtsNone, mtsTutorialFinished]);
end;

procedure TGameStateComponentMetaTutorial.OnCompleteStage(Stage : EnumMetaTutorialStage);
begin

end;

procedure TGameStateComponentMetaTutorial.OnShowDialog(Open : Boolean);
begin
  if Open and (Stage in STAGE_REWARD) then
      SoundManager.PlayReward;
end;

procedure TGameStateComponentMetaTutorial.OnShowTutorialVideoDialog(Open : Boolean);
begin
  if assigned(UserProfile) then
      UserProfile.HasFoundTutorialVideos := True;
end;

procedure TGameStateComponentMetaTutorial.ParentEntered;
begin
  inherited;
  if IsInitialized then
      GUI.SetContext('metatutorial', self);
end;

procedure TGameStateComponentMetaTutorial.ParentLeft;
begin
  inherited;
  GUI.SetContext('metatutorial', nil);
end;

function TGameStateComponentMetaTutorial.ReceivedStarterDeckColor : EnumEntityColor;
begin
  case Stage of
    mtsStarterdeckWhite : Result := ecWhite;
  else
    Result := ecWhite;
  end;
end;

function TGameStateComponentMetaTutorial.RewardStage : Boolean;
begin
  Result := Stage in STAGE_REWARD;
end;

procedure TGameStateComponentMetaTutorial.SetInTransition(const Value : Boolean);
begin
  FInTransition := Value;
end;

procedure TGameStateComponentMetaTutorial.SetStage(const Value : EnumMetaTutorialStage);
begin
  FStage := Value;
end;

function TGameStateComponentMetaTutorial.StageHasTitle : Boolean;
begin
  Result := self.Stage in STAGE_WITH_TITLE;
end;

procedure TGameStateComponentMetaTutorial.StartMetaTutorial;
begin
  StartMetaTutorialAtStage(EnumMetaTutorialStage(ord(low(EnumMetaTutorialStage)) + 1));
end;

procedure TGameStateComponentMetaTutorial.StartMetaTutorialAtStage(Stage : EnumMetaTutorialStage);
begin
  self.Stage := EnumMetaTutorialStage(Max(0, ord(Stage) - 1));
  FStageDelay.Start(STAGE_DELAY[self.Stage]);
end;

function TGameStateComponentMetaTutorial.TextOnlyStage : Boolean;
begin
  Result := Stage in STAGE_TEXT_ONLY;
end;

{ TNotificationLootlist }

constructor TNotificationLootlist.Create(Owner : TGameStateComponentNotification; const Identifier : string);
begin
  inherited Create(Owner);
  FNotificationType := ntLootlist;
  FIdentifier := Identifier;
  if FIdentifier.ToLowerInvariant.Contains('green') then
      FStarterDeckColor := ecGreen
  else if FIdentifier.ToLowerInvariant.Contains('black') then
      FStarterDeckColor := ecBlack
  else if FIdentifier.ToLowerInvariant.Contains('blue') then
      FStarterDeckColor := ecBlue
  else if FIdentifier.ToLowerInvariant.Contains('colorless') then
      FStarterDeckColor := ecColorless
  else
      FStarterDeckColor := ecWhite;
end;

procedure TNotificationLootlist.OnShown;
begin
  inherited;
  SoundManager.PlayReward;
end;

{ TGameStateComponentLeaderboards }

destructor TGameStateComponentLeaderboards.Destroy;
begin
  GUI.SetContext('leaderboards', nil);
  inherited;
end;

procedure TGameStateComponentLeaderboards.Initialize;
begin
  if assigned(LeaderboardManager) then
  begin
    FCurrentMonth := HDate.CurrentMonth;
    LeaderboardManager.OnLeaderboardsLoaded := OnLeaderboardsLoaded;
    ChosenLeague := DEFAULT_LEAGUE;
    ChosenScenario := DEFAULT_SCENARIO;
    GUI.SetContext('leaderboards', self);
    inherited;
  end;
end;

function TGameStateComponentLeaderboards.IsTimeBoard : Boolean;
begin
  Result := ChosenScenario in TIME_SCENARIOS;
end;

procedure TGameStateComponentLeaderboards.OnLeaderboardsLoaded;
begin
  UpdateCurrentLeaderboard;
end;

procedure TGameStateComponentLeaderboards.ParentEntered;
begin
  inherited;
  if IsInitialized then
  begin
    RefreshLeaderboards;
    GUI.SetContext('leaderboards', self);
  end;
end;

procedure TGameStateComponentLeaderboards.ParentLeft;
begin
  inherited;
  GUI.SetContext('leaderboards', nil);
end;

procedure TGameStateComponentLeaderboards.RefreshLeaderboards;
begin
  self.Leaderboard := nil;
  LeaderboardManager.ReloadLeaderboards;
end;

procedure TGameStateComponentLeaderboards.SetChosenScenario(const Value : EnumScenario);
begin
  FChosenScenario := Value;
  if not IsTimeBoard and not(ChosenLeague in NON_TIME_LEAGUES) then
      ChosenLeague := DEFAULT_LEAGUE;
  UpdateCurrentLeaderboard;
end;

procedure TGameStateComponentLeaderboards.SetChosenLeague(const Value : EnumLeaderboardCategory);
begin
  FChosenLeague := Value;
  UpdateCurrentLeaderboard;
end;

procedure TGameStateComponentLeaderboards.SetCurrentLeaderboard(const Value : TLeaderboard);
begin
  FCurrentLeaderboard := Value;
end;

procedure TGameStateComponentLeaderboards.UpdateCurrentLeaderboard;
var
  i : integer;
begin
  for i := 0 to LeaderboardManager.Leaderboards.Count - 1 do
    if (LeaderboardManager.Leaderboards[i].League = ord(FChosenLeague) + 1) and
      assigned(LeaderboardManager.Leaderboards[i].ForScenario) and
      (Parent.GetComponent<TGameStateComponentMatchMaking>.GetEnumScenario(LeaderboardManager.Leaderboards[i].ForScenario.Scenario) = FChosenScenario) then
    begin
      self.Leaderboard := LeaderboardManager.Leaderboards[i];
      exit;
    end;
  // if no one is found, our current may be invalid
  self.Leaderboard := nil;
end;

end.
