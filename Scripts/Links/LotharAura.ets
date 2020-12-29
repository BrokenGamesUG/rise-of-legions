{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  // precent damage is redirected to lothar
  Entity.Blackboard.SetValue(eiWelaModifier, [], 0.8);
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
    // Redirects damage from source to dest, make damage irredirectable
    TLinkEffectDamageRedirectionComponent.Create(Entity)
      .DestinationToSource();
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerAttacherComponent.Create(Entity)
      .AttachToSource
      .SetSubPosition(BIND_ZONE_HIT_ZONE);
    TLinkRayVisualizerComponent.Create(Entity)
      .Texture('\Units\White\Defender' + Entity.SkinFileSuffix + '\DevotionRay\DevotionRay.png')
      .SetOpacity(0.2)
      .SetWidth(RVariedSingle.Create(0.3, 0.05))
      .SetLength(RVariedSingle.Create(5, 1))
      .SetLongitudinalSpeed(RVariedSingle.Create(-8.0, 0.5))
      .SetRayCount(1);

    TPositionerAttacherComponent.CreateGrouped(Entity, [1])
      .AttachToDestination
      .SetSubPosition(BIND_ZONE_HIT_ZONE);
    TPointLightComponent.CreateGrouped(Entity, [1], $80feff98, 2.0)
      .IsPiece;
  {$ENDIF}
end;
