unit Engine.Math.Collision3D;

interface

uses
  Math,
  Engine.Math,
  SysUtils;

const

  COLLISIONEPSILON = 1E-7;
  MAXDISTANCE      = 1E5;

type

  RRay = record
    strict private
      FDirection : RVector3;
      procedure SetDirection(const Value : RVector3);
    private
      procedure ClosestPointsParametersBetweenRays(const Ray : RRay; out u, v : single);
    public
      Origin : RVector3;
      property Direction : RVector3 read FDirection write SetDirection;
      constructor Create(const Origin, Direction : RVector3);
      function GetPoint(Distance : single) : RVector3;
      function DistanceToRay(const Ray : RRay) : single;
      function NearestPointToRay(const Ray : RRay) : RVector3;
      function DistanceToPoint(const Point : RVector3) : single;
      function NearestPointToPoint(const Point : RVector3) : RVector3;
  end;

  PLine = ^RLine;

  RLine = record
    strict private
      function getEndpoint : RVector3;
      procedure setEndpoint(const Value : RVector3);
    public
      Origin : RVector3;
      /// <summary> Length of direction determines length of the line segment. </summary>
      Direction : RVector3;
      property Endpoint : RVector3 read getEndpoint write setEndpoint;
      constructor CreateFromPoints(const Startpoint, Endpoint : RVector3);
      constructor Create(const Origin, Direction : RVector3);
      function DistanceToPoint(const Point : RVector3) : single;
      function ClosestPointToRay(const Ray : RRay) : RVector3;
      function DistanceToRay(const Ray : RRay) : single;
      function DistanceToLine(const Line : RLine) : single;
      function Lerp(const b : RLine; s : single) : RLine;
      function ToRay : RRay;
      function Translate(const MoveVector : RVector3) : RLine;
  end;

  PRPlane = ^RPlane;

  RPlane = packed record
    private
      FNormal : RVector3;
      procedure setNormal(const Value : RVector3);
    public
      Position : RVector3;
      property Normal : RVector3 read FNormal write setNormal;
      constructor CreateFromPoints(const v1, v2, v3 : RVector3);
      constructor CreateFromCenter(const Center, Direction1, Direction2 : RVector3);
      constructor CreateFromKartesian(a, b, c, d : single);
      constructor CreateFromNormal(const Position, Normal : RVector3);
      function Reflect(const IncidentVector : RVector3) : RVector3;
      function Normalize : RPlane;
      function DistanceAbsolute(const a : RVector3) : single;
      function DistanceSigned(const a : RVector3) : single;
      function ParallelToRay(const Ray : RRay) : boolean;
      function IntersectRay(const Ray : RRay) : RVector3;
      function IntersectPlane(const Plane : RPlane) : RRay;
      function Intersect3Planes(const Plane2, Plane3 : RPlane) : RVector3;
      function ProjectPointToPlane(const Point : RVector3) : RVector3;
      function ToCartesian : RVector4;
      function SimilarTo(const b : RPlane) : boolean;
      function Translate(const Offset : RVector3) : RPlane;
      /// <summary> Effectively ToString </summary>
      class operator implicit(const a : RPlane) : string;
  end;

  RPlaneConstantHelper = record helper for RPlane
    const
      XY : RPlane = (FNormal : (x : 0; y : 0; z : 1); Position : (x : 0; y : 0; z : 0));
      XZ : RPlane = (FNormal : (x : 0; y : 1; z : 0); Position : (x : 0; y : 0; z : 0));
      YZ : RPlane = (FNormal : (x : 1; y : 0; z : 0); Position : (x : 0; y : 0; z : 0));
  end;

  PSphere = ^RSphere;

  RSphere = record
    public
      Center : RVector3;
      Radius : single;
      constructor CreateSphere(const Center : RVector3; Radius : single);
      constructor CreateWrapping(Spheres : array of RSphere);
      /// <summary> Ensures that point lies in the sphere. If its outside its projected to the surface. </summary>
      function ClampPointToSphere(const Point : RVector3) : RVector3;
      function IntersectSphereSphere(const Sphere : RSphere) : boolean;
      function IntersectSphereLine(const Line : RLine) : boolean;
      function IntersectSphereRay(const Ray : RRay) : boolean;
  end;

  RSphereConstantHelper = record helper for RSphere
    const
      ZERO : RSphere = (Center : (x : 0; y : 0; z : 0); Radius : 0);
  end;

  RTriangle = packed record
    constructor Create(const Point1, Point2, Point3 : RVector3);
    function GetNormal() : RVector3;
    function GetPlane() : RPlane;
    function IntersectRayTriangle(const Ray : RRay) : boolean;
    function IntersectLineTriangle(const Line : RLine) : boolean;
    function ContainsPoint(const Point : RVector3) : boolean;
    function PointToBaryCentric(const Point : RVector3) : RVector3;
    case byte of
      0 : (Vertex1, Vertex2, Vertex3 : RVector3);
      1 : (Vertices : array [0 .. 2] of RVector3);
  end;

  PQuad = ^RQuad;

  RQuad = packed record
    strict private
      function getVertex4 : RVector3;
    public
      /// <summary> Build quad as parallelogram => P4 is P1 mirrored at P2P3. </summary>
      constructor CreateFromPoints(const Point1, Point2, Point3 : RVector3);
      function GetNormal() : RVector3;
      function IntersectRayQuad(const Ray : RRay) : boolean;
      function IntersectSphereQuad(const Sphere : RSphere) : boolean;
      function IntersectQuadQuad(const Quad : RQuad) : boolean;
      function IntersectLineQuad(const Line : RLine) : boolean;
      property Vertex4 : RVector3 read getVertex4;
      case byte of
        0 : (Vertex1, Vertex2, Vertex3 : RVector3);
        1 : (Vertices : array [0 .. 2] of RVector3);
  end;

  PAABB = ^RAABB;

  RAABB = record
    private
      function getCorner(index : integer) : RVector3;
    public
      const
      CORNERCOUNT = 8;
    var
      Min, Max : RVector3;
      property Corners[index : integer] : RVector3 read getCorner;
      constructor Create(const Min, Max : RVector3); overload;
      constructor CreateWrapping(const Sphere : RSphere); overload;
      constructor CreateWrapping(Boxes : array of RAABB); overload;
      /// <summary> Size is expected to be the diameter in each direction. </summary>
      constructor CreateFromPositionSize(const Position, Size : RVector3); overload;
      constructor Create(const Point : RVector3); overload;
      function Center : RVector3;
      function Top : RVector3;
      function HalfExtents : RVector3;
      /// <summary> Determines whether the point lies in the AABB. </summary>
      function ContainsPoint(const Point : RVector3) : boolean;
      function ContainsAABB(const AABB : RAABB) : boolean;
      /// <summary> Ensures that point lies in the AABB. If its outside its projected to the surface. </summary>
      function ClampPoint(const Point : RVector3) : RVector3;
      /// <summary> Extends the AABB so that the point is included. </summary>
      procedure Extend(const Point : RVector3); overload;
      procedure Extend(const AABB : RAABB); overload;
      function IntersectAABBAABB(const AABB : RAABB) : boolean;
      function IntersectionSetAABB(const AABB : RAABB) : RAABB;
      /// <summary> Returns the intersection set of the aabb and the line. Returns nonsense if AABB isn't hit by the line. </summary>
      function IntersectLine(const Line : RLine) : RLine;
      /// <summary> Returns the intersection set of the aabb and the ray. Returns nonsense if AABB isn't hit by ray. </summary>
      function IntersectRay(const Ray : RRay) : RLine;
      function IntersectsRay(const Ray : RRay) : boolean;
      function DistanceToPoint(const Point : RVector3) : single;
      function getPositiveVertex(const Normal : RVector3) : RVector3;
      function getNegativeVertex(const Normal : RVector3) : RVector3;
      function Scale(const Scaler : RVector3) : RAABB;
      function Translate(const MoveVector : RVector3) : RAABB;
      function ToSphere() : RSphere;
  end;

  PZylinder = ^RCylinder;

  RCylinder = record
    strict private
      procedure setEndpoint(const Value : RVector3);
      function getEndpoint : RVector3;
    public
      Start, Direction : RVector3; // Richtung ist normalisiert zu halten
      Radius, Height : single;
      property Endpoint : RVector3 read getEndpoint write setEndpoint;
      constructor Create(const Start, Direction : RVector3; Radius, Height : single);
      function IntersectCylinderSphere(const Sphere : RSphere) : boolean;
      function IntersectCylinderLine(const Line : RLine) : boolean;
  end;

  PCapsule = ^RCapsule;

  RCapsule = record
    strict private
      FDirection : RVector3;
      procedure SetDirection(const Value : RVector3);
      procedure setEndpoint(const Value : RVector3);
      function getEndpoint : RVector3;
    public
      Origin : RVector3;
      Radius, Height : single;
      property Direction : RVector3 read FDirection write SetDirection;
      property Endpoint : RVector3 read getEndpoint write setEndpoint;
      constructor Create(const Origin, Direction : RVector3; Radius, Height : single); overload;
      constructor Create(const Origin, Endpoint : RVector3; Radius : single); overload;
      function DistanceToPoint(const Point : RVector3) : single;
      function IntersectCapsuleSphere(const Sphere : RSphere) : boolean;
      function IntersectCapsuleLine(const Line : RLine; IntersectionSet : PLine = nil) : boolean;
      function IntersectCapsuleRay(const Ray : RRay; IntersectionSet : PLine = nil) : boolean;
      /// <summary> Drop radius. </summary>
      function ToLine : RLine;
      /// <summary> Drop caps. </summary>
      function ToCylinder : RCylinder;
  end;

  PFrustum = ^RFrustum;

  RFrustum = record
    private
      function getCorner(index : integer) : RVector3;
      function getRay(index : integer) : RRay;
      function getLine(index : integer) : RLine;
      function getFarPlane : RPlane;
      function getNearPlane : RPlane;
      procedure setFarPlane(const Value : RPlane);
      procedure setNearPlane(const Value : RPlane);
    public
      const
      CORNER_COUNT = 8;
      LINE_COUNT   = 4;

    type
      AFrustumPlanes = array [0 .. 5] of RPlane;
    var
      // Left, Right, Top, Bottom, Near, Far
      Planes : AFrustumPlanes;
      property NearPlane : RPlane read getNearPlane write setNearPlane;
      property FarPlane : RPlane read getFarPlane write setFarPlane;
      /// <summary> Returns [0:NearLeftTop,1:NearTopRight,2:NearRightBottom,3:NearBottomLeft,4:FarLeftTop,5:FarTopRight,6:FarRightBottom,7:FarBottomLeft] </summary>
      property Corners[index : integer] : RVector3 read getCorner;
      property Rays[index : integer] : RRay read getRay;
      property Lines[index : integer] : RLine read getLine;
      /// <summary> Extract from Projection*View => Planes:[Left, Right,Top,Bottom,Near,Far] </summary>
      constructor CreateFromViewProjectionMatrix(const View : RMatrix);
      function NearCenter : RVector3;
      function FarCenter : RVector3;
      function Direction : RVector3;
      // Intersection methods
      /// <summary> Returns the smallest signed distance to a plane. Returns 0 if intersecting. </summary>
      function DistanceToPlane(const Plane : RPlane) : single;
      /// <summary> Returns the smallest signed distance to a plane. > if outside, <=0 if inside. </summary>
      function DistanceToPoint(const Point : RVector3) : single;
      function IntersectSphere(const Sphere : RSphere; OmitNearFar : boolean = False) : boolean;
      function ContainsAABB(const AABB : RAABB) : boolean;
      function IntersectAABB(const AABB : RAABB; OmitNearFar : boolean = False) : boolean;
      function IntersectionSetAABB(const AABB : RAABB) : RAABB;
      /// <summary> Returns all in and out points of the 4 view rays + X lerped. Can contain Empty Vectors </summary>
      function IntersectionSetAABBRaw(const AABB : RAABB) : TArray<RVector3>;
      /// <summary> Moves the far and near plane to be as tight as possible to the AABB as long as there are outside of the box.
      /// The frustum sides are not affected. </summary>
      function FitNearFarToAABB(const AABB : RAABB) : RFrustum;
  end;

  /// <summary> Oriented Bounding Box, Position is the center of the box pointing to Front with Up. Size is the half size of the box. </summary>
  ROBB = record
    private
      function getCorner(index : integer) : RVector3;
      function GetInterval(const Axis : RVector3) : RVector2;
      function getLine(index : integer) : RLine;
      function getLeft : RVector3;
      function getRay(index : integer) : RRay;
    public
      /// <summary> Size is the half diameter in each direction. </summary>
      Position, Front, Up, Size : RVector3;
      property Left : RVector3 read getLeft;
      /// <summary> Returns [0:BackLeftUp,1:BackUpRight,2:BackRightDown,3:FrontDownLeft,4:FrontLeftUp,5:FrontUpRight,6:FrontRightDown,7:FrontDownLeft] </summary>
      property Corners[index : integer] : RVector3 read getCorner;
      property Lines[index : integer] : RLine read getLine;
      property Rays[index : integer] : RRay read getRay;
      constructor Create(const Position, Front, Up, Size : RVector3);
      constructor CreateWrappedAroundFrustum(const Frustum : RFrustum; const Front, Up : RVector3);
      constructor CreateWrappedAroundAABB(const AABB : RAABB; const Front, Up : RVector3);
      /// <summary> Extends the OBB so that the point lies within. Preserves the position. </summary>
      procedure Extend(const Point : RVector3); overload;
      /// <summary> Extends the OBB so that the point lies within. Moves the position. </summary>
      procedure ExtendOptimal(Point : RVector3);
      procedure Extend(const AABB : RAABB); overload;
      function GetWrappingAABB() : RAABB;
      function ContainsPoint(const Point : RVector3) : boolean;
      function NearestPointToPoint(const Point : RVector3) : RVector3;
      function IntersectOBBOBB(const OBB : ROBB) : boolean;
      /// <summary> Moves the far and near plane to be as tight as possible to the AABB. The obb sides are not affected.
      /// Uses an iteration not a real mathematical solution atm :/</summary>
      function FitNearFarToAABB(const AABB : RAABB) : ROBB;
  end;

  HIntersection = class
    class function SphereFrustum(const Sphere : RSphere; const Frustum : RFrustum) : boolean; static;
    class function AABBFrustum(const AABB : RAABB; const Frustum : RFrustum) : boolean; static;
  end;

implementation

{ RPlane }

constructor RPlane.CreateFromCenter(const Center, Direction1, Direction2 : RVector3);
begin
  self.Position := Center;
  self.Normal := Direction1.Cross(Direction2);
end;

constructor RPlane.CreateFromKartesian(a, b, c, d : single);
var
  temp : RVector3;
begin
  temp.x := a;
  temp.y := b;
  temp.z := c;
  d := -d / temp.Length;
  Normal := temp;
  Position := Normal * d;
end;

constructor RPlane.CreateFromNormal(const Position, Normal : RVector3);
begin
  self.Position := Position;
  self.Normal := Normal;
end;

constructor RPlane.CreateFromPoints(const v1, v2, v3 : RVector3);
begin
  self.Position := v1;
  self.Normal := ((v2 - v1).Cross(v3 - v1));
end;

function RPlane.DistanceAbsolute(const a : RVector3) : single;
begin
  Result := abs(DistanceSigned(a));
end;

function RPlane.DistanceSigned(const a : RVector3) : single;
begin
  Result := (a - Position).Dot(Normal);
end;

class operator RPlane.implicit(const a : RPlane) : string;
begin
  Result := '(' + string(a.Position) + ';' + a.Normal + ')';
end;

function RPlane.Intersect3Planes(const Plane2, Plane3 : RPlane) : RVector3;
begin
  Result := Plane3.IntersectRay(IntersectPlane(Plane2))
end;

function RPlane.IntersectPlane(const Plane : RPlane) : RRay;
var
  tempRay : RRay;
begin
  Result.Direction := Normal.Cross(Plane.Normal);
  tempRay := RRay.Create(Position, Normal.Cross(Result.Direction));
  Result.Origin := Plane.IntersectRay(tempRay);
end;

function RPlane.IntersectRay(const Ray : RRay) : RVector3;
var
  d : single;
begin
  d := Ray.Direction.Dot(Normal);
  // if parallel there is no intersection
  if d = 0.0 then exit(RVector3.ZERO);
  d := (Position - Ray.Origin).Dot(Normal) / d;
  Result := (d * Ray.Direction) + Ray.Origin;
end;

function RPlane.Normalize : RPlane;
begin
  Result.Normal := Normal.Normalize;
  Result.Position := Result.Normal.Dot(Result.Position) * Result.Normal;
end;

function RPlane.ParallelToRay(const Ray : RRay) : boolean;
begin
  Result := abs(Ray.Direction.Dot(Normal)) < SINGLE_ZERO_EPSILON;
end;

function RPlane.ProjectPointToPlane(const Point : RVector3) : RVector3;
begin
  Result := Point - (DistanceSigned(Point) * Normal);
end;

function RPlane.Reflect(const IncidentVector : RVector3) : RVector3;
begin
  Result := IncidentVector - 2 * Normal * IncidentVector.Dot(Normal);
end;

procedure RPlane.setNormal(const Value : RVector3);
begin
  FNormal := Value.Normalize;
end;

function RPlane.SimilarTo(const b : RPlane) : boolean;
begin
  Result := Position.SimilarTo(b.Position) and Normal.SimilarTo(b.Normal);
end;

function RPlane.ToCartesian : RVector4;
begin
  Result.x := Normal.x;
  Result.y := Normal.y;
  Result.z := Normal.z;
  Result.W := Normal.Dot(Position);
end;

function RPlane.Translate(const Offset : RVector3) : RPlane;
begin
  Result := self;
  Result.Position := Result.Position + Offset;
end;

{ RMinMaxBox }

function RAABB.Center : RVector3;
begin
  Result := Min.Lerp(Max, 0.5);
end;

function RAABB.ClampPoint(const Point : RVector3) : RVector3;
begin
  Result := Point.MinEachComponent(Max).MaxEachComponent(Min);
end;

function RAABB.DistanceToPoint(const Point : RVector3) : single;
begin
  if ContainsPoint(Point) then exit(0);
  Result := ClampPoint(Point).Distance(Point);
end;

procedure RAABB.Extend(const AABB : RAABB);
begin
  Extend(AABB.Min);
  Extend(AABB.Max);
end;

procedure RAABB.Extend(const Point : RVector3);
begin
  Min := Point.MinEachComponent(Min);
  Max := Point.MaxEachComponent(Max);
end;

constructor RAABB.Create(const Point : RVector3);
begin
  Create(Point, Point);
end;

constructor RAABB.CreateFromPositionSize(const Position, Size : RVector3);
begin
  Min := Position - (Size / 2);
  Max := Position + (Size / 2);
end;

constructor RAABB.CreateWrapping(const Sphere : RSphere);
begin
  self.Min := Sphere.Center - Sphere.Radius;
  self.Max := Sphere.Center + Sphere.Radius;
end;

constructor RAABB.CreateWrapping(Boxes : array of RAABB);
var
  i : integer;
begin
  if Length(Boxes) <= 0 then
  begin
    self.Min := RVector3.ZERO;
    self.Max := RVector3.ZERO;
  end
  else
  begin
    self := Boxes[0];
    for i := 1 to Length(Boxes) - 1 do
    begin
      self.Extend(Boxes[i]);
    end;
  end;
end;

function RAABB.getCorner(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < 8));
  case index of
    0 : Result := Min;
    1 : Result := RVector3.Create(Max.x, Min.y, Min.z);
    2 : Result := RVector3.Create(Min.x, Max.y, Min.z);
    3 : Result := RVector3.Create(Min.x, Min.y, Max.z);
    4 : Result := RVector3.Create(Max.x, Max.y, Min.z);
    5 : Result := RVector3.Create(Min.x, Max.y, Max.z);
    6 : Result := RVector3.Create(Max.x, Min.y, Max.z);
    7 : Result := Max;
  end;
end;

function RAABB.getNegativeVertex(const Normal : RVector3) : RVector3;
begin
  Result := Max;
  if (Normal.x >= 0) then Result.x := Min.x;
  if (Normal.y >= 0) then Result.y := Min.y;
  if (Normal.z >= 0) then Result.z := Min.z;
end;

function RAABB.getPositiveVertex(const Normal : RVector3) : RVector3;
begin
  Result := Min;
  if (Normal.x >= 0) then Result.x := Max.x;
  if (Normal.y >= 0) then Result.y := Max.y;
  if (Normal.z >= 0) then Result.z := Max.z;
end;

function RAABB.HalfExtents : RVector3;
begin
  Result := (Max - Min) / 2;
end;

function RAABB.IntersectAABBAABB(const AABB : RAABB) : boolean;
begin
  Result := (AABB.Center - Center).abs > AABB.HalfExtents + HalfExtents;
end;

function RAABB.IntersectionSetAABB(const AABB : RAABB) : RAABB;
begin
  Result.Min := self.Min.MaxEachComponent(AABB.Min);
  Result.Max := self.Max.MinEachComponent(AABB.Max);
end;

function RAABB.IntersectLine(const Line : RLine) : RLine;
var
  temp : RVector3;
begin
  Result := IntersectRay(RRay.Create(Line.Origin, Line.Direction));
  if ContainsPoint(Line.Origin) then
  begin
    temp := Result.Endpoint;
    Result.Origin := Line.Origin;
    Result.Endpoint := temp;
  end;
  if ContainsPoint(Line.Endpoint) then Result.Endpoint := Line.Endpoint;
end;

function RAABB.IntersectRay(const Ray : RRay) : RLine;
var
  t1, t2, t3, t4, t5, t6, tmin, tmax : single;
begin
  t1 := ((Min.x - Ray.Origin.x) / Ray.Direction.x);
  t2 := ((Max.x - Ray.Origin.x) / Ray.Direction.x);
  t3 := ((Min.y - Ray.Origin.y) / Ray.Direction.y);
  t4 := ((Max.y - Ray.Origin.y) / Ray.Direction.y);
  t5 := ((Min.z - Ray.Origin.z) / Ray.Direction.z);
  t6 := ((Max.z - Ray.Origin.z) / Ray.Direction.z);
  tmin := Math.Max(Math.Max(Math.Min(t1, t2), Math.Min(t3, t4)), Math.Min(t5, t6));
  tmax := Math.Min(Math.Min(Math.Max(t1, t2), Math.Max(t3, t4)), Math.Max(t5, t6));
  Result := RLine.CreateFromPoints(Ray.Origin + (Ray.Direction * tmin), Ray.Origin + (Ray.Direction * tmax));
end;

function RAABB.IntersectsRay(const Ray : RRay) : boolean;
var
  t1, t2, t3, t4, t5, t6, tmin, tmax : single;
begin
  t1 := ((Min.x - Ray.Origin.x) / Ray.Direction.x);
  t2 := ((Max.x - Ray.Origin.x) / Ray.Direction.x);
  t3 := ((Min.y - Ray.Origin.y) / Ray.Direction.y);
  t4 := ((Max.y - Ray.Origin.y) / Ray.Direction.y);
  t5 := ((Min.z - Ray.Origin.z) / Ray.Direction.z);
  t6 := ((Max.z - Ray.Origin.z) / Ray.Direction.z);
  tmin := Math.Max(Math.Max(Math.Min(t1, t2), Math.Min(t3, t4)), Math.Min(t5, t6));
  tmax := Math.Min(Math.Min(Math.Max(t1, t2), Math.Max(t3, t4)), Math.Max(t5, t6));
  Result := tmin <= tmax;
end;

function RAABB.Scale(const Scaler : RVector3) : RAABB;
var
  tmin, tmax, Center : RVector3;
begin
  tmin := Min;
  tmax := Max;
  Center := self.Center;
  Result.Min := (tmin - Center) * Scaler + Center;
  Result.Max := (tmax - Center) * Scaler + Center;
end;

function RAABB.Top : RVector3;
begin
  Result.x := (Min.x + Max.x) / 2;
  Result.y := Max.y;
  Result.z := (Min.z + Max.z) / 2;
end;

function RAABB.ToSphere : RSphere;
begin
  Result.Center := Center;
  Result.Radius := HalfExtents.MaxValue;
end;

function RAABB.Translate(const MoveVector : RVector3) : RAABB;
begin
  Result.Min := Min + MoveVector;
  Result.Max := Max + MoveVector;
end;

constructor RAABB.Create(const Min, Max : RVector3);
begin
  self.Min := Min;
  self.Max := Max;
  assert(Min <= Max, 'RAABB.CreateAABB: Min must be smaller than Max in each direction!')
end;

function RAABB.ContainsAABB(const AABB : RAABB) : boolean;
begin
  Result := (AABB.Min >= Min) and (AABB.Max <= Max);
end;

function RAABB.ContainsPoint(const Point : RVector3) : boolean;
begin
  Result := (Min.x <= Point.x) and (Point.x <= Max.x) and (Min.y <= Point.y) and (Point.y <= Max.y) and (Min.z <= Point.z) and (Point.z <= Max.z);
end;

{ RKugel }

function RSphere.ClampPointToSphere(const Point : RVector3) : RVector3;
begin
  Result := (Point - Center).SetLengthMax(Radius) + Center;
end;

constructor RSphere.CreateSphere(const Center : RVector3; Radius : single);
begin
  self.Center := Center;
  self.Radius := Radius;
end;

constructor RSphere.CreateWrapping(Spheres : array of RSphere);
var
  i : integer;
begin
  if Length(Spheres) <= 0 then
  begin
    self.Center := RVector3.ZERO;
    self.Radius := 0;
  end
  else
  begin
    self := Spheres[0];
    for i := 1 to Length(Spheres) - 1 do
    begin
      self.Center := self.Center + Spheres[i].Center;
    end;
    self.Center := self.Center / Length(Spheres);
    for i := 0 to Length(Spheres) - 1 do
    begin
      self.Radius := Math.Max(self.Radius, self.Center.Distance(Spheres[i].Center) + Spheres[i].Radius);
    end;
  end;
end;

function RSphere.IntersectSphereLine(const Line : RLine) : boolean;
var
  StreckeEnde, Ortho : RVector3;
  abstand : single;
begin
  StreckeEnde := Line.Endpoint;
  abstand := Line.DistanceToPoint(Center);
  Result := (abstand <= Radius)// Nächster Punkt in Kugel
    and ((sqr(Ortho.Distance(Line.Origin) + Ortho.Distance(StreckeEnde)) <= (Line.Direction.LengthSq) + 0.1)
    // Nächster Punkt zwischen Start und Ende
    or (Center.Distance(Line.Origin) <= Radius)
    // Startpunkt in Kugel
    or (Center.Distance(StreckeEnde) <= Radius));
  // EndPunkt in Kugel
end;

function RSphere.IntersectSphereRay(const Ray : RRay) : boolean;
begin
  Result := Ray.DistanceToPoint(Center) <= Radius;
end;

function RSphere.IntersectSphereSphere(const Sphere : RSphere) : boolean;
begin
  Result := Sphere.Center.Distance(Center) < Sphere.Radius + Radius;
end;

{ RRay }

procedure RRay.ClosestPointsParametersBetweenRays(const Ray : RRay; out u, v : single);
var
  between : RVector3;
  a, b, c, d, e, denom : single;
begin
  // from http://geomalgorithms.com/a07-_distance.html
  between := self.Origin - Ray.Origin;
  a := self.Direction.LengthSq; // always >= 0
  b := self.Direction.Dot(Ray.Direction);
  c := Ray.Direction.LengthSq; // always >= 0
  d := self.Direction.Dot(between);
  e := Ray.Direction.Dot(between);
  denom := a * c - sqr(b); // always >= 0

  // compute the line parameters of the two closest points
  if (abs(denom) < SINGLE_ZERO_EPSILON) then // the lines are almost parallel
  begin
    u := 0.0;
    if b > c then v := d / b
    else v := e / c; // use the largest denominator
  end
  else
  begin
    u := (b * e - c * d) / denom;
    v := (a * e - b * d) / denom;
  end;
end;

constructor RRay.Create(const Origin, Direction : RVector3);
begin
  self.Origin := Origin;
  self.FDirection := Direction.Normalize;
end;

function RRay.DistanceToPoint(const Point : RVector3) : single;
begin
  if Direction.isZeroVector then exit(Origin.Distance(Point));
  Result := Direction.Cross(Point - Origin).Length;
end;

function RRay.DistanceToRay(const Ray : RRay) : single;
var
  Kreuz : RVector3;
begin
  Kreuz := Direction.Cross(Ray.Direction);
  if (Kreuz.isZeroVector) then Result := 0
  else Result := abs((Ray.Origin - Origin).Dot(Kreuz)) / Kreuz.Length;
end;

function RRay.GetPoint(Distance : single) : RVector3;
begin
  Result := Origin + (Distance * Direction);
end;

function RRay.NearestPointToPoint(const Point : RVector3) : RVector3;
begin
  Result := Origin + (Direction * Direction.Dot(Point - Origin));
end;

function RRay.NearestPointToRay(const Ray : RRay) : RVector3;
var
  a, b, c, d, e, sc : single;
  w0 : RVector3;
begin
  // magic equation from http://geomalgorithms.com/a07-_distance.html
  w0 := self.Origin - Ray.Origin;
  a := self.Direction.LengthSq;
  b := self.Direction.Dot(Ray.Direction);
  c := Ray.Direction.LengthSq;
  d := self.Direction.Dot(w0);
  e := Ray.Direction.Dot(w0);
  sc := (a * c - sqr(b));
  // parallel
  if sc = 0 then exit(Ray.Origin);
  sc := (b * e - c * d) / sc;
  Result := Origin + (sc * Direction);
end;

procedure RRay.SetDirection(const Value : RVector3);
begin
  FDirection := Value.Normalize;
end;

{ RFrustum }

function RFrustum.ContainsAABB(const AABB : RAABB) : boolean;
var
  i, j : integer;
begin
  Result := True;
  j := 5;
  for i := 0 to j do
    if (Planes[i].DistanceSigned(AABB.getNegativeVertex(Planes[i].Normal)) < 0) then exit(False);
end;

constructor RFrustum.CreateFromViewProjectionMatrix(const View : RMatrix);
begin
  // Left Clipping Plane
  Planes[0] := RPlane.CreateFromKartesian(View._14 + View._11, View._24 + View._21, View._34 + View._31, View._44 + View._41);
  // Right Clipping Plane
  Planes[1] := RPlane.CreateFromKartesian(View._14 - View._11, View._24 - View._21, View._34 - View._31, View._44 - View._41);
  // Top Clipping Plane
  Planes[2] := RPlane.CreateFromKartesian(View._14 - View._12, View._24 - View._22, View._34 - View._32, View._44 - View._42);
  // Bottom Clipping Plane
  Planes[3] := RPlane.CreateFromKartesian(View._14 + View._12, View._24 + View._22, View._34 + View._32, View._44 + View._42);
  // Near Clipping Plane
  Planes[4] := RPlane.CreateFromKartesian(View._14 + View._13, View._24 + View._23, View._34 + View._33, View._44 + View._43);
  // Far Clipping Plane
  Planes[5] := RPlane.CreateFromKartesian(View._14 - View._13, View._24 - View._23, View._34 - View._33, View._44 - View._43);
end;

function RFrustum.Direction : RVector3;
begin
  Result := (FarCenter - NearCenter).Normalize;
end;

function RFrustum.DistanceToPlane(const Plane : RPlane) : single;
var
  dist : single;
  i : integer;
begin
  Result := Plane.DistanceSigned(Corners[0]);
  for i := 1 to CORNER_COUNT - 1 do
  begin
    dist := Plane.DistanceSigned(Corners[i]);
    // intersecting
    if sign(dist) <> sign(Result) then exit(0);
    if dist < 0 then Result := Max(Result, dist)
    else Result := Min(Result, dist);
  end;
end;

function RFrustum.DistanceToPoint(const Point : RVector3) : single;
var
  dist : single;
  i : integer;
begin
  Result := -Planes[0].DistanceSigned(Point);
  // first test planes, take maximal distance
  for i := 1 to Length(Planes) - 1 do
  begin
    dist := -Planes[i].DistanceSigned(Point);
    Result := Max(Result, dist);
  end;
  // if point is at the edges take minimal distance to them, automatically doing corner case as they are part in them
  for i := 0 to LINE_COUNT - 1 do
      Result := Min(Result, Lines[i].DistanceToPoint(Point));
end;

function RFrustum.FarCenter : RVector3;
begin
  Result := (Corners[4] + Corners[5] + Corners[6] + Corners[7]) / 4;
end;

function RFrustum.FitNearFarToAABB(const AABB : RAABB) : RFrustum;
var
  NearPoint, FarPoint : RVector3;
  tAABB : RAABB;
begin
  Result := self;
  tAABB := self.IntersectionSetAABB(AABB);
  NearPoint := tAABB.getPositiveVertex(Direction);
  FarPoint := tAABB.getNegativeVertex(Direction);
  if NearPlane.DistanceSigned(NearPoint) > 0 then Result.NearPlane := RPlane.CreateFromNormal(NearPlane.Position + (NearPlane.Normal * NearPlane.DistanceSigned(NearPoint)), NearPlane.Normal);
  if FarPlane.DistanceSigned(FarPoint) > 0 then Result.FarPlane := RPlane.CreateFromNormal(FarPlane.Position + (FarPlane.Normal * FarPlane.DistanceSigned(FarPoint)), FarPlane.Normal);
end;

function RFrustum.getCorner(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < 8));
  // Planes[0:Left, 1:Right,2:Top,3:Bottom,4:Near,5:Far]
  case index of
    0 : Result := Planes[4].Intersect3Planes(Planes[0], Planes[2]);
    1 : Result := Planes[4].Intersect3Planes(Planes[2], Planes[1]);
    2 : Result := Planes[4].Intersect3Planes(Planes[1], Planes[3]);
    3 : Result := Planes[4].Intersect3Planes(Planes[3], Planes[0]);
    4 : Result := Planes[5].Intersect3Planes(Planes[0], Planes[2]);
    5 : Result := Planes[5].Intersect3Planes(Planes[2], Planes[1]);
    6 : Result := Planes[5].Intersect3Planes(Planes[1], Planes[3]);
    7 : Result := Planes[5].Intersect3Planes(Planes[3], Planes[0]);
  end;
end;

function RFrustum.getFarPlane : RPlane;
begin
  Result := Planes[5];
end;

function RFrustum.getLine(index : integer) : RLine;
var
  target : RVector3;
begin
  assert((index >= 0) and (index < 4));
  target := Corners[index + 4];
  Result.Origin := Corners[index];
  Result.Direction := target - Result.Origin;
end;

function RFrustum.getNearPlane : RPlane;
begin
  Result := Planes[4];
end;

function RFrustum.getRay(index : integer) : RRay;
var
  Line : RLine;
begin
  Line := Lines[index];
  Result := RRay.Create(Line.Origin, Line.Direction);
end;

function RFrustum.IntersectAABB(const AABB : RAABB; OmitNearFar : boolean) : boolean;
var
  i, j : integer;
begin
  if OmitNearFar then j := 3
  else j := 5;
  for i := 0 to j do
    if (Planes[i].DistanceSigned(AABB.getPositiveVertex(Planes[i].Normal)) < 0) then exit(False);
  Result := True;
end;

function RFrustum.IntersectionSetAABB(const AABB : RAABB) : RAABB;
var
  Line : RLine;
  i : integer;
begin
  Line := AABB.IntersectLine(Lines[0]);
  Result := RAABB.Create(Line.Origin, Line.Origin);
  Result.Extend(Line.Endpoint);
  for i := 1 to 3 do
  begin
    Line := AABB.IntersectLine(Lines[i]);
    Result.Extend(Line.Origin);
    Result.Extend(Line.Endpoint);
  end;
  Result := AABB.IntersectionSetAABB(Result);
end;

function RFrustum.IntersectionSetAABBRaw(const AABB : RAABB) : TArray<RVector3>;
const
  RAY_COUNT = 10;
var
  x, y, i : integer;
  sx, sy : single;
  Line : RLine;
begin
  SetLength(Result, RAY_COUNT * RAY_COUNT * 2);
  i := 0;
  for x := 0 to RAY_COUNT - 1 do
    for y := 0 to RAY_COUNT - 1 do
    begin
      assert(i + 1 < Length(Result));
      sx := x / (RAY_COUNT - 1);
      sy := y / (RAY_COUNT - 1);
      Line := Lines[0].Lerp(Lines[1], sx).Lerp(Lines[2].Lerp(Lines[3], 1 - sx), sy);
      if not AABB.IntersectsRay(Line.ToRay) then
      begin
        Result[i] := RVector3.EMPTY;
        Result[i + 1] := RVector3.EMPTY;
      end
      else
      begin
        Line := AABB.IntersectLine(Line);
        Result[i] := Line.Origin;
        Result[i + 1] := Line.Endpoint;
      end;
      inc(i, 2);
    end;
end;

function RFrustum.IntersectSphere(const Sphere : RSphere;
  OmitNearFar :
  boolean) : boolean;
var
  i, j : integer;
begin
  if OmitNearFar then j := 3
  else j := 5;
  for i := 0 to j do
    if Planes[i].DistanceSigned(Sphere.Center) <= -Sphere.Radius then exit(False);
  Result := True;
end;

function RFrustum.NearCenter : RVector3;
begin
  Result := (Corners[0] + Corners[1] + Corners[2] + Corners[3]) / 4;
end;

procedure RFrustum.setFarPlane(const Value : RPlane);
begin
  Planes[5] := Value;
end;

procedure RFrustum.setNearPlane(const Value : RPlane);
begin
  Planes[4] := Value;
end;

{ HIntersection }

class function HIntersection.AABBFrustum(const AABB : RAABB; const Frustum : RFrustum) : boolean;
begin
  Result := Frustum.IntersectAABB(AABB);
end;

class function HIntersection.SphereFrustum(const Sphere : RSphere; const Frustum : RFrustum) : boolean;
begin
  Result := Frustum.IntersectSphere(Sphere);
end;

{ RQuad }

constructor RQuad.CreateFromPoints(const Point1, Point2, Point3 : RVector3);
begin
  self.Vertex1 := Point1;
  self.Vertex2 := Point2;
  self.Vertex3 := Point3;
end;

function RQuad.GetNormal : RVector3;
begin
  Result := (Vertices[1] - Vertices[0]).Cross(Vertices[2] - Vertices[0]).Normalize;
end;

function RQuad.getVertex4 : RVector3;
begin
  Result := Vertex2 + Vertex3 - Vertex1;
end;

function RQuad.IntersectLineQuad(const Line : RLine) : boolean;
begin
  Result := RTriangle.Create(Vertex1, Vertex2, Vertex3).IntersectLineTriangle(Line) or RTriangle.Create(Vertex2, Vertex3, Vertex4).IntersectLineTriangle(Line);
end;

function RQuad.IntersectQuadQuad(const Quad : RQuad) : boolean;
begin
  raise ENotImplemented.Create('RQuad.IntersectQuadQuad');
  { Result := SchnittStreckeViereck(GibStrecke(Viereck1[0], Viereck1[1] - Viereck1[0]), Viereck2) or SchnittStreckeViereck(GibStrecke(Viereck1[0], Viereck1[2] - Viereck1[0]), Viereck2) or SchnittStreckeViereck(GibStrecke(Viereck1[3], Viereck1[1] - Viereck1[3]), Viereck2) or SchnittStreckeViereck(GibStrecke(Viereck1[3], (Viereck1[2] - Viereck1[3])), Viereck2) or SchnittStreckeViereck(GibStrecke(Viereck2[0], (Viereck2[1] - Viereck2[0])), Viereck1)
   or SchnittStreckeViereck(GibStrecke(Viereck2[0], (Viereck2[2] - Viereck2[0])), Viereck1) or SchnittStreckeViereck(GibStrecke(Viereck2[3], (Viereck2[1] - Viereck2[3])), Viereck1) or SchnittStreckeViereck(GibStrecke(Viereck2[3], (Viereck2[2] - Viereck2[3])), Viereck1); }
end;

function RQuad.IntersectRayQuad(const Ray : RRay) : boolean;
begin
  Result := RTriangle.Create(Vertex1, Vertex2, Vertex3).IntersectRayTriangle(Ray) or RTriangle.Create(Vertex2, Vertex3, Vertex4).IntersectRayTriangle(Ray);
end;

function RQuad.IntersectSphereQuad(const Sphere : RSphere) : boolean;
{ var
 EbenenRichtungen : array [0 .. 1] of RVector3;
 Schnittpunkt, Ortho : RVector3; }
begin
  raise ENotImplemented.Create('RQuad.IntersectSphereQuad');
  { Result := False;
   // Kugel überhaupt in der nötigen Nähe der Ebene
   if AbstandEbenePunkt(Viereck[0], Viereck[1], Viereck[2], Kugel.Center) <= Kugel.Radius then
   begin
   // 1.Test
   // Kugel befindet sich im Inneren des Quaders was das Viereck ins unendliche gezogen ausmacht
   // (Orthogonale der Ebene an die KugelMitte schneidet das Viereck)
   // 2-5.Test
   // Einer der Kanten des Vierecks schneidet die Kugel
   EbenenRichtungen[0] := Viereck[1] - Viereck[0];
   EbenenRichtungen[1] := Viereck[2] - Viereck[0];
   AbstandEbenePunkt(Viereck[1], Viereck[2], Viereck[0], Kugel.Center, Schnittpunkt);
   // Wenn Ortho der Nullvektor ist kann es Probleme geben
   // wegen unwahrscheinlichkeit des auftretens weggelassen
   Ortho := Schnittpunkt - Kugel.Center;
   Result := SchnittStreckeViereck(GibStrecke(Kugel.Center, Ortho), Viereck) or SchnittStreckeKugel(GibStrecke(Viereck[0], EbenenRichtungen[0]), Kugel) or SchnittStreckeKugel(GibStrecke(Viereck[0], EbenenRichtungen[1]), Kugel) or SchnittStreckeKugel(GibStrecke(Viereck[3], Viereck[1] - Viereck[3]), Kugel) or SchnittStreckeKugel(GibStrecke(Viereck[3], Viereck[2] - Viereck[3]), Kugel);
   end; }
end;

{ RTriangle }

function RTriangle.ContainsPoint(const Point : RVector3) : boolean;
var
  barycentric : RVector3;
begin
  // check if in plane of triangle
  if abs(GetNormal.Dot(Point - Vertex1)) > COLLISIONEPSILON then exit(False);
  // check if in triangle
  barycentric := PointToBaryCentric(Point);
  Result := InRange(barycentric.x, 0, 1) and InRange(barycentric.y, 0, 1) and InRange(barycentric.z, 0, 1) and (abs(barycentric.Sum - 1) < COLLISIONEPSILON);
end;

constructor RTriangle.Create(const Point1, Point2, Point3 : RVector3);
begin
  self.Vertex1 := Point1;
  self.Vertex2 := Point2;
  self.Vertex3 := Point3;
end;

function RTriangle.GetNormal : RVector3;
begin
  Result := (Vertex2 - Vertex1).Cross(Vertex3 - Vertex1).Normalize;
end;

function RTriangle.GetPlane : RPlane;
begin
  Result := RPlane.CreateFromPoints(Vertex1, Vertex2, Vertex3);
end;

function RTriangle.IntersectLineTriangle(const Line : RLine) : boolean;
begin
  raise ENotImplemented.Create('RTriangle.IntersectLineTriangle');
end;

function RTriangle.IntersectRayTriangle(const Ray : RRay) : boolean;
var
  Plane : RPlane;
begin
  Plane := GetPlane;
  Result := not Plane.ParallelToRay(Ray) and ContainsPoint(Plane.IntersectRay(Ray));
end;

function RTriangle.PointToBaryCentric(const Point : RVector3) : RVector3;
var
  tri1, tri2, tri3 : RVector3;
  d00, d01, d11, d20, d21, denom : single;
begin
  tri1 := Vertex2 - Vertex1;
  tri2 := Vertex3 - Vertex1;
  tri3 := Point - Vertex1;
  d00 := tri1.Dot(tri1);
  d01 := tri1.Dot(tri2);
  d11 := tri2.Dot(tri2);
  d20 := tri3.Dot(tri1);
  d21 := tri3.Dot(tri2);
  denom := d00 * d11 - d01 * d01;
  if denom = 0 then exit(RVector3.Create(1, 0, 0));
  Result.y := (d11 * d20 - d01 * d21) / denom;
  Result.z := (d00 * d21 - d01 * d20) / denom;
  Result.x := 1.0 - Result.x - Result.y;
end;

{ RLine }

function RLine.ClosestPointToRay(const Ray : RRay) : RVector3;
var
  u, v : single;
begin
  ToRay.ClosestPointsParametersBetweenRays(Ray, u, v);
  if u <= 0 then Result := Ray.NearestPointToPoint(Origin)
  else if u >= Direction.Length then Result := Ray.NearestPointToPoint(Endpoint)
  else Result := Ray.Origin + (Ray.Direction * v);
end;

constructor RLine.Create(const Origin, Direction : RVector3);
begin
  self.Origin := Origin;
  self.Direction := Direction;
end;

constructor RLine.CreateFromPoints(const Startpoint, Endpoint : RVector3);
begin
  Create(Startpoint, Endpoint - Startpoint);
end;

function RLine.DistanceToLine(const Line : RLine) : single;
var
  between : RVector3;
  a, b, c, d, e, denom : single;
  sc, SN, sD, tc, tN, tD : single;
begin
  // from http://geomalgorithms.com/a07-_distance.html
  between := Origin - Line.Origin;
  a := Direction.LengthSq; // always >= 0
  b := Direction.Dot(Line.Direction);
  c := Line.Direction.LengthSq; // always >= 0
  d := Direction.Dot(between);
  e := Line.Direction.Dot(between);
  denom := a * c - b * b; // always >= 0
  sD := denom;
  tD := denom;
  // compute the line parameters of the two closest points
  if (denom < SINGLE_ZERO_EPSILON) then // the lines are almost parallel
  begin
    SN := 0.0; // force using point P0 on segment S1
    sD := 1.0; // to prevent possible division by 0.0 later
    tN := e;
    tD := c;
  end
  else // get the closest points on the infinite lines
  begin
    SN := (b * e - c * d);
    tN := (a * e - b * d);
    if (SN < 0.0) then // sc < 0 => the s=0 edge is visible
    begin
      SN := 0.0;
      tN := e;
      tD := c;
    end
    else if (SN > sD) then // sc > 1  => the s=1 edge is visible
    begin
      SN := sD;
      tN := e + b;
      tD := c;
    end
  end;

  if (tN < 0.0) then // tc < 0 => the t=0 edge is visible
  begin
    tN := 0.0;
    // recompute sc for this edge
    if (-d < 0.0) then SN := 0.0
    else if (-d > a) then SN := sD
    else
    begin
      SN := -d;
      sD := a;
    end;
  end
  else if (tN > tD) then // tc > 1  => the t=1 edge is visible
  begin
    tN := tD;
    // recompute sc for this edge
    if ((-d + b) < 0.0) then SN := 0
    else if ((-d + b) > a) then SN := sD
    else
    begin
      SN := (-d + b);
      sD := a;
    end;
  end;
  // finally do the division to get sc and tc
  if abs(SN) < SINGLE_ZERO_EPSILON then sc := 0.0
  else sc := SN / sD;
  if abs(tN) < SINGLE_ZERO_EPSILON then tc := 0.0
  else tc := tN / tD;

  // get the difference of the two closest points
  Result := (between + (sc * Direction) - (tc * Line.Direction)).Length; // =  S1(sc) - S2(tc)
end;

function RLine.DistanceToPoint(const Point : RVector3) : single;
var
  s : single;
begin
  if Direction.isZeroVector then exit(Origin.Distance(Point));
  s := (Point - Origin).Dot(Direction.Normalize);
  if s < 0 then Result := Origin.Distance(Point)
  else if s > 1 then Result := Endpoint.Distance(Point)
  else Result := Direction.Normalize.Cross(Point - Origin).Length;
end;

function RLine.DistanceToRay(const Ray : RRay) : single;
var
  u, v : single;
begin
  ToRay.ClosestPointsParametersBetweenRays(Ray, u, v);
  if u <= 0 then Result := Ray.DistanceToPoint(Origin)
  else if u >= Direction.Length then Result := Ray.DistanceToPoint(Endpoint)
  else Result := (Origin + (Direction.Normalize * u)).Distance(Ray.Origin + (Ray.Direction * v));
end;

function RLine.getEndpoint : RVector3;
begin
  Result := Origin + Direction;
end;

function RLine.Lerp(const b : RLine; s : single) : RLine;
begin
  Result.Origin := Origin.Lerp(b.Origin, s);
  Result.Endpoint := Endpoint.Lerp(b.Endpoint, s);
end;

procedure RLine.setEndpoint(const Value : RVector3);
begin
  Direction := Value - Origin;
end;

function RLine.ToRay : RRay;
begin
  Result := RRay.Create(Origin, Direction);
end;

function RLine.Translate(const MoveVector : RVector3) : RLine;
begin
  Result.Origin := Origin + MoveVector;
  Result.Endpoint := Endpoint + MoveVector;
end;

{ RCylinder }

constructor RCylinder.Create(const Start, Direction : RVector3;
  Radius, Height : single);
begin
  self.Start := Start;
  self.Direction := Direction.Normalize;
  self.Radius := Radius;
  self.Height := Height;
end;

function RCylinder.getEndpoint : RVector3;
begin
  Result := Start + (Direction * Height);
end;

function RCylinder.IntersectCylinderLine(const Line : RLine) : boolean;
begin
  raise ENotImplemented.Create('RCylinder.IntersectCylinderLine');
end;

function RCylinder.IntersectCylinderSphere(const Sphere : RSphere) : boolean;
{ var
 NPunkt, temp : RVector3;
 Laenge, abstand, s : single; }
begin
  raise ENotImplemented.Create('RCylinder.IntersectCylinderSphere');
  { Result := False;
   // überhaupt in der Nähe? (unendlich langer Zylinder)
   abstand := AbstandGeradePunkt(Zylinder.Start, Zylinder.Direction, Kugel.Center, NPunkt);
   if abstand <= Zylinder.Radius + Kugel.Radius then
   begin
   // Kugelmitte im undendlichen Zylinder
   if abstand <= Zylinder.Radius then
   begin
   // vor oder hinter dem Startpunkt?
   temp := NPunkt - Zylinder.Start;
   abstand := Zylinder.Start.Distance(NPunkt);
   if (temp.Dot(Zylinder.Direction)) > 0 then
   begin
   // Vor
   Laenge := (Zylinder.Direction).Length;
   Result := abstand <= Laenge + Kugel.Radius;
   end
   else
   begin
   // Hinter
   Result := abstand <= Kugel.Radius;
   end;
   end
   // Kugelmitte außerhalb des unendlichen Zylinders
   else
   begin
   // Schnittpunkt von Zylinderhülle mit Kugelhülle s ist dann die Entfernung in der Kugel
   s := abstand - Zylinder.Radius;
   s := sqrt(Kugel.Radius * Kugel.Radius - s * s);
   // vor oder hinter dem Startpunkt?
   temp := NPunkt - Zylinder.Start;
   abstand := Zylinder.Start.Distance(NPunkt);
   if (temp.Dot(Zylinder.Direction)) > 0 then
   begin
   // Vor
   Laenge := Zylinder.Direction.Length;
   Result := abstand <= Laenge + s;
   end
   else
   begin
   // Hinter
   Result := abstand <= s;
   end;
   end;
   end; }
end;

procedure RCylinder.setEndpoint(
  const
  Value :
  RVector3);
begin
  Direction := Value - Start;
  Height := Direction.Length;
  Direction.Normalize;
end;

{ ROBB }

function ROBB.ContainsPoint(const Point : RVector3) : boolean;
begin
  raise ENotImplemented.Create('Doesn''t work properly.');
  Result := (RMatrix.CreateBase(Left, Up, Front) * (Point - Position)).abs <= Size;
end;

constructor ROBB.Create(const Position, Front, Up, Size : RVector3);
begin
  self.Position := Position;
  self.Front := Front.Normalize;
  self.Up := Up.Normalize;
  self.Up := -self.Front.Cross(Left).Normalize;
  self.Size := Size.abs;
end;

procedure ROBB.Extend(const Point : RVector3);
var
  tPoint : RVector3;
begin
  tPoint := Point - Position;
  Size.x := Max(Size.x, abs(Left.Dot(tPoint)));
  Size.y := Max(Size.y, abs(Up.Dot(tPoint)));
  Size.z := Max(Size.z, abs(Front.Dot(tPoint)));
end;

constructor ROBB.CreateWrappedAroundAABB(const AABB : RAABB; const Front, Up : RVector3);
var
  i : integer;
  corner : RVector3;
begin
  self.Position := AABB.Center;
  self.Front := Front.Normalize;
  self.Up := Up.Orthogonalize(Front).Normalize;
  self.Size := RVector3.ZERO;
  for i := 0 to AABB.CORNERCOUNT - 1 do
  begin
    corner := AABB.getCorner(i);
    ExtendOptimal(corner);
  end;
end;

constructor ROBB.CreateWrappedAroundFrustum(const Frustum : RFrustum; const Front, Up : RVector3);
var
  i : integer;
  corner : RVector3;
begin
  self.Position := Frustum.getCorner(0);
  self.Front := Front.Normalize;
  self.Up := Up.Orthogonalize(Front).Normalize;
  self.Size := RVector3.ZERO;
  for i := 1 to 7 do
  begin
    corner := Frustum.getCorner(i);
    ExtendOptimal(corner);
  end;
end;

procedure ROBB.Extend(const AABB : RAABB);
var
  i : integer;
begin
  for i := 0 to 7 do Extend(AABB.Corners[i]);
end;

procedure ROBB.ExtendOptimal(Point : RVector3);
var
  ProjectedPoint : RVector3;
begin
  Point := Point - Position;
  ProjectedPoint := RVector3.Create(Left.Dot(Point), Up.Dot(Point), Front.Dot(Point));
  if Size.x < abs(ProjectedPoint.x) then
  begin
    ProjectedPoint.x := ProjectedPoint.x - (Size.x * sign(ProjectedPoint.x));
    Position := Position + ((ProjectedPoint.x / 2) * Left);
    Size.x := Size.x + (abs(ProjectedPoint.x) / 2);
  end;
  if Size.y < abs(ProjectedPoint.y) then
  begin
    ProjectedPoint.y := ProjectedPoint.y - (Size.y * sign(ProjectedPoint.y));
    Position := Position + ((ProjectedPoint.y / 2) * Up);
    Size.y := Size.y + (abs(ProjectedPoint.y) / 2);
  end;
  if Size.z < abs(ProjectedPoint.z) then
  begin
    ProjectedPoint.z := ProjectedPoint.z - (Size.z * sign(ProjectedPoint.z));
    Position := Position + ((ProjectedPoint.z / 2) * Front);
    Size.z := Size.z + (abs(ProjectedPoint.z) / 2);
  end;
end;

function ROBB.FitNearFarToAABB(const AABB : RAABB) : ROBB;
const
  RAY_COUNT = 10;
var
  Line : RLine;
  bestMin, bestMax, sx, sy : single;
  midPlane : RPlane;
  x, y : integer;
  Ray : RRay;
begin
  // generates n rays and test for minimal and maximal intersections with the AABB, not really good but I'm on the end of my wisdom
  Result := self;
  bestMin := NaN;
  bestMax := NaN;
  midPlane := RPlane.CreateFromNormal(Position, Front);
  for x := 0 to RAY_COUNT - 1 do
    for y := 0 to RAY_COUNT - 1 do
    begin
      sx := x / (RAY_COUNT - 1);
      sy := y / (RAY_COUNT - 1);
      Ray := RRay.Create(Rays[0].Origin.Lerp(Rays[1].Origin, sx).Lerp(Rays[2].Origin.Lerp(Rays[3].Origin, sx), sy), Front);
      if AABB.IntersectsRay(Ray) then
      begin
        Line := AABB.IntersectRay(Ray);
        if isNaN(bestMin) or (bestMin > midPlane.DistanceSigned(Line.Origin)) then bestMin := midPlane.DistanceSigned(Line.Origin);
        if isNaN(bestMax) or (bestMax < midPlane.DistanceSigned(Line.Endpoint)) then bestMax := midPlane.DistanceSigned(Line.Endpoint);
      end;
    end;
  if isNaN(bestMin) then exit(self);
  Result.Size.z := abs(bestMax - bestMin) / 2;
  Result.Position := Position + (Front * (bestMax - Result.Size.z));
end;

function ROBB.getCorner(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < 8));
  case index of
    0 : Result := Position - (Front * Size.z) + (Left * Size.x) + (Up * Size.y);
    1 : Result := Position - (Front * Size.z) - (Left * Size.x) + (Up * Size.y);
    2 : Result := Position - (Front * Size.z) - (Left * Size.x) - (Up * Size.y);
    3 : Result := Position - (Front * Size.z) + (Left * Size.x) - (Up * Size.y);
    4 : Result := Position + (Front * Size.z) + (Left * Size.x) + (Up * Size.y);
    5 : Result := Position + (Front * Size.z) - (Left * Size.x) + (Up * Size.y);
    6 : Result := Position + (Front * Size.z) - (Left * Size.x) - (Up * Size.y);
    7 : Result := Position + (Front * Size.z) + (Left * Size.x) - (Up * Size.y);
  end;
end;

function ROBB.GetInterval(const Axis : RVector3) : RVector2;
begin
  raise ENotImplemented.Create('ROBB.GetInterval');
end;

function ROBB.getLeft : RVector3;
begin
  Result := Front.Cross(Up).Normalize;
end;

function ROBB.getLine(index : integer) : RLine;
var
  target : RVector3;
begin
  assert((index >= 0) and (index < 4));
  target := Corners[index + 4];
  Result.Origin := Corners[index];
  Result.Direction := target - Result.Origin;
end;

function ROBB.getRay(index : integer) : RRay;
begin
  Result := Lines[index].ToRay;
end;

function ROBB.GetWrappingAABB : RAABB;
var
  xa, xb, ya, yb, za, zb : RVector3;
begin
  xa := Left * (-Size.x / 2);
  xb := Left * (Size.x / 2);

  ya := Up * (-Size.y / 2);
  yb := Up * (Size.y / 2);

  za := Front * (-Size.z / 2);
  zb := Front * (Size.z / 2);

  Result := RAABB.Create(
    (xa.MinEachComponent(xb) + ya.MinEachComponent(yb) + za.MinEachComponent(zb)) + Position,
    (xa.MaxEachComponent(xb) + ya.MaxEachComponent(yb) + za.MaxEachComponent(zb)) + Position
    );
end;

function ROBB.IntersectOBBOBB(const OBB : ROBB) : boolean;
begin
  raise ENotImplemented.Create('Fehlermeldung');
  Result := False;
  GetInterval(OBB.Position); // delete, only for supressing warning
end;

function ROBB.NearestPointToPoint(const Point : RVector3) : RVector3;
begin
  raise ENotImplemented.Create('ROBB.GetInterval');
  // Result:=Position+ (Point-Position).Dot(Front);
end;

{ RCapsule }

constructor RCapsule.Create(const Origin, Endpoint : RVector3; Radius : single);
begin
  self.Origin := Origin;
  self.Endpoint := Endpoint;
  self.Radius := Radius;
end;

function RCapsule.DistanceToPoint(const Point : RVector3) : single;
begin
  Result := Max(0, ToLine.DistanceToPoint(Point) - Radius);
end;

constructor RCapsule.Create(const Origin, Direction : RVector3; Radius, Height : single);
begin
  self.Origin := Origin;
  self.Direction := Direction;
  self.Radius := Radius;
  self.Height := Height;
end;

function RCapsule.getEndpoint : RVector3;
begin
  Result := Origin + (Direction * Height);
end;

function RCapsule.IntersectCapsuleLine(const Line : RLine; IntersectionSet : PLine) : boolean;
begin
  Result := ToLine.DistanceToLine(Line) <= Radius;
  if IntersectionSet <> nil then
  begin
    raise ENotImplemented.Create('RCapsule.IntersectCapsuleLine: IntersectionSet not implemented!');
  end;
end;

function RCapsule.IntersectCapsuleRay(const Ray : RRay; IntersectionSet : PLine) : boolean;
begin
  Result := ToLine.DistanceToRay(Ray) <= Radius;
  if IntersectionSet <> nil then
  begin
    raise ENotImplemented.Create('RCapsule.IntersectCapsuleLine: IntersectionSet not implemented!');
  end;
end;

function RCapsule.IntersectCapsuleSphere(const Sphere : RSphere) : boolean;
begin
  Result := ToLine.DistanceToPoint(Sphere.Center) <= Radius + Sphere.Radius;
end;

procedure RCapsule.SetDirection(const Value : RVector3);
begin
  FDirection := Value.Normalize;
end;

procedure RCapsule.setEndpoint(const Value : RVector3);
begin
  Height := Origin.Distance(Value);
  Direction := Value - Origin;
end;

function RCapsule.ToCylinder : RCylinder;
begin
  Result := RCylinder.Create(Origin, Direction, Radius, Height);
end;

function RCapsule.ToLine : RLine;
begin
  Result := RLine.CreateFromPoints(Origin, Endpoint)
end;

end.
