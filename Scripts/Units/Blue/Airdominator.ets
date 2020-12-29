{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upRanged, upRangedGroundOnly, upFlying]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}120.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}120.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], {@UBL_Range}15.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Blue\AirdominatorMissile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}25.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 2.5);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 333);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 833);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.Create(Entity, 'Flying');
    TTooltipUnitAbilityComponent.Create(Entity, 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'AntiAir')
      .PassPercentage('primary_damage_amount_percentage', 200, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');

    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, -0.4);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,1.0,0.1), RVector3.Create(0,1.2,-0.2), 0.9);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\Airdominator\Airdominator.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_WALK, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 24)
      .BindZoneToBone(BIND_ZONE_CENTER, 'AirdominatorHub001')
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BoneSwapXZ(BIND_ZONE_CENTER)
      .BoneOffset(BIND_ZONE_CENTER, 0, 0, 0.2)
      .BindZoneToBone(BIND_ZONE_TOP, 'AirdominatorHub001')
      .BoneSwapXY(BIND_ZONE_TOP)
      .BoneSwapXZ(BIND_ZONE_TOP)
      .BoneOffset(BIND_ZONE_TOP, 0, 0.4, 0.2)
      .BindZoneToBone(BIND_ZONE_HEAD, 'AirdominatorHub001')
      .BoneSwapXY(BIND_ZONE_HEAD)
      .BoneSwapXZ(BIND_ZONE_HEAD)
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.1, 0.55)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE + '0', 'AirdominatorMuzzleLeft') // rocket left
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE + '0')
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE + '0')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE + '1', 'AirdominatorMuzzleRight') // rocket right
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE + '1')
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE + '1')
      .AlternatingZone(BIND_ZONE_WEAPON_MUZZLE, 2)
      .BindZoneToBone('eninge_left', 'AirdominatorEngineLeftAngle')
      .BoneSwapXY('eninge_left')
      .BoneOffset('eninge_left', 0.05, 0.15, 0.0)
      .BoneRotation('eninge_left', -0.175, 0.35, -0.15)
      .BindZoneToBone('eninge_right', 'AirdominatorEngineRightAngle')
      .BoneSwapXY('eninge_right')
      .BoneInvertZ('eninge_right')
      .BoneOffset('eninge_right', 0.05, 0.15, 0.0)
      .BoneRotation('eninge_right', -0.175, 0.35, -0.15);

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.9], [0]);
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
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], True);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [1])
      .Prioritize([upFlying, upMonumental]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/blue/unit/airdominator/attack_fire')
      .TriggerOnFire;

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
      .BindToSubPosition('eninge_left');

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\flight_engine.pfx', 1.0)
      .ActivateOnCreate
      .BindToSubPosition('eninge_right');
  {$ENDIF}
end;


