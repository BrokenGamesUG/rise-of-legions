{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtRanged, dtSplash, dtAbility]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 10.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [2], 3.0);
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
    // damage
    TLinkBrainComponent.CreateGrouped(Entity, [0])
      .FiresAtCreate([1]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Surefire')
      .TriggerOnDamageDone;

    // root
    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upUnit])
      .MustNotHave([upLegendary, upImmuneToRooted, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Root')
      .TriggerOnFire;

    // splash to rooted enemies
    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([2])
      .RedirectToGround;
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [2]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upRooted])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Splash')
      .Name('RootNetwork')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Surefire')
      .TriggerOnDamageDone;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [1], 'Modifiers\Root.dws');

  {$IFDEF CLIENT}
    TSuicideOnGameEndComponent.Create(Entity);

    TPositionerAttacherComponent.CreateGrouped(Entity, [0])
      .AttachToDestination
      .SetSubPosition(BIND_ZONE_BOTTOM)
      .Offset(0, GROUND_EPSILON, 0);

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/green/unit/rootling/attack_fire')
      .TriggerOnCreate()
      .StopOnFree
      .IsPiece;
    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/green/unit/rootling/attack_loop')
      .TriggerOnFire()
      .StopOnFree
      .IsPiece;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Green\RootDamage.pfx', 1.2)
      .ActivateOnFire()
      .ScaleWith(eiCollisionRadius)
      .MaxScale(0.7)
      .IsPiece;

    TPositionerAttacherComponent.CreateGrouped(Entity, [1])
      .AttachToSource;

    TLinkRayVisualizerComponent.CreateGrouped(Entity, [1])
      .SetDestSubPosition(BIND_ZONE_BOTTOM)
      .Texture('\Units\Green\Rootling' + Entity.SkinFileSuffix + '\RootlingLink\RootlingFiber.tga')
      .SetOpacity(0.8)
      .SetWidth(RVariedSingle.Create(0.4, 0.1))
      .SetLength(RVariedSingle.Create(20.0, 0.0))
      .SetLongitudinalSpeed(RVariedSingle.Create(20.0, 0.0))
      .BindStartOffset(0, GROUND_EPSILON, 0)
      .BindEndOffset(0, GROUND_EPSILON, 0)
      .Planar
      .SetRayCount(1);

    TPositionerAttacherComponent.CreateGrouped(Entity, [2])
      .AttachToDestination;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Green\rootling_root_system.pfx', 3.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .IsPiece;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Green\green_border_wide_once.pfx', 5.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .IsPiece
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
