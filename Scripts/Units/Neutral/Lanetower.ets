{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity);
  Entity.CollisionRadius := 1.0;

  Entity.Blackboard.SetValue(eiUnitProperties, [], [upFlying, upGround, upMonumental, upBuilding, upBase, upRanged, upLanetower]);

  Entity.Blackboard.SetValue(eiArmorType, [], atFortified);

  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [7], reWelaCharge, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [7], reWelaCharge, 20);

  // 2v2 - PvP
  {$IFNDEF MAPEDITOR}
  if Game.IsDuo and Game.IsPvP and Game.IsOneLane then
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, i([8, 18, 18, 23, 23], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, i([4, 9, 9, 12, 12], Entity.CardLeague));
    Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 2);
    Entity.Blackboard.SetValue(eiCooldown, [1], 1250);
  end
  else
  // Rest
  {$ENDIF}
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, i([6, 14, 14, 18, 18], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, i([3, 7, 7, 9, 9], Entity.CardLeague));
    Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 1);
    Entity.Blackboard.SetValue(eiCooldown, [1], 1000);
  end;

  // Attack
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 15.0);
  // attack speed set per scenario
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtTrue, dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], f([100.0, 100.0, 100.0, 100.0, 100.0], Entity.CardLeague));

  // Spawnzone-Emitter
  Entity.Blackboard.SetValue(eiWelaRange, [3], 30.0);

  // On-Death spawn capture point
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Units\Neutral\LaneNode');
  Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [2], 1, 'Units\Neutral\LaneNode_Red');
  Entity.Blackboard.SetIndexedValue(eiWelaUnitPattern, [2], 2, 'Units\Neutral\LaneNode_Blue');

  // Ammo-Recharge
  Entity.Blackboard.SetValue(eiWelaDamage, [5], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [5], i([10000, 9000, 8000, 6000, 6000], Entity.CardLeague));

  // Nexus-Shot
  // -- Charge
  Entity.Blackboard.SetValue(eiWelaDamage, [6], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [6], 500);

  // -- Attack
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [7], reWelaCharge, 20);
  Entity.Blackboard.SetValue(eiWelaDamage, [7], 100.0);
  Entity.Blackboard.SetValue(eiDamageType, [7], [dtTrue, dtRanged]);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [7], 'Projectiles\Neutral\LaneTowerAntiNexusProjectile');

  // -- Clear
  Entity.Blackboard.SetValue(eiWelaDamage, [8], 0.0);

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIcon, 'minimap_icon_tower_%d.png');
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIconSize, 2.5);
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, 1.2);

    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Monumental');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'EnergyRegenerationLanetower')
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
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash_Lanetower1')
      .PassInteger('damage_amount', i([25, 25, 30, 30, 30], Entity.CardLeague), 'damage');

    {$IFNDEF MAPEDITOR}if Game.HasShowdown then{$ENDIF}
      TTooltipUnitAbilityComponent.CreateGrouped(Entity, [7], 'NexusBuster1')
        .PassInteger('damage_amount', 100, 'damage')
        .PassInteger('cooldown', 10)
        .PassInteger('activation_cooldown', i([6, 9, 9, 12, 12], Entity.CardLeague));
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TPointLightComponent.CreateGrouped(Entity, [2], $AA000000, 0)
      .SetLightShape(RVector3.Create(2.5, 2, 0))
      .BindToSubPosition(BIND_ZONE_CENTER);

    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Neutral\Lanetower\LanetowerBase.xml')
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow2.tga', 2)
      .BindZoneToBone(BIND_ZONE_HIT_ZONE_AIR, 'crystal_hit_zone')
      .BoneOffset(BIND_ZONE_HIT_ZONE_AIR, 0, 3, 0)
      .BoneOffset(BIND_ZONE_TOP, 0, 2.5, 0);

    Entity.Eventbus.WriteGrouped(eiModelSize, [0.12], [0, 1, 2, 3, 6, 7]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
var TowerCaptureEventGroup : integer;
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);
  TowerCaptureEventGroup := Entity.ReserveFreeGroup();

  {$IFDEF SERVER}
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
    // clear charge if attacking
    TWelaEffectFireComponent.CreateGrouped(Entity, [1])
      .TargetGroup([8])
      .RedirectToSelf;

    TAutoBrainOnDeathComponent.CreateGrouped(Entity, [2]);
    if Game.IsPvP then
      TWelaHelperResolveComponent.CreateGrouped(Entity, [2])
        .ResolveTeamID();
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [2])
      .SetSpawnedTeam(0);

    // Ammo-Charge
    TWelaHelperInitActiveAfterGameStartComponent.CreateGrouped(Entity, [5]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [5]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [5], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [5])
      .SetResourceType(reWelaCharge);

    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [TowerCaptureEventGroup]);
    TWelaEffectGameEventComponent.CreateGrouped(Entity, [TowerCaptureEventGroup])
      .Event(GAME_EVENT_TOWER_CAPTURED);

    if Game.HasShowdown then
    begin
      // Nexus-Shot
      TWelaReadyAfterGameEventComponent.CreateGrouped(Entity, [6, 7, 8])
        .GameEvent(GAME_EVENT_SHOWDOWN);

      // charging if no enemy is near
      TBrainWelaSelftargetComponent.CreateGrouped(Entity, [6]);
      TWelaReadyCooldownComponent.CreateGrouped(Entity, [6], true);
      TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [6])
        .CheckingGroup([7])
        .ComparedResource(reWelaCharge)
        .CheckNotFull();
      TWelaEffectInstantComponent.CreateGrouped(Entity, [6]);
      TWarheadSpottyResourceComponent.CreateGrouped(Entity, [6])
        .SetResourceType(reWelaCharge)
        .TargetGroup([7]);

      // firing at enemy nexus if charges are full
      TBrainWelaFightComponent.CreateGrouped(Entity, [7])
        .Preemptive;
      TWelaReadyCostComponent.CreateGrouped(Entity, [7])
        .SetPayingGroupForType(reWelaCharge, [7]);
      TWelaReadyCooldownComponent.CreateGrouped(Entity, [7], True);
      TWelaTargetingNexusComponent.CreateGrouped(Entity, [7]);
      TWelaEffectProjectileComponent.CreateGrouped(Entity, [7]);
      TWelaEffectPayCostComponent.CreateGrouped(Entity, [7])
        .SetPayingGroupForType(reWelaCharge, [7]);

      // clear charge if attacking
      TWelaEffectInstantComponent.CreateGrouped(Entity, [8]);
      TWarheadSpottyResourceComponent.CreateGrouped(Entity, [8])
        .SetResourceType(reWelaCharge)
        .SetsResourceToValue
        .TargetGroup([7]);
    end;
  {$ENDIF}

  TDynamicZoneRadialEmitterComponent.CreateGrouped(Entity, [3])
    .SetZone([dzDrop]);

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
      .ValueGroup([1])
      .CheckGroup([13]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [13])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upInvisible, upBanished]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [3])
      .HideInCaptureMode
      .DrawOnShowSpawnZone([dzDrop])
      .DrawCircle(0.5)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'RangeLine.tga')
      .ShowTeamColor()
      .ShowWeaponRange()
      .IsPermanent;

    TGameIntensityComponent.Create(Entity);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/env/building/lane_tower/death')
      .TriggerOnDie();

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Neutral\tower_fire.pfx', 0.12)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [2])
      .FixedOrientationDefault;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/env/building/lane_tower/attack_fire')
      .TriggerOnFire();

    TResourceDisplayProgressBarComponent.CreateGrouped(Entity, [7])
      .GradientTop($FFDEDEDE)
      .GradientBottom($FF404040)
      .ShowResource(reWelaCharge)
      .HideIfEmpty;

    {$IFNDEF MAPEDITOR}if Game.HasShowdown then{$ENDIF}
    begin
      TSoundComponent.CreateGrouped(Entity, [7], 'event:/env/building/lane_tower/nexus_buster_fire')
        .TriggerOnFire();

      TParticleEffectComponent.CreateGrouped(Entity, [6], '\Neutral\tower_nexus_shot_charge.pfx', 0.16)
        .ActivateOnFire()
        .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [2]);

      TSoundComponent.CreateGrouped(Entity, [1, 6], 'event:/env/building/lane_tower/nexus_buster_charge_loop')
        .IsLoop
        .TriggerOnFire
        .StopGroup([1])
        .StopOnFire
        .StopOnFree;

      TParticleEffectComponent.CreateGrouped(Entity, [7], '\Neutral\tower_nexus_shot_fire.pfx', 0.10)
        .ActivateOnFire()
        .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [2])
        .FixedOrientationDefault;
    end;
  {$ENDIF}
end;

