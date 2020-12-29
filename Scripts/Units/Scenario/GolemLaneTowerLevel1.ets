{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, False);
  Entity.CollisionRadius := 0.95;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upMonumental, upLanetower, upTier1, upFlying, upGround, upRanged, upBuilding, upBase, upGolem]);

  Entity.Blackboard.SetValue(eiArmorType, [], atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, 600.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, 600.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 15);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 5);

  // Ranged-Attack
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reMana, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], 16.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Colorless\GolemLaneTowerLevel1Projectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], 1000);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtTrue, dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 32.0);

  // Ammo-Recharge
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [5], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Monumental');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Ammo')
      .PassInteger('energy_cost', 1, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 7);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0), RVector3.Create(0, 4.4, 0), 1.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\GolemLaneTowerLevel1\GolemLaneTowerLevel1.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 1, 100)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BoneC2')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneC2')
      .BindZoneToBone(BIND_ZONE_HIT_ZONE_AIR, 'BoneC2')
      .SetModelOffset(0, -0.4, 0);

    Entity.Eventbus.WriteGrouped(eiModelSize, [3.4], [0, 1]);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Colorless\SharedCrystalShards\SharedCrystalShards.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneC1')
      .FixedOrientationDefault
      .BindToSubPositionGroup('BoneC2', [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystalNeutral.png')
      );

    Entity.Eventbus.WriteGrouped(eiModelSize, [3.0], [2]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, False);

  {$IFDEF SERVER}
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaReadyCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
        .SetPayingGroupForType(reMana, []);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    TAutoBrainOnDeathComponent.CreateGrouped(Entity, [3]);
    TWelaEffectGameEventComponent.CreateGrouped(Entity, [3])
      .Event('GolemTower_Destroyed');

    // Ammo-Charge
    TWelaHelperInitActiveAfterGameStartComponent.CreateGrouped(Entity, [5]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [5])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [5], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [5])
      .SetResourceType(reMana);
  {$ENDIF}

  TGameEventEnumeratorComponent.CreateGrouped(Entity, [3])
      .Event('GolemTower_Destroyed');

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\golem_lane_tower_level1_attack.pfx', 8.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [2]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/building/golem_lane_tower_level1/attack_fire')
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/env/building/lane_tower/death')
      .TriggerOnDie();
  {$ENDIF}
end;


