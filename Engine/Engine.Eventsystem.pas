unit Engine.Eventsystem;

interface

uses
  // -----------------------Delphi-----------------------------------------------
  Generics.Defaults,
  Generics.Collections,
  System.Rtti,
  System.Classes,
  System.SysUtils,
  TypInfo,
  // -----------------------Engine-----------------------------------------------
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Script,
  // ------------------------Eventsystem----------------------------------------
  Engine.Eventsystem.Types,
  Engine.Eventsystem.Helper;

type

  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic]) FIELDS([vcPublic, vcProtected])}
  {$TYPEINFO ON}
  TEntityComponent = class;
  {$TYPEINFO OFF}
  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic]) FIELDS([vcPublic, vcProtected])}
  TEntity = class;

  {$RTTI EXPLICIT METHODS([]) FIELDS([])}

  /// <summary> Holds a value for every event. Entitylocal pool of values. Will be serialized between
  /// Server and Client </summary>
  TBlackboard = class
    public
      /// <summary> For every event in WriteOnDeserialize, on deserialize, Write for event will be
      /// triggerd instead of simple save value in blackboard (write will also save value in blackboard, but)
      /// though write, other components can notice value.</summary>
      class var WriteOnDeserialize : set of EnumEventIdentifier;
    private
      function TryGetValue(Event : EnumEventIdentifier; GroupIndex : integer; var Value : TList<RParam>) : boolean; overload;
      function TryGetValue(Event : EnumEventIdentifier; GroupIndex, Index : integer; out Value : RParam) : boolean; overload;
    protected
      FOwner : TEntity;
      FValues : array [EnumEventIdentifier] of TObjectList<TList<RParam>>;
      procedure SaveToStream(Stream : TStream);
      procedure LoadFromStream(Stream : TStream);
    public
      constructor Create(Owner : TEntity);
      procedure SetIndexedValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Index : integer; Value : RParam);
      function GetIndexedValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Index : integer) : RParam;
      procedure SetValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Value : RParam);
      function GetValue(Event : EnumEventIdentifier; Group : SetComponentGroup) : RParam;
      function GetIndexMap(Event : EnumEventIdentifier; Group : SetComponentGroup) : TDictionary<integer, RParam>;
      destructor Destroy; override;
  end;

  TEventbus = class;

  TRemoteSubscription = class(TObject)
    protected
      FTargetEventbus : TEventbus;
      FTargetComponent : TEntityComponent;
      FComponentFreed : boolean;
      FEventbusFreed : boolean;
      FEventname : EnumEventIdentifier;
      FEventType : EnumEventType;
      FPriority : EnumEventPriority;
      FRefCounter : integer;
      procedure DecRefCounter;
    public
      constructor Create(TargetComponent : TEntityComponent; TargetEventbus : TEventbus; Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority);
      procedure FreeComponent;
      procedure FreeEventbus;
      destructor Destroy; override;
  end;

  TEventbus = class
    public
      /// <summary> List all events that are sended by client or server if triggerd.</summary>
      class var SendIfServer : set of EnumEventIdentifier;
      class var SendIfClient : set of EnumEventIdentifier;
    protected
      const
      ARRAYSIZE = 256;

    type
      RSubscriber = record
        EntityComponent : TEntityComponent;
        Priority : EnumEventPriority;
        constructor Create(EntityComponent : TEntityComponent; Priority : EnumEventPriority);
      end;

    type

      TEventhandler = class
        Subscribers : TList<RSubscriber>;
        ParameterCount : integer;
        constructor Create(ParameterCount : integer);
        destructor Destroy; override;
      end;
    var
      FOwner : TEntity;
      FEventhandler : array [EnumEventIdentifier] of array [EnumEventType] of TEventhandler;
      FRemoteSubscriptions : TList<TRemoteSubscription>;
      procedure StartEvent(Group : SetComponentGroup);
      procedure EndEvent();
    public
      constructor Create(Owner : TEntity);
      function Read(Eventname : EnumEventIdentifier) : RParam; overload;
      function Read(Eventname : EnumEventIdentifier; Parameters : array of RParam) : RParam; overload;
      function Read(Eventname : EnumEventIdentifier; Parameters : array of RParam; Group : SetComponentGroup) : RParam; overload;
      function Read(Eventname : EnumEventIdentifier; Parameters : array of RParam; Group : SetComponentGroup; ComponentID : integer) : RParam; overload;
      procedure Trigger(Eventname : EnumEventIdentifier); overload;
      procedure Trigger(Eventname : EnumEventIdentifier; Values : array of RParam); overload;
      procedure Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup); overload;
      procedure Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup; ComponentID : integer); overload;
      procedure Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup; ComponentID : integer; Write : boolean); overload;
      procedure InvokeWithRawData(Eventname : EnumEventIdentifier; Group : SetComponentGroup; ComponentID : integer; ValuesAsRawData : TArray<Byte>; WriteEvent : boolean);
      procedure Write(Eventname : EnumEventIdentifier); overload;
      procedure Write(Eventname : EnumEventIdentifier; Values : array of RParam); overload;
      procedure Write(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup); overload;
      procedure Write(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup; ComponentID : integer); overload;
      procedure Subscribe(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityCompononent : TEntityComponent; ParameterCount : integer);
      /// <summary> Subscribe one remote eventbus and return class to manage subscribtion.</summary>
      procedure SubscribeRemote(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityCompononent : TEntityComponent; MethodName : string; ParameterCount : integer; NetworkSender : EnumNetworkSender = nsNone);
      procedure Unsubscribe(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityComponent : TEntityComponent);
      destructor Destroy; override;
  end;

  TEntityComponent = class
    private type
      TSubscribedEvent = class
        private
          Eventname : EnumEventIdentifier;
          EventHandler : Pointer;
          ParameterCount : integer;
          EventType : EnumEventType;
          TargetEventbus : TEventbus;
          EventPriority : EnumEventPriority;
        public
          constructor Create(Eventname : EnumEventIdentifier; EventHandler : Pointer; ParameterCount : integer; TargetEventbus : TEventbus; EventPriority : EnumEventPriority; EventType : EnumEventType);
      end;

    private
      FRttiContext : TRttiContext;
      FSubscribedEvents : array [EnumEventIdentifier] of array [EnumEventType] of TObjectList<TSubscribedEvent>;
      FRemoteSubscription : TList<TRemoteSubscription>;
      function LookUpSubscribedEvent(Caller : TEventbus; ei : EnumEventIdentifier; et : EnumEventType) : TSubscribedEvent;
      procedure DeploySubscribedEvent(Event : TSubscribedEvent);
      procedure DeleteSubscribedEvent(Event : TSubscribedEvent);
      function OnRead(Caller : TEventbus; Event : EnumEventIdentifier; ResultFromAncestor : RParam) : RParam; overload;
      function OnRead(Caller : TEventbus; Event : EnumEventIdentifier; var Parameters : array of RParam; ResultFromAncestor : RParam) : RParam; overload;
      function OnTrigger(Caller : TEventbus; Event : EnumEventIdentifier; var Parameters : array of RParam; Write : boolean) : boolean; virtual;
      procedure SubscribeEvents; virtual;
      procedure SubscribeEvent(Event : EnumEventIdentifier; EventType : EnumEventType; EventPriority : EnumEventPriority; EventHandler : Pointer; ParameterCount : integer; TargetEventbus : TEventbus);
      procedure UnSubscribeEvents; virtual;
    protected
      FOwner : TEntity;
      [XScriptNotPublished]
      FComponentGroup : SetComponentGroup;
      /// <summary> Unique ID for component related to owner entity NOT global. </summary>
      FUniqueID : integer;
      // Eventbus of the Owner
      function Eventbus : TEventbus;
      function GlobalEventbus : TEventbus;
    published
      [XEvent(eiFree, epLast, etTrigger)]
      function OnFree() : boolean;
    public
      property UniqueID : integer read FUniqueID;
      [XScriptNotPublished]
      property ComponentGroup : SetComponentGroup read FComponentGroup;
      constructor Create(Owner : TEntity); virtual;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<Byte>); virtual;
      destructor Destroy; override;
  end;

  CEntityComponent = class of TEntityComponent;

  {$RTTI INHERIT}
  TSerializableEntityComponent = class(TEntityComponent)
    protected
      function GetBaseType(AType : TRttiType) : TRttiType;
    public
      /// <summary> Load all data with Rtti from stream. Only called on clients</summary>
      [XScriptNotPublished]
      procedure Deserialize(Stream : TStream);
    published
      /// <summary> save all data with Rtti to stream. Only called on server</summary>
      [XScriptNotPublished]
      [XEvent(eiSerialize, epLast, etTrigger)]
      function Serialize(Stream : RParam) : boolean;
  end;

  CSerializableEntityComponent = class of TSerializableEntityComponent;

  TEntity = class
    strict private
      class function CreateFromScriptProc(PatternFileName, ProcName : string; GlobalEventbus : TEventbus) : TEntity; static;
    protected
      FEventbus : TEventbus;
      FGlobalEventbus : TEventbus;
      FBlackboard : TBlackboard;
      FMeta : boolean;
      FID : integer;
      FScriptFile : string;
      FCurrentComponentID : integer;
      function GetNewComponentID : integer;
    public
      property ID : integer read FID write FID;
      property ScriptFile : string read FScriptFile write FScriptFile;
      /// <summary>The local eventbus of this entity.</summary>
      property Eventbus : TEventbus read FEventbus;
      property Blackboard : TBlackboard read FBlackboard;
      property GlobalEventbus : TEventbus read FGlobalEventbus;
      property Meta : boolean read FMeta write FMeta;
      /// <summary>Creates the entity. Now components can be added.</summary>
      constructor Create(GlobalEventbus : TEventbus; ID : integer = 0);
      class function CreateFromScript(PatternFileName : string; GlobalEventbus : TEventbus) : TEntity; static;
      class function CreateMetaFromScript(PatternFileName : string; GlobalEventbus : TEventbus) : TEntity; static;
      /// <summary>Registers the entity in the game. Should be called after adding the components.</summary>
      procedure Deploy;
      [XScriptNotPublished]
      procedure Serialize(Stream : TStream);
      /// <summary> Creates an entity with the serialized components. Won't be deployed. </summary>
      [XScriptNotPublished]
      class function Deserialize(Stream : TStream; GlobalEventbus : TEventbus; ClassMap : TArray<REntityComponentClassMap>) : TEntity; static;
      destructor Destroy; override;
  end;

  REventInformation = record
    CalledToGroup : SetComponentGroup;
    constructor Create(CalledToGroup : SetComponentGroup);
  end;

var
  /// <summary> Holds information about the currently executing event. </summary>
  CurrentEvent : REventInformation;
  Eventstack : TStack<REventInformation>;

implementation

{ TBlackboard }

constructor TBlackboard.Create(Owner : TEntity);
begin
  FOwner := Owner;
end;

destructor TBlackboard.Destroy;
var
  i : EnumEventIdentifier;
begin
  for i := low(EnumEventIdentifier) to high(EnumEventIdentifier) do
    if assigned(FValues[i]) then
    begin
      FValues[i].Free;
    end;
  inherited;
end;

function TBlackboard.TryGetValue(Event : EnumEventIdentifier; GroupIndex, Index : integer; out Value : RParam) : boolean;
begin
  Result := (GroupIndex < FValues[Event].Count) and (index < FValues[Event][GroupIndex].Count) and not FValues[Event][GroupIndex][index].IsEmpty;
  if Result then Value := FValues[Event][GroupIndex][index];
end;

function TBlackboard.TryGetValue(Event : EnumEventIdentifier; GroupIndex : integer; var Value : TList<RParam>) : boolean;
begin
  Result := (GroupIndex < FValues[Event].Count) and assigned(FValues[Event][GroupIndex]);
  if Result then Value := FValues[Event][GroupIndex];
end;

function TBlackboard.GetIndexedValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Index : integer) : RParam;
var
  i : Byte;
begin
  index := index + 1;
  if not assigned(FValues[Event]) then exit(RPARAMEMPTY);
  if Group = [] then
  begin
    if not TryGetValue(Event, 0, index, Result) then exit(RPARAMEMPTY)
    else exit;
  end
  else
  begin
    for i := low(Byte) to high(Byte) do
      if i in Group then
      begin
        if TryGetValue(Event, i + 1, index, Result) then exit;
        Group := Group - [i];
        if Group = [] then break;
      end;
    Result := RPARAMEMPTY;
  end;
end;

function TBlackboard.GetIndexMap(Event : EnumEventIdentifier; Group : SetComponentGroup) : TDictionary<integer, RParam>;
var
  i : Byte;
  list : TList<RParam>;
  j : integer;
begin
  Result := TDictionary<integer, RParam>.Create;
  if not assigned(FValues[Event]) then exit;
  list := nil;
  if Group = [] then
  begin
    if not TryGetValue(Event, 0, list) then exit
  end
  else
  begin
    for i := low(Byte) to high(Byte) do
      if i in Group then
      begin
        if TryGetValue(Event, i + 1, list) then break;
        Group := Group - [i];
        if Group = [] then break;
      end;
  end;
  if assigned(list) then
    for j := 1 to list.Count - 1 do
      if not list[j].IsEmpty then Result.Add(j - 1, list[j]);
end;

function TBlackboard.GetValue(Event : EnumEventIdentifier; Group : SetComponentGroup) : RParam;
begin
  Result := GetIndexedValue(Event, Group, -1);
end;

procedure TBlackboard.SetIndexedValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Index : integer; Value : RParam);
var
  CompIndex : Byte;
  i, j : integer;
  procedure SetValueIndex(i, innerindex : integer);
  begin
    while FValues[Event].Count <= i do
        FValues[Event].Add(TList<RParam>.Create);
    while FValues[Event][i].Count <= innerindex do
        FValues[Event][i].Add(RPARAMEMPTY);
    FValues[Event][i][innerindex] := Value;
  end;

begin
  index := index + 1;
  if not assigned(FValues[Event]) then FValues[Event] := TObjectList < TList < RParam >>.Create;
  if Group = [] then SetValueIndex(0, index)
  else
    for CompIndex := low(Byte) to high(Byte) do
      if CompIndex in Group then
      begin
        SetValueIndex(CompIndex + 1, index);
        Group := Group - [CompIndex];
        if Group = [] then break;
      end;
  // check and clean list, if unsetting a value
  if Value.IsEmpty then
  begin
    for i := FValues[Event].Count - 1 downto 0 do
    begin
      for j := FValues[Event][i].Count - 1 downto 0 do
        if FValues[Event][i][j].IsEmpty then FValues[Event][i].Delete(j)
        else break;
      if not FValues[Event][i].Count <= 0 then FValues[Event].Delete(i)
      else break;
    end;
  end;
end;

procedure TBlackboard.SetValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Value : RParam);
begin
  SetIndexedValue(Event, Group, -1, Value);
end;

procedure TBlackboard.SaveToStream(Stream : TStream);
var
  i : EnumEventIdentifier;
  j, k : integer;
  Count : Word;
  groupcount, indexcount : Byte;
begin
  Count := 0;
  // count used events
  for i := low(EnumEventIdentifier) to high(EnumEventIdentifier) do
    if assigned(FValues[i]) then inc(Count);
  Stream.WriteAny<Word>(Count);
  // write used events
  for i := low(EnumEventIdentifier) to high(EnumEventIdentifier) do
    if assigned(FValues[i]) then
    begin
      Stream.WriteAny<EnumEventIdentifier>(i);
      // count used componentgroups
      groupcount := 0;
      for j := 0 to FValues[i].Count - 1 do
        if FValues[i][j].Count > 0 then inc(groupcount);
      assert(groupcount > 0, 'There seems to be an invalid item in the board');
      Stream.WriteAny<Byte>(groupcount);
      // write used componentgroups
      for j := 0 to FValues[i].Count - 1 do
        if FValues[i][j].Count > 0 then
        begin
          Stream.WriteAny<Byte>(j);
          // count used indices
          indexcount := 0;
          for k := 0 to FValues[i][j].Count - 1 do
            if not FValues[i][j][k].IsEmpty then inc(indexcount);
          Stream.WriteAny<Byte>(indexcount);
          // write used indices
          for k := 0 to FValues[i][j].Count - 1 do
            if not FValues[i][j][k].IsEmpty then
            begin
              Stream.WriteAny<Byte>(k);
              FValues[i][j][k].SerializeIntoStream(Stream);
            end;
        end;
    end;
end;

procedure TBlackboard.LoadFromStream(Stream : TStream);
var
  ei : EnumEventIdentifier;
  i, Count : Word;
  TargetGroup, groupcount, indexcount : Byte;
  j, k, Index : integer;
  Group : SetComponentGroup;
  Para : RParam;
begin
  Count := Stream.ReadAny<Word>();
  for i := 0 to Count - 1 do
  begin
    ei := Stream.ReadAny<EnumEventIdentifier>();
    groupcount := Stream.ReadAny<Byte>();
    for j := 0 to groupcount - 1 do
    begin
      TargetGroup := Stream.ReadAny<Byte>();
      if TargetGroup <= 0 then Group := []
      else Group := [TargetGroup - 1];
      indexcount := Stream.ReadAny<Byte>();
      for k := 0 to indexcount - 1 do
      begin
        index := Stream.ReadAny<Byte>() - 1;
        Para := RParam.DeserializeFromStream(Stream);
        if ei in TBlackboard.WriteOnDeserialize then
            FOwner.Eventbus.Write(ei, [Para], Group)
        else SetIndexedValue(ei, Group, index, Para);
      end;
    end;
  end;
end;

{ TRemoteSubscription }

constructor TRemoteSubscription.Create(TargetComponent : TEntityComponent; TargetEventbus : TEventbus; Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority);
begin
  FComponentFreed := False;
  FEventbusFreed := False;
  FTargetEventbus := TargetEventbus;
  FTargetComponent := TargetComponent;
  FEventname := Eventname;
  FPriority := Priority;
  FEventType := EventType;
  FRefCounter := 2;
end;

procedure TRemoteSubscription.DecRefCounter;
begin
  dec(FRefCounter);
  // eventbus and component are freed, free me too ;)
  if FRefCounter <= 0 then
      self.Free;
end;

destructor TRemoteSubscription.Destroy;
begin
  if not FComponentFreed then
      raise EHandleEventException.Create('TRemoteSubscription.Destroy: Component(' + FTargetComponent.ClassName + ') has not been freed!');
  if not FEventbusFreed then
      raise EHandleEventException.Create('TRemoteSubscription.Destroy: Eventbus has not been freed!');
  inherited;
end;

procedure TRemoteSubscription.FreeComponent;
begin
  assert(FComponentFreed = False);
  FComponentFreed := True;
  // if TargetEventbus exist, unsubscribe!
  if not FEventbusFreed then
  begin
    FTargetEventbus.Unsubscribe(FEventname, FEventType, FPriority, FTargetComponent);
  end;
  // delete manually to prevent auto unsubscribe on eventbus
  FTargetComponent.DeleteSubscribedEvent(FTargetComponent.LookUpSubscribedEvent(FTargetEventbus, FEventname, FEventType));
  DecRefCounter;
end;

procedure TRemoteSubscription.FreeEventbus;
begin
  assert(FEventbusFreed = False);
  FEventbusFreed := True;
  DecRefCounter;
end;

{ TEventbus.RSubscriber }

constructor TEventbus.RSubscriber.Create(EntityComponent : TEntityComponent; Priority : EnumEventPriority);
begin
  self.EntityComponent := EntityComponent;
  self.Priority := Priority;
end;

{ TEventbus.TEventhandler }

constructor TEventbus.TEventhandler.Create(ParameterCount : integer);
begin
  self.ParameterCount := ParameterCount;
  Subscribers := TList<RSubscriber>.Create(TComparer<RSubscriber>.Construct(
    function(const Left, Right : RSubscriber) : integer
    begin
      if ((Left.EntityComponent = Right.EntityComponent) and (Left.Priority = Right.Priority)) then
          Result := 0
      else Result := 1;
    end
    ));
end;

destructor TEventbus.TEventhandler.Destroy;
begin
  Subscribers.Free;
  inherited;
end;

{ TEventbus }

constructor TEventbus.Create(Owner : TEntity);
begin
  FOwner := Owner;
  FRemoteSubscriptions := TList<TRemoteSubscription>.Create;
end;

destructor TEventbus.Destroy;
var
  ei : EnumEventIdentifier;
  et : EnumEventType;
  Event : TEventhandler;
  i : integer;
begin
  for i := 0 to FRemoteSubscriptions.Count - 1 do
      FRemoteSubscriptions[i].FreeEventbus;
  FRemoteSubscriptions.Free;
  for ei := low(EnumEventIdentifier) to high(EnumEventIdentifier) do
    for et := low(EnumEventType) to high(EnumEventType) do
      if assigned(FEventhandler[ei, et]) then
      begin
        Event := FEventhandler[ei, et];
        Event.Free;
      end;
  inherited;
end;

procedure TEventbus.StartEvent(Group : SetComponentGroup);
begin
  Eventstack.Push(REventInformation.Create(Group));
  CurrentEvent := Eventstack.Peek;
end;

procedure TEventbus.EndEvent;
begin
  Eventstack.Pop;
  if Eventstack.Count > 0 then CurrentEvent := Eventstack.Peek
  else CurrentEvent := default (REventInformation);
end;

function TEventbus.Read(Eventname : EnumEventIdentifier) : RParam;
begin
  Result := read(Eventname, [], [], 0);
end;

function TEventbus.Read(Eventname : EnumEventIdentifier; Parameters : array of RParam) : RParam;
begin
  Result := read(Eventname, Parameters, [], 0);
end;

function TEventbus.Read(Eventname : EnumEventIdentifier; Parameters : array of RParam; Group : SetComponentGroup) : RParam;
begin
  Result := read(Eventname, Parameters, Group, 0);
end;

function TEventbus.Read(Eventname : EnumEventIdentifier; Parameters : array of RParam; Group : SetComponentGroup; ComponentID : integer) : RParam;
var
  EventHandler : TEventhandler;
  i : integer;
begin
  StartEvent(Group);
  if assigned(FOwner) then Result := FOwner.FBlackboard.GetValue(Eventname, Group)
  else FillChar(Result, SizeOf(Result), 0);
  EventHandler := FEventhandler[Eventname, etRead];
  if assigned(EventHandler) then
  begin
    for i := 0 to EventHandler.Subscribers.Count - 1 do
      if ((Group = []) or (Group * EventHandler.Subscribers[i].EntityComponent.ComponentGroup <> []) or (EventHandler.Subscribers[i].EntityComponent.ComponentGroup = ALLGROUP)) and
        ((ComponentID = 0) or (EventHandler.Subscribers[i].EntityComponent.FUniqueID = ComponentID)) then
      begin
        Result := EventHandler.Subscribers[i].EntityComponent.OnRead(self, Eventname, Parameters, Result);
      end;
  end;
  EndEvent;
  // if not assigned(EventHandler) or (EventHandler.Subscribers.Count <= 0) then
  // raise Exception.Create('Event ' + HRtti.EnumerationToString<EnumEventIdentifier>(Eventname) + ' was read, but no handler registered!');
end;

procedure TEventbus.Subscribe(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority;
EntityCompononent : TEntityComponent; ParameterCount : integer);
var
  EventHandler : TEventhandler;
  Subscriber : RSubscriber;
  i : integer;
  Inserted : boolean;
begin
  Subscriber := RSubscriber.Create(EntityCompononent, Priority);
  EventHandler := FEventhandler[Eventname, EventType];
  if not assigned(EventHandler) then
  begin
    EventHandler := TEventhandler.Create(ParameterCount);
    FEventhandler[Eventname, EventType] := EventHandler;
  end;
  Inserted := False;
  for i := 0 to EventHandler.Subscribers.Count - 1 do
    if Ord(EventHandler.Subscribers[i].Priority) > Ord(Priority) then
    begin
      EventHandler.Subscribers.Insert(i, Subscriber);
      Inserted := True;
      break;
    end;
  if not Inserted then EventHandler.Subscribers.Add(Subscriber);
end;

procedure TEventbus.SubscribeRemote(Eventname : EnumEventIdentifier;
EventType : EnumEventType; Priority : EnumEventPriority;
EntityCompononent : TEntityComponent; MethodName : string;
ParameterCount : integer;
NetworkSender : EnumNetworkSender);
var
  RttiContext : TRttiContext;
  RttiMethod : TRttiMethod;
  MethodAdress : Pointer;
  Subscribtion : TRemoteSubscription;
begin
  assert(EntityCompononent.Eventbus <> self, 'Wrong method for selfregistration, but technically should work.');
  RttiContext := TRttiContext.Create;
  RttiMethod := RttiContext.GetType(EntityCompononent.ClassType).GetMethod(MethodName);
  if not assigned(RttiMethod) then raise ERegisterEventException.Create('TEventbus.SubscribeRemote: Could not find ' + RttiMethod.Name + 'in class' + EntityCompononent.ClassName);
  MethodAdress := RttiMethod.CodeAddress;
  assert(MethodAdress <> nil);
  Subscribtion := TRemoteSubscription.Create(EntityCompononent, self, Eventname, EventType, Priority);
  EntityCompononent.FRemoteSubscription.Add(Subscribtion);
  self.FRemoteSubscriptions.Add(Subscribtion);
  EntityCompononent.SubscribeEvent(Eventname, EventType, Priority, MethodAdress, ParameterCount, self);
end;

procedure TEventbus.Trigger(Eventname : EnumEventIdentifier);
begin
  Trigger(Eventname, [], [], 0);
end;

procedure TEventbus.Trigger(Eventname : EnumEventIdentifier; Values : array of RParam);
begin
  Trigger(Eventname, Values, [], 0);
end;

procedure TEventbus.Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup);
begin
  Trigger(Eventname, Values, Group, 0);
end;

procedure TEventbus.Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup; ComponentID : integer);
begin
  Trigger(Eventname, Values, Group, ComponentID, False);
end;

procedure TEventbus.Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup; ComponentID : integer; Write : boolean);

  function EventIdentifierToNetworkSend(Event : EnumEventIdentifier) : EnumNetworkSender;
  begin
    if Event in TEventbus.SendIfServer then
        Result := nsServer
    else
      if Event in TEventbus.SendIfClient then
        Result := nsClient
    else Result := nsNone;
  end;

var
  EventHandler : TEventhandler;
  Subscriber : RSubscriber;
  i, Count : integer;
  Parameters : TArray<RParam>;
  GlobalEventbus : TEventbus;
  SendID : integer;
begin
  StartEvent(Group);
  EventHandler := FEventhandler[Eventname, HGeneric.TertOp<EnumEventType>(write, etWrite, etTrigger)];
  if assigned(EventHandler) then
  begin
    i := 0;
    while i <= EventHandler.Subscribers.Count - 1 do
    begin
      Count := EventHandler.Subscribers.Count;
      Subscriber := EventHandler.Subscribers[i];
      if ((Group = []) or (Group * Subscriber.EntityComponent.ComponentGroup <> []) or (EventHandler.Subscribers[i].EntityComponent.ComponentGroup = ALLGROUP)) and
        ((ComponentID = 0) or (Subscriber.EntityComponent.FUniqueID = ComponentID)) then
        if not Subscriber.EntityComponent.OnTrigger(self, Eventname, Values, write) then
        begin
          EndEvent;
          exit;
        end;
      if EventHandler.Subscribers.Count >= Count then inc(i);
    end;
  end;
  if EventIdentifierToNetworkSend(Eventname) in [APPLICATIONTYPE] then
  begin
    setlength(Parameters, length(Values));
    for i := 0 to length(Values) - 1 do
    begin
      Parameters[i] := Values[i];
    end;
    // only the globaleventbus has no owner
    if assigned(FOwner) then GlobalEventbus := FOwner.FGlobalEventbus
    else GlobalEventbus := self;
    if assigned(FOwner) then SendID := FOwner.ID
    else SendID := 0;
    GlobalEventbus.Trigger(eiNetworkSend, [SendID, RParam.From<EnumEventIdentifier>(Eventname), RParam.From<SetComponentGroup>(Group), ComponentID, RParam.FromArray<RParam>(Parameters), write]);
    GlobalEventbus.Trigger(eiEventFired, [RParam.From<EnumEventIdentifier>(Eventname), True]);
  end;
  if assigned(FOwner) and write and (length(Values) > 0) then FOwner.FBlackboard.SetValue(Eventname, Group, Values[0]);
  EndEvent;
end;

procedure TEventbus.InvokeWithRawData(Eventname : EnumEventIdentifier; Group : SetComponentGroup; ComponentID : integer; ValuesAsRawData : TArray<Byte>; WriteEvent : boolean);
var
  i, DataPos, ParameterCount : integer;
  Values : TArray<RParam>;
  RawDataPosition, DataLength : integer;
  StringLength : Word;
  Str : string;
begin
  // count parameter
  ParameterCount := 0;
  DataPos := 0;
  while DataPos < length(ValuesAsRawData) do
  begin
    // if data was found a parameter is here ;)
    inc(ParameterCount);
    // skip data for parameter
    // other data then string save data in first byte
    if PByte(@ValuesAsRawData[DataPos])^ > 0 then
        DataPos := DataPos + 1 + PByte(@ValuesAsRawData[DataPos])^
      // string save data in a extra word
    else DataPos := DataPos + 1 + 2 + (PWord(@ValuesAsRawData[DataPos + 1])^ * SizeOf(Char));
  end;
  assert(DataPos = length(ValuesAsRawData));
  // now we know how much parameter we have
  setlength(Values, ParameterCount);
  // copy rawdata in to RParam array
  RawDataPosition := 0;
  for i := 0 to length(Values) - 1 do
  begin
    DataLength := PByte(@ValuesAsRawData[RawDataPosition])^;
    inc(RawDataPosition);
    case DataLength of
      // Zero signals that following data saved stringdata
      0 :
        begin
          StringLength := PWord(@ValuesAsRawData[RawDataPosition])^;
          inc(RawDataPosition, 2);
          setlength(Str, StringLength);
          move(ValuesAsRawData[RawDataPosition], Str[1], StringLength * SizeOf(Char));
          Values[i] := Str;
          RawDataPosition := RawDataPosition + (StringLength * SizeOf(Char));
        end
      // <> Zero, dont know datatype, only knows datasize
    else
      begin
        Values[i] := RParam.FromRawData(@ValuesAsRawData[RawDataPosition], DataLength);
        RawDataPosition := RawDataPosition + DataLength;
      end;
    end;
  end;
  assert(RawDataPosition = length(ValuesAsRawData));
  if WriteEvent then write(Eventname, Values, Group, ComponentID)
  else Trigger(Eventname, Values, Group, ComponentID);
end;

procedure TEventbus.Unsubscribe(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityComponent : TEntityComponent);
begin
  assert(assigned(FEventhandler[Eventname, EventType]));
  FEventhandler[Eventname, EventType].Subscribers.Remove(RSubscriber.Create(EntityComponent, Priority));
end;

procedure TEventbus.Write(Eventname : EnumEventIdentifier);
begin
  write(Eventname, [], [], 0);
end;

procedure TEventbus.Write(Eventname : EnumEventIdentifier; Values : array of RParam);
begin
  write(Eventname, Values, [], 0);
end;

procedure TEventbus.Write(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup);
begin
  write(Eventname, Values, Group, 0);
end;

procedure TEventbus.Write(Eventname : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup; ComponentID : integer);
begin
  Trigger(Eventname, Values, Group, ComponentID, True);
end;

{ REventInformation }

constructor REventInformation.Create(CalledToGroup : SetComponentGroup);
begin
  self.CalledToGroup := CalledToGroup;
end;

{ TEntityComponent.TSubscribedEvent }

constructor TEntityComponent.TSubscribedEvent.Create(Eventname : EnumEventIdentifier; EventHandler : Pointer;
  ParameterCount : integer; TargetEventbus : TEventbus; EventPriority : EnumEventPriority; EventType : EnumEventType);
begin
  self.Eventname := Eventname;
  self.EventHandler := EventHandler;
  self.ParameterCount := ParameterCount;
  self.TargetEventbus := TargetEventbus;
  self.EventPriority := EventPriority;
  self.EventType := EventType;
end;

{ TEntityComponent }

constructor TEntityComponent.Create(Owner : TEntity);
begin
  CreateGrouped(Owner, nil);
end;

constructor TEntityComponent.CreateGrouped(Owner : TEntity; Group : TArray<Byte>);
begin
  FOwner := Owner;
  FRemoteSubscription := TList<TRemoteSubscription>.Create;
  FUniqueID := Owner.GetNewComponentID;
  FComponentGroup := ByteArrayToComponentGroup(Group);
  FRttiContext := TRttiContext.Create;
  SubscribeEvents;
end;

procedure TEntityComponent.DeploySubscribedEvent(Event : TSubscribedEvent);
var
  list : TObjectList<TSubscribedEvent>;
begin
  list := FSubscribedEvents[Event.Eventname, Event.EventType];
  assert(not(LookUpSubscribedEvent(Event.TargetEventbus, Event.Eventname, Event.EventType) <> nil), 'Double subscription!');
  if not assigned(list) then
  begin
    list := TObjectList<TSubscribedEvent>.Create;
    FSubscribedEvents[Event.Eventname, Event.EventType] := list;
  end;
  list.Add(Event);
end;

procedure TEntityComponent.DeleteSubscribedEvent(Event : TSubscribedEvent);
var
  list : TObjectList<TSubscribedEvent>;
begin
  list := FSubscribedEvents[Event.Eventname, Event.EventType];
  if assigned(list) then
  begin
    list.Remove(Event);
  end;
end;

destructor TEntityComponent.Destroy;
begin
  UnSubscribeEvents;
  FRemoteSubscription.Free;
  FRttiContext.Free;
  inherited;
end;

function TEntityComponent.Eventbus : TEventbus;
begin
  assert(assigned(FOwner));
  Result := FOwner.FEventbus;
end;

function TEntityComponent.GlobalEventbus : TEventbus;
begin
  assert(assigned(FOwner));
  Result := FOwner.FGlobalEventbus;
end;

function TEntityComponent.LookUpSubscribedEvent(Caller : TEventbus; ei : EnumEventIdentifier; et : EnumEventType) : TSubscribedEvent;
var
  list : TObjectList<TSubscribedEvent>;
  i : integer;
begin
  Result := nil;
  list := FSubscribedEvents[ei, et];
  if assigned(list) then
  begin
    for i := 0 to list.Count - 1 do
      if list[i].TargetEventbus = Caller then exit(list[i]);
  end;
end;

function TEntityComponent.OnFree : boolean;
begin
  Result := True;
  self.Free;
end;

function TEntityComponent.OnRead(Caller : TEventbus; Event : EnumEventIdentifier; ResultFromAncestor : RParam) : RParam;
var
  SubscribedEvent : TSubscribedEvent;
  EventMethod : TMethod;
begin
  SubscribedEvent := LookUpSubscribedEvent(Caller, Event, etRead);
  assert(assigned(SubscribedEvent), 'For event "' + HRtti.EnumerationToString(Event) + '" of type "' + HRtti.EnumerationToString(etRead) + '" no method found!');

  // ResultFromAncestor is optional, check parametercount
  if not((1 = SubscribedEvent.ParameterCount) or ((0 = SubscribedEvent.ParameterCount))) then
      raise EHandleEventException.Create(Format('Parametercount for read event "%s" in component "%s" does not match - expected %d[+1], found %d.',
      [HRtti.EnumerationToString(Event), self.ClassName, SubscribedEvent.ParameterCount, 0]));
  // prepare invoke
  EventMethod.Code := SubscribedEvent.EventHandler;
  EventMethod.Data := self;
  // choice methodtype by parametercount
  case SubscribedEvent.ParameterCount of
    0 : Result := ProcEventReadParam0(EventMethod)();
    1 : Result := ProcEventReadParam1(EventMethod)(ResultFromAncestor);
  else raise EHandleEventException.Create(Format('Parametercount %d not supported.', [SubscribedEvent.ParameterCount]));
  end;
end;

function TEntityComponent.OnRead(Caller : TEventbus; Event : EnumEventIdentifier; var Parameters : array of RParam; ResultFromAncestor : RParam) : RParam;
var
  SubscribedEvent : TSubscribedEvent;
  EventMethod : TMethod;
  UseResultFromAncestor : boolean;
begin
  SubscribedEvent := LookUpSubscribedEvent(Caller, Event, etRead);
  assert(assigned(SubscribedEvent), 'For event "' + HRtti.EnumerationToString(Event) + '" of type "' + HRtti.EnumerationToString(etRead) + '" no method found!');

  // ResultFromAncestor is optional, check parametercount
  if not((length(Parameters) + 1 = SubscribedEvent.ParameterCount) or ((length(Parameters) = SubscribedEvent.ParameterCount))) then
      raise EHandleEventException.Create(Format('Parametercount for read event "%s" in component "%s" does not match - expected %d[+1], found %d.',
      [HRtti.EnumerationToString(Event), self.ClassName, SubscribedEvent.ParameterCount, length(Parameters)]));
  // prepare invoke
  EventMethod.Code := SubscribedEvent.EventHandler;
  EventMethod.Data := self;
  UseResultFromAncestor := length(Parameters) + 1 = SubscribedEvent.ParameterCount;
  // choice methodtype by parametercount
  case SubscribedEvent.ParameterCount of
    0 : Result := ProcEventReadParam0(EventMethod)();
    1 :
      begin
        if UseResultFromAncestor then Result := ProcEventReadParam1(EventMethod)(ResultFromAncestor)
        else Result := ProcEventReadParam1(EventMethod)(Parameters[0]);
      end;
    2 :
      begin
        if UseResultFromAncestor then Result := ProcEventReadParam2(EventMethod)(Parameters[0], ResultFromAncestor)
        else Result := ProcEventReadParam2(EventMethod)(Parameters[0], Parameters[1]);
      end;
    3 :
      begin
        if UseResultFromAncestor then Result := ProcEventReadParam3(EventMethod)(Parameters[0], Parameters[1], ResultFromAncestor)
        else Result := ProcEventReadParam3(EventMethod)(Parameters[0], Parameters[1], Parameters[2]);
      end;
    4 :
      begin
        if UseResultFromAncestor then Result := ProcEventReadParam4(EventMethod)(Parameters[0], Parameters[1], Parameters[2], ResultFromAncestor)
        else Result := ProcEventReadParam4(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3]);
      end;
    5 :
      begin
        if UseResultFromAncestor then Result := ProcEventReadParam5(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], ResultFromAncestor)
        else Result := ProcEventReadParam5(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], Parameters[4]);
      end
  else raise EHandleEventException.Create(Format('Parametercount %d not supported.', [SubscribedEvent.ParameterCount]));
  end;
end;

function TEntityComponent.OnTrigger(Caller : TEventbus; Event : EnumEventIdentifier; var Parameters : array of RParam; Write : boolean) : boolean;
var
  SubscribedEvent : TSubscribedEvent;
  EventMethod : TMethod;
begin
  if write then SubscribedEvent := LookUpSubscribedEvent(Caller, Event, etWrite)
  else SubscribedEvent := LookUpSubscribedEvent(Caller, Event, etTrigger);
  assert(assigned(SubscribedEvent), 'For event "' + HRtti.EnumerationToString(Event) + '" of type "' + HRtti.EnumerationToString(etTrigger) + '" no method found!');

  // check parametercount
  if not(length(Parameters) = SubscribedEvent.ParameterCount) then
      raise EHandleEventException.Create(Format('Parametercount for trigger event "%s" in component "%s" does not match - expected %d, found %d.',
      [HRtti.EnumerationToString(Event), self.ClassName, SubscribedEvent.ParameterCount, length(Parameters)]));
  // prepare invoke
  EventMethod.Code := SubscribedEvent.EventHandler;
  EventMethod.Data := Pointer(self);
  // choice methodtype by parametercount
  case SubscribedEvent.ParameterCount of
    0 : Result := ProcEventTriggerParam0(EventMethod)();
    1 :
      begin
        Result := ProcEventTriggerParam1(EventMethod)(Parameters[0]);
      end;
    2 :
      begin
        Result := ProcEventTriggerParam2(EventMethod)(Parameters[0], Parameters[1]);
      end;
    3 :
      begin
        Result := ProcEventTriggerParam3(EventMethod)(Parameters[0], Parameters[1], Parameters[2]);
      end;
    4 :
      begin
        Result := ProcEventTriggerParam4(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3]);
      end;
    5 :
      begin
        Result := ProcEventTriggerParam5(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], Parameters[4]);
      end;
    6 :
      begin
        Result := ProcEventTriggerParam6(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], Parameters[4], Parameters[5]);
      end
  else raise EHandleEventException.Create(Format('Parametercount %d not supported.', [SubscribedEvent.ParameterCount]));
  end;
end;

procedure TEntityComponent.SubscribeEvent(Event : EnumEventIdentifier;
  EventType : EnumEventType; EventPriority : EnumEventPriority; EventHandler : Pointer; ParameterCount : integer;
  TargetEventbus : TEventbus);
begin
  // subscribe event
  TargetEventbus.Subscribe(Event, EventType, EventPriority, self, ParameterCount);
  DeploySubscribedEvent(TSubscribedEvent.Create(Event, EventHandler, ParameterCount, TargetEventbus, EventPriority, EventType));
end;

procedure TEntityComponent.SubscribeEvents;
var
  SelfType : TRttiInstanceType;
  Method : TRttiMethod;
  EventAttribute : XEvent;
  TargetEventbus : TEventbus;
  Attributes : TArray<TCustomAttribute>;
  Parameters : TArray<TRttiParameter>;
  VarParameters : SetVarParameter;
var
  i : integer;
  procedure CheckExpected(ExpectedType, GivenType : PTypeInfo; Target : string);
  begin
    if ExpectedType <> GivenType then
        raise ERegisterEventException.Create(Format(
        'TEntityComponent.SubscribeEvents: For %s in "%s.%s" was type "%s" expected, but type "%s" found!',
        [Target, SelfType.QualifiedName, Method.Name, ExpectedType.Name, GivenType.Name]));
  end;

  procedure CheckResultType;
  begin
    case EventAttribute.FEventType of
      etRead : CheckExpected(TypeInfo(RParam), Method.ReturnType.Handle, 'Result');
      etTrigger :
        begin
          if Method.MethodKind <> TypInfo.mkFunction then
              raise ERegisterEventException.Create(Format(
              'TEntityComponent.SubscribeEvents: "%s.%s" is not a function!',
              [SelfType.QualifiedName, Method.Name]));
          CheckExpected(TypeInfo(boolean), Method.ReturnType.Handle, 'Result')
        end;
    end;
  end;

  procedure CheckParameterTypes;
  var
    Parameter : TRttiParameter;
  begin
    for Parameter in Parameters do
    begin
      CheckExpected(TypeInfo(RParam), Parameter.ParamType.Handle, 'Parameter "' + Parameter.Name + '"');
    end;
  end;

begin
  SelfType := FRttiContext.GetType(self.ClassType).AsInstance;
  // search for all event-methods
  for Method in SelfType.GetMethods do
    // skip all abstract and all methods from TObject
    if not(Method.IsAbstract or (Method.Parent.AsInstance.MetaclassType = TObject)) then
    begin
      if not Method.HasExtendedInfo then
          raise ERegisterEventException.Create('TEntityComponent.SubscribeEvents: No extended info was found for ' + Method.Name + ' in class ' + Method.Parent.AsInstance.MetaclassType.ClassName + '!')
      else
      { if not Method.HasExtendedInfo then
       noop; }
      begin
        Attributes := Method.GetAttributes;
        EventAttribute := XEvent(HRtti.SearchForAttribute(XEvent, Attributes));
        if assigned(EventAttribute) then
        begin
          // skip already subscribed events, because inheritance could cause twice event decleratiosn
          if not assigned(FSubscribedEvents[EventAttribute.FEvent, EventAttribute.FEventType]) then
          begin
            Parameters := Method.GetParameters;
            CheckResultType;
            CheckParameterTypes;
            VarParameters := [];
            for i := 0 to length(Parameters) - 1 do
              if pfVar in Parameters[i].Flags then VarParameters := VarParameters + [EnumParameterSlot(i)];
            TargetEventbus := HGeneric.TertOp<TEventbus>(EventAttribute.FEventScope = esLocal, FOwner.Eventbus, GlobalEventbus);
            SubscribeEvent(EventAttribute.FEvent, EventAttribute.FEventType, EventAttribute.FEventPriotity,
              Method.CodeAddress, length(Parameters), TargetEventbus);
          end;
        end
        else
          // Reminder removed because of inheritance - added, because inheritance fixed
          // has prefix On but no XEventattribute -> exception
          if AnsiUpperCase(copy(Method.Name, 1, 2)) = 'ON' then
              raise ERegisterEventException.Create('TEntityComponent.SubscribeEvents: Method "' + Method.Name + '" with prefix "On" found but no XEventAttribute!');
      end;
    end;
end;

procedure TEntityComponent.UnSubscribeEvents;
var
  ei : EnumEventIdentifier;
  et : EnumEventType;
  Event : TSubscribedEvent;
  i : integer;
begin
  for i := 0 to FRemoteSubscription.Count - 1 do
      FRemoteSubscription[i].FreeComponent;
  // subscribe local events
  for ei := low(EnumEventIdentifier) to high(EnumEventIdentifier) do
    for et := low(EnumEventType) to high(EnumEventType) do
      if assigned(FSubscribedEvents[ei, et]) then
      begin
        for Event in FSubscribedEvents[ei, et] do
            Event.TargetEventbus.Unsubscribe(Event.Eventname, Event.EventType, Event.EventPriority, self);
        FSubscribedEvents[ei, et].Free;
      end;
end;

{ TEntity }

constructor TEntity.Create(GlobalEventbus : TEventbus; ID : integer = 0);
begin
  FID := ID;
  FEventbus := TEventbus.Create(self);
  FGlobalEventbus := GlobalEventbus;
  FBlackboard := TBlackboard.Create(self);
{$IFDEF SERVER}FCurrentComponentID := low(integer); {$ENDIF}
{$IFDEF CLIENT}FCurrentComponentID := high(integer); {$ENDIF}
end;

class function TEntity.CreateFromScript(PatternFileName : string; GlobalEventbus : TEventbus) : TEntity;
begin
  Result := CreateFromScriptProc(PatternFileName, 'CreateEntity', GlobalEventbus);
end;

class function TEntity.CreateFromScriptProc(PatternFileName, ProcName : string;
  GlobalEventbus : TEventbus) : TEntity;
var
  EntityPattern : TScript;
  VarExist : boolean;
begin
  EntityPattern := ScriptManager.CompileScriptFromFile(FormatDateiPfad('scripts\' + PatternFileName + '.ets'));
  VarExist := EntityPattern.SetGlobalVariableValueIfExist<TEventbus>('GlobalEventbus', GlobalEventbus);
  assert(VarExist);
  Result := EntityPattern.ExecuteFunction(ProcName, [], TypeInfo(TEntity)).AsType<TEntity>;
  Result.ScriptFile := PatternFileName;
  EntityPattern.Free;
end;

class function TEntity.CreateMetaFromScript(PatternFileName : string; GlobalEventbus : TEventbus) : TEntity;
begin
  Result := CreateFromScriptProc(PatternFileName, 'CreateMeta', GlobalEventbus);
  Result.Meta := True;
end;

procedure TEntity.Deploy;
begin
  FGlobalEventbus.Trigger(eiNewEntity, [self]);
end;

class function TEntity.Deserialize(Stream : TStream; GlobalEventbus : TEventbus; ClassMap : TArray<REntityComponentClassMap>) : TEntity;
  function MapClass(AClass : TClass) : TClass;
  var
    i : integer;
  begin
    // default value no mapping found use class as is
    Result := AClass;
    for i := 0 to length(ClassMap) - 1 do
      if ClassMap[i].FromClass = AClass then exit(ClassMap[i].ToClass);
  end;

var
  QualifiedName : string;
  RttiContext : TRttiContext;
  RttiType : TRttiInstanceType;
  Field : TRttiField;
  Value : TValue;
  EntityComponent : TSerializableEntityComponent;
  Attributes : TArray<TCustomAttribute>;
  SerializeAttribute : XNetworkSerialize;
begin
  RttiContext := TRttiContext.Create;
  Result := TEntity.CreateFromScript(Stream.ReadString, GlobalEventbus);
  Stream.ReadData(Result.FID);
  Result.Blackboard.LoadFromStream(Stream);
  while Stream.Position < Stream.Size do
  begin
    QualifiedName := Stream.ReadString;
    RttiType := RttiContext.FindType(QualifiedName).AsInstance;
    if not assigned(RttiType) then raise Exception.Create('TEntity.DeSerialize: Can''t find typeinfo for type "' + QualifiedName + '"');
    assert(RttiType.MetaclassType.InheritsFrom(TSerializableEntityComponent));
    EntityComponent := CSerializableEntityComponent(MapClass(RttiType.MetaclassType)).Create(Result);
    EntityComponent.Deserialize(Stream);
    for Field in RttiType.GetFields do
    begin
      Attributes := Field.GetAttributes;
      SerializeAttribute := XNetworkSerialize(HRtti.SearchForAttribute(XNetworkSerialize, Attributes));
      if SerializeAttribute <> nil then
      begin
        Value := Field.GetValue(EntityComponent);
        Result.Eventbus.Write(SerializeAttribute.Event, [RParam.FromTValue(Value)]);
      end;
    end;
  end;
  RttiContext.Free;
end;

procedure TEntity.Serialize(Stream : TStream);
begin
  Stream.WriteString(FScriptFile);
  Stream.WriteData(FID);
  Blackboard.SaveToStream(Stream);
  Eventbus.Trigger(eiSerialize, [Stream]);
  GlobalEventbus.Trigger(eiEventFired, [RParam.From<EnumEventIdentifier>(eiSerialize), True]);
end;

destructor TEntity.Destroy;
begin
  FEventbus.Trigger(eiFree);
  FEventbus.Free;
  FBlackboard.Free;
  inherited;
end;

function TEntity.GetNewComponentID : integer;
begin
  Result := FCurrentComponentID;
{$IFDEF SERVER}inc(FCurrentComponentID); {$ENDIF}
{$IFDEF CLIENT}dec(FCurrentComponentID); {$ENDIF}
end;

{ TSerializableEntityComponent }

procedure TSerializableEntityComponent.Deserialize(Stream : TStream);
var
  RttiContext : TRttiContext;
  Field : TRttiField;
  RttiType : TRttiType;
  Value : TValue;
  RawData : TArray<Byte>;
  StringData : string;
  TypeSupported : boolean;
begin
  RttiContext := TRttiContext.Create;
  RttiType := GetBaseType(RttiContext.GetType(self.ClassType));
  if not assigned(RttiType) then
      raise Exception.Create('TSerializableEntityComponent.Deserialize: Can''t find typeinfo class "' + self.ClassName + '".');
  FUniqueID := Stream.ReadAny<integer>;
  FComponentGroup := Stream.ReadAny<SetComponentGroup>;
  for Field in RttiType.GetFields do
  begin
    // skip ihnerited class to prevent serializing unnecessary data (and prevent fatal behavior e.g. serialize FSubscribedEvents)
    if not((Field.Parent.Name = 'TObject') or (Field.Parent.Name = 'TEntityComponent')
      or (Field.Parent.Name = 'TEntityScriptComponent') or (Field.Parent.Name = 'TSerializableEntityComponent')) then
    begin
      if not assigned(Field.FieldType) then
          raise Exception.Create('TSerializableEntityComponent.Deserialize: Can''t find typeinfo for field "' + Field.Name + '" in class "' + self.ClassName + '".');
      TypeSupported := True;
      case Field.FieldType.TypeKind of
        // assume record no contains strings, otherwise this will maybe cause problems
        tkInteger, tkChar, tkFloat, tkEnumeration, tkSet, tkWChar, tkRecord, tkInt64 :
          begin
            setlength(RawData, Field.FieldType.TypeSize);
            Stream.ReadBuffer(RawData[0], Field.FieldType.TypeSize);
            TValue.Make(@RawData[0], Field.FieldType.Handle, Value);
          end;
        tkLString, tkWString, tkUString :
          begin
            StringData := Stream.ReadString;
            Value := StringData;
          end;
        tkClass :
          begin
            if Field.FieldType.AsInstance.MetaclassType = TTimer then
            begin
              if Stream.ReadAny<boolean> then
                  Value := TTimer.CreatePaused(Stream.ReadAny<int64>)
              else Value := TTimer.CreateAndStart(Stream.ReadAny<int64>);
              TTimer(Value.AsObject).SetZeitDiffProzent(Stream.ReadAny<Single>);
            end
            else TypeSupported := False;
          end
      else TypeSupported := False;
      end;
      if not TypeSupported then raise Exception.Create('TSerializableEntityComponent.Deserialize: Type "' + Field.FieldType.Name + '" from field "' + Field.Name + '" is currently not supported!');

      Field.SetValue(self, Value);
    end;
  end;
  RttiContext.Free;
end;

function TSerializableEntityComponent.GetBaseType(AType : TRttiType) : TRttiType;
var
  Attributes : TArray<TCustomAttribute>;
begin
  assert(AType.BaseType <> nil);
  // if no basetypetagging found, use type as is
  Result := AType;
  repeat
    Attributes := AType.GetAttributes;
    // if <> nil type contains attribute -> use them!
    if HRtti.SearchForAttribute(XNetworkBasetype, Attributes) <> nil then
    begin
      Result := AType;
      break;
    end
    // do not test type with no base type, bit tricky but useful, because only TObject has no basetype
    // and also don't need to be tested
    else AType := AType.BaseType;
  until AType.BaseType = nil;
end;

function TSerializableEntityComponent.Serialize(Stream : RParam) : boolean;
var
  RttiContext : TRttiContext;
  Field : TRttiField;
  RttiType : TRttiType;
  Value : TValue;
  StringData : string;
  TypeSupported : boolean;
  AStream : TStream;
begin
  AStream := Stream.AsType<TStream>;
  Result := True;
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(self.ClassType);
  if not assigned(RttiType) then
      raise Exception.Create('TSerializableEntityComponent.Serialize: Can''t find typeinfo class "' + self.ClassName + '".');
  RttiType := GetBaseType(RttiType);
  AStream.WriteString(RttiType.QualifiedName);
  // has to serialized manually because all fields from TEntityComponent will skipped
  AStream.WriteAny<integer>(FUniqueID);
  AStream.WriteAny<SetComponentGroup>(FComponentGroup);
  for Field in RttiType.GetFields do
  begin
    // skip ihnerited class to prevent serializing unnecessary data (and prevent fatal behavior e.g. serialize FSubscribedEvents)
    if not((Field.Parent.Name = 'TObject') or (Field.Parent.Name = 'TEntityComponent')
      or (Field.Parent.Name = 'TEntityScriptComponent') or (Field.Parent.Name = 'TSerializableEntityComponent')) then
    begin
      Value := Field.GetValue(self);
      if not assigned(Field.FieldType) then
          raise Exception.Create('TSerializableEntityComponent.Serialize: Can''t find typeinfo for field "' + Field.Name + '" in class "' + self.ClassName + '".');
      TypeSupported := True;
      case Field.FieldType.TypeKind of
        // assume record no contains strings, otherwise this will maybe cause problems
        tkInteger, tkChar, tkFloat, tkEnumeration, tkSet, tkWChar, tkRecord, tkInt64 :
          begin
            AStream.WriteBuffer(Value.GetReferenceToRawData^, Value.DataSize);
          end;
        tkLString, tkWString, tkUString :
          begin
            StringData := Value.AsString;
            AStream.WriteString(StringData);
          end;
        tkClass :
          begin
            if Field.FieldType.AsInstance.MetaclassType = TTimer then
            begin
              AStream.WriteAny<boolean>(TTimer(Value.AsObject).Paused);
              AStream.WriteAny<int64>(TTimer(Value.AsObject).Interval);
              AStream.WriteAny<Single>(TTimer(Value.AsObject).ZeitDiffProzent);
            end
            else TypeSupported := False;
          end
      else TypeSupported := False;
      end;
      if not TypeSupported then
          raise Exception.Create('TSerializableEntityComponent.Serialize: Type "' + Field.FieldType.Name + '" from field "' + Field.Name + '" is currently not supported!');
    end;
  end;
  RttiContext.Free;
end;

end.
