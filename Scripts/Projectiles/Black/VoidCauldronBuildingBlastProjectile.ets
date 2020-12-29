{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 12 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
var i : integer;
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Black\voidcauldron_building_blast_projectile.pfx', 1.0)
      .ActivateOnCreate();

    for i := 0 to 2 do
    begin
      TPositionerRotationComponent.CreateGrouped(Entity, [1+i])
        .Radius(0.2)
        .RotationSpeed(0, 0, 10 * PI)
        .Phase(i * 0.25);
      TVertexTraceComponent.CreateGrouped(Entity, [1+i])
        .Texture('Effects\Textures\ShadowTrace.tga')
        .Color($80FFFFFF)
        .Width(0.2)
        .SamplingDistance(0.3)
        .FadeLength(2.5)
        .MaxLength(5.0)
        .TexturePerDistance(4.0)
        .IsPiece
        .SetModelOffset(RVector3.Create(0, 0, -0.3));
    end;
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Siege')
      .TriggerOnDamageDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 2, 0, 5)
      .StartTangentRandom(PI / 6, PI / 6, 2)
      .EndTangent(PI / 16, 0, 1)
      .MaxDistanceScaling(6);

    TSoundComponent.Create(Entity, 'event:/card/black/unit/voidcauldron/blast_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
