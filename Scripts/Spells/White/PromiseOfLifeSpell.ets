{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.CollisionRadius := 4.0;
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upCharm]);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 10);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 10);

  // guarded aura
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [0, 2], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [0], 5.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [0], 'Links\GuardedAura');

  // immunity passive
  Entity.Blackboard.SetValue(eiWelaRange, [4], 5.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [4], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [4], 'Links\ImmuneToStateEffectsAura');

  // limited
  Entity.Blackboard.SetValue(eiWelaDamage, [5, 6], 1.0);
  Entity.Blackboard.SetValue(eiWelaRange, [7], 10000.0);

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIcon, 'MinimapCharmIcon.png');
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udMinimapIconSize, Entity.CollisionRadius * 0.25);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
    .MustNotHave([upGuarded]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
    .MustHave([upUnit])
    .MustNotHave([upImmuneToGuarded]);
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [0]);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity)
      .SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,0,0), 4.0)
      .LowPriority;

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  TCollisionComponent.Create(Entity);

  {$IFDEF SERVER}
    TPositionComponent.Create(Entity);
    TThinkImpulseTimerComponent.Create(Entity);

    // guarded
    TBrainWelaLinkComponent.CreateGrouped(Entity, [0])
      .ThinksPassively();
    TWelaReadyCostComponent.CreateGrouped(Entity, [0])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .IgnoreOwnCollisionradius
      .SetValidateGroup([1]) // don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [0, 1]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [0, 1])
      .CreatorGroup([2]);

    // each guarding costs a charge, after all charges are used, the field dies
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaEffectFireComponent.CreateGrouped(Entity, [2])
      .TargetGroup([3])
      .RedirectToSelf;
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [3])
      .ComparedResource(reWelaCharge)
      .CheckEmpty;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [3]);

    // immunity to state effects
    TBrainWelaLinkComponent.CreateGrouped(Entity, [4])
      .ThinksPassively();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .IgnoreOwnCollisionradius
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustNotHave([upCharm]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [4]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [4]);

    // kill a charm if too much charms
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [7])
      .FireAtTarget;
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [7])
      .ComparedResource(reCharmCount)
      .CheckFull
      .ChecksCommander;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [7])
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [7])
      .MustHave([upCharm]);
    TWelaEfficiencyCreatedComponent.CreateGrouped(Entity, [7]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [7]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [7])
      .Remove;

    // take a charm slot in commander on creation
    TAutoBrainOnCreateComponent.CreateGrouped(Entity, [5])
      .FireAtCommander;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [5])
      .SetResourceType(reCharmCount);
    // release a charm slot in commander on death
    TAutoBrainOnFreeComponent.CreateGrouped(Entity, [6])
      .FireAtCommander
      .ThinksPassively
      .ThinksInExile;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [6]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [6])
      .SetResourceType(reCharmCount)
      .SetFactor(-1.0);
  {$ENDIF}

  {$IFDEF CLIENT}
    TShowOnMinimapComponent.Create(Entity);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\promise_of_life_cast.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\promise_of_life_field.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\white_border_wide.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/white/spell/promise_of_life/cast')
      .TriggerOnCreate();

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationMedium
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorMedium
      .ActivateOnCreate;

    TIndicatorResourceCircleComponent.CreateGrouped(Entity, [])
      .Padding(PI / 500)
      .ShowsResource(reWelaCharge)
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'ProgressCircle.tga')
      .SetRadius(1.05)
      .ScaleWith(eiCollisionRadius)
      .SetThickness(0.1)
      .Color($40F9FF84);
  {$ENDIF}
end;
