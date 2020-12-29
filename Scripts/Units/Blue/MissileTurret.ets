{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upGround, upBuilding, upRanged, upGadget]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}260.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}260.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 14);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 14);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reMana, 2);
  Entity.Blackboard.SetValue(eiWelaRange, [1], {@UBL_Range}15.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Blue\MissileTowerMissile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}47.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 2.5);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 233);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 766);

  // limited
  Entity.Blackboard.SetValue(eiWelaDamage, [2, 3], 1.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'LimitedGadget')
      .PassInteger('gadget_limit', 5)
      .PassInteger('gadget_limit_exceeded', 6);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Ammo2')
      .PassInteger('energy_cost', 2, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'AntiAir')
      .PassPercentage('primary_damage_amount_percentage', 200, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1,0), 0.9);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\MissileTurret' + Entity.SkinFileSuffix + '\MissileTurret.xml')
      .ApplyLegacySizeFactor
      .BindZoneToBone(BIND_ZONE_HEAD, 'head')
      .BoneOffset(BIND_ZONE_HEAD, 0, 0, 0.25)
      .CreateNewAnimation(ANIMATION_ATTACK, 22, 44)
      .CreateNewAnimation(ANIMATION_ATTACK2, 44, 66)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE + '0', 'CATRigHubMissileLeft')
      .BoneSwapYZ(BIND_ZONE_WEAPON_MUZZLE + '0')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE + '1', 'CATRigHubMissileRight')
      .BoneSwapYZ(BIND_ZONE_WEAPON_MUZZLE + '1')
      .AlternatingZone(BIND_ZONE_WEAPON_MUZZLE, 2)
      .BindZoneToBone('exhaust0', 'CATRigHubExhaustRight')
      .BoneSwapXY('exhaust0')
      .BindZoneToBone('exhaust1', 'CATRigHubExhaustLeft')
      .BoneSwapXY('exhaust1')
      .AlternatingZone('exhaust', 2);
    TMeshComponent.CreateGrouped(Entity, [3], 'Units\Blue\TurretBase\TurretBase.xml')
      .ApplyLegacySizeFactor
      .FixedOrientationDefault;

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.0], [0, 1, 2, 3]);
    TAnimationComponent.CreateGrouped(Entity, [1])
      .AlternatingAttack;

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .ShowWeaponRange
      .SetTexture('SpelltargetShootingRangeMissile.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);

  {$IFDEF SERVER}
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reMana, []);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .Prioritize([upFlying, upMonumental]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
    // every projectile costs
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('AmmoEmpty')
      .CheckResourceEmpty(reMana)
      .TriggerOnFire;

    // take a gadget slot in commander on creation
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [2])
      .FireAtCommander;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [2])
      .SetResourceType(reGadgetCount);
    // release a gadget slot in commander on death
    TAutoBrainOnDeathComponent.CreateGrouped(Entity, [3])
      .FireAtCommander
      .ThinksPassively
      .ThinksInExile;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reGadgetCount)
      .SetFactor(-1.0);
  {$ENDIF}

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\missile' + Entity.SkinFileSuffix + '_turret_exhaust.pfx', 2.0)
      .ActivateOnFire()
      .BindToSubPositionGroup('exhaust', [1]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/blue/unit/missile_turret/attack_fire')
      .TriggerOnFire();

    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana);

    TOrienterTargetComponent.CreateGrouped(Entity, [1])
      .KeepLastFront;
    //TOrienterSmoothRotateComponent.CreateGrouped(Entity, [1])
    //  .SetAngleSpeed(0.002);
  {$ENDIF}
end;
