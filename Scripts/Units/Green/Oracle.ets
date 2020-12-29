{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.9;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upMelee]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}610.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}610.0);

  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 12);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaChargeCapacity, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaChargeCapacity, 12);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], 1.5);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}87.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}3600);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 2.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 533);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1166);

  // Sapling-Health-Boost
  Entity.Blackboard.SetValue(eiCooldown, [2], 500);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 60.0);
  Entity.Blackboard.SetValue(eiWelaRange, [2], 6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Green\OracleSaplingProjectile');

  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'BarkBoost')
      .Keyword('Sapling')
      .PassInteger('health_amount', 60, 'health')
      .PassInteger('absorb_cap', 12)
      .PassInteger('cooldown', 3);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);

    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, -0.5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0.2,0,0), RVector3.Create(0.2,1.0,0), 1.0);

   TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Oracle' + Entity.SkinFileSuffix + '\Oracle.xml')
      .CreateNewAnimation(ANIMATION_WALK, 0, 25)
      .CreateNewAnimation(ANIMATION_ATTACK, 26, 60)
      .CreateNewAnimation(ANIMATION_STAND, 61, 121)
      .BindZoneToBone(BIND_ZONE_CENTER, 'Base HumanSpine4')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'Base HumanRPalm')
      .BoneOffset(BIND_ZONE_WEAPON, 0.2, 0, 0)
      .BindZoneToBone(BIND_ZONE_HEAD, 'Base HumanRibcageBone002');

    if Entity.SkinID = SKIN_GROUP_CRUSADER then
    begin
      TMeshEffectMetal.Create()
        .ShowAsColor(ecWhite)
        .AssignToEntity(Entity);
    end;

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

    // health-boost with saplings, sacrifice sapling, shoot projectile from sapling to self
    TBrainWelaFightComponent.CreateGrouped(Entity, [2, 3]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], True);
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [2])
      .ComparedResource(reWelaChargeCapacity)
      .CheckNotFull();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiIsAlive);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upSapling]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2])
      .Reverse;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2, 3]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [2])
      .Sacrifice;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('BarkBoost')
      .TriggerOnFire;
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reWelaChargeCapacity)
      .RedirectToSelf;

    // Auto-Attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .GradientTop($FFA38871)
      .GradientBottom($FF3B352F)
      .ShowResource(reWelaChargeCapacity)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/oracle/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Green\oracle_attack_impact.pfx', 7.0)
      .ActivateOnFire()
      .ScaleWith(eiWelaAreaOfEffect)
      .SetModelOffset(RVector3.Create(0, 0, 2.0));

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .PresetVectorLight
      .ActivateOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Green\green_border_wide_once.pfx', 5.0)
      .ActivateOnFire
      .ActivateAtFireTarget
      .FixedOrientationDefault
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
