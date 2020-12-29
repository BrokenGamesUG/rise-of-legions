{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity, True);
  Entity.CollisionRadius := 0.85;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier3, upGround, upBuilding, upRanged, upGolem]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}570.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}570.0);

  // Ranged-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}11.0);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [1], 2); // Multishot
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Colorless\BigGolemTowerProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}1700);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}68.0);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'MultiShot2')
      .PassInteger('target_count', 2);

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
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,3.0,0), 0.95);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\BigGolemTower\BigGolemTower.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .BoneOffset(BIND_ZONE_TOP, 0, 0.9, -0.1)
      .BindZoneToBone(BIND_ZONE_HEAD, 'head')
      .BoneOffset(BIND_ZONE_HEAD, 0, 1.5, 0)
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BoneC')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneC');

    Entity.Eventbus.WriteGrouped(eiModelSize, [0.6], [0]);

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

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .SetTexture('SpelltargetShootingRange.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity, True);

  {$IFDEF SERVER}
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

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Colorless\big_golem_tower_attack.pfx', 0.4)
      .ActivateOnFire()
      .BindToSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/colorless/building/big_golem_tower/attack_fire')
      .TriggerOnFire();
  {$ENDIF}
end;


