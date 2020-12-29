unit BaseConflict.Game.Server;

interface

uses
  // Delphi
  System.SysUtils,
  System.Math,
  System.Rtti,
  System.Generics.Collections,
  System.Classes,
  System.SyncObjs,
  Vcl.Forms,
  // 3rd party
  Winapi.Windows,
  Winapi.MMSystem,
  madExcept,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Serializer.JSON,
  Engine.Math,
  Engine.Script,
  Engine.Network,
  Engine.Network.RPC,
  Engine.Log,
  // Game
  BaseConflict.Api,
  BaseConflict.Api.Account,
  BaseConflict.Api.Types,
  BaseConflict.Game,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Server,
  BaseConflict.EntityComponents.Server.Warheads,
  BaseConflict.EntityComponents.Server.Brains,
  BaseConflict.EntityComponents.Server.Brains.Special,
  BaseConflict.EntityComponents.Server.Welas,
  BaseConflict.EntityComponents.Server.Welas.Special,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Scenario,
  BaseConflict.Classes.Server,
  BaseConflict.Classes.Shared,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Server,
  BaseConflict.Map;

type

  {$RTTI EXPLICIT METHODS([vcPublic]) FIELDS([vcPublic]) PROPERTIES([vcPublic])}
  THeartbeatManager = class;

  THeartbeat = class
    private
      FCurrentHeartbeat : LongWord;
      FHeartbeatManager : THeartbeatManager;
    public
      constructor Create(HeartbeatManager : THeartbeatManager);
      procedure DoBeat;
  end;

  THeartbeatManager = class
    private const
      TARGET_FRAMETIME = 32; // ms
    private type
      THeartbeatThread = class(TThread)
        strict private
          FTimer : THandle;
          FHeartbeatCounter : LongWord;
          FHeartbeatEvent : TEvent;
        protected
          procedure Execute; override;
        public
          property HeartbeatEvent : TEvent read FHeartbeatEvent;
          property HeartbeatCounter : LongWord read FHeartbeatCounter;
          constructor Create;
          destructor Destroy; override;
      end;
    private
      FHeartbeatThread : THeartbeatThread;
    public
      constructor Create;
      function GetHeartbeat : THeartbeat;
      destructor Destroy; override;
  end;

  EnumGameFinishedState = (gfNone, gfCrashed, gfFinished, gfAborted);

  [ScriptExcludeAll]
  TServerGame = class(TGame)
    var
      FGlobalEventbus : TEventbus;
      FFinished : boolean;
      FWinnerTeamID, FSurrenderedTeamID : integer;
      FCommanders : TAdvancedList<TEntity>;
      FServerEntityManager : TServerEntityManagerComponent;
      FGameStatistics : TGameStatisticManager;
      FDelayedEvents : TIntPriorityQueue<TDelayedEventHandler>;
      FScenarioDirector : TScenarioDirectorComponent;
      function GetServerGameInformation : TServerGameInformation;
    private
      FEventstack : TFastStack<REventInformation>;
    protected
      function GetServerTime : Int64; override;
    public
      property GlobalEventbus : TEventbus read FGlobalEventbus;
      property Statistics : TGameStatisticManager read FGameStatistics;
      property DelayedEvents : TIntPriorityQueue<TDelayedEventHandler> read FDelayedEvents write FDelayedEvents;
      property GameInformation : TServerGameInformation read GetServerGameInformation;
      [ScriptIncludeMember]
      property ServerEntityManager : TServerEntityManagerComponent read FServerEntityManager;
      [ScriptIncludeMember]
      property ScenarioDirector : TScenarioDirectorComponent read FScenarioDirector write FScenarioDirector;
      /// <summary> All commanders in this game. (don't free this list). </summary>
      property Commanders : TAdvancedList<TEntity> read FCommanders;
      property IsFinished : boolean read FFinished;
      /// <summary> All commander of a certain team in this game. (free this list) </summary>
      function GetCommandersPerTeam(TeamID : integer) : TAdvancedList<TEntity>;
      function GetTeamCount : integer;
      /// <summary> Will start game. That starts the prepare timer.</summary>
      procedure Start;
      procedure TeamLost(const TeamID : integer);
      procedure TeamSurrendered(const TeamID : integer);
      procedure BuildStatistics(var Statistics : RGameFinishedStatistics);
      /// <summary> Initialized the players. </summary>
      procedure Initialize; override;
      procedure Idle; override;
      constructor Create(GameInformation : TServerGameInformation);
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPrivate, vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  TGameThread = class;

  /// <summary> Manage all! games and provide some info and control methods.</summary>
  TGameManager = class(TInterfacedObject, IGameServerBackchannel)
    private
      FGameThreads : TList<TGameThread>;
      FOnNewLogMessage : ProcNewLogMessage;
      FOpenGamePorts : array of boolean;
      FGamesServed : integer;
      FAccount : TAccount;
      FBreakOnException, FIsTestServer : boolean;
      // when true, no new games can created
      FStopNewGames : boolean;
      /// <summary> Return a available port and reserve them</summary>
      function GetOpenPort : Word;
      function CreateDefaultGameInfo : TServerGameInformation;
      function CreateTestserverGameInfo : TServerGameInformation;
      function CreateTutorialGameInfo : TServerGameInformation;
      procedure InitTutorialCommander(Commander : TCommanderInformation);
      function GetGameRunning : integer;
      function CheckGameOnline(GameID : string) : boolean;
      /// <summary> Backchannel implementation. Called by manage server.</summary>
      function CreateGame(GameData : RGameCreateData) : RGameReponseData;
      /// <summary> Reports a message to assigned NewLogMessage callback.</summary>
      procedure Report(const Msg : string);
      /// <summary> Will shutdown the server by killing all currently runnining games and will prevent that new games are created.</summary>
      procedure ShutdownServer;
    public
      property IsTestServer : boolean read FIsTestServer write FIsTestServer;
      property BreakOnException : boolean read FBreakOnException write FBreakOnException;
      property GamesServed : integer read FGamesServed;
      property GamesRunning : integer read GetGameRunning;
      property GameThreads : TList<TGameThread> read FGameThreads;
      constructor Create(OnNewLogMessage : ProcNewLogMessage);
      /// <summary> Create new game with given informations and returns address of new created server.
      /// <param name="GameInformation"> Gameinfo (description) for game to be created, like teams and players.</param>summary>
      function CreateNewGame(GameInformation : TServerGameInformation) : RInetAddress;
      /// <summary> Remove a gamethread from this manager. Cleanup is </summary>
      procedure RemoveGame(GameThread : TGameThread; UsedPort : Word);
      /// <summary> Kill all currently running games. If testserver should running, a new testserver will automatically created.</summary>
      procedure KillAllGames;
      procedure Idle;
      /// <summary> Force sending a gametick to all games.</summary>
      procedure SendGameTick;
      /// <summary> Free all allocated Resources and end all games!</summary>
      destructor Destroy; override;
  end;

  TGameThread = class(TThread)
    strict private
    const
      TIMEOUT_TIME = 30 * 1000;
      DEAD_TIME    = 30 * 60 * 1000; // after 30min of no client connection this game is marked dead

    type
      EnumGameThreadState = (
        gsWaitingForPlayers,
        gsRunning,
        gsAborted
        );
    var
      FCurrentFrameRate, FConnectedPlayerCount : integer;
      FTimeFromStart : Int64;
      FServerGame : TServerGame;
      FNetworkComponent : TServerNetworkComponent;
      FOverwatch : boolean;
      FTicksToGo : integer;
      FGameTimeManager : TTimeManager;
      FActiveEntities : integer;
      FGameManager : TGameManager;
      FEntityDataCache : TEntityDataCache;
      FGameID : string;
      ErrorMsg : string;
      FHeartbeat : THeartbeat;
      FFPSLimiter : TFPSCounter;
      FGameFinishedState : EnumGameFinishedState;
      FTimeSinceCreate : TTimer;
      FState : EnumGameThreadState;
      procedure Report(const Msg : string);
    private
      procedure PrepareGame;
      procedure DoComputeGame;
      /// <summary> Report gamefinished data to server and return result if an error occur.</summary>
      function ReportGameFinished(State : EnumGameFinishedState; const LogFileContent, ErrorMsg : string) : string;
    protected
      procedure Execute; override;
    public
      /// <summary> Direct access to game that is managed by thread. Should only used with care,
      /// becaue game will changed in thread context. Whenever possible use special properties.</summary>
      property InternalGame : TServerGame read FServerGame;
      property GameID : string read FGameID;
      property CurrentFrameRate : integer read FCurrentFrameRate;
      property TimeFromStart : Int64 read FTimeFromStart;
      property ConnectedPlayerCount : integer read FConnectedPlayerCount;
      property State : EnumGameThreadState read FState;
      /// <summary> Will kill game as fast as possible. Game will reported as forced shutdown.</summary>
      procedure ForceShutdownGame;
      constructor Create(GameInformation : TServerGameInformation; GameManager : TGameManager);
      procedure SendGameTick;
      /// <summary> Returns the milliseconds since creation. </summary>
      function TimeSinceCreate : Int64;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}

var
  MULTITHREADING_ENABLED : boolean = True;
  HeartbeatManager : THeartbeatManager;

implementation

uses
  BaseConflict.Globals,
  BaseConflict.Globals.Server;

{ TGameManager }

function TGameManager.CreateDefaultGameInfo : TServerGameInformation;
  function CreateCommander(Color : EnumEntityColor; TeamID : integer) : TCommanderInformation;
  var
    i, Tier : integer;
    Picked : TAdvancedList<integer>;
    Order : TObjectDictionary<integer, TList<RCommanderCard>>;
    TierList : TList<RCommanderCard>;
    CardUID : string;
    CardInfo : TCardInfo;
    Colors : SetEntityColor;
  begin
    Result := TCommanderInformation.Create;
    Result.TeamID := TeamID;
    Result.Deckname := 'Sandbox';
    Picked := TAdvancedList<integer>.Create;
    Order := TObjectDictionary < integer, TList < RCommanderCard >>.Create([doOwnsValues]);
    if Color = ecWhite then Colors := [ecWhite]
    else if Color = ecGreen then Colors := [ecGreen]
    else if Color = ecBlack then Colors := [ecBlack]
    else if Color = ecColorless then Colors := [ecColorless]
    else if Color = ecRed then Colors := [ecColorless]
    else Colors := ALL_COLORS - [ecWhite, ecGreen, ecBlack, ecColorless];
    for CardUID in CardInfoManager.GetAllCardUIDs do
      if CardInfoManager.TryResolveCardUID(CardUID, DEFAULT_LEAGUE, DEFAULT_LEVEL, CardInfo) then
      begin
        if (CardInfo.CardColors * Colors <> []) and ((Color <> ecRed) or (CardInfo.Filename.Contains(FILE_IDENTIFIER_GOLEMS)))
          and ((Color <> ecColorless) or not(CardInfo.Filename.Contains(FILE_IDENTIFIER_GOLEMS))) then
        begin
          Result.Cards.Add(RCommanderCard.Create(CardInfo.UID, DEFAULT_LEAGUE, DEFAULT_LEVEL));

          Tier := CardInfo.Techlevel;
          if not Order.TryGetValue(Tier, TierList) then
          begin
            TierList := TList<RCommanderCard>.Create;
            Order.Add(Tier, TierList);
          end;
          TierList.Add(RCommanderCard.Create(CardInfo.UID, DEFAULT_LEAGUE, DEFAULT_LEVEL));
        end;
      end;

    // sort for Tier
    Result.Cards.Clear;
    for Tier := 0 to 10 do
      if Order.TryGetValue(Tier, TierList) then
      begin
        for i := 0 to TierList.Count - 1 do
            Result.Cards.Add(TierList[i]);
      end;
    Order.Free;
    Picked.Free;
  end;

var
  Player : TGamePlayer;
  SecretKey : string;
begin
  // create default gamesettings
  Result := TServerGameInformation.Create;
  Result.ScenarioUID := TESTSERVER_SCENARIO_UID;
  Result.League := TESTSERVER_SENARIO_LEAGUE;
  Result.IsSandboxOverride := TESTSERVER_SCENARIO_UID.Contains(SCENARIO_SANDBOX_UID);
  Result.Scenario := HScenario.ResolveScenario(TESTSERVER_SCENARIO_UID, TESTSERVER_SENARIO_LEAGUE);

  Result.CoopVsAI := True;

  SecretKey := '1';
  Player := TGamePlayer.Create(0, 0, 'Player 1');
  Result.AddPlayer(SecretKey, Player);

  Result.Slots.Add(CreateCommander(ecBlack, 1));
  Result.Slots.Add(CreateCommander(ecGreen, 1));
  Result.Slots.Add(CreateCommander(ecWhite, 1));
  Result.Slots.Add(CreateCommander(ecRed, 1));
  Result.Slots.Add(CreateCommander(ecBlue, 1));
  Result.Slots.Add(CreateCommander(ecColorless, 1));

  Result.Slots.Add(CreateCommander(ecBlack, 2));
  Result.Slots.Add(CreateCommander(ecGreen, 2));
  Result.Slots.Add(CreateCommander(ecWhite, 2));
  Result.Slots.Add(CreateCommander(ecRed, 2));
  Result.Slots.Add(CreateCommander(ecBlue, 2));
  Result.Slots.Add(CreateCommander(ecColorless, 2));

  Result.Slots.Add(CreateCommander(ecColorless, PVE_TEAM_ID));

  Result.Mapping.Add(SecretKey, TList<integer>.Create);
  Result.Mapping[SecretKey].Add(0);
  Result.Mapping[SecretKey].Add(1);
  Result.Mapping[SecretKey].Add(2);
  Result.Mapping[SecretKey].Add(3);
  Result.Mapping[SecretKey].Add(4);
  Result.Mapping[SecretKey].Add(5);
  Result.Mapping[SecretKey].Add(6);
  Result.Mapping[SecretKey].Add(7);
  Result.Mapping[SecretKey].Add(8);
  Result.Mapping[SecretKey].Add(9);
  Result.Mapping[SecretKey].Add(10);
  Result.Mapping[SecretKey].Add(11);
  Result.Mapping[SecretKey].Add(12);
end;

function TGameManager.CreateGame(GameData : RGameCreateData) : RGameReponseData;
var
  i, j, Slot : integer;
  Gameinfo : TServerGameInformation;
  SecretKey : string;
  Player : TGamePlayer;
  Commander : TCommanderInformation;
  PlayerData : RGameCreatePlayer;
  GameServerAddress : RInetAddress;
  CurrentCard : TCardInfo;
begin
  inc(FGamesServed);
  if GameData.scenario_instance.scenario_identifier.Contains(SCENARIO_SANDBOX_UID) then
  begin
    // add sandbox decks
    Gameinfo := CreateDefaultGameInfo;
    Gameinfo.ScenarioUID := GameData.scenario_instance.scenario_identifier;
    Gameinfo.League := GameData.scenario_instance.Tier;
    Gameinfo.Scenario := HScenario.ResolveScenario(Gameinfo.ScenarioUID, Gameinfo.League);

    // add selected deck for team 2
    PlayerData := GameData.Slots[0];
    Commander := TCommanderInformation.Create;
    Commander.TeamID := 2;
    Commander.Deckname := PlayerData.Deckname;
    for j := 0 to length(PlayerData.Cards) - 1 do
    begin
      CurrentCard := CardInfoManager.ResolveCardUID(PlayerData.Cards[j].base_card_uid, PlayerData.Cards[j].Tier, PlayerData.Cards[j].level);
      if DISABLE_LEAGUE_SYSTEM then
          Commander.Cards.Add(RCommanderCard.Create(CurrentCard.UID, DEFAULT_LEAGUE, DEFAULT_LEVEL))
      else
          Commander.Cards.Add(RCommanderCard.Create(CurrentCard.UID, CurrentCard.League, CurrentCard.level))
    end;
    Gameinfo.Slots.Insert(0, Commander);
    // add selected deck for team 1
    PlayerData := GameData.Slots[0];
    Commander := TCommanderInformation.Create;
    Commander.TeamID := 1;
    Commander.Deckname := PlayerData.Deckname;
    for j := 0 to length(PlayerData.Cards) - 1 do
    begin
      CurrentCard := CardInfoManager.ResolveCardUID(PlayerData.Cards[j].base_card_uid, PlayerData.Cards[j].Tier, PlayerData.Cards[j].level);
      if DISABLE_LEAGUE_SYSTEM then
          Commander.Cards.Add(RCommanderCard.Create(CurrentCard.UID, DEFAULT_LEAGUE, DEFAULT_LEVEL))
      else
          Commander.Cards.Add(RCommanderCard.Create(CurrentCard.UID, CurrentCard.League, CurrentCard.level))
    end;
    Gameinfo.Slots.Insert(0, Commander);

    Gameinfo.League := GameData.scenario_instance.Tier;
    assert(length(GameData.Slots) = 1, 'TGameManager.CreateGame: Sandbox game assumes only one player!');
    SecretKey := PlayerData.secret_key;
    Gameinfo.Player.Clear;
    Gameinfo.AddPlayer(SecretKey, TGamePlayer.Create(PlayerData.user_id, PlayerData.team_id, PlayerData.username));
    Gameinfo.Mapping.Clear;
    Gameinfo.Mapping.Add(SecretKey, TList<integer>.Create);
    // sandbox commanders and real commanders
    Gameinfo.Mapping[SecretKey].Add(0);
    Gameinfo.Mapping[SecretKey].Add(1);
    Gameinfo.Mapping[SecretKey].Add(2);
    Gameinfo.Mapping[SecretKey].Add(3);
    Gameinfo.Mapping[SecretKey].Add(4);
    Gameinfo.Mapping[SecretKey].Add(5);
    Gameinfo.Mapping[SecretKey].Add(6);
    Gameinfo.Mapping[SecretKey].Add(7);
    Gameinfo.Mapping[SecretKey].Add(8);
    Gameinfo.Mapping[SecretKey].Add(9);
    Gameinfo.Mapping[SecretKey].Add(10);
    Gameinfo.Mapping[SecretKey].Add(11);
    Gameinfo.Mapping[SecretKey].Add(12);
    Report('[INFO] Finished set up sandbox.');
  end
  else if GameData.scenario_instance.scenario_identifier.Contains(SCENARIO_PVE_TUTORIAL) then
  begin
    Gameinfo := CreateTutorialGameInfo;
    Gameinfo.League := GameData.scenario_instance.Tier;
    Gameinfo.ScenarioUID := GameData.scenario_instance.scenario_identifier;
    try
      Gameinfo.Scenario := HScenario.ResolveScenario(GameData.scenario_instance.scenario_identifier, Gameinfo.League);
    except
      Report('[ERROR] Could not find scenario ' + GameData.scenario_instance.scenario_identifier + '.');
      raise;
    end;
    PlayerData := GameData.Slots[0];
    SecretKey := PlayerData.secret_key;
    Gameinfo.Mapping.Clear;

    for i := 0 to Gameinfo.Slots.Count - 1 do
    begin
      if not Gameinfo.Mapping.ContainsKey(SecretKey) then
          Gameinfo.Mapping.Add(SecretKey, TList<integer>.Create);
      Gameinfo.Mapping[SecretKey].Add(i);
      Player := TGamePlayer.Create(PlayerData.user_id, PlayerData.team_id, PlayerData.username);
      Gameinfo.AddPlayer(SecretKey, Player);
    end;
  end
  else
  begin
    Gameinfo := TServerGameInformation.Create;
    Gameinfo.League := GameData.scenario_instance.Tier;
    Gameinfo.ScenarioUID := GameData.scenario_instance.scenario_identifier;
    try
      Gameinfo.Scenario := HScenario.ResolveScenario(GameData.scenario_instance.scenario_identifier, Gameinfo.League);
    except
      Report('[ERROR] Could not find scenario ' + GameData.scenario_instance.scenario_identifier + '.');
      raise;
    end;
    for i := 0 to length(GameData.scenario_instance.mutators) - 1 do
        Gameinfo.mutators.Add(HScenario.ResolveMutator(GameData.scenario_instance.mutators[i].identifier));

    for i := 0 to length(GameData.Slots) - 1 do
    begin
      PlayerData := GameData.Slots[i];
      Commander := TCommanderInformation.Create;
      Commander.TeamID := PlayerData.team_id;
      Commander.Deckname := PlayerData.Deckname;
      Commander.IsBot := PlayerData.is_bot;
      Commander.BotDifficulty := PlayerData.bot_difficulty;

      for j := 0 to length(PlayerData.Cards) - 1 do
      begin
        if DISABLE_LEAGUE_SYSTEM then
        begin
          CurrentCard := CardInfoManager.ResolveCardUID(PlayerData.Cards[j].base_card_uid, DEFAULT_LEAGUE, DEFAULT_LEVEL);
          Commander.Cards.Add(RCommanderCard.CreateMaxed(CurrentCard.UID))
        end
        else
        begin
          CurrentCard := CardInfoManager.ResolveCardUID(PlayerData.Cards[j].base_card_uid, PlayerData.Cards[j].Tier, PlayerData.Cards[j].level);
          Commander.Cards.Add(RCommanderCard.Create(CurrentCard.UID, CurrentCard.League, CurrentCard.level))
        end;
      end;

      SecretKey := PlayerData.secret_key;
      Slot := Gameinfo.Slots.Add(Commander);
      if not Gameinfo.Mapping.ContainsKey(SecretKey) then
          Gameinfo.Mapping.Add(SecretKey, TList<integer>.Create);
      Gameinfo.Mapping[SecretKey].Add(Slot);
      Player := TGamePlayer.Create(PlayerData.user_id, PlayerData.team_id, PlayerData.username);
      Gameinfo.AddPlayer(SecretKey, Player);
    end;
  end;
  Gameinfo.GameID := GameData.UID;

  GameServerAddress := CreateNewGame(Gameinfo);
  Result.UID := GameData.UID;
  Result.Port := GameServerAddress.Port;
end;

function TGameManager.CreateNewGame(GameInformation : TServerGameInformation) : RInetAddress;
begin
  if not FStopNewGames then
  begin
    GameInformation.GamePort := GetOpenPort;

    if GameInformation.GamePort > 0 then
    begin
      if IsTestServer then GameInformation.GameID := '09062316-161e-4067-be51-6df4a987bfb5';
      // create thread will create game, at this point the thread execution will start and game is running
      FGameThreads.Add(TGameThread.Create(GameInformation, self));
      Result := RInetAddress.CreateByUrl(GAMESERVER_OUTBOUND_IP, GameInformation.GamePort);
    end
    else
    begin
      Result := RInetAddress.CreateByUrl('255.255.255.255', Word.MaxValue);
      GameInformation.Free;
    end;
  end
  else
  begin
    Result := RInetAddress.CreateByUrl('255.255.255.255', Word.MaxValue);
    GameInformation.Free;
  end;
end;

function TGameManager.CreateTestserverGameInfo : TServerGameInformation;
var
  Commander : TCommanderInformation;
  SecretKey : string;
begin
  Result := CreateDefaultGameInfo;
  Result.IsSandboxOverride := True;
  // add selected deck for team 2
  Commander := TCommanderInformation.Create;
  Commander.TeamID := 2;
  Commander.Deckname := 'Sandbox';
  InitTutorialCommander(Commander);
  Result.Slots.Insert(0, Commander);
  // add selected deck for team 1
  Commander := TCommanderInformation.Create;
  Commander.TeamID := 1;
  Commander.Deckname := 'Sandbox';
  InitTutorialCommander(Commander);
  Result.Slots.Insert(0, Commander);

  SecretKey := '1';
  Result.Player.Clear;
  Result.AddPlayer(SecretKey, TGamePlayer.Create(1, 1, 'Player'));
  Result.Mapping.Clear;
  Result.Mapping.Add(SecretKey, TList<integer>.Create);
  // sandbox commanders and real commanders
  Result.Mapping[SecretKey].Add(0);
  Result.Mapping[SecretKey].Add(1);
  Result.Mapping[SecretKey].Add(2);
  Result.Mapping[SecretKey].Add(3);
  Result.Mapping[SecretKey].Add(4);
  Result.Mapping[SecretKey].Add(5);
  Result.Mapping[SecretKey].Add(6);
  Result.Mapping[SecretKey].Add(7);
  Result.Mapping[SecretKey].Add(8);
  Result.Mapping[SecretKey].Add(9);
  Result.Mapping[SecretKey].Add(10);
  Result.Mapping[SecretKey].Add(11);
  Result.Mapping[SecretKey].Add(12);
  Result.Mapping[SecretKey].Add(13);
  Result.Mapping[SecretKey].Add(14);
end;

function TGameManager.CreateTutorialGameInfo : TServerGameInformation;
var
  Commander : TCommanderInformation;
begin
  Result := TServerGameInformation.Create;
  Result.CoopVsAI := True;

  Commander := TCommanderInformation.Create;
  Commander.TeamID := 1;
  Commander.Deckname := 'Tutorial';
  InitTutorialCommander(Commander);
  Result.Slots.Insert(0, Commander);
end;

function TGameManager.CheckGameOnline(GameID : string) : boolean;
var
  GameThread : TGameThread;
begin
  Result := False;
  for GameThread in FGameThreads do
  begin
    // if game found, it is running (when can get stopped, it will remove themself from list)
    if GameThread.GameID = GameID then
    begin
      Result := True;
      exit;
    end;
  end;
end;

constructor TGameManager.Create(OnNewLogMessage : ProcNewLogMessage);
var
  i : integer;
  username, password : string;
  Promise : TPromise<boolean>;
begin
  IsTestServer := HFileIO.ReadBoolFromIni(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE), 'Server', 'IS_TESTSERVER', False);
  FGameThreads := TObjectList<TGameThread>.Create(False);
  FOnNewLogMessage := OnNewLogMessage;

  username := HFileIO.ReadFromIni(FormatDateiPfad(GAMESERVER_SETTINGSFILE), 'Account', 'Username', 'broker');
  password := HFileIO.ReadFromIni(FormatDateiPfad(GAMESERVER_SETTINGSFILE), 'Account', 'password', 'broker');

  {$IFDEF DEBUG}
  if FileExists(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE)) then
  begin
    username := HFileIO.ReadFromIni(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE), 'Account', 'Username', username);
    password := HFileIO.ReadFromIni(FormatDateiPfad(GAMESERVER_DEBUG_SETTINGSFILE), 'Account', 'password', password);
  end;
  {$ENDIF}
  FAccount := TAccount.Create(False);

  if not IsTestServer then
  begin
    Report('[INFO] Connecting to manage server...');
    FAccount.LoginWithPassword(username, password);
    // wait until login
    while FAccount.Status = asConnecting do
        Application.ProcessMessages;
    if FAccount.IsConnected then
    begin
      Promise := GameManagerAPI.RegisterGameServer(GAMESERVER_OUTBOUND_IP, GAMESERVER_HTTP_PORT, 32);
      Promise.WaitForData;
      if Promise.WasSuccessful then Report('[INFO] Connected and registered to manage server (' + MANAGE_SERVER_URL + ').')
      else Report('[ERROR] Register at manage server failed.');
      Promise.Free;
    end
    else Report('[ERROR] Could not login on manage server.');
  end
  else Report('[INFO] Testserver');

  setLength(FOpenGamePorts, GAMESERVER_PORTRANGE_LENGTH);
  // "open" all possible ports
  for i := 0 to GAMESERVER_PORTRANGE_LENGTH - 1 do
      FOpenGamePorts[i] := True;

  if IsTestServer then
      CreateNewGame(CreateTestserverGameInfo);

  RPCHandlerManager.SubscribeHandler(self);
end;

destructor TGameManager.Destroy;
begin
  FAccount.Free;
  RPCHandlerManager.UnsubscribeHandler(self);
  ShutdownServer;
  FGameThreads.Free;
  inherited;
end;

procedure TGameManager.RemoveGame(GameThread : TGameThread; UsedPort : Word);
begin
  FGameThreads.Remove(GameThread);

  assert((GAMESERVER_PORTRANGE_MIN <= UsedPort) and (GAMESERVER_PORTRANGE_MAX >= UsedPort));
  // server shutdown, reopen port
  FOpenGamePorts[UsedPort - GAMESERVER_PORTRANGE_MIN] := True;

  if IsTestServer then
      CreateNewGame(CreateTestserverGameInfo);
end;

function TGameManager.GetGameRunning : integer;
begin
  Result := FGameThreads.Count;
end;

function TGameManager.GetOpenPort : Word;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to GAMESERVER_PORTRANGE_LENGTH - 1 do
    // is port available (not used by another game)?
    if FOpenGamePorts[i] then
    begin
      Result := GAMESERVER_PORTRANGE_MIN + i;
      // reserve port
      FOpenGamePorts[i] := False;
      break;
    end;
  if Result = 0 then
      Report('[ERROR] - TGameManager.GetOpenPort: Could not find any free port!');
end;

procedure TGameManager.Idle;
var
  GameThread : TGameThread;
begin
  if not MULTITHREADING_ENABLED then
  begin
    assert(FGameThreads.Count <= 1);
    if FGameThreads.Count > 0 then
    begin
      GameThread := FGameThreads.First;
      GameThread.DoComputeGame;
      if GameThread.Terminated then
          GameThread.Free;
    end;
  end;
end;

procedure TGameManager.InitTutorialCommander(Commander : TCommanderInformation);
begin
  Commander.Cards.Add(RCommanderCard.Create('4a3d81c7-8c6b-454d-9469-95f6cf394c9b', 2, 1)); // 0 - FootmanDrop
  Commander.Cards.Add(RCommanderCard.Create('51c25adb-3f4b-4e89-a972-15c2080933b9', 2, 1)); // 1 - ArcherDrop
  Commander.Cards.Add(RCommanderCard.Create('d6775352-3586-4a2d-af0f-b3149d59dbec', 2, 1)); // 2 - BallistaDrop
  Commander.Cards.Add(RCommanderCard.Create('527dd787-d8e9-4817-b45a-13b72495dbf7', 2, 1)); // 3 - HailOfArrows
  Commander.Cards.Add(RCommanderCard.Create('21780eb8-3d2c-4c97-b279-59971475f3f8', 1, 1)); // 4 - DefenderDrop
  Commander.Cards.Add(RCommanderCard.Create('30b4f36d-03d4-413c-8e9c-dc9f70346c15', 1, 1)); // 5 - ArcherSpawner
  Commander.Cards.Add(RCommanderCard.Create('212b4d7e-65f9-43fa-a3df-50b31dd3da8f', 1, 1)); // 6 - FootmanSpawner
  Commander.Cards.Add(RCommanderCard.Create('212b4d7e-65f9-43fa-a3df-50b31dd3da8f', 1, 1)); // 7 - FootmanSpawner
end;

procedure TGameManager.KillAllGames;
var
  i : integer;
begin
  for i := FGameThreads.Count - 1 downto 0 do
  begin
    FGameThreads[i].ForceShutdownGame;
    // this will terminate the thread and wait for his ending
    FGameThreads[i].FreeOnTerminate := False;
    FGameThreads[i].Free;
  end;
end;

procedure TGameManager.Report(const Msg : string);
begin
  if assigned(FOnNewLogMessage) then
      FOnNewLogMessage(Msg);
end;

procedure TGameManager.SendGameTick;
var
  GameThread : TGameThread;
begin
  for GameThread in FGameThreads do
  begin
    GameThread.SendGameTick;
  end;
end;

procedure TGameManager.ShutdownServer;
begin
  FStopNewGames := True;
  KillAllGames;
end;

{ TGame }

procedure TServerGame.BuildStatistics(var Statistics : RGameFinishedStatistics);
begin
  Statistics.winner_team_id := FWinnerTeamID;
  self.Statistics.BuildStatistics(Statistics);
end;

constructor TServerGame.Create(GameInformation : TServerGameInformation);
begin
  FEventstack := TFastStack<REventInformation>.Create(1000);
  FGameStatistics := TGameStatisticManager.Create;
  FGlobalEventbus := TEventbus.Create(nil);
  FDelayedEvents := TIntPriorityQueue<TDelayedEventHandler>.Create;
  BaseConflict.Globals.GlobalEventbus := FGlobalEventbus;
  inherited Create(GameInformation);
  BaseConflict.Globals.Server.ServerGame := self;
  FCommanders := TAdvancedList<TEntity>.Create;
  FServerEntityManager := TServerEntityManagerComponent.Create(GameEntity);
  FEntityManager := FServerEntityManager;
  CollisionManager := TServerCollisionManagerComponent.Create(GameEntity);
end;

destructor TServerGame.Destroy;
begin
  FCommanders.Free;
  inherited;
  FGlobalEventbus.Free;
  BaseConflict.Globals.GlobalEventbus := nil;
  FEventstack.Free;
  FDelayedEvents.Free;
  FGameStatistics.Free;
end;

function TServerGame.GetCommandersPerTeam(TeamID : integer) : TAdvancedList<TEntity>;
begin
  Result := FCommanders.Filter(
    function(Entity : TEntity) : boolean
    begin
      Result := Entity.TeamID = TeamID;
    end);
end;

function TServerGame.GetServerGameInformation : TServerGameInformation;
begin
  Result := FGameInfo as TServerGameInformation;
end;

function TServerGame.GetServerTime : Int64;
begin
  Result := GameTimeManager.GetTimestamp;
end;

function TServerGame.GetTeamCount : integer;
begin
  Result := FCommanders.Max<integer>(
    function(Entity : TEntity) : integer
    begin
      Result := Entity.TeamID;
    end,
    function(a, b : integer) : integer
    begin
      Result := sign(b - a);
    end).TeamID;
end;

procedure TServerGame.Idle;
var
  DelayedEvent : TDelayedEventHandler;
begin
  inherited;
  while not FDelayedEvents.IsEmpty and (FDelayedEvents.PeekPriority <= GameTimeManager.GetTimestamp) do
  begin
    DelayedEvent := FDelayedEvents.ExtractMin;
    DelayedEvent.Callback;
  end;
  if not FFinished then
      GlobalEventbus.Trigger(eiIdle, []);
end;

procedure TServerGame.Initialize;
  procedure InitializeCommander(Commander : TEntity; CommanderInformation : TCommanderInformation; League : integer);
  var
    i : integer;
  begin
    if Cheatmode then
    begin
      Commander.Blackboard.SetIndexedValue(eiResourceCap, [], ord(reGold), 100000.0);
      Commander.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reGold), 100000.0);
      Commander.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reWood), 10000.0);
      Commander.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reTier), 3);
    end;

    Commander.Eventbus.Write(eiOwnerCommander, [Commander.ID]);
    Commander.Eventbus.Write(eiTeamID, [CommanderInformation.TeamID]);

    // add Cards
    for i := 0 to CommanderInformation.Cards.Count - 1 do
    begin
      TCommanderAbilityComponent.CreateGroupedSlot(Commander, [], CommanderInformation.Cards[i], i);
    end;

    if CommanderInformation.IsBot then
        TPvPBotComponent.Create(Commander)
        .Difficulty(CommanderInformation.BotDifficulty)
        .League(League);
  end;

var
  Commander : TEntity;
  SpectatorInformation : TCommanderInformation;
  Mapping : TObjectDictionary<string, TList<integer>>;
  list : TList<integer>;
  i : integer;
  Token : string;
begin
  // initialze scenario scripts and environment
  inherited;

  // Create Playermapping
  Mapping := TObjectDictionary < string, TList < integer >>.Create([doOwnsValues]);

  // Create Commanders for Slots
  for i := 0 to GameInformation.Slots.Count - 1 do
  begin
    Commander := TEntity.CreateFromScript('Commander\CommanderTemplate', GlobalEventbus);
    Commander.ID := EntityManager.GenerateUniqueID;

    InitializeCommander(Commander, GameInformation.Slots[i], GameInformation.League);

    // map slots to player
    for Token in GameInformation.Mapping.Keys do
    begin
      if not Mapping.ContainsKey(Token) then
      begin
        list := TList<integer>.Create();
        Mapping.Add(Token, list);
      end;
      if GameInformation.Mapping[Token].Contains(i) then
      begin
        Commander.Eventbus.Write(eiPlayerOwner, [GameInformation.Player[Token].Name]);
        Mapping[Token].Add(Commander.ID);
        FGameStatistics.AddCommander(Commander.ID, GameInformation.Player[Token].PlayerID);
      end;
    end;
    Commander.Deploy;

    FCommanders.Add(Commander);
  end;

  // add spectator commander
  Commander := TEntity.CreateFromScript('Commander\CommanderTemplate', GlobalEventbus);
  Commander.ID := EntityManager.GenerateUniqueID;
  SpectatorInformation := TCommanderInformation.CreateSpectator;
  InitializeCommander(Commander, SpectatorInformation, GameInformation.League);
  SpectatorInformation.Free;
  list := TList<integer>.Create();
  list.Add(Commander.ID);
  Mapping.Add('', list);
  Commander.Deploy;
  FCommanders.Add(Commander);

  TTokenMappingComponent.Create(GameEntity, Mapping);
  TSurrenderComponent.Create(GameEntity, GameInformation.Player.Count);
  FGameEntity.Eventbus.Trigger(eiAfterCreate, []);
end;

procedure TServerGame.Start;
begin
  GlobalEventbus.Trigger(eiGameCommencing, []);
end;

procedure TServerGame.TeamLost(const TeamID : integer);
begin
  // TODO: Add proper team handling, instead of hardcoded 2 teams
  if TeamID = 1 then FWinnerTeamID := 2
  else if TeamID = 2 then FWinnerTeamID := 1
  else if TeamID = PVE_TEAM_ID then FWinnerTeamID := 1
  else FWinnerTeamID := 0;
  FFinished := True;
end;

procedure TServerGame.TeamSurrendered(const TeamID : integer);
begin
  FSurrenderedTeamID := TeamID;
end;

{ TGameThread }

constructor TGameThread.Create(GameInformation : TServerGameInformation; GameManager : TGameManager);
begin
  // final init game player data (TeamID and isBot)
  GameInformation.UpdateGamePlayers;
  FTimeSinceCreate := TTimer.CreateAndStart(1000);
  FServerGame := TServerGame.Create(GameInformation);
  FNetworkComponent := TServerNetworkComponent.Create(FServerGame.GameEntity, GameInformation);
  {$IFDEF BENCHMARK}
  TBenchmarkServerComponent.Create(Game.GameEntity);
  {$ENDIF}
  FFPSLimiter := TFPSCounter.Create();
  FOverwatch := Overwatch;
  FGameID := GameInformation.GameID;
  FGameManager := GameManager;
  FGameTimeManager := TTimeManager.Create;
  FEntityDataCache := TEntityDataCache.Create;
  if MULTITHREADING_ENABLED then
  begin
    FreeOnTerminate := True;
    // for multithread, thread is ready to start - instant start
    inherited Create(False);
  end
  else
  begin
    // multithreading disabled -> create suspended thread (thread will never started),
    // instead GameManager will update thread while idle
    inherited Create(True);
    PrepareGame;
  end;
end;

destructor TGameThread.Destroy;
var
  Port : Word;
begin
  inherited;
  Port := FNetworkComponent.Port;
  FEntityDataCache.Free;
  // free servergame before remove it from GameManager to make used port available
  // else GameManager could use it for another game before port is unblocked
  FServerGame.Free;
  Synchronize(
    procedure()
    begin
      FGameManager.RemoveGame(self, Port);
    end);
  FFPSLimiter.Free;
  FGameTimeManager.Free;
  FHeartbeat.Free;
  FTimeSinceCreate.Free;
end;

procedure TGameThread.PrepareGame;
begin
  {$IFDEF DEBUG}
  NameThreadForDebugging('Game Thread ' + self.GameID);
  {$ENDIF}
  // set global game context for current game (only need to setup once for thread, becauce every thread has his own global context)
  Eventstack := FServerGame.FEventstack;
  Game := FServerGame;
  ServerGame := FServerGame;
  Overwatch := FOverwatch;
  Map := FServerGame.Map;
  GlobalEventbus := FServerGame.GlobalEventbus;
  GameTimeManager := FGameTimeManager;
  EntityDataCache := FEntityDataCache;
  TWelaEffectPayCostComponent.NOT_PAYED_RESOURCES := TWelaEffectPayCostComponent.DEFAULT_NOT_PAYED_RESOURCES;
  // after setup, game need some init code
  FServerGame.Initialize;

  if FServerGame.IsPerformanceTest then
  begin
    FConnectedPlayerCount := 2;
    FState := gsRunning;
    FNetworkComponent.AllowReconnect := True;
    FServerGame.Start;
  end;
end;

procedure TGameThread.DoComputeGame;
var
  tick : integer;
begin
  // pre setup
  GameTimeManager.TickTack;
  FFPSLimiter.FrameTick;
  FCurrentFrameRate := FFPSLimiter.GetFps;
  FTimeFromStart := TimeSinceCreate;
  if not FServerGame.IsPerformanceTest then
      FConnectedPlayerCount := FNetworkComponent.ConnectedPlayerCount;
  if not ServerGame.IsFinished then
  begin
    try
      // do the hot stuff, idle game
      FServerGame.Idle;
      // if FNetworkComponent.ShouldAbortGame then
      // FNetworkComponent.AbortGame;
      // debug ticking
      for tick := 0 to FTicksToGo - 1 do
          FServerGame.GlobalEventbus.Trigger(eiGameTick, []);
      FTicksToGo := 0;
      FActiveEntities := Game.EntityManager.DeployedEntityCount;
      FHeartbeat.DoBeat;

      if State = gsWaitingForPlayers then
      begin
        if FNetworkComponent.AllPlayersInStatePlaying then
        begin
          FState := gsRunning;
          FNetworkComponent.AllowReconnect := True;
          FServerGame.Start;
        end
        else if FNetworkComponent.AnyPlayerDisconnected then
        begin
          FState := gsAborted;
          ErrorMsg := 'A player lost connection during loading.'
        end
        else if (TimeSinceCreate >= TIMEOUT_TIME) and not FNetworkComponent.AllPlayersConnected then
        begin
          FState := gsAborted;
          ErrorMsg := 'Not all players connected within 30s.'
        end;
      end;

      if State = gsAborted then
      begin
        // inform all connected players that game is aborted
        FNetworkComponent.SendAbort;
        // ensure last SendAbort is sended
        sleep(1000);
        // and bye bye players
        FNetworkComponent.DisconnectAllPlayers;
        // waiting time give user oppurtunity to get info that game is aborted, but after some time is needed to be killed
        if TimeSinceCreate >= TIMEOUT_TIME then
        begin
          FGameFinishedState := gfAborted;
          Terminate;
        end;
      end;

      if State = gsRunning then
      begin
        // all disconnected -> kill game
        if not FServerGame.IsPerformanceTest and FNetworkComponent.AllPlayersDisconnected then
        begin
          FGameFinishedState := gfCrashed;
          Terminate;
          ErrorMsg := 'All players are disconnected.';
        end;
      end;
    except
      on e : Exception do
      begin
        FGameFinishedState := gfCrashed;
        ErrorMsg := CreateBugReport(etNormal);
        // if an error occurs, use madexcept to send a bugreport
        if not FGameManager.BreakOnException then
        begin
          AutoSaveBugReport(ErrorMsg, nil);
          AutoSendBugReport(ErrorMsg, nil);
        end;
        // also report bug to window
        Report('[EXCEPTION] "' + e.Message + '"!');
        Terminate;
        if FGameManager.BreakOnException then raise;
      end
      else
      begin
        Terminate;
        FGameFinishedState := gfCrashed;
        ErrorMsg := 'Unknown Error.'
      end;
    end
  end
  else
  begin
    self.Priority := TThreadPriority.tpLowest;
    Terminate;
    FGameFinishedState := gfFinished;
    FServerGame.GlobalEventbus.Trigger(eiServerShutdown, []);
  end;
end;

procedure TGameThread.Execute;
var
  ReportResult : string;
begin
  self.Priority := TThreadPriority.tpLowest;
  PrepareGame;
  FHeartbeat := HeartbeatManager.GetHeartbeat;
  ErrorMsg := '';
  self.Priority := TThreadPriority.tpNormal;
  while not Terminated do
  begin
    DoComputeGame;
  end;
  self.Priority := TThreadPriority.tpLowest;

  if not FGameManager.IsTestServer then
  begin
    // code is reached when game is finished or crashed
    ReportResult := ReportGameFinished(FGameFinishedState, HLog.ReadLog, ErrorMsg);
    if not ReportResult.IsEmpty then
        Report('[EXCEPTION] Send game finished data to server failed - Errorcode ' + ReportResult);
  end;
end;

procedure TGameThread.ForceShutdownGame;
begin
  ErrorMsg := 'Forced shutdown.';
  FGameFinishedState := gfAborted;
  Terminate;
end;

procedure TGameThread.Report(const Msg : string);
begin
  Synchronize(
    procedure()
    begin
      FGameManager.Report(Msg);
    end);
end;

function TGameThread.ReportGameFinished(State : EnumGameFinishedState; const LogFileContent, ErrorMsg : string) : string;
var
  statistic_data : RGameFinishedStatistics;
  statistic_data_json : string;
  EncodedLog : string;
  Promise : TPromise<boolean>;
begin
  EncodedLog := TJSONSerializer.SerializeValue(LogFileContent);
  if State = gfCrashed then
  begin
    Promise := GameManagerAPI.GameFinished(FServerGame.GameInformation.GameID, ord(State), ErrorMsg, EncodedLog);
  end
  else
  begin
    // fill RGameFinishedStatistics with data from different components
    // as game don't know players, and network component has no idea about entity/game data
    FNetworkComponent.BuildStatistics(statistic_data);
    FServerGame.BuildStatistics(statistic_data);
    statistic_data_json := TJSONSerializer.SerializeValue<RGameFinishedStatistics>(statistic_data);
    Promise := GameManagerAPI.GameFinished(FServerGame.GameInformation.GameID, ord(State), statistic_data_json, EncodedLog);
  end;
  Promise.WaitForData;
  if Promise.WasSuccessful then
      Result := ''
  else
      Result := Promise.ErrorMessage;
  Promise.Free;
end;

procedure TGameThread.SendGameTick;
begin
  AtomicIncrement(FTicksToGo, 1);
end;

function TGameThread.TimeSinceCreate : Int64;
begin
  Result := trunc(FTimeSinceCreate.ZeitDiffProzent * 1000);
end;

{ THeartbeat }

constructor THeartbeat.Create(HeartbeatManager : THeartbeatManager);
begin
  FHeartbeatManager := HeartbeatManager;
  FCurrentHeartbeat := HeartbeatManager.FHeartbeatThread.HeartbeatCounter;
end;

procedure THeartbeat.DoBeat;
begin
  AtomicIncrement(FCurrentHeartbeat);
  if FCurrentHeartbeat >= FHeartbeatManager.FHeartbeatThread.HeartbeatCounter then
  begin
    FHeartbeatManager.FHeartbeatThread.HeartbeatEvent.WaitFor(INFINITE);
    FHeartbeatManager.FHeartbeatThread.HeartbeatEvent.ResetEvent;
  end
  else
      FCurrentHeartbeat := Max(FCurrentHeartbeat, FHeartbeatManager.FHeartbeatThread.HeartbeatCounter - 1);
end;

{ THeartbeatManager.THeartbeatThread }

constructor THeartbeatManager.THeartbeatThread.Create;
var
  UID : TGuid;
begin
  CreateGuid(UID);
  FHeartbeatEvent := TEvent.Create(nil, True, False, GuidToString(UID));
  FTimer := CreateWaitableTimer(nil, True, nil);
  inherited Create(False);
end;

destructor THeartbeatManager.THeartbeatThread.Destroy;
begin
  FHeartbeatEvent.Free;
  inherited;
end;

procedure THeartbeatManager.THeartbeatThread.Execute;
var
  WaitTime : TLargeInteger;
begin
  WaitTime := -TARGET_FRAMETIME * 1000 * 10;
  self.Priority := TThreadPriority.tpTimeCritical;
  while not Terminated do
  begin
    AtomicIncrement(FHeartbeatCounter);
    SetWaitableTimer(FTimer, WaitTime, 0, nil, nil, False);
    WaitForSingleObject(FTimer, INFINITE);
    FHeartbeatEvent.SetEvent;
    FHeartbeatEvent.ResetEvent;
  end;
end;

{ THeartbeatManager }

constructor THeartbeatManager.Create;
begin
  FHeartbeatThread := THeartbeatThread.Create;
  timeBeginPeriod(1);
end;

destructor THeartbeatManager.Destroy;
begin
  FHeartbeatThread.Free;
  timeEndPeriod(1);
  inherited;
end;

function THeartbeatManager.GetHeartbeat : THeartbeat;
begin
  Result := THeartbeat.Create(self);
end;

initialization

HeartbeatManager := THeartbeatManager.Create;
ScriptManager.Defines.Add('SERVER');
ScriptManager.ExposeClass(TServerGame);

finalization

HeartbeatManager.Free;

end.
