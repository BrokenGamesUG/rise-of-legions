{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellAlly]);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellGroup], reGold, GetCardBaseCost({@SBL_Tier}1, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), False, True, False) + 10);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EnchantmentFrenzy')
      .Keyword('Enchanted')
      .Keyword('StateEffect')
      .PassInteger('duration', 10)
      .PassPercentage('attack_speed_bonus_percentage', 200, 'damage')
      .PassPercentage('attack_speed_bonus_ranged_percentage', 150, 'damage')
      .PassInteger('heal_amount', 70, 'health')
      .PassInteger('additional_target_count', 1);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 8);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 0);
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

  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [SpellGroup]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHave([upUnit])
    .MustNotHave([upBase, upBlessedFrenzy]);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
    TWarheadSpottyRemoveBuffComponent.CreateGrouped(Entity, [SpellGroup])
      .MustHaveAny([btState]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Modifiers\BlessingFrenzy.dws');

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/black/spell/frenzy/cast')
      .UsePositionOfTarget
      .TriggerOnFire();
  {$ENDIF}
end;
