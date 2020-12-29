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
      .BothTangents(PI / 8, 0, 1.0)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);
  {$ENDIF}
end;
