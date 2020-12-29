{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 14 / 1000);

  // Bounce
  Entity.Blackboard.SetValue(eiWelaCount, [0], 6);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 5.0);

  Entity.Blackboard.SetValue(eiWelaModifier, [2], -1.0);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\GreenLensFlare.tga', 2.2, 1.1)
      .ScreenSpace()
      .Additive()
      .Color($A0FFFFFF);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\NatureTrace.tga')
      .Color($A0FFFFFF)
      .Width(0.35)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(3.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.15)
      .Additive;

    TParticleEffectComponent.Create(Entity, '\Green\wisp_projectile_trail.pfx', 3.5)
      .ActivateOnCreate();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .Bounces([1]);
    TWelaReadyEventCompareComponent.CreateGrouped(Entity, [0])
      .ComparedEvent(eiWelaDamage)
      .SetComparator(coGreater)
      .ReferenceValue(0.0);
    // projectile damage
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Flying')
      .TriggerOnKillDone;

    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies)
      .PicksRandomTargets;
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
    TWelaTargetConstraintBlacklistComponent.CreateGrouped(Entity, [1]);

    TAutoBrainOnDealDamageComponent.CreateGrouped(Entity, [2])
      .DontFire
      .WriteAmountTo(eiWelaDamage)
      .AddAmountAtWrite
      .FireInGroup([0]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .OrientStartWithTarget
      .BothTangents(PI / 16, 0, 1)
      .BothTangentsAfterReached(PI / 2.5, 0, 2.2)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/green/unit/wisp/attack_impact')
      .TriggerOnFireWarhead;
  {$ENDIF}
end;
