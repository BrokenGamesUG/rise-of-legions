unit BaseConflict.Map;

interface

uses
  {$IFDEF CLIENT}
  Engine.Core,
  Engine.Core.Types,
  Engine.Vertex,
  Engine.GFXApi,
  BaseConflict.Constants.Client,
  {$ENDIF}
  Generics.Collections,
  System.SysUtils,
  System.Math,
  Engine.Log,
  Engine.Math,
  Engine.Math.CollisionHelper,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Script,
  BaseConflict.Entity,
  BaseConflict.Constants,
  BaseConflict.Types.Shared,
  BaseConflict.Classes.Pathfinding,
  Engine.Serializer.Types,
  Engine.Serializer,
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Windows;

type

  {$RTTI EXPLICIT METHODS([vcPublic]) FIELDS([vcProtected,vcPublic]) PROPERTIES([vcPublic])}

  /// <summary> A buildzone keeps all information of one buildgrid, where the owning team is
  /// able to set unit templates on. </summary>
  [XMLIncludeAll([XMLIncludeFields, XMLIncludeProperties]), ScriptExcludeAll]
  TBuildZone = class
    private
      procedure SetGridFront(const Value : RVector2);
      procedure SetGridSize(const Value : RIntVector2);
      function getLeft : RVector2;
      function getBase : RMatrix2x2;
      function GetSpawnTargetBase : RMatrix2x2;
    protected
      // direction the grid is pointing to
      [XMLExcludeElement]
      FFront : RVector2;
      // gridsize
      [XMLExcludeElement]
      FSize : RIntVector2;
      // saves whether a gridfield is blocked or not
      [XMLExcludeElement]
      FGrid : T2DGrid<integer>;
    public
      const
      GRIDNODESIZE = 2;
      FIELD_BANNED = -2; // and lower means banned
      FIELD_FREE   = -1;
    var
      // the owner of that buildzone (Slot ID), owning team, ID in map
      TeamID, ID : integer;
      // the index when this grid will spawn in rotation
      SpawnRotationIndex : integer;
      // position of center and front of orientation
      Center, SpawnTarget, SpawnDirection : RVector2;
      // size of grid in fields
      property Size : RIntVector2 read FSize write SetGridSize;
      property Front : RVector2 read FFront write SetGridFront;
      [XMLExcludeElement]
      property Left : RVector2 read getLeft;
      [XMLExcludeElement]
      property CoordBase : RMatrix2x2 read getBase;
      [XMLExcludeElement]
      property SpawnTargetBase : RMatrix2x2 read GetSpawnTargetBase;
      [ScriptIncludeMember]
      constructor Create(ID : integer);
      function GetCenterOfField(CoordX, CoordY : integer) : RVector2; overload;
      function GetCenterOfField(Coord : RIntVector2) : RVector2; overload;
      function InRange(WorldCoord : RVector2) : boolean; overload;
      function InRange(Coord : RIntVector2) : boolean; overload;
      function PositionToCoord(Position : RVector2) : RIntVector2;
      function IsFree(Coord : RIntVector2) : boolean;
      function IsBanned(CoordX, CoordY : integer) : boolean; overload;
      function IsBanned(Coord : RIntVector2) : boolean; overload;
      function GetFieldID(Coord : RIntVector2) : integer;
      procedure SetFieldID(Coord : RIntVector2; BlockerID : integer);
      procedure UpdateEntityID(oldID, newID : integer);
      {$IFDEF CLIENT}
      procedure RenderEntityGrid(EntityID : integer; Color : RColor);
      procedure RenderGridNode(x, y : integer; Color : RColor; YOffset : single = 0.2); overload;
      procedure RenderGridNode(xy : RIntVector2; Color : RColor; YOffset : single = 0.2); overload;
      procedure RenderDebug(Selected : boolean);
      procedure RenderOccupation(ReferencePosition : RVector2);
      {$ENDIF}
      [ScriptIncludeMember]
      /// <summary> Blocks the field, so no player can build on it. </summary>
      function Block(CoordX, CoordY : integer) : TBuildZone;
      [ScriptIncludeMember]
      function SetTeam(TeamID : integer) : TBuildZone;
      [ScriptIncludeMember]
      function SetPosition(PosX, PosY : single) : TBuildZone;
      [ScriptIncludeMember]
      function SetSize(SizeX, SizeY : integer) : TBuildZone;
      [ScriptIncludeMember]
      function SetFront(FrontX, FrontY : single) : TBuildZone;
      [ScriptIncludeMember]
      function SetSpawnTarget(PosX, PosY, NormalX, NormalY : single) : TBuildZone;
      destructor Destroy; override;
  end;

  /// <summary>  Manages the buildzones of a map. </summary>
  [ScriptExcludeAll]
  TBuildZoneManager = class
    public
      BuildZones : TObjectDictionary<integer, TBuildZone>;
      constructor Create;
      procedure UpdateEntityIDInBuildZones(oldID, newID : integer);
      [ScriptIncludeMember]
      function AddBuildZone(BuildZone : TBuildZone) : TBuildZoneManager;
      function TryGetBuildZone(ID : integer; out BuildZone : TBuildZone) : boolean;
      function GetBuildZone(ID : integer) : TBuildZone;
      function GetBuildZoneByPosition(Position : RVector2) : TBuildZone;
      function GetWaveEntityIDByPosition(Position : RVector2) : integer;
      function GetWaveEntityIDByCoord(ID : integer; Coord : RIntVector2) : integer;
      {$IFDEF CLIENT}
      procedure RenderEntityGrid(EntityID : integer; Color : RColor);
      procedure RenderOccupation(ReferencePosition : RVector2);
      procedure RenderDebug();
      {$ENDIF}
      destructor Destroy; override;
  end;

  PLane = ^TLane;

  [XMLIncludeAll([XMLIncludeFields])]
  TLane = class
    protected
      type
      RWaypoint = record
        Waypoint : RLine2D;
        ProjectionCenter : RVector2;
        DirectionNormal, DirectionReverse : array [0 .. 2] of RVector2; // Start, Center, End
        function ProjectPoint(Point : RVector2) : RVector2;
      end;
    var
      FWayPoints : TList<RWaypoint>;

    public
      function GetNextWaypoint(Position : RVector2; LaneDirection : EnumLaneDirection) : RWaypoint;
      constructor Create();
      procedure AddWayPoint(Waypoint : RLine2D; ProjectionCenter : RVector2; DirectionNormal, DirectionReverse : TArray<RVector2>);
      function DistanceToPoint(Point : RVector2) : single;
      /// <summary> Returns the direction of the lane if I want to walk to the endpoint. </summary>
      function GetLaneDirection(Endpoint : RVector2) : EnumLaneDirection;
      function DirectionOnLane(Point : RVector2; LaneDirection : EnumLaneDirection) : RVector2;
      /// <summary> Returns the distance between Pos and Target weighted, so walking along the lane is
      /// cheaper than orthogonal to it. </summary>
      function GetWeightedDistance(Pos, Target : RVector2) : single;
      function TryGetNextWaypoint(Position : RVector2; LaneDirection : EnumLaneDirection; out TargetPosition : RVector2) : boolean;
      {$IFDEF CLIENT}
      procedure DebugRender(Selected : boolean);
      {$ENDIF}
      destructor Destroy; override;
  end;

  [XMLExcludeAll, ScriptExcludeAll]
  TLaneManager = class
    protected
      FLanes : TObjectList<TLane>;
    public
      property Lanes : TObjectList<TLane> read FLanes;
      constructor Create;
      function GetNextLaneToPoint(Position : RVector2) : TLane;
      procedure GetLanePropertiesOfEntity(Entity : TEntity; oTargetLane : PLane; oDirection : PLaneDirection); overload;
      procedure GetLanePropertiesOfEntity(Position : RVector2; TeamID : integer; oTargetLane : PLane; oDirection : PLaneDirection); overload;
      function GetOrientationOfNextLane(Position : RVector2; TeamID : integer) : RVector2;
      [ScriptIncludeMember]
      function single : TLaneManager;
      {$IFDEF CLIENT}
      procedure DebugRender(Selected : integer);
      {$ENDIF}
      destructor Destroy; override;
  end;

  /// <summary> A worldentity describes an entity which is placed on the map at the beginning of the game.
  /// So it covers all base buildings and npc entities on the map. </summary>
  [XMLIncludeAll([XMLIncludeFields])]
  RWorldEntitiy = record
    ScriptFile : string;
    Position, Front : RVector2;
    TeamID, SlotID : integer; // SlotID: 0 = npc, 1-8 belongs to 1-8th player of this team
  end;

  [XMLIncludeAll([XMLIncludeFields, XMLIncludeProperties]), ScriptExcludeAll]
  TMap = class
    private
      FFilepath : string;
      procedure SetPlayerCount(const Value : integer);
    protected
      [XMLExcludeElement]
      FPlayerCount : integer;
      [XMLExcludeElement]
      FBuildZones : TBuildZoneManager;
      [XMLExcludeElement]
      FLanes : TLaneManager;
    public
      TeamCount : integer;
      MapBoundaries : RRectFloat;
      Zones : TObjectDictionary<string, TMultipolygon>;
      [XMLExcludeElement]
      Pathfinding : TPathfinding;
      [XMLExcludeElement, ScriptIncludeMember]
      property BuildZones : TBuildZoneManager read FBuildZones;
      [XMLExcludeElement, ScriptIncludeMember]
      property Lanes : TLaneManager read FLanes;
      [XMLExcludeElement]
      property Filepath : string read FFilepath;
      property PlayerCount : integer read FPlayerCount write SetPlayerCount;
      function TeamSize : integer;
      constructor Create;
      constructor CreateEmpty;
      constructor CreateFromFile(Filename : string);

      function ClampToZone(const Zone : string; const Position : RVector2) : RVector2;

      procedure Idle;
      procedure SaveToFile(Filename : string);
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}

implementation

uses
  BaseConflict.Globals;

{ TMap }

function TMap.ClampToZone(const Zone : string; const Position : RVector2) : RVector2;
var
  ZonePolygon : TMultipolygon;
begin
  if self.Zones.TryGetValue(Zone, ZonePolygon) then
      Result := ZonePolygon.EnsurePointInMultiPoly(Position)
  else
      Result := Position;
end;

constructor TMap.Create;
begin
  Zones := TObjectDictionary<string, TMultipolygon>.Create([doOwnsValues]);
  MapBoundaries := RRectFloat.Create(-100, -100, 100, 100);
  FBuildZones := TBuildZoneManager.Create;
  FLanes := TLaneManager.Create;
end;

constructor TMap.CreateEmpty;
begin
  Create;
end;

constructor TMap.CreateFromFile(Filename : string);
begin
  Create;
  HXMLSerializer.LoadObjectFromFile(self, Filename);
  {$IFNDEF MAPEDITOR}
  assert(Zones.ContainsKey(ZONE_WALK));
  Pathfinding := TPathfinding.Create(PATHFINDING_TILE_SIZE, 4, MapBoundaries, Zones[ZONE_WALK]);
  {$ENDIF}
  FFilepath := Filename;
end;

destructor TMap.Destroy;
begin
  Pathfinding.Free;
  BuildZones.Free;
  Zones.Free;
  Lanes.Free;
  inherited;
end;

procedure TMap.Idle;
begin
  {$IFDEF CLIENT}
  // BuildZones.RenderDebug;
  {$ENDIF}
end;

procedure TMap.SaveToFile(Filename : string);
begin
  HXMLSerializer.SaveObjectToFile(self, Filename);
end;

procedure TMap.SetPlayerCount(const Value : integer);
begin
  FPlayerCount := Value;
end;

function TMap.TeamSize : integer;
begin
  if TeamCount > 0 then Result := PlayerCount div TeamCount
  else Result := 0;
end;

{ TBuildZone }

function TBuildZone.Block(CoordX, CoordY : integer) : TBuildZone;
begin
  Result := self;
  SetFieldID(RIntVector2.Create(CoordX, CoordY), FIELD_BANNED);
end;

constructor TBuildZone.Create(ID : integer);
begin
  self.ID := ID;
  FGrid := T2DGrid<integer>.Create(FIELD_FREE);
  Size := RIntVector2.Create(2, 2);
  Front := RVector2.Create(0, 1);
end;

procedure TBuildZone.SetFieldID(Coord : RIntVector2; BlockerID : integer);
begin
  FGrid.Nodes[Coord] := BlockerID;
end;

function TBuildZone.SetFront(FrontX, FrontY : single) : TBuildZone;
begin
  Result := self;
  self.Front := RVector2.Create(FrontX, FrontY);
end;

procedure TBuildZone.SetGridFront(const Value : RVector2);
begin
  FFront := Value.Normalize;
end;

procedure TBuildZone.SetGridSize(const Value : RIntVector2);
begin
  FSize := Value;
  FGrid.Size := FSize;
end;

procedure TBuildZone.UpdateEntityID(oldID, newID : integer);
begin
  FGrid.Update(
    function(x, y, old : integer) : integer
    begin
      if old = oldID then Result := newID
      else Result := old
    end)
end;

{$IFDEF CLIENT}


procedure TBuildZone.RenderDebug(Selected : boolean);
var
  Color : RColor;
begin
  Color := GetTeamColor(TeamID);
  LinePool.AddSphere(Center.X0Y, 0.5, Color);
  LinePool.AddArrow(Center.X0Y, Front.X0Y, 0.5, 1, Color);
  LinePool.AddGrid(Center.X0Y.SetY(0.1), Front.X0Y.Cross(RVector3.UNITY), Front.X0Y, Size * GRIDNODESIZE, Color, Size + 1);
  if Selected then
  begin
    LinePool.AddGrid(Center.X0Y.SetY(0.1) + ((Left + Front).X0Y * 0.1), Front.X0Y.Cross(RVector3.UNITY), Front.X0Y, Size * GRIDNODESIZE, RColor.CWHITE, Size + 1);
    LinePool.AddGrid(Center.X0Y.SetY(0.1) - ((Left + Front).X0Y * 0.1), Front.X0Y.Cross(RVector3.UNITY), Front.X0Y, Size * GRIDNODESIZE, RColor.CWHITE, Size + 1);
    LinePool.AddGrid(Center.X0Y.SetY(0.1) + ((Left - Front).X0Y * 0.1), Front.X0Y.Cross(RVector3.UNITY), Front.X0Y, Size * GRIDNODESIZE, RColor.CWHITE, Size + 1);
    LinePool.AddGrid(Center.X0Y.SetY(0.1) - ((Left - Front).X0Y * 0.1), Front.X0Y.Cross(RVector3.UNITY), Front.X0Y, Size * GRIDNODESIZE, RColor.CWHITE, Size + 1);
  end;
end;

procedure TBuildZone.RenderEntityGrid(EntityID : integer; Color : RColor);
begin
  FGrid.Each(
    procedure(x, y : integer; ID : integer)
    begin
      if ID = EntityID then RenderGridNode(x, y, Color);
    end)
end;

procedure TBuildZone.RenderGridNode(xy : RIntVector2; Color : RColor; YOffset : single);
begin
  RenderGridNode(xy.x, xy.y, Color, YOffset);
end;

procedure TBuildZone.RenderOccupation(ReferencePosition : RVector2);
const
  INNER_RADIUS  = 2 * GRIDNODESIZE;
  FADING_RADIUS = 6 * GRIDNODESIZE;
var
  y : integer;
  x : integer;
  dist : single;
  Color : RColor;
begin
  for y := 0 to FGrid.Height - 1 do
    for x := 0 to FGrid.Width - 1 do
    begin
      dist := ReferencePosition.Distance(GetCenterOfField(x, y));
      if IsFree(RIntVector2.Create(x, y)) or IsBanned(RIntVector2.Create(x, y)) then
          continue
      else
          Color := $00800000;
      Color.A := 1 - (abs(dist - INNER_RADIUS) / (FADING_RADIUS));
      if not Color.IsFullTransparent then
          RenderGridNode(x, y, Color);
    end;
end;

procedure TBuildZone.RenderGridNode(x, y : integer; Color : RColor; YOffset : single);
begin
  LinePool.AddGrid(self.GetCenterOfField(x, y).X0Y.SetY(YOffset), self.Front.X0Y, self.Left.X0Y, RVector2.Create(TBuildZone.GRIDNODESIZE), Color, 6);
end;

{$ENDIF}


destructor TBuildZone.Destroy;
begin
  FGrid.Free;
  inherited;
end;

function TBuildZone.getBase : RMatrix2x2;
begin
  Result := RMatrix2x2.CreateBase(Left, Front);
end;

function TBuildZone.GetCenterOfField(Coord : RIntVector2) : RVector2;
begin
  Result := Center + (GRIDNODESIZE * Front * (Coord.y - Size.y / 2 + 0.5)) + (GRIDNODESIZE * Left * (Coord.x - Size.x / 2 + 0.5));
end;

function TBuildZone.PositionToCoord(Position : RVector2) : RIntVector2;
var
  Offset : RVector2;
begin
  Offset := Position - Center;
  Result.x := Round((Left.Dot(Offset) / GRIDNODESIZE + Size.x / 2 - 0.5));
  Result.y := Round((Front.Dot(Offset) / GRIDNODESIZE + Size.y / 2 - 0.5));
end;

function TBuildZone.GetCenterOfField(CoordX, CoordY : integer) : RVector2;
begin
  Result := GetCenterOfField(RIntVector2.Create(CoordX, CoordY));
end;

function TBuildZone.GetFieldID(Coord : RIntVector2) : integer;
begin
  Result := FGrid.Nodes[Coord];
end;

function TBuildZone.getLeft : RVector2;
begin
  Result := Front.GetOrthogonal;
end;

function TBuildZone.GetSpawnTargetBase : RMatrix2x2;
begin
  Result := RMatrix2x2.CreateBase(SpawnDirection.Normalize, SpawnDirection.GetOrthogonal.Normalize);
end;

function TBuildZone.InRange(WorldCoord : RVector2) : boolean;
begin
  Result := InRange(PositionToCoord(WorldCoord));
end;

function TBuildZone.InRange(Coord : RIntVector2) : boolean;
begin
  Result := (Coord >= 0) and (Coord < Size) and not IsBanned(Coord);
end;

function TBuildZone.IsBanned(Coord : RIntVector2) : boolean;
begin
  Result := (FGrid.Nodes[Coord] <= FIELD_BANNED);
end;

function TBuildZone.IsBanned(CoordX, CoordY : integer) : boolean;
begin
  Result := IsBanned(RIntVector2.Create(CoordX, CoordY));
end;

function TBuildZone.IsFree(Coord : RIntVector2) : boolean;
begin
  Result := (FGrid.Nodes[Coord] = FIELD_FREE);
end;

function TBuildZone.SetPosition(PosX, PosY : single) : TBuildZone;
begin
  Result := self;
  self.Center := RVector2.Create(PosX, PosY);
end;

function TBuildZone.SetSize(SizeX, SizeY : integer) : TBuildZone;
begin
  Result := self;
  self.Size := RIntVector2.Create(SizeX, SizeY);
end;

function TBuildZone.SetSpawnTarget(PosX, PosY, NormalX, NormalY : single) : TBuildZone;
begin
  Result := self;
  SpawnTarget := RVector2.Create(PosX, PosY);
  SpawnDirection := RVector2.Create(NormalX, NormalY).Normalize;
end;

function TBuildZone.SetTeam(TeamID : integer) : TBuildZone;
begin
  Result := self;
  self.TeamID := TeamID;
end;

{ TLaneManager }

constructor TLaneManager.Create;
const
  LANE_POINT1 : RVector2         = (x : - 60; y : - 11);
  LANE_POINT2 : RVector2         = (x : - 60; y : - 35);
  LANE_CENTER : RVector2         = (x : - 60; y : - 23);
  NEXUS_POINT : RVector2         = (x : - 96; y : 0);
  LANE_END_DIRECTION1 : RVector2 = (x : - 6; y : 11);
  LANE_END_DIRECTION2 : RVector2 = (x : - 1; y : 0);
var
  Lane : TLane;
begin
  FLanes := TObjectList<TLane>.Create;

  // Hacked values
  Lane := TLane.Create();
  Lane.AddWayPoint(
    RLine2D.CreateFromPoints(LANE_POINT1, LANE_POINT2),
    LANE_CENTER,
    [LANE_POINT1.DirectionTo(LANE_POINT1.nXY), LANE_CENTER.DirectionTo(LANE_CENTER.nXY), LANE_POINT2.DirectionTo(LANE_POINT2.nXY)],
    [LANE_END_DIRECTION1, LANE_CENTER.DirectionTo(NEXUS_POINT), LANE_END_DIRECTION2]
    );
  Lane.AddWayPoint(
    RLine2D.CreateFromPoints(LANE_POINT1.nXY, LANE_POINT2.nXY),
    LANE_CENTER.nXY,
    [LANE_END_DIRECTION1.nXY, LANE_CENTER.DirectionTo(NEXUS_POINT).nXY, LANE_END_DIRECTION2.nXY],
    [LANE_POINT1.DirectionTo(LANE_POINT1.nXY).nXY, LANE_CENTER.DirectionTo(LANE_CENTER.nXY).nXY, LANE_POINT2.DirectionTo(LANE_POINT2.nXY).nXY]
    );
  FLanes.Add(Lane);

  Lane := TLane.Create();
  Lane.AddWayPoint(
    RLine2D.CreateFromPoints(LANE_POINT2.XnY, LANE_POINT1.XnY),
    LANE_CENTER.XnY,
    [LANE_POINT2.DirectionTo(LANE_POINT2.nXY).XnY, LANE_CENTER.DirectionTo(LANE_CENTER.nXY).XnY, LANE_POINT1.DirectionTo(LANE_POINT1.nXY).XnY],
    [LANE_END_DIRECTION2.XnY, LANE_CENTER.DirectionTo(NEXUS_POINT).XnY, LANE_END_DIRECTION1.XnY]
    );
  Lane.AddWayPoint(
    RLine2D.CreateFromPoints(LANE_POINT2.nXnY, LANE_POINT1.nXnY),
    LANE_CENTER.nXnY,
    [LANE_END_DIRECTION2.nXnY, LANE_CENTER.DirectionTo(NEXUS_POINT).nXnY, LANE_END_DIRECTION1.nXnY],
    [LANE_POINT2.DirectionTo(LANE_POINT2.nXY).nXnY, LANE_CENTER.DirectionTo(LANE_CENTER.nXY).nXnY, LANE_POINT1.DirectionTo(LANE_POINT1.nXY).nXnY]
    );
  FLanes.Add(Lane);
end;

{$IFDEF CLIENT}


procedure TLaneManager.DebugRender(Selected : integer);
var
  i : integer;
begin
  for i := 0 to FLanes.Count - 1 do FLanes[i].DebugRender(Selected = i);
end;
{$ENDIF}


destructor TLaneManager.Destroy;
begin
  FLanes.Free;
  inherited;
end;

procedure TLaneManager.GetLanePropertiesOfEntity(Position : RVector2; TeamID : integer; oTargetLane : PLane; oDirection : PLaneDirection);
var
  spos : RVector2;
  opponentNexus : TEntity;
  TargetLane : TLane;
  Direction : EnumLaneDirection;
begin
  // look for next lane and bind to it
  TargetLane := GetNextLaneToPoint(Position);
  if assigned(TargetLane) then
  begin
    if Game.EntityManager.TryGetNexusNextEnemy(Position, TeamID, opponentNexus) then
    begin
      spos := opponentNexus.Position;
      Direction := TargetLane.GetLaneDirection(spos);
    end
    else
    begin
      // if I have no Nexus, I walk to the next end
      Direction := TargetLane.GetLaneDirection(Position);
    end;
  end
  else
      Direction := ldNormal;
  if assigned(oTargetLane) then oTargetLane^ := TargetLane;
  if assigned(oDirection) then oDirection^ := Direction;
end;

procedure TLaneManager.GetLanePropertiesOfEntity(Entity : TEntity; oTargetLane : PLane; oDirection : PLaneDirection);
begin
  GetLanePropertiesOfEntity(Entity.Position, Entity.TeamID, oTargetLane, oDirection);
end;

function TLaneManager.GetNextLaneToPoint(Position : RVector2) : TLane;
var
  i : integer;
begin
  if FLanes.Count <= 0 then exit(nil);
  Result := FLanes.First;
  for i := 0 to FLanes.Count - 1 do
  begin
    if FLanes[i].DistanceToPoint(Position) < Result.DistanceToPoint(Position) then
        Result := FLanes[i];
  end;
end;

function TLaneManager.GetOrientationOfNextLane(Position : RVector2; TeamID : integer) : RVector2;
var
  Lane : TLane;
  Direction : EnumLaneDirection;
begin
  GetLanePropertiesOfEntity(Position, TeamID, @Lane, @Direction);
  if assigned(Lane) then
  begin
    Result := Lane.DirectionOnLane(Position, Direction);
  end
  else Result := RVector2.UNITY;
end;

function TLaneManager.Single : TLaneManager;
const
  LANE_POINT1 : RVector2         = (x : - 60; y : - 11);
  LANE_POINT2 : RVector2         = (x : - 60; y : - 35);
  LANE_CENTER : RVector2         = (x : - 60; y : - 23);
  NEXUS_POINT : RVector2         = (x : - 96; y : - 23);
  LANE_END_DIRECTION1 : RVector2 = (x : - 1; y : 0);
  LANE_END_DIRECTION2 : RVector2 = (x : - 1; y : 0);
var
  Lane : TLane;
begin
  Result := self;
  FLanes.Clear;
  // Hacked values
  Lane := TLane.Create();
  Lane.AddWayPoint(
    RLine2D.CreateFromPoints(LANE_POINT1, LANE_POINT2),
    LANE_CENTER,
    [LANE_POINT1.DirectionTo(LANE_POINT1.nXY), LANE_CENTER.DirectionTo(LANE_CENTER.nXY), LANE_POINT2.DirectionTo(LANE_POINT2.nXY)],
    [LANE_END_DIRECTION1, LANE_CENTER.DirectionTo(NEXUS_POINT), LANE_END_DIRECTION2]
    );
  Lane.AddWayPoint(
    RLine2D.CreateFromPoints(LANE_POINT1.nXY, LANE_POINT2.nXY),
    LANE_CENTER.nXY,
    [LANE_END_DIRECTION1.nXY, LANE_CENTER.DirectionTo(NEXUS_POINT).nXY, LANE_END_DIRECTION2.nXY],
    [LANE_POINT1.DirectionTo(LANE_POINT1.nXY).nXY, LANE_CENTER.DirectionTo(LANE_CENTER.nXY).nXY, LANE_POINT2.DirectionTo(LANE_POINT2.nXY).nXY]
    );
  FLanes.Add(Lane);
end;

{ TLane }

constructor TLane.Create();
begin
  FWayPoints := TList<RWaypoint>.Create;;
end;

destructor TLane.Destroy;
begin
  FWayPoints.Free;
  inherited;
end;

{$IFDEF CLIENT}


procedure TLane.DebugRender(Selected : boolean);
var
  Color : RColor;
  i : integer;
begin
  Color := HGeneric.TertOp(Selected, RColor.CPINK, RColor.CPURPLE);
  for i := 0 to FWayPoints.Count - 1 do
  begin
    LinePool.AddLine(FWayPoints[i].Waypoint.To3D.Translate(RVector3.UNITY * 0.3), Color);
    // LinePool.AddLine(FWayPoints[i].ProjectionCenter.X0Y + (RVector3.UNITY * 0.3), (FWayPoints[i].ProjectionCenter + FWayPoints[i].DirectionNormal).X0Y + (RVector3.UNITY * 0.3), RColor.CGREEN);
    // LinePool.AddLine(FWayPoints[i].ProjectionCenter.X0Y + (RVector3.UNITY * 0.3), (FWayPoints[i].ProjectionCenter + FWayPoints[i].DirectionReverse).X0Y + (RVector3.UNITY * 0.3), RColor.CGRASSGREEN);
  end;
end;
{$ENDIF}


procedure TLane.AddWayPoint(Waypoint : RLine2D; ProjectionCenter : RVector2; DirectionNormal, DirectionReverse : TArray<RVector2>);
var
  aWaypoint : RWaypoint;
  i : integer;
begin
  aWaypoint.Waypoint := Waypoint;
  aWaypoint.ProjectionCenter := ProjectionCenter;
  for i := 0 to 2 do
      aWaypoint.DirectionNormal[i] := DirectionNormal[i].Normalize;
  for i := 0 to 2 do
      aWaypoint.DirectionReverse[i] := DirectionReverse[i].Normalize;
  FWayPoints.Add(aWaypoint);
end;

function TLane.DirectionOnLane(Point : RVector2; LaneDirection : EnumLaneDirection) : RVector2;
var
  Waypoint : RWaypoint;
begin
  Waypoint := GetNextWaypoint(Point, LaneDirection);
  Result := Point.DirectionTo(Waypoint.ProjectPoint(Point));
  if Waypoint.Waypoint.IsLeft(Point) xor (LaneDirection = ldReverse) then
      Result := -Result;
end;

function TLane.DistanceToPoint(Point : RVector2) : single;
var
  i : integer;
begin
  Result := MaxSingle;
  for i := 0 to FWayPoints.Count - 1 do
      Result := FWayPoints[i].Waypoint.DistanceToPoint(Point);
end;

function TLane.GetLaneDirection(Endpoint : RVector2) : EnumLaneDirection;
begin
  if FWayPoints.First.Waypoint.Center.Distance(Endpoint) < FWayPoints.Last.Waypoint.Center.Distance(Endpoint) then
      Result := ldReverse
  else
      Result := ldNormal;
end;

function TLane.GetNextWaypoint(Position : RVector2; LaneDirection : EnumLaneDirection) : RWaypoint;
var
  i : integer;
  dist : single;
begin
  assert(FWayPoints.Count > 0);
  Result := FWayPoints.First;
  for i := 1 to FWayPoints.Count - 1 do
  begin
    dist := FWayPoints[i].Waypoint.DistanceToPoint(Position);
    if Result.Waypoint.DistanceToPoint(Position) > dist then
        Result := FWayPoints[i];
  end;
end;

function TLane.GetWeightedDistance(Pos, Target : RVector2) : single;
var
  sorth, sstraight, slane : single;
begin
  // compute lane and orthogonal component
  sstraight := (Target - Pos).Length;
  sorth := (Target - Pos).Orthogonalize(DirectionOnLane(Pos, ldNormal)).Length;
  slane := abs(sqr(sstraight) - sqr(sorth));
  if slane > 0 then
      slane := sqrt(slane);
  // walking orthogonal costs more
  Result := slane + sorth * 1.5;
end;

function TLane.TryGetNextWaypoint(Position : RVector2; LaneDirection : EnumLaneDirection; out TargetPosition : RVector2) : boolean;
var
  i : integer;
  dist : single;
  First : boolean;
  Waypoint : RWaypoint;
begin
  First := True;
  for i := 0 to FWayPoints.Count - 1 do
  begin
    dist := FWayPoints[i].Waypoint.DistanceToPoint(Position);
    // due to precision errors don't detect waypoints very near
    if not(FWayPoints[i].Waypoint.IsLeft(Position) xor (LaneDirection = ldReverse)) and (dist > 1.0) and (First or (Waypoint.Waypoint.DistanceToPoint(Position) > dist)) then
    begin
      Waypoint := FWayPoints[i];
      First := False;
    end;
  end;
  Result := not First;
  if Result then
      TargetPosition := Waypoint.ProjectPoint(Position);
end;

{ TBuildZoneManager }

function TBuildZoneManager.AddBuildZone(BuildZone : TBuildZone) : TBuildZoneManager;
begin
  Result := self;
  BuildZones.Add(BuildZone.ID, BuildZone);
end;

constructor TBuildZoneManager.Create;
begin
  BuildZones := TObjectDictionary<integer, TBuildZone>.Create([doOwnsValues]);
end;

function TBuildZoneManager.GetBuildZone(ID : integer) : TBuildZone;
begin
  if not TryGetBuildZone(ID, Result) then Result := nil;
end;

function TBuildZoneManager.GetBuildZoneByPosition(Position : RVector2) : TBuildZone;
var
  BuildZone : TBuildZone;
begin
  Result := nil;
  for BuildZone in BuildZones.Values do
    if BuildZone.InRange(Position) then exit(BuildZone);
end;

function TBuildZoneManager.GetWaveEntityIDByCoord(ID : integer; Coord : RIntVector2) : integer;
var
  BuildZone : TBuildZone;
  Pos : RVector2;
begin
  Result := -1;
  BuildZone := GetBuildZone(ID);
  if assigned(BuildZone) then
  begin
    Pos := BuildZone.GetCenterOfField(Coord);
    Result := GetWaveEntityIDByPosition(Pos);
  end;
end;

function TBuildZoneManager.GetWaveEntityIDByPosition(Position : RVector2) : integer;
var
  BuildZone : TBuildZone;
begin
  Result := -1;
  BuildZone := GetBuildZoneByPosition(Position);
  if assigned(BuildZone) then
  begin
    Result := BuildZone.GetFieldID(BuildZone.PositionToCoord(Position));
  end;
end;

function TBuildZoneManager.TryGetBuildZone(ID : integer; out BuildZone : TBuildZone) : boolean;
begin
  Result := BuildZones.TryGetValue(ID, BuildZone);
end;

procedure TBuildZoneManager.UpdateEntityIDInBuildZones(oldID, newID : integer);
var
  BuildZone : TBuildZone;
begin
  for BuildZone in BuildZones.Values do
      BuildZone.UpdateEntityID(oldID, newID);
end;

{$IFDEF CLIENT}


procedure TBuildZoneManager.RenderDebug;
var
  BuildZone : TBuildZone;
begin
  for BuildZone in BuildZones.Values do
      BuildZone.RenderDebug(False);
end;

procedure TBuildZoneManager.RenderEntityGrid(EntityID : integer; Color : RColor);
var
  BuildZone : TBuildZone;
begin
  for BuildZone in BuildZones.Values do
      BuildZone.RenderEntityGrid(EntityID, Color);
end;

procedure TBuildZoneManager.RenderOccupation(ReferencePosition : RVector2);
var
  BuildZone : TBuildZone;
begin
  for BuildZone in BuildZones.Values do
      BuildZone.RenderOccupation(ReferencePosition);
end;

{$ENDIF}


destructor TBuildZoneManager.Destroy;
begin
  BuildZones.Free;
  inherited;
end;

{ TLane.RWaypoint }

function TLane.RWaypoint.ProjectPoint(Point : RVector2) : RVector2;
var
  LeftBorder, RightBorder, Endpoint, ProjectedPoint : RVector2;
begin
  if Waypoint.IsLeft(Point) then
  begin
    if DirectionNormal[1].Cross(ProjectionCenter.DirectionTo(Point)) < 0 then
    begin
      LeftBorder := DirectionNormal[1];
      RightBorder := DirectionNormal[2];
      Endpoint := Waypoint.Endpoint;
    end
    else
    begin
      LeftBorder := DirectionNormal[1];
      RightBorder := DirectionNormal[0];
      Endpoint := Waypoint.Origin;
    end;
  end
  else
  begin
    if DirectionReverse[1].Cross(ProjectionCenter.DirectionTo(Point)) > 0 then
    begin
      LeftBorder := DirectionReverse[1];
      RightBorder := DirectionReverse[2];
      Endpoint := Waypoint.Endpoint;
    end
    else
    begin
      LeftBorder := DirectionReverse[1];
      RightBorder := DirectionReverse[0];
      Endpoint := Waypoint.Origin;
    end;
  end;
  if LeftBorder.Dot(RightBorder) >= 0.999 then
  begin
    // parallel => direct projection onto lane
    Result := Waypoint.NearestPointOnLine(Point);
    exit;
  end;
  ProjectedPoint := RRay2D.Create(ProjectionCenter, LeftBorder).IntersectionWithRay(RRay2D.Create(Endpoint, RightBorder));
  Result := RRay2D.Create(ProjectedPoint, ProjectedPoint.DirectionTo(Point)).IntersectionWithRay(Waypoint.ToRay);
end;

initialization

ScriptManager.ExposeClass(TMap);
ScriptManager.ExposeClass(TBuildZoneManager);
ScriptManager.ExposeClass(TBuildZone);
ScriptManager.ExposeClass(TLaneManager);

end.
