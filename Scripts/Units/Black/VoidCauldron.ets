{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upRanged, upSoulGatherer, upHasDeathRattle]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atHeavy);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}285.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}285.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 15);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}3.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Black\VoidCauldronProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}60.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 200);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 500);

  Entity.Blackboard.SetValue(eiWelaRange, [2], 14.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Black\VoidCauldronBuildingBlastProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtRanged, dtSiege, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 15.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2], 0); // + Modifier
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 1); // x Mana = TargetCount

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Siege');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'SoulGatherer')
      .PassInteger('energy_amount', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'DeathRattleBlast')
      .PassInteger('damage_amount', 15, 'damage')
      .PassInteger('energy_cost', 1, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 3);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.4,0), 0.75);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidCauldron\VoidCauldron.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 15, 73)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 14)
      .CreateNewAnimation(ANIMATION_STAND, 15, 73)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_WEAPON, 'VoidcauldronHub')
      .BoneSwapXY(BIND_ZONE_WEAPON)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'VoidcauldronHub')
      .BoneSwapXY(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_CENTER, 'VoidcauldronSpine2')
      .BoneSwapXY(BIND_ZONE_CENTER);
    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.2], [0]);
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

    // ranged-attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    // fires soul-scaling-projectile at nearest enemy building on death
    TAutoBrainOnBeforeDeath.CreateGrouped(Entity, [2])
      .FireAtTarget();
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    // only fire if at least one soul was collected
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [2])
      .ComparedResource(reMana)
      .CheckNotEmpty;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies)
      .PicksRandomTargetsWithRepetition();
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upInvisible, upBanished])
      .MustHave([upBuilding]);
    TModifierWelaTargetCountComponent.CreateGrouped(Entity, [2])
      .ScaleWithResource(reMana);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('DeathRattle')
      .Name('DeathRattleBlast')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('BuildingBlastMax')
      .CheckResourceMax(reMana)
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Black\voidcauldron_idle.pfx', 1.0)
      .ActivateOnCreate
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/voidcauldron/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Black\voidcauldron_building_blast_cast.pfx', 1.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetRotationMedium
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetVectorMedium
      .ActivateOnFire;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/black/unit/voidcauldron/blast_cast')
      .TriggerOnFire();
  {$ENDIF}
end;
