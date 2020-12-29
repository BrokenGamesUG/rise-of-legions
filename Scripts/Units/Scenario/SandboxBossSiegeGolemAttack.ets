{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, False);
  Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHasDeathEffect, False);
  Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIcon, 'MinimapBossIcon.png');
  Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIconSize, 3.0);
  Entity.CollisionRadius := 2.55;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upFlying, upBuilding, upGround, upLegendary, upNexus, upUnhealable, upBase, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, 1200.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, 1200.0);

  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 4 * 60);

  // Charged-Nexus-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], 9999999.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Colorless\BossSiegeGolemAttackProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtIgnoreArmor, dtTrue]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 0.041667);
  Entity.Blackboard.SetValue(eiCooldown, [1], 5000);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 933);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1833);

  // Charge
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 1.0);

  // Charge-Cap increase on tower destroy
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 3.0 * 60.0);

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
    TTooltipUnitAbilityComponent.Create(Entity, 'PrimaryTarget');
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,3.72,0), 1.86);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Scenario\AttackBoss\AttackBoss.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 60)
      .CreateNewAnimation(ANIMATION_ATTACK, 118, 172)
      .BindZoneToBone(BIND_ZONE_CENTER, 'MeleeGolemTowerPelvis');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.7], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, False);

  {$IFDEF SERVER}
    TServerPrimaryTargetComponent.Create(Entity);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/siege_golem/crystal_artillery_fire')
      .TriggerOnFire();

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Neutral\NexusDie5.pfx', 1.0)
      .ActivateOnDie()
      .IgnoreModelSize
      .FixedOrientationDefault
      .SetModelOffset(RVector3.Create(0, 3, 0));

    TMeshEffectComponent.CreateGrouped(Entity, [0])
      .ActivateOnDie
      .SetEffect(
        TMeshEffectGlow.Create(10000)
          .AddKey(0, 0)
          .AddKey(2800, 0.5)
          .AddKey(3100, 1)
          .AddKey(3201, 0)
          .AddKey(10000, 0)
      );

    TAnimatorComponent.CreateGrouped(Entity, [0])
      .Duration(30000)
      .ActivateOnDie
      .HideAfter(3150);

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0.005, 0.005, 0.02)
      .Duration(1000)
      .Waves(24)
      .ActivateOnDie()
      .Delay(3200);

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.3)
      .Duration(1000)
      .Waves(16)
      .ActivateOnDie()
      .Delay(3200);

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0.001, 0.001, 0.005)
      .Duration(3200)
      .Waves(24)
      .Invert
      .ActivateOnDie();

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.1)
      .Duration(3200)
      .Waves(16)
      .Invert
      .ActivateOnDie();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/env/building/nexus/destroy')
      .TriggerOnDie();

    TOrienterTargetComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}
end;








