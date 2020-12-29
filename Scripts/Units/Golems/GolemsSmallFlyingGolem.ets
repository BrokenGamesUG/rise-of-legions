{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upFlying, upRanged, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}97.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}97.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Colorless\SmallFlyingGolemProjectile');
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 2); // Multishot
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2300);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}29.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'MultiShot2')
      .PassInteger('target_count', 2);

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.0,0.0), RVector3.Create(0,0.6,0.0), 0.65);

    TPositionerOffsetComponent.CreateGrouped(Entity, [])
      .Offset(0, FLYING_HEIGHT + 0.8, 0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\SmallFlyingGolem\SmallFlyingGolem.xml')
      .ApplyLegacySizeFactor
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BoneCrystal')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneCrystal')
      .CreateNewAnimation(ANIMATION_STAND, 1, 100);

    Entity.Eventbus.WriteGrouped(eiModelSize, [0.9], [0, 1]);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Colorless\SharedCrystalShards\SharedCrystalShards.xml')
      .IgnoreScalingForAnimations
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneC1')
      .FixedOrientationDefault
      .BindToSubPositionGroup('BoneCrystal', [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystalNeutral.png')
      );

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.8], [2]);

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
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\small_flying_golem_attack.pfx', 4.9)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [2]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/small_flying_golem/attack_fire')
      .TriggerOnFire();
  {$ENDIF}
end;


