unit Engine.Helferlein.Rtti;

interface

uses
  System.Classes,
  System.Rtti,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Engine.Helferlein.DataStructures;

type
  ENotFoundException = class(Exception);
  EVirtualMethodInterceptorError = class(Exception);

  TVirtualMethodInterceptorHandle = class
    private
      FOnBefore : TInterceptBeforeNotify;
      FOnException : TInterceptExceptionNotify;
      FOnAfter : TInterceptAfterNotify;
    public
      property OnBefore : TInterceptBeforeNotify read FOnBefore write FOnBefore;
      property OnAfter : TInterceptAfterNotify read FOnAfter write FOnAfter;
      property OnException : TInterceptExceptionNotify read FOnException write FOnException;
  end;

  TInstanceInterceptor = class
    Instance : TObject;
    Interceptor : TVirtualMethodInterceptor;
    Handles : TLoopSafeObjectList<TVirtualMethodInterceptorHandle>;
    // counter of current intercepted calls, is incremented everytime a call starts and decremented when the call ends
    OpenCalls : integer;
    procedure BeforeHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : Boolean; out Result : TValue);
    procedure AfterHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; var Result : TValue);
    procedure ExceptionHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out RaiseException : Boolean; TheException : Exception; out Result : TValue);
    constructor Create(Instance : TObject);
    destructor Destroy; override;
  end;

  TVirtualMethodInterceptorManager = class
    private
      FDeadInstances : TObjectList<TInstanceInterceptor>;
      FInterceptedInstances : TDictionary<TObject, TInstanceInterceptor>;
      procedure CleanUp;
    public
      function Proxify(AInstance : TObject) : TVirtualMethodInterceptorHandle;
      procedure Unproxify(AInstance : TObject; Handle : TVirtualMethodInterceptorHandle);
      constructor Create;
      destructor Destroy; override;
  end;

var
  VirtualMethodInterceptorManager : TVirtualMethodInterceptorManager;
  // if enabled, some performance hungry checks are done to catch VirtualMethodInterceptor bugs
  // ONLY FOR DEBUGGING
  VIRTUAL_METHOD_INTERCEPTOR_DEBUG_MODE : Boolean = {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};

implementation

procedure Noop;
begin

end;

{ TInstanceInterceptor }

procedure TInstanceInterceptor.BeforeHandler(Instance : TObject; Method : TRttiMethod;
  const Args : TArray<TValue>; out DoInvoke : Boolean; out Result : TValue);
var
  Handle : TVirtualMethodInterceptorHandle;
begin
  assert(not SameText(Method.Name, 'BeforeDestruction', TLocaleOptions.loInvariantLocale) or assigned(self.Instance));
  inc(OpenCalls);
  // work on copy to avoid removing or adding handles cause unexpected behavior
  Handles.EnterSafeLoop;
  for Handle in Handles do
  begin
    if assigned(Handle) and assigned(Handle.FOnBefore) then
        Handle.FOnBefore(Instance, Method, Args, DoInvoke, Result);
  end;
  Handles.LeaveSafeLoop;
  if SameText(Method.Name, 'BeforeDestruction', TLocaleOptions.loInvariantLocale) then 
      self.Instance := nil;
end;

procedure TInstanceInterceptor.AfterHandler(Instance : TObject; Method : TRttiMethod;
  const Args : TArray<TValue>; var Result : TValue);
var
  Handle : TVirtualMethodInterceptorHandle;
begin
  if assigned(self.Instance) then
  begin
    Handles.EnterSafeLoop;
    for Handle in Handles do
    begin
      if assigned(Handle) and assigned(Handle.FOnAfter) then
          Handle.FOnAfter(Instance, Method, Args, Result);
    end;
    Handles.LeaveSafeLoop;
  end;
  dec(OpenCalls);
end;

procedure TInstanceInterceptor.ExceptionHandler(Instance : TObject; Method : TRttiMethod;
  const Args : TArray<TValue>; out RaiseException : Boolean; TheException : Exception; out Result : TValue);
var
  Handle : TVirtualMethodInterceptorHandle;
begin
  if assigned(self.Instance) then
  begin
    Handles.EnterSafeLoop;
    for Handle in Handles do
      if assigned(Handle) and assigned(Handle.FOnException) then
          Handle.FOnException(Instance, Method, Args, RaiseException, TheException, Result);
    Handles.LeaveSafeLoop;
  end;
  dec(OpenCalls);
end;

constructor TInstanceInterceptor.Create(Instance : TObject);
begin
  Handles := TLoopSafeObjectList<TVirtualMethodInterceptorHandle>.Create();
  Interceptor := TVirtualMethodInterceptor.Create(Instance.ClassType);
  Interceptor.OnBefore := BeforeHandler;
  Interceptor.OnAfter := AfterHandler;
  Interceptor.OnException := ExceptionHandler;
  Interceptor.Proxify(Instance);
  self.Instance := Instance;
end;

destructor TInstanceInterceptor.Destroy;
begin
  if assigned(self.Instance) then
  begin
    // some sanity checks...
    if PPointer(Instance)^ <> Interceptor.ProxyClass then
    begin
      if PPointer(Instance)^ = Interceptor.OriginalClass then
          raise EVirtualMethodInterceptorError.CreateFmt('Instance of type "%s" was tried to unproxified, but original class was already restored (was already unproxified).', [Interceptor.OriginalClass.ClassName])
      else
          raise EVirtualMethodInterceptorError.CreateFmt('Class of instance of type "%s" is not original and not proxy class, maybe it was proxified twice.', [Interceptor.OriginalClass.ClassName])
    end;
    Interceptor.Unproxify(Instance);
  end;
  Interceptor.Free;
  Handles.Free;
  inherited;
end;

{ TVirtualMethodInterceptorManager }

procedure TVirtualMethodInterceptorManager.CleanUp;
var
  i : integer;
begin
  for i := FDeadInstances.Count - 1 downto 0 do
    if (FDeadInstances[i].OpenCalls = 0) and assigned(FDeadInstances[i].Instance) then FDeadInstances.Delete(i);
end;

constructor TVirtualMethodInterceptorManager.Create;
begin
  FInterceptedInstances := TDictionary<TObject, TInstanceInterceptor>.Create(
    TEqualityComparer<TObject>.Construct(
    function(const Left, Right : TObject) : Boolean
    begin
      Result := Left = Right;
    end,
    function(const Value : TObject) : integer
    begin
      {$IFDEF CPUX64}
      Result := integer(IntPtr(Value)) xor integer(IntPtr(Value) shr 32);
      {$ELSE !CPUX64}
      Result := integer(IntPtr(Value));
      {$ENDIF !CPUX64}
    end));
  FDeadInstances := TObjectList<TInstanceInterceptor>.Create;
end;

destructor TVirtualMethodInterceptorManager.Destroy;
var Value : TInstanceInterceptor;
begin
  FDeadInstances.Free;
  for Value in FInterceptedInstances.Values do
    Value.Free;
  FInterceptedInstances.Free;
  inherited;
end;

function TVirtualMethodInterceptorManager.Proxify(AInstance : TObject) : TVirtualMethodInterceptorHandle;
var
  Interceptor : TInstanceInterceptor;
  i : integer;
begin
  CleanUp;
  assert(System.MainThreadID = TThread.CurrentThread.ThreadID, 'TVirtualMethodInterceptorManager.Proxify: Should never called in a thread environment!');
  if not assigned(AInstance) then raise EInvalidOpException.Create('TVirtualMethodInterceptorManager.Proxify: AInstance must not be nil to proxify!');

  // is instance not already intercepted
  if not FInterceptedInstances.TryGetValue(AInstance, Interceptor) then
  begin
    Interceptor := nil;
    // it's still possible that interceptor is already on deadlist (also when cleanup was already done)
    for i := 0 to FDeadInstances.Count - 1 do
      if FDeadInstances[i].Instance = AInstance then
      begin
        // reanimate interceptor, it's still needed
        // prevent deadlist from killing interceptor
        Interceptor := FDeadInstances[i];
        FInterceptedInstances.Add(AInstance, Interceptor);
        FDeadInstances.OwnsObjects := False;
        FDeadInstances.Delete(i);
        FDeadInstances.OwnsObjects := True;
        break;
      end;
    // but if no interceptor still present, create a new one
    if not assigned(Interceptor) then
    begin
      if VIRTUAL_METHOD_INTERCEPTOR_DEBUG_MODE then
      begin
        for Interceptor in FInterceptedInstances.Values do
        begin
          if Interceptor.Interceptor.ProxyClass = AInstance.ClassType then
          begin
            Noop;
            raise EVirtualMethodInterceptorError.CreateFmt('Instance of type "%s" is already intercepted, was tried to intercept it twice.', [AInstance.ClassName]);
          end;
        end;

        for Interceptor in FDeadInstances do
        begin
          if Interceptor.Interceptor.ProxyClass = AInstance.ClassType then
          begin
            Noop;
            raise EVirtualMethodInterceptorError.CreateFmt('Instance of type "%s" is already intercepted, was tried to intercept it twice.', [AInstance.ClassName]);
          end;
        end;
      end;

      Interceptor := TInstanceInterceptor.Create(AInstance);
      FInterceptedInstances.Add(AInstance, Interceptor);
    end;
  end;
  Result := TVirtualMethodInterceptorHandle.Create;
  Interceptor.Handles.Add(Result);
end;

procedure TVirtualMethodInterceptorManager.Unproxify(AInstance : TObject; Handle : TVirtualMethodInterceptorHandle);
var
  Interceptor : TInstanceInterceptor;
begin
  assert(System.MainThreadID = TThread.CurrentThread.ThreadID, 'TVirtualMethodInterceptorManager.Proxify: Should never called in a thread environment!');
  CleanUp;
  if not assigned(AInstance) or not assigned(Handle) then exit;
  if FInterceptedInstances.TryGetValue(AInstance, Interceptor) then
  begin
    Interceptor.Handles.Remove(Handle);
    // if no more handles left, no need to intercept instance anymore, so time to "real" Unproxify
    if Interceptor.Handles.Count <= 0 then
    begin
      // free instance will unproxify
      FInterceptedInstances.Remove(AInstance);
      FDeadInstances.Add(Interceptor);
    end;
  end
  else raise ENotFoundException.CreateFmt('TVirtualMethodInterceptorManager.Unproxify: Not entry for instance of class "%s" was found.',
      [AInstance.ClassName]);
  CleanUp;
end;

initialization

VirtualMethodInterceptorManager := TVirtualMethodInterceptorManager.Create;

finalization

VirtualMethodInterceptorManager.Free;

end.
