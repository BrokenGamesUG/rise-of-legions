{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upMelee, upGround]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}41.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}41.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 2);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee, dtSiege]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}11.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1500);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 900);

  // DampingShield
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 0.3);

  // BreachingCharge
  Entity.Blackboard.SetValue(eiWelaRange, [3], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [3], [dtSiege, dtSplash, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 20.0);
  Entity.Blackboard.SetValue(eiWelaModifier, [3], 15.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [3], 1.5);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Siege');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'DampingShield')
      .PassPercentage('damage_reduction_percentage', 30);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'BreachingCharge')
      .PassInteger('damage_amount', 20, 'damage')
      .PassInteger('damage_amount_per_energy', 15, 'damage');

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0.6,0), 0.55);

    MeshComponent := TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\DamperDrone' + Entity.SkinFileSuffix + '\DamperDrone.xml');
    if Entity.SkinID = SKIN_GROUP_POPULAR then
      MeshComponent.DeathColorIdentityOverride(ecRed);
    MeshComponent
      .ApplyLegacySizeFactor
      .IgnoreScalingForAnimations
      .CreateNewAnimation(ANIMATION_STAND, 201, 300)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 26)
      .CreateNewAnimation(ANIMATION_WALK, 28, 65)
      .BindZoneToBone(BIND_ZONE_CENTER, 'DamperdroneHead')
      .BoneSwizzleYZX(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_HEAD, 'DamperdroneHead')
      .BoneSwizzleYZX(BIND_ZONE_HEAD)
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.15, 0.25)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'DamperdroneHead')
      .BoneSwizzleYZX(BIND_ZONE_WEAPON)
      .BoneOffset(BIND_ZONE_WEAPON, 0, 0.2, 0.2)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'DamperdroneHead')
      .BoneSwizzleYZX(BIND_ZONE_WEAPON_MUZZLE)
      .BoneOffset(BIND_ZONE_WEAPON_MUZZLE, 0, 0, 0.3);

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.7], [0]);
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

    // breaching charge
    TBrainWelaFightComponent.CreateGrouped(Entity, [3])
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upSilenced]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [3, 4], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [3, 4])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustHave([upBuilding])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [3])
      .SetValidateGroup([4]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('BreachingCharge')
      .Name('Siege')
      .Name('Splash')
      .TriggerOnDamageDone
      .TriggerOnFire;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [3]);

    // auto attack
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

    // splash damage reduction
    TBuffTakenDamageMultiplierComponent.CreateGrouped(Entity, [2])
      .DamageTypeMustHave([dtSplash]);
  {$ENDIF}

  // breaching charge damage boost
  TModifierWelaDamageComponent.CreateGrouped(Entity, [3])
    .ScaleWithResource(reMana)
    .ResourceGroup([]);

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/blue/unit/damperdrone/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\damper_drone' + Entity.SkinFileSuffix + '_attack.pfx', 0.8)
      .ActivateOnFire
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);


    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Blue\damper_drone' + Entity.SkinFileSuffix + '_breaching_charge_fire.pfx', 0.9)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [3])
      .PresetVectorLight
      .ActivateOnFire;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Blue\blue_border_wide_once.pfx', 5.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [3], 'event:/card/blue/unit/damperdrone/breaching_charge_fire')
      .TriggerOnFire;
  {$ENDIF}
end;








