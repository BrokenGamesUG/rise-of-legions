{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 14 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Spells\Black\Frostspear\FrostspearProjectile.png', 1.2, 0.6)
      .CameraOriented();

    TParticleEffectComponent.Create(Entity, '\Black\frostspear_projectile.pfx', 8.3)
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
      .Name('Frostspear')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Spell')
      .TriggerOnDamageDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 3, 0, 3)
      .StartTangentRandom(PI / 8, PI, 0)
      .EndTangent(PI / 8, 0, 0)
      .OrientStartWithTarget
      .BindToSubPosition(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/black/spell/frostspear/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
