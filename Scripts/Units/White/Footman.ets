{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.55;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upMelee, upGround]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}32.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}32.0);

  // Sword-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}13.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 300);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 800);

  // Shield-Block
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 10.0);
  Entity.Blackboard.SetValue(eiCooldown, [2], 5000);
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 0.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'ShieldBlock')
      .Keyword('Shieldblock')
      .PassInteger('cooldown', 5);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
{$IFDEF CLIENT}
var MeshComponent : TMeshComponent;
{$ENDIF}
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.2,0), 0.6);

    MeshComponent := TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\White\Footman' + Entity.SkinFileSuffix + '\Footman.xml')
      .ApplyLegacySizeFactor
      .IgnoreScalingForAnimations;

    if Entity.SkinID = SKIN_GROUP_WOODLANDS then
    begin
      MeshComponent
        .BindZoneToBone(BIND_ZONE_CENTER, 'ForestKnightSpine4')
        .BindZoneToBone(BIND_ZONE_WEAPON, 'ForestKnightRPalm')
        .BindZoneToBone(BIND_ZONE_HEAD, 'ForestKnightHead')
        .CreateNewAnimation(ANIMATION_STAND, 0, 57)
        .CreateNewAnimation(ANIMATION_ATTACK, 58, 71)
        .CreateNewAnimation(ANIMATION_WALK, 72, 112);

      TMeshEffectMetal.Create().AssignToEntity(Entity);
    end
    else if Entity.SkinID = SKIN_GROUP_UNDERWORLD then
    begin
      MeshComponent
        .BindZoneToBone(BIND_ZONE_CENTER, 'TormentedSoulSpine4')
        .BindZoneToBone(BIND_ZONE_WEAPON, 'TormentedSoulRPalm')
        .BindZoneToBone(BIND_ZONE_HEAD, 'TormentedSoulHead')
        .CreateNewAnimation(ANIMATION_STAND, 0, 52)
        .CreateNewAnimation(ANIMATION_ATTACK, 53, 71)
        .CreateNewAnimation(ANIMATION_WALK, 72, 112);
    end
    else
    begin
      MeshComponent
        .BindZoneToBone(BIND_ZONE_CENTER, 'FootmanSpine4')
        .BindZoneToBone(BIND_ZONE_WEAPON, 'FootmanRPalm')
        .BindZoneToBone(BIND_ZONE_HEAD, 'FootmanHead')
        .BoneSwapXY(BIND_ZONE_CENTER)
        .CreateNewAnimation(ANIMATION_STAND, 0, 56)
        .CreateNewAnimation(ANIMATION_ATTACK, 58, 81)
        .CreateNewAnimation(ANIMATION_WALK, 83, 122);

      TMeshEffectMetal.Create().AssignToEntity(Entity);
    end;

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
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;

    TAutoBrainOnTakeDamageComponent.CreateGrouped(Entity, [2])
      .ModifiesAmount
      .FireSelfInGroup([2])
      .ThinksPassively;
    TWelaTriggerCheckTakeDamageThresholdComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Shieldblock')
      .TriggerOnFire;
  {$ENDIF}

  TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], True);

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/footman/attack')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\shield_block.pfx', 1.7)
      .ActivateOnCreate()
      .ScaleWith(eiCollisionRadius)
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1])
      .VisibleWithWelaReady();

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\footman_shield_block_trigger.pfx', 1.0)
      .ActivateOnFire()
      .IgnoreModelSize
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/white/effect/shield_block')
      .TriggerOnFire();
  {$ENDIF}
end;








