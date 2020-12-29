{$INCLUDE 'Math.dws'};

var
  InheritsFrom : string = 'Projectiles/Neutral/LanetowerBaseProjectile.ets';

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], f([1.5, 1.5, 2.0, 2.0, 2.0], Entity.CardLeague));
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
