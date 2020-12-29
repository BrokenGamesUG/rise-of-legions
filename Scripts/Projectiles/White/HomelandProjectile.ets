{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 22 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 5.0, 2.5)
      .ScreenSpace()
      .Additive()
      .Color($FFFEFF98);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\LightTrace.tga')
      .Color($80FFFFFF)
      .Width(0.3)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(8.0)
      .TexturePerDistance(4.0)
      .Additive;

    TPointLightComponent.Create(Entity, $5AFEFF98, 3);

    TParticleEffectComponent.Create(Entity, '\White\homeland_glitter.pfx', 1.0)
      .ActivateOnCreate();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerOffsetComponent.Create(Entity)
      .Offset(0, 0.5, 0);

    TPositionerSplineComponent.Create(Entity)
      .OrientStartWithTarget
      .StartTangent(PI / 2, 0, 1)
      .EndTangent(PI / 32, 0, 1);

    TParticleEffectComponent.Create(Entity, '\White\homeland_trigger.pfx', 1.0)
      .ActivateOnCreate();

    TParticleEffectComponent.Create(Entity, '\White\homeland_impact.pfx', 1.0)
      .ActivateOnFree()
      .FixedOrientationDefault;
  {$ENDIF}
end;
