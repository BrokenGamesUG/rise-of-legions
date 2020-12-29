unit Baseconflict.Api;

interface


uses
  // System
  System.Generics.Collections,
  SysUtils,
  // Engine
  Engine.Network.RPC,
  Engine.Helferlein,
  Engine.Helferlein.Datastructures,
  Engine.Serializer.JSON,
  // Game
  Baseconflict.Api.Types;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$M+}
  TFriendlistAPI = class(TRpcApi)
    published
      [RpcUrl('/api/friendlist/get_own_status/', hmGET)]
      function GetOwnStatus() : TPromise<EnumChatAPIStatus>; virtual; abstract;
      [RpcUrl('/api/friendlist/set_own_status/')]
      function SetOwnStatus(New_Own_Status : EnumChatAPIStatus) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/friendlist/get_friendlist/', hmGET)]
      function GetFriendlist() : TPromise<RFriendlist>; virtual; abstract;
      [RpcUrl('/api/friendlist/filter_steam_friends/', hmPOST)]
      function FilterSteamFriends(steam_friends : TArray<UInt64>) : TPromise<ARSteamFriend>; virtual; abstract;
      [RpcUrl('/api/friendlist/remove_friend/')]
      function RemoveFriend(Friend_ID : integer) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/friendlist/add_friend/')]
      function SendFriendRequest(friend_uid : integer) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/friendlist/answer_friend_request/')]
      function AnswerFriendRequest(Request_ID : integer; Accept : Boolean) : TPromise<Boolean>; virtual; abstract;
  end;

  IFriendlistBackchannel = interface
    ['{4F9CD569-5032-4710-8856-6FE65EF8D687}']
    [RpcHandler('/friendlist/status_changed/')]
    procedure FriendStatusChanged(Friend : RChatAPIFriend);
    [RpcHandler('/friendlist/friend_added/')]
    procedure FriendAdded(Friend : RChatAPIFriend);
    [RpcHandler('/friendlist/friend_removed/')]
    procedure FriendRemoved(Friend : RChatAPIFriend);
  end;

  IFriendRequestBackchannel = interface
    ['{E52E0AE4-7B9E-4493-B50D-364092CF6B5C}']
    [RpcHandler('/friendlist/request_answered/')]
    procedure FriendRequestAnswered(Accepted : Boolean; Request_ID : integer);
    [RpcHandler('/friendlist/request_deleted/')]
    procedure FriendRequestDeleted(Request_ID : integer);
    [RpcHandler('/friendlist/request_new/')]
    procedure FriendRequestReceived(Request : RChatApiRequest);
  end;

  TChatAPI = class(TRpcApi)
    published
      [RpcUrl('/api/chat/send_private_message/')]
      function SendPrivateMessage(Friend_ID : integer; Msg : string) : TPromise<Boolean>; virtual; abstract;
  end;

  IChatBackchannel = interface
    ['{88278D70-1D85-4AA7-A29C-27B1A1AE4491}']
    [RpcHandler('/chat/new_message/')]
    procedure NewChatMessage(Msg : RChatMessage);
  end;

  IProfileBackchannel = interface
    ['{D340AD2B-7D8A-4AEC-AAFB-F0430F93ECD7}']
    [RpcHandler('/profile/level_up/')]
    procedure ReceivedLevelUpReward(reward : RLootbox; for_Reaching_Level : integer; additional_text : string);
    [RpcHandler('/profile/player_league_changed/')]
    procedure PlayerLeagueChanged(new_league : integer);
    [RpcHandler('/profile/icon_unlocked/')]
    procedure IconUnlocked(icon_identifier : string);
    [RpcHandler('/profile/premium_account_changed/')]
    procedure PremiumAccountChanged(active_until : TDatetime);
    [RpcHandler('/profile/deck_slots_increased/')]
    procedure DeckSlotsIncreased(deck_slots : integer);
  end;

  TAccountAPI = class(TRpcApi)
    published
      [RpcUrl('/api/account/login/')]
      function Login(username, password : string) : TPromise<RLoginReturn>; virtual; abstract;
      [RpcUrl('/api/account/login_steam/', hmPOST, [roEncodeParameterAsJson])]
      function LoginWithSteam(auth_ticket : string) : TPromise<RLoginReturn>; virtual; abstract;
      [RpcUrl('/api/account/check_version/', hmGET)]
      function CheckGameVersion(build_id : integer; branch_name : string) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/logout/')]
      function Logout() : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/get_profile/', hmGET)]
      function GetProfileData() : TPromise<RProfileData>; virtual; abstract;
      [RpcUrl('/api/account/get_profile_constants/', hmGET)]
      function GetProfileConstants() : TPromise<RProfileConstants>; virtual; abstract;
      [RpcUrl('/api/tutorial/get_videos/', hmGET)]
      function GetTutorialVideos() : TPromise<ARTutorialVideo>; virtual; abstract;
      [RpcUrl('/api/account/store_custom_data/', hmPOST)]
      function StoreCustomData(custom_data : TJSONData) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/change_icon/', hmPOST)]
      function ChangeIcon(icon : string) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/send_feedback/', hmPOST, [roEncapsuleParameterIntoJSONObject])]
      function SendFeedback(feedback : string) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/latest_patch_note/', hmGET)]
      function GetLatestPatchNotes() : TPromise<RPatchNotes>; virtual; abstract;
      [RpcUrl('/crystal_event_time/', hmGET)]
      function GetCrystalEventTime() : TPromise<RCrystalEventTime>; virtual; abstract;
      [RpcUrl('/api/account/send_custom_bugreport/', hmPOST, [roEncapsuleParameterIntoJSONObject])]
      function SendCustomBugReport(bugreport : string; error_log : string) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/get_unlocked_icons/', hmGET)]
      function GetUnlockedIconIdentifiers() : TPromise<TArray<string>>; virtual; abstract;
      [RpcUrl('/api/account/get_server_is_online/', hmGET)]
      function GetServerIsOnline() : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/get_server_state/', hmGET)]
      function GetServerState() : TPromise<RServerState>; virtual; abstract;
      [RpcUrl('/api/account/get_current_player_online/', hmGET)]
      function GetCurrentPlayerOnline() : TPromise<integer>; virtual; abstract;
      [RpcUrl('/api/account/send_ping_log/', hmPOST)]
      function SendPingLog(ping_log_data : TArray < TArray < int64 >> ) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/send_fps_log/', hmPOST)]
      function SendFPSLog(fps_log_data : TArray < TArray < int64 >> ) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/send_api_log/', hmPOST)]
      function SendApiLog(api_log_data : TArray<RCallLogItem>) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/broker/activate_fallback/', hmPOST)]
      function ActivateFallback() : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/broker/poll_broker_data/', hmGET)]
      function PollBrokerData() : TPromise<ARBrokerData>; virtual; abstract;
      [RpcUrl('/api/broker/deactivate_fallback/', hmPOST)]
      function DeactivateFallback() : TPromise<Boolean>; virtual; abstract;
  end;

  IAccountBackchannel = interface
    ['{CC76E119-A905-4DD1-B422-1C3A3CC3685B}']
  end;

  IServerStateBackchannel = interface
    ['{E611BCDD-412B-4890-9BD9-02C764B5982F}']
    [RpcHandler('/server/server_state_changed/')]
    procedure ServerStateChanged(Data : RServerState);
  end;

  TMatchmakingAPI = class(TRpcApi)
    published
      [RpcUrl('/api/matchmaking/get_leaderboard/', hmGET)]
      function GetLeaderboards() : TPromise<RLeaderboardData>; virtual; abstract;
      [RpcUrl('/api/matchmaking/get_rankings/', hmGET)]
      function GetRankings() : TPromise<ARMatchmakingRanking>; virtual; abstract;
      /// <summary> Create a new matchmaking team and returns the uuid of that team, if creation was successful</summary>
      [RpcUrl('/api/matchmaking/get_current_team/', hmGET)]
      function GetCurrentTeam() : TPromise<RMatchmakingTeam>; virtual; abstract;
      [RpcUrl('/api/matchmaking/accept_invite/')]
      function AcceptInvite(invite_id : integer) : TPromise<RMatchmakingTeam>; virtual; abstract;
      [RpcUrl('/api/matchmaking/decline_invite/')]
      function DeclineInvite(invite_id : integer) : TPromise<Boolean>; virtual; abstract;
      /// <summary> Leave the MMTeam with the given uuid.</summary>
      [RpcUrl('/api/matchmaking/leave_team/')]
      function LeaveTeam(team_uuid : DMatchmakingTeamUID) : TPromise<Boolean>; virtual; abstract;
      /// <summary> Will sends the friend a invitation to team, works only if current player is leader of the team and
      /// if target players does not already belongs to any team.</summary>
      [RpcUrl('/api/matchmaking/invite_friend_to_team/')]
      function InviteFriendToTeam(Friend_ID : integer; team_uuid : DMatchmakingTeamUID) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/matchmaking/promote_member_to_leader/')]
      function PromoteMemberToLeader(member_id : integer; team_uuid : DMatchmakingTeamUID) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/matchmaking/kick_member_from_team/')]
      function KickPlayerFromTeam(member_id : integer; team_uuid : DMatchmakingTeamUID) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/matchmaking/enter_matchmaking_queue/')]
      function EnterQueue(team_uuid : DMatchmakingTeamUID) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/matchmaking/leave_matchmaking_queue/')]
      function LeaveQueue(team_uuid : DMatchmakingTeamUID) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/matchmaking/set_current_deck/')]
      function SetCurrentDeck(deck_id : integer) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/matchmaking/set_scenario/')]
      function SetScenario(team_uuid : DMatchmakingTeamUID; scenario_instance_id : integer) : TPromise<Boolean>; virtual; abstract;
  end;

  IMatchmakingInviteBackchannel = interface
    ['{C44D2383-1AE2-4E9B-8C5F-89426B8B1938}']
    [RpcHandler('/matchmaking/new_invite/')]
    procedure NewTeamInvite(invite_data : RMatchmakingTeamInvite);
    [RpcHandler('/matchmaking/invite_status_changed/')]
    procedure InviteStatusChanged(invitation_id : integer; new_status : EnumMatchmakingTeamInviteStatus);
  end;

  IMatchmakingManagerBackchannel = interface
    ['{16C66046-DF0E-40DE-A633-0F8648DBE987}']
    [RpcHandler('/matchmaking/kicked_from_team/')]
    procedure KickFromTeam(new_team_data : RMatchmakingTeam);
    [RpcHandler('/matchmaking/game_found/')]
    procedure GameFound(Data : RGameFoundData);
  end;

  IMatchmakingTeamBackchannel = interface
    ['{7F239287-630E-425C-B861-D178B51604C9}']
    [RpcHandler('/matchmaking/queue_entered/')]
    procedure EnteredQueue(team_uid : string; QueueData : RMatchmakingQueueData);
    [RpcHandler('/matchmaking/team_update/')]
    procedure TeamUpdate(Data : RMatchmakingTeam);
  end;

  IMatchmakingQueueBackchannel = interface
    ['{828A05A4-C951-4239-A5C6-E4AFACB80DB4}']
    [RpcHandler('/matchmaking/update_queue_data/')]
    procedure UpdateQueueData(Data : RMatchmakingQueueData);
    [RpcHandler('/matchmaking/server_queue_error/')]
    procedure ServerQueueError();
    [RpcHandler('/matchmaking/queue_left/')]
    procedure QueueLeft(Leaver : RMatchmakingUser);
  end;

  TManageServerAPI = class(TRpcApi)
    published
      [RpcUrl('/api/account/user_connected/')]
      function UserConnected(Session_ID : string) : TPromise<integer>; virtual; abstract;
      [RpcUrl('/api/account/user_disconnected/')]
      function UserDisconnected(User_id : integer) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/set_all_user_offline/')]
      /// <summary> If called, in database all user are set to offline, so a defined state is guaranteed.</summary>
      function SetAllUserOffline() : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/check_is_online/')]
      /// <summary> Check if ManageServer is available or not.</summary>
      function CheckIsOnline() : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/account/get_max_current_player_online/', hmGET)]
      function GetMaxCurrentPlayerOnline() : TPromise<integer>; virtual; abstract;
      [RpcUrl('/api/matchmaking/update_matchmaking_queue/')]
      /// <summary> Check if ManageServer is available or not.</summary>
      function UpdateMatchmakingQueue(scenario_identifier : string; tier : integer) : TPromise<Boolean>; virtual; abstract;
      [RpcUrl('/api/matchmaking/get_scenario_instances_list/', hmGET)]
      /// <summary> Check if ManageServer is available or not.</summary>
      function GetScenarioInstanceList() : TPromise<ARBrokerScenarioInstance>; virtual; abstract;
  end;

  TGameManagerAPI = class(TRpcApi)
    [RpcUrl('/api/game_manager/register_gameserver/')]
    function RegisterGameServer(gameserver_ip : string; Port, Max_Game_Count : integer) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/game_manager/get_scenarios/', hmGET)]
    function GetScenarios : TPromise<ARScenario>; virtual; abstract;
    [RpcMixedObjectList('type_identifier', 'type_data')]
    [RpcUrl('/api/game_manager/get_scenario_deck_constraints/', hmGET)]
    function GetScenarioDeckConstraints : TPromise<ATApiScenarioDeckConstraint>; virtual; abstract;
    [RpcUrl('/api/game_manager/game_finished/')]
    function GameFinished(game_uid : string; game_finished_state : integer; game_statistics_data : string; logfile_content : string) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/game_manager/get_game_finished_data/')]
    function GetGameFinishedData(game_uid : string) : TPromise<RGameFinishedData>; virtual; abstract;
    [RpcUrl('/api/game_manager/tutorial_last_step/')]
    function SendTutorialLastStep(tutorial_last_step : string) : TPromise<Boolean>; virtual; abstract;
  end;

  IGameServerBackchannel = interface
    ['{C719EEC9-87F2-444E-A6CB-449A65AD32C6}']
    [RpcHandler('/gameserver/create_game/')]
    function CreateGame(GameData : RGameCreateData) : RGameReponseData;
  end;

  TDeckbuildingAPI = class(TRpcApi)
    [RpcUrl('/api/deckbuilding/get_decks/', hmGET)]
    /// <summary> Returns an array of all decks that current logged in player owns.</summary>
    function GetDecks() : TPromise<ARDeck>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/create_deck/')]
    /// <summary> Create a new deck on server and return the id of this deck, if creation was successfull,
    /// else promise contains error. This deck will contain predefined data and no cards. </summary>
    function CreateDeck() : TPromise<integer>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/delete_deck/')]
    /// <summary> Deletes the deck on server. If current user does not own this deck or deck does
    /// does not exists this operation will fail. </summary>
    function DeleteDeck(deck_id : integer) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/change_deck/', hmPOST)]
    /// <summary> Set any data in the deck.</summary>
    function ChangeDeck(deck_id : integer; deck_data : RDeck) : TPromise<string>; virtual; abstract;
  end;

  IDeckbuildingBackchannel = interface
    ['{FEAA8C66-1A5B-4F7C-A9F0-B781AD3CF42A}']
    [RpcHandler('/deckbuilding/deck_created/')]
    /// <summary> Called if a new deck is created e.g. by selecting a starter deck or buy a starter pack.</summary>
    procedure DeckCreated(deck_data : RDeck);
  end;

  TShopApi = class(TRpcApi)
    [RpcUrl('/api/shop/get_currencies/', hmGET)]
    function GetCurrencies() : TPromise<ARCurrency>; virtual; abstract;
    [RpcUrl('/api/shop/get_balance/', hmGET)]
    function GetBalance() : TPromise<RBalanceData>; virtual; abstract;
    [RpcMixedObjectList('type_identifier', 'type_data')]
    [RpcUrl('/api/shop/get_shop_items/', hmGET)]
    function GetShopItems() : TPromise<ATApiShopItem>; virtual; abstract;
    [RpcUrl('/api/shop/get_shop_purchases_count/', hmGET)]
    function GetShopPurchasesCount() : TPromise<ARShopPurchase>; virtual; abstract;
    [RpcUrl('/api/shop/buy_offer/')]
    function BuyOffer(offer_id : integer; amount : integer) : TPromise<TJSONData>; virtual; abstract;
    [RpcUrl('/api/shop/buy_offer_for_real_money/')]
    function BuyOfferForRealMoney(offer_id : integer; amount : integer; description : string) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/shop/finalize_ingame_purchase/')]
    function FinalizeInGamePurchase(order_id : integer; buy_authorized : integer) : TPromise<TJSONData>; virtual; abstract;
    [RpcUrl('/api/shop/dlc_package_ownerhip_changed/')]
    function DlcOwnershipChanged() : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/shop/redeem_keycode/', hmPOST)]
    function RedeemKey(keycode : string) : TPromise<ARLootboxContent>; virtual; abstract;
    [RpcUrl('/api/loot/get_inventory_draftboxes/', hmGET)]
    function GetInventoryDraftboxes() : TPromise<ARDraftBox>; virtual; abstract;
    [RpcUrl('/api/loot/get_inventory_lootboxes/', hmGET)]
    function GetInventoryLootboxes() : TPromise<ARLootbox>; virtual; abstract;
    [RpcUrl('/api/loot/choose_starterdeck/', hmPOST)]
    function ChooseStarterDeck(Choice : integer) : TPromise<Boolean>; virtual; abstract;
  end;

  IShop = interface
    ['{55A1FCA3-C057-4214-ACFC-0CCE319EB58A}']
    [RpcHandler('/shop/balance_update/')]
    procedure BalanceUpdate(balance_data : RBalance);
  end;

  TLootApi = class(TRpcApi)
    [RpcUrl('/api/loot/open_lootbox/')]
    function OpenLootbox(lootbox_id : integer) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/loot/draft_item_from_draftbox/')]
    function DraftItemFromDraftBox(draftbox_id : integer; choice_id : integer) : TPromise<Boolean>; virtual; abstract;
  end;

  ILoot = interface
    ['{8DA452C9-0A9F-4D26-AE4F-A1ADAEB031E9}']
    [RpcHandler('/loot/new_draftbox/')]
    procedure NewDraftBox(draftbox_data : RDraftBox);
  end;

  TQuestApi = class(TRpcApi)
    [RpcUrl('/api/quests/get_quest_data/', hmGET)]
    function GetCurrentQuestData() : TPromise<RQuestData>; virtual; abstract;
    [RpcUrl('/api/quests/send_player_action/')]
    function SendPlayerAction(action_identifier : string) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/quests/collect_reward/')]
    function CollectReward(quest_progress_id : integer) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/quests/reroll_quest/')]
    function ReRoll(quest_progress_id : integer) : TPromise<Boolean>; virtual; abstract;
  end;

  IQuestBackchannel = interface
    ['{BBE42640-ABA9-4FAA-A9A8-7AFFBA7C7497}']
    [RpcHandler('/quests/quest_progress_update/')]
    procedure QuestUpdate(quest_data : RQuestProgress; created : Boolean);
  end;

  TCardApi = class(TRpcApi)
    [RpcUrl('/api/deckbuilding/get_card_constants/', hmGET)]
    /// <summary> Returns a record containing all important constants for card upgrading. This data is required to
    /// completly emulate server behavior.</summary>
    function GetCardConstants : TPromise<RCardConstants>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/get_cards/', hmGET)]
    /// <summary> Returns an array of all cards available in game.</summary>
    function GetAllCards : TPromise<ARCard>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/get_card_unlocks/', hmGET)]
    /// <summary> Returns an array of all card and skins unlocked for player.</summary>
    function GetAllUnlocks : TPromise<RUnlockData>; virtual; abstract;
    [RpcMixedObjectList('type_identifier', 'type_data')]
    [RpcUrl('/api/deckbuilding/get_card_requirements/', hmGET)]
    /// <summary> Returns an array of all requriements for all cards.</summary>
    function GetCardRequirements : TPromise<AApiCardRequirement>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/get_card_requirement_progress/', hmGET)]
    /// <summary> Returns an array of all requriement progress player has made.</summary>
    function GetCardRequirementProgress : TPromise<ARCardRequirementProgress>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/get_player_cards/', hmGET)]
    /// <summary> Returns an array of all cardinstance that the player owns.</summary>
    function GetPlayerCards : TPromise<ARCardInstance>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/card/ascend/', hmPOST)]
    function UpgradeCardInstance(card_instance_id : integer; card_sacrifice_ids : TArray<integer>; use_premium : Boolean) : TPromise<Boolean>; virtual; abstract;
    [RpcUrl('/api/deckbuilding/card/push_card_xp_by_sacrifice/', hmPOST)]
    function PushCardInstanceExperienceBySacrifice(card_instance_id : integer; card_sacrifice_ids : TArray<integer>) : TPromise<Boolean>; virtual; abstract;
  end;

  ICardBackchannel = interface
    ['{B0E874AA-2947-4C52-AE82-23C4BFD9AAF0}']
    [RpcHandler('/deckbuilding/card_unlocked/')]
    /// <summary> Called if a new card is unlocked for player.</summary>
    procedure CardUnlocked(card_uid : string);
    [RpcHandler('/deckbuilding/skin_unlocked/')]
    /// <summary> Called if a new skin is unlocked for player.</summary>
    procedure SkinUnlocked(skin_uid, card_uid : string);
    [RpcHandler('/deckbuilding/card_instance_changed/')]
    /// <summary> Called if a new card is unlocked for player.</summary>
    procedure CardInstanceChanged(card_instance : RCardInstance; created : Boolean);
    [RpcHandler('/deckbuilding/card_unlock_progress/')]
    /// <summary> Called if unlock progress has changed.</summary>
    procedure CardUnlockProgressUpdate(requirement_id : integer; progress : integer);
  end;

  IDataTracker = interface
    ['{A5F3372F-E5AB-45CC-A8E4-EB4023190B7D}']
    [RpcHandler('/datatracker/data_updated/')]
    procedure DataUpdated(new_data : RDataTrackerData);
  end;

  TMessageApi = class(TRpcApi)
    [RpcUrl('/api/messagebox/get_unread_messages/', hmGET)]
    function GetUnreadMessages : TPromise<ARMessage>; virtual; abstract;
    [RpcUrl('/api/messagebox/mark_as_read_and_collect_all_items/', hmPOST)]
    function ReadMessageAndCollectItems(message_id : integer) : TPromise<Boolean>; virtual; abstract;
  end;

  IMessageBackchannel = interface
    ['{F16A2F1E-CB93-48DD-9833-B51357CC6934}']
    [RpcHandler('/messagebox/new_message/')]
    procedure NewMessage(message_data : RMessage);
  end;

  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  AccountAPI : TAccountAPI;
  FriendlistAPI : TFriendlistAPI;
  ChatAPI : TChatAPI;
  MatchmakingAPI : TMatchmakingAPI;
  ManageServerAPI : TManageServerAPI;
  GameManagerAPI : TGameManagerAPI;
  CardApi : TCardApi;
  DeckBuildingAPI : TDeckbuildingAPI;
  ShopApi : TShopApi;
  LootApi : TLootApi;
  QuestApi : TQuestApi;
  MessageApi : TMessageApi;
  MainActionQueue : TActionQueue;

implementation

initialization

{$WARN CONSTRUCTING_ABSTRACT OFF}
// Create all RPC-APIs
AccountAPI := TAccountAPI.Create;
FriendlistAPI := TFriendlistAPI.Create;
ChatAPI := TChatAPI.Create;
MatchmakingAPI := TMatchmakingAPI.Create;
ManageServerAPI := TManageServerAPI.Create;
GameManagerAPI := TGameManagerAPI.Create;
CardApi := TCardApi.Create;
DeckBuildingAPI := TDeckbuildingAPI.Create;
ShopApi := TShopApi.Create;
LootApi := TLootApi.Create;
QuestApi := TQuestApi.Create;
MessageApi := TMessageApi.Create;
{$WARN CONSTRUCTING_ABSTRACT DEFAULT}

MainActionQueue := TActionQueue.Create;

finalization

// Free all RPC-APIs
FreeAndNil(AccountAPI);
FreeAndNil(FriendlistAPI);
FreeAndNil(ChatAPI);
FreeAndNil(MatchmakingAPI);
FreeAndNil(ManageServerAPI);
FreeAndNil(GameManagerAPI);
FreeAndNil(CardApi);
FreeAndNil(DeckBuildingAPI);
FreeAndNil(ShopApi);
FreeAndNil(LootApi);
FreeAndNil(QuestApi);
FreeAndNil(MessageApi);

FreeAndNil(MainActionQueue);

end.
