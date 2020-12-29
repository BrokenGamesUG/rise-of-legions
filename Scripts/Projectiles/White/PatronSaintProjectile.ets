{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);

  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 3.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 60.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtFlatHeal, dtSplash]);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TOrienterMovementComponent.Create(Entity);
    if Entity.SkinID = SKIN_GROUP_MACHINE then
    begin
      TVertexQuadComponent.Create(Entity, 'Effects\Textures\BlueLensFlare.tga', 6.0, 6.0)
        .ScreenSpace()
        .Additive();
      TPointLightComponent.Create(Entity, $AF4080FF, 2);
      TPointLightComponent.Create(Entity, $1A4080FF, 10)
        .SetLightShape(RVector3.Create(5, 10, 0));
    end
    else
    begin
      TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 8.0, 4.0)
        .ScreenSpace()
        .Additive();
      TPointLightComponent.Create(Entity, $AFFFFFFF, 2);
      TPointLightComponent.Create(Entity, $1Afeff98, 10)
        .SetLightShape(RVector3.Create(5, 10, 0));
    end;
    TParticleEffectComponent.Create(Entity, '\White\patron_saint' + Entity.SkinFileSuffix + '_projectile.pfx', 6.5)
      .ActivateOnCreate();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks();

    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([1])
      .RedirectToGround;

    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustNotHave([upBanished]);

    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashHealComponent.CreateGrouped(Entity, [1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upUnit])
      .MustNotHave([upUnhealable, upBase, upBanished]);
    TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('FlatHeal')
      .TriggerOnHealDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 16, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\patron_saint' + Entity.SkinFileSuffix + '_impact.pfx', 1.6)
      .ActivateOnFireWarhead()
      .ScaleWith(eiWelaAreaOfEffect);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\white_border_wide_once.pfx', 5.0)
      .ActivateOnFireWarhead()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnFree;
    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnFree;

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\white_border_wide_once.pfx', 5.0)
      .ActivateOnFireWarhead()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.Create(Entity, 'event:/card/white/unit/patron_saint/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
