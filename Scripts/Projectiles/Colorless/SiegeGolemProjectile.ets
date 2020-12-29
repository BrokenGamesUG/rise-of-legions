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
    TParticleEffectComponent.Create(Entity, '\Colorless\siege_golem_projectile.pfx', 1.0)
      .ActivateOnCreate();
    TPointLightComponent.Create(Entity, $2A00FFFF, 5);

    for i := 0 to 3 do
    begin
      TPositionerRotationComponent.CreateGrouped(Entity, [1+i])
        .Radius(0.3)
        .RotationSpeed(0, 0, (3 + i) * PI)
        .Phase(i * 0.2);
      TVertexTraceComponent.CreateGrouped(Entity, [1+i])
        .Texture('Effects\Textures\CrystalTrace.tga')
        .Color($3080FFFF)
        .Width(0.25)
        .SamplingDistance(0.5)
        .FadeLength(5.0)
        .MaxLength(7.0)
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Siege')
      .TriggerOnDamageDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .OrientStartWithTarget
      .StartTangent(PI / 4, 0, 1.5)
      .EndTangent(PI / 8, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Colorless\siege_golem_projectile_impact.pfx', 1.1)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead();

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationMedium
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorMedium
      .ActivateOnFree;

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/siege_golem/crystal_artillery_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
