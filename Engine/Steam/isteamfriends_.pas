unit isteamfriends_;

interface

uses
  System.SysUtils,
  steamclientpublic,
  steamtypes;

const
  STEAMFRIENDS_INTERFACE_VERSION = 'SteamFriends015';

type

  // -----------------------------------------------------------------------------
  // Purpose: set of relationships to other users
  // -----------------------------------------------------------------------------
  EFriendRelationship =
    (
    k_EFriendRelationshipNone = 0,
    k_EFriendRelationshipBlocked = 1, // this doesn't get stored; the user has just done an Ignore on an friendship invite
    k_EFriendRelationshipRequestRecipient = 2,
    k_EFriendRelationshipFriend = 3,
    k_EFriendRelationshipRequestInitiator = 4,
    k_EFriendRelationshipIgnored = 5, // this is stored; the user has explicit blocked this other user from comments/chat/etc
    k_EFriendRelationshipIgnoredFriend = 6,
    k_EFriendRelationshipSuggested_DEPRECATED = 7, // was used by the original implementation of the facebook linking feature, but now unused.

    // keep this updated
    k_EFriendRelationshipMax = 8
    );

  // maximum length of friend group name (not including terminating nul!)
const
  k_cchMaxFriendsGroupName = 64;

  // maximum number of groups a single user is allowed
const
  k_cFriendsGroupLimit = 100;

  // friends group identifier type
type
  FriendsGroupID_t = Int16;

  // invalid friends group identifier constant
const
  k_FriendsGroupID_Invalid : FriendsGroupID_t = -1;

const
  k_cEnumerateFollowersMax = 50;

type
  // -----------------------------------------------------------------------------
  // Purpose: list of states a friend can be in
  // -----------------------------------------------------------------------------
  EPersonaState =
    (
    k_EPersonaStateOffline = 0,        // friend is not currently logged on
    k_EPersonaStateOnline = 1,         // friend is logged on
    k_EPersonaStateBusy = 2,           // user is on, but busy
    k_EPersonaStateAway = 3,           // auto-away feature
    k_EPersonaStateSnooze = 4,         // auto-away for a long time
    k_EPersonaStateLookingToTrade = 5, // Online, trading
    k_EPersonaStateLookingToPlay = 6,  // Online, wanting to play
    k_EPersonaStateMax
    );

  // -----------------------------------------------------------------------------
  // Purpose: flags for enumerating friends list, or quickly checking a the relationship between users
  // -----------------------------------------------------------------------------
  // EFriendFlags
const

  k_EFriendFlagNone                = $00;
  k_EFriendFlagBlocked             = $01;
  k_EFriendFlagFriendshipRequested = $02;
  k_EFriendFlagImmediate           = $04; // "regular" friend
  k_EFriendFlagClanMember          = $08;
  k_EFriendFlagOnGameServer        = $10;
  // k_EFriendFlagHasPlayedWith	= $20;	// not currently used
  // k_EFriendFlagFriendOfFriend	= $40; // not currently used
  k_EFriendFlagRequestingFriendship = $80;
  k_EFriendFlagRequestingInfo       = $100;
  k_EFriendFlagIgnored              = $200;
  k_EFriendFlagIgnoredFriend        = $400;
  // k_EFriendFlagSuggested		= $800;	// not used
  k_EFriendFlagChatMember = $1000;
  k_EFriendFlagAll        = $FFFF;

type
  FriendGameInfo_t = record
    m_gameID : CGameID;
    m_unGameIP : UInt32;
    m_usGamePort : UInt16;
    m_usQueryPort : UInt16;
    m_steamIDLobby : CSteamID;
  end;

  // maximum number of characters in a user's name. Two flavors; one for UTF-8 and one for UTF-16.
  // The UTF-8 version has to be very generous to accomodate characters that get large when encoded
  // in UTF-8.
const
  k_cchPersonaNameMax  = 128;
  k_cwchPersonaNameMax = 32;

type
  // -----------------------------------------------------------------------------
  // Purpose: user restriction flags
  // -----------------------------------------------------------------------------
  EUserRestriction =
    (
    k_nUserRestrictionNone = 0,         // no known chat/content restriction
    k_nUserRestrictionUnknown = 1,      // we don't know yet (user offline)
    k_nUserRestrictionAnyChat = 2,      // user is not allowed to (or can't) send/recv any chat
    k_nUserRestrictionVoiceChat = 4,    // user is not allowed to (or can't) send/recv voice chat
    k_nUserRestrictionGroupChat = 8,    // user is not allowed to (or can't) send/recv group chat
    k_nUserRestrictionRating = 16,      // user is too young according to rating in current region
    k_nUserRestrictionGameInvites = 32, // user cannot send or recv game invites (e.g. mobile)
    k_nUserRestrictionTrading = 64      // user cannot participate in trading (console, mobile)
    );

  // -----------------------------------------------------------------------------
  // Purpose: information about user sessions
  // -----------------------------------------------------------------------------
  FriendSessionStateInfo_t = record
    m_uiOnlineSessionInstances : UInt32;
    m_uiPublishedToFriendsSessionInstance : UInt8;
  end;

  // size limit on chat room or member metadata
const
  k_cubChatMetadataMax : UInt32 = 8192;

  // size limits on Rich Presence data
  k_cchMaxRichPresenceKeys        = 20;
  k_cchMaxRichPresenceKeyLength   = 64;
  k_cchMaxRichPresenceValueLength = 256;

type
  // These values are passed as parameters to the store
  EOverlayToStoreFlag =
    (
    k_EOverlayToStoreFlag_None = 0,
    k_EOverlayToStoreFlag_AddToCart = 1,
    k_EOverlayToStoreFlag_AddToCartAndShow = 2
    );

  // helper record for typed pointer
  _ISteamFriends = record
  end;

  PISteamFriends = ^_ISteamFriends;

  ISteamFriends = class
    private
      FHandle : PISteamFriends;
    public
      // activates game overlay to a specific place
      // valid options are
      // "steamid" - opens the overlay web browser to the specified user or groups profile
      // "chat" - opens a chat window to the specified user, or joins the group chat
      // "jointrade" - opens a window to a Steam Trading session that was started with the ISteamEconomy/StartTrade Web API
      // "stats" - opens the overlay web browser to the specified user's stats
      // "achievements" - opens the overlay web browser to the specified user's achievements
      // "friendadd" - opens the overlay in minimal mode prompting the user to add the target user as a friend
      // "friendremove" - opens the overlay in minimal mode prompting the user to remove the target friend
      // "friendrequestaccept" - opens the overlay in minimal mode prompting the user to accept an incoming friend invite
      // "friendrequestignore" - opens the overlay in minimal mode prompting the user to ignore an incoming friend invite
      procedure ActivateGameOverlayToUser(const pchDialog : string; steamID : CSteamID);

      // friend iteration
      // takes a set of k_EFriendFlags, and returns the number of users the client knows about who meet that criteria
      // then GetFriendByIndex() can then be used to return the id's of each of those users
      function GetFriendCount(iFriendFlags : integer) : integer;
      // returns the steamID of a user
      // iFriend is a index of range [0, GetFriendCount())
      // iFriendsFlags must be the same value as used in GetFriendCount()
      // the returned CSteamID can then be used by all the functions below to access details about the user
      function GetFriendByIndex(iFriend : integer; iFriendFlags : integer) : SteamID_t;
      // returns the name another user - guaranteed to not be NULL.
      // same rules as GetFriendPersonaState() apply as to whether or not the user knowns the name of the other user
      // note that on first joining a lobby, chat room or game server the local user will not known the name of the other users automatically; that information will arrive asyncronously
      function GetFriendPersonaName(steamIDFriend : CSteamID) : string;
      // if current user is chat restricted, he can't send or receive any text/voice chat messages.
      // the user can't see custom avatars. But the user can be online and send/recv game invites.
      // a chat restricted user can't add friends or join any groups.

      function GetUserRestrictions : UInt32;

      constructor Create(SteamFriendsHandle : PISteamFriends);
      destructor Destroy; override;
  end;

implementation

uses
  steam_api;

function SteamAPI_ISteamFriends_GetPersonaName(SteamFriends : PISteamFriends) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamFriends_SetPersonaName(SteamFriends : PISteamFriends; const char *pchPersonaName) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetPersonaState(SteamFriends : PISteamFriends) : EPersonaState; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendCount(SteamFriends : PISteamFriends; iFriendFlags : integer) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendByIndex(SteamFriends : PISteamFriends; iFriend : integer; iFriendFlags : integer) : SteamID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendRelationship(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : EFriendRelationship; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendPersonaState(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : EPersonaState; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendPersonaName(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendGamePlayed(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; out pFriendGameInfo : FriendGameInfo_t) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendPersonaNameHistory(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; iPersonaName : integer) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendSteamLevel(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetPlayerNickname(SteamFriends : PISteamFriends; steamIDPlayer : CSteamID) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendsGroupCount(SteamFriends : PISteamFriends) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendsGroupIDByIndex(SteamFriends : PISteamFriends; iFG : integer) : FriendsGroupID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendsGroupName(SteamFriends : PISteamFriends; friendsGroupID : FriendsGroupID_t) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendsGroupMembersCount(SteamFriends : PISteamFriends; friendsGroupID : FriendsGroupID_t) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_GetFriendsGroupMembersList(SteamFriends : PISteamFriends; friendsGroupID : FriendsGroupID_t; pOutSteamIDMembers : PCSteamID; nMembersCount : integer); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_HasFriend(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; iFriendFlags : integer) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanCount(SteamFriends : PISteamFriends) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanByIndex(SteamFriends : PISteamFriends; iClan : integer) : SteamID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanName(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanTag(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanActivityCounts(SteamFriends : PISteamFriends; steamIDClan : CSteamID; out pnOnline : integer; out pnInGame : integer; out pnChatting : integer) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamFriends_DownloadClanActivityCounts(SteamFriends : PISteamFriends; psteamIDClans : PCSteamID; cClansToRequest : integer) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendCountFromSource(SteamFriends : PISteamFriends; steamIDSource : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendFromSourceByIndex(SteamFriends : PISteamFriends; steamIDSource : CSteamID; iFriend : integer) : SteamID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_IsUserInSource(SteamFriends : PISteamFriends; steamIDUser : CSteamID; steamIDSource : CSteamID) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(SteamFriends : PISteamFriends; steamIDUser : CSteamID; bSpeaking : Boolean); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_ActivateGameOverlay(SteamFriends : PISteamFriends; const pchDialog : AnsiString); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayToUser(SteamFriends : PISteamFriends; const pchDialog : AnsiString; steamID : CSteamID); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(SteamFriends : PISteamFriends; const pchURL : AnsiString); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayToStore(SteamFriends : PISteamFriends; nAppID : AppId_t; eFlag : EOverlayToStoreFlag); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_SetPlayedWith(SteamFriends : PISteamFriends; steamIDUserPlayedWith : CSteamID); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(SteamFriends : PISteamFriends; steamIDLobby : CSteamID); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetSmallFriendAvatar(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetMediumFriendAvatar(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetLargeFriendAvatar(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_RequestUserInformation(SteamFriends : PISteamFriends; steamIDUser : CSteamID; bRequireNameOnly : Boolean) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamFriends_RequestClanOfficerList(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanOwner(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : SteamID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanOfficerCount(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanOfficerByIndex(SteamFriends : PISteamFriends; steamIDClan : CSteamID; iOfficer : integer) : SteamID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetUserRestrictions(SteamFriends : PISteamFriends) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_SetRichPresence(SteamFriends : PISteamFriends; const pchKey : AnsiString; const pchValue : AnsiString) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_ClearRichPresence(SteamFriends : PISteamFriends); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendRichPresence(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; const pchKey : AnsiString) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; iKey : integer) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamFriends_RequestFriendRichPresence(SteamFriends : PISteamFriends; steamIDFriend : CSteamID); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_InviteUserToGame(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; const pchConnectString : AnsiString) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetCoplayFriendCount(SteamFriends : PISteamFriends) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetCoplayFriend(SteamFriends : PISteamFriends; iCoplayFriend : integer) : SteamID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendCoplayTime(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendCoplayGame(SteamFriends : PISteamFriends; steamIDFriend : CSteamID) : AppId_t; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamFriends_JoinClanChatRoom(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_LeaveClanChatRoom(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanChatMemberCount(SteamFriends : PISteamFriends; steamIDClan : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetChatMemberByIndex(SteamFriends : PISteamFriends; steamIDClan : CSteamID; iUser : integer) : SteamID_t; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_SendClanChatMessage(SteamFriends : PISteamFriends; steamIDClanChat : CSteamID; const pchText : AnsiString) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetClanChatMessage(SteamFriends : PISteamFriends; steamIDClanChat : CSteamID; iMessage : integer; prgchText : Pointer; cchTextMax : integer; out peChatEntryType : EChatEntryType; out psteamidChatter : CSteamID) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_IsClanChatAdmin(SteamFriends : PISteamFriends; steamIDClanChat : CSteamID; steamIDUser : CSteamID) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam(SteamFriends : PISteamFriends; steamIDClanChat : CSteamID) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_OpenClanChatWindowInSteam(SteamFriends : PISteamFriends; steamIDClanChat : CSteamID) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_CloseClanChatWindowInSteam(SteamFriends : PISteamFriends; steamIDClanChat : CSteamID) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_SetListenForFriendsMessages(SteamFriends : PISteamFriends; bInterceptEnabled : Boolean) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_ReplyToFriendMessage(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; const pchMsgToSend : AnsiString) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamFriends_GetFriendMessage(SteamFriends : PISteamFriends; steamIDFriend : CSteamID; iMessageID : integer; pvData : Pointer; cubData : integer; out peChatEntryType : EChatEntryType) : integer; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamFriends_GetFollowerCount(SteamFriends : PISteamFriends; CSteamID steamID) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamFriends_IsFollowing(SteamFriends : PISteamFriends; CSteamID steamID) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamFriends_EnumerateFollowingList(SteamFriends : PISteamFriends; uint32 unStartIndex) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;

{ ISteamFriends }

procedure ISteamFriends.ActivateGameOverlayToUser(const pchDialog : string; steamID : CSteamID);
begin
  SteamAPI_ISteamFriends_ActivateGameOverlayToUser(FHandle, AnsiString(pchDialog), steamID);
end;

constructor ISteamFriends.Create(SteamFriendsHandle : PISteamFriends);
begin
  FHandle := SteamFriendsHandle;
end;

destructor ISteamFriends.Destroy;
begin

  inherited;
end;

function ISteamFriends.GetFriendByIndex(iFriend, iFriendFlags : integer) : CSteamID;
begin
  result := SteamAPI_ISteamFriends_GetFriendByIndex(FHandle, iFriend, iFriendFlags);
end;

function ISteamFriends.GetFriendCount(iFriendFlags : integer) : integer;
begin
  result := SteamAPI_ISteamFriends_GetFriendCount(FHandle, iFriendFlags);
end;

function ISteamFriends.GetFriendPersonaName(steamIDFriend: CSteamID): string;
begin
  result := String(SteamAPI_ISteamFriends_GetFriendPersonaName(FHandle, steamIDFriend));
end;

function ISteamFriends.GetUserRestrictions : UInt32;
begin
  result := SteamAPI_ISteamFriends_GetUserRestrictions(FHandle);
end;

end.
