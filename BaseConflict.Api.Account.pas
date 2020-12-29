unit Baseconflict.Api.Account;

interface

uses
  // ----------- Delphi ------------
  System.Math,
  System.SysUtils,
  System.Generics.Collections,
  System.DateUtils,
  System.UITypes,
  System.Classes,
  Vcl.Dialogs,
  // ---------- ThirdParty --------
  {$IFDEF CLIENT}
  steam_api,
  steamclientpublic,
  isteamuser_,
  {$ENDIF}
  {$IFDEF MADEXCEPT}
  madExcept,
  {$ENDIF}
  // ----------- Engine ------------
  Engine.Log,
  Engine.Math,
  Engine.Network,
  Engine.Network.RPC,
  Engine.Helferlein,
  Engine.Helferlein.Threads,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Serializer.JSON,
  Engine.DataQuery,
  Engine.dXML,
  // ----------- Game ------------
  Baseconflict.Constants,
  Baseconflict.Api,
  Baseconflict.Api.Types;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished, vcPrivate]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$M+}
  ELoginError = class(Exception);

  /// <summary> Class that provide some information for a friend or a person. TFriend stand not mandatory for a friend. It is also
  /// possible, that it stands for a person who has requested a friendship to you or some similar.</summary>
  TPerson = class
    private
      FIsCurrentUser : boolean;
      FPersonID, FFriendID : integer;
      FSteamID : UInt64;
      FCurrentGame : RGameFoundData;
    strict private
      FStatus : EnumChatAPIStatus;
      FName, FIcon : string;
      procedure SetStatus(const Value : EnumChatAPIStatus); virtual;
      procedure SetName(const Value : string); virtual;
      procedure SetIcon(const Value : string); virtual;
      procedure SetGameFoundData(const Value : RGameFoundData); virtual;
    published
      property name : string read FName write SetName;
      property Status : EnumChatAPIStatus read FStatus write SetStatus;
      property Icon : string read FIcon write SetIcon;
      /// <summary> By creating the current user at login, this will be set once. </summary>
      property IsCurrentUser : boolean read FIsCurrentUser;
      property CurrentGame : RGameFoundData read FCurrentGame write SetGameFoundData;
      [dXMLDependency('.CurrentGame')]
      function HasValidGame : boolean;
    public
      property SteamID : UInt64 read FSteamID;
      property PersonID : integer read FPersonID;
      property FriendID : integer read FFriendID;
      constructor Create(const Name : string; Status : EnumChatAPIStatus; PersonID : integer; Icon : string);
      function IsOnline : boolean;
  end;

  EnumLoginStatus = (lsNone, lsPending, lsSuccess, lsInvalidCredentials, lsConnectionFailed, lsUnknownError);

  /// <summary> The accountclass offers methods for accountmanaging and authentification. This class is the topclass
  /// in the dependencyhierarchie of all classes.</summary>
  TAccount = class(TInterfacedObject, IAccountBackchannel)
    private type
      EnumAuthenticationMethod = (amNotSet, amPassword, amSteam);

      TBackchannelPollingThread = class(TThread)
        strict private
        const
          POLLING_TIME = 1000; // ms
        strict private
          FPollingTimer : TTimer;
          FAccount : TAccount;
        protected
          procedure Execute; override;
        public
          constructor Create(Account : TAccount);
          destructor Destroy; override;
      end;

    private
      FPlayerOnlinePromise : TPromise<integer>;
      FOwnID : integer;
      FName : string;
      FPassword : string;
      FSessionKey, FBrokerAddress : string;
      /// <summary> If true, broker is used as backchannel</summary>
      FUseBroker : boolean;
      FForceBrokerFallback : boolean;
      FAuthenticationMethod : EnumAuthenticationMethod;
      FOwn : TPerson;
      // servertime on login - only for debug or info, not direcly used
      FServertimeOnLogin : TDatetime;
      // servertime delta
      FServertimeDelta : double;
      /// <summary> Saves a list of all persons known be loggedin user, this is the pool for every other servercommunicationcomponent,
      /// like chat or matchmaking, so every persons that exists in the system is hold by the accountclass.</summary>
      FPersonsKnown : TUltimateObjectList<TPerson>;
      FBackchannelSuspended : boolean;
      FBackchannelSuspendQueue : TQueue<RTuple<string, string>>;
      FBackchannelConnection : TWebSocketClient;
      FBackchannelPollingThread : TBackchannelPollingThread;
      /// <summary> Will set to true when broker has received at least one frame from broker.</summary>
      FBackchannelAnyDataReceived : boolean;
      {$IFDEF CLIENT}
      FSteamTicketHandle : HAuthTicket;
      FSteamTicketValid : boolean;
      procedure SteamAuthTicketCallback(const Data : GetAuthSessionTicketResponse_t);
      {$ENDIF}
      function GetOwnID : integer;
      procedure LoginFinished(const Response : RLoginReturn);
      procedure ActivateBackchannelFallback;
      function GetServertime : TDatetime;
      procedure SendDataToBackchannel(const Identifier : string; const Parameter : string);
    strict private
      FLoginStatus : EnumLoginStatus;
      FStatus : EnumAccountStatus;
      FCurrentPlayersOnline : integer;
      FBuildID : integer;
      procedure SetCurrentPlayersOnline(const Value : integer); virtual;
      procedure SetLoginStatus(const Value : EnumLoginStatus); virtual;
      procedure SetStatus(const Value : EnumAccountStatus); virtual;
      procedure SetBuildID(const Value : integer); virtual;
    published
      property CurrentPlayersOnline : integer read FCurrentPlayersOnline write SetCurrentPlayersOnline;
      property Own : TPerson read FOwn;
      property LoginStatus : EnumLoginStatus read FLoginStatus write SetLoginStatus;
      /// <summary> Current status of the account. Only if status = connected, other class that depend on this class will work.</summary>
      property Status : EnumAccountStatus read FStatus write SetStatus;
      property CurrentBuildID : integer read FBuildID write SetBuildID;
    public
      property ForceBrokerFallback : boolean read FForceBrokerFallback write FForceBrokerFallback;
      /// <summary> Socket that is the backchannel to server. So over this socket the server can send data to client.</summary>
      property BackchannelSocket : TWebSocketClient read FBackchannelConnection;
      /// <summary> The own id of current logged in user, if user not logged in, this value will be -1.</summary>
      property OwnID : integer read GetOwnID;
      /// <summary> Will return current servertime by using localtime and servertimedelta. This time is only one time synchronized
      /// on login. So is possible that gap between real servertime and this "fake" servertime is <= 5 seconds. </summary>
      property Servertime : TDatetime read GetServertime;
      /// <summary> Returns true if account is connected to server, else returns false
      /// HINT: Also returns false if account is currently connecting.</summary>
      function IsConnected : boolean;
      function IsBrokerFallbackActive : boolean;
      /// <summary> Log user with given credentials in.</summary>
      procedure LoginWithPassword(const Name, Password : string);
      /// <summary> Login on server using steam auth.</summary>
      procedure LoginWithSteam;
      /// <summary> Relogin to server, if user is offline. Use saved credentials.</summary>
      procedure ReLogin;
      /// <summary> Disconnect from server. All other services that requires a authenticated connection
      /// will not work correctly anymore.</summary>
      procedure Logout;
      /// <summary> Suspend backchannel per storing all incoming backchannel data instead of redirect it
      /// to system and call backchannels. Backchannel will stayed suspended, until ResumeBackchannel is called.</summary>
      procedure SuspendBackchannel;
      procedure ResumeBackchannel;
      /// <summary> Checks if backchannel is healthy and activate fallback if not.</summary>
      procedure CheckBackchannelOrActivateFallback;
      /// <summary> </summary>
      procedure Idle;
      /// <summary> Sends feedback to Admins.</summary>
      procedure SendFeedback(const Feedback : string);
      function GetPerson(const PersonID : integer; const Name : string = ''; const Icon : string = '') : TPerson; overload;
      function GetPerson(const MatchmakingUser : RMatchmakingUser) : TPerson; overload;
      function GetPerson(const ChatAPIFriend : RChatAPIFriend) : TPerson; overload;
      function GetPerson(const GameInfoPlayer : RClientGameStatisticPlayer) : TPerson; overload;

      procedure UpdateCurrentPlayersOnline;
      /// <summary> Init account but will NOT login.
      /// <param name="UseBroker"> If True, on login connection to broker is etablished and all data from broker will
      /// be handled. </param></summary>
      constructor Create(UseBroker : boolean = True);
      /// <summary> Will logout if current status is not offline and free all memory.</summary>
      destructor Destroy; override;
  end;

  TServerState = class(TInterfacedObject, IServerStateBackchannel)
    protected
      procedure LoadData(const Data : RServerState);
    private
      function CurrentServerTime : TDatetime;
      // backchannel
      procedure ServerStateChanged(Data : RServerState);
    strict private// general
      FServerOffline : boolean;
      FMaxCurrentPlayerOnline : integer;
      procedure SetServerOffline(const Value : boolean); virtual;
      procedure SetMaxCurrentPlayerOnline(const Value : integer); virtual;
    strict private// server issue
      FClientDashboardHeadline : string;
      FClientDashboardText : string;
      FClientTournamentDatetime : TDatetime;
      FClientServerIssuesEnabled : boolean;
      FClientServerIssuesWobbel : boolean;
      FClientServerIssuesText : string;
      FClientServerIssuesWobbelMuted : boolean;
      procedure SetClientTournamentDatetime(const Value : TDatetime); virtual;
      procedure SetClientServerIssuesWobbelMuted(const Value : boolean); virtual;
      procedure SetMaintenanceWobbelMuted(const Value : boolean); virtual;
      procedure SetClientDashboardHeadline(const Value : string); virtual;
      procedure SetClientDashboardText(const Value : string); virtual;
      procedure SetClientServerIssuesEnabled(const Value : boolean); virtual;
      procedure SetClientServerIssuesText(const Value : string); virtual;
      procedure SetClientServerIssuesWobbel(const Value : boolean); virtual;
    strict private// maintenance
      FMaintenanceModeEnabled : boolean;
      FMaintenanceDatetime : TDatetime;
      FMaintenanceBlockingtimeBefore : integer;
      FServertimeDelta : double;
      FMaintenanceDuration : integer;
      FMaintenanceRemainingTimeUntilEnd : integer;
      FMaintenanceRemainingTimeToBegin : integer;
      FMaintenanceWobbelMuted : boolean;
      procedure SetMaintenanceBlockingtimeBefore(const Value : integer); virtual;
      procedure SetMaintenanceDatetime(const Value : TDatetime); virtual;
      procedure SetMaintenanceModeEnabled(const Value : boolean); virtual;
      procedure SetMaintenanceDuration(const Value : integer); virtual;
      procedure SetMaintenanceRemainingTimeToBegin(const Value : integer); virtual;
      procedure SetMaintenanceRemainingTimeUntilEnd(const Value : integer); virtual;
    strict private// connections
      FLoginQueueAddress : string;
      procedure SetLoginQueueAddress(const Value : string); virtual;
    published
      property ServerOffline : boolean read FServerOffline write SetServerOffline;
      property MaxCurrentPlayerOnline : integer read FMaxCurrentPlayerOnline write SetMaxCurrentPlayerOnline;
      property ClientDashboardHeadline : string read FClientDashboardHeadline write SetClientDashboardHeadline;
      property ClientDashboardText : string read FClientDashboardText write SetClientDashboardText;
      property ClientServerIssuesEnabled : boolean read FClientServerIssuesEnabled write SetClientServerIssuesEnabled;
      property ClientServerIssuesWobbel : boolean read FClientServerIssuesWobbel write SetClientServerIssuesWobbel;
      property ClientServerIssuesText : string read FClientServerIssuesText write SetClientServerIssuesText;
      property ClientServerIssuesWobbelMuted : boolean read FClientServerIssuesWobbelMuted write SetClientServerIssuesWobbelMuted;
      procedure MuteServerIssue;
      property ClientTournamentDatetime : TDatetime read FClientTournamentDatetime write SetClientTournamentDatetime;
      [dXMLDependency('.ClientTournamentDatetime')]
      function IsTournamentUpcoming : boolean;

      property MaintenanceModeEnabled : boolean read FMaintenanceModeEnabled write SetMaintenanceModeEnabled;
      property MaintenanceDatetime : TDatetime read FMaintenanceDatetime write SetMaintenanceDatetime;
      property MaintenanceBlockingtimeBefore : integer read FMaintenanceBlockingtimeBefore write SetMaintenanceBlockingtimeBefore;
      property MaintenanceDuration : integer read FMaintenanceDuration write SetMaintenanceDuration;
      property MaintenanceWobbelMuted : boolean read FMaintenanceWobbelMuted write SetMaintenanceWobbelMuted;
      procedure MuteMaintenance;

      property LoginQueueAddress : string read FLoginQueueAddress write SetLoginQueueAddress;

      /// <summary> Returns True, if server is current under maintenance. Any requests sended to server while maintenance will
      /// fail with error_code 5.</summary>
      [dXMLDependency('.MaintenanceModeEnabled', '.MaintenanceDatetime')]
      function IsMaintenanceActive : boolean;
      [dXMLDependency('.MaintenanceModeEnabled', '.MaintenanceDatetime', '.MaintenanceBlockingtimeBefore')]
      function MaintenanceCanEnterQueues : boolean;

      property MaintenanceRemainingTimeToBegin : integer read FMaintenanceRemainingTimeToBegin write SetMaintenanceRemainingTimeToBegin;
      property MaintenanceRemainingTimeUntilEnd : integer read FMaintenanceRemainingTimeUntilEnd write SetMaintenanceRemainingTimeUntilEnd;
    public
      constructor Create();
      function UpdateServerStateSynchronous : boolean;
      procedure UpdateServerStateAsynchronous;
      /// <summary> Update Times. </summary>
      procedure Idle;
      destructor Destroy; override;
  end;

  [AQCriticalAction]
  TAccountActionLogin = class(TPromiseAction)
    private
      FAccount : TAccount;
      FName : string;
      FPassword : string;
    public
      constructor Create(Account : TAccount; const Name, Password : string);
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TAccountActionActivateFallback = class(TPromiseAction)
    private
      FAccount : TAccount;
    public
      constructor Create(Account : TAccount);
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
  end;

  TAccountActionSendFeedback = class(TPromiseAction)
    private
      FFeedback : string;
    public
      property Feedback : string read FFeedback;
      constructor Create(Feedback : string);
      function Execute : boolean; override;
  end;

  /// <summary> Parent class for any action targeting deckmanager.</summary>
  TServerStateActionLoadData = class(TPromiseAction)
    private
      FServerState : TServerState;
    public
      constructor Create(ServerState : TServerState);
      function Execute : boolean; override;
  end;
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  Account : TAccount;
  ServerState : TServerState;

implementation

{$IFDEF CLIENT}
uses
  Baseconflict.Globals.Client,
  Baseconflict.Api.Profile;
{$ENDIF}

{ TPerson }

procedure TPerson.SetGameFoundData(const Value : RGameFoundData);
begin
  FCurrentGame := Value;
end;

procedure TPerson.SetIcon(const Value : string);
begin
  FIcon := Value;
end;

procedure TPerson.SetName(const Value : string);
begin
  FName := Value;
end;

procedure TPerson.SetStatus(const Value : EnumChatAPIStatus);
begin
  if InRange(ord(Value), ord(low(EnumChatAPIStatus)), ord(high(EnumChatAPIStatus))) then
      FStatus := Value
  else FStatus := EnumChatAPIStatus.csOffline;
end;

constructor TPerson.Create(const Name : string; Status : EnumChatAPIStatus; PersonID : integer; Icon : string);
begin
  FName := name;
  SetStatus(Status);
  FPersonID := PersonID;
  FIcon := Icon;
end;

function TPerson.HasValidGame : boolean;
begin
  Result := self.CurrentGame.game_uid <> '';
end;

function TPerson.IsOnline : boolean;
begin
  Result := Status <> csOffline;
end;

{ TAccount }

procedure TAccount.ActivateBackchannelFallback;
begin
  AccountAPI.SendCustomBugReport('Broker fallback got activated.', HLog.ReadLog).Free;
  FStatus := asConnected;
  FLoginStatus := lsSuccess;
  FBackchannelPollingThread := TBackchannelPollingThread.Create(self);
end;

procedure TAccount.CheckBackchannelOrActivateFallback;
begin
  if not FBackchannelAnyDataReceived and not IsBrokerFallbackActive and not ForceBrokerFallback then
      MainActionQueue.DoAction(TAccountActionActivateFallback.Create(self));
end;

constructor TAccount.Create(UseBroker : boolean);
begin
  FUseBroker := UseBroker;
  FStatus := asDisconnected;
  FPersonsKnown := TUltimateObjectList<TPerson>.Create();
  FBackchannelSuspendQueue := TQueue < RTuple < string, string >>.Create;
end;

function TAccount.GetOwnID : integer;
begin
  if Status = asConnected then
      Result := FOwnID
  else Result := -1;
end;

function TAccount.GetPerson(const GameInfoPlayer : RClientGameStatisticPlayer) : TPerson;
begin
  Result := GetPerson(GameInfoPlayer.user_id, GameInfoPlayer.username);
  Result.FSteamID := GameInfoPlayer.steam_id;
  Result.FFriendID := GameInfoPlayer.friend_id;
  Result.Icon := GameInfoPlayer.playericon;
end;

function TAccount.GetPerson(const ChatAPIFriend : RChatAPIFriend) : TPerson;
begin
  Result := GetPerson(ChatAPIFriend.ID, ChatAPIFriend.Name, ChatAPIFriend.Icon);
  Result.Status := ChatAPIFriend.Status;
  Result.FSteamID := ChatAPIFriend.steam_id;
end;

function TAccount.GetServertime : TDatetime;
begin
  Result := now() + FServertimeDelta;
end;

function TAccount.GetPerson(const MatchmakingUser : RMatchmakingUser) : TPerson;
begin
  Result := GetPerson(MatchmakingUser.ID, MatchmakingUser.username)
end;

function TAccount.GetPerson(const PersonID : integer; const Name, Icon : string) : TPerson;
begin
  // search for with person with given ID (because ID is the unqiue identifier, Name can change)
  Result := FPersonsKnown.Query.Get(F('PersonID') = PersonID, True);
  // until now person is unknown
  if not assigned(Result) then
  begin
    if not name.IsEmpty then
    begin
      Result := TPerson.Create(name, csOffline, PersonID, Icon);
      FPersonsKnown.Add(Result);
    end
    else raise EAccountError.CreateFmt('TAccount.GetPerson: Can''t find target person with ID "%d".', [PersonID]);
  end;
end;

procedure TAccount.Idle;
var
  Frame : TWebSocketClientFrame;
  Data : TJSONObject;
  Identifier, Parameter : string;
begin
  if IsConnected and assigned(FBackchannelConnection) then
  begin
    if FBackchannelConnection.IsConnected then
    begin
      while assigned(FBackchannelConnection) and FBackchannelConnection.IsFrameAvailable do
      begin
        if not FBackchannelAnyDataReceived then
        begin
          FBackchannelAnyDataReceived := True;
          HLog.Log('Broker: Received frist frame from broker.');
        end;
        Frame := FBackchannelConnection.ReceiveFrame;
        Data := TJSONSerializer.ParseJson(Frame.TextPayload).AsObject;
        Identifier := Data['identifier'].AsValue.AsString;
        Parameter := Data['parameter'].AsValue.AsString;
        Data.Free;
        Frame.Free;
        SendDataToBackchannel(Identifier, Parameter);
      end;
    end
    else
        Status := asDisconnected;
  end;
  if assigned(FPlayerOnlinePromise) and FPlayerOnlinePromise.IsFinished and (FPlayerOnlinePromise.Status = psSuccesful) then
  begin
    CurrentPlayersOnline := FPlayerOnlinePromise.Value;
    FreeAndNil(FPlayerOnlinePromise);
  end;
end;

function TAccount.IsBrokerFallbackActive : boolean;
begin
  Result := assigned(FBackchannelPollingThread);
end;

function TAccount.IsConnected : boolean;
begin
  Result := Status = asConnected;
end;

procedure TAccount.UpdateCurrentPlayersOnline;
begin
  if not assigned(FPlayerOnlinePromise) then
      FPlayerOnlinePromise := AccountAPI.GetCurrentPlayerOnline;
end;

destructor TAccount.Destroy;
begin
  FBackchannelPollingThread.Free;
  Logout;
  FreeAndNil(FPlayerOnlinePromise);
  // I know this are duplicates, because logout will already do the job, but for overview
  FBackchannelConnection.Free;
  FPersonsKnown.Free;
  FBackchannelSuspendQueue.Free;
  inherited;
end;

procedure TAccount.LoginWithPassword(const Name, Password : string);
begin
  if Status = asDisconnected then
  begin
    LoginStatus := lsPending;
    Status := asConnecting;
    FName := name;
    FPassword := Password;
    FOwn := GetPerson(-1, name);
    FOwn.Name := name;
    FOwn.FIsCurrentUser := True;
    FOwn.Status := csOnline;
    MainActionQueue.DoAction(TAccountActionLogin.Create(self, name, Password));
  end
  else; // ReportError(ecAlreadyLoggedIn);
end;

procedure TAccount.LoginFinished(const Response : RLoginReturn);
begin
  {$IFDEF MADEXCEPT}
  MESettings.MailFrom := Response.own_id.ToString;
  {$ENDIF}
  FreeAndNil(FBackchannelConnection);
  FSessionKey := Response.session_key;
  FBrokerAddress := Response.broker_address;
  FOwnID := Response.own_id;
  FName := Response.own_name;
  FOwn.FPersonID := Response.own_id;
  FOwn.Name := Response.own_name;
  FServertimeOnLogin := Response.Servertime;
  FServertimeDelta := Response.Servertime - now();
  if FUseBroker then
  begin
    if ForceBrokerFallback then
    begin
      HLog.Log('Force Broker Fallback');
      Status := asConnected;
      LoginStatus := lsSuccess;
      MainActionQueue.DoAction(TAccountActionActivateFallback.Create(self));
    end
    else
    begin
      HLog.Log('Open connection to broker');
      assert(not FBrokerAddress.IsEmpty);
      assert(not FSessionKey.IsEmpty);
      FBackchannelAnyDataReceived := False;
      FBackchannelConnection := TWebSocketClient.Create();
      FBackchannelConnection.Connect(FBrokerAddress + '?session_key=' + FSessionKey + '&user_id=' + FOwnID.ToString);
      if FBackchannelConnection.IsConnected then
      begin
        HLog.Log('Connected to broker');
        Status := asConnected;
        LoginStatus := lsSuccess;
      end
      else
      begin
        HLog.Log('Connection to broker failed');
        Status := asDisconnected;
        LoginStatus := lsConnectionFailed;
      end;
    end;
  end
  else
  begin
    Status := asConnected;
    LoginStatus := lsSuccess;
  end;
end;

procedure TAccount.LoginWithSteam;
{$IFDEF CLIENT}
const
  STEAM_LOGIN_TIMEOUT = 15;

  function TryGetSteamTicket(out EncodedSteamTicket : string) : boolean;
  var
    Timer : TTimer;
    TicketBuffer : TBytes;
    TicketLength : UInt32;
  begin
    HLog.Log('Try to get steam ticket');
    HSteamAPI<GetAuthSessionTicketResponse_t>.RegisterCallback(SteamAuthTicketCallback);
    FSteamTicketValid := False;
    setLength(TicketBuffer, 1024);
    FSteamTicketHandle := SteamUser.GetAuthSessionTicket(@TicketBuffer[0], length(TicketBuffer), TicketLength);
    if FSteamTicketHandle <> k_HAuthTicketInvalid then
    begin
      setLength(TicketBuffer, TicketLength);
      EncodedSteamTicket := EncodeBase16(TicketBuffer);

      Timer := TTimer.CreateAndStart(STEAM_LOGIN_TIMEOUT * 1000);

      HLog.Log('Wait for response');
      while not(Timer.Expired or FSteamTicketValid) do
      begin
        SteamAPI_RunCallbacks();
      end;
      if Timer.Expired and not FSteamTicketValid then
          HLog.Log('Failed - No response from Steam within ' + STEAM_LOGIN_TIMEOUT.ToString + ' seconds.');
      Timer.Free;
    end
    else
        HLog.Log('Failed - Steam created an invalid ticked');
    HSteamAPI<GetAuthSessionTicketResponse_t>.UnregisterCallback(SteamAuthTicketCallback);
    Result := FSteamTicketValid;
  end;

  procedure GetLocalVersion(out SteamAppBuildId : integer; out BranchName : string);
  begin
    SteamAppBuildId := SteamApps.GetAppBuildId;
    CurrentBuildID := SteamAppBuildId;
    HLog.Log('SteamBuildID: ' + SteamAppBuildId.ToString);
    if not SteamApps.GetCurrentBetaName(BranchName) then
        BranchName := 'public';
    HLog.Log('Branch: ' + BranchName);
  end;

  function HandlePromiseError(Promise : TPromise; out SteamError : boolean) : boolean;
  begin
    Result := True;
    if not Promise.WasSuccessful then
    begin
      Result := False;
      SteamError := False;
      if Promise.ErrorMessage.Contains('TIMEOUT') then
      begin
        // metaserver could not be reached
        HLog.Log('Failed - metaserver timeout');
        raise ENetworkException.Create('Could not connect to "Rise of Legions" network');
      end
      else if Promise.ErrorMessage = ord(ecSteamInternalError).ToString then
      begin
        // steam has internal error - give user ability to retry
        HLog.Log('Failed - steam internal error');
        SteamError := True;
      end
      else if Promise.ErrorMessage = ord(ecSteamAppWrongVersion).ToString then
      begin
        // version is wrong
        HLog.Log('Failed - version outdated');
        SteamApps.MarkContentCorrupt(False);
        raise ESteamException.Create('Gameclient is not up-to-date, please update and restart the client.');
      end
      else
      begin
        // metaserver has an undefined error
        HLog.Log('Failed - metaserver internal error');
        raise ENetworkException.Create('The "Rise of Legions" server responded with an internal error');
      end;
    end
    else
        HLog.Log('Successful');
  end;

var
  EncodedSteamTicket : string;
  LoginPromise : TPromise<RLoginReturn>;
  VersionCheckPromise : TPromise<boolean>;
  LoginData : RLoginReturn;
  SteamAppBuildId : integer;
  BranchName : string;
  FirstTry, SteamError : boolean;
  {$ENDIF}
begin
  {$IFDEF CLIENT}
  if Status = asDisconnected then
  begin
    FAuthenticationMethod := amSteam;
    LoginStatus := lsPending;
    FirstTry := True;

    // give the player the ability to retry to connect if steam is the problem
    while True do
    begin
      HLog.Log('');
      HLog.Log('Logging in with Steam' + HGeneric.TertOp<string>(FirstTry, '', ' - Retry'));
      if not FirstTry then
      begin
        PreventIdle := True;
        if MessageDlg('Could not connect to Steam. Please check your internet connection and Steam status.', mtError, [mbRetry, mbAbort], 0, mbRetry) <> mrRetry then
        begin
          ReportMemoryLeaksOnShutdown := False;
          halt;
        end;
        PreventIdle := False;
        HLog.Log('Next try to log in with Steam');
      end
      else FirstTry := False;

      if not TryGetSteamTicket(EncodedSteamTicket) then
          continue;
      HLog.Log('Successful - Steam ticket valid');

      GetLocalVersion(SteamAppBuildId, BranchName);

      LoginPromise := nil;
      VersionCheckPromise := nil;
      try
        HLog.Log('Metaserver tries to login with steam ticket');
        LoginPromise := AccountAPI.LoginWithSteam(EncodedSteamTicket);
        LoginPromise.WaitForData;
        if not HandlePromiseError(LoginPromise, SteamError) then
        begin
          if SteamError then
              continue
          else
          begin
            // metaserver has an undefined error
            HLog.Log('Failed - metaserver responded with false');
            raise ENetworkException.Create('The "Rise of Legions" server rejected your login request');
          end;
        end;
        HLog.Log('Successful - Login on Metaserver successful');

        HLog.Log('Checking version');
        VersionCheckPromise := AccountAPI.CheckGameVersion(SteamAppBuildId, BranchName);
        VersionCheckPromise.WaitForData;
        if not HandlePromiseError(VersionCheckPromise, SteamError) then
        begin
          if SteamError then
              continue
          else
          begin
            // metaserver has an undefined error
            HLog.Log('Failed - metaserver responded with false');
            raise ENetworkException.Create('The "Rise of Legions" server rejected version check request');
          end;
        end;
        HLog.Log('Successful - Version is up-to-date');

        LoginData := LoginPromise.Value;
        FOwn := GetPerson(LoginData.own_id, LoginData.own_name);
        FOwn.FIsCurrentUser := True;
        FOwn.Status := csOnline;
        LoginFinished(LoginData);
        break;
      finally
        LoginPromise.Free;
        VersionCheckPromise.Free;
      end;
    end;
  end;
  {$ELSE}
  raise ENotImplemented.Create('Only client can use steam login');
  {$ENDIF}
end;

procedure TAccount.Logout;
var
  boolPromise : TPromise<boolean>;
begin
  FreeAndNil(FBackchannelConnection);
  // don't do a logout by webrequest, because if program is closed while request, server will raise
  // an error or if client wait until request is finsihed, a slow server will annoy the user, because
  // the user want to leave quickly a program.
  // This is also not really necessary, because closing the connection to broker, will automatically
  // report the webhost and this will close the connection to the user
  // AccountAPI.Logout.WaitForData;
  // but if no broker is used, we still need to logout on his own
  if not FUseBroker and (LoginStatus <> lsNone) then
  begin
    boolPromise := ManageServerAPI.UserDisconnected(self.OwnID);
    boolPromise.WaitForData;
    boolPromise.Free;
  end;
  LoginStatus := lsNone;
  FStatus := asDisconnected;
  // clear all persons as the current user might change after a relogin
  FPersonsKnown.Clear;
end;

procedure TAccount.ReLogin;
begin
  case FAuthenticationMethod of
    amNotSet : raise ELoginError.Create('Player has not logged in yet.');
    amPassword : LoginWithPassword(FName, FPassword);
    amSteam : LoginWithSteam();
  end;
end;

procedure TAccount.ResumeBackchannel;
var
  Item : RTuple<string, string>;
begin
  if FBackchannelSuspended then
  begin
    FBackchannelSuspended := False;
    while FBackchannelSuspendQueue.Count > 0 do
    begin
      Item := FBackchannelSuspendQueue.Dequeue;
      RPCHandlerManager.CallHandlers(Item.a, Item.b);
    end;
  end;
end;

procedure TAccount.SendDataToBackchannel(const Identifier, Parameter : string);
begin
  // ignore pong, only for server to force backchannel use
  if not SameText(Identifier, '/pong/') then
  begin
    if FBackchannelSuspended then
        FBackchannelSuspendQueue.Enqueue(RTuple<string, string>.Create(Identifier, Parameter))
    else
        RPCHandlerManager.CallHandlers(Identifier, Parameter);
  end;
end;

procedure TAccount.SendFeedback(const Feedback : string);
begin
  MainActionQueue.DoAction(TAccountActionSendFeedback.Create(Feedback));
end;

procedure TAccount.SetBuildID(const Value : integer);
begin
  FBuildID := Value;
end;

procedure TAccount.SetCurrentPlayersOnline(const Value : integer);
begin
  FCurrentPlayersOnline := Value;
end;

procedure TAccount.SetLoginStatus(const Value : EnumLoginStatus);
begin
  FLoginStatus := Value;
end;

procedure TAccount.SetStatus(const Value : EnumAccountStatus);
begin
  FStatus := Value;
end;

{$IFDEF CLIENT}


procedure TAccount.SteamAuthTicketCallback(const Data : GetAuthSessionTicketResponse_t);
begin
  if FSteamTicketHandle = Data.m_hAuthTicket then
  begin
    if Data.m_eResult = k_EResultOK then
        FSteamTicketValid := True
    else
        HLog.Log('Ticket callback failed with error code %d.', [ord(Data.m_eResult)]);
  end
  else
      HLog.Log('Ticket callback failed as handle is outdated.');
end;
{$ENDIF}


procedure TAccount.SuspendBackchannel;
begin
  FBackchannelSuspended := True;
end;

{ TAccountActionLogin }

constructor TAccountActionLogin.Create(Account : TAccount; const Name, Password : string);
begin
  inherited Create();
  FAccount := Account;
  FName := name;
  FPassword := Password;
end;

function TAccountActionLogin.Execute : boolean;
var
  Promise : TPromise<RLoginReturn>;
  intPromise : TPromise<integer>;
  ReturnValue : RLoginReturn;
  ErrorCode : EnumErrorCode;
begin
  Promise := AccountAPI.Login(FName, FPassword);
  Promise.WaitForData;

  // assume connecting works, because some connection does not signal a successfull connection,
  // instead they only signal errors and then the result will be falsed
  Result := True;
  try
    assert(Promise.Status <> psWaiting);
    if Promise.WasSuccessful then
    begin
      ReturnValue := Promise.Value;
      // should broker be used as backchannel or is this app provide his own backchannel
      if FAccount.FUseBroker then FAccount.LoginFinished(ReturnValue)
      else
      // if no broker is used, the app has to inform the server on his own about login
      begin
        FAccount.FSessionKey := ReturnValue.session_key;
        FAccount.FOwnID := ReturnValue.own_id;
        FAccount.FServertimeOnLogin := ReturnValue.Servertime;
        FAccount.FServertimeDelta := ReturnValue.Servertime - now();
        intPromise := ManageServerAPI.UserConnected(ReturnValue.session_key);
        intPromise.WaitForData;
        if intPromise.WasSuccessful then
        begin
          assert(intPromise.Value = FAccount.FOwnID);
          FAccount.LoginFinished(ReturnValue);
        end
        else
        begin
          Result := False;
          ErrorCode := intPromise.ErrorAsErrorCode;
        end;
        intPromise.Free;
      end;
    end
    else
    begin
      Result := False;
      ErrorCode := Promise.ErrorAsErrorCode;
    end;
  except
    Result := False;
    ErrorCode := ecServerNoResponse;
  end;

  DoSynchronized(
    procedure
    begin
      if ErrorCode in [ecServerNoResponse, ecRequestTimeOut] then
          FAccount.LoginStatus := lsConnectionFailed
      else if ErrorCode in [ecUnknownUsername, ecWrongPassword] then
          FAccount.LoginStatus := lsInvalidCredentials
      else
          FAccount.LoginStatus := lsUnknownError;
    end);

  // no need to set status, this will be managed by rollback, only provide
  // errormessage
  if not Result then FErrorMsg := ErrorCodeToString(ErrorCode);

  Promise.Free;
end;

procedure TAccountActionLogin.Rollback;
begin
  FAccount.Status := asDisconnected;
end;

{ TAccountActionSendFeedback }

constructor TAccountActionSendFeedback.Create(Feedback : string);
begin
  inherited Create;
  FFeedback := Feedback;
end;

function TAccountActionSendFeedback.Execute : boolean;
begin
  Result := True;
  HandlePromise(AccountAPI.SendFeedback(Feedback));
end;

{ TServerState }

constructor TServerState.Create();
begin
  FServerOffline := True;
  RPCHandlerManager.SubscribeHandler(self);
end;

function TServerState.CurrentServerTime : TDatetime;
begin
  Result := now() + FServertimeDelta;
end;

destructor TServerState.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  inherited;
end;

procedure TServerState.UpdateServerStateAsynchronous;
begin
  MainActionQueue.DoAction(TServerStateActionLoadData.Create(self));
end;

procedure TServerState.Idle;
var
  NewMaintenanceRemainingTimeToBegin, NewMaintenanceRemainingTimeUntilEnd : integer;
begin
  if MaintenanceModeEnabled then
  begin
    if CurrentServerTime <= MaintenanceDatetime then
    begin
      NewMaintenanceRemainingTimeToBegin := SecondsBetween(CurrentServerTime, MaintenanceDatetime);
      NewMaintenanceRemainingTimeUntilEnd := NewMaintenanceRemainingTimeToBegin + MaintenanceDuration;
    end
    else
    begin
      NewMaintenanceRemainingTimeToBegin := 0;
      NewMaintenanceRemainingTimeUntilEnd := Max(MaintenanceDuration - SecondsBetween(CurrentServerTime, MaintenanceDatetime), 0);
    end;
    // only set values if changed
    if NewMaintenanceRemainingTimeToBegin <> MaintenanceRemainingTimeToBegin then
    begin
      // notify CanEnterQueue, hardfix for now
      MaintenanceModeEnabled := MaintenanceModeEnabled;
      MaintenanceRemainingTimeToBegin := NewMaintenanceRemainingTimeToBegin;
    end;
    if NewMaintenanceRemainingTimeUntilEnd <> MaintenanceRemainingTimeUntilEnd then
        MaintenanceRemainingTimeUntilEnd := NewMaintenanceRemainingTimeUntilEnd;
  end;
end;

function TServerState.IsMaintenanceActive : boolean;
begin
  Result := MaintenanceModeEnabled and (MaintenanceDatetime <= CurrentServerTime);
end;

function TServerState.IsTournamentUpcoming : boolean;
begin
  Result := (CurrentServerTime <= ClientTournamentDatetime);
end;

procedure TServerState.LoadData(const Data : RServerState);
begin
  ServerOffline := Data.server_offline;
  MaxCurrentPlayerOnline := Data.max_current_player_online;
  FServertimeDelta := now() - Data.server_time;

  ClientDashboardHeadline := Data.client_dashboard_headline;
  ClientDashboardText := Data.client_dashboard_text;
  ClientTournamentDatetime := Data.client_dashboard_tournament_datetime;

  ClientServerIssuesEnabled := Data.client_server_issues_enabled;
  ClientServerIssuesWobbel := Data.client_server_issues_wobbel;
  ClientServerIssuesText := Data.client_server_issues_text;

  MaintenanceModeEnabled := Data.maintenance_mode_enabled;
  MaintenanceDatetime := Data.maintenance_datetime;
  MaintenanceBlockingtimeBefore := Data.maintenance_blockingtime_before;
  MaintenanceDuration := Data.maintenance_duration;

  LoginQueueAddress := Data.login_queue_address;
end;

function TServerState.MaintenanceCanEnterQueues : boolean;
begin
  Result := not MaintenanceModeEnabled or // no maintenance everything normal
    IsMaintenanceActive or                // during maintenance all BypassMaintenance Tester can enter queue
    (SecondsBetween(CurrentServerTime, MaintenanceDatetime) > MaintenanceBlockingtimeBefore); // before maintenance and in blockingtime, no entrance
end;

procedure TServerState.MuteMaintenance;
begin
  if not MaintenanceWobbelMuted then
      MaintenanceWobbelMuted := True;
end;

procedure TServerState.MuteServerIssue;
begin
  if not ClientServerIssuesWobbelMuted then
      ClientServerIssuesWobbelMuted := True;
end;

procedure TServerState.ServerStateChanged(Data : RServerState);
begin
  LoadData(Data);
end;

procedure TServerState.SetClientDashboardHeadline(const Value : string);
begin
  FClientDashboardHeadline := Value;
end;

procedure TServerState.SetClientDashboardText(const Value : string);
begin
  FClientDashboardText := Value;
end;

procedure TServerState.SetClientServerIssuesEnabled(const Value : boolean);
begin
  if Value and not FClientServerIssuesEnabled and ClientServerIssuesWobbelMuted then
      ClientServerIssuesWobbelMuted := False;
  FClientServerIssuesEnabled := Value;
end;

procedure TServerState.SetClientServerIssuesText(const Value : string);
begin
  FClientServerIssuesText := Value;
end;

procedure TServerState.SetClientServerIssuesWobbel(const Value : boolean);
begin
  FClientServerIssuesWobbel := Value;
end;

procedure TServerState.SetClientServerIssuesWobbelMuted(const Value : boolean);
begin
  FClientServerIssuesWobbelMuted := Value;
end;

procedure TServerState.SetClientTournamentDatetime(const Value : TDatetime);
begin
  FClientTournamentDatetime := Value;
end;

procedure TServerState.SetLoginQueueAddress(const Value : string);
begin
  FLoginQueueAddress := Value;
end;

procedure TServerState.SetMaintenanceBlockingtimeBefore(const Value : integer);
begin
  FMaintenanceBlockingtimeBefore := Value;
end;

procedure TServerState.SetMaintenanceDatetime(const Value : TDatetime);
begin
  FMaintenanceDatetime := Value;
end;

procedure TServerState.SetMaintenanceDuration(const Value : integer);
begin
  FMaintenanceDuration := Value;
end;

procedure TServerState.SetMaintenanceModeEnabled(const Value : boolean);
begin
  if Value and not FMaintenanceModeEnabled and MaintenanceWobbelMuted then
      MaintenanceWobbelMuted := False;
  FMaintenanceModeEnabled := Value;
end;

procedure TServerState.SetMaintenanceRemainingTimeToBegin(
  const Value : integer);
begin
  FMaintenanceRemainingTimeToBegin := Value;
end;

procedure TServerState.SetMaintenanceRemainingTimeUntilEnd(
  const Value : integer);
begin
  FMaintenanceRemainingTimeUntilEnd := Value;
end;

procedure TServerState.SetMaintenanceWobbelMuted(const Value : boolean);
begin
  FMaintenanceWobbelMuted := Value;
end;

procedure TServerState.SetMaxCurrentPlayerOnline(const Value : integer);
begin
  FMaxCurrentPlayerOnline := Value;
end;

procedure TServerState.SetServerOffline(const Value : boolean);
begin
  FServerOffline := Value;
end;

function TServerState.UpdateServerStateSynchronous : boolean;
var
  Action : TServerStateActionLoadData;
begin
  Action := TServerStateActionLoadData.Create(self);
  Result := Action.Execute;
  Action.Free;
end;

{ TServerStateActionLoadData }

constructor TServerStateActionLoadData.Create(ServerState : TServerState);
begin
  inherited Create();
  FServerState := ServerState;
end;

function TServerStateActionLoadData.Execute : boolean;
var
  Promise : TPromise<RServerState>;
  error_code : integer;
begin
  Promise := AccountAPI.GetServerState;
  Promise.WaitForData;
  if Promise.WasSuccessful or (TryStrToInt(Promise.ErrorMessage, error_code) and (error_code = ord(EnumErrorCode.ecMaintenance))) then
  begin
    DoSynchronized(
      procedure()
      var
        Data : RServerState;
      begin
        if Promise.WasSuccessful then
            Data := Promise.Value
        else
        begin
          FillChar(Data, SizeOf(Data), 0);
          Data.server_offline := True;
        end;
        FServerState.LoadData(Data);
      end);
  end
  else if True then
      HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

{ TAccountActionActivateFallback }

constructor TAccountActionActivateFallback.Create(Account : TAccount);
begin
  FAccount := Account;
  inherited Create();
end;

function TAccountActionActivateFallback.Execute : boolean;
var
  Promise : TPromise<boolean>;
begin
  Promise := AccountAPI.ActivateFallback();
  Promise.WaitForData;
  Result := HandlePromise(Promise);
end;

function TAccountActionActivateFallback.ExecuteSynchronized : boolean;
begin
  FAccount.ActivateBackchannelFallback;
  Result := True;
end;

{ TAccount.TBackchannelPollingThread }

constructor TAccount.TBackchannelPollingThread.Create(Account : TAccount);
begin
  FAccount := Account;
  FPollingTimer := TTimer.CreateAndStart(POLLING_TIME);
  inherited Create;
end;

destructor TAccount.TBackchannelPollingThread.Destroy;
begin
  inherited;
  AccountAPI.DeactivateFallback.Free;
  FPollingTimer.Free;
end;

procedure TAccount.TBackchannelPollingThread.Execute;
var
  BrokerDataPromise : TPromise<ARBrokerData>;
  BrokerData : ARBrokerData;
  BrokerDataItem : RBrokerData;
  LastItemIdReceived : integer;
begin
  LastItemIdReceived := -1;
  while not Terminated do
  begin
    FPollingTimer.Start;
    BrokerDataPromise := AccountAPI.PollBrokerData();
    BrokerDataPromise.WaitForData;
    if BrokerDataPromise.WasSuccessful then
    begin
      BrokerData := BrokerDataPromise.Value;
      for BrokerDataItem in BrokerData do
      begin
        if BrokerDataItem.ID > LastItemIdReceived then
        begin
          LastItemIdReceived := BrokerDataItem.ID;
          DoSynchronized(
            procedure()
            begin
              FAccount.SendDataToBackchannel(BrokerDataItem.url, BrokerDataItem.Data);
            end);
        end;
      end;
    end;
    BrokerDataPromise.Free;
    while not(FPollingTimer.Expired or Terminated) do
        sleep(50);
  end;
end;

end.
