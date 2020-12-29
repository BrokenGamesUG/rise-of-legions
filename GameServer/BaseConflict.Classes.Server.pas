unit BaseConflict.Classes.Server;

interface

uses
  Math,
  Generics.Collections,
  SysUtils,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Log,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Globals,
  BaseConflict.Api.Types;

type

  TGameStatisticManager = class
    strict private
      // CommanderID -> (GameEventIdentifier -> Count)
      FCommanderStatistics : TObjectDictionary<integer, TDictionary<string, integer>>;
      // CommanderID -> PlayerName
      FPlayer : TDictionary<integer, integer>;

      function CountEvent(CommanderID : integer; const Identifier : string; Times : integer = 1) : integer;
      function MaxEvent(CommanderID : integer; const Identifier : string; Times : integer = 1) : integer;
      procedure GetStatistics(CommanderID : integer; const Identifier : string; out Dict : TDictionary<string, integer>; out CurrentValue : integer);
      function SanitizeScriptFileName(const ScriptFileName : string) : string;
    public
      // --- Unit related events -----------------------------------------------------------------
      /// <summary> Triggered whenever a unit is spawned. </summary>
      procedure UnitSpawned(CommanderID : integer; const ScriptFileName : string);
      /// <summary> Triggered whenever a unit has killed another unit. </summary>
      procedure UnitKills(CommanderID : integer; const ScriptFileName : string);
      /// <summary> Triggered whenever a unit died. </summary>
      procedure UnitDeaths(CommanderID : integer; const ScriptFileName : string);

      // --- Wela related events -----------------------------------------------------------------
      /// <summary> Triggered whenever a unit has spawned while having a certain ability. </summary>
      procedure WelaSpawns(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Triggered whenever a unit has died while having a certain ability. </summary>
      procedure WelaDeaths(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Triggered whenever a unit has killed another one while having a certain ability. </summary>
      procedure WelaKills(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Triggered whenever a certain ability is executed. </summary>
      procedure WelaTriggers(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Counts the targets affected by a certain ability. </summary>
      procedure WelaTargets(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Triggered whenever a unit has gained damage summing the damage, while having a certain ability. </summary>
      procedure WelaDamage(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Triggered whenever a unit has gained damage summing the damage, while having a certain ability. </summary>
      procedure WelaDamageMax(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Triggered whenever a unit has dealt damage summing the damage, while having a certain ability. </summary>
      procedure WelaDealtDamage(CommanderID : integer; const AbilityName : string; Times : integer);
      /// <summary> Triggered whenever a unit dies summing the living time, while having a certain ability. </summary>
      procedure WelaDuration(CommanderID : integer; const AbilityName : string; Times : integer);

      // --- Global events -----------------------------------------------------------------------
      /// <summary> Triggered whenever a spawner has been placed. </summary>
      procedure GlobalSpawners(CommanderID : integer);
      /// <summary> Triggered whenever a drop has been played. </summary>
      procedure GlobalDrops(CommanderID : integer);
      /// <summary> Triggered whenever a building has been spawned. </summary>
      procedure GlobalBuildings(CommanderID : integer);
      /// <summary> Triggered whenever a spell has been cast. </summary>
      procedure GlobalSpells(CommanderID : integer);

      /// <summary> Triggered whenever a unit has been spawned. </summary>
      procedure GlobalSpawns(CommanderID : integer);
      /// <summary> Triggered whenever a unit has killed another unit. </summary>
      procedure GlobalKills(CommanderID : integer);
      /// <summary> Triggered whenever a unit died. </summary>
      procedure GlobalDeaths(CommanderID : integer);
      /// <summary> Triggered whenever a unit died from full health. </summary>
      procedure GlobalInstaDeaths(CommanderID : integer);
      /// <summary> Triggered whenever a unit has been killed from full health. </summary>
      procedure GlobalInstaKills(CommanderID : integer);
      /// <summary> Triggered whenever a unit has gained damage summing the damage. </summary>
      procedure GlobalDamage(CommanderID : integer; Times : integer);
      /// <summary> Triggered whenever a commander uses a card. </summary>
      procedure CardPlayed(CommanderID : integer; const ScriptFileName : string);

      procedure AddCommander(CommanderID : integer; PlayerID : integer);
      procedure BuildStatistics(var Statistics : RGameFinishedStatistics);

      constructor Create;
      destructor Destroy; override;
  end;

  /// <summary> A delayed event called by the main game loop if timestamp has been reached. </summary>
  TDelayedEventHandler = class
    protected
      FInQueue : TIntPriorityQueue<TDelayedEventHandler>;
      FCallback : ProcOfObject;
    public
      constructor Create(Callback : ProcOfObject);
      procedure Callback;
      function IsWaiting : boolean;
      procedure RegisterEvent(const TimeToEvent : Int64);
      procedure UnregisterEvent();
      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals.Server;

{ TGameStatisticManager }

procedure TGameStatisticManager.AddCommander(CommanderID : integer; PlayerID : integer);
begin
  FPlayer.AddOrSetValue(CommanderID, PlayerID);
  CountEvent(CommanderID, 'commander_created');
end;

procedure TGameStatisticManager.BuildStatistics(var Statistics : RGameFinishedStatistics);
var
  CommanderStatistics : RGameCommanderStatistics;
  PlayerID, CommanderID : integer;
  GameEventIdentifier : string;
  GameEvent : RGameStatisticsGameEvent;
begin
  Statistics.duration := GlobalEventbus.Read(eiGameTickCounter, []).AsInteger;
  Statistics.commander_statistics := nil;
  for CommanderID in FCommanderStatistics.Keys do
    if FPlayer.TryGetValue(CommanderID, PlayerID) then
    begin
      CommanderStatistics.player_id := PlayerID;
      CommanderStatistics.game_events := nil;
      for GameEventIdentifier in FCommanderStatistics[CommanderID].Keys do
      begin
        GameEvent.Identifier := GameEventIdentifier;
        GameEvent.count := FCommanderStatistics[CommanderID][GameEventIdentifier];
        HArray.Push<RGameStatisticsGameEvent>(CommanderStatistics.game_events, GameEvent);
      end;
      HArray.Push<RGameCommanderStatistics>(Statistics.commander_statistics, CommanderStatistics);
    end;
end;

procedure TGameStatisticManager.CardPlayed(CommanderID : integer; const ScriptFileName : string);
var
  sanitizedScriptFilename : string;
  CardColors : SetEntityColor;
  PlayCount : integer;
begin
  case CardInfoManager.ScriptFilenameToCardType(ScriptFileName) of
    ctDrop : GlobalDrops(CommanderID);
    ctSpell : GlobalSpells(CommanderID);
    ctBuilding : GlobalBuildings(CommanderID);
    ctSpawner : GlobalSpawners(CommanderID);
  else
    raise ENotImplemented.Create('TGameStatisticManager.CardPlayed: Unimplemented card type!');
  end;
  CardColors := CardInfoManager.ScriptFilenameToCardColors(ScriptFileName);
  if ecColorless in CardColors then CountEvent(CommanderID, GSE_CARD_PLAY_COLOR_PREFIX + 'colorless');
  if ecBlack in CardColors then CountEvent(CommanderID, GSE_CARD_PLAY_COLOR_PREFIX + 'black');
  if ecGreen in CardColors then CountEvent(CommanderID, GSE_CARD_PLAY_COLOR_PREFIX + 'green');
  if ecRed in CardColors then CountEvent(CommanderID, GSE_CARD_PLAY_COLOR_PREFIX + 'red');
  if ecBlue in CardColors then CountEvent(CommanderID, GSE_CARD_PLAY_COLOR_PREFIX + 'blue');
  if ecWhite in CardColors then CountEvent(CommanderID, GSE_CARD_PLAY_COLOR_PREFIX + 'white');

  // remove alternates for now
  sanitizedScriptFilename := HString.Replace(ScriptFileName, ['_White', '_Green', '_Black', '_Red', '_Blue', '.sps']);
  sanitizedScriptFilename := sanitizedScriptFilename.Remove(0, sanitizedScriptFilename.LastDelimiter('/\') + 1);
  PlayCount := CountEvent(CommanderID, GSE_CARD_PLAY_PREFIX + sanitizedScriptFilename);
  MaxEvent(CommanderID, GSE_CARD_PLAY_PREFIX + 'countoftype', PlayCount);
end;

procedure TGameStatisticManager.GetStatistics(CommanderID : integer; const Identifier : string; out Dict : TDictionary<string, integer>; out CurrentValue : integer);
var
  EventDict : TDictionary<string, integer>;
  CurrentCount : integer;
begin
  if not FCommanderStatistics.TryGetValue(CommanderID, EventDict) then
  begin
    EventDict := TDictionary<string, integer>.Create;
    FCommanderStatistics.Add(CommanderID, EventDict);
  end;
  if not EventDict.TryGetValue(Identifier, CurrentCount) then CurrentCount := 0;
  Dict := EventDict;
  CurrentValue := CurrentCount;
end;

function TGameStatisticManager.CountEvent(CommanderID : integer; const Identifier : string; Times : integer) : integer;
var
  EventDict : TDictionary<string, integer>;
  CurrentCount : integer;
begin
  GetStatistics(CommanderID, Identifier, EventDict, CurrentCount);
  Result := CurrentCount + Times;
  EventDict.AddOrSetValue(Identifier, Result);
  // Hlog.Console('(%d) %s: %d', [CommanderID, Identifier, CurrentCount + Times]);
end;

function TGameStatisticManager.MaxEvent(CommanderID : integer; const Identifier : string; Times : integer) : integer;
var
  EventDict : TDictionary<string, integer>;
  CurrentCount : integer;
begin
  GetStatistics(CommanderID, Identifier, EventDict, CurrentCount);
  if CurrentCount > Times then
      exit(CurrentCount);
  Result := Times;
  EventDict.AddOrSetValue(Identifier, Result);
  // Hlog.Console('(%d) %s: %d', [CommanderID, Identifier, Max(CurrentCount, Times)]);
end;

constructor TGameStatisticManager.Create;
begin
  FCommanderStatistics := TObjectDictionary < integer, TDictionary < string, integer >>.Create([doOwnsValues]);
  FPlayer := TDictionary<integer, integer>.Create;
end;

destructor TGameStatisticManager.Destroy;
begin
  FCommanderStatistics.Free;
  FPlayer.Free;
  inherited;
end;

procedure TGameStatisticManager.GlobalBuildings(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_BUILDINGS);
end;

procedure TGameStatisticManager.GlobalDamage(CommanderID, Times : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_GAIN_DAMAGE, Times);
end;

procedure TGameStatisticManager.GlobalDeaths(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_DEATHS);
end;

procedure TGameStatisticManager.GlobalDrops(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_DROPS);
end;

procedure TGameStatisticManager.GlobalInstaDeaths(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_INSTADEATHS);
end;

procedure TGameStatisticManager.GlobalInstaKills(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_INSTAKILLS);
end;

procedure TGameStatisticManager.GlobalKills(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_KILLS);
end;

procedure TGameStatisticManager.GlobalSpawners(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_SPAWNERS);
end;

procedure TGameStatisticManager.GlobalSpawns(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_SPAWNS);
end;

procedure TGameStatisticManager.GlobalSpells(CommanderID : integer);
begin
  CountEvent(CommanderID, GSE_GLOBAL_SPELLS);
end;

function TGameStatisticManager.SanitizeScriptFileName(const ScriptFileName : string) : string;
begin
  // remove alternates for now
  Result := HString.Replace(ScriptFileName, ['_White', '_Green', '_Black', '_Red', '_Blue', '.sps']);
  Result := Result.Remove(0, Result.LastDelimiter('/\') + 1);
end;

procedure TGameStatisticManager.WelaDamage(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_GAIN_DAMAGE_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaDamageMax(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  MaxEvent(CommanderID, GSE_WELA_GAIN_DAMAGE_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaDealtDamage(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_DEALT_DAMAGE_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaDeaths(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_DEATH_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaDuration(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_DURATION_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaKills(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_KILL_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaSpawns(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_SPAWN_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaTargets(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_TARGET_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.WelaTriggers(CommanderID : integer; const AbilityName : string; Times : integer);
begin
  CountEvent(CommanderID, GSE_WELA_TRIGGER_PREFIX + AbilityName, Times);
end;

procedure TGameStatisticManager.UnitDeaths(CommanderID : integer; const ScriptFileName : string);
begin
  CountEvent(CommanderID, GSE_UNIT_DEATH_PREFIX + SanitizeScriptFileName(ScriptFileName));
  GlobalDeaths(CommanderID);
end;

procedure TGameStatisticManager.UnitKills(CommanderID : integer; const ScriptFileName : string);
begin
  CountEvent(CommanderID, GSE_UNIT_KILL_PREFIX + SanitizeScriptFileName(ScriptFileName));
  GlobalKills(CommanderID);
end;

procedure TGameStatisticManager.UnitSpawned(CommanderID : integer; const ScriptFileName : string);
begin
  CountEvent(CommanderID, GSE_UNIT_SPAWN_PREFIX + SanitizeScriptFileName(ScriptFileName));
  if ScriptFileName.Contains('Building') then
      CountEvent(CommanderID, GSE_UNIT_SPAWN_PREFIX + 'building');
  if ScriptFileName.Contains('Units\') and
    not HString.ContainsSubstring([FILE_IDENTIFIER_DROP, FILE_IDENTIFIER_SPAWNER, FILE_IDENTIFIER_BUILDING], ScriptFileName) then
      GlobalSpawns(CommanderID);
end;

{ TDelayedEventHandler }

procedure TDelayedEventHandler.Callback;
begin
  if Assigned(FCallback) then FCallback;
  FInQueue := nil;
end;

constructor TDelayedEventHandler.Create(Callback : ProcOfObject);
begin
  FCallback := Callback;
end;

destructor TDelayedEventHandler.Destroy;
begin
  UnregisterEvent;
  inherited;
end;

function TDelayedEventHandler.IsWaiting : boolean;
begin
  Result := Assigned(FInQueue);
end;

procedure TDelayedEventHandler.RegisterEvent(const TimeToEvent : Int64);
begin
  assert(not IsWaiting, 'TDelayedEventHandler.RegisterEvent: Tried to register same event twice!');
  FInQueue := ServerGame.DelayedEvents;
  ServerGame.DelayedEvents.Insert(self, GameTimeManager.GetTimestamp + TimeToEvent);
end;

procedure TDelayedEventHandler.UnregisterEvent;
begin
  if IsWaiting then
  begin
    FInQueue.Remove(self);
    FInQueue := nil;
  end;
end;

end.
