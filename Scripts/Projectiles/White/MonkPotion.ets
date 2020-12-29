{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 18 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\White\Monk' + Entity.SkinFileSuffix + '\HealPotion\HealPotion.xml')
      .ApplyAutoSizeNormalization;
    TMeshEffectMetal.Create().AssignToEntity(Entity);
    Entity.Eventbus.Write(eiModelSize, [0.45]);
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
    TWarheadSpottyRemoveBuffComponent.CreateGrouped(Entity, [0])
      .MustHaveAny([btState]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\ImmuneToStateEffects.dws');

  {$IFDEF CLIENT}
    TOrienterMovementComponent.Create(Entity);
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 4, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\monk_heal_potion_impact.pfx', 5.5)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/white/unit/monk/potion_drink')
      .TriggerOnFree;
  {$ENDIF}
end;
