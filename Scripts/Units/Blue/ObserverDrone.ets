{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upFlying, upBuilding, upUnit, upGadget, upNoAutoAttack, upSupporter]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}78.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}78.0);

  // range aura
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2, 3], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [2, 3], 'Links\RangeUpgradeAura');
  Entity.Blackboard.SetValue(eiWelaRange, [2, 3], 4.0);
  Entity.Blackboard.SetValue(eiWelaActive, [2], False);

  // limited
  Entity.Blackboard.SetValue(eiWelaDamage, [4, 5], 1.0);

  // inivisbility
  Entity.Blackboard.SetValue(eiWelaTargetCount, [6], 1);
  Entity.Blackboard.SetValue(eiLinkPattern, [6], 'Links\InvisibleAura');
  Entity.Blackboard.SetValue(eiWelaRange, [6, 7], 15.0); // range of lane tower

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Flying');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'LimitedGadget')
      .PassInteger('gadget_limit', 5)
      .PassInteger('gadget_limit_exceeded', 6);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Stationary');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'CloakGround')
      .Keyword('Stealthed');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'RangeAura')
      .PassInteger('range_increase_units', 3, 'range')
      .PassInteger('range_increase_buildings', 5, 'range');

    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, 3.5);

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(-0.2,1.3,0), RVector3.Create(0.2,1.3,0), 0.6);

    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, FLYING_HEIGHT, 0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Blue\ObserverDrone' + Entity.SkinFileSuffix + '\ObserverDrone.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 69)
      .BindZoneToBone(BIND_ZONE_CENTER, 'CATRigHub001')
      .BoneSwapXZ(BIND_ZONE_CENTER)
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'CATRigHub001')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneSwapXY(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_TOP, 'CATRigHub001')
      .BoneSwapXZ(BIND_ZONE_TOP)
      .BoneSwapXY(BIND_ZONE_TOP)
      .BoneOffset(BIND_ZONE_TOP, 0, 0.3, 0)
      .BindZoneToBone('engine_bottom', 'CATRigHub001')
      .BoneSwapXY('engine_bottom')
      .BoneSwapYZ('engine_bottom')
      .BoneInvertZ('engine_bottom')
      .BoneOffset('engine_bottom', 0, 0, 0.1)
      .BindZoneToBone('engine_left', 'CATRigLArmCollarbone')
      .BoneSwapXY('engine_left')
      .BoneOffset('engine_left', 0, 0.2, 0)
      .BoneRotation('engine_left', 0.025, 0, 0)
      .BindZoneToBone('engine_right', 'CATRigRArmCollarbone')
      .BoneSwapXY('engine_right')
      .BoneInvertZ('engine_right')
      .BoneOffset('engine_right', 0, 0.2, 0)
      .BoneRotation('engine_right', 0.025, 0, 0)
      .SetModelOffset(0, -1.7, 0);

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.0], [0]);
    TAnimationComponent.CreateGrouped(Entity, [1]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [2])
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);

  {$IFDEF SERVER}
    TWelaHelperActivateTimerComponent.CreateGrouped(Entity, [2])
      .Delay(1000);
    TBrainWelaLinkComponent.CreateGrouped(Entity, [2]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetValidateGroup([3]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upRanged])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upRangeAuraBuffed, upBase]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [2, 3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 3])
      .MustHave([upRanged])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upBase, upNoAutoAttack]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [2, 3]);

    TThinkImpulseOnceComponent.CreateGrouped(Entity, [6])
      .TriggerOnDeploy;
    TBrainWelaLinkComponent.CreateGrouped(Entity, [6])
      .ThinksPassively;
    TWelaTargetingSelfComponent.CreateGrouped(Entity, [6]);
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [6])
      .MustNotHave([upHasStateEffect]);
    TWelaReadyEntityNearbyComponent.CreateGrouped(Entity, [6])
      .TargetingGroup([7])
      .ReadyIfNoTargets;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [7])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [7])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [6]);

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
    TPositionerRotationComponent.CreateGrouped(Entity, [])
      .Radius(0.025)
      .RotationSpeed(0.45 * PI, 0.55 * PI, 0.65 * PI)
      .Factor(1, 0, 1)
      .Phase(random)
      .FadeIn(1500);

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\flight_engine.pfx', 1.0)
      .ActivateOnCreate
      .Delay(1000)
      .BindToSubPosition('engine_bottom');

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\flight_engine.pfx', 1.0)
      .ActivateOnCreate
      .Delay(1200)
      .BindToSubPosition('engine_left');

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\flight_engine.pfx', 1.0)
      .ActivateOnCreate
      .Delay(1300)
      .BindToSubPosition('engine_right');

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\observer' + Entity.SkinFileSuffix + '_aura_field.pfx', 5.0)
      .ActivateOnCreate
      .ActivateOnWelaActivate
      .FixedOrientationDefault()
      .FixedHeightGround
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\blue_border_wide.pfx', 5.0)
      .IgnoreModelSize
      .ActivateOnCreate
      .ActivateOnWelaActivate
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
