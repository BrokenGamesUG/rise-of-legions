{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 1.5;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecColorless);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upFlying, upGround, upMonumental, upUnit, upMelee, upLegendary, upTier3, upGolem]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atFortified);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}1900.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}1900.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1, 2], 0.5+{@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1, 2], [dtMelee, dtSplash]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1, 2], {@UBL_Damage}370.0);
  Entity.Blackboard.SetValue(eiCooldown, [1, 2], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [1, 2], 5.0);
  Entity.Blackboard.SetValue(eiWelaAreaOfEffectCone, [1, 2], 3.141 * 0.9);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 1600);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 2533);

  // Melee-Attack vs Air
  Entity.Blackboard.SetValue(eiWelaActionpoint, [2], 1166);
  Entity.Blackboard.SetValue(eiWelaActionduration, [2], 2333);

  // Asteroid
  Entity.Blackboard.SetValue(eiWelaAreaOfEffect, [3], 4.5);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 100.0);
  Entity.Blackboard.SetValue(eiDamageType, [3], [dtAbility, dtSplash]);
  Entity.Blackboard.SetValue(eiCooldown, [3], 500);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Legendary');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [], 'Monumental');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [1], 'Splash');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'DebutAsteroid')
      .PassInteger('damage_amount', 100, 'damage');
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,4,0), 2.0);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Colorless\BossGolem' + Entity.SkinFileSuffix + '\BossGolem.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 233, 289)
      .CreateNewAnimation(ANIMATION_ATTACK, 81, 156)
      .CreateNewAnimation(ANIMATION_ATTACK2, 157, 232)
      .CreateNewAnimation(ANIMATION_ATTACK_AIR, 290, 359)
      .CreateNewAnimation(ANIMATION_ATTACK_AIR2, 360, 429)
      .CreateNewAnimation(ANIMATION_STAND, 0, 79)
      .IgnoreScalingForAnimations
      .BindZoneToBone(BIND_ZONE_WEAPON, 'BossGolemRPalm')
      .BindZoneToBone(BIND_ZONE_CENTER, 'BossGolemRibcage')
      .BindZoneToBone(BIND_ZONE_HEAD, 'BossGolemHead');

    if Entity.SkinID = SKIN_GROUP_TOURNAMENT then
    begin
      TMeshEffectMetal.Create()
        .ShowAsColor(ecWhite)
        .AssignToEntity(Entity);
    end;

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 2])
      .HasAntiAirAttack
      .AlternatingAttack;
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.3], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
var PositionX, PositionY, PositionZ : array of single;
    Time : array of integer;
    i : integer;
    color : integer;
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1, 2])
      .MustNotHave([upInvisible, upBanished]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0, 1, 2]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1, 2], eiDamageable);


    TBrainWelaFightComponent.CreateGrouped(Entity, [2])
      .Blocking;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [2])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upGround]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upFlying])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [2]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('Splash')
      .TriggerOnKillDone;

    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1, 2], true);

    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upGround])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Splash')
      .TriggerOnKillDone;

    // starfall
    TThinkImpulseTimerCooldownComponent.CreateGrouped(Entity, [3]);
    TBrainWelaSelftargetGroundComponent.CreateGrouped(Entity, [3])
      .ThinksLocal
      .ThinksPassively;
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [3]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [3], eiDamageable);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [3]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [3])
      .Name('DebutAsteroid')
      .TriggerOnKillDone;
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [3]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(1600)
    .ApplyToSelfAtCreate();

  TUnitPropertyComponent.CreateGrouped(Entity, [], [upHasLegendaryUnit])
    .GivePropertyOwner();

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1, 2], 'event:/card/colorless/unit/boss_golem/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    // spawn - Asteroid
    // hide real unit
    TAnimatorComponent.CreateGrouped(Entity, [0, 1])
      .Duration(1500)
      .HideUntil(1400)
      .SizeKeypoints([0.0, 0.0, 1.0])
      .SizeTimes([0, 1300, 1500]);

    TMeshEffectComponent.CreateGrouped(Entity, [])
      .TargetGroup([0, 1])
      .SetEffect(
        TMeshEffectGlow.Create(2000)
          .AddKey(0, 0.1)
          .AddKey(1300, 0.2)
          .AddKey(1500, 0.1)
          .AddKey(2000, 0)
      );

    PositionX := [20.0, 0.0, 0];
    PositionY := [100.0, 0.8, 0.8];
    PositionZ := [-20.0, 0.0, 0.0];
    Time := [0, 350, 800];

    for i := 1 to 60 do
    begin
      PositionX := PositionX + [random * sin(PI * (1 - (0.4 * i / 60)))];
      PositionY := PositionY + [0.8 + (random * sin(PI * (1 - (0.4 * i / 60))))];
      PositionZ := PositionZ + [random * sin(PI * (1 - (0.4 * i / 60)))];
      Time := Time + [800 + i * 10];
    end;

    // show spawn mesh
    TAnimatorComponent.CreateGrouped(Entity, [9])
      .Duration(1500)
      .HideAfter(1400)
      .PositionKeypointsX(PositionX)
      .PositionKeypointsY(PositionY)
      .PositionKeypointsZ(PositionZ)
      .PositionTimes(Time)
      .FreeGroupAfter;

    TMeshComponent.CreateGrouped(Entity, [9], 'Units\Colorless\BossGolem' + Entity.SkinFileSuffix + '\Asteroid\Stone.xml')
      .ApplyLegacySizeFactor
      .FixedOrientationAngle(PI / 4, -PI * 1.3 / 4, 0)
      .IsPiece;

    if Entity.SkinID = SKIN_GROUP_TOURNAMENT then
    begin
      TMeshEffectMetal.Create()
        .ShowAsColor(ecWhite)
        .AssignToEntity(Entity);
    end;

    if Entity.SkinID = SKIN_GROUP_INFLAMED then
    begin
      color := $FFb83e26;
      TMeshEffectComponent.CreateGrouped(Entity, [])
      .TargetGroup([9])
      .SetEffect(
        TMeshEffectGlow.Create(2000)
          .FixedColorIdentity(ecRed)
          .AddKey(0, 0)
          .AddKey(800, 0)
          .AddKey(1400, 0.2)
      );
    end
    else
    begin
      color := $80FFFFFF;
      TMeshEffectComponent.CreateGrouped(Entity, [])
      .TargetGroup([9])
      .SetEffect(
        TMeshEffectGlow.Create(2000)
          .AddKey(0, 0)
          .AddKey(800, 0)
          .AddKey(1400, 0.2)
      );
    end;

    Entity.Eventbus.WriteGrouped(eiModelSize, [5.0], [9]);

    TVertexTraceComponent.CreateGrouped(Entity, [9])
      .Texture('Effects\Textures\StoneTrace.tga')
      .Color(color)
      .Width(0.85)
      .SamplingDistance(0.5)
      .FadeLength(20.0)
      .MaxLength(24.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.1)
      .RollUpSpeed(44)
      .DeactivateAfterTime(1000)
      .Additive
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [9]);

    TParticleEffectComponent.CreateGrouped(Entity, [9], '\Colorless\boss_golem' + Entity.SkinFileSuffix + '_spawn_trail.pfx', 7.0)
      .ActivateOnCreate()
      .Delay(50)
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [9]);

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/colorless/unit/boss_golem/spawn')
      .TriggerOnCreate();

    TParticleEffectComponent.CreateGrouped(Entity, [9], '\Colorless\boss_golem' + Entity.SkinFileSuffix + '_spawn.pfx', 1.0)
      .ActivateOnCreate
      .Delay(1300)
      .IgnoreModelSize
      .IgnoreSize;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Colorless\boss_golem' + Entity.SkinFileSuffix + '_spawn_impact.pfx', 4.0)
      .ActivateOnCreate
      .Delay(310)
      .ScaleWith(eiWelaAreaOfEffect)
      .IgnoreSize;

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\Colorless\colorless_border_wide_once.pfx', 5.0)
      .ActivateOnCreate
      .Delay(350)
      .FixedOrientationDefault
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedHeightGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TCameraShakerComponent.Create(Entity)
      .VectorShaker(0, -1, 0)
      .Strength(1.1)
      .Duration(700)
      .Waves(5)
      .ActivateOnCreate()
      .Delay(350);

    TCameraShakerComponent.Create(Entity)
      .RotationShaker(0, 0, 0.01)
      .Strength(1.1)
      .Duration(400)
      .Waves(2)
      .ActivateOnCreate()
      .Delay(350);
  {$ENDIF}
end;
