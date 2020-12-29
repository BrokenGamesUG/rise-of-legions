{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  // damage
  Entity.Blackboard.SetValue(eiWelaDamage, [0], 12.0);
  Entity.Blackboard.SetValue(eiCooldown, [0], 1000);
  Entity.Blackboard.SetValue(eiDamageType, [0], [dtAbility]);
  // life leech
  Entity.Blackboard.SetValue(eiWelaModifier, [1], 0.5);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtHoT]);
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
    // deal damage at linked targets
    TLinkBrainComponent.CreateGrouped(Entity, [0]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustHave([upFrozen]);

    // and heal for a percentage of dealt damage
    TAutoBrainOnDealDamageComponent.CreateGrouped(Entity, [0])
      .RedirectToSource
      .WriteAmountTo(eiWelaDamage)
      .FireInGroup([1]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyHealComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerAttacherComponent.Create(Entity)
      .AttachToSource
      .SetSubPosition(BIND_ZONE_HIT_ZONE);

    TLinkRayVisualizerComponent.Create(Entity)
      .Texture('\Units\Black\Vecra' + Entity.SkinFileSuffix + '\FrostLink\FrostLink.tga')
      .SetOpacity(0.1)
      .SetWidth(RVariedSingle.Create(0.3, 0.05))
      .SetLength(RVariedSingle.Create(5, 1))
      .SetLongitudinalSpeed(RVariedSingle.Create(-8.0, 0.5))
      .SetRayCount(1);

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/black/unit/vecra/monarch_of_frost')
      .TriggerOnCreate()
      .StopOnFree;
  {$ENDIF}
end;
