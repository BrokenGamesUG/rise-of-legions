{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}2);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellCharm, upSpellEnemy]);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellGroup], reGold, GetCardBaseCost({@SBL_Tier}2, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), False, True, False) - 20);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctCoordinate);
  // effect
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [SpellGroup], 'Spells\Black\OnTheEdge');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'OnTheEdge')
      .IsCardDescription
      .PassInteger('range_reduction', 3, 'range')
      .PassInteger('charge_amount', 10, 'counter');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EnchantmentGrievousWounds')
      .Keyword('Domain')
      .Keyword('Enchanted')
      .Keyword('Bleeding')
      .PassInteger('cooldown', 1);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 7);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, ChargeGroup : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo);
  CreateData(Entity, SpellGroup, ChargeGroup);

  {$IFDEF SERVER}
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [SpellGroup]);
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowPatternComponent.CreateGrouped(Entity, [SpellGroup]);

    TIndicatorShowTextComponent.CreateGrouped(Entity, [SpellGroup])
      .ShowResource(reCharmCount)
      .ResourceGroup([])
      .Color($FF03a9a3)
      .SpelltargetVisualizer;
  {$ENDIF}
end;
