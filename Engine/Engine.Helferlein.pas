unit Engine.Helferlein;

interface

uses
  System.Math,
  System.Rtti,
  System.DateUtils,
  System.TypInfo,
  System.Classes,
  System.SysConst,
  System.SysUtils,
  System.UITypes,
  Generics.Defaults,
  Generics.Collections,
  Engine.Math;

const
  iTrue  = 1;
  iFalse = 0;

type
  /// <summary> Raised if an item or whatever not found.</summary>
  ENotFoundException = class(Exception);
  /// <summary> Raise if bounds of an array or list are violated.</summary>
  EOutOfBoundException = class(Exception);
  EUnsupportedException = class(Exception);

  AString = TArray<string>;
  SetChar = set of AnsiChar; // set of Char isn't possible, as sets contains at max 256 values

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  ProcString = reference to procedure(const Value : string);

  AStringHelper = record helper for AString
    procedure Each(const Callback : ProcString);
    function Count : integer; inline;
  end;

  /// <summary> Useful in situation where two classes share a datum and can die before each other. </summary>
  ISharedData<T> = interface
    function GetData : T;
    function SetData(const Value : T) : T;
  end;

  TSharedData<T> = class(TInterfacedObject, ISharedData<T>)
    protected
      FData : T;
    public
      function GetData : T;
      function SetData(const Value : T) : T;
  end;

  PColor = ^RColor;

  RColor = packed record
    private
      function getAlphaByte : Byte;
      function getBlueByte : Byte;
      function getBGRCardinal : Cardinal;
      function getGreenByte : Byte;
      function getRedByte : Byte;
      function getHSV : RVector3;
      procedure setAlphaByte(const Value : Byte);
      procedure setBlueByte(const Value : Byte);
      procedure setBGRCardinal(const Value : Cardinal);
      procedure setGreenByte(const Value : Byte);
      procedure setRedByte(const Value : Byte);
      procedure setHSV(const HSV : RVector3);
      function getBGRA : RColor;
      procedure setBGRA(const Value : RColor);
      function getCardinal : Cardinal;
      procedure setCardinal(const Value : Cardinal);
      function getBGR : RVector3;
      procedure setBGR(const Value : RVector3);
    public
      property AlphaByte : Byte read getAlphaByte write setAlphaByte;
      property RedByte : Byte read getRedByte write setRedByte;
      property GreenByte : Byte read getGreenByte write setGreenByte;
      property BlueByte : Byte read getBlueByte write setBlueByte;
      property BGR : RVector3 read getBGR write setBGR;
      property BGRA : RColor read getBGRA write setBGRA;
      /// <summary> Hue, Saturation, Value all in range [0.0,1.0]. </summary>
      property HSV : RVector3 read getHSV write setHSV;
      property AsCardinal : Cardinal read getCardinal write setCardinal;
      property AsBGRCardinal : Cardinal read getBGRCardinal write setBGRCardinal;

      function RGB1 : RColor;

      procedure SetGrey(Value : Single);
      function MaxChannel : Single;
      function Difference(const Value : RColor) : RColor;
      function Lerp(const ZielFarbe : RColor; s : Single) : RColor;
      function ToHexString(Precision : integer = 8; WithDollar : boolean = True) : string;
      function ToPhotoshopString() : string;
      function ToCSSString() : string;
      function ToConstantString() : string;
      function ToHLSLString() : string;
      function ToHLSLStringWithoutAlpha() : string;
      function AdjustSaturation(s : Single) : RColor;
      function Desaturate : Single;
      function IsFullTransparent : boolean;
      function IsTransparentBlack : boolean;
      /// <summary> Switches from Alpha to Opacity and vice versa. </summary>
      function InvertAlpha : RColor;
      function SetAlphaF(Value : Single) : RColor; overload;
      /// <summary> Multiplies alpha value with color </summary>
      function PremultiplyAlpha : RColor;
      /// <summary> Average two colors using their premultiplied expressions. </summary>
      function Average(const AnotherColor : RColor) : RColor; overload;

      constructor Create(Color : Cardinal); overload;
      constructor CreateFromBGRCardinal(Color : Cardinal); overload;
      constructor CreateGrey(Color : Byte); overload;
      constructor Create(const HexColorAsString : string); overload;
      constructor Create(Red, Green, Blue, Alpha : Byte); overload;
      constructor Create(Red, Green, Blue : integer; Alpha : integer = 255); overload;
      constructor CreateFromSingle(Red, Green, Blue, Alpha : Single); overload;
      /// <summary> Hue, Saturation, Value all in range [0.0,1.0]. </summary>
      constructor CreateFromHSV(const HueSaturationValue : RVector3); overload;
      constructor CreateFromHSV(Hue, Saturation, Value : Single); overload;
      constructor CreateFromCSS(const ColorString : string);
      constructor CreateFromHLSL(const ColorString : string);
      /// <summary> Tries to parse color from different formats. If not valid string, creates CTRANSPARENTBLACK. </summary>
      constructor CreateFromString(const ColorString : string);

      /// <summary> Linear average of the given colors. If array is empty, returns CTRANSPARENTBLACK. </summary>
      class function Average(Colors : array of RColor) : RColor; overload; static;
      /// <summary> Prevents bleeding from colors with high transparency. If array is empty, returns CTRANSPARENTBLACK. </summary>
      class function AverageWithAlpha(Colors : array of RColor) : RColor; overload; static;
      class function LerpArray(Farben : array of RColor; s : Single) : RColor; overload; static;
      class function LerpArray(Farben : array of Cardinal; s : Single) : RColor; overload; static;
      class function LerpList(Farben : TList<RColor>; s : Single) : RColor; static;

      class function TryFromString(const Value : string; out Color : RColor) : boolean; static;

      class operator Add(const A, B : RColor) : RColor;
      class operator equal(const A, B : RColor) : boolean;
      class operator Notequal(const A, B : RColor) : boolean;
      class operator Notequal(const A : RColor; B : Cardinal) : boolean;
      class operator Subtract(const A, B : RColor) : RColor;
      class operator Subtract(const A : RColor; B : Byte) : RColor;
      class operator Multiply(const A, B : RColor) : RColor;
      class operator Multiply(const A : RColor; B : Single) : RColor;
      class operator Multiply(A : Single; const B : RColor) : RColor;
      class operator Implicit(A : Cardinal) : RColor;
      class operator Implicit(const A : RVector4) : RColor;
      class operator Implicit(const A : RColor) : RVector4;
      class operator Implicit(const A : RColor) : TValue;
      class operator Implicit(const A : RColor) : string;
      case Byte of
        0 : (RGBA : RVector4);
        1 : (RGB : RVector3);
        2 : (RG, BA : RVector2);
        3 : (R, G, B, A : Single);
  end;

  ARColor = TArray<RColor>;

type

  RColorHelper = record helper for RColor
    public
      const
      // special
      {$IFDEF ANDROID}
      // working around internal errors on Android
      CTRANSPARENTBLACK : Cardinal = $00000000;
      CBLACK : Cardinal            = $FF000000;
      {$ELSE}
      CTRANSPARENTBLACK : RColor = (R : 0.0; G : 0.0; B : 0.0; A : 0.0);
      CBLACK : RColor            = (R : 0.0; G : 0.0; B : 0.0; A : 1.0);
      CWHITE : RColor            = (R : 1.0; G : 1.0; B : 1.0; A : 1.0);
      CGREY : RColor             = (R : 0.5; G : 0.5; B : 0.5; A : 1.0);
      CDEFAULTNORMAL : RColor    = (R : 0.5; G : 0.5; B : 1.0; A : 0.0);
      // full colors
      CRED : RColor    = (R : 1.0; G : 0.0; B : 0.0; A : 1.0);
      CYELLOW : RColor = (R : 1.0; G : 1.0; B : 0.0; A : 1.0);
      CGREEN : RColor  = (R : 0.0; G : 1.0; B : 0.0; A : 1.0);
      CBLUE : RColor   = (R : 0.0; G : 0.0; B : 1.0; A : 1.0);
      CCYAN : RColor   = (R : 0.0; G : 1.0; B : 1.0; A : 1.0);
      CPINK : RColor   = (R : 1.0; G : 0.0; B : 1.0; A : 1.0);
      // custom
      CPURPLE : RColor         = (R : 0.5; G : 0.0; B : 0.5; A : 1.0);
      CNEONORANGE : RColor     = (R : 1.0; G : 0.451; B : 0.282; A : 1.0);
      CGRASSGREEN : RColor     = (R : 0.529; G : 0.769; B : 0.259; A : 1.0);
      CNOTEPAD_YELLOW : RColor = (R : 0.988; G : 0.976; B : 0.639; A : 1.0);
      CNOTEPAD_BLUE : RColor   = (R : 0.788; G : 0.925; B : 0.973; A : 1.000);
      CNOTEPAD_GREEN : RColor  = (R : 0.808; G : 0.988; B : 0.784; A : 1.000);
      CNOTEPAD_PINK : RColor   = (R : 0.929; G : 0.718; B : 0.929; A : 1.000);
      CNOTEPAD_VIOLET : RColor = (R : 0.788; G : 0.737; B : 0.996; A : 1.000);
      CNOTEPAD_WHITE : RColor  = (R : 0.937; G : 0.937; B : 0.937; A : 1.000);
      // wc3 player colors
      CWC3_RED : RColor       = (R : 1.000; G : 0.008; B : 0.008; A : 1.000);
      CWC3_BLUE : RColor      = (R : 0.000; G : 0.255; B : 1.000; A : 1.000);
      CWC3_CYAN : RColor      = (R : 0.106; G : 0.898; B : 0.722; A : 1.000);
      CWC3_PURPLE : RColor    = (R : 0.325; G : 0.000; B : 0.502; A : 1.000);
      CWC3_YELLOW : RColor    = (R : 1.000; G : 1.000; B : 0.000; A : 1.000);
      CWC3_ORANGE : RColor    = (R : 0.996; G : 0.537; B : 0.051; A : 1.000);
      CWC3_GREEN : RColor     = (R : 0.122; G : 0.749; B : 0.000; A : 1.000);
      CWC3_PINK : RColor      = (R : 0.894; G : 0.353; B : 0.667; A : 1.000);
      CWC3_GREY : RColor      = (R : 0.580; G : 0.584; B : 0.588; A : 1.000);
      CWC3_LIGHTBLUE : RColor = (R : 0.490; G : 0.745; B : 0.945; A : 1.000);
      CWC3_DARKGREEN : RColor = (R : 0.059; G : 0.380; B : 0.271; A : 1.000);
      CWC3_BROWN : RColor     = (R : 0.302; G : 0.161; B : 0.012; A : 1.000);
      // color arrays
      COLORSPECTRUMARRAY : array [0 .. 5] of RColor = ((R : 1.0; G : 0.0; B : 0.0; A : 1.0), (R : 1.0; G : 1.0; B : 0.0; A : 1.0), (R : 0.0; G : 1.0; B : 0.0; A : 1.0), (R : 0.0; G : 1.0; B : 1.0; A : 1.0), (R : 0.0; G : 0.0; B : 1.0; A : 1.0), (R : 1.0; G : 0.0; B : 1.0; A : 1.0));
      RGB_ARRAY : array [0 .. 2] of RColor          = ((R : 1.0; G : 0.0; B : 0.0; A : 1.0), (R : 0.0; G : 1.0; B : 0.0; A : 1.0), (R : 0.0; G : 0.0; B : 1.0; A : 1.0));
      HORIZON : array [0 .. 4] of RColor            = ((R : 0.0; G : 0.345; B : 0.91; A : 1.0), (R : 0.188; G : 0.506; B : 0.941; A : 1.0), (R : 0.376; G : 0.671; B : 0.973; A : 1.0), (R : 0.478; G : 0.737; B : 1.0; A : 1.0), (R : 0.749; G : 0.875; B : 1.0; A : 1.0));
      HUEARRAY : array [0 .. 6] of RColor           = ((R : 1.0; G : 0.0; B : 0.0; A : 1.0), (R : 1.0; G : 0.0; B : 1.0; A : 1.0), (R : 0.0; G : 0.0; B : 1.0; A : 1.0), (R : 0.0; G : 1.0; B : 1.0; A : 1.0), (R : 0.0; G : 1.0; B : 0.0; A : 1.0), (R : 1.0; G : 1.0; B : 0.0; A : 1.0), (R : 1.0; G : 0.0; B : 0.0; A : 1.0));
      {$ENDIF}
  end;

type

  CAttribute = class of TCustomAttribute;

  ProcMethodFilter = reference to function(RttiMethod : TRttiMethod) : boolean;

  HRtti = class
    private
      class function HelperSetToString(Info : PTypeInfo; const Value; const Separator, Prefix, Suffix : string) : string;
    public
      /// <summary> Look for a specific attribute class in an array of attributes and return the first matching. Nil if not found. </summary>
      class function SearchForAttribute(AttributeLookingFor : TClass; Attributes : TArray<TCustomAttribute>) : TCustomAttribute;
      /// <summary> Loof for a specific attribute class in an array of attributes and return all matching. </summary>
      class function SearchForAttributes(AttributeLookingFor : TClass; Attributes : TArray<TCustomAttribute>) : TArray<TCustomAttribute>;
      /// <summary> Returns True, if target instance based on a class which is marked with AttributeLookingFor.</summary>
      class function HasAttribute(Instance : TObject; AttributeLookingFor : CAttribute) : boolean; overload;
      /// <summary> Returns True, if target class which is marked with AttributeLookingFor.</summary>
      class function HasAttribute(AClass : TClass; AttributeLookingFor : CAttribute) : boolean; overload;
      /// <summary> Returns True, if target type is marked with AttributeLookingFor.</summary>
      class function HasAttributeType(AType : TRttiObject; AttributeLookingFor : CAttribute) : boolean;
      /// <summary> Returns True, if AttributeLookingFor is in Attributes.</summary>
      class function HasAttribute(const Attributes : TArray<TCustomAttribute>; AttributeLookingFor : CAttribute) : boolean; overload;
      /// <summary> Returns the attribute instance, if target instance based on a class which is marked with AttributeLookingFor,
      /// else returns nil.</summary>
      class function GetAttribute(Instance : TObject; AttributeLookingFor : CAttribute) : TCustomAttribute; overload;
      class function GetAttribute(AClass : TClass; AttributeLookingFor : CAttribute) : TCustomAttribute; overload;
      class function GetAttribute(const Attributes : TArray<TCustomAttribute>; AttributeLookingFor : CAttribute) : TCustomAttribute; overload;
      /// <summary> Returns all attribute instances, if they base on a class which is marked with AttributeLookingFor,
      /// else returns nil.</summary>
      class function GetAttributes(Instance : TObject; AttributeLookingFor : CAttribute) : TArray<TCustomAttribute>; overload;
      class function GetAttributes(AClass : TClass; AttributeLookingFor : CAttribute) : TArray<TCustomAttribute>; overload;
      /// <summary> Returns the first method that passes the filter method. If no found, an exception is raised.</summary>
      class function GetMethod(const Methods : TArray<TRttiMethod>; const Filter : ProcMethodFilter) : TRttiMethod; overload;
      /// <summary> Returns the first method that passed the filter. If no found, an exception is raised.</summary>
      class function GetMethod(const Methods : TArray<TRttiMethod>; const MethodName : string; ParameterCount : integer) : TRttiMethod; overload;
      class function SetToString(const aSet : TSysCharSet; StartDelimiter : string = '['; EndDelimiter : string = ']'; Seperator : string = ',') : string; overload;
      class function SetToString<T>(aSet : T) : string; overload;
      /// <summary> Works only with integer, so no sets with more than 32 elements are supported. </summary>
      class function StringToSet<T>(SetAsString : string; FailSilently : boolean = True) : T;
      /// <summary> Works only with integer, so no sets with more than 32 elements are supported. </summary>
      class function TryStringToSet<T>(SetAsString : string; out aSet : T) : boolean;
      class function EnumerationToString<T>(AEnumeration : T) : string;
      /// <summary> Returns for a string the corresponding enumerationvalue. If there isn't a match an invalid (-1) value is returned. </summary>
      class function StringToEnumeration<T>(EnumerationAsString : string; FailSilently : boolean = True) : T;
      /// <summary> Returns for a string the corresponding enumerationvalue. Returns whether there was a match or not. </summary>
      class function TryStringToEnumeration<T>(EnumerationAsString : string; out Value : T) : boolean;
      class function EnumerationToInteger<T>(ANEnumeration : T) : integer;
      class function TryIntegerToEnumeration<T>(EnumerationOrd : integer; out Value : T) : boolean;
      class function IntegerToEnumeration<T>(EnumerationOrd : integer) : T;
      class function EnumerationTypeToStringList<T> : TStrings;

      // ----------------------------------------------------------------------------------------------
      // Wrapper methods for Typeinfo related actions -------------------------------------------------
      // ----------------------------------------------------------------------------------------------
      /// <summary> Returns the TypeKind of T. </summary>
      class function GetTypeKindOf<T> : TTypeKind; inline; static;
  end;

  /// <summary> Class helper for TRttiMethod. Extends this information with some useful methods, like IsAbstract</summary>
  TRttiMethodHelper = class helper for TRttiMethod
    /// <summary> Return True if method is declared with flag abstract.</summary>
    function IsAbstract : boolean;
    /// <summary> Return the number of parameters.</summary>
    function ParameterCount : integer;
  end;

  TRttiTypeHelper = class helper for TRttiType
    function HasField(const AName : string) : boolean;
    function TryGetField(const AName : string; out AField : TRttiField) : boolean;
    function HasProperty(const AName : string) : boolean;
    function TryGetProperty(const AName : string; out AProperty : TRttiProperty) : boolean;
    function HasMethod(const AName : string) : boolean;
    function TryGetMethod(const AName : string; out AMethod : TRttiMethod) : boolean;
    /// <summary> Search in fields, properties and methods for member and returns it if found.</summary>
    function TryGetMember(const AName : string; out AMember : TRttiMember) : boolean;
    /// <summary> Returns the first parameterless constructor found and matching ConstructorName.
    /// If ConstructorName = '' then the methodname will ignored, if no constructor found,
    /// method will return nil.</summary>
    function GetParameterlessConstructor(const ConstructorName : string = '') : TRttiMethod;
  end;

  TRttiPropertyHelper = class helper for TRttiProperty
    private
      function IsField(P : Pointer) : boolean; inline;
      function GetCodePointer(AClass : TClass; P : Pointer) : Pointer;
    public
      /// <summary> Returns True, if property using settermethod to set value.</summary>
      function UsingSetterMethod : boolean;
      function TryGetSetterMethod(out SetterMethod : TRttiMethod) : boolean;
      function TryGetGetterMethod(out GetterMethod : TRttiMethod) : boolean;
  end;

  HGeneric = class abstract
    public
      /// <summary>Sucht in einem Array nach dem Item, wurde es gefunden wird True zurück gegeben, ansonsten False</summary>
      class function SucheItemInArray<T>(Item : T; ZuDurchsuchenderArray : array of T) : boolean; overload;
      /// <summary>Sucht in einem Array nach dem Item, wurde es gefunden wird True zurück gegeben, ansonsten False.
      /// Außerdem wird der Index des gesuchten Items in ItemIndex übergeben. Wurde das Item nicht gefunden, ist ItemIndex = -1 </summary>
      class function SucheItemInArray<T>(Item : T; ZuDurchsuchenderArray : array of T; out ItemIndex : integer) : boolean; overload;
      /// <summary>Implementiert den tertiären Operator für jeden Datentyp, da ja generisch;)
      /// Wird benutzt wie If then else, wenn Bedingung Wahr, gebe WennWahr aus, ansonsten WennFalsch</summary>
      class function TertOp<T>(Bedingung : boolean; WennWahr : T; WennFalsch : T) : T;
      /// <summary> Tauscht den Inhalt der beiden Variablen, so dass danach gilt a = b' und b = a'</summary>
      class procedure Swap<T>(var A, B : T);
      /// <summary> Converts a Variant to the generic Type </summary>
      class function ConvertVariantToGeneric<T>(Vari : Variant) : T;
      class function ConvertGenericToVariant<T>(Value : T) : Variant;
      /// <summary>  </summary>
      class function EnumerationArrayToEnumeration<TEnum, V>(inArray : array of V) : TArray<TPair<TEnum, V>>;
      class function RandomEnum<TEnum>() : TEnum;
      class procedure ArrayAppend<T>(var arr : TArray<T>; Item : T);
  end;

  HConvert = class abstract
    public
      class function FloatToStr(const Value : Single) : string;
      class function ExtractSingleFromNativeUInt(const Value : NativeUInt) : Single;
      class function PackSingleToNativeUInt(const Value : Single) : NativeUInt;
      class function ExtractIntegerFromNativeUInt(const Value : NativeUInt) : integer;
      class function PackIntegerToNativeUInt(const Value : integer) : NativeUInt;
  end;

  HDate = class abstract
    public
      class function CurrentDay : integer;
      class function CurrentMonth : integer;
      class function CurrentYear : integer;
  end;

  HArray = class abstract
    public type
      ProcEach<T> = reference to procedure(const Item : T);
      FuncMapFunction<T, U> = reference to function(const Item : T) : U;
      FuncFilterFunction<T> = reference to function(const Item : T) : boolean;
      FuncFilteredMapFunction<T, U> = reference to function(const Item : T; out Mapped : U) : boolean;
      FuncOperatorFunction<T> = reference to function(itemA, itemB : T; out newValue : T) : boolean;
      FuncLerpOperator<T> = reference to function(itemA, itemB : T; s : Single) : T;
    public
      /// <summary> Search a class in a array of classes. To search it use "is" operator.
      /// If class is found, method returns true and writes it to FoundAttribute if not nil, otherwise false</summary>
      class function SearchClassInArray<T : class>(ClassToSearch : TClass; ArrayToScan : TArray<T>; FoundAttribute : Pointer = nil) : boolean; overload;
      /// <summary> Search any class of an array in a array of classes. To search it use "is" operator. If class is found, method returns true, otherwise false</summary>
      class function SearchClassInArray<T : class>(ClassesToSearch : TArray<TClass>; ArrayToScan : TArray<T>; FoundAttribute : Pointer = nil) : boolean; overload;
      /// <summary> Convert any array to string, uses TValue for conversion of single value. With default
      /// parameters e.g. an Integer array will result in [0, 1, 2, 3]</summary>
      class function ArrayToString<T>(Data : TArray<T>; StartTag : string = '['; EndTag : string = ']'; Delimiter : string = ', ') : string;
      /// <summary> Free and nil any object in array and if desired, also free (length = 0) array.
      /// <param name="Data">Array of T (where T is a class), containing objects which should be freed and niled.</param>
      /// <param name="FreeArray">If true, arraylength is set to 0.</param></summary>
      class procedure FreeAllObjects<T : class>(var Data : TArray<T>; FreeArray : boolean); overload;
      class procedure FreeAllObjects<T : class>(Data : TArray<T>); overload;
      class procedure FreeAllObjects<T : class>(Data : array of T); overload;
      class procedure FreeAndNilAllObjects<T : class>(var Data : array of T);
      /// <summary> Returns an array with all items where the filter method say true. </summary>
      class function Filter<T>(anArray : array of T; func : FuncFilterFunction<T>) : TArray<T>;
      /// <summary> Maps anArray of type T to an array of type U with mapping function func. </summary>
      class function Map<T, U>(anArray : array of T; func : FuncMapFunction<T, U>) : TArray<U>;
      class function MapFiltered<T, U>(anArray : array of T; func : FuncFilteredMapFunction<T, U>) : TArray<U>;
      /// <summary> Return an array, where any item is unique. All duplicates from data are discarded.
      /// complexity: O(n) </summary>
      class function RemoveDuplicates<T>(Data : TArray<T>) : TArray<T>;
      /// <summary> Convert a dynamic array (open array parameter) to a TArray<>.
      /// HINT: All data of array will be COPIED, so use this method with caution!</summary>
      class function ConvertDynamicToTArray<T>(Data : array of T) : TArray<T>;
      class function ConvertEnumerableToArray<T>(Enumerable : IEnumerable<T>) : TArray<T>; overload;
      /// <summary> Returns an array that contains all elements from Enumerable. </summary>
      class function ConvertEnumerableToArray<T>(Enumerable : TEnumerable<T>) : TArray<T>; overload;
      /// <summary> Generates an array with Count-times Data in it </summary>
      class function Generate<T>(Count : integer; Data : T) : TArray<T>;
      /// <summary> Iterate over all items and apply callback. </summary>
      class procedure Each<T>(const arr : array of T; Callback : ProcEach<T>);
      /// <summary> Merges A and B with OperatorFunc. Everytime OperatorFunc retuns true for a pair of items, the items
      /// are merged with the newValue. If no there is no matching for a specific itemB it's appended. </summary>
      class function Merge<T>(ArrayA, ArrayB : array of T; OperatorFunc : FuncOperatorFunction<T>) : TArray<T>;
      /// <summary> Returns the maximum value of anArray. Returns Integer.MinValue if array is empty. </summary>
      class function Max(anArray : array of integer) : integer;
      /// <summary> Returns true if any bool is true. </summary>
      class function Any(anArray : array of boolean) : boolean; overload;
      class function Any<T>(anArray : array of T; MapFunction : FuncMapFunction<T, boolean>) : boolean; overload;
      /// <summary> Appends a value to an array. </summary>
      class procedure Push<T>(var arr : TArray<T>; Value : T); overload;
      class procedure Push<T>(var arr : TArray<T>; Values : array of T); overload;
      /// <summary> Prepend a value to an array, equal to Insert at 0. </summary>
      class procedure Prepend<T>(var arr : TArray<T>; Value : T);
      /// <summary> Delete item with given index from array by moving all items after to this position and shorten
      /// the array.</summary>
      class procedure Delete<T>(var arr : TArray<T>; Index : integer);
      class procedure Insert<T>(var arr : TArray<T>; const Value : T; Index : integer);
      class procedure Remove<T>(var arr : TArray<T>; const Value : T);
      /// <summary> Searches for the first occurence of Value in arr. If not found, returns -1. </summary>
      class function IndexOf<T>(arr : TArray<T>; Value : T) : integer; overload;
      class function IndexOf(arr : TArray<string>; Value : string) : integer; overload;
      class function IndexOf(arr : array of string; Value : string) : integer; overload;
      class function Contains(arr : TArray<string>; Value : string) : boolean; overload;
      class function Contains(arr : array of string; Value : string) : boolean; overload;
      class function Contains<T>(arr : TArray<T>; Value : T) : boolean; overload;
      class function Contains<T>(Container : TArray<T>; Elements : TArray<T>) : boolean; overload;
      class function Compare<T>(const Array1, Array2 : TArray<T>) : boolean;
      /// <summary> Interpolates a resulting value from an array of values. It is assumed that the keys are ordered ascending. </summary>
      class function InterpolateLinear<T>(arr : TArray<T>; TargetKey : Single; KeyCallback : FuncMapFunction<T, Single>; LerpCallback : FuncLerpOperator<T>) : T;
      /// <summary> Returns the input array in reversed order.</summary>
      class function Reverse<T>(arr : TArray<T>) : TArray<T>; overload;
      /// <summary> Revers the content of the array. If Count > -1, only elements from 0 .. Count - 1 will reversed.</summary>
      class procedure Reverse<T>(var anArray : TArray<T>; Count : integer); overload;
      /// <summary> Returns the last item of the array, raise exeception if array is empty.</summary>
      class function Last<T>(const arr : TArray<T>) : T;
      /// <summary> Returns True if all elements at same index on both arrays are equal.
      /// Use Generics.Defaults.TComparer<T> to compare two elements.</summary>
      class function equal<T>(const ArrayA, ArrayB : array of T) : boolean;
      class function Sort<T>(const arr : TArray<T>; const SortOperator : TComparison<T>) : TArray<T>;
      /// <summary> Casts all items of the array. </summary>
      class function Cast<T : class; U : class>(const arr : TArray<T>) : TArray<U>;
      class function Create<T>(Items : array of T) : TArray<T>;
  end;

  /// <summary> A wrapper around a variable to have the additional null state. </summary>
  TNullable<T> = class
    public
      Value : T;
      constructor Create(const Value : T);
      /// <summary> NILSAFE | Clones this nullable copying the value. </summary>
      function Clone : TNullable<T>;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}


function SingleToByte(s : Single) : Byte;

implementation

function SingleToByte(s : Single) : Byte;
begin
  Result := Min(255, Max(0, Round(s * 255)));
end;

{ RColor }

class operator RColor.Add(const A, B : RColor) : RColor;
begin
  Result.RGBA := A.RGBA + B.RGBA;
end;

function RColor.AdjustSaturation(s : Single) : RColor;
var
  grey : Single;
begin
  grey := self.Desaturate;
  Result.R := grey + s * (R - grey);
  Result.B := grey + s * (B - grey);
  Result.G := grey + s * (G - grey);
end;

class function RColor.Average(Colors : array of RColor) : RColor;
var
  RGBA : RVector4;
  i : integer;
begin
  if Length(Colors) <= 0 then Exit(RColor.CTRANSPARENTBLACK);
  RGBA := RVector4.ZERO;
  for i := 0 to Length(Colors) - 1 do
      RGBA := RGBA + Colors[i].RGBA;
  Result := RGBA / Length(Colors);
end;

class function RColor.AverageWithAlpha(Colors : array of RColor) : RColor;
var
  RGBA : RVector4;
  weightSum, weight : Single;
  i : integer;
begin
  if Length(Colors) <= 0 then Exit(RColor.CTRANSPARENTBLACK);
  RGBA := RVector4.ZERO;
  weightSum := 0;
  for i := 0 to Length(Colors) - 1 do
  begin
    weight := Colors[i].A;
    RGBA.W := RGBA.W + weight;
    weightSum := weightSum + weight;
    RGBA.X := RGBA.X + Colors[i].R * weight;
    RGBA.Y := RGBA.Y + Colors[i].G * weight;
    RGBA.Z := RGBA.Z + Colors[i].B * weight;
  end;
  Result := RGBA / weightSum;
end;

constructor RColor.Create(Red, Green, Blue, Alpha : Byte);
begin
  self.RedByte := Red;
  self.GreenByte := Green;
  self.BlueByte := Blue;
  self.AlphaByte := Alpha;
end;

constructor RColor.Create(Red, Green, Blue : integer; Alpha : integer = 255);
begin
  self.RedByte := Red;
  self.GreenByte := Green;
  self.BlueByte := Blue;
  self.AlphaByte := Alpha;
end;

constructor RColor.CreateFromHSV(const HueSaturationValue : RVector3);
begin
  self.HSV := HueSaturationValue;
end;

constructor RColor.CreateFromBGRCardinal(Color : Cardinal);
begin
  self.AsBGRCardinal := Color;
end;

constructor RColor.CreateFromCSS(const ColorString : string);
var
  params : TArray<string>;
  R, G, B : integer;
  A : Single;
begin
  params := ColorString.Replace('rgba(', '').Replace(')', '').Replace(' ', '').Split([','], TStringSplitOptions.ExcludeEmpty);
  if Length(params) = 4 then
  begin
    if TryStrToInt(params[0], R) and
      TryStrToInt(params[1], G) and
      TryStrToInt(params[2], B) and
      TryStrToFloat(params[3], A, EngineFloatFormatSettings) then
        Create(R, G, B, SingleToByte(A))
  end
  else self := RColor.CTRANSPARENTBLACK;
end;

constructor RColor.CreateFromHLSL(const ColorString : string);
var
  params : TArray<string>;
begin
  params := ColorString.Replace('float4(', '').Replace('float3(', '').Replace(')', '').Replace(' ', '').Split([','], TStringSplitOptions.ExcludeEmpty);
  if Length(params) = 4 then
  begin
    if TryStrToFloat(params[0], R, EngineFloatFormatSettings) and
      TryStrToFloat(params[1], G, EngineFloatFormatSettings) and
      TryStrToFloat(params[2], B, EngineFloatFormatSettings) and
      TryStrToFloat(params[3], A, EngineFloatFormatSettings) then
        CreateFromSingle(R, G, B, A)
  end
  else if Length(params) = 3 then
  begin
    if TryStrToFloat(params[0], R, EngineFloatFormatSettings) and
      TryStrToFloat(params[1], G, EngineFloatFormatSettings) and
      TryStrToFloat(params[2], B, EngineFloatFormatSettings) then
        CreateFromSingle(R, G, B, 1.0)
  end
  else self := RColor.CTRANSPARENTBLACK;
end;

constructor RColor.CreateFromHSV(Hue, Saturation, Value : Single);
begin
  self.HSV := RVector3.Create(Hue, Saturation, Value);
end;

constructor RColor.CreateFromSingle(Red, Green, Blue, Alpha : Single);
begin
  self.RGBA := RVector4.Create(Red, Green, Blue, Alpha);
end;

constructor RColor.CreateFromString(const ColorString : string);
begin
  try
    if ColorString.StartsWith('$') then Create(ColorString)
    else if ColorString.StartsWith('#') then Create(ColorString.Replace('#', '$'))
    else if ColorString.StartsWith('rgba') then CreateFromCSS(ColorString)
    else if ColorString.StartsWith('float3') or ColorString.StartsWith('float4') then CreateFromHLSL(ColorString)
    else raise ENotImplemented.Create('');
  except
    self := RColor.CTRANSPARENTBLACK;
  end;
end;

constructor RColor.CreateGrey(Color : Byte);
begin
  Create(Color, Color, Color, $FF);
end;

constructor RColor.Create(const HexColorAsString : string);
begin
  self.AsCardinal := StrToInt64Def(HexColorAsString, 0)
end;

constructor RColor.Create(Color : Cardinal);
begin
  self.AsCardinal := Color;
end;

function RColor.Desaturate : Single;
begin
  Result := R * 0.2125 + G * 0.7154 + B * 0.0721;
end;

function RColor.Difference(const Value : RColor) : RColor;
begin
  Result := (self.RGBA - Value.RGBA).Abs;
end;

class operator RColor.Notequal(const A, B : RColor) : boolean;
begin
  Result := A.RGBA <> B.RGBA;
end;

function RColor.PremultiplyAlpha : RColor;
begin
  Result.RGB := self.RGB * self.A;
  Result.A := 0;
end;

function RColor.RGB1 : RColor;
begin
  Result.RGB := RGB;
  Result.A := 1;
end;

class operator RColor.equal(const A, B : RColor) : boolean;
begin
  Result := A.RGBA = B.RGBA;
end;

function RColor.getAlphaByte : Byte;
begin
  Result := SingleToByte(A);
end;

function RColor.getBlueByte : Byte;
begin
  Result := SingleToByte(B);
end;

function RColor.getGreenByte : Byte;
begin
  Result := SingleToByte(G);
end;

function RColor.getRedByte : Byte;
begin
  Result := SingleToByte(R);
end;

function RColor.getCardinal : Cardinal;
type
  KanalArray = array [0 .. 3] of Byte;
begin
  KanalArray(Result)[2] := SingleToByte(R);
  KanalArray(Result)[1] := SingleToByte(G);
  KanalArray(Result)[0] := SingleToByte(B);
  KanalArray(Result)[3] := SingleToByte(A);
end;

function RColor.getBGRCardinal : Cardinal;
type
  KanalArray = array [0 .. 3] of Byte;
begin
  Result := BGRA.AsCardinal;
  KanalArray(Result)[3] := 0;
end;

function RColor.getBGR : RVector3;
begin
  Result := RGB.ZYX;
end;

function RColor.getBGRA : RColor;
begin
  Result.RGBA := RGBA.ZYXW;
end;

function RColor.getHSV : RVector3;
var
  minVal, maxVal, delta : Single;
  RGB : RVector3;
begin
  Result := RVector3.ZERO;
  RGB := self.RGB;
  minVal := self.RGB.MinValue;
  maxVal := self.RGB.MaxValue;
  delta := maxVal - minVal;
  Result.Z := maxVal;
  if (delta <> 0) then // If gray, leave H & S at zero
  begin
    Result.Y := delta / maxVal;
    if ((RGB.X >= RGB.Y) and (RGB.X >= RGB.Z)) then Result.X := 1 / 6 * (0 + (RGB.Y - RGB.Z) / delta)
    else if ((RGB.Y >= RGB.X) and (RGB.Y >= RGB.Z)) then Result.X := 1 / 6 * (2 + (RGB.Z - RGB.X) / delta)
    else if ((RGB.Z >= RGB.X) and (RGB.Z >= RGB.Y)) then Result.X := 1 / 6 * (4 + (RGB.X - RGB.Y) / delta);
    if (Result.X < 0.0) then Result.X := Result.X + 1.0;
    if (Result.X > 1.0) then Result.X := Result.X - 1.0;
  end;
end;

class operator RColor.Implicit(const A : RColor) : string;
begin
  Result := '$' + IntToHex(A.AsCardinal, 8);
end;

function RColor.InvertAlpha : RColor;
begin
  Result.R := R;
  Result.B := B;
  Result.G := G;
  Result.A := 1 - A;
end;

class operator RColor.Implicit(const A : RColor) : RVector4;
begin
  Result := A.RGBA;
end;

class operator RColor.Implicit(const A : RVector4) : RColor;
begin
  Result.RGBA := A;
end;

function RColor.IsFullTransparent : boolean;
begin
  Result := A = 0.0;
end;

function RColor.IsTransparentBlack : boolean;
begin
  Result := RGBA.IsZero;
end;

class operator RColor.Implicit(A : Cardinal) : RColor;
begin
  Result.AsCardinal := A;
end;

function RColor.Lerp(const ZielFarbe : RColor; s : Single) : RColor;
begin
  Result.RGBA := RGBA.Lerp(ZielFarbe.RGBA, s);
end;

class function RColor.LerpArray(Farben : array of Cardinal; s : Single) : RColor;
var
  Index, FarbAnzahl : integer;
  ss : Single;
begin
  FarbAnzahl := Length(Farben);
  if FarbAnzahl <= 0 then raise Exception.Create('RFarbe.LerpArray kann nicht mit einem leeren Array aufgerufen werden.');
  if FarbAnzahl = 1 then
  begin
    Result := Farben[0];
    Exit;
  end;
  s := HMath.clamp(s, 0, 1);
  index := HMath.clamp(trunc((FarbAnzahl - 1) * s), 0, FarbAnzahl - 2);
  ss := frac((FarbAnzahl - 1) * s);
  if (s <> 0) and (ss = 0) then ss := 1;
  Result := RColor(Farben[index]).Lerp(Farben[index + 1], ss);
end;

class function RColor.LerpArray(Farben : array of RColor; s : Single) : RColor;
var
  CardColors : array of Cardinal;
  i : integer;
begin
  Setlength(CardColors, Length(Farben));
  for i := 0 to Length(Farben) - 1 do CardColors[i] := Farben[i].AsCardinal;
  Result := RColor.LerpArray(CardColors, s);
end;

class function RColor.LerpList(Farben : TList<RColor>; s : Single) : RColor;
var
  Index, FarbAnzahl : integer;
  ss : Single;
begin
  FarbAnzahl := Farben.Count;
  if FarbAnzahl <= 0 then raise Exception.Create('RFarbe.LerpListe kann nicht mit einer leeren Liste aufgerufen werden.');
  if FarbAnzahl = 1 then
  begin
    Result := Farben.Items[0];
    Exit;
  end;
  index := HMath.clamp(trunc((FarbAnzahl - 1) * s), 0, FarbAnzahl - 2);
  ss := frac((FarbAnzahl - 1) * s);
  if (s <> 0) and (ss = 0) then ss := 1;
  Result := Farben.Items[index].Lerp(Farben.Items[index + 1], ss);
end;

function RColor.MaxChannel : Single;
begin
  Result := RGBA.MaxValue;
end;

function RColor.Average(const AnotherColor : RColor) : RColor;
begin
  Result.A := AnotherColor.A + A * (1 - AnotherColor.A);
  Result.RGB := (AnotherColor.RGB * AnotherColor.A) + ((RGB * A) * (1 - AnotherColor.A));
  if Result.A > 0 then
      Result.RGB := Result.RGB / Result.A;
end;

class operator RColor.Multiply(A : Single; const B : RColor) : RColor;
begin
  Result.RGBA := A * B.RGBA;
end;

class operator RColor.Multiply(const A, B : RColor) : RColor;
begin
  Result.RGBA := A.RGBA * B.RGBA;
end;

class operator RColor.Notequal(const A : RColor; B : Cardinal) : boolean;
begin
  Result := A.AsCardinal <> B;
end;

class operator RColor.Multiply(const A : RColor; B : Single) : RColor;
begin
  Result.RGBA := B * A.RGBA;
end;

procedure RColor.setAlphaByte(const Value : Byte);
begin
  A := Value / 255;
end;

function RColor.SetAlphaF(Value : Single) : RColor;
begin
  Result := self;
  Result.A := Value;
end;

procedure RColor.setBlueByte(const Value : Byte);
begin
  B := Value / 255;;
end;

procedure RColor.setGreenByte(const Value : Byte);
begin
  G := Value / 255;
end;

procedure RColor.setRedByte(const Value : Byte);
begin
  R := Value / 255;
end;

procedure RColor.setCardinal(const Value : Cardinal);
type
  KanalArray = array [0 .. 3] of Byte;
begin
  R := KanalArray(Value)[2] / 255;
  G := KanalArray(Value)[1] / 255;
  B := KanalArray(Value)[0] / 255;
  A := KanalArray(Value)[3] / 255;
end;

procedure RColor.setBGRCardinal(const Value : Cardinal);
begin
  AsCardinal := Value;
  RGB := RGB.ZYX;
  A := 0;
end;

procedure RColor.setBGR(const Value : RVector3);
begin
  self.RGB := Value.ZYX;
end;

procedure RColor.setBGRA(const Value : RColor);
begin
  RGBA := Value.RGBA.ZYXW;
end;

procedure RColor.setHSV(const HSV : RVector3);
var
  RGB : RVector3;
  var_h, var_i, var_1, var_2, var_3 : Single;
begin
  RGB := HSV.ZZZ;
  if (HSV.Y <> 0) then
  begin
    var_h := HSV.X * 6;
    var_i := floor(var_h);
    var_1 := HSV.Z * (1.0 - HSV.Y);
    var_2 := HSV.Z * (1.0 - HSV.Y * (var_h - var_i));
    var_3 := HSV.Z * (1.0 - HSV.Y * (1 - (var_h - var_i)));
    if (var_i = 0) then RGB := RVector3.Create(HSV.Z, var_3, var_1)
    else if (var_i = 1) then RGB := RVector3.Create(var_2, HSV.Z, var_1)
    else if (var_i = 2) then RGB := RVector3.Create(var_1, HSV.Z, var_3)
    else if (var_i = 3) then RGB := RVector3.Create(var_1, var_2, HSV.Z)
    else if (var_i = 4) then RGB := RVector3.Create(var_3, var_1, HSV.Z)
    else RGB := RVector3.Create(HSV.Z, var_1, var_2)
  end;
  self.RGB := RGB;
end;

procedure RColor.SetGrey(Value : Single);
begin
  R := Value;
  G := Value;
  B := Value;
end;

class operator RColor.Subtract(const A : RColor; B : Byte) : RColor;
begin
  Result.RGBA := A.RGBA - B;
end;

function RColor.ToConstantString : string;
begin
  Result := Format('(R:%.3f; G:%.3f; B:%.3f; A:%.3f)', [R, G, B, A], EngineFloatFormatSettings);
end;

function RColor.ToCSSString : string;
begin
  Result := Format('rgba(%d, %d, %d, %.1f)', [RedByte, GreenByte, BlueByte, A]);
end;

function RColor.ToHexString(Precision : integer; WithDollar : boolean) : string;
begin
  if Precision = 8 then
      Result := IntToHex(AsCardinal, Precision)
  else
      Result := IntToHex(AsCardinal and ((2 shl (Precision * 4 - 1)) - 1), Precision);
  if WithDollar then
      Result := '$' + Result;
end;

function RColor.ToHLSLString : string;
begin
  Result := Format('float4(%.2f, %.2f, %.2f, %.2f)', [R, G, B, A], EngineFloatFormatSettings);
end;

function RColor.ToHLSLStringWithoutAlpha : string;
begin
  Result := Format('float3(%.2f, %.2f, %.2f)', [R, G, B], EngineFloatFormatSettings);
end;

function RColor.ToPhotoshopString : string;
begin
  Result := '#' + Copy(IntToHex(AsCardinal, 8), 3, 6);
end;

class function RColor.TryFromString(const Value : string; out Color : RColor) : boolean;
var
  int : int64;
begin
  Result := TryStrToInt64(Value, int);
  if Result then Color := RColor.Create(int);
end;

class operator RColor.Subtract(const A, B : RColor) : RColor;
begin
  Result.RGBA := A.RGBA - B.RGBA;
end;

class operator RColor.Implicit(const A : RColor) : TValue;
begin
  Result := TValue.From<RColor>(A);
end;

{ HRtti }

class function HRtti.EnumerationToString<T>(AEnumeration : T) : string;
var
  RttiContext : TRttiContext;
  RttiType : TRttiType;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(TypeInfo(T));
  if not Assigned(RttiType) then
      raise EInsufficientRtti.Create('HRtti.EnumerationToString<T>: Doesn''t find rtti for type.');
  assert(RttiType.TypeKind = tkEnumeration);
  Result := TValue.From<T>(AEnumeration).ToString;
  RttiContext.Free;
end;

class function HRtti.EnumerationTypeToStringList<T> : TStrings;
var
  RttiContext : TRttiContext;
  RttiType : TRttiOrdinalType;
  i : integer;
  Value : TValue;
begin
  Result := TStringList.Create;
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(TypeInfo(T)).AsOrdinal;
  if not Assigned(RttiType) then
      raise EInsufficientRtti.Create('HRtti.EnumerationToString<T>: Doesn''t find rtti for type.');
  assert(RttiType.TypeKind = tkEnumeration);
  for i := RttiType.MinValue to RttiType.MaxValue do
  begin
    Value := TValue.FromOrdinal(RttiType.Handle, i);
    Result.Add(Value.ToString);
  end;
end;

class function HRtti.GetAttribute(const Attributes : TArray<TCustomAttribute>; AttributeLookingFor : CAttribute) : TCustomAttribute;
var
  Attribute : TCustomAttribute;
begin
  Result := nil;
  // return the first instance of type AttributeLookingFor if any found
  for Attribute in Attributes do
  begin
    if Attribute.InheritsFrom(AttributeLookingFor) then
    begin
      Result := Attribute;
      Exit;
    end;
  end;
end;

class function HRtti.GetAttribute(Instance : TObject; AttributeLookingFor : CAttribute) : TCustomAttribute;
begin
  Result := GetAttribute(Instance.ClassType, AttributeLookingFor);
end;

class function HRtti.GetAttribute(AClass : TClass; AttributeLookingFor : CAttribute) : TCustomAttribute;
var
  RttiContext : TRttiContext;
  Attributes : TArray<TCustomAttribute>;
begin
  RttiContext := TRttiContext.Create;
  Attributes := RttiContext.GetType(AClass).AsInstance.GetAttributes;
  Result := HRtti.GetAttribute(Attributes, AttributeLookingFor);
  RttiContext.Free;
end;

class function HRtti.GetAttributes(Instance : TObject; AttributeLookingFor : CAttribute) : TArray<TCustomAttribute>;
begin
  Result := GetAttributes(Instance.ClassType, AttributeLookingFor);
end;

class function HRtti.GetAttributes(AClass : TClass; AttributeLookingFor : CAttribute) : TArray<TCustomAttribute>;
var
  RttiContext : TRttiContext;
  Attributes : TArray<TCustomAttribute>;
  RttiType : TRttiType;
  Attribute : TCustomAttribute;
  ArraySize : integer;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AClass);
  Attributes := RttiType.GetAttributes;
  // assume all attributes match AttributeLookingFor
  Setlength(Result, Length(Attributes));
  ArraySize := 0;
  // return the all instances of type AttributeLookingFor if any found
  for Attribute in Attributes do
  begin
    if Attribute.InheritsFrom(AttributeLookingFor) then
    begin
      Result[ArraySize] := Attribute;
      inc(ArraySize);
    end;
  end;
  // result length to real size of found attributes
  Setlength(Result, ArraySize);
  RttiContext.Free;
end;

class function HRtti.GetMethod(const Methods : TArray<TRttiMethod>; const Filter : ProcMethodFilter) : TRttiMethod;
var
  method : TRttiMethod;
begin
  Result := nil;
  for method in Methods do
    if Filter(method) then
        Exit(method);
  if Result = nil then
      raise ENotFoundException.Create('HRtti.GetMethod: No method has passed the filter.');
end;

class function HRtti.GetMethod(const Methods : TArray<TRttiMethod>; const MethodName : string; ParameterCount : integer) : TRttiMethod;
begin
  Result := GetMethod(Methods,
    function(method : TRttiMethod) : boolean
    begin
      Result := (method.ParameterCount = ParameterCount) and (method.Name = MethodName);
    end);
end;

class function HRtti.GetTypeKindOf<T> : TTypeKind;
begin
  Result := PTypeInfo(TypeInfo(T))^.Kind;
end;

class function HRtti.HasAttribute(Instance : TObject; AttributeLookingFor : CAttribute) : boolean;
begin
  Result := HasAttribute(Instance.ClassType, AttributeLookingFor);
end;

class function HRtti.HasAttribute(AClass : TClass; AttributeLookingFor : CAttribute) : boolean;
begin
  Result := GetAttribute(AClass, AttributeLookingFor) <> nil;
end;

class function HRtti.HasAttribute(const Attributes : TArray<TCustomAttribute>; AttributeLookingFor : CAttribute) : boolean;
begin
  Result := SearchForAttribute(AttributeLookingFor, Attributes) <> nil;
end;

class function HRtti.HasAttributeType(AType : TRttiObject; AttributeLookingFor : CAttribute) : boolean;
begin
  Result := HasAttribute(AType.GetAttributes, AttributeLookingFor);
end;

class function HRtti.HelperSetToString(Info : PTypeInfo; const Value; const Separator, Prefix, Suffix : string) : string;
  function OrdToString(Info : PTypeInfo; Value : integer) : string;
  resourcestring
    sCvtError = 'OrdToString: type kind must be ordinal, not %s';
  const
    AsciiChars = [32 .. 127]; // Printable ASCII characters.
  begin
    case Info.Kind of
      tkInteger :
        Result := IntToStr(Value);
      tkChar, tkWChar :
        if Value in AsciiChars then
            Result := '''' + chr(Value) + ''''
        else
            Result := Format('#%d', [Value]);
      tkEnumeration :
        Result := GetEnumName(Info, Value);
    else
      raise EConvertError.CreateFmt(sCvtError,
        [GetEnumName(TypeInfo(TTypeKind), Ord(Info.Kind))]);
    end;
  end;

resourcestring
  sNotASet = 'SetToString: argument must be a ' +
    'set type; %s not allowed';
const
  MaxSet      = 255; // Largest ordinal value in a Delphi set.
  BitsPerByte = 8;
  // Mask to force the minimum set value to be
  // a set element on a byte boundary.
  ByteBoundaryMask = not(BitsPerByte - 1);

type
  TSet = set of 0 .. MaxSet;

var
  CompInfo : PTypeInfo;
  CompData : PTypeData;
  SetValue : TSet absolute Value;
  Element : 0 .. MaxSet;
  MinElement : 0 .. MaxSet;
begin
  if Info.Kind <> tkSet then
      raise EConvertError.CreateFmt(sNotASet, [GetEnumName(TypeInfo(TTypeKind), Ord(Info.Kind))]);
  CompInfo := GetTypeData(Info)^.CompType^;
  CompData := GetTypeData(CompInfo);
  Result := '';
  MinElement := CompData.MinValue and ByteBoundaryMask;
  for Element := CompData.MinValue to CompData.MaxValue do
  begin
    if (Element - MinElement) in SetValue then
      if Result = '' then
          Result := Prefix + OrdToString(CompInfo, Element)
      else
          Result := Result + Separator +
          OrdToString(CompInfo, Element);
  end;
  if Result = '' then
      Result := Prefix + Suffix
  else
      Result := Result + Suffix;
end;

class function HRtti.IntegerToEnumeration<T>(EnumerationOrd : integer) : T;
begin
  if not TryIntegerToEnumeration<T>(EnumerationOrd, Result) then raise
      EInvalidCast.CreateRes(@SInvalidCast);
end;

class function HRtti.EnumerationToInteger<T>(ANEnumeration : T) : integer;
var
  typeInf : PTypeInfo;
begin
  typeInf := PTypeInfo(TypeInfo(T));
  if typeInf^.Kind <> tkEnumeration then
      raise EInvalidCast.CreateRes(@SInvalidCast);

  case GetTypeData(typeInf)^.OrdType of
    otUByte, otSByte :
      Result := PByte(@ANEnumeration)^;
    otUWord, otSWord :
      Result := PWord(@ANEnumeration)^;
    otULong, otSLong :
      Result := PInteger(@ANEnumeration)^;
  else
    raise EInvalidCast.CreateRes(@SInvalidCast);
  end;
end;

class function HRtti.SearchForAttribute(AttributeLookingFor : TClass; Attributes : TArray<TCustomAttribute>) : TCustomAttribute;
var
  Attribute : TCustomAttribute;
begin
  Result := nil;
  for Attribute in Attributes do
  begin
    if Attribute is AttributeLookingFor then Exit(Attribute);
  end;
end;

class function HRtti.SearchForAttributes(AttributeLookingFor : TClass; Attributes : TArray<TCustomAttribute>) : TArray<TCustomAttribute>;
var
  Attribute : TCustomAttribute;
begin
  Result := nil;
  for Attribute in Attributes do
  begin
    if Attribute is AttributeLookingFor then
    begin
      Setlength(Result, Length(Result) + 1);
      Result[high(Result)] := Attribute;
    end;
  end;
end;

class function HRtti.SetToString(const aSet : TSysCharSet; StartDelimiter, EndDelimiter, Seperator : string) : string;
var
  chars : TList<string>;
  AChar : Char;
begin
  chars := TList<string>.Create;
  for AChar in aSet do
      chars.Add(AChar);
  Result := StartDelimiter + string.Join(Seperator, chars.ToArray) + EndDelimiter;
  chars.Free;
end;

class function HRtti.SetToString<T>(aSet : T) : string;
// var
// RttiContext : TRttiContext;
// RttiType : TRttiType;
begin
  Result := HelperSetToString(TypeInfo(T), aSet, ',', '[', ']');
  // RttiContext := TRttiContext.Create;
  // RttiType := RttiContext.GetType(TypeInfo(T));
  // if not Assigned(RttiType) then
  // raise EInsufficientRtti.Create('HRtti.SetToString<T>: Doesn''t find rtti for type.');
  // assert(RttiType.TypeKind = tkSet);
  // Result := TValue.From<T>(aSet).ToString;
  // RttiContext.Free;
end;

class function HRtti.TryIntegerToEnumeration<T>(EnumerationOrd : integer; out Value : T) : boolean;
var
  typeInf : PTypeInfo;
begin
  Result := False;
  typeInf := PTypeInfo(TypeInfo(T));
  assert(Assigned(typeInf), 'HRtti.TryIntegerToEnumeration<T>: No typeinfo for enumeration!');
  if typeInf^.Kind <> tkEnumeration then
      Exit;

  case GetTypeData(typeInf)^.OrdType of
    otUByte, otSByte :
      PByte(@Value)^ := EnumerationOrd;
    otUWord, otSWord :
      PWord(@Value)^ := EnumerationOrd;
    otULong, otSLong :
      PInteger(@Value)^ := EnumerationOrd;
  else
    Exit;
  end;
  Result := True;
end;

class function HRtti.TryStringToEnumeration<T>(EnumerationAsString : string; out Value : T) : boolean;
var
  RttiContext : TRttiContext;
  RttiType : TRttiType;
  res : integer;
begin
  Result := True;
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(TypeInfo(T));
  if not Assigned(RttiType) then
      raise EInsufficientRtti.Create('HRtti.StringToEnumeration<T>: Doesn''t find rtti for type.');
  assert(RttiType.TypeKind = tkEnumeration);
  res := GetEnumValue(RttiType.Handle, EnumerationAsString);
  if res = -1 then Exit(False);
  Value := (TValue.FromOrdinal(RttiType.Handle, res)).AsType<T>;
  RttiContext.Free;
end;

class function HRtti.StringToEnumeration<T>(EnumerationAsString : string; FailSilently : boolean) : T;
var
  RttiContext : TRttiContext;
  RttiType : TRttiType;
  res : integer;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(TypeInfo(T));
  if not Assigned(RttiType) then
      raise EInsufficientRtti.Create('HRtti.StringToEnumeration<T>: Doesn''t find rtti for type.');
  assert(RttiType.TypeKind = tkEnumeration);
  res := GetEnumValue(RttiType.Handle, EnumerationAsString);
  if (res = -1) and not FailSilently then raise EConvertError.Create('HRtti.StringToEnumeration<T>: Invalid string!');
  Result := (TValue.FromOrdinal(RttiType.Handle, res)).AsType<T>;
  RttiContext.Free;
end;

class function HRtti.StringToSet<T>(SetAsString : string; FailSilently : boolean) : T;
begin
  if not TryStringToSet<T>(SetAsString, Result) then
  begin
    if not FailSilently then raise EConvertError.Create('HRtti.StringToSet<T>: Invalid string!');
    Result := default (T);
  end;
end;

class function HRtti.TryStringToSet<T>(SetAsString : string; out aSet : T) : boolean;
var
  RttiContext : TRttiContext;
  RttiType : TRttiType;
  Value : integer;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(TypeInfo(T));
  if not Assigned(RttiType) then
      raise EInsufficientRtti.Create('HRtti.StringToSet<T>: Doesn''t find rtti for type.');
  assert(RttiType.TypeKind = tkSet);
  try
    aSet := default (T);
    Value := System.TypInfo.StringToSet(RttiType.Handle, SetAsString);
    Move(Value, aSet, Min(SizeOf(integer), SizeOf(T)));
    Result := True;
  except
    RttiContext.Free;
    Exit(False);
  end;
  RttiContext.Free;
end;

{ TRttiMethodHelper }

function TRttiMethodHelper.IsAbstract : boolean;
begin
  Result := (PVmtMethodExEntry(self.Handle).Flags and (1 shl 7)) <> 0;
end;

function TRttiMethodHelper.ParameterCount : integer;
var
  parameter : TArray<TRttiParameter>;
begin
  parameter := self.GetParameters;
  Result := Length(parameter);
  parameter := nil;
end;

{ HGeneric }

class function HGeneric.SucheItemInArray<T>(Item : T; ZuDurchsuchenderArray : array of T) : boolean;
var
  i : integer;
  Comparer : IEqualityComparer<T>;
begin
  Result := False;
  // Vergleicher raussuchen
  Comparer := TEqualityComparer<T>.Default;
  // und Array nach Item durchsuchen, ist der Wert gefunden worden, gebe True zurück
  for i := 0 to Length(ZuDurchsuchenderArray) - 1 do
    if Comparer.Equals(ZuDurchsuchenderArray[i], Item) then Exit(True);
end;

class procedure HGeneric.ArrayAppend<T>(var arr : TArray<T>; Item : T);
begin
  Setlength(arr, Length(arr) + 1);
  arr[high(arr)] := Item;
end;

class function HGeneric.ConvertGenericToVariant<T>(Value : T) : Variant;
var
  val : TValue;
  bRes : boolean;
begin
  val := TValue.From<T>(Value);
  case val.Kind of
    tkInteger : Result := val.AsInteger;
    tkInt64 : Result := val.AsInt64;
    tkEnumeration :
      begin
        if val.TryAsType<boolean>(bRes) then
            Result := bRes
        else
            Result := val.AsOrdinal;
      end;
    tkFloat : Result := val.AsExtended;
    tkString, tkChar, tkWChar, tkLString, tkWString, tkUString :
      Result := val.AsString;
    tkVariant : Result := val.AsVariant
  else
    begin
      raise Exception.Create('Unsupported type');
    end;
  end;
end;

class function HGeneric.ConvertVariantToGeneric<T>(Vari : Variant) : T;
begin
  Result := TValue.FromVariant(Vari).AsType<T>;
end;

class function HGeneric.EnumerationArrayToEnumeration<TEnum, V>(inArray : array of V) : TArray<TPair<TEnum, V>>;
var
  typeInf : PTypeInfo;
  typeData : PTypeData;
  iterValue : integer;
begin
  typeInf := PTypeInfo(TypeInfo(TEnum));
  if typeInf^.Kind <> tkEnumeration then raise EInvalidCast.CreateRes(@SInvalidCast);
  typeData := GetTypeData(typeInf);
  Setlength(Result, typeData.MaxValue);
  for iterValue := typeData.MinValue to typeData.MaxValue do
  begin
    // GetEnumValue()
    // result[iterValue].Key :=
    Result[iterValue].Value := inArray[iterValue];
  end;
end;

class function HGeneric.RandomEnum<TEnum> : TEnum;
type
  PEnum = ^TEnum;
var
  typeInf : PTypeInfo;
  typeData : PTypeData;
  enumvalue : Byte;
begin
  typeInf := PTypeInfo(TypeInfo(TEnum));
  if typeInf^.Kind <> tkEnumeration then
      raise EInvalidCast.CreateRes(@SInvalidCast);
  typeData := GetTypeData(typeInf);
  enumvalue := typeData.MinValue + Random(typeData.MaxValue - typeData.MinValue + 1);
  Result := PEnum(@enumvalue)^;
end;

class function HGeneric.SucheItemInArray<T>(Item : T; ZuDurchsuchenderArray : array of T; out ItemIndex : integer) : boolean;
var
  i : integer;
  Comparer : IEqualityComparer<T>;
begin
  Result := False;
  ItemIndex := -1;
  // Vergleicher raussuchen
  Comparer := TEqualityComparer<T>.Default;
  // und Array nach Item durchsuchen, ist der Wert gefunden worden, gebe True und ItemIndex zurück
  for i := 0 to Length(ZuDurchsuchenderArray) - 1 do
    if Comparer.Equals(ZuDurchsuchenderArray[i], Item) then
    begin
      ItemIndex := i;
      Result := True;
      Exit;
    end;
end;

class procedure HGeneric.Swap<T>(var A, B : T);
var
  tSwap : T;
begin
  tSwap := A;
  A := B;
  B := tSwap;
end;

class function HGeneric.TertOp<T>(Bedingung : boolean; WennWahr,
  WennFalsch : T) : T;
begin
  if Bedingung then Result := WennWahr
  else Result := WennFalsch;
end;

{ HArray }

class function HArray.Any(anArray : array of boolean) : boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to Length(anArray) - 1 do
    if anArray[i] then Exit(True);
end;

class function HArray.Any<T>(anArray : array of T; MapFunction : FuncMapFunction<T, boolean>) : boolean;
begin
  Result := HArray.Any(HArray.Map<T, boolean>(anArray, MapFunction));
end;

class function HArray.ArrayToString<T>(Data : TArray<T>; StartTag : string; EndTag : string; Delimiter : string) : string;
var
  i : integer;
  Value : TValue;
begin
  // begin array
  Result := StartTag;
  for i := 0 to Length(Data) - 1 do
  begin
    // use TValue to convert any to string
    Value := TValue.From<T>(Data[i]);
    Result := Result + Value.ToString;
    // only add delimiter if any item will follow
    if i < (Length(Data) - 1) then
        Result := Result + Delimiter;
  end;
  // end array
  Result := Result + EndTag;
end;

class procedure HArray.FreeAllObjects<T>(var Data : TArray<T>; FreeArray : boolean);
var
  Item : T;
begin
  for Item in Data do
  begin
    Item.Free;
  end;
  if FreeArray then
      Data := nil;
end;

class function HArray.SearchClassInArray<T>(ClassToSearch : TClass; ArrayToScan : TArray<T>; FoundAttribute : Pointer) : boolean;
type
  PT = ^T;
var
  Obj : T;
begin
  Result := False;
  for Obj in ArrayToScan do
  begin
    if Obj is ClassToSearch then
    begin
      if FoundAttribute <> nil then PT(FoundAttribute)^ := Obj;
      Exit(True);
    end;
  end;
end;

class function HArray.SearchClassInArray<T>(ClassesToSearch : TArray<TClass>; ArrayToScan : TArray<T>; FoundAttribute : Pointer) : boolean;
var
  LookFor : TClass;
begin
  Result := False;
  for LookFor in ClassesToSearch do
  begin
    if SearchClassInArray<T>(LookFor, ArrayToScan, FoundAttribute) then
        Exit(True);
  end;
end;

class function HArray.Sort<T>(const arr : TArray<T>; const SortOperator : TComparison<T>) : TArray<T>;
var
  list : TList<T>;
begin
  list := TList<T>.Create(TComparer<T>.Construct(
    function(const Left, Right : T) : integer
    begin
      Result := SortOperator(Left, Right);
    end));
  list.AddRange(arr);
  list.Sort;
  Result := list.ToArray;
  list.Free;
end;

class function HArray.Contains(arr : TArray<string>; Value : string) : boolean;
begin
  Result := HArray.IndexOf(arr, Value) >= 0;
end;

class function HArray.Cast<T, U>(const arr : TArray<T>) : TArray<U>;
var
  i : integer;
begin
  Setlength(Result, Length(arr));
  for i := 0 to Length(arr) - 1 do
      Result[i] := U(Pointer(arr[i]));
end;

class function HArray.Compare<T>(const Array1, Array2 : TArray<T>) : boolean;
begin
  Result := (Length(Array1) = Length(Array2)) and
    contains<T>(Array1, Array2) and
    contains<T>(Array2, Array1);
end;

class function HArray.Contains(arr : array of string; Value : string) : boolean;
begin
  Result := HArray.IndexOf(arr, Value) >= 0;
end;

class function HArray.Contains<T>(Container, Elements : TArray<T>) : boolean;
var
  i : integer;
begin
  Result := True;
  for i := 0 to Length(Elements) - 1 do
      Result := Result and HArray.Contains<T>(Container, Elements[i]);
end;

class function HArray.Contains<T>(arr : TArray<T>; Value : T) : boolean;
begin
  Result := HArray.IndexOf<T>(arr, Value) >= 0;
end;

class function HArray.ConvertDynamicToTArray<T>(Data : array of T) : TArray<T>;
var
  i : integer;
begin
  Setlength(Result, Length(Data));
  for i := 0 to Length(Data) - 1 do
      Result[i] := Data[i];
end;

class function HArray.ConvertEnumerableToArray<T>(Enumerable : TEnumerable<T>) : TArray<T>;
var
  buf : TList<T>;
  X : T;
begin
  buf := TList<T>.Create;
  try
    for X in Enumerable do
        buf.Add(X);
    Result := buf.ToArray; // relies on TList<T>.ToArray override
  finally
    buf.Free;
  end;
end;

class function HArray.Create<T>(Items : array of T) : TArray<T>;
begin
  Result := HArray.ConvertDynamicToTArray<T>(Items);
end;

class function HArray.ConvertEnumerableToArray<T>(Enumerable : IEnumerable<T>) : TArray<T>;
var
  buf : TList<T>;
  X : T;
begin
  buf := TList<T>.Create;
  try
    for X in Enumerable do
        buf.Add(X);
    Result := buf.ToArray; // relies on TList<T>.ToArray override
  finally
    buf.Free;
  end;
end;

class procedure HArray.Delete<T>(var arr : TArray<T>; Index : integer);
var
  i : integer;
begin
  if Length(arr) <= 0 then Exit;
  for i := 0 to Length(arr) - 2 do
    if i >= index then arr[i] := arr[i + 1];
  Setlength(arr, Length(arr) - 1);
end;

class procedure HArray.Each<T>(const arr : array of T; Callback : ProcEach<T>);
var
  i : integer;
begin
  for i := 0 to Length(arr) - 1 do
      Callback(arr[i]);
end;

class function HArray.equal<T>(const ArrayA, ArrayB : array of T) : boolean;
var
  Comparer : IComparer<T>;
  i : integer;
begin
  // fast exit if length differ
  if Length(ArrayA) <> Length(ArrayB) then
      Result := False
  else
  begin
    Result := True;
    Comparer := TComparer<T>.Default;
    for i := 0 to Length(ArrayA) - 1 do
      if Comparer.Compare(ArrayA[i], ArrayB[i]) <> 0 then
          Exit(False);
  end;
end;

class procedure HArray.FreeAllObjects<T>(Data : TArray<T>);
begin
  HArray.FreeAllObjects<T>(Data, False);
end;

class function HArray.Filter<T>(anArray : array of T; func : FuncFilterFunction<T>) : TArray<T>;
var
  i, Count : integer;
begin
  Count := 0;
  Setlength(Result, Length(anArray));
  for i := 0 to Length(anArray) - 1 do
    if func(anArray[i]) then
    begin
      Result[Count] := anArray[i];
      inc(Count);
    end;
  Setlength(Result, Count);
end;

class procedure HArray.FreeAllObjects<T>(Data : array of T);
var
  i : integer;
begin
  for i := 0 to Length(Data) - 1 do
      Data[i].Free;
end;

class procedure HArray.FreeAndNilAllObjects<T>(var Data : array of T);
var
  i : integer;
begin
  for i := 0 to Length(Data) - 1 do
  begin
    Data[i].Free;
    Data[i] := nil;
  end;
end;

class function HArray.Generate<T>(Count : integer; Data : T) : TArray<T>;
var
  i : integer;
begin
  if Count <= 0 then Exit(nil);
  Setlength(Result, Count);
  for i := 0 to Count - 1 do Result[i] := Data;
end;

class function HArray.IndexOf(arr : TArray<string>; Value : string) : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to Length(arr) - 1 do
    if arr[i] = Value then Exit(i);
end;

class function HArray.IndexOf(arr : array of string; Value : string) : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to Length(arr) - 1 do
    if arr[i] = Value then Exit(i);
end;

class function HArray.IndexOf<T>(arr : TArray<T>; Value : T) : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to Length(arr) - 1 do
    if CompareMem(@arr[i], @Value, SizeOf(T)) then Exit(i);
end;

class procedure HArray.Insert<T>(var arr : TArray<T>; const Value : T; Index : integer);
var
  i : integer;
begin
  Setlength(arr, Length(arr) + 1);
  for i := Length(arr) - 1 downto 1 do
  begin
    if i <= index then
    begin
      arr[i] := Value;
      break;
    end;
    arr[i] := arr[i - 1];
  end;
  if index <= 0 then arr[0] := Value;
end;

class function HArray.InterpolateLinear<T>(arr : TArray<T>; TargetKey : Single; KeyCallback : FuncMapFunction<T, Single>;
LerpCallback : FuncLerpOperator<T>) : T;
var
  prev, current : T;
  prevKey, currentKey : Single;
  i : integer;
begin
  Result := default (T);
  if Length(arr) <= 0 then Exit;
  if Length(arr) = 1 then Exit(arr[0]);
  prev := arr[0];

  // if TargetKey is before all other keys take first
  if (KeyCallback(prev) > TargetKey) then
  begin
    Result := prev;
    Exit;
  end;

  for i := 1 to Length(arr) - 1 do
  begin
    current := arr[i];
    prevKey := KeyCallback(prev);
    currentKey := KeyCallback(current);

    if (prevKey <= TargetKey) and (currentKey > TargetKey) then
    begin
      // found frame, now lerp
      Result := LerpCallback(prev, current, (TargetKey - prevKey) / (currentKey - prevKey));
      Exit;
    end;
    prev := current;
  end;

  // if no frame fits, the targetkey must beyond the timeline, so take the last
  Result := current;
end;

class function HArray.Last<T>(const arr : TArray<T>) : T;
begin
  if Length(arr) > 0 then
  begin
    Result := arr[Length(arr) - 1];
  end
  else raise EOutOfBoundException.Create('HArray.Last<T>: Array is empty.');
end;

class function HArray.Map<T, U>(anArray : array of T; func : FuncMapFunction<T, U>) : TArray<U>;
var
  i : integer;
begin
  Setlength(Result, Length(anArray));
  for i := 0 to Length(anArray) - 1 do Result[i] := func(anArray[i]);
end;

class function HArray.MapFiltered<T, U>(anArray : array of T; func : FuncFilteredMapFunction<T, U>) : TArray<U>;
var
  i, Count : integer;
  Item : U;
begin
  Count := 0;
  Setlength(Result, Length(anArray));
  for i := 0 to Length(anArray) - 1 do
    if func(anArray[i], Item) then
    begin
      Result[Count] := Item;
      inc(Count);
    end;
  Setlength(Result, Count);
end;

class function HArray.Max(anArray : array of integer) : integer;
var
  i : integer;
begin
  Result := integer.MinValue;
  for i := 0 to Length(anArray) - 1 do
      Result := System.Math.Max(anArray[i], Result);
end;

class function HArray.Merge<T>(ArrayA, ArrayB : array of T; OperatorFunc : FuncOperatorFunction<T>) : TArray<T>;
var
  i, j : integer;
  merged : boolean;
  newVal : T;
begin
  Result := HArray.ConvertDynamicToTArray<T>(ArrayA);
  for i := 0 to Length(ArrayB) - 1 do
  begin
    merged := False;
    for j := 0 to Length(Result) - 1 do
      if OperatorFunc(Result[j], ArrayB[i], newVal) then
      begin
        merged := True;
        Result[j] := newVal;
        break;
      end;
    if not merged then
    begin
      Setlength(Result, Length(Result) + 1);
      Result[high(Result)] := ArrayB[i];
    end;
  end;
end;

class procedure HArray.Prepend<T>(var arr : TArray<T>; Value : T);
var
  i : integer;
begin
  Setlength(arr, Length(arr) + 1);
  for i := Length(arr) - 1 downto 1 do
      arr[i] := arr[i - 1];
  arr[0] := Value;
end;

class procedure HArray.Push<T>(var arr : TArray<T>; Values : array of T);
var
  i, offset : integer;
begin
  offset := Length(arr);
  Setlength(arr, Length(arr) + Length(Values));
  for i := 0 to Length(Values) - 1 do
      arr[i + offset] := Values[i];
end;

class procedure HArray.Push<T>(var arr : TArray<T>; Value : T);
begin
  Setlength(arr, Length(arr) + 1);
  arr[high(arr)] := Value;
end;

class procedure HArray.Remove<T>(var arr : TArray<T>; const Value : T);
var
  i : integer;
  deleted : boolean;
begin
  deleted := False;
  for i := 0 to Length(arr) - 1 do
  begin
    if CompareMem(@arr[i], @Value, SizeOf(T)) then deleted := True;
    if deleted and (i + 1 < Length(arr)) then arr[i] := arr[i + 1];
  end;
  if deleted then Setlength(arr, Length(arr) - 1);
end;

class function HArray.RemoveDuplicates<T>(Data : TArray<T>) : TArray<T>;
var
  dict : TDictionary<T, boolean>;
  Item : T;
begin
  dict := TDictionary<T, boolean>.Create();
  for Item in Data do
  begin
    // avoid duplicates
    if not dict.ContainsKey(Item) then
        dict.Add(Item, True);
  end;
  Result := dict.Keys.ToArray;
  dict.Free;
end;

class procedure HArray.Reverse<T>(var anArray : TArray<T>; Count : integer);
var
  i : integer;
  ReverseLength : integer;
  Temp : T;
begin
  if Count <= -1 then
      ReverseLength := Count
  else
      ReverseLength := Length(anArray);

  for i := 0 to (ReverseLength - 1) div 2 do
  begin
    Temp := anArray[i];
    anArray[i] := anArray[(ReverseLength - 1) - i];
    anArray[(ReverseLength - 1) - i] := Temp;
  end;
end;

class function HArray.Reverse<T>(arr : TArray<T>) : TArray<T>;
var
  i : integer;
begin
  Setlength(Result, Length(arr));
  for i := 0 to Length(arr) - 1 do
      Result[i] := arr[(Length(arr) - 1) - i];
end;

{ TRttiTypeHelper }

function TRttiTypeHelper.GetParameterlessConstructor(const ConstructorName : string = '') : TRttiMethod;
var
  i : TRttiMethod;
begin
  for i in GetMethods do
  begin
    Result := i;
    if Result.IsConstructor and (ConstructorName.IsEmpty or SameText(Result.Name, ConstructorName)) and
      (Result.ParameterCount = 0) then
      // exit complete method if parameterless constructor found,
      // result will contain this constructor already
        Exit;
  end;
  // reaching this code means, that no constructor was found
  Result := nil;
end;

function TRttiTypeHelper.HasField(const AName : string) : boolean;
begin
  Result := Assigned(GetField(AName));
end;

function TRttiTypeHelper.HasMethod(const AName : string) : boolean;
begin
  Result := Assigned(GetMethod(AName));
end;

function TRttiTypeHelper.HasProperty(const AName : string) : boolean;
begin
  Result := Assigned(GetProperty(AName));
end;

function TRttiTypeHelper.TryGetField(const AName : string; out AField : TRttiField) : boolean;
begin
  AField := GetField(AName);
  Result := Assigned(AField);
end;

function TRttiTypeHelper.TryGetMember(const AName : string; out AMember : TRttiMember) : boolean;
var
  AField : TRttiField;
  AProperty : TRttiProperty;
  AMethod : TRttiMethod;
begin
  if TryGetField(AName, AField) then
  begin
    Result := True;
    AMember := AField;
  end
  else if TryGetProperty(AName, AProperty) then
  begin
    Result := True;
    AMember := AProperty;
  end
  else if TryGetMethod(AName, AMethod) then
  begin
    Result := True;
    AMember := AMethod;
  end
  else
  begin
    Result := False;
    AMember := nil;
  end
end;

function TRttiTypeHelper.TryGetMethod(const AName : string; out AMethod : TRttiMethod) : boolean;
begin
  AMethod := GetMethod(AName);
  Result := Assigned(AMethod);
end;

function TRttiTypeHelper.TryGetProperty(const AName : string; out AProperty : TRttiProperty) : boolean;
begin
  AProperty := GetProperty(AName);
  Result := Assigned(AProperty);
end;

{ TRttiPropertyHelper }

function TRttiPropertyHelper.UsingSetterMethod : boolean;
var
  LPropInfo : PPropInfo;
begin
  Result := False;
  if (self.IsWritable) and (self.ClassNameIs('TRttiInstancePropertyEx')) then
  begin
    // get the PPropInfo pointer
    LPropInfo := TRttiInstanceProperty(self).PropInfo;
    if (LPropInfo <> nil) and (LPropInfo.SetProc <> nil) and not IsField(LPropInfo.SetProc) then
        Result := True;
  end;
end;

function TRttiPropertyHelper.IsField(P : Pointer) : boolean;
begin
  Result := (IntPtr(P) and PROPSLOT_MASK) = PROPSLOT_FIELD;
end;

function TRttiPropertyHelper.GetCodePointer(AClass : TClass; P : Pointer) : Pointer;
begin
  if (IntPtr(P) and PROPSLOT_MASK) = PROPSLOT_VIRTUAL then // Virtual Method
      Result := PPointer(NativeUInt(AClass) + (UIntPtr(P) and $FFFF))^
  else // Static method
      Result := P;
end;

function TRttiPropertyHelper.TryGetGetterMethod(out GetterMethod : TRttiMethod) : boolean;
var
  LPropInfo : PPropInfo;
  LMethod : TRttiMethod;
  LCodeAddress : Pointer;
begin
  Result := False;
  if (self.IsReadable) and (self.ClassNameIs('TRttiInstancePropertyEx')) then
  begin
    // get the PPropInfo pointer
    LPropInfo := TRttiInstanceProperty(self).PropInfo;
    if (LPropInfo <> nil) and (LPropInfo.GetProc <> nil) and not IsField(LPropInfo.GetProc) then
    begin
      Result := True;
      // get the real address of the method
      LCodeAddress := GetCodePointer(Parent.AsInstance.MetaclassType, LPropInfo^.GetProc);
      // iterate over the methods of the instance
      for LMethod in Parent.GetMethods do
      begin
        // compare the address of the currrent method against the address of the getter
        if LMethod.CodeAddress = LCodeAddress then
        begin
          GetterMethod := LMethod;
          Exit;
        end;
      end;
    end;
  end;
end;

function TRttiPropertyHelper.TryGetSetterMethod(out SetterMethod : TRttiMethod) : boolean;
var
  LPropInfo : PPropInfo;
  LMethod : TRttiMethod;
  LCodeAddress : Pointer;
begin
  Result := False;
  SetterMethod := nil;
  if (self.IsWritable) and (self.ClassNameIs('TRttiInstancePropertyEx')) then
  begin
    // get the PPropInfo pointer
    LPropInfo := TRttiInstanceProperty(self).PropInfo;
    if (LPropInfo <> nil) and (LPropInfo.SetProc <> nil) and not IsField(LPropInfo.SetProc) then
    begin
      Result := True;
      // get the real address of the method
      LCodeAddress := GetCodePointer(Parent.AsInstance.MetaclassType, LPropInfo^.SetProc);
      // iterate over the methods
      for LMethod in Parent.GetMethods do
      begin
        // compare the address of the currrent method against the address of the setter
        if LMethod.CodeAddress = LCodeAddress then
        begin
          SetterMethod := LMethod;
          Exit;
        end;
      end;
    end;
  end;
end;

{ TSharedData<T> }

function TSharedData<T>.GetData : T;
begin
  Result := FData;
end;

function TSharedData<T>.SetData(const Value : T) : T;
begin
  FData := Value;
end;

{ HConvert }

class function HConvert.FloatToStr(const Value : Single) : string;
begin
  Result := FloatToStrF(Value, ffGeneral, 4, 4, EngineFloatFormatSettings);
end;

class function HConvert.ExtractIntegerFromNativeUInt(const Value : NativeUInt) : integer;
begin
  Result := Value;
end;

class function HConvert.ExtractSingleFromNativeUInt(const Value : NativeUInt) : Single;
begin
  Result := PSingle(@Value)^;
end;

class function HConvert.PackIntegerToNativeUInt(const Value : integer) : NativeUInt;
begin
  Result := Value;
end;

class function HConvert.PackSingleToNativeUInt(const Value : Single) : NativeUInt;
begin
  Result := 0;
  PSingle(@Result)^ := Value;
end;

{ AStringHelper }

function AStringHelper.Count : integer;
begin
  Result := Length(self);
end;

procedure AStringHelper.Each(const Callback : ProcString);
var
  i : integer;
begin
  for i := 0 to Length(self) - 1 do
      Callback(self[i]);
end;

{ TNullable<T> }

function TNullable<T>.Clone : TNullable<T>;
begin
  if self = nil then
      Result := nil
  else
      Result := TNullable<T>.Create(self.Value);
end;

constructor TNullable<T>.Create(const Value : T);
begin
  self.Value := Value;
end;

{ HDate }

class function HDate.CurrentDay : integer;
var
  CurrentDate : TDateTime;
begin
  CurrentDate := Now;
  Result := DayOf(CurrentDate);
end;

class function HDate.CurrentMonth : integer;
var
  CurrentDate : TDateTime;
begin
  CurrentDate := Now;
  Result := MonthOf(CurrentDate);
end;

class function HDate.CurrentYear : integer;
var
  CurrentDate : TDateTime;
begin
  CurrentDate := Now;
  Result := YearOf(CurrentDate);
end;

initialization

FormatSettings.DecimalSeparator := '.';

finalization

end.
