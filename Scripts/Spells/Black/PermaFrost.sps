{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}2);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellGroup], reGold, GetCardBaseCost({@SBL_Tier}2, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), False, True, False) - 30);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellEnemy]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'Permafrost')
      .Keyword('Enchanted')
      .Keyword('Frozen')
      .PassInteger('ally_health_amount', 300, 'health')
      .PassInteger('enemy_health_reduction_amount', 300, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 2);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, ChargeGroup : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo);
  CreateData(Entity, SpellGroup, ChargeGroup);

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHave([upUnit])
    .MustNotHave([upBase, upLegendary, upBlessedHardening, upSpellImmune]);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
    TWelaEffectRemoveBeaconComponent.CreateGrouped(Entity, [SpellGroup])
      .SearchForWelaBeacon([upFrozen]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Modifiers\Frozen.dws');
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Spells\Black\PermaFrost.dws')
    .PassSameTeam;

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/black/spell/permafrost/cast')
      .UsePositionOfTarget
      .TriggerOnFire();
  {$ENDIF}
end;
