{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.CollisionRadius := 4.0;
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upCharm]);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 6);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 6);

  // blessing energy
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [0], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 1);
  Entity.Blackboard.SetValue(eiCooldown, [0], 500);
  Entity.Blackboard.SetValue(eiWelaRange, [0], 4.0);

  // mana regeneration passive
  Entity.Blackboard.SetValue(eiWelaRange, [4, 5], 4.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [4, 5], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [4, 5], 'Links\SilencedAura');

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

  // blessing
  // permanent
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [10]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [10])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upBase]);
  TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [10])
    .CheckResource(reMana)
    .CheckHasResource;

  // temporary
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [11])
    .MustNotHave([upBlessedEnergy]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [0])
    .GroupA([10])
    .GroupB([11])
    .OperatorAnd;

  // silence
  // permanent
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [12]);
  TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [12, 5]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [12, 5])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upLegendary, upBase, upSpellImmune]);

  // temporary
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [13])
    .MustNotHave([upSilenced]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [13, 5])
    .MustNotHave([upImmuneToStateEffects]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [4])
    .GroupA([12])
    .GroupB([13])
    .OperatorAnd;

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity)
      .SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0,0), 3.5)
      .LowPriority;

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0])
      .Valid([10])
      .Invalid([11]);
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [4])
      .Valid([12])
      .Invalid([13]);
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('EnchantmentFlux')
      .TriggerOnFire;

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
      .SetTargetTeamConstraint(tcEnemies);
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

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\BlessingEnergy.dws');

  {$IFDEF CLIENT}
    TShowOnMinimapComponent.Create(Entity);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\flux_field_cast.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\flux_field_field.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\blue_border_wide.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault()
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/blue/spell/flux_field/cast')
      .TriggerOnCreate;

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/blue/spell/flux_field/trigger')
      .TriggerOnFire;

    TIndicatorResourceCircleComponent.CreateGrouped(Entity, [])
      .Padding(PI / 500)
      .ShowsResource(reWelaCharge)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'ProgressCircle.tga')
      .SetRadius(1.05)
      .ScaleWith(eiCollisionRadius)
      .SetThickness(0.1)
      .Color($605BA9FF);
  {$ENDIF}
end;
