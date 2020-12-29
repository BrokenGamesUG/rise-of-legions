{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.75;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecWhite);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier1, upUnit, upMelee, upGround]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}265.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}265.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reMana, 4);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reMana, 4);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1, 2, 3, 4], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1, 4], {@UBL_Damage}38.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [3], 10.0 + {@UBL_Damage}38.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2800);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 300);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 700);

  // Healpotion-Ability
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [5], reMana, 4);
  Entity.Blackboard.SetValue(eiWelaRange, [5], 6.0);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [5], 'Projectiles\White\MonkPotion');
  Entity.Blackboard.SetValue(eiWelaActionpoint, [5], 400);
  Entity.Blackboard.SetValue(eiWelaActionduration, [5], 650);

  // Mana-Reg
  Entity.Blackboard.SetValue(eiWelaDamage, [6], 1.0);
  Entity.Blackboard.SetValue(eiCooldown, [6], 3000);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [6], 'EnergyRegeneration')
      .PassInteger('energy_amount', 1, 'energy')
      .PassInteger('cooldown', 3);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3, 4], 'DragonPunch')
      .Keyword('Annihilated')
      .Keyword('Stunned')
      .PassInteger('damage_bonus', 10, 'damage')
      .PassPercentage('annihilate_threshold_percentage', 50, 'health');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [5], 'PurifyingPotion')
      .Keyword('StateEffect')
      .PassInteger('energy_cost', 4, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 3);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
{$IFDEF CLIENT}
var MeshComponent : TMeshComponent;
{$ENDIF}
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0, 0, 0), RVector3.Create(0, 0.8, 0), 0.9);

    MeshComponent := TMeshComponent.CreateGrouped(Entity, [0, 1, 2, 3, 4, 5], 'Units\White\Monk' + Entity.SkinFileSuffix + '\Monk.xml')
      .ApplyLegacySizeFactor;

    if Entity.SkinID = SKIN_GROUP_UNDERWORLD then
    begin
      MeshComponent
        .BindZoneToBone(BIND_ZONE_CENTER, 'Base HumanSpine4')
        .BoneSwapXY(BIND_ZONE_CENTER)
        .BindZoneToBone(BIND_ZONE_WEAPON, 'Base HumanRArmForearm')
        .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'Base HumanRArmPalm')
        .BindZoneToBone(BIND_ZONE_HEAD, 'Base HumanHead')
        .CreateNewAnimation(ANIMATION_STAND, 70, 130)
        .CreateNewAnimation(ANIMATION_WALK, 0, 39)
        .CreateNewAnimation(ANIMATION_ATTACK, 40, 69)
        .CreateNewAnimation(ANIMATION_ABILITY_1, 131, 169)
    end
    else
    begin
     MeshComponent
        .BindZoneToBone(BIND_ZONE_CENTER, 'MoinkSpine4')
        .BoneSwapXY(BIND_ZONE_CENTER)
        .BindZoneToBone(BIND_ZONE_WEAPON, 'MoinkRArmForearm')
        .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'MoinkRArmPalm')
        .BindZoneToBone(BIND_ZONE_HEAD, 'MoinkHead')
        .CreateNewAnimation(ANIMATION_STAND, 71, 131)
        .CreateNewAnimation(ANIMATION_WALK, 0, 40)
        .CreateNewAnimation(ANIMATION_ATTACK, 41, 70)
        .CreateNewAnimation(ANIMATION_ABILITY_1, 132, 170)
    end;

    MeshComponent
      .SetAnimationSpeed(ANIMATION_WALK, 0.7)
      .SetAnimationSpeed(ANIMATION_ABILITY_1, 0.5)
      .SetModelOffset(RVector3.Create(0, 20 / 128, 0));

    TMeshEffectMetal.Create().AssignToEntity(Entity);

    TAnimationComponent.CreateGrouped(Entity, [0, 1, 5])
      .AbilityGroup([5]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.3], [0]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitUnitEntity(Entity);

  {$IFDEF SERVER}
    // Approach for auto attack ------------------------------------------------------------------------
    TBrainApproachComponent.CreateGrouped(Entity, [0]);
    TWelaTargetingRadialAttentionComponent.CreateGrouped(Entity, [0])
      .SetTargetTeamConstraint(tcEnemies);

    // Healing potion ------------------------------------------------------------------------
    TBrainWelaFightComponent.CreateGrouped(Entity, [5])
      .Blocking;
    TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [5])
      .MustNotHave([upSilenced]);
    TWelaReadyCostComponent.CreateGrouped(Entity, [5])
      .SetPayingGroupForType(reMana, []);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [5])
      .SetTargetTeamConstraint(tcAllies);
    TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [5]);
    TWelaTargetConstraintNotSelfComponent.CreateGrouped(Entity, [5]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [5])
      .MustHave([upUnit, upHasStateEffect])
      .MustNotHave([upHasDrunkPotion]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [5])
      .SetPayingGroupForType(reMana, []);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [5]);
    TWelaEffectProjectileComponent.CreateGrouped(Entity, [5]);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [5])
      .SetCheckGroup([])
      .CheckNotFull(reMana)
      .SetsActive()
      .SetActivationGroup([6]);

    // Auto attack ------------------------------------------------------------------------
    TBrainWelaFightComponent.CreateGrouped(Entity, [1])
      .Preemptive;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [1], true);
    TWelaTargetingRadialComponent.CreateGrouped(Entity, [1])
      .SetTargetTeamConstraint(tcEnemies);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1, 2, 3, 4])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2, 3])
      .MustHave([upUnit])
      .MustNotHave([upBase]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2, 3])
      .Name('DragonPunch')
      .TriggerOnFire;

    TWelaEffectFireComponent.CreateGrouped(Entity, [1])
      .MultiTargetGroup([2])
      .MultiTargetGroup([3])
      .MultiTargetGroup([4]);

    // dragon punch against weaklings
    TWelaTargetConstraintResourceCompareComponent.CreateGrouped(Entity, [2])
      .ComparedResource(reHealth)
      .ComparedResource(reOverheal)
      .SetComparator(coGreater)
      .TargetFactor(2.0);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [2]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [2])
      .Exile;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [2])
      .Name('DragonPunchExile')
      .TriggerOnFire;

    // dragon punch against big enemies
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [3])
      .MustNotHave([upLegendary, upImmuneToStateEffects]);
    TWelaTargetConstraintResourceCompareComponent.CreateGrouped(Entity, [3])
      .ComparedResource(reHealth)
      .ComparedResource(reOverheal)
      .SetComparator(coGreater);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [3]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [3]);

    // normal auto attack
    TWelaEffectInstantComponent.CreateGrouped(Entity, [4]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [4]);

    // regenerate mana over time ------------------------------------------------------
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [6])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [6], False);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [6]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [6])
      .SetResourceType(reMana)
      .TargetGroup([]);
    TWelaEffectActivationAbilityComponent.CreateGrouped(Entity, [6])
      .SetCheckGroup([])
      .TriggerOnReachResourceCap(reMana);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [5], 'Modifiers\ImmuneToPotion.dws');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [3], 'Modifiers\Stun.dws');

  {$IFDEF CLIENT}
    TResourceDisplayIntegerProgressBarComponent.Create(Entity)
      .ShowResource(reMana)
      .HideIfEmpty;

    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/white/unit/monk/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;

    TSoundComponent.CreateGrouped(Entity, [2], 'event:/card/shared/effect/annihilate')
      .TriggerOnFire();

    TSoundComponent.CreateGrouped(Entity, [5], 'event:/card/white/unit/monk/potion_throw')
      .TriggerOnPreFire()
      .StopOnFree;

    TOrienterTargetComponent.CreateGrouped(Entity, [5]);

    TParticleEffectComponent.CreateGrouped(Entity, [3], '\White\monk_dragonpunch_impact.pfx', 0.8)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_HIT_ZONE, [0, 1]);

    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetRotationLight
      .ActivateOnFire;
    TCameraShakerComponent.CreateGrouped(Entity, [2])
      .PresetVectorLight
      .ActivateOnFire;
    TParticleEffectComponent.CreateGrouped(Entity, [2], '\White\monk_dragonpunch_exile_impact.pfx', 0.8)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_HIT_ZONE, [0, 1]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .ActivateOnFire
      .SetEffect(
        TMeshEffectTint.Create(400, $FFFFFFFF)
          .AddKey(0, 0.0)
          .AddKey(100, 1.0)
          .AddKey(400, 0.0)
    );
  {$ENDIF}
end;


