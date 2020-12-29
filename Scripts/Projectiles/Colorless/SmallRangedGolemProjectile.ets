{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 28 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\Colorless\SmallRangedGolem\SmallRangedGolemProjectile.xml')
      .ApplyLegacySizeFactor;
    Entity.Eventbus.Write(eiModelSize, [0.7]);

    TParticleEffectComponent.Create(Entity, '\Colorless\small_ranged_golem_projectile.pfx', 1.0)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Color($80a6a594)
      .Width(0.3)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(4.0)
      .TexturePerDistance(4.0);
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
      .BothTangents(PI / 16, 0, 1)
      .OrientStartWithTarget()
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/small_ranged_golem/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
