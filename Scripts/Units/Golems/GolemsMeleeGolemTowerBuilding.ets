{$INCLUDE 'BuildingCardTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingCardData(Entity, False, {@UBL_Tier}2);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Golems\GolemsMeleeGolemTower');
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingCardMeta(Entity);

  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingCardEntity(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
