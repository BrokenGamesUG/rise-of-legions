{$INCLUDE 'Math.dws'};
var
  InheritsFromPreceding : string = 'Projectiles\Blue\Missile.ets';

procedure CreateData(Entity : TEntity);
begin
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\Blue\Airdominator\Missile\Missile.xml')
      .ApplyLegacySizeFactor;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('AirdominatorLifted')
      .TriggerOnKillDone
      .CheckUnitPropertyMustHave([upLifted]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(0, 0, 1)
      .EndTangent(0, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1])
      .BindToTargetSubPosition(BIND_ZONE_HIT_ZONE_AIR);

    TSoundComponent.Create(Entity, 'event:/card/blue/unit/airdominator/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
