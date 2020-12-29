{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}3);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellArea, upSpellAlly]);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellGroup], reGold, GetCardBaseCost({@SBL_Tier}3, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), False, True, False) - 100);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctCoordinate);
  // effect
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [SpellGroup], 'Spells\Green\EvolveThistle');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EvolveThistle')
      .IsCardDescription
      .Keyword('Sapling')
      .PassInteger('target_count', 6);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 7);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 0);
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
