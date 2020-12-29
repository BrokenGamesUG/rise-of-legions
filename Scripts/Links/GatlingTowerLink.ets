{$INCLUDE 'Math.dws'};

var
  InheritsFrom : string = 'Links\GatlingLinkBase.ets';

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

  {$IFDEF CLIENT}
    TSoundComponent.Create(Entity, 'event:/card/blue/unit/gatling/attack_fire')
      .TriggerOnCreate()
      .StopOnFree
      .IsPiece;

    TPositionerAttacherComponent.Create(Entity)
      .AttachToSource
      .SetSubPositionGroup(BIND_ZONE_WEAPON_MUZZLE, [1])
      .ApplyFront();
  {$ENDIF}
end;
