{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, False);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upGround, upBuilding, upMelee, upGolem]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}655.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}655.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}150.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 666);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1033);

  Entity.Blackboard.SetValue(eiWelaRange, [1, 2], 0.5 + {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiCooldown, [1, 2], {@UBL_Cooldown}2800);
  // Cone-Attack
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtMelee, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 0.333 * {@UBL_Damage}150.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [2], 2.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffectCone, [2], 3.141);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 466);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 866);

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, -1.0);

    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'Wipe')
      .PassInteger('health_threshold', 200, 'health')
      .PassPercentage('damage_reduction_percentage', 66, 'damage');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 3);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(-0.3, 0, -0.1), RVector3.Create(-0.3, 2.5, -0.1), 1.2);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\MeleeGolemTower\MeleeGolemTower.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_ATTACK, 87, 117)
      .CreateNewAnimation(ANIMATION_ATTACK2, 61, 86)
      .CreateNewAnimation(ANIMATION_STAND, 0, 60)
      .BindZoneToBone(BIND_ZONE_CENTER, 'MeleeGolemTowerPelvis')
      .BindZoneToBone(BIND_ZONE_HEAD, 'MeleeGolemTowerHead')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'MeleeGolemTowerLDigit31');

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2])
      .SecondAttackGroup([2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.55], [0]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetShootingRange.png')
      .ShowWeaponRange();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);

  {$IFDEF SERVER}
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [1])
      .CheckResource(reHealth)
      .Comparator(coGreaterEqual)
      .Reference(200.0)
      .CompareCapToReference();
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);

    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1, 2], true);

    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [2])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [2]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Splash')
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/building/melee_golem_tower/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/colorless/building/melee_golem_tower/wipe_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TOrienterTargetComponent.CreateGrouped(Entity, [1, 2]);
  {$ENDIF}
end;
