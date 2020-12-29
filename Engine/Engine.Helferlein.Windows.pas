unit Engine.Helferlein.Windows;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Forms,
  Contnrs,
  Vcl.Controls,
  Classes,
  IniFiles,
  Math,
  Variants,
  Engine.Log,
  Vcl.FileCtrl,
  ZLib,
  IdHashMessageDigest,
  idHash,
  idGlobal,

  Types,
  Winapi.mmSystem,
  Engine.Math,
  StrUtils,
  Winapi.ShellAPI,
  System.RTTI,
  System.TypInfo,
  Winapi.Commctrl,
  Winapi.ShlObj,
  Vcl.Graphics,
  SysConst,
  uTPLb_CryptographicLibrary,
  uTPLb_Hash,
  uTPLb_StreamUtils,
  uTPLb_Constants,
  uTPLb_Signatory,
  uTPLb_Asymetric,
  uTPLb_Codec,
  IdHTTP,
  IdURI,
  IdComponent,
  System.SyncObjs,
  SysUtils,
  System.IOUtils,
  Engine.Serializer.Types,
  Engine.Helferlein,
  Engine.Helferlein.Threads,
  System.DateUtils,
  RegularExpressions,
  Engine.DataQuery,
  System.Hash,
  System.Character,
  Generics.collections,
  Generics.Defaults;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  EHRttiError = class(Exception);

  AString = TArray<string>;
  AWord = array of Word;
  ALongWord = array of LongWord;
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  SetByte = set of Byte;
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  ProcOfObject = procedure of object;
  ProcCallback = reference to procedure;

  ClassOfCustomAttribute = class of TCustomAttribute;

  /// <summary> Raised if an item already exists in a collection.</summary>
  EAlreadyExists = class(Exception);

  /// <summary> Raised if an file of an unsupported fileformat was tried to load.</summary>
  EUnsupportedFileformat = class(Exception);

  /// <summary> Any error in custom TValue code.</summary>
  ECustomTValueError = class(Exception);

  /// <summary> Generic exception for any operand operations, where an operation can't handle
  /// the operands.</summary>
  EOperandTypeMissmatch = class(Exception);

  /// <summary> Shortcut for HInternationalizer.TranslateText. </summary>
function _(const Langkey : string) : string; overload;
function _(const Langkey : string; const FormatParams : array of const) : string; overload;
function _(const Langkey : string; out TranslatedText : string) : boolean; overload;
function _(const Langkey : string; const FormatParams : array of const; out TranslatedText : string) : boolean; overload;

// eine Procedure die nichts tut
procedure NOOP;

// bis JETZT gitbt die Funktion zu einem Wert zwischen 0-16 den entsprechenden Hex-Wert zurück, also noch ausbaubar!
function DezToHex(Value : Byte) : string;

// Verwandelt einen Single in einen Cardinal nötig für einige Renderstates
function DHS2C(_s : Single) : Cardinal;

// Integer zu TObject und wieder zurück
function IntToObject(Value : Integer) : TObject;
function ObjectToInt(Objekt : TObject) : Integer;

function SetToCardinal(const aSet; const Size : Cardinal) : Cardinal;
procedure CardinalToSet(const Value : Cardinal; var aSet; const Size : Cardinal);

// Cardinal zu TObject und wieder zurück
function CardinalToObject(Value : Cardinal) : TObject;
function ObjectToCardinal(Objekt : TObject) : Cardinal;

// Cardinal zu String und wieder zurück (Speicherumformung)
function CardinalToString(Value : Cardinal) : string;
function StringToCardinal(Value : string) : Cardinal;

// TObject zu String und wieder zurück, dabei wird direkt der Speicher umgeformt, also NICHT zum Ausgeben geeignet!
function ObjectToString(Objekt : TObject) : string;
function StringToObject(Value : string) : TObject;

// Gibt zu einem relativen Dateipfad den kompletten String zurück
function FormatDateiPfad(Value : string) : string;
function AbsolutePath(Value : string) : string;

// Löscht aus einem String den momentanen Programmpfad raus, damit enthält er nur noch den Pfad innerhalb des Programmordners
function RelativDateiPfad(Value : string) : string; overload;

// clamp mit 0,255
function saturate(Wert : Integer) : Integer;
// formt einen 0.0-1.0 Single in 0-255er byte um
function SingleToByte(s : Single) : Byte;

function Log2Aufgerundet(InWert : Cardinal) : Integer;
function Naechste2erPotenz(InWert : Cardinal) : Integer;

// Bitmaske
procedure BitmaskeBitLoeschen(var Maske : Cardinal; Bitposition : Byte);
procedure BitmaskeBitSetzen(var Maske : Cardinal; Bitposition : Byte);
function BitmaskeBitTesten(Maske : Cardinal; Bitposition : Byte) : boolean;
function BitmaskeMaskenVereinen(Maske1, Maske2 : Cardinal) : Cardinal;
function BitmaskeMaskenSchneiden(Maske1, Maske2 : Cardinal) : Cardinal;

// Base16 (Hex) En-/Decoding
function EncodeBase16(const Data : TBytes) : string;

// Base64 En-/Decoding

function EncodeBase64(s : AnsiString) : AnsiString;
function DecodeBase64(s : AnsiString) : AnsiString;

// StringUtils

function TrimLeft(s : string; chars : array of char) : string;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  /// ///////////////////////////////////////////////////////////////////////////////////////////////////
  /// RParam
  /// ///////////////////////////////////////////////////////////////////////////////////////////////////

  ETypeMissmatch = class(Exception);

  EnumParameterType = (ptEmpty, ptUnknown, ptInteger, ptSingle, ptBoolean, ptPointer, ptTObject,
    ptRVector3, ptRVector2, ptRColor, ptString, ptArray, ptRIntVector2, ptMethod, ptByte, ptSet);

  IParameterHeapData = interface
    function GetSize : Integer;
    function GetRawDataPointer : Pointer;
  end;

  TStringHeapData = class(TInterfacedObject, IParameterHeapData)
    private
      FData : string;
    public
      constructor Create(Data : string);
      function GetSize : Integer;
      function GetRawDataPointer : Pointer;
  end;

  TArrayHeapData<T> = class(TInterfacedObject, IParameterHeapData)
    private
      FData : TArray<T>;
    public
      property Data : TArray<T> read FData;
      constructor Create(Data : TArray<T>);
      function GetSize : Integer;
      function GetRawDataPointer : Pointer;
  end;

  TAnyHeapData<T> = class(TInterfacedObject, IParameterHeapData)
    private
      FData : T;
    public
      constructor Create(Data : T);
      function GetSize : Integer;
      function GetRawDataPointer : Pointer;
  end;

  TRawHeapData = class(TInterfacedObject, IParameterHeapData)
    private
      FData : TBytes;
    public
      constructor CreateFromRawData(Data : Pointer; Size : Integer);
      function GetSize : Integer;
      function GetRawDataPointer : Pointer;
      function GetData<T> : T;
      function AsArray<T> : TArray<T>;
      destructor Destroy; override;
  end;

  /// <summary> Type that can hold any type and provide severals methods to create RParam fom type and
  /// read type from RParam. Replace TValue and make things faster but more unsafe.
  /// HINT: Read any data from a RParam will NOT convert any data. This will only do a memory cast!</summary>
  RParam = packed record
    public const
      // detemines max size of a type that saved on stack, for types > MAXSTACKSIZE heap memory is allocated
      MAXSTACKSIZE = SizeOf(RVector4);
    private
      FType : EnumParameterType;
      FSize : Byte;
      FUnknownType : Pointer;
      FHeapData : IParameterHeapData;
      function GetSize : Integer;
      class procedure ExpectType(Expected, Given : EnumParameterType; AllowOther : boolean = True); static;
    public
      /// <summary> Size of saved data in bytes.
      /// For heapdata like string or array will return size of data only, not of data + lengthcounter etc.</summary>
      property Size : Integer read GetSize;
      /// <summary> Datatype of saved data. This field is unreliable, because only for typed (non generic)
      /// creation methods informations are created. Only relaiable for string and array data!</summary>
      property DataType : EnumParameterType read FType;
      /// <summary> Create RParam from a Value of generic type T. NOT used it for reference counted types
      /// like arrays or strings. This will cause errors on data access. </summary>
      class function From<T>(Value : T) : RParam; static;
      class function FromString(const Value : string) : RParam; static;
      /// <summary> Use with care as this method is way more slower than others. It will determine the type of T correctly. </summary>
      class function FromWithType<T>(const Value : T) : RParam; static;
      class function FromProc<T>(const proc : T) : RParam; static;
      class function FromArray<ElementType>(Value : TArray<ElementType>) : RParam; static;
      class function FromRawData(RawData : Pointer; RawDataSize : Integer) : RParam; static;
      class function FromTValue(const Value : TValue) : RParam; static;
      /// <summary> There is an implicit conversion, but to prevent the compiler from auto-cast a rounded single value its needed. </summary>
      class function FromInteger(Value : Integer) : RParam; static;
      class function DeserializeFromStream(Stream : TStream) : RParam; static;
      function IsEmpty : boolean;
      function AsBooleanDefaultTrue : boolean;
      /// <summary> Only works on values with type ptUnknown. </summary>
      function IsType<T> : boolean;
      function AsType<T> : T;
      function AsTypeDefault<T>(const DefaultValue : T) : T;
      function AsEnumType<T> : T;
      function AsSetType<T> : T;
      function AsProc<T> : T;
      function AsVector3 : RVector3;
      function AsVector3Default(const DefaultValue : RVector3) : RVector3;
      function AsVector2 : RVector2;
      function AsVector2Default(const DefaultValue : RVector2) : RVector2;
      function AsString : string;
      function AsBoolean : boolean;
      function AsSingle : Single;
      function AsSingleDefault(DefaultValue : Single) : Single;
      function AsInteger : Integer;
      function AsIntegerDefault(DefaultValue : Integer) : Integer;
      function AsByte : Byte;
      function AsIntVector2 : RIntVector2;
      /// <summary> Return for a RParam containing array or rawdata a typed array.</summary>
      function AsArray<ElementType> : TArray<ElementType>;
      function GetRawDataPointer : Pointer;
      function ToString : string;
      procedure SerializeIntoStream(Stream : TStream);
      class operator implicit(const a : RVector3) : RParam;
      class operator implicit(const a : RVector2) : RParam;
      class operator implicit(const a : RColor) : RParam;
      class operator implicit(a : Integer) : RParam;
      class operator explicit(a : Byte) : RParam;
      class operator implicit(a : Single) : RParam;
      class operator implicit(a : TObject) : RParam;
      class operator implicit(const a : string) : RParam;
      class operator explicit(const a : string) : RParam;
      class operator implicit(a : boolean) : RParam;
      class operator implicit(const a : RIntVector2) : RParam;
      class operator equal(const a, b : RParam) : boolean;
      class operator notequal(const a, b : RParam) : boolean;
    private
      case Byte of
        0 : (FInteger : Integer);
        1 : (FSingle : Single);
        2 : (FBoolean : boolean);
        3 : (FPointer : Pointer);
        4 : (FObject : TObject);
        5 : (FVector3 : RVector3);
        6 : (FColor : RColor);
        7 : (FByte : Byte);
        8 : (FIntVector2 : RIntVector2);
        9 : (FVector2 : RVector2);
  end;

const

  RPARAMEMPTY : RParam  = ();
  RPARAM_EMPTY : RParam = ();

  /// ///////////////////////////////////////////////////////////////////////////////////////////////////
  /// End RParam
  /// ///////////////////////////////////////////////////////////////////////////////////////////////////

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  [XMLExcludeAll]
  TDirtyClass = class
    protected
      FClean : boolean;
      procedure SetDirty;
      procedure SetClean;
      function IsDirty : boolean; virtual;
  end;

  EnumSpecialPaths = (spDesktop, spMyDocuments, spAppdata, spProgramFiles);

  ProcFileCallback = reference to procedure(const Filename : string);

  /// <summary> A global manager class for everything around filepaths.
  /// Terminology:
  /// Path/FilePath - targeting folders
  /// Name/FileName - targeting files without folders
  /// FullFileName - targeting files with folders, independend of relative or absolute
  /// </summary>
  HFilepathManager = class abstract
    strict private
      class var FExePath, FWorkingPath : string;
      class procedure setWorkingPath(Value : string); static;
      class function getAbsoluteWorkingPath : string; static;
      class procedure TrimEqualPath(var Path1, Path2 : string); static;
      class procedure ResolveFolderJumps(var Path : string); static;
    public
      /// <summary> Absolute path where the program exe can be found. </summary>
      class property ExePath : string read FExePath;
      /// <summary> The root folder for all relative file paths. Relative from the exepath. </summary>
      class property RelativeWorkingPath : string read FWorkingPath write setWorkingPath;
      /// <summary> The root folder for all relative file paths. </summary>
      class property AbsoluteWorkingPath : string read getAbsoluteWorkingPath;
      /// <summary> Loads the working path from a file in the same folder as the exe. If file doesn't
      /// exist create a dialog for the user to choose the working path. </summary>
      class procedure LoadWorkingPath(Filename : string); static;
      /// <summary> Saves the current workingpath to a file. </summary>
      class procedure SaveWorkingPath(Filename : string); static;

      /// <summary> Returns whether the path is an absolute path or not. </summary>
      class function IsAbsolute(const Path : string) : boolean;
      /// <summary> Returns whether the path is an realative path or not. </summary>
      class function IsRelative(const Path : string) : boolean;
      /// <summary> Transforms a relative path to an absolute path with the working path
      /// as root folder. Resolves shortcuts. </summary>
      class function RelativeToAbsolute(const Path : string) : string; static;
      /// <summary> Transforms an absolute path to an relative path. Resolves shortcuts. </summary>
      class function AbsoluteToRelative(const Path : string) : string; static;
      /// <summary> Returns the path to some special folders. </summary>
      class function GetSpecialPath(SpecialPath : EnumSpecialPaths; FormHandle : HWND) : string; static;

      /// <summary> Returns whether the file exists. If the path is relative it will be absolutized. </summary>
      class function FileExists(Filename : string) : boolean; static;

      /// <summary> Checks wheter the given Filename has the given FileExtension. </summary>
      class function IsFileType(const Filename, FileExtension : string) : boolean;

      /// <summary> Returns the relative path of RelativePath relative to BaseRelativePath. </summary>
      class function RelativeToRelative(RelativePath, BaseRelativePath : string) : string; static;

      /// <summary> Appends Suffix to the Filename of the Filepath, keeping extension intact. </summary>
      class function AppendToFilename(const Filepath, Suffix : string) : string; static;

      /// <summary> Sanitizes the path for comparisons. </summary>
      class function UnifyPath(const Filepath : string) : string;

      class procedure ForEachFile(RootFolder : string; Callback : ProcFileCallback; Mask : string = '*.*'; Recurse : boolean = True);

      class constructor Create;
  end;

  ProcSubstitute = reference to function(const sub : string) : string;
  ProcAdjuster = reference to function(index : Integer; const sub : string) : string;
  ProcMatchCallback = reference to procedure(matchindex : Integer; Matches : TArray<string>);
  ProcMultiSubstitute = reference to function(sub : array of string) : string;

  TRegexHelper = record helper for TRegex
    public
      function Substitute(str : string; Callback : ProcSubstitute) : string;
      /// <summary> Replaces found matches with replacement, working with \1 \2 ...
      /// Adjuster can adjust the \1 \2 when used.</summary>
      class function SubstituteDirect(const str : string; const Pattern : string; const replacement : string; adjuster : ProcAdjuster = nil; Options : TRegExOptions = []) : string; overload; static;
      function SubstituteDirect(const str : string; const replacement : string; adjuster : ProcAdjuster = nil) : string; overload;
      function MultiSubstitute(str : string; Callback : ProcMultiSubstitute) : string;
      class function StartsWith(const Text, Pattern : string; out Match : string; Options : TRegExOptions = []) : boolean; static;
      class function StartsWithAt(const Text : string; StartIndex : Integer; Pattern : string; out Match : string; Options : TRegExOptions = []) : boolean; static;
      /// <summary> Assumes there is at least one capture group. The first will be returned in match. </summary>
      class function IsMatchOne(const str, Pattern : string; out Match : string; Options : TRegExOptions = []) : boolean; static;
      class function IsMatchTwo(const str, Pattern : string; out MatchOne, MatchTwo : string; Options : TRegExOptions = []) : boolean; static;
      /// <summary> Calls for each group (not the 0-group) of each match the callback. </summary>
      class procedure MatchesForEach(const str, Pattern : string; Callback : ProcMatchCallback; Options : TRegExOptions = []); static;
  end;

  /// <summary>
  /// Thread-safe implementation of a FIFO queue
  /// </summary>
  TThreadSafeQueue<T> = class
    private
      FMutex : TMutex;
      FItems : TQueue<T>;

      function GetSize() : Integer;

    public
      constructor Create();
      destructor Destroy(); override;
      /// <summary>Adds an item to the end of the queue</summary>
      procedure Enqueue(Item : T);
      /// <summary>Returns the first item of the queue without removing it.
      /// Peeking on an empty queue will raise an exception.</summary>
      function Peek() : T;
      /// <summary>Returns the first item of the queue and removes it.
      /// Peeking on an empty queue will raise an exception.</summary>
      function Dequeue() : T;
      /// <summary>Tries to dequeue the first item of the queue. If there is
      /// an item to dequeue it will be assigned to the item paramter and return
      /// True. Otherwise this function will return False.</summary>
      function TryDequeue(var Item : T) : boolean;
      property Count : Integer read GetSize;
  end;

  /// <summary> Provides functionality for translation. Keys can be substituted with
  /// nationalized strings loaded from text-files. The text-files should be named as the
  /// ISO 639-1: http://de.wiktionary.org/wiki/Hilfe:Sprachcodes with lang as ending.
  /// E.g german = de.lang. The textfiles should be constructed with a key-value pair
  /// in one line. With // at the beginning comments are introduced. Key are case-insensitive
  /// </summary>
  HInternationalizer = class
    strict private
    const
      DEFAULTLANG = 'en';
    class var
      FMapping : TObjectDictionary<string, TDictionary<string, string>>;
      FCurrentLang : string;
      class procedure UpdateLangFile(const Filepath : string; const Filecontent : string);
    public
      class property CurrentLanguage : string read FCurrentLang;
      class function CurrentLanguageAsLocaleName : string;

      class function DecimalSeparator : string;
      class function MakePercentage(const NumberAsString : string) : string;
      class function TranslationProgress(const Language : string = '') : Single;

      /// <summary> Return all LangKeys saved over all languages. </summary>
      class function GetAllKeys : TArray<string>;
      /// <summary> Adds the empty langkey to all languages. </summary>
      class procedure AddLangKey(Langkey : string);
      /// <summary> Renames a langkey in all languages. </summary>
      class procedure RenameLangKey(Langkey, newLangKey : string);
      /// <summary> Removes a langkey from all languages. </summary>
      class procedure RemoveLangKey(Langkey : string);
      /// <summary> Returns whether the langkey is present. </summary>
      class function HasLangKey(Langkey : string) : boolean;
      /// <summary> Sets a langkey in a language. </summary>
      class procedure SetLangKey(Lang, Langkey, Value : string);
      /// <summary> Gets a langkey in a language. </summary>
      class function GetLangKey(Lang, Langkey : string) : string;
      /// <summary> Returns the raw lang dict of a language. DON'T FREE! </summary>
      class function GetLangDict(Lang : string) : TDictionary<string, string>;
      /// <summary> Saves all langfiles to the given directory. </summary>
      class procedure SaveLangFiles(FileFolder : string);

      /// <summary> Returns an array of all mapped languages, e.g [de,en] </summary>
      class function GetLoadedLanguages() : TArray<string>;
      /// <summary> Chooses a language for the target of the translation. If it isn't mapped
      /// nevertheless it will be chosen, because user could recharge langfiles. </summary>
      /// <param name="Lang"> New language to which the Internationalizer will translate. Format is
      /// 'de', 'en', whereby the format of lang files determines the keys.</param>
      class procedure ChooseLanguage(const Lang : string);
      /// <summary> Loads a langfile. Filename will be used as lang-key. </summary>
      class procedure LoadLangFile(const Filename : string);
      /// <summary> Loads all langfiles in the given directory and subdirectories if recursive. </summary>
      class procedure LoadLangFiles(const FileFolder : string; Recursive : boolean = False; const IgnorePattern : string = '');

      /// <summary> The most important method. Translates a case-insensitive key to the target language. §-Chars are
      /// ignored in the key, because it's the official prefix. If the key is not found in the target language,
      /// the defaultlang will be used ('en'). If the key isn't found there too , the key will be returned unchanged,
      /// </summary>
      class function Translate(const Key : string) : string;
      class function TryTranslate(Key : string; out Translated : string) : boolean;
      /// <summary> Substitutes all occurencies of keys with prefixed § (regex: (§\w+)) using the Translate method.
      /// If no § is found, trys to translate as key. </summary>
      class function TranslateText(const Text : string) : string;
      /// <summary> Returns whether something was translated in the text. </summary>
      class function TryTranslateText(const Text : string; out newText : string) : boolean;
      /// <summary> Same as TranslateText, but supports nested lang keys. </summary>
      class function TranslateTextRecursive(const Text : string) : string; overload;
      class function TranslateTextRecursive(const Text : string; const FormatParams : array of const) : string; overload;

      /// <summary> Initializes Internationalizer, will be called automatically. Set Language to current systemlanguage.</summary>
      class procedure Init;
      /// <summary> Finalizes Internationalizer, will be called automatically. </summary>
      class procedure Finalize;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  TTimer = class;
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  /// <summary> Wraps any fileaccess with caching. Calls a callback if file has changed.</summary>
  TContentManager = class
    public
      type
      ProcFileLoadIntoMemoryCallback = procedure(const Filepath : string; const Filecontent : TMemoryStream) of object;
      ProcFileLoadIntoStringCallback = procedure(const Filepath : string; const Filecontent : string) of object;
      ProcFileChangeNotificationCallback = procedure(const Filepath : string) of object;
    private
      procedure SetObservationEnabled(const Value : boolean);
      function GetObservationEnabled : boolean;
    protected
      type
      TManagedFile = class
        private
          FMemoryCleaned, FStringCleaned, FHoldInMemory : boolean;
          FData : TMemoryStream;
          FDataAsString : string;
          function GetData : TMemoryStream;
          function GetStringData : string;
          procedure FreeData;
        public
          MemorySubscribers : TList<ProcFileLoadIntoMemoryCallback>;
          StringSubscribers : TList<ProcFileLoadIntoStringCallback>;
          PlainSubscribers : TList<ProcFileChangeNotificationCallback>;
          Filepath : string;
          Timestamp : TDateTime;
          property Data : TMemoryStream read GetData;
          property DataAsString : string read GetStringData;
          constructor Create(Filepath : string); overload;
          /// <summary> Will notify the subscriber immediately. </summary>
          procedure SubscribePlain(Callback : ProcFileChangeNotificationCallback; SubscribeOnly : boolean);
          procedure UnSubscribePlain(Callback : ProcFileChangeNotificationCallback);
          /// <summary> Will notify the subscriber immediately. </summary>
          procedure Subscribe(Callback : ProcFileLoadIntoMemoryCallback; SubscribeOnly : boolean);
          procedure UnSubscribe(Callback : ProcFileLoadIntoMemoryCallback);
          /// <summary> Will notify the subscriber immediately. </summary>
          procedure SubscribeWithString(Callback : ProcFileLoadIntoStringCallback; SubscribeOnly : boolean);
          procedure UnSubscribeWithString(Callback : ProcFileLoadIntoStringCallback);
          function UpToDate() : boolean;
          function GetCurrentFileAge : TDateTime;
          procedure NotifySubscribers;
          procedure CleanDirty;
          procedure UpdateTimeStamp;
          destructor Destroy; override;
      end;

      TContentObserverThread = class(TThread)
        strict private
          FObservedContent : TThreadSafeObjectDictionary<string, TManagedFile>;
          FCheckTime : TThreadSafeData<int64>;
          FObservationEnabled : boolean;
        private
          procedure SetCheckTime(const Value : int64);
        protected
          procedure Execute; override;
        public
          property ObservationEnabled : boolean read FObservationEnabled write FObservationEnabled;
          property CheckTime : int64 write SetCheckTime;
          constructor Create(ObservedContent : TThreadSafeObjectDictionary<string, TManagedFile>; CheckTime : int64);
          destructor Destroy; override;
      end;
    var
      FContent : TThreadSafeObjectDictionary<string, TManagedFile>;
      FObserverThread : TContentObserverThread;
      FLock : TCriticalSection;
      function GetManagedFile(Filepath : string) : TManagedFile;
      function HasManagedFile(Filepath : string) : boolean;
      procedure SetCheckTime(Value : int64);
    public
      /// <summary> Timeinterval in which files will be checked for up-to-dateness. </summary>
      property CheckTime : int64 write SetCheckTime;
      property ObservationEnabled : boolean read GetObservationEnabled write SetObservationEnabled;
      constructor Create(CheckTime : int64);
      /// <summary> Returns the filecontent as string. If the file is already loaded a cached version is returned. </summary>
      function FileToString(const Filepath : string) : string;
      /// <summary> Returns the filecontent as managed memory stream. If the file is already loaded a cached version is returned. </summary>
      function FileToMemory(const Filepath : string) : TMemoryStream;

      /// <summary> Preloads the file as text. </summary>
      procedure PreloadFileIntoText(const Filepath : string);
      /// <summary> Preloads the file into memory. </summary>
      procedure PreloadFileIntoMemory(const Filepath : string);

      /// <summary> Calls the callback with the content of a file (absolute path expected) as an Stream. If file was loaded before data will be cached. If SubscribeOnly, the callback is not called at registering. </summary>
      procedure SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoMemoryCallback; SubscribeOnly : boolean = False); overload;
      /// <summary> Calls the callback with the content of a file (absolute path expected) as an string. If file was loaded before data will be cached. If SubscribeOnly, the callback is not called at registering. </summary>
      procedure SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoStringCallback; SubscribeOnly : boolean = False); overload;
      /// <summary> Calls the callback only with the filepath. If file was loaded before data will be cached. If SubscribeOnly, the callback is not called at registering. </summary>
      procedure SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileChangeNotificationCallback; SubscribeOnly : boolean = False); overload;
      /// <summary> Returns the content of a file (absolute path expected) as an string. If file was loaded before data will be cached. If SubscribeOnly, the callback is not called at registering. </summary>
      procedure SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoStringCallback; out Filecontent : string; SubscribeOnly : boolean = False); overload;
      /// <summary> Call this every frame. If checktimer is expired, the registered files will be checked. </summary>
      procedure UnSubscribeFromFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoMemoryCallback); overload;
      procedure UnSubscribeFromFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoStringCallback); overload;
      procedure UnSubscribeFromFile(const Filepath : string; ChangeCallback : ProcFileChangeNotificationCallback); overload;
      // ==== Debug methods
      /// <summary> Returns a string containg for each file extension the used memory.</summary>
      function GetMemoryUsageOverview : string;
      destructor Destroy; override;
  end;

  TDatenSpeicher<T> = class
    protected
      class var parameters : array of T;
    public
      class function GetParameter(Index : Integer) : T;
      class function SetParameter(Index : Integer; const Value : T) : T;
  end;

  RBitmaske = record
    Bits : Cardinal;
    procedure BitSetzen(Index : Integer; Value : boolean);
    function BitTesten(Index : Integer) : boolean;
    property BitArray[index : Integer] : boolean read BitTesten write BitSetzen;
    function Vereinen(Maske2 : RBitmaske) : RBitmaske;
    function Schneiden(Maske2 : RBitmaske) : RBitmaske;
  end;

  TFileVersionInfo = record
    fCompanyName,
      fFileDescription,
      fFileVersion,
      fInternalName,
      fLegalCopyRight,
      fLegalTradeMark,
      fOriginalFileName,
      fProductName,
      fProductVersion,
      fComments : string;
  end;

  /// <summary> Enthält alle Operationen die auf Systemebene operieren, z.B. DVD-Laufwerk aufmachen, Name der Festplatte,...
  /// ACHTUNG: Die Klasse muss / sollte nicht instanziert werden, da sie nur Klassenmethoden besitzt, welche direkt genutzt werden können
  /// </summary>
  HSystem = class
    private
      class var FRegisteredFonts : TArray<string>;
    public
      class property RegisteredFonts : TArray<string> read FRegisteredFonts;
      /// <summary>  Öffnet oder Schließt ein Laufwerk. </summary>
      /// <param name="ADriveChar"> Das Laufwerk was geöffnet/geschloßen werden soll </param>
      /// <param name="AOpen"> Bei True wird das Laufwerk geöffnet, bei False geschlossen </param>
      class procedure LaufwerkÖffnen(ADriveChar : char; AOpen : boolean);
      /// <summary>  Prüft ob in ein Laufwerk ein Medium (z.B. DVD) eingelegt ist. Dazu wird der Laufwerksbuchstabe übergeben.</summary>
      class function MediumInLaufwerk(const ADrive : char) : boolean;
      /// <summary>  Listet alle Laufwerke eines bestimmten Typs auf.
      /// Typen: DRIVE_REMOVABLE, DRIVE_FIXED, DRIVE_REMOTE, DRIVE_CDROM, DRIVE_RAMDISK</summary>
      class function GetLaufwerkeEinesTyps(LaufwerksType : Cardinal) : TStrings;
      /// <summary>  Bringt ein Fenster (gegeben durch das Handle) in den Vordergrund</summary>
      class function ForceForegroundWindow(HWND : THandle) : boolean;
      /// <summary> Load icon from file. Size of icon is given by flag e.g. SHIL_JUMBO or SHIL_LARGE</summary>
      class procedure GetIconFromFile(const aFile : string; var aIcon : TIcon; SHIL_FLAG : Cardinal);
      /// <summary> Return a record with different infos about file like FileDescription and FileVersion. If something fails on collecting
      /// data, method raise a Exception.</summary>
      class function GetAllFileVersionInfo(const Filename : string) : TFileVersionInfo;
      class function GetKeynameFromScanCode(Scancode : Word) : string;
      /// <summary> Registers a processlocal font until the process terminates. </summary>
      class procedure RegisterFontFromResource(Resource : Integer);
      /// <summary> Registers a processlocal font until the process terminates. </summary>
      class procedure RegisterFontFromFile(const Resourcepath : string);
      class procedure OpenUrlInBrowser(const Url : string); static;
      /// <summary> Check if the application can write one this directoy, the test will also fail
      /// if the directoy does not exists.</summary>
      class function CheckIfDirectoryIsWritable(DirectoryPath : string) : boolean;
      /// <summary> Abort any running shutdowns of the system. </summary>
      class procedure ShutdownAbort;
      /// <summary> Shutdowns the system in TimeToShutdown seconds. </summary>
      class procedure Shutdown(const TimeToShutdown : int64);
      /// <summary> Plays target wave file. Should only be used to debug purposes otherwise use Engine.Sound! </summary>
      class procedure PlayWave(const Filename : string; Loop : boolean = False);
      /// <summary> Stops any played wave files started by PlayWave. </summary>
      class procedure StopPlayWave();
      /// <summary> Parses a resolution string with format 'WidthxHeight'.</summary>
      class function TryParseResolution(const Resolution : string; out Width, Height : Integer) : boolean;
      /// <summary> Parses a resolution string with format 'LeftxTopxWidthxHeight'.</summary>
      class function TryParseRect(const RectString : string; out Rect : TRect) : boolean;
      /// <summary> The amount of memory currently in use of the delphi memory manager. </summary>
      class function MemoryUsed : Cardinal;
      /// <summary> The amount of memory currently reserved of the delphi memory manager. </summary>
      class function MemoryReserved : Cardinal;
      class destructor Destroy;
  end;

  /// <summary> Enthält alle Operationen um Dateien zu verändern, Eigenschaften auszulesen etc.
  /// ACHTUNG: Die Klasse muss / sollte nicht instanziert werden, da sie nur Klassenmethoden besitzt, welche direkt genutzt werden können
  /// </summary>
  HFileIO = class
    public type
      ProcCSVCallback = reference to procedure(ColumnValues : TArray<string>);
      /// <summary>
      /// <param name="LastItemFound"> Last directory or file found</param>
      /// <param name="CurrentFileCount"> Count of files added to filelist</param>
      /// <param name="Cancel"> Default is False, if True, method will stop searching for files.</param></summary>
      ProcFindFilesCallback = reference to procedure(const LastItemFound : string; CurrentFileCount : Integer; var Cancel : boolean);
    public
      /// <summary> Sucht alle Dateien die zur Maske 'Mask' passen im Rootfolder. Ist Recurse = True, wird auch in allen Unterordnern gesucht.
      /// Die gefunden Dateien werden mit vollständigen Pfad in FileList gespeichert. Wenn das Objekt FileList noch nicht existiert, wird es erstellt.
      /// If Callback is not nil, callback is called before! every file or directory found.</summary>
      class procedure FindAllFiles(var FileList : TStrings; RootFolder : string; Mask : string = '*.*'; Recurse : boolean = True; Callback : ProcFindFilesCallback = nil);
      class function GetSubDirectories(const Directory : string) : TStrings;
      /// <summary> Returns the number of files in directory.</summary>
      class function FileCount(const Directory : string; Recurse : boolean = False) : Integer;
      /// <summary> Return size from file given by FileName. If file not exist, return 0. Use WinApi for implementation.</summary>
      class function GetFileSize(const Filename : string) : int64;
      class function TryReadFromIni(Filename, Section, Key : string; out Value : string) : boolean;
      class function TryReadIntFromIni(Filename, Section, Key : string; out Value : Integer) : boolean;
      class function TryReadBoolFromIni(Filename, Section, Key : string; out Value : boolean) : boolean;
      /// <summary> Read Inivalue section and key in section. If key not exists, return default.</summary>
      class function ReadFromIni(Filename, Section, Key : string; Default : string = '') : string;
      class function ReadBoolFromIni(Filename, Section, Key : string; Default : boolean = False) : boolean;
      class function ReadIntFromIni(Filename, Section, Key : string; Default : Integer = 0) : Integer;
      class function ReadSectionsFromIni(Filename : string) : TStrings;
      class procedure WriteToIni(Filename, Section, Key, Value : string);
      /// <summary> For each row CSVCallback is called with the splitted values. </summary>
      class procedure ReadCSV(const Filename : string; CSVCallback : ProcCSVCallback; Delimiter : char = ' '; CommentCharacter : char = '#');
      class procedure ReadCSVFromString(const Filecontent : string; CSVCallback : ProcCSVCallback; Delimiter : char = ' '; CommentCharacter : char = '#');
      /// <summary> Returns true if path is directory (and not a file), else false.
      /// <param name="DirPath"> Path to check if is a directory.</param><summary>
      class function IsDirectory(DirPath : string) : boolean;
      /// <summary> Tests if file exists, if not raise FileNotFoundException containing filename</summary>
      class procedure EnsureFileExists(Filename : string);
      /// <summary> Adds a string at the end of the filename, takes file extension into account. </summary>
      class function AddFileSuffix(Filename, Suffix : string) : string;
      class function FileToMD5Hash(Filename : string) : string;
      class function ReadAllText(const Filepath : string; Encoding : TEncoding = nil) : string;
      class procedure DeleteAllFilesInDirectory(const Path : string);
  end;

  /// <summary> This class encapsulated helper methods for working with strings.
  /// ATTENTION: This class is designed for static use. </summary>
  HString = class abstract
    public
      type
      ProcIncludeLoaderCallback = function(Identifier : string) : AnsiString of object;
    var
      /// <summary> Inserts for each upcase character within a word a space. </summary>
      class function BreakCamelCase(str : string) : string;
      /// <summary> Save the content of a resource to an ansistring </summary>
      /// <param name=UseInclude>Extract #include Filename, and searches for appropriate Resources to be inserted</param>
      class function ResourceToString(Resourcename : string; UseInclude : boolean = False) : AnsiString;
      class function FileToString(Filename : string; UseInclude : boolean = False) : AnsiString;
      class function FileOrResourceToString(FileNameOrResourceName : string; UseInclude : boolean = False) : AnsiString;
      class function IdentifierToString(Identifier : string; UseInclude : boolean = False; LoaderCallback : ProcIncludeLoaderCallback = nil) : AnsiString;
      /// <summary> Loads the content of a resource in a string. </summary>
      class function ResourceToStringRaw(Resourcename : string) : AnsiString;
      /// <summary> Loads the content of a file in a string. </summary>
      class function FileToStringRaw(Filename : string) : AnsiString;
      class function FileOrResourceToStringRaw(Identifier : string) : AnsiString;
      /// <summary> Loads the content of a file in a string. </summary>
      class function StreamToStringRaw(Stream : TStream) : AnsiString;
      class procedure SaveStringToFile(Filename : string; Data : string);
      /// <summary> Speichert einen String (rein) in einem Array of Char (raus). Das Array wird von der Methode auf die benötigte Größe angepasst</summary>
      class procedure StringToCharArray(var raus : array of AnsiChar; rein : string);
      /// <summary> Converts a null-terminated char-array to a string. </summary>
      class function CharArrayToString(inArray : array of char) : string; overload;
      class function AnsiCharArrayToString(inArray : array of AnsiChar) : string; overload;
      /// <summary> Gibt den gemeinsamen String zweier Strings zurück, dabei wird vom Anfang beginnend verglichen und abgebrochen bei einem unterschiedlichem Zeichen.
      /// ExtrahiereGemeinsamenString('12345','12355') gibt also '123' zurück </summary>
      class function ExtrahiereGemeinsamenString(Str1, Str2 : string) : string;
      /// <summary>Gibt einen zweistelligen Integer in String Form zurück 0-9 als '00'-'09' und den Rest dann '10'-'99'</summary>
      class function IntMitNull(const Value : Integer; Digits : Integer = 2) : string;
      /// <summary> Returns a string from an int. If FixedLength is set, the string will be filled with 0s at the beginnging. </summary>
      class function IntToStr(int : Integer; FixedLength : Integer = -1; AddThousandSeparator : char = #0) : string;
      class function GenerateChars(MultipliedString : string; Times : Integer) : string;
      /// <summary> Gibt aus einer beliebigen Zusammenstellung von Werten ein String zurück, getrennt durch Komma.
      /// Bsp.: strO(['Hallo Nummer ',3,'!'])</summary>
      class function strO(Values : array of Variant) : string;
      /// <summary>gibt aus einer beliebigen Zusammenstellung von Werten ein String zurück, im C-Style
      /// Beispiel strC('Hallo ihr %v, da draußen.',[Zahl]);
      /// dabei gibt es nur %v für Variable, der Typ ist egal</summary>
      class function strC(Text : string; Values : array of Variant) : string;
      /// <summary> Ensures that the given Duplicant is at most once at one time. 'Rgl/rgl//rglrgl///' => 'Rgl/rgl/rglrgl/' </summary>
      class function RemoveDuplicants(const Value : string; const Duplicant : char) : string;
      /// <summary>  Ersetzt jedes vorkommen von ZuErsetzenderString in einem String (Str) durch ErsetzenderString.
      /// HINWEIS: Es wird solange ersetzt bis ZuErsetzenderString nicht mehr vorkommt. Damit führt
      /// Replace(a,aa,'abc') zu einer Endlosschleife! </summary>
      class function Replace(ZuErsetzenderString, ErsetzenderString, str : string) : string; overload;
      class function Replace(const Value : string; const Replacers : array of string; const replacement : string = '') : string; overload;
      /// <summary> <summary>  Ersetzt jedes vorkommen von ZuErsetzenderString in einem String (Str) durch ErsetzenderString genau einmal. </summary>
      class function ReplaceEachOnce(ZuErsetzenderString, ErsetzenderString, str : string) : string;
      /// <summary> Deletes all chars after the last appearance of the mark, including the mark. </summary>
      class function TrimAfter(Mark, TrimString : string) : string;
      /// <summary> Deletes all chars before the first appearance of the mark, including the mark. </summary>
      class function TrimBefore(Mark, TrimString : string) : string;
      class function TrimBeforeCaseInsensitive(Mark, TrimString : string) : string;
      class function StartWith(StrValue : string; StartWith : TArray<string>) : boolean;
      /// <summary> Deletes the equal prefix of both parameters. </summary>
      class procedure TrimEqualityBeforeCaseInsensitive(var AString, AnotherString : string);
      class function DeleteDoubleSpaces(str : string) : string;
      /// <summary> Deletes all occurencies of Character at the beginning and ending of str, e.g. HString.TrimBoth(' ','  rgl blubs  ') => 'rgl blubs' </summary>
      class function TrimBoth(Character : char; str : string) : string;
      class function DeleteDoubles(DoubledChar : char; str : string) : string;
      /// <summary> Maps 'false','0' to false and 'true','1' to true. Case-Insensitive. Everything else will return Default. </summary>
      class function StrToBool(const str : string; const Default : boolean = False) : boolean;
      class function TryStrToBool(const str : string; out ParsedValue : boolean) : boolean;
      /// <summary> Converts a string to a single, if Value isn't valid Default is returned. </summary>
      class function StrToFloat(const Value : string; const Default : Single) : Single;
      /// <summary> Converts a string to a integer, if Value isn't valid Default is returned. </summary>
      class function StrToInt(const Value : string; const Default : Integer) : Integer;
      class function Count(Substring, Text : string) : Integer;
      /// <summary> Splits up a string according to a set of delimiter. If count is set it splits only the first count occurences and collapses the rest into the last element.
      /// '#if defined(BLA) || defined(RGLRGL) && defined(BLUBBAR)' ['||','&&']
      /// => ['#if defined(BLA) ',' defined(RGLRGL) ',' defined(BLUBBAR)']
      /// => ['#if defined(BLA) ','||',' defined(RGLRGL) ','&&',' defined(BLUBBAR)'] with KeepDelimiter
      /// </summary>
      class function Split(Text : string; const SplitStrings : array of string; const KeepDelimiter : boolean = False; const Count : Integer = -1) : TArray<string>; static;
      /// <summary> 'Reverses a string in its order.' => '.redro sti ni gnirts a sesreveR' </summary>
      class function Reverse(Text : string) : string;
      /// <summary> Returns the substring from startinedx to endindex including both. Negative values are allowed and are counted from the end,
      /// where -1 is the last character of the text, -2 the forelast and so one. Don't goes over string borders.
      /// 'Legions': (1,4) => 'egio', (4,-2) => 'on', (-4,-2) => 'ion', (5, -5) => '', (-1, 5) => '' </summary>
      class function Slice(const Text : string; StartSlice, EndSlice : Integer; Step : Integer = 1) : string;
      /// <summary> Returns "mm:ss", so mm is the minute part and ss the second part of ticks in seconds.
      /// Clamps the time to a valid range, if is not. </summary>
      class function IntToTime(Ticks : Integer; TruncOverflow : boolean = True) : string;
      /// <summary> Returns "hh:mm", so hh is the hour part and mm the minute part of ticks in seconds.
      /// Clamps the time to a valid range, if is not. </summary>
      class function IntToLongTime(Ticks : Integer; TruncOverflow : boolean = True) : string;
      /// <summary> Returns "hh:mm:ss", so hh is the hour part and mm the minute part of ticks in seconds.
      /// Clamps the time to a valid range, if is not. </summary>
      class function IntToLongTimeDetail(Ticks : Integer; TruncOverflow : boolean = True) : string;
      /// <summary> Converts an integer to byte display with different stages (kb, mb, gb). 1023 => 1023 b, 1025 => 1 kb
      /// If ForceUnit <> '' bytes will also formated in units.</summary>
      class function IntToStrBandwidth(Bytes : UInt64; Decimals : Integer = 0; ForceUnit : string = '') : string;
      /// <summary> Trys to apply format on the format string. </summary>
      class function TryFormat(var FormatString : string; const parameters : array of const) : boolean; overload;
      class function TryFormat(const FormatString : string; const parameters : array of const; out FormattedString : string) : boolean; overload;
      /// <summary> Returns the roman numeral for specified integer > 0. 1 -> I, 2 -> II </summary>
      class function IntToRomanNumeral(Value : Integer) : string;
      class function Join(const Values : TArray<string>; const Joiner : string) : string;
      /// <summary> Appends a string on the beginning of each line of text. </summary>
      class function Indent(const Text : string; const Indenter : string = #9) : string;
      /// <summary> Returns true if Str is contained in Strings. </summary>
      class function ContainsString(const Strings : array of string; str : string; IgnoreCase : boolean = False) : boolean; overload;
      /// <summary> Returns true if any of the given substrings are contained in the Str. Case sensitive. </summary>
      class function ContainsSubstring(const Substrings : array of string; const str : string; CaseSensitive : boolean = True) : boolean; overload;
  end;

  /// <summary> This class encapsulated helper methods for working with pointers.
  /// ATTENTION: This class is designed for static use. </summary>
  HPointer = class abstract

  end;

  {$DEFINE SUPERPOINTER_ASSERTS}

  /// <summary> This record encapsulates a normal pointer and offers some methods to work with. </summary>
  RSuperPointer<T> = record
    public type
      PT = ^T;
    private
      FWidth, FHeight : Integer;
      FCount : Integer;
      FOwnsPointer : boolean;
      function GetSize : RIntVector2;
      function GetDataSize : UInt64;
    public
      Memory : Pointer;
      property Width : Integer read FWidth;
      property Height : Integer read FHeight;
      property Size : RIntVector2 read GetSize;
      property DataSize : UInt64 read GetDataSize;
      /// <summary> Assumes that there is valid memory at the pointer. </summary>
      constructor Create(Memory : Pointer);
      /// <summary> Assumes that there is valid memory at the pointer. </summary>
      constructor Create2D(Memory : Pointer; Width, Height : Integer);
      /// <summary> Allocates memory for this pointer. </summary>
      constructor CreateMem(Count : Integer);
      /// <summary> Allocates memory for this pointer. </summary>
      constructor CreateMem2D(Width, Height : Integer); overload;
      /// <summary> Allocates memory for this pointer. </summary>
      constructor CreateMem2D(Size : RIntVector2); overload;
      procedure WriteValue(Offset : Integer; const Value : T);
      function ReadValue(Offset : Integer) : T;
      procedure WriteValue2D(OffsetX, OffsetY : Integer; const Value : T);
      function ReadValue2D(OffsetX, OffsetY : Integer) : T;
      /// <summary> Clamps the positions to the borders of the 2D-Layout. </summary>
      procedure Clamp(var OffsetX, OffsetY : Integer);
      /// <summary> If created with CreateMem, you should call this. </summary>
      procedure Free;
      class operator implicit(a : RSuperPointer<T>) : Pointer;
  end;

  /// <summary> Offers preprocessor abilities for string. </summary>
  HPreProcessor = class
    public
      /// <summary> Takes a code string with newlines and applies defines written in the following style:
      /// #define DEFINITION_NAME an * arbitary + expression
      /// will replace all 'DEFINITION_NAME' found in the text with 'an * arbitary + expression' </summary>
      class function ResolveDefines(str : string) : string;
      /// <summary> Resolves all preprocessor commands in HSLS style. One command per line supported.
      /// Supported commands: #ifdef, #ifndef, #endif, #else, #define
      /// Not supported atm: #if </summary>
      class function ResolveHLSL(str : string) : string;
      /// <summary> Reformats a hlsl file. Removing double empty lines and reindent. </summary>
      class function PrettyPrintHLSL(str : string) : string;
  end;

  /// <summary> A wrapper around the delphi TDateTime type for easy working with Dates and Times. </summary>
  RDate = record
    DateTime : TDateTime;
    constructor Create(DateTime : TDateTime);
    function Day : Integer;
    function Month : Integer;
    function Year : Integer;
    function ToString(FormatString : string) : string;
    class operator implicit(a : TDateTime) : RDate;
  end;

  HRandom = class
    protected
      class var RandomValues : array [0 .. 50000] of Single;
      class var CurrentIndex : Integer;
      class procedure setCurrentIndex(const Value : Integer); static;
    public
      class constructor Create;
      class property RandSeed : Integer read CurrentIndex write setCurrentIndex;
      class function Random() : Single;
  end;

  /// <summary> A generic class Tuple, e.g for object dictionaries to free all owned items. </summary>
  TTuple<T, U> = class
    a : T;
    b : U;
    constructor Create(a : T; b : U);
    destructor Destroy; override;
  end;

  /// <summary> A generic Triple </summary>
  RTriple<T, U, V> = record
    a : T;
    b : U;
    c : V;
    constructor Create(a : T; b : U; c : V);
  end;

  /// <summary> A range type for single.</summary>
  RRange = record
    Minimum : Single;
    Maximum : Single;
    /// <summary> Sort and assign Minimum and Maximum, so if Minimum > Maximum, values are exchanged.</summary>
    constructor Create(const Minimum, Maximum : Single);
    /// <summary> Returns a range with maximum possible range</summary>
    class function MaxRange : RRange; static;
    /// <summary> Returns True if Minimum<= T <=b</summary>
    function InRange(const Value : Single) : boolean;
    function EnsureRange(const Value : Single) : Single;
  end;

  CAttribute = class of TCustomAttribute;

  ProcMethodFilter = reference to function(RttiMethod : TRttiMethod) : boolean;

  TValueEnumerator = class(TEnumerator<TValue>)
    private
      FEnumeratorInstance : TObject;
      FArrayValue : TValue;
      FArrayIndex : Integer;
      FIsArray : boolean;
      FMoveNextMethod : TRttiMethod;
      FCurrentProperty : TRttiProperty;
    protected
      function DoGetCurrent : TValue; override;
      function DoMoveNext : boolean; override;
    public
      constructor Create(const EnumerableValue : TValue);
      function GetEnumerator : TEnumerator<TValue>;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  /// <summary> Der Zeitgeber ist quasi ein Countdowntimer auf ms-Basis </summary>
  [XMLIncludeAll([XMLIncludeFields, XMLIncludeProperties])]
  TTimer = class
    protected
      [XMLExcludeElement]
      FInterval : int64;
      [XMLExcludeElement]
      FLastTime, FPauseTime : double;
      [XMLExcludeElement]
      FPaused : boolean;
      function getExpired : boolean;
      procedure setExpired(const IsExpired : boolean);
      procedure setPaused(const IsExpired : boolean);
      function GetTimeStamp : double; virtual;
      /// <summary> Reinit the Timer with a new Interval, Initially the time is expired</summary>
      procedure SetInterval(const Interval : int64);
    public
      property Interval : int64 read FInterval write SetInterval;
      property Paused : boolean read FPaused write setPaused;
      constructor Create; overload;
      /// <summary> Erstellt einen Zeitgeber mit dem Intervall in ms, Initial ist der Zeitgeber abgelaufen </summary>
      constructor Create(Interval : int64); overload;
      /// <summary> Creates a timer and start him. </summary>
      constructor CreateAndStart(Interval : int64); overload;
      /// <summary> Creates a timer and pause it at beginning. </summary>
      constructor CreatePaused(Interval : int64); overload;
      /// <summary> Gibt zurück ob das Intervall seit dem letzten Start abgelaufen ist </summary>
      [XMLExcludeElement]
      property Expired : boolean read getExpired write setExpired;
      /// <summary> Returns the precent value of the expired interval.
      /// if ClampZeroOne is false, 0.5 = Interval passed half; 2 = Interval passed twice.
      /// else if ClampZeroOne is true, the return value have the same meaning but is clamped to range 0..1</summary>
      function ZeitDiffProzent(ClampZeroOne : boolean = False) : Single;
      /// <summary> Returns the percent value of the expired interval clamped to [0,1]. </summary>
      function Progress : Single;
      /// <summary> Returns 1- ZeitDiffProzent </summary>
      function ZeitDiffProzentInverted(ClampZeroOne : boolean = False) : Single;
      function ProgressInverted : Single;
      /// <summary> Returns the lasted time (in ms) since last Start. </summary>
      function TimeSinceStart : double;
      /// <summary> Returns the needed time (in ms) for expiring. Return 0 if expired. </summary>
      function TimeToExpired : Single;
      /// <summary> Returns how often the timer expired since start. Clamps return value to maximum if set. </summary>
      function TimesExpired(Maximum : Integer = -1) : Integer;
      /// <summary> Returns whether this timer has started and is beyond it's delay. </summary>
      function HasStarted : boolean;
      /// <summary> Restart the timer to zero and unpause it. Expired 3.6 => 0.0 </summary>
      procedure Start; overload;
      procedure Start(const NewInterval : int64); overload;
      /// <summary> Resets the timer by reducing is by at max one interval. Expired 3.6 => 2.6 </summary>
      procedure StartWithRest;
      /// <summary> Resets the timer by reducing all expired intervals. Expired 3.6 => 0.6 </summary>
      procedure StartWithFrac;
      /// <summary> Restart the timer to zero and pause it. </summary>
      procedure StartAndPause;
      /// <summary> Sets the timer to expired. </summary>
      procedure Expire;
      /// <summary> Pausiert den Zeitgeber, friert seinen Status ein </summary>
      procedure Pause;
      /// <summary> Lässt einen pausierten Zeitgeber weiterlaufen, Zeit verhält sich konsistent </summary>
      procedure Weiter;
      /// <summary> Restart the timer, but don't touch the pause state. </summary>
      procedure Reset;
      /// <summary> Setzt den Wert, so dass der Zeitgeber sich verhält, als wenn Wert abgelaufen ist </summary>
      procedure SetZeitDiffProzent(Wert : Single);
      /// <summary> Reinit the Timer with a new Interval and start it </summary>
      procedure SetIntervalAndStart(Interval : int64);
      /// <summary> Delays the expiring by DelayMs. </summary>
      procedure Delay(DelayMs : Integer);
      /// <summary> Clones this timer with all its states. </summary>
      function Clone : TTimer;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  EnumClockType = (ctHighPerformanceCounter, ctGetTickCount);

  TTimeManager = class
    strict private
      class var
        ProgramStart : int64;
    var
      FZDiff : Single;
      FPaused : boolean;
      FPauseTime, FTimeAtPause : int64;
      FHighPerformanceCounter : boolean;
      Frequenz, LetzteZeit, MomentaneZeit : int64;
      Zeitskalierung : double;
      procedure SetPause(const Value : boolean);
      function GetClockType : EnumClockType;
    public
      /// <summary> If True HighPerformanceCounter is used to read timestamps, else GetTickCount.
      /// On default system tries to use HighPerformanceCounter, if not available GetTickCount is used.</summary>
      property HighPerformanceCounter : boolean read FHighPerformanceCounter write FHighPerformanceCounter;
      // sets the pause-state, time doesnt elapse while paused
      property Pause : boolean read FPaused write SetPause;
      /// <summary> Timedifference between the last two TickTacks. </summary>
      property ZDiff : Single read FZDiff write FZDiff;
      /// <summary> Clock that is used to read timestamps.</summary>
      property ClockType : EnumClockType read GetClockType;
      /// <summary> Set initial values </summary>
      constructor Create;
      // in jeden Frame aufrufen
      procedure TickTack;
      /// <summary> Returns the Ticks per sec.</summary>
      function GetFrequency : int64;
      /// <summary> Returns current timeticks, value depends on QueryPerformanceCounterFrequency.</summary>
      function GetTimeTick : int64;
      /// <summary> Returns current time since program start in milliseconds.</summary>
      function GetTimeStamp : int64;
      /// <summary> Returns current time since program start in milliseconds.</summary>
      function GetFloatingTimestamp : double;
      /// <summary> Returns current timestamp in seconds. </summary>
      function FloatingTimestampSeconds : double;
      class procedure Initialize;
  end;

  TTimeMeasurement = class
    protected
      type
      TSubmeasurement = class
        protected
          FTimeStamp : int64;
          FDescription : string;
        public
          constructor Create(Description : string);
      end;

      TMeasurement = class
        protected
          FStartTime, FEndTime : int64;
          FStopped : boolean;
          FSubMeasurments : TObjectList<TSubmeasurement>;
        public
          property Stopped : boolean read FStopped;
          constructor Start;
          procedure Stop;
          function GetTimeElapsed : int64;
          destructor Destroy; override;
      end;

      TMeasurementSeries = class
        protected
          FMeasurements : TObjectList<TMeasurement>;
          FKey, FDescription : string;
        public
          constructor Create(Key : string; Description : string);
          procedure Start;
          procedure Stop;
          function GetResult : string;
          destructor Destroy; override;
      end;

    protected
      class var FActive : boolean;
      class var FMainMeasurements : TObjectDictionary<string, TMeasurementSeries>;
      class var FOutputFileName : string;
      class procedure Initialize;
      class procedure Finalize;
      class procedure OutputFile;
    public
      /// <summary> Activate the timemeasurement and display results at the termination of programm.</summary>
      class procedure Activate;
      /// <summary> Set a customfile for measurment results.</summary>
      class procedure SetOutputeFile(Filename : string);
      class procedure StartMainMeasurement(Key : string; Description : string = '');
      class procedure NewSubMeasurement(MainKey : string; SubMeasurementDescription : string);
      class procedure StopMainMeasurement(Key : string);
  end;

  /// <summary> Class helper for TStream. Extends stream for read and write some ordinary types.</summary>
  TStreamHelper = class helper for TStream
    procedure WriteByte(Value : Byte);
    procedure WriteString(Value : string);
    procedure WriteCardinal(Value : Cardinal);
    procedure WriteAny<T>(Value : T);
    /// <summary> Skippes n (=length) bytes in stream. Will set position to position + Length</summary>
    procedure Skip(Length : int64);
    function ReadInteger : Integer;
    function ReadSmallInt : SmallInt;
    function ReadWord : Word;
    function ReadByte : Byte;
    function ReadString : string;
    function ReadCardinal : Cardinal;
    function ReadBoolean : boolean;
    function ReadAny<T> : T;
    /// <summary> Return an array containing ArrayLength count elements with sizeOf(T)</summary>
    function ReadArray<T>(ArrayLength : Cardinal) : TArray<T>;
    function EoF : boolean;
  end;

  TValueHelper = record helper for TValue
    function IsFloat : boolean;
    function IsString : boolean;
    function IsNumeric : boolean;
    function IsInteger : boolean;
    function IsOrdinalOrSet : boolean;
    function IsSet : boolean;
    function AsSet : SetByte;
    function IsRecord : boolean;
    function GetRttiType : TRttiType;
    function GetTypeName : string;
    /// <summary> Returns an array that contains any items that the value contains, if value is array,
    /// else it will contain self.</summary>
    function ToArray : TArray<TValue>; overload;
    function ToArray<T> : TArray<T>; overload;
    /// <summary> Resolves the path to a field/property/method and return the assigned value (field/property)
    /// or call the method and return the returnvalue. If method is a procedure, returnvalue will be empty.
    /// <param name="Path"> Path to a field/property/member. Example: Childs.first.name
    /// To pass parameter, path has to contains a parameter data and parameter has to pass to parameter Params.
    /// The name of the parameter data is irrelevant, because the parameter data is only a placeholder to assign
    /// parameter to correct item
    /// Example GetChild(i).name; Params = [10].
    /// For passing multiple parameters on different subinstances, path simply contains multiple paramter data
    /// Example: GetItem(i, j).GetColorChannel(channel).AsSingle; Params=[1, 20, 'red']
    /// Also Indexed properties/array access is supported
    /// Example: matrix.items[i, j]; Params = [2, 0] </param>
    /// <param name="StrongeParameterMatching"> If Value is false, the indicated parametercount for an method can be greater
    /// than the real parametercount of method is. Parameter will anyway consumed.</param></summary>
    function Resolve(const Path : string; Params : array of TValue; StrongParameterMatching : boolean = True) : TValue;
    procedure Assign(const Path : string; const Value : TValue; Params : array of TValue; StrongParameterMatching : boolean = True);
    /// <summary> Returns a simple (no deep crawling of datastructure) hashvalue for data. E.g. for a TObject this based on
    /// pointer address.</summary>
    function GetSimpleHashValue : Integer;
    /// <summary> Returns True if both content of both values are identical, else false. Comparing method depends on
    /// type, if types can't compared, like string and TObject, an exception is raised.
    /// If CaseInsensitive is True, case will ignored for string comparison.</summary>
    function SameValue(const AnotherValue : TValue; CaseInsensitive : boolean = False) : boolean;
    function CompareValue(const AnotherValue : TValue) : Integer;
    /// <summary> Returns True, if Value (self) contains AValue. Various types are supported and use various methods
    /// to test contains.</summary>
    function Contains(const AValue : TValue; CaseInsensitive : boolean = False) : boolean;
    /// <summary> Returns the intersection of the two values interpreted as set. If both values are not sets, an exception is raised.</summary>
    function Intersect(const SetValue : TValue) : TValue;
    /// <summary> Returns the product of the two values. Only supports numeric values. If both values integer types,
    /// return type will be also an integer type.</summary>
    function Multiply(const AnotherValue : TValue) : TValue;
    /// <summary> Returns the quotient of the two values. Only supports numeric values. Will always return floating type.</summary>
    function Divide(const AnotherValue : TValue) : TValue;
    /// <summary> Returns the sum of the two values. Only supports numeric values. If both values integer types,
    /// return type will be also an integer type.</summary>
    function Add(const AnotherValue : TValue) : TValue;
    /// <summary> Returns the difference of the two values. Only supports numeric values. If both values integer types,
    /// return type will be also an integer type.</summary>
    function Subtract(const AnotherValue : TValue) : TValue;
  end;

  TFormHelper = class helper for TForm
    private
      procedure SetStayOnTop(const Value : boolean);
    public
      property StayOnTop : boolean write SetStayOnTop;
  end;

  TBooleanHelper = record helper for
    boolean
    function ToString : string;
  end;

  TCardinalHelper = record helper for Cardinal
    function ToString : string;
  end;

  TPointerHelper = record helper for Pointer
    function ToString : string;
  end;

  TControlHelper = class helper for TControl
    /// <summary> Remove from all components owned by this component.</summary>
    procedure RemoveAllComponents(FreeComponents : boolean = True);
  end;

  /// <summary> Callback method for event.</summary>
  /// <param name="Eventname"> Event with name has occured</param>
  /// <param name="Eventparameters"> Parameter for event. Type is variable</param>
  /// <param name="Pass"> Default value is true. If Value is changed to false, no other
  /// registered method will be called after this.</param>
  PEvent<T> = procedure(Eventname : T; Eventparameters : array of RParam; Pass : PBoolean) of object;

  /// <summary> An eventsystem, which calls all registered callbacks to a given Event. </summary>
  TEventManager<T> = class
    protected
      FComparer : IComparer<T>;
      FCallbacks : TObjectDictionary<T, TList<PEvent<T>>>;
    public
      constructor Create;
      /// <summary> Register the procedure to be called, if the event is set. If Eventname = '' then registered to all events. </summary>
      procedure Subscribe(Eventname : T; proc : PEvent<T>);
      /// <summary> Deregister the procedure. </summary>
      procedure UnSubscribe(Eventname : T; proc : PEvent<T>);
      /// <summary> Set an event, so all registered callbacks are called immediately. </summary>
      procedure SetEvent(Eventname : T; Eventparameters : array of RParam);
      destructor Destroy; override;
  end;

  /// <summary> Callback method for event.</summary>
  /// <param name="Eventname"> Event with name has occured</param>
  /// <param name="Eventparameters"> Parameter for event. Type is variable</param>
  /// <param name="Pass"> Default value is true. If Value is changed to false, no other
  /// registered method will be called after this.</param>
  PEventWithSender<T, U> = procedure(Eventname : T; const Sender : U; const Eventparameters : array of RParam; var Pass : boolean) of object;

  /// <summary> An eventsystem, which calls all registered callbacks to a given Event. </summary>
  TEventManagerWithSender<T, U> = class
    protected
      FComparer : IComparer<T>;
      FCallbacks : TObjectDictionary<T, TList<PEventWithSender<T, U>>>;
    public
      constructor Create;
      /// <summary> Register the procedure to be called, if the event is set. If Eventname = '' then registered to all events. </summary>
      procedure Subscribe(Eventname : T; proc : PEventWithSender<T, U>);
      /// <summary> Deregister the procedure. </summary>
      procedure UnSubscribe(Eventname : T; proc : PEventWithSender<T, U>);
      /// <summary> Set an event, so all registered callbacks are called immediately. </summary>
      procedure SetEvent(Eventname : T; const Sender : U; const Eventparameters : array of RParam);
      destructor Destroy; override;
  end;

  /// <summary> Computes the frames per second. </summary>
  TFPSCounter = class
    protected const
      FRAMES_LIMITER_INFLUENCING = 15; // number of frames incluencing the limitation of frames
    protected
      FCurrentTimeStart, FOldTimeStart : Cardinal;
      FFrameCount : int64;
      FCurrentFPS, FFPSCounter : Integer;
      FTimeKey : Single;
      FLastSleep : double;
      FLastFrameTimestamps : array [0 .. FRAMES_LIMITER_INFLUENCING - 1] of int64;
      FFrameLimit : Integer;
      FTimeManager : TTimeManager;
      procedure LimitFrameRate();
    public
      property FrameLimit : Integer read FFrameLimit write FFrameLimit;
      /// <summary> Increased on every frame (by FrameTick) and so mark every frame
      /// with unique increasing number.</summary>
      property FrameCount : int64 read FFrameCount;
      /// <summary> FrameLimit = 0 => unlimited,
      /// if TimeManager not assigned, default TimeManager is used.</summary>
      constructor Create(FrameLimit : Integer = 0; TimeManager : TTimeManager = nil);
      /// <summary> Returns the actual frames per second. </summary>
      function getFPS : Integer;
      /// <summary> Should be called every frame once. Required for correct computation. Also does the limit framerate</summary>
      procedure FrameTick;
  end;

  TObjectWrapper<T> = class
    private
      FValue : T;
    public
      property Value : T read FValue write FValue;
      constructor Create(Value : T);
  end;

  TString = class
    private
      FValue : string;
    public
      property Value : string read FValue write FValue;
      constructor Create(Value : string);
  end;

  TFastStack<T> = class
    private
      FStack : array of T;
      FStackSize : Integer;
    public
      property Size : Integer read FStackSize;
      constructor Create(MaxSize : Integer);
      /// <summary> Pushes a value onto the stack. </summary>
      procedure Push(const Value : T); inline;
      /// <summary> Removes a value from the stack. </summary>
      function Pop() : T; inline;
      /// <summary> Return the topmost value of the stack. </summary>
      function Peek() : T; inline;
      /// <summary> Removes a value from the stack without giving it back. </summary>
      procedure PopRemove; inline;
  end;

  RDataRate = record
    private
      FTimeStamp : Cardinal;
      FDataRate : Integer;
      FDataLength : int64;
      FTimeRate : Cardinal;
    public
      constructor Create(TimeRate : Cardinal);
      procedure AddData(DataLength : int64);
      procedure Compute;
      function GetDataRate : Integer;
  end;

  TProgressEvent = reference to procedure(bytesDownloaded : int64);

  /// <summary> Helper that wraps parts of Lockbox 3 for hashing and RSA encryption. </summary>
  TCryptoHelper = class
    private
      FCryptoLib : TCryptographicLibrary;
      FHash : uTPLb_Hash.THash;
      FSignatory : TSignatory;
      FHasPrivateKey : boolean;
      FHasPublicKey : boolean;
      FOnProgress : TProgressEvent;

      function ReadHasKeys() : boolean;
      function OnHashProgress(Sender : TObject; CountBytesProcessed : int64) : boolean;

    public
      constructor Create();
      destructor Destroy(); override;
      property OnProgress : TProgressEvent read FOnProgress write FOnProgress;
      /// <summary> Indicates whether the helper is ready to sign and verify. For this
      /// RSA keys have to be loaded either by generating them (CryptoHelper.GenerateKeys)
      /// or loading them (TCryptoHelper.LoadPrivateKey and TCryptoHelper.LoadPublicKey).</summary>
      property CanSignAndVerify : boolean read ReadHasKeys;
      /// <summary> Indicates whether the helper is ready to verify files. For this
      /// a public RSA key has to be loaded.</summary>
      property CanVerify : boolean read FHasPublicKey;
      /// <summary> Computes a hash for given string using the algorithm indicated by
      /// hashId (@see uTPLb_Constants unit). Example constants are SHA512_ProgId
      /// and MD5_ProgId.</summary>
      function GetStringHash(Text : string; hashId : string) : string;
      /// <summary> Computes a hash for the content of given file using the algorithm indicated
      /// by hashid (@see uTPLb_Constants unit). Example constants are SHA512_ProgId
      /// and MD5_ProgId.</summary>
      function GetFileHash(Path : string; hashId : string) : string;
      /// <summary> Computes the Base64 encoded MD5 hash of given string.</summary>
      function MD5(Text : string) : string;
      /// <summary> Computes the Base64 encoded MD5 hash of the content of given file.</summary>
      function FileMD5(Path : string) : string;
      /// <summary> Computes the Base64 encoded SHA2-512 hash of the given string.</summary>
      function SHA2(Text : string) : string;
      /// <summary> Computes the Base64 encoded SHA2-512 hash of the content of given file.</summary>
      function FileSHA2(Path : string) : string;
      /// <summary> Generates a new set of random private and public RSA keys that can be
      /// used to sign and verify files. The generated keys can be saved with
      /// the SavePrivateKey() and SavePublicKey() methods.</summary>
      /// <returns>Returns true if the keys could be generated</returns>
      function GenerateKeys() : boolean;

      /// <summary>
      /// Saves a previously generated or loaded private RSA key to the file at path.
      /// Returns true on success. Existing files are overwritten.
      /// </summary>
      procedure SavePrivateKey(Path : string);

      /// <summary>
      /// Saves a previously generated or loaded public RSA key to the file at path.
      /// Returns true on success. Existing files are overwritten.
      /// </summary>
      procedure SavePublicKey(Path : string);

      /// <summary>
      /// Loads a private RSA key for usage with the crypto helper's SignFile()
      /// and VerifyFile() functions. Returns true if the key could be successfully loaded.
      /// </summary>
      function LoadPrivateKey(Path : string) : boolean;

      /// <summary>
      /// Loads a public RSA key for usage with the crypto helper's SignFile()
      /// and VerifyFile() functions. Returns true if the key could be successfully loaded.
      /// </summary>
      function LoadPublicKey(Path : string) : boolean;

      /// <summary>
      /// Creates a signature file at signaturepath signing the file located at
      /// filepath. Uses the currently loaded private key and returns true on success.
      /// Existing files are overwritten.
      /// </summary>
      function SignFile(Filepath : string; signaturepath : string) : boolean;

      /// <summary>
      /// Attempts to verify the file located at filepath using the signature
      /// loaded from signaturepath and the currently loaded public key.
      /// Returns true if the file could be successfully verified.
      /// </summary>
      function VerifyFile(Filepath : string; signaturepath : string) : boolean;

      class function StringToBase64(str : string) : AnsiString;
      class function Base64ToString(base64str : AnsiString) : string;
  end;

  /// <summary>
  /// Helper for Internet downloads
  /// </summary>
  TInternet = class
    private
      FHTTP : TIdHTTP;
      FOnProgress : TProgressEvent;
      FOnTotalSize : TProgressEvent;
      procedure OnWork(ASender : TObject; AWorkMode : TWorkMode; AWorkCount : int64);
      procedure OnWorkBegin(ASender : TObject; AWorkMode : TWorkMode;
        AWorkCount : int64);
    public
      constructor Create();
      destructor Destroy(); override;
      property OnProgress : TProgressEvent read FOnProgress write FOnProgress;
      property OnTotalSize : TProgressEvent read FOnTotalSize write FOnTotalSize;
      /// <summary> Downloads the content of a file located at url and returns them as
      /// a string. If something is getting wrong, it returns ''. </summary>
      function DownloadString(Url : string) : string;
      /// <summary> Downloads the contents of a file located at url and returns a
      /// memory stream. </summary>
      function DownloadStream(Url : string) : TStream;
      /// <summary> Downloads the contents of a file located at url and saves it into
      /// the local file at filePath, creating the file and if necessary its
      /// parent directories. </summary>
      procedure DownloadFile(Url : string; Filepath : string); overload;
      procedure DownloadFile(Url : string; Filepath : string; OnProgress : TProgressEvent); overload;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  EnumInterpolationMethod = (imLinear, imCosinus);

  /// <summary> Metaclass for interpolators. Wraps common tasks for interpolating
  /// between two values over a time intervall. </summary>
  TInterpolator<T> = class abstract
    protected
      FStart, FEnd : T;
      FInterpolationMethod : EnumInterpolationMethod;
      FTimer : TTimer;
      FStopped : boolean;
      /// <summary> Interpolates FStart => FEnd with s and FInterpolationMethod.</summary>
      function Interpolate(s : Single) : T; virtual; abstract;
    public
      property EndValue : T read FEnd;
      /// <summary> Returns whether the interpolator is currently running. </summary>
      function Running : boolean;
      /// <summary> Returns whether the interpolator has stopped since last call of stopped. </summary>
      function Stopped : boolean;
      /// <summary> The current percent of the interpolation in [0,1]. Only valid if running. </summary>
      function CurrentPercent : Single;
      /// <summary> The current value of the interpolation. Only valid if running. </summary>
      function CurrentValue : T;
      constructor Create(InterpolationTime : Integer; InterpolationMethod : EnumInterpolationMethod = imLinear);
      /// <summary> Starts the interpolator. Interval overrides permanently the interpolationtime if <> -1. </summary>
      procedure Start(StartValue, EndValue : T; Interval : Integer = -1);
      destructor Destroy; override;
  end;

  TRVector2Interpolator = class(TInterpolator<RVector2>)
    protected
      function Interpolate(s : Single) : RVector2; override;
  end;

  TRVector3Interpolator = class(TInterpolator<RVector3>)
    protected
      function Interpolate(s : Single) : RVector3; override;
  end;

  /// <summary> Encapsulate all common rttitypes of a class (property, field, member) to one class.
  /// The class conclude all members from the three types to one easy accessible class.</summary>
  TRttiMemberUnified = class
    public type
      EnumMemberType = (mtProperty, mtField, mtMethod);
      SetMemberType = set of EnumMemberType;
    private
      FSourceRttiInfo : TRttiMember;
      FMemberType : EnumMemberType;
      function GetName : string;
      function GetType : TRttiType;
      procedure ExpectType(MemberType : EnumMemberType); overload;
      procedure ExpectType(MemberTypes : SetMemberType); overload;
    public
      property MemberType : TRttiType read GetType;
      property name : string read GetName;
      function GetValue(const Instance : TValue) : TValue;
      function GetValueFromRawPointer(const Instance : Pointer) : TValue;
      procedure SetValue(const Instance : TValue; const AValue : TValue);
      procedure SetValueToRawPointer(const Instance : Pointer; const AValue : TValue);
      function GetAttributes : TArray<TCustomAttribute>;
      function HasAttribute<a : TCustomAttribute>(out AttributeInstance : a) : boolean; overload;
      function HasAttributeOfClass(SearchFor : ClassOfCustomAttribute) : boolean; overload;
      function Invoke(const Instance : Pointer; const Args : array of TValue) : TValue;
      /// <summary> Create TRttiFieldPropertyUnified from property.</summary>
      constructor Create(SourceRttiInfo : TRttiProperty); overload;
      /// <summary> Create TRttiFieldPropertyUnified from field.</summary>
      constructor Create(SourceRttiInfo : TRttiField); overload;
      /// <summary> Create TRttiUnified from Method</summary>
      constructor Create(SourceRttiInfo : TRttiMethod); overload;
      constructor Create(SourceRttiInfo : TRttiMember); overload;
  end;

const
  SHIL_LARGE             = $00; // The image size is normally 32x32 pixels. However, if the Use large icons option is selected from the Effects section of the Appearance tab in Display Properties, the image is 48x48 pixels.
  SHIL_SMALL             = $01; // These images are the Shell standard small icon size of 16x16, but the size can be customized by the user.
  SHIL_EXTRALARGE        = $02; // These images are the Shell standard extra-large icon size. This is typically 48x48, but the size can be customized by the user.
  SHIL_SYSSMALL          = $03; // These images are the size specified by GetSystemMetrics called with SM_CXSMICON and GetSystemMetrics called with SM_CYSMICON.
  SHIL_JUMBO             = $04; // Windows Vista and later. The image is normally 256x256 pixels.
  IID_IImageList : TGUID = '{46EB5926-582E-4017-9FDF-E8998DAA0950}';

var
  ConstToVarHelfer : Byte;
  ContentManager : TContentManager;
  TimeManager : TTimeManager;

function LoescheDoppelSlash(str : string) : string;

// MD5 Checksummen

function MD5(const Text : string) : string; overload;
function MD5(const Stream : TStream) : string; overload;
function MD5(const Bytes : TBytes) : string; overload;
function MD5(const Memory : Pointer; DataLength : Integer) : string; overload;

function LöscheZeichen(Zeichen : char; str : string) : string;
function AnzahlZeichen(Zeichen : char; str : string) : Integer;
/// <summary>  Erzeugt einen String mit Anzahl oft dem Zeichen
/// Bsp: ZeichenGenerieren('*',4) = '****' </summary>
function ZeichenGenerieren(Zeichen : string; Anzahl : Integer) : string;
function Split(str, splitstr : string) : TStringList;

// Format file byte size
function FormatByteSize(const Bytes : int64) : string;

function ReadFileInString(Filename : string) : string;

function SecToTime(Sec : Integer) : string;

function GUIDToRawByte(const GUID : TGUID) : RawByteString;

/// <summary> Swap byteorder of a 32 bit value.</summary>
function Swap32(Value : LongWord) : LongWord;
/// <summary> Swap byteorder of a 64 bit value.</summary>
function Swap64(Value : UInt64) : UInt64;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

function Swap32(Value : LongWord) : LongWord;
type
  Bytes = packed array [0 .. 3] of Byte;
begin
  Bytes(Result)[0] := Bytes(Value)[3];
  Bytes(Result)[1] := Bytes(Value)[2];
  Bytes(Result)[2] := Bytes(Value)[1];
  Bytes(Result)[3] := Bytes(Value)[0];
end;

function Swap64(Value : UInt64) : UInt64;
begin
  Result := Swap(LongWord(Value));
  Result := (Result shl 32) or Swap32(LongWord(Value shr 32));
end;

const
  Base64Codes : AnsiString = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/';

function EncodeBase64(s : AnsiString) : AnsiString;
var
  i : Integer;
  a : Integer;
  X : Integer;
  b : Integer;
begin
  Result := '';
  a := 0;
  b := 0;
  for i := 1 to Length(s) do
  begin
    X := Ord(s[i]);
    b := b * 256 + X;
    a := a + 8;
    while a >= 6 do
    begin
      a := a - 6;
      X := b div (1 shl a);
      b := b mod (1 shl a);
      Result := Result + Base64Codes[X + 1];
    end;
  end;
  if a > 0 then
  begin
    X := b shl (6 - a);
    Result := Result + Base64Codes[X + 1];
  end;
end;

function DecodeBase64(s : AnsiString) : AnsiString;
var
  i : Integer;
  a : Integer;
  X : Integer;
  b : Integer;
begin
  Result := '';
  a := 0;
  b := 0;
  for i := 1 to Length(s) do
  begin
    X := Pos(s[i], Base64Codes) - 1;
    if X >= 0 then
    begin
      b := b * 64 + X;
      a := a + 6;
      if a >= 8 then
      begin
        a := a - 8;
        X := b shr a;
        b := b mod (1 shl a);
        X := X mod 256;
        Result := Result + AnsiChar(chr(X));
      end;
    end
    else
        Exit;
  end;
end;

function GUIDToRawByte(const GUID : TGUID) : RawByteString;
begin
  SetLength(Result, 16);
  PCardinal(@Result[1])^ := GUID.D1;
end;

function EncodeBase16(const Data : TBytes) : string;
var
  Text : PWideChar;
begin
  SetLength(Result, Length(Data) * 2);
  Text := @Result[1];
  BinToHex(Data, Text, Length(Data));
end;

function TrimLeft(s : string; chars : array of char) : string;
var
  i : Integer;
  eat : boolean;
  c : Integer;
begin
  for i := 1 to Length(s) do
  begin
    eat := False;
    for c := 0 to Length(chars) - 1 do
      if eat or (chars[c] = s[i]) then eat := True;

    if eat then Continue;
    Exit(Copy(s, i, Length(s) - (i - 1)));
  end;
end;

function AddInteger(a, b : Integer) : Integer;
begin
  Result := a + b;
end;

function SetToCardinal(const aSet; const Size : Cardinal) : Cardinal;
begin
  Result := 0;
  Move(aSet, Result, Size);
  Result := Result shr 1;
end;

procedure CardinalToSet(const Value : Cardinal; var aSet; const Size : Cardinal);
begin
  Move(Value, aSet, Size);
end;

function SecToTime(Sec : Integer) : string;
var
  H, M, s : string;
  ZH, ZM, ZS : Integer;
begin
  ZH := Sec div 3600;
  ZM := Sec div 60 - ZH * 60;
  ZS := Sec - (ZH * 3600 + ZM * 60);
  H := HGeneric.TertOp<string>(ZH > 0, HString.IntMitNull(ZH) + 'h ', '');
  M := HGeneric.TertOp<string>(ZM > 0, HString.IntMitNull(ZM) + 'm ', '');
  s := HGeneric.TertOp<string>(ZS > 0, HString.IntMitNull(ZS) + 's', '');
  Result := H + M + s;
end;

function ReadFileInString(Filename : string) : string;
var
  HelperStringList : TStrings;
begin
  HelperStringList := TStringList.Create;
  HelperStringList.LoadFromFile(Filename);
  Result := HelperStringList.Text;
  HelperStringList.Free;
end;

// Format file byte size
function FormatByteSize(const Bytes : int64) : string;
const
  b  = 1;         // byte
  KB = 1024 * b;  // kilobyte
  MB = 1024 * KB; // megabyte
  GB = 1024 * MB; // gigabyte
begin
  if Bytes > GB then
      Result := FormatFloat('#.## GB', Bytes / GB)
  else
    if Bytes > MB then
      Result := FormatFloat('#.## MB', Bytes / MB)
  else
    if Bytes > KB then
      Result := FormatFloat('#.## KB', Bytes / KB)
  else
      Result := FormatFloat('0.## bytes', Bytes);
end;

function LöscheZeichen(Zeichen : char; str : string) : string;
var
  i : Integer;
begin
  Result := '';
  if Length(str) = 0 then Exit;
  for i := 1 to Length(str) do
    if str[i] <> Zeichen then Result := Result + str[i];
end;

function Split(str, splitstr : string) : TStringList;
var
  Index : Integer;
begin
  Result := TStringList.Create;
  index := Pos(splitstr, str);
  while (index >= 1) do
  begin
    Result.Add(Copy(str, 1, index - 1));
    Delete(str, 1, index);
    index := Pos(splitstr, str);
  end;
  Result.Add(str);
end;

function ZeichenGenerieren(Zeichen : string; Anzahl : Integer) : string;
begin
  if Anzahl <= 0 then Result := ''
  else Result := ZeichenGenerieren(Zeichen, Anzahl - 1) + Zeichen;
end;

function AnzahlZeichen(Zeichen : char; str : string) : Integer;
var
  i : Integer;
begin
  Result := 0;
  for i := 1 to Length(str) do
    if str[i] = Zeichen then inc(Result);
end;

function MD5(const Stream : TStream) : string;
var
  idmd5 : TIdHashMessageDigest5;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  try
    Result := idmd5.HashStreamAsHex(Stream);
  finally
    idmd5.Free;
  end;
end;

function MD5(const Text : string) : string;
var
  idmd5 : TIdHashMessageDigest5;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  try
    Result := idmd5.HashStringAsHex(Text);
  finally
    idmd5.Free;
  end;
end;

function MD5(const Bytes : TBytes) : string;
var
  idmd5 : TIdHashMessageDigest5;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  try
    Result := idmd5.HashBytesAsHex(TIdbytes(Bytes));
  finally
    idmd5.Free;
  end;
end;

function MD5(const Memory : Pointer; DataLength : Integer) : string; overload;
var
  Stream : TStream;
begin
  Stream := TMemoryStream.Create;
  Stream.ReadBuffer(Memory^, DataLength);
  Result := MD5(Stream);
  Stream.Free;
end;

procedure BitmaskeBitLoeschen(var Maske : Cardinal; Bitposition : Byte);
begin
  if BitmaskeBitTesten(Maske, Bitposition) then Maske := Maske xor (1 shl Bitposition)
  else Maske := Maske;
end;

procedure BitmaskeBitSetzen(var Maske : Cardinal; Bitposition : Byte);
begin
  Maske := Maske or (1 shl Bitposition);
end;

function BitmaskeBitTesten(Maske : Cardinal; Bitposition : Byte) : boolean;
begin
  Result := ((Maske and (1 shl Bitposition)) <> 0);
end;

function BitmaskeMaskenVereinen(Maske1, Maske2 : Cardinal) : Cardinal;
begin
  Result := Maske1 or Maske2;
end;

function BitmaskeMaskenSchneiden(Maske1, Maske2 : Cardinal) : Cardinal;
begin
  Result := Maske1 and Maske2;
end;

function Naechste2erPotenz(InWert : Cardinal) : Integer;
var
  i2 : Cardinal;
begin
  Assert(InWert > 0);
  i2 := 1;
  while (i2 < InWert) do
  begin
    i2 := i2 shl 1; // equals to i2 := i2 * 2;
  end;
  Result := i2;
end;

function Log2Aufgerundet(InWert : Cardinal) : Integer;
var
  i2 : Cardinal;
begin
  Assert(InWert > 0);
  Result := 0;
  i2 := 1;
  while (i2 < InWert) do
  begin
    i2 := i2 shl 1;
    inc(Result);
  end;
end;

function SingleToByte(s : Single) : Byte;
begin
  Result := Min(255, Max(0, Round(s * 255)));
end;

function CardinalToObject(Value : Cardinal) : TObject;
begin
  Result := TObject(Pointer(Value));
end;

function ObjectToCardinal(Objekt : TObject) : Cardinal;
begin
  Result := Cardinal(Pointer(Objekt));
end;

function IntToObject(Value : Integer) : TObject;
begin
  Result := TObject(Pointer(Value));
end;

function ObjectToInt(Objekt : TObject) : Integer;
begin
  Result := Integer(Pointer(Objekt));
end;

function CardinalToString(Value : Cardinal) : string;
begin
  SetLength(Result, SizeOf(Cardinal));
  System.Move(Value, Pointer(@Result[1])^, SizeOf(Cardinal));
end;

function StringToCardinal(Value : string) : Cardinal;
begin
  Result := PCardinal(@Value[1])^;
end;

function ObjectToString(Objekt : TObject) : string;
begin
  Result := CardinalToString(ObjectToCardinal(Objekt));
end;

function StringToObject(Value : string) : TObject;
begin
  Result := CardinalToObject(StringToCardinal(Value));
end;

function saturate(Wert : Integer) : Integer;
begin
  Result := Min(255, Max(0, Wert));
end;

function LoescheDoppelSlash(str : string) : string;
begin
  while Pos('\\', str) <> 0 do Delete(str, Pos('\\', str), 1);
  Result := str;
end;

function FormatDateiPfad(Value : string) : string;
begin
  Result := HFilepathManager.RelativeToAbsolute(Value);
end;

function AbsolutePath(Value : string) : string;
begin
  Result := HFilepathManager.RelativeToAbsolute(Value);
end;

function RelativDateiPfad(Value : string) : string;
begin
  Result := HFilepathManager.AbsoluteToRelative(Value);
end;

procedure NOOP;
begin
end;

function DezToHex(Value : Byte) : string;
begin
  if Value < 10 then Result := chr(Ord('0') + Value)
  else Result := chr(Ord('A') + Value - 10);
end;

function DHS2C(_s : Single) : Cardinal; // von Martin Pyka, aus der Bibel (-;
begin
  Result := PCardinal(@_s)^;
end;

{ TTimer }

constructor TTimer.Create;
begin
  SetInterval(1);
end;

function TTimer.Clone : TTimer;
begin
  Result := TTimer.Create;
  Result.FInterval := FInterval;
  Result.FLastTime := FLastTime;
  Result.FPauseTime := FPauseTime;
  Result.FPaused := FPaused;
end;

constructor TTimer.Create(Interval : int64);
begin
  SetInterval(Interval);
end;

constructor TTimer.CreateAndStart(Interval : int64);
begin
  Create(Interval);
  Start;
end;

constructor TTimer.CreatePaused(Interval : int64);
begin
  CreateAndStart(Interval);
  Pause;
end;

procedure TTimer.Delay(DelayMs : Integer);
begin
  FLastTime := FLastTime + DelayMs;
end;

procedure TTimer.Expire;
begin
  Expired := True;
end;

function TTimer.getExpired : boolean;
begin
  if FPaused then Result := FPauseTime >= FInterval
  else Result := GetTimeStamp - FLastTime >= FInterval;
end;

function TTimer.GetTimeStamp : double;
begin
  Result := TimeManager.GetFloatingTimestamp;
end;

function TTimer.HasStarted : boolean;
begin
  Result := FLastTime >= GetTimeStamp;
end;

procedure TTimer.setExpired(const IsExpired : boolean);
const
  EPSILON = 1E-7;
var
  WasPaused : boolean;
begin
  if IsExpired then
  begin
    if FPaused then FPauseTime := FInterval
    else FLastTime := GetTimeStamp - FInterval - EPSILON; // due to rounding errors we go slightly beyond expired
  end
  else
  begin
    WasPaused := FPaused;
    Start;
    if WasPaused then Pause;
  end;
end;

function TTimer.ZeitDiffProzent(ClampZeroOne : boolean) : Single;
begin
  if FInterval = 0 then
      Result := 1
  else
      Result := TimeSinceStart / FInterval;
  if ClampZeroOne then
      Result := EnsureRange(Result, 0, 1);
end;

function TTimer.ZeitDiffProzentInverted(ClampZeroOne : boolean) : Single;
begin
  Result := 1 - ZeitDiffProzent(ClampZeroOne);
end;

procedure TTimer.Start;
begin
  FLastTime := GetTimeStamp;
  FPaused := False;
end;

procedure TTimer.Start(const NewInterval : int64);
begin
  Interval := NewInterval;
  Start;
end;

procedure TTimer.StartAndPause;
begin
  Start;
  Pause;
end;

procedure TTimer.StartWithRest;
begin
  FLastTime := GetTimeStamp - Round((Min(0, trunc(ZeitDiffProzent) - 1) + frac(ZeitDiffProzent)) * FInterval);
  FPaused := False;
end;

procedure TTimer.StartWithFrac;
begin
  FLastTime := GetTimeStamp - Round(frac(ZeitDiffProzent) * FInterval);
  FPaused := False;
end;

function TTimer.TimesExpired(Maximum : Integer) : Integer;
begin
  Result := trunc(ZeitDiffProzent);
  if Maximum > 0 then Result := Min(Result, Maximum);
end;

function TTimer.TimeSinceStart : double;
begin
  if FPaused then Result := FPauseTime
  else Result := GetTimeStamp - FLastTime;
  Result := Max(0, Result);
end;

function TTimer.TimeToExpired : Single;
begin
  Result := Max(0, (1 - ZeitDiffProzent) * Interval);
end;

procedure TTimer.Pause;
begin
  FPaused := True;
  FPauseTime := GetTimeStamp - FLastTime;
end;

function TTimer.Progress : Single;
begin
  if FInterval = 0 then Result := 1
  else Result := TimeSinceStart / FInterval;
  Result := EnsureRange(Result, 0, 1);
end;

function TTimer.ProgressInverted : Single;
begin
  Result := 1 - Progress;
end;

procedure TTimer.Reset;
begin
  SetZeitDiffProzent(0);
end;

procedure TTimer.Weiter;
begin
  if FPaused then
  begin
    FPaused := False;
    FLastTime := GetTimeStamp - FPauseTime;
  end;
end;

procedure TTimer.SetInterval(const Interval : int64);
begin
  FInterval := Max(1, Interval);
end;

procedure TTimer.SetIntervalAndStart(Interval : int64);
begin
  SetInterval(Interval);
  Start;
end;

procedure TTimer.setPaused(const IsExpired : boolean);
begin
  if Paused <> IsExpired then
  begin
    if IsExpired then self.Weiter
    else self.Pause;
  end;
end;

procedure TTimer.SetZeitDiffProzent(Wert : Single);
begin
  if Paused then
      FPauseTime := Wert * FInterval
  else
      FLastTime := GetTimeStamp - Wert * FInterval;
end;

{ TTimeManager }

constructor TTimeManager.Create;
begin
  QueryPerformanceFrequency(Frequenz);
  HighPerformanceCounter := Frequenz <> 0;
  if HighPerformanceCounter then
  begin
    // Hochleistungs Zeitgeber
    Zeitskalierung := Frequenz;
    QueryPerformanceCounter(LetzteZeit);
  end
  else
  begin
    // Gettickcountzeitgeber
    LetzteZeit := Gettickcount;
    Frequenz := 1;
    Zeitskalierung := 1000;
  end;
end;

function TTimeManager.GetFrequency : int64;
begin
  Result := Frequenz;
end;

function TTimeManager.GetTimeStamp : int64;
begin
  Result := Round(GetTimeTick * 1000 / Zeitskalierung);
end;

function TTimeManager.GetTimeTick : int64;
begin
  if FPaused then Result := FTimeAtPause + FPauseTime
  else QueryPerformanceCounter(Result);
  Result := Result - FPauseTime - ProgramStart;
end;

class procedure TTimeManager.Initialize;
var
  TimeManager : TTimeManager;
begin
  TimeManager := TTimeManager.Create;
  ProgramStart := TimeManager.GetTimeTick;
  TimeManager.Free;
end;

function TTimeManager.FloatingTimestampSeconds : double;
begin
  Result := GetTimeTick / Zeitskalierung;
end;

function TTimeManager.GetClockType : EnumClockType;
begin
  if HighPerformanceCounter then
      Result := ctHighPerformanceCounter
  else
      Result := ctGetTickCount;
end;

function TTimeManager.GetFloatingTimestamp : double;
begin
  Result := GetTimeTick * 1000 / Zeitskalierung;
end;

procedure TTimeManager.SetPause(const Value : boolean);
begin
  if Value = FPaused then Exit;
  // switch on
  if Value then
  begin
    MomentaneZeit := GetTimeTick;
    LetzteZeit := MomentaneZeit;
    FTimeAtPause := MomentaneZeit;
  end;
  FPaused := Value;
  // switch off
  if not Value then
  begin
    FPauseTime := FPauseTime + (GetTimeTick - FTimeAtPause);
    MomentaneZeit := GetTimeTick;
    LetzteZeit := MomentaneZeit;
  end;
end;

procedure TTimeManager.TickTack;
begin
  // LogikFrameBerechnung
  if HighPerformanceCounter then
  begin
    MomentaneZeit := GetTimeTick;
    FZDiff := ((MomentaneZeit - LetzteZeit) * 1000 / Zeitskalierung);
  end
  else
  begin
    MomentaneZeit := GetTimeTick;
    FZDiff := MomentaneZeit - LetzteZeit;
  end;
  LetzteZeit := MomentaneZeit;
end;

{ HFileIO }

class function HFileIO.AddFileSuffix(Filename, Suffix : string) : string;
begin
  Result := ChangeFileExt(Filename, '') + Suffix + ExtractFileExt(Filename);
end;

class procedure HFileIO.DeleteAllFilesInDirectory(const Path : string);
var
  FileList : TStrings;
  Filename : string;
begin
  FileList := nil;
  FindAllFiles(FileList, Path, '*.*', False);
  for Filename in FileList do
      DeleteFile(Filename);
  FileList.Free;
end;

class procedure HFileIO.EnsureFileExists(Filename : string);
begin
  if not FileExists(Filename) then
      raise EFileNotFoundException.Create('Could''t find file "' + Filename + '".');
end;

class function HFileIO.FileCount(const Directory : string; Recurse : boolean) : Integer;
var
  FileList : TStrings;
begin
  FileList := nil;
  FindAllFiles(FileList, Directory, '*.*', Recurse);
  Result := FileList.Count;
  FileList.Free;
end;

class function HFileIO.FileToMD5Hash(Filename : string) : string;
var
  FileStream : TFileStream;
begin
  FileStream := nil;
  try
    FileStream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
    Result := MD5(FileStream);
  finally
    FileStream.Free;
  end;
end;

class procedure HFileIO.FindAllFiles(var FileList : TStrings; RootFolder, Mask : string; Recurse : boolean; Callback : ProcFindFilesCallback);
var
  SR : TSearchRec;

  // returns True if FindFiles should exit else false
  function CheckCallback() : boolean;
  begin
    Result := False;
    if assigned(Callback) then
        Callback(RootFolder + SR.Name, FileList.Count, Result);
  end;

begin
  RootFolder := IncludeTrailingPathDelimiter(RootFolder);
  if not assigned(FileList) then FileList := TStringList.Create;
  if Recurse then
    if FindFirst(RootFolder + '*.*', faAnyFile, SR) = 0 then
      try
        repeat
          if SR.Attr and faDirectory = faDirectory then
            // --> ein Verzeichnis wurde gefunden
            // der Verzeichnisname steht in SR.Name
            // der vollständige Verzeichnisname (inkl. darüberliegender Pfade) ist
            // RootFolder + SR.Name
            if (SR.Name <> '.') and (SR.Name <> '..') then
            begin
              if CheckCallback() then
                  Exit;
              FindAllFiles(FileList, RootFolder + SR.Name, Mask, Recurse);
            end;
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
  if FindFirst(RootFolder + Mask, faAnyFile, SR) = 0 then
    try
      repeat
        if SR.Attr and faDirectory <> faDirectory then
        begin
          // --> eine Datei wurde gefunden
          // der Dateiname steht in SR.Name
          // der vollständige Dateiname (inkl. Pfadangabe) ist
          // RootFolder + SR.Name
          if CheckCallback() then
              Exit;
          FileList.Add(RootFolder + SR.Name);
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
end;

class function HFileIO.GetFileSize(const Filename : string) : int64;
var
  FileStream : TFileStream;
begin
  FileStream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
  try
    try
      Result := FileStream.Size;
    except
      Result := 0;
    end;
  finally
    FileStream.Free;
  end;
end;

class function HFileIO.GetSubDirectories(const Directory : string) : TStrings;
var
  SR : TSearchRec;
begin
  Result := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(Directory) + '*.*', faDirectory, SR) < 0 then Exit
    else
      repeat
        if ((SR.Attr and faDirectory <> 0) and (SR.Name <> '.') and (SR.Name <> '..')) then Result.Add(IncludeTrailingPathDelimiter(Directory) + SR.Name);
      until FindNext(SR) <> 0;
  finally
    SysUtils.FindClose(SR);
  end;
end;

class function HFileIO.IsDirectory(DirPath : string) : boolean;
var
  DirEx : Cardinal;
begin
  DirEx := GetFileAttributes(PChar(DirPath));
  if DirEx <> DWord(-1) then
  begin
    Result := (FILE_ATTRIBUTE_DIRECTORY and DirEx) = FILE_ATTRIBUTE_DIRECTORY;
  end
  else Result := False;
end;

class function HFileIO.ReadAllText(const Filepath : string; Encoding : TEncoding) : string;
var
  Stream : TFileStream;
  TextReader : TStreamReader;
begin
  Stream := nil;
  TextReader := nil;
  try
    Stream := TFileStream.Create(Filepath, fmOpenRead or fmShareDenyNone);
    if assigned(Encoding) then
        TextReader := TStreamReader.Create(Stream, Encoding, False)
    else
        TextReader := TStreamReader.Create(Stream);
    Result := TextReader.ReadToEnd;
  finally
    TextReader.Free;
    Stream.Free;
  end;
end;

class function HFileIO.ReadBoolFromIni(Filename, Section, Key : string; Default : boolean) : boolean;
begin
  if not TryReadBoolFromIni(Filename, Section, Key, Result) then Result := default;
end;

class procedure HFileIO.ReadCSV(const Filename : string; CSVCallback : ProcCSVCallback; Delimiter, CommentCharacter : char);
var
  f : TextFile;
  content, line : string;
begin
  try
    AssignFile(f, AbsolutePath(Filename));
    Reset(f);
    content := '';
    while not EoF(f) do
    begin
      readln(f, line);
      content := content + line + sLineBreak;
    end;
  finally
    CloseFile(f);
  end;
  ReadCSVFromString(content, CSVCallback, Delimiter, CommentCharacter);
end;

class procedure HFileIO.ReadCSVFromString(const Filecontent : string; CSVCallback : ProcCSVCallback; Delimiter, CommentCharacter : char);
var
  splitted, lineSplitted : TArray<string>;
  i, i2 : Integer;
  line : string;
begin
  splitted := Filecontent.Split([sLineBreak]);
  for i := 0 to Length(splitted) - 1 do
  begin
    line := splitted[i];
    if line.StartsWith(CommentCharacter) then Continue;
    lineSplitted := line.Split([Delimiter], '"');
    for i2 := 0 to Length(lineSplitted) - 1 do
        lineSplitted[i2] := lineSplitted[i2].DeQuotedString('"');
    CSVCallback(lineSplitted);
  end;
end;

class function HFileIO.ReadFromIni(Filename, Section, Key, Default : string) : string;
begin
  if not TryReadFromIni(Filename, Section, Key, Result) then Result := default;
end;

class function HFileIO.ReadIntFromIni(Filename, Section, Key : string; Default : Integer) : Integer;
begin
  if not TryReadIntFromIni(Filename, Section, Key, Result) then Result := default;
end;

class function HFileIO.ReadSectionsFromIni(Filename : string) : TStrings;
var
  Ini : TIniFile;
begin
  Ini := nil;
  try
    Ini := TIniFile.Create(Filename);
    Result := TStringList.Create;
    Ini.ReadSections(Result);
  finally
    Ini.Free;
  end;
end;

class function HFileIO.TryReadBoolFromIni(Filename, Section, Key : string; out Value : boolean) : boolean;
var
  Ini : TIniFile;
begin
  Ini := nil;
  try
    Ini := TIniFile.Create(Filename);
    Result := Ini.ValueExists(Section, Key);
    if Result then
        Value := Ini.ReadBool(Section, Key, False);
  finally
    Ini.Free;
  end;
end;

class function HFileIO.TryReadFromIni(Filename, Section, Key : string; out Value : string) : boolean;
var
  Ini : TIniFile;
begin
  Ini := nil;
  try
    Ini := TIniFile.Create(Filename);
    Result := Ini.ValueExists(Section, Key);
    if Result then
        Value := Ini.ReadString(Section, Key, '');
  finally
    Ini.Free;
  end;
end;

class function HFileIO.TryReadIntFromIni(Filename, Section, Key : string; out Value : Integer) : boolean;
var
  Ini : TIniFile;
begin
  Ini := nil;
  try
    Ini := TIniFile.Create(Filename);
    Result := Ini.ValueExists(Section, Key);
    if Result then
        Value := Ini.ReadInteger(Section, Key, 0);
  finally
    Ini.Free;
  end;
end;

class procedure HFileIO.WriteToIni(Filename, Section, Key, Value : string);
var
  Ini : TIniFile;
begin
  Ini := nil;
  try
    Ini := TIniFile.Create(Filename);
    Ini.WriteString(Section, Key, Value);
  finally
    Ini.Free;
  end;
end;

{ HSystem }

class function HSystem.CheckIfDirectoryIsWritable(DirectoryPath : string) : boolean;
var
  Filename : string;
begin
  if DirectoryExists(DirectoryPath) then
  begin
    Filename := IncludeTrailingPathDelimiter(DirectoryPath) + 'chk.tmp';
    try
      HString.SaveStringToFile(Filename, 'Test if directory is writable');
      if FileExists(Filename, False) then
      begin
        Result := True;
        DeleteFile(Filename);
      end
      else
          Result := False;
    except
      Result := False;
    end;
  end
  else Result := False;
end;

class destructor HSystem.Destroy;
var
  i : Integer;
begin
  for i := 0 to Length(HSystem.FRegisteredFonts) - 1 do
  begin
    RemoveFontResource(PChar(FRegisteredFonts[i]));
  end;
end;

class function HSystem.ForceForegroundWindow(HWND : THandle) : boolean;
const
  SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
  SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
var
  ForegroundThreadID : DWord;
  ThisThreadID : DWord;
  timeout : DWord;
begin
  if IsIconic(HWND) then ShowWindow(HWND, SW_RESTORE);

  if GetForegroundWindow = HWND then Result := True
  else
  begin
    // Windows 98/2000 doesn't want to foreground a window when some other
    // window has keyboard focus

    if ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 4)) or
      ((Win32Platform = VER_PLATFORM_WIN32_WINDOWS) and
      ((Win32MajorVersion > 4) or ((Win32MajorVersion = 4) and
      (Win32MinorVersion > 0)))) then
    begin
      // Code from Karl E. Peterson, [url]www.mvps.org/vb/sample.htm[/url]
      // Converted to Delphi by Ray Lischner
      // Published in The Delphi Magazine 55, page 16

      Result := False;
      ForegroundThreadID := GetWindowThreadProcessID(GetForegroundWindow, nil);
      ThisThreadID := GetWindowThreadProcessID(HWND, nil);
      if AttachThreadInput(ThisThreadID, ForegroundThreadID, True) then
      begin
        BringWindowToTop(HWND); // IE 5.5 related hack
        SetForegroundWindow(HWND);
        AttachThreadInput(ThisThreadID, ForegroundThreadID, False);
        Result := (GetForegroundWindow = HWND);
      end;
      if not Result then
      begin
        // Code by Daniel P. Stasinski
        SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @timeout, 0);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(0),
          SPIF_SENDCHANGE);
        BringWindowToTop(HWND); // IE 5.5 related hack
        SetForegroundWindow(HWND);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(timeout), SPIF_SENDCHANGE);
      end;
    end
    else
    begin
      BringWindowToTop(HWND); // IE 5.5 related hack
      SetForegroundWindow(HWND);
    end;

    Result := (GetForegroundWindow = HWND);
  end;
end;

class function HSystem.GetAllFileVersionInfo(const Filename : string) : TFileVersionInfo;
var
  Buffer : array of char;
  Infosize : DWord;

  procedure InitVersion;
  begin
    with Result do
    begin
      Infosize := GetFileVersionInfoSize(PChar(Filename), Infosize);
      if Infosize > 0 then
      begin
        SetLength(Buffer, Infosize);
        if not GetFileVersionInfo(PChar(Filename), 0, Infosize, @Buffer[0]) then
            raise Exception.Create('GetAllFileVersionInfo: Error on GetFileVersionInfo.')
      end
      else raise Exception.Create('GetAllFileVersionInfo: Error on GetFileVersionInfoSize.');
    end;
  end;

  function GetVersion(Typ : string) : string;
  var
    temp : string;
    Len : DWord;
    Value : PChar;
  begin
    Result := 'Undefined';
    if Infosize > 0 then
    begin
      SetLength(temp, 200);
      Value := @temp;
      // 04E4 (code-page)
      // English: 0409 (language)
      // German: 0407 (language)
      if VerQueryValue(@Buffer[0], PChar('StringFileInfo\040904E4\' + Typ), Pointer(Value), Len) then
          Result := Value;
    end;
  end;

begin
  ZeroMemory(@Result, SizeOf(TFileVersionInfo));
  Buffer := nil;
  with Result do
  begin
    InitVersion;
    fCompanyName := GetVersion('CompanyName');
    fFileDescription := GetVersion('FileDescription');
    fFileVersion := GetVersion('FileVersion');
    fInternalName := GetVersion('InternalName');
    fLegalCopyRight := GetVersion('LegalCopyRight');
    fLegalTradeMark := GetVersion('LegalTradeMark');
    fOriginalFileName := GetVersion('OriginalFileName');
    fProductName := GetVersion('ProductName');
    fProductVersion := GetVersion('ProductVersion');
    fComments := GetVersion('Comments');
  end;
  Buffer := nil;
end;

class procedure HSystem.GetIconFromFile(const aFile : string; var aIcon : TIcon;
  SHIL_FLAG : Cardinal);
  function GetImageListSH(SHIL_FLAG : Cardinal) : HIMAGELIST;
  type
    _SHGetImageList = function(iImageList : Integer; const riid : TGUID; var ppv : Pointer) : hResult; stdcall;
  var
    Handle : THandle;
    SHGetImageList : _SHGetImageList;
  begin
    Result := 0;
    Handle := LoadLibrary('Shell32.dll');
    if Handle <> S_OK then
      try
        SHGetImageList := GetProcAddress(Handle, PChar(727));
        if assigned(SHGetImageList) and (Win32Platform = VER_PLATFORM_WIN32_NT) then
            SHGetImageList(SHIL_FLAG, IID_IImageList, Pointer(Result));
      finally
        FreeLibrary(Handle);
      end;
  end;

var
  aImgList : HIMAGELIST;
  SFI : TSHFileInfo;
begin
  // Get the index of the imagelist
  SHGetFileInfo(PChar(aFile), FILE_ATTRIBUTE_NORMAL, SFI,
    SizeOf(TSHFileInfo), SHGFI_ICON or SHGFI_LARGEICON or SHGFI_SHELLICONSIZE or
    SHGFI_SYSICONINDEX or SHGFI_TYPENAME or SHGFI_DISPLAYNAME);

  if not assigned(aIcon) then
      aIcon := TIcon.Create;
  // get the imagelist
  aImgList := GetImageListSH(SHIL_FLAG);
  // extract the icon handle
  aIcon.Handle := ImageList_GetIcon(aImgList, Pred(ImageList_GetImageCount(aImgList)), ILD_NORMAL);
end;

class function HSystem.GetKeynameFromScanCode(Scancode : Word) : string;
var
  Key : LongInt;
  KeyName : array [0 .. 99] of char;
  KeyNameLength : Integer;
begin
  Key := Scancode shl 16;
  KeyNameLength := GetKeyNameText(Key, @KeyName[0], 100);
  Assert(KeyNameLength < Length(KeyName));
  if KeyNameLength <= 0 then Result := ''
  else Result := string(KeyName);
end;

class function HSystem.GetLaufwerkeEinesTyps(LaufwerksType : Cardinal) : TStrings;
var
  Drives : array [1 .. 255] of char;
  LWListe : TStringList;
  i : Byte;
  Len : DWord;
begin
  LWListe := TStringList.Create;
  Result := TStringList.Create;
  { Alle Laufwerke ermitteln }
  Len := GetLogicalDriveStrings(255, @Drives);
  for i := 1 to Len - 2 do
    if (i mod 4) = 1 then
        LWListe.Add(Copy(Drives, i, 3));
  { Laufwerke des angegebenen Typs zählen }
  for i := 0 to LWListe.Count - 1 do
  begin
    if GetDriveType(PChar(LWListe[i])) = LaufwerksType then
    begin
      Result.Add(Copy(LWListe[i], 1, 2))
    end;
  end;
  LWListe.Free;
end;

class procedure HSystem.LaufwerkÖffnen(ADriveChar : char; AOpen : boolean);
const
  OpenStr : array [False .. True] of string = ('closed', 'open');
begin
  if mciSendString(PChar('open ' + ADriveChar + ': type cdaudio alias cdlw'), nil, 0, 0) = 0 then
  begin
    mciSendString(PChar('set cdlw door ' + OpenStr[AOpen] + ' wait'), nil, 0, 0);
    mciSendString('close cdlw', nil, 0, 0);
  end;
end;

class function HSystem.MediumInLaufwerk(const ADrive : char) : boolean;
var
  ErrorMode : Word;
begin
  ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
  try
    Result := (DiskSize(Ord(UpperCase(ADrive)[1]) - 64) > -1);
  finally
    SetErrorMode(ErrorMode);
  end;
end;

class function HSystem.MemoryReserved : Cardinal;
var
  st : TMemoryManagerState;
  sb : TSmallBlockTypeState;
begin
  GetMemoryManagerState(st);
  Result := st.ReservedMediumBlockAddressSpace + st.ReservedMediumBlockAddressSpace;
  for sb in st.SmallBlockTypeStates do
  begin
    Result := Result + sb.ReservedAddressSpace;
  end;
end;

class function HSystem.MemoryUsed : Cardinal;
var
  st : TMemoryManagerState;
  sb : TSmallBlockTypeState;
begin
  GetMemoryManagerState(st);
  Result := st.TotalAllocatedMediumBlockSize + st.TotalAllocatedLargeBlockSize;
  for sb in st.SmallBlockTypeStates do
  begin
    Result := Result + sb.UseableBlockSize * sb.AllocatedBlockCount;
  end;
end;

class procedure HSystem.OpenUrlInBrowser(const Url : string);
begin
  ShellExecute(Application.Handle, 'open', PChar(Url), nil, nil, sw_ShowNormal);
end;

class procedure HSystem.PlayWave(const Filename : string; Loop : boolean = False);
var
  Options : Cardinal;
begin
  Options := SND_ASYNC or SND_FILENAME;
  if Loop then Options := Options or SND_LOOP;
  Winapi.mmSystem.PlaySound(PChar(AbsolutePath(Filename)), 0, Options);
end;

class procedure HSystem.RegisterFontFromFile(const Resourcepath : string);
begin
  AddFontResourceEx(PChar(Resourcepath), FR_PRIVATE, nil);
  // AddFontResource(PChar(Resourcepath));
  HArray.Push<string>(FRegisteredFonts, Resourcepath);
  SendMessage(Application.Handle, WM_FONTCHANGE, 0, 0);
end;

class procedure HSystem.RegisterFontFromResource(Resource : Integer);
var
  Stream : TResourceStream;
  FontCount : Cardinal;
begin
  Stream := TResourceStream.CreateFromID(HInstance, Resource, RT_FONT);
  FontCount := 1;
  AddFontMemResourceEx(Stream.Memory, Stream.Size, nil, @FontCount);
  SendMessage(Application.Handle, WM_FONTCHANGE, 0, 0);
  Stream.Free;
end;

class procedure HSystem.Shutdown(const TimeToShutdown : int64);
var
  a : string;
begin
  a := 'cmd /C shutdown /s /f /t ' + IntToStr(TimeToShutdown);
  ShellExecute(Application.Handle, nil, PChar('cmd.exe'), PChar(a), nil, SW_SHOWNOACTIVATE);
end;

class procedure HSystem.ShutdownAbort;
var
  a : string;
begin
  a := 'cmd /C shutdown /a';
  ShellExecute(Application.Handle, nil, PChar('cmd.exe'), PChar(a), nil, SW_SHOWNOACTIVATE);
end;

class procedure HSystem.StopPlayWave;
begin
  Winapi.mmSystem.PlaySound(nil, 0, SND_ASYNC);
end;

class function HSystem.TryParseRect(const RectString : string; out Rect : TRect) : boolean;
var
  Split : TArray<string>;
  tWidth, tHeight, tLeft, tTop : Integer;
begin
  Split := RectString.Split(['x']);
  Result := (Length(Split) = 4) and TryStrToInt(Split[0], tLeft) and TryStrToInt(Split[1], tTop) and TryStrToInt(Split[2], tWidth) and TryStrToInt(Split[3], tHeight);
  // only if all checks passes, the out values are written, so no single value changes if invalid resolution string
  if Result then
      Rect := TRect.Create(tLeft, tTop, tLeft + tWidth, tTop + tHeight);
end;

class function HSystem.TryParseResolution(const Resolution : string; out Width, Height : Integer) : boolean;
var
  Split : TArray<string>;
  tWidth, tHeight : Integer;
begin
  Split := Resolution.Split(['x']);
  Result := (Length(Split) = 2) and TryStrToInt(Split[0], tWidth) and TryStrToInt(Split[1], tHeight);
  // only if all checks passes, the out values are written, so no single value changes if invalid resolution string
  if Result then
  begin
    Width := tWidth;
    Height := tHeight;
  end;
end;

{ HString }

class function HString.BreakCamelCase(str : string) : string;
var
  Last : char;
  i : Integer;
begin
  Result := '';
  if Length(str) <= 0 then Exit;
  Result := Result + str[1];
  Last := str[1];
  for i := 2 to Length(str) do
  begin
    if (Last <> ' ') and (str[i] = UpCase(str[i])) then Result := Result + ' ' + str[i]
    else Result := Result + str[i];
    Last := str[i];
  end;
end;

class function HString.CharArrayToString(inArray : array of char) : string;
var
  i : Integer;
begin
  Result := '';
  for i := 0 to Length(inArray) - 1 do
  begin
    if inArray[i] = #0 then break;
    Result := Result + inArray[i];
  end;
end;

class function HString.AnsiCharArrayToString(inArray : array of AnsiChar) : string;
var
  i : Integer;
begin
  Result := '';
  for i := 0 to Length(inArray) - 1 do
  begin
    if inArray[i] = #0 then break;
    Result := Result + char(inArray[i]);
  end;
end;

class function HString.ContainsString(const Strings : array of string; str : string; IgnoreCase : boolean) : boolean;
var
  i : Integer;
begin
  Result := False;
  for i := 0 to Length(Strings) - 1 do
    if (IgnoreCase and SameText(Strings[i], str)) or (not IgnoreCase and (Strings[i] = str)) then Exit(True);
end;

class function HString.ContainsSubstring(const Substrings : array of string; const str : string; CaseSensitive : boolean) : boolean;
var
  i : Integer;
  Substring, AString : string;
begin
  Result := False;
  if CaseSensitive then AString := str
  else AString := str.ToLowerInvariant;
  for i := 0 to Length(Substrings) - 1 do
  begin
    if CaseSensitive then Substring := Substrings[i]
    else Substring := Substrings[i].ToLowerInvariant;
    if AString.Contains(Substring) then
        Exit(True);
  end;
end;

class function HString.Count(Substring, Text : string) : Integer;
var
  Offset : Integer;
begin
  Result := 0;
  Offset := PosEx(Substring, Text, 1);
  while Offset <> 0 do
  begin
    inc(Result);
    Offset := PosEx(Substring, Text, Offset + Length(Substring));
  end;
end;

class function HString.DeleteDoubles(DoubledChar : char; str : string) : string;
var
  double : string;
  position : Integer;
begin
  double := DoubledChar + DoubledChar;
  position := Pos(double, str);
  while position > 0 do
  begin
    Delete(str, position, 1);
    position := Pos(double, str);
  end;
  Result := str;
end;

class function HString.DeleteDoubleSpaces(str : string) : string;
var
  i : Integer;
  eat : boolean;
begin
  eat := False;
  Result := '';
  for i := 1 to Length(str) do
  begin
    if str[i] <> ' ' then eat := False;
    if not eat then Result := Result + str[i];
    if str[i] = ' ' then eat := True;
  end;
end;

class function HString.TrimBoth(Character : char; str : string) : string;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length(str) do
    if str[i] <> Character then
    begin
      Result := Copy(str, i, Length(str) - i + 1);
      break;
    end;
  for i := Length(Result) downto 1 do
    if Result[i] <> Character then
    begin
      Result := Copy(Result, 1, i);
      break;
    end;
end;

class function HString.ExtrahiereGemeinsamenString(Str1, Str2 : string) : string;
var
  i : Integer;
begin
  i := 1;
  Result := '';
  while Str1[i] = Str2[i] do
  begin
    Result := Result + Str1[i];
    inc(i);
  end;
end;

class function HString.Indent(const Text, Indenter : string) : string;
begin
  Result := Indenter + HString.Join(HString.Split(Text, [sLineBreak]), sLineBreak + Indenter)
end;

class function HString.IntMitNull(const Value : Integer; Digits : Integer) : string;
begin
  Result := IntToStr(Value);
  if Length(Result) < Digits then
      Result := GenerateChars('0', Digits - Length(Result)) + Result;
end;

class function HString.IntToLongTime(Ticks : Integer; TruncOverflow : boolean) : string;
var
  Minutes, Hours : Integer;
begin
  Ticks := Max(0, Ticks);
  Minutes := (Ticks div 60) mod 60;
  Hours := Ticks div 3600;
  if TruncOverflow then
      Hours := Min(Hours, 99);
  Result := Format('%.2d:%.2d', [Hours, Minutes]);
end;

class function HString.IntToLongTimeDetail(Ticks : Integer; TruncOverflow : boolean) : string;
var
  Minutes, Hours, Seconds : Integer;
begin
  Ticks := Max(0, Ticks);
  Seconds := Ticks mod 60;
  Minutes := (Ticks div 60) mod 60;
  Hours := Ticks div 3600;
  if TruncOverflow then
      Hours := Min(Hours, 99);
  Result := Format('%.2d:%.2d:%.2d', [Hours, Minutes, Seconds]);
end;

class function HString.IntToRomanNumeral(Value : Integer) : string;
var
  RomanDict : TArray<RTuple<string, Integer>>;
  i, Matches : Integer;
begin
  Result := '';
  // algorithm from http://stackoverflow.com/questions/12967896/converting-integers-to-roman-numerals-java
  SetLength(RomanDict, 13);
  RomanDict[0] := RTuple<string, Integer>.Create('M', 1000);
  RomanDict[1] := RTuple<string, Integer>.Create('CM', 900);
  RomanDict[2] := RTuple<string, Integer>.Create('D', 500);
  RomanDict[3] := RTuple<string, Integer>.Create('CD', 400);
  RomanDict[4] := RTuple<string, Integer>.Create('C', 100);
  RomanDict[5] := RTuple<string, Integer>.Create('XC', 90);
  RomanDict[6] := RTuple<string, Integer>.Create('L', 50);
  RomanDict[7] := RTuple<string, Integer>.Create('XL', 40);
  RomanDict[8] := RTuple<string, Integer>.Create('X', 10);
  RomanDict[9] := RTuple<string, Integer>.Create('IX', 9);
  RomanDict[10] := RTuple<string, Integer>.Create('V', 5);
  RomanDict[11] := RTuple<string, Integer>.Create('IV', 4);
  RomanDict[12] := RTuple<string, Integer>.Create('I', 1);
  for i := 0 to Length(RomanDict) - 1 do
  begin
    Matches := Value div RomanDict[i].b;
    Result := Result + HString.GenerateChars(RomanDict[i].a, Matches);
    Value := Value mod RomanDict[i].b;
  end;
end;

class function HString.IntToStr(int, FixedLength : Integer; AddThousandSeparator : char) : string;
var
  res : string;
  i : Integer;
begin
  Result := SysUtils.IntToStr(int);
  if (FixedLength > 0) and (Length(Result) < FixedLength) then
  begin
    Result := HString.GenerateChars('0', FixedLength - Length(Result)) + Result;
  end;
  if AddThousandSeparator <> #0 then
  begin
    res := '';
    for i := HGeneric.TertOp<Integer>(int < 0, 2, 1) to Length(Result) do
    begin
      if ((Length(Result) - i + 1) mod 3 = 0) and (i <> 1) and (i <> Length(Result)) then res := res + AddThousandSeparator;
      res := res + Result[i];
    end;
    Result := res;
    if int < 0 then Result := '-' + Result;
  end;
end;

class function HString.IntToStrBandwidth(Bytes : UInt64; Decimals : Integer; ForceUnit : string) : string;
const
  UNIT_IDENTIFIER : array [0 .. 6] of string = ('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB');
var
  id : Integer;
  BytesFloat : double;
begin
  id := 0;
  BytesFloat := Bytes;
  while ((BytesFloat >= 1024.0) and (id < high(UNIT_IDENTIFIER))) and ((id < high(UNIT_IDENTIFIER)) and not SameText(ForceUnit, UNIT_IDENTIFIER[id])) do
  begin
    inc(id);
    BytesFloat := BytesFloat / 1024.0;
  end;
  Result := FloatToStrF(BytesFloat, ffFixed, 15, Decimals) + ' ' + UNIT_IDENTIFIER[id];
end;

class function HString.IntToTime(Ticks : Integer; TruncOverflow : boolean) : string;
var
  Seconds, Minutes : Integer;
begin
  Ticks := Max(0, Ticks);
  Seconds := Ticks mod 60;
  Minutes := Ticks div 60;
  if TruncOverflow then
      Minutes := Min(Minutes, 99);
  Result := Format('%.2d:%.2d', [Minutes, Seconds]);
end;

class function HString.Join(const Values : TArray<string>; const Joiner : string) : string;
var
  i : Integer;
begin
  Result := '';
  for i := 0 to Length(Values) - 1 do
    if i <> Length(Values) - 1 then Result := Result + Values[i] + Joiner
    else Result := Result + Values[i]
end;

class function HString.Replace(ZuErsetzenderString, ErsetzenderString, str : string) : string;
begin
  Result := str.Replace(ZuErsetzenderString, ErsetzenderString);
end;

class function HString.RemoveDuplicants(const Value : string; const Duplicant : char) : string;
var
  i, Count : Integer;
begin
  SetLength(Result, Length(Value));
  Count := 0;
  for i := 0 to Length(Value) - 1 do
    if (i <= 0) or (not(Value[i] = Duplicant) or (Value[i + 1] <> Duplicant)) then
    begin
      Result[Count + 1] := Value[i + 1];
      inc(Count);
    end;
  SetLength(Result, Count);
end;

class function HString.Replace(const Value : string; const Replacers : array of string; const replacement : string) : string;
var
  i : Integer;
begin
  Result := Value;
  for i := 0 to Length(Replacers) - 1 do
      Result := Result.Replace(Replacers[i], replacement);
end;

class function HString.ReplaceEachOnce(ZuErsetzenderString, ErsetzenderString, str : string) : string;
begin
  Result := SysUtils.StringReplace(str, ZuErsetzenderString, ErsetzenderString, [rfReplaceAll]);
end;

class function HString.FileToString(Filename : string; UseInclude : boolean = False) : AnsiString;
begin
  Result := IdentifierToString(Filename, UseInclude, FileToStringRaw);
end;

class function HString.ResourceToString(Resourcename : string; UseInclude : boolean = False) : AnsiString;
begin
  Result := IdentifierToString(Resourcename, UseInclude, ResourceToStringRaw);
end;

class function HString.IdentifierToString(Identifier : string; UseInclude : boolean; LoaderCallback : ProcIncludeLoaderCallback) : AnsiString;
var
  StringList : TStrings;
  resfile, resfilename : string;
  i : Integer;
  br : AnsiString;
begin
  Result := LoaderCallback(Identifier);

  if not ContainsStr(string(Result), sLineBreak) then br := #10// \n
  else br := sLineBreak; // \r\n

  StringList := Engine.Helferlein.Windows.Split(string(Result), string(br));

  // Check whether the file was split by lines correctly
  Assert(((StringList.Count = 1) and (not ContainsStr(string(Result), #10))) or
    ((StringList.Count > 1) and (AnsiContainsStr(string(Result), #10))),
    '"' + Identifier + '" was not split by line breaks correclty');

  Result := '';
  for i := 0 to StringList.Count - 1 do
  begin
    if UseInclude and (Pos('#include', StringList.Strings[i]) >= 1) then
    begin
      resfile := Replace('#include', '', StringList.Strings[i]);
      resfile := Trim(resfile);
      resfilename := resfile;
      resfile := string(IdentifierToString(resfile, UseInclude, LoaderCallback));
      resfile := resfile + '///////////////////////////////////////////////////////////////////////////////' + sLineBreak +
        '/////// ' + resfilename + sLineBreak +
        '///////////////////////////////////////////////////////////////////////////////' + sLineBreak;
      StringList.Strings[i] := resfile;
    end
    else
    begin
      resfile := Replace(#10, '', StringList.Strings[i]);
      resfile := Replace(#13, '', resfile);
      StringList.Strings[i] := resfile;
    end;
    Result := Result + AnsiString(StringList.Strings[i] + sLineBreak);
  end;
  StringList.Free;
end;

class function HString.ResourceToStringRaw(Resourcename : string) : AnsiString;
var
  ResourceStream : TResourceStream;
begin
  Result := '';
  ResourceStream := nil;
  try
    ResourceStream := TResourceStream.Create(0, Resourcename, RT_RCDATA);
    Result := StreamToStringRaw(ResourceStream);
  finally
    ResourceStream.Free;
  end;
end;

class function HString.Reverse(Text : string) : string;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length(Text) do
      Result := Result + Text[i];
end;

class procedure HString.SaveStringToFile(Filename, Data : string);
var
  Stream : TStreamWriter;
begin
  Stream := TFile.CreateText(Filename);
  try
    Stream.Write(Data);
  finally
    Stream.Free;
  end;
end;

class function HString.Slice(const Text : string; StartSlice, EndSlice : Integer; Step : Integer = 1) : string;
var
  TextLength : Integer;
  i : Integer;
begin
  Result := '';
  if Text = '' then Exit;
  TextLength := Length(Text);
  StartSlice := HMath.Clamp(StartSlice, -TextLength, TextLength - 1);
  EndSlice := HMath.Clamp(EndSlice, -TextLength, TextLength - 1);

  // normalized indices to positive value
  if StartSlice < 0 then
      StartSlice := TextLength + StartSlice;
  if EndSlice < 0 then
      EndSlice := TextLength + EndSlice;
  for i := StartSlice to EndSlice do
      Result := Result + Text[i + 1];
end;

class function HString.Split(Text : string; const SplitStrings : array of string; const KeepDelimiter : boolean; const Count : Integer) : TArray<string>;

/// <summary> Output the first SplitString found in text and returns true if any found
/// <param name="SplitstringIndex"> Index (zero base) of found splitstring.</param>
/// <param name="SplitString"> Found splitstring.</param></summary>
  function FindFirstSplitString(out SplitstringIndex : Integer; out SplitString : string) : boolean;
  var
    Item : string;
    Index : Integer;
  begin
    Result := False;
    SplitstringIndex := MaxInt;
    for Item in SplitStrings do
    begin
      index := Text.IndexOf(Item);
      if (index >= 0) and (index < SplitstringIndex) then
      begin
        Result := True;
        SplitstringIndex := index;
        SplitString := Item;
      end;
    end;
  end;

var
  SplitString, Substring : string;
  SplitstringIndex, Splits : Integer;
begin
  // empty string in SplitStrings would cause an infinite loop
  Assert(not HArray.Contains<string>(HArray.ConvertDynamicToTArray<string>(SplitStrings), ''));
  Result := nil;
  Splits := 1;
  while FindFirstSplitString(SplitstringIndex, SplitString) and ((Count < 0) or (Splits < Count)) do
  begin
    // left part from delimiter, ignore empty parts
    Substring := Text.Substring(0, SplitstringIndex);
    if not Substring.IsEmpty then
        HArray.Push<string>(Result, Substring);
    // add delimiter(split string) if wanted
    if KeepDelimiter then
        HArray.Push<string>(Result, SplitString);
    Text := Text.Remove(0, SplitstringIndex + Length(SplitString));
    inc(Splits);
  end;
  // add rightmost part, ignore empty parts
  if not Text.IsEmpty then
      HArray.Push<string>(Result, Text);
end;

class function HString.StartWith(StrValue : string; StartWith : TArray<string>) : boolean;
var
  Item : string;
begin
  Result := False;
  for Item in StartWith do
  begin
    if StrValue.StartsWith(Item) then
        Exit(True);
  end;
end;

class function HString.StreamToStringRaw(Stream : TStream) : AnsiString;
begin
  Result := '';
  if assigned(Stream) and (Stream.Size > 0) then
  begin
    Stream.position := 0;
    SetLength(Result, Stream.Size);
    Stream.ReadBuffer(Result[1], Stream.Size);
  end;
end;

class function HString.FileToStringRaw(Filename : string) : AnsiString;
var
  FileStream : TFileStream;
begin
  Result := '';
  FileStream := nil;
  try
    FileStream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
    Result := StreamToStringRaw(FileStream);
  finally
    FileStream.Free;
  end;
end;

class function HString.GenerateChars(MultipliedString : string; Times : Integer) : string;
var
  i : Integer;
begin
  Result := '';
  for i := 0 to Times - 1 do
      Result := MultipliedString + Result;
end;

class function HString.FileOrResourceToString(FileNameOrResourceName : string; UseInclude : boolean) : AnsiString;
begin
  Result := IdentifierToString(FileNameOrResourceName, UseInclude, FileOrResourceToStringRaw);
end;

class function HString.FileOrResourceToStringRaw(Identifier : string) : AnsiString;
begin
  if FileExists(Identifier) then Result := FileToStringRaw(Identifier)
  else if FileExists(FormatDateiPfad(Identifier)) then Result := FileToStringRaw(FormatDateiPfad(Identifier))
  else Result := ResourceToString(Identifier);
end;

class function HString.strC(Text : string; Values : array of Variant) : string;
var
  i, iWert : Integer;
begin
  Result := Text;
  iWert := 0;
  repeat
    i := Pos('%v', Result);
    if (i > 0) and (iWert < Length(Values)) then
    begin
      Delete(Result, i, 2);
      Insert(string(Values[iWert]), Result, i);
      inc(iWert);
    end
    else i := -1;
  until i <= 0;
end;

class procedure HString.StringToCharArray(var raus : array of AnsiChar; rein : string);
var
  i : Integer;
begin
  // überprüft ob die String ineinander passen (von den Dimensionen her), +1 wegen der Nullterminierung
  if (Length(rein) + 1) > Length(raus) then raise Exception.Create('StringToCharArray: Der String passt nicht ins Array.');
  for i := 1 to Length(rein) do
  begin
    // -1 weil StringIndex bei 1 anfängt und Array bei 0
    raus[i - 1] := AnsiChar(rein[i]);
  end;
  raus[Length(rein)] := #0;
end;

class function HString.strO(Values : array of Variant) : string;
var
  i : Integer;
begin
  Result := '';
  for i := 0 to Length(Values) - 1 do Result := string(Result) + string(Values[i]);
end;

class function HString.StrToBool(const str : string; const Default : boolean = False) : boolean;
begin
  if not TryStrToBool(str, Result) then Result := default;
end;

class function HString.StrToFloat(const Value : string; const Default : Single) : Single;
begin
  if not TryStrToFloat(Value, Result, EngineFloatFormatSettings) then Result := default;
end;

class function HString.StrToInt(const Value : string; const Default : Integer) : Integer;
begin
  if not TryStrToInt(Value, Result) then Result := default;
end;

class function HString.TrimAfter(Mark, TrimString : string) : string;
var
  i, j : Integer;
  found : boolean;
begin
  Result := TrimString;
  found := False;
  for i := Length(TrimString) - (Length(Mark) - 1) downto 1 do
  begin
    for j := 0 to Length(Mark) - 1 do
    begin
      if Mark[j + 1] <> TrimString[i + j] then break;
      if j = Length(Mark) - 1 then found := True;
    end;
    if found then
    begin
      Result := TrimString;
      Delete(Result, i, Length(TrimString) - i + 1);
      Exit;
    end;
  end;
end;

class function HString.TrimBefore(Mark, TrimString : string) : string;
var
  i, j : Integer;
  found : boolean;
begin
  found := False;
  for i := 1 to Length(TrimString) - (Length(Mark) - 1) do
  begin
    for j := 0 to Length(Mark) - 1 do
    begin
      if Mark[j + 1] <> TrimString[i + j] then break;
      if j = Length(Mark) - 1 then found := True;
    end;
    if found then
    begin
      Result := TrimString;
      Delete(Result, 1, i + (j - 1));
      Exit;
    end;
  end;
end;

class function HString.TrimBeforeCaseInsensitive(Mark, TrimString : string) : string;
var
  i, j : Integer;
  found : boolean;
  temp : string;
begin
  found := False;
  Mark := Mark.ToLowerInvariant;
  temp := TrimString.ToLowerInvariant;
  for i := 1 to Length(temp) - (Length(Mark) - 1) do
  begin
    for j := 0 to Length(Mark) - 1 do
    begin
      if (Mark[j + 1]) <> (temp[i + j]) then break;
      if j = Length(Mark) - 1 then found := True;
    end;
    if found then
    begin
      Result := TrimString;
      Delete(Result, 1, i + (j - 1));
      Exit;
    end;
  end;
end;

class procedure HString.TrimEqualityBeforeCaseInsensitive(var AString, AnotherString : string);
var
  Count, i : Integer;
begin
  Count := 0;
  for i := 1 to Max(Length(AString), Length(AnotherString)) do
  begin
    if (i <= Length(AString)) and (i <= Length(AnotherString)) then
      if AnsiCompareText(AString[i], AnotherString[i]) = 0 then inc(Count)
      else break;
  end;
  Delete(AString, 1, Count);
  Delete(AnotherString, 1, Count);
end;

class function HString.TryFormat(var FormatString : string; const parameters : array of const) : boolean;
begin
  Result := False;
  try
    FormatString := Format(FormatString, parameters);
    Result := True;
  except
    on e : EConvertError do
  end;
end;

class function HString.TryFormat(const FormatString : string; const parameters : array of const; out FormattedString : string) : boolean;
begin
  Result := False;
  try
    FormattedString := Format(FormatString, parameters);
    Result := True;
  except
    on e : EConvertError do
  end;
end;

class function HString.TryStrToBool(const str : string; out ParsedValue : boolean) : boolean;
begin
  Result := True;
  if (str = '0') or (CompareText(str, 'true') = 0) then ParsedValue := True
  else if (str = '1') or (CompareText(str, 'false') = 0) then ParsedValue := False
  else Result := False;
end;

{ RBitmaske }

procedure RBitmaske.BitSetzen(Index : Integer; Value : boolean);
begin
  if Value then Bits := Bits or (1 shl index)
  else
    if BitTesten(index) then Bits := Bits xor (1 shl index)
  else Bits := Bits;
end;

function RBitmaske.BitTesten(Index : Integer) : boolean;
begin
  Result := ((Bits and (1 shl index)) <> 0);
end;

function RBitmaske.Schneiden(Maske2 : RBitmaske) : RBitmaske;
begin
  Result.Bits := Bits and Maske2.Bits;
end;

function RBitmaske.Vereinen(Maske2 : RBitmaske) : RBitmaske;
begin
  Result.Bits := Bits or Maske2.Bits;
end;

{ TDatenSpeicher }

class function TDatenSpeicher<T>.GetParameter(Index : Integer) : T;
begin
  if Length(parameters) > index then Result := parameters[index]
  else ZeroMemory(@Result, SizeOf(T));
end;

class function TDatenSpeicher<T>.SetParameter(Index : Integer; const Value : T) : T;
begin
  if Length(parameters) <= index then SetLength(parameters, index + 1);
  parameters[index] := Value;
  Result := Value;
end;

{ TTimeMeasurement }

class procedure TTimeMeasurement.Activate;
begin
  FActive := True;
end;

class procedure TTimeMeasurement.Finalize;
begin
  if FActive then OutputFile;
  FMainMeasurements.Free;
end;

class procedure TTimeMeasurement.Initialize;
begin
  FActive := False;
  FMainMeasurements := TObjectDictionary<string, TMeasurementSeries>.Create([doOwnsValues]);
  FOutputFileName := FormatDateiPfad('TimeMeasurement.txt');
end;

class procedure TTimeMeasurement.NewSubMeasurement(MainKey, SubMeasurementDescription : string);
begin
  if not FActive then Exit;
  if not FMainMeasurements.ContainsKey(MainKey) then
      raise Exception.Create('TTimeMeasurement.NewSubMeasurement: Mainkey: "' + MainKey + '"doesn''t exist.');
  FMainMeasurements[MainKey].FMeasurements.Last.FSubMeasurments.Add(TSubmeasurement.Create(SubMeasurementDescription));
end;

class procedure TTimeMeasurement.OutputFile;
var
  output : TextFile;
  Key : string;
begin
  AssignFile(output, FOutputFileName);
  Rewrite(output);
  Writeln(output, '--Time Measurement--');
  Writeln(output, '====================');
  Writeln(output);

  for Key in FMainMeasurements.Keys do
  begin
    Writeln(output, FMainMeasurements[Key].GetResult);
  end;
  CloseFile(output);
  ShellExecute(Application.Handle, 'open', PChar(FOutputFileName), nil, nil, sw_ShowNormal);
end;

class procedure TTimeMeasurement.SetOutputeFile(Filename : string);
begin
  FOutputFileName := Filename;
end;

class procedure TTimeMeasurement.StartMainMeasurement(Key, Description : string);
begin
  if not FActive then Exit;
  if not FMainMeasurements.ContainsKey(Key) then FMainMeasurements.Add(Key, TMeasurementSeries.Create(Key, Description));
  FMainMeasurements[Key].Start;
end;

class procedure TTimeMeasurement.StopMainMeasurement(Key : string);
begin
  if not FActive then Exit;
  if not FMainMeasurements.ContainsKey(Key) then
      raise Exception.Create('TTimeMeasurement.StopMainMeasurement: Key: "' + Key + '"doesn''t exist.');
  FMainMeasurements[Key].Stop;
end;

{ TTimeMeasurement.TSubmeasurement }

constructor TTimeMeasurement.TSubmeasurement.Create(Description : string);
begin
  FTimeStamp := TimeManager.GetTimeStamp;
  FDescription := Description;
end;

{ TTimeMeasurement.TMeasurement }

destructor TTimeMeasurement.TMeasurement.Destroy;
begin
  FSubMeasurments.Free;
  inherited;
end;

function TTimeMeasurement.TMeasurement.GetTimeElapsed : int64;
begin
  Result := FEndTime - FStartTime;
end;

constructor TTimeMeasurement.TMeasurement.Start;
begin
  FStartTime := TimeManager.GetTimeStamp;
  FSubMeasurments := TObjectList<TSubmeasurement>.Create;
end;

procedure TTimeMeasurement.TMeasurement.Stop;
begin
  FEndTime := TimeManager.GetTimeStamp;
  FStopped := True;
end;

{ TTimeMeasurement.TMeasurementSeries }

constructor TTimeMeasurement.TMeasurementSeries.Create(Key,
  Description : string);
begin
  FKey := Key;
  FDescription := Description;
  FMeasurements := TObjectList<TMeasurement>.Create;
end;

destructor TTimeMeasurement.TMeasurementSeries.Destroy;
begin
  FMeasurements.Free;
  inherited;
end;

function TTimeMeasurement.TMeasurementSeries.GetResult : string;
  function GetElapsedArray : TArray<Extended>;
  var
    i : Integer;
  begin
    SetLength(Result, FMeasurements.Count);
    for i := 0 to FMeasurements.Count - 1 do
        Result[i] := FMeasurements[i].GetTimeElapsed;
  end;
  function GetElapsedSubMatrix : TArray<TArray<Extended>>;
  var
    i, i2 : Integer;
  begin
    SetLength(Result, FMeasurements[0].FSubMeasurments.Count);
    for i := 0 to FMeasurements[0].FSubMeasurments.Count - 1 do
    begin
      SetLength(Result[i], FMeasurements.Count);
      for i2 := 0 to FMeasurements.Count - 1 do
        // calculate duration for all subemasurements
        if i < (FMeasurements[0].FSubMeasurments.Count - 1) then Result[i][i2] := FMeasurements[i2].FSubMeasurments[i + 1].FTimeStamp - FMeasurements[i2].FSubMeasurments[i].FTimeStamp
        else Result[i][i2] := FMeasurements[i2].FEndTime - FMeasurements[i2].FSubMeasurments[i].FTimeStamp;
    end;
  end;

var
  Data : TArray<Extended>;
  SubData : TArray<TArray<Extended>>;
  i : Integer;
begin
  if FMeasurements.Count <= 0 then Exit;
  Data := GetElapsedArray;
  SubData := GetElapsedSubMatrix;
  Result := '-=Results for ' + FKey + ' - ' + FDescription + '=-' + sLineBreak + sLineBreak;
  Result := Result + 'DataCount: ' + IntToStr(Length(Data)) + sLineBreak;
  Result := Result + 'Avg: ' + FloatToStrF(Mean(Data), ffGeneral, 4, 4, EngineFloatFormatSettings) + 'ms'
    + ' | Min: ' + FloatToStrF(MinValue(Data), ffGeneral, 4, 4, EngineFloatFormatSettings) + 'ms'
    + ' | Max: ' + FloatToStrF(MaxValue(Data), ffGeneral, 4, 4, EngineFloatFormatSettings) + 'ms' + sLineBreak;
  for i := 0 to FMeasurements[0].FSubMeasurments.Count - 1 do
  begin
    Result := Result + '   ' + FMeasurements[0].FSubMeasurments[i].FDescription;
    Result := Result + 'Avg: ' + FloatToStrF(Mean(SubData[i]), ffGeneral, 4, 4, EngineFloatFormatSettings) + 'ms'
      + ' | Min: ' + FloatToStrF(MinValue(SubData[i]), ffGeneral, 4, 4, EngineFloatFormatSettings) + 'ms'
      + ' | Max: ' + FloatToStrF(MaxValue(SubData[i]), ffGeneral, 4, 4, EngineFloatFormatSettings) + 'ms' + sLineBreak;
  end;

end;

procedure TTimeMeasurement.TMeasurementSeries.Start;
begin
  if (FMeasurements.Count > 0) and not FMeasurements.Last.Stopped then FMeasurements.Last.Stop;
  FMeasurements.Add(TTimeMeasurement.TMeasurement.Start);
end;

procedure TTimeMeasurement.TMeasurementSeries.Stop;
begin
  FMeasurements.Last.Stop;
end;

{ TString }

constructor TString.Create(Value : string);
begin
  FValue := Value;
end;

{ RDataRate }

procedure RDataRate.AddData(DataLength : int64);
begin
  Compute;
  FDataLength := FDataLength + DataLength;
end;

procedure RDataRate.Compute;
var
  CurrentTimeStamp : Cardinal;
begin
  CurrentTimeStamp := Gettickcount;
  // if FTimeRate eleapsed calculate datarate and reset counter
  if (CurrentTimeStamp - FTimeStamp) >= FTimeRate then
  begin
    FDataRate := FDataLength;
    FDataLength := 0;
    FTimeStamp := CurrentTimeStamp;
  end;
end;

constructor RDataRate.Create(TimeRate : Cardinal);
begin
  FTimeStamp := Gettickcount;
  FTimeRate := TimeRate;
  FDataLength := 0;
  FDataRate := 0;
end;

function RDataRate.GetDataRate : Integer;
begin
  Result := FDataRate;
end;

{ TEventManager<T> }

constructor TEventManager<T>.Create;
begin
  FCallbacks := TObjectDictionary < T, TList < PEvent<T> >>.Create([doOwnsValues]);
  FComparer := TComparer<T>.Default;
end;

procedure TEventManager<T>.UnSubscribe(Eventname : T; proc : PEvent<T>);
var
  Callbacklist : TList<PEvent<T>>;
  Event : PEvent<T>;
  i : Integer;
begin
  if FCallbacks.TryGetValue(Eventname, Callbacklist) then
  begin
    i := 0;
    while i <= Callbacklist.Count - 1 do
    begin
      Event := Callbacklist[i];
      if (TMethod(Event).Code = TMethod(proc).Code) and (TMethod(Event).Data = TMethod(proc).Data) then Callbacklist.Delete(i)
      else inc(i);
    end;
  end;
end;

destructor TEventManager<T>.Destroy;
begin
  FCallbacks.Free;
  inherited;
end;

procedure TEventManager<T>.Subscribe(Eventname : T; proc : PEvent<T>);
var
  Callbacklist : TList<PEvent<T>>;
begin
  if not FCallbacks.TryGetValue(Eventname, Callbacklist) then
  begin
    Callbacklist := TList < PEvent < T >>.Create;
    FCallbacks.Add(Eventname, Callbacklist);
  end;
  Callbacklist.Add(proc);
end;

procedure TEventManager<T>.SetEvent(Eventname : T; Eventparameters : array of RParam);
var
  i : Integer;
  Callbacklist : TList<PEvent<T>>;
  Callback : PEvent<T>;
  Pass : boolean;
  dT : T;
begin
  dT := default (T);
  if FComparer.Compare(Eventname, dT) = 0 then Exit;
  Pass := True;
  if FCallbacks.TryGetValue(dT, Callbacklist) then
  begin
    i := 0;
    while i < Callbacklist.Count do
    begin
      Callback := Callbacklist[i];
      Callback(Eventname, Eventparameters, @Pass);
      if not Pass then Exit;
      // if list has changed, don't increment, because the new item should get the event as well
      if (i < Callbacklist.Count) and (TMethod(Callbacklist[i]) = TMethod(Callback)) then inc(i);
    end;
  end;
  if FCallbacks.TryGetValue(Eventname, Callbacklist) then
  begin
    i := 0;
    while i < Callbacklist.Count do
    begin
      Callback := Callbacklist[i];
      Callback(Eventname, Eventparameters, @Pass);
      if not Pass then Exit;
      // if list has changed, don't increment, because the new item should get the event as well
      if (i < Callbacklist.Count) and (TMethod(Callbacklist[i]) = TMethod(Callback)) then inc(i);
    end;
  end;
end;

{ TEventManagerWithSender<T, U> }

constructor TEventManagerWithSender<T, U>.Create;
begin
  FCallbacks := TObjectDictionary < T, TList < PEventWithSender<T, U> >>.Create([doOwnsValues]);
  FComparer := TComparer<T>.Default;
end;

procedure TEventManagerWithSender<T, U>.UnSubscribe(Eventname : T; proc : PEventWithSender<T, U>);
var
  Callbacklist : TList<PEventWithSender<T, U>>;
  Event : PEventWithSender<T, U>;
  i : Integer;
begin
  if FCallbacks.TryGetValue(Eventname, Callbacklist) then
  begin
    i := 0;
    while i <= Callbacklist.Count - 1 do
    begin
      Event := Callbacklist[i];
      if (TMethod(Event).Code = TMethod(proc).Code) and (TMethod(Event).Data = TMethod(proc).Data) then Callbacklist.Delete(i)
      else inc(i);
    end;
  end;
end;

destructor TEventManagerWithSender<T, U>.Destroy;
begin
  FCallbacks.Free;
  inherited;
end;

procedure TEventManagerWithSender<T, U>.Subscribe(Eventname : T; proc : PEventWithSender<T, U>);
var
  Callbacklist : TList<PEventWithSender<T, U>>;
begin
  if not FCallbacks.TryGetValue(Eventname, Callbacklist) then
  begin
    Callbacklist := TList < PEventWithSender < T, U >>.Create;
    FCallbacks.Add(Eventname, Callbacklist);
  end;
  Callbacklist.Add(proc);
end;

procedure TEventManagerWithSender<T, U>.SetEvent(Eventname : T; const Sender : U; const Eventparameters : array of RParam);
var
  i : Integer;
  Callbacklist : TList<PEventWithSender<T, U>>;
  Callback : PEventWithSender<T, U>;
  Pass : boolean;
  dT : T;
begin
  dT := default (T);
  if FComparer.Compare(Eventname, dT) = 0 then Exit;
  Pass := True;
  if FCallbacks.TryGetValue(dT, Callbacklist) then
  begin
    i := 0;
    while i < Callbacklist.Count do
    begin
      Callback := Callbacklist[i];
      Callback(Eventname, Sender, Eventparameters, Pass);
      if not Pass then Exit;
      // if list has changed, don't increment, because the new item should get the event as well
      if (i < Callbacklist.Count) and (TMethod(Callbacklist[i]) = TMethod(Callback)) then inc(i);
    end;
  end;
  if FCallbacks.TryGetValue(Eventname, Callbacklist) then
  begin
    i := 0;
    while i < Callbacklist.Count do
    begin
      Callback := Callbacklist[i];
      Callback(Eventname, Sender, Eventparameters, Pass);
      if not Pass then Exit;
      // if list has changed, don't increment, because the new item should get the event as well
      if (i < Callbacklist.Count) and (TMethod(Callbacklist[i]) = TMethod(Callback)) then inc(i);
    end;
  end;
end;

{ TObjectWrapper<T> }

constructor TObjectWrapper<T>.Create(Value : T);
begin
  FValue := Value;
end;

{ TStreamExtender }

function TStreamHelper.EoF : boolean;
begin
  Result := position >= Size;
end;

function TStreamHelper.ReadAny<T> : T;
begin
  ReadBuffer(Result, SizeOf(T));
end;

function TStreamHelper.ReadArray<T>(ArrayLength : Cardinal) : TArray<T>;
begin
  SetLength(Result, ArrayLength);
  ReadBuffer(Result[0], ArrayLength * SizeOf(T));
end;

function TStreamHelper.ReadBoolean : boolean;
begin
  ReadBuffer(Result, SizeOf(boolean));
end;

function TStreamHelper.ReadByte : Byte;
begin
  ReadBuffer(Result, SizeOf(Byte));
end;

function TStreamHelper.ReadCardinal : Cardinal;
begin
  ReadBuffer(Result, SizeOf(Cardinal));
end;

function TStreamHelper.ReadInteger : Integer;
begin
  ReadBuffer(Result, SizeOf(Integer));
end;

function TStreamHelper.ReadSmallInt : SmallInt;
begin
  ReadBuffer(Result, SizeOf(SmallInt));
end;

function TStreamHelper.ReadString : string;
var
  CharCount : Integer;
begin
  ReadData(CharCount);
  if CharCount > 0 then
  begin
    SetLength(Result, CharCount);
    ReadBuffer(Result[1], CharCount * SizeOf(char));
  end
  else
      Result := '';
end;

function TStreamHelper.ReadWord : Word;
begin
  ReadBuffer(Result, SizeOf(Word));
end;

procedure TStreamHelper.Skip(Length : int64);
begin
  position := position + Length;
end;

procedure TStreamHelper.WriteAny<T>(Value : T);
begin
  WriteBuffer(Value, SizeOf(T));
end;

procedure TStreamHelper.WriteByte(Value : Byte);
begin
  WriteBuffer(Value, SizeOf(Byte));
end;

procedure TStreamHelper.WriteCardinal(Value : Cardinal);
begin
  WriteBuffer(Value, SizeOf(Cardinal));
end;

procedure TStreamHelper.WriteString(Value : string);
begin
  WriteData(Length(Value));
  if Length(Value) > 0 then
      WriteBuffer(Value[1], Value.Length * SizeOf(char));
end;

{ TFPS }

constructor TFPSCounter.Create(FrameLimit : Integer; TimeManager : TTimeManager);
begin
  FFrameLimit := FrameLimit;
  if assigned(TimeManager) then
      FTimeManager := TimeManager
  else FTimeManager := Engine.Helferlein.Windows.TimeManager;
end;

procedure TFPSCounter.FrameTick;
var
  Delta : int64;
begin
  inc(FFPSCounter);
  inc(FFrameCount);
  FTimeKey := (FTimeManager.GetTimeStamp - FCurrentTimeStart) / 1000;
  FCurrentTimeStart := FTimeManager.GetTimeStamp;

  Delta := FCurrentTimeStart - FOldTimeStart;
  if Delta >= 1000 then
  begin
    FCurrentFPS := FFPSCounter * 1000 div Delta;
    FFPSCounter := 0;
    FOldTimeStart := FCurrentTimeStart;
  end;
  LimitFrameRate;
end;

function TFPSCounter.getFPS : Integer;
begin
  Result := FCurrentFPS;
end;

procedure TFPSCounter.LimitFrameRate;
var
  sleeptime : double;
  current_time : int64;
  timeForLastFrames : int64;
begin
  current_time := FTimeManager.GetTimeStamp;
  if FrameLimit > 0 then
  begin
    timeForLastFrames := current_time - FLastFrameTimestamps[FrameCount mod FRAMES_LIMITER_INFLUENCING];
    sleeptime := 1000 / FrameLimit - (timeForLastFrames / FRAMES_LIMITER_INFLUENCING);
    if trunc(sleeptime) > 0 then
    begin
      Sleep(trunc(sleeptime));
    end
  end;
  FLastFrameTimestamps[FrameCount mod FRAMES_LIMITER_INFLUENCING] := current_time;
end;

{ TBooleanHelper }

function TBooleanHelper.ToString : string;
begin
  Result := BoolToStr(self, True);
end;

{ TCryptoHelper }

function TCryptoHelper.FileMD5(Path : string) : string;
begin
  Result := GetFileHash(Path, MD5_ProgId);
end;

function TCryptoHelper.FileSHA2(Path : string) : string;
begin
  Result := GetFileHash(Path, SHA512_ProgId);
end;

function TCryptoHelper.GenerateKeys : boolean;
begin
  Result := FSignatory.GenerateKeys();
  FHasPrivateKey := True;
  FHasPublicKey := True;
end;

function TCryptoHelper.GetFileHash(Path, hashId : string) : string;
begin
  {$OVERFLOWCHECKS Off}
  FHash.hashId := hashId;
  FHash.HashFile(Path);
  Result := string(Stream_to_Base64(FHash.HashOutputValue));
  FHash.Burn();
  {$OVERFLOWCHECKS On}
end;

function TCryptoHelper.GetStringHash(Text, hashId : string) : string;
begin
  FHash.hashId := hashId;
  FHash.HashString(Text);
  Result := string(Stream_to_Base64(FHash.HashOutputValue));
  FHash.Burn();
end;

constructor TCryptoHelper.Create();
var
  codec : TCodec;
begin
  FCryptoLib := TCryptographicLibrary.Create(nil);
  FHash := uTPLb_Hash.THash.Create(nil);
  FHash.CryptoLibrary := FCryptoLib;
  FHash.OnProgress := OnHashProgress;
  FSignatory := TSignatory.Create(nil);
  FHasPrivateKey := False;
  FHasPublicKey := False;

  codec := TCodec.Create(nil);
  codec.StreamCipherId := RSA_ProgId;
  codec.CryptoLibrary := FCryptoLib;
  codec.AsymetricKeySizeInBits := 1024;
  codec.ChainModeId := CBC_ProgId;

  FSignatory.codec := codec;
end;

function TCryptoHelper.LoadPrivateKey(Path : string) : boolean;
var
  Stream : TFileStream;
begin
  if not FileExists(Path) then Exit(False);
  Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  FSignatory.LoadKeysFromStream(Stream, [partPrivate]);
  Stream.Free();
  Result := FSignatory.FCryptoKeys.FPrivatePart <> nil;
  self.FHasPrivateKey := Result;
end;

function TCryptoHelper.LoadPublicKey(Path : string) : boolean;
var
  Stream : TFileStream;
begin
  if not FileExists(Path) then Exit(False);
  Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  FSignatory.LoadKeysFromStream(Stream, [partPublic]);
  Stream.Free();
  Result := FSignatory.FSigningKeys.FPublicPart <> nil;
  self.FHasPublicKey := Result;
end;

function TCryptoHelper.MD5(Text : string) : string;
begin
  Result := GetStringHash(Text, 'native.hash.MD5');
end;

function TCryptoHelper.OnHashProgress(Sender : TObject;
  CountBytesProcessed : int64) : boolean;
begin
  if assigned(FOnProgress) then
  begin
    FOnProgress(CountBytesProcessed);
  end;
  Result := True;
end;

function TCryptoHelper.ReadHasKeys : boolean;
begin
  Result := FHasPrivateKey and FHasPublicKey;
end;

procedure TCryptoHelper.SavePrivateKey(Path : string);
var
  Stream : TStream;
begin
  if not FHasPrivateKey then GenerateKeys();
  Stream := TFileStream.Create(Path, fmCreate);
  FSignatory.StoreKeysToStream(Stream, [partPrivate]);
  Stream.Free();
end;

procedure TCryptoHelper.SavePublicKey(Path : string);
var
  Stream : TStream;
begin
  if not FHasPublicKey then GenerateKeys();
  Stream := TFileStream.Create(Path, fmCreate);
  FSignatory.StoreKeysToStream(Stream, [partPublic]);
  Stream.Free();
end;

function TCryptoHelper.SHA2(Text : string) : string;
begin
  Result := GetStringHash(Text, SHA512_ProgId);
end;

destructor TCryptoHelper.Destroy();
begin
  FHash.Free();
  FCryptoLib.Free();
  FSignatory.codec.Free();
  FSignatory.Free();
end;

function TCryptoHelper.SignFile(Filepath, signaturepath : string) : boolean;
var
  inputStream, outputStream : TStream;
begin
  if not FileExists(Filepath) then Exit(False);
  inputStream := TFileStream.Create(Filepath, fmOpenRead or fmShareDenyWrite);
  outputStream := TFileStream.Create(signaturepath, fmCreate);

  Result := FSignatory.Sign(inputStream, outputStream);

  inputStream.Free();
  outputStream.Free();
end;

class function TCryptoHelper.StringToBase64(str : string) : AnsiString;
var
  strStream : TBytesStream;
begin
  Assert(False, 'Method works not correct!');
  strStream := TBytesStream.Create;
  strStream.WriteBuffer(str[1], Length(str) * SizeOf(char));
  strStream.position := 0;
  Result := Stream_to_Base64(strStream);
  strStream.Free;
end;

class function TCryptoHelper.Base64ToString(base64str : AnsiString) : string;
var
  strStream : TStringStream;
begin
  Assert(False, 'Method works not correct!');
  strStream := TStringStream.Create;
  Base64_to_stream(base64str, strStream);
  strStream.position := 0;
  Result := strStream.DataString;
  strStream.Free;
end;

function TCryptoHelper.VerifyFile(Filepath, signaturepath : string) : boolean;
var
  FileStream, signatureStream : TStream;
  verification : TVerifyResult;
begin
  if (not FileExists(Filepath)) or (not FileExists(signaturepath)) then
      Exit(False);

  FileStream := TFileStream.Create(Filepath, fmOpenRead or fmShareDenyWrite);
  signatureStream := TFileStream.Create(signaturepath, fmOpenRead or fmShareDenyWrite);

  verification := FSignatory.Verify(FileStream, signatureStream);
  Result := verification = vPass;

  FileStream.Free();
  signatureStream.Free();
end;

{ HInternet }

procedure TInternet.DownloadFile(Url, Filepath : string);
var
  Stream : TStream;
  dir : string;
begin
  dir := ExtractFilePath(ExpandFileName(Filepath));
  if not DirectoryExists(dir) then ForceDirectories(dir);
  Stream := TFileStream.Create(Filepath, fmCreate);
  Url := TIdURI.URLEncode(Url);
  if assigned(FOnProgress) then FHTTP.OnWork := OnWork
  else FHTTP.OnWork := nil;

  FHTTP.OnWorkBegin := OnWorkBegin;

  try
    FHTTP.Get(Url, Stream);
  finally
    Stream.Free();
  end;
end;

procedure TInternet.OnWork(ASender : TObject; AWorkMode : TWorkMode; AWorkCount : int64);
begin
  if assigned(FOnProgress) then FOnProgress(AWorkCount);
end;

procedure TInternet.OnWorkBegin(ASender : TObject; AWorkMode : TWorkMode; AWorkCount : int64);
begin
  if assigned(FOnTotalSize) then FOnTotalSize(AWorkCount);
end;

procedure TInternet.DownloadFile(Url, Filepath : string; OnProgress : TProgressEvent);
var
  Stream : TStream;
  dir : string;
begin
  dir := ExtractFilePath(ExpandFileName(Filepath));
  if not DirectoryExists(dir) then ForceDirectories(dir);
  Stream := TFileStream.Create(Filepath, fmCreate);
  Url := TIdURI.URLEncode(Url);
  FOnProgress := OnProgress;
  FHTTP.OnWorkBegin := OnWorkBegin;
  FHTTP.OnWork := OnWork;

  try
    FHTTP.Get(Url, Stream);
  finally
    Stream.Free();
  end;
end;

function TInternet.DownloadStream(Url : string) : TStream;
var
  Stream : TStream;
begin
  Stream := TMemoryStream.Create();
  Url := TIdURI.URLEncode(Url);
  FHTTP.OnWorkBegin := OnWorkBegin;
  FHTTP.Get(Url, Stream);
  Result := Stream;
end;

function TInternet.DownloadString(Url : string) : string;
var
  Stream : TStringStream;
begin
  Result := '';
  Stream := TStringStream.Create();
  Url := TIdURI.URLEncode(Url);
  FHTTP.OnWorkBegin := OnWorkBegin;
  try
    FHTTP.Get(Url, Stream);
    Result := Stream.DataString;
  except
    Result := '';
  end;
  Stream.Free();
end;

constructor TInternet.Create();
begin
  FHTTP := TIdHTTP.Create(nil);
  FHTTP.ConnectTimeout := 2000;
  FHTTP.OnWorkBegin := OnWorkBegin;
end;

destructor TInternet.Destroy();
begin
  FreeAndNil(FHTTP);
end;

{ TThreadSafeQueue<T> }

constructor TThreadSafeQueue<T>.Create;
begin
  inherited Create();
  FItems := TQueue<T>.Create();
  FMutex := TMutex.Create();
end;

procedure TThreadSafeQueue<T>.Enqueue(Item : T);
begin
  FMutex.Acquire();
  FItems.Enqueue(Item);
  FMutex.Release();
end;

function TThreadSafeQueue<T>.GetSize : Integer;
begin
  FMutex.Acquire();
  Result := FItems.Count;
  FMutex.Release();
end;

function TThreadSafeQueue<T>.Peek : T;
begin
  FMutex.Acquire();
  Result := FItems.Peek();
  FMutex.Release();
end;

function TThreadSafeQueue<T>.TryDequeue(var Item : T) : boolean;
begin
  FMutex.Acquire();
  if FItems.Count > 0 then
  begin
    Item := FItems.Extract();
    Result := True;
  end
  else
  begin
    Result := False;
  end;
  FMutex.Release();
end;

function TThreadSafeQueue<T>.Dequeue : T;
begin
  FMutex.Acquire();
  Result := FItems.Extract();
  FMutex.Release();
end;

destructor TThreadSafeQueue<T>.Destroy;
begin
  FMutex.Acquire;
  FMutex.Free;
  FItems.Free;
  inherited;
end;

{ TCardinalHelper }

function TCardinalHelper.ToString : string;
begin
  Result := IntToStr(self);
end;

{ TPointerHelper }

function TPointerHelper.ToString : string;
begin
  Result := IntToStr(Integer(self));
end;

{ TContentManager }

constructor TContentManager.Create(CheckTime : int64);
begin
  FContent := TThreadSafeObjectDictionary<string, TManagedFile>.Create([doOwnsValues]);
  FObserverThread := TContentObserverThread.Create(FContent, CheckTime);
  FLock := TCriticalSection.Create;
end;

destructor TContentManager.Destroy;
begin
  FObserverThread.Free;
  FContent.Free;
  FLock.Free;
  inherited;
end;

function TContentManager.FileToMemory(const Filepath : string) : TMemoryStream;
begin
  Result := GetManagedFile(Filepath).Data;
end;

function TContentManager.FileToString(const Filepath : string) : string;
begin
  Result := GetManagedFile(Filepath).DataAsString;
end;

function TContentManager.GetManagedFile(Filepath : string) : TManagedFile;
begin
  Filepath := Filepath.ToLowerInvariant;
  if not FileExists(Filepath) then
      raise EFileNotFoundException.Create('File ' + ExtractFileName(Filepath) + ' not found: ' + Filepath);

  if not FContent.TryGetValue(Filepath, Result) then
  begin
    FLock.Acquire;
    if not FContent.TryGetValue(Filepath, Result) then
    begin
      Result := TManagedFile.Create(Filepath);
      FContent.Add(Filepath, Result);
    end;
    FLock.Release;
  end;
end;

function TContentManager.GetMemoryUsageOverview : string;
begin
  Result := '';
  // var
  // Item : TManagedFile;
  // MemoryUsageDict : TDictionary<string, int64>;
  // MemoryUsage : int64;
  // FileExtension : string;
  // MemoryUsageItem : TPair<string, int64>;
  // begin
  // MemoryUsageDict := TDictionary<string, int64>.Create;
  // for Item in FContent.ExclusiveLock.Values do
  // begin
  // FileExtension := ExtractFileExt(Item.Value.FilePath)
  // MemoryUsage := 0;
  // MemoryUsageDict.TryGetValue(FileExtension, MemoryUsage);
  // MemoryUsage := Item.FData.Size + Length(Item.FDataAsString) * SizeOf(char);
  // MemoryUsageDict.AddOrSetValue(FileExtension, Memory);
  // end;
  // Result := '';
  // for MemoryUsageItem in MemoryUsageDict do
  // begin
  // result := result + MemoryUsageItem.Key
  // end;
end;

function TContentManager.GetObservationEnabled : boolean;
begin
  Result := FObserverThread.ObservationEnabled;
end;

function TContentManager.HasManagedFile(Filepath : string) : boolean;
begin
  Result := FContent.ContainsKey(Filepath.ToLowerInvariant);
end;

procedure TContentManager.PreloadFileIntoMemory(const Filepath : string);
var
  Entry : TManagedFile;
begin
  Entry := GetManagedFile(Filepath);
  Entry.GetData;
end;

procedure TContentManager.PreloadFileIntoText(const Filepath : string);
var
  Entry : TManagedFile;
begin
  Entry := GetManagedFile(Filepath);
  Entry.GetStringData;
end;

procedure TContentManager.SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoMemoryCallback; SubscribeOnly : boolean);
var
  Entry : TManagedFile;
begin
  Entry := GetManagedFile(Filepath);
  Entry.Subscribe(ChangeCallback, SubscribeOnly);
end;

procedure TContentManager.SetCheckTime(Value : int64);
begin
  FObserverThread.CheckTime := Value;
end;

procedure TContentManager.SetObservationEnabled(const Value : boolean);
begin
  FObserverThread.ObservationEnabled := Value;
end;

procedure TContentManager.SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoStringCallback; SubscribeOnly : boolean);
var
  temp : string;
begin
  SubscribeToFile(Filepath, ChangeCallback, temp, SubscribeOnly);
end;

procedure TContentManager.SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoStringCallback; out Filecontent : string; SubscribeOnly : boolean);
var
  Entry : TManagedFile;
begin
  Entry := GetManagedFile(Filepath);
  Entry.SubscribeWithString(ChangeCallback, SubscribeOnly);
  Filecontent := Entry.DataAsString;
end;

procedure TContentManager.SubscribeToFile(const Filepath : string; ChangeCallback : ProcFileChangeNotificationCallback; SubscribeOnly : boolean);
var
  Entry : TManagedFile;
begin
  Entry := GetManagedFile(Filepath);
  Entry.SubscribePlain(ChangeCallback, SubscribeOnly);
end;

procedure TContentManager.UnSubscribeFromFile(const Filepath : string; ChangeCallback : ProcFileChangeNotificationCallback);
var
  Entry : TManagedFile;
begin
  if HasManagedFile(Filepath) then
  begin
    Entry := GetManagedFile(Filepath);
    Entry.UnSubscribePlain(ChangeCallback);
  end;
end;

procedure TContentManager.UnSubscribeFromFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoMemoryCallback);
var
  Entry : TManagedFile;
begin
  if HasManagedFile(Filepath) then
  begin
    Entry := GetManagedFile(Filepath);
    Entry.UnSubscribe(ChangeCallback);
  end;
end;

procedure TContentManager.UnSubscribeFromFile(const Filepath : string; ChangeCallback : ProcFileLoadIntoStringCallback);
var
  Entry : TManagedFile;
begin
  if HasManagedFile(Filepath) then
  begin
    Entry := GetManagedFile(Filepath);
    Entry.UnSubscribeWithString(ChangeCallback);
  end;
end;

{ TContentManager.TManagedFile }

procedure TContentManager.TManagedFile.CleanDirty;
begin
  FMemoryCleaned := False;
  FStringCleaned := False;
  if FileExists(Filepath) then NotifySubscribers;
  UpdateTimeStamp;
end;

constructor TContentManager.TManagedFile.Create(Filepath : string);
begin
  FHoldInMemory := True;
  if HArray.Contains(['.png', '.tga', '.jpg', '.tex'], ExtractFileExt(Filepath)) then
      FHoldInMemory := False;
  self.FData := TMemoryStream.Create;
  self.Filepath := Filepath;
  MemorySubscribers := TList<ProcFileLoadIntoMemoryCallback>.Create;
  StringSubscribers := TList<ProcFileLoadIntoStringCallback>.Create;
  PlainSubscribers := TList<ProcFileChangeNotificationCallback>.Create;
  CleanDirty;
end;

destructor TContentManager.TManagedFile.Destroy;
begin
  MemorySubscribers.Free;
  StringSubscribers.Free;
  PlainSubscribers.Free;
  FData.Free;
  inherited;
end;

procedure TContentManager.TManagedFile.FreeData;
begin
  FMemoryCleaned := False;
  FDataAsString := '';
  FStringCleaned := False;
  FData.Clear;
end;

function TContentManager.TManagedFile.GetCurrentFileAge : TDateTime;
begin
  if not FileAge(Filepath, Result) then Result := 0;
end;

function TContentManager.TManagedFile.GetData : TMemoryStream;
begin
  if not FMemoryCleaned then
  begin
    FData.Clear;
    FData.LoadFromFile(Filepath);
    FMemoryCleaned := True;
  end;
  FData.position := 0;
  Result := FData;
end;

function TContentManager.TManagedFile.GetStringData : string;
begin
  if not FStringCleaned then
  begin
    FDataAsString := HFileIO.ReadAllText(Filepath);
    FStringCleaned := True;
  end;
  Result := FDataAsString;
end;

procedure TContentManager.TManagedFile.NotifySubscribers;
var
  i : Integer;
begin
  for i := 0 to StringSubscribers.Count - 1 do StringSubscribers[i](Filepath, DataAsString);
  for i := 0 to MemorySubscribers.Count - 1 do MemorySubscribers[i](Filepath, Data);
  for i := 0 to PlainSubscribers.Count - 1 do PlainSubscribers[i](Filepath);
  if not FHoldInMemory then
      FreeData;
end;

procedure TContentManager.TManagedFile.Subscribe(Callback : ProcFileLoadIntoMemoryCallback; SubscribeOnly : boolean);
begin
  MemorySubscribers.Add(Callback);
  if not SubscribeOnly then
  begin
    try
      Callback(Filepath, Data);
    finally
      if not FHoldInMemory then
          FreeData;
    end;
  end;
end;

procedure TContentManager.TManagedFile.SubscribePlain(Callback : ProcFileChangeNotificationCallback; SubscribeOnly : boolean);
begin
  PlainSubscribers.Add(Callback);
  if not SubscribeOnly then
      Callback(Filepath);
end;

procedure TContentManager.TManagedFile.SubscribeWithString(Callback : ProcFileLoadIntoStringCallback; SubscribeOnly : boolean);
begin
  StringSubscribers.Add(Callback);
  if not SubscribeOnly then
  begin
    Callback(Filepath, DataAsString);
    if not FHoldInMemory then
        FreeData;
  end;
end;

procedure TContentManager.TManagedFile.UnSubscribe(Callback : ProcFileLoadIntoMemoryCallback);
begin
  MemorySubscribers.Remove(Callback);
end;

procedure TContentManager.TManagedFile.UnSubscribePlain(Callback : ProcFileChangeNotificationCallback);
begin
  PlainSubscribers.Remove(Callback);
end;

procedure TContentManager.TManagedFile.UnSubscribeWithString(Callback : ProcFileLoadIntoStringCallback);
begin
  StringSubscribers.Remove(Callback);
end;

procedure TContentManager.TManagedFile.UpdateTimeStamp;
begin
  Timestamp := GetCurrentFileAge;
end;

function TContentManager.TManagedFile.UpToDate : boolean;
var
  tmp : TDateTime;
begin
  tmp := GetCurrentFileAge;
  Result := SameDateTime(tmp, Timestamp);
end;

{ HInternationalizer }

class procedure HInternationalizer.AddLangKey(Langkey : string);
var
  Lang : string;
begin
  Langkey := Langkey.ToLowerInvariant;
  for Lang in FMapping.Keys do
    if not FMapping[Lang].ContainsKey(Langkey) then
    begin
      FMapping[Lang].Add(Langkey, '');
    end;
end;

class procedure HInternationalizer.ChooseLanguage(const Lang : string);
begin
  FCurrentLang := Lang.ToLowerInvariant;
end;

class function HInternationalizer.CurrentLanguageAsLocaleName : string;
begin
  if FCurrentLang = 'en' then
      Result := 'en-US'
  else if FCurrentLang = 'de' then
      Result := 'de-DE'
  else
      Result := 'en-US';
end;

class function HInternationalizer.DecimalSeparator : string;
begin
  if (FCurrentLang = 'en') or
    (FCurrentLang = 'zh-cn') or
    (FCurrentLang = 'zh-tw') or
    (FCurrentLang = 'ja') or
    (FCurrentLang = 'ko') or
    (FCurrentLang = 'th') then
      Result := '.'
  else if FCurrentLang = 'ar' then
      Result := '٫'
  else
      Result := ','
end;

class procedure HInternationalizer.Finalize;
begin
  FMapping.Free;
end;

class function HInternationalizer.GetAllKeys : TArray<string>;
var
  list : TList<string>;
  Lang, Key : string;
begin
  list := TList<string>.Create;
  for Lang in FMapping.Keys do
  begin
    for Key in FMapping[Lang].Keys do
    begin
      if list.IndexOf(Key) = -1 then list.Add(Key);
    end;
  end;
  Result := list.ToArray;
  list.Free;
end;

class function HInternationalizer.GetLangDict(Lang : string) : TDictionary<string, string>;
begin
  if not FMapping.TryGetValue(Lang.ToLowerInvariant, Result) then Result := nil;
end;

class function HInternationalizer.GetLangKey(Lang, Langkey : string) : string;
var
  dict : TDictionary<string, string>;
begin
  Result := '';
  if Lang = '' then Exit;
  Lang := Lang.ToLowerInvariant;
  Langkey := Langkey.ToLowerInvariant;
  if FMapping.TryGetValue(Lang, dict) then
      dict.TryGetValue(Langkey, Result);
end;

class function HInternationalizer.GetLoadedLanguages : TArray<string>;
begin
  Result := FMapping.Keys.ToArray;
end;

class function HInternationalizer.HasLangKey(Langkey : string) : boolean;
var
  Lang : string;
begin
  Result := False;
  Langkey := Langkey.ToLowerInvariant;
  for Lang in FMapping.Keys do
    if FMapping[Lang].ContainsKey(Langkey.ToLowerInvariant) then Exit(True);
end;

class procedure HInternationalizer.Init;
var
  LangIndex : Integer;
begin
  FMapping := TObjectDictionary < string, TDictionary < string, string >>.Create([doOwnsValues]);
  LangIndex := Languages.IndexOf(SysLocale.DefaultLCID);
  if (LangIndex >= 0) and (LangIndex < Languages.Count) then
      FCurrentLang := Languages.LocaleName[LangIndex].Substring(0, 2).ToLowerInvariant
  else
      FCurrentLang := 'en';
end;

class procedure HInternationalizer.UpdateLangFile(const Filepath, Filecontent : string);
var
  Map : TDictionary<string, string>;
  Langkey, Key, Value : string;
  lines : TStrings;
  lineSplitter : TStringList;
  Columns : TArray<string>;
  ColumnsLanguageKey : TArray<string>;
  i, j : Integer;
begin
  lineSplitter := TStringList.Create;
  lineSplitter.Delimiter := ';';
  lineSplitter.QuoteChar := '"';
  lineSplitter.StrictDelimiter := True;
  lines := TStringList.Create;
  lines.Text := Filecontent;
  for i := 0 to lines.Count - 1 do
  begin
    lineSplitter.Clear;
    lineSplitter.DelimitedText := lines[i];
    Columns := lineSplitter.ToStringArray;
    // build languages
    if i = 0 then
    begin
      ColumnsLanguageKey := Columns;
      for j := 0 to Length(ColumnsLanguageKey) - 1 do
          ColumnsLanguageKey[j] := ColumnsLanguageKey[j].ToLowerInvariant;
    end
    // build key value pairs for each language
    else
    begin
      for j := 1 to Length(Columns) - 1 do
        if j < Length(ColumnsLanguageKey) then
        begin
          Key := Columns[0].ToLowerInvariant;
          Langkey := ColumnsLanguageKey[j];
          if Langkey = '' then Continue;

          if not FMapping.TryGetValue(Langkey, Map) then
          begin
            Map := TDictionary<string, string>.Create;
            FMapping.Add(Langkey, Map);
          end;

          Value := Columns[j];
          Map.AddOrSetValue(Key, Value);
        end;
    end;
  end;
  lines.Free;
  lineSplitter.Free;
end;

class procedure HInternationalizer.LoadLangFile(const Filename : string);
begin
  if FileExists(Filename) then
  begin
    ContentManager.SubscribeToFile(Filename, UpdateLangFile);
  end;
end;

class procedure HInternationalizer.LoadLangFiles(const FileFolder : string; Recursive : boolean; const IgnorePattern : string);
var
  FileList : TStrings;
  str : string;
begin
  FileList := TStringList.Create;
  HFileIO.FindAllFiles(FileList, FileFolder, '*.csv', Recursive);
  // FindAllFiles also find .csv# files and other thing so we need to filter once more
  for str in FileList do
    if (ExtractFileExt(str) = '.csv') and ((IgnorePattern = '') or not TRegex.IsMatch(ExtractFileName(str), IgnorePattern)) then
    begin
      LoadLangFile(str);
    end;
  FileList.Free;
end;

class function HInternationalizer.MakePercentage(const NumberAsString : string) : string;
begin
  Result := NumberAsString;
  if (FCurrentLang = 'fi') or
    (FCurrentLang = 'fr') or
    (FCurrentLang = 'es') or
    (FCurrentLang = 'sv') then
      Result := Result + #160 + '%'
  else if (FCurrentLang = 'ar') or
    (FCurrentLang = 'tr') then
      Result := '%' + Result
  else
      Result := Result + '%';
end;

class procedure HInternationalizer.RemoveLangKey(Langkey : string);
var
  Lang : string;
begin
  Langkey := Langkey.ToLowerInvariant;
  for Lang in FMapping.Keys do
      FMapping[Lang].Remove(Langkey);
end;

class procedure HInternationalizer.RenameLangKey(Langkey, newLangKey : string);
var
  Lang : string;
begin
  Langkey := Langkey.ToLowerInvariant;
  newLangKey := newLangKey.ToLowerInvariant;
  for Lang in FMapping.Keys do
  begin
    if FMapping[Lang].ContainsKey(Langkey) then FMapping[Lang].Add(newLangKey, FMapping[Lang][Langkey])
    else FMapping[Lang].Add(newLangKey, '');
    FMapping[Lang].Remove(Langkey);
  end;
end;

class procedure HInternationalizer.SaveLangFiles(FileFolder : string);
var
  Key, Lang : string;
  Keys : TArray<string>;
  Outfile : TStreamWriter;
begin
  for Lang in FMapping.Keys do
  begin
    Outfile := TStreamWriter.Create(FileFolder + '\' + Lang + '.lang', False, TEncoding.UTF8);
    try
      Keys := FMapping[Lang].Keys.ToArray;
      TArray.Sort<string>(Keys);
      for Key in Keys do
      begin
        Outfile.WriteLine(Key + '=' + FMapping[Lang][Key]);
      end;
    finally
      Outfile.Free;
    end;
  end;
end;

class procedure HInternationalizer.SetLangKey(Lang, Langkey, Value : string);
var
  dict : TDictionary<string, string>;
begin
  if Lang = '' then Exit;
  Lang := Lang.ToLowerInvariant;
  Langkey := Langkey.ToLowerInvariant;
  if not FMapping.TryGetValue(Lang, dict) then
  begin
    dict := TDictionary<string, string>.Create();
    FMapping.Add(Lang, dict);
  end;
  dict.AddOrSetValue(Langkey, Value);
end;

class function HInternationalizer.Translate(const Key : string) : string;
begin
  if not TryTranslate(Key, Result) then Result := Key;
end;

class function HInternationalizer.TranslateText(const Text : string) : string;
begin
  if not TryTranslateText(Text, Result) then Result := Text;
end;

class function HInternationalizer.TranslateTextRecursive(const Text : string; const FormatParams : array of const) : string;
const
  MAX_DEPTH = 10;
var
  i, UsedFormatParams : Integer;
  RemainingFormatParams : TArray<TVarRec>;
begin
  Result := Text;
  UsedFormatParams := 0;
  RemainingFormatParams := HArray.ConvertDynamicToTArray<TVarRec>(FormatParams);
  for i := 0 to MAX_DEPTH - 1 do
  begin
    UsedFormatParams := UsedFormatParams + HString.Count('%', Result);
    Result := Format(Result, RemainingFormatParams);
    RemainingFormatParams := Copy(RemainingFormatParams, UsedFormatParams, Length(RemainingFormatParams) - UsedFormatParams);
    if not Result.Contains('§') then break;
    Result := HInternationalizer.TranslateText(Result);
  end;
end;

class function HInternationalizer.TranslationProgress(const Language : string) : Single;
var
  Map : TDictionary<string, string>;
  Pair : TPair<string, string>;
  EmptyTranslations, TranslationCount : Integer;
  TargetLanguage : string;
begin
  Result := 0;
  if Language <> '' then
      TargetLanguage := Language.ToLowerInvariant
  else
      TargetLanguage := FCurrentLang;
  if FMapping.TryGetValue(TargetLanguage, Map) then
  begin
    TranslationCount := 0;
    EmptyTranslations := 0;
    for Pair in Map do
    begin
      inc(TranslationCount);
      if Pair.Value = '' then
          inc(EmptyTranslations);
    end;
    if TranslationCount > 0 then
        Result := 1 - (EmptyTranslations / TranslationCount);
  end;
end;

class function HInternationalizer.TranslateTextRecursive(const Text : string) : string;
const
  MAX_DEPTH = 10;
var
  i : Integer;
begin
  Result := Text;
  for i := 0 to MAX_DEPTH - 1 do
  begin
    Result := HInternationalizer.TranslateText(Result);
    if not Result.Contains('§') then break;
  end;
end;

class function HInternationalizer.TryTranslate(Key : string; out Translated : string) : boolean;
var
  Map : TDictionary<string, string>;
begin
  // if nothing found return Key as is
  Result := False;
  Key := Key.Replace('§', '').ToLowerInvariant;
  // look up chosen language
  if FMapping.TryGetValue(FCurrentLang, Map) then
      Result := Map.TryGetValue(Key, Translated) and (Translated <> '');
  // if either language or value doesn't exist look up default language
  if not Result and FMapping.TryGetValue(DEFAULTLANG, Map) then
      Result := Map.TryGetValue(Key, Translated) and (Translated <> '');
end;

class function HInternationalizer.TryTranslateText(const Text : string; out newText : string) : boolean;
var
  i : Integer;
  res, Key, Translated : string;
  CollectingKey : boolean;
begin
  if not Text.Contains('§') then Exit(False);
  Result := False;
  res := '';
  Key := '';
  CollectingKey := False;
  for i := 1 to Length(Text) do
  begin
    if Text[i] = '§' then
    begin
      if CollectingKey then
      begin
        if TryTranslate(Key, Translated) then
        begin
          res := res + Translated;
          Result := True;
        end
        else res := res + Key;
      end
      else CollectingKey := True;
      Key := '§';
    end
    else
    begin
      if CollectingKey and not(AnsiChar(Text[i]) in ['a' .. 'z', 'A' .. 'Z', '0' .. '9', '_']) then
      begin
        CollectingKey := False;
        if TryTranslate(Key, Translated) then
        begin
          res := res + Translated;
          Result := True;
        end;
        Key := '';
      end;
      if CollectingKey then Key := Key + Text[i]
      else res := res + Text[i];
    end;
  end;
  if CollectingKey and TryTranslate(Key, Translated) then
  begin
    res := res + Translated;
    Result := True;
  end;;
  if Result then newText := res;
end;

function _(const Langkey : string) : string;
begin
  Result := HInternationalizer.TranslateText(Langkey);
end;

function _(const Langkey : string; const FormatParams : array of const) : string;
begin
  Result := HInternationalizer.TranslateText(Langkey);
  try
    Result := Format(Result, FormatParams);
  except
  end;
end;

function _(const Langkey : string; out TranslatedText : string) : boolean;
begin
  Result := HInternationalizer.TryTranslateText(Langkey, TranslatedText);
end;

function _(const Langkey : string; const FormatParams : array of const; out TranslatedText : string) : boolean;
var
  res : string;
begin
  Result := HInternationalizer.TryTranslateText(Langkey, res);
  if Result then
  begin
    try
      res := Format(res, FormatParams);
    except
    end;
    TranslatedText := res;
  end;
end;

{ TRegexHelper }

class function TRegexHelper.IsMatchOne(const str, Pattern : string; out Match : string; Options : TRegExOptions) : boolean;
var
  aMatch : TMatch;
begin
  aMatch := TRegex.Match(str, Pattern, Options);
  if aMatch.Success then
  begin
    Result := True;
    Assert(aMatch.Groups.Count >= 2, 'TRegexHelper.IsMatchOne: There must be at least one capture group!');
    Match := aMatch.Groups[1].Value;
  end
  else Result := False;
end;

class function TRegexHelper.IsMatchTwo(const str, Pattern : string; out MatchOne, MatchTwo : string; Options : TRegExOptions) : boolean;
var
  aMatch : TMatch;
begin
  aMatch := TRegex.Match(str, Pattern, Options);
  if aMatch.Success then
  begin
    Result := True;
    Assert(aMatch.Groups.Count >= 3, 'TRegexHelper.IsMatchOne: There must be at least two capture group!');
    MatchOne := aMatch.Groups[1].Value;
    MatchTwo := aMatch.Groups[2].Value;
  end
  else Result := False;
end;

class procedure TRegexHelper.MatchesForEach(const str, Pattern : string; Callback : ProcMatchCallback; Options : TRegExOptions);
var
  Regex : TRegex;
  Matches : TMatchCollection;
  i, j : Integer;
  matcharr : TArray<string>;
begin
  Regex := TRegex.Create(Pattern, Options);
  Matches := Regex.Matches(str);
  for i := 0 to Matches.Count - 1 do
  begin
    SetLength(matcharr, Matches[i].Groups.Count - 1);
    for j := 1 to Matches[i].Groups.Count - 1 do
    begin
      matcharr[j - 1] := Matches[i].Groups[j].Value;
    end;
    Callback(i, matcharr);
  end;
end;

function TRegexHelper.MultiSubstitute(str : string; Callback : ProcMultiSubstitute) : string;
var
  Matches : TMatchCollection;
  splitted, bunch : TArray<string>;
  i, j : Integer;
begin
  Matches := self.Matches(str);
  if Matches.Count = 0 then Exit(str);
  splitted := self.Split(str);
  Result := '';
  for i := 0 to Matches.Count - 1 do
  begin
    if (Length(splitted) <= i * 2) or (Matches[i].Groups.Count <= 1) then Continue;
    Assert(Length(splitted) > i * 2);
    Result := Result + splitted[i * 2];
    SetLength(bunch, Matches[i].Groups.Count - 1);
    for j := 0 to Length(bunch) - 1 do bunch[j] := Matches[i].Groups.Item[j + 1].Value;
    Result := Result + Callback(bunch);
  end;
  if Matches.Count < Length(splitted) then
  begin
    Assert(Length(splitted) > 0);
    Result := Result + splitted[high(splitted)];
  end;
end;

class function TRegexHelper.StartsWith(const Text, Pattern : string; out Match : string; Options : TRegExOptions) : boolean;
begin
  Result := StartsWithAt(Text, 0, Pattern, Match, Options);
end;

class function TRegexHelper.StartsWithAt(const Text : string; StartIndex : Integer; Pattern : string; out Match : string; Options : TRegExOptions) : boolean;
var
  aMatch : TMatch;
  Regex : TRegex;
begin
  Regex := TRegex.Create(Pattern, Options);
  aMatch := Regex.Match(Text, StartIndex);
  Result := aMatch.Success and (aMatch.Index = StartIndex);
  if Result then
  begin
    if aMatch.Groups.Count >= 2 then
        Match := aMatch.Groups[1].Value
    else
        Match := aMatch.Value
  end
end;

function TRegexHelper.Substitute(str : string; Callback : ProcSubstitute) : string;
var
  Matches : TMatchCollection;
  splitted : TArray<string>;
  i : Integer;
begin
  Matches := self.Matches(str);
  if Matches.Count = 0 then Exit(str);
  splitted := self.Split(str);
  Result := '';
  for i := 0 to Matches.Count - 1 do
  begin
    if (Length(splitted) <= i * 2) or (Matches[i].Groups.Count <= 1) then Continue;
    Assert(Length(splitted) > i * 2);
    Result := Result + splitted[i * 2];
    Result := Result + Callback(Matches[i].Groups.Item[1].Value);
  end;
  if Matches.Count < Length(splitted) then
  begin
    Assert(Length(splitted) > 0);
    Result := Result + splitted[high(splitted)];
  end;
end;

class function TRegexHelper.SubstituteDirect(const str, Pattern, replacement : string; adjuster : ProcAdjuster; Options : TRegExOptions) : string;
var
  Regex : TRegex;
begin
  Regex := TRegex.Create(Pattern, Options);
  Result := Regex.SubstituteDirect(str, replacement, adjuster);
end;

function TRegexHelper.SubstituteDirect(const str, replacement : string; adjuster : ProcAdjuster) : string;
var
  Matches : TMatchCollection;
  splitted : TArray<string>;
  temp, rgl : string;
  i : Integer;
  j : Integer;
begin
  Matches := self.Matches(str);
  if Matches.Count = 0 then Exit(str);
  splitted := self.Split(str);
  Result := '';
  for i := 0 to Matches.Count - 1 do
  begin
    if (Length(splitted) <= i * 2) or (Matches[i].Groups.Count <= 1) then Continue;
    Assert(Length(splitted) > i * 2);
    Result := Result + splitted[i * 2];
    temp := replacement;
    for j := 1 to Matches[i].Groups.Count - 1 do
    begin
      rgl := Matches[i].Groups[j].Value;
      if assigned(adjuster) then rgl := adjuster(j, rgl);
      temp := temp.Replace('\L\' + IntToStr(j), rgl.ToLower);
      temp := temp.Replace('\U\' + IntToStr(j), rgl.ToUpper);
      temp := temp.Replace('\' + IntToStr(j), rgl);
    end;
    Result := Result + temp;
  end;
  if Matches.Count < Length(splitted) then
  begin
    Assert(Length(splitted) > 0);
    Result := Result + splitted[high(splitted)];
  end;
end;

{ TInterpolator<T> }

constructor TInterpolator<T>.Create(InterpolationTime : Integer; InterpolationMethod : EnumInterpolationMethod = imLinear);
begin
  FTimer := TTimer.Create(InterpolationTime);
  FInterpolationMethod := InterpolationMethod;
end;

function TInterpolator<T>.CurrentPercent : Single;
begin
  Result := FTimer.ZeitDiffProzent;
end;

function TInterpolator<T>.CurrentValue : T;
begin
  Result := Interpolate(FTimer.ZeitDiffProzent);
end;

destructor TInterpolator<T>.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TInterpolator<T>.Running : boolean;
begin
  Result := not FTimer.Expired;
end;

procedure TInterpolator<T>.Start(StartValue, EndValue : T; Interval : Integer = -1);
begin
  FStart := StartValue;
  FEnd := EndValue;
  if Interval < 0 then FTimer.Start
  else FTimer.SetIntervalAndStart(Interval);
end;

function TInterpolator<T>.Stopped : boolean;
begin
  Result := not Running and FStopped;
  FStopped := Running;
end;

{ TRVector2Interpolator }

function TRVector2Interpolator.Interpolate(s : Single) : RVector2;
begin
  case FInterpolationMethod of
    imLinear : Result := FStart.Lerp(FEnd, s);
    imCosinus : Result := FStart.CosLerp(FEnd, s);
  end;
end;

{ TRVector3Interpolator }

function TRVector3Interpolator.Interpolate(s : Single) : RVector3;
begin
  case FInterpolationMethod of
    imLinear : Result := FStart.Lerp(FEnd, s);
    imCosinus : Result := FStart.CosLerp(FEnd, s);
  end;
end;

{ TTuple<T, U> }

constructor TTuple<T, U>.Create(a : T; b : U);
begin
  self.a := a;
  self.b := b;
end;

destructor TTuple<T, U>.Destroy;
begin
  if HRTTI.GetTypeKindOf<T> = tkClass then PObject(@a)^.Free;
  if HRTTI.GetTypeKindOf<U> = tkClass then PObject(@b)^.Free;
  inherited;
end;

{ RTriple<T, U, V> }

constructor RTriple<T, U, V>.Create(a : T; b : U; c : V);
begin
  self.a := a;
  self.b := b;
  self.c := c;
end;

{ TControlHelper }

procedure TControlHelper.RemoveAllComponents(FreeComponents : boolean);
var
  i : Integer;
begin
  for i := ComponentCount - 1 downto 0 do
  begin
    if FreeComponents then Components[i].Free
    else RemoveComponent(Components[i]);
  end;
end;

{ TRttiFieldPropertyUnified }

constructor TRttiMemberUnified.Create(SourceRttiInfo : TRttiField);
begin
  FSourceRttiInfo := SourceRttiInfo;
  FMemberType := mtField;
end;

constructor TRttiMemberUnified.Create(SourceRttiInfo : TRttiProperty);
begin
  FSourceRttiInfo := SourceRttiInfo;
  FMemberType := mtProperty;
end;

constructor TRttiMemberUnified.Create(SourceRttiInfo : TRttiMethod);
begin
  FSourceRttiInfo := SourceRttiInfo;
  FMemberType := mtMethod;
end;

constructor TRttiMemberUnified.Create(SourceRttiInfo : TRttiMember);
begin
  Assert(assigned(SourceRttiInfo));
  if SourceRttiInfo is TRttiMethod then
      Create(SourceRttiInfo as TRttiMethod)
  else if SourceRttiInfo is TRttiProperty then
      Create(SourceRttiInfo as TRttiProperty)
  else if SourceRttiInfo is TRttiField then
      Create(SourceRttiInfo as TRttiField)
  else raise ENotSupportedException.CreateFmt('TRttiMemberUnified.Create: Unknown member type "%s"', [SourceRttiInfo.ClassName]);
end;

procedure TRttiMemberUnified.ExpectType(MemberTypes : SetMemberType);
begin
  if not(FMemberType in MemberTypes) then
      HLog.Write(elError, 'TRttiMemberUnified: Action is for this membertype not supported!', ENotSupportedException);
end;

procedure TRttiMemberUnified.ExpectType(MemberType : EnumMemberType);
begin
  try
    ExpectType([MemberType]);
  except
    on e : Exception do
        raise e at ReturnAddress;
  end;
end;

function TRttiMemberUnified.GetAttributes : TArray<TCustomAttribute>;
begin
  Result := FSourceRttiInfo.GetAttributes;
end;

function TRttiMemberUnified.GetName : string;
begin
  Result := FSourceRttiInfo.Name;
end;

function TRttiMemberUnified.GetType : TRttiType;
begin
  ExpectType([mtField, mtProperty, mtMethod]);
  case FMemberType of
    mtProperty : Result := TRttiProperty(FSourceRttiInfo).PropertyType;
    mtField : Result := TRttiField(FSourceRttiInfo).FieldType;
    mtMethod : Result := TRttiMethod(FSourceRttiInfo).ReturnType
  else raise ENotImplemented.Create('Member type currently not supported!');
  end;
end;

function TRttiMemberUnified.GetValue(const Instance : TValue) : TValue;
begin
  ExpectType([mtField, mtProperty, mtMethod]);
  case FMemberType of
    mtProperty : if Instance.Kind = tkClass then
          Result := TRttiProperty(FSourceRttiInfo).GetValue(Instance.AsObject)
      else
          Result := TRttiProperty(FSourceRttiInfo).GetValue(Instance.GetReferenceToRawData);
    mtField : if Instance.Kind = tkClass then
          Result := TRttiField(FSourceRttiInfo).GetValue(Instance.AsObject)
      else
          Result := TRttiField(FSourceRttiInfo).GetValue(Instance.GetReferenceToRawData);
    mtMethod :
      if TRttiMethod(FSourceRttiInfo).ParameterCount = 0 then
          Result := TRttiMethod(FSourceRttiInfo).Invoke(Instance, [])
      else
          raise EHRttiError.Create('TRttiMemberUnified.GetValue: Only support methods with 0 parameters.');
  end;
end;

function TRttiMemberUnified.GetValueFromRawPointer(const Instance : Pointer) : TValue;
var
  InstanceKind : TTypeKind;
begin
  ExpectType([mtField, mtProperty]);
  InstanceKind := FSourceRttiInfo.Parent.TypeKind;
  case FMemberType of
    mtProperty : if InstanceKind = tkClass then
          Result := TRttiProperty(FSourceRttiInfo).GetValue(TObject(Instance))
      else
          Result := TRttiProperty(FSourceRttiInfo).GetValue(Instance);
    mtField : if InstanceKind = tkClass then
          Result := TRttiField(FSourceRttiInfo).GetValue(TObject(Instance))
      else
          Result := TRttiField(FSourceRttiInfo).GetValue(Instance);
  end;
end;

function TRttiMemberUnified.HasAttributeOfClass(SearchFor : ClassOfCustomAttribute) : boolean;
begin
  Result := HArray.SearchClassInArray<TCustomAttribute>(SearchFor, GetAttributes, nil);
end;

function TRttiMemberUnified.HasAttribute<a>(out AttributeInstance : a) : boolean;
var
  temp : TClass;
begin
  temp := a;
  Result := HArray.SearchClassInArray<TCustomAttribute>(temp, GetAttributes, Pointer(AttributeInstance));
end;

function TRttiMemberUnified.Invoke(const Instance : Pointer; const Args : array of TValue) : TValue;
var
  InstanceKind : TTypeKind;
begin
  ExpectType(mtMethod);
  InstanceKind := FSourceRttiInfo.Parent.TypeKind;
  if InstanceKind = tkClass then
      TRttiMethod(FSourceRttiInfo).Invoke(TObject(Instance), Args)
  else
      TRttiMethod(FSourceRttiInfo).Invoke(Instance, Args);
end;

procedure TRttiMemberUnified.SetValue(const Instance : TValue; const AValue : TValue);
begin
  ExpectType([mtField, mtProperty]);
  case FMemberType of
    mtProperty : if Instance.Kind = tkClass then
          TRttiProperty(FSourceRttiInfo).SetValue(Instance.AsObject, AValue)
      else
          TRttiProperty(FSourceRttiInfo).SetValue(Instance.GetReferenceToRawData, AValue);
    mtField : if Instance.Kind = tkClass then
          TRttiField(FSourceRttiInfo).SetValue(Instance.AsObject, AValue)
      else
          TRttiField(FSourceRttiInfo).SetValue(Instance.GetReferenceToRawData, AValue);
    mtMethod : Assert(False);
  end;
end;

procedure TRttiMemberUnified.SetValueToRawPointer(const Instance : Pointer; const AValue : TValue);
var
  InstanceKind : TTypeKind;
begin
  ExpectType([mtField, mtProperty]);
  InstanceKind := FSourceRttiInfo.Parent.TypeKind;
  case FMemberType of
    mtProperty : if InstanceKind = tkClass then
          TRttiProperty(FSourceRttiInfo).SetValue(TObject(Instance), AValue)
      else
          TRttiProperty(FSourceRttiInfo).SetValue(Instance, AValue);
    mtField : if InstanceKind = tkClass then
          TRttiField(FSourceRttiInfo).SetValue(TObject(Instance), AValue)
      else
          TRttiField(FSourceRttiInfo).SetValue(Instance, AValue);
  end;
end;

{ HRandom }

class constructor HRandom.Create;
var
  i : Integer;
begin
  for i := 0 to Length(HRandom.RandomValues) - 1 do
      HRandom.RandomValues[i] := Random;
  HRandom.CurrentIndex := 0;
end;

class function HRandom.Random : Single;
begin
  Result := HRandom.RandomValues[HRandom.CurrentIndex];
  HRandom.CurrentIndex := (HRandom.CurrentIndex + 1) mod Length(HRandom.RandomValues);
end;

class procedure HRandom.setCurrentIndex(const Value : Integer);
begin
  HRandom.CurrentIndex := Value mod Length(HRandom.RandomValues);
end;

{ HFilepathManager }

class function HFilepathManager.AppendToFilename(const Filepath, Suffix : string) : string;
begin
  Result := ChangeFileExt(Filepath, Suffix + ExtractFileExt(Filepath));
end;

class constructor HFilepathManager.Create;
begin
  FExePath := ExtractFilePath(Application.ExeName);
end;

class function HFilepathManager.FileExists(Filename : string) : boolean;
begin
  Result := SysUtils.FileExists(AbsolutePath(Filename));
end;

class procedure HFilepathManager.ForEachFile(RootFolder : string; Callback : ProcFileCallback; Mask : string; Recurse : boolean);
var
  SR : TSearchRec;
begin
  RootFolder := IncludeTrailingPathDelimiter(RelativeToAbsolute(RootFolder));
  // if recursive look for folder to look through
  if Recurse then
    if FindFirst(RootFolder + '*.*', faAnyFile, SR) = 0 then
      try
        repeat
          if SR.Attr and faDirectory = faDirectory then
            // --> found a directory, dig deeper
            if (SR.Name <> '.') and (SR.Name <> '..') then ForEachFile(RootFolder + SR.Name, Callback, Mask, Recurse);
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
  // process matching files
  if FindFirst(RootFolder + Mask, faAnyFile, SR) = 0 then
    try
      repeat
        if SR.Attr and faDirectory <> faDirectory then
        begin
          // --> found a matching file
          Callback(RootFolder + SR.Name);
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
end;

class function HFilepathManager.getAbsoluteWorkingPath : string;
begin
  Result := ExePath + RelativeWorkingPath;
  // Resolve Folder jumps
  ResolveFolderJumps(Result);
end;

class function HFilepathManager.GetSpecialPath(SpecialPath : EnumSpecialPaths; FormHandle : HWND) : string;
var
  PIDL : PItemIDList;
  Path : array [0 .. MAX_PATH] of char;
  id : shortint;
begin
  case SpecialPath of
    spDesktop : id := CSIDL_DESKTOP;
    spMyDocuments : id := CSIDL_MYDOCUMENTS;
    spAppdata : id := CSIDL_APPDATA;
    spProgramFiles : id := CSIDL_PROGRAM_FILES;
  else
    raise ENotImplemented.Create('HFilepathManager.GetSpecialPath: Special Path not implemented for this path!');
  end;
  SHGetSpecialFolderLocation(FormHandle, id, PIDL);
  SHGetPathFromIDList(PIDL, Path);
  Result := HString.CharArrayToString(Path) + '\';
end;

class function HFilepathManager.IsAbsolute(const Path : string) : boolean;
begin
  Result := ExtractFileDrive(Path) <> '';
end;

class function HFilepathManager.IsFileType(const Filename, FileExtension : string) : boolean;
begin
  Result := ExtractFileExt(Filename).ToLowerInvariant = '.' + FileExtension.ToLowerInvariant;
end;

class function HFilepathManager.IsRelative(const Path : string) : boolean;
begin
  Result := ExtractFileDrive(Path) = '';
end;

class procedure HFilepathManager.LoadWorkingPath(Filename : string);
var
  str : string;
  Datei : TextFile;
begin
  if FileExists(ExePath + Filename) then
  begin
    AssignFile(Datei, ExePath + Filename);
    Reset(Datei);
    readln(Datei, str);
    CloseFile(Datei);
    RelativeWorkingPath := str;
  end
  else
  begin
    SelectDirectory('Please choose the working directory:', '', str);
    RelativeWorkingPath := str;
  end;
end;

class function HFilepathManager.AbsoluteToRelative(const Path : string) : string;
var
  temp, WorkingPathRest, SplitItem : string;
begin
  // chech whether already is relative
  if (Path = '') or IsRelative(Path) then Exit(Path);
  Result := Path;
  // remove equal path part
  WorkingPathRest := AbsoluteWorkingPath;
  HFilepathManager.TrimEqualPath(Result, WorkingPathRest);
  // if equal part ends in working directory, everything is finished
  // if equal part ends higher than the working directy add folder jumps (..) as many as there are higher folders left
  temp := '';
  for SplitItem in WorkingPathRest.Split(['\']) do
    if not SplitItem.IsEmpty then
        temp := temp + '..\';
  Result := '\' + temp + Result;
  // make path prettier
  Result := Result.Replace('/', '\');
  Result := HString.RemoveDuplicants(Result, '\');
end;

class function HFilepathManager.RelativeToAbsolute(const Path : string) : string;
begin
  if Path = '' then Exit('');
  // comfort adjustments, allow / instead of \ and remove double slashes
  Result := Path.Replace('/', '\');
  Result := HString.RemoveDuplicants(Result, '\');
  // if the relative path is already absolute, don't add working path, but resolve folder jumps
  if IsRelative(Result) then Result := AbsoluteWorkingPath + Result
  else Result := Result;
  // everytime paths are concat clean double slashes
  Result := HString.RemoveDuplicants(Result, '\');
  ResolveFolderJumps(Result);
end;

class function HFilepathManager.RelativeToRelative(RelativePath, BaseRelativePath : string) : string;
begin
  // Remove equal path
  TrimEqualPath(RelativePath, BaseRelativePath);
  Result := RelativePath;
  // if base path has still folders, we need to jump them up to the real common base
  if BaseRelativePath <> '' then
      Result := HString.GenerateChars('..\', Length(BaseRelativePath.Split(['\'], TStringSplitOptions.ExcludeEmpty))) + Result;
end;

class procedure HFilepathManager.ResolveFolderJumps(var Path : string);
var
  strS : TStringList;
  i : Integer;
begin
  Path := HString.RemoveDuplicants(Path, '\');
  // resolve folder jumps (..)
  if Pos('..', Path) > 0 then
  begin
    strS := Split(Path, '\');
    // start with 1 because of file drive mark
    i := 1;
    while i <= strS.Count - 1 do
    begin
      if strS.Strings[i] = '..' then
      begin
        // for each ..
        // consume the mark
        strS.Delete(i);
        // if we are on file drive level, prevent eating file drive
        if i <> 1 then
        begin
          // consume the folder before the mark
          strS.Delete(i - 1);
          dec(i);
        end;
      end
      else inc(i);
    end;
    // rebuild path
    Path := strS.Strings[0];
    for i := 1 to strS.Count - 1 do Path := Path + '\' + strS.Strings[i];
    strS.Free;
  end;
end;

class procedure HFilepathManager.SaveWorkingPath(Filename : string);
var
  Datei : TextFile;
begin
  AssignFile(Datei, ExePath + Filename);
  Rewrite(Datei);
  Writeln(Datei, RelativeWorkingPath);
  CloseFile(Datei);
end;

class procedure HFilepathManager.setWorkingPath(Value : string);
begin
  FWorkingPath := AbsoluteToRelative(Value);
end;

class procedure HFilepathManager.TrimEqualPath(var Path1, Path2 : string);
var
  Path1Split, Path2Split : TArray<string>;
  Path1EndsWith, Path2EndsWith : boolean;
  i, j : Integer;
begin
  Path1 := HString.Replace('\\', '\', Path1);
  Path2 := HString.Replace('\\', '\', Path2);
  Path1EndsWith := Path1.EndsWith('\');
  Path2EndsWith := Path2.EndsWith('\');
  Path1Split := Path1.Split(['\']);
  Path2Split := Path2.Split(['\']);
  for i := 0 to Min(Length(Path1Split), Length(Path2Split)) - 1 do
    if string.CompareText(Path1Split[i], Path2Split[i]) <> 0 then break;
  Path1 := '';
  for j := i to Length(Path1Split) - 1 do
  begin
    Path1 := Path1 + Path1Split[j];
    if (j < Length(Path1Split) - 1) or Path1EndsWith then Path1 := Path1 + '\';
  end;
  Path2 := '';
  for j := i to Length(Path2Split) - 1 do
  begin
    Path2 := Path2 + Path2Split[j];
    if (j < Length(Path2Split) - 1) or Path2EndsWith then Path2 := Path2 + '\';
  end;
end;

class function HFilepathManager.UnifyPath(const Filepath : string) : string;
begin
  Result := Filepath.ToLowerInvariant.Replace('/', '\');
end;

{ HPreProcessor }

class function HPreProcessor.PrettyPrintHLSL(str : string) : string;
var
  lines : TArray<string>;
  i, openBracketCount : Integer;
  lastLine, currentLine : string;
begin
  lines := HString.Split(str, [sLineBreak]);
  openBracketCount := 0;
  for i := 0 to Length(lines) - 1 do
  begin
    currentLine := lines[i];
    currentLine := currentLine.TrimLeft;
    if currentLine.Contains('}') then dec(openBracketCount);
    if not((lastLine = '') and (currentLine = '')) then Result := Result + HString.GenerateChars('  ', openBracketCount) + currentLine + sLineBreak;
    if currentLine.Contains('{') then inc(openBracketCount);
    lastLine := currentLine;
  end;
end;

class function HPreProcessor.ResolveDefines(str : string) : string;
var
  Defines : TList<RTuple<string, string>>;
  replacement_key : RTuple<string, string>;
begin
  Defines := TList < RTuple < string, string >>.Create;
  // extract defines
  TRegex.MatchesForEach(str, '\#define ([\w\d_]+) (.+)',
    procedure(matchindex : Integer; Matches : TArray<string>)
    begin
      Defines.Add(RTuple<string, string>.Create(Matches[0], Matches[1]));
    end, [roMultiLine]);
  // delete define definition
  Result := TRegex.SubstituteDirect(str, '(\#define [\w\d_]+ .+)', '');
  // sort longest defines to shortest, to resolve prefix problematic
  Defines.Sort(TComparer < RTuple < string, string >>.Construct(
    function(const Left, Right : RTuple<string, string>) : Integer
    begin
      Result := Length(Right.a) - Length(Left.a);
    end));
  // replace defines with defines expressions
  for replacement_key in Defines do
      Result := Result.Replace(replacement_key.a, replacement_key.b, [rfReplaceAll]);
  Defines.Free;
end;

class function HPreProcessor.ResolveHLSL(str : string) : string;
type
  RStackItem = record
    Condition, InElse, Pass : boolean;
  end;
var
  IfDefines, Defines : TDictionary<string, string>;
  lines : TArray<string>;
  DefineStack : TList<RStackItem>;
  Stackitem : RStackItem;
  IsWriting : boolean;
  Define, Condition, replacement, SanitizedLine, FinalLine : string;
  i : Integer;
  function ResolveReplacements(str : string) : string;
  var
    replacement_key : string;
  begin
    Result := str;
    for replacement_key in Defines.Keys do
      if Result.Contains(replacement_key) then
      begin
        Result := Result.Replace(replacement_key, Defines[replacement_key], [rfReplaceAll]);
      end;
  end;

type
  EnumBoolOp = (boOr, boAnd, boGreater, boGreaterEqual, boLesser, boLesserEqual, boSame, boUnsame);

  function TryExpressionToBool(str : string; out Value : boolean) : boolean;
  var
    splitted : TArray<string>;
  begin
    str := ResolveReplacements(str).Replace(' ', '').Replace(#9, '');
    splitted := HString.Split(str, ['<', '>', '>=', '<=', '==', '!='], True);
    if Length(splitted) <> 3 then Exit(False);
    Result := True;
    // reverse string to have the string comparison working as a number comparison
    splitted[0] := HString.Reverse(splitted[0]);
    splitted[2] := HString.Reverse(splitted[2]);
    if splitted[1] = '<' then Value := splitted[0] < splitted[2]
    else if splitted[1] = '>' then Value := splitted[0] > splitted[2]
    else if splitted[1] = '<=' then Value := splitted[0] <= splitted[2]
    else if splitted[1] = '>=' then Value := splitted[0] >= splitted[2]
    else if splitted[1] = '==' then Value := splitted[0] = splitted[2]
    else if splitted[1] = '!=' then Value := splitted[0] <> splitted[2];
  end;

  function CheckCondition(Condition : string; var Not_Implemented : boolean) : boolean;
  var
    splitted : TArray<string>;
    boolOp : EnumBoolOp;
    literalValue, negate : boolean;
    i : Integer;
  begin
    Not_Implemented := False;
    Result := False;
    boolOp := boOr;
    Condition := Condition.Replace('#if ', '').Replace(' ', '').Replace(#9, '');
    // resolve defined() method
    Condition := TRegex.SubstituteDirect(Condition,
      'defined\((.*?)\)',
      '\1',
      function(Index : Integer; const str : string) : string
      begin
        Result := BoolToStr(IfDefines.ContainsKey(str));
      end);
    splitted := HString.Split(Condition, ['||', '&&'], True);
    for i := 0 to Length(splitted) - 1 do
    begin
      if i mod 2 = 0 then
      begin
        // literal
        negate := Pos('!', splitted[i]) > 0;
        splitted[i] := splitted[i].Replace('!', '', []);
        // try to parse literal
        if not(TryStrToBool(splitted[i], literalValue) or TryExpressionToBool(splitted[i], literalValue)) then
        begin
          Not_Implemented := True;
          Exit(True);
        end;
        literalValue := negate xor literalValue;
        if boolOp = boOr then Result := Result or literalValue
        else Result := Result and literalValue;
      end
      else
      begin
        // operator
        if splitted[i] = '||' then boolOp := boOr
        else if splitted[i] = '&&' then boolOp := boAnd
        else
        begin
          Not_Implemented := True;
          Exit(True);
        end;
      end;
    end;
  end;

  procedure ComputeIsWriting;
  var
    i : Integer;
  begin
    IsWriting := True;
    for i := 0 to DefineStack.Count - 1 do
        IsWriting := IsWriting and ((DefineStack[i].Condition xor DefineStack[i].InElse) or DefineStack[i].Pass);
  end;

begin
  Defines := TDictionary<string, string>.Create;
  IfDefines := TDictionary<string, string>.Create;

  // parse through string, split with linebreaks
  lines := str.Split([sLineBreak], TStringSplitOptions.None);
  Result := '';
  DefineStack := TList<RStackItem>.Create;
  Stackitem.Condition := True;
  Stackitem.InElse := False;
  Stackitem.Pass := False;
  DefineStack.Add(Stackitem);
  IsWriting := True;
  for i := 0 to Length(lines) - 1 do
  begin
    SanitizedLine := lines[i].TrimLeft([' ', #9]);
    // if the first character is a # it is a command
    if SanitizedLine.StartsWith('#') then
    begin
      if IsWriting and TRegex.IsMatchTwo(SanitizedLine, '\#define ([\w\d_]+) ([\d\.\w]+)', Define, replacement, [roIgnoreCase, roSingleLine]) then
      begin
        Defines.AddOrSetValue(Define, replacement);
      end
      else if IsWriting and TRegex.IsMatchOne(SanitizedLine, '\#define ([\w\d_]+)', Define, [roIgnoreCase, roSingleLine]) then
      begin
        IfDefines.AddOrSetValue(Define, replacement);
      end
      else if TRegex.IsMatchOne(SanitizedLine, '\#ifdef ([\w\d_]+)', Define, [roIgnoreCase, roSingleLine]) then
      begin
        Stackitem.Condition := IfDefines.ContainsKey(Define);
        Stackitem.InElse := False;
        Stackitem.Pass := False;
        DefineStack.Add(Stackitem);
      end
      else if TRegex.IsMatchOne(SanitizedLine, '\#ifndef ([\w\d_]+)', Define, [roIgnoreCase, roSingleLine]) then
      begin
        Stackitem.Condition := not IfDefines.ContainsKey(Define);
        Stackitem.InElse := False;
        Stackitem.Pass := False;
        DefineStack.Add(Stackitem);
      end
      else if TRegex.IsMatchOne(SanitizedLine, '\#if (.+)', Condition, [roIgnoreCase, roSingleLine]) then
      begin
        Stackitem.Condition := CheckCondition(Condition, Stackitem.Pass);
        Stackitem.InElse := False;
        DefineStack.Add(Stackitem);
      end
      else if SanitizedLine.StartsWith('#else', True) then
      begin
        Stackitem := DefineStack.Last;
        Stackitem.InElse := not Stackitem.InElse;
        DefineStack[DefineStack.Count - 1] := Stackitem;
      end
      else if SanitizedLine.StartsWith('#endif', True) then
      begin
        Assert(DefineStack.Count > 1, 'HPreProcessor.Resolve: Found closing #endif without opening!');
        if IsWriting and DefineStack.Last.Pass then Result := Result + lines[i] + sLineBreak;
        DefineStack.Delete(DefineStack.Count - 1);
      end;
      ComputeIsWriting;
      if IsWriting and DefineStack.Last.Pass then Result := Result + lines[i] + sLineBreak;
    end
    else
    begin
      // write line content
      if IsWriting then
      begin
        // apply direct replacement defines
        FinalLine := ResolveReplacements(lines[i]) + sLineBreak;
        Result := Result + FinalLine;
      end;
    end;
  end;
  Assert(DefineStack.Count = 1, 'HPreProcessor.Resolve: Found openingif without closing!');
  IfDefines.Free;
  DefineStack.Free;
  Defines.Free;
end;

{ TDirtyClass }

function TDirtyClass.IsDirty : boolean;
begin
  Result := not FClean;
end;

procedure TDirtyClass.SetClean;
begin
  FClean := True;
end;

procedure TDirtyClass.SetDirty;
begin
  FClean := False;
end;

{ TFormHelper }

procedure TFormHelper.SetStayOnTop(const Value : boolean);
begin
  if Value then
      FormStyle := fsStayOnTop
  else
      FormStyle := fsNormal;
end;

{ RDate }

constructor RDate.Create(DateTime : TDateTime);
begin
  self.DateTime := DateTime;
end;

function RDate.Day : Integer;
var
  Year, Month, Day : Word;
begin
  DecodeDate(DateTime, Year, Month, Day);
  Result := Day;
end;

class operator RDate.implicit(a : TDateTime) : RDate;
begin
  Result.DateTime := a;
end;

function RDate.Month : Integer;
var
  Year, Month, Day : Word;
begin
  DecodeDate(DateTime, Year, Month, Day);
  Result := Month;
end;

function RDate.Year : Integer;
var
  Year, Month, Day : Word;
begin
  DecodeDate(DateTime, Year, Month, Day);
  Result := Year;
end;

function RDate.ToString(FormatString : string) : string;
begin
  DateTimeToString(Result, FormatString, DateTime);
end;

{ RSuperPointer<T> }

procedure RSuperPointer<T>.Clamp(var OffsetX, OffsetY : Integer);
begin
  OffsetX := Max(0, Min(OffsetX, Width - 1));
  OffsetY := Max(0, Min(OffsetY, Height - 1));
end;

constructor RSuperPointer<T>.Create(Memory : Pointer);
begin
  self.FWidth := 0;
  self.FHeight := 0;
  self.FCount := 0;
  self.Memory := Memory;
  self.FOwnsPointer := False;
end;

constructor RSuperPointer<T>.Create2D(Memory : Pointer; Width, Height : Integer);
begin
  self.FWidth := Width;
  self.FHeight := Height;
  self.FCount := Width * Height;
  self.Memory := Memory;
  self.FOwnsPointer := False;
end;

constructor RSuperPointer<T>.CreateMem(Count : Integer);
begin
  {$IFDEF SUPERPOINTER_ASSERTS}
  Assert(Count > 0, 'RSuperPointer<T>.CreateMem: Try to allocate zero memory.');
  {$ENDIF}
  self.FWidth := 0;
  self.FHeight := 0;
  self.FCount := Count;
  self.FOwnsPointer := True;
  GetMem(self.Memory, FCount * SizeOf(T));
end;

constructor RSuperPointer<T>.CreateMem2D(Size : RIntVector2);
begin
  self.CreateMem2D(Size.X, Size.Y);
end;

constructor RSuperPointer<T>.CreateMem2D(Width, Height : Integer);
begin
  {$IFDEF SUPERPOINTER_ASSERTS}
  Assert(Width * Height > 0, 'RSuperPointer<T>.CreateMem2D: Try to allocate zero memory.');
  {$ENDIF}
  self.FWidth := Width;
  self.FHeight := Height;
  self.FCount := Width * Height;
  self.FOwnsPointer := True;
  GetMem(self.Memory, FCount * SizeOf(T));
end;

procedure RSuperPointer<T>.Free;
begin
  {$IFDEF SUPERPOINTER_ASSERTS}
  // Assert((FCount > 0) and FOwnsPointer, 'RSuperPointer<T>.Free: Never allocated memory to be freed.');
  {$ENDIF}
  if FOwnsPointer and (FCount > 0) then
      FreeMem(self.Memory, FCount * SizeOf(T));
end;

function RSuperPointer<T>.GetDataSize : UInt64;
begin
  Result := FCount * SizeOf(T);
end;

function RSuperPointer<T>.GetSize : RIntVector2;
begin
  Result.X := FWidth;
  Result.Y := FHeight;
end;

class operator RSuperPointer<T>.implicit(a : RSuperPointer<T>) : Pointer;
begin
  Result := a.Memory;
end;

function RSuperPointer<T>.ReadValue(Offset : Integer) : T;
var
  MovedPointer : PT;
begin
  {$IFDEF SUPERPOINTER_ASSERTS}
  Assert((FCount <= 0) or ((Offset >= 0) and (Offset < FCount)), 'RSuperPointer<T>.ReadValue: Read out of bounds!');
  {$ENDIF}
  MovedPointer := Memory;
  inc(MovedPointer, Offset);
  Result := MovedPointer^;
end;

function RSuperPointer<T>.ReadValue2D(OffsetX, OffsetY : Integer) : T;
var
  MovedPointer : PT;
begin
  {$IFDEF SUPERPOINTER_ASSERTS}
  Assert((FCount <= 0) or ((OffsetX >= 0) and (OffsetX < FWidth) and (OffsetY >= 0) and (OffsetY < FHeight)), 'RSuperPointer<T>.ReadValue2D: Read out of bounds!');
  {$ENDIF}
  MovedPointer := Memory;
  inc(MovedPointer, OffsetX + OffsetY * FWidth);
  Result := MovedPointer^;
end;

procedure RSuperPointer<T>.WriteValue(Offset : Integer; const Value : T);
var
  MovedPointer : PT;
begin
  {$IFDEF SUPERPOINTER_ASSERTS}
  Assert((FCount <= 0) or ((Offset >= 0) and (Offset < FCount)), 'RSuperPointer<T>.WriteValue: Write out of bounds!');
  {$ENDIF}
  MovedPointer := Memory;
  inc(MovedPointer, Offset);
  MovedPointer^ := Value;
end;

procedure RSuperPointer<T>.WriteValue2D(OffsetX, OffsetY : Integer; const Value : T);
var
  MovedPointer : PT;
begin
  {$IFDEF SUPERPOINTER_ASSERTS}
  Assert((FCount <= 0) or ((OffsetX >= 0) and (OffsetX < FWidth) and (OffsetY >= 0) and (OffsetY < FHeight)), 'RSuperPointer<T>.WriteValue2D: Write out of bounds!');
  {$ENDIF}
  MovedPointer := Memory;
  inc(MovedPointer, OffsetX + OffsetY * FWidth);
  MovedPointer^ := Value;
end;

{ RRange<T> }

constructor RRange.Create(const Minimum, Maximum : Single);
begin
  self.Minimum := Min(Minimum, Maximum);
  self.Maximum := Max(Minimum, Maximum);
end;

function RRange.EnsureRange(const Value : Single) : Single;
begin
  Result := Math.EnsureRange(Value, Minimum, Maximum);
end;

function RRange.InRange(const Value : Single) : boolean;
begin
  Result := Math.InRange(Value, Minimum, Maximum);
end;

class function RRange.MaxRange : RRange;
begin
  Result.Minimum := Single.MinValue;
  Result.Maximum := Single.MaxValue;
end;

{ RParam }

/// ////////////////////////////////////////////////////////////////////////////
/// To RParam Conversion
/// ////////////////////////////////////////////////////////////////////////////

class operator RParam.implicit(const a : RColor) : RParam;
begin
  Result.FColor := a;
  Result.FSize := SizeOf(RColor);
  Result.FType := ptRColor;
  Result.FHeapData := nil;
end;

class operator RParam.implicit(const a : RVector3) : RParam;
begin
  Result.FVector3 := a;
  Result.FSize := SizeOf(RVector3);
  Result.FType := ptRVector3;
  Result.FHeapData := nil;
end;

class operator RParam.implicit(a : Integer) : RParam;
begin
  Result.FInteger := a;
  Result.FSize := SizeOf(Integer);
  Result.FType := ptInteger;
  Result.FHeapData := nil;
end;

class operator RParam.implicit(a : TObject) : RParam;
begin
  Result.FObject := a;
  Result.FSize := SizeOf(TObject);
  Result.FType := ptTObject;
  Result.FHeapData := nil;
end;

class operator RParam.implicit(const a : string) : RParam;
begin
  Result.FHeapData := TStringHeapData.Create(a);
  Result.FSize := 0;
  Result.FType := ptString;
end;

class operator RParam.implicit(a : boolean) : RParam;
begin
  Result.FBoolean := a;
  Result.FSize := SizeOf(boolean);
  Result.FType := ptBoolean;
  Result.FHeapData := nil;
end;

class operator RParam.implicit(a : Single) : RParam;
begin
  Result.FSingle := a;
  Result.FSize := SizeOf(Single);
  Result.FType := ptSingle;
  Result.FHeapData := nil;
end;

class operator RParam.implicit(const a : RIntVector2) : RParam;
begin
  Result.FIntVector2 := a;
  Result.FSize := SizeOf(RIntVector2);
  Result.FType := ptRIntVector2;
  Result.FHeapData := nil;
end;

class operator RParam.implicit(const a : RVector2) : RParam;
begin
  Result.FVector2 := a;
  Result.FSize := SizeOf(RVector2);
  Result.FType := ptRVector2;
  Result.FHeapData := nil;
end;

class operator RParam.equal(const a, b : RParam) : boolean;
begin
  Result := False;
  if (a.FType = b.FType) then
  begin
    case a.FType of
      ptEmpty : Result := True;
      ptUnknown :
        begin
          if assigned(a.FHeapData) or assigned(b.FHeapData) then
              raise ENotImplemented.Create('RParam.equal: Unknown heapdata not implemented yet.');
          Result := (a.GetSize = b.GetSize) and CompareMem(a.GetRawDataPointer, b.GetRawDataPointer, a.GetSize);
        end;
      ptInteger, ptSingle, ptBoolean,
        ptPointer, ptTObject, ptRVector3, ptRVector2,
        ptRColor, ptRIntVector2, ptByte : Result := CompareMem(a.GetRawDataPointer, b.GetRawDataPointer, a.GetSize);
      ptString : Result := a.AsString = b.AsString;
      ptArray : raise ENotImplemented.Create('RParam.equal: Array not implemented yet.');
      ptMethod : raise ENotImplemented.Create('RParam.equal: Method not implemented yet.');
    end;
  end;
end;

class operator RParam.notequal(const a, b : RParam) : boolean;
begin
  Result := not(a = b)
end;

class operator RParam.explicit(a : Byte) : RParam;
begin
  Result.FByte := a;
  Result.FSize := SizeOf(Byte);
  Result.FType := ptByte;
  Result.FHeapData := nil;
end;

function RParam.IsEmpty : boolean;
begin
  Result := (FType = ptEmpty) or ((FSize <= 0) and not assigned(FHeapData));
end;

function RParam.IsType<T> : boolean;
begin
  Result := False;
  if FType = ptEmpty then Exit();
  if FType = ptUnknown then
  begin
    Result := TypeInfo(T) = FUnknownType;
  end;
end;

procedure RParam.SerializeIntoStream(Stream : TStream);
var
  str : string;
begin
  Stream.WriteAny<EnumParameterType>(DataType);
  case DataType of
    // if String SizeOfString + lengthCounter(using word)
    ptString :
      begin
        // convention -> string save length in a word with correct length not a byte
        str := AsString;
        Assert(Length(str) <= high(Word));
        Stream.WriteAny<Word>(Length(str));
        if Length(str) > 0 then
            Stream.Write(str[1], Length(str) * SizeOf(char));
      end;
  else
    begin
      // first save datalength
      Assert(Size <= high(Byte));
      Stream.WriteByte(Size);
      // after that save data
      Stream.WriteData(GetRawDataPointer, Size);
    end;
  end;
end;

function RParam.ToString : string;
var
  val : TValue;
begin
  case FType of
    ptEmpty : Result := 'Empty';
    ptUnknown :
      begin
        Result := 'Unknown';
        if assigned(FUnknownType) then
        begin
          TValue.Make(GetRawDataPointer, FUnknownType, val);
          Result := val.ToString;
        end;
      end;
    ptInteger : Result := IntToStr(FInteger);
    ptSingle : Result := FormatFloat('0.##', FSingle);
    ptBoolean : Result := BoolToStr(FBoolean, True);
    ptPointer : Result := NativeUInt(FPointer).ToString;
    ptTObject : Result := 'Object';
    ptRVector3 : Result := FVector3;
    ptRVector2 : Result := FVector2;
    ptRColor : Result := FColor.toHexString;
    ptString : Result := AsString;
    ptArray : Result := 'Array';
    ptRIntVector2 : Result := FIntVector2;
    ptMethod : Result := 'Method';
    ptByte : Result := IntToStr(FByte);
  else Result := 'No stringhandler for Paramtype ' + HRTTI.EnumerationToString<EnumParameterType>(FType);
  end;
end;

class function RParam.From<T>(Value : T) : RParam;
begin
  // if RParam can contain type complete save data in variablefield
  if SizeOf(T) <= MAXSTACKSIZE then
  begin
    Result.FSize := SizeOf(T);
    Move(Value, Result.FByte, Result.FSize);
    Result.FHeapData := nil;
  end
  // else allocate heapdata save data
  else
  begin
    Result.FSize := 0;
    Result.FHeapData := TAnyHeapData<T>.Create(Value);
  end;
  Result.FUnknownType := TypeInfo(T);
  Result.FType := ptUnknown;
end;

class function RParam.FromProc<T>(const proc : T) : RParam;
begin
  Result.FSize := 0;
  Result.FHeapData := TAnyHeapData<T>.Create(proc);
  Result.FType := ptMethod;
end;

class function RParam.FromArray<ElementType>(Value : TArray<ElementType>) : RParam;
begin
  Result.FHeapData := TArrayHeapData<ElementType>.Create(Value);
  Result.FSize := 0;
  Result.FType := ptArray;
end;

class function RParam.FromInteger(Value : Integer) : RParam;
begin
  Result := Value;
end;

class function RParam.FromRawData(RawData : Pointer; RawDataSize : Integer) : RParam;
begin
  // if RParam can contain type complete save data in variablefield
  if RawDataSize <= MAXSTACKSIZE then
  begin
    Result.FSize := RawDataSize;
    Move(RawData^, Result.FByte, Result.FSize);
    Result.FHeapData := nil;
  end
  // else allocate heapdata with size of T to save data
  else
  begin
    Result.FSize := 0;
    Result.FHeapData := TRawHeapData.CreateFromRawData(RawData, RawDataSize);
  end;
  Result.FType := ptUnknown;
end;

class function RParam.FromString(const Value : string) : RParam;
begin
  Result.FHeapData := TStringHeapData.Create(Value);
  Result.FSize := 0;
  Result.FType := ptString;
end;

class function RParam.FromTValue(const Value : TValue) : RParam;
begin
  Result.FHeapData := nil;
  case Value.Kind of
    tkInteger, tkRecord, tkEnumeration, tkFloat, tkSet, tkInt64 : Result := RParam.FromRawData(Value.GetReferenceToRawData, Value.DataSize);
    tkClass : Result := Value.AsObject;
    tkString, tkLString, tkWString, tkUString : Result := Value.AsString;
    tkMethod, tkVariant, tkArray, tkChar, tkClassRef, tkWChar, tkDynArray, tkInterface, tkPointer,
      tkProcedure, tkUnknown : raise EConvertError.Create('RParam.FromTValue: Can''t can convert TValue to RParam - Type "' + HRTTI.EnumerationToString<TTypeKind>(Value.Kind) + '" not supported!');
  end;
end;

class function RParam.FromWithType<T>(const Value : T) : RParam;
var
  valueTypeInfo : Pointer;
  valueType : TTypeKind;
begin
  valueTypeInfo := TypeInfo(T);
  if valueTypeInfo = TypeInfo(boolean) then Exit(PBoolean(@Value)^);
  valueType := PTypeInfo(valueTypeInfo).Kind;
  case valueType of
    tkClass, tkUnknown, tkEnumeration, tkSet : Result := RParam.From<T>(Value);
    tkInteger : Result := PInteger(@Value)^;
    tkFloat : Result := PSingle(@Value)^;
    tkString : Result := PString(@Value)^;
    tkUString : Result := PUnicodeString(@Value)^;
    tkMethod, tkProcedure : Result := RParam.FromProc<T>(Value);
    tkRecord :
      begin
        if valueTypeInfo = TypeInfo(RVector2) then Result := PRVector2(@Value)^
        else if valueTypeInfo = TypeInfo(RVector3) then Result := PRVector3(@Value)^
        else if valueTypeInfo = TypeInfo(RIntVector2) then Result := PRIntVector2(@Value)^
        else if valueTypeInfo = TypeInfo(RColor) then Result := PColor(@Value)^
        else Result := RParam.From<T>(Value);
      end;
    tkPointer : Result := PPointer(@Value)^;
  else
    begin
      Assert(False, 'RParam.FromWithType<T>: Unsupported Type!');
      Result := RPARAMEMPTY;
    end;
  end;
end;

function RParam.GetRawDataPointer : Pointer;
begin
  if assigned(FHeapData) then
      Result := FHeapData.GetRawDataPointer
  else Result := @FByte;
end;

function RParam.GetSize : Integer;
begin
  if FSize > 0 then Result := FSize
  else
  begin
    if assigned(FHeapData) then Result := FHeapData.GetSize
    else Result := 0;
  end;
end;

/// ////////////////////////////////////////////////////////////////////////////
/// From RParam to Type Conversion
/// ////////////////////////////////////////////////////////////////////////////

class procedure RParam.ExpectType(Expected, Given : EnumParameterType; AllowOther : boolean = True);
var
  AllowedTypes : set of EnumParameterType;
begin
  if AllowOther then AllowedTypes := [Expected, ptUnknown, ptEmpty]
  else AllowedTypes := [Expected];
  if not(Given in AllowedTypes) then
      raise ETypeMissmatch.Create(Format('Type "%s" expected but type "%s" found.', [HRTTI.EnumerationToString<EnumParameterType>(Expected), HRTTI.EnumerationToString<EnumParameterType>(Given)]));
end;

class operator RParam.explicit(const a : string) : RParam;
begin
  Result.FHeapData := TStringHeapData.Create(a);
  Result.FSize := 0;
  Result.FType := ptString;
end;

function RParam.AsArray<ElementType> : TArray<ElementType>;
var
  ElementCount : Integer;
begin
  if GetSize <= 0 then Exit(nil);
  {$IFDEF DEBUG}
  if not(FType in [ptArray, ptUnknown]) then raise ETypeMissmatch.Create(Format('Type "%s" expected but type "%s" found.', [HRTTI.EnumerationToString<EnumParameterType>(ptArray), HRTTI.EnumerationToString<EnumParameterType>(FType)]));
  {$ENDIF}
  if FType = ptArray then
  begin
    Assert(assigned(FHeapData));
    if FHeapData is TArrayHeapData<ElementType> then
        Result := TArrayHeapData<ElementType>(FHeapData).Data
    else if FHeapData is TRawHeapData then
        Result := TRawHeapData(FHeapData).AsArray<ElementType>
    else Assert(False);
  end
  else
  // array created from raw data
  begin
    // prepare array
    ElementCount := GetSize div SizeOf(ElementType);
    Assert(GetSize mod SizeOf(ElementType) = 0);
    Assert(HMath.InRange(ElementCount, 0, MaxInt));
    SetLength(Result, ElementCount);
    // copy rawdata to new typed array
    Move(GetRawDataPointer^, Result[0], GetSize);
  end;
end;

function RParam.AsBoolean : boolean;
begin
  {$IFDEF DEBUG}
  ExpectType(ptBoolean, FType);
  {$ENDIF}
  Result := FBoolean;
end;

function RParam.AsBooleanDefaultTrue : boolean;
begin
  Result := IsEmpty or AsBoolean;
end;

function RParam.AsByte : Byte;
begin
  {$IFDEF DEBUG}
  ExpectType(ptByte, FType);
  {$ENDIF}
  Result := FByte;
end;

function RParam.AsEnumType<T> : T;
begin
  {$IFDEF DEBUG}
  if not(FType in [ptEmpty, ptUnknown, ptInteger, ptByte]) then raise ETypeMissmatch.Create(Format('RParam.AsEnumType<T>: Type "%s" was for enumtype not expected!', [HRTTI.EnumerationToString<EnumParameterType>(FType)]));
  {$ENDIF}
  if FType = ptEmpty then Result := default (T)
  else
  begin
    {$IFDEF DEBUG}
    Assert(SizeOf(T) <= GetSize);
    Assert(GetSize <= MAXSTACKSIZE);
    {$ENDIF}
    // enumtype everytime saved directly
    Move(FByte, Result, SizeOf(T));
  end;
end;

function RParam.AsInteger : Integer;
begin
  {$IFDEF DEBUG}
  ExpectType(ptInteger, FType);
  {$ENDIF}
  Result := FInteger;
end;

function RParam.AsIntegerDefault(DefaultValue : Integer) : Integer;
begin
  {$IFDEF DEBUG}
  ExpectType(ptInteger, FType);
  {$ENDIF}
  if IsEmpty then Result := DefaultValue
  else Result := FInteger;
end;

function RParam.AsIntVector2 : RIntVector2;
begin
  {$IFDEF DEBUG}
  ExpectType(ptRIntVector2, FType);
  {$ENDIF}
  Result := FIntVector2;
end;

function RParam.AsProc<T> : T;
begin
  {$IFDEF DEBUG}
  if not(ptMethod = FType) then raise ETypeMissmatch.Create(Format('Type "ptMethod" expected but type "%s" found.', [HRTTI.EnumerationToString<EnumParameterType>(FType)]));
  Assert(assigned(FHeapData));
  Assert(FHeapData is TAnyHeapData<T>);
  {$ENDIF}
  Result := TAnyHeapData<T>(FHeapData).FData;
end;

function RParam.AsSetType<T> : T;
var
  ResultSize, DataSize : Integer;
  MinimumSize : Integer;
begin
  if FType = ptEmpty then Result := default (T)
  else
  begin
    ResultSize := SizeOf(T);
    DataSize := GetSize;
    // when sets are binary exchanged between 32 und 64bit applications, data is not compatible and need some adjustement
    if DataSize <> ResultSize then
    begin
      MinimumSize := Min(ResultSize, DataSize);
      {$IFDEF DEBUG}
      Assert(MinimumSize in [5, 6, 7]);
      Assert(not assigned(FHeapData));
      {$ENDIF}
      // clear result memory, it is possible that existing data not overwrite complete result memory
      Result := default (T);
      // compatibly mode is applied for DataSize < 8 Byte, an this will always fit in local stack
      Move(FByte, Result, MinimumSize);
    end
    else
    begin
      {$IFDEF DEBUG}
      Assert(DataSize = ResultSize);
      {$ENDIF}
      // types <= MAXSTACKSIZE are saved directly in varsection
      if DataSize <= MAXSTACKSIZE then Move(FByte, Result, DataSize)
        // for other types heapmemory is allocated
      else
      begin
        Assert(assigned(FHeapData));
        if (FHeapData is TRawHeapData) then
            Result := TRawHeapData(FHeapData).GetData<T>
        else
        begin
          Assert(FHeapData is TAnyHeapData<T>);
          Result := TAnyHeapData<T>(FHeapData).FData;
        end;
      end;
    end;
  end;
end;

function RParam.AsSingle : Single;
begin
  {$IFDEF DEBUG}
  ExpectType(ptSingle, FType);
  {$ENDIF}
  Result := FSingle;
end;

function RParam.AsSingleDefault(DefaultValue : Single) : Single;
begin
  {$IFDEF DEBUG}
  ExpectType(ptSingle, FType);
  {$ENDIF}
  if IsEmpty then Result := DefaultValue
  else Result := FSingle;
end;

function RParam.AsString : string;
var
  StringLength : Integer;
begin
  {$IFDEF DEBUG}
  ExpectType(ptString, FType);
  {$ENDIF}
  if (FType = ptEmpty) or (GetSize = 0) then Result := ''
  else if FType = ptString then
  begin
    {$IFDEF DEBUG}
    Assert(assigned(FHeapData));
    Assert(FHeapData is TStringHeapData);
    {$ENDIF}
    Result := TStringHeapData(FHeapData).FData;
  end
  else
  // string created from raw data
  begin
    // prepare array
    StringLength := GetSize div SizeOf(char);
    Assert(GetSize mod SizeOf(char) = 0);
    Assert(HMath.InRange(StringLength, 0, MaxInt));
    SetLength(Result, StringLength);
    // copy rawdata to new typed array
    Move(GetRawDataPointer^, Result[1], GetSize);
  end;
end;

function RParam.AsType<T> : T;
begin
  {$IFDEF DEBUG}
  if (FType in [ptString, ptArray, ptMethod]) then raise ETypeMissmatch.Create(Format('RParam.AsType<T>: For type "%s" generic method should not used!', [HRTTI.EnumerationToString<EnumParameterType>(FType)]));
  {$ENDIF}
  if FType = ptEmpty then Result := default (T)
  else
  begin
    {$IFDEF DEBUG}
    Assert(GetSize = SizeOf(T));
    {$ENDIF}
    // types <= MAXSTACKSIZE are saved directly in varsection
    if GetSize <= MAXSTACKSIZE then Move(FByte, Result, FSize)
      // for other types heapmemory is allocated
    else
    begin
      Assert(assigned(FHeapData));
      if (FHeapData is TRawHeapData) then
          Result := TRawHeapData(FHeapData).GetData<T>
      else
      begin
        Assert(FHeapData is TAnyHeapData<T>);
        Result := TAnyHeapData<T>(FHeapData).FData;
      end;
    end;
  end;
end;

function RParam.AsTypeDefault<T>(const DefaultValue : T) : T;
begin
  if IsEmpty then Result := DefaultValue
  else Result := AsType<T>;
end;

function RParam.AsVector2 : RVector2;
begin
  {$IFDEF DEBUG}
  ExpectType(ptRVector2, FType);
  {$ENDIF}
  Result := FVector2;
end;

function RParam.AsVector2Default(const DefaultValue : RVector2) : RVector2;
begin
  if IsEmpty then Result := DefaultValue
  else Result := AsVector2;
end;

function RParam.AsVector3 : RVector3;
begin
  {$IFDEF DEBUG}
  ExpectType(ptRVector3, FType);
  {$ENDIF}
  Result := FVector3;
end;

function RParam.AsVector3Default(const DefaultValue : RVector3) : RVector3;
begin
  if IsEmpty then Result := DefaultValue
  else Result := AsVector3;
end;

class function RParam.DeserializeFromStream(Stream : TStream) : RParam;
var
  DataLength : Byte;
  str : string;
  StringLength : Word;
  Buffer : TArray<Byte>;
  DataType : EnumParameterType;
begin
  DataType := Stream.ReadAny<EnumParameterType>;
  // convention, if datalength = 0, string expected
  if DataType = ptString then
  begin
    StringLength := Stream.ReadWord;
    if StringLength > 0 then
    begin
      SetLength(str, StringLength);
      Stream.Read(str[1], StringLength * SizeOf(char));
    end
    else
        str := '';
    Result := str;
  end
  else
  begin
    DataLength := Stream.ReadByte;
    SetLength(Buffer, DataLength);
    Stream.Read(Buffer, DataLength);
    Result := RParam.FromRawData(@Buffer[0], DataLength);
  end;
  // arrays normally lies only on heap, but this method put them into stack if fitting, so we need raw mode
  if DataType = ptArray then Result.FType := ptUnknown
  else Result.FType := DataType;
end;

{ TStringHeapData }

constructor TStringHeapData.Create(Data : string);
begin
  FData := Data;
end;

function TStringHeapData.GetRawDataPointer : Pointer;
begin
  if Length(FData) <= 0 then Result := nil
  else Result := @FData[1];
end;

function TStringHeapData.GetSize : Integer;
begin
  Result := SizeOf(char) * Length(FData);
end;

{ TArrayHeapData<T> }

constructor TArrayHeapData<T>.Create(Data : TArray<T>);
begin
  FData := Data;
end;

function TArrayHeapData<T>.GetRawDataPointer : Pointer;
begin
  if Length(FData) <= 0 then Result := nil
  else Result := @FData[0];
end;

function TArrayHeapData<T>.GetSize : Integer;
begin
  Result := SizeOf(T) * Length(FData);
end;

{ TAnyHeapData }

function TRawHeapData.AsArray<T> : TArray<T>;
begin
  Assert(Length(FData) mod SizeOf(T) = 0);
  SetLength(Result, Length(FData) div SizeOf(T));
  Move(FData[0], Result[0], Length(FData));
end;

constructor TRawHeapData.CreateFromRawData(Data : Pointer; Size : Integer);
begin
  SetLength(FData, Size);
  Move(Data^, FData[0], Size);
end;

destructor TRawHeapData.Destroy;
begin
  FData := nil;
  inherited;
end;

function TRawHeapData.GetData<T> : T;
begin
  Assert(SizeOf(T) = GetSize);
  Move(FData[0], Result, Length(FData));
end;

function TRawHeapData.GetRawDataPointer : Pointer;
begin
  Result := @FData[0];
end;

function TRawHeapData.GetSize : Integer;
begin
  Result := Length(FData);
end;

{ TAnyHeapData<T> }

constructor TAnyHeapData<T>.Create(Data : T);
begin
  FData := Data;
end;

function TAnyHeapData<T>.GetRawDataPointer : Pointer;
begin
  Result := @FData;
end;

function TAnyHeapData<T>.GetSize : Integer;
begin
  Result := SizeOf(T);
end;

{ TFastStack<T> }

constructor TFastStack<T>.Create(MaxSize : Integer);
begin
  SetLength(FStack, MaxSize);
  FStackSize := 0;
end;

function TFastStack<T>.Peek : T;
begin
  {$IFDEF DEBUG}
  Assert(FStackSize > 0, 'TFastStack<T>.Peek: Stack runned out of bounds!');
  {$ENDIF}
  Result := FStack[FStackSize - 1];
end;

function TFastStack<T>.Pop : T;
begin
  {$IFDEF DEBUG}
  Assert(FStackSize > 0, 'TFastStack<T>.Pop: Stack runned out of bounds!');
  {$ENDIF}
  dec(FStackSize);
  Result := FStack[FStackSize];
end;

procedure TFastStack<T>.PopRemove;
begin
  {$IFDEF DEBUG}
  Assert(FStackSize > 0, 'TFastStack<T>.PopRemove: Stack runned out of bounds!');
  {$ENDIF}
  dec(FStackSize);
end;

procedure TFastStack<T>.Push(const Value : T);
begin
  {$IFDEF DEBUG}
  Assert(FStackSize < Length(FStack), 'TFastStack<T>.Push: Stack runned out of bounds!');
  {$ENDIF}
  FStack[FStackSize] := Value;
  inc(FStackSize);
end;

{ TValueHelper }

function TValueHelper.AsSet : SetByte;
begin
  Result := [];
  Assert(DataSize <= SizeOf(SetByte));
  ExtractRawDataNoCopy(@Result);
end;

procedure TValueHelper.Assign(const Path : string; const Value : TValue; Params : array of TValue; StrongParameterMatching : boolean);
var
  PathParts : TArray<string>;
  FieldName, ShortedPath : string;
  ObjectValue : TValue;
  InstanceType : TRttiType;
  AField : TRttiField;
  AProperty : TRttiProperty;
begin
  if Path.IsEmpty then
      raise ECustomTValueError.Create('TValueHelper.Assign: Can only assign field/property a value, else the value would replace the TValue content itself.');
  // extract property/field name by get last item
  PathParts := Path.Split(['.']);
  FieldName := PathParts[Length(PathParts) - 1];
  HArray.Delete<string>(PathParts, Length(PathParts) - 1);
  ShortedPath := string.Join('.', PathParts);
  // resolve remaining path to get object that has the field to which the value will assigened
  if not ShortedPath.IsEmpty then
      ObjectValue := self.Resolve(ShortedPath, Params, StrongParameterMatching)
  else
      ObjectValue := self;
  if ObjectValue.IsObject then
  begin
    InstanceType := ObjectValue.GetRttiType;
    if InstanceType.TryGetField(FieldName, AField) then
        AField.SetValue(ObjectValue.AsObject, Value)
    else if InstanceType.TryGetProperty(FieldName, AProperty) then
        AProperty.SetValue(ObjectValue.AsObject, Value)
    else raise ENotFoundException.CreateFmt('TValueHelper.Assign: Field/Property "%s" could not find in type "%s"',
        [FieldName, InstanceType.Name]);
  end
  else
      raise EUnsupportedException.Create('TValueHelper.Assign: Assign operations is only supported for fields/properties of objects.');
end;

function TValueHelper.CompareValue(const AnotherValue : TValue) : Integer;
begin
  if self.IsOrdinal and AnotherValue.IsOrdinal then
  begin
    Result := System.Math.CompareValue(self.AsOrdinal, AnotherValue.AsOrdinal);
  end
  else
    if self.IsNumeric and AnotherValue.IsNumeric then
  begin
    Result := System.Math.CompareValue(self.AsExtended, AnotherValue.AsExtended);
  end
  else
    if self.IsString and AnotherValue.IsString then
  begin
    Result := string.CompareText(self.AsString, AnotherValue.AsString);
  end
  else
  begin
    raise EOperandTypeMissmatch.CreateFmt('%s: Can''t compare "%s" and "%s"',
      ['TValueHelper.CompareValue', self.GetTypeName, AnotherValue.GetTypeName]);
  end;
end;

function TValueHelper.Contains(const AValue : TValue; CaseInsensitive : boolean) : boolean;
var
  AItem : TValue;
  i : Integer;
begin
  if AValue.IsEmpty or self.IsEmpty then Result := False
  else if self.IsString and AValue.IsString then
  begin
    if CaseInsensitive then
        Result := self.AsString.ToLowerInvariant.Contains(AValue.AsString.ToLowerInvariant)
    else
        Result := self.AsString.Contains(AValue.AsString);
  end
  else
    case self.Kind of
      tkSet :
        begin
          if AValue.IsOrdinal then
              Result := AValue.AsOrdinal in self.AsSet
            // set in set -> all elements in first set has to be in second set
          else if AValue.Kind = tkSet then
              Result := AValue.AsSet <= self.AsSet
          else
              raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Contains: Only ordinal or set values are supported as first operand for in set, found type "%s".', [AValue.GetRttiType.Name]);
        end;
      tkDynArray, tkArray :
        begin
          Result := False;
          for i := 0 to self.GetArrayLength - 1 do
            if AValue.SameValue(self.GetArrayElement(i), CaseInsensitive) then
                Exit(True);
        end;
      tkClass, tkRecord :
        begin
          if self.GetRttiType.HasMethod('GetEnumerator') then
          begin
            Result := False;
            for AItem in TValueEnumerator.Create(self) do
              if AValue.SameValue(AItem, CaseInsensitive) then
                  Exit(True);
          end
          else
              raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Contains: Type "%s" does not implement GetEnumerator. It''s required for contains operation.', [self.GetRttiType.Name]);
        end
    else
      raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Contains: Type "%s" does not support contains operator.', [self.GetRttiType.Name]);
    end;
end;

function TValueHelper.GetRttiType : TRttiType;
begin
  if IsClass and not IsEmpty then
      Result := Context.GetType(AsClass)
  else
      Result := Context.GetType(TypeInfo);
end;

function TValueHelper.GetSimpleHashValue : Integer;
begin
  if self.IsString then
      Result := THashBobJenkins.GetHashValue(self.AsString)
  else if self.IsOrdinal then
      Result := self.AsOrdinal mod Integer.MaxValue
  else
      Result := THashBobJenkins.GetHashValue(self.GetReferenceToRawData^, self.DataSize);
end;

function TValueHelper.GetTypeName : string;
var
  RttiType : TRttiType;
begin
  RttiType := self.GetRttiType;
  if assigned(RttiType) then
      Result := RttiType.Name
  else
      Result := 'Unknown';
end;

function TValueHelper.Intersect(const SetValue : TValue) : TValue;
var
  aSet : SetByte;
begin
  if self.IsSet and SetValue.IsSet then
  begin
    aSet := self.AsSet * SetValue.AsSet;
    TValue.Make(@aSet, System.TypeInfo(SetByte), Result);
  end
  else raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Intersect: Operand intersect is for "%s" and "%s" not supported.',
      [self.GetRttiType.Name, SetValue.GetRttiType.Name]);
end;

function TValueHelper.IsFloat : boolean;
begin
  Result := IsEmpty or (Kind = tkFloat);
end;

function TValueHelper.IsInteger : boolean;
begin
  Result := IsEmpty or (Kind in [tkInteger, tkInt64]);
end;

function TValueHelper.IsSet : boolean;
begin
  Result := IsEmpty or (Kind = tkSet);
end;

function TValueHelper.IsString : boolean;
begin
  Result := IsEmpty or (Kind in [tkChar, tkString, tkWChar, tkLString, tkWString, tkUString]);
end;

function TValueHelper.Add(const AnotherValue : TValue) : TValue;
begin
  if self.IsEmpty and AnotherValue.IsEmpty then
      Result := TValue.Empty
  else if self.IsInteger and AnotherValue.IsInteger then
      Result := self.AsInteger + AnotherValue.AsInteger
  else if self.IsNumeric and AnotherValue.IsNumeric then
      Result := self.AsExtended + AnotherValue.AsExtended
  else if self.IsString and AnotherValue.IsString then
      Result := self.AsString + AnotherValue.AsString
  else raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Add: Operand add is for "%s" and "%s" not supported.',
      [self.GetRttiType.Name, AnotherValue.GetRttiType.Name]);
end;

function TValueHelper.Subtract(const AnotherValue : TValue) : TValue;
begin
  if self.IsEmpty and AnotherValue.IsEmpty then
      Result := TValue.Empty
  else if self.IsInteger and AnotherValue.IsInteger then
      Result := self.AsInteger - AnotherValue.AsInteger
  else if self.IsNumeric and AnotherValue.IsNumeric then
      Result := self.AsExtended - AnotherValue.AsExtended
  else raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Subtract: Operand subtract is for "%s" and "%s" not supported.',
      [self.GetRttiType.Name, AnotherValue.GetRttiType.Name]);
end;

function TValueHelper.ToArray : TArray<TValue>;
var
  i : Integer;
begin
  if self.IsEmpty then
      Result := []
  else if self.IsArray then
  begin
    SetLength(Result, self.GetArrayLength);
    for i := 0 to self.GetArrayLength - 1 do
    begin
      Result[i] := self.GetArrayElement(i);
    end;
  end
  else
      Result := [self];
end;

function TValueHelper.ToArray<T> : TArray<T>;
var
  i : Integer;
begin
  if self.IsEmpty then
      Result := []
  else if self.IsArray then
  begin
    SetLength(Result, self.GetArrayLength);
    for i := 0 to self.GetArrayLength - 1 do
    begin
      Result[i] := self.GetArrayElement(i).AsType<T>;
    end;
  end
  else
      Result := [self.AsType<T>];
end;

function TValueHelper.Divide(const AnotherValue : TValue) : TValue;
begin
  if self.IsEmpty and AnotherValue.IsEmpty then
      Result := TValue.Empty
  else if self.IsNumeric and AnotherValue.IsNumeric then
      Result := self.AsExtended / AnotherValue.AsExtended
  else raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Divide: Operand divide is for "%s" and "%s" not supported.',
      [self.GetRttiType.Name, AnotherValue.GetRttiType.Name]);
end;

function TValueHelper.Multiply(const AnotherValue : TValue) : TValue;
begin
  if self.IsEmpty and AnotherValue.IsEmpty then
      Result := TValue.Empty
  else if self.IsInteger and AnotherValue.IsInteger then
      Result := self.AsInteger * AnotherValue.AsInteger
  else if self.IsNumeric and AnotherValue.IsNumeric then
      Result := self.AsExtended * AnotherValue.AsExtended
  else raise EOperandTypeMissmatch.CreateFmt('TValueHelper.Multiply: Operand multiply is for "%s" and "%s" not supported.',
      [self.GetRttiType.Name, AnotherValue.GetRttiType.Name]);
end;

function TValueHelper.Resolve(const Path : string; Params : array of TValue; StrongParameterMatching : boolean) : TValue;
var
  Tokens : TList<string>;
  Token : string;
  CurrentType : TRttiType;
  CurrentItem : TValue;
  ParameterIndex : Integer;
  Parameter : TArray<TValue>;

  function ReadNextToken : string;
  begin
    Tokens.Delete(0);
    if Tokens.Count > 0 then
        Token := Tokens.First
    else
        Token := string.Empty;
    Result := Token;
  end;

  function NextToken : string;
  begin
    if Tokens.Count >= 2 then
        Result := Tokens[1]
    else
        Result := string.Empty;
  end;

  function ParseMethod(const MethodName : string) : TValue;
  var
    Method : TRttiMethod;
    Param : TRTTIParameter;
    ParameterCount, i : Integer;
  begin
    Method := CurrentType.GetMethod(MethodName);
    ParameterCount := 0;
    if NextToken = '(' then
    begin
      // pop "("
      ReadNextToken;
      // read ")" or parameter_name
      while ReadNextToken <> ')' do
        if not(Token = ',') then
        begin
          if Token = '(' then
              raise EQueryResolveError.CreateFmt('TValueHelper.Resolve: Does not support innercalls for methods. Path "%s" is buggy.', [Path]);
          inc(ParameterCount);
        end;
    end;
    // only test parameter count is equal if no differences allowed
    if StrongParameterMatching and not(Method.ParameterCount = ParameterCount) then
        raise EQueryResolveError.CreateFmt('TValueHelper.Resolve: Method "%s" expect %d parameters, but %d parameter has been declared. Path "%s" is buggy.',
        [Method.Name, Method.ParameterCount, ParameterCount, Path])
    else
      if Method.ParameterCount > ParameterCount then
        raise EQueryResolveError.CreateFmt('TValueHelper.Resolve: Method "%s" expect %d parameters, but %d parameter has been declared. Path "%s" is buggy.',
        [Method.Name, Method.ParameterCount, ParameterCount, Path]);
    Assert(ParameterIndex + ParameterCount <= Length(Parameter));
    i := 0;
    // check whether passed parameters are matching methods parameters
    for Param in Method.GetParameters do
    begin
      if (Param.ParamType.TypeKind <> Parameter[i].Kind) and not Parameter[i].IsEmpty then
          raise EQueryResolveError.CreateFmt('TValueHelper.Resolve: Method "%s" expect as %dth paramater a %s, but %s was given. Path "%s" is buggy.',
          [Method.Name, i, Param.ParamType.QualifiedName, Parameter[i].TypeInfo.Name, Path]);
      inc(i);
    end;
    // use real parametercount here, because it could differ from indicated count
    Result := Method.Invoke(CurrentItem, Copy(Parameter, ParameterIndex, Method.ParameterCount));
    // consume use parameters
    ParameterIndex := ParameterIndex + ParameterCount;
  end;

  function ParseField(const FieldName : string) : TValue;
  var
    Member : TRttiMemberUnified;
  begin
    Member := TRttiMemberUnified.Create(CurrentType.GetField(FieldName));
    Result := Member.GetValue(CurrentItem);
    Member.Free;
  end;

  function ParseProperty(const PropertyName : string) : TValue;
  var
    Member : TRttiMemberUnified;
  begin
    Member := TRttiMemberUnified.Create(CurrentType.GetProperty(PropertyName));
    Result := Member.GetValue(CurrentItem);
    Member.Free;
  end;

begin
  Parameter := HArray.ConvertDynamicToTArray(Params);
  // step through the FieldDescriptor
  Tokens := TList<string>.Create();
  Tokens.AddRange(HString.Split(Path, ['.', '(', ',', ')'], True));
  CurrentItem := self;
  ParameterIndex := 0;
  if Tokens.Count > 0 then
      Token := Tokens.First;
  while (Tokens.Count > 0) and (not CurrentItem.IsEmpty) do
  begin
    // ignore point fieldnames, because this is caused by '..' '.field' or 'field.'
    // and is interpreted as access the current field or item itself
    if (Token <> '.') and (Token <> '') then
    begin
      if not HArray.Contains(['(', ',', ')'], Token) then
      begin
        CurrentType := CurrentItem.GetRttiType;
        if CurrentType.HasField(Token) then
            CurrentItem := ParseField(Token)
        else if CurrentType.HasProperty(Token) then
            CurrentItem := ParseProperty(Token)
        else if CurrentType.HasMethod(Token) then
            CurrentItem := ParseMethod(Token)
        else raise ECustomTValueError.CreateFmt('TValueHelper.Resolve: In type "%s" no field/property/method with ' +
            'name "%s" was found, Path "%s" is buggy.', [CurrentType.Name, Token, Path]);
      end
      else
          raise ECustomTValueError.CreateFmt('TValueHelper.Resolve: Unexpected Token "%s" for FieldName. Path "%s" is buggy.', [Token, Path]);
    end;
    ReadNextToken;
  end;
  Result := CurrentItem;
  Tokens.Free;
end;

function TValueHelper.SameValue(const AnotherValue : TValue; CaseInsensitive : boolean) : boolean;
begin
  if self.IsEmpty or AnotherValue.IsEmpty then
  begin
    Result := self.IsEmpty and AnotherValue.IsEmpty;
  end
  else if self.IsOrdinal and AnotherValue.IsOrdinal then
  begin
    Result := self.AsOrdinal = AnotherValue.AsOrdinal;
  end
  else if self.IsNumeric and AnotherValue.IsNumeric then
  begin
    Result := System.Math.SameValue(self.AsExtended, AnotherValue.AsExtended);
  end
  else if self.IsString and AnotherValue.IsString then
  begin
    if CaseInsensitive then
        Result := SameText(self.AsString, AnotherValue.AsString)
    else
        Result := self.AsString = AnotherValue.AsString;
  end
  else if self.IsSet and AnotherValue.IsSet then
  begin
    Result := self.AsSet = AnotherValue.AsSet;
  end
  else if self.IsObject and AnotherValue.IsObject then
  begin
    Result := self.AsObject = AnotherValue.AsObject;
  end
  else if self.IsClass and AnotherValue.IsClass then
  begin
    Result := self.AsClass = AnotherValue.AsClass;
  end
  else if (self.IsRecord and AnotherValue.IsRecord) and (self.TypeInfo = AnotherValue.TypeInfo) then
  begin
    if self.DataSize = AnotherValue.DataSize then
        Result := CompareMem(self.GetReferenceToRawData, AnotherValue.GetReferenceToRawData, self.DataSize)
    else Result := False;
  end
  else if self.IsObject and AnotherValue.IsClass then
  begin
    Result := self.IsInstanceOf(AnotherValue.AsClass);
  end
  else
  begin
    raise ENotSupportedException.CreateFmt('TValueHelper.SameValue: Can''t compare "%s" and "%s"',
      [self.GetTypeName, AnotherValue.GetTypeName]);
  end;
end;

function TValueHelper.IsNumeric : boolean;
begin
  Result := IsEmpty or (Kind in [tkInteger, tkChar, tkEnumeration, tkFloat, tkWChar, tkInt64]);
end;

function TValueHelper.IsOrdinalOrSet : boolean;
begin
  Result := Kind in [tkInteger, tkChar, tkWChar, tkEnumeration, tkInt64, tkSet];
end;

function TValueHelper.IsRecord : boolean;
begin
  Result := Kind = tkRecord;
end;

{ TValueEnumerator }

constructor TValueEnumerator.Create(const EnumerableValue : TValue);
var
  Enumerator : TValue;
begin
  Assert(EnumerableValue.Kind in [tkClass, tkRecord, tkInterface, tkArray, tkDynArray]);
  if EnumerableValue.GetRttiType.HasMethod('GetEnumerator') then
  begin
    FIsArray := False;
    Enumerator := EnumerableValue.GetRttiType.GetMethod('GetEnumerator').Invoke(EnumerableValue, []);
    FEnumeratorInstance := Enumerator.AsObject;
    FMoveNextMethod := Enumerator.GetRttiType.GetMethod('MoveNext');
    FCurrentProperty := Enumerator.GetRttiType.GetProperty('Current');
  end
  else if EnumerableValue.Kind in [tkArray, tkDynArray] then
  begin
    FIsArray := True;
    FArrayValue := EnumerableValue;
    FArrayIndex := -1;
  end
  else raise EHRttiError.CreateFmt('TValueEnumerator.Create: Type "%s" has no method "GetEnumerator" in  or is array type.', [EnumerableValue.GetRttiType.Name]);
end;

destructor TValueEnumerator.Destroy;
begin
  FEnumeratorInstance.Free;
  inherited;
end;

function TValueEnumerator.DoGetCurrent : TValue;
begin
  if FIsArray then
      Result := FArrayValue.GetArrayElement(FArrayIndex)
  else
      Result := FCurrentProperty.GetValue(FEnumeratorInstance);
end;

function TValueEnumerator.DoMoveNext : boolean;
var
  Args : TArray<TValue>;
begin
  if FIsArray then
  begin
    if FArrayIndex >= FArrayValue.GetArrayLength then
        Exit(False);
    inc(FArrayIndex);
    Result := FArrayIndex < FArrayValue.GetArrayLength;
  end
  else
  begin
    Args := [];
    Result := FMoveNextMethod.Invoke(FEnumeratorInstance, Args).AsBoolean;
  end;
end;

function TValueEnumerator.GetEnumerator : TEnumerator<TValue>;
begin
  Result := self;
end;

{ TContentManager.TContentObserverThread }

constructor TContentManager.TContentObserverThread.Create(ObservedContent : TThreadSafeObjectDictionary<string, TManagedFile>;
CheckTime : int64);
begin
  FObservedContent := ObservedContent;
  FObservationEnabled := False;
  FCheckTime := TThreadSafeData<int64>.Create(CheckTime);
  inherited Create(False);
end;

destructor TContentManager.TContentObserverThread.Destroy;
begin
  inherited;
  FCheckTime.Free;
end;

procedure TContentManager.TContentObserverThread.Execute;
var
  Entry : TManagedFile;
  SharedContent : TObjectDictionary<string, TManagedFile>;
  Timestamp, Diff : LongWord;
  CheckTime : int64;
  DirtyEntries : TList<TManagedFile>;
begin
  DirtyEntries := TList<TManagedFile>.Create;
  while not Terminated do
  begin
    Timestamp := Gettickcount;
    if ObservationEnabled then
    begin

      // threadsafe check if content has changed
      SharedContent := FObservedContent.SharedLock;
      try
        // deferred entry cleandirty call, so all calls are made in one synchronized step and
        for Entry in SharedContent.Values do
          if not Entry.UpToDate then DirtyEntries.Add(Entry);
        // iterate is done, next step don't need entries anymore
        FObservedContent.SharedUnlock;
        if DirtyEntries.Count > 0 then
        begin
          DoSynchronized(
            procedure
            var
              Entry : TManagedFile;
            begin
              for Entry in DirtyEntries do
                  Entry.CleanDirty;
            end);
        end;
      except
        on e : Exception do
        begin
          HLog.Write(elWarning, 'ContentManager hot reload failed with %s', [e.ToString]);
        end;
      end;
      DirtyEntries.Clear;
    end;
    // ensure that thread waits with next observe check round, until set time is elapsed
    CheckTime := FCheckTime.GetDataSafe;

    Diff := Gettickcount - Timestamp;
    while (Diff < CheckTime) and not Terminated do
    begin
      Diff := Gettickcount - Timestamp;
      Sleep(50);
    end;
  end;
  DirtyEntries.Free;
end;

procedure TContentManager.TContentObserverThread.SetCheckTime(const Value : int64);
begin
  FCheckTime.SetDataSafe(Value);
end;

initialization

TTimeManager.Initialize;
TimeManager := TTimeManager.Create;
TTimeMeasurement.Initialize;
ContentManager := TContentManager.Create(1000);
HInternationalizer.Init;
FormatSettings.DecimalSeparator := '.';

finalization

FreeAndNil(ContentManager);
TTimeMeasurement.Finalize;
TimeManager.Free;
HInternationalizer.Finalize;

end.
