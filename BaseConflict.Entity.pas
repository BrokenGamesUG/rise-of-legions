unit BaseConflict.Entity;

interface

uses
  Math,
  Engine.Math,
  Generics.Defaults,
  Generics.Collections,
  RTTI,
  TypInfo,
  Engine.Helferlein.Threads,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  SysUtils,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  Engine.Script,
  Engine.Log,
  System.Classes,
  dwsComp,
  dwsExprs,
  dwsDataContext,
  dwsSymbols,
  dwsRttiExposer;

type

  ProcEventReadParam0 = function : RParam of object;
  ProcEventReadParam1 = function(var Param1 : RParam) : RParam of object;
  ProcEventReadParam2 = function(var Param1, Param2 : RParam) : RParam of object;
  ProcEventReadParam3 = function(var Param1, Param2, Param3 : RParam) : RParam of object;
  ProcEventReadParam4 = function(var Param1, Param2, Param3, Param4 : RParam) : RParam of object;
  ProcEventReadParam5 = function(var Param1, Param2, Param3, Param4, Param5 : RParam) : RParam of object;
  ProcEventReadParam6 = function(var Param1, Param2, Param3, Param4, Param5, Param6 : RParam) : RParam of object;

  ProcEventTriggerParam0 = function : boolean of object;
  ProcEventTriggerParam1 = function(var Param1 : RParam) : boolean of object;
  ProcEventTriggerParam2 = function(var Param1, Param2 : RParam) : boolean of object;
  ProcEventTriggerParam3 = function(var Param1, Param2, Param3 : RParam) : boolean of object;
  ProcEventTriggerParam4 = function(var Param1, Param2, Param3, Param4 : RParam) : boolean of object;
  ProcEventTriggerParam5 = function(var Param1, Param2, Param3, Param4, Param5 : RParam) : boolean of object;
  ProcEventTriggerParam6 = function(var Param1, Param2, Param3, Param4, Param5, Param6 : RParam) : boolean of object;

  ERegisterEventException = class(Exception);
  EHandleEventException = class(Exception);

  REntityComponentClassMap = record
    FromClass : TClass;
    ToClass : TClass;
  end;

  EnumParameterSlot = (psSlot0, psSlot1, psSlot2, psSlot3, psSlot4);

  SetVarParameter = set of EnumParameterSlot;

  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic]) FIELDS([vcPublic, vcProtected])}
  {$TYPEINFO ON}
  TEntityComponent = class;
  {$TYPEINFO OFF}
  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic]) FIELDS([vcPublic, vcProtected])}
  TEntity = class;

  EnumEventPriority = (epFirst, epHigher, epHigh, epMiddle, epLow, epLower, epLast);
  EnumEventScope = (esLocal, esGlobal);
  EnumEventType = (etRead, etTrigger, etWrite);

  REventSpecification = record
    Event : EnumEventIdentifier;
    EventPriotity : EnumEventPriority;
    EventType : EnumEventType;
    EventScope : EnumEventScope;
    constructor Create(Event : EnumEventIdentifier; EventPriotity : EnumEventPriority; EventType : EnumEventType; EventScope : EnumEventScope);
  end;

  XEvent = class(TCustomAttribute)
    private
      FEventSpecification : REventSpecification;
    public
      constructor Create(Event : EnumEventIdentifier; EventPriotity : EnumEventPriority; EventType : EnumEventType; EventScope : EnumEventScope = esLocal);
  end;

  XNetworkSerialize = class(TCustomAttribute)
    private
      FEvent : EnumEventIdentifier;
    public
      property Event : EnumEventIdentifier read FEvent;
      constructor Create(Event : EnumEventIdentifier);
  end;

  XNetworkBasetype = class(TCustomAttribute);

  ENoSubscriberForRead = class(Exception);

  {$RTTI EXPLICIT METHODS([]) FIELDS([])}
  SetComponentGroup = set of Byte;

  /// <summary> Holds a value for every event. Entitylocal pool of values. Will be serialized between
  /// Server and Client </summary>
  TBlackboard = class
    private
      function GetValueRaw(Event : EnumEventIdentifier; GroupIndex, Index : integer) : RParam; inline;
      procedure SetValueRaw(Event : EnumEventIdentifier; GroupIndex, Index : integer; const Value : RParam); inline;
    protected
      FOwner : TEntity;
      // Values for [Event][GroupIndex][SubIndex]
      FValues : array [EnumEventIdentifier] of array of array of RParam;
      procedure SaveToStream(Stream : TStream);
      procedure LoadFromStream(Stream : TStream);
    public
      constructor Create(Owner : TEntity);
      procedure SetIndexedValue(Event : EnumEventIdentifier; const Group : SetComponentGroup; Index : integer; const Value : RParam);
      /// <summary> The global group has index -1. Other indices as usual. If value is not present returns RPARAMEMPTY. </summary>
      function GetIndexedValue(Event : EnumEventIdentifier; const Group : SetComponentGroup; Index : integer) : RParam;
      procedure SetValue(Event : EnumEventIdentifier; const Group : SetComponentGroup; const Value : RParam);
      function GetValue(Event : EnumEventIdentifier; const Group : SetComponentGroup) : RParam; inline;
      function GetIndexMap(Event : EnumEventIdentifier; const Group : SetComponentGroup) : TDictionary<integer, RParam>;
      procedure DeleteValues(const Group : SetComponentGroup);
  end;

  TEventbus = class;

  TRemoteSubscription = class(TObject)
    protected
      FTargetEventbus : TEventbus;
      FTargetComponent : TEntityComponent;
      FComponentFreed : boolean;
      FEventbusFreed : boolean;
      FEvent : EnumEventIdentifier;
      FEventType : EnumEventType;
      FEventPriotity : EnumEventPriority;
      FRefCounter : integer;
      procedure DecRefCounter;
    public
      constructor Create(TargetComponent : TEntityComponent; TargetEventbus : TEventbus; Event : EnumEventIdentifier; EventType : EnumEventType; EventPriority : EnumEventPriority);
      procedure FreeComponent;
      procedure FreeEventbus;
      destructor Destroy; override;
  end;

  TEventbus = class
    protected
      type
      PSubscriber = ^RSubscriber;

      RSubscriber = record
        EntityComponent : TEntityComponent;
        Priority : EnumEventPriority;
        constructor Create(EntityComponent : TEntityComponent; Priority : EnumEventPriority);
      end;

    type
      TEventhandler = class;

      TEventEnumerator = class
        strict private
          FOwner : TEventhandler;
        private
          FCurrentlyActive : boolean;
          FActiveIndex : integer;
        public
          constructor Create(Owner : TEventhandler);
          function CurrentSubscriber : RSubscriber; inline;
          function HasNext : boolean; inline;
          procedure Increment; inline;
          procedure Decrement; inline;
          procedure BeginEvent; inline;
          procedure EndEvent; inline;
      end;

      TEventhandler = class
        strict private
          ParameterCount : integer;
          FEnumerators : TObjectList<TEventEnumerator>;
          FEnumeratorIndex : Byte;
        private
          Subscribers : TList<RSubscriber>;
        public
          constructor Create(ParameterCount : integer);
          procedure AddSubscriber(const Subscriber : RSubscriber);
          procedure RemoveSubscriber(const Subscriber : RSubscriber);
          function GetEnumerator : TEventEnumerator; inline;
          procedure ReleaseEnumerator; inline;
          destructor Destroy; override;
      end;

    var
      FOwner : TEntity;
      FEventhandler : array [EnumEventIdentifier] of array [EnumEventType] of TEventhandler;
      FRemoteSubscriptions : TList<TRemoteSubscription>;
      procedure StartEvent(Event : EnumEventIdentifier; const Group : SetComponentGroup); inline;
      procedure EndEvent; inline;
    public
      property Owner : TEntity read FOwner;
      constructor Create(Owner : TEntity);
      /// <summary> Reads a value in the local group and if empty is returned, read in the global group. </summary>
      function ReadHierarchic(Eventname : EnumEventIdentifier; const Values : TArray<RParam>; const Group : SetComponentGroup) : RParam;
      function Read(Eventname : EnumEventIdentifier; Parameters : array of RParam; const Group : SetComponentGroup = []; ComponentID : integer = 0) : RParam;
      procedure Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; const Group : SetComponentGroup = []; ComponentID : integer = 0; Write : boolean = False);
      procedure InvokeWithRawData(Eventname : EnumEventIdentifier; const Group : SetComponentGroup; ComponentID : integer; const ValuesAsRawData : TArray<Byte>; WriteEvent : boolean);
      procedure Write(Eventname : EnumEventIdentifier; const Values : array of RParam; const Group : SetComponentGroup = []; ComponentID : integer = 0);
      procedure Subscribe(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityCompononent : TEntityComponent; ParameterCount : integer);
      /// <summary> Subscribe one remote eventbus and return class to manage subscription.</summary>
      procedure SubscribeRemote(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityCompononent : TEntityComponent; const MethodName : string; ParameterCount : integer; NetworkSender : EnumNetworkSender = nsNone);
      procedure Unsubscribe(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityComponent : TEntityComponent);
      destructor Destroy; override;
  end;

  ProcEnumerateEntityComponentCallback = reference to procedure(Component : TEntityComponent);

  TEntityComponent = class
    private
      type
      RSubscriptionPattern = record
        EventSpecification : REventSpecification;
        EventHandler : Pointer;
        ParameterLength : integer;
        constructor Create(const EventSpecification : REventSpecification; EventHandler : Pointer; ParameterLength : integer);
      end;

      TSubscribedEvent = class
        private
          Eventname : EnumEventIdentifier;
          EventType : EnumEventType;
          EventPriority : EnumEventPriority;
          EventHandler : Pointer;
          ParameterCount : integer;
          TargetEventbus : TEventbus;
        public
          constructor Create(Eventname : EnumEventIdentifier; EventHandler : Pointer; ParameterCount : integer; TargetEventbus : TEventbus; EventPriority : EnumEventPriority; EventType : EnumEventType);
      end;
    strict private
  [ScriptExcludeMember]
      FComponentGroup : SetComponentGroup;
      class var FComponentSubscriptionPatterns : TThreadSafeObjectDictionary<TClass, TList<RSubscriptionPattern>>;
    private
      FRttiContext : TRttiContext;
      FSubscribedEvents : array [EnumEventIdentifier] of array [EnumEventType] of TObjectList<TSubscribedEvent>;
      FRemoteSubscription : TList<TRemoteSubscription>;
      function LookUpSubscribedEvent(Caller : TEventbus; ei : EnumEventIdentifier; et : EnumEventType) : TSubscribedEvent;
      procedure DeploySubscribedEvent(Event : TSubscribedEvent);
      procedure DeleteSubscribedEvent(Event : TSubscribedEvent);
      procedure ExtractSubscribedEvent(Event : TSubscribedEvent);
      function OnRead(Caller : TEventbus; Event : EnumEventIdentifier; var Parameters : array of RParam; var ResultFromAncestor : RParam) : RParam;
      function OnTrigger(Caller : TEventbus; Event : EnumEventIdentifier; var Parameters : array of RParam; Write : boolean) : boolean; virtual;
      /// <summary> Look for published methods with an XEvent-Attribute and subscribe them to their events. If more than one XEvent
      /// attribute is present, the first one will be chosen and the rest will be dropped. </summary>
      procedure SubscribeEvents; virtual;
      procedure SubscribeEvent(Event : EnumEventIdentifier; EventType : EnumEventType; EventPriority : EnumEventPriority; EventHandler : Pointer; ParameterCount : integer; TargetEventbus : TEventbus);
      procedure UnSubscribeEvents; virtual;
      procedure SetSetComponentGroup(const Value : SetComponentGroup);
      procedure RegisterInOwner;
      procedure DeregisterInOwner;
    protected
      FOwner : TEntity;
      /// <summary> Unique ID for component related to owner entity NOT global. </summary>
      FUniqueID : integer;
      // Eventbus of the Owner
      function Eventbus : TEventbus;
      function GlobalEventbus : TEventbus;
      function BuildExceptionMessage(const ExceptionMessage : string) : string; overload;
      function BuildExceptionMessage(const ExceptionMessage : string; const FormatParameters : array of const) : string; overload;
      procedure MakeException(const ExceptionMessage : string); overload;
      procedure MakeException(const ExceptionMessage : string; const FormatParameters : array of const); overload;
      procedure ComponentFree; virtual;
      procedure BeforeComponentFree; virtual;
      procedure EnumerateComponents(Callback : ProcEnumerateEntityComponentCallback); virtual;
      /// <summary> Use to free component in an event stack. </summary>
      procedure DeferFree;
      /// <summary> Returns whether the caller belongs to my own group. Prevents execution of groupless events in local groups. </summary>
      function IsLocalCall : boolean; overload;
      function IsLocalCall(const TargetGroup : SetComponentGroup) : boolean; overload;
    published
      [XEvent(eiEnumerateComponents, epLast, etTrigger)]
      function OnEnumerate(const Callback : RParam) : boolean;
      [XEvent(eiBeforeFree, epLast, etTrigger)]
      function OnBeforeComponentFree() : boolean;
      [XEvent(eiFree, epLast, etTrigger)]
      function OnComponentFree() : boolean;
    public
      property Owner : TEntity read FOwner;
      property UniqueID : integer read FUniqueID;
      [ScriptExcludeMember]
      property ComponentGroup : SetComponentGroup read FComponentGroup write SetSetComponentGroup;

      /// <summary> Shortcut to read resource reCardLevel. </summary>
      function CardLevel() : integer;
      /// <summary> Shortcut to read resource reCardLeague. </summary>
      function CardLeague() : integer;

      constructor Create(Owner : TEntity); virtual;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<Byte>); virtual;
      constructor CreateGroupedAll(Owner : TEntity); virtual;
      procedure ChangeEventPriority(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; Scope : EnumEventScope = esLocal);
      destructor Destroy; override;

      class constructor Create;
      class destructor Destroy;
  end;

  CEntityComponent = class of TEntityComponent;

  {$RTTI INHERIT}

  TSerializableEntityComponent = class(TEntityComponent)
    protected
      function GetBaseType(AType : TRttiType) : TRttiType;
    public
      /// <summary> Load all data with Rtti from stream. Only called on clients</summary>
      [ScriptExcludeMember]
      procedure Deserialize(Stream : TStream);
    published
      /// <summary> save all data with Rtti to stream. Only called on server</summary>
      [ScriptExcludeMember]
      [XEvent(eiSerialize, epLast, etTrigger)]
      function Serialize(const Stream : RParam) : boolean;
  end;

  CSerializableEntityComponent = class of TSerializableEntityComponent;

  ProcEntityInitializer = reference to procedure(Entity : TEntity);

  TEntity = class
    strict private
      FCollisionRadius : single;
      FPosition, FFront : RVector2;
      {$IFDEF CLIENT}
      FDisplayPosition, FDisplayFront, FDisplayUp : RVector3;
      {$ENDIF}
      procedure SetFront(const Value : RVector2);
      procedure SetPosition(const Value : RVector2);
      class function CreateFromScriptProc(const PatternFileName, ProcName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer = nil; IsMeta : boolean = False; FileNameOverride : string = '') : TEntity; static;
    protected
      const
      RESERVED_GROUPS = 20; // reserve the first n groups, so the user can hardcode something
    var
      FEventbus : TEventbus;
      FGlobalEventbus : TEventbus;
      FBlackboard : TBlackboard;
      FAbstract : boolean;
      FID : integer;
      FCreatedTimestamp : int64;
      FScriptFile, FUID, FSkinID : string;
      FCurrentComponentID : integer;
      // Count of entity components in each group. If 0 group is free to use, if <0 group is reserved by someone
      FGroupsInUse : TList<integer>;
      function GetID : integer;
      function GetNewComponentID : integer;
      procedure RegisterComponent(EntityComponent : TEntityComponent);
      procedure DeregisterComponent(EntityComponent : TEntityComponent);
    public
      property ID : integer read GetID write FID;
      property UID : string read FUID write FUID;
      property ScriptFile : string read FScriptFile write FScriptFile;
      /// <summary> Same as ScriptFile, but without file path and extension. </summary>
      function ScriptFileName : string;
      /// <summary>The local eventbus of this entity.</summary>
      property Eventbus : TEventbus read FEventbus;
      property Blackboard : TBlackboard read FBlackboard;
      property GlobalEventbus : TEventbus read FGlobalEventbus;
      /// <summary> Determines whether entity is a final entity in world or only abstract. </summary>
      property IsAbstract : boolean read FAbstract write FAbstract;
      property CreatedTimestamp : int64 read FCreatedTimestamp;

      property SkinID : string read FSkinID write FSkinID;
      function SkinFileSuffix : string;
      function HasSkin : boolean;
      [ScriptExcludeMember]
      function GetSkinID(const ComponentGroup : SetComponentGroup) : string;
      [ScriptExcludeMember]
      function GetSkinFileSuffix(const ComponentGroup : SetComponentGroup) : string;

      [ScriptExcludeMember]
      property Position : RVector2 read FPosition write SetPosition;
      [ScriptExcludeMember]
      property Front : RVector2 read FFront write SetFront;
      {$IFDEF CLIENT}
      [ScriptExcludeMember]
      property DisplayPosition : RVector3 read FDisplayPosition write FDisplayPosition;
      [ScriptExcludeMember]
      property DisplayFront : RVector3 read FDisplayFront write FDisplayFront;
      [ScriptExcludeMember]
      property DisplayUp : RVector3 read FDisplayUp write FDisplayUp;
      {$ENDIF}
      property CollisionRadius : single read FCollisionRadius write FCollisionRadius;

      /// <summary>Creates the entity. Now components can be added.</summary>
      constructor Create(GlobalEventbus : TEventbus; ID : integer = 0);
      class function CreateFromScript(const PatternFileName : string; GlobalEventbus : TEventbus) : TEntity; overload; static;
      [ScriptExcludeMember]
      class function CreateFromScript(const PatternFileName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer) : TEntity; overload; static;
      [ScriptExcludeMember]
      class function CreateMetaFromScript(const PatternFileName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer) : TEntity; static;
      [ScriptExcludeMember]
      class function CreateDataFromScript(const PatternFileName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer) : TEntity; static;
      [ScriptExcludeMember]
      procedure ApplyScript(ScriptFileName : string; ProcName : string = ''; Parameters : TArray<TValue> = nil);
      [ScriptExcludeMember]
      function ApplyScriptReturnGroups(const ScriptFileName : string; const ProcName : string = '') : SetComponentGroup;
      /// <summary> Reserves a unused group for further usage. The first component placed in this group will free
      /// the reserved state. So if killed the group is free for next use. </summary>
      function ReserveFreeGroup : Byte;
      /// <summary> Release all content of the groups and unreserves them. </summary>
      [ScriptExcludeMember]
      procedure FreeGroups(const Groups : SetComponentGroup);
      /// <summary>Registers the entity in the game. Should be called after adding the components.</summary>
      procedure Deploy;
      [ScriptExcludeMember]
      procedure Serialize(Stream : TStream);
      /// <summary> Creates an entity with the serialized components. Won't be deployed. </summary>
      [ScriptExcludeMember]
      class function Deserialize(EntityID : integer; Stream : TStream; GlobalEventbus : TEventbus; const ClassMap : TArray<REntityComponentClassMap>) : TEntity; static;

      [ScriptExcludeMember]
      /// <summary> Shortcut to read unit properties from eventbus. </summary>
      function UnitProperties : SetUnitProperty; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read unit data from blackboads. </summary>
      function UnitData(const DataType : EnumUnitData) : RParam; inline;
      /// <summary> Shortcut to read resource balance from eventbus. </summary>
      function BalanceInt(const ResourceType : EnumResource) : integer; overload; inline;
      /// <summary> Shortcut to read resource balance from eventbus. </summary>
      function BalanceSingle(const ResourceType : EnumResource) : single; overload; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read resource balance from eventbus. </summary>
      function Balance(const ResourceType : EnumResource) : RParam; overload; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read resource balance from eventbus. </summary>
      function Balance(const ResourceType : EnumResource; const Group : SetComponentGroup) : RParam; overload; inline;
      /// <summary> Shortcut to read resource cap from eventbus. </summary>
      function CapSingle(const ResourceType : EnumResource) : single; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read resource cap from eventbus. </summary>
      function Cap(const ResourceType : EnumResource) : RParam; overload; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read resource cap from eventbus. </summary>
      function Cap(const ResourceType : EnumResource; const Group : SetComponentGroup) : RParam; overload; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read resource fill percentage from eventbus. </summary>
      function ResFill(const ResourceType : EnumResource) : single; overload; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read resource fill percentage from eventbus. </summary>
      function ResFill(const ResourceType : EnumResource; const Group : SetComponentGroup) : single; overload; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read teamid from eventbus. </summary>
      function TeamID() : integer; inline;
      [ScriptExcludeMember]
      /// <summary> Shortcut to read owner commander id from eventbus. </summary>
      function CommanderID() : integer; inline;
      [ScriptExcludeMember]
      function OwningCommander : TEntity;

      /// <summary> Returns whether this unit has this property or not. </summary>
      function HasUnitProperty(UnitProperty : EnumUnitProperty) : boolean;
      /// <summary> Returns whether the main weapon of this unit has this type or not. </summary>
      function HasDamageType(DamageType : EnumDamageType) : boolean;
      /// <summary> Shortcut to read coloridentity from eventbus. </summary>
      function ColorIdentity() : integer; overload;
      function ColorIdentity(Group : TArray<Byte>) : integer; overload;
      /// <summary> Shortcut to read collisionradius from eventbus. </summary>
      function ReadCollisionRadius(Group : TArray<Byte>) : single; overload;
      /// <summary> Shortcut to read resource reCardLevel. </summary>
      function CardLevel() : integer; overload;
      function CardLevel(Group : Byte) : integer; overload;
      function CardLevel(Group : TArray<Byte>) : integer; overload;
      /// <summary> Shortcut to read resource reCardLeague. </summary>
      function CardLeague() : integer; overload;
      function CardLeague(Group : Byte) : integer; overload;
      function CardLeague(Group : TArray<Byte>) : integer; overload;

      /// <summary> Adds the groups to be removed by the entity manager. </summary>
      procedure RemoveGroups(const Groups : TArray<Byte>);

      procedure DeferFree;
      destructor Destroy; override;
  end;

  REventInformation = record
    EventIdentifier : EnumEventIdentifier;
    CalledToGroup : SetComponentGroup;
  end;

function ByteArrayToComponentGroup(const inArray : TArray<Byte>) : SetComponentGroup;
function IntArrayToComponentGroup(const inArray : TArray<integer>) : SetComponentGroup;
function ComponentGroupToByteArray(const inSet : SetComponentGroup) : TArray<Byte>;

const
  ALLGROUP_INDEX : Byte        = 255;
  ALLGROUP : SetComponentGroup = [255];

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

threadvar
/// <summary> Holds information about the currently executing event. </summary>
  CurrentEvent : REventInformation;
threadvar
  Eventstack : TFastStack<REventInformation>;

implementation

uses
  BaseConflict.Globals,
  BaseConflict.Game,
  BaseConflict.Classes.Shared,
  BaseConflict.EntityComponents.Shared;

{ TEntity }

function TEntity.Cap(const ResourceType : EnumResource) : RParam;
begin
  Result := Eventbus.Read(eiResourceCap, [ord(ResourceType)]);
end;

function TEntity.CardLeague : integer;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(reCardLeague)]).AsInteger;
end;

function TEntity.CardLeague(Group : Byte) : integer;
begin
  Result := Eventbus.ReadHierarchic(eiResourceBalance, [ord(reCardLeague)], [Group]).AsInteger;
end;

function TEntity.Cap(const ResourceType : EnumResource; const Group : SetComponentGroup) : RParam;
begin
  Result := Eventbus.ReadHierarchic(eiResourceCap, [ord(ResourceType)], Group);
end;

function TEntity.CapSingle(const ResourceType: EnumResource): single;
begin
  result := Cap(ResourceType).AsSingle;
end;

function TEntity.CardLeague(Group : TArray<Byte>) : integer;
begin
  Result := Eventbus.ReadHierarchic(eiResourceBalance, [ord(reCardLeague)], ByteArrayToComponentGroup(Group)).AsInteger;
end;

function TEntity.CardLevel(Group : Byte) : integer;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(reCardLevel)], [Group]).AsInteger;
end;

function TEntity.CardLevel(Group : TArray<Byte>) : integer;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(reCardLevel)], ByteArrayToComponentGroup(Group)).AsInteger;
end;

function TEntity.CardLevel : integer;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(reCardLevel)]).AsInteger;
end;

function TEntity.ColorIdentity : integer;
begin
  Result := ord(Eventbus.Read(eiColorIdentity, []).AsEnumType<EnumEntityColor>);
end;

function TEntity.ReadCollisionRadius(Group : TArray<Byte>) : single;
begin
  Result := Eventbus.Read(eiCollisionRadius, [], ByteArrayToComponentGroup(Group)).AsSingle;
end;

function TEntity.ColorIdentity(Group : TArray<Byte>) : integer;
begin
  Result := ord(Eventbus.Read(eiColorIdentity, [], ByteArrayToComponentGroup(Group)).AsEnumType<EnumEntityColor>);
end;

function TEntity.CommanderID : integer;
begin
  Result := Eventbus.Read(eiOwnerCommander, []).AsInteger;
end;

constructor TEntity.Create(GlobalEventbus : TEventbus; ID : integer = 0);
begin
  FID := ID;
  FEventbus := TEventbus.Create(self);
  FGlobalEventbus := GlobalEventbus;
  FBlackboard := TBlackboard.Create(self);
  FGroupsInUse := TList<integer>.Create;
  FCreatedTimestamp := TimeManager.GetTimeStamp;
  {$IFDEF SERVER}FCurrentComponentID := low(integer); {$ENDIF}
  {$IFDEF CLIENT}FCurrentComponentID := high(integer); {$ENDIF}
  TResourceManagerComponent.CreateGroupedAll(self);
end;

class function TEntity.CreateDataFromScript(const PatternFileName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer) : TEntity;
begin
  Result := CreateFromScriptProc(PatternFileName, 'CreateData', GlobalEventbus, Initializer, True);
end;

class function TEntity.CreateFromScript(const PatternFileName : string; GlobalEventbus : TEventbus) : TEntity;
begin
  Result := CreateFromScript(PatternFileName, GlobalEventbus, nil);
end;

class function TEntity.CreateFromScript(const PatternFileName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer) : TEntity;
begin
  Result := CreateFromScriptProc(PatternFileName, 'CreateEntity', GlobalEventbus, Initializer);
end;

class function TEntity.CreateFromScriptProc(const PatternFileName, ProcName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer; IsMeta : boolean; FileNameOverride : string) : TEntity;
var
  EntityPattern : TScript;
  ScriptFilePath, ParentScriptFilePath, FinalScriptFilename : string;
begin
  if FileNameOverride = '' then FinalScriptFilename := PatternFileName
  else FinalScriptFilename := FileNameOverride;

  ScriptFilePath := AbsolutePath('scripts\' + PatternFileName);
  if ExtractFileExt(ScriptFilePath) = '' then ScriptFilePath := ScriptFilePath + FILE_EXTENSION_ENTITY;
  EntityPattern := ScriptManager.CompileScriptFromFile(ScriptFilePath); // checks file exist
  EntityPattern.RunMain; // init global variables of the script
  EntityPattern.SetGlobalVariableValueIfExist<TEventbus>('GlobalEventbus', GlobalEventbus);
  EntityPattern.SetGlobalVariableValueIfExist<TGame>('Game', Game);
  // if script file inherits from another script, initialize the entity with that file and afterwards
  // run our script over this entity
  if EntityPattern.TryGetGlobalVariableValue<string>(SCRIPT_INHERIT_VAR_NAME, ParentScriptFilePath) then
  begin
    Result := TEntity.CreateFromScriptProc(ParentScriptFilePath, ProcName, GlobalEventbus, Initializer, IsMeta, FinalScriptFilename);
  end
  else
    if EntityPattern.TryGetGlobalVariableValue<string>(SCRIPT_INHERIT_PRECEDING_VAR_NAME, ParentScriptFilePath) then
  begin
    Result := TEntity.CreateFromScriptProc(ParentScriptFilePath, ProcName, GlobalEventbus,
      procedure(Entity : TEntity)
      begin
        if assigned(Initializer) then Initializer(Entity);
        EntityPattern.ExecuteFunction(ProcName, [TValue.From<TEntity>(Entity)], nil);
      end,
      IsMeta, FinalScriptFilename);
    Result.ScriptFile := FinalScriptFilename;
    EntityPattern.Free;
    exit;
  end
  else
  begin
    // only base script file runs initilization methods
    Result := TEntity.Create(GlobalEventbus, 0);
    Result.IsAbstract := IsMeta;
    if assigned(Initializer) then Initializer(Result);
  end;
  Result.ScriptFile := FinalScriptFilename;
  EntityPattern.ExecuteFunction(ProcName, [TValue.From<TEntity>(Result)], nil);
  EntityPattern.Free;
end;

procedure TEntity.ApplyScript(ScriptFileName : string; ProcName : string; Parameters : TArray<TValue>);
var
  Script : TScript;
begin
  if ProcName = '' then ProcName := 'Apply';
  if not HFilepathManager.IsAbsolute(ScriptFileName) and not ScriptFileName.StartsWith(PATH_SCRIPT) then ScriptFileName := PATH_SCRIPT + ScriptFileName;
  Script := ScriptManager.CompileScriptFromFile(AbsolutePath(ScriptFileName));
  Script.RunMain; // init global variables of the script
  Script.SetGlobalVariableValueIfExist<TEventbus>('GlobalEventbus', GlobalEventbus);
  Script.SetGlobalVariableValueIfExist<TGame>('Game', Game);
  if assigned(Parameters) then Script.ExecuteFunction(ProcName, Parameters, nil)
  else
      Script.ExecuteFunction(ProcName, [TValue.From<TEntity>(self)], nil);
  Script.Free;
end;

function TEntity.ApplyScriptReturnGroups(const ScriptFileName, ProcName : string) : SetComponentGroup;
var
  finalProcName : string;
  Script : TScript;
  ReturnValue : TValue;
  arr : TArray<integer>;
  barr : TArray<Byte>;
begin
  if ProcName = '' then finalProcName := 'Apply'
  else finalProcName := ProcName;
  Script := ScriptManager.CompileScriptFromFile(FormatDateiPfad('scripts\' + ScriptFileName));
  Script.RunMain; // init global variables of the script
  Script.SetGlobalVariableValueIfExist<TEventbus>('GlobalEventbus', GlobalEventbus);
  Script.SetGlobalVariableValueIfExist<TGame>('Game', Game);
  ReturnValue := Script.ExecuteFunction(finalProcName, [TValue.From<TEntity>(self)], TypeInfo(TArray<integer>));
  if ReturnValue.IsEmpty or not ReturnValue.IsArray then
      Result := []
  else
  begin
    arr := ReturnValue.AsType<TArray<integer>>;
    barr := HArray.Map<integer, Byte>(arr,
      function(const int : integer) : Byte
      begin
        Result := int;
      end);
    Result := ByteArrayToComponentGroup(barr);
  end;
  Script.Free;
end;

function TEntity.Balance(const ResourceType : EnumResource; const Group : SetComponentGroup) : RParam;
begin
  Result := Eventbus.ReadHierarchic(eiResourceBalance, [ord(ResourceType)], Group);
end;

function TEntity.BalanceInt(const ResourceType : EnumResource) : integer;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(ResourceType)]).AsInteger;
end;

function TEntity.BalanceSingle(const ResourceType : EnumResource) : single;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(ResourceType)]).AsSingle;
end;

function TEntity.Balance(const ResourceType : EnumResource) : RParam;
begin
  Result := Eventbus.Read(eiResourceBalance, [ord(ResourceType)]);
end;

class function TEntity.CreateMetaFromScript(const PatternFileName : string; GlobalEventbus : TEventbus; const Initializer : ProcEntityInitializer) : TEntity;
begin
  Result := CreateFromScriptProc(PatternFileName, 'CreateMeta', GlobalEventbus, Initializer, True);
end;

procedure TEntity.DeferFree;
begin
  if assigned(Game) and assigned(Game.EntityManager) then
      Game.EntityManager.FreeEntity(self)
  else
      self.Free;
end;

procedure TEntity.Deploy;
begin
  FGlobalEventbus.Trigger(eiNewEntity, [self]);
  Eventbus.Trigger(eiDeploy, []);
end;

class function TEntity.Deserialize(EntityID : integer; Stream : TStream; GlobalEventbus : TEventbus; const ClassMap : TArray<REntityComponentClassMap>) : TEntity;
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
  QualifiedName, ScriptFile, SkinID, UID : string;
  RttiContext : TRttiContext;
  RttiType : TRttiInstanceType;
  Field : TRttiField;
  Value : TValue;
  EntityComponent : TSerializableEntityComponent;
  Attributes : TArray<TCustomAttribute>;
  SerializeAttribute : XNetworkSerialize;
  BlackboardStreamPosition : int64;
begin
  RttiContext := TRttiContext.Create;
  ScriptFile := Stream.ReadString;
  SkinID := Stream.ReadString;
  UID := Stream.ReadString;
  BlackboardStreamPosition := Stream.Position;
  Result := TEntity.CreateFromScript(
    ScriptFile,
    GlobalEventbus,
    procedure(Entity : TEntity)
    begin
      Entity.SkinID := SkinID;
      // init all values set by the server to the entity, so all components have access to them
      Entity.Blackboard.LoadFromStream(Stream);
    end);
  // now override all values already overwritten by the server, but set by the creation script
  Stream.Position := BlackboardStreamPosition;
  Result.Blackboard.LoadFromStream(Stream);
  Result.FID := EntityID;
  Result.UID := UID;
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

function TEntity.ScriptFileName : string;
begin
  Result := ChangeFileExt(ExtractFileName(ScriptFile), '');
end;

procedure TEntity.Serialize(Stream : TStream);
begin
  Stream.WriteData(FID);
  Stream.WriteString(FScriptFile);
  Stream.WriteString(FSkinID);
  Stream.WriteString(FUID);
  Blackboard.SaveToStream(Stream);
  Eventbus.Trigger(eiSerialize, [Stream]);
end;

procedure TEntity.SetFront(const Value : RVector2);
begin
  FFront := Value;
  Eventbus.Write(eiFront, [Value]);
end;

procedure TEntity.SetPosition(const Value : RVector2);
begin
  FPosition := Value;
  Eventbus.Write(eiPosition, [Value]);
end;

function TEntity.SkinFileSuffix : string;
begin
  if HasSkin then
      Result := '_' + FSkinID
  else
      Result := '';
end;

function TEntity.TeamID : integer;
begin
  Result := Eventbus.Read(eiTeamID, []).AsInteger;
end;

function TEntity.UnitData(const DataType : EnumUnitData) : RParam;
begin
  Result := Blackboard.GetIndexedValue(eiUnitData, [], ord(DataType));
end;

function TEntity.UnitProperties : SetUnitProperty;
begin
  Result := Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

destructor TEntity.Destroy;
begin
  FEventbus.Trigger(eiBeforeFree, []);
  FEventbus.Trigger(eiFree, []);
  FEventbus.Free;
  FBlackboard.Free;
  FGroupsInUse.Free;
  inherited;
end;

procedure TEntity.FreeGroups(const Groups : SetComponentGroup);
var
  i : integer;
  cg : SetComponentGroup;
begin
  Eventbus.Trigger(eiBeforeFree, [], Groups);
  Eventbus.Trigger(eiFree, [], Groups);
  Blackboard.DeleteValues(Groups);
  cg := Groups;
  for i in Groups do
  begin
    if FGroupsInUse.Count > i then
    begin
      assert(FGroupsInUse[i] <= 0, 'TEntity.FreeGroups: Some components seems to ignore to call to free them. After freeing a group it is still in use.');
      FGroupsInUse[i] := 0;
    end;
  end;
end;

function TEntity.GetID : integer;
begin
  if assigned(self) then Result := FID
  else Result := -1;
end;

function TEntity.GetNewComponentID : integer;
begin
  Result := FCurrentComponentID;
  {$IFDEF SERVER}inc(FCurrentComponentID); {$ENDIF}
  {$IFDEF CLIENT}dec(FCurrentComponentID); {$ENDIF}
end;

function TEntity.GetSkinFileSuffix(const ComponentGroup : SetComponentGroup) : string;
begin
  Result := GetSkinID(ComponentGroup);
  if Result <> '' then
      Result := '_' + Result;
end;

function TEntity.GetSkinID(const ComponentGroup : SetComponentGroup) : string;
begin
  Result := Eventbus.ReadHierarchic(eiSkinIdentifier, [], ComponentGroup).AsString;
  if Result = '' then
      Result := SkinID;
end;

function TEntity.HasDamageType(DamageType : EnumDamageType) : boolean;
begin
  Result := DamageType in Eventbus.Read(eiDamageType, [], [GROUP_MAINWEAPON]).AsType<SetDamageType>;
end;

function TEntity.HasSkin : boolean;
begin
  Result := FSkinID <> '';
end;

function TEntity.HasUnitProperty(UnitProperty : EnumUnitProperty) : boolean;
begin
  Result := UnitProperty in Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TEntity.OwningCommander : TEntity;
begin
  if not assigned(Game) or not Game.EntityManager.TryGetEntityByID(CommanderID, Result) then
      Result := nil;;
end;

procedure TEntity.RegisterComponent(EntityComponent : TEntityComponent);
var
  i : integer;
begin
  if EntityComponent.ComponentGroup = ALLGROUP then exit;
  for i in EntityComponent.ComponentGroup do
  begin
    while FGroupsInUse.Count <= i do FGroupsInUse.Add(0);
    // if group is reserved, first component dereserves it
    if FGroupsInUse[i] < 0 then FGroupsInUse[i] := 0;
    FGroupsInUse[i] := FGroupsInUse[i] + 1;
  end;
end;

procedure TEntity.RemoveGroups(const Groups : TArray<Byte>);
begin
  GlobalEventbus.Trigger(eiRemoveComponentGroup, [ID, RParam.From<SetComponentGroup>(ByteArrayToComponentGroup(Groups))]);
end;

procedure TEntity.DeregisterComponent(EntityComponent : TEntityComponent);
var
  i : integer;
begin
  if EntityComponent.ComponentGroup = ALLGROUP then exit;
  for i in EntityComponent.ComponentGroup do
  begin
    assert(FGroupsInUse.Count > i, 'TEntity.DeregisterComponent: Some component seems to deregister but never registered or changed its group without notifing the entity.');
    FGroupsInUse[i] := FGroupsInUse[i] - 1;
  end;
end;

function TEntity.ReserveFreeGroup : Byte;
var
  i : Byte;
begin
  for i := RESERVED_GROUPS - 1 to high(Byte) do
  begin
    while FGroupsInUse.Count <= i do FGroupsInUse.Add(0);
    if FGroupsInUse[i] = 0 then
    begin
      // reserve group
      FGroupsInUse[i] := -1;
      if i > 200 then
          NOOP;
      exit(i);
    end;
  end;
  // should never happen, except we exaggerate with buffs (256 groups are filled up = ~ 128 Buffs)
  raise EOutOfResources.Create('TEntity.ReserveFreeGroup: Could not find free group!');
end;

function TEntity.ResFill(const ResourceType : EnumResource; const Group : SetComponentGroup) : single;
begin
  if ResourceType in RES_INT_RESOURCES then
      Result := Balance(ResourceType, Group).AsInteger / Cap(ResourceType, Group).AsInteger
  else
      Result := Balance(ResourceType, Group).AsSingle / Cap(ResourceType, Group).AsSingle;
end;

function TEntity.ResFill(const ResourceType : EnumResource) : single;
begin
  if ResourceType in RES_INT_RESOURCES then
      Result := Balance(ResourceType).AsInteger / Cap(ResourceType).AsInteger
  else
      Result := Balance(ResourceType).AsSingle / Cap(ResourceType).AsSingle;
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
        FEventhandler[ei, et] := nil;
      end;
  inherited;
end;

procedure TEventbus.StartEvent(Event : EnumEventIdentifier; const Group : SetComponentGroup);
begin
  CurrentEvent.EventIdentifier := Event;
  CurrentEvent.CalledToGroup := Group;
  Eventstack.Push(CurrentEvent);
end;

procedure TEventbus.EndEvent;
begin
  Eventstack.PopRemove;
  if Eventstack.Size > 0 then CurrentEvent := Eventstack.Peek
  else FillChar(CurrentEvent, SizeOf(REventInformation), 0);
end;

function TEventbus.Read(Eventname : EnumEventIdentifier; Parameters : array of RParam; const Group : SetComponentGroup; ComponentID : integer) : RParam;
var
  EventHandler : TEventhandler;
  EventEnumerator : TEventEnumerator;
  EntityComponent : TEntityComponent;
begin
  StartEvent(Eventname, Group);
  if assigned(FOwner) then
      Result := FOwner.FBlackboard.GetValue(Eventname, Group)
  else
      Result := RPARAM_EMPTY;
  EventHandler := FEventhandler[Eventname, etRead];
  if assigned(EventHandler) then
  begin
    EventEnumerator := EventHandler.GetEnumerator;
    EventEnumerator.BeginEvent;
    while EventEnumerator.HasNext do
    begin
      EntityComponent := EventEnumerator.CurrentSubscriber.EntityComponent;
      if ((Group = []) or (Group * EntityComponent.ComponentGroup <> []) or (ALLGROUP_INDEX in EntityComponent.ComponentGroup)) and
        ((ComponentID = 0) or (EntityComponent.FUniqueID = ComponentID)) then
      begin
        Result := EntityComponent.OnRead(self, Eventname, Parameters, Result);
      end;
      EventEnumerator.Increment;
    end;
    EventEnumerator.EndEvent;
    EventHandler.ReleaseEnumerator;
  end;
  EndEvent;
end;

function TEventbus.ReadHierarchic(Eventname : EnumEventIdentifier; const Values : TArray<RParam>; const Group : SetComponentGroup) : RParam;
begin
  Result := read(Eventname, Values, Group);
  if (Group <> []) and Result.IsEmpty then
      Result := read(Eventname, Values, []);
end;

procedure TEventbus.Subscribe(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityCompononent : TEntityComponent; ParameterCount : integer);
var
  EventHandler : TEventhandler;
  Subscriber : RSubscriber;
begin
  Subscriber := RSubscriber.Create(EntityCompononent, Priority);
  EventHandler := FEventhandler[Eventname, EventType];
  if not assigned(EventHandler) then
  begin
    EventHandler := TEventhandler.Create(ParameterCount);
    FEventhandler[Eventname, EventType] := EventHandler;
  end;
  EventHandler.AddSubscriber(Subscriber);
end;

procedure TEventbus.SubscribeRemote(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; EntityCompononent : TEntityComponent; const MethodName : string; ParameterCount : integer; NetworkSender : EnumNetworkSender);
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

procedure TEventbus.Trigger(Eventname : EnumEventIdentifier; Values : array of RParam; const Group : SetComponentGroup; ComponentID : integer; Write : boolean);
var
  EventHandler : TEventhandler;
  EventEnumerator : TEventEnumerator;
  Subscriber : RSubscriber;
  i : integer;
  Parameters : TArray<RParam>;
  GlobalEventbus : TEventbus;
  SendID : integer;
begin
  StartEvent(Eventname, Group);
  EventHandler := FEventhandler[Eventname, HGeneric.TertOp<EnumEventType>(write, etWrite, etTrigger)];
  if assigned(EventHandler) then
  begin
    EventEnumerator := EventHandler.GetEnumerator;
    EventEnumerator.BeginEvent;
    while EventEnumerator.HasNext do
    begin
      Subscriber := EventEnumerator.CurrentSubscriber;
      if ((Group = []) or
        (Group * Subscriber.EntityComponent.ComponentGroup <> []) or
        (ALLGROUP_INDEX in Subscriber.EntityComponent.ComponentGroup))
        and
        ((ComponentID = 0) or
        (Subscriber.EntityComponent.FUniqueID = ComponentID)) then
        if not Subscriber.EntityComponent.OnTrigger(self, Eventname, Values, write) then
        begin
          EventEnumerator.EndEvent;
          EventHandler.ReleaseEnumerator;
          EndEvent;
          exit;
        end;
      EventEnumerator.Increment;
    end;
    EventEnumerator.EndEvent;
    EventHandler.ReleaseEnumerator;
  end;
  if EventIdentifierToNetworkSend(Eventname) in [APPLICATIONTYPE] then
  begin
    setlength(Parameters, length(Values));
    for i := 0 to length(Values) - 1 do
    begin
      Parameters[i] := Values[i];
    end;
    // only the globaleventbus has no owner
    if assigned(FOwner) then
        GlobalEventbus := FOwner.FGlobalEventbus
    else
        GlobalEventbus := self;
    if assigned(FOwner) then
        SendID := FOwner.ID
    else
        SendID := 0;
    GlobalEventbus.Trigger(eiNetworkSend, [
      SendID,
      RParam.From<EnumEventIdentifier>(Eventname),
      RParam.From<SetComponentGroup>(Group),
      ComponentID,
      RParam.FromArray<RParam>(Parameters),
      write]);
  end;
  if assigned(FOwner) and write and (length(Values) > 0) then FOwner.FBlackboard.SetValue(Eventname, Group, Values[0]);
  EndEvent;
end;

procedure TEventbus.InvokeWithRawData(Eventname : EnumEventIdentifier; const Group : SetComponentGroup; ComponentID : integer; const ValuesAsRawData : TArray<Byte>; WriteEvent : boolean);
var
  i, DataPos, ParameterCount : integer;
  Values : TArray<RParam>;
  RawDataPosition, DataLength : integer;
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
    if PWord(@ValuesAsRawData[DataPos])^ > 0 then
        DataPos := DataPos + 2 + PWord(@ValuesAsRawData[DataPos])^
      // string save size as length not as byte size
    else DataPos := DataPos + 2 + (PWord(@ValuesAsRawData[DataPos])^ * SizeOf(Char));
  end;
  assert(DataPos = length(ValuesAsRawData));
  // now we know how much parameter we have
  setlength(Values, ParameterCount);
  // copy rawdata in to RParam array
  RawDataPosition := 0;
  for i := 0 to length(Values) - 1 do
  begin
    DataLength := PWord(@ValuesAsRawData[RawDataPosition])^;
    inc(RawDataPosition, 2);
    case DataLength of
      // Zero signals that following data saved stringdata
      0 :
        begin
          Values[i] := RPARAMEMPTY;
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
  FEventhandler[Eventname, EventType].RemoveSubscriber(RSubscriber.Create(EntityComponent, Priority));
end;

procedure TEventbus.Write(Eventname : EnumEventIdentifier; const Values : array of RParam; const Group : SetComponentGroup; ComponentID : integer);
begin
  Trigger(Eventname, Values, Group, ComponentID, True);
end;

{ TUnitProperty }

procedure TEntityComponent.BeforeComponentFree;
begin

end;

function TEntityComponent.BuildExceptionMessage(const ExceptionMessage : string; const FormatParameters : array of const) : string;
begin
  Result := BuildExceptionMessage(Format(ExceptionMessage, FormatParameters));
end;

function TEntityComponent.BuildExceptionMessage(const ExceptionMessage : string) : string;
begin
  Result := self.QualifiedClassName + '.' + ExceptionMessage + ' Group|Called: ' + HRtti.SetToString<SetComponentGroup>(ComponentGroup) + '|' + HRtti.SetToString<SetComponentGroup>(CurrentEvent.CalledToGroup) + ' Entity: ' + Owner.ScriptFile;
end;

function TEntityComponent.CardLeague : integer;
begin
  Result := Eventbus.ReadHierarchic(eiResourceBalance, [ord(reCardLeague)], ComponentGroup).AsInteger;
end;

function TEntityComponent.CardLevel : integer;
begin
  Result := Eventbus.ReadHierarchic(eiResourceBalance, [ord(reCardLevel)], ComponentGroup).AsInteger;
end;

procedure TEntityComponent.ChangeEventPriority(Eventname : EnumEventIdentifier; EventType : EnumEventType; Priority : EnumEventPriority; Scope : EnumEventScope);
var
  SubscribedEvent : TSubscribedEvent;
  TargetEventbus : TEventbus;
begin
  if Scope = esGlobal then
      TargetEventbus := GlobalEventbus
  else
      TargetEventbus := Eventbus;
  SubscribedEvent := LookUpSubscribedEvent(TargetEventbus, Eventname, EventType);
  assert(assigned(SubscribedEvent), 'TEntityComponent.ChangeEventPriority: Could not find event to change!');
  ExtractSubscribedEvent(SubscribedEvent);
  TargetEventbus.Unsubscribe(SubscribedEvent.Eventname, SubscribedEvent.EventType, SubscribedEvent.EventPriority, self);

  SubscribedEvent.EventPriority := Priority;
  DeploySubscribedEvent(SubscribedEvent);
  TargetEventbus.Subscribe(SubscribedEvent.Eventname, SubscribedEvent.EventType, SubscribedEvent.EventPriority, self, SubscribedEvent.ParameterCount);
end;

procedure TEntityComponent.ComponentFree;
begin
  self.Free;
end;

constructor TEntityComponent.Create(Owner : TEntity);
begin
  CreateGrouped(Owner, nil);
end;

class constructor TEntityComponent.Create;
begin
  FComponentSubscriptionPatterns := TThreadSafeObjectDictionary < TClass, TList < RSubscriptionPattern >>.Create([doOwnsValues]);
end;

class destructor TEntityComponent.Destroy;
begin
  FComponentSubscriptionPatterns.Free;
end;

constructor TEntityComponent.CreateGrouped(Owner : TEntity; Group : TArray<Byte>);
begin
  FOwner := Owner;
  FRemoteSubscription := TList<TRemoteSubscription>.Create;
  FUniqueID := Owner.GetNewComponentID;
  FComponentGroup := ByteArrayToComponentGroup(Group);
  FRttiContext := TRttiContext.Create;
  RegisterInOwner;
  SubscribeEvents;
end;

constructor TEntityComponent.CreateGroupedAll(Owner : TEntity);
begin
  CreateGrouped(Owner, [ALLGROUP_INDEX]);
end;

procedure TEntityComponent.DeploySubscribedEvent(Event : TSubscribedEvent);
var
  list : TObjectList<TSubscribedEvent>;
begin
  list := FSubscribedEvents[Event.Eventname, Event.EventType];
  assert(not(LookUpSubscribedEvent(Event.TargetEventbus, Event.Eventname, Event.EventType) <> nil), 'TEntityComponent.DeploySubscribedEvent: Double subscription!');
  if not assigned(list) then
  begin
    list := TObjectList<TSubscribedEvent>.Create;
    FSubscribedEvents[Event.Eventname, Event.EventType] := list;
  end;
  list.Add(Event);
end;

procedure TEntityComponent.DeregisterInOwner;
begin
  if assigned(FOwner) then FOwner.DeregisterComponent(self);
end;

procedure TEntityComponent.DeferFree;
begin
  if assigned(Game) then Game.EntityManager.FreeComponent(self);
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
  DeregisterInOwner;
  UnSubscribeEvents;
  FRemoteSubscription.Free;
  FRttiContext.Free;
  inherited;
end;

procedure TEntityComponent.EnumerateComponents(Callback : ProcEnumerateEntityComponentCallback);
begin
  Callback(self);
end;

function TEntityComponent.Eventbus : TEventbus;
begin
  assert(assigned(FOwner));
  Result := FOwner.FEventbus;
end;

procedure TEntityComponent.ExtractSubscribedEvent(Event : TSubscribedEvent);
var
  list : TObjectList<TSubscribedEvent>;
begin
  list := FSubscribedEvents[Event.Eventname, Event.EventType];
  if assigned(list) then
  begin
    list.Extract(Event);
  end;
end;

function TEntityComponent.GlobalEventbus : TEventbus;
begin
  assert(assigned(FOwner));
  Result := FOwner.FGlobalEventbus;
end;

function TEntityComponent.IsLocalCall(const TargetGroup : SetComponentGroup) : boolean;
begin
  Result := (CurrentEvent.CalledToGroup * TargetGroup <> []) or (TargetGroup = []);
end;

function TEntityComponent.IsLocalCall : boolean;
begin
  Result := (CurrentEvent.CalledToGroup * ComponentGroup <> []) or (ComponentGroup = []);
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

procedure TEntityComponent.MakeException(const ExceptionMessage : string);
var
  msg : string;
begin
  msg := BuildExceptionMessage(ExceptionMessage);
  HLog.Log(msg);
  raise Exception.Create(msg);
end;

procedure TEntityComponent.MakeException(const ExceptionMessage : string; const FormatParameters : array of const);
var
  msg : string;
begin
  msg := BuildExceptionMessage(ExceptionMessage, FormatParameters);
  HLog.Log(msg);
  raise Exception.Create(msg);
end;

function TEntityComponent.OnEnumerate(const Callback : RParam) : boolean;
begin
  Result := True;
  EnumerateComponents(Callback.AsProc<ProcEnumerateEntityComponentCallback>());
end;

function TEntityComponent.OnBeforeComponentFree : boolean;
begin
  Result := True;
  // only free with whole entity
  if (CurrentEvent.CalledToGroup <> []) and (ComponentGroup = ALLGROUP) then exit;
  BeforeComponentFree;
end;

function TEntityComponent.OnComponentFree : boolean;
begin
  Result := True;
  // only free with whole entity
  if (CurrentEvent.CalledToGroup <> []) and (ComponentGroup = ALLGROUP) then exit;
  ComponentFree;
end;

function TEntityComponent.OnRead(Caller : TEventbus; Event : EnumEventIdentifier; var Parameters : array of RParam; var ResultFromAncestor : RParam) : RParam;
var
  SubscribedEvent : TSubscribedEvent;
  EventMethod : TMethod;
  UseResultFromAncestor : boolean;
begin
  SubscribedEvent := LookUpSubscribedEvent(Caller, Event, etRead);
  assert(assigned(SubscribedEvent), 'For event "' + HRtti.EnumerationToString<EnumEventIdentifier>(Event) + '" of type "' + HRtti.EnumerationToString<EnumEventType>(etRead) + '" no method found!');

  // ResultFromAncestor is optional, check parametercount
  if not((length(Parameters) + 1 = SubscribedEvent.ParameterCount) or ((length(Parameters) = SubscribedEvent.ParameterCount))) then
      raise EHandleEventException.Create(Format('Parametercount for read event "%s" in component "%s" does not match - expected %d[+1], found %d.',
      [HRtti.EnumerationToString<EnumEventIdentifier>(Event), self.ClassName, SubscribedEvent.ParameterCount, length(Parameters)]));
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
      end;
    6 :
      begin
        if UseResultFromAncestor then Result := ProcEventReadParam6(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], Parameters[4], ResultFromAncestor)
        else Result := ProcEventReadParam6(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], Parameters[4], Parameters[5]);
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
  assert(assigned(SubscribedEvent), 'For event "' + HRtti.EnumerationToString<EnumEventIdentifier>(Event) + '" of type "' + HRtti.EnumerationToString<EnumEventType>(etTrigger) + '" no method found!');

  // check parametercount
  if not(length(Parameters) = SubscribedEvent.ParameterCount) then
      raise EHandleEventException.Create(Format('Parametercount for trigger event "%s" in component "%s" does not match - expected %d, found %d.',
      [HRtti.EnumerationToString<EnumEventIdentifier>(Event), self.ClassName, SubscribedEvent.ParameterCount, length(Parameters)]));
  // prepare invoke
  EventMethod.Code := SubscribedEvent.EventHandler;
  EventMethod.Data := Pointer(self);
  // choice methodtype by parametercount
  case SubscribedEvent.ParameterCount of
    0 : Result := ProcEventTriggerParam0(EventMethod)();
    1 : Result := ProcEventTriggerParam1(EventMethod)(Parameters[0]);
    2 : Result := ProcEventTriggerParam2(EventMethod)(Parameters[0], Parameters[1]);
    3 : Result := ProcEventTriggerParam3(EventMethod)(Parameters[0], Parameters[1], Parameters[2]);
    4 : Result := ProcEventTriggerParam4(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3]);
    5 : Result := ProcEventTriggerParam5(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], Parameters[4]);
    6 : Result := ProcEventTriggerParam6(EventMethod)(Parameters[0], Parameters[1], Parameters[2], Parameters[3], Parameters[4], Parameters[5]);
  else raise EHandleEventException.Create(Format('Parametercount %d not supported.', [SubscribedEvent.ParameterCount]));
  end;
end;

procedure TEntityComponent.RegisterInOwner;
begin
  if assigned(FOwner) then FOwner.RegisterComponent(self);
end;

procedure TEntityComponent.SetSetComponentGroup(const Value : SetComponentGroup);
begin
  DeregisterInOwner;
  FComponentGroup := Value;
  RegisterInOwner;
end;

procedure TEntityComponent.SubscribeEvent(Event : EnumEventIdentifier; EventType : EnumEventType;
EventPriority : EnumEventPriority; EventHandler : Pointer; ParameterCount : integer; TargetEventbus : TEventbus);
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
  EventAttributes : TArray<TCustomAttribute>;
  TargetEventbus : TEventbus;
  Attributes : TArray<TCustomAttribute>;
  Parameters : TArray<TRttiParameter>;
  SubscriptionPattern : RSubscriptionPattern;
  SubscriptionPatterns : TList<RSubscriptionPattern>;
var
  i, j : integer;
  AlreadySet : boolean;
  procedure CheckExpected(ExpectedType, GivenType : PTypeInfo; Target : string);
  begin
    if ExpectedType <> GivenType then
        raise ERegisterEventException.Create(Format(
        'TEntityComponent.SubscribeEvents: For %s in "%s.%s" was type "%s" expected, but type "%s" found!',
        [Target, SelfType.QualifiedName, Method.Name, ExpectedType.Name, GivenType.Name]));
  end;

  procedure CheckResultType;
  begin
    case EventAttribute.FEventSpecification.EventType of
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
  FComponentSubscriptionPatterns.SharedLock;
  if not FComponentSubscriptionPatterns.TryGetValue(self.ClassType, SubscriptionPatterns) then
  begin
    FComponentSubscriptionPatterns.ExclusiveLock;
    // fetch pattern a second time, as two threads going the steps simultaneously could wait for writing at the same time
    // so all threads after the first have to check if some other already filled the gap
    if not FComponentSubscriptionPatterns.TryGetValue(self.ClassType, SubscriptionPatterns) then
    begin
      SubscriptionPatterns := TList<RSubscriptionPattern>.Create;
      FComponentSubscriptionPatterns.Add(self.ClassType, SubscriptionPatterns);
      SelfType := FRttiContext.GetType(self.ClassType).AsInstance;
      // search for all event-methods
      for Method in SelfType.GetMethods do
      begin
        // skip all abstract and all methods from TObject
        if not(Method.IsAbstract or (Method.Parent.AsInstance.MetaclassType = TObject)) then
        begin
          if not Method.HasExtendedInfo then
              raise ERegisterEventException.Create('TEntityComponent.SubscribeEvents: No extended info was found for ' + Method.Name + ' in class ' + Method.Parent.AsInstance.MetaclassType.ClassName + '!')
          else
          begin
            Attributes := Method.GetAttributes;
            EventAttributes := HRtti.SearchForAttributes(XEvent, Attributes);
            if length(EventAttributes) > 0 then
            begin
              assert(Method.DispatchKind = dkStatic, 'TEntityComponent.SubscribeEvents: Virtual event methods could produce subscription errors.');
              for i := 0 to length(EventAttributes) - 1 do
              begin
                EventAttribute := XEvent(EventAttributes[i]);
                // prevent double subscription by inheritance
                AlreadySet := False;
                for j := 0 to SubscriptionPatterns.Count - 1 do
                  if (SubscriptionPatterns[j].EventSpecification.Event = EventAttribute.FEventSpecification.Event) and
                    (SubscriptionPatterns[j].EventSpecification.EventType = EventAttribute.FEventSpecification.EventType) then
                  begin
                    AlreadySet := True;
                    break;
                  end;
                if not AlreadySet then
                begin
                  Parameters := Method.GetParameters;
                  CheckResultType;
                  CheckParameterTypes;
                  SubscriptionPatterns.Add(RSubscriptionPattern.Create(
                    EventAttribute.FEventSpecification,
                    Method.CodeAddress,
                    length(Parameters)
                    ));
                end;
              end;
            end
            else
              // Reminder removed because of inheritance - added, because inheritance fixed
              // has prefix On but no XEventattribute -> exception
              if (AnsiUpperCase(copy(Method.Name, 1, 2)) = 'ON') and (Method.Visibility = mvPublished) then
                  raise ERegisterEventException.Create('TEntityComponent.SubscribeEvents: Method "' + Method.Name + '" with prefix "On" found but no XEventAttribute!');
          end;
        end;
      end;
    end;
    FComponentSubscriptionPatterns.ExclusiveUnlock;
  end;
  FComponentSubscriptionPatterns.SharedUnlock;
  for i := 0 to SubscriptionPatterns.Count - 1 do
  begin
    SubscriptionPattern := SubscriptionPatterns[i];
    TargetEventbus := HGeneric.TertOp<TEventbus>(SubscriptionPattern.EventSpecification.EventScope = esLocal, FOwner.Eventbus, GlobalEventbus);
    SubscribeEvent(
      SubscriptionPattern.EventSpecification.Event,
      SubscriptionPattern.EventSpecification.EventType,
      SubscriptionPattern.EventSpecification.EventPriotity,
      SubscriptionPattern.EventHandler,
      SubscriptionPattern.ParameterLength,
      TargetEventbus);
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

{ XEvent }

constructor XEvent.Create(Event : EnumEventIdentifier; EventPriotity : EnumEventPriority; EventType : EnumEventType; EventScope : EnumEventScope);
begin
  FEventSpecification := REventSpecification.Create(Event, EventPriotity, EventType, EventScope);
end;

{ TEventbus.RSubscriber }

constructor TEventbus.RSubscriber.Create(EntityComponent : TEntityComponent; Priority : EnumEventPriority);
begin
  self.EntityComponent := EntityComponent;
  self.Priority := Priority;
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

{ TEventbus.TEventhandler }

procedure TEventbus.TEventhandler.AddSubscriber(const Subscriber : RSubscriber);
var
  i, j : integer;
  Inserted : boolean;
begin
  Inserted := False;
  for i := 0 to Subscribers.Count - 1 do
    if ord(Subscribers[i].Priority) > ord(Subscriber.Priority) then
    begin
      Subscribers.Insert(i, Subscriber);
      Inserted := True;
      // if a subscriber get added before or at current position, the position has to increment as stack grows
      for j := 0 to FEnumerators.Count - 1 do
        if FEnumerators[j].FCurrentlyActive and (i <= FEnumerators[j].FActiveIndex) then FEnumerators[j].Increment;
      break;
    end;
  if not Inserted then Subscribers.Add(Subscriber);
end;

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
  FEnumerators := TObjectList<TEventEnumerator>.Create;
  FEnumerators.Add(TEventEnumerator.Create(self));
end;

procedure TEventbus.TEventhandler.ReleaseEnumerator;
begin
  assert(FEnumeratorIndex > 0);
  dec(FEnumeratorIndex);
  assert(not FEnumerators[FEnumeratorIndex].FCurrentlyActive);
end;

procedure TEventbus.TEventhandler.RemoveSubscriber(const Subscriber : RSubscriber);
var
  i, j : integer;
begin
  i := Subscribers.Remove(Subscriber);
  assert(i >= 0, 'TEventbus.TEventhandler.RemoveSubscriber: Trying to remove subscriber of event, but isn'' present!');
  // if a subscriber get removed before current position, the position has to decrement as stack shrinks
  for j := 0 to FEnumerators.Count - 1 do
    if FEnumerators[j].FCurrentlyActive and (i <= FEnumerators[j].FActiveIndex) then FEnumerators[j].Decrement;
end;

destructor TEventbus.TEventhandler.Destroy;
begin
  Subscribers.Free;
  FEnumerators.Free;
  inherited;
end;

function TEventbus.TEventhandler.GetEnumerator : TEventEnumerator;
begin
  while FEnumeratorIndex >= FEnumerators.Count do
      FEnumerators.Add(TEventEnumerator.Create(self));
  assert(not FEnumerators[FEnumeratorIndex].FCurrentlyActive, 'TEventbus.TEventhandler.GetEnumerator: Last enumerator is active, should not happen.');
  Result := FEnumerators[FEnumeratorIndex];
  inc(FEnumeratorIndex);
end;

{ TEventbus.TEventEnumerator }

procedure TEventbus.TEventEnumerator.BeginEvent;
begin
  assert(not FCurrentlyActive, 'TEventbus.TEventhandler.BeginEvent: Eventhandler has been entered twice!');
  FCurrentlyActive := True;
  FActiveIndex := 0;
end;

constructor TEventbus.TEventEnumerator.Create(Owner : TEventhandler);
begin
  FOwner := Owner;
  FCurrentlyActive := False;
  FActiveIndex := 0;
end;

function TEventbus.TEventEnumerator.CurrentSubscriber : RSubscriber;
begin
  assert(FCurrentlyActive);
  Result := FOwner.Subscribers[FActiveIndex];
end;

procedure TEventbus.TEventEnumerator.Decrement;
begin
  dec(FActiveIndex);
end;

procedure TEventbus.TEventEnumerator.EndEvent;
begin
  assert(FCurrentlyActive, 'TEventbus.TEventhandler.EndEvent: Eventhandler has been entered twice!');
  FCurrentlyActive := False;
end;

function TEventbus.TEventEnumerator.HasNext : boolean;
begin
  Result := FActiveIndex < FOwner.Subscribers.Count;
end;

procedure TEventbus.TEventEnumerator.Increment;
begin
  inc(FActiveIndex);
end;

{ XNetworkSerialize }

constructor XNetworkSerialize.Create(Event : EnumEventIdentifier);
begin
  FEvent := Event;
end;

type
  TEventbusScriptSideHelper = class
    private
      procedure Invoker(Info : TProgramInfo; ExtObject : TObject; Write : boolean);
      procedure TriggerInvoker(Info : TProgramInfo; ExtObject : TObject);
      procedure WriteInvoker(Info : TProgramInfo; ExtObject : TObject);
    public
  end;

type

  TScriptRParamInvoker = class
    private
      FRttitype : TRttiType;
    public
      constructor Create(TargetType : TRttiType);
      procedure OnInvoke(Info : TProgramInfo; var ExtObject : TObject);
      destructor Destroy; override;
  end;

  TScriptRParam = class
    Value : TValue;
  end;

type
  /// <summary> Helperclass for custom published blackboard in scriptengine. Contains invokermethods
  /// for every published method from blackboard.</summary>
  TBlackboardScriptInvoker = class
    private
      procedure ExtractInfos(const Info : TProgramInfo; const ExtObject : TObject; out Blackboard : TBlackboard; out Eventname : EnumEventIdentifier; out Group : SetComponentGroup);
      procedure ExtractIndexedInfos(const Info : TProgramInfo; const ExtObject : TObject; out Blackboard : TBlackboard; out Eventname : EnumEventIdentifier; out Group : SetComponentGroup; out Index : integer);
      function VarToRParam(vari : Variant) : RParam;
    public
      procedure SetValueInvoker(Info : TProgramInfo; ExtObject : TObject);
      procedure SetValueRIntVector2Invoker(Info : TProgramInfo; ExtObject : TObject);
      procedure SetValueByteArrayInvoker(Info : TProgramInfo; ExtObject : TObject);
      procedure GetValueInvoker(Info : TProgramInfo; ExtObject : TObject);
      procedure SetIndexedValueInvoker(Info : TProgramInfo; ExtObject : TObject);
      procedure GetIndexedValueInvoker(Info : TProgramInfo; ExtObject : TObject);

      procedure SetIndexedIntegerValuesInvoker(Info : TProgramInfo; ExtObject : TObject);
      procedure SetIndexedSingleValuesInvoker(Info : TProgramInfo; ExtObject : TObject);
      procedure SetIndexedStringValuesInvoker(Info : TProgramInfo; ExtObject : TObject);
  end;

procedure PublishRParamToScript();
var
  AClass : TdwsClass;
  AConstructor : TdwsConstructor;
  helper : TObjectList<TScriptRParamInvoker>;
  RttiContext : TRttiContext;
  // add constructor for given type to RParam
  procedure AddTypeToRParam(RttiType : TRttiType);
  var
    Invoker : TScriptRParamInvoker;
  begin
    Invoker := TScriptRParamInvoker.Create(RttiType);
    helper.Add(Invoker);
    AConstructor := AClass.Constructors.Add;
    AConstructor.Overloaded := True;
    AConstructor.Name := 'From';
    AConstructor.Parameters.Add('Value', RttiType.Name);
    AConstructor.OnEval := Invoker.OnInvoke;
  end;

begin
  helper := TObjectList<TScriptRParamInvoker>.Create(True);
  AClass := ScriptManager.CustomExpose.Classes.Add;
  AClass.Name := 'RParam';
  AClass.OnCleanUp := ScriptManager.CustomExpose.DoStandardCleanUp;
  AClass.HelperObject := helper;
  RttiContext := TRttiContext.Create;
  AddTypeToRParam(RttiContext.GetType(TypeInfo(RVector3)));
  RttiContext.Free;
end;

procedure PublishBlackboard();
var
  AClass : TdwsClass;
  AMeth : TdwsMethod;
  helper : TBlackboardScriptInvoker;
begin
  AClass := ScriptManager.CustomExpose.Classes.Add;
  AClass.Name := 'TBlackboard';
  helper := TBlackboardScriptInvoker.Create;
  AClass.HelperObject := helper;
  // procedure TBlackboard.SetValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Value : RParam);
  AMeth := AClass.Methods.Add('SetValue');
  AMeth.Overloaded := True;
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Value', 'Variant');
  AMeth.OnEval := helper.SetValueInvoker;

  AMeth := AClass.Methods.Add('SetValue');
  AMeth.Overloaded := True;
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Value', 'RIntVector2');
  AMeth.OnEval := helper.SetValueRIntVector2Invoker;

  AMeth := AClass.Methods.Add('SetValue');
  AMeth.Overloaded := True;
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Value', 'TArray<System.Byte>');
  AMeth.OnEval := helper.SetValueByteArrayInvoker;

  // function TBlackboard.GetValue(Event : EnumEventIdentifier; Group : SetComponentGroup) : RParam;
  AMeth := AClass.Methods.Add('GetValue', 'Variant');
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.OnEval := helper.GetValueInvoker;
  // procedure TBlackboard.SetIndexedValue(Event : EnumEventIdentifier; Group : SetComponentGroup; Index:integer; Value : RParam);
  AMeth := AClass.Methods.Add('SetIndexedValue');
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Index', 'integer');
  AMeth.Parameters.Add('Value', 'Variant');
  AMeth.OnEval := helper.SetIndexedValueInvoker;
  // function TBlackboard.GetIndexedValue(Event : EnumEventIdentifier; Index:integer; Group : SetComponentGroup) : RParam;
  AMeth := AClass.Methods.Add('GetIndexedValue', 'Variant');
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Index', 'integer');
  AMeth.OnEval := helper.GetIndexedValueInvoker;

  AMeth := AClass.Methods.Add('SetIndexedValues');
  AMeth.Overloaded := True;
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Values', 'TArray<System.Integer>');
  AMeth.OnEval := helper.SetIndexedIntegerValuesInvoker;

  AMeth := AClass.Methods.Add('SetIndexedValues');
  AMeth.Overloaded := True;
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Values', 'TArray<System.Single>');
  AMeth.OnEval := helper.SetIndexedSingleValuesInvoker;

  AMeth := AClass.Methods.Add('SetIndexedValues');
  AMeth.Overloaded := True;
  AMeth.Parameters.Add('Event', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.Parameters.Add('Values', 'TArray<System.String>');
  AMeth.OnEval := helper.SetIndexedStringValuesInvoker;
end;

procedure PublishEventbus();
var
  AClass : TdwsClass;
  AMeth : TdwsMethod;
  AArray : TdwsArray;
  helper : TEventbusScriptSideHelper;
begin
  // expose new Arraytype : array of Variant
  AArray := ScriptManager.CustomExpose.Arrays.Add;
  AArray.Name := 'AVariant';
  AArray.IsDynamic := True;
  AArray.DataType := 'Variant';
  // expose a special script version of TEventbus
  AClass := ScriptManager.CustomExpose.Classes.Add;
  AClass.Name := TEventbus.ClassName;
  // trigger invoker
  helper := TEventbusScriptSideHelper.Create;
  AClass.HelperObject := helper;
  AMeth := AClass.Methods.Add('Trigger');
  AMeth.Parameters.Add('Eventname', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Values', 'AVariant');
  AMeth.OnEval := helper.TriggerInvoker;

  AMeth := AClass.Methods.Add('TriggerGrouped');
  AMeth.Parameters.Add('Eventname', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Values', 'AVariant');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.OnEval := helper.TriggerInvoker;
  // write invoker
  AMeth := AClass.Methods.Add('WriteGrouped');
  AMeth.Parameters.Add('Eventname', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Values', 'AVariant');
  AMeth.Parameters.Add('Group', 'TArray<System.Byte>');
  AMeth.OnEval := helper.WriteInvoker;
  // write invoker
  AMeth := AClass.Methods.Add('Write');
  AMeth.Parameters.Add('Eventname', 'EnumEventIdentifier');
  AMeth.Parameters.Add('Values', 'AVariant');
  AMeth.OnEval := helper.WriteInvoker;
end;

{ TEventbusScriptSideHelper }

procedure TEventbusScriptSideHelper.Invoker(Info : TProgramInfo; ExtObject : TObject; Write : boolean);
var
  Eventname : EnumEventIdentifier;
  Eventbus : TEventbus;
  Parameters : TArray<RParam>;
  ScriptParameter : dwsDataContext.TData;
  i : integer;
  InterfaceValue : IInterface;
  GroupsAsArray : dwsDataContext.TData;
  Group : SetComponentGroup;
begin
  assert(assigned(ExtObject));
  assert(ExtObject is TEventbus);
  Eventbus := TEventbus(ExtObject);
  // first parameter contains everytime the eventname
  Eventname := EnumEventIdentifier(Info.ParamAsInteger[0]);
  ScriptParameter := Info.Data['Values'];
  setlength(Parameters, length(ScriptParameter));
  // apply parameter from script to native app
  for i := 0 to length(Parameters) - 1 do
  begin
    case TVarData(ScriptParameter[i]).VType of
      varUnknown :
        begin
          InterfaceValue := IUnknown(ScriptParameter[i]);
          if InterfaceValue is TScriptRParam then RParam.FromTValue(TScriptRParam(IScriptObj(IUnknown(ScriptParameter[i])).ExternalObject).Value)
          else Parameters[i] := IScriptObj(InterfaceValue).ExternalObject;
        end;
      varSingle, varDouble : Parameters[i] := single(ScriptParameter[i]);
      varSmallint, varInteger, varInt64, varLongWord, varUInt64 : Parameters[i] := integer(ScriptParameter[i]);
      varString, varUString : Parameters[i] := string(ScriptParameter[i]);
      varBoolean : Parameters[i] := boolean(ScriptParameter[i]);
    else raise EConvertError.Create(Format('TEventbusScriptSideHelper.TriggerInvoker: Can''t convert variant of type %d to RParam!',
        [TVarData(ScriptParameter[i]).VType]));
    end;
  end;
  Group := [];
  if Info.Table.FindSymbol('Group', TdwsVisibility.cvMagic) <> nil then
  begin
    GroupsAsArray := Info.Data['Group'];
    for i := 0 to length(GroupsAsArray) - 1 do
    begin
      assert(TVarData(GroupsAsArray[i]).VType in [varByte, varInteger, varInt64]);
      Group := Group + [Byte(GroupsAsArray[i])];
    end;
  end;
  if write then Eventbus.Write(Eventname, Parameters, Group)
  else Eventbus.Trigger(Eventname, Parameters, Group);
end;

procedure TEventbusScriptSideHelper.TriggerInvoker(Info : TProgramInfo; ExtObject : TObject);
begin
  Invoker(Info, ExtObject, False);
end;

procedure TEventbusScriptSideHelper.WriteInvoker(Info : TProgramInfo; ExtObject : TObject);
begin
  Invoker(Info, ExtObject, True);
end;

{ TScriptTValueInvoker }

constructor TScriptRParamInvoker.Create(TargetType : TRttiType);
begin
  FRttitype := TargetType;
end;

destructor TScriptRParamInvoker.Destroy;
begin
  FRttitype := nil;
  inherited;
end;

procedure TScriptRParamInvoker.OnInvoke(Info : TProgramInfo; var ExtObject : TObject);
begin
  ExtObject := TScriptRParam.Create;
  TScriptRParam(ExtObject).Value := TdwsRTTIInvoker.ValueFromIInfo(FRttitype, Info.Vars['Value']);
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
  ArraySize : integer;
begin
  RttiContext := TRttiContext.Create;
  RttiType := GetBaseType(RttiContext.GetType(self.ClassType));
  if not assigned(RttiType) then
      raise Exception.Create('TSerializableEntityComponent.Deserialize: Can''t find typeinfo class "' + self.ClassName + '".');
  FUniqueID := Stream.ReadAny<integer>;
  ComponentGroup := Stream.ReadAny<SetComponentGroup>();
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
        tkDynArray :
          begin
            TValue.Make(nil, Field.FieldType.Handle, Value);
            ArraySize := Stream.ReadAny<integer>();
            if ArraySize > 0 then
            begin
              DynArraySetLength(Pointer(Value.GetReferenceToRawData^), Value.TypeInfo, 1, @ArraySize);
              Stream.Read(Pointer(Value.GetReferenceToRawData^)^, ArraySize * Value.GetArrayElement(0).DataSize);
            end;
          end;
        tkLString, tkWString, tkUString :
          begin
            StringData := Stream.ReadString;
            Value := StringData;
          end;
        tkClass : TypeSupported := False;
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

function TSerializableEntityComponent.Serialize(const Stream : RParam) : boolean;
var
  RttiContext : TRttiContext;
  Field : TRttiField;
  RttiType : TRttiType;
  Value : TValue;
  StringData : string;
  i : integer;
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
  AStream.WriteAny<SetComponentGroup>(ComponentGroup);
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
        tkDynArray :
          begin
            AStream.WriteAny<integer>(Value.GetArrayLength);
            for i := 0 to Value.GetArrayLength - 1 do
                AStream.WriteBuffer(Value.GetReferenceToRawArrayElement(i)^, Value.GetArrayElement(0).DataSize);
          end;
        tkLString, tkWString, tkUString :
          begin
            StringData := Value.AsString;
            AStream.WriteString(StringData);
          end;
        tkClass : TypeSupported := False;
      else TypeSupported := False;
      end;
      if not TypeSupported then
          raise Exception.Create('TSerializableEntityComponent.Serialize: Type "' + Field.FieldType.Name + '" from field "' + Field.Name + '" is currently not supported!');
    end;
  end;
  RttiContext.Free;
end;

{ TBlackboard }

constructor TBlackboard.Create(Owner : TEntity);
begin
  FOwner := Owner;
end;

function TBlackboard.GetValueRaw(Event : EnumEventIdentifier; GroupIndex, Index : integer) : RParam;
begin
  if assigned(FValues[Event]) and
    (length(FValues[Event]) > GroupIndex) and
    assigned(FValues[Event, GroupIndex]) and
    (length(FValues[Event, GroupIndex]) > index) then
      Result := FValues[Event][GroupIndex][index]
  else Result := RPARAMEMPTY;
end;

procedure TBlackboard.DeleteValues(const Group : SetComponentGroup);
var
  i : Byte;
  Event : EnumEventIdentifier;
begin
  if (Group <> []) then
  begin
    for Event := low(FValues) to high(FValues) do
    begin
      for i in Group do
        if length(FValues[Event]) > i + 1 then
        begin
          FValues[Event][i + 1] := nil;
        end;
    end;
  end;
end;

function TBlackboard.GetIndexedValue(Event : EnumEventIdentifier; const Group : SetComponentGroup; Index : integer) : RParam;
var
  i : Byte;
begin
  // index 0 is reserved for the default index
  index := index + 1;
  if Group = [] then
  begin
    Result := GetValueRaw(Event, 0, index);
  end
  else
  begin
    Result := RPARAMEMPTY;
    for i in Group do
    begin
      Result := GetValueRaw(Event, i + 1, index);
      if not Result.IsEmpty then break;
    end;
  end;
end;

function TBlackboard.GetIndexMap(Event : EnumEventIdentifier; const Group : SetComponentGroup) : TDictionary<integer, RParam>;
var
  i, j : Byte;
  Value : RParam;
begin
  Result := TDictionary<integer, RParam>.Create;
  if not assigned(FValues[Event]) then exit;
  if (Group = []) then
  begin
    if (length(FValues[Event]) >= 1) and assigned(FValues[Event, 0]) then
      for i := 1 to length(FValues[Event, 0]) - 1 do
      begin
        Value := GetValueRaw(Event, 0, i);
        if not Value.IsEmpty then Result.AddOrSetValue(i - 1, Value)
      end;
  end
  else
  begin
    for i in Group do
      if (length(FValues[Event]) > i + 1) and assigned(FValues[Event, i + 1]) then
      begin
        for j := 1 to length(FValues[Event, i + 1]) - 1 do
        begin
          Value := GetValueRaw(Event, i + 1, j);
          if not Value.IsEmpty then Result.AddOrSetValue(j - 1, Value)
        end;
        if (Result.Count = 0) then break;
      end;
  end;
end;

function TBlackboard.GetValue(Event : EnumEventIdentifier; const Group : SetComponentGroup) : RParam;
begin
  Result := GetIndexedValue(Event, Group, -1);
end;

procedure TBlackboard.SetIndexedValue(Event : EnumEventIdentifier; const Group : SetComponentGroup; Index : integer; const Value : RParam);
var
  i : integer;
begin
  index := index + 1;
  if Group = [] then SetValueRaw(Event, 0, index, Value)
  else
    for i in Group do
        SetValueRaw(Event, i + 1, index, Value);
end;

procedure TBlackboard.SetValue(Event : EnumEventIdentifier; const Group : SetComponentGroup; const Value : RParam);
begin
  SetIndexedValue(Event, Group, -1, Value);
end;

procedure TBlackboard.SetValueRaw(Event : EnumEventIdentifier; GroupIndex, Index : integer; const Value : RParam);
begin
  if not assigned(FValues[Event]) or
    (GroupIndex >= length(FValues[Event])) then
      setlength(FValues[Event], GroupIndex + 1);
  if not assigned(FValues[Event][GroupIndex]) or
    (index >= length(FValues[Event][GroupIndex])) then
      setlength(FValues[Event][GroupIndex], index + 1);
  FValues[Event][GroupIndex][index] := Value;
end;

procedure TBlackboard.SaveToStream(Stream : TStream);
var
  i : EnumEventIdentifier;
  j, k : integer;
  Count : Word;
begin
  Count := 0;
  // count used events
  for i := low(EnumEventIdentifier) to high(EnumEventIdentifier) do
    for j := 0 to length(FValues[i]) - 1 do
      for k := 0 to length(FValues[i, j]) - 1 do
        if not FValues[i][j][k].IsEmpty then inc(Count);
  Stream.WriteAny<Word>(Count);
  // write used events
  for i := low(EnumEventIdentifier) to high(EnumEventIdentifier) do
    for j := 0 to length(FValues[i]) - 1 do
      for k := 0 to length(FValues[i, j]) - 1 do
        if not FValues[i][j][k].IsEmpty then
        begin
          Stream.WriteAny<EnumEventIdentifier>(i);
          Stream.WriteAny<Byte>(j);
          Stream.WriteAny<Byte>(k);
          FValues[i][j][k].SerializeIntoStream(Stream);
        end;
end;

procedure TBlackboard.LoadFromStream(Stream : TStream);
var
  i : EnumEventIdentifier;
  j, k, Index, Count : integer;
  Group : SetComponentGroup;
  Para : RParam;
begin
  Count := Stream.ReadAny<Word>();
  for index := 0 to Count - 1 do
  begin
    i := Stream.ReadAny<EnumEventIdentifier>();
    j := Stream.ReadAny<Byte>();
    k := Stream.ReadAny<Byte>();
    Para := RParam.DeserializeFromStream(Stream);
    if not Para.IsEmpty then
    begin
      if EventIdentifierToBlackboardEvent(i) then
      begin
        assert(k = 0, 'TBlackboard.LoadFromStream: Blackboardevents cannot have indices!');
        if j <= 0 then Group := []
        else Group := [j - 1];
        if i = eiPosition then FOwner.Position := Para.AsVector2
        else if i = eiFront then FOwner.Front := Para.AsVector2
        else FOwner.Eventbus.Write(i, [Para], Group);
      end
      else SetValueRaw(i, j, k, Para);
    end;
  end;
end;

{ TBlackboardScriptInvoker }

procedure TBlackboardScriptInvoker.ExtractIndexedInfos(const Info : TProgramInfo;
const ExtObject : TObject; out Blackboard : TBlackboard;
out Eventname : EnumEventIdentifier; out Group : SetComponentGroup;
out Index : integer);
begin
  assert(assigned(ExtObject));
  assert(ExtObject is TBlackboard);
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  // third parameter contains index
  index := Info.ParamAsInteger[2];
end;

procedure TBlackboardScriptInvoker.ExtractInfos(const Info : TProgramInfo;
const ExtObject : TObject; out Blackboard : TBlackboard; out Eventname : EnumEventIdentifier;
out Group : SetComponentGroup);
var
  GroupsAsArray : dwsDataContext.TData;
  i : integer;
begin
  assert(assigned(ExtObject));
  assert(ExtObject is TBlackboard);
  Blackboard := TBlackboard(ExtObject);
  // first parameter contains the eventname
  Eventname := EnumEventIdentifier(Info.ParamAsInteger[0]);
  // second parameter contains groups
  GroupsAsArray := Info.Data['Group'];
  Group := [];
  for i := 0 to length(GroupsAsArray) - 1 do
  begin
    assert(TVarData(GroupsAsArray[i]).VType in [varByte, varInteger, varInt64]);
    Group := Group + [Byte(GroupsAsArray[i])];
  end;
end;

procedure TBlackboardScriptInvoker.GetIndexedValueInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  Result : RParam;
begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  Result := Blackboard.GetValue(Eventname, Group);
  assert(False, 'Convert RParam to Variant')
end;

procedure TBlackboardScriptInvoker.GetValueInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  Result : RParam;
begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  Result := Blackboard.GetValue(Eventname, Group);
  assert(False, 'Convert RParam to Variant')
end;

procedure TBlackboardScriptInvoker.SetIndexedIntegerValuesInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  RawValues : TData;
  i : integer;
begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  // last parameter contains new value to set
  RawValues := Info.Data['Values'];
  for i := 0 to length(RawValues) - 1 do
  begin
    assert(TVarData(RawValues[i]).VType in [varByte, varInteger, varInt64]);
    Blackboard.SetIndexedValue(Eventname, Group, i, integer(RawValues[i]));
  end;
end;

procedure TBlackboardScriptInvoker.SetIndexedSingleValuesInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  RawValues : TData;
  i : integer;
begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  // last parameter contains new value to set
  RawValues := Info.Data['Values'];
  for i := 0 to length(RawValues) - 1 do
  begin
    assert(TVarData(RawValues[i]).VType in [varSingle, varDouble]);
    Blackboard.SetIndexedValue(Eventname, Group, i, single(RawValues[i]));
  end;
end;

procedure TBlackboardScriptInvoker.SetIndexedStringValuesInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  RawValues : TData;
  i : integer;
begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  // last parameter contains new value to set
  RawValues := Info.Data['Values'];
  for i := 0 to length(RawValues) - 1 do
  begin
    assert(TVarData(RawValues[i]).VType = varUString);
    Blackboard.SetIndexedValue(Eventname, Group, i, string(RawValues[i]));
  end;
end;

procedure TBlackboardScriptInvoker.SetIndexedValueInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  ValueAsVariant : Variant;
  Value : RParam;
  Index : integer;
begin
  ExtractIndexedInfos(Info, ExtObject, Blackboard, Eventname, Group, index);
  // last parameter contains new value to set
  ValueAsVariant := Info.ParamAsVariant[3];
  Value := VarToRParam(ValueAsVariant);
  Blackboard.SetIndexedValue(Eventname, Group, index, Value);
end;

procedure TBlackboardScriptInvoker.SetValueInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  ValueAsVariant : Variant;
  Value : RParam;

begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  // last parameter contains new value to set
  ValueAsVariant := Info.ParamAsVariant[2];
  Value := VarToRParam(ValueAsVariant);
  Blackboard.SetValue(Eventname, Group, Value);
end;

procedure TBlackboardScriptInvoker.SetValueRIntVector2Invoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  Value : RIntVector2;

begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  Value.X := Info.Vars['Value'].Member['X'].ValueAsInteger;
  Value.Y := Info.Vars['Value'].Member['Y'].ValueAsInteger;
  Blackboard.SetValue(Eventname, Group, Value);
end;

procedure TBlackboardScriptInvoker.SetValueByteArrayInvoker(Info : TProgramInfo; ExtObject : TObject);
var
  Eventname : EnumEventIdentifier;
  Blackboard : TBlackboard;
  Group : SetComponentGroup;
  Value : TArray<Byte>;
  GroupsAsArray : dwsDataContext.TData;
  i : integer;
  ValPar : RParam;
begin
  ExtractInfos(Info, ExtObject, Blackboard, Eventname, Group);
  // second parameter contains groups
  GroupsAsArray := Info.Data['Value'];
  setlength(Value, length(GroupsAsArray));
  for i := 0 to length(GroupsAsArray) - 1 do
  begin
    assert(TVarData(GroupsAsArray[i]).VType in [varByte, varInteger, varInt64], 'TBlackboardScriptInvoker.SetValueByteArrayInvoker: Only ordinal values are supported!');
    assert(not(TVarData(GroupsAsArray[i]).VType in [varInteger, varInt64]) or (integer(GroupsAsArray[i]) <= high(Byte)), 'TBlackboardScriptInvoker.SetValueByteArrayInvoker: Currently values > Byte not supported!');
    Value[i] := Byte(GroupsAsArray[i]);
  end;
  // convert byte array to sets for some events
  case Eventname of
    eiUnitProperties : ValPar := RParam.From<SetUnitProperty>(ByteArrayToSetUnitProperies(Value));
    eiDamageType : ValPar := RParam.From<SetDamageType>(ByteArrayToSetDamageType(Value));
  else
    ValPar := RParam.FromArray<Byte>(Value);
  end;
  Blackboard.SetValue(Eventname, Group, ValPar);
end;

function TBlackboardScriptInvoker.VarToRParam(vari : Variant) : RParam;
var
  InterfaceValue : IInterface;
begin
  case TVarData(vari).VType of
    varUnknown :
      begin
        InterfaceValue := IUnknown(vari);
        if InterfaceValue is TScriptRParam then Result := RParam.FromTValue(TScriptRParam(IScriptObj(IUnknown(vari)).ExternalObject).Value)
        else Result := IScriptObj(InterfaceValue).ExternalObject;
      end;
    varSingle, varDouble : Result := single(vari);
    varSmallint, varInteger, varInt64, varLongWord, varUInt64 : Result := integer(vari);
    varString, varUString : Result := string(vari);
    varBoolean : Result := boolean(vari);
  else raise EConvertError.Create(Format('TBlackboardScriptInvoker.SetValueInvoker: Can''t convert variant of type %d to RParam!',
      [TVarData(vari).VType]));
  end;
end;

function ByteArrayToComponentGroup(const inArray : TArray<Byte>) : SetComponentGroup;
var
  i : integer;
begin
  Result := [];
  for i := 0 to length(inArray) - 1 do
      Result := Result + [inArray[i]];
end;

function IntArrayToComponentGroup(const inArray : TArray<integer>) : SetComponentGroup;
var
  i : integer;
begin
  Result := [];
  for i := 0 to length(inArray) - 1 do
      Result := Result + [inArray[i]];
end;

function ComponentGroupToByteArray(const inSet : SetComponentGroup) : TArray<Byte>;
var
  i : Byte;
begin
  Result := nil;
  for i in inSet do
  begin
    setlength(Result, length(Result) + 1);
    Result[high(Result)] := i;
  end;
end;

{ TRemoteSubscription }

constructor TRemoteSubscription.Create(TargetComponent : TEntityComponent; TargetEventbus : TEventbus; Event : EnumEventIdentifier; EventType : EnumEventType; EventPriority : EnumEventPriority);
begin
  FComponentFreed := False;
  FEventbusFreed := False;
  FTargetEventbus := TargetEventbus;
  FTargetComponent := TargetComponent;
  FEvent := Event;
  FEventPriotity := EventPriority;
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
    FTargetEventbus.Unsubscribe(FEvent, FEventType, FEventPriotity, FTargetComponent);
  end;
  // delete manually to prevent auto unsubscribe on eventbus
  FTargetComponent.DeleteSubscribedEvent(FTargetComponent.LookUpSubscribedEvent(FTargetEventbus, FEvent, FEventType));
  DecRefCounter;
end;

procedure TRemoteSubscription.FreeEventbus;
begin
  assert(FEventbusFreed = False);
  FEventbusFreed := True;
  DecRefCounter;
end;

{ REventSpecification }

constructor REventSpecification.Create(Event : EnumEventIdentifier; EventPriotity : EnumEventPriority; EventType : EnumEventType; EventScope : EnumEventScope);
begin
  self.Event := Event;
  self.EventPriotity := EventPriotity;
  self.EventType := EventType;
  self.EventScope := EventScope;
end;

{ TEntityComponent.RSubscriptionPattern }

constructor TEntityComponent.RSubscriptionPattern.Create(const EventSpecification : REventSpecification; EventHandler : Pointer; ParameterLength : integer);
begin
  self.EventSpecification := EventSpecification;
  self.EventHandler := EventHandler;
  self.ParameterLength := ParameterLength;
end;

initialization

Eventstack := TFastStack<REventInformation>.Create(1000);

{$IFDEF SERVER}
ScriptManager.UnitSearchPath := AbsolutePath('\..\' + PATH_SCRIPT_UNITS);
{$ELSE}
ScriptManager.UnitSearchPath := AbsolutePath(PATH_SCRIPT_UNITS);
{$ENDIF}
{$IFDEF DEBUG}
ScriptManager.Defines.Add('DEBUG');
{$ENDIF}
ScriptManager.ExposeConstant('ALLGROUP_INDEX', ALLGROUP_INDEX);
ScriptManager.ExposeType(TypeInfo(EnumEventPriority));
ScriptManager.ExposeType(TypeInfo(EnumEventType));
ScriptManager.ExposeType(TypeInfo(EnumEventScope));
ScriptManager.ExposeType(TypeInfo(EnumEventIdentifier));
ScriptManager.ExposeType(TypeInfo(RColor));
ScriptManager.ExposeType(TypeInfo(RVector2));
ScriptManager.ExposeType(TypeInfo(RVector3));
ScriptManager.ExposeType(TypeInfo(RVector4));
ScriptManager.ExposeType(TypeInfo(RVariedSingle));
ScriptManager.ExposeType(TypeInfo(RIntVector2));
ScriptManager.ExposeType(TypeInfo(RVariedVector3));
ScriptManager.ExposeType(TypeInfo(TArray<Byte>));
ScriptManager.ExposeType(TypeInfo(TArray<integer>));
ScriptManager.ExposeType(TypeInfo(TArray<single>));
ScriptManager.ExposeType(TypeInfo(TArray<string>));
ScriptManager.ExposeClass(TTimeManager);
PublishBlackboard();
PublishEventbus();
PublishRParamToScript();
ScriptManager.ExposeClass(TEntity);

finalization

FreeAndNil(Eventstack);

end.
