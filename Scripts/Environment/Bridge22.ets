{$INCLUDE 'Math.dws'};

var
  GlobalEventbus : TEventbus;

procedure CreateMeta(Entity : TEntity);
begin
  // shared
  
{$IFDEF SERVER}
  assert(False, 'Environmentobjects shouldn''t created on server side!'); 
{$ENDIF}

{$IFDEF CLIENT}
  TMeshComponent.CreateGrouped(Entity, [0], 'Environment\Bridge22\Bridge22.xml');
   
  Entity.Eventbus.WriteGrouped(eiModelSize, [1.0], [0]);
{$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
end;
