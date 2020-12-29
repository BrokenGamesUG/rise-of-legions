{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 18 / 1000);

  // shatter ice
  Entity.Blackboard.SetValue(eiWelaModifier, [1], 2.0); // double damage against movement impaired
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 3.0); // triple damage against frozen
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Units\Black\VoidWraith\VoidWraithProjectile.png', 2.0, 1.0)
      .CameraOriented();

    TParticleEffectComponent.Create(Entity, '\Black\voidwraith_projectile.pfx', 5.0)
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

    // extra damage
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [0])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHaveAny([upStunned, upBlinded, upRooted, upGrounded, upLifted, upBleeding, upPetrified])
      .MustNotHave([upFrozen]);
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [0])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([2]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upFrozen]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(0, 0, 0)
      .EndTangent(PI / 16, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/black/unit/voidwraith/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
