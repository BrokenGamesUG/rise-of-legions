{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.CollisionRadius := 3.5;
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upCharm]);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 6);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 6);

  // blessing health
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [0], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 1);
  Entity.Blackboard.SetValue(eiCooldown, [0], 2000);
  Entity.Blackboard.SetValue(eiWelaRange, [0], 3.5);

  // mana regeneration passive
  Entity.Blackboard.SetValue(eiWelaRange, [4, 5], 3.5);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [4, 5], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [4, 5], 'Links\ManaRegenerationAura');

  // limited
  Entity.Blackboard.SetValue(eiWelaDamage, [6, 7], 1.0);
  Entity.Blackboard.SetValue(eiWelaRange, [8], 10000.0);

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIcon, 'MinimapCharmIcon.png');
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIconSize, Entity.CollisionRadius * 0.25);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
    .MustHave([upUnit])
    .MustNotHave([upBlessedHealth]);
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [0]);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upEnergyAuraBuffed, upBase]);
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [4, 5]);
  TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [4, 5])
    .CheckResource(reMana)
    .CheckNotFull;
  TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [4, 5]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4, 5])
    .MustHaveAny([upUnit, upBuilding]);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity)
      .SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0,0), 3.5)
      .LowPriority;

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0]);
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [4]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  TCollisionComponent.Create(Entity);

  {$IFDEF SERVER}
    TPositionComponent.Create(Entity);
    TThinkImpulseTimerComponent.Create(Entity);

    // apply blessing to allied units
    TBrainWelaFightComponent.CreateGrouped(Entity, [0])
      .DisableTargetLock();
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [0], true);
    TWelaReadyCostComponent.CreateGrouped(Entity, [0])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .IgnoreOwnCollisionradius
      .SetTargetTeamConstraint(tcAllies)
      .PicksRandomTargets;
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [0]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [0])
      .SetPayingGroupForType(reWelaCharge, []);

    // each blessing costs a charge, after all charges are used, the field dies
    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([1])
      .RedirectToSelf;
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [1])
      .ComparedResource(reWelaCharge)
      .CheckEmpty;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [1]);

    // passive aura
    TBrainWelaLinkComponent.CreateGrouped(Entity, [4])
      .ThinksPassively();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .IgnoreOwnCollisionradius
      .SetValidateGroup([5]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [4, 5]);

    // kill a charm if too much charms
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [8])
      .FireAtTarget;
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [8])
      .ComparedResource(reCharmCount)
      .CheckFull
      .ChecksCommander;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [8])
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [8])
      .MustHave([upCharm]);
    TWelaEfficiencyCreatedComponent.CreateGrouped(Entity, [8]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [8]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [8])
      .Remove;

    // take a charm slot in commander on creation
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [6])
      .FireAtCommander;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [6]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [6])
      .SetResourceType(reCharmCount);
    // release a charm slot in commander on death
    TAutoBrainOnFreeComponent.CreateGrouped(Entity, [7])
      .FireAtCommander
      .ThinksPassively
      .ThinksInExile;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [7]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [7])
      .SetResourceType(reCharmCount)
      .SetFactor(-1.0);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\BlessingHealth.dws');

  {$IFDEF CLIENT}
    TShowOnMinimapComponent.Create(Entity);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Green\healing_garden_cast.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Green\healing_garden_field.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Green\green_border_wide.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault()
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/spell/healing_garden/cast')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/green/spell/healing_garden/trigger')
      .TriggerOnFire();

    TIndicatorResourceCircleComponent.CreateGrouped(Entity, [])
      .Padding(PI / 500)
      .ShowsResource(reWelaCharge)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'ProgressCircle.tga')
      .SetRadius(1.05)
      .ScaleWith(eiCollisionRadius)
      .SetThickness(0.1)
      .Color($4073ff00);
  {$ENDIF}
end;
