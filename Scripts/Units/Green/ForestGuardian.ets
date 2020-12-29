{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, True);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upGround, upBuilding, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}335.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}335.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], {@UBL_Range}11.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1, 2], 'Projectiles\Green\ForestGuardianProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1, 2], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtSplash, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}32.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1, 2], 2.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1, 2], 880);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1, 2], 1933);

  // Hail of Stones
  Entity.Blackboard.SetValue(eiWelaRange, [2], 24.0);
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtRanged, dtSplash, dtSiege, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 0.5 * {@UBL_Damage}32.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Siege');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'HailOfStones')
      .PassPercentage('damage_reduction_percentage', 50, 'damage');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 3);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,-0.1), RVector3.Create(0,2.5,-0.1), 1.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\ForestGuardian' + Entity.SkinFileSuffix + '\ForestGuardian.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 57)
      .CreateNewAnimation(ANIMATION_STAND, 120, 239)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'GuardianSpine5')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'GuardianRArmRDigit21')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'GuardianPalmStone')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_HEAD, 'GuardianHead')
      .BoneSwizzleYZX(BIND_ZONE_HEAD)
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.2, 0.3);
    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.8], [0]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetShootingRange.png')
      .ShowWeaponRange();
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [2])
      .SetTexture('SpelltargetShootingRange.png')
      .ShowWeaponRange();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, True);

  {$IFDEF SERVER}
    // Auto-Attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], True);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1, 2], True);

    // Hail of Stones
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upInvisible, upBanished])
      .MustHave([upBuilding]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('HailOfStones')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1, 2], 'event:/card/green/unit/forest_guardian/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TOrienterTargetComponent.CreateGrouped(Entity, [1, 2]);
  {$ENDIF}
end;
