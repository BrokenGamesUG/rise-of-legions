{$INCLUDE 'Math.dws'};

var
  InheritsFrom : string = 'Units\Neutral\LaneNode.ets';

procedure CreateData(Entity : TEntity);
begin
  // block capture of team blue
  Entity.Blackboard.SetValue(eiCooldown, [10+1], 40000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    // remove block after time
    TWelaEffectRemoveAfterUseComponent.CreateGrouped(Entity, [10+1]);
    TBrainWelaSelftargetComponent.CreateGrouped(Entity, [10+1])
      .ThinksPassively();
  {$ENDIF}

  TWelaReadyCooldownComponent.CreateGrouped(Entity, [10+1], False);

  {$IFDEF CLIENT}
    TIndicatorCooldownCircleComponent.CreateGrouped(Entity, [10+1])
      .ShowAsTeam(2)
      .Invert
      .SetTexture(PATH_GRAPHICS_EFFECTS_TEXTURES + 'ProgressCircle.tga')
      .SetRadius(1.34)
      .SetThickness(0.3)
      .SetLinearBlend
      .Opacity(0.7);
  {$ENDIF}
end;

