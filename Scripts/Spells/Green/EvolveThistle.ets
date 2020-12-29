{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [], 4.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [], 6);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [], 'Units\Green\Thistle');
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [])
    .MustHave([upSapling]);
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, []);

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [])
      .SetTexture('SpelltargetGround.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, []);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TThinkImpulseOnceComponent.CreateGrouped(Entity, []);

    TWelaTargetingRadialComponent.CreateGrouped(Entity, [])
      .SetTargetTeamConstraint(tcAllies);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [])
      .PassCardValues;
    TWelaEffectInstantComponent.CreateGrouped(Entity, []);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [])
      .Exile;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('Evolve')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('EvolveThistleMaxTargets')
      .CheckMaxTargets
      .TriggerOnFire;
    TWelaEffectSuicideComponent.CreateGrouped(Entity, []);

    TBrainWelaFightComponent.CreateGrouped(Entity, []);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\Evolve.dws')
    .PassIntValue(1000)
    .ApplyToProducedUnits();

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/spell/evolve/thistle/cast')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\evolve_thistle.pfx', 1.0)
      .ActivateOnFire()
      .ActivateAtFireTarget()
      .SetModelOffset(RVector3.Create(0, 0.7, 0));

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnCreate;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnCreate;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\green_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
