#define GOLD_GROUP [1]
#define TIER_GROUP [2]
#define GOLD_UPGRADE_GROUP [3]
#define PING_GENERIC_GROUP 4
#define PING_ATTACK_GROUP 5
#define PING_DEFENSE_GROUP 6

{$INCLUDE 'Math.dws'};

var Game : TGame;

procedure CreateEntity(Entity : TEntity);
var i : integer;
begin
  // starting resources are
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reGold, Game.StartingGold);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reGold, Game.GoldCap);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reWood, Game.StartingWood);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reIncomeUpgrade, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reIncomeUpgrade, Game.IncomeUpgradeCap); // at max 10 income upgrades
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reTier, Game.StartingTier);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reTier, 3);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reGadgetCount, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reGadgetCount, Game.GadgetCountCap);
  Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reCharmCount, 0);
  Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reCharmCount, Game.CharmCountCap);

  TCommanderIncomeOverflowComponent.CreateGrouped(Entity, []);

  // gold gain, base income of gold every second
  Entity.Blackboard.SetIndexedValue(eiResourceCost, GOLD_GROUP, reGold, Game.StartingIncomeRate); // default gold income
  Entity.Blackboard.SetValue(eiWelaDamage, GOLD_GROUP, Game.IncomeRatePerIncomeUpgrade); // income per IncomeUpgrade
  TCommanderIncomeDefaultComponent.CreateGrouped(Entity, GOLD_GROUP);

  // Income upgrade
  Entity.Blackboard.SetIndexedValue(eiResourceCost, GOLD_UPGRADE_GROUP, reSpentWood, Game.StartingIncomeUpgradeCost); // initial cost
  Entity.Blackboard.SetValue(eiWelaDamage, GOLD_UPGRADE_GROUP, 1.0);
  Entity.Blackboard.SetValue(eiWelaModifier, GOLD_UPGRADE_GROUP, Game.IncomeUpgradeCostPerIncomeUpgrade); // added cost after each upgrade

  // automatic Tier upgrade
  Entity.Blackboard.SetValue(eiWelaDamage, TIER_GROUP, 1.0);

  // pings
  Entity.Blackboard.SetValue(eiAbilityTargetCount, [PING_GENERIC_GROUP, PING_ATTACK_GROUP, PING_DEFENSE_GROUP], 1);
  Entity.Blackboard.SetValue(eiAbilityTargetType, [PING_GENERIC_GROUP, PING_ATTACK_GROUP, PING_DEFENSE_GROUP], ctCoordinate);

  {$IFDEF SERVER}
    // tier upgrade
    TAutoBrainOnGameEventComponent.CreateGrouped(Entity, TIER_GROUP)
      .SetEvent(GAME_EVENT_TECH_LEVEL_2)
      .SetEvent(GAME_EVENT_TECH_LEVEL_3);

    TWelaEffectInstantComponent.CreateGrouped(Entity, TIER_GROUP);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, TIER_GROUP)
      .SetResourceType(reTier);
    // increase gold cap with each tier upgrade by 300
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, TIER_GROUP)
      .SetResourceType(reGold)
      .SetFactor(Game.GoldCapPerTier)
      .ChangesMax
      .DontFillCap;

    // automatic income upgrade
    TThinkImpulseImmediateComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP);
    TWelaReadyCostComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP)
      .SetPayingGroup([]);
    // deny upgrades if we reached the cap
    TWelaReadyResourceCompareComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP)
      .ComparedResource(reIncomeUpgrade)
      .CheckNotFull;
    TWelaEffectPayCostComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP)
      .SetPayingGroup([]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP)
      .SetResourceType(reIncomeUpgrade);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP)
      .Name('IncomeUpgrade')
      .TriggerOnFire;

    TBrainWelaCommanderComponent.CreateGrouped(Entity, [PING_GENERIC_GROUP]);
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [PING_ATTACK_GROUP]);
    TBrainWelaCommanderComponent.CreateGrouped(Entity, [PING_DEFENSE_GROUP]);
  {$ENDIF}

  TModifierCostComponent.CreateGrouped(Entity, GOLD_UPGRADE_GROUP)
    .ScaleWithResource(reIncomeUpgrade);

  {$IFDEF CLIENT}
    TCommanderComponent.Create(Entity); // for enumeration and other commander related actions

    TCommanderAbilityButtonComponent.CreateGrouped(Entity, [PING_GENERIC_GROUP])
      .UID('ping_generic');

    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [PING_GENERIC_GROUP])
      .NoValidChecks
      .SetTexture('ping_generic.png', 0)
      .SetSize(1.5, 0)
      .Additive(0);

    TClientFireTeamFilterComponent.CreateGrouped(Entity, [PING_GENERIC_GROUP]);

    TMinimapPingComponent.CreateGrouped(Entity, [PING_GENERIC_GROUP])
      .Texture('ping_generic.png')
      .Size(2.0);

    TParticleEffectComponent.CreateGrouped(Entity, [PING_GENERIC_GROUP], '\Shared\ping_generic.pfx', 1.0)
      .ActivateOnFire
      .ActivateAtFireTarget
      .FixedOrientationDefault
      .FixedHeightGround;

    TSoundComponent.CreateGrouped(Entity, [PING_GENERIC_GROUP], 'event:/ui/core/ping_generic')
      .TriggerOnFire
      .UsePositionOfTarget;

    TCommanderAbilityButtonComponent.CreateGrouped(Entity, [PING_ATTACK_GROUP])
      .UID('ping_attack');

    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [PING_ATTACK_GROUP])
      .NoValidChecks
      .SetTexture('ping_attack.png', 0)
      .SetSize(1.5, 0)
      .Additive(0);

    TClientFireTeamFilterComponent.CreateGrouped(Entity, [PING_ATTACK_GROUP]);

    TMinimapPingComponent.CreateGrouped(Entity, [PING_ATTACK_GROUP])
      .Texture('ping_attack.png')
      .Size(2.0);

    TParticleEffectComponent.CreateGrouped(Entity, [PING_ATTACK_GROUP], '\Shared\ping_attack.pfx', 1.0)
      .ActivateOnFire
      .ActivateAtFireTarget
      .FixedOrientationDefault
      .FixedHeightGround;

    TSoundComponent.CreateGrouped(Entity, [PING_ATTACK_GROUP], 'event:/ui/core/ping_attack')
      .TriggerOnFire
      .UsePositionOfTarget;

    TCommanderAbilityButtonComponent.CreateGrouped(Entity, [PING_DEFENSE_GROUP])
      .UID('ping_defense');

    TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Entity, [PING_DEFENSE_GROUP])
      .NoValidChecks
      .SetTexture('ping_defense.png', 0)
      .SetSize(1.5, 0)
      .Additive(0);

    TClientFireTeamFilterComponent.CreateGrouped(Entity, [PING_DEFENSE_GROUP]);

    TMinimapPingComponent.CreateGrouped(Entity, [PING_DEFENSE_GROUP])
      .Texture('ping_defense.png')
      .Size(2.0);

    TParticleEffectComponent.CreateGrouped(Entity, [PING_DEFENSE_GROUP], '\Shared\ping_defense.pfx', 1.0)
      .ActivateOnFire
      .ActivateAtFireTarget
      .FixedOrientationDefault
      .FixedHeightGround;

    TSoundComponent.CreateGrouped(Entity, [PING_DEFENSE_GROUP], 'event:/ui/core/ping_defend')
      .TriggerOnFire
      .UsePositionOfTarget;
  {$ENDIF}
end;
