{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWelaCharge, 1);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reWelaCharge, 3);
  Entity.Blackboard.SetValue(eiWelaModifier, [1], 1.5);

  Entity.Blackboard.SetValue(eiWelaDamage, [2], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [2], 3000);
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('BigCasterGolemLink')
      .TriggerOnDuration;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Surefire')
      .TriggerOnDamageDone;

    TLinkBrainComponent.CreateGrouped(Entity, [0]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);

    TModifierWelaDamageComponent.CreateGrouped(Entity, [0])
      .Multiply
      .ScaleWithResource(reWelaCharge)
      .SetValueGroup([1]);

    TThinkImpulseTimerComponent.CreateGrouped(Entity, [2]);
    // ramp up damage over time
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [2]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], False);
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, [2])
      .ComparedResource(reWelaCharge)
      .CheckNotFull();
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [2])
      .SetResourceType(reWelaCharge);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerAttacherComponent.Create(Entity)
      .AttachToSource
      .SetSubPosition(BIND_ZONE_WEAPON_MUZZLE)
      .ApplyFront;
    TLinkRayVisualizerComponent.Create(Entity)
      .Texture('\Units\Colorless\BigCasterGolem\GolemLink\GolemRay.png')
      .SetOpacity(0.50)
      .SetWidth(RVariedSingle.Create(0.2, 0.1))
      .ScaleWidth(0.9)
      .SetLength(RVariedSingle.Create(4, 1))
      .SetLongitudinalSpeed(RVariedSingle.Create(10.0, 0.5))
      .SetRayCount(2)
      .ScaleWith(reWelaCharge);

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Colorless\big_caster_golem_attack_stage1.pfx', 1.0)
      .ActivateOnCreate
      .ScaleWithResource(reWelaCharge, 0.7, 1.0)
      .IsPiece;

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Colorless\big_caster_golem_attack_stage2.pfx', 1.0)
      .ActivateOnFire
      .IsPiece;

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Colorless\big_caster_golem_attack_stage3.pfx', 1.0)
      .ActivateOnCreate
      .IsPiece
      .VisibleWithResource(reWelaCharge);

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/big_caster_golem/attack_fire')
      .BindParameterToResource('intensity_level', reWelaCharge)
      .TriggerOnCreate()
      .StopOnFree
      .IsPiece;
  {$ENDIF}
end;
