unit Engine.Helferlein.Threads;

interface

uses
  Winapi.Windows,
  Generics.Collections,
  System.SysUtils,
  System.SyncObjs,
  System.Classes;

type

  ProcThreadSafeCallback<T> = procedure(const Index : integer; const Item : T) of object;

  /// <summary> Thread safe queue working with FIFO concept.</summary>
  TThreadSafeQueue<T> = class
    protected
      FQueue : array of T;
      FQueueSize, FQueueOffset : integer;
      FQueueNotEmpty, FQueueNotFull : TObject;
      FQueueLock : TObject;
      FShutDown : Boolean;
      FPushTimeout, FPopTimeout : LongWord;
      FTotalItemsPushed, FTotalItemsPopped : LongWord;
    public
      constructor Create(AQueueDepth : integer = 10; PushTimeout : LongWord = INFINITE; PopTimeout : LongWord = INFINITE);
      destructor Destroy; override;
      /// <summary> Will grow </summary>
      procedure Grow(ADelta : integer);
      /// <summary> Push (add) an item on the end of the queue.</summary>
      function PushItem(const AItem : T) : TWaitResult; overload;
      /// <summary> Push (add) an item on the end of the queue. Will return current queue size with
      /// paramerer AQueueSize.</summary>
      function PushItem(const AItem : T; var AQueueSize : integer) : TWaitResult; overload;
      /// <summary> Pop (remove and return) an item from beginning of the queue.</summary>
      function PopItem : T; overload;
      function PopItem(var AQueueSize : integer) : T; overload;
      function PopItem(var AQueueSize : integer; var AItem : T) : TWaitResult; overload;
      function PopItem(var AItem : T) : TWaitResult; overload;
      procedure DoShutDown;

      property QueueSize : integer read FQueueSize;
      property ShutDown : Boolean read FShutDown;
      property TotalItemsPushed : LongWord read FTotalItemsPushed;
      property TotalItemsPopped : LongWord read FTotalItemsPopped;

      /// <summary> Remember to use a try .. finally block with lock unlock!. </summary>
      procedure Lock;
      /// <summary> Remember to use a try .. finally block with lock unlock!. </summary>
      procedure Unlock;
      /// <summary> Calls the callback for each item. Locks the Queue while doing this. </summary>
      procedure ForEach(Callback : ProcThreadSafeCallback<T>);
  end;

  /// <summary> Threadsafe implementation of a dictionary. Use TMultiReadExclusiveWriteSynchronizer to allow multiple
  /// read access, but exclusice write access.</summary>
  /// <remarks> Only the dict is threadsafe NOT the values safed in dict. So if get a graphics interface, it is possible that
  /// a other threads use the same graphics interface at the same moment. If using Lock and Unlock, a virtual exclusive accesss
  /// is granted. But that protect not against e.g. threads saving reference to items and change them later.</remarks>
  TThreadSafeObjectDictionary<TKey, TValue> = class
    private
      FObjectDictionary : TObjectDictionary<TKey, TValue>;
      // Multi read, single write
      FMRSWLock : TMultiReadExclusiveWriteSynchronizer;
      function GetItem(const Key : TKey) : TValue;
      procedure SetItem(const Key : TKey; const Value : TValue);
      function GetKeys : TObjectDictionary<TKey, TValue>.TKeyCollection;
    public
      property Items[const Key : TKey] : TValue read GetItem write SetItem; default;
      property Keys : TObjectDictionary<TKey, TValue>.TKeyCollection read GetKeys;
      procedure Add(const Key : TKey; const Value : TValue);
      procedure Remove(const Key : TKey);
      function TryGetValue(const Key : TKey; out Value : TValue) : Boolean;
      function ContainsKey(const Key : TKey) : Boolean;
      procedure Clear;
      /// <summary> Give exclusive access to dictionary. After finished work with dict, use unlock to give another threads
      /// access to dict.</summary>
      function ExclusiveLock : TObjectDictionary<TKey, TValue>;
      /// <summary> End exclusive access and give other threads possibilty to access dict.</summary>
      procedure ExclusiveUnlock;
      /// <summary> Give shared access to dictionary. After finished work with dict, use unlock to allow exclusive access to dict
      /// for other threads.</summary>
      function SharedLock : TObjectDictionary<TKey, TValue>;
      /// <summary> End exclusive access and give other threads possibilty to access dict.</summary>
      procedure SharedUnlock;

      constructor Create(Ownerships : TDictionaryOwnerships);
      destructor Destroy; override;
  end;

  /// <summary> Protect any data from type T from multiple access at same time, using CriticalSection.</summary>
  TThreadSafeData<T> = class
    private
      FData : T;
      FCritSection : TCriticalSection;
    public
      /// <summary> Direct access to data to write and read data, especially useful for non reference types. </summary>
      /// <remarks> Pay attention to lock data (call lock) before use data, else data is NOT threadsafe. Use unlock after finished
      /// working with data.</remarks>
      property Data : T read FData write FData;
      /// <summary> Init critical section and set data</summary>
      constructor Create(Data : T);
      /// <summary> Give exclusive access to data. After finished work with data, use unlock to give another threads
      /// access to data.</summary>
      function Lock : T;
      /// <summary> End exclusive access and give other threads possibilty to access data.</summary>
      procedure Unlock;
      /// <summary> Returns the data protecting the access of the data, but at return of this function the protection is alerady
      /// released. So use this only to read value data not refrence data (because the refrence is not protected anymore)</summary>
      function GetDataSafe : T;
      /// <summary> Sets the data in a protected enviroment. The protection is released when this method returns.</summary>
      procedure SetDataSafe(const Data : T);
      /// <summary> Badabumm</summary>
      destructor Destroy; override;
  end;

  /// <summary> Helper for some threadfunctions</summary>
  HThread = class
    private type
      TDoWorkThread = class(TThread)
        private
          FWork : TThreadProcedure;
          FSynchronize : Boolean;
        public
          constructor Create(Work : TThreadProcedure; Synchronize : Boolean; FreeOnTerminate : Boolean);
          procedure Execute; override;
      end;
    public
      /// <summary> Will do work in seperate Thread. Method create a new thread, thats execute the threadprocedure. Return the thread
      /// thats do the work. Do not OWN the thread! Thread will auomatically free all resources after finished.</summary>
      class function DoWork(Work : TThreadProcedure; FreeOnTerminate : Boolean = True) : TThread;
      /// <summary> Will do work in seperate Thread, but this thread will do the work synchronized with SynchronizeThread or if
      /// SynchronizeThread is = nil, with MainThread.
      /// Especially for use VCL stuff in another thread, e.g. Report an error, without blocking the current thread.</summary>
      class procedure DoWorkSynchronized(Work : TThreadProcedure; FreeOnTerminate : Boolean = True);
      class procedure WaitForMultipleThreads(Threads : TList<TThread>); overload;
      class procedure WaitForMultipleThreads(Threads : array of TThread); overload;
  end;

  /// <summary> Same as TThreadSafeData but addional owns data and free data on destruction.</summary>
  TThreadSafeObjectData<T : class> = class(TThreadSafeData<T>)
    private
      FOwnsData : Boolean;
    public
      /// <summary> Init critical section and set data.
      /// <param name="Data"> Data thats set.</param>
      /// <param name="OwnsData"> If true, data is freed on destruction of this object.</param></summary>
      constructor Create(Data : T; OwnsData : Boolean = True);
      /// <summary> Badabumm and free data if OwnsData.</summary>
      destructor Destroy; override;
  end;

  TThreadWorker<D, R> = class(TThread)
    private
      FResult : R;
      FData : D;
    public
      property Result : R read FResult write FResult;
      property Data : D read FData write FData;
  end;

  /// <summary> This class is a implementation of queue that processing data using workers.
  /// T is the Workerthread type. U is the type datatype of the work (the data which the workers processing).</summary>
  TThreadWorkerQueue<D, R; T : TThreadWorker<D, R>, constructor> = class
    public type
      ProcJobDone = reference to procedure(const Data : D; const Result : R);
    private
      FQueuingData : TQueue<D>;
      FMaximalWorkerThreads : integer;
      FRunningWorkerThreads : integer;
      FOnJobFinished : ProcJobDone;
      procedure StartWorker;
      procedure ThreadTerminteHandler(Sender : TObject);
    public
      property RunningWorkerThreads : integer read FRunningWorkerThreads;
      property MaximalWorkerThreads : integer read FMaximalWorkerThreads write FMaximalWorkerThreads;
      property OnJobFinished : ProcJobDone read FOnJobFinished write FOnJobFinished;
      procedure AddJob(Data : D);
      constructor Create(MaxWorkerThreads : integer);
      destructor Destroy; override;
  end;

  /// <summary> Executes a procedure in the contetx of the main thread. </summary>
procedure DoSynchronized(f : TThreadProcedure);

implementation


procedure DoSynchronized(f : TThreadProcedure);
begin
  // If this is not the main thread, synchronize f with the main thread
  if System.MainThreadID <> TThread.CurrentThread.ThreadID then
  begin
    TThread.Synchronize(nil, f);
  end
  // otherwise just call it, since we're already in the main thread apparently
  else f();
end;

{ TThreadSafeObjectDictionary<TKey, TValue> }

procedure TThreadSafeObjectDictionary<TKey, TValue>.Add(const Key : TKey; const Value : TValue);
begin
  FMRSWLock.BeginWrite;
  try
    FObjectDictionary.Add(Key, Value);
  finally
    FMRSWLock.EndWrite;
  end;
end;

procedure TThreadSafeObjectDictionary<TKey, TValue>.Clear;
begin
  FMRSWLock.BeginWrite;
  try
    FObjectDictionary.Clear;
  finally
    FMRSWLock.EndWrite;
  end;
end;

function TThreadSafeObjectDictionary<TKey, TValue>.ContainsKey(const Key : TKey) : Boolean;
begin
  FMRSWLock.BeginRead;
  try
    Result := FObjectDictionary.ContainsKey(Key);
  finally
    FMRSWLock.EndRead;
  end;
end;

constructor TThreadSafeObjectDictionary<TKey, TValue>.Create(Ownerships : TDictionaryOwnerships);
begin
  FMRSWLock := TMultiReadExclusiveWriteSynchronizer.Create;
  FObjectDictionary := TObjectDictionary<TKey, TValue>.Create(Ownerships);
end;

destructor TThreadSafeObjectDictionary<TKey, TValue>.Destroy;
begin
  FObjectDictionary.Free;
  FMRSWLock.Free;
  inherited;
end;

function TThreadSafeObjectDictionary<TKey, TValue>.GetItem(const Key : TKey) : TValue;
begin
  FMRSWLock.BeginRead;
  try
    Result := FObjectDictionary.Items[Key];
  finally
    FMRSWLock.EndRead;
  end;
end;

function TThreadSafeObjectDictionary<TKey, TValue>.GetKeys : TObjectDictionary<TKey, TValue>.TKeyCollection;
begin
  FMRSWLock.BeginRead;
  try
    Result := FObjectDictionary.Keys;
  finally
    FMRSWLock.EndRead;
  end;
end;

function TThreadSafeObjectDictionary<TKey, TValue>.ExclusiveLock : TObjectDictionary<TKey, TValue>;
begin
  FMRSWLock.BeginWrite;
  Result := FObjectDictionary;
end;

procedure TThreadSafeObjectDictionary<TKey, TValue>.ExclusiveUnlock;
begin
  FMRSWLock.EndWrite;
end;

procedure TThreadSafeObjectDictionary<TKey, TValue>.Remove(const Key : TKey);
begin
  FMRSWLock.BeginWrite;
  try
    FObjectDictionary.Remove(Key);
  finally
    FMRSWLock.EndWrite;
  end;
end;

procedure TThreadSafeObjectDictionary<TKey, TValue>.SetItem(const Key : TKey; const Value : TValue);
begin
  FMRSWLock.BeginWrite;
  try
    FObjectDictionary.Items[Key] := Value;
  finally
    FMRSWLock.EndWrite;
  end;
end;

function TThreadSafeObjectDictionary<TKey, TValue>.SharedLock : TObjectDictionary<TKey, TValue>;
begin
  FMRSWLock.BeginRead;
  Result := FObjectDictionary;
end;

procedure TThreadSafeObjectDictionary<TKey, TValue>.SharedUnlock;
begin
  FMRSWLock.EndRead;
end;

function TThreadSafeObjectDictionary<TKey, TValue>.TryGetValue(const Key : TKey; out Value : TValue) : Boolean;
begin
  FMRSWLock.BeginRead;
  try
    Result := FObjectDictionary.TryGetValue(Key, Value);
  finally
    FMRSWLock.EndRead;
  end;
end;

{ TThreadSafeObjectData<T> }

constructor TThreadSafeObjectData<T>.Create(Data : T; OwnsData : Boolean);
begin
  inherited Create(Data);
  FOwnsData := OwnsData;
end;

destructor TThreadSafeObjectData<T>.Destroy;
begin
  FCritSection.Enter;
  if FOwnsData then
      FData.Free;
  inherited;
end;

{ TThreadSafeData<T> }

constructor TThreadSafeData<T>.Create(Data : T);
begin
  FCritSection := TCriticalSection.Create;
  FData := Data;
end;

destructor TThreadSafeData<T>.Destroy;
begin
  FCritSection.Free;
  inherited;
end;

function TThreadSafeData<T>.GetDataSafe : T;
begin
  Result := Lock;
  Unlock;
end;

function TThreadSafeData<T>.Lock : T;
begin
  FCritSection.Enter;
  Result := FData;
end;

procedure TThreadSafeData<T>.SetDataSafe(const Data : T);
begin
  Lock;
  self.Data := Data;
  Unlock;
end;

procedure TThreadSafeData<T>.Unlock;
begin
  FCritSection.Leave;
end;

{ HThread.TDoWorkThread }

constructor HThread.TDoWorkThread.Create(Work : TThreadProcedure; Synchronize : Boolean; FreeOnTerminate : Boolean);
begin
  FWork := Work;
  FSynchronize := Synchronize;
  self.FreeOnTerminate := FreeOnTerminate;
  inherited Create();
end;

procedure HThread.TDoWorkThread.Execute;
begin
  if FSynchronize then
      Synchronize(nil, FWork)
  else
      FWork();
end;

{ HThread }

class function HThread.DoWork(Work : TThreadProcedure; FreeOnTerminate : Boolean) : TThread;
begin
  Result := TDoWorkThread.Create(Work, False, FreeOnTerminate);
end;

class procedure HThread.DoWorkSynchronized(Work : TThreadProcedure; FreeOnTerminate : Boolean);
begin
  TDoWorkThread.Create(Work, True, FreeOnTerminate);
end;

class procedure HThread.WaitForMultipleThreads(Threads : TList<TThread>);
begin
  WaitForMultipleThreads(Threads.ToArray());
end;

class procedure HThread.WaitForMultipleThreads(Threads : array of TThread);
var
  ThreadHandles : array of THandle;
  i : integer;
  ErrorCode : DWORD;

  procedure HandleError(ErrorCode : DWORD);
  var
    ErrorMessage : string;
    Len : integer;
  begin
    SetLength(ErrorMessage, 512);
    Len := Formatmessage(Format_Message_from_System,
      nil, ErrorCode, 0, @ErrorMessage[1], length(ErrorMessage), nil);
    SetLength(ErrorMessage, Len);
    ErrorMessage := inttostr(ErrorCode) + ': ' + ErrorMessage;
    raise EThread.Create(ErrorMessage);
  end;

begin
  if length(Threads) > 0 then
  begin
    SetLength(ThreadHandles, length(Threads));
    for i := 0 to length(Threads) - 1 do
        ThreadHandles[i] := Threads[i].Handle;
    ErrorCode := WaitForMultipleObjects(length(Threads), @ThreadHandles[0], True, INFINITE);
    if ErrorCode = WAIT_FAILED then
        HandleError(GetLastError);
  end;
end;

{ TThreadWorkerQueue<D, R, T> }

procedure TThreadWorkerQueue<D, R, T>.AddJob(Data : D);
begin
  FQueuingData.Enqueue(Data);
  if RunningWorkerThreads < MaximalWorkerThreads then
      StartWorker;
end;

constructor TThreadWorkerQueue<D, R, T>.Create(MaxWorkerThreads : integer);
begin
  FQueuingData := TQueue<D>.Create;
  FMaximalWorkerThreads := MaxWorkerThreads;
end;

destructor TThreadWorkerQueue<D, R, T>.Destroy;
begin
  FQueuingData.Free;
  inherited;
end;

procedure TThreadWorkerQueue<D, R, T>.StartWorker;
var
  Worker : TThreadWorker<D, R>;
begin
  assert(FQueuingData.Count > 0);
  Worker := T.Create;
  Worker.Data := FQueuingData.Dequeue;
  Worker.OnTerminate := ThreadTerminteHandler;
  Worker.Start;
end;

procedure TThreadWorkerQueue<D, R, T>.ThreadTerminteHandler(Sender : TObject);
var
  Worker : TThreadWorker<D, R>;
begin
  Worker := TThreadWorker<D, R>(Sender);
  Dec(FRunningWorkerThreads);
  if assigned(OnJobFinished) then
      OnJobFinished(Worker.Data, Worker.Result);
  if (RunningWorkerThreads < MaximalWorkerThreads) and (FQueuingData.Count > 0) then
      StartWorker;
end;

{ TThreadSafeQueue<T> }

constructor TThreadSafeQueue<T>.Create(AQueueDepth : integer = 10; PushTimeout : LongWord = INFINITE; PopTimeout : LongWord = INFINITE);
begin
  inherited Create;
  SetLength(FQueue, AQueueDepth);
  FQueueLock := TObject.Create;
  FQueueNotEmpty := TObject.Create;
  FQueueNotFull := TObject.Create;
  FPushTimeout := PushTimeout;
  FPopTimeout := PopTimeout;
end;

destructor TThreadSafeQueue<T>.Destroy;
begin
  DoShutDown;
  FQueueNotFull.Free;
  FQueueNotEmpty.Free;
  FQueueLock.Free;
  inherited;
end;

procedure TThreadSafeQueue<T>.Grow(ADelta : integer);
begin
  TMonitor.Enter(FQueueLock);
  try
    SetLength(FQueue, length(FQueue) + ADelta);
  finally
    TMonitor.Exit(FQueueLock);
  end;
  TMonitor.PulseAll(FQueueNotFull);
end;

function TThreadSafeQueue<T>.PopItem : T;
var
  LQueueSize : integer;
begin
  PopItem(LQueueSize, Result);
end;

function TThreadSafeQueue<T>.PopItem(var AQueueSize : integer; var AItem : T) : TWaitResult;
begin
  AItem := default (T);
  TMonitor.Enter(FQueueLock);
  try
    Result := wrSignaled;
    while (Result = wrSignaled) and (FQueueSize = 0) and not FShutDown do
      if not TMonitor.Wait(FQueueNotEmpty, FQueueLock, FPopTimeout) then
          Result := wrTimeout;

    if (FShutDown and (FQueueSize = 0)) or (Result <> wrSignaled) then
        Exit;

    AItem := FQueue[FQueueOffset];

    FQueue[FQueueOffset] := default (T);

    Dec(FQueueSize);
    Inc(FQueueOffset);
    Inc(FTotalItemsPopped);

    if FQueueOffset = length(FQueue) then
        FQueueOffset := 0;

  finally
    AQueueSize := FQueueSize;
    TMonitor.Exit(FQueueLock);
  end;

  TMonitor.Pulse(FQueueNotFull);
end;

function TThreadSafeQueue<T>.PopItem(var AItem : T) : TWaitResult;
var
  LQueueSize : integer;
begin
  Result := PopItem(LQueueSize, AItem);
end;

function TThreadSafeQueue<T>.PopItem(var AQueueSize : integer) : T;
begin
  PopItem(AQueueSize, Result);
end;

function TThreadSafeQueue<T>.PushItem(const AItem : T) : TWaitResult;
var
  LQueueSize : integer;
begin
  Result := PushItem(AItem, LQueueSize);
end;

function TThreadSafeQueue<T>.PushItem(const AItem : T; var AQueueSize : integer) : TWaitResult;
begin
  TMonitor.Enter(FQueueLock);
  try
    Result := wrSignaled;
    while (Result = wrSignaled) and (FQueueSize = length(FQueue)) and not FShutDown do
      if not TMonitor.Wait(FQueueNotFull, FQueueLock, FPushTimeout) then
          Result := wrTimeout;

    if FShutDown or (Result <> wrSignaled) then
        Exit;

    FQueue[(FQueueOffset + FQueueSize) mod length(FQueue)] := AItem;
    Inc(FQueueSize);
    Inc(FTotalItemsPushed);

  finally
    AQueueSize := FQueueSize;
    TMonitor.Exit(FQueueLock);
  end;

  TMonitor.Pulse(FQueueNotEmpty);
end;

procedure TThreadSafeQueue<T>.DoShutDown;
begin
  TMonitor.Enter(FQueueLock);
  try
    FShutDown := True;
  finally
    TMonitor.Exit(FQueueLock);
  end;
  TMonitor.PulseAll(FQueueNotFull);
  TMonitor.PulseAll(FQueueNotEmpty);
end;

procedure TThreadSafeQueue<T>.ForEach(Callback : ProcThreadSafeCallback<T>);
var
  i, Count : integer;
  AItem : T;
begin
  Lock;
  try
    i := FQueueOffset;
    Count := 0;
    while Count < FQueueSize do
    begin
      AItem := FQueue[i];
      Callback(Count, AItem);

      Inc(i);
      if i = length(FQueue) then
          i := 0;
      Inc(Count);
    end;
  finally
    Unlock;
  end;
end;

procedure TThreadSafeQueue<T>.Lock;
begin
  TMonitor.Enter(FQueueLock);
end;

procedure TThreadSafeQueue<T>.Unlock;
begin
  TMonitor.Exit(FQueueLock);
end;

end.
