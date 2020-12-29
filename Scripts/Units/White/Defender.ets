{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upMelee, upGround, upLegendary]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atHeavy);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}1050.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}1050.0);

  // Sword-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}270.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 533);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1067);

  // Defender-Aura: redirect 80% damage of near allies to himself
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2, 3], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [2, 3], 'Links\LotharAura');
  Entity.Blackboard.SetValue(eiWelaRange, [2, 3], 6.0);
  Entity.Blackboard.SetValue(eiWelaActive, [2], False);

  // Powerful Debut: Stun all enemies on impact
  Entity.Blackboard.SetValue(eiWelaRange, [5], 6.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [5], 200);
  Entity.Blackboard.SetValue(eiCooldown, [5], 1500);

  // Wall of Light
  Entity.Blackboard.SetValue(eiWelaRange, [7], 11.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [7], 'Projectiles\White\LotharWallOfLightProjectile');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [0], 'Legendary')
      .Keyword('StateEffect');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [8], 'Fury');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'LotharAura')
      .PassPercentage('redirected_damage_percentage', 80);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'DebutStun')
      .Keyword('Stunned');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [6], 'WallOfLight')
      .Keyword('Shieldblock');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 1);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 9);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0.2), RVector3.Create(0, 1.0, 0.2), 0.9);
    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\White\Defender' + Entity.SkinFileSuffix + '\Defender.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 142, 202)
      .CreateNewAnimation(ANIMATION_ATTACK, 110, 141)
      .CreateNewAnimation(ANIMATION_WALK, 69, 108)
      .CreateNewAnimation(ANIMATION_SPAWN, 0, 68)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'LotharSpine4')
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'LotharRPalm')
      .BindZoneToBone(BIND_ZONE_HEAD, 'LotharHead');

    if Entity.SkinID = SKIN_GROUP_POPULAR then
      TMeshEffectMetal.Create()
        .ShowAsColor(ecBlue)
        .AssignToEntity(Entity)
    else
      TMeshEffectMetal.Create()
        .AssignToEntity(Entity);

    Entity.Eventbus.Write(eiModelSize, [1.35]);
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

    // Defender-Aura
    TBrainWelaLinkComponent.CreateGrouped(Entity, [2])
      .ThinksPassively();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetValidateGroup([3]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upBuilding, upLotharBuffed]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [2, 3]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [2, 3]);
    TWelaLinkEffectUnitPropertyComponent.CreateGrouped(Entity, [2, 3], upLotharBuffed);
    TWelaHelperActivateTimerComponent.CreateGrouped(Entity, [2])
      .Delay(1800);

    // Auto-Attack
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
    // fury - reset if enemy is at full health
    TWelaEffectFireComponent.CreateGrouped(Entity, [1])
      .TargetGroup([8]);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [8])
      .CheckResource(reHealth)
      .CheckFull;
    TWelaEffectFireComponent.CreateGrouped(Entity, [8])
      .TargetGroup([9])
      .RedirectToSelf;
    TWelaEffectResetCooldownComponent.CreateGrouped(Entity, [9])
      .TargetGroup([1])
      .Expire;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;

    TBrainWelaFightComponent.CreateGrouped(Entity, [5])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [5], false);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [5])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [5])
      .MustNotHave([upBuilding, upLegendary, upImmuneToStateEffects]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [5], eiDamageable);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [5]);

    TAutoBrainOnHealedComponent.CreateGrouped(Entity, [6]);
    TThinkImpulseFireComponent.CreateGrouped(Entity, [6])
      .TargetGroup([7]);
    TBrainWelaFightComponent.CreateGrouped(Entity, [7])
      .DisableTargetLock
      .ThinksPassively
      .ThinksLocal;
    TWelaEfficiencyMaxHealthComponent.CreateGrouped(Entity, [7])
      .Inverse;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [7])
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [7])
      .MustHave([upUnit])
      .MustNotHave([upBase, upHasShieldBlock]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [7]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [7])
      .Name('WallOfLight')
      .TriggerOnFire;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(2200)
    .ApplyToSelfAtCreate();

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [5], 'Modifiers\Stun.dws');

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/defender/attack')
      .TriggerOnFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\white_border_wide.pfx', 5.0)
      .ActivateOnWelaActivate()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TMeshEffectComponent.CreateGrouped(Entity, [9])
      .TargetGroup([])
      .ActivateOnFire
      .SetEffect(
        TMeshEffectSoulGain.Create(400)
          .Color($40FEFF98)
          .Radius(0.5)
          .AddKey(0, 0.0)
          .AddKey(400, 1.0)
          .Additive
      );

    // Spawn-Animation ---------------------------------------------------------------------
    TParticleEffectComponent.CreateGrouped(Entity, [], '\White\lothar_spawn.pfx', 0.8)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .BindToSubPositionGroup('LotharSpine3', [0, 1])
      .IgnoreSize();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/white/unit/defender/spawn')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [], '\White\lothar_impact.pfx', 2.0)
      .ActivateOnCreate()
      .Delay(1500)
      .IgnoreSize();

    TMeshEffectGlow.Create(1400).AssignToEntity(Entity);

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.4)
      .Duration(250)
      .Waves(3)
      .ActivateOnCreate()
      .Delay(1500);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/music/cue/lothar')
      .TriggerOnCreate();
  {$ENDIF}
end;


