{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, True);
  Entity.CollisionRadius := 0.55;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upGround, upBuilding, upNoAutoAttack, upSupporter]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}230.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}230.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 3);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 12);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 3);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [2, 3], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiDamageType, [3], [dtFlatHeal, dtOverheal]);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 100.0);

  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [4], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiDamageType, [4], [dtSplash, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [4], 20.0);

  // Mana-Reg
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [5], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'LightWave')
      .Keyword('Overheal')
      .PassInteger('energy_cost', 3, 'energy')
      .PassInteger('damage_amount', 20, 'damage')
      .PassInteger('heal_amount', 100, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 9);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 1);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
{$IFDEF CLIENT}
var Mesh : TMeshComponent;
{$ENDIF}
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,3.0,0), 0.8);


    Mesh := TMeshComponent.CreateGrouped(Entity, [0, 1, 2], 'Units\White\MonumentOfLight' + Entity.SkinFileSuffix + '\MonumentOfLight.xml');
    Mesh
      .ApplyLegacySizeFactor
      .FixedOrientation(-1, 0, 0);

    if Entity.SkinID = SKIN_GROUP_SUMMER then
      Mesh
        .BindZoneToBone(BIND_ZONE_WEAPON, 'center')
        .BoneOffset(BIND_ZONE_WEAPON, 0.55, 0.45, 0)
    else
      Mesh.BindZoneToBone(BIND_ZONE_WEAPON, 'Sphere005');

    TMeshEffectMetal.Create().AssignToEntity(Entity);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.2], [0]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [2])
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, True);

  {$IFDEF SERVER}
    // apply buff to surrounding allied units
    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [2])
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2])
      .TargetGroup([3, 4]);

    TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustHave([upUnit])
      .MustNotHave([upUnhealable, upBase, upBanished]);
    TWarheadSplashHealComponent.CreateGrouped(Entity, [3])
      .TargetsGroundAndAir;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('MonumentOfLightHeal')
      .Name('FlatHeal')
      .TriggerOnHealDone;

    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [4]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [4], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upBanished]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [4])
      .TargetsGroundAndAir;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('Splash')
      .TriggerOnKillDone;

    // regenerate mana over time ------------------------------------------------------
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [5])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [5], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [5])
      .SetResourceType(reMana)
      .TargetGroup([]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .FixedCap(3)
      .ShowResource(reMana)
      .HideIfEmpty;

    if Entity.SkinID = SKIN_GROUP_SUMMER then
      TMeshEffectComponent.CreateGrouped(Entity, [2])
        .ActivateOnPreFire
        .SetEffect(
          TMeshEffectHideAndGlow.Create(1000, PATH_GRAPHICS + 'Units\White\MonumentOfLight' + Entity.SkinFileSuffix + '\MonumentOfLightGlowOverride.tga')
            .AddKey(0, 0)
            .AddKey(300, 1)
            .AddKey(1000, 0)
            .AddNextTimeLine()
            .AddKey(0, 1)
            .AddKey(1000, 1)
        );

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\monument_of_light_fire.pfx', 6.0)
      .ActivateOnPreFire()
      .ScaleWith(eiWelaAreaOfEffect)
      .BindToSubPositionGroup(BIND_ZONE_WEAPON, [0, 1])
      .FixedOrientationDefault();
    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetRotationLight
      .ActivateOnFire;
    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetVectorLight
      .ActivateOnFire;

    TPointLightComponent.Create(Entity, $60feff98, 0)
      .SetLightShape(RVector3.Create(5, 0, 0))
      .BindToSubPositionGroup(BIND_ZONE_WEAPON, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\white_border_wide_once.pfx', 5.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/white/building/monument_of_light/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;

