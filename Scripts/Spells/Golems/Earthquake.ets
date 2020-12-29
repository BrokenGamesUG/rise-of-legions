{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upLegendary]);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 6);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 6);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiCooldown, [1], 5000);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 8.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 35.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtSiege, dtSpell, dtSplash]);

  Entity.Blackboard.SetValue(eiWelaRange, [2], 8.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2], 200);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [1]);
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
    .MustNotHave([upBanished, upSpellImmune]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
    .MustHave([upGround]);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
    .MustHave([upUnit, upGround])
    .MustNotHave([upLegendary, upNoAutoAttack, upImmuneToStateEffects]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [2]);

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    // for legendary spawn statistic
    TStatisticsUnitComponent.Create(Entity);

    // damage field - damage tick every 5s
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [1, 2, 3])
      .TimerIsReady;

    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [1]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroup([]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroup([]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Earthquake')
      .TriggerOnFire
      .TriggerOnKillDone
      .TriggerGlobalOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Spell')
      .TriggerOnDamageDone;

    // stun
    TBrainWelaFightComponent.CreateGrouped(Entity, [2]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Stun')
      .TriggerOnFire;

    // kill after charges are depleted
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [3]);
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [3])
      .ComparedResource(reWelaCharge)
      .CheckEmpty;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [3]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\Stun.dws');

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\earthquake_fire.pfx', 6.0)
      .ActivateOnFire
      .FixedOrientationDefault
      .FixedHeightGround
      .ScaleWith(eiWelaAreaOfEffect);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\earthquake_field.pfx', 6.0)
      .ActivateOnCreate()
      .FixedOrientationDefault
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedHeightGround;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\colorless_border_wide.pfx', 5.0)
      .ActivateOnCreate()
      .PlaceAtSavedTarget()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .PresetVectorStrong
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .PresetRotationStrong
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .VectorShaker(-0.4, -1, 0.2)
      .Strength(0.03)
      .Duration(5000)
      .Waves(80)
      .NoFade
      .ActivateOnFire
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/spell/earthquake/fire')
      .TriggerOnFire();
  {$ENDIF}
end;
