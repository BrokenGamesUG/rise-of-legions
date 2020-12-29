{$INCLUDE 'Math.dws'};

var Game : TGame;
var InheritsFrom : string = 'Units\Neutral\Nexus.ets';

procedure CreateData(Entity : TEntity);
begin
  // 2v2 - PvP
  {$IFNDEF MAPEDITOR}
  if Game.IsDuo and Game.IsPvP then
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, 2.0 * f([2750.0, 3600.0, 4000.0, 4000.0, 4000.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, 2.0 * f([2750.0, 3600.0, 4000.0, 4000.0, 4000.0], Entity.CardLeague));
  end
  // Rest
  else
  {$ENDIF}
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, f([2750.0, 3600.0, 4000.0, 4000.0, 4000.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, f([2750.0, 3600.0, 4000.0, 4000.0, 4000.0], Entity.CardLeague));
  end;

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [1], 'Projectiles\Neutral\NexusLevel2Projectile');

  if Entity.CardLeague > 2 then
    Entity.Blackboard.SetValue(eiWelaUnitPattern, [4], 'Units\Neutral\NexusLevel3');

  {$IFDEF CLIENT}
    if Entity.CardLeague > 2 then
      TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'NexusUpgrade');
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  {$IFDEF CLIENT}
    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Neutral\Nexus\Nexus.xml')
      .CreateNewAnimation(ANIMATION_SPAWN, 0, 20)
      .CreateNewAnimation(ANIMATION_STAND, 20, 20)
      .BindZoneToBone(BIND_ZONE_HIT_ZONE, 'crystal_low')
      .BoneOffset(BIND_ZONE_HIT_ZONE, 0, 2.5, 0)
      .BindZoneToBone(BIND_ZONE_HIT_ZONE_AIR, 'crystal_high')
      .BoneOffset(BIND_ZONE_HIT_ZONE_AIR, 0, 4, 0)
      .BoneOffset(BIND_ZONE_TOP, 0, 4.5, 0);

    TMeshComponent.CreateGrouped(Entity, [6], 'Units\Neutral\Nexus\NexusBaseUpgrade.xml')
      .BindTextureToTeam(mtGlow, 'NexusGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'NexusGlow2.tga', 2);

    TMeshComponent.CreateGrouped(Entity, [3], 'Units\Neutral\Nexus\NexusRunes.xml')
      .CreateNewAnimation(ANIMATION_STAND, 0, 601)
      .BindTextureToTeam(mtDiffuse, 'NexusDiffuse.tga', 1)
      .BindTextureToTeam(mtDiffuse, 'NexusDiffuse2.tga', 2)
      .BindTextureToTeam(mtGlow, 'NexusGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'NexusGlow2.tga', 2);

    TMeshEffectComponent.CreateGrouped(Entity, [3, 6])
      .SetEffect(
        TMeshEffectSpawn.Create()
          .OverrideColor($FF505958)
          .OverrideColorIdentity(ecWhite)
      );
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    if Entity.CardLeague > 2 then
    begin
      TAutoBrainOnGameEventComponent.CreateGrouped(Entity, [4])
        .SetEvent(GAME_EVENT_TECH_LEVEL_3);
      TWelaEffectReplaceComponent.CreateGrouped(Entity, [4])
        .KeepTakenDamage()
        .KeepResource(reWelaCharge);
    end;
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;

