{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 18 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 6.0, 3.0)
      .ScreenSpace()
      .Additive();

    TParticleEffectComponent.Create(Entity, '\White\heavy_gunner_projectile.pfx', 1.3)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\LightTrace.tga')
      .Color($A0FFFFFF)
      .Width(0.8)
      .SamplingDistance(0.5)
      .FadeLength(5.0)
      .MaxLength(5.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.3)
      .Additive;

    TPointLightComponent.Create(Entity, $5Afeff98, 3);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks();
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustNotHave([upBanished]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Splash')
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 32, 0, 0.6)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\heavy_gunner_impact.pfx', 1.6)
      .ActivateOnFireWarhead()
      .ScaleWith(eiWelaAreaOfEffect);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\white_border_wide_once.pfx', 5.0)
      .ActivateOnFireWarhead()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
