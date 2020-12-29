{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upLegendary]);
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Spells\Green\SaplingchargeSapling');
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [0, 1], 7.0);

  // spawn Saplings initially
  Entity.Blackboard.SetValue(eiCooldown, [0], 1000);
  Entity.Blackboard.SetValue(eiWelaCount, [0], 15);

  // spawn Saplings over time
  Entity.Blackboard.SetValue(eiWelaCount, [1], 10);
  Entity.Blackboard.SetValue(eiWelaActive, [1], False);
  Entity.Blackboard.SetValue(eiCooldown, [1, 2], 1000);

  // finish
  Entity.Blackboard.SetValue(eiCooldown, [3], 15000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [0])
      .SetTexture('SpelltargetGround.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    // for legendary spawn statistic
    TStatisticsUnitComponent.Create(Entity);

    // spawn after delay initially once
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [0]);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [0])
      .SpreadSpawns();
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [0])
      .SetsActive
      .SetActivationGroup([1]);
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [0]);
    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [0]);

    // spawn every tick
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [1, 2]);
    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [1]);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [1])
      .SpreadSpawns();

    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [2]);
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [2])
      .TargetGroup([1, 2]);
    TWelaReadyNthComponent.CreateGrouped(Entity, [2])
      .Nth(11);

    // kill after 11 ticks + delay
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [3]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [3]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [3]);
  {$ENDIF}

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Green\saplingcharge_field.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaAreaOfEffect);

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.1], [3]);
    TMeshComponent.CreateGrouped(Entity, [3], 'Effects\Meshes\SaplingstormMeadow.xml')
      .IsEffectMesh()
      .IsDecal()
      .SetModelRotationOffset(RVector3.Create(0, random * 3.14 * 2, 0));

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/spell/sapling_storm/cast')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/spell/sapling_storm/despawn')
      .TriggerOnCreate()
      .Delay(13000);

    TMeshEffectWarp.Create(PATH_GRAPHICS_EFFECTS_MESHES + 'SaplingstormMeadowSpawnMask.png', 16000)
      .AddKey(0, 0)
      .AddKey(2000, 1)
      .AddKey(13000, 1)
      .AddKey(15000, 0)
      .AddKey(16000, 0)
      .AssignToEntity(Entity);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/music/cue/saplings')
      .TriggerOnCreate();
  {$ENDIF}
end;
