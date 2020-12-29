{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upRangedGroundOnly, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}165.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}165.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 2);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Ground-Only-Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Blue\InductionerProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}110.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 300);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 666);

  // Missile Launcher
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 2);
  Entity.Blackboard.SetValue(eiCooldown, [2], 3000);
  Entity.Blackboard.SetValue(eiWelaRange, [2], 15.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Blue\InductionerMissile');
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtRanged, dtSplash, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 53.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [2], 2.5);

  // Induction Energy
  Entity.Blackboard.SetValue(eiWelaRange, [3], 12.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'MissileLauncher')
      .Keyword('Missile')
      .PassInteger('energy_cost', 2, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'InductionEnergy')
      .PassInteger('energy_amount', 1, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.4,0.2), RVector3.Create(0,0.7,-0.3), 0.9);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\Inductioner\Inductioner.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_WALK, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 19)
      .BindZoneToBone(BIND_ZONE_CENTER, 'InductionerHead')
      .BindZoneToBone(BIND_ZONE_HEAD, 'InductionerHead')
      .BoneInvertY(BIND_ZONE_HEAD)
      .BoneSwapXZ(BIND_ZONE_HEAD)
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.25, 0.25)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'InductionerMuzzle')
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE)
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone('missile_launcher', 'InductionerRocketLauncherMuzzle')
      .BoneInvertY('missile_launcher')
      .BoneSwapXZ('missile_launcher');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.8], [0, 1, 2]);
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

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .ThinksPassivelyIfConscious;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], true);
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies)
      .PicksRandomTargets;
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .Prioritize([upFlying, upMonumental]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    // every projectile costs
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('MissileLauncher')
      .TriggerOnFire;

    TAutoBrainOnCommanderAbilityUsedComponent.CreateGrouped(Entity, [3])
      .ConstraintOnSameTeamID
      .ConstraintOnInWelaRange
      .FireAtSelf;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reMana);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('Induction')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TPositionerRotationComponent.CreateGrouped(Entity, [])
      .Radius(0.05)
      .RotationSpeed(0, 0, 1.8 * PI)
      .Factor(0, 1, 0)
      .Phase(random)
      .FadeIn(1500);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\inductioner_muzzle_flash.pfx', 1.2)
      .ActivateOnFire
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/blue/unit/inductioner/attack_fire')
      .TriggerOnFire;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/blue/unit/inductioner/missile_fire')
      .TriggerOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Blue\induction_energy.pfx', 1.2)
      .ActivateOnFire
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [3], 'event:/card/blue/unit/inductioner/induction_energy_fire')
      .TriggerOnFire;
  {$ENDIF}
end;



