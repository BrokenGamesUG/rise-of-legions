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

  TWarheadLinkApplyScriptComponent.CreateGrouped(Entity, [], 'Links\ProjectileReflector.dws');

  {$IFDEF CLIENT}
    TPositionerAttacherComponent.Create(Entity)
      .AttachToSource
      .SetSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [1])
      .ApplyFront();

    TPositionerAttacherComponent.CreateGrouped(Entity, [2])
      .AttachToDestination
      .SetSubPosition(BIND_ZONE_HIT_ZONE);

    TLinkRayVisualizerComponent.Create(Entity)
      .Texture('\Units\Blue\Shielddrone\ReflectorLink\ReflectorLink.png')
      .SetOpacity(0.1)
      .SetStartWidth(0.1)
      .SetLongitudinalSpeed(RVariedSingle.Create(3, 1.0))
      .SetRotationSpeed(RVariedSingle.Create(3, 0.5))
      .SetWidth(RVariedSingle.Create(0.3, 0.0))
      .SetLength(RVariedSingle.Create(1.5, 0.0))
      .SetEndposJitter(0.5)
      .SetRaycount(5);
  {$ENDIF}
end;
