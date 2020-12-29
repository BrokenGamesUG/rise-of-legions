unit Engine.GfxApi.Classmapper;

interface

uses
  Generics.Collections,
  System.SysUtils,
  Engine.GfxApi,
  Engine.DX9Api,
  Engine.DX11Api,
  Engine.GfxApi.Types;

type

  EGfxApiExistNonMapping = class(Exception);

  RClassMap = record
    FromClass : TClass;
    ToClass : TClass;
  end;

  CTextur = class of TTexture;
  CRendertarget = class of TRendertarget;
  CShader = class of TShader;
  CVertexBuffer = class of TVertexBuffer;
  CIndexBuffer = class of TIndexBuffer;
  CVertexDeclaration = class of TVertexDeclaration;
  CFont = class of TFont;
  CDevice = class of TDevice;
  CDepthStencilBuffer = class of TDepthStencilBuffer;

const
  /// <summary> Constant classmap array. For every GFXDType this array maps the main classes to the specific class.</summary>
  GFXDCLASSMAPPING : array [0 .. 2] of array [0 .. 8] of RClassMap =
  // Mapping for DirectX9
    ((
    (FromClass : TTexture; ToClass : TDirectX9Textur),
    (FromClass : TShader; ToClass : TDirectX9Shader),
    (FromClass : TVertexBuffer; ToClass : TDirectX9VertexBuffer),
    (FromClass : TIndexBuffer; ToClass : TDirectX9IndexBuffer),
    (FromClass : TVertexDeclaration; ToClass : TDirectX9VertexDeclaration),
    (FromClass : TFont; ToClass : TFont),
    (FromClass : TDevice; ToClass : TDirectX9Device),
    (FromClass : TRendertarget; ToClass : TDirectX9Rendertarget),
    (FromClass : TDepthStencilBuffer; ToClass : TDirectX9DepthStencilBuffer)
    ),
    // Mapping for DirectX11
    (
    (FromClass : TTexture; ToClass : TDirectX11Texture),
    (FromClass : TShader; ToClass : TDirectX11Shader),
    (FromClass : TVertexBuffer; ToClass : TDirectX11VertexBuffer),
    (FromClass : TIndexBuffer; ToClass : TDirectX11IndexBuffer),
    (FromClass : TVertexDeclaration; ToClass : TDirectX11VertexDeclaration),
    (FromClass : TFont; ToClass : TFont),
    (FromClass : TDevice; ToClass : TDirectX11Device),
    (FromClass : TRendertarget; ToClass : TDirectX11Rendertarget),
    (FromClass : TDepthStencilBuffer; ToClass : TDirectX11DepthStencilBuffer)
    ),
    // Mapping for OpenGL
    (
    (FromClass : TTexture; ToClass : nil),
    (FromClass : TShader; ToClass : nil),
    (FromClass : TVertexBuffer; ToClass : nil),
    (FromClass : TIndexBuffer; ToClass : nil),
    (FromClass : TVertexDeclaration; ToClass : nil),
    (FromClass : TFont; ToClass : nil),
    (FromClass : TDevice; ToClass : nil),
    (FromClass : TRendertarget; ToClass : nil),
    (FromClass : TDepthStencilBuffer; ToClass : nil)
    ));

type
  /// <summary> Maps the DirectX and OpenGL classed to the main resourceclasses, e.g. TDirectXTextur for TTextur</summary>
  TGfxApiClassMapper = class
    private
      FClassMap : TDictionary<TClass, TClass>;
      FGFXDType : EnumGFXDType;
    public
      /// <summary> Standard constructor...</summary>
      /// <param name="GFXDType"> Type of GFXD. Type detemines which classes are used for resource creation.</param>
      constructor Create(GFXDType : EnumGFXDType);
      /// <summary> Maps a resource class to corresponding class that necessary to create resource.
      /// If class can't be mapped, method raise exception.</summary>
      function MapClass(ClassToMap : TClass) : TClass;
      destructor Destroy; override;
  end;

var
  GfxApiClassMapper : TGfxApiClassMapper;

implementation

{ TGFXDClassMapper }

constructor TGfxApiClassMapper.Create(GFXDType : EnumGFXDType);
var
  i : integer;
begin
  FGFXDType := GFXDType;
  FClassMap := TDictionary<TClass, TClass>.Create;
  // fill map with data from constantarray against the GFXDType
  for i := 0 to Length(GFXDCLASSMAPPING[Ord(GFXDType)]) - 1 do
      FClassMap.Add(GFXDCLASSMAPPING[Ord(GFXDType)][i].FromClass, GFXDCLASSMAPPING[Ord(GFXDType)][i].ToClass);
end;

destructor TGfxApiClassMapper.Destroy;
begin
  FClassMap.Free;
  inherited;
end;

function TGfxApiClassMapper.MapClass(ClassToMap : TClass) : TClass;
begin
  if not FClassMap.ContainsKey(ClassToMap) then raise EGfxApiExistNonMapping.Create('TGfxApiClassMapper.MapClass: For class "' + ClassToMap.ClassName + '" exists no Mapping.');
  Result := FClassMap[ClassToMap];
end;

end.
