{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.8;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upFlying, upRanged, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}220.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}220.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 3); // Multishot
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Colorless\BigFlyingGolemProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}54.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'MultiShot3')
      .PassInteger('target_count', 3);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,1.6,0.0), RVector3.Create(0,1.6,0.0), 1.1);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\BigFlyingGolem\BigFlyingGolem.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 200)
      .BindZoneToBone(BIND_ZONE_TOP, 'BoneC')
      .BoneSwizzleXZY(BIND_ZONE_TOP)
      .BoneInvertY(BIND_ZONE_TOP)
      .BoneOffset(BIND_ZONE_TOP, 0, 1.0, 0)
      .BindZoneToBone(BIND_ZONE_HEAD, 'BoneC')
      .BoneSwizzleXZY(BIND_ZONE_HEAD)
      .BoneInvertY(BIND_ZONE_HEAD)
      .BindZoneToBone(BIND_ZONE_CENTER, 'BoneC')
      .BoneSwizzleXZY(BIND_ZONE_CENTER)
      .BoneInvertY(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BoneC')
      .BoneSwizzleXZY(BIND_ZONE_WEAPON)
      .BoneInvertY(BIND_ZONE_WEAPON)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneC')
      .BoneSwizzleXZY(BIND_ZONE_WEAPON_MUZZLE)
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE)
      .SetModelOffset(0, -2.0, 0);

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.7], [0, 1]);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Colorless\SharedCrystal\Crystal.xml')
      .IgnoreScalingForAnimations
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .FixedOrientationDefault
      .BindToSubPositionGroup('BoneC', [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystalNeutral.png')
      );

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.7], [2]);
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
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\big_flying_golem_attack.pfx', 1.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/big_flying_golem/attack_fire')
      .TriggerOnFire();
  {$ENDIF}
end;


