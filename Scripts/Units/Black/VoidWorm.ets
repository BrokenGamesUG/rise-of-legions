{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged, upRangedGroundOnly, upHasDeathRattle]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}100.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}100.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}5.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Black\VoidwormProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}40.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 250);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 666);

  // Death Rattle: Frostexplosion
  Entity.Blackboard.SetValue(eiWelaRange, [2, 3], 2.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2], 200);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Frostshot')
      .Keyword('Frozen');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'DeathRattleFrostexplosion')
      .Keyword('Frozen');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 3);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.5,-0.5), RVector3.Create(0,0.5,0.5), 0.6);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidWorm' + Entity.SkinFileSuffix + '\VoidWorm.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 40)
      .CreateNewAnimation(ANIMATION_ATTACK, 61, 80)
      .CreateNewAnimation(ANIMATION_STAND, 81, 141)
      .CreateNewAnimation(ANIMATION_ABILITY_1, 41, 60)
      .SetAnimationSpeed(ANIMATION_WALK, 0.26)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'Voidworm_teeth_back')
      .BoneSwapYZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneInvertZ(BIND_ZONE_WEAPON_MUZZLE);

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
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
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [1])
      .Prioritize([upImmuneToFrozen, upLegendary, upBuilding, upImmuneToStateEffects])
      .Reverse;

    // Death Rattle : Frostexplosion
    TAutoBrainOnBeforeDeath.CreateGrouped(Entity, [2])
      .FireAtTarget;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [2])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit])
      .MustNotHave([upImmuneToFrozen, upLegendary, upImmuneToStateEffects]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('DeathRattleFrostexplosion')
      .Name('Frozen')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('FrozenRanged')
      .CheckUnitPropertyMustHave([upRanged])
      .TriggerOnFire;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('DeathRattle')
      .Name('DeathRattleFrostexplosion')
      .TriggerOnFire;

    // for effects
    TAutoBrainOnBeforeDeath.CreateGrouped(Entity, [3])
      .FireAtSelf;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\Frozen.dws');

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Black\voidworm_attack.pfx', 0.4)
      .ActivateOnFire
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/voidworm/attack_fire')
      .TriggerOnPreFire
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [3], 'event:/card/black/unit/voidworm/frostexplosion_fire')
      .TriggerOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Black\voidworm_frostexplosion_cast.pfx', 5.0)
      .ActivateOnFire
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Black\black_border_wide_once.pfx', 5.0)
      .ActivateOnFire
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetVectorLight
      .ActivateOnFire;
  {$ENDIF}
end;
