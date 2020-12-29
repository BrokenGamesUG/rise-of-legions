{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.85;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upRangedGroundOnly, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}495.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}495.0);

  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 4);

  // Close-Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], {@UBL_Range}3.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}89.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 666);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1366);

  // root braid
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [2], 11.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Green\RootdudeRootBraidProjectile');

  // root braid charge
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 100.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3, 4], 'EnergyInfusion')
      .Keyword('Enchanted')
      .PassInteger('energy_per_health', 1, 'energy')
      .PassInteger('health_amount', 50, 'health')
      .PassInteger('energy_on_enchant', 4, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'RootBraid')
      .Keyword('Rooted')
      .PassInteger('energy_cost', 1, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.7,0), 1.1);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Rootdude\Rootdude.xml')
      .CreateNewAnimation(ANIMATION_WALK, 61, 84)
      .CreateNewAnimation(ANIMATION_ATTACK, 86, 126)
      .CreateNewAnimation(ANIMATION_STAND, 0, 59)
      .SetAnimationSpeed(ANIMATION_WALK, 1.0)
      .BindZoneToBone(BIND_ZONE_CENTER, 'RootDudeSpine2')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'RootDudeArm9')
      .IgnoreScalingForAnimations;

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.2], [0]);
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
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);

    // Root braid
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .DisableTargetLock;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEfficiencyDamageTypeComponent.CreateGrouped(Entity, [2])
      .Prioritize([dtMelee]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .PrioritizeMostDistant
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit, upGround])
      .MustNotHave([upLegendary, upImmuneToRooted, upImmuneToStateEffects]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Rootbraid')
      .TriggerOnFire;

    // each heal adds a mana
    TAutoBrainOnHealedComponent.CreateGrouped(Entity, [3])
      .TimesForEach(50);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reMana);

    TAutoBrainOnUnitPropertyComponent.CreateGrouped(Entity, [4])
      .TriggerOn([upBlessed]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [4])
      .SetResourceType(reMana);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/rootdude/attack_fire')
      .TriggerOnPreFire
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/green/unit/rootdude/braid_fire')
      .TriggerOnFire;
  {$ENDIF}
end;
