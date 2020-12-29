unit Engine.GfxApi;

interface

uses
  // ======= Delphi ==========
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  System.Types,
  System.UITypes,
  System.Hash,
  System.Math,
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  FMX.Types,
  FMX.Graphics,
  FMX.TextLayout,
  FMX.Canvas.GPU,
  FMX.Canvas.D2D,
  Winapi.Windows,

  // ======= Thrid-Party ======
  Imaging,
  ImagingTypes,

  // ======= Engine ==========
  Engine.Core.Texture,
  Engine.GfxApi.Types,
  Engine.Serializer.Types,
  Engine.Serializer,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Log;

type

  EGraphicInitError = class(Exception);

  TDevice = class;

  /// <summary> All objects which are derived from TGFXDManagedObject will be managed by the GFXD.
  /// Thats important for ALT+TAB or DeviceChanges/Losts. The GFXD try to pool all managed Objects and
  /// uses UniqueValue to determines the equality.</summary>
  TDeviceManagedObject = class abstract(TObject)
    private
      /// <summary> Custom referenzcounter, if 0 object can be destroyed </summary>
      FReferenzCounter : Integer;
      FUniqueValue : string;
    protected
      /// <summary> Owner device for object, manage pooling etc.</summary>
      FDevice : TDevice;
      /// <summary> Important for freeing order. </summary>
      FHasManagedChildren : boolean;
      constructor Create(Device : TDevice);
      /// <summary> Search in GFXD for objekt, if objekt is found it returns it, otherwise it returns nil.
      /// This method is used for pooled objekt like textures and meshes. It have to use before create objekt, otherwise the register process will fail.
      /// If it use for NonPooled ressoures, returnvalue will is always nil.</summary>
      /// <param name="GFXD"> GFXD that are used to create the resource.</param>
      /// <param name="UniqueValue"> A value that identified the objekt. It is very important that the value is unique for a resource,
      /// but equal for similar resources.</param>
      class function QueryDeviceForObject(Device : TDevice; UniqueValue : string) : TDeviceManagedObject;
      /// <summary> Register a resource to Device. All registered resources are manged by GFXD and rebuild if device lost.</summary>
      /// <param name="PoolIt"> If Value is True, the resource is pooled. That mean everbody will hold a reference if it
      /// load multiple and created only once.</param>
      procedure RegisterObjectInDevice(PoolIt : boolean; UniqueValue : string = ''; HasManagedChildren : boolean = False);
      function TryRegisterObjectInDevice(PoolIt : boolean; UniqueValue : string = ''; HasManagedChildren : boolean = False) : boolean;
      /// <summary> Recover the resource after DeviceLost or DeviceChange. If resource was created with "managed" tag
      /// the resource recovers automatic.</summary>
      procedure ResetResource; virtual;
      function CanDestroyed : boolean;
    public
      property UniqueIdentifier : string read FUniqueValue;
      procedure BeforeDestruction; override;
      procedure FreeInstance; override;
      destructor Destroy; override;
  end;

  RResolution = record
    private
      function getSize : RIntVector2;
      procedure setSize(const Value : RIntVector2);
    public
      Width : Integer;
      Height : Integer;
      property Size : RIntVector2 read getSize write setSize;
      constructor Create(Width, Height : Integer);
      function AspectRatio : single;
      // no colordepth, because 32bit is standard
      procedure SetWidthHeight(Width, Height : Integer);
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TDeviceSettings = class
    private
      FResolution : RResolution;
      FFullscreen : boolean;
      FHAL : boolean;
      FVSyncLevel : Integer;
      FVsync : boolean;
      FAntialiasingLevel : EnumAntialiasingLevel;
      FDeferredShading, FCanDeferredShading : boolean;
      FNormalMapping, FLighting : boolean;
      procedure setDeferredShading(const Value : boolean);
      procedure SetVSyncLevel(const Value : Integer);
    public
      SuppressDebugLayer : boolean;
      property Resolution : RResolution read FResolution write FResolution;
      property Fullscreen : boolean read FFullscreen write FFullscreen;
      property HAL : boolean read FHAL write FHAL;
      property Vsync : boolean read FVsync write FVsync;
      property VSyncLevel : Integer read FVSyncLevel write SetVSyncLevel;
      property AntialiasingLevel : EnumAntialiasingLevel read FAntialiasingLevel write FAntialiasingLevel;
      /// <summary> Determines whether Deferred Shading is used or not </summary>
      property DeferredShading : boolean read FDeferredShading write setDeferredShading;
      property CanDeferredShading : boolean read FCanDeferredShading write FCanDeferredShading;
      property Normalmapping : boolean read FNormalMapping write FNormalMapping;
      property Lighting : boolean read FLighting write FLighting;
      constructor Create; overload;
      constructor Create(FileWithSettings : string); overload;
      procedure LoadSettingsFromFile(FilePath : string);
      procedure SaveSettingsToFile(FilePath : string);
      destructor Destroy; override;
  end;

  TDepthStencilBuffer = class
    public
      class function CreateDepthStencilBuffer(Device : TDevice; Width, Height : Cardinal) : TDepthStencilBuffer; virtual; abstract;
  end;

  TTexture = class;

  /// <summary> A rendertarget </summary>
  TRendertarget = class
    protected
      FDevice : TDevice;
      FDepthStencilBuffer : TDepthStencilBuffer;
      FWidth, FHeight : Cardinal;
      function getSize : RIntVector2;
      procedure InitializeTarget(Target : TTexture); virtual; abstract;
    public
      property DepthStencilBuffer : TDepthStencilBuffer read FDepthStencilBuffer;
      constructor Create(Device : TDevice; Target : TTexture; Width, Height : Cardinal);
      property Width : Cardinal read FWidth write FWidth;
      property Height : Cardinal read FHeight write FHeight;
      property Size : RIntVector2 read getSize;
      function HasOwnDepthBuffer : boolean;
      procedure NeedsOwnDepthBuffer;
      destructor Destroy; override;
  end;

  TVertexDeclaration = class(TDeviceManagedObject)
    protected
      FUniqueDeclarationIdentifier : string;
      FVertexSize : Integer;
      FUsageTypes : set of EnumVertexElementUsage;
      class function iCreateVertexDeclaration(Device : TDevice) : TVertexDeclaration; virtual; abstract;
    public
      property VertexSize : Integer read FVertexSize;
      property UniqueDeclarationIdentifier : string read FUniqueDeclarationIdentifier;
      function HasUsagetype(UsageType : EnumVertexElementUsage) : boolean;
      class function CreateVertexDeclaration(Device : TDevice) : TVertexDeclaration;
      procedure AddVertexElement(elemtype : EnumVertexElementType; Usage : EnumVertexElementUsage; Method : EnumVertexElementMethod = emDefault; StreamID : word = 0; UsageIndex : word = 0); virtual;
      procedure EndDeclaration; virtual; abstract;
  end;

  TPushableBuffer = class(TDeviceManagedObject)
    protected
      FLocked, FPushPosition : Pointer;
      FSeekPosition : NativeUInt;
      FPushedElements, FTotalPushedElements : Integer;
      /// <summary> Derivated classes must fill this fields with senseful data! </summary>
      FSize : Integer;
    public
      /// <summary> The raw size of this buffer in bytes. </summary>
      property Size : Integer read FSize;
      function MaxElementsCount<T> : Integer;
      /// <summary> Read a datavalue from buffer. If buffer currently not locked, it will be locked. </summary>
      /// <param name="T"> Generic parameter to specify the data to read. </param>
      /// <param name="x"> Index of element to be read.</param>
      /// <remarks> Don't forget to unlock buffer after reading data!</remarks>
      function getElement<T>(x : Integer) : T;
      /// <summary> Read a datavalue from buffer. If buffer currently not locked, it will be locked. </summary>
      /// <param name="T"> Generic parameter to specify the data to read. </param>
      /// <param name="index"> Index of element to be write.</param>
      /// <remarks> Don't forget to unlock buffer after reading data!</remarks>
      procedure setElement<T>(x : Integer; Value : T);
      /// <summary> Only usable in combination with Lock. Lock resets position to 0, push writes a vertex and steps one vertex further. </summary>
      procedure Push<T>(Value : T);
      property PushedElementsCount : Integer read FPushedElements;
      property TotalPushedElementsCount : Integer read FTotalPushedElements;
      /// <summary> Only usable in combination with Lock and Push. Jumps to vertex n to start push at that position. </summary>
      procedure Seek<T>(const n : Integer);
      /// <summary> Locks the buffer. After locking, with methods "getElement" and "setElement" data can be read/write. After data access buffer has to unlocked.</summary>
      /// <remarks> Every lock needs a unlock, otherwise using a locked buffer for drawing will cause a error.
      /// If a dynamic vertexbuffer is used SizeToLock must be the correct size of data. Otherwise fixed vertexbuffer dont need the parameter, can be left empty. </remarks>
      procedure Lock(); virtual;
      /// <summary> Locks a range of index data and obtains a pointer to the index buffer memory. After data access buffer has to unlocked.</summary>
      /// <remarks> Every lock needs a unlock, otherwise using a locked TPushableBuffer for drawing will cause a error.</remarks>
      /// <param name="SizeToLock"> Size (in bytes) of data to be locked. If Value = 0, locks entire buffer.</param>
      /// <returns> Returns a pointer to the index buffer memory. Can be used to read or write data to buffer (but only in lockrange!)</returns>
      function LowLock(LockFlags : SetLockFlags = [lfDiscard]) : Pointer; virtual; abstract;
      /// <summary> Unlock locked buffer.</summary>
      procedure Unlock; virtual;
  end;

  TVertexBuffer = class(TPushableBuffer)
    protected
      class function iCreateVertexBuffer(Length : Cardinal; Usage : SetUsage; Device : TDevice; InitialData : Pointer) : TVertexBuffer; virtual; abstract;
    public
      /// <summary> If Length=0 the Vb is dynamic sized, every lock will choose a Buffer with appropiate size. There is no data interchange between
      /// dynamic levels, so all data must be completely moved into the buffer. </summary>
      class function CreateVertexBuffer(Length : Cardinal; Usage : SetUsage; Device : TDevice; InitialData : Pointer = nil) : TVertexBuffer;
  end;

  /// <summary> Manages multiple vertexbuffers to emulate a vertexbuffer with a dynamic size. </summary>
  TVertexBufferList = class
    protected
      type
      RDynamicVertexBuffer = record
        Vb : TVertexBuffer;
        Size : Cardinal;
        constructor Create(Vb : TVertexBuffer; Size : Cardinal);
      end;
    var
      FVertexBuffer : TAdvancedList<RDynamicVertexBuffer>;
      FCurrentvertexbuffer : TVertexBuffer;
      FDevice : TDevice;
      FUsage : SetUsage;
    public
      /// <summary> Set at each GetVertexbuffer call. </summary>
      property CurrentVertexbuffer : TVertexBuffer read FCurrentvertexbuffer;
      constructor Create(Usage : SetUsage; Device : TDevice);
      function GetVertexbuffer(Size : Cardinal) : TVertexBuffer;
      destructor Destroy; override;
  end;

  TIndexBuffer = class(TPushableBuffer)
    protected
      class function iCreateIndexBuffer(Length : longword; Usage : SetUsage; Format : EnumIndexBufferFormat; Device : TDevice; InitialData : Pointer) : TIndexBuffer; virtual; abstract;
    public
      /// <summary> Creates an index buffer. </summary>
      /// <param name="Length"> Size of the index buffer, in bytes. </param>
      /// <param name="Usage"> Specified the usage of the buffer. Default value is usDefault.</param>
      /// <param name="Format">Describing the format of the index buffer. Can be a 16 or 32 Bit buffer.</param>
      /// <param name="Device"> Device to which the indexbuffer will be bound.</param>
      class function CreateIndexBuffer(Length : longword; Usage : SetUsage; Format : EnumIndexBufferFormat; Device : TDevice; InitialData : Pointer = nil) : TIndexBuffer;
  end;

  TTextureQualityManager = class
    protected
      FDefaultOffset : Integer;
      // path => loaded mipmap offset
      FQualityOffset : TList<RTuple<string, Integer>>;
    public
      property DefaultOffset : Integer read FDefaultOffset write FDefaultOffset;
      constructor Create;
      procedure AddOffset(const RelativeFilePath : string; Offset : Integer);
      function GetOffset(FilePath : string) : Integer;
      procedure ClearOffsets;
      destructor Destroy; override;
  end;

  FuncTexelMapping<T> = reference to function(x, y : Integer; Value : T) : T;

  EnumMipMapHandling = (mhSkip, mhGenerate, mhLoad);

  /// <summary> A texture. This class handle the act of pooling etc.</summary>
  TTexture = class abstract(TDeviceManagedObject)
    private
      function getDim(index : Integer) : Integer;
    protected
      FWidth, FHeight, FMipLevels : Integer;
      FLocked : Pointer;
      /// <summary> Used for DX11 incompabilities. If 0 don't us padding, else row is bigger than expected. </summary>
      FRowSize : Integer;
      FRendertarget : TRendertarget;
      FFileName : string;
      FUsage : SetUsage;
      FFormat : EnumTextureFormat;
      FMipMapHandling : EnumMipMapHandling;
      FResizeToPow2, FChannelOrderInverted : boolean;
      function IsLocked : boolean;
      class function iCreateTexture(const Width, Height, MipLevels : Cardinal; Usage : SetUsage; Format : EnumTextureFormat; Device : TDevice) : TTexture; virtual; abstract;
      /// <summary> Must fill the fields with info of the loaded texture! </summary>
      class function iCreateTextureFromFile(FilePath : string; Device : TDevice; FailSilently : boolean; MipmapHandling : EnumMipMapHandling = mhGenerate; ResizeToPow2 : boolean = True) : TTexture; virtual; abstract;
      procedure LoadTextureFromMemoryStream(const FilePath : string; const Filecontent : TMemoryStream); virtual; abstract;
    public
      property Width : Integer read FWidth;
      property Height : Integer read FHeight;
      /// <summary> Returns Width/Height. </summary>
      function AspectRatio : single;
      function Size : RIntVector2;
      property MipmapHandling : EnumMipMapHandling read FMipMapHandling;
      property Dimension[index : Integer] : Integer read getDim;
      /// <summary> Empty String if not loaded from disk. </summary>
      property FileName : string read FFileName;
      /// <summary> Creates a rendertarget covering the full screen resolution divided by the resolutiondivider. </summary>
      class function CreateRendertarget(Device : TDevice; Size : RIntVector2; Format : EnumTextureFormat = tfA8R8G8B8) : TTexture;
      /// <summary> If MipLevels=0 they're automatically generated. </summary>
      class function CreateTexture(const Width, Height, MipLevels : Cardinal; const Usage : SetUsage; Format : EnumTextureFormat; Device : TDevice) : TTexture;
      /// <summary> If file doesn't exists => EFileNotFoundException. </summary>
      /// <param name="ResizeToPow2"> More compatibel with very old gfxcards, but unsuitable for clear texel to pixel alignment. </param>
      /// <param name="FailSilently"> If true returns nil if file not found, else throws Exception. </param>
      class function CreateTextureFromFile(FilePath : string; Device : TDevice; GenerateMipmaps : EnumMipMapHandling = mhGenerate; ResizeToPow2 : boolean = True; FailSilently : boolean = False) : TTexture;
      /// <summary> Get the texel (x,y) as T. T must be choosen properly to the texture format.
      /// If x or y exceeds the border it will be corrected with the chosen addressmode.
      /// Multiple calls should be batched with a surrounding Lock/Unlock.
      /// BorderTexel is only used in amBorderColor mode (defaulting to 0).</summary>
      function getTexel<T>(x, y : Integer; AddressMode : EnumTexturAddressMode = amWrap) : T; overload;
      function getTexel<T>(x, y : Integer; AddressMode : EnumTexturAddressMode; BorderTexel : T) : T; overload;
      /// <summary> Does a texture lookup with proper filtering. Coordinates are relative not absolute. </summary>
      function getColor(xy : RVector2; AddressMode : EnumTexturAddressMode = amWrap; FilterMode : EnumTextureFilter = tfLinear) : RColor;
      /// <summary> Set the texel (x,y) as T. T must be choosen properly to the texture format.
      /// If x or y exceeds the border it will be corrected with the chosen addressmode.
      /// Multiple calls should be batched with a surrounding Lock/Unlock.</summary>
      procedure setTexel<T>(x, y : Integer; Value : T);
      /// <summary> Fills every texel with the given value. </summary>
      procedure Fill<T>(Value : T);
      /// <summary> Fills every texel with the given value of a specified function. </summary>
      procedure Map<T>(MapFunction : FuncTexelMapping<T>);
      /// <summary> Disable the autogeneration of mipmaps, useful for editing textures on the fly. </summary>
      procedure DisableMipLevels; virtual; abstract;
      /// <summary> Enables locking and editing of this texture, e.g. if loaded from file and the want to read or write from or to. </summary>
      procedure MakeLockable; virtual; abstract;
      /// <summary> Resizes the texture with linear filtering. </summary>
      procedure Resize(newWidth, newHeight : Integer); overload; virtual; abstract;
      procedure Resize(const NewSize : RIntVector2); overload;
      /// <summary> Saves the texture to a file with the given format. </summary>
      procedure SaveToFile(FileName : string; FileFormat : EnumTextureFileType = tfTGA); virtual;
      /// <summary> Clones the texture and convert the format. </summary>
      function CloneAndConvert(newFormat : EnumTextureFormat) : TTexture;
      /// <summary> Clones the texture. If its loaded from file, it will use the normal pooling. </summary>
      function Clone() : TTexture;
      /// <summary> If the texture was created with usRendertarget this function returns the
      /// rendertarget. Otherwise it raises EInvalidOperation. </summary>
      function AsRendertarget : TRendertarget; virtual;
      /// <summary> Locks the texture for multiple calls to getTexel or setTexel. </summary>
      procedure Lock; virtual; abstract;
      /// <summary> Locks the texture and returns the raw-data pointer. Use with caution! </summary>
      function LowLock : Pointer; overload;
      /// <summary> Locks a subrect of the texture and returns the raw-data pointer. Use with caution! </summary>
      function LowLock(Lockrect : PRect) : Pointer; overload; virtual; abstract;
      /// <summary> Unlocks the texture. Must be used after using Lock or LowLock! </summary>
      procedure Unlock; virtual; abstract;
      /// <summary> Returns whether the fast copy option is available. </summary>
      function FastCopyAvailable : boolean; virtual; abstract;
      /// <summary> Copies the content of this texture to another texture with equal creation details. </summary>
      procedure FastCopy(Target : TTexture); virtual; abstract;
      destructor Destroy; override;
  end;

  RFontCacheKey = record
    Text : string;
    Desc : RFontDescription;
    Format : SetFontRenderingFlags;
    Size, RealSize : RIntVector2;
    Border : RFontBorder;
    Color : Cardinal;
    Resolution : single;
    constructor Create(const Text : string; const Desc : RFontDescription; Format : SetFontRenderingFlags; const Size, RealSize : RIntVector2; const Border : RFontBorder; const Color : Cardinal; const Resolution : single);
    function IsRealSizeDependend : boolean;
    function Hash : Integer;
    class operator equal(const L, R : RFontCacheKey) : boolean;
  end;

  TFontCache = class
    strict private
    const
      // this size determines, the size, which will lead to freeing certain unused cache items, if exceeded
      CACHE_TARGET_SIZE = 150;
    var
      FCache : TObjectDictionary<RFontCacheKey, TTexture>;
      FCacheReferences : TDictionary<RFontCacheKey, Integer>;
    protected
      procedure CleanCache;
      procedure ClearCache;
    public
      constructor Create();
      procedure AddDrawnFont(const Key : RFontCacheKey; DrawnFont : TTexture); overload;
      procedure RemoveDrawnFont(const Key : RFontCacheKey); overload;
      function TryGetDrawnFont(const Key : RFontCacheKey; out DrawnFont : TTexture) : boolean; overload;
      destructor Destroy; override;
  end;

  TTextAttribute = class
    StartIndex, Length : Integer;
    Color : TNullable<RColor>;
    Weight : TNullable<EnumFontWeight>;
    Stretch : TNullable<EnumFontStretch>;
    Style : TNullable<EnumFontStyle>;
    function IsEmpty : boolean;
    function ToTTextAttributedRange(Origin : FMX.TextLayout.TTextLayout) : TTextAttributedRange;
    procedure Merge(AnotherAttribute : TTextAttribute);
    destructor Destroy; override;
  end;

  TFontNode = class
    protected
      FParent : TFontNode;
      FText : string;
      FColor : TNullable<RColor>;
      FWeight : TNullable<EnumFontWeight>;
      FStretch : TNullable<EnumFontStretch>;
      FStyle : TNullable<EnumFontStyle>;

      FChildren : TObjectList<TFontNode>;
      constructor CreateNode(Parent : TFontNode);
      function BuildTextAttributesRecursive(Attributes : TObjectList<TTextAttribute>; CurrentIndex : Integer) : Integer;
    public
      /// <summary> Constructs a node upon a text block. </summary>
      constructor Create(const Text : string);
      function BuildTextAttributes : TObjectList<TTextAttribute>;
      function Text : string;
      destructor Destroy; override;
  end;

  TFont = class(TDeviceManagedObject)
    private
      procedure SetText(const Value : string);
    protected
      FRawText, FText : string;
      FHasCacheKey : boolean;
      FLastCacheKey : RFontCacheKey;
      FBitmap : FMX.Graphics.TBitmap;
      FTextLayout : FMX.TextLayout.TTextLayout;
      FDesc : RFontDescription;
      procedure UpdateTextLayout(const Text : string; const InfiniteSize : boolean = False);
      class function iCreateFont(const Desc : RFontDescription; Device : TDevice) : TFont; virtual;
      procedure Initialize(const Desc : RFontDescription; Device : TDevice);
      procedure DetermineFontSize();
      function CurrentTextWidth(const Text : string) : Integer;
      function CurrentTextHeight(const Text : string) : Integer;
    public
      Color : RColor;
      Border : RFontBorder;
      Format : SetFontRenderingFlags;
      Cliprect : RRect;
      Resolution : single;
      /// <summary> Parses the text for escape sequences. </summary>
      property Text : string write SetText;
      class function CreateFont(const pDesc : RFontDescription; Device : TDevice) : TFont;
      /// <summary> Returns the text width in pixels. Ignores newlines. </summary>
      function TextWidth() : Integer;
      /// <summary> Returns the height of the printed textblock. Only works as intended with ffWordBreak in Flags. </summary>
      function TextBlockHeight() : Integer;
      /// <summary> Returns the position relative to top left in pixels of the characters with the given index. </summary>
      function IndexToPosition(const CharacterIndex : Integer) : RRectFloat;
      /// <summary> Returns the character index at the given position relative to top left in pixels. </summary>
      function PositionToIndex(const Position : RVector2) : Integer;
      function DrawText : TTexture;
      destructor Destroy; override;
  end;

  TDevice = class
    protected
      const
      DEFAULT_SAMPLER_STATE : RSamplerstate = (Filter : tfAuto; AddressMode : amWrap);
    var
      FResources : TThreadList<TDeviceManagedObject>;
      FPooledResources : TThreadSafeObjectDictionary<string, TDeviceManagedObject>;
      FRenderStates : array [EnumRenderstate] of TRenderstate;
      RendertargetStack : TStack<TList<TRendertarget>>;
      FSamplerstates : TDictionary<EnumTextureSlot, RSamplerstate>;
      FDefaultDepthStencilBuffer : TRendertarget;
      /// <summary> Must be initialized by derived Device! </summary>
      FBackbuffer : TRendertarget;
      FResolution : RResolution;
      constructor Create();
      function GetAutoTextureFilter : EnumTextureFilter;
      function GetPooledResource(UniqueKey : string) : TDeviceManagedObject;
      procedure RegisterResource(Resource : TDeviceManagedObject; UniqueKey : string);
      /// <summary> Register resource in device, will return true if resource was not found, else false.</summary>
      function TryRegisterResource(Resource : TDeviceManagedObject; UniqueKey : string) : boolean;
      procedure UnregisterResource(Resource : TDeviceManagedObject);
      procedure SetRealRenderState(Renderstate : EnumRenderstate; Value : Cardinal); virtual; abstract;
      function GetRealRenderState(Renderstate : EnumRenderstate) : Cardinal; virtual; abstract;
      procedure SetRendertargets(Targets : array of TRendertarget); virtual; abstract;
      class function iCreateDevice(Handle : HWND; Settings : TDeviceSettings) : TDevice; virtual; abstract;
    public
      property Resolution : RResolution read FResolution;
      class function CreateDevice(Handle : HWND; Settings : TDeviceSettings) : TDevice;
      /// <summary> Returns -1 if info could not be fetched. </summary>
      function GetUsedVideoMemory : Int64; virtual;
      /// <summary> Returns -1 if info could not be fetched. </summary>
      function GetDedicatedVideoMemory : Int64; virtual;
      function GetVideoMemoryInfo : string; virtual;
      procedure Clear(Flags : SetClearFlags; Color : RColor; z : single; Stencil : DWord); virtual; abstract;
      procedure SetStreamSource(StreamNumber : longword; pStreamData : TVertexBuffer; OffsetInBytes, Stride : longword); virtual; abstract;
      procedure SetIndices(Indices : TIndexBuffer); virtual; abstract;
      procedure SetVertexDeclaration(vertexdeclaration : TVertexDeclaration); virtual; abstract;
      procedure DrawPrimitive(PrimitiveType : EnumPrimitveType; StartIndex, PrimitiveCount : Cardinal); virtual; abstract;
      procedure DrawIndexedPrimitive(PrimitiveType : EnumPrimitveType; BaseVertexIndex : Integer; MinVertexIndex, NumVertices, StartIndex, primCount : Cardinal); virtual; abstract;
      procedure ChangeResolution(const NewResolution : RIntVector2); virtual; abstract;
      function GetBackBuffer : TRendertarget;
      function GetMaxMRT : byte; virtual; abstract;
      /// <summary> Sets a renderstate to a value. Forced FRenderStates can't be overwritten only cleared by ClearRenderState. </summary>
      procedure SetRenderState(Renderstate : EnumRenderstate; Value : Variant; Forciert : boolean = False);
      function GetSamplerState(SamplerRegisterindex : EnumTextureSlot) : RSamplerstate;
      procedure SetSamplerState(SamplerRegisterindex : EnumTextureSlot; Filter : EnumTextureFilter = tfAuto; AddressMode : EnumTexturAddressMode = amWrap; MipMapLodBias : single = 0.0); virtual;
      /// <summary> Revert the renderstate to its initial state. If renderstate=rsNULLRENDERSTATE, all not forced FRenderStates are reverted. </summary>
      /// <summary> Sets rendertargets (index = arrayindex) and put it on top the rendertargetstack </summary>
      procedure PushRenderTargets(Rendertarget : array of TRendertarget);
      /// <summary> Recover the old rendertargets from the rendertargetstack </summary>
      procedure PopRenderTargets();
      procedure SetDefaultDepthStencilBuffer(Buffer : TRendertarget);
      function CreateDepthStencilBuffer(Width, Height : Cardinal) : TDepthStencilBuffer; virtual; abstract;
      procedure ClearRenderState(Renderstate : EnumRenderstate = EnumRenderstate(0));
      procedure ClearSamplerStates;
      procedure SetViewport(Width, Height : Cardinal); virtual; abstract;
      procedure BeginScene; virtual; abstract;
      procedure EndScene; virtual; abstract;
      procedure Present(SourceRect, DestRect : PRect; WindowOverride : HWND); virtual; abstract;
      /// <summary> Create (if not exists) the CacheDirectory and wrote (the shadercode) all pooled shaders known
      /// by this device to the directory. Uses the UniqueValue as filename.</summary>
      procedure GenerateShaderCache(CacheDirectory : string);
      procedure PreloadShaderFromDir(CacheDirectory : string);
      procedure PreloadShader(const ShaderFileName : string);
      /// <summary> Saves the image data of the backbuffer to the specified file. </summary>
      procedure SaveScreenshotToFile(FileName : string); virtual; abstract;
      destructor Destroy; override;
  end;

  TShader = class(TDeviceManagedObject)
    protected
      FShaderString, FShaderDefines, FShaderFile : string;
      FBlockspath : AString;
      FLoaded : boolean;

      FBlockingChanges : EnumShaderBlockMode;
      FBlockList : TStringList;
      FFastBlockList : SetDefaultShaderConstant;
      FTextureBlockList : SetTextureSlot;
      class function ApplyBlocks(ShaderString : string; Blocks : TDictionary<string, string>) : string;
      class function ParseBlocks(const BlockString : string) : TDictionary<string, string>;

      class function iCreateShader(Device : TDevice) : TShader; overload; virtual; abstract;
      function LoadShaderFile(const ShaderPath : string) : string;
      function ResolveIncludes(const ShaderString : string) : string;
      procedure LoadShader(const FilePath : string; const Filecontent : string);
      procedure CompileShader(Shaderstr : AnsiString); virtual; abstract;
      procedure SetRealBoolean(const ConstantName : string; bool : boolean); overload; virtual; abstract;
      procedure SetRealShaderConstant(const ConstantName : string; Value : Pointer; Size : Integer); overload; virtual; abstract;
      procedure SetRealBoolean(const ConstantName : EnumDefaultShaderConstant; bool : boolean); overload; virtual; abstract;
      procedure SetRealShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : Integer); overload; virtual; abstract;
      procedure SetRealTexture(const Slot : EnumTextureSlot; Texture : TTexture; ShaderTarget : EnumShaderType); virtual; abstract;
    public
      /// <summary> Creates a Shader from an effect resource with the given GFXD. If there is a file named as the resource it will be picked instead. </summary>
      class function CreateShaderFromResource(Device : TDevice; Resourcepath : string) : TShader; overload;
      /// <summary> Creates a Shader from an effect resource with the given GFXD. If there is a file named as the resource it will be picked instead.</summary>
      class function CreateShaderFromResourceOrFile(Device : TDevice; Resourcepath : string; Defines : array of string) : TShader; overload;
      /// <summary> Creates the shader from originpath with blockreplacement from blockspath.
      /// Paths are first looked at the filesystem then assumed to be a resourcefile.
      /// If blocks is <> nil, #block BLOCKNAME #endblock will be replaced with specified blocks.
      /// Blocks are resolved from last to first. </summary>
      class function CreateDerivedShader(Device : TDevice; Blockspath : AString; Originpath : string; Defines : array of string) : TShader; overload;
      /// <summary> Creates a Shader from an effect file with the given GFXD </summary>
      class function CreateShaderFromFile(Device : TDevice; Dateipfad : string; Defines : array of string) : TShader; overload;
      /// <summary> Creates a Shader from an effect file with the given GFXD </summary>
      class function CreateShaderFromFile(Device : TDevice; Dateipfad : string) : TShader; overload;
      /// <summary> Set rawdata to shaderconstant. If constant not found, nothing will happen.
      /// IMPORTANT: Method will check size for constant, so if size in shader of constant and given size
      /// different, a error will occure.
      /// <param name="ConstantName"> Name of shaderconstant has to be set.</param>
      /// <param name="Value"> Pointer to rawdata set to shader.</param>
      /// <param name="Size"> Size in bytes of rawdata passed to shader.</param>
      /// </summary>
      procedure SetShaderConstant(const ConstantName : string; Value : Pointer; Size : Integer); overload;
      /// <summary> Don't use reference-types as array of array. 1D-Dynamic arrays working. </summary>
      procedure SetShaderConstant<T>(const ConstantName : string; const Value : T); overload; inline;
      procedure SetShaderConstantBoolean(const ConstantName : string; Value : boolean); overload;
      procedure SetShaderConstantArray<T>(const ConstantName : string; const Value : array of T); overload;

      procedure SetShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : Integer); overload;
      procedure SetShaderConstant<T>(const ConstantName : EnumDefaultShaderConstant; const Value : T); overload; inline;
      procedure SetShaderConstantBoolean(const ConstantName : EnumDefaultShaderConstant; Value : boolean); overload;
      procedure SetShaderConstantArray<T>(const ConstantName : EnumDefaultShaderConstant; const Value : array of T); overload;
      /// <summary> Sets a texture</summary>
      procedure SetTexture(const Slot : EnumTextureSlot; Textur : TTexture; ShaderTarget : EnumShaderType = stPixelshader);
      /// <summary> Sets World and WorldInverseTranspose in the shader </summary>
      procedure SetWorld(const World : RMatrix);

      /// <summary> Prevents all configurations from changing, as black or whitelist as defined. </summary>
      procedure SetBlockMode(BlockMode : EnumShaderBlockMode);
      /// <summary> Returns whether a constant is blocked from changes. </summary>
      function IsBlocked(const ConstantName : string) : boolean; overload; inline;
      /// <summary> Returns whether a constant is blocked from changes. </summary>
      function IsBlocked(const ConstantName : EnumDefaultShaderConstant) : boolean; overload; inline;
      /// <summary> Returns whether a constant is blocked from changes. </summary>
      function IsBlocked(const ConstantName : EnumTextureSlot) : boolean; overload; inline;
      /// <summary> Adds a item onto the blacklist. </summary>
      procedure AddBlockItem(const Blockname : string); overload;
      /// <summary> Adds a item onto the blacklist. </summary>
      procedure AddBlockItem(const Blockname : EnumDefaultShaderConstant); overload;
      /// <summary> Adds a item onto the blacklist. </summary>
      procedure AddBlockItem(const Blockname : EnumTextureSlot); overload;
      /// <summary> Clear the blacklist. </summary>
      procedure ClearBlockList;

      /// <summary> Commit all constant changes within the ShaderBegin and End-Block </summary>
      procedure CommitChanges(); virtual; abstract;
      /// <summary> Activates a shader. Must be called before rendering the geometry. </summary>
      procedure ShaderBegin; virtual; abstract;
      /// <summary> Deactivates a shader. Must be called after rendering the geometry. </summary>
      procedure ShaderEnd; virtual; abstract;

      destructor Destroy; override;
  end;

var
  // if true, raw texturefile is created whenever a normal texture file is loaded
  CREATE_RAW_TEXTURE : boolean = False;
  LOAD_RAW_TEXTURE : boolean   = {$IFDEF DEBUG}False{$ELSE}True{$ENDIF};

  DEBUG_DISABLE_FONT_FOR_PROFILER : boolean = False;
  FontCache : TFontCache;
  TextureQualityManager : TTextureQualityManager;

implementation

uses
  Engine.GfxApi.ClassMapper;

{ TDeviceSettings }

constructor TDeviceSettings.Create;
begin
  Normalmapping := True;
  FLighting := True;
  FDeferredShading := True;
  VSyncLevel := 1;
end;

constructor TDeviceSettings.Create(FileWithSettings : string);
begin
  Create();
  LoadSettingsFromFile(FileWithSettings);
end;

destructor TDeviceSettings.Destroy;
begin

end;

procedure TDeviceSettings.LoadSettingsFromFile(FilePath : string);
begin
  HXMLSerializer.LoadObjectFromFile(self, FilePath);
end;

procedure TDeviceSettings.SaveSettingsToFile(FilePath : string);
begin
  HXMLSerializer.SaveObjectToFile(self, FilePath);
end;

procedure TDeviceSettings.setDeferredShading(const Value : boolean);
begin
  FDeferredShading := Value and CanDeferredShading;
end;

procedure TDeviceSettings.SetVSyncLevel(const Value : Integer);
begin
  FVSyncLevel := Max(1, Min(4, Value));
end;

{ RResolution }

function RResolution.AspectRatio : single;
begin
  Result := Width / Height;
end;

constructor RResolution.Create(Width, Height : Integer);
begin
  self.Width := Width;
  self.Height := Height;
end;

function RResolution.getSize : RIntVector2;
begin
  Result.x := Width;
  Result.y := Height;
end;

procedure RResolution.setSize(const Value : RIntVector2);
begin
  Width := Value.x;
  Height := Value.y;
end;

procedure RResolution.SetWidthHeight(Width, Height : Integer);
begin
  self.Width := Width;
  self.Height := Height;
end;

{ TDevice }

procedure TDevice.ClearSamplerStates;
begin
  FSamplerstates.Clear;
end;

constructor TDevice.Create;
begin
  FResources := TThreadList<TDeviceManagedObject>.Create();
  FPooledResources := TThreadSafeObjectDictionary<string, TDeviceManagedObject>.Create([]);
  RendertargetStack := TStack < TList < TRendertarget >>.Create;
  FSamplerstates := TDictionary<EnumTextureSlot, RSamplerstate>.Create;
end;

class function TDevice.CreateDevice(Handle : HWND; Settings : TDeviceSettings) : TDevice;
var
  i : Integer;
begin
  Result := CDevice(GfxApiClassMapper.MapClass(self)).iCreateDevice(Handle, Settings);
  for i := 0 to Length(INITALRENDERSTATS) - 1 do Result.SetRealRenderState(INITALRENDERSTATS[i].Renderstate, INITALRENDERSTATS[i].Value);
end;

destructor TDevice.Destroy;
var
  // OldCount : Integer;
  LeakedResources : TStrings;
  i : Integer;
  Resources : TList<TDeviceManagedObject>;
begin
  FontCache.ClearCache;
  LeakedResources := TStringList.Create;
  // first free objects with higher hierarchy, can't use for loop as an object can free multiple other objects
  i := 0;
  Resources := FResources.LockList;
  while i < Resources.Count do
  begin
    if Resources[i].FHasManagedChildren then
    begin
      Resources[i].Free; // free will cause multiple removing from list, so we need to restart the search
      i := 0;
    end
    else inc(i);
  end;
  // then free the rest, notify about leaked Resources
  while Resources.Count > 0 do
  begin
    // OldCount := FResources.Count;
    if (Resources.Last.FReferenzCounter > 1) or (Resources.Last.FUniqueValue = '') and not(Resources.Last is TVertexDeclaration) then
        LeakedResources.Add(Resources.Last.ClassName + Resources.Last.FUniqueValue);
    Resources.Last.Free;
    // this assertion fails if someone hasn't freed a reference to an managed object or if the managed object isn't implemented properly
    // assert(FResources.Count < OldCount);
  end;
  FResources.UnlockList;
  if LeakedResources.Count > 0 then HLog.Console(Format('Found for %d 3D-Resources memory leaks. ' + sLineBreak + ' %s', [LeakedResources.Count, LeakedResources.Text]));
  LeakedResources.Free;
  FResources.Free;
  FPooledResources.Free;
  HArray.FreeAndNilAllObjects<TRenderstate>(FRenderStates);
  RendertargetStack.Free;
  FBackbuffer.Free;
  FSamplerstates.Free;
  inherited;
end;

procedure TDevice.GenerateShaderCache(CacheDirectory : string);
var
  shader : TShader;
  Resource : TDeviceManagedObject;
  ShaderFile : TFileStream;
  ShaderFileName : string;
  PooledResources : TDictionary<string, TDeviceManagedObject>;
begin
  PooledResources := FPooledResources.SharedLock;
  for Resource in PooledResources.Values do
  begin
    if Resource is TShader then
    begin
      shader := TShader(Resource);
      ShaderFileName := IncludeTrailingBackslash(CacheDirectory) + shader.FUniqueValue + '.shader';
      if not FileExists(ShaderFileName) then
      begin
        assert(shader.FUniqueValue <> '');
        ForceDirectories(CacheDirectory);
        ShaderFile := TFileStream.Create(ShaderFileName, fmCreate);
        ShaderFile.Write(shader.FShaderString[1], ByteLength(string(shader.FShaderString)));
        ShaderFile.Free;
      end;
    end;
  end;
  FPooledResources.SharedUnlock;
end;

function TDevice.GetAutoTextureFilter : EnumTextureFilter;
begin
  Result := tfLinear;
end;

function TDevice.GetBackBuffer : TRendertarget;
begin
  Result := FBackbuffer;
end;

function TDevice.GetDedicatedVideoMemory : Int64;
begin
  Result := -1;
end;

procedure TDevice.PushRenderTargets(Rendertarget : array of TRendertarget);
var
  i, current : Integer;
  rendert : TList<TRendertarget>;
  rt : TArray<TRendertarget>;
begin
  rendert := TList<TRendertarget>.Create;
  for i := 0 to Min(Length(Rendertarget), GetMaxMRT) - 1 do rendert.Add(Rendertarget[i]);
  if RendertargetStack.Count <= 0 then current := 1
  else current := RendertargetStack.Peek.Count;
  setlength(rt, Max(current, rendert.Count));
  for i := 0 to Length(rt) - 1 do
    if i > rendert.Count - 1 then rt[i] := nil
    else rt[i] := Rendertarget[i];
  SetRendertargets(rt);
  RendertargetStack.Push(rendert);
end;

procedure TDevice.PopRenderTargets();
var
  i : Integer;
  rendert : TList<TRendertarget>;
  rt : TArray<TRendertarget>;
begin
  if RendertargetStack.Count > 0 then
  begin
    rendert := RendertargetStack.Pop;
    rendert.Free;
    if RendertargetStack.Count > 0 then rendert := RendertargetStack.Peek
    else rendert := nil;
    setlength(rt, GetMaxMRT);
    for i := 0 to Length(rt) - 1 do
    begin
      if not assigned(rendert) and (i = 0) then rt[i] := GetBackBuffer
      else if assigned(rendert) and (i < rendert.Count) then
      begin
        rt[i] := rendert[i];
      end
      else rt[i] := nil;
    end;
    SetRendertargets(rt);
  end;
end;

procedure TDevice.PreloadShader(const ShaderFileName : string);
begin
  if HFilepathManager.FileExists(ShaderFileName) then
  begin
    TShader.CreateShaderFromFile(self, ShaderFileName).Free;
  end
  else
      raise EFileNotFoundException.CreateFmt('TDevice.PreloadShader: Could not find shaderfile "%s".', [ShaderFileName]);
end;

procedure TDevice.PreloadShaderFromDir(CacheDirectory : string);
var
  ShaderFileName : string;
  files : TStrings;

begin
  files := TStringList.Create;
  HFileIO.FindAllFiles(files, CacheDirectory, '*.shader');
  for ShaderFileName in files do
  begin
    PreloadShader(ShaderFileName);
  end;
  files.Free;
end;

function TDevice.GetPooledResource(UniqueKey : string) : TDeviceManagedObject;
begin
  UniqueKey := UniqueKey.ToLowerInvariant;
  if FPooledResources.ContainsKey(UniqueKey) then
  begin
    Result := FPooledResources[UniqueKey];
    inc(Result.FReferenzCounter);
  end
  else Result := nil;
end;

function TDevice.GetSamplerState(SamplerRegisterindex : EnumTextureSlot) : RSamplerstate;
begin
  if not FSamplerstates.TryGetValue(SamplerRegisterindex, Result) then
      Result := DEFAULT_SAMPLER_STATE;
end;

function TDevice.GetUsedVideoMemory : Int64;
begin
  Result := -1;
end;

function TDevice.GetVideoMemoryInfo : string;
begin
  Result := '';
end;

procedure TDevice.RegisterResource(Resource : TDeviceManagedObject; UniqueKey : string);
begin
  if UniqueKey <> '' then
  begin
    assert(not FPooledResources.ContainsKey(UniqueKey.ToLowerInvariant));
    FPooledResources.Add(UniqueKey.ToLowerInvariant, Resource);
    inc(Resource.FReferenzCounter);
  end;
  FResources.Add(Resource);
end;

procedure TDevice.ClearRenderState(Renderstate : EnumRenderstate = EnumRenderstate(0));
var
  tmpState : TRenderstate;
  Key : EnumRenderstate;
begin
  if Renderstate = EnumRenderstate(0) then
  begin
    for Key := low(EnumRenderstate) to high(EnumRenderstate) do
      if assigned(FRenderStates[Key]) then
      begin
        if not FRenderStates[Key].Forciert then
        begin
          self.SetRealRenderState(FRenderStates[Key].Renderstate, FRenderStates[Key].UrValue);
          FreeAndNil(FRenderStates[Key]);
        end;
      end;
  end
  else
  begin
    if not assigned(FRenderStates[Renderstate]) then exit;
    tmpState := FRenderStates[Renderstate];
    self.SetRealRenderState(tmpState.Renderstate, tmpState.UrValue);
    FreeAndNil(FRenderStates[Renderstate]);
  end;
end;

procedure TDevice.SetDefaultDepthStencilBuffer(Buffer : TRendertarget);
begin
  FDefaultDepthStencilBuffer := Buffer;
end;

procedure TDevice.SetRenderState(Renderstate : EnumRenderstate; Value : Variant; Forciert : boolean);
var
  tmpState : TRenderstate;
  UrValue : Cardinal;
begin
  tmpState := FRenderStates[Renderstate];
  // wenn bereits dieses RenderState gesetzt wurde und Forciert ist aber der neue Value nicht, wird abgebrochen
  if (tmpState <> nil) and (tmpState.Forciert and (not Forciert)) then exit;
  // ansonsten wird es erstellt oder verändert
  if (tmpState = nil) then
  begin
    UrValue := self.GetRealRenderState(Renderstate);
    FRenderStates[Renderstate] := TRenderstate.Create(Renderstate, Value, UrValue, Forciert);
  end
  else
  begin
    tmpState.Value := Value;
    tmpState.Forciert := Forciert;
  end;
  // und im Device gesetzt
  self.SetRealRenderState(Renderstate, Value);
end;

procedure TDevice.SetSamplerState(SamplerRegisterindex : EnumTextureSlot; Filter : EnumTextureFilter; AddressMode : EnumTexturAddressMode; MipMapLodBias : single);
var
  SamplerState : RSamplerstate;
begin
  SamplerState.Filter := Filter;
  SamplerState.AddressMode := AddressMode;
  SamplerState.MipMapLodBias := MipMapLodBias;
  FSamplerstates.AddOrSetValue(SamplerRegisterindex, SamplerState);
end;

function TDevice.TryRegisterResource(Resource : TDeviceManagedObject; UniqueKey : string) : boolean;
var
  PooledResources : TDictionary<string, TDeviceManagedObject>;
begin
  Result := True;
  if UniqueKey <> '' then
  begin
    PooledResources := FPooledResources.ExclusiveLock;
    begin
      Result := not PooledResources.ContainsKey(UniqueKey.ToLowerInvariant);
      if Result then
      begin
        PooledResources.Add(UniqueKey.ToLowerInvariant, Resource);
        inc(Resource.FReferenzCounter);
      end;
    end;
    FPooledResources.ExclusiveUnlock;
  end;
  FResources.Add(Resource);
end;

procedure TDevice.UnregisterResource(Resource : TDeviceManagedObject);
begin
  assert(Resource.FReferenzCounter = 0, Resource.ClassName + ' wasn''t freed properly! RefCount: ' + Inttostr(Resource.FReferenzCounter));
  if Resource.FUniqueValue <> '' then
  begin
    FPooledResources.Remove(Resource.FUniqueValue);
  end;
  FResources.Remove(Resource);
end;

{ TVertexBuffer }

class function TVertexBuffer.CreateVertexBuffer(Length : Cardinal; Usage : SetUsage; Device : TDevice; InitialData : Pointer) : TVertexBuffer;
begin
  Result := CVertexBuffer(GfxApiClassMapper.MapClass(self)).iCreateVertexBuffer(Length, Usage, Device, InitialData);
  Result.RegisterObjectInDevice(False);
end;

{ TIndexBuffer }

class function TIndexBuffer.CreateIndexBuffer(Length : longword; Usage : SetUsage;
  Format : EnumIndexBufferFormat; Device : TDevice; InitialData : Pointer) : TIndexBuffer;
begin
  Result := CIndexBuffer(GfxApiClassMapper.MapClass(self)).iCreateIndexBuffer(Length, Usage, Format, Device, InitialData);
  Result.RegisterObjectInDevice(False);
  Result.FSize := Length;
end;

{ TTexture }

class function TTexture.CreateRendertarget(Device : TDevice; Size : RIntVector2; Format : EnumTextureFormat) : TTexture;
begin
  Result := TTexture.CreateTexture(Size.x, Size.y, 1, [usRendertarget], Format, Device);
end;

class function TTexture.CreateTexture(const Width, Height, MipLevels : Cardinal; const Usage : SetUsage; Format : EnumTextureFormat; Device : TDevice) : TTexture;
begin
  Result := CTextur(GfxApiClassMapper.MapClass(self)).iCreateTexture(Width, Height, MipLevels, Usage, Format, Device);
  Result.FWidth := Width;
  Result.FHeight := Height;
  Result.FUsage := Usage;
  Result.FFormat := Format;
  Result.FMipLevels := MipLevels;
  Result.RegisterObjectInDevice(False);
  Result.FUniqueValue := 'GeneratedTexture' + Inttostr(Integer(Pointer(Result)));
  if usRendertarget in Usage then
  begin
    Result.FRendertarget := CRendertarget(GfxApiClassMapper.MapClass(TRendertarget)).Create(Device, Result, Width, Height);
  end;
end;

class function TTexture.CreateTextureFromFile(FilePath : string; Device : TDevice; GenerateMipmaps : EnumMipMapHandling; ResizeToPow2 : boolean; FailSilently : boolean) : TTexture;
var
  Hash : string;
begin
  FilePath := AbsolutePath(FilePath);
  // raw textures have a different filepath (where extension is changed)
  if LOAD_RAW_TEXTURE then
      FilePath := TEngineRawTexture.ConvertFileNameToRaw(FilePath);
  // if object isn't pooled, create and register it
  Hash := FilePath;
  case GenerateMipmaps of
    mhSkip : Hash := Hash + '_mhSkip';
    mhGenerate : Hash := Hash + '_mhGenerate';
    mhLoad : Hash := Hash + '_mhLoad';
  else raise ENotImplemented.Create('TTexture.CreateTextureFromFile: Missing Mipmaphandling!');
  end;

  // try to get cashed version instead of loading it
  if assigned(Device) then
      Result := TTexture(TTexture.QueryDeviceForObject(Device, Hash))
  else
      Result := nil;

  if Result = nil then
  begin
    if not FileExists(FilePath) then
    begin
      if not FailSilently then
          HLog.Write(elWarning, 'TTextur.CreateTextureFromFile: Texture ' + FilePath + ' does not exist!', EFileNotFoundException);
      exit(nil)
    end;
    Result := CTextur(GfxApiClassMapper.MapClass(self)).iCreateTextureFromFile(FilePath, Device, FailSilently, GenerateMipmaps, ResizeToPow2);
    if assigned(Device) then
      // for thread safety, use try, maybe while loading texture another thread has already registered resource
      if not Result.TryRegisterObjectInDevice(True, Hash) then
      begin
        Result.Free;
        Result := TTexture(TTexture.QueryDeviceForObject(Device, Hash));
        assert(assigned(Result));
      end;
  end;
  Result.FFileName := FilePath;
end;

function TTexture.AspectRatio : single;
begin
  if Height = 0 then Result := 1.0// should never happen, but for robustness
  else Result := Width / Height;
end;

function TTexture.AsRendertarget : TRendertarget;
begin
  if not assigned(FRendertarget) then raise EInvalidOperation.Create('TTextur.asRendertarget: Texture isn''t a rendertarget!');
  Result := FRendertarget;
end;

function TTexture.Clone : TTexture;
begin
  if FileName = '' then raise ENotImplemented.Create('TTexture.Clone: Only loaded textures are supported at the moment');
  Result := TTexture.CreateTextureFromFile(FileName, FDevice, FMipMapHandling, FResizeToPow2, True);
end;

function TTexture.CloneAndConvert(newFormat : EnumTextureFormat) : TTexture;
var
  newTex : TTexture;
  oldByteCount, newByteCount : Integer;
  procedure Copy(oldByteCount, newByteCount : Integer);
  var
    Source, Dest : Pointer;
    x, y : Integer;
    Color : RColor;
  begin
    Dest := newTex.LowLock;
    Source := LowLock;
    for x := 0 to Width - 1 do
      for y := 0 to Height - 1 do
      begin
        if ((self.FFormat = tfA8B8G8R8) and (newFormat = tfA8R8G8B8))
          or ((self.FFormat = tfA8R8G8B8) and (newFormat = tfA8B8G8R8)) then
        begin
          Color := PCardinal(Source)^;
          Color := Color.BGRA;
          PCardinal(Dest)^ := Color.AsCardinal;
        end
        else
        begin
          ZeroMemory(Dest, newByteCount);
          CopyMemory(Dest, Source, Min(oldByteCount, newByteCount));
        end;
        inc(PByte(Dest), newByteCount);
        inc(PByte(Source), oldByteCount);
      end;
    Unlock;
    newTex.Unlock;
  end;
  function SizeOfFormat(Format : EnumTextureFormat) : Integer;
  begin
    Result := -1;
    case Format of
      tfUNKNOWN : raise Exception.Create('TTextur.CloneAndConvert: Unkown Format cannot be converted.');
      tfR8G8B8 : Result := 3;
      tfA8R8G8B8 : Result := 4;
      tfX8R8G8B8 : Result := 4;
      tfR5G6B5 : Result := 2;
      tfX1R5G5B5 : Result := 2;
      tfA1R5G5B5 : Result := 2;
      tfA4R4G4B4 : Result := 2;
      tfR3G3B2 : Result := 1;
      tfA8 : Result := 1;
      tfA8R3G3B2 : Result := 2;
      tfX4R4G4B4 : Result := 2;
      tfA2B10G10R10 : Result := 4;
      tfA8B8G8R8 : Result := 4;
      tfX8B8G8R8 : Result := 4;
      tfG16R16 : Result := 4;
      tfA2R10G10B10 : Result := 4;
      tfA16B16G16R16 : Result := 8;
      tfA8P8 : Result := 2;
      tfP8 : Result := 1;
      tfL8 : Result := 1;
      tfA8L8 : Result := 2;
      tfA4L4 : Result := 1;
      tfV8U8 : Result := 2;
      tfL6V5U5 : Result := 2;
      tfX8L8V8U8 : Result := 3;
      tfQ8W8V8U8 : Result := 4;
      tfV16U16 : Result := 4;
      tfA2W10V10U10 : Result := 4;
      tfA8X8V8U8 : Result := 4;
      tfL8X8V8U8 : Result := 4;
      tfUYVY : Exception.Create('TTextur.CloneAndConvert: tfUYVY cannot be converted.');
      tfRGBG : Exception.Create('TTextur.CloneAndConvert: tfRGBG cannot be converted.');
      tfYUY2 : Exception.Create('TTextur.CloneAndConvert: tfYUY2 cannot be converted.');
      tfGRGB : Exception.Create('TTextur.CloneAndConvert: tfGRGB cannot be converted.');
      tfDXT1 : Exception.Create('TTextur.CloneAndConvert: tfDXT1 cannot be converted.');
      tfDXT2 : Exception.Create('TTextur.CloneAndConvert: tfDXT2 cannot be converted.');
      tfDXT3 : Exception.Create('TTextur.CloneAndConvert: tfDXT3 cannot be converted.');
      tfDXT4 : Exception.Create('TTextur.CloneAndConvert: tfDXT4 cannot be converted.');
      tfDXT5 : Exception.Create('TTextur.CloneAndConvert: tfDXT5 cannot be converted.');
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
      tfVERTEXDATA : Exception.Create('TTextur.CloneAndConvert: tfVERTEXDATA cannot be converted.');
      tfQ16W16V16U16 : Result := 8;
      tfMULTI2_ARGB8 : Exception.Create('TTextur.CloneAndConvert: tfMULTI2_ARGB8 cannot be converted.');
      tfR16F : Result := 2;
      tfG16R16F : Result := 4;
      tfA16B16G16R16F : Result := 8;
      tfR32F : Result := 4;
      tfG32R32F : Result := 8;
      tfA32B32G32R32F : Result := 16;
      tfCxV8U8 : Result := 2;
      tfFORCE_DWORD : Exception.Create('TTextur.CloneAndConvert: tfFORCE_DWORD cannot be converted.');
    else raise EInvalidArgument.Create('SizeOfFormat: Unknow Format!');
    end;
  end;

begin
  newTex := TTexture.CreateTexture(Width, Height, 0, FUsage, newFormat, FDevice);
  oldByteCount := SizeOfFormat(FFormat);
  newByteCount := SizeOfFormat(newFormat);
  self.MakeLockable;
  newTex.MakeLockable;
  Copy(oldByteCount, newByteCount);
  Result := newTex;
end;

destructor TTexture.Destroy;
begin
  Unlock;
  inherited;
  FRendertarget.Free;
end;

function TTexture.getDim(index : Integer) : Integer;
begin
  Result := Width;
  case index of
    0 : Result := Width;
    1 : Result := Height;
  else assert(False, 'TTexture can atm only have 2 dimensions!');
  end;
end;

function TTexture.getColor(xy : RVector2; AddressMode : EnumTexturAddressMode = amWrap; FilterMode : EnumTextureFilter = tfLinear) : RColor;
var
  x, y : single;
  lt, rt, lb, rb : RColor;
  function nfrac(x : single) : single;
  begin
    Result := frac(x);
    if x < 0 then Result := 1 + Result;
  end;

begin
  assert(self.FFormat in [tfR8G8B8, tfA8R8G8B8, tfA8B8G8R8, tfX8R8G8B8], 'TTexture.getColor: Works only on (A8)R8G8B8 textures currently!');
  x := xy.x * Width;
  y := xy.y * Height;
  case FilterMode of
    tfPoint : Result := getTexel<Cardinal>(floor(x), floor(y), AddressMode);
    tfLinear, tfAnisotropic :
      begin
        lt := getTexel<Cardinal>(floor(x), floor(y), AddressMode);
        rt := getTexel<Cardinal>(ceil(x), floor(y), AddressMode);
        lb := getTexel<Cardinal>(floor(x), ceil(y), AddressMode);
        rb := getTexel<Cardinal>(ceil(x), ceil(y), AddressMode);
        Result := (lt.lerp(rt, nfrac(x))).lerp(lb.lerp(rb, nfrac(x)), nfrac(y));
      end;
  end;
  if self.FFormat in [tfR8G8B8, tfX8R8G8B8] then Result.A := 1.0;
  if self.FFormat in [tfA8B8G8R8] then Result.RGB := Result.BGR;
end;

function TTexture.getTexel<T>(x, y : Integer; AddressMode : EnumTexturAddressMode) : T;
begin
  Result := getTexel<T>(x, y, AddressMode, default (T));
end;

function TTexture.getTexel<T>(x, y : Integer; AddressMode : EnumTexturAddressMode; BorderTexel : T) : T;
type
  pt = ^T;
var
  Bits : Pointer;
  col : RColor;
begin
  case AddressMode of
    amWrap :
      begin
        x := IntMod(x, FWidth);
        y := IntMod(y, FHeight);
      end;
    amMirror : raise ENotImplemented.Create('TTextur.getTexel<T>: Addressmode Mirror not implemented yet.');
    amClamp :
      begin
        x := Max(0, Min(x, FWidth - 1));
        y := Max(0, Min(y, FHeight - 1));
      end;
    amBorder :
      begin
        if (x < 0) or (x >= FWidth) or (y < 0) or (y >= FHeight) then exit(BorderTexel);
      end;

    amMirrorOnce : raise ENotImplemented.Create('TTextur.getTexel<T>: Addressmode MirrorOnce not implemented yet.');
  end;

  Bits := FLocked;
  if Bits = nil then Bits := LowLock;
  if FRowSize = 0 then inc(pt(Bits), x + y * FWidth)
  else inc(PByte(Bits), (x + y * FWidth) * SizeOf(T) + y * (FRowSize - SizeOf(T) * FWidth));
  Result := pt(Bits)^;
  if FLocked = nil then Unlock;

  if FChannelOrderInverted and (TypeInfo(T) = TypeInfo(RColor)) then
  begin
    col := PColor(@Result)^.BGRA;
    Result := pt(@col)^;
  end;
end;

function TTexture.IsLocked : boolean;
begin
  Result := assigned(FLocked)
end;

function TTexture.LowLock : Pointer;
begin
  Result := LowLock(nil);
end;

procedure TTexture.setTexel<T>(x, y : Integer; Value : T);
type
  pt = ^T;
var
  Bits : Pointer;
  col : RColor;
begin
  if FChannelOrderInverted and (TypeInfo(T) = TypeInfo(RColor)) then
  begin
    col.BGRA := PColor(@Value)^;
    Value := pt(@col)^;
  end;

  Bits := FLocked;
  if Bits = nil then Bits := LowLock;
  if FRowSize = 0 then inc(pt(Bits), x + y * FWidth)
  else inc(PByte(Bits), (x + y * FWidth) * SizeOf(T) + y * (FRowSize - SizeOf(T) * FWidth));
  pt(Bits)^ := Value;
  if FLocked = nil then Unlock;
end;

function TTexture.Size : RIntVector2;
begin
  Result.x := Width;
  Result.y := Height;
end;

procedure TTexture.Fill<T>(Value : T);
var
  y : Integer;
  x : Integer;
begin
  self.Lock;
  for y := 0 to self.Height - 1 do
    for x := 0 to self.Width - 1 do
    begin
      self.setTexel<T>(x, y, Value);
    end;
  self.Unlock;
end;

procedure TTexture.Map<T>(MapFunction : FuncTexelMapping<T>);
var
  y : Integer;
  x : Integer;
begin
  self.Lock;
  for y := 0 to self.Height - 1 do
    for x := 0 to self.Width - 1 do
    begin
      self.setTexel<T>(x, y, MapFunction(x, y, self.getTexel<T>(x, y)));
    end;
  self.Unlock;
end;

procedure TTexture.Resize(const NewSize : RIntVector2);
begin
  Resize(NewSize.x, NewSize.y);
end;

procedure TTexture.SaveToFile(FileName : string; FileFormat : EnumTextureFileType);
var
  ImageData : TImageData;
  x : Integer;
  y : Integer;
  Color : TColor32Rec;
  TexColor : RColor;
begin
  if HLog.AssertAndLog(FFormat in [tfA8R8G8B8, tfX8R8G8B8, tfA8B8G8R8], 'TTexture.SaveToFile: Texture format with ID ' + Inttostr(ord(FFormat)) + 'is not supported to be saved as texture!') then exit;
  MakeLockable;
  case FileFormat of
    tfTGA :
      FileName := ChangeFileExt(FileName, '.tga');
    tfPNG :
      FileName := ChangeFileExt(FileName, '.png');
    tfJPG :
      FileName := ChangeFileExt(FileName, '.jpg');
  else
    raise ENotImplemented.Create('TDirectX11Texture.SaveToFile: Unimplemented target file format!');
  end;
  NewImage(FWidth, FHeight, ifA8R8G8B8, ImageData);
  Lock;
  for x := 0 to FWidth - 1 do
    for y := 0 to FHeight - 1 do
    begin
      TexColor := self.getTexel<Cardinal>(x, y);
      if self.FFormat = tfX8R8G8B8 then TexColor.A := 1.0;
      Color.Color := TexColor.AsCardinal;
      SetPixel32(ImageData, x, y, Color);
    end;
  Unlock;
  SaveImageToFile(FileName, ImageData);
  FreeImage(ImageData);
end;

{ TShader }

procedure TShader.AddBlockItem(const Blockname : string);
begin
  if FBlockList.IndexOf(Blockname) = -1 then FBlockList.Add(Blockname);
end;

procedure TShader.AddBlockItem(const Blockname : EnumDefaultShaderConstant);
begin
  FFastBlockList := FFastBlockList + [Blockname];
end;

procedure TShader.AddBlockItem(const Blockname : EnumTextureSlot);
begin
  FTextureBlockList := FTextureBlockList + [Blockname];
end;

class function TShader.ApplyBlocks(ShaderString : string; Blocks : TDictionary<string, string>) : string;
var
  StringList : TStrings;
  block, blockcontent, line : string;
  i : Integer;
begin
  Result := '';
  StringList := Split(ShaderString, sLineBreak);
  block := '';
  blockcontent := '';
  line := '';

  for i := 0 to StringList.Count - 1 do
  begin
    if (Pos('#block', StringList.Strings[i]) >= 1) then
    begin
      assert(block = '', 'TShader.ApplyBlocks: Nested blocks currently not supported!');
      block := StringList.Strings[i].Replace('#block', '').Replace(' ', '').Replace(#9, '').Replace(#10, '').Replace(#13, '');
      blockcontent := '';
      continue;
    end
    else if (Pos('#endblock', StringList.Strings[i]) >= 1) then
    begin
      assert(block <> '', 'TShader.ApplyBlocks: Block closed, but not opened!');
      if assigned(Blocks) and Blocks.ContainsKey(block) then
      begin
        if Pos('#inherited', Blocks[block]) >= 1 then
        begin
          Result := Result + Blocks[block].Replace('#inherited', blockcontent) + sLineBreak;
        end
        else Result := Result + Blocks[block] + sLineBreak;
      end
      else Result := Result + blockcontent;
      block := '';
      blockcontent := '';
    end
    else
    begin
      line := StringList.Strings[i].Replace(#10, '');
      line := line.Replace(#13, '');
      if block <> '' then
      begin
        blockcontent := blockcontent + line + sLineBreak;
      end
      else Result := Result + line + sLineBreak;
    end;
  end;
  StringList.Free;
end;

procedure TShader.ClearBlockList;
begin
  FBlockList.Clear;
  FFastBlockList := [];
end;

procedure TShader.LoadShader;
var
  Blocks, temp : TDictionary<string, string>;
  BlockFileContent, newValue, Value : string;
  i : Integer;
  KeyValue : TPair<string, string>;
begin
  Blocks := TDictionary<string, string>.Create;
  for i := Length(FBlockspath) - 1 downto 0 do
    if FBlockspath[i] <> '' then
    begin
      BlockFileContent := LoadShaderFile(FBlockspath[i]);
      temp := ParseBlocks(BlockFileContent);
      for KeyValue in temp.ToArray do
      begin
        newValue := KeyValue.Value;
        if Blocks.TryGetValue(KeyValue.Key, Value) then newValue := newValue.Replace('#inherited', Value);
        Blocks.AddOrSetValue(KeyValue.Key, newValue);
      end;
      temp.Free;
    end;
  FShaderString := LoadShaderFile(FShaderFile);
  FShaderString := ResolveIncludes(FShaderString);
  FShaderString := ApplyBlocks(FShaderString, Blocks);
  Blocks.Free;
  FShaderString := FShaderDefines + FShaderString;
  try
    CompileShader(AnsiString(FShaderString));
  except
    if not FLoaded then raise;
  end;
end;

function TShader.ResolveIncludes(const ShaderString : string) : string;
var
  Lines : TArray<string>;
  line, IncludeFilename, br : string;
  i : Integer;
begin
  if not ShaderString.Contains(sLineBreak) then br := #10// \n
  else br := sLineBreak;                                 // \r\n

  Lines := ShaderString.Split([br]);

  Result := '';
  for i := 0 to Length(Lines) - 1 do
  begin
    line := Lines[i];
    if Pos('#include', line) >= 1 then
    begin
      line := line.Replace('#include', '');
      line := line.Trim;
      IncludeFilename := line;
      line := LoadShaderFile(IncludeFilename);
      line := '///////////////////////////////////////////////////////////////////////////////' + sLineBreak +
        '/////// ' + IncludeFilename + sLineBreak +
        '///////////////////////////////////////////////////////////////////////////////' + sLineBreak + line;
      line := ResolveIncludes(line);
    end
    else
    begin
      line := line.Replace(#10, '');
      line := line.Replace(#13, '');
    end;
    Result := Result + line + sLineBreak;
  end;
end;

function TShader.LoadShaderFile(const ShaderPath : string) : string;
begin
  if HFilepathManager.FileExists(ShaderPath) then
      Result := ContentManager.FileToString(AbsolutePath(ShaderPath))
  else
      Result := string(HString.ResourceToString(ShaderPath));
  if Result = '' then
      raise ENotFoundException.Create('TShader.LoadShaderFile: Could not load "' + ShaderPath + '"');
end;

class function TShader.CreateDerivedShader(Device : TDevice; Blockspath : AString; Originpath : string; Defines : array of string) : TShader;

  function GenerateHashValue : string;
  var
    item : string;
  begin
    Result := Originpath + HString.Join(Blockspath, '');
    for item in Defines do
    begin
      Result := Result + item;
    end;
    Result := md5(Result);
  end;

var
  hashValue : string;
  ShaderDefs : string;
  i : Integer;
begin
  hashValue := GenerateHashValue;
  Result := TShader(QueryDeviceForObject(Device, hashValue));
  if Result = nil then
  begin
    Result := CShader(GfxApiClassMapper.MapClass(TShader)).iCreateShader(Device);
    Result.RegisterObjectInDevice(True, hashValue);
    Result.FDevice := Device;
    Result.FBlockList := TStringList.Create;
    Result.FBlockList.Sorted := True;

    Result.FBlockspath := Blockspath;
    Result.FShaderFile := Originpath;
    for i := Length(Defines) - 1 downto 0 do
        ShaderDefs := Defines[i] + sLineBreak + ShaderDefs;
    Result.FShaderDefines := ShaderDefs;
    Result.LoadShader('', '');
    Result.FLoaded := True;
    if HFilepathManager.FileExists(Result.FShaderFile) then
        ContentManager.SubscribeToFile(AbsolutePath(Result.FShaderFile), Result.LoadShader, True);
    for i := 0 to Length(Result.FBlockspath) - 1 do
      if HFilepathManager.FileExists(Result.FBlockspath[i]) then
          ContentManager.SubscribeToFile(AbsolutePath(Result.FBlockspath[i]), Result.LoadShader, True);
  end;
end;

class function TShader.CreateShaderFromFile(Device : TDevice; Dateipfad : string) : TShader;
begin
  Result := CreateShaderFromFile(Device, Dateipfad, []);
end;

class function TShader.CreateShaderFromFile(Device : TDevice; Dateipfad : string; Defines : array of string) : TShader;
begin
  Result := CreateDerivedShader(Device, nil, Dateipfad, Defines);
end;

class function TShader.CreateShaderFromResource(Device : TDevice; Resourcepath : string) : TShader;
begin
  Result := CreateShaderFromResourceOrFile(Device, Resourcepath, []);
end;

class function TShader.CreateShaderFromResourceOrFile(Device : TDevice; Resourcepath : string; Defines : array of string) : TShader;
begin
  Result := CreateDerivedShader(Device, nil, Resourcepath, Defines);
end;

destructor TShader.Destroy;
var
  i : Integer;
begin
  ContentManager.UnSubscribeFromFile(FShaderFile, LoadShader);
  for i := 0 to Length(FBlockspath) - 1 do
      ContentManager.UnSubscribeFromFile(FBlockspath[i], LoadShader);
  FBlockList.Free;
  inherited;
end;

function TShader.IsBlocked(const ConstantName : EnumDefaultShaderConstant) : boolean;
begin
  Result := not((FBlockingChanges = sbNone) or
    ((FBlockingChanges = sbWhiteList) and (ConstantName in FFastBlockList)) or
    ((FBlockingChanges = sbBlackList) and (not(ConstantName in FFastBlockList))));
end;

function TShader.IsBlocked(const ConstantName : string) : boolean;
begin
  Result := not((FBlockingChanges = sbNone) or
    ((FBlockingChanges = sbWhiteList) and (FBlockList.IndexOf(ConstantName) <> -1)) or
    ((FBlockingChanges = sbBlackList) and (FBlockList.IndexOf(ConstantName) = -1)));
end;

function TShader.IsBlocked(const ConstantName : EnumTextureSlot) : boolean;
begin
  Result := not((FBlockingChanges = sbNone) or
    ((FBlockingChanges = sbWhiteList) and (ConstantName in FTextureBlockList)) or
    ((FBlockingChanges = sbBlackList) and (not(ConstantName in FTextureBlockList))));
end;

class function TShader.ParseBlocks(const BlockString : string) : TDictionary<string, string>;
var
  StringList : TStrings;
  block, blockcontent, line : string;
  i : Integer;
begin
  Result := TDictionary<string, string>.Create;
  StringList := Split(BlockString, sLineBreak);
  block := '';
  blockcontent := '';
  line := '';

  for i := 0 to StringList.Count - 1 do
  begin
    if (Pos('#block', StringList.Strings[i]) >= 1) then
    begin
      assert(block = '', 'TShader.ApplyBlocks: Nested blocks currently not supported!');
      block := StringList.Strings[i].Replace('#block', '').Replace(' ', '').Replace(#10, '').Replace(#13, '');
      blockcontent := '';
      continue;
    end
    else if (Pos('#endblock', StringList.Strings[i]) >= 1) then
    begin
      assert(block <> '', 'TShader.ApplyBlocks: Block closed, but not opened!');
      Result.Add(block, blockcontent);
      block := '';
      blockcontent := '';
    end
    else
    begin
      line := StringList.Strings[i].Replace(#10, '');
      line := line.Replace(#13, '');
      if block <> '' then
      begin
        blockcontent := blockcontent + line + sLineBreak;
      end;
    end;
  end;
  StringList.Free;
end;

procedure TShader.SetBlockMode(BlockMode : EnumShaderBlockMode);
begin
  FBlockingChanges := BlockMode;
end;

procedure TShader.SetShaderConstant(const ConstantName : string; Value : Pointer; Size : Integer);
begin
  if not IsBlocked(ConstantName) then SetRealShaderConstant(ConstantName, Value, Size);
end;

procedure TShader.SetShaderConstant<T>(const ConstantName : string; const Value : T);
begin
  SetShaderConstant(ConstantName, @Value, SizeOf(T));
end;

procedure TShader.SetShaderConstantArray<T>(const ConstantName : string; const Value : array of T);
begin
  SetShaderConstant(ConstantName, @Value[0], Length(Value) * SizeOf(T));
end;

procedure TShader.SetShaderConstantBoolean(const ConstantName : string; Value : boolean);
begin
  if not IsBlocked(ConstantName) then SetRealBoolean(ConstantName, Value);
end;

procedure TShader.SetTexture(const Slot : EnumTextureSlot; Textur : TTexture; ShaderTarget : EnumShaderType);
begin
  if not IsBlocked(Slot) then SetRealTexture(Slot, Textur, ShaderTarget);
end;

procedure TShader.SetShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : Integer);
begin
  if not IsBlocked(ConstantName) then SetRealShaderConstant(ConstantName, Value, Size);
end;

procedure TShader.SetShaderConstant<T>(const ConstantName : EnumDefaultShaderConstant; const Value : T);
begin
  SetShaderConstant(ConstantName, @Value, SizeOf(T));
end;

procedure TShader.SetShaderConstantArray<T>(const ConstantName : EnumDefaultShaderConstant; const Value : array of T);
begin
  SetShaderConstant(ConstantName, @Value[0], Length(Value) * SizeOf(T));
end;

procedure TShader.SetShaderConstantBoolean(const ConstantName : EnumDefaultShaderConstant; Value : boolean);
begin
  if not IsBlocked(ConstantName) then SetRealBoolean(ConstantName, Value);
end;

procedure TShader.SetWorld(const World : RMatrix);
var
  WIT : RMatrix;
begin
  SetShaderConstant<RMatrix>(dcWorld, World);
  WIT := World.Inverse.Transpose;
  SetShaderConstant<RMatrix>(dcWorldInverseTranspose, WIT);
end;

{ TVertexDeclaration }

procedure TVertexDeclaration.AddVertexElement(elemtype : EnumVertexElementType; Usage : EnumVertexElementUsage; Method : EnumVertexElementMethod; StreamID,
  UsageIndex : word);
begin
  if elemtype <> etUnused then
  begin
    assert((StreamID < 10) and (UsageIndex < 10), 'TVertexDeclaration.AddVertexElement: unique identifier assumes single number. Can be changed.');
    FUniqueDeclarationIdentifier := FUniqueDeclarationIdentifier + HString.strO([ord(elemtype), ord(Usage), ord(Method), StreamID, UsageIndex]);
    case elemtype of
      etFloat1 : FVertexSize := FVertexSize + SizeOf(single);
      etFloat2 : FVertexSize := FVertexSize + SizeOf(single) * 2;
      etFloat3 : FVertexSize := FVertexSize + SizeOf(single) * 3;
      etFloat4 : FVertexSize := FVertexSize + SizeOf(single) * 4;
    end;
    FUsageTypes := FUsageTypes + [Usage];
  end;
end;

class function TVertexDeclaration.CreateVertexDeclaration(Device : TDevice) : TVertexDeclaration;
begin
  Result := CVertexDeclaration(GfxApiClassMapper.MapClass(self)).iCreateVertexDeclaration(Device);
  Result.RegisterObjectInDevice(False);
end;

function TVertexDeclaration.HasUsagetype(UsageType : EnumVertexElementUsage) : boolean;
begin
  Result := UsageType in FUsageTypes;
end;

{ TDeviceManagedObject }

procedure TDeviceManagedObject.BeforeDestruction;
begin
  AtomicDecrement(FReferenzCounter);
end;

function TDeviceManagedObject.CanDestroyed : boolean;
begin
  Result := not(FReferenzCounter > 0);
end;

constructor TDeviceManagedObject.Create(Device : TDevice);
begin
  FDevice := Device;
  FReferenzCounter := 1;
end;

destructor TDeviceManagedObject.Destroy;
begin
  inherited;
end;

procedure TDeviceManagedObject.FreeInstance;
begin
  if FReferenzCounter <= 0 then
  begin
    FDevice.UnregisterResource(self);
    inherited;
  end;
end;

class function TDeviceManagedObject.QueryDeviceForObject(Device : TDevice; UniqueValue : string) : TDeviceManagedObject;
begin
  Result := Device.GetPooledResource(UniqueValue);
end;

procedure TDeviceManagedObject.RegisterObjectInDevice(PoolIt : boolean; UniqueValue : string; HasManagedChildren : boolean);
begin
  if assigned(FDevice) then
  begin
    if PoolIt then
        FDevice.RegisterResource(self, UniqueValue)
    else
        FDevice.RegisterResource(self, '');
  end;
  FUniqueValue := UniqueValue;
  FHasManagedChildren := HasManagedChildren;
end;

procedure TDeviceManagedObject.ResetResource;
begin
  raise ENotImplemented.Create('TDeviceManagedObject.ResetResource');
end;

function TDeviceManagedObject.TryRegisterObjectInDevice(PoolIt : boolean; UniqueValue : string; HasManagedChildren : boolean) : boolean;
begin
  if PoolIt then
      Result := FDevice.TryRegisterResource(self, UniqueValue)
  else
      Result := FDevice.TryRegisterResource(self, '');
  FUniqueValue := UniqueValue;
  FHasManagedChildren := HasManagedChildren;
end;

{ TFont }

class function TFont.CreateFont(const pDesc : RFontDescription; Device : TDevice) : TFont;
begin
  Result := CFont(GfxApiClassMapper.MapClass(self)).iCreateFont(pDesc, Device);
  Result.RegisterObjectInDevice(False);
end;

class function TFont.iCreateFont(const Desc : RFontDescription; Device : TDevice) : TFont;
begin
  Result := TFont.Create(Device);
  Result.Initialize(Desc, Device);
end;

function TFont.IndexToPosition(const CharacterIndex : Integer) : RRectFloat;
var
  Rects : TRegion;
begin
  Result := RRectFloat.ZERO;
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit();
  UpdateTextLayout(FText);
  Result := RRectFloat.CreateWidthHeight(0, 0, 0, FDesc.Height);
  Rects := FTextLayout.RegionForRange(TTextRange.Create(CharacterIndex, 0));
  if Length(Rects) > 0 then
      Result := Rects[0];
end;

function TFont.PositionToIndex(const Position : RVector2) : Integer;
var
  ClampedPosition : RVector2;
begin
  Result := 0;
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit();
  UpdateTextLayout(FText);
  // shrink quad by 1 to prevent rounding errors
  ClampedPosition := RRectFloat(FTextLayout.TextRect).Inflate(-1).ClampPoint(Position);
  Result := FTextLayout.PositionAtPoint(TPointF(ClampedPosition));
end;

procedure TFont.SetText(const Value : string);
var
  ParsedFont : TFontNode;
  TextAttributes : TObjectList<TTextAttribute>;
  i : Integer;
begin
  if FRawText = Value then exit;
  FRawText := Value;
  FTextLayout.ClearAttributes;
  // parse escape blocks
  ParsedFont := TFontNode.Create(FRawText);
  FText := ParsedFont.Text;
  FText := FText.Replace('&', '&&');
  // update text layout
  FTextLayout.BeginUpdate;
  UpdateTextLayout(FText);
  // add text attributes
  TextAttributes := ParsedFont.BuildTextAttributes;
  for i := 0 to TextAttributes.Count - 1 do
      FTextLayout.AddAttribute(TextAttributes[i].ToTTextAttributedRange(FTextLayout));
  FTextLayout.EndUpdate;
  TextAttributes.Free;
  ParsedFont.Free;
end;

procedure TFont.Initialize(const Desc : RFontDescription; Device : TDevice);
var
  fontStyle : TFontStyleExt;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit;
  Resolution := 1.0;
  FDesc := Desc;
  FBitmap := FMX.Graphics.TBitmap.Create(256, 64);
  FBitmap.Canvas.Fill.Kind := TBrushKind.Solid;
  FBitmap.Canvas.Fill.Color := RColor.CWHITE.AsCardinal;

  FTextLayout := TTextLayoutManager.DefaultTextLayout.Create();
  FTextLayout.BeginUpdate;
  fontStyle := TFontStyleExt.Default;
  fontStyle.Slant := TFontSlant(Desc.Style);
  fontStyle.Weight := TFontWeight(Desc.Weight);
  fontStyle.Stretch := TFontStretch(Desc.Stretch);
  FTextLayout.Font.StyleExt := fontStyle;
  FTextLayout.Font.Size := Desc.Height;
  FTextLayout.Font.Family := Desc.FontFamily;
  FTextLayout.Color := RColor.CWHITE.AsCardinal;
  FTextLayout.EndUpdate;
end;

function TFont.CurrentTextHeight(const Text : string) : Integer;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit(100);
  Result := ceil(FTextLayout.TextHeight);
end;

function TFont.CurrentTextWidth(const Text : string) : Integer;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit(10);
  Result := ceil(FTextLayout.TextWidth);
end;

destructor TFont.Destroy;
begin
  if FHasCacheKey then
      FontCache.RemoveDrawnFont(FLastCacheKey);
  FBitmap.Free;
  FTextLayout.Free;
  inherited;
end;

procedure TFont.DetermineFontSize();
var
  Width, Height : Integer;
  tempTextHeight : single;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit;
  UpdateTextLayout(FText);
  if ffAutoShrink in Format then
  begin
    tempTextHeight := FDesc.Height;
    FTextLayout.Font.Size := FDesc.Height * 0.75;
    if ffWordWrap in Format then
    begin
      FTextLayout.MaxSize := TPointF.Create(Cliprect.Width, TTextLayout.MaxLayoutSize.y);
      Height := CurrentTextHeight(FText);
      // 6 is minimal font size
      while (Height > Cliprect.Height) and (tempTextHeight > 6) do
      begin
        tempTextHeight := tempTextHeight - 1;
        FTextLayout.Font.Size := tempTextHeight * 0.75;
        Height := CurrentTextHeight(FText);
      end;
    end
    else
    begin
      FTextLayout.MaxSize := TTextLayout.MaxLayoutSize;
      Width := CurrentTextWidth(FText);
      // 6 is minimal font size
      while (Width > Cliprect.Width) and (tempTextHeight > 6) do
      begin
        tempTextHeight := tempTextHeight - 1;
        FTextLayout.Font.Size := tempTextHeight * 0.75;
        Width := CurrentTextWidth(FText);
      end;
    end;
    FTextLayout.MaxSize := TPointF.Create(Cliprect.Width, Cliprect.Height);
  end;
end;

function TFont.DrawText() : TTexture;
type
  ChannelArray = array [0 .. 3] of byte;
var
  x, y, bx, by : Integer;
  borderRange, alphaCount : Integer;
  originalColor, tempColor : RColor;
  alphaSum{ , dist, weight } : single;
  texel : PCardinal;
  TextureSize : RIntVector2;
  TargetSize : RIntVector2;
  memimage, ptr : PCardinal;
  Data : TBitmapData;
  DrawnFont : TTexture;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit(nil);
  if (Cliprect.Width <= 0) or (Cliprect.Height <= 0) then exit(nil);
  if (Cliprect.Width > MAXWORD) or (Cliprect.Height > MAXWORD) then
      raise EInvalidArgument.CreateFmt('TFont.DrawText: Invalid arguments for drawing a text, width "%d", height "%d", text "%s" ',
      [Cliprect.Width, Cliprect.Height, FRawText]);

  // preparations

  // adjust size if needed
  TargetSize := RIntVector2.Create(ceil(Cliprect.Width * self.Resolution), ceil(Cliprect.Height * self.Resolution));
  TextureSize := RIntVector2.Create(Naechste2erPotenz(TargetSize.Width), Naechste2erPotenz(TargetSize.Height));
  // release cache
  if FHasCacheKey then
      FontCache.RemoveDrawnFont(FLastCacheKey);
  FHasCacheKey := True;
  FLastCacheKey := RFontCacheKey.Create(FRawText, FDesc, Format, TextureSize, TargetSize, Border, Color.AsCardinal, Resolution);

  Result := nil;
  if not FontCache.TryGetDrawnFont(FLastCacheKey, Result) then
  begin
    DrawnFont := TTexture.CreateTexture(TextureSize.x, TextureSize.y, 1, [usWriteable], tfA8R8G8B8, FDevice);
  end
  else
  begin
    // add cache ref
    FontCache.AddDrawnFont(FLastCacheKey, Result);
    exit;
  end;
  FBitmap.setSize(TargetSize.Width, TargetSize.Height);

  // render
  // clear bitmap
  FBitmap.Canvas.BeginScene();
  FBitmap.Canvas.Clear(Color.SetAlphaF(0).AsCardinal);

  // draw font
  DetermineFontSize(); // will call UpdateTextLayout(Text);
  // apply resolution if present
  if abs(self.Resolution - 1.0) >= 0.01 then
  begin
    FTextLayout.BeginUpdate;
    FTextLayout.Font.Size := FTextLayout.Font.Size * self.Resolution;
    FTextLayout.MaxSize := TPointF.Create(Cliprect.Width * self.Resolution, Cliprect.Height * self.Resolution);
    FTextLayout.EndUpdate;
  end;

  FTextLayout.RenderLayout(FBitmap.Canvas);
  FBitmap.Canvas.EndScene;

  memimage := nil;
  borderRange := ceil(Border.Width);
  if borderRange > 0 then
      GetMem(memimage, SizeOf(Cardinal) * DrawnFont.Width * DrawnFont.Height);

  DrawnFont.Lock;
  FBitmap.Map(TMapAccess.Read, Data);
  for y := 0 to DrawnFont.Height - 1 do
  begin
    if y < FBitmap.Height then
        texel := Data.GetScanline(y)
    else
        texel := nil;
    for x := 0 to DrawnFont.Width - 1 do
    begin
      if (y < FBitmap.Height) and (x < FBitmap.Width) then
      begin
        // copy value from drawn font
        tempColor.AsCardinal := texel^;
        if tempColor.A > 0 then
            tempColor.RGB := tempColor.RGB / tempColor.A;
        DrawnFont.setTexel<Cardinal>(x, y, tempColor.AsCardinal);
        inc(texel);
        if borderRange > 0 then
        begin
          ptr := memimage;
          inc(ptr, y * DrawnFont.Width + x);
          ptr^ := RColor.CWHITE.SetAlphaF(tempColor.A).AsCardinal;
        end;
      end
      else
        // fill textures exceeding
          DrawnFont.setTexel<Cardinal>(x, y, Color.SetAlphaF(0).AsCardinal);
    end;
  end;
  FBitmap.Unmap(Data);
  // apply border
  // ToDo: enhance with Euclidean Distance Transform and Meijster Algorithm
  // http://fab.cba.mit.edu/classes/S62.12/docs/Meijster_distance.pdf
  // http://cs.brown.edu/~pff/papers/dt-final.pdf
  // https://github.com/vinniefalco/LayerEffects/blob/6cbd0f8877ab2942bc2ed34f2e0545ecb7de918b/Extern/VFLib/modules/vf_unfinished/graphics/vf_DistanceTransform.h
  if (borderRange > 0) then
  begin
    borderRange := 1;
    for y := 0 to FBitmap.Height - 1 do
      for x := 0 to FBitmap.Width - 1 do
      begin
        alphaSum := 0;
        alphaCount := 0;
        originalColor := DrawnFont.getTexel<Cardinal>(x, y);
        for bx := Max(0, x - borderRange) to Min(FBitmap.Width - 1, x + borderRange) do
          for by := Max(0, y - borderRange) to Min(FBitmap.Height - 1, y + borderRange) do
          begin
            ptr := memimage;
            inc(ptr, by * DrawnFont.Width + bx);
            tempColor := ptr^;
            alphaSum := alphaSum + tempColor.A;
            inc(alphaCount);
          end;
        tempColor := Border.Color;
        tempColor.A := (alphaSum * 2) / alphaCount;
        originalColor := originalColor.lerp(tempColor, 1 - originalColor.A);
        DrawnFont.setTexel<Cardinal>(x, y, originalColor.AsCardinal);
      end;
    FreeMem(memimage);
  end;
  DrawnFont.Unlock;
  FontCache.AddDrawnFont(FLastCacheKey, DrawnFont);
  Result := DrawnFont;
end;

function TFont.TextBlockHeight() : Integer;
var
  lRect : TRectF;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit(10);
  lRect.Top := 0;
  lRect.Left := 0;
  lRect.Right := self.Cliprect.Width;
  lRect.Bottom := self.Cliprect.Height;
  FTextLayout.Font.Size := FTextLayout.Font.Size / Resolution;
  FTextLayout.MaxSize := TPointF.Create(Cliprect.Width, TTextLayout.MaxLayoutSize.y);
  lRect := FTextLayout.TextRect;
  FTextLayout.MaxSize := TPointF.Create(Cliprect.Width, Cliprect.Height);
  Result := ceil(lRect.Bottom - lRect.Top);
  FTextLayout.Font.Size := FTextLayout.Font.Size * Resolution;
end;

function TFont.TextWidth() : Integer;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit(10);
  FTextLayout.MaxSize := TTextLayout.MaxLayoutSize;
  Result := ceil(FTextLayout.TextWidth);
  HLog.AssertAndLog((Result >= 0) and (Result <= TTextLayout.MaxLayoutSize.x), 'TFont.TextWidth: Returned a invalid width %d! (%s)', [Result, FTextLayout.QualifiedClassName]);
  FTextLayout.MaxSize := TPointF.Create(Cliprect.Width, Cliprect.Height);
end;

procedure TFont.UpdateTextLayout(const Text : string; const InfiniteSize : boolean);
var
  fontStyle : TFontStyleExt;
begin
  if DEBUG_DISABLE_FONT_FOR_PROFILER then exit;
  FTextLayout.BeginUpdate;
  FTextLayout.Text := Text;
  FTextLayout.WordWrap := ffWordWrap in Format;
  FTextLayout.Color := Color.AsCardinal;

  FTextLayout.Font.Size := FDesc.Height * 0.75;
  FTextLayout.Font.Family := FDesc.FontFamily;

  fontStyle := TFontStyleExt.Default;
  fontStyle.Slant := TFontSlant(FDesc.Style);
  fontStyle.Weight := TFontWeight(FDesc.Weight);
  fontStyle.Stretch := TFontStretch(FDesc.Stretch);
  FTextLayout.Font.StyleExt := fontStyle;

  FTextLayout.HorizontalAlign := TTextAlign.Leading;
  if ffCenter in Format then FTextLayout.HorizontalAlign := TTextAlign.Center;
  if ffRight in Format then FTextLayout.HorizontalAlign := TTextAlign.Trailing;

  FTextLayout.VerticalAlign := TTextAlign.Leading;
  if ffVerticalCenter in Format then FTextLayout.VerticalAlign := TTextAlign.Center;
  if ffBottom in Format then FTextLayout.VerticalAlign := TTextAlign.Trailing;

  FTextLayout.TopLeft := TPointF.Create(0, 0);
  FTextLayout.MaxSize := TPointF.Create(Cliprect.Width, Cliprect.Height);
  FTextLayout.EndUpdate;
end;

{ TRendertarget }

constructor TRendertarget.Create(Device : TDevice; Target : TTexture; Width, Height : Cardinal);
begin
  self.Width := Width;
  self.Height := Height;
  FDevice := Device;
  InitializeTarget(Target);
end;

destructor TRendertarget.Destroy;
begin
  FDepthStencilBuffer.Free;
  inherited;
end;

function TRendertarget.getSize : RIntVector2;
begin
  Result.x := Width;
  Result.y := Height;
end;

function TRendertarget.HasOwnDepthBuffer : boolean;
begin
  Result := assigned(FDepthStencilBuffer);
end;

procedure TRendertarget.NeedsOwnDepthBuffer;
begin
  self.FDepthStencilBuffer.Free;
  self.FDepthStencilBuffer := CDepthStencilBuffer(GfxApiClassMapper.MapClass(TDepthStencilBuffer)).CreateDepthStencilBuffer(FDevice, Width, Height);
end;

{ TPushableBuffer }

procedure TPushableBuffer.Push<T>(Value : T);
type
  pt = ^T;
begin
  assert(FLocked <> nil, 'TPushableBuffer.Push<T>: Buffer must be locked for push!');
  if not(NativeUInt(FPushPosition) >= NativeUInt(FLocked)) and (NativeUInt(FPushPosition) + SizeOf(T) - NativeUInt(FLocked) <= FSize) then
  begin
    NOOP;
    exit;
  end;
  // assert(, 'TPushableBuffer.Push<T>: Out of bounds!');
  pt(FPushPosition)^ := Value;
  inc(pt(FPushPosition), 1);
  FSeekPosition := FSeekPosition + SizeOf(T);
  FPushedElements := FPushedElements + 1;
  FTotalPushedElements := FTotalPushedElements + 1;
end;

procedure TPushableBuffer.Seek<T>(const n : Integer);
begin
  FPushPosition := Pointer(NativeUInt(FLocked) + (SizeOf(T) * n));
  FSeekPosition := NativeUInt(FPushPosition) - NativeUInt(FLocked);
end;

function TPushableBuffer.getElement<T>(x : Integer) : T;
type
  pt = ^T;
var
  Bits : Pointer;
begin
  Bits := FLocked;
  if Bits = nil then Bits := LowLock;
  assert(x < FSize, 'TVertexBuffer.getVertex: Vertex out of Vertexbufferrange!');
  inc(pt(Bits), x);
  Result := pt(Bits)^;
  if FLocked = nil then Unlock;
end;

procedure TPushableBuffer.Lock();
begin
  FPushPosition := Pointer(NativeUInt(FLocked) + FSeekPosition);
  FPushedElements := 0;
end;

procedure TPushableBuffer.setElement<T>(x : Integer; Value : T);
type
  pt = ^T;
var
  Bits : Pointer;
begin
  Bits := FLocked;
  if Bits = nil then Bits := LowLock;
  assert(x < FSize, 'TVertexBuffer.setElement: Vertex out of Vertexbufferrange!');
  inc(pt(Bits), x);
  pt(Bits)^ := Value;
  if FLocked = nil then Unlock;
end;

procedure TPushableBuffer.Unlock;
begin
  FPushPosition := nil;
  FLocked := nil;
end;

function TPushableBuffer.MaxElementsCount<T> : Integer;
begin
  Result := FSize div SizeOf(T);
end;

{ TVertexBufferList }

constructor TVertexBufferList.Create(Usage : SetUsage; Device : TDevice);
begin
  FVertexBuffer := TAdvancedList<RDynamicVertexBuffer>.Create;
  FDevice := Device;
  FUsage := Usage;
end;

destructor TVertexBufferList.Destroy;
begin
  FVertexBuffer.Each(
    procedure(const item : RDynamicVertexBuffer)
    begin
      item.Vb.Free;
    end);
  FVertexBuffer.Free;
  inherited;
end;

function TVertexBufferList.GetVertexbuffer(Size : Cardinal) : TVertexBuffer;
var
  i : Integer;
  newVb : TVertexBuffer;
begin
  Result := nil;
  for i := 1 to Log2Aufgerundet(Size) + 1 do
  begin
    if FVertexBuffer.Count < i then FVertexBuffer.Add(RDynamicVertexBuffer.Create(nil, 1 shl (i - 1)));
    if Size < FVertexBuffer[i - 1].Size then
    begin
      if FVertexBuffer[i - 1].Vb = nil then
      begin
        newVb := TVertexBuffer.CreateVertexBuffer(FVertexBuffer[i - 1].Size, FUsage, FDevice);
        FVertexBuffer[i - 1] := RDynamicVertexBuffer.Create(newVb, FVertexBuffer[i - 1].Size);
      end;
      Result := FVertexBuffer[i - 1].Vb;
      break;
    end;
  end;
  assert(assigned(Result));
  FCurrentvertexbuffer := Result;
end;

{ TVertexBufferList.RDynamicVertexBuffer }

constructor TVertexBufferList.RDynamicVertexBuffer.Create(Vb : TVertexBuffer; Size : Cardinal);
begin
  self.Vb := Vb;
  self.Size := Size;
end;

{ TFontCache }

procedure TFontCache.AddDrawnFont(const Key : RFontCacheKey; DrawnFont : TTexture);
var
  Count : Integer;
begin
  if FCacheReferences.TryGetValue(Key, Count) then
      FCacheReferences.AddOrSetValue(Key, Count + 1)
  else
  begin
    FCacheReferences.AddOrSetValue(Key, 1);
    FCache.Add(Key, DrawnFont);
  end;
  CleanCache;
end;

procedure TFontCache.CleanCache;
var
  Pairs : TArray<TPair<RFontCacheKey, Integer>>;
  i : Integer;
begin
  if FCache.Count > CACHE_TARGET_SIZE then
  begin
    Pairs := FCacheReferences.ToArray;
    for i := 0 to Length(Pairs) - 1 do
      if Pairs[i].Value <= 0 then
      begin
        FCache.Remove(Pairs[i].Key);
        FCacheReferences.Remove(Pairs[i].Key);
      end;
  end;
end;

procedure TFontCache.ClearCache;
begin
  FCache.Clear;
  FCacheReferences.Clear;
end;

constructor TFontCache.Create;
var
  Comparer : IEqualityComparer<RFontCacheKey>;
begin
  Comparer := TEqualityComparer<RFontCacheKey>.Construct(
    (
    function(const Left, Right : RFontCacheKey) : boolean
    begin
      Result := Left = Right;
    end),
    (
    function(const L : RFontCacheKey) : Integer
    begin
      Result := L.Hash;
    end));
  FCache := TObjectDictionary<RFontCacheKey, TTexture>.Create([doOwnsValues], Comparer);
  FCacheReferences := TDictionary<RFontCacheKey, Integer>.Create(Comparer);
end;

destructor TFontCache.Destroy;
begin
  assert(FCache.Count <= 0, 'TFontCache.Destroy: Cache is not empty on destroy!');
  FCache.Free;
  FCacheReferences.Free;
  inherited;
end;

procedure TFontCache.RemoveDrawnFont(const Key : RFontCacheKey);
var
  Count : Integer;
begin
  if FCacheReferences.TryGetValue(Key, Count) then
  begin
    Count := Count - 1;
    FCacheReferences.AddOrSetValue(Key, Count);
    assert(Count >= 0, 'TFontCache.RemoveDrawnFont: Remove of texture already at zero refs!');
  end
  else
  begin
    {$IFDEF DEBUG}
    assert(False, 'TFontCache.RemoveDrawnFont: Remove of texture not present in cache!');
    {$ENDIF}
  end;
  CleanCache;
end;

function TFontCache.TryGetDrawnFont(const Key : RFontCacheKey; out DrawnFont : TTexture) : boolean;
begin
  Result := FCache.TryGetValue(Key, DrawnFont);
end;

{ RFontCacheKey }

constructor RFontCacheKey.Create(const Text : string; const Desc : RFontDescription; Format : SetFontRenderingFlags; const Size, RealSize : RIntVector2; const Border : RFontBorder; const Color : Cardinal; const Resolution : single);
begin
  self.Text := Text;
  self.Desc := Desc;
  self.Format := Format;
  self.Size := Size;
  self.RealSize := RealSize;
  self.Border := Border;
  self.Color := Color;
  self.Resolution := Resolution;
end;

class operator RFontCacheKey.equal(const L, R : RFontCacheKey) : boolean;
begin
  Result := (L.Text = R.Text) and
    (L.Desc = R.Desc) and
    (L.Format = R.Format) and
    (L.Size = R.Size) and
    ((not L.IsRealSizeDependend and not R.IsRealSizeDependend) or (L.RealSize = R.RealSize)) and
    (L.Border = R.Border) and
    (L.Color = R.Color) and
    (round(L.Resolution * 100) = round(R.Resolution * 100));
end;

function RFontCacheKey.Hash : Integer;
var
  Res : Integer;
begin
  Res := round(Resolution * 100);
  Result := THashBobJenkins.GetHashValue(Text) xor
    Desc.Hash xor
    THashBobJenkins.GetHashValue(Format, SizeOf(SetFontRenderingFlags)) xor
    Size.Hash xor
    Border.Hash xor
    THashBobJenkins.GetHashValue(Color, SizeOf(Cardinal)) xor
    THashBobJenkins.GetHashValue(Res, SizeOf(Integer));
  if IsRealSizeDependend then
      Result := Result xor RealSize.Hash;
end;

function RFontCacheKey.IsRealSizeDependend : boolean;
begin
  Result := [ffCenter, ffVerticalCenter, ffRight, ffBottom] * self.Format <> [];
end;

{ TTextureQualityManager }

procedure TTextureQualityManager.AddOffset(const RelativeFilePath : string; Offset : Integer);
begin
  FQualityOffset.Add(RTuple<string, Integer>.Create(HFilepathManager.UnifyPath(RelativeFilePath), Offset));
end;

procedure TTextureQualityManager.ClearOffsets;
begin
  FQualityOffset.Clear;
end;

constructor TTextureQualityManager.Create;
begin
  FQualityOffset := TList < RTuple < string, Integer >>.Create;
end;

destructor TTextureQualityManager.Destroy;
begin
  FQualityOffset.Free;
  inherited;
end;

function TTextureQualityManager.GetOffset(FilePath : string) : Integer;
var
  i : Integer;
begin
  Result := DefaultOffset;
  FilePath := HFilepathManager.UnifyPath(FilePath);
  for i := 0 to FQualityOffset.Count - 1 do
    if FilePath.Contains(FQualityOffset[i].A) then
        exit(FQualityOffset[i].b);
end;

{ TFontNode }

constructor TFontNode.CreateNode(Parent : TFontNode);
begin
  FParent := Parent;
  FChildren := TObjectList<TFontNode>.Create;
end;

destructor TFontNode.Destroy;
begin
  FColor.Free;
  FWeight.Free;
  FStretch.Free;
  FStyle.Free;
  FChildren.Free;
  inherited;
end;

function TFontNode.Text : string;
var
  i : Integer;
begin
  Result := '';
  if FText = '' then
  begin
    for i := 0 to FChildren.Count - 1 do
        Result := Result + FChildren[i].Text;
  end
  else
      Result := FText;
end;

function TFontNode.BuildTextAttributes : TObjectList<TTextAttribute>;
var
  i : Integer;
begin
  Result := TObjectList<TTextAttribute>.Create;
  BuildTextAttributesRecursive(Result, 0);
  // base ranges are at the end, so we have to reverse the order for the optimization
  Result.Reverse;
  for i := Result.Count - 1 downto 0 do
  begin
    if Result[i].IsEmpty then
        Result.Delete(i)
    else if (i > 0) and (Result[i].StartIndex = Result[i - 1].StartIndex) and (Result[i].Length = Result[i - 1].Length) then
    begin
      Result[i - 1].Merge(Result[i]);
      Result.Delete(i);
    end;
  end;
end;

function TFontNode.BuildTextAttributesRecursive(Attributes : TObjectList<TTextAttribute>; CurrentIndex : Integer) : Integer;
var
  i : Integer;
  Attribute : TTextAttribute;
begin
  if FText = '' then
  begin
    Result := 0;
    Attribute := TTextAttribute.Create;
    Attribute.StartIndex := CurrentIndex;
    for i := 0 to FChildren.Count - 1 do
        Result := Result + FChildren[i].BuildTextAttributesRecursive(Attributes, CurrentIndex + Result);
    Attribute.Length := Result;
    Attribute.Color := FColor.Clone;
    Attribute.Weight := FWeight.Clone;
    Attribute.Stretch := FStretch.Clone;
    Attribute.Style := FStyle.Clone;
    Attributes.Add(Attribute);
  end
  else
  begin
    {$IFDEF DEBUG}
    assert(FChildren.Count <= 0);
    {$ENDIF}
    Result := Length(FText);
  end;
end;

constructor TFontNode.Create(const Text : string);
var
  i : Integer;
  CurrentBlock, Token : string;
  CurrentNode : TFontNode;
  procedure AddTextBlock();
  begin
    if CurrentBlock <> '' then
    begin
      CurrentNode.FChildren.Add(TFontNode.CreateNode(CurrentNode));
      CurrentNode.FChildren.Last.FText := CurrentBlock;
      CurrentBlock := '';
    end;
  end;

begin
  // init root node
  CreateNode(nil);
  CurrentNode := self;

  CurrentBlock := '';
  i := 1;
  while i <= Length(Text) do
  begin
    if (Text[i] = '|') and (i + 1 <= Length(Text)) then
    begin
      Token := Text[i + 1];
      if Token = '|' then
      begin
        // passed as single '|'
        inc(i);
      end
      else if Token = 'n' then
      begin
        CurrentBlock := CurrentBlock + sLineBreak;
        inc(i, 2);
      end
      else if Token = 'r' then
      begin
        AddTextBlock;
        // close block - if already at root, syntax is wrong, but ignore it for robustness
        if assigned(CurrentNode.FParent) then
            CurrentNode := CurrentNode.FParent;
        inc(i, 2);
        continue;
      end
      else if Token = 'i' then
      begin
        AddTextBlock;
        CurrentNode.FChildren.Add(TFontNode.CreateNode(CurrentNode));
        CurrentNode := CurrentNode.FChildren.Last;
        CurrentNode.FStyle := TNullable<EnumFontStyle>.Create(fsItalic);
        inc(i, 2);
        continue;
      end
      else if Token = 'o' then
      begin
        AddTextBlock;
        CurrentNode.FChildren.Add(TFontNode.CreateNode(CurrentNode));
        CurrentNode := CurrentNode.FChildren.Last;
        CurrentNode.FStyle := TNullable<EnumFontStyle>.Create(fsOblique);
        inc(i, 2);
        continue;
      end
      else if TRegex.StartsWithAt(Text, i + 1, 'c([0-9A-F]{6})', Token, [roSingleLine]) then
      begin
        AddTextBlock;
        CurrentNode.FChildren.Add(TFontNode.CreateNode(CurrentNode));
        CurrentNode := CurrentNode.FChildren.Last;
        CurrentNode.FColor := TNullable<RColor>.Create(RColor.CreateFromString('$FF' + Token));
        inc(i, 8);
        continue;
      end
      else if TRegex.StartsWithAt(Text, i + 1, 'b([0-9]{4})', Token, [roSingleLine]) then
      begin
        AddTextBlock;
        CurrentNode.FChildren.Add(TFontNode.CreateNode(CurrentNode));
        CurrentNode := CurrentNode.FChildren.Last;
        CurrentNode.FWeight := TNullable<EnumFontWeight>.Create(ConvertFontWeight(StrToInt(Token)));
        inc(i, 6);
        continue;
      end
      else if TRegex.StartsWithAt(Text, i + 1, 's([0-9]{3})', Token, [roSingleLine]) then
      begin
        AddTextBlock;
        CurrentNode.FChildren.Add(TFontNode.CreateNode(CurrentNode));
        CurrentNode := CurrentNode.FChildren.Last;
        CurrentNode.FStretch := TNullable<EnumFontStretch>.Create(ConvertFontStretch(StrToInt(Token)));
        inc(i, 5);
        continue;
      end;
    end;
    // if escape sequence could not be parsed it is passed normally
    CurrentBlock := CurrentBlock + Text[i];
    inc(i);
  end;
  AddTextBlock;
end;

{ TTextAttribute }

destructor TTextAttribute.Destroy;
begin
  Color.Free;
  Weight.Free;
  Stretch.Free;
  Style.Free;
  inherited;
end;

function TTextAttribute.IsEmpty : boolean;
begin
  Result := (Length <= 0) or
    (not assigned(Color) and not assigned(Stretch) and not assigned(Weight) and not assigned(Style));
end;

procedure TTextAttribute.Merge(AnotherAttribute : TTextAttribute);
begin
  if assigned(AnotherAttribute.Color) then
  begin
    self.Color.Free;
    self.Color := AnotherAttribute.Color;
    AnotherAttribute.Color := nil;
  end;
  if assigned(AnotherAttribute.Weight) then
  begin
    self.Weight.Free;
    self.Weight := AnotherAttribute.Weight;
    AnotherAttribute.Weight := nil;
  end;
  if assigned(AnotherAttribute.Stretch) then
  begin
    self.Stretch.Free;
    self.Stretch := AnotherAttribute.Stretch;
    AnotherAttribute.Stretch := nil;
  end;
  if assigned(AnotherAttribute.Style) then
  begin
    self.Style.Free;
    self.Style := AnotherAttribute.Style;
    AnotherAttribute.Style := nil;
  end;
end;

function TTextAttribute.ToTTextAttributedRange(Origin : FMX.TextLayout.TTextLayout) : TTextAttributedRange;
var
  NewFont : FMX.Graphics.TFont;
  StyleExt : TFontStyleExt;
begin
  NewFont := FMX.Graphics.TFont.Create;
  NewFont.Assign(Origin.Font);
  Result := TTextAttributedRange.Create(TTextRange.Create(StartIndex, Length), FMX.TextLayout.TTextAttribute.Create(NewFont, Origin.Color));
  if assigned(Color) then
      Result.Attribute.Color := Color.Value.AsCardinal
  else
      Result.Attribute.Color := Origin.Color;

  StyleExt := NewFont.StyleExt;
  if assigned(Weight) then
      StyleExt.Weight := TFontWeight(Weight.Value);
  if assigned(Stretch) then
      StyleExt.Stretch := TFontStretch(Stretch.Value);
  if assigned(Style) then
      StyleExt.Slant := TFontSlant(Style.Value);
  NewFont.StyleExt := StyleExt;
end;

initialization

TextureQualityManager := TTextureQualityManager.Create;
FontCache := TFontCache.Create;
// FMX.Types.GlobalUseDirect2D := False;
FMX.Types.GlobalUseGPUCanvas := False;
FMX.Types.GlobalUseGDIPlusClearType := False;
// FMX.Types.GlobalUseGPUCanvas := true;
FMX.Canvas.D2D.TCustomCanvasD2D.SharedDevice;
HArray.Each<string>(HSystem.RegisteredFonts,
  procedure(const Path : string)
  begin
    FMX.Canvas.D2D.TCustomCanvasD2D.LoadFontFromFile(Path);
  end);

finalization

FontCache.Free;
TextureQualityManager.Free;
// fix memory leaks
FMX.Canvas.D2D.UnregisterCanvasClasses;
// FMX.Canvas.GPU.UnregisterCanvasClasses;

end.
