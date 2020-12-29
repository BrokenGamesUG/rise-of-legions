unit Engine.Pathfinding.Helper;

interface

uses
  Generics.Collections,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Pathfinding,
  Math;

type

  TMultipolygonPathfinding = class
    protected
      type
      RNodeLink = record
        Polygon : TPolygon;
        index : integer;
        Data : TObjectWrapper<RVector2>;
      end;
    var
      FGraph : TRoutingVectorGraph<TObjectWrapper<RVector2>>;
      FPathfinding : TRoutingVectorPathfinding<TObjectWrapper<RVector2>>;
      FPoly : TMultipolygon;
      function ConstructGraph : TRoutingVectorGraph<TObjectWrapper<RVector2>>;
    public
      /// <summary> Does not own the polygon! </summary>
      constructor Create(Polygon : TMultipolygon);
      /// <summary> Returns the shortest path between two points, which lies within the multipolygon.
      /// WARNING: Only works if no two borders of the polygons are intersecting. </summary>
      function FindPath(Startpoint, Endpoint : RVector2) : TPolygon;
      procedure DrawGraph;
      destructor Destroy; override;
  end;

implementation

function TMultipolygonPathfinding.ConstructGraph : TRoutingVectorGraph<TObjectWrapper<RVector2>>;
var
  i, j, tempi : integer;
  temp : RNodeLink;
  Line : RLine2D;
  GraphNodes : TList<RNodeLink>;
  Poly : TMultipolygon.RMultipolygon;
begin
  GraphNodes := TList<RNodeLink>.Create;
  Result := TRoutingVectorGraph < TObjectWrapper < RVector2 >>.Create(true);

  for Poly in FPoly.Polygons do
    if Poly.Polygon.Closed then
    begin
      for i := 0 to Poly.Polygon.Nodes.Count - 1 do
      begin
        if Poly.Polygon.IsNodeConvex(i) <> Poly.Subtractive then
        begin
          temp.Polygon := Poly.Polygon;
          temp.index := i;
          temp.Data := TObjectWrapper<RVector2>.Create(Poly.Polygon.Nodes[i]);
          GraphNodes.Add(temp);
        end;
      end;
    end;
  for i := 0 to GraphNodes.Count - 1 do Result.AddNode(GraphNodes[i].Data);
  for i := 0 to GraphNodes.Count - 2 do
  begin
    for j := i + 1 to GraphNodes.Count - 1 do
    begin
      Line := RLine2D.CreateFromPoints(GraphNodes[i].Polygon.Nodes[GraphNodes[i].index], GraphNodes[j].Polygon.Nodes[GraphNodes[j].index]);
      tempi := abs(GraphNodes[i].index - GraphNodes[j].index);
      if (GraphNodes[i].Polygon = GraphNodes[j].Polygon) and ((tempi = 1) or (tempi = GraphNodes[i].Polygon.Nodes.Count - 1)) then
      begin
        Result.AddEdge(GraphNodes[i].Data, GraphNodes[j].Data, Line.Direction.Length);
      end
      else
        if FPoly.IsLineInMultiPolygon(RLine2D.CreateFromPoints(Line.Lerp(0.01), Line.Lerp(0.99))) then
      begin
        Result.AddEdge(GraphNodes[i].Data, GraphNodes[j].Data, Line.Direction.Length);
      end;
    end;
  end;
  GraphNodes.Free;
end;

constructor TMultipolygonPathfinding.Create(Polygon : TMultipolygon);
begin
  FPoly := Polygon;
  FGraph := ConstructGraph;
  FPathfinding := TRoutingVectorPathfinding < TObjectWrapper < RVector2 >>.Create(FGraph);
  FPathfinding.PreComputeWays;
end;

destructor TMultipolygonPathfinding.Destroy;
begin
  FPathfinding.Free;
  inherited;
end;

procedure TMultipolygonPathfinding.DrawGraph;
var
  i, j : integer;
begin
  for i := 0 to FGraph.Nodes.Count - 1 do
    for j := 0 to FGraph.Nodes[i].Edges.Count - 1 do
      // LinePool.AddLine(RVector3.CreateX0Y(FGraph.Nodes[i].getData < TObjectWrapper < RVector2 >>.Value).SetY(1), RVector3.CreateX0Y(FGraph.Nodes[i].Edges[j].ToNode.getData < TObjectWrapper < RVector2 >>.Value).SetY(1), RColor.CWHITE);

end;

function TMultipolygonPathfinding.FindPath(Startpoint, Endpoint : RVector2) : TPolygon;
type
  RConnection = record
    Node : TObjectWrapper<RVector2>;
    Cost : single;
  end;
var
  Way : TList<TObjectWrapper<RVector2>>;
  i, j : integer;
  Line : RLine2D;
  temp : RConnection;
  bestStart, bestEnd : TObjectWrapper<RVector2>;
  bestCost, Cost : single;
  StartEntrypoint, EndEntrypoint : TList<RConnection>;
begin
  if FPoly.IsLineInMultiPolygon(RLine2D.CreateFromPoints(Startpoint, Endpoint)) then exit(TPolygon.Create([Startpoint, Endpoint]));

  StartEntrypoint := TList<RConnection>.Create;
  EndEntrypoint := TList<RConnection>.Create;

  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    Line := RLine2D.CreateFromPoints(FGraph.Nodes[i].getData.Value, Startpoint);
    Line.Origin := Line.Lerp(0.01);
    if FPoly.IsLineInMultiPolygon(Line) then
    begin
      temp.Cost := Line.Direction.Length;
      temp.Node := FGraph.Nodes[i].Data;
      StartEntrypoint.Add(temp);
    end;
    Line := RLine2D.CreateFromPoints(FGraph.Nodes[i].getData.Value, Endpoint);
    Line.Origin := Line.Lerp(0.01);
    if FPoly.IsLineInMultiPolygon(Line) then
    begin
      temp.Cost := Line.Direction.Length;
      temp.Node := FGraph.Nodes[i].Data;
      EndEntrypoint.Add(temp);
    end;
  end;

  bestCost := -1;
  bestStart := nil;
  bestEnd := nil;
  for i := 0 to StartEntrypoint.Count - 1 do
    for j := 0 to EndEntrypoint.Count - 1 do
    begin
      Cost := StartEntrypoint[i].Cost + FPathfinding.GetCost(StartEntrypoint[i].Node, EndEntrypoint[j].Node) + EndEntrypoint[j].Cost;
      if (Cost < bestCost) or (bestCost < 0) then
      begin
        bestCost := Cost;
        bestStart := StartEntrypoint[i].Node;
        bestEnd := EndEntrypoint[j].Node;
      end;
    end;

  StartEntrypoint.Free;
  EndEntrypoint.Free;

  Result := nil;
  if (bestStart = nil) or (bestEnd = nil) then exit;

  Way := FPathfinding.GetPath(bestStart, bestEnd);
  Result := TPolygon.Create;
  Result.AddNode(Startpoint);
  for i := 0 to Way.Count - 1 do
  begin
    Result.AddNode((Way[i] as TObjectWrapper<RVector2>).Value);
  end;
  Result.AddNode(Endpoint);
  Way.Free;

end;

end.
