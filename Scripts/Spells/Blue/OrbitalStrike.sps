{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}3);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellEnemy]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'OrbitalStrike')
      .IsCardDescription
      .PassInteger('primary_damage_amount', 13, 'damage')
      .PassSingle('primary_damage_cooldown', 0, 5)
      .PassInteger('splash_damage_amount', 11, 'damage')
      .PassSingle('splash_damage_cooldown', 0, 2)
      .PassInteger('duration', 15);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 10);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 0);
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

  TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [SpellGroup]);
  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHaveAny([upUnit, upBuilding])
    .MustNotHave([upBase, upBanished, upSpellImmune]);
  TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [SpellGroup], eiDamageable);

  {$IFDEF SERVER}
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
    TWarheadSpottyHealComponent.CreateGrouped(Entity, [SpellGroup]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [SpellGroup])
      .Name('FlatHeal')
      .TriggerOnFire;
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Spells\Blue\OrbitalStrike.dws');

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetGeneric.png', 0)
      .SetSize(6.0, 0);
  {$ENDIF}
end;
