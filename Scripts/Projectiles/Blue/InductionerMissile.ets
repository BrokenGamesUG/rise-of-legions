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
    TMeshComponent.Create(Entity, 'Units\Blue\MissileTurret\Missile\Missile.xml')
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
      .StartTangent(0, 0, 2)
      .EndTangent(1, 0, 1)
      .BindToSubPosition('missile_launcher', [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/blue/unit/inductioner/missile_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
