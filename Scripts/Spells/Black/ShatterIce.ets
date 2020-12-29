{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [0, 1], 4.0);
  Entity.Blackboard.SetValue(eiDamageType, [0, 1], [dtSpell, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [0], 250.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 800.0);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
    .MustHave([upUnit, upFrozen])
    .MustNotHave([upBanished, upSpellImmune]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
    .MustHave([upBuilding, upFrozen])
    .MustNotHave([upBanished]);

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0]);
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseOnceComponent.CreateGrouped(Entity, []);

    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [0])
      .TargetsGroundAndAir;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('ShatterIce')
      .TriggerOnKillDone
      .TriggerGlobalOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Spell')
      .TriggerOnDamageDone;

    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [1]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1])
      .TargetsGroundAndAir;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('ShatterIce')
      .TriggerOnKillDone
      .TriggerGlobalOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Spell')
      .TriggerOnDamageDone;

    TBrainWelaTargetlessComponent.CreateGrouped(Entity, [2]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [2]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/black/spell/shatter_ice/cast')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Black\shatter_ice_cast.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaAreaOfEffect);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationMedium
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorMedium
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Black\black_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
