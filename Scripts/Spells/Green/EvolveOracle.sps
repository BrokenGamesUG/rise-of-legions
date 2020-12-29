{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}2);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellAlly]);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [SpellGroup], 'Units\Green\Oracle');

  TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustHave([upSapling]);
  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [SpellGroup]);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EvolveOracle')
      .IsCardDescription
      .Keyword('Sapling')
      .PassPercentage('initial_health_percentage', 60, 'health');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 5);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 0);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, SpellGroupHealthReduction, ChargeGroup : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  SpellGroupHealthReduction := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo);
  CreateData(Entity, SpellGroup, ChargeGroup);

  Entity.Blackboard.SetValue(eiWelaDamage, [SpellGroupHealthReduction], 0.6);

  {$IFDEF SERVER}
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [SpellGroup])
      .PassCardValues;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [SpellGroup])
      .Exile;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [SpellGroup])
      .Name('Evolve')
      .TriggerOnFire;
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);

    TAutoBrainWelaTargetProducedUnitComponent.CreateGrouped(Entity, [SpellGroup])
      .FireOnlyAtUnitsInOwnGroup
      .FireInGroup([SpellGroupHealthReduction]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroupHealthReduction]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [SpellGroupHealthReduction])
      .SetResourceType(reHealth)
      .AmountIsPercentage()
      .SetsResourceToValue();
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Modifiers\Evolve.dws')
    .PassIntValue(1000)
    .ApplyToProducedUnits();

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);

    TParticleEffectComponent.CreateGrouped(Entity, [SpellGroup], '\Green\evolve_oracle.pfx', 1.0)
      .ActivateOnFire()
      .ActivateAtFireTarget()
      .SetModelOffset(RVector3.Create(0, 0.7, 0));

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/green/spell/evolve/oracle/cast')
      .UsePositionOfTarget()
      .TriggerOnFire();
  {$ENDIF}
end;
