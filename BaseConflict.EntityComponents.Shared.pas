unit BaseConflict.EntityComponents.Shared;

interface

uses
  Generics.Collections,
  Math,
  RTTI,
  SysUtils,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Collision,
  Engine.Serializer,
  Engine.Network,
  Engine.Script,
  Engine.Log,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Entity,
  BaseConflict.Map,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Classes.Shared,
  BaseConflict.Classes.Pathfinding;

type

  ProcFilterFunction = reference to function(Entity : TEntity) : single;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$RTTI INHERIT}

  /// <summary> Adds a unit property to an entity as long this component is attached to this entity. </summary>
  TUnitPropertyComponent = class(TEntityComponent)
    protected
      FGiveOwner, FRemove : boolean;
      FUnitProperties : SetUnitProperty;
    published
      function GetCommanderUnitProperties(Previous : RParam) : RParam;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterCreate() : boolean;
      [XEvent(eiUnitProperties, epMiddle, etRead)]
      /// <summary> Adds the unit properties. </summary>
      function OnUnitProperties(Previous : RParam) : RParam;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>; AttachedProperties : TArray<byte>); reintroduce;
      /// <summary> Remove the unit properties instead of adding them. </summary>
      function Remove : TUnitPropertyComponent;
      /// <summary> Gives the property the owning commander instead of this unit. </summary>
      function GivePropertyOwner() : TUnitPropertyComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> A global manager component, which throws events at certain game ticks and manages eiGameEventTimeTo events. </summary>
  TGameDirectorComponent = class(TEntityComponent)
    protected
      type
      RGameDirectorAction = record
        GameTick : integer;
        Eventname : string;
      end;
    var
      FActions : TList<RGameDirectorAction>;
    published
      [XEvent(eiGameEventTimeTo, epFirst, etRead, esGlobal)]
      /// <summary> Returns the time to this event. </summary>
      function OnGameEventTimeTo(Eventname, Previous : RParam) : RParam;
      {$IFDEF SERVER}
      [XEvent(eiGameTick, epHigh, etTrigger, esGlobal)]
      /// <summary> Check on each game tick, whether a event should be fired. </summary>
      function OnGameTick() : boolean;
      {$ENDIF}
    public
      constructor Create(Owner : TEntity); override;
      function AddEvent(GameTick : integer; Eventname : string) : TGameDirectorComponent;
      function AddEventIf(Condition : boolean; GameTick : integer; Eventname : string) : TGameDirectorComponent;
      function ClearEvents : TGameDirectorComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Adjust the eiWeladamage of its group so its linear depleting over time (1.0 at eiCooldown).</summary>
  TNexusEarlyVulnerabilityComponent = class(TEntityComponent)
    published
      [XEvent(eiWelaDamage, epHigh, etRead)]
      /// <summary> Adjust damage according the depleted time. </summary>
      function OnWelaDamage(Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles synchronous positioning of entities. </summary>
  TPositionComponent = class(TSerializableEntityComponent)
    published
      [XEvent(eiSyncPosition, epLast, etTrigger)]
      /// <summary> Move entity to synchronized position. </summary>
      function OnSyncPosition(Pos : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles movement of units. </summary>
  TMovementComponent = class(TPositionComponent)
    private
      {$IFDEF SERVER}
      FSyncTimer : TTimer;
      {$ENDIF}
      {$IFDEF CLIENT}
      FOverwriteMovementSpeed : boolean;
      FOverwrittenSpeed : single;
      {$ENDIF}
      FTargetPathfindingPosition : RVector2;
    protected
      [XNetworkSerialize(eiMoveTo)]
      FTarget : RTarget;
      FPath : TArray<RSmallIntVector2>;
      FMoving, FUsePathfinding : boolean;
      FRange : single;
      function TargetReached : boolean;
      procedure ComputeNewPath;
      procedure IdlePathfinding;
      procedure IdleDirect;
      {$IFDEF CLIENT}
      function OptimizePath(const Path : TArray<TPathfindingTile>) : TArray<TPathfindingTile>;
      {$ENDIF}
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Init. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiExiled, epLast, etWrite)]
      /// <summary> Unit stops movement on exile. </summary>
      function OnExiled(Exiled : RParam) : boolean;
      [XEvent(eiIsMoving, epFirst, etRead)]
      function OnIsMoving() : RParam;
      [XEvent(eiMoveTo, epLast, etTrigger)]
      /// <summary> Sets the new movementtarget and start moving. </summary>
      function OnMoveTo(Target : RParam; Range : RParam) : boolean;
      [XEvent(eiMoveTargetReached, epFirst, etRead)]
      /// <summary> Return whether the target has been reached. Instead of polling should be
      /// register on trigger. </summary>
      function OnMoveTargetReached() : RParam;
      [XEvent(eiStand, epFirst, etTrigger)]
      /// <summary> Stand still, now. </summary>
      function OnStand() : boolean;
      [XEvent(eiMove, epLast, etTrigger)]
      /// <summary> Sets the entity to the target. </summary>
      function OnMove(Target : RParam) : boolean;
      [XEvent(eiSyncPath, epLast, etTrigger)]
      /// <summary> Sets the walking path of the unit. </summary>
      function OnSyncPath(Start, Target, Path : RParam) : boolean;
      [XEvent(eiIdle, epHigher, etTrigger, esGlobal)]
      /// <summary> Compute movement. </summary>
      function OnIdle() : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> If unit dies, it shouldn't move any longer. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiLose, epMiddle, etTrigger, esGlobal)]
      /// <summary> Stop movement on lose. </summary>
      function OnLose(TeamID : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); reintroduce;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Manages the health of a unit. </summary>
  THealthComponent = class(TSerializableEntityComponent)
    protected const
      OVERHEAL_LIMIT_FACTOR = 2.0;
    protected
      FIsAlive, FInstaDeath : boolean;
      FKillerCommanderID, FKillerID : integer;
      function IsAlive : boolean;
      function IsInvincible : boolean;
      function CanBeHealed : boolean;
      function CurrentHealth : single;
      function MaxHealth : single;
      function CurrentOverheal : single;
      function MaxOverheal : single;
      procedure UpdateAlive;
      procedure ResolveKiller(ID : integer);
    published
      {$IFDEF SERVER}
      [XEvent(eiTakeDamage, epLower, etRead)]
      /// <summary> Take some damage. </summary>
      function OnDamage(Amount : RParam; DamageType : RParam; InflictorID, Previous : RParam) : RParam;
      [XEvent(eiHeal, epLast, etRead)]
      /// <summary> Receive some heal. </summary>
      function OnHeal(var Amount : RParam; HealModifier, InflictorID : RParam) : RParam;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Send killevents until unit is dead, when Health is 0. </summary>
      function OnIdle() : boolean;
      [XEvent(eiKill, epLast, etTrigger)]
      /// <summary> Kills the unit instantly. </summary>
      function OnKill(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiResourceCap, epLast, etWrite)]
      /// <summary> Adjusts dynamic caps like overheal. </summary>
      function OnWriteResourceCap(ResourceID, Amount : RParam) : boolean;
      {$ENDIF}
      [XEvent(eiIsAlive, epFirst, etRead)]
      /// <summary> Return alivestate. Do we need this? </summary>
      function OnIsAlive() : RParam;
      [XEvent(eiIsAlive, epLast, etWrite)]
      /// <summary> Set alivestate. Do we need this? </summary>
      function OnSetIsAlive(IsAlive : RParam) : boolean;
      [XEvent(eiDamageable, epFirst, etRead)]
      /// <summary> Returns true if alive. </summary>
      function OnDamageable() : RParam;
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> Sets the unit to dead. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiUnitProperties, epMiddle, etRead)]
      /// <summary> Tags the unit with certain properties. </summary>
      function OnUnitProperies(Previous : RParam) : RParam;
    public
      constructor Create(Owner : TEntity); override;
  end;

  RCommanderCard = record
    CardUID : string;
    League, Level : integer;
    constructor Create(const CardUID : string; League, Level : integer);
    constructor CreateMaxed(const CardUID : string);
  end;

  {$RTTI INHERIT}

  /// <summary> Transfers all commander abilities to the clients as they are generated on server side.
  /// This component will created on server side only and then transferred to the client. </summary>
  TCommanderAbilityComponent = class(TSerializableEntityComponent)
    protected
      FSlot : integer;
      // deserialization of records with string explodes, so don't use RCommanderCard here
      FCardUID : string;
      FCardLeague, FCardLevel : integer;
      procedure Init;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Apply the scripts on the client. </summary>
      function OnAfterCreate() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Card : RCommanderCard); reintroduce;
      constructor CreateGroupedSlot(Owner : TEntity; Group : TArray<byte>; Card : RCommanderCard; Slot : integer);
  end;

  {$RTTI INHERIT}

  ANetworkParameters = array of TValue;

  /// <summary> Handles all networktasks. </summary>
  TNetworkComponent = class(TEntityComponent)
    protected
      FNetworkDelay : integer;
      procedure NewData(Data : TDatapacket); virtual;
    published
      [XEvent(eiNetworkSend, epLast, etTrigger, esGlobal)]
      /// <summary> Send an event via the network. </summary>
      function OnNetworkSend(EntityID : RParam; Event : RParam; Group : RParam; ComponentID : RParam; Parameters : RParam; Write : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      procedure Send(Data : TCommandSequence); virtual; abstract;
      destructor Destroy; override;
  end;

  ProcEntityFilterFunction = reference to function(Entity : TEntity) : boolean;

  {$RTTI INHERIT}

  /// <summary> Manages all deployed entities. Provides several global methods. </summary>
  TEntityManagerComponent = class(TEntityComponent)
    private
      function GetDeployedEntityCount() : integer;
    protected
      FEntities : TDictionary<integer, TEntity>;
      FComponentGroupsToKill : TList<RTuple<integer, SetComponentGroup>>;
      FComponentsToKill : TList<RTuple<integer, integer>>;
      FIDCounter : integer;
      FNexusList : TList<TEntity>;
      FEntitiesToFree : TList<TEntity>;
      procedure NewEntity(Entity : TEntity); virtual;
      procedure KillDeferred;
      procedure BeforeComponentFree; override;
    published
      [XEvent(eiNewEntity, epMiddle, etTrigger, esGlobal)]
      /// <summary> Register the entity. </summary>
      function OnNewEntity(Entity : RParam) : boolean;
      [XEvent(eiRemoveComponent, epLast, etTrigger, esGlobal)]
      /// <summary> Frees the component of the entity. </summary>
      function OnRemoveComponent(EntityID, ComponentID : RParam) : boolean;
      [XEvent(eiRemoveComponentGroup, epLast, etTrigger, esGlobal)]
      /// <summary> Frees the componentgroup of the entity. </summary>
      function OnRemoveComponentGroup(EntityID : RParam; ComponentGroup : RParam) : boolean;
      [XEvent(eiKillEntity, epLast, etTrigger, esGlobal)]
      /// <summary> Frees the entity. </summary>
      function OnKillEntity(EntityID : RParam) : boolean;
      [XEvent(eiSetGridFieldBlocking, epLast, etWrite, esGlobal)]
      /// <summary> Set whether a field of a build grid is blocked and cannot be build over. </summary>
      function OnSetGridFieldBlocking(GridID, GridCoord, BlockingEntityID : RParam) : boolean;
      [XEvent(eiReplaceEntity, epLower, etTrigger, esGlobal)]
      /// <summary> Updates the grid. </summary>
      function OnReplaceEntity(oldEntityID, newEntityID, isSameEntity : RParam) : boolean;
    public
      {$IFDEF DEBUG}
      [ScriptExcludeMember]
      property Entities : TDictionary<integer, TEntity> read FEntities;
      {$ENDIF}
      property DeployedEntityCount : integer read GetDeployedEntityCount;
      constructor Create(Owner : TEntity); override;
      /// <summary> Returns a list of all deployed entities. List have to be freed. </summary>
      [ScriptExcludeMember]
      function GetDeployedEntityList : TList<TEntity>;
      /// <summary> Generate unique EntityID. IDs starting at 2 (IDs < 0 are invalid, 0 is global eventbus, 1 is game entity) and increasing one by one. </summary>
      function GenerateUniqueID : integer;
      function HasEntityByID(ID : integer) : boolean;
      /// <summary> Return the Entity to the ID if found, otherwise nil. </summary>
      function GetEntityByID(ID : integer) : TEntity;
      /// <summary> Return the Entity to the UID if found, otherwise nil. </summary>
      function GetEntityByUID(UID : string) : TEntity;
      /// <summary> Remote invokes an event on target entities eventbus. </summary>
      procedure InvokeEventOnEntity(EntityID : integer; Eventname : EnumEventIdentifier; const Group : SetComponentGroup; ComponentID : integer; RawParameters : TArray<byte>; Write : boolean);
      /// <summary> Frees the given componentgroup of the entity at the beginning of the next frame. </summary>
      procedure FreeComponentGroup(EntityID : integer; Group : SetComponentGroup);
      procedure FreeComponent(EntityID, ComponentID : integer); overload;
      procedure FreeComponent(Component : TEntityComponent); overload;
      /// <summary> A safe way to free entities without being in a event stack. </summary>
      procedure FreeEntity(Entity : TEntity);
      function FilterEntities(MustHave, MustNotHave : SetUnitProperty) : TList<TEntity>;
      /// <summary> List is managed </summary>
      function NexusList : TList<TEntity>;
      function NexusByTeamID(TeamID : integer) : TEntity;
      function TryGetNexusByTeamID(TeamID : integer; out Nexus : TEntity) : boolean;
      /// <summary> Retrieves the next hostile nexus. </summary>
      function NexusNextEnemy(Position : RVector2; MyTeamID : integer) : TEntity;
      function NexusNext(Position : RVector2) : TEntity;
      function TryGetNexusNextEnemy(Position : RVector2; MyTeamID : integer; out Nexus : TEntity) : boolean; overload;
      function TryGetNexusNextEnemy(reference : TEntity; out Nexus : TEntity) : boolean; overload;
      function TryGetEntityByID(ID : integer; out Entity : TEntity) : boolean;
      function TryGetEntityByUID(UID : string; out Entity : TEntity) : boolean;
      /// <summary> Return the owning commander of the entity if found, otherwise nil. </summary>
      function GetOwningCommander(Entity : TEntity) : TEntity;
      function TryGetOwningCommander(Entity : TEntity; out Commander : TEntity) : boolean;
      /// <summary> Returns the number of existing entities with the given unitproperties and matching the team constraint. </summary>
      function EntityCountByUnitProperty(const UnitProperties : SetUnitProperty; CountTeamConstraint : EnumTargetTeamConstraint = tcAll; TeamID : integer = -1) : integer;
      procedure Idle; virtual;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  TGameTickComponent = class(TEntityComponent)
    protected
      FTickTimer : TTimer;
      FTickCounter : integer;
    published
      [XEvent(eiGameCommencing, epMiddle, etTrigger, esGlobal)]
      /// <summary> Starts first spawntimer. </summary>
      function OnGameCommencing() : boolean;
      {$IFDEF SERVER}
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Check for spawning. </summary>
      function OnIdle() : boolean;
      {$ENDIF}
      [XEvent(eiGameTick, epHigher, etTrigger, esGlobal)]
      /// <summary> Resets tick timer. </summary>
      function OnGameTick() : boolean;
      [XEvent(eiGameTickTimeToFirstTick, epFirst, etRead, esGlobal)]
      /// <summary> Get ms to next tick. </summary>
      function OnGetTimeToFirstTick() : RParam;
      [XEvent(eiGameTickCounter, epFirst, etRead, esGlobal)]
      /// <summary> Get current game tick counter. </summary>
      function OnGetGameTickCounter() : RParam;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Component for handling resource within an entity. </summary>
  TResourceManagerComponent = class(TEntityComponent)
    protected
      FInitialValues : TDictionary<integer, RParam>;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Save initial values. </summary>
      function OnAfterCreate() : boolean;

      [XEvent(eiResourceReset, epLast, etTrigger)]
      /// <summary> Returns the balance of the resource. </summary>
      function OnResetResource(ResourceID : RParam) : boolean;

      [XEvent(eiResourceBalance, epFirst, etRead)]
      /// <summary> Returns the balance of the resource. </summary>
      function OnGetResource(ResourceID, Previous : RParam) : RParam;
      [XEvent(eiResourceBalance, epLast, etWrite)]
      /// <summary> Sets the balance of the resource. </summary>
      function OnSetResource(ResourceID, Amount : RParam) : boolean;

      [XEvent(eiResourceTransaction, epFirst, etRead)]
      /// <summary> Return whether transaction can be made inbound. </summary>
      function OnCanTransact(ResourceID, Amount, Previous : RParam) : RParam;
      [XEvent(eiResourceTransaction, epLast, etTrigger)]
      /// <summary> Executes the transaction. </summary>
      function OnTransact(ResourceID, Amount : RParam) : boolean;

      [XEvent(eiResourceSubtraction, epFirst, etRead)]
      /// <summary> Return whether negative transaction can be made inbound. </summary>
      function OnCanTransactNegative(ResourceID, Amount, Previous : RParam) : RParam;
      [XEvent(eiResourceSubtraction, epLast, etTrigger)]
      /// <summary> Executes the negative transaction. </summary>
      function OnTransactNegative(ResourceID, Amount : RParam) : boolean;

      [XEvent(eiResourceCap, epFirst, etRead)]
      /// <summary> Returns the upper bound of the resource. </summary>
      function OnGetResourceCap(ResourceID, Previous : RParam) : RParam;
      [XEvent(eiResourceCap, epLast, etWrite)]
      /// <summary> Sets the upper bound of the resource. </summary>
      function OnSetResourceCap(ResourceID, Amount : RParam) : boolean;

      [XEvent(eiResourceCost, epFirst, etRead)]
      /// <summary> Returns the amount of the resources. </summary>
      function OnGetResourceCost(Previous : RParam) : RParam;
      [XEvent(eiResourceCost, epLast, etWrite)]
      /// <summary> Saves the new cost. </summary>
      function OnSetResourceCost(ResourceID, Amount : RParam) : boolean;

      [XEvent(eiResourceCapTransaction, epLast, etTrigger)]
      /// <summary> Adjusts the upper bound of the resource. </summary>
      function OnResourceCapTransaction(ResourceID, Amount, Empty : RParam) : boolean;
    public
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Component for spatial management and collision tests of units </summary>
  TCollisionManagerComponent = class(TEntityComponent)
    protected
      FQuadTree : TEntityLooseQuardtree;
    published
      [XEvent(eiClosestEntityInRange, epFirst, etRead, esGlobal)]
      /// <summary> Return the closest matching entity. </summary>
      function OnClosestEntityInRange(Pos, Range : RParam; SourceTeamID, TargetTeamConstraint : RParam; Filter : RParam) : RParam;

      [XEvent(eiEntitiesInRange, epFirst, etRead, esGlobal)]
      /// <summary> Return all matching entities. </summary>
      function OnEntitiesInRangeOf(Pos : RParam; Range : RParam; SourceTeamID, TargetTeamConstraint : RParam; Filter : RParam) : RParam;
    public
      constructor Create(Owner : TEntity); override;
      procedure RegisterCollidable(Collidable : TLooseQuadTreeNodeData<TEntity>);
      procedure RemoveCollidable(Collidable : TLooseQuadTreeNodeData<TEntity>);
      destructor Destroy(); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Adds infinite resources to all commanders. </summary>
  TSandboxComponent = class(TEntityComponent)
    published
      [XEvent(eiGameCommencing, epLast, etTrigger, esGlobal)]
      function OnGameCommencing() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Component that keeps the entity up-to-date in the spatial partitioning
  /// data structure within the TCollisionComponentManager. All units are handled as spheres.</summary>
  TCollisionComponent = class(TEntityComponent)
    protected
      FRegistered : boolean;
      FElement : TEntityLooseQuadtreeData;
      FRadius : single;
    published
      [XEvent(eiPosition, epLast, etWrite)]
      /// <summary> Updates the collidable. </summary>
      function OnWritePosition(Position : RParam) : boolean;
      [XEvent(eiTeamID, epLast, etWrite)]
      /// <summary> Updates the LooseQuadtreeData. </summary>
      function OnWriteTeamID(TeamID : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> Dead units don't have any repulsioneffect on other units. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiExiled, epLast, etWrite)]
      /// <summary> Exiled units are not on the battlefield anymore. </summary>
      function OnExiled(IsExiled : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); reintroduce;
      destructor Destroy(); override;
  end;

  TPathfindingComponent = class(TEntityComponent)
    private
      FCurrentTile : TPathfindingTile;
    published
      [XEvent(eiPosition, epLast, etWrite)]
      /// <summary> Updates the position on map. </summary>
      function OnWritePosition(Position : RParam) : boolean;
      [XEvent(eiStand, epLast, etTrigger)]
      /// <summary> If stand, the entity should no longer reserve any timeslots.</summary>
      function OnStand() : boolean;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> If a entity is created it will block a tile</summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiPathfindingTile, epFirst, etRead)]
      /// <summary> Return the current used pathfinding tile </summary>
      function OnPathfindingTile() : RParam;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy(); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Takes different armor into account while damaging (type and value). </summary>
  TArmorComponent = class(TEntityComponent)
    published
      [XEvent(eiTakeDamage, epMiddle, etRead)]
      /// <summary> Adjust damage according to the ArmorMatrix and the armor value of the unit. </summary>
      function OnDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Manages the default income of a commander. WARNING: Component only for commander! </summary>
  TCommanderIncomeComponent = class(TEntityComponent)
    protected
      function AdjustIncome(const Income : RIncome) : RIncome; virtual;
    published
      [XEvent(eiIncome, epMiddle, etRead, esGlobal)]
      /// <summary> Set up default income. </summary>
      function OnReadIncome(CommanderID, Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Manages the default income of a commander. WARNING: Component only for commander! </summary>
  TCommanderIncomeDefaultComponent = class(TCommanderIncomeComponent)
    protected
      function AdjustIncome(const Income : RIncome) : RIncome; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Makes adjustments to the current income. </summary>
  TCommanderIncomeLoanComponent = class(TCommanderIncomeComponent)
    protected
      FFactor : single;
      FTimer : TTimer;
      function AdjustIncome(const Income : RIncome) : RIncome; override;
    public
      /// <summary> Rate of income increase. </summary>
      function Factor(Factor : single) : TCommanderIncomeLoanComponent;
      /// <summary> Time of income increase. Will reduce transform gold income for the duration * factor / 2 afterwards. </summary>
      function Duration(Duration : integer) : TCommanderIncomeLoanComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Manages the overflow of income of a commander. WARNING: Component only for commander! </summary>
  TCommanderIncomeOverflowComponent = class(TCommanderIncomeComponent)
    protected
      function AdjustIncome(const Income : RIncome) : RIncome; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  EnumDynamicZoneResult = (drNone, drTrue, drFalse);

  /// <summary> Emits a dynamic zone around this unit. </summary>
  TDynamicZoneEmitterComponent = class abstract(TEntityComponent)
    protected
      FDynamicZone : SetDynamicZone;
      FNegate : boolean;
      function IsInDynamicZone(Position : RVector2; TeamID : integer) : EnumDynamicZoneResult; virtual; abstract;
    published
      [XEvent(eiInDynamicZone, epMiddle, etRead, esGlobal), ScriptExcludeMember]
      /// <summary> Checks whether the position is covered by this emitter. </summary>
      function OnInDynamicZone(Position, TeamID, Zone, Previous : RParam) : RParam;
    public
      function SetZone(Zone : TArray<byte>) : TDynamicZoneEmitterComponent;
      function Exclude : TDynamicZoneEmitterComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Emits a radial dynamic zone around this unit. </summary>
  TDynamicZoneRadialEmitterComponent = class(TDynamicZoneEmitterComponent)
    protected
      function IsInDynamicZone(Position : RVector2; TeamID : integer) : EnumDynamicZoneResult; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Emits a dynamic zone depending on the dot-product with a normal. >= 0 True </summary>
  TDynamicZoneAxisEmitterComponent = class(TDynamicZoneEmitterComponent)
    protected
      FNormal, FPosition : RVector2;
      function IsInDynamicZone(Position : RVector2; TeamID : integer) : EnumDynamicZoneResult; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SetPosition(X, Y : single) : TDynamicZoneAxisEmitterComponent;
      function SetNormal(X, Y : single) : TDynamicZoneAxisEmitterComponent;
  end;

  {$RTTI INHERIT}

  [XNetworkBaseType]
  /// <summary> Only nexus get this component. Lose-Condition for teams. </summary>
  TPrimaryTargetComponent = class(TSerializableEntityComponent)
    published
      [XEvent(eiEnumerateNexus, epFirst, etRead, esGlobal)]
      /// <summary> Return this as RTarget if team matches. </summary>
      function OnGetNexusPosition(Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect set game events globally on fire. </summary>
  TGameEventEnumeratorComponent = class(TEntityComponent)
    protected
      FGameEvents : TArray<string>;
    published
      [XEvent(eiGameEvent, epMiddle, etRead, esGlobal)]
      function OnGameEvent(Event, Previous : RParam) : RParam;
    public
      /// <summary> Adds an event, which will be set on fire.</summary>
      function Event(const EventID : string) : TGameEventEnumeratorComponent;
  end;

implementation

uses
  {$IFDEF SERVER}
  BaseConflict.Globals.Server,
  {$ENDIF}
  BaseConflict.Globals;

{ TPositionComponent }

function TPositionComponent.OnSyncPosition(Pos : RParam) : boolean;
begin
  Result := True;
  Owner.Position := Pos.AsVector2;
end;

{ TMovementComponent }

procedure TMovementComponent.ComputeNewPath;
var
  Path : TArray<TPathfindingTile>;
  CoordPath : TArray<RSmallIntVector2>;
  i : integer;
  AEntity : TEntity;
  IgnoreOtherEntities, UseWaypoints : boolean;
begin
  Map.Pathfinding.CancelLastComputedPath(Owner);
  // negate because IgnoreOtherEntities is the opposite of USE_PATHFINDING
  // USE_PATHFINDING is confusing caption, because if value false pathfinding will used but without
  // takeing other entites into account (entity will block timeslots but ignore other an so will walk through units)
  IgnoreOtherEntities := not Owner.UnitData(udUsePathfinding).AsTypeDefault(True);
  // Use direct (beeline heuristic) pathfinding if non-nexus entity is targeted
  if FTarget.IsEntity and FTarget.TryGetTargetEntity(AEntity) then
  begin
    // is nexus?
    if upNexus in AEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then
        UseWaypoints := True
    else
        UseWaypoints := False;
  end
  else
      UseWaypoints := False;
  Path := Map.Pathfinding.ComputePath(Owner, FTarget.GetTargetPosition, PATHFINDING_MAX_COMPUTED_PATH_LENGTH, UseWaypoints, IgnoreOtherEntities);
  SetLength(CoordPath, Length(Path));
  for i := 0 to Length(CoordPath) - 1 do
      CoordPath[i] := Path[i].GridPosition;
  Eventbus.Trigger(eiSyncPath, [Owner.Position, FTarget.GetTargetPosition, RParam.FromArray<RSmallIntVector2>(CoordPath)]);
end;

constructor TMovementComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  {$IFDEF SERVER}
  FSyncTimer := TTimer.CreateAndStart(UNITSYNCINTERVAL);
  {$ENDIF}
end;

destructor TMovementComponent.Destroy;
begin
  {$IFDEF SERVER}
  FSyncTimer.Free;
  {$ENDIF}
  inherited;
end;

procedure TMovementComponent.IdleDirect;
var
  Position, targetPos, between : RVector2;
  distance, walkingdistance : single;
begin
  if FMoving then
  begin
    walkingdistance := GameTimeManager.ZDiff * Eventbus.Read(eiSpeed, []).AsSingle;
    Position := Owner.Position;
    targetPos := FTarget.GetTargetPosition;
    between := targetPos - Position;
    distance := between.Length;
    if TargetReached then
    begin
      between := between.SetLength(FRange);
      Eventbus.Trigger(eiMove, [targetPos - between]);
      Eventbus.Trigger(eiStand, []);
      exit;
    end;
    if distance - FRange <= walkingdistance then
    begin
      between := between.SetLength(FRange);
      Eventbus.Trigger(eiMove, [targetPos - between]);
      Eventbus.Trigger(eiStand, []);
    end
    else
    begin
      between := targetPos - Position;
      Eventbus.Trigger(eiMove, [Position + (walkingdistance * between.Normalize)]);
    end;
  end;

  {$IFDEF SERVER}
  if FSyncTimer.Expired then
  begin
    Position := Owner.Position;
    Eventbus.Trigger(eiSyncPosition, [Position]);
    FSyncTimer.Start;
  end;
  {$ENDIF}
end;

procedure TMovementComponent.IdlePathfinding;
var
  Position, targetPos, between : RVector2;
  distance, walkingdistance : single;
  NextNode, TargetTile : TPathfindingTile;
  {$IFDEF SERVER}
  CurrentTile : TPathfindingTile;
  {$ENDIF}
begin
  if FMoving then
  begin
    {$IFDEF CLIENT}
    if FOverwriteMovementSpeed then
        walkingdistance := GameTimeManager.ZDiff * FOverwrittenSpeed
    else
      {$ENDIF}
        walkingdistance := GameTimeManager.ZDiff * Eventbus.Read(eiSpeed, []).AsSingle;
    // safety for lags
    if (walkingdistance > 50) or (walkingdistance < 0) then walkingdistance := 0;
    if FUsePathfinding then
    begin
      Position := Owner.Position;
      {$IFDEF SERVER}
      if Length(FPath) <= 0 then
      begin
        ComputeNewPath;
        exit;
      end;
      {$ENDIF}
      while Length(FPath) > 0 do
      begin
        NextNode := Map.Pathfinding.GridBy2D[FPath[high(FPath)]];
        {$IFDEF SERVER}
        CurrentTile := Owner.Eventbus.Read(eiPathfindingTile, []).AsType<TPathfindingTile>;
        // if a tile (where unit next want to walk) and where the unit currently not stand, is
        // blocked, we need a new path, old path is no longer valid
        if (CurrentTile <> NextNode) and NextNode.IsBlocked then
        begin
          // we need a new path
          ComputeNewPath;
          exit;
        end;
        {$ENDIF}
        TargetTile := Map.Pathfinding.GetTileByPosition(FTargetPathfindingPosition);
        if NextNode = TargetTile then
            targetPos := FTargetPathfindingPosition
        else
            targetPos := NextNode.WorldSpaceBoundaries.Center;
        distance := Position.distance(targetPos);
        if distance <= walkingdistance then
        begin
          Position := targetPos;
          Eventbus.Trigger(eiMove, [Position]);
          walkingdistance := walkingdistance - distance;
          SetLength(FPath, Length(FPath) - 1);
          continue;
        end
        else
        begin
          between := (targetPos - Position).Normalize;
          Position := Position + (between * walkingdistance);
          break;
        end;
      end;
      Eventbus.Trigger(eiMove, [Position]);
      if TargetReached then
          Eventbus.Trigger(eiStand, []);
    end
  end;
end;

function TMovementComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  Eventbus.Trigger(eiStand, []);
end;

function TMovementComponent.OnExiled(Exiled : RParam) : boolean;
begin
  Result := True;
  if Exiled.AsBoolean then
      Eventbus.Trigger(eiStand, []);
end;

function TMovementComponent.OnIdle : boolean;
begin
  Result := True;
  if FUsePathfinding then IdlePathfinding
  else IdleDirect;
end;

function TMovementComponent.OnIsMoving : RParam;
begin
  Result := FMoving;
end;

function TMovementComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  {$IFDEF SERVER}
  FMoving := False;
  {$ELSE}
  Eventbus.Trigger(eiStand, []);
  {$ENDIF}
end;

function TMovementComponent.OnMove(Target : RParam) : boolean;
var
  Front : RVector2;
begin
  Result := True;
  Front := Owner.Position.DirectionTo(Target.AsVector2);
  if not Front.IsZeroVector then
      Owner.Front := Front;
  Owner.Position := Target.AsVector2;
end;

function TMovementComponent.OnMoveTargetReached : RParam;
begin
  Result := TargetReached;
end;

function TMovementComponent.OnMoveTo(Target : RParam; Range : RParam) : boolean;
var
  NewTarget : RTarget;
  Position : RVector2;
begin
  FRange := Range.AsSingle;
  NewTarget := Target.AsType<RTarget>;
  // cannot move to empty target
  if NewTarget.IsEmpty then exit(True);
  // only start moving if new target is different from current or we're not moving at the moment
  Result := (FTarget <> NewTarget) or not FMoving;
  if Result then
  begin
    Position := Owner.Position;
    FTarget := NewTarget;
    FMoving := True;
    {$IFDEF SERVER}
    if FUsePathfinding then
        ComputeNewPath;
    Eventbus.Trigger(eiSyncPosition, [Position]);
    {$ENDIF}
  end;
end;

function TMovementComponent.OnStand() : boolean;
begin
  Result := FMoving;
  FMoving := False;
  if Result then
  begin
    FPath := nil;
    {$IFDEF SERVER}
    Eventbus.Trigger(eiSyncPosition, [Owner.Position]);
    {$ENDIF}
    Eventbus.Trigger(eiMoveTargetReached, []);
  end;
end;

function TMovementComponent.OnSyncPath(Start, Target, Path : RParam) : boolean;
{$IFDEF CLIENT}
var
  optimizedPath, nodePath : TArray<TPathfindingTile>;
  oldLength : single;
  {$ENDIF}
begin
  Result := True;
  FTargetPathfindingPosition := Target.AsVector2;
  {$IFDEF CLIENT}
  nodePath := HArray.Map<RSmallIntVector2, TPathfindingTile>(Path.AsArray<RSmallIntVector2>,
    function(const Coord : RSmallIntVector2) : TPathfindingTile
    begin
      Result := Map.Pathfinding.GridBy2D[Coord];
    end);
  optimizedPath := OptimizePath(nodePath);
  if Length(optimizedPath) <> Length(nodePath) then
  begin
    oldLength := Map.Pathfinding.ComputePathLength(nodePath);
    FOverwrittenSpeed := Map.Pathfinding.ComputePathLength(optimizedPath) * Eventbus.Read(eiSpeed, []).AsSingle / oldLength;
    FOverwriteMovementSpeed := True;
  end
  else FOverwriteMovementSpeed := False;
  FPath := HArray.Map<TPathfindingTile, RSmallIntVector2>(optimizedPath,
    function(const Tile : TPathfindingTile) : RSmallIntVector2
    begin
      Result := Tile.GridPosition;
    end);
  FPath := HArray.Reverse<RSmallIntVector2>(FPath);
  {$ELSE}
  FPath := HArray.Reverse<RSmallIntVector2>(Path.AsArray<RSmallIntVector2>);
  {$ENDIF}
end;

{$IFDEF CLIENT}


function TMovementComponent.OptimizePath(const Path : TArray<TPathfindingTile>) : TArray<TPathfindingTile>;
var
  NodeCount : integer;
  node, NextNode, Target : TPathfindingTile;
  i : integer;
  procedure AddNode(node : TPathfindingTile);
  begin
    Result[NodeCount] := node;
    inc(NodeCount);
  end;

begin
  // if path is shorter or equal two nodes, there is nothing to optimize
  if Length(Path) > 2 then
  begin
    NodeCount := 0;
    SetLength(Result, Length(Path));
    Target := Path[Length(Path) - 1];
    // the first node belongs to every path
    AddNode(Path[0]);
    for i := 1 to Length(Path) - 2 do
    begin
      NextNode := Path[i + 1];
      node := Path[i];
      // if next node is best choice, we don't need it in path because the node
      // is only the discreet
      if node.GetOptimalNeighbour(Target) = NextNode then
          continue
      else
          AddNode(node);
    end;
    // the last node belongs to every path
    AddNode(Target);
    SetLength(Result, NodeCount);
  end
  else
      Result := Path;
end;
{$ENDIF}


function TMovementComponent.TargetReached : boolean;
var
  Position : RVector2;
begin
  Position := Owner.Position;
  if FUsePathfinding then
      Result := Map.Pathfinding.GetTileByPosition(Position) = Map.Pathfinding.GetTileByPosition(FTarget.GetTargetPosition)
  else
      Result := Position.distance(FTarget.GetTargetPosition) - FRange <= SPATIALEPSILON;
end;

function TMovementComponent.OnAfterCreate() : boolean;
begin
  Result := True;
  FUsePathfinding := Owner.UnitData(udUsePathfinding).AsBoolean;
end;

{ THealthComponent }

function THealthComponent.CanBeHealed : boolean;
begin
  Result := not(upUnhealable in Owner.UnitProperties) and IsAlive;
end;

constructor THealthComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FIsAlive := True;
  FKillerID := -1;
  FKillerCommanderID := -1;
  FInstaDeath := True;
  Eventbus.Write(eiResourceCap, [ord(reOverheal), MaxHealth * OVERHEAL_LIMIT_FACTOR]);
end;

function THealthComponent.CurrentHealth : single;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(reHealth)]).AsSingle;
end;

function THealthComponent.CurrentOverheal : single;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(reOverheal)]).AsSingle;
end;

function THealthComponent.IsAlive : boolean;
begin
  Result := Eventbus.Read(eiIsAlive, []).AsBoolean;
end;

function THealthComponent.IsInvincible : boolean;
begin
  Result := Owner.HasUnitProperty(upInvincible);
end;

function THealthComponent.MaxHealth : single;
begin
  Result := Eventbus.Read(eiResourceCap, [ord(reHealth)]).AsSingle;
end;

function THealthComponent.MaxOverheal : single;
begin
  Result := Eventbus.Read(eiResourceCap, [ord(reOverheal)]).AsSingle;
end;

function THealthComponent.OnDamageable : RParam;
begin
  Result := IsAlive and not IsInvincible;
end;

function THealthComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
var
  Killer : TEntity;
begin
  if not IsAlive then exit(False);
  Result := True;
  FKillerID := KillerID.AsInteger;
  FKillerCommanderID := KillerCommanderID.AsInteger;
  if Game.EntityManager.TryGetEntityByID(KillerID.AsInteger, Killer) then
      Killer.Eventbus.Trigger(eiYouHaveKilledMeShameOnYou, [FOwner.ID]);
  Eventbus.Write(eiIsAlive, [False]);
  if FInstaDeath then
      Eventbus.Trigger(eiInstaDie, [KillerID, KillerCommanderID]);
  {$IFDEF SERVER}
  GlobalEventbus.Trigger(eiDelayedKillEntity, [self.FOwner.ID]);
  {$ENDIF}
end;

function THealthComponent.OnIsAlive : RParam;
begin
  Result := FIsAlive;
end;

function THealthComponent.OnSetIsAlive(IsAlive : RParam) : boolean;
begin
  Result := True;
  FIsAlive := IsAlive.AsBoolean;
  if not FIsAlive then Eventbus.Write(eiResourceBalance, [ord(reHealth), 0.0]);
end;

function THealthComponent.OnUnitProperies(Previous : RParam) : RParam;
var
  Props : SetUnitProperty;
begin
  Props := Previous.AsSetType<SetUnitProperty>;
  if CurrentHealth < MaxHealth then Props := Props + [upInjured];
  if not IsAlive then Props := Props + [upUnhealable];
  Result := RParam.From<SetUnitProperty>(Props);
end;

procedure THealthComponent.ResolveKiller(ID : integer);
var
  Entity : TEntity;
begin
  FKillerID := ID;
  // if is projectile try to resolve to owner
  if Game.EntityManager.TryGetEntityByID(ID, Entity) then
  begin
    if upProjectile in Entity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then
    begin
      ID := Entity.Eventbus.Read(eiCreator, []).AsInteger;
      // if creator hasn't be set or is already dead, use projectile untouched as killer
      if Game.EntityManager.TryGetEntityByID(ID, Entity) then FKillerID := ID;
    end;
  end;
end;

procedure THealthComponent.UpdateAlive;
begin
  if IsAlive and (CurrentHealth < 1) then Eventbus.Trigger(eiKill, [FKillerID, FKillerCommanderID]);
end;

{$IFDEF SERVER}


function THealthComponent.OnDamage(Amount : RParam; DamageType : RParam; InflictorID, Previous : RParam) : RParam;
var
  Damage, OverhealDamage : single;
  Killer : TEntity;
begin
  if IsInvincible then exit(0.0);
  // save last damage inflictor, to determine killer later
  ResolveKiller(InflictorID.AsInteger);
  if Game.EntityManager.TryGetEntityByID(FKillerID, Killer) then
      FKillerCommanderID := Killer.Eventbus.Read(eiOwnerCommander, []).AsInteger;
  // now apply damage
  Damage := Amount.AsSingle;
  OverhealDamage := Min(Damage, CurrentOverheal);
  Damage := Min(Damage - OverhealDamage, CurrentHealth);
  if OverhealDamage > 0 then
      Eventbus.Trigger(eiResourceTransaction, [ord(reOverheal), -OverhealDamage]);
  if Damage > 0 then
      Eventbus.Trigger(eiResourceTransaction, [ord(reHealth), -Damage]);
  Result := Damage + OverhealDamage + Previous.AsSingle;
  // check if the damage killed us
  UpdateAlive;
  FInstaDeath := not IsAlive or (CurrentHealth >= MaxHealth);
end;

function THealthComponent.OnHeal(var Amount : RParam; HealModifier, InflictorID : RParam) : RParam;
var
  HealedAmount, Overheal : single;
begin
  if not CanBeHealed then exit(0.0);

  HealedAmount := Min(Amount.AsSingle, MaxHealth - CurrentHealth);
  if HealedAmount > 0 then
      Eventbus.Trigger(eiResourceTransaction, [ord(reHealth), HealedAmount]);

  if dtOverheal in HealModifier.AsType<SetDamageType> then
  begin
    Overheal := Min(Amount.AsSingle - HealedAmount, MaxOverheal - CurrentOverheal);
    if Overheal > 0 then
    begin
      Eventbus.Trigger(eiResourceTransaction, [ord(reOverheal), Overheal]);
      Eventbus.Trigger(eiOverheal, [Overheal, HealModifier, InflictorID]);
    end;
  end
  else Overheal := 0;

  Result := HealedAmount + Overheal;

  FInstaDeath := CurrentHealth >= MaxHealth;
end;

function THealthComponent.OnIdle : boolean;
begin
  Result := True;
  UpdateAlive;
end;

function THealthComponent.OnKill(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  ResolveKiller(KillerID.AsInteger);
  FKillerCommanderID := KillerCommanderID.AsInteger;
  Eventbus.Trigger(eiDie, [FKillerID, FKillerCommanderID]);
end;

function THealthComponent.OnWriteResourceCap(ResourceID, Amount : RParam) : boolean;
begin
  Result := True;
  if EnumResource(ResourceID.AsInteger) = reHealth then Eventbus.Write(eiResourceCap, [ord(reOverheal), Amount.AsSingle * OVERHEAL_LIMIT_FACTOR]);
end;
{$ENDIF}

{ TNetworkComponent }

constructor TNetworkComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
end;

destructor TNetworkComponent.Destroy;
begin
  inherited;
end;

function TNetworkComponent.OnNetworkSend(EntityID : RParam; Event : RParam; Group : RParam; ComponentID : RParam; Parameters : RParam; Write : RParam) : boolean;
var
  SendData : TCommandSequence;
  RawData : TArray<byte>;
  ParameterArray : TArray<RParam>;
  RawDataLength : integer;
  RawDataPosition : integer;
  i, DataSize : integer;
begin
  Result := True;
  SendData := TCommandSequence.Create(NET_EVENT);
  SendData.AddData<integer>(EntityID.AsInteger);
  SendData.AddData<EnumEventIdentifier>(Event.AsEnumType<EnumEventIdentifier>);
  SendData.AddData<SetComponentGroup>(Group.AsType<SetComponentGroup>);
  SendData.AddData<integer>(ComponentID.AsInteger);
  SendData.AddData<boolean>(write.AsBoolean);
  ParameterArray := Parameters.AsArray<RParam>;
  // first collect DataSize to set length for rawData
  RawDataLength := 0;
  for i := 0 to Length(ParameterArray) - 1 do
  begin
    assert(not(ParameterArray[i].DataType in [ptTObject, ptPointer]), 'Parametertype "' + Hrtti.EnumerationToString<EnumParameterType>(ParameterArray[i].DataType) + '" for networksend not supported!');
    // save for every parameter datasize (as word)
    RawDataLength := RawDataLength + SizeOf(word);
    // now increase size for data
    RawDataLength := RawDataLength + ParameterArray[i].Size;
  end;
  SetLength(RawData, RawDataLength);
  // now iterate over all data and save into buffer (rawdata)
  RawDataPosition := 0;
  for i := 0 to Length(ParameterArray) - 1 do
  begin
    DataSize := ParameterArray[i].Size;
    // first save datalength
    assert(DataSize <= word.MaxValue);
    PWord(@RawData[RawDataPosition])^ := word(DataSize);
    inc(RawDataPosition, 2);
    // after that save data, but skip zero data to avoid error in range check, because of nil pointer
    if DataSize > 0 then
    begin
      move(ParameterArray[i].GetRawDataPointer^, RawData[RawDataPosition], ParameterArray[i].Size);
      RawDataPosition := RawDataPosition + ParameterArray[i].Size;
    end;
  end;
  assert(RawDataPosition = RawDataLength);
  SendData.AddDataArray<byte>(RawData);
  // finally send
  Send(SendData);
  SendData.Free;
  RawData := nil;
end;

procedure TNetworkComponent.NewData(Data : TDatapacket);
var
  RawData : TArray<byte>;
  EntityID, ComponentID : integer;
  Eventname : EnumEventIdentifier;
  GroupID : SetComponentGroup;
  Write : boolean;
begin
  assert(Data.Command = NET_EVENT);
  EntityID := Data.Read<integer>;
  Eventname := Data.Read<EnumEventIdentifier>;
  GroupID := Data.Read<SetComponentGroup>;
  ComponentID := Data.Read<integer>;
  write := Data.Read<boolean>;
  RawData := Data.ReadArray<byte>;
  // Entity ID, EventName, RawData
  assert(assigned(Game), 'TNetworkComponent.NewData: New data received, but no active game!');
  Game.EntityManager.InvokeEventOnEntity(
    EntityID,
    Eventname,
    GroupID,
    ComponentID,
    RawData,
    write
    );
end;

{ TEntityManagerComponent }

procedure TEntityManagerComponent.BeforeComponentFree;
begin
  inherited;
  KillDeferred;
end;

constructor TEntityManagerComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FEntitiesToFree := TList<TEntity>.Create;
  FEntities := TDictionary<integer, TEntity>.Create;
  FComponentsToKill := TList < RTuple < integer, integer >>.Create;
  FComponentGroupsToKill := TList < RTuple < integer, SetComponentGroup >>.Create;
  FIDCounter := 1; // 1 is reserved for game entity
  FNexusList := TList<TEntity>.Create;
end;

destructor TEntityManagerComponent.Destroy;
var
  Entities : TArray<TPair<integer, TEntity>>;
  i : integer;
begin
  KillDeferred;
  Entities := FEntities.ToArray;
  FEntities.Clear;
  for i := 0 to Length(Entities) - 1 do
      Entities[i].Value.Free;
  // killed entities can defer killed other entites
  KillDeferred;
  FEntities.Free;

  FNexusList.Free;
  FEntitiesToFree.Free;
  FComponentGroupsToKill.Free;
  FComponentsToKill.Free;
  inherited;
end;

function TEntityManagerComponent.EntityCountByUnitProperty(const UnitProperties : SetUnitProperty; CountTeamConstraint : EnumTargetTeamConstraint; TeamID : integer) : integer;
var
  Entity : TEntity;
  key : integer;
begin
  Result := 0;
  for key in FEntities.Keys do
  begin
    Entity := FEntities[key];
    if (Entity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> * UnitProperties = UnitProperties) and
      ((CountTeamConstraint = tcAll) or
      ((CountTeamConstraint = tcEnemies) and (Entity.TeamID <> TeamID)) or
      ((CountTeamConstraint = tcAllies) and (Entity.TeamID = TeamID))) then
        inc(Result);
  end;
end;

procedure TEntityManagerComponent.FreeComponent(EntityID, ComponentID : integer);
begin
  FComponentsToKill.Add(RTuple<integer, integer>.Create(EntityID, ComponentID));
end;

function TEntityManagerComponent.FilterEntities(MustHave, MustNotHave : SetUnitProperty) : TList<TEntity>;
var
  Entity : TEntity;
begin
  Result := TList<TEntity>.Create;
  for Entity in FEntities.Values do
    if (Entity.UnitProperties * MustNotHave = []) and ((MustHave = []) or (Entity.UnitProperties * MustHave <> [])) then
        Result.Add(Entity);
end;

procedure TEntityManagerComponent.FreeComponent(Component : TEntityComponent);
begin
  FreeComponent(Component.Owner.ID, Component.UniqueID);
end;

procedure TEntityManagerComponent.FreeComponentGroup(EntityID : integer; Group : SetComponentGroup);
begin
  FComponentGroupsToKill.Add(RTuple<integer, SetComponentGroup>.Create(EntityID, Group));
end;

procedure TEntityManagerComponent.FreeEntity(Entity : TEntity);
begin
  if not FEntitiesToFree.Contains(Entity) then
      FEntitiesToFree.Add(Entity);
end;

function TEntityManagerComponent.GetEntityByID(ID : integer) : TEntity;
var
  Entity : TEntity;
begin
  if FEntities.TryGetValue(ID, Entity) then Result := Entity
  else Result := nil;
end;

function TEntityManagerComponent.GetEntityByUID(UID : string) : TEntity;
var
  Entity : TEntity;
begin
  Result := nil;
  if UID <> '' then
  begin
    for Entity in FEntities.Values do
      if Entity.UID = UID then
      begin
        Result := Entity;
        break;
      end;
  end;
end;

function TEntityManagerComponent.GetOwningCommander(Entity : TEntity) : TEntity;
begin
  Result := GetEntityByID(Entity.Eventbus.Read(eiOwnerCommander, []).AsInteger);
end;

function TEntityManagerComponent.HasEntityByID(ID : integer) : boolean;
begin
  Result := FEntities.ContainsKey(ID);
end;

procedure TEntityManagerComponent.Idle;
begin
  inherited;
  KillDeferred;
end;

procedure TEntityManagerComponent.KillDeferred;
var
  Entity : TEntity;
  i : integer;
  EntitiesToFree : TArray<TEntity>;
  ComponentsToFree : TArray<RTuple<integer, integer>>;
begin
  for i := 0 to FComponentGroupsToKill.Count - 1 do
  begin
    if TryGetEntityByID(FComponentGroupsToKill[i].a, Entity) then
        Entity.FreeGroups(FComponentGroupsToKill[i].b);
  end;
  FComponentGroupsToKill.Clear;

  // components should not free other component, but for safety
  ComponentsToFree := FComponentsToKill.ToArray;
  FComponentsToKill.Clear;
  for i := 0 to Length(ComponentsToFree) - 1 do
  begin
    if TryGetEntityByID(ComponentsToFree[i].a, Entity) then
    begin
      Entity.Eventbus.Trigger(eiBeforeFree, [], [], ComponentsToFree[i].b);
      Entity.Eventbus.Trigger(eiFree, [], [], ComponentsToFree[i].b);
    end;
  end;

  // entities can free other entities, so preserve list
  EntitiesToFree := FEntitiesToFree.ToArray;
  FEntitiesToFree.Clear;
  for i := 0 to Length(EntitiesToFree) - 1 do
  begin
    FEntities.Remove(EntitiesToFree[i].ID);
    EntitiesToFree[i].Free;
  end;
end;

procedure TEntityManagerComponent.NewEntity(Entity : TEntity);
begin
  assert(Entity.ID <> 0);
  FEntities.Add(Entity.ID, Entity);
end;

function TEntityManagerComponent.NexusByTeamID(TeamID : integer) : TEntity;
begin
  if not TryGetNexusByTeamID(TeamID, Result) then Result := nil;
end;

function TEntityManagerComponent.TryGetNexusByTeamID(TeamID : integer; out Nexus : TEntity) : boolean;
var
  itemNexus : TEntity;
begin
  Result := False;
  for itemNexus in NexusList do
    if itemNexus.TeamID = TeamID then
    begin
      Nexus := itemNexus;
      exit(True);
    end;
end;

function TEntityManagerComponent.TryGetNexusNextEnemy(reference : TEntity; out Nexus : TEntity) : boolean;
begin
  Result := TryGetNexusNextEnemy(reference.Position, reference.TeamID, Nexus);
end;

function TEntityManagerComponent.TryGetNexusNextEnemy(Position : RVector2; MyTeamID : integer; out Nexus : TEntity) : boolean;
var
  itemNexus : TEntity;
  bestDistance, distance : single;
begin
  Result := False;
  bestDistance := -1;
  for itemNexus in NexusList do
    if itemNexus.TeamID <> MyTeamID then
    begin
      distance := itemNexus.Position.distance(Position);
      if (bestDistance < 0) or (bestDistance < distance) then
      begin
        bestDistance := itemNexus.Position.distance(Position);
        Nexus := itemNexus;
        Result := True;
      end;
    end;
end;

function TEntityManagerComponent.NexusList : TList<TEntity>;
var
  List : RParam;
begin
  FreeAndNil(FNexusList);
  List := GlobalEventbus.Read(eiEnumerateNexus, []);
  if not List.IsEmpty then
      FNexusList := List.AsType < TList < TEntity >>
  else
      FNexusList := TList<TEntity>.Create;
  Result := FNexusList;
end;

function TEntityManagerComponent.NexusNext(Position : RVector2) : TEntity;
var
  itemNexus : TEntity;
  bestDistance, distance : single;
begin
  Result := nil;
  bestDistance := -1;
  for itemNexus in NexusList do
  begin
    distance := itemNexus.Position.distance(Position);
    if (bestDistance < 0) or (bestDistance < distance) then
    begin
      bestDistance := itemNexus.Position.distance(Position);
      Result := itemNexus;
    end;
  end;
end;

function TEntityManagerComponent.NexusNextEnemy(Position : RVector2; MyTeamID : integer) : TEntity;
begin
  if not TryGetNexusNextEnemy(Position, MyTeamID, Result) then Result := nil;
end;

function TEntityManagerComponent.GenerateUniqueID : integer;
begin
  inc(FIDCounter);
  Result := FIDCounter;
end;

procedure TEntityManagerComponent.InvokeEventOnEntity(EntityID : integer; Eventname : EnumEventIdentifier; const Group : SetComponentGroup; ComponentID : integer; RawParameters : TArray<byte>; Write : boolean);
var
  // EntityFound : boolean;
  localEntityID : integer;
  Entity : TEntity;
  TargetEventbus : TEventbus;
begin
  TargetEventbus := nil;
  localEntityID := EntityID;
  if localEntityID = 0 then TargetEventbus := GlobalEventbus
  else if localEntityID = 1 then TargetEventbus := Game.GameEntity.Eventbus
    // There needn't to be an entity, because some events like TeamID is been sent before the
    // entity is sent, because the Writeevent has been called to setup the entity
  else if FEntities.TryGetValue(localEntityID, Entity) then
  begin
    TargetEventbus := Entity.Eventbus;
  end;
  if assigned(TargetEventbus) then
      TargetEventbus.InvokeWithRawData(
      Eventname,
      Group,
      ComponentID,
      RawParameters,
      write
      );
end;

function TEntityManagerComponent.OnKillEntity(EntityID : RParam) : boolean;
var
  Entity : TEntity;
begin
  Result := True;
  if FEntities.TryGetValue(EntityID.AsInteger, Entity) then
  begin
    FEntities.Remove(EntityID.AsInteger);
    FEntitiesToFree.Add(Entity);
  end;
end;

function TEntityManagerComponent.OnNewEntity(Entity : RParam) : boolean;
begin
  Result := True;
  NewEntity(Entity.AsType<TEntity>);
end;

function TEntityManagerComponent.OnRemoveComponent(EntityID, ComponentID : RParam) : boolean;
begin
  Result := True;
  FreeComponent(EntityID.AsInteger, ComponentID.AsInteger);
end;

function TEntityManagerComponent.OnRemoveComponentGroup(EntityID, ComponentGroup : RParam) : boolean;
begin
  Result := True;
  FreeComponentGroup(EntityID.AsInteger, ComponentGroup.AsType<SetComponentGroup>);
end;

function TEntityManagerComponent.OnReplaceEntity(oldEntityID, newEntityID, isSameEntity : RParam) : boolean;
var
  Entity : TEntity;
  i : integer;
begin
  Result := True;
  if isSameEntity.AsBoolean then
  begin
    if TryGetEntityByID(oldEntityID.AsInteger, Entity) then
    begin
      Entity.ID := newEntityID.AsInteger;
      FEntities.Remove(oldEntityID.AsInteger);
      FEntities.Add(Entity.ID, Entity);

      for i := 0 to FComponentGroupsToKill.Count - 1 do
        if FComponentGroupsToKill[i].a = oldEntityID.AsInteger then
            FComponentGroupsToKill[i] := FComponentGroupsToKill[i].SetA(newEntityID.AsInteger);
      for i := 0 to FComponentsToKill.Count - 1 do
        if FComponentsToKill[i].a = oldEntityID.AsInteger then
            FComponentsToKill[i] := FComponentsToKill[i].SetA(newEntityID.AsInteger);
    end
    else
        HLog.Write(elWarning, 'TEntityManagerComponent.OnReplaceEntity: Entity to replace not found!');
  end;
  Game.Map.BuildZones.UpdateEntityIDInBuildZones(oldEntityID.AsInteger, newEntityID.AsInteger);
end;

function TEntityManagerComponent.OnSetGridFieldBlocking(GridID, GridCoord, BlockingEntityID : RParam) : boolean;
var
  BuildZone : TBuildZone;
begin
  Result := True;
  BuildZone := Game.Map.BuildZones.GetBuildZone(GridID.AsInteger);
  BuildZone.SetFieldID(GridCoord.AsIntVector2, BlockingEntityID.AsInteger);
end;

function TEntityManagerComponent.TryGetEntityByID(ID : integer; out Entity : TEntity) : boolean;
begin
  Entity := GetEntityByID(ID);
  Result := assigned(Entity);
end;

function TEntityManagerComponent.TryGetEntityByUID(UID : string; out Entity : TEntity) : boolean;
begin
  Entity := GetEntityByUID(UID);
  Result := assigned(Entity);
end;

function TEntityManagerComponent.TryGetOwningCommander(Entity : TEntity; out Commander : TEntity) : boolean;
begin
  Commander := GetOwningCommander(Entity);
  Result := assigned(Commander);
end;

function TEntityManagerComponent.GetDeployedEntityCount : integer;
begin
  Result := FEntities.Count;
end;

function TEntityManagerComponent.GetDeployedEntityList : TList<TEntity>;
begin
  Result := TList<TEntity>.Create;
  Result.AddRange(FEntities.Values);
end;

{ TCollisionManagerComponent }

constructor TCollisionManagerComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FQuadTree := TEntityLooseQuardtree.Create(Game.Map.MapBoundaries, 16);
end;

destructor TCollisionManagerComponent.Destroy;
begin
  FQuadTree.Free;
  inherited;
end;

function TCollisionManagerComponent.OnClosestEntityInRange(Pos, Range, SourceTeamID, TargetTeamConstraint, Filter : RParam) : RParam;
var
  MyPos, EntityPos, bestentitypos : RVector2;
  nearby : TList<TEntityLooseQuadtreeData>;
  element : TEntityLooseQuadtreeData;
  e : TEntity;
  dist : single;
  FilterFunc : ProcEntityFilterFunction;
begin
  Result := nil;
  nearby := FQuadTree.GetIntersections(RCircle.Create(Pos.AsVector2, Range.AsSingle), SourceTeamID.AsInteger, TargetTeamConstraint.AsType<EnumTargetTeamConstraint>);

  MyPos := Pos.AsVector2;
  bestentitypos := RVector2.Empty;
  Result := TObject(nil);
  if not Filter.IsEmpty then FilterFunc := Filter.AsProc<ProcEntityFilterFunction>()
  else FilterFunc := nil;

  for element in nearby do
  begin
    e := element.Data;
    EntityPos := element.Boundaries.Center;
    dist := EntityPos.distance(MyPos);

    if ((not assigned(FilterFunc)) or FilterFunc(e)) and (bestentitypos.IsEmpty or (dist < bestentitypos.distance(MyPos))) then
    begin
      bestentitypos := EntityPos;
      Result := e;
    end;
  end;
  nearby.Free;
end;

function TCollisionManagerComponent.OnEntitiesInRangeOf(Pos : RParam; Range : RParam; SourceTeamID, TargetTeamConstraint : RParam; Filter : RParam) : RParam;
var
  i : integer;
  e : TEntity;
  nearby : TList<TEntityLooseQuadtreeData>;
  FilterFunc : ProcEntityFilterFunction;
  EntitiesFound : TList<TEntity>;
begin
  nearby := FQuadTree.GetIntersections(RCircle.Create(Pos.AsVector2, Range.AsSingle),
    SourceTeamID.AsInteger, TargetTeamConstraint.AsType<EnumTargetTeamConstraint>);
  EntitiesFound := TList<TEntity>.Create();

  if not Filter.IsEmpty then FilterFunc := Filter.AsProc<ProcEntityFilterFunction>()
  else FilterFunc := nil;

  for i := 0 to nearby.Count - 1 do
  begin
    e := nearby[i].Data;
    if (not assigned(FilterFunc)) or (FilterFunc(e)) then EntitiesFound.Add(e);
  end;
  if EntitiesFound.Count = 0 then FreeAndNil(EntitiesFound);

  nearby.Free;
  Result := EntitiesFound;
end;

procedure TCollisionManagerComponent.RegisterCollidable(Collidable : TLooseQuadTreeNodeData<TEntity>);
begin
  if assigned(Collidable) then
      FQuadTree.AddItem(Collidable);
end;

procedure TCollisionManagerComponent.RemoveCollidable(Collidable : TLooseQuadTreeNodeData<TEntity>);
begin
  if assigned(Collidable) then
      FQuadTree.RemoveItem(Collidable);
end;

{ TCollisionComponent }

constructor TCollisionComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FRadius := Owner.CollisionRadius;
  if HLog.AssertAndLog(FRadius > 0, 'TCollisionComponent.Create: Missing collision radius!') then
      FRadius := 0.5;
  FElement := TEntityLooseQuadtreeData.Create(RCircle.Create(FOwner.Position, FRadius), FOwner);
  if assigned(Game) then
      Game.CollisionManager.RegisterCollidable(FElement);
  FRegistered := True;
end;

destructor TCollisionComponent.Destroy;
begin
  if FRegistered and assigned(Game) then
      Game.CollisionManager.RemoveCollidable(FElement);
  FElement.Free;
  inherited;
end;

function TCollisionComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  GlobalEventbus.Trigger(eiRemoveComponent, [FOwner.ID, FUniqueId]);
end;

function TCollisionComponent.OnExiled(IsExiled : RParam) : boolean;
begin
  Result := True;
  if not IsExiled.AsBoolean then
  begin
    if not FRegistered and assigned(Game) then
        Game.CollisionManager.RegisterCollidable(FElement);
    FRegistered := True;
  end
  else
  begin
    if FRegistered and assigned(Game) then
        Game.CollisionManager.RemoveCollidable(FElement);
    FRegistered := False;
  end;
end;

function TCollisionComponent.OnWritePosition(Position : RParam) : boolean;
begin
  Result := True;
  FElement.Boundaries.Center := Position.AsVector2;
  if FRegistered then FElement.UpdateInTree;
end;

function TCollisionComponent.OnWriteTeamID(TeamID : RParam) : boolean;
begin
  Result := True;
  FElement.TeamID := TeamID.AsInteger;
  // no need for update because set TeamID will automatically make an update
  // FElement.UpdateInTree;
end;

{ TResourceManagerComponent }

destructor TResourceManagerComponent.Destroy;
begin
  FreeAndNil(FInitialValues);
  inherited;
end;

function TResourceManagerComponent.OnAfterCreate : boolean;
begin
  Result := True;
  FInitialValues := Owner.Blackboard.GetIndexMap(eiResourceBalance, []);
end;

function TResourceManagerComponent.OnCanTransact(ResourceID, Amount, Previous : RParam) : RParam;
var
  sBalance, sAmount : single;
  iBalance, iAmount : integer;
begin
  if EnumResource(ResourceID.AsInteger) in RES_INT_RESOURCES then
  begin
    iBalance := FOwner.Blackboard.GetIndexedValue(eiResourceBalance, CurrentEvent.CalledToGroup, ResourceID.AsInteger).AsInteger;
    iAmount := Amount.AsInteger;
    Result := (iAmount >= 0) or (iBalance + iAmount >= 0);
  end
  else
  begin
    sBalance := FOwner.Blackboard.GetIndexedValue(eiResourceBalance, CurrentEvent.CalledToGroup, ResourceID.AsInteger).AsSingle;
    sAmount := Amount.AsSingle;
    Result := (sAmount >= 0) or (sBalance + sAmount >= 0);
  end;
end;

function TResourceManagerComponent.OnCanTransactNegative(ResourceID, Amount, Previous : RParam) : RParam;
begin
  if EnumResource(ResourceID.AsInteger) in RES_INT_RESOURCES then
      Result := OnCanTransact(ResourceID, -Amount.AsInteger, Previous)
  else
      Result := OnCanTransact(ResourceID, -Amount.AsSingle, Previous)
end;

function TResourceManagerComponent.OnGetResource(ResourceID, Previous : RParam) : RParam;
begin
  Result := FOwner.Blackboard.GetIndexedValue(eiResourceBalance, CurrentEvent.CalledToGroup, ResourceID.AsInteger);
end;

function TResourceManagerComponent.OnGetResourceCap(ResourceID, Previous : RParam) : RParam;
begin
  Result := FOwner.Blackboard.GetIndexedValue(eiResourceCap, CurrentEvent.CalledToGroup, ResourceID.AsInteger);
end;

function TResourceManagerComponent.OnGetResourceCost(Previous : RParam) : RParam;
var
  Map : TDictionary<integer, RParam>;
  Cost : AResourceCost;
  key : integer;
begin
  Map := FOwner.Blackboard.GetIndexMap(eiResourceCost, CurrentEvent.CalledToGroup);
  if Map.Count = 0 then Result := RPARAM_EMPTY
  else
  begin
    Cost := nil;
    for key in Map.Keys do
    begin
      SetLength(Cost, Length(Cost) + 1);
      Cost[high(Cost)].ResourceType := EnumResource(key);
      Cost[high(Cost)].Amount := Map[key];
    end;
    Result := Cost.ToRParam;
  end;
  Map.Free;
end;

function TResourceManagerComponent.OnResetResource(ResourceID : RParam) : boolean;
var
  InitialValue : RParam;
begin
  Result := True;
  if assigned(FInitialValues) and FInitialValues.TryGetValue(ResourceID.AsInteger, InitialValue) then
      Eventbus.Write(eiResourceBalance, [ResourceID, InitialValue]);
end;

function TResourceManagerComponent.OnResourceCapTransaction(ResourceID, Amount, Empty : RParam) : boolean;
var
  iCurrentCap : integer;
  sCurrentCap : single;
begin
  Result := True;
  if EnumResource(ResourceID.AsInteger) in RES_INT_RESOURCES then
  begin
    iCurrentCap := FOwner.Blackboard.GetIndexedValue(eiResourceCap, CurrentEvent.CalledToGroup, ResourceID.AsInteger).AsInteger;
    if iCurrentCap >= 0 then
    begin
      Eventbus.Write(eiResourceCap, [ResourceID, iCurrentCap + Amount.AsInteger], CurrentEvent.CalledToGroup);
      // fill new space with resource if amount is increase an should fill
      if (Amount.AsInteger > 0) and not Empty.AsBoolean then
          Eventbus.Trigger(eiResourceTransaction, [ResourceID, Amount.AsInteger], CurrentEvent.CalledToGroup);
    end
  end
  else
  begin
    sCurrentCap := FOwner.Blackboard.GetIndexedValue(eiResourceCap, CurrentEvent.CalledToGroup, ResourceID.AsInteger).AsSingle;
    if sCurrentCap >= 0 then
    begin
      Eventbus.Write(eiResourceCap, [ResourceID, sCurrentCap + Amount.AsSingle], CurrentEvent.CalledToGroup);
      // fill new space with resource if amount is increase an should fill
      if (Amount.AsSingle > 0) and not Empty.AsBoolean then
          Eventbus.Trigger(eiResourceTransaction, [ResourceID, Amount.AsSingle], CurrentEvent.CalledToGroup);
    end;
  end;
end;

function TResourceManagerComponent.OnSetResource(ResourceID, Amount : RParam) : boolean;
begin
  Result := True;
  FOwner.Blackboard.SetIndexedValue(eiResourceBalance, CurrentEvent.CalledToGroup, ResourceID.AsInteger, Amount);
end;

function TResourceManagerComponent.OnSetResourceCap(ResourceID, Amount : RParam) : boolean;
begin
  Result := True;
  FOwner.Blackboard.SetIndexedValue(eiResourceCap, CurrentEvent.CalledToGroup, ResourceID.AsInteger, Amount);
  // refresh resource if cap has been reduced, this will cap it again, else it will do nothing
  OnTransact(ResourceID, RPARAMEMPTY);
end;

function TResourceManagerComponent.OnSetResourceCost(ResourceID, Amount : RParam) : boolean;
begin
  Result := True;
  FOwner.Blackboard.SetIndexedValue(eiResourceCost, CurrentEvent.CalledToGroup, ResourceID.AsInteger, Amount);
end;

function TResourceManagerComponent.OnTransact(ResourceID, Amount : RParam) : boolean;
var
  Cap : RParam;
  sBalance : single;
  iBalance : integer;
begin
  Result := True;
  if EnumResource(ResourceID.AsInteger) in RES_INT_RESOURCES then
  begin
    iBalance := FOwner.Blackboard.GetIndexedValue(eiResourceBalance, CurrentEvent.CalledToGroup, ResourceID.AsInteger).AsInteger;
    Cap := FOwner.Blackboard.GetIndexedValue(eiResourceCap, CurrentEvent.CalledToGroup, ResourceID.AsInteger);
    iBalance := iBalance + Amount.AsInteger;
    iBalance := Max(0, iBalance);
    if not Cap.IsEmpty and not(EnumResource(ResourceID.AsInteger) in RES_IGNORE_CAP) and (Amount.AsInteger >= 0) then iBalance := Min(iBalance, Cap.AsInteger);
    Eventbus.Write(eiResourceBalance, [ResourceID, iBalance], CurrentEvent.CalledToGroup);
  end
  else
  begin
    sBalance := FOwner.Blackboard.GetIndexedValue(eiResourceBalance, CurrentEvent.CalledToGroup, ResourceID.AsInteger).AsSingle;
    Cap := FOwner.Blackboard.GetIndexedValue(eiResourceCap, CurrentEvent.CalledToGroup, ResourceID.AsInteger);
    sBalance := sBalance + Amount.AsSingle;
    sBalance := Max(0, sBalance);
    if not Cap.IsEmpty and not(EnumResource(ResourceID.AsInteger) in RES_IGNORE_CAP) and (Amount.AsSingle >= 0) then sBalance := Min(sBalance, Cap.AsSingle);
    Eventbus.Write(eiResourceBalance, [ResourceID, sBalance], CurrentEvent.CalledToGroup);
  end;
end;

function TResourceManagerComponent.OnTransactNegative(ResourceID, Amount : RParam) : boolean;
begin
  if EnumResource(ResourceID.AsInteger) in RES_INT_RESOURCES then
      Result := OnTransact(ResourceID, -Amount.AsInteger)
  else
      Result := OnTransact(ResourceID, -Amount.AsSingle)
end;

{ TPrimaryTargetComponent }

function TPrimaryTargetComponent.OnGetNexusPosition(Previous : RParam) : RParam;
var
  NexusList : TList<TEntity>;
begin
  if Previous.IsEmpty then NexusList := TList<TEntity>.Create
  else NexusList := Previous.AsType<TList<TEntity>>;

  NexusList.Add(Owner);
  Result := NexusList;
end;

{ TGameTickComponent }

constructor TGameTickComponent.Create(Owner : TEntity);
begin
  inherited;
  FTickTimer := TTimer.CreatePaused(GAME_WARMING_DURATION);
end;

destructor TGameTickComponent.Destroy;
begin
  FTickTimer.Free;
  inherited;
end;

function TGameTickComponent.OnGameCommencing : boolean;
begin
  Result := True;
  if FTickTimer.Paused then
      FTickTimer.SetIntervalAndStart(GAME_WARMING_DURATION);
end;

function TGameTickComponent.OnGetTimeToFirstTick : RParam;
begin
  Result := 0;
  if FTickCounter <= 0 then
      Result := integer(round(FTickTimer.TimeToExpired));
end;

function TGameTickComponent.OnGetGameTickCounter : RParam;
begin
  Result := FTickCounter;
end;

{$IFDEF SERVER}


function TGameTickComponent.OnIdle : boolean;
begin
  Result := True;
  if FTickTimer.Expired then
      GlobalEventbus.Trigger(eiGameTick, []);
end;

{$ENDIF}


function TGameTickComponent.OnGameTick : boolean;
begin
  Result := True;
  {$IFDEF SERVER}
  if FTickCounter <= 0 then
      GlobalEventbus.Trigger(eiGameStart, []);
  {$ENDIF}
  FTickTimer.SetIntervalAndStart(GAME_TICK_DURATION);
  inc(FTickCounter);
end;

{ TArmorComponent }

function TArmorComponent.OnDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
var
  AttackType : SetDamageType;
  MyArmor : EnumArmorType;
  Factor, Offset : single;
begin
  Result := Previous;
  AttackType := DamageType.AsType<SetDamageType>;
  if not(dtIgnoreArmor in AttackType) and (Amount.AsSingle > 1.0) then
  begin
    MyArmor := Eventbus.Read(eiArmorType, []).AsEnumType<EnumArmorType>;
    Factor := 1.0;
    Offset := 0.0;
    case MyArmor of
      // No Damage-Reduction
      atUnarmored : Factor := 1.0;
      // 15% Damage-Reduction
      atLight : Factor := 0.85;
      // 20% Damage-Reduction, 30% Damage-Reduction against Ranged
      atMedium : if (dtRanged in AttackType) then Factor := 0.7
        else Factor := 0.8;
      // 30% Damage-Reduction + 5 Flat-Damage-Reduction
      atHeavy :
        begin
          Factor := 0.7;
          Offset := 5;
        end;
      // 400% Damage if Siege, otherwise no changes
      atFortified : if (dtSiege in AttackType) then Factor := 4.0;
    else
      raise ENotImplemented.Create('TArmorComponent.OnDamage: Missing armor type!');
    end;
    // apply armor type, every shot deals 1 Damage at least
    Amount := Max(1.0, Factor * Amount.AsSingle - Offset);
  end;
end;

{ TNexusEarlyVulnerabilityComponent }

function TNexusEarlyVulnerabilityComponent.OnWelaDamage(Previous : RParam) : RParam;
var
  Damage : single;
  currentTick, endTick : integer;
begin
  Damage := Previous.AsSingle;
  currentTick := GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
  endTick := Eventbus.Read(eiCooldown, [], ComponentGroup).AsInteger;
  assert(endTick > 0);
  if endTick < 0 then endTick := 1;
  Damage := HMath.LinLerpF(Damage, 0.999, HMath.Saturate(currentTick / endTick));
  // quantize to integer, so damage increase is decreased in steps not continous 6x, 5x, 4x, 3x ...
  Damage := ceil(Damage);
  Result := Damage;
end;

{ TCommanderAbilityComponent }

constructor TCommanderAbilityComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Card : RCommanderCard);
begin
  inherited CreateGrouped(Owner, Group);
  FCardUID := Card.CardUID;
  assert((Card.League >= 1) and (Card.League <= MAX_LEAGUE), 'TCommanderAbilityComponent.CreateGrouped: Invalid card league ' + Card.League.ToString + ' passed to server!');
  assert((Card.Level >= 1) and (Card.Level <= MAX_LEVEL), 'TCommanderAbilityComponent.CreateGrouped: Invalid card level ' + Card.Level.ToString + ' passed to server!');
  FCardLeague := Card.League;
  FCardLevel := Card.Level;
  Init; // Server only
end;

constructor TCommanderAbilityComponent.CreateGroupedSlot(Owner : TEntity; Group : TArray<byte>; Card : RCommanderCard; Slot : integer);
begin
  FSlot := Slot;
  CreateGrouped(Owner, Group, Card);
end;

procedure TCommanderAbilityComponent.Init;
var
  CardInfo : TCardInfo;
begin
  CardInfo := CardInfoManager.ResolveCardUID(FCardUID, FCardLeague, FCardLevel);
  case CardInfo.CardType of
    ctDrop :
      begin
        Owner.ApplyScript('Commander\CommanderMethods.dws', 'AddDrop', [
          TValue.From<TEntity>(Owner),
          TValue.From<TCardInfo>(CardInfo),
          TValue.From<integer>(FSlot)])
      end;
    ctBuilding :
      begin
        Owner.ApplyScript('Commander\CommanderMethods.dws', 'AddBuilding', [
          TValue.From<TEntity>(Owner),
          TValue.From<TCardInfo>(CardInfo),
          TValue.From<integer>(FSlot)]);
      end;
    ctSpell :
      begin
        Owner.ApplyScript(CardInfo.Filename, 'AddSpell', [
          TValue.From<TEntity>(Owner),
          TValue.From<TCardInfo>(CardInfo),
          TValue.From<integer>(FSlot)]);
      end;
    ctSpawner :
      begin
        Owner.ApplyScript('Commander\CommanderMethods.dws', 'AddSpawner', [
          TValue.From<TEntity>(Owner),
          TValue.From<TCardInfo>(CardInfo),
          TValue.From<integer>(FSlot)]);
      end;
  end;
end;

function TCommanderAbilityComponent.OnAfterCreate : boolean;
begin
  Result := True;
  Init; // Client only
  Free;
end;

{ TPathfindingComponent }

constructor TPathfindingComponent.Create(Owner : TEntity);
begin
  inherited;
end;

destructor TPathfindingComponent.Destroy;
begin
  {$IFNDEF MAPEDITOR}
  if assigned(Map) and assigned(Map.Pathfinding) then
  begin
    if assigned(FCurrentTile) then
        FCurrentTile.UnblockTile(Owner);
    Map.Pathfinding.CancelLastComputedPath(Owner);
  end;
  {$ENDIF}
  inherited;
end;

function TPathfindingComponent.OnAfterCreate : boolean;
begin
  Result := True;
  {$IFDEF MAPEDITOR}
  Free;
  exit;
  {$ELSE}
  FCurrentTile := Map.Pathfinding.GetTileByPosition(Owner.Position);
  FCurrentTile.BlockTile(Owner);
  {$ENDIF}
end;

function TPathfindingComponent.OnPathfindingTile : RParam;
begin
  Result := FCurrentTile;
end;

function TPathfindingComponent.OnStand : boolean;
begin
  Result := True;
  {$IFNDEF MAPEDITOR}
  Map.Pathfinding.CancelLastComputedPath(Owner);
  if assigned(FCurrentTile) then
      FCurrentTile.BlockTile(Owner);
  {$ENDIF}
end;

function TPathfindingComponent.OnWritePosition(Position : RParam) : boolean;
{$IFNDEF MAPEDITOR}
var
  newTile : TPathfindingTile;
  {$ENDIF}
begin
  Result := True;
  {$IFNDEF MAPEDITOR}
  newTile := Map.Pathfinding.GetTileByPosition(Position.AsVector2);
  if assigned(newTile) and (newTile <> FCurrentTile) then
  begin
    if assigned(FCurrentTile) then
        FCurrentTile.UnblockTile(Owner);
    FCurrentTile := newTile;
  end;
  {$ENDIF}
end;

{ TDynamicZoneEmitterComponent }

function TDynamicZoneEmitterComponent.Exclude : TDynamicZoneEmitterComponent;
begin
  Result := self;
  FNegate := True;
end;

function TDynamicZoneEmitterComponent.OnInDynamicZone(Position, TeamID, Zone, Previous : RParam) : RParam;
var
  Res : EnumDynamicZoneResult;
begin
  Result := Previous;
  // check if zone type matches this emitters zone type
  if FDynamicZone * Zone.AsType<SetDynamicZone> <> [] then
  begin
    // if result is false, nothing can turn this to true
    if Previous.IsEmpty or Previous.AsBoolean then
    begin
      Res := IsInDynamicZone(Position.AsVector2, TeamID.AsInteger);
      if FNegate and (Res = drTrue) then Res := drFalse;
      case Res of
        drNone : Result := Previous;
        drTrue : Result := True;
        drFalse : Result := False;
      end;
    end
  end;
end;

function TDynamicZoneEmitterComponent.SetZone(Zone : TArray<byte>) : TDynamicZoneEmitterComponent;
begin
  Result := self;
  FDynamicZone := ByteArrayToSetDynamicZone(Zone);
end;

{ TDynamicZoneRadialEmitterComponent }

function TDynamicZoneRadialEmitterComponent.IsInDynamicZone(Position : RVector2; TeamID : integer) : EnumDynamicZoneResult;
begin
  if ((TeamID <= -1) or (TeamID = Owner.TeamID)) and
    (Owner.Position.distance(Position) <= Eventbus.Read(eiWelaRange, [], ComponentGroup).AsSingle) then
      Result := drTrue
  else Result := drNone;
end;

{ TDynamicZoneAxisEmitterComponent }

constructor TDynamicZoneAxisEmitterComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FNormal := RVector2.Create(0, 1);
  FPosition := RVector2.Create(0, -3);
end;

function TDynamicZoneAxisEmitterComponent.IsInDynamicZone(Position : RVector2; TeamID : integer) : EnumDynamicZoneResult;
begin
  if FPosition.DirectionTo(Position).Dot(FNormal) >= 0 then Result := drTrue
  else Result := drNone;
end;

function TDynamicZoneAxisEmitterComponent.SetNormal(X, Y : single) : TDynamicZoneAxisEmitterComponent;
begin
  Result := self;
  FNormal := RVector2.Create(X, Y).Normalize;
end;

function TDynamicZoneAxisEmitterComponent.SetPosition(X, Y : single) : TDynamicZoneAxisEmitterComponent;
begin
  Result := self;
  FPosition := RVector2.Create(X, Y).Normalize;
end;

{ TUnitPropertyComponent }

constructor TUnitPropertyComponent.CreateGrouped(Owner : TEntity; ComponentGroup, AttachedProperties : TArray<byte>);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FUnitProperties := ByteArrayToSetUnitProperies(AttachedProperties);
  Owner.Eventbus.Trigger(eiUnitPropertyChanged, [RParam.From<SetUnitProperty>(FUnitProperties), False]);
end;

function TUnitPropertyComponent.GivePropertyOwner : TUnitPropertyComponent;
begin
  Result := self;
  FGiveOwner := True;
end;

function TUnitPropertyComponent.OnAfterCreate : boolean;
var
  Entity : TEntity;
begin
  Result := True;
  if FGiveOwner and assigned(Game) and Game.EntityManager.TryGetOwningCommander(Owner, Entity) then
  begin
    Entity.Eventbus.SubscribeRemote(eiUnitProperties, etRead, epMiddle, self, 'GetCommanderUnitProperties', 1);
  end;
end;

destructor TUnitPropertyComponent.Destroy;
begin
  Owner.Eventbus.Trigger(eiUnitPropertyChanged, [RParam.From<SetUnitProperty>(FUnitProperties), True]);
  inherited;
end;

function TUnitPropertyComponent.GetCommanderUnitProperties(Previous : RParam) : RParam;
var
  Props : SetUnitProperty;
begin
  if FGiveOwner then
  begin
    Props := Previous.AsSetType<SetUnitProperty>;
    if FRemove then
        Props := Props - FUnitProperties
    else
        Props := Props + FUnitProperties;
    Result := RParam.From<SetUnitProperty>(Props);
  end;
end;

function TUnitPropertyComponent.OnUnitProperties(Previous : RParam) : RParam;
var
  Props : SetUnitProperty;
begin
  if not FGiveOwner then
  begin
    Props := Previous.AsSetType<SetUnitProperty>;
    if FRemove then
        Props := Props - FUnitProperties
    else
        Props := Props + FUnitProperties;
    Result := RParam.From<SetUnitProperty>(Props);
  end
  else Result := Previous;
end;

function TUnitPropertyComponent.Remove : TUnitPropertyComponent;
begin
  Result := self;
  FRemove := True;
end;

{ TGameDirectorComponent }

function TGameDirectorComponent.AddEvent(GameTick : integer; Eventname : string) : TGameDirectorComponent;
var
  Action : RGameDirectorAction;
begin
  Result := self;
  Action.GameTick := GameTick;
  Action.Eventname := Eventname.ToLowerInvariant;
  FActions.Add(Action);
end;

function TGameDirectorComponent.AddEventIf(Condition : boolean; GameTick : integer; Eventname : string) : TGameDirectorComponent;
begin
  Result := self;
  if Condition then
      AddEvent(GameTick, Eventname);
end;

function TGameDirectorComponent.ClearEvents : TGameDirectorComponent;
begin
  Result := self;
  FActions.Clear;
end;

constructor TGameDirectorComponent.Create(Owner : TEntity);
begin
  inherited;
  FActions := TList<RGameDirectorAction>.Create;
end;

destructor TGameDirectorComponent.Destroy;
begin
  FActions.Free;
  inherited;
end;

function TGameDirectorComponent.OnGameEventTimeTo(Eventname, Previous : RParam) : RParam;
var
  Name : string;
  i, currentTick : integer;
begin
  name := Eventname.AsString;
  currentTick := GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
  for i := 0 to FActions.Count - 1 do
    if (FActions[i].Eventname = name) and (FActions[i].GameTick >= currentTick) then
    begin
      Result := FActions[i].GameTick - currentTick;
      exit;
    end;
  Result := -1;
end;

{$IFDEF SERVER}


function TGameDirectorComponent.OnGameTick : boolean;
var
  Action : RGameDirectorAction;
  Tick, i : integer;
begin
  Result := True;
  Tick := GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
  for i := FActions.Count - 1 downto 0 do
    if (Tick >= FActions[i].GameTick) then
    begin
      Action := FActions[i];
      FActions.Delete(i);
      GlobalEventbus.Trigger(eiGameEvent, [Action.Eventname]);
    end;
end;
{$ENDIF}

{ RCommanderCard }

constructor RCommanderCard.Create(const CardUID : string; League, Level : integer);
begin
  self.CardUID := CardUID;
  self.League := League;
  self.Level := Level;
end;

constructor RCommanderCard.CreateMaxed(const CardUID : string);
begin
  Create(CardUID, DEFAULT_LEAGUE, DEFAULT_LEVEL);
end;

{ TGameEventEnumeratorComponent }

function TGameEventEnumeratorComponent.Event(const EventID : string) : TGameEventEnumeratorComponent;
begin
  Result := self;
  HArray.Push<string>(FGameEvents, EventID);
end;

function TGameEventEnumeratorComponent.OnGameEvent(Event, Previous : RParam) : RParam;
var
  i : integer;
  Eventstring : string;
  Enumeration : TList<TEntity>;
begin
  Result := Previous;
  Eventstring := Event.AsString;
  for i := 0 to Length(FGameEvents) - 1 do
    if FGameEvents[i] = Eventstring then
    begin
      Enumeration := Previous.AsType<TList<TEntity>>;
      if not assigned(Enumeration) then Enumeration := TList<TEntity>.Create;
      Enumeration.Add(Owner);
      Result := Enumeration;
      break;
    end;
end;

{ TSandboxComponent }

function TSandboxComponent.OnGameCommencing : boolean;
begin
  Result := True;
  Game.GameDirector.ClearEvents;
end;

{ TCommanderIncomeComponent }

function TCommanderIncomeComponent.AdjustIncome(const Income : RIncome) : RIncome;
begin
  Result := Income;
end;

function TCommanderIncomeComponent.OnReadIncome(CommanderID, Previous : RParam) : RParam;
begin
  if Owner.CommanderID = CommanderID.AsInteger then
      Result := AdjustIncome(Previous.AsType<RIncome>).ToRParam
  else
      Result := Previous;
end;

{ TCommanderIncomeDefaultComponent }

function TCommanderIncomeDefaultComponent.AdjustIncome(const Income : RIncome) : RIncome;
var
  Cost : AResourceCost;
  GoldIncomeRaw : RParam;
  CurrentGoldIncomeUpgrades : integer;
  GoldIncome, GoldIncomePerIncomeUpgrade : single;
begin
  Result := inherited;
  // default income
  Cost := Eventbus.Read(eiResourceCost, [], ComponentGroup).AsAResourceCost;
  if not(assigned(Cost) and Cost.TryGetValue(reGold, GoldIncomeRaw)) then
      assert(False, 'TCommanderIncomeComponent.OnReadIncome: eiResourceCost does not exist or contain RES_GOLD!');
  GoldIncome := GoldIncomeRaw.AsSingle;
  // income per IncomeUpgrade
  GoldIncomePerIncomeUpgrade := Eventbus.Read(eiWelaDamage, [], ComponentGroup).AsSingle;
  CurrentGoldIncomeUpgrades := Owner.Balance(reIncomeUpgrade).AsInteger;
  GoldIncome := GoldIncome + GoldIncomePerIncomeUpgrade * CurrentGoldIncomeUpgrades;

  Result.Gold := Result.Gold + GoldIncome;
end;

constructor TCommanderIncomeDefaultComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  self.ChangeEventPriority(eiIncome, etRead, epFirst, esGlobal);
end;

{ TCommanderIncomeOverflowComponent }

function TCommanderIncomeOverflowComponent.AdjustIncome(const Income : RIncome) : RIncome;
var
  GoldBalance, GoldCap, GoldIncome : single;
begin
  Result := inherited;
  GoldCap := Owner.Cap(reGold).AsSingle;
  GoldBalance := Min(GoldCap, Owner.Balance(reGold).AsSingle);
  GoldIncome := Result.Gold;
  if (GoldBalance + GoldIncome > GoldCap) then
  begin
    Result.Gold := GoldCap - GoldBalance;
    Result.Wood := GoldIncome - Result.Gold;
  end;
end;

constructor TCommanderIncomeOverflowComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  self.ChangeEventPriority(eiIncome, etRead, epLast, esGlobal);
end;

{ TCommanderIncomeLoanComponent }

function TCommanderIncomeLoanComponent.AdjustIncome(const Income : RIncome) : RIncome;
begin
  Result := inherited;
  if not FTimer.Expired or (FFactor > 0) then
  begin
    Result.Gold := Result.Gold * FFactor;

    if FTimer.Expired then
    begin
      FTimer.SetIntervalAndStart(round(FTimer.Interval * FFactor / 2));
      FFactor := 0;
    end;
  end;
end;

destructor TCommanderIncomeLoanComponent.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TCommanderIncomeLoanComponent.Duration(Duration : integer) : TCommanderIncomeLoanComponent;
begin
  Result := self;
  FTimer := TTimer.CreateAndStart(Duration);
end;

function TCommanderIncomeLoanComponent.Factor(Factor : single) : TCommanderIncomeLoanComponent;
begin
  Result := self;
  FFactor := Factor;
end;

initialization

TCommanderAbilityComponent.ClassName;

ScriptManager.ExposeType(TypeInfo(EnumComparator));

ScriptManager.ExposeClass(TDynamicZoneEmitterComponent);
ScriptManager.ExposeClass(TDynamicZoneRadialEmitterComponent);
ScriptManager.ExposeClass(TDynamicZoneAxisEmitterComponent);

ScriptManager.ExposeClass(TNexusEarlyVulnerabilityComponent);

ScriptManager.ExposeClass(TGameEventEnumeratorComponent);

ScriptManager.ExposeClass(TCommanderIncomeComponent);
ScriptManager.ExposeClass(TCommanderIncomeDefaultComponent);
ScriptManager.ExposeClass(TCommanderIncomeLoanComponent);
ScriptManager.ExposeClass(TCommanderIncomeOverflowComponent);

ScriptManager.ExposeClass(TArmorComponent);
ScriptManager.ExposeClass(THealthComponent);
ScriptManager.ExposeClass(TPositionComponent);
ScriptManager.ExposeClass(TMovementComponent);
ScriptManager.ExposeClass(TResourceManagerComponent);
ScriptManager.ExposeClass(TCollisionComponent);
ScriptManager.ExposeClass(TPrimaryTargetComponent);
ScriptManager.ExposeClass(TPathfindingComponent);

ScriptManager.ExposeClass(TUnitPropertyComponent);

ScriptManager.ExposeClass(TGameDirectorComponent);
ScriptManager.ExposeClass(TSandboxComponent);

end.
