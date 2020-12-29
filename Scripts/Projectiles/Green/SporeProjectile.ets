{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 14 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\GreenLensFlare.tga', 2.2, 1.1)
      .ScreenSpace()
      .Additive()
      .Color($A0FFFFFF);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\NatureTrace.tga')
      .Color($A0FFFFFF)
      .Width(0.4)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(3.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.09)
      .Additive;

    TParticleEffectComponent.Create(Entity, '\Green\spore_projectile_trail.pfx', 4.0)
      .ActivateOnCreate();
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
      .Name('Flying')
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .OrientStartWithTarget
      .BothTangents(PI / 16, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/green/unit/wisp/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
