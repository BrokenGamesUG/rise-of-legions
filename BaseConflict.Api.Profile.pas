unit BaseConflict.Api.Profile;

interface

uses
  // System
  System.DateUtils,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Math,
  // Engine
  Engine.Helferlein,
  Engine.DataQuery,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Helferlein.Windows,
  Engine.Serializer.Json,
  Engine.Network.RPC,
  Engine.dXML,
  // Game
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Client,
  BaseConflict.Api.Account,
  BaseConflict.Api,
  BaseConflict.Api.Types,
  BaseConflict.Api.Shared,
  BaseConflict.Api.Shop;

type

  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic, vcPrivate]) FIELDS([vcPublic, vcProtected]) PROPERTIES([vcPublic, vcPublished])}
  {$M+}
  TUserProfile = class;

  TLevelUpReward = class
    strict private
      FLevel : integer;
      FLoot : TLootList;
      FAdditionalText : string;
    published
      property Level : integer read FLevel;
      property Loot : TLootList read FLoot;
      property AdditionalText : string read FAdditionalText;
      function HasText : boolean;
    public
      constructor Create(const Data : RLevelUpReward);
      destructor Destroy; override;
  end;

  TProfileConstants = class
    strict private
      FPlayerLevelTable : TDictionary<integer, integer>;
      FPlayerMaxLevel : integer;
      FPlayerLevelUpRewardList : TList<TLevelUpReward>;
      FPlayerLevelUpRewards : TObjectDictionary<integer, TLevelUpReward>;
    public
      property PlayerMaxLevel : integer read FPlayerMaxLevel;
      /// <summary> CurrentLevel => Exp needed for next Level.</summary>
      property PlayerLevelTable : TDictionary<integer, integer> read FPlayerLevelTable;
      property PlayerLevelUpRewards : TObjectDictionary<integer, TLevelUpReward> read FPlayerLevelUpRewards;
      property PlayerLevelUpRewardList : TList<TLevelUpReward> read FPlayerLevelUpRewardList;
      constructor Create(const Data : RProfileConstants);
      destructor Destroy; override;
  end;

  /// <summary> Client class for a tutorial video showned in meta client.</summary>
  TTutorialVideo = class
    strict private
      FId : integer;
      FIdentifier : string;
      FTitle : string;
      FUrl : string;
      FOrderValue : integer;
      FProfile : TUserProfile;
    strict private
      FSeen : boolean;
      procedure SetSeen(const Value : boolean); virtual;
    published
      property Seen : boolean read FSeen write SetSeen;
    public
      property ID : integer read FId;
      property Identifier : string read FIdentifier;
      /// <summary> Value video ordered, from low to high (e.g. 0 first video, 10 last)</summary>
      property OrderValue : integer read FOrderValue;
      property Url : string read FUrl;
      property Title : string read FTitle;
      constructor Create(Profile : TUserProfile; const Data : RTutorialVideo);
      procedure Play;
  end;

  ProcLevelUpReward = procedure(Reward : TLootbox; ForReachingLevel : integer; AdditionalText : string) of object;

  TUserProfile = class(TInterfacedObject, IProfileBackchannel)
    private const
      CUSTOM_DATE_TUTORIAL_VIDEOS_FOUND          = 'tutorial_videos_found';
      CUSTOM_DATE_TUTORIAL_VIDEO_SEEN_PREFIX     = 'tutorial_video_seen_';
      CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_PREFIX   = 'level_unlock_seen_';
      CUSTOM_DATE_TUTORIAL_DIFFICULTY_UNLOCK_PVE = 'pve_difficulty_unlocked_league';
      CUSTOM_DATE_TUTORIAL_DIFFICULTY_UNLOCK_2VE = '2ve_difficulty_unlocked_league';
      CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_OVERRIDE = 'level_unlocks_override';
      CUSTOM_DATE_DISABLE_BOTS                   = 'bots_disabled';
      CUSTOM_DATE_DISABLE_SCILL_HIGHLIGHT        = 'scill_highlight_disabled';
    private
      FConstants : TProfileConstants;
      FOnExperienceGained : ProcCallback;
      FOnLevelUpReward : ProcLevelUpReward;
      FLatestPatchNotes : TDatetime;
      FCrystalEventTimeSeconds : integer;
      FCrystalTimer : TTimer;
      FPremiumActiveUntil : TDatetime;
      FDeckSlots : integer;
      FAccountCreated : TDatetime;
      FIsStaff : boolean;
      FTutorialVideos : TUltimateObjectList<TTutorialVideo>;
      FCustomData : TJsonObject;
      procedure UpdateFirstWin;
      procedure UpdatePremium;
      procedure LoadProfileData(const ProfileData : RProfileData; const ProfileConstants : RProfileConstants);
      procedure LoadUnlockedIcons(const Icons : TArray<string>);
      procedure LoadTutorialVideos(const TutorialVideoData : ARTutorialVideo);
      procedure SignalExperienceGained;
      procedure StoreCustomDataOnServer;
      function GetHasFoundTutorialVideos : boolean;
      procedure SetHasFoundTutorialVideos(const Value : boolean); virtual;
      function HasTutorialVideoBeenSeen(const Identifier : string) : boolean;
      procedure SetTutorialVideoSeen(const Identifier : string);
      // backchannel
      procedure ReceivedLevelUpReward(Reward : RLootbox; for_Reaching_Level : integer; additional_text : string);
      procedure PlayerLeagueChanged(new_league : integer);
      procedure IconUnlocked(icon_identifier : string);
      procedure PremiumAccountChanged(active_until : TDatetime);
      procedure DeckSlotsIncreased(deck_slots : integer);
      function GetBotsDisabled : boolean;
      procedure SetBotsDisabled(const Value : boolean);
      function GetDisabledLevelUnlocks : boolean;
      procedure SetDisableLevelUnlocks(const Value : boolean); virtual;
      function GetScillHighlightDisabled : boolean; virtual;
      procedure SetScillHighlightDisabled(const Value : boolean); virtual;
    strict private
      function GetHasLevelUnlockSeen : boolean;
      procedure SetHasLevelUnlockSeen(const Value : boolean); virtual;
      function GetUnlocked2vELeague : integer;
      function GetUnlockedPvELeague : integer;
      procedure SetUnlocked2vELeague(const Value : integer); virtual;
      procedure SetUnlockedPvELeague(const Value : integer); virtual;
    strict private
      FLevel, FExperiencePoints : integer;
      FLeague : integer;
      FTutorialPlayed : boolean;
      FNextFirstWin : TDatetime;
      FSecondsUntilFirstWinAvailable, FSecondsUntilPremiumEnds : integer;
      FIsFirstWinAvailable, FIsPremiumActive : boolean;
      FIcon : string;
      FUnlockedIcons : TUltimateList<string>;
      function GetLevelUpExperiencePoints : integer;
      procedure SetPremiumActive(const Value : boolean); virtual;
      procedure SetSecondsUntilPremiumEnds(const Value : integer); virtual;
      procedure SetIcon(const Value : string); virtual;
      procedure SetTutorialPlayed(const Value : boolean); virtual;
      procedure SetExperiencePoints(const Value : integer); virtual;
      procedure SetLevel(const Value : integer); virtual;
      procedure SetLeague(const Value : integer); virtual;
      procedure SetNextFirstWin(const Value : TDatetime); virtual;
      procedure SetSecondsUntilFirstWinAvailable(const Value : integer); virtual;
      procedure SetIsFirstWinAvailable(const Value : boolean); virtual;
      procedure SetLatestPatchNotes(const Value : TDatetime); virtual;
      procedure SetCrystalEventTimeSeconds(const Value : integer); virtual;
      procedure SetPremiumActiveUntil(const Value : TDatetime); virtual;
      procedure SetDeckSlots(const Value : integer); virtual;
      procedure SetAccountCreated(const Value : TDatetime); virtual;
    published
      property LatestPatchNotes : TDatetime read FLatestPatchNotes write SetLatestPatchNotes;
      property CrystalEventTimeSeconds : integer read FCrystalEventTimeSeconds write SetCrystalEventTimeSeconds;

      property Icon : string read FIcon write SetIcon;
      property UnlockedIcons : TUltimateList<string> read FUnlockedIcons;
      property IsStaff : boolean read FIsStaff;

      property HasFoundTutorialVideos : boolean read GetHasFoundTutorialVideos write SetHasFoundTutorialVideos;
      property TutorialVideos : TUltimateObjectList<TTutorialVideo> read FTutorialVideos;

      property BotsDisabled : boolean read GetBotsDisabled write SetBotsDisabled;
      property ScillHighlightDisabled : boolean read GetScillHighlightDisabled write SetScillHighlightDisabled;
      procedure ScillHighlightSeen;

      /// <summary> Returns if the player has already seen the current levels unlock. </summary>
      [dXMLDependency('.Level')]
      property HasLevelUnlockSeen : boolean read GetHasLevelUnlockSeen write SetHasLevelUnlockSeen;
      procedure LevelUnlockSeen(Level : integer);
      property DisableLevelUnlocks : boolean read GetDisabledLevelUnlocks write SetDisableLevelUnlocks;

      property UnlockedPvELeague : integer read GetUnlockedPvELeague write SetUnlockedPvELeague;
      procedure UnlockPvELeague(League : integer);
      property Unlocked2vELeague : integer read GetUnlocked2vELeague write SetUnlocked2vELeague;
      procedure Unlock2vELeague(League : integer);

      /// <summary> Current level of the player. </summary>
      property Level : integer read FLevel write SetLevel;
      /// <summary> Current ExperiencePoints the player has at the current level.</summary>
      property ExperiencePoints : integer read FExperiencePoints write SetExperiencePoints;
      /// <summary> Current league (max league of all cards) of the player. </summary>
      property League : integer read FLeague write SetLeague;
      /// <summary> If false player still have to play the tutorial.</summary>
      property TutorialPlayed : boolean read FTutorialPlayed write SetTutorialPlayed;
      /// <summary> Timestamp when player account was created.</summary>
      property AccountCreated : TDatetime read FAccountCreated write SetAccountCreated;

      property NextFirstWin : TDatetime read FNextFirstWin write SetNextFirstWin;
      /// <summary> Seconds that has to passed, until first win is available.</summary>
      property SecondsUntilFirstWinAvailable : integer read FSecondsUntilFirstWinAvailable write SetSecondsUntilFirstWinAvailable;
      property IsFirstWinAvailable : boolean read FIsFirstWinAvailable write SetIsFirstWinAvailable;

      /// <summary> Timestamp until premium account is active. When timestamp is in past, premium is not active.</summary>
      property PremiumActiveUntil : TDatetime read FPremiumActiveUntil write SetPremiumActiveUntil;
      property IsPremiumActive : boolean read FIsPremiumActive write SetPremiumActive;
      property SecondsUntilPremiumEnds : integer read FSecondsUntilPremiumEnds write SetSecondsUntilPremiumEnds;

      /// <summary> Number of total deck slots player can use to created decks. If deck count >= deckslots, creating new decks will fail.</summary>
      property DeckSlots : integer read FDeckSlots write SetDeckSlots;
      /// <summary> Total Experience Points required until player will levelup.</summary>
      [dXMLDependency('.Level')]
      property LevelUpExperiencePoints : integer read GetLevelUpExperiencePoints;
      [dXMLDependency('.IsMaxLevel', '.ExperiencePoints', '.LevelUpExperiencePoints')]
      function LevelProgress : single;
      [dXMLDependency('.Level')]
      function IsMaxLevel : boolean;
      [dXMLDependency('.Level')]
      function NextLevelUpReward : TLevelUpReward;
    public
      property OnLevelUpReward : ProcLevelUpReward read FOnLevelUpReward write FOnLevelUpReward;
      property OnExperienceGained : ProcCallback read FOnExperienceGained write FOnExperienceGained;
      /// <summary> Constants retrieved from server for player.</summary>
      property Constants : TProfileConstants read FConstants;
      /// <summary> Will gain experience and automatically make a levelup if player has collected enough exp.</summary>
      procedure GainExperience(Amount : integer);
      procedure Idle;
      constructor Create();
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  TUserProfileAction = class(TPromiseAction)
    private
      FUserProfile : TUserProfile;
    public
      property UserProfile : TUserProfile read FUserProfile;
      constructor Create(UserProfile : TUserProfile);
  end;

  [AQCriticalAction]
  TUserProfileActionLoadData = class(TUserProfileAction)
    protected
      FProfileData : RProfileData;
      FProfileConstants : RProfileConstants;
    public
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
      procedure Rollback; override;
  end;

  TUserProfileActionChangeIcon = class(TUserProfileAction)
    private
      FOldIcon, FNewIcon : string;
    public
      constructor Create(UserProfile : TUserProfile; Icon : string);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TUserProfileActionStoreCustomData = class(TUserProfileAction)
    private
      FJsonData : TJsonData;
    public
      constructor Create(UserProfile : TUserProfile; JsonData : TJsonData);
      function Execute : boolean; override;
  end;

  TUserProfileActionLoadPatchNotes = class(TUserProfileAction)
    public
      function Execute : boolean; override;
  end;

  TUserProfileActionLoadCrystalEventTime = class(TUserProfileAction)
    public
      function Execute : boolean; override;
  end;

  TUserProfileActionLoadTutorialVideos = class(TUserProfileAction)
    public
      function Execute : boolean; override;
  end;

  [AQCriticalAction]
  TUserProfileActionLoadUnlockedIcons = class(TUserProfileAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;
  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  UserProfile : TUserProfile;

implementation

{ TUserProfile }

constructor TUserProfile.Create;
begin
  FSecondsUntilFirstWinAvailable := 1000000;
  FSecondsUntilPremiumEnds := -1;
  FUnlockedIcons := TUltimateList<string>.Create;
  FTutorialVideos := TUltimateObjectList<TTutorialVideo>.Create;
  RPCHandlerManager.SubscribeHandler(self);
  MainActionQueue.DoAction(TUserProfileActionLoadData.Create(self));
  MainActionQueue.DoAction(TUserProfileActionLoadPatchNotes.Create(self));
  MainActionQueue.DoAction(TUserProfileActionLoadTutorialVideos.Create(self));
  MainActionQueue.DoAction(TUserProfileActionLoadCrystalEventTime.Create(self));
  MainActionQueue.DoAction(TUserProfileActionLoadUnlockedIcons.Create(self));
  FCrystalTimer := TTimer.CreateAndStart(1000);
end;

procedure TUserProfile.DeckSlotsIncreased(deck_slots : integer);
begin
  assert(DeckSlots < deck_slots);
  DeckSlots := deck_slots;
end;

destructor TUserProfile.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  FConstants.Free;
  FCrystalTimer.Free;
  FUnlockedIcons.Free;
  FTutorialVideos.Free;
  FCustomData.Free;
  inherited;
end;

procedure TUserProfile.GainExperience(Amount : integer);
begin
  if Constants.PlayerMaxLevel > Level then
  begin
    ExperiencePoints := ExperiencePoints + Amount;
    // do levelup if player has earned enough exp
    while ExperiencePoints >= LevelUpExperiencePoints do
    begin
      ExperiencePoints := ExperiencePoints - LevelUpExperiencePoints;
      assert(ExperiencePoints >= 0);
      // levelup after subtract experience points, else increased Level would influence LevelUpExperiencePoints
      Level := Level + 1;
      if Constants.PlayerMaxLevel <= Level then
      begin
        ExperiencePoints := 0;
        break;
      end;
    end;
    SignalExperienceGained;
  end;
end;

function TUserProfile.GetBotsDisabled : boolean;
begin
  Result := FCustomData.Booleans[CUSTOM_DATE_DISABLE_BOTS];
end;

function TUserProfile.GetDisabledLevelUnlocks : boolean;
begin
  Result := FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_OVERRIDE];
end;

function TUserProfile.GetHasFoundTutorialVideos : boolean;
begin
  Result := FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_VIDEOS_FOUND];
end;

function TUserProfile.GetHasLevelUnlockSeen : boolean;
begin
  Result := FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_PREFIX + self.Level.ToString];
end;

function TUserProfile.GetLevelUpExperiencePoints : integer;
begin
  if assigned(Constants) then
      Result := Constants.PlayerLevelTable[Level]
  else
      Result := -1;
end;

function TUserProfile.GetScillHighlightDisabled : boolean;
begin
  Result := FCustomData.Booleans[CUSTOM_DATE_DISABLE_SCILL_HIGHLIGHT];
end;

function TUserProfile.GetUnlocked2vELeague : integer;
begin
  Result := Max(MIN_LEAGUE, Min(MAX_LEAGUE, FCustomData.Integers[CUSTOM_DATE_TUTORIAL_DIFFICULTY_UNLOCK_2VE]));
end;

function TUserProfile.GetUnlockedPvELeague : integer;
begin
  Result := Max(MIN_LEAGUE, Min(MAX_LEAGUE, FCustomData.Integers[CUSTOM_DATE_TUTORIAL_DIFFICULTY_UNLOCK_PVE]));
end;

function TUserProfile.HasTutorialVideoBeenSeen(const Identifier : string) : boolean;
begin
  Result := FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_VIDEO_SEEN_PREFIX + Identifier];
end;

procedure TUserProfile.IconUnlocked(icon_identifier : string);
begin
  if not FUnlockedIcons.IndexOf(icon_identifier) >= 0 then
      FUnlockedIcons.Add(icon_identifier);
end;

procedure TUserProfile.Idle;
begin
  UpdateFirstWin;
  UpdatePremium;
  if FCrystalTimer.Expired then
  begin
    CrystalEventTimeSeconds := CrystalEventTimeSeconds - 1;
    FCrystalTimer.StartWithRest;
  end;
end;

function TUserProfile.IsMaxLevel : boolean;
begin
  if assigned(Constants) then
      Result := Level >= Constants.PlayerMaxLevel
  else
      Result := False;
end;

function TUserProfile.LevelProgress : single;
begin
  if IsMaxLevel then Result := 0
  else if LevelUpExperiencePoints <= 0 then Result := 0
  else Result := ExperiencePoints / LevelUpExperiencePoints;
end;

procedure TUserProfile.LevelUnlockSeen(Level : integer);
begin
  if (self.Level = Level) and not HasLevelUnlockSeen then
      HasLevelUnlockSeen := True;
end;

procedure TUserProfile.LoadProfileData(const ProfileData : RProfileData; const ProfileConstants : RProfileConstants);
begin
  FConstants := TProfileConstants.Create(ProfileConstants);
  FIsStaff := ProfileData.is_staff;
  Level := ProfileData.Level;
  League := ProfileData.League;
  ExperiencePoints := ProfileData.experience_points;
  TutorialPlayed := ProfileData.starterdeck_chosen;
  NextFirstWin := ProfileData.next_first_win_available;
  PremiumActiveUntil := ProfileData.premium_active_until;
  AccountCreated := ProfileData.account_created;
  DeckSlots := ProfileData.deck_slots;
  Icon := ProfileData.Icon;
  Account.Own.Icon := Icon;
  FCustomData := ProfileData.custom_data.AsObject;
end;

procedure TUserProfile.LoadTutorialVideos(const TutorialVideoData : ARTutorialVideo);
var
  Query : IDataQuery<RTutorialVideo>;
  Videos : TList<TTutorialVideo>;
  VideoData : RTutorialVideo;
begin
  Query := TDelphiDataQuery<RTutorialVideo>.CreateInterface(TutorialVideoData);
  Videos := TList<TTutorialVideo>.Create();
  for VideoData in Query.OrderBy('order_value') do
      Videos.Add(TTutorialVideo.Create(self, VideoData));
  TutorialVideos.AddRange(Videos);
  Videos.Free;
end;

procedure TUserProfile.LoadUnlockedIcons(const Icons : TArray<string>);
begin
  FUnlockedIcons.AddRange(Icons);
end;

function TUserProfile.NextLevelUpReward : TLevelUpReward;
begin
  if not assigned(FConstants) or not FConstants.PlayerLevelUpRewards.TryGetValue(Level + 1, Result) then Result := nil;
end;

procedure TUserProfile.PlayerLeagueChanged(new_league : integer);
begin
  League := new_league;
end;

procedure TUserProfile.PremiumAccountChanged(active_until : TDatetime);
begin
  PremiumActiveUntil := active_until;
end;

procedure TUserProfile.ReceivedLevelUpReward(Reward : RLootbox; for_Reaching_Level : integer; additional_text : string);
var
  Lootbox : TLootbox;
begin
  Lootbox := TLootbox.Create(Reward);
  Shop.Inventory.Add(Lootbox);
  if assigned(OnLevelUpReward) then
      OnLevelUpReward(Lootbox, for_Reaching_Level, additional_text);
end;

procedure TUserProfile.ScillHighlightSeen;
begin
  self.ScillHighlightDisabled := True;
end;

procedure TUserProfile.SetAccountCreated(const Value : TDatetime);
begin
  FAccountCreated := Value;
end;

procedure TUserProfile.SetBotsDisabled(const Value : boolean);
begin
  if Value <> FCustomData.Booleans[CUSTOM_DATE_DISABLE_BOTS] then
  begin
    FCustomData.Booleans[CUSTOM_DATE_DISABLE_BOTS] := Value;
    StoreCustomDataOnServer;
  end;
end;

procedure TUserProfile.SetCrystalEventTimeSeconds(const Value : integer);
begin
  FCrystalEventTimeSeconds := Value;
end;

procedure TUserProfile.SetDeckSlots(const Value : integer);
begin
  FDeckSlots := Value;
end;

procedure TUserProfile.SetDisableLevelUnlocks(const Value : boolean);
begin
  if not FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_OVERRIDE] then
  begin
    FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_OVERRIDE] := True;
    StoreCustomDataOnServer;
  end;
end;

procedure TUserProfile.SetExperiencePoints(const Value : integer);
begin
  FExperiencePoints := Value;
end;

procedure TUserProfile.SetHasFoundTutorialVideos(const Value : boolean);
begin
  if not FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_VIDEOS_FOUND] then
  begin
    FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_VIDEOS_FOUND] := True;
    StoreCustomDataOnServer;
  end;
end;

procedure TUserProfile.SetHasLevelUnlockSeen(const Value : boolean);
begin
  if not FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_PREFIX + self.Level.ToString] then
  begin
    FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_LEVEL_UNLOCK_PREFIX + self.Level.ToString] := True;
    StoreCustomDataOnServer;
  end;
end;

procedure TUserProfile.SetIcon(const Value : string);
begin
  if MainActionQueue.IsActive then
      FIcon := Value
  else
      MainActionQueue.DoAction(TUserProfileActionChangeIcon.Create(self, Value));
end;

procedure TUserProfile.SetIsFirstWinAvailable(const Value : boolean);
begin
  FIsFirstWinAvailable := Value;
end;

procedure TUserProfile.SetLatestPatchNotes(const Value : TDatetime);
begin
  FLatestPatchNotes := Value;
end;

procedure TUserProfile.SetLeague(const Value : integer);
begin
  FLeague := Value;
end;

procedure TUserProfile.SetLevel(const Value : integer);
begin
  FLevel := Value;
end;

procedure TUserProfile.SetNextFirstWin(const Value : TDatetime);
begin
  FNextFirstWin := Value;
  UpdateFirstWin;
end;

procedure TUserProfile.SetPremiumActive(const Value : boolean);
begin
  FIsPremiumActive := Value;
end;

procedure TUserProfile.SetPremiumActiveUntil(const Value : TDatetime);
begin
  FPremiumActiveUntil := Value;
end;

procedure TUserProfile.SetSecondsUntilPremiumEnds(const Value : integer);
begin
  FSecondsUntilPremiumEnds := Value;
end;

procedure TUserProfile.SetScillHighlightDisabled(const Value : boolean);
begin
  if Value <> FCustomData.Booleans[CUSTOM_DATE_DISABLE_SCILL_HIGHLIGHT] then
  begin
    FCustomData.Booleans[CUSTOM_DATE_DISABLE_SCILL_HIGHLIGHT] := Value;
    StoreCustomDataOnServer;
  end;
end;

procedure TUserProfile.SetSecondsUntilFirstWinAvailable(const Value : integer);
begin
  FSecondsUntilFirstWinAvailable := Value;
end;

procedure TUserProfile.SetTutorialPlayed(const Value : boolean);
begin
  FTutorialPlayed := Value;
end;

procedure TUserProfile.SetTutorialVideoSeen(const Identifier : string);
begin
  FCustomData.Booleans[CUSTOM_DATE_TUTORIAL_VIDEO_SEEN_PREFIX + Identifier] := True;
  StoreCustomDataOnServer;
end;

procedure TUserProfile.SetUnlocked2vELeague(const Value : integer);
begin
  FCustomData.Integers[CUSTOM_DATE_TUTORIAL_DIFFICULTY_UNLOCK_2VE] := Max(MIN_LEAGUE, Min(MAX_LEAGUE, Value));
  StoreCustomDataOnServer;
end;

procedure TUserProfile.SetUnlockedPvELeague(const Value : integer);
begin
  FCustomData.Integers[CUSTOM_DATE_TUTORIAL_DIFFICULTY_UNLOCK_PVE] := Max(MIN_LEAGUE, Min(MAX_LEAGUE, Value));
  StoreCustomDataOnServer;
end;

procedure TUserProfile.SignalExperienceGained;
begin
  if assigned(OnExperienceGained) then OnExperienceGained();
end;

procedure TUserProfile.StoreCustomDataOnServer;
begin
  MainActionQueue.DoAction(TUserProfileActionStoreCustomData.Create(self, FCustomData.Clone));
end;

procedure TUserProfile.Unlock2vELeague(League : integer);
begin
  if (League <= MAX_LEAGUE) and (Unlocked2vELeague < League) then
      Unlocked2vELeague := League;
end;

procedure TUserProfile.UnlockPvELeague(League : integer);
begin
  if (League <= MAX_LEAGUE) and (UnlockedPvELeague < League) then
      UnlockedPvELeague := League;
end;

procedure TUserProfile.UpdateFirstWin;
var
  NewSecondsUntilFirstWin : integer;
begin
  if Account.Servertime < NextFirstWin then
      NewSecondsUntilFirstWin := SecondsBetween(Account.Servertime, NextFirstWin)
  else
      NewSecondsUntilFirstWin := 0;
  // only set values if changed
  if NewSecondsUntilFirstWin <> SecondsUntilFirstWinAvailable then
  begin
    SecondsUntilFirstWinAvailable := NewSecondsUntilFirstWin;
    IsFirstWinAvailable := SecondsUntilFirstWinAvailable <= 0;
  end;
end;

procedure TUserProfile.UpdatePremium;
var
  NewSecondsUntilPremiumEnds : integer;
begin
  if Account.Servertime < PremiumActiveUntil then
      NewSecondsUntilPremiumEnds := SecondsBetween(Account.Servertime, PremiumActiveUntil)
  else
      NewSecondsUntilPremiumEnds := 0;
  // only set values if changed
  if NewSecondsUntilPremiumEnds <> SecondsUntilPremiumEnds then
  begin
    SecondsUntilPremiumEnds := NewSecondsUntilPremiumEnds;
    IsPremiumActive := SecondsUntilPremiumEnds > 0;
  end;
end;

{ TProfileConstants }

constructor TProfileConstants.Create(const Data : RProfileConstants);
var
  Entry : RApiTableEntry;
  LevelRewardData : RLevelUpReward;
  Reward : TLevelUpReward;
begin
  FPlayerMaxLevel := Data.player_max_level;
  FPlayerLevelTable := TDictionary<integer, integer>.Create();
  FPlayerLevelUpRewards := TObjectDictionary<integer, TLevelUpReward>.Create([doOwnsValues]);
  FPlayerLevelUpRewardList := TList<TLevelUpReward>.Create(
    TComparer<TLevelUpReward>.Construct(
    function(const L, R : TLevelUpReward) : integer
    begin
      Result := L.Level - R.Level;
    end
    )
    );
  for Entry in Data.player_level_table do
      FPlayerLevelTable.Add(Entry.key, Entry.Value);
  for LevelRewardData in Data.player_level_reward do
  begin
    Reward := TLevelUpReward.Create(LevelRewardData);
    FPlayerLevelUpRewards.Add(LevelRewardData.reaching_level, Reward);
    FPlayerLevelUpRewardList.Add(Reward);
  end;
  FPlayerLevelUpRewardList.Sort;
end;

destructor TProfileConstants.Destroy;
begin
  FPlayerLevelUpRewardList.Free;
  FPlayerLevelTable.Free;
  FPlayerLevelUpRewards.Free;
  inherited;
end;

{ TUserProfileAction }

constructor TUserProfileAction.Create(UserProfile : TUserProfile);
begin
  inherited Create();
  FUserProfile := UserProfile;
end;

{ TUserProfileActionLoadData }

function TUserProfileActionLoadData.Execute : boolean;
var
  promiseData : TPromise<RProfileData>;
  promiseConstants : TPromise<RProfileConstants>;
begin
  promiseData := AccountAPI.GetProfileData;
  promiseConstants := AccountAPI.GetProfileConstants;
  promiseData.WaitForData;
  promiseConstants.WaitForData;
  if TPromise.CheckPromisesWereSuccessfull([promiseData, promiseConstants], FErrorMsg) then
  begin
    FProfileData := promiseData.Value;
    FProfileConstants := promiseConstants.Value;
    Result := True;
  end
  else
      Result := False;
  promiseData.Free;
  promiseConstants.Free;
end;

function TUserProfileActionLoadData.ExecuteSynchronized : boolean;
begin
  Result := True;
  UserProfile.LoadProfileData(FProfileData, FProfileConstants);
end;

procedure TUserProfileActionLoadData.Rollback;
begin
  FreeAndNil(UserProfile.FConstants);
end;

{ TUserProfileActionChangeIcon }

constructor TUserProfileActionChangeIcon.Create(UserProfile : TUserProfile; Icon : string);
begin
  inherited Create(UserProfile);
  FNewIcon := Icon;
end;

procedure TUserProfileActionChangeIcon.Emulate;
begin
  FOldIcon := UserProfile.Icon;
  UserProfile.Icon := FNewIcon;
  Account.Own.Icon := FNewIcon;
end;

function TUserProfileActionChangeIcon.Execute : boolean;
begin
  Result := HandlePromise(AccountAPI.ChangeIcon(FNewIcon));
end;

procedure TUserProfileActionChangeIcon.Rollback;
begin
  UserProfile.Icon := FOldIcon;
  Account.Own.Icon := FOldIcon;
end;

{ TUserProfileActionLoadPatchNotes }

function TUserProfileActionLoadPatchNotes.Execute : boolean;
var
  promise : TPromise<RPatchNotes>;
begin
  promise := AccountAPI.GetLatestPatchNotes();
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        UserProfile.LatestPatchNotes := promise.Value.timestamp;
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

{ TUserProfileActionLoadCrystalEventTime }

function TUserProfileActionLoadCrystalEventTime.Execute : boolean;
var
  promise : TPromise<RCrystalEventTime>;
begin
  promise := AccountAPI.GetCrystalEventTime();
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        UserProfile.CrystalEventTimeSeconds := promise.Value.time_to_event;
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

{ TUserProfileActionLoadUnlockedIcons }

function TUserProfileActionLoadUnlockedIcons.Execute : boolean;
var
  promise : TPromise<TArray<string>>;
begin
  promise := AccountAPI.GetUnlockedIconIdentifiers();
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        UserProfile.LoadUnlockedIcons(promise.Value);
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TUserProfileActionLoadUnlockedIcons.Rollback;
begin
end;

{ TLevelUpReward }

constructor TLevelUpReward.Create(const Data : RLevelUpReward);
const
  REWARD_ORDER : array [EnumShopItemType] of integer = (
    0, // itInvalid,
  1,   // itPremiumTime,
  2,   // itSkin,
  3,   // itCard,
  4,   // itDraftbox,
  5,   // itLootbox,
  -1,  // itIcon,
  7,   // itDeckSlot,
  8,   // itLootList,
  -3,  // itCredits,
  -2,  // itDiamonds,
  11,  // itCurrency,
  12,  // itPlayerXP,
  13,  // itRandomCard,
  14   // itDisenchantedCard
    );
begin
  FLevel := Data.reaching_level;
  FLoot := TLootList.Create(Data.Reward);
  FLoot.Content.Sort(
    TComparer<TLootboxContent>.Construct(
    function(const L, R : TLootboxContent) : integer
    begin
      Result := ord(REWARD_ORDER[L.ShopItem.ItemType]) - ord(REWARD_ORDER[R.ShopItem.ItemType]);
    end
    ));
  FAdditionalText := Data.additional_text;
end;

destructor TLevelUpReward.Destroy;
begin
  FLoot.Free;
  inherited;
end;

function TLevelUpReward.HasText : boolean;
begin
  Result := AdditionalText <> '';
end;

{ TUserProfileActionStoreCustomData }

constructor TUserProfileActionStoreCustomData.Create(UserProfile : TUserProfile; JsonData : TJsonData);
begin
  inherited Create(UserProfile);
  FJsonData := JsonData;
end;

function TUserProfileActionStoreCustomData.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := AccountAPI.StoreCustomData(FJsonData);
  Result := HandlePromise(promise);
end;

{ TTutorialVideo }

constructor TTutorialVideo.Create(Profile : TUserProfile; const Data : RTutorialVideo);
begin
  FProfile := Profile;
  FId := Data.ID;
  FTitle := Data.Title;
  FIdentifier := Data.Identifier;
  FUrl := Data.Url;
  FOrderValue := Data.order_value;
  Seen := Profile.HasTutorialVideoBeenSeen(Identifier);
end;

procedure TTutorialVideo.Play;
begin
  HSystem.OpenUrlInBrowser(Url);
  Seen := True;
  FProfile.SetTutorialVideoSeen(Identifier);
end;

procedure TTutorialVideo.SetSeen(const Value : boolean);
begin
  FSeen := Value;
end;

{ TUserProfileActionLoadTutorialVideos }

function TUserProfileActionLoadTutorialVideos.Execute : boolean;
var
  promise : TPromise<ARTutorialVideo>;
begin
  promise := AccountAPI.GetTutorialVideos();
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        UserProfile.LoadTutorialVideos(promise.Value);
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

end.
