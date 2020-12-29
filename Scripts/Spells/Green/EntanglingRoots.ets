{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [], 4.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [], 16);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  // permanent
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
    .MustHave([upUnit, upGround])
    .MustNotHave([upLegendary, upSpellImmune]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [1]);

  // temporary
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
    .MustNotHave([upImmuneToRooted, upImmuneToStateEffects]);

  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [])
    .GroupA([1])
    .GroupB([2])
    .OperatorAnd;

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [])
      .Valid([1])
      .Invalid([2]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseOnceComponent.CreateGrouped(Entity, []);

    TWelaTargetingRadialComponent.CreateGrouped(Entity, [])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('Root')
      .TriggerOnFire;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, []);

    TBrainWelaFightComponent.CreateGrouped(Entity, []);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\Root.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/spell/entangling_roots/cast')
      .TriggerOnCreate();

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\entangling_roots_cast.pfx', 3.0)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedOffsetGround
      .IsPiece;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\green_border_wide_once.pfx', 5.0)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
