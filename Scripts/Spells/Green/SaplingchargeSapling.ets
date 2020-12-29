{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  // spawn Saplings
  Entity.Blackboard.SetValue(eiCooldown, [0], round(random * 500));

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Units\Green\Sapling');
  Entity.Blackboard.SetValue(eiWelaActive, [1], False);
  Entity.Blackboard.SetValue(eiCooldown, [1], 1600);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    // spawn after delay initially once
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [0]);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [0])
      .SetsActive
      .SetActivationGroup([1]);
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [0]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [0]);

    TThinkImpulseImmediateComponent.CreateGrouped(Entity, [1]);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [1]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [1]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], False);
    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Green\saplingcharge_spawn.pfx', 1.0)
      .ActivateOnFire()
      .FixedOrientationDefault();

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/green/spell/sapling_storm/sapling_spawn')
      .TriggerOnFire();
  {$ENDIF}
end;
