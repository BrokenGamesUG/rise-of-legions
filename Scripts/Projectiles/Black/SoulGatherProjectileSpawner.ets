{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaDamage, [0], 1.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [0], 1);
  Entity.Blackboard.SetValue(eiWelaRange, [0], 12.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0], 'Projectiles\Black\SoulGatherProjectile');
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
    TThinkImpulseOnceComponent.CreateGrouped(Entity, [0])
      .WaitOneFrame;

    TBrainWelaFightComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcAll)
      .SetTargetTeamConstraintPriority(tcAllies)
      .PicksRandomTargets;
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustHave([upSoulGatherer]);
    TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [0])
      .CheckResource(reMana)
      .CheckNotFull();
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaEffectSuicideComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
