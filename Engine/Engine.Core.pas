unit Engine.Core;

interface

uses
  // ========= Delphi =========
  System.Math,
  System.Rtti,
  System.SyncObjs,
  System.SysUtils,
  System.Variants,
  System.StrUtils,
  System.Threading,
  System.Generics.Collections,
  // ========= Third-Party =====
  WinApi.Windows,
  // ========= Engine ========
  Engine.Log,
  Engine.Math,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.GfxApi.Classmapper,
  Engine.Serializer,
  Engine.Serializer.Types,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Core.Camera,
  Engine.Core.Types,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,

  Engine.Core.Lights;

type
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  TGFXD = class;
  TRenderContext = class;
  TRenderManager = class;
  TFullscreenRendertarget = class;

  /// <summary> Deferred Shading Shader (Lighting) </summary>
  TDeferredShading = class
    protected
      type
      RPointlightVertex = packed record
        Position : RVector3;
        diffuse : RVector4;
        Center : RVector3;
        Range : RVector3;
      end;

      RSpotlightVertex = packed record
        Position, Direction, Sourceposition : RVector3;
        Color : RVector4;
        Range, Theta, Phi : Single;
      end;
    var
      Shader, ShadowDirectionalShader, Pointshader, LBShader, LBPointshader, Spotshader, LBSpotshader : TShader;
      ScreenQuad : TScreenQuad;
      pointvertices, negativepointvertices : TList<RPointlightVertex>;
      spotvertices : TList<RSpotlightVertex>;
      pointvertexbuffer, negativepointvertexbuffer, spotvertexbuffer : TVertexBufferList;
      pointvertexdeclaration, spotvertexdeclaration : TVertexdeclaration;
      procedure AddLightToVertices(Light : TLight; RenderContext : TRenderContext);
      procedure AddPointLightToVertices(Light : TPointlight; RenderContext : TRenderContext);
      procedure AddSpotLightToVertices(Light : TSpotlight; RenderContext : TRenderContext);
      procedure SetUpVertexbuffer(RenderContext : TRenderContext);
      procedure Render(RenderContext : TRenderContext); virtual;
    public
      RenderLightBuffer : boolean;
      ShadowMask : TTexture;
      constructor Create();
      destructor Destroy; override;
  end;

  /// <summary> Simply to rendering the scene as texture to the backbuffer. </summary>
  TSceneToBackbuffer = class
    protected
      Shader : TShader;
      ScreenQuad : TScreenQuad;
    public
      /// <summary> Determines whether the Effect will be applied or not </summary>
      Enabled : boolean;
      /// <summary> Creates a posteffect with a name, which can be used to get the effect from the GFXD later. If GFXD = nil then the default GFXD is used </summary>
      constructor Create();
      constructor CreateWithAlpha;
      procedure Render(Scene : TTexture; RenderContext : TRenderContext);
      destructor Destroy; override;
  end;

  TShadowMapping = class
    protected
      FRenderManager : TRenderManager;
      FMask : TFullscreenRendertarget;
      FShadowMapShader, FShadowMaskShader : TShader;
      FScreenQuad : TScreenQuad;
      FShadowCamera : TCamera;
      FDepthSave : TDepthStencilBuffer;
      FShadowMap : TTexture;
      FShadowSamplingRange : integer;
      SceneBoundings : RAABB;
      UseShadowCamera : boolean;
      constructor Create(RenderManager : TRenderManager);
      procedure RenderShadowMap();
      procedure RenderMask();
      function GetResolution : integer;
      procedure SetResolution(const Resolution : integer);
      procedure SetShadowSamplingRange(const ssr : integer);
    public
      Shadowbias, Slopebias : Single;
      Enabled : boolean;
      Strength : Single;
      /// <summary> Ignores all geometry below this value on the y-axis for computation of the perfect fitting shadow volume.
      /// Useful for aerial perspective games with a 2D-Gameplay. </summary>
      ClipBelow, ClipAbove : Single;
      TweakZoom : Single;
      property ShadowCamera : TCamera read FShadowCamera;
      property Resolution : integer read GetResolution write SetResolution;
      property ShadowSamplingRange : integer read FShadowSamplingRange write SetShadowSamplingRange;
      /// <summary> RGBA - (StartingDistance, EndDistance, Occlusion at EndDistance, unused) </summary>
      property ShadowMap : TTexture read FShadowMap;
      destructor Destroy; override;
  end;

  /// <summary> Callback method for event.</summary>
  /// <param name="Eventname"> Event with name has occured</param>
  /// <param name="Eventparameters"> Parameter for event. Type is variable</param>
  /// <param name="Pass"> Default value is true. If Value is changed to false, no other
  /// registered method will be called after this.</param>
  ProcGFXDEvent = procedure() of object;
  ProcGFXDEventWithEvent = procedure(EventIdentifier : EnumGFXDEvents) of object;
  ProcGFXDDrawEvent = procedure(RenderContext : TRenderContext) of object;
  ProcGFXDDrawEventWithStage = procedure(EventIdentifier : EnumRenderStage; RenderContext : TRenderContext) of object;
  ProcGFXDCustomEvent = procedure(Eventparameters : array of TValue) of object;

  TGFXDEventCallbacks = class
    Parameterless : TList<ProcGFXDEvent>;
    WithEvent : TList<ProcGFXDEventWithEvent>;
    WithRenderContext : TList<ProcGFXDDrawEvent>;
    WithRenderContextAndIdentifier : TList<ProcGFXDDrawEventWithStage>;
    CustomEvent : TList<ProcGFXDCustomEvent>;
    constructor Create;
    destructor Destroy; override;
  end;

  TGFXDEventInformation = TObjectDictionary<EnumCallbackTime, TGFXDEventCallbacks>;

  /// <summary> The GFXDs eventsystem, which calls all registered callbacks to a given Event.
  /// ATTENTION: While processing an event, no subscriber is allowed to unsubscribe! Mächtig badabumm sonst! </summary>
  TGFXDEventManager = class
    protected
      FCallbacks : TObjectDictionary<EnumGFXDEvents, TGFXDEventInformation>;
      procedure Subscribe<T>(Eventname : EnumGFXDEvents; proc : T; CallbackTime : EnumCallbackTime); overload;
      procedure Unsubscribe<T>(Eventname : EnumGFXDEvents; proc : T; CallbackTime : EnumCallbackTime); overload;
    public
      RenderContext : TRenderContext;
      constructor Create();
      /// <summary> Register the procedure to be called, if the event is set. If Eventname = '' then registered to all events. </summary>
      procedure Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEventWithEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEventWithStage; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDCustomEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      /// <summary> Deregister the procedure. </summary>
      procedure Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEventWithEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEventWithStage; CallbackTime : EnumCallbackTime = ctNormal); overload;
      procedure Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDCustomEvent; CallbackTime : EnumCallbackTime = ctNormal); overload;
      /// <summary> Set an event, so all registered callbacks are called immediately. </summary>
      procedure SetEvent(Eventname : EnumGFXDEvents); overload;
      procedure SetDrawEvent(Eventname : EnumRenderStage); overload;
      procedure SetEvent(Eventname : EnumGFXDEvents; CustomParameters : array of TValue); overload;
      destructor Destroy; override;
  end;

  /// <summary> Metaclass for all rendered things by the GFXD </summary>
  [XMLExcludeAll]
  TRenderable = class
    strict private
      FScene : TRenderManager;
      procedure SetCallbackTime(const Value : EnumCallbackTime);
    protected
      FVisible : boolean;
      FDrawnTriangles : integer;
      FDrawCalls : integer;
      FDrawsAtStage : SetRenderStage;
      FCallbackTime : EnumCallbackTime;
      property Scene : TRenderManager read FScene;
      function Requirements : SetRenderRequirements; virtual;
      function DrawsAtStage : SetRenderStage; virtual;
      procedure ResetDrawn;
      procedure setVisible(const Value : boolean);
      procedure Render(CurrentStage : EnumRenderStage; RenderContext : TRenderContext); virtual; abstract;
      procedure RenderCallback(EventIdentifier : EnumRenderStage; RenderContext : TRenderContext);
      constructor Create(Scene : TRenderManager; DrawsAtStage : SetRenderStage);
    public
      /// <summary> Determines whether this renderable will be rendered or not. </summary>
      property Visible : boolean read FVisible write setVisible;
      property DrawnTriangles : integer read FDrawnTriangles;
      property DrawCalls : integer read FDrawCalls;
      property RenderTime : EnumCallbackTime read FCallbackTime write SetCallbackTime;
      destructor Destroy; override;
  end;

  /// <summary> All rendering Stuff, which writes Z, such as Meshes, Terrain. Needs a position for sorting semi-transparent Objects </summary>
  TWorldObject = class(TRenderable)
    protected
      [XMLExcludeElement]
      FPosition : RVector3;
      /// <summary> If set to true, the engine knows to activate alpha testing for rendering the shadow map. </summary>
      [XMLExcludeElement]
      FUseAlphaTest : boolean;
      /// <summary> If set to false, the engine knows to use this for rendering the shadow map. </summary>
      [XMLExcludeElement]
      FCastsNoShadow : boolean;
      procedure SetPosition(const Value : RVector3); virtual;
      constructor Create(Scene : TRenderManager);
    public
      /// <summary> Worldposition </summary>
      [XMLExcludeElement]
      property Position : RVector3 read FPosition write SetPosition;
      [XMLExcludeElement]
      property CastsNoShadow : boolean read FCastsNoShadow write FCastsNoShadow;
      function GetBoundingBox() : RAABB; virtual; abstract;
      function GetBoundingSphere() : RSphere; virtual; abstract;
  end;

  TTextureBlur = class
    private
      FShader, FAdditiveShader, FBilateralShader, FAdditiveBilateralShader : TShader;
      FFullscreenQuad, FScreenQuad : TScreenQuad;
      FBlurredTexture1, FBlurredTexture2 : TFullscreenRendertarget;
      FResDiv, FKernelsize : integer;
      procedure SetResolutionDivider(const Value : integer);
      function GetResolutionDivider : integer;
      procedure SetKernelsize(const Value : integer);
    public
      AdditiveBlur, Bilateral, UseStencil, UseAlpha : boolean;
      Iterations : integer;
      SampleSpread, Intensity, Anamorphic : Single;
      BilateralRange, BilateralNormalbias : Single;
      RenderInput : boolean;
      property Kernelsize : integer read FKernelsize write SetKernelsize;
      property Resolutiondivider : integer read GetResolutionDivider write SetResolutionDivider;
      constructor Create();
      /// <summary> Renders the blurred texture to the current rendertarget. </summary>
      procedure RenderBlur(TextureToBeBlurred : TTexture; RenderContext : TRenderContext);
      procedure BuildDependencies(RenderContext : TRenderContext);
      procedure ReleaseDependencies;
      destructor Destroy; override;
  end;

  TSceneBlurManager = class
    protected
      FRenderManager : TRenderManager;
      FTextureBlur : TTextureBlur;
      procedure BeforeDrawBlur(Eventname : EnumRenderStage; RenderContext : TRenderContext);
    public
      property Blur : TTextureBlur read FTextureBlur;
      constructor Create(RenderManager : TRenderManager);
      destructor Destroy; override;
  end;

  TFullscreenRendertarget = class
    protected
      FOwner : TRenderContext;
      FResolutionDivider : integer;
      FTexture : TTexture;
    public
      property Texture : TTexture read FTexture;
      function AsRendertarget : TRendertarget;
      procedure ChangeResolution(const NewSize : RIntVector2);
      constructor Create(Owner : TRenderContext; Device : TDevice; Format : EnumTextureFormat; Resolutiondivider : integer);
      destructor Destroy; override;
  end;

  /// <summary> A composite of textures for Deferred Shading </summary>
  RGBuffer = record
    /// <summary> Stores the worldposition of the pixel (R=X ; G=Y ; B=Z) </summary>
    PositionBuffer : TFullscreenRendertarget;
    /// <summary> Stores the normalized normal in worldspace of the pixel (R=X ; G=Y ; B=Z) and the linear depth in the Alpha-Channel </summary>
    Normalbuffer : TFullscreenRendertarget;
    /// <summary> Stores the diffusecolor and a flag for the Background (RGB=Diffuse; A=0 for Background and 1 for Foreground) </summary>
    ColorBuffer : TFullscreenRendertarget;
    /// <summary> Stores Material data (A - Shading Reduction, R - SpecularIntensity, G - SpecularPower, B - SpecularTinting) </summary>
    MaterialBuffer : TFullscreenRendertarget;
    function PushArray : TArray<TRendertarget>;
  end;

  TRenderContext = class abstract
    private
      constructor Create(Rendertarget : TRendertarget); overload;
      constructor Create(Size : RIntVector2); overload;
    protected
      FRenderTarget : TRendertarget;
      FRenderTargetTexture : TTexture;
      FOwnsRenderTarget : boolean;
      FEventbus : TGFXDEventManager;
      FAmbient : RColor;
      FDirectionalLights : TUltimateObjectList<TDirectionalLight>;
      AktuellerShader : TShader;
      AktuellerShaderForciert : boolean;
      FCamera : TCamera;
      FFullscreenRendertargets : TList<TFullscreenRendertarget>;
      FBlurredScene, FLightBuffer, FSceneParameter, FSceneRendertarget : TFullscreenRendertarget;
      FGBuffer : RGBuffer;
      FDrawGBuffer : boolean;
      FShadowmapping : TShadowMapping;
      FAvailableRequirements : SetRenderRequirements;
      FShadowTechnique : EnumShadowTechnique;
      procedure SetShadowTechnique(const Value : EnumShadowTechnique);
      function GetCamera : TCamera; virtual;
      procedure setAmbient(Value : RColor);
      function GetMainDirectionalLight : TDirectionalLight;
      procedure UpdateResolution(Values : array of TValue);
      procedure FrameBegin();
    protected
      function SanitizeFlags(const Flags : SetDefaultShaderFlags) : SetDefaultShaderFlags;
    public
      /// <summary> Specifies the default color of the backbuffer </summary>
      Backgroundcolor : RColor;
      /// <summary> List of all used lights except directional lights. Only used if DeferredShading is used. </summary>
      Lights : TObjectList<TLight>;
      function Size : RIntVector2;
      /// <summary> Defines the Ambient-color of the scene. Alpha-Value will be ignored. By default a ambient light is set.</summary>
      property Ambient : RColor read FAmbient write setAmbient;
      /// <summary> The main (and shadowcasting) directional light. It is the first of all set directional lights. </summary>
      property MainDirectionalLight : TDirectionalLight read GetMainDirectionalLight;
      /// <summary> All directional lights of the scene. ATM there can be 4 directional lights at max, all above are ignored.
      /// If this list is empty, no directional light enlightens the scene and there will be no shadows. </summary>
      property DirectionalLights : TUltimateObjectList<TDirectionalLight> read FDirectionalLights;

      /// <summary> The eventbus of the GFXD. Register here for special event handling. </summary>
      property Eventbus : TGFXDEventManager read FEventbus;
      /// <summary> The camera of the scene </summary>
      property Camera : TCamera read GetCamera write FCamera;

      /// <summary>Gets the currently set shader instance</summary>
      property CurrentShader : TShader read AktuellerShader;
      // versucht einen Shader zu setzen, wobei andere Shader vorgehen können
      function SetShader(Shader : TShader; Forciert : boolean = False) : TShader;
      // entfernt einen forcierten Shader
      procedure ClearShader;

      property ShadowTechnique : EnumShadowTechnique read FShadowTechnique write SetShadowTechnique;

      property AvailableRequirements : SetRenderRequirements read FAvailableRequirements;
      property ShadowMapping : TShadowMapping read FShadowmapping;
      property DrawGBuffer : boolean read FDrawGBuffer;
      function Scene : TTexture;
      function BlurredScene : TTexture;
      property GBuffer : RGBuffer read FGBuffer;
      function Lightbuffer : TTexture;
      /// <summary> Swaps scene target and parameter. If Copy is true, they will be synchronized
      /// (important for not fully overdrawing effects) </summary>
      procedure SwitchScene(Copy : boolean = True); virtual; abstract;
      procedure SetShadowmapping(Shader : TShader);

      /// <summary> Compiles a default shader with specified flags. If CustomBlocks are used, no caching can be done. </summary>
      function CreateDefaultShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString = nil) : TShader; overload;
      function CreateDefaultShadowShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString = nil) : TShader; overload;
      // wählt einen integrierten Shader mittels der Bitmaske aus, GFXD setzt alles was sie kann
      function CreateAndSetDefaultShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString = nil) : TShader; overload;
      function CreateAndSetDefaultShadowShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString = nil) : TShader; overload;

      /// <summary> Applies a set of shader constants determined by the context, like camera, light and others. </summary>
      procedure ApplyGlobalShaderConstants(Shader : TShader);

      function CreateFullscreenRendertarget(Format : EnumTextureFormat = tfA8R8G8B8; Resolutiondivider : integer = 1) : TFullscreenRendertarget;
      procedure ChangeResolution(const NewResolution : RIntVector2);
      procedure UpdateExternalRendertarget(const Rendertarget : TRendertarget);
      /// <summary> Works not for the main scene. </summary>
      function BackbufferTexture : TTexture;

      destructor Destroy; override;
  end;

  TDefaultShaderManager = class
    private type
      TCreateShaderTaskData = class
        UID : string;
        // data for create shader
        DerivedShader : AString;
        RootShader : string;
        ShaderDefs : string;
        // cache data
        Flags : SetDefaultShaderFlags;
        Shader : TShader;
        constructor Create(const UID : string; DerivedShader : AString; const RootShader : string; const ShaderDefs : string; const Flags : SetDefaultShaderFlags);
        function ToString : string;
      end;

    strict private
      FTasks : TList<IFuture<TCreateShaderTaskData>>;
      FDefaultShaderCache : TObjectDictionary<string, TObjectDictionary<SetDefaultShaderFlags, TShader>>;
      function TryGetCachedDefaultShader(const Flags : SetDefaultShaderFlags; const UID : string; out DefaultShader : TShader) : boolean;
      procedure AddDefaultShaderToCache(const Flags : SetDefaultShaderFlags; const UID : string; DefaultShader : TShader);
      function CreateShaderTaskExecute(Sender : TObject) : TCreateShaderTaskData;
      procedure CreateShaderTask(const UID : string; const Flags : SetDefaultShaderFlags; DerivedShader : AString; const RootShader : string; const ShaderDefs : string);
    protected
      function ShaderFlagsToShaderDefines(const Flags : SetDefaultShaderFlags) : string;
      function CreateDefaultShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString; RootShader : string) : TShader; overload;
    public
      procedure PreCompileDefaultShader(const Flags : SetDefaultShaderFlags);
      procedure PreCompileDefaultShadowShader(const Flags : SetDefaultShaderFlags);
      procedure Update;
      constructor Create;
      destructor Destroy; override;
    public
      procedure PreCompileSet(Permutator : TGroupPermutator<SetDefaultShaderFlags>; ShadowShader : boolean);
      function SetDefaultShaderFlagsToArray(const ASet : SetDefaultShaderFlags) : TArray<TArray<SetDefaultShaderFlags>>;
  end;

  TRenderManager = class(TRenderContext)
    strict private
      constructor Create(const UID : string); overload;
    protected
      FRenderables : TObjectList<TRenderable>;
      Worldobjects : TObjectList<TWorldObject>;
      /// <summary> Blurs the world scene. </summary>
      FSceneBlur : TSceneBlurManager;
      // for Deferred Shading
      DeferredShadingEffect : TDeferredShading;
      SceneToBackBuffer : TSceneToBackbuffer;
      procedure RequireScene();
      procedure RequireGBuffer();
      procedure RequireLightBuffer();
      procedure RequireBlurredScene();
      function GetCamera : TCamera; override;
    public
      UID : string;
      Active : boolean;
      procedure DrawEvent(RenderOrder : EnumRenderStage);
      function GetSceneBoundings : RAABB;
      procedure GBufferRender;
      procedure RenderDeferred(CreateLightbuffer, ToScene : boolean);
      procedure SwitchScene(Copy : boolean = True); override;
      procedure AddRenderable(Renderable : TRenderable);
      procedure RemoveRenderable(Renderable : TRenderable);
      constructor Create(const UID : string; Rendertarget : TRendertarget); overload;
      constructor Create(const UID : string; Size : RIntVector2); overload;
      // Rendert das Bild
      procedure Render;
      destructor Destroy; override;
  end;

  TGFXD = class
    protected
      FSettings : TDeviceSettings;
      FFPSCounter : TFPSCounter;
      FDevice : TDevice;
      FBackbuffer : TRendertarget;
      Handle : HWND;

      FDefaultShaderManager : TDefaultShaderManager;
      FMainScene : TRenderManager;
      FScenes : TObjectList<TRenderManager>;
      FScenesByUID : TDictionary<string, TRenderManager>;
      procedure RenderBoundings;
    public
      DrawBoundings : EnumDrawnBoundings;
      property Device3D : TDevice read FDevice;
      property DefaultShaderManager : TDefaultShaderManager read FDefaultShaderManager;
      /// <summary> Class to manage all grapic-settings for device. To apply new settings call GFXD.Reset;</summary>
      property Settings : TDeviceSettings read FSettings;

      property MainScene : TRenderManager read FMainScene;
      property Scenes : TObjectList<TRenderManager> read FScenes;
      /// <summary> SceneUID is case-insensitive. </summary>
      function TryGetScene(const SceneUID : string; out Scene : TRenderManager) : boolean;
      /// <summary> SceneUID is case-insensitive. </summary>
      function AddScene(const SceneUID : string) : TRenderManager;
      /// <summary> Frees the scene. </summary>
      procedure DeleteScene(const SceneUID : string);

      property FPSCounter : TFPSCounter read FFPSCounter;
      /// <summary> actual frames per second </summary>
      function FPS : integer;
      constructor Create(Handle : HWND; Vollbild : boolean; Breite, Hoehe : integer; HAL, Vsync : boolean; Antialiasing : EnumAntialiasingLevel; Farbtiefe : integer = 32; DeviceType : EnumGFXDType = DirectX9Device; SuppressDebugLayer : boolean = False);
      /// <summary> Reset the GFXD and apply changed Settings, like Resolution or Fullscreen. Is also automatic called,
      /// if Device is lost, e.g. user tabswitch from Fullscreen (ALT + TAB)</summary>
      procedure Reset;
      /// <summary> Resizes the backbuffer. </summary>
      procedure ChangeResolution(const NewResolution : RIntVector2);
      // durch den Aufruf von Render wird der der interne Pool abgearbeitet und das Bild wird erzeugt
      procedure RenderTheWholeUniverseMegaGameProzedureDingMussNochLängerWerdenDeswegenHierMüllZeugsBlubsKeks;
      /// <summary> Saves the current backbuffer into a .png file with name 'Screenshot_<date>_<counter>.png' into the
      /// specified folder. </summary>
      procedure ScreenShot(TargetFolder : string);

      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  GFXD : TGFXD;

implementation

uses
  Engine.Vertex;

{ TGFXD }

constructor TGFXD.Create(Handle : HWND; Vollbild : boolean; Breite, Hoehe : integer; HAL, Vsync : boolean; Antialiasing : EnumAntialiasingLevel; Farbtiefe : integer; DeviceType : EnumGFXDType; SuppressDebugLayer : boolean);
begin
  Engine.Core.GFXD := self;
  GfxApiClassMapper := TGfxApiClassMapper.Create(DeviceType);
  self.Handle := Handle;
  FDefaultShaderManager := TDefaultShaderManager.Create;
  FSettings := TDeviceSettings.Create;
  Settings.Resolution.SetWidthHeight(Breite, Hoehe);
  Settings.Fullscreen := Vollbild;
  Settings.HAL := HAL;
  Settings.Vsync := Vsync;
  Settings.AntialiasingLevel := Antialiasing;
  Settings.SuppressDebugLayer := SuppressDebugLayer;
  FDevice := TDevice.CreateDevice(Handle, Settings);
  FScenes := TObjectList<TRenderManager>.Create;
  FScenesByUID := TDictionary<string, TRenderManager>.Create;
  FMainScene := TRenderManager.Create('main', Device3D.GetBackBuffer);
  FMainScene.Active := True;
  FScenes.Add(FMainScene);
  FFPSCounter := TFPSCounter.Create;
end;

function TGFXD.AddScene(const SceneUID : string) : TRenderManager;
begin
  Result := TRenderManager.Create(SceneUID.ToLowerInvariant, RIntVector2.Create(100, 100));
  FScenesByUID.Add(SceneUID.ToLowerInvariant, Result);
  FScenes.Insert(0, Result);
end;

procedure TGFXD.ChangeResolution(const NewResolution : RIntVector2);
begin
  if Settings.Resolution.Size <> NewResolution then
  begin
    Settings.Resolution := RResolution.Create(NewResolution.x, NewResolution.y);
    // first change resolution of backbuffer
    Device3D.ChangeResolution(NewResolution);
    // as other textures recreated on top of that rendertargets size information
    MainScene.UpdateExternalRendertarget(Device3D.GetBackBuffer);
  end;
end;

procedure TGFXD.DeleteScene(const SceneUID : string);
var
  Scene : TRenderManager;
begin
  if TryGetScene(SceneUID.ToLowerInvariant, Scene) then
  begin
    FScenesByUID.Remove(SceneUID.ToLowerInvariant);
    FScenes.Remove(Scene);
  end;
end;

destructor TGFXD.Destroy;
begin
  inherited;
  FBackbuffer.Free;
  FFPSCounter.Free;
  GfxApiClassMapper.Free;
  Settings.Free;
  FScenes.Free;
  FScenesByUID.Free;
  FDefaultShaderManager.Free;
  Device3D.Free;
end;

procedure TGFXD.RenderBoundings;
var
  i : integer;
  AABB : RAABB;
begin
  for i := 0 to MainScene.Worldobjects.Count - 1 do
  begin
    if DrawBoundings = dbSphere then LinePool.AddSphere(MainScene.Worldobjects[i].GetBoundingSphere, RColor.CRED);
    AABB := MainScene.Worldobjects[i].GetBoundingBox;
    if DrawBoundings = dbBox then LinePool.AddBox(AABB, RColor.CRED, 3);
  end;
end;

function TGFXD.FPS : integer;
begin
  Result := FFPSCounter.getFPS;
end;

procedure TGFXD.RenderTheWholeUniverseMegaGameProzedureDingMussNochLängerWerdenDeswegenHierMüllZeugsBlubsKeks;
var
  i : integer;
begin
  if DrawBoundings <> dbNone then RenderBoundings;
  DefaultShaderManager.Update;

  GFXD.Device3D.BeginScene;

  for i := 0 to FScenes.Count - 1 do
    if FScenes[i].Active then
    begin
      FScenes[i].Render;
      FScenes[i].Active := FScenes[i].UID = 'main';
    end;

  GFXD.Device3D.EndScene;

  GFXD.Device3D.Present(nil, nil, 0);
  FFPSCounter.FrameTick;
end;

procedure TGFXD.Reset;
begin
  raise ENotImplemented.Create('TGFXD.Reset not implemented!');
end;

procedure TGFXD.ScreenShot(TargetFolder : string);
var
  i : integer;
  FileName : string;
begin
  i := 0;
  // append incremental numbers for screenshot of the same name
  repeat
    FileName := TargetFolder + '\Screenshot_' + RDate(Date()).ToString('dd-mm-yyyy') + HGeneric.TertOp<string>(i > 0, '_' + Inttostr(i + 1), '') + '.png';
    inc(i);
  until not FileExists(FileName);
  Device3D.SaveScreenshotToFile(FileName);
end;

function TGFXD.TryGetScene(const SceneUID : string; out Scene : TRenderManager) : boolean;
begin
  Result := FScenesByUID.TryGetValue(SceneUID.ToLowerInvariant, Scene);
end;

{ TRenderManager }

procedure TRenderManager.AddRenderable(Renderable : TRenderable);
begin
  FRenderables.Add(Renderable);
  if Renderable is TWorldObject then Worldobjects.Add(TWorldObject(Renderable));
end;

procedure TRenderManager.RemoveRenderable(Renderable : TRenderable);
begin
  FRenderables.Remove(Renderable);
  if Renderable is TWorldObject then Worldobjects.Remove(TWorldObject(Renderable));
end;

constructor TRenderManager.Create(const UID : string);
begin
  self.UID := UID;
  FRenderables := TObjectList<TRenderable>.Create(False);
  Worldobjects := TObjectList<TWorldObject>.Create(False);
  DeferredShadingEffect := TDeferredShading.Create();
  SceneToBackBuffer := TSceneToBackbuffer.Create();
  FShadowmapping := TShadowMapping.Create(self);
  FSceneBlur := TSceneBlurManager.Create(self);
end;

function TRenderManager.GetCamera : TCamera;
begin
  if (ShadowTechnique = stShadowmapping) and ShadowMapping.UseShadowCamera then Result := ShadowMapping.FShadowCamera
  else Result := inherited;
end;

constructor TRenderManager.Create(const UID : string; Rendertarget : TRendertarget);
begin
  inherited Create(Rendertarget);
  Create(UID);
end;

constructor TRenderManager.Create(const UID : string; Size : RIntVector2);
begin
  inherited Create(Size);
  Create(UID);
end;

procedure TRenderManager.RequireBlurredScene;
begin
  if not assigned(FBlurredScene) then
      FBlurredScene := CreateFullscreenRendertarget();
end;

procedure TRenderManager.RequireGBuffer;
begin
  if not assigned(GBuffer.PositionBuffer) then
  begin
    FGBuffer.PositionBuffer := CreateFullscreenRendertarget(tfA32B32G32R32F);
    FGBuffer.Normalbuffer := CreateFullscreenRendertarget(tfA16B16G16R16F);
    FGBuffer.ColorBuffer := CreateFullscreenRendertarget(tfA8R8G8B8);
    FGBuffer.MaterialBuffer := CreateFullscreenRendertarget(tfA8R8G8B8);
  end;
end;

procedure TRenderManager.RequireLightBuffer;
begin
  if not assigned(FLightBuffer) then
      FLightBuffer := CreateFullscreenRendertarget(tfA16B16G16R16F);
end;

procedure TRenderManager.RequireScene;
begin
  if not assigned(FSceneParameter) then
  begin
    FSceneParameter := CreateFullscreenRendertarget(tfA8R8G8B8);
    FSceneRendertarget := CreateFullscreenRendertarget(tfA8R8G8B8);
  end;
end;

destructor TRenderManager.Destroy;
begin
  SceneToBackBuffer.Free;
  DeferredShadingEffect.Free;
  FRenderables.Free;
  Worldobjects.Free;
  FSceneBlur.Free;
  inherited;
end;

procedure TRenderManager.DrawEvent(RenderOrder : EnumRenderStage);
begin
  FEventbus.SetDrawEvent(RenderOrder);
end;

procedure TRenderManager.GBufferRender;
begin
  // Turn on GBuffer-Drawing in standard shaders
  FDrawGBuffer := True;
  // initialize Rendertargets
  GFXD.Device3D.PushRenderTargets(GBuffer.PushArray);
  // clear Textures
  GFXD.Device3D.Clear([cfTarget], 0, 1, 0);
  // Z-Objekte rendern
  DrawEvent(rsWorld);
  // recover old surface
  GFXD.Device3D.PopRenderTargets;
  FDrawGBuffer := False;
end;

function TRenderManager.GetSceneBoundings : RAABB;
var
  i : integer;
begin
  if Worldobjects.Count <= 0 then Exit;
  Result := Worldobjects[0].GetBoundingBox;
  for i := 1 to Worldobjects.Count - 1 do
    if not Worldobjects[i].CastsNoShadow then
        Result.Extend(Worldobjects[i].GetBoundingBox);
end;

procedure TRenderManager.Render;
var
  RequireGBuffer, RequireScene, RequireLightBuffer, RequireBlurredScene : boolean;
  FrameRequirements : SetRenderRequirements;
  i : integer;
begin
  if FOwnsRenderTarget then
  begin
    GFXD.Device3D.PushRenderTargets([FRenderTargetTexture.AsRendertarget]);
    GFXD.Device3D.SetDefaultDepthStencilBuffer(FRenderTargetTexture.AsRendertarget);
  end
  else
      GFXD.Device3D.SetDefaultDepthStencilBuffer(nil);

  FrameRequirements := [];
  for i := 0 to FRenderables.Count - 1 do
    if FRenderables[i].Visible then
    begin
      FrameRequirements := FrameRequirements + FRenderables[i].Requirements;
    end;

  FAvailableRequirements := FrameRequirements;
  RequireGBuffer := GFXD.Settings.DeferredShading and GFXD.Settings.CanDeferredShading;
  if RequireGBuffer then self.RequireGBuffer;

  if not RequireGBuffer then exclude(FAvailableRequirements, rrGBuffer);

  RequireScene := [rrScene, rrBlurredScene] * FrameRequirements <> [];
  if RequireScene then self.RequireScene;

  RequireBlurredScene := rrBlurredScene in FrameRequirements;
  if RequireBlurredScene then self.RequireBlurredScene;

  RequireLightBuffer := rrLightbuffer in FrameRequirements;
  if RequireLightBuffer then self.RequireLightBuffer;

  if RequireLightBuffer then
  begin
    GFXD.Device3D.PushRenderTargets([Lightbuffer.AsRendertarget]);
    GFXD.Device3D.Clear([cfTarget], $00000000, 1, 0);
    GFXD.Device3D.PopRenderTargets;
  end;

  GFXD.Device3D.Clear([cfTarget, cfZBuffer, cfStencil], Backgroundcolor, 1, 0);
  if RequireScene then
  begin
    GFXD.Device3D.PushRenderTargets([FSceneRendertarget.Texture.AsRendertarget]);
    GFXD.Device3D.Clear([cfTarget], Backgroundcolor, 1, 0);
  end;

  FEventbus.SetEvent(geFrameBegin);
  if RequireGBuffer then GBufferRender;

  DrawEvent(rsEnvironment);
  if (ShadowTechnique = stShadowmapping) then FShadowmapping.RenderShadowMap();
  if not(GFXD.Settings.DeferredShading) then
  begin
    DrawEvent(rsWorld);
  end
  else
  begin
    if (ShadowTechnique = stShadowmapping) then FShadowmapping.RenderMask();
    RenderDeferred(RequireLightBuffer, RequireScene);
  end;

  DrawEvent(rsWorldPostEffects);
  DrawEvent(rsEffects);
  DrawEvent(rsPostEffects);

  // Everything in world space is finished, now we can blur the scene if needed
  if RequireBlurredScene then
  begin
    SwitchScene(True);
    DrawEvent(rsSceneBlur);
  end;

  DrawEvent(rsGUI);

  if RequireScene then GFXD.Device3D.PopRenderTargets;

  if RequireScene then SceneToBackBuffer.Render(FSceneRendertarget.Texture, self);

  if FOwnsRenderTarget then
      GFXD.Device3D.PopRenderTargets;

  FEventbus.SetEvent(geFrameEnd);
end;

procedure TRenderManager.RenderDeferred(CreateLightbuffer, ToScene : boolean);
begin
  if CreateLightbuffer then
  begin
    if ToScene then GFXD.Device3D.PushRenderTargets([FSceneRendertarget.Texture.AsRendertarget, Lightbuffer.AsRendertarget])
    else GFXD.Device3D.PushRenderTargets([GFXD.Device3D.GetBackBuffer, Lightbuffer.AsRendertarget]);
  end;
  DeferredShadingEffect.RenderLightBuffer := CreateLightbuffer;
  DeferredShadingEffect.Render(self);
  if CreateLightbuffer then GFXD.Device3D.PopRenderTargets;
end;

procedure TRenderManager.SwitchScene(Copy : boolean);
begin
  GFXD.Device3D.PopRenderTargets;
  HGeneric.Swap<TFullscreenRendertarget>(FSceneParameter, FSceneRendertarget);
  if Copy and FSceneParameter.Texture.FastCopyAvailable then
      FSceneParameter.Texture.FastCopy(FSceneRendertarget.Texture);
  GFXD.Device3D.PushRenderTargets([FSceneRendertarget.Texture.AsRendertarget]);
  if Copy and not FSceneRendertarget.Texture.FastCopyAvailable then
      SceneToBackBuffer.Render(FSceneParameter.Texture, self);
end;

{ TDeferredShading }

procedure TDeferredShading.AddSpotLightToVertices(Light : TSpotlight; RenderContext : TRenderContext);
const
  LIGHTCONESAMPLES = 5;
var
  Points, Ground : array [0 .. LIGHTCONESAMPLES * 3 - 1] of RSpotlightVertex;
  Side, Target : RVector3;
  i, Index : integer;
  coneradius, Alpha, r1 : Single;
begin
  Points[0].Position := Light.Position;
  Points[0].Range := Light.Range;
  Points[0].Color := Light.Color;
  Points[0].Theta := cos(Light.Theta / 2);
  Points[0].Phi := cos(Light.Phi / 2);
  Points[0].Direction := Light.Direction;
  Points[0].Sourceposition := Light.Position;
  for i := 1 to length(Points) - 1 do Points[i] := Points[0];
  Target := Light.Position + (Light.Direction * Light.Range);
  Alpha := 2 * PI / LIGHTCONESAMPLES;
  r1 := Light.Range * tan(Light.Phi / 2);
  coneradius := sqrt(sqr(r1) / (1 - sqr(sin(Alpha / 2))));
  Side := RVector3.UNITY.Cross(Light.Direction).Normalize * coneradius;
  for i := 2 to length(Points) + 3 do
    if i mod 3 <> 0 then
    begin
      index := i mod length(Points);
      if (index mod 3 = 1) then
      begin
        Points[index].Position := Points[HGeneric.TertOp<integer>(index - 2 < 0, length(Points) + index, index) - 2].Position;
      end
      else
      begin
        Points[index].Position := Target + Side.RotateAxis(Light.Direction, 2 * PI * (index div 3) / (LIGHTCONESAMPLES));
      end;
    end;
  for i := 0 to length(Ground) - 1 do
  begin
    if i mod 3 = 0 then
    begin
      Ground[i] := Points[i];
      Ground[i].Position := Target;
    end;
    if i mod 3 = 1 then
    begin
      Ground[i] := Points[i + 1];
      Ground[i + 1] := Points[i];
    end;
  end;
  spotvertices.AddRange(Points);
  spotvertices.AddRange(Ground);
end;

constructor TDeferredShading.Create();
begin
  pointvertexdeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
  pointvertexdeclaration.AddVertexElement(etFloat3, euPosition);
  pointvertexdeclaration.AddVertexElement(etFloat4, euColor);
  pointvertexdeclaration.AddVertexElement(etFloat3, euTexturecoordinate);
  pointvertexdeclaration.AddVertexElement(etFloat3, euTexturecoordinate, emDefault, 0, 1);
  pointvertexdeclaration.EndDeclaration;
  spotvertexdeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
  spotvertexdeclaration.AddVertexElement(etFloat3, euPosition);
  spotvertexdeclaration.AddVertexElement(etFloat3, euTexturecoordinate);
  spotvertexdeclaration.AddVertexElement(etFloat3, euTexturecoordinate, emDefault, 0, 1);
  spotvertexdeclaration.AddVertexElement(etFloat4, euColor);
  spotvertexdeclaration.AddVertexElement(etFloat3, euTexturecoordinate, emDefault, 0, 2);
  spotvertexdeclaration.EndDeclaration;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'DeferredDirectionalAmbientLight.fx', []);
  ShadowDirectionalShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'DeferredDirectionalAmbientLight.fx', ['#define SHADOWMASK']);
  Pointshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'DeferredPointLight.fx', []);
  LBShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'DeferredDirectionalAmbientLight.fx', ['#define LIGHTBUFFER']);
  LBPointshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'DeferredPointLight.fx', ['#define LIGHTBUFFER']);
  Spotshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'DeferredSpotLight.fx', []);
  LBSpotshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'DeferredSpotLight.fx', ['#define LIGHTBUFFER']);
  ScreenQuad := TScreenQuad.Create();
  pointvertices := TList<RPointlightVertex>.Create;
  negativepointvertices := TList<RPointlightVertex>.Create;
  spotvertices := TList<RSpotlightVertex>.Create;
  pointvertexbuffer := TVertexBufferList.Create([usFrequentlyWriteable], GFXD.Device3D);
  negativepointvertexbuffer := TVertexBufferList.Create([usFrequentlyWriteable], GFXD.Device3D);
  spotvertexbuffer := TVertexBufferList.Create([usFrequentlyWriteable], GFXD.Device3D);
end;

destructor TDeferredShading.Destroy;
begin
  ScreenQuad.Free;
  Shader.Free;
  Pointshader.Free;
  Spotshader.Free;
  LBShader.Free;
  LBPointshader.Free;
  LBSpotshader.Free;
  pointvertices.Free;
  negativepointvertices.Free;
  spotvertices.Free;
  pointvertexdeclaration.Free;
  spotvertexdeclaration.Free;
  pointvertexbuffer.Free;
  negativepointvertexbuffer.Free;
  spotvertexbuffer.Free;
  ShadowDirectionalShader.Free;
end;

procedure TDeferredShading.Render(RenderContext : TRenderContext);
const
  MAX_DIRECTIONAL_LIGHTS = 4;
var
  Shader, Pointshader, Spotshader : TShader;
  i, j : integer;
  lightdirs : array [0 .. MAX_DIRECTIONAL_LIGHTS - 1] of RVector4;
  lightcolors : array [0 .. MAX_DIRECTIONAL_LIGHTS - 1] of RVector4;
begin
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable2, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable3, tfPoint, amClamp);

  if RenderLightBuffer then
  begin
    Shader := self.LBShader;
    Pointshader := self.LBPointshader;
    Spotshader := self.LBSpotshader;
  end
  else
  begin
    if (RenderContext as TRenderManager).ShadowTechnique = stShadowmapping then Shader := self.ShadowDirectionalShader
    else Shader := self.Shader;
    Pointshader := self.Pointshader;
    Spotshader := self.Spotshader;
  end;
  // Directional light + Ambient
  RenderContext.SetShader(Shader);

  GFXD.Device3D.SetRenderState(rsZENABLE, False);
  GFXD.Device3D.SetRenderState(rsZWRITEENABLE, False);

  Shader.SetTexture(tsColor, RenderContext.GBuffer.ColorBuffer.Texture);
  Shader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
  Shader.SetTexture(tsVariable1, RenderContext.GBuffer.PositionBuffer.Texture);
  Shader.SetTexture(tsVariable2, RenderContext.GBuffer.MaterialBuffer.Texture);
  if RenderContext.ShadowTechnique = stShadowmapping then Shader.SetTexture(tsVariable3, ShadowMask);
  Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
  Shader.SetShaderConstant<RVector3>(dcAmbient, RenderContext.Ambient.PremultiplyAlpha.RGB);
  Shader.SetShaderConstant<RVector2>(dcViewportSize, RenderContext.Size);

  if not RenderContext.DirectionalLights.Extra.IsEmpty then
  begin
    j := 0;
    for i := 0 to Min(RenderContext.DirectionalLights.Count - 1, MAX_DIRECTIONAL_LIGHTS - 1) do
      if RenderContext.DirectionalLights[i].Enabled then
      begin
        lightdirs[j] := -RenderContext.DirectionalLights[i].Direction.XYZ0;
        lightcolors[j] := RenderContext.DirectionalLights[i].Color;
        inc(j);
      end;
    Shader.SetShaderConstant<integer>('DirectionalLightCount', j);
    Shader.SetShaderConstantArray<RVector4>('DirectionalLightDirs', lightdirs);
    Shader.SetShaderConstantArray<RVector4>('DirectionalLightColors', lightcolors);
  end
  else Shader.SetShaderConstant<integer>('DirectionalLightCount', 0);

  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearSamplerStates;
  GFXD.Device3D.ClearRenderState();

  SetUpVertexbuffer(RenderContext);

  // Pointlights
  if pointvertices.Count > 0 then
  begin
    RenderContext.SetShader(Pointshader);
    Pointshader.SetTexture(tsColor, RenderContext.GBuffer.ColorBuffer.Texture);
    Pointshader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
    Pointshader.SetTexture(tsVariable1, RenderContext.GBuffer.PositionBuffer.Texture);
    Pointshader.SetTexture(tsVariable2, RenderContext.GBuffer.MaterialBuffer.Texture);
    Pointshader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
    Pointshader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
    Pointshader.SetShaderConstant<RVector2>(dcViewportSize, RenderContext.Size);
    Pointshader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
    Pointshader.SetShaderConstant<RVector3>(dcAmbient, RVector3.ZERO);
    GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(rsDESTBLEND, blOne);
    GFXD.Device3D.SetRenderState(rsZENABLE, 0);
    GFXD.Device3D.SetRenderState(rsCULLMODE, cmNone);
    Pointshader.ShaderBegin;
    GFXD.Device3D.SetVertexDeclaration(pointvertexdeclaration);
    GFXD.Device3D.SetStreamSource(0, pointvertexbuffer.CurrentVertexbuffer, 0, sizeof(RPointlightVertex));
    GFXD.Device3D.DrawPrimitive(ptTrianglelist, 0, pointvertices.Count div 3);
    Pointshader.ShaderEnd;
    GFXD.Device3D.ClearRenderState();
  end;

  // negative Pointlights
  if negativepointvertices.Count > 0 then
  begin
    RenderContext.SetShader(Pointshader);
    Pointshader.SetTexture(tsColor, RenderContext.GBuffer.ColorBuffer.Texture);
    Pointshader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
    Pointshader.SetTexture(tsVariable1, RenderContext.GBuffer.PositionBuffer.Texture);
    Pointshader.SetTexture(tsVariable2, RenderContext.GBuffer.MaterialBuffer.Texture);
    Pointshader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
    Pointshader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
    Pointshader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
    Pointshader.SetShaderConstant<RVector2>(dcViewportSize, RenderContext.Size);
    Pointshader.SetShaderConstant<RVector3>(dcAmbient, RVector3.ZERO);
    GFXD.Device3D.SetRenderState(rsBLENDOP, boRevSubtract);
    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(rsDESTBLEND, blOne);
    GFXD.Device3D.SetRenderState(rsZENABLE, 0);
    GFXD.Device3D.SetRenderState(rsCULLMODE, cmNone);
    Pointshader.ShaderBegin;
    GFXD.Device3D.SetVertexDeclaration(pointvertexdeclaration);
    GFXD.Device3D.SetStreamSource(0, negativepointvertexbuffer.CurrentVertexbuffer, 0, sizeof(RPointlightVertex));
    GFXD.Device3D.DrawPrimitive(ptTrianglelist, 0, negativepointvertices.Count div 3);
    Pointshader.ShaderEnd;
    GFXD.Device3D.ClearRenderState();
  end;

  // Spotlights
  if spotvertices.Count > 0 then
  begin
    RenderContext.SetShader(Spotshader);
    Spotshader.SetTexture(tsColor, RenderContext.GBuffer.ColorBuffer.Texture);
    Spotshader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
    Spotshader.SetTexture(tsVariable1, RenderContext.GBuffer.PositionBuffer.Texture);
    Spotshader.SetTexture(tsVariable2, RenderContext.GBuffer.MaterialBuffer.Texture);
    Spotshader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
    Spotshader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
    Spotshader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
    Spotshader.SetShaderConstant<RVector2>(dcViewportSize, RenderContext.Size);
    GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(rsDESTBLEND, blOne);
    GFXD.Device3D.SetRenderState(rsZWRITEENABLE, 0);
    GFXD.Device3D.SetRenderState(rsCULLMODE, cmNone);
    Spotshader.ShaderBegin;
    GFXD.Device3D.SetVertexDeclaration(spotvertexdeclaration);
    GFXD.Device3D.SetStreamSource(0, spotvertexbuffer.CurrentVertexbuffer, 0, sizeof(RSpotlightVertex));
    GFXD.Device3D.DrawPrimitive(ptTrianglelist, 0, spotvertices.Count div 3);
    Spotshader.ShaderEnd;
    GFXD.Device3D.ClearRenderState();
  end;

  GFXD.Device3D.ClearSamplerStates;
end;

procedure TDeferredShading.SetUpVertexbuffer(RenderContext : TRenderContext);
var
  i : integer;
  pointverticesarr : TArray<RPointlightVertex>;
  spotverticesarr : TArray<RSpotlightVertex>;
  pvertex : Pointer;
begin
  pointvertices.Clear;
  negativepointvertices.Clear;
  spotvertices.Clear;
  for i := 0 to RenderContext.Lights.Count - 1 do
    if RenderContext.Lights[i].Enabled and (RenderContext.Lights[i].IsVisible) then AddLightToVertices(RenderContext.Lights[i], RenderContext);
  if pointvertices.Count > 0 then
  begin
    pointverticesarr := pointvertices.ToArray;
    pointvertexbuffer.GetVertexbuffer(sizeof(RPointlightVertex) * pointvertices.Count);
    pvertex := pointvertexbuffer.CurrentVertexbuffer.LowLock([lfDiscard]);
    move(pointverticesarr[0], pvertex^, sizeof(RPointlightVertex) * pointvertices.Count);
    pointvertexbuffer.CurrentVertexbuffer.Unlock;
  end;
  if negativepointvertices.Count > 0 then
  begin
    pointverticesarr := negativepointvertices.ToArray;
    negativepointvertexbuffer.GetVertexbuffer(sizeof(RPointlightVertex) * negativepointvertices.Count);
    pvertex := negativepointvertexbuffer.CurrentVertexbuffer.LowLock([lfDiscard]);
    move(pointverticesarr[0], pvertex^, sizeof(RPointlightVertex) * negativepointvertices.Count);
    negativepointvertexbuffer.CurrentVertexbuffer.Unlock;
  end;
  if spotvertices.Count > 0 then
  begin
    spotverticesarr := spotvertices.ToArray;
    spotvertexbuffer.GetVertexbuffer(sizeof(RSpotlightVertex) * spotvertices.Count);
    pvertex := spotvertexbuffer.CurrentVertexbuffer.LowLock([lfDiscard]);
    move(spotverticesarr[0], pvertex^, sizeof(RSpotlightVertex) * spotvertices.Count);
    spotvertexbuffer.CurrentVertexbuffer.Unlock;
  end;
end;

procedure TDeferredShading.AddLightToVertices(Light : TLight; RenderContext : TRenderContext);
begin
  if Light is TPointlight then AddPointLightToVertices(TPointlight(Light), RenderContext)
  else if Light is TSpotlight then AddSpotLightToVertices(TSpotlight(Light), RenderContext);
end;

procedure TDeferredShading.AddPointLightToVertices(Light : TPointlight; RenderContext : TRenderContext);
const
  PROJECTION_BIAS = 1.15;
var
  Points : array [0 .. 5] of RPointlightVertex;
  Left, Up : RVector3;
  i : integer;
begin
  // this creates a slice in the middle of the sphere
  // this can generate a hard edge because of projection
  // possible solution, offset to the front
  // but then you cant stay in the light (which you cant now, too)
  Left := RenderContext.Camera.ScreenLeft * (Light.Range.x) * PROJECTION_BIAS;
  Up := RenderContext.Camera.ScreenUp * (Light.Range.x) * PROJECTION_BIAS;
  Points[0].Position := Light.Position + Left + Up;
  Points[1].Position := Light.Position + Left - Up;
  Points[2].Position := Light.Position - Left + Up;
  Points[3].Position := Points[2].Position;
  Points[4].Position := Points[1].Position;
  Points[5].Position := Light.Position - Left - Up;
  for i := 0 to 5 do
  begin
    Points[i].Range := Light.Range;
    Points[i].diffuse := Light.Color.RGBA.Abs;
    Points[i].Center := Light.Position;
  end;
  if Light.IsNegative then
      negativepointvertices.AddRange(Points)
  else
      pointvertices.AddRange(Points);
end;

{ TSceneToBackbuffer }

constructor TSceneToBackbuffer.Create();
begin
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'ScreenToBackbuffer.fx', []);
  ScreenQuad := TScreenQuad.Create();
end;

constructor TSceneToBackbuffer.CreateWithAlpha;
begin
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'ScreenToBackbufferWithAlpha.fx', []);
  ScreenQuad := TScreenQuad.Create();
end;

destructor TSceneToBackbuffer.Destroy;
begin
  Shader.Free;
  ScreenQuad.Free;
  inherited;
end;

procedure TSceneToBackbuffer.Render(Scene : TTexture; RenderContext : TRenderContext);
begin
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  RenderContext.SetShader(Shader);
  Shader.SetTexture(tsColor, Scene);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearSamplerStates;
end;

{ TShadowMapping }

procedure TShadowMapping.RenderShadowMap();
var
  OBB : ROBB;
  CurrentSceneBoundings : RAABB;
  i : integer;
  FormerPos, NewPos, MoveVector, RealPos : RVector3;
  Texelsize : Single;
  Points : TArray<RVector3>;
  first : boolean;
begin
  inherited;
  if not Enabled or (FRenderManager.MainDirectionalLight = nil) then Exit;
  CurrentSceneBoundings := FRenderManager.GetSceneBoundings;
  CurrentSceneBoundings.Min.y := Min(ClipAbove, Max(CurrentSceneBoundings.Min.y, ClipBelow));
  CurrentSceneBoundings.Max.y := Min(ClipAbove, Max(CurrentSceneBoundings.Max.y, ClipBelow));

  // LinePool.AddBox(CurrentSceneBoundings, RColor.CGREEN, 1);

  // surround clipped frustum with light
  if FRenderManager.Camera.ViewingFrustum.ContainsAABB(CurrentSceneBoundings) then
  begin
    setlength(Points, 8);
    for i := 0 to 7 do
        Points[i] := CurrentSceneBoundings.Corners[i];
  end
  else Points := FRenderManager.Camera.ViewingFrustum.IntersectionSetAABBRaw(CurrentSceneBoundings);

  first := True;
  for i := 0 to length(Points) - 1 do
  begin
    if Points[i].IsEmpty then Continue;
    if first then
    begin
      OBB := ROBB.Create(Points[i], FRenderManager.MainDirectionalLight.Direction, RVector3.UNITY, RVector3.ZERO);
      first := False;
      Continue;
    end;
    OBB.ExtendOptimal(Points[i]);
  end;

  // ensure near far of lightfrustum to be at the edges of the scene
  OBB := OBB.FitNearFarToAABB(CurrentSceneBoundings);

  // LinePool.AddBox(OBB, RColor.CBLACK, 1);

  NewPos := OBB.Position - (OBB.Front * OBB.Size.Z);
  RealPos := NewPos;
  FormerPos := FShadowCamera.Position;
  Texelsize := FShadowCamera.CameraData.Width / Resolution;
  MoveVector := NewPos - FormerPos;
  // movement along look direction needn't to be discretizised
  NewPos := FormerPos + MoveVector.Dot(OBB.Front) * OBB.Front;
  // movement along other axis are discretizised to texelposition for steady shadow borders.
  NewPos := NewPos + Trunc(MoveVector.Dot(OBB.Up) / Texelsize) * Texelsize * OBB.Up;
  NewPos := NewPos + Trunc(MoveVector.Dot(OBB.Left) / Texelsize) * Texelsize * OBB.Left;

  OBB.Size.x := OBB.Size.XY.MaxValue;
  OBB.Size.y := OBB.Size.x;
  // Only change size if error is over 10% for reducing flickering borders
  // if (abs(FShadowCamera.CameraData.Width - OBB.Size.x * 2) < FShadowCamera.CameraData.Width * 0.1) then
  // OBB.Size.XY := RVector2.Create(FShadowCamera.CameraData.Width / 2);

  // if FormerPos.distance(RealPos) >= NewPos.distance(RealPos) then
  NewPos := NewPos + (FRenderManager.MainDirectionalLight.Direction * TweakZoom);
  OBB.Size.Z := OBB.Size.Z - TweakZoom / 2;
  FShadowCamera.OrthogonalCamera(NewPos, NewPos + FRenderManager.MainDirectionalLight.Direction, OBB.Up, OBB.Size.x * 2, OBB.Size.y * 2, 1.0, OBB.Size.Z * 2);

  UseShadowCamera := True;
  GFXD.Device3D.PushRenderTargets([FShadowMap.AsRendertarget]);

  GFXD.Device3D.Clear([cfTarget], 0, 1, 0);
  // GFXD.Device3D.SetRenderState(rsSEPARATEALPHABLENDENABLE, true, true);
  // GFXD.Device3D.SetRenderState(rsBLENDOPALPHA, boAdd, true);
  // GFXD.Device3D.SetRenderState(rsSRCBLENDALPHA, blSrcAlpha, true);
  // GFXD.Device3D.SetRenderState(rsDESTBLENDALPHA, blInvSrcAlpha, true);
  GFXD.Device3D.SetRenderState(rsBLENDOP, boMax, True);
  GFXD.Device3D.SetRenderState(rsSRCBLEND, blOne, True);
  GFXD.Device3D.SetRenderState(rsDESTBLEND, blOne, True);
  GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1, True);
  GFXD.Device3D.SetRenderState(rsZENABLE, 0, True);

  FRenderManager.Eventbus.SetEvent(geDrawOpaqueShadowmap);

  FRenderManager.Eventbus.SetEvent(geDrawTranslucentShadowmap);

  GFXD.Device3D.ClearRenderState(rsBLENDOP);
  GFXD.Device3D.ClearRenderState(rsALPHABLENDENABLE);
  GFXD.Device3D.ClearRenderState(rsSRCBLEND);
  GFXD.Device3D.ClearRenderState(rsDESTBLEND);
  GFXD.Device3D.ClearRenderState(rsZENABLE);
  GFXD.Device3D.ClearRenderState(rsSEPARATEALPHABLENDENABLE);
  GFXD.Device3D.ClearRenderState(rsBLENDOPALPHA);
  GFXD.Device3D.ClearRenderState(rsSRCBLENDALPHA);
  GFXD.Device3D.ClearRenderState(rsDESTBLENDALPHA);

  GFXD.Device3D.PopRenderTargets;
  UseShadowCamera := False;
end;

function TShadowMapping.GetResolution : integer;
begin
  Result := FShadowMap.Width;
end;

procedure TShadowMapping.SetResolution(const Resolution : integer);
begin
  FShadowMap.Free;
  FShadowMap := TTexture.CreateTexture(Resolution, Resolution, 1, [usRendertarget], tfA32B32G32R32F, GFXD.Device3D);
  FScreenQuad.Free;
  FScreenQuad := TScreenQuad.Create(RVector2(Resolution));
end;

procedure TShadowMapping.SetShadowSamplingRange(const ssr : integer);
begin
  assert((ssr >= 0) and (ssr <= 4), 'TShadowMapping.SetShadowSamplingRange: Must be between 1 and 4!');
  FShadowSamplingRange := HMath.Clamp(ssr, 0, 4);
  FShadowMaskShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'MakeShadowMask.fx', ['#define SHADOW_SAMPLING_RANGE ' + Inttostr(FShadowSamplingRange)]);
end;

constructor TShadowMapping.Create(RenderManager : TRenderManager);
begin
  FRenderManager := RenderManager;
  FShadowMapShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, DEFAULT_SHADOW_SHADER, []);
  ShadowSamplingRange := 1;
  FMask := FRenderManager.CreateFullscreenRendertarget();
  FShadowCamera := TCamera.Create(FRenderManager.Size);
  Shadowbias := 0.01;
  Slopebias := -0.5;
  Strength := 1;
  Resolution := 2048;
  Enabled := True;
  ClipBelow := -100000;
  ClipAbove := 100000;
end;

destructor TShadowMapping.Destroy;
begin
  FMask.Free;
  FShadowMap.Free;
  FScreenQuad.Free;
  FShadowMapShader.Free;
  FShadowMaskShader.Free;
  FShadowCamera.Free;
  inherited;
end;

procedure TShadowMapping.RenderMask();
var
  Shader : TShader;
begin
  if FRenderManager.MainDirectionalLight = nil then Exit;
  inherited;
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  FRenderManager.DeferredShadingEffect.ShadowMask := nil;
  if not Enabled then Exit;
  GFXD.Device3D.PushRenderTargets([FMask.Texture.AsRendertarget]);
  Shader := FShadowMaskShader;
  FRenderManager.SetShader(Shader);
  Shader.SetTexture(tsColor, FShadowMap);
  Shader.SetTexture(tsNormal, FRenderManager.GBuffer.Normalbuffer.Texture);
  Shader.SetTexture(tsVariable1, FRenderManager.GBuffer.PositionBuffer.Texture);
  Shader.SetShaderConstant<RVector3>(dcDirectionalLightDir, -FRenderManager.MainDirectionalLight.Direction);
  Shader.SetShaderConstant<RMatrix>(dcShadowView, FShadowCamera.View);
  Shader.SetShaderConstant<RMatrix>(dcShadowProj, FShadowCamera.Projection);
  Shader.SetShaderConstant<Single>(dcShadowbias, Shadowbias);
  Shader.SetShaderConstant<Single>(dcSlopebias, Slopebias);
  Shader.SetShaderConstant<Single>(dcShadowpixelwidth, 1 / FShadowMap.Width);
  Shader.SetShaderConstant<RVector3>(dcShadowcameraPosition, FShadowCamera.Position);
  Shader.SetShaderConstant<Single>(dcShadowStrength, Strength);
  Shader.ShaderBegin;
  FScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.PopRenderTargets;
  FRenderManager.DeferredShadingEffect.ShadowMask := FMask.Texture;
  GFXD.Device3D.ClearSamplerStates;
end;

{ TSceneBlurManager }

procedure TSceneBlurManager.BeforeDrawBlur(Eventname : EnumRenderStage; RenderContext : TRenderContext);
begin
  if Eventname <> rsSceneBlur then Exit;
  // generate blurred scene
  GFXD.Device3D.PushRenderTargets([RenderContext.BlurredScene.AsRendertarget]);
  FTextureBlur.RenderBlur(RenderContext.Scene, RenderContext);
  GFXD.Device3D.PopRenderTargets;
end;

constructor TSceneBlurManager.Create(RenderManager : TRenderManager);
begin
  FRenderManager := RenderManager;
  FTextureBlur := TTextureBlur.Create();
  FTextureBlur.Resolutiondivider := 2;
  FTextureBlur.Iterations := 2;
  FRenderManager.Eventbus.Subscribe(geDraw, BeforeDrawBlur, ctBefore);
end;

destructor TSceneBlurManager.Destroy;
begin
  FRenderManager.Eventbus.Unsubscribe(geDraw, BeforeDrawBlur, ctBefore);
  FTextureBlur.Free;
  inherited;
end;

{ TGFXDEventCallbacks }

constructor TGFXDEventCallbacks.Create;
begin
  Parameterless := TList<ProcGFXDEvent>.Create;
  WithRenderContext := TList<ProcGFXDDrawEvent>.Create;
  WithRenderContextAndIdentifier := TList<ProcGFXDDrawEventWithStage>.Create;
  WithEvent := TList<ProcGFXDEventWithEvent>.Create;
  CustomEvent := TList<ProcGFXDCustomEvent>.Create;
end;

destructor TGFXDEventCallbacks.Destroy;
begin
  Parameterless.Free;
  WithRenderContext.Free;
  WithRenderContextAndIdentifier.Free;
  WithEvent.Free;
  CustomEvent.Free;
  inherited;
end;

{ TGFXDEventManager }

constructor TGFXDEventManager.Create();
begin
  FCallbacks := TObjectDictionary<EnumGFXDEvents, TGFXDEventInformation>.Create([doOwnsValues]);
end;

destructor TGFXDEventManager.Destroy;
begin
  FCallbacks.Free;
  inherited;
end;

procedure TGFXDEventManager.SetEvent(Eventname : EnumGFXDEvents);
var
  Callbackdict : TGFXDEventInformation;
  CallbackInfo : TGFXDEventCallbacks;
  ct : EnumCallbackTime;
  i, j : integer;
begin
  if not FCallbacks.TryGetValue(Eventname, Callbackdict) then
  begin
    Callbackdict := TGFXDEventInformation.Create([doOwnsValues]);
    FCallbacks.Add(Eventname, Callbackdict);
  end;
  for j := 0 to length(CALLBACK_ORDER) - 1 do
  begin
    ct := CALLBACK_ORDER[j];
    if Callbackdict.TryGetValue(ct, CallbackInfo) then
    begin
      for i := 0 to CallbackInfo.Parameterless.Count - 1 do
          CallbackInfo.Parameterless[i]();
      for i := 0 to CallbackInfo.WithEvent.Count - 1 do
          CallbackInfo.WithEvent[i](Eventname);
      for i := 0 to CallbackInfo.WithRenderContext.Count - 1 do
          CallbackInfo.WithRenderContext[i](RenderContext);
    end;
  end;
end;

procedure TGFXDEventManager.SetDrawEvent(Eventname : EnumRenderStage);
var
  Callbackdict : TGFXDEventInformation;
  CallbackInfo : TGFXDEventCallbacks;
  ct : EnumCallbackTime;
  j : integer;
  procedure ExectureCallbacks(Eventname : EnumRenderStage; CallbackInfo : TGFXDEventCallbacks);
  var
    i : integer;
  begin
    for i := 0 to CallbackInfo.Parameterless.Count - 1 do
        CallbackInfo.Parameterless[i]();
    for i := 0 to CallbackInfo.WithEvent.Count - 1 do
        CallbackInfo.WithEvent[i](geDraw);
    for i := 0 to CallbackInfo.WithRenderContext.Count - 1 do
        CallbackInfo.WithRenderContext.Items[i](RenderContext);
    for i := 0 to CallbackInfo.WithRenderContextAndIdentifier.Count - 1 do
        CallbackInfo.WithRenderContextAndIdentifier[i](Eventname, RenderContext);
  end;

begin
  if not FCallbacks.TryGetValue(geDraw, Callbackdict) then
  begin
    Callbackdict := TGFXDEventInformation.Create([doOwnsValues]);
    FCallbacks.Add(geDraw, Callbackdict);
  end;
  for j := 0 to length(CALLBACK_ORDER) - 1 do
  begin
    ct := CALLBACK_ORDER[j];
    if Callbackdict.TryGetValue(ct, CallbackInfo) then
        ExectureCallbacks(Eventname, CallbackInfo);
  end;
end;

procedure TGFXDEventManager.SetEvent(Eventname : EnumGFXDEvents; CustomParameters : array of TValue);
var
  Callbackdict : TGFXDEventInformation;
  CallbackInfo : TGFXDEventCallbacks;
  ct : EnumCallbackTime;
  i, j : integer;
begin
  if not FCallbacks.TryGetValue(Eventname, Callbackdict) then
  begin
    Callbackdict := TGFXDEventInformation.Create([doOwnsValues]);
    FCallbacks.Add(Eventname, Callbackdict);
  end;
  for j := 0 to length(CALLBACK_ORDER) - 1 do
  begin
    ct := CALLBACK_ORDER[j];
    if Callbackdict.TryGetValue(ct, CallbackInfo) then
    begin
      for i := 0 to CallbackInfo.Parameterless.Count - 1 do
          CallbackInfo.Parameterless[i]();
      for i := 0 to CallbackInfo.WithEvent.Count - 1 do
          CallbackInfo.WithEvent[i](Eventname);
      for i := 0 to CallbackInfo.WithRenderContext.Count - 1 do
          CallbackInfo.WithRenderContext[i](RenderContext);
      for i := 0 to CallbackInfo.CustomEvent.Count - 1 do
          CallbackInfo.CustomEvent[i](CustomParameters);
    end;
  end;
end;

procedure TGFXDEventManager.Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEvent; CallbackTime : EnumCallbackTime);
begin
  Subscribe<ProcGFXDEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEventWithStage; CallbackTime : EnumCallbackTime);
begin
  Subscribe<ProcGFXDDrawEventWithStage>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEventWithEvent; CallbackTime : EnumCallbackTime);
begin
  Subscribe<ProcGFXDEventWithEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEvent; CallbackTime : EnumCallbackTime);
begin
  Subscribe<ProcGFXDDrawEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Subscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDCustomEvent; CallbackTime : EnumCallbackTime);
begin
  Subscribe<ProcGFXDCustomEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Subscribe<T>(Eventname : EnumGFXDEvents; proc : T; CallbackTime : EnumCallbackTime);
var
  Callbackdict : TGFXDEventInformation;
  CallbackInfo : TGFXDEventCallbacks;
begin
  if not FCallbacks.TryGetValue(Eventname, Callbackdict) then
  begin
    Callbackdict := TGFXDEventInformation.Create([doOwnsValues]);
    FCallbacks.Add(Eventname, Callbackdict);
  end;
  if not Callbackdict.TryGetValue(CallbackTime, CallbackInfo) then
  begin
    CallbackInfo := TGFXDEventCallbacks.Create();
    Callbackdict.Add(CallbackTime, CallbackInfo);
  end;
  if TypeInfo(T) = TypeInfo(ProcGFXDEvent) then
      CallbackInfo.Parameterless.Add(ProcGFXDEvent(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDEventWithEvent) then
      CallbackInfo.WithEvent.Add(ProcGFXDEventWithEvent(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDDrawEvent) then
      CallbackInfo.WithRenderContext.Add(ProcGFXDDrawEvent(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDDrawEventWithStage) then
      CallbackInfo.WithRenderContextAndIdentifier.Add(ProcGFXDDrawEventWithStage(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDCustomEvent) then
      CallbackInfo.CustomEvent.Add(ProcGFXDCustomEvent(Pointer(@proc)^));
end;

procedure TGFXDEventManager.Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEvent; CallbackTime : EnumCallbackTime);
begin
  Unsubscribe<ProcGFXDEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEventWithStage; CallbackTime : EnumCallbackTime);
begin
  Unsubscribe<ProcGFXDDrawEventWithStage>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDDrawEvent; CallbackTime : EnumCallbackTime);
begin
  Unsubscribe<ProcGFXDDrawEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDEventWithEvent; CallbackTime : EnumCallbackTime);
begin
  Unsubscribe<ProcGFXDEventWithEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Unsubscribe(Eventname : EnumGFXDEvents; proc : ProcGFXDCustomEvent; CallbackTime : EnumCallbackTime);
begin
  Unsubscribe<ProcGFXDCustomEvent>(Eventname, proc, CallbackTime);
end;

procedure TGFXDEventManager.Unsubscribe<T>(Eventname : EnumGFXDEvents; proc : T; CallbackTime : EnumCallbackTime);
var
  Callbackdict : TGFXDEventInformation;
  CallbackInfo : TGFXDEventCallbacks;
begin
  if not FCallbacks.TryGetValue(Eventname, Callbackdict) then
  begin
    Callbackdict := TGFXDEventInformation.Create([doOwnsValues]);
    FCallbacks.Add(Eventname, Callbackdict);
  end;
  if not Callbackdict.TryGetValue(CallbackTime, CallbackInfo) then
  begin
    CallbackInfo := TGFXDEventCallbacks.Create();
    Callbackdict.Add(CallbackTime, CallbackInfo);
  end;
  if TypeInfo(T) = TypeInfo(ProcGFXDEvent) then
      CallbackInfo.Parameterless.Remove(ProcGFXDEvent(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDEventWithEvent) then
      CallbackInfo.WithEvent.Remove(ProcGFXDEventWithEvent(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDDrawEvent) then
      CallbackInfo.WithRenderContext.Remove(ProcGFXDDrawEvent(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDDrawEventWithStage) then
      CallbackInfo.WithRenderContextAndIdentifier.Remove(ProcGFXDDrawEventWithStage(Pointer(@proc)^))
  else if TypeInfo(T) = TypeInfo(ProcGFXDCustomEvent) then
      CallbackInfo.CustomEvent.Remove(ProcGFXDCustomEvent(Pointer(@proc)^));
end;

{ TRenderable }

constructor TRenderable.Create(Scene : TRenderManager; DrawsAtStage : SetRenderStage);
begin
  if not assigned(Scene) then
      FScene := GFXD.MainScene
  else
      FScene := Scene;
  FDrawsAtStage := DrawsAtStage;
  Visible := True;
end;

destructor TRenderable.Destroy;
begin
  Visible := False; // Remove from render queue
  inherited;
end;

function TRenderable.DrawsAtStage : SetRenderStage;
begin
  Result := FDrawsAtStage;
end;

procedure TRenderable.RenderCallback(EventIdentifier : EnumRenderStage; RenderContext : TRenderContext);
begin
  if EventIdentifier in DrawsAtStage then
  begin
    Render(EventIdentifier, RenderContext);
    GFXD.Device3D.ClearRenderState();
    GFXD.Device3D.ClearSamplerStates();
  end;
end;

function TRenderable.Requirements : SetRenderRequirements;
begin
  Result := [];
end;

procedure TRenderable.ResetDrawn;
begin
  FDrawCalls := 0;
  FDrawnTriangles := 0;
end;

procedure TRenderable.SetCallbackTime(const Value : EnumCallbackTime);
begin
  if (FCallbackTime <> Value) and FVisible then
  begin
    FScene.Eventbus.Unsubscribe(geDraw, RenderCallback, FCallbackTime);
    FScene.Eventbus.Subscribe(geDraw, RenderCallback, Value);
  end;
  FCallbackTime := Value;
end;

procedure TRenderable.setVisible(const Value : boolean);
begin
  if FVisible and not Value then
  begin
    // remove from render queue
    FScene.RemoveRenderable(self);
    FScene.Eventbus.Unsubscribe(geDraw, RenderCallback, FCallbackTime);
    FScene.Eventbus.Unsubscribe(geFrameBegin, ResetDrawn);
  end;
  if not FVisible and Value then
  begin
    // add to render queue
    FScene.AddRenderable(self);
    FScene.Eventbus.Subscribe(geDraw, RenderCallback, FCallbackTime);
    FScene.Eventbus.Subscribe(geFrameBegin, ResetDrawn);
  end;
  FVisible := Value;
end;

{ TWorldObject }

constructor TWorldObject.Create(Scene : TRenderManager);
begin
  inherited Create(Scene, [rsWorld]);
end;

procedure TWorldObject.SetPosition(const Value : RVector3);
begin
  FPosition := Value;
end;

{ TTextureBlur }

procedure TTextureBlur.BuildDependencies(RenderContext : TRenderContext);
begin
  if not assigned(FBlurredTexture1) then
      FBlurredTexture1 := RenderContext.CreateFullscreenRendertarget(EnumTextureFormat.tfA8R8G8B8, FResDiv);
  if not assigned(FBlurredTexture2) then
      FBlurredTexture2 := RenderContext.CreateFullscreenRendertarget(EnumTextureFormat.tfA8R8G8B8, FResDiv);
end;

constructor TTextureBlur.Create();
begin
  FKernelsize := 4;
  Resolutiondivider := 1;
  Iterations := 1;
  SampleSpread := 1.0;
  Intensity := 1;
  BilateralRange := 0.46;
  BilateralNormalbias := 0.62;
end;

destructor TTextureBlur.Destroy;
begin
  FShader.Free;
  FBlurredTexture1.Free;
  FBlurredTexture2.Free;
  FAdditiveShader.Free;
  FBilateralShader.Free;
  FAdditiveBilateralShader.Free;
  FScreenQuad.Free;
  FFullscreenQuad.Free;
  inherited;
end;

procedure TTextureBlur.ReleaseDependencies;
begin
  FreeAndNil(FBlurredTexture1);
  FreeAndNil(FBlurredTexture2);
end;

procedure TTextureBlur.RenderBlur(TextureToBeBlurred : TTexture; RenderContext : TRenderContext);
var
  i, Iterations : integer;
  Shader : TShader;
  SpreadX, SpreadY : Single;
begin
  BuildDependencies(RenderContext);
  // blur will often be used in a function, so we want a fixed start
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
  if RenderInput then
  begin
    // only draw the texture to be blurred onto screen
    Shader := self.FShader;
    RenderContext.SetShader(Shader);
    Shader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
    Shader.SetShaderConstant<Single>('intensity', 1.0);
    Shader.SetShaderConstant<Single>('pixelwidth', 0);
    Shader.SetShaderConstant<Single>('pixelheight', 0);
    Shader.SetTexture(tsColor, TextureToBeBlurred);
    Shader.ShaderBegin;
    FFullscreenQuad.Render;
    Shader.ShaderEnd;
    Exit;
  end;

  if Bilateral then
  begin
    if AdditiveBlur then Shader := self.FAdditiveBilateralShader
    else Shader := self.FBilateralShader;
  end
  else
  begin
    if AdditiveBlur then Shader := self.FAdditiveShader
    else Shader := self.FShader;
  end;
  if self.Iterations <= 0 then Exit;
  RenderContext.SetShader(Shader);
  GFXD.Device3D.SetSamplerState(tsColor, tfLinear, amClamp);
  Shader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
  Shader.SetShaderConstant<Single>('intensity', Intensity);
  if Bilateral then
  begin
    Shader.SetShaderConstant<Single>('range', BilateralRange);
    Shader.SetShaderConstant<Single>('normalbias', BilateralNormalbias);
  end;
  SpreadX := SampleSpread;
  if Anamorphic > 0 then
      SpreadX := SpreadX * (1 + Anamorphic);
  SpreadY := SampleSpread;
  if Anamorphic < 0 then
      SpreadY := SpreadY * (1 - Anamorphic);
  Iterations := Max(0, self.Iterations - 1);
  for i := 0 to Iterations do
  begin
    if AdditiveBlur and (i = Iterations) then
    begin
      GFXD.Device3D.ClearRenderState();
    end;
    if i = 0 then Shader.SetTexture(tsColor, TextureToBeBlurred)
    else Shader.SetTexture(tsColor, FBlurredTexture2.Texture);
    if Bilateral then Shader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
    GFXD.Device3D.PushRenderTargets([FBlurredTexture1.Texture.AsRendertarget]);
    // vertical Blur
    Shader.SetShaderConstant<Single>('pixelwidth', (i + 1 + SpreadX) / (GFXD.Settings.Resolution.Width div FResDiv));
    Shader.SetShaderConstant<Single>('pixelheight', 0);
    Shader.ShaderBegin;
    FScreenQuad.Render;
    Shader.ShaderEnd;
    GFXD.Device3D.PopRenderTargets;
    if AdditiveBlur and (i = Iterations) then
    begin
      GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, True);
      GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
      GFXD.Device3D.SetRenderState(rsSRCBLEND, blOne);
      GFXD.Device3D.SetRenderState(rsDESTBLEND, blOne);
    end;
    if i < Iterations then
        GFXD.Device3D.PushRenderTargets([FBlurredTexture2.Texture.AsRendertarget])
    else
    begin
      if UseStencil then
      begin
        GFXD.Device3D.SetRenderState(rsSTENCILENABLE, True);
        GFXD.Device3D.SetRenderState(rsSTENCILREF, 0);
        GFXD.Device3D.SetRenderState(rsSTENCILFUNC, coEqual);
      end;
      if UseAlpha then
      begin
        GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, True);
        GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
        GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
        GFXD.Device3D.SetRenderState(rsDESTBLEND, blInvSrcAlpha);
      end;
    end;
    Shader.SetTexture(tsColor, FBlurredTexture1.Texture);
    if Bilateral then Shader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
    // horizontal Blur
    Shader.SetShaderConstant<Single>('pixelwidth', 0);
    Shader.SetShaderConstant<Single>('pixelheight', (i + 1 + SpreadY) / (GFXD.Settings.Resolution.Height div FResDiv));
    Shader.ShaderBegin;
    if i = Iterations then FFullscreenQuad.Render
    else FScreenQuad.Render;
    Shader.ShaderEnd;
    if i < Iterations then GFXD.Device3D.PopRenderTargets;
  end;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

function TTextureBlur.GetResolutionDivider : integer;
begin
  Result := HMath.Log2Floor(FResDiv) + 1;
end;

procedure TTextureBlur.SetKernelsize(const Value : integer);
begin
  assert(InRange(Value, 0, 4));
  FKernelsize := HMath.Clamp(Value, 0, 4);
  SetResolutionDivider(Resolutiondivider); // update Kernelsize
end;

procedure TTextureBlur.SetResolutionDivider(const Value : integer);
var
  OldResDiv : integer;
begin
  OldResDiv := FResDiv;
  FResDiv := 1 shl (Value - 1);
  if OldResDiv <> FResDiv then
      ReleaseDependencies;
  FShader.Free;
  FShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectGaussianBlur.fx', ['#define KERNELSIZE ' + Inttostr(Kernelsize)]);
  FAdditiveShader.Free;
  FAdditiveShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectGaussianBlur.fx', ['#define ADDITIVE', '#define KERNELSIZE ' + Inttostr(Kernelsize)]);
  FBilateralShader.Free;
  FBilateralShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectGaussianBlur.fx', ['#define KERNELSIZE ' + Inttostr(Kernelsize), '#define BILATERAL']);
  FAdditiveBilateralShader.Free;
  FAdditiveBilateralShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectGaussianBlur.fx', ['#define ADDITIVE', '#define KERNELSIZE ' + Inttostr(Kernelsize), '#define BILATERAL']);
  FScreenQuad.Free;
  FScreenQuad := TScreenQuad.Create(FResDiv);
  FFullscreenQuad.Free;
  FFullscreenQuad := TScreenQuad.Create();
end;

{ TRenderContext }

constructor TRenderContext.Create(Rendertarget : TRendertarget);
begin
  FRenderTarget := Rendertarget;
  FOwnsRenderTarget := False;

  FEventbus := TGFXDEventManager.Create();
  FEventbus.RenderContext := self;
  FEventbus.Subscribe(geResolutionChanged, UpdateResolution);
  FEventbus.Subscribe(geFrameBegin, FrameBegin);

  Lights := TObjectList<TLight>.Create;
  FFullscreenRendertargets := TList<TFullscreenRendertarget>.Create;

  Backgroundcolor := STDHINTERGRUNDFARBE;
  Ambient := STDAMBIENT;
  FDirectionalLights := TUltimateObjectList<TDirectionalLight>.Create;
  FDirectionalLights.Add(TDirectionalLight.Create($FFFFFFFF, RVector3.Create(1, -1, 1)));
  Camera := TCamera.Create(Size);
end;

destructor TRenderContext.Destroy;
begin
  FEventbus.Free;
  FSceneParameter.Free;
  FSceneRendertarget.Free;
  FLightBuffer.Free;
  FBlurredScene.Free;
  FGBuffer.PositionBuffer.Free;
  FGBuffer.Normalbuffer.Free;
  FGBuffer.ColorBuffer.Free;
  FGBuffer.MaterialBuffer.Free;
  FShadowmapping.Free;
  FDirectionalLights.Free;
  Lights.Free;
  FCamera.Free;
  if FOwnsRenderTarget then
      FRenderTargetTexture.Free;
  assert(FFullscreenRendertargets.Count <= 0, 'TRenderContext.Destroy: Fullscreen rendertargets still in use at scene destruction!');
  FFullscreenRendertargets.Free;
  inherited;
end;

function TRenderContext.BackbufferTexture : TTexture;
begin
  Result := nil;
  if FOwnsRenderTarget then
      Result := FRenderTargetTexture;
end;

function TRenderContext.BlurredScene : TTexture;
begin
  if not assigned(FBlurredScene) then
      Result := nil
  else
      Result := FBlurredScene.Texture;
end;

procedure TRenderContext.ChangeResolution(const NewResolution : RIntVector2);
begin
  if (Size <> NewResolution) or not FOwnsRenderTarget then
  begin
    if FOwnsRenderTarget then
        FRenderTargetTexture.Resize(NewResolution);
    Eventbus.SetEvent(geResolutionChanged, [TValue.From<RIntVector2>(NewResolution)]);
  end;
end;

procedure TRenderContext.UpdateExternalRendertarget(const Rendertarget : TRendertarget);
begin
  assert(not FOwnsRenderTarget, 'TRenderContext.ChangeResolution: Rendercontext with own rendertarget handles resizing on its own and should not get an external rendertarget!');
  // apply new rendertarget, old should be already destroyed externally
  FRenderTarget := Rendertarget;
  self.ChangeResolution(FRenderTarget.Size);
end;

procedure TRenderContext.ClearShader;
begin
  AktuellerShaderForciert := False;
end;

function TRenderContext.GetCamera : TCamera;
begin
  Result := FCamera;
end;

function TRenderContext.GetMainDirectionalLight : TDirectionalLight;
var
  i : integer;
begin
  for i := 0 to FDirectionalLights.Count - 1 do
    if FDirectionalLights[i].Enabled then Exit(FDirectionalLights[i]);
  Result := nil;
end;

function TRenderContext.Lightbuffer : TTexture;
begin
  Result := FLightBuffer.Texture;
end;

function TRenderContext.SanitizeFlags(const Flags : SetDefaultShaderFlags) : SetDefaultShaderFlags;
begin
  Result := Flags;

  // lighting and gbuffer is set by GFXD
  Result := Result - [EnumDefaultShaderFlags.sfLighting];
  if GFXD.Settings.Lighting and (sfAllowLighting in Result) then
      Result := Result + [EnumDefaultShaderFlags.sfLighting];
  if DrawGBuffer then
      Result := Result + [EnumDefaultShaderFlags.sfGBuffer];

  if sfGBuffer in Result then
  begin
    // if none is specified draw in all channels
    if [sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawNormal, sfDeferredDrawMaterial] * Result = [] then
        Result := Result + [sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawNormal, sfDeferredDrawMaterial];
    exclude(Result, sfShadowMapping);
  end
  else // without GBuffer we always write the first render target channel
      Result := Result - [sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawNormal, sfDeferredDrawMaterial];

  if not GFXD.Settings.Normalmapping then
      Result := Result - [EnumDefaultShaderFlags.sfNormalmapping];
end;

function TRenderContext.Scene : TTexture;
begin
  Result := FSceneParameter.Texture;
end;

procedure TRenderContext.FrameBegin;
begin
  FCamera.Idle;
end;

procedure TRenderContext.setAmbient(Value : RColor);
begin
  FAmbient := Value;
  GFXD.Device3D.SetRenderState(rsAMBIENT, Value.AsCardinal, True);
end;

function TRenderContext.SetShader(Shader : TShader; Forciert : boolean) : TShader;
begin
  if AktuellerShaderForciert and not Forciert then Exit(AktuellerShader);
  AktuellerShaderForciert := Forciert;
  AktuellerShader := Shader;
  Result := AktuellerShader;
  // set globals
  Result.SetShaderConstant<RVector2>(dcViewportSize, Size);
end;

procedure TRenderContext.SetShadowmapping(Shader : TShader);
begin
  Shader.SetShaderConstant<RVector3>(dcShadowcameraPosition, ShadowMapping.ShadowCamera.Position);
  Shader.SetShaderConstant<RMatrix>(dcShadowView, ShadowMapping.ShadowCamera.View);
  Shader.SetShaderConstant<RMatrix>(dcShadowProj, ShadowMapping.ShadowCamera.Projection);
  Shader.SetShaderConstant<Single>(dcShadowbias, ShadowMapping.Shadowbias);
  Shader.SetShaderConstant<Single>(dcSlopebias, ShadowMapping.Slopebias);
  Shader.SetShaderConstant<Single>(dcShadowpixelwidth, 1 / ShadowMapping.Resolution);
  Shader.SetShaderConstant<Single>(dcShadowStrength, ShadowMapping.Strength);
  Shader.SetTexture(tsVariable3, ShadowMapping.ShadowMap);
end;

constructor TRenderContext.Create(Size : RIntVector2);
begin
  FRenderTargetTexture := TTexture.CreateRendertarget(GFXD.Device3D, Size);
  FRenderTarget := FRenderTargetTexture.AsRendertarget;
  FRenderTarget.NeedsOwnDepthBuffer;
  Create(FRenderTarget);
  FOwnsRenderTarget := True;
end;

function TRenderContext.CreateDefaultShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString) : TShader;
begin
  Result := GFXD.DefaultShaderManager.CreateDefaultShader(SanitizeFlags(Flags), DerivedShader, DEFAULT_SHADER);
end;

function TRenderContext.CreateDefaultShadowShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString) : TShader;
begin
  Result := GFXD.DefaultShaderManager.CreateDefaultShader(SanitizeFlags(Flags), DerivedShader, DEFAULT_SHADOW_SHADER);
end;

function TRenderContext.CreateFullscreenRendertarget(Format : EnumTextureFormat; Resolutiondivider : integer) : TFullscreenRendertarget;
begin
  Result := TFullscreenRendertarget.Create(self, GFXD.Device3D, Format, Resolutiondivider);
end;

function TRenderContext.CreateAndSetDefaultShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString) : TShader;
var
  Shader : TShader;
begin
  Shader := CreateDefaultShader(Flags, DerivedShader);
  SetShader(Shader);
  ApplyGlobalShaderConstants(Shader);
  Result := AktuellerShader;
end;

function TRenderContext.CreateAndSetDefaultShadowShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString) : TShader;
var
  Shader : TShader;
begin
  Shader := CreateDefaultShadowShader(Flags, DerivedShader);
  SetShader(Shader);
  ApplyGlobalShaderConstants(Shader);
  Result := AktuellerShader;
end;

procedure TRenderContext.ApplyGlobalShaderConstants(Shader : TShader);
begin
  // globals
  Shader.SetShaderConstant<RMatrix>(dcView, Camera.View);
  Shader.SetShaderConstant<RMatrix>(dcProjection, Camera.Projection);
  if assigned(MainDirectionalLight) then
  begin
    Shader.SetShaderConstant<RVector3>(dcDirectionalLightDir, -MainDirectionalLight.Direction);
    Shader.SetShaderConstant<RVector4>(dcDirectionalLightColor, MainDirectionalLight.Color);
  end
  else
  begin
    Shader.SetShaderConstant<RVector3>(dcDirectionalLightDir, RVector3.UNITY);
    Shader.SetShaderConstant<RVector4>(dcDirectionalLightColor, RVector4.ZERO);
  end;
  Shader.SetShaderConstant<RVector3>(dcAmbient, Ambient.PremultiplyAlpha.RGB);

  Shader.SetShaderConstant<RVector3>(dcCameraPosition, Camera.Position);
  Shader.SetShaderConstant<RVector3>(dcCameraUp, Camera.ScreenUp);
  Shader.SetShaderConstant<RVector3>(dcCameraLeft, Camera.ScreenLeft);
  Shader.SetShaderConstant<RVector3>(dcCameraDirection, Camera.CameraDirection);
  Shader.SetShaderConstant<RVector2>(dcViewportSize, Size);

  // local
  Shader.SetShaderConstant<Single>(dcAlpha, 1.0);

  Shader.SetShaderConstant<Single>(dcSpecularpower, DEFAULTSPECULARPOWER);
  Shader.SetShaderConstant<Single>(dcSpecularintensity, DEFAULTSPECULARINTENSITY);
end;

function TRenderContext.Size : RIntVector2;
begin
  assert(assigned(FRenderTarget), 'TRenderContext.Size: Rendertarget was not initialized!');
  Result := FRenderTarget.Size;
end;

procedure TRenderContext.UpdateResolution(Values : array of TValue);
var
  NewSize : RIntVector2;
  i : integer;
begin
  NewSize := Values[0].AsType<RIntVector2>;
  FCamera.UpdateResolution(NewSize);
  for i := 0 to FFullscreenRendertargets.Count - 1 do
      FFullscreenRendertargets[i].ChangeResolution(NewSize);
end;

procedure TRenderContext.SetShadowTechnique(const Value : EnumShadowTechnique);
begin
  if Value = stStencil then raise ENotImplemented.Create('Stencilshadows currently (and in near future) not supported!');
  FShadowTechnique := Value;
  ShadowMapping.Enabled := FShadowTechnique = stShadowmapping;
end;

{ TFullscreenRendertarget }

function TFullscreenRendertarget.AsRendertarget : TRendertarget;
begin
  Result := Texture.AsRendertarget;
end;

procedure TFullscreenRendertarget.ChangeResolution(const NewSize : RIntVector2);
begin
  Texture.Resize(NewSize div FResolutionDivider);
end;

constructor TFullscreenRendertarget.Create(Owner : TRenderContext; Device : TDevice; Format : EnumTextureFormat; Resolutiondivider : integer);
begin
  FOwner := Owner;
  FResolutionDivider := Resolutiondivider;
  FTexture := TTexture.CreateRendertarget(Device, Owner.Size div FResolutionDivider, Format);
  Owner.FFullscreenRendertargets.Add(self);
end;

destructor TFullscreenRendertarget.Destroy;
begin
  FTexture.Free;
  FOwner.FFullscreenRendertargets.Extract(self);
  inherited;
end;

{ RGBuffer }

function RGBuffer.PushArray : TArray<TRendertarget>;
begin
  setlength(Result, 4);
  Result[0] := ColorBuffer.Texture.AsRendertarget;
  Result[1] := PositionBuffer.Texture.AsRendertarget;
  Result[2] := Normalbuffer.Texture.AsRendertarget;
  Result[3] := MaterialBuffer.Texture.AsRendertarget;
end;

{ TDefaultShaderManager }

procedure TDefaultShaderManager.AddDefaultShaderToCache(const Flags : SetDefaultShaderFlags; const UID : string; DefaultShader : TShader);
var
  DefaultShaderSubCache : TObjectDictionary<SetDefaultShaderFlags, TShader>;
begin
  if not FDefaultShaderCache.TryGetValue(UID, DefaultShaderSubCache) then
  begin
    DefaultShaderSubCache := TObjectDictionary<SetDefaultShaderFlags, TShader>.Create([doOwnsValues]);
    FDefaultShaderCache.Add(UID, DefaultShaderSubCache);
  end;
  {$IFDEF DEBUG}
  assert(not DefaultShaderSubCache.ContainsKey(Flags) or (DefaultShaderSubCache[Flags] = nil), 'TDefaultShaderManager.AddDefaultShaderToCache: Overriding existing shader!');
  {$ENDIF}
  DefaultShaderSubCache.AddOrSetValue(Flags, DefaultShader);
end;

constructor TDefaultShaderManager.Create;
begin
  FDefaultShaderCache := TObjectDictionary < string, TObjectDictionary < SetDefaultShaderFlags, TShader >>.Create([doOwnsValues]);
  FTasks := TList < IFuture < TCreateShaderTaskData >>.Create;
end;

function TDefaultShaderManager.CreateShaderTaskExecute(Sender : TObject) : TCreateShaderTaskData;
begin
  Result := TCreateShaderTaskData(Sender);
  if length(Result.DerivedShader) > 0 then
  begin
    Result.Shader := TShader.CreateDerivedShader(GFXD.Device3D, Result.DerivedShader, Result.RootShader, [Result.ShaderDefs]);
  end
  else
      Result.Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, Result.RootShader, [Result.ShaderDefs]);
end;

function TDefaultShaderManager.SetDefaultShaderFlagsToArray(const ASet : SetDefaultShaderFlags) : TArray<TArray<SetDefaultShaderFlags>>;
var
  Flag : EnumDefaultShaderFlags;
begin
  Result := nil;
  for Flag in ASet do
  begin
    setlength(Result, length(Result) + 1);
    Result[length(Result) - 1] := TArray<SetDefaultShaderFlags>.Create([Flag]);
  end;
end;

function TDefaultShaderManager.ShaderFlagsToShaderDefines(const Flags : SetDefaultShaderFlags) : string;
const
  CHANNEL_ARRAY : array [0 .. 3] of EnumDefaultShaderFlags = (sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawNormal, sfDeferredDrawMaterial);
var
  Morphtarget : EnumDefaultShaderFlags;
  i, channel : integer;
begin
  Result := '';
  if EnumDefaultShaderFlags.sfDiffuseTexture in Flags then Result := Result + STANDARDSHADERDIFFUSETEXTURE;
  if EnumDefaultShaderFlags.sfLighting in Flags then Result := Result + STANDARDSHADERLIGHTING;
  if EnumDefaultShaderFlags.sfNormalmapping in Flags then Result := Result + STANDARDSHADERNORMALMAPPING;
  if EnumDefaultShaderFlags.sfMaterial in Flags then Result := Result + STANDARDSHADER_MATERIAL;
  if EnumDefaultShaderFlags.sfMaterialTexture in Flags then Result := Result + STANDARDSHADER_MATERIAL_TEXTURE;
  if EnumDefaultShaderFlags.sfSkinning in Flags then Result := Result + STANDARDSHADERSKINNING;
  if EnumDefaultShaderFlags.sfGBuffer in Flags then Result := Result + STANDARDSHADERGBUFFER;
  if EnumDefaultShaderFlags.sfAlphamap in Flags then Result := Result + STANDARDSHADER_ALPHAMAP_TEXCOORDS;
  if EnumDefaultShaderFlags.sfAlphamapTexCoords in Flags then Result := Result + STANDARDSHADERALPHAMAP;
  if EnumDefaultShaderFlags.sfVertexcolor in Flags then Result := Result + STANDARDSHADERVERTEXCOLOR;
  if EnumDefaultShaderFlags.sfColorAdjustment in Flags then Result := Result + STANDARDSHADERCOLORADJUSTMENT;
  if EnumDefaultShaderFlags.sfColorReplacement in Flags then Result := Result + STANDARDSHADER_COLOR_REPLACEMENT;
  if EnumDefaultShaderFlags.sfAbsoluteColorAdjustment in Flags then Result := Result + STANDARDSHADERABSOLUTECOLORADJUSTMENT;
  if EnumDefaultShaderFlags.sfRHW in Flags then Result := Result + STANDARDSHADERRHW;
  if EnumDefaultShaderFlags.sfShadowMapping in Flags then Result := Result + STANDARDSHADERSHADOWMAPPING;
  if EnumDefaultShaderFlags.sfCullAdjustNormal in Flags then Result := Result + STANDARDSHADERCULLNONE;
  if ([sfUseAlpha, sfAlphamap] * Flags <> []) then Result := Result + STANDARDSHADERUSEALPHA;
  if sfAlphaTest in Flags then Result := Result + STANDARDSHADERALPHATEST;
  if EnumDefaultShaderFlags.sfTextureTransform in Flags then Result := Result + STANDARDSHADERTEXTURETRANSFORMS;
  if EnumDefaultShaderFlags.sfDeferredDrawColor in Flags then Result := Result + STANDARDSHADER_DRAW_COLOR;
  if EnumDefaultShaderFlags.sfDeferredDrawPosition in Flags then Result := Result + STANDARDSHADER_DRAW_POSITION;
  if EnumDefaultShaderFlags.sfDeferredDrawNormal in Flags then Result := Result + STANDARDSHADER_DRAW_NORMAL;
  if EnumDefaultShaderFlags.sfDeferredDrawMaterial in Flags then Result := Result + STANDARDSHADER_DRAW_MATERIAL;
  if EnumDefaultShaderFlags.sfForceTexturecoordInput in Flags then Result := Result + STANDARDSHADER_FORCE_TEXTURECOORD_INPUT;
  if EnumDefaultShaderFlags.sfForceNormalmappingInput in Flags then Result := Result + STANDARDSHADER_FORCE_NORMALMAPPING_INPUT;
  if EnumDefaultShaderFlags.sfForceSkinningInput in Flags then Result := Result + STANDARDSHADER_FORCE_SKINNING_INPUT;
  if EnumDefaultShaderFlags.sfCullAdjustNormal in Flags then Result := Result + STANDARDSHADERCULLNONE;
  if SET_MORPHTARGET_SHADERFLAGS * Flags <> [] then
  begin
    Result := Result + STANDARDSHADER_USE_MORPH;
    for Morphtarget := MAX_MORPH_TARGET downto MIN_MORPH_TARGET do
      if Morphtarget in Flags then
      begin
        i := (ord(Morphtarget) - ord(MIN_MORPH_TARGET)) + 1;
        Result := Result + Format(STANDARDSHADER_MORPH_COUNT, [i]);
        break;
      end;
  end;
  channel := 0;
  for i := 0 to length(CHANNEL_ARRAY) - 1 do
  begin
    if CHANNEL_ARRAY[i] in Flags then
    begin
      Result := Result + Format('#define COLOR_%d COLOR%d', [i, channel]) + sLineBreak;
      channel := channel + 1;
    end;
  end;
end;

function TDefaultShaderManager.TryGetCachedDefaultShader(const Flags : SetDefaultShaderFlags; const UID : string; out DefaultShader : TShader) : boolean;
var
  DerivedDefaultShaderCache : TObjectDictionary<SetDefaultShaderFlags, TShader>;
begin
  Result := FDefaultShaderCache.TryGetValue(UID, DerivedDefaultShaderCache) and
    DerivedDefaultShaderCache.TryGetValue(Flags, DefaultShader);
end;

function TDefaultShaderManager.CreateDefaultShader(const Flags : SetDefaultShaderFlags; DerivedShader : AString; RootShader : string) : TShader;
var
  ShaderDefs, UID : string;
  i : integer;
  DerivedShaderUIDStack : AString;
  IsCached, IsFuture : boolean;
begin
  Result := nil;

  // set up all UIDs for the derived shaders
  setlength(DerivedShaderUIDStack, length(DerivedShader) + 1);
  DerivedShaderUIDStack[length(DerivedShaderUIDStack) - 1] := RootShader;
  for i := length(DerivedShaderUIDStack) - 2 downto 0 do
      DerivedShaderUIDStack[i] := DerivedShaderUIDStack[i + 1] + ';' + DerivedShader[(length(DerivedShaderUIDStack) - 2) - i];
  UID := DerivedShaderUIDStack[0];

  // check whether full shader is already available, if not cached, create it
  IsCached := TryGetCachedDefaultShader(Flags, UID, Result);
  IsFuture := IsCached and not assigned(Result);
  if not IsCached or IsFuture then
  begin
    // if in cache is nil, then shader will be available soon
    ShaderDefs := ShaderFlagsToShaderDefines(Flags);

    // if it is a derived shader, create background task for creating it
    if not IsFuture and (length(DerivedShader) > 0) then
        CreateShaderTask(UID, Flags, DerivedShader, RootShader, ShaderDefs);

    // no we search for the best fitting replacement, except first as it is not present
    for i := 1 to length(DerivedShaderUIDStack) - 1 do
      if TryGetCachedDefaultShader(Flags, DerivedShaderUIDStack[i], Result) and assigned(Result) then
          Exit;

    // if we didn't get a fitting replacement, even the root shader is missing
    // so we have to create it synchronous
    Result := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, RootShader, [ShaderDefs]);
    AddDefaultShaderToCache(Flags, RootShader, Result);
  end;
end;

procedure TDefaultShaderManager.CreateShaderTask(const UID : string; const Flags : SetDefaultShaderFlags; DerivedShader : AString; const RootShader, ShaderDefs : string);
var
  TaskData : TCreateShaderTaskData;
begin
  // flag shader as wip with nil
  AddDefaultShaderToCache(Flags, UID, nil);
  TaskData := TCreateShaderTaskData.Create(UID, DerivedShader, RootShader, ShaderDefs, Flags);
  FTasks.Add(TTask.Future<TCreateShaderTaskData>(TaskData, self.CreateShaderTaskExecute))
end;

destructor TDefaultShaderManager.Destroy;
var
  Task : IFuture<TCreateShaderTaskData>;
begin
  for Task in FTasks do
      Task.Cancel;
  FTasks.Free;
  FDefaultShaderCache.Free;
  inherited;
end;

procedure TDefaultShaderManager.PreCompileDefaultShader(const Flags : SetDefaultShaderFlags);
begin
  CreateDefaultShader(Flags, nil, DEFAULT_SHADER);
end;

procedure TDefaultShaderManager.PreCompileDefaultShadowShader(const Flags : SetDefaultShaderFlags);
begin
  CreateDefaultShader(Flags, nil, DEFAULT_SHADOW_SHADER);
end;

procedure TDefaultShaderManager.PreCompileSet(Permutator : TGroupPermutator<SetDefaultShaderFlags>; ShadowShader : boolean);
var
  LastPercent, CurrentPercent : integer;
  Iteration, Permutations, StartTime : int64;
begin
  StartTime := TimeManager.GetTimeStamp;
  Permutations := Permutator.Count;
  if Permutations <= 0 then Exit;
  HLog.Console('Precompile %d default %sshaders.', [Permutations, HGeneric.TertOp<string>(ShadowShader, 'shadow ', '')]);
  // Permutations is used as a bitmask to switch on of flags in a ordered manner
  LastPercent := -1;
  HLog.Console('0%', False);
  Iteration := 0;
  Permutator.Permutate(
    procedure(Permutation : TArray<SetDefaultShaderFlags>)
    var
      i : integer;
      CurrentSet : SetDefaultShaderFlags;
    begin
      CurrentPercent := (Iteration * 100) div (Permutations - 1);
      if CurrentPercent <> LastPercent then
      begin
        LastPercent := CurrentPercent;
        HLog.ClearLineConsole;
        HLog.Console(LastPercent.ToString + '%', False);
      end;

      CurrentSet := [];
      for i := 0 to length(Permutation) - 1 do
          CurrentSet := CurrentSet + Permutation[i];
      if ShadowShader then
          GFXD.DefaultShaderManager.PreCompileDefaultShadowShader(CurrentSet)
      else
          GFXD.DefaultShaderManager.PreCompileDefaultShader(CurrentSet);

      inc(Iteration);
    end
    );

  HLog.ClearLineConsole;
  HLog.Console('100%');
  HLog.Console('- Done in %d ms', [TimeManager.GetTimeStamp - StartTime]);
end;

procedure TDefaultShaderManager.Update;
var
  Future : IFuture<TCreateShaderTaskData>;
  Data : TCreateShaderTaskData;
  i : integer;
begin
  // update status for every thread preloaded completed file
  for i := FTasks.Count - 1 downto 0 do
  begin
    Future := FTasks[i];
    if Future.Status in [TTaskStatus.Completed, TTaskStatus.Canceled, TTaskStatus.Exception] then
    begin
      if Future.Status = TTaskStatus.Completed then
      begin
        Data := Future.Value;
        AddDefaultShaderToCache(Data.Flags, Data.UID, Data.Shader);
      end
      else
          HLog.Write(elWarning, 'TDefaultShaderManager.Update: Failed to complete task. ' + Future.Value.ToString);
      Future.Value.Free;
      FTasks.Delete(i);
    end;
  end;
end;

{ TDefaultShaderManager.TCreateShaderTaskData }

constructor TDefaultShaderManager.TCreateShaderTaskData.Create(const UID : string; DerivedShader : AString; const RootShader, ShaderDefs : string; const Flags : SetDefaultShaderFlags);
begin
  self.UID := UID;
  self.DerivedShader := DerivedShader;
  self.RootShader := RootShader;
  self.ShaderDefs := ShaderDefs;
  self.Flags := Flags;
end;

function TDefaultShaderManager.TCreateShaderTaskData.ToString : string;
begin
  Result := 'UID:' + UID;
  Result := Result + ' RootShader:' + RootShader;
  Result := Result + ' ShaderDefs:' + ShaderDefs;
  Result := Result + ' DerivedShader:' + HString.Join(DerivedShader, ',');
end;

end.
