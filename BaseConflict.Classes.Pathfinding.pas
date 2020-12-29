unit BaseConflict.Classes.Pathfinding;

interface

uses
  Math,
  System.SysUtils,
  Engine.Math,
  Engine.Math.Collision2D,
  Winapi.Windows,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  BaseConflict.Entity,
  BaseConflict.Constants,
  BaseConflict.Types.Shared,
  {$IFDEF CLIENT}
  Engine.Vertex,
  {$ENDIF}
  Generics.Collections;

type

  RSmallIntVector2 = record
    X, Y : SmallInt;
    constructor Create(X, Y : SmallInt);
    class operator add(const a, b : RSmallIntVector2) : RSmallIntVector2;
  end;

  EPathfindingError = class(Exception);

  TPathfinding = class;
  TPathfindingTile = class;

  TPathfindingTileNeighbour = class
    strict private
      FCost : Single;
      FNeighbour : TPathfindingTile;
    public
      property NeighbourTile : TPathfindingTile read FNeighbour;
      property Cost : Single read FCost;
      constructor Create(FromTile, ToTile : TPathfindingTile);
  end;

  TPathfindingTile = class
    private const
      TIMESLOTLENGTH = 150;
    private
      FGridPosition : RSmallIntVector2;
      FWorldSpaceBoundaries : RRectFloat;
      FOwner : TPathfinding;
      FNeighbours : TObjectList<TPathfindingTileNeighbour>;
      // for pathfinding
      FTargetHeuristicCost : Single;
      FCostFromSource : Single;
      FParent : TPathfindingTile;
      FBlockingBeginnTime : int64;
      // tile is permanently blocked by enviroment
      FPermanentlyBlocked : boolean;
      // list of all entities that blocking the tile by standing
      FBlockingEntities : TDictionary<TEntity, boolean>;
      // time slots where an tile will be blocked by an unit
      FBlockedTimeSlots : TRingBuffer<boolean>;
      procedure ComputeAndSetHeuristicCost(Source, Target : TPathfindingTile; Direction : EnumLaneDirection; UseWaypoints : boolean);
      function TotalEstimatedCost : Single;
      /// <summary> Reserve the tile for a unit beginning with StartingTime and for duration.
      /// StartingTime is in ms timeframe and Duration in ms.
      /// Unit should have left the tile at timestamp = StartingTime + Duration</summary>
      procedure ReserveTile(StartingTime, Duration : int64);
      /// <summary> Release the reserved timeslots on the tile</summary>
      procedure ReleaseTile(StartingTime, Duration : int64);
      function GetNeighboursList : TObjectList<TPathfindingTileNeighbour>;
      function GetNeighbours : TList<TPathfindingTile>;
    public
      property Neighbours : TObjectList<TPathfindingTileNeighbour> read GetNeighboursList;
      property GridPosition : RSmallIntVector2 read FGridPosition;
      property WorldSpaceBoundaries : RRectFloat read FWorldSpaceBoundaries;
      /// <summary> Returns true if Tile can be passed at this moment by a unit of the given size.</summary>
      function IsWalkable(UnitSize : integer) : boolean;
      function IsWalkableAtTime(Time : int64; StayDuration : int64) : boolean;
      /// <summary> Returns True if tile is blocked forever, tile will never be free, indepently if any unit move or a building is destroyed.</summary>
      function IsPermanentlyBlocked : boolean;
      /// <summary> Returns True if tile is currently blocked. Will take of care of permanently blocked tiles and temporary blocked (by building
      /// or standing unit)</summary>
      function IsBlocked : boolean;
      function GetOptimalNeighbour(Target : TPathfindingTile) : TPathfindingTile;
      procedure BlockTile(Entity : TEntity);
      procedure UnblockTile(Entity : TEntity);
      constructor Create(GridPosition : RSmallIntVector2; WorldSpaceBoundaries : RRectFloat; TIMESLOTLENGTH : integer; Owner : TPathfinding);
      destructor Destroy; override;
  end;

  TPathWaypoint = class
    Tile : TPathfindingTile;
    EnterTimestamp, StayDuration : int64;
    constructor Create(EnterTimestamp, StayDuration : int64; Tile : TPathfindingTile);
  end;

  TPath = class
    private
      FWaypoints : TObjectList<TPathWaypoint>;
    public
      property Waypoints : TObjectList<TPathWaypoint> read FWaypoints;
      procedure AddWaypoint(EnterTimestamp, StayDuration : int64; Tile : TPathfindingTile);
      constructor Create();
      procedure ReleasePath;
      destructor Destroy; override;
  end;

  TPathfinding = class
    private
      FTileWidthCount, FTileHeightCount : integer;
      FGrid : array of array of TPathfindingTile;
      FTileSize : Single;
      FMapBoundaries : RRectFloat;
      FWalkableZone : TMultipolygon;
      FMaxUnitSize : integer;
      FComputedPaths : TObjectDictionary<TEntity, TPath>;
      /// <summary> Lay a grid over the world (create the grid tile objects)</summary>
      procedure CreateGrid;
      /// <summary> Mark </summary>
      procedure InitGridWithWorldData;
      /// <summary> </summary>
      procedure ClearGrid;
      procedure SetMaxUnitSize(const Value : integer);
      function GetTile(X, Y : integer) : TPathfindingTile; overload;
      function GetTile(xy : RSmallIntVector2) : TPathfindingTile; overload;
      procedure SetTileSize(const Value : Single);
      function DoPathfinding(Source, Target : TPathfindingTile; Direction : EnumLaneDirection; MaxPathLength : integer; EntityMovementSpeed : Single; UseWaypoints : boolean; IgnoreOtherEntities : boolean; ReservePath : boolean) : TPath;
    public
      property ComputedPaths : TObjectDictionary<TEntity, TPath> read FComputedPaths;
      /// <summary> Tilecount control acuteness of the grid. The x-axis of the Map is divied by the tilecount and the tile worldunity size
      /// </summary>
      property TileWidthCount : integer read FTileWidthCount;
      property TileHeightCount : integer read FTileHeightCount;
      property TileSize : Single read FTileSize write SetTileSize;
      property Grid[X, Y : integer] : TPathfindingTile read GetTile;
      property GridBy2D[xy : RSmallIntVector2] : TPathfindingTile read GetTile;
      /// <summary> Max size of a unit in tilecount.</summary>
      property MaxUnitSize : integer read FMaxUnitSize write SetMaxUnitSize;
      /// <summary> Create and init the pathfinding grid.</summary>
      constructor Create(TileSize : Single; MaxUnitSize : integer; MapBoundaries : RRectFloat; WalkableZone : TMultipolygon);
      function GetTileByPosition(const Position : RVector2) : TPathfindingTile;
      /// <summary> Return a path for a entity from current tile to target tile (determined by TargetPosition) and reserve the path
      /// in time.
      /// <param name="Entity"> Entity for what the path will be computed.</param>
      /// <param name="TargetPosition"> Path will be calculated to target position.</param>
      /// <param name="CancelPathLength"> The max length of the returned path in worlddistance. With this value the entity can
      /// control the computationtime / path quality ratio.</param>
      /// <param name="UseWaypoints"> Will use some waypoints on which units will walk to reach target, else direct way.</param>
      /// <param name="IgnoreOtherEntities"> Path will be calculated to target position.</param>
      /// <returns> Returns an array of grid nodes (tiles) of the path, they must be visited by the entity to arrive the target.
      /// If array is empty, no path was found.</returns>
      /// </summary>
      function ComputePath(Entity : TEntity; TargetPosition : RVector2; CancelPathLength : integer; UseWaypoints : boolean; IgnoreOtherEntities : boolean) : TArray<TPathfindingTile>;
      function ComputeDebugPath(Start, Target : TPathfindingTile; MaxPathLength : integer; Direction : EnumLaneDirection) : TArray<TPathfindingTile>;
      function ComputePathLength(Path : TArray<TPathfindingTile>) : double;
      procedure CancelLastComputedPath(Entity : TEntity);
      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals,
  BaseConflict.Map;

{ TPathfinding }

procedure TPathfinding.CancelLastComputedPath(Entity : TEntity);
begin
  // delphi wiki: No exception is thrown if the key is not in the dictionary.
  ComputedPaths.Remove(Entity);
end;

procedure TPathfinding.ClearGrid;
var
  X, Y : integer;
begin
  for Y := 0 to TileHeightCount - 1 do
    for X := 0 to TileWidthCount - 1 do
        FreeAndNil(FGrid[X, Y]);
  setlength(FGrid, 0, 0);

end;

function TPathfinding.ComputeDebugPath(Start, Target : TPathfindingTile; MaxPathLength : integer; Direction : EnumLaneDirection) : TArray<TPathfindingTile>;
var
  Path : TPath;
begin
  result := nil;
  Path := DoPathfinding(Start, Target, Direction, MaxPathLength, 1, False, False, False);
  if Path <> nil then
  begin
    result := HArray.Map<TPathWaypoint, TPathfindingTile>(Path.Waypoints.ToArray,
      function(const Value : TPathWaypoint) : TPathfindingTile
      begin
        result := Value.Tile;
      end);
  end;
  Path.Free;
end;

function TPathfinding.ComputePath(Entity : TEntity; TargetPosition : RVector2; CancelPathLength : integer; UseWaypoints : boolean; IgnoreOtherEntities : boolean) : TArray<TPathfindingTile>;
var
  Source, Target : TPathfindingTile;
  Path : TPath;
  Direction : EnumLaneDirection;
begin
  result := nil;
  Source := Entity.Eventbus.Read(eiPathfindingTile, []).AsType<TPathfindingTile>;
  if assigned(Source) then
  begin
    CancelLastComputedPath(Entity);
    Target := GetTileByPosition(TargetPosition);
    assert(assigned(Target));
    Map.Lanes.GetLanePropertiesOfEntity(Entity, nil, @Direction);
    Path := DoPathfinding(Source, Target, Direction, CancelPathLength, Entity.Eventbus.Read(eiSpeed, []).AsSingle, UseWaypoints, IgnoreOtherEntities, True);
    if Path <> nil then
    begin
      assert(not ComputedPaths.ContainsKey(Entity));
      ComputedPaths.add(Entity, Path);
      result := HArray.Map<TPathWaypoint, TPathfindingTile>(Path.Waypoints.ToArray,
        function(const Value : TPathWaypoint) : TPathfindingTile
        begin
          result := Value.Tile;
        end);
    end;
  end;
end;

function TPathfinding.ComputePathLength(Path : TArray<TPathfindingTile>) : double;
var
  i : integer;
begin
  if length(Path) > 1 then
  begin
    result := 0;
    for i := 1 to length(Path) - 1 do
        result := result + (Path[i].WorldSpaceBoundaries.Center - Path[i - 1].WorldSpaceBoundaries.Center).length;
  end
  else result := 0;
end;

constructor TPathfinding.Create(TileSize : Single; MaxUnitSize : integer; MapBoundaries : RRectFloat; WalkableZone : TMultipolygon);
begin
  FTileSize := TileSize;
  FMaxUnitSize := MaxUnitSize;
  FMapBoundaries := MapBoundaries;
  FWalkableZone := WalkableZone;
  FComputedPaths := TObjectDictionary<TEntity, TPath>.Create([doOwnsValues]);
  CreateGrid;
  InitGridWithWorldData;
end;

procedure TPathfinding.CreateGrid;
var
  X, Y : integer;
  tileWorldspaceBoundaries : RRectFloat;
begin
  // every tile is quadratic, so width = height
  FTileHeightCount := trunc(FMapBoundaries.Height / TileSize);
  FTileWidthCount := trunc(FMapBoundaries.Width / TileSize);
  setlength(FGrid, FTileWidthCount, FTileHeightCount);
  for Y := 0 to FTileHeightCount - 1 do
    for X := 0 to FTileWidthCount - 1 do
    begin
      tileWorldspaceBoundaries := RRectFloat.Create(FMapBoundaries.Left + X * TileSize, FMapBoundaries.Top + Y * TileSize, FMapBoundaries.Left + (X + 1) * TileSize, FMapBoundaries.Top + (Y + 1) * TileSize);
      FGrid[X, Y] := TPathfindingTile.Create(RSmallIntVector2.Create(X, Y), tileWorldspaceBoundaries, 1, self);
    end;
end;

destructor TPathfinding.Destroy;
begin
  FComputedPaths.Free;
  ClearGrid;
  inherited;
end;

function TPathfinding.DoPathfinding(Source, Target : TPathfindingTile; Direction : EnumLaneDirection; MaxPathLength : integer;
EntityMovementSpeed : Single; UseWaypoints : boolean; IgnoreOtherEntities : boolean; ReservePath : boolean) : TPath;
var
  OpenList : TPriorityQueue<TPathfindingTile>;
  ClosedList : TDictionary<TPathfindingTile, boolean>;
  CurrentTile : TPathfindingTile;
  Neighbour : TPathfindingTileNeighbour;
  PathFound : boolean;
  i : integer;
  newCost, TileDiagonalLength : Single;
  // DistanceToNeighbourCenter : Single;
  StartingTime, EnterNeighbourTime, NeighbourStayDuration, EnterTimestamp, Duration : int64;
  Waypoints : TArray<TPathfindingTile>;

  // return the path from source to endtile, by following the path (endtile.FParent) until parent is nil
  function GetPathToSource(EndTile : TPathfindingTile) : TArray<TPathfindingTile>;
  var
    Path : TList<TPathfindingTile>;
  begin
    assert(assigned(EndTile));
    Path := TList<TPathfindingTile>.Create;
    repeat
      Path.add(EndTile);
      EndTile := EndTile.FParent;
    until EndTile = nil;
    Path.Reverse;
    result := Path.ToArray;
    Path.Free;
  end;

begin
  assert(EntityMovementSpeed > 0);
  TileDiagonalLength := Sqrt(2 * Sqr(TileSize));
  OpenList := TPriorityQueue<TPathfindingTile>.Create;
  ClosedList := TDictionary<TPathfindingTile, boolean>.Create;
  PathFound := False;
  StartingTime := GameTimeManager.GetTimeStamp;
  // init start node
  Source.FCostFromSource := 0;
  Source.FParent := nil;
  Source.FBlockingBeginnTime := StartingTime;
  // and after init add them as first node for pahtfinding
  OpenList.Insert(Source, Source.TotalEstimatedCost);
  repeat
    CurrentTile := OpenList.ExtractMin;
    // found way to target, we are finsihed or if the computed path is long enough
    if (CurrentTile = Target) or (CurrentTile.FCostFromSource >= MaxPathLength) then
    begin
      PathFound := True;
      Break;
    end;
    ClosedList.add(CurrentTile, True);
    for Neighbour in CurrentTile.Neighbours do
    begin
      // calculated the cost from current node to the center of the Neighbour
      // DistanceToNeighbourCenter := (Neighbour.WorldSpaceBoundaries.Center - currentTile.WorldSpaceBoundaries.Center).length;
      // calculate the time is needed to cross the boundaries of the current tile and enter the neighbour tile in ms
      EnterNeighbourTime := round((CurrentTile.FCostFromSource + Neighbour.Cost / 2) / EntityMovementSpeed);
      // assume maximum length (walking diagonal)
      NeighbourStayDuration := round(TileDiagonalLength / EntityMovementSpeed);

      // fast break if any way to reach target is found
      if Neighbour.NeighbourTile = Target then
      begin
        Neighbour.NeighbourTile.FParent := CurrentTile;
        Neighbour.NeighbourTile.FCostFromSource := CurrentTile.FCostFromSource + Neighbour.Cost;
        Neighbour.NeighbourTile.FBlockingBeginnTime := StartingTime + EnterNeighbourTime;
        CurrentTile := Neighbour.NeighbourTile;
        PathFound := True;
        Break;
      end;

      if ((not IgnoreOtherEntities and Neighbour.NeighbourTile.IsWalkableAtTime(StartingTime + EnterNeighbourTime, NeighbourStayDuration))
        or (IgnoreOtherEntities and Neighbour.NeighbourTile.IsPermanentlyBlocked)) and not ClosedList.ContainsKey(Neighbour.NeighbourTile) then
      begin
        if not OpenList.Contains(Neighbour.NeighbourTile) then
        begin
          Neighbour.NeighbourTile.FParent := CurrentTile;
          Neighbour.NeighbourTile.FCostFromSource := CurrentTile.FCostFromSource + Neighbour.Cost;
          Neighbour.NeighbourTile.ComputeAndSetHeuristicCost(Source, Target, Direction, UseWaypoints);
          Neighbour.NeighbourTile.FBlockingBeginnTime := StartingTime + EnterNeighbourTime;
          OpenList.Insert(Neighbour.NeighbourTile, Neighbour.NeighbourTile.TotalEstimatedCost);
        end
        else
        begin
          newCost := CurrentTile.FCostFromSource + Neighbour.Cost;
          if Neighbour.NeighbourTile.FCostFromSource > newCost then
          begin
            Neighbour.NeighbourTile.FParent := CurrentTile;
            Neighbour.NeighbourTile.FCostFromSource := CurrentTile.FCostFromSource + Neighbour.Cost;
            Neighbour.NeighbourTile.FBlockingBeginnTime := StartingTime + EnterNeighbourTime;
            OpenList.DecreaseKey(Neighbour.NeighbourTile, Neighbour.NeighbourTile.TotalEstimatedCost);
          end;
        end;
      end;
    end;
  until OpenList.IsEmpty or PathFound;
  if PathFound then
  begin
    // construct path from from source (0) to currenttile (high) by backtracking the moved path
    Waypoints := GetPathToSource(CurrentTile);
    result := TPath.Create;
    // block timeslots
    for i := 0 to length(Waypoints) - 1 do
    begin
      EnterTimestamp := Waypoints[i].FBlockingBeginnTime;
      // if i is the last node in route, block until can move into middle
      if i = (length(Waypoints) - 1) then
          Duration := round(TileDiagonalLength * 0.5 / EntityMovementSpeed)
      else
        // blocking tile while when tile is entered and until the next tile is entered
          Duration := Waypoints[i + 1].FBlockingBeginnTime - Waypoints[i].FBlockingBeginnTime;
      if ReservePath then
          Waypoints[i].ReserveTile(EnterTimestamp, Duration);

      result.AddWaypoint(EnterTimestamp, Duration, Waypoints[i]);
    end;
  end
  else
      result := nil;
  OpenList.Free;
  ClosedList.Free;
end;

function TPathfinding.GetTile(X, Y : integer) : TPathfindingTile;
begin
  if (X < 0) or (X >= TileWidthCount) then
      raise EPathfindingError.Create('TPathfinding.GetTile: Index X out of bound.');
  if (Y < 0) or (Y >= TileHeightCount) then
      raise EPathfindingError.Create('TPathfinding.GetTile: Index Y out of bound.');
  assert(length(FGrid) > X);
  assert(length(FGrid[0]) > Y);
  result := FGrid[X, Y];
end;

function TPathfinding.GetTile(xy : RSmallIntVector2) : TPathfindingTile;
begin
  result := GetTile(xy.X, xy.Y);
end;

function TPathfinding.GetTileByPosition(const Position : RVector2) : TPathfindingTile;
var
  TileIndex : RVector2;
begin
  result := nil;
  if FMapBoundaries.ContainsPoint(Position) then
  begin
    TileIndex := (Position - FMapBoundaries.LeftTop) / TileSize;
    assert(round(TileIndex.X) >= 0);
    assert(round(TileIndex.X) < TileWidthCount);
    assert(round(TileIndex.Y) >= 0);
    assert(round(TileIndex.Y) < TileHeightCount);
    result := Grid[trunc(TileIndex.X), trunc(TileIndex.Y)];
  end;
end;

procedure TPathfinding.InitGridWithWorldData;
var
  X, Y : integer;
  Tile : TPathfindingTile;
begin
  for Y := 0 to TileHeightCount - 1 do
    for X := 0 to TileWidthCount - 1 do
    begin
      Tile := Grid[X, Y];
      if not FWalkableZone.IsPointInMultiPolygon(Tile.WorldSpaceBoundaries.Center) then
        // setting freespace to a negative value, will mark them as occupied
          Tile.FPermanentlyBlocked := True;
    end;
end;

procedure TPathfinding.SetMaxUnitSize(const Value : integer);
begin
  FMaxUnitSize := Value;
end;

procedure TPathfinding.SetTileSize(const Value : Single);
begin
  ClearGrid;
  FTileSize := Value;
  CreateGrid;
  InitGridWithWorldData;
end;

{ TPathfindingTile }

procedure TPathfindingTile.BlockTile(Entity : TEntity);
begin
  FBlockingEntities.AddOrSetValue(Entity, True);
end;

procedure TPathfindingTile.ComputeAndSetHeuristicCost(Source, Target : TPathfindingTile; Direction : EnumLaneDirection; UseWaypoints : boolean);
var
  TargetPosition, SourcePosition, LastSource : RVector2;
  Lane : TLane;
begin
  SourcePosition := Source.WorldSpaceBoundaries.Center;
  TargetPosition := Target.WorldSpaceBoundaries.Center;
  // for waypoints heuristic use a more complex algorithm that compute the way cost along some waypoints
  if UseWaypoints then
  begin
    FTargetHeuristicCost := 0;
    Lane := Map.Lanes.GetNextLaneToPoint(SourcePosition);
    LastSource := SourcePosition;
    while Lane.TryGetNextWaypoint(LastSource, Direction, TargetPosition) do
    begin
      // ignore all waypoints before current position
      // else way back to first waypoint independently from current position (e.g. one field before nexus)
      // would be computed
      if ((Direction = ldNormal) and (TargetPosition.X > self.WorldSpaceBoundaries.Center.X)) or
        ((Direction = ldReverse) and (TargetPosition.X < self.WorldSpaceBoundaries.Center.X)) then
      begin
        if FTargetHeuristicCost = 0 then
            FTargetHeuristicCost := FTargetHeuristicCost + (TargetPosition - self.WorldSpaceBoundaries.Center).length
        else
            FTargetHeuristicCost := FTargetHeuristicCost + (TargetPosition - LastSource).length;
      end;
      LastSource := TargetPosition;
    end;
    if FTargetHeuristicCost = 0 then
        FTargetHeuristicCost := FTargetHeuristicCost + (Target.WorldSpaceBoundaries.Center - self.WorldSpaceBoundaries.Center).length
    else
        FTargetHeuristicCost := FTargetHeuristicCost + (Target.WorldSpaceBoundaries.Center - LastSource).length;
  end
  // no waypoints, use beeline as heuristic
  else
      FTargetHeuristicCost := (Target.WorldSpaceBoundaries.Center - self.WorldSpaceBoundaries.Center).length;
end;

constructor TPathfindingTile.Create(GridPosition : RSmallIntVector2; WorldSpaceBoundaries : RRectFloat; TIMESLOTLENGTH : integer; Owner : TPathfinding);
begin
  FGridPosition := GridPosition;
  FWorldSpaceBoundaries := WorldSpaceBoundaries;
  FPermanentlyBlocked := False;
  FBlockedTimeSlots := TRingBuffer<boolean>.Create(50);
  FBlockingEntities := TDictionary<TEntity, boolean>.Create();
  FOwner := Owner;
end;

destructor TPathfindingTile.Destroy;
begin
  FBlockingEntities.Free;
  FBlockedTimeSlots.Free;
  FNeighbours.Free;
  inherited;
end;

function TPathfindingTile.GetNeighbours : TList<TPathfindingTile>;
const
  Neighbours : array [0 .. 7] of RSmallIntVector2 = (
    (X : - 1; Y : - 1), (X : 0; Y : - 1), (X : + 1; Y : - 1),
    (X : - 1; Y : 0), (X : + 1; Y : 0),
    (X : - 1; Y : + 1), (X : 0; Y : + 1), (X : + 1; Y : + 1)
    );
var
  NeighbourIndex : RSmallIntVector2;
  i : integer;
begin
  result := TList<TPathfindingTile>.Create;
  for i := 0 to 7 do
  begin
    NeighbourIndex := GridPosition + Neighbours[i];
    if InRange(NeighbourIndex.X, 0, FOwner.TileWidthCount - 1) and InRange(NeighbourIndex.Y, 0, FOwner.TileHeightCount - 1) then
        result.add(FOwner.Grid[NeighbourIndex.X, NeighbourIndex.Y]);
  end;
end;

function TPathfindingTile.GetNeighboursList : TObjectList<TPathfindingTileNeighbour>;
var
  Neighbour : TPathfindingTile;
  Neighbours : TList<TPathfindingTile>;
begin
  if not assigned(FNeighbours) then
  begin
    FNeighbours := TObjectList<TPathfindingTileNeighbour>.Create();
    Neighbours := GetNeighbours;
    for Neighbour in Neighbours do
        FNeighbours.add(TPathfindingTileNeighbour.Create(self, Neighbour));
    Neighbours.Free;
  end;
  result := FNeighbours;
end;

function TPathfindingTile.GetOptimalNeighbour(Target : TPathfindingTile) : TPathfindingTile;
var
  Neighbour : TPathfindingTile;
  Neighbours : TList<TPathfindingTile>;
  DistanceToNeighbourCenter, Cost : Single;
  OptimalNeighbour : RTuple<Single, TPathfindingTile>;
begin
  OptimalNeighbour.a := Single.MaxValue;
  Neighbours := GetNeighbours;
  for Neighbour in Neighbours do
  begin
    DistanceToNeighbourCenter := (Neighbour.WorldSpaceBoundaries.Center - self.WorldSpaceBoundaries.Center).length;
    Neighbour.ComputeAndSetHeuristicCost(self, Target, ldNormal, True);
    Cost := DistanceToNeighbourCenter + Neighbour.FTargetHeuristicCost;
    if Cost < OptimalNeighbour.a then
    begin
      OptimalNeighbour.a := Cost;
      OptimalNeighbour.b := Neighbour;
    end;
  end;
  Neighbours.Free;
  assert(OptimalNeighbour.a <> Single.MaxValue);
  result := OptimalNeighbour.b;
end;

function TPathfindingTile.IsBlocked : boolean;
begin
  result := IsPermanentlyBlocked or (FBlockingEntities.Count > 0);
end;

function TPathfindingTile.IsPermanentlyBlocked : boolean;
begin
  result := FPermanentlyBlocked;
end;

function TPathfindingTile.IsWalkable(UnitSize : integer) : boolean;
begin
  result := IsWalkableAtTime(GameTimeManager.GetTimeStamp, 0);
end;

function TPathfindingTile.IsWalkableAtTime(Time : int64; StayDuration : int64) : boolean;
var
  blocked : boolean;
  t : integer;
begin
  // no one should ever look if a tile is walkable in to far future
  assert(Time < GameTimeManager.GetTimeStamp + FBlockedTimeSlots.Size * TIMESLOTLENGTH);
  blocked := IsBlocked;
  if not blocked then
    for t := 0 to StayDuration div TIMESLOTLENGTH do
    begin
      blocked := blocked or FBlockedTimeSlots[(Time div TIMESLOTLENGTH) + t];
      if blocked then
          Break;
    end;
  result := not blocked;
end;

procedure TPathfindingTile.ReleaseTile(StartingTime, Duration : int64);
var
  t : integer;
begin
  assert(StartingTime + Duration < GameTimeManager.GetTimeStamp + FBlockedTimeSlots.Size * TIMESLOTLENGTH);
  for t := 0 to Duration div TIMESLOTLENGTH do
  begin
    // protect slot be released when it was set by another index
    if FBlockedTimeSlots.IsIndexSet((StartingTime div TIMESLOTLENGTH) + t) then
        FBlockedTimeSlots[(StartingTime div TIMESLOTLENGTH) + t] := False;
  end;
end;

procedure TPathfindingTile.ReserveTile(StartingTime, Duration : int64);
var
  t : integer;
begin
  assert(StartingTime + Duration < GameTimeManager.GetTimeStamp + FBlockedTimeSlots.Size * TIMESLOTLENGTH);
  for t := 0 to (Duration div TIMESLOTLENGTH) do
      FBlockedTimeSlots[(StartingTime div TIMESLOTLENGTH) + t] := True;
end;

function TPathfindingTile.TotalEstimatedCost : Single;
begin
  result := FCostFromSource + FTargetHeuristicCost;
end;

procedure TPathfindingTile.UnblockTile(Entity : TEntity);
begin
  FBlockingEntities.Remove(Entity);
end;

{ TPath }

procedure TPath.AddWaypoint(EnterTimestamp, StayDuration : int64; Tile : TPathfindingTile);
begin
  FWaypoints.add(TPathWaypoint.Create(EnterTimestamp, StayDuration, Tile));
end;

constructor TPath.Create();
begin
  FWaypoints := TObjectList<TPathWaypoint>.Create();
end;

destructor TPath.Destroy;
begin
  ReleasePath;
  FWaypoints.Free;
  inherited;
end;

procedure TPath.ReleasePath;
var
  i : integer;
  currentTime : int64;
begin
  currentTime := GameTimeManager.GetTimeStamp;
  for i := Waypoints.Count - 1 downto 0 do
  begin
    // if any waypoint was completly walked in the past, no need to release this waypoint and all waypoints before
    if (Waypoints[i].EnterTimestamp + Waypoints[i].StayDuration) < currentTime then
        Break;
    Waypoints[i].Tile.ReleaseTile(Waypoints[i].EnterTimestamp, Waypoints[i].StayDuration);
  end;
end;

{ TPathWaypoint }

constructor TPathWaypoint.Create(EnterTimestamp, StayDuration : int64; Tile : TPathfindingTile);
begin
  self.EnterTimestamp := EnterTimestamp;
  self.StayDuration := StayDuration;
  self.Tile := Tile;
end;

{ TPathfindingTileNeighbour }

constructor TPathfindingTileNeighbour.Create(FromTile, ToTile : TPathfindingTile);
var
  TargetOrientation, Orientation : RVector2;
begin
  FNeighbour := ToTile;
  FCost := (ToTile.WorldSpaceBoundaries.Center - FromTile.WorldSpaceBoundaries.Center).length;
  // if FCost > 1.4 then
  // FCost := FCost * 1.1;

  TargetOrientation := Map.Lanes.GetOrientationOfNextLane(FromTile.WorldSpaceBoundaries.Center, 0);
  Orientation := ToTile.WorldSpaceBoundaries.Center - FromTile.WorldSpaceBoundaries.Center;
end;

{ RSmallIntVector2 }

class operator RSmallIntVector2.add(const a, b : RSmallIntVector2) : RSmallIntVector2;
begin
  result.X := a.X + b.X;
  result.Y := a.Y + b.Y;
end;

constructor RSmallIntVector2.Create(X, Y : SmallInt);
begin
  self.X := X;
  self.Y := Y;
end;

end.
