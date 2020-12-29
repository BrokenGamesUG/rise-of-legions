unit Engine.PostEffects;

interface

uses
  // System
  Math,
  SysUtils,
  Generics.Defaults,
  Generics.Collections,
  // Engine
  Engine.Log,
  Engine.Core,
  Engine.Core.Types,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.VCLUtils,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Serializer,
  Engine.Serializer.Types;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  /// <summary>
  /// A Posteffect is a visual Screen-Space Effect, which will be applied after the scene is rendered.
  /// </summary>
  [XMLExcludeAll]
  TPostEffect = class
    private
      /// <summary> Determines the required data of the post effect </summary>
      FRequiredData : SetRenderRequirements;
      FStage : EnumRenderStage;
      Shader : TShader;
      ScreenQuad : TScreenQuad;
      FEnabled : boolean;
      /// <summary> Can be overriden for dynamic requirements, otherwise uses FRequiredData. </summary>
      function GetRequiredData : SetRenderRequirements; virtual;
      procedure SetEnabled(const Value : boolean);
      function GetEnabled : boolean;
      procedure BuildDependencies(RenderContext : TRenderContext); virtual;
      procedure ReleaseDependencies; virtual;
    protected
      [XMLIncludeElement]
      FUID : string;
      property RenderStage : EnumRenderStage read FStage;
      property RequiredData : SetRenderRequirements read GetRequiredData;
      /// <summary> GFXD puts all required Parameters (from RequiredData) into Render, all other are nil </summary>
      procedure Render(RenderContext : TRenderContext); virtual;
    public
      /// <summary> If the value ist higher its rendered later </summary>
      [XMLIncludeElement]
      RenderOrder : integer;
      /// <summary> Determines whether the Effect will be applied or not </summary>
      [VCLBooleanField]
      [XMLIncludeElement]
      /// <summary> NILSAFE | Determines whether the effect will be applied or not. </summary>
      property Enabled : boolean read GetEnabled write SetEnabled;
      /// <summary> The unique name of this posteffect. </summary>
      property UID : string read FUID;
      constructor Create; virtual;
      destructor Destroy; override;
  end;

  CPostEffect = class of TPostEffect;

  /// <summary> Handles the posteffect-stack. </summary>
  [XMLExcludeAll]
  TPostEffectManager = class(TRenderable)
    private
      [XMLIncludeElement]
      FPostEffects : TObjectDictionary<string, TPostEffect>;
    protected
      /// <summary> Renders all posteffects, which are enabled respecting the order. </summary>
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
    public
      /// <summary> Holds a list of all classes usable with this manager. </summary>
      /// <summary> Create empty. </summary>
      constructor Create(Scene : TRenderManager);
      /// <summary> Create and load an effect stack from a file. If file does not exist, the stack is empty. </summary>
      constructor CreateFromFile(Scene : TRenderManager; EffectsFile : string);
      /// <summary> Adds a posteffect to the stack if UID isn't present, otherwise nothing happens.
      /// Returns whether the effect has been added or not. </summary>
      function TryAdd(UID : string; PostEffect : TPostEffect) : boolean;
      /// <summary> Adds a posteffect to the stack. If UID already exists an error is thrown. </summary>
      procedure Add(UID : string; PostEffect : TPostEffect);
      /// <summary> Returns whether this manager already has this UID. </summary>
      function Contains(UID : string) : boolean;
      /// <summary> Try to get a posteffect by name. </summary>
      function TryGetPostEffect(UID : string; out PostEffect : TPostEffect) : boolean;
      /// <summary> Gets a posteffect by name If name isn't matched nil is returned. </summary>
      function GetPostEffect(UID : string) : TPostEffect;
      /// <summary> Try to get a posteffect by name as type T.. </summary>
      function TryGet<T : TPostEffect>(UID : string; out PostEffect : T) : boolean;
      /// <summary> Gets a posteffect by name as type T. If name isn't matched nil is returned. </summary>
      function Get<T : TPostEffect>(UniqueName : string) : T;
      /// <summary> Returns all posteffects ordered by their renderorder. </summary>
      function ToArray : TArray<TPostEffect>;
      /// <summary> Deletes a posteffect from the stack, with freeing. If name isn't matched nothing happens. </summary>
      procedure Delete(UniqueName : string);
      /// <summary> Removes a posteffect from the stack, without freeing. If name isn't matched nothing happens. </summary>
      function Extract(UniqueName : string) : TPostEffect;
      /// <summary> Clears all effects. </summary>
      procedure Clear;
      /// <summary> The render requirements of all post effects. </summary>
      function Requirements : SetRenderRequirements; override;
      /// <summary> Loads an effect stack from a file. If file does not exist, the stack is untouched. </summary>
      procedure LoadFromFile(EffectsFile : string);
      /// <summary> Saves the effect stack to a file. </summary>
      procedure SaveToFile(EffectsFile : string);
      destructor Destroy; override;
  end;

  /// <summary> Meta class to draw a texture to the screen, used for drawing GBuffer and other special textures. </summary>
  [XMLExcludeAll]
  TPostEffectDrawBuffer = class abstract(TPostEffect)
    protected
      Fullscreen : TScreenQuad;
      procedure RenderBuffer(Texture : TTexture; RenderContext : TRenderContext);
    public
      [XMLIncludeElement]
      [VCLBooleanField]
      DrawFullscreen : boolean;
      function GetRect : RRectFloat;
      constructor Create; override;
      destructor Destroy; override;
  end;

  /// <summary> Draws a set depth buffer. Uses r-Channel for depth. </summary>
  [XMLExcludeAll]
  TPostEffectDrawDepthBuffer = class(TPostEffectDrawBuffer)
    protected
      FDepthBuffer : TTexture;
      procedure Render(RenderContext : TRenderContext); override;
      procedure SetBuffer(Buffer : TTexture);
    public
      [XMLIncludeElement]
      [VCLSingleField(1000)]
      Near, far : single;
      property DepthBuffer : TTexture write SetBuffer;
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectDrawLightbuffer = class(TPostEffectDrawBuffer)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectDrawZGBuffer = class(TPostEffectDrawBuffer)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      [VCLSingleField(1000)]
      Near, far : single;
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectDrawPosition = class(TPostEffectDrawBuffer)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectDrawNormal = class(TPostEffectDrawBuffer)
    public
      type
      EnumSpace = (Worldspace, Screenspace);
    protected
      FSpace : EnumSpace;
      procedure setSpace(const Value : EnumSpace);
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      [VCLEnumField]
      property Space : EnumSpace read FSpace write setSpace;
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectDrawColor = class(TPostEffectDrawBuffer)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectDrawMaterial = class(TPostEffectDrawBuffer)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectEdgeAA = class(TPostEffect)
    private
      procedure setShowEdges(const Value : boolean);
    protected
      FShowEdges : boolean;
      procedure Render(RenderContext : TRenderContext); override;
    public
      [VCLSingleField(10.0)]
      PositionBias : single;
      [VCLSingleField(10.0)]
      NormalBias : single;
      [VCLBooleanField]
      property ShowEdges : boolean read FShowEdges write setShowEdges;
      constructor Create; override;
  end;

  EnumFXAAMode = (fmDither, fmLessDither, fmNoDither);

  [XMLExcludeAll]
  TPostEffectFXAA = class(TPostEffect)
    private
      procedure setMode(const Value : EnumFXAAMode);
      procedure setQuality(const Value : integer);
    protected
      FMode : EnumFXAAMode;
      FQuality : integer;
      FSubPixelQuality, FEdgeThreshold, FEdgeThresholdMin : single;
      procedure BuildShader;
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      [VCLEnumField]
      property Mode : EnumFXAAMode read FMode write setMode;
      [XMLIncludeElement]
      [VCLIntegerField(0, 9)]
      property Quality : integer read FQuality write setQuality;
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      property SubPixelQuality : single read FSubPixelQuality write FSubPixelQuality;
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      property EdgeThreshold : single read FEdgeThreshold write FEdgeThreshold;
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      property EdgeThresholdMin : single read FEdgeThresholdMin write FEdgeThresholdMin;
      constructor Create; override;
  end;

  /// <summary> Metaclass for all effects using a blur. </summary>
  [XMLExcludeAll]
  TPostEffectBlur = class abstract(TPostEffect)
    private
      function GetAdditiveBlur : boolean;
      function GetIntensity : single;
      function GetIterations : integer;
      function GetSampleSpread : single;
      procedure SetAdditiveBlur(const Value : boolean);
      procedure SetIntensity(const Value : single);
      procedure SetIterations(const Value : integer);
      procedure SetSampleSpread(const Value : single);
      function GetResolutionDivider : integer;
      procedure SetResolutionDivider(const Value : integer);
      function GetKernelsize : integer;
      procedure SetKernelsize(const Value : integer);
      function GetAnamorphic : single;
      procedure SetAnamorphic(const Value : single);
      function GetRenderMask : boolean;
      procedure SetRenderMask(const Value : boolean);
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
    protected
      FTextureBlur : TTextureBlur;
    public
      [VCLBooleanField]
      property RenderInput : boolean read GetRenderMask write SetRenderMask;
      [XMLIncludeElement]
      [VCLSingleField(10.0)]
      property Anamorphic : single read GetAnamorphic write SetAnamorphic;
      [XMLIncludeElement]
      [VCLIntegerField(0, 4)]
      property Kernelsize : integer read GetKernelsize write SetKernelsize;
      [XMLIncludeElement]
      [VCLIntegerField(1, 32)]
      property ResolutionDivider : integer read GetResolutionDivider write SetResolutionDivider;
      [XMLIncludeElement]
      [VCLBooleanField]
      property AdditiveBlur : boolean read GetAdditiveBlur write SetAdditiveBlur;
      [XMLIncludeElement]
      [VCLSingleField(5.0)]
      property SampleSpread : single read GetSampleSpread write SetSampleSpread;
      [XMLIncludeElement]
      [VCLIntegerField(1, 32)]
      property Iterations : integer read GetIterations write SetIterations;
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      property Intensity : single read GetIntensity write SetIntensity;
      constructor Create; override;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectBilateralBlur = class abstract(TPostEffectBlur)
    private
      function GetNormalBias : single;
      function GetRange : single;
      procedure SetNormalBias(const Value : single);
      procedure SetRange(const Value : single);
    public
      [XMLIncludeElement]
      [VCLSingleField(5.0)]
      property Range : single read GetRange write SetRange;
      [XMLIncludeElement]
      [VCLSingleField(5.0)]
      property NormalBias : single read GetNormalBias write SetNormalBias;
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectGaussianBlur = class(TPostEffectBlur)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectBilateralGaussianBlur = class(TPostEffectBilateralBlur)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectUnsharpMasking = class(TPostEffectBlur)
    protected
      BlurredScene : TFullscreenRendertarget;
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
      procedure Render(RenderContext : TRenderContext); override;
    public
      /// <summary> Weight of the effect. (e.g. 0.5 = 50%; 1 = 100%) </summary>
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      Amount : single;
      constructor Create; override;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectFog = class(TPostEffect)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      [VCLSingleField(500.0)]
      StartRange, Range : single;
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectColorCorrection = class(TPostEffect)
    protected
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      Shadows : single;
      [XMLIncludeElement]
      [VCLSingleField(2.0)]
      Midtones : single;
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      Lights : single;
      [VCLCallable('Reset levels')]
      procedure ResetLevels;
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectMotionBlur = class(TPostEffect)
    protected
      OldViewProj : RMatrix;
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      Duration : single;
      [XMLIncludeElement]
      [VCLSingleField(10.0)]
      Scale : single;
      constructor Create; override;
  end;

  [XMLExcludeAll]
  TPostEffectToon = class(TPostEffect)
    public type
      EnumToonType = (ttBoth, ttBorder, ttLighting);
    private
      procedure setToonType(const Value : EnumToonType);
      function GetRequiredData : SetRenderRequirements; override;
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
    protected
      BorderShader, MultiplyShader : TShader;
      BlurredScene, BlurredScene2 : TFullscreenRendertarget;
      FToonType : EnumToonType;
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      [VCLRVector3Field(1, 1, 1)]
      BorderColor : RVector3;
      [XMLIncludeElement]
      [VCLIntegerField(1, 10)]
      BorderIterations : integer;
      [XMLIncludeElement]
      [VCLSingleField(32.0)]
      BorderSpread, BorderGradient : single;
      [XMLIncludeElement]
      [VCLSingleField(5.0)]
      Range, NormalBias : single;
      [XMLIncludeElement]
      [VCLSingleField(1.0)]
      LightThreshold, LightOffset, SpecularThreshold, BorderShadingReductionThreshold : single;
      [XMLIncludeElement]
      [VCLEnumField]
      property ToonType : EnumToonType read FToonType write setToonType;
      constructor Create; override;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectSSR = class(TPostEffect)
    protected
      FReflector : TObjectList<TRenderable>;
      procedure Render(RenderContext : TRenderContext); override;
    public
      [XMLIncludeElement]
      Range, alpha : single;
      [XMLIncludeElement]
      raysamples : integer;
      constructor Create; override;
      /// <summary> Add a reflector for this frame</summary>
      procedure AddReflector(Reflector : TRenderable);
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectDistortion = class(TPostEffect)
    protected
      FDistortionTexture : TFullscreenRendertarget;
      procedure Render(RenderContext : TRenderContext); override;
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
    public
      [XMLIncludeElement]
      [VCLSingleField(100)]
      Range : single;
      [VCLBooleanField()]
      RenderMask : boolean;
      constructor Create; override;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectGlow = class(TPostEffectBlur)
    protected
      FGlowTexture : TFullscreenRendertarget;
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
      procedure Render(RenderContext : TRenderContext); override;
    public
      constructor Create; override;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectOutline = class(TPostEffectBlur)
    protected
      FOutlineTexture : TFullscreenRendertarget;
      procedure Render(RenderContext : TRenderContext); override;
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
    public
      constructor Create; override;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectBloom = class(TPostEffectBlur)
    public type
      EnumBloomThresholdType = (btRGB, btLuma, btHSV);
    private
      procedure setBloomThresholdType(const Value : EnumBloomThresholdType);
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
    protected
      FBloomTexture : TFullscreenRendertarget;
      FBloomThresholdType : EnumBloomThresholdType;
      procedure Render(RenderContext : TRenderContext); override;
      procedure BuildShader;
    public
      [XMLIncludeElement]
      [VCLRVector3Field(1, 1, 1)]
      Threshold : RVector3;
      [XMLIncludeElement]
      [VCLRVector3Field(1, 1, 1)]
      ThresholdWidth : RVector3;
      [XMLIncludeElement]
      [VCLEnumField]
      property BloomThresholdType : EnumBloomThresholdType read FBloomThresholdType write setBloomThresholdType;
      constructor Create; override;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TPostEffectSSAO = class(TPostEffectBilateralBlur)
    public
      type
      EnumSSAOType = (SSAO, HBAO, VBAO);
    private
      const
      GOODKERNEL16 : array [0 .. 15] of RVector4 =
        ((x : 0.366818726062775; y : - 0.0179332066327333; z : 0.561907172203064; w : 0),
        (x : 0.175577402114868; y : 0.0478270947933197; z : 0.465164214372635; w : 0),
        (x : 0.569765985012054; y : 0.763443946838379; z : 0.700755953788757; w : 0),
        (x : - 1.05312514305115; y : 1.01253962516785; z : 0.888371527194977; w : 0),
        (x : 0.398969322443008; y : - 0.115835100412369; z : 0.711440205574036; w : 0),
        (x : 1.31234526634216; y : - 0.350987136363983; z : 1.09358584880829; w : 0),
        (x : 0.259323000907898; y : 0.468033581972122; z : 0.477805763483047; w : 0),
        (x : - 1.16028881072998; y : - 0.503920555114746; z : 0.872580528259277; w : 0),
        (x : 0.880132377147675; y : 0.244608506560326; z : 1.26456081867218; w : 0),
        (x : - 0.776650369167328; y : 0.328725516796112; z : 1.19690728187561; w : 0),
        (x : 1.64343166351318; y : - 0.927931547164917; z : 2.80412888526917; w : 0),
        (x : 0.912609100341797; y : - 1.03710222244263; z : 2.23526620864868; w : 0),
        (x : - 0.786364614963531; y : - 2.46781086921692; z : 1.48271417617798; w : 0),
        (x : - 3.1582670211792; y : - 0.667619466781616; z : 0.465798109769821; w : 0),
        (x : 1.07139194011688; y : - 2.4928286075592; z : 0.47812294960022; w : 0),
        (x : 4.51278972625732; y : 0.577045023441315; z : 3.44426870346069; w : 0));

      GOODKERNEL12 : array [0 .. 11] of RVector4 =
        ((x : 0.2396090477705; y : - 0.596452653408051; z : 0.514611482620239; w : 0),
        (x : - 0.437304079532623; y : - 0.367773473262787; z : 0.225122734904289; w : 0),
        (x : 0.762090921401978; y : - 0.564994156360626; z : 0.603042483329773; w : 0),
        (x : 0.0857679694890976; y : - 0.207510530948639; z : 0.432837247848511; w : 0),
        (x : 0.781774520874023; y : - 0.130736380815506; z : 0.128404676914215; w : 0),
        (x : - 0.571028113365173; y : 0.924506545066833; z : 0.454794645309448; w : 0),
        (x : 0.747593343257904; y : 1.49988698959351; z : 1.55433511734009; w : 0),
        (x : - 1.9012885093689; y : 1.40748035907745; z : 1.2490519285202; w : 0),
        (x : 1.24825716018677; y : 0.729442179203033; z : 0.12343668192625; w : 0),
        (x : 0.653742611408234; y : - 3.48671960830688; z : 3.51299333572388; w : 0),
        (x : - 1.56822431087494; y : 0.027000617235899; z : 0.580676317214966; w : 0),
        (x : - 0.81823742389679; y : - 1.96949183940887; z : 1.79024457931519; w : 0));
      GOODKERNEL8 : array [0 .. 7] of RVector4 =
        ((x : 0.303994059562683; y : 0.325205475091934; z : 0.612296938896179; w : 0),
        (x : 0.135105177760124; y : - 0.297892451286316; z : 0.330773144960403; w : 0),
        (x : - 0.514586210250854; y : 0.595961034297943; z : 0.679238379001617; w : 0),
        (x : - 0.0598458498716354; y : 0.081077441573143; z : 0.812211096286774; w : 0),
        (x : - 2.16824245452881; y : - 1.69098520278931; z : 1.83702397346497; w : 0),
        (x : - 1.71352517604828; y : 1.34608793258667; z : 1.47195267677307; w : 0),
        (x : - 0.447821438312531; y : 1.39364218711853; z : 1.42890858650208; w : 0),
        (x : - 4.29382467269897; y : 1.18771171569824; z : 1.76946020126343; w : 0));
      GOODKERNEL8VBAO : array [0 .. 7] of RVector4 =
        ((x : 0.0244180969893932; y : - 0.00231199990957975; z : 0; w : 0),
        (x : - 0.215206384658813; y : 0.05197898671031; z : 0; w : 0),
        (x : - 0.022928761318326; y : 0.0994080230593681; z : 0; w : 0),
        (x : - 0.410313248634338; y : - 0.127432629466057; z : 0; w : 0),
        (x : 0.875497877597809; y : - 0.171614095568657; z : 0; w : 0),
        (x : - 0.452882498502731; y : - 0.282925337553024; z : 0; w : 0),
        (x : 0.280937850475311; y : 0.17204974591732; z : 0; w : 0),
        (x : 0.0537705570459366; y : - 0.0498216450214386; z : 0; w : 0));
      GOODKERNEL4 : array [0 .. 3] of RVector4 =
        ((x : 0.304189532995224; y : 0.311473041772842; z : 0.395771563053131; w : 0),
        (x : - 0.308858752250671; y : - 0.844082355499268; z : 0.635628461837769; w : 0),
        (x : - 0.0113232722505927; y : - 1.72407257556915; z : 1.48316383361816; w : 0),
        (x : 0.321550995111465; y : - 1.13514828681946; z : 3.41874003410339; w : 0));
    var
      function GetResolution : integer;
      procedure SetResolution(Res : integer);
    protected
      UrKernel, Kernel : ARVector4;
      tempSSAOMask, DotNoiseKernel, SSAOMask : TFullscreenRendertarget;
      NoiseKernel : TTexture;
      MultiplyShader, HBAOShader, VBAOShader : TShader;
      DownsampledScreenQuad : TScreenQuad;
      FLowerResolution : integer;
      FSSAOType : EnumSSAOType;
      FRaysamples : integer;
      procedure BuildDependencies(RenderContext : TRenderContext); override;
      procedure ReleaseDependencies; override;
      procedure Render(RenderContext : TRenderContext); override;
      procedure SetSSAOType(Value : EnumSSAOType);
      procedure SetRaySamples(const Value : integer);
    public
      [XMLIncludeElement]
      [VCLBooleanField]
      RenderMask, SphericalKernel, Dotnoise : boolean;
      [XMLIncludeElement]
      [VCLIntegerField(1, 16)]
      AOKernelsize : integer;
      [XMLIncludeElement]
      [VCLIntegerField(1, 64)]
      Noisekernelsize : integer;
      [XMLIncludeElement]
      [VCLSingleField(10)]
      AORange, Darkness : single;
      [VCLSingleField(0.5)]
      JumpMax : single;
      // only HBAO
      [XMLIncludeElement]
      [VCLIntegerField(1, 32)]
      property HBAORaysamples : integer read FRaysamples write SetRaySamples;
      [XMLIncludeElement]
      [VCLEnumField]
      property SSAOType : EnumSSAOType read FSSAOType write SetSSAOType;
      [XMLIncludeElement]
      [VCLIntegerField(0, 16)]
      property AOResolutionDivider : integer read GetResolution write SetResolution;
      constructor Create; override;
      procedure RandomKernel(RenderContext : TRenderContext);
      procedure ScaleKernel;
      procedure SetKernelsize; virtual;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  AvailablePostEffects : TArray<CPostEffect>;

implementation

{ TPostEffectDrawDepthBuffer }

constructor TPostEffectDrawDepthBuffer.Create;
begin
  inherited;;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawDepthBuffer.fx', []);
  near := 0;
  far := 1000;
end;

procedure TPostEffectDrawDepthBuffer.Render(RenderContext : TRenderContext);
begin
  if assigned(FDepthBuffer) then
  begin
    Shader.SetShaderConstant<single>('near', near);
    Shader.SetShaderConstant<single>('far', far);
    RenderBuffer(FDepthBuffer, RenderContext);
  end;
end;

procedure TPostEffectDrawDepthBuffer.SetBuffer(Buffer : TTexture);
begin
  ScreenQuad.Free;
  ScreenQuad := TScreenQuad.Create(RVector2.Create(3 / 4, 0), RVector2.Create(1 / 4));
  FDepthBuffer := Buffer;
end;

{ TPostEffectDrawPosition }

constructor TPostEffectDrawPosition.Create;
begin
  inherited;;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawPosition.fx', []);
  ScreenQuad := TScreenQuad.Create(RVector2.Create(0, 1 / 4), RVector2.Create(1 / 4));
  FRequiredData := [rrGBuffer];
end;

procedure TPostEffectDrawPosition.Render(RenderContext : TRenderContext);
begin
  RenderBuffer(RenderContext.GBuffer.PositionBuffer.Texture, RenderContext);
end;

{ TPostEffectDrawNormal }

constructor TPostEffectDrawNormal.Create;
begin
  inherited;;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawNormal.fx', []);
  ScreenQuad := TScreenQuad.Create(RVector2.Create(0, 1 / 4 * 2), RVector2.Create(1 / 4));
  FRequiredData := [rrGBuffer];
end;

procedure TPostEffectDrawNormal.Render(RenderContext : TRenderContext);
begin
  if Space <> Worldspace then
  begin
    Shader.SetShaderConstant<RVector3>(dcCameraUp, RenderContext.Camera.ScreenUp);
    Shader.SetShaderConstant<RVector3>(dcCameraLeft, RenderContext.Camera.ScreenLeft);
  end;
  RenderBuffer(RenderContext.GBuffer.Normalbuffer.Texture, RenderContext);
end;

procedure TPostEffectDrawNormal.setSpace(const Value : EnumSpace);
begin
  Shader.Free;
  FSpace := Value;
  if Value = Worldspace then Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawNormal.fx', [])
  else Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawNormalSS.fx', []);
end;

{ TPostEffectDrawColor }

constructor TPostEffectDrawColor.Create;
begin
  inherited;;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawColor.fx', []);
  ScreenQuad := TScreenQuad.Create(RVector2.Create(0, 1 / 4 * 3), RVector2.Create(1 / 4));
  FRequiredData := [rrGBuffer];
end;

procedure TPostEffectDrawColor.Render(RenderContext : TRenderContext);
begin
  RenderBuffer(RenderContext.GBuffer.ColorBuffer.Texture, RenderContext);
end;

{ TPostEffectDrawMaterial }

constructor TPostEffectDrawMaterial.Create;
begin
  inherited;;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawColor.fx', []);
  ScreenQuad := TScreenQuad.Create(RVector2.Create(0, 0), RVector2.Create(1 / 4));
  FRequiredData := [rrGBuffer];
end;

procedure TPostEffectDrawMaterial.Render(RenderContext : TRenderContext);
begin
  RenderBuffer(RenderContext.GBuffer.MaterialBuffer.Texture, RenderContext);
end;

{ TPostEffectToonShader }

constructor TPostEffectEdgeAA.Create;
begin
  inherited;
  FStage := rsWorldPostEffects;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectEdgeAA.fx', []);
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrGBuffer, rrScene];
  PositionBias := 0.8;
  NormalBias := 3.1;
end;

procedure TPostEffectEdgeAA.Render(RenderContext : TRenderContext);
begin
  RenderContext.SetShader(Shader);
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  Shader.SetShaderConstant<single>('pixelwidth', 1 / GFXD.Settings.Resolution.Width);
  Shader.SetShaderConstant<single>('pixelheight', 1 / GFXD.Settings.Resolution.Height);
  Shader.SetShaderConstant<single>('positionbias', PositionBias);
  Shader.SetShaderConstant<single>('normalbias', NormalBias);
  Shader.SetTexture(tsColor, RenderContext.GBuffer.PositionBuffer.Texture);
  Shader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
  Shader.SetTexture(tsVariable1, RenderContext.Scene);
  GFXD.Device3D.SetRenderState(EnumRenderState.rsALPHABLENDENABLE, True);
  GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
  GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
  GFXD.Device3D.SetRenderState(rsDESTBLEND, blInvSrcAlpha);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TPostEffectEdgeAA.setShowEdges(const Value : boolean);
var
  define : string;
begin
  FShowEdges := Value;
  Shader.Free;
  if FShowEdges then define := '#define DRAW_EDGES'
  else define := '';
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectEdgeAA.fx', [define])
end;

{ TPostEffectGaussianBlur }

constructor TPostEffectGaussianBlur.Create;
begin
  inherited;
  FRequiredData := [rrScene];
end;

procedure TPostEffectGaussianBlur.Render(RenderContext : TRenderContext);
begin
  FTextureBlur.RenderBlur(RenderContext.Scene, RenderContext);
end;

{ TPostEffectUnsharpMasking }

procedure TPostEffectUnsharpMasking.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  if not assigned(BlurredScene) then
      BlurredScene := RenderContext.CreateFullscreenRendertarget();
end;

constructor TPostEffectUnsharpMasking.Create;
begin
  inherited;;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectUnsharpMasking.fx', []);
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrScene];
  Amount := 0.7;
end;

destructor TPostEffectUnsharpMasking.Destroy;
begin
  BlurredScene.Free;
  inherited;
end;

procedure TPostEffectUnsharpMasking.ReleaseDependencies;
begin
  inherited;
  FreeAndNil(BlurredScene);
end;

procedure TPostEffectUnsharpMasking.Render(RenderContext : TRenderContext);
begin
  inherited;
  // blur scene
  GFXD.Device3D.PushRenderTargets([BlurredScene.asRendertarget]);
  FTextureBlur.RenderBlur(RenderContext.Scene, RenderContext);
  GFXD.Device3D.PopRenderTargets;
  // use blur to sharpen
  RenderContext.SetShader(Shader);
  Shader.SetShaderConstant<single>('amount', Amount);
  Shader.SetTexture(tsColor, RenderContext.Scene);
  Shader.SetTexture(tsNormal, BlurredScene.Texture);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearSamplerStates;
end;

{ TPostEffectFog }

constructor TPostEffectFog.Create;
begin
  inherited;
  FStage := rsWorldPostEffects;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectFog.fx', []);
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrGBuffer];
  StartRange := 0;
  Range := 200;
end;

procedure TPostEffectFog.Render(RenderContext : TRenderContext);
begin
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  RenderContext.SetShader(Shader);
  GFXD.Device3D.SetRenderState(EnumRenderState.rsALPHABLENDENABLE, True);
  GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
  GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
  GFXD.Device3D.SetRenderState(rsDESTBLEND, blInvSrcAlpha);
  Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
  Shader.SetShaderConstant<single>('start_range', StartRange);
  Shader.SetShaderConstant<single>('range', Range);
  Shader.SetShaderConstant<RVector4>('fog_color', RColor($FF808080));
  Shader.SetTexture(tsColor, RenderContext.GBuffer.Normalbuffer.Texture);
  Shader.SetTexture(tsNormal, RenderContext.GBuffer.ColorBuffer.Texture);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

{ TPostEffectMotionBlur }

constructor TPostEffectMotionBlur.Create;
begin
  inherited;;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectMotionBlur.fx', []);
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrGBuffer, rrScene];
  Duration := 0.89;
  Scale := 4.03;
end;

procedure TPostEffectMotionBlur.Render(RenderContext : TRenderContext);
var
  temp : RMatrix;
begin
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  temp := RenderContext.Camera.Projection * RenderContext.Camera.View;
  OldViewProj := (temp * Duration) + (OldViewProj * (1 - Duration));
  if (temp - OldViewProj).AbsSum < 0.001 then exit;
  RenderContext.SetShader(Shader);
  Shader.SetShaderConstant<RMatrix>('Projection', RenderContext.Camera.Projection);
  Shader.SetShaderConstant<RMatrix>('oldViewProj', OldViewProj);
  Shader.SetShaderConstant<single>('scale', Scale);
  Shader.SetShaderConstant<single>('pixelwidth', 1.0 / RenderContext.Size.Width);
  Shader.SetShaderConstant<single>('pixelheight', 1.0 / RenderContext.Size.Height);
  Shader.SetTexture(tsColor, RenderContext.GBuffer.PositionBuffer.Texture);
  Shader.SetTexture(tsVariable1, RenderContext.GBuffer.ColorBuffer.Texture);
  Shader.SetTexture(tsNormal, RenderContext.Scene);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

{ TPostEffectToon }

procedure TPostEffectToon.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  if not assigned(BlurredScene) then
      BlurredScene := RenderContext.CreateFullscreenRendertarget();
  if not assigned(BlurredScene2) then
      BlurredScene2 := RenderContext.CreateFullscreenRendertarget();
end;

constructor TPostEffectToon.Create;
begin
  inherited;
  FStage := rsWorldPostEffects;
  BorderShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectBlackBorder.fx', []);
  ScreenQuad := TScreenQuad.Create();
  BorderIterations := 2;
  BorderSpread := 1.0;
  Range := 1.06;
  NormalBias := 0.74;
  BorderGradient := 3.0;
  ToonType := ttBoth;
  LightThreshold := 0.707;
  LightOffset := 0.7;
  SpecularThreshold := 0.7;
  BorderShadingReductionThreshold := 0.9;
end;

destructor TPostEffectToon.Destroy;
begin
  BorderShader.Free;
  BlurredScene.Free;
  BlurredScene2.Free;
  inherited;
end;

function TPostEffectToon.GetRequiredData : SetRenderRequirements;
begin
  case ToonType of
    ttBoth : Result := [rrGBuffer, rrLightbuffer];
    ttBorder : Result := [rrScene, rrGBuffer];
    ttLighting : Result := [rrGBuffer, rrLightbuffer];
  else
    HLog.ProcessError(False, 'TPostEffectToon.GetRequiredData: Unkown Toontype!', ENotImplemented);
  end;
end;

procedure TPostEffectToon.ReleaseDependencies;
begin
  inherited;
  FreeAndNil(BlurredScene);
  FreeAndNil(BlurredScene2);
end;

procedure TPostEffectToon.Render(RenderContext : TRenderContext);
var
  i : integer;
begin
  inherited;
  if ToonType <> ttLighting then
  begin
    GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
    GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
    GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
    GFXD.Device3D.SetSamplerState(tsVariable2, tfPoint, amClamp);
    RenderContext.SetShader(BorderShader);
    BorderShader.SetShaderConstant<single>('border_threshold', BorderShadingReductionThreshold);
    BorderShader.SetShaderConstant<single>('range', Range);
    BorderShader.SetShaderConstant<single>('normalbias', NormalBias);
    GFXD.Device3D.PushRenderTargets([BlurredScene2.asRendertarget]);
    GFXD.Device3D.Clear([cfTarget], $00FFFFFF, 1, 0);
    GFXD.Device3D.PopRenderTargets;
    for i := 0 to BorderIterations - 1 do
    begin
      BorderShader.SetTexture(tsColor, BlurredScene2.Texture);
      BorderShader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
      BorderShader.SetTexture(tsVariable2, RenderContext.GBuffer.MaterialBuffer.Texture);
      GFXD.Device3D.PushRenderTargets([BlurredScene.asRendertarget]);
      // vertical Blur
      BorderShader.SetShaderConstant<single>('pixelwidth', BorderSpread / RenderContext.Size.Width);
      BorderShader.SetShaderConstant<single>('pixelheight', 0);
      BorderShader.ShaderBegin;
      ScreenQuad.Render;
      BorderShader.ShaderEnd;
      GFXD.Device3D.PopRenderTargets;
      GFXD.Device3D.PushRenderTargets([BlurredScene2.asRendertarget]);
      BorderShader.SetTexture(tsColor, BlurredScene.Texture);
      BorderShader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
      // horizontal Blur
      BorderShader.SetShaderConstant<single>('pixelwidth', 0);
      BorderShader.SetShaderConstant<single>('pixelheight', BorderSpread / RenderContext.Size.Height);
      BorderShader.ShaderBegin;
      ScreenQuad.Render;
      BorderShader.ShaderEnd;
      GFXD.Device3D.PopRenderTargets;
    end;
  end;
  RenderContext.SetShader(Shader);
  Shader.SetShaderConstant<RVector3>('border_color', BorderColor);
  Shader.SetShaderConstant<single>('border_gradient', BorderGradient);
  Shader.SetShaderConstant<single>('light_threshold', LightThreshold);
  Shader.SetShaderConstant<single>('light_offset', LightOffset);
  Shader.SetShaderConstant<single>('specular_threshold', SpecularThreshold);
  if ToonType = ttBorder then Shader.SetTexture(tsColor, RenderContext.Scene)
  else Shader.SetTexture(tsColor, RenderContext.GBuffer.ColorBuffer.Texture);
  if ToonType <> ttLighting then Shader.SetTexture(tsNormal, BlurredScene2.Texture);
  if ToonType <> ttBorder then Shader.SetTexture(tsVariable1, RenderContext.Lightbuffer);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TPostEffectToon.setToonType(const Value : EnumToonType);
var
  define : string;
begin
  FToonType := Value;
  Shader.Free;
  case FToonType of
    ttBorder : define := '#define NO_LIGHTING';
    ttLighting : define := '#define NO_BORDER';
  else
    define := '';
  end;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectToon.fx', [define]);
end;

{ TPostEffectSSAO }

procedure TPostEffectSSAO.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  if not assigned(SSAOMask) then
      SSAOMask := RenderContext.CreateFullscreenRendertarget();
  if not assigned(tempSSAOMask) then
      tempSSAOMask := RenderContext.CreateFullscreenRendertarget(tfA8R8G8B8, FLowerResolution);
  if (not Dotnoise and not assigned(NoiseKernel)) or (Dotnoise and not assigned(DotNoiseKernel)) then
  begin
    if Dotnoise then
        DotNoiseKernel := RenderContext.CreateFullscreenRendertarget(EnumTextureFormat.tfA16B16G16R16F)
    else
        NoiseKernel := TTexture.CreateTexture(Noisekernelsize, Noisekernelsize, 1, [usWriteable], EnumTextureFormat.tfA16B16G16R16F, GFXD.Device3D);
    RandomKernel(RenderContext);
  end;
end;

constructor TPostEffectSSAO.Create;
begin
  inherited;
  FStage := rsWorldPostEffects;
  AOKernelsize := 8;
  Noisekernelsize := 4;
  HBAORaysamples := 4;
  SphericalKernel := True;
  Dotnoise := False;
  AORange := 3.0;
  Darkness := 1.7;
  JumpMax := 0.05;
  SSAOType := VBAO;
  RenderMask := False;
  SetResolution(0);
  SetKernelsize;
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrGBuffer, rrScene];
  MultiplyShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectMultiply.fx', []);
end;

destructor TPostEffectSSAO.Destroy;
begin
  DownsampledScreenQuad.Free;
  MultiplyShader.Free;
  tempSSAOMask.Free;
  NoiseKernel.Free;
  DotNoiseKernel.Free;
  SSAOMask.Free;
  HBAOShader.Free;
  VBAOShader.Free;
  inherited;
end;

function TPostEffectSSAO.GetResolution : integer;
begin
  Result := HMath.Log2Floor(FLowerResolution);
end;

procedure TPostEffectSSAO.RandomKernel(RenderContext : TRenderContext);
var
  x, y, i : integer;
  temp : RVector4;
  save : RVector4Half;
  ran : single;
  UsedNoiseKernel : TTexture;
begin
  if Dotnoise then
      UsedNoiseKernel := DotNoiseKernel.Texture
  else
      UsedNoiseKernel := NoiseKernel;

  UsedNoiseKernel.Lock;
  for x := 0 to (HGeneric.TertOp<integer>(Dotnoise, RenderContext.Size.Width, Noisekernelsize)) - 1 do
    for y := 0 to HGeneric.TertOp<integer>(Dotnoise, RenderContext.Size.Height, Noisekernelsize) - 1 do
    begin
      case FSSAOType of
        SSAO : temp := RVector4.Create(random * 2 - 1, random * 2 - 1, random * 2 - 1, 0).Normalize;
        HBAO, VBAO :
          begin
            ran := random * 2 * PI;
            temp := RVector4.Create(cos(ran), sin(ran), random * 0.5 + 0.5, 0);
          end;
      end;
      save.x := temp.x;
      save.y := temp.y;
      save.z := temp.z;
      save.w := temp.w;
      UsedNoiseKernel.setTexel<RVector4Half>(x, y, save);
    end;
  UsedNoiseKernel.Unlock;
  for i := 0 to HGeneric.TertOp<integer>(FSSAOType = HBAO, AOKernelsize div 2, AOKernelsize) - 1 do
  begin
    case FSSAOType of
      SSAO : UrKernel[i] := RVector4.Create(random * 2 - 1, random * 2 - 1, random, 0).Normalize;
      HBAO : UrKernel[i] := RVector4.Create(cos((i / (AOKernelsize div 2)) * PI * 2), sin((i / (AOKernelsize div 2)) * PI * 2), 0, 0);
      VBAO : UrKernel[i] := RVector4.Create(random * 2 - 1, random * 2 - 1, 0, 0).Normalize * random;
    end;
    Kernel[i] := UrKernel[i];
  end;
end;

procedure TPostEffectSSAO.ScaleKernel;
var
  i : integer;
  Scale : single;
  temp : RVector4;
begin
  for i := 0 to HGeneric.TertOp<integer>(FSSAOType = HBAO, AOKernelsize div 2, AOKernelsize) - 1 do
  begin
    case FSSAOType of
      SSAO :
        begin
          Scale := i / (AOKernelsize - 1);
          Scale := Scale * Scale * 0.9 + 0.1;
          if AOKernelsize = 16 then temp := GOODKERNEL16[i] * (1 / Scale) * 0.2
          else if AOKernelsize = 12 then temp := GOODKERNEL12[i] * (1 / Scale) * 0.2
          else if AOKernelsize = 8 then temp := GOODKERNEL8[i] * (1 / Scale) * 0.2
          else if AOKernelsize = 4 then temp := GOODKERNEL4[i] * (1 / Scale) * 0.2
          else temp := UrKernel[i];
          Kernel[i] := temp * Scale * (AORange);
          if SphericalKernel then
          begin
            Kernel[i] := Kernel[i] * ((Kernel[i].xyz.Dot(RVector3.Create(0, 0, 1))) / Kernel[i].xyz.Length);
          end;
        end;
      HBAO : Kernel[i] := UrKernel[i] * ((AORange / 2.0) / HBAORaysamples);
      VBAO :
        begin
          if AOKernelsize = 8 then temp := GOODKERNEL8VBAO[i]
          else temp := UrKernel[i];
          Kernel[i] := temp;
          // x,y:Offset z:Pipelength/2
          Kernel[i].z := (AORange / 2.0) * sqrt(1 - HMath.clamp(sqr(Kernel[i].x) + sqr(Kernel[i].y), 0, 1));
          Kernel[i].x := Kernel[i].x * AORange / 2.0;
          Kernel[i].y := Kernel[i].y * AORange / 2.0;
        end;
    end;
  end;
end;

procedure TPostEffectSSAO.ReleaseDependencies;
begin
  inherited;
  FreeAndNil(SSAOMask);
  FreeAndNil(tempSSAOMask);
  FreeAndNil(NoiseKernel);
  FreeAndNil(DotNoiseKernel);
end;

procedure TPostEffectSSAO.Render(RenderContext : TRenderContext);
var
  Shader : TShader;
begin
  inherited;
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable2, tfPoint, amClamp);

  ScaleKernel;
  Shader := nil;
  case FSSAOType of
    SSAO : Shader := Self.Shader;
    HBAO : Shader := HBAOShader;
    VBAO : Shader := VBAOShader;
  end;
  RenderContext.SetShader(Shader);
  Shader.SetShaderConstant<RMatrix>('ViewProjection', RenderContext.Camera.Projection * RenderContext.Camera.View);
  if SSAOType = VBAO then Shader.SetShaderConstant<RMatrix>('Projection', RenderContext.Camera.Projection);
  Shader.SetShaderConstant<RMatrix>('Projection', RenderContext.Camera.Projection);
  Shader.SetShaderConstant<RVector3>('CameraPosition', RenderContext.Camera.Position);
  Shader.SetShaderConstantArray<RVector4>('Kernel', Kernel);
  Shader.SetShaderConstant<single>('range', AORange);
  Shader.SetShaderConstant<single>('JumpMax', JumpMax);
  if Dotnoise then
  begin
    Shader.SetShaderConstant<single>('width', 1.0);
    Shader.SetShaderConstant<single>('height', 1.0);
  end
  else
  begin
    Shader.SetShaderConstant<single>('width', (1.0 * (RenderContext.Size.Width div FLowerResolution)) / Noisekernelsize);
    Shader.SetShaderConstant<single>('height', (1.0 * (RenderContext.Size.Height div FLowerResolution)) / Noisekernelsize);
  end;
  Shader.SetTexture(tsColor, RenderContext.GBuffer.PositionBuffer.Texture);
  Shader.SetTexture(tsNormal, RenderContext.GBuffer.Normalbuffer.Texture);
  Shader.SetTexture(tsVariable1, RenderContext.GBuffer.ColorBuffer.Texture);
  if Dotnoise then
      Shader.SetTexture(tsVariable2, DotNoiseKernel.Texture)
  else
      Shader.SetTexture(tsVariable2, NoiseKernel);
  GFXD.Device3D.ClearRenderState();

  // Render SSAO Mask
  GFXD.Device3D.PushRenderTargets([tempSSAOMask.asRendertarget]);
  GFXD.Device3D.Clear([cfTarget], $00FFFFFF, 1, 0);
  Shader.ShaderBegin;
  DownsampledScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.PopRenderTargets;

  // Blur SSAO Mask
  if not RenderMask then GFXD.Device3D.PushRenderTargets([SSAOMask.asRendertarget]);
  FTextureBlur.RenderBlur(tempSSAOMask.Texture, RenderContext);
  if not RenderMask then GFXD.Device3D.PopRenderTargets;

  if not RenderMask then
  begin
    RenderContext.SetShader(MultiplyShader);
    MultiplyShader.SetShaderConstant<RMatrix>('Projection', RenderContext.Camera.Projection);
    MultiplyShader.SetShaderConstant<single>('darkness', HGeneric.TertOp<single>(FSSAOType = HBAO, Darkness / 2, Darkness));
    MultiplyShader.SetTexture(tsColor, RenderContext.Scene);
    MultiplyShader.SetTexture(tsNormal, SSAOMask.Texture);
    MultiplyShader.SetTexture(tsVariable1, RenderContext.GBuffer.ColorBuffer.Texture);
    MultiplyShader.ShaderBegin;
    ScreenQuad.Render;
    MultiplyShader.ShaderEnd;
  end;
  GFXD.Device3D.ClearSamplerStates;
  GFXD.Device3D.ClearRenderState();
end;

procedure TPostEffectSSAO.SetKernelsize;
begin
  Shader.Free;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectSSAO.fx', ['#define KERNELSIZE ' + Inttostr(AOKernelsize), '#define NOISEKERNELSIZE ' + Inttostr(Noisekernelsize)]);
  HBAOShader.Free;
  HBAOShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectHBAO.fx', ['#define KERNELSIZE ' + Inttostr(AOKernelsize div 2), '#define NOISEKERNELSIZE ' + Inttostr(Noisekernelsize), '#define SAMPLES ' + Inttostr(HBAORaysamples)]);
  VBAOShader.Free;
  VBAOShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectVBAO.fx', ['#define KERNELSIZE ' + Inttostr(AOKernelsize), '#define NOISEKERNELSIZE ' + Inttostr(Noisekernelsize)]);
  SetLength(Kernel, HGeneric.TertOp<integer>(FSSAOType = HBAO, AOKernelsize div 2, AOKernelsize));
  SetLength(UrKernel, HGeneric.TertOp<integer>(FSSAOType = HBAO, AOKernelsize div 2, AOKernelsize));
  FreeAndNil(NoiseKernel);
end;

procedure TPostEffectSSAO.SetRaySamples(const Value : integer);
begin
  if Value <> FRaysamples then
  begin
    FRaysamples := Value;
    SetKernelsize;
  end;
end;

procedure TPostEffectSSAO.SetResolution(Res : integer);
var
  OldLowerRes : integer;
begin
  OldLowerRes := FLowerResolution;
  FLowerResolution := 1 shl Res;
  if OldLowerRes <> FLowerResolution then
      ReleaseDependencies;
  DownsampledScreenQuad.Free;
  DownsampledScreenQuad := TScreenQuad.Create(FLowerResolution);
end;

procedure TPostEffectSSAO.SetSSAOType(Value : EnumSSAOType);
begin
  if Value <> FSSAOType then
  begin
    FSSAOType := Value;
    SetKernelsize;
  end;
end;

{ TPostEffectBilateralGaussianBlur }

constructor TPostEffectBilateralGaussianBlur.Create;
begin
  inherited;
  FStage := rsWorldPostEffects;
  FRequiredData := [rrScene, rrGBuffer];
end;

procedure TPostEffectBilateralGaussianBlur.Render(RenderContext : TRenderContext);
begin
  FTextureBlur.RenderBlur(RenderContext.Scene, RenderContext);
end;

{ TPostEffectDrawBuffer }

constructor TPostEffectDrawBuffer.Create;
begin
  inherited;
  Fullscreen := TScreenQuad.Create();
end;

destructor TPostEffectDrawBuffer.Destroy;
begin
  Fullscreen.Free;
  inherited;
end;

function TPostEffectDrawBuffer.GetRect : RRectFloat;
begin
  Result := Self.ScreenQuad.ScreenRect;
end;

procedure TPostEffectDrawBuffer.RenderBuffer(Texture : TTexture; RenderContext : TRenderContext);
begin
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  RenderContext.SetShader(Shader);
  Shader.SetShaderConstant<RMatrix>('View', RenderContext.Camera.View);
  Shader.SetShaderConstant<RMatrix>('Projection', RenderContext.Camera.Projection);
  Shader.SetTexture(tsColor, Texture);
  Shader.ShaderBegin;
  if DrawFullscreen then Fullscreen.Render
  else ScreenQuad.Render;
  Shader.ShaderEnd;
end;

{ TPostEffectDrawLightbuffer }

constructor TPostEffectDrawLightbuffer.Create;
begin
  inherited;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PostEffectDrawColor.fx', []);
  ScreenQuad := TScreenQuad.Create(RVector2.Create(3 / 4, 0), RVector2.Create(1 / 4));
  FRequiredData := [rrLightbuffer];
end;

procedure TPostEffectDrawLightbuffer.Render(RenderContext : TRenderContext);
begin
  RenderBuffer(RenderContext.Lightbuffer, RenderContext);
end;

{ TPostEffectDrawZGBuffer }

constructor TPostEffectDrawZGBuffer.Create;
begin
  inherited;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDrawZGBuffer.fx', []);
  ScreenQuad := TScreenQuad.Create(RVector2.Create(0, 0), RVector2.Create(1 / 4));
  FRequiredData := [rrGBuffer];
  near := 0;
  far := 230;
end;

procedure TPostEffectDrawZGBuffer.Render(RenderContext : TRenderContext);
begin
  Shader.SetShaderConstant<single>('near', near);
  Shader.SetShaderConstant<single>('far', far);
  RenderBuffer(RenderContext.GBuffer.Normalbuffer.Texture, RenderContext);
end;

{ TPostEffectSSR }

procedure TPostEffectSSR.AddReflector(Reflector : TRenderable);
begin
  if not Enabled then exit;
  FReflector.Add(Reflector);
end;

constructor TPostEffectSSR.Create;
begin
  inherited;
  Range := 5.0;
  raysamples := 10;
  alpha := 0.3;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectSSR.fx', []);
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrGBuffer, rrScene];
  FReflector := TObjectList<TRenderable>.Create(False);
end;

destructor TPostEffectSSR.Destroy;
begin
  FReflector.Free;
  inherited;
end;

procedure TPostEffectSSR.Render(RenderContext : TRenderContext);
begin
  exit; // Not implemented

  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable2, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable3, tfPoint, amClamp);
  RenderContext.SetShader(Shader, True);
  GFXD.Device3D.SetRenderState(EnumRenderState.rsALPHABLENDENABLE, 1);
  Shader.SetShaderConstant<single>('raysamples', raysamples);
  Shader.SetShaderConstant<single>('range', Range);
  Shader.SetShaderConstant<single>('width', GFXD.Settings.Resolution.Width);
  Shader.SetShaderConstant<single>('height', GFXD.Settings.Resolution.Height);
  Shader.SetShaderConstant<single>('alpha', alpha);
  Shader.SetShaderConstant<RVector4>('bgcolor', RenderContext.Backgroundcolor);
  Shader.SetShaderConstant<RVector3>('CameraPosition', RenderContext.Camera.Position);
  Shader.SetShaderConstant<RMatrix>('ViewProj', RenderContext.Camera.Projection * RenderContext.Camera.View);
  Shader.SetTexture(tsVariable1, RenderContext.GBuffer.PositionBuffer.Texture);
  Shader.SetTexture(tsVariable2, RenderContext.GBuffer.Normalbuffer.Texture);
  Shader.SetTexture(tsVariable3, RenderContext.Scene);

  // render

  RenderContext.ClearShader;
  GFXD.Device3D.ClearRenderState();
  FReflector.Clear;
  GFXD.Device3D.ClearSamplerStates;
end;

{ TPostEffectDistortion }

procedure TPostEffectDistortion.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  if not assigned(FDistortionTexture) then
      FDistortionTexture := RenderContext.CreateFullscreenRendertarget();
end;

constructor TPostEffectDistortion.Create;
begin
  inherited;
  FStage := rsPostEffects;
  Range := 10;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectDistortion.fx', []);
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrScene];
end;

destructor TPostEffectDistortion.Destroy;
begin
  FDistortionTexture.Free;
  inherited;
end;

procedure TPostEffectDistortion.ReleaseDependencies;
begin
  inherited;
  FreeAndNil(FDistortionTexture);
end;

procedure TPostEffectDistortion.Render(RenderContext : TRenderContext);
var
  Shader : TShader;
begin
  inherited;
  // Prepare distortion buffer
  GFXD.Device3D.PushRenderTargets([FDistortionTexture.asRendertarget]);
  GFXD.Device3D.Clear([cfTarget], $008080FF, 1, 0);

  RenderContext.Eventbus.SetDrawEvent(rsDistortion);

  GFXD.Device3D.PopRenderTargets;

  Shader := RenderContext.SetShader(Self.Shader);
  if RenderMask then
  begin
    // render mask
    Shader.SetShaderConstant<single>('rangex', 0);
    Shader.SetShaderConstant<single>('rangey', 0);
    Shader.SetTexture(tsColor, FDistortionTexture.Texture);
  end
  else
  begin
    // now apply distortion
    Shader.SetShaderConstant<single>('rangex', -Range / GFXD.Settings.Resolution.Width);
    Shader.SetShaderConstant<single>('rangey', -Range / GFXD.Settings.Resolution.Height);
    Shader.SetTexture(tsColor, RenderContext.Scene);
  end;
  GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amMirror);
  Shader.SetTexture(tsNormal, FDistortionTexture.Texture);
  Shader.SetShaderConstant<RMatrix>('Projection', RenderContext.Camera.Projection);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;

  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

{ TPostEffectGlow }

procedure TPostEffectGlow.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  if not assigned(FGlowTexture) then
      FGlowTexture := RenderContext.CreateFullscreenRendertarget();
end;

constructor TPostEffectGlow.Create;
begin
  inherited;
  FStage := rsPostEffects;
  FTextureBlur.AdditiveBlur := True;
  FTextureBlur.Intensity := 0.5;
end;

destructor TPostEffectGlow.Destroy;
begin
  FGlowTexture.Free;
  inherited;
end;

procedure TPostEffectGlow.ReleaseDependencies;
begin
  inherited;
  FreeAndNil(FGlowTexture);
end;

procedure TPostEffectGlow.Render(RenderContext : TRenderContext);
begin
  inherited;
  // Prepare glowing buffer
  GFXD.Device3D.PushRenderTargets([FGlowTexture.asRendertarget]);
  GFXD.Device3D.Clear([cfTarget], $00000000, 1, 0);
  // we don't want any object to alter z information of our scene
  GFXD.Device3D.SetRenderState(rsZWRITEENABLE, False, True);
  // same objects will be overdrawn, so it has to be passed by the z-test
  GFXD.Device3D.SetRenderState(rsZFUNC, coLessEqual, True);

  RenderContext.Eventbus.SetDrawEvent(rsGlow);

  GFXD.Device3D.ClearRenderState(rsZWRITEENABLE);
  GFXD.Device3D.ClearRenderState(rsZFUNC);
  GFXD.Device3D.PopRenderTargets;
  // blur glowing buffer
  FTextureBlur.RenderBlur(FGlowTexture.Texture, RenderContext);
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

{ TPostEffectManager }

constructor TPostEffectManager.CreateFromFile(Scene : TRenderManager; EffectsFile : string);
begin
  Create(Scene);
  LoadFromFile(EffectsFile);
end;

procedure TPostEffectManager.Clear;
begin
  FPostEffects.Clear;
end;

function TPostEffectManager.Contains(UID : string) : boolean;
begin
  Result := FPostEffects.ContainsKey(UID);
end;

procedure TPostEffectManager.LoadFromFile(EffectsFile : string);
begin
  if HFilePathManager.FileExists(EffectsFile) then
      HXMLSerializer.LoadObjectFromFile(Self, AbsolutePath(EffectsFile));
end;

procedure TPostEffectManager.SaveToFile(EffectsFile : string);
begin
  HXMLSerializer.SaveObjectToFile(Self, EffectsFile);
end;

function TPostEffectManager.ToArray : TArray<TPostEffect>;
begin
  Result := FPostEffects.Values.ToArray;
  TArray.Sort<TPostEffect>(Result, TComparer<TPostEffect>.Construct(
    function(const Left, Right : TPostEffect) : integer
    begin
      Result := Left.RenderOrder - Right.RenderOrder;
    end));
end;

function TPostEffectManager.TryAdd(UID : string; PostEffect : TPostEffect) : boolean;
begin
  if FPostEffects.ContainsKey(UID) then Result := False
  else
  begin
    Add(UID, PostEffect);
    Result := True;
  end;
end;

function TPostEffectManager.TryGet<T>(UID : string; out PostEffect : T) : boolean;
var
  PE : TPostEffect;
begin
  Result := FPostEffects.TryGetValue(UID, PE);
  if Result and (PE is T) then PostEffect := PE as T
  else Result := False;
end;

function TPostEffectManager.Get<T>(UniqueName : string) : T;
begin
  if not TryGet<T>(UniqueName, Result) then Result := nil;
end;

function TPostEffectManager.TryGetPostEffect(UID : string; out PostEffect : TPostEffect) : boolean;
begin
  Result := FPostEffects.TryGetValue(UID, PostEffect);
end;

constructor TPostEffectManager.Create(Scene : TRenderManager);
begin
  inherited Create(Scene, [rsWorldPostEffects, rsPostEffects]);
  FPostEffects := TObjectDictionary<string, TPostEffect>.Create([doOwnsValues]);
end;

procedure TPostEffectManager.Delete(UniqueName : string);
begin
  FPostEffects.Remove(UniqueName);
end;

destructor TPostEffectManager.Destroy;
begin
  FPostEffects.Free;
  inherited;
end;

function TPostEffectManager.GetPostEffect(UID : string) : TPostEffect;
begin
  Result := Get<TPostEffect>(UID);
end;

procedure TPostEffectManager.Add(UID : string; PostEffect : TPostEffect);
begin
  FPostEffects.Add(UID, PostEffect);
  PostEffect.FUID := UID;
end;

function TPostEffectManager.Extract(UniqueName : string) : TPostEffect;
begin
  Result := FPostEffects.ExtractPair(UniqueName).Value;
end;

procedure TPostEffectManager.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
var
  PostEffect : TPostEffect;
  i : integer;
  Effects : TArray<TPostEffect>;
begin
  Effects := ToArray;
  if Length(Effects) > 0 then
  begin
    for i := 0 to Length(Effects) - 1 do
    begin
      PostEffect := Effects[i];
      if PostEffect.Enabled and
        (PostEffect.RenderStage = Stage) and
        (PostEffect.RequiredData <= RenderContext.AvailableRequirements) then
      begin
        if rrScene in PostEffect.RequiredData then
            RenderContext.SwitchScene(True);
        PostEffect.Render(RenderContext);
        GFXD.Device3D.ClearRenderState();
      end;
    end;
  end;
end;

function TPostEffectManager.Requirements : SetRenderRequirements;
var
  PostEffect : TPostEffect;
begin
  Result := [];
  for PostEffect in FPostEffects.Values do
    if PostEffect.Enabled then Result := Result + PostEffect.RequiredData;
end;

{ TPostEffect }

procedure TPostEffect.BuildDependencies(RenderContext : TRenderContext);
begin

end;

constructor TPostEffect.Create;
begin
  Enabled := True;
  FStage := rsPostEffects;
end;

destructor TPostEffect.Destroy;
begin
  Shader.Free;
  ScreenQuad.Free;
  inherited;
end;

function TPostEffect.GetEnabled : boolean;
begin
  if Self = nil then exit(False);
  Result := FEnabled;
end;

function TPostEffect.GetRequiredData : SetRenderRequirements;
begin
  Result := FRequiredData;
end;

procedure TPostEffect.ReleaseDependencies;
begin

end;

procedure TPostEffect.Render(RenderContext : TRenderContext);
begin
  BuildDependencies(RenderContext);
end;

procedure TPostEffect.SetEnabled(const Value : boolean);
begin
  if Self = nil then exit;
  if FEnabled and not Value then
      ReleaseDependencies;
  FEnabled := Value;
end;

{ TPostEffectBlur }

procedure TPostEffectBlur.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  FTextureBlur.BuildDependencies(RenderContext);
end;

constructor TPostEffectBlur.Create;
begin
  inherited;
  FTextureBlur := TTextureBlur.Create;
end;

destructor TPostEffectBlur.Destroy;
begin
  FTextureBlur.Free;
  inherited;
end;

function TPostEffectBlur.GetAdditiveBlur : boolean;
begin
  Result := FTextureBlur.AdditiveBlur;
end;

function TPostEffectBlur.GetAnamorphic : single;
begin
  Result := FTextureBlur.Anamorphic + 5.0;
end;

function TPostEffectBlur.GetIntensity : single;
begin
  Result := FTextureBlur.Intensity;
end;

function TPostEffectBlur.GetIterations : integer;
begin
  Result := FTextureBlur.Iterations;
end;

function TPostEffectBlur.GetKernelsize : integer;
begin
  Result := FTextureBlur.Kernelsize;
end;

function TPostEffectBlur.GetRenderMask : boolean;
begin
  Result := FTextureBlur.RenderInput;
end;

function TPostEffectBlur.GetResolutionDivider : integer;
begin
  Result := FTextureBlur.ResolutionDivider;
end;

function TPostEffectBlur.GetSampleSpread : single;
begin
  Result := FTextureBlur.SampleSpread;
end;

procedure TPostEffectBlur.ReleaseDependencies;
begin
  inherited;
  FTextureBlur.ReleaseDependencies;
end;

procedure TPostEffectBlur.SetAdditiveBlur(const Value : boolean);
begin
  FTextureBlur.AdditiveBlur := Value;
end;

procedure TPostEffectBlur.SetAnamorphic(const Value : single);
begin
  FTextureBlur.Anamorphic := Value - 5;
end;

procedure TPostEffectBlur.SetIntensity(const Value : single);
begin
  FTextureBlur.Intensity := Value;
end;

procedure TPostEffectBlur.SetIterations(const Value : integer);
begin
  FTextureBlur.Iterations := Value;
end;

procedure TPostEffectBlur.SetKernelsize(const Value : integer);
begin
  FTextureBlur.Kernelsize := Value;
end;

procedure TPostEffectBlur.SetRenderMask(const Value : boolean);
begin
  FTextureBlur.RenderInput := Value;
end;

procedure TPostEffectBlur.SetResolutionDivider(const Value : integer);
begin
  FTextureBlur.ResolutionDivider := Value;
end;

procedure TPostEffectBlur.SetSampleSpread(const Value : single);
begin
  FTextureBlur.SampleSpread := Value;
end;

{ TPostEffectBilateralBlur }

constructor TPostEffectBilateralBlur.Create;
begin
  inherited;
  FTextureBlur.Bilateral := True;
end;

function TPostEffectBilateralBlur.GetNormalBias : single;
begin
  Result := FTextureBlur.BilateralNormalbias;
end;

function TPostEffectBilateralBlur.GetRange : single;
begin
  Result := FTextureBlur.BilateralRange;
end;

procedure TPostEffectBilateralBlur.SetNormalBias(const Value : single);
begin
  FTextureBlur.BilateralNormalbias := Value;
end;

procedure TPostEffectBilateralBlur.SetRange(const Value : single);
begin
  FTextureBlur.BilateralRange := Value;
end;

{ TPostEffectFXAA }

procedure TPostEffectFXAA.BuildShader;
var
  Quality : string;
begin
  Shader.Free;
  Quality := '#define FXAA_QUALITY__PRESET ' + Inttostr(ord(FMode) + 1);
  case FMode of
    fmDither : Quality := Quality + Inttostr(Min(5, FQuality));
    fmLessDither : Quality := Quality + Inttostr(FQuality);
    fmNoDither : Quality := Quality + '9';
  end;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'FXAA.fx', [Quality]);
end;

constructor TPostEffectFXAA.Create;
begin
  inherited;
  FStage := rsPostEffects;
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrScene];
  FSubPixelQuality := 0.75;
  FEdgeThreshold := 0.166;
  FEdgeThresholdMin := 0.0833;
  FQuality := 2;
  FMode := fmDither;
  BuildShader;
end;

procedure TPostEffectFXAA.Render(RenderContext : TRenderContext);
begin
  RenderContext.SetShader(Shader);
  GFXD.Device3D.SetSamplerState(tsColor, tfLinear, amClamp);
  Shader.SetShaderConstant<single>('pixelwidth', 1 / GFXD.Settings.Resolution.Width);
  Shader.SetShaderConstant<single>('pixelheight', 1 / GFXD.Settings.Resolution.Height);
  Shader.SetShaderConstant<single>('SubPixelQuality', FSubPixelQuality);
  Shader.SetShaderConstant<single>('EdgeThreshold', FEdgeThreshold);
  Shader.SetShaderConstant<single>('EdgeThresholdMin', FEdgeThresholdMin);
  Shader.SetTexture(tsColor, RenderContext.Scene);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TPostEffectFXAA.setMode(const Value : EnumFXAAMode);
begin
  FMode := Value;
  BuildShader;
end;

procedure TPostEffectFXAA.setQuality(const Value : integer);
begin
  FQuality := Value;
  BuildShader;
end;

{ TPostEffectBloom }

procedure TPostEffectBloom.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  if not assigned(FBloomTexture) then
      FBloomTexture := RenderContext.CreateFullscreenRendertarget();
end;

procedure TPostEffectBloom.BuildShader;
var
  TypeDefine : string;
begin
  Shader.Free;
  case BloomThresholdType of
    btRGB : TypeDefine := '#define THRESHOLD_RGB';
    btLuma : TypeDefine := '#define THRESHOLD_LUMA';
    btHSV : TypeDefine := '#define THRESHOLD_HSV';
  end;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectBloom.fx', [TypeDefine]);
end;

constructor TPostEffectBloom.Create;
begin
  inherited;
  ScreenQuad := TScreenQuad.Create();
  FStage := rsWorldPostEffects;
  FTextureBlur.AdditiveBlur := True;
  FTextureBlur.Intensity := 0.5;
  FRequiredData := [rrScene];
  FBloomThresholdType := btRGB;
  Threshold := RVector3.Create(0.9);
  ThresholdWidth := RVector3.Create(0.1);
  BuildShader;
end;

destructor TPostEffectBloom.Destroy;
begin
  FBloomTexture.Free;
  inherited;
end;

procedure TPostEffectBloom.ReleaseDependencies;
begin
  inherited;
  FreeAndNil(FBloomTexture);
end;

procedure TPostEffectBloom.Render(RenderContext : TRenderContext);
var
  Shader : TShader;
begin
  inherited;
  // mask parts of the scene which should bloom
  GFXD.Device3D.PushRenderTargets([FBloomTexture.asRendertarget]);

  Shader := RenderContext.SetShader(Self.Shader);

  Shader.SetTexture(tsColor, RenderContext.Scene);
  Shader.SetShaderConstant<RVector3>('threshold', Threshold);
  Shader.SetShaderConstant<RVector3>('threshold_width', ThresholdWidth + RVector3.Create(0.01));

  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;

  GFXD.Device3D.PopRenderTargets;

  FTextureBlur.RenderBlur(FBloomTexture.Texture, RenderContext); // blur bloom buffer and add it to scene

  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TPostEffectBloom.setBloomThresholdType(const Value : EnumBloomThresholdType);
begin
  if FBloomThresholdType <> Value then
  begin
    FBloomThresholdType := Value;
    BuildShader;
  end;
end;

{ TPostEffectOutline }

procedure TPostEffectOutline.BuildDependencies(RenderContext : TRenderContext);
begin
  inherited;
  if not assigned(FOutlineTexture) then
      FOutlineTexture := RenderContext.CreateFullscreenRendertarget();
end;

constructor TPostEffectOutline.Create;
begin
  inherited;
  FStage := rsPostEffects;
  FTextureBlur.Intensity := 1.0;
  FTextureBlur.UseStencil := True;
end;

destructor TPostEffectOutline.Destroy;
begin
  FOutlineTexture.Free;
  inherited;
end;

procedure TPostEffectOutline.ReleaseDependencies;
begin
  inherited;
  FreeAndNil(FOutlineTexture);
end;

procedure TPostEffectOutline.Render(RenderContext : TRenderContext);
begin
  inherited;
  FTextureBlur.UseAlpha := not FTextureBlur.AdditiveBlur;
  // Prepare outline buffer
  GFXD.Device3D.PushRenderTargets([FOutlineTexture.asRendertarget]);
  GFXD.Device3D.Clear([cfTarget, cfStencil], $00000000, 1, 0);
  GFXD.Device3D.SetRenderState(rsZENABLE, True, True);
  // we don't want any object to alter z information of our scene
  GFXD.Device3D.SetRenderState(rsZWRITEENABLE, False, True);
  // same objects will be overdrawn, so it has to be passed by the z-test
  GFXD.Device3D.SetRenderState(rsZFUNC, coLessEqual, True);

  GFXD.Device3D.SetRenderState(rsSTENCILENABLE, True, True);
  GFXD.Device3D.SetRenderState(rsSTENCILFUNC, coAlways, True);
  GFXD.Device3D.SetRenderState(rsSTENCILPASS, soIncrSat, True);
  GFXD.Device3D.SetRenderState(rsSTENCILZFAIL, soIncrSat, True);
  GFXD.Device3D.SetRenderState(rsSTENCILFAIL, soIncrSat, True);

  RenderContext.Eventbus.SetDrawEvent(rsOutline);

  GFXD.Device3D.ClearRenderState(rsSTENCILENABLE);
  GFXD.Device3D.ClearRenderState(rsSTENCILFUNC);
  GFXD.Device3D.ClearRenderState(rsSTENCILPASS);
  GFXD.Device3D.ClearRenderState(rsSTENCILZFAIL);
  GFXD.Device3D.ClearRenderState(rsSTENCILFAIL);

  GFXD.Device3D.ClearRenderState(rsZWRITEENABLE);
  GFXD.Device3D.ClearRenderState(rsZFUNC);
  GFXD.Device3D.ClearRenderState(rsZENABLE);
  GFXD.Device3D.PopRenderTargets;
  // blur outline buffer
  FTextureBlur.RenderBlur(FOutlineTexture.Texture, RenderContext);
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

{ TPostEffectColorCorrection }

constructor TPostEffectColorCorrection.Create;
begin
  inherited;
  FStage := rsPostEffects;
  Shader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'PosteffectColorCorrection.fx', []);
  ScreenQuad := TScreenQuad.Create();
  FRequiredData := [rrScene];
  ResetLevels;
end;

procedure TPostEffectColorCorrection.Render(RenderContext : TRenderContext);
begin
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  RenderContext.SetShader(Shader);
  Shader.SetShaderConstant<single>('shadows', Shadows);
  if Midtones <= 1 then Shader.SetShaderConstant<single>('midtones', Midtones)
  else Shader.SetShaderConstant<single>('midtones', 1 + (Midtones - 1) * 10);
  Shader.SetShaderConstant<single>('lights', Lights);
  Shader.SetTexture(tsColor, RenderContext.Scene);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TPostEffectColorCorrection.ResetLevels;
begin
  Shadows := 0;
  Midtones := 1;
  Lights := 1;
end;

initialization

HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectDrawPosition);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectDrawNormal);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectDrawColor);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectDrawMaterial);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectDrawZGBuffer);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectDrawLightbuffer);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectSSAO);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectGlow);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectBloom);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectDistortion);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectFog);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectUnsharpMasking);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectToon);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectSSR);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectEdgeAA);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectFXAA);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectMotionBlur);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectBilateralGaussianBlur);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectGaussianBlur);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectOutline);
HArray.Push<CPostEffect>(AvailablePostEffects, TPostEffectColorCorrection);

end.
