{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upFlying, upRanged, upHasDeathRattle]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}140.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}140.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}3.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Green\SporeProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1500);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}80.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 333);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 666);

  // On-Death Sporefield
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Effects\SporeField');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'DeathRattleSporeField')
      .Keyword('Grounded')
      .PassInteger('heal_amount', 30, 'health')
      .PassInteger('duration', 10);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, -0.8, -0.2), RVector3.Create(0, 0.2, 0.0), 0.6);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT + 1.28, 0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Spore\Spore.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 61)
      .CreateNewAnimation(ANIMATION_ATTACK, 62, 81)
      .CreateNewAnimation(ANIMATION_ATTACK2, 82, 103)
      .CreateNewAnimation(ANIMATION_STAND, 0, 61)
      .BindZoneToBone(BIND_ZONE_CENTER, 'SporeTry_Tail_1')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BallBone')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BallBone')
      .BindZoneToBone(BIND_ZONE_HEAD, 'SporeTry_BodyBone001')
      .IgnoreScalingForAnimations
      .SetModelOffset(RVector3.Create(0, -0.1, 0));

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.16], [0]);
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

    TAutoBrainOnBeforeDeath.CreateGrouped(Entity, [2]);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('DeathRattle')
      .Name('DeathRattleSporeField')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TAnimatorComponent.CreateGrouped(Entity, [])
      .Duration(1750)
      .PositionKeypointsY([-FLYING_HEIGHT - 1.05, -FLYING_HEIGHT - 1.05, 0])
      .PositionTimes([0, 1000, 1750]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/spore/attack_fire')
      .TriggerOnFire
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/green/unit/spore/heal_field')
      .TriggerOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetVectorLight
      .ActivateOnFire;
  {$ENDIF}
end;
