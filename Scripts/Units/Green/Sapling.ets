{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.3;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upMelee, upSapling, upSoulless]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}2.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}2.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], 0.5);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}4.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1500);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 266);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 766);

  // limited life duration
  Entity.Blackboard.SetValue(eiCooldown, [9], 17000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [9], 'TimedLife')
      .PassInteger('duration', 17);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [10], 'Flourish')
      .Keyword('Enchanted')
      .PassInteger('health_amount', 50, 'health');

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0.6,0), 0.6);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Sapling' + Entity.SkinFileSuffix + '\Sapling.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 16)
      .CreateNewAnimation(ANIMATION_ATTACK, 17, 39)
      .CreateNewAnimation(ANIMATION_STAND, 40, 94)
      .CreateNewAnimation(ANIMATION_SPAWN, 95, 105)
      .SetAnimationSpeed(ANIMATION_WALK, 1.3)
      .BindZoneToBone(BIND_ZONE_CENTER, 'SaplingLeafMid')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'SaplingLeafMid')
      .BindZoneToBone(BIND_ZONE_HEAD, 'SaplingLeafMid');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('SaplingByBaseBuilding')
      .CheckDamageType(dtTrue)
      .TriggerOnTakeDamage;

    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

    // melee-attack
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

    // suicide after time
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [9]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [9], False);
    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [9]);

    TAutoBrainOnUnitPropertyComponent.CreateGrouped(Entity, [10])
      .TriggerOn([upBlessed]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [10])
      .Name('Flourish')
      .TriggerOnFire;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [10]);
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [10])
      .TargetGroup([9, 10]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [10], 'Modifiers\BlessingSapling.dws');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(200)
    .ApplyToSelfAtCreate();

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/unit/sapling/spawn')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/sapling/attack_fire')
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [10], 'event:/card/green/unit/sapling/flourish_fire')
      .TriggerOnFire();

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\SaplingSpawn.pfx', 6.0)
       .ActivateOnCreate()
       .FixedOrientationDefault();
  {$ENDIF}
end;
