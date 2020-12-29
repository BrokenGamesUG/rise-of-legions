{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 10 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Black\void_gather_projectile.pfx', 2.0)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Units\Black\Tyrus' + Entity.SkinFileSuffix + '\VoidGatherTrace.tga')
      .Color($80000000)
      .Width(0.2)
      .SamplingDistance(0.5)
      .FadeLength(4.0)
      .MaxLength(4.0)
      .TexturePerDistance(4.0);

    TParticleEffectComponent.Create(Entity, '\Black\void_gather_projectile_trail.pfx', 2.5)
      .ActivateOnCreate();

    TPointLightComponent.Create(Entity, $30FFFFFF, 2)
      .SetLightShape(RVector3.Create(3.0, 2.0, 0.0))
      .Negate;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [0])
      .SetResourceType(reMana);
  {$ENDIF}

  {$IFDEF CLIENT}
    TMeshEffectComponent.CreateGrouped(Entity, [0])
      .TargetGroup([])
      .ActivateOnFire
      .ApplyToFireTarget
      .SetEffect(
        TMeshEffectSoulGain.Create(400)
          .Color($40000000)
          .AddKey(0, 0.0)
          .AddKey(400, 1.0)
      );

    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 2, 0, 4)
      .EndTangent(PI / 16, 0, 1)
      .MaxDistanceScaling(15);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/effect/soul_gain')
      .TriggerOnFree();
  {$ENDIF}
end;
