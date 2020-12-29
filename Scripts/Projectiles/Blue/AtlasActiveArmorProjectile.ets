{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 34 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 6.0, 3.0)
      .Color($FF5BA9FF)
      .ScreenSpace()
      .Additive();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\BlueTrace.tga')
      .Color($A05BA9FF)
      .Width(0.3)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(3.0)
      .TexturePerDistance(4.0)
      .Additive;

    TPointLightComponent.Create(Entity, $5A5BA9FF, 2);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks();
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(0, 0, 1)
      .BindToSubPosition(BIND_ZONE_CENTER, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\blue_projectile_impact.pfx', 1.2)
      .ActivateOnFree
      .FixedOrientationDefault;

    TSoundComponent.Create(Entity, 'event:/card/blue/unit/atlas/active_armor_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
