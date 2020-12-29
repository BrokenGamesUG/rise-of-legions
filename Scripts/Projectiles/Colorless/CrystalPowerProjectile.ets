{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 14 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
var i : integer;
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Colorless\small_caster_golem_projectile.pfx', 6.0)
      .ActivateOnCreate();
    TPointLightComponent.Create(Entity, $2A00FFFF, 2);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\CrystalTrace.tga')
      .Color($80FFFFFF)
      .Width(0.15)
      .SamplingDistance(0.5)
      .FadeLength(2.0)
      .MaxLength(4.0)
      .TexturePerDistance(4.0)
      .Additive;
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
      .StartTangent(0, 0, 0.3)
      .EndTangent(PI / 4, 0, 0.3)
      .BindToSubPosition(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/small_caster_golem/crystal_power_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
