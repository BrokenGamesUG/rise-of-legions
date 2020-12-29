{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, True, {@SBL_Tier}3);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upLegendary, upSpellArea, upSpellEnemy]);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellGroup], reGold, GetCardBaseCost({@SBL_Tier}3, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), True, True, False) - 80);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctCoordinate);

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [SpellGroup], 'Spells\Green\Saplingcharge');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'Saplingcharge')
      .IsCardDescription
      .PassInteger('initial_sapling_amount', 15)
      .PassInteger('wave_sapling_amount', 10)
      .PassInteger('wave_count', 11);
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'Legendary')
      .Keyword('Sapling')
      .Keyword('Timed');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 2);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 6);
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
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [SpellGroup])
      .PassCardValues;
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}


  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowPatternComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}
end;
