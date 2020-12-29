{$INCLUDE 'SpellTemplate.dws'};

procedure CreateData(Entity : TEntity; SpellGroup, ChargeGroup : integer);
begin
  PrepareSpellData(Entity, SpellGroup, ChargeGroup, False, {@SBL_Tier}1);
  Entity.Blackboard.SetValue(eiCooldown, [ChargeGroup], GetCardBaseChargeCooldown({@SBL_Tier}1, Entity.CardLeague(SpellGroup), Entity.CardLevel(SpellGroup), False, True, False) * 3);

  Entity.Blackboard.SetValue(eiAbilityTargetCount, [SpellGroup], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [SpellGroup], ctCoordinate);

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [SpellGroup], 'EchoesOfTheFuture')
      .IsCardDescription
      .PassInteger('duration', 30);

    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaAttack, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaDefense, 0);
    Entity.Blackboard.SetIndexedValue(eiCardStats, [SpellGroup], reMetaUtility, 10);
  {$ENDIF}
end;

procedure AddSpell(Entity : TEntity; CardInfo : TCardInfo; Slot : integer);
var SpellGroup, ChargeGroup : integer;
begin
  SpellGroup := Entity.ReserveFreeGroup();
  ChargeGroup := Entity.ReserveFreeGroup();
  PrepareSpell(Entity, SpellGroup, ChargeGroup, Slot, CardInfo);
  CreateData(Entity, SpellGroup, ChargeGroup);

  TWelaReadyUnitPropertyComponent.CreateGrouped(Entity, [SpellGroup])
    .MustNotHave([upHasEchoesOfTheFuture]);

  {$IFDEF SERVER}
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [SpellGroup])
      .OverrideTargetToOwner;
    TWelaEffectInstantComponent.CreateGrouped(Entity, [SpellGroup]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [SpellGroup], 'Spells\Golems\EchoesOfTheFuture.dws');

  {$IFDEF CLIENT}
    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [SpellGroup])
      .SetTexture('SpelltargetGround.png', 0)
      .SetSize(1.5, 0);

    TSoundComponent.CreateGrouped(Entity, [SpellGroup], 'event:/card/colorless/spell/echoesofthefuture/cast')
      .TriggerOnFireWarhead()
      .UsePositionOfTarget();
  {$ENDIF}
end;
