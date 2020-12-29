{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 4.0, 2.0)
      .ScreenSpace()
      .Additive()
      .Color($FFFEFF98);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\LightTrace.tga')
      .Color($80FFFFFF)
      .Width(0.2)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(4.0)
      .TexturePerDistance(4.0)
      .Additive;

    TPointLightComponent.Create(Entity, $5AFEFF98, 3);
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
      .StartTangent(PI / 8, 0, -1)
      .EndTangent(-PI / 32, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/white/unit/priest/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
