{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upRanged, upRangedGroundOnly, upLegendary]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}680.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}680.0);

  // Ranged-Attack with splash
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}4.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Projectiles\White\PatronSaintProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}110.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2300);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 433);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 2000);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 2.0);

  // Invincible-Protection-Aura
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2, 3], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [2, 3], 'Links\GuardedAura');
  Entity.Blackboard.SetValue(eiWelaRange, [2, 3], 6.0);
  Entity.Blackboard.SetValue(eiWelaActive, [2], False);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [0], 'Legendary')
      .Keyword('StateEffect');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'WarmingLight')
      .PassInteger('heal_amount', 60, 'health');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'GuardingLight')
      .Keyword('Guarded');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 1);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.6,0), 0.95);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\White\PatronSaint' + Entity.SkinFileSuffix + '\PatronSaint.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 60)
      .CreateNewAnimation(ANIMATION_ATTACK, 61, 120)
      .CreateNewAnimation(ANIMATION_STAND, 121, 170)
      .CreateNewAnimation(ANIMATION_SPAWN, 172, 239)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'BansheeSpine4')
      .BoneSwapXY('BansheeSpine4')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BansheeLamp')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BansheeLamp')
      .BindZoneToBone(BIND_ZONE_HEAD, 'BansheeHead')
      .SetModelOffset(RVector3.Create(0,0,-0.6));

    if Entity.SkinID = SKIN_GROUP_MACHINE then
      TMeshEffectMetal.Create()
        .ShowAsColor(ecBlue)
        .AssignToEntity(Entity)
    else
      TMeshEffectMetal.Create()
        .AssignToEntity(Entity);

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.5], [0]);
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

    // Invincible-Protection-Aura
    TWelaHelperActivateTimerComponent.CreateGrouped(Entity, [2])
      .Delay(3500);
    TBrainWelaLinkComponent.CreateGrouped(Entity, [2])
      .ThinksPassively();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetValidateGroup([3]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit])
      .MustNotHave([upImmuneToGuarded, upGuarded]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [2, 3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 3])
      .MustHave([upUnit])
      .MustNotHave([upImmuneToGuarded]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [2, 3])
      .CreatorGroup([4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('GuardingLight')
      .TriggerOnFire;

    // Ranged-Attack
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
  {$ENDIF}

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(3500)
    .ApplyToSelfAtCreate();

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/patron_saint/attack_fire')
      .TriggerOnFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\patron_saint' + Entity.SkinFileSuffix + '_aura_field.pfx', 5.0)
      .ActivateOnWelaActivate()
      .FixedOrientationDefault()
      .FixedHeightGround
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\white_border_wide.pfx', 5.0)
      .IgnoreModelSize
      .ActivateOnWelaActivate()
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    // Spawn-Animation ---------------------------------------------------------------------

    TAnimatorComponent.CreateGrouped(Entity, [1])
      .Duration(2800)
      .SizeKeypoints([0, 0, 1, 1])
      .SizeTimes([0, 1000, 1200, 2800])
      .PositionKeypointsY([0, 5.5, 0, 0])
      .PositionTimes([0, 1000, 1200, 2800])
      .PlayAnimation(1000, ANIMATION_SPAWN, 1800);

    if Entity.SkinID = SKIN_GROUP_MACHINE then
    begin
      TMeshEffectGlow.Create(2500)
        .FixedColorIdentity(ecBlue)
        .AssignToEntity(Entity);
      TMeshEffectHideAndGlow.Create(3500, PATH_GRAPHICS + 'Units\White\PatronSaint' + Entity.SkinFileSuffix + '\PatronSaintSpawnMask.tga')
        .AddKey(0, 0)
        .AddKey(2700, 0)
        .AddKey(3300, 1)
        .AddKey(3500, 0)
        .AddNextTimeLine()
        .AddKey(0, 0)
        .AddKey(3300, 0)
        .AddKey(3301, 1)
        .AddKey(3500, 1)
        .OverrideColorIdentity(ecBlue)
        .AssignToEntity(Entity);
    end
    else
    begin
      TMeshEffectGlow.Create(2500)
        .AssignToEntity(Entity);
      TMeshEffectHideAndGlow.Create(3500, PATH_GRAPHICS + 'Units\White\PatronSaint' + Entity.SkinFileSuffix + '\PatronSaintSpawnMask.tga')
        .AddKey(0, 0)
        .AddKey(2700, 0)
        .AddKey(3300, 1)
        .AddKey(3500, 0)
        .AddNextTimeLine()
        .AddKey(0, 0)
        .AddKey(3300, 0)
        .AddKey(3301, 1)
        .AddKey(3500, 1)
        .AssignToEntity(Entity);
    end;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\White\patron_saint' + Entity.SkinFileSuffix + '_spawn.pfx', 0.7)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .SetModelOffset(RVector3.Create(0, 7, 0));

    TParticleEffectComponent.CreateGrouped(Entity, [], '\White\patron_saint' + Entity.SkinFileSuffix + '_landing.pfx', 1.0)
      .Delay(1000)
      .ActivateOnCreate()
      .FixedOrientationDefault();

    TAnimatorComponent.CreateGrouped(Entity, [5])
      .Duration(2800)
      .HideUntil(1000)
      .HideAfter(2600)
      .FreeGroupAfter;

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\White\patron_saint' + Entity.SkinFileSuffix + '_spawn_glitter.pfx', 1.0)
      .Delay(1300)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .BindToSubPositionGroup('BansheeLUpperarm', [0, 1])
      .IgnoreSize();

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\White\patron_saint' + Entity.SkinFileSuffix + '_spawn_glitter.pfx', 1.0)
      .Delay(1300)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .BindToSubPositionGroup('BansheeRUpperarm', [0, 1])
      .IgnoreSize();

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\White\patron_saint' + Entity.SkinFileSuffix + '_spawn_glitter.pfx', 1.0)
      .Delay(1300)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .BindToSubPositionGroup('BansheeLPalm', [0, 1])
      .IgnoreSize();

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\White\patron_saint' + Entity.SkinFileSuffix + '_spawn_glitter.pfx', 1.0)
      .Delay(1300)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .BindToSubPositionGroup('BansheeRPalm', [0, 1])
      .IgnoreSize();

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\White\patron_saint' + Entity.SkinFileSuffix + '_spawn_glitter.pfx', 1.0)
      .Delay(1300)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .BindToSubPositionGroup('BansheeCape4', [0, 1])
      .IgnoreSize();

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\White\patron_saint' + Entity.SkinFileSuffix + '_spawn_glitter.pfx', 1.0)
      .Delay(1300)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .BindToSubPositionGroup('BansheeCape5', [0, 1])
      .IgnoreSize();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/white/unit/patron_saint/spawn')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/music/cue/selga')
      .TriggerOnCreate();
  {$ENDIF}
end;


