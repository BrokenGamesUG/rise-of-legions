unit Engine.GUI;

interface

uses
  Windows,
  System.Hash,
  System.Types,
  System.Classes,
  SysUtils,
  StrUtils,
  System.Threading,
  System.SyncObjs,
  Generics.Defaults,
  Generics.Collections,
  Engine.Expression,
  Engine.DataQuery,
  Engine.Core,
  Engine.Core.Types,
  Engine.Helferlein,
  Engine.Helferlein.Threads,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Vertex,
  Engine.Serializer.Types,
  Engine.Serializer,
  Engine.Input,
  Engine.Log,
  Engine.dXML,
  RTTI,
  Math,
  RegularExpressions,
  Vcl.Clipbrd;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  EnumCursor = (crDefault, crClickable, crText, crHint);
  EnumComponentAnchor = (caTopLeft, caTop, caTopRight, caLeft, caCenter, caRight, caBottomLeft, caBottom, caBottomRight, caAuto);
  EnumKeyEvent = (keDown, keUp);
  /// <summary>
  /// dsScreenSpace - Position, Size, Orientation in ScreenSpace
  /// dsViewSpace - not implemented yet
  /// dsWorldSpace - Position, Size, Orientation in WorldSpace
  /// dsWorldScreenSpace - Position in WorldSpace, Size and Orientation in ScreenSpace
  /// </summary>
  EnumDrawSpace = (dsScreenSpace, dsViewSpace, dsWorldSpace, dsWorldScreenSpace);
  EnumBackgroundRepeat = (brNone, brStretch, brRepeat, brMask, brAuto);
  EnumStackOrientation = (soHorizontal, soVertical);
  EnumNullableBoolean = (nbUnset, nbTrue, nbFalse);
  EnumOverwritableBoolean = (obStyleTrue, obStyleFalse, obForceTrue, obForceFalse);
  EnumBackgroundAnchor = (baTopLeft, baTopRight, baBottomRight, baBottomLeft);
  EnumProgressShape = (psNone, psLinear, psRadial);
  EnumBorderSides = (bsTop, bsRight, bsBottom, bsLeft);
  SetBorderSides = set of EnumBorderSides;
  EnumBorderLocation = (blOutline, blMiddle, blInset);
  EnumOverflowHandling = (ohNone, ohClip, ohScrollX, ohScrollY, ohScroll);
  EnumBoxSizing = (bsContent, bsMargin, bsPadding);
  EnumParentBox = (pbContent, pbPadding, pbMargin);
  EnumTextTransform = (ttNone, ttUppercase, ttLowercase, ttCapitalize);
  EnumTransformOrder = (toTransformAnimation, toAnimationTransform);
  /// <summary>
  /// meAll - Reacts to clicks and hovers and nothing pass through
  /// mePass - Reacts to nothing and all pass through
  /// mePassClick - Reacts to hover and clicks pass through
  /// meBlock - Reacts to nothing and nothing pass through
  /// </summary>
  EnumMouseEvent = (meAll, mePass, mePassClick, meBlock);
  EnumAnimationDirection = (adNormal, adReverse, adAlternate, adAlternateReverse);
  EnumAnimationFillMode = (afNone, afForwards, afBackwards, afBoth);
  EnumGSSTag = (gtNone, gtDirty, gtDirtyChildren, gtDirtyGrandChildren,
    gtPosition, gtDrawSpace, gtSize, gtMinSize, gtMaxSize, gtAnchor, gtParentAnchor, gtPadding, gtZOffset, gtParentOffset, gtParentBox, gtOverflow, gtBoxSizing, gtMargin,
    gtScrollbarWidth, gtScrollbarPadding, gtScrollbarBackgroundColor, gtScrollbarBackgroundColorHover, gtScrollbarBackgroundColorElementHover,
    gtScrollbarColor, gtScrollbarColorHover, gtScrollbarColorElementHover,
    gtBackground, gtBackgroundHover, gtBackgroundDown, gtBackgroundDisabled, gtBackgroundMipMapping, gtBackgroundMask,
    gtBackgroundColor, gtBackgroundColorHover, gtBackgroundColorDown, gtBackgroundColorDisabled,
    gtBackgroundrepeat, gtBackgroundAnchor, gtBackgroundMipMapLodBias, gtBorderImage, gtBackgroundShader,
    gtBackgroundColorOverride, gtBackgroundColorOverrideInheritance,
    gtBorder, gtBorderSides, gtOutline, gtOutlineSides,
    gtBlur, gtBlurLayer, gtBlurColor, gtBlurMask,
    gtEnabled, gtVisibility, gtMouseEvents, gtFocus, gtObscureText, gtTextMaxLength, gtOpacity, gtOpacityInheritance,
    gtDefaultText, gtText, gtTextTransform, gtFontsize, gtFontfamily, gtFontWeight, gtFontStyle, gtFontStretch, gtFontQuality,
    gtFontflags, gtFontcolor, gtFontBorder, gtFontResolution,
    gtStackorientation, gtStackpartitioning, gtStackcolumns, gtStackAnchor, gtItemTemplate,
    gtProgressposition, gtProgressmaximum, gtProgressshape,
    gtFrameFile, gtCursor,
    gtHint, gtHintTemplate, gtHintClasses, gtHintAnchor, gtHintOffset,
    gtZoom, gtTransform, gtTransformAnchor, gtTransformOrder, gtTransformKeepBackground, gtTransformInheritance,
    gtTransitionProperty, gtTransitionDuration, gtTransitionTimingFunction, gtTransitionWithInheritance,
    gtAnimationDelay, gtAnimationDirection, gtAnimationDuration, gtAnimationFillMode, gtAnimationIterationCount, gtAnimationOffset,
    gtAnimationName, gtAnimationTimingFunction, gtAnimationBackgroundSpriteSize, gtAnimationBackgroundSpriteCount,
    gtSceneName, gtSceneCamera, gtSceneSuperSampling);
  SetGSSTag = set of EnumGSSTag;

const
  AllGSSTags : SetGSSTag = [low(EnumGSSTag) .. high(EnumGSSTag)];

  OVERFLOW_CLIPPING_VALUES = [ohClip, ohScrollX, ohScrollY, ohScroll];

  // root node inherit some global values
  ROOT_INHERITED_TAGS : SetGSSTag = [gtFontcolor, gtFontfamily, gtFontsize, gtFontWeight, gtFontStyle, gtFontStretch, gtFontQuality,
    gtBlurColor, gtBackgroundMipMapLodBias];

  // all tags which can have changes for children
  CHILDRENAFFECTINGTAGS : SetGSSTag = [gtPosition, gtSize, gtMinSize, gtMaxSize, gtAnchor, gtParentAnchor,
    gtStackorientation, gtStackpartitioning, gtStackcolumns, gtPadding, gtMargin, gtProgressposition,
    gtProgressmaximum, gtZOffset, gtParentOffset, gtOverflow, gtBoxSizing, gtMargin, gtOpacity, gtDefaultText, gtText, gtTextTransform] +
    [gtFontcolor, gtFontfamily, gtFontsize, gtFontWeight, gtFontStyle, gtFontStretch, gtFontQuality, gtBlurColor, gtBackgroundMipMapLodBias]; // + INHERITED_TAGS

type
  /// ///////////////////////////////////////////////////////////////////////////
  /// EVENTS thrown by GUI
  /// ///////////////////////////////////////////////////////////////////////////

  EnumGUIEvent = (
    /// <summary> Thrown for each event. </summary>
    geAll,
    /// <summary> Thrown when User hits Enter in an editfield. </summary>
    geSubmit,
    /// <summary> Thrown when User clicks with the left mouse button on an enabled component. </summary>
    geClick,
    /// <summary> Thrown when User clicks with the left mouse button on an enabled component. </summary>
    geRightClick,
    /// <summary> Thrown when User alters the value of a edit. </summary>
    geChanged,
    /// <summary> Thrown when User presses the mouse down on an enabled component. </summary>
    geMouseDown,
    /// <summary> Thrown when User releases the mouse button on an enabled component. </summary>
    geMouseUp,
    /// <summary> Thrown when an editfield gets the writefocus. </summary>
    geFocus,
    /// <summary> Thrown when an editfield lost the writefocus. </summary>
    geBlur,
    /// <summary> Thrown when the Mouse enters a component. </summary>
    geMouseEnter,
    /// <summary> Thrown when the Mouse leaves a component. </summary>
    geMouseLeave,
    /// <summary> Thrown when a Hint is been displayed. Additional data contains the hint which will be displayed. </summary>
    geHint
    );

const
  HINTNAME = 'Hint';

  HINT_DEPTH = 900000;

  HINT_FILE_COMMAND = 'hintfile>';

  MOUSEWHEEL_SCROLLSPEED = 50.0;
  FONT_WEIGHT_EPSILON    = 10;

  GSS_CLASS_PREFIX = '.';
  GSS_NAME_PREFIX  = '#';
  GSS_ALL_CLASS    = '*';

type
  RGSSSpaceData = record
    type
      EnumSpaceDataType = (
        vtInherit, vtAuto, vtAbsolute, vtAbsoluteScreen, vtText,
        vtRelative,
        vtRelativeContainerWidth, vtRelativeContainerHeight,
        vtRelativeParentWidth, vtRelativeParentHeight,
        vtRelativeViewWidth, vtRelativeViewHeight,
        vtRelativeScreenWidth, vtRelativeScreenHeight,
        vtRelativeBackgroundWidth, vtRelativeBackgroundHeight);
    var
      SpaceType : EnumSpaceDataType;
      Value : single;
      function IsRelative : boolean; inline;
      function IsAbsolute : boolean; inline;
      function IsAbsoluteScreen : boolean; inline;
      function IsAuto : boolean; inline;
      function IsText : boolean; inline;
      function IsInherit : boolean; inline;
      function IsZero : boolean; inline;
      function IsRelativeContext : boolean; inline;
      function IsRelativeContainerWidth : boolean; inline;
      function IsRelativeContainerHeight : boolean; inline;
      function IsRelativeParentWidth : boolean; inline;
      function IsRelativeParentHeight : boolean; inline;
      function IsRelativeViewWidth : boolean; inline;
      function IsRelativeViewHeight : boolean; inline;
      function IsRelativeScreenWidth : boolean; inline;
      function IsRelativeScreenHeight : boolean; inline;
      function IsRelativeBackgroundWidth : boolean; inline;
      function IsRelativeBackgroundHeight : boolean; inline;
      function Resolve(Dim : integer; const Rect, ParentRect : RRectFloat) : single;
      constructor CreateFromString(Value : string);
      class function CreateMultiFromString(Value : string) : TArray<RGSSSpaceData>; overload; static;
      constructor CreateAbsolute(Value : single); overload;
      class function CreateAbsolute(Values : array of single) : TArray<RGSSSpaceData>; overload; static;
      constructor CreateAbsoluteScreen(Value : single); overload;
      class function CreateAbsoluteScreen(Values : array of single) : TArray<RGSSSpaceData>; overload; static;
      constructor CreateRelative(Value : single); overload;
      class function CreateRelative(Values : array of single) : TArray<RGSSSpaceData>; overload; static;
      constructor CreateRelativeContainerWidth(Value : single); overload;
      constructor CreateRelativeContainerHeight(Value : single); overload;
      constructor CreateRelativeParentWidth(Value : single); overload;
      constructor CreateRelativeParentHeight(Value : single); overload;
      constructor CreateRelativeViewWidth(Value : single); overload;
      constructor CreateRelativeViewHeight(Value : single); overload;
      constructor CreateRelativeScreenWidth(Value : single); overload;
      constructor CreateRelativeScreenHeight(Value : single); overload;
      constructor CreateRelativeBackgroundWidth(Value : single); overload;
      constructor CreateRelativeBackgroundHeight(Value : single); overload;
      class function Auto() : RGSSSpaceData; static;
      class function Inherit() : RGSSSpaceData; static;
      class function Text(OverrideFontWeight : integer = 0) : RGSSSpaceData; static;
      class operator implicit(a : RGSSSpaceData) : RParam;
      class operator implicit(a : RGSSSpaceData) : string;
      class operator equal(a, b : RGSSSpaceData) : boolean;
  end;

  TGUI = class;

  {$RTTI EXPLICIT METHODS([vcPublic]) PROPERTIES([vcPublic, vcProtected, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  [XMLExcludeAll]
  /// <summary> Stores the styledata of a component. Written in GSS (GUI Style Sheets)
  /// For Tag-Reference see Confluence.
  /// </summary>
  TGUIStyleSheet = class
    strict private
      class var StyleSheetIDCounter : integer;
    strict private
      FID : integer;
      FGUI : TGUI;
      FData : array [EnumGSSTag] of TList<RParam>;
      FCoveredTags : SetGSSTag;
      function getDataAsText : string;
      procedure setDataAsText(const Data : string);
      function ParseGSSParamToValue(const Tag : EnumGSSTag; const Value : string; const Index : integer) : RParam;
      procedure ImportDataAsText(gss : string);
      /// <summary> Appends the resolved values to Values if there is a constant. Returns True if this method did something. </summary>
      function TryResolveConstantValues(const Tag : EnumGSSTag; const Value : string; Values : TList<RParam>) : boolean;
      procedure PutError(const msg : string);
      function GetDefaultValue(Style : EnumGSSTag; Index : integer) : RParam; overload;
    protected
      /// <summary> Add or set the value at position index in the style. Returns whether the value differs to the previous value. </summary>
      function AddOrSetValue<T>(Stylename : EnumGSSTag; Index : integer; const Value : T) : boolean; overload;
      /// <summary> Add or set the value at position 0 in the style. Returns whether the value differs to the previous value. </summary>
      function AddOrSetValue<T>(Stylename : EnumGSSTag; const Value : T) : boolean; overload;
      /// <summary> Add or set the value in the style. Returns always true. </summary>
      function AddOrSetValue<T>(Stylename : EnumGSSTag; Value : array of T) : boolean; overload;
      function ValueCount(Stylename : EnumGSSTag) : integer;
      function GetDefaultValue<T>(Style : EnumGSSTag; Index : integer) : T; overload;
      function TryGetValue<T>(Stylename : EnumGSSTag; Index : integer; out Value : T) : boolean; overload;
      /// <summary> Returns all set 0-indexed values. </summary>
      function Items : TDictionary<EnumGSSTag, RParam>;
      class function ResolveTransform(const TransformValue : string) : RMatrix4x3;
    public
      property ID : integer read FID;
      property CoveredTags : SetGSSTag read FCoveredTags;
      [XMLIncludeElement]
      property DataAsText : string read getDataAsText write setDataAsText;
      /// <summary> Creates an empty style </summary>
      constructor Create; overload;
      /// <summary> Creates an empty style. GUI is only needed for erroroutput while parsing. </summary>
      constructor Create(GUI : TGUI); overload;
      /// <summary> Creates a style from file containing a gss-string. GUI is only needed for erroroutput while parsing. </summary>
      constructor CreateFromFile(const Filename : string; GUI : TGUI = nil);
      /// <summary> Creates a style from gss-string. GUI is only needed for erroroutput while parsing. </summary>
      constructor CreateFromText(const gss : string; GUI : TGUI = nil);
      /// <summary> Adds definitions to the stylesheet overriding doubled definitions. </summary>
      procedure AddDataAsText(const Data : string);
      /// <summary> Adds definitions to the stylesheet. If OverrideExisting is set, existing definitions are overriden. </summary>
      procedure AddDefinitionsFromStyleSheet(const AnotherStylesheet : TGUIStyleSheet; OverrideExisting : boolean);
      /// <summary> Skadoosh </summary>
      destructor Destroy; override;
      class function CSSStrToFloat(const Value : string; Default : single = 0) : single;
      class function TryCSSStrToFloat(Value : string; out ParsedValue : single) : boolean;
      class constructor Create;
  end;

  // in ascending order of importance
  EnumPseudoClass = (pcNone, pcFirstChild, pcLastChild, pcChecked, pcHover, pcEnabled, pcDisabled, pcDown,
    pcFocus, pcScrollable, pcShowing, pcHiding, pcEven, pcOdd);
  SetPseudoClass = set of EnumPseudoClass;

  TGUIStyleNode = class;
  TGUIStyleManager = class;

  TGUIStyleManagerHandle = class
    strict private
      FManager : TGUIStyleManager;
      FVersion : integer;
    public
      constructor Create(Manager : TGUIStyleManager);
      function IsValid : boolean;
  end;

  TGUIAnimationStack = class
    strict private
      FAnimationKeys : TObjectDictionary<EnumGSSTag, TList<RTriple<single, RCubicBezier, RParam>>>;
    public
      constructor CreateFromString(const AnimationData : string);
      /// <summary> Returns the current value of the tag, if not specified returns empty. </summary>
      function Interpolate(const Key : single; Tag : EnumGSSTag) : RParam;
      function HasTag(Tag : EnumGSSTag) : boolean;
      destructor Destroy; override;
  end;

  TGUIAnimationStackHandle = class(TGUIStyleManagerHandle)
    public
      AnimationStack : TGUIAnimationStack;
      constructor Create(Manager : TGUIStyleManager; AnimationStack : TGUIAnimationStack);
  end;

  RGUIStyleSheet = record
    Specificity : RIntVector2;
    Style : TGUIStyleSheet;
    FullIdentifier : string;
    constructor Create(const Specificity : RIntVector2; Style : TGUIStyleSheet; const FullIdentifier : string);
    class operator equal(const a, b : RGUIStyleSheet) : boolean;
    class operator notequal(const a, b : RGUIStyleSheet) : boolean;
  end;

  TGUIStyleSheetStack = class
    strict private
      FManager : TGUIStyleManager;
      FStyles : TList<RGUIStyleSheet>;
      FSquashedStyles : TGUIStyleSheet;
      FCoveredTags : SetGSSTag;
      FHash : integer;
      FStyleIDs : TList<RTuple<integer, SetGSSTag>>;
    protected
      procedure AddStyleSheet(Stylesheet : RGUIStyleSheet);
      procedure FinalizeStack;
    public
      property Hash : integer read FHash;
      property CoveredTags : SetGSSTag read FCoveredTags;
      constructor Create(Manager : TGUIStyleManager);
      function TryGetValue<T>(Stylename : EnumGSSTag; Index : integer; out Value : T) : boolean;
      function ValueCount(Stylename : EnumGSSTag) : integer;
      function ComputedStyles : string;
      function IsEqual(const AnotherStack : TGUIStyleSheetStack) : boolean;
      function ChangedTags(const AnotherStack : TGUIStyleSheetStack) : SetGSSTag;
      destructor Destroy; override;
  end;

  TGUIStyleSheetStackHandle = class(TGUIStyleManagerHandle)
    public
      StyleSheetStack : TGUIStyleSheetStack;
      constructor Create(Manager : TGUIStyleManager; StyleSheetStack : TGUIStyleSheetStack);
  end;

  TMultiStyleNode = class
    PseudoClass : SetPseudoClass;
    Node : TGUIStyleNode;
    Specificity : RIntVector2;
    constructor Create(const PseudoClass : SetPseudoClass; Node : TGUIStyleNode; const Specificity : RIntVector2);
    destructor Destroy; override;
  end;

  RClassTag = record
    strict private
      function GetClassName : string;
    public
      IsChild, IsMulti : boolean; // IsChild: otherwise it's descendant
      ClassIndex : integer;
      PseudoClasses : SetPseudoClass;
      CustomSpecificity : RIntVector2;
      MultiClassIndex : TArray<integer>;
      function IsParent : boolean;
      constructor Create(ClassIndex : integer; PseudoClasses : SetPseudoClass);
      property ClassName : string read GetClassName;
      function Specificity : RIntVector2;
      /// <summary> Merges two class tags removing & and making them multi. </summary>
      function Merge(const ClassTag : RClassTag) : RClassTag;
      function ClassIndices : TArray<integer>;
      function Hash : integer;
      class operator equal(const L, R : RClassTag) : boolean;
  end;

  TClassHierarchyNode = class(TList<RClassTag>)
    strict private
      FMulticlassReady : boolean;
      FMulticlass : RClassTag;
      FHashReady : boolean;
      FHash : integer;
    public
      function Clone : TClassHierarchyNode;
      function Hash : integer;
      function Multiclass : RClassTag;
  end;

  TClassHierarchy = class(TObjectList<TClassHierarchyNode>)
    strict private
      FHashReady : boolean;
      FHash : integer;
    public
      function Clone : TClassHierarchy;
      function Hash : integer;
      function CompareTo(const R : TClassHierarchy) : boolean;
  end;

  /// <summary> A tree node of the style tree. </summary>
  TGUIStyleNode = class
    private
      /// <summary> Nested definitions of single classes. </summary>
      FDescendants : TObjectDictionary<integer, TObjectList<TMultiStyleNode>>;
      /// <summary> Nested definitions of direct children classes. </summary>
      FChildren : TObjectDictionary<integer, TObjectList<TMultiStyleNode>>;
      FMultiDescendants : TObjectList<TTuple<TArray<integer>, TObjectList<TMultiStyleNode>>>;
      FMultiChildren : TObjectList<TTuple<TArray<integer>, TObjectList<TMultiStyleNode>>>;
      /// <summary> All styles of this node. </summary>
      FStyles : TGUIStyleSheet;
      FFullIdentifier : string;
    public
      property FullIdentifier : string read FFullIdentifier;
      constructor Create(const FullIdentifier : string);
      procedure AddStylesRecursive(ClassHierarchy : TClassHierarchy; const StylesAsText : string; const Specificity : RIntVector2; Depth : integer = 0);
      procedure BuildStyleStack(ClassHierarchy : TClassHierarchy; Depth : integer; const Specificity : RIntVector2; var Stack : TGUIStyleSheetStack);
      destructor Destroy; override;
  end;

  RGUIStyleConstant = record
    Key : string;
    Value : string;
    KeyParams : TArray<string>;
    constructor Create(const Key, Value : string);
    function Apply(const Text : string) : string;
  end;

  /// <summary> The global manager for style sheets. </summary>
  TGUIStyleManager = class
    strict private
    const
      STYLE_FILE_EXTENTION = '.scss';
    var
      FGUI : TGUI;
      FStyles : TGUIStyleNode;
      FStyleFiles : TList<string>;
      FStyleFileContent : TList<string>;
      FConstants : TList<RGUIStyleConstant>;
      FVersion : integer;
      FCache : TObjectDictionary<TClassHierarchy, TGUIStyleSheetStack>;
      FAnimations : TObjectDictionary<string, TGUIAnimationStack>;
      procedure AddConstant(const Key, Value : string);
      procedure AddAnimation(const Key, Value : string);
      function ResolveConstants(const StyleBlock : string) : string;
      procedure IncVersion;
      class var FLock : TCriticalSection;
      class var FClassMapping : TDictionary<string, integer>;
      class var FReverseClassMapping : TList<string>;
    protected
      procedure FileDirtyCallback(const Filepath : string; const Filecontent : string);
      function BuildStyleStack(ClassHierarchy : TClassHierarchy) : TGUIStyleSheetStackHandle;
      function LoadStylesFromText(const StyleText : string) : string;
      function GetAnimationStack(const AnimationName : string) : TGUIAnimationStackHandle;
    public
      property CurrentVersion : integer read FVersion;
      constructor Create(Owner : TGUI);
      procedure LoadStylesFromFolder(const FolderPath : string);
      procedure LoadStylesFromFile(const Filename : string);
      destructor Destroy; override;

      class constructor Create;
      class function ClassnameSpecificity(ClassIndex : integer) : integer; static;
      class function ResolveClassname(const ClassName : string) : integer; static;
      class function ResolveClassnames(const ClassNames : array of string) : TArray<integer>; static;
      class function RemapClassname(ClassIndex : integer) : string; static;
      class destructor Destroy;
  end;

  TGUIComponent = class;

  RGUIEvent = record
    /// <summary> The event type. </summary>
    Event : EnumGUIEvent;
    /// <summary> The name of the sending component, may not be unique. </summary>
    Name : string;
    /// <summary> The unique ID of the sending component. </summary>
    UID : integer;
    /// <summary> The sending component, may not be valid. Before use test with IsValid! </summary>
    Component : TGUIComponent;
    /// <summary> The respective GUI-Context. </summary>
    GUI : TGUI;
    /// <summary> Additional data shipping with a specific event. </summary>
    AdditionalData : NativeUInt;
    function IsValid : boolean;
    /// <summary> Returns whether the additional data could be cast to a component. </summary>
    function IsAdditionalDataValid : boolean;
    function AdditionalDataToComponent : TGUIComponent;
    function TryAdditionalDataToComponent(out Component : TGUIComponent) : boolean;
    function TryGetParent(const ParentName : string; out Parent : TGUIComponent) : boolean;
    constructor Create(Event : EnumGUIEvent; Component : TGUIComponent); overload;
    constructor Create(Event : EnumGUIEvent; const Name : string; UID : integer; Component : TGUIComponent; GUI : TGUI); overload;
    constructor CreateFromUID(Event : EnumGUIEvent; UID : integer; GUI : TGUI);
    function IsAny(Names : array of string) : boolean;
    function SetAdditionalData(Data : NativeUInt) : RGUIEvent; overload;
    function SetAdditionalData(Data : TGUIComponent) : RGUIEvent; overload;
    /// <summary> Shorthand for ((Sender = Name) and Sender.IsValid) </summary>
    function Check(const Name : string) : boolean; overload;
    /// <summary> Shorthand for ((Sender in Name) and Sender.IsValid) </summary>
    function Check(const Name : array of string) : boolean; overload;
    /// <summary> Shorthand for Sender.Component.CustomData. </summary>
    function CustomData : NativeUInt;
    /// <summary> Shorthand for Sender.Component.CustomDataAs<T>. </summary>
    function CustomDataAs<T : class> : T;
    /// <summary> Shorthand for Sender.Component.CustomDataAsWrapper<T>. </summary>
    function CustomDataAsWrapper<T> : T;
    /// <summary> The RGUIEvent can directly compared with the name. </summary>
    class operator equal(const a : RGUIEvent; const b : string) : boolean;
    class operator equal(const b : string; const a : RGUIEvent) : boolean;
    class operator notequal(const a : RGUIEvent; const b : string) : boolean;
    class operator notequal(const b : string; const a : RGUIEvent) : boolean;
  end;

  ProcGUIEvent = procedure(const GUIEvent : RGUIEvent) of object;

  /// <summary> Wraps the different component states for a value. </summary>
  RState<T> = record
    Default, Hover, Down, Disabled : T;
    function IsAnySet : boolean;
  end;

  TGUITransitionValue<T> = class abstract
    protected
      FInitialized : boolean;
      FStartValue, FTargetValue : T;
      FStartingTimestamp, FDuration : int64;
      FTimingFunction : RCubicBezier;
      function CurrentFactor : single;
    public
      constructor Create;
      property TimingFunction : RCubicBezier read FTimingFunction write FTimingFunction;
      property Duration : int64 read FDuration write FDuration;
      procedure SetValue(const Value : T); virtual;
      function CurrentValue : T; virtual; abstract;
  end;

  TGUITransitionValueRMatrix4x3 = class(TGUITransitionValue<RMatrix4x3>)
    public
      function CurrentValue : RMatrix4x3; override;
  end;

  TGUITransitionValueRColor = class(TGUITransitionValue<RColor>)
    public
      function CurrentValue : RColor; override;
  end;

  TGUITransitionValueSingle = class(TGUITransitionValue<single>)
    public
      function CurrentValue : single; override;
  end;

  IGUIComponentSet = interface
    function GetItem(Index : integer) : TGUIComponent;
    property Items[index : integer] : TGUIComponent read GetItem; default;
    function Count : integer;
    /// <summary> Applies the method BindClass to all item of this set. </summary>
    function BindClass(const Value : RQuery; const GSSClass : string) : IGUIComponentSet;
  end;

  TGUIComponentSet = class(TInterfacedObject, IGUIComponentSet)
    protected
      FItems : TUltimateList<TGUIComponent>;
      procedure Add(const Component : TGUIComponent);
      function GetItem(Index : integer) : TGUIComponent;
    public
      constructor Create;
      /// <summary> The number of elements in this set. </summary>
      function Count : integer;
      /// <summary> Applies the method BindClass to all item of this set. </summary>
      function BindClass(const Value : RQuery; const GSSClass : string) : IGUIComponentSet;
      destructor Destroy; override;
  end;

  ProcDescendantFilter = reference to function(SiblingIndex, Depth : integer) : boolean;
  ProcTraverse = reference to procedure(item : TGUIComponent);

  [XMLExcludeAll]
  /// <summary> The baseclass for all GUIComponents. </summary>
  TGUIComponent = class(TXMLCustomSerializable)
    strict private
      FScrollRect : RRectFloat;
      FScrollOffset : RVector2;
      FClasses : TList<integer>;
      FClassesAsText : string;
      function Position3D : RVector3;
      function GetTransform : RMatrix4x3;
      function GetOpacity : single;
      function GetBackgroundColorOverride : RColor;
      procedure ChangeStyleFilterDescendantsRecursive<T>(Key : EnumGSSTag; Value : T; Depth : integer; Node : TGUIComponent; Filter : ProcDescendantFilter); overload;
      procedure ChangeStyleFilterDescendantsRecursive<T>(Key : EnumGSSTag; ValueIfTrue, ValueIfFalse : T; Depth : integer; Node : TGUIComponent; Filter : ProcDescendantFilter); overload;
      function GetScreenPos : RVector2;
      function GetScreenSize : RVector2;
      function GetOuterRect : RRectFloat;
      procedure SetOuterRect(const Value : RRectFloat);
      function GetContentRect : RRectFloat;
      procedure SetContentRect(const Value : RRectFloat);
      function GetClassesAsText : string;
      procedure SetClassesAsText(const Value : string);
      procedure SetBackgroundImageSafe(const Value : string);
      function GetItemTemplate(const Index : integer) : string;
      function GetCurrentHint : string;
      procedure SetCurrentHintSafe(const Value : string);
      function GetCurrentTextAsInteger : integer;
      procedure SetCurrentTextAsInteger(const Value : integer);
      procedure SetParent(const Value : TGUIComponent);
      procedure SetScrollRect(const Value : RRectFloat);
      procedure SetScrollOffset(const Value : RVector2);
      procedure SetShow(const Value : EnumNullableBoolean);
    protected// Text
      FHint, FHintTemplate, FHintClasses : string;
      FFont : TVertexFont;
      FFontColor : RColor;
      FLastText, FText, FRawStyleText, FLastStyleText, FStyleText : string;
      function TransformRawText(const Text : string) : string;
      function UpdateText(const Text : string) : boolean;
      function UpdateStyleText(const Text : string) : boolean;
    protected
      FUID : integer;
      FDepthOverride : integer;
      FDirty : SetGSSTag;
      FGUI : TGUI;
      FXMLNode : TdXMLNode;
      [XMLIncludeElement]
      FParent : TGUIComponent;
      FName : string;
      [XMLIncludeElement]
      FChildren : TObjectList<TGUIComponent>;
      [XMLIncludeElement]
      FStyleSheet : TGUIStyleSheet;
      FStyleSheetStackDirty, FClassHierarchyDirty : boolean;
      FStyleSheetStack : TGUIStyleSheetStackHandle;
      FClassHierarchy : TClassHierarchy;
      FElementName : string;
      FRect, FViewRect, FCliprect : RRectFloat;
      FOverflow : EnumOverflowHandling;
      FVisible, FEnabled, FDown : EnumOverwritableBoolean;
      FAnchor : EnumComponentAnchor;
      FHovered, FFocused : boolean;
      FCursor : EnumCursor;
      FShow : EnumNullableBoolean;
      FMouseEvent : EnumMouseEvent;
      FShowAsDisabled, FInitialized : boolean;
      FDrawSpace : EnumDrawSpace;
      FPadding, FMargin : RIntVector4;
      FTransform : RMatrix4x3;
      FTransformKeepBackground, FTransformInheritance : boolean;
      FTransformAnchor : EnumComponentAnchor;
      FTransformOrder : EnumTransformOrder;
      FMouseDown : array [EnumMouseButton] of boolean;
      FBoxSizing : EnumBoxSizing;
      FParentBox : EnumParentBox;
      FOpacity, FZoom, FRotationSpeed : single;
      FOpacityInheritance : boolean;
      FZOffset, FParentOffset : integer;
      // Background
      FDerivedShader : string;
      FMipMapHandling : EnumMipMapHandling;
      FBgTexture : RState<TTexture>;
      FBackgroundMask : TTexture;
      FBlurMask : TTexture;
      FBgColor : array [0 .. 3] of RState<RColor>;
      FBackgroundColorOverrideInheritance : boolean;
      FBackgroundColorOverride : RColor;
      FBorderColorStart, FBorderColorEnd : RColor;
      FOutlineColorStart, FOutlineColorEnd : RColor;
      FBgSheetSize : RIntVector2;
      FBgSheetCount : integer;
      FQuad : TVertexQuad;
      FCoordinateRect : RRectFloat;
      FBackgroundAnchor : EnumBackgroundAnchor;
      FBackgroundRepeatX, FBackgroundRepeatY : EnumBackgroundRepeat;
      FBorderOuter, FBorderInner : single;
      FBorderSides, FOutlineSides : SetBorderSides;
      FOutlineOuter, FOutlineInner : single;
      FBorderImage : array [0 .. 7] of TVertexScreenAlignedQuad; // LeftTop, Top, RightTop, Right, BottomRight, Bottom, BottomLeft, Left
      FBorderImageOffset : RIntVector4;
      // Scrollbars
      FScrollbarWidth : integer;
      FScrollbarHovered : boolean;
      FScrollbarPadding : RIntVector4;
      FScrollbarColor, FScrollbarBackgroundColor : RState<RColor>;
      FScrollbarBackgroundQuad, FScrollbarTrackerQuad : TVertexScreenAlignedQuad;
      // Blur
      FBlurQuad : TVertexScreenAlignedQuad;
      FBlurColor, FBlurColorFallback : RColor;
      FBlur, FBlurLayer : boolean;
      // progress
      FProgressPosition, FProgressmaximum : single;
      FProgressShape : EnumProgressShape;
      // animation
      FCachedCurrentAnimationKey : single;
      FAnimationFinished, FAnimationPaused : boolean;
      FAnimationStartTimestamp : int64;
      FAnimationOffset, FAnimationDelay, FAnimationDelayAfter, FAnimationDuration, FAnimationIterationCount : integer;
      FAnimationDirection : EnumAnimationDirection;
      FAnimationFillMode : EnumAnimationFillMode;
      FAnimationName : string;
      FAnimationStack : TGUIAnimationStackHandle;
      FAnimationTimingFunction : RCubicBezier;
      // transition
      FTransisitonProperties : SetGSSTag;
      FTransisitonTimingFunction : RCubicBezier;
      FTransitionWithInheritance : boolean;
      FTransisitonDuration : integer;
      FTransitionValueBackgroundColor : TGUITransitionValueRColor;
      FTransitionValueOpacity : TGUITransitionValueSingle;
      FTransitionValueTransform : TGUITransitionValueRMatrix4x3;
      // scene
      FSceneName : string;
      FSceneEye, FSceneTarget : RVector3;
      FSceneSuperSampling : integer;
      property Opacity : single read GetOpacity;
      property Transform : RMatrix4x3 read GetTransform;
      property BackgroundColorOverride : RColor read GetBackgroundColorOverride;

      function IsClipped(const ViewRect : RRectFloat) : boolean;
      procedure Idle; virtual;
      procedure IdleRecursive; virtual;
      property ContentRect : RRectFloat read GetContentRect write SetContentRect;
      function BackgroundRect : RRectFloat;
      property OuterRect : RRectFloat read GetOuterRect write SetOuterRect;
      procedure MoveTo(NewParent : TGUIComponent);
      function ResolvePosition(const SpaceData : RGSSSpaceData; Dim : integer) : single;
      procedure ComputeSize(Dim : integer); virtual;
      /// <summary> Apply min and max size. </summary>
      procedure ClipSize(Dim : integer); virtual;
      function TryResolveSize(const SpaceData : RGSSSpaceData; const Dim : integer; out NewSize : single) : boolean;
      procedure ApplyStyle(const ViewRect : RRectFloat); virtual;
      procedure ApplyStyleRecursive(const ViewRect : RRectFloat); virtual;
      procedure ComputePadding(); virtual;
      procedure ComputeMargin(); virtual;
      procedure ComputeTransform;
      procedure ComputePosition;
      procedure ComputeBackgroundTextures;
      procedure ComputeBackgroundAnimation;
      procedure ComputeAnimation;
      procedure ComputeTransition;
      procedure ComputeBorderAndOutline;
      procedure ComputeSizing;
      procedure ComputeVisibility;
      procedure ComputeText;
      procedure ComputeBorderImage;
      procedure ComputeBackgroundQuad;
      procedure ComputeScrollbars;
      procedure ComputeScene;
      procedure UpdateFont;
      procedure LoadTexture(Stylename : EnumGSSTag; Texture : Pointer);

      procedure ComputeAnimationKey;
      procedure CheckAndBuildAnimationStack;
      function IsAnimationFinished : boolean;
      property Show : EnumNullableBoolean read FShow write SetShow;
      procedure ResetCurrentAnimationKey;

      function DefaultElementName : string; virtual;
      [XMLIncludeElement]
      property ClassesAsText : string read FClassesAsText write SetClassesAsText;
      function UsesOnlyInlineStyles : boolean; inline;
      procedure BuildClassHierarchy;
      procedure BuildStyleSheetStack;
      procedure CheckAndBuildStyleSheetStack;
      function PseudoClasses : SetPseudoClass; virtual;
      function GetStyleValue<T>(Stylename : EnumGSSTag; Index : integer = 0) : T;
      function TryGetStyleValue<T>(Stylename : EnumGSSTag; out Value : T; Index : integer = 0) : boolean; overload;
      function StyleValueCount(Stylename : EnumGSSTag) : integer;
      procedure SetStyleSheetStackDirty;
      procedure SetStyleSheetStackDirtyRecursive;

      function IsBound : boolean;
      procedure LoadAndBindXML(const Node : TdXMLNode);
      procedure ReloadFromXML(const Node : TdXMLNode);
      procedure OnAttributeChangeRaw(Sender : TObject; const Key : string; Action : TCollectionNotification); virtual;
      procedure OnAttributeChange(const Key, Value : string); virtual;
      procedure OnTextChange(const Node : TdXMLNode); virtual;
      class function CreateChildByType(const Node : TdXMLNode; GUI : TGUI) : TGUIComponent;
      procedure OnXMLChange(Sender : TUltimateList<TdXMLNode>; Items : TArray<TdXMLNode>; Action : EnumListAction; Indices : TArray<integer>);
      procedure UnBindXML;
      procedure ResolveAttributes(const Node : TdXMLNode);

      procedure Render; virtual;
      procedure RenderRecursive(const ViewRect : RRectFloat);
      procedure RenderLayerBlur(RenderContext : TRenderContext);
      function RenderRequirements : SetRenderRequirements;
      procedure Rename(newName : string);
      procedure SetDirty; overload;
      procedure SetCompleteDirty; overload;
      procedure SetDirty(const Tags : SetGSSTag); overload; virtual;
      procedure SetDirtyAncestors(const Tags : SetGSSTag);
      function BuildDirtyFlagInheritance(const Tags : SetGSSTag) : SetGSSTag;
      procedure BuildFindMultiSet(ComponentSet : TGUIComponentSet; Query : string);
      procedure SetFocusState(const State : boolean); virtual;
      function GetCurrentText : string; virtual;
      procedure SetCurrentText(const Value : string); virtual;
      procedure SetCurrentTextSafe(const Value : string); // not virtual, for nil-safety
      function GetVisible : boolean;
      procedure SetVisible(const Value : boolean); virtual;
      procedure SetVisibleSafe(const Value : boolean); // not virtual, for nil-safety
      function GetEnabled : boolean;
      procedure SetEnabled(const Value : boolean);
      procedure SetEnabledStyle(const Value : boolean);
      function GetDown : boolean;
      procedure SetDown(const Value : boolean);
      /// <summary> Sets the downstate without overriding user set downstate. </summary>
      procedure SetDownSoft(const Value : boolean); virtual;
      function SiblingIndex : integer;
      function Depth : integer;
      function ZOffset : integer;
      /// <summary> The virtual parent for positioning and sizing computations. </summary>
      function VirtualParent : TGUIComponent;
      function ParentRect : RRectFloat;
      procedure PrepareHint;
      function PointInComponent(const Point : RVector2) : boolean;
      /// <summary> Returns the deepest component containing the given point. If no component contains it, it returns nil. </summary>
      function FindContainingComponent(const Point : RVector2) : TGUIComponent; virtual;
      procedure ChildrenChanged; virtual;

      function HasScrollbars : boolean;
      function ScrollbarsVisible : boolean;
      property ScrollRect : RRectFloat read FScrollRect write SetScrollRect;
      property ScrollOffset : RVector2 read FScrollOffset write SetScrollOffset;
      procedure Scroll(Distance : RVector2);
      function ScrollbarBackgroundRect : RRectFloat;
      function ScrollbarTrackerRect : RRectFloat;
      function PointInScrollbar(Point : RVector2) : boolean;
      function PointInScrollbarTracker(Point : RVector2) : boolean;

      /// <summary> Called to hovered elements. Position is in screen space. </summary>
      procedure MouseMove(const Position : RVector2); virtual;
      procedure MouseDown(const Position : RVector2; Button : EnumMouseButton); virtual;
      procedure MouseUp(const Position : RVector2; Button : EnumMouseButton); virtual;
      /// <summary> Handles mouse wheel events. Returns whether event should bubble up or not. </summary>
      function MouseWheel(const Position : RVector2; Ticks : integer) : boolean; virtual;
      procedure MouseEnter;
      procedure MouseLeave;
      procedure ClearMouseState; virtual;
      function KeyboardEvent(Event : EnumKeyEvent; Key : EnumKeyboardKey) : boolean; virtual;
      function KeyboardEventRecursive(Event : EnumKeyEvent; Key : EnumKeyboardKey) : boolean;
      constructor Create(); overload;
      constructor Create(Owner : TGUI); overload; virtual;
      constructor CustomXMLCreate(Node : TXMLNode; CustomData : array of TObject); override;
      procedure InitDefaultStyle; virtual;
      function ExtractGSS() : string;
      function ExtractdXML() : string;
    public
      /// <summary> A field for custom data, either an int or an object. </summary>
      CustomData : NativeUInt;
      /// <summary> If this is true, CustomData is assumed to be an object an freed at destruction. </summary>
      OwnsCustomData : boolean;
      [XMLIncludeElement]
      /// <summary> The optional name of this component. Can be addressed with it. </summary>
      property name : string read FName write Rename;
      /// <summary> The element type of this component. </summary>
      property ElementName : string read FElementName write FElementName;
      /// <summary> A unique number to identify this component. </summary>
      property UID : integer read FUID;
      /// <summary> The parent-node of this node. Can be nil. </summary>
      property Parent : TGUIComponent read FParent write SetParent;
      /// <summary> Returns whether the mouse is currently over this element. </summary>
      property Hovered : boolean read FHovered;
      /// <summary> NILSAFE | Determines whether the component is visible. Takes only its own visibility into accountn not its parents, therefore use IsVisible. </summary>
      property Visible : boolean read GetVisible write SetVisibleSafe;
      /// <summary> NILSAFE | Toggles visibility. Returns the new visibility state. </summary>
      function VisibleToggle : boolean;
      /// <summary> Removes any forced visibility state and let the styles determine visibility. </summary>
      procedure ClearVisible;
      /// <summary> NILSAFE | Determines whether the component is visible. Takes inherited visibility into account. </summary>
      function IsVisible : boolean;
      /// <summary> The component processes hover and clickevents if true. </summary>
      property Enabled : boolean read GetEnabled write SetEnabled;
      /// <summary> Removes any forced enabled state and let the styles determine enablebility. </summary>
      procedure ClearEnabled;
      property ShowAsDisabled : boolean read FShowAsDisabled write FShowAsDisabled;
      /// <summary> NILSAFE </summary>
      property Down : boolean read GetDown write SetDown;
      property ScreenPos : RVector2 read GetScreenPos;
      property ScreenSize : RVector2 read GetScreenSize;
      function AnchorPosition(Anchor : EnumComponentAnchor) : RIntVector2;
      /// <summary> NILSAFE | The text shown on top of this component. </summary>
      property Text : string read GetCurrentText write SetCurrentTextSafe;
      /// <summary> NILSAFE | Converts the text to integer and back. </summary>
      property TextAsInteger : integer read GetCurrentTextAsInteger write SetCurrentTextAsInteger;
      /// <summary> NILSAFE | The hinttext shown on hovering this component. </summary>
      property Hint : string read GetCurrentHint write SetCurrentHintSafe;
      /// <summary> NILSAFE | The background image of this component. </summary>
      property BackgroundImage : string write SetBackgroundImageSafe;
      property MouseEvents : EnumMouseEvent read FMouseEvent;
      property ItemTemplate : string index 0 read GetItemTemplate;
      property ItemTemplates[const index : integer] : string read GetItemTemplate;
      /// <summary> Returns the appropiate child. </summary>
      function GetChild(Index : integer) : TGUIComponent;
      property Children[index : integer] : TGUIComponent read GetChild; default;
      function Count : integer;
      function HasChildren : boolean;
      /// <summary> NILSAFE | Returns whether this component has a hint. </summary>
      function HasHint : boolean;
      /// <summary> Returns the index of this child. If the component is no child of this node, returns -1. </summary>
      function IndexOfChild(const Child : TGUIComponent) : integer;
      /// <summary> Returns the index of this child within all visible children. If the component is no child of this node or is not visible, returns -1. </summary>
      function IndexOfVisibleChild(const Child : TGUIComponent) : integer;
      /// <summary> Searches for a child with the given data. The first matching is returned. If nothing found returns -1. </summary>
      function IndexOfChildWithData(Data : NativeUInt) : integer; overload;
      function IndexOfChildWithData(Data : TObject) : integer; overload;
      function TryIndexOfChildWithData(Data : NativeUInt; Index : integer) : boolean;
      /// <summary> Searches for a child with the given data. The first matching is returned. If nothing found returns nil. </summary>
      function GetChildWithData(Data : NativeUInt) : TGUIComponent; overload;
      function GetChildWithData(Data : TObject) : TGUIComponent; overload;
      /// <summary> An empty string will be filled with a generic name. Empty parent will be not attached to anything like a root node. </summary>
      constructor Create(Owner : TGUI; Style : TGUIStyleSheet; const Name : string = ''; Parent : TGUIComponent = nil); overload;
      /// <summary> Loads a Component from a file. Returns nil if file was not found.</summary>
      class function CreateFromFile(const Filename : string; Owner : TGUI; Parent : TGUIComponent = nil; FailSilently : boolean = True) : TGUIComponent;
      /// <summary> Adds a child element. </summary>
      procedure AddChild(Child : TGUIComponent); virtual;
      /// <summary> Creates a child with the set template in styles (optional index for multiple templates) and append it to this element. </summary>
      function AddChildByItemTemplate(const Index : integer = 0) : TGUIComponent;
      procedure PrependChild(Child : TGUIComponent);
      /// <summary> Inserts a child element at index. All chidren at index at later are moved backwards. If index it out range, it will be appended. </summary>
      procedure InsertChild(Index : integer; Child : TGUIComponent);
      /// <summary> Remove a child from the list. It won't be freed. </summary>
      procedure RemoveChild(Child : TGUIComponent);
      /// <summary> Delete a child from this node. It will be freed. If index is invalid, nothing happens. </summary>
      procedure DeleteChild(Index : integer);
      /// <summary> Deletes the old child at index an inserts the new child. </summary>
      procedure ReplaceChild(Index : integer; NewChild : TGUIComponent);
      /// <summary> NILSAFE | Remove all children from the list. They will be freed. </summary>
      procedure ClearChildren;
      /// <summary> NILSAFE | Calls ClearChildren on all children, removing all grandchildren. They will be freed. </summary>
      procedure ClearGrandChildren;
      /// <summary> NILSAFE | Adds a class from this component. If class is already present nothing happens. Returns whether class has been added. </summary>
      function AddClass(const GSSClass : string) : boolean;
      /// <summary> NILSAFE | Removes a class from this component. If class is not present nothing happens. Returns whether class has been removed. </summary>
      function RemoveClass(const GSSClass : string) : boolean;
      /// <summary> NILSAFE | Adds a class if Value, else removes a class from this component. Returns itself for chaining. </summary>
      function BindClass(Value : boolean; const GSSClass : string) : TGUIComponent;
      /// <summary> NILSAFE | Returns wheteher this component has the class. </summary>
      function HasClass(const ClassName : string) : boolean;
      /// <summary> How many chilren have this node? </summary>
      function ChildCount : integer;
      function GetStyle<T>(Key : EnumGSSTag; Index : integer) : T; overload;
      function GetStyle<T>(Key : EnumGSSTag) : T; overload;
      /// <summary> NILSAFE | Change the value to the key in the stylesheet. </summary>
      procedure ChangeStyle<T>(Key : EnumGSSTag; Index : integer; const Value : T); overload;
      procedure ChangeStyle<T>(Key : EnumGSSTag; const Value : T); overload;
      procedure ChangeStyle<T>(Key : EnumGSSTag; Values : array of T); overload;
      /// <summary> Changes the value to the key in the stylesheet of all descendants and the node itself. </summary>
      procedure ChangeStyleWithDescendants<T>(Key : EnumGSSTag; const Value : T); overload;
      /// <summary> Changes the value to the key in the stylesheet of all descendants where the filter returns true and the node itself. </summary>
      procedure ChangeStyleFilterDescendants<T>(Key : EnumGSSTag; const Value : T; const Filter : ProcDescendantFilter); overload;
      procedure ChangeStyleFilterDescendants<T>(Key : EnumGSSTag; const ValueIfTrue, ValueIfFalse : T; const Filter : ProcDescendantFilter); overload;
      /// <summary> Unchild this from its parent and kill it with all children. </summary>
      procedure Delete;
      procedure SaveToFile(const Filename : string);
      /// <summary> Returns whether this component has a parent component or not. </summary>
      function HasParent : boolean;
      /// <summary> NILSAFE | Returns whether this component has an ancestor with the given name or not. </summary>
      function HasAncestor(const AncestorName : string) : boolean;
      /// <summary> Applies a procedure to all nodes in the subtree starting with this element as root.
      /// Uses the order (self, left - rightchildren). </summary>
      procedure Traverse(const method : ProcTraverse); virtual;
      /// <summary> NILSAFE | Get an descendant element by name. Searching in the subtree of this node with preorder-traversion.
      /// If element not found, return nil.</summary>
      function Find(const Name : string) : TGUIComponent; overload;
      /// <summary> NILSAFE | Try version of Find. </summary>
      function Find(const Name : string; out Element : TGUIComponent) : boolean; overload;
      function FindMulti(const Name : string) : IGUIComponentSet;
      function FindAs<T : class>(const Name : string) : T; overload;
      function FindAs<T : class>(const Name : string; out Element : T) : boolean; overload;
      /// <summary> NILSAFE | Get an element by name and casting it to T. Searching in the subtree of this node with preorder-traversion.
      /// If element not found, return nil.</summary>
      function GetDescendantElementByName<T : class>(const Name : string) : T; overload;
      /// <summary> Try-version of above.</summary>
      function TryGetDescendantElementByName<T : class>(const Name : string; out Element : T) : boolean; overload;
      /// <summary> NILSAFE | Get an element by name. Searching in the subtree of this node with preorder-traversion.
      /// If element not found, return nil.</summary>
      function GetDescendantComponentByName(const Name : string) : TGUIComponent; virtual;
      /// <summary> Try-version of above.</summary>
      function TryGetDescendantComponentByName(const Name : string; out Element : TGUIComponent) : boolean;
      /// <summary> Get an parent element by name. Searching in all parents of this node.
      /// If element not found, return nil.</summary>
      function TryGetParentComponentByName(const Name : string; out Element : TGUIComponent) : boolean;
      /// <summary> Shows the hint of this component immediately. </summary>
      procedure ShowHint;
      /// <summary> NILSAFE | Executes a click on this component. </summary>
      procedure Click(Button : EnumMouseButton = mbLeft); overload;
      procedure Click(Button : EnumMouseButton; const Position : RVector2); overload; virtual;
      /// <summary> Set this element as the current focused element. </summary>
      procedure SetFocus;
      /// <summary> Starts the set animation of this element. </summary>
      property AnimationFinished : boolean read FAnimationFinished;
      procedure StartAnimation;
      procedure StartAnimationRecursive;

      procedure SubscribeToEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent);
      procedure UnsubscribeFromEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent);
      /// <summary> Casts the custom data as the specified class. Does type checks.</summary>
      function CustomDataAs<T : class>() : T;
      /// <summary> Casts the custom data as an TObjectWrapper<T> and returns its value. Does type checks.</summary>
      function CustomDataAsWrapper<T>() : T;
      /// <summary> Casts the custom data as the specified class. Does not do any type checks! </summary>
      function CustomDataForceAs<T : class>() : T;
      /// <summary> NILSAFE | Set the data encapsulated in a TObjectWrapper<T> into customdata. Sets OwnsCustomData to true. </summary>
      procedure SetCustomDataAsWrapper<T>(const Value : T);
      /// <summary> Skadoosh </summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  ProcGUIError = reference to procedure(errormsg : string);

  /// <summary> The main GUI-class. Take an instance for your application. </summary>
  TGUI = class(TRenderable)
    private
      FUIDCounter : integer;
      FRoot, FDynamicRoot : TGUIComponent;
      FComponents : TObjectDictionary<integer, TGUIComponent>;
      FComponentsByName : TDictionary<string, TGUIComponent>;
      FAssetPath : string;
      FHoveredElements : TAdvancedList<integer>;
      FFocusedElementUID : integer;
      FRenderRequirements : SetRenderRequirements;
      FVirtualSizeModifier : RVector2;
      FVirtualSize, FViewSize : RIntVector2;
      // Hint
      FHintTargetComponent : integer;
      FHintComponents : TObjectDictionary<string, TGUIComponent>;
      FHintComponent : string;
      FHintVisible, FEnableBlurBackgrounds : boolean;
      FHintDelay, FHintDisplay : TTimer;
      // Events
      FEventQueue : TQueue<RGUIEvent>;
      FEventSubscriptions : TObjectDictionary<EnumGUIEvent, TObjectDictionary<integer, TList<ProcGUIEvent>>>;
      // dXML - underlying DOM
      FContext : TObjectDictionary<string, TDictionary<string, TValue>>;
      // layer blur
      FBlurTexture : TFullscreenRendertarget;
      FBlurrer : TTextureBlur;
      procedure SetEnableBlurBackgrounds(const Value : boolean);
      procedure AddEvent(const GUIEvent : RGUIEvent);
      function GetSubscriptions(Event : EnumGUIEvent; OnlyForComponent : TGUIComponent; CanFail : boolean) : TList<ProcGUIEvent>; overload;
      function GetSubscriptions(Event : EnumGUIEvent; OnlyForComponent : integer; CanFail : boolean) : TList<ProcGUIEvent>; overload;
      function TopHoveredElementWithHint : integer;
      function GetCurrentHintComponent : TGUIComponent;
      procedure HideAllHints;
      procedure ShowHint; overload;
      procedure ResolveAutoAnchor(var Anchor : EnumComponentAnchor; const Position : RVector2);
      /// <summary> Pos = Parentrect of hint used for positioning within screen. </summary>
      procedure PrepareHint(Pos : RRect; const Text : string; const HintTemplate : string = ''; const HintClasses : string = ''; DisplayTime : int64 = -1; HintAnchor : EnumComponentAnchor = caAuto; SourceComponent : integer = -1);
      // default hint
      procedure setHintComponent(const Value : TGUIComponent); overload;
      // file hint
      procedure setHintComponent(const Value : string); overload;
      procedure InitDynamicDOMRoot;
      procedure UpdateResolution;
      procedure UpdateVirtualSizeModifier;
      procedure UpdateRootSize;
      procedure UpdateDynamicRootSize;
      procedure PutError(const msg : string);
      procedure AddComponent(Component : TGUIComponent);
      procedure RemoveComponent(Component : TGUIComponent);
      procedure RenameComponent(const newName : string; Component : TGUIComponent);

      procedure OnMouse(const Sender : RGUIEvent);

      procedure RefreshContext(const Component : TGUIComponent);
      procedure ReloadContexts();

      procedure SetFocus(const ElementUID : integer);
      procedure ClearFocus;
      procedure SetVirtualSize(const Value : RIntVector2);
      procedure SetViewSize(const Value : RIntVector2);
      function GetViewSize : RIntVector2;
    protected
      FLastMousePosition : RVector2;
      FDocument : TdXMLDocument;
      function ScreenRect : RRectFloat;
      function ViewRect : RRectFloat;
      function Requirements : SetRenderRequirements; override;
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
    public
      // overridable constants, set at the initialization of this file
    class var
      /// <summary> Time after the hint will be displayed if element is hovered. </summary>
      HintDelay : int64;
      /// <summary> Time the hint will be shown. </summary>
      HintDisplayTime : int64;
    var
      /// <summary> Whis method will be called, when errors while parsing or applying a style occurs. </summary>
      Erroroutput : ProcGUIError;
      /// <summary> The director of alle stylefiles. </summary>
      StyleManager : TGUIStyleManager;
      property VirtualSize : RIntVector2 read FVirtualSize write SetVirtualSize;
      property VirtualSizeModifier : RVector2 read FVirtualSizeModifier;
      property ViewSize : RIntVector2 read GetViewSize write SetViewSize;
      property EnableBlurBackgrounds : boolean read FEnableBlurBackgrounds write SetEnableBlurBackgrounds;
      /// <summary> The path, relative to the application, where the images can be found. </summary>
      property AssetPath : string read FAssetPath write FAssetPath;
      /// <summary> The root of the static DOM. Add saveable and loadable components here </summary>
      property DOMRoot : TGUIComponent read FRoot;
      /// <summary> The default component will be displayed for hints. A subcomponent with name 'Hint' expected.
      /// Freed by GUI. For correct display all hinted components have to be completely within the
      /// boundaries of their parents.</summary>
      property HintComponent : TGUIComponent write setHintComponent;
      /// <summary> The root of the dynamic DOM. Add runtime components here. These components
      /// receives no clicks etc. Only for displaying things like healthbars. </summary>
      property DynamicDOMRoot : TGUIComponent read FDynamicRoot;

      /// <summary> Get an component by its unique name. Faster than Find. If element not found return nil.
      /// If there are more than 1 component with this name an assertion is raised. </summary>
      function FindUnique(const Name : string) : TGUIComponent; overload;
      function FindUnique(const Name : string; out Element : TGUIComponent) : boolean; overload;
      function FindUniqueAs<T : TGUIComponent>(const Name : string) : T; overload;
      function FindUniqueAs<T : TGUIComponent>(const Name : string; out Element : T) : boolean; overload;
      /// <summary> Tries to resolve a uid to a component. Returns nil if uid is not longer valid. </summary>
      function ResolveUID(UID : integer) : TGUIComponent;
      /// <summary> Get an component by uid. If element not found return false, else true.</summary>v
      function TryResolveUID(UID : integer; out Component : TGUIComponent) : boolean;

      /// <summary> Tells the gui that the cursor has been moved to Position. Must be called before Down an Up events. </summary>
      procedure MouseMove(const Position : RIntVector2);
      /// <summary> Tells the gui that a mouse button has been pressed. </summary>
      procedure MouseDown(Button : EnumMouseButton);
      /// <summary> Tells the gui that a mouse button has been released. </summary>
      procedure MouseUp(Button : EnumMouseButton);
      /// <summary> Tells the gui that the mouse wheel has been used. </summary>
      procedure MouseWheel(Ticks : integer);
      /// <summary> Should be called for Mouse handling. </summary>
      procedure HandleMouse(Mouse : TMouse);
      /// <summary> Returns whether a gui element is hovered by the cursor. </summary>
      function IsMouseOverGUI : boolean;
      /// <summary> Returns whether a gui element which is clickable, is hovered by the cursor. </summary>
      function IsMouseOverClickable : boolean;
      function GetClickableUnderMouse : TGUIComponent;
      /// <summary> Returns whether a gui element which could be written into is hovered by the cursor. </summary>
      function IsMouseOverWritable : boolean;
      function GetWritableUnderMouse : TGUIComponent;
      /// <summary> Returns whether a gui element which has a hint, is hovered by the cursor. </summary>
      function IsMouseOverHint : boolean;
      /// <summary> Should be called for Keyboard handling. Return determines whether the gui used the input. </summary>
      function KeyboardUp(Key : EnumKeyboardKey) : boolean;
      function KeyboardDown(Key : EnumKeyboardKey) : boolean;

      procedure SubscribeToEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent; OnlyForComponent : TGUIComponent = nil);
      procedure UnsubscribeFromEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent; OnlyForComponent : TGUIComponent = nil);

      /// <summary> Passes the context variables to the underlying dXML-Structure. If ComponentUID is set this context
      /// will be set to the specified component even if it will be added in future and isn't present yet, otherwise the context
      /// is set globally. </summary>
      procedure SetContext(const Key : string; const Value : TValue; const ComponentUID : string = 'root');

      /// <summary> Creates a GUI. </summary>
      constructor Create(Scene : TRenderManager);
      /// <summary> Should be called once every frame for intern computations and rendering. </summary>
      procedure Idle;
      procedure ProcessEvents;
      /// <summary> Load the DOM from a dui (dXML-GUI) file. Graphicspath will be set to the path of the filename. </summary>
      procedure LoadFromFile(Filename : string);
      /// <summary> Load the DOM from a static gui file. Graphicspath will be set to the path of the filename. </summary>
      procedure LoadStaticFromFile(Filename : string); deprecated;
      /// <summary> Saves the DOM to a static gui file. </summary>
      procedure SaveStaticToFile(const Filename : string); deprecated;
      /// <summary> Clears the DOMRoot. </summary>
      procedure Clear;
      /// <summary> Displays a hint for DisplayTime milliseconds. If DisplayTime < 0, TGUI.HintDisplayTime will be used. </summary>
      procedure ShowHint(const Pos : RIntVector2; const Text : string; DisplayTime : int64 = -1); overload;
      /// <summary> Hides the hint immediately. </summary>
      procedure HideHint();
      /// <summary> After changing the language this should be called. </summary>
      procedure ReloadLanguage;

      /// <summary> Skadoosh </summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$RTTI INHERIT}

  TGUIStackPanel = class(TGUIComponent)
    private
      FStackOrientation : EnumStackOrientation;
      FStackColumns : RIntVector2;
      FStackAnchor : EnumComponentAnchor;
      FAutomode : boolean;
      FPaddingXAuto, FPaddingYAuto : boolean;
    protected
      procedure ChildrenChanged; override;
      procedure OnAttributeChange(const Key, Value : string); override;
      procedure SetDirty(const Tags : SetGSSTag); override;
      procedure ApplyStyle(const ViewRect : RRectFloat); override;
      procedure ComputeSize(Dim : integer); override;
      procedure ComputeStackProperties;
      function DefaultElementName : string; override;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$RTTI INHERIT}

  TGUIProgressBar = class(TGUIComponent)
    protected
      FProgressPosition, FProgressmaximum : single;
      FProgressShape : EnumProgressShape;
      // Self = Background, FFillBar = bar
      procedure ApplyStyle(const ViewRect : RRectFloat); override;
      procedure InitDefaultStyle; override;
      procedure SetPosition(Value : single);
      procedure SetMax(Value : single);
      procedure InitFillbar(Owner : TGUI);
      function GetPosition : single;
      function GetMax : single;
      procedure MouseMove(const Position : RVector2); override;
      procedure OnAttributeChange(const Key, Value : string); override;
    public
      [XMLIncludeElement]
      FillBar : TGUIComponent;
      property Position : single read GetPosition write SetPosition;
      property Max : single read GetMax write SetMax;
      constructor Create(Owner : TGUI; Style : TGUIStyleSheet = nil; const Name : string = ''; Parent : TGUIComponent = nil); overload;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$RTTI INHERIT}

  TGUIEdit = class(TGUIComponent)
    private
      function getSelectionCount : integer;
      procedure SetMaxLength(const Value : integer);
      function GetMaxLength : integer;
    protected
      FTextCursor, FTextCursorEnd : TVertexScreenAlignedQuad;
      FSelStart, FSelEnd, FMaxLength : integer;
      FRepeatedKey : EnumKeyboardKey;
      FShift, FStrg, FAltGr, FBlink, FRepeat, FAcceptNewlines : boolean;
      FKeyRepeat, FKeyRepeatDelay, FBlinkTimer : TTimer;
      FObscureChar : string;
      property SelectionCount : integer read getSelectionCount;
      procedure SetBlink(State : boolean);
      procedure ResetBlink;
      procedure SetFocusState(const State : boolean); override;
      procedure Idle; override;
      procedure WriteKey(Key : EnumKeyboardKey);
      function GetSelectedString : string;
      procedure WriteStringAtCursor(str : string);
      procedure SetSelection(SelStart : integer; SelEnd : integer = -1);
      procedure DeleteSelection(Direction : integer);
      procedure ExpandSelection(Direction : integer);
      procedure FocusNextEdit;
      function KeyToChar(Key : EnumKeyboardKey) : string;
      function GetCurrentText : string; override;
      procedure SetCurrentText(const Value : string); override;
      function KeyboardEvent(Event : EnumKeyEvent; Key : EnumKeyboardKey) : boolean; override;
      procedure MouseUp(const Position : RVector2; Button : EnumMouseButton); override;
      procedure ApplyStyle(const ViewRect : RRectFloat); override;
      procedure Render; override;
      function DefaultElementName : string; override;
      procedure Init;
      constructor CustomXMLCreate(Node : TXMLNode; CustomData : array of TObject); override;
      procedure OnAttributeChange(const Key, Value : string); override;
      procedure OnTextChange(const Node : TdXMLNode); override;
      constructor Create(Owner : TGUI); override;
    public
      property Maxlength : integer read GetMaxLength write SetMaxLength;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  TGUICheckbox = class(TGUIComponent)
    private
      function GetChecked : boolean;
      procedure SetChecked(const Value : boolean);
    protected
      FChecked : boolean;
      procedure SetDownSoft(const Value : boolean); override;
      function PseudoClasses : SetPseudoClass; override;
      procedure OnAttributeChange(const Key, Value : string); override;
      function DefaultElementName : string; override;
    public
      /// <summary> NILSAFE </summary>
      property Checked : boolean read GetChecked write SetChecked;
      procedure Click(Button : EnumMouseButton; const Position : RVector2); override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  /// <summary> Gives a direction vector in which the anchor directs. </summary>
function AnchorToVector(ComponentAnchor : EnumComponentAnchor) : RIntVector2;
function InverseAnchor(ComponentAnchor : EnumComponentAnchor) : EnumComponentAnchor;

var
  /// <summary> The default font family used if nothing is declared. Arial is default. </summary>
  DefaultFontFamily : string = 'Arial';
  GUI : TGUI;

implementation

function InverseAnchor(ComponentAnchor : EnumComponentAnchor) : EnumComponentAnchor;
begin
  case ComponentAnchor of
    caTopLeft : Result := caBottomRight;
    caTop : Result := caBottom;
    caTopRight : Result := caBottomLeft;
    caLeft : Result := caRight;
    caCenter : Result := caCenter;
    caRight : Result := caLeft;
    caBottomLeft : Result := caTopRight;
    caBottom : Result := caTop;
    caBottomRight : Result := caTopLeft;
  else
    Result := ComponentAnchor;
  end;
end;

function AnchorToVector(ComponentAnchor : EnumComponentAnchor) : RIntVector2;
begin
  Result.X := (ord(ComponentAnchor) mod 3) - 1;
  Result.Y := (ord(ComponentAnchor) div 3) - 1;
end;

function ParseStyleSpaceData(const str : string) : TStringlist;
var
  i : integer;
begin
  Result := TStringlist.Create;
  Result.Add('');
  for i := 1 to length(str) do
  begin
    if str[i] <> ' ' then Result.Strings[Result.Count - 1] := Result.Strings[Result.Count - 1] + str[i];
    if (str[i] = ' ') or (str[i] = '%') or (str[i] = 'x') or (Result.Strings[Result.Count - 1] = 'auto') or (Result.Strings[Result.Count - 1] = 'inherit') then Result.Add('');
  end;
  for i := Result.Count - 1 downto 0 do
    if Result[i] = '' then Result.Delete(i);
end;

{ TGUI }

procedure TGUI.AddComponent(Component : TGUIComponent);
begin
  assert(Component.FUID < 0, 'TGUI.AddComponent: Component has been added twice to gui!');
  inc(FUIDCounter);
  Component.FUID := FUIDCounter;
  FComponents.Add(FUIDCounter, Component);
  // if key is already present, set to nil, as there are multiple values to this key
  if FComponentsByName.ContainsKey(Component.Name.ToLowerInvariant) then FComponentsByName.AddOrSetValue(Component.Name.ToLowerInvariant, nil)
  else
  begin
    FComponentsByName.AddOrSetValue(Component.Name.ToLowerInvariant, Component);
    // unique components are checked for gaining context variables
    RefreshContext(Component);
  end;
end;

procedure TGUI.RemoveComponent(Component : TGUIComponent);
var
  temp : TGUIComponent;
begin
  if FHintTargetComponent = Component.UID then HideHint;
  FHoveredElements.Remove(Component.UID);
  FComponents.Remove(Component.UID);
  // if key is a component, it is a unique name, which can be removed. If it is nil it is a multi key and remains blocked.
  if FComponentsByName.TryGetValue(Component.Name.ToLowerInvariant, temp) and assigned(temp) then FComponentsByName.Remove(Component.Name.ToLowerInvariant);
  Component.FUID := -1;
end;

procedure TGUI.AddEvent(const GUIEvent : RGUIEvent);
begin
  FEventQueue.Enqueue(GUIEvent);
end;

procedure TGUI.Clear;
begin
  FRoot.Free;
  FRoot := TGUIComponent.Create(self, nil, 'root');
  UpdateRootSize;
  FRoot.ChangeStyle<EnumMouseEvent>(gtMouseEvents, mePass);
  FRoot.ElementName := 'root';
  FreeAndNil(FDocument);
end;

procedure TGUI.SetFocus(const ElementUID : integer);
var
  Component : TGUIComponent;
begin
  if ElementUID = FFocusedElementUID then exit;
  ClearFocus;
  if TryResolveUID(ElementUID, Component) then
  begin
    Component.SetFocusState(True);
    FFocusedElementUID := ElementUID;
  end;
end;

procedure TGUI.ClearFocus;
var
  Component : TGUIComponent;
begin
  if TryResolveUID(FFocusedElementUID, Component) then Component.SetFocusState(False);
  FFocusedElementUID := -1;
end;

constructor TGUI.Create(Scene : TRenderManager);
begin
  inherited Create(Scene, []);
  FVirtualSizeModifier := RVector2.ONE;
  FEnableBlurBackgrounds := True;
  Scene.Eventbus.Subscribe(geResolutionChanged, UpdateResolution);
  StyleManager := TGUIStyleManager.Create(self);
  FComponents := TObjectDictionary<integer, TGUIComponent>.Create([]);
  FComponentsByName := TDictionary<string, TGUIComponent>.Create();
  FContext := TObjectDictionary < string, TDictionary < string, TValue >>.Create([doOwnsValues]);
  Clear;
  InitDynamicDOMRoot;
  FHintDelay := TTimer.CreatePaused(TGUI.HintDelay);
  FHintDisplay := TTimer.CreateAndStart(TGUI.HintDisplayTime);
  FHintComponent := '';
  FHintComponents := TObjectDictionary<string, TGUIComponent>.Create([doOwnsValues]);
  setHintComponent(TGUIComponent.Create(self, TGUIStyleSheet.CreateFromText('PassThroughEvents : true;position:0 0;size:200 200; fontflags : [ffWordWrap];')));
  FHoveredElements := TAdvancedList<integer>.Create;
  FEventQueue := TQueue<RGUIEvent>.Create;
  FEventSubscriptions := TObjectDictionary < EnumGUIEvent, TObjectDictionary < integer, TList<ProcGUIEvent> >>.Create([doOwnsValues]);
  SubscribeToEvent(geMouseEnter, OnMouse);
  SubscribeToEvent(geMouseLeave, OnMouse);
  SubscribeToEvent(geClick, OnMouse);
  // init layer blur
  FBlurrer := TTextureBlur.Create();
  FBlurTexture := Scene.CreateFullscreenRendertarget();
end;

destructor TGUI.Destroy;
var
  i : integer;
  remainingComponents : TArray<TGUIComponent>;
begin
  UnsubscribeFromEvent(geMouseEnter, OnMouse);
  UnsubscribeFromEvent(geMouseLeave, OnMouse);
  UnsubscribeFromEvent(geClick, OnMouse);
  HideHint;
  FHintComponents.Clear;
  FEventQueue.Free;
  FEventSubscriptions.Free;
  FRoot.Free;
  FDynamicRoot.Free;
  remainingComponents := FComponents.Values.ToArray;
  for i := 0 to length(remainingComponents) - 1 do
      remainingComponents[i].Free;
  FComponents.Free;
  FComponentsByName.Free;
  FHoveredElements.Free;
  FHintComponents.Free;
  FHintDelay.Free;
  FHintDisplay.Free;
  StyleManager.Free;
  FDocument.Free;
  FContext.Free;
  FBlurTexture.Free;
  FBlurrer.Free;
  inherited;
end;

function TGUI.FindUnique(const Name : string) : TGUIComponent;
begin
  if not FindUnique(name, Result) then Result := nil;
end;

function TGUI.FindUnique(const Name : string; out Element : TGUIComponent) : boolean;
var
  temp : TGUIComponent;
begin
  Result := FComponentsByName.TryGetValue(name.ToLowerInvariant, temp);
  if Result then
      Element := temp;
end;

function TGUI.FindUniqueAs<T>(const Name : string) : T;
begin
  if not FindUniqueAs<T>(name, Result) then Result := nil;
end;

function TGUI.FindUniqueAs<T>(const Name : string; out Element : T) : boolean;
var
  temp : TGUIComponent;
begin
  Result := FindUnique(name, temp);
  if Result then Element := temp as T;
end;

procedure TGUI.LoadFromFile(Filename : string);
begin
  Filename := AbsolutePath(Filename);
  if FAssetPath = '' then FAssetPath := HFilepathManager.AbsoluteToRelative(ExtractFilePath(Filename));
  Clear;

  TdXMLDocument.BasePath := AssetPath;
  FDocument := TdXMLDocument.Create(Filename);
  if FDocument.RootNode.Name <> 'root' then
      raise EInvalidOperation.Create('TGUI.LoadFromFile: Can''t load gui-file (' + Filename + ') as it isn''t a root file!');
  FRoot.Free;
  FRoot := TGUIComponent.CreateChildByType(FDocument.RootNode, self);
  UpdateRootSize;

  ReloadContexts;
  ReloadContexts; // twice to avoid order issues, but slower

  FRoot.ApplyStyleRecursive(ScreenRect);
end;

procedure TGUI.LoadStaticFromFile(Filename : string);
var
  XMLSerializer : TXMLSerializer;
begin
  FreeAndNil(FDocument);
  XMLSerializer := TXMLSerializer.Create;
  FRoot.Free;
  if FAssetPath = '' then FAssetPath := RelativDateiPfad(ExtractFilePath(Filename));
  FRoot := XMLSerializer.CreateAndLoadObjectFromFile<TGUIComponent>(Filename, [self]);
  UpdateRootSize;
  FRoot.ChangeStyle<EnumMouseEvent>(gtMouseEvents, mePass);
  FRoot.ElementName := 'root';
  FRoot.ApplyStyleRecursive(ScreenRect);
  XMLSerializer.Free;
end;

procedure TGUI.SaveStaticToFile(const Filename : string);
var
  XMLSerializer : TXMLSerializer;
begin
  XMLSerializer := TXMLSerializer.Create;
  XMLSerializer.SaveObjectToFile(FRoot, Filename);
  XMLSerializer.Free;
end;

function TGUI.ScreenRect : RRectFloat;
begin
  Result := RRectFloat.CreateWidthHeight(RVector2.ZERO, self.Scene.Size);
end;

procedure TGUI.RefreshContext(const Component : TGUIComponent);
var
  ContextData : TDictionary<string, TValue>;
  Key : string;
begin
  if FContext.TryGetValue(Component.Name, ContextData) and Component.IsBound then
  begin
    for Key in ContextData.Keys do
        Component.FXMLNode.Context.AddOrSetValue(Key, ContextData[Key]);
  end;
end;

procedure TGUI.ReloadContexts;
var
  Component : TGUIComponent;
  Context : TExpressionContext;
  ContextData : TDictionary<string, TValue>;
  Key, ComponentUID : string;
begin
  if assigned(FDocument) then
  begin
    for ComponentUID in FContext.Keys do
    begin
      ContextData := FContext[ComponentUID];
      Context := nil;
      if ComponentUID = 'root' then
          Context := FDocument.RootNode.Context
      else
        if FindUnique(ComponentUID, Component) and Component.IsBound then Context := Component.FXMLNode.Context;

      if assigned(Context) then
        for Key in ContextData.Keys do
            Context.AddOrSetValue(Key, ContextData[Key]);
    end;
  end;
end;

procedure TGUI.ReloadLanguage;
begin
  if assigned(FDocument) then
      FDocument.Reload;
end;

procedure TGUI.SetContext(const Key : string; const Value : TValue; const ComponentUID : string);
var
  Data : TDictionary<string, TValue>;
  Component : TGUIComponent;
begin
  if not FContext.TryGetValue(ComponentUID, Data) then
  begin
    Data := TDictionary<string, TValue>.Create;
    FContext.Add(ComponentUID, Data);
  end;
  if Value.IsEmpty then Data.Remove(Key)
  else Data.AddOrSetValue(Key, Value);

  if assigned(FDocument) then
  begin
    if ComponentUID = 'root' then
    begin
      if Value.IsEmpty then FDocument.RootNode.Context.Remove(Key)
      else FDocument.RootNode.Context.AddOrSetValue(Key, Value);
    end
    else if FindUnique(ComponentUID, Component) and Component.IsBound then
    begin
      if Value.IsEmpty then Component.FXMLNode.Context.Remove(Key)
      else Component.FXMLNode.Context.AddOrSetValue(Key, Value);
    end;
  end;
end;

procedure TGUI.SetEnableBlurBackgrounds(const Value : boolean);
var
  Component : TGUIComponent;
begin
  if FEnableBlurBackgrounds <> Value then
  begin
    FEnableBlurBackgrounds := Value;
    for Component in FComponents.Values do
    begin
      Component.SetDirty([gtBlur, gtBlurLayer, gtBlurColor]);
    end;
  end;
end;

procedure TGUI.setHintComponent(const Value : string);
var
  HintFile : TGUIComponent;
begin
  // set file hint component
  FHintComponent := Value;
  // load file
  HintFile := TGUIComponent.CreateFromFile(FormatDateiPfad(FAssetPath + Value), self);
  // overrides current default hint component
  FHintComponents.AddOrSetValue(FHintComponent, HintFile);
  if not assigned(HintFile) then exit;
  DynamicDOMRoot.AddChild(HintFile);
  HintFile.ChangeStyle<integer>(gtZOffset, HINT_DEPTH);
  HintFile.Visible := False;
end;

procedure TGUI.setHintComponent(const Value : TGUIComponent);
begin
  // set default hint component
  FHintComponent := '';
  // overrides current default hint component
  FHintComponents.AddOrSetValue(FHintComponent, Value);
  if not assigned(Value) then exit;
  DynamicDOMRoot.AddChild(Value);
  Value.ChangeStyle<integer>(gtZOffset, HINT_DEPTH);
  Value.Visible := False;
end;

procedure TGUI.ShowHint;
begin
  if (GetCurrentHintComponent = nil) then exit;
  HideAllHints;
  FHintVisible := True;
  GetCurrentHintComponent.Visible := True;
  FHintDisplay.Start;
  if FHoveredElements.Count > 0 then
  begin
    FHintTargetComponent := FHoveredElements.First;
    AddEvent(RGUIEvent.CreateFromUID(geHint, FHoveredElements.First(), self).SetAdditionalData(GetCurrentHintComponent.UID));
  end;
end;

procedure TGUI.PrepareHint(Pos : RRect; const Text, HintTemplate, HintClasses : string; DisplayTime : int64; HintAnchor : EnumComponentAnchor; SourceComponent : integer);
var
  Filename : string;
begin
  FHintTargetComponent := SourceComponent;
  if Text.StartsWith(HINT_FILE_COMMAND, True) then Filename := Text.Replace(HINT_FILE_COMMAND, '', [rfIgnoreCase]);
  if HintTemplate <> '' then Filename := HintTemplate;

  // check text for tooltip file
  if Filename <> '' then
    // set file hint
      setHintComponent(Filename)
  else
    // set default hint
      FHintComponent := '';

  if GetCurrentHintComponent = nil then exit;

  ResolveAutoAnchor(HintAnchor, Pos.Center);

  GetCurrentHintComponent.ChangeStyle<EnumComponentAnchor>(gtAnchor, HintAnchor);
  Pos := Pos.Translate((2 - (ord(HintAnchor) mod 3)) * (Pos.Width div 2), (2 - (ord(HintAnchor) div 3)) * (Pos.Height div 2));
  GetCurrentHintComponent.ChangeStyle<RGSSSpaceData>(gtPosition, RGSSSpaceData.CreateAbsoluteScreen([Pos.Left, Pos.Top]));
  GetCurrentHintComponent.ClassesAsText := 'hint ' + HintClasses;
  GetCurrentHintComponent.GetDescendantElementByName<TGUIComponent>(HINTNAME).Text := Text;
  if DisplayTime <= 0 then FHintDisplay.Interval := TGUI.HintDisplayTime
  else FHintDisplay.Interval := DisplayTime;
end;

procedure TGUI.SetViewSize(const Value : RIntVector2);
begin
  FViewSize := Value;
  UpdateResolution;
end;

procedure TGUI.SetVirtualSize(const Value : RIntVector2);
begin
  if FVirtualSize <> Value then
  begin
    FVirtualSize := Value;
    FRoot.SetCompleteDirty;
    FDynamicRoot.SetCompleteDirty;
    UpdateVirtualSizeModifier;
  end;
end;

procedure TGUI.ShowHint(const Pos : RIntVector2; const Text : string; DisplayTime : int64);
begin
  PrepareHint(RRect.Create(Pos, Pos), Text, '', '', DisplayTime);
  ShowHint;
end;

function TGUI.GetSubscriptions(Event : EnumGUIEvent; OnlyForComponent : TGUIComponent; CanFail : boolean) : TList<ProcGUIEvent>;
var
  TargetUID : integer;
begin
  if assigned(OnlyForComponent) then TargetUID := OnlyForComponent.UID
  else TargetUID := -1;
  Result := GetSubscriptions(Event, TargetUID, CanFail);
end;

function TGUI.GetSubscriptions(Event : EnumGUIEvent; OnlyForComponent : integer; CanFail : boolean) : TList<ProcGUIEvent>;
var
  Targets : TObjectDictionary<integer, TList<ProcGUIEvent>>;
  Subscriptions : TList<ProcGUIEvent>;
begin
  if not FEventSubscriptions.TryGetValue(Event, Targets) then
  begin
    if CanFail then exit(nil);
    Targets := TObjectDictionary < integer, TList < ProcGUIEvent >>.Create([doOwnsValues]);
    FEventSubscriptions.Add(Event, Targets);
  end;

  if not Targets.TryGetValue(OnlyForComponent, Subscriptions) then
  begin
    if CanFail then exit(nil);
    Subscriptions := TList<ProcGUIEvent>.Create;
    Targets.Add(OnlyForComponent, Subscriptions);
  end;

  Result := Subscriptions;
end;

function TGUI.GetViewSize : RIntVector2;
begin
  if FViewSize.Width <= 0 then
      Result.Width := Scene.Size.Width
  else
      Result.Width := FViewSize.Width;
  if FViewSize.Height <= 0 then
      Result.Height := Scene.Size.Height
  else
      Result.Height := FViewSize.Height;
end;

procedure TGUI.SubscribeToEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent; OnlyForComponent : TGUIComponent);
begin
  GetSubscriptions(Event, OnlyForComponent, False).Add(Callback);
end;

procedure TGUI.UnsubscribeFromEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent; OnlyForComponent : TGUIComponent);
begin
  GetSubscriptions(Event, OnlyForComponent, False).Remove(Callback);
end;

procedure TGUI.ProcessEvents;
var
  Event : RGUIEvent;
  Eventname : string;
  Parameter : TValue;
  procedure CallSubscriptions(Subscriptions : TList<ProcGUIEvent>);
  var
    i : integer;
  begin
    if assigned(Subscriptions) then
      for i := 0 to Subscriptions.Count - 1 do
          Subscriptions[i](Event);
  end;

begin
  while FEventQueue.Count > 0 do
  begin
    Event := FEventQueue.Dequeue;
    // manage focus ------------------------------------------------------------------------------
    if Event.Event = geFocus then SetFocus(Event.UID);

    // call all event handlers ------------------------------------------------------------------
    // first process all direct subscriptions to the sending component
    CallSubscriptions(GetSubscriptions(Event.Event, Event.UID, True));

    // then all global subscriptions to this event
    CallSubscriptions(GetSubscriptions(Event.Event, nil, True));

    // now call subscribers to all events
    CallSubscriptions(GetSubscriptions(geAll, Event.UID, True));

    // now call global subscribers to all events
    CallSubscriptions(GetSubscriptions(geAll, nil, True));

    // pass the event to the dXML engine ---------------------------------------------------------
    // if there is a dynamic document bound we have to call events there as well
    if assigned(FDocument) and Event.IsValid and Event.Component.IsBound then
    begin
      Eventname := '';
      Parameter := TValue.Empty;
      case Event.Event of
        geSubmit : Eventname := 'submit';
        geClick : Eventname := 'click';
        geRightClick : Eventname := 'rightclick';
        geBlur : Eventname := 'blur';
        geChanged :
          begin
            Eventname := 'change';
            if Event.Component is TGUIEdit then Parameter := Event.Component.Text
            else if Event.Component is TGUICheckbox then Parameter := TGUICheckbox(Event.Component).Checked
            else if Event.Component.ElementName = 'progress' then Parameter := integer(Round(HConvert.ExtractSingleFromNativeUInt(Event.AdditionalData)));
          end;
        geMouseDown : Eventname := 'mouse_down';
        geMouseUp : Eventname := 'mouse_up';
        geFocus : Eventname := 'focus';
        geMouseEnter : Eventname := 'mouse_enter';
        geMouseLeave : Eventname := 'mouse_leave';
        geHint : Eventname := 'hint';
      end;
      if Eventname <> '' then
          Event.Component.FXMLNode.CallEvent(Eventname, Parameter);
    end;
  end;
end;

function TGUI.TopHoveredElementWithHint : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to FHoveredElements.Count - 1 do
    if ResolveUID(FHoveredElements[i]).HasHint then
        exit(FHoveredElements[i]);
end;

procedure TGUI.HandleMouse(Mouse : TMouse);
var
  Button : EnumMouseButton;
begin
  MouseMove(Mouse.Position);
  for Button := low(EnumMouseButton) to high(EnumMouseButton) do
  begin
    if Mouse.ButtonDown(Button) then MouseDown(Button);
    if Mouse.ButtonUp(Button) then MouseUp(Button);
  end;
  MouseWheel(Mouse.dZ);
end;

procedure TGUI.HideAllHints;
var
  Hint : TGUIComponent;
begin
  for Hint in FHintComponents.Values do
      Hint.Visible := False;
end;

procedure TGUI.HideHint;
begin
  GetCurrentHintComponent.Visible := False;
  FHintTargetComponent := -1;
  FHintVisible := False;
  FHintDelay.Start;
  FHintDelay.Pause;
end;

function TGUI.GetCurrentHintComponent : TGUIComponent;
begin
  Result := nil;
  FHintComponents.TryGetValue(FHintComponent, Result);
end;

procedure TGUI.Idle;
begin
  if FHintDelay.Expired then
  begin
    if FHintVisible then HideHint;
    ShowHint; // may trigger geHint, so process events after that
  end;

  FRoot.ApplyStyleRecursive(ScreenRect);
  FDynamicRoot.ApplyStyleRecursive(ScreenRect);
  FRoot.IdleRecursive;
  FDynamicRoot.IdleRecursive;
  // add render jobs
  FRenderRequirements := FRoot.RenderRequirements;
  FRoot.RenderRecursive(ScreenRect);
  FDynamicRoot.RenderRecursive(ScreenRect);
end;

procedure TGUI.InitDynamicDOMRoot;
begin
  FDynamicRoot.Free;
  FDynamicRoot := TGUIComponent.Create(self, nil, 'dynamicroot');
  FDynamicRoot.ChangeStyle<RGSSSpaceData>(gtSize, [RGSSSpaceData.CreateRelativeScreenWidth(1.0), RGSSSpaceData.CreateRelativeScreenHeight(1.0)]);
  FDynamicRoot.ChangeStyle<EnumMouseEvent>(gtMouseEvents, mePass);
end;

function TGUI.GetClickableUnderMouse : TGUIComponent;
var
  i : integer;
  Comp : TGUIComponent;
begin
  Result := nil;
  for i := 0 to FHoveredElements.Count - 1 do
    if TryResolveUID(FHoveredElements[i], Comp) then
    begin
      if Comp.MouseEvents in [mePass, mePassClick] then continue;
      if Comp.Enabled or (Comp.FCursor = crClickable) then
          Result := Comp;
      break;
    end;
end;

function TGUI.IsMouseOverClickable : boolean;
begin
  Result := GetClickableUnderMouse <> nil;
end;

function TGUI.IsMouseOverHint : boolean;
var
  i : integer;
  Comp : TGUIComponent;
begin
  Result := False;
  for i := 0 to FHoveredElements.Count - 1 do
    if TryResolveUID(FHoveredElements[i], Comp) then
    begin
      if Comp.MouseEvents in [mePass] then continue;
      Result := Comp.HasHint or (Comp.FCursor = crHint);
      if Result then break;
    end;
end;

function TGUI.IsMouseOverGUI : boolean;
begin
  Result := FHoveredElements.Count > 0;
end;

function TGUI.GetWritableUnderMouse : TGUIComponent;
var
  Comp : TGUIComponent;
begin
  Result := nil;
  if (FHoveredElements.Count > 0) and
    TryResolveUID(FHoveredElements.First, Comp) and
    ((Comp.Enabled and (Comp is TGUIEdit)) or (Comp.FCursor = crText)) then
      Result := Comp;
end;

function TGUI.IsMouseOverWritable : boolean;
begin
  Result := GetWritableUnderMouse <> nil;
end;

function TGUI.KeyboardDown(Key : EnumKeyboardKey) : boolean;
begin
  Result := DOMRoot.KeyboardEventRecursive(keDown, Key);
end;

function TGUI.KeyboardUp(Key : EnumKeyboardKey) : boolean;
begin
  Result := DOMRoot.KeyboardEventRecursive(keUp, Key);
end;

procedure TGUI.MouseMove(const Position : RIntVector2);
var
  ContainingComponent, Element : TGUIComponent;
  OldHoveredElements : TAdvancedList<integer>;
  i, Index : integer;
begin
  FLastMousePosition := Position;
  // look for hovered component stack, first dom, than world
  ContainingComponent := nil;
  if not assigned(ContainingComponent) then ContainingComponent := DOMRoot.FindContainingComponent(Position);
  if not assigned(ContainingComponent) then ContainingComponent := DynamicDOMRoot.FindContainingComponent(Position);
  if assigned(ContainingComponent) then
  begin
    // leave old elements and enter new elements
    OldHoveredElements := FHoveredElements;
    FHoveredElements := TAdvancedList<integer>.Create;
    while assigned(ContainingComponent) do
    begin
      FHoveredElements.Add(ContainingComponent.UID);
      ContainingComponent := ContainingComponent.Parent;
    end;
    // remove same items (so they dont get enter/leave events)
    for i := 0 to FHoveredElements.Count - 1 do
    begin
      index := OldHoveredElements.IndexOf(FHoveredElements[i]);
      if index >= 0 then OldHoveredElements.Delete(index);
    end;
    // leave and clear remaining old components
    for i := 0 to OldHoveredElements.Count - 1 do
      if TryResolveUID(OldHoveredElements[i], Element) then Element.MouseLeave;
    OldHoveredElements.Free;
    // leave and clear remaining old components
    for i := 0 to FHoveredElements.Count - 1 do
      if TryResolveUID(FHoveredElements[i], Element) then Element.MouseEnter;
    // send move events to currently hovered elements
    for i := 0 to FHoveredElements.Count - 1 do
      if TryResolveUID(FHoveredElements[i], Element) then Element.MouseMove(Position);
  end
  // nothing found
  else
  begin
    // leave all hovered elements
    for i := 0 to FHoveredElements.Count - 1 do
      if TryResolveUID(FHoveredElements[i], Element) then Element.MouseLeave;
    FHoveredElements.Clear;
  end;
end;

procedure TGUI.MouseDown(Button : EnumMouseButton);
var
  i : integer;
  Element : TGUIComponent;
  IsEnabled : boolean;
  MouseEvents : EnumMouseEvent;
begin
  for i := 0 to FHoveredElements.Count - 1 do
    if FHoveredElements.InRange(i) and TryResolveUID(FHoveredElements[i], Element) then
    begin
      IsEnabled := Element.Enabled;
      MouseEvents := Element.MouseEvents;
      if MouseEvents in [mePass, mePassClick] then continue;
      // component may be killed here
      Element.MouseDown(FLastMousePosition, Button);
      if IsEnabled or (MouseEvents in [meAll, meBlock]) then break;
    end;
end;

procedure TGUI.MouseUp(Button : EnumMouseButton);
var
  Element : TGUIComponent;
  i : integer;
  IsEnabled : boolean;
  MouseEvents : EnumMouseEvent;
begin
  ClearFocus;
  for i := 0 to FHoveredElements.Count - 1 do
    if FHoveredElements.InRange(i) and TryResolveUID(FHoveredElements[i], Element) then
    begin
      IsEnabled := Element.Enabled;
      MouseEvents := Element.MouseEvents;
      if MouseEvents in [mePass, mePassClick] then continue;
      // component may be killed here
      Element.MouseUp(FLastMousePosition, Button);
      if IsEnabled or (MouseEvents in [meAll, meBlock]) then break;
    end;
  // clear mouse down states
  for Element in FComponents.Values do
      Element.ClearMouseState;
end;

procedure TGUI.MouseWheel(Ticks : integer);
var
  Element : TGUIComponent;
  i : integer;
begin
  if Ticks <> 0 then
    for i := 0 to FHoveredElements.Count - 1 do
      if FHoveredElements.InRange(i) and TryResolveUID(FHoveredElements[i], Element) then
          Element.MouseWheel(FLastMousePosition, Ticks);
end;

procedure TGUI.OnMouse(const Sender : RGUIEvent);
var
  temp : TGUIComponent;
begin
  if (Sender.Event = geMouseLeave) and (Sender.UID = FHintTargetComponent) then HideHint;
  if (Sender.Event = geMouseEnter) and (Sender.UID = TopHoveredElementWithHint) and Sender.IsValid then
  begin
    temp := Sender.Component;
    if temp.HasHint then
    begin
      FHintDelay.Interval := HintDelay;
      FHintDelay.Start;
      temp.PrepareHint;
    end;
  end;
end;

procedure TGUI.PutError(const msg : string);
begin
  if assigned(Erroroutput) then Erroroutput(msg);
end;

procedure TGUI.RenameComponent(const newName : string; Component : TGUIComponent);
var
  newNameFinal : string;
begin
  // remove dots for fullqualified name
  newNameFinal := newName.Replace('.', '');
  if newNameFinal.ToLowerInvariant <> Component.FName.ToLowerInvariant then
  begin
    RemoveComponent(Component);
    Component.FName := newNameFinal;
    AddComponent(Component);
  end;
end;

procedure TGUI.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
begin
  // all gui components are drawn by the vertex engine, so here is now custom render code
end;

function TGUI.Requirements : SetRenderRequirements;
begin
  Result := FRenderRequirements;
end;

procedure TGUI.ResolveAutoAnchor(var Anchor : EnumComponentAnchor; const Position : RVector2);
begin
  if Anchor = caAuto then
  begin
    if Position.X > 3 * ViewRect.Width / 4 then
    begin
      if Position.Y < ViewRect.Height / 4 then
          Anchor := caTopRight
      else
          Anchor := caBottomRight;
    end
    else
    begin
      if Position.Y < ViewRect.Height / 4 then
          Anchor := caTopLeft
      else
          Anchor := caBottomLeft;
    end;
  end;
end;

function TGUI.ResolveUID(UID : integer) : TGUIComponent;
begin
  if not TryResolveUID(UID, Result) then Result := nil;
end;

function TGUI.TryResolveUID(UID : integer; out Component : TGUIComponent) : boolean;
begin
  Result := FComponents.TryGetValue(UID, Component);
end;

procedure TGUI.UpdateDynamicRootSize;
begin
  // real output is always full screen
  FDynamicRoot.ChangeStyle<RGSSSpaceData>(gtSize, [RGSSSpaceData.CreateRelativeScreenWidth(1.0), RGSSSpaceData.CreateRelativeScreenHeight(1.0)]);
  FDynamicRoot.SetCompleteDirty;
end;

procedure TGUI.UpdateResolution;
begin
  UpdateRootSize;
  UpdateDynamicRootSize;
  UpdateVirtualSizeModifier;
end;

procedure TGUI.UpdateRootSize;
var
  FinalSize : RIntVector2;
  Padding : RIntVector4;
begin
  // real output is always full screen
  FRoot.ChangeStyle<RGSSSpaceData>(gtSize, [RGSSSpaceData.CreateRelativeScreenWidth(1.0), RGSSSpaceData.CreateRelativeScreenHeight(1.0)]);

  // Determine final output size
  FinalSize := self.ViewSize;

  // fill gaps with padding
  Padding.Top := Max(0, (Scene.Size.Height - FinalSize.Height) div 2);
  Padding.Bottom := Max(0, ((Scene.Size.Height - FinalSize.Height) div 2) + ((Scene.Size.Height - FinalSize.Height) mod 2));
  Padding.Left := Max(0, (Scene.Size.Width - FinalSize.Width) div 2);
  Padding.Right := Max(0, ((Scene.Size.Width - FinalSize.Width) div 2) + ((Scene.Size.Width - FinalSize.Width) mod 2));

  FRoot.ChangeStyle<RGSSSpaceData>(gtPadding, [
    RGSSSpaceData.CreateRelativeScreenHeight(Padding.Top / Scene.Size.Height),
    RGSSSpaceData.CreateRelativeScreenWidth(Padding.Right / Scene.Size.Width),
    RGSSSpaceData.CreateRelativeScreenHeight(Padding.Bottom / Scene.Size.Height),
    RGSSSpaceData.CreateRelativeScreenWidth(Padding.Left / Scene.Size.Width)
    ]);

  FRoot.SetCompleteDirty;
end;

procedure TGUI.UpdateVirtualSizeModifier;
begin
  if (FVirtualSize.X > 0) and (FVirtualSize.Y > 0) then
      FVirtualSizeModifier := ViewSize.ToRVector / FVirtualSize
  else
      FVirtualSizeModifier := RVector2.Create(1);
end;

function TGUI.ViewRect : RRectFloat;
begin
  Result := RRectFloat.CreateWidthHeight(RVector2.ZERO, self.ViewSize)
end;

{ TGUIComponent }

procedure TGUIComponent.AddChild(Child : TGUIComponent);
begin
  if not FChildren.Contains(Child) then FChildren.Add(Child);
  Child.Parent := self;
  SetDirty;
end;

function TGUIComponent.AddChildByItemTemplate(const Index : integer) : TGUIComponent;
begin
  Result := TGUIComponent.CreateFromFile(AbsolutePath(FGUI.AssetPath + '/' + ItemTemplates[index]), FGUI, nil, True);
  if assigned(Result) then AddChild(Result);
end;

function TGUIComponent.AddClass(const GSSClass : string) : boolean;
var
  ClassID : integer;
begin
  Result := False;
  if self = nil then exit;
  ClassID := TGUIStyleManager.ResolveClassname(GSS_CLASS_PREFIX + GSSClass);
  if not FClasses.Contains(ClassID) then
  begin
    FClasses.Add(ClassID);
    FClassesAsText := ClassesAsText;
    Result := True;
    // class changes can influence all descendants
    SetStyleSheetStackDirtyRecursive;
  end;
end;

function TGUIComponent.AnchorPosition(Anchor : EnumComponentAnchor) : RIntVector2;
begin
  Result := FRect.Translate((ord(Anchor) mod 3) * FRect.Width / 2, (ord(Anchor) div 3) * FRect.Height / 2).LeftTop.Round;
end;

function TGUIComponent.BindClass(Value : boolean; const GSSClass : string) : TGUIComponent;
begin
  Result := self;
  if Value then AddClass(GSSClass)
  else RemoveClass(GSSClass);
end;

procedure TGUIComponent.ApplyStyle(const ViewRect : RRectFloat);
var
  i, currentZOffset : integer;
  NewOverflow : EnumOverflowHandling;
  Shader : string;
begin
  // enabled can have influence on style, so compute it first
  if gtEnabled in FDirty then SetEnabledStyle(GetStyleValue<boolean>(gtEnabled));
  ComputeVisibility;

  if not Visible then exit;

  if gtZoom in FDirty then FZoom := GetStyleValue<single>(gtZoom);

  if gtZOffset in FDirty then FZOffset := GetStyleValue<integer>(gtZOffset);

  if gtParentOffset in FDirty then FParentOffset := GetStyleValue<integer>(gtParentOffset);

  if gtDrawSpace in FDirty then FDrawSpace := GetStyleValue<EnumDrawSpace>(gtDrawSpace);

  ComputeSizing;
  ComputeTransform;

  ComputePosition;

  // if rect is not in view, we can stop here as we don't see anything
  if IsClipped(ViewRect) then exit;

  if gtOverflow in FDirty then
  begin
    NewOverflow := GetStyleValue<EnumOverflowHandling>(gtOverflow);
    if FOverflow <> NewOverflow then ScrollOffset := RIntVector2.ZERO;
    FOverflow := NewOverflow;
  end;
  if HasScrollbars then
      ComputeScrollbars;

  FViewRect := ViewRect;
  if FOverflow in OVERFLOW_CLIPPING_VALUES then FViewRect := BackgroundRect.Intersection(ViewRect);
  FCliprect := BackgroundRect.Intersection(FViewRect);

  if gtOpacity in FDirty then
      FOpacity := GetStyleValue<single>(gtOpacity);
  if gtOpacityInheritance in FDirty then
      FOpacityInheritance := GetStyleValue<boolean>(gtOpacityInheritance);

  ComputeBorderAndOutline;

  // Background rendering
  if gtBackgroundShader in FDirty then
  begin
    Shader := GetStyleValue<string>(gtBackgroundShader);
    if (Shader <> '') and HFilepathManager.FileExists(FGUI.AssetPath + '\' + Shader) then FDerivedShader := FGUI.AssetPath + '\' + Shader
    else FDerivedShader := '';
  end;

  ComputeScene;
  ComputeBackgroundAnimation;
  ComputeTransition;
  ComputeBackgroundTextures;
  ComputeBackgroundQuad;

  // Text rendering
  ComputeText;

  if (gtBlur in FDirty) then
  begin
    FBlur := GetStyleValue<boolean>(gtBlur);
    if FBlur then
    begin
      if not assigned(FBlurQuad) then
      begin
        FBlurQuad := TVertexScreenAlignedQuad.Create(VertexEngine);
        FBlurQuad.DrawsAtStage := rsGUI;
        FBlurQuad.DrawOrder := ZOffset * 2 - 1;
      end;
    end
    else
        FreeAndNil(FBlurQuad);
  end;

  // blur
  if gtBlurLayer in FDirty then
      FBlurLayer := GetStyleValue<boolean>(gtBlurLayer);
  if gtBlurMask in FDirty then
      LoadTexture(gtBlurMask, @FBlurMask);
  if gtBlurColor in FDirty then
  begin
    FBlurColor := GetStyleValue<RColor>(gtBlurColor);
    if not TryGetStyleValue<RColor>(gtBlurColor, FBlurColorFallback, 1) then FBlurColorFallback := FBlurColor;
  end;

  ComputeBorderImage;

  if gtZOffset in FDirty then
  begin
    currentZOffset := ZOffset * 2;
    if assigned(FQuad) then
        FQuad.DrawOrder := currentZOffset;
    if assigned(FBlurQuad) then
        FBlurQuad.DrawOrder := currentZOffset - 1;
    if assigned(FFont) then
        FFont.DrawOrder := currentZOffset + 1;
    if assigned(FScrollbarBackgroundQuad) then
        FScrollbarBackgroundQuad.DrawOrder := currentZOffset + 2;
    if assigned(FScrollbarTrackerQuad) then
        FScrollbarTrackerQuad.DrawOrder := currentZOffset + 3;
    for i := 0 to length(FBorderImage) - 1 do
      if assigned(FBorderImage[i]) then FBorderImage[i].DrawOrder := currentZOffset;
  end;

  // interactivity
  if gtMouseEvents in FDirty then
      FMouseEvent := GetStyleValue<EnumMouseEvent>(gtMouseEvents);
  if gtCursor in FDirty then
      FCursor := GetStyleValue<EnumCursor>(gtCursor);
  if gtHint in FDirty then
      FHint := GetStyleValue<string>(gtHint);
  if gtHintTemplate in FDirty then
      FHintTemplate := GetStyleValue<string>(gtHintTemplate);
  if gtHintClasses in FDirty then
      FHintClasses := GetStyleValue<string>(gtHintClasses);

  // progress
  if gtProgressshape in FDirty then
      FProgressShape := GetStyleValue<EnumProgressShape>(gtProgressshape);

  ComputeAnimation;
end;

procedure TGUIComponent.ApplyStyleRecursive(const ViewRect : RRectFloat);
var
  Child : TGUIComponent;
begin
  CheckAndBuildStyleSheetStack;
  if FDirty = [] then
      exit;
  FDirty := FDirty - [gtDirtyChildren, gtDirtyGrandChildren];
  if FDirty <> [] then
      ApplyStyle(ViewRect);
  FDirty := [];
  if not Visible or IsClipped(ViewRect) then
      exit;

  for Child in FChildren do
      Child.ApplyStyleRecursive(FViewRect);
end;

constructor TGUIComponent.Create;
begin
  FCoordinateRect := RRectFloat.Create(0, 0, 1, 1);
  FUID := -1;
  FDepthOverride := -1;
  FZoom := 1.0;
  FOpacity := 1.0;
  FChildren := TObjectList<TGUIComponent>.Create;
  InitDefaultStyle;
  FDirty := AllGSSTags;
  FDown := obStyleFalse;
  FEnabled := obStyleFalse;
  FClasses := TList<integer>.Create;
  ElementName := DefaultElementName;
  FTransform := RMatrix4x3.IDENTITY;
  FTransformAnchor := caAuto;
  FStyleSheetStackDirty := True;
  FClassHierarchyDirty := True;
  FProgressmaximum := 1.0;
end;

procedure TGUIComponent.ChangeStyle<T>(Key : EnumGSSTag; Index : integer; const Value : T);
begin
  if self = nil then exit;
  if FStyleSheet.AddOrSetValue(Key, index, Value) then
      SetDirty([Key]);
end;

procedure TGUIComponent.ChangeStyle<T>(Key : EnumGSSTag; const Value : T);
begin
  ChangeStyle<T>(Key, 0, Value);
end;

procedure TGUIComponent.ChangeStyle<T>(Key : EnumGSSTag; Values : array of T);
begin
  if self = nil then exit;
  if FStyleSheet.AddOrSetValue<T>(Key, Values) then SetDirty([Key]);
end;

procedure TGUIComponent.ChangeStyleFilterDescendants<T>(Key : EnumGSSTag; const ValueIfTrue, ValueIfFalse : T; const Filter : ProcDescendantFilter);
begin
  ChangeStyleFilterDescendantsRecursive<T>(Key, ValueIfTrue, ValueIfFalse, 0, self, Filter);
end;

procedure TGUIComponent.ChangeStyleFilterDescendantsRecursive<T>(Key : EnumGSSTag; ValueIfTrue, ValueIfFalse : T; Depth : integer;
  Node : TGUIComponent; Filter : ProcDescendantFilter);
var
  i : integer;
begin
  for i := 0 to Node.FChildren.Count - 1 do
  begin
    if Filter(i, Depth + 1) then Node.FChildren[i].ChangeStyle<T>(Key, ValueIfTrue)
    else Node.FChildren[i].ChangeStyle<T>(Key, ValueIfFalse);
    ChangeStyleFilterDescendantsRecursive<T>(Key, ValueIfTrue, ValueIfFalse, Depth + 1, Node.FChildren[i], Filter);
  end;
end;

procedure TGUIComponent.ChangeStyleFilterDescendantsRecursive<T>(Key : EnumGSSTag; Value : T; Depth : integer; Node : TGUIComponent; Filter : ProcDescendantFilter);
var
  i : integer;
begin
  for i := 0 to Node.FChildren.Count - 1 do
  begin
    if Filter(i, Depth + 1) then Node.FChildren[i].ChangeStyle<T>(Key, Value);
    ChangeStyleFilterDescendantsRecursive<T>(Key, Value, Depth + 1, Node.FChildren[i], Filter);
  end;
end;

procedure TGUIComponent.ChangeStyleFilterDescendants<T>(Key : EnumGSSTag; const Value : T; const Filter : ProcDescendantFilter);
begin
  ChangeStyleFilterDescendantsRecursive<T>(Key, Value, 0, self, Filter);
end;

procedure TGUIComponent.ChangeStyleWithDescendants<T>(Key : EnumGSSTag; const Value : T);
var
  Child : TGUIComponent;
begin
  ChangeStyle<T>(Key, Value);
  for Child in FChildren do Child.ChangeStyleWithDescendants<T>(Key, Value);
end;

procedure TGUIComponent.CheckAndBuildAnimationStack;
begin
  if assigned(FAnimationStack) and not FAnimationStack.IsValid then
  begin
    FAnimationStack.Free;
    FAnimationStack := FGUI.StyleManager.GetAnimationStack(FAnimationName);
  end;
end;

procedure TGUIComponent.CheckAndBuildStyleSheetStack;
begin
  if not assigned(FStyleSheetStack) or FStyleSheetStackDirty or not FStyleSheetStack.IsValid then
      BuildStyleSheetStack;
end;

function TGUIComponent.ChildCount : integer;
begin
  if not assigned(self) then exit(0);
  Result := FChildren.Count;
end;

procedure TGUIComponent.ChildrenChanged;
begin
end;

procedure TGUIComponent.ClearChildren;
begin
  if not assigned(self) then exit;
  FChildren.Clear;
  ChildrenChanged;
end;

procedure TGUIComponent.ClearEnabled;
begin
  if FEnabled in [obForceTrue, obForceFalse] then
  begin
    if FEnabled = obForceTrue then FEnabled := obStyleTrue
    else FEnabled := obStyleFalse;
    SetDirty([gtEnabled]);
  end;
end;

procedure TGUIComponent.ClearGrandChildren;
var
  i : integer;
begin
  if not assigned(self) then exit;
  for i := 0 to FChildren.Count - 1 do
      FChildren[i].ClearChildren;
end;

procedure TGUIComponent.ClearMouseState;
var
  Button : EnumMouseButton;
begin
  for Button := low(EnumMouseButton) to high(EnumMouseButton) do
      FMouseDown[Button] := False;
end;

procedure TGUIComponent.ClearVisible;
begin
  if FVisible in [obForceTrue, obForceFalse] then
  begin
    if FVisible = obForceTrue then FVisible := obStyleTrue
    else FVisible := obStyleFalse;
    SetDirty([gtVisibility]);
  end;
end;

procedure TGUIComponent.Click(Button : EnumMouseButton; const Position : RVector2);
begin
  if self = nil then exit;
  SetFocus;
  if Button = mbLeft then
  begin
    SetDownSoft(False);
    FGUI.AddEvent(RGUIEvent.Create(geClick, self));
    if (ElementName = 'progress') then
    begin
      FGUI.AddEvent(RGUIEvent.Create(geChanged, self).SetAdditionalData(HConvert.PackSingleToNativeUInt(100 * HMath.Saturate(ContentRect.LocalCoordinate(Position).X))));
    end;
  end;
  if Button = mbRight then
      FGUI.AddEvent(RGUIEvent.Create(geRightClick, self));
end;

procedure TGUIComponent.ClipSize(Dim : integer);
var
  SpaceData : RGSSSpaceData;
  NewSize : single;
  OtherDim : integer;
begin
  OtherDim := (Dim + 1) mod 2;
  if TryGetStyleValue<RGSSSpaceData>(gtMinSize, SpaceData, Dim) and TryResolveSize(SpaceData, Dim, NewSize) then
      FRect.Dim[Dim] := Max(FRect.Dim[Dim], NewSize);
  if TryGetStyleValue<RGSSSpaceData>(gtMinSize, SpaceData, OtherDim) and TryResolveSize(SpaceData, OtherDim, NewSize) then
      FRect.Dim[OtherDim] := Max(FRect.Dim[OtherDim], NewSize);
  if TryGetStyleValue<RGSSSpaceData>(gtMaxSize, SpaceData, Dim) and TryResolveSize(SpaceData, Dim, NewSize) then
      FRect.Dim[Dim] := Min(FRect.Dim[Dim], NewSize);
  if TryGetStyleValue<RGSSSpaceData>(gtMaxSize, SpaceData, OtherDim) and TryResolveSize(SpaceData, OtherDim, NewSize) then
      FRect.Dim[OtherDim] := Min(FRect.Dim[OtherDim], NewSize);
end;

procedure TGUIComponent.Click(Button : EnumMouseButton);
begin
  Click(Button, FRect.Center);
end;

procedure TGUIComponent.ComputeScene;
var
  Scene : TRenderManager;
begin
  if gtSceneName in FDirty then
      FSceneName := GetStyleValue<string>(gtSceneName);
  if gtSceneSuperSampling in FDirty then
      FSceneSuperSampling := GetStyleValue<integer>(gtSceneSuperSampling);
  if gtSceneCamera in FDirty then
  begin
    FSceneEye.X := GetStyleValue<single>(gtSceneCamera, 0);
    FSceneEye.Y := GetStyleValue<single>(gtSceneCamera, 1);
    FSceneEye.Z := GetStyleValue<single>(gtSceneCamera, 2);
    FSceneTarget.X := GetStyleValue<single>(gtSceneCamera, 3);
    FSceneTarget.Y := GetStyleValue<single>(gtSceneCamera, 4);
    FSceneTarget.Z := GetStyleValue<single>(gtSceneCamera, 5);
  end;
  if (FSceneName <> '') and GFXD.TryGetScene(FSceneName, Scene) then
  begin
    if [gtSceneSuperSampling, gtSize] * FDirty <> [] then
        Scene.ChangeResolution(BackgroundRect.Size.Round * (FSceneSuperSampling + 1));
    Scene.Camera.Position := FSceneEye;
    Scene.Camera.Target := FSceneTarget;
  end;
end;

procedure TGUIComponent.ComputeScrollbars;
var
  i : integer;
begin
  if gtScrollbarWidth in FDirty then
      FScrollbarWidth := GetStyleValue<integer>(gtScrollbarWidth);
  if gtScrollbarPadding in FDirty then
  begin
    FScrollbarPadding := RIntVector4.Create(0);
    for i := 0 to 3 do
        TryGetStyleValue<integer>(gtScrollbarPadding, FScrollbarPadding.Element[i], i);
  end;

  if gtScrollbarBackgroundColor in FDirty then
      FScrollbarBackgroundColor.Default := GetStyleValue<RColor>(gtScrollbarBackgroundColor);
  if gtScrollbarBackgroundColorHover in FDirty then
      FScrollbarBackgroundColor.Hover := GetStyleValue<RColor>(gtScrollbarBackgroundColorHover);
  if gtScrollbarBackgroundColorElementHover in FDirty then
      FScrollbarBackgroundColor.Disabled := GetStyleValue<RColor>(gtScrollbarBackgroundColorElementHover);

  if gtScrollbarColor in FDirty then
      FScrollbarColor.Default := GetStyleValue<RColor>(gtScrollbarColor);
  if gtScrollbarColorHover in FDirty then
      FScrollbarColor.Hover := GetStyleValue<RColor>(gtScrollbarColorHover);
  if gtScrollbarColorElementHover in FDirty then
      FScrollbarColor.Disabled := GetStyleValue<RColor>(gtScrollbarColorElementHover);

  if not assigned(FScrollbarBackgroundQuad) then
  begin
    FScrollbarBackgroundQuad := TVertexScreenAlignedQuad.Create(VertexEngine);
    FScrollbarBackgroundQuad.DrawsAtStage := rsGUI;
    FScrollbarBackgroundQuad.DrawOrder := ZOffset * 2 + 2;
  end;
  if not assigned(FScrollbarTrackerQuad) then
  begin
    FScrollbarTrackerQuad := TVertexScreenAlignedQuad.Create(VertexEngine);
    FScrollbarTrackerQuad.DrawsAtStage := rsGUI;
    FScrollbarTrackerQuad.DrawOrder := ZOffset * 2 + 3;
  end;
end;

procedure TGUIComponent.ComputeSize(Dim : integer);
var
  OtherDim, i : integer;
  SpaceData : RGSSSpaceData;
  NewSize : single;
  OldFontDesc, FontDesc : RFontDescription;
begin
  if HLog.AssertAndLog((Dim = 0) or (Dim = 1), 'TGUIComponent.ComputeSize: GUI Components only have 2 dimensions!') then exit;
  if not Visible then
  begin
    FRect.Dim[Dim] := 0;
    exit;
  end;
  OtherDim := (Dim + 1) mod 2;
  SpaceData := GetStyleValue<RGSSSpaceData>(gtSize, Dim);
  if SpaceData.IsInherit then exit// has been set by parent, so don't overwrite any values
  else if SpaceData.IsAuto then
  begin
    SpaceData := GetStyleValue<RGSSSpaceData>(gtSize, OtherDim);
    if not SpaceData.IsAuto then ComputeSize(OtherDim); // if both auto, we take size of first children
    if assigned(FBgTexture.Default) and not SpaceData.IsAuto then
    begin
      FRect.Dim[Dim] := FRect.Dim[OtherDim] * (FBgTexture.Default.Dimension[Dim] / FBgTexture.Default.Dimension[OtherDim]);
      if FBgSheetSize > 1 then
          FRect.Dim[Dim] := FRect.Dim[Dim] / (FBgSheetSize.Element[Dim] / FBgSheetSize.Element[OtherDim]);
    end
    else
    begin
      // auto without background => same as other dim or if have children size of first child
      FRect.Dim[Dim] := FRect.Dim[OtherDim];
      if FChildren.Count > 0 then
      begin
        for i := 0 to FChildren.Count - 1 do
        begin
          FChildren[i].ComputeVisibility;
          if not FChildren[i].IsVisible then continue;
          FChildren[i].ComputeSizing;
          ContentRect := ContentRect.SetDim(FChildren[i].GetOuterRect.Dim[Dim], Dim);
          break;
        end;
      end;
    end;
  end
  else if SpaceData.IsText then
  begin
    ComputeText;
    if assigned(FFont) then
    begin
      FFont.Text := FText;
      if SpaceData.Value > FONT_WEIGHT_EPSILON then
      begin
        OldFontDesc := FFont.FontDescription;
        FontDesc := FFont.FontDescription;
        FontDesc.Weight := ConvertFontWeight(Round(SpaceData.Value));
        FFont.FontDescription := FontDesc;
      end;
      if Dim = 0 then
          ContentRect := ContentRect.SetWidth(FFont.TextWidth)
      else
      begin
        // Dim 0 should be already computed at this moment
        FFont.Rect := ContentRect.Round;
        ContentRect := ContentRect.SetHeight(FFont.TextBlockHeight);
      end;
      if SpaceData.Value > FONT_WEIGHT_EPSILON then
          FFont.FontDescription := OldFontDesc;
    end;
  end
  else if TryResolveSize(SpaceData, Dim, NewSize) then FRect.Dim[Dim] := NewSize;

  // clip size against min and maxsize
  ClipSize(Dim);
end;

procedure TGUIComponent.ComputeSizing;
var
  SpaceDataX, SpaceDataY : RGSSSpaceData;
begin
  if gtBoxSizing in FDirty then FBoxSizing := GetStyleValue<EnumBoxSizing>(gtBoxSizing);
  if gtParentBox in FDirty then FParentBox := GetStyleValue<EnumParentBox>(gtParentBox);

  // compute rect
  if ([gtSize, gtMinSize, gtMaxSize, gtDefaultText, gtText, gtTextTransform, gtParentOffset, gtBackground] * FDirty <> []) then
  begin
    SpaceDataX := GetStyleValue<RGSSSpaceData>(gtSize, 0);
    SpaceDataY := GetStyleValue<RGSSSpaceData>(gtSize, 1);
    if SpaceDataX.IsAuto or SpaceDataY.IsAuto or
      SpaceDataX.IsRelativeBackgroundWidth or SpaceDataX.IsRelativeBackgroundHeight or
      SpaceDataY.IsRelativeBackgroundWidth or SpaceDataY.IsRelativeBackgroundHeight then
    begin
      ComputeBackgroundAnimation;
      ComputeBackgroundTextures; // if a size has auto it keeps aspect ratio of background image
      ComputeMargin;             // or if it has no background image it wraps the first children,therefore we need the content rect
      ComputePadding;
    end;
    // if container width is dependend from font width, precompute container height as font height can be dependend from it
    if SpaceDataX.IsText then ComputeSize(1);
    if SpaceDataX.IsText or SpaceDataY.IsText then
    begin
      // if a size has text it is dependend on the text and the final content rect
      ComputeMargin;
      ComputePadding;
      ComputeText;
    end;
    if SpaceDataX.IsAuto or SpaceDataX.IsRelativeContainerHeight then
    begin
      ComputeSize(1);
      ComputeSize(0);
    end
    else
    begin
      ComputeSize(0);
      ComputeSize(1);
    end;
  end;

  if (gtMargin in FDirty) then ComputeMargin;
  if (gtPadding in FDirty) then ComputePadding;
end;

procedure TGUIComponent.ComputeText;
begin
  if gtDefaultText in FDirty then FRawStyleText := GetStyleValue<string>(gtDefaultText);
  if (gtTextTransform in FDirty) then
  begin
    UpdateStyleText(FRawStyleText);
    UpdateText(FText);
  end;

  if (Text <> '') and (FDirty * [gtDefaultText, gtText, gtFontsize, gtFontResolution, gtFontfamily, gtFontWeight, gtFontStyle, gtFontStretch, gtFontQuality, gtFontflags, gtFontBorder, gtFontcolor] <> []) then
  begin
    UpdateFont;
  end;
end;

procedure TGUIComponent.ComputeTransform;
var
  matrixString : string;
begin
  if gtTransform in FDirty then
  begin
    matrixString := GetStyleValue<string>(gtTransform);
    FTransform := TGUIStyleSheet.ResolveTransform(matrixString);
  end;
  if gtTransformKeepBackground in FDirty then
      FTransformKeepBackground := GetStyleValue<boolean>(gtTransformKeepBackground);
  if gtTransformInheritance in FDirty then
      FTransformInheritance := GetStyleValue<boolean>(gtTransformInheritance);
  if gtTransformAnchor in FDirty then
      FTransformAnchor := GetStyleValue<EnumComponentAnchor>(gtTransformAnchor);
  if gtTransformOrder in FDirty then
      FTransformOrder := GetStyleValue<EnumTransformOrder>(gtTransformOrder);
end;

procedure TGUIComponent.ComputeTransition;
var
  i : integer;
begin
  if gtTransitionProperty in FDirty then
  begin
    FTransisitonProperties := [];
    for i := 0 to StyleValueCount(gtTransitionProperty) - 1 do
        include(FTransisitonProperties, GetStyleValue<EnumGSSTag>(gtTransitionProperty, i));
    if (gtTransform in FTransisitonProperties) and not assigned(FTransitionValueTransform) then
        FTransitionValueTransform := TGUITransitionValueRMatrix4x3.Create;
    if (gtBackgroundColor in FTransisitonProperties) and not assigned(FTransitionValueBackgroundColor) then
        FTransitionValueBackgroundColor := TGUITransitionValueRColor.Create;
    if (gtOpacity in FTransisitonProperties) and not assigned(FTransitionValueOpacity) then
        FTransitionValueOpacity := TGUITransitionValueSingle.Create;
  end;
  if gtTransitionWithInheritance in FDirty then
      FTransitionWithInheritance := GetStyleValue<boolean>(gtTransitionWithInheritance);
  if gtTransitionDuration in FDirty then
  begin
    FTransisitonDuration := GetStyleValue<integer>(gtTransitionDuration);
    if assigned(FTransitionValueBackgroundColor) then
        FTransitionValueBackgroundColor.Duration := FTransisitonDuration;
    if assigned(FTransitionValueOpacity) then
        FTransitionValueOpacity.Duration := FTransisitonDuration;
    if assigned(FTransitionValueTransform) then
        FTransitionValueTransform.Duration := FTransisitonDuration;
  end;
  if gtTransitionTimingFunction in FDirty then
  begin
    FTransisitonTimingFunction := RCubicBezier.Create(
      GetStyleValue<single>(gtTransitionTimingFunction, 0),
      GetStyleValue<single>(gtTransitionTimingFunction, 1),
      GetStyleValue<single>(gtTransitionTimingFunction, 2),
      GetStyleValue<single>(gtTransitionTimingFunction, 3));
    if assigned(FTransitionValueBackgroundColor) then
        FTransitionValueBackgroundColor.TimingFunction := FTransisitonTimingFunction;
    if assigned(FTransitionValueOpacity) then
        FTransitionValueOpacity.TimingFunction := FTransisitonTimingFunction;
    if assigned(FTransitionValueTransform) then
        FTransitionValueTransform.TimingFunction := FTransisitonTimingFunction;
  end;
end;

procedure TGUIComponent.ComputeVisibility;
var
  WasVisible : boolean;
begin
  if (gtVisibility in FDirty) and (FVisible in [obStyleTrue, obStyleFalse]) then
  begin
    WasVisible := FVisible = obStyleTrue;
    if GetStyleValue<boolean>(gtVisibility) then
        FVisible := obStyleTrue
    else
        FVisible := obStyleFalse;
    if not WasVisible and (FVisible = obStyleTrue) then
        SetCompleteDirty;
  end;
end;

function TGUIComponent.Count : integer;
begin
  if not assigned(self) then exit(0);
  Result := FChildren.Count;
end;

function TGUIComponent.GetContentRect : RRectFloat;
begin
  case FBoxSizing of
    bsPadding : Result := FRect;
    bsContent : Result := FRect.Inflate(-FPadding);
    bsMargin : Result := FRect.Inflate(-FPadding).Inflate(-FMargin);
  end;
end;

procedure TGUIComponent.SetContentRect(const Value : RRectFloat);
begin
  case FBoxSizing of
    bsPadding : FRect := Value;
    bsContent : FRect := Value.Inflate(FPadding);
    bsMargin : FRect := Value.Inflate(FPadding).Inflate(FMargin);
  end;
end;

function TGUIComponent.BackgroundRect : RRectFloat;
begin
  case FBoxSizing of
    bsPadding : Result := FRect.Inflate(FPadding);
    bsContent : Result := FRect;
    bsMargin : Result := FRect.Inflate(-FMargin);
  end;
end;

function TGUIComponent.GetOpacity : single;
begin
  CheckAndBuildAnimationStack;
  Result := FOpacity;
  if assigned(FAnimationStack) and FAnimationStack.AnimationStack.HasTag(gtOpacity) then
      Result := Result * FAnimationStack.AnimationStack.Interpolate(FCachedCurrentAnimationKey, gtOpacity).AsSingle;

  if not FTransitionWithInheritance and (gtOpacity in FTransisitonProperties) and assigned(FTransitionValueOpacity) then
  begin
    FTransitionValueOpacity.SetValue(Result);
    Result := FTransitionValueOpacity.CurrentValue;
  end;

  if HasParent and FOpacityInheritance then
      Result := Result * VirtualParent.Opacity;

  if FTransitionWithInheritance and (gtOpacity in FTransisitonProperties) and assigned(FTransitionValueOpacity) then
  begin
    FTransitionValueOpacity.SetValue(Result);
    Result := FTransitionValueOpacity.CurrentValue;
  end;
end;

function TGUIComponent.GetOuterRect : RRectFloat;
begin
  case FBoxSizing of
    bsPadding : Result := FRect.Inflate(FPadding).Inflate(FMargin);
    bsContent : Result := FRect.Inflate(FMargin);
    bsMargin : Result := FRect;
  end;
end;

procedure TGUIComponent.SetFocus;
begin
  FGUI.AddEvent(RGUIEvent.Create(geFocus, self));
end;

procedure TGUIComponent.SetFocusState(const State : boolean);
begin
  if FFocused <> State then
  begin
    FFocused := State;
    if not FFocused then FGUI.AddEvent(RGUIEvent.Create(geBlur, self));
    SetStyleSheetStackDirtyRecursive;
  end;
end;

procedure TGUIComponent.SetOuterRect(const Value : RRectFloat);
begin
  case FBoxSizing of
    bsPadding : FRect := Value.Inflate(-FPadding).Inflate(-FMargin);
    bsContent : FRect := Value.Inflate(-FMargin);
    bsMargin : FRect := Value;
  end;
end;

procedure TGUIComponent.SetParent(const Value : TGUIComponent);
begin
  if FParent <> Value then
  begin
    FParent := Value;
    SetStyleSheetStackDirtyRecursive;
  end;
end;

procedure TGUIComponent.SetScrollOffset(const Value : RVector2);
var
  newValue : RVector2;
begin
  newValue := FScrollRect.ClampPoint(Value);
  if not newValue.SimilarTo(FScrollOffset) then
  begin
    FScrollOffset := newValue;
    SetDirty([gtPosition]);
  end;
end;

procedure TGUIComponent.SetScrollRect(const Value : RRectFloat);
begin
  FScrollRect := Value;
  FScrollOffset := FScrollRect.ClampPoint(FScrollOffset);
end;

procedure TGUIComponent.SetShow(const Value : EnumNullableBoolean);
begin
  if (FShow <> Value) and (Value <> nbUnset) then
  begin
    ResetCurrentAnimationKey;
    SetCompleteDirty;
    SetStyleSheetStackDirtyRecursive;
  end;
  FShow := Value;
end;

procedure TGUIComponent.SetStyleSheetStackDirty;
begin
  // RHWLinePool.AddRect(FRect.Round, RColor.CRED);
  FStyleSheetStackDirty := True;
  FClassHierarchyDirty := True;
  SetDirty([gtDirty]);
end;

procedure TGUIComponent.SetStyleSheetStackDirtyRecursive;
var
  i : integer;
begin
  if not FStyleSheetStackDirty or not FClassHierarchyDirty then
  begin
    SetStyleSheetStackDirty;
    for i := 0 to ChildCount - 1 do
        Children[i].SetStyleSheetStackDirtyRecursive;
  end;
end;

constructor TGUIComponent.Create(Owner : TGUI; Style : TGUIStyleSheet; const Name : string; Parent : TGUIComponent);
begin
  Create(Owner);
  FName := name;
  FParent := Parent;
  if HasParent then Parent.AddChild(self);
  if assigned(Style) then
  begin
    FStyleSheet.Free;
    FStyleSheet := Style;
  end;
  FGUI.AddComponent(self);
end;

constructor TGUIComponent.Create(Owner : TGUI);
begin
  Create();
  FGUI := Owner;
end;

class function TGUIComponent.CreateFromFile(const Filename : string; Owner : TGUI; Parent : TGUIComponent; FailSilently : boolean) : TGUIComponent;
var
  XMLSerializer : TXMLSerializer;
begin
  XMLSerializer := TXMLSerializer.Create;
  Result := XMLSerializer.CreateAndLoadObjectFromFile(AbsolutePath(Filename), [Owner], FailSilently) as TGUIComponent;
  if assigned(Result) then
  begin
    Result.Parent := Parent;
    if Result.HasParent then Result.Parent.AddChild(Result);
  end;
  XMLSerializer.Free;
end;

procedure TGUIComponent.ComputeAnimationKey;
var
  Progress, IndexNormal, IndexReverse : single;
  Iteration, AnimationDuration : integer;
begin
  if (assigned(FAnimationStack) or (FBgSheetCount > 1)) and ((FAnimationDuration > 0) or (FBgSheetCount > 1)) then
  begin
    if FAnimationDuration = 0 then AnimationDuration := Round((1000 / 30) * FBgSheetCount)
    else AnimationDuration := FAnimationDuration;
    AnimationDuration := FAnimationDelay + AnimationDuration + FAnimationDelayAfter;
    if AnimationDuration > 0 then
    begin
      Iteration := Max(0, (TimeManager.GetTimeStamp - FAnimationStartTimestamp - FAnimationOffset));
      Progress := Iteration / AnimationDuration;
      Progress := Frac(Progress);
      Progress := Progress - (FAnimationDelay / AnimationDuration);
      Progress := Progress / ((AnimationDuration - FAnimationDelay - FAnimationDelayAfter) / AnimationDuration);
      Progress := Max(0, Min(1, Progress));
      Iteration := Iteration div AnimationDuration;
    end
    else
    begin
      Progress := 0;
      Iteration := FAnimationIterationCount;
    end;
    if (Iteration >= FAnimationIterationCount) and (FAnimationIterationCount > 0) then
    begin
      IndexNormal := 1.0;
      IndexReverse := 0.0;
      FAnimationFinished := True;
      case FAnimationFillMode of
        afNone, afForwards : IndexReverse := IndexNormal;
        afBackwards : IndexNormal := IndexReverse;
        afBoth :;
      else
        raise ENotImplemented.Create('ResolveBackgroundSpriteSheetCoordinates: Fillmode not implemented.');
      end;
    end
    else
    begin
      FAnimationFinished := False;
      IndexNormal := Progress;
      IndexReverse := 1.0 - Progress;
    end;
    case FAnimationDirection of
      adNormal : FCachedCurrentAnimationKey := IndexNormal;
      adReverse : FCachedCurrentAnimationKey := IndexReverse;
      adAlternate : if Iteration mod 2 = 0 then FCachedCurrentAnimationKey := IndexNormal
        else FCachedCurrentAnimationKey := IndexReverse;
      adAlternateReverse : if Iteration mod 2 = 0 then FCachedCurrentAnimationKey := IndexReverse
        else FCachedCurrentAnimationKey := IndexNormal;
    else
      raise ENotImplemented.Create('ResolveBackgroundSpriteSheetCoordinates: AnimationDirection not implemented.');
    end;
    FCachedCurrentAnimationKey := FAnimationTimingFunction.Solve(FCachedCurrentAnimationKey);
  end
  else
  begin
    ResetCurrentAnimationKey;
    FAnimationFinished := True;
  end;
end;

function TGUIComponent.CustomDataAs<T> : T;
begin
  Result := TObject(CustomData) as T;
end;

function TGUIComponent.CustomDataAsWrapper<T> : T;
begin
  Result := (TObject(CustomData) as TObjectWrapper<T>).Value;
end;

function TGUIComponent.CustomDataForceAs<T> : T;
begin
  Result := T(CustomData);
end;

constructor TGUIComponent.CustomXMLCreate(Node : TXMLNode; CustomData : array of TObject);
begin
  inherited;
  assert(length(CustomData) >= 1);
  Create(CustomData[0] as TGUI);
end;

function TGUIComponent.DefaultElementName : string;
begin
  Result := 'div';
end;

procedure TGUIComponent.Delete;
begin
  if HasParent then Parent.RemoveChild(self);
  Free;
end;

procedure TGUIComponent.DeleteChild(Index : integer);
var
  temp : TGUIComponent;
begin
  temp := GetChild(index);
  if assigned(temp) then temp.Delete;
  ChildrenChanged;
end;

function TGUIComponent.Depth : integer;
begin
  if FDepthOverride >= 0 then exit(FDepthOverride);
  if HasParent then Result := Parent.Depth + 1
  else Result := 0;
end;

destructor TGUIComponent.Destroy;
var
  i : integer;
begin
  UnBindXML;
  if HasParent then Parent.RemoveChild(self);
  if OwnsCustomData then TObject(CustomData).Free;
  FGUI.RemoveComponent(self);
  FFont.Free;
  FBlurQuad.Free;
  FBlurMask.Free;
  FBgTexture.Default.Free;
  FBgTexture.Hover.Free;
  FBgTexture.Down.Free;
  FBgTexture.Disabled.Free;
  FBackgroundMask.Free;
  FTransitionValueBackgroundColor.Free;
  FTransitionValueOpacity.Free;
  FTransitionValueTransform.Free;
  FScrollbarBackgroundQuad.Free;
  FScrollbarTrackerQuad.Free;
  FQuad.Free;
  for i := 0 to length(FBorderImage) - 1 do
      FBorderImage[i].Free;
  FreeAndNil(FStyleSheetStack);
  FreeAndNil(FAnimationStack);
  FreeAndNil(FClassHierarchy);
  FStyleSheet.Free;
  FChildren.Free;
  FClasses.Free;
  inherited;
end;

function TGUIComponent.Find(const Name : string) : TGUIComponent;
begin
  if self = nil then exit(nil);
  Result := GetDescendantComponentByName(name);
end;

function TGUIComponent.Find(const Name : string; out Element : TGUIComponent) : boolean;
begin
  if self = nil then exit(False);
  Result := TryGetDescendantComponentByName(name, Element);
end;

function TGUIComponent.FindMulti(const Name : string) : IGUIComponentSet;
var
  ComponentSet : TGUIComponentSet;
begin
  ComponentSet := TGUIComponentSet.Create;
  BuildFindMultiSet(ComponentSet, name);
  Result := ComponentSet;
end;

function TGUIComponent.FindAs<T>(const Name : string) : T;
begin
  Result := GetDescendantElementByName<T>(name);
end;

function TGUIComponent.FindAs<T>(const Name : string; out Element : T) : boolean;
begin
  Result := TryGetDescendantElementByName<T>(name, Element);
end;

function TGUIComponent.FindContainingComponent(const Point : RVector2) : TGUIComponent;
var
  i, CurrentZ, MyZ, ChildZ : integer;
  HighestChild : TGUIComponent;
begin
  Result := nil;
  if not Visible then exit;
  MyZ := ZOffset;
  CurrentZ := MyZ;
  for i := 0 to ChildCount - 1 do
  begin
    HighestChild := Children[i].FindContainingComponent(Point);
    if assigned(HighestChild) then
    begin
      ChildZ := HighestChild.ZOffset;
      if (ChildZ >= CurrentZ) then
      begin
        CurrentZ := ChildZ;
        Result := HighestChild;
      end;
    end
    else
  end;
  if PointInComponent(Point) and (Result = nil) then Result := self;
end;

procedure TGUIComponent.ComputeBackgroundTextures;
begin
  if FDirty * [gtBackgroundMask, gtBackgroundMipMapping] <> [] then LoadTexture(gtBackgroundMask, @FBackgroundMask);
  if gtBackgroundMipMapping in FDirty then
      FMipMapHandling := GetStyleValue<EnumMipMapHandling>(gtBackgroundMipMapping);
  // background can have influence to size, so compute before
  if gtBackgroundColor in FDirty then
  begin
    FBgColor[0].Default := GetStyleValue<RColor>(gtBackgroundColor, 0);
    if not TryGetStyleValue<RColor>(gtBackgroundColor, FBgColor[1].Default, 1) then
    begin
      // shortcut one color = plain color
      FBgColor[1].Default := FBgColor[0].Default;
      FBgColor[2].Default := FBgColor[0].Default;
      FBgColor[3].Default := FBgColor[0].Default;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColor, FBgColor[2].Default, 2) then
    begin
      // shortcut two colors = vertical gradient
      FBgColor[2].Default := FBgColor[1].Default;
      FBgColor[3].Default := FBgColor[1].Default;
      FBgColor[1].Default := FBgColor[0].Default;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColor, FBgColor[3].Default, 3) then
    begin
      // shortcut three colors = horizontal gradient
      FBgColor[2].Default := FBgColor[1].Default;
      FBgColor[3].Default := FBgColor[0].Default;
    end
  end;
  if gtBackgroundColorOverride in FDirty then
      FBackgroundColorOverride := GetStyleValue<RColor>(gtBackgroundColorOverride);
  if gtBackgroundColorOverrideInheritance in FDirty then
      FBackgroundColorOverrideInheritance := GetStyleValue<boolean>(gtBackgroundColorOverrideInheritance);
  if FDirty * [gtBackground, gtBackgroundMipMapping] <> [] then LoadTexture(gtBackground, @FBgTexture.Default);
  if gtBackgroundColorHover in FDirty then
  begin
    FBgColor[0].Hover := GetStyleValue<RColor>(gtBackgroundColorHover, 0);
    if not TryGetStyleValue<RColor>(gtBackgroundColorHover, FBgColor[1].Hover, 1) then
    begin
      // shortcut one color = plain color
      FBgColor[1].Hover := FBgColor[0].Hover;
      FBgColor[2].Hover := FBgColor[0].Hover;
      FBgColor[3].Hover := FBgColor[0].Hover;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColorHover, FBgColor[2].Hover, 2) then
    begin
      // shortcut two colors = vertical gradient
      FBgColor[2].Hover := FBgColor[1].Hover;
      FBgColor[3].Hover := FBgColor[1].Hover;
      FBgColor[1].Hover := FBgColor[0].Hover;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColorHover, FBgColor[3].Hover, 3) then
    begin
      // shortcut three colors = horizontal gradient
      FBgColor[2].Hover := FBgColor[1].Hover;
      FBgColor[3].Hover := FBgColor[0].Hover;
    end
  end;
  if FDirty * [gtBackgroundHover, gtBackgroundMipMapping] <> [] then LoadTexture(gtBackgroundHover, @FBgTexture.Hover);
  if gtBackgroundColorDown in FDirty then
  begin
    FBgColor[0].Down := GetStyleValue<RColor>(gtBackgroundColorDown, 0);
    if not TryGetStyleValue<RColor>(gtBackgroundColorDown, FBgColor[1].Down, 1) then
    begin
      // shortcut one color = plain color
      FBgColor[1].Down := FBgColor[0].Down;
      FBgColor[2].Down := FBgColor[0].Down;
      FBgColor[3].Down := FBgColor[0].Down;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColorDown, FBgColor[2].Down, 2) then
    begin
      // shortcut two colors = vertical gradient
      FBgColor[2].Down := FBgColor[1].Down;
      FBgColor[3].Down := FBgColor[1].Down;
      FBgColor[1].Down := FBgColor[0].Down;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColorDown, FBgColor[3].Down, 3) then
    begin
      // shortcut three colors = horizontal gradient
      FBgColor[2].Down := FBgColor[1].Down;
      FBgColor[3].Down := FBgColor[0].Down;
    end
  end;
  if FDirty * [gtBackgroundDown, gtBackgroundMipMapping] <> [] then LoadTexture(gtBackgroundDown, @FBgTexture.Down);
  if gtBackgroundColorDisabled in FDirty then
  begin
    FBgColor[0].Disabled := GetStyleValue<RColor>(gtBackgroundColorDisabled, 0);
    if not TryGetStyleValue<RColor>(gtBackgroundColorDisabled, FBgColor[1].Disabled, 1) then
    begin
      // shortcut one color = plain color
      FBgColor[1].Disabled := FBgColor[0].Disabled;
      FBgColor[2].Disabled := FBgColor[0].Disabled;
      FBgColor[3].Disabled := FBgColor[0].Disabled;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColorDisabled, FBgColor[2].Disabled, 2) then
    begin
      // shortcut two colors = vertical gradient
      FBgColor[2].Disabled := FBgColor[1].Disabled;
      FBgColor[3].Disabled := FBgColor[1].Disabled;
      FBgColor[1].Disabled := FBgColor[0].Disabled;
    end
    else if not TryGetStyleValue<RColor>(gtBackgroundColorDisabled, FBgColor[3].Disabled, 3) then
    begin
      // shortcut three colors = horizontal gradient
      FBgColor[2].Disabled := FBgColor[1].Disabled;
      FBgColor[3].Disabled := FBgColor[0].Disabled;
    end
  end;
  if FDirty * [gtBackgroundDisabled, gtBackgroundMipMapping] <> [] then LoadTexture(gtBackgroundDisabled, @FBgTexture.Disabled);
end;

procedure TGUIComponent.ComputeAnimation;
begin
  if gtAnimationDelay in FDirty then
  begin
    FAnimationDelay := GetStyleValue<integer>(gtAnimationDelay);
    FAnimationDelayAfter := GetStyleValue<integer>(gtAnimationDelay, 1);
  end;
  if gtAnimationOffset in FDirty then
      FAnimationOffset := GetStyleValue<integer>(gtAnimationOffset);
  if gtAnimationDuration in FDirty then
      FAnimationDuration := GetStyleValue<integer>(gtAnimationDuration);
  if gtAnimationIterationCount in FDirty then
      FAnimationIterationCount := GetStyleValue<integer>(gtAnimationIterationCount);
  if gtAnimationDirection in FDirty then
      FAnimationDirection := GetStyleValue<EnumAnimationDirection>(gtAnimationDirection);
  if gtAnimationFillMode in FDirty then
      FAnimationFillMode := GetStyleValue<EnumAnimationFillMode>(gtAnimationFillMode);
  if gtAnimationName in FDirty then
  begin
    FAnimationName := GetStyleValue<string>(gtAnimationName);
    FAnimationStack.Free;
    FAnimationStack := FGUI.StyleManager.GetAnimationStack(FAnimationName);
  end;
  if gtAnimationTimingFunction in FDirty then
      FAnimationTimingFunction := RCubicBezier.Create(
      GetStyleValue<single>(gtAnimationTimingFunction, 0),
      GetStyleValue<single>(gtAnimationTimingFunction, 1),
      GetStyleValue<single>(gtAnimationTimingFunction, 2),
      GetStyleValue<single>(gtAnimationTimingFunction, 3));
end;

procedure TGUIComponent.ComputeBackgroundAnimation;
begin
  if gtAnimationBackgroundSpriteSize in FDirty then
      FBgSheetSize := RIntVector2.Create(GetStyleValue<integer>(gtAnimationBackgroundSpriteSize, 0), GetStyleValue<integer>(gtAnimationBackgroundSpriteSize, 1));
  if gtAnimationBackgroundSpriteCount in FDirty then
      FBgSheetCount := GetStyleValue<integer>(gtAnimationBackgroundSpriteCount);
end;

procedure TGUIComponent.ComputeBackgroundQuad;
var
  ScreenQuad : TVertexScreenAlignedQuad;
  WorldQuad, ParentQuad : TVertexWorldspaceQuad;
  ParentQuadLT, ParentQuadSize : RVector3;
  i : integer;
  SpaceData : RGSSSpaceData;
  needNewQuad : boolean;
  Anchor : EnumComponentAnchor;
begin
  assert(FDrawSpace <> dsViewSpace, ' TGUIComponent.ApplyStyle: ComputeBackgroundQuad: ViewSpace currently not supported!');

  // ---- Check whether a new quad has to be created -----------------------------------------------------------------------
  // build Quad if not assigned or drawspace has changed so another quad is needed
  needNewQuad := not assigned(FQuad);
  needNewQuad := needNewQuad or ((gtDrawSpace in FDirty) and
    ((FDrawSpace in [dsScreenSpace, dsWorldScreenSpace]) and not(FQuad is TVertexScreenAlignedQuad)) or
    ((FDrawSpace = dsWorldSpace) and not(FQuad is TVertexWorldspaceQuad))
    );
  // only build quad if quad is needed to show color or texture
  needNewQuad := needNewQuad and (FBgColor[0].IsAnySet or FBgTexture.IsAnySet or (FSceneName <> '') or (abs(FBorderOuter) + abs(FBorderInner) > 0) or (abs(FOutlineOuter) + abs(FOutlineInner) > 0));
  if needNewQuad then
  begin
    FQuad.Free;
    if FDrawSpace in [dsScreenSpace, dsWorldScreenSpace] then
    begin
      // adjust ZOffset for Text rendered after background
      ScreenQuad := TVertexScreenAlignedQuad.Create(VertexEngine);
      ScreenQuad.DrawOrder := ZOffset * 2;
      FQuad := ScreenQuad;
    end
    else
    begin
      WorldQuad := TVertexWorldspaceQuad.Create(VertexEngine);
      FQuad := WorldQuad;
      FQuad.DrawOrder := Depth;
    end;
    FQuad.DrawsAtStage := rsGUI;
  end;

  // ---- update existing quad ---------------------------------------------------------------------------------------------
  if FQuad <> nil then
  begin
    if gtBackgroundMipMapLodBias in FDirty then FQuad.MipMapLodBias := GetStyleValue<single>(gtBackgroundMipMapLodBias);

    if FDrawSpace in [dsScreenSpace, dsWorldScreenSpace] then
    begin
      if gtZOffset in FDirty then FQuad.DrawOrder := ZOffset * 2;
    end;
    if FDrawSpace = dsWorldSpace then
    begin
      WorldQuad := (FQuad as TVertexWorldspaceQuad);

      if [gtSize, gtBackground] * FDirty <> [] then
      begin
        SpaceData := GetStyleValue<RGSSSpaceData>(gtSize, 0);
        if SpaceData.IsRelative then
        begin
          if HasParent then WorldQuad.Width := Parent.FQuad.Width * SpaceData.Value;
        end
        else WorldQuad.Width := SpaceData.Value;

        SpaceData := GetStyleValue<RGSSSpaceData>(gtSize, 1);
        if SpaceData.IsRelative then
        begin
          if HasParent then WorldQuad.Height := Parent.FQuad.Height * SpaceData.Value;
        end
        else WorldQuad.Height := SpaceData.Value;
      end;

      if ([gtPosition, gtAnchor, gtParentAnchor, gtSize, gtMinSize, gtMaxSize, gtBackground] * FDirty <> []) then
      begin
        if HasParent and (Parent.FQuad is TVertexWorldspaceQuad) then
        begin
          ParentQuad := TVertexWorldspaceQuad(Parent.FQuad);
          ParentQuadLT := ParentQuad.Position - (ParentQuad.Left * ParentQuad.Width / 2) - (ParentQuad.Up * ParentQuad.Height / 2);
          ParentQuadSize := RVector3.Create(ParentQuad.Width, ParentQuad.Height, 0);
        end
        else ParentQuad := nil;

        for i := 0 to 2 do
        begin
          SpaceData := GetStyleValue<RGSSSpaceData>(gtPosition, i);
          if SpaceData.IsRelative and assigned(ParentQuad) then
              WorldQuad.Position.Element[i] := ParentQuadLT.Element[i] + (SpaceData.Value * ParentQuad.Left.Element[i] * ParentQuadSize.Element[i])
          else if SpaceData.IsAbsolute then
          begin
            if assigned(ParentQuad) then WorldQuad.Position.Element[i] := ParentQuadLT.Element[i] + SpaceData.Value
            else WorldQuad.Position.Element[i] := SpaceData.Value;
          end
          else if SpaceData.IsInherit then WorldQuad.Position.Element[i] := ParentQuad.Position.Element[i];
        end;

        Anchor := GetStyleValue<EnumComponentAnchor>(gtAnchor);
        if ord(Anchor) div 3 = 0 then WorldQuad.Position := WorldQuad.Position + WorldQuad.Height / 2 * WorldQuad.Up
        else if ord(Anchor) div 3 = 2 then WorldQuad.Position := WorldQuad.Position - WorldQuad.Height / 2 * WorldQuad.Up;
        if ord(Anchor) mod 3 = 0 then WorldQuad.Position := WorldQuad.Position + WorldQuad.Width / 2 * WorldQuad.Left
        else if ord(Anchor) mod 3 = 2 then WorldQuad.Position := WorldQuad.Position - WorldQuad.Width / 2 * WorldQuad.Left;
      end;
      WorldQuad.Color := $FFFFFFFF;
    end;
  end;

  if gtBackgroundAnchor in FDirty then
  begin
    FCoordinateRect := RRectFloat.Create(0, 0, 1, 1);
    FBackgroundAnchor := GetStyleValue<EnumBackgroundAnchor>(gtBackgroundAnchor);
    case FBackgroundAnchor of
      baTopLeft :;
      baTopRight : FCoordinateRect := RRectFloat.Create(1, 0, 0, 1);
      baBottomRight : FCoordinateRect := RRectFloat.Create(1, 1, 0, 0);
      baBottomLeft : FCoordinateRect := RRectFloat.Create(0, 1, 1, 0);
    end;
  end;

  if gtBackgroundrepeat in FDirty then
  begin
    FBackgroundRepeatX := GetStyleValue<EnumBackgroundRepeat>(gtBackgroundrepeat);
    FBackgroundRepeatY := GetStyleValue<EnumBackgroundRepeat>(gtBackgroundrepeat, 1);
    // double auto won't work
    if (FBackgroundRepeatX = brAuto) and (FBackgroundRepeatY = brAuto) then FBackgroundRepeatX := brStretch;
  end;

  if ([gtBackgroundrepeat, gtBackgroundAnchor, gtSize, gtMinSize, gtMaxSize, gtPosition, gtBackground] * FDirty <> []) and (FQuad <> nil) then
  begin
    if FQuad is TVertexScreenAlignedQuad then
    begin
      TVertexScreenAlignedQuad(FQuad).Rect := BackgroundRect;
    end;

    if assigned(FBgTexture.Default) then
    begin
      if FDrawSpace = dsScreenSpace then
      begin
        if FBackgroundRepeatX = brNone then FQuad.Width := FBgTexture.Default.Width;
        if FBackgroundRepeatY = brNone then FQuad.Height := FBgTexture.Default.Height;
        if HasParent and (FBackgroundRepeatX = brMask) then
            FCoordinateRect.LeftWidth := ParentRect.LocalRect(FRect).LeftWidth;
        if HasParent and (FBackgroundRepeatY = brMask) then
            FCoordinateRect.TopHeight := ParentRect.LocalRect(FRect).TopHeight;
        if FBackgroundRepeatX = brRepeat then
        begin
          if sign(FCoordinateRect.Width) >= 0 then
              FCoordinateRect.Width := BackgroundRect.Width / FBgTexture.Default.Width
          else
          begin
            if FAnchor in [caTopRight, caRight, caBottomRight] then
                FCoordinateRect.Left := FCoordinateRect.Right + BackgroundRect.Width / FBgTexture.Default.Width
            else
                FCoordinateRect.Right := FCoordinateRect.Left - BackgroundRect.Width / FBgTexture.Default.Width;
          end;
        end;
        if FBackgroundRepeatY = brRepeat then FCoordinateRect.Height := BackgroundRect.Height / FBgTexture.Default.Height * sign(FCoordinateRect.Height);
        if FBackgroundRepeatX = brAuto then
        begin
          FQuad.Width := FQuad.Height * FBgTexture.Default.AspectRatio;
          if FBgSheetSize > 1 then
              FQuad.Width := FQuad.Width / (FBgSheetSize.X / FBgSheetSize.Y);
        end;
        if FBackgroundRepeatY = brAuto then
        begin
          FQuad.Height := FQuad.Width / FBgTexture.Default.AspectRatio;
          if FBgSheetSize > 1 then
              FQuad.Height := FQuad.Height * (FBgSheetSize.X / FBgSheetSize.Y);
        end;
        if (FBackgroundRepeatX = brRepeat) or (FBackgroundRepeatY = brRepeat) then FQuad.AddressMode := amWrap
        else FQuad.AddressMode := amClamp;
      end
      else
      begin
        WorldQuad := (FQuad as TVertexWorldspaceQuad);
        FCoordinateRect := RRectFloat.Create(0, 0, (WorldQuad.Width / WorldQuad.Height) / (FBgTexture.Default.Width / FBgTexture.Default.Height), 1)
      end;
    end;
  end;
end;

procedure TGUIComponent.ComputeBorderAndOutline;
var
  BorderLocation, OutlineLocation : EnumBorderLocation;
begin
  // border
  if (FDirty * [gtSize, gtBorder] <> []) then
  begin
    FBorderOuter := GetStyleValue<RGSSSpaceData>(gtBorder, 0).Resolve(0, ContentRect, ParentRect);
    FBorderInner := FBorderOuter;
    FBorderColorStart := GetStyleValue<RColor>(gtBorder, 1);
    if not TryGetStyleValue<RColor>(gtBorder, FBorderColorEnd, 2) then FBorderColorEnd := FBorderColorStart;
    BorderLocation := GetStyleValue<EnumBorderLocation>(gtBorder, 3);
    case BorderLocation of
      blOutline : FBorderInner := 0;
      blMiddle :
        begin
          FBorderInner := FBorderInner * 0.5;
          FBorderOuter := FBorderOuter * 0.5;
        end;
      blInset :
        begin
          FBorderOuter := 0;
          HGeneric.Swap<RColor>(FBorderColorStart, FBorderColorEnd);
        end;
    end;
  end;
  if (gtBorderSides in FDirty) then FBorderSides := GetStyleValue<SetBorderSides>(gtBorderSides);
  // outline
  if (FDirty * [gtSize, gtOutline] <> []) then
  begin
    FOutlineOuter := GetStyleValue<RGSSSpaceData>(gtOutline, 0).Resolve(0, ContentRect, ParentRect);
    FOutlineInner := FOutlineOuter;
    FOutlineColorStart := GetStyleValue<RColor>(gtOutline, 1);
    if not TryGetStyleValue<RColor>(gtOutline, FOutlineColorEnd, 2) then FOutlineColorEnd := FOutlineColorStart;
    OutlineLocation := GetStyleValue<EnumBorderLocation>(gtOutline, 3);
    case OutlineLocation of
      blOutline : FOutlineInner := 0;
      blMiddle :
        begin
          FOutlineInner := FOutlineInner * 0.5;
          FOutlineOuter := FOutlineOuter * 0.5;
        end;
      blInset :
        begin
          FOutlineOuter := 0;
          HGeneric.Swap<RColor>(FOutlineColorStart, FOutlineColorEnd);
        end;
    end;
  end;
  if (gtOutlineSides in FDirty) then FOutlineSides := GetStyleValue<SetBorderSides>(gtOutlineSides);
end;

procedure TGUIComponent.ComputeBorderImage;
const
  INDEX_MAPPING : array [0 .. 7] of integer = (1, 2, 3, 6, 9, 8, 7, 4);
var
  imageFilename, ext, temp : string;
  i : integer;
begin
  if (gtBorderImage in FDirty) then
  begin
    for i := 0 to length(FBorderImage) - 1 do
        FreeAndNil(FBorderImage[i]);
    imageFilename := GetStyleValue<string>(gtBorderImage, 0);
    if imageFilename <> '' then
    begin
      ext := ExtractFileExt(imageFilename);
      for i := 0 to length(FBorderImage) - 1 do
      begin
        FBorderImage[i] := TVertexScreenAlignedQuad.Create(VertexEngine);
        FBorderImage[i].OwnsTexture := True;
        temp := ChangeFileExt(imageFilename, '_0' + Inttostr(INDEX_MAPPING[i]) + ext);
        FBorderImage[i].Texture := TTexture.CreateTextureFromFile(AbsolutePath(FGUI.AssetPath + '\' + temp), GFXD.Device3D, mhSkip, False, True);
        FBorderImage[i].DrawOrder := ZOffset * 2;
        FBorderImage[i].DrawsAtStage := rsGUI;
      end;
      for i := 0 to 3 do
          FBorderImageOffset.Element[i] := GetStyleValue<integer>(gtBorderImage, i + 1);
    end;
  end;
end;

procedure TGUIComponent.ComputeMargin;
var
  i : integer;
  SpaceData : RGSSSpaceData;
begin
  FMargin := RIntVector4.Create(0);
  for i := 0 to 3 do
    if TryGetStyleValue<RGSSSpaceData>(gtMargin, SpaceData, i) then
        FMargin.Element[i] := Round(SpaceData.Resolve((i + 1) mod 2, FRect, ParentRect));
end;

procedure TGUIComponent.ComputePadding;
var
  i : integer;
  SpaceData : RGSSSpaceData;
begin
  FPadding := RIntVector4.Create(0);
  for i := 0 to 3 do
    if TryGetStyleValue<RGSSSpaceData>(gtPadding, SpaceData, i) then
        FPadding.Element[i] := Round(SpaceData.Resolve((i + 1) mod 2, FRect, ParentRect));
end;

function TGUIComponent.ResolvePosition(const SpaceData : RGSSSpaceData; Dim : integer) : single;
begin
  if SpaceData.IsRelativeContext then
      Result := ParentRect.Dim[Dim] * SpaceData.Value
  else
      Result := SpaceData.Resolve(Dim, FRect, ParentRect);
end;

procedure TGUIComponent.ComputePosition;
  function ResolveAnchor(const Source : EnumGSSTag; out Offset : RVector2) : EnumComponentAnchor;
  const
    BORDER_PADDING = 5;
  var
    CurrentAnchor : EnumComponentAnchor;
    Anchorlist : TArray<EnumComponentAnchor>;
    AnchorOffset : RVector2;
    i, ValueCount, BestIndex : integer;
    CurrentSpace, BestSpace : single;
    SourceRect, tempRect : RRectFloat;
  begin
    Offset := RVector2.ZERO;
    Result := GetStyleValue<EnumComponentAnchor>(Source);
    if Result = caAuto then
    begin
      // skip first as it is auto
      ValueCount := StyleValueCount(Source) - 1;
      // fetch all anchors in auto list
      setLength(Anchorlist, ValueCount);
      for i := 0 to ValueCount - 1 do
          Anchorlist[i] := GetStyleValue<EnumComponentAnchor>(Source, i + 1);

      // if no order is present, use optimal direction to open
      if ValueCount = 0 then
          Anchorlist := [caTopLeft, caTop, caTopRight, caRight, caBottomRight, caBottom, caBottomLeft, caLeft];

      if not HasParent then
          exit(Anchorlist[0]);
      SourceRect := ParentRect;

      // now choose optimal option, by comparing testing all options to be not clipped
      BestIndex := -1;
      BestSpace := -10000;
      for i := 0 to length(Anchorlist) - 1 do
      begin
        CurrentAnchor := Anchorlist[i];
        // Offset by current anchor from the center of the parent
        AnchorOffset := AnchorToVector(InverseAnchor(CurrentAnchor)) * RVector2.Create(SourceRect.Width / 2, SourceRect.Height / 2);
        // Offset by current anchor for the current element
        tempRect := FRect;
        tempRect.Center := SourceRect.Center + AnchorOffset;
        tempRect := tempRect.Translate((-AnchorToVector(CurrentAnchor)) * (FRect.Size / 2));
        CurrentSpace := Min(0, tempRect.Left);
        CurrentSpace := CurrentSpace + Min(0, tempRect.Top);
        CurrentSpace := CurrentSpace + Min(0, (FGUI.Scene.Size.X - tempRect.Right));
        CurrentSpace := CurrentSpace + Min(0, (FGUI.Scene.Size.Y - tempRect.Bottom));
        if CurrentSpace > BestSpace then
        begin
          BestIndex := i;
          BestSpace := CurrentSpace;
        end;
      end;
      // if all places would introduce clipping, take the first
      if BestIndex < 0 then
          BestIndex := 0;

      assert(InRange(BestIndex, 0, length(Anchorlist) - 1));
      Result := Anchorlist[BestIndex];

      // prevent clipping of client border
      // Offset by current anchor from the center of the parent
      AnchorOffset := AnchorToVector(Result) * RVector2.Create(SourceRect.Width / 2, SourceRect.Height / 2);
      // Offset by current anchor for the current element
      tempRect := FRect;
      tempRect.Center := SourceRect.Center + AnchorOffset;
      tempRect := tempRect.Translate((-AnchorToVector(Result)) * (FRect.Size / 2));
      if tempRect.Top < BORDER_PADDING then
          Offset.Y := -tempRect.Top + BORDER_PADDING
      else if tempRect.Bottom > FGUI.Scene.Size.Y - BORDER_PADDING
      then
          Offset.Y := -(tempRect.Bottom - FGUI.Scene.Size.Y) - BORDER_PADDING;
      if tempRect.Left < BORDER_PADDING then
          Offset.X := -tempRect.Left + BORDER_PADDING
      else if tempRect.Right > FGUI.Scene.Size.X - BORDER_PADDING then
          Offset.X := -(tempRect.Right - FGUI.Scene.Size.X) - BORDER_PADDING;

      if Source = gtParentAnchor then
          Result := InverseAnchor(Result);
    end;
  end;

var
  ParentAnchor : EnumComponentAnchor;
  SpaceDataX, SpaceDataY : RGSSSpaceData;
  RelativePosition, ParentPosition, AutoAnchorOffset : RVector2;
  ParentRect : RRectFloat;
begin
  if ([gtPosition, gtSize, gtAnchor, gtParentAnchor, gtParentOffset] * FDirty <> []) then
  begin
    if gtParentBox in FDirty then FParentBox := GetStyleValue<EnumParentBox>(gtParentBox);
    RelativePosition := RVector2.ZERO;
    if (FDrawSpace = dsScreenSpace) then
    begin
      // X - Axis
      SpaceDataX := GetStyleValue<RGSSSpaceData>(gtPosition, 0);
      RelativePosition.X := ResolvePosition(SpaceDataX, 0);

      // Y - Axis
      SpaceDataY := GetStyleValue<RGSSSpaceData>(gtPosition, 1);
      RelativePosition.Y := ResolvePosition(SpaceDataY, 1);

      // compute parent anchor
      if HasParent and (not SpaceDataX.IsInherit or not SpaceDataY.IsInherit) then
      begin
        ParentRect := self.ParentRect;
        ParentPosition := ParentRect.Position;
        ParentAnchor := ResolveAnchor(gtParentAnchor, AutoAnchorOffset);
        // Vertical-Center
        if ord(ParentAnchor) div 3 = 1 then ParentPosition.Y := ParentPosition.Y + ParentRect.Height / 2
          // Bottom
        else if ord(ParentAnchor) div 3 = 2 then ParentPosition.Y := ParentPosition.Y + ParentRect.Height;

        // Horizontal-Center
        if ord(ParentAnchor) mod 3 = 1 then ParentPosition.X := ParentPosition.X + ParentRect.Width / 2
          // Right
        else if ord(ParentAnchor) mod 3 = 2 then ParentPosition.X := ParentPosition.X + ParentRect.Width;

        // offset Parent-Position by the scrolling factor
        ParentPosition := ParentPosition + VirtualParent.ScrollOffset;
      end
      else ParentPosition := RVector2.ZERO;

      // move local to screen
      if not SpaceDataX.IsInherit then FRect.X := ParentPosition.X + RelativePosition.X;
      if not SpaceDataY.IsInherit then FRect.Y := ParentPosition.Y + RelativePosition.Y;
    end
    else if (FDrawSpace = dsWorldScreenSpace) then
    begin
      // project world space position to screen space
      FRect.Position := FGUI.Scene.Camera.WorldSpaceToScreenSpace(Position3D).XY.Round;
    end
    else FRect.LeftTop := RVector2.ZERO;

    // Apply Anchor to final rect
    if (FDrawSpace in [dsScreenSpace, dsWorldScreenSpace]) then
    begin
      AutoAnchorOffset := RVector2.ZERO;
      if gtAnchor in FDirty then
          FAnchor := ResolveAnchor(gtAnchor, AutoAnchorOffset);
      FRect := FRect.Translate(AutoAnchorOffset - RVector2.Create((ord(FAnchor) mod 3) * FRect.Width / 2, (ord(FAnchor) div 3) * FRect.Height / 2));
    end;
  end;
end;

function TGUIComponent.ExtractdXML : string;
var
  i : integer;
  nodeType : string;
begin
  Result := '<';
  // extract type
  nodeType := 'div';
  if self is TGUIStackPanel then nodeType := 'stack'
  else
    if self is TGUIEdit then nodeType := 'input'
  else
    if self is TGUICheckbox then nodeType := 'check'
  else
    if self is TGUIProgressBar then nodeType := 'progress'
  else
    if GetStyleValue<string>(gtBackground) <> '' then nodeType := 'img'
  else
      nodeType := 'div';

  Result := Result + nodeType + ' id="' + self.Name + '"';

  if nodeType = 'img' then Result := Result + ' src="' + GetStyleValue<string>(gtBackground) + '"';

  // extract classes
  if ClassesAsText <> '' then Result := Result + ' class="' + ClassesAsText + '"';

  if FStyleSheet.DataAsText <> '' then Result := Result + ' style="' + HString.Replace(FStyleSheet.DataAsText, [#10, #13, #9]) + '"';

  Result := Result + '>' + sLineBreak;

  if GetStyleValue<string>(gtText) <> '' then Result := Result + GetStyleValue<string>(gtText);

  for i := 0 to ChildCount - 1 do
  begin
    Result := Result + Children[i].ExtractdXML;
    if i <> ChildCount - 1 then Result := Result + sLineBreak;
  end;

  Result := Result + '</' + nodeType + '>';
end;

function TGUIComponent.ExtractGSS : string;
var
  Styles, ChildrenData : string;
  firstChild : boolean;
  i : integer;
begin
  Styles := '';
  if assigned(FStyleSheet) then Styles := FStyleSheet.DataAsText;
  if (ChildCount <= 0) and (Styles = '') then exit('');
  Result := '#' + name + '{' + sLineBreak;
  if (Styles <> '') then
  begin
    // remove trailing newline in styles
    Styles := HString.TrimAfter(sLineBreak, Styles);
    Styles := HString.Indent(Styles);
    Result := Result + Styles + sLineBreak;
    FStyleSheet.DataAsText := '';
  end;
  firstChild := True;
  for i := 0 to ChildCount - 1 do
  begin
    ChildrenData := Children[i].ExtractGSS;
    if ChildrenData = '' then continue;
    ChildrenData := HString.Indent(ChildrenData);
    if not firstChild then Result := Result + sLineBreak;
    Result := Result + ChildrenData;
    firstChild := False;
  end;
  if not firstChild then Result := Result + sLineBreak;
  Result := Result + '}';
end;

function TGUIComponent.GetBackgroundColorOverride : RColor;
begin
  CheckAndBuildAnimationStack;
  if assigned(FAnimationStack) and FAnimationStack.AnimationStack.HasTag(gtBackgroundColorOverride) then
      Result := FAnimationStack.AnimationStack.Interpolate(FCachedCurrentAnimationKey, gtBackgroundColorOverride).AsType<RColor>
  else
      Result := FBackgroundColorOverride;

  if HasParent and FBackgroundColorOverrideInheritance then
      Result := Result.Average(VirtualParent.BackgroundColorOverride);
end;

function TGUIComponent.GetChild(Index : integer) : TGUIComponent;
begin
  Result := nil;
  if (index >= 0) and (index < FChildren.Count) then Result := FChildren[index];
end;

function TGUIComponent.GetChildWithData(Data : TObject) : TGUIComponent;
begin
  Result := GetChildWithData(NativeUInt(Data));
end;

function TGUIComponent.GetChildWithData(Data : NativeUInt) : TGUIComponent;
begin
  Result := GetChild(IndexOfChildWithData(Data));
end;

function TGUIComponent.GetClassesAsText : string;
var
  i : integer;
begin
  Result := '';
  for i := 0 to FClasses.Count - 1 do
      Result := Result + FGUI.StyleManager.RemapClassname(FClasses[i]).Replace('.', '') + ' ';
  if Result <> '' then Result := Result.Substring(0, length(Result) - 1);
end;

procedure TGUIComponent.SetBackgroundImageSafe(const Value : string);
begin
  if self = nil then exit;
  self.ChangeStyle<string>(gtBackground, Value);
  self.ChangeStyle<string>(gtBackgroundHover, Value.Replace('.', '_Hover.'));
  self.ChangeStyle<string>(gtBackgroundDown, Value.Replace('.', '_Down.'));
  self.ChangeStyle<string>(gtBackgroundDisabled, Value.Replace('.', '_Disabled.'));
end;

procedure TGUIComponent.SetClassesAsText(const Value : string);
var
  rawClasses : TArray<string>;
  i : integer;
begin
  if ClassesAsText = Value.Trim then exit;
  FClasses.Clear;
  rawClasses := Value.Split([' ', sLineBreak], TStringSplitOptions.ExcludeEmpty);
  for i := 0 to length(rawClasses) - 1 do
      FClasses.Add(FGUI.StyleManager.ResolveClassname(GSS_CLASS_PREFIX + rawClasses[i]));
  FClassesAsText := GetClassesAsText;
  SetStyleSheetStackDirtyRecursive;
end;

function TGUIComponent.GetCurrentHint : string;
begin
  if not assigned(self) then exit('');
  Result := GetStyleValue<string>(gtHint);
end;

function TGUIComponent.GetCurrentText : string;
begin
  if not assigned(self) then exit('');
  if FText = '' then
      Result := FStyleText
  else
      Result := FText;
end;

function TGUIComponent.GetCurrentTextAsInteger : integer;
begin
  if not TryStrToInt(Text, Result) then Result := 0;
end;

function TGUIComponent.GetDescendantComponentByName(const Name : string) : TGUIComponent;
var
  i : integer;
begin
  Result := nil;
  if not assigned(self) then exit;
  if (length(FName) = length(name)) and (CompareText(FName, name) = 0) then Result := self
  else
  begin
    for i := 0 to FChildren.Count - 1 do
    begin
      Result := FChildren[i].GetDescendantComponentByName(name);
      if Result <> nil then break;
    end;
  end;
end;

function TGUIComponent.GetDescendantElementByName<T>(const Name : string) : T;
begin
  Result := T(GetDescendantComponentByName(name));
end;

function TGUIComponent.GetDown : boolean;
begin
  Result := FDown in [obStyleTrue, obForceTrue];
end;

function TGUIComponent.GetEnabled : boolean;
begin
  Result := FEnabled in [obStyleTrue, obForceTrue];
end;

function TGUIComponent.GetScreenPos : RVector2;
begin
  Result := RVector2(0.5);
  if assigned(FQuad) then
  begin
    assert(FQuad is TVertexScreenAlignedQuad, 'TGUIComponent.ScreenPos: Not implemented for Worldspace!');
    Result := TVertexScreenAlignedQuad(FQuad).Position / FGUI.Scene.Size;
  end;
end;

function TGUIComponent.GetScreenSize : RVector2;
begin
  Result := RVector2(0.5);
  if assigned(FQuad) then
  begin
    assert(FQuad is TVertexScreenAlignedQuad, 'TGUIComponent.ScreenSize: Not implemented for Worldspace!');
    Result := TVertexScreenAlignedQuad(FQuad).Size / FGUI.Scene.Size;
  end;
end;

function TGUIComponent.GetStyle<T>(Key : EnumGSSTag; Index : integer) : T;
begin
  Result := GetStyleValue<T>(Key, index);
end;

function TGUIComponent.GetItemTemplate(const Index : integer) : string;
begin
  if self = nil then exit('');
  Result := GetStyleValue<string>(gtItemTemplate, index);
end;

function TGUIComponent.GetStyle<T>(Key : EnumGSSTag) : T;
begin
  Result := GetStyleValue<T>(Key);
end;

function TGUIComponent.GetStyleValue<T>(Stylename : EnumGSSTag; Index : integer) : T;
begin
  if not TryGetStyleValue(Stylename, Result, index) then
      Result := FStyleSheet.GetDefaultValue<T>(Stylename, index);
end;

function TGUIComponent.GetTransform : RMatrix4x3;
var
  Origin : RVector2;
  Anchor : EnumComponentAnchor;
  Transform : RMatrix4x3;
begin
  CheckAndBuildAnimationStack;

  if FTransformAnchor = caAuto then
      Anchor := FAnchor
  else
      Anchor := FTransformAnchor;
  Origin := FRect.Translate((ord(Anchor) mod 3) * FRect.Width / 2, (ord(Anchor) div 3) * FRect.Height / 2).LeftTop;

  Transform := FTransform;
  if assigned(FAnimationStack) and FAnimationStack.AnimationStack.HasTag(gtTransform) then
  begin
    case FTransformOrder of
      toTransformAnimation : Transform := FAnimationStack.AnimationStack.Interpolate(FCachedCurrentAnimationKey, gtTransform).AsType<RMatrix4x3> * Transform;
      toAnimationTransform : Transform := Transform * FAnimationStack.AnimationStack.Interpolate(FCachedCurrentAnimationKey, gtTransform).AsType<RMatrix4x3>;
    else
      raise ENotImplemented.Create('TGUIComponent.GetTransform: Not implemented transform order!');
    end;
  end;

  Result := RMatrix4x3.CreateTranslation(Origin.XY0) * Transform * RMatrix4x3.CreateTranslation(-Origin.XY0);

  if not FTransitionWithInheritance and (gtTransform in FTransisitonProperties) and assigned(FTransitionValueTransform) then
  begin
    FTransitionValueTransform.SetValue(Result);
    Result := FTransitionValueTransform.CurrentValue;
  end;

  if HasParent and FTransformInheritance then
      Result := VirtualParent.Transform * Result;

  if FTransitionWithInheritance and (gtTransform in FTransisitonProperties) and assigned(FTransitionValueTransform) then
  begin
    FTransitionValueTransform.SetValue(Result);
    Result := FTransitionValueTransform.CurrentValue;
  end;
end;

function TGUIComponent.GetVisible : boolean;
begin
  if self = nil then exit(False);
  Result := FVisible in [obStyleTrue, obForceTrue];
end;

function TGUIComponent.HasAncestor(const AncestorName : string) : boolean;
begin
  if self = nil then exit(False);
  Result := HasParent and (Parent.Name = AncestorName);
  if not Result and HasParent then
      Result := Parent.HasAncestor(AncestorName);
end;

function TGUIComponent.HasChildren : boolean;
begin
  Result := ChildCount > 0;
end;

function TGUIComponent.HasClass(const ClassName : string) : boolean;
var
  ClassID : integer;
begin
  if self = nil then exit(False);
  ClassID := TGUIStyleManager.ResolveClassname(GSS_CLASS_PREFIX + ClassName);
  Result := FClasses.Contains(ClassID);
end;

function TGUIComponent.HasHint : boolean;
begin
  if self = nil then Result := False
  else Result := FHint <> '';
end;

function TGUIComponent.HasParent : boolean;
begin
  Result := assigned(Parent);
end;

function TGUIComponent.HasScrollbars : boolean;
begin
  Result := FOverflow in [ohScrollX, ohScrollY, ohScroll];
end;

function TGUIComponent.IndexOfChildWithData(Data : NativeUInt) : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to ChildCount - 1 do
    if Children[i].CustomData = Data then exit(i);
end;

procedure TGUIComponent.Idle;
begin
  if (FShow <> nbUnset) and FAnimationPaused then
  begin
    StartAnimationRecursive;
  end;
  if (FShow = nbFalse) and Visible and (not FInitialized or IsAnimationFinished) then
      Visible := False;
  if Visible then
  begin
    if (FDrawSpace = dsWorldScreenSpace) and FGUI.Scene.Camera.IsSphereVisible(RSphere.CreateSphere(Position3D, 1)) then
        SetDirty([gtPosition]);
  end;
  FInitialized := True;
end;

procedure TGUIComponent.IdleRecursive;
var
  i : integer;
begin
  Idle;
  if Visible then
  begin
    for i := 0 to ChildCount - 1 do
        Children[i].IdleRecursive;
  end;
end;

function TGUIComponent.IndexOfChild(const Child : TGUIComponent) : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to ChildCount - 1 do
    if Children[i] = Child then exit(i);
end;

function TGUIComponent.IndexOfChildWithData(Data : TObject) : integer;
begin
  Result := IndexOfChildWithData(NativeUInt(Data));
end;

function TGUIComponent.IndexOfVisibleChild(const Child : TGUIComponent) : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to ChildCount - 1 do
  begin
    if Children[i].IsVisible then inc(Result);
    if Children[i] = Child then exit;
  end;
end;

procedure TGUIComponent.InitDefaultStyle;
begin
  FStyleSheet.Free;
  FStyleSheet := TGUIStyleSheet.Create();
end;

procedure TGUIComponent.InsertChild(Index : integer; Child : TGUIComponent);
begin
  index := Max(0, index);
  if not FChildren.Contains(Child) then
  begin
    if (FChildren.Count <= index) then
        FChildren.Add(Child)
    else
        FChildren.Insert(index, Child);
  end;
  Child.Parent := self;
  ChildrenChanged;
end;

function TGUIComponent.IsAnimationFinished : boolean;
begin
  Result := not assigned(FAnimationStack) or FAnimationFinished;
end;

function TGUIComponent.IsBound : boolean;
begin
  Result := assigned(FXMLNode);
end;

function TGUIComponent.IsClipped(const ViewRect : RRectFloat) : boolean;
begin
  Result := (FDrawSpace in [dsWorldSpace, dsWorldScreenSpace]) and not FRect.Intersects(ViewRect);
end;

function TGUIComponent.IsVisible : boolean;
begin
  if self = nil then exit(False);
  Result := Visible;
  if Result and HasParent then
      Result := Parent.IsVisible;
end;

function TGUIComponent.KeyboardEvent(Event : EnumKeyEvent; Key : EnumKeyboardKey) : boolean;
begin
  Result := False;
end;

function TGUIComponent.KeyboardEventRecursive(Event : EnumKeyEvent; Key : EnumKeyboardKey) : boolean;
var
  i : integer;
begin
  Result := False;
  if not Visible then exit;
  for i := FChildren.Count - 1 downto 0 do
    if FChildren[i].KeyboardEventRecursive(Event, Key) then exit(True);
  Result := KeyboardEvent(Event, Key);
end;

procedure TGUIComponent.ResetCurrentAnimationKey;
begin
  FAnimationPaused := True;
  FCachedCurrentAnimationKey := 0;
  FAnimationFinished := False;
  FAnimationStartTimestamp := TimeManager.GetTimeStamp;
end;

procedure TGUIComponent.ResolveAttributes(const Node : TdXMLNode);
var
  Key : string;
begin
  if Node.Name <> '' then
      ElementName := Node.Name;
  Node.Attributes.OnKeyNotify := OnAttributeChangeRaw;
  for Key in Node.Attributes.Keys do
      OnAttributeChangeRaw(Node.Attributes, Key, TCollectionNotification.cnAdded);
end;

class function TGUIComponent.CreateChildByType(const Node : TdXMLNode; GUI : TGUI) : TGUIComponent;
begin
  if Node.Name = 'stack' then Result := TGUIStackPanel.Create(GUI)
  else if Node.Name = 'input' then Result := TGUIEdit.Create(GUI)
  else if Node.Name = 'check' then Result := TGUICheckbox.Create(GUI)
    // else if Node.Name = 'progress' then Result := TGUIProgressBar.Create(GUI)  // progress bar is deprecated and should be build by hand
  else
  begin
    Result := TGUIComponent.Create(GUI);
    if Node.Name <> '' then
        Result.FElementName := Node.Name;
  end;
  if Node.Name = 'root' then
  begin
    Result.FElementName := 'root';
    Result.ChangeStyle<RGSSSpaceData>(gtPosition, RGSSSpaceData.CreateAbsolute([0.0, 0.0]));
    Result.ChangeStyle<RGSSSpaceData>(gtSize, RGSSSpaceData.CreateAbsolute([GUI.Scene.Size.Width, GUI.Scene.Size.Height]));
    Result.ChangeStyle<EnumMouseEvent>(gtMouseEvents, mePass);
  end;
  GUI.AddComponent(Result);
  Result.LoadAndBindXML(Node);
end;

procedure TGUIComponent.LoadAndBindXML(const Node : TdXMLNode);
begin
  FXMLNode := Node;
  OnTextChange(Node);
  Node.OnNeedReload := ReloadFromXML;
  Node.Children.OnChange := OnXMLChange;
  Node.OnTextChanged := OnTextChange;
  ReloadFromXML(Node);
end;

procedure TGUIComponent.UnBindXML;
begin
  if IsBound then
  begin
    FXMLNode.OnNeedReload := nil;
    FXMLNode.Children.OnChange := nil;
    FXMLNode.Attributes.OnKeyNotify := nil;
    FXMLNode.OnTextChanged := nil;
  end;
end;

procedure TGUIComponent.OnAttributeChange(const Key, Value : string);
var
  Anchor : EnumComponentAnchor;
  tempB : boolean;
begin
  if Key = 'src' then
      BackgroundImage := Value
  else if Key = 'class' then
      ClassesAsText := Value
  else if Key = 'visible' then
  begin
    Visible := (FShow <> nbFalse) and HString.StrToBool(Value, False);
  end
  else if Key = 'show' then
  begin
    if (CompareText(Value, 'true') = 0) then
    begin
      if (FShow <> nbTrue) and not Visible then
          Visible := True;
      Show := nbTrue
    end
    else if (CompareText(Value, 'false') = 0) then
        Show := nbFalse
    else
        Show := nbUnset;
  end
  else if Key = 'enabled' then
      Enabled := HString.StrToBool(Value)
  else if Key = 'text' then
      Text := Value.Trim
  else if Key = 'style' then
      FStyleSheet.DataAsText := Value
  else if Key = 'id' then
      name := Value
  else if Key = 'title' then
      Hint := Value
  else if Key = 'down' then
      Down := HString.StrToBool(Value, False)
  else if (Key = 'anchor') and HRTTI.TryStringToEnumeration<EnumComponentAnchor>(Value, Anchor) then
      ChangeStyle(gtAnchor, Anchor)
  else if (Key = 'parentanchor') and HRTTI.TryStringToEnumeration<EnumComponentAnchor>(Value, Anchor) then
      ChangeStyle(gtParentAnchor, Anchor)
  else if (Key = 'left') or (Key = 'position-x') then
      ChangeStyle(gtPosition, 0, RGSSSpaceData.CreateFromString(Value))
  else if (Key = 'offset-x%') then
      ChangeStyle(gtPosition, 0, RGSSSpaceData.CreateRelative(HMath.Saturate(TGUIStyleSheet.CSSStrToFloat(Value, 1.0))))
  else if (Key = 'left%') or (Key = 'position-x%') then
      ChangeStyle(gtPosition, 0, RGSSSpaceData.CreateRelative(TGUIStyleSheet.CSSStrToFloat(Value, 1.0)))
  else if (Key = 'top') or (Key = 'position-y') then
      ChangeStyle(gtPosition, 1, RGSSSpaceData.CreateFromString(Value))
  else if (Key = 'top%') or (Key = 'position-y%') then
      ChangeStyle(gtPosition, 1, RGSSSpaceData.CreateRelative(TGUIStyleSheet.CSSStrToFloat(Value, 1.0)))
  else if (Key = 'offset-y%') then
      ChangeStyle(gtPosition, 1, RGSSSpaceData.CreateRelative(HMath.Saturate(TGUIStyleSheet.CSSStrToFloat(Value, 1.0))))
  else if Key = 'width' then
      ChangeStyle(gtSize, 0, RGSSSpaceData.CreateFromString(Value))
  else if Key = 'width%' then
      ChangeStyle(gtSize, 0, RGSSSpaceData.CreateRelative(TGUIStyleSheet.CSSStrToFloat(Value, 1.0)))
  else if Key = 'max-width%' then
      ChangeStyle(gtMaxSize, 0, RGSSSpaceData.CreateRelative(TGUIStyleSheet.CSSStrToFloat(Value, 1.0)))
  else if (Key = 'fill-x%') then
      ChangeStyle(gtSize, 0, RGSSSpaceData.CreateRelative(HMath.Saturate(TGUIStyleSheet.CSSStrToFloat(Value, 1.0))))
  else if Key = 'height' then
      ChangeStyle(gtSize, 1, RGSSSpaceData.CreateFromString(Value))
  else if Key = 'height%' then
      ChangeStyle(gtSize, 1, RGSSSpaceData.CreateRelative(TGUIStyleSheet.CSSStrToFloat(Value, 1.0)))
  else if Key = 'max-height%' then
      ChangeStyle(gtMaxSize, 1, RGSSSpaceData.CreateRelative(TGUIStyleSheet.CSSStrToFloat(Value, 1.0)))
  else if (Key = 'fill-y%') then
      ChangeStyle(gtSize, 1, RGSSSpaceData.CreateRelative(HMath.Saturate(TGUIStyleSheet.CSSStrToFloat(Value, 1.0))))
  else if Key = 'rotation' then
      FRotationSpeed := TGUIStyleSheet.CSSStrToFloat(Value, 0)
  else if Key = 'transform' then
      ChangeStyle(gtTransform, Value)
  else if Key = 'animate-on' then
      StartAnimationRecursive
  else if Key = 'animate-on-if' then
  begin
    if HString.TryStrToBool(Value, tempB) and tempB then
        StartAnimationRecursive
  end
  else if Key = 'animation-delay' then
      ChangeStyle(gtAnimationDelay, HString.StrToInt(Value, 0))
  else if Key = 'animation-delay-after' then
      ChangeStyle(gtAnimationDelay, 1, HString.StrToInt(Value, 0))
  else if Key = 'clip-progress' then
      FProgressPosition := TGUIStyleSheet.CSSStrToFloat(Value, 0.0)
  else if Key = 'clip-progress-max' then
      FProgressmaximum := TGUIStyleSheet.CSSStrToFloat(Value, 0.0);
end;

procedure TGUIComponent.OnAttributeChangeRaw(Sender : TObject; const Key : string; Action : TCollectionNotification);
var
  Value : string;
begin
  if Action = cnAdded then
      Value := (Sender as TDictionary<string, string>)[Key]
  else
      Value := '';
  OnAttributeChange(Key, Value);
end;

procedure TGUIComponent.OnTextChange(const Node : TdXMLNode);
begin
  Text := Node.Text.Trim;
end;

procedure TGUIComponent.OnXMLChange(Sender : TUltimateList<TdXMLNode>; Items : TArray<TdXMLNode>; Action : EnumListAction; Indices : TArray<integer>);
var
  i : integer;
begin
  case Action of
    laAdd : InsertChild(Indices[0], CreateChildByType(Items[0], FGUI));
    laRemoved, laExtracted, laExtractedRange :
      begin
        for i := 0 to length(Indices) - 1 do
            DeleteChild(Indices[i]);
      end;
    laChanged :; // not in use
    laClear : ClearChildren;
    laAddRange :
      begin
        for i := length(Items) - 1 downto 0 do
            InsertChild(Indices[0], CreateChildByType(Items[i], FGUI));
      end;
  end;
end;

procedure TGUIComponent.ReloadFromXML(const Node : TdXMLNode);
begin
  ResolveAttributes(Node);
  Node.Children.FakeClear;
  Node.Children.FakeCompleteAdd;
end;

procedure TGUIComponent.LoadTexture(Stylename : EnumGSSTag; Texture : Pointer);
var
  str, texturepath : string;
  temp : TTexture;
begin
  if TryGetStyleValue<string>(Stylename, str) and not str.IsEmpty then
  begin
    texturepath := FormatDateiPfad(FGUI.AssetPath + '\' + str);
    if (TTexture(Texture^) = nil) or not SameText(TTexture(Texture^).Filename, texturepath) or (TTexture(Texture^).MipMapHandling <> FMipMapHandling) then
    begin
      FreeAndNil(TTexture(Texture^));
      try
        temp := TTexture.CreateTextureFromFile(texturepath, GFXD.Device3D, FMipMapHandling, FMipMapHandling = mhGenerate, True);
        if assigned(temp) then
        begin
          TTexture(Texture^) := temp;
          self.SetDirty([gtSize]);
        end
        else FGUI.PutError('Can''t find texture ' + texturepath);
      except
        TTexture(Texture^) := nil;
      end;
    end;
  end
  else FreeAndNil(TTexture(Texture^));
end;

procedure TGUIComponent.MouseEnter;
begin
  if FHovered then exit;
  FHovered := True;
  if FMouseDown[mbLeft] then SetDownSoft(True);
  FGUI.AddEvent(RGUIEvent.Create(geMouseEnter, self));
  if FMouseEvent in [meAll, mePassClick] then
  begin
    // apply hover styles except we don't care for pointer events
    SetStyleSheetStackDirtyRecursive;
  end;
end;

procedure TGUIComponent.MouseLeave;
begin
  if not FHovered then exit;
  FScrollbarHovered := False;
  FHovered := False;
  SetDownSoft(False);
  FGUI.AddEvent(RGUIEvent.Create(geMouseLeave, self));
  if FMouseEvent in [meAll, mePassClick] then
  begin
    // remove hover styles except we don't care for pointer events
    SetStyleSheetStackDirtyRecursive;
  end;
end;

procedure TGUIComponent.MouseMove(const Position : RVector2);
var
  MousePos : single;
begin
  if HasScrollbars and PointInScrollbar(Position) then
  begin
    FScrollbarHovered := PointInScrollbarTracker(Position);
    if FMouseDown[mbLeft] then
    begin
      MousePos := ((Position.Y - FRect.Top) / FRect.Height);
      ScrollOffset := ScrollOffset.SetY(HMath.Saturate(MousePos * (1 + FRect.Height / FScrollRect.Height) - FRect.Height / FScrollRect.Height * 0.5) * FScrollRect.Height);
    end;
  end
  else FScrollbarHovered := False;
end;

procedure TGUIComponent.MouseUp(const Position : RVector2; Button : EnumMouseButton);
begin
  if Enabled then
  begin
    FGUI.AddEvent(RGUIEvent.Create(geMouseUp, self));
    if FMouseDown[Button] then
    begin
      FMouseDown[Button] := False;
      Click(Button, Position);
    end;
  end;
end;

function TGUIComponent.MouseWheel(const Position : RVector2; Ticks : integer) : boolean;
var
  ScrollDistance : RVector2;
begin
  Result := True;
  case FOverflow of
    ohScrollX : ScrollDistance := RVector2.Create(1, 0);
    ohScrollY, ohScroll : ScrollDistance := RVector2.Create(0, -1);
  else
    exit;
  end;
  Scroll(ScrollDistance * Ticks * MOUSEWHEEL_SCROLLSPEED);
end;

procedure TGUIComponent.MouseDown(const Position : RVector2; Button : EnumMouseButton);
begin
  if Enabled or (HasScrollbars and PointInScrollbar(Position)) then
  begin
    FMouseDown[Button] := True;
    if Button = mbLeft then SetDownSoft(True);
    FGUI.AddEvent(RGUIEvent.Create(geMouseDown, self));
  end;
end;

function TGUIComponent.ParentRect : RRectFloat;
begin
  if HasParent then
  begin
    case FParentBox of
      pbContent : Result := VirtualParent.ContentRect;
      pbPadding : Result := VirtualParent.BackgroundRect;
      pbMargin : Result := VirtualParent.OuterRect;
    end;
  end
  else
      Result := RRectFloat.ZERO;
end;

function TGUIComponent.PointInComponent(const Point : RVector2) : boolean;
begin
  Result := Visible and not(FDrawSpace in [dsViewSpace, dsWorldSpace]) and not(FMouseEvent in [mePass]) and FCliprect.ContainsPoint(Point);
end;

function TGUIComponent.PointInScrollbar(Point : RVector2) : boolean;
begin
  Result := ScrollbarBackgroundRect.ContainsPoint(Point);
end;

function TGUIComponent.PointInScrollbarTracker(Point : RVector2) : boolean;
begin
  Result := ScrollbarTrackerRect.ContainsPoint(Point);;
end;

function TGUIComponent.Position3D : RVector3;
var
  i : integer;
  SpaceData : RGSSSpaceData;
begin
  for i := 0 to 2 do
  begin
    SpaceData := GetStyleValue<RGSSSpaceData>(gtPosition, i);
    Result.Element[i] := SpaceData.Value;
  end;
end;

procedure TGUIComponent.PrepareHint;
var
  HintAnchor : EnumComponentAnchor;
  OffsetX, OffsetY : RGSSSpaceData;
begin
  if not HasHint then exit;
  HintAnchor := self.GetStyleValue<EnumComponentAnchor>(gtHintAnchor);
  OffsetX := self.GetStyleValue<RGSSSpaceData>(gtHintOffset, 0);
  OffsetY := self.GetStyleValue<RGSSSpaceData>(gtHintOffset, 1);
  FGUI.PrepareHint(
    FRect.Round.Translate(RVector2.Create(ResolvePosition(OffsetX, 0), ResolvePosition(OffsetY, 1)).Round),
    FHint,
    FHintTemplate,
    FHintClasses,
    -1,
    HintAnchor,
    UID);
end;

procedure TGUIComponent.PrependChild(Child : TGUIComponent);
begin
  if not FChildren.Contains(Child) then FChildren.Insert(0, Child);
  Child.Parent := self;
  ChildrenChanged;
end;

function TGUIComponent.PseudoClasses : SetPseudoClass;
begin
  Result := [pcNone];
  if FHovered then include(Result, pcHover);
  if Down then include(Result, pcDown);
  if ScrollbarsVisible then include(Result, pcScrollable);
  if FShow = nbTrue then include(Result, pcShowing);
  if FShow = nbFalse then include(Result, pcHiding);
  if not Enabled then include(Result, pcDisabled)
  else include(Result, pcEnabled);
  if FFocused then include(Result, pcFocus);
  if HasParent and (Parent.IndexOfVisibleChild(self) mod 2 <> 0) then include(Result, pcOdd)
  else include(Result, pcEven);
  if HasParent and Parent.HasChildren and (Parent.GetChild(0) = self) then include(Result, pcFirstChild);
  if HasParent and Parent.HasChildren and (Parent.GetChild(Parent.ChildCount - 1) = self) then include(Result, pcLastChild);
end;

procedure TGUIComponent.MoveTo(NewParent : TGUIComponent);
begin
  assert(HasParent, 'TGUIComponent.MoveTo: Can''t move if no parent is there.');
  if NewParent = self then exit;
  if NewParent.Parent = self then
  begin
    Parent.AddChild(NewParent);
    RemoveChild(NewParent);
  end;
  Parent.RemoveChild(self);
  NewParent.AddChild(self);
  SetDirty;
end;

procedure TGUIComponent.RemoveChild(Child : TGUIComponent);
begin
  FChildren.Extract(Child);
  ChildrenChanged;
end;

function TGUIComponent.RemoveClass(const GSSClass : string) : boolean;
var
  ClassID, i : integer;
begin
  Result := False;
  if self = nil then exit;
  ClassID := TGUIStyleManager.ResolveClassname(GSS_CLASS_PREFIX + GSSClass);
  for i := FClasses.Count - 1 downto 0 do
    if FClasses[i] = ClassID then
    begin
      FClasses.Delete(i);
      FClassesAsText := ClassesAsText;
      Result := True;
      // class changes can influence all descendants
      SetStyleSheetStackDirtyRecursive;
      // dont break, if the class have found a way to be multiple in this list, if ensured, we can add it
      // break;
    end;
end;

procedure TGUIComponent.Rename(newName : string);
begin
  FGUI.RenameComponent(newName, self);
end;

procedure TGUIComponent.Render;
var
  BackgroundColorOverrideReady : boolean;
  BackgroundColorOverrideCached : RColor;
  function IsQuadVisible() : boolean;
  begin
    if not assigned(FQuad) then Result := False
    else if FQuad is TVertexScreenAlignedQuad then Result := FCliprect.HasSize
    else Result := True;
  end;
  function SetBorderSidesToSetRectSides(const Value : SetBorderSides) : SetRectSide;
  begin
    Result := [];
    if bsTop in Value then include(Result, rsTop);
    if bsRight in Value then include(Result, rsRight);
    if bsBottom in Value then include(Result, rsBottom);
    if bsLeft in Value then include(Result, rsLeft);
  end;
  function ResolveBackgroundSpriteSheetCoordinates : RRectFloat;
  var
    Progress : single;
    Iteration, ImageIndex, ImageIndexNormal, ImageIndexReverse, AnimationDuration : integer;
  begin
    if FBgSheetCount > 1 then
    begin
      if FAnimationDuration = 0 then AnimationDuration := Round((1000 / 30) * FBgSheetCount)
      else AnimationDuration := FAnimationDuration;
      AnimationDuration := FAnimationDelay + AnimationDuration + FAnimationDelayAfter;
      if AnimationDuration > 0 then
      begin
        Iteration := Max(0, (TimeManager.GetTimeStamp - FAnimationStartTimestamp){ - FAnimationDelay });
        Progress := Iteration / AnimationDuration;
        Progress := Frac(Progress);
        Progress := Progress - (FAnimationDelay / AnimationDuration);
        Progress := Progress / ((AnimationDuration - FAnimationDelay - FAnimationDelayAfter) / AnimationDuration);
        Progress := Max(0, Min(1, Progress));
        Iteration := Iteration div AnimationDuration;
      end
      else
      begin
        Progress := 0;
        Iteration := FAnimationIterationCount;
      end;
      if (Iteration >= FAnimationIterationCount) and (FAnimationIterationCount > 0) then
      begin
        ImageIndexNormal := FBgSheetCount - 1;
        ImageIndexReverse := FBgSheetCount - ImageIndexNormal;
        case FAnimationFillMode of
          afNone, afForwards : ImageIndexReverse := ImageIndexNormal;
          afBackwards : ImageIndexNormal := ImageIndexReverse;
          afBoth :;
        else
          raise ENotImplemented.Create('ResolveBackgroundSpriteSheetCoordinates: Fillmode not implemented.');
        end;
      end
      else
      begin
        ImageIndexNormal := Round(Progress * (FBgSheetCount - 1));
        ImageIndexReverse := (FBgSheetCount - 1) - ImageIndexNormal;
      end;
      case FAnimationDirection of
        adNormal : ImageIndex := ImageIndexNormal;
        adReverse : ImageIndex := ImageIndexReverse;
        adAlternate : if Iteration mod 2 = 0 then ImageIndex := ImageIndexNormal
          else ImageIndex := ImageIndexReverse;
        adAlternateReverse : if Iteration mod 2 = 0 then ImageIndex := ImageIndexReverse
          else ImageIndex := ImageIndexNormal;
      else
        raise ENotImplemented.Create('ResolveBackgroundSpriteSheetCoordinates: AnimationDirection not implemented.');
      end;
    end
    else
        ImageIndex := 0;
    if FBgSheetSize > 1 then
    begin
      Result.Left := FCoordinateRect.Left + FCoordinateRect.Width / FBgSheetSize.X * (ImageIndex mod FBgSheetSize.X);
      Result.Top := FCoordinateRect.Top + FCoordinateRect.Height / FBgSheetSize.Y * (ImageIndex div FBgSheetSize.X);
      Result.Right := FCoordinateRect.Left + FCoordinateRect.Width / FBgSheetSize.X * ((ImageIndex mod FBgSheetSize.X) + 1);
      Result.Bottom := FCoordinateRect.Top + FCoordinateRect.Height / FBgSheetSize.Y * ((ImageIndex div FBgSheetSize.X) + 1);
    end
    else
        Result := FCoordinateRect;
  end;
  function CachedBackgroundColorOverride : RColor;
  begin
    if not BackgroundColorOverrideReady then
    begin
      BackgroundColorOverrideCached := self.BackgroundColorOverride;
      BackgroundColorOverrideReady := True;
    end;
    Result := BackgroundColorOverrideCached;
  end;

var
  i : integer;
  finalColor : array [0 .. 3] of RColor;
  borderRect : RRect;
  anchorRect : RRectFloat;
  Color : RColor;
  Scene : TRenderManager;
begin
  BackgroundColorOverrideReady := False;
  ComputeAnimationKey;
  if IsQuadVisible then
  begin
    FQuad.Texture := FBgTexture.Default;
    FQuad.CoordinateRect := ResolveBackgroundSpriteSheetCoordinates;
    FQuad.UseTransform := True;
    FQuad.TransformAppliesToTexCoords := not FTransformKeepBackground;
    FQuad.Transform := Transform;
    FQuad.ColorOverride := CachedBackgroundColorOverride;
    if FQuad is TVertexScreenAlignedQuad then
    begin
      with TVertexScreenAlignedQuad(FQuad) do
      begin
        Transform := Transform * RMatrix4x3.CreateRotationZAroundPosition(Rect.Center.XY0, TimeManager.GetFloatingTimestamp / 1000 * FRotationSpeed);
        ScissorEnabled := True;
        ScissorRect := FCliprect;
        BorderSizeInner := FBorderInner;
        BorderSizeOuter := FBorderOuter;
        BorderColorOuterStart := FBorderColorStart;
        BorderColorOuterStart.a := BorderColorOuterStart.a * Opacity;
        BorderColorOuterEnd := FBorderColorEnd;
        BorderColorOuterEnd.a := BorderColorOuterEnd.a * Opacity;
        DrawBorder := SetBorderSidesToSetRectSides(FBorderSides);
        OutlineSizeInner := FOutlineInner;
        OutlineSizeOuter := FOutlineOuter;
        OutlineColorOuterStart := FOutlineColorStart;
        OutlineColorOuterStart.a := OutlineColorOuterStart.a * Opacity;
        OutlineColorOuterEnd := FOutlineColorEnd;
        OutlineColorOuterEnd.a := OutlineColorOuterEnd.a * Opacity;
        DrawOutline := SetBorderSidesToSetRectSides(FOutlineSides);
        Zoom := FZoom;
        DerivedShader := FDerivedShader;
        if FProgressShape = psRadial then
            RadialClip := HMath.Saturate(FProgressPosition / FProgressmaximum)
        else
            RadialClip := -1;
      end;
    end;
    for i := 0 to length(finalColor) - 1 do
        finalColor[i] := FBgColor[i].Default;
    if (not Enabled and (FMouseEvent in [meAll])) or FShowAsDisabled then
    begin
      if assigned(FBgTexture.Disabled) then FQuad.Texture := FBgTexture.Disabled;
      if not FBgColor[0].Disabled.IsFullTransparent then
        for i := 0 to length(finalColor) - 1 do
            finalColor[i] := FBgColor[i].Disabled;
    end;
    if FHovered and not((assigned(FBgTexture.Disabled) or (FBgColor[0].Disabled <> 0)) and not Enabled) then
    begin
      if assigned(FBgTexture.Hover) then FQuad.Texture := FBgTexture.Hover;
      if not FBgColor[0].Hover.IsFullTransparent then
        for i := 0 to length(finalColor) - 1 do
            finalColor[i] := FBgColor[i].Hover;
    end;
    if Down then
    begin
      if assigned(FBgTexture.Down) then FQuad.Texture := FBgTexture.Down;
      if not FBgColor[0].Down.IsFullTransparent then
        for i := 0 to length(finalColor) - 1 do
            finalColor[i] := FBgColor[i].Down;
    end;

    if (FSceneName <> '') and GFXD.TryGetScene(FSceneName, Scene) then
    begin
      Scene.Active := True;
      FQuad.Texture := Scene.BackbufferTexture;
    end;

    FQuad.UseGradientColors := True;
    FQuad.Color := finalColor[0];
    FQuad.TopRightColor := finalColor[1];
    FQuad.BottomRightColor := finalColor[2];
    FQuad.BottomLeftColor := finalColor[3];

    FQuad.SecondaryTexture := FBackgroundMask;
    FQuad.SecondaryCoordinateRect := RRectFloat.Create(0, 0, 1, 1);
    // TODO: hacked for current purpose, refactor it with something more general
    if assigned(FBackgroundMask) then
    begin
      FQuad.SecondaryCoordinateRect := RRectFloat.Create(0, 0, FQuad.Transform._11, FQuad.Transform._22).Translate(FQuad.Transform.Translation.XY);
      FQuad.Transform := RMatrix4x3.IDENTITY;
    end;

    // if a texture is set, fix non set colors (defaults to 0) to show texture
    if assigned(FQuad.Texture) and FQuad.Color.RGBA.IsZero then
    begin
      FQuad.Color := RColor.CWHITE;
      FQuad.UseGradientColors := False;
    end;
    // apply opacity
    FQuad.Color.a := FQuad.Color.a * Opacity;
    FQuad.TopRightColor.a := FQuad.TopRightColor.a * Opacity;
    FQuad.BottomRightColor.a := FQuad.BottomRightColor.a * Opacity;
    FQuad.BottomLeftColor.a := FQuad.BottomLeftColor.a * Opacity;
    if (FQuad.Texture <> nil) or (not FQuad.IsFullTransparent) or
      (FQuad is TVertexScreenAlignedQuad and TVertexScreenAlignedQuad(FQuad).HasBorder) or
      (FQuad is TVertexScreenAlignedQuad and TVertexScreenAlignedQuad(FQuad).HasOutline) then
        FQuad.AddRenderJob;
  end;
  if assigned(FBlurQuad) then
  begin
    FBlurQuad.ColorOverride := CachedBackgroundColorOverride;
    FBlurQuad.UseTransform := True;
    FBlurQuad.Transform := Transform;
    FBlurQuad.Color := FBlurColor;
    FBlurQuad.Rect := BackgroundRect;
    // screen coordinates
    FBlurQuad.CoordinateRect := FBlurQuad.Rect / FGUI.Scene.Size;
    FBlurQuad.SecondaryCoordinateRect := RRectFloat.Create(0, 0, 1, 1);
    FBlurQuad.OnPreRender := nil;
    FBlurQuad.DerivedShader := '';
    if FBlurLayer then
    begin
      FBlurQuad.OnPreRender := RenderLayerBlur;
      FBlurQuad.Texture := FGUI.FBlurTexture.Texture;
    end
    else if FGUI.EnableBlurBackgrounds then
    begin
      FBlurQuad.Texture := FGUI.Scene.BlurredScene;
      FBlurQuad.DerivedShader := 'GUIBlur.fx';
    end
    else
    begin
      FBlurQuad.Color := FBlurColorFallback;
      FBlurQuad.Texture := nil;
    end;
    FBlurQuad.SecondaryTexture := FBlurMask;
    // apply opacity
    FBlurQuad.Color.a := FBlurQuad.Color.a * Opacity;
    FBlurQuad.Zoom := FZoom;
    if not FBlurQuad.Color.IsFullTransparent then
        FBlurQuad.AddRenderJob;
  end;
  if (Text <> '') and assigned(FFont) and FCliprect.HasSize then
  begin
    FFont.ColorOverride := CachedBackgroundColorOverride;
    FFont.UseTransform := True;
    FFont.Transform := Transform;
    FFont.Rect := ContentRect.Round;
    FFont.ScissorEnabled := True;
    FFont.ScissorRect := FCliprect;
    FFont.Color := FFontColor;
    // apply opacity
    FFont.Color := FFont.Color.SetAlphaF(FFont.Color.a * Opacity);
    FFont.Text := Text;
    FFont.Zoom := FZoom;
    FFont.DerivedShader := FDerivedShader;
    if not FFont.Color.IsFullTransparent then
        FFont.AddRenderJob;
  end;
  if HasScrollbars and assigned(FScrollbarBackgroundQuad) and assigned(FScrollbarTrackerQuad) and ScrollbarsVisible then
  begin
    FScrollbarBackgroundQuad.UseTransform := True;
    FScrollbarBackgroundQuad.Transform := Transform;
    FScrollbarBackgroundQuad.Rect := ScrollbarBackgroundRect;
    Color := FScrollbarBackgroundColor.Default;
    if FHovered and not FScrollbarBackgroundColor.Disabled.IsFullTransparent then
        Color := FScrollbarBackgroundColor.Disabled;
    if FScrollbarHovered and not FScrollbarBackgroundColor.Hover.IsFullTransparent then
        Color := FScrollbarBackgroundColor.Hover;
    FScrollbarBackgroundQuad.Color := Color;
    FScrollbarBackgroundQuad.AddRenderJob;

    FScrollbarTrackerQuad.UseTransform := True;
    FScrollbarTrackerQuad.Transform := Transform;
    FScrollbarTrackerQuad.Rect := ScrollbarTrackerRect;
    Color := FScrollbarColor.Default;
    if FHovered and not FScrollbarColor.Disabled.IsFullTransparent then
        Color := FScrollbarColor.Disabled;
    if FScrollbarHovered and not FScrollbarColor.Hover.IsFullTransparent then
        Color := FScrollbarColor.Hover;
    FScrollbarTrackerQuad.Color := Color;
    FScrollbarTrackerQuad.AddRenderJob;
  end;
  if assigned(FBorderImage[0]) then
  begin
    borderRect := BackgroundRect.Round.Inflate(FBorderImageOffset);
    anchorRect := RRectFloat.Create(0, 0, 1, 1);
    for i := 0 to length(FBorderImage) - 1 do
      if assigned(FBorderImage[i].Texture) then
      begin
        FBorderImage[i].Position := borderRect.AnchorPoints[i];
        FBorderImage[i].Anchor := anchorRect.AnchorPoints[(i + 4) mod length(FBorderImage)];
        if (i = 3) or (i = 7) then
        begin
          FBorderImage[i].Position.Y := borderRect.Top;
          FBorderImage[i].Anchor.Y := 0;
        end;
        FBorderImage[i].Size := FBorderImage[i].Texture.Size;
        case i of
          1 : FBorderImage[i].Width := borderRect.Width;
          3 : FBorderImage[i].Height := borderRect.Height;
          5 : FBorderImage[i].Width := borderRect.Width;
          7 : FBorderImage[i].Height := borderRect.Height;
        end;
        // apply opacity
        FBorderImage[i].ColorOverride := CachedBackgroundColorOverride;
        FBorderImage[i].Color.a := FBorderImage[i].Color.a * Opacity;
        FBorderImage[i].DerivedShader := FDerivedShader;
        if not FBorderImage[i].Color.IsFullTransparent then
            FBorderImage[i].AddRenderJob;
      end;
  end;
end;

procedure TGUIComponent.RenderLayerBlur(RenderContext : TRenderContext);
begin
  RenderContext.SwitchScene(True);
  GFXD.Device3D.PushRenderTargets([FGUI.FBlurTexture.Texture.AsRendertarget]);
  FGUI.FBlurrer.RenderBlur(RenderContext.Scene, RenderContext);
  GFXD.Device3D.PopRenderTargets;
  FBlurQuad.Texture := FGUI.FBlurTexture.Texture;

  GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
  GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, cmNone);
  GFXD.Device3D.SetRenderState(EnumRenderstate.rsZWRITEENABLE, 0);
end;

procedure TGUIComponent.RenderRecursive(const ViewRect : RRectFloat);
var
  Child : TGUIComponent;
begin
  if Visible and not IsClipped(ViewRect) then
  begin
    Render;
    for Child in FChildren do
        Child.RenderRecursive(FViewRect);
  end;
end;

function TGUIComponent.RenderRequirements : SetRenderRequirements;
var
  Child : TGUIComponent;
begin
  Result := [];
  if Visible then
  begin
    if FBlur then
    begin
      if FBlurLayer then Result := [rrScene]
      else if FGUI.EnableBlurBackgrounds then Result := [rrBlurredScene];
    end;
    for Child in FChildren do Result := Result + Child.RenderRequirements;
  end;
end;

procedure TGUIComponent.ReplaceChild(Index : integer; NewChild : TGUIComponent);
begin
  DeleteChild(index);
  InsertChild(index, NewChild);
end;

procedure TGUIComponent.SetDirty;
begin
  SetDirty(AllGSSTags);
end;

procedure TGUIComponent.SaveToFile(const Filename : string);
var
  temp : TGUIComponent;
  XMLSerializer : TXMLSerializer;
begin
  XMLSerializer := TXMLSerializer.Create;
  temp := FParent;
  FParent := nil;
  XMLSerializer.SaveObjectToFile(self, Filename);
  FParent := temp;
  XMLSerializer.Free;
end;

procedure TGUIComponent.Scroll(Distance : RVector2);
begin
  if ChildCount > 0 then ScrollOffset := ScrollOffset + Distance;
end;

function TGUIComponent.ScrollbarBackgroundRect : RRectFloat;
begin
  Result := RRectFloat.Create(
    FRect.RightTop - RIntVector2.Create(Round(FScrollbarWidth), 0),
    FRect.RightBottom);
end;

function TGUIComponent.ScrollbarsVisible : boolean;
begin
  Result := HasScrollbars and (FScrollRect.Height > 0) and (FScrollbarWidth > 0);
end;

function TGUIComponent.ScrollbarTrackerRect : RRectFloat;
begin
  Result := RRectFloat.Create(
    FRect.RightTop + RVector2.Create(0, (FScrollOffset.Y / (FScrollRect.Height + FRect.Height)) * FRect.Height) - RIntVector2.Create(Round(FScrollbarWidth), 0),
    FRect.RightTop + RVector2.Create(0, ((FScrollOffset.Y + FRect.Height) / (FScrollRect.Height + FRect.Height)) * FRect.Height))
    .Inflate(-FScrollbarPadding)
end;

procedure TGUIComponent.SetCompleteDirty;
var
  Child : TGUIComponent;
begin
  SetDirty(AllGSSTags);
  for Child in FChildren do
  begin
    Child.SetCompleteDirty;
  end;
end;

procedure TGUIComponent.SetCurrentHintSafe(const Value : string);
begin
  ChangeStyle<string>(gtHint, Value);
end;

procedure TGUIComponent.SetCurrentText(const Value : string);
begin
  if UpdateText(Value) then
      SetDirty([gtText]);
end;

procedure TGUIComponent.SetCurrentTextAsInteger(const Value : integer);
begin
  Text := Inttostr(Value);
end;

procedure TGUIComponent.SetCurrentTextSafe(const Value : string);
begin
  if assigned(self) then SetCurrentText(Value);
end;

procedure TGUIComponent.SetCustomDataAsWrapper<T>(const Value : T);
begin
  if not assigned(self) then exit;
  self.OwnsCustomData := True;
  self.CustomData := NativeUInt(TObjectWrapper<T>.Create(Value));
end;

procedure TGUIComponent.SetDirty(const Tags : SetGSSTag);
begin
  if Tags - FDirty = [] then exit;
  // first tag all parents that they recompute their children
  if HasParent then
  begin
    if Tags - [gtDirtyChildren] = [] then
        Parent.SetDirty([gtDirtyGrandChildren])
    else
        Parent.SetDirty([gtDirtyChildren]);
  end;
  // then inherit dirty to all ancestors so they adapt to the changes
  SetDirtyAncestors(Tags);
end;

procedure TGUIComponent.SetDirtyAncestors(const Tags : SetGSSTag);
var
  Child : TGUIComponent;
  InheritedDirtyFlags : SetGSSTag;
begin
  if Tags - FDirty = [] then exit;
  FDirty := FDirty + Tags;
  if (FChildren.Count > 0) and (Tags * CHILDRENAFFECTINGTAGS <> []) then
  begin
    InheritedDirtyFlags := BuildDirtyFlagInheritance(Tags);
    for Child in FChildren do
        Child.SetDirtyAncestors(InheritedDirtyFlags);
  end;
end;

procedure TGUIComponent.SetDown(const Value : boolean);
begin
  if not assigned(self) then exit;
  if Value <> Down then
  begin
    // apply down styles
    // down is used as a pseudo class, so all children could change their style
    SetStyleSheetStackDirtyRecursive;
  end;
  if Value then FDown := obForceTrue
  else FDown := obForceFalse;
end;

procedure TGUIComponent.SetDownSoft(const Value : boolean);
begin
  if (FDown in [obStyleTrue, obStyleFalse]) and (Value <> Down) then
  begin
    if Value then FDown := obStyleTrue
    else FDown := obStyleFalse;
    // apply down styles
    // down is used as a pseudo class, so all children could change their style
    SetStyleSheetStackDirtyRecursive;
  end;
end;

procedure TGUIComponent.SetEnabled(const Value : boolean);
begin
  if Value <> Enabled then
  begin
    // enabeld is used as a pseudo class, so all children could change their style
    SetStyleSheetStackDirtyRecursive;
  end;
  if Value then FEnabled := obForceTrue
  else FEnabled := obForceFalse;
end;

procedure TGUIComponent.SetEnabledStyle(const Value : boolean);
begin
  if (FEnabled in [obStyleTrue, obStyleFalse]) and (Value <> Enabled) then
  begin
    if Value then FEnabled := obStyleTrue
    else FEnabled := obStyleFalse;
    // apply disabled styles
    SetStyleSheetStackDirtyRecursive;
  end;
end;

procedure TGUIComponent.SetVisible(const Value : boolean);
var
  WasVisible : boolean;
begin
  WasVisible := Visible;

  if Value then
      FVisible := obForceTrue
  else
      FVisible := obForceFalse;

  if not WasVisible and Visible then
  begin
    SetCompleteDirty;
  end;

  if WasVisible and not Visible then
  begin
    Traverse(
      procedure(item : TGUIComponent)
      begin
        item.MouseLeave
      end);
    // notify Stackpanel that this children is now missing
    if HasParent then
        Parent.ChildrenChanged;
  end;
end;

procedure TGUIComponent.SetVisibleSafe(const Value : boolean);
begin
  if assigned(self) then SetVisible(Value);
end;

procedure TGUIComponent.ShowHint;
begin
  if not HasHint then exit;
  PrepareHint;
  FGUI.ShowHint;
end;

function TGUIComponent.SiblingIndex : integer;
begin
  Result := 0;
  if HasParent then Result := Parent.FChildren.IndexOf(self);
end;

function TGUIComponent.TransformRawText(const Text : string) : string;
  function ChangeCase(const Text : string; ToUpper : boolean) : string;
  var
    i : integer;
    InText : boolean;
  begin
    Result := '';
    InText := True;
    for i := 0 to length(Text) - 1 do
    begin
      if Text[i + 1] = '|' then
      begin
        InText := not InText;
      end
      else if not InText then
          Result := Text[i + 1]
      else
      begin
        if ToUpper then
            Result := Result + AnsiUpperCase(Text[i + 1])
        else
            Result := Result + AnsiLowerCase(Text[i + 1])
      end;
    end;
  end;

var
  words : AString;
  i : integer;
  Regex : TRegex;
begin
  if Text <> '' then
  begin
    // translate
    Result := HInternationalizer.TranslateTextRecursive(Text);

    // apply styles
    if Result.Contains('<span') then
    begin
      Regex := TRegex.Create('\<span class="((?:[a-zA-z\-\%\:0-9]+ ?)+)"\>(.*?)\<\/span\>', [roSingleLine, roIgnoreCase]);
      Result := Regex.MultiSubstitute(Result,
        function(sub : array of string) : string
        var
          rawClasses : TArray<string>;
          i : integer;
          ClassHierarchy : TClassHierarchy;
          Classes : TClassHierarchyNode;
          StyleStack : TGUIStyleSheetStackHandle;
          Color : RColor;
          Weight : EnumFontWeight;
          Stretch : EnumFontStretch;
          Style : EnumFontStyle;
          TextTransform : EnumTextTransform;
          words : AString;
        begin
          if length(sub) < 2 then exit('');
          Result := sub[1];
          rawClasses := sub[0].Split([' ']);

          ClassHierarchy := TClassHierarchy.Create;

          Classes := TClassHierarchyNode.Create;
          Classes.Add(RClassTag.Create(FGUI.StyleManager.ResolveClassname('span'), [pcNone, pcFirstChild, pcLastChild, pcEven]));
          for i := 0 to length(rawClasses) - 1 do
              Classes.Add(RClassTag.Create(FGUI.StyleManager.ResolveClassname('.' + rawClasses[i]), [pcNone, pcFirstChild, pcLastChild, pcEven]));

          ClassHierarchy.Add(Classes);

          StyleStack := FGUI.StyleManager.BuildStyleStack(ClassHierarchy);

          if StyleStack.StyleSheetStack.TryGetValue<EnumTextTransform>(gtTextTransform, 0, TextTransform) then
            case TextTransform of
              ttNone :;
              ttUppercase : Result := Result.ToUpper;
              ttLowercase : Result := Result.ToLower;
              ttCapitalize :
                begin
                  words := Result.Split([' ']);
                  for i := 0 to length(words) - 1 do
                    if length(words[i]) >= 1 then
                        words[i] := string(words[i][1]).ToUpper + words[i].Remove(0, 1);
                  Result := HString.Join(words, ' ');
                end;
            end;

          if StyleStack.StyleSheetStack.TryGetValue<RColor>(gtFontcolor, 0, Color) then
              Result := '|c' + Color.ToHexString(6, False) + Result + '|r';
          if StyleStack.StyleSheetStack.TryGetValue<EnumFontWeight>(gtFontWeight, 0, Weight) then
              Result := '|b' + HString.IntMitNull(ord(Weight) * 100, 4) + Result + '|r';
          if StyleStack.StyleSheetStack.TryGetValue<EnumFontStretch>(gtFontStretch, 0, Stretch) then
              Result := '|s' + HString.IntMitNull(ord(Stretch) * 100, 3) + Result + '|r';
          if StyleStack.StyleSheetStack.TryGetValue<EnumFontStyle>(gtFontStyle, 0, Style) then
          begin
            if (Style = fsItalic) then
                Result := '|i' + Result + '|r'
            else if (Style = fsOblique) then
                Result := '|o' + Result + '|r';
          end;

          StyleStack.Free;
          ClassHierarchy.Free;
        end
        );
    end;

    // apply transformations
    Result := Result.Replace('\n', sLineBreak);

    case GetStyleValue<EnumTextTransform>(gtTextTransform) of
      ttNone :;
      ttUppercase : Result := ChangeCase(Result, True);
      ttLowercase : Result := ChangeCase(Result, False);
      ttCapitalize :
        begin
          words := Result.Split([' ']);
          for i := 0 to length(words) - 1 do
            if length(words[i]) >= 1 then
                words[i] := string(words[i][1]).ToUpper + words[i].Remove(0, 1);
          Result := HString.Join(words, ' ');
        end;
    end
  end
  else
      Result := '';
end;

procedure TGUIComponent.Traverse(const method : ProcTraverse);
var
  i : integer;
begin
  method(self);
  for i := 0 to ChildCount - 1 do
      GetChild(i).Traverse(method);
end;

function TGUIComponent.TryGetDescendantComponentByName(const Name : string; out Element : TGUIComponent) : boolean;
begin
  Element := GetDescendantComponentByName(name);
  Result := assigned(Element);
end;

function TGUIComponent.TryGetDescendantElementByName<T>(const Name : string; out Element : T) : boolean;
var
  res : TGUIComponent;
begin
  res := GetDescendantComponentByName(name);
  if res is T then
      Element := T(res);
  Result := assigned(Element) and (res is T);
end;

function TGUIComponent.TryGetParentComponentByName(const Name : string; out Element : TGUIComponent) : boolean;
begin
  if Parent = nil then exit(False);
  if CompareText(Parent.Name, name) = 0 then
  begin
    Result := True;
    Element := Parent;
  end
  else
      Result := Parent.TryGetParentComponentByName(name, Element);
end;

procedure TGUIComponent.BuildClassHierarchy;
var
  Classes : TClassHierarchyNode;
  PseudoClasses : SetPseudoClass;
  i : integer;
begin
  if not FClassHierarchyDirty then exit;
  FClassHierarchy.Free;
  if self.HasParent then
  begin
    Parent.BuildClassHierarchy;
    FClassHierarchy := Parent.FClassHierarchy.Clone;
  end
  else
      FClassHierarchy := TClassHierarchy.Create;
  Classes := TClassHierarchyNode.Create;
  PseudoClasses := self.PseudoClasses;
  for i := 0 to FClasses.Count - 1 do
      Classes.Add(RClassTag.Create(FClasses[i], PseudoClasses));
  Classes.Add(RClassTag.Create(FGUI.StyleManager.ResolveClassname(GSS_NAME_PREFIX + name), PseudoClasses));
  Classes.Add(RClassTag.Create(FGUI.StyleManager.ResolveClassname(ElementName), PseudoClasses));
  Classes.Add(RClassTag.Create(FGUI.StyleManager.ResolveClassname(GSS_ALL_CLASS), PseudoClasses));
  FClassHierarchy.Add(Classes);
  FClassHierarchyDirty := False;
end;

function TGUIComponent.BuildDirtyFlagInheritance(const Tags : SetGSSTag) : SetGSSTag;
const
  DIRECT_INHERITANCE : SetGSSTag = [gtPosition, gtFontcolor, gtBlurColor, gtOpacity, gtZOffset];
  FULL_INHERITANCE : SetGSSTag   = [
    gtSize, gtMinSize, gtMaxSize,
    gtStackorientation, gtStackpartitioning, gtStackcolumns, gtPadding, gtMargin,
    gtProgressposition, gtProgressmaximum, gtParentOffset, gtOverflow, gtBoxSizing,
    gtDefaultText, gtText, gtTextTransform, gtFontfamily, gtFontsize, gtFontWeight,
    gtFontStyle, gtFontStretch
    ];
begin
  Result := [];
  if Tags * DIRECT_INHERITANCE <> [] then
      Result := Result + Tags * DIRECT_INHERITANCE;
  if Tags * [gtAnchor, gtParentAnchor] <> [] then
      Result := Result + [gtPosition, gtAnchor, gtParentAnchor];
  if Tags * FULL_INHERITANCE <> [] then
      Result := Result + CHILDRENAFFECTINGTAGS;
end;

procedure TGUIComponent.BuildFindMultiSet(ComponentSet : TGUIComponentSet; Query : string);
var
  i : integer;
begin
  if not assigned(self) then exit;
  if (CompareText(FName, Query) = 0) then ComponentSet.Add(self);

  for i := 0 to FChildren.Count - 1 do
      FChildren[i].BuildFindMultiSet(ComponentSet, Query);
end;

procedure TGUIComponent.BuildStyleSheetStack;
var
  FormerStack : TGUIStyleSheetStackHandle;
  ChangedTags : SetGSSTag;
begin
  BuildClassHierarchy;
  FormerStack := FStyleSheetStack;
  FStyleSheetStack := FGUI.StyleManager.BuildStyleStack(FClassHierarchy);
  if assigned(FormerStack) and FormerStack.IsValid then
  begin
    if FormerStack.StyleSheetStack.Hash <> FStyleSheetStack.StyleSheetStack.Hash then
        ChangedTags := FormerStack.StyleSheetStack.ChangedTags(FStyleSheetStack.StyleSheetStack)
    else
        ChangedTags := [];
  end
  else
      ChangedTags := FStyleSheetStack.StyleSheetStack.CoveredTags;
  // only tags that weren't present before and after are ensured to have no changes
  SetDirty(ChangedTags + BuildDirtyFlagInheritance(ChangedTags));
  FStyleSheetStackDirty := False;
  FormerStack.Free;
end;

function TGUIComponent.TryGetStyleValue<T>(Stylename : EnumGSSTag; out Value : T; Index : integer) : boolean;
begin
  if Stylename in FStyleSheet.CoveredTags then
      Result := FStyleSheet.TryGetValue<T>(Stylename, index, Value)
  else
      Result := False;
  if not UsesOnlyInlineStyles then
  begin
    CheckAndBuildStyleSheetStack;
    // if no inline style is present check stylestack
    if not Result and assigned(FStyleSheetStack) and (Stylename in FStyleSheetStack.StyleSheetStack.CoveredTags) then
        Result := FStyleSheetStack.StyleSheetStack.TryGetValue<T>(Stylename, index, Value);
    // if style is inherited and no one found look at root for globals
    if not Result and (Stylename in ROOT_INHERITED_TAGS) and (FGUI.DOMRoot <> self) then
        Result := FGUI.DOMRoot.TryGetStyleValue<T>(Stylename, Value, index);
  end;
end;

procedure TGUIComponent.StartAnimation;
begin
  ResetCurrentAnimationKey;
  FAnimationPaused := False;
  FAnimationStartTimestamp := TimeManager.GetTimeStamp;
end;

procedure TGUIComponent.StartAnimationRecursive;
var
  i : integer;
begin
  StartAnimation;
  for i := 0 to FChildren.Count - 1 do
      FChildren[i].StartAnimationRecursive;
end;

function TGUIComponent.StyleValueCount(Stylename : EnumGSSTag) : integer;
begin
  if Stylename in FStyleSheet.CoveredTags then
      Result := FStyleSheet.ValueCount(Stylename)
  else
      Result := 0;
  if not UsesOnlyInlineStyles then
  begin
    CheckAndBuildStyleSheetStack;
    // if no inline style is present check stylestack
    if (Result = 0) and assigned(FStyleSheetStack) and (Stylename in FStyleSheetStack.StyleSheetStack.CoveredTags) then
        Result := FStyleSheetStack.StyleSheetStack.ValueCount(Stylename);
    // if style is inherited and no one found look at root
    if (Result = 0) and (Stylename in ROOT_INHERITED_TAGS) and (FGUI.DOMRoot <> self) then
        Result := FGUI.DOMRoot.StyleValueCount(Stylename);
  end;
end;

procedure TGUIComponent.SubscribeToEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent);
begin
  FGUI.SubscribeToEvent(Event, Callback, self);
end;

function TGUIComponent.TryIndexOfChildWithData(Data : NativeUInt; Index : integer) : boolean;
begin
  index := IndexOfChildWithData(Data);
  Result := index >= 0;
end;

function TGUIComponent.TryResolveSize(const SpaceData : RGSSSpaceData; const Dim : integer; out NewSize : single) : boolean;
var
  OtherDim : integer;
begin
  OtherDim := (Dim + 1) mod 2;
  Result := False;
  if (SpaceData.IsRelativeContainerWidth and (Dim = 1)) or
    (SpaceData.IsRelativeContainerHeight and (Dim = 0)) then
  begin
    Result := True;
    NewSize := FRect.Dim[OtherDim] * SpaceData.Value;
  end
  else if SpaceData.IsRelativeViewWidth then
  begin
    Result := True;
    NewSize := FGUI.ViewSize.Width * SpaceData.Value;
  end
  else if SpaceData.IsRelativeViewHeight then
  begin
    Result := True;
    NewSize := FGUI.ViewSize.Height * SpaceData.Value;
  end
  else if SpaceData.IsRelativeScreenWidth then
  begin
    Result := True;
    NewSize := FGUI.Scene.Size.Width * SpaceData.Value;
  end
  else if SpaceData.IsRelativeScreenHeight then
  begin
    Result := True;
    NewSize := FGUI.Scene.Size.Height * SpaceData.Value;
  end
  else if SpaceData.IsRelativeBackgroundWidth and assigned(FBgTexture.Default) then
  begin
    Result := True;
    NewSize := FBgTexture.Default.Width * SpaceData.Value * GUI.VirtualSizeModifier.X;
  end
  else if SpaceData.IsRelativeBackgroundHeight and assigned(FBgTexture.Default) then
  begin
    Result := True;
    NewSize := FBgTexture.Default.Height * SpaceData.Value * GUI.VirtualSizeModifier.Y;
  end
  else if HasParent and SpaceData.IsRelativeParentWidth then
  begin
    Result := True;
    NewSize := ParentRect.Width * SpaceData.Value;
  end
  else if HasParent and SpaceData.IsRelativeParentHeight then
  begin
    Result := True;
    NewSize := ParentRect.Height * SpaceData.Value;
  end
  else if HasParent and SpaceData.IsRelative then
  begin
    Result := True;
    NewSize := ParentRect.Dim[Dim] * SpaceData.Value;
  end
  else if SpaceData.IsAbsolute then
  begin
    Result := True;
    NewSize := SpaceData.Value * GUI.VirtualSizeModifier.Element[Dim];
  end
end;

procedure TGUIComponent.UnsubscribeFromEvent(Event : EnumGUIEvent; Callback : ProcGUIEvent);
begin
  FGUI.UnsubscribeFromEvent(Event, Callback, self);
end;

procedure TGUIComponent.UpdateFont;
var
  tempFontDesc : RFontDescription;
  fontBorder : RFontBorder;
  fontSize : RGSSSpaceData;
begin
  if not assigned(FFont) then
  begin
    FFont := TVertexFont.Create(VertexEngine, RFontDescription.Create(DefaultFontFamily));
    FFont.DrawsAtStage := rsGUI;
    FFont.Visible := True;
    FFont.Color := $FF000000;
  end;

  tempFontDesc := FFont.FontDescription;
  fontSize := GetStyleValue<RGSSSpaceData>(gtFontsize);
  tempFontDesc.Height := fontSize.Resolve(1, ContentRect, ParentRect);
  if tempFontDesc.Height <= 0 then
      tempFontDesc.Height := 24;

  tempFontDesc.FontFamily := GetStyleValue<string>(gtFontfamily);
  tempFontDesc.Weight := GetStyleValue<EnumFontWeight>(gtFontWeight);
  tempFontDesc.Style := GetStyleValue<EnumFontStyle>(gtFontStyle);
  tempFontDesc.Stretch := GetStyleValue<EnumFontStretch>(gtFontStretch);
  tempFontDesc.Quality := GetStyleValue<EnumFontQuality>(gtFontQuality);

  // adjust ZOffset for Text rendered after background
  FFont.DrawOrder := ZOffset * 2 + 1;
  FFont.FontDescription := tempFontDesc;
  FFont.Format := GetStyleValue<SetFontRenderingFlags>(gtFontflags);
  FFont.Resolution := GetStyleValue<single>(gtFontResolution);

  fontBorder.Width := GetStyleValue<single>(gtFontBorder, 0);
  fontBorder.Color := GetStyleValue<RColor>(gtFontBorder, 1);
  FFont.fontBorder := fontBorder;

  FFontColor := GetStyleValue<RColor>(gtFontcolor);
end;

function TGUIComponent.UpdateStyleText(const Text : string) : boolean;
begin
  Result := Text <> FLastStyleText;
  if Result then
  begin
    FLastStyleText := Text;
    FStyleText := TransformRawText(Text);
  end;
end;

function TGUIComponent.UpdateText(const Text : string) : boolean;
begin
  Result := Text <> FLastText;
  if Result then
  begin
    FLastText := Text;
    FText := TransformRawText(Text);
  end;
end;

function TGUIComponent.UsesOnlyInlineStyles : boolean;
begin
  Result := FDrawSpace in [dsWorldSpace, dsWorldScreenSpace];
end;

function TGUIComponent.VirtualParent : TGUIComponent;
var
  i : integer;
begin
  Result := self.Parent;
  for i := 0 to FParentOffset - 1 do
  begin
    if Result.HasParent then Result := Result.Parent
    else break;
  end;
end;

function TGUIComponent.VisibleToggle : boolean;
begin
  Result := not Visible;
  Visible := Result;
end;

function TGUIComponent.ZOffset : integer;
begin
  Result := 1 + FZOffset;
  if HasParent then
      Result := Result + Parent.ZOffset;
end;

{ TGUIStyleSheet }

function TGUIStyleSheet.AddOrSetValue<T>(Stylename : EnumGSSTag; Index : integer; const Value : T) : boolean;
var
  Values : TList<RParam>;
  i : integer;
begin
  Result := False;
  Values := FData[Stylename];
  if not assigned(Values) then
  begin
    Values := TList<RParam>.Create;
    include(FCoveredTags, Stylename);
    FData[Stylename] := Values;
    Result := True;
  end;
  if Values.Count <= index then
  begin
    Result := True;
    for i := Values.Count to index do Values.Add(RParamEmpty);
  end
  else
      Result := Result or not(Values[index] = RParam.FromWithType<T>(Value));
  if Result then
      Values[index] := RParam.FromWithType<T>(Value);
end;

procedure TGUIStyleSheet.AddDataAsText(const Data : string);
begin
  ImportDataAsText(Data);
end;

procedure TGUIStyleSheet.AddDefinitionsFromStyleSheet(const AnotherStylesheet : TGUIStyleSheet; OverrideExisting : boolean);
var
  Tag : EnumGSSTag;
  i : integer;
  NewValues, Values : TList<RParam>;
begin
  for Tag := low(EnumGSSTag) to high(EnumGSSTag) do
    if (Tag in AnotherStylesheet.CoveredTags) then
    begin
      NewValues := AnotherStylesheet.FData[Tag];
      Values := FData[Tag];
      if assigned(NewValues) and (NewValues.Count > 0) then
      begin
        if not assigned(Values) then
        begin
          Values := TList<RParam>.Create;
          FData[Tag] := Values;
        end;
        for i := 0 to NewValues.Count - 1 do
        begin
          if Values.Count <= i then
              Values.Add(NewValues[i])
          else if Values[i].IsEmpty or (OverrideExisting and not NewValues[i].IsEmpty) then
              Values[i] := NewValues[i];
        end;
        include(FCoveredTags, Tag);
      end;
    end;
end;

function TGUIStyleSheet.AddOrSetValue<T>(Stylename : EnumGSSTag; Value : array of T) : boolean;
var
  Values : TList<RParam>;
  i : integer;
begin
  Result := False;
  Values := FData[Stylename];
  if not assigned(Values) then
  begin
    Values := TList<RParam>.Create;
    include(FCoveredTags, Stylename);
    FData[Stylename] := Values;
    Result := True;
  end;
  for i := 0 to length(Value) - 1 do
  begin
    if i >= Values.Count then
    begin
      Result := True;
      Values.Add(RParam.FromWithType<T>(Value[i]));
    end
    else
    begin
      Result := Result or not(Values[i] = RParam.FromWithType<T>(Value[i]));
      if Result then Values[i] := RParam.FromWithType<T>(Value[i]);
    end;
  end;
end;

function TGUIStyleSheet.AddOrSetValue<T>(Stylename : EnumGSSTag; const Value : T) : boolean;
begin
  Result := AddOrSetValue<T>(Stylename, 0, Value);
end;

constructor TGUIStyleSheet.Create(GUI : TGUI);
begin
  Create;
  FGUI := GUI;
end;

constructor TGUIStyleSheet.Create;
begin
  FID := TGUIStyleSheet.StyleSheetIDCounter;
  inc(TGUIStyleSheet.StyleSheetIDCounter);
end;

constructor TGUIStyleSheet.CreateFromFile(const Filename : string; GUI : TGUI = nil);
begin
  CreateFromText(string(HString.FileToString(Filename)), GUI);
end;

constructor TGUIStyleSheet.CreateFromText(const gss : string; GUI : TGUI = nil);
begin
  Create(GUI);
  DataAsText := gss;
end;

class function TGUIStyleSheet.TryCSSStrToFloat(Value : string; out ParsedValue : single) : boolean;
var
  IsDeg : boolean;
begin
  if Value.StartsWith('.') then
      Value := '0' + Value;
  IsDeg := Value.EndsWith('deg', True);
  Value := Value.TrimRight(['p', 'x', 'd', 'e', 'g']);
  if TryStrToFloat(Value, ParsedValue, EngineFloatFormatSettings) then
  begin
    if IsDeg then
        ParsedValue := DegToRad(ParsedValue);
    Result := True;
  end
  else
      Result := False;
end;

class function TGUIStyleSheet.CSSStrToFloat(const Value : string; Default : single) : single;
begin
  if not TryCSSStrToFloat(Value, Result) then
      Result := default;
end;

destructor TGUIStyleSheet.Destroy;
begin
  HArray.FreeAllObjects < TList < RParam >> (FData);
  inherited;
end;

function TGUIStyleSheet.getDataAsText : string;
var
  Key : EnumGSSTag;
  Values : TList<RParam>;
  i, loopend : integer;
begin
  Result := '';
  // iterate over all items to ensure fix ordering at save
  for Key := low(EnumGSSTag) to high(EnumGSSTag) do
    if assigned(FData[Key]) then
    begin
      Values := FData[Key];
      Result := Result + HRTTI.EnumerationToString<EnumGSSTag>(Key).Substring(2) + ' : ';
      loopend := Max(Values.Count, HGeneric.TertOp<integer>(Key in [gtPadding, gtMargin], 4, 0)) - 1;
      for i := 0 to loopend do
      begin
        if (i >= Values.Count) or (Values[i].IsEmpty) then Result := Result + 'empty'
        else if Values[i].IsType<RGSSSpaceData> then Result := Result + Values[i].AsType<RGSSSpaceData>
        else Result := Result + Values[i].ToString;
        if i <> loopend then Result := Result + ' ';
      end;
      Result := Result + ';' + sLineBreak;
    end;
end;

function TGUIStyleSheet.GetDefaultValue(Style : EnumGSSTag; Index : integer) : RParam;
begin
  case Style of
    gtBackground, gtBackgroundHover, gtBackgroundDown, gtBackgroundDisabled, gtBackgroundMask, gtBlurMask, gtItemTemplate,
      gtSceneName, gtText, gtDefaultText, gtHint, gtFrameFile, gtHintTemplate, gtHintClasses, gtBackgroundShader,
      gtAnimationName, gtTransform : Result := '';
    gtPosition, gtPadding, gtMargin, gtHintOffset : Result := RGSSSpaceData.CreateAbsolute(0);
    gtDrawSpace : Result := RParam.From<EnumDrawSpace>(dsScreenSpace);
    gtSize : Result := RGSSSpaceData.CreateAbsolute(100);
    gtAnchor, gtStackAnchor, gtParentAnchor : Result := RParam.From<EnumComponentAnchor>(caTopLeft);
    gtHintAnchor, gtTransformAnchor : Result := RParam.From<EnumComponentAnchor>(caAuto);
    gtTransformOrder : Result := RParam.From<EnumTransformOrder>(toTransformAnimation);
    gtEnabled, gtBlur, gtBlurLayer, gtTransformKeepBackground : Result := False;
    gtMouseEvents : Result := RParam.From<EnumMouseEvent>(meAll);
    gtVisibility, gtTransitionWithInheritance, gtOpacityInheritance, gtTransformInheritance,
      gtBackgroundColorOverrideInheritance : Result := True;
    gtBackgroundMipMapping : Result := RParam.From<EnumMipMapHandling>(mhGenerate);
    gtBackgroundrepeat : Result := RParam.From<EnumBackgroundRepeat>(brStretch);
    gtBackgroundAnchor : Result := RParam.From<EnumBackgroundAnchor>(baTopLeft);
    gtOverflow : Result := RParam.From<EnumOverflowHandling>(ohNone);
    gtFontsize : Result := RGSSSpaceData.CreateAbsolute(24);
    gtTextTransform : Result := RParam.From<EnumTextTransform>(ttNone);
    gtCursor : Result := RParam.From<EnumCursor>(crDefault);
    gtBorder, gtFontBorder, gtOutline :
      begin
        case index of
          0 : if Style = gtFontBorder then Result := 0.0
            else Result := RGSSSpaceData.CreateAbsolute(0.0);
          1 : Result := RColor.CBLACK;
          2 : Result := RColor.CBLACK;
          3 : if Style = gtBorder then Result := RParam.From<EnumBorderLocation>(blInset)
            else Result := RParam.From<EnumBorderLocation>(blOutline);
        end;
      end;
    gtBorderImage :
      begin
        case index of
          0 : Result := '';
        else
          Result := 0;
        end;
      end;
    gtBoxSizing : Result := RParam.From<EnumBoxSizing>(bsContent);
    gtParentBox : Result := RParam.From<EnumParentBox>(pbContent);
    gtFontfamily : Result := DefaultFontFamily;
    gtFontWeight : Result := RParam.From<EnumFontWeight>(fwRegular);
    gtFontStyle : Result := RParam.From<EnumFontStyle>(fsNormal);
    gtFontStretch : Result := RParam.From<EnumFontStretch>(fsRegular);
    gtFontQuality : Result := RParam.From<EnumFontQuality>(fqAntiAliased);
    gtFontflags : Result := RParam.From<SetFontRenderingFlags>([]);
    gtBorderSides, gtOutlineSides : Result := RParam.From<SetBorderSides>([low(EnumBorderSides) .. high(EnumBorderSides)]);
    gtFontcolor : Result := RColor.Create($FF000000);
    gtBackgroundColor, gtBackgroundColorOverride, gtBlurColor, gtBackgroundColorHover, gtBackgroundColorDown,
      gtBackgroundColorDisabled : Result := RColor.CTRANSPARENTBLACK;
    gtScrollbarBackgroundColor, gtScrollbarBackgroundColorHover, gtScrollbarBackgroundColorElementHover : Result := RColor.Create($80000000);
    gtScrollbarColor, gtScrollbarColorHover, gtScrollbarColorElementHover : Result := RColor.Create($80FFFFFF);
    gtScrollbarWidth : Result := 10;
    gtStackorientation : Result := RParam.From<EnumStackOrientation>(soHorizontal);
    gtStackpartitioning : Result := RGSSSpaceData.CreateRelative(1);
    gtStackcolumns : Result := HGeneric.TertOp<integer>(index = 0, 10000, 0);
    gtProgressposition, gtBackgroundMipMapLodBias : Result := 0.0;
    gtProgressmaximum, gtOpacity, gtZoom, gtFontResolution : Result := 1.0;
    gtProgressshape : Result := RParam.From<EnumProgressShape>(psNone);
    gtZOffset, gtParentOffset, gtAnimationOffset, gtAnimationDelay, gtAnimationDuration,
      gtTransitionDuration, gtAnimationIterationCount, gtScrollbarPadding, gtSceneSuperSampling : Result := 0;
    gtAnimationBackgroundSpriteSize, gtAnimationBackgroundSpriteCount : Result := 1;
    gtTextMaxLength : Result := -1;
    gtObscureText : Result := Char(' ');
    gtMinSize, gtMaxSize : Result := RParamEmpty;
    gtAnimationDirection : Result := RParam.From<EnumAnimationDirection>(adNormal);
    gtAnimationFillMode : Result := RParam.From<EnumAnimationFillMode>(afNone);
    gtTransitionProperty : Result := RParam.From<EnumGSSTag>(gtNone);
    gtSceneCamera :
      begin
        case index of
          0, 1, 2 : Result := 10.0;
        else
          Result := 0.0;
        end;
      end;
    gtAnimationTimingFunction, gtTransitionTimingFunction :
      begin
        case index of
          0 : Result := 0.0;
          1 : Result := 0.0;
          2 : Result := 1.0;
          3 : Result := 1.0;
        end;
      end;
  else
    HLog.Write(elError, 'There is no default Value for ' + HRTTI.EnumerationToString<EnumGSSTag>(Style) + '!', ENotSupportedException);
  end;
end;

function TGUIStyleSheet.GetDefaultValue<T>(Style : EnumGSSTag; Index : integer) : T;
var
  res : RParam;
begin
  res := GetDefaultValue(Style, index);
  if res.IsEmpty then exit(default (T));
  if TypeInfo(T) = TypeInfo(string) then PString(@Result)^ := res.AsString
  else Result := res.AsType<T>;
end;

procedure TGUIStyleSheet.ImportDataAsText(gss : string);
const
  SINGLE_VALUE_PARAMETERS = [gtBackground, gtBackgroundHover, gtBackgroundDown, gtBackgroundDisabled,
    gtDefaultText, gtText, gtHint, gtHintTemplate, gtHintClasses, gtFontfamily, gtFrameFile, gtTransform];
var
  Regex : TRegex;
  Matches : TMatchCollection;
  Match : TMatch;
  TagString : string;
  Tag : EnumGSSTag;
  Values, FormerValues : TList<RParam>;
  Value : RParam;
  ValuesString, ValueString : string;
  Strings : TArray<string>;
  i, Index, IndexOverride : integer;
begin
  gss := gss.Replace(#10, '').Replace(#13, '');
  Regex := TRegex.Create('([^:;]+):([^:;]+);', [roIgnoreCase]);
  Matches := Regex.Matches(gss);
  for Match in Matches do
  begin
    TagString := HString.TrimBoth(' ', Match.Groups.item[1].Value).ToLowerInvariant;
    if TagString = '' then continue;
    // check for synonyms
    if TagString = 'width' then TagString := 'size-x';
    if TagString = 'height' then TagString := 'size-y';
    if TagString = 'minwidth' then TagString := 'minsize-x';
    if TagString = 'minheight' then TagString := 'minsize-y';
    if TagString = 'maxwidth' then TagString := 'maxsize-x';
    if TagString = 'maxheight' then TagString := 'maxsize-y';
    if TagString = 'animation-name' then TagString := 'animationname';
    if TagString = 'animation-duration' then TagString := 'animationduration';
    if TagString = 'animation-timing-function' then TagString := 'animationtimingfunction';
    if TagString = 'animation-delay' then TagString := 'animationdelay';
    if TagString = 'animation-iteration-count' then TagString := 'animationiterationcount';
    if TagString = 'animation-direction' then TagString := 'animationdirection';
    if TagString = 'animation-fill-mode' then TagString := 'animationfillmode';

    // check for subindices
    if HString.ContainsSubstring(['-top', '-x'], TagString) then IndexOverride := 0
    else if HString.ContainsSubstring(['-right', '-y'], TagString) then IndexOverride := 1
    else if HString.ContainsSubstring(['-bottom', '-z'], TagString) then IndexOverride := 2
    else if HString.ContainsSubstring(['-left', '-w'], TagString) then IndexOverride := 3
    else IndexOverride := -1;
    if IndexOverride >= 0 then TagString := HString.TrimAfter('-', TagString);

    // parse tag and its values
    if HRTTI.TryStringToEnumeration<EnumGSSTag>('gt' + TagString, Tag) then
    begin
      Values := TList<RParam>.Create;
      ValuesString := HString.TrimBoth(' ', Match.Groups.item[2].Value);
      // read full string for single-valued parameters
      if (Tag in SINGLE_VALUE_PARAMETERS) then
      begin
        Value := ValuesString;
        Values.Add(Value);
      end
      // split parameters by space and parse each individual
      else
      begin
        ValuesString := HString.DeleteDoubleSpaces(ValuesString);
        if not TryResolveConstantValues(Tag, ValuesString.ToLowerInvariant, Values) then
        begin
          Strings := ValuesString.Split([' ']);
          for i := 0 to length(Strings) - 1 do
          begin
            ValueString := Strings[i];
            if IndexOverride >= 0 then index := IndexOverride
            else index := i;
            // Parse tag value
            Value := ParseGSSParamToValue(Tag, ValueString, index);
            if IndexOverride >= 0 then
            begin
              // position value into correct index, then break as subindices are single valued
              for index := 0 to IndexOverride - 1 do Values.Add(RParamEmpty);
              Values.Add(Value);
              break;
            end;
            Values.Add(Value);
          end;
        end;
        // expand padding and margin values
        if (Tag in [gtPadding, gtMargin, gtScrollbarPadding]) and not(IndexOverride >= 0) then
        begin
          // Padding: 15; => Padding: 15 15; will be complete expanded with the second if statement
          if Values.Count = 1 then Values.Add(Values[0]);
          // Padding: 15 10; => Padding: 15 10 15 10;
          if Values.Count = 2 then
          begin
            Values.Add(Values[0]);
            Values.Add(Values[1]);
          end;
        end;
      end;
      // override existing values with parsed values if not empty
      FormerValues := FData[Tag];
      if assigned(FormerValues) then
      begin
        for i := 0 to FormerValues.Count - 1 do
        begin
          if Values.Count <= i then Values.Add(FormerValues[i])
          else if Values[i].IsEmpty then Values[i] := FormerValues[i];
        end;
        FormerValues.Free;
      end;
      // finally set value block in style dict
      FData[Tag] := Values;
      include(FCoveredTags, Tag);
    end
    else PutError('Unknown tag: ' + TagString);
  end;
end;

function TGUIStyleSheet.Items : TDictionary<EnumGSSTag, RParam>;
var
  Tag : EnumGSSTag;
begin
  Result := TDictionary<EnumGSSTag, RParam>.Create;
  for Tag := low(FData) to high(FData) do
    if assigned(FData[Tag]) and (FData[Tag].Count >= 1) then
        Result.AddOrSetValue(Tag, FData[Tag][0]);
end;

function TGUIStyleSheet.ParseGSSParamToValue(const Tag : EnumGSSTag; const Value : string; const Index : integer) : RParam;
var
  temp : integer;
begin
  Result := RParamEmpty;
  // save empty in value if empty or initial, will be fallen back to default value
  if not HArray.Contains(['empty', 'initial'], Value.ToLowerInvariant) then
  begin
    try
      case Tag of
        // RGSSSpaceData
        gtPosition, gtHintOffset, gtSize, gtMinSize, gtMaxSize, gtStackpartitioning, gtPadding, gtMargin, gtFontsize : Result := RGSSSpaceData.CreateFromString(Value);
        // EnumDrawSpace
        gtDrawSpace : Result := RParam.From<EnumDrawSpace>(HRTTI.StringToEnumeration<EnumDrawSpace>(Value, False));
        // string
        gtBackground, gtBackgroundHover, gtBackgroundDown, gtBackgroundDisabled, gtBackgroundMask, gtItemTemplate, gtText, gtHint,
          gtFontfamily, gtFrameFile, gtBlurMask, gtBackgroundShader, gtAnimationName, gtTransform, gtSceneName : Result := Value;
        // Char
        gtObscureText : if length(Value) > 0 then Result := string(Value[1])
          else Result := Char(' ');
        // EnumComponentAnchor
        gtAnchor, gtParentAnchor, gtHintAnchor, gtStackAnchor, gtTransformAnchor : Result := RParam.From<EnumComponentAnchor>(HRTTI.StringToEnumeration<EnumComponentAnchor>(Value, False));
        // boolean
        gtEnabled, gtVisibility, gtBlur, gtBlurLayer, gtTransformKeepBackground, gtTransitionWithInheritance, gtOpacityInheritance,
          gtTransformInheritance, gtBackgroundColorOverrideInheritance : Result := StrToBool(Value);
        gtBackgroundMipMapping : Result := RParam.From<EnumMipMapHandling>(HRTTI.StringToEnumeration<EnumMipMapHandling>(Value, False));
        gtBackgroundrepeat : Result := RParam.From<EnumBackgroundRepeat>(HRTTI.StringToEnumeration<EnumBackgroundRepeat>(Value, False));
        gtBackgroundAnchor : Result := RParam.From<EnumBackgroundAnchor>(HRTTI.StringToEnumeration<EnumBackgroundAnchor>(Value, False));
        gtOverflow : Result := RParam.From<EnumOverflowHandling>(HRTTI.StringToEnumeration<EnumOverflowHandling>(Value, False));
        gtMouseEvents : Result := RParam.From<EnumMouseEvent>(HRTTI.StringToEnumeration<EnumMouseEvent>(Value, False));
        // RColor
        gtFontcolor, gtBackgroundColor, gtBackgroundColorOverride, gtBlurColor, gtBackgroundColorHover, gtBackgroundColorDown, gtBackgroundColorDisabled,
          gtScrollbarBackgroundColor, gtScrollbarBackgroundColorHover, gtScrollbarBackgroundColorElementHover,
          gtScrollbarColor, gtScrollbarColorHover, gtScrollbarColorElementHover : Result := RColor.Create(Value);
        // Integer
        gtZOffset, gtParentOffset, gtTextMaxLength, gtAnimationDelay, gtAnimationDuration, gtTransitionDuration, gtScrollbarWidth,
          gtAnimationOffset, gtAnimationIterationCount, gtSceneSuperSampling, gtAnimationBackgroundSpriteSize,
          gtAnimationBackgroundSpriteCount, gtScrollbarPadding : Result := StrToInt(Value);
        gtFontBorder, gtBorder, gtOutline :
          begin
            case index of
              0 : if Tag = gtFontBorder then Result := CSSStrToFloat(Value)
                else Result := RGSSSpaceData.CreateFromString(Value);
              1 : Result := RColor.Create(Value);
              2 : Result := RColor.Create(Value);
              3 : Result := RParam.From<EnumBorderLocation>(HRTTI.StringToEnumeration<EnumBorderLocation>(Value, False));
            end;
          end;
        gtBorderImage :
          begin
            case index of
              0 : Result := Value;
            else Result := StrToInt(Value);
            end;
          end;
        gtFontWeight :
          begin
            if TryStrToInt(Value, temp) then
            begin
              Result := RParam.From<EnumFontWeight>(ConvertFontWeight(temp));
            end
            else Result := RParam.From<EnumFontWeight>(HRTTI.StringToEnumeration<EnumFontWeight>('fw' + Value, False));
          end;
        gtFontStyle :
          begin
            Result := RParam.From<EnumFontStyle>(HRTTI.StringToEnumeration<EnumFontStyle>('fs' + Value, False));
          end;
        gtFontStretch :
          begin
            if TryStrToInt(Value, temp) then
            begin
              if temp < 100 then Result := RParam.From<EnumFontStretch>(fsUltraCondensed)
              else if temp < 200 then Result := RParam.From<EnumFontStretch>(fsExtraCondensed)
              else if temp < 300 then Result := RParam.From<EnumFontStretch>(fsCondensed)
              else if temp < 400 then Result := RParam.From<EnumFontStretch>(fsSemiCondensed)
              else if temp < 500 then Result := RParam.From<EnumFontStretch>(fsRegular)
              else if temp < 600 then Result := RParam.From<EnumFontStretch>(fsSemiExpanded)
              else if temp < 700 then Result := RParam.From<EnumFontStretch>(fsExpanded)
              else if temp < 800 then Result := RParam.From<EnumFontStretch>(fsExtraExpanded)
              else Result := RParam.From<EnumFontStretch>(fsUltraExpanded);
            end
            else Result := RParam.From<EnumFontStretch>(HRTTI.StringToEnumeration<EnumFontStretch>('fs' + Value, False));
          end;
        gtStackcolumns : Result := Max(0, StrToInt(Value));
        gtAnimationFillMode : Result := RParam.From<EnumAnimationFillMode>(HRTTI.StringToEnumeration<EnumAnimationFillMode>(Value, False));
        gtAnimationDirection : Result := RParam.From<EnumAnimationDirection>(HRTTI.StringToEnumeration<EnumAnimationDirection>(Value, False));
        gtBoxSizing : Result := RParam.From<EnumBoxSizing>(HRTTI.StringToEnumeration<EnumBoxSizing>(Value, False));
        gtParentBox : Result := RParam.From<EnumParentBox>(HRTTI.StringToEnumeration<EnumParentBox>(Value, False));
        gtFontQuality : Result := RParam.From<EnumFontQuality>(HRTTI.StringToEnumeration<EnumFontQuality>(Value, False));
        gtFontflags : Result := RParam.From<SetFontRenderingFlags>(HRTTI.StringToSet<SetFontRenderingFlags>(Value, False));
        gtBorderSides, gtOutlineSides : Result := RParam.From<SetBorderSides>(HRTTI.StringToSet<SetBorderSides>(Value, False));
        gtStackorientation : Result := RParam.From<EnumStackOrientation>(HRTTI.StringToEnumeration<EnumStackOrientation>(Value, False));
        gtTextTransform : Result := RParam.From<EnumTextTransform>(HRTTI.StringToEnumeration<EnumTextTransform>(Value, False));
        gtTransformOrder : Result := RParam.From<EnumTransformOrder>(HRTTI.StringToEnumeration<EnumTransformOrder>(Value, False));
        gtTransitionProperty : Result := RParam.From<EnumGSSTag>(HRTTI.StringToEnumeration<EnumGSSTag>(Value, False));
        gtCursor : Result := RParam.From<EnumCursor>(HRTTI.StringToEnumeration<EnumCursor>(Value, False));
        // single
        gtProgressposition, gtProgressmaximum, gtOpacity, gtZoom, gtBackgroundMipMapLodBias, gtAnimationTimingFunction,
          gtTransitionTimingFunction, gtSceneCamera, gtFontResolution : Result := CSSStrToFloat(Value);
        gtProgressshape : Result := RParam.From<EnumProgressShape>(HRTTI.StringToEnumeration<EnumProgressShape>(Value, False));
      else PutError('No parseinformation for tag (punch Tobi): ' + HRTTI.EnumerationToString<EnumGSSTag>(Tag));
      end;
    except
      PutError(Format('Error at parsing value from tag %s (Value:<%s> Index:%d', [HRTTI.EnumerationToString<EnumGSSTag>(Tag), Value, index]));
    end;
  end;
end;

procedure TGUIStyleSheet.PutError(const msg : string);
begin
  if assigned(FGUI) then FGUI.PutError(msg);
end;

class function TGUIStyleSheet.ResolveTransform(const TransformValue : string) : RMatrix4x3;
var
  method : string;
  methods : TArray<string>;
  Parameters : TArray<string>;
  sp : TArray<single>;
  i, j : integer;
begin
  Result := RMatrix4x3.IDENTITY;
  if TransformValue <> '' then
  begin
    methods := TransformValue.Replace(', ', ',').Split([' ']);
    for j := 0 to length(methods) - 1 do
    begin
      method := HString.TrimAfter('(', methods[j]).ToLowerInvariant;
      Parameters := HString.TrimAfter(')', HString.TrimBefore('(', methods[j])).Replace(' ', '').Split([',']);
      setLength(sp, length(Parameters));
      for i := 0 to length(Parameters) - 1 do
          sp[i] := CSSStrToFloat(Parameters[i], 0);

      if (method = 'matrix') and (length(sp) >= 6) then
      begin
        Result := Result * RMatrix4x3.Create([sp[0], sp[1], 0, sp[2], sp[3], sp[4], 0, sp[5], 0, 0, 1, 0]);
      end
      else if (method = 'matrix3d') and (length(sp) >= 12) then
      begin
        Result := Result * RMatrix4x3.Create(sp);
      end
      else if (method = 'translate') and (length(Parameters) >= 1) then
      begin
        if length(Parameters) < 2 then
            Result := Result * RMatrix4x3.CreateTranslation(RVector3.Create(sp[0], sp[0], 0))
        else
            Result := Result * RMatrix4x3.CreateTranslation(RVector3.Create(sp[0], sp[1], 0))
      end
      else if (method = 'translate3d') and (length(Parameters) >= 3) then
      begin
        Result := Result * RMatrix4x3.CreateTranslation(RVector3.Create(sp[0], sp[1], sp[2]));
      end
      else if (method = 'translatex') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateTranslation(RVector3.Create(sp[0], 0, 0));
      end
      else if (method = 'translatey') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateTranslation(RVector3.Create(0, sp[0], 0));
      end
      else if (method = 'translatez') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateTranslation(RVector3.Create(0, 0, sp[0]));
      end
      else if (method = 'scale') and (length(Parameters) >= 1) then
      begin
        if length(Parameters) < 2 then
            Result := Result * RMatrix4x3.CreateScaling(RVector3.Create(sp[0], sp[0], 1))
        else
            Result := Result * RMatrix4x3.CreateScaling(RVector3.Create(sp[0], sp[1], 1));
      end
      else if (method = 'scale3d') and (length(Parameters) >= 3) then
      begin
        Result := Result * RMatrix4x3.CreateScaling(RVector3.Create(sp[0], sp[1], sp[2]));
      end
      else if (method = 'scalex') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateScaling(RVector3.Create(sp[0], 1, 1));
      end
      else if (method = 'scaley') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateScaling(RVector3.Create(1, sp[0], 1));
      end
      else if (method = 'scalez') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateScaling(RVector3.Create(1, 1, sp[0]));
      end
      else if (method = 'rotate') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateRotationZ(sp[0]);
      end
      else if (method = 'rotate3d') and (length(Parameters) >= 4) then
      begin
        Result := Result * RMatrix4x3.CreateRotationAxis(RVector3.Create(sp[0], sp[1], sp[2]), sp[3]);
      end
      else if (method = 'rotatex') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateRotationX(sp[0]);
      end
      else if (method = 'rotatey') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateRotationY(sp[0]);
      end
      else if (method = 'rotatez') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateRotationZ(sp[0]);
      end
      else if (method = 'skew') and (length(Parameters) >= 1) then
      begin
        if length(Parameters) < 2 then
            Result := Result * RMatrix4x3.CreateSkew(RVector2.Create(sp[0], sp[0]))
        else
            Result := Result * RMatrix4x3.CreateSkew(RVector2.Create(sp[0], sp[1]));
      end
      else if (method = 'skewx') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateSkew(RVector2.Create(sp[0], 0));
      end
      else if (method = 'skewy') and (length(Parameters) >= 1) then
      begin
        Result := Result * RMatrix4x3.CreateSkew(RVector2.Create(0, sp[1]));
      end;
    end;
  end;
end;

procedure TGUIStyleSheet.setDataAsText(const Data : string);
begin
  HArray.FreeAndNilAllObjects < TList < RParam >> (FData);
  FCoveredTags := [];
  ImportDataAsText(Data);
end;

function TGUIStyleSheet.TryGetValue<T>(Stylename : EnumGSSTag; Index : integer; out Value : T) : boolean;
var
  Values : TList<RParam>;
begin
  Result := False;
  if assigned(FData[Stylename]) then
  begin
    Values := FData[Stylename];
    if (Values.Count > index) and not Values[index].IsEmpty then
    begin
      if TypeInfo(T) = TypeInfo(string) then PString(@Value)^ := Values[index].AsString
      else Value := Values[index].AsType<T>;
      Result := True;
    end;
  end;
end;

function TGUIStyleSheet.TryResolveConstantValues(const Tag : EnumGSSTag; const Value : string; Values : TList<RParam>) : boolean;
var
  Bezier : RCubicBezier;
begin
  Result := True;
  case Tag of
    gtAnimationIterationCount :
      begin
        if Value = 'infinite' then
            Values.Add(0)
        else
            Result := False;
      end;
    gtAnimationTimingFunction :
      begin
        if Value = 'linear' then
            Bezier := RCubicBezier.LINEAR
        else if Value = 'ease' then
            Bezier := RCubicBezier.EASE
        else if Value = 'ease-in' then
            Bezier := RCubicBezier.EASEIN
        else if Value = 'ease-out' then
            Bezier := RCubicBezier.EASEOUT
        else if Value = 'ease-in-out' then
            Bezier := RCubicBezier.EASEINOUT
        else
            Result := False;
        if Result then
        begin
          Values.Add(Bezier.P1X);
          Values.Add(Bezier.P1Y);
          Values.Add(Bezier.P2X);
          Values.Add(Bezier.P2Y);
        end;
      end;
  else
    Result := False;
  end;
end;

function TGUIStyleSheet.ValueCount(Stylename : EnumGSSTag) : integer;
begin
  if assigned(FData[Stylename]) then
      Result := FData[Stylename].Count
  else
      Result := 0;
end;

class constructor TGUIStyleSheet.Create;
begin
  StyleSheetIDCounter := 0;
end;

{ TGUIStackPanel }

procedure TGUIStackPanel.ApplyStyle(const ViewRect : RRectFloat);
var
  flowDirectionColumn, flowDirectionRow : single;
  FirstProcessedElement, autoColumnCount, wasScrollable : boolean;
  spaceLeft, availableSpace, Size, ContentSize, Pos, otherOffset, rowHeight, RelativeWeightsSum : single;
  columnCount : RIntVector2;
  paddingMove, StackPosition : RVector2;
  i, Dim, OtherDim, processedChildren, row, currentColumnFirst, currentColumnLast, maxRows, ChildCount, itemCountInRow, RowCount : integer;
  SpaceData : RGSSSpaceData;
  tempRect, childRect, ContentRect : RRectFloat;
  ChildrenInheritance : TArray<boolean>;
begin
  ComputeStackProperties;
  if gtStackAnchor in FDirty then
      FStackAnchor := GetStyleValue<EnumComponentAnchor>(gtStackAnchor);
  if gtStackpartitioning in FDirty then
      FAutomode := GetStyleValue<RGSSSpaceData>(gtStackpartitioning, 0).IsAuto;
  if gtPadding in FDirty then
  begin
    FPaddingXAuto := GetStyleValue<RGSSSpaceData>(gtPadding, 0).IsAuto;
    FPaddingYAuto := GetStyleValue<RGSSSpaceData>(gtPadding, 1).IsAuto
  end;

  // here our needed own size will be computed
  inherited ApplyStyle(ViewRect);

  if [gtStackorientation, gtStackpartitioning, gtStackcolumns, gtSize, gtMinSize, gtMaxSize, gtPosition, gtStackAnchor, gtPadding] * FDirty <> [] then
  begin
    // vertical aligns along y-axis first, horizontal along x-axis first
    if FStackOrientation = soVertical then Dim := 1
    else Dim := 0;
    OtherDim := (Dim + 1) mod 2;

    // compute flow direction
    if FStackOrientation = soHorizontal then
    begin
      // if bottom new rows upwards
      if FStackAnchor in [caBottomLeft, caBottom, caBottomRight] then flowDirectionRow := -1
      else flowDirectionRow := 1;
      // if right flow left
      if FStackAnchor in [caTopRight, caRight, caBottomRight] then flowDirectionColumn := -1
      else flowDirectionColumn := 1;
    end
    else
    begin
      // if right new rows to the left
      if FStackAnchor in [caTopRight, caRight, caBottomRight] then flowDirectionRow := -1
      else flowDirectionRow := 1;
      // if bottom flow up
      if FStackAnchor in [caBottomLeft, caBottom, caBottomRight] then flowDirectionColumn := -1
      else flowDirectionColumn := 1;
    end;

    // compute space
    ContentRect := self.ContentRect;
    availableSpace := ContentRect.Dim[Dim];
    columnCount.Element[Dim] := FStackColumns.X;
    // count visible and inheriting children to compute rowCount
    ChildCount := 0;
    setLength(ChildrenInheritance, FChildren.Count);
    for i := 0 to FChildren.Count - 1 do
    begin
      FChildren[i].ComputeVisibility;
      if FChildren[i].Visible then
      begin
        ChildrenInheritance[i] := FChildren[i].GetStyleValue<RGSSSpaceData>(gtPosition, Dim).IsInherit or
          FChildren[i].GetStyleValue<RGSSSpaceData>(gtPosition, OtherDim).IsInherit;
        if ChildrenInheritance[i] then inc(ChildCount);
      end;
    end;
    columnCount.Element[OtherDim] := (ChildCount div Max(1, FStackColumns.X));
    if ChildCount mod Max(1, FStackColumns.X) <> 0 then inc(columnCount.Element[OtherDim]);
    columnCount.Element[OtherDim] := Max(columnCount.Element[OtherDim], FStackColumns.Y);
    autoColumnCount := columnCount.Element[Dim] = 0;

    // in automode sizing of children is used to place them beside each other
    // otherwise specified sizing will be applied to the children
    // auto width stack ----------------------------------------------------------------------------------------------
    if FAutomode then
    begin
      otherOffset := 0;
      if (flowDirectionColumn < 0) and (Dim = 0) then StackPosition.X := ContentRect.Right
      else StackPosition.X := ContentRect.Left;
      if (flowDirectionRow < 0) and (Dim = 1) then StackPosition.Y := ContentRect.Bottom
      else StackPosition.Y := ContentRect.Top;
      Pos := 0;
      rowHeight := 0;
      spaceLeft := availableSpace;
      FirstProcessedElement := True;
      itemCountInRow := 0;
      childRect := RRectFloat.ZERO;
      RowCount := 0;
      for i := 0 to FChildren.Count - 1 do
        // only process visible and inheriting children
        if FChildren[i].Visible and ChildrenInheritance[i] then
        begin
          FChildren[i].ComputeSizing;

          rowHeight := Max(rowHeight, FChildren[i].OuterRect.Dim[OtherDim]);
          Size := FChildren[i].OuterRect.Dim[Dim];
          spaceLeft := spaceLeft - Size;
          if (autoColumnCount and (spaceLeft < 0)) or (not autoColumnCount and (itemCountInRow >= columnCount.Element[Dim])) then
          begin
            // after the first iteration we have the row height of the current row and can apply it to the next row
            spaceLeft := availableSpace - Size;
            otherOffset := otherOffset + (rowHeight * flowDirectionRow);
            rowHeight := FChildren[i].OuterRect.Dim[OtherDim];
            Pos := 0;
            itemCountInRow := 0;
            inc(RowCount);
          end;

          tempRect := FChildren[i].OuterRect;
          if gtSize in FDirty then
          begin
            // resize child in stackorientation
            tempRect.Dim[Dim] := Size;
            // resize child to fill stack, if children isn't inherit in size it will override this
            tempRect.Dim[OtherDim] := ContentRect.Dim[OtherDim];
          end;

          // move child to target position, if children isn't inherit in a certain dimension it will override this
          tempRect.Pos[OtherDim] := StackPosition.Element[OtherDim] + otherOffset;
          tempRect.Pos[Dim] := StackPosition.Element[Dim] + Pos;
          // apply scrolling to the children
          tempRect.Position := tempRect.Position - ScrollOffset;

          FChildren[i].OuterRect := tempRect;
          // any of this changes can affect both position and size of children
          if FDirty * [gtStackorientation, gtStackpartitioning, gtStackcolumns, gtSize, gtMinSize, gtMaxSize, gtPadding] <> [] then
              FChildren[i].SetDirtyAncestors(BuildDirtyFlagInheritance([gtPosition, gtSize]))
            // moving the stack only invalidated the position of children
          else if FDirty * [gtPosition, gtStackAnchor] <> [] then
              FChildren[i].SetDirtyAncestors(BuildDirtyFlagInheritance([gtPosition]));

          // compute used content for content rect
          if FirstProcessedElement then childRect := tempRect.SetDim(rowHeight, OtherDim)
          else childRect := childRect.Extend(tempRect.SetDim(rowHeight, OtherDim));

          Pos := Pos + (Size * flowDirectionColumn);

          inc(itemCountInRow);
          FirstProcessedElement := False;
        end;

      // compute auto-paddings ------------------------------------------
      paddingMove := RVector2.ZERO;
      tempRect := ContentRect;

      // auto padding is determined on full row length on fixed column count, assuming equal sized items
      // to extend childrect to be big as a full filled grid
      if not autoColumnCount and (FPaddingXAuto or FPaddingYAuto) then
      begin
        // fill columns up if we have no full row
        if (columnCount.Element[Dim] <> 0) and (RowCount <= 0) and (itemCountInRow > 0) then
        begin
          childRect.Dim[Dim] := (childRect.Dim[Dim] / itemCountInRow) * columnCount.Element[Dim];
        end;
        // fill row up if we have no full row
        if (columnCount.Element[OtherDim] <> 0) and (RowCount >= 0) then
        begin
          childRect.Dim[OtherDim] := (childRect.Dim[OtherDim] / (RowCount + 1)) * columnCount.Element[OtherDim];
        end;
      end;

      // now compute translation based on free space
      for i := 0 to 1 do
      begin
        // Padding is (Height,Width), but Rects are (Width,Height) so flip index
        // don't set FPadding as children will resize with wrong contentrect if they have a relative size
        if ((i = 0) and FPaddingYAuto) or ((i = 1) and FPaddingXAuto) then
            paddingMove.Element[i] := Max(0, (tempRect.Dim[i] - childRect.Dim[i]) / 2);
      end;

      // move children according to auto-padding
      for i := 0 to FChildren.Count - 1 do
        // only process visible and inheriting children
        if FChildren[i].Visible and ChildrenInheritance[i] then
            FChildren[i].OuterRect := FChildren[i].OuterRect.Translate(paddingMove);

      // determine scrollrect, if scrollbars showed up or vanished, we need to recompute everything as style can apply due to pseudo selector :scrollable
      wasScrollable := ScrollbarsVisible;
      ScrollRect := ScrollRect.SetSize(RVector2.Max(RVector2.ZERO, (childRect.Size + FPadding.SumAxis) - FViewRect.Size));
      if ScrollbarsVisible <> wasScrollable then
      begin
        SetStyleSheetStackDirtyRecursive;
        SetCompleteDirty;
      end;
    end
    else
    // fixed width stack ----------------------------------------------------------------------------------------------
    begin
      row := 0;
      processedChildren := 0;
      otherOffset := 0;
      while processedChildren < FChildren.Count do
      begin
        currentColumnFirst := row * columnCount.Element[Dim];
        currentColumnLast := currentColumnFirst + columnCount.Element[Dim] - 1;
        if currentColumnFirst > currentColumnLast then break; // safety

        spaceLeft := availableSpace;

        // compute used space by absolute elements, so relative components can share the rest
        RelativeWeightsSum := 0;
        for i := currentColumnFirst to Min(currentColumnLast, StyleValueCount(gtStackpartitioning) - 1) do
        begin
          SpaceData := GetStyleValue<RGSSSpaceData>(gtStackpartitioning, i);
          if (Dim = 0) and SpaceData.IsRelativeContainerHeight then
              spaceLeft := spaceLeft - SpaceData.Resolve(Dim, ContentRect, ParentRect)
          else if (Dim = 1) and SpaceData.IsRelativeContainerWidth then
              spaceLeft := spaceLeft - SpaceData.Resolve(Dim, ContentRect, ParentRect)
          else if SpaceData.IsAbsolute then
              spaceLeft := spaceLeft - SpaceData.Resolve(Dim, ContentRect, ParentRect)
          else if SpaceData.IsRelative and (i < ChildCount) then
              RelativeWeightsSum := RelativeWeightsSum + SpaceData.Value;
        end;

        Pos := 0;
        rowHeight := 0;
        // size and position children
        for i := currentColumnFirst to currentColumnLast do
        begin
          if i >= FChildren.Count then break;
          inc(processedChildren);

          FChildren[i].ComputeSizing;
          rowHeight := Max(rowHeight, FChildren[i].OuterRect.Dim[OtherDim]);

          // read size of child in partitioning
          SpaceData := GetStyleValue<RGSSSpaceData>(gtStackpartitioning, i);
          if SpaceData.IsAbsolute then
              Size := SpaceData.Resolve(Dim, ContentRect, ParentRect)
          else if (Dim = 0) and SpaceData.IsRelativeContainerHeight then
              Size := SpaceData.Resolve(Dim, ContentRect, ParentRect)
          else if (Dim = 1) and SpaceData.IsRelativeContainerWidth then
              Size := SpaceData.Resolve(Dim, ContentRect, ParentRect)
          else if SpaceData.IsRelative then
              Size := spaceLeft * (SpaceData.Value / RelativeWeightsSum)
          else Size := 0;

          tempRect := FChildren[i].OuterRect;
          // resize child in stackorientation
          tempRect.Dim[Dim] := Size;
          // resize child to fill stack, if children isn't inherit in size it will override this
          tempRect.Dim[OtherDim] := ContentRect.Dim[OtherDim];

          // move child to target position, if children isn't inherit in a certain dimension it will override this
          tempRect.Pos[OtherDim] := ContentRect.Pos[OtherDim] + otherOffset;
          tempRect.Pos[Dim] := ContentRect.Pos[Dim] + Pos;

          FChildren[i].OuterRect := tempRect;

          Pos := Pos + (Size + flowDirectionColumn);
        end;

        // after the first iteration we have the row height of the current row and can apply it to the next row
        otherOffset := otherOffset + (rowHeight * flowDirectionRow);

        inc(row);
      end;
    end;
  end;
end;

procedure TGUIStackPanel.ChildrenChanged;
begin
  inherited;
  SetDirty([gtPosition, gtSize]);
end;

procedure TGUIStackPanel.ComputeSize(Dim : integer);
var
  SpaceData : RGSSSpaceData;
  Size : single;
  i, oridim : integer;
begin
  inherited;
  if not Visible then exit;
  SpaceData := GetStyleValue<RGSSSpaceData>(gtSize, Dim);
  if SpaceData.IsAuto then
  begin
    Size := 0;
    ComputeStackProperties;
    oridim := HGeneric.TertOp(FStackOrientation = soVertical, 1, 0);
    if gtStackpartitioning in FDirty then
        FAutomode := GetStyleValue<RGSSSpaceData>(gtStackpartitioning, 0).IsAuto;
    if FAutomode then
    begin
      // in automode no relative padding can be used
      ComputeMargin;
      ComputePadding;
      // size derives from children, fix values expected, otherwise 0 for relative member used
      for i := 0 to FChildren.Count - 1 do
      begin
        FChildren[i].ComputeVisibility;
        if FChildren[i].IsVisible and FChildren[i].GetStyleValue<RGSSSpaceData>(gtPosition, oridim).IsInherit then
        begin
          FChildren[i].ComputeSizing;
          Size := Size + FChildren[i].OuterRect.Dim[oridim];
        end;
      end;
      FRect.Dim[oridim] := 0;
      Size := Size - ContentRect.Dim[oridim];
    end
    else
    begin
      // size derives from stackpartioning, fix values expected, otherwise 0 for relative member used
      for i := 0 to StyleValueCount(gtStackorientation) - 1 do
      begin
        Size := GetStyleValue<RGSSSpaceData>(gtStackpartitioning, i).Resolve(Dim, FRect, ParentRect);
      end;
    end;
    FRect.Dim[oridim] := Size;
  end;
  ClipSize(Dim);
end;

procedure TGUIStackPanel.ComputeStackProperties;
begin
  if gtStackorientation in FDirty then
      FStackOrientation := GetStyleValue<EnumStackOrientation>(gtStackorientation);
  if gtStackcolumns in FDirty then
  begin
    FStackColumns.X := GetStyleValue<integer>(gtStackcolumns, 0);
    FStackColumns.Y := GetStyleValue<integer>(gtStackcolumns, 1);
  end;
end;

function TGUIStackPanel.DefaultElementName : string;
begin
  Result := 'stack';
end;

procedure TGUIStackPanel.OnAttributeChange(const Key, Value : string);
begin
  inherited;
  if Key = 'split' then ChangeStyle<RGSSSpaceData>(gtStackpartitioning, RGSSSpaceData.CreateMultiFromString(Value))
  else if Key = 'horizontal' then ChangeStyle<EnumStackOrientation>(gtStackorientation, soHorizontal)
  else if Key = 'vertical' then ChangeStyle<EnumStackOrientation>(gtStackorientation, soVertical)
  else if Key = 'cols' then ChangeStyle<integer>(gtStackcolumns, HString.StrToInt(Value, 10000))
  else if Key = 'rows' then ChangeStyle<integer>(gtStackcolumns, HString.StrToInt(Value, 0));
end;

procedure TGUIStackPanel.SetDirty(const Tags : SetGSSTag);
begin
  if Tags - FDirty = [] then exit;
  inherited;
  if gtDirtyChildren in Tags then
      SetDirty(CHILDRENAFFECTINGTAGS);
end;

{ TGUIProgressBar }

procedure TGUIProgressBar.ApplyStyle;
begin
  inherited;
  if gtProgressposition in FDirty then
      FProgressPosition := GetStyleValue<single>(gtProgressposition);
  if gtProgressmaximum in FDirty then
      FProgressmaximum := GetStyleValue<single>(gtProgressmaximum);
  if gtProgressshape in FDirty then
      FProgressShape := GetStyleValue<EnumProgressShape>(gtProgressshape);
  if assigned(FillBar.FQuad) and (FProgressShape = psRadial) then
  begin
    if (FillBar.FQuad is TVertexScreenAlignedQuad) then TVertexScreenAlignedQuad(FillBar.FQuad).RadialClip := HMath.Saturate(FProgressPosition / FProgressmaximum)
    else assert(False, 'TGUIProgressBar.ApplyStyle: Radial progress only supported for screen aligned quads!');
    FillBar.ChangeStyle<RGSSSpaceData>(gtSize, RGSSSpaceData.CreateRelative([1, 1]));
  end
  else
  begin
    if assigned(FillBar.FQuad) and (FillBar.FQuad is TVertexScreenAlignedQuad) then TVertexScreenAlignedQuad(FillBar.FQuad).RadialClip := -1;
    FillBar.ChangeStyle<RGSSSpaceData>(gtSize, RGSSSpaceData.CreateRelative([HMath.Saturate(FProgressPosition / FProgressmaximum), 1]));
  end;
  FillBar.ChangeStyle<EnumMouseEvent>(gtMouseEvents, mePass);
end;

constructor TGUIProgressBar.Create(Owner : TGUI; Style : TGUIStyleSheet; const Name : string; Parent : TGUIComponent);
begin
  inherited;
  InitFillbar(Owner);
end;

procedure TGUIProgressBar.InitFillbar(Owner : TGUI);
var
  DrawSpace : EnumDrawSpace;
begin
  FillBar := TGUIComponent.Create(Owner, nil, 'FillBar', self);
  FillBar.ChangeStyle<RGSSSpaceData>(gtSize, RGSSSpaceData.CreateRelative([0, 1]));
  FillBar.ChangeStyle<RGSSSpaceData>(gtPosition, RGSSSpaceData.CreateAbsolute([0, 0]));
  DrawSpace := GetStyleValue<EnumDrawSpace>(gtDrawSpace);
  if DrawSpace = dsWorldScreenSpace then DrawSpace := dsScreenSpace;
  FillBar.ChangeStyle<EnumDrawSpace>(gtDrawSpace, DrawSpace);
  FillBar.ChangeStyle<EnumMouseEvent>(gtMouseEvents, mePass);
end;

procedure TGUIProgressBar.OnAttributeChange(const Key, Value : string);
begin
  inherited;
  if (Key = 'position') then Position := TGUIStyleSheet.CSSStrToFloat(Value, 0.0);
end;

procedure TGUIProgressBar.MouseMove(const Position : RVector2);
begin
  inherited;
  if Enabled and FMouseDown[mbLeft] then
  begin
    self.Position := ((Position.X - FRect.Left) / (FRect.Width - 1)) * self.Max;
  end;
end;

destructor TGUIProgressBar.Destroy;
begin
  inherited;
end;

function TGUIProgressBar.GetMax : single;
begin
  Result := FProgressmaximum;
end;

function TGUIProgressBar.GetPosition : single;
begin
  Result := FProgressPosition;
end;

procedure TGUIProgressBar.InitDefaultStyle;
begin
  inherited;
  FStyleSheet.AddOrSetValue<single>(gtProgressposition, 0.0);
  FStyleSheet.AddOrSetValue<single>(gtProgressmaximum, 1.0);
end;

procedure TGUIProgressBar.SetMax(Value : single);
begin
  if FProgressmaximum <> Value then
  begin
    ChangeStyle<single>(gtProgressmaximum, Value);
    FProgressmaximum := Value;
  end;
end;

procedure TGUIProgressBar.SetPosition(Value : single);
begin
  if FProgressPosition <> Value then
  begin
    ChangeStyle<single>(gtProgressposition, Value);
    FProgressPosition := Value;
  end;
end;

{ RGSSSpaceData }

class function RGSSSpaceData.Auto : RGSSSpaceData;
begin
  Result.SpaceType := vtAuto;
  Result.Value := 0;
end;

constructor RGSSSpaceData.CreateAbsolute(Value : single);
begin
  SpaceType := vtAbsolute;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelative(Value : single);
begin
  SpaceType := vtRelative;
  self.Value := Value;
end;

class function RGSSSpaceData.Inherit : RGSSSpaceData;
begin
  Result.SpaceType := vtInherit;
  Result.Value := 0;
end;

function RGSSSpaceData.IsAbsolute : boolean;
begin
  Result := SpaceType = vtAbsolute;
end;

function RGSSSpaceData.IsAbsoluteScreen : boolean;
begin
  Result := SpaceType = vtAbsoluteScreen;
end;

function RGSSSpaceData.IsAuto : boolean;
begin
  Result := SpaceType = vtAuto;
end;

function RGSSSpaceData.IsInherit : boolean;
begin
  Result := SpaceType = vtInherit;
end;

function RGSSSpaceData.IsRelative : boolean;
begin
  Result := SpaceType in [vtRelative, vtRelativeContainerHeight, vtRelativeContainerWidth, vtRelativeParentWidth, vtRelativeParentHeight, vtRelativeViewWidth, vtRelativeViewHeight, vtRelativeScreenWidth, vtRelativeScreenHeight];
end;

function RGSSSpaceData.IsRelativeBackgroundHeight : boolean;
begin
  Result := SpaceType = vtRelativeBackgroundHeight;
end;

function RGSSSpaceData.IsRelativeBackgroundWidth : boolean;
begin
  Result := SpaceType = vtRelativeBackgroundWidth;
end;

function RGSSSpaceData.IsRelativeContainerHeight : boolean;
begin
  Result := SpaceType = vtRelativeContainerHeight;
end;

function RGSSSpaceData.IsRelativeContainerWidth : boolean;
begin
  Result := SpaceType = vtRelativeContainerWidth;
end;

function RGSSSpaceData.IsRelativeContext : boolean;
begin
  Result := SpaceType = vtRelative;
end;

function RGSSSpaceData.IsRelativeParentHeight : boolean;
begin
  Result := SpaceType = vtRelativeParentHeight;
end;

function RGSSSpaceData.IsRelativeParentWidth : boolean;
begin
  Result := SpaceType = vtRelativeParentWidth;
end;

function RGSSSpaceData.IsRelativeScreenHeight : boolean;
begin
  Result := SpaceType = vtRelativeScreenHeight;
end;

function RGSSSpaceData.IsRelativeScreenWidth : boolean;
begin
  Result := SpaceType = vtRelativeScreenWidth;
end;

function RGSSSpaceData.IsRelativeViewHeight : boolean;
begin
  Result := SpaceType = vtRelativeViewHeight;
end;

function RGSSSpaceData.IsRelativeViewWidth : boolean;
begin
  Result := SpaceType = vtRelativeViewWidth;
end;

function RGSSSpaceData.IsText : boolean;
begin
  Result := SpaceType = vtText;
end;

function RGSSSpaceData.IsZero : boolean;
begin
  Result := Value = 0.0;
end;

function RGSSSpaceData.Resolve(Dim : integer; const Rect, ParentRect : RRectFloat) : single;
begin
  if IsRelativeContainerWidth then
      Result := Rect.Width * Value
  else if IsRelativeContainerHeight then
      Result := Rect.Height * Value
  else if IsRelativeViewWidth then
      Result := GUI.ViewSize.Width * Value
  else if IsRelativeViewHeight then
      Result := GUI.ViewSize.Height * Value
  else if IsRelativeScreenWidth then
      Result := GUI.Scene.Size.Width * Value
  else if IsRelativeScreenHeight then
      Result := GUI.Scene.Size.Height * Value
  else if IsRelativeParentWidth then
      Result := ParentRect.Width * Value
  else if IsRelativeParentHeight then
      Result := ParentRect.Height * Value
  else if IsRelative then
      Result := Rect.Dim[Dim] * Value
  else if IsAbsoluteScreen then
      Result := Value
  else // if SpaceData.IsAbsolute then
      Result := Value * GUI.VirtualSizeModifier.Element[Dim];
end;

class function RGSSSpaceData.Text(OverrideFontWeight : integer) : RGSSSpaceData;
begin
  Result.SpaceType := vtText;
  Result.Value := OverrideFontWeight;
end;

class function RGSSSpaceData.CreateAbsolute(Values : array of single) : TArray<RGSSSpaceData>;
var
  i : integer;
begin
  setLength(Result, length(Values));
  for i := 0 to length(Values) - 1 do Result[i] := RGSSSpaceData.CreateAbsolute(Values[i]);
end;

class function RGSSSpaceData.CreateAbsoluteScreen(Values : array of single) : TArray<RGSSSpaceData>;
var
  i : integer;
begin
  setLength(Result, length(Values));
  for i := 0 to length(Values) - 1 do Result[i] := RGSSSpaceData.CreateAbsoluteScreen(Values[i]);
end;

constructor RGSSSpaceData.CreateAbsoluteScreen(Value : single);
begin
  SpaceType := vtAbsoluteScreen;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeBackgroundHeight(Value : single);
begin
  SpaceType := vtRelativeBackgroundHeight;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeBackgroundWidth(Value : single);
begin
  SpaceType := vtRelativeBackgroundWidth;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateFromString(Value : string);
begin
  Value := Value.Replace(' ', '').ToLowerInvariant;
  if Value.Contains('auto') then self := Auto
  else if Value.Contains('text') then self := Text(HString.StrToInt(Value.Replace('text', ''), 0) + FONT_WEIGHT_EPSILON)// +10 to preent rounding bugs
  else if Value.Contains('%') then self := RGSSSpaceData.CreateRelative(TGUIStyleSheet.CSSStrToFloat(Value.Replace('%', ''), 100.0) / 100.0)
  else if Value.Contains('cw') then self := RGSSSpaceData.CreateRelativeContainerWidth(TGUIStyleSheet.CSSStrToFloat(Value.Replace('cw', ''), 100.0) / 100)
  else if Value.Contains('ch') then self := RGSSSpaceData.CreateRelativeContainerHeight(TGUIStyleSheet.CSSStrToFloat(Value.Replace('ch', ''), 100.0) / 100)
  else if Value.Contains('pw') then self := RGSSSpaceData.CreateRelativeParentWidth(TGUIStyleSheet.CSSStrToFloat(Value.Replace('pw', ''), 100.0) / 100)
  else if Value.Contains('ph') then self := RGSSSpaceData.CreateRelativeParentHeight(TGUIStyleSheet.CSSStrToFloat(Value.Replace('ph', ''), 100.0) / 100)
  else if Value.Contains('vw') then self := RGSSSpaceData.CreateRelativeViewWidth(TGUIStyleSheet.CSSStrToFloat(Value.Replace('vw', ''), 100.0) / 100)
  else if Value.Contains('vh') then self := RGSSSpaceData.CreateRelativeViewHeight(TGUIStyleSheet.CSSStrToFloat(Value.Replace('vh', ''), 100.0) / 100)
  else if Value.Contains('sw') then self := RGSSSpaceData.CreateRelativeScreenWidth(TGUIStyleSheet.CSSStrToFloat(Value.Replace('sw', ''), 100.0) / 100)
  else if Value.Contains('sh') then self := RGSSSpaceData.CreateRelativeScreenHeight(TGUIStyleSheet.CSSStrToFloat(Value.Replace('sh', ''), 100.0) / 100)
  else if Value.Contains('bw') then self := RGSSSpaceData.CreateRelativeBackgroundWidth(TGUIStyleSheet.CSSStrToFloat(Value.Replace('bw', ''), 100.0) / 100)
  else if Value.Contains('bh') then self := RGSSSpaceData.CreateRelativeBackgroundHeight(TGUIStyleSheet.CSSStrToFloat(Value.Replace('bh', ''), 100.0) / 100)
  else if Value.Contains('as') then self := RGSSSpaceData.CreateAbsoluteScreen(TGUIStyleSheet.CSSStrToFloat(Value.Replace('as', '')))
  else if not Value.Contains('inherit') then self := RGSSSpaceData.CreateAbsolute(TGUIStyleSheet.CSSStrToFloat(Value, 100.0))
  else self := Inherit;
end;

class function RGSSSpaceData.CreateMultiFromString(Value : string) : TArray<RGSSSpaceData>;
var
  Splits : TArray<string>;
  i : integer;
begin
  Splits := Value.Split([' '], TStringSplitOptions.ExcludeEmpty);
  setLength(Result, length(Splits));
  for i := 0 to length(Result) - 1 do
      Result[i] := RGSSSpaceData.CreateFromString(Splits[i]);
end;

class function RGSSSpaceData.CreateRelative(Values : array of single) : TArray<RGSSSpaceData>;
var
  i : integer;
begin
  setLength(Result, length(Values));
  for i := 0 to length(Values) - 1 do Result[i] := RGSSSpaceData.CreateRelative(Values[i]);
end;

constructor RGSSSpaceData.CreateRelativeContainerHeight(Value : single);
begin
  SpaceType := vtRelativeContainerHeight;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeContainerWidth(Value : single);
begin
  SpaceType := vtRelativeContainerWidth;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeParentHeight(Value : single);
begin
  SpaceType := vtRelativeParentHeight;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeParentWidth(Value : single);
begin
  SpaceType := vtRelativeParentWidth;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeScreenHeight(Value : single);
begin
  SpaceType := vtRelativeScreenHeight;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeScreenWidth(Value : single);
begin
  SpaceType := vtRelativeScreenWidth;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeViewHeight(Value : single);
begin
  SpaceType := vtRelativeViewHeight;
  self.Value := Value;
end;

constructor RGSSSpaceData.CreateRelativeViewWidth(Value : single);
begin
  SpaceType := vtRelativeViewWidth;
  self.Value := Value;
end;

class operator RGSSSpaceData.equal(a, b : RGSSSpaceData) : boolean;
begin
  Result := (a.SpaceType = b.SpaceType) and ((a.Value - b.Value) < EPSILON);
end;

class operator RGSSSpaceData.implicit(a : RGSSSpaceData) : string;
var
  Suffix : string;
  s : single;
begin
  case a.SpaceType of
    vtInherit : exit('inherit');
    vtAuto : exit('auto');
    vtText : exit('text');
    vtAbsolute : Suffix := '';
    vtAbsoluteScreen : Suffix := 'as';
    vtRelative : Suffix := '%';
    vtRelativeContainerWidth : Suffix := 'cw';
    vtRelativeContainerHeight : Suffix := 'ch';
    vtRelativeParentWidth : Suffix := 'pw';
    vtRelativeParentHeight : Suffix := 'ph';
    vtRelativeViewWidth : Suffix := 'vw';
    vtRelativeViewHeight : Suffix := 'vh';
    vtRelativeScreenWidth : Suffix := 'sw';
    vtRelativeScreenHeight : Suffix := 'sh';
    vtRelativeBackgroundWidth : Suffix := 'bw';
    vtRelativeBackgroundHeight : Suffix := 'bh';
  end;
  s := a.Value;
  if a.IsRelative then s := s * 100;
  if abs(s) < 1E-4 then s := 0;
  Result := FloatToStrF(s, ffGeneral, 4, 4, EngineFloatFormatSettings) + Suffix;
end;

class operator RGSSSpaceData.implicit(a : RGSSSpaceData) : RParam;
begin
  Result := RParam.From<RGSSSpaceData>(a);
end;

{ TGUIEdit }

procedure TGUIEdit.ApplyStyle;
var
  originDirty : SetGSSTag;
begin
  originDirty := FDirty;
  exclude(FDirty, gtText); // text is handled internally
  inherited;
  FDirty := originDirty;
  if gtText in FDirty then UpdateFont;
  if gtText in FDirty then SetSelection(FSelStart, FSelEnd);
  if (gtObscureText in FDirty) then FObscureChar := GetStyleValue<string>(gtObscureText);
  if gtTextMaxLength in FDirty then FMaxLength := GetStyleValue<integer>(gtTextMaxLength);
  if not assigned(FTextCursor) then
  begin
    FTextCursor := TVertexScreenAlignedQuad.Create(VertexEngine);
    FTextCursor.DrawsAtStage := rsGUI;
    FTextCursor.DrawOrder := ZOffset * 2 + 4;
  end;
  if not assigned(FTextCursorEnd) then
  begin
    FTextCursorEnd := TVertexScreenAlignedQuad.Create(VertexEngine);
    FTextCursorEnd.DrawsAtStage := rsGUI;
    FTextCursorEnd.DrawOrder := ZOffset * 2 + 4;
  end;
end;

constructor TGUIEdit.Create(Owner : TGUI);
begin
  inherited Create(Owner);
  Init();
end;

constructor TGUIEdit.CustomXMLCreate(Node : TXMLNode; CustomData : array of TObject);
begin
  inherited;
  Init();
end;

procedure TGUIEdit.Init;
begin
  FKeyRepeat := TTimer.Create(Round(1000 / 30));
  FKeyRepeatDelay := TTimer.Create(750);
  FBlinkTimer := TTimer.Create(600);
  FObscureChar := ' ';
  FMaxLength := -1;
end;

function TGUIEdit.DefaultElementName : string;
begin
  Result := 'input';
end;

procedure TGUIEdit.DeleteSelection(Direction : integer);
begin
  if SelectionCount > 0 then
      FText := FText.Remove(Min(FSelStart, FSelEnd), SelectionCount)
  else
  begin
    if Direction > 0 then
    begin
      FText := FText.Remove(FSelStart - 1, 1);
      dec(FSelStart);
    end
    else if Direction < 0 then FText := FText.Remove(FSelStart, 1);
  end;
  SetSelection(Min(FSelEnd, FSelStart));
end;

destructor TGUIEdit.Destroy;
begin
  FBlinkTimer.Free;
  FKeyRepeatDelay.Free;
  FKeyRepeat.Free;
  FTextCursor.Free;
  FTextCursorEnd.Free;
  inherited;
end;

procedure TGUIEdit.ExpandSelection(Direction : integer);
begin
  if Direction = 0 then exit;
  SetSelection(FSelStart + Direction, FSelEnd);
end;

procedure TGUIEdit.FocusNextEdit;
var
  me, i : integer;
begin
  if HasParent then
  begin
    me := Parent.FChildren.IndexOf(self);
    i := me;
    repeat
      i := (i + 1) mod Parent.ChildCount;
      if (Parent.FChildren[i] is TGUIEdit) and (i <> me) then
      begin
        Parent.FChildren[i].SetFocus;
        break;
      end;
    until i = me;
  end;
end;

function TGUIEdit.GetCurrentText : string;
begin
  Result := FText;
end;

function TGUIEdit.GetMaxLength : integer;
begin
  if self = nil then exit(-1);
  Result := FMaxLength;
end;

function TGUIEdit.GetSelectedString : string;
begin
  Result := FText.Substring(FSelStart, SelectionCount);
end;

function TGUIEdit.getSelectionCount : integer;
begin
  Result := abs(FSelEnd - FSelStart);
end;

function TGUIEdit.KeyboardEvent(Event : EnumKeyEvent; Key : EnumKeyboardKey) : boolean;
begin
  Result := inherited;
  if (Key in [TasteSTRGLinks, TasteSTRGRechts]) then
  begin
    FStrg := Event = keDown;
    exit(False);
  end;
  if (Key = TasteAltGr) then
  begin
    FAltGr := Event = keDown;
    exit(False);
  end;
  if (Key in [TasteShiftLinks, TasteShiftRechts]) then
  begin
    FShift := Event = keDown;
    exit(False);
  end;
  if FFocused then
  begin
    Result := True;
    if (Event = keDown) then
    begin
      WriteKey(Key);
      FRepeatedKey := Key;
      FRepeat := True;
      FKeyRepeatDelay.Start;
    end
    else
      if (Event = keUp) then
    begin
      if (Key = FRepeatedKey) then FRepeat := False;
      if not FAcceptNewlines and (Key in [TasteEnter, TasteNumEnter]) then
      begin
        FGUI.ClearFocus;
        FGUI.AddEvent(RGUIEvent.Create(geSubmit, self));
      end;
      if Key = TasteTabulator then FocusNextEdit;
    end;
  end;
end;

function TGUIEdit.KeyToChar(Key : EnumKeyboardKey) : string;

  function ToStr() : string;
  var
    keystate : TKeyboardState;
    copiedChars : integer;
  begin
    // Hack missing numpad keys for now
    case Key of
      TasteNumDivision : exit('/');
      TasteNum7 : exit('7');
      TasteNum8 : exit('8');
      TasteNum9 : exit('9');
      TasteNum4 : exit('4');
      TasteNum5 : exit('5');
      TasteNum6 : exit('6');
      TasteNum1 : exit('1');
      TasteNum2 : exit('2');
      TasteNum3 : exit('3');
      TasteNum0 : exit('0');
      TasteNumKomma : exit(',');
    end;
    GetKeyboardState(keystate);
    setLength(Result, 10);
    copiedChars := ToUnicode(MapVirtualKey(ord(Key), 1), ord(Key), keystate, @Result[1], 10, 0);
    if copiedChars <= 0 then Result := ''
    else if copiedChars = 1 then setLength(Result, 1)
    else if copiedChars >= 2 then setLength(Result, Min(10, copiedChars));
    // remove control chars
    if (length(Result) >= 1) and ((ord(Result[1]) <= 31) or (ord(Result[1]) = 127)) then Result := '';
  end;

begin
  Result := '';
  case Key of
    TasteEnter, TasteNumEnter :
      begin
        if FAcceptNewlines then
            Result := #10;
      end;
    TasteRücktaste : DeleteSelection(+1);
    TasteX :
      begin
        if FStrg then
        begin
          Clipboard.AsText := GetSelectedString;
          DeleteSelection(0);
        end
        else Result := ToStr;
      end;
    TasteA :
      begin
        if FStrg then SetSelection(0, length(FText))
        else Result := ToStr;
      end;
    TasteC :
      begin
        if FStrg then Clipboard.AsText := GetSelectedString
        else Result := ToStr;
      end;
    TasteV :
      begin
        if FStrg then WriteStringAtCursor(Clipboard.AsText)
        else Result := ToStr;
      end;
    TastePOS1 :
      if FShift then ExpandSelection(-FSelStart)
      else SetSelection(0);
    TasteEnde :
      if FShift then ExpandSelection(+length(FText))
      else SetSelection(length(FText));
    TastePfeilLinks :
      begin
        if FShift then ExpandSelection(-1)
        else SetSelection(FSelStart - 1);
      end;
    TastePfeilRechts :
      begin
        if FShift then ExpandSelection(+1)
        else SetSelection(FSelStart + 1);
      end;
    TasteEntf :
      DeleteSelection(-1);
  else Result := ToStr;
  end;
end;

procedure TGUIEdit.MouseUp(const Position : RVector2; Button : EnumMouseButton);
var
  newIndex : integer;
begin
  inherited;
  if (Button = mbLeft) and assigned(FFont) then
  begin
    newIndex := FFont.PositionToIndex(Position - FRect.LeftTop);
    SetSelection(newIndex);
  end;
end;

procedure TGUIEdit.WriteKey(Key : EnumKeyboardKey);
var
  KeyToInsert : string;
begin
  KeyToInsert := KeyToChar(Key);
  if (KeyToInsert <> '') and ((FMaxLength < 0) or (length(FText) < FMaxLength)) then
  begin
    WriteStringAtCursor(KeyToInsert);
  end;
  // throw event that something has changed
  FGUI.AddEvent(RGUIEvent.Create(geChanged, self));
  ResetBlink;
end;

procedure TGUIEdit.WriteStringAtCursor(str : string);
begin
  if str = '' then exit;
  DeleteSelection(0);
  FText := FText.Insert(FSelStart, str);
  SetSelection(FSelStart + length(str));
end;

procedure TGUIEdit.OnAttributeChange(const Key, Value : string);
begin
  if Key = 'maxlength' then Maxlength := HString.StrToInt(Value, -1)
  else if Key = 'text' then Text := Value
  else if Key = 'type' then FAcceptNewlines := Value = 'textarea'
  else inherited;
end;

procedure TGUIEdit.OnTextChange(const Node : TdXMLNode);
begin
  Text := Node.Text;
end;

procedure TGUIEdit.Idle;
begin
  inherited;
  if FFocused then
  begin
    if FRepeat and FKeyRepeatDelay.Expired and FKeyRepeat.Expired then
    begin
      WriteKey(FRepeatedKey);
      FKeyRepeat.Start;
    end;
    if FBlinkTimer.Expired then
    begin
      SetBlink(not FBlink);
      FBlinkTimer.Start;
    end;
  end;
end;

procedure TGUIEdit.Render;
var
  ShownText, OriginText : string;
  First, second : integer;
begin
  ShownText := FText;
  if (FObscureChar <> ' ') and (FObscureChar <> '') then ShownText := HString.GenerateChars(FObscureChar, length(FText));
  OriginText := FText;
  FText := ShownText;
  SetDownSoft(FHovered or FFocused);

  inherited;
  if FFocused and FBlink then
  begin
    First := Min(FSelStart, FSelEnd);
    second := Max(FSelStart, FSelEnd);

    FTextCursor.UseTransform := True;
    FTextCursor.Transform := Transform;
    // if text is empty, this haven't been updated yet by rendering
    if FText = '' then
    begin
      FFont.Text := FText;
      FFont.Rect := ContentRect.Round;
    end;
    FTextCursor.Rect := FFont.IndexToPosition(First).Translate(FRect.LeftTop).Round.Inflate(0, 3, 0, -1).ToRectFloat;
    FTextCursor.Color := FFontColor;
    FTextCursor.ScissorEnabled := True;
    FTextCursor.ScissorRect := FCliprect;
    FTextCursor.AddRenderJob;

    if First <> second then
    begin
      FTextCursorEnd.UseTransform := True;
      FTextCursorEnd.Transform := Transform;
      FTextCursorEnd.Rect := FFont.IndexToPosition(second).Translate(FRect.LeftTop).Round.Inflate(0, 3, 0, -1).ToRectFloat;
      FTextCursorEnd.Color := FFontColor;
      FTextCursorEnd.ScissorEnabled := True;
      FTextCursorEnd.ScissorRect := FCliprect;
      FTextCursorEnd.AddRenderJob;
    end;
  end;

  FText := OriginText;
  if assigned(FFont) then FFont.Text := ShownText;
end;

procedure TGUIEdit.ResetBlink;
begin
  SetBlink(True);
  FBlinkTimer.Start;
end;

procedure TGUIEdit.SetBlink(State : boolean);
begin
  if FBlink = State then exit;
  FBlink := State;
end;

procedure TGUIEdit.SetCurrentText(const Value : string);
begin
  if not assigned(self) then exit();
  if FText <> Value then SetDirty([gtText]);
  FText := Value;
end;

procedure TGUIEdit.SetFocusState(const State : boolean);
begin
  inherited;
  if not FFocused then
  begin
    FRepeat := False;
    SetBlink(False);
  end;
end;

procedure TGUIEdit.SetMaxLength(const Value : integer);
begin
  if self = nil then exit;
  ChangeStyle<integer>(gtTextMaxLength, Value);
  FMaxLength := Value;
end;

procedure TGUIEdit.SetSelection(SelStart, SelEnd : integer);
begin
  FSelStart := HMath.Clamp(SelStart, 0, length(FText));
  if SelEnd = -1 then FSelEnd := FSelStart
  else FSelEnd := HMath.Clamp(SelEnd, 0, length(FText));
  ResetBlink;
end;

{ TGUICheckbox }

procedure TGUICheckbox.Click(Button : EnumMouseButton;
const
  Position :
  RVector2);
begin
  if Button = mbLeft then Checked := not Checked;
  inherited;
end;

function TGUICheckbox.DefaultElementName : string;
begin
  Result := 'check';
end;

function TGUICheckbox.GetChecked : boolean;
begin
  if self = nil then exit(False);
  Result := FChecked;
end;

function TGUICheckbox.PseudoClasses : SetPseudoClass;
begin
  Result := inherited;
  if FChecked then include(Result, pcChecked);
end;

procedure TGUICheckbox.SetChecked(const Value : boolean);
begin
  if self = nil then exit();
  if FChecked <> Value then
  begin
    FChecked := Value;
    SetDownSoft(FChecked);
    FGUI.AddEvent(RGUIEvent.Create(geChanged, self));
  end;
end;

procedure TGUICheckbox.SetDownSoft(const Value : boolean);
begin
  inherited SetDownSoft(FChecked);
end;

procedure TGUICheckbox.OnAttributeChange(const Key, Value : string);
begin
  inherited;
  if Key = 'checked' then Checked := HString.StrToBool(Value);
end;

{ RGUIEvent }

function RGUIEvent.AdditionalDataToComponent : TGUIComponent;
begin
  if IsAdditionalDataValid then Result := GUI.ResolveUID(AdditionalData)
  else Result := nil;
end;

function RGUIEvent.Check(const Name : string) : boolean;
begin
  Result := (self = name) and IsValid;
end;

function RGUIEvent.Check(const Name : array of string) : boolean;
begin
  Result := IsValid and HString.ContainsString(name, self.Name);
end;

constructor RGUIEvent.Create(Event : EnumGUIEvent; const Name : string; UID : integer; Component : TGUIComponent; GUI : TGUI);
begin
  self.Event := Event;
  self.Name := name;
  self.UID := UID;
  self.Component := Component;
  self.GUI := GUI;
end;

constructor RGUIEvent.Create(Event : EnumGUIEvent; Component : TGUIComponent);
begin
  self.Event := Event;
  self.AdditionalData := 0;
  if assigned(Component) then
  begin
    self.Name := Component.Name;
    self.UID := Component.UID;
    self.GUI := Component.FGUI;
  end
  else
  begin
    self.Name := '';
    self.UID := -1;
    self.GUI := nil;
  end;
  self.Component := Component;
end;

constructor RGUIEvent.CreateFromUID(Event : EnumGUIEvent; UID : integer; GUI : TGUI);
begin
  self.Event := Event;
  self.Component := GUI.ResolveUID(UID);
  if assigned(self.Component) then self.Name := self.Component.Name
  else self.Name := '';
  self.UID := UID;
  self.GUI := GUI;
end;

function RGUIEvent.CustomData : NativeUInt;
begin
  Result := self.Component.CustomData;
end;

function RGUIEvent.CustomDataAs<T> : T;
begin
  Result := self.Component.CustomDataAs<T>;
end;

function RGUIEvent.CustomDataAsWrapper<T> : T;
begin
  Result := self.Component.CustomDataAsWrapper<T>;
end;

class operator RGUIEvent.equal(const a : RGUIEvent; const b : string) : boolean;
begin
  Result := a.Name = b;
end;

class operator RGUIEvent.equal(const b : string; const a : RGUIEvent) : boolean;
begin
  Result := a.Name = b;
end;

function RGUIEvent.IsAdditionalDataValid : boolean;
begin
  Result := GUI.ResolveUID(AdditionalData) <> nil;
end;

function RGUIEvent.IsAny(Names : array of string) : boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to length(Names) - 1 do
    if name = Names[i] then exit(True);
end;

function RGUIEvent.IsValid : boolean;
begin
  Result := assigned(GUI) and (GUI.ResolveUID(UID) <> nil);
end;

class operator RGUIEvent.notequal(const a : RGUIEvent; const b : string) : boolean;
begin
  Result := a.Name <> b;
end;

class operator RGUIEvent.notequal(const b : string; const a : RGUIEvent) : boolean;
begin
  Result := a.Name <> b;
end;

function RGUIEvent.SetAdditionalData(Data : TGUIComponent) : RGUIEvent;
begin
  if assigned(Data) then self.AdditionalData := Data.UID;
  Result := self;
end;

function RGUIEvent.SetAdditionalData(Data : NativeUInt) : RGUIEvent;
begin
  self.AdditionalData := Data;
  Result := self;
end;

function RGUIEvent.TryAdditionalDataToComponent(out Component : TGUIComponent) : boolean;
begin
  Result := GUI.TryResolveUID(AdditionalData, Component);
end;

function RGUIEvent.TryGetParent(const ParentName : string; out Parent : TGUIComponent) : boolean;
begin
  if IsValid then
  begin
    Result := Component.TryGetParentComponentByName(ParentName, Parent);
  end
  else Result := False;
end;

{ RState<T> }

function RState<T>.IsAnySet : boolean;
var
  DefaultValue : T;
begin
  DefaultValue := System.Default(T);
  Result := not CompareMem(@default, @DefaultValue, SizeOf(T)) or
    not CompareMem(@Hover, @DefaultValue, SizeOf(T)) or
    not CompareMem(@Down, @DefaultValue, SizeOf(T)) or
    not CompareMem(@Disabled, @DefaultValue, SizeOf(T));
end;

{ TGUIStyleManager }

procedure TGUIStyleManager.AddAnimation(const Key, Value : string);
begin
  FAnimations.AddOrSetValue(Key, TGUIAnimationStack.CreateFromString(Value));
end;

procedure TGUIStyleManager.AddConstant(const Key, Value : string);
var
  i : integer;
begin
  // constants are ordered by key length to prevent replacements of keys which are prefix of other keys too early
  // e.g. $rgl_blubs should be replaced before $rgl
  for i := 0 to FConstants.Count - 1 do
    if length(FConstants[i].Key) > length(Key) then
    begin
      FConstants.Insert(i, RGUIStyleConstant.Create(Key, ResolveConstants(Value)));
      exit;
    end;
  FConstants.Add(RGUIStyleConstant.Create(Key, ResolveConstants(Value)));
end;

function TGUIStyleManager.ResolveConstants(const StyleBlock : string) : string;
var
  i : integer;
begin
  Result := StyleBlock;
  for i := FConstants.Count - 1 downto 0 do
  begin
    Result := FConstants[i].Apply(Result);
  end;
end;

function TGUIStyleManager.BuildStyleStack(ClassHierarchy : TClassHierarchy) : TGUIStyleSheetStackHandle;
var
  Stack : TGUIStyleSheetStack;
begin
  FLock.Acquire;
  if not FCache.TryGetValue(ClassHierarchy, Stack) then
  begin
    Stack := TGUIStyleSheetStack.Create(self);
    FStyles.BuildStyleStack(ClassHierarchy, 0, RIntVector2.ZERO, Stack);
    Stack.FinalizeStack;
    FCache.Add(ClassHierarchy.Clone, Stack);
  end;
  FLock.Release;
  Result := TGUIStyleSheetStackHandle.Create(self, Stack);
end;

class constructor TGUIStyleManager.Create;
begin
  FLock := TCriticalSection.Create;
  FClassMapping := TDictionary<string, integer>.Create;
  FReverseClassMapping := TList<string>.Create;
  FClassMapping.Add('&', 0);
  FReverseClassMapping.Add('&');
end;

constructor TGUIStyleManager.Create(Owner : TGUI);
var
  Comparer : IEqualityComparer<TClassHierarchy>;
begin
  Comparer := TEqualityComparer<TClassHierarchy>.Construct(
    (
    function(const Left, Right : TClassHierarchy) : boolean
    begin
      Result := Left.CompareTo(Right);
    end),
    (
    function(const L : TClassHierarchy) : integer
    begin
      Result := L.Hash;
    end));
  FVersion := 1;
  FGUI := Owner;
  FStyles := TGUIStyleNode.Create('');
  FStyleFiles := TList<string>.Create;
  FStyleFileContent := TList<string>.Create;
  FAnimations := TObjectDictionary<string, TGUIAnimationStack>.Create([doOwnsValues]);
  FConstants := TList<RGUIStyleConstant>.Create;
  FCache := TObjectDictionary<TClassHierarchy, TGUIStyleSheetStack>.Create([doOwnsKeys, doOwnsValues], Comparer);
end;

destructor TGUIStyleManager.Destroy;
begin
  FCache.Free;
  FStyles.Free;
  FStyleFiles.Free;
  FStyleFileContent.Free;
  FConstants.Free;
  FAnimations.Free;
  inherited;
end;

procedure TGUIStyleManager.FileDirtyCallback(const Filepath, Filecontent : string);
var
  i, dirtyIndex : integer;
  OldStyles : TGUIStyleNode;
  OldAnimations : TObjectDictionary<string, TGUIAnimationStack>;
  errors : string;
begin
  dirtyIndex := FStyleFiles.IndexOf(Filepath.ToLowerInvariant);
  if dirtyIndex >= 0 then
  begin
    OldStyles := FStyles;
    FStyles := TGUIStyleNode.Create('');
    FConstants.Clear;
    OldAnimations := FAnimations;
    FAnimations := TObjectDictionary<string, TGUIAnimationStack>.Create([doOwnsValues]);
    // reload all stylesheets
    errors := '';
    for i := 0 to FStyleFileContent.Count - 1 do
      if errors = '' then
      begin
        if i = dirtyIndex then errors := LoadStylesFromText(Filecontent)
        else errors := LoadStylesFromText(FStyleFileContent[i]);
      end;
    if errors <> '' then
    begin
      FStyles.Free;
      FStyles := OldStyles;
      FAnimations.Free;
      FAnimations := OldAnimations;
      HLog.Write(elInfo, 'Stylefile %s contains an error: %s', [Filepath, errors]);
    end
    else
    begin
      FStyleFileContent[dirtyIndex] := Filecontent;
      OldStyles.Free;
      OldAnimations.Free;
      IncVersion;
    end;
  end
  else
  begin
    LoadStylesFromText(Filecontent);
    FStyleFiles.Add(Filepath.ToLowerInvariant);
    FStyleFileContent.Add(Filecontent);
    IncVersion;
  end;
end;

function TGUIStyleManager.GetAnimationStack(const AnimationName : string) : TGUIAnimationStackHandle;
var
  Stack : TGUIAnimationStack;
begin
  if FAnimations.TryGetValue(AnimationName.ToLowerInvariant, Stack) then
  begin
    Result := TGUIAnimationStackHandle.Create(self, Stack);
  end
  else
      Result := nil;
end;

procedure TGUIStyleManager.IncVersion;
begin
  FGUI.DOMRoot.SetCompleteDirty;
  inc(FVersion);
  FCache.Clear;
end;

procedure TGUIStyleManager.LoadStylesFromFile(const Filename : string);
begin
  ContentManager.SubscribeToFile(Filename, FileDirtyCallback);
end;

procedure TGUIStyleManager.LoadStylesFromFolder(const FolderPath : string);
var
  Files : TStringlist;
  i : integer;
begin
  Files := TStringlist.Create;
  Files.sorted := True;
  HFilepathManager.ForEachFile(FolderPath,
    procedure(const Filename : string)
    begin
      Files.Add(Filename);
    end, '*' + STYLE_FILE_EXTENTION, True);
  for i := 0 to Files.Count - 1 do
      LoadStylesFromFile(Files[i]);
  Files.Free;
end;

function TGUIStyleManager.LoadStylesFromText(const StyleText : string) : string;
  function StrToClassTag(Value : string; out ClassTag : RClassTag; out Error : string) : boolean;
  var
    splitted : TArray<string>;
    Name : string;
    Classes : TArray<integer>;
    i : integer;
  begin
    Result := True;
    ClassTag := RClassTag.Create(-1, []);
    if Value.Contains('>') then
    begin
      ClassTag.IsChild := True;
      Value := HString.TrimBefore('>', Value);
    end;
    splitted := Value.Split([':']);
    if length(splitted) <= 0 then
    begin
      Error := Format('Class definition invalid! %s', [Value]);
      Result := False;
    end;
    Classes := nil;
    name := '';
    for i := 1 to length(splitted[0]) + 1 do
    begin
      if (i = length(splitted[0]) + 1) or (splitted[0][i] = '.') or (splitted[0][i] = '#') then
      begin
        if name <> '' then HArray.Push<integer>(Classes, ResolveClassname(name));
        if i < length(splitted[0]) then name := splitted[0][i];
        continue;
      end;
      name := name + splitted[0][i];
    end;
    if length(Classes) <= 1 then ClassTag.ClassIndex := Classes[0]
    else
    begin
      ClassTag.IsMulti := True;
      ClassTag.MultiClassIndex := Classes;
    end;

    for i := 1 to length(splitted) - 1 do
    begin
      if splitted[i] = 'hover' then include(ClassTag.PseudoClasses, pcHover);
      if splitted[i] = 'checked' then include(ClassTag.PseudoClasses, pcChecked);
      if splitted[i] = 'enabled' then include(ClassTag.PseudoClasses, pcEnabled);
      if splitted[i] = 'disabled' then include(ClassTag.PseudoClasses, pcDisabled);
      if splitted[i] = 'scrollable' then include(ClassTag.PseudoClasses, pcScrollable);
      if splitted[i] = 'showing' then include(ClassTag.PseudoClasses, pcShowing);
      if splitted[i] = 'hiding' then include(ClassTag.PseudoClasses, pcHiding);
      if splitted[i] = 'down' then include(ClassTag.PseudoClasses, pcDown);
      if splitted[i] = 'focus' then include(ClassTag.PseudoClasses, pcFocus);
      if splitted[i] = 'even' then include(ClassTag.PseudoClasses, pcEven);
      if splitted[i] = 'odd' then include(ClassTag.PseudoClasses, pcOdd);
      if splitted[i] = 'first-child' then include(ClassTag.PseudoClasses, pcFirstChild);
      if splitted[i] = 'last-child' then include(ClassTag.PseudoClasses, pcLastChild);
      if splitted[i] = 'important' then ClassTag.CustomSpecificity := ClassTag.CustomSpecificity + 1000000;
    end;
    if ClassTag.PseudoClasses = [] then ClassTag.PseudoClasses := [pcNone];
  end;

// resolve pseudo parent selector
  function SanitizeClassHierarchy(const ClassHierarchy : TClassHierarchy) : TClassHierarchy;
  var
    i, j, k : integer;
    ClassTag : RClassTag;
    ClassList : TClassHierarchyNode;
    allParent : boolean;
  begin
    Result := TClassHierarchy.Create();
    for i := 0 to ClassHierarchy.Count - 1 do
    begin
      ClassList := TClassHierarchyNode.Create;
      // if parent selector, e.g. #button &.error:hover, merge it with one level higher => #button.error:hover
      allParent := True;
      for k := 0 to ClassHierarchy[i].Count - 1 do
          allParent := allParent and ClassHierarchy[i][k].IsParent;
      if (i > 0) and (ClassHierarchy[i].Count > 0) and allParent then
      begin
        for j := 0 to Result.Last.Count - 1 do
        begin
          for k := 0 to ClassHierarchy[i].Count - 1 do
          begin
            ClassTag := Result.Last[j];
            ClassTag := ClassTag.Merge(ClassHierarchy[i][k]);
            ClassList.Add(ClassTag);
          end;
        end;
        Result.Delete(Result.Count - 1);
      end
      // else don't touch the level
      else ClassList.AddRange(ClassHierarchy[i]);
      Result.Add(ClassList);
    end;
  end;

  function EvaluateSpecialMethods(const StyleString : string) : string;
  var
    Regex : TRegex;
  begin
    Result := StyleString;
    // rgba
    Regex := TRegex.Create('((?:lighten|darken|rgba|lerp)\([^\)]+?\))', [roSingleLine, roIgnoreCase]);
    Result := Regex.Substitute(Result,
      function(const Input : string) : string
        type EnumCSSMethod = (cmLighten, cmDarken, cmRGBA, cmLerp);
      var
        params : TArray<string>;
        Color, Color2 : RColor;
        R, g, b, a : single;
        method : EnumCSSMethod;
      begin
        if Input.StartsWith('lighten') then method := cmLighten
        else if Input.StartsWith('darken') then method := cmDarken
        else if Input.StartsWith('rgba') then method := cmRGBA
        else if Input.StartsWith('lerp') then method := cmLerp
        else exit(Input);
        Result := HString.Slice(Input, Pos('(', Input) + 1, -2).Replace(' ', ''); // remove 'method(' and ')'
        params := Result.Split([','], TStringSplitOptions.ExcludeEmpty);
        case method of
          cmRGBA :
            begin
              if length(params) = 2 then
              begin
                if RColor.TryFromString(params[0], Color) and TGUIStyleSheet.TryCSSStrToFloat(params[1], a) then
                    Result := Color.SetAlphaF(a)
              end
              else if length(params) = 4 then
              begin
                if TGUIStyleSheet.TryCSSStrToFloat(params[0], R) and
                  TGUIStyleSheet.TryCSSStrToFloat(params[1], g) and
                  TGUIStyleSheet.TryCSSStrToFloat(params[2], b) and
                  TGUIStyleSheet.TryCSSStrToFloat(params[3], a) then
                    Result := RColor.CreateFromSingle(R, g, b, a)
              end
            end;
          cmLighten, cmDarken :
            begin
              if length(params) = 2 then
              begin
                if RColor.TryFromString(params[0], Color) and TGUIStyleSheet.TryCSSStrToFloat(params[1], a) then
                begin
                  if method = cmLighten then Result := Color.Lerp(RColor.CWHITE, a)
                  else Result := Color.Lerp(RColor.CBLACK, a);
                end;
              end;
            end;
          cmLerp :
            begin
              if length(params) = 3 then
              begin
                if RColor.TryFromString(params[0], Color) and
                  RColor.TryFromString(params[1], Color2) and
                  TGUIStyleSheet.TryCSSStrToFloat(params[2], a) then
                begin
                  Result := Color.Lerp(Color2, a);
                end;
              end;
            end;
        end;
      end);
  end;

var
  ClassHierarchy, SanitizedClassHierarchy : TClassHierarchy;
  Classes : TClassHierarchyNode;
  ClassTag : RClassTag;
  Lines, ClassesRaw, ConstantSplit : TArray<string>;
  SanitizedLine, ConstantBlock, ConstantBlockKey, AnimationBlock, AnimationBlockKey : string;
  CurrentBlock : TList<string>;
  IsConstantBlock, IsAnimationBlock : boolean;
  i, ConstantBlockOpenCount, AnimationBlockOpenCount : integer;
  j : integer;
begin
  Result := '';
  IsConstantBlock := False;
  IsAnimationBlock := False;
  CurrentBlock := TList<string>.Create;
  CurrentBlock.Add('');
  ClassHierarchy := TClassHierarchy.Create();
  Lines := ResolveConstants(StyleText).Split([sLineBreak]);
  ConstantBlockOpenCount := 0;
  AnimationBlockOpenCount := 0;
  SanitizedClassHierarchy := nil;
  for i := 0 to length(Lines) - 1 do
  begin
    SanitizedLine := Lines[i].Trim([#9, ' ']); // trim tabs and whitespaces
    if SanitizedLine <> '' then
    begin
      if SanitizedLine.Contains('{') then
      begin
        if IsConstantBlock then
        begin
          inc(ConstantBlockOpenCount);
          ConstantBlock := ConstantBlock + sLineBreak + SanitizedLine;
        end
        else if IsAnimationBlock then
        begin
          inc(AnimationBlockOpenCount);
          AnimationBlock := AnimationBlock + sLineBreak + SanitizedLine;
        end
        else if SanitizedLine.StartsWith('$') then
        begin
          // Constant definition
          ConstantBlockKey := SanitizedLine.Replace('{', '').Replace(' ', '');
          IsConstantBlock := True;
          inc(ConstantBlockOpenCount);
          ConstantBlock := '';
        end
        else if SanitizedLine.StartsWith('@keyframes') then
        begin
          // Animation definition
          AnimationBlockKey := SanitizedLine.Replace('@keyframes', '').Replace('{', '').Replace(' ', '');
          IsAnimationBlock := True;
          inc(AnimationBlockOpenCount);
          AnimationBlock := '';
        end
        else
        begin
          // Style definition
          ClassesRaw := SanitizedLine.Replace('{', '').Replace(' ', '').Split([',']);
          Classes := TClassHierarchyNode.Create;
          for j := 0 to length(ClassesRaw) - 1 do
          begin
            if not StrToClassTag(ClassesRaw[j], ClassTag, Result) then exit;
            Classes.Add(ClassTag);
          end;
          if Classes.Count <= 0 then exit(Format('Class definition invalid! Line %d', [i]));
          ClassHierarchy.Add(Classes);
          CurrentBlock.Add('');
        end;
      end
      else if SanitizedLine.Contains('}') then
      begin
        if IsConstantBlock then
        begin
          dec(ConstantBlockOpenCount);
          if ConstantBlockOpenCount <= 0 then
          begin
            // submit constant
            IsConstantBlock := False;
            AddConstant(ConstantBlockKey, ResolveConstants(ConstantBlock));
          end
          else ConstantBlock := ConstantBlock + sLineBreak + SanitizedLine;
        end
        else if IsAnimationBlock then
        begin
          dec(AnimationBlockOpenCount);
          if AnimationBlockOpenCount <= 0 then
          begin
            // submit animation
            IsAnimationBlock := False;
            AddAnimation(AnimationBlockKey, ResolveConstants(AnimationBlock));
          end
          else AnimationBlock := AnimationBlock + sLineBreak + SanitizedLine;
        end
        else
        begin
          if ClassHierarchy.Count <= 0 then exit(Format('Closing block without opening! Line %d', [i]));
          // submit block
          SanitizedClassHierarchy := SanitizeClassHierarchy(ClassHierarchy);
          FStyles.AddStylesRecursive(SanitizedClassHierarchy, ResolveConstants(CurrentBlock[CurrentBlock.Count - 1]), RIntVector2.ZERO);
          FreeAndNil(SanitizedClassHierarchy);
          CurrentBlock.Delete(CurrentBlock.Count - 1);
          ClassHierarchy.Delete(ClassHierarchy.Count - 1);
        end;
      end
      else
      begin
        if CurrentBlock.Count <= 0 then exit(Format('Invalid block! Line %d', [i]));
        if IsConstantBlock then
        begin
          ConstantBlock := ConstantBlock + sLineBreak + SanitizedLine;
        end
        else if IsAnimationBlock then
        begin
          AnimationBlock := AnimationBlock + sLineBreak + SanitizedLine;
        end
        else if SanitizedLine.StartsWith('$') and (CurrentBlock.Count <= 1) then
        begin
          // read single value contant
          ConstantSplit := SanitizedLine.Replace(';', '').Split([':']);
          if length(ConstantSplit) <> 2 then exit(Format('Invalid single line constant! Line %d', [i]));
          AddConstant(ConstantSplit[0], ConstantSplit[1]);
        end
        else CurrentBlock[CurrentBlock.Count - 1] := CurrentBlock[CurrentBlock.Count - 1] + EvaluateSpecialMethods(SanitizedLine);
      end;
    end;
  end;
  if IsConstantBlock then exit('Invalid constant block!');
  if IsAnimationBlock then exit('Invalid animation block!');
  if CurrentBlock.Count <> 1 then exit('Invalid global block!');
  FStyles.AddStylesRecursive(ClassHierarchy, CurrentBlock[0], RIntVector2.ZERO);
  ClassHierarchy.Free;
  CurrentBlock.Free;
end;

class function TGUIStyleManager.ClassnameSpecificity(ClassIndex : integer) : integer;
begin
  case (ClassIndex mod 3) of
    0 : Result := 1;
    1 : Result := 10;
    2 : Result := 100;
  else raise EInvalidArgument.Create('TGUIStyleManager.ClassnameSpecificity: Broken ClassIndex!');
  end;
end;

class function TGUIStyleManager.RemapClassname(ClassIndex : integer) : string;
begin
  FLock.Acquire;
  Result := FReverseClassMapping[ClassIndex div 3];
  FLock.Release;
end;

class function TGUIStyleManager.ResolveClassname(const ClassName : string) : integer;
begin
  FLock.Acquire;
  if not FClassMapping.TryGetValue(ClassName.ToLowerInvariant, Result) then
  begin
    FReverseClassMapping.Add(ClassName);
    Result := (FReverseClassMapping.Count - 1) * 3;
    // if Classname has no specifier its an element tag and so +0
    if ClassName.Contains('.') then Result := Result + 1
    else if ClassName.Contains('#') then Result := Result + 2;
    FClassMapping.Add(ClassName.ToLowerInvariant, Result);
  end;
  FLock.Release;
end;

class function TGUIStyleManager.ResolveClassnames(const ClassNames : array of string) : TArray<integer>;
var
  i : integer;
begin
  setLength(Result, length(ClassNames));
  for i := 0 to length(ClassNames) - 1 do
      Result[i] := ResolveClassname(ClassNames[i]);
end;

class destructor TGUIStyleManager.Destroy;
begin
  FLock.Free;
  FReverseClassMapping.Free;
  FClassMapping.Free;
end;

{ TGUIStyleNode }

procedure TGUIStyleNode.AddStylesRecursive(ClassHierarchy : TClassHierarchy; const StylesAsText : string; const Specificity : RIntVector2; Depth : integer);
  function CompareClassArray(const a, b : TArray<integer>) : boolean;
  var
    i, j : integer;
    found : boolean;
  begin
    Result := length(a) = length(b);
    if Result then
    begin
      for i := 0 to length(a) - 1 do
      begin
        found := False;
        for j := 0 to length(b) - 1 do
          if a[i] = b[j] then found := True;
        if not found then exit(False);
      end;
    end;
  end;

  function ResolveMultiChildren(const ClassName : RClassTag; List : TObjectList < TTuple < TArray<integer>, TObjectList<TMultiStyleNode> >> ) : TObjectList<TMultiStyleNode>;
  var
    i : integer;
  begin
    Result := nil;
    for i := 0 to List.Count - 1 do
      if CompareClassArray(List[i].a, ClassName.MultiClassIndex) then
      begin
        Result := List[i].b;
      end;
    if not assigned(Result) then
    begin
      Result := TObjectList<TMultiStyleNode>.Create;
      List.Add(TTuple < TArray<integer>, TObjectList < TMultiStyleNode >>.Create(ClassName.MultiClassIndex, Result));
    end;
  end;

var
  Children : TObjectList<TMultiStyleNode>;
  ClassNames : TClassHierarchyNode;
  ClassName : RClassTag;
  CurrentSpecificity : RIntVector2;
  found : boolean;
  FullIdentifier : string;
  PseudoClass : EnumPseudoClass;
  i, k : integer;
begin
  if Depth < ClassHierarchy.Count then
  begin
    ClassNames := ClassHierarchy[Depth];
    for i := 0 to ClassNames.Count - 1 do
    begin
      ClassName := ClassNames[i];
      CurrentSpecificity := Specificity + ClassName.Specificity;
      // child
      if ClassName.IsChild then
      begin
        // multi
        if ClassName.IsMulti then
            Children := ResolveMultiChildren(ClassName, FMultiChildren)
          // single
        else if not FChildren.TryGetValue(ClassName.ClassIndex, Children) then
        begin
          Children := TObjectList<TMultiStyleNode>.Create;
          FChildren.Add(ClassName.ClassIndex, Children);
        end;
      end
      else
      // descendant
      begin
        // multi
        if ClassName.IsMulti then
            Children := ResolveMultiChildren(ClassName, FMultiDescendants)
          // single
        else if not FDescendants.TryGetValue(ClassName.ClassIndex, Children) then
        begin
          Children := TObjectList<TMultiStyleNode>.Create;
          FDescendants.Add(ClassName.ClassIndex, Children);
        end;
      end;

      found := False;
      // if node already exist append styledata to is
      for k := 0 to Children.Count - 1 do
        if Children[k].PseudoClass = ClassName.PseudoClasses then
        begin
          found := True;
          Children[k].Node.AddStylesRecursive(ClassHierarchy, StylesAsText, CurrentSpecificity, Depth + 1);
        end;
      // otherwise create new node
      if not found then
      begin
        FullIdentifier := self.FullIdentifier;
        if ClassName.IsChild then FullIdentifier := FullIdentifier + ' > '
        else FullIdentifier := FullIdentifier + ' ';
        FullIdentifier := FullIdentifier + ClassName.ClassName;
        for PseudoClass in ClassName.PseudoClasses do
          if PseudoClass <> pcNone then
          begin
            FullIdentifier := FullIdentifier + ':' + HRTTI.EnumerationToString<EnumPseudoClass>(PseudoClass).Remove(0, 2);
          end;
        Children.Add(TMultiStyleNode.Create(ClassName.PseudoClasses, TGUIStyleNode.Create(FullIdentifier), CurrentSpecificity));
        Children.Last.Node.AddStylesRecursive(ClassHierarchy, StylesAsText, CurrentSpecificity, Depth + 1);
      end;
    end;
  end
  else
  begin
    if not assigned(FStyles) then FStyles := TGUIStyleSheet.Create;
    FStyles.AddDataAsText(StylesAsText);
  end;
end;

procedure TGUIStyleNode.BuildStyleStack(ClassHierarchy : TClassHierarchy; Depth : integer; const Specificity : RIntVector2; var Stack : TGUIStyleSheetStack);
var
  ClassNames : TClassHierarchyNode;
  ClassTag : RClassTag;
  Children : TObjectList<TMultiStyleNode>;
  Child : TMultiStyleNode;
  i, CurrentDepth : integer;
  procedure EvaluateList(List : TObjectList<TMultiStyleNode>);
  var
    j : integer;
  begin
    for j := 0 to List.Count - 1 do
    begin
      Child := List[j];
      if Child.PseudoClass * ClassTag.PseudoClasses = Child.PseudoClass then
      begin
        Child.Node.BuildStyleStack(ClassHierarchy, CurrentDepth + 1, Specificity + Child.Specificity, Stack);
      end;
    end;
  end;
  procedure EvaluateMulti(List : TObjectList < TTuple < TArray<integer>, TObjectList<TMultiStyleNode> >> );
  var
    i : integer;
  begin
    for i := 0 to List.Count - 1 do
    begin
      if HArray.Contains<integer>(ClassNames.Multiclass.ClassIndices, List[i].a) then
          EvaluateList(List[i].b);
    end;
  end;

begin
  // dig deep as possible as the resulting style should be the one lying deepest in the hierarchy
  // first try to find complete class hierarchy, if not found remove topmost level and try again
  for CurrentDepth := Depth to ClassHierarchy.Count - 1 do
  begin
    ClassNames := ClassHierarchy[CurrentDepth];
    for i := 0 to ClassNames.Count - 1 do
    begin
      ClassTag := ClassNames[i];
      // look for matching children
      if (Depth = CurrentDepth) and FChildren.TryGetValue(ClassTag.ClassIndex, Children) then
          EvaluateList(Children);

      // look for matching descendants
      if FDescendants.TryGetValue(ClassTag.ClassIndex, Children) then
          EvaluateList(Children);
    end;
    if ClassNames.Count > 1 then
    begin
      // look for matching multi children
      if (Depth = CurrentDepth) then
          EvaluateMulti(FMultiChildren);
      // look for matching multi descendants
      EvaluateMulti(FMultiDescendants);
    end;
  end;

  if assigned(FStyles) and (Depth >= ClassHierarchy.Count) then
      Stack.AddStyleSheet(RGUIStyleSheet.Create(Specificity, FStyles, self.FullIdentifier));
end;

constructor TGUIStyleNode.Create(const FullIdentifier : string);
begin
  FDescendants := TObjectDictionary < integer, TObjectList < TMultiStyleNode >>.Create([doOwnsValues]);
  FChildren := TObjectDictionary < integer, TObjectList < TMultiStyleNode >>.Create([doOwnsValues]);
  FMultiDescendants := TObjectList < TTuple < TArray<integer>, TObjectList<TMultiStyleNode> >>.Create;
  FMultiChildren := TObjectList < TTuple < TArray<integer>, TObjectList<TMultiStyleNode> >>.Create;
  FFullIdentifier := FullIdentifier;
end;

destructor TGUIStyleNode.Destroy;
begin
  FDescendants.Free;
  FChildren.Free;
  FMultiDescendants.Free;
  FMultiChildren.Free;
  FStyles.Free;
  inherited;
end;

{ TMultiStyleNode }

constructor TMultiStyleNode.Create(const PseudoClass : SetPseudoClass; Node : TGUIStyleNode; const Specificity : RIntVector2);
begin
  self.PseudoClass := PseudoClass;
  self.Node := Node;
  self.Specificity := Specificity;
end;

destructor TMultiStyleNode.Destroy;
begin
  Node.Free;
  inherited;
end;

{ TGUIStyleSheetStack }

constructor TGUIStyleSheetStack.Create(Manager : TGUIStyleManager);
begin
  FManager := Manager;
  FStyles := TList<RGUIStyleSheet>.Create(
    TComparer<RGUIStyleSheet>.Construct(
    function(const Left, Right : RGUIStyleSheet) : integer
    begin
      // negate order to sort from high to low
      Result := -(Left.Specificity.X - Right.Specificity.X);
      if Result = 0 then
          Result := -(Left.Specificity.Y - Right.Specificity.Y);
    end));
  FStyleIDs := TList < RTuple < integer, SetGSSTag >>.Create(
    TComparer < RTuple < integer, SetGSSTag >>.Construct(
    function(const Left, Right : RTuple<integer, SetGSSTag>) : integer
    begin
      Result := (Left.a - Right.a);
    end));
end;

destructor TGUIStyleSheetStack.Destroy;
begin
  FStyles.Free;
  FStyleIDs.Free;
  FSquashedStyles.Free;
  inherited;
end;

procedure TGUIStyleSheetStack.AddStyleSheet(Stylesheet : RGUIStyleSheet);
begin
  // skip empty style sheets, as they are nonsense and interfere with hash computation
  if Stylesheet.Style.CoveredTags <> [] then
      FStyles.Add(Stylesheet);
end;

procedure TGUIStyleSheetStack.FinalizeStack;
var
  i : integer;
  IDList : TArray<integer>;
begin
  FStyles.Sort;
  FCoveredTags := [];
  FSquashedStyles := TGUIStyleSheet.Create;
  setLength(IDList, FStyles.Count);
  for i := 0 to FStyles.Count - 1 do
  begin
    IDList[i] := FStyles[i].Style.ID;
    FStyleIDs.Add(RTuple<integer, SetGSSTag>.Create(FStyles[i].Style.ID, FStyles[i].Style.CoveredTags));
    FCoveredTags := FCoveredTags + FStyles[i].Style.CoveredTags;
    FSquashedStyles.AddDefinitionsFromStyleSheet(FStyles[i].Style, False);
  end;
  FHash := THashBobJenkins.GetHashValue(IDList[0], SizeOf(integer) * length(IDList));
  FStyleIDs.Sort;
end;

function TGUIStyleSheetStack.ChangedTags(const AnotherStack : TGUIStyleSheetStack) : SetGSSTag;
var
  i, j, ID, id2 : integer;
begin
  i := 0;
  j := 0;
  Result := [];
  while ((i < FStyleIDs.Count) or (j < AnotherStack.FStyleIDs.Count)) do
  begin
    if (i < FStyleIDs.Count) and (j < AnotherStack.FStyleIDs.Count) then
    begin
      ID := FStyleIDs[i].a;
      id2 := AnotherStack.FStyleIDs[j].a;
      if ID = id2 then
      begin
        // same ids => no changes
        inc(i);
        inc(j);
      end
      else
      begin
        // lower id is added to changes as ids are sorted
        if ID < id2 then
        begin
          Result := Result + FStyleIDs[i].b;
          inc(i);
        end
        else
        begin
          Result := Result + AnotherStack.FStyleIDs[j].b;
          inc(j);
        end;
      end;
    end
    else if (i < FStyleIDs.Count) then
    begin
      Result := Result + FStyleIDs[i].b;
      inc(i);
    end
    else
    begin
      Result := Result + AnotherStack.FStyleIDs[j].b;
      inc(j);
    end;
  end;
end;

function TGUIStyleSheetStack.ComputedStyles : string;
var
  i : integer;
begin
  Result := '';
  for i := 0 to FStyles.Count - 1 do
  begin
    Result := Result + FStyles[i].FullIdentifier.Trim + '{' + sLineBreak;
    Result := Result + '  ' + FStyles[i].Style.DataAsText.Replace(sLineBreak, sLineBreak + '  ').Trim + sLineBreak;
    Result := Result + '}' + sLineBreak + sLineBreak;
  end;
end;

function TGUIStyleSheetStack.IsEqual(const AnotherStack : TGUIStyleSheetStack) : boolean;
var
  i : integer;
begin
  if (FStyles.Count <> AnotherStack.FStyles.Count) or (FCoveredTags <> AnotherStack.CoveredTags) then exit(False);
  Result := True;
  for i := 0 to FStyles.Count - 1 do
    if FStyles[i] <> AnotherStack.FStyles[i] then exit(False);
end;

function TGUIStyleSheetStack.TryGetValue<T>(Stylename : EnumGSSTag; Index : integer; out Value : T) : boolean;
begin
  Result := (Stylename in CoveredTags) and FSquashedStyles.TryGetValue<T>(Stylename, index, Value);
end;

function TGUIStyleSheetStack.ValueCount(Stylename : EnumGSSTag) : integer;
begin
  Result := 0;
  if Stylename in CoveredTags then
      Result := FSquashedStyles.ValueCount(Stylename);
end;

{ RClassTag }

function RClassTag.ClassIndices : TArray<integer>;
begin
  if IsMulti then
      Result := self.MultiClassIndex
  else
      Result := [self.ClassIndex]
end;

constructor RClassTag.Create(ClassIndex : integer; PseudoClasses : SetPseudoClass);
begin
  self.IsChild := False;
  self.IsMulti := False;
  self.CustomSpecificity := RIntVector2.ZERO;
  self.ClassIndex := ClassIndex;
  self.PseudoClasses := PseudoClasses;
end;

class operator RClassTag.equal(const L, R : RClassTag) : boolean;
begin
  Result := (L.IsMulti = R.IsMulti) and
    (L.PseudoClasses = R.PseudoClasses) and
    ((not L.IsMulti and (L.ClassIndex = R.ClassIndex)) or
    (L.IsMulti and HArray.Compare<integer>(L.ClassIndices, R.ClassIndices)));
end;

function RClassTag.GetClassName : string;
var
  i : integer;
begin
  if not IsMulti then Result := TGUIStyleManager.RemapClassname(ClassIndex)
  else
  begin
    Result := '';
    for i := 0 to length(MultiClassIndex) - 1 do Result := Result + TGUIStyleManager.RemapClassname(MultiClassIndex[i]);
  end;
end;

function RClassTag.Hash : integer;
begin
  Result := ClassIndex xor THashBobJenkins.GetHashValue(PseudoClasses, SizeOf(SetPseudoClass))
end;

function RClassTag.IsParent : boolean;
begin
  if IsMulti then Result := (length(MultiClassIndex) > 0) and (MultiClassIndex[0] = 0)
  else Result := ClassIndex = 0;
end;

function RClassTag.Merge(const ClassTag : RClassTag) : RClassTag;
var
  i : integer;
begin
  Result.ClassIndex := -1;
  Result.IsChild := IsChild;
  Result.PseudoClasses := PseudoClasses + ClassTag.PseudoClasses;
  Result.CustomSpecificity := CustomSpecificity + ClassTag.CustomSpecificity;

  // merge classes to multiclass
  if IsMulti then Result.MultiClassIndex := Copy(MultiClassIndex)
  else Result.MultiClassIndex := [ClassIndex];
  if ClassTag.IsMulti then Result.MultiClassIndex := Result.MultiClassIndex + ClassTag.MultiClassIndex
  else Result.MultiClassIndex := Result.MultiClassIndex + [ClassTag.ClassIndex];

  // remove parent (&) classes
  for i := length(Result.MultiClassIndex) - 1 downto 0 do
    if Result.MultiClassIndex[i] = 0 then HArray.Delete<integer>(Result.MultiClassIndex, i);

  // if there is only one class reorganize to single class tag
  Result.IsMulti := length(Result.MultiClassIndex) > 1;
  if not Result.IsMulti and (length(Result.MultiClassIndex) = 1) then
      Result.ClassIndex := Result.MultiClassIndex[0];
end;

function RClassTag.Specificity : RIntVector2;
var
  Pseudo : EnumPseudoClass;
  i : integer;
begin
  Result := RIntVector2.Create(0, 0);
  if not IsMulti then Result.X := TGUIStyleManager.ClassnameSpecificity(self.ClassIndex)
  else
    for i := 0 to length(MultiClassIndex) - 1 do Result.X := Result.X + TGUIStyleManager.ClassnameSpecificity(MultiClassIndex[i]);
  for Pseudo in self.PseudoClasses do
      inc(Result.Y, ord(Pseudo));
  Result := Result + CustomSpecificity;
end;

{ RGUIStyleSheet }

constructor RGUIStyleSheet.Create(const Specificity : RIntVector2; Style : TGUIStyleSheet; const FullIdentifier : string);
begin
  self.Specificity := Specificity;
  self.Style := Style;
  self.FullIdentifier := FullIdentifier;
end;

class operator RGUIStyleSheet.equal(const a, b : RGUIStyleSheet) : boolean;
begin
  Result := (a.Style = b.Style) and (a.Specificity = b.Specificity) and (a.FullIdentifier = b.FullIdentifier);
end;

class operator RGUIStyleSheet.notequal(const a, b : RGUIStyleSheet) : boolean;
begin
  Result := (a.Style <> b.Style) or (a.Specificity <> b.Specificity) or (a.FullIdentifier <> b.FullIdentifier);
end;

{ RGUIStyleConstant }

function RGUIStyleConstant.Apply(const Text : string) : string;
var
  Regex : TRegex;
  Constant : RGUIStyleConstant;
begin
  // without params
  if length(KeyParams) <= 0 then Result := Text.Replace(Key, Value)
  else
  begin
    // with params
    Regex := TRegex.Create(Key, [roIgnoreCase, roMultiLine]);
    Constant := self;
    Result := Regex.MultiSubstitute(Text,
      function(sub : array of string) : string
      var
        params : TArray<string>;
        i : integer;
      begin
        if length(sub) <= 0 then exit('');
        Result := Constant.Value;
        params := sub[0].Split([',']);
        if length(Constant.KeyParams) <> length(params) then HLog.Write(elInfo, 'RGUIStyleConstant.Apply: Invalid paramcount! Key: %s Replace %s', [Constant.Key, sub[0]]);

        for i := 0 to Min(length(Constant.KeyParams), length(params)) - 1 do
        begin
          Result := Result.Replace(Constant.KeyParams[i], params[i]);
        end;
      end);
  end;
end;

constructor RGUIStyleConstant.Create(const Key, Value : string);
var
  KeyID, KeyParamString : string;
begin
  self.Key := Key;
  if Key.Contains('(') then
  begin
    // build regex from parametrized constant, e.g. $constant-name(paramname, paramname2)
    KeyID := HString.TrimAfter('(', Key); // $constant-name
    KeyParamString := HString.TrimBefore('(', Key).Replace(')', '').Replace(' ', ''); // paramname,paramname2
    KeyParams := KeyParamString.Split([',']); // [paramname, paramname2];
    if length(KeyParams) <= 0 then
    begin
      // no params $constant-name() => $constant-name
      self.Key := KeyID;
      self.KeyParams := nil;
    end
    else
    begin
      // build regex
      self.Key := KeyID.Replace('$', '\$') + '\(([^)]+?)\);'; // \$constant-name\(([^)]+?)\);
    end;
  end
  else self.KeyParams := nil;
  self.Value := Value;
end;

{ TGUIComponentSet }

procedure TGUIComponentSet.Add(const Component : TGUIComponent);
begin
  FItems.Add(Component);
end;

function TGUIComponentSet.BindClass(const Value : RQuery; const GSSClass : string) : IGUIComponentSet;
begin
  Result := self;
  raise ENotImplemented.Create('TGUIComponentSet.BindClass: Is not implemented!');
  FItems.Query.Filter(Value).Each(
    procedure(const item : TGUIComponent)
    begin
      item.BindClass(True, GSSClass);
    end);
  FItems.Query.exclude(Value).Each(
    procedure(const item : TGUIComponent)
    begin
      item.BindClass(False, GSSClass);
    end);
end;

function TGUIComponentSet.Count : integer;
begin
  Result := FItems.Count;
end;

constructor TGUIComponentSet.Create;
begin
  FItems := TUltimateList<TGUIComponent>.Create;
end;

destructor TGUIComponentSet.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TGUIComponentSet.GetItem(Index : integer) : TGUIComponent;
begin
  Result := FItems[index];
end;

{ TGUIStyleSheetStackHandle }

constructor TGUIStyleSheetStackHandle.Create(Manager : TGUIStyleManager; StyleSheetStack : TGUIStyleSheetStack);
begin
  inherited Create(Manager);
  self.StyleSheetStack := StyleSheetStack;
end;

{ TClassHierarchyNode }

function TClassHierarchyNode.Clone : TClassHierarchyNode;
var
  i : integer;
begin
  Result := TClassHierarchyNode.Create;
  for i := 0 to self.Count - 1 do
      Result.Add(self[i]);
  if FMulticlassReady then
  begin
    Result.FMulticlassReady := True;
    Result.FMulticlass := FMulticlass;
  end;
end;

function TClassHierarchyNode.Hash : integer;
var
  i : integer;
begin
  if not FHashReady then
  begin
    FHash := 0;
    for i := 0 to self.Count - 1 do
    begin
      FHash := FHash xor self[i].Hash;
    end;
    FHashReady := True;
  end;
  Result := FHash;
end;

function TClassHierarchyNode.Multiclass : RClassTag;
var
  i : integer;
begin
  if not FMulticlassReady then
  begin
    if self.Count > 0 then
    begin
      FMulticlass := self[0];
      for i := 1 to self.Count - 1 do
          FMulticlass := FMulticlass.Merge(self[i]);
    end;
    FMulticlassReady := True;
  end;
  Result := FMulticlass
end;

{ TClassHierarchy }

function TClassHierarchy.Clone : TClassHierarchy;
var
  i : integer;
begin
  Result := TClassHierarchy.Create(True);
  for i := 0 to self.Count - 1 do
      Result.Add(self[i].Clone);
  // don't clone hash, as cloning always lead to altering class hierarchy afterwards
end;

function TClassHierarchy.CompareTo(const R : TClassHierarchy) : boolean;
var
  i, j : integer;
begin
  Result := (self.Hash = R.Hash) and (self.Count = R.Count);
  if Result then
  begin
    for i := 0 to self.Count - 1 do
    begin
      Result := self[i].Count = R[i].Count;
      if Result then
      begin
        for j := 0 to self[i].Count - 1 do
        begin
          Result := self[i][j] = R[i][j];
          if not Result then exit;
        end;
      end
      else exit;
    end;
  end;
end;

function TClassHierarchy.Hash : integer;
var
  i : integer;
begin
  if not FHashReady then
  begin
    FHash := 0;
    for i := 0 to self.Count - 1 do
        FHash := FHash xor self[i].Hash;
    FHashReady := True;
  end;
  Result := FHash;
end;

{ TGUIAnimationStack }

constructor TGUIAnimationStack.CreateFromString(const AnimationData : string);
var
  Key, Value : string;
  Blocks : TArray<string>;
  i : integer;
  TimeKey : single;
  Styles : TGUIStyleSheet;
  Style : EnumGSSTag;
  SetStyles : TDictionary<EnumGSSTag, RParam>;
  AnimationCurve : TList<RTriple<single, RCubicBezier, RParam>>;
  Bezier : RCubicBezier;
begin
  FAnimationKeys := TObjectDictionary < EnumGSSTag, TList < RTriple<single, RCubicBezier, RParam> >>.Create([doOwnsValues]);
  // space ensures that, all cases of last closing parenthesis can be handled the same after splitting
  Blocks := (AnimationData + ' ').Split(['}']);
  // last block should be empty
  for i := 0 to length(Blocks) - 2 do
  begin
    Key := HString.TrimAfter('{', Blocks[i]).Replace('%', '').Trim;
    TimeKey := HMath.Saturate(TGUIStyleSheet.CSSStrToFloat(Key, 0.0) / 100);
    Value := HString.TrimBefore('{', Blocks[i]);
    Styles := TGUIStyleSheet.CreateFromText(Value);
    SetStyles := Styles.Items;
    Bezier := RCubicBezier.LINEAR;
    Styles.TryGetValue<single>(gtAnimationTimingFunction, 0, Bezier.P1X);
    Styles.TryGetValue<single>(gtAnimationTimingFunction, 1, Bezier.P1Y);
    Styles.TryGetValue<single>(gtAnimationTimingFunction, 2, Bezier.P2X);
    Styles.TryGetValue<single>(gtAnimationTimingFunction, 3, Bezier.P2Y);
    SetStyles.Remove(gtAnimationTimingFunction);
    Styles.Free;
    for Style in SetStyles.Keys do
    begin
      if not FAnimationKeys.TryGetValue(Style, AnimationCurve) then
      begin
        AnimationCurve := TList < RTriple < single, RCubicBezier, RParam >>.Create;
        FAnimationKeys.Add(Style, AnimationCurve);
      end;
      AnimationCurve.Add(RTriple<single, RCubicBezier, RParam>.Create(TimeKey, Bezier, SetStyles[Style]));
    end;
    SetStyles.Free;
  end;
end;

destructor TGUIAnimationStack.Destroy;
begin
  FAnimationKeys.Free;
  inherited;
end;

function TGUIAnimationStack.HasTag(Tag : EnumGSSTag) : boolean;
begin
  Result := FAnimationKeys.ContainsKey(Tag);
end;

function TGUIAnimationStack.Interpolate(const Key : single; Tag : EnumGSSTag) : RParam;
var
  AnimationCurve : TList<RTriple<single, RCubicBezier, RParam>>;
  i : integer;
  localKey : single;
  function BuildResult(i, j : integer; s : single) : RParam;
  begin
    if i = j then
    begin
      case Tag of
        gtOpacity : Result := AnimationCurve[i].c.AsSingle;
        gtTransform : Result := RParam.From<RMatrix4x3>(TGUIStyleSheet.ResolveTransform(AnimationCurve[i].c.AsString));
        gtBackgroundColorOverride : Result := RParam.From<RColor>(AnimationCurve[i].c.AsType<RColor>);
      else
        raise ENotImplemented.Create('TGUIAnimationStack.Interpolate: Not implemented for tag!');
      end;
    end
    else
    begin
      s := AnimationCurve[i].b.Solve(s);
      case Tag of
        gtOpacity : Result := AnimationCurve[i].c.AsSingle * (1 - s) + AnimationCurve[j].c.AsSingle * s;
        gtTransform : Result := RParam.From<RMatrix4x3>(TGUIStyleSheet.ResolveTransform(AnimationCurve[i].c.AsString).Interpolate(
            TGUIStyleSheet.ResolveTransform(AnimationCurve[j].c.AsString), s));
        gtBackgroundColorOverride : Result := RParam.From<RColor>(AnimationCurve[i].c.AsType<RColor>.Lerp(AnimationCurve[j].c.AsType<RColor>, s));
      else
        raise ENotImplemented.Create('TGUIAnimationStack.Interpolate: Not implemented for tag!');
      end;
    end;
  end;

begin
  if (Tag in [gtOpacity, gtTransform, gtBackgroundColorOverride]) and FAnimationKeys.TryGetValue(Tag, AnimationCurve) and (AnimationCurve.Count > 0) then
  begin
    i := 0;
    if AnimationCurve.First.a > Key then exit(BuildResult(0, 0, 0));
    if AnimationCurve.Last.a <= Key then exit(BuildResult(AnimationCurve.Count - 1, AnimationCurve.Count - 1, 0));
    while i <= AnimationCurve.Count - 2 do
    begin
      if (AnimationCurve[i].a <= Key) and (AnimationCurve[i + 1].a > Key) then
      begin
        localKey := (Key - AnimationCurve[i].a) / (AnimationCurve[i + 1].a - AnimationCurve[i].a);
        exit(BuildResult(i, i + 1, localKey));
      end;
      inc(i);
    end;
    Result := RParamEmpty;
  end
  else Result := RParamEmpty;
end;

{ TGUIStyleManagerHandle }

constructor TGUIStyleManagerHandle.Create(Manager : TGUIStyleManager);
begin
  FManager := Manager;
  FVersion := FManager.CurrentVersion;
end;

function TGUIStyleManagerHandle.IsValid : boolean;
begin
  Result := FVersion = FManager.CurrentVersion;
end;

{ TGUIAnimationStackHandle }

constructor TGUIAnimationStackHandle.Create(Manager : TGUIStyleManager; AnimationStack : TGUIAnimationStack);
begin
  inherited Create(Manager);
  self.AnimationStack := AnimationStack;
end;

{ TGUITransitionValue<T> }

constructor TGUITransitionValue<T>.Create;
begin
  FTimingFunction := RCubicBezier.LINEAR;
end;

function TGUITransitionValue<T>.CurrentFactor : single;
begin
  if Duration <= 0 then
      Result := 1.0
  else
      Result := TimingFunction.Solve(HMath.Saturate((TimeManager.GetTimeStamp - FStartingTimestamp) / Duration));
end;

procedure TGUITransitionValue<T>.SetValue(const Value : T);
begin
  if not FInitialized then
  begin
    FInitialized := True;
    FStartValue := Value;
    FTargetValue := Value;
  end;
  if not CompareMem(@FTargetValue, @Value, SizeOf(T)) then
  begin
    FStartValue := CurrentValue;
    FStartingTimestamp := TimeManager.GetTimeStamp;
  end;
  FTargetValue := Value;
end;

{ TGUITransitionValueRMatrix4x3 }

function TGUITransitionValueRMatrix4x3.CurrentValue : RMatrix4x3;
begin
  Result := FStartValue.Interpolate(FTargetValue, CurrentFactor);
end;

{ TGUITransitionValueRColor }

function TGUITransitionValueRColor.CurrentValue : RColor;
begin
  Result := FStartValue.Lerp(FTargetValue, CurrentFactor);
end;

{ TGUITransitionValueSingle }

function TGUITransitionValueSingle.CurrentValue : single;
begin
  Result := HMath.LinLerpF(FStartValue, FTargetValue, CurrentFactor);
end;

initialization

TGUIProgressBar.ClassName;
TGUIStackPanel.ClassName;
TGUIEdit.ClassName;
TGUI.HintDelay := 500;
TGUI.HintDisplayTime := 10000;

end.
