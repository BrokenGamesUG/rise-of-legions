{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.Blackboard.SetValue(eiSpeed, [], (4.25 / 1000));
  Entity.CollisionRadius := 0.5;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upFlying, upNoAutoAttack, upSupporter, upFollower]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}260.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}260.0);

  // wait if enemy is near in range
  Entity.Blackboard.SetValue(eiAttentionrange, [0], 10.0);

  // Projectile Reflection-Aura
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2, 3], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [2, 3], 'Links\ProjectileReflectorAura');
  Entity.Blackboard.SetValue(eiWelaRange, [2, 3], 7.0);
  Entity.Blackboard.SetValue(eiWelaActive, [2], False);

  // Reflection feedback damage
  Entity.Blackboard.SetValue(eiDamageType, [5], [dtTrue, dtIgnoreArmor]);
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 10.0);

  // follow allied units nearby
  Entity.Blackboard.SetValue(eiAttentionrange, [6], 10.0);
  Entity.Blackboard.SetValue(eiWelaRange, [6], 2.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Pacifist');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'ReflectiveShield')
      .PassPercentage('reflected_damage_percentage', 40, 'damage')
      .PassInteger('self_damage_amount', 10, 'damage');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 1.0, 0), RVector3.Create(0, 1.5, 0.0), 0.6);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\ShieldDrone\ShieldDrone.xml')
      .ApplyLegacySizeFactor
      .BindZoneToBone(BIND_ZONE_CENTER, 'ShielddroneCore')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'ShielddroneCore')
      .BindZoneToBone('engine_left', 'ShielddroneEngineLeft')
      .BoneSwapXY('engine_left')
      .BoneOffset('engine_left', 0, 0, -0.4)
      .BindZoneToBone('engine_right', 'ShielddroneEngineRight')
      .BoneSwapXY('engine_right')
      .BoneOffset('engine_right', 0, 0, -0.4);

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.9], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TBrainFollowComponent.CreateGrouped(Entity, [6]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [6])
      .RangeFromEvent(eiAttentionRange)
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [6]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [6])
      .MustHaveAny([upUnit])
      .MustNotHave([upBuilding, upInvisible, upFollower]);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [6])
      .Prioritize([upMelee]);

    TBrainWaitComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upInvisible]);

    TWelaHelperActivateTimerComponent.CreateGrouped(Entity, [2])
      .Delay(1000);
    TBrainWelaLinkComponent.CreateGrouped(Entity, [2]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetValidateGroup([3]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upProjectileReflector, upBase]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [2, 3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 3])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upBase]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [2, 3])
      .CreatorGroup([4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('ReflectiveShield')
      .TriggerOnFire;
    TWelaEffectFireComponent.CreateGrouped(Entity, [4])
      .TargetGroup([5])
      .RedirectToSelf;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [5]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerRotationComponent.CreateGrouped(Entity, [])
      .Radius(0.1)
      .RotationSpeed(0, 0, 0.75 * PI)
      .Factor(0, 1, 0)
      .Phase(random)
      .FadeIn(1500);

    TPositionerRotationComponent.CreateGrouped(Entity, [])
      .Radius(0.025)
      .RotationSpeed(0.45 * PI, 0.55 * PI, 0.65 * PI)
      .Factor(1, 0, 1)
      .Phase(random)
      .FadeIn(1500);

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\flight_engine.pfx', 1.0)
      .ActivateOnCreate
      .Delay(1000)
      .BindToSubPosition('engine_right');

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\flight_engine.pfx', 1.0)
      .ActivateOnCreate
      .Delay(1000)
      .BindToSubPosition('engine_left');

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\shielddrone_aura_field.pfx', 5.0)
      .ActivateOnCreate
      .ActivateOnWelaActivate
      .FixedOrientationDefault
      .FixedHeightGround
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\blue_border_wide.pfx', 5.0)
      .IgnoreModelSize
      .ActivateOnCreate
      .ActivateOnWelaActivate
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TParticleEffectComponent.CreateGrouped(Entity, [4], '\Blue\projectile_reflector_feedback.pfx', 1.1)
      .ActivateOnFire
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);
  {$ENDIF}
end;
