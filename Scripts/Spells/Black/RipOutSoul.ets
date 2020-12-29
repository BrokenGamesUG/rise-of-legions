{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiCooldown, [0], 500);

  Entity.Blackboard.SetValue(eiWelaRange, [0], 5.5);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 20);
  Entity.Blackboard.SetValue(eiWelaDamage, [0], 0.30); // 30% of Max-Health
  Entity.Blackboard.SetValue(eiDamageType, [0], [dtSpell, dtSplash]);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  // permanent
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [10])
    .MustHave([upUnit])
    .MustNotHave([upLegendary, upSpellImmune]);

  // temporary
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [11], eiDamageable);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [11])
    .MustNotHave([upImmuneToBanished, upImmuneToStateEffects]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [0])
    .GroupA([10])
    .GroupB([11])
    .OperatorAnd;

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0])
      .Valid([10])
      .Invalid([11]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    // delay spell by a short moment for effect
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [0, 1, 3]);

    // deal % damage of max health
    TBrainWelaFightComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcAll);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0])
      .PercentageOfMaxHealth();
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('RipOutSoul')
      .TriggerOnFire
      .TriggerOnKillDone
      .TriggerGlobalOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Spell')
      .TriggerOnDamageDone;
    // and banish
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Banished')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('BanishedMelee')
      .CheckUnitPropertyMustHave([upMelee])
      .TriggerOnFire;

    // and kill this spell entity
    TBrainWelaTargetlessComponent.CreateGrouped(Entity, [3]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [3]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Banished.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/spell/rip_out_soul/cast')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Black\rip_out_soul_cast.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .Delay(500)
      .PresetRotationMedium
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .Delay(500)
      .PresetVectorMedium
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Black\rip_out_soul_fire.pfx', 1.0)
      .ActivateOnFire()
      .ActivateAtFireTarget();

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Black\black_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
