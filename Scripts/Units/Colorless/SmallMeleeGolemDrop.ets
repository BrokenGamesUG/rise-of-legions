{$INCLUDE 'DropTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitDropData(Entity, False, {@UBL_Tier}1);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Colorless\SmallMeleeGolem');
  Entity.Blackboard.SetValue(eiWelaCount, [GROUP_DROP_SPAWNER], {@UBL_SquadSize}3);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitDropMeta(Entity);

  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitDropEntity(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;

