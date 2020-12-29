{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upNoAutoAttack, upSupporter]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}60.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}60.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 3);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 3);

  // wait if enemy is near in 10 range
  Entity.Blackboard.SetValue(eiAttentionrange, [0], 10.0);

  // Blessing Strength
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2, 4], reMana, 3);
  Entity.Blackboard.SetValue(eiWelaRange, [2, 4], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Green\HeartOfTheForestProjectile');
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2], 1);
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtIrredirectable]);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 800);

  // Mana-Reg
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [5], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Pacifist');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'EnchantmentStrength')
      .Keyword('Enchanted')
      .PassInteger('energy_cost', 3, 'energy')
      .PassInteger('health_bonus', 40, 'health')
      .PassInteger('damage_bonus', 8, 'damage')
      .PassInteger('damage_bonus_surefire', 5, 'damage');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 6);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.4,0), 0.65);

    TMeshComponent.CreateGrouped(Entity, [0, 1, 2, 3], 'Units\Green\HeartOfTheForest\HeartOfTheForest.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 16)
      .CreateNewAnimation(ANIMATION_ATTACK, 18, 41)
      .CreateNewAnimation(ANIMATION_STAND, 43, 102)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'HOTFHead1')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'HOTFHead3')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'HOTFHead3')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneSwapYZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_HEAD, 'HOTFHead3');
    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TBrainApproachComponent.CreateGrouped(Entity, [4]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [4])
      .SetTargetTeamConstraint(tcAllies);

    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2, 4])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2, 4])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [2, 4]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [2, 4]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 4])
      .MustHave([upUnit])
      .MustNotHave([upBlessedStrength, upInvisible, upBanished]);

    // apply buff to surrounding allied units
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .DisableTargetLock()
      .Blocking;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcAllies);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [2])
      .SetCheckGroup([])
      .CheckNotFull(reMana)
      .SetsActive()
      .SetActivationGroup([5]);

    TBrainWaitComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upInvisible]);

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

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\BlessingStrengthIncoming.dws');

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .FixedCap(3)
      .ShowResource(reMana)
      .HideIfEmpty;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Green\heart_of_the_forest_attack.pfx', 1.2)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/green/unit/heart_of_the_forest/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;
