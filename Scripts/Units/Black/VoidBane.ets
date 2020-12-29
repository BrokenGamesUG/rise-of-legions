{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.7;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upMelee, upSoulGatherer, upHasDeathRattle]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}190.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}190.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 14);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Scythe-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], 0.5 + {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}27.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2300);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 2.5);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffectCone, [1], 3.141 * 0.9);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 333);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1133);

  // Soul Gatherer : Reaper
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 15.0); // Gained health per Soul

  // Soul Donor - give nearby allied units saved souls
  Entity.Blackboard.SetValue(eiWelaTargetCount, [3], 0); // + Modifier
  Entity.Blackboard.SetValue(eiWelaModifier, [3], 1); // x Mana = TargetCount
  Entity.Blackboard.SetValue(eiWelaRange, [3], 8.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [3], 'Projectiles\Black\SoulDonorProjectileVoidBane');
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);
  Entity.Blackboard.SetValue(eiDamageType, [3], [dtIrredirectable]);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Cleave');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'SoulGatherer')
      .PassInteger('energy_amount', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'SoulGathererReaper')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('health_amount', 15, 'health');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'DeathRattleSoulDonor');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 2);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(-0.2,0,0), RVector3.Create(-0.2,1.8,0), 0.90);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidBane' + Entity.SkinFileSuffix + '\VoidBane.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 60)
      .CreateNewAnimation(ANIMATION_ATTACK, 60, 93)
      .CreateNewAnimation(ANIMATION_STAND, 94, 154)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'VoidbaneSpine3')
      .BindZoneToBone(BIND_ZONE_HEAD, 'VoidbaneHead')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'VoidbaneWeaponBlade')
      .BoneSwapXY(BIND_ZONE_WEAPON)
      .BoneInvertY(BIND_ZONE_WEAPON);

    if Entity.SkinID = SKIN_GROUP_CRUSADER then
    begin
      TMeshEffectMetal.Create()
        .ShowAsColor(ecWhite)
        .AssignToEntity(Entity);
    end;

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.4], [0]);
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

    // Scythe-Melee-Attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;

    TAutoBrainOnResourceComponent.CreateGrouped(Entity, [2])
      .TriggerOn([reMana])
      .TimesForEach;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [2])
      .SetResourceType(reHealth)
      .ChangesMax;

    TAutoBrainOnBeforeDeath.CreateGrouped(Entity, [3])
      .FireAtTarget();
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upSilenced]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3])
      .SetTargetTeamConstraint(tcAllies)
      .PicksRandomTargetsWithRepetition();
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upSoulDonor]);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [3])
      .CheckResource(reMana)
      .CheckNotFull();
    TModifierWelaTargetCountComponent.CreateGrouped(Entity, [3])
      .ScaleWithResource(reMana);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [3]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('SoulDonor')
      .Name('DeathRattleSoulDonor')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TVertexTraceComponent.CreateGrouped(Entity, [1])
      .Texture('Units\Black\VoidBane' + Entity.SkinFileSuffix + '\ScytheTrace.tga')
      .Color($A0FFFFFF)
      .Width(1.0)
      .SamplingDistance(0.2)
      .FadeLength(3.0)
      .MaxLength(6.0)
      .TexturePerDistance(4.0)
      .RollUpSpeed(10)
      .ActivateOnFire()
      .DeactivateAfterTime(233)
      .DeactivateOnMoveTo()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/voidbane/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Black\void_bane_reaper.pfx', 1.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/black/unit/voidbane/reaper_trigger')
      .TriggerOnFire();

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Black\void_bane_soul_donor.pfx', 1.2)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [3], 'event:/card/black/unit/voidbane/death_cry_trigger')
      .TriggerOnFire();

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetVectorLight
      .ActivateOnFire;

    TSoundComponent.CreateGrouped(Entity, [3], 'event:/card/shared/effect/energy_donor')
      .TriggerOnFire();
  {$ENDIF}
end;
