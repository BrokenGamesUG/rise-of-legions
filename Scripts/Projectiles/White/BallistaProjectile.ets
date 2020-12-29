{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 26 / 1000);

  // heal flares
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 2);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 2);

  Entity.Blackboard.SetIndexedValue(eiResourceCost, [1], reWelaCharge, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Projectiles\White\BallistaHealProjectile');
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtFlatHeal]);
  Entity.Blackboard.SetValue(eiCooldown, [1], 250);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 5.5);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 2);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\White\Ballista\BallistaArrow\BallistaArrow.xml')
      .ApplyLegacySizeFactor;
    Entity.Eventbus.Write(eiModelSize, [0.9]);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\LightTrace.tga')
      .Color($80FFFFFF)
      .Width(0.3)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(7.0)
      .TexturePerDistance(4.0)
      .Additive;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);

    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks()
      .SetNotFollowingTarget();
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustHave([upGround])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Siege')
      .Name('Splash')
      .TriggerOnDamageDone;

    // heal flares
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [1]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upUnit, upInjured])
      .MustNotHave([upUnhealable]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
    // every projectile costs
    TWelaReadyCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reWelaCharge, []);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [1])
      .SetPayingGroupForType(reWelaCharge, []);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(0, 0, 1)
      .EndTangent(PI / 7, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/white/unit/ballista/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
