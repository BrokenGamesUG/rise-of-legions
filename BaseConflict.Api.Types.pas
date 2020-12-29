unit BaseConflict.Api.Types;

interface

uses
  // System
  SysUtils,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.Threads,
  Engine.Network.RPC,
  Engine.Helferlein.DataStructures,
  Engine.Serializer.JSON,
  // Game
  BaseConflict.Constants.Cards;

type

  /// //////////////////////////////////////////////////////////////////////////////////
  /// General
  /// //////////////////////////////////////////////////////////////////////////////////

  EConnectorError = class(Exception);
  ETypeMissmatch = class(Exception);

  // max 999 errorcodes possible!!!
  EnumErrorCode = (
    /// undefined
    ecUndefined = 0,
    /// connection problems
    ecServerNoResponse = 1,
    ecRequestTimeOut = 2,
    ecRequestBlocked = 3,
    ecMaintenance = 5,
    ecSteamInternalError = 6,
    ecSteamAppWrongVersion = 9,
    /// permission/authentication problems
    ecNotAuthenticated = 10,
    ecBadParameter = 11,
    ecSteamOverlayDisabled = 13,
    /// context dependent problems
    ecUnknownUsername = 20,
    ecWrongPassword = 21,
    ecAlreadyLoggedIn = 22,
    ecNoFriend = 23,
    ecUnknownFriendRequest = 24,
    ecFriendRequestNotReceiver = 25,
    ecAlreadyFriends = 26,
    ecTeamNotInTheQueue = 27,
    ecUnknownMatchmakingTeam = 28,
    ecNonLeaderPerformLeaderOP = 29,
    ecAlreadyMMTeamMember = 30,
    ecPlayerNotSuggested = 31,
    ecPlayerIsNotMemberOfMMTeam = 32,
    ecUnkownGamemode = 33,
    ecGamemodeDisabled = 34,
    ecUnkownInvite = 35,
    ecNotInvitedPerson = 36,
    ecInviteRejected = 37,
    ecInvalidInvite = 38,
    ecTeamAlreadyInQueue = 39,
    ecUnknownDeck = 40,
    ecNotOwnDeck = 41,
    ecCardNotUnlocked = 42,
    ecCardMultipleInDeck = 43,
    ecUnknownOffer = 45,
    ecInsufficientBalance = 46,
    ecUnknownGame = 47,
    ecGameAlreadyFinished = 48,
    ecGameNotFinished = 49,
    ecPlayerNotPlayedGame = 50,
    ecCardAscensionFailed = 55,
    ecFriendInviteFailedUnknownFriendID = 62,
    ecDeckConstraintFailed = 63,
    ecGameCrashed = 65,
    ecQuestNotFound = 66,
    ecQuestNotFinished = 67,
    ecQuestRewardAlreadyCollected = 68,
    ecQuestRerollFailedNoRerollsAvailable = 69,
    ecMessageNotFound = 70,
    ecMessageAttachmentsAlreadyCollected = 71,
    ecDeckTierNotMatchingQueue = 72,
    ecBonusCodeNotFound = 73,
    ecBonusCodeAlreadyRedeemedBySomeone = 74,
    ecBonusCodeAlreadyRedeemedByAccount = 75,
    ecIconNotUnlocked = 76,
    ecDeckCreateFailedNoDeckSlots = 77,
    ecPurchaseFailedAlreadyBoughtMaximum = 78,
    ecSkinNotUnlocked = 79,
    ecReferAFriendBonusAlreadyRedeemed = 80,
    ecReferAFriendMinLevelNotReached = 81,
    ecReferAFriendCantReferSelf = 83,
    // client errors
    ecConnectionRefusedWrongTokenMapping = 400,
    ecConnectionLostToGameServerDuringLoading = 401,
    ecConnectionToGameServerNotPossible = 402,
    ecConnectionLostToGameServerDuringGame = 403,
    ecGameAbortedAnotherPlayerLostConnection = 404,
    ecConnectionToGameServerNotPossiblePorts = 405,
    ecMatchmakingTeamReset = 406,
    ecMatchmakingTeamCorrupt = 407,
    ecConnectionRefusedTooMuchSpectators = 408,
    ecConnectionRefusedTokenAlreadyInUse = 409,
    // undefined server errors
    ecInternalServerError = 500
    );

  RErrorCodeTranslate = record
    ErrorCode : EnumErrorCode;
    Description : string;
  end;

const
  ERROR_TRANSLATION_PREFIX = '§Errorcode_';

type

  ProcOnConnectorError = reference to procedure(ErrorCode : EnumErrorCode);

  TPromiseHelper = class helper for TPromise
    public
      function ErrorAsErrorCode : EnumErrorCode;
  end;

  /// <summary> Normal action behaviour + handling for errors within promises.</summary>
  TPromiseAction = class abstract(TAction)
    protected
      procedure HandlePromiseError(const Promise : TPromise);
      procedure HandleMultiplePromisesErrors(Promises : array of TPromise);
      /// <summary> Handle the result of a promise, this includes waitfordata
      /// and set error if any occurs. This method will also free the promise after handling.</summary>
      function HandlePromise(const Promise : TPromise<boolean>) : boolean;
  end;

  /// <summary> Wrapper for simple data fetching via the action queue. </summary>
  TPromiseLoadAction<T> = class abstract(TPromiseAction)
    protected
      function GetData : TPromise<T>; virtual; abstract;
      /// <summary> Will be called synchronous. </summary>
      procedure ProcessData(const Data : T); virtual; abstract;
    public
      function Execute : boolean; override;
  end;

  /// ////////////////////////////////////////////////////////////////////////////
  /// /////////////// Code Convention ////////////////////////////////////////////
  /// Some words about code convention in the is file:
  /// Normally all Delphi code follow our defined code conventions, like camel-
  /// case etc. In this special file the python code conventions will be used,
  /// because many parameter or struct names a directly used in code and
  /// e.g. camel case is not used in python. This is only used for fieldnames,
  /// not types.
  /// ////////////////////////////////////////////////////////////////////////////

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Account (Login)
  /// //////////////////////////////////////////////////////////////////////////////////

  EAccountError = class(Exception);

  EnumAccountStatus = (asDisconnected, asConnecting, asConnected);

  RLoginReturn = record
    own_id : integer;
    own_name : string;
    session_key : string;
    broker_address : string;
    servertime : TDatetime;
  end;

  RBrokerData = record
    id : integer;
    url : string;
    Data : string;
  end;

  ARBrokerData = TArray<RBrokerData>;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Social (Friendlist, Chat)
  /// //////////////////////////////////////////////////////////////////////////////////

  EChatError = class(Exception);
  EnumChatAPIStatus = (csOffline, csOnline, csAway, csBusy, csInGame);

const

  CHAT_STATUS_I18N_PREFIX = 'Chat_Status_';
  CHAT_STATUS_OFFLINE     = [csOffline];
  CHAT_STATUS_ONLINE      = [csOnline, csAway, csBusy];

type
  /// //////////////////////////////////////////////////////////////////////////////////
  /// Shared
  /// //////////////////////////////////////////////////////////////////////////////////

  /// <summary> Common record of multiple card upgrade, gold value, etc. tables.</summary>
  RApiTableEntry = record
    key : integer;
    value : integer;
  end;

  AApiTable = TArray<RApiTableEntry>;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Serverstate
  /// //////////////////////////////////////////////////////////////////////////////////

  RServerState = record
    server_offline : boolean;
    max_current_player_online : integer;
    server_time : TDatetime;
    // -----------
    client_dashboard_headline : string;
    client_dashboard_text : string;
    client_dashboard_tournament_datetime : TDatetime;
    // -----------
    client_server_issues_enabled : boolean;
    client_server_issues_wobbel : boolean;
    client_server_issues_text : string;
    // -----------
    maintenance_mode_enabled : boolean;
    maintenance_datetime : TDatetime;
    maintenance_blockingtime_before : integer;
    maintenance_duration : integer;
    // ------------
    login_queue_address : string;
  end;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// cards & Deckbuilding
  /// //////////////////////////////////////////////////////////////////////////////////

  RColorCurrencyEntry = record
    card_color : EnumEntityColor;
    currency_UID : string;
  end;

  ARColorCurrencyEntry = TArray<RColorCurrencyEntry>;

  RCardConstants = record
    // currencies
    gold_currency_uid : string;
    premium_currency_uid : string;
    // same for upgrade cost and sacrifice value
    card_gold_legendary_multiplier : single;
    // card values
    card_gold_value_table : AApiTable;
    // Upgrade costs
    card_upgrade_gold_cost : AApiTable;
    // other constants
    card_max_tier : integer;
    card_level_per_tier : integer;
    card_level_table : AApiTable;
    card_experience_value_table : AApiTable;
  end;

  [RpcMixedBaseClass]
  TApiCardRequirement = class
    id : integer;
    card_uid : string;
  end;

  [RpcMixedClassDescendant('CARDREQUIREMENT_PLAYERLEVEL')]
  TApiCardRequirementPlayerLevel = class(TApiCardRequirement)
    minimum_player_level : integer;
  end;

  [RpcMixedClassDescendant('CARDREQUIREMENT_CARDUNLOCKED')]
  TApiCardRequirementCardUnlocked = class(TApiCardRequirement)
    require_card_unlocked_uid : string;
  end;

  [RpcMixedClassDescendant('CARDREQUIREMENT_GAMEEVENT')]
  TApiCardRequirementGameEvent = class(TApiCardRequirement)
    game_event_identifier : string;
    use_times : integer;
    single_game : boolean;
  end;

  AApiCardRequirement = TArray<TApiCardRequirement>;

  RCardRequirementProgress = record
    card_uid : string;
    requirement_id : integer;
    progress : integer;
  end;

  ARCardRequirementProgress = TArray<RCardRequirementProgress>;

  /// <summary> A unique card that is available in game.</summary>
  RCardSkin = record
    id : integer;
    uid : string;
    name : string;
  end;

  ACardRSkin = TArray<RCardSkin>;

  RCard = record
    uid : string;
    name : string;
    colors : SetEntityColor;
    starting_tier : integer;
    skins : ACardRSkin;
  end;

  ARCard = TArray<RCard>;

  RCardUnlock = record
    card_uid : string;
  end;

  ARCardUnlock = TArray<RCardUnlock>;

  RSkinUnlock = record
    skin_id : integer;
    card_uid : string;
  end;

  ARSkinUnlock = TArray<RSkinUnlock>;

  RUnlockData = record
    card_unlocks : ARCardUnlock;
    skin_unlocks : ARSkinUnlock;
  end;

  RCardInstance = record
    id : integer;
    origin_card_uid : string;
    tier : integer;
    experience_points : integer;
    ascension_progress : integer;
    created : TDatetime;
  end;

  ARCardInstance = TArray<RCardInstance>;

  RDeckCard = record
    card_id : integer;
    skin_id : integer;
  end;

  ARDeckCard = TArray<RDeckCard>;

  RDeck = record
    id : integer;
    name : string;
    icon_identifier : string;
    /// <summary> Only ids of cardinstances.</summary>
    Cards : ARDeckCard;
  end;

  ARDeck = TArray<RDeck>;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Shop & Loot
  /// //////////////////////////////////////////////////////////////////////////////////

  RLootboxContent = record
    shopitem_id : integer;
    shopitem_count : integer;
  end;

  ARLootboxContent = TArray<RLootboxContent>;

  RLootlist = record
    loot : ARLootboxContent;
  end;

  RLootbox = record
    id : integer;
    opened : boolean;
    content : ARLootboxContent;
    type_identifier : string;
  end;

  ARLootbox = TArray<RLootbox>;

  RDraftBoxChoice = record
    choice_id : integer;
    shopitem_id : integer;
    shopitem_count : integer;
  end;

  ARDraftBoxChoice = TArray<RDraftBoxChoice>;

  RDraftBox = record
    id : integer;
    opened : boolean;
    league : integer;
    type_identifier : string;
    choices : ARDraftBoxChoice;
  end;

  ARDraftBox = TArray<RDraftBox>;

  RCurrency = record
    uid : string;
    name : string;
  end;

  ARCurrency = TArray<RCurrency>;

  RBalance = record
    currency_UID : string;
    balance : integer;
  end;

  ARBalance = TArray<RBalance>;

  RBalanceData = record
    player_currency : string;
    balances : ARBalance;
  end;

  RCostRaw = record
    currency_UID : string;
    amount : integer;
  end;

  ARCostRaw = TArray<RCostRaw>;

  ROffer = record
    id : integer;
    costs : ARCostRaw;
    available_until : TDatetime;
    active : boolean;
    real_money : boolean;
  end;

  AROffer = TArray<ROffer>;

  [RpcMixedBaseClass]
  TApiShopItem = class
    id : integer;
    name : string;
    purchases_limited_to : integer;
    time_to_buy : integer;
    offers : AROffer;
  end;

  ATApiShopItem = TArray<TApiShopItem>;

  [RpcMixedClassDescendant('SHOPITEM_BUYCARD')]
  TApiShopItemBuyCard = class(TApiShopItem)
    card_uid : string;
    card_tier : integer;
  end;

  [RpcMixedClassDescendant('SHOPITEM_UNLOCKSKIN')]
  TApiShopItemUnlockSkin = class(TApiShopItem)
    card_uid : string;
    skin_uid : string;
  end;

  [RpcMixedClassDescendant('SHOPITEM_RANDOMCARD')]
  TApiShopItemRandomCard = class(TApiShopItem)
    card_tier : integer;
  end;

  [RpcMixedClassDescendant('SHOPITEM_BUYCURRENCY')]
  TApiShopItemBuyCurrency = class(TApiShopItem)
    currency_UID : string;
    amount : integer;
  end;

  [RpcMixedClassDescendant('SHOPITEM_GAINPLAYEREXPERIENCE')]
  TApiShopItemGainPlayerExperience = class(TApiShopItem)
    amount : integer;
  end;

  [RpcMixedClassDescendant('SHOPITEM_LOOTBOX')]
  TApiShopItemLootbox = class(TApiShopItem)
    // only loot table and this will not shown here.
  end;

  [RpcMixedClassDescendant('SHOPITEM_DRAFTBOX')]
  TApiShopItemDraftbox = class(TApiShopItem)
    league : integer;
    type_identifier : string;
  end;

  [RpcMixedClassDescendant('SHOPITEM_UNLOCK_ICON')]
  TApiShopItemUnlockIcon = class(TApiShopItem)
    icon_identifier : string;
  end;

  [RpcMixedClassDescendant('SHOPITEM_PREMIUM_ACCOUNT')]
  TApiShopItemPremiumAccount = class(TApiShopItem)
    days : integer;
  end;

  [RpcMixedClassDescendant('SHOPITEM_DECK_SLOT')]
  TApiShopItemDeckSlot = class(TApiShopItem)
  end;

  [RpcMixedClassDescendant('SHOPITEM_LOOTLIST')]
  TApiShopItemLootList = class(TApiShopItem)
    loot : RLootlist;
  end;

  RShopPurchase = record
    shopitem_id : integer;
    count : integer;
  end;

  ARShopPurchase = TArray<RShopPurchase>;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Quests
  /// //////////////////////////////////////////////////////////////////////////////////

  EnumQuestType = (qtTutorial, qtDaily, qtWeekly, qtEvent);

  RQuest = record
    identifier : string;
    quest_type : EnumQuestType;
    invisible : boolean;
    reward : RLootlist;
    rerollable : boolean;
    target_count : integer;
    custom_task_data : TJSONObject;
  end;

  RQuestProgress = record
    id : integer;
    quest : RQuest;
    completed : boolean;
    reward_collected : boolean;
    counter : integer;
  end;

  ARQuestProgress = TArray<RQuestProgress>;

  RQuestData = record
    quests : ARQuestProgress;
    rerolls : integer;
    max_rerolls : integer;
  end;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Account & Profile
  /// //////////////////////////////////////////////////////////////////////////////////

  RLevelUpReward = record
    reaching_level : integer;
    reward : RLootlist;
    additional_text : string;
  end;

  ARLevelUpReward = TArray<RLevelUpReward>;

  RTutorialVideo = record
    id : integer;
    identifier : string;
    title : string;
    url : string;
    order_value : integer;
  end;

  ARTutorialVideo = TArray<RTutorialVideo>;

  RProfileConstants = record
    player_max_level : integer;
    player_level_table : AApiTable;
    player_level_reward : ARLevelUpReward;
  end;

  RProfileData = record
    experience_points : integer;
    level : integer;
    league : integer;
    starterdeck_chosen : boolean;
    account_created : TDatetime;
    next_first_win_available : TDatetime;
    premium_active_until : TDatetime;
    deck_slots : integer;
    icon : string;
    is_staff : boolean;
    custom_data : TJSONData;
  end;

  RPatchNotes = record
    timestamp : TDatetime;
  end;

  RCrystalEventTime = record
    time_to_event : integer;
  end;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Matchmaking & Team
  /// //////////////////////////////////////////////////////////////////////////////////

  DMatchmakingTeamUID = string;

  RMatchmakingUser = record
    id : integer;
    username : string;
    current_deck : string;
    deck_icon : string;
    deck_tier : integer;
  end;

  ARMatchmakingUser = TArray<RMatchmakingUser>;

  EnumMatchmakingTeamInviteStatus = (
    tiOpen,               // Initial state of a invitation to join a matchmakingteam, this state last until player accept or decline a invite.
    tiAccepted,           // Invite goes into this state after a player has accepted a invitation.
    tiDeclined,           // A player declined a invitation, this can be made manually by player or automatically by system if target player is alerady ingame.
    tiTeamIsFull,         // The matchmakingteam is full
    tiGameNoLongerExists, // If an invite goes to that state, the game to which the invitation invites, no longer exists. After a invite
    // has this state, accept or decline will cause an error, so only option is to ignore it
    tiLeftTheGame// player has joined but then left the game
    );

  RMatchmakingTeamInvite = record
    id : integer;
    team_uid : string;
    status : EnumMatchmakingTeamInviteStatus;
    /// <summary> Target player of the invite.</summary>
    player : RMatchmakingUser;
    /// <summary> Player that has sent the invite.</summary>
    sourceplayer : RMatchmakingUser;
  end;

  RMatchmakingTeam = record
    members : TArray<RMatchmakingUser>;
    leader_id : integer;
    team_uuid : DMatchmakingTeamUID;
    invites : TArray<RMatchmakingTeamInvite>;
    scenario_identifier : string;
    scenario_instance_id : integer;
    scenario_team : integer;
  end;

  RMatchmakingQueueData = record
    players_in_queue : integer;
    server_available : boolean;
  end;

  RGameFoundPlayer = record
    username : string;
    user_id : integer;
    team_id : integer;
    deckname : string;
    deck_icon : string;
    // array of card_uid strings
    Cards : TArray<string>;
  end;

  ARGameFoundPlayer = TArray<RGameFoundPlayer>;

  RGameFoundData = record
    game_uid : string;
    secret_key : string;
    gameserver_ip : string;
    gameserver_port : Word;
    scenario_instance_id : integer;
    scenario_uid : string;
    scenario_instance_league : integer;
    players : ARGameFoundPlayer;
  end;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Scenarios & Game
  /// //////////////////////////////////////////////////////////////////////////////////

  RScenarioSlot = record
    team_id : integer;
  end;

  ARScenarioSlot = TArray<RScenarioSlot>;

  RScenarioMutator = record
    identifier : string;
  end;

  ARScenarioMutator = TArray<RScenarioMutator>;

  [RpcMixedBaseClass]
  TApiScenarioDeckConstraint = class
    id : integer;
    scenario_instance_id : integer;
  end;

  ATApiScenarioDeckConstraint = TArray<TApiScenarioDeckConstraint>;

  [RpcMixedClassDescendant('DECKCONSTRAINT_LIMITTIER')]
  TApiScenarioDeckConstraintLimitTier = class(TApiScenarioDeckConstraint)
    tier : integer;
  end;

  [RpcMixedClassDescendant('DECKCONSTRAINT_LIMITMAXTIER')]
  TApiScenarioDeckConstraintLimitMaxTier = class(TApiScenarioDeckConstraint)
    max_tier : integer;
  end;

  [RpcMixedClassDescendant('DECKCONSTRAINT_CARDCOLOR')]
  TApiScenarioDeckConstraintLimitCardColor = class(TApiScenarioDeckConstraint)
    card_colors : SetEntityColor;
  end;

  RScenarioInstance = record
    id : integer;
    tier : integer;
    mutators : ARScenarioMutator;
  end;

  ARScenarioInstance = TArray<RScenarioInstance>;

  RScenario = record
    identifier : string;
    enabled : boolean;
    slots : ARScenarioSlot;
    levels_of_difficulty : ARScenarioInstance;
    ranked : boolean;
    minimum_playerlevel : integer;
    deck_required : boolean;
    staff_only : boolean;
  end;

  ARScenario = TArray<RScenario>;

  RBrokerScenarioInstance = record
    scenario__identifier : string;
    tier : integer;
  end;

  ARBrokerScenarioInstance = TArray<RBrokerScenarioInstance>;

  RMatchmakingRanking = record
    id : integer;
    scenario_instance_id : integer;
    rank : integer;
    stars : integer;
    stars_to_climb : integer;
    won : integer;
    lost : integer;
    best_time : integer;
  end;

  ARMatchmakingRanking = TArray<RMatchmakingRanking>;

  RLeaderboardRow = record
    icon_identifier : string;
    user_id : integer;
    position : integer;
    nickname : string;
    points : integer;
  end;

  RLeaderboardRows = TArray<RLeaderboardRow>;

  RLeaderboard = record
    top_placements, player_placements : RLeaderboardRows;
  end;

  RLeaderboardForLeague = record
    leaderboard : RLeaderboard;
    scenario_instance_id : integer;
  end;

  RLeaderboardData = TArray<RLeaderboardForLeague>;

  RGameCard = record
    base_card_uid : string;
    slot_index : integer;
    /// <summary> Value between 1..5, known as league.</summary>
    tier : integer;
    /// <summary> Value between 0..1, determine the power of a card. 1 - card has max power_level for current tier.</summary>
    power_level : single;
    /// <summary> Level of card as 0 based value (0..4) </summary>
    level : integer;
  end;

  ARGameCard = TArray<RGameCard>;

  RGameCreatePlayer = record
    user_id : integer;
    is_bot : boolean;
    bot_difficulty : integer;
    username : string;
    secret_key : string;
    team_id : integer;
    deckname : string;
    Cards : ARGameCard;
  end;

  ARGameCreatePlayer = TArray<RGameCreatePlayer>;

  RServerScenarioInstance = record
    id : integer;
    scenario_identifier : string;
    tier : integer;
    mutators : ARScenarioMutator;
  end;

  RGameCreateData = record
    uid : string;
    scenario_instance : RServerScenarioInstance;
    slots : ARGameCreatePlayer;
  end;

  RGameReponseData = record
    uid : string;
    port : integer;
  end;

  RGameCardReward = record
    card_instance_id : integer;
    card_skin_id : integer;
    daily_reward_used : boolean;
    experience_points_before_game : integer;
    experience_points_gained : integer;
    experience_premium : integer;
    has_premium : boolean;
  end;

  ARGameCardReward = TArray<RGameCardReward>;

  RGameFinishedRewards = record
    has_premium : boolean;
    experience_before : integer;
    level_before : integer;
    experience : integer;
    experience_premium : integer;
    currency : integer;
    currency_premium : integer;
    loot : RLootbox;
    draftbox : RDraftBox;
    Cards : ARGameCardReward;
  end;

  RGameStatisticsGameEvent = record
    identifier : string;
    count : integer;
  end;

  AGameStatisticsGameEvent = TArray<RGameStatisticsGameEvent>;

  RGameCommanderStatistics = record
    player_id : integer;
    game_events : AGameStatisticsGameEvent;
  end;

  AGameCommanderStatistics = TArray<RGameCommanderStatistics>;

  RGamePlayerStatistics = record
    player_id : integer;
    player_state : integer;
  end;

  AGamePlayerStatistics = TArray<RGamePlayerStatistics>;

  RGameFinishedStatistics = record
    duration : integer;
    winner_team_id : integer;
    player_statistics : AGamePlayerStatistics;
    commander_statistics : AGameCommanderStatistics;
  end;

  RClientGameStatisticPlayer = record
    username : string;
    user_id : integer;
    steam_id : UInt64;
    friend_id : integer;
    playericon : string;
    team_id : integer;
    deckname : string;
    deck_icon : string;
    ranking : integer;
    Cards : ARGameCard;
  end;

  ARClientGameStatisticPlayer = TArray<RClientGameStatisticPlayer>;

  RClientGameFinishedStatistics = record
    duration : integer;
    players : ARClientGameStatisticPlayer;
  end;

  RGameFinishedData = record
    scenario_instance_id : integer;
    crashed : boolean;
    statistic_data : RClientGameFinishedStatistics;
    has_won : boolean;
    first_win_used : boolean;
    next_first_win : TDatetime;
    new_ranking : RMatchmakingRanking;
    rewards : RGameFinishedRewards;
  end;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Chat
  /// //////////////////////////////////////////////////////////////////////////////////

  RChatAPIFriend = record
    id : integer;
    name : string;
    icon : string;
    steam_id : UInt64;
    status : EnumChatAPIStatus;
    current_game : RGameFoundData;
  end;

  ARChatAPIFriend = TArray<RChatAPIFriend>;

  RChatApiRequest = record
    id : integer;
    to_id : integer;
    to_name : string;
    requester_id : integer;
    requester_name : string;
  end;

  ARChatApiRequest = TArray<RChatApiRequest>;

  RFriendlist = record
    friend_id : integer;
    friends : ARChatAPIFriend;
    requests : ARChatApiRequest;
  end;

  RSteamFriend = record
    steam_id : UInt64;
    friend_uid : integer;
  end;

  ARSteamFriend = TArray<RSteamFriend>;

  RChatMessage = record
    sender_id : integer;
    sender_name : string;
    timestamp : TDatetime;
    text_message : string;
    receiver_id : integer;
    chatroom_id : integer;
  end;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Datatracker
  /// //////////////////////////////////////////////////////////////////////////////////

  RBalanceTrackerData = record
    currency_UID : string;
    currency_spent : integer;
    currency_gained : integer;
  end;

  ARBalanceTrackerData = TArray<RBalanceTrackerData>;

  RDataTrackerData = record
    cards_buyed : integer;
    cards_upgraded : integer;
    card_highest_tier : integer;
    total_cardexp_gained : integer;
    total_playerexp_gained : integer;
    unlocked_cards : integer;
    balance_tracker_data : ARBalanceTrackerData;
  end;

  /// //////////////////////////////////////////////////////////////////////////////////
  /// Messages
  /// //////////////////////////////////////////////////////////////////////////////////

  RMessageAttachement = record
    shopitem_id : integer;
    amount : integer;
  end;

  ARMessageAttachement = TArray<RMessageAttachement>;

  RMessage = record
    id : integer;
    subject : string;
    text : string;
    attachments : ARMessageAttachement;
  end;

  ARMessage = TArray<RMessage>;

function ErrorCodeToString(ErrorCode : EnumErrorCode) : string;

implementation

function ErrorCodeToString(ErrorCode : EnumErrorCode) : string;
begin
  result := _(ERROR_TRANSLATION_PREFIX + HString.IntToStr(ord(ErrorCode), 3));
end;

{ TPromiseHelper }

function TPromiseHelper.ErrorAsErrorCode : EnumErrorCode;
var
  ErrorValue : integer;
begin
  if SameText(self.ErrorMessage, 'TIMEOUT') then
      result := ecServerNoResponse
  else if TryStrToInt(self.ErrorMessage, ErrorValue) then
  begin
    result := EnumErrorCode(ErrorValue);
  end
  else result := ecUndefined;
end;

{ TPromiseAction }

procedure TPromiseAction.HandleMultiplePromisesErrors(Promises : array of TPromise);
begin
  raise ENotImplemented.Create('TPromiseAction.HandleMultiplePromisesErrors');
end;

function TPromiseAction.HandlePromise(const Promise : TPromise<boolean>) : boolean;
begin
  Promise.WaitForData;
  if not Promise.WasSuccessful then
      HandlePromiseError(Promise);
  result := Promise.WasSuccessful;
  Promise.Free;
end;

procedure TPromiseAction.HandlePromiseError(const Promise : TPromise);
begin
  assert(not Promise.WasSuccessful);
  FErrorMsg := Promise.ErrorMessage;
end;

{ TPromiseLoadAction<T> }

function TPromiseLoadAction<T>.Execute : boolean;
var
  Data : TPromise<T>;
begin
  Data := GetData;
  Data.WaitForData;
  if Data.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        self.ProcessData(Data.value)
      end);
  end
  else HandlePromiseError(Data);
  result := Data.WasSuccessful;
  Data.Free;
end;

end.
