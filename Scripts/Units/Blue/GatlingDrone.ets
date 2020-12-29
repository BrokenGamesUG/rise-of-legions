{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.55;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upGround, upRanged, upImmuneToBlinded, upLinkWeapon]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}98.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}98.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}6.0);
  Entity.Blackboard.SetValue(eiLinkPattern, [0, 1], 'Links\GatlingLink');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}500);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged, dtIgnoreArmor]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}11.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Surefire')
      .Keyword('Blinded');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'SearchingFire')
      .PassInteger('damage_amount', 3, 'damage');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'ArmorPiercing');

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.4,0.5), RVector3.Create(0,0.7,-0.5), 0.55);

    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Blue\GatlingDrone' + Entity.SkinFileSuffix + '\GatlingDrone.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 60, 90)
      .CreateNewAnimation(ANIMATION_WALK, 60, 90)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 30)
      .CreateNewAnimation(ANIMATION_ATTACK_LOOP, 0, 30)
      .HasAttackLoop
      .BindZoneToBone(BIND_ZONE_HEAD, 'CATRigHub001Bone001Bone001')
      .BoneSwapXZ(BIND_ZONE_HEAD)
      .BoneInvertY(BIND_ZONE_HEAD)
      .BoneOffset(BIND_ZONE_HEAD, 0, 0.15, -0.25)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'CATRigHub001Bone001Bone001')
      .BoneSwapXZ(BIND_ZONE_WEAPON)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'attackBone')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE);

    Entity.Eventbus.WriteGrouped(eiModelSize, [2.0], [0]);
    TAnimationComponent.CreateGrouped(Entity, [0, 1])
      .IsLink;
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
      .LinkTime(500)
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [0, 1]);
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
