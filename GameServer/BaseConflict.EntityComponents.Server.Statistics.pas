unit BaseConflict.EntityComponents.Server.Statistics;

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
  BaseConflict.EntityComponents.Server.Welas,
  BaseConflict.Types.Shared;

type

  {$RTTI INHERIT}
  /// <summary> Will be placed in every unit and collects statistics for it. </summary>
  TStatisticsUnitComponent = class(TEntityComponent)
    protected
      FGainedDamage : single;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterCreate() : boolean;
      [XEvent(eiYouHaveKilledMeShameOnYou, epLast, etTrigger)]
      function OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiInstaDie, epLast, etTrigger)]
      function OnInstaDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiTakeDamage, epLast, etRead)]
      function OnTakeDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
      [XEvent(eiDamageDone, epLast, etTrigger)]
      function OnDoneDamage(Amount, DamageType, TargetEntity : RParam) : boolean;
      [XEvent(eiHeal, epLast, etRead)]
      function OnHeal(var Amount : RParam; HealModifier, InflictorID, Previous : RParam) : RParam;
      [XEvent(eiOverheal, epLast, etTrigger)]
      function OnOverheal(Amount, HealModifier, InflictorID : RParam) : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Tracks statistics to single welas of entities. </summary>
  TWelaEffectStatisticsComponent = class(TEntityComponent)
    protected
      FWelaName : AString;
      FTriggerOnKill, FTriggerOnFire, FTriggerOnKillDone, FTriggerOnDie, FTriggerOnKilled, FTriggerOnTakeDamage,
        FTriggerOnHealDone, FTriggerOnDamageDone, FTriggerOnDamageDoneTargets, FTriggerOnHeal, FTriggerOnCreate : boolean;
      FKillCountsGlobal, FCheckMaxTargets, FCheckDamageType, FTakeOwnerFromTarget : boolean;
      FCheckUnitPropertyMustHave, FCheckUnitPropertyMustHaveAny : SetUnitProperty;
      FCheckResourceMax, FCheckResourceEmpty, FTriggerTimesByResource : EnumResource;
      FDamageType : EnumDamageType;
      FDurationCounter : TTimer;
      FNth, FNthCounter : integer;
      function Check : boolean;
      function CheckTarget(Target : RTarget) : boolean;
      function Times : integer;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterCreate() : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(const TargetsParam : RParam) : boolean;
      [XEvent(eiYouHaveKilledMeShameOnYou, epLast, etTrigger)]
      function OnYouHaveKilledMeShameOnYou(const KilledUnitID : RParam) : boolean;
      [XEvent(eiKillDone, epLast, etTrigger)]
      function OnKillDone(const KilledUnitID : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiTakeDamage, epLast, etRead)]
      function OnTakeDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
      [XEvent(eiHeal, epLast, etRead)]
      function OnHeal(var Amount : RParam; HealModifier, InflictorID, Previous : RParam) : RParam;
      [XEvent(eiDamageDone, epLast, etTrigger)]
      function OnDamageDone(Amount, DamageType, TargetEntity : RParam) : boolean;
      [XEvent(eiHealDone, epLast, etTrigger)]
      function OnHealDone(Amount, DamageType, TargetEntity : RParam) : boolean;
    public
      /// <summary> Adds a wela name for which events are tracked. Can be called multiple times for multiple names. </summary>
      function Name(const WelaName : string) : TWelaEffectStatisticsComponent;
      /// <summary> Only throws the events if a certain resource is at its cap. </summary>
      function CheckResourceMax(Resource : EnumResource) : TWelaEffectStatisticsComponent;
      /// <summary> Only throws the events if a certain resource is at 0. </summary>
      function CheckResourceEmpty(Resource : EnumResource) : TWelaEffectStatisticsComponent;
      /// <summary> Only throws the events for each target have the unit property. Only for TriggerOnFire and TriggerOnKill. </summary>
      function CheckUnitPropertyMustHave(UnitProperties : TArray<byte>) : TWelaEffectStatisticsComponent;
      /// <summary> Only throws the events for each target have the unit property. Only for TriggerOnFire and TriggerOnKill. </summary>
      function CheckUnitPropertyMustHaveAny(UnitProperties : TArray<byte>) : TWelaEffectStatisticsComponent;
      /// <summary> Only throws the events if the maximum amount of targets are targeted. Only for OnFire. </summary>
      function CheckMaxTargets() : TWelaEffectStatisticsComponent;
      /// <summary> Only throws the events if the damage type is present. Only for OnTakeDamage. </summary>
      function CheckDamageType(DamageType : EnumDamageType) : TWelaEffectStatisticsComponent;
      /// <summary> Triggers only each nth times called. </summary>
      function CheckNth(Nth : integer) : TWelaEffectStatisticsComponent;
      /// <summary> Throws events multiple times depending on the balance of the given resource. </summary>
      function TriggerTimesByResource(Resource : EnumResource) : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_triggers_ event for the owner at after create. </summary>
      function TriggerOnCreate : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_duration_ event for the owner at the end of this component. </summary>
      function TriggerOnDuration : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_dealt_damage_ for the owner. </summary>
      function TriggerOnDamageDone : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_targets_ for the owner. </summary>
      function TriggerOnDamageDoneTargets : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_dealt_damage_ for the owner. </summary>
      function TriggerOnHealDone : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_death_ event for the owner. </summary>
      function TriggerOnDie : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_kills_ event for the killer. </summary>
      function TriggerOnKilled : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_triggers_ and wela_targets_ event for the owner. </summary>
      function TriggerOnFire : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_kills_ event for the owner. Triggered by any death of a killed unit by this unit. </summary>
      function TriggerOnKill : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_kills_ event for the owner. Triggered by a warhead in the componentgroup. </summary>
      function TriggerOnKillDone : TWelaEffectStatisticsComponent;
      /// <summary> Throws a global_kills_ event for the owner. Triggered by a warhead in the componentgroup. </summary>
      function TriggerGlobalOnKillDone : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_gain_damage_ for the owner. </summary>
      function TriggerOnTakeDamage : TWelaEffectStatisticsComponent;
      /// <summary> Throws a wela_gain_damage_ for the owner. </summary>
      function TriggerOnHeal : TWelaEffectStatisticsComponent;
      /// <summary> Thrown events for the owner of the target. Only for OnFire. </summary>
      function TakeOwnerFromTarget : TWelaEffectStatisticsComponent;

      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals.Server,
  BaseConflict.Game;

{ TStatisticsUnitComponent }

function TStatisticsUnitComponent.OnAfterCreate : boolean;
begin
  Result := True;
  if dtRanged in Eventbus.Read(eiDamageType, [], [GROUP_MAINWEAPON]).AsType<SetDamageType> then
  begin
    ServerGame.Statistics.WelaSpawns(Owner.CommanderID, 'Ranged', 1);
    ServerGame.Statistics.WelaSpawns(Owner.CommanderID, 'Range', round(Eventbus.Read(eiWelaRange, [], [GROUP_MAINWEAPON]).AsSingle));
  end;
  if Owner.HasUnitProperty(upLegendary) then
      ServerGame.Statistics.WelaSpawns(Owner.CommanderID, 'upLegendary', 1);
  if Owner.HasUnitProperty(upMelee) then
      ServerGame.Statistics.WelaSpawns(Owner.CommanderID, 'Melee', 1);
  if Owner.BalanceSingle(reHealth) >= 500.0 then
      ServerGame.Statistics.WelaSpawns(Owner.CommanderID, 'gte500Health', 1);
end;

function TStatisticsUnitComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
var
  StateEffects : SetUnitProperty;
  StateEffectCount : integer;
  StateEffect : EnumUnitProperty;
  i : integer;
begin
  Result := True;
  if assigned(ServerGame) then
  begin
    ServerGame.Statistics.UnitDeaths(Owner.CommanderID, Owner.ScriptFileName);

    StateEffects := Owner.UnitProperties * UNIT_PROPERTIES_STATE_EFFECTS;
    StateEffectCount := 0;
    for StateEffect in StateEffects do
        inc(StateEffectCount);
    if StateEffectCount >= 2 then
        ServerGame.Statistics.WelaKills(KillerCommanderID.AsInteger, 'with_two_state_effects', 1);

    ServerGame.Statistics.GlobalKills(KillerCommanderID.AsInteger);

    for i := 0 to ServerGame.Commanders.Count - 1 do
      if Owner.HasUnitProperty(upBase) and (ServerGame.Commanders[i].TeamID <> Owner.TeamID) and ServerGame.Commanders[i].HasUnitProperty(upHasEchoesOfTheFuture) then
      begin
        ServerGame.Statistics.WelaKills(ServerGame.Commanders[i].ID, 'basebuildingwhileeotfactive', 1);
      end;
  end;
end;

function TStatisticsUnitComponent.OnDoneDamage(Amount, DamageType, TargetEntity : RParam) : boolean;
var
  DamageTypeSet : SetDamageType;
begin
  Result := True;
  if assigned(ServerGame) then
  begin
    DamageTypeSet := DamageType.AsType<SetDamageType>;
    if (dtRanged in DamageTypeSet) and TargetEntity.AsType<TEntity>.HasUnitProperty(upRooted) then
        ServerGame.Statistics.WelaDealtDamage(Owner.CommanderID, 'rootbyranged', round(Amount.AsSingle));
  end;
end;

function TStatisticsUnitComponent.OnHeal(var Amount : RParam; HealModifier, InflictorID, Previous : RParam) : RParam;
var
  DamageTypeSet : SetDamageType;
begin
  Result := Previous;
  if assigned(ServerGame) then
  begin
    DamageTypeSet := HealModifier.AsType<SetDamageType>;
    if (dtFlatHeal in DamageTypeSet) then
        ServerGame.Statistics.WelaDamage(Owner.CommanderID, 'FlatHeal', round(Amount.AsSingle));
    if (dtHoT in DamageTypeSet) then
        ServerGame.Statistics.WelaDamage(Owner.CommanderID, 'HoT', round(Amount.AsSingle));
  end;
end;

function TStatisticsUnitComponent.OnInstaDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  if assigned(ServerGame) then
  begin
    ServerGame.Statistics.GlobalInstaDeaths(Owner.CommanderID);
    ServerGame.Statistics.GlobalInstaKills(KillerCommanderID.AsInteger);
  end;
end;

function TStatisticsUnitComponent.OnOverheal(Amount, HealModifier, InflictorID : RParam) : boolean;
begin
  Result := True;
  if assigned(ServerGame) then
  begin
    ServerGame.Statistics.WelaDamage(Owner.CommanderID, 'Overheal', round(Amount.AsSingle));
  end;
end;

function TStatisticsUnitComponent.OnTakeDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
var
  DamageTypeSet : SetDamageType;
begin
  Result := Previous;
  if assigned(ServerGame) then
  begin
    FGainedDamage := FGainedDamage + Amount.AsSingle;
    ServerGame.Statistics.WelaDamageMax(Owner.CommanderID, 'max', round(FGainedDamage));
    ServerGame.Statistics.GlobalDamage(Owner.CommanderID, round(FGainedDamage));
    DamageTypeSet := DamageType.AsType<SetDamageType>;
    if (dtRanged in DamageTypeSet) and not(dtTrue in DamageTypeSet) then
        ServerGame.Statistics.WelaDamage(Owner.CommanderID, 'Ranged', round(Amount.AsSingle));
    if (dtTrue in DamageTypeSet) and (upRooted in Owner.UnitProperties) then
        ServerGame.Statistics.WelaDamage(Owner.CommanderID, 'RootByBasebuilding', round(Amount.AsSingle));
    if (upLegendary in Owner.UnitProperties) then
        ServerGame.Statistics.WelaDamage(Owner.CommanderID, 'upLegendary', round(Amount.AsSingle));
  end;
end;

function TStatisticsUnitComponent.OnYouHaveKilledMeShameOnYou(KilledUnitID : RParam) : boolean;
begin
  Result := True;
  // we don't want to count suicide as kill
  if assigned(ServerGame) and (KilledUnitID.AsInteger <> Owner.ID) then
  begin
    ServerGame.Statistics.UnitKills(Owner.CommanderID, Owner.ScriptFileName);
    if (upBuilding in Owner.UnitProperties) and not(upBase in Owner.UnitProperties) then
        ServerGame.Statistics.WelaKills(Owner.CommanderID, 'upBuilding', 1);
    if (upLegendary in Owner.UnitProperties) then
        ServerGame.Statistics.WelaKills(Owner.CommanderID, 'upLegendary', 1);
  end;
end;

{ TWelaEffectStatisticsComponent }

function TWelaEffectStatisticsComponent.Check : boolean;
begin
  Result := True;
  if FNth > 0 then
  begin
    inc(FNthCounter);
    Result := Result and ((FNthCounter mod FNth) = 0);
  end;
  if FCheckResourceMax <> reNone then
  begin
    Result := Result and
      ResourceCompare(FCheckResourceMax,
      Owner.Balance(FCheckResourceMax, ComponentGroup),
      coGreaterEqual,
      Owner.Cap(FCheckResourceMax, ComponentGroup));
  end;
  if FCheckResourceEmpty <> reNone then
  begin
    Result := Result and
      ResourceCompare(FCheckResourceEmpty,
      Owner.Balance(FCheckResourceEmpty, ComponentGroup),
      coLowerEqual,
      0)
  end;
end;

function TWelaEffectStatisticsComponent.CheckDamageType(DamageType : EnumDamageType) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FCheckDamageType := True;
  FDamageType := DamageType;
end;

function TWelaEffectStatisticsComponent.CheckMaxTargets : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FCheckMaxTargets := True;
end;

function TWelaEffectStatisticsComponent.CheckNth(Nth : integer) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FNth := Nth;
end;

function TWelaEffectStatisticsComponent.CheckResourceEmpty(Resource : EnumResource) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FCheckResourceEmpty := Resource;
end;

function TWelaEffectStatisticsComponent.CheckResourceMax(Resource : EnumResource) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FCheckResourceMax := Resource;
end;

function TWelaEffectStatisticsComponent.CheckTarget(Target : RTarget) : boolean;
var
  TargetEntity : TEntity;
  UnitProperties : SetUnitProperty;
begin
  Result := True;
  if (FCheckUnitPropertyMustHave <> []) or (FCheckUnitPropertyMustHaveAny <> []) then
  begin
    if Target.TryGetTargetEntity(TargetEntity) then
    begin
      UnitProperties := TargetEntity.UnitProperties;
      if FCheckUnitPropertyMustHave <> [] then
          Result := Result and (FCheckUnitPropertyMustHave <= UnitProperties);
      if FCheckUnitPropertyMustHaveAny <> [] then
          Result := Result and (FCheckUnitPropertyMustHaveAny * UnitProperties <> []);
    end
    else
        Result := False;
  end;
end;

function TWelaEffectStatisticsComponent.CheckUnitPropertyMustHave(UnitProperties : TArray<byte>) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FCheckUnitPropertyMustHave := ByteArrayToSetUnitProperies(UnitProperties);
end;

function TWelaEffectStatisticsComponent.CheckUnitPropertyMustHaveAny(UnitProperties : TArray<byte>) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FCheckUnitPropertyMustHaveAny := ByteArrayToSetUnitProperies(UnitProperties);
end;

destructor TWelaEffectStatisticsComponent.Destroy;
var
  i : integer;
begin
  if assigned(FDurationCounter) then
  begin
    if assigned(ServerGame) then
    begin
      for i := 0 to FWelaName.Count - 1 do
      begin
        ServerGame.Statistics.WelaDuration(Owner.CommanderID, FWelaName[i], FDurationCounter.TimesExpired);
      end;
    end;
    FDurationCounter.Free;
  end;
  inherited;
end;

function TWelaEffectStatisticsComponent.Name(const WelaName : string) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  HArray.Push<string>(FWelaName, WelaName);
end;

function TWelaEffectStatisticsComponent.OnAfterCreate : boolean;
var
  i : integer;
begin
  Result := True;
  if FTriggerOnCreate and assigned(ServerGame) and Check then
  begin
    for i := 0 to FWelaName.Count - 1 do
    begin
      if FTriggerOnCreate then
          ServerGame.Statistics.WelaTriggers(Owner.CommanderID, FWelaName[i], Times);
    end;
  end;
end;

function TWelaEffectStatisticsComponent.OnDamageDone(Amount, DamageType, TargetEntity : RParam) : boolean;
var
  i : integer;
begin
  Result := True;
  if (FTriggerOnDamageDone or FTriggerOnDamageDoneTargets) and assigned(ServerGame) and Check and CheckTarget(RTarget.Create(TargetEntity.AsType<TEntity>)) then
  begin
    for i := 0 to FWelaName.Count - 1 do
    begin
      if FTriggerOnDamageDone then
          ServerGame.Statistics.WelaDealtDamage(Owner.CommanderID, FWelaName[i], round(Amount.AsSingle));
      if FTriggerOnDamageDoneTargets then
          ServerGame.Statistics.WelaTargets(Owner.CommanderID, FWelaName[i], Times);
    end;
  end;
end;

function TWelaEffectStatisticsComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
var
  i : integer;
begin
  Result := True;
  if (FTriggerOnDie or FTriggerOnKilled) and assigned(ServerGame) and Check then
  begin
    for i := 0 to FWelaName.Count - 1 do
    begin
      // we don't want to count suicide as kill
      if FTriggerOnKilled and (KillerID.AsInteger <> Owner.ID) then
          ServerGame.Statistics.WelaKills(KillerCommanderID.AsInteger, FWelaName[i], Times);
      if FTriggerOnDie then
          ServerGame.Statistics.WelaDeaths(Owner.CommanderID, FWelaName[i], Times);
    end;
  end;
end;

function TWelaEffectStatisticsComponent.OnFire(const TargetsParam : RParam) : boolean;
var
  i, ii : integer;
  Targets : ATarget;
  TargetEntity : TEntity;
begin
  Result := True;
  if FTriggerOnFire and IsLocalCall and assigned(ServerGame) and Check and
    (not FCheckMaxTargets or (Eventbus.Read(eiWelaTargetCount, [], ComponentGroup).AsInteger <= TargetsParam.AsATarget.Count)) then
  begin
    Targets := TargetsParam.AsATarget;
    for i := 0 to FWelaName.Count - 1 do
    begin
      ServerGame.Statistics.WelaTriggers(Owner.CommanderID, FWelaName[i], Times);
      for ii := 0 to length(Targets) - 1 do
        if CheckTarget(Targets[ii]) then
        begin
          if not FTakeOwnerFromTarget or not Targets[ii].TryGetTargetEntity(TargetEntity) then
              TargetEntity := Owner;
          ServerGame.Statistics.WelaTargets(TargetEntity.CommanderID, FWelaName[i], Times);
        end;
    end;
  end;
end;

function TWelaEffectStatisticsComponent.OnHeal(var Amount : RParam; HealModifier, InflictorID, Previous : RParam) : RParam;
var
  i : integer;
begin
  Result := Previous;
  if FTriggerOnHeal and assigned(ServerGame) and Check and
    (not FCheckDamageType or (FDamageType in HealModifier.AsType<SetDamageType>)) then
  begin
    for i := 0 to FWelaName.Count - 1 do
    begin
      ServerGame.Statistics.WelaDamage(Owner.CommanderID, FWelaName[i], round(Amount.AsSingle));
    end;
  end;
end;

function TWelaEffectStatisticsComponent.OnHealDone(Amount, DamageType, TargetEntity : RParam) : boolean;
var
  i : integer;
begin
  Result := True;
  if FTriggerOnHealDone and assigned(ServerGame) and Check then
  begin
    for i := 0 to FWelaName.Count - 1 do
    begin
      ServerGame.Statistics.WelaDealtDamage(Owner.CommanderID, FWelaName[i], round(Amount.AsSingle));
    end;
  end;
end;

function TWelaEffectStatisticsComponent.OnKillDone(const KilledUnitID : RParam) : boolean;
var
  i : integer;
begin
  Result := True;
  if (FKillCountsGlobal or FTriggerOnKillDone) and IsLocalCall and assigned(ServerGame) and
    (KilledUnitID.AsInteger <> Owner.ID) and Check then
  begin
    // we don't want to count suicide as kill
    if FTriggerOnKillDone then
      for i := 0 to FWelaName.Count - 1 do
      begin
        ServerGame.Statistics.WelaKills(Owner.CommanderID, FWelaName[i], Times);
      end;
    if FKillCountsGlobal then
        ServerGame.Statistics.GlobalKills(Owner.CommanderID);
  end;
end;

function TWelaEffectStatisticsComponent.OnTakeDamage(var Amount : RParam; DamageType, InflictorID, Previous : RParam) : RParam;
var
  i : integer;
begin
  Result := Previous;
  if FTriggerOnTakeDamage and assigned(ServerGame) and Check and
    (not FCheckDamageType or (FDamageType in DamageType.AsType<SetDamageType>)) then
  begin
    for i := 0 to FWelaName.Count - 1 do
    begin
      ServerGame.Statistics.WelaDamage(Owner.CommanderID, FWelaName[i], round(Amount.AsSingle));
    end;
  end;
end;

function TWelaEffectStatisticsComponent.OnYouHaveKilledMeShameOnYou(const KilledUnitID : RParam) : boolean;
var
  i : integer;
begin
  Result := True;
  if FTriggerOnKill and assigned(ServerGame) and (KilledUnitID.AsInteger <> Owner.ID) and Check and CheckTarget(RTarget.Create(KilledUnitID.AsInteger)) then
  begin
    for i := 0 to FWelaName.Count - 1 do
    begin
      ServerGame.Statistics.WelaKills(Owner.CommanderID, FWelaName[i], Times);
    end;
  end;
end;

function TWelaEffectStatisticsComponent.TakeOwnerFromTarget : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTakeOwnerFromTarget := True;
end;

function TWelaEffectStatisticsComponent.Times : integer;
begin
  if FTriggerTimesByResource = reNone then
      Result := 1
  else
  begin
    if FTriggerTimesByResource in RES_INT_RESOURCES then
        Result := Owner.Balance(FTriggerTimesByResource, ComponentGroup).AsInteger
    else
        Result := round(Owner.Balance(FTriggerTimesByResource, ComponentGroup).AsSingle)
  end;
end;

function TWelaEffectStatisticsComponent.TriggerGlobalOnKillDone : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FKillCountsGlobal := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnCreate : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnCreate := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnDamageDone : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnDamageDone := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnDamageDoneTargets : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnDamageDoneTargets := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnDie : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnDie := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnDuration : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FDurationCounter := TTimer.CreateAndStart(1000);
end;

function TWelaEffectStatisticsComponent.TriggerOnFire : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnFire := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnHeal : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnHeal := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnHealDone : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnHealDone := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnKill : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnKill := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnKillDone : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnKillDone := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnKilled : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnKilled := True;
end;

function TWelaEffectStatisticsComponent.TriggerOnTakeDamage : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerOnTakeDamage := True;
end;

function TWelaEffectStatisticsComponent.TriggerTimesByResource(Resource : EnumResource) : TWelaEffectStatisticsComponent;
begin
  Result := self;
  FTriggerTimesByResource := Resource;
end;

initialization

ScriptManager.ExposeClass(TStatisticsUnitComponent);
ScriptManager.ExposeClass(TWelaEffectStatisticsComponent);

end.
