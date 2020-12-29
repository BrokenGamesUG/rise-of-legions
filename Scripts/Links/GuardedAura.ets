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

  TWarheadLinkApplyScriptComponent.CreateGrouped(Entity, [], 'Links\Guarded.dws');

  {$IFDEF CLIENT}
  {$ENDIF}
end;
