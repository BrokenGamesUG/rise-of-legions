{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 24 / 1000);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 1);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 2);

  // Bounce
  Entity.Blackboard.SetValue(eiWelaCount, [0], 2);
  Entity.Blackboard.SetValue(eiWelaRange, [1], 5.0);

  Entity.Blackboard.SetValue(eiWelaDamage, [2], 1.0);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\White\Avenger\Hammer\Hammer.xml')
      .ApplyLegacySizeFactor;
    Entity.Eventbus.Write(eiModelSize, [1.0]);

    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 6.0, 3.0)
      .ScreenSpace()
      .Additive()
      .Color($FFFEFF98);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\LightTrace.tga')
      .Color($80FFFFFF)
      .Width(0.20)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
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
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .Bounces([1]);
    // projectile damage
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([2])
      .RedirectToSelf;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('InnerFireBounce')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Flying')
      .TriggerOnKillDone;

    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
    TWelaTargetConstraintBlacklistComponent.CreateGrouped(Entity, [1]);

    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [2])
      .SetResourceType(reWelaCharge);
  {$ENDIF}

  TModifierWelaDamageComponent.CreateGrouped(Entity, [0])
    .Divide
    .ScaleWithResource(reWelaCharge);

  {$IFDEF CLIENT}
    TOrienterMovementComponent.Create(Entity);
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 16, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/white/unit/avenger/attack_impact')
      .TriggerOnFireWarhead;
  {$ENDIF}
end;
