var
  InheritsFrom : string = 'Projectiles/White/ArcherBaseProjectile.ets';

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
      .StartTangent(PI / 2, 0, 3.0)
      .EndTangent(PI / 3, 0, 1.0)
      .OrientStartWithTarget()
      .BindToSubPosition(BIND_ZONE_CENTER, [0, 1]);
  {$ENDIF}
end;
