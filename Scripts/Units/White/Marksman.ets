{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}28.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}28.0);

  // Ranged-Attack (only Air, see below)
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}13.5);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\White\MarksmanProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}5000);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}190.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 733);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1166);

  // Steady Aim
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 6.0);
  Entity.Blackboard.SetValue(eiCooldown, [2], 10000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'SteadyAim')
      .PassString('range_increase', '+6', 'range')
      .PassInteger('duration', 10);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'BigGameHunter');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 10);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.2,0), 0.6);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\White\Marksman' + Entity.SkinFileSuffix + '\Marksman.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 56, 116)
      .CreateNewAnimation(ANIMATION_WALK, 0, 20)
      .CreateNewAnimation(ANIMATION_ATTACK, 21, 55)
      .SetAnimationSpeed(ANIMATION_WALK, 0.91)
      .BindZoneToBone(BIND_ZONE_CENTER, 'MarksmanSpine4')
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'MarksmanWeapon_muzzle')
      .BoneSwapXZ(BIND_ZONE_WEAPON)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'MarksmanWeapon_muzzle')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_HEAD, 'MarksmanHead');
    TMeshEffectMetal.Create()
      .AssignToEntity(Entity);

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
    TWelaEfficiencyMaxHealthComponent.CreateGrouped(Entity, [1]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('SteadyAimBuilding')
      .CheckUnitPropertyMustHave([upBuilding])
      .TriggerOnFire;
  {$ENDIF}

  TModifierWelaRangeComponent.CreateGrouped(Entity, [1])
    .AddModifier
    .ScaleWithTime
    .ActivateOnStand
    .DeactivateOnMoveTo
    .SetValueGroup([2]);

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/marksman/attack_fire')
      .TriggerOnFire
      .StopOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .PresetVectorLight
      .ActivateOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\marksman_muzzle_flash.pfx', 1.0)
      .ActivateOnFire
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);
  {$ENDIF}
end;


