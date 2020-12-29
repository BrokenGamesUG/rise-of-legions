unit BaseConflict.Classes.Gamestates.GUI;

interface

uses
  Math,
  SysUtils,
  System.Generics.Collections,
  Engine.Math,
  Engine.GUI,
  Engine.Input,
  Engine.dXML,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.DataQuery,
  BaseConflict.Entity,
  BaseConflict.Api.Shop,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Client,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Client,
  BaseConflict.Constants.Scenario,
  BaseConflict.Settings.Client,
  BaseConflict.Globals;

type

  {$RTTI EXPLICIT METHODS([vcPrivate, vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$M+}
  TPaginatorFilter<T : class> = class abstract
    private
      FOnChange : ProcCallback;
      FItemList : TUltimateObjectList<T>;
      procedure Filter(var Query : IDataQuery<T>); virtual; abstract;
      function ResetValues : boolean; virtual;
    protected
      procedure CallChangeHandler;
    public
      property OnChange : ProcCallback read FOnChange write FOnChange;
      constructor Create(const ItemList : TUltimateObjectList<T>);
      procedure ApplyFilters(Paginator : TPaginator<T>); virtual;
  end;

  TPaginatorCardFilter<T : class> = class(TPaginatorFilter<T>)
    private
      FFilterForColors : SetEntityColor;
      FFilterForTech : SetTechLevels;
      FFilterForType : SetCardType;
      FFilterForText : string;
      FFilterForLeagues : SetLeagues;
      FOrderBy : EnumFilterItemOrder;
      procedure Filter(var FilteredItems : IDataQuery<T>); override;
      function ResetValues : boolean; override;
      procedure SetFilterForColors(const Value : SetEntityColor);
      procedure SetFilterForTech(const Value : SetTechLevels);
      procedure SetFilterForType(const Value : SetCardType);
      procedure SetOrderBy(const Value : EnumFilterItemOrder);
      procedure SetFilterForLeagues(const Value : SetLeagues);
    public
      procedure SetColor(const Color : EnumEntityColor; const Value : boolean);
      property FilterForColors : SetEntityColor read FFilterForColors write SetFilterForColors;

      procedure SetTech(const Tech : byte; const Value : boolean);
      property FilterForTech : SetTechLevels read FFilterForTech write SetFilterForTech;

      procedure SetLeague(const League : byte; const Value : boolean);
      property FilterForLeague : SetLeagues read FFilterForLeagues write SetFilterForLeagues;

      procedure SetType(const CardType : EnumCardType; const Value : boolean);
      property FilterForType : SetCardType read FFilterForType write SetFilterForType;

      procedure SetFilterForText(const Value : string);
      property FilterForText : string read FFilterForText write SetFilterForText;

      function OrderItems : TArray<EnumFilterItemOrder>; virtual;
      property OrderBy : EnumFilterItemOrder read FOrderBy write SetOrderBy;

      /// <summary> Returns whether the reset changed anything. </summary>
      function Reset : boolean;
  end;

  TPaginatorShopFilter<T : class> = class(TPaginatorCardFilter<T>)
    private
      FCategoryFilter : EnumShopCategory;
      function ResetValues : boolean; override;
      procedure Filter(var FilteredItems : IDataQuery<T>); override;
      procedure SetCategoryFilter(const Value : EnumShopCategory);
    public
      property Category : EnumShopCategory read FCategoryFilter write SetCategoryFilter;
  end;

  EnumHUDState = (hsGame, hsNone, hsVictory, hsDefeat);

  RScoreboardPlayer = record
    username : string;
    deckname : string;
    deck_icon : string;
    constructor Create(const username, deckname, DeckIcon : string);
  end;

  THUDCommanderAbility = class
    protected
      FCommanderSpellData : TCommanderSpellData;
      FUID : string;
    public
      property UID : string read FUID;
      property CommanderSpellData : TCommanderSpellData read FCommanderSpellData;
      constructor Create(const UID : string; CommanderSpellData : TCommanderSpellData);
      destructor Destroy; override;
  end;

  THUDDeckSlot = class(THUDCommanderAbility)
    private
      FIsReady : boolean;
      FCardInfo : TCardInfo;
      FCurrentCharges, FMaxCharges, FSlot : integer;
      FChargeProgress : single;
      FHotkey : string;
      FCooldownSeconds : single;
      procedure SetCardInfo(const Value : TCardInfo); virtual;
      procedure SetCurrentCharges(const Value : integer); virtual;
      procedure SetIsReady(const Value : boolean); virtual;
      procedure SetChargeProgress(const Value : single); virtual;
      procedure SetMaxCharges(const Value : integer); virtual;
      procedure SetSlot(const Value : integer); virtual;
      procedure SetHotkey(const Value : string); virtual;
      procedure SetCooldownSeconds(const Value : single); virtual;
    published
      property CardInfo : TCardInfo read FCardInfo write SetCardInfo;
      property Slot : integer read FSlot write SetSlot;
      property CurrentCharges : integer read FCurrentCharges write SetCurrentCharges;
      property MaxCharges : integer read FMaxCharges write SetMaxCharges;
      property ChargeProgress : single read FChargeProgress write SetChargeProgress;
      property CooldownSeconds : single read FCooldownSeconds write SetCooldownSeconds;
      property IsReady : boolean read FIsReady write SetIsReady;
      property Hotkey : string read FHotkey write SetHotkey;
    public
      property CommanderSpellData : TCommanderSpellData read FCommanderSpellData;
      constructor Create(CardInfo : TCardInfo; Slot : integer; CommanderSpellData : TCommanderSpellData);
      procedure UpdateHotkey;
  end;

  ProcCommanderAbilityClick = procedure(CommanderSpellData : TCommanderSpellData; MouseEvent : EnumGUIEvent) of object;

  /// <summary> Contains all values visible to the core HUD. </summary>
  TIngameHUD = class
    private
      FCommanderAbilityClick : ProcCommanderAbilityClick;
    protected
      const
      CARD_HINT_DELAY               = 800;
      BASE_IS_UNDER_ATTACK_THROTTLE = 10000;
    var
      FCardHintTimer, FAnnouncementTimer, FBaseIsUnderAttackTimer : TTimer;
      FShouldCloseSettings : boolean;
      FSpawnerJumpLastPosition : RVector2;
      procedure OnNexusDamage(TeamID : integer);
    strict private
      FIsAnnouncementVisible : boolean;
      FAnnouncementTitle, FAnnouncementSubtitle : string;
      procedure SetAnnouncementSubtitle(const Value : string); virtual;
      procedure SetAnnouncementTitle(const Value : string); virtual;
      procedure SetIsAnnouncementVisible(const Value : boolean); virtual;
    strict private
      FCommanderAbilities : TObjectDictionary<string, THUDCommanderAbility>;
    strict private
      FShowCardHotkeys : boolean;
      FShowCardNumericChargeProgress : boolean;
      FDeckSlotsStage1, FDeckSlotsStage2, FDeckSlotsStage3, FDeckSlotsSpawner : TUltimateObjectList<THUDDeckSlot>;
      procedure SetShowCardHotkeys(const Value : boolean); virtual;
      procedure SetShowCardNumericChargeProgress(const Value : boolean); virtual;
      procedure SetDeckSlotsSpawner(const Value : TUltimateObjectList<THUDDeckSlot>); virtual;
      procedure SetDeckSlotsStage1(const Value : TUltimateObjectList<THUDDeckSlot>); virtual;
      procedure SetDeckSlotsStage2(const Value : TUltimateObjectList<THUDDeckSlot>); virtual;
      procedure SetDeckSlotsStage3(const Value : TUltimateObjectList<THUDDeckSlot>); virtual;
    strict private
      FHUDState : EnumHUDState;
      FIsMenuOpen, FIsSettingsOpen, FHasGameStarted, FIsReconnecting : boolean;
      FIsSandboxControlVisible, FIsHUDVisible, FIsSandbox, FCameraFixedToLane : boolean;
      FTimeToAttack, FAttackBaseCount, FPing, FFPS : integer;
      FIsPvEAttack : boolean;
      FTimeToNextBossWave : integer;
      FSpawnTimer, FTutorialHintText, FTutorialWindowButtonText : string;
      FCardHintTextVisible, FPreventConsecutivePlaying : boolean;
      FCurrentGold, FCurrentGoldCap, FCurrentTier, FCurrentGoldIncome, FCurrentWood, FCurrentWoodIncome, FTimeToNextTier,
        FSpentWood, FSpentWoodToIncomeUpgrade, FIncomeUpgrades, FMaxIncomeUpgrades : integer;
      FLeftTeamID, FRightTeamID, FLeftNexusHealth, FRightNexusHealth, FCameraFollowEntity : integer;
      FCommanderCount, FCommanderActiveIndex : integer;
      FCameraLaneXLimit : single;
      FCardHintCardInfo : TCardInfo;
      FCameraRotationSpeed, FCameraScrollSpeed, FCameraTiltOffset, FCameraRotationOffset, FCameraFoVOffset : single;
      FCaptureMode, FCameraRotate, FIsTechnicalPanelVisible, FCameraLocked, FKeepResourcesInCaptureMode, FCameraTiltOffsetUsed,
        FCameraRotationOffsetUsed, FCameraFoVOffsetUsed, FIsTutorial, FIsTutorialHintOpen, FCameraLimited, FCameraLaneXLimited : boolean;
      FMousePosition : RVector2;
      FTutorialHintFullscreen, FTutorialWindowBackdrop, FTutorialWindowArrowVisible : boolean;
      FMouseScreenPosition : RIntVector2;
      FCameraLockedSpawnerJumpEnabled, FTutorialWindowHighlight : boolean;
      FTutorialWindowAnchor : EnumComponentAnchor;
      FTutorialWindowPosition, FResolution : RIntVector2;
      FSandboxSpawnWithOverwatchClearable, FSandboxSpawnWithOverwatch : boolean;
      FCameraPosition : RVector2;
      FScoreboardVisible : boolean;
      FScoreboardRightTeam : TUltimateList<RScoreboardPlayer>;
      FScoreboardLeftTeam : TUltimateList<RScoreboardPlayer>;
      FIsBaseUnderAttack : boolean;
      FIsTeamMode : boolean;
      procedure SetCurrentWoodIncome(const Value : integer); virtual;
      procedure SetIsTeamMode(const Value : boolean); virtual;
      procedure SetIsBaseUnderAttack(const Value : boolean); virtual;
      procedure SetCardHintCardInfo(const Value : TCardInfo); virtual;
      procedure SetTutorialWindowArrowVisible(const Value : boolean); virtual;
      procedure SetResolution(const Value : RIntVector2); virtual;
      procedure SetScoreboardVisible(const Value : boolean); virtual;
      procedure SetFPS(const Value : integer); virtual;
      procedure SetPing(const Value : integer); virtual;
      procedure SetCameraPosition(const Value : RVector2); virtual;
      procedure SetPreventConsecutivePlaying(const Value : boolean); virtual;
      procedure SetCameraLaneXLimit(const Value : single); virtual;
      procedure SetCameraLaneXLimited(const Value : boolean); virtual;
      procedure SetTutorialWindowBackdrop(const Value : boolean); virtual;
      procedure SetTutorialWindowButtonText(const Value : string); virtual;
      procedure SetTutorialWindowHighlight(const Value : boolean); virtual;
      procedure SetTutorialWindowAnchor(const Value : EnumComponentAnchor); virtual;
      procedure SetTutorialWindowPosition(const Value : RIntVector2); virtual;
      procedure SetCameraLockedSpawnerJumpEnabled(const Value : boolean); virtual;
      procedure SetSandboxSpawnWithOverwatch(const Value : boolean); virtual;
      procedure SetSandboxSpawnWithOverwatchClearable(const Value : boolean); virtual;
      procedure SetCameraFollowEntity(const Value : integer); virtual;
      procedure SetCameraLimited(const Value : boolean); virtual;
      procedure SetMouseScreenPosition(const Value : RIntVector2); virtual;
      procedure SetTutorialHintFullscreen(const Value : boolean); virtual;
      procedure SetIsTutorialHintOpen(const Value : boolean); virtual;
      procedure SetTutorialHintText(const Value : string); virtual;
      procedure SetMousePosition(const Value : RVector2); virtual;
      procedure SetIsTutorial(const Value : boolean); virtual;
      procedure SetCameraFoVOffset(const Value : single); virtual;
      procedure SetCameraFoVOffsetUsed(const Value : boolean); virtual;
      procedure SetCameraRotationOffsetUsed(const Value : boolean); virtual;
      procedure SetCameraTiltOffsetUsed(const Value : boolean); virtual;
      procedure SetCameraRotationOffset(const Value : single); virtual;
      procedure SetCameraTiltOffset(const Value : single); virtual;
      procedure SetCameraLocked(const Value : boolean); virtual;
      procedure SetCameraScrollSpeed(const Value : single); virtual;
      procedure SetKeepResourcesInCaptureMode(const Value : boolean); virtual;
      procedure SetCaptureMode(const Value : boolean); virtual;
      procedure SetIsTechnicalPanelVisible(const Value : boolean); virtual;
      procedure SetCameraRotate(const Value : boolean); virtual;
      procedure SetCameraRotationSpeed(const Value : single); virtual;
      procedure SetCameraFixedToLane(const Value : boolean); virtual;
      procedure SetIsReconnecting(const Value : boolean); virtual;
      procedure SetIncomeUpgrades(const Value : integer); virtual;
      procedure SetMaxIncomeUpgrades(const Value : integer); virtual;
      procedure SetSpentWood(const Value : integer); virtual;
      procedure SetSpentWoodToIncomeUpgrade(const Value : integer); virtual;
      procedure SetIsSandbox(const Value : boolean); virtual;
      procedure SetIsHUDVisible(const Value : boolean); virtual;
      procedure SetIsSandboxControlVisible(const Value : boolean); virtual;
      procedure SetCommanderActiveIndex(const Value : integer); virtual;
      procedure SetCommanderCount(const Value : integer); virtual;
      procedure SetIsSettingsOpen(const Value : boolean); virtual;
      procedure SetLeftNexusHealth(const Value : integer); virtual;
      procedure SetLeftTeamID(const Value : integer); virtual;
      procedure SetRightNexusHealth(const Value : integer); virtual;
      procedure SetRightTeamID(const Value : integer); virtual;
      procedure SetCurrentGoldIncome(const Value : integer); virtual;
      procedure SetCurrentTier(const Value : integer); virtual;
      procedure SetCurrentWood(const Value : integer); virtual;
      procedure SetTimeToNextTier(const Value : integer); virtual;
      procedure SetCurrentGold(const Value : integer); virtual;
      procedure SetCurrentGoldCap(const Value : integer); virtual;
      procedure SetTimeToNextBossWave(const Value : integer); virtual;
      procedure SetAttackBaseCount(const Value : integer); virtual;
      procedure SetIsPvEAttack(const Value : boolean); virtual;
      procedure SetTimeToAttack(const Value : integer); virtual;
      procedure SetHasGameStarted(const Value : boolean); virtual;
      procedure SetHUDState(const Value : EnumHUDState); virtual;
      procedure SetIsMenuOpen(const Value : boolean); virtual;
      procedure SetCardHintTextVisible(const Value : boolean); virtual;
      procedure SetSpawnTimer(const Value : string); virtual;
    published
      // general
      property State : EnumHUDState read FHUDState write SetHUDState;
      property IsReconnecting : boolean read FIsReconnecting write SetIsReconnecting;
      property IsHUDVisible : boolean read FIsHUDVisible write SetIsHUDVisible;
      property IsSandboxControlVisible : boolean read FIsSandboxControlVisible write SetIsSandboxControlVisible;
      property IsSandbox : boolean read FIsSandbox write SetIsSandbox;
      property IsMenuOpen : boolean read FIsMenuOpen write SetIsMenuOpen;
      property IsSettingsOpen : boolean read FIsSettingsOpen write SetIsSettingsOpen;
      property IsTutorial : boolean read FIsTutorial write SetIsTutorial;
      property IsTeamMode : boolean read FIsTeamMode write SetIsTeamMode;
      property CaptureMode : boolean read FCaptureMode write SetCaptureMode;
      property KeepResourcesInCaptureMode : boolean read FKeepResourcesInCaptureMode write SetKeepResourcesInCaptureMode;
      property HasGameStarted : boolean read FHasGameStarted write SetHasGameStarted;
      property PreventConsecutivePlaying : boolean read FPreventConsecutivePlaying write SetPreventConsecutivePlaying;
      procedure Surrender;
      procedure SendGameEvent(const Eventname : string);
      property MousePosition : RVector2 read FMousePosition write SetMousePosition;
      property MouseScreenPosition : RIntVector2 read FMouseScreenPosition write SetMouseScreenPosition;
      procedure CallClientCommand(Command : EnumClientCommand); overload;

      property Resolution : RIntVector2 read FResolution write SetResolution;

      // nexus damage hint
      procedure BaseIsUnderAttack;
      property IsBaseUnderAttack : boolean read FIsBaseUnderAttack write SetIsBaseUnderAttack;

      // announcements
      property IsAnnouncementVisible : boolean read FIsAnnouncementVisible write SetIsAnnouncementVisible;
      property AnnouncementTitle : string read FAnnouncementTitle write SetAnnouncementTitle;
      property AnnouncementSubtitle : string read FAnnouncementSubtitle write SetAnnouncementSubtitle;
      procedure ShowAnnouncement(const AnnouncementUID : string);
      procedure ShowAnnouncementForTime(const AnnouncementUID : string; const Duration : integer = 2000);
      procedure HideAnnouncement;
      procedure SetAnnouncementTimer(const Duration : integer);

      // technical panel
      property IsTechnicalPanelVisible : boolean read FIsTechnicalPanelVisible write SetIsTechnicalPanelVisible;
      property Ping : integer read FPing write SetPing;
      property FPS : integer read FFPS write SetFPS;

      // camera
      property CameraPosition : RVector2 read FCameraPosition write SetCameraPosition;
      property CameraLimited : boolean read FCameraLimited write SetCameraLimited;
      property CameraFixedToLane : boolean read FCameraFixedToLane write SetCameraFixedToLane;
      property CameraRotate : boolean read FCameraRotate write SetCameraRotate;
      property CameraRotationSpeed : single read FCameraRotationSpeed write SetCameraRotationSpeed;
      property CameraScrollSpeed : single read FCameraScrollSpeed write SetCameraScrollSpeed;
      property CameraLocked : boolean read FCameraLocked write SetCameraLocked;
      property CameraLaneXLimited : boolean read FCameraLaneXLimited write SetCameraLaneXLimited;
      property CameraLaneXLimit : single read FCameraLaneXLimit write SetCameraLaneXLimit;
      property CameraFollowEntity : integer read FCameraFollowEntity write SetCameraFollowEntity;
      property CameraRotationOffset : single read FCameraRotationOffset write SetCameraRotationOffset;
      property CameraRotationOffsetUsed : boolean read FCameraRotationOffsetUsed write SetCameraRotationOffsetUsed;
      property CameraTiltOffset : single read FCameraTiltOffset write SetCameraTiltOffset;
      property CameraTiltOffsetUsed : boolean read FCameraTiltOffsetUsed write SetCameraTiltOffsetUsed;
      property CameraFoVOffset : single read FCameraFoVOffset write SetCameraFoVOffset;
      property CameraFoVOffsetUsed : boolean read FCameraFoVOffsetUsed write SetCameraFoVOffsetUsed;
      procedure CameraMoveTo(const Target : RVector2; TimeToMove : integer);
      property CameraLockedSpawnerJumpEnabled : boolean read FCameraLockedSpawnerJumpEnabled write SetCameraLockedSpawnerJumpEnabled;
      procedure SpawnerJump;

      // Tutorial
      property IsTutorialHintOpen : boolean read FIsTutorialHintOpen write SetIsTutorialHintOpen;
      property TutorialHintText : string read FTutorialHintText write SetTutorialHintText;
      property TutorialHintFullscreen : boolean read FTutorialHintFullscreen write SetTutorialHintFullscreen;
      property TutorialWindowHighlight : boolean read FTutorialWindowHighlight write SetTutorialWindowHighlight;
      property TutorialWindowBackdrop : boolean read FTutorialWindowBackdrop write SetTutorialWindowBackdrop;
      property TutorialWindowArrowVisible : boolean read FTutorialWindowArrowVisible write SetTutorialWindowArrowVisible;
      property TutorialWindowPosition : RIntVector2 read FTutorialWindowPosition write SetTutorialWindowPosition;
      property TutorialWindowAnchor : EnumComponentAnchor read FTutorialWindowAnchor write SetTutorialWindowAnchor;
      property TutorialWindowButtonText : string read FTutorialWindowButtonText write SetTutorialWindowButtonText;

      // Sandbox
      property SandboxSpawnWithOverwatch : boolean read FSandboxSpawnWithOverwatch write SetSandboxSpawnWithOverwatch;
      property SandboxSpawnWithOverwatchClearable : boolean read FSandboxSpawnWithOverwatchClearable write SetSandboxSpawnWithOverwatchClearable;

      // deck panel
      property ShowCardHotkeys : boolean read FShowCardHotkeys write SetShowCardHotkeys;
      property ShowCardNumericChargeProgress : boolean read FShowCardNumericChargeProgress write SetShowCardNumericChargeProgress;
      property DeckSlotsStage1 : TUltimateObjectList<THUDDeckSlot> read FDeckSlotsStage1 write SetDeckSlotsStage1;
      property DeckSlotsStage2 : TUltimateObjectList<THUDDeckSlot> read FDeckSlotsStage2 write SetDeckSlotsStage2;
      property DeckSlotsStage3 : TUltimateObjectList<THUDDeckSlot> read FDeckSlotsStage3 write SetDeckSlotsStage3;
      property DeckSlotsSpawner : TUltimateObjectList<THUDDeckSlot> read FDeckSlotsSpawner write SetDeckSlotsSpawner;
      function RegisterDeckSlot(CardInfo : TCardInfo; SlotIndex : integer; CommanderSpellData : TCommanderSpellData) : THUDDeckSlot;
      procedure DeregisterDeckSlot(DeckSlot : THUDDeckSlot);
      procedure ClickDeckslot(DeckSlot : THUDDeckSlot);
      procedure MousedownDeckslot(DeckSlot : THUDDeckSlot);

      // generic commander abilities
      function RegisterCommanderAbility(const UID : string; CommanderSpellData : TCommanderSpellData) : THUDCommanderAbility;
      procedure DeregisterCommanderAbility(CommanderAbility : THUDCommanderAbility);
      procedure ClickCommanderAbility(const UID : string);
      procedure MousedownCommanderAbility(CommanderAbility : THUDCommanderAbility);

      // card preview
      property CardHintTextVisible : boolean read FCardHintTextVisible write SetCardHintTextVisible;
      property CardHintCardInfo : TCardInfo read FCardHintCardInfo write SetCardHintCardInfo;

      // commander switch
      property CommanderCount : integer read FCommanderCount write SetCommanderCount;
      property CommanderActiveIndex : integer read FCommanderActiveIndex write SetCommanderActiveIndex;
      procedure CommanderChange(CommanderIndex : integer);

      // GameState
      property SpawnTimer : string read FSpawnTimer write SetSpawnTimer;
      property LeftTeamID : integer read FLeftTeamID write SetLeftTeamID;
      property LeftNexusHealth : integer read FLeftNexusHealth write SetLeftNexusHealth;
      property RightTeamID : integer read FRightTeamID write SetRightTeamID;
      property RightNexusHealth : integer read FRightNexusHealth write SetRightNexusHealth;

      // Resources
      property Gold : integer read FCurrentGold write SetCurrentGold;
      property GoldCap : integer read FCurrentGoldCap write SetCurrentGoldCap;
      property GoldIncome : integer read FCurrentGoldIncome write SetCurrentGoldIncome;
      property Wood : integer read FCurrentWood write SetCurrentWood;
      property WoodIncome : integer read FCurrentWoodIncome write SetCurrentWoodIncome;
      property SpentWood : integer read FSpentWood write SetSpentWood;
      property SpentWoodToIncomeUpgrade : integer read FSpentWoodToIncomeUpgrade write SetSpentWoodToIncomeUpgrade;
      property IncomeUpgrades : integer read FIncomeUpgrades write SetIncomeUpgrades;
      property MaxIncomeUpgrades : integer read FMaxIncomeUpgrades write SetMaxIncomeUpgrades;
      property Tier : integer read FCurrentTier write SetCurrentTier;
      property TimeToNextTier : integer read FTimeToNextTier write SetTimeToNextTier;

      // PvE - Attack
      property IsPvEAttack : boolean read FIsPvEAttack write SetIsPvEAttack;
      property TimeToAttack : integer read FTimeToAttack write SetTimeToAttack;
      property AttackBaseCount : integer read FAttackBaseCount write SetAttackBaseCount;
      property TimeToNextBossWave : integer read FTimeToNextBossWave write SetTimeToNextBossWave;

      // Scoreboard
      property ScoreboardVisible : boolean read FScoreboardVisible write SetScoreboardVisible;
      property ScoreboardLeftTeam : TUltimateList<RScoreboardPlayer> read FScoreboardLeftTeam;
      property ScoreboardRightTeam : TUltimateList<RScoreboardPlayer> read FScoreboardRightTeam;
    public
      property ShouldCloseSettings : boolean read FShouldCloseSettings write FShouldCloseSettings;
      property OnCommanderAbilityClick : ProcCommanderAbilityClick read FCommanderAbilityClick write FCommanderAbilityClick;
      constructor Create;
      procedure Idle;
      procedure CallClientCommand(Command : EnumClientCommand; Param1 : RParam); overload;
      procedure UpdateHotkeysInDeck;
      destructor Destroy; override;
  end;

  HGUIMethods = class
    /// <summary> Transforms int to roman numeral 8 => IIX </summary>
    class function AsRoman(const Value : integer) : string;
    class function IntToStr(const Value : integer) : string;
    /// <summary> Transforms seconds to mm:ss </summary>
    class function IntToTime(const Value : integer) : string;
    /// <summary> Transforms seconds to hh:mm </summary>
    class function IntToLongTime(const Value : integer) : string;
    /// <summary> Transforms seconds to "24 days" or "1 day and 22 hours" or "22 hours and 12 minutes" or "22 minutes and 5 seconds" </summary>
    class function IntToTimeAdaptive(const Value : integer) : string;
    /// <summary> Transforms seconds to "24 days" greater a day, otherwise returns to IntToLongTime. </summary>
    class function IntToTimeAdaptiveDays(const Value : integer) : string;
    /// <summary> Transforms seconds to hh:mm:ss </summary>
    class function IntToLongTimeDetail(const Value : integer) : string;
    class function IntComma(const Value : integer) : string;
    class function _0(const Key : string) : string;
    class function _(const Key, Value : string) : string;
    class function _d(const Key : string; Value : integer) : string;
    class function _dd(const Key : string; Value, Value2 : integer) : string;
    class function _ds(const Key : string; Value : integer; Value2 : string) : string;
    class function _2(const Key, Value, Value2 : string) : string;
    class function _sss(const Key, Value, Value2, Value3 : string) : string;
    class function _pluralize(const Key : string; Value : integer) : string;
    class function _pluralize_d(const Key : string; Value : integer) : string;
    class function _pluralize_dd(const Key : string; Value, Value2 : integer) : string;
    class function Date(const Date : TDatetime) : string;
    class function FloatToStr(const Value : single) : string;
    class function FloatToCooldown(const Value : single) : string;
    class function Ceil(const Value : single) : integer;
    class function Trunc(const Value : single) : integer;
    class function Floor(const Value : single) : integer;
    class function Max(const ValueA, ValueB : single) : single;
    class function Min(const ValueA, ValueB : single) : single;
    class function TruncChars(const Value : string; MaxChars : integer) : string;
    class function LoopChars(const Times : integer; const Chars : string) : string;
    class function Range(n : integer) : TArray<integer>;
    class function KeybindingToStr(Keybinding : RBinding) : string;
    class function KeybindingToStrRaw(Keybinding : RBinding) : string;
  end;

  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

uses
  BaseConflict.Globals.Client;

{ TPaginatorCardFilter<T> }

procedure TPaginatorCardFilter<T>.Filter(var FilteredItems : IDataQuery<T>);
begin
  FilteredItems := FilteredItems.Filter(F('CardInfo.CardColors') in RQuery.From<SetEntityColor>(FilterForColors));
  FilteredItems := FilteredItems.Filter(F('CardInfo.Techlevel') in RQuery.From<SetTechLevels>(FilterForTech));
  FilteredItems := FilteredItems.Filter(F('CardInfo.CardType') in RQuery.From<SetCardType>(FilterForType));
  FilteredItems := FilteredItems.Filter(F('League') in RQuery.From<SetLeagues>(FilterForLeague));
  if FilterForText <> '' then
      FilteredItems := FilteredItems.Filter(FilterForText in F('CardInfo.Name'));
  case OrderBy of
    foAlphabetical : FilteredItems := FilteredItems.OrderBy(['CardInfo.Name', 'League', 'ID']);
    foAlphabeticalReverse : FilteredItems := FilteredItems.OrderBy(['-CardInfo.Name', 'League', 'ID']);
    foTech : FilteredItems := FilteredItems.OrderBy(['CardInfo.Techlevel', 'CardInfo.Name', 'League', 'ID']);
    foTechReverse : FilteredItems := FilteredItems.OrderBy(['-CardInfo.Techlevel', 'CardInfo.Name', 'League', 'ID']);
    foAttack : FilteredItems := FilteredItems.OrderBy(['-CardInfo.AttackValue', 'CardInfo.Name', 'League', 'ID']);
    foDefense : FilteredItems := FilteredItems.OrderBy(['-CardInfo.DefenseValue', 'CardInfo.Name', 'League', 'ID']);
    foUtility : FilteredItems := FilteredItems.OrderBy(['-CardInfo.UtilityValue', 'CardInfo.Name', 'League', 'ID']);
  else
    // foCreated as default
    FilteredItems := FilteredItems.OrderBy(['-Created', 'CardInfo.Name', 'League', 'ID']);
  end;
end;

function TPaginatorCardFilter<T>.ResetValues : boolean;
begin
  Result := inherited;
  Result := Result or (FFilterForColors <> ALL_COLORS);
  FFilterForColors := ALL_COLORS;
  Result := Result or (FFilterForTech <> ALL_TECHLEVELS);
  FFilterForTech := ALL_TECHLEVELS;
  Result := Result or (FFilterForLeagues <> ALL_LEAGUES);
  FFilterForLeagues := ALL_LEAGUES;
  Result := Result or (FFilterForType <> ALL_CARDTYPES);
  FFilterForType := ALL_CARDTYPES;
  Result := Result or (FFilterForText <> '');
  FFilterForText := '';
  Result := Result or (FOrderBy <> foCreated);
  FOrderBy := foCreated;
end;

function TPaginatorCardFilter<T>.OrderItems : TArray<EnumFilterItemOrder>;
begin
  Result := [foCreated, foAlphabetical, foAlphabeticalReverse, foTech, foTechReverse, foAttack, foDefense, foUtility];
end;

function TPaginatorCardFilter<T>.Reset : boolean;
begin
  Result := ResetValues;
  CallChangeHandler;
end;

procedure TPaginatorCardFilter<T>.SetColor(const Color : EnumEntityColor; const Value : boolean);
begin
  if Value and not(Color in FilterForColors) then
      FilterForColors := FilterForColors + [Color]
  else if not Value and (Color in FilterForColors) then
  begin
    // If all colors are selected, special case to select the chosen one
    if [ecBlack, ecGreen, ecBlue, ecWhite, ecColorless] <= FilterForColors then
        FilterForColors := FilterForColors - [ecBlack, ecGreen, ecBlue, ecWhite, ecColorless] + [Color]
    else
        FilterForColors := FilterForColors - [Color];
  end;
end;

procedure TPaginatorCardFilter<T>.SetFilterForColors(const Value : SetEntityColor);
begin
  if Value <> FFilterForColors then
  begin
    FFilterForColors := Value;
    CallChangeHandler;
  end;
end;

procedure TPaginatorCardFilter<T>.SetFilterForLeagues(const Value : SetLeagues);
begin
  if FFilterForLeagues <> Value then
  begin
    FFilterForLeagues := Value;
    CallChangeHandler;
  end;
end;

procedure TPaginatorCardFilter<T>.SetFilterForTech(const Value : SetTechLevels);
begin
  if FFilterForTech <> Value then
  begin
    FFilterForTech := Value;
    CallChangeHandler;
  end;
end;

procedure TPaginatorCardFilter<T>.SetFilterForText(const Value : string);
begin
  if FFilterForText <> Value then
  begin
    FFilterForText := Value;
    CallChangeHandler;
  end;
end;

procedure TPaginatorCardFilter<T>.SetFilterForType(const Value : SetCardType);
begin
  if FFilterForType <> Value then
  begin
    FFilterForType := Value;
    CallChangeHandler;
  end;
end;

procedure TPaginatorCardFilter<T>.SetLeague(const League : byte; const Value : boolean);
begin
  if Value and not(League in FilterForLeague) then
      FilterForLeague := FilterForLeague + [League]
  else if not Value and (League in FilterForLeague) then
  begin
    // If all leagues are selected, special case to select the chosen one
    if ALL_LEAGUES <= FilterForLeague then
        FilterForLeague := FilterForLeague - ALL_LEAGUES + [League]
    else
        FilterForLeague := FilterForLeague - [League];
  end;
end;

procedure TPaginatorCardFilter<T>.SetOrderBy(const Value : EnumFilterItemOrder);
begin
  if FOrderBy <> Value then
  begin
    FOrderBy := Value;
    CallChangeHandler;
  end;
end;

procedure TPaginatorCardFilter<T>.SetTech(const Tech : byte; const Value : boolean);
begin
  if Value and not(Tech in FilterForTech) then
      FilterForTech := FilterForTech + [Tech]
  else if not Value and (Tech in FilterForTech) then
  begin
    // If all tech levels are selected, special case to select the chosen one
    if ALL_TECHLEVELS <= FilterForTech then
        FilterForTech := FilterForTech - ALL_TECHLEVELS + [Tech]
    else
        FilterForTech := FilterForTech - [Tech];
  end;
end;

procedure TPaginatorCardFilter<T>.SetType(const CardType : EnumCardType; const Value : boolean);
begin
  if Value and not(CardType in FilterForType) then
      FilterForType := FilterForType + [CardType]
  else if not Value and (CardType in FilterForType) then
  begin
    // If all types are selected, special case to select the chosen one
    if ALL_CARDTYPES <= FilterForType then
        FilterForType := FilterForType - ALL_CARDTYPES + [CardType]
    else
        FilterForType := FilterForType - [CardType];
  end;
end;

{ TPaginatorFilter<T> }

procedure TPaginatorFilter<T>.ApplyFilters(Paginator : TPaginator<T>);
var
  FilteredItems : IDataQuery<T>;
begin
  FilteredItems := FItemList.Query;
  Filter(FilteredItems);
  Paginator.Objects := FilteredItems.ToList(False);
end;

procedure TPaginatorFilter<T>.CallChangeHandler;
begin
  if assigned(FOnChange) then
      FOnChange();
end;

constructor TPaginatorFilter<T>.Create(const ItemList : TUltimateObjectList<T>);
begin
  FItemList := ItemList;
  ResetValues;
end;

function TPaginatorFilter<T>.ResetValues : boolean;
begin
  // nothing to initialize
  Result := False;
end;

{ TPaginatorShopFilter<T> }

procedure TPaginatorShopFilter<T>.Filter(var FilteredItems : IDataQuery<T>);
begin
  FilteredItems := FilteredItems.Filter(RQuery.From<EnumShopCategory>(Category) in F('Categories'));
  FilteredItems := FilteredItems.Filter(F('IsVisible'));
  if Category = scCards then
  begin
    inherited Filter(FilteredItems);
  end
  else if Category = scBundles then
      FilteredItems := FilteredItems.Exclude(F('IsTimeLimited')).OrderBy(['ID'])
  else
      FilteredItems := FilteredItems.OrderBy(['Name']);
end;

function TPaginatorShopFilter<T>.ResetValues : boolean;
begin
  Result := inherited;
  Result := Result or (FCategoryFilter <> scSkins);
  FCategoryFilter := scSkins;
end;

procedure TPaginatorShopFilter<T>.SetCategoryFilter(const Value : EnumShopCategory);
begin
  if FCategoryFilter <> Value then
  begin
    FCategoryFilter := Value;
    CallChangeHandler;
  end;
end;

{ HGUIMethods }

class function HGUIMethods.AsRoman(const Value : integer) : string;
begin
  Result := HString.IntToRomanNumeral(Value);
end;

class function HGUIMethods.Ceil(const Value : single) : integer;
begin
  Result := Math.Ceil(Value);
end;

class function HGUIMethods.Date(const Date : TDatetime) : string;
var
  Day, Month, Year : Word;
begin
  DecodeDate(Date, Year, Month, Day);
  if HInternationalizer.CurrentLanguage = 'de' then Result := HString.IntMitNull(Day) + '.' + HString.IntMitNull(Month) + '.'
  else Result := HString.IntMitNull(Month) + '-' + HString.IntMitNull(Day);
end;

class function HGUIMethods.FloatToCooldown(const Value : single) : string;
var
  Seconds : integer;
begin
  Seconds := round(Value * 10);
  if Seconds < 20 then
  begin
    Result := IntToStr(Seconds div 10) + FormatSettings.DecimalSeparator + IntToStr(Seconds mod 10);
  end
  else
      Result := IntToStr(Seconds div 10);
end;

class function HGUIMethods.FloatToStr(const Value : single) : string;
begin
  Result := Format('%.1f', [Value]);
end;

class function HGUIMethods.Floor(const Value : single) : integer;
begin
  Result := Math.Floor(Value);
end;

class function HGUIMethods.IntComma(const Value : integer) : string;
begin
  Result := HString.IntToStr(Value, -1, FormatSettings.ThousandSeparator);
end;

class function HGUIMethods.IntToLongTime(const Value : integer) : string;
begin
  Result := HString.IntToLongTime(Value, False);
end;

class function HGUIMethods.IntToLongTimeDetail(const Value : integer) : string;
begin
  Result := HString.IntToLongTimeDetail(Value, False);
end;

class function HGUIMethods.IntToStr(const Value : integer) : string;
begin
  Result := SysUtils.IntToStr(Value);
end;

class function HGUIMethods.IntToTime(const Value : integer) : string;
begin
  Result := HString.IntToTime(Value, False);
end;

class function HGUIMethods.IntToTimeAdaptive(const Value : integer) : string;
var
  Days, Minutes, Hours, Seconds, Ticks : integer;
begin
  Ticks := Math.Max(0, Value);
  Seconds := Ticks mod 60;
  Minutes := (Ticks div 60) mod 60;
  Hours := (Ticks div 3600) mod 24;
  Days := Ticks div 86400;
  if Days > 2 then
      Result := Format('%d %s', [Days + 1, self._pluralize_d('§misc_time_string_day', Days + 1)])
  else if Days >= 1 then
      Result := Format('%d %s %s %d %s', [Days, _pluralize_d('§misc_time_string_day', Days), _0('§misc_time_string_join'), Hours, _pluralize_d('§misc_time_string_hour', Hours)])
  else if Hours > 2 then
      Result := Format('%d %s', [Hours + 1, self._pluralize_d('§misc_time_string_hour', Hours + 1)])
  else if Hours >= 1 then
      Result := Format('%d %s %s %d %s', [Hours, _pluralize_d('§misc_time_string_hour', Hours), _0('§misc_time_string_join'), Minutes, _pluralize_d('§misc_time_string_minute', Minutes)])
  else if Minutes > 2 then
      Result := Format('%d %s', [Minutes + 1, self._pluralize_d('§misc_time_string_minute', Minutes + 1)])
  else if Minutes >= 1 then
      Result := Format('%d %s %s %d %s', [Minutes, _pluralize_d('§misc_time_string_minute', Minutes), _0('§misc_time_string_join'), Seconds, _pluralize_d('§misc_time_string_second', Seconds)])
  else
      Result := Format('%d %s', [Seconds, self._pluralize_d('§misc_time_string_second', Seconds)]);
end;

class function HGUIMethods.IntToTimeAdaptiveDays(const Value : integer) : string;
var
  Days, Ticks : integer;
begin
  Ticks := Math.Max(0, Value);
  Days := Ticks div 86400;
  if Days >= 1 then
      Result := Format('%d %s', [Days, self._pluralize_d('§misc_time_string_day', Days)])
  else
      Result := HGUIMethods.IntToLongTime(Ticks);
end;

class function HGUIMethods.KeybindingToStr(Keybinding : RBinding) : string;
begin
  Result := Keybinding.ToString;
end;

class function HGUIMethods.KeybindingToStrRaw(Keybinding : RBinding) : string;
begin
  Result := Keybinding.ToStringRaw;
end;

class function HGUIMethods.LoopChars(const Times : integer; const Chars : string) : string;
begin
  Result := HString.GenerateChars(Chars, Times);
end;

class function HGUIMethods.Max(const ValueA, ValueB : single) : single;
begin
  Result := Math.Max(ValueA, ValueB);
end;

class function HGUIMethods.Min(const ValueA, ValueB : single) : single;
begin
  Result := Math.Min(ValueA, ValueB);
end;

class function HGUIMethods.Range(n : integer) : TArray<integer>;
var
  i : integer;
begin
  if n <= 0 then exit(nil);
  setLength(Result, n);
  for i := 0 to n - 1 do
      Result[i] := i;
end;

class function HGUIMethods.Trunc(const Value : single) : integer;
begin
  Result := System.Trunc(Value);
end;

class function HGUIMethods.TruncChars(const Value : string; MaxChars : integer) : string;
begin
  if length(Value) > MaxChars then
  begin
    Result := Copy(Value, 0, MaxChars - 3) + '...';
  end
  else Result := Value;
end;

class function HGUIMethods._(const Key, Value : string) : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Key, [Value]);
end;

class function HGUIMethods._0(const Key : string) : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Key);
end;

class function HGUIMethods._2(const Key, Value, Value2 : string) : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Key, [Value, Value2]);
end;

class function HGUIMethods._d(const Key : string; Value : integer) : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Key, [Value]);
end;

class function HGUIMethods._dd(const Key : string; Value, Value2 : integer) : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Key, [Value, Value2]);
end;

class function HGUIMethods._ds(const Key : string; Value : integer; Value2 : string) : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Key, [Value, Value2]);
end;

class function HGUIMethods._pluralize(const Key : string; Value : integer) : string;
begin
  if Value <> 1 then
      Result := HInternationalizer.TranslateTextRecursive(Key + '_plural', [])
  else
      Result := HInternationalizer.TranslateTextRecursive(Key, []);
end;

class function HGUIMethods._pluralize_d(const Key : string; Value : integer) : string;
begin
  if Value <> 1 then
      Result := HInternationalizer.TranslateTextRecursive(Key + '_plural', [Value])
  else
      Result := HInternationalizer.TranslateTextRecursive(Key, [Value]);
end;

class function HGUIMethods._pluralize_dd(const Key : string; Value, Value2 : integer) : string;
begin
  if Value <> 1 then
      Result := HInternationalizer.TranslateTextRecursive(Key + '_plural', [Value, Value2])
  else
      Result := HInternationalizer.TranslateTextRecursive(Key, [Value, Value2]);
end;

class function HGUIMethods._sss(const Key, Value, Value2, Value3 : string) : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Key, [Value, Value2, Value3]);
end;

{ TIngameHUD }

procedure TIngameHUD.CallClientCommand(Command : EnumClientCommand);
begin
  GlobalEventbus.Trigger(eiClientCommand, [ord(Command), RPARAMEMPTY]);
end;

procedure TIngameHUD.BaseIsUnderAttack;
begin
  FBaseIsUnderAttackTimer.Start;
  if not IsBaseUnderAttack then
      IsBaseUnderAttack := True;
end;

procedure TIngameHUD.CallClientCommand(Command : EnumClientCommand; Param1 : RParam);
begin
  GlobalEventbus.Trigger(eiClientCommand, [ord(Command), Param1]);
end;

procedure TIngameHUD.CameraMoveTo(const Target : RVector2; TimeToMove : integer);
begin
  GlobalEventbus.Trigger(eiCameraMoveTo, [Target, TimeToMove]);
end;

procedure TIngameHUD.ClickCommanderAbility(const UID : string);
var
  CommanderAbility : THUDCommanderAbility;
begin
  if assigned(OnCommanderAbilityClick) and FCommanderAbilities.TryGetValue(UID.ToLowerInvariant, CommanderAbility) then
      OnCommanderAbilityClick(CommanderAbility.CommanderSpellData, geClick);
end;

procedure TIngameHUD.ClickDeckslot(DeckSlot : THUDDeckSlot);
begin
  if assigned(OnCommanderAbilityClick) then
      OnCommanderAbilityClick(DeckSlot.CommanderSpellData, geClick);
end;

procedure TIngameHUD.CommanderChange(CommanderIndex : integer);
begin
  if (0 <= CommanderIndex) and (CommanderIndex < CommanderCount) then
  begin
    CommanderActiveIndex := CommanderIndex;
    GlobalEventbus.Trigger(eiChangeCommander, [CommanderIndex]);
  end;
end;

constructor TIngameHUD.Create;
begin
  FAnnouncementTimer := TTimer.CreatePaused(1000);
  FBaseIsUnderAttackTimer := TTimer.CreatePaused(BASE_IS_UNDER_ATTACK_THROTTLE);
  FCardHintTimer := TTimer.CreatePaused(CARD_HINT_DELAY);
  FCommanderActiveIndex := -1;
  FIsHUDVisible := True;
  FIsSandboxControlVisible := False;
  FCameraRotationSpeed := Settings.GetSingleOption(coSandboxRotationSpeed);
  FCameraScrollSpeed := Settings.GetSingleOption(coGameplayScrollSpeed);
  FCameraRotationOffset := Settings.GetSingleOption(coSandboxRotationOffset);
  FCameraTiltOffset := Settings.GetSingleOption(coSandboxTiltOffset);
  FCameraFoVOffset := Settings.GetSingleOption(coSandboxFoVOffset);
  FCameraLimited := True;
  FSpawnerJumpLastPosition := RVector2.EMPTY;
  FCameraFollowEntity := -1;
  FScoreboardRightTeam := TUltimateList<RScoreboardPlayer>.Create;
  FScoreboardLeftTeam := TUltimateList<RScoreboardPlayer>.Create;
  FTutorialWindowArrowVisible := True;
  FDeckSlotsStage1 := TUltimateObjectList<THUDDeckSlot>.Create;
  FDeckSlotsStage2 := TUltimateObjectList<THUDDeckSlot>.Create;
  FDeckSlotsStage3 := TUltimateObjectList<THUDDeckSlot>.Create;
  FDeckSlotsSpawner := TUltimateObjectList<THUDDeckSlot>.Create;
  FCommanderAbilities := TObjectDictionary<string, THUDCommanderAbility>.Create([doOwnsValues]);
end;

procedure TIngameHUD.DeregisterCommanderAbility(CommanderAbility : THUDCommanderAbility);
begin
  if assigned(CommanderAbility) then
      FCommanderAbilities.Remove(CommanderAbility.UID);
end;

procedure TIngameHUD.DeregisterDeckSlot(DeckSlot : THUDDeckSlot);
begin
  self.DeckSlotsStage1.Remove(DeckSlot);
  self.DeckSlotsStage2.Remove(DeckSlot);
  self.DeckSlotsStage3.Remove(DeckSlot);
  self.DeckSlotsSpawner.Remove(DeckSlot);
end;

destructor TIngameHUD.Destroy;
begin
  FBaseIsUnderAttackTimer.Free;
  FAnnouncementTimer.Free;
  FCardHintTimer.Free;
  FScoreboardLeftTeam.Free;
  FScoreboardRightTeam.Free;
  FDeckSlotsStage1.Free;
  FDeckSlotsStage2.Free;
  FDeckSlotsStage3.Free;
  FDeckSlotsSpawner.Free;
  FCommanderAbilities.Free;
  inherited;
end;

procedure TIngameHUD.HideAnnouncement;
begin
  IsAnnouncementVisible := False;
  FAnnouncementTimer.Pause;
end;

procedure TIngameHUD.Idle;
begin
  if FCardHintTimer.Expired and not FCardHintTimer.Paused and not IsTutorial then
  begin
    CardHintTextVisible := True;
    FCardHintTimer.Start;
    FCardHintTimer.Pause;
  end;
  if FAnnouncementTimer.Expired and not FAnnouncementTimer.Paused then
  begin
    HideAnnouncement;
  end;
  if FBaseIsUnderAttackTimer.Expired and IsBaseUnderAttack then
      IsBaseUnderAttack := False;
end;

procedure TIngameHUD.MousedownCommanderAbility(CommanderAbility : THUDCommanderAbility);
begin
  if assigned(OnCommanderAbilityClick) then
      OnCommanderAbilityClick(CommanderAbility.CommanderSpellData, geMouseDown);
end;

procedure TIngameHUD.MousedownDeckslot(DeckSlot : THUDDeckSlot);
begin
  MousedownCommanderAbility(DeckSlot);
end;

procedure TIngameHUD.OnNexusDamage(TeamID : integer);
begin
  if TeamID = ClientGame.CommanderManager.ActiveCommanderTeamID then
      BaseIsUnderAttack;
end;

function TIngameHUD.RegisterCommanderAbility(const UID : string; CommanderSpellData : TCommanderSpellData) : THUDCommanderAbility;
begin
  Result := THUDCommanderAbility.Create(UID, CommanderSpellData);
  FCommanderAbilities.Add(Result.UID, Result);
end;

function TIngameHUD.RegisterDeckSlot(CardInfo : TCardInfo; SlotIndex : integer; CommanderSpellData : TCommanderSpellData) : THUDDeckSlot;
begin
  Result := THUDDeckSlot.Create(CardInfo, SlotIndex, CommanderSpellData);
  if CardInfo.IsSpawner then
  begin
    self.DeckSlotsSpawner.Add(Result);
  end
  else
  begin
    case CardInfo.Techlevel of
      2 : self.DeckSlotsStage2.Add(Result);
      3 : self.DeckSlotsStage3.Add(Result);
    else
      self.DeckSlotsStage1.Add(Result);
    end;
  end;
end;

procedure TIngameHUD.SendGameEvent(const Eventname : string);
begin
  GlobalEventbus.Trigger(eiGameEvent, [Eventname]);
end;

procedure TIngameHUD.SetAnnouncementSubtitle(const Value : string);
begin
  FAnnouncementSubtitle := Value;
end;

procedure TIngameHUD.SetAnnouncementTimer(const Duration : integer);
begin
  FAnnouncementTimer.SetIntervalAndStart(Duration);
end;

procedure TIngameHUD.SetAnnouncementTitle(const Value : string);
begin
  FAnnouncementTitle := Value;
end;

procedure TIngameHUD.SetAttackBaseCount(const Value : integer);
begin
  FAttackBaseCount := Value;
end;

procedure TIngameHUD.SetCameraFixedToLane(const Value : boolean);
begin
  FCameraFixedToLane := Value;
end;

procedure TIngameHUD.SetCameraFollowEntity(const Value : integer);
begin
  FCameraFollowEntity := Value;
end;

procedure TIngameHUD.SetCameraFoVOffset(const Value : single);
begin
  FCameraFoVOffset := Value;
  Settings.SetSingleOption(coSandboxFoVOffset, Value);
  Settings.SaveSettings;
end;

procedure TIngameHUD.SetCameraFoVOffsetUsed(const Value : boolean);
begin
  FCameraFoVOffsetUsed := Value;
end;

procedure TIngameHUD.SetCameraLaneXLimit(const Value : single);
begin
  FCameraLaneXLimit := Value;
end;

procedure TIngameHUD.SetCameraLaneXLimited(const Value : boolean);
begin
  FCameraLaneXLimited := Value;
end;

procedure TIngameHUD.SetCameraLimited(const Value : boolean);
begin
  FCameraLimited := Value;
end;

procedure TIngameHUD.SetCameraLocked(const Value : boolean);
begin
  FCameraLocked := Value;
end;

procedure TIngameHUD.SetCameraLockedSpawnerJumpEnabled(const Value : boolean);
begin
  FCameraLockedSpawnerJumpEnabled := Value;
end;

procedure TIngameHUD.SetCameraPosition(const Value : RVector2);
begin
  FCameraPosition := Value;
end;

procedure TIngameHUD.SetCameraRotate(const Value : boolean);
begin
  FCameraRotate := Value;
end;

procedure TIngameHUD.SetCameraRotationOffsetUsed(const Value : boolean);
begin
  FCameraRotationOffsetUsed := Value;
end;

procedure TIngameHUD.SetCameraRotationOffset(const Value : single);
begin
  FCameraRotationOffset := Value;
  Settings.SetSingleOption(coSandboxRotationOffset, Value);
  Settings.SaveSettings;
end;

procedure TIngameHUD.SetCameraRotationSpeed(const Value : single);
begin
  FCameraRotationSpeed := Value;
  Settings.SetSingleOption(coSandboxRotationSpeed, Value);
  Settings.SaveSettings;
end;

procedure TIngameHUD.SetCameraScrollSpeed(const Value : single);
begin
  FCameraScrollSpeed := Value;
  Settings.SetSingleOption(coGameplayScrollSpeed, Value);
  Settings.SaveSettings;
end;

procedure TIngameHUD.SetCameraTiltOffset(const Value : single);
begin
  FCameraTiltOffset := Value;
  Settings.SetSingleOption(coSandboxTiltOffset, Value);
  Settings.SaveSettings;
end;

procedure TIngameHUD.SetCameraTiltOffsetUsed(const Value : boolean);
begin
  FCameraTiltOffsetUsed := Value;
end;

procedure TIngameHUD.SetCaptureMode(const Value : boolean);
begin
  FCaptureMode := Value;
end;

procedure TIngameHUD.SetCardHintCardInfo(const Value : TCardInfo);
begin
  FCardHintCardInfo := Value;
  CardHintTextVisible := False;
  FCardHintTimer.Start;
  if not assigned(FCardHintCardInfo) then
      FCardHintTimer.Pause;
end;

procedure TIngameHUD.SetCardHintTextVisible(const Value : boolean);
begin
  FCardHintTextVisible := Value;
end;

procedure TIngameHUD.SetCommanderActiveIndex(const Value : integer);
begin
  FCommanderActiveIndex := Value;
end;

procedure TIngameHUD.SetCommanderCount(const Value : integer);
begin
  FCommanderCount := Value;
end;

procedure TIngameHUD.SetCurrentGold(const Value : integer);
begin
  FCurrentGold := Value;
end;

procedure TIngameHUD.SetCurrentGoldCap(const Value : integer);
begin
  FCurrentGoldCap := Value;
end;

procedure TIngameHUD.SetCurrentGoldIncome(const Value : integer);
begin
  FCurrentGoldIncome := Value;
end;

procedure TIngameHUD.SetCurrentTier(const Value : integer);
begin
  FCurrentTier := Value;
end;

procedure TIngameHUD.SetCurrentWood(const Value : integer);
begin
  FCurrentWood := Value;
end;

procedure TIngameHUD.SetCurrentWoodIncome(const Value : integer);
begin
  FCurrentWoodIncome := Value;
end;

procedure TIngameHUD.SetDeckSlotsSpawner(const Value : TUltimateObjectList<THUDDeckSlot>);
begin
  // only notification
end;

procedure TIngameHUD.SetDeckSlotsStage1(const Value : TUltimateObjectList<THUDDeckSlot>);
begin
  // only notification
end;

procedure TIngameHUD.SetDeckSlotsStage2(const Value : TUltimateObjectList<THUDDeckSlot>);
begin
  // only notification
end;

procedure TIngameHUD.SetDeckSlotsStage3(const Value : TUltimateObjectList<THUDDeckSlot>);
begin
  // only notification
end;

procedure TIngameHUD.SetFPS(const Value : integer);
begin
  FFPS := Value;
end;

procedure TIngameHUD.SetHasGameStarted(const Value : boolean);
begin
  FHasGameStarted := Value;
end;

procedure TIngameHUD.SetHUDState(const Value : EnumHUDState);
begin
  FHUDState := Value;
  // close menu if leaving normal game hud
  if not(FHUDState in [hsGame]) then IsMenuOpen := False;
end;

procedure TIngameHUD.SetIncomeUpgrades(const Value : integer);
begin
  FIncomeUpgrades := Value;
end;

procedure TIngameHUD.SetIsAnnouncementVisible(const Value : boolean);
begin
  FIsAnnouncementVisible := Value;
end;

procedure TIngameHUD.SetIsBaseUnderAttack(const Value : boolean);
begin
  FIsBaseUnderAttack := Value;
end;

procedure TIngameHUD.SetIsHUDVisible(const Value : boolean);
begin
  FIsHUDVisible := Value;
end;

procedure TIngameHUD.SetIsMenuOpen(const Value : boolean);
begin
  FIsMenuOpen := Value;
end;

procedure TIngameHUD.SetIsPvEAttack(const Value : boolean);
begin
  FIsPvEAttack := Value;
end;

procedure TIngameHUD.SetIsReconnecting(const Value : boolean);
begin
  FIsReconnecting := Value;
end;

procedure TIngameHUD.SetIsSandbox(const Value : boolean);
begin
  FIsSandbox := Value;
end;

procedure TIngameHUD.SetIsSandboxControlVisible(const Value : boolean);
begin
  FIsSandboxControlVisible := Value;
end;

procedure TIngameHUD.SetIsSettingsOpen(const Value : boolean);
begin
  FIsSettingsOpen := Value;
end;

procedure TIngameHUD.SetIsTeamMode(const Value : boolean);
begin
  FIsTeamMode := Value;
end;

procedure TIngameHUD.SetIsTechnicalPanelVisible(const Value : boolean);
begin
  FIsTechnicalPanelVisible := Value;
end;

procedure TIngameHUD.SetIsTutorial(const Value : boolean);
begin
  FIsTutorial := Value;
end;

procedure TIngameHUD.SetIsTutorialHintOpen(const Value : boolean);
begin
  FIsTutorialHintOpen := Value;
end;

procedure TIngameHUD.SetKeepResourcesInCaptureMode(const Value : boolean);
begin
  FKeepResourcesInCaptureMode := Value;
end;

procedure TIngameHUD.SetLeftNexusHealth(const Value : integer);
begin
  if Value < FLeftNexusHealth then
      OnNexusDamage(LeftTeamID);
  FLeftNexusHealth := Value;
end;

procedure TIngameHUD.SetLeftTeamID(const Value : integer);
begin
  FLeftTeamID := Value;
end;

procedure TIngameHUD.SetMaxIncomeUpgrades(const Value : integer);
begin
  FMaxIncomeUpgrades := Value;
end;

procedure TIngameHUD.SetMousePosition(const Value : RVector2);
begin
  FMousePosition := Value;
end;

procedure TIngameHUD.SetMouseScreenPosition(const Value : RIntVector2);
begin
  FMouseScreenPosition := Value;
end;

procedure TIngameHUD.SetPing(const Value : integer);
begin
  FPing := Value;
end;

procedure TIngameHUD.SetPreventConsecutivePlaying(const Value : boolean);
begin
  FPreventConsecutivePlaying := Value;
end;

procedure TIngameHUD.SetResolution(const Value : RIntVector2);
begin
  FResolution := Value;
end;

procedure TIngameHUD.SetRightNexusHealth(const Value : integer);
begin
  if Value < FRightNexusHealth then
      OnNexusDamage(RightTeamID);
  FRightNexusHealth := Value;
end;

procedure TIngameHUD.SetRightTeamID(const Value : integer);
begin
  FRightTeamID := Value;
end;

procedure TIngameHUD.SetSandboxSpawnWithOverwatch(const Value : boolean);
begin
  FSandboxSpawnWithOverwatch := Value;
end;

procedure TIngameHUD.SetSandboxSpawnWithOverwatchClearable(const Value : boolean);
begin
  FSandboxSpawnWithOverwatchClearable := Value;
end;

procedure TIngameHUD.SetScoreboardVisible(const Value : boolean);
begin
  FScoreboardVisible := Value;
end;

procedure TIngameHUD.SetShowCardHotkeys(const Value : boolean);
begin
  FShowCardHotkeys := Value;
end;

procedure TIngameHUD.SetShowCardNumericChargeProgress(
  const Value : boolean);
begin
  FShowCardNumericChargeProgress := Value;
end;

procedure TIngameHUD.SetSpawnTimer(const Value : string);
begin
  FSpawnTimer := Value;
end;

procedure TIngameHUD.SetSpentWood(const Value : integer);
begin
  FSpentWood := Value;
end;

procedure TIngameHUD.SetSpentWoodToIncomeUpgrade(const Value : integer);
begin
  FSpentWoodToIncomeUpgrade := Value;
end;

procedure TIngameHUD.SetTimeToAttack(const Value : integer);
begin
  FTimeToAttack := Value;
end;

procedure TIngameHUD.SetTimeToNextBossWave(const Value : integer);
begin
  FTimeToNextBossWave := Value;
end;

procedure TIngameHUD.SetTimeToNextTier(const Value : integer);
begin
  FTimeToNextTier := Value;
end;

procedure TIngameHUD.SetTutorialHintFullscreen(const Value : boolean);
begin
  FTutorialHintFullscreen := Value;
end;

procedure TIngameHUD.SetTutorialHintText(const Value : string);
begin
  FTutorialHintText := Value;
end;

procedure TIngameHUD.SetTutorialWindowAnchor(const Value : EnumComponentAnchor);
begin
  FTutorialWindowAnchor := Value;
end;

procedure TIngameHUD.SetTutorialWindowArrowVisible(const Value : boolean);
begin
  FTutorialWindowArrowVisible := Value;
end;

procedure TIngameHUD.SetTutorialWindowBackdrop(const Value : boolean);
begin
  FTutorialWindowBackdrop := Value;
end;

procedure TIngameHUD.SetTutorialWindowButtonText(const Value : string);
begin
  FTutorialWindowButtonText := Value;
end;

procedure TIngameHUD.SetTutorialWindowHighlight(const Value : boolean);
begin
  FTutorialWindowHighlight := Value;
end;

procedure TIngameHUD.SetTutorialWindowPosition(const Value : RIntVector2);
begin
  FTutorialWindowPosition := Value;
end;

procedure TIngameHUD.ShowAnnouncement(const AnnouncementUID : string);
begin
  AnnouncementTitle := '§core_announcement_title_' + AnnouncementUID;
  AnnouncementSubtitle := '§core_announcement_subtitle_' + AnnouncementUID;
  IsAnnouncementVisible := True;
end;

procedure TIngameHUD.ShowAnnouncementForTime(const AnnouncementUID : string; const Duration : integer);
begin
  ShowAnnouncement(AnnouncementUID);
  SetAnnouncementTimer(Duration);
end;

procedure TIngameHUD.SpawnerJump;
  function GetNexusPosition : RVector2;
  var
    Nexus : TEntity;
  begin
    Nexus := Game.EntityManager.NexusByTeamID(ClientGame.CommanderManager.ActiveCommanderTeamID);
    if assigned(Nexus) then
        Result := Nexus.DisplayPosition.XZ
    else
        Result := RVector2.ZERO;
  end;

var
  NexusPosition : RVector2;
begin
  if not self.CameraLocked or self.CameraLockedSpawnerJumpEnabled then
  begin
    NexusPosition := GetNexusPosition;
    if Game.GameInfo.Scenario.MapName = MAP_DOUBLE then
        NexusPosition := NexusPosition.SetY(sign(FSpawnerJumpLastPosition.Y) * 15)
    else
        NexusPosition := NexusPosition + RVector2.Create(sign(NexusPosition.X) * 10.5, 0);

    if NexusPosition.SetY(0).Distance(GlobalEventbus.Read(eiCameraPosition, []).AsVector2.SetY(0)) > 20 then
    begin
      FSpawnerJumpLastPosition := GlobalEventbus.Read(eiCameraPosition, []).AsVector2;
      self.CameraMoveTo(NexusPosition, 100);
    end
    else if not FSpawnerJumpLastPosition.IsEmpty then
    begin
      self.CameraMoveTo(FSpawnerJumpLastPosition, 100);
      FSpawnerJumpLastPosition := RVector2.EMPTY;
    end;
    if IsTutorial then
        SendGameEvent(GAME_EVENT_SPAWNER_JUMP);
  end;
end;

procedure TIngameHUD.Surrender;
begin
  // send server that my team wants to lose
  // TODO: improve surrender handling
  if assigned(Game) then
  begin
    GlobalEventbus.Trigger(eiSurrender, [ClientGame.CommanderManager.ActiveCommanderTeamID]);
  end;
end;

procedure TIngameHUD.UpdateHotkeysInDeck;
var
  i : integer;
begin
  for i := 0 to FDeckSlotsStage1.Count - 1 do
      FDeckSlotsStage1[i].UpdateHotkey;
  for i := 0 to FDeckSlotsStage2.Count - 1 do
      FDeckSlotsStage2[i].UpdateHotkey;
  for i := 0 to FDeckSlotsStage3.Count - 1 do
      FDeckSlotsStage3[i].UpdateHotkey;
  for i := 0 to FDeckSlotsSpawner.Count - 1 do
      FDeckSlotsSpawner[i].UpdateHotkey;
end;

{ RScoreboardPlayer }

constructor RScoreboardPlayer.Create(const username, deckname, DeckIcon : string);
begin
  self.username := username;
  self.deckname := deckname;
  self.deck_icon := DeckIcon;
end;

{ THUDDeckSlot }

constructor THUDDeckSlot.Create(CardInfo : TCardInfo; Slot : integer; CommanderSpellData : TCommanderSpellData);
begin
  inherited Create('DeckSlot_' + Slot.ToString, CommanderSpellData);
  FSlot := Slot;
  FCardInfo := CardInfo;
  UpdateHotkey;
end;

procedure THUDDeckSlot.SetCardInfo(const Value : TCardInfo);
begin
  FCardInfo := Value;
end;

procedure THUDDeckSlot.SetCooldownSeconds(const Value : single);
begin
  FCooldownSeconds := Value;
end;

procedure THUDDeckSlot.SetChargeProgress(const Value : single);
begin
  FChargeProgress := Value;
end;

procedure THUDDeckSlot.SetCurrentCharges(const Value : integer);
begin
  FCurrentCharges := Value;
end;

procedure THUDDeckSlot.SetHotkey(const Value : string);
begin
  FHotkey := Value;
end;

procedure THUDDeckSlot.SetIsReady(const Value : boolean);
begin
  FIsReady := Value;
end;

procedure THUDDeckSlot.SetMaxCharges(const Value : integer);
begin
  FMaxCharges := Value;
end;

procedure THUDDeckSlot.SetSlot(const Value : integer);
begin
  FSlot := Value;
end;

procedure THUDDeckSlot.UpdateHotkey;
var
  Binding : RBinding;
begin
  if (Slot >= 0) and (Slot <= 11) then
  begin
    Binding := Settings.GetKeybinding(EnumClientOption(ord(coKeybindingBindingDeckslot01) + Slot * 2));
    Hotkey := Binding.ToString;
  end
  else
      Hotkey := '';
end;

{ THUDCommanderAbility }

constructor THUDCommanderAbility.Create(const UID : string; CommanderSpellData : TCommanderSpellData);
begin
  FUID := UID.ToLowerInvariant;
  FCommanderSpellData := CommanderSpellData;
end;

destructor THUDCommanderAbility.Destroy;
begin
  FCommanderSpellData.Free;
  inherited;
end;

end.
