{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged, upGolem, upSupporter]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}60.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}60.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Colorless\SmallCasterGolemProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}26.0);

  // Crystal Power
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2, 3], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [2, 3], 'Links\CrystalPowerLink');
  Entity.Blackboard.SetValue(eiWelaRange, [2, 3], 8.0);
  Entity.Blackboard.SetValue(eiCooldown, [3], 5000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'CrystalPower');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0.1), RVector3.Create(0,1.7,0.1), 0.6);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\SmallCasterGolem\SmallCasterGolem.xml')
      .IgnoreScalingForAnimations
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BoneCrystal2')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneCrystal2');

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.8], [0, 1]);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Colorless\SharedCrystalShards\SharedCrystalShards.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneC1')
      .FixedOrientationDefault
      .BindToSubPositionGroup('BoneCrystal2', [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystalNeutral.png')
      );

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.8], [2]);
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

    // apply buff to surrounding allied units
    TBrainWelaLinkComponent.CreateGrouped(Entity, [2])
      .SetBuildCheckGroup([3])
      .ThinksPassively();
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [3], True);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetValidateGroup([3]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies)
      .MaxNewTargetCount(1);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit])
      .MustNotHave([upHasCrystalPower]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [2, 3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 3])
      .MustHave([upUnit]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [2, 3]);

    // ranged attack
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
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\small_caster_golem_attack.pfx', 8.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [2]);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Colorless\small_caster_golem_cast.pfx', 1.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [2])
      .IgnoreModelSize;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/small_caster_golem/attack_fire')
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/colorless/unit/small_caster_golem/crystal_power_cast')
      .TriggerOnFire();
  {$ENDIF}
end;



