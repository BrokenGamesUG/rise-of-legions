unit Engine.Math.CollisionHelper;

interface

uses
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D;

type

  RLine2DHelper = record helper for RLine2D
    public
      function To3D : RLine;
  end;

implementation

{ RLine2DHelper }

function RLine2DHelper.To3D: RLine;
begin
  Result.Origin := Self.Origin.X0Y;
  Result.Endpoint := Self.Endpoint.X0Y;
end;

end.
