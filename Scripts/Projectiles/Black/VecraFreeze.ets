{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [0], 8.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 200);

  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 8.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 1000.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtSpell, dtSplash]);
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
    TThinkImpulseOnceComponent.CreateGrouped(Entity, [1]);

    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upUnit, upFrozen])
      .MustNotHave([upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [1]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1])
      .TargetsGroundAndAir;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;

    TThinkImpulseOnceComponent.CreateGrouped(Entity, [0]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustHave([upUnit])
      .MustNotHave([upFrozen, upImmuneToFrozen, upLegendary, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Frozen')
      .Name('IcyPrison')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('FrozenRanged')
      .CheckUnitPropertyMustHave([upRanged])
      .TriggerOnFire;

    TWelaEffectSuicideComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Frozen.dws');

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Black\vecra' + Entity.SkinFileSuffix + '_freeze.pfx', 7.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Black\black_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationStrong
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorStrong
      .ActivateOnFree;
  {$ENDIF}
end;
