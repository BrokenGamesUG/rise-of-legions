unit Engine.Physics;

interface

uses
  Engine.Math,
  Engine.Math.Collision3D,
  generics.Collections;

type

{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  TObstacle = class
    protected
    public
      procedure Apply(var Position, MovementVector: RVector3); virtual; abstract;
  end;

  TPlaneObstacle = class(TObstacle)
    protected
    public
      Plane : RPlane;
      constructor Create(Obstacle : RPlane);
      procedure Apply(var Position, MovementVector: RVector3); override;
  end;


  TForceField = class
    protected
    public
      function getForceAtPosition(Position : RVector3) : RVector3; virtual; abstract;
  end;

  TGlobalForceField = class(TForceField)
    protected
    public
      Direction : RVector3;
      constructor Create(Force : RVector3);
      function getForceAtPosition(Position : RVector3) : RVector3; override;
  end;

  TCuboidForceField = class(TForceField)
    protected
    public
      Base : RMatrix;
      Position, Size : RVector3;
      Strength : single;
      constructor Create(Position, Size : RVector3; Base : RMatrix; Strength : single);
      function getForceAtPosition(Position : RVector3) : RVector3; override;
  end;

  TBlackHoleForceField = class(TForceField)
    protected
    public
      Position : RVector3;
      Radius, Strength : single;
      constructor Create(Position : RVector3; Radius, Strength : single);
      function getForceAtPosition(Position : RVector3) : RVector3; override;
  end;

  TWhiteHoleForceField = class(TBlackHoleForceField)
    constructor Create(Position : RVector3; Radius, Strength : single);
  end;

  TVortexForceField = class(TForceField)
    protected
    public
      Position, Axis : RVector3;
      Radius, Strength : single;
      constructor Create(Position, Axis : RVector3; Radius, Strength : single);
      function getForceAtPosition(Position : RVector3) : RVector3; override;
  end;

  TConeForceField = class(TForceField)
    protected
    public
      Position, Direction : RVector3;
      Radius, Strength : single;
      constructor Create(Position, Direction : RVector3; Radius, Strength : single);
      function getForceAtPosition(Position : RVector3) : RVector3; override;
  end;

  TPhysicManager = class
    protected
      FForceFields : TObjectList<TForceField>;
      FObstacles : TObjectList<TObstacle>;
    public
      constructor Create;
      procedure AddForceField(ForceField : TForceField);
      procedure AddObstacle(Obstacle : TObstacle);
      function getForceAtPosition(Position : RVector3) : RVector3;
      procedure ApplyObstacles(var Position, Direction : RVector3);
      destructor Destroy; override;
  end;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  PhysicManager : TPhysicManager;

implementation

{ TGlobalForceField }

constructor TGlobalForceField.Create(Force : RVector3);
begin
  Direction := Force;
end;

function TGlobalForceField.getForceAtPosition(Position : RVector3) : RVector3;
begin
  Result := Direction;
end;

{ TPhysicManager }

procedure TPhysicManager.AddForceField(ForceField : TForceField);
begin
  FForceFields.Add(ForceField);
end;

procedure TPhysicManager.AddObstacle(Obstacle: TObstacle);
begin
  FObstacles.Add(Obstacle);
end;

procedure TPhysicManager.ApplyObstacles(var Position, Direction: RVector3);
var
  i : integer;
begin
  for i := 0 to FObstacles.Count - 1 do FObstacles[i].Apply(Position, Direction);
end;

constructor TPhysicManager.Create;
begin
  FForceFields := TObjectList<TForceField>.Create;
  FObstacles := TObjectList<TObstacle>.Create;
end;

destructor TPhysicManager.Destroy;
begin
  FForceFields.Free;
  FObstacles.Free;
  inherited;
end;

function TPhysicManager.getForceAtPosition(Position : RVector3) : RVector3;
var
  i : integer;
begin
  Result := RVector3.ZERO;
  for i := 0 to FForceFields.Count - 1 do Result := Result + FForceFields[i].getForceAtPosition(Position);
end;

{ TCuboidForceField }

constructor TCuboidForceField.Create(Position, Size : RVector3; Base : RMatrix; Strength : single);
begin
  self.Position := Position;
  self.Base := Base;
  self.Size := Size;
  self.Strength := Strength;
end;

function TCuboidForceField.getForceAtPosition(Position : RVector3) : RVector3;
var
  Transformed : RVector3;
begin
  Result := RVector3.ZERO;
  Transformed := Base * (Position - self.Position);
  if ((Transformed.X > Size.X / 2) or (Transformed.X < -Size.X / 2) or (Transformed.Y > Size.Y) or (Transformed.Y < 0) or (Transformed.Z > Size.Z / 2) or (Transformed.Z < -Size.Z / 2)) then exit;
  Result := -Base.Column[1] * Strength * (Transformed.Y / Size.Y);
end;

{ TBlackHoleForceField }

constructor TBlackHoleForceField.Create(Position : RVector3; Radius,
  Strength : single);
begin
  self.Position := Position;
  self.Radius := Radius;
  self.Strength := Strength;
end;

function TBlackHoleForceField.getForceAtPosition(Position : RVector3) : RVector3;
var
  dist : single;
begin
  Result := RVector3.ZERO;
  dist := Position.Distance(self.Position);
  if dist > Radius then exit;
  Result := (self.Position - Position).Normalize * (1 - sqr(dist / Radius)) * Strength;
end;

{ TVortexForceField }

constructor TVortexForceField.Create(Position, Axis : RVector3; Radius,
  Strength : single);
begin
  self.Position := Position;
  self.Axis := Axis.Normalize;
  self.Radius := Radius;
  self.Strength := Strength;
end;

function TVortexForceField.getForceAtPosition(Position : RVector3) : RVector3;
var
  dist : single;
begin
  Result := RVector3.ZERO;
  dist := Position.Distance(self.Position);
  if dist > Radius then exit;
  Result := (self.Position - Position).Normalize.Cross(Axis) * (dist / Radius) * Strength;
end;

{ TWhiteHoleForceField }

constructor TWhiteHoleForceField.Create(Position : RVector3; Radius, Strength : single);
begin
  inherited;
  self.Strength := -self.Strength;
end;

{ TConeForceField }

constructor TConeForceField.Create(Position, Direction : RVector3; Radius,
  Strength : single);
begin
  self.Position := Position;
  self.Direction := Direction;
  self.Radius := Radius;
  self.Strength := Strength;
end;

function TConeForceField.getForceAtPosition(Position : RVector3) : RVector3;
var
  temp : RVector3;
begin
  Result := RVector3.ZERO;
  temp := Position - self.Position;
  if (temp.Length > Radius) then exit;
  Result := Direction.RotateAxis(self.Direction.Normalize.Cross(temp.Normalize), ArcTan(Direction.Length / Radius)).Normalize * Strength;
end;

{ TPlaneObstacle }

constructor TPlaneObstacle.Create(Obstacle: RPlane);
begin
  Self.Plane := Obstacle;
end;

procedure TPlaneObstacle.Apply(var Position, MovementVector: RVector3);
begin
  if Plane.DistanceSigned(Position) < 0 then
  begin
    Position := Plane.ProjectPointToPlane(Position);
    if MovementVector.Normalize.Dot(Plane.Normal) <= 0 then
      MovementVector := Plane.Reflect(MovementVector)
  end;
end;

end.
