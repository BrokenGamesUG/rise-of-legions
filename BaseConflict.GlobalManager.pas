unit BaseConflict.GlobalManager;

interface

uses
  BaseConflict.Entity,
  Generics.Collections;

type

  TCommanderManager = class
    protected
      FCommander : TList<TEntity>;
      FActiveCommander : TEntity;
      FActiveIndex : integer;
    public
      property ActiveCommander : TEntity read FActiveCommander;
      property ActiveIndex : integer read FActiveIndex;
      function HasActiveCommander : boolean;
      function CommanderCount : integer;
      procedure Clear;
      procedure AddCommander(Commander : TEntity);
      procedure ChooseCommander(Index : integer);
      constructor Create;
      destructor Destroy; override;
  end;

var

  CommanderManager : TCommanderManager;

implementation

{ TCommanderManager }

procedure TCommanderManager.AddCommander(Commander : TEntity);
begin
  FCommander.Add(Commander);
  if not assigned(FActiveCommander) then
  begin
    FActiveCommander := Commander;
    FActiveIndex := 0;
  end;
end;

procedure TCommanderManager.ChooseCommander(Index : integer);
begin
  if index = -1 then
  begin
    FActiveCommander := nil;
    FActiveIndex := -1;
  end;
  if (index < FCommander.Count) and (index >= 0) then
  begin
    FActiveCommander := FCommander[index];
    FActiveIndex := index;
  end;
end;

procedure TCommanderManager.Clear;
begin
  FCommander.Clear;
  ChooseCommander(-1)
end;

function TCommanderManager.CommanderCount : integer;
begin
  Result := FCommander.Count;
end;

constructor TCommanderManager.Create;
begin
  FActiveIndex := -1;
  FCommander := TList<TEntity>.Create;
end;

destructor TCommanderManager.Destroy;
begin
  FCommander.Free;
  inherited;
end;

function TCommanderManager.HasActiveCommander : boolean;
begin
  Result := ActiveCommander <> nil;
end;

initialization

CommanderManager := TCommanderManager.Create;

finalization

CommanderManager.Free;

end.
