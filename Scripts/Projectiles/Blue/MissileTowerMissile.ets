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
    TMeshComponent.Create(Entity, 'Units\Blue\MissileTurret' + Entity.SkinFileSuffix + '\Missile\Missile.xml')
      .ApplyLegacySizeFactor;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(0, 0, 1)
      .EndTangent(1, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/blue/unit/missile_turret/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
