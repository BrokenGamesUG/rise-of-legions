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
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upLegendary, upBase, upSpellImmune]);

  // temporary
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
    .MustNotHave([upImmuneToPetrified, upImmuneToStateEffects]);

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
      .SetTargetTeamConstraint(tcAll);
    TWelaEffectInstantComponent.CreateGrouped(Entity, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('Petrify')
      .TriggerOnFire;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, []);

    TBrainWelaFightComponent.CreateGrouped(Entity, []);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\Petrified.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/colorless/spell/petrify/cast')
      .TriggerOnCreate();

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Colorless\petrify_cast.pfx', 4.5)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedOffsetGround
      .IsPiece;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Colorless\colorless_border_wide_once.pfx', 5.0)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
