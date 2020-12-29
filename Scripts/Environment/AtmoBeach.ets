procedure CreateMeta(Entity : TEntity);
begin
  // shared
  {$IFDEF SERVER}
    assert(False, 'Environmentobjects shouldn''t created on server side!');
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF CLIENT}
    TSoundComponent.Create(Entity, 'event:/env/map/atmo_beach')
      .CheckOption(coSoundPlayAtmo)
      .IsLoop
      .TriggerOnCreate
      .StopOnFree;
  {$ENDIF}
end;
