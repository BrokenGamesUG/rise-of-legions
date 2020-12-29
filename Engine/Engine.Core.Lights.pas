unit Engine.Core.Lights;

interface

uses
  Engine.Math,
  Engine.Helferlein;

type

  /// <summary> A light. Metaclass for all lighttypes. </summary>
  TLight = class
    public
      // XYZW = RGBA, Alpha - Intensity (0 - no light), negative values allowed for negative lights
      Color : RColor;
      Enabled : boolean;
      function IsNegative : boolean;
      function IsVisible : boolean;
      constructor Create(Color : RColor); overload;
      constructor Create(Color : RVector4); overload;
  end;

  /// <summary>A directional light.</summary>
  TDirectionalLight = class(TLight)
    protected
      FDirection : RVector3;
      procedure setDirection(Value : RVector3);
    public
      constructor Create(Color : RColor; Direction : RVector3); overload;
      constructor Create(Color : RVector4; Direction : RVector3); overload;
      property Direction : RVector3 read FDirection write setDirection;
  end;

  /// <summary> A point light (lightsphere). </summary>
  TPointlight = class(TLight)
    public
      Position : RVector3;
      /// <summary> x - range, y - pow-shaping (0=linear), z - overdrive (multiplication-factor, Intensity*(1+factor)) </summary>
      Range : RVector3;
      /// <summary> Creates a pointlight. </summary>
      /// <param name="Range">lightrange in worldspace</param>
      constructor Create(Color : RColor; Position : RVector3; Range : RVector3);
  end;

  /// <summary> A spot light (lightcone). </summary>
  TSpotlight = class(TLight)
    public
      Position, Direction : RVector3;
      Range, Phi, Theta : Single;
      /// <summary> Creates a spotlight. </summary>
      /// <param name="Color">A - Intensity, RGB - Lightcolor</param>
      /// <param name="Position">Lightsourceposition</param>
      /// <param name="Direction">Spotdirection</param>
      /// <param name="Range">Lightrange in Spotdirection</param>
      /// <param name="Theta">Bright inner cone angle</param>
      /// <param name="Phi">Falloff outer cone angle</param>
      constructor Create(Color : RColor; Position, Direction : RVector3; Range, Theta, Phi : Single);
  end;

implementation


{ TLight }

constructor TLight.Create(Color : RColor);
begin
  Create(Color.RGBA);
end;

constructor TLight.Create(Color : RVector4);
begin
  self.Color := Color;
  Enabled := true;
end;

function TLight.IsNegative : boolean;
begin
  Result := Color.A < 0;
end;

function TLight.IsVisible : boolean;
begin
  Result := Color.A <> 0;
end;

{ TDirectionalLight }

constructor TDirectionalLight.Create(Color : RColor; Direction : RVector3);
begin
  inherited Create(Color);
  self.Direction := Direction;
end;

constructor TDirectionalLight.Create(Color : RVector4; Direction : RVector3);
begin
  inherited Create(Color);
  self.Direction := Direction;
end;

procedure TDirectionalLight.setDirection(Value : RVector3);
begin
  FDirection := Value.Normalize;
end;

{ TPointLight }

constructor TPointlight.Create(Color : RColor; Position{ , Attenuation } : RVector3; Range : RVector3);
begin
  inherited Create(Color);
  self.Position := Position;
  // self.Attenuation := Attenuation;
  self.Range := Range;
end;

{ TSpotlight }

constructor TSpotlight.Create(Color : RColor; Position, Direction : RVector3; Range, Theta, Phi : Single);
begin
  inherited Create(Color);
  self.Position := Position;
  self.Direction := Direction;
  self.Range := Range;
  self.Theta := Theta;
  self.Phi := Phi;
end;

end.
