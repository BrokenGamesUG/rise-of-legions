{$INCLUDE 'Math.dws'};

var Game : TGame;
var InheritsFrom : string = 'Units\Neutral\Lanetower.ets';

procedure CreateData(Entity : TEntity);
begin
  // 2v2 - PvP
  {$IFNDEF MAPEDITOR}
  if Game.IsDuo and Game.IsPvP and Game.IsOneLane then
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, 2.0 * f([800.0, 1000.0, 1200.0, 1200.0, 1200.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, 2.0 * f([800.0, 1000.0, 1200.0, 1200.0, 1200.0], Entity.CardLeague));
  end
  else
  // Rest
  {$ENDIF}
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, f([800.0, 1000.0, 1200.0, 1200.0, 1200.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, f([800.0, 1000.0, 1200.0, 1200.0, 1200.0], Entity.CardLeague));
  end;

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Neutral\LanetowerLevel1Projectile');

  // Upgrade effect
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [4], 'Units\Neutral\LanetowerLevel2');

  {$IFDEF CLIENT}
    TTooltipUnitAbilityComponent.CreateGrouped(Entity, [4], 'LanetowerUpgrade');
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,4,0), 1.2);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Neutral\Lanetower\LanetowerCrystalShards.xml')
      .IgnoreScalingForAnimations
      .ApplyLegacySizeFactor
      .CreateNewAnimation(ANIMATION_STAND, 0, 100)
      .BindTextureToTeam(mtGlow, 'LanetowerCrystalShardsGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'LanetowerCrystalShardsGlow2.tga', 2)
      .BindZoneToBone(BIND_ZONE_WEAPON_MUZZLE, 'BoneC1')
      .BoneSwapYZ(BIND_ZONE_WEAPON_MUZZLE)
      .FixedOrientationDefault
      .SetModelOffset(RVector3.Create(0, 1.0, 0));

    Entity.Eventbus.WriteGrouped(eiModelSize, [4.5], [2]);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystal%d.png')
      );

    TMeshEffectSpawn.Create()
      .OverrideColor($FF505958)
      .OverrideColorIdentity(ecWhite)
      .AssignToEntity(Entity);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    // Replace with tower of next level if stage has increased
    TAutoBrainOnGameEventComponent.CreateGrouped(Entity, [4])
      .SetEvent(GAME_EVENT_TECH_LEVEL_2);
    TWelaEffectReplaceComponent.CreateGrouped(Entity, [4])
      .KeepTakenDamage()
      .KeepResource(reWelaCharge);
  {$ENDIF}

  {$IFDEF CLIENT}
    TIndicatorCooldownCircleComponent.CreateGrouped(Entity, [4])
      .ShowsGameEvent(GAME_EVENT_TECH_LEVEL_2, 4 * 60)
      .Invert
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'ProgressCircle.tga')
      .SetRadius(1.94)
      .SetThickness(0.4)
      .Offset(0, 0, 0.05)
      .SetLinearBlend
      .Opacity(0.7);
  {$ENDIF}
end;

