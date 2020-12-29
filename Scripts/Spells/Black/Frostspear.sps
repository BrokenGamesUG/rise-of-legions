{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellEnemy]);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellGroup], reGold, GetCardBaseCost({@SBL_Tier}1, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), False, True, False) + 20);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'Frostspear')
      .IsCardDescription
      .Keyword('Frozen')
      .PassInteger('shard_count', 12)
      .PassInteger('damage_amount', 10, 'damage');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 5);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, SpellFreeze, SpellFreezeBase, ChargeGroup : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo);
  CreateData(Entity, SpellGroup, ChargeGroup);

  SpellFreeze := Entity.ReserveFreeGroup();
  SpellFreezeBase := Entity.ReserveFreeGroup();

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upBanished, upSpellImmune]);
  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [SpellGroup]);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);

    // freeze
    TWelaEffectFireComponent.CreateGrouped(Entity, [SpellGroup])
      .TargetGroup([SpellFreeze]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellFreeze])
      .MustHaveAny([upUnit, upBuilding])
      .MustNotHave([upCharm, upLegendary, upNexus, upImmuneToFrozen, upImmuneToStateEffects, upBase]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellFreeze]);
    TWelaEffectFireComponent.CreateGrouped(Entity, [SpellGroup])
      .TargetGroup([SpellFreezeBase]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellFreezeBase])
      .MustHave([upBase])
      .MustHaveAny([upBuilding])
      .MustNotHave([upCharm, upLegendary, upNexus, upImmuneToFrozen, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellFreezeBase]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [SpellFreezeBase])
      .Name('FrostspearBase')
      .TriggerOnFire;
    // ice shards - after possible freeze as it scales with the frozen state
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellFreeze], 'Modifiers\Frozen.dws');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellFreezeBase], 'Modifiers\Frozen.dws')
    .PassIntValue(5000)
    .MethodName('ApplyWithDuration');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Spells\Black\Frostspear.dws');

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetGeneric.png', 0)
      .SetSize(6.0, 0);

    TParticleEffectComponent.CreateGrouped(Entity, [SpellGroup], '\Black\frostspear_cast.pfx', 1.5)
      .ActivateOnFire()
      .ActivateAtFireTarget();

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/black/spell/frostspear/cast')
      .TriggerOnFire()
      .UsePositionOfTarget();
  {$ENDIF}
end;
