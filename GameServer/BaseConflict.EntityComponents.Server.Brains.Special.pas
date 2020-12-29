unit BaseConflict.EntityComponents.Server.Brains.Special;

interface

uses
  SysUtils,
  System.Rtti,
  Generics.Collections,
  Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Script,
  BaseConflict.Map,
  BaseConflict.Types.Server,
  BaseConflict.Globals,
  BaseConflict.Constants,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Server.Brains,
  BaseConflict.EntityComponents.Server.Warheads;

type

  {$RTTI INHERIT}
  /// <summary> Handles capture points on the map. Fires to different groups if units of the specific team is near
  /// or not. </summary>
  TBrainCapturePointComponent = class(TBrainComponent)
    protected
      FFireInactive : boolean;
      FCapturingTeamID : integer;
      FIdleGroup : SetComponentGroup;
      FTeamGroups : TDictionary<integer, RTuple<SetComponentGroup, SetComponentGroup>>;
      function IsBlockedForTeam(TeamID : integer) : boolean;
      procedure Think; override;
    published
      [XEvent(eiThinkChain, epMiddle, etTrigger)]
      function OnThinkChain() : boolean;
    public
      constructor CreateGrouped(Entity : TEntity; Group : TArray<byte>); override;
      function SetTeamGroup(TeamID : integer; PositiveGroup, NegativeGroup : TArray<byte>) : TBrainCapturePointComponent;
      function SetIdleGroup(IdleGroup : TArray<byte>) : TBrainCapturePointComponent;
      destructor Destroy; override;
  end;

  /// <summary> Handles a spawner.</summary>
  TBrainSpawnerComponent = class(TBrainComponent)
    protected
      FFireNotInitially, FApplyGridOffset, FApplyRandomOffset : boolean;
      procedure Spawn;
      function BuildGridID : integer;
      function OccupiedField : RIntVector2;
    published
      [XEvent(eiGameStart, epLast, etTrigger, esGlobal)]
      function OnGameStart() : boolean;
      [XEvent(eiWaveSpawn, epMiddle, etTrigger, esGlobal)]
      function OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
      [XEvent(eiDeploy, epLast, etTrigger)]
      function OnDeploy() : boolean;
    public
      function ApplyRandomOffset : TBrainSpawnerComponent;
      function ApplyGridOffset : TBrainSpawnerComponent;
      function FireNotInitially : TBrainSpawnerComponent;
  end;

implementation

uses
  BaseConflict.Globals.Server;

{ TBrainCapturePointComponent }

constructor TBrainCapturePointComponent.CreateGrouped(Entity : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Entity, Group);
  FCapturingTeamID := -1;
  FTeamGroups := TDictionary < integer, RTuple < SetComponentGroup, SetComponentGroup >>.Create;
end;

destructor TBrainCapturePointComponent.Destroy;
begin
  FTeamGroups.Free;
  inherited;
end;

function TBrainCapturePointComponent.IsBlockedForTeam(TeamID : integer) : boolean;
begin
  Result := not Eventbus.Read(eiIsReady, [], [TeamID + 10]).AsBooleanDefaultTrue;
end;

function TBrainCapturePointComponent.OnThinkChain : boolean;
begin
  Result := ThinkChainEvent;
end;

function TBrainCapturePointComponent.SetIdleGroup(IdleGroup : TArray<byte>) : TBrainCapturePointComponent;
begin
  Result := self;
  FFireInactive := True;
  FIdleGroup := ByteArrayToComponentGroup(IdleGroup);
end;

function TBrainCapturePointComponent.SetTeamGroup(TeamID : integer; PositiveGroup, NegativeGroup : TArray<byte>) : TBrainCapturePointComponent;
begin
  Result := self;
  FTeamGroups.Add(TeamID, RTuple<SetComponentGroup, SetComponentGroup>.Create(ByteArrayToComponentGroup(PositiveGroup), ByteArrayToComponentGroup((NegativeGroup))));
end;

procedure TBrainCapturePointComponent.Think;
var
  TargetList : TList<RTarget>;
  NearTeams : TList<integer>;
  i, TeamID : integer;
  ent : TEntity;
  active : boolean;
begin
  if not Eventbus.Read(eiIsReady, [], ComponentGroup).AsBooleanDefaultTrue then exit;
  TargetList := TList<RTarget>.Create;
  NearTeams := TList<integer>.Create;
  Eventbus.Trigger(eiWelaUpdateTargets, [TargetList], ComponentGroup);
  for i := 0 to TargetList.Count - 1 do
    if TargetList[i].IsEntity and TargetList[i].TryGetTargetEntity(ent) then
    begin
      TeamID := ent.TeamID;
      if not NearTeams.Contains(TeamID) then NearTeams.Add(TeamID);
    end;
  TargetList.Free;
  // one team primes the captures point if not blocked, more teams stops it completely
  if (NearTeams.Count = 1) and not IsBlockedForTeam(NearTeams.First) then
      FCapturingTeamID := NearTeams.First
  else if NearTeams.Count > 1 then
      FCapturingTeamID := -1;
  NearTeams.Free;
  active := False;
  for TeamID in FTeamGroups.Keys do
  begin
    if FCapturingTeamID >= 0 then
    begin
      if FCapturingTeamID = TeamID then
      begin
        if not IsBlockedForTeam(TeamID) then
        begin
          Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], FTeamGroups[TeamID].a);
          active := True;
        end;
      end
      // negative things if you have no unit near, but another team is there
      else
      begin
        Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], FTeamGroups[TeamID].b);
        active := True;
      end;
    end;
  end;
  if not active and FFireInactive then Eventbus.Trigger(eiFire, [ATarget.Create(Owner).ToRParam], FIdleGroup);
end;

{ TBrainSpawnerComponent }

function TBrainSpawnerComponent.ApplyGridOffset : TBrainSpawnerComponent;
begin
  Result := self;
  FApplyGridOffset := True;
end;

function TBrainSpawnerComponent.ApplyRandomOffset : TBrainSpawnerComponent;
begin
  Result := self;
  FApplyRandomOffset := True;
end;

function TBrainSpawnerComponent.BuildGridID : integer;
begin
  Result := Eventbus.Read(eiBuildgridOwner, []).AsIntegerDefault(-1);
end;

function TBrainSpawnerComponent.FireNotInitially : TBrainSpawnerComponent;
begin
  Result := self;
  FFireNotInitially := True;
end;

function TBrainSpawnerComponent.OccupiedField : RIntVector2;
var
  OccupiedFields : TArray<RTuple<integer, RIntVector2>>;
begin
  OccupiedFields := Eventbus.Read(eiBuildgridBlockedFields, []).AsArray<RTuple<integer, RIntVector2>>;
  if length(OccupiedFields) > 0 then
      Result := OccupiedFields[0].b
  else
      Result := RIntVector2.Create(-1, -1);
end;

function TBrainSpawnerComponent.OnDeploy : boolean;
begin
  Result := True;
  if not FFireNotInitially and IsWelaReady and assigned(Game) and Game.HasStarted then
      GlobalEventbus.Trigger(eiWaveSpawn, [BuildGridID, OccupiedField]);
end;

function TBrainSpawnerComponent.OnGameStart : boolean;
begin
  Result := True;
  if not FFireNotInitially and IsWelaReady then
    // if created before first wave spawn, spawn now at game start
      GlobalEventbus.Trigger(eiWaveSpawn, [BuildGridID, OccupiedField]);
end;

function TBrainSpawnerComponent.OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
begin
  Result := True;
  if not CanThink or (GridID.AsInteger <> self.BuildGridID) then exit;
  if IsWelaReady then
  begin
    if Coordinate.AsIntVector2 = self.OccupiedField then
        Spawn;
  end;
end;

procedure TBrainSpawnerComponent.Spawn;
var
  Target : ATarget;
  BuildZone : TBuildZone;
  TargetPos, BuildzoneOffset : RVector2;
begin
  FFireNotInitially := False;
  if Game.Map.BuildZones.TryGetBuildZone(BuildGridID, BuildZone) then
  begin
    BuildzoneOffset := RVector2.Create(0, 0);
    // apply random offset for spawn
    if FApplyRandomOffset then
        BuildzoneOffset := BuildzoneOffset + RVector2.Create(round(random) * 2 - 1, round(random) * 2 - 1);
    if FApplyGridOffset then
        BuildzoneOffset := BuildzoneOffset + RMatrix2x2.CreateBase(-BuildZone.Front, -BuildZone.Left).Inverse * (BuildZone.GetCenterOfField(OccupiedField) - BuildZone.Center);
    // buildgrid to spawnbuildgrid
    BuildzoneOffset := BuildZone.SpawnTargetBase * BuildzoneOffset;
    TargetPos := BuildZone.SpawnTarget + BuildzoneOffset;
    Target := ATarget.Create(RTarget.Create(TargetPos));
  end
  else
  begin
    assert(False, 'TBrainWelaCommanderGameTickComponent.Spawn: Could not extract owning buildgrid!');
    Target := ATarget.Create(self.FOwner);
  end;
  Eventbus.Trigger(eiFire, [Target.ToRParam], ComponentGroup);
end;

initialization

ScriptManager.ExposeClass(TBrainCapturePointComponent);
ScriptManager.ExposeClass(TBrainSpawnerComponent);

end.
