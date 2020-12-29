{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 12 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TPointLightComponent.Create(Entity, $AFFFFFFF, 2);
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 3.0, 1.5)
      .ScreenSpace()
      .Additive();
    TParticleEffectComponent.Create(Entity, '\White\ballista_heal_projectile.pfx', 14.5)
      .ActivateOnCreate();
    TPointLightComponent.Create(Entity, $1Afeff98, 10)
      .SetLightShape(RVector3.Create(3, 5, 0));
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    // projectile heal
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyHealComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('FlatHeal')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TOrienterMovementComponent.Create(Entity);
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 8, 0, 1)
      .BindToSubPosition(BIND_ZONE_CENTER, []);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\ballist_heal_impact.pfx', 1.5)
      .ActivateOnFireWarhead()
      .FixedOrientationDefault();

    TSoundComponent.Create(Entity, 'event:/card/white/unit/ballista/heal_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
