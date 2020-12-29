{$INCLUDE 'BuildingTemplate.dws'};

var
  InheritsFrom : string = 'Units\Scenario\BossSiegeGolemAttack.ets';

procedure CreateData(Entity : TEntity);
begin
  // Charge-Cap increase on tower destroy
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.5 * 60.0);
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








