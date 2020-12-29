{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}27.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}27.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 2); // Multishot
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Green\ThistleProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}14.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 233);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1400);

  // Evasion 40%
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 0.40);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'MultiShot2')
      .PassInteger('target_count', 2);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'Evasion')
      .PassPercentage('evasion_percentage', 40);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,-0.2), RVector3.Create(0,1.4,-0.2), 0.6);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Thistle' + Entity.SkinFileSuffix + '\Thistle.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 30)
      .CreateNewAnimation(ANIMATION_ATTACK, 31, 72)
      .CreateNewAnimation(ANIMATION_STAND, 73, 133)
      .SetAnimationSpeed(ANIMATION_WALK, 0.91)
      .BindZoneToBone(BIND_ZONE_CENTER, 'FlowerSpine4')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'FlowerTail4')
      .BindZoneToBone(BIND_ZONE_HEAD, 'FlowerHead');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.25], [0]);
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
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    TBuffTakenDamageMultiplierComponent.CreateGrouped(Entity, [2])
      .DodgeDamage()
      .DamageTypeMustNotHave([dtSpell, dtDot, dtSplash]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Evade')
      .TriggerOnFire;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('EvadedThreeTimes')
      .CheckNth(3)
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/green/unit/thistle/attack_fire')
      .TriggerOnFire();

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Green\dodge.pfx', 1.5)
      .ActivateOnFire();
  {$ENDIF}
end;
