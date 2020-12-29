{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 200);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 16.5);
  Entity.Blackboard.SetValue(eiCooldown, [1], 250);

  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    //TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
    //  .SetTexture('SpelltargetShootingRange.png')
    //  .IsPermanent;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TPositionComponent.Create(Entity);

    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [1]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .ChangeTargetToMyself;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .IgnoreOwnCollisionradius()
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectGameEventComponent.CreateGrouped(Entity, [1])
      .Event('StepTrigger');
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;

