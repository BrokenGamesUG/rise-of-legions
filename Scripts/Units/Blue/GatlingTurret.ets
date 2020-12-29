{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upGround, upBuilding, upRanged, upImmuneToBlinded, upLinkWeapon, upGadget]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}230.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}230.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 20);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 20);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reMana, 1); // per second of established link
  Entity.Blackboard.SetValue(eiWelaRange, [1], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiLinkPattern, [0, 1], 'Links\GatlingTowerLink');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}500);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}15.0);

  // limited
  Entity.Blackboard.SetValue(eiWelaDamage, [3, 4], 1.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'LimitedGadget')
      .PassInteger('gadget_limit', 5)
      .PassInteger('gadget_limit_exceeded', 6);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Ammo')
      .PassInteger('energy_cost', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'SearchingFire')
      .PassInteger('damage_amount', 3, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Surefire')
      .Keyword('Blinded');

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

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\GatlingTurret' + Entity.SkinFileSuffix + '\GatlingTurret.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 30)
      .CreateNewAnimation(ANIMATION_ATTACK_LOOP, 0, 30)
      .HasAttackLoop
      .BindZoneToBone(BIND_ZONE_CENTER, 'center')
      .BoneOffset(BIND_ZONE_CENTER, 0, -0.2, -0.1)
      .BindZoneToBone(BIND_ZONE_HEAD, 'head')
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.1, 0.2)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'attackBone')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE);
    TMeshComponent.CreateGrouped(Entity, [3], 'Units\Blue\TurretBase' + Entity.SkinFileSuffix + '\TurretBase.xml')
      .ApplyLegacySizeFactor
      .FixedOrientationDefault;

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.0], [0, 1, 2, 3]);
    TAnimationComponent.CreateGrouped(Entity, [1])
      .IsLink;

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetShootingRange.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);

  {$IFDEF SERVER}
    TBrainWelaLinkComponent.CreateGrouped(Entity, [1])
      .LinkTime(500)
      .Preemptive;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upSilenced]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [0, 1]);
    // every link costs per second of uptime
    TWelaEffectLinkPayCostMyselfComponentServer.CreateGrouped(Entity, [1])
      .FireOnEmpty([2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('AmmoEmpty')
      .CheckResourceEmpty(reMana)
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('GatlingTurretRanged')
      .TriggerOnKill
      .CheckUnitPropertyMustHave([upRanged]);

    // take a gadget slot in commander on creation
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [3])
      .FireAtCommander;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [3])
      .SetResourceType(reGadgetCount);
    // release a gadget slot in commander on death
    TAutoBrainOnDeathComponent.CreateGrouped(Entity, [4])
      .FireAtCommander
      .ThinksPassively
      .ThinksInExile;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [4])
      .SetResourceType(reGadgetCount)
      .SetFactor(-1.0);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana);

    TOrienterTargetComponent.CreateGrouped(Entity, [1])
      .KeepLastFront;
    //TOrienterSmoothRotateComponent.CreateGrouped(Entity, [1])
    //  .SetAngleSpeed(0.002);
  {$ENDIF}
end;
