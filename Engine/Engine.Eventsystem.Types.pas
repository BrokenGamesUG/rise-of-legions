unit Engine.Eventsystem.Types;

interface

uses
  // ------------------------Delphi----------------------------------------------
  System.Rtti,
  System.Typinfo,
  System.SysUtils,
  System.Classes,
  // -----------------------Engine-----------------------------------------------
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows;

type

  ETypeMissmatch = class(Exception);

  EnumParameterType = (ptEmpty, ptUnknown, ptInteger, ptSingle, ptBoolean, ptPointer, ptTObject,
    ptRVector3, ptRColor, ptString, ptArray, ptCardinal, ptRIntVector2, ptMethod, ptByte);

  EnumParameterSlot = (psSlot0, psSlot1, psSlot2, psSlot3, psSlot4);

  SetVarParameter = set of EnumParameterSlot;

  IParameterHeapData = interface
    function GetSize : integer;
    function GetRawDataPointer : Pointer;
  end;

  TStringHeapData = class(TInterfacedObject, IParameterHeapData)
    private
      FData : string;
    public
      constructor Create(Data : string);
      function GetSize : integer;
      function GetRawDataPointer : Pointer;
  end;

  TArrayHeapData<T> = class(TInterfacedObject, IParameterHeapData)
    private
      FData : TArray<T>;
    public
      constructor Create(Data : TArray<T>);
      function GetSize : integer;
      function GetRawDataPointer : Pointer;
  end;

  TAnyHeapData<T> = class(TInterfacedObject, IParameterHeapData)
    private
      FData : T;
    public
      constructor Create(Data : T);
      function GetSize : integer;
      function GetRawDataPointer : Pointer;
  end;

  TRawHeapData = class(TInterfacedObject, IParameterHeapData)
    private
      FData : TBytes;
    public
      constructor CreateFromRawData(Data : Pointer; Size : integer);
      function GetSize : integer;
      function GetRawDataPointer : Pointer;
      function GetData<T> : T;
      destructor Destroy; override;
  end;

  /// <summary> Type that can hold any type and provide severals methods to create RParam fom type and
  /// read type from RParam. Replace TValue and make things faster but more unsafe.
  /// HINT: Read any data from a RParam will NOT convert any data. This will only do a memory cast!</summary>
  RParam = packed record
    public const
      // detemines max size of a type that saved on stack, for types > MAXSTACKSIZE heap memory is allocated
      MAXSTACKSIZE = SizeOf(RVector3);
    private
      FType : EnumParameterType;
      FSize : Byte;
      FHeapData : IParameterHeapData;
      function GetSize : integer;
    public
      /// <summary> Size of saved data in bytes.
      /// For heapdata like string or array will return size of data only, not of data + lengthcounter etc.</summary>
      property Size : integer read GetSize;
      /// <summary> Datatype of saved data. This field is unreliable, because only for typed (non generic)
      /// creation methods informations are created. Only relaiable for string and array data!</summary>
      property DataType : EnumParameterType read FType;
      /// <summary> Create RParam from a Value of generic type T. NOT used it for reference counted types
      /// like arrays or strings. This will cause errors on data access. </summary>
      class function From<T>(Value : T) : RParam; static;
      class function FromProc<T>(Proc : T) : RParam; static;
      class function FromArray<ElementType>(Value : TArray<ElementType>) : RParam; static;
      class function FromRawData(RawData : Pointer; RawDataSize : integer) : RParam; static;
      class function FromTValue(Value : TValue) : RParam; static;
      class function DeserializeFromStream(Stream : TStream) : RParam; static;
      function IsEmpty : boolean;
      function AsType<T> : T;
      function AsEnumType<T> : T;
      function AsProc<T> : T;
      function AsVector3 : RVector3;
      function AsString : string;
      function AsBoolean : boolean;
      function AsSingle : Single;
      function AsInteger : integer;
      function AsByte : Byte;
      // function AsCardinal : Cardinal;
      function AsIntVector2 : RIntVector2;
      function AsArray<ElementType> : TArray<ElementType>;
      function GetRawDataPointer : Pointer;
      function ToString : string;
      procedure SerializeIntoStream(Stream : TStream);
      class operator implicit(a : RVector3) : RParam;
      class operator implicit(a : RColor) : RParam;
      class operator implicit(a : integer) : RParam;
      class operator explicit(a : Byte) : RParam;
      class operator implicit(a : Cardinal) : RParam;
      class operator implicit(a : Single) : RParam;
      class operator implicit(a : TObject) : RParam;
      class operator implicit(a : string) : RParam;
      class operator implicit(a : boolean) : RParam;
      class operator implicit(a : RIntVector2) : RParam;
    private
      case Byte of
        0 : (FInteger : integer);
        1 : (FSingle : Single);
        2 : (FBoolean : boolean);
        3 : (FPointer : Pointer);
        4 : (FObject : TObject);
        5 : (FVector3 : RVector3);
        6 : (FColor : RColor);
        7 : (FByte : Byte);
        8 : (FCardinal : Cardinal);
        9 : (FIntVector2 : RIntVector2);
  end;

const

  RPARAMEMPTY : RParam = ();

type

  ProcEventReadParam0 = function : RParam of object;
  ProcEventReadParam1 = function(var Param1 : RParam) : RParam of object;
  ProcEventReadParam2 = function(var Param1, Param2 : RParam) : RParam of object;
  ProcEventReadParam3 = function(var Param1, Param2, Param3 : RParam) : RParam of object;
  ProcEventReadParam4 = function(var Param1, Param2, Param3, Param4 : RParam) : RParam of object;
  ProcEventReadParam5 = function(var Param1, Param2, Param3, Param4, Param5 : RParam) : RParam of object;

  ProcEventTriggerParam0 = function : boolean of object;
  ProcEventTriggerParam1 = function(var Param1 : RParam) : boolean of object;
  ProcEventTriggerParam2 = function(var Param1, Param2 : RParam) : boolean of object;
  ProcEventTriggerParam3 = function(var Param1, Param2, Param3 : RParam) : boolean of object;
  ProcEventTriggerParam4 = function(var Param1, Param2, Param3, Param4 : RParam) : boolean of object;
  ProcEventTriggerParam5 = function(var Param1, Param2, Param3, Param4, Param5 : RParam) : boolean of object;
  ProcEventTriggerParam6 = function(var Param1, Param2, Param3, Param4, Param5, Param6 : RParam) : boolean of object;

  ERegisterEventException = class(Exception);
  EHandleEventException = class(Exception);
  ENoSubscriberForRead = class(Exception);

  EnumEventPriority = (epFirst, epHigher, epHigh, epMiddle, epLow, epLower, epLast);
  EnumEventScope = (esLocal, esGlobal);
  EnumEventType = (etRead, etTrigger, etWrite);
  EnumNetworkSender = (nsNone, nsClient, nsServer);

  EnumEventIdentifier = Byte;
  SetComponentGroup = set of Byte;

  REntityComponentClassMap = record
    FromClass : TClass;
    ToClass : TClass;
  end;

  XEvent = class(TCustomAttribute)
    public
      FEvent : EnumEventIdentifier;
      FEventPriotity : EnumEventPriority;
      FEventType : EnumEventType;
      FEventScope : EnumEventScope;
    public
      constructor Create(Event : EnumEventIdentifier; EventPriotity : EnumEventPriority; EventType : EnumEventType; EventScope : EnumEventScope = esLocal);
  end;

  /// <summary> Inforecordtype for scriptevents, because script doesn't support attribute for
  /// functions yet. </summary>
  XEventInfo = record
    Event : EnumEventIdentifier;
    EventPriotity : EnumEventPriority;
    EventType : EnumEventType;
    EventScope : EnumEventScope;
  end;

  XNetworkSerialize = class(TCustomAttribute)
    private
      FEvent : EnumEventIdentifier;
    public
      property Event : EnumEventIdentifier read FEvent;
      constructor Create(Event : EnumEventIdentifier);
  end;

  XNetworkBasetype = class(TCustomAttribute);

const
  ALLGROUP : SetComponentGroup = [255];
  ALLGROUPINDEX : Byte         = 255;
  APPLICATIONTYPE              = {$IFDEF SERVER}nsServer{$ELSE}nsClient{$ENDIF};

  // all predefined events : EnumEventIdentifier
  eiNetworkSend : EnumEventIdentifier = 0;
  eiEventFired : EnumEventIdentifier  = 1;
  eiFree = 2;
  eiNewEntity = 3;
  eiSerialize = 4;

implementation

{ RParam }

/// ////////////////////////////////////////////////////////////////////////////
/// To RParam Conversion
/// ////////////////////////////////////////////////////////////////////////////

class operator RParam.implicit(a : RColor) : RParam;
begin
  Result.FColor := a;
  Result.FSize := SizeOf(RColor);
  Result.FType := ptRColor;
end;

class operator RParam.implicit(a : RVector3) : RParam;
begin
  Result.FVector3 := a;
  Result.FSize := SizeOf(RVector3);
  Result.FType := ptRVector3;
end;

class operator RParam.implicit(a : integer) : RParam;
begin
  Result.FInteger := a;
  Result.FSize := SizeOf(integer);
  Result.FType := ptInteger;
end;

class operator RParam.implicit(a : TObject) : RParam;
begin
  Result.FObject := a;
  Result.FSize := SizeOf(TObject);
  Result.FType := ptTObject;
end;

class operator RParam.implicit(a : string) : RParam;
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
end;

class operator RParam.implicit(a : Cardinal) : RParam;
begin
  raise Exception.Create('Fehlermeldung');
  Result.FSingle := a;
  Result.FSize := SizeOf(Cardinal);
  Result.FType := ptCardinal;
end;

class operator RParam.implicit(a : Single) : RParam;
begin
  Result.FSingle := a;
  Result.FSize := SizeOf(Single);
  Result.FType := ptSingle;
end;

class operator RParam.implicit(a : RIntVector2) : RParam;
begin
  Result.FIntVector2 := a;
  Result.FSize := SizeOf(RIntVector2);
  Result.FType := ptRIntVector2;
end;

class operator RParam.explicit(a : Byte) : RParam;
begin
  Result.FByte := a;
  Result.FSize := SizeOf(Byte);
  Result.FType := ptByte;
end;

function RParam.IsEmpty : boolean;
begin
  Result := (FType = ptEmpty) or ((FSize <= 0) and not assigned(FHeapData));
end;

procedure RParam.SerializeIntoStream(Stream : TStream);
var
  Str : string;
begin
  Stream.WriteAny<EnumParameterType>(DataType);
  case DataType of
    // if String SizeOfString + lengthCounter(using word)
    ptString :
      begin
        // convention -> string save length in a word with correct length not a byte
        Str := AsString;
        assert(length(Str) <= high(Word));
        Stream.WriteAny<Word>(length(Str));
        Stream.Write(Str[1], length(Str) * SizeOf(Char));
      end;
  else
    begin
      // first save datalength
      assert(Size <= high(Byte));
      Stream.WriteByte(Size);
      // after that save data
      Stream.WriteData(GetRawDataPointer, Size);
    end;
  end;
end;

function RParam.ToString : string;
begin
  case FType of
    ptEmpty : Result := 'Empty';
    ptUnknown : Result := 'Unknown';
    ptInteger : Result := Inttostr(FInteger);
    ptSingle : Result := FormatFloat('0.##', FSingle);
    ptBoolean : Result := BoolToStr(FBoolean, True);
    ptPointer : Result := Inttostr(NativeInt(FPointer));
    ptTObject : Result := 'Object';
    ptRVector3 : Result := FVector3;
    ptRColor : Result := FColor.toHexString;
    ptString : Result := AsString;
    ptArray : Result := 'Array';
    ptCardinal : Result := Inttostr(FCardinal);
    ptRIntVector2 : Result := FIntVector2;
    ptMethod : Result := 'Method';
    ptByte : Result := Inttostr(FByte);
  else Result := 'No stringhandler for Paramtype ' + HRtti.EnumerationToString<EnumParameterType>(FType);
  end;
end;

class function RParam.From<T>(Value : T) : RParam;
begin
  Result.FSize := SizeOf(T);
  // if RParam can contain type complete save data in variablefield
  if Result.FSize <= MAXSTACKSIZE then
      move(Value, Result.FByte, Result.FSize)
    // else allocate heapdata save data
  else Result.FHeapData := TAnyHeapData<T>.Create(Value);
  Result.FType := ptUnknown;
end;

class function RParam.FromProc<T>(Proc : T) : RParam;
begin
  Result.FSize := 0;
  Result.FHeapData := TAnyHeapData<T>.Create(Proc);
  Result.FType := ptMethod;
end;

class function RParam.FromArray<ElementType>(Value : TArray<ElementType>) : RParam;
begin
  Result.FHeapData := nil;
  Result.FHeapData := TArrayHeapData<ElementType>.Create(Value);
  Result.FSize := 0;
  Result.FType := ptArray;
end;

class function RParam.FromRawData(RawData : Pointer;
  RawDataSize : integer) : RParam;
begin
  Result.FSize := RawDataSize;
  // if RParam can contain type complete save data in variablefield
  if Result.FSize <= MAXSTACKSIZE then
      move(RawData^, Result.FByte, Result.FSize)
    // else allocate heapdata with size of T to save data
  else Result.FHeapData := TRawHeapData.CreateFromRawData(RawData, RawDataSize);
  Result.FType := ptUnknown;
end;

class function RParam.FromTValue(Value : TValue) : RParam;
begin
  case Value.Kind of
    tkInteger, tkRecord, tkEnumeration, tkFloat, tkSet, tkInt64 : Result := RParam.FromRawData(Value.GetReferenceToRawData, Value.DataSize);
    tkClass : Result := Value.AsObject;
    tkString, tkLString, tkWString, tkUString : Result := Value.AsString;
    tkMethod, tkVariant, tkArray, tkChar, tkClassRef, tkWChar, tkDynArray, tkInterface, tkPointer,
      tkProcedure, tkUnknown : raise EConvertError.Create('RParam.FromTValue: Can''t can convert TValue to RParam - Type "' + HRtti.EnumerationToString(Value.Kind) + '" not supported!');
  end;
end;

function RParam.GetRawDataPointer : Pointer;
begin
  if assigned(FHeapData) then
      Result := FHeapData.GetRawDataPointer
  else Result := @FByte;
end;

function RParam.GetSize : integer;
begin
  if FSize > 0 then Result := FSize
  else
  begin
    assert(assigned(FHeapData));
    Result := FHeapData.GetSize;
  end;
end;

/// ////////////////////////////////////////////////////////////////////////////
/// From RParam to Type Conversion
/// ////////////////////////////////////////////////////////////////////////////

procedure ExpectType(Expected, Given : EnumParameterType; AllowOther : boolean = True);
var
  AllowedTypes : set of EnumParameterType;
begin
  if AllowOther then AllowedTypes := [Expected, ptUnknown, ptEmpty]
  else AllowedTypes := [Expected];
  if not(Given in AllowedTypes) then raise ETypeMissmatch.Create(Format('Type "%s" expected but type "%s" found.', [HRtti.EnumerationToString(Expected), HRtti.EnumerationToString(Given)]));
end;

function RParam.AsArray<ElementType> : TArray<ElementType>;
begin
  {$IFDEF DEBUG}
  if FType <> ptArray then raise ETypeMissmatch.Create(Format('Type "%s" expected but type "%s" found.', [HRtti.EnumerationToString<EnumParameterType>(ptArray), HRtti.EnumerationToString<EnumParameterType>(FType)]));
  assert(assigned(FHeapData));
  assert(FHeapData is TArrayHeapData<ElementType>);
  {$ENDIF}
  Result := TArrayHeapData<ElementType>(FHeapData).FData;
end;

function RParam.AsBoolean : boolean;
begin
  {$IFDEF DEBUG}
  ExpectType(ptBoolean, FType);
  {$ENDIF}
  Result := FBoolean;
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
  begin
    {$IFDEF DEBUG}
    if not(FType in [ptEmpty, ptUnknown, ptInteger, ptByte]) then raise ETypeMissmatch.Create(Format('RParam.AsType<T>: Type "%s" was for enumtype not expected!', [HRtti.EnumerationToString<EnumParameterType>(FType)]));
    {$ENDIF}
    if FType = ptEmpty then Result := default (T)
    else
    begin
      {$IFDEF DEBUG}
      assert(SizeOf(T) <= FSize);
      assert(FSize <= MAXSTACKSIZE);
      {$ENDIF}
      // enumtype everytime saved directly
      move(FByte, Result, SizeOf(T));
    end;
  end;
end;

(* function RParam.AsCardinal : Cardinal;
 begin
 {$IFDEF DEBUG}
 ExpectType(ptCardinal, FType);
 {$ENDIF}
 Result := FInteger;
 end; *)

function RParam.AsInteger : integer;
begin
  {$IFDEF DEBUG}
  ExpectType(ptInteger, FType);
  {$ENDIF}
  Result := FInteger;
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
  if not(ptMethod = FType) then raise ETypeMissmatch.Create(Format('Type "ptMethod" expected but type "%s" found.', [HRtti.EnumerationToString<EnumParameterType>(FType)]));
  assert(assigned(FHeapData));
  assert(FHeapData is TAnyHeapData<T>);
  {$ENDIF}
  Result := TAnyHeapData<T>(FHeapData).FData;
end;

function RParam.AsSingle : Single;
begin
  {$IFDEF DEBUG}
  ExpectType(ptSingle, FType);
  {$ENDIF}
  Result := FSingle;
end;

function RParam.AsString : string;
begin
  {$IFDEF DEBUG}
  ExpectType(ptString, FType);
  {$ENDIF}
  if FType = ptEmpty then Result := ''
  else
  begin
    {$IFDEF DEBUG}
    assert(assigned(FHeapData));
    assert(FHeapData is TStringHeapData);
    {$ENDIF}
    Result := TStringHeapData(FHeapData).FData;
  end;
end;

function RParam.AsType<T> : T;
begin
  {$IFDEF DEBUG}
  if (FType in [ptString, ptArray, ptMethod]) then raise ETypeMissmatch.Create(Format('RParam.AsType<T>: For type "%s" generic method should not used!', [HRtti.EnumerationToString<EnumParameterType>(FType)]));
  {$ENDIF}
  if FType = ptEmpty then Result := default (T)
  else
  begin
    {$IFDEF DEBUG}
    assert(FSize = SizeOf(T));
    {$ENDIF}
    // types <= MAXSTACKSIZE are saved directly in varsection
    if FSize <= MAXSTACKSIZE then move(FByte, Result, FSize)
      // for other types heapmemory is allocated
    else
    begin
      assert(assigned(FHeapData));
      if (FHeapData is TRawHeapData) then
          Result := TRawHeapData(FHeapData).GetData<T>
      else
      begin
        assert(FHeapData is TAnyHeapData<T>);
        Result := TAnyHeapData<T>(FHeapData).FData;
      end;
    end;
  end;
end;

function RParam.AsVector3 : RVector3;
begin
  {$IFDEF DEBUG}
  ExpectType(ptRVector3, FType);
  {$ENDIF}
  Result := FVector3;
end;

class function RParam.DeserializeFromStream(Stream : TStream) : RParam;
var
  DataLength : Byte;
  Str : string;
  StringLength : Word;
  Buffer : TArray<Byte>;
  DataType : EnumParameterType;
begin
  DataType := Stream.ReadAny<EnumParameterType>;
  // convention, if datalength = 0, string expected
  if DataType = ptString then
  begin
    StringLength := Stream.ReadWord;
    setlength(Str, StringLength);
    Stream.Read(Str[1], StringLength * SizeOf(Char));
    Result := Str;
  end
  // else any other data
  else
  begin
    DataLength := Stream.ReadByte;
    setlength(Buffer, DataLength);
    Stream.Read(Buffer, DataLength);
    Result := RParam.FromRawData(@Buffer[0], DataLength);
  end;
  Result.FType := DataType;
end;

{ TStringHeapData }

constructor TStringHeapData.Create(Data : string);
begin
  FData := Data;
end;

function TStringHeapData.GetRawDataPointer : Pointer;
begin
  Result := @FData[1];
end;

function TStringHeapData.GetSize : integer;
begin
  Result := SizeOf(Char) * length(FData);
end;

{ TArrayHeapData<T> }

constructor TArrayHeapData<T>.Create(Data : TArray<T>);
begin
  FData := Data;
end;

function TArrayHeapData<T>.GetRawDataPointer : Pointer;
begin
  Result := @FData[0];
end;

function TArrayHeapData<T>.GetSize : integer;
begin
  Result := SizeOf(T) * length(FData);
end;

{ TAnyHeapData }

constructor TRawHeapData.CreateFromRawData(Data : Pointer; Size : integer);
begin
  setlength(FData, Size);
  move(Data^, FData[0], Size);
end;

destructor TRawHeapData.Destroy;
begin
  FData := nil;
  inherited;
end;

function TRawHeapData.GetData<T> : T;
begin
  move(FData[0], Result, length(FData));
end;

function TRawHeapData.GetRawDataPointer : Pointer;
begin
  Result := @FData[0];
end;

function TRawHeapData.GetSize : integer;
begin
  raise Exception.Create('TAnyHeapData<T>.GetSize: Codeblock should never reached!');
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

function TAnyHeapData<T>.GetSize : integer;
begin
  Result := SizeOf(T);
end;

{ XNetworkSerialize }

constructor XNetworkSerialize.Create(Event : EnumEventIdentifier);
begin
  FEvent := Event;
end;

{ XEvent }

{ XEvent }

constructor XEvent.Create(Event : EnumEventIdentifier; EventPriotity : EnumEventPriority; EventType : EnumEventType; EventScope : EnumEventScope);
begin
  FEvent := Event;
  FEventPriotity := EventPriotity;
  FEventType := EventType;
  FEventScope := EventScope;
end;

end.
