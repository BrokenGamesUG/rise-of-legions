unit Engine.Network.RPC;

interface


uses
  // System
  System.SysUtils,
  System.SyncObjs,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  Generics.Collections,
  // Indy
  IdHttp,
  IdCookieManager,
  IdMultipartFormData,
  IdUri,
  IdException,
  IdExceptionCore,
  IdStack,
  {$IF Defined(MSWINDOWS)}
  Winapi.Windows,
  {$ENDIF}
  // Engine
  Engine.Log,
  Engine.Serializer.JSON,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.Threads;

type

  EPromiseException = class(Exception);

  EnumPromiseStatus = (psWaiting, psSuccesful, psError);

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  /// <summary> Metaclass for generic Promise. Details see below TPromise<T>. </summary>
  TPromise = class abstract
    protected
      FCritSection : TCriticalSection;
      FErrorMessage : string;
      FStatus : EnumPromiseStatus;
      /// <summary> Thread that provide the value.</summary>
      FSourceThread : TThread;
      FRefCounter : integer;
      function GetErrorMessage : string;
      function GetStatus : EnumPromiseStatus;
      procedure SetPromiseError(ErrorMessage : string); virtual;
      procedure SetThread(const Value : TThread); virtual;
      function GetSourceThread : TThread;
      procedure SetPromiseSuccessful(Value : TValue); overload; virtual; abstract;
      function GetDefaultValue : TValue; virtual; abstract;
    public
      /// <summary> Status of promise, musst be polled and waited unitil value is ready.</summary>
      property Status : EnumPromiseStatus read GetStatus;
      /// <summary> Return the errormessage, if an error occured instead value was set. Only
      /// available if status = psError, so status musst be checked before get errormessage.</summary>
      property ErrorMessage : string read GetErrorMessage;
      /// <summary> If promised value will be provided by a thread, the thread is set here.</summary>
      property SourceThread : TThread read GetSourceThread write SetThread;
      /// <summary> Get mem and init all.</summary>
      constructor Create();
      /// <summary> Current thread will wait, until sourcethread has finished. After wait status <> psWaiting.
      /// Method will raise exception, if no sourcethread is set.</summary>
      procedure WaitForData;
      /// <summary> Will return true if no error has occured on getting data for the promise, else false.</summary>
      procedure BeforeDestruction; override;
      procedure FreeInstance; override;
      function WasSuccessful : boolean;
      function IsFinished : boolean;
      /// <summary> Check for all promises if they were sucessfull. If any promise fail, the method returns false
      /// and the first errormessage of the promise that fails will returned in outparameter.
      /// HINT: This method will fails also if any promise is at the moment of check not finsihed.</summary>
      class function CheckPromisesWereSuccessfull(Promises : array of TPromise; out ErrorMessage : string) : boolean;
      /// <summary> Badabumm</summary>
      destructor Destroy; override;
  end;

  CPromise = class of TPromise;

  /// <summary> A promise for a value, useful for delayed calls, like network calls. So a promise will contain
  /// the value if no error occurs, but the point in time is uncertain.
  /// Promise is designed for use in threaded enviroment, so every access is protected by a critical section.</summary>
  TPromise<T> = class(TPromise)
    public type
      ProcOnFinished = reference to procedure(Promise : TPromise<T>);
    protected
      FValue : T;
      FOnFinished : ProcOnFinished;
      function GetValue : T;
      procedure SetPromiseSuccessful(Value : T); overload;
      procedure SetPromiseSuccessful(Value : TValue); override;
      procedure SetPromiseError(ErrorMessage : string); override;
      function GetDefaultValue : TValue; override;
      procedure CallOnFinished;
    public
      /// <summary> Callback that is called, after the processing of the promise is finished. The callback is also called,
      /// if the processing failed. The callback is called in mainthreadcontext.</summary>
      property OnFinished : ProcOnFinished read FOnFinished write FOnFinished;
      /// <summary> Return the promised value. Value is only availabe if status = psReady, so status
      /// musst be checked before get value.</summary>
      property Value : T read GetValue;
  end;

  /// /////////////////////////////////  RPC - Caller  ///////////////////////////////////

  ERPC_Exception = class(Exception);

  EnumRPCOptions = (roSSL, roEncodeParameterAsJson, roEncapsuleParameterIntoJSONObject);
  SetRPCOPtions = set of EnumRPCOptions;

  EnumHttpMethod = (hmGET, hmPOST);

  /// <summary> Used to annotate methods which should be called remotely.
  /// ATTENTION: The method has to be virtual and must return a promise (for procedures it has to return TPromise<boolean>) </summary>
  RpcUrl = class(TCustomAttribute)
    strict private
      FUrl : string;
      FHTTPMethod : EnumHttpMethod;
      FJSONParameterObjectName : string;
      FOptions : SetRPCOPtions;
    public
      property Url : string read FUrl;
      property HTTPMethod : EnumHttpMethod read FHTTPMethod;
      property Options : SetRPCOPtions read FOptions;
      property JSONParameterObjectName : string read FJSONParameterObjectName;
      /// <summary>
      /// <param name="Url"> Relative or absolute url to rpc endpoint.</param>
      /// <param name="HTTPMethod"> HTTP method, current options are GET and POST. Default is POST</param>
      /// <param name="Options"> Set of additional options for rpc call, see EnumRPCOptions for more infos. Default is []</param>
      /// <param name="JSONParameterObjectName"> Name of the json object where all parameter will encapsuled into.
      /// Only used if option roEncapsuleParameterIntoJSONObject is set. Default is "data"</param></summary>
      constructor Create(Url : string; HTTPMethod : EnumHttpMethod = hmPOST; Options : SetRPCOPtions = []; JSONParameterObjectName : string = 'data');
  end;

  /// <summary> Marks a RpcMethod that the result is a list of different object types. To achive
  /// this on delphisite, the method returns an array of ABaseClass and all different objecttypes must
  /// derive from them. The matching of the objecttypes is done by an identifier. The identifier is a stringtype and the
  /// fieldname is determined by TypeIdentifierField. The data of this field is saved in a different field.
  /// e.g.
  /// datastructure:
  /// [{"type_id": "2", "type_data": {field_1:123, "field_2": 678}},
  /// {"type_id": "1", "type_data": {field_1:897}}]"
  /// Attribute:
  /// [RpcMixedObjectList('type_id', 'type_data')]</summary>
  RpcMixedObjectList = class(TCustomAttribute)
    strict private
      FTypeIdentifierField : string;
      FTypeDataField : string;
    public
      property TypeIdentifierField : string read FTypeIdentifierField;
      property TypeDataField : string read FTypeDataField;
      constructor Create(TypeIdentifierField : string; TypeDataField : string);
  end;

  RpcMixedBaseClass = class(TCustomAttribute);

  /// <summary> Mark a class used in RpcMixedObjectList as abstract, so it will not used for RpcMixedObjectList
  /// and ignored.</summary>
  RPCMixedAbstractClass = class(TCustomAttribute);

  RpcMixedClassDescendant = class(TCustomAttribute)
    strict private
      FTypeIdentifier : string;
    public
      property TypeIdentifier : string read FTypeIdentifier;
      constructor Create(TypeIdentifier : string);
  end;

  RCallLogItem = record
    Url : string;
    status_code : integer;
    error : string;
    response_time : integer;
    class function Empty : RCallLogItem; static;
  end;

  ProcCallLogDataAvailable = procedure(const Data : TArray<RCallLogItem>) of object;

  /// <summary> Base class for every API that accesses API calls per RPC. For every descendant no constructor nessecary,
  /// because constructor will setup all RPC registrations for every virtual method markes with attribute.</summary>
  /// <remarks>
  /// ATTENTION!!! Only for VIRTUAL methods marked with attribute RPC_Url(..) will prepared to call via RPC.
  /// The following RULES apply for any RPC method:
  /// 1. Only functions are supported, because any call, regardless of whether it has a return value or not, returns a promise.
  /// If no returnvalue is expected, the method needs a TPromise<boolean> which indicates that call was sucessfull or not.
  /// 2. Every function returns a TPromise: RPC presupposes that every API method returns a value of type TPromise. Because
  /// a RPC call is ASYNC and returnvalue will not available immediately. So a promise will supply value after call is finished.
  /// The promise will also handle/report errors, so if any error occurs on RPC, no exception will raised, instead the promise
  /// will report them.
  /// TPromise is owned by user and thread, so both has to free the promise.
  /// 3. Only methods marked with attribute RPC_Url will work for RPC. The attribute will configure the RPC access and engine
  /// knows where and how the RPC access has do be made.
  /// 4. Only virtual methods works for RPC, because only virtual methods can be intercepted and so the call is redirected to
  /// the remote computer. Methods don't need any implementation, so it works also with abstract methods.
  /// </remarks>
  TRpcApi = class abstract
    private type
      TRPCMethodInfo = class
        protected
          FIsAbsolute : boolean;
        public
          Protocol, HostID, Path : string; // aka url, split into pars as host will be resolved on-the-fly
          PromiseClass : CPromise;
          HTTPMethod : EnumHttpMethod;
          Options : SetRPCOPtions;
          JSONParameterName : string;
          CallerMethodType : TRttiMethod;
          function Url : string;
          constructor Create(Protocol, HostID, Path : string);
          constructor CreateAbsolute(Protocol, HostPath : string);
      end;

      TRPCCallThread = class(TThread)
        private
          FHTTPClient : TIdHttp;
          FPromise : TPromise;
          FUrl : string;
          FHTTPMethod : EnumHttpMethod;
          FCallerMethodType : TRttiMethod;
          FParameter : TDictionary<string, string>;
          procedure ProcessMixedObjectList(const JSONRawData : string; var ResultValue : TValue);
        protected
          procedure DoTerminate; override;
        public
          constructor Create(Promise : TPromise; CallerMethodType : TRttiMethod; Url : string; HTTPMethod : EnumHttpMethod; Parameter : TDictionary<string, string>; CookieManager : TIdCookieManager);
          procedure Execute; override;
          destructor Destroy; override;
      end;

      TCallLogSendThread = class(TThread)
        private
          FCallLog : TThreadList<RCallLogItem>;
          FCallLogItemAdded : TEvent;
        protected
          procedure Execute; override;
        public
          procedure AddCallLogItem(const LogItem : RCallLogItem);
          constructor Create;
          destructor Destroy; override;
      end;

    private
      // use global cookiemanager for seesionid's etc.
      class var CookieManager : TIdCookieManager;
      class var CallLogSendThread : TCallLogSendThread;
    var
      FMethodInterceptor : TVirtualMethodInterceptor;
      FRPCMethodInfos : TObjectDictionary<string, TRPCMethodInfo>;

      procedure CallHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
      class constructor Create;
      class destructor Destroy;
    public
      class var OnCallLogDataAvailable : ProcCallLogDataAvailable;
      /// <summary> Initializes the api and intercept all marked methods.
      /// <param name="HostID"> Hosts url is added to any relative url. Absolute urls will not changed.
      /// Use the HRPCHostManager to map HostIDs to Host-Urls. Mapping and completion of relative urls are evaluated lazy,
      /// so changing the host url will affect all RPC calls after.
      /// If HostID = '', it uses the DefaultHost from the HRPCHostManager.</param>
      /// </summary>
      constructor Create(HostID : string = '');
      class procedure FlushCallLog;
      destructor Destroy; override;
  end;

  /// <summary> A static mapper class used by RpcApis to resolve their target host. </summary>
  HRPCHostManager = class abstract
    strict private
      class var FHosts : TDictionary<string, string>;
    protected
      class function ResolveHost(HostID : string) : string;
    public
      /// <summary> The default host for RPCApis, which does not explicit specify a host.
      /// Defaults to 'localhost:8000' </summary>
      class var DefaultHost : string;
      /// <summary> Maps a host identifier to a specific host. Does not contain the protocol, but may contain parts of the path.
      /// Example: HRPCHostManager.SetHost(MANAGE_API_ID, 'myserver:8439/api'); </summary>
      class procedure SetHost(HostID : string; HostBase : string);
      class constructor Create;
      class destructor Destroy;
  end;

  /// ////////////////////////////////////  RPC - Handler  /////////////////////////////////////////////

  RpcHandler = class(TCustomAttribute)
    private
      FUrl : string;
    public
      property Url : string read FUrl;
      constructor Create(Url : string);
  end;

  /// <summary> Manage all RPC handlers. This means that first any handler that want to be called if a new RPC call is received,
  /// has to subscribe on handler. Now everytime the RPC Handler manager process any data, the handler calls every handler with
  /// the matching url.</summary>
  TRPCHandlerManager = class
    private type
      TRPCHandler = class
        strict private
          FTargetObject : TObject;
          FMethodHandler : TRttiMethod;
        public
          property TargetObject : TObject read FTargetObject;
          constructor Create(MethodHandler : TRttiMethod; TargetObject : TObject);
          /// <param name="Parameter"> JSONcoded dictionary (=object) that provide data for every parameter.</param>
          function Call(Parameter : string) : TValue;
          /// <summary> Returns true if target method returns a return value, else false.</summary>
          function IsFunction : boolean;
      end;
    private
      FHandlers : TObjectDictionary<string, TObjectList<TRPCHandler>>;
      FRttiContext : TRttiContext;
      class constructor Create;
      class destructor Destroy;
      constructor Create;
    public
      procedure SubscribeHandler(HandlerObject : TObject);
      procedure UnsubscribeHandler(HandlerObject : TObject);
      /// <summary> Call every Handler with the </summary>
      procedure CallHandlers(Url : string; Parameter : string);
      /// <summary> Call a RPC method with given parameter and retieve a result, this call will fail
      /// if more than one handler is registered on MethodIdentifier or if handler is not a function.</summary>
      function CallHandlerWithResult(MethodIdentifier : string; Parameter : string) : TValue;
      destructor Destroy; override;
  end;

  EnumBrokerError = (
    beNoError,        // no real error, only exist for easy uninitialized variables
    beSecurityError,  // any security error like unexpected behavior occurs
    beAnotherLogin,   // another PC has logged in with same username, so connection to you is closed
    beServerShutdown, // server is shuting down
    beTimeOut,        // connection is timedout or broker expect some data, that was not sended
    beUnknownError
    );

  ProcError = reference to procedure(ErrorType : EnumBrokerError);
  EBrokerException = class(Exception);

  {$IFDEF WINDOWS}

  TApiBroker = class
    private const
      NETMYSESSIONID         = 21; // Client -> Broker
      NETNEWDATA             = 22; // Server -> Broker -> Client, data send from server to client using the broker as backpath
      NETSERVERSHUTDOWNERROR = 96; // Broker -> Client, Broker will shutdown, so all connections between client and broker are cut
      NETANOTHERLOGINERROR   = 97; // Broker -> Client, send if broker gets a new connection request, old connection will be closed
      NETTIMEOUTERROR        = 98; // Server, Broker -> Client, Server, Broker, Whaterver waiting too long for data
      NETSECURITYERROR       = 99;
    private
      FTCPConnection : TTCPClientSocketDeluxe;
      FOnError : ProcError;
      FBrokerAddress : string;
      FSessionKey : string;
    public
      property OnError : ProcError write FOnError;
      property SessionKey : string read FSessionKey write FSessionKey;
      property BrokerAddress : string read FBrokerAddress write FBrokerAddress;
      function isConnected : boolean;
      procedure Connect;
      procedure Idle;

      constructor CreateAndConnect(BrokerAddress : string; SessionKey : string);
      constructor Create;
      destructor Destroy; override;
  end;

  {$ENDIF}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  RPCHandlerManager : TRPCHandlerManager;
  RPC_API_TIMEOUT : integer = 15000;

implementation

{ TPromise }

procedure TPromise.BeforeDestruction;
begin
  dec(FRefCounter);
end;

class function TPromise.CheckPromisesWereSuccessfull(Promises : array of TPromise; out ErrorMessage : string) : boolean;
var
  Promise : TPromise;
begin
  // hope the best :)
  ErrorMessage := '';
  Result := True;
  // if any promise fail, whole check failed
  for Promise in Promises do
  begin
    if not Promise.WasSuccessful then
    begin
      ErrorMessage := Promise.ErrorMessage;
      Result := False;
      exit;
    end;
  end;
end;

constructor TPromise.Create;
begin
  FCritSection := TCriticalSection.Create;
  // as usually a promise is shared by two parties and so it needs two frees to finally kill the promise
  FRefCounter := 2;
end;

destructor TPromise.Destroy;
begin
  if FRefCounter <= 0 then
  begin
    FCritSection.Free;
    inherited;
  end;
end;

procedure TPromise.FreeInstance;
begin
  if FRefCounter <= 0 then
      inherited;
end;

function TPromise.GetErrorMessage : string;
begin
  FCritSection.Enter;
  if FStatus <> psError then
      raise EPromiseException.Create('TPromise<T>.GetErrorMessage: No errormessage available, status is ' +
      HRtti.EnumerationToString<EnumPromiseStatus>(FStatus) + '.')
  else
      Result := FErrorMessage;
  FCritSection.Leave;
end;

function TPromise.GetSourceThread : TThread;
begin
  FCritSection.Enter;
  Result := FSourceThread;
  FCritSection.Leave;
end;

function TPromise.GetStatus : EnumPromiseStatus;
begin
  FCritSection.Enter;
  Result := FStatus;
  FCritSection.Leave;
end;

function TPromise.IsFinished : boolean;
begin
  Result := Status <> psWaiting;
end;

procedure TPromise.SetPromiseError(ErrorMessage : string);
begin
  FCritSection.Enter;
  assert(FStatus = psWaiting);
  FStatus := psError;
  FErrorMessage := ErrorMessage;
  FCritSection.Leave;
end;

procedure TPromise.SetThread(const Value : TThread);
begin
  FCritSection.Enter;
  FSourceThread := Value;
  FCritSection.Leave;
end;

procedure TPromise.WaitForData;
begin
  if Status = psWaiting then
  begin
    if not Assigned(SourceThread) then
        raise EPromiseException.Create('TPromise.SynchronizeWithSourceThread: No SourceThread is set.');
    {$IF Defined(MSWINDOWS)}
    WaitForSingleObject(SourceThread.Handle, INFINITE);
    {$ELSE}
    while not SourceThread.Finished do
        CheckSynchronize(1000);
    {$ENDIF}
    // Can't use waitfor, because this method will wait, until thread is finished and then get result from thread and
    // this will fail with invalid thread handle, because at this point the thread is already freed (because FreeOnTerminate = True)
    // SourceThread.WaitFor;
  end;
end;

function TPromise.WasSuccessful : boolean;
begin
  Result := Status = psSuccesful;
end;

{ TPromise<T> }

procedure TPromise<T>.CallOnFinished;
begin
  if Assigned(OnFinished) then
  begin
    // increment ref counter, because the new thread is calculated after current thread (that has created the promise)
    // ends and so any reference to promise is already freed
    inc(FRefCounter);
    HThread.DoWorkSynchronized(
      procedure
      begin
        OnFinished(self);
        // decrement manual increased refcounter
        self.Free;
      end);
  end;
end;

function TPromise<T>.GetDefaultValue : TValue;
begin
  Result := TValue.From<T>(default (T));
end;

function TPromise<T>.GetValue : T;
begin
  FCritSection.Enter;
  if FStatus <> psSuccesful then
      raise EPromiseException.Create('TPromise<T>.GetValue: Can''t get value, status is ' +
      HRtti.EnumerationToString<EnumPromiseStatus>(FStatus) + '.')
  else
      Result := FValue;
  FCritSection.Leave;
end;

procedure TPromise<T>.SetPromiseSuccessful(Value : T);
begin
  FCritSection.Enter;
  assert(FStatus = psWaiting);
  FStatus := psSuccesful;
  FValue := Value;
  FCritSection.Leave;
  CallOnFinished;
end;

procedure TPromise<T>.SetPromiseError(ErrorMessage : string);
begin
  inherited;
  CallOnFinished;
end;

procedure TPromise<T>.SetPromiseSuccessful(Value : TValue);
begin
  SetPromiseSuccessful(Value.AsType<T>);
end;

{ TRPC_API }

procedure TRpcApi.CallHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
var
  RPCInfo : TRPCMethodInfo;
  Promise : TPromise;
  Parameters : TDictionary<string, string>;
  RttiParameter : TRttiParameter;
  Counter : integer;
  Value : TValue;
  JSONData : TJSONData;
  JSONObject : TJSONObject;
begin
  // method marked for RPC
  if FRPCMethodInfos.TryGetValue(Method.Name, RPCInfo) then
  begin
    DoInvoke := False;
    Promise := RPCInfo.PromiseClass.Create;
    // collect all parameter provided by method, convert all parametername to lowercase, because usually
    // other languages, especially web, uses all lowercase
    Parameters := TDictionary<string, string>.Create();
    Counter := 0;
    if roEncapsuleParameterIntoJSONObject in RPCInfo.Options then
    begin
      JSONObject := TJSONObject.Create;
      for RttiParameter in Method.GetParameters do
      begin
        JSONObject.AddField(RttiParameter.Name, TJSONData.FromTValue(Args[Counter]));
        inc(Counter);
      end;
      Parameters.Add(RPCInfo.JSONParameterName, JSONObject.AsJSONString);
      JSONObject.Free;
    end
    else
      for RttiParameter in Method.GetParameters do
      begin
        if (RttiParameter.ParamType.TypeKind in [tkRecord, tkArray, tkDynArray, tkClass]) or (roEncodeParameterAsJson in RPCInfo.Options) then
        begin
          Value := Args[Counter];
          // direct use jsondata if given instead of convert jsondata into jsondata
          if Value.IsInstanceOf(TJSONData) then
              JSONData := Value.AsObject as TJSONData
          else
              JSONData := TJSONData.FromTValue(Value);
          Parameters.Add(RttiParameter.Name.ToLowerInvariant, JSONData.AsJSONString);
          JSONData.Free;
        end
        else
            Parameters.Add(RttiParameter.Name.ToLowerInvariant, Args[Counter].ToString);
        inc(Counter);
      end;
    // start thread that will perform the RPC call
    TRPCCallThread.Create(Promise, RPCInfo.CallerMethodType, RPCInfo.Url, RPCInfo.HTTPMethod, Parameters, TRpcApi.CookieManager);
    Result := Promise;
  end
  // not marked, work as usual
  else
      DoInvoke := True;
end;

constructor TRpcApi.Create(HostID : string);
var
  RttiContext : TRttiContext;
  RttiType : TRttiType;
  RttiMethod : TRttiMethod;
  RPC_UrlAttribute : RpcUrl;
  Protocol : string;
  RPCMethodInfo : TRPCMethodInfo;
begin
  FRPCMethodInfos := TObjectDictionary<string, TRPCMethodInfo>.Create([doOwnsValues]);
  assert(self.ClassType <> TRpcApi);
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(self.ClassType);
  // search for any method in class with RPC_Url attribute
  for RttiMethod in RttiType.GetMethods do
  begin
    if HArray.SearchClassInArray<TCustomAttribute>(RpcUrl, RttiMethod.GetAttributes, @RPC_UrlAttribute) then
    begin
      // only virtual methods can be intercepted
      if RttiMethod.DispatchKind <> dkVtable then
          raise ERPC_Exception.CreateFmt('TRpcApi.Create: In class "%s" non virtual method "%s" with RPC_Url attribute found.',
          [self.ClassName, RttiMethod.Name]);
      // only functions supported
      if RttiMethod.MethodKind <> mkFunction then
          raise ERPC_Exception.CreateFmt('TRpcApi.Create: In class "%s" non function "%s" with RPC_Url attribute found.',
          [self.ClassName, RttiMethod.Name]);
      // every function has to return a TPromise
      if not(RttiMethod.ReturnType.Name.StartsWith('TPromise') and RttiMethod.ReturnType.AsInstance.MetaclassType.InheritsFrom(TPromise)) then
          raise ERPC_Exception.CreateFmt('TRpcApi.Create: In class "%s" method "%s" with RPC_Url attribute not returning TPromise found.',
          [self.ClassName, RttiMethod.Name]);

      // should we use SSL?
      if roSSL in RPC_UrlAttribute.Options then Protocol := 'https://'
      else Protocol := 'http://';
      // relative or absolute?
      if RPC_UrlAttribute.Url.StartsWith('/') then
          RPCMethodInfo := TRPCMethodInfo.Create(Protocol, HostID, RPC_UrlAttribute.Url)
      else
          RPCMethodInfo := TRPCMethodInfo.CreateAbsolute(Protocol, RPC_UrlAttribute.Url);

      RPCMethodInfo.CallerMethodType := RttiMethod;
      RPCMethodInfo.HTTPMethod := RPC_UrlAttribute.HTTPMethod;
      RPCMethodInfo.Options := RPC_UrlAttribute.Options;
      RPCMethodInfo.JSONParameterName := RPC_UrlAttribute.JSONParameterObjectName;
      // save result promise
      RPCMethodInfo.PromiseClass := CPromise(RttiMethod.ReturnType.AsInstance.MetaclassType);
      FRPCMethodInfos.Add(RttiMethod.Name, RPCMethodInfo);
    end;
  end;
  RttiContext.Free;

  // intercept all virtual methods
  FMethodInterceptor := TVirtualMethodInterceptor.Create(self.ClassType);
  FMethodInterceptor.Proxify(self);
  FMethodInterceptor.OnBefore := CallHandler;
end;

class constructor TRpcApi.Create;
begin
  TRpcApi.CookieManager := TIdCookieManager.Create();
  TRpcApi.CallLogSendThread := TCallLogSendThread.Create;
end;

class destructor TRpcApi.Destroy;
begin
  FreeAndNil(TRpcApi.CallLogSendThread);
  FreeAndNil(TRpcApi.CookieManager);
end;

destructor TRpcApi.Destroy;
begin
  FMethodInterceptor.Unproxify(self);
  FMethodInterceptor.Free;
  FRPCMethodInfos.Free;
  inherited;
end;

class procedure TRpcApi.FlushCallLog;
begin
  FreeAndNil(TRpcApi.CallLogSendThread);
end;

{ RpcUrl }

constructor RpcUrl.Create(Url : string; HTTPMethod : EnumHttpMethod; Options : SetRPCOPtions; JSONParameterObjectName : string);
begin
  FUrl := Url;
  FHTTPMethod := HTTPMethod;
  FOptions := Options;
  FJSONParameterObjectName := JSONParameterObjectName;
end;

{ TRpcApi.TRPCMethodInfo }

constructor TRpcApi.TRPCMethodInfo.Create(Protocol, HostID, Path : string);
begin
  self.Protocol := Protocol;
  self.HostID := HostID;
  self.Path := Path;
end;

constructor TRpcApi.TRPCMethodInfo.CreateAbsolute(Protocol, HostPath : string);
begin
  self.Protocol := Protocol;
  self.Path := Path;
  FIsAbsolute := True;
end;

function TRpcApi.TRPCMethodInfo.Url : string;
var
  BaseHost : string;
begin
  // already set protocol will overwritre any other settings
  if Path.Contains('://') then Result := Path
  else if FIsAbsolute then Result := Protocol + Path
  else
  begin
    BaseHost := HRPCHostManager.ResolveHost(HostID);
    if not BaseHost.Contains('://') then
        BaseHost := Protocol + BaseHost;
    Result := BaseHost + Path;
  end;
end;

{ TRpcApi.TRPCCallThread }

constructor TRpcApi.TRPCCallThread.Create(Promise : TPromise; CallerMethodType : TRttiMethod; Url : string; HTTPMethod : EnumHttpMethod; Parameter : TDictionary<string, string>; CookieManager : TIdCookieManager);
begin
  ReturnValue := 1;
  FreeOnTerminate := True;
  FHTTPClient := TIdHttp.Create();
  FHTTPClient.Response.Clear;
  FHTTPClient.Response.ResponseCode := -1;
  FHTTPClient.ConnectTimeout := RPC_API_TIMEOUT;
  FHTTPClient.ReadTimeout := RPC_API_TIMEOUT;
  FHTTPClient.CookieManager := CookieManager;
  FParameter := Parameter;
  FHTTPMethod := HTTPMethod;
  FCallerMethodType := CallerMethodType;
  FUrl := Url;
  Promise.SourceThread := self;
  FPromise := Promise;
  inherited Create(False);
end;

destructor TRpcApi.TRPCCallThread.Destroy;
begin
  inherited;
  FHTTPClient.Free;
  FPromise.Free;
  FParameter.Free;
end;

procedure TRpcApi.TRPCCallThread.DoTerminate;
begin
  if Assigned(OnTerminate) then
      OnTerminate(self);
end;

procedure TRpcApi.TRPCCallThread.Execute;
var
  Data : TIdMultiPartFormDataStream;
  ParameterName : string;
  ResponseText : string;
  ResultValue : TValue;
  GetParameterList : TList<string>;
  GetParameter, Param : string;
  DefaultValue : TValue;
  LogItem : RCallLogItem;
  StopWatch : TTimer;
begin
  NameThreadForDebugging('RPCCallThread');
  Data := nil;
  GetParameterList := nil;
  StopWatch := TTimer.CreateAndStart(1000);
  LogItem := RCallLogItem.Empty;
  try
    try
      LogItem.Url := FUrl;
      /// /////////////////////////////////////////////////////////////////////
      /// ///////////// REQUEST ///////////////////////////////////////////////
      /// /////////////////////////////////////////////////////////////////////
      case FHTTPMethod of
        hmGET :
          begin
            GetParameterList := TList<string>.Create;
            for ParameterName in FParameter.Keys do
                GetParameterList.Add(ParameterName + '=' + FParameter[ParameterName]);
            // only need to encode parameter if there are any
            if GetParameterList.Count > 0 then
            begin
              GetParameter := TIdURI.ParamsEncode(GetParameter.join('&', GetParameterList.ToArray));
              ResponseText := FHTTPClient.Get(FUrl + '?' + GetParameter);
            end
            else
            begin
              ResponseText := FHTTPClient.Get(FUrl);
            end;
          end;

        hmPOST :
          begin
            Data := TIdMultiPartFormDataStream.Create;
            for ParameterName in FParameter.Keys do
            begin
              Param := FParameter[ParameterName];
              Data.AddFormField(ParameterName, Param, 'UTF-8', sContentTypeOctetStream).ContentTransfer := sContentTransferBinary;
            end;
            ResponseText := FHTTPClient.Post(FUrl, Data);
          end;
      else raise ENotImplemented.Create('TRpcApi.TRPCCallThread.Execute: Only GET and POST are supported.');
      end;

      /// //////////////////////////////////////////////////////////////////////
      /// /////////// PROCESS RESPONSE /////////////////////////////////////////
      /// //////////////////////////////////////////////////////////////////////
      case FHTTPClient.ResponseCode of
        200 :
          begin
            DefaultValue := FPromise.GetDefaultValue;
            // call successful and no returnvalue expected respectively not delivered
            // return
            if (DefaultValue.TypeInfo = TypeInfo(boolean)) and (ResponseText = '') then
                ResultValue := True
            else
            begin
              // if result is a mixed list of different objects, we need a more complex processing
              if HRtti.HasAttributeType(FCallerMethodType, RpcMixedObjectList) then
                  ProcessMixedObjectList(ResponseText, DefaultValue)
              else
              // else simple object mapping do the thing
              begin
                // if the raw jsondata is requested, don't cast jsondata as TValue, instead returning data
                // directly
                if DefaultValue.TypeInfo = TypeInfo(TJSONData) then
                    DefaultValue := TJSONSerializer.ParseJSON(ResponseText)
                else
                    DefaultValue := TJSONSerializer.ParseJSON(ResponseText, DefaultValue.TypeInfo);
              end;
              ResultValue := DefaultValue;
            end;
            FPromise.SetPromiseSuccessful(ResultValue);
          end
      else
        FPromise.SetPromiseError(inttostr(FHTTPClient.ResponseCode) + ': ' + FHTTPClient.ResponseText);
      end;
    except
      on HttpError : EIdHTTPProtocolException do
      begin
        case FHTTPClient.ResponseCode of
          500 :
            begin
              // {$IFDEF WINDOWS}
              // ForceDirectories(FormatDateiPfad('\Error_500\'));
              // HString.SaveStringToFile(FormatDateiPfad('\Error_500\error500.html'), HttpError.ErrorMessage);
              // shellExecute(0, 'open', PChar(FormatDateiPfad('\Error_500\error500.html')), '', '', 0);
              // {$ENDIF}
              FPromise.SetPromiseError(HttpError.ErrorCode.ToString);
            end;
          405 : FPromise.SetPromiseError(inttostr(10));
          400 : FPromise.SetPromiseError(HttpError.ErrorMessage);
        else FPromise.SetPromiseError(HttpError.Message);
        end;
      end;
      on e : EIdSocketError do
          FPromise.SetPromiseError('TIMEOUT');
      on e : EIdConnectTimeout do
          FPromise.SetPromiseError('TIMEOUT');
      on e : EIdConnClosedGracefully do
          FPromise.SetPromiseError('BLOCKED');
      on e : Exception do
          FPromise.SetPromiseError(e.ClassName + ': ' + e.Message);
    end;
  finally
    try
      if Assigned(TRpcApi.CallLogSendThread) then
      begin
        if not FPromise.WasSuccessful then
            LogItem.error := FPromise.ErrorMessage;
        LogItem.status_code := FHTTPClient.ResponseCode;
        LogItem.response_time := Round(StopWatch.TimeSinceStart);
        TRpcApi.CallLogSendThread.AddCallLogItem(LogItem);
      end;
    except
      HLog.Log('TRpcApi.TRPCCallThread.Execute: Logging call "' + FUrl + '" failed.');
    end;
    StopWatch.Free;
    Data.Free;
    GetParameterList.Free;
  end;
end;

procedure TRpcApi.TRPCCallThread.ProcessMixedObjectList(const JSONRawData : string; var ResultValue : TValue);
var
  ListType : TRttiDynamicArrayType;
  BaseClass : TRttiInstanceType;
  DerivedClass : TRttiType;
  IdentifierClassMap : TDictionary<string, TRttiType>;
  DerivedClassAttribute : RpcMixedClassDescendant;
  MixedObjectListAttribute : RpcMixedObjectList;
  JSONData : TJSONData;
  JSONArray : TJSONArray;
  JSONObject : TJSONObject;
  TypeIdentifier : string;
  i : integer;
  ArraySize : NativeInt;
  ItemValue : TValue;
  RttiContext : TRttiContext;
begin
  RttiContext := TRttiContext.Create;
  MixedObjectListAttribute := RpcMixedObjectList(HRtti.GetAttribute(FCallerMethodType.GetAttributes, RpcMixedObjectList));
  IdentifierClassMap := TDictionary<string, TRttiType>.Create();
  assert(ResultValue.Kind = tkDynArray);
  ListType := TRttiDynamicArrayType(RttiContext.GetType(ResultValue.TypeInfo));
  BaseClass := ListType.ElementType.AsInstance;
  assert(HRtti.HasAttribute(BaseClass.GetAttributes, RpcMixedBaseClass));
  // build type identifier -> derived class map
  for DerivedClass in RttiContext.GetTypes do
  begin
    if DerivedClass.IsInstance and DerivedClass.AsInstance.MetaclassType.InheritsFrom(BaseClass.MetaclassType)
      and not(DerivedClass.Handle = BaseClass.Handle) then
    begin
      // ignore as abstract marked classes
      if not HRtti.HasAttribute(DerivedClass.GetAttributes, RPCMixedAbstractClass) then
      begin
        DerivedClassAttribute := RpcMixedClassDescendant(HRtti.GetAttribute(DerivedClass.GetAttributes, RpcMixedClassDescendant));
        if Assigned(DerivedClassAttribute) then
            IdentifierClassMap.Add(DerivedClassAttribute.TypeIdentifier.ToLowerInvariant, DerivedClass.AsInstance)
        else
            raise ERPC_Exception.CreateFmt('TRpcApi.TRPCCallThread.ProcessMixedObjectList: Derived class "%s" without attribute RpcMixedClassDescendant is not supported.', [DerivedClass.Name]);
      end;
    end;
  end;
  JSONData := TJSONSerializer.ParseJSON(JSONRawData);
  if JSONData.IsArray then
  begin
    JSONArray := JSONData.AsArray;
    // adjust arraysize
    ArraySize := JSONArray.Count;
    DynArraySetLength(Pointer(ResultValue.GetReferenceToRawData^), ResultValue.TypeInfo, 1, @ArraySize);
    // fill array with data
    for i := 0 to JSONArray.Count - 1 do
    begin
      assert(JSONArray[i].IsObject);
      JSONObject := JSONArray[i].AsObject;
      // read type for next array element
      TypeIdentifier := JSONObject.Field[MixedObjectListAttribute.TypeIdentifierField].AsValue.AsString.ToLowerInvariant;
      if IdentifierClassMap.TryGetValue(TypeIdentifier, DerivedClass) then
      begin
        // convert the data of current json array item to target type
        ItemValue := JSONObject.Field[MixedObjectListAttribute.TypeDataField].AsTValue(DerivedClass.Handle);
        ResultValue.SetArrayElement(i, ItemValue);
      end
      else raise ERPC_Exception.CreateFmt('TRpcApi.TRPCCallThread.ProcessMixedObjectList: No derived class from baseclass "%s" with type identifier "%s" found.', [BaseClass.Name, TypeIdentifier]);
    end;
  end
  else raise ERPC_Exception.Create('TRpcApi.TRPCCallThread.ProcessMixedObjectList: For mixed object list an array was expected.');
  IdentifierClassMap.Free;
  JSONData.Free;
  RttiContext.Free;
end;

{ RpcHandler }

constructor RpcHandler.Create(Url : string);
begin
  FUrl := Url;
end;

{ TRPCHandlerManager }

procedure TRPCHandlerManager.CallHandlers(Url, Parameter : string);
var
  lowerIdentifier : string;
  Handler : TRPCHandler;
begin
  // user lowercase to ensure code is case insensitive
  lowerIdentifier := Url.ToLowerInvariant;
  if not(FHandlers.ContainsKey(lowerIdentifier) and (FHandlers[lowerIdentifier].Count > 0)) then
      raise ENotFoundException.CreateFmt('TRPCHandlerManager.CallHandlers: For identifier "%s" no handler was found.', [Url]);
  for Handler in FHandlers[lowerIdentifier] do
      Handler.Call(Parameter);
end;

function TRPCHandlerManager.CallHandlerWithResult(MethodIdentifier, Parameter : string) : TValue;
var
  lowerIdentifier : string;
begin
  // user lowercase to ensure code is case insensitive
  lowerIdentifier := MethodIdentifier.ToLowerInvariant;
  if not(FHandlers.ContainsKey(lowerIdentifier) and (FHandlers[lowerIdentifier].Count > 0)) then
      raise ENotFoundException.CreateFmt('TRPCHandlerManager.CallHandlers: For identifier "%s" no handler was found.', [MethodIdentifier]);
  // if there are more than one handler for RPC call is registered, returning a value would be ambiguous
  if FHandlers[lowerIdentifier].Count > 1 then
      raise ERPC_Exception.CreateFmt('TRPCHandlerManager.CallHandlerWithResult: For identifier "%s" more than one handler was found', [MethodIdentifier]);
  if not FHandlers[lowerIdentifier].First.IsFunction then
      raise ERPC_Exception.CreateFmt('TRPCHandlerManager.CallHandlerWithResult: Handler with identifier "%s" doesn''t return any value.', [MethodIdentifier]);
  Result := FHandlers[lowerIdentifier].First.Call(Parameter);
end;

constructor TRPCHandlerManager.Create;
begin
  FHandlers := TObjectDictionary < string, TObjectList < TRPCHandler >>.Create([doOwnsValues]);
  FRttiContext := TRttiContext.Create;
end;

class constructor TRPCHandlerManager.Create;
begin
  RPCHandlerManager := TRPCHandlerManager.Create;
end;

class destructor TRPCHandlerManager.Destroy;
begin
  RPCHandlerManager.Free;
end;

destructor TRPCHandlerManager.Destroy;
begin
  FHandlers.Free;
  FRttiContext.Free;
  inherited;
end;

procedure TRPCHandlerManager.SubscribeHandler(HandlerObject : TObject);

  function GetAttributesForInterfaces(AClass : TClass; MethodName : string) : TArray<TCustomAttribute>;
  var
    i : integer;
    InterfaceTable : PInterfaceTable;
    InterfaceEntry : PInterfaceEntry;
    RttiType : TRttiType;
    RttiMethod : TRttiMethod;
  begin
    Result := nil;
    while Assigned(AClass) do
    begin
      // look in every interface that this class implements, if a method with attribute
      // was found
      InterfaceTable := AClass.GetInterfaceTable;
      if Assigned(InterfaceTable) then
      begin
        for i := 0 to InterfaceTable.EntryCount - 1 do
        begin
          InterfaceEntry := @InterfaceTable.Entries[i];
          for RttiType in FRttiContext.GetTypes do
          begin
            if (RttiType.TypeKind = tkInterface) and (InterfaceEntry.IID = TRttiInterfaceType(RttiType).GUID) then
            begin
              for RttiMethod in RttiType.GetMethods do
                if SameText(RttiMethod.Name, MethodName) then
                begin
                  Result := RttiMethod.GetAttributes;
                  exit();
                end;
            end;
          end;
        end;
      end;
      AClass := AClass.ClassParent;
    end;
  end;

var
  RttiType : TRttiType;
  RttiMethod : TRttiMethod;
  attribute : RpcHandler;
  lowerIdentifier : string;
begin
  RttiType := FRttiContext.GetType(HandlerObject.ClassType);
  // check for every method of object, if method is tagged with RPCHandler attribute
  // every tagged method will be a endpoint for a call
  for RttiMethod in RttiType.GetMethods do
  begin
    if HArray.SearchClassInArray<TCustomAttribute>(RpcHandler, RttiMethod.GetAttributes
      + GetAttributesForInterfaces(HandlerObject.ClassType, RttiMethod.Name), @attribute) then
    begin
      // user lowercase to ensure code is case insensitive
      lowerIdentifier := attribute.Url.ToLowerInvariant;
      // ensure list for handlers for identifer exists
      if not FHandlers.ContainsKey(lowerIdentifier) then
          FHandlers.Add(lowerIdentifier, TObjectList<TRPCHandler>.Create());
      // add new handler
      FHandlers[lowerIdentifier].Add(TRPCHandler.Create(RttiMethod, HandlerObject));
    end;
  end;
end;

procedure TRPCHandlerManager.UnsubscribeHandler(HandlerObject : TObject);
var
  lowerIdentifier : string;
  Handlers : TObjectList<TRPCHandler>;
  i : integer;
begin
  // remove handler if this use target object (regardless of method, because use of nil object would result in KABUMMM)
  for lowerIdentifier in FHandlers.Keys do
  begin
    Handlers := FHandlers[lowerIdentifier];
    for i := Handlers.Count - 1 downto 0 do
    begin
      if Handlers[i].TargetObject = HandlerObject then
          Handlers.Delete(i);
    end;
  end;
end;

{ TRPCHandlerManager.TRPCHandler }

function TRPCHandlerManager.TRPCHandler.Call(Parameter : string) : TValue;
var
  parameterJSON : TJSONObject;
  RttiParameter : TRttiParameter;
  ParameterValueArray : TArray<TValue>;
  i : integer;
begin
  parameterJSON := nil;
  if FMethodHandler.ParameterCount > 0 then
  begin
    parameterJSON := TJSONSerializer.ParseJSON(Parameter).AsObject;
    // check count match
    if parameterJSON.FieldCount <> FMethodHandler.ParameterCount then
        raise ERPC_Exception.CreateFmt('TRPCHandlerManager.TRPCHandler.Call: Parametercount of method "%s" and received data does not match.',
        [FMethodHandler.Name]);
    i := 0;
    setLength(ParameterValueArray, FMethodHandler.ParameterCount);
    for RttiParameter in FMethodHandler.GetParameters do
    begin
      // is there any data for parameter?
      if not parameterJSON.HasField(RttiParameter.Name) then
          raise ERPC_Exception.CreateFmt('TRPCHandlerManager.TRPCHandler.Call: Parameter "%s" for method "%s" is missing in JSONData.',
          [RttiParameter.Name, FMethodHandler.Name])
      else
      // alright, then lets transfrom JSONData into usable binary data
      begin
        ParameterValueArray[i] := parameterJSON.Field[RttiParameter.Name].AsTValue(RttiParameter.ParamType.Handle)
      end;
      inc(i);
    end;
    assert(i = FMethodHandler.ParameterCount);
  end
  // no parameter, no array with data needed
  else
      ParameterValueArray := nil;
  // finally make the call
  Result := FMethodHandler.Invoke(FTargetObject, ParameterValueArray);
  parameterJSON.Free;
end;

constructor TRPCHandlerManager.TRPCHandler.Create(MethodHandler : TRttiMethod; TargetObject : TObject);
begin
  FTargetObject := TargetObject;
  FMethodHandler := MethodHandler;
end;

function TRPCHandlerManager.TRPCHandler.IsFunction : boolean;
begin
  Result := FMethodHandler.MethodKind in [mkFunction, mkConstructor, mkClassFunction];
end;

{$IFDEF WINDOWS}

{ TApiBroker }

procedure TApiBroker.Connect;
begin
  assert(not(FBrokerAddress.IsEmpty and FSessionKey.IsEmpty));
  FTCPConnection := TTCPClientSocketDeluxe.Create(RInetAddress.Create(BrokerAddress));
  FTCPConnection.SendData(NETMYSESSIONID, [SessionKey]);
end;

constructor TApiBroker.Create;
begin
  // nothing to be done here :)
end;

constructor TApiBroker.CreateAndConnect(BrokerAddress, SessionKey : string);
begin
  FBrokerAddress := BrokerAddress;
  FSessionKey := SessionKey;
  Connect;
end;

destructor TApiBroker.Destroy;
begin
  FTCPConnection.Free;
  inherited;
end;

procedure TApiBroker.Idle;
var
  Data : TDatapacket;
  error : EnumBrokerError;
  Identifier, Parameter : string;
begin
  if Assigned(FTCPConnection) then
  begin
    FTCPConnection.Idle;
    error := beNoError;
    while FTCPConnection.IsDataPacketAvailable do
    begin
      error := beNoError;
      Data := FTCPConnection.ReceiveDataPacket;
      case Data.Command of
        NETNEWDATA :
          begin
            Identifier := Data.ReadString;
            Parameter := Data.ReadString;
            RPCHandlerManager.CallHandlers(Identifier, Parameter);
          end;
        NETSERVERSHUTDOWNERROR : error := beServerShutdown;
        NETANOTHERLOGINERROR : error := beAnotherLogin;
        NETTIMEOUTERROR : error := beTimeOut;
        NETSECURITYERROR : error := beSecurityError;
      else error := beUnknownError;
      end;
      Data.Free;
    end;
    if error <> beNoError then
    begin
      // if any error occurs, connection is no longer usable, so best choice is kill connection
      FreeAndNil(FTCPConnection);
      if Assigned(FOnError) then FOnError(error)
      else
          raise EBrokerException.CreateFmt('TApiBroker: An error "%s" occured.',
          [HRtti.EnumerationToString<EnumBrokerError>(error)]);
    end;
  end;
end;

function TApiBroker.isConnected : boolean;
begin
  Result := Assigned(FTCPConnection) and (FTCPConnection.Status = TCPStConnected);
end;

{$ENDIF}

{ HRPCHostManager }

class constructor HRPCHostManager.Create;
begin
  FHosts := TDictionary<string, string>.Create();
  DefaultHost := 'localhost:8000';
end;

class destructor HRPCHostManager.Destroy;
begin
  FHosts.Free;
end;

class
  function HRPCHostManager.ResolveHost(HostID : string) : string;
begin
  if not FHosts.TryGetValue(HostID.ToLowerInvariant, Result) then Result := DefaultHost;
end;

class
  procedure HRPCHostManager.SetHost(HostID, HostBase : string);
begin
  FHosts.AddOrSetValue(HostID.ToLowerInvariant, HostBase);
end;

{ RpcMixedObjectList }

constructor RpcMixedObjectList.Create(TypeIdentifierField, TypeDataField : string);
begin
  FTypeIdentifierField := TypeIdentifierField;
  FTypeDataField := TypeDataField;
end;

{ RpcMixedClassDescendant }

constructor RpcMixedClassDescendant.Create(TypeIdentifier : string);
begin
  FTypeIdentifier := TypeIdentifier;
end;

{ TRpcApi.TCallLogSendThread }

procedure TRpcApi.TCallLogSendThread.AddCallLogItem(const LogItem : RCallLogItem);
begin
  // hacky hardcoded soluation
  if not LogItem.Url.Contains('/api/account/send_api_log/') then
  begin
    FCallLog.Add(LogItem);
    FCallLogItemAdded.SetEvent;
  end;
end;

constructor TRpcApi.TCallLogSendThread.Create;
var
  Uid : TGuid;
begin
  FCallLog := TThreadList<RCallLogItem>.Create;
  CreateGuid(Uid);
  FCallLogItemAdded := TEvent.Create(nil, True, False, GuidToString(Uid));
  inherited Create(False);
end;

destructor TRpcApi.TCallLogSendThread.Destroy;
begin
  inherited;
  FCallLogItemAdded.Free;
  FCallLog.Free;
end;

procedure TRpcApi.TCallLogSendThread.Execute;
var
  DataList : TList<RCallLogItem>;
  Data : TArray<RCallLogItem>;
  WaitResult : TWaitResult;
begin
  while not Terminated do
  begin
    WaitResult := FCallLogItemAdded.WaitFor(500);
    // only send data if signal was really triggered and not if timeout occurs or any other event occurs
    if (WaitResult = TWaitResult.wrSignaled) or Terminated then
    begin
      FCallLogItemAdded.ResetEvent;
      if Assigned(TRpcApi.OnCallLogDataAvailable) then
      begin
        Data := nil;
        DataList := FCallLog.LockList;
        if (DataList.Count > 20) or Terminated then
        begin
          Data := DataList.ToArray;
          DataList.Clear;
        end;
        FCallLog.UnlockList;
        if Data <> nil then
            TRpcApi.OnCallLogDataAvailable(Data);
      end;
    end;
  end;
end;

{ RCallLogItem }

class function RCallLogItem.Empty : RCallLogItem;
begin
  Result.Url := '';
  Result.status_code := -1;
  Result.error := '';
  Result.response_time := -1;
end;

end.
