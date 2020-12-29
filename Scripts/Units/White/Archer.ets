{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged, upHasDeathRattle]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}19.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}19.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1, 4], {@UBL_Range}10.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\White\ArcherProjectile');
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [4], 'Projectiles\White\ArcherDeathCryProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiDamageType, [1, 4], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1, 4], {@UBL_Damage}20.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 350);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 833);

  // Relentless: Stunned
  Entity.Blackboard.SetValue(eiWelaModifier, [2], 1.5); // 150% damage against state effect
  Entity.Blackboard.SetValue(eiWelaModifier, [3], 2.0); // 200% damage against stunned

  // Deathrattle: Bent Bow [4]

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'RelentlessStunned')
      .Keyword('Stunned')
      .Keyword('StateEffect')
      .PassPercentage('primary_damage_amount_percentage', 200, 'damage')
      .PassPercentage('secondary_damage_amount_percentage', 150, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'DeathrattleBentBow');

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0.1), RVector3.Create(0,1.2,0.1), 0.6);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\White\Archer' + Entity.SkinFileSuffix + '\Archer.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 46, 106)
      .CreateNewAnimation(ANIMATION_WALK, 0, 20)
      .CreateNewAnimation(ANIMATION_ATTACK, 21, 45)
      .SetAnimationSpeed(ANIMATION_WALK, 0.91)
      .BindZoneToBone(BIND_ZONE_CENTER, 'ArcherSpine4')
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'archerBow_center')
      .BoneSwapXZ(BIND_ZONE_WEAPON)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'archerBow_center')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone(BIND_ZONE_HEAD, 'ArcherHead');

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
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
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 4])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1, 4], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    // extra damage
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [1])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([2]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHaveAny([upFrozen, upBlinded, upRooted, upGrounded, upLifted, upBleeding, upPetrified])
      .MustNotHave([upStunned]);
    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [1])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustHave([upStunned]);

    // fires arrow on death
    TAutoBrainOnBeforeDeath.CreateGrouped(Entity, [4])
      .FireAtTarget();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .SetTargetTeamConstraint(tcEnemies)
      .PicksRandomTargets;
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [4]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [4])
      .Name('DeathRattle')
      .Name('DeathRattleBentBow')
      .TriggerOnFire;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1, 4], 'event:/card/white/unit/archer/attack_fire')
      .TriggerOnFire()
      .StopOnFree;
  {$ENDIF}
end;



