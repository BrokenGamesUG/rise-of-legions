{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TOrienterMovementComponent.Create(Entity);
    TPointLightComponent.Create(Entity, $AFFFFFFF, 2);
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 4.0, 2.0)
      .ScreenSpace()
      .Additive();
    TParticleEffectComponent.Create(Entity, '\White\suntower_projectile.pfx', 8.5)
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
    // projectile damage
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 16, 0, 1)
      .EndTangent(-PI / 16, 0, 2)
      .OrientStartWithTarget()
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/white/building/suntower/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
