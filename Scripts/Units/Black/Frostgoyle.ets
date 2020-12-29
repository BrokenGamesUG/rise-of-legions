{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.7;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upMelee, upFlying]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}155.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}155.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}75.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}3600);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 700);

  // Relentless: Frozen
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 1.5); // 150% damage against state effect
  Entity.Blackboard.SetValue(eiWelaModifier, [3], 2.0); // 200% damage against frozen

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2, 3], 'RelentlessFrozen')
      .Keyword('Frozen')
      .Keyword('StateEffect')
      .PassPercentage('primary_damage_amount_percentage', 200, 'damage')
      .PassPercentage('secondary_damage_amount_percentage', 150, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'Fury');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 1);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,2.4,0.5), RVector3.Create(0,1.6,-0.2), 0.7);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);
    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\FrostGoyle\FrostGoyle.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_SPAWN, 0, 20)
      .CreateNewAnimation(ANIMATION_WALK, 21, 50)
      .CreateNewAnimation(ANIMATION_ATTACK, 52, 72)   // vs ground
      .CreateNewAnimation(ANIMATION_ATTACK_AIR, 73, 93) // vs air
      .CreateNewAnimation(ANIMATION_STAND, 21, 50)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'FrostgoyleSpine3')
      .BindZoneToBone(BIND_ZONE_HEAD, 'FrostgoyleHub003')
      .SetModelOffset(RVector3.Create(0, -0.8, 0));

    TAnimationComponent.CreateGrouped(Entity, [0, 1])
      .HasAntiAirAttack;
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.1], [0]);
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

    // melee
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    // fury - reset if enemy is at full health
    TWelaEffectFireComponent.CreateGrouped(Entity, [1])
      .TargetGroup([4]);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [4])
      .CheckResource(reHealth)
      .CheckFull;
    TWelaEffectFireComponent.CreateGrouped(Entity, [4])
      .TargetGroup([5])
      .RedirectToSelf;
    TWelaEffectResetCooldownComponent.CreateGrouped(Entity, [5])
      .TargetGroup([1])
      .Expire;
    // damage
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .Name('Flying')
      .TriggerOnDie
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
  {$ENDIF}

  {$IFDEF CLIENT}
    TVertexTraceComponent.CreateGrouped(Entity, [1])
      .Texture('Effects\Textures\ShadowTrace.tga')
      .Color($FFFFFFFF)
      .Width(1.0)
      .SamplingDistance(0.3)
      .FadeLength(4.0)
      .MaxLength(6.0)
      .TexturePerDistance(4.0)
      .RollUpSpeed(16)
      .ActivateOnFire()
      .DeactivateAfterTime(666)
      .DeactivateOnMoveTo()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);;

    TParticleEffectComponent.CreateGrouped(Entity, [5], '\Black\frostgoyle_fury.pfx', 1.1)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [5])
      .TargetGroup([])
      .ActivateOnFire
      .SetEffect(
        TMeshEffectSoulGain.Create(400)
          .Color($40FF0000)
          .Radius(0.5)
          .AddKey(0, 0.0)
          .AddKey(400, 1.0)
          .Additive
      );

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/frostgoyle/attack_ground_fire')
      .TriggerOnPreFire()
      .StopOnFree
      .CheckGroup([6]);

    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [6])
      .MustNotHave([upFlying]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/frostgoyle/attack_air_fire')
      .TriggerOnPreFire()
      .StopOnFree
      .CheckGroup([7]);

    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [7])
      .BothMustHaveAny([upGround, upFlying]);

    TSoundComponent.CreateGrouped(Entity, [5], 'event:/card/black/unit/frostgoyle/fury_trigger')
      .TriggerOnFire();
  {$ENDIF}
end;


