unit Engine.Pathfinding;

interface

uses
  Generics.Collections,
  Generics.Defaults,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Math,
  SysUtils;

type

  ENoPathBetween = class(Exception);

  TNode<T : class> = class;

  EnumEdgeType = (etDirectedEdge, etUndirectedEdge);

  REdge<T : class> = record
    ToNode : TNode<T>;
    Weight : single;
    constructor Create(ToNode : TNode<T>; Weight : single = 1.0);
  end;

  TNode<T : class> = class
    protected
      FEdge : TList<REdge<T>>;
      FData : T;
      FOwnsData : boolean;
    public
      property Data : T read FData;
      property Edges : TList < REdge < T >> read FEdge;
      function getData() : T;
      constructor Create(Data : T; OwnsData : boolean);
      procedure AddEdge(Edge : REdge<T>);
      procedure RemoveNode(Node : TNode<T>); virtual;
      function Neighbours : TList<RTuple<TNode<T>, single>>;
      destructor Destroy; override;
  end;

  TGraph<T : class> = class
    protected
      FNodes : TObjectList<TNode<T>>;
      FNodesOwnData : boolean;
      function ExistsNode(Data : T) : boolean;
      function TryGetNode(Data : T; out oNode : TNode<T>) : boolean;
      function MakeNode(Data : T) : TNode<T>; virtual;
    public
      property Nodes : TObjectList < TNode < T >> read FNodes;
      constructor Create(NodesOwnData : boolean = False);
      procedure AddNode(Data : T);
      procedure AddEdge(Data1, Data2 : T; Weight : single = 1.0; EdgeType : EnumEdgeType = EnumEdgeType.etUndirectedEdge);
      procedure RemoveNode(Data : T);
      procedure ClearGraph;
      destructor Destroy; override;
  end;

  TPathfinding<T : class> = class abstract
    protected
      FGraph : TGraph<T>;
    public
      /// <summary> Owns graph. </summary>
      constructor Create(Graph : TGraph<T>);
      /// <summary> Returns a successive list of all nodes on the path. Returns nil
      /// if there isn't a path.</summary>
      function GetPath(FromNode, ToNode : T) : TList<T>; virtual; abstract;
      function GetCost(FromNode, ToNode : T) : single; virtual; abstract;
      destructor Destroy; override;
  end;

  RRoutingVectorData<T : class> = record
    Target : TNode<T>;
    Cost : single;
    constructor Create(Target : TNode<T>; Cost : single);
  end;

  TRoutingVectorNode<T : class> = class(TNode<T>)
    protected
      FShortestPathNext : TDictionary<TNode<T>, RRoutingVectorData<T>>;
      function UpdatePathDataFromNeightbours : boolean;
      function UpdatePathData(Neighbour : TNode<T>; Weight : single) : boolean;
    public
      constructor Create(Data : T; OwnsData : boolean);
      procedure RemoveNode(Node : TNode<T>); override;
      destructor Destroy; override;
  end;

  /// <summary> A graph holding a discrete structure of node to compute a path on. </summary>
  TRoutingVectorGraph<T : class> = class(TGraph<T>)
    protected
      function MakeNode(Data : T) : TNode<T>; override;
  end;

  /// <summary> Computes graphs on TRoutingVectorGraph classes.</summary>
  TRoutingVectorPathfinding<T : class> = class(TPathfinding<T>)
    protected
    public
      constructor Create(Graph : TRoutingVectorGraph<T>);
      procedure PreComputeWays;
      function GetNextWaypoint(FromNode, ToNode : T) : T;
      function GetPath(FromNode, ToNode : T) : TList<T>; override;
      function GetCost(FromNode, ToNode : T) : single; override;
  end;

  /// <summary> A graph holding a discrete structure of node to compute a path on. </summary>
  TAStarGraph<T : class> = class(TGraph<T>)
    protected
      function MakeNode(Data : T) : TNode<T>; override;
  end;

  TAStarNode<T : class> = class(TNode<T>)
    protected
      FCost : single;
      Fpredecessor : TAStarNode<T>;
  end;

  /// <summary> Computes graphs on TRoutingVectorGraph classes.</summary>
  TAStarPathfinding<T : class> = class(TPathfinding<T>)
    public
      type
      FuncGetPriorityOfItem = reference to function(item : T) : single;
    protected
      FOpenList : TPriorityQueue<TNode<T>>;
      FClosedList : TList<TNode<T>>;
      FGuess : FuncGetPriorityOfItem;
    public
      constructor Create(Graph : TGraph<T>);
      procedure SetGuess(Mapping : FuncGetPriorityOfItem);
      function GetPath(FromNode, ToNode : T) : TList<T>; override;
      function GetCost(FromNode, ToNode : T) : single; override;
      destructor Destroy; override;
  end;

implementation

{ TNode }

procedure TNode<T>.AddEdge(Edge : REdge<T>);
var
  i : integer;
begin
  for i := 0 to FEdge.Count - 1 do
    if FEdge[i].ToNode = Edge.ToNode then
    begin
      FEdge[i] := Edge;
      exit;
    end;
  FEdge.Add(Edge);
end;

constructor TNode<T>.Create(Data : T; OwnsData : boolean);
begin
  FData := Data;
  FEdge := TList < REdge < T >>.Create;
  FOwnsData := OwnsData;
end;

destructor TNode<T>.Destroy;
begin
  FEdge.Free;
  if FOwnsData then FData.Free;
  inherited;
end;

function TNode<T>.getData : T;
begin
  Result := FData as T;
end;

function TNode<T>.Neighbours : TList<RTuple<TNode<T>, single>>;
var
  Edge : REdge<T>;
begin
  Result := TList < RTuple < TNode<T>, single >>.Create;
  for Edge in FEdge do
  begin
    Result.Add(RTuple<TNode<T>, single>.Create(Edge.ToNode, Edge.Weight));
  end;
end;

procedure TNode<T>.RemoveNode(Node : TNode<T>);
var
  i : integer;
begin
  for i := FEdge.Count - 1 downto 0 do
    if FEdge[i].ToNode = Node then FEdge.Delete(i);
end;

{ REdge<T> }

constructor REdge<T>.Create(ToNode : TNode<T>; Weight : single = 1.0);
begin
  self.ToNode := ToNode;
  assert(Weight >= 0);
  self.Weight := Weight;
end;

{ TPathfinding }

constructor TPathfinding<T>.Create(Graph : TGraph<T>);
begin
  FGraph := Graph;
end;

destructor TPathfinding<T>.Destroy;
begin
  FGraph.Free;
  inherited;
end;

{ RRoutingVectorData }

constructor RRoutingVectorData<T>.Create(Target : TNode<T>; Cost : single);
begin
  self.Target := Target;
  self.Cost := Cost;
end;

{ TRoutingVectorNode }

constructor TRoutingVectorNode<T>.Create(Data : T; OwnsData : boolean);
begin
  inherited Create(Data, OwnsData);
  FShortestPathNext := TDictionary < TNode<T>, RRoutingVectorData < T >>.Create;
  FShortestPathNext.Add(self, RRoutingVectorData<T>.Create(self, 0));
end;

destructor TRoutingVectorNode<T>.Destroy;
begin
  FShortestPathNext.Free;
  inherited;
end;

procedure TRoutingVectorNode<T>.RemoveNode(Node : TNode<T>);
begin
  inherited;
  FShortestPathNext.Remove(Node);
end;

function TRoutingVectorNode<T>.UpdatePathData(Neighbour : TNode<T>; Weight : single) : boolean;
var
  Data, myData : RRoutingVectorData<T>;
  Target : TNode<T>;
  aNeighbour : TRoutingVectorNode<T>;
  Cost : single;
begin
  Result := False;
  aNeighbour := (Neighbour as TRoutingVectorNode<T>);
  for Target in aNeighbour.FShortestPathNext.Keys do
  begin
    Data := aNeighbour.FShortestPathNext[Target];
    Cost := Data.Cost + Weight;
    if (not FShortestPathNext.TryGetValue(Target, myData)) or (myData.Cost > Cost) then
    begin
      FShortestPathNext.AddOrSetValue(Target, RRoutingVectorData<T>.Create(Neighbour, Cost));
      Result := True;
    end;
  end;
end;

function TRoutingVectorNode<T>.UpdatePathDataFromNeightbours : boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to FEdge.Count - 1 do Result := UpdatePathData(FEdge[i].ToNode, FEdge[i].Weight) or Result;
end;

{ TGraph }

procedure TGraph<T>.AddEdge(Data1, Data2 : T; Weight : single; EdgeType : EnumEdgeType);
var
  wNode1, wNode2 : TNode<T>;
begin
  if not(TryGetNode(Data1, wNode1) and TryGetNode(Data2, wNode2)) then exit;
  wNode1.AddEdge(REdge<T>.Create(wNode2, Weight));
  if EdgeType = EnumEdgeType.etUndirectedEdge then
      wNode2.AddEdge(REdge<T>.Create(wNode1, Weight));
end;

procedure TGraph<T>.AddNode(Data : T);
begin
  if not ExistsNode(Data) then FNodes.Add(MakeNode(Data));
end;

procedure TGraph<T>.ClearGraph;
begin
  FNodes.Clear;
end;

constructor TGraph<T>.Create(NodesOwnData : boolean = False);
begin
  FNodes := TObjectList < TNode < T >>.Create;
  FNodesOwnData := NodesOwnData;
end;

destructor TGraph<T>.Destroy;
begin
  FNodes.Free;
  inherited;
end;

function TGraph<T>.ExistsNode(Data : T) : boolean;
var
  wNode : TNode<T>;
begin
  Result := False;
  for wNode in FNodes do
    if wNode.FData = Data then exit(True);
end;

function TGraph<T>.MakeNode(Data : T) : TNode<T>;
begin
  Result := TNode<T>.Create(Data, FNodesOwnData);
end;

procedure TGraph<T>.RemoveNode(Data : T);
var
  wNode, aNode : TNode<T>;
begin
  if TryGetNode(Data, wNode) then
  begin
    for aNode in FNodes do aNode.RemoveNode(wNode);
    FNodes.Remove(wNode);
  end;
end;

function TGraph<T>.TryGetNode(Data : T; out oNode : TNode<T>) : boolean;
var
  wNode : TNode<T>;
begin
  Result := False;
  for wNode in FNodes do
    if wNode.FData = Data then
    begin
      oNode := wNode;
      exit(True);
    end;
end;

{ TRoutingVectorPathfinding }

constructor TRoutingVectorPathfinding<T>.Create(Graph : TRoutingVectorGraph<T>);
begin
  inherited Create(Graph);
end;

procedure TRoutingVectorPathfinding<T>.PreComputeWays;
var
  change : boolean;
  aNode : TNode<T>;
begin
  if FGraph.Nodes.Count <= 0 then exit;
  change := True;
  while change do
  begin
    change := False;
    for aNode in FGraph.Nodes do change := (aNode as TRoutingVectorNode<T>).UpdatePathDataFromNeightbours or change;
  end;
end;

function TRoutingVectorPathfinding<T>.GetCost(FromNode, ToNode : T) : single;
var
  PreviousNode, TargetNode : TNode<T>;
  Value : RRoutingVectorData<T>;
begin
  Result := -1;
  if FGraph.TryGetNode(FromNode, PreviousNode) and FGraph.TryGetNode(ToNode, TargetNode) and TRoutingVectorNode<T>(PreviousNode).FShortestPathNext.TryGetValue(TargetNode, Value) then Result := Value.Cost;
end;

function TRoutingVectorPathfinding<T>.GetNextWaypoint(FromNode, ToNode : T) : T;
var
  bNode, aNode : TNode<T>;
  nNode : RRoutingVectorData<T>;
begin
  if FGraph.TryGetNode(FromNode, bNode) and FGraph.TryGetNode(ToNode, aNode) and (bNode as TRoutingVectorNode<T>).FShortestPathNext.TryGetValue(aNode, nNode) then
  begin
    Result := nNode.Target.FData;
  end
  else Result := nil;
end;

function TRoutingVectorPathfinding<T>.GetPath(FromNode, ToNode : T) : TList<T>;
begin
  Result := TList<T>.Create;
  Result.Add(FromNode);
  while FromNode <> ToNode do
  begin
    FromNode := GetNextWaypoint(FromNode, ToNode);
    if FromNode = nil then
    begin
      FreeAndNil(Result);
      exit;
    end;
    Result.Add(FromNode);
  end;
end;

{ TRoutingVectorGraph }

function TRoutingVectorGraph<T>.MakeNode(Data : T) : TNode<T>;
begin
  Result := TRoutingVectorNode<T>.Create(Data, FNodesOwnData);
end;

{ TAStarGraph<T> }

function TAStarGraph<T>.MakeNode(Data : T) : TNode<T>;
begin
  Result := TAStarNode<T>.Create(Data, FNodesOwnData);
end;

{ TAStarPathfinding<T> }

constructor TAStarPathfinding<T>.Create(Graph : TGraph<T>);
begin
  inherited Create(Graph);
  FOpenList := TPriorityQueue < TNode < T >>.Create();
  FClosedList := TList < TNode < T >>.Create;
end;

destructor TAStarPathfinding<T>.Destroy;
begin
  FOpenList.Free;
  FClosedList.Free;
  inherited;
end;

function TAStarPathfinding<T>.GetCost(FromNode, ToNode : T) : single;
begin

end;

function TAStarPathfinding<T>.GetPath(FromNode, ToNode : T) : TList<T>;
var
  currentNode : TNode<T>;
  successor : RTuple<TNode<T>, single>;
  fNode, TNode : TNode<T>;
  Neighbours : TList<RTuple<TNode<T>, single>>;
  nNode : RRoutingVectorData<T>;
  tentative_g, f : single;
begin
  if not(FGraph.TryGetNode(FromNode, fNode) and FGraph.TryGetNode(ToNode, TNode)) then exit(nil);

  for currentNode in FGraph.Nodes do
  begin
    (currentNode as TAStarNode<T>).FCost := Infinity;
  end;

  FOpenList.Clear;
  FClosedList.Clear;
  // Initialisierung der Open List, die Closed List ist noch leer
  // (die Priorität bzw. der f Wert des Startknotens ist unerheblich)
  FOpenList.insert(fNode, 0);
  // diese Schleife wird durchlaufen bis entweder
  // - die optimale Lösung gefunden wurde oder
  // - feststeht, dass keine Lösung existiert
  repeat
    // Knoten mit dem geringsten f Wert aus der Open List entfernen
    currentNode := FOpenList.extractMin();
    // Wurde das Ziel gefunden?
    if currentNode = TNode then exit(TList<T>.Create);
    // Der aktuelle Knoten soll durch nachfolgende Funktionen
    // nicht weiter untersucht werden damit keine Zyklen entstehen
    FClosedList.Add(currentNode);
    // Wenn das Ziel noch nicht gefunden wurde: Nachfolgeknoten
    // des aktuellen Knotens auf die Open List setzen

    // überprüft alle Nachfolgeknoten und fügt sie der Open List hinzu, wenn entweder
    // - der Nachfolgeknoten zum ersten Mal gefunden wird oder
    // - ein besserer Weg zu diesem Knoten gefunden wird
    Neighbours := currentNode.Neighbours;
    for successor in Neighbours do
    begin
      // wenn der Nachfolgeknoten bereits auf der Closed List ist - tue nichts
      if FClosedList.contains(successor.a) then continue;
      // g Wert für den neuen Weg berechnen: g Wert des Vorgängers plus
      // die Kosten der gerade benutzten Kante
      tentative_g := (currentNode as TAStarNode<T>).FCost + successor.b;
      // wenn der Nachfolgeknoten bereits auf der Open List ist,
      // aber der neue Weg nicht besser ist als der alte - tue nichts
      if FOpenList.contains(successor.a) and (tentative_g >= (successor.a as TAStarNode<T>).FCost) then
          continue;
      // Vorgängerzeiger setzen und g Wert merken
      (successor.a as TAStarNode<T>).Fpredecessor := currentNode as TAStarNode<T>;
      (successor.a as TAStarNode<T>).FCost := tentative_g;
      // f Wert des Knotens in der Open List aktualisieren
      // bzw. Knoten mit f Wert in die Open List einfügen
      f := tentative_g + FGuess(successor.a);
      if FOpenList.contains(successor.a) then
          FOpenList.decreaseKey(successor.a, f)
      else
          FOpenList.insert(successor.a, f)
    end;
  until FOpenList.Count = 0;
  // die Open List ist leer, es existiert kein Pfad zum Ziel
  exit(nil);
end;

procedure TAStarPathfinding<T>.SetGuess(Mapping : FuncGetPriorityOfItem);
begin
  FGuess := Mapping;
end;

end.
