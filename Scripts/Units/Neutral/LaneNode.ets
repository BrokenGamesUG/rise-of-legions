{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upGround, upBase, upLaneNode]);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reTeamPower1, 15.0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reTeamPower2, 15.0);

  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 200);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 16.5);
  Entity.Blackboard.SetValue(eiCooldown, [1], 500);
  Entity.Blackboard.SetValue(eiWelaDamage, [2, 3, 6, 7], 1.0);

  Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [4, 5], 0, 'Units\Neutral\LanetowerLevel1.ets');
  Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [4, 5], 1, 'Units\Neutral\LanetowerLevel2.ets');

  if Entity.CardLeague > 2 then
    Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [4, 5], 2, 'Units\Neutral\LanetowerLevel3.ets')
  else
    Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [4, 5], 2, 'Units\Neutral\LanetowerLevel2.ets');
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [4], reTeamPower1, 15.0);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [5], reTeamPower2, 15.0);

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIcon, 'minimap_icon_tower_%d.png');
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIconSize, 2.5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0,0), 1.2);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Neutral\LaneNode.pfx', 10.0/(3.0))
      .ActivateOnCreate();
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .HideInCaptureMode
      .DrawCircle(0.5)
      .Slice(0.57, 0.93)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'RangeLine.tga')
      .ShowTeamColor()
      .ShowWeaponRange()
      .IsPermanent;
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .HideInCaptureMode
      .DrawCircle(0.5)
      .Slice(0.07, 0.43)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'RangeLine.tga')
      .ShowTeamColor()
      .ShowWeaponRange()
      .IsPermanent;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Neutral\Capture%d.pfx', 10.0/4.0)
      .ActivateOnFire()
      .SetModelOffset(RVector3.Create(0,0.1,0))
      .ShowAsTeam(1);

    TParticleEffectComponent.CreateGrouped(Entity, [6], '\Neutral\Capture%d.pfx', 10.0/4.0)
      .ActivateOnFire()
      .SetModelOffset(RVector3.Create(0,0.1,0))
      .ShowAsTeam(2);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TPositionComponent.Create(Entity);

    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [1, 4, 5]);
    TWelaReadyAfterGameStartComponent.CreateGrouped(Entity, [1, 4, 5]);

    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .IgnoreOwnCollisionradius()
      .SetTargetTeamConstraint(tcAll);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upBase, upInvisible, upBanished]);
    TBrainCapturePointComponent.CreateGrouped(Entity, [1])
      .SetIdleGroup([8])
      .SetTeamGroup(1, [2], [3])
      .SetTeamGroup(2, [6], [7]);

    // Add Teampower1 if an unit of team 1 is near
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [2])
      .SetResourceType(reTeamPower1);

    // Reduce Teampower1 if no unit of team 1 is near
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reTeamPower1)
      .SetFactor(-1.0);

    // Add Teampower2 if an unit of team 2 is near
    TWelaEffectInstantComponent.CreateGrouped(Entity, [6]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [6])
      .SetResourceType(reTeamPower2);

    // Reduce Teampower2 if no unit of team 2 is near
    TWelaEffectInstantComponent.CreateGrouped(Entity, [7]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [7])
      .SetResourceType(reTeamPower2)
      .SetFactor(-1.0);

    // Replace with tower from team 1 if power is enough
    TWelaEffectReplaceComponent.CreateGrouped(Entity, [4])
      .SetNewTeam(1);
    TWelaReadyCostComponent.CreateGrouped(Entity, [4])
      .SetPayingGroup([]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [4]);

    TWelaHelperResolveComponent.CreateGrouped(Entity, [4, 5])
      .ResolveCurrentTier;

    // Replace with tower from team 2 if power is enough
    TWelaEffectReplaceComponent.CreateGrouped(Entity, [5])
      .SetNewTeam(2);
    TWelaReadyCostComponent.CreateGrouped(Entity, [5])
      .SetPayingGroup([]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [5]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TShowOnMinimapComponent.Create(Entity);
    TEntityDisplayWrapperComponent.Create(Entity);

    TIndicatorCooldownCircleComponent.Create(Entity)
      .ShowsResource(reTeamPower1)
      .ShowAsTeam(1)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'ProgressCircle.tga')
      .SetRadius(1.94)
      .SetThickness(0.4)
      .Offset(0, 0, 0.05)
      .SetLinearBlend
      .Opacity(0.7);
    TIndicatorCooldownCircleComponent.Create(Entity)
      .ShowsResource(reTeamPower2)
      .ShowAsTeam(2)
      .InvertDirection
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'ProgressCircle.tga')
      .SetRadius(1.94)
      .SetThickness(0.4)
      .Offset(0, 0, 0.05)
      .SetLinearBlend
      .Opacity(0.7);

    TSoundComponent.CreateGrouped(Entity, [2, 6, 8], 'event:/env/building/lane_node/capture_loop')
      .IsLoop
      .TriggerOnFire()
      .StopGroup([8])
      .StopOnFire()
      .StopOnFree;
    TSoundComponent.CreateGrouped(Entity, [4, 5], 'event:/env/building/lane_node/capture_success')
      .TriggerOnFire();
  {$ENDIF}
end;

