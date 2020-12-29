{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, True);
  Entity.CollisionRadius := 0.55;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upGround, upBuilding, upNoAutoAttack]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}84.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}84.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 5);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 10);

  // summon 2 saplings
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 5);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Units\Green\Sapling');
  Entity.Blackboard.SetValue(eiWelaCount, [2], 3);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 500);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 1366);

  // Mana-Reg
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [3], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'GrowSaplings')
      .Keyword('Sapling')
      .Keyword('Timed')
      .PassInteger('energy_cost', 5, 'energy')
      .PassInteger('sapling_count', 3);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
{$IFDEF CLIENT}
var MeshComponent : TMeshComponent;
{$ENDIF}
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0.7,0), 1.2);

    MeshComponent := TMeshComponent.CreateGrouped(Entity, [0, 1, 2], 'Units\Green\SaplingFarm' + Entity.SkinFileSuffix + '\SaplingFarm.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 50);

    if Entity.SkinID = SKIN_GROUP_SNOW then
      MeshComponent.CreateNewAnimation(ANIMATION_ATTACK, 50, 90)
    else
    begin
      MeshComponent.CreateNewAnimation(ANIMATION_ATTACK, 60, 100);
      MeshComponent.FixedOrientation(1, 0, 0);
    end;

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2]);

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, True);

  {$IFDEF SERVER}
    // summon saplings
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [2])
      .Blocking();
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [2])
      .SpreadSpawns();
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [2])
      .SetCheckGroup([])
      .CheckNotFull(reMana)
      .SetsActive()
      .SetActivationGroup([3]);

    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [GROUP_BUILDING_LIFETIME])
      .Name('SaplingFarmTimeout')
      .TriggerOnDie;

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
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .FixedCap(5)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/green/unit/sapling_farm/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Green\sapling_farm_attack' + Entity.SkinFileSuffix + '.pfx', 2.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);
  {$ENDIF}
end;
