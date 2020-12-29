{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.7;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upRanged, upFlying]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}230.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}230.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\White\AvengerProjectileBounce');
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [3], 'Projectiles\White\AvengerProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiDamageType, [1, 2, 3], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1, 2, 3], {@UBL_Damage}42.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 550);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 966);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'InnerFireBounce')
      .PassSingleAsInteger('base_health', {@UBL_Health}230.0, 'health')
      .PassInteger('target_count', 2)
      .PassPercentage('damage_reduction_percentage', 50);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 1);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.6,0.0), RVector3.Create(0,2.0,0.1), 0.65);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);
    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\White\Avenger\Avenger.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 30, 69)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 28)
      .CreateNewAnimation(ANIMATION_STAND, 70, 135)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'avengerSpine4')
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'avengerRPalm')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'avengerRPalm')
      .BindZoneToBone(BIND_ZONE_HEAD, 'avengerHead')
      .SetModelOffset(0, -0.2, 0);
    TMeshEffectMetal.Create().AssignToEntity(Entity);
    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.2], [0]);
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
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);

    TWelaEffectFireComponent.CreateGrouped(Entity, [1])
      .MultiTargetGroup([2])
      .MultiTargetGroup([3]);
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [2])
      .ComparedResource(reHealth)
      .ComparedResource(reOverheal)
      .SetComparator(coGreaterEqual)
      .ReferenceValue({@UBL_Health}230.0)
      .ReferenceIsAbsolute;
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);

    TWelaEffectProjectileComponent.CreateGrouped(Entity, [3]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/avenger/attack_fire')
      .TriggerOnFire()
      .StopOnFree;
  {$ENDIF}
end;


