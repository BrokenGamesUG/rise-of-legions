{$INCLUDE 'Math.dws'};

var Game : TGame;
var InheritsFrom : string = 'Units\Neutral\Lanetower.ets';

procedure CreateData(Entity : TEntity);
begin
  // 2v2 - PvP
  {$IFNDEF MAPEDITOR}
  if Game.IsDuo and Game.IsPvP and Game.IsOneLane then
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, 2.0 * f([1200.0, 1400.0, 1600.0, 1600.0, 1600.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, 2.0 * f([1200.0, 1400.0, 1600.0, 1600.0, 1600.0], Entity.CardLeague));
  end
  else
  // Rest
  {$ENDIF}
  begin
    Entity.Blackboard.SetIndexedValue(eiResourceCap, [], reHealth, f([1200.0, 1400.0, 1600.0, 1600.0, 1600.0], Entity.CardLeague));
    Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], reHealth, f([1200.0, 1400.0, 1600.0, 1600.0, 1600.0], Entity.CardLeague));
  end;

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0, 1], 'Projectiles\Neutral\LanetowerLevel3Projectile');

  {$IFDEF CLIENT}
    Entity.Blackboard.SetIndexedValue(eiUnitData, [], udHealthbarOffset, 1.9);
  {$ENDIF}
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TClickCollisionComponent.Create(Entity).SetCapsule(RVector3.Create(0,0,0), RVector3.Create(0,4,0), 1.4);

    TMeshComponent.CreateGrouped(Entity, [2], 'Units\Neutral\Lanetower\LanetowerCrystal.xml')
      .CreateNewAnimation(ANIMATION_STAND, 0, 201)
      .BindTextureToTeam(mtDiffuse, 'LanetowerDiffuse.tga', 1)
      .BindTextureToTeam(mtDiffuse, 'LanetowerDiffuse2.tga', 2)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow2.tga', 2);

    TMeshEffectComponent.CreateGrouped(Entity, [2])
      .SetEffect(
        TMeshEffectMatCap.Create()
          .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'MatcapCrystal%d.png')
      );

    TMeshComponent.CreateGrouped(Entity, [0], 'Units\Neutral\Lanetower\LanetowerCrystalRunes.xml')
      .CreateNewAnimation(ANIMATION_STAND, 0, 301)
      .BindTextureToTeam(mtDiffuse, 'LanetowerDiffuse.tga', 1)
      .BindTextureToTeam(mtDiffuse, 'LanetowerDiffuse2.tga', 2)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow2.tga', 2);

    TMeshComponent.CreateGrouped(Entity, [3], 'Units\Neutral\Lanetower\LanetowerBaseUpgrade.xml')
      .CreateNewAnimation(ANIMATION_STAND, 0, 0)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow.tga', 1)
      .BindTextureToTeam(mtGlow, 'LanetowerGlow2.tga', 2);

    TMeshEffectComponent.CreateGrouped(Entity, [0, 1, 2, 3, 4])
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
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;

