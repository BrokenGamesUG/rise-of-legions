{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiCooldown, [0, 1], 500);
  Entity.Blackboard.SetValue(eiWelaRange, [0], 6.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 200);
  Entity.Blackboard.SetValue(eiWelaModifier, [0], 0.5);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TModifierWelaRangeComponent.CreateGrouped(Entity, [0])
    .ScaleWithStage
    .AddModifier;

  // permanent
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upBase, upSpellImmune]);

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [0, 1]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcAll);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [0])
      .Exile;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Cataclysm')
      .TriggerOnKillDone;

    TBrainWelaTargetlessComponent.CreateGrouped(Entity, [1]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/colorless/spell/cataclysm/cast')
      .TriggerOnCreate();

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0.001, 0.001, 0.005)
      .Duration(500)
      .Waves(4)
      .Invert
      .ActivateOnCreate;

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(0.1)
      .Duration(50)
      .Waves(2)
      .Invert
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationStrong
      .Delay(500)
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorStrong
      .Delay(500)
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Colorless\cataclysm_cast.pfx', 5.25)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedOffsetGround;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Colorless\colorless_border_wide_once.pfx', 5.0)
      .ActivateOnCreate
      .FixedOrientationDefault
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
