{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 24 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\Scenario\AttackBoss\Projectile\Stone.xml')
      .ApplyLegacySizeFactor;

    TParticleEffectComponent.Create(Entity, '\Colorless\boss_siege_golem_projectile_trail.pfx', 1.0)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\StoneTrace.tga')
      .Color($80FFFFFF)
      .Width(0.65 * 3.0)
      .SamplingDistance(0.25)
      .FadeLength(3.0 * 3.0)
      .MaxLength(4.0 * 3.0)
      .TexturePerDistance(4.0);

    Entity.Eventbus.WriteGrouped(eiModelSize, [3.0], []);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0], eiDamageable);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0])
      .PercentageOfMaxHealth;
  {$ENDIF}

  {$IFDEF CLIENT}
    TOrienterAutoRotationComponent.Create(Entity)
      .SetSpeed(RVector3.Create(0.006, 0*0.0051, 0*0.0084));

    TPositionerSplineComponent.Create(Entity)
      .OrientStartWithTarget
      .StartTangent(PI / 8, 0, 1)
      .EndTangent(3 / 4 * PI / 2, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/boss_siege_golem/attack_impact')
      .TriggerOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Colorless\boss_siege_golem_projectile_impact.pfx', 1.0)
      .ActivateOnFireWarhead()
      .FixedOrientationDefault();

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationStrong
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorStrong
      .ActivateOnFree;
  {$ENDIF}
end;
