{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 14 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Black\voidcauldron_projectile.pfx', 6.0)
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Siege')
      .TriggerOnDamageDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 2, 0, 6)
      .EndTangent(PI / 16, 0, 1);

    TSoundComponent.Create(Entity, 'event:/card/black/unit/voidcauldron/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
