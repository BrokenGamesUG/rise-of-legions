{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
var CurrentLevel : integer;
    AdjustedHealth : single;
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 1.0;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upMelee, upGround, upLegendary]);

  CurrentLevel := Entity.BalanceInt(reLevel);
  if CurrentLevel < 2 then
    Entity.Blackboard.SetValue(eiArmorType, [], atUnarmored)
  else if CurrentLevel < 4 then
    Entity.Blackboard.SetValue(eiArmorType, [], atLight)
  else if CurrentLevel < 6 then
    Entity.Blackboard.SetValue(eiArmorType, [], atMedium)
  else
    Entity.Blackboard.SetValue(eiArmorType, [], atHeavy);

  AdjustedHealth := ({@UBL_Health}155.0);
  AdjustedHealth := AdjustedHealth + 70.0 * Max(0, CurrentLevel - 1);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, AdjustedHealth);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, AdjustedHealth);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reLevel, 10);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}79.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 766);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1400);

  // Active Armor
  Entity.Blackboard.SetValue(eiWelaRange, [3], 6.5);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [3], 'Projectiles\Blue\AtlasActiveArmorProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [3], [dtRanged, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 10.0);

  // Active Armor feedback damage
  Entity.Blackboard.SetValue(eiDamageType, [4], [dtTrue, dtIgnoreArmor]);
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 10.0);

  // Induction Repair
  Entity.Blackboard.SetValue(eiWelaRange, [5], 12.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 0.1);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Legendary')
      .Keyword('StateEffect');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Supreme')
      .PassInteger('module_gain', 1, 'counter')
      .PassInteger('module_cap', 10, 'counter')
      .PassInteger('health_amount', 70, 'health')
      .PassString('armor_level_unarmored', '1', 'counter')
      .PassString('armor_level_light', '2-3', 'counter')
      .PassString('armor_level_medium', '4-5', 'counter')
      .PassString('armor_level_heavy', '6-10', 'counter');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'ActiveArmor')
      .PassInteger('damage_amount', 10, 'damage')
      .PassInteger('self_damage_amount', 10, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'InductionRepair')
      .PassPercentage('heal_amount_percentage', 10, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 1);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 9);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
var i : integer;
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(-0.8, 1.2, 0.05), RVector3.Create(0.8, 1.2, 0.05), 1.1);

    for i := 0 to 5 do
    begin
      TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\Atlas' + Entity.SkinFileSuffix + '\Atlas_Stage' + IntToStr(i) + '.xml')
        .ApplyLegacySizeFactor
        .CreateNewAnimation(ANIMATION_STAND, 192, 248)
        .CreateNewAnimation(ANIMATION_WALK, 0, 39)
        .CreateNewAnimation(ANIMATION_ATTACK, 41, 82)
        .CreateNewAnimation(ANIMATION_SPAWN, 91, 168)
        .CreateNewAnimation('attack_spawn_special', 251, 321)
        .CreateNewAnimation('attack_special', 322, 362)
        .CreateNewAnimation(ANIMATION_ABILITY_1, 363, 400)
        .BindZoneToBone(BIND_ZONE_CENTER, 'WalkerTorso')
        .BoneSwapXY(BIND_ZONE_CENTER)
        .BoneSwapXZ(BIND_ZONE_CENTER)
        .BindZoneToBone(BIND_ZONE_HEAD, 'WalkerTorso')
        .BoneOffset(BIND_ZONE_HEAD, 0, 0.15, 0.0)
        .BindZoneToBone(BIND_ZONE_WEAPON, 'WalkerLArmPalm')
        .IgnoreScalingForAnimations
        .VisibleWithWelaReadyGrouped([i + 7]);

      TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [i + 7])
        .ComparedResource(reLevel)
        .SetComparator(coGreaterEqual)
        .ReferenceValue(i * 2)
        .ReferenceIsAbsolute;
      TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [i + 7])
        .ComparedResource(reLevel)
        .SetComparator(coLowerEqual)
        .ReferenceValue(i * 2 + 1)
        .ReferenceIsAbsolute;
    end;

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.09], [0]);

    TAnimationComponent.CreateGrouped(Entity, [0, 1])
      .AbilityGroup([3]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [3])
      .ShowWeaponRange
      .SetTexture('SpelltargetGeneric.png');

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [5])
      .ShowWeaponRange
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
var i : integer;
    color : integer;
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
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;

    TAutoBrainOnTakeDamageComponent.CreateGrouped(Entity, [2])
      .FireSelfInGroup([2]);
    TWelaTriggerCheckNotSelfComponent.CreateGrouped(Entity, [2]);
    TThinkImpulseFireComponent.CreateGrouped(Entity, [2])
      .TargetGroup([3]);
    TBrainWelaFightComponent.CreateGrouped(Entity, [3])
      .DisableTargetLock
      .ThinksPassively
      .ThinksLocal;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3])
      .SetTargetTeamConstraint(tcEnemies)
      .PicksRandomTargets;
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [3], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [3]);
    TWelaEffectFireComponent.CreateGrouped(Entity, [3])
      .TargetGroup([4])
      .RedirectToSelf;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [4]);

    TAutoBrainOnCommanderAbilityUsedComponent.CreateGrouped(Entity, [5])
      .ConstraintOnSameTeamID
      .ConstraintOnInWelaRange
      .FireAtSelf;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyHealComponent.CreateGrouped(Entity, [5])
      .PercentageOfMaxHealth;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [5])
      .Name('Induction')
      .TriggerOnFire;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(2200)
    .ApplyToSelfAtCreate();

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reLevel);

    // Attack --------------------------------------------------------------------------------------------------

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/blue/unit/atlas/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    // Active Armor --------------------------------------------------------------------------------------------

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Blue\blue_border_wide.pfx', 5.0)
      .IgnoreModelSize
      .ActivateOnWelaActivate
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [4], 'event:/card/blue/unit/atlas/active_armor_fire')
      .TriggerOnFire;

    if Entity.SkinID = SKIN_GROUP_POPULAR then
      color := $402040FF
    else
      color := $405BA9FF;

    TMeshEffectComponent.CreateGrouped(Entity, [4])
      .TargetGroup([])
      .ActivateOnFire
      .SetEffect(
        TMeshEffectSoulGain.Create(400)
          .Color(color)
          .Radius(0.5)
          .AddKey(0, 0.0)
          .AddKey(400, 1.0)
          .Additive
      );

    // Induction Repair ----------------------------------------------------------------------------------------

    TSoundComponent.CreateGrouped(Entity, [5], 'event:/card/blue/unit/atlas/induction_repair_fire')
      .TriggerOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\Blue\induction_health.pfx', 0.8)
      .ActivateOnFire
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    // Spawn-Animation -----------------------------------------------------------------------------------------

    TMeshEffectComponent.CreateGrouped(Entity, [0, 1, 2])
      .SetEffect(
        TMeshEffectWarp.Create(PATH_GRAPHICS + 'Units\Blue\Atlas' + Entity.SkinFileSuffix + '\AtlasSpawnMask.png', 2600)
          .Smooth(0.5)
          .AddKey(0, 0)
          .AddKey(200, 0.6)
          .AddKey(1000, 1.0)
      );

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\atlas_spawn.pfx', 1.0)
      .ActivateOnCreate
      .DeactivateOnTime(2600)
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1])
      .IgnoreSize;

    TMeshEffectGlow.Create(2600)
      .FixedColorIdentity(ecBlue)
      .AddKey(0, 0.15)
      .AddKey(600, 0.15)
      .AddKey(2600, 0.0)
      .AssignToEntity(Entity);

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\atlas_impact.pfx', 2.0)
      .ActivateOnCreate
      .Delay(1200);

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.4)
      .Duration(250)
      .Waves(3)
      .ActivateOnCreate()
      .Delay(1233);

    for i := 0 to 5 do
    begin
      TSoundComponent.CreateGrouped(Entity, [], 'event:/card/blue/unit/atlas/spawn_' + IntToStr(i))
        .Delay(0) // trigger on first frame after creation as level is not ready in AfterCreate
        .CheckGroup([i + 7])
        .TriggerOnCreate;
    end;
  {$ENDIF}
end;


