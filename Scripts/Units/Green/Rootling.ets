{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.45;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecGreen);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRangedGroundOnly, upRanged, upImmuneToBlinded, upLinkWeapon]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atLight);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}200.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}200.0);

  // Ranged-Attack with root
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}5.0);
  Entity.Blackboard.SetValue(eiLinkPattern, [1], 'Links/RootlingLink');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1000);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}12.0);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 500);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 500);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'GroundOnly');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Surefire')
      .Keyword('Blinded');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Root')
      .Keyword('Rooted');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'RootNetwork')
      .Keyword('Rooted')
      .PassInteger('damage_amount', 10, 'damage');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 5);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0), RVector3.Create(0, 1.0, 0), 0.8);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Green\Rootling' + Entity.SkinFileSuffix + '\Rootling.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 17)
      .CreateNewAnimation(ANIMATION_ATTACK, 18, 32)
      .CreateNewAnimation(ANIMATION_ATTACK_LOOP, 32, 54)
      //.CreateNewAnimation(ANIMATION_ATTACK_LOOP_END, 54, 63)
      .CreateNewAnimation(ANIMATION_STAND, 64, 124)
      .BindZoneToBone(BIND_ZONE_CENTER, 'RootlingHeadBone001')
      .BoneSwapXY(BIND_ZONE_CENTER)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'RootlingHeadBone003')
      .BindZoneToBone(BIND_ZONE_HEAD, 'RootlingHeadBone003')
      .HasAttackLoop
      .SetAnimationSpeed(ANIMATION_WALK, 1.69);

    TAnimationComponent.CreateGrouped(Entity, [0, 1])
      .IsLink;
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.8], [0]);
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

    TBrainWelaLinkComponent.CreateGrouped(Entity, [1])
      .LinkTime(1000)
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
