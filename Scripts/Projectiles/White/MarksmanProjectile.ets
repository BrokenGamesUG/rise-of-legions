{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 40 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 4.0, 2.0)
      .ScreenSpace()
      .Additive();
    TVertexQuadComponent.Create(Entity, 'Units\White\Marksman_Default\Projectile\marksman_projectile.tga', 2.0, 0.55)
      .CameraOriented()
      .Additive();
    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\LightTrace.tga')
      .Color($FFFFFFFF)
      .Width(0.4)
      .SamplingDistance(0.5)
      .FadeLength(15.0)
      .MaxLength(15.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.1)
      .Additive;
    Entity.Eventbus.Write(eiModelSize, [1.0]);
    TPointLightComponent.Create(Entity, $2Afeff98, 10)
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
      .BothTangents(0, 0, 1)
      .OrientStartWithTarget()
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnFree;

    TSoundComponent.Create(Entity, 'event:/card/white/unit/marksman/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
