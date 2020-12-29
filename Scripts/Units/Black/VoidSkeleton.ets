{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upMelee, upHasUndying, upSoulGatherer]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}105.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}105.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 1);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Claw-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}16.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 266);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 933);

  // Relentless: Frozen
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 1.5); // 150% damage against movement impaired
  Entity.Blackboard.SetValue(eiWelaModifier, [3], 2.0); // 200% damage against frozen

  // Soul gatherer : undying
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [4], reMana, 1);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'SoulGatherer')
      .PassInteger('energy_amount', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2, 3], 'RelentlessFrozen')
      .Keyword('Frozen')
      .Keyword('StateEffect')
      .PassPercentage('primary_damage_amount_percentage', 200, 'damage')
      .PassPercentage('secondary_damage_amount_percentage', 150, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'SoulGathererUndying')
      .PassInteger('duration', 15);

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.0,0), 0.65);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidSkeleton' + Entity.SkinFileSuffix + '\VoidSkeleton.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 26)
      .CreateNewAnimation(ANIMATION_ATTACK, 27, 54)
      .CreateNewAnimation(ANIMATION_STAND, 55, 115)
      .BindZoneToBone(BIND_ZONE_CENTER, 'SkeletonSpine3')
      .BindZoneToBone(BIND_ZONE_HEAD, 'SkeletonHead')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'SkeletonLDigit21');

    if Entity.SkinID = SKIN_GROUP_CRUSADER then
    begin
      TMeshEffectMetal.Create()
        .ShowAsColor(ecWhite)
        .AssignToEntity(Entity);
    end;

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.05], [0]);
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('RelentlessFrozen')
      .CheckUnitPropertyMustHave([upFrozen])
      .TriggerOnKillDone;

    // extra damage
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [1])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([2]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHaveAny([upStunned, upBlinded, upRooted, upGrounded, upLifted, upBleeding, upPetrified])
      .MustNotHave([upFrozen]);
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [1])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustHave([upFrozen]);

    // undying
    TAutoBrainPreventDeathComponent.CreateGrouped(Entity, [4]);
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upSilenced, upRescued]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [4])
      .SetPayingGroup([]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('SoulConsumed')
      .TriggerOnFire;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('SoulgathererUndying')
      .TriggerOnFire;
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [4])
      .TargetGroup([4]);
  {$ENDIF}

  // make undying
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [4], 'Modifiers\Undying.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/voidskeleton/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Black\voidskeleton' + Entity.SkinFileSuffix + '_attack.pfx', 3.0)
      .ActivateOnFireDelayed(100);

    TPositionerOffsetComponent.CreateGrouped(Entity, [4])
      .Offset(0, 0.3, 0);
    TPositionerRotationComponent.CreateGrouped(Entity, [4])
      .Radius(0.1)
      .RadiusFromEvent(eiCollisionRadius)
      .RotationSpeed(0, -2 * PI, 0);
    TVertexTraceComponent.CreateGrouped(Entity, [4])
      .Texture('Effects\Textures\SoulGatherTrace.tga')
      .Color($80FFFFFF)
      .Width(0.4)
      .SamplingDistance(0.3)
      .FadeLength(2.5)
      .MaxLength(3.0)
      .TexturePerDistance(2.0)
      .LocalSpace
      .ActivateNow
      .IsPiece
      .VisibleWithResource(reMana);
  {$ENDIF}
end;
