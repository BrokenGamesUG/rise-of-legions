{$INCLUDE 'BuildingCardTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingCardData(Entity, True, {@UBL_Tier}3);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Blue\Aegis');
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
  InitBuildingCardEntity(Entity, True);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
