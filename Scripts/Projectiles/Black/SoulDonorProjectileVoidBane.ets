var
  InheritsFrom : string = 'Projectiles\Black\SoulDonorProjectile.ets';

procedure CreateData(Entity : TEntity);
begin
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 2, 0, 2)
      .StartTangentRandom(PI / 2, 2 * PI, 0)
      .EndTangent(PI / 16, 0, 1)
      .MaxDistanceScaling(15);
  {$ENDIF}
end;
