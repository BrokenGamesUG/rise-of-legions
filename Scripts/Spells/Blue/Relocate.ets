{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], 5.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0, 1], 6);

  Entity.Blackboard.SetValue(eiCooldown, [2], 2000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  // permanent
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [10]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [10])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upBase, upSpellImmune]);

  // temporary
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [11])
    .MustNotHave([upImmuneToRelocate]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [0])
    .GroupA([10])
    .GroupB([11])
    .OperatorAnd;

  {$IFDEF CLIENT}
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0])
      .Valid([10])
      .Invalid([11]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseOnceComponent.CreateGrouped(Entity, [0]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcAllies);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [0])
      .Prioritize([upBuilding]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);

    TThinkImpulseOnceComponent.CreateGrouped(Entity, [1]);
    TBrainWelaSavedTargetComponent.CreateGrouped(Entity, [1])
      .FireAtIndex(1);

    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [2]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [2]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [2]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Spells\Blue\Relocate.dws')
    .PassSavedTargetPosition(1)
    .OverrideLastParameterGroup([])
    .PassOffsetToOwner;

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Stopped.dws')
    .PassIntValue(600);

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/blue/spell/relocate/cast')
      .TriggerOnCreate;

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/blue/spell/relocate/cast_with_targets')
      .TriggerOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\relocate_cast.pfx', 5.0)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedHeightGround;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\relocate_cast_finish.pfx', 5.0)
      .Delay(466)
      .ActivateOnFire
      .ActivateAtFireTarget
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedHeightGround;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\blue_border_wide_once.pfx', 5.0)
      .Delay(500)
      .ActivateOnFire
      .ActivateAtFireTarget
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\blue_border_wide_once.pfx', 5.0)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
