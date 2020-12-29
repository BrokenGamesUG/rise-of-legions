{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TPointLightComponent.Create(Entity, $FF80E92B, 2);

    TVertexQuadComponent.Create(Entity, 'Effects\Textures\GreenLensFlare.tga', 2.6, 1.3)
      .ScreenSpace()
      .Additive()
      .Color($A0FFFFFF);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\NatureTrace.tga')
      .Color($A0FFFFFF)
      .Width(0.36)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(3.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.09)
      .Additive;

    TParticleEffectComponent.Create(Entity, '\Green\woodwalker_projectile.pfx', 4.0)
      .ActivateOnCreate();
    Entity.Eventbus.Write(eiModelSize, [1.0]);
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
      .BothTangents(PI / 8, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/green/unit/woodwalker/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
