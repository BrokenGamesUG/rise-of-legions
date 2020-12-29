{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellAlly]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EnchantmentGrowth')
      .Keyword('Enchanted')
      .PassInteger('duration', 10)
      .PassPercentage('heal_amount_percentage', 2, 'health')
      .PassInteger('health_amount', 160, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 5);
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

  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [SpellGroup]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHave([upUnit])
    .MustNotHave([upBase, upBlessedGrowth]);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Modifiers\BlessingGrowth.dws');

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);

    TParticleEffectComponent.CreateGrouped(Entity, [SpellGroup], '\Green\giant_growth_cast.pfx', 1.4)
      .ActivateOnFire()
      .ClonesToTarget()
      .FixedOrientationDefault;

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/green/spell/giant_gowth/cast')
      .UsePositionOfTarget
      .TriggerOnFire();
  {$ENDIF}
end;
