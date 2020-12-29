{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 40 / 1000);
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
      .FadeLength(5.0)
      .MaxLength(5.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.1)
      .Additive;

    TPointLightComponent.Create(Entity, $5A5BA9FF, 3);
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('EnergyRift')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Spell')
      .TriggerOnDamageDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(0, 0, 0)
      .EndTangent(0, 0, 0)
      .OrientStartWithTarget
      .StartOffset(0, 1.8, 0)
      .BindToSubPosition(BIND_ZONE_TOP, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\blue_projectile_impact.pfx', 1.0)
      .ActivateOnFree
      .FixedOrientationDefault;

    TSoundComponent.Create(Entity, 'event:/card/blue/spell/energy_rift/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
