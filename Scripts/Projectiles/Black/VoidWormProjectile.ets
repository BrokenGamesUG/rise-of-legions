{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidWorm_Default\Frostblob.xml')
      .ApplyLegacySizeFactor
      .SetModelRotationOffset(RVector3.Create(3.141 / 2, 0, 0));

    TMeshEffectWobble.Create(PATH_GRAPHICS + 'Units\Black\VoidWorm_Default\FrostblobVoidMask.tga')
      .AssignToEntity(Entity);
    TMeshEffectMatCap.Create()
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapIce.png')
      .AssignToEntity(Entity);

    TParticleEffectComponent.Create(Entity, '\Black\voidworm_projectile.pfx', 5.0)
      .ActivateOnCreate();

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.6], [0]);
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

    // Frostshot
    TAutoBrainOnDealDamageComponent.CreateGrouped(Entity, [1]);
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
      .BothTangents(PI / 16, 0, 1);

    TSoundComponent.Create(Entity, 'event:/card/black/unit/voidworm/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
