{$INCLUDE 'BuildingCardTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingCardData(Entity, False, {@UBL_Tier}2);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Blue\AmmoFactory');

  Entity.Blackboard.SetValue(eiWelaRange, [5], 10000.0);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingCardMeta(Entity);

  {$IFDEF CLIENT}
    TIndicatorShowTextComponent.CreateGrouped(Entity, [])
      .ShowResource(reGadgetCount)
      .ResourceGroup([])
      .ResourceFromCommander
      .Color($FF5BA9FF)
      .CursorOffset(30, -40);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingCardEntity(Entity);

  {$IFDEF SERVER}
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [5])
      .FireAtTarget;
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [5])
      .ComparedResource(reGadgetCount)
      .CheckFull
      .ChecksCommander;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [5])
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [5])
      .MustHave([upGadget]);
    TWelaEfficiencyCreatedComponent.CreateGrouped(Entity, [5]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [5])
      .Sacrifice;
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
