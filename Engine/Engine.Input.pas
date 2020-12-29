unit Engine.Input;

interface

uses
  DirectInput,
  Windows,
  JwaWinUser,
  JwaWinType,
  Engine.Log,
  Classes,
  SysUtils,
  Math,
  Generics.Defaults,
  Generics.Collections,
  Vcl.Forms,
  Messages,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Math.Collision2D;

const
  GIDC_ARRIVAL = 1;
  GIDC_REMOVAL = 2;

  BITMASK_BUTTONDOWN   = 1;
  BITMASK_BUTTONUP     = 2;
  BITMASK_BUTTONISDOWN = 4;

  DIMOUSEBUFFERSIZE          = 1024;
  DIKEYBOARDBUFFERSIZE       = 32;
  DIGAMECONTROLLERBUFFERSIZE = 32;

  HOOK_MARKER = 39;

  RAWINPUTIGNORLIST : array [0 .. 1] of string       = (('RDP_MOU'), ('RDP_KBD'));
  KEYBOARDSCANCODEIGNORLIST : array [0 .. 0] of word = ((170));

type
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  ERawInputException = class(Exception);

  EControllerDeviceNotFoundException = class(Exception);

  EnumMouseButton = (mbNone, mbLeft, mbRight, mbMiddle, mbExtra1, mbExtra2, mbExtra3, mbExtra4);
  SetMouseButton = set of EnumMouseButton;
  EnumKeyboardKey = (
    TasteNone,
    TasteEsc,
    Taste1,
    Taste2,
    Taste3,
    Taste4,
    Taste5,
    Taste6,
    Taste7,
    Taste8,
    Taste9,
    Taste0,
    Tasteß,
    TasteAkzent,
    TasteRücktaste,
    TasteTabulator,
    TasteQ,
    TasteW,
    TasteE,
    TasteR,
    TasteT,
    TasteZ,
    TasteU,
    TasteI,
    TasteO,
    TasteP,
    TasteÜ,
    TastePlus,
    TasteEnter,
    TasteSTRGLinks,
    TasteA,
    TasteS,
    TasteD,
    TasteF,
    TasteG,
    TasteH,
    TasteJ,
    TasteK,
    TasteL,
    TasteÖ,
    TasteÄ,
    TasteZirkumflex,
    TasteShiftLinks,
    TasteRaute,
    TasteY,
    TasteX,
    TasteC,
    TasteV,
    TasteB,
    TasteN,
    TasteM,
    TasteKomma,
    TastePunkt,
    TasteMinus,
    TasteShiftRechts,
    TasteNumMultiplikation,
    TasteAltLeft,
    TasteLeerTaste,
    TasteFeststelltaste,
    TasteF1,
    TasteF2,
    TasteF3,
    TasteF4,
    TasteF5,
    TasteF6,
    TasteF7,
    TasteF8,
    TasteF9,
    TasteF10,
    TasteNumLock,
    TasteRollen,
    TasteNum7,
    TasteNum8,
    TasteNum9,
    TasteNumMinus,
    TasteNum4,
    TasteNum5,
    TasteNum6,
    TasteNumPlus,
    TasteNum1,
    TasteNum2,
    TasteNum3,
    TasteNum0,
    TasteNumKomma,
    Taste084,
    Taste085,
    Taste086,
    TasteF11,
    TasteF12,
    Taste089,
    Taste090,
    Taste091,
    Taste092,
    Taste093,
    Taste094,
    Taste095,
    Taste096,
    Taste097,
    Taste098,
    Taste099,
    Taste100,
    Taste101,
    Taste102,
    Taste103,
    Taste104,
    Taste105,
    Taste106,
    Taste107,
    Taste108,
    Taste109,
    Taste110,
    Taste111,
    Taste112,
    Taste113,
    Taste114,
    Taste115,
    Taste116,
    Taste117,
    Taste118,
    Taste119,
    Taste120,
    Taste121,
    Taste122,
    Taste123,
    Taste124,
    Taste125,
    Taste126,
    Taste127,
    Taste128,
    Taste129,
    Taste130,
    Taste131,
    Taste132,
    Taste133,
    Taste134,
    Taste135,
    Taste136,
    Taste137,
    Taste138,
    Taste139,
    Taste140,
    Taste141,
    Taste142,
    Taste143,
    Taste144,
    Taste145,
    Taste146,
    Taste147,
    Taste148,
    Taste149,
    Taste150,
    Taste151,
    Taste152,
    Taste153,
    Taste154,
    Taste155,
    TasteNumEnter,
    TasteSTRGRechts,
    Taste158,
    Taste159,
    Taste160,
    Taste161,
    Taste162,
    Taste163,
    Taste164,
    Taste165,
    Taste166,
    Taste167,
    Taste168,
    Taste169,
    Taste170,
    Taste171,
    Taste172,
    Taste173,
    Taste174,
    Taste175,
    Taste176,
    Taste177,
    Taste178,
    Taste179,
    Taste180,
    TasteNumDivision,
    Taste182,
    TasteDruck,
    TasteAltGr,
    Taste185,
    Taste186,
    Taste187,
    Taste188,
    Taste189,
    Taste190,
    Taste191,
    Taste192,
    Taste193,
    Taste194,
    Taste195,
    Taste196,
    Taste197,
    Taste198,
    TastePOS1,
    TastePfeilOben,
    TasteBildOben,
    Taste202,
    TastePfeilLinks,
    Taste204,
    TastePfeilRechts,
    Taste206,
    TasteEnde,
    TastePfeilUnten,
    Taste209,
    Taste210,
    TasteEntf,
    Taste212,
    Taste213,
    Taste214,
    Taste215,
    Taste216,
    Taste217,
    Taste218,
    Taste219,
    Taste220,
    Taste221,
    Taste222,
    Taste223,
    Taste224,
    Taste225,
    Taste226,
    Taste227,
    Taste228,
    Taste229,
    Taste230,
    Taste231,
    Taste232,
    Taste233,
    Taste234,
    Taste235,
    Taste236,
    Taste237,
    Taste238,
    Taste239,
    Taste240,
    Taste241,
    Taste242,
    Taste243,
    Taste244,
    Taste245,
    Taste246,
    Taste247,
    Taste248,
    Taste249,
    Taste250,
    Taste251,
    Taste252,
    Taste253,
    Taste254,
    Taste255);
  SetKeyboard = set of EnumKeyboardKey;

const

  AllKeys : SetKeyboard            = [low(EnumKeyboardKey) .. high(EnumKeyboardKey)];
  AllMouseButtons : SetMouseButton = [low(EnumMouseButton) .. high(EnumMouseButton)];

type

  TInputDevice = class
    protected
      /// <summary> Refreshes the data of this input device. Only used for polling devices.</summary>
      procedure Idle; virtual;
    public
  end;

  /// <summary> The super class of all different kinds of keyboards. </summary>
  TKeyboard = class abstract(TInputDevice)
    protected type
      ProcDataChange = procedure(Key : EnumKeyboardKey; Up : boolean) of object;
    protected
      // saves modified keyboard data {ScanCode: Data as Bitmask}
      FKeyData : TDictionary<word, word>;
      FDataFromLastFrame : TList<TPair<EnumKeyboardKey, boolean>>;
      constructor Create;
      // deletes all past events of the data list (e.g. up and down, but not isDown)
      procedure CleanKeyData;
      function GetLastKeyDown : TList<EnumKeyboardKey>;
      function GetLastKeyIsDown : TList<EnumKeyboardKey>;
      function GetLastKeyUp : TList<EnumKeyboardKey>;
    public
      /// <summary> Called for all keyboard events. </summary>
      OnDataChange : ProcDataChange;
      /// <summary> Delete all current states of the buttons. Helpful when the mainform get the focus.  </summary>
      procedure CleanButtonState;
      /// <summary> Contains all keyboardevent from last frame. </summary>
      property DataFromLastFrame : TList < TPair < EnumKeyboardKey, boolean >> read FDataFromLastFrame;
      /// <summary> A list of all keys which have been pressed down since the last update. </summary>
      property LastKeysDown : TList<EnumKeyboardKey> read GetLastKeyDown;
      /// <summary> A list of all released keys since the last update. </summary>
      property LastKeysUp : TList<EnumKeyboardKey> read GetLastKeyUp;
      /// <summary> A list of all keys which are hold down at the moment. </summary>
      property LastKeysIsDown : TList<EnumKeyboardKey> read GetLastKeyIsDown;
      /// <summary> Returns for a key whether it was pressed down since the last update. </summary>
      function KeyDown(Taste : EnumKeyboardKey) : boolean;
      /// <summary> Returns for a button whether it was released since the last update. </summary>
      function KeyUp(Taste : EnumKeyboardKey) : boolean;
      /// <summary> Returns for a button whether it is hold down at the moment. </summary>
      function KeyIsDown(Taste : EnumKeyboardKey) : boolean;
      /// <summary> Returns true if any key of the set is down </summary>
      function AnyKeyIsDown(Keys : SetKeyboard) : boolean;
      /// <summary> Returns true if any key of the set have been released since the last update. </summary>
      function AnyKeyUp(Keys : SetKeyboard) : boolean;
      /// <summary> Returns whether left or right Strg-Key is hold down. </summary>
      function Strg : boolean;
      /// <summary> Returns whether the alt key is hold down. </summary>
      function Alt : boolean;
      /// <summary> Returns whether the altgr key is hold down. </summary>
      function AltGr : boolean;
      /// <summary> Returns whether left or right Shift-Key is hold down. </summary>
      function Shift : boolean;
      /// <summary> Returns true if any key changed it's state or is pressed. </summary>
      function HasAnyKeyActivity : boolean;
      class function KeyToString(Key : EnumKeyboardKey) : string; static;
      destructor Destroy; override;
  end;

  /// <summary> A dummy keyboard without any funcionality. Used as default. </summary>
  TDummyKeyboard = class(TKeyboard)

  end;

  EnumMouseButtonFrameState = (mbsUp, mbsDown, mbsIsDown);
  SetMouseButtonFrameState = set of EnumMouseButtonFrameState;

  /// <summary> The super class of all different kinds of mice. </summary>
  TMouse = class abstract(TInputDevice)
    protected type
      ProcDataChange = procedure(Sender : TMouse) of object;
    private
      function GetDeltaPosition : RIntVector2;
    protected
      FX, FY, FZ, FdX, FdY, FdZ : integer;
      FMouseButton : array [EnumMouseButton] of SetMouseButtonFrameState;
      FAcceleration, FSensitivity : single;
      FDragPosition : RIntVector2;
      FDragging, FWasDragging : boolean;
      function GetPosition : RIntVector2;
      procedure Idle; override;
      procedure SetPosition(const Value : RIntVector2);
      procedure OnChange;
      constructor Create;
      procedure ClearOneFrameStates;
    public
      /// <summary> The minimal pixel-distance for the cursor to move to be regarded as dragging. </summary>
      MinimalDragDistance : integer;
      /// <summary> Called for all mouse events. </summary>
      OnDataChange : ProcDataChange;
      /// <summary> Limits the cursor to this rectangle. The position is clamped to the borders. </summary>
      ClipRect : RRect;
      /// <summary> X-Coordinate of the cursor. </summary>
      property X : integer read FX;
      /// <summary> Y-Coordinate of the cursor. </summary>
      property Y : integer read FY;
      /// <summary> Current cursor position. </summary>
      property Position : RIntVector2 read GetPosition write SetPosition;
      /// <summary> Positional difference since last update. </summary>
      property DeltaPosition : RIntVector2 read GetDeltaPosition;
      /// <summary> Absolute position of the mouse wheel. </summary>
      property Z : integer read FZ;
      /// <summary> Positional difference of the x-axis since last update. </summary>
      property dX : integer read FdX;
      /// <summary> Positional difference of the y-axis since last update. </summary>
      property dY : integer read FdY;
      /// <summary> Difference of the mouse wheel since last update. </summary>
      property dZ : integer read FdZ;
      /// <summary> Set the Accelerationlevel for mousemovement. This value will
      /// accelerate fast movement and decelerated slow movements (small delta)
      /// Hint: Only affect X and Y axis, not the Z axis</summary>
      property Acceleration : single read FAcceleration write FAcceleration;
      /// <summary> Set the Sensitivitylevel for mousemovement. The value direct scale all
      /// movement. So default value = 1, > 1 speed up, < 1 slow down
      /// Hint: Only affect X and Y axis, not the Z axis</summary>
      property Sensitivity : single read FSensitivity write FSensitivity;
      /// <summary> Returns for a button whether it was pressed down since the last update. </summary>
      function ButtonDown(MouseButton : EnumMouseButton) : boolean;
      /// <summary> Returns for a button whether it was released since the last update. </summary>
      function ButtonUp(MouseButton : EnumMouseButton) : boolean;
      /// <summary> Returns for a button whether it is hold down at the moment. </summary>
      function ButtonIsDown(MouseButton : EnumMouseButton) : boolean;
      /// <summary> Returns whether a mousebutton is down and has been moved further the the minimal drag distance. </summary>
      property IsDragging : boolean read FDragging;
      /// <summary> Same as dragging except it return the state before the last update. </summary>
      property WasDragging : boolean read FWasDragging;
      /// <summary> Returns true when no button is hold down, else false. </summary>
      function AllButtonsUp(Buttons : SetMouseButton) : boolean;
      /// <summary> Returns true if any button was pressed down since the last update. </summary>
      function AnyButtonDown(Buttons : SetMouseButton) : boolean;
      /// <summary> Returns true if any button is hold down. </summary>
      function AnyButtonIsDown(Buttons : SetMouseButton) : boolean;
      /// <summary> Returns true if any button changed it's state or is pressed. </summary>
      function HasAnyButtonActivity : boolean;
      class function ButtonToString(Button : EnumMouseButton) : string; static;
  end;

  /// <summary> A mouse without any funcionality. Used as default. </summary>
  TDummyMouse = class(TMouse)

  end;

  RBinding = record
    KeyboardKeyCode : EnumKeyboardKey;
    MouseKeyCode : EnumMouseButton;
    Strg, Alt, Shift : boolean;
    constructor Create(KeyboardKeyCode : EnumKeyboardKey); overload;
    constructor Create(MouseKeyCode : EnumMouseButton); overload;
    function IsEmpty : boolean;
    function WithShift : RBinding;
    function WithAlt : RBinding;
    function WithStrg : RBinding;
    function IsEqual(const R : RBinding) : boolean;
    function ToString : string;
    function ToStringRaw : string;
    function SaveToString : string;
    constructor CreateFromString(const Value : string);
    class function EMPTY : RBinding; static;
  end;

  TKeybindingManager<T : record { :Enum }> = class
    protected
      FMouse : TMouse;
      FKeyboard : TKeyboard;
      FMapping : TObjectDictionary<T, TList<RBinding>>;
      FBlocks : TDictionary<T, boolean>;
    public
      /// <summary> Returns for a key whether it was pressed down since the last update. </summary>
      function KeyDown(const Key : T) : boolean;
      /// <summary> Returns for a button whether it was released since the last update. </summary>
      function KeyUp(const Key : T) : boolean;
      /// <summary> Returns for a button whether it is hold down at the moment. </summary>
      function KeyIsDown(const Key : T) : boolean;
      procedure AddMapping(const Key : T; const Binding : RBinding); overload;
      procedure AddMapping(const Key : T; Binding : array of RBinding); overload;
      procedure SetMapping(const Key : T; Index : integer; const Binding : RBinding);
      function GetMapping(const Key : T; Index : integer) : RBinding;
      procedure RemoveMapping(const Key : T; Index : integer);
      procedure BlockBindings(const Keys : array of T);
      procedure UnblockBindings(const Keys : array of T);
      function IsKeyBlocked(const Key : T) : boolean;
      constructor Create(Mouse : TMouse; Keyboard : TKeyboard);
      destructor Destroy; override;
  end;

  TGameController = class(TInputDevice)
    protected const
      MAXBUTTONCOUNT = 32;
    protected
      FLXAxis : single;
      FLYAxis : single;
      FVAxis : single;
      FUAxis : single;
      FRXAxis : single;
      FRYAxis : single;
      FDigiPad : single;
      FButtonState : array [0 .. MAXBUTTONCOUNT - 1] of word;
      function GetLeftStick : RVector2;
      function GetRightStick : RVector2;
    public
      /// <summary> Absolute position for x-axis of, commonly left, possibly another, stick.
      /// Valuerange: -1..1 (-1 deflection to left, 0 no deflection, 1 deflection to right)</summary>
      property LXAxis : single read FLXAxis;
      /// <summary> Absolute position for y-axis of, commonly left, possibly another, stick.
      /// Valuerange: -1..1 (-1 deflection to left, 0 no deflection, 1 deflection to right)</summary>
      property LYAxis : single read FLYAxis;
      property LeftStick : RVector2 read GetLeftStick;
      property RXAxis : single read FRXAxis;
      property RYAxis : single read FRYAxis;
      property RightStick : RVector2 read GetRightStick;
      property UAxis : single read FUAxis;
      property VAxis : single read FVAxis;
      property DigiPad : single read FDigiPad;
      /// <summary> Return for a button if it pressed down since last query (=last idle)
      /// <param name="Button">Buttonnumber e.g. 0, 1, 2 ...</param></summary>
      function GCButtonDown(Button : integer) : boolean;
      /// <summary> Return for a button if it released since last query (=last idle)
      /// <param name="Button">Buttonnumber e.g. 0, 1, 2 ...</param></summary>
      function GCButtonUp(Button : integer) : boolean;
      function GCButtonIsDown(Button : integer) : boolean;
  end;

  TGameControllerDirectInput = class(TGameController)
    private const
      MAXAXISDEFLECTION = high(word);
    protected
      // speichert die Factory von dem die Maus kommt, um sich beim Löschen austragen zu können
      FDirectInputFactory : TObject;
      FGameControllerDevice : IDirectInputDevice8;
      constructor Create(GamecontrollerGUID : TGUID; handle : hwnd; DirectInputFactory : TObject; DirectInput : IDirectInput8; ExklusiverZugriff : boolean);
      procedure Idle; override;
      procedure VerarbeiteDaten(DIGameControllerDaten : TDIDEVICEOBJECTDATA);
      procedure MaintainButtonArray();
    public
      destructor Destroy; override;
  end;

  TMouseDirectInput = class(TMouse)
    protected
      // speichert die Factory von dem die Maus kommt, um sich beim Löschen austragen zu können
      FDirectInputFactory : TObject;
      FMausDevice : IDirectInputDevice8;
      constructor Create(handle : hwnd; DirectInputFactory : TObject; DirectInput : IDirectInput8; ExklusiverZugriff : boolean);
      procedure Idle; override;
      procedure VerarbeiteDaten(DIMausDaten : TDIDEVICEOBJECTDATA);
    public
      destructor Destroy; override;
  end;

  TKeyboardDirectInput = class(TKeyboard)
    protected
      // speichert die Factory von dem die Tastatur kommt, um sich beim Löschen austragen zu können
      FDirectInputFactory : TObject;
      FTastaturDevice : IDirectInputDevice8;
      constructor Create(handle : hwnd; DirectInputFactory : TObject; DirectInput : IDirectInput8; ExklusiverZugriff : boolean);
      procedure Idle; override;
      procedure VerarbeiteDaten(DITastaturDaten : TDIDEVICEOBJECTDATA);
    public
      destructor Destroy; override;
  end;

  /// <summary> Handle zu einem beliebigen (RawInput-)Eingabegerät.</summary>
  RRawInputDeviceHandle = record
    private const
      MAXHANDLES = 10;
    private
      FHandleCount : integer;
    public
      name : string;
      // speichert die Handles, die zu diesem Gerät gehören
      // use static array to prevent memoryleak in record
      HandleID : array [0 .. MAXHANDLES - 1] of hwnd;
      class operator Implicit(A : RRawInputDeviceHandle) : string; inline;
      // gibt eine Record mit den Werten zurück
      constructor Create(name : string; HandleID : array of hwnd);
      function ContainsHandle(handle : hwnd) : boolean;
      procedure AddHandle(handle : hwnd);
  end;

  TInputDeviceManager = class;

  TMouseRaw = class(TMouse)
    private
      procedure SetBeinflusstSystemMaus(const Value : boolean);
    protected
      FRRawInputDeviceHandle : RRawInputDeviceHandle;
      FBeinflusstSystemMaus : boolean;
      // speichert die Factory von dem die Maus kommt, um sich beim Löschen austragen zu können
      FRawInputFactory : TObject;
      // Konstruktor, darf keiner benutzen, da die Klasse über der Factory erstellen werden muss
      constructor Create(RawInputFactory : TObject; RawInputGeräteHandle : RRawInputDeviceHandle; BeinflusstSystemMaus : boolean);
      // füllt die Maus mit Daten ankommend aus den RawInputDaten
      procedure VerarbeiteDaten(RawInputDaten : tagRAWINPUT);
      // gibt das Record mit gefüllten Daten zurück
      function GetInputDaten : tagINPUT;
    public
      /// <summary> Wenn der Wert True ist, beeinflusst die Bewegung der Maus auch die
      /// Systemmaus. Bei mehreren Mäusen ist es daher oft sinnvoll nur eine Maus dazu zu erklären. </summary>
      property BeeinflusstSystemMaus : boolean read FBeinflusstSystemMaus write SetBeinflusstSystemMaus;
      destructor Destroy; override;
  end;

  TKeyboardRaw = class(TKeyboard)
    protected
      FRRawInputDeviceHandle : RRawInputDeviceHandle;
      // speichert die Factory von dem die Tastatur kommt, um sich beim Löschen austragen zu können
      FRawInputFactory : TObject;
      // Konstruktor, darf keiner benutzen, da die Klasse über der Factory erstellen werden muss
      constructor Create(RawInputFactory : TObject; RawInputGeräteHandle : RRawInputDeviceHandle);
      // konvertiert die Scancodes aus RawInput zu DirectInput konformen Scancodes
      function KonvertiereScanCode(ScanCode, Flags : word) : word;
      // füllt die Tastatur mit Daten ankommend aus den RawInputDaten
      procedure VerarbeiteDaten(RawInputDaten : tagRAWINPUT);
      procedure Idle; override;
    public
  end;

  TRawInputDeviceList = class
    protected
      FRawInputGeräte : TList<RRawInputDeviceHandle>;
      // GeräteTyp gibt an nach welchen Geräten gefiltert werden soll, z.B RIM_TYPEKEYBOARD
      constructor Create(GeräteTyp : Byte);
    public
      /// <summary>Liste mit Handels aller angeschlossenen Geräte (eines bestimmten Typs)
      /// (wichtig um Zugriff auf dieses Gerät zu erhalten) </summary>
      property RawInputGeräte : TList<RRawInputDeviceHandle> read FRawInputGeräte;
      /// <summary>Gibt die Liste der Geräte in Stringrepräsentation wieder (als TStringList).</summary>
      function GetStringList : TStringList;
      destructor Destroy; override;
  end;

  /// <summary> Describe the datasource for inputdata</summary>
  EnumInputDataType = (
    idt0D,  // Button/Keys like ESC, Button_1 or Mouse_Left
    idt1D,  // One Axis like mouse wheel or speed wheel on joystick
    idt2D); // Two Axis like mouse or stick on gamepad

  EnumInputStatusChange = (isMove, isDown, isUp);

  TInputHeapData = record
    private
      FID : integer;
      FStatusChange : EnumInputStatusChange;
      FDataType : EnumInputDataType;
    public
      property DataID : integer read FID;
      property DataType : EnumInputDataType read FDataType;
      property StatusChange : EnumInputStatusChange read FStatusChange;
      function ToString : string;

  end;

  TInputHeap = class
    private
    public

  end;

  TDeviceList = class

  end;

  DIDeviceDesc = DIDEVICEINSTANCE;

  /// <summary> Der EingabeManager bietet die Möglichkeit Instanzen zum Zugriff auf die Eingabegeräte
  /// die an das System angeschlossen sind zu erstellen und verwaltet diese Instanzen.
  /// </summary>
  TInputDeviceManager = class
    protected type
      TDirectInputFactory = class
        protected
          FHandle : hwnd;
          FDirectInput : IDirectInput8;
          FMausDirectInputListe : TObjectList<TMouseDirectInput>;
          FTastaturDirectInputListe : TObjectList<TKeyboardDirectInput>;
          // speichert alle herausgegebenen Geräte von DirectInput (wichtig für Idle)
          FGeräteDirectInputListe : TObjectList<TInputDevice>;
          constructor Create(handle : hwnd);
        public
          /// <summary> Erstellt den Zugriff auf die Maus über DirectInput (DirectX)
          /// dabei werden alle angeschlossenen Mäuse als eine Maus aufgefasst </summary>
          /// <param name="ExklusiverZugriff"> Wenn True werden alle Mauseingaben nur von DirectInput verabeitet, die anderen Anwendungen bekommen nix mehr ab</param>
          function ErzeugeTMouseDirectInput(ExklusiverZugriff : boolean) : TMouse;
          /// <summary> Erstellt den Zugriff auf die Tastatur über DirectInput (DirectX)
          /// dabei werden alle angeschlossenen Tastaturen als eine aufgefasst </summary>
          /// <param name="ExklusiverZugriff"> Wenn True werden alle Tastatureingaben nur von DirectInput verabeitet, die anderen Anwendungen bekommen nix mehr ab</param>
          function ErzeugeTKeyboardDirectInput(ExklusiverZugriff : boolean) : TKeyboard;
          /// <summary> Return a list of all connected gamecontrollers</summary>
          function GetConnectedGamecontroller : TList<DIDeviceDesc>;
          /// <summary> Erstellt den Zugriff auf den GameController über DirectInput (DirectX)
          /// dabei werden alle angeschlossenen GameController als einer aufgefasst </summary>
          /// <param name="ExklusiverZugriff"> Wenn True werden alle GameControllereingaben nur von DirectInput verabeitet, die anderen Anwendungen bekommen nix mehr ab</param>
          function ErzeugeTGameControllerDirectInput(ExklusiverZugriff : boolean; ControllerGUID : TGUID) : TGameController; overload;
          function ErzeugeTGameControllerDirectInput(ExklusiverZugriff : boolean) : TGameController; overload;
          /// <summary> Aktualisiert die Daten für alle Eingabegeräte die über DirectInput angesteuert werden.</summary>
          procedure Idle;
          destructor Destroy; override;
      end;

      TRawInputFactory = class
        protected type
          ProcMausAngeschloßen = procedure(RawInputGeräteHandle : RRawInputDeviceHandle) of object;
          ProcMausAbgesteckt = procedure(Mäuse : TList<TMouse>) of object;
        protected
          FHandle : hwnd;
          // speichert alle herausgegebenen Mäuse
          FMausRawListe : TObjectList<TMouseRaw>;
          // speichert alle herausgegebenen Tastaturen
          FTastaturRawListe : TObjectList<TKeyboardRaw>;
          // wenn True werden auch HIDNachrichten empfangen, wenn die Anwendung nicht den Fokus hat
          FImHintergrundAktiv : boolean;
          // Anzahl der Mäuse die keinen Zugriff auf die SystemMaus haben
          FMäuseOhneSystemZugriff : integer;
          procedure MäuseOhneSystemZugriffIncrement;
          procedure MäuseOhneSystemZugriffDecrement;
          constructor Create(handle : hwnd; ImHintergrundAktiv : boolean);
          // filtert die einkommenden Messages der Anwendung nach wichtigen Messages für RawInput
          procedure MessageHandler(var Msg : Windows.TMsg; var Handled : boolean);
          procedure VerarbeiteWM_Input(Msg : Windows.TMsg);
          procedure VerarbeiteWM_INPUT_DEVICE_CHANGE(Msg : Windows.TMsg);
          // entfernt die Verweise der übergebenen Maus aus der Factory, die Klasse wird dadurch aber nicht freigegeben
          // also nur für die Verwaltung in der Factory
          procedure MausRawFreigeben(Maus : TMouseRaw);
          procedure Idle;
        public
          /// <summary> Das Ereignis wird aufgerufen, wenn eine neue Maus angesteckt wurde.</summary>
          /// <param name="RawInputGeräteHandle"> Der Parameter enthält den Handle für die Maus.
          /// Damit kann über die Factory eine TMouse erzeugt werden. </param>
          OnMausAngeschloßen : ProcMausAngeschloßen;
          /// <summary> Das Ereignis wird aufgerufen, wenn eine Maus abgesteckt, also vom Computer entfernt, wurde.</summary>
          /// <param name="Mäuse"> Der Parameter enthält alle Mausobjekte die vom Abstecken der Maus betroffen sind. </param>
          OnMausMausAbgesteckt : ProcMausAbgesteckt;
          /// <summary> Erstellt den Zugriff auf eine angeschlossene Maus über
          /// RAWInput. Damit ist es möglich mehrere angeschlossene Mäuse einzeln
          /// anzusteuern.</summary>
          /// <param name="Index"> Index der Maus auf die der Zugriff erstellt werden soll. Der Index stimmt mit den Einträgen
          /// aus der MausListe überein.</param>
          /// <param name="BeeinflusstSystemMaus"> Wenn der Wert True ist, beeinflusst die Bewegung der Maus auch die
          /// Systemmaus. Bei mehreren Mäusen ist es daher oft sinnvoll nur eine Maus dazu zu erklären.
          /// HINWEIS!: Ist bei keiner Maus BeeinflusstSystemMaus = True, gibt es keine Möglichkeit mehr den WindowsCursor zu bewegen.</param>
          function ErzeugeTMouseRaw(Index : integer; BeeinflusstSystemMaus : boolean = true) : TMouse; overload;
          /// <summary> Erstellt den Zugriff auf eine angeschlossene Maus über
          /// RAWInput. Damit ist es möglich mehrere angeschlossene Mäuse einzeln
          /// anzusteuern.</summary>
          /// <param name="RawInputGeräteHandle"> Das Gerätehandle dient zur Identifikation der Maus.
          /// Es kann über die MausListe oder das Ereignis OnNeueMaus bezogen werden.</param>
          /// <param name="BeeinflusstSystemMaus"> Wenn der Wert True ist, beeinflusst die Bewegung der Maus auch die
          /// Systemmaus. Bei mehreren Mäusen ist es daher oft sinnvoll nur eine Maus dazu zu erklären.
          /// HINWEIS!: Ist bei keiner Maus BeeinflusstSystemMaus = True, gibt es keine Möglichkeit mehr den WindowsCursor zu bewegen.</param>
          function ErzeugeTMouseRaw(RawInputGeräteHandle : RRawInputDeviceHandle; BeeinflusstSystemMaus : boolean = true) : TMouse; overload;
          /// <summary> Gibt eine Liste mit allen angeschlossenen Mäusen zurück</summary>
          function GeTMouseListe : TRawInputDeviceList;
          /// <summary> Erstellt den Zugriff auf eine angeschlossene Tastatur über
          /// RAWInput. Damit ist es möglich mehrere angeschlossene Tastaturen einzeln
          /// anzusteuern.</summary>
          /// <param name="Index"> Index der Tastatur auf die der Zugriff erstellt werden soll. Der Index stimmt mit den Einträgen
          /// aus der TastaturListe überein.</param>
          function ErzeugeTKeyboardRaw(Index : integer) : TKeyboard; overload;
          /// <summary> Erstellt den Zugriff auf eine angeschlossene Tastatur über
          /// RAWInput. Damit ist es möglich mehrere angeschlossene Tastaturen einzeln
          /// anzusteuern.</summary>
          /// <param name="RawInputGeräteHandle"> Das Gerätehandle dient zur Identifikation der Tastatur.
          /// Es kann über die TastaturListe oder das Ereignis OnNeueTastatur bezogen werden.</param>
          function ErzeugeTKeyboardRaw(RawInputGeräteHandle : RRawInputDeviceHandle) : TKeyboard; overload;
          /// <summary> Gibt eine Liste mit allen angeschlossenen Tastaturen zurück</summary>
          function GetTastaturListe : TRawInputDeviceList;
          destructor Destroy; override;
      end;
    protected
      FHandle : hwnd;
      FDirectInputFactory : TDirectInputFactory;
      FRawInputFactory : TRawInputFactory;
      FImHintergrundAktiv : boolean;
      function GetDirectInputFactory : TDirectInputFactory;
    public
      /// <summary> Richtet den EingabeManager ein </summary>
      /// <param name="ImHintergrundAktiv"> Wenn der Wert True ist, bekommt die Anwendung auch Daten von den Eingabegeräten, selbt
      /// wenn sie sich im Hintergrund befindet (also nicht den Fokus hat). </param>
      /// <param name="FensterHandle"> Über den Handle kann die Eingabe an ein bestimmtes Fenster gebunden werden,
      /// wenn der Handle = 0 ist, sucht sich die Klasse automatisch das Handle.
      /// ACHTUNG!!!! das weglassen des Handles funktioniert wunderbar für RAWInput, jedoch NICHT FÜR DIRECTINPUT.
      /// Werden also Eingabegeräte über DirectInput angesteuert, muss hier ein Wert eingetragen werden.</param>
      constructor Create(ImHintergrundAktiv : boolean = false; FensterHandle : hwnd = 0);
      /// <summary> Über die DirectInputFactory werden alle Eingabegeräte mithifle von
      /// DirectInput erstellt. Alle angeschlossenen Geräte des gleichen Typ (z.B. Maus)
      /// werden dabei zu einem zusammengefasst.</summary>
      property DirectInputFactory : TDirectInputFactory read GetDirectInputFactory;
      /// <summary> Über die RawInputFactory werden alle Eingabegeräte mithifle von
      /// RawInput erstellt. Mit RawInput können alle Geräte des gleichen Typ einzeln
      /// angesprochen werden.</summary>
      property RawInputFactory : TRawInputFactory read FRawInputFactory;
      /// <summary> Fragt die Daten für alle PollingDevices (z.B. alle DirectInputDevices) ab</summary>
      procedure Idle;
      procedure EndFrame;
      /// <summary>Destruktor zum Freigeben des Speichers</summary>
      destructor Destroy; override;
  end;

  // der Rückgabewert entscheidet ob der Hook weitergegeben wird
  MouseHookCallback = function(nCode : integer; wParam : wParam; lParam : lParam) : boolean;

function UninstallMausHook : boolean; stdcall; external 'MausHook.dll' delayed;
function InstallMausHook(hwnd : Cardinal; CallbackFunc : MouseHookCallback; LokalerHook : boolean) : boolean; stdcall; external 'MausHook.dll' delayed;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  /// <summary> The default mous and keyboard. Initialized with dummy-controllers. Dummies musn't be freed.
  /// DefaultMouse and DefaultKeyboard are freed automatically at termination. </summary>
  Mouse, _DefaultMouse : TMouse;
  Keyboard, _DefaultKeyboard : TKeyboard;

implementation

const
  APPKEY = 324127683;
var
  DIDevicesFound : TList<TDIDeviceInstance>;

function DIEnumerateDeviceCallback(var lpddi : TDIDeviceInstance; pvRef : Pointer) : BOOL; stdcall;
begin
  if LongWord(pvRef) = APPKEY then
  begin
    DIDevicesFound.Add(lpddi);
  end;
  Result := DIENUM_CONTINUE;
end;

function CallbackMausHook(nCode : integer; wParam : wParam; lParam : lParam) : boolean;
var
  Data : ^MSLLHOOKSTRUCT;
begin
  Data := Pointer(lParam);
  if Data.dwExtraInfo = HOOK_MARKER then Exit(true);
  Result := false;
end;

procedure TMouse.ClearOneFrameStates;
var
  i : EnumMouseButton;
begin
  // remove one frame states
  for i := low(EnumMouseButton) to high(EnumMouseButton) do
      FMouseButton[i] := FMouseButton[i] - [mbsUp, mbsDown];
end;

constructor TMouse.Create;
begin
  ClipRect.Left := -MaxInt;
  ClipRect.Top := -MaxInt;
  ClipRect.Bottom := MaxInt;
  ClipRect.Right := MaxInt;
  FAcceleration := 10;
  FSensitivity := 2;
  MinimalDragDistance := 8;
end;

function TMouse.GetDeltaPosition : RIntVector2;
begin
  Result := RIntVector2.Create(dX, dY);
end;

function TMouse.GetPosition : RIntVector2;
begin
  Result.X := FX;
  Result.Y := FY;
end;

function TMouse.HasAnyButtonActivity : boolean;
var
  i : EnumMouseButton;
begin
  Result := false;
  for i := low(EnumMouseButton) to high(EnumMouseButton) do
    if FMouseButton[i] <> [] then
        Exit(true);
end;

procedure TMouse.Idle;
begin
  inherited;
  FWasDragging := IsDragging;
end;

procedure TMouse.OnChange;
begin
  if AllButtonsUp(AllMouseButtons) then FDragging := false;
  if not IsDragging and AnyButtonDown(AllMouseButtons) then FDragPosition := Position;
  if not IsDragging and AnyButtonIsDown(AllMouseButtons) and (Position.Distance(FDragPosition) > MinimalDragDistance) then FDragging := true;
end;

function TMouse.AllButtonsUp(Buttons : SetMouseButton) : boolean;
var
  Button : EnumMouseButton;
begin
  for Button in Buttons do
    if ButtonIsDown(Button) then Exit(false);
  Result := true;
end;

function TMouse.AnyButtonDown(Buttons : SetMouseButton) : boolean;
var
  Button : EnumMouseButton;
begin
  for Button in Buttons do
    if ButtonDown(Button) then Exit(true);
  Result := false;
end;

function TMouse.AnyButtonIsDown(Buttons : SetMouseButton) : boolean;
var
  Button : EnumMouseButton;
begin
  for Button in Buttons do
    if ButtonIsDown(Button) then Exit(true);
  Result := false;
end;

function TMouse.ButtonDown(MouseButton : EnumMouseButton) : boolean;
begin
  Result := mbsDown in FMouseButton[MouseButton];
end;

function TMouse.ButtonIsDown(MouseButton : EnumMouseButton) : boolean;
begin
  Result := mbsIsDown in FMouseButton[MouseButton];
end;

class function TMouse.ButtonToString(Button : EnumMouseButton) : string;
begin
  case Button of
    mbLeft : Result := 'LMB';
    mbRight : Result := 'RMB';
    mbMiddle : Result := 'MMB';
    mbExtra1 : Result := 'MB1';
    mbExtra2 : Result := 'MB2';
    mbExtra3 : Result := 'MB3';
    mbExtra4 : Result := 'MB4';
  else
    Result := 'Unknown';
  end;
end;

function TMouse.ButtonUp(MouseButton : EnumMouseButton) : boolean;
begin
  Result := mbsUp in FMouseButton[MouseButton];
end;

procedure TMouse.SetPosition(const Value : RIntVector2);
var
  tmpPunkt : RIntVector2;
begin
  tmpPunkt := ClipRect.ClipPoint(Value);
  FX := tmpPunkt.X;
  FY := tmpPunkt.Y;
end;

{ TEingabeManager }

constructor TInputDeviceManager.Create(ImHintergrundAktiv : boolean = false; FensterHandle : hwnd = 0);
begin
  FHandle := HGeneric.TertOP<hwnd>(FensterHandle <> 0, FensterHandle, Application.handle);
  FImHintergrundAktiv := ImHintergrundAktiv;
  FRawInputFactory := TRawInputFactory.Create(FHandle, ImHintergrundAktiv);
end;

destructor TInputDeviceManager.Destroy;
begin
  FDirectInputFactory.Free;
  FRawInputFactory.Free;
  inherited;
end;

procedure TInputDeviceManager.EndFrame;
begin
  if Assigned(FRawInputFactory) then FRawInputFactory.Idle;
end;

function TInputDeviceManager.GetDirectInputFactory : TDirectInputFactory;
begin
  if FDirectInputFactory = nil then FDirectInputFactory := TDirectInputFactory.Create(FHandle);
  Result := FDirectInputFactory;
end;

procedure TInputDeviceManager.Idle;
begin
  if Assigned(FDirectInputFactory) then FDirectInputFactory.Idle;
end;

{ TMouseDirectInput }

constructor TMouseDirectInput.Create(handle : hwnd; DirectInputFactory : TObject; DirectInput : IDirectInput8; ExklusiverZugriff : boolean);
var
  BufferEigenschaften : TDIProPDWord;
begin
  inherited Create;
  FDirectInputFactory := DirectInputFactory;
  // Zugriff auf das Mausdevice holen
  HLog.CheckDX9Error(DirectInput.CreateDevice(GUID_SysMouse, FMausDevice, nil), 'Fehler beim Zugriff auf die Maus.');
  // und Zugriff festlegen
  if ExklusiverZugriff then FMausDevice.SetCooperativeLevel(handle, DISCL_EXCLUSIVE or DISCL_FOREGROUND)
  else FMausDevice.SetCooperativeLevel(handle, DISCL_NONEXCLUSIVE or DISCL_FOREGROUND);
  // Datenformat festlegen (vorgegeben durch SDK)
  FMausDevice.SetDataFormat(c_dfDImouse2);
  // Maus auf BufferedDataReading einstellen
  with BufferEigenschaften do
  begin
    diph.dwSize := Sizeof(TDIProPDWord);
    diph.dwHeaderSize := Sizeof(TDIPropHeader);
    diph.dwObj := 0;
    diph.dwHow := DIPH_Device;
    // 32 (oder was auch immer in der Konstante drin steht) Datenpakete werden gepuffert
    dwdata := DIMOUSEBUFFERSIZE;
  end;
  if FMausDevice.SetProperty(DIPROP_BUFFERSIZE, @BufferEigenschaften) <> DI_OK then raise Exception.Create('TMouseDirectInput.Create: Error on set buffersize.');
  // Maus Achsenmodus auf Relativ stellen, so dass nur die Änderungen ankommen
  with BufferEigenschaften do
  begin
    diph.dwSize := Sizeof(TDIProPDWord);
    diph.dwHeaderSize := Sizeof(TDIPropHeader);
    diph.dwObj := 0;
    diph.dwHow := DIPH_Device;
    // 32 (oder was auch immer in der Konstante drin steht) Datenpakete werden gepuffert
    dwdata := DIPROPAXISMODE_REL;
  end;
  FMausDevice.SetProperty(DIPROP_AXISMODE, @BufferEigenschaften.diph);
  // Fehler(FMausDevice.Acquire, 'TMouseDirectInput.Create: Fehler beim Acquire');
end;

destructor TMouseDirectInput.Destroy;
begin
  FMausDevice.Unacquire;
  FMausDevice := nil;
  // aus der DirectInputFactory austragen
  TInputDeviceManager.TDirectInputFactory(FDirectInputFactory).FMausDirectInputListe.Remove(self);
  inherited;
end;

procedure TMouseDirectInput.Idle;
var
  Buffer : array [0 .. DIMOUSEBUFFERSIZE - 1] of TDIDEVICEOBJECTDATA;
  ElementeImBuffer : Cardinal;
  FehlerCode, i : integer;
begin
  inherited;
  ElementeImBuffer := DIMOUSEBUFFERSIZE;
  FehlerCode := FMausDevice.GetDeviceData(Sizeof(TDIDEVICEOBJECTDATA), @Buffer, ElementeImBuffer, 0);
  case FehlerCode of
    // Wenn der Zugriff auf das Device fehlt
    DIERR_INPUTLOST, DIERR_NOTACQUIRED :
      begin
        // wird versucht dieser zu bekommen und die Daten erneut abzurufen
        if FMausDevice.Acquire <> DI_OK then
        begin
          Exit;
        end;
        Idle;
        Exit;
      end;
    // DI_BUFFEROVERFLOW : raise Exception.Create('TMouseDirectInput.Idle: Too many data, bufferoverflow!');
  end;
  ClearOneFrameStates;
  FdX := 0;
  FdY := 0;
  FdZ := 0;
  for i := 0 to integer(ElementeImBuffer) - 1 do
      VerarbeiteDaten(Buffer[i]);
end;

procedure TMouseDirectInput.VerarbeiteDaten(DIMausDaten : TDIDEVICEOBJECTDATA);
var
  Button : EnumMouseButton;
begin
  // event for mouse button?
  if (DIMausDaten.dwOfs >= DIMOFS_BUTTON0) and (DIMausDaten.dwOfs <= DIMOFS_BUTTON7) then
  begin
    Button := EnumMouseButton(DIMausDaten.dwOfs - DIMOFS_BUTTON0 + 1);
    // DIMausDaten.dwData and $80 <> 0 => mouse button pressed
    if (DIMausDaten.dwdata and $80) <> 0 then
        FMouseButton[Button] := FMouseButton[Button] + [mbsDown, mbsIsDown]
    else
        FMouseButton[Button] := FMouseButton[Button] + [mbsUp] - [mbsIsDown];
  end
  // otherwise, mouse has been moved
  else
    case DIMausDaten.dwOfs of
      DIMOFS_X :
        begin
          FdX := LongInt(DIMausDaten.dwdata);
          FdX := round(Sensitivity * Sign(FdX) * Max(abs(FdX), (FdX * FdX / Acceleration)));
          FX := FX + FdX;
        end;
      DIMOFS_Y :
        begin
          FdY := LongInt(DIMausDaten.dwdata);
          FdY := round(Sensitivity * Sign(FdY) * Max(abs(FdY), (FdY * FdY / Acceleration)));
          FY := FY + FdY;
        end;
      DIMOFS_Z :
        begin
          FdZ := LongInt(DIMausDaten.dwdata) div 120;
          FZ := FZ + FdZ;
        end;
    end;
  Position := ClipRect.ClipPoint(Position);
  if Assigned(OnDataChange) then OnDataChange(self);
  OnChange;
end;

{ TMouseRaw }

constructor TMouseRaw.Create(RawInputFactory : TObject; RawInputGeräteHandle : RRawInputDeviceHandle; BeinflusstSystemMaus : boolean);
var
  MausPosition :
    tagPOINT;
begin
  inherited Create;
  FRRawInputDeviceHandle := RawInputGeräteHandle;
  FRawInputFactory := RawInputFactory;
  FBeinflusstSystemMaus := BeinflusstSystemMaus;
  // X,Y Position auf momentane Mausposition setzen
  GetCursorPos(MausPosition);
  FX := MausPosition.X;
  FY := MausPosition.Y;
end;

destructor TMouseRaw.Destroy;
begin
  TInputDeviceManager.TRawInputFactory(FRawInputFactory).MausRawFreigeben(self);
  inherited;
end;

function TMouseRaw.GetInputDaten : tagINPUT;
begin
  Result.type_ := INPUT_MOUSE;
  Result.mi.dX := FdX;
  Result.mi.dY := FdY;
  Result.mi.mouseData := FdZ * 120;
  if (FdX <> 0) or (FdY <> 0) then Result.mi.dwFlags := MOUSEEVENTF_MOVE
  else Result.mi.dwFlags := 0;
  if FdZ <> 0 then Result.mi.dwFlags := Result.mi.dwFlags or MOUSEEVENTF_WHEEL;
  if ButtonDown(mbLeft) then Result.mi.dwFlags := Result.mi.dwFlags or MOUSEEVENTF_LEFTDOWN;
  if ButtonDown(mbRight) then Result.mi.dwFlags := Result.mi.dwFlags or MOUSEEVENTF_RIGHTDOWN;
  if ButtonDown(mbMiddle) then Result.mi.dwFlags := Result.mi.dwFlags or MOUSEEVENTF_MIDDLEDOWN;
  if ButtonUp(mbLeft) then Result.mi.dwFlags := Result.mi.dwFlags or MOUSEEVENTF_LEFTUP;
  if ButtonUp(mbRight) then Result.mi.dwFlags := Result.mi.dwFlags or MOUSEEVENTF_RIGHTUP;
  if ButtonUp(mbMiddle) then Result.mi.dwFlags := Result.mi.dwFlags or MOUSEEVENTF_MIDDLEUP;
  Result.mi.time := 0;
  // Markieren damit Inputhook Daten durchwinkt
  Result.mi.dwExtraInfo := HOOK_MARKER;
end;

procedure TMouseRaw.SetBeinflusstSystemMaus(const Value : boolean);
begin
  if Value = FBeinflusstSystemMaus then Exit;
  FBeinflusstSystemMaus := Value;
  // Maus hat jetzt Zurgiff also Decrement
  if Value then TInputDeviceManager.TRawInputFactory(FRawInputFactory).MäuseOhneSystemZugriffDecrement
  else TInputDeviceManager.TRawInputFactory(FRawInputFactory).MäuseOhneSystemZugriffIncrement;
end;

procedure TMouseRaw.VerarbeiteDaten(RawInputDaten : tagRAWINPUT);
var
  InputDaten : tagINPUT;
begin
  with RawInputDaten.Mouse do
  begin
    // Mausposition und deren Veränderung auslesen
    // absolute Mauskoordinaten
    if (usFlags and MOUSE_MOVE_ABSOLUTE) <> 0 then
    begin
      FdX := lLastX - FX;
      FdY := lLastY - FY;
      FX := lLastX;
      FY := lLastY;
    end
    // relative Mauskoordinaten
    else
    begin
      FdX := lLastX;
      FdY := lLastY;
      FX := FX + lLastX;
      FY := FY + lLastY;
    end;
    Position := ClipRect.ClipPoint(Position);
    ClearOneFrameStates;
    FdZ := 0;

    if (union.usButtonFlags and RI_MOUSE_LEFT_BUTTON_DOWN) <> 0 then
        FMouseButton[mbLeft] := FMouseButton[mbLeft] + [mbsDown, mbsIsDown];
    if (union.usButtonFlags and RI_MOUSE_LEFT_BUTTON_UP) <> 0 then
        FMouseButton[mbLeft] := FMouseButton[mbLeft] + [mbsUp] - [mbsIsDown];

    if (union.usButtonFlags and RI_MOUSE_RIGHT_BUTTON_DOWN) <> 0 then
        FMouseButton[mbRight] := FMouseButton[mbRight] + [mbsDown, mbsIsDown];
    if (union.usButtonFlags and RI_MOUSE_RIGHT_BUTTON_UP) <> 0 then
        FMouseButton[mbRight] := FMouseButton[mbRight] + [mbsUp] - [mbsIsDown];

    if (union.usButtonFlags and RI_MOUSE_MIDDLE_BUTTON_DOWN) <> 0 then
        FMouseButton[mbMiddle] := FMouseButton[mbMiddle] + [mbsDown, mbsIsDown];
    if (union.usButtonFlags and RI_MOUSE_MIDDLE_BUTTON_UP) <> 0 then
        FMouseButton[mbMiddle] := FMouseButton[mbMiddle] + [mbsUp] - [mbsIsDown];

    if (union.usButtonFlags and RI_MOUSE_BUTTON_4_DOWN) <> 0 then
        FMouseButton[mbExtra1] := FMouseButton[mbExtra1] + [mbsDown, mbsIsDown];
    if (union.usButtonFlags and RI_MOUSE_BUTTON_4_UP) <> 0 then
        FMouseButton[mbExtra1] := FMouseButton[mbExtra1] + [mbsUp] - [mbsIsDown];

    if (union.usButtonFlags and RI_MOUSE_BUTTON_5_DOWN) <> 0 then
        FMouseButton[mbExtra2] := FMouseButton[mbExtra2] + [mbsDown, mbsIsDown];
    if (union.usButtonFlags and RI_MOUSE_BUTTON_5_UP) <> 0 then
        FMouseButton[mbExtra2] := FMouseButton[mbExtra2] + [mbsUp] - [mbsIsDown];

    if (union.usButtonFlags and RI_MOUSE_WHEEL) <> 0 then
    begin
      FdZ := Short(union.usButtonData) div 120;
      FZ := FZ + FdZ;
    end;
  end;

  // Wenn ein Hook zum Abfangen von Mauseingaben installiert wurde und die Maus die Systemmaus verändert
  if (TInputDeviceManager.TRawInputFactory(FRawInputFactory).FMäuseOhneSystemZugriff > 0) and FBeinflusstSystemMaus then
  begin
    InputDaten := GetInputDaten;
    if SendInput(1, @InputDaten, Sizeof(tagINPUT)) = 0 then HLog.Log('Probleme beim Injezieren der Inputdaten.');
  end;

  if Assigned(OnDataChange) then OnDataChange(self);
  OnChange;
end;

{ TEingabeManager.TDirectInputFactory }

constructor TInputDeviceManager.TDirectInputFactory.Create(handle : hwnd);
begin
  FHandle := handle;
  FMausDirectInputListe := TObjectList<TMouseDirectInput>.Create(false);
  FTastaturDirectInputListe := TObjectList<TKeyboardDirectInput>.Create(false);
  FGeräteDirectInputListe := TObjectList<TInputDevice>.Create(false);
  HLog.CheckDX9Error(DirectInput8Create(GetModuleHandle(nil), DirectInput_Version, IID_IDirectInput8, FDirectInput, nil), 'TInputDeviceeManager.TDirectInputFactory.Create: Fehler beim Initialisieren von IDirectInput8.');
end;

destructor TInputDeviceManager.TDirectInputFactory.Destroy;
begin
  FMausDirectInputListe.Free;
  FTastaturDirectInputListe.Free;
  FGeräteDirectInputListe.Free;
  FDirectInput := nil;
  inherited;
end;

procedure TInputDeviceManager.TDirectInputFactory.Idle;
var
  i : integer;
begin
  for i := 0 to FMausDirectInputListe.Count - 1 do FMausDirectInputListe.Items[i].Idle;
  for i := 0 to FTastaturDirectInputListe.Count - 1 do FTastaturDirectInputListe.Items[i].Idle;
  for i := 0 to FGeräteDirectInputListe.Count - 1 do FGeräteDirectInputListe.Items[i].Idle;
end;

function TInputDeviceManager.TDirectInputFactory.ErzeugeTGameControllerDirectInput(
  ExklusiverZugriff : boolean; ControllerGUID : TGUID) : TGameController;
begin
  Result := TGameControllerDirectInput.Create(ControllerGUID, FHandle, self, FDirectInput, ExklusiverZugriff);
  FGeräteDirectInputListe.Add(Result);
end;

function TInputDeviceManager.TDirectInputFactory.ErzeugeTMouseDirectInput(ExklusiverZugriff : boolean) : TMouse;
begin
  Result := TMouseDirectInput.Create(FHandle, self, FDirectInput, ExklusiverZugriff);
  FMausDirectInputListe.Add(TMouseDirectInput(Result));
end;

function TInputDeviceManager.TDirectInputFactory.GetConnectedGamecontroller : TList<DIDEVICEINSTANCE>;
begin
  FreeAndNil(DIDevicesFound);
  if not Assigned(DIDevicesFound) then
      DIDevicesFound := TList<TDIDeviceInstance>.Create;
  DIDevicesFound.Clear;
  FDirectInput.EnumDevices(DI8DEVCLASS_GAMECTRL, DIEnumerateDeviceCallback, Pointer(APPKEY), DIEDFL_ATTACHEDONLY);
  Result := DIDevicesFound;
end;

function TInputDeviceManager.TDirectInputFactory.ErzeugeTGameControllerDirectInput(
  ExklusiverZugriff : boolean) : TGameController;
begin
  Result := ErzeugeTGameControllerDirectInput(ExklusiverZugriff, GUID_Joystick)
end;

function TInputDeviceManager.TDirectInputFactory.ErzeugeTKeyboardDirectInput(ExklusiverZugriff : boolean) : TKeyboard;
begin
  Result := TKeyboardDirectInput.Create(FHandle, self, FDirectInput, ExklusiverZugriff);
  FTastaturDirectInputListe.Add(TKeyboardDirectInput(Result));
end;

{ TEingabeManager.TRawInputFactory }

function TInputDeviceManager.TRawInputFactory.GeTMouseListe : TRawInputDeviceList;
begin
  Result := TRawInputDeviceList.Create(RIM_TYPEMOUSE);
end;

function TInputDeviceManager.TRawInputFactory.GetTastaturListe : TRawInputDeviceList;
begin
  Result := TRawInputDeviceList.Create(RIM_TYPEKEYBOARD);
end;

procedure TInputDeviceManager.TRawInputFactory.Idle;
var
  i : integer;
begin
  for i := 0 to FTastaturRawListe.Count - 1 do
      FTastaturRawListe[i].Idle;
end;

procedure TInputDeviceManager.TRawInputFactory.MausRawFreigeben(Maus : TMouseRaw);
begin
  FMausRawListe.Remove(Maus);
  if not Maus.FBeinflusstSystemMaus then MäuseOhneSystemZugriffDecrement;
end;

procedure TInputDeviceManager.TRawInputFactory.MessageHandler(var Msg : Windows.TMsg; var Handled : boolean);
begin
  if { FHandle = Msg.hwnd }true then
  begin
    if Msg.message = WM_INPUT then
    begin
      VerarbeiteWM_Input(Msg);
      Handled := true;
    end;
    if Msg.message = WM_INPUT_DEVICE_CHANGE then
    begin
      VerarbeiteWM_INPUT_DEVICE_CHANGE(Msg);
      Handled := true;
    end;
  end;
end;

procedure TInputDeviceManager.TRawInputFactory.MäuseOhneSystemZugriffDecrement;
begin
  dec(FMäuseOhneSystemZugriff);
  // wenn es keine Mäuse mehr gibt deren Daten abgefangen werden müssen, kann der Hook deinstalliert werden
  if FMäuseOhneSystemZugriff <= 0 then UninstallMausHook;
end;

procedure TInputDeviceManager.TRawInputFactory.MäuseOhneSystemZugriffIncrement;
begin
  // wenn es noch keine Maus vorher ohne Systemzugriff gab
  if (FMäuseOhneSystemZugriff = 0) then
  begin
    // muss der Hook installiert werden, um die Eingaben abzufangen
    InstallMausHook(FHandle, CallbackMausHook, not FImHintergrundAktiv);
  end;
  inc(FMäuseOhneSystemZugriff);
end;

procedure TInputDeviceManager.TRawInputFactory.VerarbeiteWM_Input(Msg : Windows.TMsg);
var
  Daten : tagRAWINPUT;
  DatenGröße : Cardinal;
  i : integer;
begin
  // Raw Daten auslesen
  DatenGröße := Sizeof(tagRAWINPUT);
  GetRawInputData(Msg.lParam, RID_INPUT, @Daten, DatenGröße, Sizeof(tagRAWINPUTHEADER));
  // raussuchen zu welchem Typ die Daten gehören und die Klasse die das Handle verarbeitet dazu raussuchen
  case Daten.header.dwType of
    RIM_TYPEKEYBOARD :
      begin
        for i := 0 to FTastaturRawListe.Count - 1 do
          if FTastaturRawListe[i].FRRawInputDeviceHandle.ContainsHandle(Daten.header.hDevice) then
          begin
            FTastaturRawListe[i].VerarbeiteDaten(Daten);
            // keine exit hier, weil es auch mehrere TKeyboardRaw für das gleiche Handle geben kann
          end;
      end;
    RIM_TYPEMOUSE :
      begin
        for i := 0 to FMausRawListe.Count - 1 do
          if FMausRawListe[i].FRRawInputDeviceHandle.ContainsHandle(Daten.header.hDevice) then
          begin
            FMausRawListe[i].VerarbeiteDaten(Daten);
            // keine exit hier, weil es auch mehrere TMouseRaw für das gleiche Handle geben kann
          end;
      end;
    RIM_TYPEHID :;
  end;
end;

procedure TInputDeviceManager.TRawInputFactory.VerarbeiteWM_INPUT_DEVICE_CHANGE(Msg : Windows.TMsg);
var
  InfoData : tagRID_DEVICE_INFO;
  GeräteName : string;
  BufferGröße : Cardinal;
  Mäuse : TList<TMouse>;
  i : integer;
begin
  // soll laut MSDN Doku auf diesen Wert gesetzt werden
  InfoData.cbSize := Sizeof(RID_DEVICE_INFO);
  // Größe speichern und InfoDaten auslesen, sind wichtig zum Identfizieren um welchen Gerätetyp es sich handelt
  BufferGröße := Sizeof(tagRID_DEVICE_INFO);
  GetRawInputDeviceInfo(Msg.lParam, RIDI_DEVICEINFO, @InfoData, BufferGröße);
  // Größe bestimmen, String anpassen und Name auslesen
  GetRawInputDeviceInfo(Msg.lParam, RIDI_DEVICENAME, nil, BufferGröße);
  setlength(GeräteName, BufferGröße);
  GetRawInputDeviceInfo(Msg.lParam, RIDI_DEVICENAME, @GeräteName[1], BufferGröße);
  setlength(GeräteName, BufferGröße - 1);
  // Typ des neuen Gerätes bestimmen und auf Ereignis reagieren
  case InfoData.dwType of
    RIM_TYPEMOUSE :
      begin
        case Msg.wParam of
          GIDC_ARRIVAL : if Assigned(OnMausAngeschloßen) then OnMausAngeschloßen(RRawInputDeviceHandle.Create(GeräteName, [Msg.lParam]));
          // alle TMouse Objekte raussuchen die von der Enterfernung der Maus betroffen sind
          GIDC_REMOVAL :
            begin
              Mäuse := TList<TMouse>.Create;
              // wenn ein TMouseobjekt den handle der entfernten Maus enthält, wird sie der List hinzugefügt
              for i := 0 to FMausRawListe.Count - 1 do
                if FMausRawListe[i].FRRawInputDeviceHandle.ContainsHandle(Msg.lParam) then Mäuse.Add(FMausRawListe[i]);
              // wurden TMouseobjekte gefunden wird das Ereignis ausgelöst, ansonsten beleibt alles still
              if Mäuse.Count > 0 then
              begin
                if Assigned(OnMausMausAbgesteckt) then OnMausMausAbgesteckt(Mäuse);
              end
              else Mäuse.Free;
            end;
        end;
      end;
    RIM_TYPEKEYBOARD :;
    RIM_TYPEHID :;
  end;
end;

constructor TInputDeviceManager.TRawInputFactory.Create(handle : hwnd; ImHintergrundAktiv : boolean);
begin
  FHandle := handle;
  // if Assigned(Application.OnMessage) then raise ERawInputException.Create('OnMessage Ereignis bereits belegt - kann RawInput nicht nutzen.');
  FMausRawListe := TObjectList<TMouseRaw>.Create(false);
  FTastaturRawListe := TObjectList<TKeyboardRaw>.Create(false);
  FImHintergrundAktiv := ImHintergrundAktiv;
end;

destructor TInputDeviceManager.TRawInputFactory.Destroy;
begin
  if FMäuseOhneSystemZugriff > 0 then UninstallMausHook;

  FMausRawListe.Free;
  FTastaturRawListe.Free;
  inherited;
end;

function TInputDeviceManager.TRawInputFactory.ErzeugeTMouseRaw(RawInputGeräteHandle : RRawInputDeviceHandle; BeeinflusstSystemMaus : boolean = true) : TMouse;
var
  rd : array [0 .. 0] of Rawinputdevice;
begin
  // wenn bisher keine Geräte rausgegeben wurden, muss erstmal alles dafür eingerichtet werden
  if (FMausRawListe.Count <= 0) then
  begin
    Application.OnMessage := nil;
    rd[0].usUsagePage := 1;
    rd[0].usUsage := 2;
    rd[0].dwFlags := RIDEV_DEVNOTIFY or HGeneric.TertOP<integer>(FImHintergrundAktiv, RIDEV_INPUTSINK, 0);
    rd[0].hwndTarget := FHandle;
    RegisterRawInputDevices(@rd[0], 1, Sizeof(Rawinputdevice));
    Application.ProcessMessages;
    Application.OnMessage := MessageHandler;
  end;
  if not BeeinflusstSystemMaus then MäuseOhneSystemZugriffIncrement;

  Result := TMouseRaw.Create(self, RawInputGeräteHandle, BeeinflusstSystemMaus);
  FMausRawListe.Add(TMouseRaw(Result));
end;

function TInputDeviceManager.TRawInputFactory.ErzeugeTKeyboardRaw(
  Index : integer) : TKeyboard;
var
  RawInputDeviceList : TRawInputDeviceList;
begin
  RawInputDeviceList := GetTastaturListe;
  if (index < 0) or (index >= RawInputDeviceList.RawInputGeräte.Count) then raise ERawInputException.Create('Fehlerhafter Tastaturindex.');
  Result := ErzeugeTKeyboardRaw(RawInputDeviceList.RawInputGeräte[index]);
  RawInputDeviceList.Free;
end;

function TInputDeviceManager.TRawInputFactory.ErzeugeTMouseRaw(Index : integer; BeeinflusstSystemMaus : boolean) : TMouse;
begin
  if (index < 0) or (index >= GeTMouseListe.RawInputGeräte.Count) then raise ERawInputException.Create('Fehlerhafte Mausindex.');
  Result := ErzeugeTMouseRaw(GeTMouseListe.RawInputGeräte[index], BeeinflusstSystemMaus);
end;

function TInputDeviceManager.TRawInputFactory.ErzeugeTKeyboardRaw(RawInputGeräteHandle : RRawInputDeviceHandle) : TKeyboard;
var
  rd : array [0 .. 0] of Rawinputdevice;
begin
  // wenn bisher keine Geräte rausgegeben wurden, muss erstmal alles dafür eingerichtet werden
  if (FTastaturRawListe.Count <= 0) then
  begin
    Application.OnMessage := nil;
    rd[0].usUsagePage := 1;
    rd[0].usUsage := 6;
    rd[0].dwFlags := RIDEV_DEVNOTIFY or RIDEV_NOLEGACY or RIDEV_NOHOTKEYS or RIDEV_APPKEYS;
    rd[0].hwndTarget := FHandle;
    RegisterRawInputDevices(@rd[0], 1, Sizeof(Rawinputdevice));
    Application.ProcessMessages;
    Application.OnMessage := MessageHandler;
  end;
  Result := TKeyboardRaw.Create(self, RawInputGeräteHandle);
  FTastaturRawListe.Add(TKeyboardRaw(Result));
end;

{ TRawInputGeräteListe }

constructor TRawInputDeviceList.Create(GeräteTyp : Byte);
var
  AnzahlGeräte, BufferGröße : Cardinal;
  GeräteListe : array of RawInputDeviceList;
  GeräteName : string;
  i, i2 : integer;
  gefunden : boolean;
  // testet ob der GeräteName auf der IgnorListe steht (ist schon so, wenn nur ein Teil des Namens mit dem Eintrag übereinstimmt)
  // True - wenn der Eintrag ignoriert werden soll
  function IstAufIgnorListe(GeräteName : string) : boolean;
  var
    i : integer;
  begin
    Result := false;
    for i := 0 to length(RAWINPUTIGNORLIST) - 1 do
      // wenn der Ingnoreintrag im Namen gefunden wird - True zurückgeben
      if pos(RAWINPUTIGNORLIST[i], GeräteName) > 0 then
      begin
        Result := true;
        Exit;
      end;
  end;

begin
  FRawInputGeräte := TList<RRawInputDeviceHandle>.Create;
  // speichert die Anzahl der Geräte
  GetRawInputDeviceList(nil, AnzahlGeräte, Sizeof(RawInputDeviceList));
  // Array auf Größe einstellen und Geräteliste auslesen
  setlength(GeräteListe, AnzahlGeräte);
  GetRawInputDeviceList(@GeräteListe[0], AnzahlGeräte, Sizeof(RawInputDeviceList));
  for i := 0 to AnzahlGeräte - 1 do
    // wenn das Gerät dem geünschten Typ entspricht ist, Namen auslesen und in Liste eintragen
    if GeräteListe[i].dwType = GeräteTyp then
    begin
      // bestimme benötigten Speicher für den Namen und String drauf einstellen
      GetRawInputDeviceInfo(GeräteListe[i].hDevice, RIDI_DEVICENAME, nil, BufferGröße);
      setlength(GeräteName, BufferGröße);
      // Namen auslesen und in Liste einfügen
      GetRawInputDeviceInfo(GeräteListe[i].hDevice, RIDI_DEVICENAME, @GeräteName[1], BufferGröße);
      // weil sonst am Ende vom String '/0' steht und der String andere Strings beeinflusst
      setlength(GeräteName, BufferGröße - 1);
      if IstAufIgnorListe(GeräteName) then Continue;
      // suchen ob das Gerät bereits in der Liste steht
      gefunden := false;
      for i2 := 0 to RawInputGeräte.Count - 1 do
        // wenn ja Handle hinzufügen und fertig
        if RawInputGeräte[i2].name = GeräteName then
        begin
          RawInputGeräte[i2].AddHandle(GeräteListe[i].hDevice);
          gefunden := true;
          break;
        end;
      if not gefunden then
      begin
        // Gerätrecord einstellen und Liste hinzufügen
        RawInputGeräte.Add(RRawInputDeviceHandle.Create(GeräteName, [GeräteListe[i].hDevice]));
      end;
    end;
  GeräteListe := nil;
end;

destructor TRawInputDeviceList.Destroy;
begin
  FRawInputGeräte.Free;
  inherited;
end;

function TRawInputDeviceList.GetStringList : TStringList;
var
  i : integer;
begin
  Result := TStringList.Create;
  for i := 0 to RawInputGeräte.Count - 1 do Result.Add(RawInputGeräte[i]);
end;

{ RRawInputDeviceHandle }

class operator RRawInputDeviceHandle.Implicit(A : RRawInputDeviceHandle) : string;
// var
// i : integer;
begin
  Result := A.name;
  // for i := 0 to A.HandleID.Count - 1 do result := result + '| HandleID[' + IntToStr(i) + ']: ' + IntToStr(A.HandleID[i]);
end;

procedure RRawInputDeviceHandle.AddHandle(handle : hwnd);
begin
  if (FHandleCount + 1) > MAXHANDLES then raise Exception.Create('RRawInputDeviceHandle.Create: Can''t save more then ' + IntToStr(MAXHANDLES) + ' handles for one device.');
  HandleID[FHandleCount] := handle;
  inc(FHandleCount);
end;

function RRawInputDeviceHandle.ContainsHandle(handle : hwnd) : boolean;
var
  i : integer;
begin
  Result := false;
  for i := 0 to FHandleCount - 1 do
    if HandleID[i] = handle then Exit(true);

end;

constructor RRawInputDeviceHandle.Create(name : string; HandleID : array of hwnd);
var
  i : integer;
begin
  FHandleCount := 0;
  for i := 0 to length(HandleID) - 1 do AddHandle(HandleID[i]);
  self.name := name;
end;

{ TTastatur }

constructor TKeyboard.Create;
begin
  FKeyData := TDictionary<word, word>.Create;
  FDataFromLastFrame := TList < TPair < EnumKeyboardKey, boolean >>.Create;
end;

destructor TKeyboard.Destroy;
begin
  FKeyData.Free;
  FDataFromLastFrame.Free;
  inherited;
end;

function TKeyboard.GetLastKeyDown : TList<EnumKeyboardKey>;
var
  Key : word;
begin
  Result := TList<EnumKeyboardKey>.Create;
  for Key in FKeyData.Keys do
    // die Taste wurde gedrückt also rein in die Liste
    if (FKeyData.Items[Key] and BITMASK_BUTTONDOWN) <> 0 then Result.Add(EnumKeyboardKey(Key));
end;

function TKeyboard.GetLastKeyIsDown : TList<EnumKeyboardKey>;
var
  Key : word;
begin
  Result := TList<EnumKeyboardKey>.Create;
  for Key in FKeyData.Keys do
    // die Taste wurde gedrückt und noch nicht losgelassen also rein in die Liste
    if (FKeyData.Items[Key] and BITMASK_BUTTONISDOWN) <> 0 then Result.Add(EnumKeyboardKey(Key));
end;

function TKeyboard.GetLastKeyUp : TList<EnumKeyboardKey>;
var
  Key : word;
begin
  Result := TList<EnumKeyboardKey>.Create;
  for Key in FKeyData.Keys do
    // die Taste wurde losgelassen also rein in die Liste
    if (FKeyData.Items[Key] and BITMASK_BUTTONUP) <> 0 then Result.Add(EnumKeyboardKey(Key));
end;

function TKeyboard.HasAnyKeyActivity : boolean;
var
  Key : word;
begin
  Result := false;
  for Key in FKeyData.Keys do
    if (FKeyData.Items[Key] and (BITMASK_BUTTONUP or BITMASK_BUTTONISDOWN or BITMASK_BUTTONDOWN)) <> 0 then
        Exit(true);
end;

function TKeyboard.KeyDown(Taste : EnumKeyboardKey) : boolean;
begin
  Result := false;
  if FKeyData.ContainsKey(ord(Taste)) then Result := (FKeyData[ord(Taste)] and BITMASK_BUTTONDOWN) <> 0;
end;

function TKeyboard.KeyIsDown(Taste : EnumKeyboardKey) : boolean;
begin
  Result := false;
  if FKeyData.ContainsKey(ord(Taste)) then Result := (FKeyData[ord(Taste)] and BITMASK_BUTTONISDOWN) <> 0;
end;

class function TKeyboard.KeyToString(Key : EnumKeyboardKey) : string;
  function ToStr() : string;
  var
    keystate : Windows.TKeyboardState;
    copiedChars : integer;
  begin
    // Hack missing numpad keys for now
    case Key of
      TasteNumDivision : Exit('Num/');
      TasteNumPlus : Exit('Num+');
      TasteNumMultiplikation : Exit('Num*');
      TasteNumMinus : Exit('Num-');
      TasteNum7 : Exit('Num7');
      TasteNum8 : Exit('Num8');
      TasteNum9 : Exit('Num9');
      TasteNum4 : Exit('Num4');
      TasteNum5 : Exit('Num5');
      TasteNum6 : Exit('Num6');
      TasteNum1 : Exit('Num1');
      TasteNum2 : Exit('Num2');
      TasteNum3 : Exit('Num3');
      TasteNum0 : Exit('Num0');
      TasteNumKomma : Exit('Num,');
    end;
    ZeroMemory(@keystate, Sizeof(Windows.TKeyboardState));
    setlength(Result, 10);
    copiedChars := Windows.ToUnicode(MapVirtualKey(ord(Key), 1), ord(Key), keystate, @Result[1], 10, 0);
    if copiedChars <= 0 then Result := ''
    else if copiedChars = 1 then setlength(Result, 1)
    else if copiedChars >= 2 then setlength(Result, Min(10, copiedChars));
    // remove control chars
    if (length(Result) >= 1) and ((ord(Result[1]) <= 31) or (ord(Result[1]) = 127)) then Result := '';
  end;

begin
  Result := '';
  case Key of
    TasteLeerTaste : Result := 'Space';
    TasteEnter : Result := 'Enter';
    TasteNumEnter : Result := 'NumEnter';
    TasteRücktaste : Result := 'Backspace';
    TastePOS1 : Result := 'Home';
    TasteEnde : Result := 'End';
    TasteEntf : Result := 'Del';
    TasteEsc : Result := 'Esc';
    TasteRollen : Result := 'Scroll';
    TasteTabulator : Result := 'Tab';
    TasteBildOben : Result := 'PageUp';
    TasteZirkumflex : Result := '^';
    TasteF1 : Result := 'F1';
    TasteF2 : Result := 'F2';
    TasteF3 : Result := 'F3';
    TasteF4 : Result := 'F4';
    TasteF5 : Result := 'F5';
    TasteF6 : Result := 'F6';
    TasteF7 : Result := 'F7';
    TasteF8 : Result := 'F8';
    TasteF9 : Result := 'F9';
    TasteF10 : Result := 'F10';
    TasteF11 : Result := 'F11';
    TasteF12 : Result := 'F12';
    TastePfeilLinks : Result := '←';
    TastePfeilRechts : Result := '→';
    TastePfeilOben : Result := '↑';
    TastePfeilUnten : Result := '↓';
    TasteAkzent : Result := '´';
  else Result := ToStr().ToUpper;
  end;
end;

function TKeyboard.Alt : boolean;
begin
  Result := KeyIsDown(TasteAltLeft);
end;

function TKeyboard.AltGr : boolean;
begin
  Result := KeyIsDown(TasteAltGr);
end;

function TKeyboard.AnyKeyIsDown(Keys : SetKeyboard) : boolean;
var
  Key : EnumKeyboardKey;
begin
  for Key in Keys do
    if KeyIsDown(Key) then Exit(true);
  Result := false;
end;

function TKeyboard.AnyKeyUp(Keys : SetKeyboard) : boolean;
var
  Key : EnumKeyboardKey;
begin
  for Key in Keys do
    if FKeyData.ContainsKey(ord(Key)) and ((FKeyData.Items[ord(Key)] and BITMASK_BUTTONUP) <> 0) then Exit(true);
  Result := false;
end;

procedure TKeyboard.CleanButtonState;
begin
  FKeyData.Clear;
end;

procedure TKeyboard.CleanKeyData;
var
  Key : word;
begin
  for Key in FKeyData.Keys do
  begin
    // die Taste wurde losgelassen, also Raus aus der List
    if (FKeyData.Items[Key] and BITMASK_BUTTONUP) <> 0 then FKeyData.Remove(Key)
      // die Taste wurde nach unten gedrückt, also den Status auf isUnten setzen
    else if (FKeyData.Items[Key] and BITMASK_BUTTONDOWN) <> 0 then FKeyData.Items[Key] := BITMASK_BUTTONISDOWN;
  end;
  FDataFromLastFrame.Clear;
end;

function TKeyboard.KeyUp(Taste : EnumKeyboardKey) : boolean;
begin
  Result := false;
  if FKeyData.ContainsKey(ord(Taste)) then Result := (FKeyData[ord(Taste)] and BITMASK_BUTTONUP) <> 0;
end;

function TKeyboard.Shift : boolean;
begin
  Result := KeyIsDown(TasteShiftLinks) or KeyIsDown(TasteShiftRechts);
end;

function TKeyboard.Strg : boolean;
begin
  Result := KeyIsDown(TasteSTRGLinks) or KeyIsDown(TasteSTRGRechts);
end;

{ TKeyboardRaw }

constructor TKeyboardRaw.Create(RawInputFactory : TObject; RawInputGeräteHandle : RRawInputDeviceHandle);
begin
  inherited Create;
  FRRawInputDeviceHandle := RawInputGeräteHandle;
  FRawInputFactory := RawInputFactory;
end;

function GetCharFromVirtualKey(Key : word) : string;
var
  asciiResult : integer;
begin
  setlength(Result, 2);
  asciiResult := ToAscii(Key, MapVirtualKey(Key, 0), nil, @Result[1], 0);
  case asciiResult of
    0 : Result := '';
    1 : setlength(Result, 1);
    2 :;
  else
    Result := '';
  end;
end;

procedure TKeyboardRaw.Idle;
begin
  CleanKeyData;
end;

function TKeyboardRaw.KonvertiereScanCode(ScanCode, Flags : word) : word;
var
  AltVersion : boolean;
begin
  // handelt es sich bei der Taste um eine alternative Taste (z.B. Numblock Enter)
  AltVersion := (Flags and RI_KEY_E0) <> 0;
  if not AltVersion then Result := ScanCode
  else Result := ScanCode + $80;
end;

procedure TKeyboardRaw.VerarbeiteDaten(RawInputDaten : tagRAWINPUT);
var
  ScanCode : word;
  KeyDown, KeyUp : boolean;
begin
  ScanCode := KonvertiereScanCode(RawInputDaten.Keyboard.MakeCode, RawInputDaten.Keyboard.Flags);
  if HGeneric.SucheItemInArray<word>(ScanCode, KEYBOARDSCANCODEIGNORLIST) then Exit;
  KeyDown := RawInputDaten.Keyboard.message = WM_KEYDOWN;
  KeyUp := RawInputDaten.Keyboard.message = WM_KEYUP;
  if FKeyData.ContainsKey(ScanCode) then
  begin
    if KeyUp then
    begin
      FKeyData[ScanCode] := BITMASK_BUTTONUP;
    end
    // wenn eine Taste bereits eingetragen wurde und erneut KeyDown Ereignis ankommt, wird es ignoriert
    else if KeyDown then Exit;
  end
  else if KeyDown then FKeyData.Add(ScanCode, BITMASK_BUTTONDOWN or BITMASK_BUTTONISDOWN);
  FDataFromLastFrame.Add(TPair<EnumKeyboardKey, boolean>.Create(EnumKeyboardKey(ScanCode), KeyUp));
  // Neue Daten sind da, also benachrichtigen
  if Assigned(OnDataChange) then OnDataChange(EnumKeyboardKey(ScanCode), KeyUp);
end;

{ TKeyboardDirectInput }

constructor TKeyboardDirectInput.Create(handle : hwnd;
  DirectInputFactory : TObject; DirectInput : IDirectInput8;
  ExklusiverZugriff : boolean);
var
  BufferEigenschaften : TDIProPDWord;
begin
  inherited Create;
  FDirectInputFactory := DirectInputFactory;
  // Zugriff auf das Tastaturdevice holen
  HLog.CheckDX9Error(DirectInput.CreateDevice(GUID_SysKeyboard, FTastaturDevice, nil), 'Fehler beim Zugriff auf die Tastatur.');
  // und Zugriff festlegen
  if ExklusiverZugriff then FTastaturDevice.SetCooperativeLevel(handle, DISCL_EXCLUSIVE or DISCL_FOREGROUND)
  else FTastaturDevice.SetCooperativeLevel(handle, DISCL_NONEXCLUSIVE or DISCL_FOREGROUND);
  // Datenformat festlegen (vorgegeben durch SDK)
  FTastaturDevice.SetDataFormat(c_dfDIKeyboard);
  // Tastatur auf BufferedDataReading einstellen
  with BufferEigenschaften do
  begin
    diph.dwSize := Sizeof(TDIProPDWord);
    diph.dwHeaderSize := Sizeof(TDIPropHeader);
    diph.dwObj := 0;
    diph.dwHow := DIPH_Device;
    // 32 (oder was auch immer in der Konstante drin steht) Datenpakete werden gepuffert
    dwdata := DIKEYBOARDBUFFERSIZE;
  end;
  FTastaturDevice.SetProperty(DIPROP_BUFFERSIZE, @BufferEigenschaften.diph);
  // Fehler(FTastaturDevice.Acquire, 'TKeyboardDirectInput.Create: Fehler beim Acquire');
end;

destructor TKeyboardDirectInput.Destroy;
begin
  FTastaturDevice.Unacquire;
  FTastaturDevice := nil;
  // aus der DirectInputFactory austragen
  TInputDeviceManager.TDirectInputFactory(FDirectInputFactory).FTastaturDirectInputListe.Remove(self);
  inherited;
end;

procedure TKeyboardDirectInput.Idle;
var
  Buffer : array [0 .. DIKEYBOARDBUFFERSIZE - 1] of TDIDEVICEOBJECTDATA;
  ElementeImBuffer : Cardinal;
  FehlerCode, i : integer;
begin
  inherited;
  FTastaturDevice.Acquire;
  ElementeImBuffer := DIKEYBOARDBUFFERSIZE;
  FehlerCode := FTastaturDevice.GetDeviceData(Sizeof(TDIDEVICEOBJECTDATA), @Buffer, ElementeImBuffer, 0);
  case FehlerCode of
    // Wenn der Zugriff auf das Device fehlt
    DIERR_INPUTLOST, DIERR_NOTACQUIRED :
      begin
        // wird versucht dieser zu bekommen und die Daten erneut abzurufen
        if FTastaturDevice.Acquire <> DI_OK then
        begin
          Exit;
        end;
        Idle;
        Exit;
      end;
  end;
  CleanKeyData;
  for i := 0 to integer(ElementeImBuffer) - 1 do VerarbeiteDaten(Buffer[i]);
end;

procedure TKeyboardDirectInput.VerarbeiteDaten(DITastaturDaten : TDIDEVICEOBJECTDATA);
var
  ScanCode : Cardinal;
begin
  ScanCode := DITastaturDaten.dwOfs;
  // wenn die Taste bereits erfasst ist, wurde Sie runtergedrückt
  if FKeyData.ContainsKey(ScanCode) then
  begin
    // also ist einizige mögliche Aktion, sie wurde losgelassen, wenn das so ist, Daten ändern
    if ((DITastaturDaten.dwdata and $80) = 0) then FKeyData.Items[ScanCode] := BITMASK_BUTTONUP;
  end
  else
    // Taste nicht erfasst, also wurde sie heruntergedrückt
    if (DITastaturDaten.dwdata and $80) <> 0 then FKeyData.Add(ScanCode, BITMASK_BUTTONDOWN or BITMASK_BUTTONISDOWN);
  FDataFromLastFrame.Add(TPair<EnumKeyboardKey, boolean>.Create(EnumKeyboardKey(ScanCode), ((DITastaturDaten.dwdata and $80) = 0)));
  if Assigned(OnDataChange) then OnDataChange(EnumKeyboardKey(ScanCode), ((DITastaturDaten.dwdata and $80) = 0));
end;

{ TGameControllerDirectInput }

constructor TGameControllerDirectInput.Create(GamecontrollerGUID : TGUID; handle : hwnd; DirectInputFactory : TObject; DirectInput : IDirectInput8; ExklusiverZugriff : boolean);
var
  BufferEigenschaften : TDIProPDWord;
begin
  FDirectInputFactory := DirectInputFactory;
  // Zugriff auf das GameControllerdevice holen
  HLog.CheckDX9Error(DirectInput.CreateDevice(GamecontrollerGUID, FGameControllerDevice, nil), 'Fehler beim Zugriff auf den GameController.');
  if not Assigned(FGameControllerDevice) then raise EControllerDeviceNotFoundException.Create('TGameControllerDirectInput.Create failed!');
  // und Zugriff festlegen
  if ExklusiverZugriff then FGameControllerDevice.SetCooperativeLevel(handle, DISCL_EXCLUSIVE or DISCL_FOREGROUND)
  else FGameControllerDevice.SetCooperativeLevel(handle, DISCL_NONEXCLUSIVE or DISCL_FOREGROUND);
  // Datenformat festlegen (vorgegeben durch SDK)
  FGameControllerDevice.SetDataFormat(c_dfDIJoystick);
  // GameController auf BufferedDataReading einstellen
  with BufferEigenschaften do
  begin
    diph.dwSize := Sizeof(TDIProPDWord);
    diph.dwHeaderSize := Sizeof(TDIPropHeader);
    diph.dwObj := 0;
    diph.dwHow := DIPH_Device;
    // 32 (oder was auch immer in der Konstante drin steht) Datenpakete werden gepuffert
    dwdata := DIGAMECONTROLLERBUFFERSIZE;
  end;
  FGameControllerDevice.SetProperty(DIPROP_BUFFERSIZE, @BufferEigenschaften.diph);
  // GameController Achsenmodus auf Relativ stellen, so dass nur die Änderungen ankommen
  with BufferEigenschaften do
  begin
    diph.dwSize := Sizeof(TDIProPDWord);
    diph.dwHeaderSize := Sizeof(TDIPropHeader);
    diph.dwObj := 0;
    diph.dwHow := DIPH_Device;
    // 32 (oder was auch immer in der Konstante drin steht) Datenpakete werden gepuffert
    dwdata := DIPROPAXISMODE_ABS;
  end;
  FGameControllerDevice.SetProperty(DIPROP_AXISMODE, @BufferEigenschaften.diph);
  HLog.CheckDX9Error(FGameControllerDevice.Acquire, 'TGameControllerDirectInput.Create: Fehler beim Acquire');
end;

destructor TGameControllerDirectInput.Destroy;
begin
  if Assigned(FGameControllerDevice) then
      FGameControllerDevice.Unacquire;
  FGameControllerDevice := nil;
  // aus der DirectInputFactory austragen
  TInputDeviceManager.TDirectInputFactory(FDirectInputFactory).FGeräteDirectInputListe.Remove(self);
end;

procedure TGameControllerDirectInput.Idle;
var
  Data : array [0 .. DIGAMECONTROLLERBUFFERSIZE - 1] of TDIDEVICEOBJECTDATA;
  DataCount : Cardinal;
  FehlerCode, i : integer;
begin
  // bei GameControllern müssen die Daten extra "abgeholt" werden
  FehlerCode := FGameControllerDevice.Poll;
  case FehlerCode of
    // Wenn der Zugriff auf das Device fehlt
    DIERR_INPUTLOST, DIERR_NOTACQUIRED :
      begin
        // wird versucht dieser zu bekommen und die Daten erneut abzurufen
        if FGameControllerDevice.Acquire <> DI_OK then
        begin
          Exit;
        end;
        Idle;
        Exit;
      end;
  end;
  MaintainButtonArray();
  DataCount := DIGAMECONTROLLERBUFFERSIZE;
  FGameControllerDevice.GetDeviceData(Sizeof(TDIDEVICEOBJECTDATA), @Data, DataCount, 0);
  for i := 0 to DataCount - 1 do VerarbeiteDaten(Data[i]);
end;

procedure TGameControllerDirectInput.MaintainButtonArray;
var
  i : integer;
begin
  // clear all temporary states (buttondown, buttonup), only buttonisdown can persit
  for i := 0 to length(FButtonState) - 1 do FButtonState[i] := (FButtonState[i] and BITMASK_BUTTONISDOWN);
end;

procedure TGameControllerDirectInput.VerarbeiteDaten(DIGameControllerDaten : TDIDEVICEOBJECTDATA);
begin
  // handelt es sich bei der Aktion um eine Maustaste?
  if (DIGameControllerDaten.dwOfs >= DIJOFS_BUTTON0) and (DIGameControllerDaten.dwOfs <= DIJOFS_BUTTON31) then
  begin
    // Index ergibt sich aus der Differenz zu ersten Mausknopfkonstante, da Konstanten aufeinanderfolgend sind
    // DIGameControllerDaten.dwData and $80 = 0, laut SDK Maustaste unten, ansonsten Oben
    if (DIGameControllerDaten.dwdata and $80) <> 0 then FButtonState[DIGameControllerDaten.dwOfs - DIJOFS_BUTTON0] := BITMASK_BUTTONDOWN or BITMASK_BUTTONISDOWN
    else FButtonState[DIGameControllerDaten.dwOfs - DIJOFS_BUTTON0] := BITMASK_BUTTONUP;
  end
  // nein, dann wurde die Maus bewegt
  else
  begin
    case DIGameControllerDaten.dwOfs of
      DIJOFS_RX : FRXAxis := (DIGameControllerDaten.dwdata / MAXAXISDEFLECTION) * 2 - 1;
      DIJOFS_RY : FRYAxis := (DIGameControllerDaten.dwdata / MAXAXISDEFLECTION) * 2 - 1;
      DIJOFS_RZ : FVAxis := (DIGameControllerDaten.dwdata / MAXAXISDEFLECTION) * 2 - 1;
      DIJOFS_X : FLXAxis := (DIGameControllerDaten.dwdata / MAXAXISDEFLECTION) * 2 - 1;
      DIJOFS_Y : FLYAxis := (DIGameControllerDaten.dwdata / MAXAXISDEFLECTION) * 2 - 1;
      DIJOFS_Z : FUAxis := (DIGameControllerDaten.dwdata / MAXAXISDEFLECTION) * 2 - 1;
    else
      begin
        if DIGameControllerDaten.dwOfs = DIJOFS_POV(0) then
        begin
          FDigiPad := DegToRad(DIGameControllerDaten.dwdata);
        end;
      end;
    end;
  end;
end;

{ TInputHeapData }

function TInputHeapData.ToString : string;
begin

end;

{ TInputDevice }

procedure TInputDevice.Idle;
begin

end;

{ TGameController }

function TGameController.GCButtonDown(Button : integer) : boolean;
begin
  assert(InRange(Button, 0, MAXBUTTONCOUNT));
  Result := (FButtonState[Button] and BITMASK_BUTTONDOWN) <> 0;
end;

function TGameController.GCButtonIsDown(Button : integer) : boolean;
begin
  assert(InRange(Button, 0, MAXBUTTONCOUNT));
  Result := (FButtonState[Button] and BITMASK_BUTTONISDOWN) <> 0;
end;

function TGameController.GCButtonUp(Button : integer) : boolean;
begin
  assert(InRange(Button, 0, MAXBUTTONCOUNT));
  Result := (FButtonState[Button] and BITMASK_BUTTONUP) <> 0;
end;

function TGameController.GetLeftStick : RVector2;
begin
  Result := RVector2.Create(FLXAxis, FLYAxis);
end;

function TGameController.GetRightStick : RVector2;
begin
  Result := RVector2.Create(FRXAxis, FRYAxis);
end;

{ RBinding }

constructor RBinding.Create(KeyboardKeyCode : EnumKeyboardKey);
begin
  self.KeyboardKeyCode := KeyboardKeyCode;
  self.MouseKeyCode := mbNone;
  self.Strg := false;
  self.Alt := false;
  self.Shift := false;
end;

constructor RBinding.Create(MouseKeyCode : EnumMouseButton);
begin
  self.KeyboardKeyCode := TasteNone;
  self.MouseKeyCode := MouseKeyCode;
  self.Strg := false;
  self.Alt := false;
  self.Shift := false;
end;

class function RBinding.EMPTY : RBinding;
begin
  ZeroMemory(@Result, Sizeof(RBinding));
end;

function RBinding.IsEmpty : boolean;
begin
  Result := (KeyboardKeyCode = TasteNone) and (MouseKeyCode = mbNone);
end;

function RBinding.IsEqual(const R : RBinding) : boolean;
begin
  Result := CompareMem(@self, @R, Sizeof(RBinding));
end;

constructor RBinding.CreateFromString(const Value : string);
var
  Splitted : TArray<string>;
  KeyCode : integer;
begin
  self := EMPTY;
  Splitted := Value.Trim.Split(['_']);
  if length(Splitted) > 0 then
  begin
    self.Strg := Splitted[0].Contains('Strg');
    self.Shift := Splitted[0].Contains('Shift');
    self.Alt := Splitted[0].Contains('Alt');
  end;
  if (length(Splitted) > 1) and TryStrToInt(Splitted[1], KeyCode) then
      HRtti.TryIntegerToEnumeration<EnumKeyboardKey>(KeyCode, self.KeyboardKeyCode);
  if (length(Splitted) > 2) and TryStrToInt(Splitted[2], KeyCode) then
      HRtti.TryIntegerToEnumeration<EnumMouseButton>(KeyCode, self.MouseKeyCode);
end;

function RBinding.SaveToString : string;
begin
  Result := '';
  if Strg then Result := Result + 'Strg';
  if Shift then Result := Result + 'Shift';
  if Alt then Result := Result + 'Alt';
  Result := Result + '_';
  Result := Result + IntToStr(ord(KeyboardKeyCode)) + '_' +
    IntToStr(ord(MouseKeyCode));
end;

function RBinding.ToString : string;
begin
  if IsEmpty then Result := ''
  else Result := ToStringRaw;
end;

function RBinding.ToStringRaw : string;
begin
  Result := '';
  if Strg then Result := Result + 'Strg+';
  if Shift then Result := Result + 'Shift+';
  if Alt then Result := Result + 'Alt+';
  if KeyboardKeyCode <> TasteNone then Result := Result + TKeyboard.KeyToString(KeyboardKeyCode)
  else if MouseKeyCode <> mbNone then Result := Result + TMouse.ButtonToString(MouseKeyCode);
end;

function RBinding.WithAlt : RBinding;
begin
  Result := self;
  Result.Alt := true;
end;

function RBinding.WithShift : RBinding;
begin
  Result := self;
  Result.Shift := true;
end;

function RBinding.WithStrg : RBinding;
begin
  Result := self;
  Result.Strg := true;
end;

{ TKeybindingManager<T> }

procedure TKeybindingManager<T>.AddMapping(const Key : T; const Binding : RBinding);
begin
  AddMapping(Key, [Binding]);
end;

procedure TKeybindingManager<T>.AddMapping(const Key : T; Binding : array of RBinding);
var
  Bindings : TList<RBinding>;
begin
  if not FMapping.TryGetValue(Key, Bindings) then
  begin
    Bindings := TList<RBinding>.Create(
      TComparer<RBinding>.Construct(
      function(const L, R : RBinding) : integer
      begin
        // sort for most specifying bindings coming first
        Result := -((ord(L.Strg) + ord(L.Alt) + ord(L.Shift)) - (ord(R.Strg) + ord(R.Alt) + ord(R.Shift)));
      end
      )
      );
    FMapping.Add(Key, Bindings);
  end;
  Bindings.AddRange(Binding);
  Bindings.Sort;
end;

procedure TKeybindingManager<T>.BlockBindings(const Keys : array of T);
var
  i : integer;
begin
  for i := 0 to length(Keys) - 1 do
      FBlocks.AddOrSetValue(Keys[i], true);
end;

constructor TKeybindingManager<T>.Create(Mouse : TMouse; Keyboard : TKeyboard);
begin
  FMouse := Mouse;
  FKeyboard := Keyboard;
  FMapping := TObjectDictionary < T, TList < RBinding >>.Create([doOwnsValues]);
  FBlocks := TDictionary<T, boolean>.Create;
end;

destructor TKeybindingManager<T>.Destroy;
begin
  FMapping.Free;
  FBlocks.Free;
  inherited;
end;

function TKeybindingManager<T>.GetMapping(const Key : T; Index : integer) : RBinding;
var
  Bindings : TList<RBinding>;
begin
  if FMapping.TryGetValue(Key, Bindings) then
  begin
    if Bindings.Count > index then
        Result := Bindings[index]
    else
        Result := RBinding.EMPTY;
  end
  else Result := RBinding.EMPTY;
end;

function TKeybindingManager<T>.IsKeyBlocked(const Key : T) : boolean;
var
  Blocked : boolean;
begin
  Result := FBlocks.TryGetValue(Key, Blocked) and Blocked;
end;

function TKeybindingManager<T>.KeyDown(const Key : T) : boolean;
var
  Bindings : TList<RBinding>;
  Binding : RBinding;
  i : integer;
begin
  if not IsKeyBlocked(Key) and FMapping.TryGetValue(Key, Bindings) then
  begin
    for i := 0 to Bindings.Count - 1 do
    begin
      Binding := Bindings[i];
      if Binding.KeyboardKeyCode <> TasteNone then Result := FKeyboard.KeyDown(Binding.KeyboardKeyCode)
      else if Binding.MouseKeyCode <> mbNone then Result := FMouse.ButtonDown(Binding.MouseKeyCode)
      else Result := false;
      Result := Result and
        (not Binding.Strg or FKeyboard.Strg) and
        (not Binding.Alt or FKeyboard.Alt) and
        (not Binding.Shift or FKeyboard.Shift);
      if Result then
          break;
    end;
  end
  else Result := false;
end;

function TKeybindingManager<T>.KeyIsDown(const Key : T) : boolean;
var
  Bindings : TList<RBinding>;
  Binding : RBinding;
  i : integer;
begin
  if not IsKeyBlocked(Key) and FMapping.TryGetValue(Key, Bindings) then
  begin
    for i := 0 to Bindings.Count - 1 do
    begin
      Binding := Bindings[i];
      if Binding.KeyboardKeyCode <> TasteNone then Result := FKeyboard.KeyIsDown(Binding.KeyboardKeyCode)
      else if Binding.MouseKeyCode <> mbNone then Result := FMouse.ButtonIsDown(Binding.MouseKeyCode)
      else Result := false;
      Result := Result and
        (not Binding.Strg or FKeyboard.Strg) and
        (not Binding.Alt or FKeyboard.Alt) and
        (not Binding.Shift or FKeyboard.Shift);
      if Result then
          break;
    end;
  end
  else Result := false;
end;

function TKeybindingManager<T>.KeyUp(const Key : T) : boolean;
var
  Bindings : TList<RBinding>;
  Binding : RBinding;
  i : integer;
begin
  if not IsKeyBlocked(Key) and FMapping.TryGetValue(Key, Bindings) then
  begin
    for i := 0 to Bindings.Count - 1 do
    begin
      Binding := Bindings[i];
      if Binding.KeyboardKeyCode <> TasteNone then Result := FKeyboard.KeyUp(Binding.KeyboardKeyCode)
      else if Binding.MouseKeyCode <> mbNone then Result := FMouse.ButtonUp(Binding.MouseKeyCode)
      else Result := false;
      Result := Result and
        (not Binding.Strg or FKeyboard.Strg) and
        (not Binding.Alt or FKeyboard.Alt) and
        (not Binding.Shift or FKeyboard.Shift);
      if Result then
          break;
    end;
  end
  else Result := false;
end;

procedure TKeybindingManager<T>.RemoveMapping(const Key : T; Index : integer);
var
  Bindings : TList<RBinding>;
begin
  if FMapping.TryGetValue(Key, Bindings) and (Bindings.Count > index) then
      Bindings[index] := RBinding.EMPTY;
end;

procedure TKeybindingManager<T>.SetMapping(const Key : T; Index : integer; const Binding : RBinding);
var
  Bindings : TList<RBinding>;
begin
  if not FMapping.TryGetValue(Key, Bindings) then
  begin
    Bindings := TList<RBinding>.Create;
    FMapping.Add(Key, Bindings);
  end;
  while Bindings.Count <= index do
      Bindings.Add(RBinding.EMPTY);
  Bindings[index] := Binding;
end;

procedure TKeybindingManager<T>.UnblockBindings(const Keys : array of T);
var
  i : integer;
begin
  for i := 0 to length(Keys) - 1 do
      FBlocks.AddOrSetValue(Keys[i], false);
end;

initialization

Mouse := TDummyMouse.Create;
_DefaultMouse := Mouse;
Keyboard := TDummyKeyboard.Create;
_DefaultKeyboard := Keyboard;

finalization

FreeAndNil(_DefaultMouse);
FreeAndNil(_DefaultKeyboard);
FreeAndNil(DIDevicesFound);

end.
