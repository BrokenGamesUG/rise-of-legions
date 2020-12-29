unit BaseConflict.Api.Matchmaking;

interface

uses
  // Delphi
  System.Generics.Collections,
  System.SysUtils,
  Winapi.Windows,
  System.Math,
  // Engine
  Engine.Network.RPC,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.Threads,
  Engine.Helferlein.DataStructures,
  Engine.DataQuery,
  Engine.dXML,
  // Game
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Scenario,
  BaseConflict.Api,
  BaseConflict.Api.Types,
  BaseConflict.Api.Account,
  BaseConflict.Api.Chat,
  BaseConflict.Api.Deckbuilding,
  BaseConflict.Api.Shop,
  BaseConflict.Api.Scenarios,
  BaseConflict.Api.Game;

type
  EMatchmakingError = class(Exception);

  {$RTTI EXPLICIT METHODS([vcPrivate, vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$M+}
  TMatchmakingTeam = class;

  TMatchmakingManager = class;
  TMatchmakingTeamInvite = class;
  TMatchmakingQueue = class;

  TMatchmakingDeck = class
    strict private
      FName : string;
      FIcon : string;
      FIsSet : boolean;
      FLeague : Integer;
      procedure SetIcon(const Value : string); virtual;
      procedure SetIsSet(const Value : boolean); virtual;
      procedure SetName(const Value : string); virtual;
      procedure SetLeague(const Value : Integer); virtual;
    published
      /// <summary> Determines whether the deck already have been set. </summary>
      property IsSet : boolean read FIsSet write SetIsSet;
      /// <summary> The decks name. </summary>
      property name : string read FName write SetName;
      /// <summary> The decks icon. </summary>
      property Icon : string read FIcon write SetIcon;
      /// <summary> League of deck.</summary>
      property League : Integer read FLeague write SetLeague;
    public
  end;

  TMatchmakingMember = class
    strict private
      FOwner : TPerson;
      FDeck : TMatchmakingDeck;
      FIsLeader, FIsKickable : boolean;
      procedure SetIsLeader(const Value : boolean); virtual;
      procedure SetIsKickable(const Value : boolean); virtual;
    published
      /// <summary> The person which is impersonated by this member. </summary>
      property Owner : TPerson read FOwner;
      /// <summary> The chosen deck by this team member. Can be not set, which is checkable by IsSet. </summary>
      property Deck : TMatchmakingDeck read FDeck;
      /// <summary> Returns True if person is leader of matchmaking team he belongs to.</summary>
      property IsLeader : boolean read FIsLeader write SetIsLeader;
      /// <summary> Returns True if person is leader of matchmaking team he belongs to.</summary>
      property IsKickable : boolean read FIsKickable write SetIsKickable;
    public
      constructor Create(const Owner : TPerson);
      destructor Destroy; override;
  end;

  ProcMatchmakingTeamQueueEntered = procedure(Sender : TMatchmakingTeam; Queue : TMatchmakingQueue) of object;
  ProcMatchmakingTeamChanged = procedure(Sender : TMatchmakingTeam) of object;

  EnumQueueEnterable = (qeYes, qeNoLeagueDisabled, qeNoScenarioNotSet, qeNoTooManyPlayers, qeNoDecksNotSet, qeNoNotEnoughPlayers, qeNoNotLeader);

  TMatchmakingTeam = class(TInterfacedObject, IMatchmakingTeamBackchannel, IMatchmakingInviteBackchannel)
    private// backchannel
      procedure NewTeamInvite(invite_data : RMatchmakingTeamInvite);
      procedure InviteStatusChanged(invitation_id : Integer; new_status : EnumMatchmakingTeamInviteStatus);
      procedure EnteredQueue(team_uid : string; QueueData : RMatchmakingQueueData);
      procedure TeamUpdate(Data : RMatchmakingTeam);
    private
      FUID : string;
      FManager : TMatchmakingManager;
      // FSelectedScenarioTeam : TScenarioTeam;
      FOnEnteredQueue : ProcMatchmakingTeamQueueEntered;
      FOnScenarioChanged : ProcCallback;
      FQueue : TMatchmakingQueue;
      constructor Create(Manager : TMatchmakingManager; CurrentPlayerIsLeader : boolean = True);

      procedure SignalScenarioChange();
      function GetLeader : TMatchmakingMember;
      function GetCurrentUser : TMatchmakingMember;
      procedure UpdateMembers;
      procedure UpdateMemberDeck;
      procedure UpdateQueueEnterable;
    strict private
      FPlayers : TUltimateObjectList<TMatchmakingMember>;
      FInvites : TUltimateObjectList<TMatchmakingTeamInvite>;
      FDeck : TDeck;
      FScenarioInstance : TScenarioInstance;
      FQueueEnterable : EnumQueueEnterable;
      procedure SetDeck(Deck : TDeck); virtual;
      procedure SetScenario(const ForceOverride : Integer; const Value : TScenarioInstance); virtual;
      procedure SetQueueEnterable(const Value : EnumQueueEnterable); virtual;
    published
      /// <summary> The chosen scenario for this team. Initialized with nil as a new team has no scenario set. </summary>
      property ScenarioInstance : TScenarioInstance index iFalse read FScenarioInstance write SetScenario;
      /// <summary> All player of the team, the current player will also listed and always the first item.</summary>
      property Players : TUltimateObjectList<TMatchmakingMember> read FPlayers;
      [dXMLDependency('.Players')]
      function PlayerCount : Integer;
      /// <summary> All sended invites including the status of the invite, like open or declined. If a invited player accept
      /// the invite, the invite will still displayed in this list, but the invite is then accepted.</summary>
      property Invites : TUltimateObjectList<TMatchmakingTeamInvite> read FInvites;
      /// <summary> The deck chosen by the current player for this team. </summary>
      property Deck : TDeck read FDeck write SetDeck;

      /// <summary> Determines whether the queue can be entered and when not why. </summary>
      property QueueEnterable : EnumQueueEnterable read FQueueEnterable write SetQueueEnterable;

      /// <summary> Returns whether the team is already full. </summary>
      [dXMLDependency('.Players', '.ScenarioInstance.Scenario.MaxTeamSize')]
      function IsFull : boolean;
      /// <summary> Invites a friend (player on friendlist) to this team. Only if player accept the invite, he will
      /// become a member of this team.</summary>
      procedure InviteFriend(const Friend : TPerson);
      /// <summary> Kicks a player that a member of current team from team. You can't kick yourself and only if you are the leader.</summary>
      procedure Kick(const Member : TMatchmakingMember);
      /// <summary> Leave the team and so make self available for another matchmakingteam.</summary>
      procedure LeaveTeam;
      /// <summary> Returns true if current logged in user is leader of this team and therefore has the permissions
      /// to invite other players or promote another member to leader.</summary>
      [dXMLDependency('.Players')]
      function CurrentUserIsLeader : boolean;

      /// <summary> Will enter with the whole team the matchmaking queue. This operation can only be executed by the leader.</summary>
      procedure EnterQueue;
    public
      property Queue : TMatchmakingQueue read FQueue;
      /// <summary> If called when the team entered the queue, as this point no player can longer join the team.
      /// But if the queue will be left before a game is found, all players will return to the matchmakingteam.</summary>
      property OnEnteredQueue : ProcMatchmakingTeamQueueEntered read FOnEnteredQueue write FOnEnteredQueue;
      /// <summary> Called if the scenario has been changed by the leader. </summary>
      property OnScenarioChanged : ProcCallback read FOnScenarioChanged write FOnScenarioChanged;
      /// <summary> The selected scenario team for scenario. This is only important if the scenario provides
      /// a different kind of teams, like 2 Vs 1 (+KI). If no ScenarioTeam was selected, this value is nil
      /// and means that a random team will selected by server.</summary>
      // property SelectedScenarioTeam : TScenarioTeam read FSelectedScenarioTeam;
      /// <summary> Leader of the team, can also queried with player.IsLeader().</summary>
      property Leader : TMatchmakingMember read GetLeader;
      [dXMLDependency('.Players', '.IsFull', '.CurrentUserIsLeader')]
      function CanInviteFriend(const Player : TPerson) : boolean;
      [dXMLDependency('.Deck.League', '.Deck.Name')]
      function UpdateDeck : Integer;
      [dXMLDependency('.Players.Deck.League')]
      function League : Integer;
      [dXMLDependency('.Players.Deck.League')]
      function HavePlayersSameLeague : boolean;
      /// <summary> Assign the leadership for this team to another member.
      /// HINT: After using this method, current user is not anymore the leader.</summary>
      procedure PromotePlayerToLeader(const NewLeader : TMatchmakingMember);
      procedure ChooseScenarioInstance(ScenarioInstance : TScenarioInstance);
      procedure ChooseDeck(Deck : TDeck);
      function CanEnterQueue : boolean;
      destructor Destroy; override;
  end;

  /// <summary> A matchmakingteam can have multiple invites, which are sent to the target players. </summary>
  TMatchmakingTeamInvite = class
    private
      FID : Integer;
      FMatchmakingManager : TMatchmakingManager;
      constructor CreateIncoming(TeamID : Integer; Source, Target : TPerson; MatchmakingManager : TMatchmakingManager);
      constructor CreateOutgoing(TeamID : Integer; Source, Target : TPerson; Status : EnumMatchmakingTeamInviteStatus);
    strict private
      FStatus : EnumMatchmakingTeamInviteStatus;
      FSource, FTarget : TPerson;
      procedure SetStatus(const Value : EnumMatchmakingTeamInviteStatus); virtual;
    published
      /// <summary> Status of the invite.</summary>
      property Status : EnumMatchmakingTeamInviteStatus read FStatus write SetStatus;
      /// <summary> Player who has sent this invite. Nil if this invite is outgoing. </summary>
      property Source : TPerson read FSource;
      /// <summary> Player who has invited the current user. Nil if this invite is incoming. </summary>
      property Target : TPerson read FTarget;
      /// <summary> Accept the invite and join the team for which the invit stays. Remove the invite from the list invites.
      /// If another player than targetplayer calls that method, an error will be signaled by server.</summary>
      procedure Accept;
      /// <summary> Decline the invite.
      /// If another player than targetplayer calls that method, an error will be signaled by server.</summary>
      procedure Decline;
      [dXMLDependency('.Status')]
      function IsPending : boolean;
  end;

  ProcOnGameFound = procedure(Game : TGameMetaInfo) of object;
  ProcMatchmakingQueueChanged = procedure(Sender : TMatchmakingQueue) of object;
  ProcMatchMakingQueueLeft = procedure(Sender : TMatchmakingQueue; Leaver : TPerson) of object;

  TMatchmakingQueue = class(TInterfacedObject, IMatchmakingQueueBackchannel)
    private
      FMatchmakingTeam : TMatchmakingTeam;
      FOnChange : ProcMatchmakingQueueChanged;
      FOnServerQueueError : ProcCallback;
      FOnQueueLeft : ProcMatchMakingQueueLeft;
      constructor Create(SourceMatchmakingTeam : TMatchmakingTeam; QueueData : RMatchmakingQueueData);
      function GetScenario : TScenarioInstance;
      function GetTimeInQueue : Integer;
      procedure UpdateQueueData(Data : RMatchmakingQueueData);
      procedure QueueLeft(Leaver : RMatchmakingUser);
      procedure ServerQueueError();
    strict private
      FPlayerCount : Integer;
      FEnterTimestamp : LongWord; // timestamp on which the user has entered the queue
      FServerAvailable : boolean;
      procedure SetPlayerCount(const Value : Integer); virtual;
      procedure SetServerAvailable(const Value : boolean); virtual;
    published
      /// <summary> Is a slot on a gameserver available? </summary>
      property ServerAvailable : boolean read FServerAvailable write SetServerAvailable;
      /// <summary> Number of player for gamemode that are currently searching for game.</summary>
      property PlayerCount : Integer read FPlayerCount write SetPlayerCount;
      /// <summary> Number of seconds that the user is in the matchmaking queue.</summary>
      property TimeInQueue : Integer read GetTimeInQueue;
      /// <summary> Will leave the queue with the team he has entered the queue, so if one player of a team will left the queue,
      /// the whole team will leave the queue.</summary>
      procedure LeaveQueue;
    public
      property OnServerQueueError : ProcCallback read FOnServerQueueError write FOnServerQueueError;
      /// <summary> Will be called when the queue is left be any user of current matchmakingteam. Will also
      /// called when current user left team queue. After leaving a queue, all players will return to the current matchmakingteam.</summary>
      property OnQueueLeft : ProcMatchMakingQueueLeft read FOnQueueLeft write FOnQueueLeft;
      /// <summary> Will called when ever data changed, e.g. PlayerCount.</summary>
      property OnChange : ProcMatchmakingQueueChanged read FOnChange write FOnChange;
      destructor Destroy; override;
  end;

  TMatchmakingManager = class(TInterfacedObject, IMatchmakingManagerBackchannel, IMatchmakingInviteBackchannel)
    private
      FCurrentTeam : TMatchmakingTeam;
      FAccount : TAccount;
      FFriendlist : TFriendlist;
      FOnGameFound : ProcOnGameFound;
      FInvites : TUltimateObjectList<TMatchmakingTeamInvite>;
      FOnCurrentTeamChange : ProcCallback;
      procedure NewTeamInvite(invite_data : RMatchmakingTeamInvite);
      procedure InviteStatusChanged(invitation_id : Integer; new_status : EnumMatchmakingTeamInviteStatus);
      procedure KickFromTeam(new_team_data : RMatchmakingTeam);
      procedure UpdateCurrentInvite;
      procedure GameFound(Data : RGameFoundData);
    strict private
      FCurrentInvite : TMatchmakingTeamInvite;
      procedure SetCurrentInvite(const Value : TMatchmakingTeamInvite); virtual;
      procedure SetCurrentTeam(const Value : TMatchmakingTeam); virtual;
    published
      property CurrentTeam : TMatchmakingTeam read FCurrentTeam write SetCurrentTeam;
      /// <summary> List all invites for current user, list will auto managed, so a decline or accept of an
      /// invite will remove it from list.</summary>
      property Invites : TUltimateObjectList<TMatchmakingTeamInvite> read FInvites;
      property CurrentInvite : TMatchmakingTeamInvite read FCurrentInvite write SetCurrentInvite;
    public
      /// <summary> Will called when a game for user is found, after ths call the queue and the matchmaking team which has joined
      /// the queue can be deleted, because the user will no longer stay within the queue and the matchmaking team will no longer
      /// exists in database.
      /// <param name="GameData"> All data that is nessecary to join the game. The data also contain a
      /// small overview about the teams.</param>/summary>
      property OnGameFound : ProcOnGameFound read FOnGameFound write FOnGameFound;
      /// <summary> Is called when the player enters another team. When this callback is called,
      /// current team already contains the new team. </summary>
      property OnCurrentTeamChange : ProcCallback read FOnCurrentTeamChange write FOnCurrentTeamChange;
      constructor Create(Account : TAccount; Friendlist : TFriendlist);
      /// <summary> Free memory.</summary>
      destructor Destroy; override;
  end;

  RLeaderboardEntry = record
    Rank, Points, PlayerID : Integer;
    PlayerName, PlayerIcon : string;
    constructor Create(const Data : RLeaderboardRow);
  end;

  EnumLeaderboardFormat = (lfRank, lfTime);

  TLeaderboard = class
    strict private
      FScenarioInstance : TScenarioInstance;
      FFormat : EnumLeaderboardFormat;
      FLeague : Integer;
      FTopList, FPlayerList : TUltimateList<RLeaderboardEntry>;
    published
      property Format : EnumLeaderboardFormat read FFormat;
      property League : Integer read FLeague;
      property ForScenario : TScenarioInstance read FScenarioInstance;
      property TopList : TUltimateList<RLeaderboardEntry> read FTopList;
      property PlayerList : TUltimateList<RLeaderboardEntry> read FPlayerList;
    public
      constructor Create(Data : RLeaderboardForLeague);
      destructor Destroy; override;
  end;

  TLeaderboardManager = class
    protected
      FOnLeaderboardsLoaded : ProcOfObject;
      procedure LoadLeaderboards(Data : RLeaderboardData);
    strict private
      FLeaderboards : TUltimateObjectList<TLeaderboard>;
    published
      /// <summary> All existing leaderboards unsorted. </summary>
      property Leaderboards : TUltimateObjectList<TLeaderboard> read FLeaderboards;
    public
      property OnLeaderboardsLoaded : ProcOfObject read FOnLeaderboardsLoaded write FOnLeaderboardsLoaded;
      constructor Create;
      procedure ReloadLeaderboards;
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  TLeaderboardsLoadAction = class(TPromiseLoadAction<RLeaderboardData>)
    protected
      FLeaderboardManager : TLeaderboardManager;
      function GetData : TPromise<RLeaderboardData>; override;
      procedure ProcessData(const Data : RLeaderboardData); override;
    public
      constructor Create(LeaderboardManager : TLeaderboardManager);
  end;

  TMatchmakingManagerAction = class(TPromiseAction)
    private
      FMatchmakingManager : TMatchmakingManager;
    public
      constructor Create(MatchmakingManager : TMatchmakingManager);
  end;

  [AQCriticalAction]
  TMatchmakingManagerActionLoadCurrentTeam = class(TMatchmakingManagerAction)
    private
      FNewTeam : TMatchmakingTeam;
      FOldTeam : TMatchmakingTeam;
    public
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TMatchmakingTeamAction = class(TPromiseAction)
    private
      FMatchmakingTeam : TMatchmakingTeam;
    public
      constructor Create(MatchmakingTeam : TMatchmakingTeam);
  end;

  [AQCriticalAction]
  TMatchmakingTeamActionSetScenarioInstance = class(TMatchmakingTeamAction)
    private
      FOldScenario, FNewScenario : TScenarioInstance;
    public
      constructor Create(MatchmakingTeam : TMatchmakingTeam; NewScenario : TScenarioInstance);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TMatchmakingTeamActionKickPlayer = class(TMatchmakingTeamAction)
    private
      FMember : TMatchmakingMember;
      FIndex : Integer;
    public
      constructor Create(MatchmakingTeam : TMatchmakingTeam; Member : TMatchmakingMember);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
      procedure Finished; override;
  end;

  [AQCriticalAction]
  TMatchmakingTeamActionPromotePlayer = class(TMatchmakingTeamAction)
    private
      FNewLeader, FOldLeader : TMatchmakingMember;
    public
      constructor Create(MatchmakingTeam : TMatchmakingTeam; NewLeader : TMatchmakingMember);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TMatchmakingTeamActionSetCurrentDeck = class(TMatchmakingTeamAction)
    private
      FNewDeck, FOldDeck : TDeck;
    public
      constructor Create(MatchmakingTeam : TMatchmakingTeam; NewDeck : TDeck);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TMatchmakingTeamActionLeave = class(TMatchmakingTeamAction)
    private
      FOldTeam : TMatchmakingTeam;
    public
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TMatchmakingTeamInviteAction = class(TPromiseAction)
    private
      FInvite : TMatchmakingTeamInvite;
    public
      constructor Create(Invite : TMatchmakingTeamInvite);
  end;

  [AQCriticalAction]
  TMatchmakingTeamInviteActionAccept = class(TMatchmakingTeamInviteAction)
    private
      FNewTeam, FOldTeam : TMatchmakingTeam;
    public
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TMatchmakingTeamInviteActionDecline = class(TMatchmakingTeamInviteAction)
    public
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TMatchmakingTeamActionInvitePlayer = class(TMatchmakingTeamAction)
    private
      FFriend : TPerson;
      FInvite : TMatchmakingTeamInvite;
    public
      constructor Create(MatchmakingTeam : TMatchmakingTeam; Friend : TPerson);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TMatchmakingTeamActionEnterQueue = class(TMatchmakingTeamAction)
    public
      function Execute : boolean; override;
  end;
  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  Matchmaking : TMatchmakingManager;
  LeaderboardManager : TLeaderboardManager;

implementation

{ TMatchmakingTeam }

function TMatchmakingTeam.CanEnterQueue : boolean;
var
  i : Integer;
begin
  Result := (ScenarioInstance <> nil) and CurrentUserIsLeader and (ScenarioInstance.Scenario.MaxTeamSize >= Players.Count);
  for i := 0 to Players.Count - 1 do
      Result := Result and Players[i].Deck.IsSet;
end;

function TMatchmakingTeam.CanInviteFriend(const Player : TPerson) : boolean;
begin
  Result := CurrentUserIsLeader and not Players.Query.Filter(F('Owner.PersonID') = Player.PersonID).Exists;
end;

procedure TMatchmakingTeam.ChooseDeck(Deck : TDeck);
begin
  if self.Deck <> Deck then
      MainActionQueue.DoAction(TMatchmakingTeamActionSetCurrentDeck.Create(self, Deck))
end;

procedure TMatchmakingTeam.ChooseScenarioInstance(ScenarioInstance : TScenarioInstance);
begin
  if CurrentUserIsLeader and (self.ScenarioInstance <> ScenarioInstance) and assigned(ScenarioInstance) then
      MainActionQueue.DoAction(TMatchmakingTeamActionSetScenarioInstance.Create(self, ScenarioInstance));
end;

constructor TMatchmakingTeam.Create(Manager : TMatchmakingManager; CurrentPlayerIsLeader : boolean);
var
  Member : TMatchmakingMember;
begin
  FManager := Manager;
  FUID := 'empty';
  FPlayers := TUltimateObjectList<TMatchmakingMember>.Create;
  FInvites := TUltimateObjectList<TMatchmakingTeamInvite>.Create;
  Member := TMatchmakingMember.Create(FManager.FAccount.Own);
  Member.IsLeader := CurrentPlayerIsLeader;
  Players.Add(Member);
  UpdateQueueEnterable;
  RPCHandlerManager.SubscribeHandler(self);
end;

destructor TMatchmakingTeam.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  FInvites.Free;
  FPlayers.Free;
  FreeAndNil(FQueue);
  inherited;
end;

procedure TMatchmakingTeam.EnteredQueue(team_uid : string; QueueData : RMatchmakingQueueData);
begin
  assert(self.FUID = team_uid);
  FQueue := TMatchmakingQueue.Create(self, QueueData);
  if assigned(OnEnteredQueue) then
      OnEnteredQueue(self, FQueue)
  else
      raise EMatchmakingError.Create('TMatchmakingTeam.EnteredQueue: Queue has been entered, but no callback was set.');
end;

procedure TMatchmakingTeam.EnterQueue;
begin
  MainActionQueue.DoAction(TMatchmakingTeamActionEnterQueue.Create(self));
end;

function TMatchmakingTeam.GetCurrentUser : TMatchmakingMember;
begin
  Result := Players.Query.Get(F('Owner.IsCurrentUser'), True);
end;

function TMatchmakingTeam.GetLeader : TMatchmakingMember;
begin
  Result := Players.Query.Get(F('IsLeader'), True);
end;

function TMatchmakingTeam.HavePlayersSameLeague : boolean;
var
  i : Integer;
begin
  Result := True;
  for i := 1 to Players.Count - 1 do
      Result := Result and (Players[i - 1].Deck.League = Players[i].Deck.League);
end;

procedure TMatchmakingTeam.InviteFriend(const Friend : TPerson);
begin
  MainActionQueue.DoAction(TMatchmakingTeamActionInvitePlayer.Create(self, Friend));
end;

procedure TMatchmakingTeam.InviteStatusChanged(invitation_id : Integer; new_status : EnumMatchmakingTeamInviteStatus);
var
  Invite : TMatchmakingTeamInvite;
begin
  // maybe the invite does not exists in this team, so save
  Invite := Invites.Query.Get(F('FID') = invitation_id, True);
  if assigned(Invite) and (Invite.Status <> new_status) then
  begin
    Invite.Status := new_status;
    FInvites.SignalItemChanged(Invite);
  end;
end;

function TMatchmakingTeam.IsFull : boolean;
begin
  if assigned(ScenarioInstance) then
      Result := Players.Count >= ScenarioInstance.Scenario.MaxTeamSize
  else
  begin
    if ScenarioManager.Scenarios.Count > 0 then
        Result := Players.Count >= ScenarioManager.Scenarios.Query.OrderBy('-MaxTeamSize').First.MaxTeamSize
    else
        Result := False;
  end;
end;

procedure TMatchmakingTeam.Kick(const Member : TMatchmakingMember);
begin
  // you can't kick yourself and only other players if you are the leader
  if assigned(Member) and not Member.Owner.IsCurrentUser and CurrentUserIsLeader then
  begin
    MainActionQueue.DoAction(TMatchmakingTeamActionKickPlayer.Create(self, Member));
  end;
end;

function TMatchmakingTeam.League : Integer;
var
  i : Integer;
begin
  Result := 1;
  for i := 0 to Players.Count - 1 do
      Result := Max(Result, Players[i].Deck.League);
end;

procedure TMatchmakingTeam.LeaveTeam;
begin
  MainActionQueue.DoAction(TMatchmakingTeamActionLeave.Create(self));
  MainActionQueue.DoAction(TMatchmakingManagerActionLoadCurrentTeam.Create(FManager));
end;

procedure TMatchmakingTeam.NewTeamInvite(invite_data : RMatchmakingTeamInvite);
var
  Invite : TMatchmakingTeamInvite;
begin
  // only invites for this team matters
  if FUID = invite_data.team_uid then
  begin
    Invite := Invites.Query.Get(F('Target.PersonID') = invite_data.Player.ID, True);
    // if invite already exists, update id
    if assigned(Invite) then
        Invite.FID := invite_data.ID
    else
        Invites.Add(TMatchmakingTeamInvite.CreateOutgoing(invite_data.ID, FManager.FAccount.GetPerson(invite_data.sourceplayer), FManager.FAccount.GetPerson(invite_data.Player), invite_data.Status));
  end;
end;

function TMatchmakingTeam.PlayerCount : Integer;
begin
  Result := Players.Count;
end;

procedure TMatchmakingTeam.PromotePlayerToLeader(const NewLeader : TMatchmakingMember);
begin
  if CurrentUserIsLeader then
      MainActionQueue.DoAction(TMatchmakingTeamActionPromotePlayer.Create(self, NewLeader));
end;

procedure TMatchmakingTeam.SetDeck(Deck : TDeck);
begin
  if MainActionQueue.IsActive then
      FDeck := Deck
  else
      MainActionQueue.DoAction(TMatchmakingTeamActionSetCurrentDeck.Create(self, Deck));
end;

procedure TMatchmakingTeam.SetQueueEnterable(const Value : EnumQueueEnterable);
begin
  FQueueEnterable := Value;
end;

procedure TMatchmakingTeam.SetScenario(const ForceOverride : Integer; const Value : TScenarioInstance);
begin
  if (ForceOverride = iTrue) or MainActionQueue.IsActive then
  begin
    FScenarioInstance := Value;
    SignalScenarioChange;
  end
  else if CurrentUserIsLeader and (ScenarioInstance <> Value) then
      MainActionQueue.DoAction(TMatchmakingTeamActionSetScenarioInstance.Create(self, Value));
end;

procedure TMatchmakingTeam.SignalScenarioChange;
begin
  UpdateQueueEnterable;
  if assigned(FOnScenarioChanged) then
      FOnScenarioChanged();
end;

procedure TMatchmakingTeam.TeamUpdate(Data : RMatchmakingTeam);
var
  PlayerQuery : IDataQuery<TMatchmakingMember>;
  Player : TMatchmakingMember;
  DataQuery : IDataQuery<RMatchmakingUser>;
  player_data : RMatchmakingUser;
  Leader : TMatchmakingMember;
  PlayerTrash : TObjectList<TMatchmakingMember>;
  Scenario : TScenario;
  i, FormerLeaderID : Integer;
begin
  if Data.team_uuid = FUID then
  begin
    // get old leader before remove player etc. to avoid that old leader is removed
    // before leader was read
    Leader := self.Leader;
    if assigned(Leader) then
        FormerLeaderID := Leader.Owner.PersonID
    else
        FormerLeaderID := -1;
    DataQuery := TDelphiDataQuery<RMatchmakingUser>.Create(Data.Members);
    // remove all players which are no longer part of the team
    // direct delete and free of member leads to memory violation, so quick fix with deferring delete
    PlayerTrash := TObjectList<TMatchmakingMember>.Create;
    for Player in Players.Query.Filter(not(F('Owner.PersonID') in DataQuery.ValuesAsInteger('id'))) do
        PlayerTrash.Add(Players.Extract(Player));
    PlayerTrash.Free;
    // and then add all players which are now part of the team
    PlayerQuery := TDelphiDataQuery<TMatchmakingMember>.Create(Players);
    for player_data in DataQuery.Filter(not(F('ID') in PlayerQuery.ValuesAsInteger('Owner.PersonID'))) do
    begin
      Player := TMatchmakingMember.Create(FManager.FAccount.GetPerson(player_data));
      Player.Deck.Name := player_data.current_deck;
      Player.Deck.Icon := player_data.deck_icon;
      Player.Deck.IsSet := player_data.current_deck <> '';
      Players.Add(Player);
    end;
    // and after player list is up-to-date, look for changed user_data (e.g. deck)
    PlayerQuery := TDelphiDataQuery<TMatchmakingMember>.Create(Players);
    for player_data in Data.Members do
    begin
      Player := PlayerQuery.Get(F('Owner.PersonID') = player_data.ID);
      // ignore deck changes for current user, because this changes are already emulated
      // will prevent jumping when server lags or fast changes
      if not Player.Owner.IsCurrentUser and ((Player.Deck.Name <> player_data.current_deck) or (Player.Deck.Icon <> player_data.deck_icon) or (Player.Deck.League <> player_data.deck_tier)) then
      begin
        Player.Deck.Name := player_data.current_deck;
        Player.Deck.Icon := player_data.deck_icon;
        Player.Deck.League := player_data.deck_tier;
        Player.Deck.IsSet := player_data.current_deck <> '';
        Players.SignalItemChanged(Player);
      end;
    end;

    if FormerLeaderID <> Data.leader_id then
    begin
      if Players.Query.TryGet(F('Owner.PersonID') = FormerLeaderID, Leader) then
      begin
        // downgrade current leader if still present in new team
        Leader.IsLeader := False;
        Players.SignalItemChanged(Leader);
      end;
      // promote new leader
      Leader := Players.Query.Get(F('Owner.PersonID') = Data.leader_id);
      Leader.IsLeader := True;
      Players.SignalItemChanged(Leader);
    end;
    if not CurrentUserIsLeader and (not assigned(ScenarioInstance) or (ScenarioInstance.Scenario.UID <> Data.scenario_identifier)
      or (ScenarioInstance.ID <> Data.scenario_instance_id)) then
    begin
      Scenario := ScenarioManager.Scenarios.Query.Get(F('FIdentifier') = Data.scenario_identifier, True);
      if assigned(Scenario) then
          SetScenario(iTrue, Scenario.LevelsOfDifficulty.Query.Get(F('FID') = Data.scenario_instance_id, True))
      else
          SetScenario(iTrue, nil);
    end;
    // finally ensure that the current user is the first item
    for i := 1 to Players.Count - 1 do
      if Players[i].Owner.IsCurrentUser then
      begin
        Players.Extra.Swap(0, i);
        break;
      end;
    UpdateMembers;
  end;
end;

function TMatchmakingTeam.UpdateDeck : Integer;
begin
  Result := -1;
  UpdateMemberDeck;
end;

procedure TMatchmakingTeam.UpdateMemberDeck;
var
  Member : TMatchmakingMember;
begin
  Member := GetCurrentUser;
  assert(assigned(Member), 'TMatchmakingTeamActionSetCurrentDeck.Emulate: Current user not found in matchmaking team!');
  if assigned(Member) then
  begin
    if assigned(Deck) then
    begin
      Member.Deck.Name := Deck.Name;
      Member.Deck.Icon := Deck.Icon;
      Member.Deck.League := Deck.League;
    end
    else
    begin
      Member.Deck.Name := '';
      Member.Deck.Icon := '';
      Member.Deck.League := -1;
    end;
    Member.Deck.IsSet := assigned(Deck);
    Players.SignalItemChanged(Member);
  end;
end;

procedure TMatchmakingTeam.UpdateMembers;
var
  MayKick : boolean;
  i : Integer;
begin
  MayKick := CurrentUserIsLeader;
  for i := 1 to Players.Count - 1 do
  begin
    Players[i].IsKickable := MayKick and not Players[i].Owner.IsCurrentUser;
    Players.SignalItemChanged(Players[i]);
  end;
  UpdateQueueEnterable;
end;

procedure TMatchmakingTeam.UpdateQueueEnterable;
begin
  if not assigned(ScenarioInstance) then
      QueueEnterable := qeNoScenarioNotSet
  else if ScenarioInstance.Scenario.MaxTeamSize < Players.Count then
      QueueEnterable := qeNoTooManyPlayers
  else if ScenarioInstance.Scenario.DeckRequired and Players.Query.Filter(not F('Deck.IsSet')).Exists then
      QueueEnterable := qeNoDecksNotSet
  else if ScenarioInstance.Scenario.IsDuel and (Players.Count < ScenarioInstance.Scenario.MaxTeamSize) then
      QueueEnterable := qeNoNotEnoughPlayers
    // ToDo Remove Crystal League Block
  else if ScenarioInstance.Scenario.IsPvP and not ScenarioInstance.Scenario.IsDuel and
    ((ScenarioInstance.League >= MAX_LEAGUE) or Players.Query.Filter(F('Deck.League') >= MAX_LEAGUE).Exists) then
      QueueEnterable := qeNoLeagueDisabled
  else if not CurrentUserIsLeader then
      QueueEnterable := qeNoNotLeader
  else
      QueueEnterable := qeYes;
end;

function TMatchmakingTeam.CurrentUserIsLeader : boolean;
var
  Member : TMatchmakingMember;
begin
  Member := Players.Query.Get(F('Owner.PersonID') = FManager.FAccount.OwnID, True);
  Result := assigned(Member) and Member.IsLeader;
end;

{ TMatchmakingTeamManager }

constructor TMatchmakingManager.Create(Account : TAccount; Friendlist : TFriendlist);
begin
  assert(assigned(Account));
  assert(assigned(Friendlist));
  assert(assigned(ScenarioManager));
  FAccount := Account;
  FFriendlist := Friendlist;
  FInvites := TUltimateObjectList<TMatchmakingTeamInvite>.Create;
  MainActionQueue.DoAction(TMatchmakingManagerActionLoadCurrentTeam.Create(self));
  RPCHandlerManager.SubscribeHandler(self);
end;

destructor TMatchmakingManager.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  FInvites.Free;
  CurrentTeam.Free;
  inherited;
end;

procedure TMatchmakingManager.InviteStatusChanged(invitation_id : Integer; new_status : EnumMatchmakingTeamInviteStatus);
var
  Invite : TMatchmakingTeamInvite;
begin
  Invite := Invites.Query.Get(F('FID') = invitation_id, True);
  if (Invite <> nil) and (Invite.Status <> new_status) then
  begin
    Invite.Status := new_status;
    UpdateCurrentInvite;
    Invites.SignalItemChanged(Invite);
  end;
end;

procedure TMatchmakingManager.KickFromTeam(new_team_data : RMatchmakingTeam);
var
  NewTeam, OldTeam : TMatchmakingTeam;
begin
  OldTeam := CurrentTeam;
  NewTeam := TMatchmakingTeam.Create(self);
  NewTeam.FUID := new_team_data.team_uuid;
  NewTeam.TeamUpdate(new_team_data);
  CurrentTeam := NewTeam;
  OldTeam.Free;
end;

procedure TMatchmakingManager.NewTeamInvite(invite_data : RMatchmakingTeamInvite);
var
  new_invite : TMatchmakingTeamInvite;
begin
  // only if current user is the target of the invite, we should process it, else it maybe for the
  // matchmakingteam
  if invite_data.Player.ID = FAccount.OwnID then
  begin
    new_invite := Invites.Query.Get(F('FID') = invite_data.ID, True);
    if not assigned(new_invite) then
    begin
      // incoming invites are targeting the current user
      new_invite := TMatchmakingTeamInvite.CreateIncoming(invite_data.ID, FAccount.GetPerson(invite_data.sourceplayer), FAccount.Own, self);
      Invites.Add(new_invite);
    end
    else
    begin
      new_invite.Status := invite_data.Status;
      Invites.SignalItemChanged(new_invite);
    end;
    UpdateCurrentInvite;
  end;
end;

procedure TMatchmakingManager.SetCurrentInvite(const Value : TMatchmakingTeamInvite);
begin
  FCurrentInvite := Value;
end;

procedure TMatchmakingManager.SetCurrentTeam(const Value : TMatchmakingTeam);
begin
  FCurrentTeam := Value;
  if assigned(OnCurrentTeamChange) then OnCurrentTeamChange();
end;

procedure TMatchmakingManager.UpdateCurrentInvite;
var
  i : Integer;
begin
  CurrentInvite := nil;
  for i := 0 to Invites.Count - 1 do
    if Invites[i].Status = tiOpen then
    begin
      CurrentInvite := Invites[i];
      break;
    end;
end;

procedure TMatchmakingManager.GameFound(Data : RGameFoundData);
begin
  assert(assigned(FOnGameFound));
  OnGameFound(TGameMetaInfo.Create(Data));
end;

{ TMatchmakingTeamInvite }

procedure TMatchmakingTeamInvite.Accept;
begin
  MainActionQueue.DoAction(TMatchmakingTeamInviteActionAccept.Create(self));
end;

constructor TMatchmakingTeamInvite.CreateIncoming(TeamID : Integer; Source, Target : TPerson; MatchmakingManager : TMatchmakingManager);
begin
  FID := TeamID;
  FSource := Source;
  FTarget := Target;
  FMatchmakingManager := MatchmakingManager;
end;

constructor TMatchmakingTeamInvite.CreateOutgoing(TeamID : Integer; Source, Target : TPerson; Status : EnumMatchmakingTeamInviteStatus);
begin
  FID := TeamID;
  FStatus := Status;
  FTarget := Target;
end;

procedure TMatchmakingTeamInvite.Decline;
begin
  MainActionQueue.DoAction(TMatchmakingTeamInviteActionDecline.Create(self));
end;

function TMatchmakingTeamInvite.IsPending : boolean;
begin
  Result := Status = tiOpen;
end;

procedure TMatchmakingTeamInvite.SetStatus(const Value : EnumMatchmakingTeamInviteStatus);
begin
  FStatus := Value;
end;

{ TMatchmakingQueue }

constructor TMatchmakingQueue.Create(SourceMatchmakingTeam : TMatchmakingTeam; QueueData : RMatchmakingQueueData);
begin
  FMatchmakingTeam := SourceMatchmakingTeam;
  FEnterTimestamp := GetTickCount;
  UpdateQueueData(QueueData);
  RPCHandlerManager.SubscribeHandler(self);
end;

destructor TMatchmakingQueue.Destroy;
begin
  FMatchmakingTeam.FQueue := nil;
  RPCHandlerManager.UnsubscribeHandler(self);
  inherited;
end;

function TMatchmakingQueue.GetScenario : TScenarioInstance;
begin
  assert(assigned(FMatchmakingTeam));
  Result := FMatchmakingTeam.ScenarioInstance;
end;

function TMatchmakingQueue.GetTimeInQueue : Integer;
begin
  // transform msec -> sec
  Result := (GetTickCount - FEnterTimestamp) div 1000;
end;

procedure TMatchmakingQueue.LeaveQueue;
begin
  MatchmakingAPI.LeaveQueue(FMatchmakingTeam.FUID).Free;
end;

procedure TMatchmakingQueue.QueueLeft(Leaver : RMatchmakingUser);
begin
  FMatchmakingTeam.FQueue := nil;
  if assigned(FOnQueueLeft) then
      OnQueueLeft(self, FMatchmakingTeam.FManager.FAccount.GetPerson(Leaver))
  else
      raise EMatchmakingError.Create('TMatchmakingQueue.QueueLeft: No callback for OnQueueLeft is set.');
end;

procedure TMatchmakingQueue.ServerQueueError;
begin
  if assigned(OnServerQueueError) then
      OnServerQueueError();
end;

procedure TMatchmakingQueue.SetPlayerCount(const Value : Integer);
begin
  FPlayerCount := Value;
end;

procedure TMatchmakingQueue.SetServerAvailable(const Value : boolean);
begin
  FServerAvailable := Value;
end;

procedure TMatchmakingQueue.UpdateQueueData(Data : RMatchmakingQueueData);
begin
  PlayerCount := Data.players_in_queue;
  ServerAvailable := Data.server_available;
  if assigned(OnChange) then OnChange(self);
end;

{ TMatchmakingTeamSetScenarioAction }

constructor TMatchmakingTeamActionSetScenarioInstance.Create(MatchmakingTeam : TMatchmakingTeam; NewScenario : TScenarioInstance);
begin
  inherited Create(MatchmakingTeam);
  FNewScenario := NewScenario;
  FOldScenario := MatchmakingTeam.ScenarioInstance;
end;

procedure TMatchmakingTeamActionSetScenarioInstance.Emulate;
begin
  FMatchmakingTeam.ScenarioInstance := FNewScenario;
end;

function TMatchmakingTeamActionSetScenarioInstance.Execute : boolean;
begin
  if assigned(FNewScenario) then
      Result := HandlePromise(MatchmakingAPI.SetScenario(FMatchmakingTeam.FUID, FNewScenario.ID))
  else
      Result := HandlePromise(MatchmakingAPI.SetScenario(FMatchmakingTeam.FUID, -1));
end;

procedure TMatchmakingTeamActionSetScenarioInstance.Rollback;
begin
  FMatchmakingTeam.ScenarioInstance := FOldScenario;
end;

{ TMatchmakingTeamAction }

constructor TMatchmakingTeamAction.Create(MatchmakingTeam : TMatchmakingTeam);
begin
  inherited Create();
  FMatchmakingTeam := MatchmakingTeam;
end;

{ TMatchmakingTeamActionKickPlayer }

constructor TMatchmakingTeamActionKickPlayer.Create(MatchmakingTeam : TMatchmakingTeam; Member : TMatchmakingMember);
begin
  inherited Create(MatchmakingTeam);
  FMember := Member;
end;

procedure TMatchmakingTeamActionKickPlayer.Emulate;
begin
  FIndex := FMatchmakingTeam.Players.IndexOf(FMember);
  FMatchmakingTeam.Players.Extract(FMember);
  FMatchmakingTeam.UpdateMembers;
end;

function TMatchmakingTeamActionKickPlayer.Execute : boolean;
begin
  Result := HandlePromise(MatchmakingAPI.KickPlayerFromTeam(FMember.Owner.PersonID, FMatchmakingTeam.FUID));
end;

procedure TMatchmakingTeamActionKickPlayer.Finished;
begin
  inherited;
  FMember.Free;
end;

procedure TMatchmakingTeamActionKickPlayer.Rollback;
begin
  FMatchmakingTeam.Players.Insert(FIndex, FMember);
  FMember := nil;
  FMatchmakingTeam.UpdateMembers;
end;

{ TMatchmakingManagerActionLoadCurrentTeam }

procedure TMatchmakingManagerActionLoadCurrentTeam.Emulate;
begin
  FOldTeam := FMatchmakingManager.CurrentTeam;
  FNewTeam := TMatchmakingTeam.Create(FMatchmakingManager);
  FMatchmakingManager.CurrentTeam := FNewTeam;
end;

function TMatchmakingManagerActionLoadCurrentTeam.Execute : boolean;
var
  TeamData : TPromise<RMatchmakingTeam>;
begin
  TeamData := MatchmakingAPI.GetCurrentTeam();
  TeamData.WaitForData;
  if TeamData.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        FOldTeam.Free;
        FNewTeam.FUID := TeamData.Value.team_uuid;
        FNewTeam.TeamUpdate(TeamData.Value);
      end);
  end
  else HandlePromiseError(TeamData);
  Result := TeamData.WasSuccessful;
  TeamData.Free;
end;

procedure TMatchmakingManagerActionLoadCurrentTeam.Rollback;
begin
  if FMatchmakingManager.CurrentTeam = FNewTeam then
      FMatchmakingManager.CurrentTeam := FOldTeam;
  FNewTeam.Free;
end;

{ TMatchmakingManagerAction }

constructor TMatchmakingManagerAction.Create(MatchmakingManager : TMatchmakingManager);
begin
  inherited Create();
  FMatchmakingManager := MatchmakingManager;
end;

{ TMatchmakingTeamActionInvitePlayer }

constructor TMatchmakingTeamActionInvitePlayer.Create(MatchmakingTeam : TMatchmakingTeam; Friend : TPerson);
begin
  inherited Create(MatchmakingTeam);
  FFriend := Friend;
end;

procedure TMatchmakingTeamActionInvitePlayer.Emulate;
begin
  inherited;
  // only add invite to list, if not already an invite for target player exists
  if FMatchmakingTeam.Invites.Query.Filter(F('Target.PersonID') = FFriend.PersonID).Exists() then
      FInvite := nil
  else
  begin
    FInvite := TMatchmakingTeamInvite.CreateOutgoing(-1, FMatchmakingTeam.FManager.FAccount.Own, FFriend, tiOpen);
    FMatchmakingTeam.Invites.Add(FInvite);
  end;
end;

function TMatchmakingTeamActionInvitePlayer.Execute : boolean;
begin
  Result := HandlePromise(MatchmakingAPI.InviteFriendToTeam(FFriend.PersonID, FMatchmakingTeam.FUID))
end;

procedure TMatchmakingTeamActionInvitePlayer.Rollback;
begin
  // when invite already exists in db, it was not created
  if FInvite <> nil then
      FMatchmakingTeam.Invites.Remove(FInvite);
end;

{ TMatchmakingTeamActionPromotePlayer }

constructor TMatchmakingTeamActionPromotePlayer.Create(MatchmakingTeam : TMatchmakingTeam; NewLeader : TMatchmakingMember);
begin
  inherited Create(MatchmakingTeam);
  FNewLeader := NewLeader;
end;

procedure TMatchmakingTeamActionPromotePlayer.Emulate;
begin
  FOldLeader := FMatchmakingTeam.Leader;
  FOldLeader.IsLeader := False;
  FMatchmakingTeam.Players.SignalItemChanged(FOldLeader);
  FNewLeader.IsLeader := True;
  FMatchmakingTeam.Players.SignalItemChanged(FNewLeader);
  FMatchmakingTeam.UpdateMembers;
end;

function TMatchmakingTeamActionPromotePlayer.Execute : boolean;
begin
  Result := HandlePromise(MatchmakingAPI.PromoteMemberToLeader(FNewLeader.Owner.PersonID, FMatchmakingTeam.FUID));
end;

procedure TMatchmakingTeamActionPromotePlayer.Rollback;
begin
  FOldLeader.IsLeader := True;
  FMatchmakingTeam.Players.SignalItemChanged(FOldLeader);
  FNewLeader.IsLeader := False;
  FMatchmakingTeam.Players.SignalItemChanged(FNewLeader);
end;

{ TMatchmakingTeamActionSetCurrentDeck }

constructor TMatchmakingTeamActionSetCurrentDeck.Create(MatchmakingTeam : TMatchmakingTeam; NewDeck : TDeck);
begin
  inherited Create(MatchmakingTeam);
  FNewDeck := NewDeck;
end;

procedure TMatchmakingTeamActionSetCurrentDeck.Emulate;
begin
  FOldDeck := FMatchmakingTeam.Deck;
  FMatchmakingTeam.Deck := FNewDeck;
  FMatchmakingTeam.UpdateMemberDeck;
end;

function TMatchmakingTeamActionSetCurrentDeck.Execute : boolean;
begin
  if assigned(FNewDeck) then
      Result := HandlePromise(MatchmakingAPI.SetCurrentDeck(FNewDeck.ID))
  else
      Result := HandlePromise(MatchmakingAPI.SetCurrentDeck(-1));
end;

procedure TMatchmakingTeamActionSetCurrentDeck.Rollback;
begin
  FMatchmakingTeam.Deck := FOldDeck;
  FMatchmakingTeam.UpdateMemberDeck;
end;

{ TMatchmakingTeamActionLeave }

procedure TMatchmakingTeamActionLeave.Emulate;
begin
  FOldTeam := FMatchmakingTeam;
  FMatchmakingTeam.FManager.CurrentTeam := nil;
end;

function TMatchmakingTeamActionLeave.Execute : boolean;
begin
  Result := HandlePromise(MatchmakingAPI.LeaveTeam(FMatchmakingTeam.FUID));
  // leave was successful, no need to keep old team any longer
  if Result then
      FOldTeam.Free;
end;

procedure TMatchmakingTeamActionLeave.Rollback;
begin
  FMatchmakingTeam.FManager.CurrentTeam := FOldTeam;
end;

{ TMatchmakingTeamInviteAction }

constructor TMatchmakingTeamInviteAction.Create(Invite : TMatchmakingTeamInvite);
begin
  inherited Create();
  FInvite := Invite;
end;

{ TTMatchmakingTeamInviteActionDecline }

procedure TMatchmakingTeamInviteActionDecline.Emulate;
begin
  FInvite.Status := tiDeclined;
  FInvite.FMatchmakingManager.UpdateCurrentInvite;
  FInvite.FMatchmakingManager.FInvites.SignalItemChanged(FInvite);
end;

function TMatchmakingTeamInviteActionDecline.Execute : boolean;
begin
  Result := HandlePromise(MatchmakingAPI.DeclineInvite(FInvite.FID));
end;

procedure TMatchmakingTeamInviteActionDecline.Rollback;
begin
  // don't set status back to open on failure, because this would cause in not closing
  // invite popups
  // FInvite.FStatus := tiOpen;
  // FInvite.FMatchmakingManager.FInvites.SignalItemChanged(FInvite);
  FInvite.FMatchmakingManager.UpdateCurrentInvite;
end;

{ TTMatchmakingTeamInviteActionAccept }

procedure TMatchmakingTeamInviteActionAccept.Emulate;
begin
  FOldTeam := FInvite.FMatchmakingManager.CurrentTeam;
  FNewTeam := TMatchmakingTeam.Create(Matchmaking, False);
  FInvite.FMatchmakingManager.CurrentTeam := FNewTeam;
  FInvite.Status := tiAccepted;
  FInvite.FMatchmakingManager.FInvites.SignalItemChanged(FInvite);
  FInvite.FMatchmakingManager.UpdateCurrentInvite;
end;

function TMatchmakingTeamInviteActionAccept.Execute : boolean;
var
  TeamData : TPromise<RMatchmakingTeam>;
begin
  TeamData := MatchmakingAPI.AcceptInvite(FInvite.FID);
  TeamData.WaitForData;
  if TeamData.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        FNewTeam.FUID := TeamData.Value.team_uuid;
        FNewTeam.TeamUpdate(TeamData.Value);
      end
      );
    FOldTeam.Free;
  end
  else HandlePromiseError(TeamData);
  Result := TeamData.WasSuccessful;
  TeamData.Free;
end;

procedure TMatchmakingTeamInviteActionAccept.Rollback;
begin
  if FInvite.FMatchmakingManager.CurrentTeam = FNewTeam then
      FInvite.FMatchmakingManager.CurrentTeam := FOldTeam;
  FNewTeam.Free;
  FInvite.FMatchmakingManager.UpdateCurrentInvite;
end;

{ TMatchmakingDeck }

procedure TMatchmakingDeck.SetIcon(const Value : string);
begin
  FIcon := Value;
end;

procedure TMatchmakingDeck.SetIsSet(const Value : boolean);
begin
  FIsSet := Value;
end;

procedure TMatchmakingDeck.SetLeague(const Value : Integer);
begin
  FLeague := Value;
end;

procedure TMatchmakingDeck.SetName(const Value : string);
begin
  FName := Value;
end;

{ TMatchmakingMember }

constructor TMatchmakingMember.Create(const Owner : TPerson);
begin
  FOwner := Owner;
  FDeck := TMatchmakingDeck.Create;
end;

destructor TMatchmakingMember.Destroy;
begin
  FDeck.Free;
  inherited;
end;

procedure TMatchmakingMember.SetIsKickable(const Value : boolean);
begin
  FIsKickable := Value;
end;

procedure TMatchmakingMember.SetIsLeader(const Value : boolean);
begin
  FIsLeader := Value;
end;

{ TMatchmakingTeamActionEnterQueue }

function TMatchmakingTeamActionEnterQueue.Execute : boolean;
begin
  Result := HandlePromise(MatchmakingAPI.EnterQueue(FMatchmakingTeam.FUID));
end;

{ TLeaderboardManager }

constructor TLeaderboardManager.Create;
begin
  FLeaderboards := TUltimateObjectList<TLeaderboard>.Create;
  ReloadLeaderboards;
end;

destructor TLeaderboardManager.Destroy;
begin
  FreeAndNil(FLeaderboards);
  inherited;
end;

procedure TLeaderboardManager.LoadLeaderboards(Data : RLeaderboardData);
var
  i : Integer;
begin
  FLeaderboards.Clear;
  for i := 0 to length(Data) - 1 do
      FLeaderboards.Add(TLeaderboard.Create(Data[i]));
  if assigned(OnLeaderboardsLoaded) then
      OnLeaderboardsLoaded();
end;

procedure TLeaderboardManager.ReloadLeaderboards;
begin
  MainActionQueue.DoAction(TLeaderboardsLoadAction.Create(self));
end;

{ TLeaderboardsLoadAction }

constructor TLeaderboardsLoadAction.Create(LeaderboardManager : TLeaderboardManager);
begin
  inherited Create();
  FLeaderboardManager := LeaderboardManager;
end;

function TLeaderboardsLoadAction.GetData : TPromise<RLeaderboardData>;
begin
  Result := MatchmakingAPI.GetLeaderboards();
end;

procedure TLeaderboardsLoadAction.ProcessData(const Data : RLeaderboardData);
begin
  FLeaderboardManager.LoadLeaderboards(Data);
end;

{ TLeaderboard }

constructor TLeaderboard.Create(Data : RLeaderboardForLeague);
var
  i : Integer;
begin
  FTopList := TUltimateList<RLeaderboardEntry>.Create;
  FPlayerList := TUltimateList<RLeaderboardEntry>.Create;
  for i := 0 to length(Data.leaderboard.top_placements) - 1 do
      FTopList.Add(RLeaderboardEntry.Create(Data.leaderboard.top_placements[i]));
  for i := 0 to length(Data.leaderboard.player_placements) - 1 do
      FPlayerList.Add(RLeaderboardEntry.Create(Data.leaderboard.player_placements[i]));
  if ScenarioManager.TryResolveScenarioInstance(Data.scenario_instance_id, FScenarioInstance) then
  begin
    FLeague := FScenarioInstance.League;
    if FScenarioInstance.Scenario.IsPvE then
        FFormat := lfTime
    else
        FFormat := lfRank;
  end;
end;

destructor TLeaderboard.Destroy;
begin
  FTopList.Free;
  FPlayerList.Free;
  inherited;
end;

{ RLeaderboardEntry }

constructor RLeaderboardEntry.Create(const Data : RLeaderboardRow);
begin
  self.Rank := Data.position;
  self.Points := Data.Points;
  self.PlayerID := Data.user_id;
  self.PlayerName := Data.nickname;
  self.PlayerIcon := Data.icon_identifier;
end;

end.
