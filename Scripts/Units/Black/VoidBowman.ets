{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}60.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}60.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Black\VoidBowmanProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}20.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 366);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1200);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'DebutInsidious');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'EnchantmentGrievousWounds')
      .Keyword('Enchanted')
      .Keyword('Bleeding')
      .PassInteger('cooldown', 1);

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0.1,0,0.2), RVector3.Create(0.1,1.0,0.2), 0.7);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidBowman' + Entity.SkinFileSuffix + '\VoidBowman.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 26)
      .CreateNewAnimation(ANIMATION_ATTACK, 27, 62)
      .CreateNewAnimation(ANIMATION_STAND, 63, 123)
      .SetAnimationSpeed(ANIMATION_WALK, 0.95)
      .BindZoneToBone(BIND_ZONE_CENTER, 'SkeletonSpine3')
      .BindZoneToBone(BIND_ZONE_HEAD, 'SkeletonHead')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'SkeletonRThumb1')
      .BoneSwapXZ(BIND_ZONE_WEAPON)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'SkeletonRThumb1')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindTextureToUnitProperty(mtGlow, 'MultishotGlow.tga', [upBlessedGrievousWounds])
      .SetModelOffset(RVector3.Create(0, 0, -0.25));

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
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  // debut insidious
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [2], 'Modifiers\BlessingGrievousWounds.dws')
    .ApplyToSelfAtCreate
    .Methodname('ApplyWithoutEffect');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/voidbowman/attack_fire')
      .TriggerOnFire();
  {$ENDIF}
end;



