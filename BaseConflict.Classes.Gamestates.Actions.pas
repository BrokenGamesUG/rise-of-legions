unit BaseConflict.Classes.Gamestates.Actions;

interface

uses
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  Engine.GUI,
  // Game
  BaseConflict.Globals.Client,
  BaseConflict.Classes.Client,
  BaseConflict.Classes.Gamestates;

type

  TActionClient = class(TAction)
    private
      FInverted, FDoInExecute, FDoInExecuteSynchronized, FDoInFinished : boolean;
    public
      function Invert : TActionClient;
      function InvertIf(const Condition : boolean) : TActionClient;
      function DoInExecute : TActionClient;
      function DoInExecuteSynchronized : TActionClient;
      function DoInFinished : TActionClient;
      procedure Deploy;
  end;

  ProcInlineActionWithValue<T> = reference to procedure(const Value : T);

  TActionInlineWithValue<T> = class(TActionInline)
    strict private
      FEmulateWithValue, FRollbackWithValue : ProcInlineActionWithValue<T>;
    public
      Value : T;
      constructor Create(const Value : T);
      procedure Deploy;
      function OnEmulate(const Action : ProcInlineActionWithValue<T>) : TActionInlineWithValue<T>; overload;
      function OnRollback(const Action : ProcInlineActionWithValue<T>) : TActionInlineWithValue<T>; overload;
      procedure Emulate; override;
      procedure Rollback; override;
  end;

  TActionGeneric<T> = class(TActionClient)
    private
      FValueT : T;
    public
      constructor Create(const ValueT : T);
  end;

  TActionGeneric<T, U> = class(TActionGeneric<T>)
    private
      FValueU : U;
    public
      constructor Create(const ValueT : T; const ValueU : U);
  end;

  /// <summary> Activates the given component at the given state. </summary>
  TActionActivateStateComponent = class(TActionGeneric<TGameState, CGameStateComponent>)
    public
      procedure Emulate; override;
      procedure Rollback; override;
  end;

  /// <summary> Shows the specified gui component. </summary>
  TActionShowComponent = class(TActionGeneric<string>)
    private
      FFormerState : boolean;
    public
      procedure Emulate; override;
      procedure Rollback; override;
  end;

  /// <summary> Adds the specified gui class. </summary>
  TActionAddClassToComponent = class(TActionGeneric<string, string>)
    private
      FHasAdded : boolean;
    public
      procedure Emulate; override;
      procedure Rollback; override;
  end;

  ProcSetter<T> = reference to procedure(const Value : T);

  TActionSetVariable<T> = class(TActionClient)
    public type
      PT = ^T;
    private
      FNewValue, FFormerValue : T;
      FSetter : ProcSetter<T>;
    public
      constructor Create(const NewValue : T; const FormerValue : T; const ValueSetter : ProcSetter<T>);
      procedure Emulate; override;
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
      procedure Rollback; override;
      procedure Finished; override;
  end;

  /// <summary> Frees the old variable after the action completed sucessfully. </summary>
  TActionSetInstanceVariable<T : class> = class(TActionSetVariable<T>)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TActionCompound = class
    private
      FInverted : boolean;
      FActions : TArray<TActionClient>;
    public
      constructor Create(const Actions : array of TActionClient);
      function Invert : TActionCompound;
      function InvertIf(const Condition : boolean) : TActionCompound;
      /// <summary> Should be called at the end of chain. Frees the compound. </summary>
      procedure Deploy;
  end;

implementation

uses
  BaseConflict.Api;

{ TActionActivateStateComponent }

procedure TActionActivateStateComponent.Emulate;
begin
  FValueT.SetComponentActive(FValueU, FInverted);
end;

procedure TActionActivateStateComponent.Rollback;
begin
  FValueT.SetComponentActive(FValueU, not FInverted);
end;

{ TActionGeneric<T> }

constructor TActionGeneric<T>.Create(const ValueT : T);
begin
  inherited Create;
  FValueT := ValueT;
end;

{ TActionGeneric<T, U> }

constructor TActionGeneric<T, U>.Create(const ValueT : T; const ValueU : U);
begin
  inherited Create(ValueT);
  FValueU := ValueU;
end;

{ TActionInlineWithValue<T> }

constructor TActionInlineWithValue<T>.Create(const Value : T);
begin
  inherited Create;
  self.Value := Value;
end;

procedure TActionInlineWithValue<T>.Deploy;
begin
  MainActionQueue.DoAction(self);
end;

procedure TActionInlineWithValue<T>.Emulate;
begin
  inherited;
  if assigned(FEmulateWithValue) then FEmulateWithValue(Value);
end;

function TActionInlineWithValue<T>.OnEmulate(const Action : ProcInlineActionWithValue<T>) : TActionInlineWithValue<T>;
begin
  Result := self;
  FEmulateWithValue := Action;
end;

function TActionInlineWithValue<T>.OnRollback(const Action : ProcInlineActionWithValue<T>) : TActionInlineWithValue<T>;
begin
  Result := self;
  FRollbackWithValue := Action;
end;

procedure TActionInlineWithValue<T>.Rollback;
begin
  inherited;
  if assigned(FRollbackWithValue) then FRollbackWithValue(Value);
end;

{ TActionShowComponent }

procedure TActionShowComponent.Emulate;
var
  Element : TGUIComponent;
begin
  Element := GUI.FindUnique(FValueT);
  FFormerState := Element.Visible;
  Element.Visible := not FInverted;
end;

procedure TActionShowComponent.Rollback;
begin
  GUI.FindUnique(FValueT).Visible := FFormerState;
end;

{ TActionAddClassToComponent }

procedure TActionAddClassToComponent.Emulate;
begin
  if FInverted then FHasAdded := GUI.FindUnique(FValueT).RemoveClass(FValueU)
  else FHasAdded := GUI.FindUnique(FValueT).AddClass(FValueU);
end;

procedure TActionAddClassToComponent.Rollback;
begin
  if FHasAdded then
  begin
    if FInverted then GUI.FindUnique(FValueT).AddClass(FValueU)
    else GUI.FindUnique(FValueT).RemoveClass(FValueU);
  end;
end;

{ TActionCompound }

constructor TActionCompound.Create(const Actions : array of TActionClient);
begin
  FActions := HArray.ConvertDynamicToTArray<TActionClient>(Actions);
end;

procedure TActionCompound.Deploy;
var
  i : Integer;
begin
  for i := 0 to length(FActions) - 1 do
      FActions[i].InvertIf(FInverted).Deploy;
  Free;
end;

function TActionCompound.Invert : TActionCompound;
begin
  Result := InvertIf(True);
end;

function TActionCompound.InvertIf(const Condition : boolean) : TActionCompound;
begin
  Result := self;
  FInverted := Condition;
end;

{ TActionClient }

procedure TActionClient.Deploy;
begin
  MainActionQueue.DoAction(self);
end;

function TActionClient.DoInExecute : TActionClient;
begin
  Result := self;
  FDoInExecute := True;
end;

function TActionClient.DoInExecuteSynchronized : TActionClient;
begin
  Result := self;
  FDoInExecuteSynchronized := True;
end;

function TActionClient.DoInFinished : TActionClient;
begin
  Result := self;
  FDoInFinished := True;
end;

function TActionClient.Invert : TActionClient;
begin
  Result := InvertIf(True);
end;

function TActionClient.InvertIf(const Condition : boolean) : TActionClient;
begin
  Result := self;
  FInverted := Condition;
end;

{ TActionSetVariable<T> }

constructor TActionSetVariable<T>.Create(const NewValue : T; const FormerValue : T; const ValueSetter : ProcSetter<T>);
begin
  inherited Create;
  FNewValue := NewValue;
  FFormerValue := FormerValue;
  FSetter := ValueSetter;
end;

procedure TActionSetVariable<T>.Emulate;
begin
  inherited;
  assert(not FInverted, 'TActionSetVariable<T> is not invertible!');
  if not FDoInExecute and not FDoInExecuteSynchronized and not FDoInFinished then FSetter(FNewValue);
end;

function TActionSetVariable<T>.Execute : boolean;
begin
  Result := True;
  if FDoInExecute then FSetter(FNewValue);
end;

function TActionSetVariable<T>.ExecuteSynchronized : boolean;
begin
  Result := True;
  if FDoInExecuteSynchronized then FSetter(FNewValue);
end;

procedure TActionSetVariable<T>.Finished;
begin
  inherited;
  if FDoInFinished then FSetter(FNewValue);
end;

procedure TActionSetVariable<T>.Rollback;
begin
  inherited;
  if not FDoInExecute and not FDoInFinished then FSetter(FFormerValue);
end;

{ TActionSetInstanceVariable<T> }

function TActionSetInstanceVariable<T>.Execute : boolean;
begin
  Result := True;
  FFormerValue.Free;
end;

procedure TActionSetInstanceVariable<T>.Rollback;
begin
  inherited;
  FNewValue.Free;
end;

end.
