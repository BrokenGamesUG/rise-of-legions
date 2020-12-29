{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, True);
  Entity.CollisionRadius := 0.95;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upGround, upBuilding, upRanged]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}465.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}465.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}11.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\White\SuntowerProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2000);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}50.0);

  // Homeland
  Entity.Blackboard.SetValue(eiWelaRange, [2, 3], 5.5);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [2, 3], 200);
  Entity.Blackboard.SetValue(eiLinkPattern, [2, 3], 'Links\HomelandAura');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'Homeland')
      .Keyword('Rescued')
      .Keyword('StateEffect');

    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, -1.4);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 7);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,2.4,0), 0.95);

    TMeshComponent.CreateGrouped(Entity, [0], 'Units\White\Suntower\Suntower.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 49)
      .BoneOffset(BIND_ZONE_TOP, 0, 1.4, 0)
      .BindZoneToBone(BIND_ZONE_HEAD, 'head')
      .BoneOffset(BIND_ZONE_HEAD, 0, 1.6, 0)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'Object499')
      .SetModelOffset(0, 2.0, 0)
      .FixedOrientationDefault;

    TMeshEffectMetal.Create()
      .AssignToEntity(Entity);
    Entity.Eventbus.WriteGrouped(eiModelSize, [0.75], [0]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetShootingRange.png');
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [2])
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, True);

  {$IFDEF SERVER}
    // Homeland
    TBrainWelaLinkComponent.CreateGrouped(Entity, [2])
      .ThinksPassively();
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .IgnoreOwnCollisionradius
      .SetValidateGroup([3]) //don't validate against the buffed property, otherwise aura would be killed instantly after applied
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit])
      .MustNotHave([upBase, upLegendary, upImmuneToRescued, upRescued]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 3])
      .MustHave([upUnit])
      .MustNotHave([upBase, upLegendary, upImmuneToRescued]);
    TWelaLinkEffectComponent.CreateGrouped(Entity, [2, 3]);

    // Auto-Attack
    TBrainWelaFightComponent.CreateGrouped(Entity, [1]);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [0], '\White\suntower_idle.pfx', 6.0)
      .ActivateOnCreate()
      .SetModelOffset(RVector3.Create(0, 3.5, 0));

    TParticleEffectComponent.CreateGrouped(Entity, [1], '\White\suntower_attack.pfx', 2.0)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\white_border_wide.pfx', 5.0)
      .ActivateOnCreate()
      .ScaleWith(eiWelaRange)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/building/suntower/attack_fire')
      .TriggerOnFire()
      .StopOnFree;
  {$ENDIF}
end;


