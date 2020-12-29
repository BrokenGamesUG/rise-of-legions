{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 40 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Neutral\tower_projectile.pfx', 6.0)
      .ActivateOnCreate();
    TParticleEffectComponent.Create(Entity, '\Neutral\tower_nexus_shot_projectile.pfx', 8.5)
      .ActivateOnCreate();
    TPointLightComponent.Create(Entity, $2A00FFFF, 0)
      .SetLightShape(RVector3.Create(4, 10, 0));
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .CantBeReflected;
    // projectile damage
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 2 * 7 / 8, 0, 1)
      .OrientStartWithTarget
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [2]);

    TSoundComponent.Create(Entity, 'event:/env/building/lane_tower/nexus_buster_impact')
      .TriggerOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .RotationShaker(0.005, 0.005, 0.02)
      .Duration(500)
      .Waves(8)
      .ActivateOnFree()
      .Global;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .VectorShaker(0, -1, 0)
      .Strength(0.2)
      .Duration(500)
      .Waves(4)
      .ActivateOnFree()
      .Global;
  {$ENDIF}
end;
