{$INCLUDE 'DropTemplate.dws'};

const MAX_LEVEL : integer = 10;

procedure CreateData(Entity : TEntity);
begin
  InitDropData(Entity, True, {@UBL_Tier}1);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Blue\Atlas');
  Entity.Blackboard.SetValue(eiWelaCount, [GROUP_DROP_SPAWNER], {@UBL_SquadSize}1);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reLevel, MAX_LEVEL);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reLevel, Min(Entity.BalanceInt(reCardTimesPlayed), MAX_LEVEL));

  Entity.Blackboard.SetValue(eiWelaDamage, [5], 100.0);

  Entity.Blackboard.SetValue(eiWelaDamage, [6], 1.0);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitDropMeta(Entity);

  {$IFDEF CLIENT}
    TIndicatorShowTextComponent.CreateGrouped(Entity, [])
      .ShowResource(reCardTimesPlayed)
      .ResourceGroup([])
      .NoCap
      .FixedCap(10)
      .Clamp(1, 10)
      .Color($FF8ba0b2)
      .ColorAtCap($FFEEF4AD)
      .CursorOffset(30, -40);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitDropEntity(Entity, True);

  {$IFDEF SERVER}
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [GROUP_DROP_SPAWNER])
      .Name('Supreme')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
