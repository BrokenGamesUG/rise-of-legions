{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}2);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellCharm, upSpellAlly]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctCoordinate);
  // effect
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [SpellGroup], 'Spells\Blue\Fluxfield');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'FluxField')
      .IsCardDescription
      .Keyword('Domain')
      .Keyword('Silenced')
      .PassInteger('charge_amount', 6, 'counter');
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EnchantmentFlux')
      .Keyword('Enchanted')
      .PassInteger('energy_regeneration_amount', 1, 'energy')
      .PassInteger('energy_regeneration_cooldown', 3)
      .PassInteger('energy_regeneration_cap', 4, 'energy')
      .PassInteger('energy_cap_increase', 2, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 3);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 0);
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
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [SpellGroup])
      .PassCardValues;
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
