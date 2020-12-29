{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.7;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upMelee]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}165.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}165.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 2);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 2);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}16.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 966);

  // Shield Overload
  Entity.Blackboard.SetValue(eiCooldown, [2], 8000);

  // Teleport Strike
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [3], reMana, 2);
  Entity.Blackboard.SetValue(eiWelaRange, [3], 8.0);
  Entity.Blackboard.SetValue(eiCooldown, [3], 3000);
  Entity.Blackboard.SetValue(eiDamageType, [3], [dtMelee, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 100.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [3], 333);
  Entity.Blackboard.SetValue(eiWelaActionduration, [3], 1066);

  // Induction Energy
  Entity.Blackboard.SetValue(eiWelaRange, [4], 12.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 1.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'Shieldoverload')
      .PassInteger('duration', 2)
      .PassInteger('cooldown', 8);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'TeleportStrike')
      .PassInteger('energy_cost', 2)
      .PassInteger('damage_amount', 100, 'damage')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'InductionEnergy')
      .PassInteger('energy_amount', 1, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 1);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0.1,0,0.1), RVector3.Create(0.1,1.0,0.1), 0.9);

    TMeshComponent.CreateGrouped(Entity, [0, 1, 3], 'Units\Blue\Phasedrone' + Entity.SkinFileSuffix + '\Phasedrone.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 87, 146)
      .CreateNewAnimation(ANIMATION_WALK, 0, 23)
      .CreateNewAnimation(ANIMATION_ATTACK, 25, 53)
      .CreateNewAnimation(ANIMATION_ABILITY_1, 54, 85)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'PhaseDroneLArmPalm')
      .BindZoneToBone(BIND_ZONE_HEAD, 'PhaseDroneHub002')
      .BoneSwizzleYZX(BIND_ZONE_HEAD)
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.4, 0.3)
      .BindZoneToBone(BIND_ZONE_CENTER, 'PhaseDroneHub002')
      .BoneSwapXZ(BIND_ZONE_CENTER)
      .BoneSwapYZ(BIND_ZONE_CENTER);

    if Entity.SkinID = SKIN_GROUP_CRUSADER then
      TMeshEffectMetal.Create()
        .ShowAsColor(ecWhite)
        .AssignToEntity(Entity);

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 3])
      .AbilityGroup([3]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.8], [0]);
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

    TBrainWelaFightComponent.CreateGrouped(Entity, [3])
      .DisableTargetLock
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upSilenced]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [3], true);
    TWelaReadyCostComponent.CreateGrouped(Entity, [3])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3])
      .SetTargetTeamConstraint(tcEnemies)
      .PicksRandomTargets;
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [3])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [3], eiDamageable);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyTeleportComponent.CreateGrouped(Entity, [3])
      .OffsetByCollisionRadius
      .Offset(-0.1);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [3]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [3])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('TeleportStrike')
      .TriggerOnKillDone;

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
      .TriggersAfterDamage
      .FireSelfInGroup([2])
      .ThinksPassivelyIfConscious;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], True);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Shieldoverload')
      .TriggerOnFire;

    TAutoBrainOnCommanderAbilityUsedComponent.CreateGrouped(Entity, [4])
      .ConstraintOnSameTeamID
      .ConstraintOnInWelaRange
      .FireAtSelf;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [4])
      .SetResourceType(reMana);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('Induction')
      .TriggerOnFire;
  {$ENDIF}

  if Entity.SkinID = SKIN_GROUP_CRUSADER then
    TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\Invincibility.dws')
  else
    TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\Invincibility.dws')
      .Methodname('ApplyBlue');

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/blue/unit/phasedrone/attack_fire')
      .TriggerOnPreFire
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Blue\phase_drone' + Entity.SkinFileSuffix + '_teleport_strike_trigger.pfx', 0.5)
      .ActivateOnPreFire
      .ScaleWith(eiCollisionRadius)
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Blue\phase_drone' + Entity.SkinFileSuffix + '_teleport_strike_impact.pfx', 0.5)
      .Delay(100)
      .ActivateOnFire
      .ScaleWith(eiCollisionRadius)
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetVectorLight
      .ActivateOnFire;

    TSoundComponent.CreateGrouped(Entity, [3], 'event:/card/blue/unit/phasedrone/teleport_strike_fire')
      .TriggerOnPreFire
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\induction_energy.pfx', 1.2)
      .ActivateOnFire
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [4], 'event:/card/blue/unit/phasedrone/induction_energy_fire')
      .TriggerOnFire;
  {$ENDIF}
end;
