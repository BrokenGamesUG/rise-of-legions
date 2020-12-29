{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [], 4.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [], 12);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  // permanent
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [10])
    .MustHave([upUnit])
    .MustNotHave([upLegendary, upSpellImmune]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [10]);

  // temporary
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [11], eiDamageable);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [11])
    .MustNotHave([upFrozen, upImmuneToStateEffects, upImmuneToFrozen]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [])
    .GroupA([10])
    .GroupB([11])
    .OperatorAnd;

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [])
      .Valid([10])
      .Invalid([11]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseOnceComponent.CreateGrouped(Entity, []);
    TBrainWelaFightComponent.CreateGrouped(Entity, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('Frozen')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('FrozenRanged')
      .CheckUnitPropertyMustHave([upRanged])
      .TriggerOnFire;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, []);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\Frozen.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/spell/freeze/cast')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Black\freeze_cast.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Black\black_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
