{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [1], 4.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [1], 'Links\HealthRegenerationAura');

  Entity.Blackboard.SetValue(eiCooldown, [3], 10000);

  Entity.Blackboard.SetValue(eiWelaTargetCount, [4], 200);
  Entity.Blackboard.SetValue(eiWelaRange, [4], 4.0);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TPositionComponent.Create(Entity);
    // heal tick every 1s
    TThinkImpulseTimerComponent.Create(Entity);

    TBrainWelaLinkComponent.CreateGrouped(Entity, [1])
      .ThinksPassively();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .IgnoreOwnCollisionradius
      .SetValidateGroup([2]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upInjured, upUnit])
      .MustNotHave([upUnhealable, upSporeFieldRegenerating]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [1, 2]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1, 2])
      .MustHave([upInjured, upUnit])
      .MustNotHave([upUnhealable]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [1]);

    // Fields ends after duration
    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [3]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [3], False);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [3]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [4])
      .DisableTargetLock()
      .ThinksPassively();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .IgnoreOwnCollisionradius
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustHave([upUnit, upFlying])
      .MustNotHave([upGround, upLegendary, upImmuneToGrounded, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [4], 'Modifiers\Grounded.dws')
    .Methodname('ApplyGreen');

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Green\spore_field.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Green\spore_death.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Green\green_border.pfx', 5.0)
      .ActivateOnCreate()
      .IgnoreModelSize
      .ScaleWith(eiWelaRange)
      .FixedOrientationDefault
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [4], 'event:/card/shared/effect/grounded')
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/unit/spore/heal_field_loop')
      .TriggerOnCreate()
      .StopOnFree;
  {$ENDIF}
end;
