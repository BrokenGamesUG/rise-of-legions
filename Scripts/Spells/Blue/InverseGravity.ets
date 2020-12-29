{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1, 2, 9], 4.5);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0, 1, 2, 9], 16);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 2])
    .MustHaveAny([upUnit, upGadget])
    .MustNotHave([upLifted, upGrounded, upLegendary, upMonumental, upImmuneToStateEffects, upSpellImmune]);
  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [2])
    .GroupA([0])
    .GroupB([1])
    .OperatorOr;

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
    .MustHave([upFlying])
    .MustNotHave([upImmuneToGrounded]);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
    .MustHave([upGround])
    .MustNotHave([upImmuneToLifted]);

  // permanent
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [10])
    .MustHaveAny([upUnit, upGadget])
    .MustNotHave([upLegendary, upMonumental]);
  // temporary
  TWelaTargetConstraintBooleanComponent.CreateGrouped(Entity, [11])
    .GroupA([0])
    .GroupB([1])
    .OperatorOr;
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [11])
    .MustNotHave([upImmuneToStateEffects]);

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [9])
      .Valid([10])
      .Invalid([11])
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseOnceComponent.CreateGrouped(Entity, []);

    TBrainWelaFightComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcAll);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Grounded')
      .TriggerOnFire;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [0]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcAll);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Lifted')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('LiftedGroundOnly')
      .TriggerOnFire
      .CheckUnitPropertyMustHaveAny([upMelee, upRangedGroundOnly]);

    TWelaEffectSuicideComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Grounded.dws')
    .Methodname('ApplyBlue');

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [1], 'Modifiers\Lifted.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/blue/spell/inverse_gravity/cast')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\inverse_gravity_cast.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\blue_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
