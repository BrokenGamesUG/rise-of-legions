{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 100);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 4);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiCooldown, [1], 500);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 4.5);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 16.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtSpell, dtSplash]);

  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [1]);
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
    .MustNotHave([upBanished, upSpellImmune]);

  // one charge for every archer in range
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);
  Entity.Blackboard.SetValue(eiWelaRange, [3], 18.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [3], 100);

  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [3]);
  TWelaTargetConstraintCardNameComponent.CreateGrouped(Entity, [3])
    .AddCard('Archer');
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [1]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [3])
      .SetTexture('SpelltargetGeneric.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [3]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    // damage field - damage tick every 0.5s
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [1, 2]);

    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [1]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroup([]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroup([]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1])
      .TargetsGroundAndAir;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Spell')
      .TriggerOnDamageDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('HailOfArrows')
      .TriggerOnFire
      .TriggerOnKillDone
      .TriggerGlobalOnKillDone;

    // kill after charges are depleted
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [2]);
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [2])
      .ComparedResource(reWelaCharge)
      .CheckEmpty;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [2]);

    // gain one charge for each archer in range
    TThinkImpulseOnceComponent.CreateGrouped(Entity, [3, 4]);
    TBrainWelaFightComponent.CreateGrouped(Entity, [3])
      .ChangeTargetToMyself();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3, 4])
      .SetTargetTeamConstraint(tcAllies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reWelaCharge)
      .TargetGroup([]);

    // trigger effect on archers
    TBrainWelaFightComponent.CreateGrouped(Entity, [4]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\white_border.pfx', 5.0)
      .ActivateOnCreate()
      .PlaceAtSavedTarget()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\hail_of_arrows_tick.pfx', 5.0)
      .ActivateOnFire()
      .PlaceAtSavedTarget()
      .FixedOrientation(-1, 0, 0)
      .ScaleWith(eiWelaAreaOfEffect);

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .Delay(250)
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .Delay(250)
      .PresetVectorLight
      .ActivateOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [4], '\White\hail_of_arrows_archer_support.pfx', 2.0)
      .ActivateOnFire()
      .ActivateAtFireTarget()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/spell/hail_of_arrows/cast')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/spell/hail_of_arrows/attack_impact')
      .TriggerOnFire();
  {$ENDIF}
end;
