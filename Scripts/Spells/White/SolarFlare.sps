{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}3);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellAlly]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'SolarFlare')
      .IsCardDescription
      .Keyword('Overheal')
      .PassInteger('primary_heal_amount', 400, 'health')
      .PassInteger('splash_heal_amount', 25, 'health')
      .PassInteger('duration', 10);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 10);
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

  // initial heal on single target
  Entity.Blackboard.SetValue(eiWelaDamage, [SpellGroup], 400.0);
  Entity.Blackboard.SetValue(eiDamageType, [SpellGroup], [dtFlatHeal, dtOverheal]);

  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [SpellGroup]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHave([upUnit]);

  {$IFDEF SERVER}
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
    TWarheadSpottyHealComponent.CreateGrouped(Entity, [SpellGroup]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [SpellGroup])
      .Name('FlatHeal')
      .TriggerOnFire;
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Spells\White\SolarFlare.dws')
    .PassResource(reCardLeague);

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetGeneric.png', 0)
      .SetSize(8.0, 0);
  {$ENDIF}
end;
