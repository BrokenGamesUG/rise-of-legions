{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [], 4.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [], 8);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upLegendary, upBase, upSpellImmune]);

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

    TBrainWelaFightComponent.CreateGrouped(Entity, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [])
      .SetTargetTeamConstraint(tcAll);
    // reset building timer
    TWelaEffectResetCooldownComponent.CreateGrouped(Entity, [])
      .SearchForWelaBeacon([upBuildingLimitedTime]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, []);
    // remove all buffs except summoning sickness
    TWarheadSpottyRemoveBuffComponent.CreateGrouped(Entity, [])
      .All
      .MustNotHave([btSummoningSickness]);
    // reset health
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [])
      .SetResourceType(reHealth)
      .ResetResource;
    // reset energy
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [])
      .SetResourceType(reMana)
      .ResetResource;
    // reset overheal
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [])
      .SetResourceType(reOverheal)
      .ResetResource;
    // reset wela targets
    TWarheadSpottyWelaStopComponent.CreateGrouped(Entity, []);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, []);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/blue/spell/factory_reset/cast')
      .TriggerOnCreate;

    TMeshEffectComponent.CreateGrouped(Entity, [])
      .TargetGroup([])
      .ApplyToFireTarget
      .ActivateOnFire
      .SetEffect(
        TMeshEffectTint.Create(300, $FF5BA9FF)
          .Additive
          .AddKey(0, 0.0)
          .AddKey(100, 1.0)
          .AddKey(300, 0.0)
      );

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\factory_reset_apply.pfx', 1.2)
      .ClonesToTarget
      .ActivateOnFire
      .FixedOrientationDefault
      .ScaleWith(eiCollisionRadius)
      .FixedHeightGround;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\factory_reset_cast.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\blue_border_wide_once.pfx', 5.0)
      .ActivateOnCreate()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
