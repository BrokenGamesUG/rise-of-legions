{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [0], 2.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 8);

  Entity.Blackboard.SetValue(eiWelaRange, [1], 5.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 14);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  // stun
  // permanent
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [10])
    .MustHave([upUnit])
    .MustNotHave([upLegendary, upSpellImmune]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [10]);

  // temporary
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [11])
    .MustNotHave([upImmuneToStateEffects]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [0])
    .GroupA([10])
    .GroupB([11])
    .OperatorAnd;

  // blind
  // permanent
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [12])
    .MustHave([upUnit])
    .MustNotHave([upLegendary, upNoAutoAttack]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [12]);

  // temporary
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [13])
    .MustNotHave([upImmuneToStateEffects, upImmuneToBlinded]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [1])
    .GroupA([12])
    .GroupB([13])
    .OperatorAnd;

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGeneric.png');
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [1])
      .Valid([12])
      .Invalid([13]);
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0])
      .Valid([10])
      .Invalid([11]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseOnceComponent.CreateGrouped(Entity, []);

    // stun
    TBrainWelaFightComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Stun')
      .TriggerOnFire;

    // blind
    TBrainWelaFightComponent.CreateGrouped(Entity, [1]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Blind')
      .TriggerOnFire;

    TBrainWelaTargetlessComponent.CreateGrouped(Entity, [3]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [3]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Stun.dws');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [1], 'Modifiers\Blind.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/white/spell/light_pulse/cast')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\light_pulse_cast.pfx', 6.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationMedium
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorMedium
      .ActivateOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\white_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
