{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
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
  {$ENDIF}

  TWarheadLinkApplyScriptComponent.CreateGrouped(Entity, [], 'Links\CrystalSpeed.dws');

  {$IFDEF CLIENT}
    TPositionerAttacherComponent.Create(Entity)
      .AttachToSource
      .SetSubPosition(BIND_ZONE_WEAPON_MUZZLE);
    TLinkRayVisualizerComponent.Create(Entity)
      .Texture('\Units\Colorless\SmallCasterGolem\CrystalPowerLink\CrystalPowerLink.png')
      .SetOpacity(0.2)
      .SetWidth(RVariedSingle.Create(0.3, 0.05))
      .SetLength(RVariedSingle.Create(5, 1))
      .SetLongitudinalSpeed(RVariedSingle.Create(8.0, 0.5))
      .SetRayCount(1);

    TPositionerAttacherComponent.CreateGrouped(Entity, [1])
      .AttachToDestination
      .SetSubPosition(BIND_ZONE_WEAPON);
  {$ENDIF}
end;
