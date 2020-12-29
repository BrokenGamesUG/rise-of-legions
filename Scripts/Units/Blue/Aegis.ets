{$INCLUDE 'BuildingTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitBuildingData(Entity);
  Entity.CollisionRadius := 1.4;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlue);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upMonumental, upFlying, upTier3, upGround, upBuilding, upRanged, upImmuneToBlinded, upLinkWeapon, upLegendary]);

  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}890.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}890.0);

  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 12);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 12);

  // rift cannon, ranged-attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], 11.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Projectiles\Blue\AegisRiftProjectile');
  Entity.Blackboard.SetValue(eiCooldown, [1], 4000);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 433);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 1033);

  // missile launcher
  Entity.Blackboard.SetValue(eiWelaActive, [2], False);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [2], reMana, 1);
  Entity.Blackboard.SetValue(eiWelaRange, [2], 15.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [2], 'Projectiles\Blue\AegisMissile');
  Entity.Blackboard.SetValue(eiCooldown, [2], 1800);
  Entity.Blackboard.SetValue(eiDamageType, [2], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [2], 53.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [2], 2.5);

  // gatling turrets, four directions
  Entity.Blackboard.SetValue(eiWelaActive, [3, 4, 5, 6], False);
  Entity.Blackboard.SetValue(eiWelaRange, [3, 4, 5, 6], 6.0);
  Entity.Blackboard.SetValue(eiLinkPattern, [3], 'Links\AegisGatlingLinkFront');
  Entity.Blackboard.SetValue(eiLinkPattern, [4], 'Links\AegisGatlingLinkLeft');
  Entity.Blackboard.SetValue(eiLinkPattern, [5], 'Links\AegisGatlingLinkBack');
  Entity.Blackboard.SetValue(eiLinkPattern, [6], 'Links\AegisGatlingLinkRight');
  Entity.Blackboard.SetValue(eiCooldown, [3, 4, 5, 6], 500);
  Entity.Blackboard.SetValue(eiDamageType, [3, 4, 5, 6], [dtRanged]);
  Entity.Blackboard.SetValue(eiWelaDamage, [3, 4, 5, 6], 5.9);

  // Starfall
  Entity.Blackboard.SetValue(eiWelaRange, [7], 1.5);
  Entity.Blackboard.SetValue(eiWelaTargetCount, [7], 200);
  Entity.Blackboard.SetValue(eiCooldown, [7], 333);

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, -0.5);

    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'Legendary');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'Monumental');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [7], 'DebutStarfall')
      .Keyword('Annihilated');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [ ], 'HeavilyArmed')
      .Keyword('Annihilated')
      .Keyword('Missile');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 0);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitBuildingMeta(Entity);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [7])
    .MustNotHave([upBase, upLegendary]);
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [7], eiDamageable);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,2,0), 1.4);

    // base
    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\Aegis.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 36, 36)
      .BindZoneToBone(BIND_ZONE_HIT_ZONE, 'CATRigHub002')
      .BoneSwapXZ('AimBone_RiftCannon_LeftRight')
      .BoneSwapXY('AimBone_RiftCannon_LeftRight')
      .BoneOffset(BIND_ZONE_TOP, 0, 1.0, 0)
      .FixedOrientation(-1, 0, 0);
    // rift cannon
    TMeshComponent.CreateGrouped(Entity, [1], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\AegisRiftCannon.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 31)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'AttackBone_Riftcannon') //Exhaust_Riftcannon
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BoneInvertY(BIND_ZONE_WEAPON_MUZZLE)
      .BindZoneToBone('charge', 'ZappyEffectBone_RiftCannon')
      .BoneInvertY('charge')
      .BindToSubPositionGroup('AimBone_RiftCannon_LeftRight', [0])
      .IsPiece;
    TAnimationComponent.CreateGrouped(Entity, [1]);
    // missile turret
    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\AegisMissiles.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 23)
      .CreateNewAnimation(ANIMATION_ATTACK2, 24, 45)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE + '0', 'AttackBone_Missiles_left')
      .BoneSwapXY(BIND_ZONE_WEAPON_MUZZLE + '0')
      .BoneSwapYZ(BIND_ZONE_WEAPON_MUZZLE + '0')
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE + '1', 'Attackbone_Missiles_right')
      .BoneSwapYZ(BIND_ZONE_WEAPON_MUZZLE + '1')
      .BoneSwapXY(BIND_ZONE_WEAPON_MUZZLE + '1')
      .BoneInvertX(BIND_ZONE_WEAPON_MUZZLE + '1')
      .AlternatingZone(BIND_ZONE_WEAPON_MUZZLE, 2)
      .BindZoneToBone('exhaust0', 'Exhaust_Missiles_Left')
      .BoneSwapYZ('exhaust0')
      .BoneInvertX('exhaust0')
      .BoneInvertY('exhaust0')
      .BindZoneToBone('exhaust1', 'Exhaust_Missiles_Right')
      .BoneSwapYZ('exhaust1')
      .BoneInvertZ('exhaust1')
      .AlternatingZone('exhaust', 2)
      .BindToSubPositionGroup('AimBone_RiftCannon_LeftRight', [0])
      .IsPiece;
    TAnimationComponent.CreateGrouped(Entity, [2])
      .AlternatingAttack;
    TOrienterFrontComponent.CreateGrouped(Entity, [1, 2])
      .Front(-1, 0, 0);
    // gatlings
    TMeshComponent.CreateGrouped(Entity, [3], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\AegisGatling.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 31)
      .CreateNewAnimation(ANIMATION_ATTACK_LOOP, 0, 31)
      .HasAttackLoop
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'AttackBone_Gatling')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindToSubPositionGroup('AimBone_Gatling_Front', [0])
      .IsPiece;
    TOrienterFrontComponent.CreateGrouped(Entity, [3])
      .Front(-1, 0, 0);
    TAnimationComponent.CreateGrouped(Entity, [3])
      .IsLink;
    TMeshComponent.CreateGrouped(Entity, [4], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\AegisGatling.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 31)
      .CreateNewAnimation(ANIMATION_ATTACK_LOOP, 0, 31)
      .HasAttackLoop
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'AttackBone_Gatling')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindToSubPositionGroup('AimBone_Gatling_Right', [0])
      .IsPiece;
    TOrienterFrontComponent.CreateGrouped(Entity, [4])
      .Front(0, 0, 1);
    TAnimationComponent.CreateGrouped(Entity, [4])
      .IsLink;
    TMeshComponent.CreateGrouped(Entity, [5], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\AegisGatling.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 31)
      .CreateNewAnimation(ANIMATION_ATTACK_LOOP, 0, 31)
      .HasAttackLoop
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'AttackBone_Gatling')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindToSubPositionGroup('AimBone_Gatling_Back', [0])
      .IsPiece;
    TOrienterFrontComponent.CreateGrouped(Entity, [5])
      .Front(1, 0, 0);
    TAnimationComponent.CreateGrouped(Entity, [5])
      .IsLink;
    TMeshComponent.CreateGrouped(Entity, [6], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\AegisGatling.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .CreateNewAnimation(ANIMATION_ATTACK, 0, 31)
      .CreateNewAnimation(ANIMATION_ATTACK_LOOP, 0, 31)
      .HasAttackLoop
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'AttackBone_Gatling')
      .BoneSwapXZ(BIND_ZONE_WEAPON_MUZZLE)
      .BindToSubPositionGroup('AimBone_Gatling_Left', [0])
      .IsPiece;
    TOrienterFrontComponent.CreateGrouped(Entity, [6])
      .Front(0, 0, -1);
    TAnimationComponent.CreateGrouped(Entity, [6])
      .IsLink;

    Entity.Eventbus.WriteGrouped(eiModelSize, [1.55], [0,1,2,3,4,5,6,7,8,9]);

    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [1])
      .ShowWeaponRange
      .SetTexture('SpelltargetGeneric.png');
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [2])
      .ShowWeaponRange
      .SetTexture('SpelltargetShootingRangeMissile.png');
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [3])
      .ShowWeaponRange
      .SetTexture('SpelltargetShootingRangeAngle.png')
      .Cone(-1, 0)
      .Offset(-0.8, 0);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [4])
      .ShowWeaponRange
      .SetTexture('SpelltargetShootingRangeAngle.png')
      .Cone(0, 1)
      .Offset(0, 0.8);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [5])
      .ShowWeaponRange
      .SetTexture('SpelltargetShootingRangeAngle.png')
      .Cone(1, 0)
      .Offset(0.8, 0);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [6])
      .ShowWeaponRange
      .SetTexture('SpelltargetShootingRangeAngle.png')
      .Cone(0, -1)
      .Offset(0, -0.8);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [7])
      .SetTexture('SpelltargetGeneric.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [7]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
var i : integer;
begin
  CreateMeta(Entity);
  InitBuildingEntity(Entity);

  {$IFDEF SERVER}
    // rift cannon
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaEfficiencyMaxHealthComponent.CreateGrouped(Entity, [1]);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [1], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upLegendary, upBase, upInvincible]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [1]);

    // missile
    TWelaHelperActivateTimerComponent.CreateGrouped(Entity, [2])
      .Delay(1600);
    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .ThinksPassively;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [2], eiDamageable);
    TWelaEfficiencyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .Prioritize([upFlying, upMonumental]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [2]);
    // every projectile costs
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [2])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('AmmoEmpty')
      .CheckResourceEmpty(reMana)
      .TriggerOnFire;

    for i := 3 to 6 do
    begin
      TWelaHelperActivateTimerComponent.CreateGrouped(Entity, [i])
        .Delay(1400);
      TBrainWelaLinkComponent.CreateGrouped(Entity, [i])
        .LinkTime(500)
        .ThinksPassively;
      TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [i])
        .MustNotHave([upInvisible, upBanished]);
      TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [i], eiDamageable);
      TWelaLinkEffectComponent.CreateGrouped(Entity, [i]);
    end;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [3])
      .Cone(-1, 0, PI * 2 / 3)
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [4])
      .Cone(0, 1, PI * 2 / 3)
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [5])
      .Cone(1, 0, PI * 2 / 3)
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [6])
      .Cone(0, -1, PI * 2 / 3)
      .SetTargetTeamConstraint(tcEnemies);

    // starfall
    TThinkImpulseImmediateComponent.CreateGrouped(Entity, [7, 8]);
    TBrainWelaFightComponent.CreateGrouped(Entity, [7])
      .ThinksLocal
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [7], false);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [7])
      .IgnoreOwnCollisionradius
      .SetTargetTeamConstraint(tcAll);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [7]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [7]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [7])
      .Name('DebutStarfall')
      .TriggerOnKillDone;
    TBrainWelaTargetlessComponent.CreateGrouped(Entity, [8]);
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [7, 8]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(1400)
    .ApplyToSelfAtCreate();

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    // starfall
    // hide real unit
    TAnimatorComponent.CreateGrouped(Entity, [0, 1, 2, 3, 4, 5, 6])
      .Duration(1600)
      .HideUntil(1500);

    // show spawn mesh
    TAnimatorComponent.CreateGrouped(Entity, [9])
      .Duration(1600)
      .HideAfter(1500)
      .PlayAnimation(0, ANIMATION_SPAWN, 1500)
      .FreeGroupAfter;

    TMeshComponent.CreateGrouped(Entity, [9], 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\AegisSpawn.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_SPAWN, 0, 43)
      .FixedOrientation(-1, 0, 0);

    TMeshEffectComponent.CreateGrouped(Entity, [9])
      .SetEffect(
        TMeshEffectGlow.Create(1100)
          .AddKey(0, 1)
          .AddKey(250, 0.6)
          .AddKey(1100, 0)
      );

    TVertexTraceComponent.CreateGrouped(Entity, [9])
      .Texture('Effects\Textures\Trace.tga')
      .Color($FF4fa6ff)
      .Width(0.85)
      .SamplingDistance(0.5)
      .FadeLength(20.0)
      .MaxLength(24.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.1)
      .RollUpSpeed(44)
      .DeactivateAfterTime(1000)
      .Additive
      .BindToSubPositionGroup('CATRigHub002', [9]);

    TParticleEffectComponent.CreateGrouped(Entity, [9], '\Blue\aegis' + Entity.SkinFileSuffix + '_fall.pfx', 2.0)
      .ActivateOnCreate()
      .Delay(50)
      .BindToSubPositionGroup('CATRigHub002', [9]);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/blue/unit/aegis/spawn')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [], '\Blue\aegis' + Entity.SkinFileSuffix + '_impact.pfx', 1.8)
      .ActivateOnCreate()
      .Delay(300)
      .IgnoreSize();

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(1.1)
      .Duration(700)
      .Waves(5)
      .ActivateOnCreate()
      .Delay(333);

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0, 0, 0.01)
      .Strength(1.1)
      .Duration(400)
      .Waves(2)
      .ActivateOnCreate()
      .Delay(333);

    // effects
    TParticleEffectComponent.CreateGrouped(Entity, [1], '\Blue\aegis' + Entity.SkinFileSuffix + '_rift_charge.pfx', 1.0)
      .ActivateOnPreFire()
      .BindToSubPositionGroup('charge', [1]);
    TParticleEffectComponent.CreateGrouped(Entity, [2], '\Blue\missile_turret_exhaust.pfx', 2.0)
      .ActivateOnFire()
      .BindToSubPositionGroup('exhaust', [2]);

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .RotationShaker(0.005, 0.005, 0.02)
      .Strength(0.5)
      .Duration(500)
      .Waves(4)
      .ActivateOnFire();

    TCameraShakerComponent.CreateGrouped(Entity, [1])
      .VectorShaker(0, -1, 0)
      .Strength(0.3)
      .Duration(500)
      .Waves(4)
      .ActivateOnFire();

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/blue/unit/aegis/attack_fire')
      .TriggerOnPreFire();
    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/blue/unit/aegis/missile_attack_fire')
      .TriggerOnFire();

    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana);

    TOrienterTargetComponent.CreateGrouped(Entity, [1])
      .FrontGroup([1])
      .FrontWithY
      .FrontFromPivot
      .KeepLastFront;
    TOrienterTargetComponent.CreateGrouped(Entity, [1, 2])
      .FrontGroup([2])
      .TargetGroup([1])
      .KeepLastFront;
    TOrienterTargetComponent.CreateGrouped(Entity, [3])
      .FrontGroup([3])
      .FrontWithY
      .FrontFromPivot;
    TOrienterTargetComponent.CreateGrouped(Entity, [4])
      .FrontGroup([4])
      .FrontWithY
      .FrontFromPivot;
    TOrienterTargetComponent.CreateGrouped(Entity, [5])
      .FrontGroup([5])
      .FrontWithY
      .FrontFromPivot;
    TOrienterTargetComponent.CreateGrouped(Entity, [6])
      .FrontGroup([6])
      .FrontWithY
      .FrontFromPivot;
  {$ENDIF}
end;
