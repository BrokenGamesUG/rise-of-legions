unit BaseConflict.Api.Game;

interface

uses
  // ===== Delphi ==========
  System.SysUtils,
  Generics.Defaults,
  Math,
  // ===== Engine ==========
  Engine.dXML,
  Engine.Math,
  Engine.Network.RPC,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.DataQuery,
  // ===== Game ==========
  BaseConflict.Api,
  BaseConflict.Api.Account,
  BaseConflict.Api.Types,
  BaseConflict.Api.Cards,
  BaseConflict.Api.Shop,
  BaseConflict.Api.Scenarios,
  BaseConflict.Constants.Cards;

type

  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic, vcPrivate]) FIELDS([vcPublic, vcProtected]) PROPERTIES([vcPublic, vcPublished])}
  {$M+}
  TGameMetaInfoStatisticsPlayer = class
    strict private
      FPlayer : TPerson;
      FTeamID : integer;
      FRanking : integer;
      FCards : TUltimateList<TCardInfo>;
    published
      property Player : TPerson read FPlayer;
      property Cards : TUltimateList<TCardInfo> read FCards;
      property TeamID : integer read FTeamID;
      /// <summary> Ranking of player for scenario. Will be -1 when scenario was unranked.</summary>
      property Ranking : integer read FRanking;
    public
      constructor Create(const Data : RClientGameStatisticPlayer);
      destructor Destroy; override;
  end;

  TGameMetaInfoStatistics = class
    strict private
      FDuration, FCurrentUserTeamID : integer;
      FTeamBlue, FTeamRed : TUltimateObjectList<TGameMetaInfoStatisticsPlayer>;
    published
      property Duration : integer read FDuration;
      property CurrentUserTeamID : integer read FCurrentUserTeamID;
      property TeamBlue : TUltimateObjectList<TGameMetaInfoStatisticsPlayer> read FTeamBlue;
      property TeamRed : TUltimateObjectList<TGameMetaInfoStatisticsPlayer> read FTeamRed;
    public
      constructor Create(Data : RClientGameFinishedStatistics);
      destructor Destroy; override;
  end;

  TCardInstanceWithRewards = class
    strict private
      FExperienceBefore, FExperienceGained, FExperienceGainedPremium : integer;
      FUpgradePointsBefore, FUpgradePointsGained : integer;
      FDailyRewardUsed, FPremiumApplied : boolean;
      FCardInstance : TCardInstance;
      FCardSkin : TCardSkin;
      FCardStateAfterRewards, FHasAscension : boolean;
      procedure SetExperienceGainedPremium(const Value : integer); virtual;
      procedure SetHasAscension(const Value : boolean); virtual;
      procedure SetExperienceGained(const Value : integer); virtual;
      procedure SetDailyRewardUsed(const Value : boolean); virtual;
      procedure SetUpgradePointsGained(const Value : integer); virtual;
    published
      property PremiumApplied : boolean read FPremiumApplied;
      property CardInstance : TCardInstance read FCardInstance;
      property CardSkin : TCardSkin read FCardSkin;
      property HasAscension : boolean read FHasAscension write SetHasAscension;
      [dxmlDependency('.CardInstance.ExperiencePoints')]
      function ExperienceBefore : integer;
      property ExperienceGained : integer read FExperienceGained write SetExperienceGained;
      property ExperienceGainedPremium : integer read FExperienceGainedPremium write SetExperienceGainedPremium;
      [dxmlDependency('.ExperienceBefore')]
      function LevelProgressBefore : single;
      [dxmlDependency('.ExperienceBefore', '.ExperienceGained')]
      function LevelProgressAfter : single;
      [dxmlDependency('.ExperienceBefore', '.ExperienceGained', '.ExperienceGainedPremium')]
      function LevelProgressAfterPremium : single;
      [dxmlDependency('.ExperienceBefore')]
      function LevelBefore : integer;
      [dxmlDependency('.ExperienceBefore', '.ExperienceGained')]
      function LevelAfter : integer;
      [dxmlDependency('.LevelAfter')]
      function IsMaxLeveLAfter : boolean;
      [dxmlDependency('.LevelBefore', '.LevelAfter')]
      function LevelUp : boolean;
      property DailyRewardUsed : boolean read FDailyRewardUsed write SetDailyRewardUsed;
      [dxmlDependency('.LevelBefore')]
      function CardInfoBefore : TCardInfo;
      [dxmlDependency('.LevelAfter', '.HasAscension')]
      function CardInfoAfter : TCardInfo;

      [dxmlDependency('.CardInstance.CurrentUpgradePoints')]
      function UpgradePointsBefore : integer;
      property UpgradePointsGained : integer read FUpgradePointsGained write SetUpgradePointsGained;
      [dxmlDependency('.UpgradePointsBefore')]
      function UpgradeProgressBefore : single;
      [dxmlDependency('.UpgradePointsBefore', '.UpgradePointsGained')]
      function UpgradeProgressAfter : single;
    public
      constructor Create(const CardData : RGameCardReward); overload;
      constructor Create(const Card : TCardInstance); overload;
  end;

  TGameMetaInfoRewards = class
    strict private
      FCardWithRewards : TUltimateObjectList<TCardInstanceWithRewards>;
      FPremiumApplied : boolean;
      FGold, FGoldPremium : integer;
      FExperience, FExperiencePremium : integer;
      FLevelProgressBefore, FLevelProgress, FLevelProgressAfterPremium : single;
      FLevelBefore, FStarsAfter, FRankingAfter, FStarsBefore, FRankingBefore, FMaxStarsAtRank, FStarsChange : integer;
      procedure SetPremiumApplied(const Value : boolean); virtual;
    published
      property PremiumApplied : boolean read FPremiumApplied write SetPremiumApplied;
      property LevelBefore : integer read FLevelBefore;
      property Experience : integer read FExperience;
      property ExperiencePremium : integer read FExperiencePremium;
      property LevelProgressBefore : single read FLevelProgressBefore;
      property LevelProgress : single read FLevelProgress;
      property LevelProgressAfterPremium : single read FLevelProgressAfterPremium;
      property Gold : integer read FGold;
      property GoldPremium : integer read FGoldPremium;
      // Card experience per card
      property CardWithRewards : TUltimateObjectList<TCardInstanceWithRewards> read FCardWithRewards;
      // rankings
      property RankingBefore : integer read FRankingBefore;
      property RankingAfter : integer read FRankingAfter;
      /// <summary> Amount of stars gained (+) or lost (-) </summary>
      property StarsChange : integer read FStarsChange;
      property StarsBefore : integer read FStarsBefore;
      property StarsAfter : integer read FStarsAfter;
      property MaxStarsAtRank : integer read FMaxStarsAtRank;
    public
      constructor Create(const Data : RGameFinishedRewards; const NewRankingData : RMatchmakingRanking);
      destructor Destroy; override;
  end;

  TGameMetaInfo = class
    private
      FData : RGameFoundData;
      FCancelLoadingAfterGameData : TThreadSafeData<boolean>;
      FOnReady : ProcOfObject;
      procedure LoadData(const Data : RGameFinishedData);
    strict private
      FScenarioInstance : TScenarioInstance;
      FRewards : TGameMetaInfoRewards;
      FIsLoading, FCrashed : boolean;
      FGainedLoot : TLootbox;
      FGainedDraftBox : TDraftBox;
      FStatistics : TGameMetaInfoStatistics;
      FWon : boolean;
      FFirstWinUsed : boolean;
      FAborted : boolean;
      FSpectator : boolean;
      procedure SetSpectator(const Value : boolean); virtual;
      procedure SetAborted(const Value : boolean); virtual;
      procedure SetGainedDraftBox(const Value : TDraftBox); virtual;
      procedure SetGainedLoot(const Value : TLootbox); virtual;
      procedure SetRewards(const Value : TGameMetaInfoRewards); virtual;
      procedure SetStatistics(const Value : TGameMetaInfoStatistics); virtual;
      procedure SetCrashed(const Value : boolean); virtual;
      procedure SetIsLoading(const Value : boolean); virtual;
      procedure SetWon(const Value : boolean); virtual;
      procedure SetFirstWinUsed(const Value : boolean); virtual;
    published
      property ScenarioInstance : TScenarioInstance read FScenarioInstance;
      property IsLoading : boolean read FIsLoading write SetIsLoading;
      /// <summary> If True, the game has not ended properly and the gameserver has crashed while serving the game.
      /// If this happens, the client should display a apologize.
      /// CAUTION: If Crashed is True, no loot and statistic data will be available for player (both will be nil).</summary>
      property Crashed : boolean read FCrashed write SetCrashed;
      property Aborted : boolean read FAborted write SetAborted;
      /// <summary> Determines whether this player only spectated this game. </summary>
      property Spectator : boolean read FSpectator write SetSpectator;
      /// <summary> All gained rewards for the current user from this game. </summary>
      property Rewards : TGameMetaInfoRewards read FRewards write SetRewards;
      /// <summary> Containing the gained loot of the game after the game is finished. Data needed to be loaded with
      /// LoadAfterGameData. Property is nil until after game data is loaded.</summary>
      property GainedLoot : TLootbox read FGainedLoot write SetGainedLoot;
      /// <summary> Containing the gained loot of the game after the game is finished. Data needed to be loaded with
      /// LoadAfterGameData. Property is nil until after game data is loaded.</summary>
      property GainedDraftBox : TDraftBox read FGainedDraftBox write SetGainedDraftBox;
      /// <summary> Containing the statistics of the game after the game is finished. Data needed to be loaded with
      /// LoadAfterGameData. Property is nil until after game data is loaded.</summary>
      property Statistics : TGameMetaInfoStatistics read FStatistics write SetStatistics;
      /// <summary> True if player has won the game else false. Will also false if player surrender or on chrash.</summary>
      property Won : boolean read FWon write SetWon;
      /// <summary> True if firstwin was consumed by this game to increase XP and gold income.</summary>
      property FirstWinUsed : boolean read FFirstWinUsed write SetFirstWinUsed;
    public
      property OnReady : ProcOfObject read FOnReady write FOnReady;
      property Data : RGameFoundData read FData write FData;
      constructor Create(const Data : RGameFoundData);
      constructor CreateSpectator(Data : RGameFoundData);
      /// <summary> Has to be called after the game is finished. Will load infos like statisticdata about the game
      /// and the loot gained. This will loop until data received to handle that server has not receive game has ended signal
      /// from gameserver. To stop try loading data, use CancelLoadingAfterGameData.
      /// CAUTION: Always call CancelLoadingAfterGameData after when leaving where normally the TGameMetaInfo will been shown,
      /// because else the loop LoadAfterGameData would block all other actions.</summary>
      procedure LoadAfterGameData;
      procedure CancelLoadingAfterGameData();
      destructor Destroy; override;
  end;

  TGameMetaInfoActionLoadAfterGameData = class(TPromiseAction)
    private
      FGameMetaInfo : TGameMetaInfo;
    public
      constructor Create(GameMetaInfo : TGameMetaInfo);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Finished; override;
  end;

  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}


implementation

uses
  // BaseConflict.Api.Account,
  BaseConflict.Api.Profile,
  BaseConflict.Api.Matchmaking;

{ TGameMetaInfoActionLoadAfterGameData }

constructor TGameMetaInfoActionLoadAfterGameData.Create(GameMetaInfo : TGameMetaInfo);
begin
  inherited Create;
  FGameMetaInfo := GameMetaInfo;
end;

procedure TGameMetaInfoActionLoadAfterGameData.Emulate;
begin
  FGameMetaInfo.IsLoading := True;
end;

function TGameMetaInfoActionLoadAfterGameData.Execute : boolean;
var
  promise : TPromise<RGameFinishedData>;
  error_code : integer;
  cancel : boolean;
begin
  promise := nil;
  cancel := False;
  while not cancel do
  begin
    promise.Free;
    promise := GameManagerAPI.GetGameFinishedData(FGameMetaInfo.FData.game_uid);
    promise.WaitForData;
    if promise.WasSuccessful then
    begin
      DoSynchronized(
        procedure()
        begin
          FGameMetaInfo.LoadData(promise.Value);
        end);
      cancel := True;
    end
    else
      // on error "game not finished" try again until data received or user cancel trying
      if TryStrToInt(promise.ErrorMessage, error_code) and (EnumErrorCode(error_code) = ecGameNotFinished) then
      begin
        // stop user trying to get data? -> cancel
        if FGameMetaInfo.FCancelLoadingAfterGameData.GetDataSafe then
            cancel := True
        else
          // sleep for 500ms, to avaoid extrem polling of manage server
            sleep(500);
      end
      else
      begin
        HandlePromiseError(promise);
        cancel := True;
      end;
  end;
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TGameMetaInfoActionLoadAfterGameData.Finished;
begin
  FGameMetaInfo.IsLoading := False;
end;

{ TGameMetaInfoStatistics }

constructor TGameMetaInfoStatistics.Create(Data : RClientGameFinishedStatistics);
var
  player_data : RClientGameStatisticPlayer;
  Player : TGameMetaInfoStatisticsPlayer;
begin
  FDuration := Data.Duration;
  FTeamBlue := TUltimateObjectList<TGameMetaInfoStatisticsPlayer>.Create;
  FTeamRed := TUltimateObjectList<TGameMetaInfoStatisticsPlayer>.Create;
  for player_data in Data.players do
  begin
    Player := TGameMetaInfoStatisticsPlayer.Create(player_data);
    if player_data.team_id = 1 then
        FTeamBlue.Add(Player)
    else if player_data.team_id = 2 then
        FTeamRed.Add(Player);
    if Player.Player.IsCurrentUser then FCurrentUserTeamID := Player.TeamID;
  end;
end;

destructor TGameMetaInfoStatistics.Destroy;
begin
  FTeamBlue.Free;
  FTeamRed.Free;
  inherited;
end;

{ TGameMetaInfo }

procedure TGameMetaInfo.CancelLoadingAfterGameData;
begin
  FCancelLoadingAfterGameData.SetDataSafe(True);
end;

constructor TGameMetaInfo.Create(const Data : RGameFoundData);
begin
  FScenarioInstance := ScenarioManager.Scenarios.Query.Get(F('UID') = Data.scenario_uid).LevelsOfDifficulty.Query.Get(F('ID') = Data.scenario_instance_id);
  FData := Data;
  if Data.secret_key = '' then
      Spectator := True;
  // FScenarioInstance := MatchmakingManager.Scenarios.Query
  FCancelLoadingAfterGameData := TThreadSafeData<boolean>.Create(False);
end;

constructor TGameMetaInfo.CreateSpectator(Data : RGameFoundData);
begin
  Data.secret_key := '';
  Create(Data);
end;

destructor TGameMetaInfo.Destroy;
begin
  FCancelLoadingAfterGameData.Free;
  FStatistics.Free;
  FGainedLoot.Free;
  FRewards.Free;
  inherited;
end;

procedure TGameMetaInfo.LoadAfterGameData();
begin
  if not Spectator then
      MainActionQueue.DoAction(TGameMetaInfoActionLoadAfterGameData.Create(self));
end;

procedure TGameMetaInfo.LoadData(const Data : RGameFinishedData);
begin
  if Data.Rewards.loot.id > 0 then
      GainedLoot := TLootbox.Create(Data.Rewards.loot);
  if Data.Rewards.draftbox.id > 0 then
      GainedDraftBox := TDraftBox.Create(Data.Rewards.draftbox);
  Statistics := TGameMetaInfoStatistics.Create(Data.statistic_data);
  Rewards := TGameMetaInfoRewards.Create(Data.Rewards, Data.new_ranking);
  Crashed := Data.Crashed;
  Won := Data.has_won;
  FirstWinUsed := Data.first_win_used;
  if FirstWinUsed then
      UserProfile.NextFirstWin := Data.next_first_win;
  IsLoading := False;
  if assigned(FOnReady) then FOnReady();
end;

procedure TGameMetaInfo.SetAborted(const Value : boolean);
begin
  FAborted := Value;
end;

procedure TGameMetaInfo.SetCrashed(const Value : boolean);
begin
  FCrashed := Value;
end;

procedure TGameMetaInfo.SetFirstWinUsed(const Value : boolean);
begin
  FFirstWinUsed := Value;
end;

procedure TGameMetaInfo.SetGainedDraftBox(const Value : TDraftBox);
begin
  FGainedDraftBox := Value;
end;

procedure TGameMetaInfo.SetGainedLoot(const Value : TLootbox);
begin
  FGainedLoot := Value;
end;

procedure TGameMetaInfo.SetIsLoading(const Value : boolean);
begin
  FIsLoading := Value;
end;

procedure TGameMetaInfo.SetRewards(const Value : TGameMetaInfoRewards);
begin
  FRewards := Value;
end;

procedure TGameMetaInfo.SetSpectator(const Value : boolean);
begin
  FSpectator := Value;
end;

procedure TGameMetaInfo.SetStatistics(const Value : TGameMetaInfoStatistics);
begin
  FStatistics := Value;
end;

procedure TGameMetaInfo.SetWon(const Value : boolean);
begin
  FWon := Value;
end;

{ TCardInstanceWithRewards }

constructor TCardInstanceWithRewards.Create(const CardData : RGameCardReward);
begin
  FCardInstance := CardManager.PlayerCards.Query.Get(F('ID') = CardData.card_instance_id);
  FCardSkin := FCardInstance.OriginCard.Skins.Query.Get(F('ID') = CardData.card_skin_id, True);

  DailyRewardUsed := CardData.daily_reward_used;
  FExperienceBefore := CardData.experience_points_before_game;
  FExperienceGained := CardData.experience_points_gained;
  FExperienceGainedPremium := CardData.experience_premium;
  FCardStateAfterRewards := True;
  FPremiumApplied := CardData.has_premium;
end;

function TCardInstanceWithRewards.CardInfoAfter : TCardInfo;
var
  League, Level : integer;
  UID : string;
begin
  League := FCardInstance.League;
  Level := LevelAfter;
  if FCardInstance.IsLeagueUpgradable then
  begin
    League := League + 1;
    Level := 1;
  end;
  if assigned(CardSkin) then
      UID := FCardSkin.CardInfo.UID
  else
      UID := FCardInstance.CardInfo.UID;
  Result := CardInfoManager.ResolveCardUID(UID, League, Level);
end;

function TCardInstanceWithRewards.CardInfoBefore : TCardInfo;
begin
  if assigned(CardSkin) then
      Result := FCardSkin.CardInfo
  else
      Result := FCardInstance.CardInfo;
end;

constructor TCardInstanceWithRewards.Create(const Card : TCardInstance);
begin
  FCardInstance := Card;
  FCardStateAfterRewards := False;
end;

function TCardInstanceWithRewards.ExperienceBefore : integer;
begin
  if FCardStateAfterRewards then Result := FExperienceBefore
  else Result := CardInstance.ExperiencePoints
end;

function TCardInstanceWithRewards.IsMaxLeveLAfter : boolean;
begin
  Result := LevelAfter >= CardManager.CardConstants.LevelPerLeague;
end;

function TCardInstanceWithRewards.LevelAfter : integer;
begin
  Result := CardManager.CardConstants.GetCardLevel(FCardInstance.League, ExperienceBefore + ExperienceGained);
end;

function TCardInstanceWithRewards.LevelBefore : integer;
begin
  Result := CardManager.CardConstants.GetCardLevel(FCardInstance.League, ExperienceBefore);
end;

function TCardInstanceWithRewards.LevelProgressAfter : single;
var
  ExperienceWithoutPremium : integer;
begin
  ExperienceWithoutPremium := ExperienceBefore + ExperienceGained;
  if PremiumApplied then
      ExperienceWithoutPremium := ExperienceWithoutPremium - ExperienceGainedPremium;
  Result := CardManager.CardConstants.GetLevelProgress(FCardInstance.League, ExperienceWithoutPremium);
  if CardManager.CardConstants.GetCardLevel(FCardInstance.League, ExperienceWithoutPremium) < LevelAfter then
      Result := 0;
end;

function TCardInstanceWithRewards.LevelProgressAfterPremium : single;
var
  ExperienceWithPremium : integer;
begin
  ExperienceWithPremium := ExperienceBefore + ExperienceGained;
  if not PremiumApplied then
      ExperienceWithPremium := ExperienceWithPremium + ExperienceGainedPremium;
  Result := CardManager.CardConstants.GetLevelProgress(FCardInstance.League, ExperienceWithPremium);
  if CardManager.CardConstants.GetCardLevel(FCardInstance.League, ExperienceWithPremium) > LevelAfter then
      Result := 1.0;
end;

function TCardInstanceWithRewards.LevelProgressBefore : single;
begin
  if LevelUp then
      Result := 0
  else
      Result := CardManager.CardConstants.GetLevelProgress(FCardInstance.League, ExperienceBefore);
end;

function TCardInstanceWithRewards.LevelUp : boolean;
begin
  Result := LevelBefore <> LevelAfter;
end;

procedure TCardInstanceWithRewards.SetDailyRewardUsed(const Value : boolean);
begin
  FDailyRewardUsed := Value;
end;

procedure TCardInstanceWithRewards.SetExperienceGained(const Value : integer);
begin
  FExperienceGained := Value;
end;

procedure TCardInstanceWithRewards.SetExperienceGainedPremium(const Value : integer);
begin
  FExperienceGainedPremium := Value;
end;

procedure TCardInstanceWithRewards.SetHasAscension(const Value : boolean);
begin
  FHasAscension := Value;
end;

procedure TCardInstanceWithRewards.SetUpgradePointsGained(const Value : integer);
begin
  FUpgradePointsGained := Value;
end;

function TCardInstanceWithRewards.UpgradePointsBefore : integer;
begin
  if FCardStateAfterRewards then Result := FUpgradePointsBefore
  else Result := CardInstance.CurrentUpgradePoints
end;

function TCardInstanceWithRewards.UpgradeProgressAfter : single;
begin
  Result := HMath.Saturate((UpgradePointsBefore + UpgradePointsGained) / CardInstance.TotalUpgradePoints);
end;

function TCardInstanceWithRewards.UpgradeProgressBefore : single;
begin
  Result := HMath.Saturate(UpgradePointsBefore / CardInstance.TotalUpgradePoints);
end;

{ TGameMetaInfoRewards }

constructor TGameMetaInfoRewards.Create(const Data : RGameFinishedRewards; const NewRankingData : RMatchmakingRanking);
var
  Card : RGameCardReward;
  RankingData : TMatchmakingRanking;
  LevelBefore, ExperienceBefore : integer;
  LevelUp : boolean;
begin
  assert(assigned(CardManager));
  // premium
  FPremiumApplied := Data.has_premium;
  // currency
  FGoldPremium := Data.currency_premium;
  FGold := Data.currency;
  if FPremiumApplied then
      FGold := FGold - FGoldPremium;
  // player experience rewards
  FExperiencePremium := Data.experience_premium;
  FExperience := Data.Experience;

  FLevelBefore := Data.level_before;
  LevelBefore := UserProfile.Level;
  ExperienceBefore := UserProfile.ExperiencePoints;
  UserProfile.GainExperience(FExperience); // Experience contains premium if applied

  LevelUp := LevelBefore < UserProfile.Level;
  if LevelUp then
      FLevelProgressBefore := 0
  else
      FLevelProgressBefore := ExperienceBefore / UserProfile.LevelUpExperiencePoints;

  FLevelProgress := UserProfile.ExperiencePoints;
  if PremiumApplied then
      FLevelProgress := Max(0, FLevelProgress - Data.experience_premium);
  FLevelProgress := FLevelProgress / UserProfile.LevelUpExperiencePoints;

  FLevelProgressAfterPremium := UserProfile.ExperiencePoints;
  if not PremiumApplied then
      FLevelProgressAfterPremium := FLevelProgressAfterPremium + Data.experience_premium;
  FLevelProgressAfterPremium := Min(1.0, FLevelProgressAfterPremium / UserProfile.LevelUpExperiencePoints);
  // card rewards
  FCardWithRewards := TUltimateObjectList<TCardInstanceWithRewards>.Create;
  for Card in Data.Cards do
  begin
    FCardWithRewards.Add(TCardInstanceWithRewards.Create(Card));
  end;
  // ranking data
  RankingData := ScenarioManager.Rankings.Query.Get(F('FID') = NewRankingData.id);
  FRankingAfter := NewRankingData.rank;
  FRankingBefore := RankingData.rank;
  FStarsAfter := NewRankingData.stars;
  if FRankingAfter < FRankingBefore then
  begin
    FStarsBefore := 0;
    FStarsChange := (RankingData.StarsToClimbUp - RankingData.stars) + NewRankingData.stars;
  end
  else if FRankingAfter > FRankingBefore then
  begin
    FStarsBefore := NewRankingData.stars_to_climb;
    FStarsChange := -RankingData.stars - (NewRankingData.stars_to_climb - NewRankingData.stars);
  end
  else
  begin
    FStarsBefore := RankingData.stars;
    FStarsChange := FStarsAfter - FStarsBefore;
  end;
  FMaxStarsAtRank := NewRankingData.stars_to_climb;
  RankingData.UpdateData(NewRankingData);
end;

destructor TGameMetaInfoRewards.Destroy;
begin
  FCardWithRewards.Free;
  inherited;
end;

procedure TGameMetaInfoRewards.SetPremiumApplied(const Value : boolean);
begin
  FPremiumApplied := Value;
end;

{ TGameMetaInfoStatisticsPlayer }

constructor TGameMetaInfoStatisticsPlayer.Create(const Data : RClientGameStatisticPlayer);
var
  card_data : RGameCard;
begin
  FPlayer := Account.GetPerson(Data);
  FRanking := Data.Ranking;
  FTeamID := Data.team_id;
  FCards := TUltimateList<TCardInfo>.Create;
  for card_data in Data.Cards do
  begin
    FCards.Add(CardInfoManager.ResolveCardUID(card_data.base_card_uid, card_data.tier, card_data.Level));
  end;
  FCards.Sort(TComparer<TCardInfo>.Construct(TCardInfo.Compare));
end;

destructor TGameMetaInfoStatisticsPlayer.Destroy;
begin
  FCards.Free;
  inherited;
end;

end.
