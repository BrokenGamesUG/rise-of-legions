{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.8;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upMelee, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atHeavy);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}505.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}505.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}100.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 466);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1000);

  // Splinter
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 35.0);
  Entity.Blackboard.SetValue(eiCooldown, [2], 3000);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [3], 'Projectiles\Colorless\SplinterProjectile');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'Splinter')
      .PassInteger('damage_threshold', 35, 'damage')
      .PassInteger('cooldown', 3);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0.1), RVector3.Create(0, 1.4, 0.1), 1.3);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\BigMeleeGolem\BigMeleeGolem.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 34)
      .CreateNewAnimation(ANIMATION_ATTACK, 97, 126)
      .CreateNewAnimation(ANIMATION_STAND, 36, 95)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BigMeleeGolemRPalm')
      .BoneOffset(BIND_ZONE_WEAPON, 0.2, 0.2, 0)
      .BindZoneToBone(BIND_ZONE_HEAD, 'BigMeleeGolemHead')
      .BindZoneToBone(BIND_ZONE_CENTER, 'BigMeleeGolemRibcage');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.53], [0]);
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

    // Melee-Attack
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

    // Splinter
    TAutoBrainOnTakeDamageComponent.CreateGrouped(Entity, [2])
      .FireSelfInGroup([2])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], True);
    TWelaTriggerCheckTakeDamageThresholdComponent.CreateGrouped(Entity, [2]);
    TWelaEffectFireComponent.CreateGrouped(Entity, [2])
      .TargetGroup([3])
      .RedirectToGround
      .RandomizeGroundtarget(3.0, 4.0);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [3]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('Splinter')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/big_melee_golem/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/colorless/unit/big_melee_golem/splinter_trigger')
      .TriggerOnFire();
  {$ENDIF}
end;








