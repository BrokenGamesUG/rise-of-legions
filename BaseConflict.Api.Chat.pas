unit BaseConflict.Api.Chat;

interface

uses
  // Delphi
  System.Math,
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Vcl.Clipbrd,
  // Third Party
  steam_api,
  isteamfriends_,
  // Engine
  Engine.dXML,
  Engine.Network,
  Engine.Network.RPC,
  Engine.Helferlein.Threads,
  Engine.Helferlein.Datastructures,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.DataQuery,
  // Game
  BaseConflict.Constants,
  BaseConflict.Api,
  BaseConflict.Api.Types,
  BaseConflict.Api.Account;

type

  {$RTTI EXPLICIT METHODS([vcPrivate, vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$M+}
  TFriendRequest = class(TInterfacedObject)
    public type
      EnumRequestType = (rtUndefined, rtSended, rtReceived);
    private
      FRequestID : integer;
      FOtherPerson : TPerson;
      FRequestType : EnumRequestType;
      constructor Create(const Account : TAccount; const Request : RChatApiRequest);
    public
      property RequestType : EnumRequestType read FRequestType;
      property OtherPerson : TPerson read FOtherPerson;
      function Name : string;
      function IsIncoming : boolean;
      procedure Accept();
      procedure Decline();
      destructor Destroy; override;
  end;

  TFriendProposal = class
    strict private
      FName : string;
      FSteamID : int64;
      FFriendID : integer;
    published
      property SteamID : int64 read FSteamID;
      property FriendID : integer read FFriendID;
      property name : string read FName;
      procedure SendRequest;
    public
      constructor Create(const Name : string; SteamID : int64; FriendID : integer);
  end;

  ProcFriendStatusChanged = procedure(const Friend : TPerson) of object;

  ProcRequestAnswered = procedure(const Friend : TPerson; Accepted : boolean) of object;
  ProcRequestReceived = procedure(const FriendRequest : TFriendRequest) of object;

  ProcNewPrivateMessage = procedure(Context : TPerson; Sender : TPerson; const Message : string; TimeStamp : TDateTime) of object;

  TFriendlist = class;

  TFriendlist = class(TInterfacedObject, IFriendlistBackchannel, IFriendRequestBackchannel)
    private
      FOwnStatus : EnumChatAPIStatus;
      FFriends : TUltimateList<TPerson>;
      FRequests : TUltimateObjectList<TFriendRequest>;
      FOnRequestAnswered : ProcRequestAnswered;
      FOnFriendRequest : ProcRequestReceived;
      FAccount : TAccount;
      FFriendProposals : TUltimateObjectList<TFriendProposal>;
      procedure SetOwnStatus(const Value : EnumChatAPIStatus);
      procedure SignalOwnStatusChanged;
      /// ================== Backchannel Friendlist BEGIN=======================
      procedure FriendStatusChanged(Friend : RChatAPIFriend);
      procedure FriendAdded(Friend : RChatAPIFriend);
      procedure FriendRemoved(Friend : RChatAPIFriend);
      /// ================== Backchannel Friendlist END ========================
      /// ================== Backchannel FriendRequest BEGIN====================
      procedure FriendRequestAnswered(Accepted : boolean; Request_ID : integer);
      procedure FriendRequestDeleted(Request_ID : integer);
      procedure FriendRequestReceived(Request : RChatApiRequest);
      /// ================== Backchannel FriendRequest END =====================
      function IsFriendByID(PersonID : integer) : boolean;
      function GetFriend(PersonID : integer) : TPerson;
    strict private
      FFriendID : integer;
      procedure SetFriendID(const Value : integer); virtual;
    published
      property FriendID : integer read FFriendID write SetFriendID;
      /// <summary> All steamfriends that current player have which has also a account in game.</summary>
      property FriendProposals : TUltimateObjectList<TFriendProposal> read FFriendProposals;
      procedure CopyFriendIDToClipboard;

      /// <summary> Current friends that are listed.</summary>
      property Friends : TUltimateList<TPerson> read FFriends;
      [dXMLDependency('.Friends')]
      function FriendCount : integer;
      /// <summary> A list of all requests that which are sended to or received by a other person.</summary>
      property Requests : TUltimateObjectList<TFriendRequest> read FRequests;
      [dXMLDependency('.Requests')]
      function RequestCount : integer;
    public
      property Owner : TAccount read FAccount;
      /// <summary> Own status. Status is recoverd from last session, so if set to busy and go offline and then online again,
      /// status is still busy. If you change your status, any friend will be informed.</summary>
      property OwnStatus : EnumChatAPIStatus read FOwnStatus write SetOwnStatus;
      /// <summary> Event called if any friend request you sent have been answered.</summary>
      /// <param name="Friend"> Person who has answered the request.</param>
      property OnRequestAnswered : ProcRequestAnswered read FOnRequestAnswered write FOnRequestAnswered;
      property OnFriendRequest : ProcRequestReceived read FOnFriendRequest write FOnFriendRequest;
      function TryGetFriend(PersonID : integer; out Friend : TPerson) : boolean;
      /// <summary> Return True if given person is your friend, else return false.</summary>
      [dXMLDependency('.Friends')]
      function IsFriend(Friend : TPerson) : boolean;
      procedure AddUserToFriendlist(FriendID : integer);
      /// <summary> Break up the friendship to target person and in conclusion remove them from friendlist.</summary>
      procedure RemoveFriendFromList(Friend : TPerson);
      /// <summary> Create the friendlist and load all data from server.
      /// HINT: The friendlist expect that the user is logged in on the server, else the creation will fail.</summary>
      constructor Create(Account : TAccount);
      /// <summary> KADABUMM!</summary>
      destructor Destroy; override;
  end;

  TChatSystem = class(TInterfacedObject, IChatBackchannel)
    private
      FFriendlist : TFriendlist;
      FOnNewPrivateMessage : ProcNewPrivateMessage;
      procedure NewChatMessage(Msg : RChatMessage);
    public
      property OnNewPrivateMessage : ProcNewPrivateMessage write FOnNewPrivateMessage;
      /// <summary> Sends a message to friend on you friendlist.</summary>
      /// <param name="Receiver"> Receiver of the message. If receiver isn't on your friendlist, method will raise an exception.</param>
      procedure SendPrivateMessage(Receiver : TPerson; const Msg : string);
      /// <summary> Alloc memory and init chatsystem</summary>
      /// <param name="Friendlist"> Base friendlist which the system works. E.g. needs to send a private message.</param>
      constructor Create(Friendlist : TFriendlist);
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  TFriendlistAction = class(TPromiseAction)
    private
      FFriendlist : TFriendlist;
    public
      constructor Create(Friendlist : TFriendlist);
  end;

  [AQCriticalAction]
  TFriendlistActionLoadFriendlist = class(TFriendlistAction)
    public
      function Execute : boolean; override;
  end;

  [AQCriticalAction]
  TFriendlistActionLoadFriendProposals = class(TFriendlistAction)
    public
      function Execute : boolean; override;
  end;

  [AQCriticalAction]
  TFriendlistActionLoadStatus = class(TFriendlistAction)
    public
      function Execute : boolean; override;
  end;

  TFriendlistActionAddUserToFriendlist = class(TPromiseAction)
    private
      FFriend_UID : integer;
    public
      constructor Create(Friend_UID : integer);
      function Execute : boolean; override;
  end;

  TFriendlistActionRemoveFromFriendlist = class(TPromiseAction)
    private
      FFriend : TPerson;
    public
      constructor Create(Friend : TPerson);
      function Execute : boolean; override;
  end;

  TFriendRequestActionAnswer = class(TPromiseAction)
    private
      FRequest : TFriendRequest;
      FAccept : boolean;
    public
      property Request : TFriendRequest read FRequest;
      property Accept : boolean read FAccept;
      constructor Create(Request : TFriendRequest; Accept : boolean);
      function Execute : boolean; override;
  end;

  TChatSystemActionSendPrivateMessage = class(TPromiseAction)
    private
      FMessage : string;
      FReceiver : TPerson;
    public
      constructor Create(Receiver : TPerson; AMessage : string);
      function Execute : boolean; override;
  end;

  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
var
  Friendlist : TFriendlist;
  ChatSystem : TChatSystem;

implementation

{ TChatSystem }

constructor TChatSystem.Create(Friendlist : TFriendlist);
begin
  assert(assigned(Friendlist));
  FFriendlist := Friendlist;
  RPCHandlerManager.SubscribeHandler(self);
end;

destructor TChatSystem.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  inherited;
end;

procedure TChatSystem.NewChatMessage(Msg : RChatMessage);
var
  Sender, Context : TPerson;
begin
  // chatroom id <> 0 -> is no private message, else it is a message for a chatroom thats the player has jpoi
  if Msg.chatroom_id = 0 then
  begin
    if assigned(FOnNewPrivateMessage) then
    begin
      if Msg.Sender_ID = FFriendlist.FAccount.OwnID then
      begin
        Sender := FFriendlist.FAccount.Own;
        Context := FFriendlist.GetFriend(Msg.receiver_id);
      end
      else
      begin
        Sender := FFriendlist.GetFriend(Msg.Sender_ID);
        Context := Sender;
      end;
      if Sender <> nil then
          FOnNewPrivateMessage(Context, Sender, Msg.text_message, Msg.TimeStamp)
      else
          raise EChatError.Create('TChatSystem.NewChatMessage: Message from unknown person.');
    end;
  end
  else raise ENotImplemented.Create('TChatSystem.NewChatMessage: Chatrooms.');
end;

procedure TChatSystem.SendPrivateMessage(Receiver : TPerson; const Msg : string);
begin
  // Receiver is really a friend?
  if FFriendlist.IsFriend(Receiver) then
  begin
    if SteamUtils.IsOverlayEnabled then
    begin
      SteamFriends.ActivateGameOverlayToUser('chat', Receiver.SteamID);
    end
    // MainActionQueue.DoAction(TChatSystemActionSendPrivateMessage.Create(Receiver, Msg));
  end;
end;

{ TFriendlist }

procedure TFriendlist.AddUserToFriendlist(FriendID : integer);
begin
  MainActionQueue.DoAction(TFriendlistActionAddUserToFriendlist.Create(FriendID));
end;

procedure TFriendlist.CopyFriendIDToClipboard;
begin
  Clipboard.AsText := Inttostr(FriendID);
end;

constructor TFriendlist.Create(Account : TAccount);
begin
  FAccount := Account;
  FFriends := TUltimateList<TPerson>.Create();
  FFriendProposals := TUltimateObjectList<TFriendProposal>.Create;
  FRequests := TUltimateObjectList<TFriendRequest>.Create;
  MainActionQueue.DoAction(TFriendlistActionLoadStatus.Create(self));
  MainActionQueue.DoAction(TFriendlistActionLoadFriendlist.Create(self));
  {$IFDEF STEAM}
  MainActionQueue.DoAction(TFriendlistActionLoadFriendProposals.Create(self));
  {$ENDIF}
  RPCHandlerManager.SubscribeHandler(self);
end;

destructor TFriendlist.Destroy;
begin
  FFriends.Free;
  FFriendProposals.Free;
  FRequests.Free;
  RPCHandlerManager.UnsubscribeHandler(self);
  inherited;
end;

procedure TFriendlist.FriendAdded(Friend : RChatAPIFriend);
var
  Person : TPerson;
begin
  // avoid asyncproblems
  if not IsFriendByID(Friend.ID) then
  begin
    Person := FAccount.GetPerson(Friend);
    FFriends.Add(Person);
  end;
  MainActionQueue.DoAction(TFriendlistActionLoadFriendProposals.Create(self));
end;

function TFriendlist.FriendCount : integer;
begin
  Result := Friends.Count;
end;

procedure TFriendlist.FriendRemoved(Friend : RChatAPIFriend);
var
  index : integer;
begin
  index := Friends.Query.GetIndex(F('PersonID') = Friend.ID);
  if index >= 0 then
      FFriends.Delete(index);
  MainActionQueue.DoAction(TFriendlistActionLoadFriendProposals.Create(self));
end;

procedure TFriendlist.FriendRequestAnswered(Accepted : boolean; Request_ID : integer);
var
  Request : TFriendRequest;
begin
  Request := Requests.Query.Get(F('FRequestID') = Request_ID, True);
  if assigned(Request) and assigned(OnRequestAnswered) then
      OnRequestAnswered(Request.OtherPerson, Accepted);
end;

procedure TFriendlist.FriendRequestDeleted(Request_ID : integer);
var
  index : integer;
begin
  index := Requests.Query.GetIndex(F('FRequestID') = Request_ID);
  if index >= 0 then
      FRequests.Delete(index);
  MainActionQueue.DoAction(TFriendlistActionLoadFriendProposals.Create(self));
end;

procedure TFriendlist.FriendRequestReceived(Request : RChatApiRequest);
var
  FriendRequest : TFriendRequest;
begin
  FriendRequest := TFriendRequest.Create(FAccount, Request);
  assert(assigned(FriendRequest));
  FRequests.Add(FriendRequest);
  if assigned(OnFriendRequest) then OnFriendRequest(FriendRequest);
  MainActionQueue.DoAction(TFriendlistActionLoadFriendProposals.Create(self));
end;

procedure TFriendlist.FriendStatusChanged(Friend : RChatAPIFriend);
var
  aFriend : TPerson;
begin
  // maybe friendlist is out of sync
  if IsFriendByID(Friend.ID) then
  begin
    aFriend := Friends.Query.Get(F('PersonID') = Friend.ID);
    aFriend.Status := Friend.Status;
    aFriend.CurrentGame := Friend.current_game;
    Friends.SignalItemChanged(aFriend);
  end;
end;

function TFriendlist.GetFriend(PersonID : integer) : TPerson;
begin
  Result := Friends.Query.Get(F('PersonID') = PersonID);
end;

function TFriendlist.IsFriendByID(PersonID : integer) : boolean;
begin
  Result := Friends.Query.Filter(F('PersonID') = PersonID).Exists();
end;

procedure TFriendlist.RemoveFriendFromList(Friend : TPerson);
begin
  assert(assigned(Friend));
  MainActionQueue.DoAction(TFriendlistActionRemoveFromFriendlist.Create(Friend));
end;

function TFriendlist.RequestCount : integer;
begin
  Result := Requests.Count;
end;

function TFriendlist.IsFriend(Friend : TPerson) : boolean;
begin
  Result := IsFriendByID(Friend.PersonID);
end;

procedure TFriendlist.SetFriendID(const Value : integer);
begin
  FFriendID := Value;
end;

procedure TFriendlist.SetOwnStatus(const Value : EnumChatAPIStatus);
begin
  FriendlistAPI.SetOwnStatus(Value).Free;
end;

procedure TFriendlist.SignalOwnStatusChanged;
begin
  // TODO implement
end;

function TFriendlist.TryGetFriend(PersonID : integer; out Friend : TPerson) : boolean;
var
  index : integer;
begin
  index := Friends.Query.GetIndex(F('PersonID') = PersonID);
  if index >= 0 then
  begin
    Result := True;
    Friend := Friends[index];
  end
  else
  begin
    Result := False;
    Friend := nil;
  end;
end;

{ TFriendRequest }

procedure TFriendRequest.Accept;
begin
  if (RequestType = rtReceived) then
  begin
    MainActionQueue.DoAction(TFriendRequestActionAnswer.Create(self, True));
  end
  else raise EChatError.Create('TFriendRequest.Accept: You can''t accept a request that is sended by yourself.');
end;

constructor TFriendRequest.Create(const Account : TAccount; const Request : RChatApiRequest);
begin
  // different code if the logged in user has send or received the request, because different settings has to be made
  if Account.OwnID = Request.To_ID then
  begin
    begin
      FOtherPerson := Account.GetPerson(Request.Requester_ID, Request.Requester_Name);
      FRequestType := rtReceived;
    end
  end
  else if Account.OwnID = Request.Requester_ID then
  begin
    begin
      FOtherPerson := Account.GetPerson(Request.To_ID, Request.To_Name);
      FRequestType := rtSended;
    end
  end
  else assert(False, 'TFriendlist.FriendRequestReceived: The new request seems not to belongs to logged in account.');
  FRequestID := Request.ID;
end;

procedure TFriendRequest.Decline;
begin
  MainActionQueue.DoAction(TFriendRequestActionAnswer.Create(self, False));
end;

destructor TFriendRequest.Destroy;
begin
  inherited;
end;

function TFriendRequest.IsIncoming : boolean;
begin
  Result := RequestType = rtReceived;
end;

function TFriendRequest.Name : string;
begin
  Result := OtherPerson.Name;
end;

{ TFriendlistAction }

constructor TFriendlistAction.Create(Friendlist : TFriendlist);
begin
  inherited Create();
  FFriendlist := Friendlist;
end;

{ TFriendlistActionLoadStatus }

function TFriendlistActionLoadStatus.Execute : boolean;
var
  Promise : TPromise<EnumChatAPIStatus>;
begin
  Promise := FriendlistAPI.GetOwnStatus;
  Promise.WaitForData;
  if Promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure
      begin
        FFriendlist.FOwnStatus := Promise.Value;
        FFriendlist.SignalOwnStatusChanged;
      end);
  end
  else HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

{ TFriendlistActionLoadFriends }

function TFriendlistActionLoadFriendlist.Execute : boolean;
var
  Promise : TPromise<RFriendlist>;
begin
  Promise := FriendlistAPI.GetFriendlist;
  Promise.WaitForData;
  if Promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      var
        Friend : RChatAPIFriend;
        Request : RChatApiRequest;
      begin
        FFriendlist.FriendID := Promise.Value.friend_id;
        FFriendlist.Friends.Clear;
        for Friend in Promise.Value.Friends do
        begin
            FFriendlist.Friends.Add(FFriendlist.FAccount.GetPerson(Friend));
            FFriendlist.Friends.Last.CurrentGame := Friend.current_game;
        end;
        FFriendlist.Requests.Clear;
        for Request in Promise.Value.Requests do
            FFriendlist.Requests.Add(TFriendRequest.Create(FFriendlist.FAccount, Request));
      end);
  end
  else HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

{ TFriendProposal }

constructor TFriendProposal.Create(const Name : string; SteamID : int64; FriendID : integer);
begin
  FName := name;
  FSteamID := SteamID;
  FFriendID := FriendID;
end;

procedure TFriendProposal.SendRequest;
begin
  Friendlist.AddUserToFriendlist(FriendID);
end;

{ TFriendlistActionLoadFriendProposals }

function TFriendlistActionLoadFriendProposals.Execute : boolean;
var
  FriendCount, i : integer;
  SteamFriendList : TArray<UInt64>;
  Promise : TPromise<ARSteamFriend>;
begin
  FriendCount := SteamFriends.GetFriendCount(k_EFriendFlagImmediate);
  SetLength(SteamFriendList, FriendCount);
  for i := 0 to FriendCount - 1 do
      SteamFriendList[i] := SteamFriends.GetFriendByIndex(i, k_EFriendFlagImmediate);
  Promise := FriendlistAPI.FilterSteamFriends(SteamFriendList);
  Promise.WaitForData;
  if Promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      var
        SteamFriend : RSteamFriend;
        Name : string;
      begin
        FFriendlist.FriendProposals.Clear;
        for SteamFriend in Promise.Value do
        begin
          name := SteamFriends.GetFriendPersonaName(SteamFriend.steam_id);
          FFriendlist.FriendProposals.Add(TFriendProposal.Create(name, SteamFriend.steam_id, SteamFriend.Friend_UID));
        end;
      end);
  end
  else HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

{ TChatSystemActionSendPrivateMessage }

constructor TChatSystemActionSendPrivateMessage.Create(Receiver : TPerson; AMessage : string);
begin
  inherited Create();
  FReceiver := Receiver;
  FMessage := AMessage;
end;

function TChatSystemActionSendPrivateMessage.Execute : boolean;
begin
  Result := HandlePromise(ChatAPI.SendPrivateMessage(FReceiver.PersonID, FMessage));
end;

{ TFriendlistActionAddUserToFriendlist }

constructor TFriendlistActionAddUserToFriendlist.Create(Friend_UID : integer);
begin
  inherited Create();
  FFriend_UID := Friend_UID;
end;

function TFriendlistActionAddUserToFriendlist.Execute : boolean;
begin
  Result := HandlePromise(FriendlistAPI.SendFriendRequest(FFriend_UID));
end;

{ TFriendlistActionRemoveFromFriendlist }

constructor TFriendlistActionRemoveFromFriendlist.Create(Friend : TPerson);
begin
  inherited Create();
  FFriend := Friend;
end;

function TFriendlistActionRemoveFromFriendlist.Execute : boolean;
begin
  Result := HandlePromise(FriendlistAPI.RemoveFriend(FFriend.PersonID));
end;

{ TFriendRequestAnswer }

constructor TFriendRequestActionAnswer.Create(Request : TFriendRequest; Accept : boolean);
begin
  inherited Create;
  FRequest := Request;
  FAccept := Accept;
end;

function TFriendRequestActionAnswer.Execute : boolean;
begin
  Result := HandlePromise(FriendlistAPI.AnswerFriendRequest(Request.FRequestID, Accept));
end;

end.
