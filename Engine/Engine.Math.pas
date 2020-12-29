unit Engine.Math;

interface

uses
  Hash,
  Math,
  Types,
  SysUtils,
  RTTI;

const
  // Big primenumbers, e.g. used for hashcomputation of RVector3
  PRIMENUMBERS : array [0 .. 2] of Integer = (73856093, 19349663, 83492791);

  SINGLE_ZERO_EPSILON = 1E-7;

type
  // supress warning for constructors with different names but identic parameters as not working under c++
  {$WARN DUPLICATE_CTOR_DTOR OFF}

  // Mathunit full RTTI for saving data
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  /// <summary> A generic Tuple </summary>
  RTuple<T, U> = record
    a : T;
    b : U;
    constructor Create(a : T; b : U);
    function SetA(const newA : T) : RTuple<T, U>;
    function SetB(const newB : U) : RTuple<T, U>;
  end;

  EnumAxis = (aX, aY, aZ, aW);

  half = record
    Value : Word;
    class function FloatToHalf(Float : Single) : half; static;
    class function HalfToFloat(Value : half) : Single; static;
    class operator implicit(Float : Single) : half;
  end;

  RVector4Half = record
    X, Y, Z, W : half;
  end;

  /// <summary> A range type for integer.</summary>
  RIntRange = record
    public
      Minimum, Maximum : Integer;
      function IsInvalid : boolean;
      function Size : Integer;
      constructor Create(const Minimum, Maximum : Integer);
      class function CreateInvalid : RIntRange; static;
      /// <summary> Returns a range with maximum possible range</summary>
      class function MaxRange : RIntRange; static;
      procedure Extend(Value : Integer); overload;
      procedure Extend(RangeStart, RangeEnd : Integer); overload;
      /// <summary> Returns True if Minimum<= T <=b</summary>
      function inRange(const Value : Integer) : boolean;
      function EnsureRange(const Value : Integer) : Integer;
      class operator implicit(const Value : RIntRange) : string;
  end;

  PRVector2 = ^RVector2;

  RVector2 = packed record
    private
      function GetElement(Index : Integer) : Single; inline;
      procedure SetElement(Index : Integer; const Value : Single); inline;
    public
      constructor Create(X, Y : Single); overload;
      constructor Create(XY : Single); overload;
      class function ZERO : RVector2; static;
      class function ONE : RVector2; static;
      class function UNITX : RVector2; static;
      class function UNITY : RVector2; static;
      class function EMPTY : RVector2; static;

      function ToIniString : string;
      constructor CreateFromIniString(const Value : string);

      function Rotate(Angle : Single) : RVector2;
      function MaxAbsValue : Single;
      procedure InRotieren(Winkel : Single);
      function IsZeroVector : boolean;
      function Normalize : RVector2;
      function IsEmpty : boolean;
      function Lerp(const Target : RVector2; s : Single) : RVector2;
      function SLerp(const Target, Center : RVector2; s : Single) : RVector2;
      function CosLerp(const Target : RVector2; s : Single) : RVector2;
      procedure InNormalisieren;
      /// <summary> Returns a normalized direction from this to target. </summary>
      function DirectionTo(const Target : RVector2) : RVector2;
      function Frac : RVector2;
      function Abs : RVector2;
      function Sign : RVector2;
      function Negate(Dim : Integer) : RVector2;
      function SetLength(Length : Single) : RVector2;
      /// <summary> Set the length to Length if its greater then length. </summary>
      function SetLengthMax(Length : Single) : RVector2;
      /// <summary> Returns the distance between this vector and b </summary>
      function Distance(const b : RVector2) : Single;
      /// <summary> Returns the distance squared between this vector and b </summary>
      function DistanceSq(const b : RVector2) : Single;
      /// <summary> Returns the manhattan distance between this vector and b </summary>
      function DistanceManhattan(const b : RVector2) : Single;
      /// <summary> Returns the closest point to this. Either a or b. </summary>
      function Closest(const a, b : RVector2) : RVector2;
      /// <summary> Make this vector orthogonal to b with the Gram-Schmidt-Method. </summary>
      function Orthogonalize(const b : RVector2) : RVector2;
      class function Random(Jitter : Single) : RVector2; static;
      function Length : Single;
      function LengthSq : Single;
      function LengthManhattan : Single;
      function Cross(const a : RVector2) : Single;
      function Dot(const a : RVector2) : Single;
      /// <summary> Returns the inner angle between this and the given vector. Result in [0,PI]. </summary>
      function InnerAngle(const a : RVector2) : Single;
      /// <summary> Returns the inner angle between this and the given vector. CW angles are negative. Result in [-PI,PI]. </summary>
      function InnerAngleOriented(const a : RVector2) : Single;
      function Mirror(const Mirror : RVector2) : RVector2;
      function SimilarTo(const b : RVector2; Epsilon : Single = SINGLE_ZERO_EPSILON) : boolean;
      function SetX(Wert : Single) : RVector2;
      function SetY(Wert : Single) : RVector2;
      function MaxValue() : Single;
      function MinValue() : Single;
      /// <summary> Returns the left orthogonal vector to the vector. (rotated by 90° ccw) </summary>
      function GetOrthogonal : RVector2;
      function GetHashValue() : Integer;
      /// <summary> Swizzles. n is negate </summary>
      function nXY : RVector2;
      function XnY : RVector2;
      function nXnY : RVector2;
      function YZ : RVector2;
      /// <summary> Returns a random point in the circle with specified radius. If radius < 0 it returns
      /// points on the circle surface with radius abs(radius).</summary>
      class function GetRandomPointInCircle(Radius : Single) : RVector2; static;
      function Min(b : Single) : RVector2; overload;
      function Max(b : Single) : RVector2; overload;
      function Min(const b : RVector2) : RVector2; overload;
      function Max(const b : RVector2) : RVector2; overload;
      /// <summary> Return self moved to the MaxDistance of if greater than. </summary>
      function ClampDistance(const b : RVector2; MaxDistance : Single) : RVector2;

      property Elements[index : Integer] : Single read GetElement write SetElement; default;

      class function Min(const a, b : RVector2) : RVector2; overload; static;
      class function Max(const a, b : RVector2) : RVector2; overload; static;
      /// <summary> ensures that each component of Minimum <= Vector <= Maximum </summary>
      class function Clamp(const Vector, Minimum, Maximum : RVector2) : RVector2; static;
      class operator multiply(const a : RVector2; b : Single) : RVector2;
      class operator multiply(a : Single; const b : RVector2) : RVector2;
      class operator divide(const a : RVector2; b : Single) : RVector2;
      class operator divide(a : Single; const b : RVector2) : RVector2;
      class operator divide(const a : RVector2; const b : RVector2) : RVector2;
      class operator multiply(const a, b : RVector2) : RVector2;
      class operator add(const a, b : RVector2) : RVector2;
      class operator add(const a : RVector2; b : Single) : RVector2;
      class operator subtract(const a, b : RVector2) : RVector2;
      class operator subtract(const a : RVector2; b : Single) : RVector2;
      class operator equal(const a, b : RVector2) : boolean;
      class operator lessthanorequal(const a : RVector2; b : Single) : boolean;
      class operator lessthanorequal(const a, b : RVector2) : boolean;
      class operator greaterthanorequal(const a, b : RVector2) : boolean;
      class operator notequal(const a, b : RVector2) : boolean;
      class operator Explicit(const a : RVector2) : TPoint;
      class operator Explicit(const a : RVector2) : TPointF;
      class operator Explicit(a : Single) : RVector2;
      class operator implicit(a : TPointF) : RVector2;
      class operator negative(const a : RVector2) : RVector2;
      class operator implicit(const a : RVector2) : string;
      case byte of
        0 : (X : Single; Y : Single);
        1 : (Width : Single; Height : Single);
        2 : (Element : array [0 .. 1] of Single);
        3 : (Axis : array [aX .. aY] of Single);
  end;

  ARVector2 = array of RVector2;

  PRVector3 = ^RVector3;

  RVector3 = packed record
    strict private
      function GetLength() : Single;
      procedure InSetLength(Length : Single);
      function getXZ : RVector2;
      procedure setXZ(const Value : RVector2);
      function ToPolar() : RVector3;
      procedure InSetPolar(const Value : RVector3);
    public
      constructor Create(X, Y, Z : Single); overload;
      constructor Create(XYZ : Single); overload;
      constructor Create(XYZ : TArray<Single>); overload;
      constructor Create0Y0(Y : Single); overload;

      constructor CreateFromIniString(const Value : string);
      function ToIniString : string;

      function IsEmpty : boolean;
      function IsZeroVector : boolean;
      property Length : Single read GetLength write InSetLength;
      function LengthSq() : Single;
      function MaxValue() : Single;
      function MinValue() : Single;
      /// <summary> Returns the maximum value of all abs(elements). </summary>
      function MaxAbsValue() : Single;
      /// <summary> Returns the axis index of the maxmimum abs(value). </summary>
      function MaxAbsDimension() : Integer;
      function Clamp(MinValue, MaxValue : Single) : RVector3;
      function Cross(const b : RVector3) : RVector3;
      /// <summary> Returns a normalized direction from this to target. </summary>
      function DirectionTo(const Target : RVector3) : RVector3;
      /// <summary> Componentwise signs. </summary>
      function Sign : RVector3;
      /// <summary> Make this vector orthogonal to b with the Gram-Schmidt-Method. </summary>
      function Orthogonalize(const b : RVector3) : RVector3;
      function Distance(const b : RVector3) : Single;
      function DistanceXZ(const b : RVector3) : Single;
      /// <summary> Return a hashvalue in integer range for vector. Uses nice computation for the value with primes and xor ;) </summary>
      function GetHashValue : Integer;
      function GetArbitaryOrthogonalVector : RVector3;
      procedure InNormalize; overload;
      procedure InNormalize(Base : Single); overload;
      function Dot(const b : RVector3) : Single;

      // Chainable Operations --------------------------------------------------
      function SetDim(Dim : Integer; Wert : Single) : RVector3;
      function SetLength(Length : Single) : RVector3;
      /// <summary> Set the length to Length if its smaller then length. </summary>
      function SetLengthMin(Length : Single) : RVector3;
      /// <summary> Set the length to Length if its greater then length. </summary>
      function SetLengthMax(Length : Single) : RVector3;
      function SetX(Value : Single) : RVector3;
      function SetY(Value : Single) : RVector3;
      function SetZ(Value : Single) : RVector3;
      function SetYZ(Value : RVector2) : RVector3;
      function NegateY : RVector3;
      function NegateDim(Dim : Integer) : RVector3;
      function Normalize : RVector3; overload;
      function Normalize(Base : Single) : RVector3; overload;
      function Frac : RVector3;
      function Trunc : RVector3;
      function Round : RVector3;

      /// <summary> Compare two vectors with a delta value (epsilon). If distance of vector 1 and vector 2 greater
      /// epsilon, this function returns False, else True.</summary>
      function SimilarTo(const CompareWith : RVector3; Epsilon : Single = SINGLE_ZERO_EPSILON) : boolean;
      function AngleBetween(const b : RVector3) : Single;
      function Lerp(const Target : RVector3; s : Single) : RVector3;
      function CosLerp(const Target : RVector3; s : Single) : RVector3;
      function RotateAroundPoint(const Point : RVector3; Pitch, Yaw, Roll : Single) : RVector3; overload;
      function RotateAroundPoint(const Point, PitchYawRoll : RVector3) : RVector3; overload;
      function RotateAxis(const Axis : RVector3; Angle : Single) : RVector3;
      procedure InRotateAxis(const Axis : RVector3; Angle : Single);
      function RotatePitchYawRoll(Pitch, Yaw, Roll : Single) : RVector3; overload;
      procedure InRotatePitchYawRoll(Pitch, Yaw, Roll : Single);
      function RotatePitchYawRoll(const PitchYawRoll : RVector3) : RVector3; overload;
      function ToBaryCentric(tri1, tri2, tri3 : RVector3) : RVector3;
      class function CartesianToSphere(U, V, r : Single) : RVector3; static; inline;
      function Sum : Single;
      function Abs : RVector3;
      /// <summary>Min for each component</summary>
      function MinEachComponent(const b : RVector3) : RVector3;
      /// <summary>Max for each component</summary>
      function MaxEachComponent(const b : RVector3) : RVector3; overload;
      /// <summary> Transforms a kartesian vector (x,y,z) into spherical coordinates (u,v,r) with u the rotation angle around x
      /// v the rotation angle along y and r the distance from the origin.  </summary>
      property Polar : RVector3 read ToPolar write InSetPolar;
      // Swizzles; If someone is bored please complete all Swizzles
      property XZ : RVector2 read getXZ write setXZ;
      function YZ : RVector2;
      function ZY : RVector2;
      function XYZ : RVector3;
      function YZX : RVector3;
      function ZXY : RVector3;
      function XZY : RVector3;
      function ZYX : RVector3;
      function YXZ : RVector3;
      function ZZZ : RVector3;
      function X0Z : RVector3;
      class function TryFromString(str : string; out Vector : RVector3) : boolean; static;

      class function BaryCentric(const v1, v2, v3 : RVector3; f, g : Single) : RVector3; static;
      class function Random : RVector3; static;
      class function RandomFromDisk(const Diskposition, Disknormal : RVector3; Diskradius : Single) : RVector3; static;
      /// <summary> Returns a random point in the sphere with specified radius. If radius < 0 it returns points on the sphere surface with radius abs(radius).
      /// Constraints are angle constraints. </summary>
      class function getRandomPointInSphere(Radius : Single; UpperConstraint : Single = 0; LowerConstraint : Single = 0) : RVector3; static;

      class operator add(const a, b : RVector3) : RVector3;
      class operator add(const a : RVector3; b : Single) : RVector3;
      class operator equal(const a, b : RVector3) : boolean;
      class operator notequal(const a, b : RVector3) : boolean;
      class operator subtract(const a, b : RVector3) : RVector3;
      class operator subtract(const a : RVector3; b : Single) : RVector3;
      class operator negative(const a : RVector3) : RVector3;
      // each component with the other
      class operator multiply(const a, b : RVector3) : RVector3;
      class operator multiply(const a : RVector3; b : Single) : RVector3;
      class operator multiply(a : Single; const b : RVector3) : RVector3;
      class operator divide(const a : RVector3; b : Single) : RVector3;
      class operator divide(const a, b : RVector3) : RVector3;
      class operator implicit(const a : RVector3) : string;
      class operator implicit(const a : RVector3) : TValue;
      class operator Explicit(a : Single) : RVector3;
      /// <summary> For each component </summary>
      class operator LessThan(const a, b : RVector3) : boolean;
      class operator lessthanorequal(const a, b : RVector3) : boolean;
      class operator greaterthanorequal(const a, b : RVector3) : boolean;
      class operator GreaterThan(const a, b : RVector3) : boolean;

      case byte of
        0 : (X : Single; Y : Single; Z : Single);
        1 : (XY : RVector2);
        2 : (Element : array [0 .. 2] of Single);
        3 : (Axis : array [aX .. aZ] of Single);
  end;

  ARVector3 = array of RVector3;

  PRVector4 = ^RVector4;

  /// <summary> A 4D single Vector. </summary>
  RVector4 = packed record
    class function ZERO : RVector4; static;
    /// <summary> Creates a 4D-Vector (X,Y,Z,W) </summary>
    constructor Create(X, Y, Z, W : Single); overload;
    /// <summary> Creates a 4D-Vector (vec.x,vec.y,vec.z,W) </summary>
    constructor Create(const vec : RVector3; W : Single = 0.0); overload;
    constructor Create(const XY, ZW : RVector2); overload;
    constructor Create(const XYZW : Single); overload;

    /// <summary> (X,Y,Z,W)/|(X,Y,Z,W)|; if (0,0,0,0) returns (0,0,0,0) </summary>
    function Normalize : RVector4;
    /// <summary> |(X,Y,Z,W)| </summary>
    function Length : Single;
    /// <summary> (X,Y,Z,W) = (0,0,0,0) </summary>
    function IsZero : boolean;
    /// <summary> (X,Y,Z,W) => (X/W,Y/W,Z/W); if (W = 0) returns (0,0,0,0) </summary>
    function Unproject : RVector3;
    /// <summary> Returns linear Interpolation between self and target: self + s * (Target-self). </summary>
    function Lerp(const Target : RVector4; s : Single) : RVector4;
    /// <summary> Returns (x,y,z,value) </summary>
    function SetW(Value : Single) : RVector4;
    function Dot(const b : RVector4) : Single;
    function Abs : RVector4;
    function Sum : Single;
    function MaxValue() : Single;
    function MinValue() : Single;
    function MaxAbsValue() : Single;

    /// <summary> Easy access functions. </summary>
    function WXYZ : RVector4;
    function ZYXW : RVector4;

    /// <summary> Check equality for each element with Epsilon for rounding error. </summary>
    function SimilarTo(const b : RVector4; Epsilon : Single = SINGLE_ZERO_EPSILON) : boolean;

    function SLerp(const Target : RVector4; s : Single) : RVector4;

    /// <summary> Operators for each component. </summary>
    class operator add(const a : RVector4; b : Single) : RVector4;
    class operator add(const a, b : RVector4) : RVector4;
    class operator subtract(const a, b : RVector4) : RVector4;
    class operator subtract(const a : RVector4; b : Single) : RVector4;
    class operator multiply(const a : RVector4; b : Single) : RVector4;
    class operator divide(const a : RVector4; b : Single) : RVector4;
    class operator multiply(a : Single; const b : RVector4) : RVector4;
    class operator multiply(const a : RVector4; const b : RVector4) : RVector4;
    class operator negative(const a : RVector4) : RVector4;
    class operator equal(const a, b : RVector4) : boolean;
    class operator notequal(const a, b : RVector4) : boolean;
    /// <summary> Effectively ToString </summary>
    class operator implicit(const a : RVector4) : string;
    class operator Explicit(a : Single) : RVector4;
    case byte of
      0 : (X : Single; Y : Single; Z : Single; W : Single);
      1 : (XYZ : RVector3);
      2 : (XY : RVector2);
      3 : (Element : array [0 .. 3] of Single);
      4 : (Axis : array [aX .. aW] of Single);
  end;

  ARVector4 = array of RVector4;

  PMatrix = ^RMatrix;

  RQuaternion = RVector4;

  /// <summary> A 4x4 single Matrix. </summary>
  RMatrix = packed record
    private
      function GetElement(Index : Integer) : Single;
      procedure SetElement(Index : Integer; const Value : Single); inline;
      /// <summary> Easy access to the rows and columns. </summary>
      function getColumn(Index : Integer) : RVector3;
      procedure setColumn(Index : Integer; const Value : RVector3);
      function getRow(Index : Integer) : RVector3;
      procedure setRow(Index : Integer; const Value : RVector3);
      /// <summary> Alias for getColumn(3). </summary>
      function GetTranslationComponent() : RVector3;
      procedure SetTranslationComponent(const V : RVector3);
    const
      Size = 4;
    public
      /// <summary> Create a 4x4-Matrix with the elements row-by-row. </summary>
      constructor Create(const Elements : array of Single);
      /// <summary> Create a basetransformationmatrix with new base (Left,Up,Front). </summary>
      constructor CreateBase(const Left, Up, Front : RVector3);
      /// <summary> Normalization is assured. Up will be aligned to orthogonal to front and left derived. </summary>
      constructor CreateSaveBase(const Front, Up : RVector3);
      /// <summary> Create a translationmatrix. </summary>
      constructor CreateTranslation(const Position : RVector3);
      /// <summary> Create a scalingmatrix. </summary>
      constructor CreateScaling(const Scale : RVector3); overload;
      constructor CreateScaling(const Scale : Single); overload;
      /// <summary> Rotation ccw around the respective axis. (Right-Hand-Rotation on Left-Hand-System)</summary>
      constructor CreateRotationX(const Angle : Single);
      constructor CreateRotationY(const Angle : Single);
      constructor CreateRotationZ(const Angle : Single);
      /// <summary> Creates a Yaw-Pitch-Roll-Rotation. (Pitch = Neigen, Yaw = Drehen, Roll = Rollen)
      /// Rotation is applied first roll then pitch and finally yaw.
      /// For a UnitZ-Vector this Matrix rotates with angles (x,y,z) around the axis'.</summary>
      constructor CreateRotationPitchYawRoll(const Pitch, Yaw, Roll : Single); overload;
      constructor CreateRotationPitchYawRoll(const YawPitchRoll : RVector3); overload;
      /// <summary> Create a rotationmatrix ccw around the axis. Axis will be normalized. </summary>
      constructor CreateRotationAxis(const Axis : RVector3; const Angle : Single);
      /// <summary> Create a cameramatrix at point Eye looking at At with updirection Up. </summary>
      constructor CreateLookAtLH(const Eye, At, Up : RVector3);
      /// <summary> Create a orthogonal projectionmatrix. </summary>
      constructor CreateOrthoLH(Width, Height, ZNear, ZFar : Single);
      /// <summary> Create a perspective projectionmatrix. </summary>
      constructor CreatePerspectiveFovLH(FovY, AspectRatio, ZNear, ZFar : Single);
      /// <summary> Returns the upper left 3x3-SubMatrix. </summary>
      function Get3x3() : RMatrix;
      /// <summary> Transpose the matrix. </summary>
      function Transpose : RMatrix;
      /// <summary> Transpose the matrix in-place. </summary>
      procedure InTranspose;
      /// <summary> Inverse the matrix. </summary>
      function Inverse : RMatrix;
      /// <summary> Inverse the matrix in-place. </summary>
      procedure InInverse;
      /// <summary> Returns the determinant of the matrix. </summary>
      function Determinant : Single;
      /// <summary> Sum over all abs(element). </summary>
      function AbsSum : Single;
      procedure SwapXY;
      procedure SwapXZ;
      procedure SwapYZ;

      property Front : RVector3 index 2 read getColumn write setColumn;
      property Up : RVector3 index 1 read getColumn write setColumn;
      property Left : RVector3 index 0 read getColumn write setColumn;

      /// <summary> Check equality for each element with Epsilon for rounding error. </summary>
      function SimilarTo(const Matrix : RMatrix) : boolean;

      /// <summary> Easy access to the rows and columns. </summary>
      property Column[index : Integer] : RVector3 read getColumn write setColumn;
      property Row[index : Integer] : RVector3 read getRow write setRow;
      /// <summary> Alias for Column[3]. </summary>
      property Translation : RVector3 read GetTranslationComponent write SetTranslationComponent;
      /// <summary> Elements row by row with range 0..15 </summary>
      property Element[index : Integer] : Single read GetElement write SetElement;

      class operator negative(const a : RMatrix) : RMatrix;
      /// <summary> Addition/Subtraction for each component. </summary>
      class operator add(const a, b : RMatrix) : RMatrix;
      class operator subtract(const a, b : RMatrix) : RMatrix;
      /// <summary> Matrixmultiplication. </summary>
      class operator multiply(const a, b : RMatrix) : RMatrix;
      class operator multiply(a : Single; const b : RMatrix) : RMatrix;
      class operator multiply(const a : RMatrix; b : Single) : RMatrix;
      class operator divide(const a : RMatrix; b : Single) : RMatrix;
      /// <summary> Matrixtransformation of b with a. </summary>
      class operator multiply(const a : RMatrix; const b : RVector4) : RVector4;
      /// <summary> Matrixtransformation of (b,1) with a and finally reprojection to 3D. </summary>
      class operator multiply(const a : RMatrix; const b : RVector3) : RVector3;
      /// <summary> Compare element by element, if all equal return true </summary>
      class operator equal(const a, b : RMatrix) : boolean;
      /// <summary> Effectively ToString </summary>
      class operator implicit(const a : RMatrix) : string;

      /// <summary>
      /// 1   2  3  4
      /// 5   6  7  8   is saved as 1 5 9 13 2 6 10 14 3 7 11 15 4 8 12 16
      /// 9  10 11 12   in memory, because of the access per array[X,Y]
      /// 13 14 15 16   access per _XY or m[X,Y] or Element[X+Y*4]
      /// </summary>
      case Integer of
        0 : (_11, _12, _13, _14 : Single;
            _21, _22, _23, _24 : Single;
            _31, _32, _33, _34 : Single;
            _41, _42, _43, _44 : Single);
        1 : (m : array [0 .. Size - 1, 0 .. Size - 1] of Single);
  end;

  AMatrix = array of RMatrix;

  PMatrix4x3 = ^RMatrix4x3;

  /// <summary> A 4x3 single Matrix. </summary>
  RMatrix4x3 = packed record
    private
      const
      ELEMENT_COUNT = 12;
      SIZE_X        = 4;
      SIZE_Y        = 3;
      /// <summary> Alias for getColumn(3). </summary>
      function GetTranslationComponent() : RVector3;
      procedure SetTranslationComponent(const V : RVector3);
      function getColumn(Index : Integer) : RVector3;
      procedure setColumn(Index : Integer; const Value : RVector3);
    public
      /// <summary> Alias for Column[3]. </summary>
      property Translation : RVector3 read GetTranslationComponent write SetTranslationComponent;
      property Column[index : Integer] : RVector3 read getColumn write setColumn;

      property Front : RVector3 index 2 read getColumn write setColumn;
      property Up : RVector3 index 1 read getColumn write setColumn;
      property Left : RVector3 index 0 read getColumn write setColumn;

      constructor Create(const Elements : array of Single);
      constructor CreateFrom4x4(const Matrix : RMatrix);
      /// <summary> Create a basetransformationmatrix with new base (Left,Up,Front). </summary>
      constructor CreateBase(const Left, Up, Front : RVector3);
      /// <summary> Create a translationmatrix. </summary>
      constructor CreateTranslation(const Position : RVector3);
      /// <summary> Create a scalingmatrix. </summary>
      constructor CreateScaling(const Scale : RVector3); overload;
      constructor CreateScaling(const Scale : Single); overload;
      /// <summary> Rotation ccw around the respective axis. (Right-Hand-Rotation on Left-Hand-System)</summary>
      constructor CreateRotationX(const Angle : Single);
      constructor CreateRotationY(const Angle : Single);
      constructor CreateRotationZ(const Angle : Single);
      constructor CreateRotationZAroundPosition(const Position : RVector3; const Angle : Single);
      constructor CreateRotationFromQuaternion(const Quaternion : RQuaternion);
      /// <summary> Creates a Yaw-Pitch-Roll-Rotation. (Pitch = Neigen, Yaw = Drehen, Roll = Rollen)
      /// Rotation is applied first roll then pitch and finally yaw.
      /// For a UnitZ-Vector this Matrix rotates with angles (x,y,z) around the axis'.</summary>
      constructor CreateRotationPitchYawRoll(const Pitch, Yaw, Roll : Single); overload;
      constructor CreateRotationPitchYawRoll(const YawPitchRoll : RVector3); overload;
      /// <summary> Create a rotationmatrix ccw around the axis. Axis will be normalized. </summary>
      constructor CreateRotationAxis(const Axis : RVector3; const Angle : Single);
      constructor CreateSkew(const Skew : RVector2);

      function Interpolate(const Target : RMatrix4x3; Factor : Single) : RMatrix4x3;
      function IsZero : boolean;
      function Determinant : Single;

      /// <summary> Transposes 3x3 only! </summary>
      function Transpose : RMatrix4x3;
      function Inverse : RMatrix4x3;

      function To3x3 : RMatrix4x3;
      function To4x4 : RMatrix;
      function ToQuaternion : RQuaternion;

      procedure SwapXY;
      procedure SwapXZ;
      procedure SwapYZ;

      /// <summary> Addition/Subtraction for each component. </summary>
      class operator add(const a, b : RMatrix4x3) : RMatrix4x3;
      class operator subtract(const a, b : RMatrix4x3) : RMatrix4x3;
      /// <summary> Matrixmultiplication. </summary>
      class operator multiply(const a, b : RMatrix4x3) : RMatrix4x3;
      class operator multiply(a : Single; const b : RMatrix4x3) : RMatrix4x3;
      class operator multiply(const a : RMatrix4x3; b : Single) : RMatrix4x3;
      class operator divide(const b : RMatrix4x3; const a : Single) : RMatrix4x3;
      /// <summary> Matrixtransformation of b with a. </summary>
      class operator multiply(const a : RMatrix4x3; const b : RVector3) : RVector3;

      case Integer of
        0 : (_11, _12, _13, _41 : Single;
            _21, _22, _23, _42 : Single;
            _31, _32, _33, _43 : Single);
        1 : (Element : array [0 .. 11] of Single);
  end;

  AMatrix4x3 = array of RMatrix4x3;

  RMatrix2x2 = packed record
    private
      function getColumn(Index : Integer) : RVector2;
      procedure setColumn(Index : Integer; const Value : RVector2);
    const
      Size = 2;
    public
      /// <summary> Create a basetransformationmatrix with new base (Left,Front). </summary>
      constructor CreateBase(const Left, Front : RVector2);

      function Determinant : Single;
      function Inverse : RMatrix2x2;
      /// <summary> Easy access to the rows and columns. </summary>
      property Column[index : Integer] : RVector2 read getColumn write setColumn;
      /// <summary> Matrixtransformation of b with a. </summary>
      class operator multiply(const a : RMatrix2x2; const b : RVector2) : RVector2;

      case Integer of
        0 : (_11, _12 : Single;
            _21, _22 : Single);
        1 : (m : array [0 .. Size - 1, 0 .. Size - 1] of Single);
  end;

  PRIntVector2 = ^RIntVector2;

  RIntVector2 = packed record
    function SetX(X : Integer) : RIntVector2;
    function SetY(Y : Integer) : RIntVector2;
    constructor Create(X, Y : Integer); overload;
    constructor Create(XY : Integer); overload;
    constructor CreateFromVector2(const vec : RVector2);
    function IsZeroVector : boolean;
    /// <summary> Returns True if any axis has a zero. </summary>
    function HasAZero : boolean;
    function Length : Single;
    function Min(const b : RIntVector2) : RIntVector2; overload;
    function Max(const b : RIntVector2) : RIntVector2; overload;
    function Min(b : Integer) : RIntVector2; overload;
    function Max(b : Integer) : RIntVector2; overload;
    function MaxValue : Integer;
    function MinValue : Integer;
    function Hash : Integer;
    /// <summary> Returns (random(x), random(y)). </summary>
    function Random : RIntVector2;
    function Distance(const b : RIntVector2) : Single;
    function Clamp(const Min, Max : RIntVector2) : RIntVector2;
    function YX : RIntVector2;
    class function TryFromString(str : string; out Vector : RIntVector2) : boolean; static;
    class function ZERO : RIntVector2; static;
    class operator implicit(a : TPoint) : RIntVector2;
    class operator Explicit(const a : RIntVector2) : TPoint;
    class operator implicit(const a : RIntVector2) : RVector2;
    class operator Explicit(const a : RIntVector2) : RVector2;
    class operator implicit(const a : RIntVector2) : TValue;
    class operator implicit(const a : RIntVector2) : string;
    class operator equal(const a, b : RIntVector2) : boolean;
    class operator notequal(const a, b : RIntVector2) : boolean;
    class operator negative(const a : RIntVector2) : RIntVector2;
    class operator GreaterThan(const a : RIntVector2; b : Integer) : boolean;
    class operator greaterthanorequal(const a : RIntVector2; b : Integer) : boolean;
    class operator LessThan(const a : RIntVector2; b : Integer) : boolean;
    class operator lessthanorequal(const a : RIntVector2; b : Integer) : boolean;
    class operator GreaterThan(const a, b : RIntVector2) : boolean;
    class operator greaterthanorequal(const a, b : RIntVector2) : boolean;
    class operator LessThan(const a, b : RIntVector2) : boolean;
    class operator lessthanorequal(const a, b : RIntVector2) : boolean;
    class operator add(const a, b : RIntVector2) : RIntVector2;
    class operator add(const a : RIntVector2; b : Integer) : RIntVector2;
    class operator add(a : Integer; const b : RIntVector2) : RIntVector2;
    class operator multiply(a : Integer; const b : RIntVector2) : RIntVector2;
    class operator multiply(const a : RIntVector2; b : Integer) : RIntVector2;
    class operator multiply(a : Single; const b : RIntVector2) : RVector2;
    class operator multiply(const a : RIntVector2; b : Single) : RVector2;
    class operator multiply(const a, b : RIntVector2) : RIntVector2;
    class operator IntDivide(const a : RIntVector2; b : Integer) : RIntVector2;
    class operator divide(const a : RIntVector2; b : Single) : RVector2;
    class operator divide(a : Single; const b : RIntVector2) : RVector2;
    class operator subtract(const a, b : RIntVector2) : RIntVector2;
    class operator subtract(const a : RIntVector2; b : Integer) : RIntVector2;
    class operator subtract(a : Integer; const b : RIntVector2) : RIntVector2;
    case byte of
      0 : (X : Integer; Y : Integer);
      1 : (Width : Integer; Height : Integer);
      2 : (Element : array [0 .. 1] of Integer);
      3 : (Axis : array [aX .. aY] of Integer);
  end;

  PIntVector3 = ^RIntVector3;

  RIntVector3 = packed record
    public
      function Elementsumme : Integer;
      function QuadratischeElementSumme : Integer; // Summer der quadratischen Elemente
      function ToString : string;
      function AbsVektor : RIntVector3;
      function Kreuzprodukt(const b : RIntVector3) : RIntVector3;
      function ToRVector3 : RVector3;
      function Dot(const b : RIntVector3) : Integer;
      function Contains(a : Integer) : boolean;
      class function ZERO : RIntVector3; static; // gibt den Nullvektor zurück
      class function getRIntVector3(X, Y, Z : Integer) : RIntVector3; static;
      constructor Create(X, Y, Z : Integer);
      class operator implicit(const a : RIntVector3) : RVector3;
      class operator multiply(const a : RIntVector3; b : Integer) : RIntVector3;
      class operator multiply(a : Integer; const b : RIntVector3) : RIntVector3;
      class operator multiply(const a : RIntVector3; const b : RIntVector3) : RIntVector3;
      class operator negative(const a : RIntVector3) : RIntVector3;
      class operator add(const a : RIntVector3; const b : RIntVector3) : RIntVector3;
      class operator subtract(const a : RIntVector3; const b : RIntVector3) : RIntVector3;
      class operator equal(const a, b : RIntVector3) : boolean;
      class operator notequal(const a, b : RIntVector3) : boolean;
      case byte of
        0 : (X : Integer; Y : Integer; Z : Integer);
        1 : (XY : RIntVector2);
        2 : (Element : array [0 .. 2] of Integer);
        3 : (Axis : array [aX .. aZ] of Integer);
  end;

  ARintVector3 = array of RIntVector3;

  RIntVector4 = packed record
    private
      function getXZ : RIntVector2;
      function GetYW : RIntVector2;
      procedure setXZ(const Value : RIntVector2);
      procedure setYW(const Value : RIntVector2);
    public
      constructor Create(X, Y, Z, W : Integer); overload;
      constructor Create(XYZW : Integer); overload;
      class operator negative(const a : RIntVector4) : RIntVector4;
      class operator implicit(const a : RIntVector4) : RVector4;
      /// <summary> Sums each axis in the rectangle space (Top, Right, Bottom, Left). Returns (Y+W, X+Z). </summary>
      function SumAxis : RIntVector2;
      function ToArray : TArray<Single>;
      // swizzles
      function YX : RIntVector2;
      function WX : RIntVector2;
      function WZ : RIntVector2;
      property YW : RIntVector2 read GetYW write setYW;
      property XZ : RIntVector2 read getXZ write setXZ;
      case byte of
        0 : (X : Integer; Y : Integer; Z : Integer; W : Integer);
        1 : (Top : Integer; Right : Integer; Bottom : Integer; Left : Integer);
        2 : (XYZ : RIntVector3);
        3 : (XY : RIntVector2);
        4 : (Element : array [0 .. 3] of Integer);
        5 : (Axis : array [aX .. aW] of Integer);
  end;

  AIntVector4 = array of RIntVector4;

  /// <summary> A Hermite-Spline. http://de.wikipedia.org/wiki/Kubisch_Hermitescher_Spline </summary>
  RHermiteSpline = record
    StartPosition, EndPosition, StartTangent, EndTangent : RVector3;
    constructor Create(const StartPosition, EndPosition, StartTangent, EndTangent : RVector3);
    function Direction : RVector3;
    function Length(Samplingrate : Integer = 20) : Single;
    /// <summary> Returns the position at s percent (0.0-1.0) of the spline. </summary>
    function getPosition(s : Single) : RVector3;
    function getLinearPosition(s : Single; Samplingrate : Integer = 20) : RVector3;
    /// <summary> Returns the direction of the spline at s percent (0.0-1.0). </summary>
    function getTangent(s : Single) : RVector3;
    function getLinearTangent(s : Single; Samplingrate : Integer = 20) : RVector3;
    /// <summary> Returns an orthogonal vector to the spline at s percent (0.0-1.0). </summary>
    function getNormal(s : Single) : RVector3;
    function getLinearNormal(s : Single; Samplingrate : Integer = 20) : RVector3;
  end;

  /// <summary> Describes a timing curve between 0,0 and 1,1 by two control points.
  /// Used in css animation system, code from https://gist.github.com/mckamey/3783009. </summary>
  RCubicBezier = record
    P1X, P1Y, P2X, P2Y : Single;
    constructor Create(P1X, P1Y, P2X, P2Y : Single);
    /// <summary> Returns the progress at the time t in [0,1]. </summary>
    function Solve(T : Single; Epsilon : Single = 1E-6) : Single;
    class function LINEAR : RCubicBezier; static;
    class function EASE : RCubicBezier; static;
    class function EASEIN : RCubicBezier; static;
    class function EASEOUT : RCubicBezier; static;
    class function EASEINOUT : RCubicBezier; static;
  end;

  RVariedInteger = record
    Mean, Variance : Integer;
    constructor Create(Mean : Integer); overload;
    constructor Create(Mean, Variance : Integer); overload;
    function Random() : Integer;
    function Lerp(s : Single) : Integer;
    class operator implicit(a : Integer) : RVariedInteger;
  end;

  RVariedSingle = record
    Mean, Variance : Single;
    constructor Create(Mean : Single); overload;
    constructor Create(Mean, Variance : Single); overload;
    function Random() : Single; overload;
    function Random(FixedRandomFactor : Single) : Single; overload;
    class operator implicit(a : Single) : RVariedSingle;
  end;

  RVariedVector2 = record
    private
      FRadialVaried : boolean;
    public
      Mean, Variance : RVector2;
      property RadialVaried : boolean read FRadialVaried write FRadialVaried;
      constructor Create(const Mean : RVector2); overload;
      constructor Create(const Mean, Variance : RVector2); overload;
      constructor Create(MeanX, MeanY, VarianceX, VarianceY : Single); overload;
      constructor CreateRadialVaried(const Mean : RVector2; Variance : Single);
      function GetRandomVector() : RVector2;
      class operator implicit(const a : RVector2) : RVariedVector2;
  end;

  RVariedVector3 = record
    private
      FRadialVaried : boolean;
    public
      Mean, Variance : RVector3;
      property RadialVaried : boolean read FRadialVaried write FRadialVaried;
      constructor Create(MeanXYZ : Single); overload;
      constructor Create(MeanX, MeanY, MeanZ : Single); overload;
      constructor Create(const Mean : RVector3); overload;
      constructor Create(const Mean, Variance : RVector3); overload;
      constructor CreateRadialVaried(const Mean : RVector3; Variance : Single);
      function GetRandomVector() : RVector3;
      function GetRandomVectorSpecial(FixedRandomFactor : Single) : RVector3;
      /// <summary> Returns a random value from negative variance to positive variance around mean. </summary>
      function RandomDim(Dim : Integer) : Single;
      /// <summary> Returns a linear interpolated value from negative variance to positive variance around mean. </summary>
      function LerpDim(Dim : Integer; s : Single) : Single;
      class operator implicit(const a : RVector3) : RVariedVector3;
  end;

  RVariedVector4 = record
    private
      function getX : RVariedSingle;
      function getXY : RVariedVector2;
      function getXYZ : RVariedVector3;
      procedure SetX(const Value : RVariedSingle);
      procedure setXY(const Value : RVariedVector2);
      procedure setXYZ(const Value : RVariedVector3);
    public
      Mean, Variance : RVector4;
      property X : RVariedSingle read getX write SetX;
      property XY : RVariedVector2 read getXY write setXY;
      property XYZ : RVariedVector3 read getXYZ write setXYZ;
      constructor Create(const Mean : RVector4); overload;
      constructor Create(const Mean, Variance : RVector4); overload;
      function GetRandomVector() : RVector4;
      class operator implicit(const a : RVector4) : RVariedVector4;
  end;

  RVariedHermiteSpline = record
    StartPosition, EndPosition, StartTangent, EndTangent : RVariedVector3;
    constructor Create(const StartPosition, EndPosition, StartTangent, EndTangent : RVariedVector3);
    function getRandomSpline : RHermiteSpline;
  end;

type

  RIntVector2Helper = record helper for RIntVector2
    function ToRVector : RVector2;
  end;

  RIntVector4Helper = record helper for RIntVector4
    const
      ZERO : RIntVector4 = (X : 0; Y : 0; Z : 0; W : 0);
  end;

  RMatrixHelper = record helper for RMatrix
    public
      const
      ZERO : RMatrix     = ();
      IDENTITY : RMatrix = (_11 : 1.0; _22 : 1.0; _33 : 1.0; _44 : 1.0);
      function To4x3 : RMatrix4x3;
  end;

  RMatrix4x3Helper = record helper for RMatrix4x3
    public
      const
      ZERO : RMatrix4x3     = ();
      IDENTITY : RMatrix4x3 = (_11 : 1.0; _22 : 1.0; _33 : 1.0);
  end;

  RVector2Helper = record helper for RVector2
    function X0Y(Y : Single = 0.0) : RVector3;
    function XY0(Z : Single = 0.0) : RVector3;
    function Trunc : RIntVector2;
    function Round : RIntVector2;
  end;

  RVector3Helper = record helper for RVector3
    const
      UNITX : RVector3 = (X : 1; Y : 0; Z : 0);
      UNITY : RVector3 = (X : 0; Y : 1; Z : 0);
      UNITZ : RVector3 = (X : 0; Y : 0; Z : 1);
      ONE : RVector3   = (X : 1; Y : 1; Z : 1);
      ZERO : RVector3  = (X : 0; Y : 0; Z : 0);
      EMPTY : RVector3 = (X : NaN; Y : 0; Z : 0);
      function XYZ1 : RVector4;
      function XYZ0 : RVector4;
  end;

  RVector4Helper = record helper for RVector4
    function QuaternionToMatrix : RMatrix;
    function QuaternionToMatrix4x3 : RMatrix4x3;
  end;

  EnumInterpolationMode = (imLinear, imCosinus);

  HMath = class
    private
      class procedure GetInterpolationIndices(ArrayLength : Integer; Progress : Single; out startIndex, endIndex : Integer; out localFactor : Single);
      class procedure GetInterpolationKeys<T>(const TimeKeys : array of RTuple<Integer, T>; Progress : Single; TimeRange : Integer; out StartValue, EndValue : T; out localFactor : Single);
    public
      /// <summary> Schneidet einen Wert ab, falls er über oder unter die Grenzen geht.</summary>
      class function Clamp(Wert, UntereGrenze, ObereGrenze : Single) : Single; overload;
      class function Clamp(Wert, UntereGrenze, ObereGrenze : Integer) : Integer; overload;
      class function Clamp(Wert, UntereGrenze, ObereGrenze : Int64) : Int64; overload;
      /// <summary> Clamp between 0 and 1 </summary>
      class function Saturate(Wert : Single) : Single; overload;
      /// <summary> Evaluates a formula. Very simple and restricted. Only +,-,*,/ supported, no right order
      /// only evaluated from left to right. 1+2*3-4/5 = 1 (1+2=3 *3=9 -4=5 /5=1). </summary>
      class function Eval(str : string) : Single;
      /// <summary> Tests if Value is in a given range
      /// Returns True if lowerBound <= Value <= upperBound </summary>
      class function inRange(Value, lowerBound, upperBound : Integer) : boolean; overload;
      class function inRange(Value, lowerBound, upperBound : Single) : boolean; overload;
      class function LinLerpF(X, Y, s : Single) : Single;
      class function CosLerpF(X, Y, s : Single) : Single;
      class function iSqrt(const Value : Single) : Integer;
      class function fMod(const Value, Modulo : Single) : Single;
      class function Log2Ceil(X : Single) : Integer;
      class function HasRepeatedDigits(Number : Integer) : boolean; static;
      /// <summary> Returns the smallest exponent of a power of 2 number which is smaller or equal than X. Examples: 2 => 1, 4 => 2, 5 => 2, 9 => 3 </summary>
      class function Log2Floor(X : Integer) : Integer;
      class function Interpolate(const Values : array of Single; Progress : Single; InterpolationMode : EnumInterpolationMode = imLinear) : Single; overload;
      class function Interpolate(const TimeKeys : array of RTuple<Integer, Single>; Progress : Single; InterpolationMode : EnumInterpolationMode = imLinear; TimeRange : Integer = -1) : Single; overload;
      class function Interpolate(const Values : array of RVector2; Progress : Single; InterpolationMode : EnumInterpolationMode = imLinear) : RVector2; overload;
      class function Interpolate(const TimeKeys : array of RTuple<Integer, RVector2>; Progress : Single; InterpolationMode : EnumInterpolationMode = imLinear; TimeRange : Integer = -1) : RVector2; overload;
      class function Interpolate(const Values : array of RVector3; Progress : Single; InterpolationMode : EnumInterpolationMode = imLinear) : RVector3; overload;
      class function Interpolate(const TimeKeys : array of RTuple<Integer, RVector3>; Progress : Single; InterpolationMode : EnumInterpolationMode = imLinear; TimeRange : Integer = -1) : RVector3; overload;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  ADWord = array of DWord;
  ASingle = array of Single;

function MapToLowerSampling(X, Samplingrate : Integer) : Integer;

function IsPowerOf2(X : Integer) : boolean;

// Gibt einen zufälligen 3D-Punkt innerhalb von einem Min und einem Max-Wert zurück
function GetRandomPointMinMax(const Min, Max : RVector3) : RVector3;

// Drehung eines Punktes um einen Anderen entsprechend zweier Winkel in einer bestimmten Entfernung
// Ähnlich Längen und Breitengrade der Erde
function Kugeldrehung(Waagwinkel, Senkwinkel, SKX, SKY, SKZ, Entfernung : Single) : RVector3; overload;
function Kugeldrehung(Waagwinkel, Senkwinkel : Single; const KugelZentrum : RVector3; Entfernung : Single) : RVector3; overload;
// Drehung des Invektors um den Zielvektor entsprechend der Winkel Kugelförmig
function Kugeldrehung(const Invektor, ZielVektor : RVector3; Waagwinkel, Senkwinkel : Single) : RVector3; overload;

// Berechnet die Länge des Vektors vom Start bis zu dem orthogonal nächsten Punkt des Punktes
// function RichtungsAbstand(const StartPosition, Richtung, Punkt : RVector3) : Single;

// function AbstandEbenePunkt(const Ebenenpunkt, EbenenNormale, Punkt : RVector3) : Single; overload;

// LineareInterpolation
function LinLerp(y1, y2 : Integer; s : Single) : Integer; overload;
function LinLerp(const y1, y2 : RVector3; s : Single) : RVector3; overload;
function SLinLerp(y1, y2 : Single; s : Single) : Single;

// KosinusInterpolation

function QuadraLerp(X, Y, Z : Single; s : Single) : Single; overload;
function QuadraLerp(const X, Y, Z : RVector3; s : Single) : RVector3; overload;

function diffMax(Wert1, Wert2, MaxWert : Integer) : Integer;
procedure decMax(var Wert : Integer; MaxWert : Integer; ModWert : Integer = 1);
procedure incMax(var Wert : Integer; MaxWert : Integer; ModWert : Integer = 1);

function cub(X : Single) : Single;

function sinc(const X : Single) : Single; inline;

function IntMod(const X, Y : Integer) : Integer;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  EngineFloatFormatSettings : TFormatSettings;

implementation

function IsPowerOf2(X : Integer) : boolean;
var
  Y : Integer;
begin
  Y := 1;
  while Y < X do Y := Y shl 1;
  Result := (X = 0) or (Y = X);
end;

function MapToLowerSampling(X, Samplingrate : Integer) : Integer;
begin
  Result := X - (X mod Samplingrate);
  if (X mod Samplingrate) >= Samplingrate / 2 then Result := Result + Samplingrate;
end;

function QuadraLerp(X, Y, Z : Single; s : Single) : Single;
begin
  Result := X * (1 - 2 * s) * (1 - s) + s * (Y * (4 - 4 * s) + Z * (2 * s - 1));
end;

function QuadraLerp(const X, Y, Z : RVector3; s : Single) : RVector3;
begin
  Result.X := QuadraLerp(X.X, Y.X, Z.X, s);
  Result.Y := QuadraLerp(X.Y, Y.Y, Z.Y, s);
  Result.Z := QuadraLerp(X.Z, Y.Z, Z.Z, s);
end;

function sinc(const X : Single) : Single;
begin
  Result := sin(X * PI) / (X * PI);
end;

function cub(X : Single) : Single;
begin
  Result := X * sqr(X);
end;

function LinLerp(y1, y2 : Integer; s : Single) : Integer;
begin
  Result := Round(s * y2 + (1 - s) * y1);
end;

function SLinLerp(y1, y2 : Single; s : Single) : Single;
begin
  Result := (s * y2 + (1 - s) * y1);
end;

function LinLerp(const y1, y2 : RVector3; s : Single) : RVector3;
begin
  Result := (s * y2) + ((1 - s) * y1);
end;

function GetRandomPointMinMax(const Min, Max : RVector3) : RVector3;
begin
  Result.X := Min.X + Random * (Max.X - Min.X);
  Result.Y := Min.Y + Random * (Max.Y - Min.Y);
  Result.Z := Min.Z + Random * (Max.Z - Min.Z);
end;

function Kugeldrehung(Waagwinkel, Senkwinkel, SKX, SKY, SKZ, Entfernung : Single) : RVector3;
begin
  Kugeldrehung.X := sin(Waagwinkel) * sin(Senkwinkel) * Entfernung + SKX;
  Kugeldrehung.Y := Cos(Senkwinkel) * Entfernung + SKY;
  Kugeldrehung.Z := Cos(Waagwinkel) * sin(Senkwinkel) * Entfernung + SKZ;
end;

function Kugeldrehung(Waagwinkel, Senkwinkel : Single; const KugelZentrum : RVector3; Entfernung : Single) : RVector3;
begin
  Kugeldrehung.X := sin(Waagwinkel) * sin(Senkwinkel) * Entfernung + KugelZentrum.X;
  Kugeldrehung.Y := Cos(Senkwinkel) * Entfernung + KugelZentrum.Y;
  Kugeldrehung.Z := Cos(Waagwinkel) * sin(Senkwinkel) * Entfernung + KugelZentrum.Z;
end;

function Kugeldrehung(const Invektor, ZielVektor : RVector3; Waagwinkel, Senkwinkel : Single) : RVector3;
var
  Matrix : RMatrix;
  temp : RVector3;
begin
  Matrix := RMatrix.CreateRotationPitchYawRoll(Senkwinkel, Waagwinkel, 0);
  temp := Invektor - ZielVektor;
  Result := (Matrix * temp) + ZielVektor;
end;

{ RHermiteSpline }

function RHermiteSpline.getNormal(s : Single) : RVector3;
var
  tangent : RVector3;
begin
  tangent := getTangent(s);
  if tangent = RVector3.UNITX then Result := tangent.Cross(-RVector3.UNITZ).Normalize
  else Result := tangent.Cross(RVector3.UNITX).Normalize;
end;

function RHermiteSpline.Direction : RVector3;
begin
  Result := (EndPosition - StartPosition).Normalize;
end;

function RHermiteSpline.getLinearNormal(s : Single; Samplingrate : Integer) : RVector3;
var
  tangent : RVector3;
begin
  tangent := getLinearTangent(s, Samplingrate);
  if tangent = RVector3.UNITX then Result := tangent.Cross(-RVector3.UNITZ).Normalize
  else Result := tangent.Cross(RVector3.UNITX).Normalize;
end;

function RHermiteSpline.getLinearPosition(s : Single; Samplingrate : Integer) : RVector3;
var
  ZurückzulegendeStrecke, momStrecke : Single;
  i : Integer;
  temp, lasttemp : RVector3;
begin
  Samplingrate := Samplingrate - 1;
  i := 0;
  s := Min(Max(s, 0), 1);
  momStrecke := 0;
  ZurückzulegendeStrecke := self.Length(Samplingrate) * s;
  while (true) do
  begin
    temp := getPosition(i / Samplingrate);
    if i <> 0 then momStrecke := momStrecke + (temp - lasttemp).Length;
    if (momStrecke >= ZurückzulegendeStrecke) and (i <> 0) then
    begin
      Result := lasttemp.Lerp(temp, (1 - (momStrecke - ZurückzulegendeStrecke) / (temp - lasttemp).Length));
      exit;
    end;
    lasttemp := temp;
    inc(i);
  end;
end;

function RHermiteSpline.getLinearTangent(s : Single; Samplingrate : Integer = 20) : RVector3;
const
  Epsilon = 0.001;
begin
  s := Min(Max(s, 0), 1);
  if 1 - s < Epsilon then Result := EndTangent.Normalize
  else Result := (getLinearPosition(s + Epsilon, Samplingrate) - getLinearPosition(s, Samplingrate)).Normalize;
end;

function RHermiteSpline.getPosition(s : Single) : RVector3;
var
  sqrs, cubs : Single;
begin
  s := HMath.Saturate(s);
  sqrs := sqr(s);
  cubs := cub(s);
  Result := ((2 * cubs - 3 * sqrs + 1) * StartPosition) + ((-2 * cubs + 3 * sqrs) * EndPosition) + ((cubs - 2 * sqrs + s) * StartTangent) + ((cubs - sqrs) * EndTangent);
end;

constructor RHermiteSpline.Create(const StartPosition, EndPosition, StartTangent, EndTangent : RVector3);
begin
  self.StartPosition := StartPosition;
  self.EndPosition := EndPosition;
  self.StartTangent := StartTangent;
  self.EndTangent := EndTangent;
end;

function RHermiteSpline.getTangent(s : Single) : RVector3;
const
  Epsilon = 0.001;
begin
  s := Min(Max(s, 0), 1);
  if 1 - s < Epsilon then Result := EndTangent.Normalize
  else Result := (getPosition(s + Epsilon) - getPosition(s)).Normalize;
end;

function RHermiteSpline.Length(Samplingrate : Integer) : Single;
var
  i : Integer;
  s : Single;
  temp, lasttemp : RVector3;
begin
  s := 0;
  for i := 0 to Samplingrate do
  begin
    temp := getPosition(i / Samplingrate);
    if i <> 0 then s := s + (temp - lasttemp).Length;
    lasttemp := temp;
  end;
  Result := s;
end;

{ RIntVektor3 }

function RIntVector3.AbsVektor : RIntVector3;
begin
  Result.X := Abs(X);
  Result.Y := Abs(Y);
  Result.Z := Abs(Z);
end;

class operator RIntVector3.add(const a, b : RIntVector3) : RIntVector3;
begin
  Result.X := a.X + b.X;
  Result.Y := a.Y + b.Y;
  Result.Z := a.Z + b.Z;
end;

function RIntVector3.Contains(a : Integer) : boolean;
begin
  Result := (X = a) or (Y = a) or (Z = a);
end;

constructor RIntVector3.Create(X, Y, Z : Integer);
begin
  self.X := X;
  self.Y := Y;
  self.Z := Z;
end;

function RIntVector3.Dot(const b : RIntVector3) : Integer;
begin
  Result := X * b.X + Y * b.Y + Z * b.Z;
end;

function RIntVector3.Elementsumme : Integer;
begin
  Result := X + Y + Z;
end;

class operator RIntVector3.equal(const a, b : RIntVector3) : boolean;
begin
  Result := (a.X = b.X) and (a.Y = b.Y) and (a.Z = b.Z);
end;

class function RIntVector3.getRIntVector3(X, Y, Z : Integer) : RIntVector3;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

class operator RIntVector3.implicit(const a : RIntVector3) : RVector3;
begin
  Result.X := a.X;
  Result.Y := a.Y;
  Result.Z := a.Z;
end;

function RIntVector3.Kreuzprodukt(const b : RIntVector3) : RIntVector3;
begin
  Result.X := Y * b.Z - Z * b.Y;
  Result.Y := Z * b.X - X * b.Z;
  Result.Z := X * b.Y - Y * b.X;
end;

class operator RIntVector3.multiply(const a : RIntVector3; b : Integer) : RIntVector3;
begin
  Result.X := a.X * b;
  Result.Y := a.Y * b;
  Result.Z := a.Z * b;
end;

class operator RIntVector3.multiply(a : Integer; const b : RIntVector3) : RIntVector3;
begin
  Result.X := a * b.X;
  Result.Y := a * b.Y;
  Result.Z := a * b.Z;
end;

class operator RIntVector3.negative(const a : RIntVector3) : RIntVector3;
begin
  Result.X := -a.X;
  Result.Y := -a.Y;
  Result.Z := -a.Z;
end;

class operator RIntVector3.notequal(const a, b : RIntVector3) : boolean;
begin
  Result := (a.X <> b.X) or (a.Y <> b.Y) or (a.Z <> b.Z);
end;

function RIntVector3.QuadratischeElementSumme : Integer;
begin
  Result := X * X + Y * Y + Z * Z;
end;

class operator RIntVector3.subtract(const a, b : RIntVector3) : RIntVector3;
begin
  Result.X := a.X - b.X;
  Result.Y := a.Y - b.Y;
  Result.Z := a.Z - b.Z;
end;

function RIntVector3.ToRVector3 : RVector3;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function RIntVector3.ToString : string;
begin
  Result := '(' + Inttostr(X) + ',' + Inttostr(Y) + ',' + Inttostr(Z) + ')';
end;

class function RIntVector3.ZERO : RIntVector3;
begin
  Result.X := 0;
  Result.Y := 0;
  Result.Z := 0;
end;

class operator RIntVector3.multiply(const a, b : RIntVector3) : RIntVector3;
begin
  Result.X := a.X * b.X;
  Result.Y := a.Y * b.Y;
  Result.Z := a.Z * b.Z;
end;

{ RVector2 }

class operator RVector2.add(const a, b : RVector2) : RVector2;
begin
  Result.X := a.X + b.X;
  Result.Y := a.Y + b.Y;
end;

class operator RVector2.multiply(const a : RVector2; b : Single) : RVector2;
begin
  Result.X := a.X * b;
  Result.Y := a.Y * b;
end;

class operator RVector2.multiply(a : Single; const b : RVector2) : RVector2;
begin
  Result.X := b.X * a;
  Result.Y := b.Y * a;
end;

constructor RVector2.Create(X, Y : Single);
begin
  self.X := X;
  self.Y := Y;
end;

function RVector2.Abs : RVector2;
begin
  Result.X := System.Abs(X);
  Result.Y := System.Abs(Y);
end;

class operator RVector2.add(const a : RVector2; b : Single) : RVector2;
begin
  Result.X := a.X + b;
  Result.Y := a.Y + b;
end;

class function RVector2.Clamp(const Vector, Minimum, Maximum : RVector2) : RVector2;
begin
  Result := RVector2.Min(RVector2.Max(Vector, Minimum), Maximum);
end;

function RVector2.ClampDistance(const b : RVector2; MaxDistance : Single) : RVector2;
begin
  Result := b + (self - b).SetLengthMax(MaxDistance);
end;

function RVector2.Closest(const a, b : RVector2) : RVector2;
begin
  if self.DistanceSq(a) > self.DistanceSq(b) then Result := b
  else Result := a;
end;

function RVector2.CosLerp(const Target : RVector2; s : Single) : RVector2;
var
  temp : Single;
begin
  s := HMath.Saturate(s);
  temp := (1 + Cos(s * PI)) / 2;
  Result := ((temp * self) + ((1 - temp) * Target));
end;

constructor RVector2.Create(XY : Single);
begin
  self.X := XY;
  self.Y := XY;
end;

constructor RVector2.CreateFromIniString(const Value : string);
var
  Chunks : TArray<string>;
begin
  Chunks := Value.Split(['_']);
  if not(System.Length(Chunks) > 0) or not TryStrToFloat(Chunks[0], self.X, EngineFloatFormatSettings) then
      self.X := 0;
  if not(System.Length(Chunks) > 1) or not TryStrToFloat(Chunks[1], self.Y, EngineFloatFormatSettings) then
      self.Y := 0;
end;

function RVector2.Cross(const a : RVector2) : Single;
begin
  Result := X * a.Y - Y * a.X;
end;

function RVector2.DirectionTo(const Target : RVector2) : RVector2;
begin
  Result := (Target - self).Normalize;
end;

function RVector2.Distance(const b : RVector2) : Single;
begin
  Result := (b - self).Length;
end;

function RVector2.DistanceManhattan(const b : RVector2) : Single;
begin
  Result := System.Abs(b.X - X) + System.Abs(b.Y - Y);
end;

function RVector2.DistanceSq(const b : RVector2) : Single;
begin
  Result := (b - self).LengthSq;
end;

class operator RVector2.divide(const a : RVector2; b : Single) : RVector2;
begin
  Result.X := a.X / b;
  Result.Y := a.Y / b;
end;

class operator RVector2.divide(a : Single; const b : RVector2) : RVector2;
begin
  Result.X := a / b.X;
  Result.Y := a / b.Y;
end;

class operator RVector2.divide(const a : RVector2; const b : RVector2) : RVector2;
begin
  Result.X := a.X / b.X;
  Result.Y := a.Y / b.Y;
end;

class function RVector2.EMPTY : RVector2;
begin
  Result.X := NaN;
  Result.Y := 0;
end;

class operator RVector2.equal(const a, b : RVector2) : boolean;
begin
  Result := (a.X = b.X) and (a.Y = b.Y);
end;

class operator RVector2.Explicit(a : Single) : RVector2;
begin
  Result.X := a;
  Result.Y := a;
end;

class operator RVector2.Explicit(const a : RVector2) : TPointF;
begin
  Result.X := a.X;
  Result.Y := a.Y;
end;

class operator RVector2.Explicit(const a : RVector2) : TPoint;
begin
  Result.X := System.Round(a.X);
  Result.Y := System.Round(a.Y);
end;

function RVector2.Frac : RVector2;
begin
  Result.X := System.Frac(X);
  Result.Y := System.Frac(Y);
end;

function RVector2.GetElement(Index : Integer) : Single;
begin
  Result := self.Element[index];
end;

function RVector2.GetHashValue : Integer;
begin
  Result := ((System.Round(X / 0.00001 * PRIMENUMBERS[0])) xor (System.Round(Y / 0.00001 * PRIMENUMBERS[1]))) mod MaxInt;
end;

function RVector2.GetOrthogonal : RVector2;
begin
  Result.X := -Y;
  Result.Y := X;
end;

class function RVector2.GetRandomPointInCircle(Radius : Single) : RVector2;
var
  U : Single;
begin
  U := System.Random * 2 * PI;
  if Radius < 0 then Radius := -Radius
  else Radius := System.Random * Radius;
  Result.X := Radius * Cos(U);
  Result.Y := Radius * sin(U);
end;

class operator RVector2.greaterthanorequal(const a, b : RVector2) : boolean;
begin
  Result := (a.X >= b.X) and (a.Y >= b.Y);
end;

class operator RVector2.implicit(const a : RVector2) : string;
var
  X, Y : Single;
begin
  if System.Abs(a.X) < SINGLE_ZERO_EPSILON then X := 0
  else X := a.X;
  if System.Abs(a.Y) < SINGLE_ZERO_EPSILON then Y := 0
  else Y := a.Y;
  Result := '(' + FloattostrF(X, ffGeneral, 4, 4, EngineFloatFormatSettings) + ',' + FloattostrF(Y, ffGeneral, 4, 4, EngineFloatFormatSettings) + ')';
end;

function RVector2.InnerAngle(const a : RVector2) : Single;
begin
  if (a.IsZeroVector) or (self.IsZeroVector) then Result := 0
  else Result := ArcCos(Math.Max(-1, Math.Min(1, self.Dot(a) / a.Length / Length)));
end;

function RVector2.InnerAngleOriented(const a : RVector2) : Single;
begin
  if (a.IsZeroVector) or (self.IsZeroVector) then Result := 0
  else
  begin
    Result := ArcCos(Math.Max(-1, Math.Min(1, self.Dot(a) / a.Length / Length)));
    Result := Result * Math.Sign(Cross(a));
  end;
end;

procedure RVector2.InNormalisieren;
begin
  self := Normalize;
end;

procedure RVector2.InRotieren(Winkel : Single);
begin
  self := self.Rotate(Winkel);
end;

function RVector2.IsEmpty : boolean;
begin
  Result := IsNaN(X);
end;

function RVector2.IsZeroVector : boolean;
begin
  Result := (X = 0) and (Y = 0);
end;

function RVector2.Lerp(const Target : RVector2; s : Single) : RVector2;
begin
  s := Math.Min(1, Math.Max(0, s));
  Result := (Target * s) + (self * (1 - s));
end;

class operator RVector2.lessthanorequal(const a : RVector2; b : Single) : boolean;
begin
  Result := (a.X <= b) and (a.Y <= b);
end;

class operator RVector2.lessthanorequal(const a, b : RVector2) : boolean;
begin
  Result := (a.X <= b.X) and (a.Y <= b.Y);
end;

function RVector2.Length : Single;
begin
  Result := sqrt(X * X + Y * Y);
end;

function RVector2.LengthManhattan : Single;
begin
  Result := System.Abs(X) + System.Abs(Y);
end;

function RVector2.LengthSq : Single;
begin
  Result := X * X + Y * Y;
end;

class function RVector2.Max(const a, b : RVector2) : RVector2;
begin
  Result.X := Math.Max(a.X, b.X);
  Result.Y := Math.Max(a.Y, b.Y);
end;

function RVector2.Max(const b : RVector2) : RVector2;
begin
  Result.X := Math.Max(self.X, b.X);
  Result.Y := Math.Max(self.Y, b.Y);
end;

function RVector2.Max(b : Single) : RVector2;
begin
  Result.X := Math.Max(self.X, b);
  Result.Y := Math.Max(self.Y, b);
end;

function RVector2.MaxAbsValue : Single;
begin
  Result := Math.Max(System.Abs(X), System.Abs(Y));
end;

function RVector2.MaxValue : Single;
begin
  Result := Math.Max(X, Y);
end;

class function RVector2.Min(const a, b : RVector2) : RVector2;
begin
  Result.X := Math.Min(a.X, b.X);
  Result.Y := Math.Min(a.Y, b.Y);
end;

function RVector2.MinValue : Single;
begin
  Result := Math.Min(X, Y);
end;

function RVector2.Min(const b : RVector2) : RVector2;
begin
  Result.X := Math.Min(self.X, b.X);
  Result.Y := Math.Min(self.Y, b.Y);
end;

function RVector2.Min(b : Single) : RVector2;
begin
  Result.X := Math.Min(self.X, b);
  Result.Y := Math.Min(self.Y, b);
end;

function RVector2.Mirror(const Mirror : RVector2) : RVector2;
begin
  Mirror.InNormalisieren;
  Result := self + (2 * ((Mirror * (self.Dot(Mirror))) - self));
end;

class operator RVector2.multiply(const a, b : RVector2) : RVector2;
begin
  Result.X := b.X * a.X;
  Result.Y := b.Y * a.Y;
end;

function RVector2.Negate(Dim : Integer) : RVector2;
begin
  Result := -self;
  if Dim = 0 then Result.Y := -Result.Y;
  if Dim = 1 then Result.X := -Result.X;
end;

class operator RVector2.negative(const a : RVector2) : RVector2;
begin
  Result.X := -a.X;
  Result.Y := -a.Y;
end;

function RVector2.Normalize : RVector2;
var
  s : Single;
begin
  if IsZeroVector then exit(RVector2.ZERO);
  s := Length();
  Result.X := X / s;
  Result.Y := Y / s;
end;

class operator RVector2.notequal(const a, b : RVector2) : boolean;
begin
  Result := (a.X <> b.X) or (a.Y <> b.Y);
end;

function RVector2.nXnY : RVector2;
begin
  Result.X := -X;
  Result.Y := -Y;
end;

function RVector2.nXY : RVector2;
begin
  Result.X := -X;
  Result.Y := Y;
end;

class function RVector2.ONE : RVector2;
begin
  Result.X := 1;
  Result.Y := 1;
end;

function RVector2.Orthogonalize(const b : RVector2) : RVector2;
begin
  Result := self - (b.Normalize.Dot(self) * b.Normalize);
end;

class function RVector2.Random(Jitter : Single) : RVector2;
begin
  Result.X := System.Random * Jitter;
  Result.Y := System.Random * Jitter;
end;

function RVector2.Rotate(Angle : Single) : RVector2;
begin
  Result.X := Cos(Angle) * X - sin(Angle) * Y;
  Result.Y := sin(Angle) * X + Cos(Angle) * Y;
end;

procedure RVector2.SetElement(Index : Integer; const Value : Single);
begin
  self.Element[index] := Value;
end;

function RVector2.SetLength(Length : Single) : RVector2;
begin
  Result := (self.Normalize) * Length;
end;

function RVector2.SetLengthMax(Length : Single) : RVector2;
begin
  if self.LengthSq() > sqr(Length) then Result := self.SetLength(Length)
  else Result := self;
end;

function RVector2.SetX(Wert : Single) : RVector2;
begin
  Result.X := Wert;
  Result.Y := Y;
end;

function RVector2.SetY(Wert : Single) : RVector2;
begin
  Result.X := X;
  Result.Y := Wert;
end;

function RVector2.SLerp(const Target, Center : RVector2; s : Single) : RVector2;
var
  omega, Radius : Single;
  p0, p1 : RVector2;
begin
  Radius := Math.Max(self.Distance(Center), Target.Distance(Center));
  p0 := (self - Center).Normalize;
  p1 := (Target - Center).Normalize;
  omega := ArcCos(p0.Dot(p1));
  Result := sin((1 - s) * omega) / sin(omega) * p0 + sin(s * omega) / sin(omega) * p1;
  Result := Result * Radius + Center;
end;

function RVector2.Dot(const a : RVector2) : Single;
begin
  Result := a.X * X + a.Y * Y;
end;

class operator RVector2.subtract(const a : RVector2; b : Single) : RVector2;
begin
  Result.X := a.X - b;
  Result.Y := a.Y - b;
end;

function RVector2.ToIniString : string;
begin
  Result := FloattostrF(self.X, ffGeneral, 4, 4, EngineFloatFormatSettings) + '_' + FloattostrF(self.Y, ffGeneral, 4, 4, EngineFloatFormatSettings);
end;

class operator RVector2.subtract(const a, b : RVector2) : RVector2;
begin
  Result.X := a.X - b.X;
  Result.Y := a.Y - b.Y;
end;

function RVector2Helper.Round : RIntVector2;
begin
  Result.X := System.Round(X);
  Result.Y := System.Round(Y);
end;

function RVector2Helper.Trunc : RIntVector2;
begin
  Result.X := System.Trunc(X);
  Result.Y := System.Trunc(Y);
end;

class function RVector2.UNITX : RVector2;
begin
  Result.X := 1;
  Result.Y := 0;
end;

class function RVector2.UNITY : RVector2;
begin
  Result.X := 0;
  Result.Y := 1;
end;

function RVector2.XnY : RVector2;
begin
  Result.X := X;
  Result.Y := -Y;
end;

function RVector2.YZ : RVector2;
begin
  Result.X := Y;
  Result.Y := X;
end;

class function RVector2.ZERO : RVector2;
begin
  Result.X := 0;
  Result.Y := 0;
end;

function RVector2.Sign : RVector2;
begin
  Result.X := Math.Sign(X);
  Result.Y := Math.Sign(Y);
end;

function RVector2.SimilarTo(const b : RVector2; Epsilon : Single) : boolean;
begin
  Result := (System.Abs(self.X - b.X) < Epsilon) and (System.Abs(self.Y - b.Y) < Epsilon);
end;

class operator RVector2.implicit(a : TPointF) : RVector2;
begin
  Result.X := a.X;
  Result.Y := a.Y;
end;

{ RVector4 }

function RVector4.Abs : RVector4;
begin
  Result.X := System.Abs(X);
  Result.Y := System.Abs(Y);
  Result.Z := System.Abs(Z);
  Result.W := System.Abs(W);
end;

class operator RVector4.add(const a, b : RVector4) : RVector4;
begin
  Result.X := a.X + b.X;
  Result.Y := a.Y + b.Y;
  Result.Z := a.Z + b.Z;
  Result.W := a.W + b.W;
end;

constructor RVector4.Create(const XYZW : Single);
begin
  X := XYZW;
  Y := XYZW;
  Z := XYZW;
  W := XYZW;
end;

class operator RVector4.divide(const a : RVector4; b : Single) : RVector4;
begin
  Result.X := a.X / b;
  Result.Y := a.Y / b;
  Result.Z := a.Z / b;
  Result.W := a.W / b;
end;

constructor RVector4.Create(const XY, ZW : RVector2);
begin
  self.X := XY.X;
  self.Y := XY.Y;
  self.Z := ZW.X;
  self.W := ZW.Y;
end;

function RVector4.Dot(const b : RVector4) : Single;
begin
  Result := X * b.X + Y * b.Y + Z * b.Z + W * b.W;
end;

class operator RVector4.equal(const a, b : RVector4) : boolean;
begin
  Result := (a.X = b.X) and (a.Y = b.Y) and (a.Z = b.Z) and (a.W = b.W);
end;

class operator RVector4.Explicit(a : Single) : RVector4;
begin
  Result.X := a;
  Result.Y := a;
  Result.Z := a;
  Result.W := a;
end;

class operator RVector4.add(const a : RVector4; b : Single) : RVector4;
begin
  Result.X := a.X + b;
  Result.Y := a.Y + b;
  Result.Z := a.Z + b;
  Result.W := a.W + b;
end;

constructor RVector4.Create(X, Y, Z, W : Single);
begin
  self.X := X;
  self.Y := Y;
  self.Z := Z;
  self.W := W;
end;

constructor RVector4.Create(const vec : RVector3; W : Single = 0.0);
begin
  X := vec.X;
  Y := vec.Y;
  Z := vec.Z;
  self.W := W;
end;

function RVector4.IsZero : boolean;
begin
  Result := (X = 0) and (Y = 0) and (Z = 0) and (W = 0);
end;

function RVector4.Length : Single;
begin
  Result := sqrt(X * X + Y * Y + Z * Z + W * W);
end;

function RVector4.Lerp(const Target : RVector4; s : Single) : RVector4;
begin
  Result.X := self.X * (1 - s) + Target.X * s;
  Result.Y := self.Y * (1 - s) + Target.Y * s;
  Result.Z := self.Z * (1 - s) + Target.Z * s;
  Result.W := self.W * (1 - s) + Target.W * s;
end;

function RVector4.MaxAbsValue : Single;
begin
  Result := Max(System.Abs(X), Max(System.Abs(Y), Max(System.Abs(Z), System.Abs(W))));
end;

function RVector4.MaxValue : Single;
begin
  Result := Max(X, Max(Y, Max(Z, W)));
end;

function RVector4.MinValue : Single;
begin
  Result := Min(X, Min(Y, Min(Z, W)));
end;

class operator RVector4.multiply(a : Single; const b : RVector4) : RVector4;
begin
  Result.X := b.X * a;
  Result.Y := b.Y * a;
  Result.Z := b.Z * a;
  Result.W := b.W * a;
end;

function RVector4.Normalize : RVector4;
var
  s : Single;
begin
  s := Length;
  if s = 0 then exit(RVector4.ZERO);
  Result.X := X / s;
  Result.Y := Y / s;
  Result.Z := Z / s;
  Result.W := W / s;
end;

class operator RVector4.notequal(const a, b : RVector4) : boolean;
begin
  Result := (a.X <> b.X) or (a.Y <> b.Y) or (a.Z <> b.Z) or (a.W <> b.W);
end;

function RVector4.SetW(Value : Single) : RVector4;
begin
  Result := RVector4.Create(X, Y, Z, Value);
end;

function RVector4.SimilarTo(const b : RVector4; Epsilon : Single) : boolean;
begin
  Result := (System.Abs(X - b.X) <= Epsilon) and (System.Abs(Y - b.Y) <= Epsilon) and (System.Abs(Z - b.Z) <= Epsilon) and (System.Abs(W - b.W) <= Epsilon);
end;

function RVector4.SLerp(const Target : RVector4; s : Single) : RVector4;
var
  q1, q2 : RQuaternion;
  Dot, om, sinom, scale0, scale1 : Single;
begin
  q1 := self.Normalize;
  q2 := Target.Normalize;

  Dot := q1.Dot(q2);;

  if Dot < 0 then
  begin
    q2 := -q2;
    Dot := -Dot;
  end;

  if (1.0 - Dot) > 0.00001 then
  begin
    om := ArcCos(Dot);
    sinom := sin(Dot);
    scale0 := sin((1.0 - s) * om) / sinom;
    scale1 := sin(s * om) / sinom;
  end
  else
  begin
    scale0 := 1.0 - s;
    scale1 := s;
  end;

  Result := ((scale0 * q1) + (scale1 * q2)).Normalize;
end;

class operator RVector4.implicit(const a : RVector4) : string;
begin
  Result := '(' + FloattostrF(a.X, ffGeneral, 4, 4, EngineFloatFormatSettings) + ',' + FloattostrF(a.Y, ffGeneral, 4, 4, EngineFloatFormatSettings) + ',' + FloattostrF(a.Z, ffGeneral, 4, 4, EngineFloatFormatSettings) + ',' + FloattostrF(a.W, ffGeneral, 4, 4, EngineFloatFormatSettings) + ')';
end;

class operator RVector4.multiply(const a : RVector4; b : Single) : RVector4;
begin
  Result.X := a.X * b;
  Result.Y := a.Y * b;
  Result.Z := a.Z * b;
  Result.W := a.W * b;
end;

class operator RVector4.subtract(const a, b : RVector4) : RVector4;
begin
  Result.X := a.X - b.X;
  Result.Y := a.Y - b.Y;
  Result.Z := a.Z - b.Z;
  Result.W := a.W - b.W;
end;

class operator RVector4.subtract(const a : RVector4; b : Single) : RVector4;
begin
  Result.X := a.X - b;
  Result.Y := a.Y - b;
  Result.Z := a.Z - b;
  Result.W := a.W - b;
end;

function RVector4.Sum : Single;
begin
  Result := X + Y + Z + W;
end;

function RVector4.Unproject : RVector3;
begin
  if W = 0 then exit(RVector3.ZERO);
  Result.X := X / W;
  Result.Y := Y / W;
  Result.Z := Z / W;
end;

function RVector4.WXYZ : RVector4;
begin
  Result.X := W;
  Result.Y := X;
  Result.Z := Y;
  Result.W := Z;
end;

class function RVector4.ZERO : RVector4;
begin
  Result.X := 0;
  Result.Y := 0;
  Result.Z := 0;
  Result.W := 0;
end;

function RVector4.ZYXW : RVector4;
begin
  Result.X := Z;
  Result.Y := Y;
  Result.Z := X;
  Result.W := W;
end;

class operator RVector4.multiply(const a, b : RVector4) : RVector4;
begin
  Result.X := a.X * b.X;
  Result.Y := a.Y * b.Y;
  Result.Z := a.Z * b.Z;
  Result.W := a.W * b.W;
end;

class operator RVector4.negative(const a : RVector4) : RVector4;
begin
  Result.X := -a.X;
  Result.Y := -a.Y;
  Result.Z := -a.Z;
  Result.W := -a.W;
end;

{ HMathe }

class function HMath.Clamp(Wert, UntereGrenze, ObereGrenze : Single) : Single;
begin
  if Wert < UntereGrenze then
      Result := UntereGrenze
  else if Wert > ObereGrenze then
      Result := ObereGrenze
  else
      Result := Wert;
end;

class function HMath.Clamp(Wert, UntereGrenze, ObereGrenze : Integer) : Integer;
begin
  if Wert < UntereGrenze then
      Result := UntereGrenze
  else if Wert > ObereGrenze then
      Result := ObereGrenze
  else
      Result := Wert;
end;

class function HMath.Clamp(Wert, UntereGrenze, ObereGrenze : Int64) : Int64;
begin
  if Wert < UntereGrenze then
      Result := UntereGrenze
  else if Wert > ObereGrenze then
      Result := ObereGrenze
  else
      Result := Wert;
end;

class function HMath.CosLerpF(X, Y, s : Single) : Single;
var
  temp : Single;
begin
  temp := (1 + Cos(s * PI)) / 2;
  Result := (temp * X + (1 - temp) * Y);
end;

class function HMath.Eval(str : string) : Single;
  function Split(const str : string; Del : array of char) : TArray<string>;
  var
    i, j, c : Integer;
    deli : boolean;
  begin
    c := 0;
    SetLength(Result, 1);
    Result[c] := '';
    deli := false;
    for i := 1 to Length(str) do
    begin
      for j := 0 to Length(Del) - 1 do
        if Del[j] = str[i] then
        begin
          inc(c);
          SetLength(Result, Length(Result) + 1);
          deli := true;
          break;
        end;
      Result[c] := Result[c] + str[i];
      if deli then
      begin
        inc(c);
        SetLength(Result, Length(Result) + 1);
      end;
      deli := false;
    end;
  end;

var
  splitted : TArray<string>;
  i : Integer;
  operation : byte;
  operand : double;
begin
  Result := 0;
  splitted := nil;
  str := str.Replace('.', FormatSettings.DecimalSeparator).Replace(',', FormatSettings.DecimalSeparator);
  splitted := Split(str, ['+', '-', '/', '*']);
  operation := 0;
  operand := 0;
  for i := 0 to Length(splitted) - 1 do
  begin
    if i mod 2 = 1 then
    begin
      if (splitted[i] = '+') then operation := 1
      else if (splitted[i] = '-') then operation := 2
      else if (splitted[i] = '*') then operation := 3
      else if (splitted[i] = '/') then operation := 4
      else operation := 0;
      continue;
    end;
    if not TextToFloat(splitted[i], operand) then continue;
    case operation of
      0 : Result := operand;
      1 : Result := Result + operand;
      2 : Result := Result - operand;
      3 : Result := Result * operand;
      4 : Result := Result / operand;
    end;
    operation := 0;
  end;
end;

class function HMath.fMod(const Value, Modulo : Single) : Single;
begin
  Result := Value - Trunc(Value / Modulo) * Modulo;
end;

class function HMath.HasRepeatedDigits(Number : Integer) : boolean;
var
  checker : Int64;
begin
  checker := 0;
  // go through all digits and compare them against an array of booleans packed in an two-byte binary
  while Number > 0 do
  begin
    if (checker and (1 shl (Number mod 10))) <> 0 then exit(true);
    checker := checker or (1 shl (Number mod 10));
    Number := Number div 10;
  end;
  Result := false;
end;

class function HMath.inRange(Value, lowerBound, upperBound : Single) : boolean;
begin
  Result := (lowerBound <= Value) and (Value <= upperBound);
end;

class function HMath.Interpolate(const TimeKeys : array of RTuple<Integer, RVector3>; Progress : Single; InterpolationMode : EnumInterpolationMode; TimeRange : Integer) : RVector3;
var
  localFactor : Single;
  StartValue, EndValue : RVector3;
begin
  if Length(TimeKeys) <= 0 then exit(RVector3.ZERO);
  if Length(TimeKeys) = 1 then exit(TimeKeys[0].b);
  GetInterpolationKeys<RVector3>(TimeKeys, Progress, TimeRange, StartValue, EndValue, localFactor);
  case InterpolationMode of
    imLinear : Result := StartValue.Lerp(EndValue, localFactor);
    imCosinus : Result := StartValue.CosLerp(EndValue, localFactor);
  else
    raise ENotImplemented.Create('HMath.Interpolate: Unimplemented interpolation mode!');
  end;
end;

class function HMath.Interpolate(const Values : array of RVector2; Progress : Single; InterpolationMode : EnumInterpolationMode) : RVector2;
var
  localFactor : Single;
  prevIndex, nextIndex : Integer;
begin
  if Length(Values) <= 0 then exit(RVector2.ZERO);
  GetInterpolationIndices(Length(Values), Progress, prevIndex, nextIndex, localFactor);
  case InterpolationMode of
    imLinear : Result := Values[prevIndex].Lerp(Values[nextIndex], localFactor);
    imCosinus : Result := Values[prevIndex].CosLerp(Values[nextIndex], localFactor);
  else
    raise ENotImplemented.Create('HMath.Lerp: Unimplemented interpolation mode!');
  end;
end;

class function HMath.Interpolate(const TimeKeys : array of RTuple<Integer, RVector2>; Progress : Single; InterpolationMode : EnumInterpolationMode; TimeRange : Integer) : RVector2;
var
  localFactor : Single;
  StartValue, EndValue : RVector2;
begin
  if Length(TimeKeys) <= 0 then exit(RVector2.ZERO);
  if Length(TimeKeys) = 1 then exit(TimeKeys[0].b);
  GetInterpolationKeys<RVector2>(TimeKeys, Progress, TimeRange, StartValue, EndValue, localFactor);
  case InterpolationMode of
    imLinear : Result := StartValue.Lerp(EndValue, localFactor);
    imCosinus : Result := StartValue.CosLerp(EndValue, localFactor);
  else
    raise ENotImplemented.Create('HMath.Interpolate: Unimplemented interpolation mode!');
  end;
end;

class function HMath.Interpolate(const TimeKeys : array of RTuple<Integer, Single>; Progress : Single; InterpolationMode : EnumInterpolationMode; TimeRange : Integer) : Single;
var
  localFactor : Single;
  StartValue, EndValue : Single;
begin
  if Length(TimeKeys) <= 0 then exit(0.0);
  if Length(TimeKeys) = 1 then exit(TimeKeys[0].b);
  GetInterpolationKeys<Single>(TimeKeys, Progress, TimeRange, StartValue, EndValue, localFactor);
  case InterpolationMode of
    imLinear : Result := HMath.LinLerpF(StartValue, EndValue, localFactor);
    imCosinus : Result := HMath.CosLerpF(StartValue, EndValue, localFactor);
  else
    raise ENotImplemented.Create('HMath.Interpolate: Unimplemented interpolation mode!');
  end;
end;

class procedure HMath.GetInterpolationIndices(ArrayLength : Integer; Progress : Single; out startIndex, endIndex : Integer; out localFactor : Single);
var
  maxIndex, prevIndex, nextIndex : Integer;
begin
  startIndex := 0;
  endIndex := 0;
  localFactor := 0.0;
  maxIndex := ArrayLength - 1;
  if maxIndex <= 0 then exit;

  Progress := HMath.Saturate(Progress);
  prevIndex := HMath.Clamp(Trunc(Progress * maxIndex), 0, maxIndex);
  nextIndex := HMath.Clamp(prevIndex + 1, 0, maxIndex);

  startIndex := prevIndex;
  endIndex := nextIndex;
  if prevIndex <> nextIndex then localFactor := (Progress - prevIndex / maxIndex) / (nextIndex / maxIndex - prevIndex / maxIndex);
end;

class procedure HMath.GetInterpolationKeys<T>(const TimeKeys : array of RTuple<Integer, T>; Progress : Single; TimeRange : Integer; out StartValue, EndValue : T; out localFactor : Single);
var
  TimeSpan, i : Integer;
  CurrentTime : Single;
  startIndex, endIndex : Integer;
begin
  assert(Length(TimeKeys) > 0);
  TimeSpan := TimeKeys[high(TimeKeys)].a;
  if TimeRange > 0 then CurrentTime := HMath.Saturate(Progress) * TimeRange
  else CurrentTime := HMath.Saturate(Progress) * TimeSpan;
  for i := Length(TimeKeys) - 1 downto 0 do
    if CurrentTime > TimeKeys[i].a then
    begin
      startIndex := i;
      endIndex := Min(i + 1, Length(TimeKeys) - 1);
      if startIndex = endIndex then localFactor := 0.0
      else localFactor := (CurrentTime - TimeKeys[startIndex].a) / (TimeKeys[endIndex].a - TimeKeys[startIndex].a);
      StartValue := TimeKeys[startIndex].b;
      EndValue := TimeKeys[endIndex].b;
      exit;
    end;
  // if we reach this point, the TimeKeys must be corrupt
  assert(false);
end;

class function HMath.Interpolate(const Values : array of RVector3; Progress : Single; InterpolationMode : EnumInterpolationMode) : RVector3;
var
  localFactor : Single;
  prevIndex, nextIndex : Integer;
begin
  if Length(Values) <= 0 then exit(RVector3.ZERO);
  GetInterpolationIndices(Length(Values), Progress, prevIndex, nextIndex, localFactor);
  case InterpolationMode of
    imLinear : Result := Values[prevIndex].Lerp(Values[nextIndex], localFactor);
    imCosinus : Result := Values[prevIndex].CosLerp(Values[nextIndex], localFactor);
  else
    raise ENotImplemented.Create('HMath.Lerp: Unimplemented interpolation mode!');
  end;
end;

class function HMath.Interpolate(const Values : array of Single; Progress : Single; InterpolationMode : EnumInterpolationMode) : Single;
var
  localFactor : Single;
  prevIndex, nextIndex : Integer;
begin
  if Length(Values) <= 0 then exit(0.0);
  GetInterpolationIndices(Length(Values), Progress, prevIndex, nextIndex, localFactor);
  case InterpolationMode of
    imLinear : Result := HMath.LinLerpF(Values[prevIndex], Values[nextIndex], localFactor);
    imCosinus : Result := HMath.CosLerpF(Values[prevIndex], Values[nextIndex], localFactor);
  else
    raise ENotImplemented.Create('HMath.Lerp: Unimplemented interpolation mode!');
  end;
end;

class function HMath.iSqrt(const Value : Single) : Integer;
begin
  Result := Trunc(sqrt(Value));
end;

class function HMath.LinLerpF(X, Y, s : Single) : Single;
begin
  Result := X * (1 - s) + Y * s;
end;

class function HMath.Log2Ceil(X : Single) : Integer;
var
  i2 : Cardinal;
begin
  Result := 0;
  i2 := 1;
  while (i2 < X) do
  begin
    i2 := i2 shl 1;
    inc(Result);
  end;
end;

class function HMath.Log2Floor(X : Integer) : Integer;
begin
  Result := 0;
  while (X > 1) do
  begin
    X := X shr 1; // equal to div 2, but slightly faster
    inc(Result);
  end;
end;

class function HMath.inRange(Value, lowerBound, upperBound : Integer) : boolean;
begin
  Result := (lowerBound <= Value) and (Value <= upperBound);
end;

class function HMath.Saturate(Wert : Single) : Single;
begin
  Result := Clamp(Wert, 0, 1);
end;

{ RVector3 }

function RVector3.Abs : RVector3;
begin
  Result.X := System.Abs(X);
  Result.Y := System.Abs(Y);
  Result.Z := System.Abs(Z);
end;

class operator RVector3.add(const a, b : RVector3) : RVector3;
begin
  Result.X := a.X + b.X;
  Result.Y := a.Y + b.Y;
  Result.Z := a.Z + b.Z;
end;

class operator RVector3.divide(const a : RVector3; b : Single) : RVector3;
begin
  Result.X := a.X / b;
  Result.Y := a.Y / b;
  Result.Z := a.Z / b;
end;

function RVector3.SetLengthMax(Length : Single) : RVector3;
begin
  if self.LengthSq() > sqr(Length) then Result := self.SetLength(Length)
  else Result := self;
end;

function RVector3.SetLengthMin(Length : Single) : RVector3;
begin
  if self.LengthSq() < sqr(Length) then Result := self.SetLength(Length)
  else Result := self;
end;

function RVector3.SetDim(Dim : Integer; Wert : Single) : RVector3;
begin
  assert((Dim >= 0) and (Dim <= 2), 'RVector3.SetDim: Only 3 dimensions are available!');
  Result := self;
  Result.Element[Dim] := Wert;
end;

function RVector3.SetLength(Length : Single) : RVector3;
begin
  Result := (self.Normalize) * Length;
end;

function RVector3.SetX(Value : Single) : RVector3;
begin
  Result.X := Value;
  Result.Y := Y;
  Result.Z := Z;
end;

procedure RVector3.setXZ(const Value : RVector2);
begin
  X := Value.X;
  Z := Value.Y;
end;

function RVector3.SetY(Value : Single) : RVector3;
begin
  Result.X := X;
  Result.Y := Value;
  Result.Z := Z;
end;

function RVector3.SetYZ(Value : RVector2) : RVector3;
begin
  Result.X := X;
  Result.Y := Value.X;
  Result.Z := Value.Y;
end;

function RVector3.SetZ(Value : Single) : RVector3;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Value;
end;

constructor RVector3.Create(X, Y, Z : Single);
begin
  self.X := X;
  self.Y := Y;
  self.Z := Z;
end;

class function RVector3.BaryCentric(const v1, v2, v3 : RVector3; f, g : Single) : RVector3;
begin
  Result.X := v1.X + (f * (v2.X - v1.X)) + (g * (v3.X - v1.X));
  Result.Y := v1.Y + (f * (v2.Y - v1.Y)) + (g * (v3.Y - v1.Y));
  Result.Z := v1.Z + (f * (v2.Z - v1.Z)) + (g * (v3.Z - v1.Z));
end;

constructor RVector3.Create(XYZ : Single);
begin
  self.X := XYZ;
  self.Y := XYZ;
  self.Z := XYZ;
end;

function RVector3.DirectionTo(const Target : RVector3) : RVector3;
begin
  Result := (Target - self).Normalize;
end;

function RVector3.Distance(const b : RVector3) : Single;
begin
  Result := sqrt(sqr(b.X - X) + sqr(b.Y - Y) + sqr(b.Z - Z));
end;

function RVector3.DistanceXZ(const b : RVector3) : Single;
begin
  Result := sqrt(sqr(b.X - X) + sqr(b.Z - Z));
end;

class operator RVector3.divide(const a, b : RVector3) : RVector3;
begin
  Result.X := a.X / b.X;
  Result.Y := a.Y / b.Y;
  Result.Z := a.Z / b.Z;
end;

function RVector3.Dot(const b : RVector3) : Single;
begin
  Result := (X * b.X + Y * b.Y + Z * b.Z);
end;

class operator RVector3.equal(const a, b : RVector3) : boolean;
begin
  Result := (a.X = b.X) and (a.Y = b.Y) and (a.Z = b.Z);
end;

class operator RVector3.Explicit(a : Single) : RVector3;
begin
  Result.X := a;
  Result.Y := a;
  Result.Z := a;
end;

function RVector3.Frac : RVector3;
begin
  Result.X := System.Frac(X);
  Result.Y := System.Frac(Y);
  Result.Z := System.Frac(Z);
end;

function RVector3.GetArbitaryOrthogonalVector : RVector3;
begin
  Result := self.Cross(RVector3.UNITY).Normalize;
  if Result.IsZeroVector then Result := self.Cross(RVector3.UNITX).Normalize;
end;

function RVector3.GetHashValue : Integer;
begin
  Result := ((System.Round(X / 0.00001 * PRIMENUMBERS[0])) xor (System.Round(Y / 0.00001 * PRIMENUMBERS[1])) xor (System.Round(Z / 0.00001 * PRIMENUMBERS[2]))) mod MaxInt;
end;

class function RVector3.getRandomPointInSphere(Radius : Single; UpperConstraint : Single; LowerConstraint : Single) : RVector3;
var
  U, V : Single;
begin
  U := System.Random * 2 * PI;
  V := System.Random * (PI - UpperConstraint - LowerConstraint) + LowerConstraint - PI / 2;
  if Radius < 0 then Radius := -Radius
  else Radius := System.Random * Radius;
  Result.X := Radius * Cos(U) * Cos(V);
  Result.Y := Radius * Cos(U) * sin(V);
  Result.Z := Radius * sin(U);
end;

class operator RVector3.GreaterThan(const a, b : RVector3) : boolean;
begin
  Result := (a.X > b.X) and (a.Y > b.Y) and (a.Z > b.Z);
end;

class operator RVector3.greaterthanorequal(const a, b : RVector3) : boolean;
begin
  Result := (a.X >= b.X) and (a.Y >= b.Y) and (a.Z >= b.Z);
end;

class operator RVector3.implicit(const a : RVector3) : string;
var
  X, Y, Z : Single;
begin
  if System.Abs(a.X) < SINGLE_ZERO_EPSILON then X := 0
  else X := a.X;
  if System.Abs(a.Y) < SINGLE_ZERO_EPSILON then Y := 0
  else Y := a.Y;
  if System.Abs(a.Z) < SINGLE_ZERO_EPSILON then Z := 0
  else Z := a.Z;
  Result := '(' + FloattostrF(X, ffGeneral, 4, 4, EngineFloatFormatSettings) + ',' + FloattostrF(Y, ffGeneral, 4, 4, EngineFloatFormatSettings) + ',' + FloattostrF(Z, ffGeneral, 4, 4, EngineFloatFormatSettings) + ')';
end;

procedure RVector3.InNormalize;
begin
  self := Normalize;
end;

procedure RVector3.InNormalize(Base : Single);
begin
  self := Normalize(Base);
end;

procedure RVector3.InRotateAxis(const Axis : RVector3; Angle : Single);
begin
  self := RotateAxis(Axis, Angle)
end;

procedure RVector3.InRotatePitchYawRoll(Pitch, Yaw, Roll : Single);
begin
  self := RotatePitchYawRoll(Pitch, Yaw, Roll)
end;

procedure RVector3.InSetLength(Length : Single);
begin
  self := SetLength(Length);
end;

function RVector3.ToPolar : RVector3;
var
  temp : RVector3;
begin
  temp := self;
  Result := RVector3.ZERO;
  Result.Z := temp.Length;
  if Result.Z = 0 then exit;
  Result.Y := -Math.ArcTan2(X, Z);
  Result.X := (PI / 2 - Math.ArcCos(Y / Result.Z));
end;

procedure RVector3.InSetPolar(const Value : RVector3);
begin
  self := RVector3.UNITZ.RotatePitchYawRoll(Value.X, Value.Y, 0);
  self := self * Value.Z;
end;

function RVector3.IsEmpty : boolean;
begin
  Result := IsNaN(X);
end;

function RVector3.IsZeroVector : boolean;
begin
  Result := (X = 0) and (Y = 0) and (Z = 0);
end;

function RVector3.Cross(const b : RVector3) : RVector3;
begin
  Result.X := Y * b.Z - Z * b.Y;
  Result.Y := Z * b.X - X * b.Z;
  Result.Z := X * b.Y - Y * b.X;
end;

function RVector3.Lerp(const Target : RVector3; s : Single) : RVector3;
begin
  Result.X := self.X * (1 - s) + Target.X * s;
  Result.Y := self.Y * (1 - s) + Target.Y * s;
  Result.Z := self.Z * (1 - s) + Target.Z * s;
end;

class operator RVector3.LessThan(const a, b : RVector3) : boolean;
begin
  Result := (a.X < b.X) and (a.Y < b.Y) and (a.Z < b.Z);
end;

class operator RVector3.lessthanorequal(const a, b : RVector3) : boolean;
begin
  Result := (a.X <= b.X) and (a.Y <= b.Y) and (a.Z <= b.Z);
end;

function RVector3.GetLength : Single;
begin
  Result := sqrt(X * X + Y * Y + Z * Z);
end;

function RVector3.LengthSq : Single;
begin
  Result := X * X + Y * Y + Z * Z;
end;

function RVector3.MaxEachComponent(const b : RVector3) : RVector3;
begin
  Result.X := Math.Max(X, b.X);
  Result.Y := Math.Max(Y, b.Y);
  Result.Z := Math.Max(Z, b.Z);
end;

function RVector3.MaxAbsDimension : Integer;
begin
  if System.Abs(X) > System.Abs(Y) then
  begin
    if System.Abs(X) > System.Abs(Z) then Result := 0
    else Result := 2;
  end
  else
    if System.Abs(Y) > System.Abs(Z) then Result := 1
  else Result := 2;
end;

function RVector3.MaxAbsValue : Single;
begin
  if System.Abs(X) > System.Abs(Y) then
  begin
    if System.Abs(X) > System.Abs(Z) then Result := System.Abs(X)
    else Result := System.Abs(Z);
  end
  else
    if System.Abs(Y) > System.Abs(Z) then Result := System.Abs(Y)
  else Result := System.Abs(Z);
end;

function RVector3.MaxValue : Single;
begin
  if X > Y then
  begin
    if X > Z then Result := X
    else Result := Z;
  end
  else
    if Y > Z then Result := Y
  else Result := Z;
end;

function RVector3.MinEachComponent(const b : RVector3) : RVector3;
begin
  Result.X := Min(X, b.X);
  Result.Y := Min(Y, b.Y);
  Result.Z := Min(Z, b.Z);
end;

function RVector3.MinValue : Single;
begin
  Result := Min(X, Min(Y, Z));
end;

class operator RVector3.multiply(const a : RVector3; b : Single) : RVector3;
begin
  Result.X := a.X * b;
  Result.Y := a.Y * b;
  Result.Z := a.Z * b;
end;

class operator RVector3.multiply(a : Single; const b : RVector3) : RVector3;
begin
  Result.X := b.X * a;
  Result.Y := b.Y * a;
  Result.Z := b.Z * a;
end;

function RVector3.NegateDim(Dim : Integer) : RVector3;
begin
  Result := self;
  Result.Element[Dim] := -Result.Element[Dim];
end;

function RVector3.NegateY : RVector3;
begin
  Result.X := X;
  Result.Y := -Y;
  Result.Z := Z;
end;

class operator RVector3.negative(const a : RVector3) : RVector3;
begin
  Result.X := -a.X;
  Result.Y := -a.Y;
  Result.Z := -a.Z;
end;

function RVector3.Normalize(Base : Single) : RVector3;
var
  s : Single;
begin
  if IsZeroVector then exit(RVector3.ZERO);
  s := Power((Power(System.Abs(X), Base) + Power(System.Abs(Y), Base) + Power(System.Abs(Z), Base)), 1 / Base);
  Result.X := X / s;
  Result.Y := Y / s;
  Result.Z := Z / s;
end;

function RVector3.Normalize : RVector3;
var
  s : Single;
begin
  if IsZeroVector then exit(RVector3.ZERO);
  s := Length;
  Result.X := X / s;
  Result.Y := Y / s;
  Result.Z := Z / s;
end;

class operator RVector3.notequal(const a, b : RVector3) : boolean;
begin
  Result := (a.X <> b.X) or (a.Y <> b.Y) or (a.Z <> b.Z);
end;

function RVector3.Orthogonalize(const b : RVector3) : RVector3;
begin
  Result := self - (b.Normalize.Dot(self) * b);
end;

class function RVector3.Random : RVector3;
begin
  Result.X := System.Random;
  Result.Y := System.Random;
  Result.Z := System.Random;
end;

class function RVector3.RandomFromDisk(const Diskposition, Disknormal : RVector3; Diskradius : Single) : RVector3;
var
  Diskleft : RVector3;
begin
  if Disknormal = RVector3.UNITY then Diskleft := RVector3.UNITX
  else Diskleft := Disknormal.Normalize.Cross(RVector3.UNITY);
  Result := (Diskleft * (Diskradius * Cos(System.Random * PI))).RotateAxis(Disknormal, System.Random * 2 * PI) + Diskposition;
end;

function RVector3.RotateAroundPoint(const Point : RVector3; Pitch, Yaw, Roll : Single) : RVector3;
begin
  Result := self - Point;
  Result := Result.RotatePitchYawRoll(Pitch, Yaw, Roll);
  Result := Result + Point;
end;

function RVector3.RotateAroundPoint(const Point, PitchYawRoll : RVector3) : RVector3;
begin
  Result := RotateAroundPoint(Point, PitchYawRoll.X, PitchYawRoll.Y, PitchYawRoll.Z);
end;

function RVector3.RotateAxis(const Axis : RVector3; Angle : Single) : RVector3;
var
  normAxis : RVector3;
  cosA : Single;
begin
  // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
  normAxis := Axis.Normalize;
  cosA := Cos(Angle);
  Result := (self * cosA) + (normAxis.Cross(self) * sin(Angle)) + (normAxis * normAxis.Dot(self) * (1 - cosA));
end;

function RVector3.RotatePitchYawRoll(const PitchYawRoll : RVector3) : RVector3;
begin
  Result := RotatePitchYawRoll(PitchYawRoll.X, PitchYawRoll.Y, PitchYawRoll.Z);
end;

function RVector3.Round : RVector3;
begin
  Result.X := System.Round(X);
  Result.Y := System.Round(Y);
  Result.Z := System.Round(Z);
end;

function RVector3.RotatePitchYawRoll(Pitch, Yaw, Roll : Single) : RVector3;
begin
  Result := RMatrix.CreateRotationPitchYawRoll(Pitch, Yaw, Roll) * self;
end;

class operator RVector3.subtract(const a : RVector3; b : Single) : RVector3;
begin
  Result.X := a.X - b;
  Result.Y := a.Y - b;
  Result.Z := a.Z - b;
end;

function RVector3.Sum : Single;
begin
  Result := X + Y + Z;
end;

function RVector3.ToBaryCentric(tri1, tri2, tri3 : RVector3) : RVector3;
var
  temp : RVector3;
  d00, d01, d11, d20, d21, denom : Single;
begin
  temp := tri1;
  tri1 := tri2 - temp;
  tri2 := tri3 - temp;
  tri3 := self - temp;
  d00 := tri1.Dot(tri1);
  d01 := tri1.Dot(tri2);
  d11 := tri2.Dot(tri2);
  d20 := tri3.Dot(tri1);
  d21 := tri3.Dot(tri2);
  denom := d00 * d11 - d01 * d01;
  if denom = 0 then exit(RVector3.Create(1, 0, 0));
  Result.Y := (d11 * d20 - d01 * d21) / denom;
  Result.Z := (d00 * d21 - d01 * d20) / denom;
  Result.X := 1.0 - Result.X - Result.Y;
end;

function RVector3.ToIniString : string;
begin
  Result := FloattostrF(self.X, ffGeneral, 4, 4, EngineFloatFormatSettings) + '_' + FloattostrF(self.Y, ffGeneral, 4, 4, EngineFloatFormatSettings) + '_' + FloattostrF(self.Z, ffGeneral, 4, 4, EngineFloatFormatSettings);
end;

function RVector3.Trunc : RVector3;
begin
  Result.X := System.Trunc(X);
  Result.Y := System.Trunc(Y);
  Result.Z := System.Trunc(Z);
end;

class function RVector3.TryFromString(str : string; out Vector : RVector3) : boolean;
var
  data : TArray<string>;
begin
  str := str.Replace('(', '').Replace(')', '');
  data := str.Split([',']);
  Result := (System.Length(data) = 3) and TryStrToFloat(data[0], Vector.X, EngineFloatFormatSettings) and TryStrToFloat(data[1], Vector.Y, EngineFloatFormatSettings) and TryStrToFloat(data[2], Vector.Z, EngineFloatFormatSettings);
end;

function RVector3.X0Z : RVector3;
begin
  Result.X := X;
  Result.Y := 0;
  Result.Z := Z;
end;

function RVector3.XYZ : RVector3;
begin
  Result := RVector3.Create(X, Y, Z);
end;

function RVector3.getXZ : RVector2;
begin
  Result := RVector2.Create(X, Z);
end;

function RVector3.XZY : RVector3;
begin
  Result := RVector3.Create(X, Z, Y);
end;

function RVector3.YXZ : RVector3;
begin
  Result := RVector3.Create(Y, X, Z);
end;

function RVector3.YZ : RVector2;
begin
  Result := RVector2.Create(Y, Z);
end;

function RVector3.YZX : RVector3;
begin
  Result := RVector3.Create(Y, Z, X);
end;

class operator RVector3.add(const a : RVector3; b : Single) : RVector3;
begin
  Result.X := a.X + b;
  Result.Y := a.Y + b;
  Result.Z := a.Z + b;
end;

function RVector3.AngleBetween(const b : RVector3) : Single;
begin
  Result := ArcCos(Math.Min(1, Math.Max(-1, self.Normalize.Dot(b.Normalize))));
end;

function RVector3.ZXY : RVector3;
begin
  Result := RVector3.Create(Z, X, Y);
end;

function RVector3.ZY : RVector2;
begin
  Result := RVector2.Create(Z, Y);
end;

function RVector3.ZYX : RVector3;
begin
  Result := RVector3.Create(Z, Y, X);
end;

function RVector3.ZZZ : RVector3;
begin
  Result.X := Z;
  Result.Y := Z;
  Result.Z := Z;
end;

function RVector3.Sign : RVector3;
begin
  Result := RVector3.Create(Math.Sign(X), Math.Sign(Y), Math.Sign(Z));
end;

function RVector3.SimilarTo(const CompareWith : RVector3; Epsilon : Single) : boolean;
begin
  Result := (Epsilon > System.Abs(X - CompareWith.X)) and (Epsilon > System.Abs(Y - CompareWith.Y)) and (Epsilon > System.Abs(Z - CompareWith.Z));
end;

class operator RVector3.multiply(const a, b : RVector3) : RVector3;
begin
  Result.X := a.X * b.X;
  Result.Y := a.Y * b.Y;
  Result.Z := a.Z * b.Z;
end;

class operator RVector3.subtract(const a, b : RVector3) : RVector3;
begin
  Result.X := a.X - b.X;
  Result.Y := a.Y - b.Y;
  Result.Z := a.Z - b.Z;
end;

class function RVector3.CartesianToSphere(U, V, r : Single) : RVector3;
var
  a : Single;
begin
  a := r * sin(U);
  Result.X := a * Cos(V);
  Result.Y := r * Cos(U);
  Result.Z := a * sin(V);
end;

function RVector3.Clamp(MinValue, MaxValue : Single) : RVector3;
begin
  Result.X := Min(MaxValue, Max(MinValue, X));
  Result.Y := Min(MaxValue, Max(MinValue, Y));
  Result.Z := Min(MaxValue, Max(MinValue, Z));
end;

function RVector3.CosLerp(const Target : RVector3; s : Single) : RVector3;
var
  temp : Single;
begin
  s := HMath.Saturate(s);
  temp := (1 + Cos(s * PI)) / 2;
  Result := ((temp * self) + ((1 - temp) * Target));
end;

constructor RVector3.Create0Y0(Y : Single);
begin
  self.X := 0;
  self.Y := Y;
  self.Z := 0;
end;

constructor RVector3.CreateFromIniString(const Value : string);
var
  Chunks : TArray<string>;
begin
  Chunks := Value.Split(['_']);
  if not(System.Length(Chunks) > 0) or not TryStrToFloat(Chunks[0], self.X, EngineFloatFormatSettings) then
      self.X := 0;
  if not(System.Length(Chunks) > 1) or not TryStrToFloat(Chunks[1], self.Y, EngineFloatFormatSettings) then
      self.Y := 0;
  if not(System.Length(Chunks) > 2) or not TryStrToFloat(Chunks[2], self.Z, EngineFloatFormatSettings) then
      self.Z := 0;
end;

constructor RVector3.Create(XYZ : TArray<Single>);
begin
  assert(System.Length(XYZ) = 3);
  self.X := XYZ[0];
  self.Y := XYZ[1];
  self.Z := XYZ[2];
end;

class operator RVector3.implicit(const a : RVector3) : TValue;
begin
  Result := TValue.From<RVector3>(a);
end;

{ RMatrix }

class operator RMatrix.add(const a, b : RMatrix) : RMatrix;
var
  X, Y : Integer;
begin
  for X := 0 to 3 do
    for Y := 0 to 3 do
        Result.m[X, Y] := a.m[X, Y] + b.m[X, Y];
end;

constructor RMatrix.Create(const Elements : array of Single);
begin
  assert(Length(Elements) = Size * Size, 'RMatrix.Create: Invalid argument count:' + Inttostr(Length(Elements)));
  _11 := Elements[0];
  _21 := Elements[1];
  _31 := Elements[2];
  _41 := Elements[3];

  _12 := Elements[4];
  _22 := Elements[5];
  _32 := Elements[6];
  _42 := Elements[7];

  _13 := Elements[8];
  _23 := Elements[9];
  _33 := Elements[10];
  _43 := Elements[11];

  _14 := Elements[12];
  _24 := Elements[13];
  _34 := Elements[14];
  _44 := Elements[15];
end;

function RMatrix.Determinant : Single;
begin
  Result :=
    _14 * _23 * _32 * _41 - _13 * _24 * _32 * _41 - _14 * _22 * _33 * _41 + _12 * _24 * _33 * _41 +
    _13 * _22 * _34 * _41 - _12 * _23 * _34 * _41 - _14 * _23 * _31 * _42 + _13 * _24 * _31 * _42 +
    _14 * _21 * _33 * _42 - _11 * _24 * _33 * _42 - _13 * _21 * _34 * _42 + _11 * _23 * _34 * _42 +
    _14 * _22 * _31 * _43 - _12 * _24 * _31 * _43 - _14 * _21 * _32 * _43 + _11 * _24 * _32 * _43 +
    _12 * _21 * _34 * _43 - _11 * _22 * _34 * _43 - _13 * _22 * _31 * _44 + _12 * _23 * _31 * _44 +
    _13 * _21 * _32 * _44 - _11 * _23 * _32 * _44 - _12 * _21 * _33 * _44 + _11 * _22 * _33 * _44;
end;

class operator RMatrix.divide(const a : RMatrix; b : Single) : RMatrix;
var
  X, Y : Integer;
begin
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
        Result.m[X, Y] := a.m[X, Y] / b;
end;

class operator RMatrix.equal(const a, b : RMatrix) : boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to (Size * Size) - 1 do
      Result := Result and (a.Element[0] = b.Element[0]);
end;

function RMatrix.Get3x3 : RMatrix;
begin
  Result := self;
  Result._14 := 0;
  Result._24 := 0;
  Result._34 := 0;
  Result._41 := 0;
  Result._42 := 0;
  Result._43 := 0;
  Result._44 := 1;
end;

function RMatrix.AbsSum : Single;
var
  X, Y : Integer;
begin
  Result := 0;
  for X := 0 to 3 do
    for Y := 0 to 3 do Result := Result + Abs(m[X, Y]);
end;

constructor RMatrix.CreateBase(const Left, Up, Front : RVector3);
begin
  self := IDENTITY;
  self.Column[0] := Left;
  self.Column[1] := Up;
  self.Column[2] := Front;
end;

constructor RMatrix.CreateLookAtLH(const Eye, At, Up : RVector3);
var
  xaxis, yaxis, zaxis : RVector3;
begin
  zaxis := (At - Eye).Normalize;
  xaxis := Up.Cross(zaxis).Normalize;
  yaxis := zaxis.Cross(xaxis).Normalize;
  Create([xaxis.X, xaxis.Y, xaxis.Z, -xaxis.Dot(Eye),
    yaxis.X, yaxis.Y, yaxis.Z, -yaxis.Dot(Eye),
    zaxis.X, zaxis.Y, zaxis.Z, -zaxis.Dot(Eye),
    0, 0, 0, 1]);
end;

constructor RMatrix.CreateOrthoLH(Width, Height, ZNear, ZFar : Single);
begin
  Create([2 / Width, 0, 0, 0,
    0, 2 / Height, 0, 0,
    0, 0, 1 / (ZFar - ZNear), ZNear / (ZNear - ZFar),
    0, 0, 0, 1]);
end;

constructor RMatrix.CreatePerspectiveFovLH(FovY, AspectRatio, ZNear, ZFar : Single);
var
  xScale, yScale : Single;
begin
  yScale := Math.Cot(FovY / 2);
  xScale := yScale / AspectRatio;
  Create([xScale, 0, 0, 0,
    0, yScale, 0, 0,
    0, 0, ZFar / (ZFar - ZNear), -ZNear * ZFar / (ZFar - ZNear),
    0, 0, 1, 0]);
end;

function RMatrix.GetElement(Index : Integer) : Single;
begin
  assert((index >= 0) and (index < Size * Size));
  Result := m[index mod 4, index div 4];
end;

constructor RMatrix.CreateRotationPitchYawRoll(const Pitch, Yaw, Roll : Single);
begin
  self := RMatrix.CreateRotationY(Yaw) * RMatrix.CreateRotationX(Pitch) * RMatrix.CreateRotationZ(Roll);
end;

constructor RMatrix.CreateRotationPitchYawRoll(const YawPitchRoll : RVector3);
begin
  self := RMatrix.CreateRotationPitchYawRoll(YawPitchRoll.X, YawPitchRoll.Y, YawPitchRoll.Z);
end;

constructor RMatrix.CreateRotationAxis(const Axis : RVector3; const Angle : Single);
var
  tSin, tCos, tCosI : Single;
begin
  Axis.InNormalize;
  tSin := sin(Angle);
  tCos := Cos(Angle);
  tCosI := 1.0 - tCos;
  self._11 := (tCosI * Axis.X * Axis.X) + tCos;
  self._12 := (tCosI * Axis.Y * Axis.X) - (tSin * Axis.Z);
  self._13 := (tCosI * Axis.Z * Axis.X) + (tSin * Axis.Y);
  self._14 := 0.0;
  self._21 := (tCosI * Axis.X * Axis.Y) + (tSin * Axis.Z);
  self._22 := (tCosI * Axis.Y * Axis.Y) + tCos;
  self._23 := (tCosI * Axis.Z * Axis.Y) - (tSin * Axis.X);
  self._24 := 0.0;
  self._31 := (tCosI * Axis.X * Axis.Z) - (tSin * Axis.Y);
  self._32 := (tCosI * Axis.Y * Axis.Z) + (tSin * Axis.X);
  self._33 := (tCosI * Axis.Z * Axis.Z) + tCos;
  self._34 := 0.0;
  self._41 := 0.0;
  self._42 := 0.0;
  self._43 := 0.0;
  self._44 := 1.0;
end;

constructor RMatrix.CreateRotationX(const Angle : Single);
begin
  FillChar(self, sizeof(RMatrix), 0);
  self._11 := 1;
  self._44 := 1;
  self._22 := Cos(Angle);
  self._33 := self._22;
  self._32 := sin(Angle);
  self._23 := -self._32;
end;

constructor RMatrix.CreateRotationY(const Angle : Single);
begin
  FillChar(self, sizeof(RMatrix), 0);
  self._22 := 1;
  self._44 := 1;
  self._11 := Cos(Angle);
  self._33 := self._11;
  self._13 := sin(Angle);
  self._31 := -self._13;
end;

constructor RMatrix.CreateRotationZ(const Angle : Single);
begin
  FillChar(self, sizeof(RMatrix), 0);
  self._33 := 1;
  self._44 := 1;
  self._11 := Cos(Angle);
  self._22 := self._11;
  self._21 := sin(Angle);
  self._12 := -self._21;
end;

constructor RMatrix.CreateScaling(const Scale : RVector3);
begin
  self := IDENTITY;
  self._11 := self._11 * Scale.X;
  self._22 := self._22 * Scale.Y;
  self._33 := self._33 * Scale.Z;
end;

constructor RMatrix.CreateSaveBase(const Front, Up : RVector3);
var
  FFront, FUp, FLeft : RVector3;
begin
  FFront := Front.Normalize;
  FUp := Up.Normalize;
  FLeft := -FFront.Cross(FUp).Normalize;
  FUp := FFront.Cross(FLeft).Normalize;
  self := RMatrix.CreateBase(FLeft, FUp, FFront);
end;

constructor RMatrix.CreateScaling(const Scale : Single);
begin
  self := RMatrix.CreateScaling(RVector3.Create(Scale));
end;

function RMatrix.getColumn(Index : Integer) : RVector3;
var
  i : Integer;
begin
  for i := 0 to 2 do Result.Element[i] := m[index, i];
end;

function RMatrix.GetTranslationComponent : RVector3;
begin
  Result := self.Column[3];
end;

constructor RMatrix.CreateTranslation(const Position : RVector3);
begin
  self := IDENTITY;
  self.Column[3] := Position;
end;

function RMatrix.getRow(Index : Integer) : RVector3;
var
  i : Integer;
begin
  for i := 0 to 2 do Result.Element[i] := m[i, index];
end;

class operator RMatrix.implicit(const a : RMatrix) : string;
var
  i : Integer;
begin
  Result := '{(';
  for i := 0 to Size * Size - 1 do
  begin
    if Abs(a.Element[i]) < SINGLE_ZERO_EPSILON then a.Element[i] := 0;
    Result := Result + FloattostrF(a.Element[i], ffGeneral, 4, 4, EngineFloatFormatSettings);
    if (i = Size * Size - 1) then break;
    if (i mod 4 = 3) then Result := Result + ')('
    else Result := Result + ' , '
  end;
  Result := Result + ')}';
end;

procedure RMatrix.InInverse;
begin
  self := Inverse;
end;

procedure RMatrix.InTranspose;
begin
  self := Transpose;
end;

function RMatrix.Inverse : RMatrix;
begin
  Result._11 := _23 * _34 * _42 - _24 * _33 * _42 + _24 * _32 * _43 - _22 * _34 * _43 - _23 * _32 * _44 + _22 * _33 * _44;
  Result._12 := _14 * _33 * _42 - _13 * _34 * _42 - _14 * _32 * _43 + _12 * _34 * _43 + _13 * _32 * _44 - _12 * _33 * _44;
  Result._13 := _13 * _24 * _42 - _14 * _23 * _42 + _14 * _22 * _43 - _12 * _24 * _43 - _13 * _22 * _44 + _12 * _23 * _44;
  Result._14 := _14 * _23 * _32 - _13 * _24 * _32 - _14 * _22 * _33 + _12 * _24 * _33 + _13 * _22 * _34 - _12 * _23 * _34;
  Result._21 := _24 * _33 * _41 - _23 * _34 * _41 - _24 * _31 * _43 + _21 * _34 * _43 + _23 * _31 * _44 - _21 * _33 * _44;
  Result._22 := _13 * _34 * _41 - _14 * _33 * _41 + _14 * _31 * _43 - _11 * _34 * _43 - _13 * _31 * _44 + _11 * _33 * _44;
  Result._23 := _14 * _23 * _41 - _13 * _24 * _41 - _14 * _21 * _43 + _11 * _24 * _43 + _13 * _21 * _44 - _11 * _23 * _44;
  Result._24 := _13 * _24 * _31 - _14 * _23 * _31 + _14 * _21 * _33 - _11 * _24 * _33 - _13 * _21 * _34 + _11 * _23 * _34;
  Result._31 := _22 * _34 * _41 - _24 * _32 * _41 + _24 * _31 * _42 - _21 * _34 * _42 - _22 * _31 * _44 + _21 * _32 * _44;
  Result._32 := _14 * _32 * _41 - _12 * _34 * _41 - _14 * _31 * _42 + _11 * _34 * _42 + _12 * _31 * _44 - _11 * _32 * _44;
  Result._33 := _12 * _24 * _41 - _14 * _22 * _41 + _14 * _21 * _42 - _11 * _24 * _42 - _12 * _21 * _44 + _11 * _22 * _44;
  Result._34 := _14 * _22 * _31 - _12 * _24 * _31 - _14 * _21 * _32 + _11 * _24 * _32 + _12 * _21 * _34 - _11 * _22 * _34;
  Result._41 := _23 * _32 * _41 - _22 * _33 * _41 - _23 * _31 * _42 + _21 * _33 * _42 + _22 * _31 * _43 - _21 * _32 * _43;
  Result._42 := _12 * _33 * _41 - _13 * _32 * _41 + _13 * _31 * _42 - _11 * _33 * _42 - _12 * _31 * _43 + _11 * _32 * _43;
  Result._43 := _13 * _22 * _41 - _12 * _23 * _41 - _13 * _21 * _42 + _11 * _23 * _42 + _12 * _21 * _43 - _11 * _22 * _43;
  Result._44 := _12 * _23 * _31 - _13 * _22 * _31 + _13 * _21 * _32 - _11 * _23 * _32 - _12 * _21 * _33 + _11 * _22 * _33;
  if self.Determinant <> 0 then
      Result := Result / self.Determinant;
end;

class operator RMatrix.multiply(a : Single; const b : RMatrix) : RMatrix;
var
  X, Y : Integer;
begin
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
        Result.m[X, Y] := a * b.m[X, Y];
end;

class operator RMatrix.multiply(const a : RMatrix; b : Single) : RMatrix;
var
  X, Y : Integer;
begin
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
        Result.m[X, Y] := a.m[X, Y] * b;
end;

class operator RMatrix.multiply(const a, b : RMatrix) : RMatrix;
var
  X, Y, i : Integer;
  Sum : Single;
begin
  for X := 0 to RMatrix.Size - 1 do
    for Y := 0 to RMatrix.Size - 1 do
    begin
      Sum := 0;
      for i := 0 to RMatrix.Size - 1 do
          Sum := Sum + a.m[i, Y] * b.m[X, i];
      Result.m[X, Y] := Sum;
    end;
end;

class operator RMatrix.multiply(const a : RMatrix; const b : RVector3) : RVector3;
var
  temp : RVector4;
begin
  temp := a * RVector4.Create(b, 1);
  Result := temp.Unproject;
end;

class operator RMatrix.negative(const a : RMatrix) : RMatrix;
var
  X, Y : Integer;
begin
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
        Result.m[X, Y] := -a.m[X, Y];
end;

procedure RMatrix.SetElement(Index : Integer; const Value : Single);
begin
  assert((index >= 0) and (index < Size * Size));
  m[index mod 4, index div 4] := Value;
end;

class operator RMatrix.multiply(const a : RMatrix; const b : RVector4) : RVector4;
var
  Y, i : Integer;
  Sum : Single;
begin
  for Y := 0 to RMatrix.Size - 1 do
  begin
    Sum := 0;
    for i := 0 to RMatrix.Size - 1 do
        Sum := Sum + a.m[i, Y] * b.Element[i];
    Result.Element[Y] := Sum;
  end;
end;

procedure RMatrix.setColumn(Index : Integer; const Value : RVector3);
var
  i : Integer;
begin
  for i := 0 to 2 do
      m[index, i] := Value.Element[i];
end;

procedure RMatrix.SetTranslationComponent(const V : RVector3);
begin
  self.Column[3] := V;
end;

procedure RMatrix.setRow(Index : Integer; const Value : RVector3);
var
  i : Integer;
begin
  for i := 0 to 2 do
      m[i, index] := Value.Element[i];
end;

function RMatrix.SimilarTo(const Matrix : RMatrix) : boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to Size * Size - 1 do
    if Abs(self.Element[i] - Matrix.Element[i]) > SINGLE_ZERO_EPSILON then exit(false);
end;

class operator RMatrix.subtract(const a, b : RMatrix) : RMatrix;
var
  X, Y : Integer;
begin
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
        Result.m[X, Y] := a.m[X, Y] - b.m[X, Y];
end;

procedure RMatrix.SwapXY;
var
  temp : RVector3;
begin
  temp := Column[0];
  Column[0] := Column[1];
  Column[1] := temp;
end;

procedure RMatrix.SwapXZ;
var
  temp : RVector3;
begin
  temp := Column[2];
  Column[2] := Column[0];
  Column[0] := temp;
end;

procedure RMatrix.SwapYZ;
var
  temp : RVector3;
begin
  temp := Column[1];
  Column[1] := Column[2];
  Column[2] := temp;
end;

function RMatrix.Transpose : RMatrix;
var
  X, Y : Integer;
begin
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
        Result.m[X, Y] := m[Y, X];
end;

{ half }

class function half.FloatToHalf(Float : Single) : half;
var
  Src : LongWord;
  Sign, Exp, Mantissa : LongInt;
begin
  Src := PLongWord(@Float)^;
  // Extract sign, exponent, and mantissa from Single number
  Sign := Src shr 31;
  Exp := LongInt((Src and $7F800000) shr 23) - 127 + 15;
  Mantissa := Src and $007FFFFF;

  if (Exp > 0) and (Exp < 30) then
  begin
    // Simple case - round the significand and combine it with the sign and exponent
    Result.Value := (Sign shl 15) or (Exp shl 10) or ((Mantissa + $00001000) shr 13);
  end
  else if Src = 0 then
  begin
    // Input float is zero - return zero
    Result.Value := 0;
  end
  else
  begin
    // Difficult case - lengthy conversion
    if Exp <= 0 then
    begin
      if Exp < -10 then
      begin
        // Input float's value is less than HalfMin, return zero
        Result.Value := 0;
      end
      else
      begin
        // Float is a normalized Single whose magnitude is less than HalfNormMin.
        // We convert it to denormalized half.
        Mantissa := (Mantissa or $00800000) shr (1 - Exp);
        // Round to nearest
        if (Mantissa and $00001000) > 0 then
            Mantissa := Mantissa + $00002000;
        // Assemble Sign and Mantissa (Exp is zero to get denormalized number)
        Result.Value := (Sign shl 15) or (Mantissa shr 13);
      end;
    end
    else if Exp = 255 - 127 + 15 then
    begin
      if Mantissa = 0 then
      begin
        // Input float is infinity, create infinity half with original sign
        Result.Value := (Sign shl 15) or $7C00;
      end
      else
      begin
        // Input float is NaN, create half NaN with original sign and mantissa
        Result.Value := (Sign shl 15) or $7C00 or (Mantissa shr 13);
      end;
    end
    else
    begin
      // Exp is > 0 so input float is normalized Single

      // Round to nearest
      if (Mantissa and $00001000) > 0 then
      begin
        Mantissa := Mantissa + $00002000;
        if (Mantissa and $00800000) > 0 then
        begin
          Mantissa := 0;
          Exp := Exp + 1;
        end;
      end;

      if Exp > 30 then
      begin
        // Exponent overflow - return infinity half
        Result.Value := (Sign shl 15) or $7C00;
      end
      else
        // Assemble normalized half
          Result.Value := (Sign shl 15) or (Exp shl 10) or (Mantissa shr 13);
    end;
  end;
end;

class function half.HalfToFloat(Value : half) : Single;
var
  Dst, Sign, Mantissa : LongWord;
  Exp : LongInt;
begin
  // Extract sign, exponent, and mantissa from half number
  Sign := Value.Value shr 15;
  Exp := (Value.Value and $7C00) shr 10;
  Mantissa := Value.Value and 1023;

  if (Exp > 0) and (Exp < 31) then
  begin
    // Common normalized number
    Exp := Exp + (127 - 15);
    Mantissa := Mantissa shl 13;
    Dst := (Sign shl 31) or (LongWord(Exp) shl 23) or Mantissa;
    // Result := Power(-1, Sign) * Power(2, Exp - 15) * (1 + Mantissa / 1024);
  end
  else if (Exp = 0) and (Mantissa = 0) then
  begin
    // Zero - preserve sign
    Dst := Sign shl 31;
  end
  else if (Exp = 0) and (Mantissa <> 0) then
  begin
    // Denormalized number - renormalize it
    while (Mantissa and $00000400) = 0 do
    begin
      Mantissa := Mantissa shl 1;
      Dec(Exp);
    end;
    inc(Exp);
    Mantissa := Mantissa and not $00000400;
    // Now assemble normalized number
    Exp := Exp + (127 - 15);
    Mantissa := Mantissa shl 13;
    Dst := (Sign shl 31) or (LongWord(Exp) shl 23) or Mantissa;
    // Result := Power(-1, Sign) * Power(2, -14) * (Mantissa / 1024);
  end
  else if (Exp = 31) and (Mantissa = 0) then
  begin
    // +/- infinity
    Dst := (Sign shl 31) or $7F800000;
  end
  else // if (Exp = 31) and (Mantisa <> 0) then
  begin
    // Not a number - preserve sign and mantissa
    Dst := (Sign shl 31) or $7F800000 or (Mantissa shl 13);
  end;

  // Reinterpret LongWord as Single
  Result := PSingle(@Dst)^;
end;

class operator half.implicit(Float : Single) : half;
begin
  Result := half.FloatToHalf(Float);
end;

{ RIntVector2 }

class operator RIntVector2.add(const a, b : RIntVector2) : RIntVector2;
begin
  Result.X := a.X + b.X;
  Result.Y := a.Y + b.Y;
end;

class operator RIntVector2.add(a : Integer; const b : RIntVector2) : RIntVector2;
begin
  Result.X := a + b.X;
  Result.Y := a + b.Y;
end;

class operator RIntVector2.add(const a : RIntVector2; b : Integer) : RIntVector2;
begin
  Result.X := a.X + b;
  Result.Y := a.Y + b;
end;

function RIntVector2.Clamp(const Min, Max : RIntVector2) : RIntVector2;
begin
  Result := self.Max(Min).Min(Max);
end;

constructor RIntVector2.Create(XY : Integer);
begin
  self.X := XY;
  self.Y := XY;
end;

constructor RIntVector2.Create(X, Y : Integer);
begin
  self.X := X;
  self.Y := Y;
end;

constructor RIntVector2.CreateFromVector2(const vec : RVector2);
begin
  self.X := Round(vec.X);
  self.Y := Round(vec.Y);
end;

function RIntVector2.Distance(const b : RIntVector2) : Single;
begin
  Result := (b - self).Length;
end;

class operator RIntVector2.divide(a : Single; const b : RIntVector2) : RVector2;
begin
  Result.X := a / b.X;
  Result.Y := a / b.Y;
end;

class operator RIntVector2.divide(const a : RIntVector2; b : Single) : RVector2;
begin
  Result.X := a.X / b;
  Result.Y := a.Y / b;
end;

class operator RIntVector2.equal(const a, b : RIntVector2) : boolean;
begin
  Result := (a.X = b.X) and (a.Y = b.Y);
end;

class operator RIntVector2.Explicit(const a : RIntVector2) : RVector2;
begin
  Result.X := a.X;
  Result.Y := a.Y;
end;

class operator RIntVector2.GreaterThan(const a, b : RIntVector2) : boolean;
begin
  Result := (a.X > b.X) and (a.Y > b.Y);
end;

class operator RIntVector2.GreaterThan(const a : RIntVector2; b : Integer) : boolean;
begin
  Result := (a.X > b) and (a.Y > b);
end;

class operator RIntVector2.greaterthanorequal(const a : RIntVector2; b : Integer) : boolean;
begin
  Result := (a.X >= b) and (a.Y >= b);
end;

class operator RIntVector2.implicit(a : TPoint) : RIntVector2;
begin
  Result.X := a.X;
  Result.Y := a.Y;
end;

class operator RIntVector2.implicit(const a : RIntVector2) : RVector2;
begin
  Result.X := a.X;
  Result.Y := a.Y;
end;

class operator RIntVector2.IntDivide(const a : RIntVector2; b : Integer) : RIntVector2;
begin
  Result.X := a.X div b;
  Result.Y := a.Y div b;
end;

function RIntVector2.IsZeroVector : boolean;
begin
  Result := (X = 0) and (Y = 0);
end;

function RIntVector2.Length : Single;
begin
  Result := sqrt(sqr(X) + sqr(Y));
end;

class operator RIntVector2.LessThan(const a, b : RIntVector2) : boolean;
begin
  Result := (a.X < b.X) and (a.Y < b.Y);
end;

class operator RIntVector2.LessThan(const a : RIntVector2; b : Integer) : boolean;
begin
  Result := (a.X < b) and (a.Y < b);
end;

class operator RIntVector2.lessthanorequal(const a : RIntVector2; b : Integer) : boolean;
begin
  Result := (a.X <= b) and (a.Y <= b);
end;

function RIntVector2.Max(const b : RIntVector2) : RIntVector2;
begin
  Result.X := Math.Max(X, b.X);
  Result.Y := Math.Max(Y, b.Y);
end;

function RIntVector2.Min(const b : RIntVector2) : RIntVector2;
begin
  Result.X := Math.Min(X, b.X);
  Result.Y := Math.Min(Y, b.Y);
end;

function RIntVector2.Max(b : Integer) : RIntVector2;
begin
  Result.X := Math.Max(X, b);
  Result.Y := Math.Max(Y, b);
end;

function RIntVector2.MaxValue : Integer;
begin
  Result := Math.Max(X, Y);
end;

function RIntVector2.Min(b : Integer) : RIntVector2;
begin
  Result.X := Math.Min(X, b);
  Result.Y := Math.Min(Y, b);
end;

function RIntVector2.MinValue : Integer;
begin
  Result := Math.Min(X, Y);
end;

class operator RIntVector2.multiply(a : Integer; const b : RIntVector2) : RIntVector2;
begin
  Result.X := b.X * a;
  Result.Y := b.Y * a;
end;

class operator RIntVector2.multiply(const a : RIntVector2; b : Integer) : RIntVector2;
begin
  Result.X := a.X * b;
  Result.Y := a.Y * b;
end;

class operator RIntVector2.negative(const a : RIntVector2) : RIntVector2;
begin
  Result.X := -a.X;
  Result.Y := -a.Y;
end;

class operator RIntVector2.notequal(const a, b : RIntVector2) : boolean;
begin
  Result := (a.X <> b.X) or (a.Y <> b.Y);
end;

function RIntVector2.Random : RIntVector2;
begin
  Result.X := System.Random(X);
  Result.Y := System.Random(Y);
end;

function RIntVector2.SetX(X : Integer) : RIntVector2;
begin
  Result.X := X;
  Result.Y := self.Y;
end;

function RIntVector2.SetY(Y : Integer) : RIntVector2;
begin
  Result.X := self.X;
  Result.Y := Y;
end;

class operator RIntVector2.subtract(a : Integer; const b : RIntVector2) : RIntVector2;
begin
  Result.X := a - b.X;
  Result.Y := a - b.Y;
end;

class function RIntVector2.TryFromString(str : string; out Vector : RIntVector2) : boolean;
var
  data : TArray<string>;
begin
  str := str.Replace('(', '').Replace(')', '');
  data := str.Split([',']);
  Result := (System.Length(data) = 2) and TryStrToInt(data[0], Vector.X) and TryStrToInt(data[1], Vector.Y);
end;

function RIntVector2.YX : RIntVector2;
begin
  Result.X := Y;
  Result.Y := X;
end;

class operator RIntVector2.subtract(const a : RIntVector2; b : Integer) : RIntVector2;
begin
  Result.X := a.X - b;
  Result.Y := a.Y - b;
end;

class operator RIntVector2.subtract(const a, b : RIntVector2) : RIntVector2;
begin
  Result.X := a.X - b.X;
  Result.Y := a.Y - b.Y;
end;

class function RIntVector2.ZERO : RIntVector2;
begin
  Result.X := 0;
  Result.Y := 0;
end;

class operator RIntVector2.Explicit(const a : RIntVector2) : TPoint;
begin
  Result.X := a.X;
  Result.Y := a.Y;
end;

class operator RIntVector2.implicit(const a : RIntVector2) : TValue;
begin
  Result := TValue.From<RIntVector2>(a);
end;

class operator RIntVector2.implicit(const a : RIntVector2) : string;
begin
  Result := '(' + Inttostr(a.X) + ',' + Inttostr(a.Y) + ')';
end;

class operator RIntVector2.multiply(a : Single; const b : RIntVector2) : RVector2;
begin
  Result.X := a * b.X;
  Result.Y := a * b.Y;
end;

class operator RIntVector2.multiply(const a : RIntVector2; b : Single) : RVector2;
begin
  Result.X := a.X * b;
  Result.Y := a.Y * b;
end;

class operator RIntVector2.greaterthanorequal(const a, b : RIntVector2) : boolean;
begin
  Result := (a.X >= b.X) and (a.Y >= b.Y);
end;

function RIntVector2.HasAZero : boolean;
begin
  Result := (X = 0) or (Y = 0);
end;

function RIntVector2.Hash : Integer;
begin
  Result := THashBobJenkins.GetHashValue(self, sizeof(RIntVector2));
end;

class operator RIntVector2.lessthanorequal(const a, b : RIntVector2) : boolean;
begin
  Result := (a.X <= b.X) and (a.Y <= b.Y);
end;

class operator RIntVector2.multiply(const a, b : RIntVector2) : RIntVector2;
begin
  Result.X := a.X * b.X;
  Result.Y := a.Y * b.Y;
end;

{ RVariedVector3 }

constructor RVariedVector3.Create(const Mean : RVector3);
begin
  Create(Mean, RVector3.ZERO);
end;

constructor RVariedVector3.Create(const Mean, Variance : RVector3);
begin
  self.Mean := Mean;
  self.Variance := Variance;
  self.FRadialVaried := false;
end;

constructor RVariedVector3.Create(MeanXYZ : Single);
begin
  Create(RVector3(MeanXYZ));
end;

constructor RVariedVector3.Create(MeanX, MeanY, MeanZ : Single);
begin
  Create(RVector3.Create(MeanX, MeanY, MeanZ));
end;

constructor RVariedVector3.CreateRadialVaried(const Mean : RVector3; Variance : Single);
begin
  Create(Mean, RVector3.Create(Variance, 0, 0));
  FRadialVaried := true;
end;

function RVariedVector3.GetRandomVector : RVector3;
begin
  if FRadialVaried then
  begin
    Result := Mean + RVector3.getRandomPointInSphere(Variance.X);
  end
  else
  begin
    Result.X := Mean.X + ((Random * 2 - 1) * Variance.X);
    Result.Y := Mean.Y + ((Random * 2 - 1) * Variance.Y);
    Result.Z := Mean.Z + ((Random * 2 - 1) * Variance.Z);
  end;
end;

function RVariedVector3.GetRandomVectorSpecial(FixedRandomFactor : Single) : RVector3;
begin
  if FRadialVaried then
  begin
    Result := Mean + RVector3.getRandomPointInSphere(Variance.X);
  end
  else
  begin
    if Variance.X < 0 then
        Result.X := Mean.X + ((FixedRandomFactor * 2 - 1) * Variance.X)
    else
        Result.X := Mean.X + ((Random * 2 - 1) * Variance.X);
    if Variance.Y < 0 then
        Result.Y := Mean.Y + ((FixedRandomFactor * 2 - 1) * Variance.Y)
    else
        Result.Y := Mean.Y + ((Random * 2 - 1) * Variance.Y);
    if Variance.Z < 0 then
        Result.Z := Mean.Z + ((FixedRandomFactor * 2 - 1) * Variance.Z)
    else
        Result.Z := Mean.Z + ((Random * 2 - 1) * Variance.Z);
  end;
end;

class operator RVariedVector3.implicit(const a : RVector3) : RVariedVector3;
begin
  Result := RVariedVector3.Create(a);
end;

function RVariedVector3.LerpDim(Dim : Integer; s : Single) : Single;
begin
  Result := Mean.Element[Dim] + Variance.Element[Dim] * (s * 2 - 1);
end;

function RVariedVector3.RandomDim(Dim : Integer) : Single;
begin
  Result := Mean.Element[Dim] + Variance.Element[Dim] * (Random * 2 - 1);
end;

{ RVariedSingle }

constructor RVariedSingle.Create(Mean : Single);
begin
  Create(Mean, 0);
end;

constructor RVariedSingle.Create(Mean, Variance : Single);
begin
  self.Mean := Mean;
  self.Variance := Variance;
end;

function RVariedSingle.Random : Single;
begin
  Result := Mean + ((System.Random * 2 - 1) * Variance);
end;

class operator RVariedSingle.implicit(a : Single) : RVariedSingle;
begin
  Result := RVariedSingle.Create(a);
end;

function RVariedSingle.Random(FixedRandomFactor : Single) : Single;
begin
  if Variance < 0 then
      Result := Mean + ((FixedRandomFactor * 2 - 1) * Variance)
  else
      Result := Random
end;

{ RVariedInteger }

constructor RVariedInteger.Create(Mean : Integer);
begin
  Create(Mean, 0);
end;

constructor RVariedInteger.Create(Mean, Variance : Integer);
begin
  self.Mean := Mean;
  if Variance mod 2 = 1 then Variance := Variance + 1;
  self.Variance := Variance;
end;

function RVariedInteger.Random : Integer;
begin
  Result := Mean + (System.Random(Variance * 2) - Variance div 2);
end;

class operator RVariedInteger.implicit(a : Integer) : RVariedInteger;
begin
  Result := RVariedInteger.Create(a);
end;

function RVariedInteger.Lerp(s : Single) : Integer;
begin
  Result := Mean + Round((s * 2 - 1) * Variance);
end;

{ RVariedVector4 }

constructor RVariedVector4.Create(const Mean : RVector4);
begin
  Create(Mean, RVector4.ZERO);
end;

constructor RVariedVector4.Create(const Mean, Variance : RVector4);
begin
  self.Mean := Mean;
  self.Variance := Variance;
end;

function RVariedVector4.GetRandomVector : RVector4;
begin
  Result.X := Mean.X + ((Random * 2 - 1) * Variance.X);
  Result.Y := Mean.Y + ((Random * 2 - 1) * Variance.Y);
  Result.Z := Mean.Z + ((Random * 2 - 1) * Variance.Z);
  Result.W := Mean.W + ((Random * 2 - 1) * Variance.W);
end;

class operator RVariedVector4.implicit(const a : RVector4) : RVariedVector4;
begin
  Result := RVariedVector4.Create(a);
end;

procedure RVariedVector4.SetX(const Value : RVariedSingle);
begin
  self.Mean.X := Value.Mean;
  self.Variance.X := Value.Variance;
end;

procedure RVariedVector4.setXY(const Value : RVariedVector2);
begin
  self.Mean.X := Value.Mean.X;
  self.Mean.Y := Value.Mean.Y;
  self.Variance.X := Value.Variance.X;
  self.Variance.Y := Value.Variance.Y;
end;

procedure RVariedVector4.setXYZ(const Value : RVariedVector3);
begin
  self.Mean.X := Value.Mean.X;
  self.Mean.Y := Value.Mean.Y;
  self.Mean.Z := Value.Mean.Z;
  self.Variance.X := Value.Variance.X;
  self.Variance.Y := Value.Variance.Y;
  self.Variance.Z := Value.Variance.Z;
end;

function RVariedVector4.getX : RVariedSingle;
begin
  Result.Mean := Mean.X;
  Result.Variance := Variance.X;
end;

function RVariedVector4.getXY : RVariedVector2;
begin
  Result.Mean.X := Mean.X;
  Result.Mean.Y := Mean.Y;
  Result.Variance.X := Variance.X;
  Result.Variance.Y := Variance.Y;
end;

function RVariedVector4.getXYZ : RVariedVector3;
begin
  Result.Mean.X := Mean.X;
  Result.Mean.Y := Mean.Y;
  Result.Mean.Z := Mean.Z;
  Result.Variance.X := Variance.X;
  Result.Variance.Y := Variance.Y;
  Result.Variance.Z := Variance.Z;
end;

procedure incMax(var Wert : Integer; MaxWert : Integer; ModWert : Integer = 1);
begin
  Wert := (Wert + ModWert) mod (MaxWert + 1);
end;

procedure decMax(var Wert : Integer; MaxWert : Integer; ModWert : Integer = 1);
begin
  Wert := (Wert - ModWert);
  if Wert < 0 then Wert := MaxWert + Wert + 1;
end;

function diffMax(Wert1, Wert2, MaxWert : Integer) : Integer;
var
  i, tmpz, tmp : Integer;
begin
  Result := 0;
  tmp := Wert1;
  tmpz := 0;
  for i := 0 to MaxWert do
    if tmp = Wert2 then
    begin
      Result := tmpz;
      exit;
    end
    else
    begin
      incMax(tmp, MaxWert);
      inc(tmpz);
    end;
end;

{ RIntVector4 }

constructor RIntVector4.Create(X, Y, Z, W : Integer);
begin
  self.X := X;
  self.Y := Y;
  self.Z := Z;
  self.W := W;
end;

constructor RIntVector4.Create(XYZW : Integer);
begin
  X := XYZW;
  Y := XYZW;
  Z := XYZW;
  W := XYZW;
end;

function RIntVector4.getXZ : RIntVector2;
begin
  Result.X := X;
  Result.Y := Z;
end;

function RIntVector4.GetYW : RIntVector2;
begin
  Result.X := Y;
  Result.Y := W;
end;

class operator RIntVector4.implicit(const a : RIntVector4) : RVector4;
begin
  Result.X := a.X;
  Result.Y := a.Y;
  Result.Z := a.Z;
  Result.W := a.W;
end;

class operator RIntVector4.negative(const a : RIntVector4) : RIntVector4;
begin
  Result.X := -a.X;
  Result.Y := -a.Y;
  Result.Z := -a.Z;
  Result.W := -a.W;
end;

procedure RIntVector4.setXZ(const Value : RIntVector2);
begin
  X := Value.X;
  Z := Value.Y;
end;

procedure RIntVector4.setYW(const Value : RIntVector2);
begin
  Y := Value.X;
  W := Value.Y;
end;

function RIntVector4.SumAxis : RIntVector2;
begin
  Result.X := Y + W;
  Result.Y := X + Z;
end;

function RIntVector4.ToArray : TArray<Single>;
begin
  SetLength(Result, 4);
  Result[0] := X;
  Result[1] := Y;
  Result[2] := Z;
  Result[3] := W;
end;

function RIntVector4.WX : RIntVector2;
begin
  Result.X := W;
  Result.Y := X;
end;

function RIntVector4.WZ : RIntVector2;
begin
  Result.X := W;
  Result.Y := Z;
end;

function RIntVector4.YX : RIntVector2;
begin
  Result.X := Y;
  Result.Y := X;
end;

{ RVector2Helper }

function RVector2Helper.X0Y(Y : Single) : RVector3;
begin
  Result.X := self.X;
  Result.Y := Y;
  Result.Z := self.Y;
end;

function RVector2Helper.XY0(Z : Single) : RVector3;
begin
  Result.X := self.X;
  Result.Y := self.Y;
  Result.Z := Z;
end;

function IntMod(const X, Y : Integer) : Integer;
begin
  Result := (X mod Y + Y) mod Y;
end;

{ RVector3Helper }

function RVector3Helper.XYZ0 : RVector4;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.W := 0;
end;

function RVector3Helper.XYZ1 : RVector4;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.W := 1;
end;

{ RVector4Helper }

function RVector4Helper.QuaternionToMatrix : RMatrix;
var
  sqx, sqy, sqz, sqw, invs, tmp1, tmp2 : Single;
begin
  // from https://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/index.htm
  sqw := sqr(W);
  sqx := sqr(X);
  sqy := sqr(Y);
  sqz := sqr(Z);

  // invs (inverse square length) is only required if quaternion is not already normalised
  invs := (sqx + sqy + sqz + sqw);
  if invs = 0 then
      invs := 1
  else
      invs := 1 / invs;
  Result._11 := (sqx - sqy - sqz + sqw) * invs; // since sqw + sqx + sqy + sqz :=1/invs*invs
  Result._22 := (-sqx + sqy - sqz + sqw) * invs;
  Result._33 := (-sqx - sqy + sqz + sqw) * invs;

  tmp1 := X * Y;
  tmp2 := Z * W;
  Result._12 := 2.0 * (tmp1 + tmp2) * invs;
  Result._21 := 2.0 * (tmp1 - tmp2) * invs;

  tmp1 := X * Z;
  tmp2 := Y * W;
  Result._13 := 2.0 * (tmp1 - tmp2) * invs;
  Result._31 := 2.0 * (tmp1 + tmp2) * invs;
  tmp1 := Y * Z;
  tmp2 := X * W;
  Result._23 := 2.0 * (tmp1 + tmp2) * invs;
  Result._32 := 2.0 * (tmp1 - tmp2) * invs;

  Result._41 := 0;
  Result._42 := 0;
  Result._43 := 0;
  Result._44 := 1;
  Result._14 := 0;
  Result._24 := 0;
  Result._34 := 0;
end;

function RVector4Helper.QuaternionToMatrix4x3 : RMatrix4x3;
var
  sqx, sqy, sqz, sqw, invs, tmp1, tmp2 : Single;
begin
  // from https://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/index.htm
  sqw := sqr(W);
  sqx := sqr(X);
  sqy := sqr(Y);
  sqz := sqr(Z);

  // invs (inverse square length) is only required if quaternion is not already normalised
  invs := (sqx + sqy + sqz + sqw);
  if invs = 0 then
      invs := 1
  else
      invs := 1 / invs;
  Result._11 := (sqx - sqy - sqz + sqw) * invs; // since sqw + sqx + sqy + sqz :=1/invs*invs
  Result._22 := (-sqx + sqy - sqz + sqw) * invs;
  Result._33 := (-sqx - sqy + sqz + sqw) * invs;

  tmp1 := X * Y;
  tmp2 := Z * W;
  Result._12 := 2.0 * (tmp1 + tmp2) * invs;
  Result._21 := 2.0 * (tmp1 - tmp2) * invs;

  tmp1 := X * Z;
  tmp2 := Y * W;
  Result._13 := 2.0 * (tmp1 - tmp2) * invs;
  Result._31 := 2.0 * (tmp1 + tmp2) * invs;
  tmp1 := Y * Z;
  tmp2 := X * W;
  Result._23 := 2.0 * (tmp1 + tmp2) * invs;
  Result._32 := 2.0 * (tmp1 - tmp2) * invs;

  Result._41 := 0;
  Result._42 := 0;
  Result._43 := 0;
end;

{ RVariedHermiteSpline }

constructor RVariedHermiteSpline.Create(const StartPosition, EndPosition, StartTangent, EndTangent : RVariedVector3);
begin
  self.StartPosition := StartPosition;
  self.EndPosition := EndPosition;
  self.StartTangent := StartTangent;
  self.EndTangent := EndTangent;
end;

function RVariedHermiteSpline.getRandomSpline : RHermiteSpline;
begin
  Result.StartPosition := StartPosition.GetRandomVector;
  Result.EndPosition := EndPosition.GetRandomVector;
  Result.StartTangent := StartTangent.GetRandomVector;
  Result.EndTangent := EndTangent.GetRandomVector;
end;

{ RVariedVector2 }

constructor RVariedVector2.Create(const Mean : RVector2);
begin
  Create(Mean, RVector2.ZERO);
end;

constructor RVariedVector2.Create(const Mean, Variance : RVector2);
begin
  self.Mean := Mean;
  self.Variance := Variance;
  self.FRadialVaried := false;
end;

constructor RVariedVector2.Create(MeanX, MeanY, VarianceX, VarianceY : Single);
begin
  Create(RVector2.Create(MeanX, MeanY), RVector2.Create(VarianceX, VarianceY));
end;

constructor RVariedVector2.CreateRadialVaried(const Mean : RVector2; Variance : Single);
begin
  Create(Mean, RVector2.Create(Variance, 0));
  FRadialVaried := true;
end;

function RVariedVector2.GetRandomVector : RVector2;
begin
  if FRadialVaried then
  begin
    Result := Mean + RVector2.GetRandomPointInCircle(Variance.X);
  end
  else
  begin
    Result.X := Mean.X + ((Random * 2 - 1) * Variance.X);
    Result.Y := Mean.Y + ((Random * 2 - 1) * Variance.Y);
  end;
end;

class operator RVariedVector2.implicit(const a : RVector2) : RVariedVector2;
begin
  Result := RVariedVector2.Create(a);
end;

{ RMatrix2x2 }

constructor RMatrix2x2.CreateBase(const Left, Front : RVector2);
begin
  self.Column[0] := Left;
  self.Column[1] := Front;
end;

function RMatrix2x2.Determinant : Single;
begin
  Result := _11 * _22 - _12 * _21;
end;

function RMatrix2x2.getColumn(Index : Integer) : RVector2;
var
  i : Integer;
begin
  for i := 0 to Size - 1 do Result.Element[i] := m[index, i];
end;

function RMatrix2x2.Inverse : RMatrix2x2;
var
  Determinant : Single;
begin
  Determinant := self.Determinant;
  if Determinant <> 0 then
  begin
    Result._11 := _22 / Determinant;
    Result._12 := -_21 / Determinant;
    Result._21 := -_12 / Determinant;
    Result._22 := _11 / Determinant;
  end
  else
      Result := self;
end;

class operator RMatrix2x2.multiply(const a : RMatrix2x2; const b : RVector2) : RVector2;
var
  Y, i : Integer;
  Sum : Single;
begin
  for Y := 0 to Size - 1 do
  begin
    Sum := 0;
    for i := 0 to Size - 1 do
        Sum := Sum + a.m[i, Y] * b.Element[i];
    Result.Element[Y] := Sum;
  end;
end;

procedure RMatrix2x2.setColumn(Index : Integer; const Value : RVector2);
var
  i : Integer;
begin
  for i := 0 to Size - 1 do
      m[index, i] := Value.Element[i];
end;

{ RIntVector2Helper }

function RIntVector2Helper.ToRVector : RVector2;
begin
  Result.X := X;
  Result.Y := Y;
end;

{ RIntRange }

constructor RIntRange.Create(const Minimum, Maximum : Integer);
begin
  self.Minimum := Minimum;
  self.Maximum := Maximum;
end;

class function RIntRange.CreateInvalid : RIntRange;
begin
  Result.Minimum := 0;
  Result.Maximum := -1;
end;

function RIntRange.EnsureRange(const Value : Integer) : Integer;
begin
  Result := HMath.Clamp(Value, Minimum, Maximum);
end;

procedure RIntRange.Extend(Value : Integer);
begin
  if IsInvalid then
  begin
    Minimum := Value;
    Maximum := Value;
  end
  else
  begin
    Minimum := Min(Minimum, Value);
    Maximum := Max(Maximum, Value);
  end;
end;

procedure RIntRange.Extend(RangeStart, RangeEnd : Integer);
begin
  Extend(RangeStart);
  Extend(RangeEnd);
end;

class operator RIntRange.implicit(const Value : RIntRange) : string;
begin
  Result := Format('[%d, %d]', [Value.Minimum, Value.Maximum]);
end;

function RIntRange.inRange(const Value : Integer) : boolean;
begin
  Result := (Value >= Minimum) and (Value <= Maximum);
end;

function RIntRange.IsInvalid : boolean;
begin
  Result := Maximum < Minimum;
end;

class function RIntRange.MaxRange : RIntRange;
begin
  Result := RIntRange.Create(Integer.MinValue, Integer.MaxValue);
end;

function RIntRange.Size : Integer;
begin
  Result := Maximum - Minimum + 1;
end;

{ RMatrix4x3 }

constructor RMatrix4x3.Create(const Elements : array of Single);
begin
  assert(Length(Elements) = ELEMENT_COUNT, 'RMatrix4x3.Create: Invalid argument count:' + Inttostr(Length(Elements)));
  _11 := Elements[0];
  _21 := Elements[1];
  _31 := Elements[2];
  _41 := Elements[3];

  _12 := Elements[4];
  _22 := Elements[5];
  _32 := Elements[6];
  _42 := Elements[7];

  _13 := Elements[8];
  _23 := Elements[9];
  _33 := Elements[10];
  _43 := Elements[11];
end;

constructor RMatrix4x3.CreateBase(const Left, Up, Front : RVector3);
begin
  _11 := Left.X;
  _21 := Up.X;
  _31 := Front.X;
  _41 := 0;

  _12 := Left.Y;
  _22 := Up.Y;
  _32 := Front.Y;
  _42 := 0;

  _13 := Left.Z;
  _23 := Up.Z;
  _33 := Front.Z;
  _43 := 0;
end;

constructor RMatrix4x3.CreateFrom4x4(const Matrix : RMatrix);
begin
  _11 := Matrix._11;
  _21 := Matrix._21;
  _31 := Matrix._31;
  _41 := Matrix._41;

  _12 := Matrix._12;
  _22 := Matrix._22;
  _32 := Matrix._32;
  _42 := Matrix._42;

  _13 := Matrix._13;
  _23 := Matrix._23;
  _33 := Matrix._33;
  _43 := Matrix._43;
end;

constructor RMatrix4x3.CreateRotationPitchYawRoll(const Pitch, Yaw, Roll : Single);
begin
  self := RMatrix4x3.CreateRotationY(Yaw) * RMatrix4x3.CreateRotationX(Pitch) * RMatrix4x3.CreateRotationZ(Roll);
end;

constructor RMatrix4x3.CreateRotationPitchYawRoll(const YawPitchRoll : RVector3);
begin
  self := RMatrix4x3.CreateRotationY(YawPitchRoll.Y) * RMatrix4x3.CreateRotationX(YawPitchRoll.X) * RMatrix4x3.CreateRotationZ(YawPitchRoll.Z);
end;

constructor RMatrix4x3.CreateRotationAxis(const Axis : RVector3; const Angle : Single);
var
  tSin, tCos, tCosI : Single;
begin
  Axis.InNormalize;
  tSin := sin(Angle);
  tCos := Cos(Angle);
  tCosI := 1.0 - tCos;
  self._11 := (tCosI * Axis.X * Axis.X) + tCos;
  self._12 := (tCosI * Axis.Y * Axis.X) - (tSin * Axis.Z);
  self._13 := (tCosI * Axis.Z * Axis.X) + (tSin * Axis.Y);

  self._21 := (tCosI * Axis.X * Axis.Y) + (tSin * Axis.Z);
  self._22 := (tCosI * Axis.Y * Axis.Y) + tCos;
  self._23 := (tCosI * Axis.Z * Axis.Y) - (tSin * Axis.X);

  self._31 := (tCosI * Axis.X * Axis.Z) - (tSin * Axis.Y);
  self._32 := (tCosI * Axis.Y * Axis.Z) + (tSin * Axis.X);
  self._33 := (tCosI * Axis.Z * Axis.Z) + tCos;

  self._41 := 0.0;
  self._42 := 0.0;
  self._43 := 0.0;
end;

constructor RMatrix4x3.CreateRotationFromQuaternion(const Quaternion : RQuaternion);
begin
  self := RMatrix4x3.CreateFrom4x4((RMatrix.Create(
    [Quaternion.W, Quaternion.Z, -Quaternion.Y, Quaternion.X,
    -Quaternion.Z, Quaternion.W, Quaternion.X, Quaternion.Y,
    Quaternion.Y, -Quaternion.X, Quaternion.W, Quaternion.Z,
    -Quaternion.X, -Quaternion.Y, -Quaternion.Z, Quaternion.W]
    ) * RMatrix.Create(
    [Quaternion.W, Quaternion.Z, -Quaternion.Y, -Quaternion.X,
    -Quaternion.Z, Quaternion.W, Quaternion.X, -Quaternion.Y,
    Quaternion.Y, -Quaternion.X, Quaternion.W, -Quaternion.Z,
    Quaternion.X, Quaternion.Y, Quaternion.Z, Quaternion.W]
    )).Get3x3);
end;

constructor RMatrix4x3.CreateRotationX(const Angle : Single);
begin
  _11 := 1;
  _21 := 0;
  _31 := 0;
  _41 := 0;

  _12 := 0;
  _22 := Cos(Angle);
  _32 := sin(Angle);
  _42 := 0;

  _13 := 0;
  _23 := -self._32;
  _33 := self._22;
  _43 := 0;
end;

constructor RMatrix4x3.CreateRotationY(const Angle : Single);
begin
  _11 := Cos(Angle);
  _21 := 0;
  _31 := sin(Angle);
  _41 := 0;

  _12 := 0;
  _22 := 1;
  _32 := 0;
  _42 := 0;

  _13 := -self._31;
  _23 := 0;
  _33 := self._11;
  _43 := 0;
end;

constructor RMatrix4x3.CreateRotationZ(const Angle : Single);
begin
  _11 := Cos(Angle);
  _21 := sin(Angle);
  _31 := 0;
  _41 := 0;

  _12 := -_21;
  _22 := _11;
  _32 := 0;
  _42 := 0;

  _13 := 0;
  _23 := 0;
  _33 := 1;
  _43 := 0;

end;

constructor RMatrix4x3.CreateRotationZAroundPosition(const Position : RVector3; const Angle : Single);
begin
  self := RMatrix4x3.CreateTranslation(Position) * RMatrix4x3.CreateRotationZ(Angle) * RMatrix4x3.CreateTranslation(-Position);
end;

constructor RMatrix4x3.CreateScaling(const Scale : RVector3);
begin
  _11 := Scale.X;
  _21 := 0;
  _31 := 0;
  _41 := 0;

  _12 := 0;
  _22 := Scale.Y;
  _32 := 0;
  _42 := 0;

  _13 := 0;
  _23 := 0;
  _33 := Scale.Z;
  _43 := 0;
end;

constructor RMatrix4x3.CreateScaling(const Scale : Single);
begin
  _11 := Scale;
  _21 := 0;
  _31 := 0;
  _41 := 0;

  _12 := 0;
  _22 := Scale;
  _32 := 0;
  _42 := 0;

  _13 := 0;
  _23 := 0;
  _33 := Scale;
  _43 := 0;
end;

constructor RMatrix4x3.CreateSkew(const Skew : RVector2);
begin
  _11 := 1;
  _21 := tan(Skew.X);
  _31 := 0;
  _41 := 0;

  _12 := tan(Skew.Y);
  _22 := 1;
  _32 := 0;
  _42 := 0;

  _13 := 0;
  _23 := 0;
  _33 := 1;
  _43 := 0;
end;

function RMatrix4x3.GetTranslationComponent : RVector3;
begin
  Result.X := self._41;
  Result.Y := self._42;
  Result.Z := self._43;
end;

function RMatrix4x3.Interpolate(const Target : RMatrix4x3; Factor : Single) : RMatrix4x3;
var
  i : Integer;
begin
  for i := 0 to ELEMENT_COUNT - 1 do
      Result.Element[i] := Element[i] * (1 - Factor) + Target.Element[i] * Factor;
end;

function RMatrix4x3.Inverse : RMatrix4x3;
begin
  Result._11 := -_23 * _32 + _22 * _33;
  Result._12 := +_13 * _32 - _12 * _33;
  Result._13 := -_13 * _22 + _12 * _23;
  Result._21 := +_23 * _31 - _21 * _33;
  Result._22 := -_13 * _31 + _11 * _33;
  Result._23 := +_13 * _21 - _11 * _23;
  Result._31 := -_22 * _31 + _21 * _32;
  Result._32 := +_12 * _31 - _11 * _32;
  Result._33 := -_12 * _21 + _11 * _22;
  Result._41 := _23 * _32 * _41 - _22 * _33 * _41 - _23 * _31 * _42 + _21 * _33 * _42 + _22 * _31 * _43 - _21 * _32 * _43;
  Result._42 := _12 * _33 * _41 - _13 * _32 * _41 + _13 * _31 * _42 - _11 * _33 * _42 - _12 * _31 * _43 + _11 * _32 * _43;
  Result._43 := _13 * _22 * _41 - _12 * _23 * _41 - _13 * _21 * _42 + _11 * _23 * _42 + _12 * _21 * _43 - _11 * _22 * _43;
  if self.Determinant <> 0 then
      Result := Result / self.Determinant;
end;

function RMatrix4x3.IsZero : boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to ELEMENT_COUNT - 1 do Result := Result and (Element[i] = 0.0);
end;

constructor RMatrix4x3.CreateTranslation(const Position : RVector3);
begin
  _11 := 1;
  _21 := 0;
  _31 := 0;
  _41 := Position.X;

  _12 := 0;
  _22 := 1;
  _32 := 0;
  _42 := Position.Y;

  _13 := 0;
  _23 := 0;
  _33 := 1;
  _43 := Position.Z;
end;

function RMatrix4x3.Determinant : Single;
begin
  Result :=
    -_13 * _22 * _31 + _12 * _23 * _31 +
    _13 * _21 * _32 - _11 * _23 * _32 - _12 * _21 * _33 + _11 * _22 * _33;
end;

class operator RMatrix4x3.divide(const b : RMatrix4x3; const a : Single) : RMatrix4x3;
begin
  Result._11 := b._11 / a;
  Result._21 := b._21 / a;
  Result._31 := b._31 / a;
  Result._41 := b._41 / a;

  Result._12 := b._12 / a;
  Result._22 := b._22 / a;
  Result._32 := b._32 / a;
  Result._42 := b._42 / a;

  Result._13 := b._13 / a;
  Result._23 := b._23 / a;
  Result._33 := b._33 / a;
  Result._43 := b._43 / a;
end;

function RMatrix4x3.getColumn(Index : Integer) : RVector3;
begin
  case index of
    0 : Result := RVector3.Create(_11, _12, _13);
    1 : Result := RVector3.Create(_21, _22, _23);
    2 : Result := RVector3.Create(_31, _32, _33);
    3 : Result := RVector3.Create(_41, _42, _43);
  else
    raise EInvalidArgument.Create('RMatrix4x3.getColumn: Wrong column index!');
  end;
end;

class operator RMatrix4x3.multiply(a : Single; const b : RMatrix4x3) : RMatrix4x3;
begin
  Result._11 := b._11 * a;
  Result._21 := b._21 * a;
  Result._31 := b._31 * a;
  Result._41 := b._41 * a;

  Result._12 := b._12 * a;
  Result._22 := b._22 * a;
  Result._32 := b._32 * a;
  Result._42 := b._42 * a;

  Result._13 := b._13 * a;
  Result._23 := b._23 * a;
  Result._33 := b._33 * a;
  Result._43 := b._43 * a;
end;

class operator RMatrix4x3.multiply(const a : RMatrix4x3; b : Single) : RMatrix4x3;
begin
  Result._11 := a._11 * b;
  Result._21 := a._21 * b;
  Result._31 := a._31 * b;
  Result._41 := a._41 * b;

  Result._12 := a._12 * b;
  Result._22 := a._22 * b;
  Result._32 := a._32 * b;
  Result._42 := a._42 * b;

  Result._13 := a._13 * b;
  Result._23 := a._23 * b;
  Result._33 := a._33 * b;
  Result._43 := a._43 * b;
end;

class operator RMatrix4x3.multiply(const a, b : RMatrix4x3) : RMatrix4x3;
begin
  Result._11 := a._11 * b._11 + a._21 * b._12 + a._31 * b._13;
  Result._21 := a._11 * b._21 + a._21 * b._22 + a._31 * b._23;
  Result._31 := a._11 * b._31 + a._21 * b._32 + a._31 * b._33;
  Result._41 := a._11 * b._41 + a._21 * b._42 + a._31 * b._43 + a._41;

  Result._12 := a._12 * b._11 + a._22 * b._12 + a._32 * b._13;
  Result._22 := a._12 * b._21 + a._22 * b._22 + a._32 * b._23;
  Result._32 := a._12 * b._31 + a._22 * b._32 + a._32 * b._33;
  Result._42 := a._12 * b._41 + a._22 * b._42 + a._32 * b._43 + a._42;

  Result._13 := a._13 * b._11 + a._23 * b._12 + a._33 * b._13;
  Result._23 := a._13 * b._21 + a._23 * b._22 + a._33 * b._23;
  Result._33 := a._13 * b._31 + a._23 * b._32 + a._33 * b._33;
  Result._43 := a._13 * b._41 + a._23 * b._42 + a._33 * b._43 + a._43;
end;

class operator RMatrix4x3.multiply(const a : RMatrix4x3; const b : RVector3) : RVector3;
begin
  Result.X := a._11 * b.X + a._21 * b.Y + a._31 * b.Z + a._41;
  Result.Y := a._12 * b.X + a._22 * b.Y + a._32 * b.Z + a._42;
  Result.Z := a._13 * b.X + a._23 * b.Y + a._33 * b.Z + a._43;
end;

procedure RMatrix4x3.setColumn(Index : Integer; const Value : RVector3);
begin
  case index of
    0 :
      begin
        _11 := Value.X;
        _12 := Value.Y;
        _13 := Value.Z;
      end;
    1 :
      begin
        _21 := Value.X;
        _22 := Value.Y;
        _23 := Value.Z;
      end;
    2 :
      begin
        _31 := Value.X;
        _32 := Value.Y;
        _33 := Value.Z;
      end;
    3 :
      begin
        _41 := Value.X;
        _42 := Value.Y;
        _43 := Value.Z;
      end;
  else
    raise EInvalidArgument.Create('RMatrix4x3.setColumn: Wrong column index!');
  end;
end;

procedure RMatrix4x3.SetTranslationComponent(const V : RVector3);
begin
  self._41 := V.X;
  self._42 := V.Y;
  self._43 := V.Z;
end;

class operator RMatrix4x3.subtract(const a, b : RMatrix4x3) : RMatrix4x3;
begin
  Result._11 := a._11 - b._11;
  Result._21 := a._21 - b._21;
  Result._31 := a._31 - b._31;
  Result._41 := a._41 - b._41;

  Result._12 := a._12 - b._12;
  Result._22 := a._22 - b._22;
  Result._32 := a._32 - b._32;
  Result._42 := a._42 - b._42;

  Result._13 := a._13 - b._13;
  Result._23 := a._23 - b._23;
  Result._33 := a._33 - b._33;
  Result._43 := a._43 - b._43;
end;

procedure RMatrix4x3.SwapXY;
var
  temp : RVector3;
begin
  temp := Column[0];
  Column[0] := Column[1];
  Column[1] := temp;
end;

procedure RMatrix4x3.SwapXZ;
var
  temp : RVector3;
begin
  temp := Column[2];
  Column[2] := Column[1];
  Column[1] := temp;
end;

procedure RMatrix4x3.SwapYZ;
var
  temp : RVector3;
begin
  temp := Column[1];
  Column[1] := Column[2];
  Column[2] := temp;
end;

function RMatrix4x3.To3x3 : RMatrix4x3;
begin
  Result := self;
  Result.Translation := RVector3.ZERO;
end;

function RMatrix4x3.To4x4 : RMatrix;
begin
  Result._11 := self._11;
  Result._21 := self._21;
  Result._31 := self._31;
  Result._41 := self._41;

  Result._12 := self._12;
  Result._22 := self._22;
  Result._32 := self._32;
  Result._42 := self._42;

  Result._13 := self._13;
  Result._23 := self._23;
  Result._33 := self._33;
  Result._43 := self._43;

  Result._14 := 0.0;
  Result._24 := 0.0;
  Result._34 := 0.0;
  Result._44 := 1.0;
end;

function RMatrix4x3.ToQuaternion : RVector4;
begin
  Result.W := 1 + self._11 + self._22 + self._33;
  if Result.W > 0 then
  begin
    Result.W := sqrt(Result.W) / 2.0;
    Result.X := (self._32 - self._23) / (4 * Result.W);
    Result.Y := (self._13 - self._31) / (4 * Result.W);
    Result.Z := (self._21 - self._12) / (4 * Result.W);
  end
  else
      Result := RVector4.ZERO;
end;

function RMatrix4x3.Transpose : RMatrix4x3;
begin
  Result._11 := self._11;
  Result._21 := self._12;
  Result._31 := self._13;
  Result._41 := self._41;

  Result._12 := self._21;
  Result._22 := self._22;
  Result._32 := self._23;
  Result._42 := self._42;

  Result._13 := self._31;
  Result._23 := self._32;
  Result._33 := self._33;
  Result._43 := self._43;
end;

class operator RMatrix4x3.add(const a, b : RMatrix4x3) : RMatrix4x3;
begin
  Result._11 := a._11 + b._11;
  Result._21 := a._21 + b._21;
  Result._31 := a._31 + b._31;
  Result._41 := a._41 + b._41;

  Result._12 := a._12 + b._12;
  Result._22 := a._22 + b._22;
  Result._32 := a._32 + b._32;
  Result._42 := a._42 + b._42;

  Result._13 := a._13 + b._13;
  Result._23 := a._23 + b._23;
  Result._33 := a._33 + b._33;
  Result._43 := a._43 + b._43;
end;

{ RMatrixHelper }

function RMatrixHelper.To4x3 : RMatrix4x3;
begin
  Result._11 := self._11;
  Result._21 := self._21;
  Result._31 := self._31;
  Result._41 := self._41;

  Result._12 := self._12;
  Result._22 := self._22;
  Result._32 := self._32;
  Result._42 := self._42;

  Result._13 := self._13;
  Result._23 := self._23;
  Result._33 := self._33;
  Result._43 := self._43;
end;

{ RTuple<T, U> }

constructor RTuple<T, U>.Create(a : T; b : U);
begin
  self.a := a;
  self.b := b;
end;

function RTuple<T, U>.SetA(const newA : T) : RTuple<T, U>;
begin
  Result.a := newA;
  Result.b := self.b;
end;

function RTuple<T, U>.SetB(const newB : U) : RTuple<T, U>;
begin
  Result.a := self.a;
  Result.b := newB;
end;

{ RCubicBezier }

constructor RCubicBezier.Create(P1X, P1Y, P2X, P2Y : Single);
begin
  self.P1X := P1X;
  self.P1Y := P1Y;
  self.P2X := P2X;
  self.P2Y := P2Y;
end;

class function RCubicBezier.EASE : RCubicBezier;
begin
  Result := RCubicBezier.Create(0.25, 0.1, 0.25, 1.0);
end;

class function RCubicBezier.EASEIN : RCubicBezier;
begin
  Result := RCubicBezier.Create(0.42, 0, 1.0, 1.0);
end;

class function RCubicBezier.EASEINOUT : RCubicBezier;
begin
  Result := RCubicBezier.Create(0.42, 0, 0.58, 1.0);
end;

class function RCubicBezier.EASEOUT : RCubicBezier;
begin
  Result := RCubicBezier.Create(0, 0, 0.58, 1.0);
end;

class function RCubicBezier.LINEAR : RCubicBezier;
begin
  Result := RCubicBezier.Create(0, 0, 1, 1);
end;

function RCubicBezier.Solve(T : Single; Epsilon : Single) : Single;
var
  cx, bx, aX, cy, by, aY : Single;
  function sampleCurveX(s : Single) : Single;
  begin
    Result := ((aX * s + bx) * s + cx) * s;
  end;
  function sampleCurveY(s : Single) : Single;
  begin
    Result := ((aY * s + by) * s + cy) * s;
  end;
  function sampleCurveDerivativeX(s : Single) : Single;
  begin
    Result := (3.0 * aX * s + 2.0 * bx) * s + cx;
  end;
  function solveCurveX(X, Epsilon : Single) : Single;
  var
    t0, t1, t2, x2, d2 : Single;
    i : Integer;
  begin
    t2 := X;
    for i := 0 to 7 do
    begin
      x2 := sampleCurveX(t2) - X;
      if Abs(x2) < Epsilon then
          exit(t2);
      d2 := sampleCurveDerivativeX(t2);
      if Abs(d2) < 1E-6 then
          break;
      t2 := t2 - x2 / d2;
    end;
    // Fall back to the bisection method for reliability.
    t0 := 0.0;
    t1 := 1.0;
    t2 := X;

    if (t2 < t0) then
        exit(t0);

    if (t2 > t1) then
        exit(t1);

    while (t0 < t1) do
    begin
      x2 := sampleCurveX(t2);
      if Abs(x2 - X) < Epsilon then
          exit(t2);
      if (X > x2) then
          t0 := t2
      else
          t1 := t2;
      t2 := (t1 - t0) * 0.5 + t0;
    end;

    exit(t2);
  end;

begin
  T := HMath.Saturate(T);
  cx := 3.0 * P1X;
  bx := 3.0 * (P2X - P1X) - cx;
  aX := 1.0 - cx - bx;
  cy := 3.0 * P1Y;
  by := 3.0 * (P2Y - P1Y) - cy;
  aY := 1.0 - cy - by;
  Result := sampleCurveY(solveCurveX(T, Epsilon));
end;

initialization

EngineFloatFormatSettings := TFormatSettings.Create('de-DE');
EngineFloatFormatSettings.DecimalSeparator := '.';

end.
