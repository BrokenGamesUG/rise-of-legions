{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.4;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}46.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}46.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Colorless\SmallRangedGolemProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}15.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 100);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 333);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Siege');

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.2,0.0), RVector3.Create(0.1,1.5,0.2), 0.7);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\SmallRangedGolem\SmallRangedGolem.xml')
      .IgnoreScalingForAnimations
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 60)
      .CreateNewAnimation(ANIMATION_ATTACK, 61, 71)
      .CreateNewAnimation(ANIMATION_STAND, 0, 60)
      .BindZoneToBone(BIND_ZONE_CENTER, 'Bone001')
      .BoneOffset(BIND_ZONE_CENTER, 0, -0.2, 0.4)
      .BindZoneToBone(BIND_ZONE_HEAD, 'Bone001')
      .BoneOffset(BIND_ZONE_HEAD, 0, -0.2, 0.4)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'Bone001')
      .BoneOffset(BIND_ZONE_WEAPON, 0, -0.2, 0.4)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'Bone001')
      .BoneOffset(BIND_ZONE_WEAPON_MUZZLE, 0, -0.2, 0.4);

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.55], [0]);
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
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/small_ranged_golem/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;



