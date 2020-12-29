{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 1.8;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetIndexedValue(eiUnitData, [], udUsePathfinding, False);
  Entity.Blackboard.SetValue(eiSpeed, [], (2 / 1000));

  Entity.Blackboard.SetValue(eiUnitProperties, [], [upMonumental, upTier3, upUnit, upGround, upFlying, upMelee, upLegendary]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}1800.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}1800.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], 0.5);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}34.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}3600);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 1000);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 2000);

  // Massive Stomp - extra damage from health
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 0.2);

  // Ancient Wisdom - health per being blessed
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 300.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Legendary')
      .Keyword('StateEffect');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Monumental');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Siege');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Juggernaut');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'FocusSiege');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'MassiveStomp')
      .PassPercentage('damage_amount_percentage', 20, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'AncientWisdom')
      .Keyword('Enchanted')
      .PassInteger('health_bonus', 300, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 10);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 2);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,3.5,0), 2.7);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Brratu' + Entity.SkinFileSuffix + '\Brratu.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 40)
      .CreateNewAnimation(ANIMATION_ATTACK, 146, 208)
      .CreateNewAnimation(ANIMATION_STAND, 210, 270)
      .CreateNewAnimation(ANIMATION_SPAWN, 100, 145)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'BrratuPelvis')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BrratuRDigit11')
      .BindZoneToBone(BIND_ZONE_HEAD, 'BrratuEyelidUpper');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.75], [0]);
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
      .MustHave([upBuilding])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Siege')
      .TriggerOnDamageDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;

    TAutoBrainOnUnitPropertyComponent.CreateGrouped(Entity, [3])
      .TriggerOn([upBlessed]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reHealth)
      .ChangesMax;
  {$ENDIF}

  TModifierWelaDamageComponent.CreateGrouped(Entity, [1])
    .ScaleWithResource(reHealth)
    .SetValueGroup([2]);

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(3000)
    .ApplyToSelfAtCreate();

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TAnimatorComponent.CreateGrouped(Entity, [1])
      .Duration(1600)
      .HideUntil(1550)
      .PlayAnimation(1525, ANIMATION_SPAWN, 2000);

    TMeshEffectComponent.CreateGrouped(Entity, [1])
      .SetEffect(
        TMeshEffectGlow.Create(2000)
          .AddKey(0, 0.1)
          .AddKey(1580, 0.1)
          .AddKey(2000, 0)
      );

    TAnimatorComponent.CreateGrouped(Entity, [8])
      .Duration(2400)
      .PlayAnimation(0, ANIMATION_SPAWN, 1800)
      .PositionKeypointsX([-0.2, -0.2, -0.2])
      .PositionKeypointsY([0, 0, -1.8])
      .PositionTimes([0, 800, 1800])
      .FreeGroupAfter;

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.3], [8]);
    // sapling
    TMeshComponent.CreateGrouped(Entity, [8], 'Units\Green\Sapling' + Entity.SkinFileSuffix + '\Sapling.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_SPAWN, 95, 125)
      .IsPiece;
    TAnimationComponent.CreateGrouped(Entity, [8]);
    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\SaplingSpawn.pfx', 6.0)
       .ActivateOnCreate()
       .FixedOrientationDefault();

    TMeshEffectComponent.CreateGrouped(Entity, [8])
      .SetEffect(
        TMeshEffectGlow.Create(2000)
          .AddKey(0, 0)
          .AddKey(800, 0)
          .AddKey(1500, 1)
          .AddKey(2000, 1)
      );

    TParticleEffectComponent.CreateGrouped(Entity, [8], '\Green\brratu' + Entity.SkinFileSuffix + '_spawn.pfx', 0.8)
      .ActivateOnCreate()
      .Delay(500)
      .FixedOrientationDefault()
      .BindToSubPositionGroup('SaplingHead', [8])
      .IgnoreSize()
      .SetModelOffset(RVector3.Create(-0.2, 0.1, 0));
    TParticleEffectComponent.CreateGrouped(Entity, [8], '\Green\brratu' + Entity.SkinFileSuffix + '_spawn_finish.pfx', 0.8)
      .ActivateOnCreate()
      .Delay(1500)
      .FixedOrientationDefault()
      .BindToSubPositionGroup('SaplingHead', [8])
      .IgnoreSize()
      .SetModelOffset(RVector3.Create(-0.2, 0.4, 0));

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\brratu_impact.pfx', 2.0)
      .ActivateOnCreate()
      .Delay(2350)
      .IgnoreSize();

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.6)
      .Duration(400)
      .Waves(1)
      .ActivateOnCreate()
      .Delay(2350);

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0, 0, 0.01)
      .Duration(400)
      .Waves(2)
      .ActivateOnCreate()
      .Delay(2350);

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .VectorShaker(0, -1, 0)
      .Strength(0.4)
      .Duration(200)
      .Waves(1)
      .ActivateOnFire();

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .RotationShaker(0, 0, 0.01)
      .Duration(400)
      .Waves(2)
      .ActivateOnFire();

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Green\brratu_attack_impact.pfx', 4.0)
      .ActivateOnFire()
      .SetModelOffset(RVector3.Create(-0.2, 0, 2.2));

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/unit/brratu/spawn')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/music/cue/brratu')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/brratu/attack_fire')
      .TriggerOnPreFire();
  {$ENDIF}
end;
