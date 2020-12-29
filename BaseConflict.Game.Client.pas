unit BaseConflict.Game.Client;

interface

uses
  System.UITypes,
  generics.Collections,
  generics.defaults,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  BaseConflict.Constants,
  BaseConflict.Constants.Scenario,
  Engine.Terrain,
  {$IFDEF DEBUG}
  Engine.Terrain.Editor,
  {$ENDIF}
  Engine.Serializer,
  Engine.Collision,
  Engine.Core,
  Engine.Script,
  Engine.Network,
  BaseConflict.Entity,
  BaseConflict.Game,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Client,
  BaseConflict.Map,
  BaseConflict.Map.Client,
  BaseConflict.Types.Client,
  SysUtils,
  Vcl.Dialogs,
  Math,
  RTTI,
  Vcl.Forms;

type

  {$RTTI EXPLICIT METHODS([vcPublic]) FIELDS([vcProtected,vcPublic]) PROPERTIES([vcProtected, vcPublic])}

  [ScriptExcludeAll]
  TClientGame = class(TGame)
    protected
      FGameState : EnumGameStatus;
      FTokenMapping : TList<integer>;
      FClientMap : TClientMap;
      FClientNetworkComponent : TClientNetworkComponent;
      FClientInputComponent : TClientInputComponent;
      procedure OnTokenMapping(TokenMapping : TList<integer>);
      procedure FinishedReceiveGameData;
    public
      MinimapManager : TMiniMapComponent;
      CommanderManager : TCommanderManagerComponent;
      DecayManager : TUnitDecayManagerComponent;
      TraceManager : TVertexTraceManagerComponent;
      BuildgridManager : TBuildGridManagerComponent;
      property GameState : EnumGameStatus read FGameState write FGameState;
      function IsReady : boolean;
      function IsRunning : boolean;
      function IsFinished : boolean;
      [ScriptIncludeMember]
      property ClientMap : TClientMap read FClientMap;
      constructor Create(GameInfo : TGameInformation; Socket : TTCPClientSocketDeluxe; const AuthentificationToken : string; TokenMapping : TList<integer>);
      function Ping : integer;
      procedure Initialize; override;
      procedure Idle; override;
      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals,
  BaseConflict.Globals.Client,
  BaseConflict.EntityComponents.Client.GUI,
  BaseConflict.EntityComponents.Client.Sound;

{ TClientGame }

constructor TClientGame.Create(GameInfo : TGameInformation; Socket : TTCPClientSocketDeluxe; const AuthentificationToken : string; TokenMapping : TList<integer>);
var
  Map : string;
begin
  inherited Create(GameInfo);
  FGameState := gsPreparing;
  FTokenMapping := TokenMapping;

  if FGameInfo.Scenario.MapName <> '' then
  begin
    Map := FormatDateiPfad(PATH_MAP + FGameInfo.Scenario.MapName + '\' + FGameInfo.Scenario.MapName + '.bcm');
    FClientMap := TClientMap.CreateFromFile(Map);
    BaseConflict.Globals.Client.ClientMap := FClientMap;
  end
  else raise EFileNotFoundException.Create('TClientGame.Create: Mapname should not be empty!');

  CollisionManager := TCollisionManagerComponent.Create(GameEntity);
  FEntityManager := TClientEntityManagerComponent.Create(GameEntity);
  FClientNetworkComponent := TClientNetworkComponent.Create(GameEntity, Socket, AuthentificationToken, FinishedReceiveGameData);
  FClientInputComponent := TClientInputComponent.Create(GameEntity);
  TClientCameraComponent.Create(GameEntity);
  TClientGUIComponent.Create(GameEntity);
  TGameSoundManagerComponent.Create(GameEntity);
  CommanderManager := TCommanderManagerComponent.Create(GameEntity);
  DecayManager := TUnitDecayManagerComponent.Create(GameEntity);
  TraceManager := TVertexTraceManagerComponent.Create(GameEntity);

  MinimapManager := TMiniMapComponent.Create(GameEntity);
  if FGameInfo.Scenario.MapName = 'Single' then
      MinimapManager.Minimap.IsSingleMap;

  Initialize;
  // build zones are set by scripts in initialize
  BuildgridManager := TBuildGridManagerComponent.Create(GameEntity);
end;

destructor TClientGame.Destroy;
begin
  FTokenMapping.Free;
  FClientMap.Free;
  FClientInputComponent.ClearAction;
  BaseConflict.Globals.Client.ClientMap := nil;
  inherited;
end;

procedure TClientGame.FinishedReceiveGameData;
begin
  OnTokenMapping(FTokenMapping);
end;

procedure TClientGame.Idle;
begin
  ClientMap.Idle;
  inherited;
end;

procedure TClientGame.Initialize;
begin
  inherited;
end;

function TClientGame.IsFinished : boolean;
begin
  Result := GameState in [gsAborted, gsCrashed, gsFinished];
end;

function TClientGame.IsReady : boolean;
begin
  Result := not(GameState in [gsPreparing]);
end;

function TClientGame.IsRunning : boolean;
begin
  Result := GameState in [gsPreparing, gsRunning, gsReconnecting];
end;

procedure TClientGame.OnTokenMapping(TokenMapping : TList<integer>);
var
  i : integer;
  Entity : TEntity;
begin
  CommanderManager.ClearCommanders;
  for i := 0 to TokenMapping.Count - 1 do
  begin
    Entity := EntityManager.GetEntityByID(TokenMapping[i]);
    GlobalEventbus.Trigger(eiNewCommander, [Entity]);
  end;
  GameState := gsRunning;
end;

function TClientGame.Ping : integer;
begin
  Result := FClientNetworkComponent.Ping;
end;

initialization

ScriptManager.ExposeClass(TClientGame);

end.
