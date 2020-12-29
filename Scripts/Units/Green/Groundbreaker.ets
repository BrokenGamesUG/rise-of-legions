{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upMelee]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}345.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}345.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}150.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 500);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1500);

  // Relentless: Root
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 1.5); // 150% damage against state effect
  Entity.Blackboard.SetValue(eiWelaModifier, [3], 2.0); // 200% damage against rooted

  // Powerful Debut: Rupture
  Entity.Blackboard.SetValue(eiWelaRange, [4, 5], 1.0);

  Entity.Blackboard.SetValue(eiDamageType, [5], [dtSplash, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [5], 3.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 120.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [5], 133);
  Entity.Blackboard.SetValue(eiWelaActionduration, [5], 1233);

  // Evasion 40%
  Entity.Blackboard.SetValue(eiWelaModifier, [6], 0.40);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Haste')
      .Keyword('SummoningSickness');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2, 3], 'RelentlessRooted')
      .Keyword('Rooted')
      .Keyword('StateEffect')
      .PassPercentage('primary_damage_amount_percentage', 200, 'damage')
      .PassPercentage('secondary_damage_amount_percentage', 150, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'DebutRupture')
      .PassInteger('damage_amount', 120, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [6], 'Evasion')
      .PassPercentage('evasion_percentage', 40);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 7);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.8,0), 0.8);

    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Green\Groundbreaker\Groundbreaker.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 103, 162)
      .CreateNewAnimation(ANIMATION_WALK, 37, 57)
      .CreateNewAnimation(ANIMATION_ATTACK, 58, 102)
      .CreateNewAnimation('break_out', 0, 36)
      .CreateNewAnimation('dig_in', 164, 194)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'GroundbreakerChest')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'GroundbreakerMFinger1')
      .BindZoneToBone(BIND_ZONE_HEAD, 'GroundbreakerHead')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'GroundbreakerMFinger1')
      .VisibleWithUnitPropertyMustNotHave([upBurrowed]);

    TMeshComponent.CreateGrouped(Entity, [5], 'Units\Green\Groundbreaker\GroundbreakerEffect.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 48)
      .CreateNewAnimation(ANIMATION_WALK, 0, 48)
      .IgnoreScalingForAnimations;

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.9], [0, 5]);
    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
  {$ENDIF}

  TUnitPropertyComponent.CreateGrouped(Entity, [5], [upInvincible, upBurrowed]);
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    // Digging Approach
    TBrainApproachComponent.CreateGrouped(Entity, [4]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [4])
      .SetTargetTeamConstraint(tcEnemies);

    // Powerful Debut : Rupture
    TBrainWelaFightComponent.CreateGrouped(Entity, [5])
      .Preemptive;
    TAutoBrainOnUnitPropertyComponent.CreateGrouped(Entity, [5])
      .TriggerOn([upFlying]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [5])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [4, 5], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4, 5])
      .MustHave([upGround])
      .MustNotHave([upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [4, 5]);
    TWelaEffectRedirecterComponent.CreateGrouped(Entity, [5])
      .RedirectToGround;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [5]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [5])
      .Name('DebutRupture')
      .Name('Splash')
      .TriggerOnKillDone
      .TriggerOnFire;
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [5])
      .TargetGroup([4, 5]);

    // Melee Approach
    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

    // melee
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
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;

    // extra damage
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [1])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([2]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHaveAny([upFrozen, upStunned, upBlinded, upGrounded, upLifted, upBleeding, upPetrified])
      .MustNotHave([upRooted]);
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [1])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustHave([upRooted]);

    TBuffTakenDamageMultiplierComponent.CreateGrouped(Entity, [6])
      .DodgeDamage()
      .DamageTypeMustNotHave([dtSpell, dtDot, dtSplash]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [6])
      .Name('Evade')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [6])
      .Name('EvadedThreeTimes')
      .CheckNth(3)
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/unit/groundbreaker/spawn')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\groundbreaker_spawn.pfx', 0.9)
       .ActivateOnCreate()
       .FixedOrientationDefault();

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/groundbreaker/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [5], 'event:/card/green/unit/groundbreaker/break_in_fire')
      .TriggerOnPreFire();

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\Green\groundbreaker_break.pfx', 2.0)
       .ActivateOnFire()
       .ScaleWith(eiWelaAreaOfEffect)
       .FixedOrientationDefault();

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\Green\green_border_wide_once.pfx', 5.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TAnimatorComponent.CreateGrouped(Entity, [5])
      .Duration(200)
      .PositionKeypointsY([-5.0, 0.2, 0.0])
      .PositionTimes([0, 160, 200])
      .SizeKeypoints([0, 1.2, 1.0])
      .SizeTimes([0, 160, 200]);

    TAnimatorComponent.CreateGrouped(Entity, [0, 5])
      .Duration(1000)
      .ActivateOnFire
      .PlayAnimation(0, 'break_out', 0);

    TCameraShakerComponent.CreateGrouped(Entity, [5])
      .PresetRotationMedium
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [5])
      .PresetVectorMedium
      .ActivateOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [6], '\Green\dodge.pfx', 1.5)
      .ActivateOnFire();
  {$ENDIF}
end;
