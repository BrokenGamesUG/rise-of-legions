unit XFile.Loader;

interface

uses
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  SysUtils,
  Generics.Collections,
  Windows,
  Engine.Math,
  TypInfo,
  Classes,
  XFile.MSZip;

type
  EIncorrectXFileFormatException = class(Exception);
  ENotSupportedXFileFormatException = class(Exception);
  EIsNotAValueDataNode = class(Exception);

  EnumFileFormat = (txt, bin, tzip, bzip);

type
  EnumTokens = (
    DUMMY_0,
    // record-bearing tokens
    TOKEN_NAME,    // = 1
    TOKEN_STRING,  // = 2
    TOKEN_INTEGER, // = 3
    DUMMY_4,
    TOKEN_GUID,         // = 5,
    TOKEN_INTEGER_LIST, // = 6,
    TOKEN_FLOAT_LIST,   // = 7,
    DUMMY_8, DUMMY_9,
    // stand-alone tokens
    TOKEN_OBRACE,    // = 10,
    TOKEN_CBRACE,    // = 11,
    TOKEN_OPAREN,    // = 12,
    TOKEN_CPAREN,    // = 13,
    TOKEN_OBRACKET,  // = 14,
    TOKEN_CBRACKET,  // = 15,
    TOKEN_OANGLE,    // = 16,
    TOKEN_CANGLE,    // = 17,
    TOKEN_DOT,       // = 18,
    TOKEN_COMMA,     // = 19,
    TOKEN_SEMICOLON, // = 20,
    DUMMY_21, DUMMY_22, DUMMY_23, DUMMY_24, DUMMY_25, DUMMY_26, DUMMY_27, DUMMY_28, DUMMY_29, DUMMY_30,
    TOKEN_TEMPLATE, // = 31,
    DUMMY_32, DUMMY_33, DUMMY_34, DUMMY_35, DUMMY_36, DUMMY_37, DUMMY_38, DUMMY_39,
    TOKEN_WORD,    // = 40,
    TOKEN_DWORD,   // = 41,
    TOKEN_FLOAT,   // = 42,
    TOKEN_DOUBLE,  // = 43,
    TOKEN_CHAR,    // = 44,
    TOKEN_UCHAR,   // = 45,
    TOKEN_SWORD,   // = 46,
    TOKEN_SDWORD,  // = 47,
    TOKEN_VOID,    // = 48,
    TOKEN_LPSTR,   // = 49,
    TOKEN_UNICODE, // = 50,
    TOKEN_CSTRING, // = 51,
    TOKEN_ARRAY,   // = 52
    // own tokens ;)
    TOKEN_REFERENCE// = 53
    );

  SetTokens = set of EnumTokens;

  // record for tokens
  RGUID = packed record
    data1 : DWord;
    data2 : Word;
    data3 : Word;
    data4 : array [0 .. 7] of Byte;
    function GetDummy : RGUID;
    procedure ReadData(DataStream : TStream);
  end;

  RIntegerList = record
    Count : DWord;
    List : array of DWord;
    procedure ReadData(DataStream : TStream);
    procedure WriteRawData(DataStream : TStream);
  end;

  RFloatList = record
    Count : DWord;
    List : array of single;
    procedure ReadData(DataStream : TStream);
    procedure WriteRawData(DataStream : TStream);
  end;

  RName = record
    Count : DWord;
    Name : AnsiString;
    procedure ReadData(DataStream : TStream);
    class operator implicit(a : RName) : string;
  end;

  RString = record
    Count : DWord;
    StringData : AnsiString;
    procedure ReadData(DataStream : TStream);
    procedure WriteRawData(DataStream : TStream);
  end;

  // Header of x file
  RHeader = packed record
    const
      MAGICNUMBERCONST = 'xof ';
      FORMATTYPETXT    = 'txt ';
      FORMATTYPEBIN    = 'bin ';
      FORMATTYPETZIP   = 'tzip';
      FORMATTYPEBZIP   = 'bzip';
      DEFAULTFLOATSIZE = '0032';
    var
      MagicNumber : array [0 .. 3] of AnsiChar;
      VersionNumberMajor : array [0 .. 1] of AnsiChar;
      VersionNumberMinor : array [0 .. 1] of AnsiChar;
      FormatType : array [0 .. 3] of AnsiChar;
      FloatSize : array [0 .. 3] of AnsiChar;
      function GetFileFormat : EnumFileFormat;
  end;

  TDataNode = class;

  TTemplate = class
    type
      TTemplateMember = class
        public
          Name : RName;
          TemplateType : TTemplate;
          constructor Create; overload;
          constructor Create(Name : RName; TemplateType : TTemplate); overload;
      end;

      TTemplateMemberArray = class(TTemplateMember)
        DimensionRef : TTemplateMember;
        Dimension : DWord;
        function GetDimension(DataNode : TDataNode) : DWord;
      end;
    var
      Name : string;
      GUID : RGUID;
      Size : DWord;
      Members : TObjectList<TTemplateMember>;
      // if true any other member can appear
      OpenMemberList : boolean;
      constructor Create(Name : string; GUID : RGUID);
      constructor CreatePrimitiveType(Name : string; Size : DWord);
      // procedure ReadData; virtual;
      destructor Destroy; override;
  end;

  TDataNode = class
    private
      function GetValue(Key : string) : TDataNode;
    public
      Parent : TDataNode;
      DataType : TTemplate;
      Members : TObjectDictionary<string, TDataNode>;
      property Value[Key : string] : TDataNode read GetValue; default;
      constructor CreateAndLoad(DataType : TTemplate; RawData : TStream; Parent : TDataNode);
      constructor CreateRootNode;
      function AsFloat : single; virtual;
      function AsDWord : DWord; virtual;
      function AsString : AnsiString; virtual;
      function AsVector3 : RVector3; virtual;
      function AsVector2 : RVector2; virtual;
      function AsMatrix : RMatrix; virtual;
      function AsAFloat : ASingle; virtual;
      function AsADWord : ADWord; virtual;
      function AsARVector2 : ARVector2; virtual;
      function AsARVector3 : ARVector3; virtual;
      destructor Destroy; override;
  end;

  TDataNodeValue = class(TDataNode)
    Data : TArray<Byte>;
    constructor CreateAndLoad(DataType : TTemplate; RawData : TStream; Parent : TDataNode);
    function AsDWord : DWord; override;
    function AsFloat : single; override;
    function AsString : AnsiString; override;
    destructor Destroy; override;
  end;

  TDataNodeArray = class(TDataNode)
    Values : TObjectList<TDataNode>;
    constructor CreateAndLoad(ElementDataType : TTemplate; RawData : TStream; Count : DWord; Parent : TDataNode);
    function AsMatrix : RMatrix; override;
    function AsARVector3 : ARVector3; override;
    function AsARVector2 : ARVector2; override;
    function AsADWord : ADWord; override;
    function AsAFloat : ASingle; override;
    destructor Destroy; override;
  end;

  TXFileLoader = class
    private
      FHeader : RHeader;
      FFileFormat : EnumFileFormat;
      FXFile : TStream;
      FTemplates : TObjectDictionary<string, TTemplate>;
      FData : TDataNode;
      procedure ParseXFile;
      procedure AddPrimitiveTypes;
      function DeCompressFileStream(Source : TStream) : TStream;
    public
      property Data : TDataNode read FData;
      constructor CreateFromFile(FileName : string);
      constructor CreateFromStream(Stream : TStream);
      destructor Destroy; override;
  end;

implementation

{ TXFileLoader }

procedure TXFileLoader.AddPrimitiveTypes;
begin
  FTemplates.Add('FLOAT', TTemplate.CreatePrimitiveType('Float', 4));
  FTemplates.Add('DWORD', TTemplate.CreatePrimitiveType('DWord', 4));
  // word is saved as dword (4 bytes) even if documentation says 2 bytes
  FTemplates.Add('WORD', TTemplate.CreatePrimitiveType('Word', 4));
  FTemplates.Add('LPSTR', TTemplate.CreatePrimitiveType('LPStr', MAXDWORD));
  FTemplates.Add('REFERENCE', TTemplate.CreatePrimitiveType('Reference', MAXDWORD));
end;

constructor TXFileLoader.CreateFromFile(FileName : string);
var
  Stream : TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  CreateFromStream(Stream);
  Stream.Free;
end;

constructor TXFileLoader.CreateFromStream(Stream : TStream);
begin
  // anti bug;)
  assert(Ord(TOKEN_ARRAY) = 52);
  FTemplates := TObjectDictionary<string, TTemplate>.Create([doOwnsValues]);
  FData := TDataNode.CreateRootNode;
  FXFile := Stream;
  FXFile.ReadBuffer(FHeader, SizeOf(RHeader));
  // Check Magic Number
  if AnsiLowerCase(string(FHeader.MagicNumber)) <> RHeader.MAGICNUMBERCONST then raise EIncorrectXFileFormatException.Create('Magicnumber is wrong or missing.');
  // get enumeration from string fileformat
  FFileFormat := FHeader.GetFileFormat;
  // atm only support 32-Bit floats
  if FHeader.FloatSize <> RHeader.DEFAULTFLOATSIZE then raise ENotSupportedXFileFormatException.Create('Floatsize "' + FHeader.FloatSize + '" not supported (only 32-Bit).');
  // Load all primitive types into template libary (e.g. Float, DWord etc.)
  AddPrimitiveTypes;
  // parse data depending on format
  case FFileFormat of
    txt : raise ENotSupportedXFileFormatException.Create('Txt-fileformat not supported!');
    bin : ParseXFile;
    tzip : raise ENotSupportedXFileFormatException.Create('Tzip-fileformat not supported!');
    bzip :
      begin
        FXFile := DeCompressFileStream(FXFile);
        ParseXFile;
        // free XFile because UnCompressFileStream will create new XFile-stream
        FXFile.Free;
      end;
  end;
end;

destructor TXFileLoader.Destroy;
begin
  FTemplates.Free;
  FData.Free;
  inherited;
end;

function ConvertEnumTokenToPrimtiveType(Token : EnumTokens) : AnsiString;
begin
  case Token of
    TOKEN_WORD : result := 'Word';
    TOKEN_DWORD : result := 'DWord';
    TOKEN_FLOAT : result := 'Float';
    TOKEN_DOUBLE : result := 'Double';
    TOKEN_CHAR : result := 'Char';
    TOKEN_UCHAR : result := 'UChar';
    TOKEN_SWORD : result := 'SWord';
    TOKEN_SDWORD : result := 'SDWord';
    TOKEN_VOID : result := 'Void';
    TOKEN_LPSTR : result := 'LPStr';
    TOKEN_UNICODE : result := 'Unicode';
    TOKEN_CSTRING : result := 'CString';
  end;
end;

procedure TXFileLoader.ParseXFile;
var
  Token : EnumTokens;
  function TokenToStr(Token : EnumTokens) : string;
  begin
    result := GetEnumName(TypeInfo(EnumTokens), Ord(Token));
  end;
  procedure GetToken;
  begin
    if not FXFile.Eof then Token := EnumTokens(FXFile.ReadWord)
    else Token := DUMMY_0;
  end;
  procedure Expect(ExpectedToken : EnumTokens); overload;
  begin
    if ExpectedToken <> Token then raise EIncorrectXFileFormatException.Create('Was expect token ' + TokenToStr(ExpectedToken) + ', but found token ' + TokenToStr(Token));
  end;
  procedure Expect(ExpectedToken : SetTokens); overload;
  begin
    if not(Token in ExpectedToken) then raise EIncorrectXFileFormatException.Create('Token "' + TokenToStr(Token) + '" was not expected.');
  end;
  procedure ParseTemplate;
  var
    Name : RName;
    GUID : RGUID;
    Template : TTemplate;
    procedure ParseTemplateParts;
      procedure ParseTemplateMembersList;
        procedure ParseTemplateMembers;
        var
          TemplateMember : TTemplate.TTemplateMember;
          TemplateTypeName : RName;
          procedure GetArrayDimension;
          var
            DimRef : RName;
            i : integer;
          begin
            TTemplate.TTemplateMemberArray(TemplateMember).DimensionRef := nil;
            Expect(TOKEN_OBRACKET);
            GetToken;
            if Token = TOKEN_INTEGER then
            begin
              TTemplate.TTemplateMemberArray(TemplateMember).Dimension := FXFile.ReadCardinal;
            end
            else
            begin
              Expect(TOKEN_NAME);
              DimRef.ReadData(FXFile);
              // search in members if current template for given reference
              for i := 0 to Template.Members.Count - 1 do
                if AnsiUpperCase(Template.Members[i].Name) = AnsiUpperCase(DimRef) then
                begin
                  TTemplate.TTemplateMemberArray(TemplateMember).DimensionRef := Template.Members[i];
                  break;
                end;
              if not assigned(TTemplate.TTemplateMemberArray(TemplateMember).DimensionRef) then raise EIncorrectXFileFormatException.Create('Datareferenz "' + DimRef + '" was not found.');
            end;
            GetToken;
            Expect(TOKEN_CBRACKET);
            GetToken;
            if Token = TOKEN_OBRACKET then raise ENotSupportedXFileFormatException.Create('Multidimensional arrays atm not supported.');
          end;

        begin
          if Token = TOKEN_ARRAY then
          begin
            TemplateMember := TTemplate.TTemplateMemberArray.Create;
            GetToken;
          end
          else TemplateMember := TTemplate.TTemplateMember.Create;
          if Token = TOKEN_NAME then TemplateTypeName.ReadData(FXFile)
          else if Token in [TOKEN_WORD .. TOKEN_CSTRING] then TemplateTypeName.Name := ConvertEnumTokenToPrimtiveType(Token)
          else raise EIncorrectXFileFormatException.Create('Primitive type or name token expected but token ' + TokenToStr(Token) + ' found.');
          if not FTemplates.TryGetValue(AnsiUpperCase(TemplateTypeName), TemplateMember.TemplateType) then raise EIncorrectXFileFormatException.Create('Templatename "' + TemplateTypeName + '" not found. Template must be a primitive type or declared before use.');
          GetToken;
          if Token = TOKEN_NAME then
          begin
            TemplateMember.Name.ReadData(FXFile);
            GetToken;
          end;
          if TemplateMember is TTemplate.TTemplateMemberArray then GetArrayDimension;
          Expect(TOKEN_SEMICOLON);
          GetToken;
          // new template member parsed, add it to list
          Template.Members.Add(TemplateMember);
        end;

      begin
        while Token in [TOKEN_ARRAY, TOKEN_NAME, TOKEN_WORD .. TOKEN_CSTRING] do ParseTemplateMembers;
      end;

      procedure ParseTemplateOptionInfo;
      var
        OptionName : RName;
        OptionClassId : RGUID;
      begin

        Expect(TOKEN_OBRACKET);
        GetToken;
        case Token of
          TOKEN_DOT :
            // excepect ellipsis = ...
            begin
              GetToken;
              Expect(TOKEN_DOT);
              GetToken;
              Expect(TOKEN_DOT);
              GetToken;
              Template.OpenMemberList := True;
            end;
          // template_option_list
        else while Token <> TOKEN_CBRACKET do
          begin
            Expect(TOKEN_NAME);
            OptionName.ReadData(FXFile);
            GetToken;
            // classId is optional
            if Token = TOKEN_GUID then
            begin
              OptionClassId.ReadData(FXFile);
              GetToken;
            end;
          end;
        end;
        Expect(TOKEN_CBRACKET);
        GetToken;
      end;

    begin
      if Token = TOKEN_OBRACKET then ParseTemplateOptionInfo
      else
      begin
        ParseTemplateMembersList;
        if Token = TOKEN_OBRACKET then ParseTemplateOptionInfo;
      end;
    end;

  begin
    // check token and read template name
    Expect(TOKEN_NAME);
    name.ReadData(FXFile);
    GetToken;
    Expect(TOKEN_OBRACE);
    GetToken;
    // check token and read unique template GUID
    Expect(TOKEN_GUID);
    GUID.ReadData(FXFile);
    GetToken;
    Template := TTemplate.Create(name, GUID);
    // parse members etc
    ParseTemplateParts;
    Expect(TOKEN_CBRACE);
    FTemplates.Add(AnsiUpperCase(name), Template);
  end;

  procedure ParseData;

    procedure ParseDataObject(RootData : TDataNode);
    var
      identifier : RName;
      Name : RName;
      Data : TDataNode;
      GUID : RGUID;
      RawData : TStream;
      Key : string;
      i : integer;
      procedure ParseDataOptional;
      var
        Member : TDataNodeValue;
        StringData : RString;
        optionalGUID : RGUID;
      begin
        while Token in [TOKEN_NAME, TOKEN_OBRACE] do
        begin
          case Token of
            // object
            TOKEN_NAME : ParseDataObject(Data);
            // data_reference
            TOKEN_OBRACE :
              begin
                Member := TDataNodeValue.CreateAndLoad(FTemplates['REFERENCE'], nil, Data);
                GetToken;
                // data referenz as string
                Expect(TOKEN_NAME);
                StringData.ReadData(FXFile);
                setlength(Member.Data, StringData.Count);
                Move(StringData.StringData[1], Member.Data[0], StringData.Count);
                GetToken;
                // optional class id, only loaded not used or saved
                if Token = TOKEN_GUID then
                begin
                  optionalGUID.ReadData(FXFile);
                  GetToken;
                end;
                Expect(TOKEN_CBRACE);
                GetToken;
                if Data.Members.ContainsKey(FTemplates['REFERENCE'].Name) then Member.Free
                else Data.Members.Add(FTemplates['REFERENCE'].Name, Member);
              end
          else raise ENotSupportedXFileFormatException.Create('Token ' + TokenToStr(Token) + ' is valid but not implemented.');
          end;
        end;
      end;

      function ExtractRawData : TStream;
      var
        StringData : RString;
        FloatList : RFloatList;
        IntegerList : RIntegerList;
      begin
        result := TMemoryStream.Create;
        // if token not in set, specified data ends
        while Token in [TOKEN_INTEGER_LIST, TOKEN_FLOAT_LIST, TOKEN_STRING] do
        begin
          case Token of
            TOKEN_INTEGER_LIST :
              begin
                IntegerList.ReadData(FXFile);
                IntegerList.WriteRawData(result);
                GetToken;
              end;
            TOKEN_FLOAT_LIST :
              begin
                FloatList.ReadData(FXFile);
                FloatList.WriteRawData(result);
                GetToken;
              end;
            TOKEN_STRING :
              begin
                StringData.ReadData(FXFile);
                StringData.WriteRawData(result);
                GetToken;
                Expect([TOKEN_SEMICOLON, TOKEN_COMMA]);
                GetToken;
                // while loop, because list of strings possible
              end
          else raise ENotSupportedXFileFormatException.Create('Token ' + TokenToStr(Token) + ' is valid but not implemented.');
          end;
        end;
      end;

    begin
      Expect(TOKEN_NAME);
      identifier.ReadData(FXFile);
      if not FTemplates.ContainsKey(AnsiUpperCase(identifier)) then EIncorrectXFileFormatException.Create('ParseDataObject: Unknown identifier "' + identifier);
      GetToken;
      // name is optional, if exist (name not '') add it by name, else by identifier
      name.Count := 0;
      if Token = TOKEN_NAME then
      begin
        name.ReadData(FXFile);
        GetToken;
      end;

      Expect(TOKEN_OBRACE);
      GetToken;
      // optional GUID
      if Token = TOKEN_GUID then
      begin
        GUID.ReadData(FXFile);
        GetToken;
      end;
      // first load all specified data and add node
      RawData := ExtractRawData;
      RawData.Position := 0;
      if FTemplates.ContainsKey(AnsiUpperCase(identifier)) then Data := TDataNode.CreateAndLoad(FTemplates[AnsiUpperCase(identifier)], RawData, RootData)
      else Data := nil;
      // if RawData.Position = RawData.Size then all data was loaded
      assert(RawData.Position = RawData.Size);
      RawData.Free;
      // if Mesh, dont use name (i little hack :( )
      if (name.Count > 0) and ((CompareText(identifier, 'Mesh') <> 0)) then
      begin
        Key := name;
      end
      else Key := identifier;
      // if key already added, manipulate them with index
      if RootData.Members.ContainsKey(Key) then
      begin
        i := 1;
        while RootData.Members.ContainsKey(Key + IntToStr(i)) do inc(i);
        Key := Key + IntToStr(i);
      end;
      RootData.Members.Add(Key, Data);

      // load all optional data
      ParseDataOptional;
      Expect(TOKEN_CBRACE);
      GetToken;
    end;

  begin
    while not FXFile.Eof do
    begin
      ParseDataObject(FData);
    end;
  end;

begin
  while not FXFile.Eof do
  begin
    GetToken;
    Expect([TOKEN_TEMPLATE, TOKEN_NAME]);

    case Token of
      TOKEN_TEMPLATE :
        begin
          GetToken;
          ParseTemplate;
        end;
      TOKEN_NAME : ParseData;
    end;
  end;
end;

function TXFileLoader.DeCompressFileStream(Source : TStream) : TStream;
const
  BUFFERSIZE = 1024;
var
  CompressedChunkSize : Word;
  DecompressedChunkSize : Cardinal;
  Decompressor : TMSZipDecompressor;
  Buffer, OutBuffer : TArray<Byte>;
begin
  setlength(Buffer, 32 * 1024 + 100);
  setlength(OutBuffer, 32 * 1024 + 100);
  Decompressor := TMSZipDecompressorUseZLib.Create;
  result := TMemoryStream.Create;
  repeat
    ZeroMemory(@OutBuffer[0], Length(OutBuffer));
    DecompressedChunkSize := Source.ReadWord;
    CompressedChunkSize := Source.ReadWord;
    Source.ReadBuffer(Buffer[0], CompressedChunkSize);
    Decompressor.DecompressBuffer(@OutBuffer[0], @Buffer[0], CompressedChunkSize, DecompressedChunkSize);
    // assert(CheckSize = DecompressedChunkSize);
    result.WriteBuffer(OutBuffer[0], DecompressedChunkSize);
  until Source.Eof;
  result.Position := 0;
  Decompressor.Free;
end;

{ RHeader }

function RHeader.GetFileFormat : EnumFileFormat;
begin
  if AnsiLowerCase(string(FormatType)) = FORMATTYPETXT then Exit(EnumFileFormat.txt)
  else if AnsiLowerCase(string(FormatType)) = FORMATTYPEBIN then Exit(EnumFileFormat.bin)
  else if AnsiLowerCase(string(FormatType)) = FORMATTYPETZIP then Exit(EnumFileFormat.tzip)
  else if AnsiLowerCase(string(FormatType)) = FORMATTYPEBZIP then Exit(EnumFileFormat.bzip)
  else raise EIncorrectXFileFormatException.Create('Unknown fileformat: ' + FormatType);
end;

{ RGUID }

function RGUID.GetDummy : RGUID;
begin
  ZeroMemory(@result, SizeOf(RGUID));
end;

procedure RGUID.ReadData(DataStream : TStream);
begin
  DataStream.ReadBuffer(self, SizeOf(RGUID));
end;

{ RIntegerList }

procedure RIntegerList.ReadData(DataStream : TStream);
begin
  Count := DataStream.ReadCardinal;
  setlength(List, Count);
  DataStream.ReadBuffer(List[0], SizeOf(DWord) * Count);
end;

procedure RIntegerList.WriteRawData(DataStream : TStream);
begin
  DataStream.Write(List[0], Count * SizeOf(DWord));
end;

{ RFloatList }

procedure RFloatList.ReadData(DataStream : TStream);
begin
  Count := DataStream.ReadCardinal;
  setlength(List, Count);
  DataStream.ReadBuffer(List[0], SizeOf(single) * Count);
end;

procedure RFloatList.WriteRawData(DataStream : TStream);
begin
  DataStream.Write(List[0], Count * SizeOf(single));
end;

{ RName }

class operator RName.implicit(a : RName) : string;
begin
  result := string(a.Name);
end;

procedure RName.ReadData(DataStream : TStream);
begin
  Count := DataStream.ReadCardinal;
  setlength(name, Count);
  if Count > 0 then DataStream.ReadBuffer(name[1], SizeOf(AnsiChar) * Count);
end;

{ RString }

procedure RString.ReadData(DataStream : TStream);
begin
  Count := DataStream.ReadCardinal;
  setlength(StringData, Count);
  DataStream.ReadBuffer(StringData[1], SizeOf(AnsiChar) * Count);
end;

procedure RString.WriteRawData(DataStream : TStream);
begin
  DataStream.Write(Count, SizeOf(DWord));
  DataStream.Write(StringData[1], Count * SizeOf(AnsiChar));
end;

{ TTemplate }

constructor TTemplate.Create(Name : string; GUID : RGUID);
begin
  self.Name := name;
  self.GUID := GUID;
  Members := TObjectList<TTemplateMember>.Create;
end;

constructor TTemplate.CreatePrimitiveType(Name : string; Size : DWord);
begin
  self.Name := name;
  self.Size := Size;
end;

destructor TTemplate.Destroy;
begin
  Members.Free;
  inherited;
end;

{ TDataNode }

function TDataNode.AsADWord : ADWord;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsAFloat : ASingle;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsARVector2 : ARVector2;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsARVector3 : ARVector3;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsDWord : DWord;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsFloat : single;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsMatrix : RMatrix;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsString : AnsiString;
begin
  raise EIsNotAValueDataNode.Create('This node doesn''t contain any data.');
end;

function TDataNode.AsVector2 : RVector2;
begin
  assert(DataType.Name = 'Coords2d');
  assert(Members.ContainsKey('u') and Members.ContainsKey('v'));
  assert(Members.Count = 2);
  result := RVector2.Create(Members['u'].AsFloat, Members['v'].AsFloat);
end;

function TDataNode.AsVector3 : RVector3;
begin
  assert(DataType.Name = 'Vector');
  assert(Members.ContainsKey('x') and Members.ContainsKey('y') and Members.ContainsKey('z'));
  assert(Members.Count = 3);
  result := RVector3.Create(Members['x'].AsFloat, Members['y'].AsFloat, Members['z'].AsFloat);
end;

constructor TDataNode.CreateAndLoad(DataType : TTemplate; RawData : TStream; Parent : TDataNode);
var
  TemplateMember : TTemplate.TTemplateMember;
  ArraySize : DWord;
begin
  assert(DataType.Size = 0);
  self.Parent := Parent;
  self.DataType := DataType;
  Members := TObjectDictionary<string, TDataNode>.Create([doOwnsValues]);
  for TemplateMember in DataType.Members do
  begin
    // if size > 0
    if TemplateMember is TTemplate.TTemplateMemberArray then
    begin
      ArraySize := TTemplate.TTemplateMemberArray(TemplateMember).GetDimension(self);
      Members.Add(TemplateMember.Name, TDataNodeArray.CreateAndLoad(TemplateMember.TemplateType, RawData, ArraySize, self))
    end
    else if TemplateMember.TemplateType.Size > 0 then
        Members.Add(TemplateMember.Name, TDataNodeValue.CreateAndLoad(TemplateMember.TemplateType, RawData, self))
    else
        Members.Add(TemplateMember.Name, TDataNode.CreateAndLoad(TemplateMember.TemplateType, RawData, self));
  end;
end;

constructor TDataNode.CreateRootNode;
begin
  Parent := nil;
  Members := TObjectDictionary<string, TDataNode>.Create([doOwnsValues]);
end;

destructor TDataNode.Destroy;
begin
  Members.Free;
  inherited;
end;

function TDataNode.GetValue(Key : string) : TDataNode;
begin
  result := Members[Key];
end;

{ TTemplate.TTemplateMember }

constructor TTemplate.TTemplateMember.Create(Name : RName;
  TemplateType : TTemplate);
begin
  self.Name := name;
  self.TemplateType := TemplateType;
end;

constructor TTemplate.TTemplateMember.Create;
begin

end;

{ TTemplate.TTemplateMemberArray }

function TTemplate.TTemplateMemberArray.GetDimension(
  DataNode : TDataNode) : DWord;
begin
  if DimensionRef = nil then result := Dimension
  else result := DataNode.Members[DimensionRef.Name].AsDWord;
end;

{ TDataNodeValue }

function TDataNodeValue.AsDWord : DWord;
begin
  assert((DataType.Name = 'DWord') or (DataType.Name = 'Word'));
  Move(Data[0], result, SizeOf(DWord));
end;

function TDataNodeValue.AsFloat : single;
begin
  assert(DataType.Name = 'Float');
  Move(Data[0], result, SizeOf(single));
end;

function TDataNodeValue.AsString : AnsiString;
begin
  assert((DataType.Name = 'LPStr') or (DataType.Name = 'Reference'));
  setlength(result, Length(Data));
  Move(Data[0], result[1], Length(Data) * SizeOf(AnsiChar));
end;

constructor TDataNodeValue.CreateAndLoad(DataType : TTemplate; RawData : TStream; Parent : TDataNode);
var
  Count : DWord;
begin
  self.DataType := DataType;
  self.Parent := Parent;
  assert(DataType.Size > 0);
  if DataType.Size < MAXDWORD then
  begin
    setlength(Data, DataType.Size);
    RawData.Read(Data[0], DataType.Size);
  end
  else
  begin
    // if reference, data is stored after create
    if AnsiUpperCase(string(DataType.Name)) <> 'REFERENCE' then
    begin
      RawData.Read(Count, SizeOf(DWord));
      setlength(Data, Count);
      RawData.Read(Data[0], Count);
    end;
  end;
end;

destructor TDataNodeValue.Destroy;
begin
  Data := nil;
  inherited;
end;

{ TDataNodeArray }

function TDataNodeArray.AsADWord : ADWord;
var
  i : integer;
begin
  assert(DataType.Name = 'DWord');
  setlength(result, Values.Count);
  for i := 0 to Values.Count - 1 do result[i] := Values[i].AsDWord;
end;

function TDataNodeArray.AsAFloat : ASingle;
var
  i : integer;
begin
  assert(DataType.Name = 'Float');
  setlength(result, Values.Count);
  for i := 0 to Values.Count - 1 do result[i] := Values[i].AsFloat;
end;

function TDataNodeArray.AsARVector2 : ARVector2;
var
  i : integer;
begin
  assert(DataType.Name = 'Coords2d');
  setlength(result, Values.Count);
  for i := 0 to Values.Count - 1 do result[i] := Values[i].AsVector2;
end;

function TDataNodeArray.AsARVector3 : ARVector3;
var
  i : integer;
begin
  assert(DataType.Name = 'Vector');
  setlength(result, Values.Count);
  for i := 0 to Values.Count - 1 do result[i] := Values[i].AsVector3;
end;

function TDataNodeArray.AsMatrix : RMatrix;
var
  i : integer;
begin
  assert(Values.Count = 16);
  assert(DataType.Name = 'Float');
  for i := 0 to 15 do result.Element[i] := Values[i].AsFloat;
end;

constructor TDataNodeArray.CreateAndLoad(ElementDataType : TTemplate;
  RawData : TStream; Count : DWord; Parent : TDataNode);
var
  i : integer;
begin
  self.DataType := ElementDataType;
  self.Parent := Parent;
  Values := TObjectList<TDataNode>.Create;
  for i := 0 to Count - 1 do
  begin
    // if size > 0, is primitive type -> load data
    if ElementDataType.Size > 0 then Values.Add(TDataNodeValue.CreateAndLoad(ElementDataType, RawData, self))
    else Values.Add(TDataNode.CreateAndLoad(ElementDataType, RawData, self))
  end;
end;

destructor TDataNodeArray.Destroy;
begin
  Values.Free;
  inherited;
end;

end.
