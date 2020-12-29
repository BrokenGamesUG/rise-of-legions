unit Engine.Core.Types;

interface

uses
  Generics.Collections,
  RTTI,
  Math,
  SysUtils,
  Engine.GFXApi,
  Engine.GFXApi.Types,
  Engine.Helferlein,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Serializer.Types,
  Engine.Serializer;

type
  /// <summary> A set of these flags choose the spezific Defaultshader </summary>
  EnumDefaultShaderFlags = (sfDiffuseTexture, sfNormalmapping, sfMaterial, sfMaterialTexture,
    sfSkinning, sfAlphamap, sfAlphamapTexCoords, sfVertexcolor, sfColorAdjustment, sfUseAlpha,
    sfAbsoluteColorAdjustment, sfRHW, sfShadowMapping, sfAlphaTest, sfColorReplacement,
    sfTextureTransform, sfCullAdjustNormal, sfAllowLighting,
    sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawNormal, sfDeferredDrawMaterial,
    sfForceNormalmappingInput, sfForceSkinningInput, sfForceTexturecoordInput,
    sfMorphtarget1, sfMorphtarget2, sfMorphtarget3, sfMorphtarget4, sfMorphtarget5, sfMorphtarget6, sfMorphtarget7, sfMorphtarget8,
    // set by GFXD
    sfLighting, sfGBuffer);

  /// <summary> A set of EnumDefaultShaderFlags. GBuffer and Lighting are ignored and set by the GFXD </summary>
  SetDefaultShaderFlags = set of EnumDefaultShaderFlags;

const
  DEFAULT_SHADOW_SHADER_ALLOWED_FLAGS : SetDefaultShaderFlags = [
    sfDiffuseTexture, sfSkinning, sfAlphamap, sfAlphamapTexCoords, sfVertexcolor, sfAlphaTest, sfColorReplacement,
    sfTextureTransform, sfForceNormalmappingInput, sfForceSkinningInput, sfForceTexturecoordInput,
    sfMorphtarget1, sfMorphtarget2, sfMorphtarget3, sfMorphtarget4, sfMorphtarget5, sfMorphtarget6, sfMorphtarget7, sfMorphtarget8
    ];

type

  EnumShadowTechnique = (stNone, stShadowmapping, stStencil);

  EnumDrawnBoundings = (dbNone, dbSphere, dbBox);

  EnumRenderRequirements = (rrScene, rrLightbuffer, rrBlurredScene, rrGBuffer);
  SetRenderRequirements = set of EnumRenderRequirements;

  EnumCallbackTime = (
    ctNormal,
    ctBefore,
    ctAfter
    );

  /// <summary> All render categories, calls are not exactly in this order. </summary>
  EnumRenderStage = (
    rsNone,              // empty default value
    rsEnvironment,       // Skyboxes, etc. anything to paint a background
    rsZPass,             // renders all Z-Writing objects to the depthbuffer to use early z-rejection for pixelcomplex scenes
    rsShadow,            // all opaque shadow casting objects are rendered to the shadow map.
    rsTranslucentShadow, // all translucent shadow casting objects are rendered to the shadow map.
    rsWorld,             // Meshes, Terrain, etc. anything writing Z and receiving light
    rsWorldPostEffects,  // SSAO, Toon - everything on top of the world
    rsEffects,           // ParticleEffects, anything drawn over the scene
    rsOutline,           // Outlines of meshes
    rsPostEffects,       // UnsharpMasking, GaussBlur - everything on top of everything
    rsDistortion,        // Renders all objects, which are contributing to the screen distortion
    rsGlow,              // Renders all objects, which are contributing to the screen glow
    rsSceneBlur,         // Renders all objects, which are used for masking the scene blur, don't called if whole scene is blurred
    rsGUI                // GUI, anything drawn on top of everything else
    );

  SetRenderStage = set of EnumRenderStage;

const
  RENDER_STAGES_ALL = [low(EnumRenderStage) .. high(EnumRenderStage)];

type

  /// <summary> All events used by the GFXD to power up the engine-pipeline. </summary>
  EnumGFXDEvents = (
    // Pipeline Events ///////////////////////////////////////////////////////////////////////

    /// <summary> Thrown by the GFXD when it attempts to draw our scene. </summary>
    geFrameBegin,
    /// <summary> Thrown by the GFXD after finishing our scene. </summary>
    geFrameEnd,
    /// <summary> Called by the renderpipeline to draw the selected stage. Param0: EnumRenderOrder; Param1: TRenderContext;</summary>
    geDraw,
    /// <summary> Called from the shadowmaprenderer, to draw all fully opaque objects to the shadow map.
    /// Other classes can register on this and contribute their objects to the shadowmap, which is already
    /// set as rendertarget and needed renderstates are forced. </summary>
    geDrawOpaqueShadowmap,
    /// <summary> Called from the shadowmaprenderer, after worldobjects are drawn to the shadow map.
    /// Other classes can register on this and contribute their objects to the shadowmap, which is already
    /// set as rendertarget and needed renderstates are forced. </summary>
    geDrawTranslucentShadowmap,
    // Environment Events //////////////////////////////////////////////////////////////////////

    /// <summary> Called when backbuffer resolution is changed. Param1 : RIntVector2 - New resolution. </summary>
    geResolutionChanged
    );

const
  CALLBACK_ORDER : array [0 .. ord(high(EnumCallbackTime))] of EnumCallbackTime = (ctBefore, ctNormal, ctAfter);

  MAX_MORPH_TARGET            = sfMorphtarget8;
  MIN_MORPH_TARGET            = sfMorphtarget1;
  SET_MORPHTARGET_SHADERFLAGS = [sfMorphtarget1 .. sfMorphtarget8];
  MAX_MORPH_TARGET_COUNT      = 8;

type

  /// <summary>
  /// A screen-aligned Quad. Useful for Posteffects.
  /// </summary>
  TScreenQuad = class
    protected
      vertexbuffer : TVertexBuffer;
      FQuad : RRectFloat;
      /// <summary> Creates a screen-aligned Quad in pixelspace </summary>
      constructor Create(LinksOben, BreiteHöhe : RVector2; Pixelsize : RVector2); overload;
    public
      /// <summary> Creates a fullscreen-Quad. </summary>
      constructor Create(); overload;
      constructor Create(Resolution : RVector2); overload;
      constructor Create(RelativePosition, RelativeSize : RVector2); overload;
      constructor Create(Resolutiondivider : integer); overload;
      /// <summary> Draws the Quad. Shader should be set before. </summary>
      procedure Render;
      /// <summary> Frees the memory </summary>
      destructor Destroy; override;
      property ScreenRect : RRectFloat read FQuad;
  end;

implementation

uses
  Engine.Core,
  Engine.Vertex;

{ TScreenQuad }

constructor TScreenQuad.Create(LinksOben, BreiteHöhe : RVector2; Pixelsize : RVector2);
var
  vertices : array [0 .. 3] of RVertexPositionTexture;
  pVertices : Pointer;
begin
  FQuad := RRectFloat.CreateWidthHeight(LinksOben, BreiteHöhe);
  vertexbuffer := TVertexBuffer.CreateVertexBuffer(sizeof(RVertexPositionTexture) * 4, [usWriteable], GFXD.Device3D);
  vertices[0].Position := RVector3.Create(LinksOben.x, -LinksOben.y, 0);
  vertices[0].TextureCoordinate := RVector2.Create(0, 0);
  vertices[1].Position := RVector3.Create(LinksOben.x + BreiteHöhe.x, -LinksOben.y, 0);
  vertices[1].TextureCoordinate := RVector2.Create(1, 0);
  vertices[2].Position := RVector3.Create(LinksOben.x, -LinksOben.y - BreiteHöhe.y, 0);
  vertices[2].TextureCoordinate := RVector2.Create(0, 1);
  vertices[3].Position := RVector3.Create(LinksOben.x + BreiteHöhe.x, -LinksOben.y - BreiteHöhe.y, 0);
  vertices[3].TextureCoordinate := RVector2.Create(1, 1);

  pVertices := vertexbuffer.LowLock;
  move(vertices, pVertices^, sizeof(vertices));
  vertexbuffer.Unlock;
end;

constructor TScreenQuad.Create();
begin
  Create(1);
end;

constructor TScreenQuad.Create(Resolutiondivider : integer);
begin
  assert(Resolutiondivider > 0);
  Create(RVector2.Create(-1, -1), RVector2.Create(2, 2), Resolutiondivider / GFXD.Settings.Resolution.Size.ToRVector);
end;

constructor TScreenQuad.Create(Resolution : RVector2);
begin
  Create(RVector2.Create(-1, -1), RVector2.Create(2, 2), 1 / Resolution);
end;

constructor TScreenQuad.Create(RelativePosition, RelativeSize : RVector2);
begin
  Create((RelativePosition * 2) - 1, RelativeSize * 2, 1 / GFXD.Settings.Resolution.Size.ToRVector);
end;

destructor TScreenQuad.Destroy;
begin
  vertexbuffer.Free;
end;

procedure TScreenQuad.Render;
begin
  GFXD.Device3D.SetRenderState(rsCULLMODE, cmNone);
  GFXD.Device3D.SetRenderState(rsZENABLE, False);
  GFXD.Device3D.SetStreamSource(0, vertexbuffer, 0, sizeof(RVertexPositionTexture));
  GFXD.Device3D.SetVertexDeclaration(RVertexPositionTexture.BuildVertexdeclaration());
  GFXD.Device3D.DrawPrimitive(ptTrianglestrip, 0, 2);
  GFXD.Device3D.ClearRenderState();
end;

end.
