unit BaseConflict.Constants;

interface

uses
  Generics.Collections,
  SysUtils,
  Engine.Helferlein,
  Engine.Math,
  Engine.Script,
  BaseConflict.Api,
  BaseConflict.Constants.Cards;

const
  /// /////////////////////////////////////////////////////////////////////////
  /// Paths
  /// /////////////////////////////////////////////////////////////////////////

  PATH_MAP                     = '\Maps\';
  PATH_SCRIPT                  = '\Scripts\';
  PATH_SCRIPT_AI               = PATH_SCRIPT + '\AI\';
  PATH_SCRIPT_UNITS            = PATH_SCRIPT + 'HelperScripts\';
  PATH_SCRIPT_ENVIRONMENT      = PATH_SCRIPT + 'Environment\';
  PATH_SCRIPT_SCENARIO         = PATH_SCRIPT + 'Scenarios\';
  PATH_SCRIPT_SCENARIO_MUTATOR = PATH_SCRIPT_SCENARIO + 'Mutators\';

  /// ///////////////////////////////////////////////////////////////////////////
  // General
  /// ///////////////////////////////////////////////////////////////////////////

  SPATIALEPSILON = 0.1;

  GAMESETTINGSFILE = '\Settings.ini';
var
  CONNECTIONSETTINGSFILE : string = '\SettingsConnection.ini';
const
  GAMEDEBUGSETTINGSFILE         = '\DebugSettings.ini';
  CLIENTSETTINGSFILE            = '\ClientSettings.ini';
  GAMESERVER_SETTINGSFILE       = '\ServerSettings.ini';
  GAMESERVER_DEBUG_SETTINGSFILE = '\DebugServerSettings.ini';
  MATCHMAKINGSETTINGSFILE       = '\ServerSettings.ini';

  SCRIPT_INHERIT_VAR_NAME           = 'InheritsFrom';
  SCRIPT_INHERIT_PRECEDING_VAR_NAME = 'InheritsFromPreceding';

  UNITSYNCINTERVAL = 3000;

  GAME_TICK_DURATION      = 1000;
  GAME_WARMING_DURATION   = 10000;
  MAP_FILEEXTENSION       = '.bcm';
  CLIENTMAP_FILEEXTENSION = '.bcc';

  PATHFINDING_TILE_SIZE = 0.8; // 1.1 // Size of Tile in worldspace, will be square, e.g. 1.1 = 1.1 x 1.1
  /// <summary> Max length (in worldspace) of a computed path. Pathfinding will stop if a path with length >= is computed. </summary>
  PATHFINDING_MAX_COMPUTED_PATH_LENGTH = 15;

  BUILDGRID_SIZE : RIntVector2 = (x : 8; y : 3);
  BUILDGRID_SLOTS              = 20;

  // AI

  THINK_TIME_INTERVAL = 250;

  // Game

  PVE_TEAM_ID = 5;

  /// /////////////////////////////////////////////////////////////////////////
  /// Game statistic events
  /// Prefixes are used in combination with the script file names
  /// /////////////////////////////////////////////////////////////////////////

  GSE_UNIT_SPAWN_PREFIX        = 'unit_spawns_';
  GSE_UNIT_KILL_PREFIX         = 'unit_kills_';
  GSE_UNIT_DEATH_PREFIX        = 'unit_deaths_';
  GSE_WELA_TRIGGER_PREFIX      = 'wela_triggers_';
  GSE_WELA_TARGET_PREFIX       = 'wela_targets_';
  GSE_WELA_SPAWN_PREFIX        = 'wela_spawns_';
  GSE_WELA_KILL_PREFIX         = 'wela_kills_';
  GSE_WELA_DEATH_PREFIX        = 'wela_deaths_';
  GSE_WELA_DURATION_PREFIX     = 'wela_duration_';
  GSE_WELA_GAIN_DAMAGE_PREFIX  = 'wela_gain_damage_';
  GSE_WELA_DEALT_DAMAGE_PREFIX = 'wela_dealt_damage_';
  GSE_CARD_PLAY_PREFIX         = 'card_play_';
  GSE_CARD_PLAY_COLOR_PREFIX   = 'card_play_color_';

  GSE_GLOBAL_KILLS       = 'global_kills';
  GSE_GLOBAL_INSTAKILLS  = 'global_instakills';
  GSE_GLOBAL_GAIN_DAMAGE = 'global_gain_damage';
  GSE_GLOBAL_DEATHS      = 'global_deaths';
  GSE_GLOBAL_INSTADEATHS = 'global_instadeaths';
  GSE_GLOBAL_SPAWNS      = 'global_spawns';
  GSE_GLOBAL_SPAWNERS    = 'global_spawners';
  GSE_GLOBAL_DROPS       = 'global_drops';
  GSE_GLOBAL_BUILDINGS   = 'global_buildings';
  GSE_GLOBAL_SPELLS      = 'global_spells';

  GAME_STATISTIC_EVENTS : array [0 .. 22] of string = (GSE_UNIT_SPAWN_PREFIX, GSE_UNIT_KILL_PREFIX, GSE_UNIT_DEATH_PREFIX,
    GSE_WELA_TRIGGER_PREFIX, GSE_WELA_TARGET_PREFIX, GSE_WELA_SPAWN_PREFIX, GSE_WELA_KILL_PREFIX, GSE_WELA_DEATH_PREFIX,
    GSE_WELA_DURATION_PREFIX, GSE_WELA_GAIN_DAMAGE_PREFIX, GSE_WELA_DEALT_DAMAGE_PREFIX, GSE_CARD_PLAY_PREFIX,
    GSE_GLOBAL_KILLS, GSE_GLOBAL_INSTAKILLS, GSE_GLOBAL_GAIN_DAMAGE, GSE_GLOBAL_DEATHS, GSE_GLOBAL_INSTADEATHS, GSE_GLOBAL_SPAWNS,
    GSE_GLOBAL_SPAWNERS, GSE_GLOBAL_DROPS, GSE_GLOBAL_BUILDINGS, GSE_GLOBAL_SPELLS, GSE_CARD_PLAY_COLOR_PREFIX);

  /// /////////////////////////////////////////////////////////////////////////
  /// ZoneNames
  /// Prefixes are used in combination with the team ID (NAME_PREFIX will be NAME_PREFIX{TEAM_ID})
  /// /////////////////////////////////////////////////////////////////////////

  ZONE_CAMERA = 'Camera';
  ZONE_WALK   = 'Walkzone';
  ZONE_DROP   = 'Drop';

  /// ///////////////////////////////////////////////////////////////////////////
  // Predefined game events
  /// ///////////////////////////////////////////////////////////////////////////

  GAME_EVENT_TECH_LEVEL_2            = 'tech2';
  GAME_EVENT_TECH_LEVEL_3            = 'tech3';
  GAME_EVENT_SHOWDOWN                = 'showdown';
  GAME_EVENT_SPAWNER_PLACED          = 'spawner_placed';
  GAME_EVENT_DROP_PLACED             = 'drop_placed';
  GAME_EVENT_SPELL_PLACED            = 'spell_placed';
  GAME_EVENT_SPAWNER_SELECTED        = 'spawner_selected';
  GAME_EVENT_DROP_SELECTED           = 'drop_selected';
  GAME_EVENT_SPELL_SELECTED          = 'spell_selected';
  GAME_EVENT_CARD_DESELECTED         = 'card_deselected';
  GAME_EVENT_TUTORIAL_HINT_CONFIRMED = 'tutorial_hint_confirmed';
  GAME_EVENT_CLIENT_READY            = 'client_ready';
  GAME_EVENT_GAME_TICK               = 'game_tick';
  GAME_EVENT_GAME_TICK_FIRST         = 'game_tick_first';
  GAME_EVENT_SKIP_WARMING            = 'skip_warming';
  GAME_EVENT_TOWER_CAPTURED          = 'tower_captured';
  GAME_EVENT_FREEZE_GAME             = 'freeze_game';
  GAME_EVENT_UNFREEZE_GAME           = 'unfreeze_game';
  GAME_EVENT_ACTIVATE_SPAWNER        = 'activate_spawner';
  GAME_EVENT_DEACTIVATE_SPAWNER      = 'deactivate_spawner';
  GAME_EVENT_ACTIVATE_INCOME         = 'activate_income';
  GAME_EVENT_DEACTIVATE_INCOME       = 'deactivate_income';
  GAME_EVENT_SPAWNER_JUMP            = 'spawner_jump';
  GAME_EVENT_REFRESH_GOLD            = 'refresh_gold';
  GAME_EVENT_REFRESH_CHARGES         = 'refresh_charges';
  GAME_EVENT_ACTIVATE_CARD_COST      = 'activate_card_cost';
  GAME_EVENT_DEACTIVATE_CARD_COST    = 'deactivate_card_cost';
  GAME_EVENT_GIVE_GOLD_PREFIX        = 'give_gold_';
  GAME_EVENT_GIVE_WOOD_PREFIX        = 'give_wood_';
  GAME_EVENT_SET_GOLD_PREFIX         = 'set_gold_';
  GAME_EVENT_SET_WOOD_PREFIX         = 'set_wood_';

  /// ///////////////////////////////////////////////////////////////////////////
  // Network
  /// ///////////////////////////////////////////////////////////////////////////

type

  EnumNetworkSender = (nsNone, nsClient, nsServer);

const

  NET_ASSIGNED_PLAYER                = 1;
  NET_HELLO_SERVER                   = 2;
  NET_NEW_ENTITY                     = 3;
  NET_RECONNECT                      = 4;
  NET_RECONNECT_RESULT               = 5;
  NET_CLIENT_ENTER_CORE              = 6;
  NET_SERVER_FINISHED_SEND_GAME_DATA = 7;
  NET_SERVER_GAME_ABORTED            = 8;
  NET_CLIENT_RAGE_QUIT               = 9;
  NET_CLIENT_READY                   = 10;
  NET_MY_SESSION_ID                  = 21; // Clsient -> Broker
  NET_NEW_DATA                       = 22; // Masterserver -> Broker -> Client, data send from server to client using the broker as backpath
  NET_EVENT                          = 31;
  NET_SERVER_SHUTDOWN_ERROR          = 96; // Broker -> Client, Broker will shutdown, so all connections between client and broker are cut
  NET_ANOTHER_LOGIN_ERROR            = 97; // Broker -> Client, send if broker gets a new connection request, old connection will be closed
  NET_TIMEOUT_ERROR                  = 98; // Masterserver, Broker -> Client, Server, Broker, Whaterver waiting too long for data
  NET_SECURITY_ERROR                 = 99;
  NET_LOGIN_QUEUE_ENTER_NOW          = 100;
  NET_LOGIN_QUEUE_UPDATE             = 101;

  MAX_SEND_TIME_BEFORE_SHUTDOWN = 5 * 1000; // wait 5 sec

  APPLICATIONTYPE = {$IFDEF SERVER}nsServer{$ELSE}nsClient{$ENDIF};
var

  GAMESERVER_OUTBOUND_IP : string    = 'localhost';
  GAMESERVER_HTTP_PORT : word        = 7940;
  MANAGE_SERVER_URL : string         = 'localhost:8000';
  GAMESERVER_PORTRANGE_MIN : word    = 40000;
  GAMESERVER_PORTRANGE_MAX : word    = 40255;
  GAMESERVER_PORTRANGE_LENGTH : word = 40255 - 40000 + 1;

const
  MATCHMAKINGQUEUE_POLLING_TIME = 2000;
  LOGINQUEUE_POLLING_TIME       = 5000;

const
  TESTSERVERGAMEPORT = 40000; // only for debug (if debug game at this port will start on its own)

  /// ///////////////////////////////////////////////////////////////////////////
  // Resource types
  /// ///////////////////////////////////////////////////////////////////////////

type

  EnumResource = (
    reNone,
    // single
    reFloat, reGold, reWood, reSpentWood, reHealth, reOverheal, reWelaPower, reTeamPower1, reTeamPower2, reTeamPower3,
    // integer
    reInteger, reCharge, reMana, reLevel, reTier, reSpawner, reIncomeUpgrade, reMetaAttack, reMetaDefense, reMetaUtility,
    reWelaCharge, reWelaChargeCapacity, reCardLevel, reCardTimesPlayed, reCardLeague, reGadgetCount, reCharmCount
    );

  SetResource = set of EnumResource;

const

  RES_FLOAT_RESOURCES : SetResource = [reFloat .. pred(reInteger)];
  RES_INT_RESOURCES : SetResource   = [reInteger .. high(EnumResource)];
  RES_IGNORE_CAP : SetResource      = [reGadgetCount, reCharmCount];

type
  /// ///////////////////////////////////////////////////////////////////////////
  // Dynamic Zones
  /// ///////////////////////////////////////////////////////////////////////////

  EnumDynamicZone = (dzNone, dzDrop, dzNexus);
  SetDynamicZone = set of EnumDynamicZone;

  /// ///////////////////////////////////////////////////////////////////////////
  // Unit properties
  /// ///////////////////////////////////////////////////////////////////////////

const

  GROUP_APPROACH_MAINWEAPON = 0;
  GROUP_MAINWEAPON          = 1;
  GROUP_TEMPLATE_SPAWNER    = 0;
  GROUP_DROP_SPAWNER        = GROUP_TEMPLATE_SPAWNER;
  GROUP_SPELL_SPAWNER       = 0;
  GROUP_BUILDING_LIFETIME   = 10;
  GROUP_SOUL                = 11;

  /// ///////////////////////////////////////////////////////////////////////////
  // Unit properties
  /// ///////////////////////////////////////////////////////////////////////////

type

  EnumUnitProperty = (
    upNone,
    // attackpriority reduction
    upLowPrio,
    // general unit properties
    upGround, upBuilding, upUnit, upLegendary, upEpic, upFlying, upMonumental, upBase, upLanetower, upLaneNode, upNexus, upDrop, upSpawner,
    upBuildingCard, upProjectile, upLink, upSapling, upGadget, upTier1, upTier2, upTier3, upGolem, upLinkWeapon, upSoulGatherer,
    upSoulDonor, upMelee, upRanged, upRangedGroundOnly, upCharm, upNoAutoAttack, upSupporter, upFollower,
    // unit states
    upSummoningSickness, upInvincible, upUntargetable, upUnhealable, upInjured,
    upSoulless, upInvisible, upBurrowed, upImmobilized, upSpellImmune,
    upGuarded, upImmuneToGuarded,
    upRescued, upImmuneToRescued,
    // state effects
    upHasStateEffect, upImmuneToStateEffects,
    upStunned,
    upSilenced,
    upBleeding,
    upBefogged,
    upFrozen, upImmuneToFrozen,
    upBlinded, upImmuneToBlinded,
    upRooted, upImmuneToRooted,
    upGrounded, upImmuneToGrounded,
    upLifted, upImmuneToLifted,
    upBanished, upImmuneToBanished,
    upPetrified, upImmuneToPetrified,
    // commander states
    upHasHeroicUnit, upHasLegendaryUnit,
    // wela constraint flags
    upLotharBuffed, upRangeAuraBuffed, upEnergyAuraBuffed, upSoulGathered, upSoulUnstable, upSporeFieldRegenerating,
    upHasShieldBlock, upHasUndying, upHasCrystalPower, upHasDeathRattle, upHasEnergyRift, upHasDrunkPotion,
    upBuildingLimitedTime, upImmuneToRelocate, upHasEchoesOfTheFuture, upSpellshieldAuraBuffed, upHasCrystalSpeed,
    upBlessed, upBlessedArmor, upBlessedGrowth, upBlessedHealth, upBlessedStrength, upBlessedFrenzy, upBlessedHardening,
    upBlessedEnergy, upBlessedGrievousWounds, upBlessedStonefist,
    upPlaceholder1, upPlaceholder2, upPlaceholder3,
    // misc
    upProjectileReflector, upProjectileWillMiss,
    upSpellSingle, upSpellArea, upSpellDoubleArea, upSpellCharm, upSpellAlly, upSpellEnemy,
    // client
    upSelected);
  SetUnitProperty = set of EnumUnitProperty;

const

  UNIT_PROPERTIES_STATE_EFFECTS    = [upStunned, upRooted, upBlinded, upFrozen, upSoulless, upGrounded, upLifted, upPetrified];
  UNIT_PROPERTIES_PREVENT_THINKING = [upSummoningSickness, upStunned, upFrozen, upBanished, upPetrified];
  UNIT_PROPERTIES_PREVENT_MOVEMENT = [upRooted, upGrounded, upLifted, upImmobilized];

type

  EnumBuffType = (btNeutral, btPositive, btNegative, btState, btDivine, btSummoningSickness);
  SetBuffType = set of EnumBuffType;

  ECorruptData = class(Exception);

const

  ALL_BUFF_TYPES = [low(EnumBuffType) .. high(EnumBuffType)];

type

  EnumTargetTeamConstraint = (tcAll, tcEnemies, tcAllies);
  EnumZoneRestriction = (zrNone, zrBuild, zrBase, zrSpell, zrBaseSpell);
  EnumClientCommand = (ccClearUnits, ccClearAllUnits, ccClearSpawners, ccClearLaneTowers, ccClearGolemTowers, ccBaseBuildingsLevel1, ccBaseBuildingsLevel2, ccBaseBuildingsLevel3, ccBaseBuildingsIndestructible,
    ccToggleOverwatch, ccToggleOverwatchSandbox, ccClearOverwatch, ccSaveCameraPosition, ccReturnToSavedCameraPosition, ccTutorialGameEvent, ccForceGameTick);

  /// ///////////////////////////////////////////////////////////////////////////
  // Misc unit data
  /// ///////////////////////////////////////////////////////////////////////////

type

  EnumUnitData = (
    udUsePathfinding,  // boolean = True; Determines whether the unit uses pathfind for movement or not
    udMinimapIcon,     // string; The minimap icon used by this unit
    udMinimapIconSize, // single; If set, override the automatic icon size computation depending on collision radius
    udHasDeathEffect,  // boolean = False;
    udHealthbarOffset  // single; Added to y of the healthbar
    );

  /// ///////////////////////////////////////////////////////////////////////////
  // Event Identifier
  /// ///////////////////////////////////////////////////////////////////////////

type
  EnumEventIdentifier = (
    eiNone,
    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// RESOURCES /////////////////////////////////////////
    // ////////////////////////////////////////////////////////////////////////

    /// Some resources are saves as single, some as integer. For type look at the constants.

    /// <summary> Reads or sets the current resource in the entity.
    /// Read:  function (ResourceID : integer) : single|integer;
    /// Write: function (ResourceID : integer; Amount : single|integer) : boolean;</summary>
    eiResourceBalance,
    /// <summary> Manipulates a resource.
    /// Check whether the transaction can be done and doesn't violates the [0,Cap]-Range.
    /// Read: function (ResourceID : integer; Amount : single|integer) : boolean;
    /// Add the amount of a resource to the pool. Negative sign is allowed.
    /// Trigger: function (ResourceID : integer; Amount : single|integer) : boolean; </summary>
    eiResourceTransaction,
    /// <summary> Manipulates a resource. Resets its balance to the initial value after creation.
    /// Trigger: function (ResourceID : integer) : boolean; </summary>
    eiResourceReset,
    /// <summary> Same as eiResourceTransaction, except that it negates the amount.
    /// Trigger: function (ResourceID : integer; Amount : single|integer) : boolean; </summary>
    eiResourceSubtraction,
    /// <summary> The upper bound of the resource. -1 => unbound
    /// Read: function (ResourceID : integer) : single|integer;
    /// Write: function (ResourceID : integer; Amount : single|integer) : boolean;</summary>
    eiResourceCap,
    /// <summary> Retrieves the cost of casting this wela. (Mapping of Resource=>Amount)
    /// Read: function () : AResourceCost; </summary>
    eiResourceCost,
    /// <summary> Highers or lowers the resource cap of a resource. Empty determines whether new resource is added or only space.
    /// Trigger: function (ResourceID : integer; Amount : single|integer; Empty : boolean) : boolean;</summary>
    eiResourceCapTransaction,

    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// GENERAL / GLOBAL //////////////////////////////////
    // ////////////////////////////////////////////////////////////////////////

    /// <summary> Signals that an entity has been replaced by another. If it is the same entity its id will be updated.
    /// Trigger: function (OldEntityID,NewEntityID : integer; isSameEntity : boolean) : boolean; </summary>
    eiReplaceEntity,
    /// <summary> Registers a new entity in the manager.
    /// Trigger: function (Entity : TEntity) : boolean; </summary>
    eiNewEntity,
    /// <summary> Thrown whenever a spell is cast at the moment.
    /// Trigger: function (TeamID : integer; Targets : ATarget) : boolean; </summary>
    eiCommanderAbilityUsed,
    /// <summary> Called globally once a frame.
    /// Trigger: function () : boolean;</summary>
    eiIdle,
    /// <summary> Removes a specific component of a specific entity.
    /// Trigger: function (EntityID, ComponentID : integer) : boolean; </summary>
    eiRemoveComponent,
    /// <summary> Removes a specific group of components of a specific entity, e.g. a complete wela.
    /// Trigger: function (EntityID : integer; ComponentGroup : SetComponentGroup) : boolean; </summary>
    eiRemoveComponentGroup,
    /// <summary> Removes an entity from the game.
    /// Trigger: function (EntityID : integer) : boolean; </summary>
    eiKillEntity,
    /// <summary> Marks an entity ready to be killed. Useful if Entities wants to kill
    /// themselve in reaction to an event. Entity will then be killed at the next idle
    /// of the EntityManager.
    /// Trigger: function (EntityID : integer) : boolean; </summary>
    eiDelayedKillEntity,
    /// <summary> Sent if a team has lost. TeamID is the loosing teams id.
    /// Trigger: function (TeamID : integer) : boolean; </summary>
    eiLose,
    /// <summary> The client can send eiSurrender to express the demand to surrender. At the moment this demand is sanctified
    /// in bot games and no where else. (ATM it is possible to give up for the enemy, so TODO make safe)
    /// Trigger: function (TeamID : integer) : boolean; </summary>
    eiSurrender,
    /// <summary> Get all Nexus-entities.
    /// Read: function () : TList<TEntity>; </summary>
    eiEnumerateNexus,
    /// <summary> Triggered when the client has finished loading and now initializes components.
    /// Trigger: function () : boolean; </summary>
    eiClientInit,
    /// <summary> Triggered when the client has finished loading and would be ready to start.
    /// Trigger: function () : boolean; </summary>
    eiClientReady,
    /// <summary> Triggered when the game begins to count down to the first wave.
    /// Trigger: function () : boolean; </summary>
    eiGameCommencing,
    /// <summary> Called globally before the first game tick is sent, basically the game start after warming.
    /// Trigger: function () : boolean; </summary>
    eiGameStart,
    /// <summary> Called globally every second of the game. Used for global events, which should be exact at the same time for all players.
    /// Trigger: function () : boolean; </summary>
    eiGameTick,
    /// <summary> Called globally to get the ms until the game starts. Returns 0 if game has started.
    /// Read: function () : integer; </summary>
    eiGameTickTimeToFirstTick,
    /// <summary> Called globally to get the number of previous game ticks aka time of the match.
    /// Read: function () : integer; </summary>
    eiGameTickCounter,
    /// <summary> Called globally to spawn all units on the specified build grid with this coordinate.
    /// Trigger: function (GridID : integer; Coordinate : RIntVector2) : boolean; </summary>
    eiWaveSpawn,
    /// <summary> Set whether a field of a build grid is blocked and cannot be build over (EntityID) or free (-1).
    /// Trigger: function (GridID: integer; GridCoord:RIntVector2; BlockedBy: Integer) : boolean; </summary>
    eiSetGridFieldBlocking,
    /// <summary> Called globally to get income value and trigger income.
    /// Read: function (CommanderID : integer) : RIncome; // Returns the current income of a specific commander <Gold,Wood>
    /// Trigger: function () : boolean; // Runs the income payout </summary>
    eiIncome,
    /// <summary> Called globally to trigger things globally (e.g. tech upgrades or events in scenarios).
    /// Can be read to enumerate all contributing entities of this event. List is nil if no entity found.
    /// Read : function(Eventname : string) : TList<TEntity>;
    /// Trigger: function (Eventname : string) : boolean; </summary>
    eiGameEvent,
    /// <summary> Called globally to get the time in game ticks (seconds) to this event. Returns -1 if event will not happen anymore.
    /// Read: function (Eventname : string) : integer; </summary>
    eiGameEventTimeTo,
    /// <summary> Called globally to do a certain action.
    /// Trigger: function (Command : EnumSandboxCommand; Param1 : anything) : boolean; </summary>
    eiClientCommand,

    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// CLIENT ONLY ///////////////////////////////////////
    // ////////////////////////////////////////////////////////////////////////

    // General

    /// <summary> Triggered when the player changes an client option.
    /// Global Trigger: function (ChangedOption : EnumClientOption): boolean;</summary>
    eiClientOption,
    /// <summary> Returns the shortest distance of the battle to any nexus -> Game intensity
    /// Global Trigger: function (): single;</summary>
    eiShortestBattleFrontDistance,

    // View

    /// <summary> Triggered whenever the cameraposition changes.
    /// Global read: function () : RVector2; </summary>
    eiCameraPosition,
    /// <summary> Moves the camera linear to target position over speficied duration. Ignore user
    /// input while moving.
    /// Global Trigger: function (Pos : RVector2; TransitionDuration : int64) : boolean; </summary>
    eiCameraMoveTo,
    /// <summary> Triggered whenever the cameraposition changes.
    /// Global Trigger: function (Pos : RVector2) : boolean; </summary>
    eiCameraMove,
    /// <summary> Returns all unit at the mouse cursor sorted by the nearest to farest ones.
    /// Read: function (ClickRay : RRay): TList<RTuple<single,TEntity>>;</summary>
    eiGetUnitsAtCursor,

    // Input

    /// <summary> Triggered when a mouse has been moved (Key = -1).
    /// Global Trigger: function (Position, Difference : RIntVector2) : boolean; </summary>
    eiMouseMoveEvent,
    /// <summary> Triggered when user rotates the mousewheel.
    /// Global Trigger: function (dZ:integer) : boolean; </summary>
    eiMouseWheelEvent,
    /// <summary> Triggered whenever a guievent is thrown.
    /// Global Trigger: function (Event : RGUIEvent) : boolean; </summary>
    eiGUIEvent,
    /// <summary> Triggered whenever a key or mousbutton is pressed or released.
    /// Global Trigger: function () : boolean; </summary>
    eiKeybindingEvent,
    /// <summary> Triggered whenever the camera should move to target minimap position.
    /// Global Trigger: function (MiniMapPosition : RVector2) : boolean; </summary>
    eiMiniMapMoveToEvent,

    // GUI

    /// <summary> Draws the zone where the player can spawn units. </summary>
    /// Global Read : function OnDrawSpawnZone(List : TList<RCircle>) : TList<RCircle>;
    /// Global Trigger: function OnDrawSpawnZone() : boolean;
    eiDrawSpawnZone,

    // Commanderadministration

    /// <summary> Changes the active commander of a multicommander-player.
    /// Trigger: function (index : integer) : boolean; </summary>
    eiChangeCommander,
    /// <summary> Registers a new commander.
    /// Trigger: function (Commander : TEntity) : boolean; </summary>
    eiNewCommander,

    // Entity

    /// <summary> The current display position of the entity. Can differ from logical position eiPosition
    /// Read: function () : RVector3;
    eiDisplayPosition,
    /// <summary> The current display front of the entity. Can differ from logical orientation eiFront
    /// Read: function () : RVector3;
    eiDisplayFront,
    /// <summary> The current uporientation of the entity.
    /// Read: function () : RVector3;
    eiDisplayUp,

    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// COMMANDER /////////////////////////////////////////
    // ////////////////////////////////////////////////////////////////////////

    /// <summary> Determines whether a ability of a commander can be used with a specified target.
    /// Read: function (Targets : TArray<RCommanderAbilityTarget>) : boolean;</summary>
    eiCanUseAbility,
    /// <summary> Use a commanderability.
    /// Trigger: function (Targets : TArray<RCommanderAbilityTarget>) : boolean; </summary>
    eiUseAbility,
    /// <summary> Targettype of a commanderability.
    /// Read: function () : EnumCommanderAbilityTargetType; </summary>
    eiAbilityTargetType,
    /// <summary> Targetcount of a commanderability.
    /// Read: function () : integer; </summary>
    eiAbilityTargetCount,
    /// <summary> Maximal distance between all targets of a multitarget ability.
    /// Read: function () : single; </summary>
    eiAbilityTargetRange,
    /// <summary> Read the name of the owner of this commander.
    /// Read: function () : string; </summary>
    eiPlayerOwner,
    /// <summary> Retrieve a list of all commanders.
    /// Read: function () : TList<TEntity>; </summary>
    eiEnumerateCommanders,
    /// <summary> Retrieve a list of all commander abilities. SERVER ONLY
    /// Read: function () : TList<TCommanderAbility>; </summary>
    eiEnumerateCommanderAbilities,

    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// ENTITYPROPERTIES //////////////////////////////////
    // ////////////////////////////////////////////////////////////////////////

    /// <summary> The current position of the entity.
    /// Read: Use Entity.Position!
    /// Write: function (Position : RVector2) : boolean; </summary>
    eiPosition,
    /// <summary> The current frontorientation of the entity.
    /// Read: Use Entity.Front!
    /// Write: function (Front : RVector2) : boolean;</summary>
    eiFront,
    /// <summary> The current position of the entity.
    /// Read: function () : TPathfindingTile;
    eiPathfindingTile,

    /// <summary> Retrieve the color identity of an entity.
    /// Read: function () : EnumEntityColor; </summary>
    eiColorIdentity,
    // OwnerCommander must be in order before TeamID, for deserialization!
    /// <summary> Gets/Sets the owning commander of an unit.
    /// Read: function () : integer;
    /// Write: function (OwnerCommanderID : integer) : boolean;</summary>
    eiOwnerCommander,
    /// <summary> The direct creator of an entity, e.g. an Archer which shoots an arrow. If placed in a group, it is the creator of
    /// a certain ability.
    /// Read: function () : integer;
    /// Write: function (CreatorID : integer) : boolean;</summary>
    eiCreator,
    /// <summary> The group of the creator, if reduced to a single ability
    /// Read: function () : SetComponentGroup;
    /// Write: function (CreatorGroup : SetComponentGroup) : boolean;</summary>
    eiCreatorGroup,
    /// <summary> The direct creator of an entity, e.g. an Archer which shoots an arrow.
    /// Read: function () : integer;
    /// Write: function (CreatorScriptFileName : string) : boolean;</summary>
    eiCreatorScriptFileName,
    /// <summary> Used to determine the team the entity belongs to.
    /// Read: function () : integer;
    /// Write: function (TeamID : integer) : boolean;</summary>
    eiTeamID,
    /// <summary> An exiled entity is not present in the game, but could be returned to the battlefield.
    /// Read: function () : boolean;
    /// Write: function (Exiled : boolean) : boolean;</summary>
    eiExiled,
    /// <summary> Called before an entity should be freed, but nothing have been freed at this moment.
    /// Trigger:  function () : boolean;</summary>
    eiBeforeFree,
    /// <summary> Called when the entity should be freed. Be cautious as the entity can be in an invalid state as some components already have been freed.
    /// Trigger:  function () : boolean;</summary>
    eiFree,
    /// <summary> Think event for brains with passive effects. Usually called periodically by a brainthinktimer. Not
    /// called each frame for performance reason. Called before eiThinkChain.
    /// Trigger: function OnThink() : boolean; </summary>
    eiThink,
    /// <summary> Starts the wela thinking chain, can be interrupted by preemptive brains.
    // Usually called periodically by a brainthinktimer. Not called each frame for performance reason.  Called after eiThink.
    /// Trigger: function OnThink() : boolean; </summary>
    eiThinkChain,
    /// <summary> Retrieve the current targets of a brain.
    /// Read: function OnGetCurrentTargets() : TList<RTarget>; </summary>
    eiGetCurrentTargets,
    /// <summary> Serializes all serializable Components into the stream.
    /// Trigger: function (Stream : TStream) : boolean; </summary>
    eiSerialize,
    /// <summary> Client : Called after deserialization of the entity, when the blackboard is ready.
    /// Server : Called after unit has been initialized and before it has been deployed to the game.
    /// Trigger: function () : boolean; </summary>
    eiAfterCreate,
    /// <summary> Called when the entity is finally present in the game.
    /// Trigger: function () : boolean; </summary>
    eiDeploy,
    /// <summary> Calls proc for all entity compononents on this entity.
    /// Trigger: function (Callback : ProcEnumerateEntityComponentCallback) : boolean; </summary>
    eiEnumerateComponents,
    /// <summary> Get the general properties of a unit, e.g. ground,flying,building etc.
    /// Read: function () : SetUnitProperty;
    /// Write: function (Props : SetUnitProperty) : boolean; </summary>
    eiUnitProperties,
    /// <summary> If the unit has been placed on a buildgrid, this holds the id of the buildgrid.
    /// Read: function () : integer;</summary>
    eiBuildgridOwner,
    /// <summary> If the unit has been placed on a buildgrid this event encapsulates all its used build grid fields.
    /// ATTENTION : ONLY AVAILABLE ON SERVER SIDE.
    /// Read: function () : TArray<RTuple<integer, RIntVector2>>;</summary>
    /// Write: function(Fields : TArray<RTuple<integer, RIntVector2>>) :boolean </summary>
    eiBuildgridBlockedFields,
    /// <summary> Returns all kind of buff types applied on this unit.
    /// Read: function() : SetBuffType; </summary>
    eiBuffed,
    /// <summary> Remove all whitelisted buffs, but not the blacklisted ones.
    /// Trigger: function(WhiteList, Blacklist: SetBuffType) : boolean; </summary>
    eiRemoveBuffs,
    /// <summary> Saves miscellanious data for the unit. Constants starting with UNITDATA_
    /// Only for direct blackboard use, not as event.</summary>
    eiUnitData,
    /// <summary> Saves the skin identifier for the spawned entity. </summary>
    eiSkinIdentifier,

    // Health

    /// <summary> Apply a healing effect to a unit. It's healed by amount. Return the healed amount.
    /// Read: function (var Amount : single; HealModifier : SetDamageType; InflictorID : integer) : single;</summary>
    eiHeal,
    /// <summary> Triggered when a unit gets overhealed.
    /// Trigger: function (Amount : single; HealModifier : SetDamageType; InflictorID : integer) : boolean;</summary>
    eiOverheal,
    /// <summary> Determines whether an entity can be dealt damage.
    /// Read: function () : boolean; </summary>
    eiDamageable,
    /// <summary> Retrieves the armortype of an entity.
    /// Read: function () : EnumArmorType;
    /// Write: function (Value : EnumArmorType);</summary>
    eiArmorType,
    /// <summary> Retrieves the damage types of a weapongroup.
    /// Read: function () : TArray<byte>;
    /// Write: function (Value : TArray<byte>);</summary>
    eiDamageType,
    /// <summary> Triggered with the final amount of damage dealt to the target right after this event.
    /// Damageadjuster can register here to apply their effects to this value.
    /// Read: function (Amount : single; TargetEntity : TEntity) : single;</summary>
    eiWillDealDamage,
    /// <summary> Deals amount of damage to target entity. InflictorID is the EntityID of
    /// the entity which deals the damage. Result is the amount of really dealt damage, all components managing damage
    /// should add their damage to the previous one, other should just return the previous one.
    /// Read: function (var Amount : single; DamageType : SetDamageType; InflictorID : integer) : single;</summary>
    eiTakeDamage,
    /// <summary> Triggered when a group of an entity has dealt some damage (real damage, after Armor etc.).
    /// Trigger: function (Amount : single; DamageType : SetDamageType; TargetEntity : TEntity) : boolean;</summary>
    eiDamageDone,
    /// <summary> Triggered when a group of an entity has healed some damage.
    /// Trigger: function (Amount : single; DamageType : SetDamageType; TargetEntity : TEntity) : boolean;</summary>
    eiHealDone,
    /// <summary> Triggered groupless to a unit, which has killed a unit.
    /// Trigger: function (KilledUnitID : integer) : boolean;</summary>
    eiYouHaveKilledMeShameOnYou,
    /// <summary> Triggered in the group of a unit, which has killed a unit.
    /// Trigger: function (KilledUnitID : integer) : boolean;</summary>
    eiKillDone,
    /// <summary> Gets and sets the alivestate of an entity.
    /// Read: function () : boolean; </summary>
    /// Write: function (IsAlive : boolean) : boolean;
    eiIsAlive,
    /// <summary> Called when the unit dies. Can be intercepted. IDs are -1 if not present.
    /// Trigger:  function (KillerID, KillerCommanderID : integer) : boolean;</summary>
    eiDie,
    /// <summary> Called when the unit dies from full health. Can be intercepted. IDs are -1 if not present.
    /// Trigger:  function (KillerID, KillerCommanderID : integer) : boolean;</summary>
    eiInstaDie,
    /// <summary> Kills the entity for another allied effect. IDs are -1 if not present.
    /// Trigger: function (KillerID, KillerCommanderID : integer) : boolean; </summary>
    eiSacrifice,
    /// <summary> Kills the entity. Deadly damage will call this to kill the entity. IDs are -1 if not present.
    /// Trigger: function (KillerID, KillerCommanderID : integer) : boolean; </summary>
    eiKill,
    /// <summary> Triggered after being effected by a certain unit property. Used for state changed, like become frozen or buffed.
    /// Trigger: function (ChangedUnitProperties : SetUnitProperty; Removed : boolean) : boolean; </summary>
    eiUnitPropertyChanged,

    // Movement

    /// <summary> Returns whether the unit is currently moving or not.
    /// Read:  function () : boolean; </summary>
    eiIsMoving,
    /// <summary> Orders the entity to move in range to target.
    /// Trigger:  function (Target : RTarget; Range : single) : boolean; </summary>
    eiMoveTo,
    /// <summary> Gets the current movementspeed of the unit.
    /// Read: function () : single; </summary>
    eiSpeed,
    /// <summary> Order the entity to stand.
    /// Trigger: function () : boolean; </summary>
    eiStand,
    /// <summary> Sets the position of the entity to target ordered by a movement.
    /// Trigger: function (Target : RVector2) : boolean; </summary>
    eiMove,
    /// <summary>  Triggered when the entity reaches its destination.
    /// Trigger: function () : boolean; </summary>
    eiMoveTargetReached,
    /// <summary> Synchronize the walking path of an entity between server and client.
    /// Trigger: function (Path : TArray<RIntVector2>) : boolean; </summary>
    eiSyncPath,
    /// <summary> Synchronize the position of an entity between server and client.
    /// Set the current position to Pos.
    /// Trigger: function (Pos : RVector2) : boolean; </summary>
    eiSyncPosition,
    /// <summary> Returns the lane the entity has been attached to (don't free it!). </summary>
    /// Read : function() : TLane;
    eiGetLane,
    /// <summary> Returns the lanedirection the entity is heading. </summary>
    /// Read : function() : EnumLaneDirection;
    eiGetLaneDirection,

    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// WELA //////////////////////////////////////////////
    // ////////////////////////////////////////////////////////////////////////

    /// <summary> Determines whether a wela is active and will take action. Defaults to true if not set.
    /// Read: function () : boolean; </summary>
    /// Write: function (IsActive : boolean) : boolean; </summary>
    eiWelaActive,
    /// <summary> Triggers the warhead on a target.
    /// Trigger: function (Targets : ATarget) : boolean;</summary>
    eiFireWarhead,
    /// <summary> Can be used to save targets of a wela.
    /// Read: function () : ATarget;
    /// Trigger: function (Targets : ATarget) : boolean; </summary>
    eiWelaSavedTargets,
    /// <summary> Gets the area of effect of a spell/warhead.
    /// Read: function () : single; </summary>
    eiWelaAreaOfEffect,
    /// <summary> Reduces the AoE to an angle aka a cone.
    /// Read: function () : single; </summary>
    eiWelaAreaOfEffectCone,
    /// <summary> Reads the current damage of a wela.
    /// Read: function () : single; </summary>
    eiWelaDamage,
    /// <summary> Reads the a modifier of a wela. Used by various components to, e.g. modify the wela damage.
    /// Read: function () : single; </summary>
    eiWelaModifier,
    /// <summary> Reads the current chance of a wela to been fired.
    /// Read: function () : single; </summary>
    eiWelaChance,
    /// <summary> Reads the current splashfactor of a wela.
    /// Read: function () : single; </summary>
    eiWelaSplashfactor,
    /// <summary> Triggered whenever a unit shoots a projectile.
    /// Trigger: function (Projectile : TEntity) : boolean; </summary>
    eiWelaShotProjectile,
    /// <summary> Triggered whenever a unit got hit by a projectile.
    /// Trigger: function (Projectile : TEntity) : boolean; </summary>
    eiWelaHitByProjectile,
    /// <summary> Triggered whenever a unit produces another unit.
    /// Trigger: function (EntityID : integer) : boolean; </summary>
    eiWelaUnitProduced,
    /// <summary> Reads the current unitpattern of a wela, e.g. for factory component.
    /// Read: function () : string; </summary>
    eiWelaUnitPattern,
    /// <summary> Reads the needed gridsize of this entity if placed on a grid.
    /// Read: function () : RIntVector2; </summary>
    eiWelaNeededGridSize,
    /// <summary> The maximal count of simultan living units of a producing component, e.g. for factory component.
    /// Read: function () : integer; </summary>
    eiWelaUnitMaximum,
    /// <summary> A count value, e.g. for factory component to determine the number of produced units.
    /// Read: function () : integer; </summary>
    eiWelaCount,
    /// <summary> Reads the current possible targetcount of a wela.
    /// Read: function () : integer; </summary>
    eiWelaTargetCount,
    /// <summary> The time in ms after initiating the action of a wela, when the real action takes place.
    /// Read: function () : integer; </summary>
    eiWelaActionpoint,
    /// <summary> The time in ms after initiating the action of a wela, while the unit is unable to do something.
    /// Read: function () : integer; </summary>
    eiWelaActionduration,
    /// <summary> Reads the current cooldown of a wela.
    /// Read: function () : int64; </summary>
    eiCooldown,
    /// <summary> Reads the starting time of a cooldown. (its the server time, when it has been started)
    /// Read: function () : double; </summary>
    /// Write: function (StartingTime : double) : boolean; </summary>
    eiCooldownStartingTime,
    /// <summary> Reads the time of the cooldown to be finished in ms. Returns 0 if its ready and -1 if it won't become ready.
    /// Read: function () : double; </summary>
    eiCooldownRemainingTime,
    /// <summary> Returns the percentage of eiCooldownRemainingTime. Returns 0 if its ready and -1 if it won't become ready.
    /// Read: function () : double; </summary>
    eiCooldownProgress,
    /// <summary> Resets the cooldown in the given group. If Finish the cooldown will expire otherwise restarted.
    /// Trigger: function (Finish : boolean) : boolean; </summary>
    eiWelaCooldownReset,
    /// <summary> Reads the current linkpatternfile of a wela.
    /// Read: function () : string; </summary>
    eiLinkPattern,
    /// <summary> Triggers a wela to fire at the eiWelaActionpoint at a list of targets.
    /// Trigger: function (Targets : ATarget) : boolean; </summary>
    eiPreFire,
    /// <summary> Triggered if the wela tries to fire at the actionpoint, but the targets aren't valid anymore.
    /// Trigger: function () : boolean; </summary>
    eiCancelFire,
    /// <summary> Triggers a wela to fire at a list of targets.
    /// Trigger: function (Targets : ATarget) : boolean; </summary>
    eiFire,
    /// <summary> Get the range of a wela.
    /// Read: function () : single; </summary>
    eiWelaRange,
    /// <summary> The Attentionrange determines the range, where units are looking for targets.
    /// Read: function () : single; </summary>
    eiAttentionrange,
    /// <summary> Stop the current action of a wela.
    /// Trigger: function () : boolean; </summary>
    eiWelaStop,
    /// <summary> Units send this to themselves when they change their maintarget.
    /// Trigger: function (MainTarget : RTarget) : boolean; </summary>
    eiWelaSetMainTarget,
    /// <summary> Units send this to units, when they lock their target to.
    /// Trigger: function (Attacker : TEntity) : boolean; </summary>
    eiWelaYoureMyTarget,
    /// <summary> Updates the targets with a TWelaTargetingComponent.
    /// Trigger: function (Targets : TList<RTarget>) : boolean; </summary>
    eiWelaUpdateTargets,
    /// <summary> Forces a wela to change a target, if it's possible.
    /// Read: function (Target : RTarget) : boolean; </summary>
    eiWelaChangeTarget,
    /// <summary> Validates a target via a TWelaTargetingComponent.
    /// Read: function (Target : RTarget) : boolean; </summary>
    eiWelaValidateTarget,
    /// <summary> Returns whether a list of targets are possible. (e.g. Anti-Air would return false for ground units)
    /// Read: function (Targets : ATarget) : RTargetValidity; </summary>
    eiWelaTargetPossible,
    /// <summary> Returns whether a list of targets are possible for applying warheads. (e.g. Bash will deal extra damage against buildings, but not stun them)
    /// Read: function (Targets : ATarget) : RTargetValidity; </summary>
    eiWarheadTargetPossible,
    /// <summary> Returns whether a AutoWela triggers to a certain event.
    /// ATTENTION: parameter list is dynamic and depends on the triggering event!
    /// Read: function (-dynamic-) : boolean; </summary>
    /// Read-OnTakeDamage-OnHeal: function (var Amount : single; HealModifier : SetDamageType; InflictorID : integer) : boolean; </summary>
    eiWelaTriggerCheck,
    /// <summary> Returns the groups which are matching the given unit property via TWelaHelperBeacon.
    /// Read: function (UnitProperties : SetUnitProperty) : SetComponenGroup; </summary>
    eiWelaSearch,
    /// <summary> Gets or sets the source of a link.
    /// Read: function () : ATarget;
    /// Write: function(Sources : ATarget) : boolean; </summary>
    eiLinkSource,
    /// <summary> Gets or sets the target of a link.
    /// Read: function () : ATarget;
    /// Write: function(Dest : ATarget) : boolean; </summary>
    eiLinkDest,
    /// <summary> Kills a link.
    /// Trigger: function(LinkTarget : RTarget) : boolean; </summary>
    eiLinkBreak,
    /// <summary> Establishes a link.
    /// Trigger: function(Source : RTarget; Dest : RTarget) : boolean; </summary>
    eiLinkEstablish,
    /// <summary> Return the efficiency of a weapon to a specified target.
    /// Read: function (Target : TEntity) : single; </summary>
    eiEfficiency,
    /// <summary>
    /// Read: function (PrevValue : boolean) : boolean; </summary>
    eiIsReady,
    /// <summary> Checks whether the position is in the dynamic zone.
    /// Global Read: function (Position : RVector2; TeamID : integer; Zone : SetDynamicZone) : boolean; </summary>
    eiInDynamicZone,


    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// VISUALS ///////////////////////////////////////////
    // ////////////////////////////////////////////////////////////////////////

    // Meta

    /// <summary> Hold values for target usage of cards. Used with indexed values RES_META_* </summary>
    eiCardStats,
    /// <summary> Sent to a entity, which should build a list of its abilities. Used in the deckbuilding.
    /// Trigger: function (AbilityIDList : TList<RAbilityDescription>; KeywordIDList : TList<string>; CardDescription : TCardDescription) : boolean;</summary>
    eiBuildAbilityList,

    // HUD

    /// <summary> Registers all abilities of the current commander in the HUD.
    /// Trigger: function () : boolean; </summary>
    eiRegisterInGui,
    /// <summary> Deregisters all abilities of the current commander in the HUD.
    /// Trigger: function () : boolean; </summary>
    eiDeregisterInGui,

    // Tooltip

    /// <summary> Selects an entity, e.g. for display of the tooltip.
    /// if Entity = nil => Deselection
    /// Read : function () : TEntity
    /// Trigger: function (Entity : TEntity) : boolean;</summary>
    eiSelectEntity,
    /// <summary> Shows the Tooltip of an Entity. Send it global for display of the tooltip.
    /// Trigger: function (Entity : TEntity; IsCard : boolean) : boolean;</summary>
    eiShowToolTip,
    /// <summary> Hides the tooltip immediately.
    /// Trigger: function () : boolean;</summary>
    eiHideToolTip,

    // Entity
    /// <summary> Controls the visibility of a component group. Saving false will hide meshes, etc.
    /// Components can hide the entity as well, so writing true doesn't force the entity to be visible.
    /// Remarks - Defaults to true (use AsBooleanDefaultTrue)
    /// Read: function () : boolean;
    /// Write: function (Visible : boolean) : boolean;</summary>
    eiVisible,
    /// <summary> The subposition of something like the end of the barrel of a gun, bonepositions, etc..
    /// Read: function (Name : string) : RMatrix;</summary>
    eiSubPositionByString,
    /// <summary> Applies a colorization of an entity. Manipulating the HSV-Colorspace.
    /// absHSV = absolute, set the value to the target, otherweise it will be added to the value.
    /// Trigger: function (ColorAdjustment : RVector3; absH, absS, absV : boolean) : boolean; </summary>
    eiColorAdjustment,
    /// <summary> A size modificator of an entity. Defaults to RVector3.ONE
    /// Read: function () : RVector3; </summary>
    eiSize,
    /// <summary> Determines the size of the model.
    /// Write: function (Size : single) : boolean; </summary>
    eiModelSize,
    /// <summary> Trigger the play-back of a animation </summary>
    /// Trigger : function (AnimationName : string; AnimationPlayMode : EnumAnimationPlayMode; Length : integer) : boolean;
    eiPlayAnimation,
    /// <summary> Draws an outline of an unit in this frame. If Color is zero the team color is used. </summary>
    /// Trigger : function (Color : RColor; OnlyOutline : boolean) : boolean;
    eiDrawOutline,

    /// <summary> Shows the visualization of a spell. </summary>
    /// Trigger: function (Data: TCommanderSpellData) : Boolean</summary>
    eiSpellVisualization,
    /// <summary> Hides the visualization of a spell. </summary>
    /// Trigger: function () : Boolean</summary>
    eiSpellVisualizationHide,

    /// <summary> Returns the floating wrapper for Resource displays of an entity
    /// Read: function () : TGUIStackPanel</summary>
    eiGetEntityResourceWrapper,
    /// <summary> Returns the floating wrapper for icon displays of an entity
    /// Read: function () : TGUIStackPanel</summary>
    eiGetEntityStateWrapper,

    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// COLLISION / SPATIAL QUERIES ///////////////////////
    // ////////////////////////////////////////////////////////////////////////

    /// <summary> The boundingsphere of a unit.
    /// Read: function () : RSphere; </summary>
    eiBoundings,
    /// <summary>
    /// Read: function () : single; </summary>
    eiCollisionRadius,

    // Queries

    /// <summary> Get all enemies with efficiency in range of an entity matching the filterfunction (e.g different TeamID).
    /// Read: function (Pos : RVector2; Range : single; SourceTeamID: integer; TargetTeamConstraint : EnumTargetTeamConstraint; Filter : ProcFilterFunction) : TList<RTargetWithEfficiency>; </summary>
    eiEnemiesInRangeEfficiency,
    /// <summary> Get all entities in range of a position matching the filterfunction.
    /// Read: function (Pos : RVector2; Range : single; SourceTeamID: integer; TargetTeamConstraint : EnumTargetTeamConstraint; Filter : ProcEntityFilterFunction) : TList<TEntity>;</summary>
    eiEntitiesInRange,
    /// <summary> Returns the closest Entity matching a filter to a point.
    /// Read: function (Pos : RVector2; Range : single; SourceTeamID: integer; TargetTeamConstraint : EnumTargetTeamConstraint; Filter : ProcEntityFilterFunction) : TEntity; </summary>
    eiClosestEntityInRange,

    // ////////////////////////////////////////////////////////////////////////
    // //////////////////// NETWORK FUNCTIONS AND SETTINGS ////////////////////
    // ////////////////////////////////////////////////////////////////////////

    /// <summary> Send all given entities to all clients.
    /// Trigger: function (Entities : TList<TEntity>) : boolean; </summary>
    eiSendEntities,
    /// <summary> Sends a triggerevent over network with given parameters.
    /// Sended event will automatic called on peer machine.
    /// Trigger:  function (EntityID : integer; Event : EnumEventIdentifier; ComponentID : integer; Parameters : TArray<RParam>) : boolean; </summary>
    eiNetworkSend,
    /// <summary> Retrieves the Tokenmapping for a player to its commanders.
    /// Read: function (Token : string) : TList<integer>;
    /// Trigger: function (Token : string; CallBackProcedure : ProcTokenCallBack) : boolean;</summary>
    eiTokenMapping,
    /// <summary> Sent when the server should shut down.
    /// Trigger: function () : boolean; </summary>
    eiServerShutdown
    );

  /// <summary> Determines whether to send an triggered/written event via network. </summary>
function EventIdentifierToNetworkSend(Event : EnumEventIdentifier) : EnumNetworkSender;

/// <summary> Determines whether a writeevent should be called,
/// when deserialize this event in the blackboard. </summary>
function EventIdentifierToBlackboardEvent(Event : EnumEventIdentifier) : boolean;

function ByteArrayToSetUnitProperies(const arr : TArray<byte>) : SetUnitProperty;
function ByteArrayToSetResource(const arr : TArray<byte>) : SetResource;

function ByteArrayToSetBuffType(const arr : TArray<byte>) : SetBuffType;

function ByteArrayToSetDamageType(const arr : TArray<byte>) : SetDamageType;
function ByteArrayToSetDynamicZone(const arr : TArray<byte>) : SetDynamicZone;

implementation


function ByteArrayToSetUnitProperies(const arr : TArray<byte>) : SetUnitProperty;
var
  i : Integer;
begin
  Result := [];
  for i := 0 to length(arr) - 1 do
      Result := Result + [EnumUnitProperty(arr[i])];
end;

function ByteArrayToSetResource(const arr : TArray<byte>) : SetResource;
var
  i : Integer;
begin
  Result := [];
  for i := 0 to length(arr) - 1 do
      Result := Result + [EnumResource(arr[i])];
end;

function EventIdentifierToNetworkSend(Event : EnumEventIdentifier) : EnumNetworkSender;
begin
  case Event of
    eiTeamID, eiMoveTo, eiStand, eiSyncPosition, eiDie, eiRemoveComponent,
      eiKillEntity, eiResourceBalance, eiResourceCap, eiResourceCost, eiLose, eiPreFire, eiFire, eiCancelFire,
      eiFireWarhead, eiGameCommencing, eiGameStart,
      eiRemoveComponentGroup, eiReplaceEntity, eiWelaSetMainTarget, eiGameTick, eiLinkEstablish, eiLinkBreak,
      eiSetGridFieldBlocking, eiExiled, eiUnitProperties,
      eiWelaUnitProduced, eiCooldownStartingTime, eiGameEvent,
      eiWelaActive, eiWelaSavedTargets, eiSyncPath, eiWaveSpawn, eiWelaCooldownReset : Result := nsServer;
    eiUseAbility, eiSurrender, eiClientCommand : Result := nsClient;
  else Result := nsNone;
  end;
end;

function EventIdentifierToBlackboardEvent(Event : EnumEventIdentifier) : boolean;
begin
  case Event of
    eiTeamID, eiPosition, eiFront, eiOwnerCommander,
      eiExiled, eiBuildgridBlockedFields : Result := True;
  else Result := False;
  end;
end;

function ByteArrayToSetBuffType(const arr : TArray<byte>) : SetBuffType;
var
  i : Integer;
begin
  Result := [];
  for i := 0 to length(arr) - 1 do
      Result := Result + [EnumBuffType(arr[i])];
end;

function ByteArrayToSetDamageType(const arr : TArray<byte>) : SetDamageType;
var
  i : Integer;
begin
  Result := [];
  for i := 0 to length(arr) - 1 do
      Result := Result + [EnumDamageType(arr[i])];
end;

function ByteArrayToSetDynamicZone(const arr : TArray<byte>) : SetDynamicZone;
var
  i : Integer;
begin
  Result := [];
  for i := 0 to length(arr) - 1 do
      Result := Result + [EnumDynamicZone(arr[i])];
end;

initialization

ScriptManager.ExposeConstant('ZONE_WALK', ZONE_WALK);
ScriptManager.ExposeConstant('ZONE_DROP', ZONE_DROP);

ScriptManager.ExposeType(TypeInfo(EnumNetworkSender));
ScriptManager.ExposeType(TypeInfo(EnumUnitProperty));
ScriptManager.ExposeType(TypeInfo(EnumTargetTeamConstraint));

ScriptManager.ExposeType(TypeInfo(EnumBuffType));
ScriptManager.ExposeType(TypeInfo(EnumZoneRestriction));
ScriptManager.ExposeType(TypeInfo(EnumDynamicZone));
ScriptManager.ExposeType(TypeInfo(EnumResource));

ScriptManager.ExposeConstant('PVE_TEAM_ID', PVE_TEAM_ID);

ScriptManager.ExposeConstant('GROUP_APPROACH_MAINWEAPON', GROUP_APPROACH_MAINWEAPON);
ScriptManager.ExposeConstant('GROUP_MAINWEAPON', GROUP_MAINWEAPON);
ScriptManager.ExposeConstant('GROUP_TEMPLATE_SPAWNER', GROUP_TEMPLATE_SPAWNER);
ScriptManager.ExposeConstant('GROUP_DROP_SPAWNER', GROUP_DROP_SPAWNER);
ScriptManager.ExposeConstant('GROUP_SPELL_SPAWNER', GROUP_SPELL_SPAWNER);
ScriptManager.ExposeConstant('GROUP_BUILDING_LIFETIME', GROUP_BUILDING_LIFETIME);
ScriptManager.ExposeConstant('GROUP_SOUL', GROUP_SOUL);

ScriptManager.ExposeType(TypeInfo(EnumUnitData));

ScriptManager.ExposeConstant('GAME_EVENT_TECH_LEVEL_2', GAME_EVENT_TECH_LEVEL_2);
ScriptManager.ExposeConstant('GAME_EVENT_TECH_LEVEL_3', GAME_EVENT_TECH_LEVEL_3);
ScriptManager.ExposeConstant('GAME_EVENT_SHOWDOWN', GAME_EVENT_SHOWDOWN);
ScriptManager.ExposeConstant('GAME_EVENT_CLIENT_READY', GAME_EVENT_CLIENT_READY);
ScriptManager.ExposeConstant('GAME_EVENT_SPAWNER_PLACED', GAME_EVENT_SPAWNER_PLACED);
ScriptManager.ExposeConstant('GAME_EVENT_DROP_PLACED', GAME_EVENT_DROP_PLACED);
ScriptManager.ExposeConstant('GAME_EVENT_SPELL_PLACED', GAME_EVENT_SPELL_PLACED);
ScriptManager.ExposeConstant('GAME_EVENT_SPAWNER_SELECTED', GAME_EVENT_SPAWNER_SELECTED);
ScriptManager.ExposeConstant('GAME_EVENT_DROP_SELECTED', GAME_EVENT_DROP_SELECTED);
ScriptManager.ExposeConstant('GAME_EVENT_SPELL_SELECTED', GAME_EVENT_SPELL_SELECTED);
ScriptManager.ExposeConstant('GAME_EVENT_TUTORIAL_HINT_CONFIRMED', GAME_EVENT_TUTORIAL_HINT_CONFIRMED);
ScriptManager.ExposeConstant('GAME_EVENT_GAME_TICK', GAME_EVENT_GAME_TICK);
ScriptManager.ExposeConstant('GAME_EVENT_GAME_TICK_FIRST', GAME_EVENT_GAME_TICK_FIRST);
ScriptManager.ExposeConstant('GAME_EVENT_SKIP_WARMING', GAME_EVENT_SKIP_WARMING);
ScriptManager.ExposeConstant('GAME_EVENT_TOWER_CAPTURED', GAME_EVENT_TOWER_CAPTURED);
ScriptManager.ExposeConstant('GAME_EVENT_FREEZE_GAME', GAME_EVENT_FREEZE_GAME);
ScriptManager.ExposeConstant('GAME_EVENT_UNFREEZE_GAME', GAME_EVENT_UNFREEZE_GAME);
ScriptManager.ExposeConstant('GAME_EVENT_ACTIVATE_SPAWNER', GAME_EVENT_ACTIVATE_SPAWNER);
ScriptManager.ExposeConstant('GAME_EVENT_DEACTIVATE_SPAWNER', GAME_EVENT_DEACTIVATE_SPAWNER);
ScriptManager.ExposeConstant('GAME_EVENT_ACTIVATE_INCOME', GAME_EVENT_ACTIVATE_INCOME);
ScriptManager.ExposeConstant('GAME_EVENT_DEACTIVATE_INCOME', GAME_EVENT_DEACTIVATE_INCOME);
ScriptManager.ExposeConstant('GAME_EVENT_SPAWNER_JUMP', GAME_EVENT_SPAWNER_JUMP);
ScriptManager.ExposeConstant('GAME_EVENT_REFRESH_GOLD', GAME_EVENT_REFRESH_GOLD);
ScriptManager.ExposeConstant('GAME_EVENT_REFRESH_CHARGES', GAME_EVENT_REFRESH_CHARGES);
ScriptManager.ExposeConstant('GAME_EVENT_ACTIVATE_CARD_COST', GAME_EVENT_ACTIVATE_CARD_COST);
ScriptManager.ExposeConstant('GAME_EVENT_DEACTIVATE_CARD_COST', GAME_EVENT_DEACTIVATE_CARD_COST);
ScriptManager.ExposeConstant('GAME_EVENT_CARD_DESELECTED', GAME_EVENT_CARD_DESELECTED);
ScriptManager.ExposeConstant('GAME_EVENT_GIVE_GOLD_PREFIX', GAME_EVENT_GIVE_GOLD_PREFIX);
ScriptManager.ExposeConstant('GAME_EVENT_GIVE_WOOD_PREFIX', GAME_EVENT_GIVE_WOOD_PREFIX);
ScriptManager.ExposeConstant('GAME_EVENT_SET_GOLD_PREFIX', GAME_EVENT_SET_GOLD_PREFIX);
ScriptManager.ExposeConstant('GAME_EVENT_SET_WOOD_PREFIX', GAME_EVENT_SET_WOOD_PREFIX);

end.
