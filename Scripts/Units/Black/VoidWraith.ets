{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.7;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}475.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}475.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 6);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 12);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}5.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Black\VoidWraithProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}86.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 266);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 833);

  // frost nova
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 6);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 200.0);
  Entity.Blackboard.SetValue(eiWelaRange, [2], 7.0);
  Entity.Blackboard.SetValue(eiDamageType, [2], []);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 800);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 1600);
  Entity.Blackboard.SetValue(eiCooldown, [2], 3000);

  Entity.Blackboard.SetValue(eiDamageType, [3], [dtSplash, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 60.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [3], 4.0);

  // Mana-Reg
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [5], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'MercilessFrozen')
      .Keyword('Frozen')
      .Keyword('StateEffect')
      .PassPercentage('primary_damage_amount_percentage', 300, 'damage')
      .PassPercentage('secondary_damage_amount_percentage', 200, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'FrostNova')
      .Keyword('Frozen')
      .PassInteger('energy_cost', 6, 'energy')
      .PassInteger('main_target_damage', 200, 'damage')
      .PassInteger('main_target_splashdamage', 60, 'damage')
      .PassInteger('splash_damage', 60, 'damage')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 3);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, -0.4), RVector3.Create(0, 2.5, -0.2), 0.9);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidWraith\VoidWraith.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 134, 194)
      .CreateNewAnimation(ANIMATION_ATTACK, 109, 133)
      .CreateNewAnimation(ANIMATION_STAND, 0, 60)
      .CreateNewAnimation(ANIMATION_ABILITY_1, 61, 108)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'VoidwraithRPalm');

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2])
      .AbilityGroup([2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.5], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    // frost nova
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Blocking;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], True);
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [2, 3]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2, 3], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .Prioritize([upImmuneToFrozen, upLegendary, upBuilding, upImmuneToStateEffects])
      .Reverse;
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [2])
      .SetCheckGroup([])
      .CheckNotFull(reMana)
      .SetsActive()
      .SetActivationGroup([5]);

    // splash need own values and splash kills should not trigger with spotty damage, so own group
    TWelaEffectFireComponent.CreateGrouped(Entity, [2])
      .TargetGroup([3]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [3]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('Splash')
      .TriggerOnKillDone;

    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [2]);

    TWelaEffectFireComponent.CreateGrouped(Entity, [2])
      .TargetGroup([4]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustHave([upUnit])
      .MustNotHave([upImmuneToFrozen, upLegendary, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('Frozen')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('FrozenRanged')
      .CheckUnitPropertyMustHave([upRanged])
      .TriggerOnFire;

    // ranged-attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], True);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);

    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

    // regenerate mana over time
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [5])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [5], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [5])
      .SetResourceType(reMana)
      .TargetGroup([]);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [5])
      .SetCheckGroup([])
      .TriggerOnReachResourceCap(reMana);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [4], 'Modifiers\Frozen.dws');

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/voidwraith/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/black/unit/voidwraith/ice_nova_cast')
      .TriggerOnFire();

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetRotationMedium
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetVectorMedium
      .ActivateOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Black\voidwraith_frost_nova_cast.pfx', 5.0)
      .ActivateOnFire()
      .ActivateAtFireTarget()
      .ScaleWith(eiWelaAreaOfEffect);

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Black\black_border_wide_once.pfx', 5.0)
      .ActivateOnFire()
      .ActivateAtFireTarget()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
