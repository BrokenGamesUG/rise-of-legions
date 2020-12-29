{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 16 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\Green\ForestGuardian' + Entity.SkinFileSuffix + '\Projectile\Stone.xml')
      .ApplyLegacySizeFactor;

    TParticleEffectComponent.Create(Entity, '\Green\forest_guardian' + Entity.SkinFileSuffix + '_projectile_trail.pfx', 1.0)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\StoneTrace.tga')
      .Color($80E0FFE0)
      .Width(0.65)
      .SamplingDistance(0.25)
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
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks();
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Splash')
      .Name('Siege')
      .TriggerOnDamageDone
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TOrienterAutoRotationComponent.Create(Entity)
      .SetSpeed(RVector3.Create(0.006, 0*0.0051, 0*0.0084));

    TPositionerSplineComponent.Create(Entity)
      .OrientStartWithTarget
      .StartTangent(PI / 8, 0, 1)
      .EndTangent(3 / 4 * PI / 2, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Green\forest_guardian' + Entity.SkinFileSuffix + '_projectile_impact.pfx', 7.0)
      .ActivateOnFireWarhead()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOrientationDefault();

    TSoundComponent.Create(Entity, 'event:/card/green/unit/forest_guardian/attack_impact')
      .TriggerOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Green\green_border_wide_once.pfx', 5.0)
      .ActivateOnFireWarhead
      .FixedOrientationDefault
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnFree;
  {$ENDIF}
end;
