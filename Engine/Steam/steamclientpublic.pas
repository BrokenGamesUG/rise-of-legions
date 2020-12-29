unit steamclientpublic;

interface

uses
  System.SysUtils;

type
  ESteamException = class(Exception);

  // General result codes
  EResult =
    (
    k_EResultOK = 1,           // success
    k_EResultFail = 2,         // generic failure
    k_EResultNoConnection = 3, // no/failed network connection
    // k_EResultNoConnectionRetry = 4,				// OBSOLETE - removed
    k_EResultInvalidPassword = 5,        // password/ticket is invalid
    k_EResultLoggedInElsewhere = 6,      // same user logged in elsewhere
    k_EResultInvalidProtocolVer = 7,     // protocol version is incorrect
    k_EResultInvalidParam = 8,           // a parameter is incorrect
    k_EResultFileNotFound = 9,           // file was not found
    k_EResultBusy = 10,                  // called method busy - action not taken
    k_EResultInvalidState = 11,          // called object was in an invalid state
    k_EResultInvalidName = 12,           // name is invalid
    k_EResultInvalidEmail = 13,          // email is invalid
    k_EResultDuplicateName = 14,         // name is not unique
    k_EResultAccessDenied = 15,          // access is denied
    k_EResultTimeout = 16,               // operation timed out
    k_EResultBanned = 17,                // VAC2 banned
    k_EResultAccountNotFound = 18,       // account not found
    k_EResultInvalidSteamID = 19,        // steamID is invalid
    k_EResultServiceUnavailable = 20,    // The requested service is currently unavailable
    k_EResultNotLoggedOn = 21,           // The user is not logged on
    k_EResultPending = 22,               // Request is pending (may be in process, or waiting on third party)
    k_EResultEncryptionFailure = 23,     // Encryption or Decryption failed
    k_EResultInsufficientPrivilege = 24, // Insufficient privilege
    k_EResultLimitExceeded = 25,         // Too much of a good thing
    k_EResultRevoked = 26,               // Access has been revoked (used for revoked guest passes)
    k_EResultExpired = 27,               // License/Guest pass the user is trying to access is expired
    k_EResultAlreadyRedeemed = 28,       // Guest pass has already been redeemed by account, cannot be acked again
    k_EResultDuplicateRequest = 29,      // The request is a duplicate and the action has already occurred in the past, ignored this time
    k_EResultAlreadyOwned = 30,          // All the games in this guest pass redemption request are already owned by the user
    k_EResultIPNotFound = 31,            // IP address not found
    k_EResultPersistFailed = 32,         // failed to write change to the data store
    k_EResultLockingFailed = 33,         // failed to acquire access lock for this operation
    k_EResultLogonSessionReplaced = 34,
    k_EResultConnectFailed = 35,
    k_EResultHandshakeFailed = 36,
    k_EResultIOFailure = 37,
    k_EResultRemoteDisconnect = 38,
    k_EResultShoppingCartNotFound = 39, // failed to find the shopping cart requested
    k_EResultBlocked = 40,              // a user didn't allow it
    k_EResultIgnored = 41,              // target is ignoring sender
    k_EResultNoMatch = 42,              // nothing matching the request found
    k_EResultAccountDisabled = 43,
    k_EResultServiceReadOnly = 44,               // this service is not accepting content changes right now
    k_EResultAccountNotFeatured = 45,            // account doesn't have value, so this feature isn't available
    k_EResultAdministratorOK = 46,               // allowed to take this action, but only because requester is admin
    k_EResultContentVersion = 47,                // A Version mismatch in content transmitted within the Steam protocol.
    k_EResultTryAnotherCM = 48,                  // The current CM can't service the user making a request, user should try another.
    k_EResultPasswordRequiredToKickSession = 49, // You are already logged in elsewhere, this cached credential login has failed.
    k_EResultAlreadyLoggedInElsewhere = 50,      // You are already logged in elsewhere, you must wait
    k_EResultSuspended = 51,                     // Long running operation (content download) suspended/paused
    k_EResultCancelled = 52,                     // Operation canceled (typically by user: content download)
    k_EResultDataCorruption = 53,                // Operation canceled because data is ill formed or unrecoverable
    k_EResultDiskFull = 54,                      // Operation canceled - not enough disk space.
    k_EResultRemoteCallFailed = 55,              // an remote call or IPC call failed
    k_EResultPasswordUnset = 56,                 // Password could not be verified as it's unset server side
    k_EResultExternalAccountUnlinked = 57,       // External account (PSN, Facebook...) is not linked to a Steam account
    k_EResultPSNTicketInvalid = 58,              // PSN ticket was invalid
    k_EResultExternalAccountAlreadyLinked = 59,  // External account (PSN, Facebook...) is already linked to some other account, must explicitly request to replace/delete the link first
    k_EResultRemoteFileConflict = 60,            // The sync cannot resume due to a conflict between the local and remote files
    k_EResultIllegalPassword = 61,               // The requested new password is not legal
    k_EResultSameAsPreviousValue = 62,           // new value is the same as the old one ( secret question and answer )
    k_EResultAccountLogonDenied = 63,            // account login denied due to 2nd factor authentication failure
    k_EResultCannotUseOldPassword = 64,          // The requested new password is not legal
    k_EResultInvalidLoginAuthCode = 65,          // account login denied due to auth code invalid
    k_EResultAccountLogonDeniedNoMail = 66,      // account login denied due to 2nd factor auth failure - and no mail has been sent
    k_EResultHardwareNotCapableOfIPT = 67,       //
    k_EResultIPTInitError = 68,                  //
    k_EResultParentalControlRestricted = 69,     // operation failed due to parental control restrictions for current user
    k_EResultFacebookQueryError = 70,            // Facebook query returned an error
    k_EResultExpiredLoginAuthCode = 71,          // account login denied due to auth code expired
    k_EResultIPLoginRestrictionFailed = 72,
    k_EResultAccountLockedDown = 73,
    k_EResultAccountLogonDeniedVerifiedEmailRequired = 74,
    k_EResultNoMatchingURL = 75,
    k_EResultBadResponse = 76,                         // parse failure, missing field, etc.
    k_EResultRequirePasswordReEntry = 77,              // The user cannot complete the action until they re-enter their password
    k_EResultValueOutOfRange = 78,                     // the value entered is outside the acceptable range
    k_EResultUnexpectedError = 79,                     // something happened that we didn't expect to ever happen
    k_EResultDisabled = 80,                            // The requested service has been configured to be unavailable
    k_EResultInvalidCEGSubmission = 81,                // The set of files submitted to the CEG server are not valid !
    k_EResultRestrictedDevice = 82,                    // The device being used is not allowed to perform this action
    k_EResultRegionLocked = 83,                        // The action could not be complete because it is region restricted
    k_EResultRateLimitExceeded = 84,                   // Temporary rate limit exceeded, try again later, different from k_EResultLimitExceeded which may be permanent
    k_EResultAccountLoginDeniedNeedTwoFactor = 85,     // Need two-factor code to login
    k_EResultItemDeleted = 86,                         // The thing we're trying to access has been deleted
    k_EResultAccountLoginDeniedThrottle = 87,          // login attempt failed, try to throttle response to possible attacker
    k_EResultTwoFactorCodeMismatch = 88,               // two factor code mismatch
    k_EResultTwoFactorActivationCodeMismatch = 89,     // activation code for two-factor didn't match
    k_EResultAccountAssociatedToMultiplePartners = 90, // account has been associated with multiple partners
    k_EResultNotModified = 91,                         // data not modified
    k_EResultNoMobileDevice = 92,                      // the account does not have a mobile device associated with it
    k_EResultTimeNotSynced = 93,                       // the time presented is out of range or tolerance
    k_EResultSmsCodeFailed = 94,                       // SMS code failure (no match, none pending, etc.)
    k_EResultAccountLimitExceeded = 95,                // Too many accounts access this resource
    k_EResultAccountActivityLimitExceeded = 96,        // Too many changes to this account
    k_EResultPhoneActivityLimitExceeded = 97,          // Too many changes to this phone
    k_EResultRefundToWallet = 98,                      // Cannot refund to payment method, must use wallet
    k_EResultEmailSendFailure = 99,                    // Cannot send an email
    k_EResultNotSettled = 100,                         // Can't perform operation till payment has settled
    k_EResultNeedCaptcha = 101,                        // Needs to provide a valid captcha
    k_EResultGSLTDenied = 102,                         // a game server login token owned by this token's owner has been banned
    k_EResultGSOwnerDenied = 103,                      // game server owner is denied for other reason (account lock, community ban, vac ban, missing phone)
    k_EResultInvalidItemType = 104,                    // the type of thing we were requested to act on is invalid
    k_EResultIPBanned = 105,                           // the ip address has been banned from taking this action
    k_EResultGSLTExpired = 106,                        // this token has expired from disuse; can be reset for use
    k_EResultInsufficientFunds = 107,                  // user doesn't have enough wallet funds to complete the action
    k_EResultTooManyPending = 108,                     // There are too many of this thing pending already
    k_EResultNoSiteLicensesFound = 109,                // No site licenses found
    k_EResultWGNetworkSendExceeded = 110               // the WG couldn't send a response because we exceeded max network send size
    );

  // Error codes for use with the voice functions
  EVoiceResult =
    (
    k_EVoiceResultOK = 0,
    k_EVoiceResultNotInitialized = 1,
    k_EVoiceResultNotRecording = 2,
    k_EVoiceResultNoData = 3,
    k_EVoiceResultBufferTooSmall = 4,
    k_EVoiceResultDataCorrupted = 5,
    k_EVoiceResultRestricted = 6,
    k_EVoiceResultUnsupportedCodec = 7,
    k_EVoiceResultReceiverOutOfDate = 8,
    k_EVoiceResultReceiverDidNotAnswer = 9
    );

  // Steam account types
  EAccountType =
    (
    k_EAccountTypeInvalid = 0,
    k_EAccountTypeIndividual = 1,     // single user account
    k_EAccountTypeMultiseat = 2,      // multiseat (e.g. cybercafe) account
    k_EAccountTypeGameServer = 3,     // game server account
    k_EAccountTypeAnonGameServer = 4, // anonymous game server account
    k_EAccountTypePending = 5,        // pending
    k_EAccountTypeContentServer = 6,  // content server
    k_EAccountTypeClan = 7,
    k_EAccountTypeChat = 8,
    k_EAccountTypeConsoleUser = 9, // Fake SteamID for local PSN account on PS3 or Live account on 360, etc.
    k_EAccountTypeAnonUser = 10,

    // Max of 16 items in this field
    k_EAccountTypeMax
    );

  // -----------------------------------------------------------------------------
  // Purpose:
  // -----------------------------------------------------------------------------
  EAppReleaseState =
    (
    k_EAppReleaseState_Unknown = 0,     // unknown, required appinfo or license info is missing
    k_EAppReleaseState_Unavailable = 1, // even if user 'just' owns it, can see game at all
    k_EAppReleaseState_Prerelease = 2,  // can be purchased and is visible in games list, nothing else. Common appInfo section released
    k_EAppReleaseState_PreloadOnly = 3, // owners can preload app, not play it. AppInfo fully released.
    k_EAppReleaseState_Released = 4     // owners can download and play app.
    );

  // -----------------------------------------------------------------------------
  // Purpose:
  // -----------------------------------------------------------------------------
  EAppOwnershipFlags =
    (
    k_EAppOwnershipFlags_None = $0000,                // unknown
    k_EAppOwnershipFlags_OwnsLicense = $0001,         // owns license for this game
    k_EAppOwnershipFlags_FreeLicense = $0002,         // not paid for game
    k_EAppOwnershipFlags_RegionRestricted = $0004,    // owns app, but not allowed to play in current region
    k_EAppOwnershipFlags_LowViolence = $0008,         // only low violence version
    k_EAppOwnershipFlags_InvalidPlatform = $0010,     // app not supported on current platform
    k_EAppOwnershipFlags_SharedLicense = $0020,       // license was granted by authorized local device
    k_EAppOwnershipFlags_FreeWeekend = $0040,         // owned by a free weekend licenses
    k_EAppOwnershipFlags_RetailLicense = $0080,       // has a retail license for game, (CD-Key etc)
    k_EAppOwnershipFlags_LicenseLocked = $0100,       // shared license is locked (in use) by other user
    k_EAppOwnershipFlags_LicensePending = $0200,      // owns app, but transaction is still pending. Can't install or play
    k_EAppOwnershipFlags_LicenseExpired = $0400,      // doesn't own app anymore since license expired
    k_EAppOwnershipFlags_LicensePermanent = $0800,    // permanent license, not borrowed, or guest or freeweekend etc
    k_EAppOwnershipFlags_LicenseRecurring = $1000,    // Recurring license, user is charged periodically
    k_EAppOwnershipFlags_LicenseCanceled = $2000,     // Mark as canceled, but might be still active if recurring
    k_EAppOwnershipFlags_AutoGrant = $4000,           // Ownership is based on any kind of autogrant license
    k_EAppOwnershipFlags_PendingGift = $8000,         // user has pending gift to redeem
    k_EAppOwnershipFlags_RentalNotActivated = $10000, // Rental hasn't been activated yet
    k_EAppOwnershipFlags_Rental = $20000,             // Is a rental
    k_EAppOwnershipFlags_SiteLicense = $40000         // Is from a site license
    );

  // -----------------------------------------------------------------------------
  // Purpose: designed as flags to allow filters masks
  // -----------------------------------------------------------------------------
  EAppType =
    (
    k_EAppType_Invalid = $000,          // unknown / invalid
    k_EAppType_Game = $001,             // playable game, default type
    k_EAppType_Application = $002,      // software application
    k_EAppType_Tool = $004,             // SDKs, editors & dedicated servers
    k_EAppType_Demo = $008,             // game demo
    k_EAppType_Media_DEPRECATED = $010, // legacy - was used for game trailers, which are now just videos on the web
    k_EAppType_DLC = $020,              // down loadable content
    k_EAppType_Guide = $040,            // game guide, PDF etc
    k_EAppType_Driver = $080,           // hardware driver updater (ATI, Razor etc)
    k_EAppType_Config = $100,           // hidden app used to config Steam features (backpack, sales, etc)
    k_EAppType_Hardware = $200,         // a hardware device (Steam Machine, Steam Controller, Steam Link, etc.)
    k_EAppType_Franchise = $400,        // A hub for collections of multiple apps, eg films, series, games
    k_EAppType_Video = $800,            // A video component of either a Film or TVSeries (may be the feature, an episode, preview, making-of, etc)
    k_EAppType_Plugin = $1000,          // Plug-in types for other Apps
    k_EAppType_Music = $2000,           // Music files
    k_EAppType_Series = $4000,          // Container app for video series
    k_EAppType_Comic = $8000,           // Comic Book

    k_EAppType_Shortcut = $40000000// just a shortcut, client side only
    // k_EAppType_DepotOnly			= $80000000	// placeholder since depots and apps share the same namespace
    );

  // -----------------------------------------------------------------------------
  // types of user game stats fields
  // WARNING: DO NOT RENUMBER EXISTING VALUES - STORED IN DATABASE
  // -----------------------------------------------------------------------------
  ESteamUserStatType =
    (
    k_ESteamUserStatTypeINVALID = 0,
    k_ESteamUserStatTypeINT = 1,
    k_ESteamUserStatTypeFLOAT = 2,
    // Read as FLOAT, set with count / session length
    k_ESteamUserStatTypeAVGRATE = 3,
    k_ESteamUserStatTypeACHIEVEMENTS = 4,
    k_ESteamUserStatTypeGROUPACHIEVEMENTS = 5,

    // max, for sanity checks
    k_ESteamUserStatTypeMAX
    );

  // -----------------------------------------------------------------------------
  // Purpose: Chat Entry Types (previously was only friend-to-friend message types)
  // -----------------------------------------------------------------------------
  EChatEntryType =
    (
    k_EChatEntryTypeInvalid = 0,
    k_EChatEntryTypeChatMsg = 1,    // Normal text message from another user
    k_EChatEntryTypeTyping = 2,     // Another user is typing (not used in multi-user chat)
    k_EChatEntryTypeInviteGame = 3, // Invite from other user into that users current game
    k_EChatEntryTypeEmote = 4,      // text emote message (deprecated, should be treated as ChatMsg)
    // k_EChatEntryTypeLobbyGameStart = 5,	// lobby game is starting (dead - listen for LobbyGameCreated_t callback instead)
    k_EChatEntryTypeLeftConversation = 6, // user has left the conversation ( closed chat window )
    // Above are previous FriendMsgType entries, now merged into more generic chat entry types
    k_EChatEntryTypeEntered = 7,         // user has entered the conversation (used in multi-user chat and group chat)
    k_EChatEntryTypeWasKicked = 8,       // user was kicked (data: 64-bit steamid of actor performing the kick)
    k_EChatEntryTypeWasBanned = 9,       // user was banned (data: 64-bit steamid of actor performing the ban)
    k_EChatEntryTypeDisconnected = 10,   // user disconnected
    k_EChatEntryTypeHistoricalChat = 11, // a chat message from user's chat history or offilne message
    // k_EChatEntryTypeReserved1 = 12, // No longer used
    // k_EChatEntryTypeReserved2 = 13, // No longer used
    k_EChatEntryTypeLinkBlocked = 14// a link was removed by the chat filter.
    );

  // return type of GetAuthSessionTicket
type
  HAuthTicket = uint32;
const
  k_HAuthTicketInvalid : HAuthTicket = 0;

type
  // results from BeginAuthSession
  EBeginAuthSessionResult =
    (
    k_EBeginAuthSessionResultOK = 0,               // Ticket is valid for this game and this steamID.
    k_EBeginAuthSessionResultInvalidTicket = 1,    // Ticket is not valid.
    k_EBeginAuthSessionResultDuplicateRequest = 2, // A ticket has already been submitted for this steamID
    k_EBeginAuthSessionResultInvalidVersion = 3,   // Ticket is from an incompatible interface version
    k_EBeginAuthSessionResultGameMismatch = 4,     // Ticket is not for this game
    k_EBeginAuthSessionResultExpiredTicket = 5     // Ticket has expired
    );

  // Callback values for callback ValidateAuthTicketResponse_t which is a response to BeginAuthSession
  EAuthSessionResponse =
    (
    k_EAuthSessionResponseOK = 0,                      // Steam has verified the user is online, the ticket is valid and ticket has not been reused.
    k_EAuthSessionResponseUserNotConnectedToSteam = 1, // The user in question is not connected to steam
    k_EAuthSessionResponseNoLicenseOrExpired = 2,      // The license has expired.
    k_EAuthSessionResponseVACBanned = 3,               // The user is VAC banned for this game.
    k_EAuthSessionResponseLoggedInElseWhere = 4,       // The user account has logged in elsewhere and the session containing the game instance has been disconnected.
    k_EAuthSessionResponseVACCheckTimedOut = 5,        // VAC has been unable to perform anti-cheat checks on this user
    k_EAuthSessionResponseAuthTicketCanceled = 6,      // The ticket has been canceled by the issuer
    k_EAuthSessionResponseAuthTicketInvalidAlreadyUsed = 7, // This ticket has already been used, it is not valid.
    k_EAuthSessionResponseAuthTicketInvalid = 8, // This ticket is not from a user instance currently connected to steam.
    k_EAuthSessionResponsePublisherIssuedBan = 9 // The user is banned for this game. The ban came via the web api and not VAC
    );

  // results from UserHasLicenseForApp
  EUserHasLicenseForAppResult =
    (
    k_EUserHasLicenseResultHasLicense = 0,         // User has a license for specified app
    k_EUserHasLicenseResultDoesNotHaveLicense = 1, // User does not have a license for the specified app
    k_EUserHasLicenseResultNoAuth = 2              // User has not been authenticated
    );

  // -----------------------------------------------------------------------------
  // Purpose: Possible positions to tell the overlay to show notifications in
  // -----------------------------------------------------------------------------
  ENotificationPosition =
    (
    k_EPositionTopLeft = 0,
    k_EPositionTopRight = 1,
    k_EPositionBottomLeft = 2,
    k_EPositionBottomRight = 3
    );

type
  // helper record for typed pointer, don't use ISteamClient here, because pointer
  // points to c++ class and direct use (dereference) would cause serious errors
  _CSteamID = record

  end;

  // CSteamID = ^_CSteamID;
  CSteamID = UInt64;
  PCSteamID = ^CSteamID;

  // helper record for typed pointer, don't use ISteamClient here, because pointer
  // points to c++ class and direct use (dereference) would cause serious errors
  _CGameID = record

  end;

  CGameID = ^_CGameID;

  SteamID_t = UInt64;

implementation

end.
