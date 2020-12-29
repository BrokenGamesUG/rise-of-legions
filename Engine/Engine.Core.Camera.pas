unit Engine.Core.Camera;

interface

uses
  Engine.Math,
  RTTI,
  Engine.Core.Types,
  Engine.Math.Collision3D,
  Generics.Collections,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.GfxApi.Types;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  /// <summary> a compact record with all essential data of a camera </summary>
  RCameraData = record
    Position, Target, Up : RVector3;
    Nearplane, Farplane : Single;
    AspectRatio, FieldOfView : Single;    // only perspective camera
    Width, Height : Single;               // only orthogonal camera
    WithoutNearFarPlaneCulling : boolean; // frustumculling without near and far plane
    VFDSkal : Single;
    Orthogonal : boolean;
    // computed values
    ScreenLeft, ScreenUp, CameraDirection : RVector3;
  end;

  TCameraShaker = class;

  /// <summary> A scene-camera </summary>
  TCamera = class
    private
      procedure SetPosition(const Value : RVector3);
      procedure SetDirection(const Value : RVector3);
      procedure SetFieldOfView(const Value : Single);
      procedure SetTarget(const Value : RVector3);
    protected
      FFrustum : RFrustum;
      FCameraData : RCameraData;
      FResolution : RIntVector2;
      FView, FProjection : RMatrix;
      FShaker : TObjectList<TCameraShaker>;
      procedure CreateVFD;
      procedure ComputeAll;
      procedure ComputeView;
      procedure ComputeProjection;
      procedure ComputeSecondaryVectors;
      procedure SetCameraData(const CameraDaten : RCameraData);
    public
      /// <summary> The frustum of the current view. </summary>
      property ViewingFrustum : RFrustum read FFrustum;
      /// <summary> The normalized left-direction of the camera in worldspace </summary>
      property ScreenLeft : RVector3 read FCameraData.ScreenLeft;
      /// <summary> The normalized up-direction of the camera in worldspace </summary>
      property ScreenUp : RVector3 read FCameraData.ScreenUp;
      /// <summary> The normalized look-direction of the camera in worldspace </summary>
      property CameraDirection : RVector3 read FCameraData.CameraDirection write SetDirection;
      /// <summary> The view matrix </summary>
      property View : RMatrix read FView;
      /// <summary> The projection matrix </summary>
      property Projection : RMatrix read FProjection;
      /// <summary> The position of the camera </summary>
      property Position : RVector3 read FCameraData.Position write SetPosition;
      /// <summary> The up vector of the camera </summary>
      property Up : RVector3 read FCameraData.Up;
      /// <summary> The position of the camera </summary>
      property Target : RVector3 read FCameraData.Target write SetTarget;
      /// <summary> The FoV of the camera. </summary>
      property FieldOfView : Single read FCameraData.FieldOfView write SetFieldOfView;
      /// <summary> all essential camera data in one record </summary>
      property CameraData : RCameraData read FCameraData write SetCameraData;
      procedure Move(const Offset : RVector3);
      constructor Create(ResolutionWidth, ResolutionHeight : cardinal); overload;
      constructor Create(Resolution : RIntVector2); overload;
      /// <summary> Projects a screenposition into worldspace. (View ray in this pixel direction) </summary>
      function ScreenSpaceToWorldSpace(ScreenPosition : RVector2) : RRay;
      /// <summary> Projects a worldposition into screenspace </summary>
      function WorldSpaceToScreenSpace(WorldPosition : RVector3) : RVector3;
      /// <summary> Try to project a worldposition into screenspace. Returns whether resulting point is in view (not out of the sides or behind). </summary>
      function TryWorldSpaceToScreenSpace(WorldPosition : RVector3; out ScreenSpacePosition : RVector3) : boolean;
      /// <summary> Returns the ray the relative screencoordinate points to. </summary>
      function Clickvector(ScreenPosition : RVector2) : RRay; overload;
      /// <summary> Returns the ray the relative screencoordinate points to. </summary>
      function Clickvector(ScreenPositionX, ScreenPositionY : Single) : RRay; overload;
      /// <summary> Returns the ray the absolute screencoordinate points to. </summary>
      function Clickvector(ScreenPosition : RIntVector2) : RRay; overload;
      /// <summary> Returns the ray the absolute screencoordinate points to. </summary>
      function Clickvector(ScreenPositionX, ScreenPositionY : integer) : RRay; overload;
      /// <summary> Determines whether the given sphere can be seen or not </summary>
      function IsSphereVisible(Sphere : RSphere) : boolean;
      /// <summary> Determines whether the given axis-aligned bounding box can be seen or not </summary>
      function IsAABBVisible(MinMaxBox : RAABB) : boolean;
      function ViewProjectionInverse : RMatrix;
      // wenn ein Value nicht angegeben wird, wird der zuletzt gesetzte genommen
      // wenn dieser Value noch nie angegeben wurde, wird der Default-Value genommen
      procedure PerspectiveCamera(Camera, Ziel, Oben : RVector3; Seitenverhaeltnis, Nah, Fern : Single); overload;
      procedure PerspectiveCamera(Camera, Ziel, Oben : RVector3; Seitenverhaeltnis : Single); overload;
      procedure PerspectiveCamera(Camera, Ziel : RVector3; Seitenverhaeltnis : Single); overload;
      procedure PerspectiveCamera(Camera, Ziel, Oben : RVector3); overload;
      procedure PerspectiveCamera(Camera, Ziel : RVector3); overload;
      procedure OrthogonalCamera(Camera, Ziel, Oben : RVector3; Breite, Hoehe, Nah, Fern : Single); overload;
      procedure OrthogonalCamera(Camera, Ziel, Oben : RVector3; Breite, Hoehe : Single); overload;
      procedure OrthogonalCamera(Camera, Ziel, Oben : RVector3); overload;
      procedure OrthogonalCamera(Camera, Ziel : RVector3); overload;
      procedure OrthogonalCamera(Camera, Ziel : RVector3; Breite, Hoehe : Single); overload;
      procedure Idle;
      procedure UpdateResolution(const NewSize : RIntVector2);
      /// <summary> Adds a shaker to the camera. The camera will manage the shaker afterwards. </summary>
      procedure AddShaker(Shaker : TCameraShaker);
      procedure RemoveShaker(Shaker : TCameraShaker);
      destructor Destroy; override;
  end;

  /// <summary> Shakes the camera for a given duration. </summary>
  TCameraShaker = class
    private
      function getDuration : integer;
      procedure setDuration(const Value : integer);
    protected
      FDuration : TTimer;
      FAffectTarget, FNoFade : boolean;
      function Alive : boolean;
      function Progress : Single;
      function Fade : Single;
    public
      Waves : integer;
      Position : ISharedData<RVector3>;
      /// <summary>The effect will rise instead of decay with this option. </summary>
      Invert : boolean;
      /// <summary> The effect will apply to the camera disregarding the distance to the shaker. </summary>
      Global : boolean;
      property Duration : integer read getDuration write setDuration;
      constructor Create(Duration : Int64; AffectTarget : boolean);
      function Delay(DelayMs : integer) : TCameraShaker;
      function NoFade : TCameraShaker;
      function GetShakeVector : RVector3; virtual;
      function GetShakeRotationVector : RVector3; virtual;
      destructor Destroy; override;
  end;

  /// <summary> Shakes the camera randomly inside the radius. </summary>
  TCameraShakerRadial = class(TCameraShaker)
    protected
      FRadius : Single;
    public
      constructor Create(Duration : Int64; AffectTarget : boolean; Radius : Single);
      function GetShakeVector : RVector3; override;
  end;

  /// <summary> Shakes the camera along the vector. </summary>
  TCameraShakerVector = class(TCameraShaker)
    protected
      FVector : RVector3;
    public
      constructor Create(Duration : Int64; AffectTarget : boolean; Vector : RVector3);
      function GetShakeVector : RVector3; override;
  end;

  /// <summary> Shakes the camera with a rotation in its base. </summary>
  TCameraShakerRotation = class(TCameraShaker)
    protected
      FRotation : RVector3;
    public
      constructor Create(Duration : Int64; AffectTarget : boolean; Rotation : RVector3);
      function GetShakeRotationVector : RVector3; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

uses
  Engine.Core;

{ TCamera }

constructor TCamera.Create(Resolution : RIntVector2);
begin
  Create(Resolution.X, Resolution.Y);
end;

procedure TCamera.CreateVFD;
var
  mat, skal : RMatrix;
begin
  with FCameraData do
  begin
    if VFDSkal <> 1 then
    begin
      skal := RMatrix.CreateLookAtLH(Target + ((Position - Target) * VFDSkal), Target, Up);
      mat := self.Projection * skal;
    end
    else mat := self.Projection * self.View;
  end;
  FFrustum := RFrustum.CreateFromViewProjectionMatrix(mat);
end;

destructor TCamera.Destroy;
begin
  FShaker.Free;
end;

constructor TCamera.Create(ResolutionWidth, ResolutionHeight : cardinal);
begin
  with FCameraData do
  begin
    WithoutNearFarPlaneCulling := False;
    VFDSkal := 1;
    Up := RVector3.Create(0, 1, 0);
    Nearplane := DEFAULTCAMERANAH;
    Farplane := DEFAULTCAMERAFERN;
    FieldOfView := DEFAULTCAMERAFOVY;
    Width := 100;
    Height := 100;
  end;
  UpdateResolution(RIntVector2.Create(ResolutionWidth, ResolutionHeight));
  FShaker := TObjectList<TCameraShaker>.Create;
end;

procedure TCamera.AddShaker(Shaker : TCameraShaker);
begin
  FShaker.Add(Shaker);
end;

function TCamera.IsSphereVisible(Sphere : RSphere) : boolean;
begin
  Result := FFrustum.IntersectSphere(Sphere);
end;

procedure TCamera.Move(const Offset : RVector3);
begin
  FCameraData.Position := FCameraData.Position + Offset;
  FCameraData.Target := FCameraData.Target + Offset;
  ComputeAll;
end;

procedure TCamera.Idle;
var
  i : integer;
  temp, temp2, temp3, Front, Left, Up, ShakingVector, ShakingRotation, ShakingTargetVector : RVector3;
  CameraSpace : RMatrix;
begin
  i := 0;
  ShakingVector := RVector3.ZERO;
  ShakingTargetVector := RVector3.ZERO;
  ShakingRotation := RVector3.ZERO;
  while i < FShaker.Count do
  begin
    if FShaker[i].Alive then
    begin
      // translation
      temp := FShaker[i].GetShakeVector;
      if not FShaker[i].Global then
          temp := temp * (1 - HMath.Saturate(ViewingFrustum.DistanceToPoint(FShaker[i].Position.GetData) / Position.Distance(Target)));
      ShakingVector := ShakingVector + temp;
      if FShaker[i].FAffectTarget then ShakingTargetVector := ShakingTargetVector + temp;
      // rotation
      temp := FShaker[i].GetShakeRotationVector;
      if not FShaker[i].Global then
          temp := temp * (1 - HMath.Saturate(ViewingFrustum.DistanceToPoint(FShaker[i].Position.GetData) / Position.Distance(Target)));
      ShakingRotation := ShakingRotation + temp;
      inc(i);
    end
    else
    begin
      FShaker.Exchange(i, FShaker.Count - 1);
      FShaker.Delete(FShaker.Count - 1);
    end;
  end;
  if not ShakingVector.IsZeroVector or not ShakingRotation.IsZeroVector then
  begin
    temp := FCameraData.Position;
    temp2 := FCameraData.Target;
    temp3 := FCameraData.Up;
    FCameraData.Position := FCameraData.Position + ShakingVector;
    FCameraData.Target := FCameraData.Target + ShakingTargetVector;

    Front := FCameraData.Position.DirectionTo(FCameraData.Target);
    Left := Front.Cross(FCameraData.Up).Normalize;
    Up := -Front.Cross(Left).Normalize;
    CameraSpace := RMatrix.CreateBase(Left, Up, Front);
    CameraSpace := CameraSpace * RMatrix.CreateRotationPitchYawRoll(ShakingRotation) * CameraSpace.Inverse;
    FCameraData.Up := CameraSpace * Up;
    FCameraData.Target := FCameraData.Position + CameraSpace * Front;

    ComputeAll;
    FCameraData.Position := temp;
    FCameraData.Target := temp2;
    FCameraData.Up := temp3;
  end;
end;

function TCamera.IsAABBVisible(MinMaxBox : RAABB) : boolean;
begin
  Result := FFrustum.IntersectAABB(MinMaxBox);
end;

procedure TCamera.ComputeProjection;
begin
  with FCameraData do
    if Orthogonal then FProjection := RMatrix.CreateOrthoLH(Width, Height, Nearplane, Farplane)
    else FProjection := RMatrix.CreatePerspectiveFovLH(FieldOfView, AspectRatio, Nearplane, Farplane);
end;

procedure TCamera.ComputeView;
begin
  with FCameraData do FView := RMatrix.CreateLookAtLH(Position, Target, Up);
end;

procedure TCamera.ComputeSecondaryVectors;
begin
  FCameraData.CameraDirection := (FCameraData.Target - FCameraData.Position).Normalize;
  FCameraData.ScreenLeft := CameraDirection.Cross(FCameraData.Up).Normalize;
  FCameraData.ScreenUp := ScreenLeft.Cross(CameraDirection).Normalize;
end;

procedure TCamera.OrthogonalCamera(Camera, Ziel, Oben : RVector3;
  Breite, Hoehe, Nah, Fern : Single);
begin
  FCameraData.Orthogonal := true;
  FCameraData.Nearplane := Nah;
  FCameraData.Farplane := Fern;
  FCameraData.Position := Camera;
  FCameraData.Target := Ziel;
  FCameraData.Up := Oben;
  FCameraData.Width := Breite;
  FCameraData.Height := Hoehe;
  ComputeAll;
end;

procedure TCamera.PerspectiveCamera(Camera, Ziel, Oben : RVector3;
  Seitenverhaeltnis, Nah, Fern : Single);
begin
  FCameraData.Orthogonal := False;
  FCameraData.AspectRatio := Seitenverhaeltnis;
  FCameraData.Nearplane := Nah;
  FCameraData.Farplane := Fern;
  FCameraData.Position := Camera;
  FCameraData.Target := Ziel;
  FCameraData.Up := Oben;
  ComputeAll;
end;

procedure TCamera.ComputeAll;
begin
  ComputeProjection;
  ComputeView;
  CreateVFD;
  ComputeSecondaryVectors;
end;

procedure TCamera.PerspectiveCamera(Camera, Ziel, Oben : RVector3;
  Seitenverhaeltnis : Single);
begin
  PerspectiveCamera(Camera, Ziel, Oben, Seitenverhaeltnis, FCameraData.Nearplane, FCameraData.Farplane);
end;

procedure TCamera.PerspectiveCamera(Camera, Ziel : RVector3;
  Seitenverhaeltnis : Single);
begin
  PerspectiveCamera(Camera, Ziel, FCameraData.Up, Seitenverhaeltnis, FCameraData.Nearplane, FCameraData.Farplane);
end;

procedure TCamera.PerspectiveCamera(Camera, Ziel : RVector3);
begin
  PerspectiveCamera(Camera, Ziel, FCameraData.Up, FCameraData.AspectRatio, FCameraData.Nearplane, FCameraData.Farplane);
end;

procedure TCamera.RemoveShaker(Shaker : TCameraShaker);
begin
  FShaker.Remove(Shaker);
end;

procedure TCamera.PerspectiveCamera(Camera, Ziel, Oben : RVector3);
begin
  PerspectiveCamera(Camera, Ziel, Oben, FCameraData.AspectRatio, FCameraData.Nearplane, FCameraData.Farplane);
end;

procedure TCamera.OrthogonalCamera(Camera, Ziel, Oben : RVector3; Breite, Hoehe : Single);
begin
  OrthogonalCamera(Camera, Ziel, Oben, Breite, Hoehe, FCameraData.Nearplane, FCameraData.Farplane);
end;

procedure TCamera.OrthogonalCamera(Camera, Ziel, Oben : RVector3);
begin
  OrthogonalCamera(Camera, Ziel, Oben, FCameraData.Width, FCameraData.Height, FCameraData.Nearplane, FCameraData.Farplane);
end;

procedure TCamera.OrthogonalCamera(Camera, Ziel : RVector3; Breite, Hoehe : Single);
begin
  OrthogonalCamera(Camera, Ziel, FCameraData.Up, Breite, Hoehe, FCameraData.Nearplane, FCameraData.Farplane);
end;

procedure TCamera.OrthogonalCamera(Camera, Ziel : RVector3);
begin
  OrthogonalCamera(Camera, Ziel, FCameraData.Up, FCameraData.Width, FCameraData.Height, FCameraData.Nearplane, FCameraData.Farplane);
end;

function TCamera.ScreenSpaceToWorldSpace(ScreenPosition : RVector2) : RRay;
var
  NDC : RVector3;
begin
  NDC := (ScreenPosition * 2 - 1).XY0.NegateY;
  Result.Origin := Position;
  Result.Direction := (ViewProjectionInverse * NDC) - Position;
end;

procedure TCamera.SetCameraData(const CameraDaten : RCameraData);
begin
  self.FCameraData := CameraDaten;
  ComputeAll;
end;

procedure TCamera.SetDirection(const Value : RVector3);
begin
  FCameraData.Target := FCameraData.Position + Value;
  ComputeAll;
end;

procedure TCamera.SetFieldOfView(const Value : Single);
begin
  FCameraData.FieldOfView := Value;
  ComputeAll;
end;

procedure TCamera.SetPosition(const Value : RVector3);
begin
  FCameraData.Position := Value;
  ComputeAll;
end;

procedure TCamera.SetTarget(const Value : RVector3);
begin
  FCameraData.Target := Value;
  ComputeAll;
end;

function TCamera.TryWorldSpaceToScreenSpace(WorldPosition : RVector3; out ScreenSpacePosition : RVector3) : boolean;
begin
  Result := IsSphereVisible(RSphere.CreateSphere(WorldPosition, 0.0));
  if Result then
      ScreenSpacePosition := WorldSpaceToScreenSpace(WorldPosition);
end;

procedure TCamera.UpdateResolution(const NewSize : RIntVector2);
begin
  FResolution := NewSize;
  FCameraData.AspectRatio := FResolution.X / FResolution.Y;
end;

function TCamera.ViewProjectionInverse : RMatrix;
begin
  Result := (Projection * View).Inverse;
end;

function TCamera.WorldSpaceToScreenSpace(WorldPosition : RVector3) : RVector3;
var
  NDC : RVector3;
begin
  NDC := Projection * View * WorldPosition;
  Result := ((NDC.XY * RVector2.Create(1, -1) + 1) * 0.5 * FResolution).XY0(NDC.Z);
end;

function TCamera.Clickvector(ScreenPosition : RVector2) : RRay;
var
  matInvView : RMatrix;
  Origin, Dir, v : RVector3;
begin
  // IX,IY ist die Mausposition auf der Direct3DOberfläche
  if self.FCameraData.Orthogonal then
  begin
    Origin := FCameraData.Position + ((-ScreenLeft) * (ScreenPosition.X - 0.5) * FCameraData.Width) + ((-ScreenUp) * (ScreenPosition.Y - 0.5) * FCameraData.Height);
    Dir := CameraDirection;
    Dir.Normalize;
  end
  else
  begin
    v.X := ((2 * ScreenPosition.X) - 1) / FProjection._11;
    v.Y := -((2 * ScreenPosition.Y) - 1) / FProjection._22;
    v.Z := 1;
    matInvView := FView.Inverse;
    Dir.X := v.X * matInvView._11 + v.Y * matInvView._21 + v.Z * matInvView._31;
    Dir.Y := v.X * matInvView._12 + v.Y * matInvView._22 + v.Z * matInvView._32;
    Dir.Z := v.X * matInvView._13 + v.Y * matInvView._23 + v.Z * matInvView._33;
    Dir.InNormalize;
    Origin.X := matInvView._41;
    Origin.Y := matInvView._42;
    Origin.Z := matInvView._43;
  end;
  Result := RRay.Create(Origin, Dir);
end;

function TCamera.Clickvector(ScreenPosition : RIntVector2) : RRay;
begin
  Result := Clickvector(RVector2(ScreenPosition) / FResolution);
end;

function TCamera.Clickvector(ScreenPositionX, ScreenPositionY : integer) : RRay;
begin
  Result := Clickvector(RIntVector2.Create(ScreenPositionX, ScreenPositionY));
end;

function TCamera.Clickvector(ScreenPositionX, ScreenPositionY : Single) : RRay;
begin
  Result := Clickvector(RVector2.Create(ScreenPositionX, ScreenPositionY));
end;

{ TCameraShaker }

function TCameraShaker.Alive : boolean;
begin
  Result := not FDuration.Expired;
end;

constructor TCameraShaker.Create(Duration : Int64; AffectTarget : boolean);
begin
  Waves := 5;
  FDuration := TTimer.CreateAndStart(Duration);
  FAffectTarget := AffectTarget;
  Position := TSharedData<RVector3>.Create;
end;

function TCameraShaker.Delay(DelayMs : integer) : TCameraShaker;
begin
  Result := self;
  FDuration.Delay(DelayMs);
end;

destructor TCameraShaker.Destroy;
begin
  FDuration.Free;
  inherited;
end;

function TCameraShaker.Fade : Single;
begin
  if FNoFade then
      Result := 1
  else
      Result := Progress;
end;

function TCameraShaker.getDuration : integer;
begin
  Result := FDuration.Interval;
end;

function TCameraShaker.GetShakeRotationVector : RVector3;
begin
  Result := RVector3.ZERO;
end;

function TCameraShaker.GetShakeVector : RVector3;
begin
  Result := RVector3.ZERO;
end;

function TCameraShaker.NoFade : TCameraShaker;
begin
  Result := self;
  FNoFade := true;
end;

function TCameraShaker.Progress : Single;
begin
  if Invert then Result := FDuration.Progress
  else Result := FDuration.ProgressInverted;
end;

procedure TCameraShaker.setDuration(const Value : integer);
begin
  FDuration.Interval := Value;
end;

{ TCameraShakerRadial }

constructor TCameraShakerRadial.Create(Duration : Int64; AffectTarget : boolean; Radius : Single);
begin
  inherited Create(Duration, AffectTarget);
  FRadius := Radius;
end;

function TCameraShakerRadial.GetShakeVector : RVector3;
begin
  Result := RVector3.getRandomPointInSphere(FRadius) * Progress * Fade;
end;

{ TCameraShakerVector }

constructor TCameraShakerVector.Create(Duration : Int64; AffectTarget : boolean; Vector : RVector3);
begin
  inherited Create(Duration, AffectTarget);
  FVector := Vector;
end;

function TCameraShakerVector.GetShakeVector : RVector3;
begin
  Result := FVector * sin(Progress * PI * 2 * Waves) * Fade;
end;

{ TCameraShakerRotation }

constructor TCameraShakerRotation.Create(Duration : Int64; AffectTarget : boolean; Rotation : RVector3);
begin
  inherited Create(Duration, AffectTarget);
  FRotation := Rotation;
end;

function TCameraShakerRotation.GetShakeRotationVector : RVector3;
begin
  Result := FRotation * sin(Progress * PI * 2 * Waves) * Fade;
end;

end.
