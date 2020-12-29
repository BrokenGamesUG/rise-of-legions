unit BaseConflict.EntityComponents.Server;

interface

uses
  // ===== Delphi ==========
  System.SysUtils,
  System.Math,
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  System.Generics.Defaults,
  Winapi.Windows,
  // ===== Engine ==========
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Log,
  Engine.Collision,
  Engine.Serializer,
  Engine.Network,
  Engine.Script,
  // ===== Game ==========
  BaseConflict.Classes.Shared,
  BaseConflict.Game,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Scenario,
  BaseConflict.Constants.Scenario.Server,
  BaseConflict.Types.Target,
  BaseConflict.Types.Server,
  BaseConflict.Types.Shared,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Server.Brains,
  BaseConflict.Globals,
  BaseConflict.Map,
  BaseConflict.Api,
  BaseConflict.Api.Types;

type

  {$RTTI INHERIT}
  TBuffComponent = class(TEntityComponent)
    public
      [ScriptExcludeMember]
      /// <summary> An entity which gives a buff to another unit will call this with its data, so the
      /// buff can read it needed values at the time of creation. </summary>
      procedure Initialize(Creator : TEntity; ComponentGroup : SetComponentGroup); virtual;
  end;

  {$RTTI INHERIT}

  /// <summary> Manipulates the received damage of an unit. This component can be used to increase or decrease the
  /// amount of damage the owner receives.
  /// Normally this component is put alone in a local group.
  /// eiWelaModifier is multiplied with the incoming damage, so for damage reduction use values <1.0 and for boosts >1.0.
  /// If eiDamageType is set the factor is only applied to damage of this type. </summary>
  TBuffTakenDamageMultiplierComponent = class(TEntityComponent)
    protected
      FDamageMustHave, FDamageMustHaveAny, FDamageMustNotHave : SetDamageType;
      FReflect, FDodge, FOnHeal, FFlatValue : boolean;
    published
      [XEvent(eiTakeDamage, epLow, etRead)]
      /// <summary> Reduce the taken damage if DamageType matches. </summary>
      function OnTakeDamage(var Amount : RParam; DamageType : RParam; InflictorID : RParam; Previous : RParam) : RParam;
      [XEvent(eiHeal, epLower, etRead)]
      /// <summary> Modifies the taken heal if damagetypes matches. </summary>
      function OnHeal(var Amount : RParam; DamageType : RParam; InflictorID : RParam; Previous : RParam) : RParam;
    public
      function DamageTypeMustHaveAny(DamageTypes : TArray<byte>) : TBuffTakenDamageMultiplierComponent;
      function DamageTypeMustHave(DamageTypes : TArray<byte>) : TBuffTakenDamageMultiplierComponent;
      function DamageTypeMustNotHave(DamageTypes : TArray<byte>) : TBuffTakenDamageMultiplierComponent;
      function ReflectReducedDamage : TBuffTakenDamageMultiplierComponent;
      function DodgeDamage : TBuffTakenDamageMultiplierComponent;
      function ApplyOnHeal : TBuffTakenDamageMultiplierComponent;
      function Flat : TBuffTakenDamageMultiplierComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Manipulates the received damage of an unit. This component can be used to cap the
  /// amount of damage the owner receives by its (maximum health * eiWeladamage).
  /// Normally this component is put alone in the globl group.
  /// </summary>
  TBuffCapDamageByHealthComponent = class(TBuffComponent)
    protected
      FFactor : single;
    published
      [XEvent(eiTakeDamage, epLow, etRead)]
      /// <summary> Reduce the taken damage if its exceedes a percent of life. </summary>
      function OnTakeDamage(var Amount : RParam; DamageType : RParam; InflictorID : RParam; Previous : RParam) : RParam;
    public
      [ScriptExcludeMember]
      procedure Initialize(Creator : TEntity; ComponentGroup : SetComponentGroup); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Manipulates the eiWeladamage. This component can be used to increase or decrease the
  /// efficiency of an wela, e.g. to buff the damage output.
  /// Normally this component is put in the same group of an existing wela.
  /// eiWeladamage is multiplied with the set factor (which is derived from eiWelaDamage of the creator),
  /// so for damage reduction use values <1.0 and for buffs >1.0.
  /// The Buff can be tuned to last only for the next x eiWeladamage-Events with eiWelaCount of the creator,
  /// self destructing afterwards. </summary>
  TBuffDamageMultiplierComponent = class(TBuffComponent)
    protected
      FFactor : single;
      FCount : integer;
    published
      [XEvent(eiWeladamage, epMiddle, etRead)]
      /// <summary> Multiply the eiWeladamage with a factor. </summary>
      function OnWelaDamage(PrevValue : RParam) : RParam;
    public
      [ScriptExcludeMember]
      procedure Initialize(Creator : TEntity; ComponentGroup : SetComponentGroup); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Heals the owner whenever he deals damage. All warheads send eiDamageDone entity globally if they do damage.
  /// Normally this component is put alone in a local group.
  /// Uses eiWeladamage to determine how much of the dealt damage is converted to health, so 0.5 would heal
  /// the owner for the half of each damage dealt. </summary>
  TBuffLifeLeechComponent = class(TEntityComponent)
    published
      [XEvent(eiDamageDone, epLast, etTrigger)]
      /// <summary> Heals for damage dealt. </summary>
      function OnDoneDamage(Amount, DamageType, TargetEntity : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Only the Nexus get this component. Lose-Condition for teams.
  /// When the owner of this component dies (eiDie) the owning team loses the game (eiLose is send). </summary>
  TServerPrimaryTargetComponent = class(TPrimaryTargetComponent)
    published
      [XEvent(eiDie, epFirst, etTrigger)]
      /// <summary> If Nexus dies, the owning team loses. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> The wela-"brain" of a link. It uses the eiCooldown of the link to fire it warheads, whenever
  /// the cooldown expires. All links should have this component to have their welas started.  </summary>
  TLinkBrainComponent = class(TEntityComponent)
    protected
      FFiresAtSources, FFiresAtCreate : boolean;
      FSourceTargetGroup, FFiresAtCreateGroup : SetComponentGroup;
      FTimer : TTimer;
      procedure FetchCooldown;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Set firewarheadevents whenever timer expires. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); override;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function FiresAtSources(Group : TArray<byte>) : TLinkBrainComponent;
      function FiresAtCreate(Group : TArray<byte>) : TLinkBrainComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles all networkthings at the server. Written bei Martin so comment it yourself!
  /// Created at game initialization and attached to the global entity. </summary>
  TServerNetworkComponent = class(TNetworkComponent)
    private const
      MAX_CLIENTS     = 16;
      MAX_PACKET_SIZE = 50 * 1024;
      RECONNECT_TIME  = 60000;
      SPECTATOR_TOKEN = '';

    type
      TSendedData = class
        Data : TCommandSequence;
        // when was data sended
        Timestamp : LongWord;
        constructor Create(Data : TCommandSequence);
        destructor Destroy; override;
      end;

      EnumNetworkPlayerState = (
        psNone,         // player never connected to server
        psPreparing,    // player connected to server and loading core game data -> not ready to receive game data
        psPlaying,      // player ready for reciving game data and will send input data
        psReconnecting, // player has lost connection and will try to reconnect if allowed
        psDisconnected  // player has lost connection permanently, it's impossible for player to continue game
        );

      EnumPlayerQuitReason = (
        qrNone,                       // reason not set - player never connected
        qrNormal,                     // player quit game in normal way (after game finished)
        qrSurrendered,                // player surrendeded while game was running
        qrDisconnectedWhilePreparing, // player close connection while in preparing state
        qrDisconnectedWhilePlaying,   // player close connection while in state playing, will be set back to qrNormal when player reconnect
        qrRageQuit                    // player close game while was running (hard surrender)
        );

      TNetworkPlayer = class
        strict private
          FNetworkComponent : TServerNetworkComponent;
          FState : EnumNetworkPlayerState;
          FQuitReason : EnumPlayerQuitReason;
          FSendedData : TObjectRingBuffer<TSendedData>;
          FToken : string;
          FPlayerID, FTeamID : integer;
          FSocket : TTCPClientSocketDeluxe;
          FReconnectTimer : TTimer;
          procedure ProcessNewData(Data : TDatapacket);
          procedure ResendData(LastReceivedIndex : integer);
        public
          function IsSpectator : boolean;
          property Token : string read FToken;
          property PlayerID : integer read FPlayerID;
          property TeamID : integer read FTeamID;
          property State : EnumNetworkPlayerState read FState write FState;
          property QuitReason : EnumPlayerQuitReason read FQuitReason write FQuitReason;
          /// <summary> Set socket for player.</summary>
          procedure AssignSocket(Socket : TTCPClientSocketDeluxe);
          function TryReconnect(NewSocket : TTCPClientSocketDeluxe; LastReceivedDataIndex : integer) : boolean;
          procedure SendData(Data : TCommandSequence);
          /// <summary> Close connection to client.</summary>
          procedure Disconnect;
          // --------- State shortcuts
          /// <summary> Player is has connected to server and connection is healthy (reconnect is also a healthy state)</summary>
          function IsConnected : boolean;
          function IsDisconnected : boolean;
          // ----------- Standard methods ----------------
          constructor Create(const Token : string; PlayerID : integer; TeamID : integer; NetworkComponent : TServerNetworkComponent);
          procedure Idle;
          destructor Destroy; override;
      end;
    protected
      /// <summary> Server socket that listen on port and accept new clients.</summary>
      FTCPServerSocket : TTCPServerSocket;
      FAllowReconnect : boolean;
      /// <summary> New clients connected to server, but not yet sended any token to assign them to player. </summary>
      FConnectedClients : TObjectList<TTCPClientSocketDeluxe>;
      /// <summary> List of all players. Is fill with data on creation.</summary>
      FPlayers : TObjectList<TNetworkPlayer>;
      function GetPlayerByToken(const Token : string) : TNetworkPlayer;
      procedure RefuseConnection(Connection : TTCPClientSocketDeluxe; Token : string; ErrorCode : integer = 400);
      procedure SendWorld(Player : TNetworkPlayer);
      /// <summary> Returns whether the Sender has been deleted. </summary>
      function ProcessNewData(Data : TDatapacket; Sender : TTCPClientSocketDeluxe) : boolean;
      procedure OnClientConnect(ClientSocket : TSocket; InetAddress : RInetAddress);
      procedure SendEntities(Entities : TList<TEntity>; Receiver : TNetworkPlayer); overload;
      procedure SendEntities(Entities : TList<TEntity>); overload;
      function GetPort : Word;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Compute.Send.Receive. </summary>
      function OnIdle : boolean;
      [XEvent(eiSendEntities, epLast, etTrigger, esGlobal)]
      /// <summary> Send the list of entities to all clients. </summary>
      function OnSendEntities(Entities : RParam) : boolean;
      [XEvent(eiServerShutdown, epLast, etTrigger, esGlobal)]
      /// <summary> Send all clients a shutdown and kill connections. </summary>
      function OnServerShutdown : boolean;
      [XEvent(eiSurrender, epLast, etTrigger, esGlobal)]
      function OnSurrender(TeamID : RParam) : boolean;
    public
      property Port : Word read GetPort;
      /// <summary> If True, player can try to reconnect to server after disconnect else any disconnect will be permanent.
      /// After player successful reconnect, all data player missed is resended.</summary>
      property AllowReconnect : boolean read FAllowReconnect write FAllowReconnect;
      constructor Create(Owner : TEntity; GameInformation : TServerGameInformation); reintroduce;
      /// <summary> Send data to any connected player.</summary>
      procedure Send(Data : TCommandSequence); overload; override;
      /// <summary> Send data to player. If player is nil, data is sended to every player.</summary>
      procedure SendDirectly(Data : TCommandSequence; Player : TNetworkPlayer);
      /// <summary> Returns the number of player connected to </summary>
      function ConnectedPlayerCount : integer;
      /// <summary> Returns True if all players connected.</summary>
      function AllPlayersConnected : boolean;
      /// <summary> Returns True if all players ready for game (in state playing) </summary>
      function AllPlayersInStatePlaying : boolean;
      /// <summary> Return true if all players are disconnected (but at least one was connected).</summary>
      function AllPlayersDisconnected : boolean;
      /// <summary> Return true if any players is disconnected. A player never connected to server counts NOT as disconnected.</summary>
      function AnyPlayerDisconnected : boolean;
      /// <summary> Broadcast to any player connected abort command.</summary>
      procedure SendAbort;
      procedure DisconnectAllPlayers;
      procedure BuildStatistics(var Statistics : RGameFinishedStatistics);
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Holds the TokenMapping on the server (playertoken to map playerslot mapping).
  /// Created at game initialization and attached to the global entity. </summary>
  TTokenMappingComponent = class(TEntityComponent)
    published
      [XEvent(eiTokenMapping, epFirst, etRead, esGlobal)]
      /// <summary> Return the tokenmapping. </summary>
      function OnTokenMapping(Token : RParam) : RParam;
    private
      FTokenMapping : TObjectDictionary<string, TList<integer>>;
    public
      constructor Create(Owner : TEntity; TokenMapping : TObjectDictionary < string, TList < integer >> ); reintroduce;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Waits until enough clients have shown their want to surrender and then defeat them.
  /// At the moment it only works in single player mode against bots.
  /// TODO: extend functionality to multiplayer. </summary>
  TSurrenderComponent = class(TEntityComponent)
    protected
      FCanSurrender : boolean;
    published
      [XEvent(eiSurrender, epLast, etTrigger, esGlobal)]
      /// <summary> Initiates the defeat of the team. </summary>
      function OnSurrender(SurrenderingTeamID : RParam) : boolean;
    public
      constructor Create(Owner : TEntity; ClientCount : integer); reintroduce;
  end;

  {$RTTI INHERIT}

  /// <summary> Tracks the playing of cards of the commanders. </summary>
  TServerCardPlayStatisticsComponent = class(TEntityComponent)
    protected
      FScriptFile : string;
    published
      [XEvent(eiUseAbility, epLast, etTrigger)]
      /// <summary> Logs the usage of this card. </summary>
      function OnUseAbility(Targets : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; ScriptFile : string); reintroduce;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles all specific collisionqueries of the server. The TCollisionManagerComponent wraps all simple
  /// collisionqueries. This derivation extends it with special queries for welas with efficiency.
  /// Created at game initialization and attached to the global entity. </summary>
  TServerCollisionManagerComponent = class(TCollisionManagerComponent)
    published
      [XEvent(eiEnemiesInRangeEfficiency, epFirst, etRead, esGlobal)]
      /// <summary> Return all matching enemies. </summary>
      function OnEnemiesInRangeOf(Position : RParam; Range : RParam; SourceTeamID, TargetTeamConstraint : RParam; Filter : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Serverside entitymanager. Provides numerous methods to be called globally.
  /// Created at game initialization and attached to the global entity. </summary>
  [ScriptExcludeAll]
  TServerEntityManagerComponent = class(TEntityManagerComponent)
    protected
      FEntitiesToKill : TList<integer>;
    published
      [XEvent(eiDelayedKillEntity, epLast, etTrigger, esGlobal)]
      /// <summary> Add entity to kill-on-next-frame-list. </summary>
      function OnDelayedKillEntity(EntityID : RParam) : boolean;
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      /// <summary> Initiates the defeat of the team. </summary>
      function OnLose(TeamID : RParam) : boolean;
    public
      const
      INHERIT_FROM_GAME = -1;
    var
      constructor Create(Owner : TEntity); override;
      /// <summary> Creates a new entity with given setting.
      /// PatternFileName - Filename of Scriptfile containing code to create entity relative so script path and
      /// without extension, e.g. 'Units\Archer' </summary>
      [ScriptIncludeMember]
      function SpawnUnit(PositionX, PositionY : single; PatternFileName : string; TeamID : integer) : TEntity; overload;
      [ScriptIncludeMember]
      function SpawnUnitWithFront(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer) : TEntity;
      [ScriptIncludeMember]
      function SpawnUnitWithOverwatch(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer) : TEntity; overload;
      [ScriptIncludeMember]
      function SpawnUnitWithOverwatchAndFlee(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer; FleeDistance : single) : TEntity; overload;
      [ScriptIncludeMember]
      function SpawnUnitWithoutLimitedLifetime(PositionX, PositionY : single; PatternFileName : string; TeamID : integer) : TEntity;
      [ScriptIncludeMember]
      function SpawnUnitWithoutLimitedLifetimeWithFront(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer) : TEntity;

      function SpawnSpawner(BuildGridID : integer; BuildGridCoordinate : RIntVector2; PatternFileName : string; TeamID : integer; OwnerCommanderID : integer; Creator : TEntity; Callback : ProcSetUpEntity; CreateMethod : string = '') : TEntity; overload;
      function SpawnSpawner(BuildGridID : integer; BuildGridCoordinate : RIntVector2; PatternFileName : string; TeamID : integer; OwnerCommanderID : integer; Creator : TEntity; Callback, PreProcessing : ProcSetUpEntity; CreateMethod : string = '') : TEntity; overload;
      function SpawnUnitWithOverwatch(Position, Front : RVector2; PatternFileName : string; TeamID : integer) : TEntity; overload;
      function SpawnUnitWithOverwatchAndFlee(Position, Front : RVector2; PatternFileName : string; TeamID : integer; FleeDistance : single) : TEntity; overload;

      function SpawnUnit(Position, Front : RVector2; PatternFileName : string; League, Level, TeamID : integer) : TEntity; overload;
      function SpawnUnit(Position, Front : RVector2; PatternFileName : string; League, Level, TeamID : integer; OwnerCommanderID : integer; Creator : TEntity) : TEntity; overload;
      function SpawnUnit(Position, Front : RVector2; PatternFileName : string; League, Level, TeamID : integer; OwnerCommanderID : integer; Creator : TEntity; Callback : ProcSetUpEntity; PreProcessing : ProcSetUpEntity = nil; PostProcessing : ProcSetUpEntity = nil; CreateMethod : string = '') : TEntity; overload;
      /// <summary> Creates a new entity of the given scriptfile. A callback method enables you to set up the
      /// entity before it gets deployed and sent.
      /// PatternFileName - Filename of Scriptfile containing code to create entity relative so script path and
      /// without extension, e.g. 'Units\Archer' </summary>
      function SpawnUnitRaw(PatternFileName : string; Callback : ProcSetUpEntity) : TEntity;
      procedure Idle; override;
      destructor Destroy; override;
  end;

  /// <summary> A message of a specific game. All crashing errors are important and should be displayed always! </summary>
  ProcNewLogMessage = procedure(Message : string) of object;
  /// <summary> For each event this procedure is called, send means whether the event is send to the clients or only processed locally. </summary>
  ProcFiredEvent = procedure(Event : EnumEventIdentifier; Send : boolean) of object;

  {$RTTI INHERIT}

  /// <summary> Will continously create units that fight against another to simulate server load. Will balance
  /// number of units for both sides, so that for every unit dying on one site, component will spawn units for another side.</summary>
  TBenchmarkServerComponent = class(TEntityComponent)
    protected
      FSpawndUnits : TDictionary<integer, TEntity>;
      FLeftSideCount, FRightSideCount : integer;
      FBenchScript : TScript;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Spawn new units if old was lost.</summary>
      function OnIdle() : boolean;
      [XEvent(eiKillEntity, epFirst, etTrigger, esGlobal)]
      /// <summary> Get informed if any spawned units dies (need to recreate unit)</summary>
      function OnKillEntity(EntityID : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Adds infinite resources to all commanders. </summary>
  TServerSandboxComponent = class(TEntityComponent)
    published
      [XEvent(eiGameCommencing, epLast, etTrigger, esGlobal)]
      function OnGameCommencing() : boolean;
  end;

  {$RTTI INHERIT}

  TServerSandboxCommandComponent = class(TEntityComponent)
    published
      [XEvent(eiClientCommand, epLast, etTrigger, esGlobal)]
      function OnClientCommand(Command, Param1 : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles all actions in the tutorial. </summary>
  TTutorialDirectorServerComponent = class(TEntityComponent)
    strict private
      FFrozen, FNoWaveSpawn, FIncomeDisabled : boolean;
    published
      [XEvent(eiIncome, epLast, etRead, esGlobal)]
      function OnReadIncome(CommanderID, Previous : RParam) : RParam;
      [XEvent(eiWaveSpawn, epFirst, etTrigger, esGlobal)]
      function OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
      [XEvent(eiNewEntity, epLast, etTrigger, esGlobal)]
      function OnNewEntity(NewEntity : RParam) : boolean;
      [XEvent(eiGameEvent, epLast, etTrigger, esGlobal)]
      function OnGameEvent(Eventname : RParam) : boolean;
      [XEvent(eiGameTick, epFirst, etTrigger, esGlobal)]
      function OnGameTick() : boolean;
      [XEvent(eiClientCommand, epLast, etTrigger, esGlobal)]
      function OnClientCommand(Command, Eventname : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles all actions in the tutorial. </summary>
  TCommanderAbility = class(TEntityComponent)
    strict private
      FCardInfo : TCardInfo;
      FChargeGroup : SetComponentGroup;
      FMultiModes : TArray<SetComponentGroup>;
    published
      [XEvent(eiEnumerateCommanderAbilities, epLast, etRead)]
      function OnEnumerateCommanderAbilities(Previous : RParam) : RParam;
    public
      function CardInfo(CardInfo : TCardInfo) : TCommanderAbility;
      function ChargeGroup(ChargeGroup : TArray<byte>) : TCommanderAbility;
      function IsMultiMode(MultiModes : TArray<byte>) : TCommanderAbility;
    public
      property GetCardInfo : TCardInfo read FCardInfo;
      [ScriptExcludeMember]
      property GetChargeGroup : SetComponentGroup read FChargeGroup;
      [ScriptExcludeMember]
      function CanUseAbility(const Targets : ACommanderAbilityTarget; Mode : integer = 0) : boolean;
      [ScriptExcludeMember]
      procedure UseAbility(const Targets : ACommanderAbilityTarget; Mode : integer = 0);
      function ModeCount : integer;
      function IsReady : boolean;
      function CurrentCharges : integer;
      function MaxCharges : integer;
  end;

  {$RTTI INHERIT}

  RCurrentUnitStatistic = record
    DropCount, SpawnerCount, BuildingCount : integer;
  end;

  {$RTTI EXPLICIT METHODS([vcPublished]) PROPERTIES([vcPublished])}
  {$M+}

  TPvPBotComponent = class(TEntityComponent)
    strict private
    const
      MAX_INCOME_LEVEL = 10;
      INCOME_TABLE : array [0 .. MAX_INCOME_LEVEL] of integer = (10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);
      INCOME_LEVEL_WOOD_SPENT : array [0 .. MAX_INCOME_LEVEL] of integer = (1500, 3250, 5250, 7500, 10000, 12750, 15750, 19000, 22500, 26250, 1000000);

    type
      TEnhancedCardInfo = class
        strict private
          FCardInfo : TCardInfo;
          FTypes : SetUnitTypes;
          FChargeCooldown, FMaxChargeCount, FCurrentChargeCount : integer;
          FLastRechargeTimeStamp : int64;
          FTier : integer;
          FLegendary : boolean;
          procedure ApplyCurrentRecharging;
        public
          property Tier : integer read FTier;
          property CardInfo : TCardInfo read FCardInfo;
          property Types : SetUnitTypes read FTypes;
          property Legendary : boolean read FLegendary;
          constructor Create(CardInfo : TCardInfo);
          /// <summary> Returns whether this card has charges and can be used. </summary>
          function IsReady : boolean;
          /// <summary> Uses this card, removing a charge from it. </summary>
          procedure Use;
      end;

      TBaseAI = class
        private type
          EnumDropFilter = (dfRanged, dfMelee, dfSupporter);
          SetDropFilter = set of EnumDropFilter;
        private const
          DROP_FILTER_ALL = [low(EnumDropFilter) .. high(EnumDropFilter)];
        protected
          // ghost gold does not produce wood on spending
          FCurrentGold, FCurrentGhostGold : integer;
          procedure SpentGold(GoldAmount : integer);
          procedure SpentWood(WoodAmount : integer);
          function GetCurrentGold : integer;
          property CurrentGold : integer read GetCurrentGold;
        public
          Parent : TPvPBotComponent;
          CurrentWood : integer;
          TotalWoodSpent : integer;
          BotSpawnerCount, BotDropCount : integer;
          NextDrop : TEnhancedCardInfo;
          NextSpawner : TEnhancedCardInfo;
          CurrentIncomeLevel : integer;
          WalkingDirectionBot : integer;
          AtlasSpawns : integer;
          constructor Create(Parent : TPvPBotComponent);
          // ------- helper -----------
          /// <summary> Return a random drop filtered against various filter options.
          /// <param name="AllowLegendary"> If True, drop can be a legendary card. Should be False if bot control already any legendary unit.</param>
          /// <param name="DropType"> If not dfAny, only drops of given type will be used for draw random drop.</param>
          /// <param name="DropStage"> If DropStage <> -1, returned drop tier will be DropStage.</param>
          /// </summary>
          function GetRandomFilteredDrop(AllowLegendary : boolean; DropType : SetDropFilter; DropStage : integer = -1) : TEnhancedCardInfo;
          function GetOptimalRandomDrop : TEnhancedCardInfo;
          function GetRandomSpawner : TEnhancedCardInfo;
          function GetCurrentIncome : integer; virtual;
          function GetCurrentGhostIncome : integer; virtual;
          function GetFrontmostTowerPosition : RVector2;
          /// <summary> Add random fuzziness to position by adding a random vector.</summary>
          function AddFuzzinessToPosition(const Position : RVector2) : RVector2;
          /// <summary> Returns True, when left is on lane near enemy nexus, then right, else false.</summary>
          function IsLeftBeforeRight(const Left, Right : RVector2) : boolean;
          /// <summary> Returns a list of all units bot owns before frontmost tower, so </summary>
          function GetBotUnitsBeforeFrontmostTower : TList<TEntity>;
          function GetBotUnitsBeforePosition(const Position : RVector2) : TList<TEntity>;
          /// <summary> Returns True if bot controls any legendary unit.</summary>
          function HasAnyLegendaryUnit : boolean;
          /// <summary> Returns the unit count normalized by SquadSize, e.g. 2 footmans will count as 0.5 instead of 2.</summary>
          function ComputeNormalizeUnitCount(Units : TList<TEntity>) : single;
          /// <summary> Compute and returns the most backline (unit nearest bot tower) unit positions.</summary>
          function ComputeBacklineUnitPosition(Units : TList<TEntity>) : RVector2;
          /// <summary> Returns the number of supporter units in list. </summary>
          function ComputeSupporterUnitCount(Units : TList<TEntity>) : integer;
          /// <summary> Returns the number of ranged units in list. </summary>
          function ComputeRangedUnitCount(Units : TList<TEntity>) : integer;
          /// <summary> Returns the number of melee units in list. </summary>
          function ComputeMeleeUnitCount(Units : TList<TEntity>) : integer;
          // ------- commands ------------------
          procedure PlaceSpawner;
          function PlaceDrop(Drop : TEnhancedCardInfo; DropPoint : RVector2) : boolean;
          // ------- published ------------------
          procedure Think; virtual;
          /// <summary> Called by parent whenever an entity is spawned on battlefield.</summary>
          procedure DoNewEntity(NewEntity : TEntity); virtual;
          procedure PrintDebug;
      end;

      TEasyAI = class(TBaseAI)
        private const
          INITIAL_GOLD = 150;
        public
          DelayTimer : TTimer;
          constructor Create(Parent : TPvPBotComponent);
          destructor Destroy; override;
          function GetCurrentIncome : integer; override;
          procedure Think; override;
          procedure DoNewEntity(NewEntity : TEntity); override;
      end;

      TEnhanceBaseAI = class(TBaseAI)
        public
          DropDelayTimer : TTimer;
          constructor Create(Parent : TPvPBotComponent);
          destructor Destroy; override;
      end;

      TEasyPlusAI = class(TEnhanceBaseAI)
        private const
          INITIAL_GOLD = 100;
          INITIAL_WOOD = 1600;
          DROP_DELAY   = 3000;
        public
          constructor Create(Parent : TPvPBotComponent);
          function GetCurrentIncome : integer; override;
          procedure Think; override;
      end;

      TMediumAI = class(TEnhanceBaseAI)
        private const
          INCOME_FACTOR = 0.8;
        public
          function GetCurrentIncome : integer; override;
          procedure Think; override;
      end;

      TVeryHardAI = class(TEnhanceBaseAI)
        public
          DropMode : boolean;
          function CurrentSaveThreshold : integer; virtual;
          procedure Think; override;
      end;

      THardAI = class(TVeryHardAI)
        private const
          INCOME_FACTOR = 0.7;
        public
          function CurrentSaveThreshold : integer; override;
          function GetCurrentIncome : integer; override;
      end;

      TInsaneAI = class(TVeryHardAI)
        private const
          // the first two waves should not be suspicious
          GHOST_GOLD_DELAY_AMOUNT  = -300;
          GHOST_GOLD_INCOME_FACTOR = 0.5;
        public
          constructor Create(Parent : TPvPBotComponent);
          function CurrentSaveThreshold : integer; override;
          function GetCurrentGhostIncome : integer; override;
      end;

    public type
      TScriptAI = class(TBaseAI)
        strict private
          FAIScript : TScript;
          FMinimumGoldCost : integer;
          FMinimumWoodCost : integer;
        private
        published
          // helper for analyse battlefield
          function GetCardByName(CardName : string) : TCommanderAbility;
          function GetUnitCountByName(UnitName : string) : integer;
          /// <summary> Get frontmost unit bot own where unit name match.
          /// If no unit exists, return nil.</summary>
          function GetFrontmostUnitByName(UnitName : string) : TEntity;
          function EnsurePositionIsInDropZone(Position : RVector2) : RVector2;
          // use cards methods
          procedure UseSpawnerCard(Card : TCommanderAbility);
          procedure UseDropCard(Card : TCommanderAbility; DropPoint : RVector2);
          procedure UseDropCardBehind(Card : TCommanderAbility; AUnit : TEntity; Distance : single);
          procedure UseSingleTargetSpell(Spell : TCommanderAbility; Target : TEntity);
          function IsTargetForSpellValid(Spell : TCommanderAbility; Target : TEntity) : boolean;
        public
          constructor Create(Parent : TPvPBotComponent; ScriptFileName : string);
          procedure Think; override;
          destructor Destroy; override;
      end;

    strict private
      FTeam1Numbers, FTeam2Numbers : RCurrentUnitStatistic;
      FBotAI : TBaseAI;
      function GetPlayerTeam : integer;
      function GetBotTeam : integer;
      function GetPlayerNumbers : RCurrentUnitStatistic;
      function GetNexusPosition(TeamID : integer) : RVector2;
    protected
      FDeck : TList<TCommanderAbility>;
      FCards : TUltimateObjectList<TEnhancedCardInfo>;
      FBuildID : integer;
      FFirst : boolean;
      FLeague : integer;
      FDifficulty : integer;
      /// <summary> Returns whether the build grid has free fields or not. </summary>
      function HasFreeSpawnerPoint : boolean;
      /// <summary> Returns a free spawning point from the used build grid. </summary>
      function RandomFreeSpawnerPoint : RIntVector2;
      /// <summary> Returns the current stage of the game. </summary>
      function CurrentStage : integer;
      /// <summary> Number of drops placed by the player. </summary>
      function PlayerDropCount : integer;
      /// <summary> Number of spawners placed by the player. </summary>
      function PlayerSpawnerCount : integer;
      /// <summary> Number of buildings placed by the player. </summary>
      function PlayerBuildingCount : integer;
      /// <summary> X coordinate is along lane. </summary>
      function NexusPositionPlayer : RVector2;
      /// <summary> X coordinate is along lane. </summary>
      function NexusPositionBot : RVector2;
      /// <summary> X coordinate is along lane. </summary>
      function ClosestEnemyToNexus : RVector2;
      /// <summary> Closest spawn point to the players nexus. X coordinate is along lane. Returns Y always center of lane. </summary>
      function ClosestSpawnPoint : RVector2;
      /// <summary> Closest spawn point to the players nexus, which is not behind enemies. </summary>
      function ClosestValidSpawnPoint : RVector2;
      /// <summary> Default spawn point at bot nexus. </summary>
      function NexusBotSpawnPoint : RVector2;
      /// <summary> Between 0.0..1.0, 1.0 is at Player nexus, 0.0 at bot nexus. </summary>
      function ProgressPercentage : single;
      /// <summary> Direction of X coordinate. </summary>
      function WalkingDirectionPlayer : integer;
      /// <summary> Direction of X coordinate. </summary>
      function WalkingDirectionBot : integer;
      procedure DoGameTick;
      procedure InitCards;
    published
      [XEvent(eiNewEntity, epLast, etTrigger, esGlobal)]
      function OnNewEntity(NewEntityParam : RParam) : boolean;
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal)]
      /// <summary> Check on each game tick, whether something could be build or not. </summary>
      function OnGameTick() : boolean;
    public
      property Deck : TList<TCommanderAbility> read FDeck;
      property BuildID : integer read FBuildID;
      constructor Create(Owner : TEntity); override;
      function League(Value : integer) : TPvPBotComponent;
      function Difficulty(Value : integer) : TPvPBotComponent;
      destructor Destroy; override;
  end;

  TScriptAIInterface = class(TPvPBotComponent.TScriptAI)
  end;

  {$M-}
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([])}
  {$RTTI INHERIT}

  EnumScenarioAction = (saBuildOnGrid, saDrop, saEvent);

  /// <summary> A very simple AI for a commander, which builds and spawns units at certain timestamps. </summary>
  TScenarioComponent = class(TEntityComponent)
    protected
      type
      RScenarioAction = record
        GameTick : integer;
        Action : EnumScenarioAction;
        Filename : string;
        Target : ATarget;
      end;
    var
      FActions : TList<RScenarioAction>;
      FTeamID, FMirrorAxis : integer;
      FBuildgrids : TArray<byte>;
      function CheckFile(const Filename : string) : string;
    published
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal)]
      /// <summary> Check on each game tick, whether something could be build or not. </summary>
      function OnGameTick() : boolean;
    public
      constructor Create(Owner : TEntity); override;
      function SetTeam(TeamID : integer) : TScenarioComponent;
      function AddBuildgrid(GridID : integer) : TScenarioComponent;
      function AddSpawner(GameTick : integer; Filename : string; BuildGridID : TArray<byte>; BuildGridCoordinateX, BuildGridCoordinateY : integer) : TScenarioComponent; overload;
      function AddSpawner(GameTick : integer; Filename : string; BuildGridID : TArray<byte>; BuildGridCoordinate : RIntVector2) : TScenarioComponent; overload;
      function AddSpawnerAll(GameTick : integer; Filename : string; BuildGridCoordinateX, BuildGridCoordinateY : integer) : TScenarioComponent; overload;
      function AddSpawnerAll(GameTick : integer; Filename : string; BuildGridCoordinate : RIntVector2) : TScenarioComponent; overload;
      function MirrorDrops(Axis : integer) : TScenarioComponent;
      function AddDrop(GameTick : integer; Filename : string; PosX, PosY : single) : TScenarioComponent;
      function AddEvent(GameTick : integer; Eventname : string) : TScenarioComponent;
      destructor Destroy; override;
  end;

  /// <summary> Enhanced AI for a commander, spawning units more planned.</summary>
  TScenarioDirectorComponent = class(TEntityComponent)
    {$REGION 'protected type'}
    protected type
      TUnit = class
        strict private
          FGoldCost : integer;
          FWoodCost : integer;
          FSquadSize : integer;
          FTypes : SetUnitTypes;
          FIdentifier : string;
          FDropFilename : string;
          FSpawnerFileName : string;
        public
          property DropFilename : string read FDropFilename;
          property SpawnerFileName : string read FSpawnerFileName;
          property Identifier : string read FIdentifier;
          property GoldCost : integer read FGoldCost;
          property WoodCost : integer read FWoodCost;
          property SquadSize : integer read FSquadSize;
          property Types : SetUnitTypes read FTypes;
          constructor Create(CardInfo : TCardInfo);
      end;

      TUnitSubset = class
        public type
          FuncFilterUnit = reference to function(AUnit : TUnit) : boolean;
        strict private
          FSubset : TUltimateList<TUnit>;
        public
          procedure AddUnits(Units : TList<TUnit>); overload;
          procedure AddUnits(Units : TArray<TUnit>); overload;
          procedure Clear;
          /// <summary> Return a random unit from UnitSubset that does match filter. If no unit was found,
          /// method will return nil. If Filter is nil, no filter will applied.</summary>
          function GetRandomUnit(Filter : FuncFilterUnit) : TUnit;

          constructor Create;
          destructor Destroy; override;
      end;

      /// <summary> A pattern for a bosswave.</summary>
      TBossWave = class
        strict private
          FFixedUnits : TArray<TUnit>;
          FDynamicUnits : TUnitSubset;
          FFixedGoldValue : integer;
          FIdentifier : string;
        public
          property Identifier : string read FIdentifier;
          /// <summary>Fixed goldvalue of the bosswave.</summary>
          property FixedGoldValue : integer read FFixedGoldValue;
          constructor Create(const Identifier : string; FixedUnits : TArray<TUnit>; DynamicUnits : TUnitSubset);
          function ComputeBossWave(DynamicGoldValue : integer) : TList<TUnit>;
          destructor Destroy; override;
      end;

      TAction = class abstract
        Parent : TScenarioDirectorComponent;
        GameTick : integer;
        procedure Execute; virtual; abstract;
        constructor Create(GameTick : integer; Parent : TScenarioDirectorComponent);
      end;

      /// <summary> Baseclass for all actions using a single integer value.</summary>
      TValueAction = class abstract(TAction)
        Value : integer;
        constructor Create(Value : integer; GameTick : integer; Parent : TScenarioDirectorComponent);
      end;

      TEventAction = class(TAction)
        Eventname : string;
        constructor Create(const Eventname : string; GameTick : integer; Parent : TScenarioDirectorComponent);
        procedure Execute; override;
      end;

      TSetGoldIncomeAction = class(TValueAction)
        procedure Execute; override;
      end;

      TSetGoldAction = class(TValueAction)
        procedure Execute; override;
      end;

      TSetWoodAction = class(TValueAction)
        procedure Execute; override;
      end;

      TSetWoodIncomeAction = class(TValueAction)
        procedure Execute; override;
      end;

      TChangeUnitSubset = class(TAction)
        Units : TArray<TUnit>;
        TargetSubset : TUnitSubset;
        OverwriteSubset : boolean;
        procedure Execute; override;
        constructor Create(Units : TArray<TUnit>; OverwriteSubset : boolean; TargetSubset : TUnitSubset;
          GameTick : integer; Parent : TScenarioDirectorComponent);
      end;

      TDropUnitsNowAction = class(TAction)
        procedure Execute; override;
      end;

      TSpawnBossWaveAction = class(TAction)
        DynamicGoldValue : integer;
        BossWave : TBossWave;
        constructor Create(BossWave : TBossWave; DynamicGoldValue : integer; GameTick : integer; Parent : TScenarioDirectorComponent);
        procedure Execute; override;
      end;

      TSpawnRandomBossWaveAction = class(TAction)
        GoldValue : integer;
        constructor Create(GoldValue : integer; GameTick : integer; Parent : TScenarioDirectorComponent);
        procedure Execute; override;
      end;

      TRegisterBossWaveAction = class(TAction)
        BossWave : TBossWave;
        constructor Create(BossWave : TBossWave; GameTick : integer; Parent : TScenarioDirectorComponent);
        procedure Execute; override;
        destructor Destroy; override;
      end;

      TUnregisterBossWaveAction = class(TAction)
        BossWaveIdentifier : string;
        constructor Create(const Identifier : string; GameTick : integer; Parent : TScenarioDirectorComponent);
        procedure Execute; override;
      end;

      TKIPlayer = class
        Buildgrid : byte;
        SpawnPoint : RVector2;

        // amount of gold that will saved to spawn units, after spawning units, new value will roled
        NextGoldSave : integer;
        // current gold the director has to spawn units
        Gold : integer;
        // wood variables
        NextSpawner : TUnit;
        // current wood the director has to spawn units
        Wood : integer;
        SpawnerCount : integer;
        Director : TScenarioDirectorComponent;
        constructor Create(Director : TScenarioDirectorComponent; Buildgrid : byte; SpawnPoint : RVector2);
        procedure DoThink;
        procedure SpawnSpawner;
        /// <summary> Use all current available gold to spawn units.</summary>
        procedure DropUnits;
        function GetNextSpawnerPosition : RIntVector2;
      end;

      EnumSquadRow = (srFront, srOffTank, srRanged, srArtillery);
      {$ENDREGION}
    protected
      // all spawned units/buildings will have this team id
      FTeamID : integer;
      FLeague : integer;
      // current income for director gold/sec
      FGoldIncome : integer;
      // current income for director wood/sec
      FWoodIncome : integer;

      FActions : TObjectList<TAction>;
      FMirroringEnabled : boolean;

      // all available units for director
      FUnitPool : TUltimateObjectList<TUnit>;
      FDropUnitSubset : TUnitSubset;
      FSpawnerUnitSubset : TUnitSubset;
      FBossWavePool : TUltimateObjectList<TBossWave>;
      FKIPlayers : TObjectList<TKIPlayer>;

      // Debug
      FLastUnitsSpawned : TList<TUnit>;

      function GetUnitsByIdentifier(UnitSubsetIdentifiers : TArray<string>) : TArray<TUnit>;
      procedure SpawnUnits(Units : TList<TUnit>; const Position : RVector2; WithOverwatch : boolean = False);
      /// <summary> Return the next boss wave that will spawn, nil if no boss wave found.</summary>
      function GetNextBossWaveAction : TSpawnRandomBossWaveAction;

      // Mainmethods
      /// <summary> Will execute all action where gametick >= action.gametick.</summary>
      procedure ProcessActions(GameTick : integer);
      procedure DoGameTick; virtual;

      procedure PrintDebug(GameTick : integer); virtual;
    protected const
      SQUAD_ROW_DISTANCE = 3;
      SQUAD_UNIT_SPACE   = 3;
    published
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal)]
      /// <summary> Check on each game tick, whether something could be build or not. </summary>
      function OnGameTick() : boolean;
    public
      constructor Create(Owner : TEntity); override;

      // --------------------- setup methods -----------------------------------
      function SetTeam(TeamID : integer) : TScenarioDirectorComponent;
      function SetLeague(League : integer) : TScenarioDirectorComponent;
      /// <summary> Set default spawnpoint for drops. Units will spawned around the point.</summary>
      function AddKIPlayer(GridID : integer; PosX, PosY : integer) : TScenarioDirectorComponent;
      /// <summary> Will setup the factions where units will choosed from. Will build the unit pool
      /// where the units are selected from. So it's important that this method is called once before director is used.</summary>
      function ChooseUnitFaction(UnitFaction : EnumEntityColor) : TScenarioDirectorComponent;
      /// <summary> Register a bosswave template by set fixed and dynamic units. Template can later spawned by using SpawnBossWave
      /// or SpawnRandomBossWave.</summary>
      function RegisterBossWave(Identifier : string; FixedUnits : TArray<string>; DynamicUnits : TArray<string>) : TScenarioDirectorComponent;
      /// <summary> Enable mirroring. When mirroring is enabled, all units/buildings spawned, will also spawned
      /// on the other lane.</summary>
      function EnableMirroring : TScenarioDirectorComponent;
      function DisableMirroring : TScenarioDirectorComponent;
      /// <summary> Spawn a guards at given position. Guards are units that spawned with overwatch.
      /// GoldValue is for all guards, so goldvalue will fir</summary>
      function SpawnGuards(PosX, PosY : integer; FixedUnits : TArray<string>; DynamicUnits : TArray<string>; GoldValue : integer) : TScenarioDirectorComponent;
      function SpawnUnit(PositionX, PositionY : single; PatternFileName : string) : TScenarioDirectorComponent;
      function SpawnUnitWithoutLimitedLifetime(PositionX, PositionY : single; PatternFileName : string) : TScenarioDirectorComponent; overload;
      function SpawnUnitWithoutLimitedLifetime(PositionX, PositionY : single; PatternFileName : string; out SpawnedEntity : TEntity) : TScenarioDirectorComponent; overload;
      function SpawnUnitWithoutLimitedLifetimeAndReturnEntity(PositionX, PositionY : single; PatternFileName : string) : TEntity;
      function SpawnUnitWithoutLimitedLifetimeWithFront(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string) : TScenarioDirectorComponent; overload;
      // --------------------- actions methods ---------------------------------
      // time binded setup methods
      function RegisterBossWaveAtTime(GameTick : integer; Identifier : string; FixedUnits : TArray<string>; DynamicUnits : TArray<string>) : TScenarioDirectorComponent;
      function UnregisterBossWaveAtTime(GameTick : integer; Identifier : string) : TScenarioDirectorComponent;
      // gold methods
      function ChangeGold(GameTick : integer; Gold : integer) : TScenarioDirectorComponent;
      function ChangeGoldIncome(GameTick : integer; GoldIncome : integer) : TScenarioDirectorComponent;
      // wood methods
      function ChangeWoodIncome(GameTick : integer; WoodIncome : integer) : TScenarioDirectorComponent;
      function ChangeWood(GameTick : integer; Wood : integer) : TScenarioDirectorComponent;
      // unit methods
      function ChangeUnitDropSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
      function AddUnitsToDropSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
      function ChangeUnitSpawnerSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
      function AddUnitsToSpawnerSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
      function SpawnBossWave(GameTick : integer; Identifier : string; DynamicGoldValue : integer) : TScenarioDirectorComponent;
      function SpawnRandomBossWave(GameTick : integer; GoldValue : integer) : TScenarioDirectorComponent;
      /// <summary> Using all gold currently available to drop units.</summary>
      function DropUnitsNow(GameTick : integer) : TScenarioDirectorComponent;
      // other
      function AddEvent(GameTick : integer; Eventname : string) : TScenarioDirectorComponent;
      destructor Destroy; override;
  end;

  TSurvivalScenarioDirectorComponent = class(TScenarioDirectorComponent)
    protected
      FTotalGoldRemaining, FTotalGoldSpent : integer;
      FAdditionalGoldIncome : integer;
      FCurrentThreat : single;
      FMaxThreatDistance : integer;
      FMaxThreatMultiplier : single;
      procedure ComputeThreat;
      procedure DoGameTick; override;

      procedure PrintDebug(GameTick : integer); override;
    protected const
      THREAT_MAX_CHECK_RANGE = 72;
      THREAT_CHECK_DISTANCE  = 10;
    public
      constructor Create(Owner : TEntity); override;
      // --------------------- setup methods -----------------------------------
      function SetTotalGoldRemaining(Value : integer) : TSurvivalScenarioDirectorComponent;
      /// <summary> Sets the distance from spawn point where threat is detected.</summary>
      function SetMaxThreatDistance(Value : integer) : TSurvivalScenarioDirectorComponent;
      function SetMaxThreatMultiplier(Value : single) : TSurvivalScenarioDirectorComponent;
  end;

implementation

uses
  BaseConflict.EntityComponents.Server.Welas,
  BaseConflict.Globals.Server;

{ TServerPrimaryTargetComponent }

function TServerPrimaryTargetComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
var
  i : integer;
begin
  Result := False;
  // have to be triggered manually as after eiLose the game is shut down
  for i := 0 to ServerGame.Commanders.Count - 1 do
    if Owner.HasUnitProperty(upBase) and (ServerGame.Commanders[i].TeamID <> Owner.TeamID) and ServerGame.Commanders[i].HasUnitProperty(upHasEchoesOfTheFuture) then
    begin
      ServerGame.Statistics.WelaKills(ServerGame.Commanders[i].ID, 'basebuildingwhileeotfactive', 1);
    end;
  // finish
  GlobalEventbus.Trigger(eiLose, [Owner.TeamID]);
end;

{ TServerNetworkComponent }

function TServerNetworkComponent.ConnectedPlayerCount : integer;
var
  Player : TNetworkPlayer;
begin
  Result := 0;
  for Player in FPlayers do
    if Player.IsConnected then
        inc(Result);
end;

constructor TServerNetworkComponent.Create(Owner : TEntity; GameInformation : TServerGameInformation);
var
  PlayerData : TGamePlayer;
begin
  inherited Create(Owner);
  FConnectedClients := TObjectList<TTCPClientSocketDeluxe>.Create;
  FPlayers := TObjectList<TNetworkPlayer>.Create;
  // hold data for every player that should connect to server
  // but skip bots as bots will never connect to game server as they are emulated by gameserver themself
  for PlayerData in GameInformation.Player.Values do
    if not PlayerData.IsBot then
        FPlayers.Add(TNetworkPlayer.Create(PlayerData.Token, PlayerData.PlayerID, PlayerData.TeamID, self));
  FTCPServerSocket := TTCPServerSocket.Create(GameInformation.GamePort);
  FTCPServerSocket.OnNewTCPClient := OnClientConnect;
end;

destructor TServerNetworkComponent.Destroy;
begin
  FTCPServerSocket.Free;
  FPlayers.Free;
  FConnectedClients.Free;
  inherited;
end;

procedure TServerNetworkComponent.DisconnectAllPlayers;
var
  Player : TNetworkPlayer;
begin
  for Player in FPlayers do
  begin
    Player.Disconnect;
  end;
end;

function TServerNetworkComponent.GetPlayerByToken(const Token : string) : TNetworkPlayer;
var
  Player : TNetworkPlayer;
begin
  Result := nil;
  if Token <> SPECTATOR_TOKEN then
  begin
    for Player in FPlayers do
    begin
      if Player.Token = Token then
          Exit(Player);
    end;
  end
  else
  // create new player specator or reuse disconnected spectator
  begin
    for Player in FPlayers do
    begin
      if (Player.Token = Token) and Player.IsDisconnected then
          Exit(Player);
    end;
    // accept new spectator only if not all slots already in use
    if (FPlayers.Count <= MAX_CLIENTS) then
    begin
      // TODO Set Player and TeamID for spectator
      Result := TNetworkPlayer.Create(Token, 0, 0, self);
      FPlayers.Add(Result);
    end
    else Result := nil;
  end;
end;

function TServerNetworkComponent.GetPort : Word;
begin
  Result := FTCPServerSocket.Port;
end;

procedure TServerNetworkComponent.OnClientConnect(ClientSocket : TSocket; InetAddress : RInetAddress);
begin
  FConnectedClients.Add(TTCPClientSocketDeluxe.Create(ClientSocket, InetAddress));
end;

function TServerNetworkComponent.OnSurrender(TeamID : RParam) : boolean;
var
  i : integer;
begin
  Result := True;
  for i := 0 to FPlayers.Count - 1 do
    if (FPlayers[i].TeamID = TeamID.AsInteger) and (FPlayers[i].QuitReason in [qrNone, qrNormal]) then
        FPlayers[i].QuitReason := qrSurrendered;
end;

function TServerNetworkComponent.AllPlayersInStatePlaying : boolean;
var
  i : integer;
begin
  Result := True;
  for i := 0 to FPlayers.Count - 1 do
    if (FPlayers[i].State <> psPlaying) and not FPlayers[i].IsSpectator then
        Exit(False);
end;

function TServerNetworkComponent.AllPlayersConnected : boolean;
var
  i : integer;
begin
  Result := True;
  for i := 0 to FPlayers.Count - 1 do
    if not FPlayers[i].IsConnected and not FPlayers[i].IsSpectator then
        Exit(False);
end;

function TServerNetworkComponent.AllPlayersDisconnected : boolean;
var
  i : integer;
begin
  Result := True;
  for i := 0 to FPlayers.Count - 1 do
    if not FPlayers[i].IsDisconnected and not FPlayers[i].IsSpectator then
        Exit(False);
end;

function TServerNetworkComponent.AnyPlayerDisconnected : boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to FPlayers.Count - 1 do
    if FPlayers[i].IsDisconnected and not FPlayers[i].IsSpectator then
        Exit(True);
end;

procedure TServerNetworkComponent.BuildStatistics(var Statistics : RGameFinishedStatistics);
var
  i : integer;
begin
  setLength(Statistics.player_statistics, FPlayers.Count);
  for i := 0 to FPlayers.Count - 1 do
    if not FPlayers[i].IsSpectator then
    begin
      Statistics.player_statistics[i].player_id := FPlayers[i].PlayerID;
      Statistics.player_statistics[i].player_state := ord(FPlayers[i].QuitReason);
    end;
end;

function TServerNetworkComponent.OnIdle : boolean;
var
  i : integer;
  Datapacket : TDatapacket;
  Player : TNetworkPlayer;
  Socket : TTCPClientSocketDeluxe;
  Deleted : boolean;
begin
  Result := True;
  for i := FConnectedClients.Count - 1 downto 0 do
  begin
    Socket := FConnectedClients[i];
    if Socket.IsDisconnected then
        FConnectedClients.Delete(i)
    else
    begin
      while Socket.IsDataPacketAvailable do
      begin
        Datapacket := Socket.ReceiveDataPacket;
        Deleted := ProcessNewData(Datapacket, Socket);
        Datapacket.Free;
        if Deleted then
            break;
      end;
    end;
  end;
  for Player in FPlayers do
  begin
    Player.Idle;
  end;
end;

function TServerNetworkComponent.ProcessNewData(Data : TDatapacket; Sender : TTCPClientSocketDeluxe) : boolean;
var
  Token : string;
  Player : TNetworkPlayer;
  LastReceivedDataIndex : integer;
  Sequence : TCommandSequence;
begin
  Result := False;
  case Data.Command of
    NET_HELLO_SERVER :
      begin
        Token := Data.ReadString;
        Player := GetPlayerByToken(Token);
        // refuse too much spectators
        if not assigned(Player) and (Token = SPECTATOR_TOKEN) then
            RefuseConnection(Sender, Token, 408)
        else if assigned(Player) and (Player.State = psNone) then
            Player.AssignSocket(Sender)
        else
            RefuseConnection(Sender, Token, 409);
        FConnectedClients.Extract(Sender);
      end;
    NET_RECONNECT :
      begin
        Token := Data.ReadString;
        LastReceivedDataIndex := Data.Read<integer>;
        Player := GetPlayerByToken(Token);
        if assigned(Player) then
        begin
          if Player.TryReconnect(Sender, LastReceivedDataIndex) then
              FConnectedClients.Extract(Sender)
          else
          begin
            FConnectedClients.Remove(Sender);
            Result := True;
          end;
        end
        else
        begin
          Sequence := TCommandSequence.Create(NET_RECONNECT_RESULT);
          Sequence.AddData<boolean>(False);
          Sequence.AddData(Format('No player matching token "%s" found', [Token]));
          // fake piggybacked last sended index
          Sequence.AddData<integer>(-1);
          Sender.SendData(Sequence);
          Sequence.Free;
          Sender.CloseConnection;
        end;
      end;
  else
    begin
      AccountAPI.SendCustomBugReport(Format('Server unexpected unknown command "%d". Datapacket: %s', [Data.Command, Data.AsBase64EncodedString]), '').Free;
      Sender.CloseConnection;
    end;
  end;
end;

procedure TServerNetworkComponent.RefuseConnection(Connection : TTCPClientSocketDeluxe; Token : string; ErrorCode : integer);
var
  SendData : TCommandSequence;
  ErrorMessage : string;
begin
  SendData := TCommandSequence.Create(NET_SECURITY_ERROR);
  SendData.AddData<integer>(ErrorCode);
  case ErrorCode of
    400 : ErrorMessage := 'Wrong token mapping';
    408 : ErrorMessage := 'Too much spectators';
    409 : ErrorMessage := 'Token already in use';
  end;
  SendData.AddData(ErrorMessage + ' Token: ' + Token);
  Connection.SendData(SendData);
  SendData.Free;
  Connection.CloseConnection;
end;

function TServerNetworkComponent.OnSendEntities(Entities : RParam) : boolean;
begin
  Result := True;
  SendEntities(Entities.AsType < TList < TEntity >> );
end;

function TServerNetworkComponent.OnServerShutdown : boolean;
var
  Timer : TTimer;
begin
  Result := True;
  Timer := TTimer.CreateAndStart(MAX_SEND_TIME_BEFORE_SHUTDOWN);
  // try to flush sendbuffers before shutdown server
  while not Timer.Expired and not AllPlayersDisconnected do
  begin
    sleep(250);
  end;
  Timer.Free;
end;

procedure TServerNetworkComponent.Send(Data : TCommandSequence);
var
  i : integer;
begin
  for i := 0 to FPlayers.Count - 1 do
  begin
    FPlayers[i].SendData(Data);
  end;
end;

procedure TServerNetworkComponent.SendAbort;
var
  SendData : TCommandSequence;
begin
  SendData := TCommandSequence.Create(NET_SERVER_GAME_ABORTED);
  Send(SendData);
  SendData.Free;
end;

procedure TServerNetworkComponent.SendDirectly(Data : TCommandSequence; Player : TNetworkPlayer);
begin
  if not assigned(Player) then
      Send(Data)
  else
      Player.SendData(Data);
end;

procedure TServerNetworkComponent.SendEntities(Entities : TList<TEntity>; Receiver : TNetworkPlayer);
var
  SendData : TCommandSequence;
  StreamList : TObjectList<TStream>;
  Stream : TStream;
  EntityCount, i : integer;
  DataSize : Cardinal;
  Entity : TEntity;
begin
  StreamList := TObjectList<TStream>.Create(True);
  assert(assigned(Entities));
  assert(Entities.Count >= 1);
  // prepare entity add
  EntityCount := 0;
  DataSize := 0;
  Stream := TMemoryStream.Create;
  for Entity in Entities do
  begin
    Entity.Serialize(Stream);
    assert(Stream.Size < MAX_PACKET_SIZE);
    // avoide packets > MAXPACKETSIZE -> send packet before add data
    if (DataSize + Stream.Size) > MAX_PACKET_SIZE then
    begin
      SendData := TCommandSequence.Create(NET_NEW_ENTITY);
      SendData.AddData<integer>(EntityCount);
      for i := 0 to StreamList.Count - 1 do
      begin
        SendData.AddStream(StreamList[i]);
      end;
      SendDirectly(SendData, Receiver);
      SendData.Free;
      StreamList.Clear;
      DataSize := 0;
      EntityCount := 0;
    end;
    // add stream and adjust counting data
    Stream.Position := 0;
    StreamList.Add(Stream);
    inc(EntityCount);
    DataSize := DataSize + Stream.Size;
    // new stream ready for new data
    Stream := TMemoryStream.Create;
  end;
  // finally send data from not full packet
  SendData := TCommandSequence.Create(NET_NEW_ENTITY);
  SendData.AddData<integer>(EntityCount);
  for i := 0 to StreamList.Count - 1 do
  begin
    SendData.AddStream(StreamList[i]);
  end;
  SendDirectly(SendData, Receiver);
  SendData.Free;
  Stream.Free;
  StreamList.Free;
end;

procedure TServerNetworkComponent.SendEntities(Entities : TList<TEntity>);
begin
  SendEntities(Entities, nil);
end;

procedure TServerNetworkComponent.SendWorld(Player : TNetworkPlayer);
var
  SendData : TCommandSequence;
  EntityList, FilteredEntities : TList<TEntity>;
begin
  // send world
  EntityList := Game.EntityManager.GetDeployedEntityList;
  FilteredEntities := TAdvancedList<TEntity>(EntityList).Filter(
    function(Entity : TEntity) : boolean
    begin
      Result := Entity.ScriptFile <> '';
    end);
  SendEntities(FilteredEntities, Player);
  EntityList.Free;
  FilteredEntities.Free;

  SendData := TCommandSequence.Create(NET_SERVER_FINISHED_SEND_GAME_DATA);
  Player.SendData(SendData);
  SendData.Free;
end;

{ TTokenMappingComponent }

constructor TTokenMappingComponent.Create(Owner : TEntity; TokenMapping : TObjectDictionary < string, TList < integer >> );
begin
  inherited Create(Owner);
  FTokenMapping := TokenMapping;
end;

destructor TTokenMappingComponent.Destroy;
begin
  FTokenMapping.Free;
  inherited;
end;

function TTokenMappingComponent.OnTokenMapping(Token : RParam) : RParam;
var
  ResultValue : TList<integer>;
begin
  // not found return nil
  if FTokenMapping.TryGetValue(Token.AsString, ResultValue) then
      ResultValue := TList<integer>.Create(ResultValue)
  else
      ResultValue := nil;
  Result := ResultValue;
end;

{ TLinkBrainComponent }

constructor TLinkBrainComponent.Create(Owner : TEntity);
begin
  CreateGrouped(Owner, []);
end;

constructor TLinkBrainComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FTimer := TTimer.Create(0);
end;

destructor TLinkBrainComponent.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TLinkBrainComponent.FetchCooldown;
begin
  FTimer.Interval := Eventbus.Read(eiCooldown, [], ComponentGroup).AsInteger;
end;

function TLinkBrainComponent.FiresAtCreate(Group : TArray<byte>) : TLinkBrainComponent;
begin
  Result := self;
  FFiresAtCreate := True;
  FFiresAtCreateGroup := ByteArrayToComponentGroup(Group);
end;

function TLinkBrainComponent.FiresAtSources(Group : TArray<byte>) : TLinkBrainComponent;
begin
  Result := self;
  FFiresAtSources := True;
  FSourceTargetGroup := ByteArrayToComponentGroup(Group);
end;

function TLinkBrainComponent.OnIdle : boolean;
var
  Targets : ATarget;
  fireTimes, i : integer;
begin
  Result := True;
  if FTimer.Interval <= 1 then
  begin
    FetchCooldown;
    FTimer.Start;
    if FFiresAtCreate and
      Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
      Eventbus.Read(eiIsReady, [], FFiresAtCreateGroup).AsBooleanDefaultTrue then
    begin
      Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
      if Eventbus.Read(eiWelaTargetPossible, [Targets.ToRParam], FFiresAtCreateGroup).AsRTargetValidity.IsValid then
          Eventbus.Trigger(eiFire, [Targets.ToRParam], FFiresAtCreateGroup);
    end;
  end
  else
    if FTimer.Expired then
  begin
    Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
    if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
    begin
      // compute the times the brain has to fire, for lag safety at max 50 times
      fireTimes := FTimer.TimesExpired(50);
      FTimer.StartWithFrac;
      if Eventbus.Read(eiWelaTargetPossible, [Targets.ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
        for i := 0 to fireTimes - 1 do
            Eventbus.Trigger(eiFire, [Targets.ToRParam], ComponentGroup);
      if FFiresAtSources then
      begin
        Targets := Eventbus.Read(eiLinkSource, []).AsATarget;
        if Eventbus.Read(eiWelaTargetPossible, [Targets.ToRParam], FSourceTargetGroup).AsRTargetValidity.IsValid then
          for i := 0 to fireTimes - 1 do
              Eventbus.Trigger(eiFire, [Targets.ToRParam], FSourceTargetGroup);
      end;
    end;
    FTimer.StartWithFrac;
    FetchCooldown;
  end;
end;

{ TServerCollisionManagerComponent }

function TServerCollisionManagerComponent.OnEnemiesInRangeOf(Position : RParam; Range : RParam; SourceTeamID, TargetTeamConstraint : RParam; Filter : RParam) : RParam;
var
  Efficiency : single;
  i : integer;
  e : TEntity;
  nearby : TList<TEntityLooseQuadtreeData>;
  FilterFunc : ProcFilterFunction;
  EntitiesFound : TList<RTargetWithEfficiency>;
begin
  nearby := FQuadTree.GetIntersections(RCircle.Create(Position.AsVector2, Range.AsSingle),
    SourceTeamID.AsInteger, TargetTeamConstraint.AsType<EnumTargetTeamConstraint>);

  if not Filter.IsEmpty then FilterFunc := Filter.AsProc<ProcFilterFunction>()
  else FilterFunc := nil;

  EntitiesFound := TList<RTargetWithEfficiency>.Create();

  for i := 0 to nearby.Count - 1 do
  begin
    e := nearby[i].Data;
    if assigned(FilterFunc) then Efficiency := FilterFunc(e)
    else Efficiency := 1;
    if (Efficiency >= 0) then
        EntitiesFound.Add(RTargetWithEfficiency.Create(RTarget.Create(e), Efficiency));
  end;

  //

  if EntitiesFound.Count = 0 then FreeAndNil(EntitiesFound);

  nearby.Free;

  Result := EntitiesFound;
end;

{ TServerNetworkComponent.TNetworkPlayer }

procedure TServerNetworkComponent.TNetworkPlayer.AssignSocket(Socket : TTCPClientSocketDeluxe);
var
  CommanderList : TList<integer>;
  SendData : TCommandSequence;
begin
  // if socket already assigned, other player already used token
  assert(not assigned(FSocket));
  CommanderList := FNetworkComponent.GlobalEventbus.Read(eiTokenMapping, [Token]).AsType<TList<integer>>;
  if assigned(CommanderList) then
  begin
    FSocket := Socket;
    FQuitReason := qrNormal;
    FState := psPreparing;
    // send mappings
    SendData := TCommandSequence.Create(NET_ASSIGNED_PLAYER);
    SendData.AddDataArray<integer>(CommanderList.ToArray);
    self.SendData(SendData);
    SendData.Free;
    CommanderList.Free;
  end
  else
      FNetworkComponent.RefuseConnection(Socket, Token);
end;

constructor TServerNetworkComponent.TNetworkPlayer.Create(const Token : string; PlayerID : integer; TeamID : integer; NetworkComponent : TServerNetworkComponent);
begin
  FSendedData := TObjectRingBuffer<TSendedData>.Create(20000);
  FReconnectTimer := TTimer.Create(RECONNECT_TIME);
  FNetworkComponent := NetworkComponent;
  FToken := Token;
  FPlayerID := PlayerID;
  FTeamID := TeamID;
end;

destructor TServerNetworkComponent.TNetworkPlayer.Destroy;
begin
  FSocket.Free;
  FSendedData.Free;
  FReconnectTimer.Free;
  inherited;
end;

procedure TServerNetworkComponent.TNetworkPlayer.Disconnect;
begin
  if assigned(FSocket) then
      FSocket.CloseConnection;
  State := psDisconnected;
end;

procedure TServerNetworkComponent.TNetworkPlayer.Idle;
var
  Datapacket : TDatapacket;
begin
  while assigned(FSocket) and FSocket.IsDataPacketAvailable do
  begin
    Datapacket := FSocket.ReceiveDataPacket;
    ProcessNewData(Datapacket);
    Datapacket.Free;
  end;
  // update player connection state
  if assigned(FSocket) and FSocket.IsDisconnected and (State in [psNone, psPreparing, psPlaying]) then
  begin
    // try to reconnect if player lost connection -> reconnect state
    if FNetworkComponent.AllowReconnect then
    begin
      FReconnectTimer.Start;
      State := psReconnecting;
    end
    else
    begin
      // connection is permanently lost, can not be recovered
      State := psDisconnected;
      QuitReason := qrDisconnectedWhilePreparing;
    end;
  end
  else if (State = psReconnecting) and FReconnectTimer.Expired then
  begin
    // reconnect failed -> connection is permanently lost, can not be recovered
    State := psDisconnected;
    QuitReason := qrDisconnectedWhilePlaying;
  end;
end;

function TServerNetworkComponent.TNetworkPlayer.IsConnected : boolean;
begin
  Result := State in [psPreparing, psPlaying, psReconnecting];
end;

function TServerNetworkComponent.TNetworkPlayer.IsDisconnected : boolean;
begin
  Result := State = psDisconnected;
end;

function TServerNetworkComponent.TNetworkPlayer.IsSpectator : boolean;
begin
  Result := Token = TServerNetworkComponent.SPECTATOR_TOKEN;
end;

procedure TServerNetworkComponent.TNetworkPlayer.ProcessNewData(Data : TDatapacket);
begin
  case Data.Command of
    NET_CLIENT_ENTER_CORE :
      begin
        FNetworkComponent.SendWorld(self);
      end;
    NET_CLIENT_READY :
      begin
        State := psPlaying;
      end;
    NET_EVENT :
      begin
        // spectators must not send anything game relevant
        if not IsSpectator then
            FNetworkComponent.NewData(Data);
      end;
    NET_CLIENT_RAGE_QUIT :
      begin
        State := psDisconnected;
        QuitReason := qrRageQuit;
      end;
  else
    begin
      AccountAPI.SendCustomBugReport(Format('Server retrieved unknown command "%d". Datapacket: %s', [Data.Command, Data.AsBase64EncodedString]), '').Free;
    end;
  end;
end;

procedure TServerNetworkComponent.TNetworkPlayer.ResendData(LastReceivedIndex : integer);
var
  i : integer;
begin
  if FSocket.IsConnected then
  begin
    // player hasn't received any packet that exists after index
    i := LastReceivedIndex + 1;
    while FSendedData.IsIndexSet(i) do
    begin
      FSocket.SendData(FSendedData.Items[i].Data);
      inc(i);
    end;
  end;
end;

procedure TServerNetworkComponent.TNetworkPlayer.SendData(Data : TCommandSequence);
begin
  // Piggyback current sended data index
  Data.AddData<integer>(FSendedData.LastIndex + 1);
  FSendedData.Append(TSendedData.Create(Data.GetCopy));
  if assigned(FSocket) then
      FSocket.SendData(Data);
end;

function TServerNetworkComponent.TNetworkPlayer.TryReconnect(NewSocket : TTCPClientSocketDeluxe; LastReceivedDataIndex : integer) : boolean;
var
  Sequence : TCommandSequence;
  FailReason : string;
begin
  if FSendedData.IsIndexSet(LastReceivedDataIndex)
    and (Gettickcount - FSendedData.Items[LastReceivedDataIndex].Timestamp < RECONNECT_TIME) then
  begin
    // the old socket might be still active due to longer timeouts than the clients reconnect, so it may be not already detected that
    // the client is gone here
    // assert(State = psReconnecting);
    // all requirements are fulfilled, so migrate new connected client to old
    Sequence := TCommandSequence.Create(NET_RECONNECT_RESULT);
    Sequence.AddData<boolean>(True);
    FSocket.Free;
    FSocket := NewSocket;
    SendData(Sequence);
    Sequence.Free;
    ResendData(LastReceivedDataIndex);
    State := psPlaying;
    Result := True;
  end
  else
  // reconnecting failed
  begin
    FailReason := 'Don''t know';
    if not FSendedData.IsIndexSet(LastReceivedDataIndex) then
        FailReason := 'not Client.SendedData.IsIndexSet(LastReceivedDataIndex)'
    else if not(Gettickcount - FSendedData.Items[LastReceivedDataIndex].Timestamp < RECONNECT_TIME) then
        FailReason := 'not Gettickcount - Client.SendedData.Items[LastReceivedDataIndex].Timestamp < RECONNECTTIME';

    Sequence := TCommandSequence.Create(NET_RECONNECT_RESULT);
    Sequence.AddData<boolean>(False);
    Sequence.AddData(FailReason);
    // fake piggybacked last sended index
    Sequence.AddData<integer>(-1);
    NewSocket.SendData(Sequence);
    Sequence.Free;
    State := psDisconnected;
    QuitReason := qrDisconnectedWhilePlaying;
    Result := False;
  end;
end;

{ TServerEntityManagerComponent }

constructor TServerEntityManagerComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FEntitiesToKill := TList<integer>.Create;
end;

destructor TServerEntityManagerComponent.Destroy;
begin
  inherited;
  FEntitiesToKill.Free;
end;

function TServerEntityManagerComponent.OnDelayedKillEntity(EntityID : RParam) : boolean;
begin
  Result := True;
  FEntitiesToKill.Add(EntityID.AsInteger);
end;

procedure TServerEntityManagerComponent.Idle;
var
  i : integer;
begin
  inherited;
  for i := 0 to FEntitiesToKill.Count - 1 do
  begin
    GlobalEventbus.Trigger(eiKillEntity, [FEntitiesToKill[i]]);
  end;
  FEntitiesToKill.Clear;
end;

function TServerEntityManagerComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  ServerGame.TeamLost(TeamID.AsInteger);
end;

function TServerEntityManagerComponent.SpawnSpawner(BuildGridID : integer; BuildGridCoordinate : RIntVector2; PatternFileName : string; TeamID : integer; OwnerCommanderID : integer; Creator : TEntity; Callback : ProcSetUpEntity; CreateMethod : string) : TEntity;
begin
  Result := SpawnSpawner(BuildGridID, BuildGridCoordinate, PatternFileName, TeamID, OwnerCommanderID, Creator, Callback, nil, CreateMethod);
end;

function TServerEntityManagerComponent.SpawnSpawner(BuildGridID : integer; BuildGridCoordinate : RIntVector2; PatternFileName : string; TeamID, OwnerCommanderID : integer; Creator : TEntity; Callback, PreProcessing : ProcSetUpEntity; CreateMethod : string) : TEntity;
var
  BuildZone : TBuildZone;
  BuildTarget : RTarget;
  Position, Front : RVector2;
  NeededGridSize : RIntVector2;
  x, y, j : integer;
  BlockedFieldGrids : TArray<RTuple<integer, RIntVector2>>;
begin
  Result := nil;
  if Map.BuildZones.TryGetBuildZone(BuildGridID, BuildZone) then
  begin
    BuildTarget := RTarget.CreateBuildTarget(BuildGridID, BuildGridCoordinate);
    NeededGridSize := RIntVector2.Create(1, 1);
    Position := BuildTarget.GetRealBuildPosition(NeededGridSize);
    Front := BuildZone.Front;

    Result := SpawnUnit(
      Position,
      Front,
      PatternFileName,
      TServerEntityManagerComponent.INHERIT_FROM_GAME,
      TServerEntityManagerComponent.INHERIT_FROM_GAME,
      TeamID,
      OwnerCommanderID,
      Creator,
      procedure(SpawnedEntity : TEntity)
      begin
        if assigned(Callback) then Callback(SpawnedEntity);

        // save target buildgrid, must be in setup, as the spawner can spawn directly after create
        SpawnedEntity.Eventbus.Write(eiBuildgridOwner, [BuildZone.ID]);
      end,
      PreProcessing,
      nil,
      CreateMethod);

    // block gridfields
    setLength(BlockedFieldGrids, NeededGridSize.x * NeededGridSize.y);
    j := 0;
    for x := 0 to NeededGridSize.x - 1 do
      for y := 0 to NeededGridSize.y - 1 do
      begin
        // assume non overlapping buildgrids, look for buildgrid at target coordinate and block the field there
        Position := BuildZone.GetCenterOfField(BuildTarget.BuildGridCoordinate + RIntVector2.Create(x, y));
        BuildZone := Game.Map.BuildZones.GetBuildZoneByPosition(Position);
        if not assigned(BuildZone) then
            assert(assigned(BuildZone), 'TServerEntityManagerComponent.SpawnSpawner: Invalid buildcoordinate passed to Server!');
        if not assigned(BuildZone) then continue;
        BlockedFieldGrids[j].a := BuildZone.ID;
        BlockedFieldGrids[j].b := BuildZone.PositionToCoord(Position);
        GlobalEventbus.Write(eiSetGridFieldBlocking, [BlockedFieldGrids[j].a, BlockedFieldGrids[j].b, Result.ID]);
        inc(j);
      end;
    // save blocked gridfields, for refunding
    Result.Eventbus.Write(eiBuildgridBlockedFields, [RParam.FromArray < RTuple < integer, RIntVector2 >> (BlockedFieldGrids)]);
  end
  else assert(False, 'TServerEntityManagerComponent.SpawnSpawner: Invalid buildgrid id!');
end;

function TServerEntityManagerComponent.SpawnUnit(Position, Front : RVector2; PatternFileName : string; League, Level, TeamID, OwnerCommanderID : integer; Creator : TEntity; Callback : ProcSetUpEntity; PreProcessing, PostProcessing : ProcSetUpEntity; CreateMethod : string) : TEntity;
var
  Entity : TEntity;
  EntityList : TList<TEntity>;
begin
  if PatternFileName = '' then
      raise EInvalidArgument.CreateFmt('TServerEntityManagerComponent.SpawnUnit: Empty script pattern for creating entity created by unit "%s"', [Creator.ScriptFile]);

  if League = TServerEntityManagerComponent.INHERIT_FROM_GAME then League := Game.League;
  if Level = TServerEntityManagerComponent.INHERIT_FROM_GAME then Level := MAX_LEVEL;

  if assigned(ServerGame) and not PatternFileName.Contains(FILE_IDENTIFIER_SPAWNER) then
      Position := ServerGame.Map.ClampToZone(ZONE_WALK, Position);

  ServerGame.Statistics.UnitSpawned(OwnerCommanderID, PatternFileName);

  Entity := TEntity.CreateFromScript(
    PatternFileName,
    GlobalEventbus,
    procedure(Entity : TEntity)
    begin
      Entity.Eventbus.Write(eiTeamID, [TeamID]);
      Entity.Position := Position;
      Entity.Front := Front;
      if OwnerCommanderID >= 0 then Entity.Eventbus.Write(eiOwnerCommander, [OwnerCommanderID]);
      if assigned(Creator) then
      begin
        Entity.Eventbus.Write(eiCreator, [Creator.ID]);
        Entity.Eventbus.Write(eiCreatorScriptFileName, [Creator.ScriptFileName]);
      end;
      Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), League);
      Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), Level);
      if assigned(PreProcessing) then PreProcessing(Entity);
    end);
  Result := Entity;
  Entity.ID := Game.EntityManager.GenerateUniqueID;

  if assigned(Callback) then Callback(Entity);

  if Game.IsSandbox and Overwatch then
  begin
    if OverwatchClearable then
        TBrainOverwatchSandboxComponent.Create(Entity)
    else
        TBrainOverwatchComponent.Create(Entity);
  end;

  Entity.Eventbus.Trigger(eiAfterCreate, []);
  // send new entity to client
  EntityList := TList<TEntity>.Create;
  EntityList.Add(Entity);
  GlobalEventbus.Trigger(eiSendEntities, [EntityList]);
  EntityList.Free;
  // deploy after send, as the unit has to be on the client for triggered effects
  Entity.Deploy;

  if assigned(PostProcessing) then PostProcessing(Entity);
end;

function TServerEntityManagerComponent.SpawnUnitWithFront(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer) : TEntity;
begin
  Result := SpawnUnit(RVector2.Create(PositionX, PositionY), RVector2.Create(FrontX, FrontY), PatternFileName, TServerEntityManagerComponent.INHERIT_FROM_GAME, TServerEntityManagerComponent.INHERIT_FROM_GAME, TeamID, -1, nil, nil);
end;

function TServerEntityManagerComponent.SpawnUnitWithoutLimitedLifetime(PositionX, PositionY : single; PatternFileName : string; TeamID : integer) : TEntity;
begin
  Result := SpawnUnitWithoutLimitedLifetimeWithFront(PositionX, PositionY, -1, 0, PatternFileName, TeamID);
end;

function TServerEntityManagerComponent.SpawnUnitWithoutLimitedLifetimeWithFront(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer) : TEntity;
begin
  Result := SpawnUnit(RVector2.Create(PositionX, PositionY), RVector2.Create(FrontX, FrontY), PatternFileName, TServerEntityManagerComponent.INHERIT_FROM_GAME, TServerEntityManagerComponent.INHERIT_FROM_GAME, TeamID, -1, nil,
    procedure(Entity : TEntity)
    begin
      Entity.FreeGroups([GROUP_BUILDING_LIFETIME]);
    end);
end;

function TServerEntityManagerComponent.SpawnUnitWithOverwatch(Position, Front : RVector2; PatternFileName : string; TeamID : integer) : TEntity;
begin
  Result := SpawnUnit(Position, Front, PatternFileName, TServerEntityManagerComponent.INHERIT_FROM_GAME, TServerEntityManagerComponent.INHERIT_FROM_GAME, TeamID, -1, nil,
    procedure(Entity : TEntity)
    begin
      TBrainOverwatchComponent.Create(Entity);
    end);
end;

function TServerEntityManagerComponent.SpawnUnitWithOverwatchAndFlee(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer;
FleeDistance : single) : TEntity;
begin
  Result := SpawnUnitWithOverwatchAndFlee(RVector2.Create(PositionX, PositionY), RVector2.Create(FrontX, FrontY), PatternFileName, TeamID, FleeDistance);
end;

function TServerEntityManagerComponent.SpawnUnitWithOverwatchAndFlee(Position, Front : RVector2; PatternFileName : string; TeamID : integer;
FleeDistance : single) : TEntity;
begin
  Result := SpawnUnit(Position, Front, PatternFileName, TServerEntityManagerComponent.INHERIT_FROM_GAME, TServerEntityManagerComponent.INHERIT_FROM_GAME, TeamID, -1, nil,
    procedure(Entity : TEntity)
    begin
      TBrainOverwatchComponent.Create(Entity);
      TBrainFleeComponent.Create(Entity).Range(FleeDistance);
    end);
end;

function TServerEntityManagerComponent.SpawnUnitWithOverwatch(PositionX, PositionY, FrontX, FrontY : single; PatternFileName : string; TeamID : integer) : TEntity;
begin
  Result := SpawnUnitWithOverwatch(RVector2.Create(PositionX, PositionY), RVector2.Create(FrontX, FrontY), PatternFileName, TeamID);
end;

function TServerEntityManagerComponent.SpawnUnit(PositionX, PositionY : single; PatternFileName : string; TeamID : integer) : TEntity;
begin
  Result := SpawnUnit(RVector2.Create(PositionX, PositionY), RVector2.Create(0, 1), PatternFileName, TServerEntityManagerComponent.INHERIT_FROM_GAME, TServerEntityManagerComponent.INHERIT_FROM_GAME, TeamID, -1, nil, nil);
end;

function TServerEntityManagerComponent.SpawnUnit(Position, Front : RVector2; PatternFileName : string; League, Level, TeamID, OwnerCommanderID : integer; Creator : TEntity) : TEntity;
begin
  Result := SpawnUnit(Position, Front, PatternFileName, League, Level, TeamID, OwnerCommanderID, Creator, nil);
end;

function TServerEntityManagerComponent.SpawnUnit(Position, Front : RVector2; PatternFileName : string; League, Level, TeamID : integer) : TEntity;
begin
  Result := SpawnUnit(Position, Front, PatternFileName, League, Level, TeamID, -1, nil, nil);
end;

function TServerEntityManagerComponent.SpawnUnitRaw(PatternFileName : string; Callback : ProcSetUpEntity) : TEntity;
var
  Entity : TEntity;
  EntityList : TList<TEntity>;
begin
  Entity := TEntity.CreateFromScript(PatternFileName, GlobalEventbus);
  Result := Entity;
  Entity.ID := Game.EntityManager.GenerateUniqueID;
  Callback(Entity);
  Entity.Eventbus.Trigger(eiAfterCreate, []);
  // send new entity to client
  EntityList := TList<TEntity>.Create;
  EntityList.Add(Entity);
  GlobalEventbus.Trigger(eiSendEntities, [EntityList]);
  EntityList.Free;
  // deploy after send, as the unit has to be on the client for triggered effects
  Entity.Deploy;
end;

{ TBuffTakenDamageMultiplierComponent }

function TBuffTakenDamageMultiplierComponent.ApplyOnHeal : TBuffTakenDamageMultiplierComponent;
begin
  Result := self;
  FOnHeal := True;
end;

function TBuffTakenDamageMultiplierComponent.DamageTypeMustHave(DamageTypes : TArray<byte>) : TBuffTakenDamageMultiplierComponent;
begin
  Result := self;
  FDamageMustHave := ByteArrayToSetDamageType(DamageTypes);
end;

function TBuffTakenDamageMultiplierComponent.DamageTypeMustHaveAny(DamageTypes : TArray<byte>) : TBuffTakenDamageMultiplierComponent;
begin
  Result := self;
  FDamageMustHaveAny := ByteArrayToSetDamageType(DamageTypes);
end;

function TBuffTakenDamageMultiplierComponent.DamageTypeMustNotHave(DamageTypes : TArray<byte>) : TBuffTakenDamageMultiplierComponent;
begin
  Result := self;
  FDamageMustNotHave := ByteArrayToSetDamageType(DamageTypes);
end;

function TBuffTakenDamageMultiplierComponent.DodgeDamage : TBuffTakenDamageMultiplierComponent;
begin
  FDodge := True;
  Result := self;
end;

function TBuffTakenDamageMultiplierComponent.Flat : TBuffTakenDamageMultiplierComponent;
begin
  Result := self;
  FFlatValue := True;
end;

function TBuffTakenDamageMultiplierComponent.OnHeal(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
var
  sFactor : single;
  Factor : RParam;
  AttackType : SetDamageType;
begin
  if not FOnHeal then Exit(Previous);
  assert(not FDodge, 'TBuffTakenDamageMultiplierComponent.OnHeal: Dodged heal not implemented!');
  assert(not FReflect, 'TBuffTakenDamageMultiplierComponent.OnHeal: Reflected heal not implemented!');
  AttackType := DamageType.AsType<SetDamageType>;
  Factor := Eventbus.Read(eiWelaModifier, [], ComponentGroup);
  if not Factor.IsEmpty and
    ((FDamageMustHave <= AttackType) and
    ((FDamageMustHaveAny = []) or (FDamageMustHaveAny * AttackType <> [])) and
    ((FDamageMustNotHave = []) or (FDamageMustNotHave * AttackType = []))) then
  begin
    sFactor := Factor.AsSingle;
    Amount := Amount.AsSingle * sFactor;
  end;
  Result := Previous;
end;

function TBuffTakenDamageMultiplierComponent.OnTakeDamage(var Amount : RParam; DamageType : RParam; InflictorID, Previous : RParam) : RParam;
var
  sFactor, reflectedAmount : single;
  Factor : RParam;
  Inflictor : TEntity;
  AttackType : SetDamageType;
begin
  if FOnHeal then Exit(Previous);
  AttackType := DamageType.AsType<SetDamageType>;
  Factor := Eventbus.Read(eiWelaModifier, [], ComponentGroup);
  if not Factor.IsEmpty and
    ((FDamageMustHave <= AttackType) and
    ((FDamageMustHaveAny = []) or (FDamageMustHaveAny * AttackType <> [])) and
    ((FDamageMustNotHave = []) or (FDamageMustNotHave * AttackType = []))) then
  begin
    sFactor := Factor.AsSingle;
    // check whether damage should be dodged by chance, not reduced by factor
    if FDodge then
    begin
      if (random < sFactor) then
      begin
        sFactor := 0.0;
        // if dodged send eiFire to its owning group for following effects
        Eventbus.Trigger(eiFire, [ATarget.Create(FOwner).ToRParam], ComponentGroup);
      end
      else sFactor := 1.0;
    end;
    // if damage should be reflected, take the reduced amount and send it back to the inflictor
    // it will only be reflected if damage will be reduced and is not irredirectable (e.g. has been reflected before, prevent ping-pong)
    if FReflect and (FFlatValue or InRange(sFactor, 0.0, 1.0)) and not(dtIrredirectable in AttackType) and Game.EntityManager.TryGetEntityByID(InflictorID.AsInteger, Inflictor) then
    begin
      if FFlatValue then
          reflectedAmount := Max(1.0, Amount.AsSingle - sFactor)
      else
          reflectedAmount := Amount.AsSingle * (1 - sFactor);
      AttackType := AttackType + [dtIrredirectable];
      Inflictor.Eventbus.Read(eiTakeDamage, [reflectedAmount, RParam.From<SetDamageType>(AttackType), InflictorID]);
    end;
    if FFlatValue then
        Amount := Max(1.0, Amount.AsSingle - sFactor)
    else
        Amount := Amount.AsSingle * sFactor;
  end;
  Result := Previous;
end;

function TBuffTakenDamageMultiplierComponent.ReflectReducedDamage : TBuffTakenDamageMultiplierComponent;
begin
  FReflect := True;
  Result := self;
end;

{ TBuffLifeLeechComponent }

function TBuffLifeLeechComponent.OnDoneDamage(Amount, DamageType, TargetEntity : RParam) : boolean;
var
  rFactor : RParam;
  Factor : single;
begin
  Result := True;
  rFactor := Eventbus.Read(eiWeladamage, [], ComponentGroup);
  if rFactor.IsEmpty then Factor := 1.0
  else Factor := rFactor.AsSingle;
  Eventbus.Read(eiHeal, [
    Amount.AsSingle * Factor,
    RParam.From<SetDamageType>([]),
    Owner.ID]);
end;

{ TBuffDamageMultiplierComponent }

procedure TBuffDamageMultiplierComponent.Initialize(Creator : TEntity; ComponentGroup : SetComponentGroup);
begin
  inherited;
  FFactor := Creator.Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle;
  FCount := Creator.Eventbus.Read(eiWelaCount, [], ComponentGroup).AsInteger - 1;
end;

function TBuffDamageMultiplierComponent.OnWelaDamage(PrevValue : RParam) : RParam;
begin
  Result := PrevValue.AsSingle * FFactor;
  if FCount >= 0 then
  begin
    dec(FCount);
    if FCount < 0 then self.Free;
  end;
end;

{ TBenchmarkServerComponent }

constructor TBenchmarkServerComponent.Create(Owner : TEntity);
begin
  inherited;
  FSpawndUnits := TDictionary<integer, TEntity>.Create();
  FBenchScript := ScriptManager.CompileScriptFromFile(FormatDateiPfad('scripts\benchmark.ets'));
end;

destructor TBenchmarkServerComponent.Destroy;
begin
  FSpawndUnits.Free;
  FBenchScript.Free;
  inherited;
end;

function TBenchmarkServerComponent.OnIdle : boolean;
var
  i : integer;
  targetUnit : string;
  unitCount : integer;

  procedure SpawnUnit(BuildZone : TBuildZone);
  var
    Position : RVector2;
    buildGridPosition : RIntVector2;
    Entity : TEntity;
  begin
    if targetUnit = '' then
    begin
      targetUnit := FBenchScript.GetGlobalVariableValue<string>('BENCHMARK_UNIT');
    end;
    buildGridPosition := RIntVector2.Create(random(BuildZone.Size.x), random(BuildZone.Size.y));
    Position := BuildZone.GetCenterOfField(buildGridPosition);
    Entity := ServerGame.ServerEntityManager.SpawnUnit(
      Position,
      BuildZone.Front,
      targetUnit,
      TServerEntityManagerComponent.INHERIT_FROM_GAME,
      TServerEntityManagerComponent.INHERIT_FROM_GAME,
      BuildZone.TeamID,
      0,
      nil);
    FSpawndUnits.Add(Entity.ID, Entity);
  end;

begin
  Result := True;
  targetUnit := '';
  FBenchScript.RunMain;
  unitCount := FBenchScript.GetGlobalVariableValue<integer>('BENCHMARK_UNIT_COUNT');
  for i := FLeftSideCount to unitCount - 1 do
  begin
    SpawnUnit(Game.Map.BuildZones.BuildZones[0]);
    inc(FLeftSideCount);
  end;
  for i := FRightSideCount to unitCount - 1 do
  begin
    SpawnUnit(Game.Map.BuildZones.BuildZones[4]);
    inc(FRightSideCount);
  end;

end;

function TBenchmarkServerComponent.OnKillEntity(EntityID : RParam) : boolean;
var
  Entity : TEntity;
begin
  Result := True;
  if FSpawndUnits.TryGetValue(EntityID.AsInteger, Entity) then
  begin
    if Entity.TeamID = 1 then
    begin
      dec(FLeftSideCount);
      FSpawndUnits.Remove(EntityID.AsInteger);
    end
    else
      if Entity.TeamID = 2 then
    begin
      dec(FRightSideCount);
      FSpawndUnits.Remove(EntityID.AsInteger);
    end;
  end;
end;

{ TBuffComponent }

procedure TBuffComponent.Initialize(Creator : TEntity; ComponentGroup : SetComponentGroup);
begin

end;

{ TBuffCapDamageByHealthComponent }

procedure TBuffCapDamageByHealthComponent.Initialize(Creator : TEntity; ComponentGroup : SetComponentGroup);
begin
  inherited;
  FFactor := Creator.Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle;
end;

function TBuffCapDamageByHealthComponent.OnTakeDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
var
  MaxHealth : single;
begin
  Result := Previous;
  MaxHealth := Eventbus.Read(eiResourceCap, [ord(reHealth)]).AsSingle;
  if MaxHealth <= 0 then Exit;
  Amount := Min(Amount.AsSingle, MaxHealth * FFactor);
end;

{ TScenarioComponent }

function TScenarioComponent.AddBuildgrid(GridID : integer) : TScenarioComponent;
begin
  Result := self;
  FBuildgrids := FBuildgrids + [GridID];
end;

function TScenarioComponent.AddDrop(GameTick : integer; Filename : string; PosX, PosY : single) : TScenarioComponent;
var
  Action : RScenarioAction;
begin
  Result := self;
  Action.GameTick := GameTick;
  Action.Action := saDrop;
  Action.Filename := CheckFile(Filename);
  Action.Target := ATarget.Create(RVector2.Create(PosX, PosY));
  FActions.Add(Action);
  if FMirrorAxis > 0 then
  begin
    Action.Target := ATarget.Create(RVector2.Create(PosX, PosY).Negate(FMirrorAxis));
    FActions.Add(Action);
  end;
end;

function TScenarioComponent.AddEvent(GameTick : integer; Eventname : string) : TScenarioComponent;
var
  Action : RScenarioAction;
begin
  Result := self;
  Action.GameTick := GameTick;
  Action.Action := saEvent;
  Action.Filename := Eventname.ToLowerInvariant;
  Action.Target := nil;
  FActions.Add(Action);
end;

function TScenarioComponent.AddSpawner(GameTick : integer; Filename : string; BuildGridID : TArray<byte>; BuildGridCoordinate : RIntVector2) : TScenarioComponent;
begin
  Result := AddSpawner(GameTick, Filename, BuildGridID, BuildGridCoordinate.x, BuildGridCoordinate.y);
end;

function TScenarioComponent.AddSpawnerAll(GameTick : integer; Filename : string; BuildGridCoordinateX, BuildGridCoordinateY : integer) : TScenarioComponent;
begin
  Result := self;
  AddSpawner(GameTick, Filename, FBuildgrids, BuildGridCoordinateX, BuildGridCoordinateY);
end;

function TScenarioComponent.AddSpawnerAll(GameTick : integer; Filename : string; BuildGridCoordinate : RIntVector2) : TScenarioComponent;
begin
  Result := self;
  AddSpawner(GameTick, Filename, FBuildgrids, BuildGridCoordinate);
end;

function TScenarioComponent.AddSpawner(GameTick : integer; Filename : string; BuildGridID : TArray<byte>; BuildGridCoordinateX, BuildGridCoordinateY : integer) : TScenarioComponent;
var
  Action : RScenarioAction;
  i : integer;
begin
  Result := self;
  Action.GameTick := GameTick;
  Action.Action := saBuildOnGrid;
  Action.Filename := CheckFile(Filename);
  setLength(Action.Target, length(BuildGridID));
  for i := 0 to length(BuildGridID) - 1 do
      Action.Target[i] := RTarget.CreateBuildTarget(BuildGridID[i], RIntVector2.Create(BuildGridCoordinateX, BuildGridCoordinateY));
  FActions.Add(Action);
end;

function TScenarioComponent.CheckFile(const Filename : string) : string;
begin
  Result := Filename;
  if not Result.Contains('.') then Result := Result + '.ets';
  if not HFilepathManager.FileExists(PATH_SCRIPT + Result) then
      raise EFileNotFoundException.CreateFmt('TScenarioComponent: Could not find %s!', [Result]);
end;

constructor TScenarioComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FActions := TList<RScenarioAction>.Create;
  FMirrorAxis := -1;
end;

destructor TScenarioComponent.Destroy;
begin
  FActions.Free;
  inherited;
end;

function TScenarioComponent.MirrorDrops(Axis : integer) : TScenarioComponent;
begin
  Result := self;
  FMirrorAxis := Axis;
end;

function TScenarioComponent.OnGameTick : boolean;
var
  Action : RScenarioAction;
  i, j : integer;
  Position : RVector2;
  Tick : integer;
begin
  Result := True;
  Tick := GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
  for i := FActions.Count - 1 downto 0 do
    if FActions[i].GameTick <= Tick then
    begin
      Action := FActions[i];
      case Action.Action of
        saBuildOnGrid :
          for j := 0 to Action.Target.Count - 1 do
          begin
            ServerGame.ServerEntityManager.SpawnSpawner(
              Action.Target[j].BuildGridID,
              Action.Target[j].BuildGridCoordinate,
              Action.Filename,
              FTeamID,
              -1,
              nil,
              nil);
          end;
        saDrop :
          for j := 0 to Action.Target.Count - 1 do
          begin
            Position := Action.Target[j].GetTargetPosition;
            ServerGame.ServerEntityManager.SpawnUnit(
              Position,
              Map.Lanes.GetOrientationOfNextLane(Position, FTeamID),
              Action.Filename,
              TServerEntityManagerComponent.INHERIT_FROM_GAME,
              TServerEntityManagerComponent.INHERIT_FROM_GAME,
              FTeamID
              );
          end;
        saEvent :
          GlobalEventbus.Trigger(eiGameEvent, [Action.Filename]);
      end;
      FActions.Delete(i);
    end;

end;

function TScenarioComponent.SetTeam(TeamID : integer) : TScenarioComponent;
begin
  Result := self;
  FTeamID := TeamID;
end;

{ TSurrenderComponent }

constructor TSurrenderComponent.Create(Owner : TEntity; ClientCount : integer);
begin
  inherited Create(Owner);
  FCanSurrender := True;
end;

function TSurrenderComponent.OnSurrender(SurrenderingTeamID : RParam) : boolean;
var
  Nexus : TEntity;
  SurrenderingTeam : integer;
begin
  Result := True;
  if FCanSurrender then
  begin
    if Game.IsTutorial then
        SurrenderingTeam := PVE_TEAM_ID
    else
        SurrenderingTeam := SurrenderingTeamID.AsInteger;
    ServerGame.TeamSurrendered(SurrenderingTeam);
    if Game.EntityManager.TryGetNexusByTeamID(SurrenderingTeam, Nexus) then
        Nexus.Eventbus.Trigger(eiKill, [-1, -1])
    else
        GlobalEventbus.Trigger(eiLose, [SurrenderingTeam]);
  end;
end;

{ TScenarioDirectorComponent.TValueAction }

constructor TScenarioDirectorComponent.TValueAction.Create(Value : integer; GameTick : integer; Parent : TScenarioDirectorComponent);
begin
  inherited Create(GameTick, Parent);
  self.Value := Value;
end;

{ TScenarioDirectorComponent.TEventAction }

constructor TScenarioDirectorComponent.TEventAction.Create(const Eventname : string; GameTick : integer; Parent : TScenarioDirectorComponent);
begin
  inherited Create(GameTick, Parent);
  self.Eventname := Eventname;
end;

procedure TScenarioDirectorComponent.TEventAction.Execute;
begin
  Parent.GlobalEventbus.Trigger(eiGameEvent, [Eventname]);
end;

{ TScenarioDirectorComponent.TAction }

constructor TScenarioDirectorComponent.TAction.Create(GameTick : integer; Parent : TScenarioDirectorComponent);
begin
  self.Parent := Parent;
  self.GameTick := GameTick;
end;

{ TScenarioDirectorComponent }

function TScenarioDirectorComponent.SpawnBossWave(GameTick : integer; Identifier : string; DynamicGoldValue : integer) : TScenarioDirectorComponent;
var
  BossWave : TBossWave;
begin
  BossWave := FBossWavePool.Extra.FilterFirst(
    function(BossWave : TBossWave) : boolean
    begin
      Result := BossWave.Identifier = Identifier;
    end);

  FActions.Add(TSpawnBossWaveAction.Create(BossWave, DynamicGoldValue, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.SpawnRandomBossWave(GameTick, GoldValue : integer) : TScenarioDirectorComponent;
begin
  FActions.Add(TSpawnRandomBossWaveAction.Create(GoldValue, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.SpawnUnit(PositionX, PositionY : single; PatternFileName : string) : TScenarioDirectorComponent;
begin
  ServerGame.ServerEntityManager.SpawnUnit(PositionX, PositionY, PatternFileName, FTeamID);
  if FMirroringEnabled then
      ServerGame.ServerEntityManager.SpawnUnit(PositionX, PositionY * -1, PatternFileName, FTeamID);
  Result := self;
end;

procedure TScenarioDirectorComponent.SpawnUnits(Units : TList<TUnit>; const Position : RVector2; WithOverwatch : boolean);
var
  Squad : TObjectDictionary<EnumSquadRow, TList<TUnit>>;
  SquadRow : EnumSquadRow;
  AUnit : TUnit;
  RowOffset, Target : RVector2;
  SquadLine : TList<TUnit>;
  i, counter : integer;
begin
  FLastUnitsSpawned.Clear;
  Squad := TObjectDictionary < EnumSquadRow, TList < TUnit >>.Create([doOwnsValues]);
  for SquadRow := low(EnumSquadRow) to high(EnumSquadRow) do
      Squad.Add(SquadRow, TList<TUnit>.Create);

  // assign units to categories/rows
  for AUnit in Units do
  begin
    if utCannonFodder in AUnit.Types then
        SquadLine := Squad[srFront]
    else if utTank in AUnit.Types then
        SquadLine := Squad[srOffTank]
    else if utSiege in AUnit.Types then
        SquadLine := Squad[srArtillery]
    else if utRanged in AUnit.Types then
        SquadLine := Squad[srRanged]
    else if utMelee in AUnit.Types then
        SquadLine := Squad[srOffTank]
    else raise EUnsupportedException.CreateFmt('TScenarioDirectorComponent.SpawnUnits: Could not assign unit "%s" to a squad row.',
        [AUnit.Identifier]);
    for i := 0 to AUnit.SquadSize - 1 do
        SquadLine.Add(AUnit);
  end;
  // spawn all units from squad
  RowOffset := RVector2.ZERO;
  for SquadRow := low(EnumSquadRow) to high(EnumSquadRow) do
  begin
    SquadLine := Squad[SquadRow];
    if SquadLine.Count > 0 then
    begin
      counter := 0;
      for i := 0 to SquadLine.Count - 1 do
      begin
        if counter > 6 then
        begin
          RowOffset := RowOffset + RVector2.Create(SQUAD_ROW_DISTANCE, 0);
          counter := 0;
        end;
        AUnit := SquadLine[i];
        Target := Position + RowOffset + RVector2.Create(0, i * SQUAD_UNIT_SPACE - (SquadLine.Count - 1) * SQUAD_UNIT_SPACE / 2);
        if assigned(ServerGame) then
            Target := ServerGame.Map.ClampToZone(ZONE_WALK, Target);
        if not WithOverwatch then
            ServerGame.ServerEntityManager.SpawnUnit(
            Target,
            Map.Lanes.GetOrientationOfNextLane(Target, FTeamID),
            AUnit.DropFilename,
            TServerEntityManagerComponent.INHERIT_FROM_GAME,
            TServerEntityManagerComponent.INHERIT_FROM_GAME,
            FTeamID
            )
        else
            ServerGame.ServerEntityManager.SpawnUnitWithOverwatchAndFlee(
            Target,
            Map.Lanes.GetOrientationOfNextLane(Target, FTeamID),
            AUnit.DropFilename,
            FTeamID, 30
            );
        FLastUnitsSpawned.Add(AUnit);
        inc(counter);
      end;
      RowOffset := RowOffset + RVector2.Create(SQUAD_ROW_DISTANCE, 0);
    end;
  end;
  Squad.Free;
end;

function TScenarioDirectorComponent.SpawnUnitWithoutLimitedLifetime(PositionX, PositionY : single; PatternFileName : string;
out SpawnedEntity : TEntity) : TScenarioDirectorComponent;
begin
  assert(not FMirroringEnabled);
  SpawnedEntity := ServerGame.ServerEntityManager.SpawnUnitWithoutLimitedLifetime(PositionX, PositionY, PatternFileName, FTeamID);
  Result := self;
end;

function TScenarioDirectorComponent.SpawnUnitWithoutLimitedLifetimeAndReturnEntity(PositionX, PositionY : single;
PatternFileName : string) : TEntity;
begin
  assert(not FMirroringEnabled);
  Result := ServerGame.ServerEntityManager.SpawnUnitWithoutLimitedLifetime(PositionX, PositionY, PatternFileName, FTeamID);
end;

function TScenarioDirectorComponent.SpawnUnitWithoutLimitedLifetimeWithFront(PositionX, PositionY, FrontX, FrontY : single;
PatternFileName : string) : TScenarioDirectorComponent;
begin
  ServerGame.ServerEntityManager.SpawnUnitWithoutLimitedLifetimeWithFront(PositionX, PositionY, FrontX, FrontY, PatternFileName, FTeamID);
  if FMirroringEnabled then
      ServerGame.ServerEntityManager.SpawnUnitWithoutLimitedLifetimeWithFront(PositionX, PositionY * -1, FrontX, FrontY, PatternFileName, FTeamID);
  Result := self;
end;

function TScenarioDirectorComponent.SpawnUnitWithoutLimitedLifetime(PositionX, PositionY : single;
PatternFileName : string) : TScenarioDirectorComponent;
begin
  ServerGame.ServerEntityManager.SpawnUnitWithoutLimitedLifetime(PositionX, PositionY, PatternFileName, FTeamID);
  if FMirroringEnabled then
      ServerGame.ServerEntityManager.SpawnUnitWithoutLimitedLifetime(PositionX, PositionY * -1, PatternFileName, FTeamID);
  Result := self;
end;

function TScenarioDirectorComponent.UnregisterBossWaveAtTime(GameTick : integer; Identifier : string) : TScenarioDirectorComponent;
begin
  FActions.Add(TUnregisterBossWaveAction.Create(Identifier, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.AddEvent(GameTick : integer; Eventname : string) : TScenarioDirectorComponent;
begin
  FActions.Add(TEventAction.Create(Eventname, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.AddKIPlayer(GridID, PosX, PosY : integer) : TScenarioDirectorComponent;
begin
  FKIPlayers.Add(TKIPlayer.Create(self, GridID, RVector2.Create(PosX, PosY)));
  Result := self;
end;

function TScenarioDirectorComponent.AddUnitsToDropSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
begin
  FActions.Add(TChangeUnitSubset.Create(GetUnitsByIdentifier(UnitSubset), False, FDropUnitSubset, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.AddUnitsToSpawnerSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
begin
  FActions.Add(TChangeUnitSubset.Create(GetUnitsByIdentifier(UnitSubset), False, FSpawnerUnitSubset, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.ChangeUnitDropSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
begin
  FActions.Add(TChangeUnitSubset.Create(GetUnitsByIdentifier(UnitSubset), True, FDropUnitSubset, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.ChangeUnitSpawnerSubset(GameTick : integer; UnitSubset : TArray<string>) : TScenarioDirectorComponent;
begin
  FActions.Add(TChangeUnitSubset.Create(GetUnitsByIdentifier(UnitSubset), True, FSpawnerUnitSubset, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.ChangeGold(GameTick, Gold : integer) : TScenarioDirectorComponent;
begin
  FActions.Add(TSetGoldAction.Create(Gold, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.ChangeGoldIncome(GameTick, GoldIncome : integer) : TScenarioDirectorComponent;
begin
  FActions.Add(TSetGoldIncomeAction.Create(GoldIncome, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.ChangeWood(GameTick, Wood : integer) : TScenarioDirectorComponent;
begin
  FActions.Add(TSetWoodAction.Create(Wood, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.ChangeWoodIncome(GameTick, WoodIncome : integer) : TScenarioDirectorComponent;
begin
  FActions.Add(TSetWoodIncomeAction.Create(WoodIncome, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.ChooseUnitFaction(UnitFaction : EnumEntityColor) : TScenarioDirectorComponent;
var
  CardInfo : TCardInfo;
  CardUID : string;
begin
  for CardUID in CardInfoManager.GetAllCardUIDs do
  begin
    CardInfo := CardInfoManager.ResolveCardUID(CardUID, FLeague, 1);
    if assigned(CardInfo) and (UnitFaction in CardInfo.CardColors) and not CardInfo.IsSpawner and not CardInfo.Filename.Contains(FILE_IDENTIFIER_GOLEMS) then
    begin
      FUnitPool.Add(TUnit.Create(CardInfo));
      // only allow units in pool, no buildings
      if not(utUnit in FUnitPool.Last.Types) then
          FUnitPool.Delete(FUnitPool.Count - 1);
    end;
  end;
  FDropUnitSubset.AddUnits(FUnitPool);
  FSpawnerUnitSubset.AddUnits(FUnitPool);
  Result := self;
end;

constructor TScenarioDirectorComponent.Create(Owner : TEntity);
begin
  inherited;
  FActions := TObjectList<TAction>.Create();
  FUnitPool := TUltimateObjectList<TUnit>.Create();
  FLastUnitsSpawned := TList<TUnit>.Create;
  FDropUnitSubset := TUnitSubset.Create;
  FSpawnerUnitSubset := TUnitSubset.Create;
  FBossWavePool := TUltimateObjectList<TBossWave>.Create();
  FKIPlayers := TObjectList<TKIPlayer>.Create;
  FLeague := Game.League;
end;

destructor TScenarioDirectorComponent.Destroy;
begin
  FLastUnitsSpawned.Free;
  FActions.Free;
  FDropUnitSubset.Free;
  FSpawnerUnitSubset.Free;
  FBossWavePool.Free;
  FUnitPool.Free;
  FKIPlayers.Free;
  inherited;
end;

function TScenarioDirectorComponent.DisableMirroring : TScenarioDirectorComponent;
begin
  FMirroringEnabled := False;
  Result := self;
end;

function TScenarioDirectorComponent.SpawnGuards(PosX, PosY : integer; FixedUnits, DynamicUnits : TArray<string>;
GoldValue : integer) : TScenarioDirectorComponent;
var
  FixedUnitsArray : TArray<TUnit>;
  DynamicUnitsSubset : TUnitSubset;
  Guards : TBossWave;
  GuardUnitList : TList<TUnit>;
  DynamicGoldValue : integer;
  AUnit : TUnit;
  Lanes : TArray<integer>;
  Lane : integer;
begin
  DynamicGoldValue := GoldValue;
  FixedUnitsArray := GetUnitsByIdentifier(FixedUnits);
  for AUnit in FixedUnitsArray do
  begin
    DynamicGoldValue := DynamicGoldValue - AUnit.GoldCost;
  end;
  if FMirroringEnabled then
      Lanes := [1, -1]
  else
      Lanes := [1];
  for Lane in Lanes do
  begin
    DynamicUnitsSubset := TUnitSubset.Create;
    DynamicUnitsSubset.AddUnits(GetUnitsByIdentifier(DynamicUnits));
    Guards := TBossWave.Create('', FixedUnitsArray, DynamicUnitsSubset);
    GuardUnitList := Guards.ComputeBossWave(DynamicGoldValue);
    SpawnUnits(GuardUnitList, RVector2.Create(PosX, PosY * Lane), True);
    GuardUnitList.Free;
    Guards.Free;
  end;
  Result := self;
end;

procedure TScenarioDirectorComponent.DoGameTick;
var
  Tick : integer;
  KIPlayer : TKIPlayer;
begin
  // setup
  Tick := GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
  ProcessActions(Tick);
  for KIPlayer in FKIPlayers do
      KIPlayer.DoThink;
  // PrintDebug(Tick);
end;

function TScenarioDirectorComponent.DropUnitsNow(GameTick : integer) : TScenarioDirectorComponent;
begin
  FActions.Add(TDropUnitsNowAction.Create(GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.EnableMirroring : TScenarioDirectorComponent;
begin
  FMirroringEnabled := True;
  Result := self;
end;

function TScenarioDirectorComponent.GetUnitsByIdentifier(UnitSubsetIdentifiers : TArray<string>) : TArray<TUnit>;
var
  i : integer;
  AUnit : TUnit;
begin
  setLength(Result, length(UnitSubsetIdentifiers));
  for i := 0 to length(UnitSubsetIdentifiers) - 1 do
  begin
    AUnit := FUnitPool.Extra.FilterFirst(
      function(Item : TUnit) : boolean
      begin
        Result := Item.Identifier = UnitSubsetIdentifiers[i];
      end);
    Result[i] := AUnit;
  end;
end;

function TScenarioDirectorComponent.GetNextBossWaveAction : TSpawnRandomBossWaveAction;
var
  Action : TAction;
begin
  Result := nil;
  for Action in FActions do
  begin
    if Action is TSpawnRandomBossWaveAction then
    begin
      Result := TSpawnRandomBossWaveAction(Action);
      Exit;
    end;
  end;
end;

function TScenarioDirectorComponent.OnGameTick : boolean;
begin
  Result := True;
  DoGameTick;
end;

procedure TScenarioDirectorComponent.PrintDebug(GameTick : integer);
// var
// AUnit : TUnit;
// BossWaveAction : TSpawnRandomBossWaveAction;
begin
  HLog.ClearConsole();
  HLog.Console('Scenario Director Debug');
  HLog.Console('=======================' + sLineBreak);
  HLog.Console('');
  // HLog.Console('Current Gold: %d ', [FGold]);
  // HLog.Console('Gold Income: %d ', [FGoldIncome]);
  // HLog.Console('Next Gold Save: %d ', [FNextGoldSave]);
  // HLog.Console('');
  // HLog.Console('Current Wood: %d', [FWood]);
  // HLog.Console('Wood Income: %d', [FWoodIncome]);
  // HLog.Console('Spawner Count: %d', [FSpawnerCount]);
  // if assigned(FNextSpawner) then
  // HLog.Console('Next Spawner: %s (%d wood)', [FNextSpawner.Identifier, FNextSpawner.WoodCost])
  // else
  // HLog.Console('Next Spawner: ---');
  // HLog.Console('');
  // BossWaveAction := GetNextBossWaveAction;
  // HLog.Console('·····································');
  // if assigned(BossWaveAction) then
  // HLog.Console('Next Bosswave in %d sec', [BossWaveAction.GameTick - GameTick])
  // else
  // HLog.Console('Next Bosswave: ---');
  // HLog.Console('·····································');
  // HLog.Console('');
  // for AUnit in FLastUnitsSpawned do
  // begin
  // HLog.Console('%s - %s', [AUnit.Identifier, HRtti.SetToString<SetUnitTypes>(AUnit.Types)]);
  // end;
end;

procedure TScenarioDirectorComponent.ProcessActions(GameTick : integer);
var
  i : integer;
begin
  // execute and delete all actions where is about time
  for i := FActions.Count - 1 downto 0 do
    if FActions[i].GameTick <= GameTick then
    begin
      FActions[i].Execute;
      FActions.Delete(i);
    end;
end;

function TScenarioDirectorComponent.RegisterBossWave(Identifier : string; FixedUnits, DynamicUnits : TArray<string>) : TScenarioDirectorComponent;
var
  FixedUnitsArray : TArray<TUnit>;
  DynamicUnitsSubset : TUnitSubset;
  BossWave : TBossWave;
begin
  FixedUnitsArray := GetUnitsByIdentifier(FixedUnits);
  DynamicUnitsSubset := TUnitSubset.Create;
  DynamicUnitsSubset.AddUnits(GetUnitsByIdentifier(DynamicUnits));
  BossWave := TBossWave.Create(Identifier, FixedUnitsArray, DynamicUnitsSubset);
  FBossWavePool.Add(BossWave);
  Result := self;
end;

function TScenarioDirectorComponent.RegisterBossWaveAtTime(GameTick : integer; Identifier : string; FixedUnits, DynamicUnits : TArray<string>) : TScenarioDirectorComponent;
var
  FixedUnitsArray : TArray<TUnit>;
  DynamicUnitsSubset : TUnitSubset;
  BossWave : TBossWave;
begin
  FixedUnitsArray := GetUnitsByIdentifier(FixedUnits);
  DynamicUnitsSubset := TUnitSubset.Create;
  DynamicUnitsSubset.AddUnits(GetUnitsByIdentifier(DynamicUnits));
  BossWave := TBossWave.Create(Identifier, FixedUnitsArray, DynamicUnitsSubset);
  FActions.Add(TRegisterBossWaveAction.Create(BossWave, GameTick, self));
  Result := self;
end;

function TScenarioDirectorComponent.SetLeague(League : integer) : TScenarioDirectorComponent;
begin
  FLeague := League;
  Result := self;
end;

function TScenarioDirectorComponent.SetTeam(TeamID : integer) : TScenarioDirectorComponent;
begin
  FTeamID := TeamID;
  Result := self;
end;

{ TScenarioDirectorComponent.TUnit }

constructor TScenarioDirectorComponent.TUnit.Create(CardInfo : TCardInfo);
var
  ScenarioInfoData : TScenarioUnitInfo;
  NormalizedCardInfo : TCardInfo;
  CardUID : string;
  SpawnerCardInfo : TCardInfo;
begin
  // use gold league as normalized card league (as scenarios created for gold league)
  NormalizedCardInfo := CardInfoManager.ResolveCardUID(CardInfo.UID, 4, 1);
  FGoldCost := NormalizedCardInfo.GoldCost;
  FSquadSize := NormalizedCardInfo.SquadSize;
  FIdentifier := CardInfoManager.ScriptFilenameToCardIdentifier(CardInfo.Filename);
  if ScenarioUnitInfoMapping.TryGetValue(Identifier, ScenarioInfoData) then
      FTypes := ScenarioInfoData.UnitTypes
  else
      raise ENotFoundException.CreateFmt('TScenarioDirectorComponent.TUnit.Create: For unit "%s" was no infodata found.',
      [Identifier]);
  FDropFilename := CardInfo.Filename.Replace('Drop', '');
  for CardUID in CardInfoManager.GetAllCardUIDs do
    if CardInfoManager.TryResolveCardUID(CardUID, CardInfo.League, CardInfo.Level, SpawnerCardInfo) then
    begin
      if SameText(CardInfoManager.ScriptFilenameToCardIdentifier(SpawnerCardInfo.Filename), Identifier) and SpawnerCardInfo.IsSpawner then
      begin
        NormalizedCardInfo := CardInfoManager.ResolveCardUID(SpawnerCardInfo.UID, 4, 1);
        FSpawnerFileName := SpawnerCardInfo.Filename;
        FWoodCost := NormalizedCardInfo.WoodCost;
        break;
      end;
    end;
end;

{ TScenarioDirectorComponent.TSetGoldIncomeAction }

procedure TScenarioDirectorComponent.TSetGoldIncomeAction.Execute;
begin
  self.Parent.FGoldIncome := Value;
end;

{ TScenarioDirectorComponent.TSetGoldAction }

procedure TScenarioDirectorComponent.TSetGoldAction.Execute;
var
  KIPlayer : TKIPlayer;
begin
  for KIPlayer in self.Parent.FKIPlayers do
      KIPlayer.Gold := Value;
end;

{ TScenarioDirectorComponent.TChangeUnitSubset }

constructor TScenarioDirectorComponent.TChangeUnitSubset.Create(Units : TArray<TUnit>; OverwriteSubset : boolean;
TargetSubset : TUnitSubset; GameTick : integer; Parent : TScenarioDirectorComponent);
begin
  inherited Create(GameTick, Parent);
  self.Units := Units;
  self.OverwriteSubset := OverwriteSubset;
  self.TargetSubset := TargetSubset;
end;

procedure TScenarioDirectorComponent.TChangeUnitSubset.Execute;
begin
  if OverwriteSubset then
      TargetSubset.Clear;
  TargetSubset.AddUnits(Units);
end;

{ TScenarioDirectorComponent.TSetWoodAction }

procedure TScenarioDirectorComponent.TSetWoodAction.Execute;
var
  KIPlayer : TKIPlayer;
begin
  for KIPlayer in self.Parent.FKIPlayers do
      KIPlayer.Wood := Value;
end;

{ TScenarioDirectorComponent.TSetWoodIncomeAction }

procedure TScenarioDirectorComponent.TSetWoodIncomeAction.Execute;
begin
  Parent.FWoodIncome := Value;
end;

{ TScenarioDirectorComponent.TUnitSubset }

procedure TScenarioDirectorComponent.TUnitSubset.AddUnits(Units : TList<TUnit>);
begin
  FSubset.AddRange(Units);
end;

procedure TScenarioDirectorComponent.TUnitSubset.AddUnits(Units : TArray<TUnit>);
begin
  FSubset.AddRange(Units);
end;

procedure TScenarioDirectorComponent.TUnitSubset.Clear;
begin
  FSubset.Clear;
end;

constructor TScenarioDirectorComponent.TUnitSubset.Create;
begin
  FSubset := TUltimateList<TUnit>.Create;
end;

destructor TScenarioDirectorComponent.TUnitSubset.Destroy;
begin
  FSubset.Free;
  inherited;
end;

function TScenarioDirectorComponent.TUnitSubset.GetRandomUnit(Filter : FuncFilterUnit) : TUnit;
var
  AUnit : TUnit;
begin
  Result := nil;
  FSubset.Shuffle;
  for AUnit in FSubset do
  begin
    if not assigned(Filter) or Filter(AUnit) then
        Exit(AUnit);
  end;
end;

{ TScenarioDirectorComponent.TDropUnitsNowAction }

procedure TScenarioDirectorComponent.TDropUnitsNowAction.Execute;
var
  KIPlayer : TKIPlayer;
begin
  for KIPlayer in self.Parent.FKIPlayers do
      KIPlayer.DropUnits;
end;

{ TScenarioDirectorComponent.TBossWave }

function TScenarioDirectorComponent.TBossWave.ComputeBossWave(DynamicGoldValue : integer) : TList<TUnit>;
var
  AUnit : TUnit;
begin
  // make compute non destructible
  Result := TList<TUnit>.Create;
  // definitely add fixed units
  Result.AddRange(FFixedUnits);
  // and additionaly add randomly dynamic units until all gold is spent or gold
  // not suffices minimum unit cost
  repeat
    AUnit := FDynamicUnits.GetRandomUnit(
      function(AUnit : TUnit) : boolean
      begin
        Result := AUnit.GoldCost <= DynamicGoldValue;
      end);
    if assigned(AUnit) then
    begin
      DynamicGoldValue := DynamicGoldValue - AUnit.GoldCost;
      Result.Add(AUnit);
    end;
  until not assigned(AUnit);
end;

constructor TScenarioDirectorComponent.TBossWave.Create(const Identifier : string; FixedUnits : TArray<TUnit>; DynamicUnits : TUnitSubset);
var
  AUnit : TUnit;
begin
  FFixedUnits := FixedUnits;
  FDynamicUnits := DynamicUnits;
  FIdentifier := Identifier;
  // compute FixedGoldValue
  for AUnit in FFixedUnits do
      FFixedGoldValue := FFixedGoldValue + AUnit.GoldCost;
end;

destructor TScenarioDirectorComponent.TBossWave.Destroy;
begin
  FDynamicUnits.Free;
  inherited;
end;

{ TScenarioDirectorComponent.TSpawnBossWaveAction }

constructor TScenarioDirectorComponent.TSpawnRandomBossWaveAction.Create(GoldValue : integer; GameTick : integer; Parent : TScenarioDirectorComponent);
begin
  inherited Create(GameTick, Parent);
  self.GoldValue := GoldValue;
end;

procedure TScenarioDirectorComponent.TSpawnRandomBossWaveAction.Execute;
var
  UnitList : TList<TUnit>;
  DynamicGold : integer;
  BossWave : TBossWave;
  KIPlayer : TKIPlayer;
begin
  for KIPlayer in Parent.FKIPlayers do
  begin
    Parent.FBossWavePool.Shuffle;
    BossWave := Parent.FBossWavePool.Extra.FilterFirstSave(
      function(Item : TBossWave) : boolean
      begin
        Result := Item.FixedGoldValue <= GoldValue
      end);
    if not assigned(BossWave) then
        raise ENotFoundException.CreateFmt('TScenarioDirectorComponent.SpawnRandomBossWave: No bosswave with goldcost <= %d was found.',
        [GoldValue]);
    DynamicGold := GoldValue - BossWave.FixedGoldValue;
    UnitList := BossWave.ComputeBossWave(DynamicGold);
    Parent.SpawnUnits(UnitList, KIPlayer.SpawnPoint);
    UnitList.Free;
  end;
end;

{ TScenarioDirectorComponent.TSpawnBossWaveAction }

constructor TScenarioDirectorComponent.TSpawnBossWaveAction.Create(BossWave : TBossWave; DynamicGoldValue, GameTick : integer;
Parent : TScenarioDirectorComponent);
begin
  inherited Create(GameTick, Parent);
  self.BossWave := BossWave;
  self.DynamicGoldValue := DynamicGoldValue;
end;

procedure TScenarioDirectorComponent.TSpawnBossWaveAction.Execute;
var
  UnitList : TList<TUnit>;
  KIPlayer : TKIPlayer;
begin
  for KIPlayer in Parent.FKIPlayers do
  begin
    UnitList := BossWave.ComputeBossWave(DynamicGoldValue);
    Parent.SpawnUnits(UnitList, KIPlayer.SpawnPoint);
    UnitList.Free;
  end;
end;

{ TSurvivalScenarioDirectorComponent }

procedure TSurvivalScenarioDirectorComponent.ComputeThreat;
var
  Range : single;
  Entity : TEntity;
  Position : RVector2;
begin
  FCurrentThreat := 0;
  Range := 0;
  repeat
    Range := Range + THREAT_CHECK_DISTANCE;
    Entity := ServerGame.GlobalEventbus.Read(eiClosestEntityInRange, [FKIPlayers[0].SpawnPoint, Range, FTeamID, RParam.From<EnumTargetTeamConstraint>(tcEnemies), RPARAM_EMPTY]).AsType<TEntity>;
    if assigned(Entity) then
    begin
      Position := Entity.Position;
      FCurrentThreat := Max(0, THREAT_MAX_CHECK_RANGE - abs((FKIPlayers[0].SpawnPoint - Position).x));
    end;
  until (FCurrentThreat > 0) or (Range > THREAT_MAX_CHECK_RANGE);
end;

constructor TSurvivalScenarioDirectorComponent.Create(Owner : TEntity);
begin
  inherited;
end;

procedure TSurvivalScenarioDirectorComponent.DoGameTick;
// var
// TotalIncome : integer;
begin
  // ComputeThreat;
  // FAdditionalGoldIncome := round(FGoldIncome * (FMaxThreatMultiplier * FCurrentThreat / FMaxThreatDistance));
  // TotalIncome := Min(FGoldIncome + FAdditionalGoldIncome, FTotalGoldRemaining);
  // FGold := FGold + TotalIncome;
  // // burn totalgold by income, because KI have only limite amount
  // FTotalGoldRemaining := FTotalGoldRemaining - TotalIncome;
  // FTotalGoldSpent := FTotalGoldSpent + TotalIncome;
  //
  // ProcessActions(FTotalGoldSpent);
  //
  // if FGold >= FNextGoldSave then
  // begin
  // DropUnits;
  // FNextGoldSave := RandomFrom(FGoldSave);
  // end;
  //
  // PrintDebug(FTotalGoldSpent);
end;

procedure TSurvivalScenarioDirectorComponent.PrintDebug(GameTick : integer);
// var
// BossWaveAction : TSpawnRandomBossWaveAction;
// AUnit : TUnit;
begin
  // HLog.ClearConsole();
  // HLog.Console('Scenario Survival Director Debug');
  // HLog.Console('================================' + sLineBreak);
  // HLog.Console('');
  // HLog.Console('Current Threat: %f', [FCurrentThreat]);
  // HLog.Console('');
  // HLog.Console('Gold remaining: %d', [FTotalGoldRemaining]);
  // HLog.Console('Gold spent: %d', [FTotalGoldSpent]);
  // HLog.Console('Current Gold: %d ', [FGold]);
  // HLog.Console('Gold Income: %d ', [FGoldIncome]);
  // HLog.Console('Additional Gold Income: %d ', [FAdditionalGoldIncome]);
  // HLog.Console('Next Gold Save: %d ', [FNextGoldSave]);
  // HLog.Console('');
  // BossWaveAction := GetNextBossWaveAction;
  // HLog.Console('·····································');
  // if assigned(BossWaveAction) then
  // HLog.Console('Next Bosswave in %d gold', [BossWaveAction.GameTick - GameTick])
  // else
  // HLog.Console('Next Bosswave: ---');
  // HLog.Console('·····································');
  // HLog.Console('');
  // for AUnit in FLastUnitsSpawned do
  // begin
  // HLog.Console('%s - %s', [AUnit.Identifier, HRtti.SetToString<SetUnitTypes>(AUnit.Types)]);
  // end;
end;

function TSurvivalScenarioDirectorComponent.SetTotalGoldRemaining(Value : integer) : TSurvivalScenarioDirectorComponent;
begin
  FTotalGoldRemaining := Value;
  Result := self;
end;

function TSurvivalScenarioDirectorComponent.SetMaxThreatDistance(Value : integer) : TSurvivalScenarioDirectorComponent;
begin
  FMaxThreatDistance := Value;
  Result := self;
end;

function TSurvivalScenarioDirectorComponent.SetMaxThreatMultiplier(Value : single) : TSurvivalScenarioDirectorComponent;
begin
  FMaxThreatMultiplier := Value;
  Result := self;
end;

{ TServerCardPlayStatisticsComponent }

constructor TServerCardPlayStatisticsComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; ScriptFile : string);
begin
  inherited CreateGrouped(Owner, Group);
  FScriptFile := ScriptFile;
end;

function TServerCardPlayStatisticsComponent.OnUseAbility(Targets : RParam) : boolean;
begin
  Result := True;
  // cards are components of the commander so: Owner = Commander
  ServerGame.Statistics.CardPlayed(Owner.ID, self.FScriptFile);
end;

{ TScenarioDirectorComponent.TRegisterBossWaveAction }

constructor TScenarioDirectorComponent.TRegisterBossWaveAction.Create(BossWave : TBossWave; GameTick : integer; Parent : TScenarioDirectorComponent);
begin
  inherited Create(GameTick, Parent);
  self.BossWave := BossWave;
end;

destructor TScenarioDirectorComponent.TRegisterBossWaveAction.Destroy;
begin
  // free bosswave because it is possible that action was never executed and so bosswave will not freed be BossWavePool
  // execute will perevent a double free
  BossWave.Free;
  inherited;
end;

procedure TScenarioDirectorComponent.TRegisterBossWaveAction.Execute;
begin
  Parent.FBossWavePool.Add(BossWave);
  // prevent that bosswave is double freed
  BossWave := nil;
end;

{ TScenarioDirectorComponent.TUnregisterBossWaveAction }

constructor TScenarioDirectorComponent.TUnregisterBossWaveAction.Create(const Identifier : string; GameTick : integer; Parent : TScenarioDirectorComponent);
begin
  inherited Create(GameTick, Parent);
  self.BossWaveIdentifier := Identifier;
end;

procedure TScenarioDirectorComponent.TUnregisterBossWaveAction.Execute;
var
  index : integer;
begin
  index := Parent.FBossWavePool.Extra.FilterFirstIndex(
    function(Value : TBossWave) : boolean
    begin
      Result := Value.Identifier = BossWaveIdentifier
    end);
  if index >= 0 then
      Parent.FBossWavePool.Delete(index)
  else
      raise ENotFoundException.CreateFmt('TScenarioDirectorComponent.TUnregisterBossWaveAction.Execute: No bosswave with identifier "%s" was found.', [BossWaveIdentifier]);
end;

{ TScenarioDirectorComponent.TKIPlayer }

constructor TScenarioDirectorComponent.TKIPlayer.Create(Director : TScenarioDirectorComponent; Buildgrid : byte; SpawnPoint : RVector2);
begin
  self.Director := Director;
  self.Buildgrid := Buildgrid;
  self.SpawnPoint := SpawnPoint;
end;

procedure TScenarioDirectorComponent.TKIPlayer.DoThink;
begin
  Gold := Gold + Director.FGoldIncome;
  Wood := Wood + Director.FWoodIncome;

  if Gold >= NextGoldSave then
  begin
    DropUnits;
    NextGoldSave := 300;
  end;

  SpawnSpawner();
end;

procedure TScenarioDirectorComponent.TKIPlayer.DropUnits;
var
  UnitList : TList<TUnit>;
  AUnit : TUnit;
begin
  // spawning units
  UnitList := TList<TUnit>.Create;
  // select until no unit was found to spawn
  repeat
    AUnit := Director.FDropUnitSubset.GetRandomUnit(
      function(AUnit : TUnit) : boolean
      begin
        Result := (AUnit.GoldCost <= Gold) and (AUnit.GoldCost = NextGoldSave)
      end);
    if assigned(AUnit) then
    begin
      assert(AUnit.GoldCost > 0);
      Gold := Gold - AUnit.GoldCost;
      UnitList.Add(AUnit);
    end;
    // when AUnit = nil, no unit to spawn was found, so stop trying
  until not assigned(AUnit);
  Director.SpawnUnits(UnitList, SpawnPoint);
  UnitList.Free;
end;

function TScenarioDirectorComponent.TKIPlayer.GetNextSpawnerPosition : RIntVector2;
begin
  if SpawnerCount in [0, 7, 16] then
      inc(SpawnerCount);
  Result.x := SpawnerCount mod 8;
  Result.y := SpawnerCount div 8;
  inc(SpawnerCount);
end;

procedure TScenarioDirectorComponent.TKIPlayer.SpawnSpawner;
var
  SpawnerPosition : RIntVector2;
begin
  if assigned(NextSpawner) then
  begin
    // if woodcost can payed, build the spawner
    // prevent that AI build more spawner then buildgrid slots are existing
    if (Wood >= NextSpawner.WoodCost) and (BUILDGRID_SLOTS > SpawnerCount) then
    begin
      assert(NextSpawner.WoodCost > 0, NextSpawner.Identifier);
      Wood := Wood - NextSpawner.WoodCost;
      SpawnerPosition := GetNextSpawnerPosition;
      ServerGame.ServerEntityManager.SpawnSpawner(Buildgrid, SpawnerPosition, NextSpawner.SpawnerFileName, Director.FTeamID, -1, nil, nil);
      NextSpawner := Director.FSpawnerUnitSubset.GetRandomUnit(nil);
    end;
  end
  else
    // there have to be everytime a spawner
      NextSpawner := Director.FSpawnerUnitSubset.GetRandomUnit(nil);
end;

{ TServerNetworkComponent.TSendedData }

constructor TServerNetworkComponent.TSendedData.Create(Data : TCommandSequence);
begin
  self.Data := Data;
  self.Timestamp := Gettickcount;
end;

destructor TServerNetworkComponent.TSendedData.Destroy;
begin
  Data.Free;
  inherited;
end;

{ TServerSandboxComponent }

function TServerSandboxComponent.OnGameCommencing : boolean;
var
  Commander : TEntity;
begin
  Result := True;
  if assigned(ServerGame) then
  begin
    for Commander in ServerGame.Commanders do
    begin
      Commander.Eventbus.Trigger(eiResourceCapTransaction, [ord(reGold), 100000.0, True]);
      Commander.Eventbus.Trigger(eiResourceTransaction, [ord(reGold), 100000.0]);
      Commander.Eventbus.Trigger(eiResourceTransaction, [ord(reWood), 10000.0]);
    end;
  end;
  GlobalEventbus.Trigger(eiGameEvent, [GAME_EVENT_TECH_LEVEL_2]);
  GlobalEventbus.Trigger(eiGameEvent, [GAME_EVENT_TECH_LEVEL_3]);
end;

{ TServerSandboxCommandComponent }

function TServerSandboxCommandComponent.OnClientCommand(Command, Param1 : RParam) : boolean;
var
  RealCommand : EnumClientCommand;
  Entities : TList<TEntity>;
  i : integer;
begin
  Result := True;
  Entities := nil;
  RealCommand := Command.AsEnumType<EnumClientCommand>;
  case RealCommand of
    ccClearUnits :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upUnit, upBuilding, upCharm], [upBase, upGolem]);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
      end;
    ccClearAllUnits :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upUnit, upBuilding, upCharm], [upBase]);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
      end;
    ccClearSpawners :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upSpawner, upBuilding], [upBase, upGolem]);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
      end;
    ccClearLaneTowers :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upLanetower, upLaneNode], [upGolem]);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
        ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LaneNode', 0);
        ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0);
        ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LaneNode', 0);
        if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LaneNode', 0);
        end;
      end;
    ccClearGolemTowers :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upLanetower, upLaneNode], []);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
        ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LaneNode', 0);
        ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0);
        ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LaneNode', 0);
        if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LaneNode', 0);
        end;
      end;
    ccBaseBuildingsLevel1 :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upBase], [upGolem]);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
        if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
            ServerGame.ServerEntityManager.SpawnUnit(-92, 0, 'Units\Neutral\NexusLevel1', 1)// Blue Nexus
        else
            ServerGame.ServerEntityManager.SpawnUnit(-96, -23, 'Units\Neutral\NexusLevel1', 1); // Blue Nexus
        if not ServerGame.GameInformation.ScenarioUID.Contains(SCENARIO_PVE_DEFAULT_PREFIX) then
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LanetowerLevel1', 1);
          ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0); // right capture point

          ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LanetowerLevel1', 2);
          if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
          begin
            ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LanetowerLevel1', 1);
            ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0); // left capture point
            ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LanetowerLevel1', 2);
            ServerGame.ServerEntityManager.SpawnUnit(92, 0, 'Units\Neutral\NexusLevel1', 2); // Red Nexus
          end
          else
              ServerGame.ServerEntityManager.SpawnUnit(96, -23, 'Units\Neutral\NexusLevel1', 2); // Red Nexus
        end
        else
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LaneNode', 0);
          if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
          begin
            ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LaneNode', 0);
            ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0);
            ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LaneNode', 0);
          end;
        end;
      end;
    ccBaseBuildingsLevel2 :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upBase], [upGolem]);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
        if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
            ServerGame.ServerEntityManager.SpawnUnit(-92, 0, 'Units\Neutral\NexusLevel2', 1)// Blue Nexus
        else
            ServerGame.ServerEntityManager.SpawnUnit(-96, -23, 'Units\Neutral\NexusLevel2', 1); // Blue Nexus
        if not ServerGame.GameInformation.ScenarioUID.Contains(SCENARIO_PVE_DEFAULT_PREFIX) then
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LanetowerLevel2', 1);
          ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0); // right capture point
          ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LanetowerLevel2', 2);
          if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
          begin
            ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LanetowerLevel2', 1);
            ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0); // left capture point
            ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LanetowerLevel2', 2);
            ServerGame.ServerEntityManager.SpawnUnit(92, 0, 'Units\Neutral\NexusLevel2', 2); // Red Nexus
          end
          else
              ServerGame.ServerEntityManager.SpawnUnit(96, -23, 'Units\Neutral\NexusLevel2', 2); // Red Nexus
        end
        else
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LaneNode', 0);
          if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
          begin
            ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LaneNode', 0);
            ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0);
            ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LaneNode', 0);
          end;
        end;
      end;
    ccBaseBuildingsLevel3 :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upBase], [upGolem]);
        for i := 0 to Entities.Count - 1 do
            GlobalEventbus.Trigger(eiDelayedKillEntity, [Entities[i].ID]);
        if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
            ServerGame.ServerEntityManager.SpawnUnit(-92, 0, 'Units\Neutral\NexusLevel3', 1)// Blue Nexus
        else
            ServerGame.ServerEntityManager.SpawnUnit(-96, -23, 'Units\Neutral\NexusLevel3', 1); // Blue Nexus
        if not ServerGame.GameInformation.ScenarioUID.Contains(SCENARIO_PVE_DEFAULT_PREFIX) then
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LanetowerLevel3', 1);
          ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0); // right capture point
          ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LanetowerLevel3', 2);
          if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
          begin
            ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LanetowerLevel3', 1);
            ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0); // left capture point
            ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LanetowerLevel3', 2);
            ServerGame.ServerEntityManager.SpawnUnit(92, 0, 'Units\Neutral\NexusLevel3', 2); // Red Nexus
          end
          else
              ServerGame.ServerEntityManager.SpawnUnit(96, -23, 'Units\Neutral\NexusLevel3', 2); // Red Nexus
        end
        else
        begin
          ServerGame.ServerEntityManager.SpawnUnit(-48, -23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(0, -23, 'Units\Neutral\LaneNode', 0);
          ServerGame.ServerEntityManager.SpawnUnit(48, -23, 'Units\Neutral\LaneNode', 0);
          if ServerGame.GameInformation.Scenario.MapName = MAP_DOUBLE then
          begin
            ServerGame.ServerEntityManager.SpawnUnit(-48, 23, 'Units\Neutral\LaneNode', 0);
            ServerGame.ServerEntityManager.SpawnUnit(0, 23, 'Units\Neutral\LaneNode', 0);
            ServerGame.ServerEntityManager.SpawnUnit(48, 23, 'Units\Neutral\LaneNode', 0);
          end;
        end;
      end;
    ccBaseBuildingsIndestructible :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([upBase], [upGolem]);
        for i := 0 to Entities.Count - 1 do
        begin
          Entities[i].Eventbus.Trigger(eiResourceCapTransaction, [ord(reHealth), 1000000.0, True]);
          Entities[i].Eventbus.Trigger(eiResourceTransaction, [ord(reHealth), 1000000.0]);
          Entities[i].Eventbus.Trigger(eiResourceCapTransaction, [ord(reMana), 10000, True]);
          Entities[i].Eventbus.Trigger(eiResourceTransaction, [ord(reMana), 10000]);
        end;
      end;
    ccToggleOverwatch : Overwatch := not Overwatch;
    ccToggleOverwatchSandbox : OverwatchClearable := not OverwatchClearable;
    ccClearOverwatch :
      begin
        Entities := ServerGame.EntityManager.FilterEntities([], []);
        for i := 0 to Entities.Count - 1 do
        begin
          Entities[i].Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(
            procedure(Component : TEntityComponent)
            begin
              if (Component is TBrainOverwatchSandboxComponent) then
                  Component.Free;
            end)]);
        end;
      end;
    ccForceGameTick :
      begin
        GlobalEventbus.Trigger(eiGameTick, []);
      end;
  end;
  Entities.Free;
end;

{ TTutorialDirectorServerComponent }

function TTutorialDirectorServerComponent.OnClientCommand(Command, Eventname : RParam) : boolean;
begin
  Result := True;
  if Command.AsEnumType<EnumClientCommand> = ccTutorialGameEvent then
      GlobalEventbus.Trigger(eiGameEvent, [Eventname]);
end;

function TTutorialDirectorServerComponent.OnGameEvent(Eventname : RParam) : boolean;
var
  RealEventname : string;
  i, j : integer;
  Cap : RParam;
  Amount : single;
  Entities : TList<TEntity>;
begin
  Result := True;
  RealEventname := Eventname.AsString;
  Entities := nil;
  if RealEventname = GAME_EVENT_FREEZE_GAME then
  begin
    if not FFrozen then
    begin
      Entities := ServerGame.EntityManager.FilterEntities([upUnit, upBuilding], []);
      for i := 0 to Entities.Count - 1 do
      begin
        TThinkBlockComponent.Create(Entities[i]);
        Entities[i].Eventbus.Trigger(eiStand, []);
      end;
    end;
    FFrozen := True;
  end
  else if RealEventname = GAME_EVENT_UNFREEZE_GAME then
  begin
    FFrozen := False;
    Entities := ServerGame.EntityManager.FilterEntities([], []);
    for i := 0 to Entities.Count - 1 do
    begin
      Entities[i].Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(
        procedure(Component : TEntityComponent)
        begin
          if (Component is TThinkBlockComponent) then
              Component.Free;
        end)]);
    end;
  end
  else if RealEventname = GAME_EVENT_DEACTIVATE_SPAWNER then
      FNoWaveSpawn := True
  else if RealEventname = GAME_EVENT_ACTIVATE_SPAWNER then
      FNoWaveSpawn := False
  else if RealEventname = GAME_EVENT_DEACTIVATE_INCOME then
      FIncomeDisabled := True
  else if RealEventname = GAME_EVENT_ACTIVATE_INCOME then
      FIncomeDisabled := False
  else if RealEventname = GAME_EVENT_REFRESH_GOLD then
  begin
    for i := 0 to ServerGame.Commanders.Count - 1 do
    begin
      ServerGame.Commanders[i].Eventbus.Trigger(eiResourceTransaction, [ord(reGold), 10000.0]);
    end;
  end
  else if RealEventname = GAME_EVENT_REFRESH_CHARGES then
  begin
    for i := 0 to ServerGame.Commanders.Count - 1 do
    begin
      for j := 0 to MAXBYTE do
      begin
        Cap := ServerGame.Commanders[i].Blackboard.GetIndexedValue(eiResourceCap, [j], ord(reCharge));
        if not Cap.IsEmpty then
            ServerGame.Commanders[i].Eventbus.Trigger(eiResourceTransaction, [ord(reCharge), 10000], [j]);
        if ServerGame.Commanders[i].Blackboard.GetValue(eiDamageType, [j]).AsTypeDefault<SetDamageType>([]) = [dtCharge] then
            ServerGame.Commanders[i].Eventbus.Trigger(eiFire, [ATarget.CreateEmpty.ToRParam], [j]);;
      end;
    end;
  end
  else if RealEventname = GAME_EVENT_ACTIVATE_CARD_COST then
  begin
    TWelaEffectPayCostComponent.NOT_PAYED_RESOURCES := TWelaEffectPayCostComponent.DEFAULT_NOT_PAYED_RESOURCES;
  end
  else if RealEventname = GAME_EVENT_DEACTIVATE_CARD_COST then
  begin
    TWelaEffectPayCostComponent.NOT_PAYED_RESOURCES := TWelaEffectPayCostComponent.DEFAULT_NOT_PAYED_RESOURCES + [reCharge, reWood, reGold];
  end
  else if RealEventname.StartsWith(GAME_EVENT_GIVE_GOLD_PREFIX) then
  begin
    RealEventname := RealEventname.Replace(GAME_EVENT_GIVE_GOLD_PREFIX, '');
    Amount := HString.StrToInt(RealEventname, 100);
    for i := 0 to ServerGame.Commanders.Count - 1 do
    begin
      ServerGame.Commanders[i].Eventbus.Trigger(eiResourceTransaction, [ord(reGold), Amount]);
    end;
  end
  else if RealEventname.StartsWith(GAME_EVENT_GIVE_WOOD_PREFIX) then
  begin
    RealEventname := RealEventname.Replace(GAME_EVENT_GIVE_WOOD_PREFIX, '');
    Amount := HString.StrToInt(RealEventname, 100);
    for i := 0 to ServerGame.Commanders.Count - 1 do
    begin
      ServerGame.Commanders[i].Eventbus.Trigger(eiResourceTransaction, [ord(reWood), Amount]);
    end;
  end
  else if RealEventname.StartsWith(GAME_EVENT_SET_GOLD_PREFIX) then
  begin
    RealEventname := RealEventname.Replace(GAME_EVENT_SET_GOLD_PREFIX, '');
    Amount := HString.StrToInt(RealEventname, 100);
    for i := 0 to ServerGame.Commanders.Count - 1 do
    begin
      ServerGame.Commanders[i].Eventbus.Write(eiResourceBalance, [ord(reGold), Amount]);
    end;
  end
  else if RealEventname.StartsWith(GAME_EVENT_SET_WOOD_PREFIX) then
  begin
    RealEventname := RealEventname.Replace(GAME_EVENT_SET_WOOD_PREFIX, '');
    Amount := HString.StrToInt(RealEventname, 100);
    for i := 0 to ServerGame.Commanders.Count - 1 do
    begin
      ServerGame.Commanders[i].Eventbus.Write(eiResourceBalance, [ord(reWood), Amount]);
    end;
  end
  else if RealEventname = GAME_EVENT_SKIP_WARMING then
  begin
    GlobalEventbus.Trigger(eiGameTick, []);
  end;
  Entities.Free;
end;

function TTutorialDirectorServerComponent.OnGameTick : boolean;
begin
  Result := not FFrozen;
end;

function TTutorialDirectorServerComponent.OnNewEntity(NewEntity : RParam) : boolean;
begin
  Result := True;
  if FFrozen then
  begin
    TThinkBlockComponent.Create(NewEntity.AsType<TEntity>);
    NewEntity.AsType<TEntity>.Eventbus.Trigger(eiStand, []);
  end;
end;

function TTutorialDirectorServerComponent.OnReadIncome(CommanderID, Previous : RParam) : RParam;
begin
  if FIncomeDisabled then
      Result := RIncome.Create(0, 0).ToRParam
  else
      Result := Previous;
end;

function TTutorialDirectorServerComponent.OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
begin
  Result := not FNoWaveSpawn;
end;

{ TPvPBotComponent }

function TPvPBotComponent.ClosestEnemyToNexus : RVector2;
var
  AllEntities : TList<TEntity>;
  i : integer;
  NexusPos : RVector2;
begin
  AllEntities := ServerGame.EntityManager.FilterEntities([upUnit, upBuilding], [upBase]);
  for i := AllEntities.Count - 1 downto 0 do
    if AllEntities[i].TeamID <> GetPlayerTeam then
        AllEntities.Delete(i);
  if AllEntities.Count <= 0 then
      Result := RVector2.EMPTY
  else
  begin
    Result := AllEntities[0].Position;
    NexusPos := NexusPositionBot;
    for i := 1 to AllEntities.Count - 1 do
      if NexusPos.Distance(AllEntities[i].Position) < NexusPos.Distance(Result) then
          Result := AllEntities[i].Position;
  end;
end;

function TPvPBotComponent.ClosestSpawnPoint : RVector2;
var
  AllEntities : TList<TEntity>;
  i, BotTeamID : integer;
  NexusPos : RVector2;
begin
  AllEntities := ServerGame.EntityManager.FilterEntities([upBase, upBuilding], []);
  BotTeamID := GetBotTeam;
  for i := AllEntities.Count - 1 downto 0 do
    if AllEntities[i].TeamID <> BotTeamID then
        AllEntities.Delete(i);
  if AllEntities.Count <= 0 then
      Result := RVector2.EMPTY
  else
  begin
    Result := AllEntities[0].Position;
    NexusPos := NexusPositionPlayer;
    for i := 1 to AllEntities.Count - 1 do
      if NexusPos.Distance(AllEntities[i].Position) < NexusPos.Distance(Result) then
          Result := AllEntities[i].Position;
    // add spawnrange offset
    Result := Result + RVector2.Create(30 * WalkingDirectionBot, 0);
  end;
end;

function TPvPBotComponent.ClosestValidSpawnPoint : RVector2;
var
  Enemy : RVector2;
begin
  Result := ClosestSpawnPoint;
  if Result.IsEmpty then Exit(RVector2.EMPTY);
  Enemy := ClosestEnemyToNexus;
  if not Enemy.IsEmpty then
  begin
    if WalkingDirectionBot = -1 then
        Result.x := Max(Result.x, Enemy.x)
    else
        Result.x := Min(Result.x, Enemy.x);
  end;
end;

constructor TPvPBotComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FCards := TUltimateObjectList<TEnhancedCardInfo>.Create;
  FFirst := True;
  FBuildID := -1;
end;

function TPvPBotComponent.CurrentStage : integer;
begin
  Result := Owner.Balance(reTier).AsIntegerDefault(1);
end;

destructor TPvPBotComponent.Destroy;
begin
  FBotAI.Free;
  FCards.Free;
  FDeck.Free;
  inherited;
end;

function TPvPBotComponent.Difficulty(Value : integer) : TPvPBotComponent;
begin
  Result := self;
  FDifficulty := Value;
end;

procedure TPvPBotComponent.DoGameTick;
var
  BuildZone : TBuildZone;
  PrintDebug : boolean;
begin
  if FFirst then
  begin
    FFirst := False;
    for BuildZone in ServerGame.Map.BuildZones.BuildZones.Values do
    begin
      if BuildZone.TeamID = GetBotTeam then
      begin
        FBuildID := BuildZone.ID;
        break;
      end;
    end;
    assert(FBuildID <> -1);
    InitCards();
    case FDifficulty of
      - 1 : FBotAI := TScriptAIInterface.Create(self, HFilepathManager.RelativeToAbsolute(PATH_SCRIPT_AI + 'MegaRootDude.dws'));
      0 : FBotAI := TEasyAI.Create(self);
      1 : FBotAI := TEasyPlusAI.Create(self);
      2 : FBotAI := TMediumAI.Create(self);
      3 : FBotAI := THardAI.Create(self);
      4 : FBotAI := TVeryHardAI.Create(self);
      5 : FBotAI := TInsaneAI.Create(self);
    end;

  end;
  FBotAI.Think;
  PrintDebug := False;
  if PrintDebug then
  begin
    HLog.OpenConsole;
    HLog.ClearConsole;
    FBotAI.PrintDebug;
  end;
end;

function TPvPBotComponent.GetBotTeam : integer;
begin
  Result := Owner.TeamID;
end;

function TPvPBotComponent.GetNexusPosition(TeamID : integer) : RVector2;
var
  Nexus : TEntity;
begin
  if ServerGame.EntityManager.TryGetNexusByTeamID(TeamID, Nexus) then
      Result := Nexus.Position
  else
      Result := RVector2.EMPTY;
end;

function TPvPBotComponent.GetPlayerNumbers : RCurrentUnitStatistic;
begin
  if GetPlayerTeam = 1 then
      Result := FTeam1Numbers
  else
      Result := FTeam2Numbers;
end;

function TPvPBotComponent.GetPlayerTeam : integer;
begin
  if GetBotTeam = 1 then
      Result := 2
  else
      Result := 1;
end;

function TPvPBotComponent.HasFreeSpawnerPoint : boolean;
begin
  Result := not(RandomFreeSpawnerPoint <= -1);
end;

procedure TPvPBotComponent.InitCards;
var
  i : integer;
begin
  FDeck.Free;
  FDeck := Owner.Eventbus.Read(eiEnumerateCommanderAbilities, []).AsType<TList<TCommanderAbility>>;
  for i := 0 to FDeck.Count - 1 do
      FCards.Add(TEnhancedCardInfo.Create(FDeck[i].GetCardInfo));
end;

function TPvPBotComponent.League(Value : integer) : TPvPBotComponent;
begin
  Result := self;
  FLeague := Value;
end;

function TPvPBotComponent.NexusBotSpawnPoint : RVector2;
begin
  Result := NexusPositionBot + RVector2.Create(8.0 * WalkingDirectionBot, 0);
end;

function TPvPBotComponent.NexusPositionBot : RVector2;
begin
  Result := GetNexusPosition(GetBotTeam);
end;

function TPvPBotComponent.NexusPositionPlayer : RVector2;
begin
  Result := GetNexusPosition(GetPlayerTeam);
end;

function TPvPBotComponent.OnGameTick : boolean;
begin
  Result := True;
  DoGameTick;
end;

function TPvPBotComponent.OnNewEntity(NewEntityParam : RParam) : boolean;
var
  NewEntity : TEntity;
  UnitProperties : SetUnitProperty;
begin
  Result := True;
  NewEntity := NewEntityParam.AsType<TEntity>;
  if (NewEntity <> nil) then
  begin
    UnitProperties := NewEntity.UnitProperties;
    if NewEntity.TeamID = 1 then
    begin
      if upDrop in UnitProperties then
          inc(FTeam1Numbers.DropCount)
      else if upSpawner in UnitProperties then
          inc(FTeam1Numbers.SpawnerCount)
      else if upBuildingCard in UnitProperties then
          inc(FTeam1Numbers.BuildingCount);
    end
    else
    begin
      if upDrop in UnitProperties then
          inc(FTeam2Numbers.DropCount)
      else if upSpawner in UnitProperties then
          inc(FTeam2Numbers.SpawnerCount)
      else if upBuildingCard in UnitProperties then
          inc(FTeam2Numbers.BuildingCount);
    end;
  end;
  if assigned(FBotAI) then
      FBotAI.DoNewEntity(NewEntity);
end;

function TPvPBotComponent.PlayerBuildingCount : integer;
begin
  Result := GetPlayerNumbers.BuildingCount;
end;

function TPvPBotComponent.PlayerDropCount : integer;
begin
  Result := GetPlayerNumbers.DropCount;
end;

function TPvPBotComponent.PlayerSpawnerCount : integer;
begin
  Result := GetPlayerNumbers.SpawnerCount;
end;

function TPvPBotComponent.ProgressPercentage : single;
var
  ClosestEnemyToNexusTemp : RVector2;
begin
  ClosestEnemyToNexusTemp := ClosestEnemyToNexus;
  if ClosestEnemyToNexusTemp.IsEmpty then
      ClosestEnemyToNexusTemp := NexusPositionPlayer;
  Result := abs(ClosestEnemyToNexusTemp.x - NexusPositionBot.x) / abs(NexusPositionPlayer.x - NexusPositionBot.x)
end;

function TPvPBotComponent.RandomFreeSpawnerPoint : RIntVector2;
var
  BuildZone : TBuildZone;
  x, y : integer;
  FreePoints : TAdvancedList<RIntVector2>;
begin
  Result := RIntVector2.Create(-1);
  if assigned(Map) and Map.BuildZones.TryGetBuildZone(FBuildID, BuildZone) then
  begin
    FreePoints := TAdvancedList<RIntVector2>.Create;
    for x := 0 to BuildZone.Size.x - 1 do
      for y := 0 to BuildZone.Size.y - 1 do
        if BuildZone.IsFree(RIntVector2.Create(x, y)) then
            FreePoints.Add(RIntVector2.Create(x, y));
    if not FreePoints.IsEmpty then
        Result := FreePoints.random;
    FreePoints.Free;
  end;
end;

function TPvPBotComponent.WalkingDirectionBot : integer;
begin
  Result := sign((NexusPositionPlayer - NexusPositionBot).x);
end;

function TPvPBotComponent.WalkingDirectionPlayer : integer;
begin
  Result := sign((NexusPositionBot - NexusPositionPlayer).x);
end;

{ TPvPBotComponent.TEnhancedCardInfo }

constructor TPvPBotComponent.TEnhancedCardInfo.Create(CardInfo : TCardInfo);
var
  ScenarioInfoData : TScenarioUnitInfo;
  Identifier : string;
begin
  // use gold league as normalized card league (as scenarios created for gold league)
  FCardInfo := CardInfo;
  FChargeCooldown := CardInfo.ChargeCooldown;
  FMaxChargeCount := CardInfo.ChargeCount;
  FCurrentChargeCount := FMaxChargeCount;
  FTier := CardInfo.Techlevel;
  FLegendary := CardInfo.IsLegendary;
  Identifier := CardInfoManager.ScriptFilenameToCardIdentifier(CardInfo.Filename);
  if ScenarioUnitInfoMapping.TryGetValue(Identifier, ScenarioInfoData) then
      FTypes := ScenarioInfoData.UnitTypes
  else
      FTypes := [utDD];
end;

function TPvPBotComponent.TEnhancedCardInfo.IsReady : boolean;
begin
  ApplyCurrentRecharging;
  Result := FCurrentChargeCount > 0;
end;

procedure TPvPBotComponent.TEnhancedCardInfo.ApplyCurrentRecharging;
var
  CurrentTime, LastedTime, RechargeTimeOverhang : int64;
  RechargeCount : integer;
begin
  CurrentTime := TimeManager.GetTimeStamp;

  // time since last charge update
  LastedTime := CurrentTime - FLastRechargeTimeStamp;
  // amount of charges recharged in this time
  RechargeCount := LastedTime div FChargeCooldown;
  // rest of time is the time in the current recharge cycle
  RechargeTimeOverhang := LastedTime mod FChargeCooldown;
  // current charges refill, but capped
  FCurrentChargeCount := Min(FMaxChargeCount, FCurrentChargeCount + RechargeCount);

  // if there is still time in the current recharge cycle, we push the last recharge timestamp back from now to it
  FLastRechargeTimeStamp := CurrentTime - RechargeTimeOverhang;
end;

procedure TPvPBotComponent.TEnhancedCardInfo.Use;
begin
  // first update current charges, so overhang of recharge time won't fill the now used charge instantly
  ApplyCurrentRecharging;
  dec(FCurrentChargeCount);
end;

{ TPvPBotComponent.TBaseAI }

function TPvPBotComponent.TBaseAI.AddFuzzinessToPosition(const Position : RVector2) : RVector2;
begin
  Result := Position + RVector2.Create(-WalkingDirectionBot * random * 5, 5 - random() * 10)
end;

function TPvPBotComponent.TBaseAI.ComputeBacklineUnitPosition(Units : TList<TEntity>) : RVector2;
var
  i : integer;
begin
  Result := RVector2.EMPTY;
  for i := 0 to Units.Count - 1 do
    if Result.IsEmpty or IsLeftBeforeRight(Units[i].Position, Result) then
        Result := Units[i].Position;
end;

function TPvPBotComponent.TBaseAI.ComputeMeleeUnitCount(Units : TList<TEntity>) : integer;
var
  i : integer;
  CardInfo : TCardInfo;
  AUnit : TEntity;
begin
  Result := 0;
  for i := 0 to Units.Count - 1 do
  begin
    AUnit := Units[i];
    CardInfo := CardInfoManager.ScriptFilenameToCardInfo(AUnit.ScriptFile + 'Drop', AUnit.SkinID, AUnit.CardLeague, AUnit.CardLevel);
    if assigned(CardInfo) and not CardInfo.IsRanged then
        Result := Result + 1;
  end;
end;

function TPvPBotComponent.TBaseAI.ComputeNormalizeUnitCount(Units : TList<TEntity>) : single;
var
  i : integer;
  CardInfo : TCardInfo;
  AUnit : TEntity;
begin
  Result := 0.0;
  for i := 0 to Units.Count - 1 do
  begin
    AUnit := Units[i];
    CardInfo := CardInfoManager.ScriptFilenameToCardInfo(AUnit.ScriptFile + 'Drop', AUnit.SkinID, AUnit.CardLeague, AUnit.CardLevel);
    if assigned(CardInfo) then
        Result := Result + 1 / CardInfo.SquadSize;
  end;
end;

function TPvPBotComponent.TBaseAI.ComputeRangedUnitCount(Units : TList<TEntity>) : integer;
var
  i : integer;
  CardInfo : TCardInfo;
  AUnit : TEntity;
begin
  Result := 0;
  for i := 0 to Units.Count - 1 do
  begin
    AUnit := Units[i];
    CardInfo := CardInfoManager.ScriptFilenameToCardInfo(AUnit.ScriptFile + 'Drop', AUnit.SkinID, AUnit.CardLeague, AUnit.CardLevel);
    if assigned(CardInfo) and CardInfo.IsRanged then
        Result := Result + 1;
  end;
end;

function TPvPBotComponent.TBaseAI.ComputeSupporterUnitCount(Units : TList<TEntity>) : integer;
var
  i : integer;
  CardInfo : TCardInfo;
  AUnit : TEntity;
begin
  Result := 0;
  for i := 0 to Units.Count - 1 do
  begin
    AUnit := Units[i];
    CardInfo := CardInfoManager.ScriptFilenameToCardInfo(AUnit.ScriptFile + 'Drop', AUnit.SkinID, AUnit.CardLeague, AUnit.CardLevel);
    if assigned(CardInfo) and CardInfo.IsSupporter then
        Result := Result + 1;
  end;
end;

constructor TPvPBotComponent.TBaseAI.Create(Parent : TPvPBotComponent);
begin
  self.Parent := Parent;
  CurrentIncomeLevel := 0;
  CurrentWood := 1600;
  FCurrentGold := 300;
  WalkingDirectionBot := Parent.WalkingDirectionBot;
end;

procedure TPvPBotComponent.TBaseAI.DoNewEntity(NewEntity : TEntity);
begin
  // noop
end;

function TPvPBotComponent.TBaseAI.GetBotUnitsBeforeFrontmostTower : TList<TEntity>;
var
  FrontmostTowerPosition : RVector2;
begin
  FrontmostTowerPosition := GetFrontmostTowerPosition;
  Result := GetBotUnitsBeforePosition(FrontmostTowerPosition);
end;

function TPvPBotComponent.TBaseAI.GetBotUnitsBeforePosition(const Position : RVector2) : TList<TEntity>;
var
  i : integer;
  BotTeamID : integer;
begin
  Result := ServerGame.EntityManager.FilterEntities([upUnit], [upSapling]);
  BotTeamID := Parent.GetBotTeam;
  for i := Result.Count - 1 downto 0 do
    if (Result[i].TeamID <> BotTeamID) or IsLeftBeforeRight(Position, Result[i].Position) then
        Result.Delete(i);
end;

function TPvPBotComponent.TBaseAI.GetCurrentGhostIncome : integer;
begin
  Result := 0;
end;

function TPvPBotComponent.TBaseAI.GetCurrentGold : integer;
begin
  Result := FCurrentGold + Max(0, FCurrentGhostGold);
end;

function TPvPBotComponent.TBaseAI.GetCurrentIncome : integer;
begin
  Result := INCOME_TABLE[CurrentIncomeLevel];
end;

function TPvPBotComponent.TBaseAI.GetFrontmostTowerPosition : RVector2;
var
  AllEntities : TList<TEntity>;
  i, BotTeamID : integer;
begin
  Result := RVector2.EMPTY;
  BotTeamID := Parent.GetBotTeam;
  AllEntities := ServerGame.EntityManager.FilterEntities([upLanetower, upNexus], []);
  for i := AllEntities.Count - 1 downto 0 do
    if AllEntities[i].TeamID = BotTeamID then
    begin
      if Result.IsEmpty or IsLeftBeforeRight(AllEntities[i].Position, Result) then
          Result := AllEntities[i].Position;
    end;
  AllEntities.Free;
end;

function TPvPBotComponent.TBaseAI.GetOptimalRandomDrop : TEnhancedCardInfo;
var
  FrontUnits : TList<TEntity>;
  MeeleUnitCount, RangedUnitCount, SupporterUnitCount : integer;
  HasLegendary : boolean;
  DropFilter : SetDropFilter;
  BattleFront : RVector2;
  PreferredStage : integer;
begin
  // count units for foremost tower and slight behind
  BattleFront := GetFrontmostTowerPosition + RVector2.Create(-WalkingDirectionBot * 10);
  FrontUnits := GetBotUnitsBeforePosition(BattleFront);
  MeeleUnitCount := ComputeMeleeUnitCount(FrontUnits);
  RangedUnitCount := ComputeRangedUnitCount(FrontUnits);
  SupporterUnitCount := ComputeSupporterUnitCount(FrontUnits);
  HasLegendary := HasAnyLegendaryUnit();
  FrontUnits.Free;
  // if bot has more melee units, prefer to spawn ranged units
  if MeeleUnitCount > RangedUnitCount then
      DropFilter := [dfRanged]
  else
      DropFilter := [dfMelee];
  // maximum two supporter on the frontline
  if SupporterUnitCount <= 1 then
      DropFilter := DropFilter + [dfSupporter];
  if assigned(NextDrop) then
      PreferredStage := NextDrop.Tier
  else
      PreferredStage := -1;
  Result := GetRandomFilteredDrop(not HasLegendary, DropFilter, PreferredStage);
  // not matching drop found, drop stage filter
  if not assigned(Result) then
      Result := GetRandomFilteredDrop(not HasLegendary, DropFilter, -1);
  // if still no matching drop found, drop all filter and get random
  if not assigned(Result) then
      Result := GetRandomFilteredDrop(not HasLegendary, DROP_FILTER_ALL, -1);
end;

function TPvPBotComponent.TBaseAI.GetRandomFilteredDrop(AllowLegendary : boolean; DropType : SetDropFilter; DropStage : integer) : TEnhancedCardInfo;
var
  Card : TEnhancedCardInfo;
begin
  Result := nil;
  Parent.FCards.Shuffle;
  for Card in Parent.FCards do
  begin
    // match filters
    if Card.CardInfo.IsDrop and Card.IsReady
      and ((Card.Tier = DropStage) or ((DropStage = -1) and (Card.Tier <= Parent.CurrentStage)))
      and (not Card.Legendary or AllowLegendary) then
    begin
      // previous filter all matched, if drop type also match, return card info
      if (DropType = DROP_FILTER_ALL) or
        ((((dfRanged in DropType) and Card.CardInfo.IsRanged) or
        ((dfMelee in DropType) and not Card.CardInfo.IsRanged)) and
        ((dfSupporter in DropType) or not Card.CardInfo.IsSupporter)) then
          Exit(Card);
    end;
  end;
end;

function TPvPBotComponent.TBaseAI.GetRandomSpawner :
  TEnhancedCardInfo;
var
  Card : TEnhancedCardInfo;
begin
  Result := nil;
  Parent.FCards.Shuffle;
  for Card in Parent.FCards do
  begin
    if Card.CardInfo.IsSpawner then
        Result := Card;
  end;
end;

function TPvPBotComponent.TBaseAI.HasAnyLegendaryUnit : boolean;
// var
// i : integer;
// BotTeamID : integer;
// Entities : TList<Entity>;
begin
  Result := Parent.Owner.HasUnitProperty(upHasLegendaryUnit);
  // Result := False;
  // Entities := ServerGame.EntityManager.FilterEntities([upLegendary]);
  // BotTeamID := Parent.GetBotTeam;
  // for i := Entities.Count - 1 downto 0 do
  // if (Result[i].TeamID = BotTeamID) then
  // Exit(True)
end;

function TPvPBotComponent.TBaseAI.IsLeftBeforeRight(const Left, Right : RVector2) : boolean;
begin
  Result := WalkingDirectionBot = sign(Left.x - Right.x);
end;

function TPvPBotComponent.TBaseAI.PlaceDrop(Drop : TEnhancedCardInfo; DropPoint : RVector2) : boolean;
var
  IsAtlas : boolean;
begin
  Result := False;
  if not DropPoint.IsEmpty then
  begin
    IsAtlas := Drop.CardInfo.Filename.Contains('Atlas');
    if IsAtlas then inc(AtlasSpawns);
    ServerGame.ServerEntityManager.SpawnUnit(DropPoint, RVector2.Create(Parent.WalkingDirectionBot, 0),
      Drop.CardInfo.Filename, Drop.CardInfo.League, Drop.CardInfo.Level, Parent.GetBotTeam, Parent.Owner.ID, nil, nil,
      procedure(PreprocessedEntity : TEntity)
      begin
        PreprocessedEntity.SkinID := Drop.CardInfo.SkinID;
        PreprocessedEntity.Blackboard.SetValue(eiSkinIdentifier, [], Drop.CardInfo.SkinID);
        if IsAtlas then
            PreprocessedEntity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardTimesPlayed), AtlasSpawns);
      end);
    SpentGold(Drop.CardInfo.GoldCost);
    Drop.Use;
    inc(BotDropCount);
    Result := True;
  end;
end;

procedure TPvPBotComponent.TBaseAI.PlaceSpawner;
var
  SpawnerPoint : RIntVector2;
begin
  if Parent.HasFreeSpawnerPoint then
  begin
    SpawnerPoint := Parent.RandomFreeSpawnerPoint;
    ServerGame.ServerEntityManager.SpawnSpawner(Parent.FBuildID, SpawnerPoint, NextSpawner.CardInfo.Filename, Parent.GetBotTeam, -1, nil, nil,
      procedure(PreprocessedEntity : TEntity)
      begin
        PreprocessedEntity.SkinID := NextSpawner.CardInfo.SkinID;
        PreprocessedEntity.Blackboard.SetValue(eiSkinIdentifier, [], NextSpawner.CardInfo.SkinID);
      end);
    SpentWood(NextSpawner.CardInfo.WoodCost);
    inc(BotSpawnerCount);
    NextSpawner.Use;
    NextSpawner := nil;
  end;
end;

procedure TPvPBotComponent.TBaseAI.PrintDebug;
var
  i : integer;
begin
  Parent.FCards.Sort(TComparer<TEnhancedCardInfo>.Construct(
    function(const Left, Right : TEnhancedCardInfo) : integer
    begin
      Result := string.Compare(Left.CardInfo.Filename, Right.CardInfo.Filename);
    end));
  WriteLn('Bot ' + self.ClassName);
  WriteLn('=================');
  WriteLn('');
  WriteLn('Current Gold: ', CurrentGold);
  WriteLn('Current Wood: ', CurrentWood);
  WriteLn('Current Income: ', GetCurrentIncome);
  for i := 0 to Parent.FCards.Count - 1 do
      WriteLn(Parent.FCards[i].CardInfo.Filename, ' IsReady: ', Parent.FCards[i].IsReady);
end;

procedure TPvPBotComponent.TBaseAI.SpentGold(GoldAmount : integer);
begin
  if GoldAmount > FCurrentGold then
  begin
    CurrentWood := CurrentWood + FCurrentGold;
    GoldAmount := GoldAmount - FCurrentGold;
    FCurrentGold := 0;
    FCurrentGhostGold := FCurrentGhostGold - GoldAmount;
  end
  else
  begin
    FCurrentGold := FCurrentGold - GoldAmount;
    CurrentWood := CurrentWood + GoldAmount;
  end;
end;

procedure TPvPBotComponent.TBaseAI.SpentWood(WoodAmount : integer);
begin
  CurrentWood := CurrentWood - WoodAmount;
  TotalWoodSpent := TotalWoodSpent + WoodAmount;
  CurrentIncomeLevel := 0;
  // determine bot income using total wood spent (use same rules as player income upgrade)
  while (CurrentIncomeLevel < MAX_INCOME_LEVEL) and (TotalWoodSpent > INCOME_LEVEL_WOOD_SPENT[CurrentIncomeLevel]) do
      inc(CurrentIncomeLevel);
end;

procedure TPvPBotComponent.TBaseAI.Think;
begin
  FCurrentGold := FCurrentGold + GetCurrentIncome;
  FCurrentGhostGold := FCurrentGhostGold + GetCurrentGhostIncome;
  if not assigned(NextSpawner) then
      NextSpawner := GetRandomSpawner;
  if not assigned(NextDrop) then
      NextDrop := GetRandomFilteredDrop(not HasAnyLegendaryUnit, DROP_FILTER_ALL);
end;

{ TPvPBotComponent.TEasyAI }

constructor TPvPBotComponent.TEasyAI.Create(Parent : TPvPBotComponent);
begin
  inherited;
  FCurrentGold := INITIAL_GOLD;
  DelayTimer := TTimer.CreateAndStart(4000 + random(1000));
  if Parent.PlayerDropCount <= 0 then
  begin
    DelayTimer.Interval := 60000 + random(10000);
    DelayTimer.Start;
  end;
end;

destructor TPvPBotComponent.TEasyAI.Destroy;
begin
  DelayTimer.Free;
  inherited;
end;

procedure TPvPBotComponent.TEasyAI.DoNewEntity(NewEntity : TEntity);
var
  UnitProperties : SetUnitProperty;
begin
  inherited;
  if (NewEntity <> nil) then
  begin
    UnitProperties := NewEntity.UnitProperties;
    if (NewEntity.TeamID = Parent.GetPlayerTeam) and (upDrop in UnitProperties) then
    begin
      // first time player spawns a unit -> bot also spawns a unit but with middle delay
      if (Parent.PlayerDropCount <= 1) then
      begin
        DelayTimer.Interval := 4000 + random(1000);
        DelayTimer.Start;
      end
      else if (Parent.PlayerDropCount > BotDropCount) and (DelayTimer.Interval > 10000) then
      begin
        DelayTimer.Interval := 1000 + random(2000);
        DelayTimer.Start;
      end;
    end;
  end;
end;

function TPvPBotComponent.TEasyAI.GetCurrentIncome : integer;
begin
  Result := round(inherited GetCurrentIncome * (1 - Parent.ProgressPercentage * 0.75));
end;

procedure TPvPBotComponent.TEasyAI.Think;
var
  DropPoint : RVector2;
begin
  inherited;
  if DelayTimer.Expired and (NextDrop.CardInfo.GoldCost <= CurrentGold) then
  begin
    if BotDropCount <= 3 then
        DropPoint := Parent.NexusBotSpawnPoint
    else
        DropPoint := Parent.ClosestValidSpawnPoint;

    if not DropPoint.IsEmpty then
    begin
      DropPoint := AddFuzzinessToPosition(DropPoint);
      PlaceDrop(NextDrop, DropPoint);
    end;

    // bot wait long if he has already spawned more units as player, else short
    if BotDropCount >= Parent.PlayerDropCount then
    begin
      DelayTimer.Interval := 15000 + random(5000);
      DelayTimer.Start;
    end
    else
    begin
      DelayTimer.Interval := 1000 + random(2000);
      DelayTimer.Start;
    end;
  end;

  if assigned(NextSpawner) and (BotSpawnerCount < Parent.PlayerSpawnerCount - 1) and (NextSpawner.CardInfo.WoodCost <= CurrentWood) and Parent.HasFreeSpawnerPoint then
      PlaceSpawner;
end;

{ TPvPBotComponent.THardAI }

function TPvPBotComponent.THardAI.CurrentSaveThreshold : integer;
begin
  Result := 300;
end;

function TPvPBotComponent.THardAI.GetCurrentIncome : integer;
begin
  Result := round(inherited GetCurrentIncome * INCOME_FACTOR);
end;

{ TPvPBotComponent.TVeryHardAI }

function TPvPBotComponent.TVeryHardAI.CurrentSaveThreshold : integer;
begin
  Result := round(Game.GoldCap) - 100;
end;

procedure TPvPBotComponent.TVeryHardAI.Think;
var
  FrontUnits : TList<TEntity>;
  FrontPower : single;
  BacklinePosition, ClosestSpawnPoint, DropPosition : RVector2;
begin
  inherited;
  // place spawner whenever possible
  if assigned(NextSpawner) and (NextSpawner.CardInfo.WoodCost <= CurrentWood) and Parent.HasFreeSpawnerPoint then
      PlaceSpawner;

  // when dropmode is on, bot will drop units with some delay until gold is spent
  if DropMode then
  begin
    if DropDelayTimer.Expired then
    begin
      DropDelayTimer.Interval := 500 + RandomRange(-150, +150);
      DropDelayTimer.Start;
      BacklinePosition := GetFrontmostTowerPosition;
      if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) then
      begin
        DropPosition := AddFuzzinessToPosition(BacklinePosition);
        NextDrop := GetOptimalRandomDrop;
        if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) then
            PlaceDrop(NextDrop, DropPosition);
        NextDrop := GetRandomFilteredDrop(not HasAnyLegendaryUnit, DROP_FILTER_ALL);
      end;
      if assigned(NextDrop) and (CurrentGold < NextDrop.CardInfo.GoldCost) then
          DropMode := False;
    end;
  end
  // else determine current strategie, support current push or save money for next push
  else if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) then
  begin
    FrontUnits := GetBotUnitsBeforeFrontmostTower;
    FrontPower := ComputeNormalizeUnitCount(FrontUnits);

    if FrontPower >= 3.0 then
    // bot has enough power to attack, support attack by drop more units
    begin
      // ensure bot will only drop units in own drop zone ()
      BacklinePosition := ComputeBacklineUnitPosition(FrontUnits) + RVector2.Create(5, 0) * -WalkingDirectionBot;
      ClosestSpawnPoint := GetFrontmostTowerPosition + RVector2.Create(30, 0) * WalkingDirectionBot;
      if IsLeftBeforeRight(BacklinePosition, ClosestSpawnPoint) then
          BacklinePosition := ClosestSpawnPoint;
      BacklinePosition := AddFuzzinessToPosition(BacklinePosition);
      NextDrop := GetOptimalRandomDrop;
      if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) then
          PlaceDrop(NextDrop, BacklinePosition);
    end
    else
    // bot will save money, until a little wave can spawned
    begin
      if CurrentGold > CurrentSaveThreshold then
      begin
        DropMode := True;
        DropDelayTimer.Interval := 500 + RandomRange(-150, +150);
        DropDelayTimer.Start;
      end;
    end;
  end;
end;

{ TPvPBotComponent.TMedium }

function TPvPBotComponent.TMediumAI.GetCurrentIncome : integer;
begin
  Result := round(inherited GetCurrentIncome * INCOME_FACTOR);
end;

procedure TPvPBotComponent.TMediumAI.Think;
var
  BacklinePosition, DropPosition : RVector2;
begin
  inherited;
  // place spawner whenever possible
  if assigned(NextSpawner) and (NextSpawner.CardInfo.WoodCost <= CurrentWood) and Parent.HasFreeSpawnerPoint then
      PlaceSpawner;

  // when dropmode is on, bot will drop units with some delay until gold is spent
  if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) and DropDelayTimer.Expired then
  begin
    DropDelayTimer.Interval := 500 + RandomRange(-150, +150);
    DropDelayTimer.Start;
    BacklinePosition := GetFrontmostTowerPosition;
    if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) then
    begin
      DropPosition := AddFuzzinessToPosition(BacklinePosition);
      NextDrop := GetOptimalRandomDrop;
      if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) then
          PlaceDrop(NextDrop, DropPosition);
      NextDrop := GetRandomFilteredDrop(not HasAnyLegendaryUnit, DROP_FILTER_ALL);
    end;
  end;
end;

{ TPvPBotComponent.TEasyPlusAI }

constructor TPvPBotComponent.TEasyPlusAI.Create(Parent : TPvPBotComponent);
begin
  inherited;
  DropDelayTimer.Interval := DROP_DELAY;
  DropDelayTimer.Start;
  FCurrentGold := INITIAL_GOLD;
  CurrentWood := INITIAL_WOOD;
end;

function TPvPBotComponent.TEasyPlusAI.GetCurrentIncome : integer;
begin
  Result := round(inherited GetCurrentIncome * (0.4 + (1 - Parent.ProgressPercentage) * 0.3));
end;

procedure TPvPBotComponent.TEasyPlusAI.Think;
var
  DropPosition : RVector2;
begin
  inherited;
  // place spawner whenever possible
  if assigned(NextSpawner) and (NextSpawner.CardInfo.WoodCost <= CurrentWood) and Parent.HasFreeSpawnerPoint then
      PlaceSpawner;

  // when dropmode is on, bot will drop units with some delay until gold is spent
  if assigned(NextDrop) and (CurrentGold >= NextDrop.CardInfo.GoldCost) and DropDelayTimer.Expired then
  begin
    if BotDropCount <= 3 then
        DropPosition := Parent.NexusBotSpawnPoint
    else
        DropPosition := Parent.ClosestValidSpawnPoint;

    if not DropPosition.IsEmpty then
    begin
      DropDelayTimer.Interval := 1000 + round(2000);
      DropDelayTimer.Start;
      DropPosition := AddFuzzinessToPosition(DropPosition);
      PlaceDrop(NextDrop, DropPosition);
    end;
  end;
end;

{ TPvPBotComponent.TEnhanceBaseAI }

constructor TPvPBotComponent.TEnhanceBaseAI.Create(Parent : TPvPBotComponent);
begin
  inherited;
  DropDelayTimer := TTimer.Create(500);
end;

destructor TPvPBotComponent.TEnhanceBaseAI.Destroy;
begin
  DropDelayTimer.Free;
  inherited;
end;

{ TCommanderAbility }

function TCommanderAbility.CanUseAbility(const Targets : ACommanderAbilityTarget; Mode : integer) : boolean;
var
  TargetGroup : SetComponentGroup;
begin
  if length(FMultiModes) > Mode then
      TargetGroup := FMultiModes[Mode]
  else
      TargetGroup := ComponentGroup;
  Result := Eventbus.Read(eiCanUseAbility, [Targets.ToRParam], TargetGroup).AsBoolean;
end;

function TCommanderAbility.CardInfo(CardInfo : TCardInfo) : TCommanderAbility;
begin
  Result := self;
  FCardInfo := CardInfo;
end;

function TCommanderAbility.ChargeGroup(ChargeGroup : TArray<byte>) : TCommanderAbility;
begin
  Result := self;
  FChargeGroup := ByteArrayToComponentGroup(ChargeGroup);
end;

function TCommanderAbility.CurrentCharges : integer;
begin
  Result := Owner.Balance(reCharge, ComponentGroup).AsInteger;
end;

function TCommanderAbility.IsMultiMode(MultiModes : TArray<byte>) : TCommanderAbility;
var
  i : integer;
begin
  Result := self;
  setLength(FMultiModes, length(MultiModes));
  for i := 0 to length(MultiModes) - 1 do
      FMultiModes[i] := [MultiModes[i]];
end;

function TCommanderAbility.IsReady : boolean;
begin
  Result := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBoolean;
end;

function TCommanderAbility.MaxCharges : integer;
begin
  Result := Owner.Cap(reCharge, ComponentGroup).AsInteger;
end;

function TCommanderAbility.ModeCount : integer;
begin
  Result := Min(1, length(FMultiModes));
end;

function TCommanderAbility.OnEnumerateCommanderAbilities(Previous : RParam) : RParam;
var
  List : TList<TCommanderAbility>;
begin
  List := Previous.AsType<TList<TCommanderAbility>>;
  if not assigned(List) then
      List := TList<TCommanderAbility>.Create;
  List.Add(self);
  Result := List;
end;

procedure TCommanderAbility.UseAbility(const Targets : ACommanderAbilityTarget; Mode : integer);
var
  TargetGroup : SetComponentGroup;
begin
  if length(FMultiModes) > Mode then
      TargetGroup := FMultiModes[Mode]
  else
      TargetGroup := ComponentGroup;
  Eventbus.Trigger(eiUseAbility, [Targets.ToRParam], TargetGroup);
end;

{ TPvPBotComponent.TScriptAI }

constructor TPvPBotComponent.TScriptAI.Create(Parent : TPvPBotComponent; ScriptFileName : string);
var
  Card : TCommanderAbility;
  CardInfo : TCardInfo;
begin
  inherited Create(Parent);
  FAIScript := ScriptManager.CompileScriptFromFile(ScriptFileName);
  FAIScript.RunMain;
  FAIScript.ExecuteFunction('Prepare', [self], nil);
  FMinimumGoldCost := integer.MaxValue;
  FMinimumWoodCost := integer.MaxValue;
  // determine minimum gold and minimum wood cost
  for Card in Parent.Deck do
  begin
    CardInfo := Card.GetCardInfo;
    if CardInfo.IsSpawner then
        FMinimumWoodCost := Min(FMinimumWoodCost, CardInfo.WoodCost);
    if CardInfo.CardType in [ctDrop, ctSpell, ctBuilding] then
        FMinimumGoldCost := Min(FMinimumGoldCost, CardInfo.GoldCost);
  end;
end;

destructor TPvPBotComponent.TScriptAI.Destroy;
begin
  FAIScript.Free;
  inherited;
end;

function TPvPBotComponent.TScriptAI.EnsurePositionIsInDropZone(Position : RVector2) : RVector2;
var
  ClosestSpawnPoint : RVector2;
begin
  ClosestSpawnPoint := Parent.ClosestSpawnPoint;
  if IsLeftBeforeRight(Position, ClosestSpawnPoint) then
      Result := ClosestSpawnPoint
  else
      Result := Position;
end;

function TPvPBotComponent.TScriptAI.GetCardByName(CardName : string) : TCommanderAbility;
var
  Card : TCommanderAbility;
begin
  Result := nil;
  for Card in Parent.Deck do
  begin
    if Card.GetCardInfo.Filename.ToLowerInvariant.Contains(CardName.ToLowerInvariant) then
    begin
      Result := Card;
      Exit;
    end;
  end;
  if not assigned(Result) then
      raise ENotFoundException.CreateFmt('TPvPBotComponent.TScriptAI.GetCardByName: No card with name "%s" was found in deck.', [CardName]);
end;

function TPvPBotComponent.TScriptAI.GetFrontmostUnitByName(UnitName : string) : TEntity;
var
  Units : TList<TEntity>;
  AUnit : TEntity;
  CardInfo : TCardInfo;
  BotTeamID : integer;
begin
  Result := nil;
  Units := ServerGame.EntityManager.FilterEntities([upUnit], [upSapling]);
  BotTeamID := Parent.GetBotTeam;
  for AUnit in Units do
  begin
    if (AUnit.TeamID = BotTeamID) and string.EndsText(UnitName, AUnit.ScriptFile) then
    begin
      if not assigned(Result) or IsLeftBeforeRight(AUnit.Position, Result.Position) then
          Result := AUnit;
    end;
  end;
end;

function TPvPBotComponent.TScriptAI.GetUnitCountByName(UnitName : string) : integer;
var
  Units : TList<TEntity>;
  AUnit : TEntity;
  CardInfo : TCardInfo;
  BotTeamID : integer;
begin
  Result := 0;
  Units := ServerGame.EntityManager.FilterEntities([upUnit], [upSapling]);
  BotTeamID := Parent.GetBotTeam;
  for AUnit in Units do
  begin
    if (AUnit.TeamID = BotTeamID) and string.EndsText(UnitName, AUnit.ScriptFile) then
        inc(Result);
  end;
end;

function TPvPBotComponent.TScriptAI.IsTargetForSpellValid(Spell : TCommanderAbility; Target : TEntity) : boolean;
begin
  Result := Spell.CanUseAbility([RCommanderAbilityTarget.Create(Target)]);
end;

procedure TPvPBotComponent.TScriptAI.Think;
begin
  FCurrentGold := Trunc(Parent.Owner.Balance(reGold).AsSingle);
  CurrentWood := Trunc(Parent.Owner.Balance(reWood).AsSingle);
  if (CurrentGold >= FMinimumGoldCost) or (CurrentWood >= FMinimumWoodCost) then
      FAIScript.ExecuteFunction('Think', [self], nil);
end;

procedure TPvPBotComponent.TScriptAI.UseDropCard(Card : TCommanderAbility; DropPoint : RVector2);
begin
  assert(Card.GetCardInfo.IsDrop or Card.GetCardInfo.IsBuilding);
  Card.UseAbility([RCommanderAbilityTarget.Create(DropPoint)]);
end;

procedure TPvPBotComponent.TScriptAI.UseDropCardBehind(Card : TCommanderAbility; AUnit : TEntity; Distance : single);
var
  DropPosition : RVector2;
begin
  DropPosition := AUnit.Position - (RVector2.Create(Distance, 0) * WalkingDirectionBot);
  DropPosition := EnsurePositionIsInDropZone(DropPosition);
  DropPosition := AddFuzzinessToPosition(DropPosition);
  UseDropCard(Card, DropPosition);
end;

procedure TPvPBotComponent.TScriptAI.UseSingleTargetSpell(Spell : TCommanderAbility; Target : TEntity);
begin
  assert(Spell.GetCardInfo.IsSpell);
  Spell.UseAbility([RCommanderAbilityTarget.Create(Target)]);
end;

procedure TPvPBotComponent.TScriptAI.UseSpawnerCard(Card : TCommanderAbility);
var
  SpawnerPoint : RIntVector2;
begin
  if Parent.HasFreeSpawnerPoint then
  begin
    assert(Card.GetCardInfo.IsSpawner);
    SpawnerPoint := Parent.RandomFreeSpawnerPoint;
    assert(Card.CanUseAbility([RCommanderAbilityTarget.CreateBuildTarget(Parent.BuildID, SpawnerPoint)]));
    Card.UseAbility([RCommanderAbilityTarget.CreateBuildTarget(Parent.BuildID, SpawnerPoint)]);
    inc(BotSpawnerCount);
  end;
end;

{ TPvPBotComponent.TInsaneAI }

constructor TPvPBotComponent.TInsaneAI.Create(Parent : TPvPBotComponent);
begin
  inherited;
  FCurrentGhostGold := GHOST_GOLD_DELAY_AMOUNT;
end;

function TPvPBotComponent.TInsaneAI.CurrentSaveThreshold : integer;
begin
  Result := round(Game.GoldCap);
end;

function TPvPBotComponent.TInsaneAI.GetCurrentGhostIncome : integer;
begin
  Result := round(inherited GetCurrentIncome * GHOST_GOLD_INCOME_FACTOR);
end;

initialization

ScriptManager.ExposeClass(TServerEntityManagerComponent);
ScriptManager.ExposeClass(TServerPrimaryTargetComponent);
ScriptManager.ExposeClass(TServerCardPlayStatisticsComponent);

ScriptManager.ExposeClass(TScenarioComponent);
ScriptManager.ExposeClass(TScenarioDirectorComponent);
ScriptManager.ExposeClass(TSurvivalScenarioDirectorComponent);
ScriptManager.ExposeClass(TScriptAIInterface);

ScriptManager.ExposeClass(TTutorialDirectorServerComponent);

ScriptManager.ExposeClass(TCommanderAbility);

ScriptManager.ExposeClass(TServerSandboxComponent);
ScriptManager.ExposeClass(TServerSandboxCommandComponent);

ScriptManager.ExposeClass(TBuffTakenDamageMultiplierComponent);
ScriptManager.ExposeClass(TBuffLifeLeechComponent);
ScriptManager.ExposeClass(TBuffDamageMultiplierComponent);
ScriptManager.ExposeClass(TBuffCapDamageByHealthComponent);

ScriptManager.ExposeClass(TLinkBrainComponent);

end.
