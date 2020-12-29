{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellAlly]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'SurgeOfLight')
      .IsCardDescription
      .Keyword('Overheal')
      .PassInteger('heal_amount', 200, 'health')
      .PassInteger('counter_gained_amount', 1, 'counter')
      .PassInteger('damage_amount', 60, 'damage');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 4);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 2);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, ChargeGroup, SpellModeHeal, SpellModeDamage, SpellModeDamageCollect : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo, True);
  CreateData(Entity, SpellGroup, ChargeGroup);

  // variant 1 heal - target is ally
  SpellModeHeal := Entity.ReserveFreeGroup();
  Entity.Blackboard.SetValue(eiWelaDamage, [SpellModeHeal], 200.0);
  Entity.Blackboard.SetValue(eiDamageType, [SpellModeHeal], [dtFlatHeal, dtOverheal]);

  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [SpellModeHeal]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellModeHeal])
    .MustHave([upUnit])
    .MustNotHave([upBase, upUnhealable]);

  // variant 2 damage - target is enemy
  SpellModeDamage := Entity.ReserveFreeGroup();
  Entity.Blackboard.SetValue(eiWelaDamage, [SpellModeDamage], 60.0);
  Entity.Blackboard.SetValue(eiDamageType, [SpellModeDamage], [dtSpell]);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellModeDamage], reWelaCharge, 1);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [SpellModeDamage], reWelaCharge, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [SpellModeDamage], reWelaCharge, 1000);

  TWelaReadyCostComponent.CreateGrouped(Entity, [SpellModeDamage])
    .SetPayingGroupForType(reWelaCharge, [SpellModeDamage]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [SpellModeDamage]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellModeDamage])
    .MustHave([upUnit])
    .MustNotHave([upBase, upBanished, upSpellImmune]);
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [SpellModeDamage], eiDamageable);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup, SpellModeHeal, SpellModeDamage]);

    // heal allied unit, generate charges for damage mode
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellModeHeal]);
    TWarheadSpottyHealComponent.CreateGrouped(Entity, [SpellModeHeal]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [SpellModeHeal])
      .Name('SurgeOfLightModeHeal')
      .Name('FlatHeal')
      .TriggerOnFire;
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [SpellModeHeal])
      .SetResourceType(reWelaCharge)
      .SetResourceSource(eiNone)
      .SetFactor(1.0) // one charge
      .TargetGroup([SpellModeDamage])
      .RedirectToSelf;

    // damage enemy unit, consumes all charges
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellModeDamage]);
    TModifierWelaDamageComponent.CreateGrouped(Entity, [SpellModeDamage])
      .Multiply
      .ScaleWithResource(reWelaCharge)
      .ResourceGroup([SpellModeDamage]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [SpellModeDamage]);
    TWelaEffectPayCostComponent.CreateGrouped(Entity, [SpellModeDamage])
      .ConsumesAll()
      .SetPayingGroupForType(reWelaCharge, [SpellModeDamage]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [SpellModeDamage])
      .Name('SurgeOfLightModeDamage')
      .TriggerOnKillDone
      .TriggerGlobalOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [SpellModeDamage])
      .Name('Spell')
      .TriggerOnDamageDone;

    TCommanderAbility.CreateGrouped(Entity, [SpellGroup])
      .CardInfo(CardInfo)
      .ChargeGroup([ChargeGroup])
      .IsMultiMode([SpellModeHeal, SpellModeDamage]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup, SpellModeHeal, SpellModeDamage])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);

    TIndicatorShowTextComponent.CreateGrouped(Entity, [SpellGroup, SpellModeHeal, SpellModeDamage])
      .ShowResource(reWelaCharge)
      .ResourceGroup([SpellModeDamage])
      .Color($FFF6F7A5)
      .SpelltargetVisualizer;

    TSoundComponent.CreateGrouped(Entity, [SpellModeHeal], 'event:/card/white/spell/surge_of_light/heal_cast')
      .TriggerOnFireWarhead()
      .UsePositionOfTarget();

    TParticleEffectComponent.CreateGrouped(Entity, [SpellModeHeal], '\White\surge_of_light_heal.pfx', 2.0)
      .ActivateOnFireWarhead()
      .ClonesToTarget()
      .FixedOrientationDefault
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [SpellModeDamage], 'event:/card/white/spell/surge_of_light/damage_cast')
      .TriggerOnFireWarhead()
      .UsePositionOfTarget();

    TParticleEffectComponent.CreateGrouped(Entity, [SpellModeDamage], '\White\surge_of_light_damage.pfx', 2.0)
      .ActivateOnFireWarhead()
      .ClonesToTarget()
      .FixedOrientationDefault
      .BindToSubPositionGroup(BIND_ZONE_CENTER, [0, 1]);

    TDeckCardButtonComponent.CreateGrouped(Entity, [SpellGroup])
      .Slot(Slot)
      .CardInfo(CardInfo)
      .SetCooldownGroup([ChargeGroup])
      .IsMultiMode([SpellModeHeal, SpellModeDamage]);
  {$ENDIF}
end;
