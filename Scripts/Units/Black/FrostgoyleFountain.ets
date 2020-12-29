{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, True);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upGround, upBuilding, upSoulGatherer, upNoAutoAttack]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}475.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}475.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 8);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 0);

  // Summon Frostgoyle
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 4);
  Entity.Blackboard.SetValue(eiCooldown, [2], 3000);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Units\Black\Frostgoyle');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'SoulGatherer')
      .PassInteger('energy_amount', 1, 'energy');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'SoulGathererSummonFrostgoyle')
      .Keyword('Timed')
      .PassInteger('energy_cost', 4, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0), RVector3.Create(0, 2.0, 0), 1.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\FrostgoyleFountain\FrostgoyleFountain.xml')
      .ApplyLegacySizeFactor;
    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Black\FrostgoyleFountain\FrostgoyleFountainFrostgoyle.xml')
      .ApplyLegacySizeFactor
      .BindZoneToBone(BIND_ZONE_CENTER, 'CatRigHub002');
    TAnimationComponent.CreateGrouped(Entity, [1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.1], [0, 1, 2]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [GROUP_SOUL])
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, True);

  {$IFDEF SERVER}
    // spawn Frostgoyle if enough souls are reached
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [2])
      .ThinksPassively;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], true);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('SoulGathererSummonFrostgoyle')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('SoulGathererSummonFrostgoyleFourTimes')
      .CheckNth(4)
      .TriggerOnFire;
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [2]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(660)
    .ApplyToProducedUnits();
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\TimedLife.dws')
    .ApplyToProducedUnits;

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Black\frostgoyle_fountain_attack.pfx', 0.8)
      .ActivateOnFire
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [2]);

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetRotationLight
      .ActivateOnFire;

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetVectorLight
      .ActivateOnFire;

    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/black/building/frostgoylefountain/trigger')
      .TriggerOnFire();
  {$ENDIF}
end;
