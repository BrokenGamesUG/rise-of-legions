unit BaseConflict.EntityComponents.Shared.Wela;

interface

uses
  Generics.Collections,
  Math,
  RTTI,
  SysUtils,
  StrUtils,
  Engine.Log,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Windows,
  Engine.Script,
  BaseConflict.Map,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Entity;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$REGION 'Modifier Components'}
  {$RTTI INHERIT}
  /// <summary> Metaclass of classes which are adjusting unit properties, which are important for the client and the server,
  /// e.g. walking speed. </summary>
  TModifierComponent = class(TEntityComponent)
    protected
      FValueGroup, FReadyGroup : SetComponentGroup;
      function IsActive : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>); override;
      function SetValueGroup(const ValueGroup : TArray<byte>) : TModifierComponent;
      function ReadyGroup(const ReadyGroup : TArray<byte>) : TModifierComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Adds or removes damage types from a group. </summary>
  TModifierDamageTypeComponent = class(TModifierComponent)
    protected
      FAdded, FRemoved : SetDamageType;
    published
      [XEvent(eiDamageType, epMiddle, etRead)]
      function OnDamageType(Previous : RParam) : RParam;
    public
      function Add(const DamageTypes : TArray<byte>) : TModifierDamageTypeComponent;
      function Remove(const DamageTypes : TArray<byte>) : TModifierDamageTypeComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Increases of decreases the wela count by an offset (eiWelaModifier in ValueGroup).</summary>
  TModifierWelaCountComponent = class(TModifierComponent)
    protected
      FTakeUnitCount : boolean;
      FUnitProperties : SetUnitProperty;
      FTeamConstraint : EnumTargetTeamConstraint;
      FScalesWithResource : EnumResource;
    published
      [XEvent(eiWelaCount, epMiddle, etRead)]
      /// <summary> Adjust wela count. </summary>
      function OnWelaCount(Previous : RParam) : RParam;
    public
      function TakeGlobalUnitCountByProperty(const UnitProperties : TArray<byte>) : TModifierWelaCountComponent;
      function TakeEnemyUnitCountByProperty(const UnitProperties : TArray<byte>) : TModifierWelaCountComponent;
      function ScaleWithResource(Resource : EnumResource) : TModifierWelaCountComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Increases or decreases the eiWelaTargetCount by a value (eiWelaModifier in ValueGroup).</summary>
  TModifierWelaTargetCountComponent = class(TModifierComponent)
    protected
      FScalesWithResource : EnumResource;
    published
      [XEvent(eiWelaTargetCount, epMiddle, etRead)]
      /// <summary> Adjust target count. </summary>
      function OnWelaTargetCount(Previous : RParam) : RParam;
    public
      function ScaleWithResource(Resource : EnumResource) : TModifierWelaTargetCountComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Increases of decreases the movement speed by a factor (eiWelaDamage in ValueGroup).</summary>
  TModifierMultiplyMovementSpeedComponent = class(TModifierComponent)
    published
      [XEvent(eiSpeed, epMiddle, etRead)]
      /// <summary> Adjust speed. </summary>
      function OnSpeed(Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Increases or decreases the health by an offset (eiWelaDamage in ValueGroup).</summary>
  TModifierResourceComponent = class(TModifierComponent)
    protected
      FModifiedResource, FScaleWithResource : EnumResource;
      FUseResourceCap, FAddModifier, FDontFillCap : boolean;
      FChangedResource : single;
      procedure BeforeComponentFree; override;
      procedure ModifyResource(const Amount : single);
    public
      function Resource(ModifiedResource : EnumResource) : TModifierResourceComponent;
      function ScaleWithResource(Resource : EnumResource) : TModifierResourceComponent;
      /// <summary> Uses the resource cap instead of balance for ScaleWithResource. </summary>
      function UseResourceCap : TModifierResourceComponent;
      /// <summary> Adds the eiWelaModifier instead of multiplying it. </summary>
      function AddModifier : TModifierResourceComponent;
      /// <summary> As this modifier isn't based on altering an event, we have to trigger it manually. </summary>
      function ApplyNow : TModifierResourceComponent;
      function DontFillCap : TModifierResourceComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Multiply all cooldowns of target group with multiplier eiWelaDamage of ValueGroup.</summary>
  TModifierMultiplyCooldownComponent = class(TModifierComponent)
    published
      [XEvent(eiCooldown, epMiddle, etRead)]
      /// <summary> Adjust cooldown. </summary>
      function OnCooldown(Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Modifies the armor type of this unit.</summary>
  TModifierArmorTypeComponent = class(TModifierComponent)
    protected
      FChangeClassIndex : integer;
      FSetArmorType : boolean;
    published
      [XEvent(eiArmorType, epMiddle, etRead)]
      /// <summary> Adjust armor type. </summary>
      function OnArmorType(Previous : RParam) : RParam;
    public
      function Increase : TModifierArmorTypeComponent;
      function Decrease : TModifierArmorTypeComponent;
      function SetTo(ArmorType : integer) : TModifierArmorTypeComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Multiply all eiWelaDamage of target group with multiplier eiWelaModifier of ValueGroup.</summary>
  TModifierWelaDamageComponent = class(TModifierComponent)
    protected
      FResourceGroup : SetComponentGroup;
      FScalesWithResource : EnumResource;
      FDivide, FMultiply, FNegate : boolean;
      FFactor, FMaximumResourceScaleFactor, FResourceOffset : single;
      FMustHave : SetUnitProperty;
    published
      [XEvent(eiWelaDamage, epMiddle, etRead)]
      /// <summary> Adjust damage. </summary>
      function OnWelaDamage(Previous : RParam) : RParam;
    public
      function ScaleWithResource(ResType : integer) : TModifierWelaDamageComponent;
      function ResourceGroup(Group : TArray<byte>) : TModifierWelaDamageComponent;
      function ResourceOffset(Offset : single) : TModifierWelaDamageComponent;
      function FactorForUnitProperty(UnitProperties : TArray<byte>; Factor : single) : TModifierWelaDamageComponent;
      function MaximumResourceScaleFactor(Maximum : single) : TModifierWelaDamageComponent;
      function Divide : TModifierWelaDamageComponent;
      function Multiply : TModifierWelaDamageComponent;
      function Negate : TModifierWelaDamageComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Multiply all eiWelaDamage of target group with multiplier eiWelaModifier of ValueGroup.</summary>
  TModifierWelaRangeComponent = class(TModifierComponent)
    protected
      FTimer : TTimer;
      FScaleWithTime, FActivateOnStand, FAdditive, FDeactivateOnMoveTo, FScaleWithStage : boolean;
    published
      [XEvent(eiWelaRange, epMiddle, etRead)]
      /// <summary> Adjust range. </summary>
      function OnWelaRange(Previous : RParam) : RParam;
      [XEvent(eiStand, epLast, etTrigger)]
      /// <summary> Start time scaling. </summary>
      function OnStand() : boolean;
      [XEvent(eiMoveTo, epLast, etTrigger)]
      /// <summary> Stop time scaling resetting it. </summary>
      function OnMoveTo(Target, Range : RParam) : boolean;
    public
      /// <summary> Adds the modifier to the value instead of multiplying it with it. </summary>
      function AddModifier : TModifierWelaRangeComponent;
      /// <summary> Scales the modifier by a time factor in eiCooldown of value group. </summary>
      function ScaleWithTime : TModifierWelaRangeComponent;
      /// <summary> Scales the modifier by stage times eiModifier. </summary>
      function ScaleWithStage : TModifierWelaRangeComponent;
      /// <summary> Time scaling is started on stand and not on create. </summary>
      function ActivateOnStand : TModifierWelaRangeComponent;
      /// <summary> Time scaling is started on stand and not on create. </summary>
      function DeactivateOnMoveTo : TModifierWelaRangeComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Adds to all eiResourceCost of target group eiWelaModifier of ValueGroup.</summary>
  TModifierCostComponent = class(TModifierComponent)
    protected
      FScalesWithResource : EnumResource;
    published
      [XEvent(eiResourceCost, epMiddle, etRead)]
      /// <summary> Adjust costs. </summary>
      function OnResourceCost(Previous : RParam) : RParam;
    public
      function ScaleWithResource(ResType : integer) : TModifierCostComponent;
  end;
  {$ENDREGION}
  {$REGION 'Target Contraints Components'}
  {$RTTI INHERIT}

  /// <summary> Masterclass of targetconstraints. </summary>
  TWelaTargetConstraintComponent = class(TEntityComponent)
    protected
      FForWarhead : boolean;
      /// <summary> Makes a single check for a target. </summary>
      function IsPossible(const Target : RTarget) : boolean; virtual;
      /// <summary> Make a single check for each target. Can be overriden for meta-checks of multiple items in combination. </summary>
      procedure Check(Targets : ATarget; var Validity : RTargetValidity); virtual;
    published
      [XEvent(eiWelaTargetPossible, epHigher, etRead), ScriptExcludeMember]
      [XEvent(eiWarheadTargetPossible, epHigher, etRead), ScriptExcludeMember]
      /// <summary> Return the result of the constraint. </summary>
      function OnTargetPossible(Targets, PrevValue : RParam) : RParam;
    public
      function ConstraintsWarhead() : TWelaTargetConstraintComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the maximum distance between all targets. </summary>
  TWelaTargetConstraintMaxTargetDistanceComponent = class(TWelaTargetConstraintComponent)
    protected
      procedure Check(Targets : ATarget; var Validity : RTargetValidity); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible buildtargets to buildzones of the own team. </summary>
  TWelaTargetConstraintBuildTeamComponent = class(TWelaTargetConstraintComponent)
    protected
      function IsPossible(const Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> The weapon can't target the unit itself. </summary>
  TWelaTargetConstraintNotSelfComponent = class(TWelaTargetConstraintComponent)
    protected
      function IsPossible(const Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> The weapon can't target units saved in eiWelaSavedTargets. </summary>
  TWelaTargetConstraintBlacklistComponent = class(TWelaTargetConstraintComponent)
    protected
      function IsPossible(const Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> The wela cannot be used. </summary>
  TWelaTargetConstraintNeverComponent = class(TWelaTargetConstraintComponent)
    protected
      function IsPossible(const Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Checks the fill percentage of a resource with a reference. </summary>
  TWelaTargetConstraintResourceComponent = class(TWelaTargetConstraintComponent)
    protected
      FCompareBalanceToReference, FCompareCapToReference, FCompareMissingToReference : boolean;
      FReference : single;
      FComparator : EnumComparator;
      FComparedResource : EnumResource;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      function CheckResource(ResourceID : EnumResource) : TWelaTargetConstraintResourceComponent;
      /// <summary> Checks Balance / Cap <Comparator> Reference. </summary>
      function Comparator(Comparator : EnumComparator) : TWelaTargetConstraintResourceComponent;
      /// <summary> Sets the reference for the comparison. </summary>
      function Reference(Reference : single) : TWelaTargetConstraintResourceComponent;
      /// <summary> Compares the missing balance to the cap to the reference. </summary>
      function CompareMissingToReference() : TWelaTargetConstraintResourceComponent;
      /// <summary> Compares the balance to the reference. </summary>
      function CompareBalanceToReference() : TWelaTargetConstraintResourceComponent;
      /// <summary> Compares the cap to the reference. </summary>
      function CompareCapToReference() : TWelaTargetConstraintResourceComponent;
      /// <summary> Shorthand for coLowerEqual and 0. </summary>
      function CheckEmpty() : TWelaTargetConstraintResourceComponent;
      /// <summary> Shorthand for coGreater and 0. </summary>
      function CheckNotEmpty() : TWelaTargetConstraintResourceComponent;
      /// <summary> Shorthand for coGreaterEqual and 1. </summary>
      function CheckFull() : TWelaTargetConstraintResourceComponent;
      /// <summary> Shorthand for coLower and 1. </summary>
      function CheckNotFull() : TWelaTargetConstraintResourceComponent;
      /// <summary> Shorthand for CompareCapToReference, coGreater and 0. </summary>
      function CheckHasResource() : TWelaTargetConstraintResourceComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Compares a resource of the owner with the target. </summary>
  TWelaTargetConstraintResourceCompareComponent = class(TWelaTargetConstraintComponent)
    protected
      FCompareCap : boolean;
      FComparator : EnumComparator;
      FComparedResource : EnumResource;
      FAdditionalComparedResource : TArray<EnumResource>;
      FTargetFactor : single;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> If called multiple, resources are added together. </summary>
      function ComparedResource(Resource : EnumResource) : TWelaTargetConstraintResourceCompareComponent;
      function ComparesResourceCap() : TWelaTargetConstraintResourceCompareComponent;
      function SetComparator(Comparator : EnumComparator) : TWelaTargetConstraintResourceCompareComponent;
      function TargetFactor(Factor : single) : TWelaTargetConstraintResourceCompareComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints buildtarget(if needed gridsize is bigger than 1, the RTarget points to
  /// the front-left point of the needed rectangle) to have free space on the target grids. </summary>
  TWelaTargetConstraintGridComponent = class(TWelaTargetConstraintComponent)
    protected
      CheckAllFields : boolean;
      function CheckGridNode(TargetBuildZone : TBuildZone; WorldCoord : RVector2) : boolean; virtual;
      function IsPossible(const Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  EnumBooleanOperator = (boAnd, boOr);

  /// <summary> Constraints different groups together. </summary>
  TWelaTargetConstraintBooleanComponent = class(TWelaTargetConstraintComponent)
    protected
      FGroupA, FGroupB : SetComponentGroup;
      FNotA, FNotB : boolean;
      FOperator : EnumBooleanOperator;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      function GroupA(Group : TArray<byte>) : TWelaTargetConstraintBooleanComponent;
      function GroupB(Group : TArray<byte>) : TWelaTargetConstraintBooleanComponent;
      function OperatorOr : TWelaTargetConstraintBooleanComponent;
      function OperatorAnd : TWelaTargetConstraintBooleanComponent;
      function NotA : TWelaTargetConstraintBooleanComponent;
      function NotB : TWelaTargetConstraintBooleanComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela with a zone,
  /// e.g. buildings can only be placed in the buildarea. </summary>
  TWelaTargetConstraintZoneComponent = class(TWelaTargetConstraintComponent)
    protected
      FZone : string;
      FPrefix : boolean;
      FPadding : single;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Zone : string; Prefix : boolean); reintroduce;
      function SetPadding(Padding : single) : TWelaTargetConstraintZoneComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela to the proximity of units creating a field,
  /// e.g. drops can only set near towers. </summary>
  TWelaTargetConstraintDynamicZoneComponent = class(TWelaTargetConstraintComponent)
    protected
      FDynamicZone : SetDynamicZone;
      FIgnoreTeam : boolean;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      function SetZone(Zone : TArray<byte>) : TWelaTargetConstraintDynamicZoneComponent;
      function IgnoresTeams() : TWelaTargetConstraintDynamicZoneComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela to targets with a specific team id. </summary>
  TWelaTargetConstraintTeamIDComponent = class(TWelaTargetConstraintComponent)
    protected
      FTargetTeamID : integer;
      FInvert : boolean;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      function SetTargetTeam(TeamID : integer) : TWelaTargetConstraintTeamIDComponent;
      /// <summary> Targets everything except the target team id. </summary>
      function Invert : TWelaTargetConstraintTeamIDComponent;
  end;

  /// <summary> Constraints the possible targets of a wela to enemies or friends. </summary>
  TWelaTargetConstraintTeamComponent = class(TWelaTargetConstraintComponent)
    protected
      FTargetsEnemies : boolean;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; TargetsEnemies : boolean); reintroduce;
  end;

  TWelaTargetConstraintAlliesComponent = class(TWelaTargetConstraintTeamComponent)
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); reintroduce;
  end;

  TWelaTargetConstraintEnemiesComponent = class(TWelaTargetConstraintTeamComponent)
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); reintroduce;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela to visible enemies. </summary>
  TWelaTargetConstraintCardNameComponent = class(TWelaTargetConstraintComponent)
    protected
      FCards : TArray<string>;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      function AddCard(const ScriptFileName : string) : TWelaTargetConstraintCardNameComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela to targets with their creator being alive. </summary>
  TWelaTargetConstraintCreatorIsAliveComponent = class(TWelaTargetConstraintComponent)
    protected
      function IsPossible(const Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela to targets with the same owning commander as self. </summary>
  TWelaTargetConstraintOwningComponent = class(TWelaTargetConstraintComponent)
    protected
      function IsPossible(const Target : RTarget) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Blacklists or whitelists the possible targets of a wela depending of unitproperties. </summary>
  TWelaTargetConstraintUnitPropertyComponent = class(TWelaTargetConstraintComponent)
    protected
      FMustNotList, FMustList, FMustNotAllList, FMustAnyList : SetUnitProperty;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      function MustHave(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
      function MustHaveAny(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
      function MustNotHave(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
      function MustNotHaveAll(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Blacklists or whitelists the possible targets of a wela depending of unitproperties. </summary>
  TWelaTargetConstraintCompareUnitPropertyComponent = class(TWelaTargetConstraintUnitPropertyComponent)
    protected
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      /// <summary> All properties have to be present at owner and target. </summary>
      function BothMustHave(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
      /// <summary> Any of these properties have to be present at owner and target. </summary>
      function BothMustHaveAny(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
      /// <summary> None of these properties must be present at owner and target. </summary>
      function BothMustNotHave(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
      /// <summary> These properties together must not be present at owner and target. </summary>
      function BothMustNotHaveAll(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Blacklists or whitelists the possible targets of a wela depending of wela properties. </summary>
  TWelaTargetConstraintWelaPropertyComponent = class(TWelaTargetConstraintComponent)
    protected
      FCheckGroup : SetComponentGroup;
      FMustHave, FMustNotHave : SetDamageType;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); reintroduce;
      function MustHave(Types : TArray<byte>) : TWelaTargetConstraintWelaPropertyComponent;
      function MustNotHave(Types : TArray<byte>) : TWelaTargetConstraintWelaPropertyComponent;
      function CheckGroup(Group : TArray<byte>) : TWelaTargetConstraintWelaPropertyComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela with the return of an event (must be boolean) </summary>
  TWelaTargetConstraintEventComponent = class(TWelaTargetConstraintComponent)
    protected
      FEvent : EnumEventIdentifier;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Event : EnumEventIdentifier); reintroduce;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints the possible targets of a wela with whether the unit have been buffer (buff types in the
  /// constructor). </summary>
  TWelaTargetConstraintBuffComponent = class(TWelaTargetConstraintComponent)
    protected
      FWhiteBuffTypes, FBlackBuffTypes : SetBuffType;
      function IsPossible(const Target : RTarget) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function Whitelist(BuffTypes : TArray<byte>) : TWelaTargetConstraintBuffComponent;
      function Blacklist(BuffTypes : TArray<byte>) : TWelaTargetConstraintBuffComponent;
  end;
  {$ENDREGION}
  {$REGION 'Trigger check components'}
  {$RTTI INHERIT}

  /// <summary> Masterclass of trigger checks for take damage events. </summary>
  TWelaTriggerCheckTakeDamageComponent = class abstract(TEntityComponent)
    protected
      /// <summary> Makes a single check for a target. </summary>
      function IsValid(Amount : single; DamageType : SetDamageType; InflictorID : integer) : boolean; virtual; abstract;
    published
      [XEvent(eiWelaTriggerCheck, epHigher, etRead), ScriptExcludeMember]
      /// <summary> Return the result of the constraint. </summary>
      function OnTriggerCheck(Amount, DamageType, InflictorID, Previous : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Checks whether the taken damage is dealt by the entity itself. </summary>
  TWelaTriggerCheckNotSelfComponent = class(TWelaTriggerCheckTakeDamageComponent)
    protected
      function IsValid(Amount : single; DamageType : SetDamageType; InflictorID : integer) : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Checks whether the taken damage is over or under a certain threshold. Default is the GreaterEqual check. </summary>
  TWelaTriggerCheckTakeDamageThresholdComponent = class(TWelaTriggerCheckTakeDamageComponent)
    protected
      FLesserEqualCheck : boolean;
      /// <summary> Makes a single check for a target. </summary>
      function IsValid(Amount : single; DamageType : SetDamageType; InflictorID : integer) : boolean; override;
    public
      function LesserEqual : TWelaTriggerCheckTakeDamageThresholdComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Checks whether the taken damage has certain types. </summary>
  TWelaTriggerCheckTakeDamageTypeComponent = class(TWelaTriggerCheckTakeDamageComponent)
    protected
      FMustHave, FMustNotHave : SetDamageType;
      /// <summary> Makes a single check for a target. </summary>
      function IsValid(Amount : single; DamageType : SetDamageType; InflictorID : integer) : boolean; override;
    public
      function MustHave(DamageTypes : TArray<byte>) : TWelaTriggerCheckTakeDamageTypeComponent;
      function MustNotHave(DamageTypes : TArray<byte>) : TWelaTriggerCheckTakeDamageTypeComponent;
  end;
  {$ENDREGION}
  {$REGION 'Wela Ready Components'}
  {$RTTI INHERIT}

  /// <summary> Mastercomponent for all readycomponents of welas, determines
  /// whether a wela can be fired or not at the moment. </summary>
  TWelaReadyComponent = class(TEntityComponent)
    protected
      function IsReady() : boolean; virtual;
    published
      [XEvent(eiIsReady, epFirst, etRead), ScriptExcludeMember]
      /// <summary> Determines whether wela is ready or not. </summary>
      function OnIsReady(PrevValue : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Constraints different groups together. </summary>
  TWelaReadyBooleanComponent = class(TWelaReadyComponent)
    protected
      FGroupA, FGroupB : SetComponentGroup;
      FNotA, FNotB : boolean;
      FOperator : EnumBooleanOperator;
      function IsReady() : boolean; override;
    public
      function GroupA(Group : TArray<byte>) : TWelaReadyBooleanComponent;
      function GroupB(Group : TArray<byte>) : TWelaReadyBooleanComponent;
      function OperatorOr : TWelaReadyBooleanComponent;
      function OperatorAnd : TWelaReadyBooleanComponent;
      function NotA : TWelaReadyBooleanComponent;
      function NotB : TWelaReadyBooleanComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Wela costs some resources. Payed by Entity itself. </summary>
  TWelaReadyCostComponent = class(TWelaReadyComponent)
    protected
      FPayingGroup : TDictionary<EnumResource, SetComponentGroup>;
      FDefaultPayingGroup, FValueGroup : SetComponentGroup;
      FRedirectToCommander, FCostsCap : boolean;
      function GetPayingGroup(ResType : EnumResource) : SetComponentGroup;
      function IsReady() : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> Set a special group for paying the resources. Default is the ComponentGroup of this component. </summary>
      function SetPayingGroup(Group : TArray<byte>) : TWelaReadyCostComponent;
      /// <summary> Set a special group for paying a certain Resource. </summary>
      function SetPayingGroupForType(ResourceType : integer; Group : TArray<byte>) : TWelaReadyCostComponent;
      /// <summary> The commander pays for this effect. Changes paying group to []! </summary>
      function CommanderPays() : TWelaReadyCostComponent;
      /// <summary> Costs the current cap. </summary>
      function CostsCap : TWelaReadyCostComponent;
      /// <summary> Determines the group where the costs are fetched from. Defaults to ComponentGroup. </summary>
      function ValueGroup(Group : TArray<byte>) : TWelaReadyCostComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Restricts abilities to be only done if a Resources percentage (Current/Max) pass the compare test. </summary>
  TWelaReadyResourceCompareComponent = class(TWelaReadyComponent)
    protected
      FCompareCap, FChecksCommander, FReferenceIsAbsolute : boolean;
      FComparator : EnumComparator;
      FComparedResource : EnumResource;
      FAdditionalComparedResource : TArray<EnumResource>;
      FReferenceValue : single;
      FCheckingGroup : SetComponentGroup;
      function IsReady() : boolean; override;
    public
      function ComparedResource(Resource : EnumResource) : TWelaReadyResourceCompareComponent;
      function SetComparator(Comparator : EnumComparator) : TWelaReadyResourceCompareComponent;
      function ReferenceValue(ReferenceValue : single) : TWelaReadyResourceCompareComponent;
      function ReferenceIsAbsolute : TWelaReadyResourceCompareComponent;
      /// <summary> Shorthand for coLowerEqual and 0. </summary>
      function CheckEmpty() : TWelaReadyResourceCompareComponent;
      /// <summary> Shorthand for coGreater and 0. </summary>
      function CheckNotEmpty() : TWelaReadyResourceCompareComponent;
      /// <summary> Shorthand for coGreaterEqual and 1. </summary>
      function CheckFull() : TWelaReadyResourceCompareComponent;
      /// <summary> Shorthand for coLower and 1. </summary>
      function CheckNotFull() : TWelaReadyResourceCompareComponent;
      /// <summary> The group where the resources are checked. Default is the public group [] </summary>
      function CheckingGroup(Group : TArray<byte>) : TWelaReadyResourceCompareComponent;
      function ChecksCommander : TWelaReadyResourceCompareComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready if the spawned unit also is ready.
  /// Used to determine things like legendary and heroic unique checks. </summary>
  TWelaReadySpawnedComponent = class(TWelaReadyComponent)
    protected
      function IsReady() : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready if the entity has or has not a certain unit property. </summary>
  TWelaReadyUnitPropertyComponent = class(TWelaReadyComponent)
    protected
      FMustNotList, FMustList, FMustNotAllList, FMustAnyList : SetUnitProperty;
      FChecksCommander : boolean;
      function IsReady() : boolean; override;
    public
      function MustHave(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
      function MustHaveAny(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
      function MustNotHave(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
      function MustNotHaveAll(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
      function ChecksCommander : TWelaReadyUnitPropertyComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready if enemies are in range of eiWelaRange. </summary>
  TWelaReadyEnemiesNearbyComponent = class(TWelaReadyComponent)
    protected
      FValueGroup, FCheckGroup : SetComponentGroup;
      function IsReady() : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function ValueGroup(ValueGroup : TArray<byte>) : TWelaReadyEnemiesNearbyComponent;
      function CheckGroup(CheckGroup : TArray<byte>) : TWelaReadyEnemiesNearbyComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready after the game started (post warming). Afterwards this component returns true for the whole time. </summary>
  TWelaReadyAfterGameStartComponent = class(TWelaReadyComponent)
    protected
      FReady : boolean;
      function IsReady() : boolean; override;
    published
      [XEvent(eiGameTick, epLast, etTrigger, esGlobal), ScriptExcludeMember]
      /// <summary> Start weapon. </summary>
      function OnGameTick() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready after the game has fired a certain game event. Afterwards this component returns true for the whole time. </summary>
  TWelaReadyAfterGameEventComponent = class(TWelaReadyComponent)
    protected
      FFired : boolean;
      FEventUID : string;
      function IsReady() : boolean; override;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger), ScriptExcludeMember]
      function OnAfterCreate() : boolean;
      [XEvent(eiGameEvent, epLast, etTrigger, esGlobal)]
      function OnGameEvent(EventIdentifier : RParam) : boolean;
    public
      function GameEvent(const EventUID : string) : TWelaReadyAfterGameEventComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready after the game has reached a certain duration. Afterwards this component returns true for the whole time. </summary>
  TWelaReadyAfterGameTimeComponent = class(TWelaReadyComponent)
    protected
      FTime : integer;
      function IsReady() : boolean; override;
    public
      function Time(Seconds : integer) : TWelaReadyAfterGameTimeComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready when the creator group is ready. If has no creator group, it is ready. </summary>
  TWelaReadyCreatorComponent = class(TWelaReadyComponent)
    protected
      function IsReady() : boolean; override;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready when the creator group is ready. If has no creator group, it is ready. </summary>
  TWelaReadyEventCompareComponent = class(TWelaReadyComponent)
    protected
      FComparator : EnumComparator;
      FComparedEvent : EnumEventIdentifier;
      FReferenceValue : single;
      FCheckingGroup : SetComponentGroup;
      function IsReady() : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function ComparedEvent(EventIdentifier : EnumEventIdentifier) : TWelaReadyEventCompareComponent;
      function SetComparator(Comparator : EnumComparator) : TWelaReadyEventCompareComponent;
      function ReferenceValue(ReferenceValue : single) : TWelaReadyEventCompareComponent;
      /// <summary> The group where the resources are checked. Default is the component group. </summary>
      function CheckingGroup(Group : TArray<byte>) : TWelaReadyEventCompareComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The associated wela is ready after expiration of a cooldown, which resets completely with an fire event.
  /// Furthermore, at each fire the cooldown gets refreshed. So the cooldown doesn't change while wela is on cooldown. </summary>
  TWelaReadyCooldownComponent = class(TEntityComponent)
    protected
      FCooldown : TGameTimer;
      FReadyGroup, FFireGroup : SetComponentGroup;
      FReadyAfterStart, FOnce, FOnceDone, FFixedCooldown : boolean;
      FFixedInterval : integer;
      function IsReady() : boolean;
      {$IFDEF CLIENT}
      // apply servertimer
      procedure UpdateTimer;
      {$ENDIF}
      {$IFDEF SERVER}
      // send time sync
      procedure SaveTimer;
      {$ENDIF}
      procedure InitTimer();
      procedure StartTimer();
      procedure FinishTimer();
    published
      [XEvent(eiIsReady, epFirst, etRead), ScriptExcludeMember]
      /// <summary> Determines whether wela is ready or not. </summary>
      function OnIsReady(Previous : RParam) : RParam;
      [XEvent(eiAfterCreate, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Apply wela active state. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiFire, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Restart cooldown. </summary>
      function OnFire(Targets : RParam) : boolean;
      {$IFDEF CLIENT}
      [XEvent(eiCooldownStartingTime, epLast, etWrite), ScriptExcludeMember]
      /// <summary> Retrieve sync from server. </summary>
      function OnWriteCooldownStartingTime(StartingTime : RParam) : boolean;
      {$ENDIF}
      [XEvent(eiCooldownRemainingTime, epLast, etRead), ScriptExcludeMember]
      /// <summary> Returns the remaining time of this cooldown. </summary>
      function OnCooldownRemainingTime() : RParam;
      [XEvent(eiCooldownProgress, epLast, etRead), ScriptExcludeMember]
      /// <summary> Returns the percentage of remaining time of this cooldown. </summary>
      function OnCooldownProgress() : RParam;
      [XEvent(eiWelaActive, epLast, etWrite), ScriptExcludeMember]
      /// <summary> Activates or deactivates this timer. </summary>
      function OnSetWelaActive(IsActive : RParam) : boolean;
      [XEvent(eiWelaCooldownReset, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Resets this timer. </summary>
      function OnCooldownReset(Finish : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>; ReadyAtStart : boolean); reintroduce;
      /// <summary> The ready group determines, where this component contribute its ready check. By default the ready group = component group.
      /// Useful if multiple groups resets this counter, but some of them won't check the counter. </summary>
      function ReadyGroup(ReadyGroup : TArray<byte>) : TWelaReadyCooldownComponent;
      /// <summary> The fire group determines, where this component is reset by fire.
      /// Useful if multiple groups read this counter, but some of them won't reset the counter. </summary>
      function FireGroup(FireGroup : TArray<byte>) : TWelaReadyCooldownComponent;
      function Cooldown(CooldownMs : integer) : TWelaReadyCooldownComponent;
      function Once() : TWelaReadyCooldownComponent;
      destructor Destroy; override;
  end;

  {$ENDREGION}
  {$REGION 'Misc'}
  {$RTTI INHERIT}

  /// <summary> Some welas produces entities and need data from them. This component redirects
  /// all eiResourceCost and eiWelaNeededGridSize reads to the meta of eiWelaUnitPattern.
  /// If other data is saved in the blackboard this data is used instead of the redirected. </summary>
  TWelaEventRedirecter = class(TEntityComponent)
    protected
      function GetPattern(TargetGroup : SetComponentGroup) : string;
      function Redirect(Event : EnumEventIdentifier; Previous : RParam) : RParam;
    published
      [XEvent(eiResourceCost, epFirst, etRead)]
      [XEvent(eiWelaNeededGridSize, epFirst, etRead)]
      [XEvent(eiWelaDamage, epFirst, etRead)]
      [XEvent(eiWelaRange, epFirst, etRead)]
      [XEvent(eiWelaTargetCount, epFirst, etRead)]
      [XEvent(eiCooldown, epFirst, etRead)]
      [XEvent(eiColorIdentity, epFirst, etRead)]
      function OnRedirect(Previous : RParam) : RParam;
      [XEvent(eiCollisionRadius, epFirst, etRead)]
      function OnCollisionRadius(Previous : RParam) : RParam;
    public
      function CopyIndexedValue(Event : EnumEventIdentifier; SourceGroup : TArray<byte>; Resource : integer; TargetGroup : TArray<byte>) : TWelaEventRedirecter;
      function CopyValue(Event : EnumEventIdentifier; SourceGroup : TArray<byte>; TargetGroup : TArray<byte>) : TWelaEventRedirecter;
  end;

  {$RTTI INHERIT}

  /// <summary> Applies a script to an entity. </summary>
  TWarheadApplyScriptComponent = class(TEntityComponent)
    protected
      type
      EnumParameterType = (ptNone, ptInteger, ptSingle, ptBoolean, ptBooleanSameTeam, ptDirectionToTarget, ptOffsetToTarget, ptIntegerEvent, ptSingleEvent, ptRVector2Event, ptResource);

      RParameter = record
        Owner : TWarheadApplyScriptComponent;
        ParameterEvent : EnumEventIdentifier;
        ParameterIntValue : integer;
        ParameterSingleValue : single;
        ParameterBooleanValue : boolean;
        ParameterType : EnumParameterType;
        ParameterResource : EnumResource;
        ParameterGroup : SetComponentGroup;
        UsesGroupOverride : boolean;
        PublicEvent : boolean;
        Index : integer;
        function GetValue(Eventbus : TEventbus; ComponentGroup : SetComponentGroup) : TValue;
      end;
    var
      FCurrentTarget : TEntity; // for passing direction to target on fire warhead
      FAtUnitProduced, FNotAtFire, FAfterCreate : boolean;
      FScriptName, FMethodname : string;
      FSpellGroup, FUpgradeGroup, FChargeGroup : byte;
      FParameters : TList<RParameter>;
      FTimer : TTimer;
      procedure Apply(Entity : TEntity);
    published
      [XEvent(eiAfterCreate, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Apply the script to the targets. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiFireWarhead, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Apply the script to the targets. </summary>
      function OnFireWarhead(Targets : RParam) : boolean;
      [XEvent(eiWelaUnitProduced, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Apply the script to produced units. </summary>
      function OnWelaUnitProduced(EntityID : RParam) : boolean;
      [XEvent(eiIdle, epLast, etTrigger, esGlobal)]
      /// <summary> Apply the script to self if delayed. </summary>
      function OnIdle() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; ScriptToApply : string); reintroduce;
      /// <summary> Passes additional parameters to the Apply-Method. The order of the passmethod determines
      /// their index. The parameters are placed AFTER the obligatory entity parameter. </summary>
      function PassValueFromEvent(Event : integer) : TWarheadApplyScriptComponent;
      function PassSavedTargetPosition(Index : integer) : TWarheadApplyScriptComponent;
      function PassResource(Resource : EnumResource) : TWarheadApplyScriptComponent;
      function PassIntValue(Value : integer) : TWarheadApplyScriptComponent;
      function PassSingleValue(Value : single) : TWarheadApplyScriptComponent;
      function PassBooleanValue(Value : boolean) : TWarheadApplyScriptComponent;
      function PassSameTeam() : TWarheadApplyScriptComponent;
      function PassDirectionToTarget : TWarheadApplyScriptComponent;
      function PassOffsetToOwner : TWarheadApplyScriptComponent;
      function OverrideLastParameterGroup(Group : TArray<byte>) : TWarheadApplyScriptComponent;
      function Methodname(const Methodname : string) : TWarheadApplyScriptComponent;
      function ApplyToProducedUnits : TWarheadApplyScriptComponent;
      /// <summary> Applies the script to the entity itself after creation and frees this. </summary>
      function ApplyToSelfAtCreate : TWarheadApplyScriptComponent;
      function ApplyToSelfAfterDelay(Duration : integer) : TWarheadApplyScriptComponent;
      destructor Destroy; override;
  end;

  /// <summary> Applies a script to an entity. </summary>
  TWarheadLinkApplyScriptComponent = class(TWarheadApplyScriptComponent)
    protected
      FSavedScriptGroup : SetComponentGroup;
      FActivateOnAfterCreate, FRemoveOnDestroy : boolean;
      /// <summary> Remove the components of the linktarget. </summary>
      procedure BeforeComponentFree; override;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Apply the script to the Linktarget. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiReplaceEntity, epLast, etTrigger, esGlobal)]
      /// <summary> Removes script from unit if replaced. </summary>
      function OnReplaceEntity(OldEntityID, NewEntityID, IsSameEntity : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; ScriptToApply : string); reintroduce;
  end;

  {$RTTI INHERIT}

  EnumResolveSource = (rsTeamID, rsLevel, rsResource, rsTier, rsOwnerTier);

  /// <summary> Resolves the level (reLevel) for (eiWeladamage, eiWelaCount). Chooses the values saved
  /// in the level index and return them. </summary>
  TWelaHelperResolveComponent = class(TEntityComponent)
    protected
      FLevelGroup : SetComponentGroup;
      FSource : EnumResolveSource;
      FResource : EnumResource;
      function GetCurrentIndex : integer;
    published
      [XEvent(eiWelaUnitPattern, epFirst, etRead)]
      [XEvent(eiWelaCount, epFirst, etRead)]
      [XEvent(eiWelaTargetCount, epFirst, etRead)]
      [XEvent(eiWelaDamage, epFirst, etRead)]
      [XEvent(eiWelaAreaOfEffect, epFirst, etRead)]
      [XEvent(eiWelaSplashfactor, epFirst, etRead)]
      [XEvent(eiWelaRange, epFirst, etRead)]
      [XEvent(eiArmorType, epFirst, etRead)]
      [XEvent(eiCooldown, epFirst, etRead)]
      /// <summary> Resolves the right index. </summary>
      function OnFetch(Previous : RParam) : RParam;
    public
      /// <summary> Sets the group which contains the level. </summary>
      function ResolveLevel(LevelGroup : TArray<byte>) : TWelaHelperResolveComponent;
      function ResolveTeamID() : TWelaHelperResolveComponent;
      /// <summary> Resolve the tier the game currently is in. </summary>
      function ResolveCurrentTier() : TWelaHelperResolveComponent;
      /// <summary> Resolves the tier of the owner. </summary>
      function ResolveTier() : TWelaHelperResolveComponent;
      /// <summary> Sets the group which contains the level. </summary>
      function ResolveResource(Resource : EnumResource; ResourceGroup : TArray<byte>) : TWelaHelperResolveComponent;
  end;

  {$ENDREGION}

implementation

uses
  {$IFDEF SERVER}
  BaseConflict.Globals.Server,
  {$ENDIF}
  {$IFDEF CLIENT}
  BaseConflict.Globals.Client,
  {$ENDIF}
  BaseConflict.Globals;

{ TModifierComponent }

constructor TModifierComponent.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FValueGroup := self.ComponentGroup;
end;

function TModifierComponent.IsActive : boolean;
begin
  Result := (FReadyGroup = []) or Eventbus.Read(eiIsReady, [], FReadyGroup).AsBooleanDefaultTrue;
end;

function TModifierComponent.ReadyGroup(const ReadyGroup : TArray<byte>) : TModifierComponent;
begin
  Result := self;
  FReadyGroup := ByteArrayToComponentGroup(ReadyGroup);
end;

function TModifierComponent.SetValueGroup(const ValueGroup : TArray<byte>) : TModifierComponent;
begin
  Result := self;
  FValueGroup := ByteArrayToComponentGroup(ValueGroup);
end;

{ TModifierMultiplyCooldownComponent }

function TModifierMultiplyCooldownComponent.OnCooldown(Previous : RParam) : RParam;
var
  Factor : RParam;
begin
  // modify cooldown if there is a cooldown value and the read doesn't come from our value group
  if not Previous.IsEmpty and (CurrentEvent.CalledToGroup * FValueGroup = []) then
  begin
    Factor := Eventbus.Read(eiWelaModifier, [], FValueGroup);
    assert(not Factor.IsEmpty, 'TModifierMultiplyCooldownComponent.OnCooldown: Expecting a value for eiWelaModifier in ValueGroup!');
    Result := integer(round(Previous.AsInteger * Factor.AsSingleDefault(1.0)));
  end
  else Result := Previous;
end;

{ TModifierWelaDamageComponent }

function TModifierWelaDamageComponent.Divide : TModifierWelaDamageComponent;
begin
  Result := self;
  FDivide := True;
end;

function TModifierWelaDamageComponent.FactorForUnitProperty(UnitProperties : TArray<byte>; Factor : single) : TModifierWelaDamageComponent;
begin
  Result := self;
  FMustHave := ByteArrayToSetUnitProperies(UnitProperties);
  FFactor := Factor;
end;

function TModifierWelaDamageComponent.MaximumResourceScaleFactor(Maximum : single) : TModifierWelaDamageComponent;
begin
  Result := self;
  FMaximumResourceScaleFactor := Maximum;
end;

function TModifierWelaDamageComponent.Multiply : TModifierWelaDamageComponent;
begin
  Result := self;
  FMultiply := True;
end;

function TModifierWelaDamageComponent.Negate : TModifierWelaDamageComponent;
begin
  Result := self;
  FNegate := True;
end;

function TModifierWelaDamageComponent.OnWelaDamage(Previous : RParam) : RParam;
var
  Factor, ResourceFactor : single;
begin
  if not Previous.IsEmpty and IsActive then
  begin
    Factor := Eventbus.Read(eiWelaModifier, [], FValueGroup).AsSingleDefault(1);
    if FNegate then
        Factor := -Factor;
    if FScalesWithResource <> reNone then
    begin
      ResourceFactor := ResourceAsSingle(FScalesWithResource, Owner.Balance(FScalesWithResource, FResourceGroup));
      ResourceFactor := ResourceFactor + FResourceOffset;
      if FMaximumResourceScaleFactor > 0 then
          ResourceFactor := Min(ResourceFactor, FMaximumResourceScaleFactor);
      Factor := Factor * ResourceFactor;
    end;
    if (FMustHave <> []) and (FMustHave <= Owner.UnitProperties) then
        Factor := Factor * FFactor;
    if FMultiply then
        Result := Previous.AsSingle * Factor
    else if FDivide then
        Result := Previous.AsSingle / Factor
    else
        Result := Previous.AsSingle + Factor;
  end
  else Result := Previous;
end;

function TModifierWelaDamageComponent.ScaleWithResource(ResType : integer) : TModifierWelaDamageComponent;
begin
  Result := self;
  FScalesWithResource := EnumResource(ResType);
end;

function TModifierWelaDamageComponent.ResourceGroup(Group : TArray<byte>) : TModifierWelaDamageComponent;
begin
  Result := self;
  FResourceGroup := ByteArrayToComponentGroup(Group);
end;

function TModifierWelaDamageComponent.ResourceOffset(Offset : single) : TModifierWelaDamageComponent;
begin
  Result := self;
  FResourceOffset := Offset;
end;

{ TModifierMultiplyMovementSpeedComponent }

function TModifierMultiplyMovementSpeedComponent.OnSpeed(Previous : RParam) : RParam;
var
  Factor : RParam;
begin
  Factor := Eventbus.Read(eiWelaDamage, [], FValueGroup);
  if not Factor.IsEmpty and not Previous.IsEmpty then Result := Previous.AsSingle * Factor.AsSingle
  else Result := Previous;
end;

{ TModifierResourceComponent }

function TModifierResourceComponent.AddModifier : TModifierResourceComponent;
begin
  Result := self;
  FAddModifier := True;
end;

function TModifierResourceComponent.ApplyNow : TModifierResourceComponent;
var
  Resource, Modifier : single;
begin
  Result := self;
  FChangedResource := Eventbus.Read(eiWelaDamage, [], FValueGroup).AsSingle;
  if FScaleWithResource <> reNone then
  begin
    if FUseResourceCap then
        Resource := ResourceAsSingle(FScaleWithResource, Owner.Cap(FScaleWithResource, ComponentGroup))
    else
        Resource := ResourceAsSingle(FScaleWithResource, Owner.Balance(FScaleWithResource, ComponentGroup));

    FChangedResource := FChangedResource * Resource;
  end;
  Modifier := Eventbus.Read(eiWelaModifier, [], FValueGroup).AsSingleDefault(1.0);
  if FAddModifier then
      FChangedResource := FChangedResource + Modifier
  else
      FChangedResource := FChangedResource * Modifier;
  // resource cap of health can't be reduced below 1 health
  if FChangedResource < 0 then
      FChangedResource := -Min((ResourceAsSingle(FModifiedResource, Owner.Cap(FModifiedResource)) - 1.0), -FChangedResource);
  ModifyResource(FChangedResource);
end;

procedure TModifierResourceComponent.BeforeComponentFree;
begin
  if assigned(Game) and not Game.IsShuttingDown then
      ModifyResource(-FChangedResource);
  inherited;
end;

function TModifierResourceComponent.DontFillCap : TModifierResourceComponent;
begin
  Result := self;
  FDontFillCap := True;
end;

procedure TModifierResourceComponent.ModifyResource(const Amount : single);
var
  iAmount : integer;
begin
  if FModifiedResource in RES_INT_RESOURCES then
  begin
    iAmount := round(Amount);
    Eventbus.Trigger(eiResourceCapTransaction, [ord(FModifiedResource), iAmount, FDontFillCap], []);
  end
  else
      Eventbus.Trigger(eiResourceCapTransaction, [ord(FModifiedResource), Amount, FDontFillCap], []);
end;

function TModifierResourceComponent.Resource(ModifiedResource : EnumResource) : TModifierResourceComponent;
begin
  Result := self;
  FModifiedResource := ModifiedResource;
end;

function TModifierResourceComponent.ScaleWithResource(Resource : EnumResource) : TModifierResourceComponent;
begin
  Result := self;
  FScaleWithResource := Resource;
end;

function TModifierResourceComponent.UseResourceCap : TModifierResourceComponent;
begin
  Result := self;
  FUseResourceCap := True;
end;

{ TModifierWelaCountComponent }

function TModifierWelaCountComponent.OnWelaCount(Previous : RParam) : RParam;
var
  AddValue : integer;
begin
  if IsLocalCall then
  begin
    AddValue := 0;
    if FTakeUnitCount then
    begin
      if assigned(Game) then AddValue := Game.EntityManager.EntityCountByUnitProperty(FUnitProperties, FTeamConstraint, Owner.TeamID);
    end
    else AddValue := Eventbus.Read(eiWelaModifier, [], FValueGroup).AsInteger;
    if FScalesWithResource <> reNone then
    begin
      if FScalesWithResource in RES_FLOAT_RESOURCES then AddValue := trunc(AddValue * Owner.Balance(FScalesWithResource, ComponentGroup).AsSingle)
      else AddValue := AddValue * Owner.Balance(FScalesWithResource, ComponentGroup).AsInteger;
    end;
    Result := Previous.AsInteger + AddValue;
  end
  else Result := Previous;
end;

function TModifierWelaCountComponent.ScaleWithResource(Resource : EnumResource) : TModifierWelaCountComponent;
begin
  Result := self;
  FScalesWithResource := Resource;
end;

function TModifierWelaCountComponent.TakeEnemyUnitCountByProperty(const UnitProperties : TArray<byte>) : TModifierWelaCountComponent;
begin
  Result := self;
  FTakeUnitCount := True;
  FTeamConstraint := tcEnemies;
  FUnitProperties := ByteArrayToSetUnitProperies(UnitProperties);
end;

function TModifierWelaCountComponent.TakeGlobalUnitCountByProperty(const UnitProperties : TArray<byte>) : TModifierWelaCountComponent;
begin
  Result := self;
  FTakeUnitCount := True;
  FTeamConstraint := tcAll;
  FUnitProperties := ByteArrayToSetUnitProperies(UnitProperties);
end;

{ TModifierArmorTypeComponent }

function TModifierArmorTypeComponent.Decrease : TModifierArmorTypeComponent;
begin
  Result := self;
  FChangeClassIndex := -1;
end;

function TModifierArmorTypeComponent.Increase : TModifierArmorTypeComponent;
begin
  Result := self;
  FChangeClassIndex := 1;
end;

function TModifierArmorTypeComponent.OnArmorType(Previous : RParam) : RParam;
var
  CurrentArmorType : EnumArmorType;
  ChangeBy : integer;
begin
  if IsActive then
  begin
    if FSetArmorType then CurrentArmorType := EnumArmorType(FChangeClassIndex)
    else
    begin
      CurrentArmorType := Previous.AsEnumType<EnumArmorType>;
      ChangeBy := FChangeClassIndex * Eventbus.Read(eiWelaModifier, [], ComponentGroup).AsIntegerDefault(1);
      if CurrentArmorType in ARMORY_TYPES_NORMAL then
          CurrentArmorType := EnumArmorType(Min(ord(atHeavy), Max(ord(atUnarmored), ord(CurrentArmorType) + ChangeBy)));
    end;
    Result := RParam.From<EnumArmorType>(CurrentArmorType);
  end
  else
      Result := Previous;
end;

function TModifierArmorTypeComponent.SetTo(ArmorType : integer) : TModifierArmorTypeComponent;
begin
  Result := self;
  FSetArmorType := True;
  FChangeClassIndex := ArmorType;
end;

{ TModifierCostComponent }

function TModifierCostComponent.OnResourceCost(Previous : RParam) : RParam;
var
  CostOffset, Factor : RParam;
  Costs : AResourceCost;
  i : integer;
  iFactor : integer;
  sFactor : single;
begin
  if not Previous.IsEmpty and IsLocalCall then
  begin
    CostOffset := Eventbus.Read(eiWelaModifier, [], FValueGroup);
    if FScalesWithResource <> reNone then
        Factor := Owner.Balance(FScalesWithResource, ComponentGroup)
    else Factor := RPARAMEMPTY;
    Costs := Previous.AsAResourceCost;
    for i := 0 to Length(Costs) - 1 do
    begin
      if Costs[i].ResourceType in RES_FLOAT_RESOURCES then
      begin
        sFactor := CostOffset.AsSingle;
        if FScalesWithResource in RES_FLOAT_RESOURCES then sFactor := sFactor * Factor.AsSingle
        else if FScalesWithResource in RES_INT_RESOURCES then sFactor := sFactor * Factor.AsInteger;
        Costs[i].Amount := Costs[i].Amount.AsSingle + sFactor;
      end
      else
      begin
        iFactor := CostOffset.AsInteger;
        if FScalesWithResource in RES_FLOAT_RESOURCES then iFactor := trunc(iFactor * Factor.AsSingle)
        else if FScalesWithResource in RES_INT_RESOURCES then iFactor := iFactor * Factor.AsInteger;
        Costs[i].Amount := Costs[i].Amount.AsInteger + iFactor;
      end;
    end;
    Result := Costs.ToRParam;
  end
  else Result := Previous;
end;

function TModifierCostComponent.ScaleWithResource(ResType : integer) : TModifierCostComponent;
begin
  Result := self;
  FScalesWithResource := EnumResource(ResType);
end;

{ TWelaTargetConstraintZoneComponent }

constructor TWelaTargetConstraintZoneComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Zone : string; Prefix : boolean);
begin
  inherited CreateGrouped(Owner, Group);
  FZone := Zone;
  FPrefix := Prefix;
end;

function TWelaTargetConstraintZoneComponent.IsPossible(const Target : RTarget) : boolean;
var
  temp : string;
  BuildZone : TMultipolygon;
  targetPos, NextValidPos : RVector2;
begin
  temp := FZone;
  if FPrefix then temp := temp + Owner.TeamID.ToString;
  if Game.Map.Zones.TryGetValue(temp, BuildZone) then
  begin
    Result := BuildZone.IsPointInMultiPolygon(Target.GetTargetPosition);
    if Result and (FPadding > 0) then
    begin
      targetPos := Target.GetTargetPosition;
      NextValidPos := BuildZone.NextPointOnBorder(targetPos);
      Result := targetPos.distance(NextValidPos) >= FPadding;
    end;
  end
  else Result := True;
end;

function TWelaTargetConstraintZoneComponent.SetPadding(Padding : single) : TWelaTargetConstraintZoneComponent;
begin
  Result := self;
  FPadding := Padding;
end;

{ TWelaTargetConstraintComponent }

procedure TWelaTargetConstraintComponent.Check(Targets : ATarget; var Validity : RTargetValidity);
var
  i : integer;
begin
  for i := 0 to Targets.Count - 1 do
  begin
    Validity.SetValidity(i, IsPossible(Targets[i]));
  end;
end;

function TWelaTargetConstraintComponent.ConstraintsWarhead : TWelaTargetConstraintComponent;
begin
  Result := self;
  FForWarhead := True;
end;

function TWelaTargetConstraintComponent.IsPossible(const Target : RTarget) : boolean;
begin
  Result := True;
end;

function TWelaTargetConstraintComponent.OnTargetPossible(Targets, PrevValue : RParam) : RParam;
var
  Validity : RTargetValidity;
begin
  if ((not FForWarhead and (CurrentEvent.EventIdentifier = eiWelaTargetPossible)) or
    (FForWarhead and (CurrentEvent.EventIdentifier = eiWarheadTargetPossible))) and
    IsLocalCall then
  begin
    if PrevValue.IsEmpty then
        Validity := RTargetValidity.Create(Targets.AsATarget)
    else
        Validity := PrevValue.AsRTargetValidity;
    Check(Targets.AsATarget, Validity);
    Result := Validity;
  end
  else Result := PrevValue;
end;

{ TWelaTargetConstraintUnitPropertyComponent }

function TWelaTargetConstraintUnitPropertyComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
  UnitProperties : SetUnitProperty;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  UnitProperties := TargetEntity.UnitProperties;
  Result :=
    (FMustList <= UnitProperties) and
    ((FMustAnyList = []) or (FMustAnyList * UnitProperties <> [])) and
    (FMustNotList * UnitProperties = []) and
    ((FMustNotAllList = []) or not(FMustNotAllList <= UnitProperties));
end;

function TWelaTargetConstraintUnitPropertyComponent.MustHave(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
begin
  Result := self;
  FMustList := ByteArrayToSetUnitProperies(Properties);
end;

function TWelaTargetConstraintUnitPropertyComponent.MustHaveAny(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
begin
  Result := self;
  FMustAnyList := ByteArrayToSetUnitProperies(Properties);
end;

function TWelaTargetConstraintUnitPropertyComponent.MustNotHaveAll(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
begin
  Result := self;
  FMustNotAllList := ByteArrayToSetUnitProperies(Properties);
end;

function TWelaTargetConstraintUnitPropertyComponent.MustNotHave(Properties : TArray<byte>) : TWelaTargetConstraintUnitPropertyComponent;
begin
  Result := self;
  FMustNotList := ByteArrayToSetUnitProperies(Properties);
end;

{ TWelaTargetConstraintTeamIDComponent }

function TWelaTargetConstraintTeamIDComponent.Invert : TWelaTargetConstraintTeamIDComponent;
begin
  Result := self;
  FInvert := True;
end;

function TWelaTargetConstraintTeamIDComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  if FInvert then Result := TargetEntity.TeamID <> FTargetTeamID
  else Result := TargetEntity.TeamID = FTargetTeamID;
end;

function TWelaTargetConstraintTeamIDComponent.SetTargetTeam(TeamID : integer) : TWelaTargetConstraintTeamIDComponent;
begin
  Result := self;
  FTargetTeamID := TeamID;
end;

{ TWelaTargetConstraintTeamComponent }

constructor TWelaTargetConstraintTeamComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; TargetsEnemies : boolean);
begin
  inherited CreateGrouped(Owner, Group);
  FTargetsEnemies := TargetsEnemies;
end;

function TWelaTargetConstraintTeamComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  Result := ((FTargetsEnemies and (TargetEntity.TeamID <> Owner.TeamID)) or
    (not FTargetsEnemies and (TargetEntity.TeamID = Owner.TeamID)));
end;

{ TWelaTargetConstraintEventComponent }

constructor TWelaTargetConstraintEventComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Event : EnumEventIdentifier);
begin
  inherited CreateGrouped(Owner, Group);
  FEvent := Event;
end;

function TWelaTargetConstraintEventComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  Result := TargetEntity.Eventbus.Read(FEvent, []).AsBoolean;
end;

{ TWelaTargetConstraintOwningComponent }

function TWelaTargetConstraintOwningComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  Result := TargetEntity.Eventbus.Read(eiOwnerCommander, []).AsInteger = Eventbus.Read(eiOwnerCommander, []).AsInteger;
end;

{ TWelaTargetConstraintBuildTeamComponent }

function TWelaTargetConstraintBuildTeamComponent.IsPossible(const Target : RTarget) : boolean;
var
  TeamID : integer;
  TargetBuildZone : TBuildZone;
begin
  if not Target.IsBuildTarget then exit(False);
  TeamID := Owner.TeamID;
  TargetBuildZone := Target.GetBuildZone;
  Result := assigned(TargetBuildZone) and (TargetBuildZone.TeamID = TeamID);
end;

{ TWelaTargetConstraintGridComponent }

function TWelaTargetConstraintGridComponent.CheckGridNode(TargetBuildZone : TBuildZone; WorldCoord : RVector2) : boolean;
var
  Coord : RIntVector2;
  BuildZone : TBuildZone;
begin
  BuildZone := Game.Map.BuildZones.GetBuildZoneByPosition(WorldCoord);
  if not assigned(BuildZone) then exit(False);
  Coord := BuildZone.PositionToCoord(WorldCoord);
  Result := BuildZone.IsFree(Coord);
end;

function TWelaTargetConstraintGridComponent.IsPossible(const Target : RTarget) : boolean;
var
  X, Y : integer;
  targetPos : RVector2;
  TargetBuildZone : TBuildZone;
  NeededSize : RIntVector2;
begin
  if not Target.IsBuildTarget then exit(False);
  TargetBuildZone := Target.GetBuildZone;
  if not assigned(TargetBuildZone) then exit(False);

  Result := True;
  NeededSize := Eventbus.Read(eiWelaNeededGridSize, [], CurrentEvent.CalledToGroup).AsIntVector2;
  for X := 0 to NeededSize.X - 1 do
    for Y := 0 to NeededSize.Y - 1 do
    begin
      targetPos := TargetBuildZone.GetCenterOfField(Target.BuildGridCoordinate + RIntVector2.Create(X, Y));
      if not CheckGridNode(TargetBuildZone, targetPos) then
      begin
        if CheckAllFields then Result := False
        else exit(False);
      end;
    end;
end;

{ TWelaTargetConstraintNotSelfComponent }

function TWelaTargetConstraintNotSelfComponent.IsPossible(const Target : RTarget) : boolean;
begin
  Result := (not Target.IsEntity) or (Target.EntityID <> FOwner.ID);
end;

{ TWelaTargetConstraintWelaPropertyComponent }

function TWelaTargetConstraintWelaPropertyComponent.CheckGroup(Group : TArray<byte>) : TWelaTargetConstraintWelaPropertyComponent;
begin
  Result := self;
  FCheckGroup := ByteArrayToComponentGroup(Group);
end;

constructor TWelaTargetConstraintWelaPropertyComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FCheckGroup := [GROUP_MAINWEAPON];
end;

function TWelaTargetConstraintWelaPropertyComponent.MustHave(Types : TArray<byte>) : TWelaTargetConstraintWelaPropertyComponent;
begin
  Result := self;
  FMustHave := ByteArrayToSetDamageType(Types);
end;

function TWelaTargetConstraintWelaPropertyComponent.MustNotHave(Types : TArray<byte>) : TWelaTargetConstraintWelaPropertyComponent;
begin
  Result := self;
  FMustNotHave := ByteArrayToSetDamageType(Types);
end;

function TWelaTargetConstraintWelaPropertyComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
  DamageTypes : SetDamageType;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(True);

  DamageTypes := TargetEntity.Eventbus.Read(eiDamageType, [], FCheckGroup).AsType<SetDamageType>;
  Result := (FMustNotHave * DamageTypes = []) and
    (FMustHave <= DamageTypes);
end;

{ TWelaTargetConstraintBuffComponent }

function TWelaTargetConstraintBuffComponent.Blacklist(BuffTypes : TArray<byte>) : TWelaTargetConstraintBuffComponent;
begin
  Result := self;
  FWhiteBuffTypes := ByteArrayToSetBuffType(BuffTypes);
end;

constructor TWelaTargetConstraintBuffComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FWhiteBuffTypes := ALL_BUFF_TYPES;
  FBlackBuffTypes := []
end;

function TWelaTargetConstraintBuffComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
  BuffTypes : SetBuffType;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  BuffTypes := TargetEntity.Eventbus.Read(eiBuffed, []).AsType<SetBuffType>;
  Result := (BuffTypes * FWhiteBuffTypes = FWhiteBuffTypes) and // whitelist
    (BuffTypes * FBlackBuffTypes = []); // blacklist
end;

function TWelaTargetConstraintBuffComponent.Whitelist(BuffTypes : TArray<byte>) : TWelaTargetConstraintBuffComponent;
begin
  Result := self;
  FBlackBuffTypes := ByteArrayToSetBuffType(BuffTypes);
end;

{ TWelaTargetConstraintAlliesComponent }

constructor TWelaTargetConstraintAlliesComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group, False);
end;

{ TWelaTargetConstraintEnemiesComponent }

constructor TWelaTargetConstraintEnemiesComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group, True);
end;

{ TWelaTargetConstraintMaxTargetDistanceComponent }

procedure TWelaTargetConstraintMaxTargetDistanceComponent.Check(Targets : ATarget; var Validity : RTargetValidity);
var
  i, j : integer;
  Range : single;
begin
  j := 0;
  for i := 0 to Length(Targets) - 1 do
    if Targets[i].IsEmpty then
        inc(j);
  if j <= 1 then exit();
  Range := Eventbus.Read(eiAbilityTargetRange, [], ComponentGroup).AsSingle;
  if Range <= 0 then exit();
  for i := 0 to Length(Targets) - 2 do
    if Targets[i].IsEmpty then
      for j := i + 1 to Length(Targets) - 1 do
        if Targets[j].IsEmpty and (Targets[i].GetTargetPosition().distance(Targets[j].GetTargetPosition()) > Range) then
        begin
          Validity.SetTogetherValid(False);
          break;
        end;
end;

{ TWelaTargetConstraintDynamicZoneComponent }

function TWelaTargetConstraintDynamicZoneComponent.IgnoresTeams : TWelaTargetConstraintDynamicZoneComponent;
begin
  Result := self;
  FIgnoreTeam := True;
end;

function TWelaTargetConstraintDynamicZoneComponent.IsPossible(const Target : RTarget) : boolean;
var
  Pos : RVector2;
  TeamID : integer;
begin
  Pos := Target.GetTargetPosition;
  if FIgnoreTeam then TeamID := -1
  else TeamID := Owner.TeamID;
  Result := GlobalEventbus.Read(eiInDynamicZone, [Pos, TeamID, RParam.From<SetDynamicZone>(FDynamicZone)]).AsBoolean;
end;

function TWelaTargetConstraintDynamicZoneComponent.SetZone(Zone : TArray<byte>) : TWelaTargetConstraintDynamicZoneComponent;
begin
  Result := self;
  FDynamicZone := ByteArrayToSetDynamicZone(Zone);
end;

{ TWelaTargetConstraintResourceCompareComponent }

function TWelaTargetConstraintResourceCompareComponent.ComparedResource(Resource : EnumResource) : TWelaTargetConstraintResourceCompareComponent;
begin
  Result := self;
  if FComparedResource = reNone then
      FComparedResource := Resource
  else
  begin
    setLength(FAdditionalComparedResource, Length(FAdditionalComparedResource) + 1);
    FAdditionalComparedResource[high(FAdditionalComparedResource)] := Resource;
    assert((Resource in RES_INT_RESOURCES) = (FAdditionalComparedResource[0] in RES_INT_RESOURCES), 'TWelaTargetConstraintResourceCompareComponent.ComparedResource: All resources must be either integer or single, not mixed! Or implement it.');
  end;
end;

function TWelaTargetConstraintResourceCompareComponent.ComparesResourceCap : TWelaTargetConstraintResourceCompareComponent;
begin
  Result := self;
  FCompareCap := True;
end;

constructor TWelaTargetConstraintResourceCompareComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FTargetFactor := 1.0;
end;

function TWelaTargetConstraintResourceCompareComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetResource, OwnResource : RParam;
  TargetEntity : TEntity;
  i : integer;
begin
  Result := False;
  if Target.TryGetTargetEntity(TargetEntity) then
  begin
    if FCompareCap then
    begin
      OwnResource := Owner.Cap(FComparedResource, ComponentGroup);
      TargetResource := TargetEntity.Cap(FComparedResource);
    end
    else
    begin
      OwnResource := Owner.Balance(FComparedResource, ComponentGroup);
      TargetResource := TargetEntity.Balance(FComparedResource);
    end;

    for i := 0 to Length(FAdditionalComparedResource) - 1 do
    begin
      if FCompareCap then
      begin
        OwnResource := ResourceAdd(FComparedResource, OwnResource, Owner.Cap(FAdditionalComparedResource[i], ComponentGroup));
        TargetResource := ResourceAdd(FComparedResource, TargetResource, TargetEntity.Cap(FAdditionalComparedResource[i]));
      end
      else
      begin
        OwnResource := ResourceAdd(FComparedResource, OwnResource, Owner.Balance(FAdditionalComparedResource[i], ComponentGroup));
        TargetResource := ResourceAdd(FComparedResource, TargetResource, TargetEntity.Balance(FAdditionalComparedResource[i]));
      end;
    end;
    Result := ResourceCompare(FComparedResource, OwnResource, FComparator, TargetResource, FTargetFactor);
  end;
end;

function TWelaTargetConstraintResourceCompareComponent.SetComparator(Comparator : EnumComparator) : TWelaTargetConstraintResourceCompareComponent;
begin
  Result := self;
  FComparator := Comparator;
end;

function TWelaTargetConstraintResourceCompareComponent.TargetFactor(Factor : single) : TWelaTargetConstraintResourceCompareComponent;
begin
  Result := self;
  FTargetFactor := Factor;
end;

{ TWelaTriggerCheckTakeDamageComponent }

function TWelaTriggerCheckTakeDamageComponent.OnTriggerCheck(Amount, DamageType, InflictorID, Previous : RParam) : RParam;
begin
  Result := Previous.AsBooleanDefaultTrue and
    IsValid(Amount.AsSingle, DamageType.AsType<SetDamageType>, InflictorID.AsInteger);
end;

{ TWelaTriggerCheckTakeDamageThresholdComponent }

function TWelaTriggerCheckTakeDamageThresholdComponent.IsValid(Amount : single; DamageType : SetDamageType; InflictorID : integer) : boolean;
var
  Threshold : single;
begin
  Threshold := Eventbus.Read(eiWelaDamage, [], ComponentGroup).AsSingle;
  if FLesserEqualCheck then
      Result := Amount <= Threshold
  else
      Result := Amount >= Threshold;
end;

function TWelaTriggerCheckTakeDamageThresholdComponent.LesserEqual : TWelaTriggerCheckTakeDamageThresholdComponent;
begin
  Result := self;
  FLesserEqualCheck := True;
end;

{ TWelaTriggerCheckTakeDamageTypeComponent }

function TWelaTriggerCheckTakeDamageTypeComponent.MustNotHave(DamageTypes : TArray<byte>) : TWelaTriggerCheckTakeDamageTypeComponent;
begin
  Result := self;
  FMustNotHave := ByteArrayToSetDamageType(DamageTypes);
end;

function TWelaTriggerCheckTakeDamageTypeComponent.IsValid(Amount : single; DamageType : SetDamageType; InflictorID : integer) : boolean;
begin
  Result := (FMustNotHave * DamageType = []) and ((DamageType * FMustHave <> []) or (FMustHave = []));
end;

function TWelaTriggerCheckTakeDamageTypeComponent.MustHave(DamageTypes : TArray<byte>) : TWelaTriggerCheckTakeDamageTypeComponent;
begin
  Result := self;
  FMustHave := ByteArrayToSetDamageType(DamageTypes);
end;

{ TWelaReadyComponent }

function TWelaReadyComponent.IsReady : boolean;
begin
  Result := True;
end;

function TWelaReadyComponent.OnIsReady(PrevValue : RParam) : RParam;
begin
  Result := PrevValue.IsEmpty or PrevValue.AsBoolean;
  Result := IsReady and Result.AsBoolean;
end;

{ TWelaReadyCostComponent }

function TWelaReadyCostComponent.CommanderPays : TWelaReadyCostComponent;
begin
  Result := self;
  FDefaultPayingGroup := [];
  FRedirectToCommander := True;
end;

function TWelaReadyCostComponent.CostsCap : TWelaReadyCostComponent;
begin
  Result := self;
  FCostsCap := True;
end;

constructor TWelaReadyCostComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FValueGroup := ComponentGroup;
  FPayingGroup := TDictionary<EnumResource, SetComponentGroup>.Create;
  FDefaultPayingGroup := ComponentGroup;
end;

destructor TWelaReadyCostComponent.Destroy;
begin
  FPayingGroup.Free;
  inherited;
end;

function TWelaReadyCostComponent.GetPayingGroup(ResType : EnumResource) : SetComponentGroup;
begin
  if not FPayingGroup.TryGetValue(ResType, Result) then
      Result := FDefaultPayingGroup;
end;

function TWelaReadyCostComponent.IsReady : boolean;
var
  Costs : AResourceCost;
  Cost : RResourceCost;
  i : integer;
  PayingEntity : TEntity;
begin
  Result := True;
  Costs := Eventbus.Read(eiResourceCost, [], FValueGroup).AsAResourceCost;
  if assigned(Costs) then
  begin
    if FRedirectToCommander then PayingEntity := Game.EntityManager.GetOwningCommander(Owner)
    else PayingEntity := Owner;

    assert(assigned(PayingEntity), 'TWelaReadyCostComponent.Fire: Could not find payer, should never happen!');
    if assigned(PayingEntity) then
      for i := 0 to Length(Costs) - 1 do
      begin
        Cost := Costs[i];
        if FCostsCap and not(Cost.ResourceType in [reLevel, reTier]) then
            Cost.Amount := PayingEntity.Cap(Cost.ResourceType, GetPayingGroup(Cost.ResourceType));
        Result := Result and PayingEntity.Eventbus.Read(eiResourceSubtraction, [ord(Cost.ResourceType), Cost.Amount], GetPayingGroup(Cost.ResourceType)).AsBoolean;
      end;
  end;
end;

function TWelaReadyCostComponent.SetPayingGroup(Group : TArray<byte>) : TWelaReadyCostComponent;
begin
  Result := self;
  FDefaultPayingGroup := ByteArrayToComponentGroup(Group);
end;

function TWelaReadyCostComponent.SetPayingGroupForType(ResourceType : integer; Group : TArray<byte>) : TWelaReadyCostComponent;
begin
  Result := self;
  FPayingGroup.AddOrSetValue(EnumResource(ResourceType), ByteArrayToComponentGroup(Group));
end;

function TWelaReadyCostComponent.ValueGroup(Group : TArray<byte>) : TWelaReadyCostComponent;
begin
  Result := self;
  FValueGroup := ByteArrayToComponentGroup(Group);
end;

{ TWelaReadyCooldownComponent }

function TWelaReadyCooldownComponent.Cooldown(CooldownMs : integer) : TWelaReadyCooldownComponent;
begin
  Result := self;
  FFixedCooldown := True;
  FFixedInterval := CooldownMs;
  InitTimer;
end;

constructor TWelaReadyCooldownComponent.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>; ReadyAtStart : boolean);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FReadyGroup := self.ComponentGroup;
  FReadyAfterStart := ReadyAtStart;
  FCooldown := TGameTimer.Create;
  InitTimer;
end;

destructor TWelaReadyCooldownComponent.Destroy;
begin
  FCooldown.Free;
  inherited;
end;

procedure TWelaReadyCooldownComponent.FinishTimer;
begin
  StartTimer;
  FCooldown.Expired := True;
end;

function TWelaReadyCooldownComponent.FireGroup(FireGroup : TArray<byte>) : TWelaReadyCooldownComponent;
begin
  Result := self;
  FFireGroup := ByteArrayToComponentGroup(FireGroup);
end;

procedure TWelaReadyCooldownComponent.InitTimer;
begin
  StartTimer();
  OnSetWelaActive(Eventbus.Read(eiWelaActive, [], self.ComponentGroup));
  if FReadyAfterStart then FCooldown.Expired := True;
  {$IFDEF SERVER}
  SaveTimer;
  {$ENDIF}
  {$IFDEF CLIENT}
  UpdateTimer;
  {$ENDIF}
end;

function TWelaReadyCooldownComponent.IsReady : boolean;
begin
  if FOnce and FOnceDone then
      exit(True);
  {$IFDEF CLIENT}
  UpdateTimer;
  {$ENDIF}
  Result := FCooldown.Expired and Eventbus.Read(eiWelaActive, [], ComponentGroup).AsBooleanDefaultTrue;
  if FOnce and Result then FOnceDone := True;
end;

function TWelaReadyCooldownComponent.OnAfterCreate : boolean;
begin
  Result := True;
  OnSetWelaActive(Eventbus.Read(eiWelaActive, [], ComponentGroup));
  if FReadyAfterStart then FCooldown.Expired := True;
  {$IFDEF SERVER}
  SaveTimer;
  {$ENDIF}
end;

function TWelaReadyCooldownComponent.Once : TWelaReadyCooldownComponent;
begin
  Result := self;
  FOnce := True;
end;

function TWelaReadyCooldownComponent.OnCooldownProgress : RParam;
begin
  if FOnce and FOnceDone then exit(1.0);
  if FCooldown.Paused then Result := -1.0
  else Result := HMath.Saturate(FCooldown.ZeitDiffProzent);
end;

function TWelaReadyCooldownComponent.OnCooldownRemainingTime : RParam;
begin
  if FOnce and FOnceDone then exit(0.0);
  if FCooldown.Paused then Result := -1.0
  else Result := FCooldown.TimeToExpired;
end;

function TWelaReadyCooldownComponent.OnCooldownReset(Finish : RParam) : boolean;
begin
  Result := True;
  if Finish.AsBoolean then
      FinishTimer
  else
      StartTimer;
  {$IFDEF SERVER}
  SaveTimer;
  {$ENDIF}
end;

function TWelaReadyCooldownComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if (FFireGroup = []) or (FFireGroup * CurrentEvent.CalledToGroup <> []) then
  begin
    StartTimer;
    {$IFDEF SERVER}
    SaveTimer;
    {$ENDIF}
  end;
end;

function TWelaReadyCooldownComponent.OnIsReady(Previous : RParam) : RParam;
begin
  if CurrentEvent.CalledToGroup * FReadyGroup = [] then Result := Previous
  else
  begin
    Result := Previous.IsEmpty or Previous.AsBoolean;
    Result := IsReady and Result.AsBoolean;
  end;
end;

function TWelaReadyCooldownComponent.OnSetWelaActive(IsActive : RParam) : boolean;
begin
  Result := True;
  StartTimer;
  if FReadyAfterStart then
      FCooldown.Expire;
  if not IsActive.AsBooleanDefaultTrue then
      FCooldown.Pause
  else FCooldown.Weiter;
  {$IFDEF SERVER}
  SaveTimer;
  {$ENDIF}
end;

function TWelaReadyCooldownComponent.ReadyGroup(ReadyGroup : TArray<byte>) : TWelaReadyCooldownComponent;
begin
  Result := self;
  FReadyGroup := ByteArrayToComponentGroup(ReadyGroup);
  InitTimer; // reload cooldown
end;

procedure TWelaReadyCooldownComponent.StartTimer();
begin
  if FFixedCooldown then FCooldown.Interval := FFixedInterval
  else FCooldown.Interval := Eventbus.Read(eiCooldown, [], FReadyGroup).AsInteger - Eventbus.Read(eiWelaActionpoint, [], FReadyGroup).AsInteger;
  FCooldown.Reset;
end;

{$IFDEF SERVER}


procedure TWelaReadyCooldownComponent.SaveTimer;
begin
  Eventbus.Write(eiCooldownStartingTime, [FCooldown.StartingTime], ComponentGroup);
end;
{$ENDIF}

{$IFDEF CLIENT}


function TWelaReadyCooldownComponent.OnWriteCooldownStartingTime(StartingTime : RParam) : boolean;
begin
  Result := True;
  FCooldown.StartingTime := StartingTime.AsSingle;
end;

procedure TWelaReadyCooldownComponent.UpdateTimer;
begin
  FCooldown.StartingTime := Eventbus.Read(eiCooldownStartingTime, [], ComponentGroup).AsSingle;
end;

{$ENDIF}

{ TWelaReadyAfterGameStartComponent }

function TWelaReadyAfterGameStartComponent.IsReady : boolean;
begin
  Result := FReady;
end;

function TWelaReadyAfterGameStartComponent.OnGameTick : boolean;
begin
  Result := True;
  FReady := True;
end;

{ TWelaReadyResourceCompareComponent }

function TWelaReadyResourceCompareComponent.CheckEmpty : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  SetComparator(coLowerEqual);
  ReferenceValue(0);
end;

function TWelaReadyResourceCompareComponent.CheckFull : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  SetComparator(coGreaterEqual);
  ReferenceValue(1);
end;

function TWelaReadyResourceCompareComponent.CheckingGroup(Group : TArray<byte>) : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  FCheckingGroup := ByteArrayToComponentGroup(Group);
end;

function TWelaReadyResourceCompareComponent.CheckNotEmpty : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  SetComparator(coGreater);
  ReferenceValue(0);
end;

function TWelaReadyResourceCompareComponent.CheckNotFull : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  SetComparator(coLower);
  ReferenceValue(1);
end;

function TWelaReadyResourceCompareComponent.ChecksCommander : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  FChecksCommander := True;
end;

function TWelaReadyResourceCompareComponent.ComparedResource(Resource : EnumResource) : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  if FComparedResource = reNone then
      FComparedResource := Resource
  else
  begin
    setLength(FAdditionalComparedResource, Length(FAdditionalComparedResource) + 1);
    FAdditionalComparedResource[high(FAdditionalComparedResource)] := Resource;
    assert((Resource in RES_INT_RESOURCES) = (FAdditionalComparedResource[0] in RES_INT_RESOURCES), 'TWelaReadyResourceCompareComponent.ComparedResource: All resources must be either integer or single, not mixed! Or implement it.');
  end;
end;

function TWelaReadyResourceCompareComponent.IsReady : boolean;
var
  Balance, Cap : RParam;
  CheckedEntity : TEntity;
  i : integer;
begin
  if FChecksCommander then CheckedEntity := Game.EntityManager.GetOwningCommander(Owner)
  else CheckedEntity := Owner;
  if not assigned(CheckedEntity) then exit(True);
  Balance := CheckedEntity.Balance(FComparedResource, FCheckingGroup);
  for i := 0 to Length(FAdditionalComparedResource) - 1 do
      Balance := ResourceAdd(FComparedResource, Balance, CheckedEntity.Balance(FAdditionalComparedResource[i], FCheckingGroup));
  if FReferenceIsAbsolute then
      Result := ResourceCompare(FComparedResource, Balance, FComparator, FReferenceValue)
  else
  begin
    Cap := CheckedEntity.Cap(FComparedResource, FCheckingGroup);
    for i := 0 to Length(FAdditionalComparedResource) - 1 do
        Cap := ResourceAdd(FComparedResource, Cap, CheckedEntity.Cap(FAdditionalComparedResource[i], FCheckingGroup));
    Result := ResourceCompare(reFloat, ResourcePercentage(FComparedResource, Balance, Cap), FComparator, FReferenceValue);
  end;
end;

function TWelaReadyResourceCompareComponent.ReferenceIsAbsolute : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  FReferenceIsAbsolute := True;
end;

function TWelaReadyResourceCompareComponent.ReferenceValue(ReferenceValue : single) : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  FReferenceValue := ReferenceValue;
end;

function TWelaReadyResourceCompareComponent.SetComparator(Comparator : EnumComparator) : TWelaReadyResourceCompareComponent;
begin
  Result := self;
  FComparator := Comparator;
end;

{ TWelaReadySpawnedComponent }

function TWelaReadySpawnedComponent.IsReady : boolean;
var
  SpawnedUnit : string;
begin
  Result := True;
  SpawnedUnit := Eventbus.Read(eiWelaUnitPattern, [], ComponentGroup).AsString;
  if not HLog.AssertAndLog(SpawnedUnit <> '', 'TWelaReadySpawnedComponent.IsReady: Wela Unit Pattern assumed if this component is used.') then
  begin
    EntityDataCache.Write(SpawnedUnit, CardLeague, CardLevel, eiOwnerCommander, [Eventbus.Read(eiOwnerCommander, [])]);
    Result := EntityDataCache.Read(SpawnedUnit, CardLeague, CardLevel, eiIsReady, [], -1, True).AsBooleanDefaultTrue;
  end;
end;

{ TWelaReadyUnitPropertyComponent }

function TWelaReadyUnitPropertyComponent.ChecksCommander : TWelaReadyUnitPropertyComponent;
begin
  Result := self;
  FChecksCommander := True;
end;

function TWelaReadyUnitPropertyComponent.IsReady : boolean;
var
  TargetEntity : TEntity;
  UnitProperties : SetUnitProperty;
begin
  if FChecksCommander then TargetEntity := Game.EntityManager.GetOwningCommander(Owner)
  else TargetEntity := Owner;
  if not assigned(TargetEntity) then exit(True);
  UnitProperties := TargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty>;
  Result :=
    (FMustList <= UnitProperties) and
    ((FMustAnyList = []) or (FMustAnyList * UnitProperties <> [])) and
    (FMustNotList * UnitProperties = []) and
    ((FMustNotAllList = []) or not(FMustNotAllList <= UnitProperties));
end;

function TWelaReadyUnitPropertyComponent.MustHave(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
begin
  Result := self;
  FMustList := ByteArrayToSetUnitProperies(Properties);
end;

function TWelaReadyUnitPropertyComponent.MustHaveAny(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
begin
  Result := self;
  FMustAnyList := ByteArrayToSetUnitProperies(Properties);
end;

function TWelaReadyUnitPropertyComponent.MustNotHave(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
begin
  Result := self;
  FMustNotList := ByteArrayToSetUnitProperies(Properties);
end;

function TWelaReadyUnitPropertyComponent.MustNotHaveAll(Properties : TArray<byte>) : TWelaReadyUnitPropertyComponent;
begin
  Result := self;
  FMustNotAllList := ByteArrayToSetUnitProperies(Properties);
end;

{ TWelaEventRedirecter }

function TWelaEventRedirecter.CopyIndexedValue(Event : EnumEventIdentifier; SourceGroup : TArray<byte>; Resource : integer; TargetGroup : TArray<byte>) : TWelaEventRedirecter;
var
  Value : RParam;
begin
  Result := self;
  Value := EntityDataCache.Read(GetPattern(ComponentGroup), CardLeague, CardLevel, Event, ByteArrayToComponentGroup(SourceGroup), Resource);
  Owner.Blackboard.SetIndexedValue(Event, ByteArrayToComponentGroup(TargetGroup), Resource, Value);
end;

function TWelaEventRedirecter.CopyValue(Event : EnumEventIdentifier; SourceGroup : TArray<byte>; TargetGroup : TArray<byte>) : TWelaEventRedirecter;
var
  Value : RParam;
begin
  Result := self;
  Value := EntityDataCache.Read(GetPattern(ComponentGroup), CardLeague, CardLevel, Event, ByteArrayToComponentGroup(SourceGroup));
  Owner.Blackboard.SetValue(Event, ByteArrayToComponentGroup(TargetGroup), Value);
end;

function TWelaEventRedirecter.GetPattern(TargetGroup : SetComponentGroup) : string;
begin
  Result := Eventbus.Read(eiWelaUnitPattern, [], TargetGroup).AsString;
end;

function TWelaEventRedirecter.OnCollisionRadius(Previous : RParam) : RParam;
begin
  if Previous.IsEmpty then
      Result := EntityDataCache.GetEntity(GetPattern(CurrentEvent.CalledToGroup), CardLeague, CardLevel).CollisionRadius
  else
      Result := Previous;
end;

function TWelaEventRedirecter.OnRedirect(Previous : RParam) : RParam;
begin
  Result := Redirect(CurrentEvent.EventIdentifier, Previous);
end;

function TWelaEventRedirecter.Redirect(Event : EnumEventIdentifier; Previous : RParam) : RParam;
begin
  Result := Previous;
  if Previous.IsEmpty then
      Result := EntityDataCache.Read(GetPattern(CurrentEvent.CalledToGroup), CardLeague, CardLevel, Event);
end;

{ TWarheadApplyScriptComponent }

procedure TWarheadApplyScriptComponent.Apply(Entity : TEntity);
var
  Parameters : TArray<TValue>;
  i : integer;
  Method : string;
begin
  if FParameters.Count > 0 then
  begin
    setLength(Parameters, FParameters.Count + 1);
    Parameters[0] := TValue.From<TEntity>(Entity);
    for i := 0 to FParameters.Count - 1 do
        Parameters[i + 1] := FParameters[i].GetValue(Eventbus, ComponentGroup);
  end;
  if FMethodname <> '' then
      Method := FMethodname
  else
      Method := 'Apply';
  Entity.ApplyScript(FScriptName, Method, Parameters)
end;

function TWarheadApplyScriptComponent.ApplyToProducedUnits : TWarheadApplyScriptComponent;
begin
  FAtUnitProduced := True;
  Result := self;
end;

function TWarheadApplyScriptComponent.ApplyToSelfAfterDelay(Duration : integer) : TWarheadApplyScriptComponent;
begin
  Result := self;
  FTimer := TTimer.CreateAndStart(Duration);
end;

function TWarheadApplyScriptComponent.ApplyToSelfAtCreate : TWarheadApplyScriptComponent;
begin
  Result := self;
  FAfterCreate := True;
end;

constructor TWarheadApplyScriptComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; ScriptToApply : string);
begin
  inherited CreateGrouped(Owner, Group);
  FScriptName := ScriptToApply;
  FParameters := TList<RParameter>.Create;
end;

destructor TWarheadApplyScriptComponent.Destroy;
begin
  FParameters.Free;
  FTimer.Free;
  inherited;
end;

function TWarheadApplyScriptComponent.Methodname(const Methodname : string) : TWarheadApplyScriptComponent;
begin
  Result := self;
  FMethodname := Methodname;
end;

function TWarheadApplyScriptComponent.OnAfterCreate : boolean;
begin
  Result := True;
  if FAfterCreate then
  begin
    Apply(Owner);
    DeferFree;
  end;
end;

function TWarheadApplyScriptComponent.OnFireWarhead(Targets : RParam) : boolean;
var
  Entity : TEntity;
  TargetsArray : ATarget;
  Target : RTarget;
  i : integer;
begin
  Result := True;
  if not FAtUnitProduced and not FNotAtFire and IsLocalCall then
  begin
    TargetsArray := Targets.AsATarget;
    for i := 0 to Length(TargetsArray) - 1 do
    begin
      Target := TargetsArray[i];
      if Target.IsEntity and Target.TryGetTargetEntity(Entity) then
      begin
        FCurrentTarget := Entity;
        Apply(Entity);
        FCurrentTarget := nil;
      end;
    end;
  end;
end;

function TWarheadApplyScriptComponent.OnIdle : boolean;
begin
  Result := True;
  if assigned(FTimer) and FTimer.Expired then
  begin
    Apply(Owner);
    FreeAndNil(FTimer);
    DeferFree;
  end;
end;

function TWarheadApplyScriptComponent.OnWelaUnitProduced(EntityID : RParam) : boolean;
var
  Entity : TEntity;
begin
  Result := True;
  if FAtUnitProduced and IsLocalCall then
  begin
    if Game.EntityManager.TryGetEntityByID(EntityID.AsInteger, Entity) then
        Apply(Entity);
  end;
end;

function TWarheadApplyScriptComponent.OverrideLastParameterGroup(Group : TArray<byte>) : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter := FParameters.Last;
  Parameter.ParameterGroup := ByteArrayToComponentGroup(Group);
  Parameter.UsesGroupOverride := True;
  FParameters[FParameters.Count - 1] := Parameter;
end;

function TWarheadApplyScriptComponent.PassValueFromEvent(Event : integer) : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.ParameterEvent := EnumEventIdentifier(Event);
  case Parameter.ParameterEvent of
    eiCooldown, eiColorIdentity, eiTeamID : Parameter.ParameterType := ptIntegerEvent;
    eiWelaDamage, eiWelaRange, eiWelaAreaOfEffect : Parameter.ParameterType := ptSingleEvent;
    eiFront : Parameter.ParameterType := ptRVector2Event;
  else
    MakeException('PassValueFromEvent: %s is not supported yet, maybe you can add it? :)', [Hrtti.EnumerationToString<EnumEventIdentifier>(Parameter.ParameterEvent)]);
  end;
  Parameter.PublicEvent := Parameter.ParameterEvent in [eiColorIdentity, eiTeamID, eiFront];
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassBooleanValue(Value : boolean) : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.ParameterType := ptBoolean;
  Parameter.ParameterBooleanValue := Value;
  Parameter.PublicEvent := False;
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassDirectionToTarget : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.Owner := self;
  Parameter.ParameterType := ptDirectionToTarget;
  Parameter.PublicEvent := False;
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassIntValue(Value : integer) : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.ParameterType := ptInteger;
  Parameter.ParameterIntValue := Value;
  Parameter.PublicEvent := False;
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassOffsetToOwner : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.Owner := self;
  Parameter.ParameterType := ptOffsetToTarget;
  Parameter.PublicEvent := False;
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassResource(Resource : EnumResource) : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.Owner := self;
  Parameter.ParameterType := ptResource;
  Parameter.ParameterResource := Resource;
  Parameter.PublicEvent := False;
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassSameTeam : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.Owner := self;
  Parameter.ParameterType := ptBooleanSameTeam;
  Parameter.PublicEvent := True;
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassSavedTargetPosition(Index : integer) : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.ParameterType := ptRVector2Event;
  Parameter.ParameterEvent := eiWelaSavedTargets;
  Parameter.PublicEvent := False;
  Parameter.Index := index;
  FParameters.Add(Parameter);
end;

function TWarheadApplyScriptComponent.PassSingleValue(Value : single) : TWarheadApplyScriptComponent;
var
  Parameter : RParameter;
begin
  Result := self;
  Parameter.ParameterType := ptSingle;
  Parameter.ParameterSingleValue := Value;
  Parameter.PublicEvent := False;
  FParameters.Add(Parameter);
end;

{ TWarheadLinkApplyScriptComponent }

procedure TWarheadLinkApplyScriptComponent.BeforeComponentFree;
var
  Targets : ATarget;
  Target : RTarget;
  Entity : TEntity;
begin
  // if Game is been closed some other entites might already been freed, as all entities are freed we don't need to deregister
  if not(assigned(Game) and not Game.IsShuttingDown) then
      exit;
  Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
  if not Targets.HasIndex(0) then
      MakeException('Destroy: No destinations are set!');
  Target := Targets[0];
  if Target.TryGetTargetEntity(Entity) and not(FSavedScriptGroup = []) then
  begin
    GlobalEventbus.Trigger(eiRemoveComponentGroup, [Entity.ID, RParam.From<SetComponentGroup>(FSavedScriptGroup)]);
  end;
  inherited;
end;

constructor TWarheadLinkApplyScriptComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; ScriptToApply : string);
begin
  inherited CreateGrouped(Owner, Group, ScriptToApply);
  FNotAtFire := True;
end;

function TWarheadLinkApplyScriptComponent.OnAfterCreate : boolean;
var
  Targets : ATarget;
  Target : RTarget;
  Entity : TEntity;
begin
  Result := True;
  Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
  if not Targets.HasIndex(0) then
      MakeException('Destroy: No destinations are set!');
  Target := Targets[0];
  if Target.TryGetTargetEntity(Entity) and Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Entity).ToRParam], ComponentGroup).AsRTargetValidity.IsValid then
  begin
    FSavedScriptGroup := Entity.ApplyScriptReturnGroups(FScriptName);
    assert(FSavedScriptGroup <> [], 'TWarheadLinkApplyScriptComponent.OnAfterCreate: (SavedGroup = [])! Error or intended?');
    Entity.Eventbus.Write(eiCreator, [Eventbus.Read(eiCreator, [])], FSavedScriptGroup);
    Entity.Eventbus.Write(eiCreatorGroup, [Eventbus.Read(eiCreatorGroup, [])], FSavedScriptGroup);
  end
  else FSavedScriptGroup := [];
end;

function TWarheadLinkApplyScriptComponent.OnReplaceEntity(OldEntityID, NewEntityID, IsSameEntity : RParam) : boolean;
var
  Targets : ATarget;
begin
  Result := True;
  Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
  assert((Targets.Count = 1) and Targets[0].IsEntity);
  if (Targets[0].EntityID = OldEntityID.AsInteger) and IsSameEntity.AsBoolean then
      GlobalEventbus.Trigger(eiRemoveComponentGroup, [NewEntityID.AsInteger, RParam.From<SetComponentGroup>(FSavedScriptGroup)]);
end;

{ TWarheadApplyScriptComponent.RParameter }

function TWarheadApplyScriptComponent.RParameter.GetValue(Eventbus : TEventbus; ComponentGroup : SetComponentGroup) : TValue;
var
  Targets : ATarget;
begin
  if PublicEvent then
      ComponentGroup := [];
  if UsesGroupOverride then
      ComponentGroup := self.ParameterGroup;
  case self.ParameterType of
    ptNone : raise ENotSupportedException.Create('TWarheadApplyScriptComponent.RParameter.GetValue: Unknown parameter type!');
    ptIntegerEvent : Result := TValue.From<integer>(Eventbus.Read(ParameterEvent, [], ComponentGroup).AsInteger);
    ptSingleEvent : Result := TValue.From<single>(Eventbus.Read(ParameterEvent, [], ComponentGroup).AsSingle);
    ptRVector2Event :
      begin
        if ParameterEvent = eiWelaSavedTargets then
        begin
          Targets := Eventbus.Read(ParameterEvent, [], ComponentGroup).AsATarget;
          if Length(Targets) < index + 1 then
              raise ENotSupportedException.Create('TWarheadApplyScriptComponent.RParameter.GetValue(eiWelaSavedTargets): Not enough targets saved!');
          Result := TValue.From<RVector2>(Targets[index].GetTargetPosition)
        end
        else
            Result := TValue.From<RVector2>(Eventbus.Read(ParameterEvent, [], ComponentGroup).AsVector2);
      end;
    ptInteger : Result := TValue.From<integer>(ParameterIntValue);
    ptSingle : Result := TValue.From<single>(ParameterSingleValue);
    ptBoolean : Result := TValue.From<boolean>(ParameterBooleanValue);
    ptBooleanSameTeam :
      begin
        assert(assigned(Owner.FCurrentTarget), 'TWarheadApplyScriptComponent.RParameter.GetValue(ptBooleanSameTeam): Invalid target, probably due to usage of ptBooleanSameTeam with other triggers than a entity target!');
        Result := TValue.From<boolean>(Eventbus.Owner.TeamID = Owner.FCurrentTarget.TeamID);
      end;
    ptDirectionToTarget :
      begin
        assert(assigned(Owner.FCurrentTarget), 'TWarheadApplyScriptComponent.RParameter.GetValue(ptDirectionToTarget): Invalid target, probably due to usage of ptDirectionToTarget with other triggers than FireWarhead!');
        Result := TValue.From<RVector2>(Eventbus.Owner.Position.DirectionTo(Owner.FCurrentTarget.Position));
      end;
    ptOffsetToTarget :
      begin
        assert(assigned(Owner.FCurrentTarget), 'TWarheadApplyScriptComponent.RParameter.GetValue(ptOffsetToTarget): Invalid target, probably due to usage of ptOffsetToTarget with other triggers than FireWarhead!');
        Result := TValue.From<RVector2>(Owner.FCurrentTarget.Position - Eventbus.Owner.Position);
      end;
    ptResource :
      begin
        if ParameterResource in RES_INT_RESOURCES then
            Result := TValue.From<integer>(Eventbus.Owner.Balance(ParameterResource, ComponentGroup).AsInteger)
        else
            Result := TValue.From<single>(Eventbus.Owner.Balance(ParameterResource, ComponentGroup).AsSingle);
      end;
  end;
end;

{ TWelaTargetConstraintCardNameComponent }

function TWelaTargetConstraintCardNameComponent.AddCard(const ScriptFileName : string) : TWelaTargetConstraintCardNameComponent;
begin
  Result := self;
  HArray.Push<string>(FCards, ScriptFileName);
end;

function TWelaTargetConstraintCardNameComponent.IsPossible(const Target : RTarget) : boolean;
var
  Entity : TEntity;
  i : integer;
begin
  Result := False;
  if Target.IsEntity and Target.TryGetTargetEntity(Entity) then
  begin
    for i := 0 to Length(FCards) - 1 do
        Result := Result or Entity.ScriptFileName.StartsWith(FCards[i], True);
  end;
end;

{ TWelaHelperResolveComponent }

function TWelaHelperResolveComponent.GetCurrentIndex : integer;
var
  UnitProperties : SetUnitProperty;
begin
  case FSource of
    rsTeamID : Result := Owner.TeamID;
    rsLevel : Result := Owner.Balance(reLevel, FLevelGroup).AsInteger;
    rsResource : Result := Owner.Balance(FResource, FLevelGroup).AsInteger;
    rsTier :
      begin
        if GlobalEventbus.Read(eiGameEventTimeTo, [GAME_EVENT_TECH_LEVEL_2]).AsInteger > 0 then Result := 0
        else if GlobalEventbus.Read(eiGameEventTimeTo, [GAME_EVENT_TECH_LEVEL_3]).AsInteger > 0 then Result := 1
        else Result := 2;
      end;
    rsOwnerTier :
      begin
        UnitProperties := Owner.UnitProperties;
        if upTier1 in UnitProperties then
            Result := 1
        else if upTier2 in UnitProperties then
            Result := 1
        else
            Result := 3;
      end;
  else
    raise ENotImplemented.Create('TWelaHelperResolveComponent.GetCurrentIndex: Missing implementation of resolve source!');
  end;
end;

function TWelaHelperResolveComponent.OnFetch(Previous : RParam) : RParam;
begin
  Result := Owner.Blackboard.GetIndexedValue(CurrentEvent.EventIdentifier, CurrentEvent.CalledToGroup, GetCurrentIndex);
  if Result.IsEmpty then
      Result := Previous;
end;

function TWelaHelperResolveComponent.ResolveCurrentTier : TWelaHelperResolveComponent;
begin
  Result := self;
  FSource := rsTier;
end;

function TWelaHelperResolveComponent.ResolveLevel(LevelGroup : TArray<byte>) : TWelaHelperResolveComponent;
begin
  Result := self;
  FSource := rsLevel;
  FLevelGroup := ByteArrayToComponentGroup(LevelGroup);
end;

function TWelaHelperResolveComponent.ResolveResource(Resource : EnumResource; ResourceGroup : TArray<byte>) : TWelaHelperResolveComponent;
begin
  Result := self;
  FSource := rsResource;
  FLevelGroup := ByteArrayToComponentGroup(ResourceGroup);
  FResource := Resource;
  assert(FResource in RES_INT_RESOURCES, 'TWelaHelperResolveComponent.ResolveResource: Only integer resources supported.');
end;

function TWelaHelperResolveComponent.ResolveTeamID : TWelaHelperResolveComponent;
begin
  Result := self;
  FSource := rsTeamID;
end;

function TWelaHelperResolveComponent.ResolveTier : TWelaHelperResolveComponent;
begin
  Result := self;
  FSource := rsOwnerTier;
end;

{ TWelaTargetConstraintResourceComponent }

function TWelaTargetConstraintResourceComponent.CheckEmpty : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  Reference(0);
  Comparator(coLowerEqual);
end;

function TWelaTargetConstraintResourceComponent.CheckFull : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  Reference(1);
  Comparator(coGreaterEqual);
end;

function TWelaTargetConstraintResourceComponent.CheckHasResource : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  CompareCapToReference;
  Reference(0);
  Comparator(coGreater);
end;

function TWelaTargetConstraintResourceComponent.CheckNotEmpty : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  Reference(0);
  Comparator(coGreater);
end;

function TWelaTargetConstraintResourceComponent.CheckNotFull : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  Reference(1);
  Comparator(coLower);
end;

function TWelaTargetConstraintResourceComponent.CheckResource(ResourceID : EnumResource) : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  FComparedResource := ResourceID;
end;

function TWelaTargetConstraintResourceComponent.Comparator(Comparator : EnumComparator) : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  FComparator := Comparator;
end;

function TWelaTargetConstraintResourceComponent.CompareBalanceToReference() : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  FCompareBalanceToReference := True;
end;

function TWelaTargetConstraintResourceComponent.CompareCapToReference() : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  FCompareCapToReference := True;
end;

function TWelaTargetConstraintResourceComponent.CompareMissingToReference : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  FCompareMissingToReference := True;
end;

function TWelaTargetConstraintResourceComponent.IsPossible(const Target : RTarget) : boolean;
var
  Value, Balance, Cap : RParam;
  TargetEntity : TEntity;
  ComparedResource : EnumResource;
begin
  Result := False;
  if Target.TryGetTargetEntity(TargetEntity) then
  begin
    ComparedResource := FComparedResource;
    Balance := TargetEntity.Eventbus.Read(eiResourceBalance, [ord(FComparedResource)]);
    Cap := TargetEntity.Eventbus.Read(eiResourceCap, [ord(FComparedResource)]);
    // if resource not present, the constraint can't be valid
    if Balance.IsEmpty or (Cap.IsEmpty and not FCompareBalanceToReference) then exit(False);

    if FCompareBalanceToReference then Value := Balance
    else if FCompareCapToReference then Value := Cap
    else if FCompareMissingToReference then Value := ResourceSubtract(FComparedResource, Cap, Balance)
    else
    begin
      Value := ResourcePercentage(
        FComparedResource,
        Balance,
        Cap
        );
      ComparedResource := reFloat;
    end;
    Result := ResourceCompare(ComparedResource, Value, FComparator, FReference);
  end;
end;

function TWelaTargetConstraintResourceComponent.Reference(Reference : single) : TWelaTargetConstraintResourceComponent;
begin
  Result := self;
  FReference := Reference;
end;

{ TWelaTargetConstraintNeverComponent }

function TWelaTargetConstraintNeverComponent.IsPossible(const Target : RTarget) : boolean;
begin
  Result := False;
end;

{ TModifierWelaTargetCountComponent }

function TModifierWelaTargetCountComponent.OnWelaTargetCount(Previous : RParam) : RParam;
var
  AddValue : integer;
  newTargetCount : integer;
begin
  AddValue := Eventbus.Read(eiWelaModifier, [], FValueGroup).AsInteger;
  if AddValue > 0 then
  begin
    if FScalesWithResource <> reNone then
    begin
      if FScalesWithResource in RES_FLOAT_RESOURCES then
          AddValue := trunc(AddValue * Owner.Balance(FScalesWithResource, ComponentGroup).AsSingle)
      else
          AddValue := AddValue * Owner.Balance(FScalesWithResource, ComponentGroup).AsInteger;
    end;
    newTargetCount := Previous.AsIntegerDefault(1) + AddValue;
    Result := newTargetCount;
  end
  else Result := Previous;
end;

function TModifierWelaTargetCountComponent.ScaleWithResource(Resource : EnumResource) : TModifierWelaTargetCountComponent;
begin
  Result := self;
  FScalesWithResource := Resource;
end;

{ TWelaTargetConstraintBlacklistComponent }

function TWelaTargetConstraintBlacklistComponent.IsPossible(const Target : RTarget) : boolean;
var
  SavedTargets : ATarget;
begin
  SavedTargets := Eventbus.Read(eiWelaSavedTargets, [], ComponentGroup).AsATarget;
  Result := not SavedTargets.Contains(Target);
end;

{ TModifierWelaRangeComponent }

function TModifierWelaRangeComponent.ActivateOnStand : TModifierWelaRangeComponent;
begin
  Result := self;
  FActivateOnStand := True;
end;

function TModifierWelaRangeComponent.AddModifier : TModifierWelaRangeComponent;
begin
  Result := self;
  FAdditive := True;
end;

function TModifierWelaRangeComponent.DeactivateOnMoveTo : TModifierWelaRangeComponent;
begin
  Result := self;
  FDeactivateOnMoveTo := True;
end;

destructor TModifierWelaRangeComponent.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TModifierWelaRangeComponent.OnMoveTo(Target, Range : RParam) : boolean;
begin
  Result := True;
  if assigned(FTimer) and FDeactivateOnMoveTo then
      FTimer.StartAndPause;
end;

function TModifierWelaRangeComponent.OnStand : boolean;
begin
  Result := True;
  if assigned(FTimer) and FActivateOnStand then
      FTimer.Start;
end;

function TModifierWelaRangeComponent.OnWelaRange(Previous : RParam) : RParam;
var
  Factor : single;
begin
  if not Previous.IsEmpty and IsActive then
  begin
    Factor := Eventbus.Read(eiWelaModifier, [], FValueGroup).AsSingleDefault(1);
    if assigned(FTimer) then
        Factor := Factor * FTimer.ZeitDiffProzent(True);
    if FScaleWithStage then
    begin
      {$IFDEF CLIENT}
      if assigned(ClientGame) then
          Factor := Factor * ClientGame.CommanderManager.ActiveCommander.Balance(reTier).AsInteger;
      {$ENDIF}
      {$IFDEF SERVER}
      if assigned(ServerGame) and (ServerGame.Commanders.Count > 0) then
          Factor := Factor * ServerGame.Commanders.First.Balance(reTier).AsInteger;
      {$ENDIF}
    end;
    if FAdditive then
        Result := Max(1.0, Previous.AsSingle + Factor)
    else
        Result := Max(1.0, Previous.AsSingle * Factor);
  end
  else Result := Previous;
end;

function TModifierWelaRangeComponent.ScaleWithStage : TModifierWelaRangeComponent;
begin
  Result := self;
  FScaleWithStage := True;
end;

function TModifierWelaRangeComponent.ScaleWithTime : TModifierWelaRangeComponent;
begin
  Result := self;
  FTimer := TTimer.CreateAndStart(Eventbus.Read(eiCooldown, [], FValueGroup).AsInteger);
end;

{ TWelaReadyAfterGameTimeComponent }

function TWelaReadyAfterGameTimeComponent.IsReady : boolean;
begin
  Result := FTime <= GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
end;

function TWelaReadyAfterGameTimeComponent.Time(Seconds : integer) : TWelaReadyAfterGameTimeComponent;
begin
  Result := self;
  FTime := Seconds;
end;

{ TWelaReadyAfterGameEventComponent }

function TWelaReadyAfterGameEventComponent.GameEvent(const EventUID : string) : TWelaReadyAfterGameEventComponent;
begin
  Result := self;
  FEventUID := EventUID;
end;

function TWelaReadyAfterGameEventComponent.IsReady : boolean;
begin
  Result := FFired;
end;

function TWelaReadyAfterGameEventComponent.OnAfterCreate : boolean;
begin
  Result := True;
  // init firing state, if event is coming, waiting for firing
  FFired := GlobalEventbus.Read(eiGameEventTimeTo, [FEventUID]).AsInteger <= 0;
end;

function TWelaReadyAfterGameEventComponent.OnGameEvent(EventIdentifier : RParam) : boolean;
begin
  Result := True;
  if EventIdentifier.AsString = FEventUID then
      FFired := True;
end;

{ TWelaTargetConstraintBooleanComponent }

function TWelaTargetConstraintBooleanComponent.GroupA(Group : TArray<byte>) : TWelaTargetConstraintBooleanComponent;
begin
  Result := self;
  FGroupA := ByteArrayToComponentGroup(Group);
end;

function TWelaTargetConstraintBooleanComponent.GroupB(Group : TArray<byte>) : TWelaTargetConstraintBooleanComponent;
begin
  Result := self;
  FGroupB := ByteArrayToComponentGroup(Group);
end;

function TWelaTargetConstraintBooleanComponent.IsPossible(const Target : RTarget) : boolean;
var
  OperandA, OperandB : boolean;
begin
  OperandA := Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Target).ToRParam], FGroupA).AsType<RTargetValidity>.IsValid;
  OperandB := Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Target).ToRParam], FGroupB).AsType<RTargetValidity>.IsValid;
  if FNotA then
      OperandA := not OperandA;
  if FNotB then
      OperandB := not OperandB;
  case FOperator of
    boAnd : Result := OperandA and OperandB;
    boOr : Result := OperandA or OperandB;
  else
    raise ENotImplemented.Create('TWelaTargetConstraintBooleanComponent.IsPossible: Operator not implemented!');
  end;
end;

function TWelaTargetConstraintBooleanComponent.NotA : TWelaTargetConstraintBooleanComponent;
begin
  Result := self;
  FNotA := True;
end;

function TWelaTargetConstraintBooleanComponent.NotB : TWelaTargetConstraintBooleanComponent;
begin
  Result := self;
  FNotB := True;
end;

function TWelaTargetConstraintBooleanComponent.OperatorAnd : TWelaTargetConstraintBooleanComponent;
begin
  Result := self;
  FOperator := boAnd;
end;

function TWelaTargetConstraintBooleanComponent.OperatorOr : TWelaTargetConstraintBooleanComponent;
begin
  Result := self;
  FOperator := boOr;
end;

{ TWelaReadyCreatorComponent }

function TWelaReadyCreatorComponent.IsReady : boolean;
var
  CreatorID : integer;
  Creator : TEntity;
  CreatorGroup : SetComponentGroup;
begin
  Result := True;
  CreatorID := Eventbus.Read(eiCreator, [], ComponentGroup).AsInteger;
  if Game.EntityManager.TryGetEntityByID(CreatorID, Creator) then
  begin
    CreatorGroup := Eventbus.Read(eiCreatorGroup, [], ComponentGroup).AsSetType<SetComponentGroup>;
    // don't make a global fire as it would trigger all welas on that entity
    if CreatorGroup <> [] then
        Result := Creator.Eventbus.Read(eiIsReady, [], CreatorGroup).AsBooleanDefaultTrue;
  end;
end;

{ TWelaReadyEnemiesNearbyComponent }

function TWelaReadyEnemiesNearbyComponent.CheckGroup(CheckGroup : TArray<byte>) : TWelaReadyEnemiesNearbyComponent;
begin
  Result := self;
  FCheckGroup := ByteArrayToComponentGroup(CheckGroup);
end;

constructor TWelaReadyEnemiesNearbyComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FValueGroup := ComponentGroup;
end;

function TWelaReadyEnemiesNearbyComponent.IsReady : boolean;
var
  Range : single;
  Enemies : TList<TEntity>;
  i : integer;
begin
  Result := False;
  Range := Eventbus.Read(eiWelaRange, [], FValueGroup).AsSingle;

  Enemies := GlobalEventbus.Read(eiEntitiesInRange, [
    Owner.Position,
    Range,
    Owner.TeamID,
    RParam.From<EnumTargetTeamConstraint>(tcEnemies), RPARAM_EMPTY]).AsType<TList<TEntity>>;
  if assigned(Enemies) then
    for i := 0 to Enemies.Count - 1 do
        Result := Result or Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Enemies[i]).ToRParam], FCheckGroup).AsRTargetValidity.IsValid;
  Enemies.Free;
end;

function TWelaReadyEnemiesNearbyComponent.ValueGroup(ValueGroup : TArray<byte>) : TWelaReadyEnemiesNearbyComponent;
begin
  Result := self;
  FValueGroup := ByteArrayToComponentGroup(ValueGroup);
end;

{ TWelaReadyEventCompareComponent }

function TWelaReadyEventCompareComponent.CheckingGroup(Group : TArray<byte>) : TWelaReadyEventCompareComponent;
begin
  Result := self;
  FCheckingGroup := ByteArrayToComponentGroup(Group);
end;

function TWelaReadyEventCompareComponent.ComparedEvent(EventIdentifier : EnumEventIdentifier) : TWelaReadyEventCompareComponent;
begin
  Result := self;
  FComparedEvent := EventIdentifier;
end;

constructor TWelaReadyEventCompareComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FCheckingGroup := ComponentGroup;
end;

function TWelaReadyEventCompareComponent.IsReady : boolean;
var
  Amount : RParam;
begin
  Amount := Eventbus.Read(FComparedEvent, [], FCheckingGroup);
  Result := ResourceCompare(reFloat, Amount, FComparator, FReferenceValue)
end;

function TWelaReadyEventCompareComponent.ReferenceValue(ReferenceValue : single) : TWelaReadyEventCompareComponent;
begin
  Result := self;
  FReferenceValue := ReferenceValue;
end;

function TWelaReadyEventCompareComponent.SetComparator(Comparator : EnumComparator) : TWelaReadyEventCompareComponent;
begin
  Result := self;
  FComparator := Comparator;
end;

{ TWelaTargetConstraintCreatorIsAliveComponent }

function TWelaTargetConstraintCreatorIsAliveComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  Result := Game.EntityManager.HasEntityByID(TargetEntity.Eventbus.Read(eiCreator, []).AsInteger);
end;

{ TWelaTriggerCheckNotSelfComponent }

function TWelaTriggerCheckNotSelfComponent.IsValid(Amount : single; DamageType : SetDamageType; InflictorID : integer) : boolean;
begin
  Result := Owner.ID <> InflictorID;
end;

{ TWelaTargetConstraintCompareUnitPropertyComponent }

function TWelaTargetConstraintCompareUnitPropertyComponent.BothMustHave(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
begin
  Result := self;
  MustHave(Properties);
end;

function TWelaTargetConstraintCompareUnitPropertyComponent.BothMustHaveAny(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
begin
  Result := self;
  MustHaveAny(Properties);
end;

function TWelaTargetConstraintCompareUnitPropertyComponent.BothMustNotHave(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
begin
  Result := self;
  MustNotHave(Properties);
end;

function TWelaTargetConstraintCompareUnitPropertyComponent.BothMustNotHaveAll(Properties : TArray<byte>) : TWelaTargetConstraintCompareUnitPropertyComponent;
begin
  Result := self;
  MustNotHaveAll(Properties);
end;

function TWelaTargetConstraintCompareUnitPropertyComponent.IsPossible(const Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
  UnitProperties, OwnUnitProperties : SetUnitProperty;
begin
  TargetEntity := Target.GetTargetEntity;
  if not assigned(TargetEntity) then exit(False);
  UnitProperties := TargetEntity.UnitProperties;
  OwnUnitProperties := Owner.UnitProperties;
  Result :=
    ((FMustList <= UnitProperties) and (FMustList <= OwnUnitProperties)) and
    ((FMustAnyList = []) or (FMustAnyList * (OwnUnitProperties * UnitProperties) <> [])) and
    ((FMustNotList * UnitProperties = []) and (FMustNotList * OwnUnitProperties = [])) and
    ((FMustNotAllList = []) or (not(FMustNotAllList <= UnitProperties) and not(FMustNotAllList <= OwnUnitProperties)));
end;

{ TWelaReadyBooleanComponent }

function TWelaReadyBooleanComponent.IsReady : boolean;
var
  OperandA, OperandB : boolean;
begin
  OperandA := Eventbus.Read(eiIsReady, [], FGroupA).AsBooleanDefaultTrue;
  OperandB := Eventbus.Read(eiIsReady, [], FGroupB).AsBooleanDefaultTrue;
  if FNotA then
      OperandA := not OperandA;
  if FNotB then
      OperandB := not OperandB;
  case FOperator of
    boAnd : Result := OperandA and OperandB;
    boOr : Result := OperandA or OperandB;
  else
    raise ENotImplemented.Create('TWelaReadyBooleanComponent.IsPossible: Operator not implemented!');
  end;
end;

function TWelaReadyBooleanComponent.GroupA(Group : TArray<byte>) : TWelaReadyBooleanComponent;
begin
  Result := self;
  FGroupA := ByteArrayToComponentGroup(Group);
end;

function TWelaReadyBooleanComponent.GroupB(Group : TArray<byte>) : TWelaReadyBooleanComponent;
begin
  Result := self;
  FGroupB := ByteArrayToComponentGroup(Group);
end;

function TWelaReadyBooleanComponent.NotA : TWelaReadyBooleanComponent;
begin
  Result := self;
  FNotA := True;
end;

function TWelaReadyBooleanComponent.NotB : TWelaReadyBooleanComponent;
begin
  Result := self;
  FNotB := True;
end;

function TWelaReadyBooleanComponent.OperatorAnd : TWelaReadyBooleanComponent;
begin
  Result := self;
  FOperator := boAnd;
end;

function TWelaReadyBooleanComponent.OperatorOr : TWelaReadyBooleanComponent;
begin
  Result := self;
  FOperator := boOr;
end;

{ TModifierDamageTypeComponent }

function TModifierDamageTypeComponent.Add(const DamageTypes : TArray<byte>) : TModifierDamageTypeComponent;
begin
  Result := self;
  FAdded := ByteArrayToSetDamageType(DamageTypes);
end;

function TModifierDamageTypeComponent.OnDamageType(Previous : RParam) : RParam;
var
  DamageTypes : SetDamageType;
begin
  DamageTypes := Previous.AsSetType<SetDamageType>;
  DamageTypes := DamageTypes + FAdded - FRemoved;
  Result := RParam.From<SetDamageType>(DamageTypes);
end;

function TModifierDamageTypeComponent.Remove(const DamageTypes : TArray<byte>) : TModifierDamageTypeComponent;
begin
  Result := self;
  FRemoved := ByteArrayToSetDamageType(DamageTypes);
end;

initialization

ScriptManager.ExposeClass(TModifierComponent);
ScriptManager.ExposeClass(TModifierMultiplyCooldownComponent);
ScriptManager.ExposeClass(TModifierWelaDamageComponent);
ScriptManager.ExposeClass(TModifierResourceComponent);
ScriptManager.ExposeClass(TModifierMultiplyMovementSpeedComponent);
ScriptManager.ExposeClass(TModifierWelaCountComponent);
ScriptManager.ExposeClass(TModifierArmorTypeComponent);
ScriptManager.ExposeClass(TModifierCostComponent);
ScriptManager.ExposeClass(TModifierWelaTargetCountComponent);
ScriptManager.ExposeClass(TModifierWelaRangeComponent);
ScriptManager.ExposeClass(TModifierDamageTypeComponent);

ScriptManager.ExposeClass(TWelaReadyCostComponent);
ScriptManager.ExposeClass(TWelaReadyResourceCompareComponent);
ScriptManager.ExposeClass(TWelaReadyEnemiesNearbyComponent);
ScriptManager.ExposeClass(TWelaReadyCooldownComponent);
ScriptManager.ExposeClass(TWelaReadyAfterGameStartComponent);
ScriptManager.ExposeClass(TWelaReadyAfterGameEventComponent);
ScriptManager.ExposeClass(TWelaReadySpawnedComponent);
ScriptManager.ExposeClass(TWelaReadyUnitPropertyComponent);
ScriptManager.ExposeClass(TWelaReadyAfterGameTimeComponent);
ScriptManager.ExposeClass(TWelaReadyCreatorComponent);
ScriptManager.ExposeClass(TWelaReadyEventCompareComponent);
ScriptManager.ExposeClass(TWelaReadyBooleanComponent);

ScriptManager.ExposeClass(TWelaTargetConstraintComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintNeverComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintAlliesComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintEnemiesComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintTeamIDComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintResourceCompareComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintEventComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintUnitPropertyComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintZoneComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintOwningComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintBuildTeamComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintGridComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintNotSelfComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintBlacklistComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintWelaPropertyComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintBuffComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintMaxTargetDistanceComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintDynamicZoneComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintCardNameComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintResourceComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintBooleanComponent);
ScriptManager.ExposeClass(TWelaTargetConstraintCreatorIsAliveComponent);

ScriptManager.ExposeClass(TWelaTargetConstraintCompareUnitPropertyComponent);

ScriptManager.ExposeClass(TWelaTriggerCheckTakeDamageThresholdComponent);
ScriptManager.ExposeClass(TWelaTriggerCheckTakeDamageTypeComponent);
ScriptManager.ExposeClass(TWelaTriggerCheckNotSelfComponent);

ScriptManager.ExposeClass(TWelaHelperResolveComponent);

ScriptManager.ExposeClass(TWelaEventRedirecter);

ScriptManager.ExposeClass(TWarheadApplyScriptComponent);
ScriptManager.ExposeClass(TWarheadLinkApplyScriptComponent);

end.
