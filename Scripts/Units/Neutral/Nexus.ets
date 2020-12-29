{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity);
  Entity.CollisionRadius := 3.5;
  Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHasDeathEffect, False);

  Entity.Blackboard.SetValue(eiUnitProperties, [], [upFlying, upGround, upMonumental, upBuilding, upRanged, upBase, upNexus, upSpellImmune]);
  Entity.Blackboard.SetValue(eiArmorType, [], atFortified);

  // 2v2 - PvP
  {$IFNDEF MAPEDITOR}
  if Game.IsDuo and Game.IsPvP and Game.IsOneLane then
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, i([10, 20, 20, 25, 25], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, i([10, 20, 20, 25, 25], Entity.CardLeague));
    Entity.Blackboard.SetValue(eiCooldown, [1], 1250);
    Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 2);
  end
  else
  // Rest
  {$ENDIF}
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, i([8, 16, 16, 20, 20], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, i([8, 16, 16, 20, 20], Entity.CardLeague));
    Entity.Blackboard.SetValue(eiCooldown, [1], 1000);
    Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 1);
  end;

  // Splash-Attack
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 15.0);
  // attack speed set per scenario
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtTrue, dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], f([110.0, 110.0, 120.0, 120.0, 120.0], Entity.CardLeague));

  // Spawnzone
  Entity.Blackboard.SetValue(eiWelaRange, [3], 31.5);

  // Ammo-Recharge
  Entity.Blackboard.SetValue(eiWelaDamage, [6], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [6], i([10000, 9000, 8000, 6000, 6000], Entity.CardLeague));

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIcon, 'minimap_icon_nexus_%d.png');
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIconSize, 5.0);
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, 10.0);

    TTooltipUnitAbilityComponent.Create(Entity, 'PrimaryTarget');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Monumental');
    TTooltipUnitAbilityComponent.Create(Entity, 'SpellImmune');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [6], 'EnergyRegenerationLanetower')
      .PassInteger('charge_amount', 1, 'generic')
      .PassInteger('cooldown_league_1', 10)
      .PassInteger('cooldown_league_2', 9)
      .PassInteger('cooldown_league_3', 8)
      .PassInteger('cooldown_league_4', 6)
      .PassInteger('cooldown_league_5', 6);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Ammo_Basebuilding')
      .PassInteger('charge_cost', 1, 'generic');
    {$IFNDEF MAPEDITOR}
    if Game.IsDuo and Game.IsPvP and Game.IsOneLane then
      TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'MultiShot2')
        .PassInteger('target_count', 2);
    {$ENDIF}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash_Nexus1')
      .PassInteger('damage_amount', i([30, 30, 35, 35, 35], Entity.CardLeague), 'damage');
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0.1,0), 3.5);

    TAnimationComponent.CreateGrouped(Entity, [0]);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Neutral\Nexus\NexusCrystal.xml')
      .CreateNewAnimation(ANIMATION_STAND, 0, 200)
      .BindTextureToTeam(mtDiffuse, 'NexusDiffuse.tga', 1)
      .BindTextureToTeam(mtDiffuse, 'NexusDiffuse2.tga', 2)
      .BindTextureToTeam(mtGlow, 'NexusGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'NexusGlow2.tga', 2);

    TPointLightComponent.CreateGrouped(Entity, [2], $8A000000, 0)
      .SetLightShape(RVector3.Create(5, 2, 5))
      .SetModelOffset(RVector3.Create(0, -20, 0));

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Neutral\NexusDie%d.pfx', 1.0)
      .ActivateOnLose()
      .IgnoreModelSize
      .FixedOrientationDefault
      .SetModelOffset(RVector3.Create(0, 35, 0));

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .ActivateOnLose
      .SetEffect(
        TMeshEffectGlow.Create(10000)
          .AddKey(0, 0)
          .AddKey(2800, 0.1)
          .AddKey(3100, 1)
          .AddKey(3201, 0)
          .AddKey(10000, 0)
      );

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystal%d.png')
      );

    TAnimatorComponent.CreateGrouped(Entity, [2, 3])
      .Duration(30000)
      .ActivateOnLose
      .HideAfter(3150);

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0.005, 0.005, 0.02)
      .Duration(1000)
      .Waves(24)
      .ActivateOnLose
      .Delay(3200);

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.3)
      .Duration(1000)
      .Waves(16)
      .ActivateOnLose
      .Delay(3200);

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0.001, 0.001, 0.005)
      .Duration(3200)
      .Waves(24)
      .Invert
      .ActivateOnLose;

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.1)
      .Duration(3200)
      .Waves(16)
      .Invert
      .ActivateOnLose;

    TSoundComponent.CreateGrouped(Entity, [], 'event:/env/building/nexus/destroy')
      .TriggerOnLose;

    Entity.Eventbus.WriteGrouped(eiModelSize, [0.12], [0, 1, 2, 3, 6]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);

  {$IFDEF SERVER}
    TServerPrimaryTargetComponent.Create(Entity);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    // Ammo-Charge
    TWelaHelperInitActiveAfterGameStartComponent.CreateGrouped(Entity, [6]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [6]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [6], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [6]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [6])
      .SetResourceType(reWelaCharge);
  {$ENDIF}

  TDynamicZoneRadialEmitterComponent.CreateGrouped(Entity, [3])
    .SetZone([dzDrop, dzNexus]);

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reWelaCharge)
      .SizeY(8);

    TStateDisplayStackComponent.Create(Entity);
    TStateDisplayComponent.Create(Entity)
      .Texture('HUD/Unitbars/icon_out_of_ammo.png')
      .CheckWelaIsReadyInGroup([11])
      .ReverseWelaIsReadyCheck;
    TWelaReadyCostComponent.CreateGrouped(Entity, [11])
      .SetPayingGroupForType(reWelaCharge, [])
      .ValueGroup([1]);

    TStateDisplayComponent.Create(Entity)
      .Texture('HUD/Unitbars/icon_not_reloading.png')
      .CheckWelaIsReadyInGroup([12]);
    TWelaReadyEnemiesNearbyComponent.CreateGrouped(Entity, [12])
      .ValueGroup([1]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [3])
      .HideInCaptureMode
      .DrawOnShowSpawnZone([dzDrop, dzNexus])
      .DrawCircle(0.5)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'RangeLine.tga')
      .ShowTeamColor()
      .ShowWeaponRange()
      .IsPermanent;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/env/building/nexus/attack_fire')
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [], 'env/building/nexus/damaged')
      .TriggerOnLoseHealth();
  {$ENDIF}
end;
