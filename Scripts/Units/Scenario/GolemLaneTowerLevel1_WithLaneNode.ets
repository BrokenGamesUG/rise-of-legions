var
  InheritsFrom : string = 'Units\Scenario\GolemLaneTowerLevel1.ets';

procedure CreateData(Entity : TEntity);
begin
  // On-Death spawn capture point
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Units\Neutral\LaneNode.ets');
  Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [2], 1, 'Units\Neutral\LaneNode_Red.ets');
  Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [2], 2, 'Units\Neutral\LaneNode_Blue.ets');
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
    // On-Death spawn capture point
    TAutoBrainOnDeathComponent.CreateGrouped(Entity, [2]);
    TWelaHelperResolveComponent.CreateGrouped(Entity, [2])
      .ResolveTeamID();
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [2])
      .SetSpawnedTeam(0);
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
