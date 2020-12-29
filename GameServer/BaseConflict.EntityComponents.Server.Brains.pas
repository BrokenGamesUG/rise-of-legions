unit BaseConflict.EntityComponents.Server.Brains;

interface

uses
  SysUtils,
  System.Rtti,
  Generics.Defaults,
  Generics.Collections,
  Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Script,
  BaseConflict.Classes.Server,
  BaseConflict.Map,
  BaseConflict.Types.Target,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Server,
  BaseConflict.Globals,
  BaseConflict.Constants,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared;

type

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Think impulse generators - initiates the thinking of brains
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///
  {$RTTI INHERIT}
  /// <summary> Initiate the thinking in its group in its constructor.
  /// Hint: If unit is exiled it does not think anymore. </summary>
  TThinkImpulseNowComponent = class(TEntityComponent)
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Initiate the thinking in its group every time the game ticks.
  /// Hint: If unit is exiled it does not think anymore. </summary>
  TThinkImpulseGameTickComponent = class(TEntityComponent)
    published
      [XEvent(eiGameTick, epMiddle, etTrigger, esGlobal)]
      /// <summary> Initiates thinking. </summary>
      function OnGameTick() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Initiate the thinking in target group every time it receives a eiFire.
  /// Hint: If unit is exiled it does not think anymore. </summary>
  TThinkImpulseFireComponent = class(TEntityComponent)
    protected
      FThinkGroup : SetComponentGroup;
    published
      [XEvent(eiFire, epLast, etTrigger)]
      /// <summary> Initiates thinking. </summary>
      function OnFire(Targets : RParam) : boolean;
    public
      /// <summary> Determines the target group of thinking, defaults to public group []. </summary>
      function TargetGroup(Group : TArray<byte>) : TThinkImpulseFireComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Initiate the thinking in its group every frame. Usually used in entities which are deployed anywhere and are
  /// wanted to explode immediately such as effectentities of commanderspells.
  /// Hint: If unit is exiled it does not think anymore. </summary>
  TThinkImpulseImmediateComponent = class(TEntityComponent)
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Initiates thinking. </summary>
      function OnIdle() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Initiate the thinking in its group at the first and only at the first idle. Usually used in entities which
  /// are deployed anywhere and are wanted to excecute an ability once. Freed after usage.
  /// Hint: If unit is exiled it does not think anymore. </summary>
  TThinkImpulseOnceComponent = class(TEntityComponent)
    protected
      FWaitOneFrame, FTriggerOnAfterCreate, FTriggerOnDeploy : boolean;
      procedure Trigger;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Initiates thinking. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiDeploy, epLast, etTrigger)]
      /// <summary> Initiates thinking. </summary>
      function OnDeploy() : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Initiates thinking. </summary>
      function OnIdle() : boolean;
    public
      function WaitOneFrame : TThinkImpulseOnceComponent;
      function TriggerOnAfterCreate : TThinkImpulseOnceComponent;
      function TriggerOnDeploy : TThinkImpulseOnceComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Initiate the thinking of all brains in its group every THINK_TIME_INTERVAL (250ms atm) and if the move target
  /// has been reached. Not done every frame, because of performance. Used in all units.
  /// Hint: If unit isn't alive or exiled it does not think anymore. </summary>
  TThinkImpulseTimerComponent = class(TEntityComponent)
    protected
      FThinkTimer : TTimer;
    published
      [XEvent(eiMoveTargetReached, epLast, etTrigger)]
      /// <summary> Inits thinking for what to do next. </summary>
      function OnMoveTargetReached() : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Initiates thinking if ready. </summary>
      function OnIdle() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Initiate the thinking of all brains in its group every time the timer expires.
  /// Timer is not ready at creation and uses the interval in eiCooldown. </summary>
  TThinkImpulseTimerCooldownComponent = class(TEntityComponent)
    protected
      FThinkTimer : TTimer;
      FOnce, FFired : boolean;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Initiates thinking if timer is ready. </summary>
      function OnIdle() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function TimerIsReady() : TThinkImpulseTimerCooldownComponent;
      function Once : TThinkImpulseTimerCooldownComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Blocks any thinking in an entity. </summary>
  TThinkBlockComponent = class(TEntityComponent)
    published
      [XEvent(eiThink, epFirst, etTrigger)]
      /// <summary> Initiates thinking. </summary>
      function OnThink() : boolean;
      [XEvent(eiThinkChain, epFirst, etTrigger)]
      /// <summary> Initiates thinking. </summary>
      function OnThinkChain() : boolean;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Brains - handles everything about units and welas
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Brainmasterclass, all thinking brains are derived from this. Every brain can have a different
  /// priority of its eiThinkChain event, so no meta-method to be overwritten here. </summary>
  TBrainComponent = class abstract(TEntityComponent)
    protected
      FPassiveThinking, FPassiveThinkingIfConscious, FThinkLocal, FThinkInExile : boolean;
      function IsWelaReady : boolean;
      function CanThink : boolean;
      function CanMove : boolean;
      /// <summary> Should be called in the OnThink-Event. </summary>
      function ThinkEvent : boolean;
      /// <summary> Should be called in the OnThinkChain-Event. </summary>
      function ThinkChainEvent : boolean;
      /// <summary> This get called everytime thinking is initiated and if brain can think. </summary>
      procedure Think; virtual;
      /// <summary> This get called everytime thinking is initiated, if brain can think and no other brain in the chain consumed the event. </summary>
      function ThinkChain : boolean; virtual;
      /// <summary> Checks whether the weapon is ready and the targets are valid and if true fires at them. </summary>
      procedure FireWithChecks(const Targets : ATarget);
    published
      [XEvent(eiThink, epMiddle, etTrigger)]
      function OnThink() : boolean;
    public
      /// <summary> This brain is thinking all the time, even if the unit is inactive (e.g. stunned). Brains
      /// are conscious at default (figurative: walking, speaking, etc.), but can be switched to automatic (figurative: breathing, etc.) </summary>
      function ThinksPassively : TBrainComponent;
      /// <summary> This brain is thinking even if the unit is attacking. </summary>
      function ThinksPassivelyIfConscious : TBrainComponent;
      /// <summary> Thinking is only processed, when think event is a local event. </summary>
      function ThinksLocal : TBrainComponent;
      /// <summary> Thinking is also done in exile. </summary>
      function ThinksInExile : TBrainComponent;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Movement brains - a walking story
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Brain for the inner need to follow the lane to its end. </summary>
  TBrainFollowLaneComponent = class(TBrainComponent)
    protected
      FMoving : boolean;
      FLane : TLane;
      FLaneDirection : EnumLaneDirection;
      procedure AcquireLane;
      function ThinkChain : boolean; override;
    published
      [XEvent(eiExiled, epLast, etWrite)]
      /// <summary> If unit returns to the battlefield we reset its relative lane position. </summary>
      function OnExiled(Exiled : RParam) : boolean;
      [XEvent(eiAfterCreate, epMiddle, etTrigger)]
      /// <summary> Fetches the next lane and bind our path to it. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiMoveTargetReached, epLast, etTrigger)]
      /// <summary> Whenever the unit stops moving the next think will compute a new path. </summary>
      function OnMoveTargetReached() : boolean;
      [XEvent(eiThinkChain, epLast, etTrigger)]
      /// <summary> If the unit isn't moving this thought computes the next point to walk to on our lane. </summary>
      function OnThinkChain() : boolean;
      [XEvent(eiGetLane, epFirst, etRead)]
      function OnGetLane() : RParam;
      [XEvent(eiGetLaneDirection, epFirst, etRead)]
      function OnGetLaneDirection() : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> This brain uses the targetingcomponent of its group to look for targets in range and approach
  /// to the next valid target if something is there.
  /// Attention: This brain needs a TWelaTargetingComponent for working properly. </summary>
  TBrainApproachComponent = class(TBrainComponent)
    protected
      FApproaching : boolean;
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epLow, etTrigger)]
      /// <summary> Look for enemies and go to them into weaponrange. </summary>
      function OnThinkChain() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> This brain uses the targetingcomponent of its group to look for targets in range and follow
  /// to the next valid target if something is there.
  /// Attention: This brain needs a TWelaTargetingComponent for working properly. </summary>
  TBrainFollowComponent = class(TBrainApproachComponent)
  end;

  {$RTTI INHERIT}

  /// <summary> Unit will try to hold a specific position. </summary>
  TBrainOverwatchComponent = class(TBrainComponent)
    protected
      FTargetPosition, FTargetDirection : RVector2;
      FMoving : boolean;
      function IsAway : boolean;
      function ThinkChain : boolean; override;
    published
      [XEvent(eiAfterCreate, epMiddle, etTrigger)]
      /// <summary> Fetches the starting position to hold. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiMoveTargetReached, epLast, etTrigger)]
      /// <summary> Whenever the unit stops moving the next think will compute a new path. </summary>
      function OnMoveTargetReached() : boolean;
      [XEvent(eiThinkChain, epLower, etTrigger)]
      /// <summary> If the unit isn't at the overwatch position, try to get there. </summary>
      function OnThinkChain() : boolean;
    public
  end;

  {$RTTI INHERIT}

  /// <summary> Unit will try to hold a specific position. </summary>
  TBrainOverwatchSandboxComponent = class(TBrainOverwatchComponent)
  end;

  {$RTTI INHERIT}

  /// <summary> Unit will flee back to its initial position if it goes out of range of its position. </summary>
  TBrainFleeComponent = class(TBrainComponent)
    protected
      FTargetPosition, FTargetDirection : RVector2;
      FRange : single;
      FMoving : boolean;
      function IsAway : boolean;
      function IsOutOFRange : boolean;
      function ThinkChain : boolean; override;
    published
      [XEvent(eiAfterCreate, epMiddle, etTrigger)]
      /// <summary> Fetches the starting position to hold. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiMoveTargetReached, epLast, etTrigger)]
      /// <summary> Whenever the unit stops moving the next think will compute a new path. </summary>
      function OnMoveTargetReached() : boolean;
      [XEvent(eiThinkChain, epLow, etTrigger)]
      /// <summary> If the unit isn't at the overwatch position, try to get there. </summary>
      function OnThinkChain() : boolean;
    public
      function Range(s : single) : TBrainFleeComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This brain uses the targetingcomponent of its group to look for targets in range and stand
  /// still if something valid is there. For example the former unit spawning zeppelin had a radial targeting
  /// component looking for enemies and if something has been found it wouldn't move anymore.
  /// Attention: This brain needs a TWelaTargetingComponent for working properly. </summary>
  TBrainWaitComponent = class(TBrainComponent)
    protected
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epLow, etTrigger)]
      /// <summary> Look for enemies and wait if something spotted. </summary>
      function OnThinkChain() : boolean;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Abilitybrains - all abilities which are triggered at certain circumstances
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Masterclass of brains which handles a wela. </summary>
  TBrainWelaComponent = class abstract(TBrainComponent)
    protected
      FBlocking : boolean;
      FFireEvent : EnumEventIdentifier;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> Blocking brains are blocking the whole think chain after their activation for the eiWelaActionduration. </summary>
      function Blocking : TBrainWelaComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles welas with selftargeting, e.g. regeneration abilities.
  /// At every thought this brain checks whether the wela is ready (eiIsReady), if yes it checks whether
  /// its owner (selftargeting) is valid (eiWelaTargetPossible) and finally if yes firing (eiFire) at itself. </summary>
  TBrainWelaSelftargetComponent = class(TBrainWelaComponent)
    protected
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      /// <summary> Handles selftargeting wela. </summary>
      function OnThinkChain() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles welas with saved targets.
  /// At every thought this brain checks whether the wela is ready (eiIsReady), if yes it checks whether
  /// its owner (selftargeting) is valid (eiWelaTargetPossible) and finally if yes firing (eiFire) at the saved
  /// target (eiWelaSavedTargets). </summary>
  TBrainWelaSavedTargetComponent = class(TBrainWelaComponent)
    protected
      FSaveGroup : SetComponentGroup;
      FDisableValidityCheck : boolean;
      FFireAtIndex : integer;
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      function OnThinkChain() : boolean;
    public
      constructor CreateGrouped(Entity : TEntity; Group : TArray<byte>); override;
      /// <summary> The group to load the targets from. Defaults to []. </summary>
      function SaveGroup(Group : TArray<byte>) : TBrainWelaSavedTargetComponent;
      /// <summary> Disables the check of the targets before the fire event is applied on them. </summary>
      function DisableValidityCheck : TBrainWelaSavedTargetComponent;
      function FireAtIndex(Index : integer) : TBrainWelaSavedTargetComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles welas with selftargeting at their feet (coordinatetargets), e.g. a nova ability.
  /// At every thought this brain checks whether the wela is ready (eiIsReady), if yes firing (eiFire) at
  /// the position of itself. </summary>
  TBrainWelaSelftargetGroundComponent = class(TBrainWelaComponent)
    protected
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      /// <summary> Handles ground-selftargeting wela. </summary>
      function OnThinkChain() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles welas without targets, e.g. the FactoryAbility.
  /// At every thought this brain checks whether the wela is ready (eiIsReady), if yes firing (eiFire) at
  /// nothing (an empty RTarget). </summary>
  TBrainWelaTargetlessComponent = class(TBrainWelaComponent)
    protected
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      /// <summary> Handles targetless wela. </summary>
      function OnThinkChain() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles welas with their owning commander as target (eiOwnerCommander).
  /// At every thought this brain checks whether the wela is ready (eiIsReady) and owner is possible (eiWelaPossible),
  /// if yes firing (eiFire) at its commander. </summary>
  TBrainWelaTargetCommanderComponent = class(TBrainComponent)
    protected
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      /// <summary> Handles commandertargeting wela. </summary>
      function OnThinkChain() : boolean;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Misc - all brains which cannot be easily put into any other section
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> The movement-"brain" of a projectile. Once the target is set by eiWelaSavedTargets (written at creation by the
  /// spawning TWelaEffectProjectileComponent) this component initiates the movement to the target. When the projectile reaches its
  /// destination, all warheads are fired (eiFireWarhead) and the the entity self destructs. </summary>
  TBrainProjectileComponent = class(TBrainComponent)
    protected
      FBounceCount : integer;
      FNotHoming, FInstant, FOnlyFollowing, FDieWithTarget, FNoTargetChecks, FBounces, FNoReflection : boolean;
      FBounceTargetGroup : SetComponentGroup;
      FDelayedEvent : TDelayedEventHandler;
      procedure InitiateOnSavedTarget;
      procedure SelfDestruct;
      function FireAtTarget(Targets : ATarget) : boolean;
      function ThinkChain : boolean; override;
    published
      function TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Initates the movement of a projectile. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiMoveTargetReached, epLast, etTrigger)]
      /// <summary> Fires the warhead of the projectile and kill itself. </summary>
      function OnMoveTargetReached : boolean;
      [XEvent(eiThinkChain, epLast, etTrigger)]
      function OnThinkChain() : boolean;
    public
      function SetNotFollowingTarget : TBrainProjectileComponent;
      function SetInstant : TBrainProjectileComponent;
      function SetOnlyFollowing : TBrainProjectileComponent;
      function NoTargetChecks : TBrainProjectileComponent;
      function CantBeReflected : TBrainProjectileComponent;
      function DieWithTarget : TBrainProjectileComponent;
      function Bounces(TargetGroup : TArray<byte>) : TBrainProjectileComponent;
      destructor Destroy; override;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Autobrains - all brains which are triggered with another mechanism than thinking
  /// ATTENTION: Autobrains are thinking passively at default!
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  TAutoBrainComponent = class(TBrainComponent)
    protected
      FFireGroup : SetComponentGroup;
      FFireAtAllCommanders, FFireAtCommander, FFireAtTarget, FFireAtGround, FFireAtSelf : boolean;
      procedure CheckAndFire(DefaultTargets : ATarget); overload;
      procedure Fire(DefaultTargets : ATarget); overload; virtual;
      procedure CheckAndFire; overload;
      procedure Fire; overload; virtual;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function FireInGroup(Group : TArray<byte>) : TAutoBrainComponent;
      /// <summary> Fires at owner. </summary>
      function FireAtSelf : TAutoBrainComponent;
      /// <summary> Fires at own position. </summary>
      function FireAtGround : TAutoBrainComponent;
      /// <summary> Uses targeting component to find targets. </summary>
      function FireAtTarget : TAutoBrainComponent;
      /// <summary> Fires at owning commander. </summary>
      function FireAtCommander : TAutoBrainComponent;
      /// <summary> Fires at all commanders, useful for bounty. </summary>
      function FireAtAllCommanders : TAutoBrainComponent;
  end;

  /// <summary> Metaclass for events with two parts a target and this entity itself. </summary>
  TAutoBrainBilateralComponent = class(TBrainComponent)
    protected
      FFiresAtSelf, FFiresAtTargets : boolean;
      FSelfFireGroup, FTargetsFireGroup, FCheckSelfForTargetsInGroup, FCheckTargetsForSelfInGroup : SetComponentGroup;
      /// <summary> Executes the set options for firing. </summary>
      procedure Fire(Targets : ATarget);
    public
      /// <summary> Group for checks and fire for targets. </summary>
      function FireTargetsInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
      /// <summary> Checks local group on owner for firing at targets as well. </summary>
      function CheckSelfForTargetsInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
      /// <summary> Group for checks and fire for self. </summary>
      function FireSelfInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
      /// <summary> Checks local group on targets for firing at owner as well. </summary>
      function CheckTargetsForSelfInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Fires the wela on each spawned unit. </summary>
  TAutoBrainUnitSpawnComponent = class(TAutoBrainComponent)
    published
      [XEvent(eiNewEntity, epLast, etTrigger, esGlobal)]
      function OnNewEntity(Entity : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles welas targeting produced units of their owner (eiWelaUnitProduced).
  /// At every production this brain checks whether the wela is ready (eiIsReady, default true), if yes firing (eiFire) at
  /// the spawned entity. </summary>
  TAutoBrainWelaTargetProducedUnitComponent = class(TAutoBrainComponent)
    protected
      FOnlyOwnGroup : boolean;
    published
      [XEvent(eiWelaUnitProduced, epLast, etTrigger)]
      /// <summary> Handles wela targeting produced entities. </summary>
      function OnWelaUnitProduced(EntityID : RParam) : boolean;
    public
      function FireOnlyAtUnitsInOwnGroup : TAutoBrainWelaTargetProducedUnitComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This projectile brain fires (eiFire) at the target as soon as it is set by eiWelaSavedTargets.
  /// It adds additional eiFire events to act like a chainlightning.
  /// Uses eiWelaAreaOfEffect to determine the next targets (Entities) and eiWelaTargetCount to determine the amount of targets.
  /// Takes always the next suitable target and don't hit targets twice. </summary>
  TAutoBrainWelaInstantChainComponent = class(TAutoBrainComponent)
    published
      [XEvent(eiWelaSavedTargets, epLast, etWrite)]
      /// <summary> Fires at target. </summary>
      function OnSetTarget(Target : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that handles some links. Kills itself if either source or destination dies. </summary>
  TAutoBrainKillLinkComponent = class(TAutoBrainComponent)
    published
      function TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Hook source/destination for dying. </summary>
      function OnAfterCreate() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at killing an enemy. Triggers eiFire on killed unit. </summary>
  TAutoBrainOnKillComponent = class(TAutoBrainComponent)
    protected
      FFireAtMyself : boolean;
    published
      [XEvent(eiYouHaveKilledMeShameOnYou, epLast, etTrigger)]
      /// <summary> On killing an enemy fire. </summary>
      function OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
    public
      function FireAtMyself : TAutoBrainOnKillComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at shooting a projectile. Triggers eiFire at the spawned projectile. </summary>
  TAutoBrainOnWelaShotProjectileComponent = class(TAutoBrainComponent)
    published
      [XEvent(eiWelaShotProjectile, epLast, etTrigger)]
      /// <summary> On killing an enemy fire. </summary>
      function OnWelaShotProjectile(Projectile : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at becoming hit a projectile. Triggers eiFire at the spawned projectile. </summary>
  TAutoBrainOnWelaHitByProjectileComponent = class(TAutoBrainComponent)
    published
      [XEvent(eiWelaHitByProjectile, epLast, etTrigger)]
      function OnWelaHitByProjectile(Projectile : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at a game event and fires at itself. </summary>
  TAutoBrainOnGameEventComponent = class(TAutoBrainComponent)
    protected
      FEvents : TArray<string>;
    published
      [XEvent(eiGameEvent, epLast, etTrigger, esGlobal)]
      /// <summary> Check if event matches, if yes fire. </summary>
      function OnGameEvent(Event : RParam) : boolean;
    public
      /// <summary> Fires at the killer of this unit. </summary>
      function SetEvent(Event : string) : TAutoBrainOnGameEventComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at creation. Triggers eiFire on itself. </summary>
  TAutoBrainOnCreateComponent = class(TAutoBrainComponent)
    protected
      FOnlyAfterGameStart, FOnlyBeforeGameStart : boolean;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterCreate() : boolean;
    public
      function OnlyAfterGameStart : TAutoBrainOnCreateComponent;
      function OnlyBeforeGameStart : TAutoBrainOnCreateComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at free. Triggers eiFire on itself. Only checks ready state. Acts passivley and even if exiled. </summary>
  TAutoBrainOnFreeComponent = class(TAutoBrainComponent)
    protected
      procedure BeforeComponentFree; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at dying. Triggers eiFire on itself. </summary>
  TAutoBrainOnDeathComponent = class(TAutoBrainComponent)
    protected
      FFireAtKiller : boolean;
      FKillerID : integer;
      procedure Fire; override;
    published
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> On dying fire at itself. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
    public
      /// <summary> Fires at the killer of this unit. </summary>
      function FireAtKiller : TAutoBrainOnDeathComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers short before dying. Triggers eiFire on itself. </summary>
  TAutoBrainOnBeforeDeath = class(TAutoBrainOnDeathComponent)
    public
      constructor CreateGrouped(Entity : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers welas on taking damage. First checks for eiWelaReady, then checks conditions
  // via eiWelaTriggerCheck. If everything passes triggers eiFire on itself in its group. </summary>
  TAutoBrainOnTakeDamageComponent = class(TAutoBrainBilateralComponent)
    protected
      FModifiesAmount : boolean;
    published
      [XEvent(eiTakeDamage, epFirst, etRead)]
      function OnTakeDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
    public
      /// <summary> Throws a local eiTakeDamage before eiFire and stops damage processing if amount becomes 0. </summary>
      function ModifiesAmount : TAutoBrainOnTakeDamageComponent;
      function TriggersAfterDamage : TAutoBrainOnTakeDamageComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers welas on units which are dealt damage. First checks for eiWelaReady, then checks conditions
  // via eiWelaTriggerCheck. If everything passes, throws a eiFire at the FireGroup. </summary>
  TAutoBrainOnDealDamageComponent = class(TAutoBrainComponent)
    protected
      FWriteAmount, FRedirectToSelf, FRedirectToSource, FDontFire, FAddAmountAtWrite : boolean;
      FWriteAmountTo : EnumEventIdentifier;
      procedure Fire(Amount : single; TargetEntity : TEntity); reintroduce;
    published
      [XEvent(eiDamageDone, epLast, etTrigger)]
      function OnDamageDone(Amount, DamageType, TargetEntity : RParam) : boolean;
    public
      /// <summary> For Links. </summary>
      function RedirectToSource : TAutoBrainOnDealDamageComponent;
      function RedirectToSelf : TAutoBrainOnDealDamageComponent;
      function WriteAmountTo(Event : EnumEventIdentifier) : TAutoBrainOnDealDamageComponent;
      function AddAmountAtWrite : TAutoBrainOnDealDamageComponent;
      function DontFire : TAutoBrainOnDealDamageComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers welas on units which are soon dealt damage. First checks for eiWelaReady, then checks conditions
  // via eiWelaTriggerCheck. If everything passes, throws a eiFire at the FireGroup. </summary>
  TAutoBrainOnWillDealDamageComponent = class(TAutoBrainOnDealDamageComponent)
    published
      [XEvent(eiWillDealDamage, epLast, etRead)]
      function OnWillDealDamage(Amount, DamageTypes, TargetEntity, Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers welas on become healed. First checks for eiWelaReady, then checks conditions
  // via eiWelaTriggerCheck. Triggers eiFire on itself in its group if tests pass. </summary>
  TAutoBrainOnHealedComponent = class(TAutoBrainComponent)
    protected
      FTimesForEach : integer;
    published
      [XEvent(eiHeal, epFirst, etRead)]
      function OnHeal(var Amount : RParam; HealModifier, InflictorID, Previous : RParam) : RParam;
    public
      function TimesForEach(Factor : integer) : TAutoBrainOnHealedComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers welas on gaining resources. First checks for eiWelaReady, then checks conditions
  // via eiWelaTriggerCheck. Triggers eiFire on itself in its group if tests pass. </summary>
  TAutoBrainOnResourceComponent = class(TAutoBrainComponent)
    protected
      FResource : SetResource;
      FTimesForEach : boolean;
    published
      [XEvent(eiResourceTransaction, epLower, etTrigger)]
      function OnTransact(ResourceID, Amount : RParam) : boolean;
    public
      function TriggerOn(Resource : TArray<byte>) : TAutoBrainOnResourceComponent;
      function TimesForEach() : TAutoBrainOnResourceComponent;
  end;

  {$RTTI INHERIT}

  TAutoBrainOnCommanderAbilityUsedComponent = class(TAutoBrainComponent)
    protected
      FConstraintOnSameTeamID, FConstraintOnInWelaRange : boolean;
    published
      [XEvent(eiCommanderAbilityUsed, epMiddle, etTrigger, esGlobal)]
      function OnCommanderAbilityUsed(TeamID, TargetsRaw : RParam) : boolean;
    public
      function ConstraintOnSameTeamID : TAutoBrainOnCommanderAbilityUsedComponent;
      function ConstraintOnInWelaRange : TAutoBrainOnCommanderAbilityUsedComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers welas on become unit property applied. First checks for eiWelaReady, then checks conditions
  // via eiWelaTriggerCheck. Triggers eiFire on itself in its group if tests pass. </summary>
  TAutoBrainOnUnitPropertyComponent = class(TAutoBrainComponent)
    protected
      FTriggerAtUnitProperties, FMustNotHave : SetUnitProperty;
    published
      [XEvent(eiUnitPropertyChanged, epMiddle, etTrigger)]
      function OnUnitPropertyChanged(ChangedUnitProperties, Removed : RParam) : boolean;
    public
      function TriggerOn(UnitProperties : TArray<byte>) : TAutoBrainOnUnitPropertyComponent;
      function MustNotHave(UnitProperties : TArray<byte>) : TAutoBrainOnUnitPropertyComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at dying and prevents it. Triggers eiFire on itself. </summary>
  TAutoBrainPreventDeathComponent = class(TAutoBrainComponent)
    published
      [XEvent(eiDie, epLower, etTrigger)]
      /// <summary> On dying fire at itself. </summary>
      function OnBeforeDie(KillerID, KillerCommanderID : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that triggers at buffremovement if type matches. Triggers eiFire on itself. </summary>
  TAutoBrainBuffComponent = class(TAutoBrainComponent)
    protected
      FBuffType : SetBuffType;
    published
      [XEvent(eiBuffed, epFirst, etRead)]
      /// <summary> Return Bufftype. </summary>
      function OnBuffed(Previous : RParam) : RParam;
      [XEvent(eiRemoveBuffs, epLast, etTrigger)]
      /// <summary> If matching fire. </summary>
      function OnRemoveBuff(Whitelist, Blacklist : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group, BuffTypes : TArray<byte>); reintroduce;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles welas which are applying effects on hit. On every eiFire, it
  /// sends an eiFire ot its firegroup. If eiWelaChance of Firegroup isn't empty, it only send the eiFire by a chance. </summary>
  TAutoBrainWelaOnHitEffectComponent = class(TAutoBrainComponent)
    published
      [XEvent(eiFire, epLast, etTrigger)]
      /// <summary> Refire in firegroup on target if chance passed.. </summary>
      function OnFire(Targets : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Metaclass for link effect brains. </summary>
  TLinkAutoBrainComponent = class(TBrainComponent)
    protected
      FFiresAtDestination, FFiresAtSource : boolean;
      FDestinationFireGroup, FSourceFireGroup, FCheckSourceForDestinationInGroup, FCheckDestinationForSourceInGroup : SetComponentGroup;
      /// <summary> Executes the set options for firing. </summary>
      procedure Fire;
      function TryGetSource(out Source : TEntity) : boolean;
      function TryGetDestination(out Destination : TEntity) : boolean;
    public
      /// <summary> Enables firing at the destination. Set target group for checks and fire. </summary>
      function FireAtDestinationInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
      /// <summary> Checks local group with source for firing at destination as well. </summary>
      function CheckSourceForDestinationInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
      /// <summary> Enables firing at the source. Set target group for checks and fire. </summary>
      function FireAtSourceInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
      /// <summary> Checks local group with destination for firing at source as well. </summary>
      function CheckDestinationForSourceInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Effect which fires (eiFire) at source if destination dies. </summary>
  TLinkAutoBrainOnDeathComponent = class(TLinkAutoBrainComponent)
    published
      function TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Hook destination for dying. </summary>
      function OnAfterCreate() : boolean;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Projectilebrains - handles brains of different projectiles
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> This projectile brain fires (eiFire) at the target as soon as it is set by eiWelaSavedTargets. </summary>
  TBrainWelaProjectileComponent = class(TBrainComponent)
    protected
      function ThinkChain : boolean; override;
    published
      [XEvent(eiWelaSavedTargets, epLast, etWrite)]
      /// <summary> Fires at target. </summary>
      function OnSetTarget(Targets : RParam) : boolean;
      [XEvent(eiThinkChain, epLast, etTrigger)]
      /// <summary> Handles targetless wela. </summary>
      function OnThinkChain() : boolean;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Commanderbrains - handles all commander welas, which are triggered by user input and so need specific handling
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Handles commander abilities. Set Fire-Events to targets selected by the commander.
  /// At the client the user selects a target for a spell and checks it locally, but only for displaying.
  /// Even if the client says no, if the user clicks the spell is tried to activate and so send to the server.
  /// Here this brain receive the order to use the ability (eiUseAbility), which firstly tests whether the action
  /// is valid (eiCanUseAbility). This tests for readyness (eiReady) and validity (eiWelaTargetPossible) of the target.
  /// Only if every test passes the ability is fired (eiFire) at the selected target. </summary>
  TBrainWelaCommanderComponent = class(TBrainComponent)
    protected
      FOverrideTargetToOwner : boolean;
      function CanUseAbility(Targets : ACommanderAbilityTarget) : boolean; virtual;
      procedure UseAbility(Targets : ACommanderAbilityTarget); virtual;
    published
      [XEvent(eiCanUseAbility, epLast, etRead)]
      /// <summary> Checks that the target is possible and the ability is ready. </summary>
      function OnCanRunAbility(Targets : RParam) : RParam;
      [XEvent(eiUseAbility, epMiddle, etTrigger)]
      /// <summary> Fire on target if ability can be run. </summary>
      function OnUseAbility(Targets : RParam) : boolean;
    public
      function OverrideTargetToOwner() : TBrainWelaCommanderComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Handles commander abilities, which establishes links between two targets selected by the commander.
  /// At the client the user selects the targets for a spell and checks it locally, but only for displaying.
  /// Even if the client says no, if the user clicks the spell is tried to activate and so send to the server.
  /// Here this brain receive the order to use the ability (eiUseAbility), which firstly tests whether the action
  /// is valid (eiCanUseAbility). This tests for readyness (eiReady) and validity (eiWelaTargetPossible) of the targets.
  /// Only if every test passes the link is established between the selected targets. </summary>
  TBrainLinkWelaCommanderComponent = class(TBrainWelaCommanderComponent)
    protected
      procedure UseAbility(Targets : ACommanderAbilityTarget); override;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Battlebrains - little freaky things, which want to see the world BURNING!
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> Sits on top of think chain and delays fire events to make time for animations to play. </summary>
  TBrainActionComponent = class(TBrainComponent)
    protected
      FTargets : ATarget;
      FFireGroup : SetComponentGroup;
      FEventHandler : TDelayedEventHandler;
      FLock : TTimer;
      FInFireHandling : boolean;
      procedure Fire;
      procedure CancelFire;
    published
      [XEvent(eiPreFire, epLast, etTrigger)]
      function OnPreFire(Targets : RParam) : boolean;
      [XEvent(eiThinkChain, epHigher, etTrigger)]
      function OnThinkChain() : boolean;
      [XEvent(eiExiled, epLast, etWrite)]
      function OnExiled(Exiled : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Masterclass of brains which have persistent targets. This class supports the basic
  /// functionality for a unit with n targets, where one is the main target. It uses a TWelaTargetingComponent for
  /// looking for targets (eiWelaUpdateTargets). </summary>
  TBrainTargetingWelaComponent = class abstract(TBrainWelaComponent)
    protected
      FCurrentTargets : TList<RTarget>;
      FPreemptive : boolean;
      /// <summary> Take care that no replacement will insert the target and may violate the maxtargetcount. </summary>
      procedure SetTarget(Index : integer; Target : RTarget; Replace : boolean = True); virtual;
      procedure RemoveTarget(Index : integer); virtual;
      procedure UpdateTargets();
    published
      [XEvent(eiWelaStop, epLast, etTrigger)]
      /// <summary> Clears all targets. </summary>
      function OnWelaStop() : boolean;
      [XEvent(eiWelaChangeTarget, epLast, etTrigger)]
      /// <summary> Change first target to this target if possible. </summary>
      function OnChangeTarget(Target : RParam) : boolean;
      [XEvent(eiGetCurrentTargets, epFirst, etRead)]
      /// <summary> Return the current set targets. </summary>
      function OnGetCurrentTargets(PrevValue : RParam) : RParam;
    public
      constructor CreateGrouped(Owner : TEntity; ControlledWelaID : TArray<byte>); override;
      /// <summary> Preemptive brains are blocking the think chain if there are possible targets. Also activates Blocking. </summary>
      function Preemptive : TBrainTargetingWelaComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> This brain is looking for enemies within weaponrange (determined by a TWelaTargetingComponent)
  /// and spawns and fire at them. If it is preemptive it breaks the thoughtchain if it has targets
  /// to be fired on. This brain it the default brain for nearly all our units.
  ///
  /// Preemptive - The default brain used for a main gun of an unit. Concentrate on the target(s) and stop all underlying
  /// brains (like movebrains) from thinking.
  /// Not Preemptive - A brain for asynchronous welas of an unit, like little guns on a tank which are not the main gun,
  /// which are firing independently of the unit.
  ///
  /// The think process:
  /// 1. Check for validity of all targets, remove invalid.
  /// 2. If we need new targets update targets with TWelaTargetingComponent
  /// 3a. If no targets are possible, let the next brain think.
  /// 3b. If there are targets, stand still and only let the next brain think if not preemptive.
  /// 3b.1. If weapon is ready (eiIsReady) fire (eiFire) at targets.
  /// </summary>
  TBrainWelaFightComponent = class(TBrainTargetingWelaComponent)
    protected
      FDisableTargetLock, FFireAtMyself, FWasActive : boolean;
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      /// <summary> Look for targets and shoot projectiles at them if ready. </summary>
      function OnThinkChain() : boolean;
    public
      function DisableTargetLock() : TBrainWelaFightComponent;
      function ChangeTargetToMyself() : TBrainWelaFightComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Brain that handles linkwelas. Currently curious implementation, TODO do it right!
  /// TWelaLinkEffectComponent does more than it should, targeting etc. should be done here. </summary>
  TBrainWelaLinkComponent = class(TBrainTargetingWelaComponent)
    protected
      const
      DEFAULT_LINK_BUILD_TIME = 250;
    var
      FLinkTimer : TTimer;
      FBuildReadyGroup : SetComponentGroup;
      procedure SetTarget(Index : integer; Target : RTarget; Replace : boolean); override;
      procedure RemoveTarget(Index : integer); override;
      function ThinkChain : boolean; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      /// <summary> Look for nearby targets, establish links on new targets. </summary>
      function OnThinkChain() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SetBuildCheckGroup(Group : TArray<byte>) : TBrainWelaLinkComponent;
      /// <summary> Time between building links. </summary>
      function LinkTime(Time : integer) : TBrainWelaLinkComponent;
      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals.Server;

{ TBrainWelaSelftargetGroundComponent }

function TBrainWelaSelftargetGroundComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainWelaSelftargetGroundComponent.ThinkChain : boolean;
var
  WeaponReady : boolean;
  OwnPosition : RVector2;
begin
  Result := True;
  WeaponReady := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
  if WeaponReady then
  begin
    // firing blocks the chain, so we have to break here
    if FBlocking then
    begin
      Eventbus.Trigger(eiStand, []);
      Result := False;
    end;
    OwnPosition := Owner.Position;
    Eventbus.Trigger(FFireEvent, [ATarget.Create(OwnPosition).ToRParam], ComponentGroup);
  end;
end;

{ TThinkImpulseImmediateComponent }

function TThinkImpulseImmediateComponent.OnIdle : boolean;
begin
  Result := True;
  if not Eventbus.Read(eiExiled, []).AsBoolean then
  begin
    Eventbus.Trigger(eiThink, [], ComponentGroup);
    Eventbus.Trigger(eiThinkChain, [], ComponentGroup);
  end;
end;

{ TBrainWelaComponent }

function TBrainWelaComponent.Blocking : TBrainWelaComponent;
begin
  Result := self;
  FBlocking := True;
  FFireEvent := eiPreFire;
end;

constructor TBrainWelaComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FFireEvent := eiFire;
end;

{ TBrainTargetingWelaComponent }

constructor TBrainTargetingWelaComponent.CreateGrouped(Owner : TEntity; ControlledWelaID : TArray<byte>);
begin
  inherited CreateGrouped(Owner, ControlledWelaID);
  FPreemptive := False;
  FFireEvent := eiFire;
  ChangeEventPriority(eiThinkChain, etTrigger, epHigh);
  FCurrentTargets := TList<RTarget>.Create(
    TComparer<RTarget>.Construct(
    function(const L, R : RTarget) : integer
    begin
      if L = R then
          Result := 0
      else Result := 1;
    end
    )
    );
end;

destructor TBrainTargetingWelaComponent.Destroy;
begin
  FCurrentTargets.Free;
  inherited;
end;

function TBrainTargetingWelaComponent.Preemptive : TBrainTargetingWelaComponent;
begin
  Result := self;
  FPreemptive := True;
  FFireEvent := eiPreFire;
  // increase priority of non-preemptive brains to trigger before
  ChangeEventPriority(eiThinkChain, etTrigger, epMiddle);
end;

function TBrainTargetingWelaComponent.OnChangeTarget(Target : RParam) : boolean;
var
  Possible : RParam;
begin
  Result := True;
  Possible := Eventbus.Read(eiWelaValidateTarget, [Target], ComponentGroup);
  if Possible.IsEmpty or Possible.AsBoolean then
  begin
    SetTarget(0, Target.AsType<RTarget>, True);
  end;
end;

function TBrainTargetingWelaComponent.OnGetCurrentTargets(PrevValue : RParam) : RParam;
begin
  if PrevValue.IsEmpty then Result := TList<RTarget>.Create()
  else Result := PrevValue;
  Result.AsType < TList < RTarget >>.AddRange(FCurrentTargets);
end;

function TBrainTargetingWelaComponent.OnWelaStop : boolean;
var
  i : integer;
begin
  Result := True;
  for i := FCurrentTargets.Count - 1 downto 0 do RemoveTarget(i);
end;

procedure TBrainTargetingWelaComponent.RemoveTarget(Index : integer);
begin
  if FCurrentTargets.Count > index then FCurrentTargets.Delete(index);
  // no more valid target exists? inform everybody about
  if FCurrentTargets.Count <= 0 then Eventbus.Trigger(eiWelaSetMainTarget, [RTarget.CreateEmpty], ComponentGroup);
end;

procedure TBrainTargetingWelaComponent.SetTarget(Index : integer; Target : RTarget; Replace : boolean);
begin
  if index = 0 then Eventbus.Trigger(eiWelaSetMainTarget, [Target], ComponentGroup);
  if FCurrentTargets.Count > index then
  begin
    if Replace then FCurrentTargets[index] := Target
    else FCurrentTargets.Insert(index, Target);
  end
  else FCurrentTargets.Add(Target);
end;

procedure TBrainTargetingWelaComponent.UpdateTargets;
var
  MaxTargets : integer;
begin
  // if not enough targets, we are searching for more
  Eventbus.Trigger(eiWelaUpdateTargets, [FCurrentTargets], ComponentGroup);
  // if our target count shrunk, we may have too many targets at this point, so we have to check them
  MaxTargets := Max(0, Eventbus.Read(eiWelaTargetCount, [], ComponentGroup).AsIntegerDefault(1));
  while MaxTargets < FCurrentTargets.Count do
      RemoveTarget(FCurrentTargets.Count - 1);
  // the first of our targets is our main target
  if FCurrentTargets.Count > 0 then Eventbus.Trigger(eiWelaSetMainTarget, [FCurrentTargets.First], ComponentGroup);
end;

{ TBrainWelaCommanderComponent }

function TBrainWelaCommanderComponent.CanUseAbility(Targets : ACommanderAbilityTarget) : boolean;
begin
  Result := Game.IsSandbox or Eventbus.Read(eiWelaTargetPossible, [Targets.ToRTargets(Owner).ToRParam], CurrentEvent.CalledToGroup).AsRTargetValidity.IsValid;
end;

function TBrainWelaCommanderComponent.OnCanRunAbility(Targets : RParam) : RParam;
var
  Res : boolean;
  Targ : ACommanderAbilityTarget;
  TargetCount : integer;
begin
  if not CanThink then exit(False);
  Result := Eventbus.Read(eiIsReady, [], CurrentEvent.CalledToGroup);
  if Result.AsBooleanDefaultTrue or Game.IsSandbox then
  begin
    TargetCount := Max(1, Eventbus.Read(eiAbilityTargetCount, [], CurrentEvent.CalledToGroup).AsInteger);
    Targ := Targets.AsACommanderAbilityTarget;
    if length(Targ) < TargetCount then exit(False);
    // truncate unneeded targets
    setLength(Targ, TargetCount);
    Res := CanUseAbility(Targ);
    Result := Res;
  end;
end;

function TBrainWelaCommanderComponent.OnUseAbility(Targets : RParam) : boolean;
begin
  if Eventbus.Read(eiCanUseAbility, [Targets], CurrentEvent.CalledToGroup).AsBoolean then
  begin
    Result := True;
    if FOverrideTargetToOwner then
    begin
      UseAbility(ACommanderAbilityTarget.Create(RCommanderAbilityTarget.Create(Owner)));
    end
    else
    begin
      UseAbility(Targets.AsACommanderAbilityTarget);
    end;
  end
  else Result := False;
end;

function TBrainWelaCommanderComponent.OverrideTargetToOwner : TBrainWelaCommanderComponent;
begin
  Result := self;
  FOverrideTargetToOwner := True;
end;

procedure TBrainWelaCommanderComponent.UseAbility(Targets : ACommanderAbilityTarget);
var
  TargetCount : integer;
begin
  TargetCount := Max(1, Eventbus.Read(eiAbilityTargetCount, [], CurrentEvent.CalledToGroup).AsInteger);
  assert(TargetCount = length(Targets), 'TBrainWelaCommanderComponent.UseAbility: Inconsistent data, expect same target count specified and given!');
  Eventbus.Trigger(eiFire, [Targets.ToRTargets(Owner).ToRParam], CurrentEvent.CalledToGroup);
end;

{ TBrainLinkWelaCommanderComponent }

procedure TBrainLinkWelaCommanderComponent.UseAbility(Targets : ACommanderAbilityTarget);
var
  SkinID : string;
begin
  if length(Targets) < 2 then exit;
  SkinID := Owner.GetSkinID(ComponentGroup);
  ServerGame.ServerEntityManager.SpawnUnitRaw(
    Eventbus.Read(eiLinkPattern, [], ComponentGroup).AsString,
    procedure(Entity : TEntity)
    begin
      Entity.Eventbus.Write(eiOwnerCommander, [FOwner.ID]);
      Entity.Eventbus.Write(eiTeamID, [Owner.TeamID]);
      Entity.Position := RVector2.ZERO;
      Entity.Front := RVector2.UNITY;
      Entity.Eventbus.Write(eiCreator, [FOwner.ID]);
      Entity.Eventbus.Write(eiLinkSource, [ATarget.Create(Targets[0].ToRTarget(Owner)).ToRParam]);
      Entity.Eventbus.Write(eiLinkDest, [ATarget.Create(Targets[1].ToRTarget(Owner)).ToRParam]);

      Entity.SkinID := SkinID;
      Entity.Blackboard.SetValue(eiSkinIdentifier, [], SkinID);
    end);
end;

{ TBrainWelaSelftargetComponent }

function TBrainWelaSelftargetComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainWelaSelftargetComponent.ThinkChain : boolean;
begin
  Result := True;
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
  begin
    if Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(self.FOwner).ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
    begin
      // firing blocks the chain, so we have to break here
      if FBlocking then
      begin
        Eventbus.Trigger(eiStand, []);
        Result := False;
      end;
      Eventbus.Trigger(FFireEvent, [ATarget.Create(self.FOwner).ToRParam], ComponentGroup);
    end;
  end;
end;

{ TBrainWaitComponent }

function TBrainWaitComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainWaitComponent.ThinkChain : boolean;
var
  TargetList : TList<RTarget>;
begin
  Result := True;

  TargetList := TList<RTarget>.Create;
  // Look for Enemy to approach at, done every thinkframe, because other entities can pass current target
  Eventbus.Trigger(eiWelaUpdateTargets, [TargetList], ComponentGroup);
  // stand still if enemy in weaponrange
  if (TargetList.Count > 0) then
  begin
    if Eventbus.Read(eiIsMoving, []).AsBoolean then
        Eventbus.Trigger(eiStand, []);
    Result := False;
  end;
  TargetList.Free;
end;

{ TBrainWelaTargetlessComponent }

function TBrainWelaTargetlessComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainWelaTargetlessComponent.ThinkChain : boolean;
var
  WeaponReady : boolean;
begin
  Result := True;
  WeaponReady := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
  if WeaponReady then
  begin
    // firing blocks the chain, so we have to break here
    if FBlocking then
    begin
      Eventbus.Trigger(eiStand, []);
      Result := False;
    end;
    Eventbus.Trigger(FFireEvent, [ATarget.CreateEmpty().ToRParam], ComponentGroup);
  end;
end;

{ TBrainWelaLinkComponent }

constructor TBrainWelaLinkComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FLinkTimer := TTimer.Create(DEFAULT_LINK_BUILD_TIME);
  FBuildReadyGroup := ComponentGroup;
end;

destructor TBrainWelaLinkComponent.Destroy;
begin
  FLinkTimer.Free;
  inherited;
end;

function TBrainWelaLinkComponent.LinkTime(Time : integer) : TBrainWelaLinkComponent;
begin
  Result := self;
  FLinkTimer.SetIntervalAndStart(Time);
end;

function TBrainWelaLinkComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

procedure TBrainWelaLinkComponent.RemoveTarget(Index : integer);
begin
  if (FCurrentTargets.Count > index) then Eventbus.Trigger(eiLinkBreak, [FCurrentTargets[index]], ComponentGroup);
  inherited;
end;

function TBrainWelaLinkComponent.SetBuildCheckGroup(Group : TArray<byte>) : TBrainWelaLinkComponent;
begin
  Result := self;
  FBuildReadyGroup := ByteArrayToComponentGroup(Group);
end;

procedure TBrainWelaLinkComponent.SetTarget(Index : integer; Target : RTarget; Replace : boolean);
begin
  if not FCurrentTargets.Contains(Target) then
  begin
    RemoveTarget(index);
    Eventbus.Trigger(eiFire, [ATarget.Create(Target).ToRParam], ComponentGroup);
    inherited SetTarget(index, Target, False);
  end;
end;

function TBrainWelaLinkComponent.ThinkChain : boolean;
var
  BuildReady, WeaponReady : boolean;
  i : integer;
begin
  // is the weapon ready to shoot, if not break all links
  WeaponReady := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;

  // check current targets, if not valid break the link
  for i := FCurrentTargets.Count - 1 downto 0 do
    if not WeaponReady or not Eventbus.Read(eiWelaValidateTarget, [FCurrentTargets[i]], ComponentGroup).AsBoolean then
    begin
      RemoveTarget(i);
    end;

  BuildReady := FLinkTimer.Expired and Eventbus.Read(eiIsReady, [], FBuildReadyGroup).AsBooleanDefaultTrue;

  if WeaponReady and ((FCurrentTargets.Count <= 0) or BuildReady) then UpdateTargets;
  if (FCurrentTargets.Count <= 0) then exit(True);

  Result := not FPreemptive;
  if not Result then Eventbus.Trigger(eiStand, []);

  if BuildReady then
  begin
    Eventbus.Trigger(eiFire, [ATarget(FCurrentTargets.ToArray).ToRParam], ComponentGroup + FBuildReadyGroup);
    FLinkTimer.Start;
  end;
end;

{ TBrainWelaFightComponent }

function TBrainWelaFightComponent.ChangeTargetToMyself : TBrainWelaFightComponent;
begin
  Result := self;
  FFireAtMyself := True;
end;

function TBrainWelaFightComponent.DisableTargetLock : TBrainWelaFightComponent;
begin
  Result := self;
  FDisableTargetLock := True;
end;

function TBrainWelaFightComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainWelaFightComponent.ThinkChain : boolean;
var
  AtLeastOneTargetOk, WeaponReady : boolean;
  i : integer;
  Target : RParam;
begin
  // check current targets, whether there is at least one valid target
  AtLeastOneTargetOk := False;
  for i := FCurrentTargets.Count - 1 downto 0 do
    if Eventbus.Read(eiWelaValidateTarget, [FCurrentTargets[i]], ComponentGroup).AsBoolean then
        AtLeastOneTargetOk := True
    else
        RemoveTarget(i);
  WeaponReady := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
  // search for targets in attackrange if targets are not ok or Weapon is ready
  // search for new targets if weapon not ready to prevent walking although a target is in range
  if not AtLeastOneTargetOk or WeaponReady then UpdateTargets;

  // no valid targets in range, let next brain think (and walk to next target)
  if (FCurrentTargets.Count <= 0) then
  begin
    FWasActive := False;
    exit(True);
  end;
  Result := not FPreemptive;
  // if wela is preemptive and there are targets, we stand to wait for activation, but only if not already waiting
  if not FWasActive and FPreemptive then Eventbus.Trigger(eiStand, []);
  // Fire!
  if WeaponReady then
  begin
    // if wela is blocking we want to stand on fire as afterwards the thinking is blocked
    if not FWasActive and not FPreemptive and FBlocking then Eventbus.Trigger(eiStand, []);

    if FFireAtMyself then
    begin
      Target := ATarget.Create(FOwner).ToRParam;
      for i := 0 to FCurrentTargets.Count - 1 do
          Eventbus.Trigger(FFireEvent, [Target], ComponentGroup)
    end
    else
        Eventbus.Trigger(FFireEvent, [ATarget(FCurrentTargets.ToArray).ToRParam], ComponentGroup);

    if FDisableTargetLock then
      for i := FCurrentTargets.Count - 1 downto 0 do RemoveTarget(i);

    // if this wela is blocking, we have to interrupt think chain after firing to prevent other welas to cancel action
    if FBlocking then Result := False;
  end;
  FWasActive := not Result;
end;

{ TThinkImpulseTimerComponent }

constructor TThinkImpulseTimerComponent.CreateGrouped(Owner : TEntity;
Group :
  TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FThinkTimer := TTimer.CreateAndStart(THINK_TIME_INTERVAL);
end;

destructor TThinkImpulseTimerComponent.Destroy;
begin
  FThinkTimer.Free;
  inherited;
end;

function TThinkImpulseTimerComponent.OnIdle : boolean;
var
  Alive : RParam;
begin
  Result := True;
  if not Eventbus.Read(eiExiled, []).AsBoolean then
  begin
    Alive := Eventbus.Read(eiIsAlive, []);
    if FThinkTimer.Expired and (Alive.IsEmpty or Alive.AsBoolean) then
    begin
      Eventbus.Trigger(eiThink, [], ComponentGroup);
      Eventbus.Trigger(eiThinkChain, [], ComponentGroup);
      FThinkTimer.Start;
    end;
  end;
end;

function TThinkImpulseTimerComponent.OnMoveTargetReached : boolean;
begin
  Result := True;
  FThinkTimer.Expired := True;
end;

{ TBrainFollowLaneComponent }

procedure TBrainFollowLaneComponent.AcquireLane;
begin
  Game.Map.Lanes.GetLanePropertiesOfEntity(self.Owner, @FLane, @FLaneDirection);
end;

function TBrainFollowLaneComponent.OnAfterCreate : boolean;
begin
  Result := True;
  AcquireLane;
end;

function TBrainFollowLaneComponent.OnExiled(Exiled : RParam) : boolean;
begin
  Result := True;
  if not Exiled.AsBoolean then AcquireLane;
end;

function TBrainFollowLaneComponent.OnGetLane : RParam;
begin
  Result := RParam.From<TLane>(FLane);
end;

function TBrainFollowLaneComponent.OnGetLaneDirection : RParam;
begin
  Result := RParam.From<EnumLaneDirection>(FLaneDirection);
end;

function TBrainFollowLaneComponent.OnMoveTargetReached : boolean;
begin
  Result := True;
  FMoving := False;
end;

function TBrainFollowLaneComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainFollowLaneComponent.ThinkChain : boolean;
var
  Next : RTarget;
  opponentNexus : TEntity;
  Position : RVector2;
  Range : single;
begin
  Result := False;
  if not FMoving and CanMove then
  begin
    Position := Owner.Position;
    if Game.EntityManager.TryGetNexusNextEnemy(Owner, opponentNexus) then
        Next := RTarget.Create(opponentNexus)
    else
        exit; // there is no enemy nexus, so stand still

    Range := Owner.CollisionRadius;

    Eventbus.Trigger(eiMoveTo, [Next, Range]);
    // don't think about our move target until it's really needed
    FMoving := True;
  end;
end;

{ TBrainApproachComponent }

function TBrainApproachComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainApproachComponent.ThinkChain : boolean;
const
  ERROR_EPSILON = 0.1;
var
  TargetList : TList<RTarget>;
  Range : single;
begin
  Result := True;
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
  begin
    TargetList := TList<RTarget>.Create;
    // Look for Enemy to approach at, done every frame, because other entities can pass current target
    Eventbus.Trigger(eiWelaUpdateTargets, [TargetList], ComponentGroup);
    // approach to enemy in weaponrange
    if (TargetList.Count > 0) then
    begin
      Result := False;
      // approach correctly to the border of the enemy (+0.1 rounding fix)
      Range := Eventbus.Read(eiWelaRange, [], ComponentGroup).AsSingle + Owner.CollisionRadius;
      if TargetList.First.IsEntity then
          Range := Range + TargetList.First.GetTargetEntity.CollisionRadius;
      Range := Range - ERROR_EPSILON;
      if CanMove then
      begin
        if (Range < TargetList.First.GetTargetPosition.Distance(Owner.Position)) then
        begin
          Eventbus.Trigger(eiMoveTo, [TargetList.First, Range]);
          FApproaching := True;
        end
        else
        begin
          if FApproaching then Eventbus.Trigger(eiStand, []);
          FApproaching := False;
        end;
      end;
    end
    else
    begin
      if FApproaching then Eventbus.Trigger(eiStand, []);
      FApproaching := False;
    end;
    TargetList.Free;
  end
  else
  begin
    if FApproaching then Eventbus.Trigger(eiStand, []);
    FApproaching := False;
  end;
end;

{ TBrainWelaProjectileComponent }

function TBrainWelaProjectileComponent.OnSetTarget(Targets : RParam) : boolean;
begin
  Result := True;
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
  begin
    Eventbus.Trigger(eiFire, [Targets]);
  end;
end;

function TBrainWelaProjectileComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainWelaProjectileComponent.ThinkChain : boolean;
begin
  Result := True;
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
  begin
    Eventbus.Trigger(eiFire, [Eventbus.Read(eiWelaSavedTargets, [])], ComponentGroup);
  end;
end;

{ TAutoBrainWelaInstantChainComponent }

function TAutoBrainWelaInstantChainComponent.OnSetTarget(Target : RParam) : boolean;
// var
// pos : RVector2;
// range : single;
// TargetCount, TeamID : integer;
// Targets : TArray<integer>;
// i : integer;
// NextTarget : TEntity;
// Filter : ProcEntityFilterFunction;
// Target : RTarget;
begin
  raise ENotImplemented.Create('TAutoBrainWelaInstantChainComponent: Not working atm.');
  // Result := True;
  // if not CanThink then exit;
  // Target := ATarget.AsType<RTarget>;
  // TargetCount := Eventbus.Read(eiWelaTargetCount, [], ComponentGroup).AsInteger;
  // Targets := HArray.Generate<integer>(TargetCount, -1);
  //
  // // range := Eventbus.Read(eiWelaAreaOfEffect, [], ComponentGroup).AsSingle;
  // // TeamID := Eventbus.Read(eiTeamID).AsInteger;
  // Filter := function(Entity : TEntity) : boolean
  // var
  // j : integer;
  // begin
  // for j := 0 to length(Targets) - 1 do
  // if Entity.ID = Targets[j] then exit(False);
  // Result := Eventbus.Read(eiWelaTargetPossible, [RTarget.Create(Entity)], ComponentGroup).AsBoolean;
  // end;
  //
  // for i := 0 to TargetCount - 1 do
  // begin
  // Eventbus.Trigger(eiFire, [Target], ComponentGroup);
  // if Target.IsEntity then Targets[i] := Target.EntityID;
  // // look sequential for targets, starting at MainTarget
  // pos := Target.GetTargetPosition.XZ;
  // NextTarget := GlobalEventbus.Read(eiClosestEntityInRange, [
  // pos,
  // range,
  // TeamID,
  // RParam.From<EnumTargetTeamConstraint>(tcAll),
  // RParam.FromProc<ProcEntityFilterFunction>(Filter)]).AsType<TEntity>;
  // if not assigned(NextTarget) then break;
  // Target := RTarget.Create(NextTarget);
  // end;
end;

{ TAutoBrainKillLinkComponent }

function TAutoBrainKillLinkComponent.OnAfterCreate : boolean;
var
  Source, Destination : ATarget;
  Entity : TEntity;
begin
  Result := True;
  Source := Eventbus.Read(eiLinkSource, []).AsATarget;
  Destination := Eventbus.Read(eiLinkDest, []).AsATarget;
  assert(Source.Count = 1);
  assert(Destination.Count = 1);
  if Source[0].TryGetTargetEntity(Entity) then
      Entity.Eventbus.SubscribeRemote(eiDie, etTrigger, epLast, self, 'TargetOnDie', 2);
  if Destination[0].TryGetTargetEntity(Entity) then
      Entity.Eventbus.SubscribeRemote(eiDie, etTrigger, epLast, self, 'TargetOnDie', 2);
end;

function TAutoBrainKillLinkComponent.TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  GlobalEventbus.Trigger(eiDelayedKillEntity, [FOwner.ID]);
end;

{ TThinkImpulseGameTickComponent }

function TThinkImpulseGameTickComponent.OnGameTick : boolean;
begin
  Result := True;
  if not Eventbus.Read(eiExiled, []).AsBoolean then
  begin
    Eventbus.Trigger(eiThink, [], ComponentGroup);
    Eventbus.Trigger(eiThinkChain, [], ComponentGroup);
  end;
end;

{ TBrainWelaTargetCommanderComponent }

function TBrainWelaTargetCommanderComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainWelaTargetCommanderComponent.ThinkChain : boolean;
begin
  Result := True;
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(self.FOwner).ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
  begin
    Eventbus.Trigger(eiFire, [ATarget.Create(Eventbus.Read(eiOwnerCommander, []).AsInteger).ToRParam], ComponentGroup);
  end;
end;

{ TAutoBrainWelaTargetProducedUnitComponent }

function TAutoBrainWelaTargetProducedUnitComponent.FireOnlyAtUnitsInOwnGroup : TAutoBrainWelaTargetProducedUnitComponent;
begin
  Result := self;
  FOnlyOwnGroup := True;
end;

function TAutoBrainWelaTargetProducedUnitComponent.OnWelaUnitProduced(EntityID : RParam) : boolean;
begin
  Result := True;
  if not CanThink or (FOnlyOwnGroup and (ComponentGroup * CurrentEvent.CalledToGroup = [])) then exit;
  if Eventbus.Read(eiIsReady, [], FFireGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(EntityID.AsInteger).ToRParam], FFireGroup).AsRTargetValidity.IsValid then
      Eventbus.Trigger(eiFire, [ATarget.Create(EntityID.AsInteger).ToRParam], FFireGroup);
end;

{ TAutoBrainWelaOnHitEffectComponent }

function TAutoBrainWelaOnHitEffectComponent.OnFire(Targets : RParam) : boolean;
var
  Chance : RParam;
begin
  Result := True;
  if not CanThink or not Eventbus.Read(eiIsReady, [], FFireGroup).AsBooleanDefaultTrue then exit;
  Chance := Eventbus.Read(eiWelaChance, [], FFireGroup);
  if Chance.IsEmpty or (random <= Chance.AsSingle) then
  begin
    if Eventbus.Read(eiWelaTargetPossible, [Targets], FFireGroup).AsRTargetValidity.IsValid then
        Eventbus.Trigger(eiFire, [Targets], FFireGroup);
  end;
end;

{ TThinkImpulseTimerCooldownComponent }

constructor TThinkImpulseTimerCooldownComponent.CreateGrouped(Owner : TEntity;
Group :
  TArray<byte>);
var
  Interval : RParam;
begin
  inherited CreateGrouped(Owner, Group);
  Interval := Eventbus.Read(eiCooldown, [], ComponentGroup);
  assert(not Interval.IsEmpty, 'TThinkImpulseTimerCooldownComponent.CreateGrouped: This component needs an interval in eiCooldown!');
  FThinkTimer := TTimer.CreateAndStart(Interval.AsInteger);
end;

destructor TThinkImpulseTimerCooldownComponent.Destroy;
begin
  FThinkTimer.Free;
  inherited;
end;

function TThinkImpulseTimerCooldownComponent.Once : TThinkImpulseTimerCooldownComponent;
begin
  Result := self;
  FOnce := True;
end;

function TThinkImpulseTimerCooldownComponent.OnIdle : boolean;
begin
  Result := True;
  if FThinkTimer.Expired and (not FOnce or not FFired) then
  begin
    Eventbus.Trigger(eiThink, [], ComponentGroup);
    Eventbus.Trigger(eiThinkChain, [], ComponentGroup);
    FThinkTimer.Start;
    FFired := True;
  end;
end;

function TThinkImpulseTimerCooldownComponent.TimerIsReady : TThinkImpulseTimerCooldownComponent;
begin
  Result := self;
  FThinkTimer.Expired := True;
end;

{ TBrainProjectileComponent }

function TBrainProjectileComponent.Bounces(TargetGroup : TArray<byte>) : TBrainProjectileComponent;
begin
  Result := self;
  FBounces := True;
  FBounceTargetGroup := ByteArrayToComponentGroup(TargetGroup);
end;

function TBrainProjectileComponent.CantBeReflected : TBrainProjectileComponent;
begin
  Result := self;
  FNoReflection := True;
end;

destructor TBrainProjectileComponent.Destroy;
begin
  FDelayedEvent.Free;
  inherited;
end;

function TBrainProjectileComponent.DieWithTarget : TBrainProjectileComponent;
begin
  Result := self;
  FDieWithTarget := True;
end;

function TBrainProjectileComponent.FireAtTarget(Targets : ATarget) : boolean;
var
  i : integer;
  TargetEntity : TEntity;
begin
  // fire only if all tests passes
  Result := (not(upProjectileWillMiss in Owner.UnitProperties)) and
    (FNoTargetChecks or (Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [Targets.ToRParam], ComponentGroup).AsRTargetValidity.IsValid));
  if Result then
  begin
    Eventbus.Trigger(eiFire, [Targets.ToRParam], ComponentGroup);
    for i := 0 to Targets.Count - 1 do
      if Targets[i].TryGetTargetEntity(TargetEntity) then
          TargetEntity.Eventbus.Trigger(eiWelaHitByProjectile, [Owner]);
  end;
end;

procedure TBrainProjectileComponent.InitiateOnSavedTarget;
var
  CurrentTargets : ATarget;
begin
  CurrentTargets := Eventbus.Read(eiWelaSavedTargets, []).AsATarget;
  if CurrentTargets.Count > 0 then
      Eventbus.Trigger(eiMoveTo, [CurrentTargets.First, 0.0]);
end;

function TBrainProjectileComponent.NoTargetChecks : TBrainProjectileComponent;
begin
  Result := self;
  FNoTargetChecks := True;
end;

function TBrainProjectileComponent.OnMoveTargetReached : boolean;
var
  Hit : boolean;
  CurrentTargets, HitTargets : ATarget;
  TargetList : TList<RTarget>;
  i : integer;
  ReflectingEntity, Creator : TEntity;
begin
  Result := True;
  if not FOnlyFollowing then
  begin
    CurrentTargets := Eventbus.Read(eiWelaSavedTargets, []).AsATarget;
    Hit := FireAtTarget(CurrentTargets);

    // if target reflects projectiles apply it here
    if Hit and not FNoReflection then
    begin
      for i := 0 to CurrentTargets.Count - 1 do
        if CurrentTargets[i].TryGetTargetEntity(ReflectingEntity) and
          (ReflectingEntity.TeamID <> Owner.TeamID) and
          ReflectingEntity.HasUnitProperty(upProjectileReflector) then
        begin
          // reflect projectile to creator, it changes team id to the reflectors one
          if Game.EntityManager.TryGetEntityByID(Eventbus.Read(eiCreator, []).AsInteger, Creator) then
          begin
            FNoReflection := True;
            Owner.Eventbus.Write(eiTeamID, [ReflectingEntity.TeamID]);
            CurrentTargets := ATarget.Create(Creator);
            Eventbus.Write(eiWelaSavedTargets, [CurrentTargets.ToRParam]);
            FDelayedEvent.Free;
            FDelayedEvent := TDelayedEventHandler.Create(InitiateOnSavedTarget);
            FDelayedEvent.RegisterEvent(0);
          end
          else
              SelfDestruct;
          exit;
        end;
    end;

    // apply bouncing
    if Hit and FBounces and IsWelaReady and (FBounceCount < Eventbus.Read(eiWelaCount, [], ComponentGroup).AsInteger) then
    begin
      // add all targets hit to the blacklist, so it won't bounce to them again
      HitTargets := Eventbus.Read(eiWelaSavedTargets, [], FBounceTargetGroup).AsATarget;
      HitTargets.Append(CurrentTargets);
      Eventbus.Write(eiWelaSavedTargets, [HitTargets.ToRParam], FBounceTargetGroup);
      // now search for targets
      TargetList := TList<RTarget>.Create;
      Eventbus.Trigger(eiWelaUpdateTargets, [TargetList], FBounceTargetGroup);
      // if targets found, set new target, else kill projectile
      if TargetList.Count > 0 then
      begin
        CurrentTargets := ATarget.Create(TargetList.First);
        Eventbus.Write(eiWelaSavedTargets, [CurrentTargets.ToRParam]);
        inc(FBounceCount);
        FDelayedEvent.Free;
        FDelayedEvent := TDelayedEventHandler.Create(InitiateOnSavedTarget);
        FDelayedEvent.RegisterEvent(0);
      end
      else SelfDestruct;
      TargetList.Free;
    end
    else
        SelfDestruct;
  end;
end;

function TBrainProjectileComponent.OnAfterCreate() : boolean;
var
  Targets : ATarget;
  Targeti : RTarget;
  TargetEntity : TEntity;
begin
  Result := True;
  Targets := Eventbus.Read(eiWelaSavedTargets, []).AsATarget;
  if Targets.Count <> 1 then
      MakeException('.OnSetTarget: Projectiles expect exactly one target!');
  Targeti := Targets[0];
  if Targeti.IsEntity and FNotHoming then
  begin
    Targeti := RTarget.Create(Targeti.GetTargetPosition);
    Targets[0] := Targeti;
    // save targets as we changed the first to a ground target
    Eventbus.Write(eiWelaSavedTargets, [Targets.ToRParam]);
  end;
  // if target is empty or not valid, we stifle the projectile as it would be never spawned
  if Targeti.IsEmpty or (Targeti.IsEntity and not Targeti.IsEntityValid) then SelfDestruct
  else
  begin
    if FInstant then
    begin
      // if spell should explode instant, don't move to target
      FireAtTarget(Targets);
      SelfDestruct;
    end
    else
    begin
      // fill RTarget position cache, if unit dies in this frame
      Targeti.GetTargetPosition;
      Eventbus.Trigger(eiMoveTo, [Targeti, 0.0]);
      if FDieWithTarget and Targeti.IsEntity and Targeti.TryGetTargetEntity(TargetEntity) then
      begin
        TargetEntity.Eventbus.SubscribeRemote(eiDie, etTrigger, epLast, self, 'TargetOnDie', 2);
      end;
    end;
  end;
end;

function TBrainProjectileComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

procedure TBrainProjectileComponent.SelfDestruct;
begin
  GlobalEventbus.Trigger(eiDelayedKillEntity, [FOwner.ID]);
end;

function TBrainProjectileComponent.SetInstant : TBrainProjectileComponent;
begin
  Result := self;
  FInstant := True;
end;

function TBrainProjectileComponent.SetNotFollowingTarget : TBrainProjectileComponent;
begin
  Result := self;
  FNotHoming := True;
end;

function TBrainProjectileComponent.SetOnlyFollowing : TBrainProjectileComponent;
begin
  FOnlyFollowing := True;
  Result := self;
end;

function TBrainProjectileComponent.TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  Eventbus.Trigger(eiDie, [-1, -1]);
end;

function TBrainProjectileComponent.ThinkChain : boolean;
begin
  Result := True;
  if FOnlyFollowing then
  begin
    Eventbus.Trigger(eiMoveTo, [Eventbus.Read(eiWelaSavedTargets, []).AsATarget.First, 0.0]);
  end;
end;

{ TAutoBrainOnKillComponent }

function TAutoBrainOnKillComponent.FireAtMyself : TAutoBrainOnKillComponent;
begin
  Result := self;
  FFireAtMyself := True;
end;

function TAutoBrainOnKillComponent.OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
var
  Target : ATarget;
begin
  Result := True;
  if not CanThink then exit;
  if FFireAtMyself then Target := ATarget.Create(FOwner)
  else Target := ATarget.Create(KilledUnitID.AsInteger);
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [Target.ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
      Eventbus.Trigger(eiFire, [Target.ToRParam], ComponentGroup);
end;

{ TBrainComponent }

function TBrainComponent.CanMove : boolean;
begin
  Result := Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> * UNIT_PROPERTIES_PREVENT_MOVEMENT = [];
end;

function TBrainComponent.CanThink : boolean;
begin
  Result := FPassiveThinking or (Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> * UNIT_PROPERTIES_PREVENT_THINKING = []);
  Result := Result and Eventbus.Read(eiWelaActive, [], ComponentGroup).AsBooleanDefaultTrue;
  Result := Result and (not FThinkLocal or IsLocalCall);
end;

procedure TBrainComponent.FireWithChecks(const Targets : ATarget);
begin
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [Targets.ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
  begin
    Eventbus.Trigger(eiFire, [Targets.ToRParam], ComponentGroup);
  end;
end;

function TBrainComponent.IsWelaReady : boolean;
begin
  Result := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
end;

function TBrainComponent.OnThink : boolean;
begin
  Result := ThinkEvent
end;

procedure TBrainComponent.Think;
begin

end;

function TBrainComponent.ThinkChain : boolean;
begin
  Result := True;
end;

function TBrainComponent.ThinkChainEvent : boolean;
begin
  Result := True;
  // Only call think if we are allowed and not passive thinking as then thinking is called in OnThink
  if CanThink and not FPassiveThinking and not FPassiveThinkingIfConscious then
      Result := ThinkChain;
end;

function TBrainComponent.ThinkEvent : boolean;
begin
  Result := True;
  if CanThink then
  begin
    Think;
    if FPassiveThinking or FPassiveThinkingIfConscious then ThinkChain;
  end;
end;

function TBrainComponent.ThinksInExile : TBrainComponent;
begin
  Result := self;
  FThinkInExile := True;
end;

function TBrainComponent.ThinksLocal : TBrainComponent;
begin
  Result := self;
  FThinkLocal := True;
end;

function TBrainComponent.ThinksPassively : TBrainComponent;
begin
  FPassiveThinking := True;
  Result := self;
end;

function TBrainComponent.ThinksPassivelyIfConscious : TBrainComponent;
begin
  Result := self;
  FPassiveThinkingIfConscious := True;
end;

{ TAutoBrainComponent }

procedure TAutoBrainComponent.CheckAndFire;
begin
  CheckAndFire(ATarget.Create(FOwner));
end;

procedure TAutoBrainComponent.CheckAndFire(DefaultTargets : ATarget);
begin
  if CanThink and
    Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    (FThinkInExile or not Eventbus.Read(eiExiled, []).AsBoolean) then
  begin
    Fire(DefaultTargets)
  end;
end;

constructor TAutoBrainComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FPassiveThinking := True;
  FFireGroup := ComponentGroup;
end;

procedure TAutoBrainComponent.Fire;
begin
  Fire(ATarget.Create(FOwner));
end;

procedure TAutoBrainComponent.Fire(DefaultTargets : ATarget);
var
  i : integer;
  Target : ATarget;
  TargetList : TList<RTarget>;
begin
  if FFireAtTarget then
  begin
    TargetList := TList<RTarget>.Create;
    Eventbus.Trigger(eiWelaUpdateTargets, [TargetList], ComponentGroup);
    Target := ATarget(TargetList.ToArray);
    TargetList.Free;
    if length(Target) <= 0 then
        exit;
  end
  else
  begin
    if FFireAtAllCommanders then
    begin
      setLength(Target, ServerGame.Commanders.Count);
      for i := 0 to ServerGame.Commanders.Count - 1 do Target[i] := RTarget.Create(ServerGame.Commanders[i]);
    end
    else if FFireAtCommander then
    begin
      Target := ATarget.Create(Eventbus.Read(eiOwnerCommander, []).AsInteger);
    end
    else if FFireAtGround then
    begin
      Target := ATarget.Create(FOwner.Position);
    end
    else if FFireAtSelf then
    begin
      Target := ATarget.Create(FOwner);
    end
    else
        Target := DefaultTargets;
  end;
  if not Eventbus.Read(eiWelaTargetPossible, [Target.ToRParam], FFireGroup).AsRTargetValidity.IsValid then exit;
  Eventbus.Trigger(eiFire, [Target.ToRParam], FFireGroup);
end;

function TAutoBrainComponent.FireAtAllCommanders : TAutoBrainComponent;
begin
  Result := self;
  FFireAtAllCommanders := True;
end;

function TAutoBrainComponent.FireAtCommander : TAutoBrainComponent;
begin
  Result := self;
  FFireAtCommander := True;
end;

function TAutoBrainComponent.FireAtGround : TAutoBrainComponent;
begin
  Result := self;
  FFireAtGround := True;
end;

function TAutoBrainComponent.FireAtSelf : TAutoBrainComponent;
begin
  Result := self;
  FFireAtSelf := True;
end;

function TAutoBrainComponent.FireAtTarget : TAutoBrainComponent;
begin
  Result := self;
  FFireAtTarget := True;
end;

function TAutoBrainComponent.FireInGroup(Group : TArray<byte>) : TAutoBrainComponent;
begin
  Result := self;
  FFireGroup := ByteArrayToComponentGroup(Group);
end;

{ TAutoBrainOnDeathComponent }

procedure TAutoBrainOnDeathComponent.Fire;
var
  Target : ATarget;
begin
  if FFireAtKiller then
  begin
    Target := ATarget.Create(FKillerID);
    if not Eventbus.Read(eiWelaTargetPossible, [Target.ToRParam], FFireGroup).AsRTargetValidity.IsValid then exit;
    Eventbus.Trigger(eiFire, [Target.ToRParam], FFireGroup);
  end
  else
      inherited;
end;

function TAutoBrainOnDeathComponent.FireAtKiller : TAutoBrainOnDeathComponent;
begin
  Result := self;
  FFireAtKiller := True;
end;

function TAutoBrainOnDeathComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  FKillerID := KillerID.AsInteger;
  CheckAndFire;
end;

{ TAutoBrainBuffComponent }

constructor TAutoBrainBuffComponent.CreateGrouped(Owner : TEntity;
Group, BuffTypes : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FBuffType := ByteArrayToSetBuffType(BuffTypes);
end;

function TAutoBrainBuffComponent.OnBuffed(Previous : RParam) : RParam;
var
  currentBuffTypes : SetBuffType;
begin
  currentBuffTypes := Previous.AsType<SetBuffType>;
  Result := RParam.From<SetBuffType>(currentBuffTypes + FBuffType);
end;

function TAutoBrainBuffComponent.OnRemoveBuff(Whitelist, Blacklist : RParam) : boolean;
begin
  Result := True;
  if (Whitelist.AsType<SetBuffType> * FBuffType <> []) and
    (Blacklist.AsType<SetBuffType> * FBuffType = []) then
  begin
    Eventbus.Trigger(eiFire, [ATarget.Create(FOwner).ToRParam], ComponentGroup);
  end;
end;

{ TAutoBrainPreventDeathComponent }

function TAutoBrainPreventDeathComponent.OnBeforeDie(KillerID, KillerCommanderID : RParam) : boolean;
var
  Target : ATarget;
begin
  Result := True;
  if not CanThink or (not FThinkInExile and Eventbus.Read(eiExiled, []).AsBoolean) then exit();
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
  begin
    Target := ATarget.Create(FOwner);
    if Eventbus.Read(eiWelaTargetPossible, [Target.ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
    begin
      Eventbus.Trigger(eiFire, [Target.ToRParam], FFireGroup);
      Result := False;
    end;
  end;
end;

{ TBrainWelaSavedTargetComponent }

constructor TBrainWelaSavedTargetComponent.CreateGrouped(Entity : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Entity, Group);
  FFireAtIndex := -1;
end;

function TBrainWelaSavedTargetComponent.DisableValidityCheck : TBrainWelaSavedTargetComponent;
begin
  Result := self;
  FDisableValidityCheck := True;
end;

function TBrainWelaSavedTargetComponent.FireAtIndex(Index : integer) : TBrainWelaSavedTargetComponent;
begin
  Result := self;
  FFireAtIndex := index;
end;

function TBrainWelaSavedTargetComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent
end;

function TBrainWelaSavedTargetComponent.SaveGroup(Group : TArray<byte>) : TBrainWelaSavedTargetComponent;
begin
  Result := self;
  FSaveGroup := ByteArrayToComponentGroup(Group);
end;

function TBrainWelaSavedTargetComponent.ThinkChain : boolean;
var
  Targets : RParam;
  NewTargets : ATarget;
begin
  Result := True;
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
  begin
    Targets := Eventbus.Read(eiWelaSavedTargets, [], FSaveGroup);
    assert(not Targets.IsEmpty, BuildExceptionMessage('OnThinkChain: No saved targets to use in group of this brain!'));

    if (FFireAtIndex >= 0) then
    begin
      NewTargets := Targets.AsATarget;
      if length(NewTargets) <= FFireAtIndex then
          exit;
      NewTargets := ATarget.Create(NewTargets[FFireAtIndex]);
      Targets := NewTargets.ToRParam;
    end;

    if FDisableValidityCheck or Eventbus.Read(eiWelaTargetPossible, [Targets], ComponentGroup).AsRTargetValidity.IsValid then
    begin
      // firing blocks the chain, so we have to break here
      if FBlocking then
      begin
        Eventbus.Trigger(eiStand, []);
        Result := False;
      end;
      Eventbus.Trigger(FFireEvent, [Targets], ComponentGroup);
    end;
  end;
end;

{ TThinkImpulseOnceComponent }

function TThinkImpulseOnceComponent.OnAfterCreate : boolean;
begin
  Result := True;
  if FTriggerOnAfterCreate then
      Trigger;
end;

function TThinkImpulseOnceComponent.OnDeploy : boolean;
begin
  Result := True;
  if FTriggerOnDeploy then
      Trigger;
end;

function TThinkImpulseOnceComponent.OnIdle : boolean;
begin
  Result := True;
  if not FTriggerOnAfterCreate and not FTriggerOnDeploy then
  begin
    if FWaitOneFrame then
        FWaitOneFrame := False
    else
    begin
      if not Eventbus.Read(eiExiled, []).AsBoolean then
          Trigger
    end;
  end;
end;

procedure TThinkImpulseOnceComponent.Trigger;
begin
  Eventbus.Trigger(eiThink, [], ComponentGroup);
  Eventbus.Trigger(eiThinkChain, [], ComponentGroup);
  Free;
end;

function TThinkImpulseOnceComponent.TriggerOnAfterCreate : TThinkImpulseOnceComponent;
begin
  Result := self;
  FTriggerOnAfterCreate := True;
end;

function TThinkImpulseOnceComponent.TriggerOnDeploy : TThinkImpulseOnceComponent;
begin
  Result := self;
  FTriggerOnDeploy := True;
end;

function TThinkImpulseOnceComponent.WaitOneFrame : TThinkImpulseOnceComponent;
begin
  Result := self;
  FWaitOneFrame := True;
end;

{ TBrainOverwatchComponent }

function TBrainOverwatchComponent.IsAway : boolean;
begin
  Result := FTargetPosition.Distance(Owner.Position) > 1.0;
end;

function TBrainOverwatchComponent.OnAfterCreate : boolean;
begin
  Result := True;
  FTargetPosition := Owner.Position;
  FTargetDirection := Owner.Front;
end;

function TBrainOverwatchComponent.OnMoveTargetReached : boolean;
begin
  Result := True;
  FMoving := False;
  if not IsAway then Owner.Front := FTargetDirection;
end;

function TBrainOverwatchComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainOverwatchComponent.ThinkChain : boolean;
begin
  Result := False;
  if not FMoving and CanMove and IsAway then
  begin
    Eventbus.Trigger(eiMoveTo, [RTarget.Create(FTargetPosition), 0.0]);
    // don't think about our move target until it's really needed
    FMoving := True;
  end;
end;

{ TAutoBrainOnGameEventComponent }

function TAutoBrainOnGameEventComponent.OnGameEvent(Event : RParam) : boolean;
begin
  Result := True;
  if HArray.Contains(FEvents, Event.AsString.ToLowerInvariant) then
      Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], ComponentGroup);
end;

function TAutoBrainOnGameEventComponent.SetEvent(Event : string) : TAutoBrainOnGameEventComponent;
begin
  Result := self;
  FEvents := FEvents + [Event.ToLowerInvariant];
end;

{ TAutoBrainUnitSpawnComponent }

function TAutoBrainUnitSpawnComponent.OnNewEntity(Entity : RParam) : boolean;
var
  Target : ATarget;
begin
  Result := True;
  Target := ATarget.Create(Entity.AsType<TEntity>);
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [Target.ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
  begin
    Eventbus.Trigger(eiFire, [Target.ToRParam], ComponentGroup);
  end;
end;

{ TLinkAutoBrainOnDeathComponent }

function TLinkAutoBrainOnDeathComponent.OnAfterCreate : boolean;
var
  Entity : TEntity;
begin
  Result := True;
  if TryGetDestination(Entity) then
      Entity.Eventbus.SubscribeRemote(eiDie, etTrigger, epLast, self, 'TargetOnDie', 2);
end;

function TLinkAutoBrainOnDeathComponent.TargetOnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  Fire;
end;

{ TLinkAutoBrainComponent }

function TLinkAutoBrainComponent.CheckDestinationForSourceInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
begin
  Result := self;
  FCheckDestinationForSourceInGroup := ByteArrayToComponentGroup(Group);
end;

function TLinkAutoBrainComponent.CheckSourceForDestinationInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
begin
  Result := self;
  FCheckSourceForDestinationInGroup := ByteArrayToComponentGroup(Group);
end;

procedure TLinkAutoBrainComponent.Fire;
var
  TargetEntity, TargetEntity2 : TEntity;
begin
  if FFiresAtSource and
    TryGetSource(TargetEntity) and
    Eventbus.Read(eiIsReady, [], FSourceFireGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(TargetEntity).ToRParam], FSourceFireGroup).AsRTargetValidity.IsValid and
    ((FCheckDestinationForSourceInGroup = []) or (
    TryGetDestination(TargetEntity2) and
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(TargetEntity2).ToRParam], FCheckDestinationForSourceInGroup).AsRTargetValidity.IsValid())) then
      Eventbus.Trigger(eiFire, [ATarget.Create(TargetEntity).ToRParam], FSourceFireGroup);
  if FFiresAtDestination and
    TryGetDestination(TargetEntity) and
    Eventbus.Read(eiIsReady, [], FDestinationFireGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(TargetEntity).ToRParam], FDestinationFireGroup).AsRTargetValidity.IsValid and
    ((FCheckSourceForDestinationInGroup = []) or (
    TryGetSource(TargetEntity2) and
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(TargetEntity2).ToRParam], FCheckSourceForDestinationInGroup).AsRTargetValidity.IsValid())) then
      Eventbus.Trigger(eiFire, [ATarget.Create(TargetEntity).ToRParam], FDestinationFireGroup);
end;

function TLinkAutoBrainComponent.FireAtDestinationInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
begin
  Result := self;
  FFiresAtDestination := True;
  FDestinationFireGroup := ByteArrayToComponentGroup(Group);
end;

function TLinkAutoBrainComponent.FireAtSourceInGroup(Group : TArray<byte>) : TLinkAutoBrainComponent;
begin
  Result := self;
  FFiresAtSource := True;
  FSourceFireGroup := ByteArrayToComponentGroup(Group);
end;

function TLinkAutoBrainComponent.TryGetDestination(out Destination : TEntity) : boolean;
var
  Target : ATarget;
begin
  Target := Eventbus.Read(eiLinkDest, []).AsATarget;
  assert(Target.Count = 1);
  Result := Target[0].TryGetTargetEntity(Destination);
end;

function TLinkAutoBrainComponent.TryGetSource(out Source : TEntity) : boolean;
var
  Target : ATarget;
begin
  Target := Eventbus.Read(eiLinkSource, []).AsATarget;
  assert(Target.Count = 1);
  Result := Target[0].TryGetTargetEntity(Source);
end;

{ TAutoBrainOnTakeDamageComponent }

function TAutoBrainOnTakeDamageComponent.ModifiesAmount : TAutoBrainOnTakeDamageComponent;
begin
  Result := self;
  FModifiesAmount := True;
end;

function TAutoBrainOnTakeDamageComponent.OnTakeDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
var
  Ready : boolean;
  TargetEntityID : integer;
  Entity : TEntity;
begin
  Result := Previous;
  if not CanThink or (CurrentEvent.CalledToGroup <> []) then exit;
  Ready := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
  if Ready then
  begin
    TargetEntityID := InflictorID.AsInteger;
    // resolve projectile owner
    if Game.EntityManager.TryGetEntityByID(InflictorID.AsInteger, Entity) then
    begin
      if (Entity.UnitProperties * [upProjectile, upLink] <> []) and
        Game.EntityManager.TryGetEntityByID(Entity.Eventbus.Read(eiCreator, []).AsInteger, Entity) then
          TargetEntityID := Entity.ID;
    end;
    if Eventbus.Read(eiWelaTriggerCheck, [Amount, DamageType, TargetEntityID], ComponentGroup).AsBooleanDefaultTrue then
    begin
      if FModifiesAmount then
      begin
        Amount := Amount.AsSingle * Eventbus.Read(eiWelaModifier, [], ComponentGroup).AsSingle;
      end;
      Fire(ATarget.Create(TargetEntityID));
    end;
  end;
end;

function TAutoBrainOnTakeDamageComponent.TriggersAfterDamage : TAutoBrainOnTakeDamageComponent;
begin
  Result := self;
  ChangeEventPriority(eiTakeDamage, etRead, epLast);
end;

{ TAutoBrainOnHealedComponent }

function TAutoBrainOnHealedComponent.OnHeal(var Amount : RParam;
HealModifier, InflictorID, Previous : RParam) : RParam;
var
  Ready : boolean;
  Times : integer;
  i : integer;
begin
  Result := Previous;
  if not CanThink or (CurrentEvent.CalledToGroup <> []) then exit;
  Ready := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
  if Ready and Eventbus.Read(eiWelaTriggerCheck, [Amount, HealModifier, InflictorID], ComponentGroup).AsBooleanDefaultTrue then
  begin
    Times := 1;
    if FTimesForEach > 0 then
        Times := (round(Amount.AsSingle) div FTimesForEach);
    for i := 0 to Times - 1 do
        Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], ComponentGroup);
  end;
end;

function TAutoBrainOnHealedComponent.TimesForEach(Factor : integer) : TAutoBrainOnHealedComponent;
begin
  Result := self;
  FTimesForEach := Factor;
end;

{ TBrainFleeComponent }

function TBrainFleeComponent.IsAway : boolean;
begin
  Result := FTargetPosition.Distance(Owner.Position) >= 0.2;
end;

function TBrainFleeComponent.IsOutOFRange : boolean;
begin
  Result := FTargetPosition.Distance(Owner.Position) >= FRange;
end;

function TBrainFleeComponent.OnAfterCreate : boolean;
begin
  Result := True;
  FTargetPosition := Owner.Position;
  FTargetDirection := Owner.Front;
end;

function TBrainFleeComponent.OnMoveTargetReached : boolean;
begin
  Result := True;
  FMoving := False;
  if not IsAway then Owner.Front := FTargetDirection;
end;

function TBrainFleeComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainFleeComponent.Range(s : single) : TBrainFleeComponent;
begin
  Result := self;
  FRange := s;
end;

function TBrainFleeComponent.ThinkChain : boolean;
begin
  Result := not FMoving;
  if not FMoving and CanMove and IsOutOFRange then
  begin
    Eventbus.Trigger(eiMoveTo, [RTarget.Create(FTargetPosition), 0.0]);
    // don't think about our move target until it's really needed
    FMoving := True;
    Result := False;
  end;
end;

{ TThinkImpulseFireComponent }

function TThinkImpulseFireComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if not Eventbus.Read(eiExiled, []).AsBoolean then
  begin
    Eventbus.Trigger(eiThink, [], FThinkGroup);
    Eventbus.Trigger(eiThinkChain, [], FThinkGroup);
  end;
end;

function TThinkImpulseFireComponent.TargetGroup(Group : TArray<byte>) : TThinkImpulseFireComponent;
begin
  Result := self;
  FThinkGroup := ByteArrayToComponentGroup(Group);
end;

{ TAutoBrainOnDealDamageComponent }

function TAutoBrainOnDealDamageComponent.AddAmountAtWrite : TAutoBrainOnDealDamageComponent;
begin
  Result := self;
  FAddAmountAtWrite := True;
end;

function TAutoBrainOnDealDamageComponent.DontFire : TAutoBrainOnDealDamageComponent;
begin
  Result := self;
  FDontFire := True;
end;

procedure TAutoBrainOnDealDamageComponent.Fire(Amount : single; TargetEntity : TEntity);
var
  Targets : RParam;
begin
  if not CanThink or not Eventbus.Read(eiIsReady, [], FFireGroup).AsBooleanDefaultTrue then exit;

  if FRedirectToSource then Targets := Eventbus.Read(eiLinkSource, [])
  else if FRedirectToSelf then Targets := ATarget.Create(Owner).ToRParam
  else Targets := ATarget.Create(TargetEntity).ToRParam;

  if Eventbus.Read(eiWelaTargetPossible, [Targets], FFireGroup).AsRTargetValidity.IsValid then
  begin
    if FWriteAmount then
    begin
      if FAddAmountAtWrite then
      begin
        Amount := Amount * Eventbus.Read(eiWelaModifier, [], ComponentGroup).AsSingleDefault(1.0);
        Amount := Amount + Owner.Blackboard.GetValue(FWriteAmountTo, FFireGroup).AsSingle;
      end;
      Eventbus.Write(FWriteAmountTo, [Amount], FFireGroup);
    end;
    if not FDontFire then
        Eventbus.Trigger(eiFire, [Targets], FFireGroup);
  end;
end;

function TAutoBrainOnDealDamageComponent.OnDamageDone(Amount, DamageType, TargetEntity : RParam) : boolean;
begin
  Result := True;
  Fire(Amount.AsSingle, TargetEntity.AsType<TEntity>);
end;

function TAutoBrainOnDealDamageComponent.RedirectToSelf : TAutoBrainOnDealDamageComponent;
begin
  Result := self;
  FRedirectToSelf := True;
end;

function TAutoBrainOnDealDamageComponent.RedirectToSource : TAutoBrainOnDealDamageComponent;
begin
  Result := self;
  FRedirectToSource := True;
end;

function TAutoBrainOnDealDamageComponent.WriteAmountTo(Event : EnumEventIdentifier) : TAutoBrainOnDealDamageComponent;
begin
  Result := self;
  FWriteAmount := True;
  FWriteAmountTo := Event;
end;

{ TAutoBrainBilateralComponent }

function TAutoBrainBilateralComponent.CheckSelfForTargetsInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
begin
  Result := self;
  FCheckSelfForTargetsInGroup := ByteArrayToComponentGroup(Group);
end;

function TAutoBrainBilateralComponent.CheckTargetsForSelfInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
begin
  Result := self;
  FCheckTargetsForSelfInGroup := ByteArrayToComponentGroup(Group);
end;

procedure TAutoBrainBilateralComponent.Fire(Targets : ATarget);
begin
  if FFiresAtSelf and
    Eventbus.Read(eiIsReady, [], FSelfFireGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Owner).ToRParam], FSelfFireGroup).AsRTargetValidity.IsValid and
    ((FCheckTargetsForSelfInGroup = []) or
    Eventbus.Read(eiWelaTargetPossible, [Targets.ToRParam], FCheckTargetsForSelfInGroup).AsRTargetValidity.IsValid) then
      Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], FSelfFireGroup);
  if FFiresAtTargets and
    Eventbus.Read(eiIsReady, [], FTargetsFireGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [Targets.ToRParam], FTargetsFireGroup).AsRTargetValidity.IsValid and
    ((FCheckSelfForTargetsInGroup = []) or
    Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Owner).ToRParam], FCheckSelfForTargetsInGroup).AsRTargetValidity.IsValid) then
      Eventbus.Trigger(eiFire, [Targets.ToRParam], FTargetsFireGroup);
end;

function TAutoBrainBilateralComponent.FireSelfInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
begin
  Result := self;
  FFiresAtSelf := True;
  FSelfFireGroup := ByteArrayToComponentGroup(Group);
end;

function TAutoBrainBilateralComponent.FireTargetsInGroup(Group : TArray<byte>) : TAutoBrainBilateralComponent;
begin
  Result := self;
  FFiresAtTargets := True;
  FTargetsFireGroup := ByteArrayToComponentGroup(Group);
end;

{ TThinkImpulseNowComponent }

constructor TThinkImpulseNowComponent.CreateGrouped(Owner : TEntity;
Group : TArray<byte>);
begin
  inherited;
  if not Eventbus.Read(eiExiled, []).AsBoolean then
  begin
    Eventbus.Trigger(eiThink, [], ComponentGroup);
    Eventbus.Trigger(eiThinkChain, [], ComponentGroup);
  end;
end;

{ TAutoBrainOnWelaShotProjectileComponent }

function TAutoBrainOnWelaShotProjectileComponent.OnWelaShotProjectile(Projectile : RParam) : boolean;
var
  Target : ATarget;
begin
  Result := True;
  if not CanThink then exit;
  Target := ATarget.Create(Projectile.AsType<TEntity>);
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [Target.ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
      Eventbus.Trigger(eiFire, [Target.ToRParam], ComponentGroup);
end;

{ TAutoBrainOnBeforeDeath }

constructor TAutoBrainOnBeforeDeath.CreateGrouped(Entity : TEntity;
Group : TArray<byte>);
begin
  inherited CreateGrouped(Entity, Group);
  ChangeEventPriority(eiDie, etTrigger, epMiddle);
end;

{ TBrainActionComponent }

procedure TBrainActionComponent.CancelFire;
begin
  FLock.Expired := True;
  Eventbus.Trigger(eiCancelFire, [], FFireGroup);
end;

constructor TBrainActionComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FEventHandler := TDelayedEventHandler.Create(Fire);
  FLock := TTimer.Create;
end;

destructor TBrainActionComponent.Destroy;
begin
  FEventHandler.Free;
  FLock.Free;
  inherited;
end;

procedure TBrainActionComponent.Fire;
begin
  if CanThink and Eventbus.Read(eiIsReady, [], FFireGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [FTargets.ToRParam], FFireGroup).AsRTargetValidity.IsValid then
  begin
    FInFireHandling := True;
    Eventbus.Trigger(eiFire, [FTargets.ToRParam], FFireGroup);
    FInFireHandling := False;
  end
  else
      CancelFire;
end;

function TBrainActionComponent.OnExiled(Exiled : RParam) : boolean;
begin
  Result := True;
  // if current fire handling exiles this unit, it won't cancel itself
  if Exiled.AsBoolean and not FInFireHandling then
  begin
    CancelFire;
    FEventHandler.UnregisterEvent;
  end;
end;

function TBrainActionComponent.OnPreFire(Targets : RParam) : boolean;
var
  ActionPoint, ActionDuration : integer;
begin
  Result := True;
  ActionPoint := Eventbus.Read(eiWelaActionpoint, [], CurrentEvent.CalledToGroup).AsInteger;
  if ActionPoint <= 0 then
      Eventbus.Trigger(eiFire, [Targets], CurrentEvent.CalledToGroup)
  else
  begin
    FFireGroup := CurrentEvent.CalledToGroup;
    FTargets := Targets.AsATarget;
    FEventHandler.RegisterEvent(ActionPoint);
  end;
  ActionDuration := Eventbus.Read(eiWelaActionduration, [], CurrentEvent.CalledToGroup).AsInteger;
  ActionDuration := Max(ActionPoint, ActionDuration);
  FLock.Interval := Max(1, ActionDuration);
  FLock.Start;
end;

function TBrainActionComponent.OnThinkChain : boolean;
begin
  Result := not FEventHandler.IsWaiting and FLock.Expired;
end;

{ TAutoBrainOnCreateComponent }

function TAutoBrainOnCreateComponent.OnAfterCreate : boolean;
begin
  Result := True;
  if (not FOnlyAfterGameStart or (GlobalEventbus.Read(eiGameTickTimeToFirstTick, []).AsInteger <= 0)) and
    (not FOnlyBeforeGameStart or (GlobalEventbus.Read(eiGameTickTimeToFirstTick, []).AsInteger > 0)) then
      CheckAndFire;
end;

function TAutoBrainOnCreateComponent.OnlyAfterGameStart : TAutoBrainOnCreateComponent;
begin
  Result := self;
  FOnlyAfterGameStart := True;
end;

function TAutoBrainOnCreateComponent.OnlyBeforeGameStart : TAutoBrainOnCreateComponent;
begin
  Result := self;
  FOnlyBeforeGameStart := True;
end;

{ TThinkBlockComponent }

function TThinkBlockComponent.OnThinkChain : boolean;
begin
  Result := False;
end;

function TThinkBlockComponent.OnThink : boolean;
begin
  Result := False;
end;

{ TAutoBrainOnFreeComponent }

procedure TAutoBrainOnFreeComponent.BeforeComponentFree;
begin
  if assigned(Game) and not Game.IsShuttingDown and Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then
  begin
    Fire
  end;
  inherited;
end;

{ TAutoBrainOnUnitPropertyComponent }

function TAutoBrainOnUnitPropertyComponent.MustNotHave(UnitProperties : TArray<byte>) : TAutoBrainOnUnitPropertyComponent;
begin
  Result := self;
  FMustNotHave := ByteArrayToSetUnitProperies(UnitProperties);
end;

function TAutoBrainOnUnitPropertyComponent.OnUnitPropertyChanged(ChangedUnitProperties, Removed : RParam) : boolean;
var
  Ready : boolean;
  UnitProperties : SetUnitProperty;
begin
  Result := True;
  if not Removed.AsBoolean then
  begin
    UnitProperties := ChangedUnitProperties.AsSetType<SetUnitProperty>;
    if (FTriggerAtUnitProperties * UnitProperties <> []) and
      (FMustNotHave * UnitProperties = []) then
    begin
      Ready := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
      if Ready then
      begin
        Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], ComponentGroup);
      end;
    end;
  end;
end;

function TAutoBrainOnUnitPropertyComponent.TriggerOn(UnitProperties : TArray<byte>) : TAutoBrainOnUnitPropertyComponent;
begin
  Result := self;
  FTriggerAtUnitProperties := ByteArrayToSetUnitProperies(UnitProperties);
end;

{ TAutoBrainOnWillDealDamageComponent }

function TAutoBrainOnWillDealDamageComponent.OnWillDealDamage(Amount, DamageTypes, TargetEntity, Previous : RParam) : RParam;
begin
  Result := Previous;
  Fire(Amount.AsSingle, TargetEntity.AsType<TEntity>);
end;

{ TAutoBrainOnResourceComponent }

function TAutoBrainOnResourceComponent.OnTransact(ResourceID, Amount : RParam) : boolean;
var
  Ready : boolean;
  Times : integer;
  sTimes : single;
  i : integer;
  ResourceType : EnumResource;
begin
  Result := True;
  if not CanThink or (CurrentEvent.CalledToGroup <> []) then exit;
  ResourceType := EnumResource(ResourceID.AsInteger);
  Ready := ResourceType in FResource;
  Ready := Ready and Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue;
  if Ready then
  begin
    if ResourceType in RES_INT_RESOURCES then
    begin
      Times := Owner.Cap(ResourceType, CurrentEvent.CalledToGroup).AsInteger;
      Times := Times - Owner.Balance(ResourceType, CurrentEvent.CalledToGroup).AsInteger;
      Times := Min(Times, Amount.AsInteger);
    end
    else
    begin
      sTimes := Owner.Cap(ResourceType, CurrentEvent.CalledToGroup).AsSingle;
      sTimes := sTimes - Owner.Balance(ResourceType, CurrentEvent.CalledToGroup).AsSingle;
      sTimes := Min(sTimes, Amount.AsSingle);
      Times := trunc(sTimes);
    end;
    if not FTimesForEach then
        Times := Min(Times, 1);
    for i := 0 to Times - 1 do
        Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], ComponentGroup);
  end;
end;

function TAutoBrainOnResourceComponent.TimesForEach : TAutoBrainOnResourceComponent;
begin
  Result := self;
  FTimesForEach := True;
end;

function TAutoBrainOnResourceComponent.TriggerOn(Resource : TArray<byte>) : TAutoBrainOnResourceComponent;
begin
  Result := self;
  FResource := ByteArrayToSetResource(Resource);
end;

{ TAutoBrainOnWelaHitByProjectileComponent }

function TAutoBrainOnWelaHitByProjectileComponent.OnWelaHitByProjectile(Projectile : RParam) : boolean;
var
  Target : ATarget;
begin
  Result := True;
  if not CanThink then exit;
  Target := ATarget.Create(Projectile.AsType<TEntity>);
  if Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue and
    Eventbus.Read(eiWelaTargetPossible, [Target.ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
      Eventbus.Trigger(eiFire, [Target.ToRParam], ComponentGroup);
end;

{ TAutoBrainOnCommanderAbilityUsedComponent }

function TAutoBrainOnCommanderAbilityUsedComponent.OnCommanderAbilityUsed(TeamID, TargetsRaw : RParam) : boolean;
var
  Targets : ATarget;
  Range : single;
  i : integer;
  AnyTargetInRange : boolean;
begin
  Result := True;
  if not CanThink then exit;
  if FConstraintOnSameTeamID and (TeamID.AsInteger <> Owner.TeamID) then exit;
  Targets := TargetsRaw.AsATarget;
  if FConstraintOnInWelaRange then
  begin
    AnyTargetInRange := False;
    Range := Eventbus.Read(eiWelaRange, [], ComponentGroup).AsSingle;
    for i := 0 to Targets.Count - 1 do
      if Owner.Position.Distance(Targets[i].GetTargetPosition) <= Range then
      begin
        AnyTargetInRange := True;
        break;
      end;
    if not AnyTargetInRange then exit;
  end;

  CheckAndFire(Targets);
end;

function TAutoBrainOnCommanderAbilityUsedComponent.ConstraintOnInWelaRange : TAutoBrainOnCommanderAbilityUsedComponent;
begin
  Result := self;
  FConstraintOnInWelaRange := True;
end;

function TAutoBrainOnCommanderAbilityUsedComponent.ConstraintOnSameTeamID : TAutoBrainOnCommanderAbilityUsedComponent;
begin
  Result := self;
  FConstraintOnSameTeamID := True;
end;

initialization

ScriptManager.ExposeClass(TThinkImpulseNowComponent);
ScriptManager.ExposeClass(TThinkImpulseFireComponent);
ScriptManager.ExposeClass(TThinkImpulseTimerComponent);
ScriptManager.ExposeClass(TThinkImpulseImmediateComponent);
ScriptManager.ExposeClass(TThinkImpulseGameTickComponent);
ScriptManager.ExposeClass(TThinkImpulseTimerCooldownComponent);
ScriptManager.ExposeClass(TThinkImpulseOnceComponent);
ScriptManager.ExposeClass(TThinkBlockComponent);

ScriptManager.ExposeClass(TBrainComponent);

ScriptManager.ExposeClass(TBrainProjectileComponent);

ScriptManager.ExposeClass(TBrainActionComponent);
ScriptManager.ExposeClass(TBrainFollowLaneComponent);
ScriptManager.ExposeClass(TBrainOverwatchComponent);
ScriptManager.ExposeClass(TBrainOverwatchSandboxComponent);
ScriptManager.ExposeClass(TBrainFleeComponent);
ScriptManager.ExposeClass(TBrainFollowComponent);
ScriptManager.ExposeClass(TBrainApproachComponent);
ScriptManager.ExposeClass(TBrainWaitComponent);
ScriptManager.ExposeClass(TBrainWelaProjectileComponent);

ScriptManager.ExposeClass(TBrainWelaComponent);
ScriptManager.ExposeClass(TBrainTargetingWelaComponent);
ScriptManager.ExposeClass(TBrainWelaFightComponent);
ScriptManager.ExposeClass(TBrainWelaLinkComponent);
ScriptManager.ExposeClass(TBrainWelaTargetlessComponent);
ScriptManager.ExposeClass(TBrainWelaSelftargetComponent);
ScriptManager.ExposeClass(TBrainWelaSelftargetGroundComponent);
ScriptManager.ExposeClass(TBrainWelaSavedTargetComponent);
ScriptManager.ExposeClass(TBrainWelaTargetCommanderComponent);
ScriptManager.ExposeClass(TBrainWelaCommanderComponent);
ScriptManager.ExposeClass(TBrainLinkWelaCommanderComponent);

ScriptManager.ExposeClass(TAutoBrainComponent);
ScriptManager.ExposeClass(TAutoBrainOnCreateComponent);
ScriptManager.ExposeClass(TAutoBrainOnUnitPropertyComponent);
ScriptManager.ExposeClass(TAutoBrainOnFreeComponent);
ScriptManager.ExposeClass(TAutoBrainBilateralComponent);
ScriptManager.ExposeClass(TAutoBrainWelaTargetProducedUnitComponent);
ScriptManager.ExposeClass(TAutoBrainOnGameEventComponent);
ScriptManager.ExposeClass(TAutoBrainKillLinkComponent);
ScriptManager.ExposeClass(TAutoBrainWelaOnHitEffectComponent);
ScriptManager.ExposeClass(TAutoBrainWelaInstantChainComponent);
ScriptManager.ExposeClass(TAutoBrainOnKillComponent);
ScriptManager.ExposeClass(TAutoBrainPreventDeathComponent);
ScriptManager.ExposeClass(TAutoBrainOnDeathComponent);
ScriptManager.ExposeClass(TAutoBrainOnBeforeDeath);
ScriptManager.ExposeClass(TAutoBrainBuffComponent);
ScriptManager.ExposeClass(TAutoBrainOnTakeDamageComponent);
ScriptManager.ExposeClass(TAutoBrainOnWillDealDamageComponent);
ScriptManager.ExposeClass(TAutoBrainUnitSpawnComponent);
ScriptManager.ExposeClass(TAutoBrainOnHealedComponent);
ScriptManager.ExposeClass(TAutoBrainOnDealDamageComponent);
ScriptManager.ExposeClass(TAutoBrainOnWelaShotProjectileComponent);
ScriptManager.ExposeClass(TAutoBrainOnWelaHitByProjectileComponent);
ScriptManager.ExposeClass(TAutoBrainOnResourceComponent);
ScriptManager.ExposeClass(TAutoBrainOnCommanderAbilityUsedComponent);

ScriptManager.ExposeClass(TLinkAutoBrainComponent);
ScriptManager.ExposeClass(TLinkAutoBrainOnDeathComponent);

end.
