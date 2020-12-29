unit BaseConflict.Api.Scenarios;

interface

uses
  // Delphi
  System.Generics.Defaults,
  System.Generics.Collections,
  System.SysUtils,
  Winapi.Windows,
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
  BaseConflict.Api.Cards,
  BaseConflict.Api.Deckbuilding,
  BaseConflict.Api.Account,
  BaseConflict.Api.Profile;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$M+}
  TScenarioTeam = class;
  TScenario = class;
  TScenarioInstance = class;

  /// <summary> A mutator for a scenario-instance. Adds additional gameplay to a scenario. </summary>
  TScenarioMutator = class
    strict private
      FIdentifier : string;
    published
      property Identifier : string read FIdentifier;
    public
      constructor Create(const Identifier : string);
  end;

  /// <summary> A team within a scenario. A scenario can consist of multiple teams with different teamsizes. </summary>
  TScenarioTeam = class
    strict private
      FTeamSize : integer;
      FTeamID : integer;
    published
      property TeamSize : integer read FTeamSize;
      property TeamID : integer read FTeamID;
    public
      constructor Create(TeamID : integer; TeamSize : integer);
  end;

  TMatchmakingRanking = class;

  /// <summary> A scenario aka a map with settings. </summary>
  TScenario = class
    private
      FIdentifier : string;
      /// <summary> Load all deck constraints that are targeting a scenario instance.</summary>
      procedure LoadConstraints(Data : ATApiScenarioDeckConstraint);
    strict private
      FTeams : TUltimateObjectList<TScenarioTeam>;
      FLevelsOfDifficulty : TUltimateObjectList<TScenarioInstance>;
      FEnabled : boolean;
      FRanked : boolean;
      FMinimumPlayerlevel : integer;
      FDeckRequired : boolean;
    published
      property Enabled : boolean read FEnabled;
      property Teams : TUltimateObjectList<TScenarioTeam> read FTeams;
      property LevelsOfDifficulty : TUltimateObjectList<TScenarioInstance> read FLevelsOfDifficulty;
      property Ranked : boolean read FRanked;
      property MinimumPlayerlevel : integer read FMinimumPlayerlevel;
      property DeckRequired : boolean read FDeckRequired;
      /// <summary> Returns True if teams are not symmetrical, means that not each team has the same teamsize.</summary>
      function AsymmetricTeams : boolean;
      /// <summary> Returns the maximum teamsize over all teams.</summary>
      function MaxTeamSize : integer;
      /// <summary> Returns true for scenarios which are player versus player. </summary>
      function IsPvP : boolean;
      function IsDuel : boolean;
      function IsPvE : boolean;
      function IsTutorial : boolean;
    public
      property UID : string read FIdentifier;
      constructor Create(const Data : RScenario);
      destructor Destroy; override;
  end;

  /// <summary> Limit usable decks of players for target scenario instance. Only if all constraints a scenario
  /// has are fulfilled, a deck can be used for scenario.</summary>
  TScenarioDeckConstraint = class
    private
      function CheckCard(const DeckCard : TCardInstance) : boolean; virtual; abstract;
    public
      /// <summary> Checks a deck against constraint and returns true if constraint is fulfilled, else false.</summary>
      function CheckDeck(Deck : TDeck) : boolean; virtual;
  end;

  TScenarioDeckConstraintLimitTier = class(TScenarioDeckConstraint)
    private
      FUsableTier : integer;
      function CheckCard(const DeckCard : TCardInstance) : boolean; override;
    public
      /// <summary> Only cards of usable tier can be used within deck, any card with higher AND lower tier
      /// will invalid the deck.</summary>
      property UsableTier : integer read FUsableTier;
      constructor Create(Data : TApiScenarioDeckConstraintLimitTier);
  end;

  TScenarioDeckConstraintLimitMaxTier = class(TScenarioDeckConstraint)
    private
      FMaxTier : integer;
      function CheckCard(const DeckCard : TCardInstance) : boolean; override;
    public
      /// <summary> Only cards with tier <= MaxTier allow in deck.</summary>
      property MaximalTier : integer read FMaxTier;
      constructor Create(Data : TApiScenarioDeckConstraintLimitMaxTier);
  end;

  TScenarioDeckConstraintLimitCardColor = class(TScenarioDeckConstraint)
    private
      FCardColors : SetEntityColor;
      function CheckCard(const DeckCard : TCardInstance) : boolean; override;
    public
      /// <summary> Only cards with colors in CardColors allowed in deck. If cardcolors contains
      /// more than one color also multicolor cards with colors in cardcolors are allowed.
      /// Constraint does not limit the affinities.</summary>
      property CardColors : SetEntityColor read FCardColors;
      constructor Create(Data : TApiScenarioDeckConstraintLimitCardColor);
  end;

  /// <summary> A tiered instance of a certain scenario with additional deck constraints and mutators. </summary>
  TScenarioInstance = class
    private
      FID : integer;
    strict private
      FMutators : TUltimateObjectList<TScenarioMutator>;
      FDeckConstraints : TUltimateObjectList<TScenarioDeckConstraint>;
      FLeague : integer;
      FScenario : TScenario;
      FRanking : TMatchmakingRanking;
      procedure SetRanking(const Value : TMatchmakingRanking); virtual;
    published
      property League : integer read FLeague;
      property Mutators : TUltimateObjectList<TScenarioMutator> read FMutators;
      property DeckConstraints : TUltimateObjectList<TScenarioDeckConstraint> read FDeckConstraints;
      property Scenario : TScenario read FScenario;
      property Ranking : TMatchmakingRanking read FRanking write SetRanking;
    public
      property ID : integer read FID;
      constructor Create(Scenario : TScenario; const Data : RScenarioInstance);
      destructor Destroy; override;
  end;

  /// <summary> Ranking player have for a specific scenario instance. This info exists also if
  /// scenario isn't ranked, then ranking infos (e.g. rank, stars) are not set.</summary>
  TMatchmakingRanking = class
    strict private
      FID : integer;
      FScenarioInstance : TScenarioInstance;
      FWon : integer;
      FRank : integer;
      FStars : integer;
      FLost : integer;
      FStarsToClimbUp : integer;
      FPersonalBestTime : integer;
      procedure SetLost(const Value : integer); virtual;
      procedure SetWon(const Value : integer); virtual;
      procedure SetRank(const Value : integer); virtual;
      procedure SetStars(const Value : integer); virtual;
      procedure SetStarsToClimbUp(const Value : integer); virtual;
      procedure SetPersonalBestTime(const Value : integer); virtual;
    published
      property ScenarioInstance : TScenarioInstance read FScenarioInstance;
      /// <summary> Games player has won this ScenarioInstance.</summary>
      property Won : integer read FWon write SetWon;
      /// <summary> Games player has lost this ScenarioInstance.</summary>
      property Lost : integer read FLost write SetLost;
      /// <summary> Current rank. Range is 25->1, where 1 is best rank.</summary>
      property Rank : integer read FRank write SetRank;
      /// <summary> Current stars player have on current rank. Stars are collected for win and disappear if player lost.</summary>
      property Stars : integer read FStars write SetStars;
      /// <summary> Stars necessary for player to climb up to next rank.</summary>
      property StarsToClimbUp : integer read FStarsToClimbUp write SetStarsToClimbUp;
      /// <summary> Players personal best time for scenario instance in seconds (only wins).
      /// HINT Value will be -1, if player has not won this scenario yet.</summary>
      property PersonalBestTime : integer read FPersonalBestTime write SetPersonalBestTime;
    public
      /// <summary> Standard constructor, init data from data.</summary>
      constructor Create(ScenarioInstance : TScenarioInstance; const Data : RMatchmakingRanking);
      procedure UpdateData(const Data : RMatchmakingRanking);
  end;

  TScenarioManager = class
    private
      FScenarios : TUltimateObjectList<TScenario>;
      FRankings : TUltimateObjectList<TMatchmakingRanking>;
      procedure LoadScenarioConstraintData(const Data : ATApiScenarioDeckConstraint);
      procedure LoadRankingData(const Data : ARMatchmakingRanking);
      function GetScenario(Identifier : string) : TScenario;
    published
      property Scenarios : TUltimateObjectList<TScenario> read FScenarios;
      property Rankings : TUltimateObjectList<TMatchmakingRanking> read FRankings;
      [dXMLDependency('.Rankings', '.Rankings.Rank')]
      function HighestRanking : integer;
    public
      constructor Create;
      function TryResolveScenario(const ScenarioUID : string; out Scenario : TScenario) : boolean;
      function TryResolveScenarioInstance(const ScenarioInstanceID : integer; out ScenarioInstance : TScenarioInstance) : boolean;
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  TScenarioManagerAction = class(TPromiseAction)
    private
      FScenarioManager : TScenarioManager;
    public
      constructor Create(ScenarioManager : TScenarioManager);
  end;

  [AQCriticalAction]
  TScenarioManagerActionLoadScenarios = class(TScenarioManagerAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TScenarioManagerActionLoadScenarioConstraints = class(TScenarioManagerAction)
    public
      function Execute : boolean; override;
  end;

  [AQCriticalAction]
  TScenarioManagerActionLoadRankings = class(TScenarioManagerAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;
  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  ScenarioManager : TScenarioManager;

implementation

{$IFDEF CLIENT}
uses
  BaseConflict.Globals.Client;
{$ENDIF}

{ TScenario }

function TScenario.AsymmetricTeams : boolean;
begin
  Result := False;
end;

constructor TScenario.Create(const Data : RScenario);
var
  Query : IDataQuery<RScenarioSlot>;
  team_id : integer;
  // mutator : RScenarioMutator;
  scenario_instance_data : RScenarioInstance;
begin
  FIdentifier := Data.Identifier;
  FEnabled := Data.Enabled;
  FTeams := TUltimateObjectList<TScenarioTeam>.Create;
  FLevelsOfDifficulty := TUltimateObjectList<TScenarioInstance>.Create;
  FRanked := Data.Ranked;
  FMinimumPlayerlevel := Data.minimum_playerlevel;
  FDeckRequired := Data.deck_required;
  // build teams from slots
  Query := TDelphiDataQuery<RScenarioSlot>.Create(Data.slots);
  // every unique team_id signals a team
  for team_id in Query.Distinct('team_id').ValuesAsInteger('team_id') do
  begin
    // team_size = number of slots with current team_id
    FTeams.Add(TScenarioTeam.Create(team_id, Query.Filter(F('team_id') = team_id).Count));
  end;
  for scenario_instance_data in Data.levels_of_difficulty do
  begin
    LevelsOfDifficulty.Add(TScenarioInstance.Create(self, scenario_instance_data))
  end;
  LevelsOfDifficulty.Sort(TComparer<TScenarioInstance>.Construct(
    function(const Left, Right : TScenarioInstance) : integer
    begin
      Result := Left.League - Right.League;
    end
    ));
end;

destructor TScenario.Destroy;
begin
  FTeams.Free;
  FLevelsOfDifficulty.Free;
  inherited;
end;

function TScenario.IsDuel : boolean;
begin
  Result := HScenario.IsDuel(FIdentifier);
end;

function TScenario.IsPvE : boolean;
begin
  Result := not IsPvP and not IsTutorial;
end;

function TScenario.IsPvP : boolean;
begin
  Result := HScenario.IsPvP(FIdentifier);
end;

function TScenario.IsTutorial : boolean;
begin
  Result := HScenario.IsTutorial(FIdentifier);
end;

procedure TScenario.LoadConstraints(Data : ATApiScenarioDeckConstraint);
var
  constraint_data : TApiScenarioDeckConstraint;
  ScenarioInstance : TScenarioInstance;
  Constraint : TScenarioDeckConstraint;
begin
  for constraint_data in Data do
  begin
    if LevelsOfDifficulty.Query.TryGet(F('FID') = constraint_data.scenario_instance_id, ScenarioInstance) then
    begin
      if constraint_data is TApiScenarioDeckConstraintLimitTier then
          Constraint := TScenarioDeckConstraintLimitTier.Create(TApiScenarioDeckConstraintLimitTier(constraint_data))
      else if constraint_data is TApiScenarioDeckConstraintLimitMaxTier then
          Constraint := TScenarioDeckConstraintLimitMaxTier.Create(TApiScenarioDeckConstraintLimitMaxTier(constraint_data))
      else if constraint_data is TApiScenarioDeckConstraintLimitCardColor then
          Constraint := TScenarioDeckConstraintLimitCardColor.Create(TApiScenarioDeckConstraintLimitCardColor(constraint_data))
      else
          raise ENotImplemented.Create('TScenario.LoadConstraints: Unkown constraint data class ' + constraint_data.ClassName);
      ScenarioInstance.DeckConstraints.Add(Constraint);
    end;
  end;
end;

function TScenario.MaxTeamSize : integer;
var
  i : integer;
begin
  if IsDuel then
  begin
    Result := 0;
    for i := 0 to FTeams.Count - 1 do
        Result := Result + FTeams[i].TeamSize;
  end
  else
      Result := FTeams.Query.OrderBy('-TeamSize').First.TeamSize;
end;

{ TScenarioTeam }

constructor TScenarioTeam.Create(TeamID, TeamSize : integer);
begin
  FTeamSize := TeamSize;
  FTeamID := TeamID;
end;

{ TScenarioMutator }

constructor TScenarioMutator.Create(const Identifier : string);
begin
  FIdentifier := Identifier;
end;

{ TScenarioDeckConstraintLimitTier }

function TScenarioDeckConstraintLimitTier.CheckCard(const DeckCard : TCardInstance) : boolean;
begin
  Result := DeckCard.League = UsableTier;
end;

constructor TScenarioDeckConstraintLimitTier.Create(Data : TApiScenarioDeckConstraintLimitTier);
begin
  inherited Create;
  FUsableTier := Data.Tier;
end;

{ TScenarioDeckConstraint }

function TScenarioDeckConstraint.CheckDeck(Deck : TDeck) : boolean;
var
  i : integer;
  Card : TCardInstance;
begin
  Result := True;
  for i := 0 to Deck.CardSlotCount - 1 do
  begin
    Card := Deck.Cards[i].CardInstance;
    if assigned(Card) then
        Result := Result and CheckCard(Card);
    // fast exit if any cards does not pass constraint
    if not Result then
        break;
  end;
end;

{ TScenarioInstance }

constructor TScenarioInstance.Create(Scenario : TScenario; const Data : RScenarioInstance);
var
  mutator : RScenarioMutator;
begin
  FID := Data.ID;
  FScenario := Scenario;
  FMutators := TUltimateObjectList<TScenarioMutator>.Create;
  for mutator in Data.Mutators do
  begin
    FMutators.Add(TScenarioMutator.Create(mutator.Identifier));
  end;
  FDeckConstraints := TUltimateObjectList<TScenarioDeckConstraint>.Create;
  FLeague := Data.Tier;
end;

destructor TScenarioInstance.Destroy;
begin
  FMutators.Free;
  FDeckConstraints.Free;
  inherited;
end;

procedure TScenarioInstance.SetRanking(const Value : TMatchmakingRanking);
begin
  FRanking := Value;
end;

{ TScenarioDeckConstraintLimitCardColor }

function TScenarioDeckConstraintLimitCardColor.CheckCard(const DeckCard : TCardInstance) : boolean;
begin
  Result := DeckCard.OriginCard.Colors <= CardColors;
end;

constructor TScenarioDeckConstraintLimitCardColor.Create(Data : TApiScenarioDeckConstraintLimitCardColor);
begin
  FCardColors := Data.card_colors;
end;

{ TScenarioDeckConstraintLimitMaxTier }

function TScenarioDeckConstraintLimitMaxTier.CheckCard(const DeckCard : TCardInstance) : boolean;
begin
  Result := DeckCard.League <= MaximalTier;
end;

constructor TScenarioDeckConstraintLimitMaxTier.Create(Data : TApiScenarioDeckConstraintLimitMaxTier);
begin
  FMaxTier := Data.max_tier;
end;

{ TMatchmakingRanking }

constructor TMatchmakingRanking.Create(ScenarioInstance : TScenarioInstance; const Data : RMatchmakingRanking);
begin
  FScenarioInstance := ScenarioInstance;
  FID := Data.ID;
  UpdateData(Data);
  ScenarioInstance.Ranking := self;
end;

procedure TMatchmakingRanking.SetPersonalBestTime(const Value : integer);
begin
  FPersonalBestTime := Value;
end;

procedure TMatchmakingRanking.SetLost(const Value : integer);
begin
  FLost := Value;
end;

procedure TMatchmakingRanking.SetRank(const Value : integer);
begin
  FRank := Value;
end;

procedure TMatchmakingRanking.SetStars(const Value : integer);
begin
  FStars := Value;
end;

procedure TMatchmakingRanking.SetStarsToClimbUp(const Value : integer);
begin
  FStarsToClimbUp := Value;
end;

procedure TMatchmakingRanking.SetWon(const Value : integer);
begin
  FWon := Value;
end;

procedure TMatchmakingRanking.UpdateData(const Data : RMatchmakingRanking);
begin
  assert(FID = Data.ID);
  Won := Data.Won;
  Lost := Data.Lost;
  Rank := Data.Rank;
  StarsToClimbUp := Data.stars_to_climb;
  Stars := Data.Stars;
  PersonalBestTime := Data.best_time;
end;

{ TScenarioManagerActionLoadRankings }

function TScenarioManagerActionLoadRankings.Execute : boolean;
var
  Promise : TPromise<ARMatchmakingRanking>;
begin
  Promise := MatchmakingAPI.GetRankings;
  Promise.WaitForData;
  if Promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        FScenarioManager.LoadRankingData(Promise.Value);
      end);
  end
  else HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

procedure TScenarioManagerActionLoadRankings.Rollback;
begin
  FScenarioManager.Rankings.Clear;
end;

{ TScenarioManagerActionLoadScenarios }

function TScenarioManagerActionLoadScenarios.Execute : boolean;
var
  Promise : TPromise<ARScenario>;
begin
  Promise := GameManagerAPI.GetScenarios;
  Promise.WaitForData;
  if Promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      var
        scenario_data : RScenario;
        Scenarios : TArray<TScenario>;
      begin
        Scenarios := nil;
        FScenarioManager.Scenarios.Clear;
        for scenario_data in Promise.Value do
          if not scenario_data.staff_only or UserProfile.IsStaff {$IFDEF CLIENT} or IsStaging{$ENDIF} then
              HArray.Push<TScenario>(Scenarios, TScenario.Create(scenario_data));
        FScenarioManager.Scenarios.AddRange(Scenarios);
      end);
  end
  else HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

procedure TScenarioManagerActionLoadScenarios.Rollback;
begin
  FScenarioManager.Scenarios.Clear;
end;

{ TScenarioManagerActionLoadScenarioConstraints }

function TScenarioManagerActionLoadScenarioConstraints.Execute : boolean;
var
  Promise : TPromise<ATApiScenarioDeckConstraint>;
  Data : ATApiScenarioDeckConstraint;
begin
  Promise := GameManagerAPI.GetScenarioDeckConstraints;
  Promise.WaitForData;
  if Promise.WasSuccessful then
  begin
    Data := Promise.Value;
    DoSynchronized(
      procedure()
      begin
        FScenarioManager.LoadScenarioConstraintData(Data);
        HArray.FreeAllObjects<TApiScenarioDeckConstraint>(Data);
      end);
  end
  else HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

{ TScenarioManager }

procedure TScenarioManager.LoadRankingData(const Data : ARMatchmakingRanking);
var
  Item : RMatchmakingRanking;
  Scenario : TScenario;
  ScenarioInstance : TScenarioInstance;
begin
  Rankings.Clear;
  for Item in Data do
  begin
    ScenarioInstance := nil;
    for Scenario in Scenarios do
    begin
      ScenarioInstance := Scenario.LevelsOfDifficulty.Query.Get(F('FID') = Item.scenario_instance_id, True);
      if assigned(ScenarioInstance) then
          break;
    end;
    // possible that no scenario instance exists, as some scenario data is dropped
    // as only staff has access to
    if assigned(ScenarioInstance) then
        Rankings.Add(TMatchmakingRanking.Create(ScenarioInstance, Item));
  end;
end;

procedure TScenarioManager.LoadScenarioConstraintData(const Data : ATApiScenarioDeckConstraint);
var
  Scenario : TScenario;
begin
  for Scenario in Scenarios do
      Scenario.LoadConstraints(Data);
end;

function TScenarioManager.TryResolveScenario(const ScenarioUID : string; out Scenario : TScenario) : boolean;
var
  res : TScenario;
begin
  res := FScenarios.Query.Get(F('UID') = ScenarioUID, True);
  Result := assigned(res);
  if Result then
      Scenario := res;
end;

function TScenarioManager.TryResolveScenarioInstance(const ScenarioInstanceID : integer; out ScenarioInstance : TScenarioInstance) : boolean;
var
  res : TScenarioInstance;
  i : integer;
  ii : integer;
begin
  res := nil;
  for i := 0 to FScenarios.Count - 1 do
    for ii := 0 to FScenarios[i].LevelsOfDifficulty.Count - 1 do
      if FScenarios[i].LevelsOfDifficulty[ii].ID = ScenarioInstanceID then
      begin
        res := FScenarios[i].LevelsOfDifficulty[ii];
        break;
      end;
  Result := assigned(res);
  if Result then
      ScenarioInstance := res;
end;

function TScenarioManager.GetScenario(Identifier : string) : TScenario;
begin
  Result := FScenarios.Query.Filter(F('FIdentifier') = Identifier).First;
end;

function TScenarioManager.HighestRanking : integer;
var
  BestRanking : TMatchmakingRanking;
begin
  BestRanking := Rankings.Query.OrderBy(F('-Rank')).First(True);
  if assigned(BestRanking) then
      Result := BestRanking.Rank
  else
      Result := -1;
end;

constructor TScenarioManager.Create;
begin
  FScenarios := TUltimateObjectList<TScenario>.Create;
  FRankings := TUltimateObjectList<TMatchmakingRanking>.Create;
  MainActionQueue.DoAction(TScenarioManagerActionLoadScenarios.Create(self));
  // disabled - not used atm
  // MainActionQueue.DoAction(TScenarioManagerActionLoadScenarioConstraints.Create(self));
  MainActionQueue.DoAction(TScenarioManagerActionLoadRankings.Create(self));
end;

destructor TScenarioManager.Destroy;
begin
  FRankings.Free;
  FScenarios.Free;
  inherited;
end;

{ TScenarioManagerAction }

constructor TScenarioManagerAction.Create(ScenarioManager : TScenarioManager);
begin
  inherited Create();
  FScenarioManager := ScenarioManager;
end;

end.
