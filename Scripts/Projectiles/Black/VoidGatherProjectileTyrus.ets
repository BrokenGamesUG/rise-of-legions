var
  InheritsFrom : string = 'Projectiles\Black\VoidGatherProjectile.ets';

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], (3 + random * 3) / 1000);
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
  {$ENDIF}
end;
