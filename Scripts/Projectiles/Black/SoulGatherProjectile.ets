{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 10 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\SoulLensFlare.tga', 4.8, 2.4)
      .ScreenSpace()
      .Additive()
      .Color($60FFFFFF);

    TVertexQuadComponent.Create(Entity, 'Effects\ParticleEffects\Soul.png', 0.75, 0.75)
      .ScreenSpace();

    TVertexTraceComponent.CreateGrouped(Entity, [1])
      .Texture('Effects\Textures\SoulGatherTrace.tga')
      .Color($A0FFFFFF)
      .Width(0.8)
      .SamplingDistance(0.3)
      .FadeLength(5.0)
      .MaxLength(5.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.4);

    TPointLightComponent.Create(Entity, $5ABFFDED, 3);
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('SoulGatherer')
      .TriggerOnFire
      .TakeOwnerFromTarget;
  {$ENDIF}

  {$IFDEF CLIENT}
    TMeshEffectComponent.CreateGrouped(Entity, [0])
      .TargetGroup([])
      .ActivateOnFire
      .ApplyToFireTarget
      .SetEffect(
        TMeshEffectSoulGain.Create(400)
          .AddKey(0, 0.0)
          .AddKey(400, 1.0)
      );

    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 2, 0, 4)
      .EndTangent(PI / 16, 0, 1)
      .MaxDistanceScaling(15);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/effect/soul_extract')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/black/effect/soul_gain')
      .TriggerOnFree();
  {$ENDIF}
end;
