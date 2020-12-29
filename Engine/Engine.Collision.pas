unit Engine.Collision;

interface

uses
  Math,
  Generics.Collections,
  SysUtils,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Serializer.Types,
  Engine.Serializer;

const
  DEBUG_DRAW_COLOR  = $FFFF0000;
  DEBUG_DRAW_COLOR2 = $402020FF;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  TLooseQuadTree<T> = class;
  TLooseQuadTreeNode<T> = class;

  TLooseQuadTreeNodeData<T> = class
    protected
      FOwner : TLooseQuadTreeNode<T>;
      FOwningTree : TLooseQuadTree<T>;
      procedure Remove;
    public
      Boundaries : RCircle;
      Data : T;
      constructor Create(Boundaries : RCircle; Data : T);
      /// <summary> Updates this item in the tree. Should be used after Boundaries are changed. </summary>
      procedure UpdateInTree;
      destructor Destroy; override;
  end;

  /// <summary> A node of a loose quadtree. Nothing interesting for the user. </summary>
  TLooseQuadTreeNode<T> = class
    protected
      const
      // do not change!
      CHILDCOUNT = 4;
      // should be greater 1
      LOOSEMODIFIER = 2;
    protected type
      // workaround because using the type directly in variable will cause an error on jumping (ctrl+click)
      AChildren<Tnx> = array [0 .. CHILDCOUNT - 1] of TLooseQuadTreeNode<Tnx>;
    protected
      FChildren : AChildren<T>;
      FRealRect, FLooseRect : RRectFloat;
      FBorderSizeHalf, FMinWidth : single;
      FHasChildren, FHasItems : boolean;
      FItems : TList<TLooseQuadTreeNodeData<T>>;
      FParent : TLooseQuadTreeNode<T>;
      // split this node into 4 childs
      procedure Split; virtual;
      // maintain FHasItems variable
      procedure UpdateEmptyness;
      procedure AddItem(Item : TLooseQuadTreeNodeData<T>);
      procedure RemoveItem(Item : TLooseQuadTreeNodeData<T>);
    public
      /// <summary> Returns whether there are items in or beneath this node. </summary>
      property HasItems : boolean read FHasItems;
      /// <summary> Returns whether this node has childnodes or is a leaf. </summary>
      property HasChildren : boolean read FHasChildren;
      /// <summary> Adds an item recursive. Searching for the correct spot to insert. </summary>
      procedure AddItemRecursive(Item : TLooseQuadTreeNodeData<T>); virtual;
      /// <summary> Removes an item recursive. </summary>
      procedure RemoveItemRecursive(Item : TLooseQuadTreeNodeData<T>); virtual;
      /// <summary> Returns recursivly all intersection items. </summary>
      procedure GetIntersections(const Intersector : RCircle; var Intersections : TList < TLooseQuadTreeNodeData < T >> ); virtual;
      /// <summary> Opens up a new node. Subrect must be square. </summary>
      constructor Create(SubRect : RRectFloat; MinWidth : single; Parent : TLooseQuadTreeNode<T>);
      destructor Destroy; override;
  end;

  /// <summary> A loose quadtree, very efficient for many dynamic object, because adding, removing and updating
  /// is cheap. But queries costs a little more effort. Has no problems like the nodehotspots in standard quadtrees. </summary>
  TLooseQuadTree<T> = class
    protected
      FRoot : TLooseQuadTreeNode<T>;
    public
      /// <summary> Span a loose quadtree over the world. Generate every node empty up to minwidth. </summary>
      constructor Create(WorldRect : RRectFloat; MinWidth : single);
      /// <summary> Adds an item to the tree. Nil will be ignored. If node was previously added, it will be updated. </summary>
      procedure AddItem(Item : TLooseQuadTreeNodeData<T>);
      /// <summary> Removes an item from the tree. Nil will be ignored. </summary>
      procedure RemoveItem(Item : TLooseQuadTreeNodeData<T>);
      /// <summary> Updates an item in the tree. </summary>
      procedure UpdateItem(Item : TLooseQuadTreeNodeData<T>);
      /// <summary> Return all items, which intersect the intersector. </summary>
      function GetIntersections(Intersector : RCircle) : TList<TLooseQuadTreeNodeData<T>>; overload;
      /// <summary> Skadoosh. </summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ TLooseQuadTreeNodeData<T> }

constructor TLooseQuadTreeNodeData<T>.Create(Boundaries : RCircle; Data : T);
begin
  Self.Boundaries := Boundaries;
  Self.Data := Data;
end;

destructor TLooseQuadTreeNodeData<T>.Destroy;
begin
  Remove;
  inherited;
end;

procedure TLooseQuadTreeNodeData<T>.Remove;
begin
  if assigned(FOwningTree) then FOwningTree.RemoveItem(Self);
end;

procedure TLooseQuadTreeNodeData<T>.UpdateInTree;
begin
  if assigned(FOwningTree) then FOwningTree.UpdateItem(Self);
end;

{ TLooseQuadTree<T> }

procedure TLooseQuadTree<T>.AddItem(Item : TLooseQuadTreeNodeData<T>);
begin
  ASSERT(not assigned(Item.FOwner));
  if assigned(Item) then
  begin
    Item.FOwningTree := Self;
    ASSERT(FRoot.FRealRect.ContainsPoint(Item.Boundaries.Center), 'Quadtree root node to small to add this element. Increase initial size!');
    FRoot.AddItemRecursive(Item);
  end;
end;

constructor TLooseQuadTree<T>.Create(WorldRect : RRectFloat; MinWidth : single);
begin
  if not WorldRect.IsSquare then
  begin
    WorldRect.Width := max(WorldRect.Width, WorldRect.Height);
    WorldRect.Height := max(WorldRect.Width, WorldRect.Height);
  end;
  FRoot := TLooseQuadTreeNode<T>.Create(WorldRect, MinWidth, nil);
end;

destructor TLooseQuadTree<T>.Destroy;
begin
  FRoot.Free;
  inherited;
end;

function TLooseQuadTree<T>.GetIntersections(Intersector : RCircle) : TList<TLooseQuadTreeNodeData<T>>;
begin
  Result := TList < TLooseQuadTreeNodeData < T >>.Create;
  FRoot.GetIntersections(Intersector, Result);
end;

procedure TLooseQuadTree<T>.RemoveItem(Item : TLooseQuadTreeNodeData<T>);
begin
  ASSERT(assigned(Item.FOwner));
  if assigned(Item) and assigned(Item.FOwner) then Item.FOwner.RemoveItemRecursive(Item);
end;

procedure TLooseQuadTree<T>.UpdateItem(Item : TLooseQuadTreeNodeData<T>);
begin
  RemoveItem(Item);
  AddItem(Item);
end;

{ TLooseQuadTreeNode<T> }

constructor TLooseQuadTreeNode<T>.Create(SubRect : RRectFloat; MinWidth : single; Parent : TLooseQuadTreeNode<T>);
begin
  ASSERT(SubRect.IsSquare, 'Loose Quadtrees need a square shaped area!');
  FParent := Parent;
  FRealRect := SubRect;
  FLooseRect := SubRect.Inflate(SubRect.Height * LOOSEMODIFIER / 4, SubRect.Width * LOOSEMODIFIER / 4, SubRect.Height * LOOSEMODIFIER / 4, SubRect.Width * LOOSEMODIFIER / 4);
  FItems := TList < TLooseQuadTreeNodeData < T >>.Create;
  FBorderSizeHalf := SubRect.Width * (LOOSEMODIFIER - 1) / 2;
  FMinWidth := MinWidth;
  if MinWidth < FRealRect.Width then Split;
end;

destructor TLooseQuadTreeNode<T>.Destroy;
var
  i : integer;
begin
  for i := 0 to FItems.Count - 1 do
  begin
    FItems[i].FOwner := nil;
    FItems[i].FOwningTree := nil;
  end;
  FItems.Free;
  for i := 0 to CHILDCOUNT - 1 do FChildren[i].Free;
  inherited;
end;

procedure TLooseQuadTreeNode<T>.AddItem(Item : TLooseQuadTreeNodeData<T>);
begin
  ASSERT(assigned(Item), 'Item isn''t assigned!');
  Item.FOwner := Self;
  FItems.Add(Item);
  FHasItems := true;
end;

procedure TLooseQuadTreeNode<T>.AddItemRecursive(Item : TLooseQuadTreeNodeData<T>);
var
  i : integer;
begin
  if (Item.Boundaries.radius >= FBorderSizeHalf) or not HasChildren then AddItem(Item)
  else
    for i := 0 to CHILDCOUNT - 1 do
      if FChildren[i].FRealRect.ContainsPoint(Item.Boundaries.Center) then
      begin
        FChildren[i].AddItemRecursive(Item);
        break;
      end;
  FHasItems := true;
end;

procedure TLooseQuadTreeNode<T>.GetIntersections(const Intersector : RCircle; var Intersections : TList < TLooseQuadTreeNodeData < T >> );
var
  i : integer;
begin
  if not Intersector.IntersectRect(FLooseRect) then
      exit;
  for i := 0 to FItems.Count - 1 do
    if Intersector.IntersectCircle(FItems[i].Boundaries) then Intersections.Add(FItems[i]);
  if HasChildren then
    for i := 0 to CHILDCOUNT - 1 do FChildren[i].GetIntersections(Intersector, Intersections);
end;

procedure TLooseQuadTreeNode<T>.RemoveItem(Item : TLooseQuadTreeNodeData<T>);
var
  pos : integer;
begin
  pos := FItems.IndexOf(Item);
  if pos >= 0 then
  begin
    FItems[pos] := FItems[FItems.Count - 1];
    FItems.Delete(FItems.Count - 1);
    Item.FOwner := nil;
    Item.FOwningTree := nil;
    UpdateEmptyness;
  end;
end;

procedure TLooseQuadTreeNode<T>.RemoveItemRecursive(Item : TLooseQuadTreeNodeData<T>);
var
  i : integer;
begin
  if not assigned(Item) then exit;
  if (Item.FOwner = Self) then RemoveItem(Item);
  if assigned(FParent) then FParent.RemoveItemRecursive(Item);
  UpdateEmptyness;
end;

procedure TLooseQuadTreeNode<T>.Split;
begin
  FHasChildren := true;
  FChildren[0] := TLooseQuadTreeNode<T>.Create(RRectFloat.CreateWidthHeight(FRealRect.Left, FRealRect.Top, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, Self);
  FChildren[1] := TLooseQuadTreeNode<T>.Create(RRectFloat.CreateWidthHeight(FRealRect.Left + FRealRect.Width / 2, FRealRect.Top, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, Self);
  FChildren[2] := TLooseQuadTreeNode<T>.Create(RRectFloat.CreateWidthHeight(FRealRect.Left, FRealRect.Top + FRealRect.Height / 2, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, Self);
  FChildren[3] := TLooseQuadTreeNode<T>.Create(RRectFloat.CreateWidthHeight(FRealRect.Left + FRealRect.Width / 2, FRealRect.Top + FRealRect.Height / 2, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, Self);
end;

procedure TLooseQuadTreeNode<T>.UpdateEmptyness;
begin
  FHasItems := (FItems.Count > 0) or (HasChildren and (FChildren[0].HasItems or FChildren[1].HasItems or FChildren[2].HasItems or FChildren[3].HasItems));
end;

end.
