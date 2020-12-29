{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upGround, upBuilding, upGadget, upSoulDonor, upNoAutoAttack, upSupporter]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}295.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}295.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 4);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 4);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 1);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2], 1);
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtIrredirectable]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 1.0);
  Entity.Blackboard.SetValue(eiWelaRange, [2], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Blue\AmmoFactoryProjectile');
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 1033);

  // energy regeneration
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [3], 3000);

  // limited
  Entity.Blackboard.SetValue(eiWelaDamage, [4, 5], 1.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'LimitedGadget')
      .PassInteger('gadget_limit', 5)
      .PassInteger('gadget_limit_exceeded', 6);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'AmmoTransfer')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 7);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0.7,0), 0.9);

    TMeshComponent.CreateGrouped(Entity, [3], 'Units\Blue\TurretBase\TurretBase.xml')
      .ApplyLegacySizeFactor;
    TMeshComponent.CreateGrouped(Entity, [0, 1, 2], 'Units\Blue\AmmoFactory\AmmoFactory.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 30)
      .BindZoneToBone(BIND_ZONE_CENTER, 'CATRigHub001Bone002')
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'CATRigHub001Bone002')
      .BoneSwapXY(BIND_ZONE_WEAPON_MUZZLE)
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneOffset(BIND_ZONE_WEAPON_MUZZLE, 0, -0.8, 0);

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.0], [0, 1, 2, 3]);
    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [2])
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);

  {$IFDEF SERVER}
    // give nearby allies mana
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .DisableTargetLock()
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [2]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upBanished, upSoulDonor]);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [2])
      .CheckResource(reMana)
      .CheckNotFull();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcAllies)
      .PicksRandomTargets;
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('AmmoTransfer')
      .TriggerOnFire;
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [2])
      .SetCheckGroup([])
      .CheckNotFull(reMana)
      .SetsActive()
      .SetActivationGroup([3]);

    // regenerate mana over time
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [3])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [3], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reMana)
      .TargetGroup([]);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [3])
      .SetCheckGroup([])
      .TriggerOnReachResourceCap(reMana);

    // take a gadget slot in commander on creation
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [4])
      .FireAtCommander;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [4])
      .SetResourceType(reGadgetCount);
    // release a gadget slot in commander on death
    TAutoBrainOnDeathComponent.CreateGrouped(Entity, [5])
      .FireAtCommander
      .ThinksPassively
      .ThinksInExile;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [5])
      .SetResourceType(reGadgetCount)
      .SetFactor(-1.0);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\ammo_factory_fire.pfx', 2.4)
      .ActivateOnFire
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/blue/unit/ammo_factory/attack_fire')
      .TriggerOnPreFire;
  {$ENDIF}
end;
