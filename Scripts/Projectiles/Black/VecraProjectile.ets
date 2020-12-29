{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 22 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Black\vecra' + Entity.SkinFileSuffix + '_projectile.pfx', 2.2)
      .ActivateOnCreate();
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

    // freeze
    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upUnit])
      .MustNotHave([upImmuneToFrozen, upLegendary, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Frozen')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('FrozenRanged')
      .CheckUnitPropertyMustHave([upRanged])
      .TriggerOnFire;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [1], 'Modifiers\Frozen.dws');

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(0, 0, 0.5)
      .EndTangent(0, 0, 0)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/black/unit/vecra/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
