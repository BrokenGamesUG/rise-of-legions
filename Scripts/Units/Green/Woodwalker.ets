{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}85.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}85.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 4);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 16);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Projectiles\Green\WoodwalkerProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}99.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 350);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1166);

  // summon 2 saplings
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 4);
  Entity.Blackboard.SetValue(eiWelaRange, [2], 12.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Units\Green\Sapling');
  Entity.Blackboard.SetValue(eiWelaCount, [2], 2);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 800);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 1700);

  // Mana-Reg
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [3], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'SummonSaplings')
      .Keyword('Sapling')
      .Keyword('Timed')
      .PassInteger('energy_cost', 4, 'energy')
      .PassInteger('sapling_amount', 2);

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0.2,0,0.1), RVector3.Create(0.2,2.0,0.1), 0.8);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Woodwalker' + Entity.SkinFileSuffix + '\Woodwalker.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 189, 224)
      .CreateNewAnimation(ANIMATION_ATTACK, 153, 187)
      .CreateNewAnimation(ANIMATION_STAND, 92, 152)
      .CreateNewAnimation(ANIMATION_ABILITY_1, 37, 91)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'WoodwalkerSpine4')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'WoodwalkerLPalm')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'WoodwalkerWeaponEye')
      .BindZoneToBone(BIND_ZONE_HEAD, 'WoodwalkerHead');
    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2])
      .AbilityGroup([2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    // summon saplings
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [2])
      .Blocking();
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [2])
      .SpreadSpawns();
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [2])
      .SetCheckGroup([])
      .CheckNotFull(reMana)
      .SetsActive()
      .SetActivationGroup([3]);

    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

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

    // regenerate mana over time
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [3])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [3], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reMana)
      .TargetGroup([]);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [3])
      .SetCheckGroup([])
      .TriggerOnReachResourceCap(reMana);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .FixedCap(4)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/woodwalker/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Green\woodwalker_summon_sapling.pfx', 3.0)
      .ActivateOnPreFire()
      .DeactivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/green/unit/woodwalker/summon_sapling/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;
