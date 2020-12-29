{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upRangedGroundOnly, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}240.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}240.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 4);

  // Ranged-Attack (only Ground, see below)
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 4);
  Entity.Blackboard.SetValue(eiWelaRange, [1, 2], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Projectiles\White\HeavyGunnerProjectile');
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\White\HeavyGunnerInfusedProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1, 2], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1, 2], [dtRanged, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1, 2], {@UBL_Damage}60.0);
  // with Splash
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 2.5);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [2], 3.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1, 2], 300);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1, 2], 1166);

  // mana infusion - healed
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 1.0);

  // mana infusion - blessed
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 100.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4, 5], 'EnergyInfusion')
      .Keyword('Enchanted')
      .PassInteger('energy_per_health', 1, 'energy')
      .PassInteger('health_amount', 50, 'health')
      .PassInteger('energy_on_enchant', 4, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'Lightgrenades')
      .Keyword('Stunned')
      .Keyword('Blinded')
      .PassInteger('energy_cost', 4, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(-0.1,0,0), RVector3.Create(-0.1,1.2,0), 0.6);

    TMeshComponent.CreateGrouped(Entity, [0, 1, 2], 'Units\White\HeavyGunner\HeavyGunner.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 56, 116)
      .CreateNewAnimation(ANIMATION_WALK, 0, 20)
      .CreateNewAnimation(ANIMATION_ATTACK, 21, 55)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'HeavyGunnerSpine4')
      .BoneSwapXY('HeavyGunnerSpine4')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'HeavyGunnerWeapon_muzzle')
      .BoneSwapXZ(BIND_ZONE_WEAPON)
      .BoneInvertY(BIND_ZONE_WEAPON)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'HeavyGunnerWeapon_muzzle')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_HEAD, 'HeavyGunnerHead')
      .BindTextureToResource(mtGlow, 'HeavyGunnerInfusedGlow.tga', reMana, coGreaterEqual, 4, []);
    TMeshEffectMetal.Create().AssignToEntity(Entity);
    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.2], [0, 1, 2]);
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

    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1, 2], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1, 2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1, 2], eiDamageable);
    // can target only ground
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 2])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 2])
      .MustNotHave([upInvisible, upBanished]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    // healinfusion
    TAutoBrainOnHealedComponent.CreateGrouped(Entity, [4])
      .TimesForEach(50);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [4])
      .SetResourceType(reMana);

    TAutoBrainOnUnitPropertyComponent.CreateGrouped(Entity, [5])
      .TriggerOn([upBlessed]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [5])
      .SetResourceType(reMana);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1, 2], 'event:/card/white/unit/heavy_gunner/attack_fire')
      .TriggerOnFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [1, 2], '\White\heavy_gunner_muzzle_flash.pfx', 1.0)
      .ActivateOnFire()
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);
  {$ENDIF}
end;



