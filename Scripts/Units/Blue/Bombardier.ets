{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.8;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upRanged, upImmuneToBlinded]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}155.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}155.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 4);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 4);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}9.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}3600);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}82.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 18.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 333);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 700);

  // Ranged-Attack with Observer Drone
  Entity.Blackboard.SetValue(eiWelaRange, [2], {@UBL_Range}9.0);
  Entity.Blackboard.SetValue(eiCooldown, [2], {@UBL_Cooldown}3600);
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtRanged, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], {@UBL_Damage}82.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [2], 23.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 333);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 700);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [4], reMana, 4);
  Entity.Blackboard.SetValue(eiWelaRange, [4], 20.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [4], 'Projectiles\Blue\BombardierProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [4], [dtRanged, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 275.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [4], 1033);
  Entity.Blackboard.SetValue(eiWelaActionduration, [4], {1766}3000); // extended so it comboes with ammo factory without moving

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Surefire');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'LAZOR');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'WaveGun')
      .Keyword('Stunned')
      .PassInteger('energy_cost', 4, 'energy')
      .PassInteger('health_threshold', 300, 'health')
      .PassInteger('damage_amount', 275, 'damage');

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 1.1, -0.6), RVector3.Create(0, 0.5, 0.5), 1.2);

    TMeshComponent.CreateGrouped(Entity, [0, 1, 2, 3, 4], 'Units\Blue\Bombardier\Bombardier.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_WALK, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 20)
      .CreateNewAnimation(ANIMATION_ABILITY_1, 21, 73)
      .BindZoneToBone(BIND_ZONE_CENTER, 'BombadierHead')
      .BindZoneToBone(BIND_ZONE_HEAD, 'head')
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.15, -0.20)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BombadierMuzzle')
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE)
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneOffset(BIND_ZONE_WEAPON_MUZZLE, 0, 0, 0.4)
      .BindZoneToBone('exhaust0', 'BombadierExhaust1')
      .BoneInvertY('exhaust0')
      .BoneSwapXY('exhaust0')
      .BoneSwapYZ('exhaust0')
      .BindZoneToBone('exhaust1', 'BombadierExhaust2')
      .BoneInvertY('exhaust1')
      .BoneSwapXY('exhaust1')
      .BoneSwapYZ('exhaust1')
      .BindZoneToBone('exhaust2', 'BombadierExhaust3')
      .BoneSwapXY('exhaust2')
      .BoneSwapYZ('exhaust2')
      .BindZoneToBone('exhaust3', 'BombadierExhaust4')
      .BoneSwapXY('exhaust3')
      .BoneSwapYZ('exhaust3');
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.8], [0]);

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2, 3, 4])
      .AbilityGroup([4]);
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

    // big ranged-attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [4])
      .DisableTargetLock
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [4])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [4])
      .CheckResource(reHealth)
      .Comparator(coGreaterEqual)
      .Reference(300.0)
      .CompareCapToReference();
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [4], eiDamageable);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [4])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [4]);

    // ranged-attack with observer drone
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upRangeAuraBuffed]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [2])
      .LineFromOwner(1.0)
      .SetValidateGroup([3]);
    // ranged-attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1, 2], True);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1, 2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 2])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1, 2, 3], eiDamageable);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1, 2, 3]);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 2, 3])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1])
      .LineFromOwner(1.0)
      .SetValidateGroup([3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upBanished]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana);

    TPositionerRotationComponent.CreateGrouped(Entity, [])
      .Radius(0.05)
      .RotationSpeed(0, 0, 1.6 * PI)
      .Factor(0, 1, 0)
      .Phase(random)
      .FadeIn(1500);

    TParticleEffectComponent.CreateGrouped(Entity, [1, 2, 4], '\Blue\bombardier_muzzle_flash.pfx', 0.6)
      .ActivateOnFire
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\bombardier_laser.pfx', 1.0)
      .ActivateOnFire
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE)
      .IgnoreSize;
    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\bombardier_laser_extended.pfx', 1.0)
      .ActivateOnFire
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE)
      .IgnoreSize;

    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_charge.pfx', 1.0)
      .ActivateOnPreFire
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);
    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust_charge.pfx', 1.0)
      .ActivateOnPreFire
      .BindToSubPosition('exhaust0');
    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust_charge.pfx', 1.0)
      .ActivateOnPreFire
      .BindToSubPosition('exhaust1');
    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust_charge.pfx', 1.0)
      .ActivateOnPreFire
      .BindToSubPosition('exhaust2');
    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust_charge.pfx', 1.0)
      .ActivateOnPreFire
      .BindToSubPosition('exhaust3');

    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust.pfx', 1.0)
      .ActivateOnFire
      .BindToSubPosition('exhaust0');
    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust.pfx', 1.0)
      .ActivateOnFire
      .BindToSubPosition('exhaust1');
    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust.pfx', 1.0)
      .ActivateOnFire
      .BindToSubPosition('exhaust2');
    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\bombardier_exhaust.pfx', 1.0)
      .ActivateOnFire
      .BindToSubPosition('exhaust3');

    TSoundComponent.CreateGrouped(Entity, [1, 2], 'event:/card/blue/unit/bombardier/attack_fire')
      .TriggerOnPreFire;

    TSoundComponent.CreateGrouped(Entity, [4], 'event:/card/blue/unit/bombardier/wavegun_fire')
      .TriggerOnPreFire;

    TCameraShakerComponent.CreateGrouped(Entity, [4])
      .PresetRotationStrong
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [4])
      .PresetVectorStrong
      .ActivateOnFire;
  {$ENDIF}
end;
