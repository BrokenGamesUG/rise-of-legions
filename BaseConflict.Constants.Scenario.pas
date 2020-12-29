unit BaseConflict.Constants.Scenario;

interface

uses
  Generics.Collections,
  SysUtils,
  RegularExpressions,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  Engine.Helferlein;

type
  /// <summary> Contains info about a scenario. </summary>
  TScenarioMetaInfo = class
    public
      ScenarioScriptfile : TList<string>;
      MapName : string;
      constructor Create;
      function Clone : TScenarioMetaInfo;
      destructor Destroy; override;
  end;

  /// <summary> Contains info about a mutator. </summary>
  TMutatorMetaInfo = class
    public
      MutatorScriptfile : TList<string>;
      constructor Create;
      destructor Destroy; override;
  end;

  HScenario = class
    public
      class function ResolveScenario(const ScenarioUID : string; League : integer) : TScenarioMetaInfo; static;
      class function IsPvEScenario(const ScenarioUID : string) : boolean; static;
      class function IsPvP(const ScenarioUID : string) : boolean; static;
      class function IsDuel(const ScenarioUID : string) : boolean; static;
      class function IsSingle(const ScenarioUID : string) : boolean; static;
      class function IsDuo(const ScenarioUID : string) : boolean; static;
      class function IsTeamMode(const ScenarioUID : string) : boolean; static;
      class function IsTutorial(const ScenarioUID : string) : boolean; static;
      class function IsSandbox(const ScenarioUID : string) : boolean; static;
      class function ResolveMutator(const MutatorUID : string) : TMutatorMetaInfo; static;
  end;

  TScenarioInfoManager = class
    strict private
    const
      PVP_SCENARIO_SCRIPTS : array [0 .. 3] of string = ('PvPBase.dws', 'PvPRed.dws', 'PvPBlue.dws', 'Game.dws');
    strict private
      FServerScenarioMapping : TObjectDictionary<string, TObjectDictionary<integer, TScenarioMetaInfo>>;
      FServerMutatorMapping : TObjectDictionary<string, TMutatorMetaInfo>;
    public
      constructor Create;
      procedure AddMutator(const MutatorUID : string; MutatorInfo : TMutatorMetaInfo);
      procedure AddScenario(const ScenarioUID : string; League : integer; MetaInfo : TScenarioMetaInfo);
      procedure AddScenarioForAllLeagues(const ScenarioUID : string; MetaInfo : TScenarioMetaInfo);

      /// <summary> PvP-Scenarios have all the same files and are created for all leagues. </summary>
      procedure AddPvPScenario(const ScenarioUID, MapName : string); overload;
      procedure AddPvPScenario(const ScenarioUID : string; AdditionalScripts : array of string; const MapName : string); overload;

      function ResolveScenario(const ScenarioUID : string; League : integer) : TScenarioMetaInfo;
      function ResolveMutator(const MutatorUID : string) : TMutatorMetaInfo;
      destructor Destroy; override;
  end;

const
  MAP_SINGLE = 'Single';
  MAP_DOUBLE = 'Classic';

  SCENARIO_DEBUG_UID           = 'debug';
  SCENARIO_PERFORMANCE_TEST    = 'performance_test';
  SCENARIO_SANDBOX_UID         = 'sandbox';
  SCENARIO_SANDBOX_DUO_UID     = 'sandbox_duo';
  SCENARIO_SANDBOX_CLASSIC_UID = 'sandbox_classic';
  SCENARIO_PVP_TEST_UID        = 'pvp_test';

  SCENARIO_PVE_TUTORIAL = 'tutorial';

  SCENARIO_PVP_DUEL_PREFIX        = 'duel';
  SCENARIO_PVP_DUEL_1VS1          = SCENARIO_PVP_DUEL_PREFIX;
  SCENARIO_PVP_DUEL_1VS1_TWO_LANE = 'two_lane_' + SCENARIO_PVP_DUEL_1VS1;
  SCENARIO_PVP_DUEL_2VS2          = 'duel2v2';
  SCENARIO_PVP_DUEL_2VS2_TWO_LANE = 'two_lane_' + SCENARIO_PVP_DUEL_2VS2;
  SCENARIO_PVP_DUEL_3VS3          = 'duel3v3';
  SCENARIO_PVP_DUEL_3VS3_TWO_LANE = 'two_lane_' + SCENARIO_PVP_DUEL_3VS3;
  SCENARIO_PVP_DUEL_4VS4          = 'duel4v4';
  SCENARIO_PVP_DUEL_4VS4_TWO_LANE = 'two_lane_' + SCENARIO_PVP_DUEL_4VS4;
  SCENARIO_PVP_1VS1               = '1vs1';
  SCENARIO_PVP_1VS1_TWO_LANE      = 'two_lane_' + SCENARIO_PVP_1VS1;
  SCENARIO_PVP_2VS2               = '2vs2';
  SCENARIO_PVP_2VS2_TWO_LANE      = 'two_lane_' + SCENARIO_PVP_2VS2;
  SCENARIO_PVP_3VS3               = '3vs3';
  SCENARIO_PVP_3VS3_TWO_LANE      = 'two_lane_' + SCENARIO_PVP_3VS3;
  SCENARIO_PVP_4VS4               = '4vs4';
  SCENARIO_PVP_4VS4_TWO_LANE      = 'two_lane_' + SCENARIO_PVP_4VS4;
  SCENARIO_PVP_1VS1_RANKED        = 'ranked' + SCENARIO_PVP_1VS1;
  SCENARIO_PVP_2VS2_RANKED        = 'ranked' + SCENARIO_PVP_2VS2;
  SCENARIO_PVP_3VS3_RANKED        = 'ranked' + SCENARIO_PVP_3VS3;
  SCENARIO_PVP_4VS4_RANKED        = 'ranked' + SCENARIO_PVP_4VS4;

  SCENARIO_PVE_DEFAULT_PREFIX = 'pve_';
  SCENARIO_PVE_DEFAULT        = 'pve_attack_solo';
  SCENARIO_PVE_ATTACK_SOLO    = SCENARIO_PVE_DEFAULT_PREFIX + 'attack_solo';
  SCENARIO_PVE_ATTACK_DUO     = SCENARIO_PVE_DEFAULT_PREFIX + 'attack';

  SCENARIO_DEBUG_META_TEST = 'META_TEST';
  SCENARIO_DEBUG_IDLE      = 'IDLE_GAME';

var
  ScenarioInfoManager : TScenarioInfoManager;
  // gamemode that is created on testserver
  TESTSERVER_SCENARIO_UID : string    = SCENARIO_SANDBOX_UID;
  TESTSERVER_SENARIO_LEAGUE : integer = 1;

implementation

function s(ScenarioScriptfiles : array of string; MapName : string) : TScenarioMetaInfo;
var
  i : integer;
begin
  Result := TScenarioMetaInfo.Create;
  Result.MapName := MapName;
  for i := 0 to length(ScenarioScriptfiles) - 1 do
      Result.ScenarioScriptfile.Add(PATH_SCRIPT_SCENARIO + ScenarioScriptfiles[i]);
end;

function m(MutatorScriptfiles : array of string) : TMutatorMetaInfo;
var
  i : integer;
begin
  Result := TMutatorMetaInfo.Create;
  for i := 0 to length(MutatorScriptfiles) - 1 do
      Result.MutatorScriptfile.Add(PATH_SCRIPT_SCENARIO_MUTATOR + MutatorScriptfiles[i]);
end;

{ TScenarioMetaInfo }

function TScenarioMetaInfo.Clone : TScenarioMetaInfo;
begin
  Result := TScenarioMetaInfo.Create;
  Result.ScenarioScriptfile.AddRange(Self.ScenarioScriptfile);
  Result.MapName := Self.MapName;
end;

constructor TScenarioMetaInfo.Create;
begin
  ScenarioScriptfile := TList<string>.Create;
end;

destructor TScenarioMetaInfo.Destroy;
begin
  ScenarioScriptfile.Free;
  inherited;
end;

{ TMutatorMetaInfo }

constructor TMutatorMetaInfo.Create;
begin
  MutatorScriptfile := TList<string>.Create;
end;

destructor TMutatorMetaInfo.Destroy;
begin
  MutatorScriptfile.Free;
  inherited;
end;

{ HScenario }

class function HScenario.IsDuel(const ScenarioUID : string) : boolean;
begin
  Result := ScenarioUID.Contains(SCENARIO_PVP_DUEL_PREFIX);
end;

class function HScenario.IsDuo(const ScenarioUID : string) : boolean;
begin
  Result := ScenarioUID.EndsWith(SCENARIO_PVP_2VS2) or
    ScenarioUID.EndsWith(SCENARIO_PVP_3VS3) or
    ScenarioUID.EndsWith(SCENARIO_PVP_4VS4) or
    ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_2VS2) or
    ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_2VS2_TWO_LANE) or
    ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_3VS3) or
    ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_3VS3_TWO_LANE) or
    ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_4VS4) or
    ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_4VS4_TWO_LANE) or
    ScenarioUID.EndsWith(SCENARIO_PVE_ATTACK_DUO) or
    ScenarioUID.EndsWith(SCENARIO_SANDBOX_DUO_UID);
end;

class function HScenario.IsPvEScenario(const ScenarioUID : string) : boolean;
begin
  Result := ScenarioUID.Contains(SCENARIO_PVE_DEFAULT_PREFIX) or ScenarioUID.Contains(SCENARIO_PVE_TUTORIAL);
end;

class function HScenario.IsPvP(const ScenarioUID : string) : boolean;
begin
  Result := ScenarioUID.EndsWith(SCENARIO_PVP_1VS1) or
    ScenarioUID.EndsWith(SCENARIO_PVP_2VS2) or
    ScenarioUID.EndsWith(SCENARIO_PVP_3VS3) or
    ScenarioUID.EndsWith(SCENARIO_PVP_4VS4) or
    HScenario.IsDuel(ScenarioUID) or
    ScenarioUID.EndsWith(SCENARIO_SANDBOX_UID) or
    ScenarioUID.EndsWith(SCENARIO_SANDBOX_DUO_UID) or
    ScenarioUID.EndsWith(SCENARIO_SANDBOX_CLASSIC_UID);
end;

class function HScenario.IsSandbox(const ScenarioUID : string) : boolean;
begin
  Result := ScenarioUID.Contains(SCENARIO_SANDBOX_UID);
end;

class function HScenario.IsSingle(const ScenarioUID : string) : boolean;
begin
  Result := not IsDuo(ScenarioUID);
end;

class function HScenario.IsTeamMode(const ScenarioUID : string) : boolean;
begin
  Result := ScenarioUID.EndsWith(SCENARIO_PVP_2VS2) or
    ScenarioUID.EndsWith(SCENARIO_PVP_3VS3) or
    ScenarioUID.EndsWith(SCENARIO_PVP_4VS4) or
    (ScenarioUID.Contains(SCENARIO_PVP_DUEL_PREFIX) and
    not ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_1VS1) and
    not ScenarioUID.EndsWith(SCENARIO_PVP_DUEL_1VS1_TWO_LANE)
    ) or
    ScenarioUID.EndsWith(SCENARIO_SANDBOX_DUO_UID) or
    ScenarioUID.EndsWith(SCENARIO_SANDBOX_CLASSIC_UID);
end;

class function HScenario.IsTutorial(const ScenarioUID : string) : boolean;
begin
  Result := ScenarioUID.Contains(SCENARIO_PVE_TUTORIAL);
end;

class function HScenario.ResolveMutator(const MutatorUID : string) : TMutatorMetaInfo;
begin
  Result := ScenarioInfoManager.ResolveMutator(MutatorUID);
end;

class function HScenario.ResolveScenario(const ScenarioUID : string; League : integer) : TScenarioMetaInfo;
begin
  Result := ScenarioInfoManager.ResolveScenario(ScenarioUID, League);
end;

{ TScenarioInfoManager }

procedure TScenarioInfoManager.AddMutator(const MutatorUID : string; MutatorInfo : TMutatorMetaInfo);
begin
  FServerMutatorMapping.Add(MutatorUID, MutatorInfo);
end;

procedure TScenarioInfoManager.AddPvPScenario(const ScenarioUID, MapName : string);
begin
  AddPvPScenario(ScenarioUID, [], MapName);
end;

procedure TScenarioInfoManager.AddPvPScenario(const ScenarioUID : string; AdditionalScripts : array of string; const MapName : string);
begin
  AddScenarioForAllLeagues(ScenarioUID, s(HArray.ConvertDynamicToTArray<string>(AdditionalScripts) + HArray.ConvertDynamicToTArray<string>(PVP_SCENARIO_SCRIPTS), MapName));
end;

procedure TScenarioInfoManager.AddScenario(const ScenarioUID : string; League : integer; MetaInfo : TScenarioMetaInfo);
var
  LeagueDict : TObjectDictionary<integer, TScenarioMetaInfo>;
begin
  if not FServerScenarioMapping.TryGetValue(ScenarioUID, LeagueDict) then
  begin
    LeagueDict := TObjectDictionary<integer, TScenarioMetaInfo>.Create([doOwnsValues]);
    FServerScenarioMapping.Add(ScenarioUID, LeagueDict);
  end;
  LeagueDict.Add(League, MetaInfo);
end;

procedure TScenarioInfoManager.AddScenarioForAllLeagues(const ScenarioUID : string; MetaInfo : TScenarioMetaInfo);
var
  i : integer;
begin
  for i := 1 to MAX_LEAGUE do
      AddScenario(ScenarioUID, i, MetaInfo.Clone);
  MetaInfo.Free;
end;

constructor TScenarioInfoManager.Create;
begin
  FServerScenarioMapping := TObjectDictionary < string, TObjectDictionary < integer, TScenarioMetaInfo >>.Create([doOwnsValues]);
  FServerMutatorMapping := TObjectDictionary<string, TMutatorMetaInfo>.Create([doOwnsValues]);
end;

destructor TScenarioInfoManager.Destroy;
begin
  FServerScenarioMapping.Free;
  FServerMutatorMapping.Free;
  inherited;
end;

function TScenarioInfoManager.ResolveMutator(const MutatorUID : string) : TMutatorMetaInfo;
begin
  Result := ScenarioInfoManager.FServerMutatorMapping[MutatorUID.ToLowerInvariant];
end;

function TScenarioInfoManager.ResolveScenario(const ScenarioUID : string; League : integer) : TScenarioMetaInfo;
begin
  assert(FServerScenarioMapping.ContainsKey(ScenarioUID.ToLowerInvariant), 'HScenario.ResolveScenario: Could not find scenario UID ' + ScenarioUID);
  assert(FServerScenarioMapping[ScenarioUID.ToLowerInvariant].ContainsKey(League), 'HScenario.ResolveScenario: Could not find league ' + Inttostr(League) + ' in scenario with UID ' + ScenarioUID);
  Result := FServerScenarioMapping[ScenarioUID.ToLowerInvariant][League];
end;

initialization

ScenarioInfoManager := TScenarioInfoManager.Create;

// ATTENTION : The order of the scripts is important and will be loaded from right to left.
ScenarioInfoManager.AddPvPScenario(SCENARIO_SANDBOX_UID, ['Sandbox.dws'], MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_SANDBOX_DUO_UID, ['Sandbox.dws'], MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_SANDBOX_CLASSIC_UID, ['Sandbox.dws'], MAP_DOUBLE);

ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_1VS1, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_1VS1_TWO_LANE, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_2VS2, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_2VS2_TWO_LANE, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_3VS3, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_3VS3_TWO_LANE, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_4VS4, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_DUEL_4VS4_TWO_LANE, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_1VS1, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_1VS1_TWO_LANE, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_2VS2, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_2VS2_TWO_LANE, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_3VS3, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_3VS3_TWO_LANE, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_4VS4, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_4VS4_TWO_LANE, MAP_DOUBLE);

ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_1VS1_RANKED, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_2VS2_RANKED, MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_3VS3_RANKED, MAP_DOUBLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_4VS4_RANKED, MAP_DOUBLE);

ScenarioInfoManager.AddScenario(SCENARIO_PVE_TUTORIAL, 1, s(['TutorialVeryEasy.dws', 'Game.dws'], MAP_SINGLE));

ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_SOLO, 1, s(['AttackScenarioVeryEasy.dws', 'AttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_SOLO, 2, s(['AttackScenarioEasy.dws', 'AttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_SOLO, 3, s(['AttackScenarioMedium.dws', 'AttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_SOLO, 4, s(['AttackScenarioHard.dws', 'AttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_SOLO, 5, s(['AttackScenarioVeryHard.dws', 'AttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));

ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_DUO, 1, s(['AttackDuoScenarioVeryEasy.dws', 'AttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_DUO, 2, s(['AttackDuoScenarioEasy.dws', 'AttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_DUO, 3, s(['AttackDuoScenarioMedium.dws', 'AttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_DUO, 4, s(['AttackDuoScenarioHard.dws', 'AttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_ATTACK_DUO, 5, s(['AttackDuoScenarioVeryHard.dws', 'AttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));

ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_UID, 1, s(['Sandbox.dws', 'SandboxAttackScenarioVeryEasy.dws', 'SandboxAttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_UID, 2, s(['Sandbox.dws', 'SandboxAttackScenarioEasy.dws', 'SandboxAttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_UID, 3, s(['Sandbox.dws', 'SandboxAttackScenarioMedium.dws', 'SandboxAttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_UID, 4, s(['Sandbox.dws', 'SandboxAttackScenarioHard.dws', 'SandboxAttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_UID, 5, s(['Sandbox.dws', 'SandboxAttackScenarioVeryHard.dws', 'SandboxAttackScenarioBase.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_CLASSIC_UID, 1, s(['Sandbox.dws', 'SandboxAttackDuoScenarioVeryEasy.dws', 'SandboxAttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_CLASSIC_UID, 2, s(['Sandbox.dws', 'SandboxAttackDuoScenarioEasy.dws', 'SandboxAttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_CLASSIC_UID, 3, s(['Sandbox.dws', 'SandboxAttackDuoScenarioMedium.dws', 'SandboxAttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_CLASSIC_UID, 4, s(['Sandbox.dws', 'SandboxAttackDuoScenarioHard.dws', 'SandboxAttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + SCENARIO_SANDBOX_CLASSIC_UID, 5, s(['Sandbox.dws', 'SandboxAttackDuoScenarioVeryHard.dws', 'SandboxAttackDuoScenarioBase.dws', 'Game.dws'], MAP_DOUBLE));

// debug scenarios
ScenarioInfoManager.AddPvPScenario(SCENARIO_DEBUG_UID, ['Debug.dws'], MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PVP_TEST_UID, ['PvPBase.dws'], MAP_SINGLE);
ScenarioInfoManager.AddPvPScenario(SCENARIO_PERFORMANCE_TEST, ['PerformanceTest.dws'], MAP_SINGLE);
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + 'core_test_1', 5, s(['CoreTest1.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + 'core_test_2', 5, s(['CoreTest2.dws', 'Game.dws'], MAP_SINGLE));
ScenarioInfoManager.AddScenario(SCENARIO_PVE_DEFAULT_PREFIX + 'core_test_3', 5, s(['CoreTest3.dws', 'Game.dws'], MAP_SINGLE));

ScenarioInfoManager.AddMutator('highly_explosive', m(['HighlyExplosive.dws']));
ScenarioInfoManager.AddMutator('gigantic', m(['Gigantic.dws']));

finalization

FreeAndNil(ScenarioInfoManager);

end.
