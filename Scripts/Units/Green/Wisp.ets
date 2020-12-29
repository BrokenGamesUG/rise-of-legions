{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.5;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upFlying, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}75.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}75.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Green\WispProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}64.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 900);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1500);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.Create(Entity, 'DepletingBounce')
      .PassInteger('target_count', 6);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 7);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.8,0), RVector3.Create(0,1.2,0), 0.65);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);

    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Green\Wisp\Wisp.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 46, 106)
      .CreateNewAnimation(ANIMATION_WALK, 0, 45)
      .CreateNewAnimation(ANIMATION_ATTACK, 151, 194)
      .BindZoneToBone(BIND_ZONE_CENTER, 'WispHead')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'WispEye')
      .BindZoneToBone(BIND_ZONE_HEAD, 'WispEye')
      .IgnoreScalingForAnimations;
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.57], [0]);
    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
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
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TAnimatorComponent.CreateGrouped(Entity, [])
      .Duration(1750)
      .PositionKeypointsY([-FLYING_HEIGHT, -FLYING_HEIGHT, 0])
      .PositionTimes([0, 1000, 1750]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/wisp/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;
