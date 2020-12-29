{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellDoubleArea, upSpellAlly]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 2);
  Entity.Blackboard.SetValue(eiAbilityTargetRange, [SpellGroup], 20.0);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctCoordinate);
  // effect
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [SpellGroup], 'Spells\Blue\Relocate');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'Relocate')
      .IsCardDescription
      .PassInteger('target_count', 6)
      .PassInteger('cooldown', 20)
      .PassPercentage('heal_stage_1', 30, 'health')
      .PassPercentage('energy_stage_1', 30, 'energy')
      .PassPercentage('heal_stage_2', 25, 'health')
      .PassPercentage('energy_stage_2', 20, 'energy')
      .PassPercentage('heal_stage_3', 15, 'health')
      .PassPercentage('energy_stage_3', 20, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 1);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 1);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 8);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, ChargeGroup : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo);
  CreateData(Entity, SpellGroup, ChargeGroup);

  TWelaTargetConstraintMaxTargetDistanceComponent.CreateGrouped(Entity, [SpellGroup]);
  TWelaTargetConstraintZoneComponent.CreateGrouped(Entity, [SpellGroup], ZONE_WALK, False)
    .SetPadding(5.0);

  {$IFDEF SERVER}
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [SpellGroup])
      .PassCardValues
      .PassTargets;
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowPatternComponent.CreateGrouped(Entity, [SpellGroup])
      .ShowForIndex(0);

    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetGround.png', 0)
      .SetSize(5.0, 0)
      .SetTexture('SpelltargetGround.png', 1)
      .SetSize(5.0, 1);

    TSpelltargetVisualizerLineBetweenTargetsComponent.CreateGrouped(Entity, [SpellGroup])
      .Texture('SpelltargetLine.png')
      .Width(0.8);
  {$ENDIF}
end;
