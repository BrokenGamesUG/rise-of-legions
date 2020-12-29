var
  InheritsFrom : string = 'Projectiles/White/HeavyGunnerBaseProjectile.ets';

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
    TSoundComponent.Create(Entity, 'event:/card/white/unit/heavy_gunner/attack_impact')
      .TriggerOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnFree;
  {$ENDIF}
end;
