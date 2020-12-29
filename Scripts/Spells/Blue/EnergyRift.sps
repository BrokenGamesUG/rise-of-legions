{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellAlly]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EnergyRift')
      .IsCardDescription
      .PassInteger('damage_amount', 24, 'damage')
      .PassInteger('duration', 30);

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

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHave([upBuilding])
    .MustNotHave([upBanished, upHasEnergyRift]);
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [SpellGroup]);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);

    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Spells\Blue\EnergyRift.dws');

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetShootingRange.png', 0)
      .SetSize(14.0, 0);

    TParticleEffectComponent.CreateGrouped(Entity, [SpellGroup], '\Blue\energy_rift_cast.pfx', 1.0)
      .ActivateOnFire()
      .ActivateAtFireTarget();

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/blue/spell/energy_rift/cast')
      .TriggerOnFire
      .UsePositionOfTarget;
  {$ENDIF}
end;
