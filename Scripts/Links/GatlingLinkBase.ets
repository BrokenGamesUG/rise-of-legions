{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtSplash, dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 3.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1, 2], 2.5);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TLinkBrainComponent.CreateGrouped(Entity, [0, 1, 2]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0, 1, 2]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Surefire')
      .TriggerOnDamageDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSuicideOnGameEndComponent.Create(Entity);

    TLinkBulletVisualizerComponent.Create(Entity, '\Units\Blue\GatlingTurret' + Entity.SkinFileSuffix + '\GatlingBullet\GatlingBullet.tga')
      .SetBulletSpawnCooldown(RVariedSingle.Create(50, 10))
      .SetSpeed(RVariedSingle.Create(40, 0.0))
      .SetWidth(RVariedSingle.Create(0.6, 0.05))
      .SetLength(RVariedSingle.Create(1.2, 0.1))
      .SetEndposJitter(0.5);

    TLinkBulletVisualizerComponent.Create(Entity, '\Units\Blue\GatlingTurret' + Entity.SkinFileSuffix + '\GatlingBullet\GatlingBullet.tga')
      .SetBulletSpawnCooldown(RVariedSingle.Create(20, 5))
      .SetSpeed(RVariedSingle.Create(40, 0.0))
      .SetWidth(RVariedSingle.Create(0.3, 0.03))
      .SetLength(RVariedSingle.Create(0.5, 0.05))
      .SetEndposJitter(2.1)
      .Color($80FFFFFF)
      .ToGround
      .ImpactParticleEffect('\Blue\gatling' + Entity.SkinFileSuffix + '_link_impact_ground.pfx')
      .ImpactSize(0.5);

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\gatling' + Entity.SkinFileSuffix + '_link_muzzle_flash.pfx', 1.5)
      .ActivateOnCreate()
      .SetModelOffset(RVector3.Create(0, 0, 0.06))
      .IsPiece;

    TPositionerAttacherComponent.CreateGrouped(Entity, [2])
      .AttachToDestination
      .SetSubPosition(BIND_ZONE_HIT_ZONE);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\gatling' + Entity.SkinFileSuffix + '_link_impact.pfx', 1.0)
      .ActivateOnCreate()
      .IsPiece;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\blue_border_wide_once.pfx', 5.0)
      .ActivateOnFireWarhead()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .IsPiece
      .VisibleWithOption(coGameplayShowEffectRadius);
  {$ENDIF}
end;
