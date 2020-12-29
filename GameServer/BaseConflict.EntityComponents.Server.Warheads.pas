unit BaseConflict.EntityComponents.Server.Warheads;

interface

uses
  SysUtils,
  System.Rtti,
  Generics.Collections,
  Math,
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Script,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Entity,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.EntityComponents.Shared;

type

  {$RTTI INHERIT}
  /// <summary> The masterclass of all warheads. A warhead is the thing which effects the targets directly, e.g. deal damage to them.
  /// A example scenario is that a wela shoots a projectile carrying a warhead, which will be fired on the target at reaching it. </summary>
  TWarheadComponent = class abstract(TEntityComponent)
    protected
      FRedirectToSelf : boolean;
      procedure FireWarhead(Targets : ATarget); virtual; abstract;
    published
      [XEvent(eiFireWarhead, epLast, etTrigger)]
      /// <summary> Fires the warhead on an entity. </summary>
      function OnFireWarhead(Targets : RParam) : boolean;
    public
      function RedirectToSelf : TWarheadComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead throws a specified global event, when fired. </summary>
  TWarheadDebugThrowEventComponent = class(TWarheadComponent)
    protected
      FThrownEvent : EnumEventIdentifier;
      procedure FireWarhead(Targets : ATarget); override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; ThrownEvent : EnumEventIdentifier); reintroduce;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Spotty warheads
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> The masterclass of all warheads, which targets a single entity. </summary>
  TWarheadSpottyComponent = class abstract(TWarheadComponent)
    protected
      procedure FireWarhead(Targets : ATarget); override;
      procedure ApplyEffect(Entity : TEntity); virtual; abstract;
  end;

  /// <summary> Teleports the target to another position. </summary>
  TWarheadSpottyTeleportComponent = class(TWarheadComponent)
    protected
      FAsProjectile, FToNexus, FOffsetByCollisionRadius : boolean;
      FTeleportedEntityID : integer;
      FOffset : single;
      FFixedTarget : RTarget;
      procedure FireWarhead(Targets : ATarget); override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> The teleported entity will be moved "range" towards their between vector. </summary>
      function Offset(Range : single) : TWarheadSpottyTeleportComponent;
      function OffsetByCollisionRadius : TWarheadSpottyTeleportComponent;
      function ImprintTeleportedID(ID : integer) : TWarheadSpottyTeleportComponent;
      /// <summary> Makes the teleport not instant, but by a projectile in eiWelaUnitpattern. </summary>
      function AsProjectile : TWarheadSpottyTeleportComponent;
      /// <summary> Target is teleported to the next friendly nexus. </summary>
      function ToNexus : TWarheadSpottyTeleportComponent;
      /// <summary> Target is teleported to specified target. </summary>
      function ToTarget(const Target : RTarget) : TWarheadSpottyTeleportComponent;
      function ToCoordinate(const CoordinateX, CoordinateY : single) : TWarheadSpottyTeleportComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead kills the effected entity instantly not regarding any shields or abilities. </summary>
  TWarheadSpottyKillComponent = class(TWarheadSpottyComponent)
    protected
      FSacrifice, FExile, FRemove : boolean;
      procedure ApplyEffect(Entity : TEntity); override;
    public
      function Sacrifice : TWarheadSpottyKillComponent;
      function Exile : TWarheadSpottyKillComponent;
      function Remove : TWarheadSpottyKillComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead removes buffs from an unit matching certain types. </summary>
  TWarheadSpottyRemoveBuffComponent = class(TWarheadSpottyComponent)
    protected
      FMustHaveAny, FMustNotHave : SetBuffType;
      procedure ApplyEffect(Entity : TEntity); override;
    public
      function All : TWarheadSpottyRemoveBuffComponent;
      function MustHaveAny(TargetBuffs : TArray<byte>) : TWarheadSpottyRemoveBuffComponent;
      function MustNotHave(TargetBuffs : TArray<byte>) : TWarheadSpottyRemoveBuffComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> The masterclass of all health manipulating spotty warheads. Can't use a generic resource warhead for
  /// health, because damage and heal events are more specific. </summary>
  TWarheadSpottyHealthComponent = class abstract(TWarheadSpottyComponent)
    protected
      FHeal, FPercentage, FPercentageOfCurrent : boolean;
      procedure ApplyEffect(Entity : TEntity); override;
    public
      function PercentageOfCurrentHealth : TWarheadSpottyHealthComponent;
      function PercentageOfMaxHealth : TWarheadSpottyHealthComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead deals a fix amount of damage (eiWelaDamage) to the target. </summary>
  TWarheadSpottyDamageComponent = class(TWarheadSpottyHealthComponent)
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead heals a fix amount (eiWelaDamage) to the target. </summary>
  TWarheadSpottyHealComponent = class(TWarheadSpottyHealthComponent)
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead creates and adds the specified component to the target. </summary>
  TWarheadSpottyBuffComponent = class(TWarheadSpottyComponent)
    protected
      type
      CompClass = class of TEntityComponent;
    var
      FClassType : CompClass;
      procedure ApplyEffect(Entity : TEntity); override;
    public
      /// <summary> The ClassType has to be a fully classified ClassName, e.g. 'BaseConflict.EntityComponents.Server.TInvisibleComponent' </summary>
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; ClassType : string); reintroduce;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead adds or sets resources (health, gold, etc.) to/of the target. </summary>
  TWarheadSpottyResourceComponent = class(TWarheadSpottyComponent)
    protected
      FFactor : single;
      FSource : EnumEventIdentifier;
      FResType : EnumResource;
      FResetResource, FSetResource, FTargetsOwningCommander, FTargetsCost, FTargetsMax, FDontFillCap, FAmountIsPercentage : boolean;
      FTargetGroup : SetComponentGroup;
      FLookForGroup : SetUnitProperty;
      procedure ApplyEffect(Entity : TEntity); override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> All Resourcetypes are constants defined in BaseConflict.Constants.pas. Defaults to RES_GOLD. </summary>
      function SetResourceType(ResType : integer) : TWarheadSpottyResourceComponent;
      /// <summary> Instead of adding the resource, it will be set to the value. </summary>
      function SetsResourceToValue() : TWarheadSpottyResourceComponent;
      /// <summary> Specify the event (eiWeladamage or eiResourceCost) to retrieve the amount. Defaults to eiWeladamage.
      /// If set to eiNone 1 is taken. </summary>
      function SetResourceSource(Eventname : EnumEventIdentifier) : TWarheadSpottyResourceComponent;
      function ResetResource : TWarheadSpottyResourceComponent;
      /// <summary> The amount describes a percentage. </summary>
      function AmountIsPercentage() : TWarheadSpottyResourceComponent;
      /// <summary> Sets a factor to be multiplied with the amount. </summary>
      function SetFactor(Factor : single) : TWarheadSpottyResourceComponent;
      /// <summary> Set the group where the resources are applied to. Default is []. </summary>
      function TargetGroup(Group : TArray<byte>) : TWarheadSpottyResourceComponent;
      /// <summary> Set target group to look for beacon. </summary>
      function SearchForWelaBeacon(const Properties : TArray<byte>) : TWarheadSpottyResourceComponent;
      /// <summary> Remaps the target of the resource adjustment to the owning commander of the actual target. </summary>
      function TargetsOwningCommander : TWarheadSpottyResourceComponent;
      /// <summary> Instead of eiResourceBalance the eiResourceCost will be changed. </summary>
      function ChangesCost() : TWarheadSpottyResourceComponent;
      /// <summary> Instead of eiResourceBalance the eiResourceCap will be changed. </summary>
      function ChangesMax() : TWarheadSpottyResourceComponent;
      /// <summary> If this component changes the maximum, it dont fill the balance according to the cap change. </summary>
      function DontFillCap : TWarheadSpottyResourceComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Whenever this warhead is fired it uses the eiWeladamage of its group
  /// to increase the eiWeladamage in target group.
  /// E.g. for increasing money-amount like the commander has. </summary>
  TWarheadSpottyPermaBuffComponent = class(TWarheadSpottyComponent)
    protected
      FTargetGroup : byte;
      procedure ApplyEffect(Entity : TEntity); override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; TargetGroup : byte); reintroduce;
  end;

  /// <summary> Resets the targets of a wela. </summary>
  TWarheadSpottyWelaStopComponent = class(TWarheadSpottyComponent)
    protected
      procedure ApplyEffect(Entity : TEntity); override;
  end;

  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Splash warheads
  /// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  {$RTTI INHERIT}

  /// <summary> The masterclass of all warheads, which targets multiple entities within a circle (eiWelaAreaOfEffect) around the target. </summary>
  TWarheadSplashComponent = class abstract(TWarheadComponent)
    protected
      FLineWidth : single;
      FTargetsGroundAndAir, FIgnoreMainTargets : boolean;
      FValidateGroup, FValueGroup : SetComponentGroup;
      // targeting and then calls ApplyEffect on filtered targets
      procedure FireWarhead(Targets : ATarget); override;
      procedure ApplyEffect(const Targets : TList<TEntity>); virtual; abstract;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      /// <summary> This warhead deals damage along the line from owner to target. Linelength = eiWelaAreaOfEffectCone. </summary>
      function LineFromOwner(LineWidth : single) : TWarheadSplashComponent;
      function IgnoreMainTargets : TWarheadSplashComponent;
      function TargetsGroundAndAir : TWarheadSplashComponent;
      function SetValidateGroup(Group : TArray<byte>) : TWarheadSplashComponent;
      function SetValueGroup(Group : TArray<byte>) : TWarheadSplashComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead collects resources from targets and give it to the owner. </summary>
  TWarheadSplashResourceCollectComponent = class(TWarheadSplashComponent)
    protected
      FSetToValue : boolean;
      FCollectedResource, FConvertedResource : EnumResource;
      FTargetGroup : SetComponentGroup;
      procedure ApplyEffect(const Targets : TList<TEntity>); override;
    public
      function CollectsResource(Resource : EnumResource) : TWarheadSplashResourceCollectComponent;
      /// <summary> Set the group where the resources are applied to. Default is []. </summary>
      function TargetGroup(Group : TArray<byte>) : TWarheadSplashResourceCollectComponent;
      function ConvertedTo(Resource : EnumResource) : TWarheadSplashResourceCollectComponent;
      function SetToValue() : TWarheadSplashResourceCollectComponent;
  end;

  /// <summary> The masterclass of all health manipulating splash warheads. Can't use a generic resource warhead for
  /// health, because damage and heal events are more specific. </summary>
  TWarheadSplashHealthComponent = class abstract(TWarheadSplashComponent)
    protected
      FHeal, FPercentage : boolean;
      procedure ApplyEffect(const Targets : TList<TEntity>); override;
    public
      function AmountIsPercentage : TWarheadSplashHealthComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead deals a capped splash damage (eiWelaDamage * eiWelaSplashfactor) to all targets in range (eiWelaAreaOfEffect). </summary>
  TWarheadSplashDamageComponent = class(TWarheadSplashHealthComponent)
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead heals a capped amoumt of health (eiWelaDamage * eiWelaSplashfactor) to all targets in range (eiWelaAreaOfEffect). </summary>
  TWarheadSplashHealComponent = class(TWarheadSplashHealthComponent)
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  /// <summary> This warhead kills the effected entity instantly not regarding any shields or abilities. </summary>
  TWarheadSplashKillComponent = class(TWarheadSplashComponent)
    protected
      FSacrifice, FExile : boolean;
      procedure ApplyEffect(const Targets : TList<TEntity>); override;
    public
      function Sacrifice : TWarheadSplashKillComponent;
      function Exile : TWarheadSplashKillComponent;
  end;

implementation

uses
  BaseConflict.Globals,
  BaseConflict.Globals.Server;

{ TWarheadSplashHealComponent }

constructor TWarheadSplashHealComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FHeal := True;
end;

{ TWarheadSpottyHealComponent }

constructor TWarheadSpottyHealComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FHeal := True;
end;

{ TWarheadSpottyComponent }

procedure TWarheadSpottyComponent.FireWarhead(Targets : ATarget);
var
  i : integer;
  Entity : TEntity;
begin
  for i := 0 to length(Targets) - 1 do
    if Targets[i].TryGetTargetEntity(Entity) then
        ApplyEffect(Entity);
end;

{ TWarheadSpottyKillComponent }

procedure TWarheadSpottyKillComponent.ApplyEffect(Entity : TEntity);
begin
  if FRemove then
  begin
    GlobalEventbus.Trigger(eiDelayedKillEntity, [Entity.ID]);
  end
  else
  begin
    if FExile then
        Entity.Eventbus.Write(eiExiled, [True]);
    if FSacrifice then
        Entity.Eventbus.Trigger(eiSacrifice, [FOwner.ID, FOwner.Eventbus.Read(eiOwnerCommander, [])]);
    Entity.Eventbus.Trigger(eiKill, [FOwner.ID, FOwner.Eventbus.Read(eiOwnerCommander, [])]);
    if not Entity.Eventbus.Read(eiIsAlive, []).AsBoolean then
        Eventbus.Trigger(eiKillDone, [Entity.ID], ComponentGroup);
  end;
end;

function TWarheadSpottyKillComponent.Exile : TWarheadSpottyKillComponent;
begin
  Result := self;
  FExile := True;
end;

function TWarheadSpottyKillComponent.Remove : TWarheadSpottyKillComponent;
begin
  Result := self;
  FRemove := True;
end;

function TWarheadSpottyKillComponent.Sacrifice : TWarheadSpottyKillComponent;
begin
  Result := self;
  FSacrifice := True;
end;

{ TSpottyWarheadBuffComponent }

procedure TWarheadSpottyBuffComponent.ApplyEffect(Entity : TEntity);
begin
  FClassType.CreateGrouped(Entity, TArray<byte>.Create(ALLGROUP_INDEX));
end;

constructor TWarheadSpottyBuffComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; ClassType : string);
var
  typus : TRttiType;
begin
  inherited CreateGrouped(Owner, Group);
  typus := TRTTIContext.Create.FindType(ClassType);
  if not assigned(typus) then raise Exception.Create('TWarheadSpottyBuffComponent.CreateGrouped: Classtype ' + self.UnitScope + '.' + ClassType + ' not found!');
  FClassType := CompClass(typus.AsInstance.MetaclassType);
end;

{ TWarheadSpottyResourceComponent }

function TWarheadSpottyResourceComponent.AmountIsPercentage : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FAmountIsPercentage := True;
end;

procedure TWarheadSpottyResourceComponent.ApplyEffect(Entity : TEntity);
var
  iCurrent : integer;
  sCurrent : single;
  Res : RParam;
  Amount : RParam;
  Cost : AResourceCost;
  TargetGroup : SetComponentGroup;
begin
  // remap target to owning commander
  if FTargetsOwningCommander then
  begin
    Entity := Game.EntityManager.GetOwningCommander(Entity);
    if not assigned(Entity) then exit;
  end;

  Res := 0.0;
  // take amount from chosen source
  case FSource of
    eiNone : if (FResType in RES_INT_RESOURCES) and not FAmountIsPercentage then Res := 1
      else Res := 1.0;
    eiWeladamage :
      begin
        if (FResType in RES_INT_RESOURCES) and not FAmountIsPercentage then Res := RParam.FromInteger(round(Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle))
        else Res := Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle;
      end;
    eiResourceCost :
      begin
        Cost := Eventbus.Read(eiResourceCost, []).AsAResourceCost;
        if not(assigned(Cost) and Cost.TryGetValue(FResType, Res)) then
            assert(False, 'TWarheadSpottyResourceComponent.ApplyEffect: eiResourceCost does not exist or contain the target resource type!');
      end;
  else
    assert(False, 'TWarheadSpottyResourceComponent.ApplyEffect: ' + HRTTI.EnumerationToString<EnumEventIdentifier>(FSource) + ' not supported atm!');
  end;

  // set target group
  TargetGroup := FTargetGroup;
  if FLookForGroup <> [] then
      TargetGroup := TargetGroup + Entity.Eventbus.Read(eiWelaSearch, [RParam.From<SetUnitProperty>(FLookForGroup)]).AsType<SetComponentGroup>;

  // apply factor for increase/decrease amount
  if (FResType in RES_INT_RESOURCES) and not FAmountIsPercentage then Amount := integer(round(Res.AsInteger * FFactor))
  else Amount := Res.AsSingle * FFactor;
  if FAmountIsPercentage then
  begin
    Amount := ResourceAsSingle(FResType, Entity.Eventbus.Read(eiResourceCap, [ord(FResType)], TargetGroup)) * Amount.AsSingle;
    if FResType in RES_INT_RESOURCES then Amount := integer(round(Amount.AsSingle));
  end;
  // not set or add resource
  if FTargetsMax then
  begin
    if FSetResource then
        Entity.Eventbus.Write(eiResourceCap, [ord(FResType), Amount], TargetGroup)
    else Entity.Eventbus.Trigger(eiResourceCapTransaction, [ord(FResType), Amount, FDontFillCap], TargetGroup);
  end
  else if FTargetsCost then
  begin
    if FResType in RES_INT_RESOURCES then
    begin
      iCurrent := Entity.Blackboard.GetIndexedValue(eiResourceCost, TargetGroup, ord(FResType)).AsInteger;
      Amount := iCurrent + Amount.AsInteger;
    end
    else
    begin
      sCurrent := Entity.Blackboard.GetIndexedValue(eiResourceCost, TargetGroup, ord(FResType)).AsSingle;
      Amount := sCurrent + Amount.AsSingle;
    end;
    Entity.Eventbus.Write(eiResourceCost, [ord(FResType), Amount], TargetGroup);
  end
  else
  begin
    if FSetResource then
    begin
      if FResType in RES_INT_RESOURCES then
          Entity.Eventbus.Write(eiResourceBalance, [ord(FResType), 0], TargetGroup)
      else
          Entity.Eventbus.Write(eiResourceBalance, [ord(FResType), 0.0], TargetGroup);
      Entity.Eventbus.Trigger(eiResourceTransaction, [ord(FResType), Amount], TargetGroup);
    end
    else if FResetResource then
        Entity.Eventbus.Trigger(eiResourceReset, [ord(FResType)], TargetGroup)
    else
        Entity.Eventbus.Trigger(eiResourceTransaction, [ord(FResType), Amount], TargetGroup);
  end;
end;

function TWarheadSpottyResourceComponent.ChangesCost : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FTargetsCost := True;
end;

function TWarheadSpottyResourceComponent.ChangesMax : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FTargetsMax := True;
end;

constructor TWarheadSpottyResourceComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FFactor := 1.0;
  FSource := eiWeladamage;
  FResType := reGold;
  FTargetGroup := [];
end;

function TWarheadSpottyResourceComponent.DontFillCap : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FDontFillCap := True;
end;

function TWarheadSpottyResourceComponent.ResetResource : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FResetResource := True;
end;

function TWarheadSpottyResourceComponent.SearchForWelaBeacon(const Properties : TArray<byte>) : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FLookForGroup := ByteArrayToSetUnitProperies(Properties);
end;

function TWarheadSpottyResourceComponent.SetFactor(Factor : single) : TWarheadSpottyResourceComponent;
begin
  FFactor := Factor;
  Result := self;
end;

function TWarheadSpottyResourceComponent.SetResourceSource(Eventname : EnumEventIdentifier) : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FSource := Eventname;
end;

function TWarheadSpottyResourceComponent.SetResourceType(ResType : integer) : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FResType := EnumResource(ResType);
end;

function TWarheadSpottyResourceComponent.SetsResourceToValue : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FSetResource := True;
end;

function TWarheadSpottyResourceComponent.TargetGroup(Group : TArray<byte>) : TWarheadSpottyResourceComponent;
begin
  FTargetGroup := ByteArrayToComponentGroup(Group);
  Result := self;
end;

function TWarheadSpottyResourceComponent.TargetsOwningCommander : TWarheadSpottyResourceComponent;
begin
  Result := self;
  FTargetsOwningCommander := True;
end;

{ TWarheadSpottyHealthComponent }

procedure TWarheadSpottyHealthComponent.ApplyEffect(Entity : TEntity);
var
  DamageDone, ModifiedDamageToDo : RParam;
  DamageToDo : single;
  DamageType : SetDamageType;
begin
  DamageType := Eventbus.Read(eiDamageType, [], ComponentGroup).AsType<SetDamageType>;
  // amount of damage
  DamageToDo := Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle * Eventbus.Read(eiWelaModifier, [], ComponentGroup).AsSingleDefault(1);
  // if amount is percentage adjust to it
  if FPercentage then
  begin
    if FPercentageOfCurrent then DamageToDo := DamageToDo * Entity.Balance(reHealth).AsSingle
    else DamageToDo := DamageToDo * Entity.Cap(reHealth).AsSingle;
  end;
  if FHeal then
  begin
    DamageDone := Entity.Eventbus.Read(eiHeal, [
      DamageToDo,
      RParam.From<SetDamageType>(DamageType),
      FOwner.ID]);
    if (DamageDone.AsSingle > 0) then
        Eventbus.Trigger(eiHealDone, [DamageDone, RParam.From<SetDamageType>(DamageType), Entity]);
  end
  else
  begin
    ModifiedDamageToDo := Eventbus.Read(eiWillDealDamage, [DamageToDo, RParam.From<SetDamageType>(DamageType), Entity]);
    if not ModifiedDamageToDo.IsEmpty then
        DamageToDo := ModifiedDamageToDo.AsSingle;
    DamageDone := Entity.Eventbus.Read(eiTakeDamage, [
      DamageToDo,
      RParam.From<SetDamageType>(DamageType),
      FOwner.ID]);
    if (DamageDone.AsSingle > 0) then
        Eventbus.Trigger(eiDamageDone, [DamageDone, RParam.From<SetDamageType>(DamageType), Entity]);
    if not Entity.Eventbus.Read(eiIsAlive, []).AsBoolean then
        Eventbus.Trigger(eiKillDone, [Entity.ID], ComponentGroup);
  end;
end;

function TWarheadSpottyHealthComponent.PercentageOfCurrentHealth : TWarheadSpottyHealthComponent;
begin
  Result := self;
  FPercentage := True;
  FPercentageOfCurrent := True;
end;

function TWarheadSpottyHealthComponent.PercentageOfMaxHealth : TWarheadSpottyHealthComponent;
begin
  Result := self;
  FPercentage := True;
  FPercentageOfCurrent := False;
end;

{ TWarheadSpottyPermaBuffComponent }

procedure TWarheadSpottyPermaBuffComponent.ApplyEffect(Entity : TEntity);
var
  currentValue, buffedValue : single;
begin
  currentValue := Entity.Blackboard.GetValue(eiWeladamage, [FTargetGroup]).AsSingle;
  buffedValue := Entity.Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle;
  Entity.Blackboard.SetValue(eiWeladamage, [FTargetGroup], currentValue + buffedValue);
end;

constructor TWarheadSpottyPermaBuffComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; TargetGroup : byte);
begin
  inherited CreateGrouped(Owner, Group);
  FTargetGroup := TargetGroup;
end;

{ TWarheadDebugThrowEventComponent }

constructor TWarheadDebugThrowEventComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; ThrownEvent : EnumEventIdentifier);
begin
  inherited CreateGrouped(Owner, Group);
  FThrownEvent := ThrownEvent;
end;

procedure TWarheadDebugThrowEventComponent.FireWarhead(Targets : ATarget);
begin
  GlobalEventbus.Trigger(FThrownEvent, []);
end;

{ TWarheadComponent }

function TWarheadComponent.OnFireWarhead(Targets : RParam) : boolean;
begin
  Result := True;
  if FRedirectToSelf then
      FireWarhead(ATarget.Create(Owner))
  else
      FireWarhead(Targets.AsATarget);
end;

function TWarheadComponent.RedirectToSelf : TWarheadComponent;
begin
  Result := self;
  FRedirectToSelf := True;
end;

{ TWarheadSplashComponent }

constructor TWarheadSplashComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FValidateGroup := ComponentGroup;
  FValueGroup := ComponentGroup;
end;

procedure TWarheadSplashComponent.FireWarhead(Targets : ATarget);
var
  Target : RTarget;
  Position, Front : RVector2;
  Range, Cone : single;
  FilteredTargets : TList<TEntity>;
  Filter : ProcEntityFilterFunction;
  TargetEntity : TEntity;
  TargetsFlying : boolean;
  i : integer;
  Line : RLine2D;
begin
  for i := 0 to length(Targets) - 1 do
  begin
    Target := Targets[i];
    if Target.IsEmpty then exit;

    Cone := Eventbus.Read(eiWelaAreaOfEffectCone, [], FValueGroup).AsSingle;
    Position := Target.GetTargetPosition;
    Front := (Position - Owner.Position).Normalize;
    if Cone > 0 then Position := Owner.Position;
    Range := Eventbus.Read(eiWelaAreaOfEffect, [], FValueGroup).AsSingle;
    if not FTargetsGroundAndAir and Target.IsEntity and Target.TryGetTargetEntity(TargetEntity) then
        TargetsFlying := not(upGround in TargetEntity.Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty>)
    else
        TargetsFlying := False;

    // doing line damage
    if FLineWidth > 0 then
    begin
      Line := RLine2D.Create(Owner.Position, Front * Range);
      Position := Line.Center;
      Range := Line.length / 2;
    end;

    Filter :=
        function(Entity : TEntity) : boolean
      var
        entityFront, entityPosition : RVector2;
        entityRadius, entityWidthAngle : single;
      begin
        Result := True;
        if FIgnoreMainTargets and Target.IsEntity and (Entity.ID = Target.EntityID) then exit(False);
        if not FTargetsGroundAndAir and (TargetsFlying = (upGround in Entity.UnitProperties)) then exit(False);
        // doing line damage
        if FLineWidth > 0 then
        begin
          entityRadius := Entity.CollisionRadius;
          entityPosition := Entity.Position;
          Result := Line.DistanceToPoint(entityPosition) - entityRadius <= FLineWidth / 2;
        end
        else
          // doing splash damage in a cone
          if Cone > 0 then
          begin
            entityRadius := Entity.CollisionRadius;
            entityPosition := Entity.Position;
            entityFront := (entityPosition - Position).Normalize;
            entityWidthAngle := arctan(entityRadius / Max(0.01, entityPosition.Distance(Position)));
            Result := Front.InnerAngle(entityFront) - entityWidthAngle <= Cone / 2;
          end;
        Result := Result and Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Entity).ToRParam], FValidateGroup).AsRTargetValidity.IsValid;
      end;

    FilteredTargets := GlobalEventbus.Read(eiEntitiesInRange, [
      Position,
      Range,
      Owner.TeamID,
      RParam.From<EnumTargetTeamConstraint>(tcAll),
      RParam.FromProc<ProcEntityFilterFunction>(Filter)
      ]).AsType<TList<TEntity>>;

    if (FilteredTargets <> nil) and (FilteredTargets.Count > 0) then ApplyEffect(FilteredTargets);
    FilteredTargets.Free;
  end;
end;

function TWarheadSplashComponent.IgnoreMainTargets : TWarheadSplashComponent;
begin
  Result := self;
  FIgnoreMainTargets := True;
end;

function TWarheadSplashComponent.LineFromOwner(LineWidth : single) : TWarheadSplashComponent;
begin
  Result := self;
  FLineWidth := LineWidth;
end;

function TWarheadSplashComponent.SetValidateGroup(Group : TArray<byte>) : TWarheadSplashComponent;
begin
  Result := self;
  FValidateGroup := ByteArrayToComponentGroup(Group);
end;

function TWarheadSplashComponent.SetValueGroup(Group : TArray<byte>) : TWarheadSplashComponent;
begin
  Result := self;
  FValueGroup := ByteArrayToComponentGroup(Group);
end;

function TWarheadSplashComponent.TargetsGroundAndAir : TWarheadSplashComponent;
begin
  Result := self;
  FTargetsGroundAndAir := True;
end;

{ TWarheadSplashHealthComponent }

function TWarheadSplashHealthComponent.AmountIsPercentage : TWarheadSplashHealthComponent;
begin
  Result := self;
  FPercentage := True;
end;

procedure TWarheadSplashHealthComponent.ApplyEffect(const Targets : TList<TEntity>);
type
  RUnitHealth = record
    Health, MaxHealth, DoneDamage : single;
    Target : TEntity;
  end;

  function DoMetric(item : RUnitHealth) : single;
  begin
    if FHeal then Result := item.MaxHealth - item.Health
    else Result := item.Health;
  end;

var
  Damage, Damagefactor, DamageDone, DamageSum, DamageToDeal, DamageToDoPerUnit, DamageToDo, MaxDamgePerUnit : single;
  DamageTypes : SetDamageType;
  ModifiedDamageToDo : RParam;
  i, leastItem : integer;
  TargetsToProcess, FinishedTargets : TAdvancedList<RUnitHealth>;
  tUnitHealth : RUnitHealth;
begin
  if Targets.Count <= 0 then exit;

  DamageTypes := Eventbus.Read(eiDamageType, [], ComponentGroup).AsType<SetDamageType>;
  // the maximal damage of this warhead to a single unit
  Damage := Eventbus.Read(eiWeladamage, [], ComponentGroup).AsSingle;
  MaxDamgePerUnit := Damage;
  // the maximal damage of this warhead summed over all targets is determined by Damage * Damagefactor
  // if no splashfactor is determined, all units get same damage
  Damagefactor := Eventbus.Read(eiWelaSplashfactor, [], ComponentGroup).AsSingleDefault(10000);
  DamageToDeal := Damage * Damagefactor;
  // evenly distribute Damagesum over enemies

  // build up healtharray of all our targets
  TargetsToProcess := TAdvancedList<RUnitHealth>.Create;
  FinishedTargets := TAdvancedList<RUnitHealth>.Create;
  for i := 0 to Targets.Count - 1 do
  begin
    tUnitHealth.Health := Targets[i].Eventbus.Read(eiResourceBalance, [ord(reHealth)]).AsSingle;
    tUnitHealth.MaxHealth := Targets[i].Eventbus.Read(eiResourceCap, [ord(reHealth)]).AsSingle;
    tUnitHealth.DoneDamage := 0;
    tUnitHealth.Target := Targets[i];
    if not FHeal or (tUnitHealth.Health < tUnitHealth.MaxHealth) or (dtOverheal in DamageTypes) then
        TargetsToProcess.Add(tUnitHealth);
  end;

  if FPercentage then
  begin
    // for percentages there is no cap of distributed dmg/heal atm, so directly apply percentage
    FinishedTargets.AddRange(TargetsToProcess);
    for i := 0 to FinishedTargets.Count - 1 do
    begin
      tUnitHealth := FinishedTargets[i];
      tUnitHealth.DoneDamage := Damage * tUnitHealth.MaxHealth;
      FinishedTargets[i] := tUnitHealth;
    end;
  end
  else
  begin
    // distribute damage or health until all are satisfied or amount is depleted
    // first precompute all amounts for each target
    while (TargetsToProcess.Count > 0) do
    begin
      // find the unit which would gain the least healing or damage
      leastItem := -1;
      DamageToDoPerUnit := MaxInt;
      for i := 0 to TargetsToProcess.Count - 1 do
      begin
        if DoMetric(TargetsToProcess[i]) < DamageToDoPerUnit then
        begin
          DamageToDoPerUnit := DoMetric(TargetsToProcess[i]);
          leastItem := i;
        end;
      end;
      // limit maximum damage per unit to the original damage
      DamageToDoPerUnit := min(DamageToDoPerUnit, Damage);
      assert(leastItem >= 0);
      // if we could evenly spread our current damage/heal over all units, do it and finish
      // else spread the least value and skip the least item which limits us
      for i := 0 to TargetsToProcess.Count - 1 do
      begin
        tUnitHealth := TargetsToProcess[i];
        tUnitHealth.DoneDamage := tUnitHealth.DoneDamage + min(DamageToDeal / TargetsToProcess.Count, DamageToDoPerUnit);
        TargetsToProcess[i] := tUnitHealth;
      end;
      if DamageToDoPerUnit >= DamageToDeal / TargetsToProcess.Count then
      begin
        DamageToDeal := 0;
        break;
      end
      else
      begin
        DamageToDeal := DamageToDeal - (DamageToDoPerUnit * TargetsToProcess.Count);
        // reduce original damage, so each unit damage is capped to it
        Damage := Damage - DamageToDoPerUnit;
        // if max damage per unit is reached break
        if Damage <= 0 then break;
        FinishedTargets.Add(TargetsToProcess[leastItem]);
        TargetsToProcess.Delete(leastItem);
      end;
    end;
    FinishedTargets.AddRange(TargetsToProcess);
    // distribute all remaining damage due armor reduction would prevent death issues
    if DamageToDeal > 0 then
      for i := 0 to FinishedTargets.Count - 1 do
      begin
        tUnitHealth := FinishedTargets[i];
        tUnitHealth.DoneDamage := min(tUnitHealth.DoneDamage + DamageToDeal / FinishedTargets.Count, MaxDamgePerUnit);
        FinishedTargets[i] := tUnitHealth;
      end;
  end;

  // now apply all computed damages / heals
  DamageSum := 0;
  for i := 0 to FinishedTargets.Count - 1 do
  begin
    if FHeal then
    begin
      DamageDone := FinishedTargets[i].Target.Eventbus.Read(eiHeal, [
        FinishedTargets[i].DoneDamage,
        RParam.From<SetDamageType>(DamageTypes + [dtSplash]),
        FOwner.ID]).AsSingle;
      if (DamageDone > 0) then
          Eventbus.Trigger(eiHealDone, [DamageDone, RParam.From<SetDamageType>(DamageTypes + [dtSplash]), FinishedTargets[i].Target]);
    end
    else
    begin
      DamageToDo := FinishedTargets[i].DoneDamage;
      ModifiedDamageToDo := Eventbus.Read(eiWillDealDamage, [DamageToDo, RParam.From<SetDamageType>(DamageTypes + [dtSplash]), FinishedTargets[i].Target]);
      if not ModifiedDamageToDo.IsEmpty then DamageToDo := ModifiedDamageToDo.AsSingle;
      DamageDone := FinishedTargets[i].Target.Eventbus.Read(eiTakeDamage, [
        DamageToDo,
        RParam.From<SetDamageType>(DamageTypes + [dtSplash]),
        FOwner.ID]).AsSingle;
      if (DamageDone > 0) then
          Eventbus.Trigger(eiDamageDone, [DamageDone, RParam.From<SetDamageType>(DamageTypes + [dtSplash]), FinishedTargets[i].Target]);
      if not FinishedTargets[i].Target.Eventbus.Read(eiIsAlive, []).AsBoolean then
          Eventbus.Trigger(eiKillDone, [FinishedTargets[i].Target.ID], ComponentGroup);
    end;
    DamageSum := DamageSum + DamageDone;
  end;

  TargetsToProcess.Free;
  FinishedTargets.Free;
end;

{ TWarheadSpottyTeleportComponent }

constructor TWarheadSpottyTeleportComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FTeleportedEntityID := -1;
end;

function TWarheadSpottyTeleportComponent.Offset(Range : single) : TWarheadSpottyTeleportComponent;
begin
  Result := self;
  FOffset := Range;
end;

function TWarheadSpottyTeleportComponent.OffsetByCollisionRadius : TWarheadSpottyTeleportComponent;
begin
  Result := self;
  FOffsetByCollisionRadius := True;
end;

function TWarheadSpottyTeleportComponent.AsProjectile : TWarheadSpottyTeleportComponent;
begin
  Result := self;
  FAsProjectile := True;
end;

function TWarheadSpottyTeleportComponent.ToCoordinate(const CoordinateX, CoordinateY : single) : TWarheadSpottyTeleportComponent;
begin
  Result := self;
  ToTarget(RTarget.Create(RVector2.Create(CoordinateX, CoordinateY)));
end;

function TWarheadSpottyTeleportComponent.ToNexus : TWarheadSpottyTeleportComponent;
begin
  Result := self;
  FToNexus := True;
end;

function TWarheadSpottyTeleportComponent.ToTarget(const Target : RTarget) : TWarheadSpottyTeleportComponent;
begin
  Result := self;
  FFixedTarget := Target;
end;

procedure TWarheadSpottyTeleportComponent.FireWarhead(Targets : ATarget);
var
  i : integer;
  Target : RTarget;
  TeleportTarget : RTarget;
  TeleportedEntity, TargetEntity : TEntity;
  Offset, TeleportTo : RVector2;
  OffsetRange : single;
  SkinID : string;
begin
  for i := 0 to Targets.Count - 1 do
  begin
    Target := Targets[i];
    if Game.EntityManager.TryGetEntityByID(FTeleportedEntityID, TeleportedEntity) or Target.TryGetTargetEntity(TeleportedEntity) then
    begin
      // teleport target to owning teams nexus
      if FToNexus then
      begin
        if not Game.EntityManager.TryGetNexusByTeamID(TeleportedEntity.TeamID, TargetEntity) then
            TargetEntity := Game.EntityManager.NexusNext(TeleportedEntity.Position);
        assert(assigned(TargetEntity), 'TWarheadSpottyTeleportComponent.FireWarhead: No nexus found!');
        TeleportTarget := RTarget.Create(TargetEntity);
      end
      // teleport imprinted target to target
      else if not FFixedTarget.IsEmpty then
      begin
        TeleportTarget := FFixedTarget;
      end
      else
      // teleport owner to target
      begin
        TeleportedEntity := Owner;
        TeleportTarget := Target;
      end;

      Offset := RVector2.ZERO;
      if FTeleportedEntityID < 0 then
      begin
        if ((FOffset > 0) or FOffsetByCollisionRadius) and TeleportTarget.TryGetTargetEntity(TargetEntity) then
        begin
          OffsetRange := FOffset;
          if FOffsetByCollisionRadius then
              OffsetRange := OffsetRange + TargetEntity.CollisionRadius + TeleportedEntity.CollisionRadius;
          Offset := (TeleportedEntity.Position - TargetEntity.Position).Normalize * OffsetRange;
        end;

        // remove entity from battlefield
        TeleportedEntity.Eventbus.Write(eiExiled, [True]);
        // break up targeting stuff by virtually converting unit into new unit
        GlobalEventbus.Trigger(eiReplaceEntity, [TeleportedEntity.ID, Game.EntityManager.GenerateUniqueID, True]);
      end;

      if FAsProjectile then
      begin
        // save entity in projectile
        SkinID := Owner.GetSkinID(ComponentGroup);
        ServerGame.ServerEntityManager.SpawnUnit(
          TeleportedEntity.Position,
          TeleportedEntity.Position.DirectionTo(TeleportTarget.GetTargetPosition),
          Eventbus.Read(eiWelaUnitPattern, [], ComponentGroup).AsString,
          CardLeague,
          CardLevel,
          Owner.TeamID,
          FOwner.ID,
          FOwner,
          procedure(Entity : TEntity)
          var
            GroundTarget : RTarget;
          begin
            GroundTarget := RTarget.Create(TeleportTarget.GetTargetPosition + Offset);
            TWarheadSpottyTeleportComponent.CreateGrouped(Entity, [0])
              .ImprintTeleportedID(TeleportedEntity.ID)
              .ToTarget(GroundTarget);
            Entity.Eventbus.Write(eiWelaSavedTargets, [ATarget.Create(GroundTarget).ToRParam]);

            Entity.SkinID := SkinID;
            Entity.Blackboard.SetValue(eiSkinIdentifier, [], SkinID);
          end);
      end
      else
      begin
        TeleportTo := TeleportTarget.GetTargetPosition;
        TeleportedEntity.Position := TeleportTo + Offset;
        TeleportedEntity.Eventbus.Trigger(eiStand, []);
        // SyncPosition is needed, because some units such as towers don't react on eiStand, which normally syncs position
        TeleportedEntity.Eventbus.Trigger(eiSyncPosition, [TeleportTo + Offset]);
        // bring entity back to the battlefield
        TeleportedEntity.Eventbus.Write(eiExiled, [False]);
      end;
    end;
  end;
end;

function TWarheadSpottyTeleportComponent.ImprintTeleportedID(ID : integer) : TWarheadSpottyTeleportComponent;
begin
  FTeleportedEntityID := ID;
  Result := self;
end;

{ TWarheadSpottyRemoveBuffComponent }

function TWarheadSpottyRemoveBuffComponent.All : TWarheadSpottyRemoveBuffComponent;
begin
  Result := self;
  FMustHaveAny := ALL_BUFF_TYPES;
end;

procedure TWarheadSpottyRemoveBuffComponent.ApplyEffect(Entity : TEntity);
begin
  if assigned(Entity) then
  begin
    Entity.Eventbus.Trigger(eiRemoveBuffs, [RParam.From<SetBuffType>(FMustHaveAny), RParam.From<SetBuffType>(FMustNotHave)]);
  end;
end;

function TWarheadSpottyRemoveBuffComponent.MustNotHave(TargetBuffs : TArray<byte>) : TWarheadSpottyRemoveBuffComponent;
begin
  Result := self;
  FMustNotHave := ByteArrayToSetBuffType(TargetBuffs);
end;

function TWarheadSpottyRemoveBuffComponent.MustHaveAny(TargetBuffs : TArray<byte>) : TWarheadSpottyRemoveBuffComponent;
begin
  Result := self;
  FMustHaveAny := ByteArrayToSetBuffType(TargetBuffs);
end;

{ TWarheadSplashResourceCollectComponent }

procedure TWarheadSplashResourceCollectComponent.ApplyEffect(const Targets : TList<TEntity>);
var
  sCollectedAmount : single;
  iCollectedAmount : integer;
  ConvertedAmount : RParam;
  Balance, Cap : RParam;
  i : integer;
  Target : TEntity;
  Full : boolean;
begin
  // reset resource
  sCollectedAmount := 100000.0;
  iCollectedAmount := 100000;
  if FConvertedResource in RES_FLOAT_RESOURCES then
      ConvertedAmount := sCollectedAmount
  else
      ConvertedAmount := iCollectedAmount;
  Owner.Eventbus.Trigger(eiResourceSubtraction, [ord(FConvertedResource), ConvertedAmount], FTargetGroup);
  Cap := Owner.Cap(FConvertedResource, FTargetGroup);
  if Targets.Count > 0 then
  begin
    // collect and remove resource from each target
    sCollectedAmount := 0.0;
    iCollectedAmount := 0;
    Full := False;
    for i := 0 to Targets.Count - 1 do
    begin
      Target := Targets[i];

      Balance := Target.Balance(FCollectedResource);
      if FCollectedResource in RES_FLOAT_RESOURCES then
      begin
        if not Cap.IsEmpty and (sCollectedAmount + Balance.AsSingle >= Cap.AsSingle) then
        begin
          Balance := Max(0.0, Cap.AsSingle - sCollectedAmount);
          Full := True;
        end;
        sCollectedAmount := sCollectedAmount + Balance.AsSingle
      end
      else
      begin
        if not Cap.IsEmpty and (iCollectedAmount + Balance.AsInteger >= Cap.AsInteger) then
        begin
          Balance := Max(0, Cap.AsInteger - iCollectedAmount);
          Full := True;
        end;
        iCollectedAmount := iCollectedAmount + Balance.AsInteger;
      end;
      Target.Eventbus.Trigger(eiResourceSubtraction, [ord(FCollectedResource), Balance]);
      if Full then
          break;
    end;
    // convert resource
    if FCollectedResource in RES_FLOAT_RESOURCES then
    begin
      if FConvertedResource in RES_INT_RESOURCES then
          iCollectedAmount := trunc(sCollectedAmount);
    end
    else
    begin
      if FConvertedResource in RES_FLOAT_RESOURCES then
          sCollectedAmount := iCollectedAmount;
    end;
    if FConvertedResource in RES_FLOAT_RESOURCES then
        ConvertedAmount := sCollectedAmount
    else
        ConvertedAmount := iCollectedAmount;
    // redeem collected amount to owner
    Owner.Eventbus.Trigger(eiResourceTransaction, [ord(FConvertedResource), ConvertedAmount], FTargetGroup);
  end;
end;

function TWarheadSplashResourceCollectComponent.CollectsResource(Resource : EnumResource) : TWarheadSplashResourceCollectComponent;
begin
  Result := self;
  FCollectedResource := Resource;
end;

function TWarheadSplashResourceCollectComponent.ConvertedTo(Resource : EnumResource) : TWarheadSplashResourceCollectComponent;
begin
  Result := self;
  FConvertedResource := Resource;
end;

function TWarheadSplashResourceCollectComponent.SetToValue : TWarheadSplashResourceCollectComponent;
begin
  Result := self;
  FSetToValue := True;
end;

function TWarheadSplashResourceCollectComponent.TargetGroup(Group : TArray<byte>) : TWarheadSplashResourceCollectComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TWarheadSplashKillComponent }

procedure TWarheadSplashKillComponent.ApplyEffect(const Targets : TList<TEntity>);
var
  Entity : TEntity;
  i : integer;
begin
  for i := 0 to Targets.Count - 1 do
  begin
    Entity := Targets[i];
    if FExile then Entity.Eventbus.Write(eiExiled, [True]);
    if FSacrifice then Entity.Eventbus.Trigger(eiSacrifice, [FOwner.ID, FOwner.Eventbus.Read(eiOwnerCommander, [])]);
    Entity.Eventbus.Trigger(eiKill, [FOwner.ID, FOwner.Eventbus.Read(eiOwnerCommander, [])]);
    if not Entity.Eventbus.Read(eiIsAlive, []).AsBoolean then
        Eventbus.Trigger(eiKillDone, [Entity.ID], ComponentGroup);
  end;
end;

function TWarheadSplashKillComponent.Exile : TWarheadSplashKillComponent;
begin
  Result := self;
  FExile := True;
end;

function TWarheadSplashKillComponent.Sacrifice : TWarheadSplashKillComponent;
begin
  Result := self;
  FSacrifice := True;
end;

{ TWarheadSpottyWelaStopComponent }

procedure TWarheadSpottyWelaStopComponent.ApplyEffect(Entity : TEntity);
begin
  Entity.Eventbus.Trigger(eiWelaStop, []);
end;

initialization

ScriptManager.ExposeClass(TWarheadDebugThrowEventComponent);

ScriptManager.ExposeClass(TWarheadComponent);

ScriptManager.ExposeClass(TWarheadSpottyDamageComponent);
ScriptManager.ExposeClass(TWarheadSpottyHealthComponent);
ScriptManager.ExposeClass(TWarheadSpottyHealComponent);
ScriptManager.ExposeClass(TWarheadSpottyResourceComponent);
ScriptManager.ExposeClass(TWarheadSpottyBuffComponent);
ScriptManager.ExposeClass(TWarheadSpottyPermaBuffComponent);
ScriptManager.ExposeClass(TWarheadSpottyKillComponent);
ScriptManager.ExposeClass(TWarheadSpottyTeleportComponent);
ScriptManager.ExposeClass(TWarheadSpottyRemoveBuffComponent);
ScriptManager.ExposeClass(TWarheadSpottyWelaStopComponent);

ScriptManager.ExposeClass(TWarheadSplashComponent);
ScriptManager.ExposeClass(TWarheadSplashHealthComponent);
ScriptManager.ExposeClass(TWarheadSplashDamageComponent);
ScriptManager.ExposeClass(TWarheadSplashHealComponent);
ScriptManager.ExposeClass(TWarheadSplashResourceCollectComponent);
ScriptManager.ExposeClass(TWarheadSplashKillComponent);

end.
