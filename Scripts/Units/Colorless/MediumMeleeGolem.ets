{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.65;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upMelee, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}190.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}190.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}17.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2300);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1], 6.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffectCone, [1], 3.141 * 0.25);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 533);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1133);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Tremor');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 6);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,1.2,0), 1.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\MediumMeleeGolem' + Entity.SkinFileSuffix + '\MediumMeleeGolem.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 29)
      .CreateNewAnimation(ANIMATION_ATTACK, 92, 125)
      .CreateNewAnimation(ANIMATION_STAND, 31, 90)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_CENTER, 'MediumMeleeGolemPelvis')
      .BindZoneToBone(BIND_ZONE_HEAD, 'MediumMeleeGolemHead')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'MediumMeleeGolemRArmPalm');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.55], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\medium_melee_golem_powerstrike.pfx', 6.0)
      .ActivateOnFire()
      .ScaleWith(eiWelaAreaOfEffect)
      .SwapXZBindMatrix;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/unit/medium_melee_golem/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;








