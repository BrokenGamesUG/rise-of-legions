unit Engine.Vertex;

interface

uses
  // System
  Windows,
  Math,
  SysUtils,
  Classes,
  Generics.Collections,
  Generics.Defaults,
  RTTI,
  // Engine
  Engine.Core,
  Engine.Core.Types,
  Engine.GfxApi.Types,
  Engine.GfxApi,
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D;

type

  EnumBlendMode = (BlendLinear, BlendAdditive, BlendSubtractive, BlendReverseSubtractive);
  EnumDrawGMode = (dgColor, dgNormal, dgPosition, dgMaterial);
  SetDrawGMode = set of EnumDrawGMode;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  RVertexTexture = record
    TextureName, SecondaryTextureName : string;
    VertexDeclaration : TVertexdeclaration;
    HasGeometry, IsScreenSpace : boolean;
    BlendMode : EnumBlendMode;
    TextureFilter : EnumTextureFilter;
    TextureAddressMode : EnumTexturAddressMode;
    TextureMipMapLodBias : single;
    DrawOnGBuffer : SetDrawGMode;
    DrawOrder : integer;
    DrawsAtStage : EnumRenderStage;
    DerivedShader : string;
    ColorOverride : RColor;
    constructor Create(TextureName, SecondaryTextureName : string; VertexDeclaration : TVertexdeclaration; DrawOrder : integer; BlendMode : EnumBlendMode; TextureFilter : EnumTextureFilter; TextureAddressMode : EnumTexturAddressMode; TextureMipMapLodBias : single; DrawOnGMode : SetDrawGMode; HasGeometry, IsScreenSpace : boolean; DrawsAtStage : EnumRenderStage; DerivedShader : string; ColorOverride : RColor);
    function Hash : integer;
    class operator equal(a, b : RVertexTexture) : boolean;
  end;

  /// ///////////////////////////////////////////////////////////////////////////
  /// RVertexPositionColor
  /// ///////////////////////////////////////////////////////////////////////////

  PVertexPositionColor = ^RVertexPositionColor;

  RVertexPositionColor = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      Color : RVector4;
      constructor Create(Position : RVector3; Color : RColor);
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionColor = array of RVertexPositionColor;

  /// ///////////////////////////////////////////////////////////////////////////
  /// RVertexPositionTexture
  /// ///////////////////////////////////////////////////////////////////////////

  PVertexPositionTexture = ^RVertexPositionTexture;

  RVertexPositionTexture = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      TextureCoordinate : RVector2;
      constructor Create(Position : RVector3; TextureCoordinate : RVector2);
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionTexture = array of RVertexPositionTexture;

  /// ///////////////////////////////////////////////////////////////////////////
  /// RVertexPositionColorTexture
  /// ///////////////////////////////////////////////////////////////////////////

  PVertexPositionColorTexture = ^RVertexPositionColorTexture;

  RVertexPositionColorTexture = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      Color : RVector4;
      TextureCoordinate : RVector2;
      constructor Create(Position : RVector3; TextureCoordinate : RVector2; Color : RColor);
      function Lerp(b : RVertexPositionColorTexture; s : single) : RVertexPositionColorTexture;
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionColorTexture = array of RVertexPositionColorTexture;

  /// ///////////////////////////////////////////////////////////////////////////
  /// RVertexPositionColorTextureTexture
  /// ///////////////////////////////////////////////////////////////////////////

  PVertexPositionColorTextureTexture = ^RVertexPositionColorTextureTexture;

  RVertexPositionColorTextureTexture = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      Color : RVector4;
      TextureCoordinate, TextureCoordinate2 : RVector2;
      constructor Create(Position : RVector3; TextureCoordinate, TextureCoordinate2 : RVector2; Color : RColor);
      function Lerp(b : RVertexPositionColorTextureTexture; s : single) : RVertexPositionColorTextureTexture;
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionColorTextureTexture = array of RVertexPositionColorTextureTexture;

  /// //////////////////////////////////////////////////////////////////////////
  /// RVertexPositionNormalColorTexture
  /// //////////////////////////////////////////////////////////////////////////

  PVertexPositionNormalColorTexture = ^RVertexPositionNormalColorTexture;

  RVertexPositionNormalColorTexture = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position, Normal : RVector3;
      Color : RVector4;
      TextureCoordinate : RVector2;
      constructor Create(Position, Normal : RVector3; TextureCoordinate : RVector2; Color : RColor);
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionNormalColorTexture = array of RVertexPositionNormalColorTexture;

  /// //////////////////////////////////////////////////////////////////////////
  /// RVertexPositionNormalColorTextureData
  /// //////////////////////////////////////////////////////////////////////////

  PVertexPositionNormalColorTextureData = ^RVertexPositionNormalColorTextureData;

  RVertexPositionNormalColorTextureData = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position, Normal : RVector3;
      Color : RVector4;
      TextureCoordinate : RVector2;
      Data : RVector3;
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionNormalColorTextureData = array of RVertexPositionNormalColorTextureData;

  /// //////////////////////////////////////////////////////////////////////////
  /// RVertexPositionNormalTextureTangentBinormal
  /// //////////////////////////////////////////////////////////////////////////

  PVertexPositionTextureNormalTangentBinormal = ^RVertexPositionTextureNormalTangentBinormal;

  RVertexPositionTextureNormalTangentBinormal = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      TextureCoordinate : RVector2;
      Normal, Tangent, Binormal : RVector3;
      constructor Create(Position, Normal : RVector3; TextureCoordinate : RVector2; Tangent, Binormal : RVector3);
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  ARVertexPositionNormalTextureTangentBinormal = array of RVertexPositionTextureNormalTangentBinormal;

  /// //////////////////////////////////////////////////////////////////////////
  /// RVertexPositionNormalColorTextureTangentBinormal
  /// //////////////////////////////////////////////////////////////////////////

  PVertexPositionNormalColorTextureTangentBinormal = ^RVertexPositionNormalColorTextureTangentBinormal;

  RVertexPositionNormalColorTextureTangentBinormal = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      Color : RVector4;
      TextureCoordinate : RVector2;
      Normal, Tangent, Binormal : RVector3;
      constructor Create(Position, Normal : RVector3; Color : RColor; TextureCoordinate : RVector2; Tangent, Binormal : RVector3);
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionNormalColorTextureTangentBinormal = array of RVertexPositionNormalColorTextureTangentBinormal;

  /// //////////////////////////////////////////////////////////////////////////
  /// RVertexPositionNormalTextureTangentBinormalBoneIndicesWeight
  /// //////////////////////////////////////////////////////////////////////////

  PVertexPositionNormalTextureTangentBinormalBoneIndicesWeight = ^RVertexPositionNormalTextureTangentBinormalBoneIndicesWeight;

  RVertexPositionNormalTextureTangentBinormalBoneIndicesWeight = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position, Normal : RVector3;
      TextureCoordinate : RVector2;
      Tangent, Binormal : RVector3;
      BoneWeights : array [0 .. 3] of single;
      BoneIndices : array [0 .. 3] of single;
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionNormalTextureTangentBinormalBoneIndicesWeight = array of RVertexPositionNormalTextureTangentBinormalBoneIndicesWeight;

  /// //////////////////////////////////////////////////////////////////////////
  /// RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight
  /// //////////////////////////////////////////////////////////////////////////

  PVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight = ^RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight;

  RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      TextureCoordinate : RVector2;
      Normal, Tangent, Binormal : RVector3;
      BoneWeights : array [0 .. 3] of single;
      BoneIndices : array [0 .. 3] of single;
      SmoothedNormal : RVector3;
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
      class destructor Destroy;
  end;

  AVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight = array of RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight;

  /// //////////////////////////////////////////////////////////////////////////
  /// RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight
  ///
  /// ATTENTION: DON'T USE SIZEOF WITH THIS STRUCT
  /// //////////////////////////////////////////////////////////////////////////

type

  PVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight = ^RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight;

  RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight = packed record
    strict private
      class var FDeclaration : array of TVertexdeclaration;
    public
      Position : array [0 .. MAX_MORPH_TARGET_COUNT - 1] of RVector3;
      TextureCoordinate : RVector2;
      Normal, Tangent, Binormal : RVector3;
      BoneWeights, BoneIndices : RVector4;
      SmoothedNormal : RVector3;
      class function BuildVertexdeclaration(MorphtargetCount : integer) : TVertexdeclaration; static;
      class function GetSize(MorphtargetCount : integer) : integer; static;
      class destructor Destroy;
  end;

  AVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight = array of RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight;

  AVMPNSNTTBBIWHelper = record helper for AVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight
    public
      procedure CopyTo(Target : Pointer; MorphtargetCount : integer; checkSize : integer = -1);
  end;

  /// //////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// END OF VERTEXDECLARATIONS
  /// //////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
const
  YOFFSET_2D_LINES = 0.1;

type

  TLinePool = class(TRenderable)
    protected
      FVertexbuffer : TVertexBufferList;
      FLinebuffer : TArray<RVertexPositionColor>;
      FCurrentLineCount, FMaxLineCount : integer;
      procedure Render(EventIdentifier : EnumRenderStage; RenderContext : TRenderContext); override;
    public
      constructor Create(Scene : TRenderManager = nil; MaxLineCount : integer = 10000);
      /// <summary> Draws a coordinate System with a line for each axis. Colors are XYZ=RGB </summary>
      procedure AddCoordinateSystem(Position : RVector3; Size : single); overload;
      procedure AddCoordinateSystem(BaseMatrix : RMatrix; Size : single = 1); overload;
      /// <summary> Draw a colored rectangular grid with edge length Size. Position is in the middle of the grid. </summary>
      procedure AddGrid(Position, Front, Left : RVector3; Size : RVector2; Color : RColor; GridLines : RIntVector2); overload;
      procedure AddGrid(Position, Front, Left : RVector3; Size : RVector2; Color : RColor; GridLines : integer); overload;
      /// <summary> Draw a colored rect. </summary>
      procedure AddRect(LeftTop, RightTop, RightBottom, LeftBottom : RVector3; Color : RColor); overload;
      procedure AddRect(Rectangle : RRectFloat; Color : RColor); overload;
      procedure AddRect(Rectangle : ROrientedRect; Color : RColor); overload;
      /// <summary> Draw a colored box grid with edge length Size. Position is in the middle of the box. </summary>
      procedure AddBox(Position, Front, Left, Size : RVector3; Color : RColor; GridLines : integer); overload;
      procedure AddBox(OBB : ROBB; Color : RColor; GridLines : integer); overload;
      procedure AddBox(AABB : RAABB; Color : RColor; GridLines : integer); overload;
      /// <summary> Draw a colored sphere. </summary>
      procedure AddSphere(Sphere : RSphere; Color : RColor; Samples : integer = 16); overload;
      procedure AddSphere(Position : RVector2; Radius : single; Color : RColor; Samples : integer = 16; Offset : single = YOFFSET_2D_LINES); overload;
      procedure AddSphere(Position : RVector3; Radius : single; Color : RColor; Samples : integer = 16); overload;
      /// <summary> Draw a colored circle. </summary>
      procedure AddCircle(Position, Normal : RVector3; Radius : single; Color : RColor; Samples : integer = 16); overload;
      procedure AddCircle(Circle : RCircle; Normal : RVector3; Color : RColor; Samples : integer = 16); overload;
      procedure AddCircle(Position, Normal : RVector3; Radius, Radius2 : single; Color : RColor; Samples : integer = 16; Rings : integer = 10); overload;
      /// <summary> Draws a colored hermite-spline. </summary>
      procedure AddHermite(Hermitespline : RHermiteSpline; Color : RColor; Samples : integer; DrawTangents : boolean = true);
      /// <summary> Draws a colored line from start to end. </summary>
      procedure AddLine(Startposition, Endposition : RVector3; Color : RColor); overload;
      procedure AddLine(Startposition, Endposition : RVector2; Color : RColor; Offset : single = YOFFSET_2D_LINES); overload;
      procedure AddLine(Line : RLine2D; Color : RColor; Offset : single = YOFFSET_2D_LINES); overload;
      procedure AddLine(Line : RLine; Color : RColor); overload;
      procedure AddLine(Startposition, Endposition : RVector3; Color : RColor; Offset : RVector3); overload;
      /// <summary> Draws a colorfaded line from start to end.</summary>
      procedure AddLine(Startposition, Endposition : RVector3; StartColor, EndColor : RColor); overload;
      procedure AddPlane(Plane : RPlane; Color : RColor; Size : single = 100; Samples : integer = 10);
      procedure AddRay(Ray : RRay; Color : RColor);
      procedure AddCone(Startposition, Endposition : RVector3; Radius : single; Color : RColor; Samples : integer = 16);
      procedure AddCylinder(Cylinder : RCylinder; Color : RColor; Samples : integer = 16);
      procedure AddCapsule(Capsule : RCapsule; Color : RColor; Samples : integer = 16);
      procedure AddFrustum(Frustum : RFrustum; Color : RColor);
      /// <summary> Draws a colored arrow. </summary>
      procedure AddArrow(Position, Direction : RVector3; Radius, Length : single; Color : RColor; Samples : integer = 16); overload;
      procedure AddPolygon(Polygon : TPolygon; Color : RColor; Offset : RVector3);
      procedure AddMultiPolygon(Polygon : TMultipolygon; Color, NegativeColor : RColor; Offset : RVector3);
      destructor Destroy; override;
  end;

  TRHWLinePool = class(TRenderable)
    protected
      FRHWVertexbuffer : TVertexBufferList;
      FLinebuffer : TArray<RVertexPositionColor>;
      FCurrentLineCount, FMaxLineCount : integer;
      procedure Render(EventIdentifier : EnumRenderStage; RenderContext : TRenderContext); override;
      function DrawRawDashedLine(StartPos, EndPos : RIntVector2; Dashlength : single; Color : RColor) : single;
      function DrawDashedLine(StartPos, EndPos : RIntVector2; Dashlength : single; Color : RColor; DashOffset : single) : single;
    public
      constructor Create(Scene : TRenderManager = nil; MaxLineCount : integer = 10000);
      /// <summary> Draw a colored rect. </summary>
      procedure AddRect(Rect : RRect; Color : RColor); overload;
      procedure AddRect(LeftTop, RightBottom : RIntVector2; Color : RColor); overload;
      procedure AddCircle(Center : RIntVector2; Radius : integer; Color : RColor; Samples : integer = 32);
      procedure AddDashedRect(Rect : RRect; Color : RColor; Dashlength : integer); overload;
      procedure AddDashedRect(LeftTop, RightBottom : RIntVector2; Color : RColor; Dashlength : integer); overload;
      procedure AddDashedCircle(Center : RIntVector2; Radius, Dashlength : integer; Color : RColor; Samples : integer = 32);
      /// <summary> Draws a colored line from start to end. </summary>
      procedure AddLine(Startposition, Endposition : RIntVector2; Color : RColor); overload;
      /// <summary> Draws a colorfaded line from start to end.</summary>
      procedure AddLine(Startposition, Endposition : RIntVector2; StartColor, EndColor : RColor); overload;
      destructor Destroy; override;
  end;

  TVertexEngine = class;

  TVertexObject = class
    protected
      FOwner : TVertexEngine;
      /// <summary> Used by vertexobjects like fonts, which have no managed geometry. </summary>
      function HasGeometry : boolean; virtual;
      function GetDrawOnGBuffer : SetDrawGMode; virtual;
      function GetDrawOrder : integer; virtual;
      function GetTexture : TTexture; virtual; abstract;
      function GetSecondaryTexture : TTexture; virtual;
      function GetNormalTexture : TTexture; virtual;
      function GetVertexFormat : TVertexdeclaration; virtual; abstract;
      function GetVertexCount : integer; virtual; abstract;
      function GetBlendMode : EnumBlendMode; virtual;
      function GetTextureFilter : EnumTextureFilter; virtual;
      function GetTextureAddressMode : EnumTexturAddressMode; virtual;
      function GetMipMapLodBias : single; virtual;
      function IsScreenSpace : boolean; virtual;
      function GetDrawsAtStage : EnumRenderStage; virtual;
      function GetDerivedShader : string; virtual;
      /// <summary> Saves the vertices to the targetmemory. Result = count of written vertices </summary>
      function ComputeAndSave(var Target : Pointer) : integer; virtual; abstract;
    public
      /// <summary> Determines wheter the VertexObject is rendered or not </summary>
      Visible : boolean;
      DrawOrder : integer;
      BlendMode : EnumBlendMode;
      FilterMode : EnumTextureFilter;
      AddressMode : EnumTexturAddressMode;
      MipMapLodBias : single;
      DrawOnGBuffer : SetDrawGMode;
      DrawsAtStage : EnumRenderStage;
      DerivedShader : string;
      OnPreRender : ProcGFXDDrawEvent;
      ColorOverride : RColor;
      UseTransform, TransformAppliesToTexCoords : boolean;
      Transform : RMatrix4x3;
      property Owner : TVertexEngine read FOwner;
      constructor Create(Owner : TVertexEngine); virtual;
      procedure AddRenderJob;
      procedure RemoveRenderJob;
      destructor Destroy; override;
  end;

  /// <summary> A textured and/or colored screenaligned Quad. </summary>
  TVertexScreenAlignedTriangle = class(TVertexObject)
    protected
      function GetTexture : TTexture; override;
      function GetVertexCount : integer; override;
      function GetVertexFormat : TVertexdeclaration; override;
      function ComputeAndSave(var Target : Pointer) : integer; override;
      function IsScreenSpace : boolean; override;
    public
      Texture : TTexture;
      Color : RColor;
      Position : array [0 .. 2] of RVector2;
      TextureCoordinate : array [0 .. 2] of RVector2;
      constructor Create(Owner : TVertexEngine); override;
  end;

  TVertexQuad = class(TVertexObject)
    private
      function GetSize : RVector2;
      procedure SetSize(const Value : RVector2);
    protected
      function GetTexture : TTexture; override;
      function GetSecondaryTexture : TTexture; override;
      function GetVertexCount : integer; override;
    public
      Texture, SecondaryTexture : TTexture;
      OwnsTexture : boolean;
      Width, Height : single;
      Color : RColor; // Topleft if used with gradient
      TopRightColor, BottomRightColor, BottomLeftColor : RColor;
      UseGradientColors : boolean;
      CoordinateRect, SecondaryCoordinateRect : RRectFloat;
      property Size : RVector2 read GetSize write SetSize;
      function IsFullTransparent : boolean;
      destructor Destroy; override;
  end;

  PVertexWorldspaceQuad = ^TVertexWorldspaceQuad;

  /// <summary> A textured and/or colored Quad. </summary>
  TVertexWorldspaceQuad = class(TVertexQuad)
    protected
      procedure PushVertex(var Target : Pointer; Position : RVector3; Color : RColor; TexCoord : RVector2);
      function GetVertexFormat : TVertexdeclaration; override;
      function GetNormalTexture : TTexture; override;
      function ComputeAndSave(var Target : Pointer) : integer; override;
    public
      Position, Up, Left : RVector3;
      /// <summary> Specifies the trapezial factor for X-Left direction and Y-Up direction. E.g for y ;<1 front smaller;=1 front and
      /// back equal; >1 front broader
      /// Use with care and only small changes, because of triangulation the texture becomes unstable.</summary>
      Trapezial : RVector2;
      NormalTexture : TTexture;
      constructor Create(Owner : TVertexEngine); overload; override;
      /// <summary> Creates the Quad. (Up,Left)-Corner is the (0,0) Texel of the Texture. </summary>
      constructor Create(Owner : TVertexEngine; Position, Up, Left : RVector3; Width, Height : single; Texture : TTexture; DrawOrder : integer = 0); reintroduce; overload;
  end;

  /// <summary> A textured and/or colored circle. </summary>
  TVertexWorldspaceCircle = class(TVertexWorldspaceQuad)
    private
      procedure SetSliceFrom(const Value : single);
      procedure SetSliceTo(const Value : single);
    protected
      FSliceFrom, FSliceTo : single;
      function ComputeAndSave(var Target : Pointer) : integer; override;
      function GetVertexCount : integer; override;
    public
      Radius, Thickness : single;
      Samples : integer;
      /// <summary> Must be in [0,1] </summary>
      property SliceFrom : single read FSliceFrom write SetSliceFrom;
      /// <summary> Must be in [0,1] and will be assured to be >= SliceFrom. </summary>
      property SliceTo : single read FSliceTo write SetSliceTo;
      constructor Create(Owner : TVertexEngine); overload; override;
  end;

  /// <summary> A textured and/or colored screenaligned Quad. </summary>
  TVertexScreenAlignedQuad = class(TVertexQuad)
    strict private
    const
      RADIAL_STOPS : array [0 .. 5] of single = (0, 1 / 8, 3 / 8, 5 / 8, 7 / 8, 1);
    var
      FRadialClip : single;
      FUseScissor : boolean;
      FScissorRect : RRectFloat;
      procedure SetRadialClip(const Value : single);
      function IsRadialClipped : boolean;
      function GetRadialClippedVertexCount : integer;
      procedure SetLocationRect(const Value : RRectFloat);
      procedure setBorderColor(const Value : RColor);
    protected
      function GetVertexFormat : TVertexdeclaration; override;
      function ComputeAndSave(var Target : Pointer) : integer; override;
      function IsScreenSpace : boolean; override;
      function GetVertexCount : integer; override;
      function GetQuad : RRectFloat;
      /// <summary> Rect with border. </summary>
      function GetFinalRect : RRectFloat;
    public
      /// <summary> Determines the anchor point on which the quad is
      /// positioned. By default this is (0, 0), i.e. the quad is aligned
      /// in the top left corner, extending to its right and bottom.
      /// To center a quad set the anchor to (0.5, 0.5), to use the bottom
      /// right corner set the anchor to (1, 1). </summary>
      Anchor : RVector2;
      Position : RVector2;
      // inflates the quad with the center as origin, keeping aspect ratio
      Zoom : single;
      // Border
      BorderSizeInner, BorderSizeOuter : single;
      BorderColorOuterStart, BorderColorOuterEnd : RColor;
      DrawBorder, DrawOutline : SetRectSide;
      // Outline
      OutlineSizeInner, OutlineSizeOuter : single;
      OutlineColorOuterStart, OutlineColorOuterEnd : RColor;
      property BorderColor : RColor write setBorderColor;
      property Rect : RRectFloat read GetQuad write SetLocationRect;
      /// <summary> Clips this rectangle in a radial manner, just like in WoW the spell cooldowns. [0,1] 0- fully visible, 1- fully transparent. </summary>
      property RadialClip : single read FRadialClip write SetRadialClip;
      /// <summary> Enables the scissor text, clipping the font to the ScissorRect. </summary>
      property ScissorEnabled : boolean read FUseScissor write FUseScissor;
      /// <summary> Sets a rect where the drawn text will be visible. (pixel clipping) </summary>
      property ScissorRect : RRectFloat read FScissorRect write FScissorRect;
      function HasBorder : boolean;
      function HasOutline : boolean;
      constructor Create(Owner : TVertexEngine); overload; override;
      /// <summary> Creates the ScreenAlignedQuad. (Up,Left)-Corner is the (0,0) Texel of the Texture. </summary>
      constructor Create(Owner : TVertexEngine; Position : RVector2; Width, Height : single; Texture : TTexture; DrawOrder : integer = 0); reintroduce; overload;
      constructor Create(Owner : TVertexEngine; Position, Size : RVector2; Texture : TTexture; DrawOrder : integer = 0); reintroduce; overload;
  end;

  /// <summary> A wrapper around a TFont to render fonts. </summary>
  TVertexFont = class(TVertexObject)
    private
      procedure setFontDescription(const Value : RFontDescription);
      procedure setText(const Value : string);
      procedure SetRect(const Value : RRect);
      procedure SetFormat(const Value : SetFontRenderingFlags);
      procedure SetFontBorder(const Value : RFontBorder);
      procedure setColor(const Value : RColor);
      procedure SetFontResolution(const Value : single);
    protected
      FFont : TFont;
      FFontDescription : RFontDescription;
      FDrawnTexture : TTexture;
      FText : string;
      FDirty : boolean;
      FRect : RRect;
      FUseScissor : boolean;
      FScissorRect : RRectFloat;
      FFormat : SetFontRenderingFlags;
      FFontBorder : RFontBorder;
      FColor : RColor;
      FFontResolution : single;
      procedure CopyValuesToFont; virtual;
      procedure CleanDirty;
      function IsClearType : boolean;
      function HasText : boolean;
      function HasGeometry : boolean; override;
      function GetTexture : TTexture; override;
      function GetVertexFormat : TVertexdeclaration; override;
      function GetVertexCount : integer; override;
      function IsScreenSpace : boolean; override;
      function ComputeAndSave(var Target : Pointer) : integer; override;
    public
      // inflates the quad with the center as origin, keeping aspect ratio
      Zoom : single;
      property Color : RColor read FColor write setColor;
      /// <summary> Sets the rect where the text will be drawn. (used for word-wrap) </summary>
      property Rect : RRect read FRect write SetRect;
      /// <summary> Enables the scissor text, clipping the font to the ScissorRect. </summary>
      property ScissorEnabled : boolean read FUseScissor write FUseScissor;
      /// <summary> Sets a rect where the drawn text will be visible. (pixel clipping) </summary>
      property ScissorRect : RRectFloat read FScissorRect write FScissorRect;
      property Format : SetFontRenderingFlags read FFormat write SetFormat;
      property Text : string read FText write setText;
      property FontDescription : RFontDescription read FFontDescription write setFontDescription;
      property FontBorder : RFontBorder read FFontBorder write SetFontBorder;
      /// <summary> Factor to the font resolution, rendering the font on a texture with higher resolution. </summary>
      property Resolution : single read FFontResolution write SetFontResolution;
      /// <summary> Returns the text width in pixels. Ignores newlines. </summary>
      function TextWidth() : integer;
      /// <summary> Returns the height of the printed textblock. Only works as intended with ffWordBreak in Flags. </summary>
      function TextBlockHeight() : integer;
      /// <summary> Returns the character index at the given position relative to top left in pixels. </summary>
      function PositionToIndex(const Position : RVector2) : integer;
      /// <summary> Returns the position relative to top left in pixels of the characters with the given index. </summary>
      function IndexToPosition(const CharacterIndex : integer) : RRectFloat;
      constructor Create(Owner : TVertexEngine; FontDescription : RFontDescription); reintroduce;
      destructor Destroy; override;
  end;

  TVertexFontWorld = class(TVertexFont)
    strict private
      FWorldToPixelFactor : single;
      FSize : RVector2;
      procedure SetSize(const Value : RVector2);
      procedure SetWorldToPixelFactor(const Value : single);
    protected
      procedure CopyValuesToFont; override;
      function GetVertexFormat : TVertexdeclaration; override;
      function GetVertexCount : integer; override;
      function IsScreenSpace : boolean; override;
      function ComputeAndSave(var Target : Pointer) : integer; override;
    public
      Position, Up, Left : RVector3;
      constructor Create(Owner : TVertexEngine; FontDescription : RFontDescription);
      property WorldToPixelFactor : single read FWorldToPixelFactor write SetWorldToPixelFactor;
      property Size : RVector2 read FSize write SetSize;
      property Width : single read FSize.X;
      property Height : single read FSize.Y;
  end;

  /// <summary> A textured and/or colored thick Line. </summary>
  TVertexLine = class(TVertexObject)
    protected
      function GetTexture : TTexture; override;
      function GetVertexFormat : TVertexdeclaration; override;
      function GetVertexCount : integer; override;
      function ComputeAndSave(var Target : Pointer) : integer; override;
    public
      Texture : TTexture;
      Start, Target, Normal : RVector3;
      Width : single;
      Color : RColor;
      CoordinateRect : RRectFloat;
      constructor Create(Owner : TVertexEngine); overload; override;
      /// <summary> Creates the Line. Target is the (0.5,0) Texel of the Texture. </summary>
      constructor Create(Owner : TVertexEngine; Start, Target, Normal : RVector3; Width : single; Texture : TTexture); reintroduce; overload;
  end;

  /// <summary> A textured polyline. Creates a trianglestrip along the path the position goes. </summary>
  TVertexTrace = class(TVertexObject)
    protected
      type
      RTrackPoint = record
        Position : RVector3;
        TextureOffset : single;
        constructor Create(Position : RVector3; TextureOffset : single);
      end;
    var
      FTrack : TList<RTrackPoint>;
      Tracking : boolean;
      FCurrentTextureOffset : single;
      FPosition, FLast, FBase : RVector3;
      function GetTexture : TTexture; override;
      function GetVertexFormat : TVertexdeclaration; override;
      function GetVertexCount : integer; override;
      function ComputeAndSave(var Target : Pointer) : integer; override;
      procedure SetPosition(const Value : RVector3);
    public
      Texture : TTexture;
      OwnsTexture : boolean;
      Up : RVector3;
      Trackwidth, TrackSetDistance, TexturePerDistance, FadeLength, MaxLength, FadeWidening : single;
      Color : RColor;
      /// <summary> Sets the pencils position. Changes while tracking spawns points. </summary>
      property Position : RVector3 read FPosition write SetPosition;
      /// <summary> Sets an offset for the position which is removed from it. Useful if trace should be in object and not in world space. </summary>
      property BasePosition : RVector3 write FBase;
      /// <summary> Creates a vertex trace. TrackSetDistance detemines how often Node are set. The track fades out so that the track is shorter then MaxLength, the piece Maxlength-Fadelength to Maxlength fades out. </summary>
      constructor Create(Owner : TVertexEngine); overload; override;
      constructor Create(Owner : TVertexEngine; Texture : TTexture; Up : RVector3; Trackwidth, TrackSetDistance, FadeLength, MaxLength, TexturePerDistance : single; DrawOrder : integer = 0); reintroduce; overload;
      /// <summary> Return whether this trace has any segments. </summary>
      function IsEmpty : boolean;
      /// <summary> Shortens the trace by given distance. Useful to add an external timed life. </summary>
      procedure RollUp(Distance : single);
      /// <summary> Starts the Positiontracking, so changes of Position spawn new Points. </summary>
      procedure StartTracking;
      /// <summary> Breaks the Track and stop pointspawning. </summary>
      procedure StopTracking;
      destructor Destroy; override;
  end;

  TVertexEngine = class(TRenderable)
    private
      const
      MAXVERTEXBUFFERSIZE = 10000;
    var
      // for rendering
      ToBeRendered : TObjectDictionary<RVertexTexture, TList<TVertexObject>>;
      KeyArray : TArray<RVertexTexture>;
      RenderCounter : TDictionary<RVertexTexture, integer>;
      VertexTextureComparer : IComparer<RVertexTexture>;
      procedure OnBeginScene();
      procedure OnFrameEnd();
    protected
      // all vertexbuffers for the differenz FVFs
      FVertexbuffer : TObjectDictionary<TVertexdeclaration, TVertexBufferList>;
      // all Vertexobjects handled by the Vertexengine
      FVertexobjects : TList<TVertexObject>;
      FVertexobjectsExistenceCheck : TDictionary<TVertexObject, boolean>;
      procedure Render(CurrentStage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure RawRender(const ToRender : RVertexTexture; const RenderContext : TRenderContext);
      /// <summary> Renders the vertexobject in this frame and then drop it. </summary>
      procedure AddVertexObject(VertexObject : TVertexObject);
      procedure RemoveVertexObject(VertexObject : TVertexObject);
    public
      /// <summary> Creates the Vertexengine. </summary>
      constructor Create(Scene : TRenderManager = nil);

      destructor Destroy; override;
    public
      class procedure PrecompileDefaultShaders;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  LinePool : TLinePool;
  RHWLinePool : TRHWLinePool;
  VertexEngine : TVertexEngine;

implementation

{ TLinePool }

constructor TLinePool.Create(Scene : TRenderManager; MaxLineCount : integer);
begin
  FCallbackTime := ctBefore;
  inherited Create(Scene, [rsGUI]);
  self.FMaxLineCount := MaxLineCount;
  FVertexbuffer := TVertexBufferList.Create([usFrequentlyWriteable], GFXD.Device3D);
  setlength(FLinebuffer, FMaxLineCount);
end;

destructor TLinePool.Destroy;
begin
  FVertexbuffer.Free;
  inherited;
end;

procedure TLinePool.Render(EventIdentifier : EnumRenderStage; RenderContext : TRenderContext);
var
  Shader : TShader;
  vertices : Pointer;
  vb : TVertexBuffer;
  NeededVertexbufferSize : integer;
begin
  if FCurrentLineCount > 0 then
  begin
    NeededVertexbufferSize := FCurrentLineCount * 2 * sizeof(RVertexPositionColor);
    vb := FVertexbuffer.GetVertexbuffer(NeededVertexbufferSize);
    // pass the geometry to the gpu
    vertices := vb.LowLock();
    CopyMemory(vertices, @FLinebuffer[0], NeededVertexbufferSize);
    vb.Unlock;

    Shader := RenderContext.CreateAndSetDefaultShader([sfVertexcolor]);
    Shader.SetWorld(RMatrix.IDENTITY);

    GFXD.Device3D.SetRenderState(EnumRenderstate.rsZWRITEENABLE, 1);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blInvSrcAlpha);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOP, boAdd);
    GFXD.Device3D.SetStreamSource(0, vb, 0, sizeof(RVertexPositionColor));
    GFXD.Device3D.SetVertexDeclaration(RVertexPositionColor.BuildVertexdeclaration);
    Shader.ShaderBegin;
    GFXD.Device3D.DrawPrimitive(ptLinelist, 0, FCurrentLineCount);
    Shader.ShaderEnd;
    FCurrentLineCount := 0;

  end;
end;

procedure TLinePool.AddBox(Position, Front, Left, Size : RVector3; Color : RColor; GridLines : integer);
begin
  AddGrid(Position + (Front.Cross(Left) * (Size.Y * 0.5)), Front, Left, Size.XZ, Color, GridLines);
  AddGrid(Position - (Front.Cross(Left) * (Size.Y * 0.5)), Front, Left, Size.XZ, Color, GridLines);
  AddGrid(Position + (Front * (Size.X * 0.5)), Front.Cross(Left), Left, Size.YZ, Color, GridLines);
  AddGrid(Position - (Front * (Size.X * 0.5)), Front.Cross(Left), Left, Size.YZ, Color, GridLines);
  AddGrid(Position + (Left * (Size.Z * 0.5)), Front, Front.Cross(Left), Size.XY, Color, GridLines);
  AddGrid(Position - (Left * (Size.Z * 0.5)), Front, Front.Cross(Left), Size.XY, Color, GridLines);
end;

procedure TLinePool.AddBox(OBB : ROBB; Color : RColor; GridLines : integer);
begin
  AddBox(OBB.Position, OBB.Front, OBB.Left, OBB.Size.ZYX * 2, Color, GridLines);
end;

procedure TLinePool.AddArrow(Position, Direction : RVector3; Radius, Length : single; Color : RColor; Samples : integer = 16);
const
  ARROWHEADLENGTH  = 2 / 3;
  ARROWSTICKRADIUS = 2 / 3;
var
  i : integer;
  side, sideOffset : RVector3;
begin
  side := Direction.Cross(RVector3.Create(0, 1, 0));
  if side.isZeroVector then side := Direction.Cross(RVector3.Create(1, 0, 0));
  side := side.Normalize;
  for i := 0 to Samples - 1 do
  begin
    sideOffset := side.RotateAxis(Direction, i / (Samples - 1) * PI * 2);
    AddLine(Position + (sideOffset * Radius * ARROWSTICKRADIUS), Position + (sideOffset * Radius * ARROWSTICKRADIUS) + (Direction * Length * ARROWHEADLENGTH), Color);
    AddLine(Position + (sideOffset * Radius * ARROWSTICKRADIUS) + (Direction * Length * ARROWSTICKRADIUS), Position + (sideOffset * Radius) + (Direction * Length * ARROWHEADLENGTH), Color);
    AddLine(Position + (Direction * Length), Position + (sideOffset * Radius) + (Direction * Length * ARROWHEADLENGTH), Color);
  end;
  AddCircle(Position + (Direction * Length * ARROWHEADLENGTH), Direction, Radius, Color, Samples);
  AddCircle(Position + (Direction * Length * ARROWHEADLENGTH), Direction, Radius * ARROWSTICKRADIUS, Color, Samples);
  AddCircle(Position, Direction, Radius * ARROWSTICKRADIUS, Color, Samples);
end;

procedure TLinePool.AddBox(AABB : RAABB; Color : RColor; GridLines : integer);
begin
  AddBox(AABB.Center, RVector3.UNITX, RVector3.UNITZ, AABB.HalfExtents * 2, Color, GridLines);
end;

procedure TLinePool.AddCircle(Position, Normal : RVector3; Radius : single; Color : RColor; Samples : integer);
var
  i : integer;
  side : RVector3;
begin
  side := Normal.Cross(RVector3.Create(0, 1, 0));
  if side.isZeroVector then side := Normal.Cross(RVector3.Create(1, 0, 0));
  side := side.Normalize * Radius;
  for i := 0 to Samples - 2 do
  begin
    AddLine(Position + side.RotateAxis(Normal, i / (Samples - 1) * PI * 2), Position + side.RotateAxis(Normal, 2 * PI * (i + 1) / (Samples - 1)), Color, Color);
  end;
end;

procedure TLinePool.AddCircle(Circle : RCircle; Normal : RVector3; Color : RColor; Samples : integer);
begin
  AddCircle(Circle.Center.X0Y, Normal, Circle.Radius, Color, Samples);
end;

procedure TLinePool.AddCone(Startposition, Endposition : RVector3;
  Radius : single; Color : RColor; Samples : integer);
var
  ConeDirection, side : RVector3;
  i : integer;
begin
  ConeDirection := Endposition - Startposition;
  side := RVector3.UNITY.Cross(ConeDirection).Normalize * Radius;
  if side.isZeroVector then side := RVector3.UNITX.Cross(ConeDirection).Normalize * Radius;
  for i := 0 to Samples - 1 do
  begin
    AddLine(Startposition, Endposition + side.RotateAxis(ConeDirection, 2 * PI * i / (Samples - 1)), Color);
    if i <> Samples - 1 then
        AddLine(Endposition + side.RotateAxis(ConeDirection, 2 * PI * i / (Samples - 1)), Endposition + side.RotateAxis(ConeDirection, 2 * PI * (i + 1) / (Samples - 1)), Color);
  end;
end;

procedure TLinePool.AddCoordinateSystem(BaseMatrix : RMatrix; Size : single);
begin
  AddLine(BaseMatrix.Translation, BaseMatrix.Translation + (BaseMatrix.Column[0] * Size), RColor.CRED);
  AddLine(BaseMatrix.Translation, BaseMatrix.Translation + (BaseMatrix.Column[1] * Size), RColor.CGREEN);
  AddLine(BaseMatrix.Translation, BaseMatrix.Translation + (BaseMatrix.Column[2] * Size), RColor.CBLUE);
end;

procedure TLinePool.AddCoordinateSystem(Position : RVector3; Size : single);
begin
  AddLine(Position, Position + (RVector3.UNITX * Size), RColor.CRED);
  AddLine(Position, Position + (RVector3.UNITY * Size), RColor.CGREEN);
  AddLine(Position, Position + (RVector3.UNITZ * Size), RColor.CBLUE);
end;

procedure TLinePool.AddCylinder(Cylinder : RCylinder; Color : RColor; Samples : integer);
var
  side, sidePoint, nextsidePoint : RVector3;
  i : integer;
begin
  side := Cylinder.Direction.GetArbitaryOrthogonalVector * Cylinder.Radius;
  for i := 0 to Samples - 1 do
  begin
    sidePoint := side.RotateAxis(Cylinder.Direction, 2 * PI * i / (Samples - 1));
    nextsidePoint := side.RotateAxis(Cylinder.Direction, 2 * PI * (i + 1) / (Samples - 1));
    AddLine(Cylinder.Start + sidePoint, Cylinder.Endpoint + sidePoint, Color);
    if i <> Samples - 1 then
    begin
      AddLine(Cylinder.Start + sidePoint, Cylinder.Start + nextsidePoint, Color);
      AddLine(Cylinder.Endpoint + sidePoint, Cylinder.Endpoint + nextsidePoint, Color);
    end;
  end;
end;

procedure TLinePool.AddFrustum(Frustum : RFrustum; Color : RColor);
begin
  // near
  AddLine(Frustum.Corners[0], Frustum.Corners[1], Color);
  AddLine(Frustum.Corners[1], Frustum.Corners[2], Color);
  AddLine(Frustum.Corners[2], Frustum.Corners[3], Color);
  AddLine(Frustum.Corners[3], Frustum.Corners[0], Color);
  // far
  AddLine(Frustum.Corners[0 + 4], Frustum.Corners[1 + 4], Color);
  AddLine(Frustum.Corners[1 + 4], Frustum.Corners[2 + 4], Color);
  AddLine(Frustum.Corners[2 + 4], Frustum.Corners[3 + 4], Color);
  AddLine(Frustum.Corners[3 + 4], Frustum.Corners[0 + 4], Color);
  // connection
  AddLine(Frustum.Corners[0], Frustum.Corners[0 + 4], Color);
  AddLine(Frustum.Corners[1], Frustum.Corners[1 + 4], Color);
  AddLine(Frustum.Corners[2], Frustum.Corners[2 + 4], Color);
  AddLine(Frustum.Corners[3], Frustum.Corners[3 + 4], Color);
end;

procedure TLinePool.AddGrid(Position, Front, Left : RVector3; Size : RVector2; Color : RColor; GridLines : integer);
begin
  AddGrid(Position, Front, Left, Size, Color, RIntVector2.Create(GridLines));
end;

procedure TLinePool.AddGrid(Position, Front, Left : RVector3; Size : RVector2; Color : RColor; GridLines : RIntVector2);
var
  X, Y : integer;
  dx, dy : single;
begin
  GridLines := GridLines.Max(2);
  Size := Size * 0.5;
  Front.InNormalize;
  Left.InNormalize;
  if Size.isZeroVector then exit;
  if Size.X = 0 then
  begin
    AddLine(Position - (Left * Size.Y), Position + (Left * Size.Y), Color);
    exit;
  end;
  if Size.Y = 0 then
  begin
    AddLine(Position - (Front * Size.X), Position + (Front * Size.X), Color);
    exit;
  end;
  for X := 0 to GridLines.X - 1 do
    for Y := 0 to GridLines.Y - 1 do
    begin
      dx := (X / (GridLines.X - 1) - 0.5) * 2;
      dy := (Y / (GridLines.Y - 1) - 0.5) * 2;
      AddLine(Position + (Front * Size.X * dx) + (Left * Size.Y), Position + (Front * Size.X * dx) - (Left * Size.Y), Color);
      AddLine(Position + (Front * Size.X) + (Left * Size.Y * dy), Position - (Front * Size.X) + (Left * Size.Y * dy), Color);
    end;
end;

procedure TLinePool.AddLine(Startposition, Endposition : RVector3; Color : RColor);
begin
  AddLine(Startposition, Endposition, Color, Color)
end;

procedure TLinePool.AddRay(Ray : RRay; Color : RColor);
begin
  AddLine(Ray.Origin + Ray.Direction * 10000, Ray.Origin - Ray.Direction * 10000, Color);
end;

procedure TLinePool.AddRect(Rectangle : RRectFloat; Color : RColor);
begin
  AddRect(Rectangle.LeftTop.X0Y, Rectangle.RightTop.X0Y, Rectangle.RightBottom.X0Y, Rectangle.LeftBottom.X0Y, Color);
end;

procedure TLinePool.AddRect(Rectangle : ROrientedRect; Color : RColor);
begin
  AddRect(Rectangle.TopLeft.X0Y, Rectangle.TopRight.X0Y, Rectangle.BottomRight.X0Y, Rectangle.BottomLeft.X0Y, Color);
end;

procedure TLinePool.AddSphere(Position : RVector2; Radius : single; Color : RColor; Samples : integer; Offset : single);
begin
  AddSphere(Position.X0Y.SetY(Offset), Radius, Color, Samples);
end;

procedure TLinePool.AddRect(LeftTop, RightTop, RightBottom, LeftBottom : RVector3; Color : RColor);
begin
  AddLine(LeftTop, RightTop, Color);
  AddLine(RightTop, RightBottom, Color);
  AddLine(RightBottom, LeftBottom, Color);
  AddLine(LeftBottom, LeftTop, Color);
end;

procedure TLinePool.AddSphere(Sphere : RSphere; Color : RColor; Samples : integer);
begin
  AddSphere(Sphere.Center, Sphere.Radius, Color, Samples);
end;

procedure TLinePool.AddHermite(Hermitespline : RHermiteSpline; Color : RColor; Samples : integer; DrawTangents : boolean);
var
  i : integer;
begin
  for i := 0 to Samples - 2 do AddLine(Hermitespline.getPosition(i / (Samples - 1)), Hermitespline.getPosition((i + 1) / (Samples - 1)), Color);
  if DrawTangents then
  begin
    AddLine(Hermitespline.Startposition, Hermitespline.Startposition + Hermitespline.StartTangent, Color);
    AddLine(Hermitespline.Endposition, Hermitespline.Endposition - Hermitespline.EndTangent, Color);
  end;
end;

procedure TLinePool.AddLine(Line : RLine2D; Color : RColor; Offset : single);
begin
  AddLine(Line.Origin, Line.Endpoint, Color, Offset);
end;

procedure TLinePool.AddLine(Startposition, Endposition : RVector3; StartColor, EndColor : RColor);
begin
  if FMaxLineCount <= FCurrentLineCount * 2 + 1 then exit;
  FLinebuffer[FCurrentLineCount * 2] := RVertexPositionColor.Create(Startposition, StartColor);
  FLinebuffer[FCurrentLineCount * 2 + 1] := RVertexPositionColor.Create(Endposition, EndColor);
  inc(FCurrentLineCount);
end;

procedure TLinePool.AddLine(Startposition, Endposition : RVector2; Color : RColor; Offset : single);
begin
  AddLine(Startposition.X0Y.SetY(Offset), Endposition.X0Y.SetY(Offset), Color);
end;

procedure TLinePool.AddLine(Startposition, Endposition : RVector3; Color : RColor; Offset : RVector3);
begin
  AddLine(Startposition + Offset, Endposition + Offset, Color);
end;

procedure TLinePool.AddMultiPolygon(Polygon : TMultipolygon; Color, NegativeColor : RColor; Offset : RVector3);
var
  i : integer;
begin
  for i := 0 to Polygon.Polygons.Count - 1 do
  begin
    if Polygon.Polygons[i].Subtractive then AddPolygon(Polygon.Polygons[i].Polygon, NegativeColor, Offset)
    else AddPolygon(Polygon.Polygons[i].Polygon, Color, Offset);
  end;
end;

procedure TLinePool.AddLine(Line : RLine; Color : RColor);
begin
  AddLine(Line.Origin, Line.Endpoint, Color);
end;

procedure TLinePool.AddPlane(Plane : RPlane; Color : RColor; Size : single; Samples : integer);
var
  temp : RVector3;
begin
  temp := Plane.Normal.GetArbitaryOrthogonalVector;
  AddGrid(Plane.Position, temp, temp.Cross(Plane.Normal), RVector2.Create(Size), Color, Samples);
end;

procedure TLinePool.AddPolygon(Polygon : TPolygon; Color : RColor; Offset : RVector3);
var
  i : integer;
begin
  for i := 0 to Polygon.Nodes.Count - HGeneric.TertOp<integer>(Polygon.Closed, 1, 2) do
  begin
    AddLine(Polygon.Nodes[i].X0Y, Polygon.Nodes[(i + 1) mod (Polygon.Nodes.Count)].X0Y, Color, Offset);
  end;
end;

procedure TLinePool.AddSphere(Position : RVector3; Radius : single; Color : RColor; Samples : integer);
var
  disk, disksample : integer;
  alpha, beta, nalpha, nbeta : single;
  SphereOffset, NextSphereOffset : RVector3;
begin
  for disk := 0 to Samples - 1 do
    for disksample := 0 to Samples - 2 do
    begin
      alpha := (disk / (Samples - 1) - 0.5) * PI * 2;
      nalpha := ((disk + 1) / (Samples - 1) - 0.5) * PI * 2;
      beta := (disksample / (Samples - 1)) * PI;
      nbeta := ((disksample + 1) / (Samples - 1)) * PI;
      // Latitude
      SphereOffset := RVector3.CartesianToSphere(alpha, beta, Radius);
      NextSphereOffset := RVector3.CartesianToSphere(alpha, nbeta, Radius);
      AddLine(Position + SphereOffset, Position + NextSphereOffset, Color);
      // Longitude
      if disk = Samples - 1 then continue;
      SphereOffset := RVector3.CartesianToSphere(alpha, beta, Radius);
      NextSphereOffset := RVector3.CartesianToSphere(nalpha, beta, Radius);
      AddLine(Position + SphereOffset, Position + NextSphereOffset, Color);
    end;
end;

procedure TLinePool.AddCapsule(Capsule : RCapsule; Color : RColor; Samples : integer);
begin
  AddSphere(Capsule.Origin, Capsule.Radius, Color, Samples);
  AddSphere(Capsule.Endpoint, Capsule.Radius, Color, Samples);
  AddCylinder(Capsule.ToCylinder, Color, Samples);
end;

procedure TLinePool.AddCircle(Position, Normal : RVector3; Radius, Radius2 : single; Color : RColor; Samples, Rings : integer);
var
  i : integer;
begin
  for i := 0 to Rings - 1 do AddCircle(Position, Normal, SLinLerp(Radius, Radius2, (i / (Rings - 1))), Color.SetAlphaF(1 - (i / (Rings - 1))), Samples);
end;

{ TVertexengine }

procedure TVertexEngine.AddVertexObject(VertexObject : TVertexObject);
begin
  if (VertexObject <> nil) and not FVertexobjectsExistenceCheck.ContainsKey(VertexObject) then
      FVertexobjects.add(VertexObject);
end;

procedure TVertexEngine.RemoveVertexObject(VertexObject : TVertexObject);
begin
  if (VertexObject = nil) then exit;
  FVertexobjects.Remove(VertexObject);
  FVertexobjectsExistenceCheck.Remove(VertexObject);
end;

constructor TVertexEngine.Create(Scene : TRenderManager);
var
  Comparer : IEqualityComparer<RVertexTexture>;
begin
  inherited Create(Scene, RENDER_STAGES_ALL);
  Scene.Eventbus.Subscribe(geFrameBegin, self.OnBeginScene);
  Scene.Eventbus.Subscribe(geFrameEnd, self.OnFrameEnd);
  FVertexbuffer := TObjectDictionary<TVertexdeclaration, TVertexBufferList>.Create([doOwnsValues]);
  FVertexobjects := TList<TVertexObject>.Create();
  FVertexobjectsExistenceCheck := TDictionary<TVertexObject, boolean>.Create;
  Comparer := TEqualityComparer<RVertexTexture>.Construct(
    (
    function(const Left, Right : RVertexTexture) : boolean
    begin
      Result := Left = Right;
    end),
    (
    function(const L : RVertexTexture) : integer
    begin
      Result := L.Hash;
    end));
  ToBeRendered := TObjectDictionary < RVertexTexture, TList < TVertexObject >>.Create([doOwnsValues], 0, Comparer);
  RenderCounter := TDictionary<RVertexTexture, integer>.Create(Comparer);
  VertexTextureComparer := TComparer<RVertexTexture>.Construct(
    (
    function(const Left, Right : RVertexTexture) : integer
    begin
      if (Left.DrawOnGBuffer = []) and (Right.DrawOnGBuffer <> []) then Result := 1
      else if (Left.DrawOnGBuffer <> []) and (Right.DrawOnGBuffer = []) then Result := -1
      else if Left.BlendMode <> Right.BlendMode then Result := sign(Ord(Left.BlendMode) - Ord(Right.BlendMode))
      else Result := sign(Left.DrawOrder - Right.DrawOrder);
    end));
end;

destructor TVertexEngine.Destroy;
begin
  ToBeRendered.Free;
  RenderCounter.Free;
  FVertexbuffer.Free;
  FVertexobjects.Free;
  FVertexobjectsExistenceCheck.Free;
  inherited;
end;

procedure TVertexEngine.OnBeginScene();
type
  AVertexTexture = array of RVertexTexture;
var
  vertexObjectList : TList<TVertexObject>;
  VertexObject : TVertexObject;
  TextureFilename, SecondaryTextureFilename : string;
  Texture : TTexture;
begin
  FDrawCalls := 0;
  FDrawnTriangles := 0;
  // Build Renderdictionary
  for VertexObject in FVertexobjects do
  begin
    if not VertexObject.Visible then continue;
    // get the TextureFVFList, create if not existing
    if (VertexObject.GetTexture <> nil) then
    begin
      Texture := VertexObject.GetTexture;
      TextureFilename := Texture.FileName;
      if TextureFilename = '' then TextureFilename := Texture.UniqueIdentifier;
    end
    else TextureFilename := '';
    if (VertexObject.GetSecondaryTexture <> nil) then
    begin
      Texture := VertexObject.GetSecondaryTexture;
      SecondaryTextureFilename := Texture.FileName;
      if SecondaryTextureFilename = '' then SecondaryTextureFilename := Texture.UniqueIdentifier;
    end
    else SecondaryTextureFilename := '';

    if not ToBeRendered.TryGetValue(RVertexTexture.Create(TextureFilename, SecondaryTextureFilename, VertexObject.GetVertexFormat, VertexObject.GetDrawOrder, VertexObject.GetBlendMode, VertexObject.GetTextureFilter, VertexObject.GetTextureAddressMode, VertexObject.GetMipMapLodBias, VertexObject.GetDrawOnGBuffer, VertexObject.HasGeometry, VertexObject.IsScreenSpace, VertexObject.DrawsAtStage, VertexObject.GetDerivedShader, VertexObject.ColorOverride), vertexObjectList) then
    begin
      vertexObjectList := TList<TVertexObject>.Create;
      ToBeRendered.add(RVertexTexture.Create(TextureFilename, SecondaryTextureFilename, VertexObject.GetVertexFormat, VertexObject.DrawOrder, VertexObject.GetBlendMode, VertexObject.GetTextureFilter, VertexObject.GetTextureAddressMode, VertexObject.GetMipMapLodBias, VertexObject.GetDrawOnGBuffer, VertexObject.HasGeometry, VertexObject.IsScreenSpace, VertexObject.DrawsAtStage, VertexObject.GetDerivedShader, VertexObject.ColorOverride), vertexObjectList);
    end;
    vertexObjectList.add(VertexObject);
  end;
  KeyArray := ToBeRendered.Keys.ToArray;

  TArray.Sort<RVertexTexture>(KeyArray, VertexTextureComparer);
end;

procedure TVertexEngine.OnFrameEnd();
begin
  // Clear Renderdictionary
  ToBeRendered.Clear;
  FVertexobjects.Clear;
  FVertexobjectsExistenceCheck.Clear;
end;

class procedure TVertexEngine.PrecompileDefaultShaders;
var
  DynamicSet : SetDefaultShaderFlags;
  Permutator : TGroupPermutator<SetDefaultShaderFlags>;
begin
  assert(assigned(GFXD), 'TVertexEngine.PrecompileDefaultShaders: Graphics needs to be initialized!');
  DynamicSet := [sfDiffuseTexture, sfNormalmapping, sfVertexcolor, sfColorReplacement];

  Permutator := TGroupPermutator<SetDefaultShaderFlags>.Create;
  Permutator.AddFixedValue(TArray<SetDefaultShaderFlags>.Create([sfGBuffer]));

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .AddValues(GFXD.DefaultShaderManager.SetDefaultShaderFlagsToArray(DynamicSet))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
  // 1
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawNormal, sfNormalmapping, sfUseAlpha]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawPosition]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawMaterial]))
  // 2
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor, sfDeferredDrawMaterial]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor, sfDeferredDrawPosition]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor, sfDeferredDrawNormal, sfNormalmapping, sfUseAlpha]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawPosition, sfDeferredDrawNormal, sfNormalmapping, sfUseAlpha]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawPosition, sfDeferredDrawMaterial]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawMaterial, sfDeferredDrawNormal, sfNormalmapping, sfUseAlpha]))
  // 3
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawMaterial]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawNormal, sfNormalmapping, sfUseAlpha]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor, sfDeferredDrawMaterial, sfDeferredDrawNormal, sfNormalmapping, sfUseAlpha]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawPosition, sfDeferredDrawMaterial, sfDeferredDrawNormal, sfNormalmapping, sfUseAlpha]))
  // 4
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDeferredDrawColor, sfDeferredDrawNormal, sfDeferredDrawPosition, sfDeferredDrawMaterial, sfNormalmapping, sfUseAlpha]))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValue(TArray<SetDefaultShaderFlags>.Create([]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfAlphaMap, sfAlphaMapTexCoords]))
    );

  GFXD.DefaultShaderManager.PrecompileSet(Permutator, False);
  Permutator.Free;

  DynamicSet := DynamicSet + [sfRHW];
  Permutator := TGroupPermutator<SetDefaultShaderFlags>.Create;

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .AddValues(GFXD.DefaultShaderManager.SetDefaultShaderFlagsToArray(DynamicSet))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValue(TArray<SetDefaultShaderFlags>.Create([]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfAlphaMap, sfAlphaMapTexCoords]))
    );

  GFXD.DefaultShaderManager.PrecompileSet(Permutator, False);
  Permutator.Free;
end;

procedure TVertexEngine.Render(CurrentStage : EnumRenderStage; RenderContext : TRenderContext);
var
  tupel : RVertexTexture;
begin
  for tupel in KeyArray do
  begin
    if CurrentStage = tupel.DrawsAtStage then
    begin
      RawRender(tupel, RenderContext)
    end;
  end;
end;

procedure TVertexEngine.RawRender(const ToRender : RVertexTexture; const RenderContext : TRenderContext);
var
  VertexObject : TVertexObject;
  pVertex : Pointer;
  Vertexcount, FinalVertexCount : integer;
  VertexbufferList : TVertexBufferList;
  vertexbuffer : TVertexBuffer;
  Shader : TShader;
  Rendertargets : TArray<TRendertarget>;
  ShaderFlags : SetDefaultShaderFlags;
  decl : TVertexdeclaration;
begin
  ResetDrawn;
  if ToBeRendered[ToRender].Count > 0 then
  begin
    // required Renderstates
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, cmNone);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsZWRITEENABLE, 0);

    decl := ToRender.VertexDeclaration;

    // fetch appropiate vertexbuffer, fetch none if FVF is empty => no geometry
    if (ToRender.HasGeometry) and not FVertexbuffer.TryGetValue(ToRender.VertexDeclaration, VertexbufferList) then
    begin
      VertexbufferList := TVertexBufferList.Create([usFrequentlyWriteable], GFXD.Device3D);
      FVertexbuffer.add(ToRender.VertexDeclaration, VertexbufferList);
    end;
    // fill vertexbuffer, first how many vertices are there
    Vertexcount := 0;
    for VertexObject in ToBeRendered[ToRender] do
    begin
      Vertexcount := Vertexcount + VertexObject.GetVertexCount;
    end;
    if (ToRender.HasGeometry) and (Vertexcount <= 0) then exit;

    // lock appropiate size in vertexbuffer, none if geometryless vertexobjects are rendered
    if (ToRender.HasGeometry) then
    begin
      vertexbuffer := VertexbufferList.GetVertexbuffer(Vertexcount * decl.VertexSize);
      pVertex := vertexbuffer.LowLock([lfDiscard]);
    end
    else vertexbuffer := nil;
    FinalVertexCount := 0;
    for VertexObject in ToBeRendered[ToRender] do
    begin
      FinalVertexCount := FinalVertexCount + VertexObject.ComputeAndSave(pVertex);
    end;
    // if geometryless vertexobjects are rendered end here, because it's done in ComputeAndSave
    if (not ToRender.HasGeometry) then exit;
    assert(assigned(decl));
    vertexbuffer.Unlock;

    // no vertices have been written to buffer
    if FinalVertexCount <= 0 then exit;

    FDrawnTriangles := FDrawnTriangles + (FinalVertexCount div 3);

    for VertexObject in ToBeRendered[ToRender] do
      if assigned(VertexObject.OnPreRender) then
          VertexObject.OnPreRender(RenderContext);

    // render vertexbuffer
    GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(rsDESTBLEND, blOne);
    case ToRender.BlendMode of
      BlendAdditive : GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
      BlendSubtractive : GFXD.Device3D.SetRenderState(rsBLENDOP, boSubtract);
      BlendReverseSubtractive : GFXD.Device3D.SetRenderState(rsBLENDOP, boRevSubtract);
    else
      begin
        GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
        GFXD.Device3D.SetRenderState(rsDESTBLEND, blInvSrcAlpha);
        GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
      end;
    end;

    ShaderFlags := [];
    if ToRender.DrawOnGBuffer <> [] then
    begin
      setlength(Rendertargets, 0);
      if dgColor in ToRender.DrawOnGBuffer then
      begin
        ShaderFlags := ShaderFlags + [sfDeferredDrawColor];
        setlength(Rendertargets, Length(Rendertargets) + 1);
        Rendertargets[high(Rendertargets)] := RenderContext.GBuffer.ColorBuffer.Texture.AsRendertarget;
      end;
      if dgPosition in ToRender.DrawOnGBuffer then
      begin
        ShaderFlags := ShaderFlags + [sfDeferredDrawPosition];
        setlength(Rendertargets, Length(Rendertargets) + 1);
        Rendertargets[high(Rendertargets)] := RenderContext.GBuffer.PositionBuffer.Texture.AsRendertarget;
      end;
      if dgNormal in ToRender.DrawOnGBuffer then
      begin
        ShaderFlags := ShaderFlags + [sfDeferredDrawNormal];
        ShaderFlags := ShaderFlags + [sfNormalmapping, sfUseAlpha];
        setlength(Rendertargets, Length(Rendertargets) + 1);
        Rendertargets[high(Rendertargets)] := RenderContext.GBuffer.Normalbuffer.Texture.AsRendertarget;
      end;
      if dgMaterial in ToRender.DrawOnGBuffer then
      begin
        ShaderFlags := ShaderFlags + [sfDeferredDrawMaterial];
        setlength(Rendertargets, Length(Rendertargets) + 1);
        Rendertargets[high(Rendertargets)] := RenderContext.GBuffer.MaterialBuffer.Texture.AsRendertarget;
      end;
      GFXD.Device3D.PushRenderTargets(Rendertargets);
    end;

    if ToRender.IsScreenSpace then ShaderFlags := ShaderFlags + [sfRHW];
    if ToRender.TextureName <> '' then ShaderFlags := ShaderFlags + [sfDiffuseTexture];
    if ToRender.SecondaryTextureName <> '' then ShaderFlags := ShaderFlags + [sfAlphaMap, sfAlphaMapTexCoords];
    if decl.HasUsagetype(euNormal) then ShaderFlags := ShaderFlags + [sfNormalmapping];
    if decl.HasUsagetype(euColor) then ShaderFlags := ShaderFlags + [sfVertexcolor];
    if not ToRender.ColorOverride.IsFullTransparent then
        ShaderFlags := ShaderFlags + [sfColorReplacement];

    GFXD.Device3D.SetSamplerState(tsColor, ToRender.TextureFilter, ToRender.TextureAddressMode, ToRender.TextureMipMapLodBias);

    if ToRender.DerivedShader <> '' then
        Shader := RenderContext.CreateAndSetDefaultShader(ShaderFlags, [ToRender.DerivedShader])
    else
        Shader := RenderContext.CreateAndSetDefaultShader(ShaderFlags);
    Shader.SetWorld(RMatrix.IDENTITY);

    if ToBeRendered[ToRender].First.GetTexture <> nil then
        Shader.SetTexture(tsColor, ToBeRendered[ToRender].First.GetTexture);
    if ToBeRendered[ToRender].First.GetSecondaryTexture <> nil then
        Shader.SetTexture(tsVariable2, ToBeRendered[ToRender].First.GetSecondaryTexture);
    if (dgNormal in ToRender.DrawOnGBuffer) then
    begin
      GFXD.Device3D.SetRenderState(rsSEPARATEALPHABLENDENABLE, true);
      GFXD.Device3D.SetRenderState(rsSRCBLENDALPHA, blZero);
      GFXD.Device3D.SetRenderState(rsDESTBLENDALPHA, blOne);
      GFXD.Device3D.SetRenderState(rsBLENDOPALPHA, boAdd);
      Shader.SetTexture(tsNormal, ToBeRendered[ToRender].First.GetNormalTexture);
    end;
    if not ToRender.ColorOverride.IsFullTransparent then
        Shader.SetShaderConstant<RVector4>(dcReplacementColor, ToRender.ColorOverride);

    GFXD.Device3D.SetVertexDeclaration(decl);
    GFXD.Device3D.SetStreamSource(0, vertexbuffer, 0, decl.VertexSize);
    Shader.ShaderBegin;
    GFXD.Device3D.DrawPrimitive(ptTrianglelist, 0, FinalVertexCount div 3);
    Shader.ShaderEnd;
    inc(FDrawCalls);
    if ToRender.DrawOnGBuffer <> [] then
        GFXD.Device3D.PopRenderTargets;

    GFXD.Device3D.ClearRenderState;
    GFXD.Device3D.ClearSamplerStates;
  end;
end;

{ TVertexWorldspaceQuad }

procedure TVertexWorldspaceQuad.PushVertex(var Target : Pointer; Position : RVector3; Color : RColor; TexCoord : RVector2);
var
  VertexTex : PVertexPositionColorTexture;
  VertexCol : PVertexPositionColor;
begin
  if Texture <> nil then
  begin
    VertexTex := PVertexPositionColorTexture(Target);
    VertexTex^.Position := Position;
    VertexTex^.TextureCoordinate := TexCoord;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    Target := VertexTex;
  end
  else
  begin
    VertexCol := PVertexPositionColor(Target);
    VertexCol^.Position := Position;
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    Target := VertexCol;
  end;
end;

function TVertexWorldspaceQuad.ComputeAndSave(var Target : Pointer) : integer;
var
  VertexKrass : PVertexPositionNormalColorTextureTangentBinormal;
  tempLeft, tempUp, TL, TR, BL, BR : RVector3;
begin
  if Left.isZeroVector then
  begin
    if Up.isZeroVector then
    begin
      tempLeft := Owner.Scene.Camera.ScreenLeft * (Width / 2);
      tempUp := Owner.Scene.Camera.ScreenUp * (Height / 2);
    end
    else
    begin
      tempUp := Up.Normalize * (Height / 2);
      tempLeft := Owner.Scene.Camera.CameraDirection.Cross(tempUp).Normalize * (Width / 2);
    end;
  end
  else
  begin
    if Up.isZeroVector then
    begin
      tempLeft := Left.Normalize * (Width / 2);
      tempUp := Owner.Scene.Camera.CameraDirection.Cross(tempLeft).Normalize * (Height / 2);
    end
    else
    begin
      tempLeft := Left.Normalize * (Width / 2);
      tempUp := Up.Normalize * (Height / 2);
    end;
  end;
  Result := 6;

  TL := Position + tempLeft * Trapezial.X + tempUp * Trapezial.Y;
  TR := Position - tempLeft * Trapezial.X + tempUp * (1 / Trapezial.Y);
  BL := Position + tempLeft * (1 / Trapezial.X) - tempUp * Trapezial.Y;
  BR := Position - tempLeft * (1 / Trapezial.X) - tempUp * (1 / Trapezial.Y);

  if dgNormal in DrawOnGBuffer then
  begin
    VertexKrass := PVertexPositionNormalColorTextureTangentBinormal(Target);
    VertexKrass^.Position := TL;
    VertexKrass^.TextureCoordinate := CoordinateRect.LeftTop;
    VertexKrass^.Color := Color;
    VertexKrass^.Normal := tempLeft.Cross(tempUp).Normalize;
    VertexKrass^.Tangent := -tempUp.Normalize;
    VertexKrass^.Binormal := tempLeft.Normalize;
    inc(VertexKrass, 1);
    VertexKrass^.Position := BL;
    VertexKrass^.TextureCoordinate := CoordinateRect.LeftBottom;
    VertexKrass^.Color := Color;
    VertexKrass^.Normal := tempLeft.Cross(tempUp).Normalize;
    VertexKrass^.Tangent := -tempUp.Normalize;
    VertexKrass^.Binormal := tempLeft.Normalize;
    inc(VertexKrass, 1);
    VertexKrass^.Position := TR;
    VertexKrass^.TextureCoordinate := CoordinateRect.RightTop;
    VertexKrass^.Color := Color;
    VertexKrass^.Normal := tempLeft.Cross(tempUp).Normalize;
    VertexKrass^.Tangent := -tempUp.Normalize;
    VertexKrass^.Binormal := tempLeft.Normalize;
    inc(VertexKrass, 1);
    VertexKrass^.Position := BL;
    VertexKrass^.TextureCoordinate := CoordinateRect.LeftBottom;
    VertexKrass^.Color := Color;
    VertexKrass^.Normal := tempLeft.Cross(tempUp).Normalize;
    VertexKrass^.Tangent := -tempUp.Normalize;
    VertexKrass^.Binormal := tempLeft.Normalize;
    inc(VertexKrass, 1);
    VertexKrass^.Position := TR;
    VertexKrass^.TextureCoordinate := CoordinateRect.RightTop;
    VertexKrass^.Color := Color;
    VertexKrass^.Normal := tempLeft.Cross(tempUp).Normalize;
    VertexKrass^.Tangent := -tempUp.Normalize;
    VertexKrass^.Binormal := tempLeft.Normalize;
    inc(VertexKrass, 1);
    VertexKrass^.Position := BR;
    VertexKrass^.TextureCoordinate := CoordinateRect.RightBottom;
    VertexKrass^.Color := Color;
    VertexKrass^.Normal := tempLeft.Cross(tempUp).Normalize;
    VertexKrass^.Tangent := -tempUp.Normalize;
    VertexKrass^.Binormal := tempLeft.Normalize;
    inc(VertexKrass, 1);
    Target := VertexKrass;
  end
  else
  begin
    PushVertex(Target, TL, Color, CoordinateRect.LeftTop);
    PushVertex(Target, BL, Color, CoordinateRect.LeftBottom);
    PushVertex(Target, TR, Color, CoordinateRect.RightTop);
    PushVertex(Target, BL, Color, CoordinateRect.LeftBottom);
    PushVertex(Target, TR, Color, CoordinateRect.RightTop);
    PushVertex(Target, BR, Color, CoordinateRect.RightBottom);
  end;
end;

constructor TVertexWorldspaceQuad.Create(Owner : TVertexEngine; Position, Up, Left : RVector3; Width, Height : single; Texture : TTexture; DrawOrder : integer);
begin
  Create(Owner);
  self.Position := Position;
  self.Up := Up;
  self.Left := Left;
  self.Width := Width;
  self.Height := Height;
  self.Texture := Texture;
  self.DrawOrder := DrawOrder;
end;

constructor TVertexWorldspaceQuad.Create(Owner : TVertexEngine);
begin
  inherited Create(Owner);
  Color := $FFFFFFFF;
  Visible := true;
  Trapezial := RVector2.Create(1, 1);
  CoordinateRect := RRectFloat.Create(0, 0, 1, 1);
end;

function TVertexWorldspaceQuad.GetNormalTexture : TTexture;
begin
  Result := NormalTexture;
end;

function TVertexWorldspaceQuad.GetVertexFormat : TVertexdeclaration;
begin
  assert(DrawOnGBuffer * [dgPosition, dgMaterial] = [], 'Position and Material only rendering not supported yet.');
  if dgNormal in DrawOnGBuffer then
  begin
    // signalize Vertexdeclaration
    Result := RVertexPositionNormalColorTextureTangentBinormal.BuildVertexdeclaration;
  end
  else
  begin
    if Texture = nil then Result := RVertexPositionColor.BuildVertexdeclaration
    else Result := RVertexPositionColorTexture.BuildVertexdeclaration;
  end;
end;

{ TVertexQuad }

destructor TVertexQuad.Destroy;
begin
  if OwnsTexture then Texture.Free;
  inherited;
end;

function TVertexQuad.GetSecondaryTexture : TTexture;
begin
  Result := SecondaryTexture;
end;

function TVertexQuad.GetSize : RVector2;
begin
  Result.X := Width;
  Result.Y := Height;
end;

function TVertexQuad.GetTexture : TTexture;
begin
  Result := Texture;
end;

function TVertexQuad.GetVertexCount : integer;
begin
  Result := 6;
end;

function TVertexQuad.IsFullTransparent : boolean;
begin
  if UseGradientColors then Result := Color.IsFullTransparent and TopRightColor.IsFullTransparent and BottomRightColor.IsFullTransparent and BottomLeftColor.IsFullTransparent
  else Result := Color.IsFullTransparent;
end;

procedure TVertexQuad.SetSize(const Value : RVector2);
begin
  Width := Value.X;
  Height := Value.Y;
end;

{ RVertexPositionTexture }

class
  function RVertexPositionTexture.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

constructor RVertexPositionTexture.Create(Position : RVector3;
TextureCoordinate : RVector2);
begin
  self.Position := Position;
  self.TextureCoordinate := TextureCoordinate;
end;

class destructor RVertexPositionTexture.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ RVertexPositionColor }

class
  function RVertexPositionColor.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat4, euColor);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

constructor RVertexPositionColor.Create(Position : RVector3; Color : RColor);
begin
  self.Position := Position;
  self.Color := Color;
end;

class destructor RVertexPositionColor.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ RVertexTexture }

constructor RVertexTexture.Create(TextureName, SecondaryTextureName : string; VertexDeclaration : TVertexdeclaration; DrawOrder : integer; BlendMode : EnumBlendMode; TextureFilter : EnumTextureFilter; TextureAddressMode : EnumTexturAddressMode; TextureMipMapLodBias : single; DrawOnGMode : SetDrawGMode; HasGeometry, IsScreenSpace : boolean; DrawsAtStage : EnumRenderStage; DerivedShader : string; ColorOverride : RColor);
begin
  self.TextureName := TextureName;
  self.SecondaryTextureName := SecondaryTextureName;
  self.VertexDeclaration := VertexDeclaration;
  self.DrawOrder := DrawOrder;
  self.BlendMode := BlendMode;
  self.TextureFilter := TextureFilter;
  self.TextureAddressMode := TextureAddressMode;
  self.TextureMipMapLodBias := TextureMipMapLodBias;
  self.DrawOnGBuffer := DrawOnGMode;
  self.HasGeometry := HasGeometry;
  self.IsScreenSpace := IsScreenSpace;
  self.DrawsAtStage := DrawsAtStage;
  self.DerivedShader := DerivedShader;
  self.ColorOverride := ColorOverride;
end;

class operator RVertexTexture.equal(a, b : RVertexTexture) : boolean;
begin
  Result := (a.TextureName = b.TextureName) and (a.SecondaryTextureName = b.SecondaryTextureName) and (a.VertexDeclaration = b.VertexDeclaration) and
    (a.DrawOrder = b.DrawOrder) and (a.BlendMode = b.BlendMode) and (a.TextureFilter = b.TextureFilter) and (a.TextureAddressMode = b.TextureAddressMode) and
    (a.DrawOnGBuffer = b.DrawOnGBuffer) and (a.HasGeometry = b.HasGeometry) and (a.IsScreenSpace = b.IsScreenSpace) and
    (a.DrawsAtStage = b.DrawsAtStage) and (a.DerivedShader = b.DerivedShader) and (abs(a.TextureMipMapLodBias - b.TextureMipMapLodBias) < SINGLE_ZERO_EPSILON) and
    (a.ColorOverride.AsCardinal = b.ColorOverride.AsCardinal);
end;

function RVertexTexture.Hash : integer;
begin
  Result := Length(TextureName) xor
    Length(DerivedShader) xor
    integer(VertexDeclaration) xor
    DrawOrder xor
    Ord(BlendMode) xor
    Ord(TextureFilter) xor
    integer(SetToCardinal(DrawOnGBuffer, sizeof(DrawOnGBuffer))) xor
    integer(ColorOverride.AsCardinal);
end;

{ TVertexTrace }

constructor TVertexTrace.Create(Owner : TVertexEngine; Texture : TTexture; Up : RVector3; Trackwidth, TrackSetDistance, FadeLength, MaxLength, TexturePerDistance : single; DrawOrder : integer);
begin
  Create(Owner);
  self.Texture := Texture;
  self.Up := Up;
  self.Trackwidth := Trackwidth;
  self.TrackSetDistance := TrackSetDistance;
  self.TexturePerDistance := TexturePerDistance;
  self.FadeLength := FadeLength;
  self.MaxLength := MaxLength;
  self.DrawOrder := DrawOrder;
end;

constructor TVertexTrace.Create(Owner : TVertexEngine);
begin
  inherited Create(Owner);
  FTrack := TList<RTrackPoint>.Create;
  self.Color := RColor.CWHITE;
  self.Visible := true;
  self.Texture := nil;
  self.Up := RVector3.ZERO;
  self.Trackwidth := 1;
  self.TrackSetDistance := 1;
  self.TexturePerDistance := 1;
  self.FadeLength := 1;
  self.MaxLength := 1;
  self.DrawOrder := 0;
end;

destructor TVertexTrace.Destroy;
begin
  if OwnsTexture then
      Texture.Free;
  FTrack.Free;
  inherited;
end;

function TVertexTrace.GetTexture : TTexture;
begin
  Result := Texture;
end;

function TVertexTrace.GetVertexCount : integer;
begin
  Result := Max(0, (FTrack.Count - 1) * 6);
end;

function TVertexTrace.GetVertexFormat : TVertexdeclaration;
begin
  Result := RVertexPositionColorTexture.BuildVertexdeclaration;
end;

function TVertexTrace.IsEmpty : boolean;
begin
  Result := (FTrack.Count <= 2);
end;

function TVertexTrace.ComputeAndSave(var Target : Pointer) : integer;
var
  i : integer;
  Point, NextPoint : RTrackPoint;
  tUp, tNextLeft, tLeft : RVector3;
  Vertex : PVertexPositionColorTexture;
  Flip : boolean;
  trackLength, segmentLength, alpha, nalpha : single;
  function getFront(index : integer) : RVector3;
  var
    temp, temp2 : RVector3;
  begin
    if index = 0 then Result := -(FTrack[index].Position - FTrack[index + 1].Position).Normalize
    else if (index = FTrack.Count - 1) then Result := -(FTrack[index - 1].Position - FTrack[index].Position).Normalize
    else
    begin
      temp := (FTrack[index].Position - FTrack[index - 1].Position).Normalize;
      temp2 := (FTrack[index + 1].Position - FTrack[index].Position).Normalize;
      if temp.Dot(temp2) < 0 then
      begin
        temp := -temp;
        Flip := not Flip;
      end;
      Result := (temp + temp2).Normalize;
      if Flip then Result := -Result;
    end;
  end;

begin
  Flip := False;
  Result := 0;
  if FTrack.Count <= 1 then exit;
  trackLength := 0;
  Vertex := PVertexPositionColorTexture(Target);
  if Up.isZeroVector then tUp := Owner.Scene.Camera.CameraDirection
  else tUp := Up.Normalize;

  for i := 0 to FTrack.Count - 2 do
  begin
    Point := FTrack[i];
    Point.Position := Point.Position + FBase;
    NextPoint := FTrack[i + 1];
    NextPoint.Position := NextPoint.Position + FBase;
    segmentLength := Point.Position.Distance(NextPoint.Position);
    alpha := HMath.Saturate(trackLength / FadeLength);
    trackLength := trackLength + segmentLength;
    nalpha := HMath.Saturate(trackLength / FadeLength);

    tLeft := getFront(i).Cross(tUp) * (Trackwidth / 2 + FadeWidening * (1 - alpha));
    tNextLeft := getFront(i + 1).Cross(tUp) * (Trackwidth / 2 + FadeWidening * (1 - alpha));

    Vertex^.Position := Point.Position + tLeft;
    Vertex^.Color := Color;
    Vertex^.Color.W := Vertex^.Color.W * alpha;
    Vertex^.TextureCoordinate := RVector2.Create(0, Point.TextureOffset);
    inc(Vertex);
    Vertex^.Position := Point.Position - tLeft;
    Vertex^.Color := Color;
    Vertex^.Color.W := Vertex^.Color.W * alpha;
    Vertex^.TextureCoordinate := RVector2.Create(1, Point.TextureOffset);
    inc(Vertex);
    Vertex^.Position := NextPoint.Position + tNextLeft;
    Vertex^.Color := Color;
    Vertex^.Color.W := Vertex^.Color.W * nalpha;
    Vertex^.TextureCoordinate := RVector2.Create(0, NextPoint.TextureOffset);
    inc(Vertex);
    Vertex^.Position := Point.Position - tLeft;
    Vertex^.Color := Color;
    Vertex^.Color.W := Vertex^.Color.W * alpha;
    Vertex^.TextureCoordinate := RVector2.Create(1, Point.TextureOffset);
    inc(Vertex);
    Vertex^.Position := NextPoint.Position - tNextLeft;
    Vertex^.Color := Color;
    Vertex^.Color.W := Vertex^.Color.W * nalpha;
    Vertex^.TextureCoordinate := RVector2.Create(1, NextPoint.TextureOffset);
    inc(Vertex);
    Vertex^.Position := NextPoint.Position + tNextLeft;
    Vertex^.Color := Color;
    Vertex^.Color.W := Vertex^.Color.W * nalpha;
    Vertex^.TextureCoordinate := RVector2.Create(0, NextPoint.TextureOffset);
    inc(Vertex);
    Result := Result + 6;
  end;
  Target := Vertex;
end;

procedure TVertexTrace.RollUp(Distance : single);
var
  segmentLength : single;
  Point : RTrackPoint;
begin
  // prevent deletion of dynamic segment
  while (FTrack.Count > 2) and (Distance > 0) do
  begin
    segmentLength := FTrack[0].Position.Distance(FTrack[1].Position);
    if Distance >= segmentLength then
    begin
      Distance := Distance - segmentLength;
      FTrack.Delete(0);
    end
    else
    begin
      Point := FTrack[0];
      Point.Position := Point.Position.Lerp(FTrack[1].Position, Distance / segmentLength);
      Point.TextureOffset := HMath.LinLerpF(Point.TextureOffset, FTrack[1].TextureOffset, Distance / segmentLength);
      FTrack[0] := Point;
      exit;
    end;
  end;
end;

procedure TVertexTrace.SetPosition(const Value : RVector3);
const
  MAX_NEW_TRACKS = 20;
var
  temp : RVector3;
  SpawnNew : boolean;
  Tail : RTrackPoint;
  i, NewTrackCount : integer;
  Overhang : single;
begin
  FPosition := Value - FBase;
  if Tracking and (TrackSetDistance > 0) then
  begin
    // if new segment will be spawned, remove dynamic part
    SpawnNew := FLast.Distance(Position) >= TrackSetDistance;
    if SpawnNew then FTrack.Delete(FTrack.Count - 1);
    NewTrackCount := 0;
    while (FLast.Distance(Position) >= TrackSetDistance) and (NewTrackCount < MAX_NEW_TRACKS) do
    begin
      FCurrentTextureOffset := FCurrentTextureOffset + TrackSetDistance / TexturePerDistance;
      temp := FLast.Lerp(Position, TrackSetDistance / FLast.Distance(Position));
      FTrack.add(RTrackPoint.Create(temp, FCurrentTextureOffset));
      FLast := temp;
      inc(NewTrackCount);
    end;
    if NewTrackCount = MAX_NEW_TRACKS then
    begin
      FLast := Position;
      SpawnNew := False;
    end;
    // re-add dynamic segment
    if SpawnNew then FTrack.add(RTrackPoint.Create(Position, FCurrentTextureOffset));
    // update dynamic segment
    Tail := FTrack[FTrack.Count - 1];
    Tail.Position := Position;
    Tail.TextureOffset := FCurrentTextureOffset + FLast.Distance(Position) / TexturePerDistance;
    FTrack[FTrack.Count - 1] := Tail;
    // check max length and shorten path if needed
    Overhang := 0;
    for i := 0 to FTrack.Count - 2 do Overhang := Overhang + FTrack[i].Position.Distance(FTrack[i + 1].Position);
    Overhang := Overhang - MaxLength;
    RollUp(Overhang);
  end;
end;

procedure TVertexTrace.StartTracking;
begin
  if Tracking then exit;
  Tracking := true;
  FCurrentTextureOffset := 0;
  // starting point
  FTrack.add(RTrackPoint.Create(Position, FCurrentTextureOffset));
  // dynamic segment
  FTrack.add(RTrackPoint.Create(Position, FCurrentTextureOffset));
  FLast := Position;
end;

procedure TVertexTrace.StopTracking;
begin
  if not Tracking then exit;
  FCurrentTextureOffset := FCurrentTextureOffset + FLast.Distance(Position) / TexturePerDistance;
  FTrack.add(RTrackPoint.Create(Position, FCurrentTextureOffset));
  FLast := Position;
  Tracking := False;
end;

{ TVertexTrace.TTrackPoint }

constructor TVertexTrace.RTrackPoint.Create(Position : RVector3; TextureOffset : single);
begin
  self.Position := Position;
  self.TextureOffset := TextureOffset;
end;

{ RVertexPositionTextureColor }

class
  function RVertexPositionColorTexture.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat4, euColor);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

function RVertexPositionColorTexture.Lerp(b : RVertexPositionColorTexture; s : single) : RVertexPositionColorTexture;
begin
  Result.Position := Position.Lerp(b.Position, s);
  Result.TextureCoordinate := TextureCoordinate.Lerp(b.TextureCoordinate, s);
  Result.Color := Color.Lerp(b.Color, s);
end;

constructor RVertexPositionColorTexture.Create(Position : RVector3; TextureCoordinate : RVector2; Color : RColor);
begin
  self.Position := Position;
  self.TextureCoordinate := TextureCoordinate;
  self.Color := Color;
end;

class destructor RVertexPositionColorTexture.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ TVertexLine }

function TVertexLine.ComputeAndSave(var Target : Pointer) : integer;
var
  VertexTex : PVertexPositionColorTexture;
  VertexCol : PVertexPositionColor;
  tempLeft : RVector3;
begin
  if Normal.isZeroVector then tempLeft := Owner.Scene.Camera.CameraDirection.Cross(self.Target - Start).Normalize * (Width / 2)
  else tempLeft := Normal.Cross(self.Target - Start).Normalize * (Width / 2);

  Result := 6;
  if Texture <> nil then
  begin
    VertexTex := PVertexPositionColorTexture(Target);
    VertexTex^.Position := self.Target + tempLeft;
    VertexTex^.TextureCoordinate := CoordinateRect.LeftTop;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    VertexTex^.Position := Start + tempLeft;
    VertexTex^.TextureCoordinate := CoordinateRect.LeftBottom;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    VertexTex^.Position := self.Target - tempLeft;
    VertexTex^.TextureCoordinate := CoordinateRect.RightTop;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    VertexTex^.Position := self.Target - tempLeft;
    VertexTex^.TextureCoordinate := CoordinateRect.RightTop;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    VertexTex^.Position := Start + tempLeft;
    VertexTex^.TextureCoordinate := CoordinateRect.LeftBottom;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    VertexTex^.Position := Start - tempLeft;
    VertexTex^.TextureCoordinate := CoordinateRect.RightBottom;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    Target := VertexTex;
  end
  else
  begin
    VertexCol := PVertexPositionColor(Target);
    VertexCol^.Position := (self.Target + tempLeft);
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    VertexCol^.Position := (Start + tempLeft);
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    VertexCol^.Position := (self.Target - tempLeft);
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    VertexCol^.Position := (Start + tempLeft);
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    VertexCol^.Position := (self.Target - tempLeft);
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    VertexCol^.Position := (Start - tempLeft);
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    Target := VertexCol;
  end;

end;

constructor TVertexLine.Create(Owner : TVertexEngine);
begin
  inherited Create(Owner);
  Visible := true;
  self.CoordinateRect := RRectFloat.Create(0, 0, 1, 1);
  self.Color := RColor.CWHITE;
end;

constructor TVertexLine.Create(Owner : TVertexEngine; Start, Target, Normal : RVector3; Width : single; Texture : TTexture);
begin
  Create(Owner);
  self.Start := Start;
  self.Target := Target;
  self.Normal := Normal;
  self.Width := Width;
  self.Texture := Texture;
end;

function TVertexLine.GetTexture : TTexture;
begin
  Result := Texture
end;

function TVertexLine.GetVertexCount : integer;
begin
  Result := 6;
end;

function TVertexLine.GetVertexFormat : TVertexdeclaration;
begin
  if Texture = nil then Result := RVertexPositionColor.BuildVertexdeclaration
  else Result := RVertexPositionColorTexture.BuildVertexdeclaration;
end;

{ TVertexObject }

procedure TVertexObject.AddRenderJob;
begin
  FOwner.AddVertexObject(self);
end;

constructor TVertexObject.Create(Owner : TVertexEngine);
begin
  FOwner := Owner;
  BlendMode := EnumBlendMode.BlendLinear;
  FilterMode := EnumTextureFilter.tfAuto;
  DrawOnGBuffer := [];
  DrawsAtStage := rsEffects;
  AddressMode := EnumTexturAddressMode.amWrap;
end;

destructor TVertexObject.Destroy;
begin
  RemoveRenderJob;
  inherited;
end;

function TVertexObject.GetDrawsAtStage : EnumRenderStage;
begin
  Result := DrawsAtStage;
end;

function TVertexObject.GetMipMapLodBias : single;
begin
  Result := MipMapLodBias;
end;

function TVertexObject.GetBlendMode : EnumBlendMode;
begin
  Result := BlendMode;
end;

function TVertexObject.GetDerivedShader : string;
begin
  Result := DerivedShader;
end;

function TVertexObject.GetDrawOnGBuffer : SetDrawGMode;
begin
  Result := self.DrawOnGBuffer;
end;

function TVertexObject.GetDrawOrder : integer;
begin
  Result := DrawOrder;
end;

function TVertexObject.GetNormalTexture : TTexture;
begin
  Result := nil;
end;

function TVertexObject.GetSecondaryTexture : TTexture;
begin
  Result := nil;
end;

function TVertexObject.GetTextureAddressMode : EnumTexturAddressMode;
begin
  Result := AddressMode;
end;

function TVertexObject.GetTextureFilter : EnumTextureFilter;
begin
  Result := FilterMode;
end;

function TVertexObject.HasGeometry : boolean;
begin
  Result := true;
end;

function TVertexObject.IsScreenSpace : boolean;
begin
  Result := False;
end;

procedure TVertexObject.RemoveRenderJob;
begin
  FOwner.RemoveVertexObject(self);
end;

{ RVertexPositionNormalColorTextureTangentBinormal }

class
  function RVertexPositionNormalColorTextureTangentBinormal.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat4, euColor);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.AddVertexElement(etFloat3, euNormal);
    FDeclaration.AddVertexElement(etFloat3, euTangent);
    FDeclaration.AddVertexElement(etFloat3, euBinormal);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

constructor RVertexPositionNormalColorTextureTangentBinormal.Create(Position,
  Normal : RVector3; Color : RColor; TextureCoordinate : RVector2; Tangent,
  Binormal : RVector3);
begin
  self.Position := Position;
  self.Normal := Normal;
  self.Color := Color;
  self.TextureCoordinate := TextureCoordinate;
  self.Tangent := Tangent;
  self.Binormal := Binormal;
end;

class destructor RVertexPositionNormalColorTextureTangentBinormal.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ RVertexPositionNormalTextureTangentBinormal }

class
  function RVertexPositionTextureNormalTangentBinormal.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.AddVertexElement(etFloat3, euNormal);
    FDeclaration.AddVertexElement(etFloat3, euTangent);
    FDeclaration.AddVertexElement(etFloat3, euBinormal);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

constructor RVertexPositionTextureNormalTangentBinormal.Create(Position,
  Normal : RVector3; TextureCoordinate : RVector2; Tangent, Binormal : RVector3);
begin
  self.Position := Position;
  self.Normal := Normal;
  self.TextureCoordinate := TextureCoordinate;
  self.Tangent := Tangent;
  self.Binormal := Binormal;
end;

class destructor RVertexPositionTextureNormalTangentBinormal.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ RVertexPositionNormalColorTexture }

class
  function RVertexPositionNormalColorTexture.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat3, euNormal);
    FDeclaration.AddVertexElement(etFloat4, euColor);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

constructor RVertexPositionNormalColorTexture.Create(Position, Normal : RVector3;
TextureCoordinate : RVector2; Color : RColor);
begin
  self.Position := Position;
  self.Normal := Normal;
  self.TextureCoordinate := TextureCoordinate;
  self.Color := Color;
end;

class destructor RVertexPositionNormalColorTexture.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ TVertexScreenAlignedQuad }

function TVertexScreenAlignedQuad.ComputeAndSave(var Target : Pointer) : integer;
  procedure PushTexTexVertex(Position, Coord, Coord2 : RVector2; Color : RVector4);
  var
    VertexTex : PVertexPositionColorTextureTexture;
  begin
    VertexTex := PVertexPositionColorTextureTexture(Target);
    VertexTex^.Position := Position.XY0(0.5);
    if UseTransform then
        VertexTex^.Position := Transform * VertexTex^.Position;
    VertexTex^.TextureCoordinate := Coord;
    if UseTransform and not TransformAppliesToTexCoords then
        VertexTex^.TextureCoordinate := (Transform.To3x3.Transpose * VertexTex^.TextureCoordinate.XY0).XY;
    VertexTex^.TextureCoordinate2 := Coord2;
    if UseTransform and not TransformAppliesToTexCoords then
        VertexTex^.TextureCoordinate2 := (Transform.To3x3.Transpose * VertexTex^.TextureCoordinate2.XY0).XY;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    Target := VertexTex;
  end;
  procedure PushTexVertex(Position, Coord : RVector2; Color : RVector4);
  var
    VertexTex : PVertexPositionColorTexture;
  begin
    VertexTex := PVertexPositionColorTexture(Target);
    VertexTex^.Position := Position.XY0(0.5);
    if UseTransform then
        VertexTex^.Position := Transform * VertexTex^.Position;
    VertexTex^.TextureCoordinate := Coord;
    if UseTransform and not TransformAppliesToTexCoords then
        VertexTex^.TextureCoordinate := (Transform.To3x3.Transpose * VertexTex^.TextureCoordinate.XY0).XY;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    Target := VertexTex;
  end;
  procedure PushColVertex(Position : RVector2; Color : RVector4);
  var
    VertexCol : PVertexPositionColor;
  begin
    VertexCol := PVertexPositionColor(Target);
    VertexCol^.Position := Position.XY0(0.5);
    if UseTransform then
        VertexCol^.Position := Transform * VertexCol^.Position;
    VertexCol^.Color := Color;
    inc(VertexCol, 1);
    Target := VertexCol;
  end;

var
  Corners : array [0 .. 5] of RVector2;
  TexCoords : array [0 .. 5] of RVector2;
  TexCoords2 : array [0 .. 5] of RVector2;
  Colors : array [0 .. 5] of RVector4;
  procedure PushTriangleRaw(Corner1, Corner2, Corner3, Tex1, Tex2, Tex3, Tex12, Tex22, Tex32 : RVector2; Color1, Color2, Color3 : RVector4);
  begin
    if assigned(Texture) and assigned(SecondaryTexture) then
    begin
      PushTexTexVertex(Corner1, Tex1, Tex12, Color1);
      PushTexTexVertex(Corner2, Tex2, Tex22, Color2);
      PushTexTexVertex(Corner3, Tex3, Tex32, Color3);
    end
    else if assigned(Texture) then
    begin
      PushTexVertex(Corner1, Tex1, Color1);
      PushTexVertex(Corner2, Tex2, Color2);
      PushTexVertex(Corner3, Tex3, Color3);
    end
    else if assigned(SecondaryTexture) then
    begin
      PushTexVertex(Corner1, Tex12, Color1);
      PushTexVertex(Corner2, Tex22, Color2);
      PushTexVertex(Corner3, Tex32, Color3);
    end
    else
    begin
      PushColVertex(Corner1, Color1);
      PushColVertex(Corner2, Color2);
      PushColVertex(Corner3, Color3);
    end;
  end;
  procedure PushQuadRaw(Corner1, Corner2, Corner3, Corner4, Tex1, Tex2, Tex3, Tex4, Tex12, Tex22, Tex32, Tex42 : RVector2; Color1, Color2, Color3, Color4 : RVector4);
  begin
    PushTriangleRaw(Corner1, Corner4, Corner2, Tex1, Tex4, Tex2, Tex12, Tex42, Tex22, Color1, Color4, Color2);
    PushTriangleRaw(Corner2, Corner4, Corner3, Tex2, Tex4, Tex3, Tex22, Tex42, Tex32, Color2, Color4, Color3);
  end;
  procedure PushTriangle(i, j, k : integer);
  begin
    PushTriangleRaw(Corners[i], Corners[j], Corners[k], TexCoords[i], TexCoords[j], TexCoords[k], TexCoords2[i], TexCoords2[j], TexCoords2[k], Colors[i], Colors[j], Colors[k]);
  end;
  procedure ComputeAndSaveRadialClippedVertices();
  const
    INDEX_MAPPING : array [0 .. 4] of array [0 .. 2] of integer = (
      (5, 4, 0),
      (5, 0, 3),
      (5, 3, 2),
      (5, 2, 1),
      (5, 1, 4)
      );
  var
    i : integer;
    s : single;
    between : RVector2;
  begin
    // top between for clipping
    Corners[4] := Corners[0].Lerp(Corners[1], 0.5);
    TexCoords[4] := TexCoords[0].Lerp(TexCoords[1], 0.5);
    TexCoords2[4] := TexCoords2[0].Lerp(TexCoords2[1], 0.5);
    Colors[4] := Colors[0].Lerp(Colors[1], 0.5);
    // center of quad
    Corners[5] := Corners[0].Lerp(Corners[2], 0.5);
    TexCoords[5] := TexCoords[0].Lerp(TexCoords[2], 0.5);
    TexCoords2[5] := TexCoords2[0].Lerp(TexCoords2[2], 0.5);
    Colors[5] := Colors[0].Lerp(Colors[2], 0.5);

    for i := 0 to Length(RADIAL_STOPS) - 2 do
    begin
      // if both stops are in range, complete triangle can be pushed
      if (RADIAL_STOPS[i] < FRadialClip) and (RADIAL_STOPS[i + 1] <= FRadialClip) then
      begin
        PushTriangle(INDEX_MAPPING[i][0], INDEX_MAPPING[i][1], INDEX_MAPPING[i][2]);
      end
      // if second stop is out of range, clip triangle
      else if (RADIAL_STOPS[i] < FRadialClip) and (RADIAL_STOPS[i + 1] > FRadialClip) then
      begin
        s := (FRadialClip - RADIAL_STOPS[i]) / (RADIAL_STOPS[i + 1] - RADIAL_STOPS[i]);
        s := 1 - s;
        between := Corners[INDEX_MAPPING[i][2]].Lerp(Corners[INDEX_MAPPING[i][1]], s);
        // slerp, more correct, but not needed atm
        // between := Corners[INDEX_MAPPING[i][2]].SLerp(Corners[INDEX_MAPPING[i][1]], Corners[5], s);
        // between := RLine2D.CreateFromPoints(between, Corners[5]).IntersectionWithLine(RLine2D.CreateFromPoints(Corners[INDEX_MAPPING[i][2]], Corners[INDEX_MAPPING[i][1]]));
        PushTriangleRaw(
          Corners[INDEX_MAPPING[i][0]],
          Corners[INDEX_MAPPING[i][1]],
          between,
          TexCoords[INDEX_MAPPING[i][0]],
          TexCoords[INDEX_MAPPING[i][1]],
          TexCoords[INDEX_MAPPING[i][2]].Lerp(TexCoords[INDEX_MAPPING[i][1]], s),
          TexCoords2[INDEX_MAPPING[i][0]],
          TexCoords2[INDEX_MAPPING[i][1]],
          TexCoords2[INDEX_MAPPING[i][2]].Lerp(TexCoords2[INDEX_MAPPING[i][1]], s),
          Colors[INDEX_MAPPING[i][0]],
          Colors[INDEX_MAPPING[i][1]],
          Colors[INDEX_MAPPING[i][2]].Lerp(Colors[INDEX_MAPPING[i][1]], s)
          );
      end
      // if both stops are out of range, we're done
      else Break;
    end;
  end;

var
  BorderCorners, OutlineCorners : array [0 .. 7] of RVector2;
  DrawMask : RVector4;
  i : integer;
  AspectRatio : single;
  FinalRect, FinalCoordinateRect, SecondaryFinalCoordinateRect : RRectFloat;
begin
  if ScissorEnabled then
  begin
    if not GetFinalRect.Intersects(FScissorRect) then exit(0);
    // apply scissor
    FinalRect := Rect.Intersection(FScissorRect);

    FinalCoordinateRect := CoordinateRect.Intersection(Rect.RectToRelative(FinalRect));
    SecondaryFinalCoordinateRect := SecondaryCoordinateRect;
  end
  else
  begin
    FinalRect := Rect;
    FinalCoordinateRect := CoordinateRect;
    SecondaryFinalCoordinateRect := SecondaryCoordinateRect;
  end;
  if Zoom <> 1.0 then
  begin
    AspectRatio := FinalRect.AspectRatio;
    if AspectRatio <> 0 then
    begin
      if AspectRatio > 1 then FinalRect := FinalRect.Inflate(Zoom / AspectRatio, Zoom)
      else FinalRect := FinalRect.Inflate(Zoom, Zoom * AspectRatio);
    end;
  end;

  Result := GetVertexCount;

  Corners[0] := RVector2.Create(FinalRect.Left, FinalRect.top);
  TexCoords[0] := FinalCoordinateRect.LeftTop;
  TexCoords2[0] := SecondaryFinalCoordinateRect.LeftTop;
  Corners[1] := RVector2.Create(FinalRect.Right, FinalRect.top);
  TexCoords[1] := FinalCoordinateRect.RightTop;
  TexCoords2[1] := SecondaryFinalCoordinateRect.RightTop;
  Corners[2] := RVector2.Create(FinalRect.Right, FinalRect.Bottom);
  TexCoords[2] := FinalCoordinateRect.RightBottom;
  TexCoords2[2] := SecondaryFinalCoordinateRect.RightBottom;
  Corners[3] := RVector2.Create(FinalRect.Left, FinalRect.Bottom);
  TexCoords[3] := FinalCoordinateRect.LeftBottom;
  TexCoords2[3] := SecondaryFinalCoordinateRect.LeftBottom;

  if UseGradientColors then
  begin
    Colors[0] := Color;
    Colors[1] := TopRightColor;
    Colors[2] := BottomRightColor;
    Colors[3] := BottomLeftColor;
  end
  else
  begin
    Colors[0] := Color;
    Colors[1] := Color;
    Colors[2] := Color;
    Colors[3] := Color;
  end;

  if HasBorder or (BorderSizeInner <> 0.0) then
  begin
    // mask sides to be not pushed if not in use
    for i := 0 to 3 do
      if EnumRectSide(i) in DrawBorder then DrawMask.Element[i] := 1.0
      else DrawMask.Element[i] := 0.0;
    // outer
    BorderCorners[0] := Corners[0] + RVector2.Create(-BorderSizeOuter * DrawMask.X, -BorderSizeOuter * DrawMask.Y);
    BorderCorners[1] := Corners[1] + RVector2.Create(BorderSizeOuter * DrawMask.Z, -BorderSizeOuter * DrawMask.Y);
    BorderCorners[2] := Corners[2] + RVector2.Create(BorderSizeOuter * DrawMask.Z, BorderSizeOuter * DrawMask.W);
    BorderCorners[3] := Corners[3] + RVector2.Create(-BorderSizeOuter * DrawMask.X, BorderSizeOuter * DrawMask.W);
    // inner
    BorderCorners[4] := Corners[0] - RVector2.Create(-BorderSizeInner * DrawMask.X, -BorderSizeInner * DrawMask.Y);
    BorderCorners[5] := Corners[1] - RVector2.Create(BorderSizeInner * DrawMask.Z, -BorderSizeInner * DrawMask.Y);
    BorderCorners[6] := Corners[2] - RVector2.Create(BorderSizeInner * DrawMask.Z, BorderSizeInner * DrawMask.W);
    BorderCorners[7] := Corners[3] - RVector2.Create(-BorderSizeInner * DrawMask.X, BorderSizeInner * DrawMask.W);
  end;

  if HasOutline then
  begin
    // mask sides to be not pushed if not in use
    for i := 0 to 3 do
      if EnumRectSide(i) in DrawOutline then DrawMask.Element[i] := 1.0
      else DrawMask.Element[i] := 0.0;
    // outer
    OutlineCorners[0] := Corners[0] + RVector2.Create(-OutlineSizeOuter * DrawMask.X, -OutlineSizeOuter * DrawMask.Y);
    OutlineCorners[1] := Corners[1] + RVector2.Create(OutlineSizeOuter * DrawMask.Z, -OutlineSizeOuter * DrawMask.Y);
    OutlineCorners[2] := Corners[2] + RVector2.Create(OutlineSizeOuter * DrawMask.Z, OutlineSizeOuter * DrawMask.W);
    OutlineCorners[3] := Corners[3] + RVector2.Create(-OutlineSizeOuter * DrawMask.X, OutlineSizeOuter * DrawMask.W);
    // inner
    OutlineCorners[4] := Corners[0] - RVector2.Create(-OutlineSizeInner * DrawMask.X, -OutlineSizeInner * DrawMask.Y);
    OutlineCorners[5] := Corners[1] - RVector2.Create(OutlineSizeInner * DrawMask.Z, -OutlineSizeInner * DrawMask.Y);
    OutlineCorners[6] := Corners[2] - RVector2.Create(OutlineSizeInner * DrawMask.Z, OutlineSizeInner * DrawMask.W);
    OutlineCorners[7] := Corners[3] - RVector2.Create(-OutlineSizeInner * DrawMask.X, OutlineSizeInner * DrawMask.W);
  end;

  // if border is pushing into the center, shrink original quad to avoid overlapping
  if BorderSizeInner > 0.0 then
  begin
    Corners[0] := BorderCorners[4];
    Corners[1] := BorderCorners[5];
    Corners[2] := BorderCorners[6];
    Corners[3] := BorderCorners[7];
  end;

  if IsRadialClipped then ComputeAndSaveRadialClippedVertices
  else
  begin
    PushTriangle(0, 3, 1);
    PushTriangle(1, 3, 2);
  end;
  // first outline as border should be drawn above outline
  if HasOutline then
  begin
    Colors[0] := OutlineColorOuterStart;
    Colors[1] := OutlineColorOuterEnd;
    // top, right, bottom, left border
    if rsTop in DrawOutline then PushQuadRaw(OutlineCorners[0], OutlineCorners[1], OutlineCorners[5], OutlineCorners[4], TexCoords[0], TexCoords[1], TexCoords[1], TexCoords[0], TexCoords2[0], TexCoords2[1], TexCoords2[1], TexCoords2[0], Colors[1], Colors[1], Colors[0], Colors[0]);
    if rsRight in DrawOutline then PushQuadRaw(OutlineCorners[1], OutlineCorners[2], OutlineCorners[6], OutlineCorners[5], TexCoords[1], TexCoords[2], TexCoords[2], TexCoords[1], TexCoords2[1], TexCoords2[2], TexCoords2[2], TexCoords2[1], Colors[1], Colors[1], Colors[0], Colors[0]);
    if rsBottom in DrawOutline then PushQuadRaw(OutlineCorners[2], OutlineCorners[3], OutlineCorners[7], OutlineCorners[6], TexCoords[2], TexCoords[3], TexCoords[3], TexCoords[2], TexCoords2[2], TexCoords2[3], TexCoords2[3], TexCoords2[2], Colors[1], Colors[1], Colors[0], Colors[0]);
    if rsLeft in DrawOutline then PushQuadRaw(OutlineCorners[3], OutlineCorners[0], OutlineCorners[4], OutlineCorners[7], TexCoords[3], TexCoords[0], TexCoords[0], TexCoords[3], TexCoords2[3], TexCoords2[0], TexCoords2[0], TexCoords2[3], Colors[1], Colors[1], Colors[0], Colors[0]);
  end;
  if HasBorder then
  begin
    Colors[0] := BorderColorOuterStart;
    Colors[1] := BorderColorOuterEnd;
    // top, right, bottom, left Outline
    if rsTop in DrawBorder then PushQuadRaw(BorderCorners[0], BorderCorners[1], BorderCorners[5], BorderCorners[4], TexCoords[0], TexCoords[1], TexCoords[1], TexCoords[0], TexCoords2[0], TexCoords2[1], TexCoords2[1], TexCoords2[0], Colors[1], Colors[1], Colors[0], Colors[0]);
    if rsRight in DrawBorder then PushQuadRaw(BorderCorners[1], BorderCorners[2], BorderCorners[6], BorderCorners[5], TexCoords[1], TexCoords[2], TexCoords[2], TexCoords[1], TexCoords2[1], TexCoords2[2], TexCoords2[2], TexCoords2[1], Colors[1], Colors[1], Colors[0], Colors[0]);
    if rsBottom in DrawBorder then PushQuadRaw(BorderCorners[2], BorderCorners[3], BorderCorners[7], BorderCorners[6], TexCoords[2], TexCoords[3], TexCoords[3], TexCoords[2], TexCoords2[2], TexCoords2[3], TexCoords2[3], TexCoords2[2], Colors[1], Colors[1], Colors[0], Colors[0]);
    if rsLeft in DrawBorder then PushQuadRaw(BorderCorners[3], BorderCorners[0], BorderCorners[4], BorderCorners[7], TexCoords[3], TexCoords[0], TexCoords[0], TexCoords[3], TexCoords2[3], TexCoords2[0], TexCoords2[0], TexCoords2[3], Colors[1], Colors[1], Colors[0], Colors[0]);
  end;
end;

constructor TVertexScreenAlignedQuad.Create(Owner : TVertexEngine);
begin
  inherited Create(Owner);
  Anchor := RVector2.Create(0, 0);
  Color := $FFFFFFFF;
  Visible := true;
  Zoom := 1.0;
  CoordinateRect := RRectFloat.Create(0, 0, 1, 1);
  RadialClip := -1; // radial clipping disabled by default
  DrawBorder := [low(EnumRectSide) .. high(EnumRectSide)];
  DrawOutline := [low(EnumRectSide) .. high(EnumRectSide)];
end;

constructor TVertexScreenAlignedQuad.Create(Owner : TVertexEngine; Position : RVector2; Width, Height : single; Texture : TTexture; DrawOrder : integer);
begin
  Create(Owner);
  self.Position := Position;
  self.Width := Width;
  self.Height := Height;
  self.Texture := Texture;
  self.DrawOrder := DrawOrder;
end;

function TVertexScreenAlignedQuad.GetRadialClippedVertexCount : integer;
var
  i : integer;
begin
  Result := 0;
  // each segment needs a triangle
  for i := 0 to Length(RADIAL_STOPS) - 1 do
    if FRadialClip > RADIAL_STOPS[i] then Result := Result + 3;
end;

function TVertexScreenAlignedQuad.GetVertexCount : integer;
var
  side : EnumRectSide;
begin
  // fully clipped
  if ScissorEnabled and not GetFinalRect.Intersects(ScissorRect) then exit(0);

  if IsRadialClipped then Result := GetRadialClippedVertexCount
  else Result := 6;
  // add border
  if HasBorder then
    for side in DrawBorder do Result := Result + 2 * 3;
  // add outline
  if HasOutline then
    for side in DrawOutline do Result := Result + 2 * 3;
end;

function TVertexScreenAlignedQuad.GetVertexFormat : TVertexdeclaration;
begin
  if assigned(SecondaryTexture) and assigned(Texture) then Result := RVertexPositionColorTextureTexture.BuildVertexdeclaration
  else if assigned(Texture) or assigned(SecondaryTexture) then Result := RVertexPositionColorTexture.BuildVertexdeclaration
  else Result := RVertexPositionColor.BuildVertexdeclaration;
end;

function TVertexScreenAlignedQuad.HasBorder : boolean;
begin
  Result := (BorderSizeInner <> 0) or (BorderSizeOuter <> 0) and not(BorderColorOuterStart.IsFullTransparent and BorderColorOuterEnd.IsFullTransparent) and (DrawBorder <> []);
end;

function TVertexScreenAlignedQuad.HasOutline : boolean;
begin
  Result := (OutlineSizeInner <> 0) or (OutlineSizeOuter <> 0) and not(OutlineColorOuterStart.IsFullTransparent and OutlineColorOuterEnd.IsFullTransparent) and (DrawOutline <> []);
end;

function TVertexScreenAlignedQuad.IsRadialClipped : boolean;
begin
  Result := RadialClip >= 0;
end;

function TVertexScreenAlignedQuad.IsScreenSpace : boolean;
begin
  Result := true;
end;

procedure TVertexScreenAlignedQuad.setBorderColor(const Value : RColor);
begin
  BorderColorOuterStart := Value;
  BorderColorOuterEnd := Value;
end;

constructor TVertexScreenAlignedQuad.Create(Owner: TVertexEngine; Position, Size: RVector2; Texture: TTexture; DrawOrder: integer);
begin
  Create(Owner, Position, Size.X, Size.Y, Texture, DrawOrder);
end;

function TVertexScreenAlignedQuad.GetFinalRect : RRectFloat;
begin
  Result := Rect.Inflate(BorderSizeOuter);
end;

function TVertexScreenAlignedQuad.GetQuad : RRectFloat;
begin
  Result := RRectFloat.CreateWidthHeight(Position.X - Anchor.X * Width,
    Position.Y - Anchor.Y * Height, Width, Height);
end;

procedure TVertexScreenAlignedQuad.SetRadialClip(const Value : single);
begin
  if Value < 0 then FRadialClip := -1
  else FRadialClip := HMath.Saturate(Value);
end;

procedure TVertexScreenAlignedQuad.SetLocationRect(const Value : RRectFloat);
begin
  Width := Value.Width;
  Height := Value.Height;
  Position := Value.LeftTop;
end;

{ TVertexFont }

procedure TVertexFont.CopyValuesToFont;
begin
  FFont.Color := FColor;
  FFont.Format := Format;
  FFont.Cliprect := Rect;
  FFont.Border := FFontBorder;
  FFont.Resolution := FFontResolution;
  FFont.Text := FText;
end;

procedure TVertexFont.CleanDirty;
begin
  if FDirty then
  begin
    CopyValuesToFont;
    FFont.Text := Text;
    FDrawnTexture := FFont.DrawText();
    FDirty := False;
  end;
end;

function TVertexFont.ComputeAndSave(var Target : Pointer) : integer;
var
  VertexTex : PVertexPositionColorTexture;
  VirtualTextureSize : RVector2;
  CoordinateRect, Cliprect, FinalRect : RRectFloat;
  AspectRatio : single;
  Color : RColor;
begin
  CleanDirty;
  if not assigned(FDrawnTexture) then exit(0);

  VirtualTextureSize := FDrawnTexture.Size / Resolution;
  Cliprect := self.Rect.ToRectFloat;
  Cliprect.Size := Cliprect.Size.Min(VirtualTextureSize);

  CoordinateRect := RRectFloat.CreateWidthHeight(RVector2.ZERO, Cliprect.Size / VirtualTextureSize);

  if ScissorEnabled then
  begin
    if not Cliprect.Intersects(FScissorRect) then exit(0);
    // apply scissor
    FinalRect := Cliprect.Intersection(FScissorRect);

    CoordinateRect := (Cliprect.RectToRelative(FinalRect) * Cliprect.Size) / VirtualTextureSize;
    Cliprect := FinalRect;
  end;
  if Zoom <> 1.0 then
  begin
    AspectRatio := Cliprect.AspectRatio;
    if AspectRatio <> 0 then
    begin
      if AspectRatio > 1 then Cliprect := Cliprect.Inflate(Zoom / AspectRatio, Zoom)
      else Cliprect := Cliprect.Inflate(Zoom, Zoom / AspectRatio);
    end;
  end;

  Color := RColor.CreateFromSingle(1, 1, 1, FColor.a);

  Result := 6;

  VertexTex := PVertexPositionColorTexture(Target);
  VertexTex^.Position := RVector3.Create(Cliprect.Left, Cliprect.top, 0.5);
  if UseTransform then
      VertexTex^.Position := Transform * VertexTex^.Position;
  VertexTex^.TextureCoordinate := CoordinateRect.LeftTop;
  VertexTex^.Color := Color;
  inc(VertexTex, 1);
  VertexTex^.Position := RVector3.Create(Cliprect.Left, Cliprect.Bottom, 0.5);
  if UseTransform then
      VertexTex^.Position := Transform * VertexTex^.Position;
  VertexTex^.TextureCoordinate := CoordinateRect.LeftBottom;
  VertexTex^.Color := Color;
  inc(VertexTex, 1);
  VertexTex^.Position := RVector3.Create(Cliprect.Right, Cliprect.top, 0.5);
  if UseTransform then
      VertexTex^.Position := Transform * VertexTex^.Position;
  VertexTex^.TextureCoordinate := CoordinateRect.RightTop;
  VertexTex^.Color := Color;
  inc(VertexTex, 1);

  VertexTex^.Position := RVector3.Create(Cliprect.Right, Cliprect.top, 0.5);
  if UseTransform then
      VertexTex^.Position := Transform * VertexTex^.Position;
  VertexTex^.TextureCoordinate := CoordinateRect.RightTop;
  VertexTex^.Color := Color;
  inc(VertexTex, 1);
  VertexTex^.Position := RVector3.Create(Cliprect.Left, Cliprect.Bottom, 0.5);
  if UseTransform then
      VertexTex^.Position := Transform * VertexTex^.Position;
  VertexTex^.TextureCoordinate := CoordinateRect.LeftBottom;
  VertexTex^.Color := Color;
  inc(VertexTex, 1);
  VertexTex^.Position := RVector3.Create(Cliprect.Right, Cliprect.Bottom, 0.5);
  if UseTransform then
      VertexTex^.Position := Transform * VertexTex^.Position;
  VertexTex^.TextureCoordinate := CoordinateRect.RightBottom;
  VertexTex^.Color := Color;
  inc(VertexTex, 1);
  Target := VertexTex;
end;

constructor TVertexFont.Create(Owner : TVertexEngine; FontDescription : RFontDescription);
begin
  inherited Create(Owner);
  FFontResolution := 1.0;
  self.FontDescription := FontDescription;
  Color := $FF000000;
  AddressMode := EnumTexturAddressMode.amClamp;
end;

destructor TVertexFont.Destroy;
begin
  FFont.Free;
  inherited;
end;

function TVertexFont.GetTexture : TTexture;
begin
  CleanDirty;
  Result := FDrawnTexture;
end;

function TVertexFont.GetVertexCount : integer;
begin
  if not HasText or (ScissorEnabled and not FScissorRect.Intersects(FRect)) then exit(0);
  CleanDirty;
  if assigned(FDrawnTexture) then Result := 6
  else Result := 0;
end;

function TVertexFont.GetVertexFormat : TVertexdeclaration;
begin
  Result := RVertexPositionColorTexture.BuildVertexdeclaration()
end;

function TVertexFont.HasGeometry : boolean;
begin
  Result := true;
end;

function TVertexFont.HasText : boolean;
begin
  Result := Text <> '';
end;

function TVertexFont.IndexToPosition(const CharacterIndex : integer) : RRectFloat;
begin
  CopyValuesToFont;
  Result := FFont.IndexToPosition(CharacterIndex);
end;

function TVertexFont.IsClearType : boolean;
begin
  Result := FFontDescription.Quality in [fqClearType, fqClearTypeNatural];
end;

function TVertexFont.IsScreenSpace : boolean;
begin
  Result := true;
end;

function TVertexFont.PositionToIndex(const Position : RVector2) : integer;
begin
  CopyValuesToFont;
  Result := FFont.PositionToIndex(Position);
end;

procedure TVertexFont.setColor(const Value : RColor);
begin
  if Value <> FColor then
  begin
    FDirty := true;
    FColor := Value;
  end;
end;

procedure TVertexFont.SetRect(const Value : RRect);
begin
  if FRect <> Value then
  begin
    // Font is drawn without offset, which are applied later, so we don't need to rerender if size didn't change
    FDirty := FDirty or (FRect.Size <> Value.Size);
    FRect := Value;
  end;
end;

procedure TVertexFont.SetFontBorder(const Value : RFontBorder);
begin
  if FFontBorder <> Value then
  begin
    FDirty := true;
    FFontBorder := Value;
  end;
end;

procedure TVertexFont.setFontDescription(const Value : RFontDescription);
begin
  if Value <> FFontDescription then
  begin
    FFont.Free;
    FFontDescription := Value;
    FFont := TFont.CreateFont(Value, GFXD.Device3D);
    FDirty := true;
  end;
end;

procedure TVertexFont.SetFontResolution(const Value : single);
begin
  if FFontResolution <> Value then
  begin
    FDirty := true;
    FFontResolution := Value;
  end;
end;

procedure TVertexFont.SetFormat(const Value : SetFontRenderingFlags);
begin
  if FFormat <> Value then
  begin
    FDirty := true;
    FFormat := Value;
  end;
end;

procedure TVertexFont.setText(const Value : string);
begin
  if FText <> Value then
  begin
    FDirty := true;
    FText := Value;
  end;
end;

function TVertexFont.TextBlockHeight() : integer;
begin
  CopyValuesToFont;
  FFont.Text := Text;
  Result := FFont.TextBlockHeight();
end;

function TVertexFont.TextWidth() : integer;
begin
  CopyValuesToFont;
  FFont.Text := Text;
  Result := FFont.TextWidth();
end;

{ TVertexFontWorld }

function TVertexFontWorld.ComputeAndSave(var Target : Pointer) : integer;
  procedure PushVertex(var Target : Pointer; Position : RVector3; Color : RColor; TexCoord : RVector2);
  var
    VertexTex : PVertexPositionColorTexture;
  begin
    VertexTex := PVertexPositionColorTexture(Target);
    VertexTex^.Position := Position;
    VertexTex^.TextureCoordinate := TexCoord;
    VertexTex^.Color := Color;
    inc(VertexTex, 1);
    Target := VertexTex;
  end;

var
  Color : RColor;
  tempLeft, tempUp, TL, TR, BL, BR : RVector3;
  CoordinateRect : RRectFloat;
begin
  CleanDirty;
  if not assigned(FDrawnTexture) then exit(0);

  Color := FColor;
  CoordinateRect := RRectFloat.CreateWidthHeight(RVector2.ZERO, (Size * WorldToPixelFactor) / FDrawnTexture.Size.ToRVector);
  if IsClearType then Color.RGB := RVector3.Create(1);

  if Left.isZeroVector then
  begin
    if Up.isZeroVector then
    begin
      tempLeft := Owner.Scene.Camera.ScreenLeft * (Width / 2);
      tempUp := Owner.Scene.Camera.ScreenUp * (Height / 2);
    end
    else
    begin
      tempUp := Up.Normalize * (Height / 2);
      tempLeft := Owner.Scene.Camera.CameraDirection.Cross(tempUp).Normalize * (Width / 2);
    end;
  end
  else
  begin
    if Up.isZeroVector then
    begin
      tempLeft := Left.Normalize * (Width / 2);
      tempUp := Owner.Scene.Camera.CameraDirection.Cross(tempLeft).Normalize * (Height / 2);
    end
    else
    begin
      tempLeft := Left.Normalize * (Width / 2);
      tempUp := Up.Normalize * (Height / 2);
    end;
  end;

  TL := Position + tempLeft + tempUp;
  TR := Position - tempLeft + tempUp;
  BL := Position + tempLeft - tempUp;
  BR := Position - tempLeft - tempUp;

  Result := 6;

  PushVertex(Target, TL, Color, CoordinateRect.LeftTop);
  PushVertex(Target, BL, Color, CoordinateRect.LeftBottom);
  PushVertex(Target, TR, Color, CoordinateRect.RightTop);
  PushVertex(Target, BL, Color, CoordinateRect.LeftBottom);
  PushVertex(Target, TR, Color, CoordinateRect.RightTop);
  PushVertex(Target, BR, Color, CoordinateRect.RightBottom);
end;

procedure TVertexFontWorld.CopyValuesToFont;
begin
  self.Rect.Size := (Size * WorldToPixelFactor).Round;
  inherited;
end;

constructor TVertexFontWorld.Create(Owner : TVertexEngine; FontDescription : RFontDescription);
begin
  inherited Create(Owner, FontDescription);
  FWorldToPixelFactor := 1.0;
end;

function TVertexFontWorld.GetVertexCount : integer;
begin
  if not HasText then exit(0);
  CleanDirty;
  if assigned(FDrawnTexture) then Result := 6
  else Result := 0;
end;

function TVertexFontWorld.GetVertexFormat : TVertexdeclaration;
begin
  Result := RVertexPositionColorTexture.BuildVertexdeclaration()
end;

function TVertexFontWorld.IsScreenSpace : boolean;
begin
  Result := False;
end;

procedure TVertexFontWorld.SetSize(const Value : RVector2);
begin
  if FSize <> Value then
  begin
    FDirty := true;
    FSize := Value;
  end;
end;

procedure TVertexFontWorld.SetWorldToPixelFactor(const Value : single);
begin
  if FWorldToPixelFactor <> Value then
  begin
    FDirty := true;
    FWorldToPixelFactor := Value;
  end;
end;

{ RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight }

class
  function RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.AddVertexElement(etFloat3, euNormal);
    FDeclaration.AddVertexElement(etFloat3, euTangent);
    FDeclaration.AddVertexElement(etFloat3, euBinormal);
    FDeclaration.AddVertexElement(etFloat4, euBlendWeight);
    FDeclaration.AddVertexElement(etFloat4, euBlendIndices);
    FDeclaration.AddVertexElement(etFloat3, euNormal, emDefault, 0, 1);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

class destructor RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ RVertexPositionNormalTextureTangentBinormalBoneIndicesWeight }

class
  function RVertexPositionNormalTextureTangentBinormalBoneIndicesWeight.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat3, euNormal);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.AddVertexElement(etFloat3, euTangent);
    FDeclaration.AddVertexElement(etFloat3, euBinormal);
    FDeclaration.AddVertexElement(etFloat4, euBlendWeight);
    FDeclaration.AddVertexElement(etFloat4, euBlendIndices);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

class destructor RVertexPositionNormalTextureTangentBinormalBoneIndicesWeight.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ RVertexPositionNormalColorTextureData }

class
  function RVertexPositionNormalColorTextureData.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat3, euNormal);
    FDeclaration.AddVertexElement(etFloat4, euColor);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.AddVertexElement(etFloat3, euTexturecoordinate, emDefault, 0, 1);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

class destructor RVertexPositionNormalColorTextureData.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

{ TRHWLinePool }

procedure TRHWLinePool.AddDashedRect(LeftTop, RightBottom : RIntVector2; Color : RColor; Dashlength : integer);
begin
  LeftTop := LeftTop + RIntVector2.Create(1, 1);
  DrawDashedLine(RIntVector2.Create(LeftTop.X, RightBottom.Y), LeftTop, Dashlength, Color,
    DrawDashedLine(RightBottom, RIntVector2.Create(LeftTop.X, RightBottom.Y), Dashlength, Color,
    DrawDashedLine(RIntVector2.Create(RightBottom.X, LeftTop.Y), RightBottom, Dashlength, Color,
    DrawDashedLine(LeftTop, RIntVector2.Create(RightBottom.X, LeftTop.Y), Dashlength, Color, 0))));
end;

procedure TRHWLinePool.AddLine(Startposition, Endposition : RIntVector2; StartColor, EndColor : RColor);
begin
  if FMaxLineCount <= FCurrentLineCount + 1 then exit;
  FLinebuffer[FCurrentLineCount * 2] := RVertexPositionColor.Create(RVector3.Create(Startposition.X, Startposition.Y, 0.5), StartColor);
  FLinebuffer[FCurrentLineCount * 2 + 1] := RVertexPositionColor.Create(RVector3.Create(Endposition.X, Endposition.Y, 0.5), EndColor);
  inc(FCurrentLineCount);
end;

procedure TRHWLinePool.AddRect(Rect : RRect; Color : RColor);
begin
  AddRect(Rect.LeftTop, Rect.RightBottom, Color);
end;

procedure TRHWLinePool.AddRect(LeftTop, RightBottom : RIntVector2; Color : RColor);
begin
  LeftTop := LeftTop + RIntVector2.Create(1, 1);
  AddLine(LeftTop - RIntVector2.Create(1, 0), RIntVector2.Create(RightBottom.X, LeftTop.Y), Color);
  AddLine(LeftTop, RIntVector2.Create(LeftTop.X, RightBottom.Y), Color);
  AddLine(RightBottom, RIntVector2.Create(RightBottom.X, LeftTop.Y), Color);
  AddLine(RightBottom, RIntVector2.Create(LeftTop.X, RightBottom.Y), Color);
end;

procedure TRHWLinePool.AddLine(Startposition, Endposition : RIntVector2; Color : RColor);
begin
  AddLine(Startposition, Endposition, Color, Color);
end;

procedure TRHWLinePool.AddCircle(Center : RIntVector2; Radius : integer; Color : RColor; Samples : integer);
var
  i : integer;
  rad : single;
  pos, pos2 : RVector2;
begin
  for i := 0 to Samples - 1 do
  begin
    rad := (i / (Samples - 1)) * 2 * PI;
    pos := (RVector2.Create(sin(rad), cos(rad)) * Radius) + Center;
    rad := ((i + 1) / (Samples - 1)) * 2 * PI;
    pos2 := (RVector2.Create(sin(rad), cos(rad)) * Radius) + Center;
    AddLine(RIntVector2.CreateFromVector2(pos), RIntVector2.CreateFromVector2(pos2), Color);
  end;
end;

procedure TRHWLinePool.AddDashedCircle(Center : RIntVector2; Radius, Dashlength : integer; Color : RColor; Samples : integer);
var
  i : integer;
  s, rad : single;
  pos, pos2 : RVector2;
begin
  s := 0;
  for i := 0 to Samples - 1 do
  begin
    rad := (i / (Samples - 1)) * 2 * PI;
    pos := (RVector2.Create(sin(rad), cos(rad)) * Radius) + Center;
    rad := ((i + 1) / (Samples - 1)) * 2 * PI;
    pos2 := (RVector2.Create(sin(rad), cos(rad)) * Radius) + Center;
    s := DrawDashedLine(RIntVector2.CreateFromVector2(pos), RIntVector2.CreateFromVector2(pos2), Dashlength, Color, s);
  end;
end;

procedure TRHWLinePool.AddDashedRect(Rect : RRect; Color : RColor; Dashlength : integer);
begin
  AddDashedRect(Rect.LeftTop, Rect.RightBottom, Color, Dashlength);
end;

constructor TRHWLinePool.Create(Scene : TRenderManager; MaxLineCount : integer);
begin
  FCallbackTime := ctAfter;
  inherited Create(Scene, [rsGUI]);
  self.FMaxLineCount := MaxLineCount;
  FRHWVertexbuffer := TVertexBufferList.Create([usFrequentlyWriteable], GFXD.Device3D);
  setlength(FLinebuffer, FMaxLineCount);
end;

destructor TRHWLinePool.Destroy;
begin
  FRHWVertexbuffer.Free;
  inherited;
end;

function TRHWLinePool.DrawDashedLine(StartPos, EndPos : RIntVector2; Dashlength : single; Color : RColor; DashOffset : single) : single;
var
  dist : single;
  Start, dir : RVector2;
begin
  // empty space ahead
  if DashOffset <= 0 then
  begin
    DashOffset := abs(DashOffset);
    Start := StartPos;
    dir := RVector2(EndPos - StartPos).Normalize;
    dist := Start.Distance(EndPos);
    if dist <= DashOffset then Result := -(DashOffset - dist)
    else Result := DrawRawDashedLine(RIntVector2.CreateFromVector2(Start + dir * DashOffset), EndPos, Dashlength, Color);
  end
  else
  // line at the beginning
  begin
    Start := StartPos;
    dist := Start.Distance(EndPos);
    if dist <= DashOffset then
    begin
      AddLine(StartPos, EndPos, Color);
      exit(DashOffset - dist);
    end;
    dir := RVector2(EndPos - StartPos).Normalize;
    AddLine(StartPos, RIntVector2.CreateFromVector2(Start + dir * DashOffset), Color);
    Start := Start + (dir * DashOffset);
    dist := Start.Distance(EndPos);
    if dist < Dashlength then exit(-dist);
    Start := Start + (dir * Dashlength);
    Result := DrawRawDashedLine(RIntVector2.CreateFromVector2(Start), EndPos, Dashlength, Color);
  end;
end;

function TRHWLinePool.DrawRawDashedLine(StartPos, EndPos : RIntVector2; Dashlength : single; Color : RColor) : single;
var
  i : integer;
  dist : single;
  Start, dash : RVector2;
begin
  dash := RVector2(EndPos - StartPos).Normalize * Dashlength;
  Start := StartPos;
  dist := Start.Distance(EndPos);
  for i := 0 to trunc(dist / (Dashlength * 2)) - 1 do
  begin
    AddLine(RIntVector2.CreateFromVector2(Start), RIntVector2.CreateFromVector2(Start + dash), Color);
    Start := Start + (2 * dash);
  end;
  dist := Start.Distance(EndPos);
  if dist >= Dashlength then
  begin
    AddLine(RIntVector2.CreateFromVector2(Start), RIntVector2.CreateFromVector2(Start + dash), Color);
    Result := -(2 * Dashlength - dist);
  end
  else
  begin
    AddLine(RIntVector2.CreateFromVector2(Start), EndPos, Color);
    Result := (Dashlength - dist);
  end;
end;

procedure TRHWLinePool.Render(EventIdentifier : EnumRenderStage; RenderContext : TRenderContext);
var
  Shader : TShader;
  vertices : Pointer;
  vb : TVertexBuffer;
  NeededVertexbufferSize : integer;
begin
  if FCurrentLineCount > 0 then
  begin
    NeededVertexbufferSize := FCurrentLineCount * 2 * sizeof(RVertexPositionColor);
    vb := FRHWVertexbuffer.GetVertexbuffer(NeededVertexbufferSize);
    // pass the geometry to the gpu
    vertices := vb.LowLock();
    CopyMemory(vertices, @FLinebuffer[0], NeededVertexbufferSize);
    vb.Unlock;

    Shader := RenderContext.CreateAndSetDefaultShader([sfVertexcolor, sfRHW]);
    Shader.SetWorld(RMatrix.IDENTITY);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsZENABLE, 0);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blInvSrcAlpha);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOP, boAdd);
    GFXD.Device3D.SetStreamSource(0, vb, 0, sizeof(RVertexPositionColor));
    GFXD.Device3D.SetVertexDeclaration(RVertexPositionColor.BuildVertexdeclaration);
    Shader.ShaderBegin;
    GFXD.Device3D.DrawPrimitive(ptLinelist, 0, FCurrentLineCount);
    Shader.ShaderEnd;
    FCurrentLineCount := 0;
  end;
end;

{ TVertexScreenAlignedTriangle }

function TVertexScreenAlignedTriangle.ComputeAndSave(var Target : Pointer) : integer;
var
  VertexTex : PVertexPositionColorTexture;
  VertexCol : PVertexPositionColor;
  i : integer;
begin
  Result := 3;

  if Texture <> nil then
  begin
    VertexTex := PVertexPositionColorTexture(Target);
    for i := 0 to 2 do
    begin
      VertexTex^.Position := Position[i].XY0(0.5);
      VertexTex^.TextureCoordinate := TextureCoordinate[i];
      VertexTex^.Color := Color;
      inc(VertexTex, 1);
    end;
    Target := VertexTex;
  end
  else
  begin
    VertexCol := PVertexPositionColor(Target);
    for i := 0 to 2 do
    begin
      VertexCol^.Position := Position[i].XY0(0.5);
      VertexCol^.Color := Color;
      inc(VertexCol, 1);
    end;
    Target := VertexCol;
  end;
end;

constructor TVertexScreenAlignedTriangle.Create(Owner : TVertexEngine);
begin
  inherited Create(Owner);
  Color := $FFFFFFFF;
  Visible := true;
end;

function TVertexScreenAlignedTriangle.GetTexture : TTexture;
begin
  Result := Texture;
end;

function TVertexScreenAlignedTriangle.GetVertexCount : integer;
begin
  Result := 3;
end;

function TVertexScreenAlignedTriangle.GetVertexFormat : TVertexdeclaration;
begin
  if Texture = nil then Result := RVertexPositionColor.BuildVertexdeclaration
  else Result := RVertexPositionColorTexture.BuildVertexdeclaration;
end;

function TVertexScreenAlignedTriangle.IsScreenSpace : boolean;
begin
  Result := true;
end;

{ RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight }

class
  function RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.BuildVertexdeclaration(MorphtargetCount : integer) : TVertexdeclaration;
var
  decl : TVertexdeclaration;
  i : integer;
begin
  assert(MorphtargetCount > 0, 'RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.BuildVertexdeclaration: Can''t build vertexdeclaration for 0 subsets!');
  if Length(FDeclaration) < MorphtargetCount then
      setlength(FDeclaration, MorphtargetCount);
  decl := FDeclaration[MorphtargetCount - 1];
  if not assigned(decl) then
  begin
    decl := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    for i := 0 to MorphtargetCount - 1 do
    begin
      decl.AddVertexElement(etFloat3, euPosition, emDefault, 0, i);
    end;
    decl.AddVertexElement(etFloat2, euTexturecoordinate);
    decl.AddVertexElement(etFloat3, euNormal);
    decl.AddVertexElement(etFloat3, euTangent);
    decl.AddVertexElement(etFloat3, euBinormal);
    decl.AddVertexElement(etFloat4, euBlendWeight);
    decl.AddVertexElement(etFloat4, euBlendIndices);
    decl.AddVertexElement(etFloat3, euNormal, emDefault, 0, 1);
    decl.EndDeclaration;
    FDeclaration[MorphtargetCount - 1] := decl;
  end;
  Result := decl;
end;

class destructor RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

class
  function RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.GetSize(MorphtargetCount : integer) : integer;
begin
  Result := sizeof(RVertexPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight) + sizeof(RVector3) * (MorphtargetCount - 1);
end;

{ AVMPNSNTTBBIWHelper }

procedure AVMPNSNTTBBIWHelper.CopyTo(Target : Pointer; MorphtargetCount : integer; checkSize : integer);
var
  i : integer;
  j : integer;
  startpointer : Pointer;
begin
  startpointer := Target;
  for i := 0 to Length(self) - 1 do
  begin
    for j := 0 to MorphtargetCount - 1 do
    begin
      PRVector3(Target)^ := self[i].Position[j];
      inc(PRVector3(Target));
    end;
    PRVector2(Target)^ := self[i].TextureCoordinate;
    inc(PRVector2(Target));
    PRVector3(Target)^ := self[i].Normal;
    inc(PRVector3(Target));
    PRVector3(Target)^ := self[i].Tangent;
    inc(PRVector3(Target));
    PRVector3(Target)^ := self[i].Binormal;
    inc(PRVector3(Target));
    PRVector4(Target)^ := self[i].BoneWeights;
    inc(PRVector4(Target));
    PRVector4(Target)^ := self[i].BoneIndices;
    inc(PRVector4(Target));
    PRVector3(Target)^ := self[i].SmoothedNormal;
    inc(PRVector3(Target));
  end;
  if checkSize > 0 then
  begin
    checkSize := checkSize - (integer(Target) - integer(startpointer));
    assert(checkSize = 0, 'AVMPNSNTTBBIWHelper.CopyTo: Checksize didn''t match!');
  end;
end;

{ RVertexPositionColorTextureTexture }

class
  function RVertexPositionColorTextureTexture.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat4, euColor);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate, emDefault, 0, 1);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

constructor RVertexPositionColorTextureTexture.Create(Position : RVector3; TextureCoordinate, TextureCoordinate2 : RVector2; Color : RColor);
begin
  self.Position := Position;
  self.TextureCoordinate := TextureCoordinate;
  self.TextureCoordinate2 := TextureCoordinate2;
  self.Color := Color;
end;

class destructor RVertexPositionColorTextureTexture.Destroy;
begin
  // freed by device
  // FDeclaration.Free;
end;

function RVertexPositionColorTextureTexture.Lerp(b : RVertexPositionColorTextureTexture; s : single) : RVertexPositionColorTextureTexture;
begin
  Result.Position := Position.Lerp(b.Position, s);
  Result.TextureCoordinate := TextureCoordinate.Lerp(b.TextureCoordinate, s);
  Result.TextureCoordinate2 := TextureCoordinate2.Lerp(b.TextureCoordinate2, s);
  Result.Color := Color.Lerp(b.Color, s);
end;

{ TVertexWorldspaceCircle }

function TVertexWorldspaceCircle.ComputeAndSave(var Target : Pointer) : integer;
var
  i : integer;
  Sample, NextSample, Angle, NextAngle, TexLeft, TexRight : single;
  Normal, SideInner, SideOuter, LeftTop, RightTop, LeftBottom, RightBottom : RVector3;
begin
  Normal := Up.Cross(Left).Normalize;
  SideInner := Up.Normalize * (Radius - Thickness / 2);
  SideOuter := Up.Normalize * (Radius + Thickness / 2);
  // circle consist of n linear segments
  for i := 0 to Samples - 2 do
  begin
    Sample := (i / (Samples - 1));
    NextSample := ((i + 1) / (Samples - 1));
    // segment out of range, skip
    if (NextSample < SliceFrom) or (Sample > SliceTo) then continue;
    if Sample < SliceFrom then Sample := SliceFrom;
    if NextSample > SliceTo then NextSample := SliceTo;
    Angle := Sample * PI * 2;
    NextAngle := NextSample * PI * 2;
    LeftTop := Position + SideOuter.RotateAxis(Normal, Angle);
    RightTop := Position + SideOuter.RotateAxis(Normal, NextAngle);
    LeftBottom := Position + SideInner.RotateAxis(Normal, Angle);
    RightBottom := Position + SideInner.RotateAxis(Normal, NextAngle);

    TexLeft := Sample;
    TexRight := NextSample;

    PushVertex(Target, LeftTop, Color, RVector2.Create(TexLeft, 0));
    PushVertex(Target, LeftBottom, Color, RVector2.Create(TexLeft, 1));
    PushVertex(Target, RightTop, Color, RVector2.Create(TexRight, 0));

    PushVertex(Target, RightTop, Color, RVector2.Create(TexRight, 0));
    PushVertex(Target, LeftBottom, Color, RVector2.Create(TexLeft, 1));
    PushVertex(Target, RightBottom, Color, RVector2.Create(TexRight, 1));
  end;
  Result := GetVertexCount;
end;

constructor TVertexWorldspaceCircle.Create(Owner : TVertexEngine);
begin
  inherited Create(Owner);
  Samples := 32;
  SliceFrom := 0;
  SliceTo := 1;
end;

function TVertexWorldspaceCircle.GetVertexCount : integer;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to Samples - 2 do
  begin
    if (((i + 1) / (Samples - 1)) < SliceFrom) or ((i / (Samples - 1)) > SliceTo) then continue;
    Result := Result + 1;
  end;
  Result := Result * 6;
end;

procedure TVertexWorldspaceCircle.SetSliceFrom(const Value : single);
begin
  FSliceFrom := HMath.Saturate(Value);
end;

procedure TVertexWorldspaceCircle.SetSliceTo(const Value : single);
begin
  FSliceTo := Max(SliceFrom, HMath.Saturate(Value));
end;

end.
