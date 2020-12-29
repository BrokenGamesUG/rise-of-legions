{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.85;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}64.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}64.0);

  // Ranged-Attack (Ground-only)
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}14.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\White\BallistaProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}23.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 0.1);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 0);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1166);

  // extended range while in air
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 5.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'NotHoming')
      .PassInteger('range_amount', 5, 'range');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Siege');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Lightovercharge')
      .PassInteger('target_count', 4)
      .PassInteger('heal_amount', 5, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0.9,0.4), 1.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\White\Ballista\Ballista.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_WALK, 0, 40)
      .CreateNewAnimation(ANIMATION_ATTACK, 41, 75)
      .BindZoneToBone(BIND_ZONE_HEAD, 'BallistaHead')
      .BoneSwizzleYZX(BIND_ZONE_HEAD)
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.6, 0.1)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'attack_bone')
      .BoneOffset(BIND_ZONE_WEAPON_MUZZLE, 0, 0.7, 0.6)
      .BoneRotation(BIND_ZONE_WEAPON_MUZZLE, 0.1, 0, 0);

    TMeshEffectMetal.Create().AssignToEntity(Entity);
    TAnimationComponent.CreateGrouped(Entity, [0, 1])
      .SetAnimationSpeed(eiFire, 1000);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.9], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .DisableStraightPreference()
      .SetTargetTeamConstraint(tcEnemies);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    // Ground-Only
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustHave([upGround])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
    .MustHave([upFlying]);
  TModifierWelaRangeComponent.CreateGrouped(Entity, [1])
    .AddModifier
    .SetValueGroup([2])
    .ReadyGroup([2]);

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/ballista/attack_fire')
      .TriggerOnFire()
      .StopOnFree;
  {$ENDIF}
end;


