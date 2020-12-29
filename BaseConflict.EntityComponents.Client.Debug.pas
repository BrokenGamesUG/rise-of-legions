unit BaseConflict.EntityComponents.Client.Debug;

interface

uses
  Generics.Collections,
  System.SysUtils,
  System.RegularExpressions,
  System.Rtti,
  Engine.Core,
  Engine.Vertex,
  Engine.GUI,
  Engine.Script,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Input,
  Engine.Terrain,
  Engine.Math,
  Engine.Math.Collision3D,
  Engine.Log,
  Engine.Math.Collision2D,
  BaseConflict.Map,
  BaseConflict.Game,
  BaseConflict.Types.Target,
  BaseConflict.Types.Shared,
  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Globals,
  BaseConflict.Globals.Client,
  BaseConflict.Classes.Pathfinding,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Client;

type

  {$RTTI INHERIT}
  /// <summary> Visualizes the actions of a movement. </summary>
  TMovementVisualizerComponent = class(TEntityComponent)
    protected
      StandPos : RVector3;
      TargetReachedPos : RVector3;
      TargetReachedTimer : TTimer;
      StandTimer : TTimer;
      FTarget : RTarget;
      SyncTimer : TTimer;
      FSyncPosition : RVector3;
    published
      [XEvent(eiMoveTargetReached, epLast, etTrigger)]
      /// <summary> Green circle at position. </summary>
      function OnMoveTargetReached() : boolean;
      [XEvent(eiStand, epLast, etTrigger)]
      /// <summary> Yellowcircle at position. </summary>
      function OnStand() : boolean;
      [XEvent(eiMove, epLast, etTrigger)]
      /// <summary> Nothing. </summary>
      function OnMove(Target : RParam) : boolean;
      [XEvent(eiMoveTo, epLower, etTrigger)]
      /// <summary> Updates the spline regarding the new target. </summary>
      function OnMoveTo(Target, Range : RParam) : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Draw debugvisualizations. </summary>
      function OnIdle() : boolean;
      [XEvent(eiSyncPosition, epLast, etTrigger)]
      /// <summary> Blue circle at position. </summary>
      function OnSyncPosition(Pos : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes the actions of a movement. </summary>
  TPositionVisualizerComponent = class(TEntityComponent)
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Draw debugvisualizations. </summary>
      function OnIdle() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes the actions of a movement. </summary>
  TSubPositionVisualizerComponent = class(TEntityComponent)
    protected
      FName : string;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Draw debugvisualizations. </summary>
      function OnIdle() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Name : string); reintroduce;
  end;

  TPathfindingGridVisualizerComponent = class(TEntityComponent)
    protected
      FShowCoordinate : boolean;
      FRenderFlow : boolean;
      FVisLength : integer;
      FPathes : TList<TArray<TPathfindingTile>>;
      FLines : TList<RLine>;
      FMousePath : TArray<TPathfindingTile>;
    published
      [XEvent(eiKeybindingEvent, epMiddle, etTrigger, esGlobal)]
      function OnKeybindingEvent() : boolean;
      [XEvent(eiMouseMoveEvent, epMiddle, etTrigger, esGlobal)]
      function OnMouseMove(Position, Difference : RParam) : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Draw debugvisualizations. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

  TPathfindingPathVisualizerComponent = class(TEntityComponent)
    protected
      FCurrentPath : TArray<TPathfindingTile>;
      FStart, FTarget : RVector2;
    published
      [XEvent(eiSyncPath, epLast, etTrigger)]
      /// <summary> Read path when set. </summary>
      function OnSyncPath(Start, Target, Path : RParam) : boolean;

      [XEvent(eiStand, epLast, etTrigger)]
      /// <summary> Stand still, now. </summary>
      function OnStand() : boolean;

      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Draw debugvisualizations. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); override;
  end;

var
  DisplayPathfindingVisualization : boolean = False;

implementation

{ TMovementVisualizerComponent }

constructor TMovementVisualizerComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  TargetReachedTimer := TTimer.Create(3000);
  StandTimer := TTimer.Create(3000);
  SyncTimer := TTimer.Create(3000);
end;

destructor TMovementVisualizerComponent.Destroy;
begin
  TargetReachedTimer.Free;
  StandTimer.Free;
  SyncTimer.Free;
  inherited;
end;

function TMovementVisualizerComponent.OnIdle : boolean;
begin
  Result := True;
  if not TargetReachedTimer.Expired then LinePool.AddCircle(TargetReachedPos + 2 * RVector3.UNITY, RVector3.UNITY, 1, RColor.CGREEN);
  if not StandTimer.Expired then LinePool.AddCircle(StandPos + 2 * RVector3.UNITY, RVector3.UNITY, 1.33, RColor.CYELLOW);
  if not SyncTimer.Expired then LinePool.AddCircle(FSyncPosition + 2 * RVector3.UNITY, RVector3.UNITY, 1.66, RColor.CBLUE);
  LinePool.AddLine(Owner.DisplayPosition + 2 * RVector3.UNITY, FTarget.GetTargetPosition.X0Y + 2 * RVector3.UNITY, RColor.CRED);
  LinePool.AddCircle(FTarget.GetTargetPosition.X0Y + 2 * RVector3.UNITY, RVector3.UNITY, 2, RColor.CRED);
end;

function TMovementVisualizerComponent.OnMove(Target : RParam) : boolean;
begin
  Result := True;
end;

function TMovementVisualizerComponent.OnMoveTargetReached : boolean;
begin
  Result := True;
  TargetReachedPos := Owner.DisplayPosition;
  TargetReachedTimer.Start;
end;

function TMovementVisualizerComponent.OnMoveTo(Target, Range : RParam) : boolean;
begin
  Result := True;
  FTarget := Target.AsType<RTarget>;
end;

function TMovementVisualizerComponent.OnStand : boolean;
begin
  Result := True;
  StandPos := Owner.DisplayPosition;
  StandTimer.Start;
end;

function TMovementVisualizerComponent.OnSyncPosition(Pos : RParam) : boolean;
begin
  Result := True;
  FSyncPosition := Pos.AsVector3;
  SyncTimer.Start;
end;

{ TPositionVisualizerComponent }

function TPositionVisualizerComponent.OnIdle : boolean;
begin
  Result := True;
  LinePool.AddCoordinateSystem(RMatrix.CreateTranslation(Owner.DisplayPosition) * RMatrix.CreateSaveBase(Owner.DisplayFront, Owner.DisplayUp));
end;

{ TSubPositionVisualizerComponent }

constructor TSubPositionVisualizerComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Name : string);
begin
  inherited CreateGrouped(Owner, Group);
  FName := name;
end;

function TSubPositionVisualizerComponent.OnIdle : boolean;
begin
  Result := True;
  LinePool.AddCoordinateSystem(Eventbus.Read(eiSubPositionByString, [FName], ComponentGroup).AsType<RMatrix>);
end;

{ TPathfindingVisualizerComponent }

constructor TPathfindingGridVisualizerComponent.Create(Owner : TEntity);
var
  Target, Source : TPathfindingTile;
  y, x : integer;
begin
  inherited;
  FPathes := TList < TArray < TPathfindingTile >>.Create;
  FLines := TList<RLine>.Create;
  Target := Map.Pathfinding.GridBy2D[RSmallIntVector2.Create(220, 135)];
  for y := 104 to 136 do
  begin
    Source := Map.Pathfinding.GridBy2D[RSmallIntVector2.Create(60, y)];
    FPathes.Add(Map.Pathfinding.ComputeDebugPath(Source, Target, 50, ldNormal))
  end;

  for x := 60 to 76 do
  begin
    Source := Map.Pathfinding.GridBy2D[RSmallIntVector2.Create(x, 135)];
    FPathes.Add(Map.Pathfinding.ComputeDebugPath(Source, Target, 50, ldNormal))
  end;
  //
  // for y := 104 to 126 do
  // begin
  // Source := Map.Pathfinding.GridBy2D[RIntVector2.Create(190, y)];
  // FPathes.Add(Map.Pathfinding.ComputeDebugPath(Source, Target, 30))
  // end;
  FVisLength := 1;
end;

destructor TPathfindingGridVisualizerComponent.Destroy;
begin
  FPathes.Free;
  FLines.Free;
  inherited;
end;

function TPathfindingGridVisualizerComponent.OnIdle : boolean;
var
  x, y, i : integer;
  rectangle : RRectFloat;
  anyWalkableNeighbor : boolean;
  Neighbour : TPathfindingTileNeighbour;
  blocked : boolean;
  Path : TArray<TPathfindingTile>;
  TargetPosition, SourcePosition : RVector2;
  Direction : EnumLaneDirection;
begin
  Result := True;

  if DisplayPathfindingVisualization then
  begin
    // grid
    for y := 0 to Map.Pathfinding.TileHeightCount - 1 do
      for x := 0 to Map.Pathfinding.TileWidthCount - 1 do
      begin
        rectangle := Map.Pathfinding.Grid[x, y].WorldSpaceBoundaries;
        if GFXD.MainScene.Camera.ViewingFrustum.ContainsAABB(RAABB.Create(rectangle.Center.X0Y)) then
        begin
          if Map.Pathfinding.Grid[x, y].IsWalkable(1) then
              blocked := False
          else
          begin
            blocked := True;
            anyWalkableNeighbor := False;
            for Neighbour in Map.Pathfinding.Grid[x, y].Neighbours do
            begin
              anyWalkableNeighbor := anyWalkableNeighbor or Neighbour.NeighbourTile.IsWalkable(1);
              if anyWalkableNeighbor then
                  break;
            end;
            if not anyWalkableNeighbor then
              // skip every tile that is not directly important for pathfinding
                Continue;
          end;
          if not blocked then
              LinePool.AddRect(rectangle.LeftTop.X0Y + RVector3.Create0Y0(GROUND_EPSILON),
              rectangle.RightTop.X0Y + RVector3.Create0Y0(GROUND_EPSILON),
              rectangle.RightBottom.X0Y + RVector3.Create0Y0(GROUND_EPSILON),
              rectangle.LeftBottom.X0Y + RVector3.Create0Y0(GROUND_EPSILON), RColor(RColor.CGREEN).SetAlphaF(0.5))
          else
          begin
            LinePool.AddLine(rectangle.LeftTop.X0Y + RVector3.Create0Y0(GROUND_EPSILON),
              rectangle.RightBottom.X0Y + RVector3.Create0Y0(GROUND_EPSILON), RColor.CRED);
            LinePool.AddLine(rectangle.RightTop.X0Y + RVector3.Create0Y0(GROUND_EPSILON),
              rectangle.LeftBottom.X0Y + RVector3.Create0Y0(GROUND_EPSILON), RColor.CRED);
          end;

        end;
      end;
  end;

  if FRenderFlow then
  begin
    for Path in FPathes do
    begin
      // path
      for i := 1 to length(Path) - 1 do
      begin
        LinePool.AddLine(Path[i - 1].WorldSpaceBoundaries.Center.X0Y(GROUND_EPSILON),
          Path[i].WorldSpaceBoundaries.Center.X0Y(GROUND_EPSILON), RColor.CBLUE);
        if FVisLength = i then
        begin
          SourcePosition := Path[i - 1].WorldSpaceBoundaries.Center;
          TargetPosition := Path[i].WorldSpaceBoundaries.Center;
          if (TargetPosition - SourcePosition).x > 0 then
              Direction := ldNormal
          else
              Direction := ldReverse;
          TargetPosition := Map.Lanes.GetNextLaneToPoint(SourcePosition)
            .GetNextWaypoint(SourcePosition, Direction).ProjectPoint(SourcePosition);

          LinePool.AddLine(SourcePosition.X0Y(GROUND_EPSILON), TargetPosition.X0Y(GROUND_EPSILON), RColor.CPINK);
        end;
      end;
    end;
    if assigned(FMousePath) then
      for i := 1 to length(FMousePath) - 1 do
      begin
        LinePool.AddLine(FMousePath[i - 1].WorldSpaceBoundaries.Center.X0Y(0.1),
          FMousePath[i].WorldSpaceBoundaries.Center.X0Y(0.1), RColor.CRED);
      end;
  end;
end;

function TPathfindingGridVisualizerComponent.OnKeybindingEvent() : boolean;
begin
  Result := True;
  if KeybindingManager.KeyUp(kbPathfindingVisualize) then
      DisplayPathfindingVisualization := not DisplayPathfindingVisualization;
  if KeybindingManager.KeyUp(kbPathfindingCoordinate) then
      FShowCoordinate := not FShowCoordinate;
  if KeybindingManager.KeyUp(kbPathfindingFlow) then
      FRenderFlow := not FRenderFlow;
  if KeybindingManager.KeyUp(kbPathfindingIncVisibleLength) then
      inc(FVisLength);
  if KeybindingManager.KeyUp(kbPathfindingDecVisibleLength) then
      dec(FVisLength);
end;

function TPathfindingGridVisualizerComponent.OnMouseMove(Position, Difference : RParam) : boolean;
var
  Tile : TPathfindingTile;
begin
  Result := True;
  Tile := Map.Pathfinding.GetTileByPosition(RPlane.XZ.IntersectRay(GFXD.MainScene.Camera.Clickvector(Position.AsIntVector2)).XZ);
  FMousePath := Map.Pathfinding.ComputeDebugPath(Tile, Map.Pathfinding.GridBy2D[RSmallIntVector2.Create(220, 135)], 10, ldNormal);
  if FShowCoordinate then
  begin
    HLog.Console('Pathgridposition: ' + string(Tile.GridPosition));
    HLog.Console('Worldposition: ' + string(Tile.WorldSpaceBoundaries.Center));
  end;
end;

{ TPathfindingPathVisualizerComponent }

constructor TPathfindingPathVisualizerComponent.Create(Owner : TEntity);
begin
  inherited;
end;

function TPathfindingPathVisualizerComponent.OnIdle : boolean;
var
  i : integer;
  rectangle : RRectFloat;
begin
  Result := True;
  if DisplayPathfindingVisualization and (length(FCurrentPath) > 0) then
  begin
    LinePool.AddSphere(FStart.X0Y(0.02), 0.15, RColor.CYELLOW);
    // path
    for i := 1 to length(FCurrentPath) - 1 do
        LinePool.AddLine(FCurrentPath[i - 1].WorldSpaceBoundaries.Center.X0Y(GROUND_EPSILON),
        FCurrentPath[i].WorldSpaceBoundaries.Center.X0Y(GROUND_EPSILON), RColor.CBLUE);
    // target
    LinePool.AddSphere(FTarget.X0Y(0.02), 0.25, RColor.CPINK);
    rectangle := Map.Pathfinding.GetTileByPosition(FTarget).WorldSpaceBoundaries;
    LinePool.AddLine(rectangle.LeftTop.X0Y + RVector3.Create0Y0(GROUND_EPSILON),
      rectangle.RightBottom.X0Y + RVector3.Create0Y0(GROUND_EPSILON), RColor.CPINK);
    LinePool.AddLine(rectangle.RightTop.X0Y + RVector3.Create0Y0(GROUND_EPSILON),
      rectangle.LeftBottom.X0Y + RVector3.Create0Y0(GROUND_EPSILON), RColor.CPINK);
  end;
end;

function TPathfindingPathVisualizerComponent.OnStand : boolean;
begin
  Result := True;
  // if stand, no path will be computed
  FCurrentPath := nil;
end;

function TPathfindingPathVisualizerComponent.OnSyncPath(Start, Target, Path : RParam) : boolean;
begin
  Result := True;
  FStart := Start.AsVector2;
  FTarget := Target.AsVector2;
  FCurrentPath := HArray.Map<RSmallIntVector2, TPathfindingTile>(Path.AsArray<RSmallIntVector2>,
    function(const Coord : RSmallIntVector2) : TPathfindingTile
    begin
      Result := Map.Pathfinding.GridBy2D[Coord];
    end);
end;

initialization

ScriptManager.ExposeClass(TMovementVisualizerComponent);
ScriptManager.ExposeClass(TPositionVisualizerComponent);
ScriptManager.ExposeClass(TSubPositionVisualizerComponent);
ScriptManager.ExposeClass(TPathfindingGridVisualizerComponent);
ScriptManager.ExposeClass(TPathfindingPathVisualizerComponent);

end.
