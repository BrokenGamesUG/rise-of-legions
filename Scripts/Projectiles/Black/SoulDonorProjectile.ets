{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 10 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\EnergyLensFlare.tga', 3.8, 1.9)
      .ScreenSpace()
      .Additive()
      .Color($A0FFFFFF);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\Trace.tga')
      .Color($805DCDCF)
      .Width(0.30)
      .SamplingDistance(0.5)
      .FadeLength(5.0)
      .MaxLength(6.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.15)
      .Additive;

    TParticleEffectComponent.Create(Entity, '\Shared\energy_trail.pfx', 4.0)
      .ActivateOnCreate();

    TPointLightComponent.Create(Entity, $5A5DCDCF, 2);
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
      .Name('SoulDonor')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 2, 0, 4)
      .EndTangent(PI / 16, 0, 1)
      .MaxDistanceScaling(15);
  {$ENDIF}
end;
