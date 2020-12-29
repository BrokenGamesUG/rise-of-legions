{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 1.2;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upRanged, upFlying, upLegendary]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atHeavy);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}460.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}460.0);

  // Ranged-Attack with Shatter Ice
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0, 1], 1);
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}7.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Black\VecraProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}290.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 450);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 833);

  // Icy Prison - Selfdamage and Freeze
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 10.0);
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtIgnoreArmor]);
  Entity.Blackboard.SetValue(eiCooldown, [2], 2000);
  Entity.Blackboard.SetValue(eiWelaModifier, [3], 0.2);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [3], 'Projectiles\Black\VecraFreeze');

  // Monarch of Frost
  Entity.Blackboard.SetValue(eiWelaTargetCount, [4, 5], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [4, 5], 'Links\VecraAura');
  Entity.Blackboard.SetValue(eiWelaRange, [4, 5], 8.0);
  Entity.Blackboard.SetValue(eiWelaActive, [4, 5], False);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [0], 'Legendary')
      .Keyword('StateEffect');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'DebutIcyPrison')
      .Keyword('Frozen')
      .PassPercentage('damage_reduction_percentage', 80)
      .PassPercentage('break_threshold_percentage', 50, 'health')
      .PassInteger('break_shatter_damage', 1000, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [6], 'IcyBreath')
      .Keyword('Frozen');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'MonarchOfFrost')
      .PassInteger('damage_amount', 12, 'damage')
      .PassPercentage('heal_amount_percentage', 50, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 1.6, 0.7), RVector3.Create(0, 1.6, -0.5), 1.1);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);
    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\Vecra' + Entity.SkinFileSuffix + '\Vecra.xml')
      .NoWalkOffset
      .ApplyLegacySizeFactor
      {$IFNDEF MAPEDITOR}
        .CreateNewAnimation(ANIMATION_SPAWN, 252, 252)
        .SetFollowingDefaultAnimation(ANIMATION_SPAWN, ANIMATION_SPAWN)
      {$ENDIF}
      .CreateNewAnimation(ANIMATION_STAND, 101, 171)
      .CreateNewAnimation(ANIMATION_ATTACK, 253, 277)
      .CreateNewAnimation(ANIMATION_WALK, 51, 100)
      .CreateNewAnimation('ANIMATION_UNLEASH', 0, 50)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_HIT_ZONE, 'VecraSpine4')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'VecraFire')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE)
      .BoneOffset(BIND_ZONE_WEAPON_MUZZLE, 0, -0.1, 0.3)
      .IsPiece;

    {$IFNDEF MAPEDITOR}
      TPositionerOffsetComponent.CreateGrouped(Entity, [0, 1, 2, 3])
        .Offset(0, -FLYING_HEIGHT, 0);
    {$ENDIF}

    Entity.Eventbus.Write(eiModelSize, [0.07]);
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

    // Auto-Attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], True);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    // Icy Prison
    // melt damage tick
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [2])
      .ThinksPassively();
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], False);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [2]);
    // tough while in prison
    TBuffTakenDamageMultiplierComponent.CreateGrouped(Entity, [3])
      .DamageTypeMustNotHave([dtIgnoreArmor]);
    // unleash
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [3])
      .ThinksPassively();
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [3])
      .ComparedResource(reHealth)
      .SetComparator(coLowerEqual)
      .ReferenceValue(0.5);
    // freeze
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [3]);
    // make self stunned and invincible while unleashing
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    // activate aura
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [3])
      .SetsActive
      .SetActivationGroup([4, 5]);
    // initiate spawn animation
    TWelaEffectFireComponent.CreateGrouped(Entity, [3])
      .TargetGroup([6]);
    // remove icy prison
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [3])
      .TargetGroup([2, 3]);

    // Monarch-of-Frost-Aura
    TBrainWelaLinkComponent.CreateGrouped(Entity, [4])
      .ThinksPassively();

    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .SetValidateGroup([5]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4, 5])
      .MustHave([upFrozen]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [4, 5]);
  {$ENDIF}

  // while in prison Vecra is grounded and frozen
  TUnitPropertyComponent.CreateGrouped(Entity, [3], [upFrozen, upImmuneToFrozen, upGround]);

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(2500)
    .ApplyToSelfAtCreate();

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [3], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(1666);

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/vecra/attack_fire')
      .TriggerOnPreFire
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Black\vecra' + Entity.SkinFileSuffix + '_attack.pfx', 1.2)
      .ActivateOnFire()
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);

    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Black\black_border_wide.pfx', 5.0)
      .IgnoreModelSize
      .ActivateOnWelaActivate()
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    // Icy-Prison ---------------------------------------------------------------------
    {$IFNDEF MAPEDITOR}
      TMeshEffectComponent.CreateGrouped(Entity, [0, 1, 2])
        .SetEffect(
          TMeshEffectWarp.Create(PATH_GRAPHICS + 'Units\Black\Vecra' + Entity.SkinFileSuffix + '\VecraSpawnMask.png', 3000)
            .Smooth(0.5)
            .AddKey(0, 0)
            .AddKey(500, 0)
            .AddKey(2000, 0.7)
            .AddKey(2500, 1)
        );

      TParticleEffectComponent.CreateGrouped(Entity, [2], '\Black\vecra_spawn.pfx', 0.95)
        .ActivateOnCreate()
        .DeactivateOnTime(1500)
        .IsPiece;

      TParticleEffectComponent.CreateGrouped(Entity, [2], '\Shared\Frozen.pfx', 1.4)
        .ActivateOnCreate()
        .Delay(1000)
        .ScaleWith(eiCollisionRadius)
        .IsPiece;
      TMeshEffectComponent.CreateGrouped(Entity, [3])
        .TargetGroup([])
        .SetEffect(
          TMeshEffectIce.Create(60 * 60 * 1000)
            .AddKey(0, 1.0)
            .AddKey(60 * 60 * 1000, 1.0)
        );

      TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/unit/vecra/spawn_prison')
        .TriggerOnCreate();

      // Spawn-Animation ---------------------------------------------------------------------
      TAnimatorComponent.CreateGrouped(Entity, [0, 1, 6])
        .Duration(1666)
        .PositionKeypointsY([-FLYING_HEIGHT, -FLYING_HEIGHT, 0])
        .PositionTimes([0, 466, 1666])
        .PlayAnimation(0, 'ANIMATION_UNLEASH', 1666)
        .ActivateOnFire;

      TSoundComponent.CreateGrouped(Entity, [6], 'event:/card/black/unit/vecra/spawn_unleash')
        .TriggerOnFire;
    {$ENDIF}
  {$ENDIF}
end;


