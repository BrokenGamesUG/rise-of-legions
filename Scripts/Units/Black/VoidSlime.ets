{$INCLUDE 'UnitTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitUnitData(Entity);
  Entity.CollisionRadius := 0.7;
  Entity.Blackboard.SetValue(eiColorIdentity, [], ecBlack);
  Entity.Blackboard.SetValue(eiUnitProperties, [], [upTier2, upUnit, upGround, upMelee]);
  Entity.Blackboard.SetValue(eiArmorType, [], {@UBL_Armortype}atUnarmored);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, {@UBL_Health}495.0);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, {@UBL_Health}495.0);

  // Melee-Attack
  Entity.Blackboard.SetValue(eiWelaRange, [0, 1], {@UBL_Range}1.0);
  Entity.Blackboard.SetValue(eiDamageType, [1], [dtMelee]);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], {@UBL_Damage}100.0);
  Entity.Blackboard.SetValue(eiCooldown, [1], {@UBL_Cooldown}2300);
  Entity.Blackboard.SetValue(eiWelaActionpoint, [1], 350);
  Entity.Blackboard.SetValue(eiWelaActionduration, [1], 966);

  Entity.Blackboard.SetValue(eiCooldown, [2], 200);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'StatusAbsorb')
      .Keyword('StateEffect')
      .PassInteger('health_amount', 250, 'health');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [3], 'StatusCopy')
      .Keyword('StateEffect');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [2], 'StatusMirror')
      .Keyword('StateEffect')
      .PassSingle('cooldown', 0, 2);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [], reMetaUtility, 6);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitUnitMeta(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0.5,-0.3), RVector3.Create(0,0.5,0.3), 0.75);

    TMeshComponent.CreateGrouped(Entity, [0, 1], 'Units\Black\VoidSlime\VoidSlime.xml')
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_WALK, 0, 50)
      .CreateNewAnimation(ANIMATION_ATTACK, 51, 79)
      .CreateNewAnimation(ANIMATION_STAND, 81, 139)
      .BindZoneToBone(BIND_ZONE_HEAD, 'VoidSlime_Head')
      .BindZoneToBone(BIND_ZONE_WEAPON, 'VoidSlime_Head')
      .BindZoneToBone(BIND_ZONE_CENTER, 'VoidslimeSpine2')
      .IgnoreScalingForAnimations;

    TMeshEffectMatCap.Create()
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapSlime.png')
      .AssignToEntity(Entity);

    TAnimationComponent.CreateGrouped(Entity, [0, 1]);
    Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
  {$ENDIF}
end;

procedure ApplyMirrorToSelf(Entity : TEntity; StateEffect : integer; Script : string);
var EnemyCheckGroup, SelfCheckGroup : integer;
begin
  EnemyCheckGroup := Entity.ReserveFreeGroup();
  SelfCheckGroup := Entity.ReserveFreeGroup();
  {$IFDEF SERVER}
    // whenever the primary wela deals damage to a unit
    TAutoBrainOnDealDamageComponent.CreateGrouped(Entity, [1])
      .FireInGroup([EnemyCheckGroup]);
    // which has a state effect
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [EnemyCheckGroup])
      .MustHave([StateEffect]);
    // fire at our self
    TWelaEffectFireComponent.CreateGrouped(Entity, [EnemyCheckGroup])
      .TargetGroup([SelfCheckGroup])
      .RedirectToSelf;
    // if we don't have the state effect already
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SelfCheckGroup])
      .MustNotHave([StateEffect]);
    // and so applying it to us
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SelfCheckGroup]);
  {$ENDIF}
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SelfCheckGroup], Script);
end;

procedure ApplyMirrorToEnemy(Entity : TEntity; StateEffect, StateEffectImmunity, SecondImmunity : integer; Script, WelaName : string);
var EnemyCheckGroup, SelfCheckGroup : integer;
begin
  EnemyCheckGroup := Entity.ReserveFreeGroup();
  SelfCheckGroup := Entity.ReserveFreeGroup();
  {$IFDEF SERVER}
    // whenever this unit gets
    TAutoBrainOnTakeDamageComponent.CreateGrouped(Entity, [2])
      .CheckSelfForTargetsInGroup([SelfCheckGroup])
      .FireTargetsInGroup([EnemyCheckGroup])
      .ThinksPassively;
    TWelaReadyCooldownComponent.CreateGrouped(Entity, [2, EnemyCheckGroup], true);
    // and has a state effect
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SelfCheckGroup])
      .MustHave([StateEffect]);
    // while the enemy has no immunity against it
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [EnemyCheckGroup])
      .MustHave([upUnit])
      .MustNotHave([StateEffectImmunity, SecondImmunity, upLegendary, upImmuneToStateEffects]);
    // apply it to it
    TWelaEffectInstantComponent.CreateGrouped(Entity, [EnemyCheckGroup]);

    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [EnemyCheckGroup])
      .Name(WelaName)
      .Name('MirrorStatus')
      .TriggerOnFire;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [EnemyCheckGroup], Script);

  {$IFDEF CLIENT}
    TParticleEffectComponent.CreateGrouped(Entity, [EnemyCheckGroup], '\Black\voidslime_mirror.pfx', 0.9)
      .ScaleWith(eiCollisionRadius)
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);
    TParticleEffectComponent.CreateGrouped(Entity, [EnemyCheckGroup], '\Black\voidslime_mirror.pfx', 0.9)
      .ScaleWith(eiCollisionRadius)
      .ActivateAtFireTarget()
      .ActivateOnFireWarhead()
      .BindToSubPositionGroup(BIND_ZONE_HIT_ZONE, [0, 1]);
  {$ENDIF}
end;

procedure ApplyAbsorbToSelf(Entity : TEntity; StateEffect : integer);
var Group : integer;
begin
  Group := Entity.ReserveFreeGroup();
  Entity.Blackboard.SetValue(eiWelaDamage, [Group], 250.0);

  {$IFDEF SERVER}
    TAutoBrainOnUnitPropertyComponent.CreateGrouped(Entity, [Group])
      .TriggerOn([StateEffect]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [Group]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [Group])
      .SetResourceType(reHealth)
      .ChangesMax;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [Group])
      .Name('StatusAbsorb')
      .TriggerOnFire;
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [Group]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [Group], 'event:/card/black/unit/voidslime/absorb_fire')
      .TriggerOnFire();
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
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0, 1], eiDamageable);
    TWelaTargetConstraintCompareUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .BothMustHaveAny([upGround, upFlying]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0, 1])
      .MustNotHave([upInvisible, upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [1]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [1])
      .Name('Melee')
      .TriggerOnDie
      .TriggerOnKillDone;
  {$ENDIF}

  // first time state effect are listened in own groups
  ApplyAbsorbToSelf(Entity, upStunned);
  ApplyAbsorbToSelf(Entity, upRooted);
  ApplyAbsorbToSelf(Entity, upBlinded);
  ApplyAbsorbToSelf(Entity, upFrozen);
  ApplyAbsorbToSelf(Entity, upLifted);
  ApplyAbsorbToSelf(Entity, upBanished);
  ApplyAbsorbToSelf(Entity, upSilenced);
  ApplyAbsorbToSelf(Entity, upBleeding);
  ApplyAbsorbToSelf(Entity, upBefogged);
  ApplyAbsorbToSelf(Entity, upPetrified);
  // sitting in [1] together with primary weapon
  // mirror ability, checks on hit for each state effect and if itself has not this effect it is applied to the slime
  ApplyMirrorToSelf(Entity, upStunned, 'Modifiers\Stun.dws');
  ApplyMirrorToSelf(Entity, upRooted, 'Modifiers\Root.dws');
  ApplyMirrorToSelf(Entity, upBlinded, 'Modifiers\Blind.dws');
  ApplyMirrorToSelf(Entity, upFrozen, 'Modifiers\Frozen.dws');
  ApplyMirrorToSelf(Entity, upLifted, 'Modifiers\Lifted.dws');
  ApplyMirrorToSelf(Entity, upBanished, 'Modifiers\Banished.dws');
  ApplyMirrorToSelf(Entity, upBleeding, 'Modifiers\Bleeding.dws');
  ApplyMirrorToSelf(Entity, upPetrified, 'Modifiers\Petrified.dws');
  // sitting in [2] to listen to damage
  // backward mirror, checks on being hit for each state effect if itself has this effect and then applying to the attacker
  ApplyMirrorToEnemy(Entity, upStunned, upStunned, upStunned, 'Modifiers\Stun.dws', 'Stun');
  ApplyMirrorToEnemy(Entity, upRooted, upImmuneToRooted, upImmuneToRooted, 'Modifiers\Root.dws', 'Root');
  ApplyMirrorToEnemy(Entity, upBlinded, upImmuneToBlinded, upNoAutoAttack, 'Modifiers\Blind.dws', 'Blind');
  ApplyMirrorToEnemy(Entity, upFrozen, upImmuneToFrozen, upImmuneToFrozen, 'Modifiers\Frozen.dws', 'Frozen');
  ApplyMirrorToEnemy(Entity, upLifted, upImmuneToLifted, upFlying, 'Modifiers\Lifted.dws', 'Lifted');
  ApplyMirrorToEnemy(Entity, upBleeding, upBleeding, upBleeding, 'Modifiers\Bleeding.dws', 'Bleeding');
  ApplyMirrorToEnemy(Entity, upPetrified, upImmuneToPetrified, upImmuneToPetrified, 'Modifiers\Petrified.dws', 'Petrified');

  {$IFDEF CLIENT}
    TSoundComponent.CreateGrouped(Entity, [1], 'event:/card/black/unit/voidslime/attack_fire')
      .TriggerOnPreFire()
      .StopOnFree;
  {$ENDIF}
end;
