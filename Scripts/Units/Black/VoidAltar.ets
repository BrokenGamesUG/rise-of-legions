{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, True);
  Entity.CollisionRadius := 0.9;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upGround, upBuilding, upRanged, upSoulDonor, upSoulGatherer, upNoAutoAttack, upSupporter]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}115.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}115.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 10);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Soul Vortex - extract souls in a huge range
  Entity.Blackboard.SetValue(eiWelaRange, [2], 40.0);
  Entity.Blackboard.SetValue(eiCooldown, [2], 3000);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Black\SoulGatherProjectile');
  Entity.Blackboard.SetValue(eiWelaDamage, [2, 3], 1.0);

  // Soul Donor - give nearby allied units saved souls
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [4], reMana, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [4], 12.0);
  Entity.Blackboard.SetValue(eiCooldown, [4], 1000);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [4], 'Projectiles\Black\SoulDonorProjectile');
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 1.0);
  Entity.Blackboard.SetValue(eiDamageType, [4], [dtIrredirectable]);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'SoulGatherer')
      .PassInteger('energy_amount', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'SoulVortex')
      .Keyword('Annihilated')
      .PassInteger('health_threshold', 60, 'health')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'SoulDonor')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 1);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 1);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 6);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,2.6,0), 1.2);

    TMeshComponent.CreateGrouped(Entity, [0, 1, 2], 'Units\Black\VoidAltar\VoidAltar.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 200)
      .BindZoneToBone(BIND_ZONE_CENTER, 'GeoSphere001')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'GeoSphere001');

    TMeshEffectWobble.Create(PATH_GRAPHICS + 'Units\Black\VoidAltar\VoidAltarVoidMask.tga')
      .AssignToEntity(Entity);
    TMeshEffectMatCap.Create()
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapVoid.png')
      .AssignToEntity(Entity);

    TAnimationComponent.CreateGrouped(Entity, [1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.95], [0]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [2])
      .SetTexture('SpelltargetShootingRange.png');
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [4])
      .SetTexture('SpelltargetGeneric.png');
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [GROUP_SOUL])
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, True);

  {$IFDEF SERVER}
    // Soul vortex
    TBrainWelaFightComponent.CreateGrouped(Entity, [2]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies)
      .PicksRandomTargets();
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [2])
      .CheckResource(reHealth)
      .Comparator(coLowerEqual)
      .Reference(60.0)
      .CompareCapToReference();
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit])
      .MustNotHave([upBase, upLegendary, upBanished, upInvisible]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2])
      .Reverse;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [2])
      .Exile;

    // Soul donor
    TBrainWelaFightComponent.CreateGrouped(Entity, [4]);
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upSilenced]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [4], true);
    TWelaReadyCostComponent.CreateGrouped(Entity, [4])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [4])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .SetTargetTeamConstraint(tcAllies)
      .PicksRandomTargets();
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upSoulDonor]);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [4])
      .CheckResource(reMana)
      .CheckNotFull();
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('SoulDonor')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Black\voidaltar_attack.pfx', 0.85)
      .ActivateOnFire()
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Black\void_altar_soul_vortex.pfx', 1.0)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_HIT_ZONE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/black/building/voidaltar/soul_vortex')
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/black/building/voidaltar/soul_vortex_impact')
      .UsePositionOfTarget
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/shared/effect/annihilate')
      .UsePositionOfTarget
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [4], 'event:/card/shared/effect/energy_donor')
      .TriggerOnFire();
  {$ENDIF}
end;
