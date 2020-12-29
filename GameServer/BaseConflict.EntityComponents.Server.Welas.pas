unit BaseConflict.EntityComponents.Server.Welas;

interface

uses
  SysUtils,
  System.Rtti,
  Generics.Defaults,
  Generics.Collections,
  Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Engine.Script,
  Engine.Math.Collision2D,
  Engine.Log,
  BaseConflict.Types.Target,
  BaseConflict.Types.Server,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Globals,
  BaseConflict.Map,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Shared.Wela,
  BaseConflict.EntityComponents.Server,
  BaseConflict.Types.Shared;

type

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Targetingmodules - looking for valid targets, they do
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}
  /// <summary> Mastercomponent of all targetingcomponents of welas. Look for and validates targets.
  /// Other modules can update their target list (eiWelaUpdateTargets) and validate a single target (eiWelaValidateTarget)
  /// with a TWelaTargetingComponent.</summary>
  TWelaTargetingComponent = class abstract(TEntityComponent)
    protected
      FPickRandom, FRepetition : boolean;
      FValidateGroup : SetComponentGroup;
      FTargetTeamConstraint, FTargetPriorization : EnumTargetTeamConstraint;
      FMaxNewTargetCount : integer;
      procedure UpdateTargets(CurrentList : TList<RTarget>); virtual; abstract;
      function ValidateTarget(Target : RTarget) : boolean; virtual; abstract;
      function IsTargetPossible(Target : TEntity; TargetGroup : SetComponentGroup) : boolean;
      function FetchEfficiency(Target : TEntity; TargetGroup : SetComponentGroup) : single;
      /// <summary> Picks random targets from PossibleTargetList and add them to the current targets.
      /// Frees the PossibleTargetList. </summary>
      procedure PickRandomTargets(CurrentTargetList : TList<RTarget>; PossibleTargetList : TList<TEntity>);
    published
      [XEvent(eiWelaUpdateTargets, epMiddle, etTrigger)]
      /// <summary> Update the list of targets. Remove invalid, add new. </summary>
      function OnUpdateShootingTargets(Targets : RParam) : boolean;
      [XEvent(eiWelaValidateTarget, epFirst, etRead)]
      /// <summary> Validate a target, whether it can be targeted. </summary>
      function OnValidateTarget(Target : RParam) : RParam;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> Set type of targets wela can attack (e.g. tcAllies). Default is tcEnemies.</summary>
      function SetTargetTeamConstraint(Value : EnumTargetTeamConstraint) : TWelaTargetingComponent;
      /// <summary> Wela can target everything, but prioritizes the set team.</summary>
      function SetTargetTeamConstraintPriority(Value : EnumTargetTeamConstraint) : TWelaTargetingComponent;
      /// <summary> Some welas mark an enemy to be not valid for other welas of the same type, so an existing target
      /// have to treated other than new targets. This method allow to validate target against another groups modules. </summary>
      function SetValidateGroup(Group : TArray<byte>) : TWelaTargetingComponent;
      /// <summary> This will pick the targets by random instead of everything else. Works in conjunction
      /// with SetTargetTeamConstraintPriority. </summary>
      function PicksRandomTargets : TWelaTargetingComponent;
      /// <summary> This will pick the targets by random and each target can be picked multiple times. </summary>
      function PicksRandomTargetsWithRepetition : TWelaTargetingComponent;
      function MaxNewTargetCount(Count : integer) : TWelaTargetingComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This targeting module looks for the next effectable unit in eiAttentionrange
  /// and return it as target. Approach brains are looking for targets with this component, because they only need the
  /// next enemy to walk to. Prefers units which are reached by walking straight along the lane. </summary>
  TWelaTargetingRadialAttentionComponent = class(TWelaTargetingComponent)
    protected
      FDisableStraightPreference : boolean;
      procedure UpdateTargets(CurrentList : TList<RTarget>); override;
      function ValidateTarget(Target : RTarget) : boolean; override;
    public
      function DisableStraightPreference : TWelaTargetingRadialAttentionComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This targeting module looks for the next effectable nexus. </summary>
  TWelaTargetingNexusComponent = class(TWelaTargetingComponent)
    protected
      procedure UpdateTargets(CurrentList : TList<RTarget>); override;
      function ValidateTarget(Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> This targeting module always targets owner. </summary>
  TWelaTargetingSelfComponent = class(TWelaTargetingComponent)
    protected
      procedure UpdateTargets(CurrentList : TList<RTarget>); override;
      function ValidateTarget(Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> This targeting module looks for the best targets in a circle with radius eiWelaRange. All current targets are
  /// preserved and only empty target slots are filled with the most efficient and if that equals nearest targets.
  /// Takes CollisionRadius of the targets and the owner into account.
  /// Targets with property upLowPrio are lower prioritized independently of efficiency and distance.
  /// Every targeted unit receives an eiWelaYoureMyTarget event from this component. </summary>
  TWelaTargetingRadialComponent = class(TWelaTargetingComponent)
    protected
      FIgnoreOwnCollisionradius, FPrioritizeMostDistant, FPrioritizeMiddleDistant : boolean;
      FConeDir : RVector2;
      FCone : single;
      FRangeEvent : EnumEventIdentifier;
      procedure UpdateTargets(CurrentList : TList<RTarget>); override;
      function ValidateTarget(Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function RangeFromEvent(EventIdentifier : EnumEventIdentifier) : TWelaTargetingRadialComponent;
      function PrioritizeMostDistant : TWelaTargetingRadialComponent;
      function PrioritizeMiddleDistant : TWelaTargetingRadialComponent;
      function IgnoreOwnCollisionradius : TWelaTargetingRadialComponent;
      function Cone(DirectionX, DirectionZ : single; Angle : single) : TWelaTargetingRadialComponent; overload;
      function Cone(Direction : RVector2; Angle : single) : TWelaTargetingRadialComponent; overload;
  end;

  {$RTTI INHERIT}

  /// <summary> This targeting module looks for the best targets on the whole map. All current targets are
  /// preserved and only empty target slots are filled with the most efficient and if that equals nearest targets.
  /// Takes CollisionRadius of the targets and the owner into account.
  /// Targets with property upLowPrio are lower prioritized independently of efficiency and distance.
  /// Every targeted unit receives an eiWelaYoureMyTarget event from this component. </summary>
  TWelaTargetingGlobalComponent = class(TWelaTargetingComponent)
    protected
      FDisableEfficiency : boolean;
      procedure UpdateTargets(CurrentList : TList<RTarget>); override;
      function ValidateTarget(Target : RTarget) : boolean; override;
    public
      function DisableEfficiencyCheck() : TWelaTargetingGlobalComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Looks for the best enemies in an rectangle, which is offseted and directed into
  /// front of the mesh and the computed left (Front.GetOrthogonal). Reads the eiWelaRange for
  /// the height (front direction) and uses a ratio for the width (width = height * WidthRatio).
  /// All current targets are  preserved and only empty target slots are filled with the most efficient
  /// and if that equals nearest targets.
  /// Takes CollisionRadius of the targets and the owner into account.
  /// Targets with property upLowPrio are lower prioritized independently of efficiency and distance.
  /// Every targeted unit receives an eiWelaYoureMyTarget event from this component. </summary>
  TWelaTargetingRectangleComponent = class(TWelaTargetingComponent)
    protected
      FOffset : RVector2;
      FRatio : single;
      FRectangle : ROrientedRect;
      procedure UpdateRectangle;
      procedure UpdateTargets(CurrentList : TList<RTarget>); override;
      function ValidateTarget(Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SetOffset(OffsetLeft, OffsetFront : single) : TWelaTargetingRectangleComponent;
      function SetWidthRatio(WidthRatio : single) : TWelaTargetingRectangleComponent;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Readynessmodules - only if they all say yes, it's time to rumble
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> The associated wela is only ready if unit maximum isn't exceeded.
  /// This component counts spawned units and tracks their death to ensure that at no point in time there
  /// are more entities on their way than eiWelaUnitMaximum caps. </summary>
  TWelaReadyUnitLimiterComponent = class(TWelaReadyComponent)
    protected
      FCurrentUnitCount : integer;
      function IsReady() : boolean; override;
    published
      function TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiWelaUnitProduced, epLast, etTrigger)]
      /// <summary> Start cooldown. </summary>
      function OnProduce(EntityID : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready each game tick dividable restless by N (default 60). Ticks are counted since creation. </summary>
  TWelaReadyEachNthGameTickComponent = class(TWelaReadyComponent)
    protected
      FTicks, FN : integer;
      FStartsReady : boolean;
      function IsReady() : boolean; override;
    published
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal)]
      /// <summary> Count Tick. </summary>
      function OnGameTick() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function StartsReady : TWelaReadyEachNthGameTickComponent;
      function SetN(n : integer) : TWelaReadyEachNthGameTickComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready after each nth check whether the wela is ready. </summary>
  TWelaReadyNthComponent = class(TWelaReadyComponent)
    protected
      FInvert : boolean;
      FCounter, FNth, FTimes : integer;
      function IsReady() : boolean; override;
    public
      /// <summary> Is only ready each nth time. </summary>
      function Nth(Nth : integer) : TWelaReadyNthComponent;
      /// <summary> Initialized the counter with another value than 0. </summary>
      function Counter(Counter : integer) : TWelaReadyNthComponent;
      /// <summary> Is ready the first n times. </summary>
      function Times(Times : integer) : TWelaReadyNthComponent;
      /// <summary> Is ready except each nth time. </summary>
      function Invert : TWelaReadyNthComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready if certain entities are nearby, uses a TWelaTargetingComponent to find entites. </summary>
  TWelaReadyEntityNearbyComponent = class(TWelaReadyComponent)
    protected
      FTargetingGroup : SetComponentGroup;
      FReadyIfTargets : boolean;
      function IsReady() : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function TargetingGroup(Group : TArray<byte>) : TWelaReadyEntityNearbyComponent;
      function ReadyIfTargets : TWelaReadyEntityNearbyComponent;
      function ReadyIfNoTargets : TWelaReadyEntityNearbyComponent;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Effectmodules - controlling the consequences of an eiFire event
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Redirects the target of a wela. </summary>
  TWelaEffectRedirecterComponent = class(TEntityComponent)
    protected
      FRedirectToGround : boolean;
    published
      [XEvent(eiFire, epFirst, etTrigger), ScriptExcludeMember]
      /// <summary> Fires the wela at all targets.. </summary>
      function OnFire(var Targets : RParam) : boolean;
    public
      function RedirectToGround : TWelaEffectRedirecterComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Masterclass for effects of welas. An effects reacts to eiFire events
  /// to start their specific action with it. </summary>
  TWelaEffectComponent = class abstract(TEntityComponent)
    protected
      procedure Fire(Targets : ATarget); virtual; abstract;
    published
      [XEvent(eiFire, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Fires the wela at all targets.. </summary>
      function OnFire(Targets : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Prevents the eiFire event by a certain Chance in eiWelaChance. </summary>
  TWelaEffectOnlyByChanceComponent = class abstract(TEntityComponent)
    published
      [XEvent(eiFire, epMiddle, etTrigger), ScriptExcludeMember]
      /// <summary> Consumes event by a chance. </summary>
      function OnFire(Targets : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Masterclass for effects of welas with efficiency. An effects knows its efficiency for a target (eiEfficiency)
  /// an reacts to eiFire events to start their specific action with it. </summary>
  TWelaEfficiencyEffectComponent = class abstract(TWelaEffectComponent)
    protected
      function GetEfficiency(TargetsInRange : TList<RTarget>) : single; virtual; abstract;
      /// <summary> Negativ value means cannot act on target. Positive Value is the efficiency</summary>
      function GetEfficiencyToTarget(Entity : TEntity) : single; virtual;
    published
      [XEvent(eiEfficiency, epFirst, etRead), ScriptExcludeMember]
      /// <summary> Return the efficiency of the wela to the target. -1 for not possible. </summary>
      function OnEfficiency(Target : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect consumes all costs returned by eiResourceCost at eiFire. They are payed by default
  /// of the owner itself and the group of this component. </summary>
  TWelaEffectPayCostComponent = class(TWelaEffectComponent)
    public
      const
      DEFAULT_NOT_PAYED_RESOURCES : SetResource = [reLevel, reTier];
      class threadvar NOT_PAYED_RESOURCES : SetResource;
    protected
      FPayingGroup : TDictionary<EnumResource, SetComponentGroup>;
      FDefaultPayingGroup : SetComponentGroup;
      FRedirectToCommander, FConsumesAll : boolean;
      FResourceConversion : TDictionary<EnumResource, EnumResource>;
      function GetPayingGroup(ResType : EnumResource) : SetComponentGroup;
      procedure Fire(Targets : ATarget); override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> Set a special group for paying the resources. Default is the ComponentGroup of this component. </summary>
      function SetPayingGroup(Group : TArray<byte>) : TWelaEffectPayCostComponent;
      /// <summary> Set a special group for paying a certain Resource. </summary>
      function SetPayingGroupForType(ResourceType : integer; Group : TArray<byte>) : TWelaEffectPayCostComponent;
      /// <summary> All resources of chosen costs are payed disregarding the amount of the costs. </summary>
      function ConsumesAll : TWelaEffectPayCostComponent;
      /// <summary> The commander pays for this effect. Changes paying group to []! </summary>
      function CommanderPays() : TWelaEffectPayCostComponent;
      function ConvertResource(FromResource, ToResource : EnumResource) : TWelaEffectPayCostComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Replaces the owning unit with another (eiWelaUnitPattern), e.g. for upgrading a spawner.
  /// The owner gets killed by eiDelayedKillEntity, then the new unit will be spawned and a global event eiReplaceEntity
  /// informs all interested parties of the replacement.  </summary>
  TWelaEffectReplaceComponent = class(TWelaEffectComponent)
    protected
      FNewTeam : integer;
      FKeepTakenDamage : boolean;
      FResource : EnumResource;
      procedure Fire(Targets : ATarget); override;
    public
      function SetNewTeam(NewTeam : integer) : TWelaEffectReplaceComponent;
      function KeepTakenDamage : TWelaEffectReplaceComponent;
      function KeepResource(Resource : EnumResource) : TWelaEffectReplaceComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Deactivates the ability on usage (eiWelaActive, only thrown if status would change).
  /// Certain condition can be chosen.  </summary>
  TWelaEffectActivationAbilityComponent = class(TWelaEffectComponent)
    protected
      FOnCap, FActivationState, FOnlyAfterGameStart, FInvertOnCap : boolean;
      FCheckGroup, FActivationGroup : SetComponentGroup;
      FResType : integer;
      procedure Fire(Targets : ATarget); override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function OnlyAfterGameStart : TWelaEffectActivationAbilityComponent;
      function TriggerOnReachResourceCap(ResType : integer) : TWelaEffectActivationAbilityComponent;
      function CheckNotFull(ResType : integer) : TWelaEffectActivationAbilityComponent;
      function SetCheckGroup(CheckGroup : TArray<byte>) : TWelaEffectActivationAbilityComponent;
      function SetsActive() : TWelaEffectActivationAbilityComponent;
      function SetActivationGroup(ActivationGroup : TArray<byte>) : TWelaEffectActivationAbilityComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect kills (eiDelayedKillEntity) the owner after the use of the associated wela. </summary>
  TWelaEffectSuicideComponent = class(TWelaEffectComponent)
    protected
      FDontFree, FPreventDeath : boolean;
      procedure Fire(Targets : ATarget); override;
    published
      [XEvent(eiDie, epLow, etTrigger)]
      /// <summary> On dying fire at itself. </summary>
      function OnBeforeDie(KillerID, KillerCommanderID : RParam) : boolean;
    public
      function PreventDeath : TWelaEffectSuicideComponent;
      function DontFree : TWelaEffectSuicideComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect calls eiCommanderAbilityUsed globally to notify a spell cast. </summary>
  TWelaEffectTriggerSpellCastComponent = class(TWelaEffectComponent)
    protected
      procedure Fire(Targets : ATarget); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Removes all components of the componentgroup of the wela after usage.
  /// Attention not likely be used with [] group, because it would clean all components of the entity! </summary>
  TWelaEffectRemoveAfterUseComponent = class(TWelaEffectComponent)
    protected
      FTargetGroup : SetComponentGroup;
      procedure Fire(Targets : ATarget); override;
    public
      function TargetGroup(TargetGroup : TArray<byte>) : TWelaEffectRemoveAfterUseComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> An effect which spawns n units (eiWelaCount) with the specified pattern (eiWelaUnitPattern) at the target.
  /// The units inherits the TeamID, Front and owning Commander of this entity.
  /// If the target is a Buildgrid the unit size (eiWelaNeededGridSize) is blocked (not checked, this does the TWelaTargetConstraintGridComponent).
  /// For each produced unit eiWelaUnitProduced is called locally and entity globally</summary>
  TWelaEffectFactoryComponent = class(TWelaEffectComponent)
    protected
      FNewTeam : integer;
      FPassCardValues, FSpawnsDifferentUnits, FUseAoE, FAoECircle, FPassTargets, FIsSpawner : boolean;
      procedure Fire(Targets : ATarget); override;
    public
      constructor CreateGrouped(Entity : TEntity; Group : TArray<byte>); override;
      /// <summary> Saves the resources reCardLeague and reCardLevel in the entity. </summary>
      function PassCardValues : TWelaEffectFactoryComponent;
      /// <summary> If this option is used the factory spawns different units found in the indices of eiWelaUnitPattern.
      /// Otherwise the return value of eiWelaUnitPattern is used for all spawned units. </summary>
      function SpawnsDifferentUnits : TWelaEffectFactoryComponent;
      /// <summary> Uses eiWelaAreaOfEffect for randomize spawning position. </summary>
      function SpreadSpawns() : TWelaEffectFactoryComponent;
      /// <summary> Uses eiWelaAreaOfEffect for randomize spawning position on a circle around target. </summary>
      function SpreadSpawnsOnCircle() : TWelaEffectFactoryComponent;
      /// <summary> Uses eiWelaAreaOfEffect for randomize spawning position. </summary>
      function IsSpawner() : TWelaEffectFactoryComponent;
      /// <summary> This option will spawn the entity at the first target and then save the targets with their index in
      /// eiWelaSavedTargets at the spawned entity. </summary>
      function PassTargets() : TWelaEffectFactoryComponent;
      /// <summary> Units spawned by this factory won't inherit the TeamID, but take the specified one. </summary>
      function SetSpawnedTeam(TeamID : integer) : TWelaEffectFactoryComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> At creation of a new unit, this unit will inherit a specific event value of the creator (read at creation time).
  /// The event is specified at create as well as the group it is saved to. </summary>
  TWelaEffectInheritEventValueComponent = class(TEntityComponent)
    protected
      FEvent : EnumEventIdentifier;
      FTargetGroup : SetComponentGroup;
    published
      [XEvent(eiWelaUnitProduced, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Writes the specified event value to the new unit. </summary>
      function OnWelaUnitProduced(EntityID : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; EventToWrite : EnumEventIdentifier); reintroduce;
      function TargetGroup(Group : TArray<byte>) : TWelaEffectInheritEventValueComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect increases the selected resource of its owning group by 1. </summary>
  TWelaEffectIncreaseResourceComponent = class(TWelaEffectComponent)
    protected
      FResource : EnumResource;
      procedure Fire(Targets : ATarget); override;
    public
      function SetResourceType(Resource : EnumResource) : TWelaEffectIncreaseResourceComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect fires directly all associated warheads (all those which are in the same group as this component) on the target. </summary>
  TWelaEffectInstantComponent = class(TWelaEfficiencyEffectComponent)
    protected
      FTargetGroup : SetComponentGroup;
      procedure Fire(Targets : ATarget); override;
      function GetEfficiency(TargetsInRange : TList<RTarget>) : single; override;
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
    public
      constructor CreateGrouped(Entity : TEntity; Group : TArray<byte>); override;
      /// <summary> Fires eiFireWarhead in the following groups instead of the component group. </summary>
      function TargetGroup(Group : TArray<byte>) : TWelaEffectInstantComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect set game events globally on fire. </summary>
  TWelaEffectGameEventComponent = class(TWelaEffectComponent)
    protected
      FGameEvents : TArray<string>;
      procedure Fire(Targets : ATarget); override;
    public
      /// <summary> Adds an event, which will be set on fire.</summary>
      function Event(const EventID : string) : TWelaEffectGameEventComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect fires directly another wela specified by targetgroup on the target. Does target checks. </summary>
  TWelaEffectFireComponent = class(TWelaEffectComponent)
    protected
      FRedirectToSelf, FRedirectToSource, FRedirectToDestination, FRedirectToGround, FFireInCreator : boolean;
      FGroundJitterMinRange, FGroundJitterMaxRange : single;
      FTargetGroup : SetComponentGroup;
      FMultitargetGroup : TArray<SetComponentGroup>;
      procedure Fire(Targets : ATarget); override;
    public
      function FireInCreator : TWelaEffectFireComponent;
      function TargetGroup(const Group : TArray<byte>) : TWelaEffectFireComponent;
      /// <summary> Check each target group and fire in the first possible one. </summary>
      function MultiTargetGroup(const Group : TArray<byte>) : TWelaEffectFireComponent;
      /// <summary> Changes the fire target to the ground and disable target checks. Overwrites other redirections.
      /// Does not work with FireInCreator. </summary>
      function RedirectToGround : TWelaEffectFireComponent;
      /// <summary> Redirected targets to ground are jittered within range. Ensures target to be inside of WALK_ZONE. </summary>
      function RandomizeGroundtarget(MinRange, MaxRange : single) : TWelaEffectFireComponent;
      /// <summary> Changes the fire target and checks to the entity itself. Overwrites other redirections. </summary>
      function RedirectToSelf : TWelaEffectFireComponent;
      /// <summary> Changes the fire target and checks to the link source. Overwrites other redirections.</summary>
      function RedirectToLinkSource : TWelaEffectFireComponent;
      /// <summary> Changes the fire target and checks to the link destination. Overwrites other redirections.</summary>
      function RedirectToLinkDestination : TWelaEffectFireComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect resets the cooldown of the target group. </summary>
  TWelaEffectResetCooldownComponent = class(TWelaEffectComponent)
    protected
      FExpire : boolean;
      FTargetGroup : SetComponentGroup;
      FLookForGroup : SetUnitProperty;
      procedure Fire(Targets : ATarget); override;
    public
      function TargetGroup(const Group : TArray<byte>) : TWelaEffectResetCooldownComponent;
      function SearchForWelaBeacon(const Properties : TArray<byte>) : TWelaEffectResetCooldownComponent;
      function Expire : TWelaEffectResetCooldownComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect removes all groups with the specified beacons of the properties. </summary>
  TWelaEffectRemoveBeaconComponent = class(TWelaEffectComponent)
    protected
      FLookForGroup : SetUnitProperty;
      procedure Fire(Targets : ATarget); override;
    public
      function SearchForWelaBeacon(const Properties : TArray<byte>) : TWelaEffectRemoveBeaconComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect spawns a projectile (script specified in eiWelaUnitPattern) an launches at the target (eiWelaSavedTargets).
  /// It copies eiWeladamage, eiWelaSplashfactor, eiWelaAreaOfEffect, eiDamageType, eiWelaTargetCount at spawn, so a projectile is after launch independent.</summary>
  TWelaEffectProjectileComponent = class(TWelaEfficiencyEffectComponent)
    protected
      FReverse, FIsLinkEffect, FReverseLink, FMultipleProjectiles : boolean;
      procedure Fire(Targets : ATarget); override;
      function GetEfficiency(TargetsInRange : TList<RTarget>) : single; override;
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
    public
      /// <summary> Shoots at each target eiWelaCount projectiles. </summary>
      function MultipleProjectiles : TWelaEffectProjectileComponent;
      /// <summary> Shoots the projectile from Target to self. </summary>
      function Reverse : TWelaEffectProjectileComponent;
      /// <summary> Shoots from eiLinkSource and not from self. </summary>
      function IsLinkEffect : TWelaEffectProjectileComponent;
      /// <summary> Shoots from eiLinkDest and not from self. </summary>
      function ReverseLink : TWelaEffectProjectileComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This effect establishes and breaks links to the targets. At the moment it handles focus and
  /// such do things which the associated brain should do, TODO refactor this into the brain. </summary>
  TWelaLinkEffectComponent = class(TWelaEfficiencyEffectComponent)
    protected
      FCurrentLinks : TDictionary<RTarget, integer>;
      FLinkOrder : TList<RTarget>;
      FCreatorGroup : SetComponentGroup;
      /// <summary> Create a link between self and target. </summary>
      procedure Fire(Targets : ATarget); override;
      function GetEfficiency(TargetsInRange : TList<RTarget>) : single; override;
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
      function EstablishLink(Source, Dest : RTarget) : boolean;
      procedure BreakLink(LinkTarget : RTarget);
      procedure BreakAllLinks;
    published
      [XEvent(eiLinkBreak, epLast, etTrigger)]
      /// <summary> Kills the linkentity to the target. </summary>
      function OnBreak(LinkTarget : RParam) : boolean;
      [XEvent(eiLinkEstablish, epFirst, etTrigger)]
      /// <summary> Establishes a link between Source and Dest. If targetcount is exceeded, the oldest link will be destroyed. </summary>
      function OnEstablishLink(Source, Dest : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> Breaks all links on death. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiExiled, epLast, etWrite)]
      /// <summary> Breaks all links on exile. </summary>
      function OnExiled(Exiled : RParam) : boolean;
      [XEvent(eiLose, epMiddle, etTrigger, esGlobal)]
      /// <summary> Breaks all links on game finish. </summary>
      function OnLose(TeamID : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function CreatorGroup(Group : TArray<byte>) : TWelaLinkEffectComponent;
      destructor Destroy; override;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// both effect and ready components
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> This component is an effect and a ready component as well. It ensures that the price can be payed and is payed.
  /// With this component a link has a steady cost over time (eiResourceCost / s). They are payed by the owner itself.
  /// ATTENTION: Uses the eiThinkChain event to apply the consumption of the resource, so needs a ThinkImpulseComponent.</summary>
  TWelaEffectLinkPayCostMyselfComponentServer = class(TWelaReadyCostComponent)
    protected
      FLastAppliedTimestamp : Int64;
      FLinkCount : integer;
      FOnEmptyTargetGroup : SetComponentGroup;
      procedure ApplyResources;
      procedure Pay(Times : integer);
    published
      [XEvent(eiLinkEstablish, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Start resource consumption. </summary>
      function OnLinkEstablish(Source, Dest : RParam) : boolean;
      [XEvent(eiLinkBreak, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> End resource consumption. </summary>
      function OnLinkBreak(Target : RParam) : boolean;
      [XEvent(eiThinkChain, epFirst, etTrigger), ScriptExcludeMember]
      /// <summary> Apply resource consumption. </summary>
      function OnThink() : boolean;
    public
      function FireOnEmpty(TargetGroup : TArray<byte>) : TWelaEffectLinkPayCostMyselfComponentServer;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Link specific components
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> This component gives a unit a specified property as long there persists a link to it.
  /// With eiLinkEstablish the target gets the property, with eiLinkBreak it is removed.
  /// Attention: If the unit has the property already, it will be removed after the link break and is not preserved atm! </summary>
  TWelaLinkEffectUnitPropertyComponent = class(TEntityComponent)
    protected
      FGivenUnitProperty : EnumUnitProperty;
    published
      [XEvent(eiLinkBreak, epLower, etTrigger)]
      /// <summary> Removes the unit property from target destination. </summary>
      function OnBreak(LinkTarget : RParam) : boolean;
      [XEvent(eiLinkEstablish, epLast, etTrigger)]
      /// <summary> Gives the dest the unit property </summary>
      function OnEstablishLink(Source, Dest : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; GivenUnitProperty : EnumUnitProperty); reintroduce;
  end;

  {$RTTI INHERIT}

  /// <summary> A projectile notifies its creator of some things, like dealt damage for life leech.  </summary>
  TProjectileEventRedirecter = class(TEntityComponent)
    protected
      function GetCreator : TEntity;
      function GetCreatorScriptFileName : string;
    published
      [XEvent(eiWillDealDamage, epLast, etRead)]
      function OnWillDealDamage(Amount, DamageTypes, TargetEntity : RParam; Previous : RParam) : RParam;
      [XEvent(eiDamageDone, epLast, etTrigger)]
      function OnDoneDamage(Amount, DamageType, TargetEntity : RParam) : boolean;
      [XEvent(eiYouHaveKilledMeShameOnYou, epLast, etTrigger)]
      function OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> A link fetches data from its source if no data is present to, e.g. do damage. This component redirects
  /// all eiCooldown, eiWeladamage and eiDamageType reads to the source of the link.  </summary>
  TLinkEventRedirecter = class(TEntityComponent)
    protected
      FGroup : SetComponentGroup;
      FSourceIndex : integer;
      function GetSource : TEntity;
    published
      [XEvent(eiCooldown, epFirst, etRead)]
      [XEvent(eiWeladamage, epFirst, etRead)]
      [XEvent(eiDamageType, epFirst, etRead)]
      /// <summary> Redirect events. </summary>
      function OnEvent(Previous : RParam) : RParam;
      [XEvent(eiDamageDone, epLast, etTrigger)]
      function OnDamageDone(Amount, DamageType, TargetEntity : RParam) : boolean;
      [XEvent(eiYouHaveKilledMeShameOnYou, epLast, etTrigger)]
      function OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>; SourceGroup : SetComponentGroup); reintroduce;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Linkeffects - continous effects a link may apply
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Effect which redirects all not irredirectable damage from source to destination. </summary>
  TLinkEffectDamageRedirectionComponent = class(TEntityComponent)
    protected
      FRedirectFromDestination : boolean;
      function GetSource : ATarget;
      function GetDestination : ATarget;
    published
      function TargetTakeDamage(var Amount : RParam; DamageType, InflictorID : RParam) : RParam;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Hook source eiTakeDamage. </summary>
      function OnAfterCreate() : boolean;
    public
      function DestinationToSource() : TLinkEffectDamageRedirectionComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Effect which fires (eiFire) at all produced (eiWelaUnitProduced) units of the destination. </summary>
  TLinkEffectFireAtProducedUnitsComponent = class(TEntityComponent)
    published
      function TargetProducesUnit(EntityID : RParam) : boolean;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Hook destination eiWelaUnitProduced. </summary>
      function OnAfterCreate() : boolean;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Modifier - things which modifies events in welas
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Multiply all dealt damage by eiWeladamage by a chance eiWelaChance.
  /// if eiWelaChance is not present, damage will be adjusted always.
  /// Sends eiFire to ValueGroup if chance applied. </summary>
  TModifierMultiplyDealtDamageComponent = class(TModifierComponent)
    protected
      FMustHave, FMustNotHave : SetDamageType;
      FCheckWelaConstraint : boolean;
    published
      [XEvent(eiWillDealDamage, epMiddle, etRead)]
      /// <summary> Roll the dice to deal possibly adjusted damage. </summary>
      function OnWillDealDamage(Amount, DamageTypes, TargetEntity : RParam; Previous : RParam) : RParam;
    public
      function CheckWelaConstraint : TModifierMultiplyDealtDamageComponent;
      function MustHave(DamageTypes : TArray<byte>) : TModifierMultiplyDealtDamageComponent;
      function MustNotHave(DamageTypes : TArray<byte>) : TModifierMultiplyDealtDamageComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Prevents the eiFireWarhead event by 50% and fires if prevented eiFire to ValueGroup. </summary>
  TModifierBlindedComponent = class(TModifierComponent)
    protected const
      BLIND_CHANCE = 0.5;
    protected
      FWillMiss : boolean;
      FFireGroup : SetComponentGroup;
    published
      [XEvent(eiFire, epFirst, etTrigger)]
      /// <summary> Roll the miss dice. </summary>
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiFireWarhead, epFirst, etTrigger)]
      /// <summary> Consumes event by a chance. </summary>
      function OnFireWarhead(Targets : RParam) : boolean;
      [XEvent(eiWelaShotProjectile, epMiddle, etTrigger)]
      /// <summary> Marks the projectile to miss if last fire determined to miss. </summary>
      function OnWelaShotProjectile(Projectile : RParam) : boolean;
    public
      function SetFireGroup(Group : TArray<byte>) : TModifierBlindedComponent;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Helper - things which do support work for welas
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Returns its group when searched for a certain unit property with eiWelaSearch.</summary>
  TWelaHelperBeaconComponent = class abstract(TEntityComponent)
    protected
      FUnitProperties : SetUnitProperty;
    published
      [XEvent(eiWelaSearch, epFirst, etRead)]
      function OnWelaSearch(Properties : RParam; Previous : RParam) : RParam;
    public
      function TriggerAt(const Properties : TArray<byte>) : TWelaHelperBeaconComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Initializes once at game start the wela activation state reagarding whether the game is running or not. </summary>
  TWelaHelperInitActiveAfterGameStartComponent = class(TEntityComponent)
    private
      FDisableOnReachResourceCap : EnumResource;
      FCheckGroup : SetComponentGroup;
      FDisabled : boolean;
    published
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal)]
      /// <summary> Activate this weapon. </summary>
      function OnGameTick() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>); override;
      function DisableOnReachResourceCap(Resource : integer; Group : TArray<byte>) : TWelaHelperInitActiveAfterGameStartComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Activates the wela after timer expires. Frees itself afterwards. </summary>
  TWelaHelperActivateTimerComponent = class(TEntityComponent)
    protected
      FTimer : TTimer;
    published
      [XEvent(eiIdle, epLast, etTrigger, esGlobal)]
      /// <summary> Activate this weapon if timer expired. </summary>
      function OnIdle() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>); override;
      function Delay(const Duration : integer) : TWelaHelperActivateTimerComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Prioritizes targets for the targeting components. </summary>
  TWelaEfficiencyComponent = class abstract(TEntityComponent)
    protected
      function GetEfficiencyToTarget(Entity : TEntity) : single; virtual; abstract;
    published
      [XEvent(eiEfficiency, epMiddle, etRead), ScriptExcludeMember]
      function OnEfficiency(Target, Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Prioritizes targets with their missing health. </summary>
  TWelaEfficiencyMissingHealthComponent = class(TWelaEfficiencyComponent)
    protected
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Prioritizes targets with were created first. </summary>
  TWelaEfficiencyCreatedComponent = class(TWelaEfficiencyComponent)
    protected
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Prioritizes targets with their maximum health. </summary>
  TWelaEfficiencyMaxHealthComponent = class(TWelaEfficiencyComponent)
    protected
      FInversed : boolean;
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
    public
      function Inverse : TWelaEfficiencyMaxHealthComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Prioritizes targets with a damage type in their main weapon. </summary>
  TWelaEfficiencyDamageTypeComponent = class(TWelaEfficiencyComponent)
    protected
      FPrioritizedDamageTypes : SetDamageType;
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
    public
      function Prioritize(DamageTypes : TArray<byte>) : TWelaEfficiencyDamageTypeComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Prioritizes targets with a certain unit property. </summary>
  TWelaEfficiencyUnitPropertyComponent = class(TWelaEfficiencyComponent)
    protected
      FReversed : boolean;
      FPrioritizedUnitProperties : SetUnitProperty;
      function GetEfficiencyToTarget(Entity : TEntity) : single; override;
    public
      function Prioritize(UnitProperties : TArray<byte>) : TWelaEfficiencyUnitPropertyComponent;
      /// <summary> Reverse the priorization, so units with the unit properties are treated less prioritized. </summary>
      function Reverse : TWelaEfficiencyUnitPropertyComponent;
  end;

implementation

uses
  BaseConflict.Globals.Server,
  BaseConflict.Game;

{ TLinkEventRedirecter }

constructor TLinkEventRedirecter.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>; SourceGroup : SetComponentGroup);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FGroup := SourceGroup;
end;

function TLinkEventRedirecter.GetSource : TEntity;
var
  temp : ATarget;
begin
  Result := nil;
  temp := Eventbus.Read(eiLinkSource, []).AsATarget;
  if not temp.HasIndex(FSourceIndex) then
      MakeException(Format('GetSource: Couldn''t find source index %d!', [FSourceIndex]));
  if temp[FSourceIndex].IsEntity then Result := temp[FSourceIndex].GetTargetEntity;
end;

function TLinkEventRedirecter.OnDamageDone(Amount, DamageType, TargetEntity : RParam) : boolean;
var
  Source : TEntity;
begin
  Result := True;
  Source := GetSource;
  if assigned(Source) then
      Source.Eventbus.Trigger(eiDamageDone, [Amount, DamageType, TargetEntity]);
end;

function TLinkEventRedirecter.OnEvent(Previous : RParam) : RParam;
var
  Source : TEntity;
begin
  if Previous.IsEmpty then
  begin
    Source := GetSource;
    if assigned(Source) then
        Result := Source.Eventbus.Read(CurrentEvent.EventIdentifier, [], FGroup);
  end
  else Result := Previous;
end;

function TLinkEventRedirecter.OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
var
  Source : TEntity;
begin
  Result := True;
  Source := GetSource;
  if assigned(Source) then
      Source.Eventbus.Trigger(eiYouHaveKilledMeShameOnYou, [KilledUnitID]);
end;

{ TWelaEffectRemoveAfterUseComponent }

procedure TWelaEffectRemoveAfterUseComponent.Fire(Targets : ATarget);
var
  TargetGroup : SetComponentGroup;
begin
  assert(ComponentGroup <> [], 'Are you sure to clean all components of this entity? A componentless entity should be killed.');
  if FTargetGroup = [] then TargetGroup := ComponentGroup
  else TargetGroup := FTargetGroup;
  GlobalEventbus.Trigger(eiRemoveComponentGroup, [FOwner.ID, RParam.From<SetComponentGroup>(TargetGroup)]);
end;

function TWelaEffectRemoveAfterUseComponent.TargetGroup(TargetGroup : TArray<byte>) : TWelaEffectRemoveAfterUseComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(TargetGroup);
end;

{ TWelaEffectInstantComponent }

constructor TWelaEffectInstantComponent.CreateGrouped(Entity : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Entity, Group);
  FTargetGroup := ComponentGroup;
end;

procedure TWelaEffectInstantComponent.Fire(Targets : ATarget);
begin
  if Eventbus.Read(eiWarheadTargetPossible, [Targets.ToRParam], CurrentEvent.CalledToGroup).AsRTargetValidity.IsValid then
      Eventbus.Trigger(eiFireWarhead, [Targets.ToRParam], FTargetGroup);
end;

function TWelaEffectInstantComponent.GetEfficiency(TargetsInRange : TList<RTarget>) : single;
begin
  Result := Eventbus.Read(eiWeladamage, [], CurrentEvent.CalledToGroup).AsSingle;
end;

function TWelaEffectInstantComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
var
  IsPossible : boolean;
begin
  IsPossible := not(upUntargetable in Entity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty>);
  if IsPossible then Result := 1
  else Result := -1;
end;

function TWelaEffectInstantComponent.TargetGroup(Group : TArray<byte>) : TWelaEffectInstantComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaEffectReplaceComponent }

procedure TWelaEffectReplaceComponent.Fire(Targets : ATarget);
var
  TargetEntity, newEntity : TEntity;
  TeamID : integer;
  takenDamage : single;
  OldResource : RParam;
  i : integer;
begin
  for i := 0 to Targets.Count - 1 do
    if not HLog.AssertAndLog(Targets[i].IsEntity, 'TWelaEffectReplaceComponent.Fire: Only entities are valid targets!')
      and Targets[i].TryGetTargetEntity(TargetEntity) then
    begin
      if (FNewTeam <> 0) then TeamID := FNewTeam
      else TeamID := TargetEntity.TeamID;

      GlobalEventbus.Trigger(eiDelayedKillEntity, [TargetEntity.ID]);
      newEntity := ServerGame.ServerEntityManager.SpawnUnit(
        TargetEntity.Position,
        TargetEntity.Front,
        Eventbus.Read(eiWelaUnitPattern, [], ComponentGroup).AsString,
        TargetEntity.CardLeague,
        TargetEntity.CardLevel,
        TeamID,
        TargetEntity.Eventbus.Read(eiOwnerCommander, []).AsInteger,
        Owner,
        nil,
        procedure(PreprocessedEntity : TEntity)
        begin
          PreprocessedEntity.SkinID := Owner.SkinID;
          PreprocessedEntity.Blackboard.SetValue(eiSkinIdentifier, [], Owner.SkinID);
        end
        );
      if FKeepTakenDamage then
      begin
        takenDamage := TargetEntity.Eventbus.Read(eiResourceCap, [ord(reHealth)]).AsSingle;
        takenDamage := takenDamage - TargetEntity.Eventbus.Read(eiResourceBalance, [ord(reHealth)]).AsSingle;
        newEntity.Eventbus.Trigger(eiResourceTransaction, [ord(reHealth), -takenDamage]);
      end;
      if FResource <> reNone then
      begin
        OldResource := Eventbus.Read(eiResourceBalance, [ord(FResource)]);
        newEntity.Eventbus.Write(eiResourceBalance, [ord(FResource), OldResource]);
      end;
      TargetEntity.Eventbus.Trigger(eiWelaUnitProduced, [newEntity.ID], ComponentGroup);
      GlobalEventbus.Trigger(eiReplaceEntity, [FOwner.ID, newEntity.ID, False]);
    end;
end;

function TWelaEffectReplaceComponent.KeepResource(Resource : EnumResource) : TWelaEffectReplaceComponent;
begin
  Result := self;
  FResource := Resource;
end;

function TWelaEffectReplaceComponent.KeepTakenDamage : TWelaEffectReplaceComponent;
begin
  Result := self;
  FKeepTakenDamage := True;
end;

function TWelaEffectReplaceComponent.SetNewTeam(NewTeam : integer) : TWelaEffectReplaceComponent;
begin
  Result := self;
  FNewTeam := NewTeam;
end;

{ TWelaReadyUnitLimiterComponent }

function TWelaReadyUnitLimiterComponent.IsReady : boolean;
var
  maximum : integer;
begin
  maximum := Eventbus.Read(eiWelaUnitMaximum, [], ComponentGroup).AsInteger;
  Result := (maximum <= 0) or (FCurrentUnitCount < maximum);
end;

function TWelaReadyUnitLimiterComponent.TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  FCurrentUnitCount := Max(0, FCurrentUnitCount - 1);
end;

function TWelaReadyUnitLimiterComponent.OnProduce(EntityID : RParam) : boolean;
var
  ent : TEntity;
begin
  Result := True;
  if (ComponentGroup <> []) and (ComponentGroup * CurrentEvent.CalledToGroup <> []) then exit;
  ent := Game.EntityManager.GetEntityByID(EntityID.AsInteger);
  if assigned(ent) then
  begin
    ent.Eventbus.SubscribeRemote(eiDie, etTrigger, epLast, self, 'TargetOnDie', 2);
    inc(FCurrentUnitCount);
  end;
end;

{ TWelaEffectComponent }

function TWelaEffectComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if IsLocalCall then Fire(Targets.AsATarget);
end;

{ TWelaEfficiencyEffectComponent }

function TWelaEfficiencyEffectComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
begin
  Result := -1;
end;

function TWelaEfficiencyEffectComponent.OnEfficiency(Target : RParam) : RParam;
begin
  Result := GetEfficiencyToTarget(Target.AsType<TEntity>);
end;

{ TWelaTargetingComponent }

constructor TWelaTargetingComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FValidateGroup := ComponentGroup;
  FTargetTeamConstraint := tcEnemies;
  FTargetPriorization := tcAll;
end;

function TWelaTargetingComponent.FetchEfficiency(Target : TEntity; TargetGroup : SetComponentGroup) : single;
begin
  if IsTargetPossible(Target, TargetGroup) then
  begin
    Result := Eventbus.Read(eiEfficiency, [Target], TargetGroup).AsSingle;
    if FTargetPriorization <> tcAll then
    begin
      if ((FTargetPriorization = tcEnemies) and (Owner.TeamID <> Target.TeamID)) or
        ((FTargetPriorization = tcAllies) and (Owner.TeamID = Target.TeamID)) then Result := Result + 0.01;
    end;
  end
  else Result := -1;
end;

function TWelaTargetingComponent.IsTargetPossible(Target : TEntity; TargetGroup : SetComponentGroup) : boolean;
var
  Possible : RParam;
begin
  if not assigned(Target) or Target.Eventbus.Read(eiExiled, []).AsBoolean then exit(False);
  Possible := Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Target).ToRParam], TargetGroup).AsRTargetValidity.IsValid;
  Result := Possible.AsBooleanDefaultTrue;
end;

function TWelaTargetingComponent.OnUpdateShootingTargets(Targets : RParam) : boolean;
begin
  Result := True;
  UpdateTargets(Targets.AsType < TList < RTarget >> );
end;

function TWelaTargetingComponent.OnValidateTarget(Target : RParam) : RParam;
begin
  if Target.IsEmpty then Result := ValidateTarget(RTarget.Create(nil))
  else Result := ValidateTarget(Target.AsType<RTarget>);
end;

procedure TWelaTargetingComponent.PickRandomTargets(CurrentTargetList : TList<RTarget>; PossibleTargetList : TList<TEntity>);
var
  MaxTargets, pick, MaxNew : integer;
  PrioritizedTargets, Targets, PickList : TList<TEntity>;
  Target : TEntity;
  i : integer;
begin
  if not(assigned(PossibleTargetList) and assigned(CurrentTargetList)) then exit;
  MaxTargets := Max(1, Eventbus.Read(eiWelaTargetCount, [], ComponentGroup).AsInteger);
  if FMaxNewTargetCount <= 0 then
      MaxNew := 10000
  else
      MaxNew := FMaxNewTargetCount;
  PrioritizedTargets := TList<TEntity>.Create;
  if FTargetPriorization <> tcAll then
  begin
    Targets := TList<TEntity>.Create;
    for i := 0 to PossibleTargetList.Count - 1 do
    begin
      Target := PossibleTargetList[i];
      if ((FTargetPriorization = tcEnemies) and (Owner.TeamID <> Target.TeamID)) or
        ((FTargetPriorization = tcAllies) and (Owner.TeamID = Target.TeamID)) then PrioritizedTargets.Add(Target)
      else Targets.Add(Target);
    end;
    PossibleTargetList.Free;
  end
  else Targets := PossibleTargetList;

  while ((PrioritizedTargets.Count > 0) or (Targets.Count > 0)) and (CurrentTargetList.Count < MaxTargets) and (MaxNew > 0) do
  begin
    if PrioritizedTargets.Count > 0 then PickList := PrioritizedTargets
    else PickList := Targets;
    pick := random(PickList.Count);
    if FRepetition or not CurrentTargetList.Contains(RTarget.Create(PickList[pick])) then
    begin
      CurrentTargetList.Add(RTarget.Create(PickList[pick]));
      PickList[pick].Eventbus.Trigger(eiWelaYoureMyTarget, [FOwner]);
      dec(MaxNew);
    end;
    if not FRepetition then
        PickList.Delete(pick);
  end;
  PrioritizedTargets.Free;
  Targets.Free;
end;

function TWelaTargetingComponent.PicksRandomTargets : TWelaTargetingComponent;
begin
  Result := self;
  FPickRandom := True;
end;

function TWelaTargetingComponent.PicksRandomTargetsWithRepetition : TWelaTargetingComponent;
begin
  Result := self;
  FPickRandom := True;
  FRepetition := True;
end;

function TWelaTargetingComponent.MaxNewTargetCount(Count : integer) : TWelaTargetingComponent;
begin
  Result := self;
  FMaxNewTargetCount := Count;
end;

function TWelaTargetingComponent.SetTargetTeamConstraint(Value : EnumTargetTeamConstraint) : TWelaTargetingComponent;
begin
  FTargetTeamConstraint := Value;
  Result := self;
end;

function TWelaTargetingComponent.SetTargetTeamConstraintPriority(Value : EnumTargetTeamConstraint) : TWelaTargetingComponent;
begin
  Result := self;
  FTargetTeamConstraint := tcAll;
  FTargetPriorization := Value;
end;

function TWelaTargetingComponent.SetValidateGroup(Group : TArray<byte>) : TWelaTargetingComponent;
begin
  Result := self;
  FValidateGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaEffectFactoryComponent }

constructor TWelaEffectFactoryComponent.CreateGrouped(Entity : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Entity, Group);
  FNewTeam := -1;
end;

procedure TWelaEffectFactoryComponent.Fire(Targets : ATarget);
var
  Count : integer;
  Position, Front, Side : RVector2;
  SpawnedEntity : TEntity;
  AoE : RParam;
  TargetPos : RVector2;
  NeededGridSize : RIntVector2;
  BuildZone : TBuildZone;
  Pattern, SkinID : string;
  TeamID, i, j, Index : integer;
  Target : RTarget;
  BlockedFieldGrids : TArray<RTuple<integer, RIntVector2>>;
begin
  inherited;
  Count := Max(1, Eventbus.Read(eiWelaCount, [], CurrentEvent.CalledToGroup).AsInteger);
  for index := 0 to length(Targets) - 1 do
  begin
    Target := Targets[index];
    if FPassTargets and (index <> 0) then exit;
    for i := 0 to Count - 1 do
    begin
      Position := Target.GetTargetPosition;
      Front := Owner.Front;

      if Target.IsBuildTarget then
      begin
        NeededGridSize := Eventbus.Read(eiWelaNeededGridSize, [], CurrentEvent.CalledToGroup).AsIntVector2;
        Position := Target.GetRealBuildPosition(NeededGridSize);
        Front := Target.GetBuildZone.Front;
      end;
      // apply spawn pattern when multispawn units
      if FUseAoE then
      begin
        AoE := Eventbus.Read(eiWelaAreaOfEffect, [], CurrentEvent.CalledToGroup);
        if not AoE.IsEmpty then
        begin
          Side := Front * AoE.AsSingle;
          if not FAoECircle then Side := Side * random;
          Side := Side.Rotate(random * 2 * PI);
          Position := Position + Side;
        end
        else Position := ComputeSpawningPattern(Position, Front, FIsSpawner, i, Count);
      end;

      Pattern := '';
      SkinID := '';
      if FSpawnsDifferentUnits then
      begin
        Pattern := FOwner.Blackboard.GetIndexedValue(eiWelaUnitPattern, CurrentEvent.CalledToGroup, i).AsString;
        SkinID := FOwner.Blackboard.GetIndexedValue(eiSkinIdentifier, CurrentEvent.CalledToGroup, i).AsString;
      end;
      if Pattern = '' then Pattern := Eventbus.Read(eiWelaUnitPattern, [], CurrentEvent.CalledToGroup).AsString;
      if SkinID = '' then SkinID := Eventbus.Read(eiSkinIdentifier, [], CurrentEvent.CalledToGroup).AsString;
      if SkinID = '' then SkinID := Owner.SkinID;

      assert(Pattern <> '', 'TWelaEffectFactoryComponent.Fire: Empty pattern in factory! Group ' + HRTTI.SetToString<SetComponentGroup>(ComponentGroup) + ' is empty!');
      if Pattern = '' then continue;
      TeamID := HGeneric.TertOp<integer>(FNewTeam >= 0, FNewTeam, Owner.TeamID);

      if Front.isZeroVector then Front := Map.Lanes.GetOrientationOfNextLane(Position, TeamID);

      SpawnedEntity := ServerGame.ServerEntityManager.SpawnUnit(
        Position,
        Front,
        Pattern,
        CardLeague,
        CardLevel,
        TeamID,
        Eventbus.Read(eiOwnerCommander, []).AsInteger,
        FOwner,
        procedure(SpawnedEntity : TEntity)
        begin
          if FPassTargets then
          begin
            SpawnedEntity.Eventbus.Write(eiWelaSavedTargets, [Targets.ToRParam]);
          end;
          // save target buildgrid, must be in setup, as the spawner can spawn directly after create
          if Target.IsBuildTarget then SpawnedEntity.Eventbus.Write(eiBuildgridOwner, [Target.GetBuildZone.ID]);
        end,
        procedure(PreprocessedEntity : TEntity)
        var
          x, y : integer;
        begin
          if FPassCardValues then
          begin
            PreprocessedEntity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardTimesPlayed), Owner.Balance(reCardTimesPlayed, CurrentEvent.CalledToGroup));
            PreprocessedEntity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reLevel), Owner.Balance(reLevel, CurrentEvent.CalledToGroup));
          end;

          PreprocessedEntity.SkinID := SkinID;
          PreprocessedEntity.Blackboard.SetValue(eiSkinIdentifier, [], SkinID);

          if Target.IsBuildTarget then
          begin
            // block gridfields
            setLength(BlockedFieldGrids, NeededGridSize.x * NeededGridSize.y);
            j := 0;
            for x := 0 to NeededGridSize.x - 1 do
              for y := 0 to NeededGridSize.y - 1 do
              begin
                TargetPos := Target.GetBuildZone.GetCenterOfField(Target.BuildGridCoordinate + RIntVector2.Create(x, y));
                BuildZone := Game.Map.BuildZones.GetBuildZoneByPosition(TargetPos);
                assert(assigned(BuildZone), 'TWelaEffectFactoryComponent.Fire: Invalid buildcoordinate passed to Server!');
                if not assigned(BuildZone) then continue;
                BlockedFieldGrids[j].a := BuildZone.ID;
                BlockedFieldGrids[j].b := BuildZone.PositionToCoord(TargetPos);
                GlobalEventbus.Write(eiSetGridFieldBlocking, [BlockedFieldGrids[j].a, BlockedFieldGrids[j].b, PreprocessedEntity.ID]);
                inc(j);
              end;
            // save blocked gridfields, for refunding
            PreprocessedEntity.Eventbus.Write(eiBuildgridBlockedFields, [RParam.FromArray < RTuple < integer, RIntVector2 >> (BlockedFieldGrids)]);
          end;
        end);

      if CurrentEvent.CalledToGroup <> [] then
          Eventbus.Trigger(eiWelaUnitProduced, [SpawnedEntity.ID], CurrentEvent.CalledToGroup);
      Eventbus.Trigger(eiWelaUnitProduced, [SpawnedEntity.ID]);
    end;
  end;
end;

function TWelaEffectFactoryComponent.IsSpawner : TWelaEffectFactoryComponent;
begin
  Result := self;
  FIsSpawner := True;
end;

function TWelaEffectFactoryComponent.PassCardValues : TWelaEffectFactoryComponent;
begin
  Result := self;
  FPassCardValues := True;
end;

function TWelaEffectFactoryComponent.PassTargets : TWelaEffectFactoryComponent;
begin
  Result := self;
  FPassTargets := True;
end;

function TWelaEffectFactoryComponent.SetSpawnedTeam(TeamID : integer) : TWelaEffectFactoryComponent;
begin
  Result := self;
  FNewTeam := TeamID;
end;

function TWelaEffectFactoryComponent.SpawnsDifferentUnits : TWelaEffectFactoryComponent;
begin
  Result := self;
  FSpawnsDifferentUnits := True;
end;

function TWelaEffectFactoryComponent.SpreadSpawns : TWelaEffectFactoryComponent;
begin
  Result := self;
  FUseAoE := True;
end;

function TWelaEffectFactoryComponent.SpreadSpawnsOnCircle : TWelaEffectFactoryComponent;
begin
  Result := self;
  FUseAoE := True;
  FAoECircle := True;
end;

{ TWelaLinkEffectComponent }

function TWelaLinkEffectComponent.OnBreak(LinkTarget : RParam) : boolean;
begin
  Result := True;
  BreakLink(LinkTarget.AsType<RTarget>);
end;

function TWelaLinkEffectComponent.OnEstablishLink(Source, Dest : RParam) : boolean;
begin
  Result := EstablishLink(Source.AsType<RTarget>, Dest.AsType<RTarget>);
end;

function TWelaLinkEffectComponent.OnExiled(Exiled : RParam) : boolean;
begin
  Result := True;
  if Exiled.AsBoolean then
      BreakAllLinks;
end;

function TWelaLinkEffectComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  BreakAllLinks;
end;

function TWelaLinkEffectComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  BreakAllLinks;
end;

procedure TWelaLinkEffectComponent.Fire(Targets : ATarget);
var
  i : integer;
begin
  for i := 0 to length(Targets) - 1 do
      Eventbus.Trigger(eiLinkEstablish, [RTarget.Create(FOwner), Targets[i]], ComponentGroup);
end;

function TWelaLinkEffectComponent.GetEfficiency(TargetsInRange : TList<RTarget>) : single;
begin
  Result := Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle;
end;

function TWelaLinkEffectComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
var
  IsPossible : boolean;
begin
  IsPossible := assigned(Entity) and not(upUntargetable in Entity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty>);
  if IsPossible then Result := 1
  else Result := -1;
end;

procedure TWelaLinkEffectComponent.BreakAllLinks;
var
  Link : RTarget;
begin
  for Link in FCurrentLinks.Keys do Eventbus.Trigger(eiLinkBreak, [Link], ComponentGroup);
end;

procedure TWelaLinkEffectComponent.BreakLink(LinkTarget : RTarget);
begin
  if FCurrentLinks.ContainsKey(LinkTarget) then
  begin
    GlobalEventbus.Trigger(eiDelayedKillEntity, [FCurrentLinks[LinkTarget]]);
    FCurrentLinks.Remove(LinkTarget);
    FLinkOrder.Remove(LinkTarget);
  end;
end;

constructor TWelaLinkEffectComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
var
  Comparer : IEqualityComparer<RTarget>;
begin
  inherited CreateGrouped(Owner, Group);
  Comparer := TEqualityComparer<RTarget>.Construct(
    (
    function(const Left, Right : RTarget) : boolean
    begin
      Result := Left = Right;
    end),
    (
    function(const L : RTarget) : integer
    begin
      Result := L.Hash;
    end));
  FCurrentLinks := TDictionary<RTarget, integer>.Create(Comparer);
  FLinkOrder := TList<RTarget>.Create;
end;

function TWelaLinkEffectComponent.CreatorGroup(Group : TArray<byte>) : TWelaLinkEffectComponent;
begin
  Result := self;
  FCreatorGroup := ByteArrayToComponentGroup(Group);
end;

destructor TWelaLinkEffectComponent.Destroy;
begin
  BreakAllLinks;
  FCurrentLinks.Free;
  FLinkOrder.Free;
  inherited;
end;

function TWelaLinkEffectComponent.EstablishLink(Source, Dest : RTarget) : boolean;
var
  Link : TEntity;
  TargetCount : RParam;
  SkinID : string;
begin
  if FCurrentLinks.ContainsKey(Dest) then exit(False);
  TargetCount := Eventbus.Read(eiWelaTargetCount, [], ComponentGroup);
  if not TargetCount.IsEmpty and (TargetCount.AsInteger > 0) and (TargetCount.AsInteger <= FLinkOrder.Count) then
  begin
    Eventbus.Trigger(eiLinkBreak, [FLinkOrder.First], ComponentGroup);
  end;
  SkinID := Owner.GetSkinID(ComponentGroup);
  Link := ServerGame.ServerEntityManager.SpawnUnit(
    RVector2.ZERO,
    RVector2.UNITY,
    Eventbus.Read(eiLinkPattern, [], ComponentGroup).AsString,
    CardLeague,
    CardLevel,
    Owner.TeamID,
    Eventbus.Read(eiOwnerCommander, []).AsInteger,
    FOwner,
    nil,
    procedure(PreprocessedEntity : TEntity)
    var
      UnitProperties : SetUnitProperty;
    begin
      UnitProperties := PreprocessedEntity.Blackboard.GetValue(eiUnitProperties, []).AsSetType<SetUnitProperty>;
      UnitProperties := UnitProperties + [upLink];
      PreprocessedEntity.Blackboard.SetValue(eiUnitProperties, [], RParam.From<SetUnitProperty>(UnitProperties));
      PreprocessedEntity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), self.CardLeague);
      PreprocessedEntity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), self.CardLevel);
      PreprocessedEntity.Eventbus.Write(eiLinkSource, [ATarget.Create(Source).ToRParam]);
      PreprocessedEntity.Eventbus.Write(eiLinkDest, [ATarget.Create(Dest).ToRParam]);
      PreprocessedEntity.Eventbus.Write(eiCreatorGroup, [RParam.From<SetComponentGroup>(FCreatorGroup)]);
      TLinkEventRedirecter.CreateGrouped(PreprocessedEntity, [ALLGROUP_INDEX], ComponentGroup);
      PreprocessedEntity.SkinID := SkinID;
      PreprocessedEntity.Blackboard.SetValue(eiSkinIdentifier, [], SkinID);
    end);
  Result := True;
  FCurrentLinks.Add(Dest, Link.ID);
  FLinkOrder.Add(Dest);
end;

{ TWelaTargetingRadialAttentionComponent }

function TWelaTargetingRadialAttentionComponent.DisableStraightPreference : TWelaTargetingRadialAttentionComponent;
begin
  Result := self;
  FDisableStraightPreference := True;
end;

procedure TWelaTargetingRadialAttentionComponent.UpdateTargets(CurrentList : TList<RTarget>);
const
  // extend lookrange with a factor to find a more likely target than the first one to walk to
  RANGE_EXTENSION_FACTOR : single = 1.2;
var
  Filter, targetTeamConstraint : RParam;
  MyPos : RVector2;
  AttentionRange : single;
  Enemies : TList<TEntity>;
  Enemy : TEntity;
  Lane : TLane;
begin
  CurrentList.Clear;
  Filter := RParam.FromProc<ProcEntityFilterFunction>(
    function(Entity : TEntity) : boolean
    begin
      Result := FetchEfficiency(Entity, ComponentGroup) >= 0;
    end);
  AttentionRange := Eventbus.Read(eiAttentionrange, [], ComponentGroup).AsSingle;
  targetTeamConstraint := RParam.From<EnumTargetTeamConstraint>(FTargetTeamConstraint);

  MyPos := Owner.Position;
  Enemies := GlobalEventbus.Read(eiEntitiesInRange, [
    MyPos,
    AttentionRange * RANGE_EXTENSION_FACTOR,
    Owner.TeamID,
    targetTeamConstraint,
    Filter]).AsType<TList<TEntity>>;
  if assigned(Enemies) then
  begin
    Lane := Eventbus.Read(eiGetLane, []).AsType<TLane>;
    if assigned(Lane) and not FDisableStraightPreference then
    begin
      // take lane into account to prefer enemies in lane direction
      // no lane => plain looking in direct surroundings
      Enemy := TAdvancedList<TEntity>(Enemies).Min(
        function(ent : TEntity) : single
        begin
          Result := Lane.GetWeightedDistance(MyPos, ent.Position);
        end);
      if assigned(Enemy) and (Enemy.Position.Distance(MyPos) > AttentionRange) then
          Enemy := nil;
    end
    else
    begin
      // no lane => plain looking in direct surroundings
      Enemy := TAdvancedList<TEntity>(Enemies).Min(
        function(ent : TEntity) : single
        begin
          Result := MyPos.Distance(ent.Position);
        end);
      if assigned(Enemy) and (Enemy.Position.Distance(MyPos) > AttentionRange) then
          Enemy := nil;
    end;

    // only if best target is in real attention range start to approach
    if assigned(Enemy) then
        CurrentList.Add(RTarget.Create(Enemy));
    Enemies.Free;
  end;
end;

function TWelaTargetingRadialAttentionComponent.ValidateTarget(Target : RTarget) : boolean;
var
  Efficiency, AttentionRange : single;
  EntityPos : RVector2;
begin
  Result := True;
  EntityPos := Owner.Position;
  Efficiency := FetchEfficiency(Target.GetTargetEntity, FValidateGroup);
  AttentionRange := Eventbus.Read(eiAttentionrange, [], ComponentGroup).AsSingle;
  if (Efficiency <= 0) or (Target.GetTargetPosition.Distance(EntityPos) > AttentionRange) then
  begin
    Result := False;
  end;
end;

{ TWelaTargetingRadialComponent }

function TWelaTargetingRadialComponent.Cone(Direction : RVector2; Angle : single) : TWelaTargetingRadialComponent;
begin
  Result := self;
  FConeDir := Direction;
  FCone := Angle;
end;

constructor TWelaTargetingRadialComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FRangeEvent := eiWelaRange;
end;

function TWelaTargetingRadialComponent.Cone(DirectionX, DirectionZ, Angle : single) : TWelaTargetingRadialComponent;
begin
  Result := Cone(RVector2.Create(DirectionX, DirectionZ), Angle);
end;

function TWelaTargetingRadialComponent.IgnoreOwnCollisionradius : TWelaTargetingRadialComponent;
begin
  Result := self;
  FIgnoreOwnCollisionradius := True;
end;

function TWelaTargetingRadialComponent.PrioritizeMiddleDistant : TWelaTargetingRadialComponent;
begin
  Result := self;
  FPrioritizeMiddleDistant := True;
end;

function TWelaTargetingRadialComponent.PrioritizeMostDistant : TWelaTargetingRadialComponent;
begin
  Result := self;
  FPrioritizeMostDistant := True;
end;

function TWelaTargetingRadialComponent.RangeFromEvent(EventIdentifier : EnumEventIdentifier) : TWelaTargetingRadialComponent;
begin
  Result := self;
  FRangeEvent := EventIdentifier;
end;

procedure TWelaTargetingRadialComponent.UpdateTargets(CurrentList : TList<RTarget>);
var
  BestTarget : RTarget;
  Filter : RParam;
  Enemies : TList<RTargetWithEfficiency>;
  PossibleTargets : TList<TEntity>;
  Entity : TEntity;
  Range : single;
  i, MaxTargets, MaxNew : integer;
  EntityPos : RVector2;
begin
  MaxTargets := Eventbus.Read(eiWelaTargetCount, [], ComponentGroup).AsIntegerDefault(1);
  if MaxTargets <= 0 then
      exit;
  if FMaxNewTargetCount <= 0 then
      MaxNew := 10000
  else
      MaxNew := FMaxNewTargetCount;
  if CurrentList.Count >= MaxTargets then exit;
  BestTarget := RTarget.CreateEmpty;
  EntityPos := Owner.Position;

  Filter := RParam.FromProc<ProcFilterFunction>(
    function(Entity : TEntity) : single
    var
      entityFront, entityPosition : RVector2;
      entityRadius, entityWidthAngle, angleBetween : single;
    begin
      Result := FetchEfficiency(Entity, ComponentGroup);
      if (Result >= 0) and (FCone > 0) then
      begin
        entityRadius := Entity.CollisionRadius;
        entityPosition := Entity.Position;
        entityFront := (entityPosition - EntityPos).Normalize;
        entityWidthAngle := arctan(entityRadius / Max(0.01, entityPosition.Distance(EntityPos)));
        angleBetween := FConeDir.InnerAngle(entityFront);
        if not(angleBetween - entityWidthAngle <= FCone / 2) then Result := -1;
        // Result := Result + 0.1 * (1 - angleBetween / PI)
      end;
    end);
  // Range = WeaponRange + OwnSize + OpponentSize
  Range := Eventbus.Read(FRangeEvent, [], ComponentGroup).AsSingle;
  if not FIgnoreOwnCollisionradius then
      Range := Range + Owner.CollisionRadius;

  Enemies := GlobalEventbus.Read(eiEnemiesInRangeEfficiency, [EntityPos, Range,
    Owner.TeamID, RParam.From<EnumTargetTeamConstraint>(FTargetTeamConstraint), Filter]).AsType<TList<RTargetWithEfficiency>>;

  if Enemies <> nil then
  begin
    if FPickRandom then
    begin
      PossibleTargets := TAdvancedList<RTargetWithEfficiency>(Enemies).Map<TEntity>(
        function(Target : RTargetWithEfficiency) : TEntity
        begin
          assert(Target.Target.IsEntity, 'TWelaTargetingRadialComponent.UpdateTargets: Random picks of non-entities not implemented yet!');
          Result := Target.Target.GetTargetEntity
        end);
      PickRandomTargets(CurrentList, PossibleTargets);
    end
    else
    begin
      // only prioritize if not all targets are taken anyway
      if MaxTargets < Enemies.Count then
          Enemies.Sort(TComparer<RTargetWithEfficiency>.Construct(
          function(const L, R : RTargetWithEfficiency) : integer
          begin
            // the higher the better
            Result := -sign(L.Efficiency - R.Efficiency);
            if Result = 0 then
            begin
              if upLowPrio in L.Target.GetTargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then inc(Result);
              if upLowPrio in R.Target.GetTargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then dec(Result);
              if Result = 0 then
              begin
                if FPrioritizeMiddleDistant then
                begin
                  // prefer unit nearest to half range
                  Result := sign(abs(L.Target.GetTargetPosition.Distance(EntityPos) - Range / 2) - abs(R.Target.GetTargetPosition.Distance(EntityPos) - Range / 2));
                end
                else
                begin
                  // the lower the better
                  Result := sign(L.Target.GetTargetPosition.DistanceSq(EntityPos) - R.Target.GetTargetPosition.DistanceSq(EntityPos));
                  if FPrioritizeMostDistant then Result := -Result;
                end;
              end;
            end;
          end));
      i := 0;
      while (i < Enemies.Count) and (CurrentList.Count < MaxTargets) and (MaxNew > 0) do
      begin
        if not CurrentList.Contains(Enemies[i].Target) then
        begin
          CurrentList.Add(Enemies[i].Target);
          if Enemies[i].Target.TryGetTargetEntity(Entity) then
              Entity.Eventbus.Trigger(eiWelaYoureMyTarget, [FOwner]);
          dec(MaxNew);
        end;
        inc(i);
      end;
    end;
    Enemies.Free;
  end;
end;

function TWelaTargetingRadialComponent.ValidateTarget(Target : RTarget) : boolean;
var
  Efficiency, Weaponrange, Distance : single;
  EntityPos, TargetPos : RVector2;
begin
  Result := False;
  EntityPos := Owner.Position;
  Efficiency := FetchEfficiency(Target.GetTargetEntity, FValidateGroup);
  if (Efficiency >= 0) then
  begin
    Weaponrange := Eventbus.Read(FRangeEvent, [], ComponentGroup).AsSingle;
    if not FIgnoreOwnCollisionradius then
        Weaponrange := Weaponrange + Owner.CollisionRadius;
    if Target.IsEntity then Weaponrange := Weaponrange + Target.GetTargetEntity.CollisionRadius;
    TargetPos := Target.GetTargetPosition;
    Distance := TargetPos.Distance(EntityPos);
    if (Distance <= Weaponrange) then
        Result := True;
  end;
end;

{ TWelaEffectProjectileComponent }

procedure TWelaEffectProjectileComponent.Fire(Targets : ATarget);
var
  i, ii, Count : integer;
  Target : RTarget;
  StartingEntity : TEntity;
  LinkTarget : ATarget;
  Position : RVector2;
  Value : RParam;
  SkinID : string;
begin
  if FMultipleProjectiles then
      Count := Eventbus.Read(eiWelaCount, [], ComponentGroup).AsIntegerDefault(1)
  else
      Count := 1;
  if Count > 0 then
  begin
    for i := 0 to length(Targets) - 1 do
    begin
      Target := Targets[i];
      if FIsLinkEffect then
      begin
        if FReverseLink then LinkTarget := Eventbus.Read(eiLinkDest, []).AsATarget
        else LinkTarget := Eventbus.Read(eiLinkSource, []).AsATarget;
        assert((LinkTarget.Count = 1) and LinkTarget[0].IsEntity);
        if not LinkTarget[0].TryGetTargetEntity(StartingEntity) then StartingEntity := Owner;
      end
      else StartingEntity := Owner;
      if FReverse then Position := Target.GetTargetPosition
      else
      begin
        // if a commander shoots a projectile, there is no starting position, so use from target
        Position := StartingEntity.Position;
        if Position.isZeroVector then Position := Target.GetTargetPosition;
      end;

      SkinID := Owner.GetSkinID(ComponentGroup);
      for ii := 0 to Count - 1 do
      begin
        ServerGame.ServerEntityManager.SpawnUnit(
          Position,
          Owner.Front,
          Eventbus.Read(eiWelaUnitPattern, [], ComponentGroup).AsString,
          CardLeague,
          CardLevel,
          Owner.TeamID,
          Eventbus.Read(eiOwnerCommander, []).AsInteger,
          FOwner,
          nil,
          procedure(PreprocessedEntity : TEntity)
          var
            UnitProperties : SetUnitProperty;
          begin
            TProjectileEventRedirecter.Create(PreprocessedEntity);
            UnitProperties := PreprocessedEntity.Blackboard.GetValue(eiUnitProperties, []).AsSetType<SetUnitProperty>;
            UnitProperties := UnitProperties + [upProjectile];
            PreprocessedEntity.Blackboard.SetValue(eiUnitProperties, [], RParam.From<SetUnitProperty>(UnitProperties));

            Value := Eventbus.Read(eiWeladamage, [], ComponentGroup);
            if not Value.IsEmpty then PreprocessedEntity.Blackboard.SetValue(eiWeladamage, [0], Value);
            Value := Eventbus.Read(eiWelaSplashfactor, [], ComponentGroup);
            if not Value.IsEmpty then PreprocessedEntity.Blackboard.SetValue(eiWelaSplashfactor, [0], Value);
            Value := Eventbus.Read(eiWelaAreaOfEffect, [], ComponentGroup);
            if not Value.IsEmpty then PreprocessedEntity.Blackboard.SetValue(eiWelaAreaOfEffect, [0], Value);
            Value := Eventbus.Read(eiDamageType, [], ComponentGroup);
            if not Value.IsEmpty then PreprocessedEntity.Blackboard.SetValue(eiDamageType, [0], Value);
            Value := Eventbus.Read(eiWelaTargetCount, [], ComponentGroup);
            if not Value.IsEmpty then PreprocessedEntity.Blackboard.SetValue(eiWelaTargetCount, [0], Value);
            Value := Eventbus.Read(eiWelaCount, [], ComponentGroup);
            if not Value.IsEmpty then PreprocessedEntity.Blackboard.SetValue(eiWelaCount, [0], Value);

            if FReverse then PreprocessedEntity.Blackboard.SetValue(eiWelaSavedTargets, [], ATarget.Create(StartingEntity).ToRParam)
            else PreprocessedEntity.Blackboard.SetValue(eiWelaSavedTargets, [], ATarget.Create(Target).ToRParam);

            PreprocessedEntity.SkinID := SkinID;
            PreprocessedEntity.Blackboard.SetValue(eiSkinIdentifier, [], SkinID);
          end,
          procedure(Entity : TEntity)
          begin
            Eventbus.Trigger(eiWelaShotProjectile, [Entity], ComponentGroup);
            if ComponentGroup <> [] then Eventbus.Trigger(eiWelaShotProjectile, [Entity]);
          end,
          '');
      end;
    end;
  end;
end;

function TWelaEffectProjectileComponent.GetEfficiency(TargetsInRange : TList<RTarget>) : single;
begin
  Result := Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle;
end;

function TWelaEffectProjectileComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
var
  IsPossible : boolean;
begin
  IsPossible := not(upUntargetable in Entity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty>);
  if IsPossible then Result := 1
  else Result := -1;
end;

function TWelaEffectProjectileComponent.IsLinkEffect : TWelaEffectProjectileComponent;
begin
  Result := self;
  FIsLinkEffect := True;
end;

function TWelaEffectProjectileComponent.MultipleProjectiles : TWelaEffectProjectileComponent;
begin
  Result := self;
  FMultipleProjectiles := True;
end;

function TWelaEffectProjectileComponent.Reverse : TWelaEffectProjectileComponent;
begin
  Result := self;
  FReverse := True;
end;

function TWelaEffectProjectileComponent.ReverseLink : TWelaEffectProjectileComponent;
begin
  Result := self;
  FReverseLink := True;
end;

{ TWelaEffectPayCostComponent }

function TWelaEffectPayCostComponent.ConsumesAll : TWelaEffectPayCostComponent;
begin
  Result := self;
  FConsumesAll := True;
end;

constructor TWelaEffectPayCostComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FPayingGroup := TDictionary<EnumResource, SetComponentGroup>.Create;
  FDefaultPayingGroup := ComponentGroup;
  FResourceConversion := TDictionary<EnumResource, EnumResource>.Create;
end;

destructor TWelaEffectPayCostComponent.Destroy;
begin
  FPayingGroup.Free;
  FResourceConversion.Free;
  inherited;
end;

procedure TWelaEffectPayCostComponent.Fire(Targets : ATarget);
var
  Cost : AResourceCost;
  i : RResourceCost;
  Amount : RParam;
  PayingEntity : TEntity;
  ConvertedTo : EnumResource;
begin
  Cost := Eventbus.Read(eiResourceCost, [], CurrentEvent.CalledToGroup).AsAResourceCost;
  assert(assigned(Cost), 'TWelaEffectPayCostComponent: Found paying component, but no cost! Added TResourceManagerComponent to calling entity?');
  if assigned(Cost) then
  begin
    if FRedirectToCommander then PayingEntity := Game.EntityManager.GetOwningCommander(Owner)
    else PayingEntity := Owner;

    assert(assigned(PayingEntity), 'TWelaEffectPayCostComponent.Fire: Could not find payer, should never happen!');
    if assigned(PayingEntity) then
    begin
      for i in Cost do
        if not(i.ResourceType in NOT_PAYED_RESOURCES) then
        begin
          // if consuming all, ignore amount and take whole balance
          if FConsumesAll then Amount := PayingEntity.Eventbus.Read(eiResourceBalance, [ord(i.ResourceType)], GetPayingGroup(i.ResourceType))
          else Amount := i.Amount;
          // pay
          PayingEntity.Eventbus.Trigger(eiResourceSubtraction, [ord(i.ResourceType), Amount], GetPayingGroup(i.ResourceType));
          // refund resources optionally
          if FResourceConversion.TryGetValue(i.ResourceType, ConvertedTo) then
              PayingEntity.Eventbus.Trigger(eiResourceTransaction, [ord(ConvertedTo), Amount], GetPayingGroup(i.ResourceType));
        end;
    end;
  end;
end;

function TWelaEffectPayCostComponent.GetPayingGroup(ResType : EnumResource) : SetComponentGroup;
begin
  if not FPayingGroup.TryGetValue(ResType, Result) then
      Result := FDefaultPayingGroup;
end;

function TWelaEffectPayCostComponent.ConvertResource(FromResource, ToResource : EnumResource) : TWelaEffectPayCostComponent;
begin
  Result := self;
  FResourceConversion.AddOrSetValue(FromResource, ToResource);
end;

function TWelaEffectPayCostComponent.SetPayingGroup(Group : TArray<byte>) : TWelaEffectPayCostComponent;
begin
  Result := self;
  FDefaultPayingGroup := ByteArrayToComponentGroup(Group);
end;

function TWelaEffectPayCostComponent.SetPayingGroupForType(ResourceType : integer; Group : TArray<byte>) : TWelaEffectPayCostComponent;
begin
  Result := self;
  FPayingGroup.AddOrSetValue(EnumResource(ResourceType), ByteArrayToComponentGroup(Group));
end;

function TWelaEffectPayCostComponent.CommanderPays() : TWelaEffectPayCostComponent;
begin
  Result := self;
  FDefaultPayingGroup := [];
  FRedirectToCommander := True;
end;

{ TWelaEffectSuicideComponent }

function TWelaEffectSuicideComponent.DontFree : TWelaEffectSuicideComponent;
begin
  Result := self;
  FDontFree := True;
end;

procedure TWelaEffectSuicideComponent.Fire(Targets : ATarget);
begin
  inherited;
  Eventbus.Trigger(eiDie, [-1, -1]);
  if not(FDontFree or Eventbus.Read(eiIsAlive, []).AsBoolean) then GlobalEventbus.Trigger(eiDelayedKillEntity, [FOwner.ID]);
end;

function TWelaEffectSuicideComponent.OnBeforeDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := not FPreventDeath;
end;

function TWelaEffectSuicideComponent.PreventDeath : TWelaEffectSuicideComponent;
begin
  Result := self;
  FPreventDeath := True;
end;

{ TWelaLinkEffectUnitPropertyComponent }

constructor TWelaLinkEffectUnitPropertyComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; GivenUnitProperty : EnumUnitProperty);
begin
  inherited CreateGrouped(Owner, Group);
  FGivenUnitProperty := GivenUnitProperty;
end;

function TWelaLinkEffectUnitPropertyComponent.OnBreak(LinkTarget : RParam) : boolean;
var
  Target : RTarget;
  TargetUnitProperties : SetUnitProperty;
  TargetEntity : TEntity;
begin
  Result := True;
  Target := LinkTarget.AsType<RTarget>;
  if Target.IsEntity then
  begin
    TargetEntity := Target.GetTargetEntity;
    if assigned(TargetEntity) then
    begin
      // get/set value direct in blackboard, as we don't want to save temporary properties introduced by components as permanent
      TargetUnitProperties := TargetEntity.Blackboard.GetValue(eiUnitProperties, []).AsSetType<SetUnitProperty>;
      TargetUnitProperties := TargetUnitProperties - [FGivenUnitProperty];
      TargetEntity.Blackboard.SetValue(eiUnitProperties, [], RParam.From<SetUnitProperty>(TargetUnitProperties));
    end;
  end;
end;

function TWelaLinkEffectUnitPropertyComponent.OnEstablishLink(Source, Dest : RParam) : boolean;
var
  Target : RTarget;
  TargetUnitProperties : SetUnitProperty;
  TargetEntity : TEntity;
begin
  Result := True;
  Target := Dest.AsType<RTarget>;
  if Target.IsEntity then
  begin
    TargetEntity := Target.GetTargetEntity;
    if assigned(TargetEntity) then
    begin
      // get/set value direct in blackboard, as we don't want to save temporary properties introduced by components as permanent
      TargetUnitProperties := TargetEntity.Blackboard.GetValue(eiUnitProperties, []).AsSetType<SetUnitProperty>;
      TargetUnitProperties := TargetUnitProperties + [FGivenUnitProperty];
      TargetEntity.Blackboard.SetValue(eiUnitProperties, [], RParam.From<SetUnitProperty>(TargetUnitProperties));
    end;
  end;
end;

{ TWelaTargetingRectangleComponent }

procedure TWelaTargetingRectangleComponent.UpdateRectangle;
begin
  FRectangle.Position := Owner.Position;
  FRectangle.Front := Owner.Front;
  FRectangle.Height := Eventbus.Read(eiWelaRange, [], ComponentGroup).AsSingle;
  FRectangle.Position := FRectangle.Position + (FRectangle.Front * FOffset.y) + (FRectangle.Left * FOffset.x);
  FRectangle.Width := FRectangle.Height * FRatio;
end;

constructor TWelaTargetingRectangleComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FRatio := 1;
end;

function TWelaTargetingRectangleComponent.SetOffset(OffsetLeft, OffsetFront : single) : TWelaTargetingRectangleComponent;
begin
  Result := self;
  FOffset := RVector2.Create(OffsetLeft, OffsetFront);
end;

function TWelaTargetingRectangleComponent.SetWidthRatio(WidthRatio : single) : TWelaTargetingRectangleComponent;
begin
  Result := self;
  FRatio := WidthRatio;
end;

procedure TWelaTargetingRectangleComponent.UpdateTargets(CurrentList : TList<RTarget>);
var
  BestTarget : RTarget;
  Filter : RParam;
  Enemies : TList<RTargetWithEfficiency>;
  i, MaxTargets : integer;
  RectCoarseBounding : RCircle;
  entityPosition : RVector2;
begin
  MaxTargets := Max(1, Eventbus.Read(eiWelaTargetCount, [], ComponentGroup).AsInteger);
  assert(CurrentList.Count <= MaxTargets, 'Dynamic targetcount could be a problem. Not implemented yet.');
  if CurrentList.Count >= MaxTargets then exit;
  BestTarget := RTarget.CreateEmpty;

  // Coarse intersection test with circle because quadtree only handle circles
  entityPosition := Owner.Position;
  UpdateRectangle;
  RectCoarseBounding := FRectangle.ToWrappingCircle;

  // fine intersection per unit
  Filter := RParam.FromProc<ProcFilterFunction>(
    function(Target : TEntity) : single
    var
      TargetBounding : RCircle;
    begin
      TargetBounding.Center := Target.Position;
      TargetBounding.Radius := Target.CollisionRadius;
      if not FRectangle.IntersectsCircle(TargetBounding) then Result := -1
      else Result := FetchEfficiency(Target, ComponentGroup);
    end);

  Enemies := GlobalEventbus.Read(eiEnemiesInRangeEfficiency, [RectCoarseBounding.Center, RectCoarseBounding.Radius,
    Owner.TeamID, RParam.From<EnumTargetTeamConstraint>(FTargetTeamConstraint), Filter]).AsType<TList<RTargetWithEfficiency>>;

  if Enemies <> nil then
  begin
    Enemies.Sort(TComparer<RTargetWithEfficiency>.Construct(
      function(const L, R : RTargetWithEfficiency) : integer
      begin
        Result := sign(L.Efficiency - R.Efficiency);
        if Result = 0 then
        begin
          if upLowPrio in L.Target.GetTargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then inc(Result);
          if upLowPrio in R.Target.GetTargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then dec(Result);
          if Result = 0 then
          begin
            Result := sign(L.Target.GetTargetPosition.DistanceSq(entityPosition) - R.Target.GetTargetPosition.DistanceSq(entityPosition));
          end;
        end;
      end));
    i := 0;
    while (i < Enemies.Count) and (CurrentList.Count < MaxTargets) do
    begin
      if not CurrentList.Contains(Enemies[i].Target) then
      begin
        CurrentList.Add(Enemies[i].Target);
        Enemies[i].Target.GetTargetEntity.Eventbus.Trigger(eiWelaYoureMyTarget, [FOwner]);
      end;
      inc(i);
    end;
    Enemies.Free;
  end;
end;

function TWelaTargetingRectangleComponent.ValidateTarget(Target : RTarget) : boolean;
var
  Efficiency : single;
  TargetCircle : RCircle;
begin
  Result := False;
  Efficiency := FetchEfficiency(Target.GetTargetEntity, FValidateGroup);
  if (Efficiency > 0) then
  begin
    UpdateRectangle;
    if Target.IsEntity then TargetCircle := RCircle.Create(Target.GetTargetPosition, Target.GetTargetEntity.CollisionRadius)
    else TargetCircle := RCircle.Create(Target.GetTargetPosition, 0);

    Result := FRectangle.IntersectsCircle(TargetCircle);
  end;
end;

{ TWelaEffectInheritEventValueComponent }

constructor TWelaEffectInheritEventValueComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; EventToWrite : EnumEventIdentifier);
begin
  inherited CreateGrouped(Owner, Group);
  FEvent := EventToWrite;
end;

function TWelaEffectInheritEventValueComponent.OnWelaUnitProduced(EntityID : RParam) : boolean;
var
  Prod : TEntity;
begin
  Result := True;
  if CurrentEvent.CalledToGroup <> ComponentGroup then exit;
  Prod := Game.EntityManager.GetEntityByID(EntityID.AsInteger);
  assert(assigned(Prod));
  if assigned(Prod) then
  begin
    Prod.Eventbus.Write(FEvent, [Eventbus.Read(FEvent, [], ComponentGroup)], FTargetGroup);
  end;
end;

function TWelaEffectInheritEventValueComponent.TargetGroup(Group : TArray<byte>) : TWelaEffectInheritEventValueComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaEffectLinkPayCostMyselfComponentServer }

procedure TWelaEffectLinkPayCostMyselfComponentServer.ApplyResources;
var
  LastedTime, CurrentTime : Int64;
begin
  // no links no resource is used
  if FLinkCount > 0 then
  begin
    CurrentTime := GameTimeManager.GetTimestamp;
    LastedTime := CurrentTime - FLastAppliedTimestamp;
    Pay(LastedTime div 1000);
    FLastAppliedTimestamp := CurrentTime - (LastedTime mod 1000);
  end;
end;

function TWelaEffectLinkPayCostMyselfComponentServer.FireOnEmpty(TargetGroup : TArray<byte>) : TWelaEffectLinkPayCostMyselfComponentServer;
begin
  Result := self;
  FOnEmptyTargetGroup := ByteArrayToComponentGroup(TargetGroup);
end;

function TWelaEffectLinkPayCostMyselfComponentServer.OnLinkBreak(Target : RParam) : boolean;
begin
  Result := True;
  // if last link is going to be broken, refresh resource consumption, to be adequate
  if FLinkCount = 1 then ApplyResources;
  dec(FLinkCount);
end;

function TWelaEffectLinkPayCostMyselfComponentServer.OnLinkEstablish(Source, Dest : RParam) : boolean;
begin
  Result := True;
  if FLinkCount <= 0 then
  begin
    FLinkCount := 1;
    FLastAppliedTimestamp := GameTimeManager.GetTimestamp;
    // links cost initial for building
    Pay(1);
  end
  else inc(FLinkCount);
end;

function TWelaEffectLinkPayCostMyselfComponentServer.OnThink : boolean;
begin
  Result := True;
  ApplyResources;
end;

procedure TWelaEffectLinkPayCostMyselfComponentServer.Pay(Times : integer);
var
  CostToPay : RParam;
  Cost : AResourceCost;
  i : RResourceCost;
  WasDepleted, IsDepleted, HasBeenDepleted : boolean;
  Balance : RParam;
begin
  Cost := Eventbus.Read(eiResourceCost, [], ComponentGroup).AsAResourceCost;
  if assigned(Cost) then
  begin
    HasBeenDepleted := False;
    for i in Cost do
    begin
      if i.ResourceType in RES_FLOAT_RESOURCES then
          CostToPay := -i.Amount.AsSingle * Times
      else
          CostToPay := -i.Amount.AsInteger * Times;

      Balance := Owner.Balance(i.ResourceType, GetPayingGroup(i.ResourceType));
      WasDepleted := ResourceCompare(i.ResourceType, Balance, coLowerEqual, 0);

      Eventbus.Trigger(eiResourceTransaction, [ord(i.ResourceType), CostToPay], GetPayingGroup(i.ResourceType));

      Balance := Owner.Balance(i.ResourceType, GetPayingGroup(i.ResourceType));
      IsDepleted := ResourceCompare(i.ResourceType, Balance, coLowerEqual, 0);
      if not WasDepleted and IsDepleted then HasBeenDepleted := True;
    end;
    if HasBeenDepleted and (FOnEmptyTargetGroup <> []) then
        Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], FOnEmptyTargetGroup);
  end;
end;

{ TLinkEffectDamageRedirectionComponent }

function TLinkEffectDamageRedirectionComponent.DestinationToSource : TLinkEffectDamageRedirectionComponent;
begin
  Result := self;
  FRedirectFromDestination := True;
end;

function TLinkEffectDamageRedirectionComponent.GetDestination : ATarget;
begin
  if FRedirectFromDestination then Result := Eventbus.Read(eiLinkSource, []).AsATarget
  else Result := Eventbus.Read(eiLinkDest, []).AsATarget;
end;

function TLinkEffectDamageRedirectionComponent.GetSource : ATarget;
begin
  if FRedirectFromDestination then Result := Eventbus.Read(eiLinkDest, []).AsATarget
  else Result := Eventbus.Read(eiLinkSource, []).AsATarget;
end;

function TLinkEffectDamageRedirectionComponent.OnAfterCreate : boolean;
var
  Source : ATarget;
  Entity : TEntity;
begin
  Result := True;
  Source := GetSource;
  if not Source.HasIndex(0) then
      MakeException('OnAfterCreate: No source found!');
  if Source[0].TryGetTargetEntity(Entity) then
      Entity.Eventbus.SubscribeRemote(eiTakeDamage, etRead, epHigher, self, 'TargetTakeDamage', 3);
end;

function TLinkEffectDamageRedirectionComponent.TargetTakeDamage(var Amount : RParam; DamageType, InflictorID : RParam) : RParam;
var
  RealDamageType, NewDamageType : SetDamageType;
  Factor : single;
  Dest : TEntity;
  Targets : ATarget;
  Target : RTarget;
begin
  RealDamageType := DamageType.AsType<SetDamageType>;
  Targets := GetDestination;
  if not Targets.HasIndex(0) then
      MakeException('TargetTakeDamage: No destinations set!');
  Target := Targets[0];
  if not(dtIrredirectable in RealDamageType) and Target.TryGetTargetEntity(Dest) then
  begin
    Factor := Eventbus.Read(eiWelaModifier, [], ComponentGroup).AsSingleDefault(1.0);
    NewDamageType := RealDamageType + [dtIrredirectable, dtRedirected];
    // redirect percentage of damage to destination
    Result := Dest.Eventbus.Read(eiTakeDamage, [Amount.AsSingle * Factor, RParam.From<SetDamageType>(NewDamageType), InflictorID]);
    // pass all not redirected damage
    Amount := Amount.AsSingle * (1 - Factor);
  end
  else Result := Amount;
end;

{ TLinkEffectFireAtProducedUnitsComponent }

function TLinkEffectFireAtProducedUnitsComponent.OnAfterCreate : boolean;
var
  Targets : ATarget;
  Dest : RTarget;
  Entity : TEntity;
begin
  Result := True;
  Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
  if not Targets.HasIndex(0) then
      MakeException('TargetTakeDamage: No destinations set!');
  Dest := Targets[0];
  if Dest.TryGetTargetEntity(Entity) then
      Entity.Eventbus.SubscribeRemote(eiWelaUnitProduced, etTrigger, epLast, self, 'TargetProducesUnit', 1);
end;

function TLinkEffectFireAtProducedUnitsComponent.TargetProducesUnit(EntityID : RParam) : boolean;
begin
  Result := True;
  Eventbus.Trigger(eiFire, [ATarget.Create(EntityID.AsInteger).ToRParam], ComponentGroup);
end;

{ TWelaReadyNthComponent }

function TWelaReadyNthComponent.Counter(Counter : integer) : TWelaReadyNthComponent;
begin
  Result := self;
  FCounter := Counter;
end;

function TWelaReadyNthComponent.Invert : TWelaReadyNthComponent;
begin
  Result := self;
  FInvert := True;
end;

function TWelaReadyNthComponent.IsReady : boolean;
begin
  inc(FCounter);
  Result := True;
  if FNth > 0 then
  begin
    if FInvert then
        Result := Result and ((FCounter mod FNth) <> 0)
    else
        Result := Result and ((FCounter mod FNth) = 0);
  end;
  if FTimes > 0 then
      Result := Result and (FCounter <= FTimes);
end;

function TWelaReadyNthComponent.Nth(Nth : integer) : TWelaReadyNthComponent;
begin
  Result := self;
  FNth := Nth;
end;

function TWelaReadyNthComponent.Times(Times : integer) : TWelaReadyNthComponent;
begin
  Result := self;
  FTimes := Times;
end;

{ TWelaReadyEachNthGameTickComponent }

constructor TWelaReadyEachNthGameTickComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FN := 60;
end;

function TWelaReadyEachNthGameTickComponent.IsReady : boolean;
begin
  Result := (FTicks mod FN = 0) and (FStartsReady or (FTicks <> 0));
end;

function TWelaReadyEachNthGameTickComponent.OnGameTick : boolean;
begin
  Result := True;
  inc(FTicks);
end;

function TWelaReadyEachNthGameTickComponent.SetN(n : integer) : TWelaReadyEachNthGameTickComponent;
begin
  Result := self;
  FN := n;
end;

function TWelaReadyEachNthGameTickComponent.StartsReady : TWelaReadyEachNthGameTickComponent;
begin
  Result := self;
  FStartsReady := True;
end;

{ TWelaTargetingGlobalComponent }

function TWelaTargetingGlobalComponent.DisableEfficiencyCheck : TWelaTargetingGlobalComponent;
begin
  Result := self;
  FDisableEfficiency := True;
end;

procedure TWelaTargetingGlobalComponent.UpdateTargets(CurrentList : TList<RTarget>);
var
  BestTarget : RTarget;
  Filter : RParam;
  Enemies : TList<RTargetWithEfficiency>;
  EnemiesWithoutEfficiency : TList<TEntity>;
  Range : single;
  i, MaxTargets : integer;
  EntityPos : RVector2;
begin
  MaxTargets := Max(1, Eventbus.Read(eiWelaTargetCount, [], ComponentGroup).AsInteger);
  assert(CurrentList.Count <= MaxTargets, 'Dynamic targetcount could be a problem. Not implemented yet.');
  if CurrentList.Count >= MaxTargets then exit;
  BestTarget := RTarget.CreateEmpty;

  Range := 100000.0; // global
  EntityPos := Owner.Position;

  if FDisableEfficiency or FPickRandom then
  begin
    Filter := RParam.FromProc<ProcEntityFilterFunction>(
      function(Target : TEntity) : boolean
      begin
        Result := IsTargetPossible(Target, ComponentGroup);
      end);
    EnemiesWithoutEfficiency := GlobalEventbus.Read(eiEntitiesInRange, [EntityPos, Range,
      Owner.TeamID, RParam.From<EnumTargetTeamConstraint>(FTargetTeamConstraint), Filter]).AsType<TList<TEntity>>;

    PickRandomTargets(CurrentList, EnemiesWithoutEfficiency);
  end
  else
  begin
    Filter := RParam.FromProc<ProcFilterFunction>(
      function(Target : TEntity) : single
      begin
        Result := FetchEfficiency(Target, ComponentGroup);
      end);
    Enemies := GlobalEventbus.Read(eiEnemiesInRangeEfficiency, [EntityPos, Range,
      Owner.TeamID, RParam.From<EnumTargetTeamConstraint>(FTargetTeamConstraint), Filter]).AsType<TList<RTargetWithEfficiency>>;

    if Enemies <> nil then
    begin
      Enemies.Sort(TComparer<RTargetWithEfficiency>.Construct(
        function(const L, R : RTargetWithEfficiency) : integer
        begin
          Result := sign(L.Efficiency - R.Efficiency);
          if Result = 0 then
          begin
            if upLowPrio in L.Target.GetTargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then inc(Result);
            if upLowPrio in R.Target.GetTargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then dec(Result);
            if Result = 0 then
            begin
              Result := sign(L.Target.GetTargetPosition.DistanceSq(EntityPos) - R.Target.GetTargetPosition.DistanceSq(EntityPos));
            end;
          end;
        end));
      i := 0;
      while (i < Enemies.Count) and (CurrentList.Count < MaxTargets) do
      begin
        if not CurrentList.Contains(Enemies[i].Target) then
        begin
          CurrentList.Add(Enemies[i].Target);
          Enemies[i].Target.GetTargetEntity.Eventbus.Trigger(eiWelaYoureMyTarget, [FOwner]);
        end;
        inc(i);
      end;
      Enemies.Free;
    end;
  end;
end;

function TWelaTargetingGlobalComponent.ValidateTarget(Target : RTarget) : boolean;
var
  Efficiency, Weaponrange : single;
  EntityPos : RVector2;
begin
  Result := False;
  EntityPos := Owner.Position;
  Efficiency := FetchEfficiency(Target.GetTargetEntity, FValidateGroup);
  if (Efficiency > 0) then
  begin
    Weaponrange := Eventbus.Read(eiWelaRange, [], ComponentGroup).AsSingle + Owner.CollisionRadius;
    if Target.IsEntity then Weaponrange := Weaponrange + Target.GetTargetEntity.CollisionRadius;
    if (Target.GetTargetPosition.Distance(EntityPos) <= Weaponrange) then
    begin
      Result := True;
    end;
  end;
end;

{ TModifierMultiplyDealtDamageComponent }

function TModifierMultiplyDealtDamageComponent.CheckWelaConstraint : TModifierMultiplyDealtDamageComponent;
begin
  Result := self;
  FCheckWelaConstraint := True;
end;

function TModifierMultiplyDealtDamageComponent.MustHave(DamageTypes : TArray<byte>) : TModifierMultiplyDealtDamageComponent;
begin
  Result := self;
  FMustHave := ByteArrayToSetDamageType(DamageTypes);
end;

function TModifierMultiplyDealtDamageComponent.MustNotHave(DamageTypes : TArray<byte>) : TModifierMultiplyDealtDamageComponent;
begin
  Result := self;
  FMustNotHave := ByteArrayToSetDamageType(DamageTypes);
end;

function TModifierMultiplyDealtDamageComponent.OnWillDealDamage(Amount, DamageTypes, TargetEntity : RParam; Previous : RParam) : RParam;
var
  Multiplier, RealAmount : single;
  Chance : RParam;
  RealDamageTypes : SetDamageType;
begin
  RealDamageTypes := DamageTypes.AsType<SetDamageType>;
  if Previous.IsEmpty then RealAmount := Amount.AsSingle
  else RealAmount := Previous.AsSingle;
  Chance := Eventbus.Read(eiWelaChance, [], FValueGroup);
  Multiplier := Eventbus.Read(eiWelaModifier, [], FValueGroup).AsSingle;
  if (Chance.IsEmpty or (random <= Chance.AsSingle)) and
    ((FMustHave = []) or (FMustHave <= RealDamageTypes)) and
    (FMustNotHave * RealDamageTypes = []) and
    (not FCheckWelaConstraint or Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(TargetEntity.AsType<TEntity>).ToRParam], FValueGroup).AsRTargetValidity.IsValid) then
  begin
    Result := RealAmount * Multiplier;
    Eventbus.Trigger(eiFire, [ATarget.Create(TargetEntity.AsType<TEntity>).ToRParam], FValueGroup);
  end
  else Result := RealAmount;
end;

{ TProjectileEventRedirecter }

function TProjectileEventRedirecter.GetCreator : TEntity;
begin
  Result := Game.EntityManager.GetEntityByID(Eventbus.Read(eiCreator, []).AsInteger);
end;

function TProjectileEventRedirecter.GetCreatorScriptFileName : string;
begin
  Result := Eventbus.Read(eiCreatorScriptFileName, []).AsString;
end;

function TProjectileEventRedirecter.OnDoneDamage(Amount, DamageType, TargetEntity : RParam) : boolean;
var
  Creator : TEntity;
begin
  Result := True;
  Creator := GetCreator;
  if assigned(Creator) then
      Creator.Eventbus.Trigger(eiDamageDone, [Amount, DamageType, TargetEntity]);
end;

function TProjectileEventRedirecter.OnWillDealDamage(Amount, DamageTypes, TargetEntity, Previous : RParam) : RParam;
var
  Creator : TEntity;
  temp : RParam;
begin
  Result := Previous;
  Creator := GetCreator;
  if assigned(Creator) then
  begin
    temp := Creator.Eventbus.Read(eiWillDealDamage, [Amount, DamageTypes, TargetEntity]);
    if not temp.IsEmpty then Result := temp;
  end;
end;

function TProjectileEventRedirecter.OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
var
  Creator : TEntity;
begin
  Result := True;
  Creator := GetCreator;
  if assigned(Creator) then
      Creator.Eventbus.Trigger(eiYouHaveKilledMeShameOnYou, [KilledUnitID])
  else
    // creator is already dead, so we have to count statistic here manually
    if assigned(ServerGame) then ServerGame.Statistics.UnitKills(Owner.CommanderID, GetCreatorScriptFileName);
end;

{ TWelaEffectActivationAbilityComponent }

function TWelaEffectActivationAbilityComponent.CheckNotFull(ResType : integer) : TWelaEffectActivationAbilityComponent;
begin
  Result := self;
  FOnCap := True;
  FResType := ResType;
  FInvertOnCap := True;
end;

constructor TWelaEffectActivationAbilityComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FActivationGroup := ComponentGroup;
end;

procedure TWelaEffectActivationAbilityComponent.Fire(Targets : ATarget);
var
  Condition : boolean;
  Balance, Cap : RParam;
begin
  Condition := True;
  Condition := Condition and (not FOnlyAfterGameStart or (GlobalEventbus.Read(eiGameTickTimeToFirstTick, []).AsInteger <= 0));
  if FOnCap then
  begin
    Balance := Eventbus.Read(eiResourceBalance, [FResType], FCheckGroup);
    Cap := Eventbus.Read(eiResourceCap, [FResType], FCheckGroup);
    Condition := Condition and ((not FInvertOnCap and (Balance = Cap)) or (FInvertOnCap and (Balance <> Cap)));
  end;
  // only throw event if it would change the targets status
  if Condition and (Eventbus.Read(eiWelaActive, [FActivationState], FActivationGroup).AsBooleanDefaultTrue <> FActivationState) then
  begin
    Eventbus.Write(eiWelaActive, [FActivationState], FActivationGroup);
  end;
end;

function TWelaEffectActivationAbilityComponent.OnlyAfterGameStart : TWelaEffectActivationAbilityComponent;
begin
  Result := self;
  FOnlyAfterGameStart := True;
end;

function TWelaEffectActivationAbilityComponent.TriggerOnReachResourceCap(ResType : integer) : TWelaEffectActivationAbilityComponent;
begin
  Result := self;
  FOnCap := True;
  FResType := ResType;
end;

function TWelaEffectActivationAbilityComponent.SetActivationGroup(ActivationGroup : TArray<byte>) : TWelaEffectActivationAbilityComponent;
begin
  Result := self;
  FActivationGroup := ByteArrayToComponentGroup(ActivationGroup);
end;

function TWelaEffectActivationAbilityComponent.SetCheckGroup(CheckGroup : TArray<byte>) : TWelaEffectActivationAbilityComponent;
begin
  Result := self;
  FCheckGroup := ByteArrayToComponentGroup(CheckGroup);
end;

function TWelaEffectActivationAbilityComponent.SetsActive : TWelaEffectActivationAbilityComponent;
begin
  Result := self;
  FActivationState := True;
end;

{ TWelaHelperInitActiveAfterGameStartComponent }

constructor TWelaHelperInitActiveAfterGameStartComponent.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>);
var
  state : boolean;
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  state := (ServerGame.IngameStatus = EnumIngameStatus.gsPlaying);
  if state or not Eventbus.Read(eiWelaActive, [], self.ComponentGroup).AsBooleanDefaultTrue then
      FDisabled := True
  else
      Eventbus.Write(eiWelaActive, [False], self.ComponentGroup);
end;

function TWelaHelperInitActiveAfterGameStartComponent.DisableOnReachResourceCap(Resource : integer; Group : TArray<byte>) : TWelaHelperInitActiveAfterGameStartComponent;
begin
  Result := self;
  FDisableOnReachResourceCap := EnumResource(Resource);
  FCheckGroup := ByteArrayToComponentGroup(Group);
end;

function TWelaHelperInitActiveAfterGameStartComponent.OnGameTick : boolean;
var
  Condition : boolean;
  Balance, Cap : RParam;
begin
  Result := True;
  if not FDisabled then
  begin
    Condition := True;
    if FDisableOnReachResourceCap <> reNone then
    begin
      Balance := Eventbus.Read(eiResourceBalance, [ord(FDisableOnReachResourceCap)], FCheckGroup);
      Cap := Eventbus.Read(eiResourceCap, [ord(FDisableOnReachResourceCap)], FCheckGroup);
      Condition := Condition and (Balance <> Cap);
    end;
    if Condition then Eventbus.Write(eiWelaActive, [True], self.ComponentGroup);
  end;
  Free;
end;

{ TWelaTargetingNexusComponent }

procedure TWelaTargetingNexusComponent.UpdateTargets(CurrentList : TList<RTarget>);
var
  opponentNexus : TEntity;
begin
  CurrentList.Clear;
  if Game.EntityManager.TryGetNexusNextEnemy(Owner, opponentNexus) then
      CurrentList.Add(RTarget.Create(opponentNexus));
end;

function TWelaTargetingNexusComponent.ValidateTarget(Target : RTarget) : boolean;
var
  Entity : TEntity;
begin
  Result := Target.IsEntity and Target.TryGetTargetEntity(Entity);
  if Result then
      Result := FetchEfficiency(Target.GetTargetEntity, FValidateGroup) > 0;
end;

{ TWelaEffectOnlyByChanceComponent }

function TWelaEffectOnlyByChanceComponent.OnFire(Targets : RParam) : boolean;
var
  Chance : RParam;
begin
  Chance := Eventbus.Read(eiWelaChance, [], ComponentGroup);
  assert(not Chance.IsEmpty, 'TWelaEffectOnlyByChanceComponent.OnFire: Empty eiWelaChance, need this value to work!');
  Result := Chance.IsEmpty or (Chance.AsSingle >= random);
end;

{ TWelaEffectFireComponent }

procedure TWelaEffectFireComponent.Fire(Targets : ATarget);
  function CheckAndFireInGroup(const TargetGroup : SetComponentGroup) : boolean;
  var
    i : integer;
    Target : RParam;
  begin
    Result := False;
    if Eventbus.Read(eiIsReady, [], TargetGroup).AsBooleanDefaultTrue then
    begin
      for i := 0 to Targets.Count - 1 do
      begin
        Target := ATarget.Create(Targets[i]).ToRParam;
        if FRedirectToGround or Eventbus.Read(eiWelaTargetPossible, [Target], TargetGroup).AsRTargetValidity.IsValid then
        begin
          Eventbus.Trigger(eiFire, [Target], TargetGroup);
          Result := True;
        end;
      end;
    end;
  end;

var
  i, CreatorID : integer;
  Creator : TEntity;
  CreatorGroup : SetComponentGroup;
  TargetPosition : RVector2;
begin
  if FFireInCreator then
  begin
    CreatorID := Eventbus.Read(eiCreator, [], ComponentGroup).AsInteger;
    if Game.EntityManager.TryGetEntityByID(CreatorID, Creator) then
    begin
      CreatorGroup := Eventbus.Read(eiCreatorGroup, [], ComponentGroup).AsSetType<SetComponentGroup>;
      // don't make a global fire as it would trigger all welas on that entity
      if CreatorGroup <> [] then
          Creator.Eventbus.Trigger(eiFire, [Targets.ToRParam], CreatorGroup);
    end;
  end
  else
  begin
    if not HLog.AssertAndLog((FTargetGroup <> []) or (length(FMultitargetGroup) > 0), 'TWelaEffectFireComponent.Fire: No target group set!') then
    begin
      if FRedirectToSelf then Targets := ATarget.Create(Owner);
      if FRedirectToGround then
      begin
        TargetPosition := Targets.First.GetTargetPosition;
        TargetPosition := TargetPosition + RVector2.Create(0, FGroundJitterMinRange + random * (FGroundJitterMaxRange - FGroundJitterMinRange)).Rotate(random * 2 * PI);
        if assigned(ServerGame) then
            TargetPosition := ServerGame.Map.ClampToZone(ZONE_WALK, TargetPosition);
        Targets := ATarget.Create(TargetPosition);
      end;

      if length(FMultitargetGroup) <= 0 then
          CheckAndFireInGroup(FTargetGroup)
      else
        for i := 0 to length(FMultitargetGroup) - 1 do
          if CheckAndFireInGroup(FMultitargetGroup[i]) then
              break;
    end;
  end;
end;

function TWelaEffectFireComponent.FireInCreator : TWelaEffectFireComponent;
begin
  Result := self;
  FFireInCreator := True;
end;

function TWelaEffectFireComponent.MultiTargetGroup(const Group : TArray<byte>) : TWelaEffectFireComponent;
begin
  Result := self;
  setLength(FMultitargetGroup, length(FMultitargetGroup) + 1);
  FMultitargetGroup[high(FMultitargetGroup)] := ByteArrayToComponentGroup(Group);
end;

function TWelaEffectFireComponent.RandomizeGroundtarget(MinRange, MaxRange : single) : TWelaEffectFireComponent;
begin
  Result := self;
  FGroundJitterMinRange := MinRange;
  FGroundJitterMaxRange := MaxRange;
end;

function TWelaEffectFireComponent.RedirectToGround : TWelaEffectFireComponent;
begin
  Result := self;
  FRedirectToGround := True;
end;

function TWelaEffectFireComponent.RedirectToLinkDestination : TWelaEffectFireComponent;
begin
  Result := self;
  FRedirectToDestination := True;
end;

function TWelaEffectFireComponent.RedirectToLinkSource : TWelaEffectFireComponent;
begin
  Result := self;
  FRedirectToSource := True;
end;

function TWelaEffectFireComponent.RedirectToSelf : TWelaEffectFireComponent;
begin
  Result := self;
  FRedirectToSelf := True;
end;

function TWelaEffectFireComponent.TargetGroup(const Group : TArray<byte>) : TWelaEffectFireComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaHelperBeaconComponent }

function TWelaHelperBeaconComponent.OnWelaSearch(Properties, Previous : RParam) : RParam;
begin
  if Properties.AsSetType<SetUnitProperty> * FUnitProperties <> [] then
  begin
    Result := RParam.From<SetComponentGroup>(Previous.AsType<SetComponentGroup> + ComponentGroup);
  end
  else Result := Previous;
end;

function TWelaHelperBeaconComponent.TriggerAt(const Properties : TArray<byte>) : TWelaHelperBeaconComponent;
begin
  Result := self;
  FUnitProperties := ByteArrayToSetUnitProperies(Properties);
end;

{ TWelaEffectResetCooldownComponent }

function TWelaEffectResetCooldownComponent.Expire : TWelaEffectResetCooldownComponent;
begin
  Result := self;
  FExpire := True;
end;

procedure TWelaEffectResetCooldownComponent.Fire(Targets : ATarget);
var
  i : integer;
  ResetGroups : SetComponentGroup;
  TargetEntity : TEntity;
begin
  for i := 0 to length(Targets) - 1 do
    if Targets[i].TryGetTargetEntity(TargetEntity) then
    begin
      ResetGroups := FTargetGroup;
      if FLookForGroup <> [] then
          ResetGroups := ResetGroups + TargetEntity.Eventbus.Read(eiWelaSearch, [RParam.From<SetUnitProperty>(FLookForGroup)]).AsType<SetComponentGroup>;
      if ResetGroups <> [] then
          TargetEntity.Eventbus.Trigger(eiWelaCooldownReset, [FExpire], ResetGroups);
    end;
end;

function TWelaEffectResetCooldownComponent.SearchForWelaBeacon(const Properties : TArray<byte>) : TWelaEffectResetCooldownComponent;
begin
  Result := self;
  FLookForGroup := ByteArrayToSetUnitProperies(Properties);
end;

function TWelaEffectResetCooldownComponent.TargetGroup(const Group : TArray<byte>) : TWelaEffectResetCooldownComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaEffectRemoveBeaconComponent }

procedure TWelaEffectRemoveBeaconComponent.Fire(Targets : ATarget);
var
  i : integer;
  RemoveGroups : SetComponentGroup;
  TargetEntity : TEntity;
begin
  assert(FLookForGroup <> [], 'TWelaEffectRemoveBeaconComponent.Fire: No beacon specified!');
  for i := 0 to length(Targets) - 1 do
    if Targets[i].TryGetTargetEntity(TargetEntity) then
    begin
      RemoveGroups := TargetEntity.Eventbus.Read(eiWelaSearch, [RParam.From<SetUnitProperty>(FLookForGroup)]).AsType<SetComponentGroup>;
      if RemoveGroups <> [] then
          TargetEntity.RemoveGroups(ComponentGroupToByteArray(RemoveGroups));
    end;
end;

function TWelaEffectRemoveBeaconComponent.SearchForWelaBeacon(const Properties : TArray<byte>) : TWelaEffectRemoveBeaconComponent;
begin
  Result := self;
  FLookForGroup := ByteArrayToSetUnitProperies(Properties);
end;

{ TWelaHelperActivateTimerComponent }

constructor TWelaHelperActivateTimerComponent.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FTimer := TTimer.CreateAndStart(1);
end;

function TWelaHelperActivateTimerComponent.Delay(const Duration : integer) : TWelaHelperActivateTimerComponent;
begin
  Result := self;
  FTimer.Interval := Duration;
end;

destructor TWelaHelperActivateTimerComponent.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TWelaHelperActivateTimerComponent.OnIdle : boolean;
begin
  Result := True;
  if FTimer.Expired then
  begin
    Eventbus.Write(eiWelaActive, [True], ComponentGroup);
    Free;
  end;
end;

{ TWelaEfficiencyMissingHealthComponent }

function TWelaEfficiencyMissingHealthComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
begin
  Result := Entity.Cap(reHealth).AsSingle - Entity.Balance(reHealth).AsSingle;
end;

{ TWelaEfficiencyComponent }

function TWelaEfficiencyComponent.OnEfficiency(Target, Previous : RParam) : RParam;
begin
  Result := Previous.AsSingle + GetEfficiencyToTarget(Target.AsType<TEntity>);
end;

{ TModifierBlindedComponent }

function TModifierBlindedComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if CurrentEvent.CalledToGroup * FValueGroup = [] then exit;
  FWillMiss := random <= BLIND_CHANCE;
  if FWillMiss then
  begin
    Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], FFireGroup);
  end;
end;

function TModifierBlindedComponent.OnFireWarhead(Targets : RParam) : boolean;
begin
  Result := not FWillMiss;
end;

function TModifierBlindedComponent.OnWelaShotProjectile(Projectile : RParam) : boolean;
var
  ProjectileEntity : TEntity;
  TargetUnitProperties : SetUnitProperty;
begin
  Result := True;
  if FWillMiss then
  begin
    ProjectileEntity := Projectile.AsType<TEntity>;
    // get/set value direct in blackboard, as we don't want to save temporary properties introduced by components as permanent
    TargetUnitProperties := ProjectileEntity.Blackboard.GetValue(eiUnitProperties, []).AsSetType<SetUnitProperty>;
    TargetUnitProperties := TargetUnitProperties + [upProjectileWillMiss];
    ProjectileEntity.Blackboard.SetValue(eiUnitProperties, [], RParam.From<SetUnitProperty>(TargetUnitProperties));
  end;
end;

function TModifierBlindedComponent.SetFireGroup(Group : TArray<byte>) : TModifierBlindedComponent;
begin
  Result := self;
  FFireGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaEfficiencyDamageTypeComponent }

function TWelaEfficiencyDamageTypeComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
var
  DamageType : SetDamageType;
begin
  DamageType := Entity.Eventbus.Read(eiDamageType, [], [GROUP_MAINWEAPON]).AsType<SetDamageType>;
  if DamageType * FPrioritizedDamageTypes <> [] then Result := 1
  else Result := 0;
end;

function TWelaEfficiencyDamageTypeComponent.Prioritize(DamageTypes : TArray<byte>) : TWelaEfficiencyDamageTypeComponent;
begin
  Result := self;
  FPrioritizedDamageTypes := ByteArrayToSetDamageType(DamageTypes);
end;

{ TWelaEfficiencyUnitPropertyComponent }

function TWelaEfficiencyUnitPropertyComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
var
  UnitProperties : SetUnitProperty;
begin
  UnitProperties := Entity.Eventbus.Read(eiUnitProperties, [], []).AsSetType<SetUnitProperty>;
  if UnitProperties * FPrioritizedUnitProperties <> [] then Result := 1
  else Result := 0;
  if FReversed then Result := 1 - Result;
end;

function TWelaEfficiencyUnitPropertyComponent.Prioritize(UnitProperties : TArray<byte>) : TWelaEfficiencyUnitPropertyComponent;
begin
  Result := self;
  FPrioritizedUnitProperties := ByteArrayToSetUnitProperies(UnitProperties);
end;

function TWelaEfficiencyUnitPropertyComponent.Reverse : TWelaEfficiencyUnitPropertyComponent;
begin
  Result := self;
  FReversed := True;
end;

{ TWelaEffectGameEventComponent }

function TWelaEffectGameEventComponent.Event(const EventID : string) : TWelaEffectGameEventComponent;
begin
  Result := self;
  HArray.Push<string>(FGameEvents, EventID);
end;

procedure TWelaEffectGameEventComponent.Fire(Targets : ATarget);
var
  i : integer;
begin
  for i := 0 to length(FGameEvents) - 1 do
      GlobalEventbus.Trigger(eiGameEvent, [FGameEvents[i]]);
end;

{ TWelaEfficiencyMaxHealthComponent }

function TWelaEfficiencyMaxHealthComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
begin
  Result := Entity.Cap(reHealth).AsSingle;
  if FInversed then
      Result := 10000 - Result;
end;

function TWelaEfficiencyMaxHealthComponent.Inverse : TWelaEfficiencyMaxHealthComponent;
begin
  Result := self;
  FInversed := True;
end;

{ TWelaEffectRedirecterComponent }

function TWelaEffectRedirecterComponent.OnFire(var Targets : RParam) : boolean;
begin
  Result := True;
  if FRedirectToGround then
      Targets := ATarget.Create(Owner.Position).ToRParam;
end;

function TWelaEffectRedirecterComponent.RedirectToGround : TWelaEffectRedirecterComponent;
begin
  Result := self;
  FRedirectToGround := True;
end;

{ TWelaEfficiencyCreatedComponent }

function TWelaEfficiencyCreatedComponent.GetEfficiencyToTarget(Entity : TEntity) : single;
begin
  Result := TimeManager.GetTimestamp - Entity.CreatedTimestamp;
end;

{ TWelaEffectTriggerSpellCastComponent }

procedure TWelaEffectTriggerSpellCastComponent.Fire(Targets : ATarget);
begin
  GlobalEventbus.Trigger(eiCommanderAbilityUsed, [Owner.TeamID, Targets.ToRParam]);
end;

{ TWelaReadyEntityNearbyComponent }

constructor TWelaReadyEntityNearbyComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FTargetingGroup := ComponentGroup;
end;

function TWelaReadyEntityNearbyComponent.IsReady : boolean;
var
  Targets : TList<RTarget>;
begin
  Targets := TList<RTarget>.Create;
  Eventbus.Trigger(eiWelaUpdateTargets, [Targets], FTargetingGroup);
  Result := (FReadyIfTargets and (Targets.Count > 0)) or (not FReadyIfTargets and (Targets.Count <= 0));
  Targets.Free;
end;

function TWelaReadyEntityNearbyComponent.ReadyIfNoTargets : TWelaReadyEntityNearbyComponent;
begin
  Result := self;
  FReadyIfTargets := False;
end;

function TWelaReadyEntityNearbyComponent.ReadyIfTargets : TWelaReadyEntityNearbyComponent;
begin
  Result := self;
  FReadyIfTargets := True;
end;

function TWelaReadyEntityNearbyComponent.TargetingGroup(Group : TArray<byte>) : TWelaReadyEntityNearbyComponent;
begin
  Result := self;
  FTargetingGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaTargetingSelfComponent }

procedure TWelaTargetingSelfComponent.UpdateTargets(CurrentList : TList<RTarget>);
begin
  CurrentList.Clear;
  CurrentList.Add(RTarget.Create(Owner));
end;

function TWelaTargetingSelfComponent.ValidateTarget(Target : RTarget) : boolean;
begin
  Result := Target.IsEntity and (Target.EntityID = Owner.ID);
  if Result then
      Result := FetchEfficiency(Owner, FValidateGroup) > 0;
end;

{ TWelaEffectIncreaseResourceComponent }

procedure TWelaEffectIncreaseResourceComponent.Fire(Targets : ATarget);
var
  Amount : RParam;
  iAmount : integer;
  sAmount : single;
begin
  if FResource in RES_INT_RESOURCES then
  begin
    iAmount := 1;
    Amount := iAmount;
  end
  else
  begin
    sAmount := 1.0;
    Amount := sAmount;
  end;
  Eventbus.Trigger(eiResourceTransaction, [ord(FResource), Amount], ComponentGroup);
end;

function TWelaEffectIncreaseResourceComponent.SetResourceType(Resource : EnumResource) : TWelaEffectIncreaseResourceComponent;
begin
  Result := self;
  FResource := Resource;
end;

initialization

ScriptManager.ExposeClass(TWelaReadyUnitLimiterComponent);
ScriptManager.ExposeClass(TWelaEffectLinkPayCostMyselfComponentServer);
ScriptManager.ExposeClass(TWelaEffectPayCostComponent);
ScriptManager.ExposeClass(TWelaReadyNthComponent);
ScriptManager.ExposeClass(TWelaReadyEachNthGameTickComponent);
ScriptManager.ExposeClass(TWelaReadyEntityNearbyComponent);

ScriptManager.ExposeClass(TWelaTargetingComponent);
ScriptManager.ExposeClass(TWelaTargetingRadialComponent);
ScriptManager.ExposeClass(TWelaTargetingNexusComponent);
ScriptManager.ExposeClass(TWelaTargetingGlobalComponent);
ScriptManager.ExposeClass(TWelaTargetingRadialAttentionComponent);
ScriptManager.ExposeClass(TWelaTargetingRectangleComponent);
ScriptManager.ExposeClass(TWelaTargetingSelfComponent);

ScriptManager.ExposeClass(TWelaEffectRedirecterComponent);

ScriptManager.ExposeClass(TWelaLinkEffectComponent);
ScriptManager.ExposeClass(TWelaLinkEffectUnitPropertyComponent);
ScriptManager.ExposeClass(TWelaEffectOnlyByChanceComponent);
ScriptManager.ExposeClass(TWelaEffectProjectileComponent);
ScriptManager.ExposeClass(TWelaEffectFactoryComponent);
ScriptManager.ExposeClass(TWelaEffectInstantComponent);
ScriptManager.ExposeClass(TWelaEffectReplaceComponent);
ScriptManager.ExposeClass(TWelaEffectRemoveAfterUseComponent);
ScriptManager.ExposeClass(TWelaEffectSuicideComponent);
ScriptManager.ExposeClass(TWelaEffectInheritEventValueComponent);
ScriptManager.ExposeClass(TWelaEffectActivationAbilityComponent);
ScriptManager.ExposeClass(TWelaEffectFireComponent);
ScriptManager.ExposeClass(TWelaEffectResetCooldownComponent);
ScriptManager.ExposeClass(TWelaEffectRemoveBeaconComponent);
ScriptManager.ExposeClass(TWelaEffectGameEventComponent);
ScriptManager.ExposeClass(TWelaEffectTriggerSpellCastComponent);
ScriptManager.ExposeClass(TWelaEffectIncreaseResourceComponent);

ScriptManager.ExposeClass(TLinkEffectDamageRedirectionComponent);
ScriptManager.ExposeClass(TLinkEffectFireAtProducedUnitsComponent);

ScriptManager.ExposeClass(TProjectileEventRedirecter);

ScriptManager.ExposeClass(TModifierMultiplyDealtDamageComponent);
ScriptManager.ExposeClass(TModifierBlindedComponent);

ScriptManager.ExposeClass(TWelaHelperInitActiveAfterGameStartComponent);
ScriptManager.ExposeClass(TWelaHelperActivateTimerComponent);
ScriptManager.ExposeClass(TWelaHelperBeaconComponent);

ScriptManager.ExposeClass(TWelaEfficiencyMissingHealthComponent);
ScriptManager.ExposeClass(TWelaEfficiencyDamageTypeComponent);
ScriptManager.ExposeClass(TWelaEfficiencyUnitPropertyComponent);
ScriptManager.ExposeClass(TWelaEfficiencyMaxHealthComponent);
ScriptManager.ExposeClass(TWelaEfficiencyCreatedComponent);

end.
