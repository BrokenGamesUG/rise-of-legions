{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.9;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upMelee, upLegendary, upSoulGatherer]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}390.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}390.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 20);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}65.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1000);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 366);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 800);

  // Soul Armor - Block damage with souls
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 1);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 5.0);
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 0.0);

  // Soul Undertow - Rip out nearby souls over time
  Entity.Blackboard.SetValue(eiWelaTargetCount, [3], 1);
  Entity.Blackboard.SetValue(eiCooldown, [3], 3000);
  Entity.Blackboard.SetValue(eiWelaRange, [3], 5.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [3], 'Projectiles\Black\VoidGatherProjectile');
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);

  // Powerful Debut: Lord of Souls - Rip out all nearby souls
  Entity.Blackboard.SetValue(eiWelaTargetCount, [5], 200);
  Entity.Blackboard.SetValue(eiWelaRange, [5], 9.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [5], 'Projectiles\Black\VoidGatherProjectileTyrus');
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 1.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [0], 'Legendary')
      .Keyword('StateEffect');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'SoulGatherer')
      .PassInteger('energy_amount', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'ShadowHunter')
      .Keyword('Banished');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'SoulUndertow')
      .Keyword('Banished')
      .PassInteger('target_count', 1)
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'SoulGathererSoulArmor')
      .PassInteger('energy_cost', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'DebutSoulVortex')
      .Keyword('Banished')
      .PassInteger('energy_amount', 1, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 7);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [5])
    .MustHave([upUnit])
    .MustNotHave([upBase, upLegendary, upImmuneToBanished, upImmuneToStateEffects]);
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [5], eiDamageable);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0.2), RVector3.Create(0, 2.2, 0.2), 1.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\Tyrus' + Entity.SkinFileSuffix + '\Tyrus.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 49)
      .CreateNewAnimation(ANIMATION_ATTACK, 51, 74)
      .CreateNewAnimation(ANIMATION_ATTACK2, 74, 97)
      .CreateNewAnimation(ANIMATION_WALK, 99, 148)
      .CreateNewAnimation(ANIMATION_SPAWN, 149, 249)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'TyrusSpine4');

    Entity.Eventbus.Write(eiModelSize, [0.95]);
    TAnimationComponent.CreateGrouped(Entity, [0, 1])
      .AlternatingAttack;

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [5])
      .SetTexture('SpelltargetGeneric.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [5]);
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

    // Soul armor
    TAutoBrainOnTakeDamageComponent.CreateGrouped(Entity, [2])
      .ModifiesAmount
      .FireSelfInGroup([2])
      .ThinksPassively;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaTriggerCheckTakeDamageThresholdComponent.CreateGrouped(Entity, [2]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('SoulGathererSoulArmor')
      .Name('SoulConsumed')
      .TriggerOnFire;

    // Void undertow
    TBrainWelaFightComponent.CreateGrouped(Entity, [3]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [3], False);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3])
      .SetTargetTeamConstraintPriority(tcEnemies)
      .PicksRandomTargets();
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustHave([upUnit])
      .MustNotHave([upBase, upLegendary, upImmuneToBanished, upImmuneToStateEffects, upInvisible]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [3], eiDamageable);

    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('Banished')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('BanishedMelee')
      .CheckUnitPropertyMustHave([upMelee])
      .TriggerOnFire;
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [3])
      .Reverse;

    // Powerful debut : Lord of Souls
    TBrainWelaFightComponent.CreateGrouped(Entity, [5])
      .ThinksPassively;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [5])
      .SetTargetTeamConstraintPriority(tcEnemies)
      .PicksRandomTargets();

    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [5])
      .Name('Banished')
      .Name('PowerfulDebutSoulVortex')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [5])
      .Name('BanishedMelee')
      .CheckUnitPropertyMustHave([upMelee])
      .TriggerOnFire;
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [5])
      .Reverse;
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [5]);

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
      .MustNotHave([upInvisible]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;
  {$ENDIF}

   // add soulless
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [3], 'Modifiers\Banished.dws');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [5], 'Modifiers\Banished.dws');

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(3300)
    .ApplyToSelfAtCreate();

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .NoCap
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/tyrus/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Black\black_border_wide.pfx', 5.0)
      .IgnoreModelSize
      .ActivateOnWelaActivate()
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    // Spawn-Animation ---------------------------------------------------------------------
    TMeshEffectSpawn.Create()
      .OverrideEffectTime(3000)
      .Legendary
      .OverrideColor($FFBFFDED)
      .AssignToEntity(Entity);

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Black\tyrus' + Entity.SkinFileSuffix + '_spawn.pfx', 1.3)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .IgnoreSize();

    Entity.Eventbus.WriteGrouped(eiModelSize, [0.35], [7]);
    TMeshComponent.CreateGrouped(Entity, [7], 'Effects\Meshes\BlackPit.xml')
      .IsEffectMesh
      .IsDecal()
      .SetModelRotationOffset(RVector3.Create(0, random * 3.14 * 2, 0));

    TMeshEffectComponent.CreateGrouped(Entity, [7])
      .SetEffect(
        TMeshEffectWarp.Create(PATH_GRAPHICS_EFFECTS_MESHES + 'BlackPitSpawnMask.png', 3500)
          .Smooth(0.2)
          .AddKey(0, 0)
          .AddKey(500, 1)
          .AddKey(1500, 1)
          .AddKey(2500, 0)
      );

    TAnimatorComponent.CreateGrouped(Entity, [7])
      .Duration(3300)
      .FreeGroupAfter;

    TMeshEffectComponent.CreateGrouped(Entity, [0, 1])
      .SetEffect(
        TMeshEffectTint.Create(2200, $FF262731)
          .AddKey(0, 1.0)
          .AddKey(1000, 1.0)
          .AddKey(2200, 0.0)
    );

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/unit/tyrus/spawn')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/unit/tyrus/theme')
      .TriggerOnCreate();
  {$ENDIF}
end;


