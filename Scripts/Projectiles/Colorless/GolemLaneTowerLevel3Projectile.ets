{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 30 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Colorless\golem_lane_tower_level3_projectile.pfx', 2.0)
      .ActivateOnCreate();
    TPointLightComponent.Create(Entity, $2A00FFFF, 0)
      .SetLightShape(RVector3.Create(2, 10, 0));

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\CrystalTrace.tga')
      .Color($80FFFFFF)
      .Width(0.3)
      .SamplingDistance(0.5)
      .FadeLength(4.0)
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
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Colorless\golem_lane_tower_level3_projectile_impact.pfx', 1.0)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead();

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/golem_lane_tower_level3/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
