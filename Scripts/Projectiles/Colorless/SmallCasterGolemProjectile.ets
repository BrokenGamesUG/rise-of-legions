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
    TParticleEffectComponent.Create(Entity, '\Colorless\small_caster_golem_projectile.pfx', 5.0)
      .ActivateOnCreate();
    TPointLightComponent.Create(Entity, $2A00FFFF, 2);

    for i := 0 to 3 do
    begin
      TPositionerRotationComponent.CreateGrouped(Entity, [1+i])
        .Radius(0.05 + i * 0.05)
        .RotationSpeed(0, 0, (3 + i) * PI)
        .Phase(i * 0.2);
      TVertexTraceComponent.CreateGrouped(Entity, [1+i])
        .Texture('Effects\Textures\CrystalTrace.tga')
        .Color($50FFFFFF)
        .Width(0.15)
        .SamplingDistance(0.5)
        .FadeLength(3.0)
        .MaxLength(6.0 - i)
        .TexturePerDistance(4.0)
        .Additive
        .IsPiece;
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
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(0, 0, 0.3)
      .EndTangent(PI / 4, 0, 0.3)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [2]);

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/small_caster_golem/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
