{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged, upSupporter]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}53.0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}53.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 5);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 5);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\White\PriestProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}18.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 450);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1333);

  // Heal-Ability
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 5);
  Entity.Blackboard.SetValue(eiWelaRange, [2], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtFlatHeal, dtOverheal]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 100.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 2000);

  // Mana-Reg
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [4], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'EnchantmentArmor')
      .Keyword('Enchanted')
      .Keyword('Overheal')
      .PassInteger('energy_cost', 5, 'energy')
      .PassInteger('heal_amount', 100, 'health')
      .PassInteger('armor_increase', 1, 'armor');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 6);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0.3), RVector3.Create(0, 2.0, 0.4), 0.7);

    TMeshComponent.CreateGrouped(Entity, [0, 1, 2], 'Units\White\Priest' + Entity.SkinFileSuffix + '\Priest.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 60)
      .CreateNewAnimation(ANIMATION_WALK, 162, 200)
      .CreateNewAnimation(ANIMATION_ABILITY_1, 61, 120)
      .CreateNewAnimation(ANIMATION_ATTACK, 121, 160)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'PriestSpine4')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'PriestPalmWeapon')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'PriestPalmWeaponBone001')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_HEAD, 'PriestHead');

    TMeshEffectMetal.Create().AssignToEntity(Entity);

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2])
      .AbilityGroup([2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.4], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TBrainApproachComponent.CreateGrouped(Entity, [3]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [3])
      .SetTargetTeamConstraint(tcAllies);

    // Heal
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2, 3])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcAllies);
    TWelaEfficiencyMissingHealthComponent.CreateGrouped(Entity, [2]);
    TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [2, 3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 3])
      .MustHave([upUnit, upInjured])
      .MustNotHave([upInvisible, upBanished, upUnhealable, upBlessedArmor]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyHealComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('HealingLight')
      .Name('FlatHeal')
      .TriggerOnFire;
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [2])
      .SetCheckGroup([])
      .CheckNotFull(reMana)
      .SetsActive()
      .SetActivationGroup([4]);

    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

    // Ranged attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    // regenerate mana over time
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [4])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [4], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [4])
      .SetResourceType(reMana)
      .TargetGroup([]);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [4])
      .SetCheckGroup([])
      .TriggerOnReachResourceCap(reMana);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\BlessingArmor.dws');

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/priest/attack_fire')
      .TriggerOnFire()
      .StopOnFree;

    TOrienterTargetComponent.CreateGrouped(Entity, [2]);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\priest_heal.pfx', 1.0)
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\priest_heal_impact.pfx', 1.0)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1])
      .FixedOrientationDefault;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/white/unit/priest/heal')
      .TriggerOnFire()
      .StopOnFree;
  {$ENDIF}
end;

