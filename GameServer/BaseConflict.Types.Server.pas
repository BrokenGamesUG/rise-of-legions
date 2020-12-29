unit BaseConflict.Types.Server;

interface

uses
  // Delphi
  System.Generics.Collections,
  // Engine
  // Game
  BaseConflict.Game,
  BaseConflict.Entity,
  BaseConflict.Api.Types,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.EntityComponents.Shared;

type

  /// <summary> A target with a computed efficiency of a wela for this target. </summary>
  RTargetWithEfficiency = record
    Target : RTarget;
    Efficiency : single;
    constructor Create(Target : RTarget; Efficiency : single);
  end;

  /// <summary> A procedure which can set specific things or create components for a freshly spawned unit. </summary>
  ProcSetUpEntity = reference to procedure(Entity : TEntity);

  TGamePlayer = class
    public
      PlayerID, TeamID : integer;
      Name, Token : string;
      IsBot : boolean;
      constructor Create(PlayerID : integer; TeamID : integer; const Name : string);
  end;

  TCommanderInformation = class
    /// <summary> Team to which the player belongs, 1 or 2, (0 are neutral)</summary>
    TeamID : integer;
    IsBot, IsSpectator : boolean;
    BotDifficulty : integer;
    /// <summary> Any name of the deck.</summary>
    Deckname : string;
    Cards : TList<RCommanderCard>;
    constructor Create;
    constructor CreateSpectator;
    destructor Destroy; override;
  end;

  TServerGameInformation = class(TGameInformation)
    CoopVsAI : boolean;
    // Token => real user
    Player : TObjectDictionary<string, TGamePlayer>;
    // SlotIndex => RCommanderInformation
    Slots : TObjectList<TCommanderInformation>;
    // Token => Slots
    Mapping : TDictionary<string, TList<integer>>;
    /// <summary> GameID given by gameserver, required to report closed games.</summary>
    GameID : string;
    GamePort : Word;
    constructor Create();
    procedure AddPlayer(const Token : string; const GamePlayer : TGamePlayer);
    procedure UpdateGamePlayers;
    function TokenToTeamID(const Token : string) : integer;
    function RealPlayerCount : integer;
    destructor Destroy; override;
  end;

implementation

{ RTargetWithEfficiency }

constructor RTargetWithEfficiency.Create(Target : RTarget; Efficiency : single);
begin
  self.Target := Target;
  self.Efficiency := Efficiency;
end;

{ TGamePlayer }

constructor TGamePlayer.Create(PlayerID : integer; TeamID : integer; const Name : string);
begin
  self.PlayerID := PlayerID;
  self.Name := name;
  self.TeamID := TeamID;
end;

{ TServerGameInformation }

procedure TServerGameInformation.AddPlayer(const Token : string; const GamePlayer : TGamePlayer);
begin
  GamePlayer.Token := Token;
  self.Player.Add(Token, GamePlayer);
end;

constructor TServerGameInformation.Create;
begin
  inherited;
  Player := TObjectDictionary<string, TGamePlayer>.Create([doOwnsValues]);
  Slots := TObjectList<TCommanderInformation>.Create;
  Mapping := TObjectDictionary < string, TList < integer >>.Create([doOwnsValues]);
end;

destructor TServerGameInformation.Destroy;
begin
  Player.Free;
  Slots.Free;
  Mapping.Free;
  inherited;
end;

function TServerGameInformation.RealPlayerCount : integer;
var
  Token : string;
begin
  Result := 0;
  for Token in Player.Keys do
    if not Player[Token].IsBot then
        inc(Result);
end;

function TServerGameInformation.TokenToTeamID(const Token : string) : integer;
var
  CommandersList : TList<integer>;
  i : integer;
begin
  Result := -1;
  if Mapping.TryGetValue(Token, CommandersList) then
  begin
    for i := 0 to CommandersList.Count - 1 do
      if CommandersList[i] < Slots.Count then
          exit(Slots[CommandersList[i]].TeamID);
  end;
end;

procedure TServerGameInformation.UpdateGamePlayers;
var
  IsBotPlayer : boolean;
  Token : string;
  ControlledCommanders : TList<integer>;
  i, TeamID : integer;
begin
  for Token in Mapping.Keys do
  begin
    IsBotPlayer := False;
    TeamID := -1;
    ControlledCommanders := Mapping[Token];
    for i := 0 to ControlledCommanders.Count - 1 do
    begin
      IsBotPlayer := IsBotPlayer or Slots[ControlledCommanders[i]].IsBot;
      if i = 0 then
          TeamID := Slots[ControlledCommanders[i]].TeamID;
    end;
    if Player.ContainsKey(Token) then
    begin
      Player[Token].IsBot := IsBotPlayer;
      Player[Token].TeamID := TeamID;
    end;
  end;
end;

{ TCommanderInformation }

constructor TCommanderInformation.Create;
begin
  Cards := TList<RCommanderCard>.Create;
end;

constructor TCommanderInformation.CreateSpectator;
begin
  TeamID := 0;
  IsSpectator := True;
  Create;
end;

destructor TCommanderInformation.Destroy;
begin
  Cards.Free;
  inherited;
end;

end.
