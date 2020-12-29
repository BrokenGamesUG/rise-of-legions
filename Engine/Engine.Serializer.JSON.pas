unit Engine.Serializer.JSON;

interface


uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Math,
  System.DateUtils,
  Generics.Collections,
  Engine.Serializer.Types,
  Engine.Helferlein;

type

  /// ////////////////////////////////////////////////////////////////////////////
  /// ////////////////////////////////// JSON ////////////////////////////////////
  /// ////////////////////////////////////////////////////////////////////////////

  EJSONTypeMismatchException = class(Exception);
  EJSONConvertError = class(Exception);

  TJSONData = class;
  TJSONValue = class;
  TJSONArray = class;
  TJSONObject = class;

  EnumJSONType = (jtValue, jtObject, jtArray, jtNull);

  TJSONData = class
    private
      FJSONType : EnumJSONType;
      procedure MatchType(JSONType : EnumJSONType);
    public
      property JSONType : EnumJSONType read FJSONType;
      class function FromTValue(const Value : TValue) : TJSONData;
      // ============================ JSON-Type test ==========================
      function IsValue : boolean;
      function IsObject : boolean;
      function IsArray : boolean;
      // ============================ Conversion ==============================
      function AsValue : TJSONValue;
      function AsObject : TJSONObject;
      function AsArray : TJSONArray;
      // ============================ JSON -> Object ==========================
      function AsTValue(TypeInfo : PTypeInfo) : TValue; virtual; abstract;
      function AsType<T> : T;
      // =========================== Object -> JSON ===========================
      function AsJSONString : string; virtual; abstract;
      function ToString : string; override;
      // =========================== Tools ====================================
      function Clone : TJSONData;
  end;

  TJSONNull = class(TJSONData)
    private
      constructor Create;
      constructor CreateFromValue(const Value : TValue);
    public
      function AsTValue(TypeInfo : PTypeInfo) : TValue; override;
      function AsJSONString : string; override;
  end;

  EnumJSONValueSubtype = (jstInteger, jstFloat, jstString, jstBoolean);

  TJSONValue = class(TJSONData)
    private
      FValue : string;
      FJSONSubtype : EnumJSONValueSubtype;

      constructor Create(const Value : string; Subtype : EnumJSONValueSubtype);
    public
      // ============================ Conversion ==============================
      function AsInteger : Int64;
      function AsFloat : Double;
      function AsString : string;
      function AsBoolean : boolean;
      function AsTValue(TypeInfo : PTypeInfo) : TValue; override;
      function AsJSONString : string; override;
      // creation
      constructor CreateFromValue(const Value : TValue);
  end;

  TJSONArray = class(TJSONData)
    public type
      TEnumerator = class(TEnumerator<TJSONData>)
        protected
          FJSONArray : TJSONArray;
          FIndex : Integer;
          function DoGetCurrent : TJSONData; override;
          function DoMoveNext : boolean; override;
        public
          constructor Create(JSONArray : TJSONArray);
      end;
    private
      FItems : TObjectList<TJSONData>;
      constructor Create;
      constructor CreateFromValue(const Value : TValue);
      function GetItems(index : Integer) : TJSONData;
    public
      property Items[index : Integer] : TJSONData read GetItems; default;
      function Count : Integer;
      function AsTValue(TypeInfo : PTypeInfo) : TValue; override;
      function AsJSONString : string; override;
      function GetEnumerator : TEnumerator;
      destructor Destroy; override;
  end;

  TJSONObject = class(TJSONData)
    private
      // if FFields is nil, complete object is nil
      FFields : TObjectDictionary<string, TJSONData>;
      constructor CreateFromValue(const Value : TValue);
      function GetField(Identifier : string) : TJSONData;
      procedure SetField(Identifier : string; const Value : TJSONData);
      function GetBooleanField(Identifier : string) : boolean;
      procedure SetBooleanField(Identifier : string; const Value : boolean);
      function GetIntegerField(Identifier : string) : Integer;
      procedure SetIntegerField(Identifier : string; const Value : Integer);
    public
      constructor Create();
      procedure AddField(Identifier : string; Data : TJSONData);
      property Field[Identifier : string] : TJSONData read GetField write SetField; default;
      property Booleans[Identifier : string] : boolean read GetBooleanField write SetBooleanField;
      property Integers[Identifier : string] : integer read GetIntegerField write SetIntegerField;
      function HasField(const Identifier : string) : boolean;
      function Fields : TArray<TJSONData>;
      function FieldCount : Integer;
      function AsTValue(TypeInfo : PTypeInfo) : TValue; override;
      function AsJSONString : string; override;
      destructor Destroy; override;
  end;

  TJSONSerializer = class
    private type
      EnumToken = (tokObjectStart, tokObjectEnd, tokArrayStart, tokArrayEnd, tokProperty, tokValue, tokValueInteger, tokValueFloat, tokValueString, tokValueBoolean, tokNull, tokEOF);
      SetToken = set of EnumToken;

      RToken = record
        Token : EnumToken;
        Value : string;
        constructor Create(Token : EnumToken; Value : string = '');
      end;
    private
      class function ParseRAWJSON(const JSONData : string) : TList<RToken>;
    public
      class function ParseJSON<T>(const JSONData : string) : T; overload;
      /// <summary> Parse JSON data, creates and load the data into target type.</summary>
      class function ParseJSON(const JSONData : string; TypeInfo : PTypeInfo) : TValue; overload;
      /// <summary> Parse JSON data instring reprensation to datastructure.</summary>
      class function ParseJSON(const JSONData : string) : TJSONData; overload;
      /// <summary> Converts a TValue into a JSON representing string.</summary>
      class function SerializeValue(const Value : TValue) : string; overload;
      class function SerializeValue<T>(const Value : T) : string; overload;
  end;

var
  JsonFloatFormatSettings : TFormatSettings;

implementation


{ TJSONSerializer }

class function TJSONSerializer.ParseRAWJSON(const JSONData : string) : TList<RToken>;

var
  Pos : Integer;
  symbol : Char;

procedure ParseObject(); forward;
procedure ParseArray(); forward;

/// <summary> Read next symbol, if result = False, end of json data reached.</summary>
  function ReadSymbol(SkipSpace : boolean = True) : boolean;
  begin
    Result := Pos <= Length(JSONData);
    symbol := Char(0);
    // data available
    if Result then
    begin
      symbol := JSONData[Pos];
      inc(Pos);
      // skip all space symbols, by read next symbol
      if CharInSet(symbol, [' ', #13, #10]) and SkipSpace then
          Result := ReadSymbol(SkipSpace);
    end;
  end;

  procedure Expect(ASymbol : Char); overload;
  begin
    if ASymbol <> symbol then
        raise EJSONParserError.CreateFmt('TJSONSerializer: Expected symbol %s, but found %s. Buggy JSONData.', [ASymbol, symbol])at ReturnAddress;
  end;

  procedure Expect(Symbols : TSysCharSet); overload;
  var
    ExpectedSymbols : string;
  begin
    if not CharInSet(symbol, Symbols) then
    begin
      ExpectedSymbols := HRtti.SetToString(Symbols);
      raise EJSONParserError.CreateFmt('TJSONSerializer: Expected symbols %s, but found %s. Buggy JSONData.', [ExpectedSymbols, symbol])at ReturnAddress;
    end;
  end;

  procedure ParsePlainValue();
  const
    VALUE_SYMBOLS : TSysCharSet = ['+', '-', '.', '0' .. '9', 't', 'r', 'u', 'e', 'f', 'a', 'l', 's'];
  var
    PlainValue : string;
  begin
    PlainValue := '';
    while CharInSet(symbol, VALUE_SYMBOLS) do
    begin
      PlainValue := PlainValue + symbol;
      ReadSymbol();
    end;
    if (PlainValue = 'true') or (PlainValue = 'false') then
        Result.Add(RToken.Create(tokValueBoolean, PlainValue))
    else if PlainValue.Contains('.') then
        Result.Add(RToken.Create(tokValueFloat, PlainValue))
    else
        Result.Add(RToken.Create(tokValueInteger, PlainValue));
    // go step back if not already end of data reached
    if symbol <> Char(0) then
        dec(Pos);
  end;

  function ParseString() : string;
  var
    CharCode, i : Integer;
    UnicodeCode : string;
  begin
    Result := '';
    // begins with
    Expect('"');
    // string can contain space
    ReadSymbol(False);
    while (symbol <> '"') do
    begin
      // if escape symbol was read, escap next char
      if symbol = '\' then
      begin
        // read symbol that will be escaped
        ReadSymbol(False);
        // if not expect unicode
        if symbol = 'u' then
        begin
          UnicodeCode := '';
          // unicode code is within the next 4 chars
          for i := 0 to 3 do
          begin
            ReadSymbol(False);
            UnicodeCode := UnicodeCode + symbol;
          end;
          if TryStrToInt('$' + UnicodeCode, CharCode) then
              Result := Result + WideChar(CharCode)
          else raise EJSONParserError.CreateFmt('TJSONSerializer: Could not convert unicode %s. Buggy JSONData.', ['\u' + UnicodeCode]);
        end
        else
          // assume a escape char, so simple add it
            Result := Result + symbol;
        ReadSymbol(False);
      end
      else
      begin
        Result := Result + symbol;
        // string can contain space
        ReadSymbol(False);
      end;
    end;
    // ends with
    Expect('"');
  end;

  procedure ParseValue();
  var
    Value : string;
  begin
    ReadSymbol();
    if symbol = '{' then
        ParseObject()
    else if symbol = '[' then
        ParseArray()
    else if symbol = '"' then
    begin
      Result.Add(RToken.Create(tokValue, ''));
      Value := ParseString;
      Result.Add(RToken.Create(tokValueString, Value));
    end
    else if CharInSet(symbol, [']', '}', Char(0), ':']) then
        raise EJSONParserError.CreateFmt('TJSONSerializer: Unexpected token %s found. Buggy JSONData.', [symbol])
    else if symbol = 'n' then
    begin
      ReadSymbol();
      Expect('u');
      ReadSymbol();
      Expect('l');
      ReadSymbol();
      Expect('l');
      Result.Add(RToken.Create(tokNull, ''));
    end
    else
    // last possible case: plain value like true, null or 42
    begin
      Result.Add(RToken.Create(tokValue, ''));
      ParsePlainValue();
    end;
  end;

  procedure ParseObject();
  var
    PropertyName : string;
  begin
    Expect('{');
    Result.Add(RToken.Create(tokObjectStart));
    // get PropertyName
    ReadSymbol();
    while symbol <> '}' do
    begin
      Expect('"');
      PropertyName := ParseString;
      Expect('"');
      Result.Add(RToken.Create(tokProperty, PropertyName));
      // next parse content for Property
      ReadSymbol();
      Expect(':');
      ParseValue();
      ReadSymbol();
      Expect([',', '}']);
      if symbol = ',' then
          ReadSymbol()
    end;
    Expect('}');
    Result.Add(RToken.Create(tokObjectEnd));
  end;

  procedure ParseArray();
  begin
    Expect('[');
    Result.Add(RToken.Create(tokArrayStart));
    ReadSymbol();
    // special case
    // if symbol = ']' array is already closed
    if symbol <> ']' then
    begin
      dec(Pos);
      // get first value
      while symbol <> ']' do
      begin
        ParseValue();
        ReadSymbol();
        Expect([',', ']']);
      end;
    end;
    Result.Add(RToken.Create(tokArrayEnd));
  end;

begin
  Result := TList<RToken>.Create;
  Pos := 1;
  ParseValue();
  ReadSymbol();
  Expect(Char(0));
  Result.Add(RToken.Create(tokEOF));
end;

class function TJSONSerializer.ParseJSON(const JSONData : string) : TJSONData;
var
  tokens : TList<RToken>;
  procedure Next();
  begin
    if tokens.Count > 0 then
        tokens.Delete(0);
  end;
  procedure Expect(Token : EnumToken); overload;
  begin
    if tokens.First.Token <> Token then
        raise EJSONParserError.CreateFmt('TJSONSerializer: Expect token "%s", but found "%s".',
        [HRtti.EnumerationToString<EnumToken>(Token), HRtti.EnumerationToString<EnumToken>(tokens.First.Token)]);
  end;
  procedure Expect(TokenSet : SetToken); overload;
  begin
    if not(tokens.First.Token in TokenSet) then
        raise EJSONParserError.CreateFmt('TJSONSerializer: Expect tokens "%s", but found "%s".',
        [HRtti.SetToString<SetToken>(TokenSet), HRtti.EnumerationToString<EnumToken>(tokens.First.Token)]);
  end;

function ReadData : TJSONData; forward;

  function ReadObject : TJSONObject;
  var
    Identifier : string;
  begin
    Expect(tokObjectStart);
    Result := TJSONObject.Create;
    Next();
    while not(tokens.First.Token in [tokObjectEnd, tokEOF]) do
    begin
      Expect(tokProperty);
      Identifier := tokens.First.Value.ToLowerInvariant();
      Next();
      Result.FFields.Add(Identifier, ReadData);
    end;
    Expect(tokObjectEnd);
    Next();
  end;

  function ReadArray : TJSONArray;
  begin
    Expect(tokArrayStart);
    Result := TJSONArray.Create;
    Next();
    while not(tokens.First.Token in [tokArrayEnd, tokEOF]) do
    begin
      Result.FItems.Add(ReadData);
    end;
    Expect(tokArrayEnd);
    Next();
  end;

  function ReadValue : TJSONValue;
  begin
    Result := nil;
    Expect(tokValue);
    Next();
    Expect([tokValueInteger, tokValueFloat, tokValueString, tokValueBoolean]);
    case tokens.First.Token of
      tokValueInteger : Result := TJSONValue.Create(tokens.First.Value, jstInteger);
      tokValueFloat : Result := TJSONValue.Create(tokens.First.Value, jstFloat);
      tokValueString : Result := TJSONValue.Create(tokens.First.Value, jstString);
      tokValueBoolean : Result := TJSONValue.Create(tokens.First.Value, jstBoolean);
    else assert(False);
    end;
    Next();
  end;

  function ReadNull : TJSONNull;
  begin
    Expect(tokNull);
    Result := TJSONNull.Create;
    Next();
  end;

  function ReadData : TJSONData;
  begin
    case tokens.First.Token of
      tokObjectStart : Result := ReadObject;
      tokArrayStart : Result := ReadArray;
      tokValue : Result := ReadValue;
      tokNull : Result := ReadNull;
    else raise EJSONParserError.CreateFmt('TJSONSerializer.ParseJSON: Unexpected token of type "%s".',
        [HRtti.EnumerationToString<EnumToken>(tokens.First.Token)]);
    end;
  end;

begin
  tokens := ParseRAWJSON(JSONData);
  Result := ReadData;
  tokens.Free;
end;

class function TJSONSerializer.ParseJSON(const JSONData : string; TypeInfo : PTypeInfo) : TValue;
var
  JSONDataObject : TJSONData;
begin
  JSONDataObject := ParseJSON(JSONData);
  Result := JSONDataObject.AsTValue(TypeInfo);
  JSONDataObject.Free;
end;

class function TJSONSerializer.ParseJSON<T>(const JSONData : string) : T;
begin
  Result := ParseJSON(JSONData).AsType<T>;
end;

class function TJSONSerializer.SerializeValue(const Value : TValue) : string;
var
  JSONData : TJSONData;
begin
  JSONData := TJSONData.FromTValue(Value);
  Result := JSONData.AsJSONString;
  JSONData.Free;
end;

class function TJSONSerializer.SerializeValue<T>(const Value : T) : string;
begin
  Result := SerializeValue(TValue.From<T>(Value));
end;

{ TJSONSerializer.RToken }

constructor TJSONSerializer.RToken.Create(Token : EnumToken; Value : string);
begin
  self.Token := Token;
  self.Value := Value;
end;

{ TJSONData }

function TJSONData.AsArray : TJSONArray;
begin
  MatchType(jtArray);
  Result := TJSONArray(self);
end;

function TJSONData.AsObject : TJSONObject;
begin
  MatchType(jtObject);
  Result := TJSONObject(self);
end;

function TJSONData.AsType<T> : T;
begin
  Result := AsTValue(TypeInfo(T)).AsType<T>;
end;

function TJSONData.AsValue : TJSONValue;
begin
  MatchType(jtValue);
  Result := TJSONValue(self);
end;

function TJSONData.Clone : TJSONData;
begin
  Result := TJSONSerializer.ParseJSON(self.AsJSONString);
end;

class function TJSONData.FromTValue(const Value : TValue) : TJSONData;
begin
  Result := nil;
  if Value.IsEmpty then
      Result := TJSONNull.CreateFromValue(Value)
  else
    case Value.Kind of
      tkInteger, tkChar, tkInt64, tkEnumeration, tkFloat, tkString, tkWChar, tkLString, tkWString, tkUString :
        Result := TJSONValue.CreateFromValue(Value);
      tkClass, tkRecord : Result := TJSONObject.CreateFromValue(Value);
      tkArray, tkDynArray : Result := TJSONArray.CreateFromValue(Value);
      tkPointer, tkUnknown, tkProcedure, tkSet, tkMethod, tkVariant, tkInterface, tkClassRef :
        raise EJSONSerializeError.Create('TJSONSerializer: Can''t serialize value to JSON, unsupported type.');
    end;
end;

function TJSONData.IsArray : boolean;
begin
  Result := JSONType in [jtArray, jtNull];
end;

function TJSONData.IsObject : boolean;
begin
  Result := JSONType in [jtObject, jtNull];
end;

function TJSONData.IsValue : boolean;
begin
  Result := JSONType = jtValue;
end;

procedure TJSONData.MatchType(JSONType : EnumJSONType);
begin
  if FJSONType <> JSONType then
      raise EJSONTypeMismatchException.CreateFmt('TJSONData: Type mismatch, can''t cast "%s" to "%s".',
      [HRtti.EnumerationToString<EnumJSONType>(FJSONType), HRtti.EnumerationToString<EnumJSONType>(JSONType)]);
end;

function TJSONData.ToString : string;
begin
  Result := AsJSONString;
end;

{ TJSONArray }

function TJSONArray.AsJSONString : string;
var
  Item : TJSONData;
  StringBuilder : TStringBuilder;
begin
  StringBuilder := TStringBuilder.Create;
  // open array
  StringBuilder.Append('[');
  for Item in FItems do
  begin
    StringBuilder.Append(Item.AsJSONString);
    // sperate items with ','
    if Item <> FItems.Last then
        StringBuilder.Append(', ');
  end;
  // close array
  StringBuilder.Append(']');
  Result := StringBuilder.ToString;
  StringBuilder.Free;
end;

function TJSONArray.AsTValue(TypeInfo : PTypeInfo) : TValue;
var
  ArraySize : NativeInt;
  ElementValue : TValue;
  SetValue : Integer;
  i : Integer;
begin
  if TypeInfo.Kind = tkDynArray then
  begin
    // create empty array and set arraysize
    TValue.Make(nil, TypeInfo, Result);
    ArraySize := Count;
    DynArraySetLength(Pointer(Result.GetReferenceToRawData^), Result.TypeInfo, 1, @ArraySize);

    // load data for every item
    for i := 0 to ArraySize - 1 do
    begin
      // only get element tvalue for typeinfo
      ElementValue := Result.GetArrayElement(i);
      // load real data
      ElementValue := Items[i].AsTValue(ElementValue.TypeInfo);
      Result.SetArrayElement(i, ElementValue);
    end;
  end
  else if TypeInfo.Kind = tkSet then
  begin
    SetValue := 0;
    // load data for every set entry
    for i := 0 to Count - 1 do
        Include(TIntegerSet(SetValue), Items[i].AsValue.AsInteger);
    // and finally convert the common integer set to target settype
    TValue.Make(SetValue, TypeInfo, Result);
  end
  else
      raise ENotSupportedException.CreateFmt('TJSONArray.AsTValue: Can''t convert JSONObject to type "%s".',
      [HRtti.EnumerationToString<TTypeKind>(TypeInfo^.Kind)])
end;

function TJSONArray.Count : Integer;
begin
  Result := FItems.Count;
end;

constructor TJSONArray.Create;
begin
  FItems := TObjectList<TJSONData>.Create();
  FJSONType := jtArray;
end;

constructor TJSONArray.CreateFromValue(const Value : TValue);
var
  i : Integer;
begin
  Create;
  for i := 0 to Value.GetArrayLength - 1 do
      FItems.Add(TJSONData.FromTValue(Value.GetArrayElement(i)))
end;

destructor TJSONArray.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TJSONArray.GetEnumerator : TEnumerator;
begin
  Result := TEnumerator.Create(self);
end;

function TJSONArray.GetItems(index : Integer) : TJSONData;
begin
  Result := FItems[index];
end;

{ TJSONValue }

function TJSONValue.AsBoolean : boolean;
begin
  assert(FJSONSubtype = jstBoolean);
  Result := StrToBool(FValue);
end;

function TJSONValue.AsInteger : Int64;
begin
  assert(FJSONSubtype = jstInteger);
  Result := StrToInt64(FValue);
end;

function TJSONValue.AsJSONString : string;
var
  StringBuilder : TStringBuilder;
  CurrentChar : Char;
begin
  case FJSONSubtype of
    jstFloat, jstInteger, jstBoolean : Result := FValue;
    jstString :
      begin
        StringBuilder := TStringBuilder.Create(Length(FValue) + 2);
        // string has format "a string text"
        StringBuilder.Append('"');
        for CurrentChar in FValue do
        begin
          case CurrentChar of
            '\', '"', '/' : StringBuilder.Append('\').Append(CurrentChar); // Escape them with \
            #$8 : StringBuilder.Append('\b'); // Backspace -> \b
            #$c : StringBuilder.Append('\f'); // Form feed -> \f
            #$a : StringBuilder.Append('\n'); // New line -> \n
            #$d : StringBuilder.Append('\r'); // Carriage return -> \r
            #$9 : StringBuilder.Append('\t'); // Tab -> \t
          else
            begin
              // no special char? simple add them
              if InRange(Ord(CurrentChar), 32, 127) then
                  StringBuilder.Append(CurrentChar)
                // Non ASCII chars need to escaped like \u123a
              else
                  StringBuilder.Append('\u' + IntToHex(Ord(CurrentChar), 4).ToLowerInvariant());
            end;
          end;
        end;
        StringBuilder.Append('"');

        Result := StringBuilder.ToString;
        StringBuilder.Free;
      end;
  end;
end;

function TJSONValue.AsFloat : Double;
begin
  assert(FJSONSubtype = jstFloat);
  Result := StrToFloat(FValue, JsonFloatFormatSettings);
end;

function TJSONValue.AsString : string;
begin
  assert(FJSONSubtype = jstString);
  Result := FValue;
end;

function TJSONValue.AsTValue(TypeInfo : PTypeInfo) : TValue;
var
  Val : Integer;
  ctx : TRttiContext;
begin
  case TypeInfo^.Kind of
    tkInteger, tkInt64 : Result := AsInteger;
    tkEnumeration :
      begin
        if not TryStrToInt(FValue, Val) then
            Val := GetEnumValue(TypeInfo, FValue);
        Result := TValue.FromOrdinal(TypeInfo, Val);
      end;
    tkFloat :
      begin
        // special conversion for datetime
        if SameText(ctx.GetType(TypeInfo).Name, 'TDateTime') then
          try
            Result := ISO8601ToDate(FValue, False)
          except
            on ELocalTimeInvalid do
                Result := ISO8601ToDate(FValue, True);
          end
        else Result := AsFloat;
      end;
    tkChar, tkString, tkWChar, tkLString,
      tkWString, tkUString, tkVariant : Result := AsString;
    tkUnknown, tkSet, tkClass, tkMethod, tkArray, tkRecord, tkInterface, tkDynArray,
      tkClassRef, tkPointer, tkProcedure :
      raise ENotSupportedException.CreateFmt('TJSONValue.AsTValue: Can''t convert a JSONValue to type "%s".',
        [HRtti.EnumerationToString<TTypeKind>(TypeInfo^.Kind)]);
  end;
end;

constructor TJSONValue.Create(const Value : string; Subtype : EnumJSONValueSubtype);
begin
  FJSONType := jtValue;
  FValue := Value;
  FJSONSubtype := Subtype;
end;

constructor TJSONValue.CreateFromValue(const Value : TValue);
begin
  FJSONType := jtValue;
  case Value.Kind of
    tkInteger, tkInt64 : Create(Value.ToString, jstInteger);
    tkFloat : Create(Value.ToString, jstFloat);
    tkEnumeration :
      begin
        if Value.TypeInfo = TypeInfo(boolean) then
            Create(HGeneric.TertOp(boolean(Value.AsOrdinal), 'true', 'false'), jstBoolean)
        else
            Create(Value.AsOrdinal.ToString(), jstInteger);
      end;
    tkString, tkUString, tkChar, tkWChar, tkLString, tkWString : Create(Value.AsString, jstString);
    tkProcedure, tkUnknown, tkPointer, tkClassRef, tkDynArray, tkInterface,
      tkSet, tkClass, tkMethod, tkVariant, tkArray, tkRecord : assert(False);
  end;
end;

{ TJSONObject }

procedure TJSONObject.AddField(Identifier : string; Data : TJSONData);
begin
  FFields.AddOrSetValue(Identifier.ToLowerInvariant, Data);
end;

function TJSONObject.AsJSONString : string;
var
  StringBuilder : TStringBuilder;
  FieldName : string;
  i : Integer;
  FieldNames : AString;
begin
  if assigned(FFields) then
  begin
    StringBuilder := TStringBuilder.Create;
    // start object
    StringBuilder.Append('{');
    // add every field within object
    FieldNames := FFields.Keys.ToArray;
    for i := 0 to Length(FieldNames) - 1 do
    begin
      // create FieldEntry of Format "fieldname": FieldValue
      // fieldname will be converted to lower case
      FieldName := FieldNames[i];
      StringBuilder.Append('"').Append(FieldName.ToLowerInvariant).Append('": ').Append(FFields[FieldName].AsJSONString);
      if i < (Length(FieldNames) - 1) then
          StringBuilder.Append(',').AppendLine;
    end;
    // end object
    StringBuilder.Append('}').AppendLine;
    Result := StringBuilder.ToString;
    StringBuilder.Free;
  end
  else Result := 'null';
end;

function TJSONObject.AsTValue(TypeInfo : PTypeInfo) : TValue;
var
  RttiField : TRttiField;
  RttiType : TRttiType;
  RttiConstructor : TRttiMethod;
  RttiContext : TRttiContext;
begin
  if not(TypeInfo^.Kind in [tkClass, tkRecord]) then
      raise ENotSupportedException.CreateFmt('TJSONObject.AsTValue: Can''t convert JSONObject to type "%s".',
      [HRtti.EnumerationToString<TTypeKind>(TypeInfo^.Kind)]);
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(TypeInfo);
  case TypeInfo^.Kind of
    tkRecord : TValue.Make(nil, TypeInfo, Result);
    tkClass :
      begin
        // to try to convert jsonobject, data has already correct form, so simple return this object
        if (RttiType.Handle = TJSONObject.ClassInfo) or (RttiType.Handle = TJSONData.ClassInfo) then
        begin
          // copy object because this object will be freed
          Result := TJSONSerializer.ParseJSON(AsJSONString).AsObject;
          Exit;
        end
        else
        begin
          RttiConstructor := RttiType.GetParameterlessConstructor();
          if assigned(RttiConstructor) then
              Result := RttiConstructor.Invoke(RttiType.AsInstance.MetaclassType, [])
          else
              raise EJSONConvertError.CreateFmt('TJSONObject.AsTValue: For classtype "%s" was no parameterless constructor found.', [RttiType.Name]);
        end;
      end;
  end;
  for RttiField in RttiType.GetFields do
  begin
    if not HasField(RttiField.Name) then
        raise EJSONConvertError.CreateFmt('TJSONObject.AsTValue: Data for field "%s" is missing.', [RttiField.Name]);
    case TypeInfo^.Kind of
      tkRecord : RttiField.SetValue(Result.GetReferenceToRawData, Field[RttiField.Name].AsTValue(RttiField.FieldType.Handle));
      tkClass : RttiField.SetValue(Result.AsObject, Field[RttiField.Name].AsTValue(RttiField.FieldType.Handle));
    end;
  end;
  RttiContext.Free;
end;

constructor TJSONObject.Create;
begin
  FJSONType := jtObject;
  FFields := TObjectDictionary<string, TJSONData>.Create([doOwnsValues]);
end;

constructor TJSONObject.CreateFromValue(const Value : TValue);
var
  RttiContext : TRttiContext;
  RttiType : TRttiType;
  RttiField : TRttiField;
  FieldValue : TValue;
begin
  FJSONType := jtObject;
  if not Value.IsEmpty then
  begin
    FFields := TObjectDictionary<string, TJSONData>.Create([doOwnsValues]);
    RttiContext := TRttiContext.Create;
    RttiType := RttiContext.GetType(Value.TypeInfo);
    for RttiField in RttiType.GetFields do
    begin
      if Value.IsObject then
          FieldValue := RttiField.GetValue(Value.AsObject)
      else
      begin
        assert(Value.Kind = tkRecord);
        FieldValue := RttiField.GetValue(Value.GetReferenceToRawData);
      end;
      FFields.Add(RttiField.Name, TJSONData.FromTValue(FieldValue));
    end;
    if Length(RttiType.GetProperties) > 0 then
        raise EJSONSerializeError.Create('TJSONObject.CreateFromValue: Currently only serialize fields is supported.');
    RttiContext.Free;
  end;
end;

destructor TJSONObject.Destroy;
begin
  FFields.Free;
  inherited;
end;

function TJSONObject.FieldCount : Integer;
begin
  Result := FFields.Count;
end;

function TJSONObject.Fields : TArray<TJSONData>;
begin
  Result := FFields.Values.ToArray;
end;

function TJSONObject.GetBooleanField(Identifier : string) : boolean;
begin
  Result := self[Identifier].AsType<boolean>;
end;

function TJSONObject.GetField(Identifier : string) : TJSONData;
begin
  Identifier := Identifier.ToLowerInvariant;
  if not HasField(Identifier) then
      AddField(Identifier, TJSONNull.Create);
  Result := FFields[Identifier];
end;

function TJSONObject.GetIntegerField(Identifier : string) : Integer;
begin
  Result := self[Identifier].AsType<Integer>;
end;

function TJSONObject.HasField(const Identifier : string) : boolean;
begin
  Result := FFields.ContainsKey(Identifier.ToLowerInvariant);
end;

procedure TJSONObject.SetBooleanField(Identifier : string; const Value : boolean);
begin
  self[Identifier] := TJSONValue.CreateFromValue(TValue.From<boolean>(Value));
end;

procedure TJSONObject.SetField(Identifier : string; const Value : TJSONData);
begin
  Identifier := Identifier.ToLowerInvariant;
  if not HasField(Identifier) then
      AddField(Identifier, Value)
  else
      FFields[Identifier] := Value;
end;

procedure TJSONObject.SetIntegerField(Identifier : string; const Value : Integer);
begin
  self[Identifier] := TJSONValue.CreateFromValue(TValue.From<Integer>(Value));
end;

{ TJSONArray.TEnumerator }

constructor TJSONArray.TEnumerator.Create(JSONArray : TJSONArray);
begin
  FJSONArray := JSONArray;
  FIndex := -1;
end;

function TJSONArray.TEnumerator.DoGetCurrent : TJSONData;
begin
  Result := FJSONArray.Items[FIndex];
end;

function TJSONArray.TEnumerator.DoMoveNext : boolean;
begin
  inc(FIndex);
  Result := FIndex < FJSONArray.Count;
end;

{ TJSONNull }

function TJSONNull.AsJSONString : string;
begin
  Result := 'null';
end;

function TJSONNull.AsTValue(TypeInfo : PTypeInfo) : TValue;
begin
  TValue.Make(nil, TypeInfo, Result);
end;

constructor TJSONNull.Create;
begin
  FJSONType := jtNull;
end;

constructor TJSONNull.CreateFromValue(const Value : TValue);
begin
  assert(Value.IsEmpty);
  Create;
end;

initialization

JsonFloatFormatSettings := TFormatSettings.Create('en-US');
JsonFloatFormatSettings.DecimalSeparator := '.';

end.
