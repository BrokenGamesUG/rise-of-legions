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

  TWarheadLinkApplyScriptComponent.CreateGrouped(Entity, [], 'Links\RangeUpgrade.dws');

  {$IFDEF CLIENT}
    TPositionerAttacherComponent.Create(Entity)
      .AttachToSource
      .SetSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [1])
      .ApplyFront();

    TPositionerAttacherComponent.CreateGrouped(Entity, [2])
      .AttachToDestination
      .SetSubPosition(BIND_ZONE_HIT_ZONE);

    TLinkRayVisualizerComponent.Create(Entity)
      .Texture('\Units\Blue\ObserverDrone' + Entity.SkinFileSuffix + '\RangeLink\RangeLink.png')
      .SetOpacity(0.15)
      .SetLongitudinalSpeed(RVariedSingle.Create(1, 0))
      .SetWidth(RVariedSingle.Create(0.6, 0.0))
      .SetLength(RVariedSingle.Create(1.5, 0.0))
      .SetRaycount(1);
  {$ENDIF}
end;
