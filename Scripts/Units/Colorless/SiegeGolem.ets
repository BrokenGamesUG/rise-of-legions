{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.9;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upMelee, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}270.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}270.0);

  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 100);

  // Melee-Attack
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}52.0);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 0.5 + {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2300);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 633);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1033);

  // Charge
  Entity.Blackboard.SetValue(eiWelaRange, [2], 20.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 5.0);
  Entity.Blackboard.SetValue(eiCooldown, [2], 500);

  // Charge-Siege-Attack
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [3], reWelaCharge, 100);
  Entity.Blackboard.SetValue(eiWelaRange, [3], 21.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [3], 'Projectiles\Colorless\SiegeGolemProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [3], [dtRanged, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 50.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [3], 250);
  Entity.Blackboard.SetValue(eiWelaActionduration, [3], 833);

  // Empty charges at walking
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [4], reWelaCharge, 1);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Siege');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'CrystalArtillery')
      .PassInteger('damage_amount', 50, 'damage')
      .PassInteger('charge_duration', 10);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 3);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0.1), RVector3.Create(0,0.9,0.1), 1.3);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\SiegeGolem\SiegeGolem.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 19, 79)
      .CreateNewAnimation(ANIMATION_ATTACK, 206, 236)
      .CreateNewAnimation(ANIMATION_ATTACK2, 181, 205)
      .CreateNewAnimation(ANIMATION_WALK, 0, 18)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_WEAPON, 'SiegeGolemPelvis')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'SiegeGolemPelvis')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE);

    TOrienterTargetComponent.CreateGrouped(Entity, [0, 1, 2, 3]);

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 3])
      .SecondAttackGroup([3]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.3], [0]);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Colorless\SharedCrystal\Crystal.xml')
      .IgnoreScalingForAnimations
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .FixedOrientationDefault
      .BindToSubPositionGroup('BoneC', [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystalNeutral.png')
      );

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.7], [2]);
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

    // melee attack, empties all charges if used
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
      .ConsumesAll()
      .SetPayingGroupForType(reWelaCharge, []);

    // charging if building is in range and charges are not full
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .ChangeTargetToMyself
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], true);
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [2])
      .ComparedResource(reWelaCharge)
      .CheckNotFull();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 2, 3], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 2, 3])
      .MustHave([upBuilding])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [2])
      .SetResourceType(reWelaCharge);

    // attacking building in range if charges are full
    TBrainWelaFightComponent.CreateGrouped(Entity, [3])
      .Blocking;
    TWelaReadyCostComponent.CreateGrouped(Entity, [3])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [3]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [3])
      .ConsumesAll()
      .SetPayingGroupForType(reWelaCharge, []);

    // if no melee nor charging nor attacking we are walking and so empty all charges
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [4]);
    TAutoBrainOnUnitPropertyComponent.CreateGrouped(Entity, [4])
      .TriggerOn([upFrozen, upStunned, upBanished]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [4])
      .ConsumesAll()
      .SetPayingGroupForType(reWelaCharge, []);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayProgressBarComponent.Create(Entity)
      .ShowResource(reWelaCharge)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/siege_golem/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Colorless\siege_golem_artillery_charge.pfx', 1.5)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [1, 2, 3, 4], 'event:/card/colorless/unit/siege_golem/crystal_artillery_charge')
      .IsLoop
      .TriggerOnFire
      .StopGroup([1, 3, 4])
      .StopOnFire
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Colorless\siege_golem_artillery_cast.pfx', 1.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetVectorLight
      .ActivateOnFire;

    TSoundComponent.CreateGrouped(Entity, [3], 'event:/card/colorless/unit/siege_golem/crystal_artillery_fire')
      .TriggerOnFire();
  {$ENDIF}
end;


