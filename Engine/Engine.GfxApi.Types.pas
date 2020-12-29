unit Engine.GfxApi.Types;

interface


uses
  System.Hash,
  Engine.Math,
  Engine.Helferlein,
  Windows,
  SysUtils;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  EGfxApiException = class(Exception);

  EnumFillMode = (fmPoint = 1, fmWireframe, fmSolid);
  EnumRenderstate = (
    rsNULLRENDERSTATE = 0,
    rsZENABLE = 7,
    rsFILLMODE = 8,
    rsSHADEMODE = 9,
    rsZWRITEENABLE = 14,
    rsALPHATESTENABLE = 15,
    rsLASTPIXEL = 16,
    rsSRCBLEND = 19,
    rsDESTBLEND = 20,
    rsCULLMODE = 22,
    rsZFUNC = 23,
    rsALPHAREF = 24,
    rsALPHAFUNC = 25,
    rsDITHERENABLE = 26,
    rsALPHABLENDENABLE = 27,
    rsFOGENABLE = 28,
    rsSPECULARENABLE = 29,
    rsFOGCOLOR = 34,
    rsFOGTABLEMODE = 35,
    rsFOGSTART = 36,
    rsFOGEND = 37,
    rsFOGDENSITY = 38,
    rsRANGEFOGENABLE = 48,
    rsSTENCILENABLE = 52,
    rsSTENCILFAIL = 53,
    rsSTENCILZFAIL = 54,
    rsSTENCILPASS = 55,
    rsSTENCILFUNC = 56,
    rsSTENCILREF = 57,
    rsSTENCILMASK = 58,
    rsSTENCILWRITEMASK = 59,
    rsTEXTUREFACTOR = 60,
    rsWRAP0 = 128,
    rsWRAP1 = 129,
    rsWRAP2 = 130,
    rsWRAP3 = 131,
    rsWRAP4 = 132,
    rsWRAP5 = 133,
    rsWRAP6 = 134,
    rsWRAP7 = 135,
    rsCLIPPING = 136,
    rsLIGHTING = 137,
    rsAMBIENT = 139,
    rsFOGVERTEXMODE = 140,
    rsCOLORVERTEX = 141,
    rsLOCALVIEWER = 142,
    rsNORMALIZENORMALS = 143,
    rsDIFFUSEMATERIALSOURCE = 145,
    rsSPECULARMATERIALSOURCE = 146,
    rsAMBIENTMATERIALSOURCE = 147,
    rsEMISSIVEMATERIALSOURCE = 148,
    rsVERTEXBLEND = 151,
    rsCLIPPLANEENABLE = 152,
    rsPOINTSIZE = 154,
    rsPOINTSIZE_MIN = 155,
    rsPOINTSPRITEENABLE = 156,
    rsPOINTSCALEENABLE = 157,
    rsPOINTSCALE_A = 158,
    rsPOINTSCALE_B = 159,
    rsPOINTSCALE_C = 160,
    rsMULTISAMPLEANTIALIAS = 161,
    rsMULTISAMPLEMASK = 162,
    rsPATCHEDGESTYLE = 163,
    rsDEBUGMONITORTOKEN = 165,
    rsPOINTSIZE_MAX = 166,
    rsINDEXEDVERTEXBLENDENABLE = 167,
    rsCOLORWRITEENABLE = 168,
    rsTWEENFACTOR = 170,
    rsBLENDOP = 171,
    rsPOSITIONDEGREE = 172,
    rsNORMALDEGREE = 173,
    rsSCISSORTESTENABLE = 174,
    rsSLOPESCALEDEPTHBIAS = 175,
    rsANTIALIASEDLINEENABLE = 176,
    rsMINTESSELLATIONLEVEL = 178,
    rsMAXTESSELLATIONLEVEL = 179,
    rsADAPTIVETESS_X = 180,
    rsADAPTIVETESS_Y = 181,
    rsADAPTIVETESS_Z = 182,
    rsADAPTIVETESS_W = 183,
    rsENABLEADAPTIVETESSELLATION = 184,
    rsTWOSIDEDSTENCILMODE = 185,
    rsCCW_STENCILFAIL = 186,
    rsCCW_STENCILZFAIL = 187,
    rsCCW_STENCILPASS = 188,
    rsCCW_STENCILFUNC = 189,
    rsCOLORWRITEENABLE1 = 190,
    rsCOLORWRITEENABLE2 = 191,
    rsCOLORWRITEENABLE3 = 192,
    rsBLENDFACTOR = 193,
    rsSRGBWRITEENABLE = 194,
    rsDEPTHBIAS = 195,
    rsWRAP8 = 198,
    rsWRAP9 = 199,
    rsWRAP10 = 200,
    rsWRAP11 = 201,
    rsWRAP12 = 202,
    rsWRAP13 = 203,
    rsWRAP14 = 204,
    rsWRAP15 = 205,
    rsSEPARATEALPHABLENDENABLE = 206,
    rsSRCBLENDALPHA = 207,
    rsDESTBLENDALPHA = 208,
    rsBLENDOPALPHA = 209
    );

  EnumTextureFormat = (
    tfUNKNOWN = 0,
    tfR8G8B8 = 20,
    tfA8R8G8B8 = 21,
    tfX8R8G8B8 = 22,
    tfR5G6B5 = 23,
    tfX1R5G5B5 = 24,
    tfA1R5G5B5 = 25,
    tfA4R4G4B4 = 26,
    tfR3G3B2 = 27,
    tfA8 = 28,
    tfA8R3G3B2 = 29,
    tfX4R4G4B4 = 30,
    tfA2B10G10R10 = 31,
    tfA8B8G8R8 = 32,
    tfX8B8G8R8 = 33,
    tfG16R16 = 34,
    tfA2R10G10B10 = 35,
    tfA16B16G16R16 = 36,
    tfA8P8 = 40,
    tfP8 = 41,
    tfL8 = 50,
    tfA8L8 = 51,
    tfA4L4 = 52,
    tfV8U8 = 60,
    tfL6V5U5 = 61,
    tfX8L8V8U8 = 62,
    tfQ8W8V8U8 = 63,
    tfV16U16 = 64,
    tfA2W10V10U10 = 67,
    tfA8X8V8U8 = 68,
    tfL8X8V8U8 = 69,
    tfUYVY = Byte('U') or (Byte('Y') shl 8) or (Byte('V') shl 16) or (Byte('Y') shl 24),
    tfRGBG = Byte('R') or (Byte('G') shl 8) or (Byte('B') shl 16) or (Byte('G') shl 24),
    tfYUY2 = Byte('Y') or (Byte('U') shl 8) or (Byte('Y') shl 16) or (Byte('2') shl 24),
    tfGRGB = Byte('G') or (Byte('R') shl 8) or (Byte('G') shl 16) or (Byte('B') shl 24),
    tfDXT1 = Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('1') shl 24),
    tfDXT2 = Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('2') shl 24),
    tfDXT3 = Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('3') shl 24),
    tfDXT4 = Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('4') shl 24),
    tfDXT5 = Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('5') shl 24),
    tfD16_LOCKABLE = 70,
    tfD32 = 71,
    tfD15S1 = 73,
    tfD24S8 = 75,
    tfD24X8 = 77,
    tfD24X4S4 = 79,
    tfD16 = 80,
    tfD32F_LOCKABLE = 82,
    tfD24FS8 = 83,
    tfL16 = 81,
    tfVERTEXDATA = 100,
    tfQ16W16V16U16 = 110,
    tfMULTI2_ARGB8 = Byte('M') or (Byte('E') shl 8) or (Byte('T') shl 16) or (Byte('1') shl 24),
    tfR16F = 111,
    tfG16R16F = 112,
    tfA16B16G16R16F = 113,
    tfR32F = 114,
    tfG32R32F = 115,
    tfA32B32G32R32F = 116,
    tfCxV8U8 = 117,
    tfFORCE_DWORD = $7FFFFFFF
    );

type
  EnumTextureFileType = (tfTGA, tfPNG, tfJPG);

  EnumIndexBufferFormat = (ifINDEX16 = 101, ifINDEX32 = 102);

  EnumShaderType = (stVertexShader, stGeometryShader, stPixelShader);

  EnumTextureFilter = (tfAuto, tfPoint, tfLinear, tfAnisotropic);
  EnumTexturAddressMode = (amWrap = 1, amMirror, amClamp, amBorder, amMirrorOnce);

  EnumCullmode = (cmNone, cmCW, cmCCW);
  EnumBlend = (blZero = 1, blOne, blSrcColor, blInvSrcColor, blSrcAlpha, blInvSrcAlpha, blDestAlpha, blInvDestAlpha, blDestColor, blInvDestColor, blSrcAlphaSat, blBlendfactor = ord(blSrcAlphaSat) + 3);
  EnumBlendOp = (boAdd = 1, boSubtract, boRevSubtract, boMin, boMax);
  EnumCompareOperator = (coNever = 1, coLess, coEqual, coLessEqual, coGreater, coNotEqual, coGreaterEqual, coAlways);
  EnumStencilOperator = (soKeep = 1, soZero, soReplace, soIncrSat, soDecrSat, soInvert, soIncr, soDecr);
  EnumPrimitveType = (ptPointlist = 1, ptLinelist, ptLinestrip, ptTrianglelist, ptTrianglestrip);
  EnumClearFlags = (cfTarget, cfZBuffer, cfStencil);
  SetClearFlags = set of EnumClearFlags;
  EnumLockFlag = (lfReadOnly, lfDiscard, lfNoOverwrite);
  SetLockFlags = set of EnumLockFlag;

  /// <summary> Resource can be
  /// usReadable - Read from (worst performance)
  /// usWriteable - Written to less than once per frame (same performance as unwriteable buffer if not updates)
  /// usFrequentlyWriteable - Written to more than once per frame (CPU can write fast, but GPU can read slower)
  /// usRendertarget - Only for textures, texture can be used as rendertarget, other usages are invalid in this case
  /// </summary>
  EnumUsage = (usReadable, usWriteable, usFrequentlyWriteable, usRendertarget);
  SetUsage = set of EnumUsage;

  EnumAntialiasingLevel = (aaNone, aa2x, aa4x, aaEdge);
  EnumVertexElementType = (etFloat1, etFloat2, etFloat3, etFloat4, etUnused);
  EnumVertexElementUsage = (euPosition, euNormal, euColor, euTexturecoordinate, euTangent, euBinormal, euBlendWeight, euBlendIndices);
  EnumVertexElementMethod = (emDefault);
  EnumFontQuality = (fqDefault, fqDraft, fqProof, fqNonAntiAliased, fqAntiAliased, fqClearType, fqClearTypeNatural);
  EnumFontRenderingFlag = (ffLeft, ffCenter, ffRight, ffTop, ffVerticalCenter, ffBottom, ffWordWrap, ffSingleLine, ffExpandTabs, ffTabstop, ffNoClip, ffAutoShrink);
  SetFontRenderingFlags = set of EnumFontRenderingFlag;
  EnumShaderBlockMode = (sbNone, sbWhiteList, sbBlackList);

  EnumGFXDType = (DirectX9Device, DirectX11Device, OpenGLDevice);

  TInitialState = record
    Renderstate : EnumRenderstate;
    Value : Cardinal;
  end;

  TRenderState = class
    Renderstate : EnumRenderstate;
    Value, UrValue : Cardinal;
    Forciert : boolean;
    constructor Create(Renderstate : EnumRenderstate; Value, UrValue : Cardinal; Forciert : boolean = False);
  end;

  RFontBorder = record
    Color : RColor;
    Width : single;
    function Hash : integer;
    class operator equal(a, b : RFontBorder) : boolean;
    class operator notequal(a, b : RFontBorder) : boolean;
  end;

  EnumFontStyle = (fsNormal, fsItalic, fsOblique);
  EnumFontWeight = (fwThin, fwUltraLight, fwLight, fwSemiLight, fwRegular, fwMedium, fwSemibold, fwBold, fwUltraBold, fwBlack, fwUltraBlack);
  EnumFontStretch = (fsUltraCondensed, fsExtraCondensed, fsCondensed, fsSemiCondensed, fsRegular, fsSemiExpanded, fsExpanded, fsExtraExpanded, fsUltraExpanded);

  RFontProperties = record
    Weight : EnumFontWeight;
    Stretch : EnumFontStretch;
    Style : EnumFontStyle;
    Quality : EnumFontQuality;
  end;

  RFontDescription = record
    strict private
      function ComparableHeight : integer;
    public
      Height : single;
      Properties : RFontProperties;
      FontFamily : string;
      property Weight : EnumFontWeight read Properties.Weight write Properties.Weight;
      property Stretch : EnumFontStretch read Properties.Stretch write Properties.Stretch;
      property Style : EnumFontStyle read Properties.Style write Properties.Style;
      property Quality : EnumFontQuality read Properties.Quality write Properties.Quality;
      constructor Create(FontName : string);
      function Hash : integer;
      class operator equal(a, b : RFontDescription) : boolean;
      class operator notequal(a, b : RFontDescription) : boolean;
  end;

  RSamplerstate = record
    Filter : EnumTextureFilter;
    MipMapLodBias : single;
    AddressMode : EnumTexturAddressMode;
    class operator equal(L, R : RSamplerstate) : boolean;
  end;

  EnumDefaultShaderConstant = (
    // globals
    dcView, dcProjection, dcDirectionalLightDir, dcDirectionalLightColor, dcAmbient, dcCameraPosition,
    dcCameraUp, dcCameraLeft, dcCameraDirection, dcViewportSize, dcLightPosition,
    // shadowmapping
    dcShadowView, dcShadowProj, dcShadowcameraPosition, dcShadowbias, dcSlopebias, dcShadowpixelwidth, dcShadowStrength,
    // default shader
    dcWorld, dcWorldInverseTranspose, dcSpecularpower, dcSpecularintensity, dcSpeculartint, dcShadingReduction, dcAlpha, dcAlphaTestRef,
    dcHSVOffset, dcAbsoluteHSV, dcReplacementColor, dcTextureOffset, dcTextureScale, dcMorphweights,
    dcBoneTransforms);

  SetDefaultShaderConstant = set of EnumDefaultShaderConstant;

const

  DEFAULT_SHADER_CONSTANT_MAPPING : array [EnumDefaultShaderConstant] of string = (
    'View', 'Projection', 'DirectionalLightDir', 'DirectionalLightColor', 'Ambient', 'CameraPosition',
    'CameraUp', 'CameraLeft', 'CameraDirection', 'viewport_size', 'LightPosition',
    // shadowmapping
    'ShadowView', 'ShadowProj', 'ShadowcameraPosition', 'Shadowbias', 'Slopebias', 'Shadowpixelwidth', 'ShadowStrength',
    // default shader
    'World', 'WorldInverseTranspose', 'Specularpower', 'Specularintensity', 'Speculartint', 'Shadingreduction', 'Alpha', 'AlphaTestRef',
    'HSVOffset', 'AbsoluteHSV', 'ReplacementColor', 'TextureOffset', 'TextureScale', 'Morphweights',
    'BoneTransforms'
    );

  DEFAULTCAMERANAH         = 1;
  DEFAULTCAMERAFERN        = 10000;
  DEFAULTCAMERAFOVY        = 3.141592654 / 4;
  DEFAULTSPECULARPOWER     = 128;
  DEFAULTSPECULARINTENSITY = 1.0;

type

  EnumTextureSlot = (
    tsColor, tsNormal, tsMaterial, tsVariable1, tsVariable2, tsVariable3, tsVariable4
    );

  SetTextureSlot = set of EnumTextureSlot;

const

  TEXTURE_SLOT_MAPPING : array [EnumTextureSlot] of string = (
    'ColorTexture',
    'NormalTexture',
    'MaterialTexture',
    'VariableTexture1',
    'VariableTexture2',
    'VariableTexture3',
    'VariableTexture4'
    );

  // RenderStates die beim initialisieren der Grafikkarte gesetzt werden, diese gelten dann auch als UrValuee
  // wenn die RenderStates wieder zurückgesetzt werden
  INITALRENDERSTATS : array [0 .. 5] of TInitialState =
    (
    (Renderstate : rsAMBIENT; Value : $303030),
    (Renderstate : rsZENABLE; Value : 1),
    (Renderstate : rsLIGHTING; Value : 1),
    (Renderstate : rsSRCBLEND; Value : ord(blSrcAlpha)),
    (Renderstate : rsDESTBLEND; Value : ord(blInvSrcAlpha)),
    (Renderstate : rsALPHABLENDENABLE; Value : 0)
    );

  STDAMBIENT : Cardinal          = $30FFFFFF;
  STDHINTERGRUNDFARBE : Cardinal = $00505050;

  DEFAULT_SHADER        = 'Standardshader.fx';
  DEFAULT_SHADOW_SHADER = 'ShadowMapZShader.fx';

  STANDARDSHADERDIFFUSETEXTURE             = '#define DIFFUSETEXTURE' + sLineBreak;
  STANDARDSHADERLIGHTING                   = '#define LIGHTING' + sLineBreak;
  STANDARDSHADERNORMALMAPPING              = '#define NORMALMAPPING' + sLineBreak;
  STANDARDSHADER_MATERIAL                  = '#define MATERIAL' + sLineBreak;
  STANDARDSHADER_MATERIAL_TEXTURE          = '#define MATERIALTEXTURE' + sLineBreak;
  STANDARDSHADERGBUFFER                    = '#define GBUFFER' + sLineBreak;
  STANDARDSHADERSKINNING                   = '#define SKINNING' + sLineBreak;
  STANDARDSHADERALPHAMAP                   = '#define ALPHAMAP' + sLineBreak;
  STANDARDSHADER_ALPHAMAP_TEXCOORDS        = '#define ALPHAMAP_TEXCOORDS' + sLineBreak;
  STANDARDSHADERVERTEXCOLOR                = '#define VERTEXCOLOR' + sLineBreak;
  STANDARDSHADERCOLORADJUSTMENT            = '#define COLORADJUSTMENT' + sLineBreak;
  STANDARDSHADERABSOLUTECOLORADJUSTMENT    = '#define ABSOLUTECOLORADJUSTMENT' + sLineBreak;
  STANDARDSHADERRHW                        = '#define RHW' + sLineBreak;
  STANDARDSHADERSHADOWMAPPING              = '#define SHADOWMAPPING' + sLineBreak;
  STANDARDSHADERUSEALPHA                   = '#define ALPHA' + sLineBreak;
  STANDARDSHADERALPHATEST                  = '#define ALPHATEST' + sLineBreak;
  STANDARDSHADERDISABLEMIPMAPPING          = '#define DISABLEMIPMAPPING' + sLineBreak;
  STANDARDSHADERTEXTURETRANSFORMS          = '#define TEXTURETRANSFORM' + sLineBreak;
  STANDARDSHADERCULLNONE                   = '#define CULLNONE' + sLineBreak;
  STANDARDSHADER_DRAW_COLOR                = '#define DRAW_COLOR' + sLineBreak;
  STANDARDSHADER_DRAW_POSITION             = '#define DRAW_POSITION' + sLineBreak;
  STANDARDSHADER_DRAW_NORMAL               = '#define DRAW_NORMAL' + sLineBreak;
  STANDARDSHADER_DRAW_MATERIAL             = '#define DRAW_MATERIAL' + sLineBreak;
  STANDARDSHADER_FORCE_NORMALMAPPING_INPUT = '#define FORCE_NORMALMAPPING_INPUT' + sLineBreak;
  STANDARDSHADER_FORCE_TEXTURECOORD_INPUT  = '#define FORCE_TEXCOORD_INPUT' + sLineBreak;
  STANDARDSHADER_FORCE_SKINNING_INPUT      = '#define FORCE_SKINNING_INPUT' + sLineBreak;
  STANDARDSHADER_USE_MORPH                 = '#define MORPH' + sLineBreak;
  STANDARDSHADER_MORPH_COUNT               = '#define MORPH_COUNT %d' + sLineBreak;
  STANDARDSHADER_COLOR_REPLACEMENT         = '#define COLOR_REPLACEMENT' + sLineBreak;

  CDEFAULT        = Cardinal(-1);
  CDEFAULTNONPOW2 = Cardinal(-2);

  DEFAULT_TECHNIQUE_NAME = 'MegaTec';

type

  TIndexedVertexDataCollector<VertexType, IndexType> = class
    protected
      FVertexData, FVertexDataCursor, FIndexData, FIndexDataCursor : Pointer;
      FVertexDataSize, FVertexCount, FIndexDataSize, FIndexCount : integer;
    public
      constructor Create(const VertexSize, IndexSize : integer);

      property VertexData : Pointer read FVertexData;
      property VertexDataSize : integer read FVertexDataSize;

      procedure PushVertex(const Value : VertexType);
      property TotalPushedVertexCount : integer read FVertexCount;

      property IndexData : Pointer read FIndexData;
      property IndexDataSize : integer read FIndexDataSize;

      procedure PushIndex(const Value : IndexType);
      property TotalPushedIndexCount : integer read FIndexCount;

      destructor Destroy; override;
  end;

  /// <summary> Return pixelsize in bytes for given pixelformat. If size is unknown, will return -1</summary>
function GetPixelSize(Pixelformat : EnumTextureFormat) : integer;
function ConvertFontWeight(Weight : integer) : EnumFontWeight;
function ConvertFontStretch(Stretch : integer) : EnumFontStretch;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

function ConvertFontWeight(Weight : integer) : EnumFontWeight;
begin
  if Weight < 100 then Result := fwThin
  else if Weight < 200 then Result := fwUltraLight
  else if Weight < 300 then Result := fwLight
  else if Weight < 400 then Result := fwSemiLight
  else if Weight < 500 then Result := fwRegular
  else if Weight < 600 then Result := fwMedium
  else if Weight < 700 then Result := fwSemibold
  else if Weight < 800 then Result := fwBold
  else if Weight < 900 then Result := fwUltraBold
  else if Weight < 1000 then Result := fwBlack
  else Result := fwUltraBlack;
end;

function ConvertFontStretch(Stretch : integer) : EnumFontStretch;
begin
  if Stretch < 100 then Result := fsUltraCondensed
  else if Stretch < 200 then Result := fsExtraCondensed
  else if Stretch < 300 then Result := fsCondensed
  else if Stretch < 400 then Result := fsSemiCondensed
  else if Stretch < 500 then Result := fsRegular
  else if Stretch < 600 then Result := fsSemiExpanded
  else if Stretch < 700 then Result := fsExpanded
  else if Stretch < 800 then Result := fsExtraExpanded
  else Result := fsUltraExpanded
end;

function GetPixelSize(Pixelformat : EnumTextureFormat) : integer;
begin
  Result := -1;
  case Pixelformat of
    tfUNKNOWN : Result := -1;
    tfR8G8B8 : Result := 3;
    tfA8R8G8B8 : Result := 4;
    tfX8R8G8B8 : Result := 4;
    tfR5G6B5 : Result := 2;
    tfX1R5G5B5 : Result := 2;
    tfA1R5G5B5 : Result := 2;
    tfA4R4G4B4 : Result := 2;
    tfR3G3B2 :;
    tfA8 :;
    tfA8R3G3B2 :;
    tfX4R4G4B4 :;
    tfA2B10G10R10 :;
    tfA8B8G8R8 :;
    tfX8B8G8R8 :;
    tfG16R16 :;
    tfA2R10G10B10 :;
    tfA16B16G16R16 :;
    tfA8P8 :;
    tfP8 :;
    tfL8 :;
    tfA8L8 :;
    tfA4L4 :;
    tfV8U8 :;
    tfL6V5U5 :;
    tfX8L8V8U8 :;
    tfQ8W8V8U8 :;
    tfV16U16 :;
    tfA2W10V10U10 :;
    tfA8X8V8U8 :;
    tfL8X8V8U8 :;
    tfUYVY :;
    tfRGBG :;
    tfYUY2 :;
    tfGRGB :;
    tfDXT1 : Result := -1;
    tfDXT2 : Result := -1;
    tfDXT3 : Result := -1;
    tfDXT4 : Result := -1;
    tfDXT5 : Result := -1;
    tfD16_LOCKABLE : Result := 2;
    tfD32 : Result := 4;
    tfD15S1 : Result := 2;
    tfD24S8 : Result := 4;
    tfD24X8 : Result := 4;
    tfD24X4S4 : Result := 4;
    tfD16 : Result := 2;
    tfD32F_LOCKABLE : Result := 4;
    tfD24FS8 : Result := 4;
    tfL16 : Result := 2;
    tfVERTEXDATA : Result := -1;
    tfQ16W16V16U16 : Result := 8;
    tfMULTI2_ARGB8 : Result := -1;
    tfR16F : Result := 2;
    tfG16R16F : Result := 4;
    tfA16B16G16R16F : Result := 8;
    tfR32F : Result := 4;
    tfG32R32F : Result := 8;
    tfA32B32G32R32F : Result := 16;
    tfCxV8U8 : Result := 2;
    tfFORCE_DWORD : Result := -1;
  end;
end;

{ RFontDescription }

function RFontDescription.ComparableHeight : integer;
begin
  Result := round(self.Height * 100);
end;

constructor RFontDescription.Create(FontName : string);
begin
  self.Height := 24;
  self.Properties.Weight := fwRegular;
  self.Properties.Style := fsNormal;
  self.Properties.Quality := fqAntiAliased;
  self.Properties.Stretch := fsRegular;
  self.FontFamily := FontName;
end;

class operator RFontDescription.equal(a, b : RFontDescription) : boolean;
begin
  Result := (a.ComparableHeight = b.ComparableHeight) and
    CompareMem(@a.Properties, @b.Properties, SizeOf(RFontProperties)) and
    (a.FontFamily = b.FontFamily);
end;

function RFontDescription.Hash : integer;
var
  temp : integer;
begin
  temp := ComparableHeight;
  Result := THashBobJenkins.GetHashValue(temp, SizeOf(integer)) xor
    THashBobJenkins.GetHashValue(self.FontFamily) xor
    THashBobJenkins.GetHashValue(self.Properties, SizeOf(RFontProperties));
end;

class operator RFontDescription.notequal(a, b : RFontDescription) : boolean;
begin
  Result := not(a = b);
end;

{ TRenderState }

constructor TRenderState.Create(Renderstate : EnumRenderstate; Value, UrValue : Cardinal; Forciert : boolean = False);
begin
  self.Renderstate := Renderstate;
  self.Value := Value;
  self.UrValue := UrValue;
  self.Forciert := Forciert;
end;

{ RSamplerstate }

class operator RSamplerstate.equal(L, R : RSamplerstate) : boolean;
begin
  Result := (L.Filter = R.Filter) and
    (L.AddressMode = R.AddressMode) and (abs(L.MipMapLodBias - R.MipMapLodBias) < SINGLE_ZERO_EPSILON);
end;

{ RFontBorder }

class operator RFontBorder.equal(a, b : RFontBorder) : boolean;
begin
  Result := (a.Color = b.Color) and (a.Width = b.Width);
end;

function RFontBorder.Hash : integer;
begin
  Result := THashBobJenkins.GetHashValue(self, SizeOf(RFontBorder));
end;

class operator RFontBorder.notequal(a, b : RFontBorder) : boolean;
begin
  Result := (a.Color <> b.Color) or (a.Width <> b.Width);
end;

{ TIndexedVertexDataCollector }

constructor TIndexedVertexDataCollector<VertexType, IndexType>.Create(const VertexSize, IndexSize : integer);
begin
  FVertexDataSize := VertexSize;
  GetMem(FVertexData, VertexSize);
  FVertexDataCursor := FVertexData;

  FIndexDataSize := IndexSize;
  GetMem(FIndexData, IndexSize);
  FIndexDataCursor := FIndexData;
end;

destructor TIndexedVertexDataCollector<VertexType, IndexType>.Destroy;
begin
  FreeMem(VertexData, VertexDataSize);
  FreeMem(IndexData, IndexDataSize);
  inherited;
end;

procedure TIndexedVertexDataCollector<VertexType, IndexType>.PushVertex(const Value : VertexType);
type
  PVertexType = ^VertexType;
begin
  PVertexType(FVertexDataCursor)^ := Value;
  inc(PVertexType(FVertexDataCursor));
  inc(FVertexCount);
end;

procedure TIndexedVertexDataCollector<VertexType, IndexType>.PushIndex(const Value : IndexType);
type
  PIndexType = ^IndexType;
begin
  PIndexType(FIndexDataCursor)^ := Value;
  inc(PIndexType(FIndexDataCursor));
  inc(FIndexCount);
end;

end.
