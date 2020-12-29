{$INCLUDE 'Math.dws'};

var Game : TGame;
var InheritsFrom : string = 'Units\Neutral\Nexus.ets';

procedure CreateData(Entity : TEntity);
begin
  // 2v2 - PvP
  {$IFNDEF MAPEDITOR}
  if Game.IsDuo and Game.IsPvP then
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, 2.0 * f([2500.0, 3250.0, 3750.0, 3750.0, 3750.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, 2.0 * f([2500.0, 3250.0, 3750.0, 3750.0, 3750.0], Entity.CardLeague));
  end
  // Rest
  else
  {$ENDIF}
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, f([2500.0, 3250.0, 3750.0, 3750.0, 3750.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, f([2500.0, 3250.0, 3750.0, 3750.0, 3750.0], Entity.CardLeague));
  end;

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Projectiles\Neutral\NexusLevel1Projectile');

  // Upgrade effect
  Entity.Blackboard.SetValue(eiCooldown, [4], 6 * 60 * 1000);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [4], 'Units\Neutral\NexusLevel2');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'NexusUpgrade');
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  {$IFDEF CLIENT}
    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Neutral\Nexus\Nexus.xml')
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .BindZoneToBone(BIND_ZONE_HIT_ZONE, 'crystal_low')
      .BoneOffset(BIND_ZONE_HIT_ZONE, 0, 2.5, 0)
      .BindZoneToBone(BIND_ZONE_HIT_ZONE_AIR, 'crystal_high')
      .BoneOffset(BIND_ZONE_HIT_ZONE_AIR, 0, 4, 0)
      .BoneOffset(BIND_ZONE_TOP, 0, 4.5, 0);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TAutoBrainOnGameEventComponent.CreateGrouped(Entity, [4])
      .SetEvent(GAME_EVENT_TECH_LEVEL_2);
    TWelaEffectReplaceComponent.CreateGrouped(Entity, [4])
      .KeepTakenDamage()
      .KeepResource(reWelaCharge);
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;

