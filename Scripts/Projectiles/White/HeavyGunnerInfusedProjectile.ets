var
  InheritsFrom : string = 'Projectiles/White/HeavyGunnerBaseProjectile.ets';

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiWelaRange, [1, 2, 3, 4], 3.5);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1, 2, 3, 4], 200);
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
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Lightgrenades')
      .TriggerOnDamageDoneTargets;

    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([1]);
    TThinkImpulseFireComponent.CreateGrouped(Entity, [1])
      .TargetGroup([2]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .ThinksLocal;
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit, upGround])
      .MustNotHave([upLegendary, upNoAutoAttack, upImmuneToBlinded, upImmuneToStateEffects]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [2]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Blind')
      .TriggerOnFire;

    TWelaEffectFireComponent.CreateGrouped(Entity, [0])
      .TargetGroup([3]);
    TThinkImpulseFireComponent.CreateGrouped(Entity, [3])
      .TargetGroup([4]);

    TBrainWelaFightComponent.CreateGrouped(Entity, [4])
      .ThinksLocal;
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [4])
      .MustHave([upUnit, upGround])
      .MustNotHave([upLegendary, upImmuneToStateEffects]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [4]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('Stun')
      .TriggerOnFire;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\Blind.dws');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [4], 'Modifiers\Stun.dws');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/heavy_gunner/attack_impact_infused')
      .TriggerOnFire();

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\light_pulse_cast.pfx', 5.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaRange)
      .FixedOffsetGround;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationMedium
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorMedium
      .ActivateOnFree;
  {$ENDIF}
end;
