{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.6;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upUnit, upGround, upRanged, upImmuneToBlinded, upGolem, upLinkWeapon]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atMedium);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}340.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}340.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}8.0);
  Entity.Blackboard.SetValue(eiLinkPattern, [1], 'Links\BigCasterGolemLink');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}500);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}21.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Surefire')
      .Keyword('Blinded');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'Intensify')
      .PassInteger('cooldown', 3)
      .PassPercentage('damage_increase_percentage', 50, 'damage')
      .PassInteger('cap', 2);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 2);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0.1), RVector3.Create(0,1.6,0.1), 0.8);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\BigCasterGolem\BigCasterGolem.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'boneC')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'boneC');

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.5], [0, 1]);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Colorless\SharedCrystal\Crystal.xml')
      .IgnoreScalingForAnimations
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .FixedOrientationDefault
      .BindToSubPositionGroup('BoneC', [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystalNeutral.png')
      );

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.7], [2]);
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
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;



