{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);

  Entity.Blackboard.SetValue(eiDamageType, [1], [dtTrue, dtRanged, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1, 2], f([25.0, 25.0, 30.0, 30.0, 30.0], Entity.CardLeague));
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Neutral\tower_projectile.pfx', 8.0)
      .ActivateOnCreate();
    TPointLightComponent.Create(Entity, $2A00FFFF, 0)
      .SetLightShape(RVector3.Create(2, 10, 0));
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0, 1, 2])
      .CantBeReflected;
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1, 2]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1, 2], eiDamageable);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0, 1, 2]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1])
      .IgnoreMainTargets;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 16, 0, 1)
      .OrientStartWithTarget
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [2]);

    TSoundComponent.Create(Entity, 'event:/env/building/lane_tower/attack_impact')
      .TriggerOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Neutral\neutral_border_once.pfx', 5.0)
      .ActivateOnFireWarhead
      .FixedOrientationDefault
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
