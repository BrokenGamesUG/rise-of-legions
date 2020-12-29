{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 1.5;

  Entity.Blackboard.SetValue(eiSpeed, [], (4 / 1000));
  Entity.Blackboard.SetValue(eiAttentionrange, [0, 1, 2, 3, 4, 5], 18.0);

  Entity.Blackboard.SetValue(eiUnitProperties, [], [upFlying, upGround, upMonumental, upUnit, upMelee, upLegendary, upTier3, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], atHeavy);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, 4000.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, 4000.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1, 2], 2.5);
  Entity.Blackboard.SetValue(eiDamageType, [1, 2], [dtMelee, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1, 2], 200.0);
  Entity.Blackboard.SetValue(eiCooldown, [1, 2], 3000);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1, 2], 5.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffectCone, [1, 2], 3.141 * 0.9);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 1600);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 2533);

  // Melee-Attack vs Air
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 1166);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 2333);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Monumental');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,4,0), 2.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\BossGolem' + Entity.SkinFileSuffix + '\BossGolem.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 233, 289)
      .CreateNewAnimation(ANIMATION_ATTACK, 81, 156)
      .CreateNewAnimation(ANIMATION_ATTACK2, 157, 232)
      .CreateNewAnimation(ANIMATION_ATTACK_AIR, 290, 359)
      .CreateNewAnimation(ANIMATION_ATTACK_AIR2, 360, 429)
      .CreateNewAnimation(ANIMATION_STAND, 0, 79)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'BossGolemRibcage')
      .BindZoneToBone(BIND_ZONE_HEAD, 'BossGolemHead');

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2])
      .HasAntiAirAttack
      .AlternatingAttack;
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.6], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    // Hold initial position and flee if too far away
    TBrainFleeComponent.CreateGrouped(Entity, [3])
      .Range(30);
    TBrainOverwatchComponent.CreateGrouped(Entity, [3]);

    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 2])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1, 2]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1, 2], eiDamageable);


    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Blocking;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upGround]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upFlying])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Splash')
      .TriggerOnKillDone;

    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1, 2], true);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/boss_golem/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;
