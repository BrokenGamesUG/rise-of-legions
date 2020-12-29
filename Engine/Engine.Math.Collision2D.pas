unit Engine.Math.Collision2D;

interface

uses
  Generics.Collections,
  Math,
  Types,
  Engine.Helferlein,
  Engine.Math,
  SysUtils;

const

  COLLISIONEPSILON = 1E-4;
  MAXDISTANCE      = 1E5;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  EnumRectSide = (rsLeft, rsTop, rsRight, rsBottom);
  SetRectSide = set of EnumRectSide;

  PRect = ^RRect;

  RRect = record
    private
      function GetWidth : integer;
      function GetHeight : integer;
      procedure SetWidth(const Value : integer);
      procedure SetHeight(const Value : integer);
      function GetCenter : RIntVector2;
      function GetSize : RIntVector2;
      function GetBottomCenter : RIntVector2;
      function GetLeftCenter : RIntVector2;
      function GetRightCenter : RIntVector2;
      function GetTopCenter : RIntVector2;
      function GetLeftBottom : RIntVector2;
      function GetRightTop : RIntVector2;
      function GetAnchorPoints(index : integer) : RIntVector2;
      function GetDim(index : integer) : integer;
      procedure SetDim(index : integer; const Value : integer);
      function GetPos(index : integer) : integer;
      procedure SetPos(index : integer; const Value : integer);
      procedure SetX(const Value : integer);
      procedure SetY(const Value : integer);
      function GetX : integer;
      function GetY : integer;
      procedure SetSize(const Value : RIntVector2);
    public
      constructor Create(const Left, Top, Right, Bottom : integer); overload;
      constructor Create(const LeftTop, RightBottom : RIntVector2); overload;
      constructor CreateWidthHeight(const Left, Top, Width, Height : integer); overload;
      constructor CreateWidthHeight(const LeftTop, WidthHeight : RIntVector2); overload;
      constructor CreatePositionSize(const Position, Size : RIntVector2); overload;
      property AnchorPoints[index : integer] : RIntVector2 read GetAnchorPoints;
      property Width : integer read GetWidth write SetWidth;
      property Height : integer read GetHeight write SetHeight;
      property RightTop : RIntVector2 read GetRightTop;
      property LeftBottom : RIntVector2 read GetLeftBottom;
      property Center : RIntVector2 read GetCenter;
      property TopCenter : RIntVector2 read GetTopCenter;
      property RightCenter : RIntVector2 read GetRightCenter;
      property BottomCenter : RIntVector2 read GetBottomCenter;
      property LeftCenter : RIntVector2 read GetLeftCenter;
      property Size : RIntVector2 read GetSize write SetSize;
      property Dim[index : integer] : integer read GetDim write SetDim;
      property Pos[index : integer] : integer read GetPos write SetPos;
      property X : integer read GetX write SetX;
      property Y : integer read GetY write SetY;
      /// <summary> Returns true if the rectangle has a width and height > 0. </summary>
      function HasSize : boolean;
      function ContainsPoint(X, Y : integer) : boolean; overload;
      function ContainsPoint(Point : TPoint) : boolean; overload;
      function ContainsPoint(const Point : RIntVector2) : boolean; overload;
      /// <summary> Clips the point to the rect. If its located out of bounds its clamped to the border. </summary>
      function ClipPoint(const Point : RIntVector2) : RIntVector2;
      function Translate(X, Y : integer) : RRect; overload;
      function Translate(const XY : RIntVector2) : RRect; overload;
      /// <summary> Moves the edges away from the middle. </summary>
      function Inflate(Top, Right, Bottom, Left : integer) : RRect; overload;
      function Inflate(const TopRightBottomLeft : RIntVector4) : RRect; overload;
      /// <summary> Returns true if this and b are intersecting or touching. </summary>
      function Intersects(const b : RRect) : boolean;
      /// <summary> Returns the intersection rect between this both rects. If rectangles aren't intersecting
      /// returns rectangle with negative dimensions. Check HasSize for that case. </summary>
      function Intersection(const b : RRect) : RRect;
      class operator implicit(const a : RRect) : TRect;
      class operator implicit(a : TRect) : RRect;
      class operator equal(const a, b : RRect) : boolean;
      class operator notequal(const a, b : RRect) : boolean;
      case byte of
        0 : (Left, Top, Right, Bottom : integer);
        2 : (LeftTop, RightBottom : RIntVector2);
        3 : (LeftTopRightBottom : RIntVector4);
        4 : (Elements : array [0 .. 3] of integer);
        5 : (Sides : array [EnumRectSide] of integer);
  end;

  PRectFloat = ^RRectFloat;

  RRectFloat = record
    private
      function GetLeftBottom : RVector2;
      function GetRightTop : RVector2;
      procedure SetLeftBottom(const Value : RVector2);
      procedure SetRightTop(const Value : RVector2);
      function GetHeight : Single;
      function GetWidth : Single;
      procedure SetPropHeight(const Value : Single);
      procedure SetPropWidth(const Value : Single);
      function GetCenter : RVector2;
      function GetDim(index : integer) : Single;
      procedure SetPropDim(index : integer; const Value : Single);
      function GetPos(index : integer) : Single;
      procedure SetPos(index : integer; const Value : Single);
      function GetSize : RVector2;
      procedure SetPropSize(const Value : RVector2);
      function GetAnchorPoints(index : integer) : RVector2;
      function GetPosition : RVector2;
      procedure SetPosition(const Value : RVector2);
      function GetX : Single;
      function GetY : Single;
      procedure SetX(const Value : Single);
      procedure SetY(const Value : Single);
      procedure SetCenter(const Value : RVector2);
      function GetLeftWidth : RVector2;
      function GetTopHeight : RVector2;
      procedure SetLeftWidth(const Value : RVector2);
      procedure SetTopHeight(const Value : RVector2);
    public
      property AnchorPoints[index : integer] : RVector2 read GetAnchorPoints;
      constructor Create(const Left, Top, Right, Bottom : Single); overload;
      constructor Create(const LeftTop, RightBottom : RVector2); overload;
      constructor CreateWidthHeight(Left, Top, Width, Height : Single); overload;
      constructor CreateWidthHeight(const LeftTop, WidthHeight : RVector2); overload;
      constructor CreatePositionSize(const Position, Size : RVector2); overload;
      function Trunc : RRect;
      function Round : RRect;
      /// <summary> Expand rect to contain all semi-contained integers. </summary>
      function RoundExpand : RRect;
      function Translate(X, Y : Single) : RRectFloat; overload;
      function Translate(const XY : RVector2) : RRectFloat; overload;
      function Inflate(Top, Right, Bottom, Left : Single) : RRectFloat; overload;
      function Inflate(TopBottom, LeftRight : Single) : RRectFloat; overload;
      function Inflate(const TopRightBottomLeft : RVector4) : RRectFloat; overload;
      function Inflate(TopRightBottomLeft : Single) : RRectFloat; overload;
      function InflateByPercentage(const WidthHeightPercentage : Single) : RRectFloat;
      /// <summary> If point lies within rect it returns for each axis the percentage of size as a value 0..1. </summary>
      function LocalCoordinate(Point : RVector2) : RVector2;
      function LocalRect(const OtherRect : RRectFloat) : RRectFloat;
      function ContainsPoint(X, Y : Single) : boolean; overload;
      function ContainsPoint(const Point : RVector2) : boolean; overload;
      /// <summary> Ensures that the point lies in the rectangle. </summary>
      function ClampPoint(const Point : RVector2) : RVector2;
      /// <summary> Extends this rect, so it contains the other rect. Returns the new rect. </summary>
      function Extend(const OtherRect : RRectFloat) : RRectFloat;
      /// <summary> Returns the ContainedRect with relative positions to self, e.g. same rect would return (0,0,1,1)
      /// If width or height is 0 of self, returns for that dimension a [0,1]-range. </summary>
      function RectToRelative(ContainedRect : RRectFloat) : RRectFloat;
      function IsSquare : boolean;
      function GetRandom : RVector2;
      function AspectRatio : Single;
      /// <summary> Returns true if the rectangle has a width and height > 0. </summary>
      function HasSize : boolean;
      /// <summary> Returns true if this and b are intersecting or touching. </summary>
      function Intersects(const b : RRectFloat) : boolean; overload;
      function Intersects(const b : RRect) : boolean; overload;
      /// <summary> Returns the intersection rect between this both rects. If rectangles aren't intersecting
      /// returns rectangle with negative dimensions. Check HasSize for that case. </summary>
      function Intersection(const b : RRectFloat) : RRectFloat;
      function SetDim(const NewDim : Single; const Dim : byte) : RRectFloat;
      function SetWidth(const NewWidth : Single) : RRectFloat;
      function SetHeight(const NewHeight : Single) : RRectFloat;
      function SetSize(const NewSize : RVector2) : RRectFloat;
      property Center : RVector2 read GetCenter write SetCenter;
      property Width : Single read GetWidth write SetPropWidth;
      property Height : Single read GetHeight write SetPropHeight;
      /// <summary> The position of the rectangle (LeftTop-Anchor) </summary>
      property Position : RVector2 read GetPosition write SetPosition;
      property Size : RVector2 read GetSize write SetPropSize;
      property Dim[index : integer] : Single read GetDim write SetPropDim;
      property Pos[index : integer] : Single read GetPos write SetPos;
      property X : Single read GetX write SetX;
      property Y : Single read GetY write SetY;
      /// <summary> Set the left top corner. ATTENTION: Resizes the quad, for moving use position. </summary>
      property RightTop : RVector2 read GetRightTop write SetRightTop;
      property LeftBottom : RVector2 read GetLeftBottom write SetLeftBottom;
      property LeftWidth : RVector2 read GetLeftWidth write SetLeftWidth;
      property TopHeight : RVector2 read GetTopHeight write SetTopHeight;
      class operator divide(const a : RRectFloat; b : Single) : RRectFloat;
      class operator divide(const a : RRectFloat; const b : RVector2) : RRectFloat;
      class operator implicit(const a : TRectF) : RRectFloat;
      class operator multiply(const a : RRectFloat; const b : RVector2) : RRectFloat;
      case byte of
        0 : (Left, Top, Right, Bottom : Single);
        2 : (LeftTop, RightBottom : RVector2);
        3 : (LeftTopRightBottom : RVector4);
        4 : (Elements : array [0 .. 3] of Single);
        5 : (Sides : array [EnumRectSide] of Single);
  end;

  PRay2D = ^RRay2D;

  /// <summary> A infinite straight line in 2D space. </summary>
  RRay2D = record
    strict private
      FDirection : RVector2;
      procedure SetDirection(const Value : RVector2);
    public
      Origin : RVector2;
      property Direction : RVector2 read FDirection write SetDirection;
      constructor Create(const Origin, Direction : RVector2);
      /// <summary> Returns the shortest distance of a point to the ray. </summary>
      function DistanceToPoint(const Point : RVector2) : Single;
      /// <summary> Returns the closest point on the ray to a point. </summary>
      function NearestPointToPoint(const Point : RVector2) : RVector2;
      /// <summary> Returns the intersection point. </summary>
      function IntersectionWithRay(const otherRay : RRay2D) : RVector2;
  end;

  PLine2D = ^RLine2D;

  /// <summary> A finite line segment in 2D space. </summary>
  RLine2D = record
    strict private
      function GetEndpoint : RVector2;
      procedure SetEndpoint(const Value : RVector2);
      function GetLength : Single;
      procedure SetLength(const Value : Single);
    private
      function GetCenter : RVector2;
    public
      Origin : RVector2;
      /// <summary> Length of direction determines the length of the line segment. </summary>
      Direction : RVector2;
      property Endpoint : RVector2 read GetEndpoint write SetEndpoint;
      property Center : RVector2 read GetCenter;
      property Length : Single read GetLength write SetLength;
      constructor CreateFromPoints(const Startpoint, Endpoint : RVector2);
      constructor Create(const Origin, Direction : RVector2);
      function IsEmpty : boolean;
      /// <summary> Returns whether the given point lies at the left of the line looked from above an in direction. </summary>
      function IsLeft(const Point : RVector2) : boolean;
      /// <summary> Returns the point on the line which lies as Origin + s * Direction. </summary>
      function Lerp(s : Single) : RVector2;
      /// <summary> Returns the shortest distance of a point to the line. </summary>
      function DistanceToPoint(const Point : RVector2) : Single;
      /// <summary> Returns whether the orthogonal projection of point is on this line. </summary>
      function IsOrthogonalProjectionOnLine(const Point : RVector2) : boolean;
      /// <summary> Returns the closest point on the line to a point. </summary>
      function NearestPointOnLine(const Point : RVector2) : RVector2;
      /// <summary> Returns whether the other line is intersecting with this line. </summary>
      function IntersectWithLine(const AnotherLine : RLine2D) : boolean;
      /// <summary> Returns the coefficients of the directions, where the intersection point lies. Not intersecting except 0<=t|u<=1. </summary>
      procedure IntersectionWithLineRaw(const AnotherLine : RLine2D; out u, t : Single);
      /// <summary> Returns the intersecting point of the two lines. If they aren't intersection returns RVector2.Empty </summary>
      function IntersectionWithLine(const AnotherLine : RLine2D) : RVector2;
      /// <summary> Returns the infinite ray which contains the line. </summary>
      function ToRay : RRay2D;
      /// <summary> Inverts the direction </summary>
      function Reverse : RLine2D;
      /// <summary> Returns an invalid RLine2D for equality-checks. </summary>
      class function EMPTY : RLine2D; static;
  end;

  PCircle = ^RCircle;

  /// <summary> A 2D circle. </summary>
  RCircle = record
    public
      Center : RVector2;
      Radius : Single;
      constructor Create(const Center : RVector2; Radius : Single);
      function ContainsPoint(const Point : RVector2) : boolean;
      /// <summary> Ensures that point lies in the circle. If its outside its clamped to the border. </summary>
      function ClampPoint(const Point : RVector2) : RVector2;
      /// <summary> Returns whether the other circle is intersecting this circle. </summary>
      function IntersectCircle(const Circle : RCircle) : boolean;
      /// <summary> Return the distance of self <-> Circle - radius. If Collide value <= 0 </summary>
      function DistanceToCircle(const Circle : RCircle) : Single;
      /// <summary> Return distance to point using radius </summary>
      function DistanceToPoint(const Point : RVector2) : Single;
      /// <summary> Returns whether the ray is intersecting this circle. </summary>
      function IntersectRay(const Ray : RRay2D) : boolean;
      /// <summary> Returns the intersection line. If ray and circle don't intersect return all Empty. </summary>
      function IntersectionRay(const Ray : RRay2D) : RLine2D;
      /// <summary> Returns whether the line is intersecting this circle. </summary>
      function IntersectLine(const Line : RLine2D) : boolean;
      /// <summary> Returns whether the rect is intersecting this circle. </summary>
      function IntersectRect(const Rect : RRectFloat) : boolean;
  end;

  /// <summary> An arbitary oriented rectangle on the 2D plane. </summary>
  ROrientedRect = record
    private
      FPosition, FFront, FSize : RVector2;
      procedure SetFront(const Value : RVector2);
      function GetLeft : RVector2;
      function GetHeight : Single;
      function GetWidth : Single;
      procedure SetHeight(const Value : Single);
      procedure SetWidth(const Value : Single);
      function PointToAxisSpace(const Point : RVector2) : RVector2;
    public
      function TopLeft : RVector2;
      function TopRight : RVector2;
      function BottomLeft : RVector2;
      function BottomRight : RVector2;
      /// <summary> The center of the rectangle. </summary>
      property Position : RVector2 read FPosition write FPosition;
      /// <summary> The normalized front of this rectangle. </summary>
      property Front : RVector2 read FFront write SetFront;
      /// <summary> The normalized left of this rectangle. Implictly derived from front. </summary>
      property Left : RVector2 read GetLeft;
      /// <summary> The (width, height) of the rectangle in (left, front) direction. </summary>
      property Size : RVector2 read FSize write FSize;
      /// <summary> Look at "Size". </summary>
      property Width : Single read GetWidth write SetWidth;
      /// <summary> Look at "Size". </summary>
      property Height : Single read GetHeight write SetHeight;
      constructor Create(const Position, Front, Size : RVector2); overload;
      /// <summary> Returns whether the point is in the polygon or is lying on an edge. </summary>
      function ContainsPoint(const b : RVector2) : boolean;
      /// <summary> Returns whether the rectangle is intersecting with the circle. </summary>
      function IntersectsCircle(const b : RCircle) : boolean;
      /// <summary> http://www.gamedev.net/page/resources/_/technical/game-programming/2d-rotated-rectangle-collision-r2604 </summary>
      /// function IntersectOrientedRect(const b : ROrientedRect):boolean;
      /// <summary> Returns the tightest circle wrapping this rect. </summary>
      function ToWrappingCircle() : RCircle;
  end;

  /// <summary> A 2D polygon or if not closed a polyline. </summary>
  TPolygon = class
    private
      function GetEdge(index : integer) : RLine2D;
    protected
      FNodes : TList<RVector2>;
      FClosed : boolean;
    public
      /// <summary> Closes the polyline to a polygon. </summary>
      property Closed : boolean read FClosed write FClosed;
      property Nodes : TList<RVector2> read FNodes;
      property Edge[index : integer] : RLine2D read GetEdge;
      function EdgeCount : integer;
      constructor Create(); overload;
      constructor Create(Nodes : array of RVector2); overload;
      constructor Create(Nodes : TList<RVector2>); overload;
      procedure AddNode(const Node : RVector2);
      procedure DeleteNode(index : integer);
      procedure InsertNode(index : integer; const Node : RVector2);
      /// <summary> Executes the corner cutting algorithm to smooth the polygon n times. </summary>
      procedure CornerCutting(Times : integer);
      /// <summary> Computes the average of all nodes. </summary>
      function Center : RVector2;
      /// <summary> Returns whether the polygon seems to be clockwise Set up (uses the center as anchor). </summary>
      function IsClockwise : boolean;
      /// <summary> Reverses the polygon order. </summary>
      procedure Reverse;
      /// <summary> Returns the absolute length of this polygon. </summary>
      function Length : Single; overload;
      /// <summary> Returns the absolute length of this polygon from node 0 to Index. </summary>
      function Length(index : integer) : Single; overload;
      /// <summary> Returns the closest point on the border of the poly to a point. </summary>
      function NearestPointAtBorder(const Point : RVector2) : RVector2;
      /// <summary> Returns the closest point outside of the poly to a point. </summary>
      function NearestPointOutside(const Point : RVector2) : RVector2;
      /// <summary> Returns the closest node of the poly to a point. </summary>
      function NearestNodeToPoint(const Point : RVector2) : RVector2;
      /// <summary> Returns the inner angle of node. If Polygon isn't closed, returns NaN. </summary>
      function GetInnerAngle(index : integer) : Single;
      /// <summary> Returns whether a node is convex (inner angle > 180°). If Polygon isn't closed, returns false. </summary>
      function IsNodeConvex(index : integer) : boolean;
      /// <summary> Returns whether the polygon is convex. (Every point of the poly can see all other points) </summary>
      function IsConvex : boolean;
      /// <summary> Returns whether a point lies within the polygon. </summary>
      function IsPointInPolygon(const Point : RVector2) : boolean;
      /// <summary> Returns whether a line intersects with the border of the polygon. </summary>
      function IntersectBorderWithLine(const Line : RLine2D) : boolean;
      /// <summary> Clamp a point to the polygon. If it's outside it will be clamped to the nearest border.
      /// If poly isn't closed it's clamped onto the polyline. </summary>
      function EnsurePointInPoly(const Point : RVector2) : RVector2;
      /// <summary> Returns a deep copy of this polygon. </summary>
      function Clone : TPolygon;
      destructor Destroy; override;
  end;

  /// <summary> A bunch of polygons which are added and subtracted for describing an area.
  /// At the moment it's very limited: For pathfinding, all polygons are expected to have
  /// no intersection of their border. </summary>
  TMultipolygon = class
    public
      type
      RMultipolygon = record
        Subtractive : boolean;
        Polygon : TPolygon;
        constructor Create(Poly : TPolygon; Subtract : boolean);
      end;
    protected
      FPolygons : TList<RMultipolygon>;
    public
      property Polygons : TList<RMultipolygon> read FPolygons;
      constructor Create;
      procedure AddPolygon(Poly : TPolygon; Subtractive : boolean);
      procedure DeletePolygon(index : integer);
      /// <summary> Returns whether a point lies within the described area. For overlapping polygons
      /// the number of additive and subtractive polygons are compared for this point. </summary>
      function IsPointInMultiPolygon(const Point : RVector2) : boolean;
      /// <summary> Returns whether a line lies within the described area. For overlapping polygons
      /// the number of additive and subtractive polygons are compared for this point. </summary>
      function IsLineInMultiPolygon(const Line : RLine2D) : boolean;
      /// <summary> Clamp a point to the multipolygon. If it's outside it will be clamped to the nearest border.</summary>
      function EnsurePointInMultiPoly(const Point : RVector2) : RVector2;
      function NextPointOnBorder(const Point : RVector2) : RVector2;
      destructor Destroy; override;

  end;

  RRectHelper = record helper for RRect
    function ToRectFloat : RRectFloat;
  end;

  RRectFloatHelper = record helper for RRectFloat
    const
      ZERO : RRectFloat    = ();
      DEFAULT : RRectFloat = (Left : 0; Top : 0; Right : 1; Bottom : 1);
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ RRect }

constructor RRect.Create(const Left, Top, Right, Bottom : integer);
begin
  self.Left := Left;
  self.Top := Top;
  self.Right := Right;
  self.Bottom := Bottom;
end;

constructor RRect.Create(const LeftTop, RightBottom : RIntVector2);
begin
  self.Left := LeftTop.X;
  self.Top := LeftTop.Y;
  self.Right := RightBottom.X;
  self.Bottom := RightBottom.Y;
end;

constructor RRect.CreatePositionSize(const Position, Size : RIntVector2);
begin
  self.Left := Position.X - (Size.X div 2);
  self.Top := Position.Y - (Size.Y div 2);
  self.Right := self.Left + Size.X;
  self.Bottom := self.Top + Size.Y;
end;

constructor RRect.CreateWidthHeight(const LeftTop, WidthHeight : RIntVector2);
begin
  Left := LeftTop.X;
  Top := LeftTop.Y;
  Right := WidthHeight.X + Left;
  Bottom := WidthHeight.Y + Top;
end;

constructor RRect.CreateWidthHeight(const Left, Top, Width, Height : integer);
begin
  self.Left := Left;
  self.Top := Top;
  self.Width := Width;
  self.Height := Height;
end;

function RRect.ClipPoint(const Point : RIntVector2) : RIntVector2;
begin
  Result.X := HMath.Clamp(Point.X, Left, Right);
  Result.Y := HMath.Clamp(Point.Y, Top, Bottom);
end;

function RRect.GetWidth : integer;
begin
  Result := Right - Left;
end;

function RRect.GetX : integer;
begin
  Result := Left;
end;

function RRect.GetY : integer;
begin
  Result := Top;
end;

function RRect.HasSize : boolean;
begin
  Result := (Width > 0) and (Height > 0);
end;

function RRect.GetAnchorPoints(index : integer) : RIntVector2;
begin
  case index of
    0 : Result := LeftTop;
    1 : Result := TopCenter;
    2 : Result := RightTop;
    3 : Result := RightCenter;
    4 : Result := RightBottom;
    5 : Result := BottomCenter;
    6 : Result := LeftBottom;
    7 : Result := LeftCenter;
  else
    raise EInvalidArgument.CreateFmt('RRect.GetAnchorPoints: Index have to be in range [0,7]! (was %d', [index]);
  end;
end;

function RRect.GetBottomCenter : RIntVector2;
begin
  Result.X := (Right + Left) div 2;
  Result.Y := Bottom;
end;

function RRect.GetCenter : RIntVector2;
begin
  Result.X := (Right + Left) div 2;
  Result.Y := (Top + Bottom) div 2;
end;

function RRect.GetDim(index : integer) : integer;
begin
  if index = 0 then Result := Width
  else Result := Height;
end;

function RRect.GetHeight : integer;
begin
  Result := Bottom - Top;
end;

function RRect.GetLeftBottom : RIntVector2;
begin
  Result.X := Left;
  Result.Y := Bottom;
end;

function RRect.GetLeftCenter : RIntVector2;
begin
  Result.X := Left;
  Result.Y := (Top + Bottom) div 2;
end;

function RRect.GetPos(index : integer) : integer;
begin
  if index = 0 then Result := X
  else Result := Y;
end;

function RRect.GetRightCenter : RIntVector2;
begin
  Result.X := Right;
  Result.Y := (Top + Bottom) div 2;
end;

function RRect.GetRightTop : RIntVector2;
begin
  Result.X := Right;
  Result.Y := Top;
end;

procedure RRect.SetX(const Value : integer);
begin
  Right := Value + Width;
  Left := Value;
end;

procedure RRect.SetY(const Value : integer);
begin
  Bottom := Value + Height;
  Top := Value;
end;

function RRect.GetSize : RIntVector2;
begin
  Result.X := Width;
  Result.Y := Height;
end;

function RRect.GetTopCenter : RIntVector2;
begin
  Result.X := (Right + Left) div 2;
  Result.Y := Top;
end;

class operator RRect.implicit(const a : RRect) : TRect;
begin
  Result := Rect(a.Left, a.Top, a.Right, a.Bottom);
end;

class operator RRect.implicit(a : TRect) : RRect;
begin
  Result := RRect.Create(a.Left, a.Top, a.Right, a.Bottom);
end;

function RRect.Inflate(Top, Right, Bottom, Left : integer) : RRect;
begin
  Result.Left := self.Left - Left;
  Result.Right := self.Right + Right;
  Result.Top := self.Top - Top;
  Result.Bottom := self.Bottom + Bottom;
end;

function RRect.Inflate(const TopRightBottomLeft : RIntVector4) : RRect;
begin
  Result := Inflate(TopRightBottomLeft.X, TopRightBottomLeft.Y, TopRightBottomLeft.Z, TopRightBottomLeft.W);
end;

function RRect.Intersection(const b : RRect) : RRect;
begin
  Result.Left := max(self.Left, b.Left);
  Result.Top := max(self.Top, b.Top);
  Result.Right := min(self.Right, b.Right);
  Result.Bottom := min(self.Bottom, b.Bottom);
end;

function RRect.Intersects(const b : RRect) : boolean;
begin
  Result := not((b.Left >= self.Right) or
    (b.Right <= self.Left) or
    (b.Top >= self.Bottom) or
    (b.Bottom <= self.Top));
end;

class operator RRect.notequal(const a, b : RRect) : boolean;
begin
  Result := (a.Left <> b.Left) or
    (a.Right <> b.Right) or
    (a.Top <> b.Top) or
    (a.Bottom <> b.Bottom);
end;

function RRect.ContainsPoint(const Point : RIntVector2) : boolean;
begin
  Result := ContainsPoint(Point.X, Point.Y);
end;

class operator RRect.equal(const a, b : RRect) : boolean;
begin
  Result := (a.Left = b.Left) and
    (a.Right = b.Right) and
    (a.Top = b.Top) and
    (a.Bottom = b.Bottom);
end;

function RRect.ContainsPoint(X, Y : integer) : boolean;
begin
  Result := (Left <= X) and (X <= Right) and (Top <= Y) and (Y <= Bottom);
end;

function RRect.ContainsPoint(Point : TPoint) : boolean;
begin
  Result := ContainsPoint(Point.X, Point.Y);
end;

procedure RRect.SetWidth(const Value : integer);
begin
  Right := Left + Value;
  if Left > Right then HGeneric.Swap<integer>(Left, Right);
end;

procedure RRect.SetDim(index : integer; const Value : integer);
begin
  if index = 0 then Width := Value
  else Height := Value;
end;

procedure RRect.SetHeight(const Value : integer);
begin
  Bottom := Top + Value;
  if Top > Bottom then HGeneric.Swap<integer>(Top, Bottom);
end;

procedure RRect.SetPos(index : integer; const Value : integer);
begin
  if index = 0 then X := Value
  else Y := Value;
end;

procedure RRect.SetSize(const Value : RIntVector2);
begin
  Width := Value.X;
  Height := Value.Y;
end;

function RRect.Translate(X, Y : integer) : RRect;
begin
  Result.Left := self.Left + X;
  Result.Right := self.Right + X;
  Result.Top := self.Top + Y;
  Result.Bottom := self.Bottom + Y;
end;

function RRect.Translate(const XY : RIntVector2) : RRect;
begin
  Result := Translate(XY.X, XY.Y);
end;

{ RRectFloat }

function RRectFloat.ContainsPoint(X, Y : Single) : boolean;
begin
  Result := (Left <= X) and (X <= Right) and (Top <= Y) and (Y <= Bottom);
end;

function RRectFloat.AspectRatio : Single;
begin
  Result := Width / Height;
end;

function RRectFloat.ClampPoint(const Point : RVector2) : RVector2;
begin
  if Point.X < Left then Result.X := Left
  else if Point.X > Right then Result.X := Right
  else Result.X := Point.X;
  if Point.Y < Top then Result.Y := Top
  else if Point.Y > Bottom then Result.Y := Bottom
  else Result.Y := Point.Y;
end;

function RRectFloat.ContainsPoint(const Point : RVector2) : boolean;
begin
  Result := ContainsPoint(Point.X, Point.Y);
end;

constructor RRectFloat.Create(const Left, Top, Right, Bottom : Single);
begin
  self.Left := Left;
  self.Top := Top;
  self.Right := Right;
  self.Bottom := Bottom;
end;

constructor RRectFloat.Create(const LeftTop, RightBottom : RVector2);
begin
  self.Left := LeftTop.X;
  self.Top := LeftTop.Y;
  self.Right := RightBottom.X;
  self.Bottom := RightBottom.Y;
end;

constructor RRectFloat.CreatePositionSize(const Position, Size : RVector2);
begin
  self.Left := Position.X - (Size.X * 0.5);
  self.Top := Position.Y - (Size.Y * 0.5);
  self.Right := self.Left + Size.X;
  self.Bottom := self.Top + Size.Y;
end;

constructor RRectFloat.CreateWidthHeight(const LeftTop, WidthHeight : RVector2);
begin
  self.Left := LeftTop.X;
  self.Top := LeftTop.Y;
  self.Width := WidthHeight.X;
  self.Height := WidthHeight.Y;
end;

constructor RRectFloat.CreateWidthHeight(Left, Top, Width, Height : Single);
begin
  self.Left := Left;
  self.Top := Top;
  self.Width := Width;
  self.Height := Height;
end;

class operator RRectFloat.divide(const a : RRectFloat; const b : RVector2) : RRectFloat;
begin
  Result.LeftTop := a.LeftTop / b;
  Result.RightBottom := a.RightBottom / b;
end;

function RRectFloat.Extend(const OtherRect : RRectFloat) : RRectFloat;
begin
  Result.Left := min(self.Left, OtherRect.Left);
  Result.Top := min(self.Top, OtherRect.Top);
  Result.Right := max(self.Right, OtherRect.Right);
  Result.Bottom := max(self.Bottom, OtherRect.Bottom);
end;

class operator RRectFloat.divide(const a : RRectFloat; b : Single) : RRectFloat;
begin
  Result.LeftTop := a.LeftTop / b;
  Result.RightBottom := a.RightBottom / b;
end;

function RRectFloat.GetAnchorPoints(index : integer) : RVector2;
begin
  case index of
    0 : Result := LeftTop;
    1 : Result := RVector2.Create((Left + Right) / 2, Top);
    2 : Result := RightTop;
    3 : Result := RVector2.Create(Right, (Top + Bottom) / 2);
    4 : Result := RightBottom;
    5 : Result := RVector2.Create((Left + Right) / 2, Bottom);
    6 : Result := LeftBottom;
    7 : Result := RVector2.Create(Left, (Top + Bottom) / 2);
  else
    raise EInvalidArgument.CreateFmt('RRectFloat.GetAnchorPoints: Index have to be in range [0,7]! (was %d', [index]);
  end;
end;

function RRectFloat.GetCenter : RVector2;
begin
  Result.X := (Right + Left) / 2;
  Result.Y := (Top + Bottom) / 2;
end;

function RRectFloat.GetDim(index : integer) : Single;
begin
  if index = 0 then Result := Width
  else Result := Height;
end;

function RRectFloat.GetHeight : Single;
begin
  Result := Bottom - Top;
end;

function RRectFloat.GetLeftBottom : RVector2;
begin
  Result.X := Left;
  Result.Y := Bottom;
end;

function RRectFloat.GetLeftWidth : RVector2;
begin
  Result.X := Left;
  Result.Y := Width;
end;

function RRectFloat.GetPos(index : integer) : Single;
begin
  if index = 0 then Result := X
  else Result := Y;
end;

function RRectFloat.GetPosition : RVector2;
begin
  Result := LeftTop;
end;

function RRectFloat.GetRandom : RVector2;
var
  s : Single;
begin
  s := random;
  Result.X := s * Left + (1 - s) * Right;
  s := random;
  Result.Y := s * Top + (1 - s) * Bottom;
end;

function RRectFloat.Intersects(const b : RRectFloat) : boolean;
begin
  Result := not((b.Left >= self.Right) or
    (b.Right <= self.Left) or
    (b.Top >= self.Bottom) or
    (b.Bottom <= self.Top));
end;

function RRectFloat.Intersection(const b : RRectFloat) : RRectFloat;
begin
  Result.Left := max(self.Left, b.Left);
  Result.Top := max(self.Top, b.Top);
  Result.Right := min(self.Right, b.Right);
  Result.Bottom := min(self.Bottom, b.Bottom);
end;

function RRectFloat.Intersects(const b : RRect) : boolean;
begin
  Result := not((b.Left >= self.Right) or
    (b.Right <= self.Left) or
    (b.Top >= self.Bottom) or
    (b.Bottom <= self.Top));
end;

function RRectFloat.GetRightTop : RVector2;
begin
  Result.X := Right;
  Result.Y := Top;
end;

function RRectFloat.GetSize : RVector2;
begin
  Result.X := Width;
  Result.Y := Height;
end;

function RRectFloat.GetTopHeight : RVector2;
begin
  Result.X := Top;
  Result.Y := Height;
end;

function RRectFloat.GetWidth : Single;
begin
  Result := Right - Left;
end;

function RRectFloat.GetX : Single;
begin
  Result := Left;
end;

function RRectFloat.GetY : Single;
begin
  Result := Top;
end;

function RRectFloat.HasSize : boolean;
begin
  Result := (Width > 0) and (Height > 0);
end;

class operator RRectFloat.implicit(const a : TRectF) : RRectFloat;
begin
  Result.Left := a.Left;
  Result.Right := a.Right;
  Result.Top := a.Top;
  Result.Bottom := a.Bottom;
end;

function RRectFloat.Inflate(Top, Right, Bottom, Left : Single) : RRectFloat;
begin
  Result.Left := self.Left - Left;
  Result.Right := self.Right + Right;
  Result.Top := self.Top - Top;
  Result.Bottom := self.Bottom + Bottom;
end;

function RRectFloat.Inflate(const TopRightBottomLeft : RVector4) : RRectFloat;
begin
  Result := Inflate(TopRightBottomLeft.X, TopRightBottomLeft.Y, TopRightBottomLeft.Z, TopRightBottomLeft.W);
end;

function RRectFloat.Inflate(TopRightBottomLeft : Single) : RRectFloat;
begin
  Result := Inflate(TopRightBottomLeft, TopRightBottomLeft, TopRightBottomLeft, TopRightBottomLeft);
end;

function RRectFloat.Inflate(TopBottom, LeftRight : Single) : RRectFloat;
begin
  Result := Inflate(TopBottom, LeftRight, TopBottom, LeftRight);
end;

function RRectFloat.InflateByPercentage(const WidthHeightPercentage : Single) : RRectFloat;
var
  Center : RVector2;
begin
  Result := self;
  Center := Result.Center;
  Result.Size := WidthHeightPercentage * Result.Size;
  Result.Center := Center;
end;

function RRectFloat.IsSquare : boolean;
begin
  Result := abs(Height - Width) < EPSILON;
end;

function RRectFloat.LocalCoordinate(Point : RVector2) : RVector2;
begin
  Result.X := Right - Left;
  if Result.X > 0 then
      Result.X := (Point.X - Left) / Result.X;
  Result.Y := Bottom - Top;
  if Result.Y > 0 then
      Result.Y := (Point.Y - Top) / Result.Y;
end;

function RRectFloat.LocalRect(const OtherRect : RRectFloat) : RRectFloat;
begin
  Result.LeftTop := self.LocalCoordinate(OtherRect.LeftTop);
  Result.RightBottom := self.LocalCoordinate(OtherRect.RightBottom);
end;

class operator RRectFloat.multiply(const a : RRectFloat; const b : RVector2) : RRectFloat;
begin
  Result.LeftTop := a.LeftTop * b;
  Result.RightBottom := a.RightBottom * b;
end;

function RRectFloat.RectToRelative(ContainedRect : RRectFloat) : RRectFloat;
var
  Width, Height : Single;
begin
  Width := self.Width;
  Height := self.Height;
  if Width = 0 then
  begin
    Result.Left := 0;
    Result.Right := 1;
  end
  else
  begin
    Result.Left := (ContainedRect.Left - Left) / Width;
    Result.Right := (ContainedRect.Right - Left) / Width;
  end;
  if Height = 0 then
  begin
    Result.Top := 0;
    Result.Bottom := 1;
  end
  else
  begin
    Result.Top := (ContainedRect.Top - Top) / Height;
    Result.Bottom := (ContainedRect.Bottom - Top) / Height;
  end;
end;

function RRectFloat.Round : RRect;
begin
  Result := RRect.Create(System.Round(Left), System.Round(Top), System.Round(Right), System.Round(Bottom));
end;

function RRectFloat.RoundExpand : RRect;
begin
  Result.Left := Floor(Left);
  Result.Top := Floor(Top);
  Result.Right := Ceil(Right);
  Result.Bottom := Ceil(Bottom);
end;

procedure RRectFloat.SetPropDim(index : integer; const Value : Single);
begin
  if index = 0 then Width := Value
  else Height := Value;
end;

procedure RRectFloat.SetCenter(const Value : RVector2);
begin
  Position := Position + (Value - Center);
end;

function RRectFloat.SetDim(const NewDim : Single; const Dim : byte) : RRectFloat;
begin
  if Dim = 0 then Result := SetWidth(NewDim)
  else Result := SetHeight(NewDim);
end;

function RRectFloat.SetHeight(const NewHeight : Single) : RRectFloat;
begin
  Result.Left := self.Left;
  Result.Top := self.Top;
  Result.Right := self.Right;
  Result.Bottom := self.Top + NewHeight;
end;

procedure RRectFloat.SetPropHeight(const Value : Single);
begin
  Bottom := Top + Value;
  if Top > Bottom then HGeneric.Swap<Single>(Top, Bottom);
end;

procedure RRectFloat.SetLeftBottom(const Value : RVector2);
begin
  Left := Value.X;
  Bottom := Value.Y;
end;

procedure RRectFloat.SetLeftWidth(const Value : RVector2);
begin
  Left := Value.X;
  Width := Value.Y;
end;

procedure RRectFloat.SetPos(index : integer; const Value : Single);
begin
  if index = 0 then X := Value
  else Y := Value;
end;

procedure RRectFloat.SetPosition(const Value : RVector2);
var
  Size : RVector2;
begin
  Size := self.Size;
  LeftTop := Value;
  RightBottom := Value + Size;
end;

procedure RRectFloat.SetRightTop(const Value : RVector2);
begin
  Right := Value.X;
  Top := Value.Y;
end;

function RRectFloat.SetSize(const NewSize : RVector2) : RRectFloat;
begin
  Result := self;
  Result.Size := NewSize;
end;

procedure RRectFloat.SetTopHeight(const Value : RVector2);
begin
  Top := Value.X;
  Height := Value.Y;
end;

procedure RRectFloat.SetPropSize(const Value : RVector2);
begin
  Width := Value.X;
  Height := Value.Y;
end;

function RRectFloat.SetWidth(const NewWidth : Single) : RRectFloat;
begin
  Result.Left := self.Left;
  Result.Top := self.Top;
  Result.Right := self.Left + NewWidth;
  Result.Bottom := self.Bottom;
end;

procedure RRectFloat.SetPropWidth(const Value : Single);
begin
  Right := Left + Value;
  if Left > Right then HGeneric.Swap<Single>(Left, Right);
end;

procedure RRectFloat.SetX(const Value : Single);
begin
  Right := Value + Width;
  Left := Value;
end;

procedure RRectFloat.SetY(const Value : Single);
begin
  Bottom := Value + Height;
  Top := Value;
end;

function RRectFloat.Translate(X, Y : Single) : RRectFloat;
begin
  Result.Left := self.Left + X;
  Result.Right := self.Right + X;
  Result.Top := self.Top + Y;
  Result.Bottom := self.Bottom + Y;
end;

function RRectFloat.Translate(const XY : RVector2) : RRectFloat;
begin
  Result := Translate(XY.X, XY.Y);
end;

function RRectFloat.Trunc : RRect;
begin
  Result.Left := System.Trunc(Left);
  Result.Right := System.Trunc(Right);
  Result.Top := System.Trunc(Top);
  Result.Bottom := System.Trunc(Bottom);
end;

{ RRay2D }

constructor RRay2D.Create(const Origin, Direction : RVector2);
begin
  self.Origin := Origin;
  self.Direction := Direction;
end;

function RRay2D.DistanceToPoint(const Point : RVector2) : Single;
var
  dist : RVector2;
begin
  dist := (Point - Origin);
  Result := sqrt(sqr(dist.Length) - sqr(dist.Dot(Direction)));
end;

function RRay2D.IntersectionWithRay(const otherRay : RRay2D) : RVector2;
var
  rs, u : Single;
begin
  rs := Direction.Cross(otherRay.Direction);
  if (rs = 0) then
      exit(RVector2.ZERO); // Parallel
  u := (otherRay.Origin - Origin).Cross(otherRay.Direction) / rs;
  Result := Origin + (u * Direction);
end;

function RRay2D.NearestPointToPoint(const Point : RVector2) : RVector2;
begin
  Result := (Point - Origin).Dot(Direction) * Direction + Origin;
end;

procedure RRay2D.SetDirection(const Value : RVector2);
begin
  FDirection := Value.Normalize;
end;

{ RLine2D }

constructor RLine2D.Create(const Origin, Direction : RVector2);
begin
  self.Origin := Origin;
  self.Direction := Direction;
end;

constructor RLine2D.CreateFromPoints(const Startpoint, Endpoint : RVector2);
begin
  self.Origin := Startpoint;
  self.Endpoint := Endpoint;
end;

function RLine2D.DistanceToPoint(const Point : RVector2) : Single;
begin
  Result := NearestPointOnLine(Point).Distance(Point);
end;

class function RLine2D.EMPTY : RLine2D;
begin
  Result.Origin := RVector2.EMPTY;
  Result.Direction := RVector2.ZERO;
end;

function RLine2D.GetCenter : RVector2;
begin
  Result := Origin + (Direction * 0.5);
end;

function RLine2D.GetEndpoint : RVector2;
begin
  Result := Origin + Direction;
end;

function RLine2D.GetLength : Single;
begin
  Result := Direction.Length();
end;

procedure RLine2D.IntersectionWithLineRaw(const AnotherLine : RLine2D; out u, t : Single);
var
  rs : Single;
begin
  rs := Direction.Cross(AnotherLine.Direction);
  if (rs = 0) then
  begin
    t := -1;
    u := -1;
    exit;
  end;
  t := (AnotherLine.Origin - Origin).Cross(AnotherLine.Direction) / rs;
  u := (AnotherLine.Origin - Origin).Cross(Direction) / rs;
end;

function RLine2D.IntersectionWithLine(const AnotherLine : RLine2D) : RVector2;
var
  t, u : Single;
begin
  IntersectionWithLineRaw(AnotherLine, u, t);
  if (0 <= t) and (t <= 1) and (0 <= u) and (u <= 1) then Result := Origin + Direction * t
  else Result := RVector2.EMPTY;
end;

function RLine2D.IntersectWithLine(const AnotherLine : RLine2D) : boolean;
var
  t, u : Single;
begin
  IntersectionWithLineRaw(AnotherLine, u, t);
  Result := (0 <= t) and (t <= 1) and (0 <= u) and (u <= 1);
end;

function RLine2D.IsEmpty : boolean;
begin
  Result := Origin.IsEmpty;
end;

function RLine2D.IsLeft(const Point : RVector2) : boolean;
begin
  Result := Origin.DirectionTo(Point).Dot(Direction.GetOrthogonal) >= 0;
end;

function RLine2D.IsOrthogonalProjectionOnLine(const Point : RVector2) : boolean;
var
  dl, dist : Single;
begin
  dl := Direction.Length;
  if dl = 0 then exit(False);
  dist := (Point - Origin).Dot(Direction / dl);
  Result := (dist >= 0) and (dist <= dl);
end;

function RLine2D.Lerp(s : Single) : RVector2;
begin
  Result := Origin + s * Direction;
end;

function RLine2D.NearestPointOnLine(const Point : RVector2) : RVector2;
var
  dl : Single;
begin
  dl := 1 / Direction.Length;
  Result := HMath.Saturate((Point - Origin).Dot(Direction * dl) * dl) * Direction + Origin;
end;

function RLine2D.Reverse : RLine2D;
begin
  Result.Origin := Endpoint;
  Result.Direction := -Direction;
end;

procedure RLine2D.SetEndpoint(const Value : RVector2);
begin
  Direction := Value - Origin;
end;

procedure RLine2D.SetLength(const Value : Single);
begin
  Direction := Direction.SetLength(Value)
end;

function RLine2D.ToRay : RRay2D;
begin
  Result := RRay2D.Create(Origin, Direction);
end;

{ RCircle }

function RCircle.ClampPoint(const Point : RVector2) : RVector2;
begin
  Result := (Point - Center).SetLengthMax(Radius) + Center;
end;

function RCircle.ContainsPoint(const Point : RVector2) : boolean;
begin
  Result := (Point - self.Center).LengthSq <= sqr(self.Radius);
end;

constructor RCircle.Create(const Center : RVector2; Radius : Single);
begin
  self.Center := Center;
  self.Radius := Radius;
end;

function RCircle.DistanceToCircle(const Circle : RCircle) : Single;
begin
  Result := self.Center.Distance(Circle.Center) - (Circle.Radius + self.Radius);
end;

function RCircle.DistanceToPoint(const Point : RVector2) : Single;
begin
  Result := self.Center.Distance(Point) - (self.Radius);
end;

function RCircle.IntersectCircle(const Circle : RCircle) : boolean;
begin
  Result := (Circle.Center - self.Center).LengthSq <= sqr(Circle.Radius + Radius);
end;

function RCircle.IntersectRay(const Ray : RRay2D) : boolean;
begin
  Result := Ray.DistanceToPoint(Center) <= Radius;
end;

function RCircle.IntersectRect(const Rect : RRectFloat) : boolean;
var
  dist, halfrectdim : RVector2;
  cornerdistsq : Single;
begin
  // algo from: http://stackoverflow.com/questions/401847/circle-rectangle-collision-detection-intersection/402010#402010
  dist := (Center - Rect.Center).abs;
  halfrectdim := RVector2.Create(Rect.Width / 2, Rect.Height / 2);

  if (dist.X > (halfrectdim.X + Radius)) then exit(False);
  if (dist.Y > (halfrectdim.Y + Radius)) then exit(False);

  if (dist.X <= (halfrectdim.X)) then exit(true);
  if (dist.Y <= (halfrectdim.Y)) then exit(true);

  cornerdistsq := sqr(dist.X - halfrectdim.X) + sqr(dist.Y - halfrectdim.Y);

  Result := (cornerdistsq <= sqr(Radius));
end;

function RCircle.IntersectionRay(const Ray : RRay2D) : RLine2D;
var
  centerProjection : RVector2;
  distToBorder : Single;
begin
  if not IntersectRay(Ray) then exit(RLine2D.CreateFromPoints(RVector2.EMPTY, RVector2.EMPTY));
  centerProjection := Ray.NearestPointToPoint(Center);
  distToBorder := sqrt(sqr(Radius) - sqr(centerProjection.Distance(Center)));
  Result := RLine2D.CreateFromPoints(centerProjection + distToBorder * Ray.Direction, centerProjection - distToBorder * Ray.Direction);
end;

function RCircle.IntersectLine(const Line : RLine2D) : boolean;
var
  diff : RVector2;
  centerProjectionRange : Single;
begin
  diff := Center - Line.Origin;
  centerProjectionRange := diff.Dot(Line.Direction.Normalize);
  Result := (centerProjectionRange >= -Radius) and (centerProjectionRange <= Line.Length + Radius) and (Line.DistanceToPoint(Center) <= Radius);
end;

{ TPolygon }

procedure TPolygon.AddNode(const Node : RVector2);
begin
  FNodes.Add(Node);
end;

constructor TPolygon.Create;
begin
  FNodes := TList<RVector2>.Create;
end;

constructor TPolygon.Create(Nodes : array of RVector2);
begin
  Create;
  FNodes.AddRange(Nodes);
end;

function TPolygon.Center : RVector2;
var
  i : integer;
begin
  Result := RVector2.ZERO;
  if Nodes.Count <= 0 then exit;
  for i := 0 to Nodes.Count - 1 do
      Result := Result + Nodes[i];
  Result := Result / Nodes.Count;
end;

function TPolygon.Clone : TPolygon;
begin
  Result := TPolygon.Create;
  Result.FClosed := FClosed;
  Result.FNodes.AddRange(FNodes.ToArray);
end;

procedure TPolygon.CornerCutting(Times : integer);
var
  i, j, prev, next : integer;
  dirprev, dirnext : RVector2;
  // shortestlength : Single;
  old : TList<RVector2>;
begin
  if (Nodes.Count < 3) then exit;
  for j := 0 to Times - 1 do
  begin
    old := TList<RVector2>.Create(FNodes);
    FNodes.Clear;
    for i := 0 to old.Count - 1 do
    begin
      prev := i - 1;
      if (prev < 0) then
      begin
        if Closed then prev := old.Count + prev
        else prev := 0;
      end;
      next := i;
      dirprev := old[prev] - old[next];
      prev := i;
      next := i + 1;
      if (next >= old.Count) then
      begin
        if Closed then next := next mod old.Count
        else next := old.Count - 1;
      end;
      dirnext := old[next] - old[prev];
      // shortestlength := min(dirprev.Length, dirnext.Length);
      // dirprev := dirprev.SetLength(shortestlength);
      // dirnext := dirnext.SetLength(shortestlength);
      FNodes.Add(old[i].Lerp(old[i] + dirprev, 0.25));
      FNodes.Add(old[i].Lerp(old[i] + dirnext, 0.25));
    end;
    old.Free;
  end;
end;

constructor TPolygon.Create(Nodes : TList<RVector2>);
begin
  Create;
  FNodes.AddRange(Nodes);
end;

procedure TPolygon.DeleteNode(index : integer);
begin
  FNodes.Delete(index);
end;

destructor TPolygon.Destroy;
begin
  FNodes.Free;
  inherited;
end;

function TPolygon.EdgeCount : integer;
begin
  if Closed then Result := FNodes.Count
  else Result := FNodes.Count - 1;
end;

function TPolygon.EnsurePointInPoly(const Point : RVector2) : RVector2;
begin
  if IsPointInPolygon(Point) then Result := Point
  else Result := NearestPointAtBorder(Point);
end;

function TPolygon.GetEdge(index : integer) : RLine2D;
begin
  assert((Closed and (index <= Nodes.Count - 1)) or ((index <= Nodes.Count - 2)));
  Result := RLine2D.CreateFromPoints(Nodes[index], Nodes[(index + 1) mod (Nodes.Count)]);
end;

function TPolygon.GetInnerAngle(index : integer) : Single;
var
  ln, rn, checkpoint : RVector2;
begin
  if not Closed then exit(NaN);
  ln := (FNodes[(FNodes.Count + (index - 1)) mod (FNodes.Count)] - FNodes[index]);
  rn := (FNodes[(index + 1) mod (FNodes.Count)] - FNodes[index]);
  checkpoint := (ln + rn).Normalize * 0.01 + FNodes[index];
  ln.InNormalisieren;
  rn.InNormalisieren;
  Result := arccos(ln.Dot(rn));
  if not IsPointInPolygon(checkpoint) then Result := 2 * PI - Result;
end;

procedure TPolygon.InsertNode(index : integer; const Node : RVector2);
begin
  FNodes.Insert(index, Node);
end;

function TPolygon.IntersectBorderWithLine(const Line : RLine2D) : boolean;
var
  i : integer;

begin
  Result := False;
  for i := 0 to Nodes.Count - 2 do
    if Edge[i].IntersectWithLine(Line) then exit(true);
  if Closed then
    if Edge[Nodes.Count - 1].IntersectWithLine(Line) then exit(true);
end;

function TPolygon.IsClockwise : boolean;
var
  Center : RVector2;
begin
  Center := self.Center;
  if not Closed or (Nodes.Count < 2) then exit(False);
  Result := sign((FNodes[1] - Center).X0Y.Cross((FNodes[0] - Center).X0Y).Y) = 1;
end;

function TPolygon.IsConvex : boolean;
var
  i : integer;
  tsign : Single;
  function CrossOfIndex(i : integer) : Single;
  var
    dx1, dx2, dy1, dy2 : Single;
  begin
    dx1 := FNodes[i + 1].X - FNodes[i].X;
    dy1 := FNodes[i + 1].Y - FNodes[i].Y;
    dx2 := FNodes[i + 2].X - FNodes[i + 1].X;
    dy2 := FNodes[i + 2].Y - FNodes[i + 1].Y;
    Result := dx1 * dy2 - dy1 * dx2;
  end;

begin
  if not Closed then exit(False);
  tsign := CrossOfIndex(0);
  for i := 1 to FNodes.Count - 1 do
    if sign(tsign) <> sign(CrossOfIndex(i)) then exit(False);
  Result := true;
end;

function TPolygon.IsNodeConvex(index : integer) : boolean;
var
  innerAngle : Single;
begin
  innerAngle := GetInnerAngle(index);
  if isNan(innerAngle) then exit(False);
  Result := innerAngle > PI;
end;

function TPolygon.IsPointInPolygon(const Point : RVector2) : boolean;
var
  i : integer;
  Startpoint, Endpoint : RVector2;
begin
  if not Closed then exit(False);
  Result := False;
  for i := 0 to FNodes.Count - 1 do
  begin
    Startpoint := FNodes[i];
    Endpoint := FNodes[(i + 1) mod (FNodes.Count)];
    if (((Startpoint.Y > Point.Y) <> (Endpoint.Y > Point.Y)) and
      (Point.X < (Endpoint.X - Startpoint.X) * (Point.Y - Startpoint.Y) / (Endpoint.Y - Startpoint.Y) + Startpoint.X)) then
        Result := not Result;
  end;
end;

function TPolygon.Length(index : integer) : Single;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to min(index, EdgeCount) - 1 do Result := Result + Edge[i].Length;
end;

function TPolygon.Length : Single;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to EdgeCount - 1 do Result := Result + Edge[i].Length;
end;

function TPolygon.NearestNodeToPoint(const Point : RVector2) : RVector2;
var
  i : integer;
begin
  Result := RVector2.EMPTY;
  for i := 0 to FNodes.Count - 1 do
    if Result.IsEmpty or (Point.Distance(FNodes[i]) < Point.Distance(Result)) then Result := FNodes[i];
end;

function TPolygon.NearestPointAtBorder(const Point : RVector2) : RVector2;
var
  i : integer;
  nearest : RVector2;
begin
  Result := RVector2.EMPTY;
  for i := 0 to EdgeCount - 1 do
  begin
    nearest := Edge[i].NearestPointOnLine(Point);
    if Result.IsEmpty or (Point.Distance(nearest) < Point.Distance(Result)) then Result := nearest;
  end;
end;

function TPolygon.NearestPointOutside(const Point : RVector2) : RVector2;
var
  i : integer;
  nearest, potential : RVector2;
begin
  Result := RVector2.EMPTY;
  for i := 0 to EdgeCount - 1 do
  begin
    nearest := Edge[i].NearestPointOnLine(Point);
    // prevent expensive PointInPoly-Test for point far away
    if Result.IsEmpty or (Point.Distance(nearest) < Point.Distance(Result)) then
    begin
      potential := nearest + Edge[i].Direction.Normalize.GetOrthogonal * COLLISIONEPSILON;
      if IsPointInPolygon(potential) then potential := -potential;
      if Result.IsEmpty or (Point.Distance(potential) < Point.Distance(Result)) then Result := potential;
    end;
  end;
end;

procedure TPolygon.Reverse;
begin
  FNodes.Reverse;
end;

{ TMultipolygon }

procedure TMultipolygon.AddPolygon(Poly : TPolygon; Subtractive : boolean);
begin
  FPolygons.Add(RMultipolygon.Create(Poly, Subtractive));
end;

constructor TMultipolygon.Create;
begin
  FPolygons := TList<RMultipolygon>.Create;
end;

procedure TMultipolygon.DeletePolygon(index : integer);
begin
  if (index >= 0) and (index < FPolygons.Count) then
  begin
    FPolygons[index].Polygon.Free;
    FPolygons.Delete(index);
  end;
end;

destructor TMultipolygon.Destroy;
var
  i : integer;
begin
  for i := 0 to FPolygons.Count - 1 do FPolygons[i].Polygon.Free;
  FPolygons.Free;
  inherited;
end;

function TMultipolygon.EnsurePointInMultiPoly(const Point : RVector2) : RVector2;
begin
  // point is inside => all fine
  if IsPointInMultiPolygon(Point) then exit(Point);
  Result := NextPointOnBorder(Point);
end;

function TMultipolygon.NextPointOnBorder(const Point : RVector2) : RVector2;
var
  temp : RVector2;
  i : integer;
begin
  Result := RVector2.EMPTY;
  for i := 0 to FPolygons.Count - 1 do
  begin
    temp := FPolygons[i].Polygon.NearestPointAtBorder(Point);
    if Result.IsEmpty or (Result.Distance(Point) > temp.Distance(Point)) then Result := temp;
  end;
  // prevent rounding error, pushin result slightly into polygon
  Result := Result + ((Result - Point).Normalize * COLLISIONEPSILON);
end;

function TMultipolygon.IsLineInMultiPolygon(const Line : RLine2D) : boolean;
var
  i : integer;
begin
  if not(IsPointInMultiPolygon(Line.Origin) and IsPointInMultiPolygon(Line.Endpoint)) then exit(False);
  for i := 0 to Polygons.Count - 1 do
    if Polygons[i].Polygon.IntersectBorderWithLine(Line) then exit(False);
  Result := true;
end;

function TMultipolygon.IsPointInMultiPolygon(const Point : RVector2) : boolean;
var
  counter, i : integer;
begin
  counter := 0;
  for i := 0 to FPolygons.Count - 1 do
    if FPolygons[i].Polygon.IsPointInPolygon(Point) then
    begin
      if FPolygons[i].Subtractive then dec(counter)
      else inc(counter);
    end;
  Result := counter > 0;
end;

{ TMultipolygon.RMultipolygon }

constructor TMultipolygon.RMultipolygon.Create(Poly : TPolygon; Subtract : boolean);
begin
  self.Subtractive := Subtract;
  self.Polygon := Poly;
end;

{ ROrientedRect }

function ROrientedRect.BottomLeft : RVector2;
begin
  Result := Position - (Front * (Size.Y / 2)) + (Left * (Size.X / 2));
end;

function ROrientedRect.BottomRight : RVector2;
begin
  Result := Position - (Front * (Size.Y / 2)) - (Left * (Size.X / 2));
end;

function ROrientedRect.ContainsPoint(const b : RVector2) : boolean;
var
  temp : RVector2;
begin
  temp := PointToAxisSpace(b).abs;
  Result := (temp.X <= Width / 2) and (temp.Y <= Height / 2);
end;

constructor ROrientedRect.Create(const Position, Front, Size : RVector2);
begin
  FPosition := Position;
  FFront := Front.Normalize;
  FSize := Size;
end;

function ROrientedRect.GetHeight : Single;
begin
  Result := FSize.Y;
end;

function ROrientedRect.GetLeft : RVector2;
begin
  Result := FFront.GetOrthogonal;
end;

function ROrientedRect.GetWidth : Single;
begin
  Result := FSize.X;
end;

function ROrientedRect.IntersectsCircle(const b : RCircle) : boolean;
var
  TransformedCenter : RVector2;
  SquaredCornerDistance : Single;
begin
  TransformedCenter := PointToAxisSpace(b.Center);
  // http://stackoverflow.com/questions/401847/circle-rectangle-collision-detection-intersection
  TransformedCenter := TransformedCenter.abs;

  if (TransformedCenter.X > (Width / 2 + b.Radius)) then exit(False);
  if (TransformedCenter.Y > (Height / 2 + b.Radius)) then exit(False);

  if (TransformedCenter.X <= (Width / 2)) then exit(true);
  if (TransformedCenter.Y <= (Height / 2)) then exit(true);

  SquaredCornerDistance := sqr(TransformedCenter.X - Width / 2) + sqr(TransformedCenter.Y - Height / 2);

  Result := SquaredCornerDistance <= sqr(b.Radius);
end;

function ROrientedRect.PointToAxisSpace(const Point : RVector2) : RVector2;
var
  temp : RVector2;
begin
  temp := (Point - Position);
  Result.X := temp.Dot(Left);
  Result.Y := temp.Dot(Front);
end;

procedure ROrientedRect.SetFront(const Value : RVector2);
begin
  FFront := Value.Normalize;
end;

procedure ROrientedRect.SetHeight(const Value : Single);
begin
  FSize.Y := Value;
end;

procedure ROrientedRect.SetWidth(const Value : Single);
begin
  FSize.X := Value;
end;

function ROrientedRect.TopLeft : RVector2;
begin
  Result := Position + (Front * (Size.Y / 2)) + (Left * (Size.X / 2));
end;

function ROrientedRect.TopRight : RVector2;
begin
  Result := Position + (Front * (Size.Y / 2)) - (Left * (Size.X / 2));
end;

function ROrientedRect.ToWrappingCircle : RCircle;
begin
  Result.Center := Position;
  Result.Radius := Size.Length / 2;
end;

{ RRectHelper }

function RRectHelper.ToRectFloat : RRectFloat;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Right;
  Result.Bottom := Bottom;
end;

end.
