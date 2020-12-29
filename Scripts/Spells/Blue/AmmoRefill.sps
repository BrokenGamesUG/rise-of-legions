{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiUnitProperties, [SpellGroup], [upSpellSingle, upSpellAlly]);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [SpellGroup], reGold, GetCardBaseCost({@SBL_Tier}1, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), False, True, False) - 40);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctEntity);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'AmmoRefill')
      .IsCardDescription
      .PassPercentage('energy_amount_stage_1_percentage', 100, 'energy')
      .PassPercentage('energy_amount_stage_2_percentage', 50, 'energy')
      .PassPercentage('energy_amount_stage_3_percentage', 25, 'energy')
      .PassPercentage('energy_amount_legendary_percentage', 25, 'energy');

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 8);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, ChargeGroup, Tier1, Tier2, Tier3, Base : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo);
  CreateData(Entity, SpellGroup, ChargeGroup);

  Tier1 := Entity.ReserveFreeGroup();
  Tier2 := Entity.ReserveFreeGroup();
  Tier3 := Entity.ReserveFreeGroup();
  Base := Entity.ReserveFreeGroup();

  TWelaTargetConstraintAlliesComponent.CreateGrouped(Entity, [SpellGroup]);
  TWelaTargetConstraintResourceComponent.CreateGrouped(Entity, [SpellGroup])
    .CheckResource(reMana)
    .CheckNotFull;

  Entity.Blackboard.SetValue(eiWelaDamage, [Tier1], 1.0);
  Entity.Blackboard.SetValue(eiWelaDamage, [Tier2], 0.5);
  Entity.Blackboard.SetValue(eiWelaDamage, [Tier3], 0.25);
  Entity.Blackboard.SetValue(eiWelaDamage, [Base], 0.2);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup]);

    TWelaEffectFireComponent.CreateGrouped(Entity, [SpellGroup])
      .TargetGroup([Tier1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [Tier1])
      .MustHave([upTier1])
      .MustNotHave([upBase]);

    TWelaEffectFireComponent.CreateGrouped(Entity, [SpellGroup])
      .TargetGroup([Tier2]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [Tier2])
      .MustHave([upTier2])
      .MustNotHave([upBase]);

    TWelaEffectFireComponent.CreateGrouped(Entity, [SpellGroup])
      .TargetGroup([Tier3]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [Tier3])
      .MustHave([upTier3])
      .MustNotHave([upBase]);

    TWelaEffectFireComponent.CreateGrouped(Entity, [SpellGroup])
      .TargetGroup([Base]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [Base])
      .MustHave([upBase]);

    TWelaEffectInstantComponent.CreateGrouped(Entity, [Tier1]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [Tier1])
      .SetResourceType(reMana)
      .AmountIsPercentage;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [Tier2]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [Tier2])
      .SetResourceType(reMana)
      .AmountIsPercentage;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [Tier3]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [Tier3])
      .SetResourceType(reMana)
      .AmountIsPercentage;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [Base]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [Base])
      .SetResourceType(reMana)
      .AmountIsPercentage;
  {$ENDIF}

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetEntity.png', 0)
      .SetSize(0.5, 0);

    TParticleEffectComponent.CreateGrouped(Entity, [SpellGroup], '\Blue\ammo_refill_cast.pfx', 1.4)
      .ActivateOnFire()
      .ClonesToTarget()
      .FixedOrientationDefault;

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/blue/spell/ammo_refill/cast')
      .UsePositionOfTarget
      .TriggerOnFire;
  {$ENDIF}
end;
