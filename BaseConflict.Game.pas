unit BaseConflict.Game;

interface

uses
  generics.Collections,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Scenario,
  Engine.Serializer,
  Engine.Collision,
  Engine.Script,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.Map,
  BaseConflict.Types.Shared,
  SysUtils,
  Math,
  RTTI;

type

  {$RTTI EXPLICIT METHODS([vcPublic]) FIELDS([vcPublic]) PROPERTIES([vcPublic])}
  TGameInformation = class
    // later mapname and type, gamemode etc.
    ScenarioUID : string;
    Scenario : TScenarioMetaInfo;
    // aka difficulty
    League : integer;
    Mutators : TList<TMutatorMetaInfo>;
    IsSandboxOverride : boolean;
    function IsSandbox : boolean;
    function IsTutorial : boolean;
    function IsPvE : boolean;
    function IsPvP : boolean;
    function IsSingle : boolean;
    function IsDuo : boolean;
    function IsTeamMode : boolean;
    constructor Create();
    destructor Destroy; override;
  end;

  [ScriptExcludeAll]
  TGame = class
    strict private
      FCharmCountCap : integer;
      FStartingGold : single;
      FIncomeUpgradeCostPerIncomeUpgrade : single;
      FStartingTier : integer;
      FStartingIncomeUpgradeCost : single;
      FGoldCap : single;
      FGoldCapPerTier : single;
      FGadgetCountCap : integer;
      FIncomeUpgradeCap : integer;
      FIncomeRatePerIncomeUpgrade : single;
      FStartingIncomeRate : single;
      FStartingWood : single;
      procedure InitValues;
    protected
      FGameInfo : TGameInformation;
      FShutdown : boolean;
      FMap : TMap;
      FServerTime : int64;
      FGameEntity : TEntity;
      FEntityManager : TEntityManagerComponent;
      FGameDirector : TGameDirectorComponent;
      function GetIngameStatus : EnumInGameStatus;
      function GetServerTime : int64; virtual;
    public
      [ScriptIncludeMember]
      property StartingGold : single read FStartingGold write FStartingGold;
      [ScriptIncludeMember]
      property GoldCap : single read FGoldCap write FGoldCap;
      [ScriptIncludeMember]
      property StartingWood : single read FStartingWood write FStartingWood;
      [ScriptIncludeMember]
      property IncomeUpgradeCap : integer read FIncomeUpgradeCap write FIncomeUpgradeCap;
      [ScriptIncludeMember]
      property StartingTier : integer read FStartingTier write FStartingTier;
      [ScriptIncludeMember]
      property GadgetCountCap : integer read FGadgetCountCap write FGadgetCountCap;
      [ScriptIncludeMember]
      property CharmCountCap : integer read FCharmCountCap write FCharmCountCap;
      [ScriptIncludeMember]
      property StartingIncomeRate : single read FStartingIncomeRate write FStartingIncomeRate;
      [ScriptIncludeMember]
      property IncomeRatePerIncomeUpgrade : single read FIncomeRatePerIncomeUpgrade write FIncomeRatePerIncomeUpgrade;
      [ScriptIncludeMember]
      property StartingIncomeUpgradeCost : single read FStartingIncomeUpgradeCost write FStartingIncomeUpgradeCost;
      [ScriptIncludeMember]
      property IncomeUpgradeCostPerIncomeUpgrade : single read FIncomeUpgradeCostPerIncomeUpgrade write FIncomeUpgradeCostPerIncomeUpgrade;
      [ScriptIncludeMember]
      property GoldCapPerTier : single read FGoldCapPerTier write FGoldCapPerTier;
    public
      CollisionManager : TCollisionManagerComponent;
      property GameInfo : TGameInformation read FGameInfo;
      [ScriptIncludeMember]
      function League : integer;
      property GameEntity : TEntity read FGameEntity;
      [ScriptIncludeMember]
      property Map : TMap read FMap;
      property EntityManager : TEntityManagerComponent read FEntityManager;
      property ServerTime : int64 read GetServerTime write FServerTime;
      property InGameStatus : EnumInGameStatus read GetIngameStatus;
      function IsWaiting : boolean;
      function HasStarted : boolean;
      [ScriptIncludeMember]
      property GameDirector : TGameDirectorComponent read FGameDirector write FGameDirector;
      constructor Create(GameInfo : TGameInformation);
      [ScriptIncludeMember]
      function IsSandbox : boolean;
      [ScriptIncludeMember]
      function IsTutorial : boolean;
      [ScriptIncludeMember]
      function IsPvE : boolean;
      [ScriptIncludeMember]
      function IsPvP : boolean;
      [ScriptIncludeMember]
      function IsDuo : boolean;
      [ScriptIncludeMember]
      function IsOneLane : boolean;
      [ScriptIncludeMember]
      function IsTwoLane : boolean;
      [ScriptIncludeMember]
      function HasShowdown : boolean;
      function IsPerformanceTest : boolean;
      function IsShuttingDown : boolean;
      /// <summary> Initialized the scenario environment. </summary>
      procedure Initialize; virtual;
      procedure Idle; virtual;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}

implementation

uses
  BaseConflict.Globals;

{ TGame }

constructor TGame.Create(GameInfo : TGameInformation);
var
  Map : string;
begin
  InitValues;
  FGameInfo := GameInfo;
  FGameEntity := TEntity.Create(GlobalEventbus, 1);
  TGameTickComponent.Create(GameEntity);
  if FGameInfo.Scenario.Mapname <> '' then
  begin
    Map := FormatDateiPfad(PATH_MAP + FGameInfo.Scenario.Mapname + '\' + FGameInfo.Scenario.Mapname + '.bcm');
    FMap := TMap.CreateFromFile(Map);
  end
  else FMap := TMap.CreateEmpty;
  BaseConflict.Globals.Game := self;
  BaseConflict.Globals.Map := FMap;
  GameDirector := TGameDirectorComponent.Create(FGameEntity);
end;

destructor TGame.Destroy;
begin
  FShutdown := True;
  // first let all entites unsubscribe from global components
  FreeAndNil(FEntityManager);
  // then kill rest
  FGameEntity.Free;
  FMap.Free;
  FGameInfo.Free;
  BaseConflict.Globals.Game := nil;
  BaseConflict.Globals.Map := nil;
  inherited;
end;

function TGame.GetIngameStatus : EnumInGameStatus;
var
  TimeToStart : integer;
begin
  if FShutdown then exit(gsShutdown);
  TimeToStart := GlobalEventbus.Read(eiGameTickTimeToFirstTick, []).AsInteger;
  if TimeToStart >= GAME_WARMING_DURATION then Result := gsLoading
  else if TimeToStart > 0 then Result := gsWarming
  else Result := gsPlaying;
end;

function TGame.GetServerTime : int64;
begin
  Result := FServerTime;
end;

function TGame.HasShowdown : boolean;
begin
  Result := IsPvP and not IsSandbox;
end;

function TGame.HasStarted : boolean;
begin
  Result := GlobalEventbus.Read(eiGameTickTimeToFirstTick, []).AsInteger <= 0;
end;

procedure TGame.Idle;
begin
  FMap.Idle;
  EntityManager.Idle;
end;

procedure TGame.Initialize;
var
  i, j : integer;
begin
  for i := FGameInfo.Scenario.ScenarioScriptfile.Count - 1 downto 0 do
      FGameEntity.ApplyScript(FGameInfo.Scenario.ScenarioScriptfile[i], 'Apply', [TValue.From<TEntity>(self.FGameEntity), TValue.From<TGame>(self)]);
  for i := 0 to FGameInfo.Mutators.Count - 1 do
    for j := 0 to FGameInfo.Mutators[i].MutatorScriptfile.Count - 1 do
        FGameEntity.ApplyScript(FGameInfo.Mutators[i].MutatorScriptfile[j], 'Apply', [TValue.From<TEntity>(self.FGameEntity), TValue.From<TGame>(self)]);
end;

procedure TGame.InitValues;
begin
  FStartingGold := 300;
  FGoldCap := 400;
  FStartingWood := 1600;
  FIncomeUpgradeCap := 10;
  FStartingTier := 1;
  FGadgetCountCap := 5;
  FCharmCountCap := 3;
  FStartingIncomeRate := 10;
  FIncomeRatePerIncomeUpgrade := 2;
  FStartingIncomeUpgradeCost := 1500;
  FIncomeUpgradeCostPerIncomeUpgrade := 250;
  FGoldCapPerTier := 100;
end;

function TGame.IsDuo : boolean;
begin
  Result := FGameInfo.IsDuo;
end;

function TGame.IsOneLane : boolean;
begin
  Result := FGameInfo.Scenario.Mapname = MAP_SINGLE;
end;

function TGame.IsPerformanceTest : boolean;
begin
  Result := FGameInfo.ScenarioUID = SCENARIO_PERFORMANCE_TEST;
end;

function TGame.IsPvE : boolean;
begin
  Result := FGameInfo.IsPvE;
end;

function TGame.IsPvP : boolean;
begin
  Result := FGameInfo.IsPvP;
end;

function TGame.IsSandbox : boolean;
begin
  Result := FGameInfo.IsSandbox;
end;

function TGame.IsShuttingDown : boolean;
begin
  Result := InGameStatus = gsShutdown;
end;

function TGame.IsTutorial : boolean;
begin
  Result := FGameInfo.IsTutorial;
end;

function TGame.IsTwoLane : boolean;
begin
  Result := FGameInfo.Scenario.Mapname = MAP_DOUBLE;
end;

function TGame.IsWaiting : boolean;
begin
  Result := GetIngameStatus in [gsLoading];
end;

function TGame.League : integer;
begin
  if DISABLE_LEAGUE_SYSTEM then
      Result := DEFAULT_LEAGUE
  else
      Result := GameInfo.League;
end;

{ TGameInformation }

constructor TGameInformation.Create;
begin
  Mutators := TList<TMutatorMetaInfo>.Create;
end;

destructor TGameInformation.Destroy;
begin
  Mutators.Free;
  inherited;
end;

function TGameInformation.IsDuo : boolean;
begin
  Result := HScenario.IsDuo(ScenarioUID);
end;

function TGameInformation.IsPvE : boolean;
begin
  Result := HScenario.IsPvEScenario(ScenarioUID);
end;

function TGameInformation.IsPvP : boolean;
begin
  Result := HScenario.IsPvP(ScenarioUID);
end;

function TGameInformation.IsSandbox : boolean;
begin
  Result := HScenario.IsSandbox(ScenarioUID) or IsSandboxOverride;
end;

function TGameInformation.IsSingle : boolean;
begin
  Result := HScenario.IsSingle(ScenarioUID);
end;

function TGameInformation.IsTeamMode : boolean;
begin
  Result := HScenario.IsTeamMode(ScenarioUID);
end;

function TGameInformation.IsTutorial : boolean;
begin
  Result := HScenario.IsTutorial(ScenarioUID);
end;

initialization

ScriptManager.ExposeClass(TGame);

end.
